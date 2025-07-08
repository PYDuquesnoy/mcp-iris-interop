/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occODBC

/// 
/// Implements the AutoML provider
/// 
Class %ML.AutoML.Provider Extends %ML.Provider
{

/// Provider name
Parameter PROVIDERNAME As %String = "AutoML";

Property initialized As %Boolean [ InitialExpression = 0 ];

Property automl As %SYS.Python [ Internal, Transient ];

Property automlts As %SYS.Python [ Internal, Transient ];

Property numpy As %SYS.Python [ Internal, Transient ];

Property pandas As %SYS.Python [ Internal, Transient ];

Property datetime As %SYS.Python [ Internal, Transient ];

Property builtins As %SYS.Python [ Internal, Transient ];

Property decimal As %SYS.Python [ Internal, Transient ];

Property cProfile As %SYS.Python [ Internal, Transient ];

Property pstats As %SYS.Python [ Internal, Transient ];

Property io As %SYS.Python [ Internal, Transient ];

/// 
/// Adds the default settings for AutoML to the settings dynamic object
/// 
ClassMethod %GetDefaultSettings(ByRef settings As %DynamicObject)
{
	do:'settings.%IsDefined("verbosity") settings.%Set("verbosity",2)
	RETURN
}

/// 
/// Train an ML model
/// 
/// name is no longer used.  trainingrun.name is already defined
Method %BeginTraining(model As %ML.Model, data As %SQL.StatementResult, trainingrun As %ML.TrainingRun, ByRef name As %String = "", ByRef trainkey) As %Status
{
	#dim status As %Status = $$$OK

	Try {
		#dim trainedmodel As %ML.AutoML.TrainedModel
		#dim predictingcolumn As %String
		#dim count As %Integer = 0


		If '..initialized {
			Set status = ..%OnInit()
			Quit:$$$ISERR(status)
		}

		If ((model.PredictingColumnNames.Count()'=1) && ('model.TimeSeries)) {
			Set status = $$$ERROR($$$MLUnknownPrediction)
			Quit
		}
		
		set predictingcolumn = ""
		for i=1:1:model.PredictingColumnNames.Count() {
			Set predictingcolumntmp = model.PredictingColumnNames.GetAt(i)
			Set:predictingcolumntmp["." predictingcolumntmp=$p(predictingcolumntmp,".",2)	// If qualified, just get the name
			If predictingcolumntmp="" {
				Set status = $$$ERROR($$$MLUnknownPrediction)
				Quit
			}
			set suffix = ""
			if i'=model.PredictingColumnNames.Count() {set suffix = ";:"}
			set predictingcolumn = predictingcolumn _ predictingcolumntmp _ suffix
		}
		// We use lower-case column names
		Set predictingcolumn = $ZCVT(predictingcolumn,"l")
		//APV091 - Defining two different cases for TS and non-TS runs
		If model.TimeSeries{
			Set status = ..%ResultSetToDataFrame(.data, .info, .df, .count)
		}
		Else{
			Set status = ..%ResultSetToDataFrame(.data, .info, .df, .count, predictingcolumn)
		}
		Quit:$$$ISERR(status)

		If count=0 {
			// Need data to train
			Set status = $$$ERROR($$$MLNoDataSupplied)
			Quit
		}

		// typeinfo needs to be JSON for automl.py
		Set typeinfo = info.%ToJSON()

		Set args = {
			"label_column":	(predictingcolumn),
			"iris_dtypes":	(typeinfo),
			"verbose":		($s(trainingrun.Settings.verbosity="":2,1:+trainingrun.Settings.verbosity)),	// 2 is default Verbosity
			"n_jobs":		1
		}

		if 'model.TimeSeries {
			Set:(trainingrun.Settings.trainmode'="") args."train_mode" = (trainingrun.Settings.trainmode)
			Set:(trainingrun.Settings.maxtime'="") args."max_time" = (trainingrun.Settings.maxtime)
			Set:(trainingrun.Settings.minimumdesiredscore'="") args."minimum_desired_score" = (trainingrun.Settings.minimumdesiredscore)
			Set:(trainingrun.Settings.isregression'="") args."is_label_regression" = (trainingrun.Settings.isregression)
			Set args."force_inc_train" = $G(^%SYS("ForceIncrementalTrain"),0)
			
			Set args."path_to_classifiers"=##class(%File).NormalizeDirectory(##class(%File).ManagerDirectory()_"/python/iris_automl/Classifiers")
			Set args."path_to_regressors"=##class(%File).NormalizeDirectory(##class(%File).ManagerDirectory()_"/python/iris_automl/Regressors")
			Set:(trainingrun.Settings.pathtoclassifiers'="") args."path_to_classifiers" = (trainingrun.Settings.pathtoclassifiers)
			Set:(trainingrun.Settings.pathtoregressors'="") args."path_to_regressors" = (trainingrun.Settings.pathtoregressors)
			Set userparams={}
			Set userParamsIter=trainingrun.Settings.%GetIterator()
			while userParamsIter.%GetNext(.key, .value){			
				if key["user"{
					Do userparams.%Set(key, value)
				}
			}
			Set args."user_params"=userparams.%ToJSON()
		}
		else {
			set args."date_column" = $ZCONVERT(model.DateTimeColumn,"L")
			set args."frequency" = $s(trainingrun.Settings.frequency="":"def",1:$ZCONVERT(trainingrun.Settings.frequency,"U"))
			set args."seasonality" = $s(trainingrun.Settings.seasonality="":"def",1:trainingrun.Settings.seasonality)
			set args."forward" = $s(trainingrun.Settings.forward="":1,1:trainingrun.Settings.forward)
			set model.Forward = args."forward"
		}

		// Setting Seed has an alias of seed
		if trainingrun.Settings.seed'="" { set args."random_state" = +trainingrun.Settings.seed }

		// Train the model!
		Set status = ##class(%ML.Utils).%RunMethodWithCapture($THIS, "%DoTrain", trainingrun.Log, .result, df, args, model.TimeSeries)
		Quit:$$$ISERR(status)

		Set trainingrun.CompletedAt = $ZDATETIME($ZTIMESTAMP,3,1,3)

		If '$IsObject(result) {
			Set status = $$$ERROR($$$MLGeneralError,"automl.train()","Failed!")
		} Else {
			Set:result.get("status")'="200" status = ..maperror(result.get("error"),result.get("text"))
		}
		
		If $$$ISERR(status) {
			Set trainingrun.RunStatus = "failed"
			Set trainingrun.StatusCode = status
		} Else {
			Set trainingrun.RunStatus = "completed"
		}

		// Update the training run with the results
		Set status = trainingrun.%Save()
		Quit:$$$ISERR(status)

		// Check for training failure ...
		If trainingrun.RunStatus = "failed" {
			Set status = trainingrun.StatusCode
			Quit
		}

		Set modeldata = result.get("body")
		Set modellen = ..builtins.len(modeldata)

		Set status = ##class(%ML.AutoML.TrainedModel).%CreateTrainedModel($THIS, trainingrun, .trainedmodel)
		Quit:$$$ISERR(status)

		// Since we are likely to now PREDICT, let's stash a copy of the provider here
		Set trainedmodel.automlprovider = $THIS

		// Write the persistent model state to a binary stream
		If $IsObject(modeldata) {
			Set offset = 0
			Set max = $$$MaxLocalLength
			While (offset < modellen) {
				Set len = $S(offset+max>modellen:modellen-offset,1:max) 
				Set slice = ..builtins.slice(offset, offset+len)

				If '$IsObject(slice) {
					Set status = $$$ERROR($$$PythonGeneralError,"slice IS NOT an object!")
					Quit
				}

				Set data = modeldata."__getitem__"(slice)

				If $IsObject(data) {
					Set status = $$$ERROR($$$PythonGeneralError,"data IS an object!")
					Quit
				}

				Do trainedmodel.ModelState.Write(data)

				Set offset = offset + $L(data)
			}
		} Else {
			Do trainedmodel.ModelState.Write(modeldata)
		}

		// Copy any available model info
		Try {
			Set modelinfo = result."__getitem__"("ModelInfo")
			Set modeltype = modelinfo."__getitem__"("ProblemType")
			Set:modeltype'="" trainedmodel.ModelType = $ZCVT(modeltype,"l")
			Set iter = modelinfo."__iter__"()
			For {
				Set key = iter."__next__"()	// NOTE: raises a StopIteration when done
				Set val = modelinfo."__getitem__"(key)

				Do trainedmodel.ModelInfo.SetAt(val,key)
			}
		} Catch (pyex) {
			// We ignore any KeyError or StopIteration exceptions here
			If (pyex.Data'["KeyError") && (pyex.Data'["StopIteration") {
				// Something else ...
				Set status = pyex.AsStatus()
				Quit
			}
		}
	
		Set status = trainedmodel.%Save()
		Quit:$$$ISERR(status)

		// We use the trained model OREF as the key since we're all complete now
		Set trainkey = trainedmodel

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

/// 
/// Helper method for invoking a python method with keyword args while under I/O capture
/// 	0			:..automl.train(df, args...),
/// 				:..automlts.train(df, args...)
Method %DoTrain(df As %SYS.Python, args As %DynamicObject, timeseries As %Boolean) As %SYS.Python [ CodeMode = expression, Internal ]
{
$CASE(timeseries,
 	0			:..automl.train(df, args...),
 				:..automlts.train(df, args...)
)
}

/// 
/// Check for training complete
/// 
Method %WaitForTraining(ByRef trainkey, trainingrun As %ML.TrainingRun, ByRef trainedmodel As %ML.TrainedModel, timeoutMS As %Integer = -1) As %Status
{
	#dim status As %Status = $$$OK
	Try {

		// The trainkey is actually the trainedmodel instance from %BeginTraining since we're not async
		If '$IsObject(trainkey) || 'trainkey.%Extends("%ML.AutoML.TrainedModel") {
			Set status = $$$ERROR($$$MLInvalidTrainKey,trainkey)
			Quit
		}

		Set trainedmodel = trainkey

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

/// 
/// Bulk Predict
/// 
Method %PredictAll(trainedmodel As %ML.AutoML.TrainedModel, tfn As %Integer, argspos As %List, predpos As %List, probpos As %List, expr As %String = "", mtorder As %List, mtunary As %List) As %Status
{
	#dim status As %Status = $$$OK
	Try {
		#dim df As %SYS.Python
		#dim result As %SYS.Python
		#dim row As %SYS.Python
		#dim count, n, pos, predict As %Integer
		#dim type As %Integer
		#dim profiler As %SYS.Python = $$$NULLOREF
		#dim value
		#dim i,method,predictions,results,sortkey As %String
		#dim raw As %List

		If '..initialized {
			Set status = ..%OnInit()
			Quit:$$$ISERR(status)
		}

		//Set time = $ZH

		If trainedmodel.TrainingRun.Settings.%IsDefined("profile") {
			Set status = ..%StartProfiler(trainedmodel.TrainingRun.Settings.profile, .profiler) // profile argument is not actually used in %STartPrifiler, but if it is defined, we profile
			Quit:$$$ISERR(status)
		}

		If '$IsObject(trainedmodel.modelinstance) {
		   Set status = trainedmodel.%LoadModel()
		   Quit:$$$ISERR(status)
		}

		If 'trainedmodel.Model.PredictingColumnTypes.Count() {
			Set status = $$$ERROR($$$MLUnknownPrediction)
			Quit
		}

		//Set time = $zh-time WRITE "LM:",?16,time,"s",!
		//Set time = $zh

		// Convert the temp data into a dataframe
		
		if trainedmodel.ModelType '= "timeseries" {
			Set status = ..%TempFileToDataFrame(trainedmodel.WithColumnNames, trainedmodel.WithColumnTypes, tfn, argspos, .df, .count)
		}
		else {
			set mtorderArgsPointer = 1, mtorderArgsCounter = 1, mtorderArgs = ""
			while (mtorderArgsPointer <= $LL(mtorder)) {
				set mtorderArgs = mtorderArgs_$LB(mtorderArgsCounter)
				if $LF(mtunary, $LG(mtorder, mtorderArgsPointer)) { set mtorderArgsCounter = mtorderArgsCounter + 1 }
				set mtorderArgsCounter = mtorderArgsCounter + 1, mtorderArgsPointer = mtorderArgsPointer + 1
			}
			set channelColumns = $LB($$$LOWER(trainedmodel.Model.DateTimeColumn))
			set channelTypes = $LB("11")
			set argspos = $LB($LG(mtorderArgs,$LF(mtorder,$$$LOWER(trainedmodel.Model.DateTimeColumn))))
			for pcn=1:1:trainedmodel.Model.PredictingColumnNames.Count() {
				set channelColumns = channelColumns_$LB($$$LOWER(trainedmodel.Model.PredictingColumnNames.GetAt(pcn)))
				set channelTypes = channelTypes_$LB(trainedmodel.Model.PredictingColumnTypes.GetAt(pcn))
				///
				set argspos = argspos_$LB($LG(mtorderArgs,$LF(mtorder,$$$LOWER(trainedmodel.Model.PredictingColumnNames.GetAt(pcn)))))
			}
			Set status = ..%TempFileToDataFrame(channelColumns, channelTypes, tfn, argspos, .df, .count, mtorder, mtunary)
		}
		Quit:$$$ISERR(status)

		//Set time = $zh-time WRITE "DF:",?16,time,"s",!
		//Set time = $zh

		If count=0 {
			Set status = $$$ERROR($$$MLNoDataSupplied)
			Quit
		}

		// Currently, we can only do PREDICT or PROBABILITY, not both in the same call
		If ($LL(predpos)>0) && ($LL(probpos)=0) {
			Set result = trainedmodel.modelinstance.predict(df, 0 /*trainedmodel.TrainingRun.Settings.Verbosity*/)
			Set method="predict"
			Set pos = $LI(predpos,1)
			Set type = trainedmodel.Model.PredictingColumnTypes.GetAt(1)
		} ElseIf ($LL(predpos)=0) && ($LL(probpos)>0) {
			Set result = trainedmodel.modelinstance.probability(df, expr, 0 /*trainedmodel.TrainingRun.Settings.Verbosity*/)
			Set method="probability"
			Set pos = $LI(probpos,1)
			Set type = $$$ODBCTYPEdouble
		} ElseIf (trainedmodel.ModelType = "timeseries") {
			set tsheaders = df."columns" /// Does this need to match/come from result?
			Set result = trainedmodel.modelinstance.predict(df, 0 /*trainedmodel.TrainingRun.Settings.Verbosity*/)
			if (result.get("warning")'="") {write "WARNING: "_result.get("warning")}
			Set method="tspredict"
			Set pos = 1 // Not necessary except to not be NULL
			Set type = $$$ODBCTYPEdouble
		} Else {
			Set status = $$$ERROR($$$MLInternalError,"PREDICT() or PROBABILITY() ... pick one!")
			Quit
		}

		// Sanity check the results
		If '$IsObject(result) {
			Set status = $$$ERROR($$$MLGeneralError,"automl."_method_"()","Failed!")
			Quit
		}

		If result.get("status") '= "200" {
			Set status = ##class(%ML.AutoML.Provider).maperror(result.get("error"),result.get("text"))
			Quit
		}

		//Set time = $zh-time WRITE "PREDICT:",?16,time,"s",!
		//Set time = $zh

		// NOTE: We can currently only PREDICT() / PROBABILITY() on one column ...
		set predict=(predpos'="")	// if predict=1, this is predict, otherwise, probability
		if trainedmodel.ModelType '= "timeseries" {
			// update the temp file using predictions
			Set types = $lb(type), fieldnames = $lb("predictions"), positions = $lb(pos), isPredict = $lb(predict)
			Set status = ..%DataFrameToTempFile(tfn, result, fieldnames, positions, types, isPredict)
		}
		else {
			Set status = ..%TSDataFrameToTempFile(tfn, result, tsheaders, trainedmodel.Model.DateTimeColumn, channelColumns, channelTypes, mtorder, mtunary)
		}
		Quit:$$$ISERR(status)

		If $IsObject(profiler) {
			Set status = ..%StopProfiler(profiler, .sortkey, .results)
			Quit:$$$ISERR(status)


			Do trainedmodel.TrainingRun.Log.MoveToEnd()
			Do trainedmodel.TrainingRun.LogMsg("Profile using: "_..builtins.str(sortkey))
			Set results = $TR(results,$C(13))
			For i=1:1:$L(results,$C(10)) {
				Do trainedmodel.TrainingRun.Log.WriteLine($P(results,$C(10),i))
			}
		}

		//Set time = $zh-time WRITE "RESULTS:",?16,time,"s",!
	}
	Catch (ex) {
			Set status = ex.AsStatus()
		}
	Quit status
}

/// 
/// Initialize an ML provider
/// 
Method %OnInit() As %Status
{
	#dim status As %Status = $$$OK
	Try {
		// Disable signal/stdio processing
		Do ##class(%SYS.Python).ChangeSignalState(1)

		// NOTE: warnings is only used here to suppress import warnings and should be before any
		//       packages such as numpy that might generate warnings
		Set warnings = $$$NULLOREF

		For pkgname = "builtins", "automl", "automlts", "numpy", "pandas", "datetime", "decimal", "io" {
			If $IsObject($PROPERTY($THIS,pkgname)) {
				Continue
			}

			If (pkgname'="builtins") && '$IsObject(warnings) {
				Set warnings = ##class(%SYS.Python).Import("warnings")
				If '$IsObject(warnings) {
					Set status = $$$ERROR($$$PythonImportFailed,"warnings")
					Quit
				}

				Do warnings.simplefilter("ignore")
			}
			
			Set status = ..%ImportPackage(pkgname, .pkg)
			If $$$ISERR(status) Quit
			Set $PROPERTY($THIS,pkgname) = pkg
		}

		// Restore warnings
		Do:$IsObject(warnings) warnings.resetwarnings()

		Set ..initialized = 1
	
	} Catch (ex) {
		set status = ex.AsStatus()
		If ex.Data["Failed to load python" {
			Set status = $$$EMBEDSC($$$ERROR($$$MLProviderUnavailable,..%GetName()),status)
		}
	}

	Quit status
}

ClassMethod %ImportPackage(pkgname As %String, Output pkg) As %Status
{
	Try{
		Set status= $$$OK
		Kill pkg
		if pkgname="automl" {
			Set pkg = ##class(%SYS.Python).Import("iris_automl.automl")
		}
		elseif pkgname="automlts" {
			Set pkg = ##class(%SYS.Python).Import("iris_automl.automlts")
		}
		else { Set pkg = ##class(%SYS.Python).Import(pkgname) }
	}Catch err{
		If (pkgname="automl") && (err.Data["No module named 'iris_automl' - Import"){ //DP-417844
			Set status = $$$ERROR($$$MLProviderUnavailable, "AutoML")
		}Else{
			Set status = err.AsStatus()
		}
	}
	
	If $$$ISERR(status) Quit status //If any exception has been thrown, quit with error

	If $IsObject(pkg) Return $$$OK
	
	//If no exception has been thrown, but pkg has not been imported, quit with error
	Return $$$ERROR($$$PythonImportFailed,pkgname)
}

/// 
/// Start the Python profiler
/// 
Method %StartProfiler(options As %String, ByRef profiler As %SYS.Python) As %Status
{
	#dim status As %Status = $$$OK
	Try {
		For pkgname = "cProfile", "pstats" {
			If '$IsObject($PROPERTY($THIS, pkgname)) {
				Set pkg = ##class(%SYS.Python).Import(pkgname)
				If '$IsObject(pkg) {
					Set status = $$$ERROR($$$PythonImportFailed,pkgname)
					Quit
				}
				
				Set $PROPERTY($THIS, pkgname) = pkg
			}
		}
		Quit:$$$ISERR(status)

		Set profiler = ..cProfile.Profile()
		Do profiler.enable()		

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

/// 
/// Stop the Python profiler
/// 
Method %StopProfiler(profiler As %SYS.Python, ByRef sortby As %String = "CUMULATIVE", ByRef results As %String) As %Status
{
	#dim status As %Status = $$$OK
	Try {
		
		Do profiler.disable()

		Set stream = ..io.StringIO()

		Try {
			Set sortby = $PROPERTY(..pstats.SortKey,$ZCVT(sortby,"U"))
		} Catch {
			Set sortby = ..pstats.SortKey.CUMULATIVE
		}

		Set ps = ..pstats.Stats(profiler, { "stream": (stream) }...)
		Do ps."sort_stats"(sortby)
		Do ps."print_stats"()

		Set sortby = $P(..builtins.str(sortby),".",*)
		Set results = stream.getvalue()

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

/// 
/// Convert an IRIS result set into a dataframe.<br>
/// If the label column, <var>predictingColumn</var>, is defined,then rows with missing values in the label column will be excluded from the dataframe.
/// 
Method %ResultSetToDataFrame(data As %SQL.StatementResult, ByRef info As %RegisteredObject, ByRef df As %RegisteredObject, ByRef count As %Integer, predictingColumn As %String) As %Status
{
	#dim status As %Status = $$$OK
	Try {
		#dim rawrows, raw As %List
		#dim rows, row As %SYS.Python
		#dim keys As %SYS.Python
		#dim cc, col, i, count As %Integer
		#dim columns As %List

		If '..initialized {
			Set status = ..%OnInit()
			Quit:$$$ISERR(status)
		}

		Set status = ..%ResultSetMetaData(data, .info, .columns, .types)
		Quit:$$$ISERR(status)

		Set count = 0
		Set requirepreprocess = 0
		Set cc = $LL(columns)
		Set keys = ..builtins.list()
		For i=1:1:cc {
			Set currCol = $LG(columns,i)
			Do keys.append(currCol)	// NOTE: Column names are lower case
			if $D(predictingColumn) && (currCol=$G(predictingColumn)){ //APV091 - The $D(predictingColumn) condition has been added to ensure predictingColumnIdx is only set for non-TimeSeries runs. As a result, the omission of rows with null labels will only happen for non-TS models
				Set predictingColumnIdx = i
			}
			
			// Check if this table has a column that requires preprocessing
			if $CASE($LI(types,i),$$$ODBCTYPElongvarchar:1,$$$ODBCTYPEtimestamp:1,$$$ODBCTYPEtime:1,$$$ODBCTYPEdate:1,:0) {
				Set requirepreprocess=1
			}
		}

		// Create an array of rows
		Set rows = ""
		
		Set chunks = ..builtins.list()
		While (data.%GetRows(1000,.rawrows,.status) || rawrows) && $$$ISOK(status) {
			set rawrowlist = ""
			For i=1:1:rawrows {
				If $D(predictingColumnIdx) && ($LI(rawrows(i), predictingColumnIdx)=""){ // APV077
						Continue
				}
				if (requirepreprocess = 1) {
					For col=1:1:cc{
						Set column = ""
						Set odbctype = $LI(types,col)
						if (odbctype = $$$ODBCTYPElongvarchar) {
							Set streamIn = ##class(%Stream.Object).%Open($LG(rawrows(i),col))
							set lt = streamIn.LineTerminatorGet()
							While 'streamIn.AtEnd {
								Set streamChunk = streamIn.Read(,.sc) 
								If $$$ISERR(sc) {
									Set myex = ##class(%Exception.General).%New("Stream Read Error","999",,"%ML.AutoML.Provider.ResultSetToDataFrame %Stream Read error") 
									Throw myex
								}
								Set column = column _ streamChunk
							}
							set $LIST(rawrows(i),col) = $REPLACE(column,lt,$C(10))
						} elseif ($case(odbctype,$$$ODBCTYPEtimestamp:1,$$$ODBCTYPEtime:1,$$$ODBCTYPEdate:1,:0)) {
							if $LG(rawrows(i),col)="" {
								Set column = ""
							} else {
								if (odbctype = $$$ODBCTYPEtimestamp) {
									if ($LG(rawrows(i),col)[" "){
										Set column = $LG(rawrows(i),col)
									} else {
										Set column = ##class(%Library.PosixTime).LogicalToOdbc($LG(rawrows(i),col))
									}
								} elseif (odbctype = $$$ODBCTYPEdate) {
									Set column = $ZD($LG(rawrows(i),col),3)
								} else {
									Set column = $p($zdatetime(0_","_$LG(rawrows(i),col),3,5),"-",1,3)
								}
							}
							set $LIST(rawrows(i),col) = column
						}
					}
				}
				set targetRow = $LB(rawrows(i))
				if ($length(targetRow)+$length(rawrowlist))>$$$MaxStringLength {
					if rawrowlist '= "" {
						Set chunk = $system.Python.To2DListTyped(rawrowlist, types)
						Do chunks.append(chunk)
					}
					set rawrowlist = ""
				}
				set rawrowlist = rawrowlist _ targetRow
				Set count = count + 1
			}
			if rawrowlist '= "" {
				Set chunk = $system.Python.To2DListTyped(rawrowlist, types)
				Do chunks.append(chunk)
			}
		}
		set itertools = ##class(%SYS.Python).Import("itertools")
		Set rows = ..builtins.list(itertools.chain."from_iterable"(chunks))

		// Construct a dataframe
		Set df = ..pandas.DataFrame(rows, , keys)
		If '$IsObject(df) {
			Set status = $$$ERROR($$$PythonGeneralError,$GET(df))
			Quit
		}
		// Success!
	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit $SELECT($$$ISERR(status):$$$EMBEDSC($$$ERROR($$$MLCannotCreateDataframe), status), 1:$$$OK)
}

/// 
/// Determine the metadata for a result set
/// 
ClassMethod %ResultSetMetaData(data As %SQL.StatementResult, ByRef info As %RegisteredObject, ByRef columns As %List, ByRef types As %List) As %Status
{
	#dim status As %Status = $$$OK
	Try {

		// First, let's determine the type information for this resultset
		Set metadata = data.%GetMetadata()

		If '$IsObject(metadata) || 'metadata.columnCount {
			Set status = $$$ERROR($$$MLNoMetadataAvailable)
			Quit
		}

		Set info = {}
		Set columns = ""
		Set types = ""
	
		Set cc = metadata.columnCount
		For i=1:1:cc {
			Set column = metadata.columns.GetAt(i)
			Set type = $SELECT(column.property.Collection=""	:column.property.Type_":"_column.property.Collection,
							   column.colName="ID"				:"%Library.String",
							   column.property.Type'=""			:column.property.Type,
							   1								:"%Library.String")
	
#;			Set type = $SELECT(column.property'=""&&(column.property.Collection="")	 :column.property.Type_":"_column.property.Collection,
#;					   column.isRowId||(column.isIdentity)						:"%Library.String",
#;					   column.typeClass.Name'=""							:column.typeClass.Name,
#;					   1										:"%Library.String")
			// Collect up type info and key names (use lowercase names)
			Set name = $ZCVT(column.colName,"l")
			Do info.%Set(name, type)
			Set columns = columns _ $LB(name)
			Set types = types _ $LB(column.ODBCType)
		}

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

/// 
/// Map an automl error to a %Status
/// 
ClassMethod maperror(error As %String, text As %String) As %Status [ CodeMode = expression, Internal ]
{
$CASE(error,
	"NoFeatures"            :$$$ERROR($$$MLNoFeatures),
	"NoIDColumn"            :$$$ERROR($$$MLNoIDColumn),
	"NoProbInRegression"    :$$$ERROR($$$MLNoProbInRegression),
	"PosLabelNotFound"      :$$$ERROR($$$MLPosLabelNotFound),
	"PosLabelNeeded"        :$$$ERROR($$$MLPosLabelNeeded),
	"NoPosLabelInRegression":$$$ERROR($$$MLNoPosLabelInRegression),
	"LabelNotFound"         :$$$ERROR($$$MLLabelNotFound),
	"LabelOnlyOneValue"     :$$$ERROR($$$MLLabelOnlyOneValue),
							:$$$ERROR($$$MLGeneralError,error,text))
}

/// 
/// Convert an IRIS temp file into Python Pandas DataFrame data
Method %TempFileToDataFrame(columns As %List, types As %List, tfn As %Integer, argspos As %List, ByRef df As %SYS.Python, ByRef count As %Integer, mtorder As %List, mtunary As %List) As %Status
{
	#dim status As %Status = $$$OK
	Try {
#if 0	// Quicker to build a CSV and convert to a dataframe ... but Don's code doesn't like the contents (some of the values need
		// to be converted).

		#dim csv, buffer, segment, bio As %SYS.Python
		#dim counter As %Integer
		#dim needsmap As %Boolean = 0
		#dim cc As %Integer
		#dim napos As %Integer

		If '..initialized {
			Set status = ..%OnInit()
			Quit:$$$ISERR(status)
		}

		Set cc = $LL(columns)
		Set napos = $LL(argspos)
	
		If napos=cc {
			For i = 1:1:napos {
		   		If $LI(argspos)'=i {
					Set needsmap = 1
					Quit
				}
			}
		} Else {
			Set needsmap = 1
		}

		Set csv = ..builtins.bytearray()
		Set buffer = $ZCVT($LTS(columns,",",1),"O","UTF8")_$C(13,10)
		Set count = 0

		// Let's build CSV out of the data in the temp global
		Set counter = ""
		For {
			Set counter = $ORDER(^IRIS.Temp.SQL(tfn,counter),1,raw)
			Quit:counter=""

			// We need to gather the rows we're predicting on, the tempfile will contain
			// other rows such as foreign row IDs used for joining
			If needsmap {
				Set row=""
				For i=1:1:napos {
					Set pos = $LI(argspos,i)
					Set row = row _ $LB($LI(raw,pos))
				}
				Set raw = row
			}

			Set row = $LTS(raw,",",3)_$C(13,10)
			Try {
				// Using Try/Catch is as fast as checking $$$MaxLocalLength and means that
				// if there's any $ZCVT() expansion trickyness (i.e. some wide chars can
				// become 3-4 bytes in length), it'll be handled.
				Set buffer = buffer _ $ZCVT(row,"O","UTF8")
			} Catch {
				Set segment = ##class(%SYS.Python).Bytes(buffer)
				Do csv.extend(segment)
				Set buffer = ""
			}

			Set count = count + 1
		}

		If $$$ISERR(status) Quit

		// Flush any remaining outout
		If $L(buffer)>0 {
			Set segment = ##class(%SYS.Python).Bytes(buffer)
			Do csv.extend(segment)
		}

		// Success, wrap a byte IO around it
		Set bio = ..io.BytesIO(csv)

		// Construct a dataframe
		Set df = ..pandas."read_csv"(bio)
		If '$IsObject(df) {
			Set status = $$$ERROR($$$PythonGeneralError,$GET(df))
			Quit
		}
#else
		#dim rawrows, raw As %List
		#dim rows, row As %SYS.Python
		#dim keys As %SYS.Python
		#dim cc, col, i, count As %Integer
		#dim columns As %List

		If '..initialized {
			Set status = ..%OnInit()
			Quit:$$$ISERR(status)
		}

		Set cc = $LL(columns)

		Set keys = ..builtins.list()
		For i=1:1:cc {
			Do keys.append($LG(columns,i))
		}

		// Create an array of rows
		Set rows = ..builtins.list()
		Set count = 0

		// Let's build a dataframe out of the data in the temp global
		Set counter = ""
		For {
			Set counter = $ORDER(^IRIS.Temp.SQL(tfn,counter),1,raw)
			Quit:counter=""

			// We need to gather the rows we're predicting on, the tempfile will contain
			// other rows such as foreign row IDs used for joining

			Set row = ..builtins.list()

			For col=1:1:cc {
				// For each column ... (note no need for remapping here since we build row col by col
				Set pos = $LI(argspos,col)
				Set column = ..maptype2python($LI(types,col), $LG(raw,pos))
				Do row.append(column)
			}

			Do rows.append(row)
			Set count = count + 1
		}

		If $$$ISERR(status) Quit

		// Construct a dataframe
		Set df = ..pandas.DataFrame(rows, , keys)
		If '$IsObject(df) {
			Set status = $$$ERROR($$$PythonGeneralError,$GET(df))
			Quit
		}
#endif

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit $SELECT($$$ISERR(status):$$$EMBEDSC($$$ERROR($$$MLCannotCreateDataframe), status), 1:$$$OK)
}

/// 
/// Update temp file #tfn using the data in DataFrame df
/// Inputs:
/// 	tfn: Temp file number
/// 	df: a Python DataFrame
/// 	fieldnames=$lb(field1, ...): A $List of strings that indicates names of fields in df that will be added to temp file #tfn
/// 	positions=$lb(pos1, ...): A list of integers that indicates the corresponding positions of each df field in temp file #tfn
/// 	types=$lb(type1, ...): A list of integers that indicates the corresponding ObjectScript type of each df field in temp file #tfn
/// 	isPredict=$lb(predict1, ...): A list of integers that indicates if each df field is predict or probablity. If predict=1, this is predict, otherwise, probability 
/// 
Method %DataFrameToTempFile(tfn As %Integer, df As %SYS.Python, fieldnames As %List, positions As %List, types As %List, isPredict As %List) As %Status
{
	Set nFields = $ll(fieldnames)
	If $ll(positions)'=nFields Return $$$ERROR($$$MLGeneralError,"Length of positions does not match the lenth of fieldnames!")
	If $ll(types)'=nFields Return $$$ERROR($$$MLGeneralError,"Length of types does not match the lenth of fieldnames!")
	If $ll(isPredict)'=nFields Return $$$ERROR($$$MLGeneralError,"Length of isPredict does not match the lenth of fieldnames!")
	
	For f=1:1:nFields {
		Set field = $lg(fieldnames, f), pos = $lg(positions, f), type = $lg(types,f), predict = $lg(isPredict,f)

		// Predictions is a Python array of prediction values (or probabilities)
		Set predictions = df.get(field)
		If '$IsObject(predictions) {
			Return $$$ERROR($$$MLGeneralError,"DataFrame.get("_field_")","Failed!")
		}

		// Now, process the results ...
		Set count = ..builtins.len(predictions)
		If count = 0 {
			Return $$$ERROR($$$MLNoPredictionResults)
		}

		Set i = ""
		For n=1:1 {
			
			Set i = $ORDER(^IRIS.Temp.SQL(tfn,i),1,raw)
			Quit:i=""

			Set value = ..maptype2iris(type,predictions."__getitem__"(n-1))

			// Replace the updated column in the row
			if predict { Set $LI(raw,pos) = value } else { Set $LI(raw,pos) = $double(value) }
			Set ^IRIS.Temp.SQL(tfn,i) = raw
		}

		If n-1 '= count {
			Return $$$ERROR($$$MLInternalError,"field """_field_""" to tempfile mismatch")
		}
	}
	Return $$$OK
}

/// 
/// Update temp file #tfn using the data in DataFrame df acquired from TimeSeries predictions
/// Inputs:
/// 	tfn: Temp file number
/// 	df: a Python DataFrame
/// 	headers: IRIS table column names
/// 	pcTypes: datetime column name
/// 
Method %TSDataFrameToTempFile(tfn As %Integer, df As %SYS.Python, tsheaders As %SYS.Python, datetimecolumn As %String, channelColumns As %List, channelTypes As %List, mtorder As %List, mtunary As %List) As %Status
{

	set tempfilesize = 0, name = ""
	for tfsidx = 1:1 {
		set name = $ORDER(^IRIS.Temp.SQL(tfn, name))
		QUIT:name=""
		set tempfilesize = tempfilesize + 1
	}

	set tempfileorder = mtorder, tempfiletypes = channelTypes

	set predictions = df.get("predictions")
	set predictHeaders = predictions.columns
	for pidx = 1:1:predictions.shape."__getitem__"(0) { // Loops through predicted rows to add
		set newrow = ""
		for headidx = 1:1:$LL(tempfileorder) { // Loops through temp file order
			set found = -1
			for phidx = 1:1:predictHeaders.shape."__getitem__"(0) { // Loops through headers used for time series prediction, but in original sql table order.
				if $$$LOWER($LG(tempfileorder,headidx)) = $$$LOWER(predictHeaders."__getitem__"(phidx-1)) {
					set found = phidx-1
				}
			}
			if found '= -1 {
				set typefound = $LG(channelTypes, $LF(channelColumns, $$$LOWER($LG(mtorder, headidx))))
				if $LF(mtunary, $$$LOWER($LG(mtorder, headidx))) {
					set newrow = newrow_$lb(..maptype2iris( typefound, predictions.iloc."__getitem__"(pidx-1)."__getitem__"($$$LOWER($LG(tempfileorder,headidx))) ) )
				}
				set newrow = newrow_$lb( ..maptype2iris( typefound, predictions.iloc."__getitem__"(pidx-1)."__getitem__"($$$LOWER($LG(tempfileorder,headidx))) ) )
			}
			else {
				if $LF(mtunary, $$$LOWER($LG(mtorder, headidx))) {
					set newrow = newrow_$lb("")
				}
				set newrow = newrow_$lb("")
			}
		}
		set ^IRIS.Temp.SQL(tfn,tempfilesize+pidx) = newrow
	}
	Return $$$OK
}

/// 
/// Map an IRIS type to a python type
/// 
Method maptype2python(type As %Integer, value) As %String [ CodeMode = expression, Internal ]
{
$CASE(type,
	$$$ODBCTYPEbit				:$S(value="":$DOUBLE("NAN"),1:..builtins.bool(+value)),
	$$$ODBCTYPEnumeric			:$S(value="":$DOUBLE("NAN"),1:+value),
	$$$ODBCTYPEdecimal			:$S(value="":$DOUBLE("NAN"),1:..decimal.Decimal(+value)),
	$$$ODBCTYPEinteger			:$S(value="":$DOUBLE("NAN"),1:+value),
	$$$ODBCTYPEbigint			:$S(value="":$DOUBLE("NAN"),1:+value),
	$$$ODBCTYPEsmallint			:$S(value="":$DOUBLE("NAN"),1:+value),
	$$$ODBCTYPEtinyint			:$S(value="":$DOUBLE("NAN"),1:+value),
	$$$ODBCTYPEreal				:$S(value="":$DOUBLE("NAN"),1:$DOUBLE(value)),
	$$$ODBCTYPEdouble			:$S(value="":$DOUBLE("NAN"),1:$DOUBLE(value)),
	$$$ODBCTYPEtimestamp        :..numpy.datetime64($S(value="":"nat",value[" ":value,1:##class(%Library.PosixTime).LogicalToOdbc(value))),
	$$$ODBCTYPEvarchar			:$S(value="":$DOUBLE("NAN"),value=$C(0):"",1:value_""),
	$$$ODBCTYPEvarbinary		:$S(value="":$DOUBLE("NAN"),1:##class(%SYS.Python).Bytes($S(value=$C(0):"",1:value_""))),
	$$$ODBCTYPEbinary			:$S(value="":$DOUBLE("NAN"),1:##class(%SYS.Python).Bytes($S(value=$C(0):"",1:value_""))),
	$$$ODBCTYPEdate				:..numpy.datetime64($S(value="":"nat",1:$ZD(value,3))),
	$$$ODBCTYPEtime				:$S(value="":..numpy.datetime64("nat"),1:..numpy.datetime64($p($zdatetime(0_","_value,3,5),"-",1,3))),
	$$$ODBCTYPElongvarchar		:1/0,														// TODO!!!!!!!!
	$$$ODBCTYPElongvarbinary	:1/0,														// TODO!!!!!!!!
								:$S(value="":$DOUBLE("NAN"),value=$C(0):"",1:value))
}

/// 
/// Map a Python type to IRIS
/// 
Method maptype2iris(type As %Integer, value) As %String [ CodeMode = expression, Internal ]
{
$SELECT(value=##class(%SYS.Python).None():"", value=$DOUBLE("NAN"):"", 1:$CASE(type,
	$$$ODBCTYPEbit				:..builtins.int(value)'=0,
	$$$ODBCTYPEnumeric			:..builtins.float(value),
	$$$ODBCTYPEdecimal			:+..builtins.str(value),
	$$$ODBCTYPEinteger			:..builtins.int(value),
	$$$ODBCTYPEbigint			:+..builtins.str(value),
	$$$ODBCTYPEsmallint			:..builtins.int(value),
	$$$ODBCTYPEtinyint			:..builtins.int(value),
	$$$ODBCTYPEreal				:$DOUBLE(..builtins.float(value)),
	$$$ODBCTYPEdouble			:$DOUBLE(..builtins.float(value)),
	$$$ODBCTYPEtimestamp		:..pyval2str(value),
	$$$ODBCTYPEvarchar			:..pyval2str(value),
	$$$ODBCTYPEdate				:+$ZDTH(..builtins.str(value)),
	$$$ODBCTYPEtime				:+$P($ZDTH("1/1/1 "_..builtins.str(value)),",",2),
	$$$ODBCTYPElongvarchar		:1/0,														// TODO!!!!!!!!
	$$$ODBCTYPElongvarbinary	:1/0,														// TODO!!!!!!!!
								:value))
}

/// 
/// Convert a python value to an SQL string
/// 
Method pyval2str(pyval) As %String [ CodeMode = expression ]
{
$SELECT($IsObject(pyval):..builtins.str(pyval),pyval="":$C(0),1:pyval_"")
}

}
