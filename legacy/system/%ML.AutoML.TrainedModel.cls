/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occODBC

/// 
/// Class for a trained AutoML model instance
/// 
Class %ML.AutoML.TrainedModel Extends %ML.TrainedModel [ ClassType = persistent ]
{

/// Serialized model state
Property ModelState As %Stream.GlobalCharacter;

/// Provider instance
Property automlprovider As %ML.AutoML.Provider [ Internal, Transient ];

/// AutoML model
Property modelinstance As %SYS.Python [ Internal, Transient ];

/// Cached column names
Property WithColumnNames As %List [ Internal ];

/// Cached column types
Property WithColumnTypes As %List [ Internal ];

/// Python Column Info
Property columnnames As %SYS.Python [ Internal, Transient ];

/// Profiler
Property profiler As %SYS.Python [ Internal, Transient ];

/// 
/// Factory method to create a trained model
/// 
ClassMethod %CreateTrainedModel(provider As %ML.AutoML.Provider, trainingrun As %ML.TrainingRun, ByRef trainedmodel As %ML.AutoML.TrainedModel) As %Status
{
	#dim status As %Status = $$$OK
	Try {
		#dim col As %Integer

		Set trainedmodel = ..%New()
		Set trainedmodel.ModelName      = trainingrun.Name
		Set trainedmodel.Provider       = provider.%ClassName(1)
		Set trainedmodel.Model          = trainingrun.Model
		Set trainedmodel.TrainingRun    = trainingrun
		Set trainedmodel.TrainedAt      = trainingrun.CompletedAt		

		// Set up the cached column headers
		For col = 1:1:trainedmodel.Model.WithColumnNames.Count() {
			// NOTE: We use lower-case column names
			Set trainedmodel.WithColumnNames = trainedmodel.WithColumnNames _ $LB($ZCVT(trainedmodel.Model.WithColumnNames.GetAt(col),"l"))
			Set trainedmodel.WithColumnTypes = trainedmodel.WithColumnTypes _ $LB(trainedmodel.Model.WithColumnTypes.GetAt(col))
		}

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

/// 
/// Load a serialized model 
/// 
Method %LoadModel() As %Status
{
	#dim status As %Status = $$$OK
	Try {
		If '$IsObject(..automlprovider) {
			Set ..automlprovider = ##class(%ML.AutoML.Provider).%New()
			
			Set status = ..automlprovider.%OnInit()
			Quit:$$$ISERR(status)
		}

		If '$IsObject(..modelinstance) {
			// Get the serialized model state
			Do ..ModelState.Rewind()
			
			If ..ModelState.Size<$$$MaxLocalLength {
				Set modelstate = ..ModelState.Read(..ModelState.Size,.status)
				Quit:$$$ISERR(status)

				// Explicitly create this as bytes rather than a string (which is UTF-8)
				Set modeldata = ##class(%SYS.Python).Bytes(modelstate)
			} Else {
				// Need to build this up in chunks
				Set modeldata = ..automlprovider.builtins.bytearray()
				For {
					Set modelstate = ..ModelState.Read($$$MaxLocalLength-1,.status)
					Quit:$$$ISERR(status)

					// Check for end of the stream
					Quit:modelstate=""

					// Explicitly create this as bytes rather than a string (which is UTF-8)
					Set data = ##class(%SYS.Python).Bytes(modelstate)

					Do modeldata.extend(data)
				}

				// Convert to regular bytes
				Set modeldata = ..automlprovider.builtins.bytes(modeldata)
			}
			
			if $THIS.ModelType '= "timeseries" {
				Set tm = ..automlprovider.automl.TrainedModel(modeldata)
				If '$IsObject(tm) {
					Set status = $$$ERROR($$$MLGeneralError,"automl.TrainedModel() failed")
					Quit
				}
			}
			else {
				Set tm = ..automlprovider.automlts.TrainedModel(modeldata)
				If '$IsObject(tm) {
					Set status = $$$ERROR($$$MLGeneralError,"automlts.TrainedModel() failed")
					Quit
				}
			}

			Set ..modelinstance = tm
		}
	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

/// 
/// Bulk Predict
/// 
/// arguments:
/// 	tfn		 - tempfile index
/// 	argspos		 - Positions of the WithColumns in the temp rows, $list(column-positions)
/// 	predpos		 - Position of the predicted value, $list(result-column-positions)
/// 	probpos		 - Position of the probability value, $list(result-column-positions)
/// 	expr		 - expression for probability
/// returns:
/// 	$$$OK on success, otherwise a $$$ERROR(...)
/// 
Method %PredictAll(tfn As %Integer, argspos As %List, predpos As %List, probpos As %List = "", expr As %String = "", mtorder As %List, mtunary As %List) As %Status
{
	#dim status As %Status = $$$OK
	Try {
		If '$IsObject(..automlprovider) {
			Set ..automlprovider = ##class(%ML.AutoML.Provider).%New()
			
			Set status = ..automlprovider.%OnInit()
			Quit:$$$ISERR(status)
		}
		if ..ModelType'="timeseries" {
			Set status = ..automlprovider.%PredictAll($THIS, tfn, argspos, predpos, probpos, expr)
		}
		else {
			Set status = ..automlprovider.%PredictAll($THIS, tfn, argspos, predpos, probpos, expr, mtorder, mtunary)
		}
		Quit:$$$ISERR(status)

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

/// 
/// Begin trained model operations
/// 
Method %Begin() As %Status
{
	#dim status As %Status = $$$OK
	Try {
		Do ##class(%SYS.Python).ConfigureAutoML("lib/automl")
		Do ##class(%SYS.Python).ChangeSignalState(1)

		// Load the model (note will set up the provider if needed)
		If '$IsObject(..modelinstance) {
			Set status = ..%LoadModel()
			Quit:$$$ISERR(status)
		}

		// Set up the column headers for building dataframes
		If '$IsObject(..columnnames) {
			Set cc = $LL(..WithColumnNames)
			Set keys = ..automlprovider.builtins.list()
			For i=1:1:cc {
				Do keys.append($LG(..WithColumnNames,i))	// NOTE: We use lower-case column names
			}
			Set ..columnnames = keys
		}

		if ..TrainingRun.Settings.%IsDefined("profile") {
			Set status = ..automlprovider.%StartProfiler(..TrainingRun.Settings.profile, .profiler)
			Quit:$$$ISERR(status)

			Set ..profiler = profiler
		}

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

/// 
/// End trained model operations
/// 
Method %End() As %Status
{
	#dim status As %Status = $$$OK
	Try {

		// We leave stuff around to be cached for more prediction runs, in the event of a
		// re-train, then a new instance of this class will be created.

		If $IsObject(..profiler) {
			Set sortkey = $s(..TrainingRun.Settings.%IsDefined("profile"):..TrainingRun.Settings.profile,1:-1)
			Set status = ..automlprovider.%StopProfiler(..profiler, .sortkey, .results)
			Quit:$$$ISERR(status)

			Do ..TrainingRun.Log.MoveToEnd()
			Do ..TrainingRun.LogMsg("Profile using: "_..automlprovider.builtins.str(sortkey))
			Set results = $TR(results,$C(13))
			For i=1:1:$L(results,$C(10)) {
				Do ..TrainingRun.Log.WriteLine($P(results,$C(10),i))
			}

			// Must save this ...
			Set status = ..TrainingRun.Log.%Save()

			Set ..profiler = $$$NULLOREF
		}

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

/// 
/// Predict on an ML model
/// 
Method %Predict(data As %List, ByRef results As %List) As %Status
{
	#dim status As %Status = $$$OK
	Try {
		Set type = ..Model.PredictingColumnTypes.GetAt(1)
		Set builtins = ..automlprovider.builtins
		Set row = builtins.list()
		Set rows = builtins.list()
		
		Set cc = $LL(..WithColumnTypes)
		For col=1:1:cc {
			// For each column ...
			Set column = ..automlprovider.maptype2python($LI(..WithColumnTypes,col), $LG(data,col))
			Do row.append(column)
		}

		Do rows.append(row)

		Set df = ..automlprovider.pandas.DataFrame(rows, , ..columnnames)	// NOTE: Lower-case column names
		If '$IsObject(df) {
			Set status = $$$ERROR($$$PythonGeneralError,$GET(df))
			Quit
		}

		// Now, PREDICT()
		Set result = ..modelinstance.predict(df, 0)

		If '$IsObject(result) {
			Set status = $$$ERROR($$$MLGeneralError,"automl.predict()","Failed!")
			Quit
		}

		If result.get("status") '= "200" {
			Set status = ##class(%ML.AutoML.Provider).maperror(result.get("error"),result.get("text"))
			Quit
		}
		
		// Predictions is an array prediction values (or probabilities)
		Set predictions = result.get("predictions")
		If '$IsObject(predictions) {
			Set status = $$$ERROR($$$MLGeneralError,"result.get()","Failed!")
			Quit
		}

		Set count = builtins.len(predictions)
		If count = 0 {
			Set status = $$$ERROR($$$MLNoPredictionResults)
		}
		
		Set results = $LB(..automlprovider.maptype2iris(type,predictions."__getitem__"(0)))

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

/// 
/// Predict probability on an ML model
/// Arguments:
/// 	expr:     The argument of PROBABILITY's FOR clause, defaults to 1
/// 	data:     $List of WITH clause values
/// 	results:  PBR, return value
Method %Probability(expr As %String = 1, data As %List, ByRef results As %List) As %Status
{
	#dim status As %Status = $$$OK
	Try {
		Set builtins = ..automlprovider.builtins
		Set row = builtins.list()
		Set rows = builtins.list()
		
		Set cc = $LL(..WithColumnTypes)
		For col=1:1:cc {
			// For each column ...
			Set column = ..automlprovider.maptype2python($LI(..WithColumnTypes,col), $LG(data,col))
			Do row.append(column)
		}

		Do rows.append(row)

		Set df = ..automlprovider.pandas.DataFrame(rows, , ..columnnames)
		If '$IsObject(df) {
			Set status = $$$ERROR($$$PythonGeneralError,$GET(df))
			Quit
		}

		// Now, PROBABILITY()
		Set result = ..modelinstance.probability(df, expr, 0)

		If '$IsObject(result) {
			Set status = $$$ERROR($$$MLGeneralError,"automl.probability()","Failed!")
			Quit
		}

		If result.get("status") '= "200" {
			Set status = ##class(%ML.AutoML.Provider).maperror(result.get("error"),result.get("text"))
			Quit
		}
		
		// Predictions is an array prediction values (or probabilities)
		Set predictions = result.get("predictions")
		If '$IsObject(predictions) {
			Set status = $$$ERROR($$$MLGeneralError,"result.get()","Failed!")
			Quit
		}

		Set count = builtins.len(predictions)
		If count = 0 {
			Set status = $$$ERROR($$$MLNoPredictionResults)
		}
		
		Set results = $LB(..automlprovider.maptype2iris($$$ODBCTYPEdouble,predictions."__getitem__"(0)))

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

Storage Default
{
<Data name="TrainedModelDefaultData1">
<Subscript>"TrainedModel"</Subscript>
<Value name="1">
<Value>ModelState</Value>
</Value>
<Value name="2">
<Value>WithColumnNames</Value>
</Value>
<Value name="3">
<Value>WithColumnTypes</Value>
</Value>
</Data>
<DefaultData>TrainedModelDefaultData1</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
