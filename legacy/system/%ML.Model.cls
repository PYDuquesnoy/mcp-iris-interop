/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occErrors

/// 
/// Definition of a ML model
/// 
Class %ML.Model Extends %Persistent [ ClassType = persistent, System = 4 ]
{

/// Name of the model
Property Name As %String(MAXLEN = 256) [ Required ];

/// Model description
Property Description As %String(MAXLEN = 8192);

/// Column Name(s) we're predicting
Property PredictingColumnNames As list Of %String(MAXLEN = 128) [ Required ];

/// Column Types(s) we're predicting
Property PredictingColumnTypes As list Of %String(MAXLEN = 128) [ Required ];

/// Columns names we're predicting using
Property WithColumnNames As list Of %String(MAXLEN = 128) [ Required ];

/// Columns types we're predicting using
Property WithColumnTypes As list Of %String(MAXLEN = 128) [ Required ];

/// Columns text we're predicting using, text from SQL query or with expression
Property WithColumnText As list Of %String(MAXLEN = 512) [ Required ];

/// Have we found an ID column that would otherwise be trained on by default if we did not exclude it
Property DefaultIDColumnFound As %Boolean [ InitialExpression = 0, Required ];

/// Is this a timeseries model?
Property TimeSeries As %Boolean [ InitialExpression = 0, Required ];

/// What is the datetime column for a timeseries model?
Property DateTimeColumn As %String(MAXLEN = 128);

/// How far forward are we predicting? Important for validation.
Property Forward As %Integer;

/// What time step size was returned (DataRobot Exclusive)
Property TimeStep As %String(MAXLEN = 128);

/// What is the calculated forward window? (DataRobot Exclusive)
Property ForwardResponse As %String(MAXLEN = 128);

/// Model parameters
Property DefaultParameters As array Of %String(MAXLEN = 1024);

/// Default training query (SQL)
Property DefaultTrainingQuery As %String(MAXLEN = 32000);

/// Timestamp for when the model was created (UTC)
Property CreatedAt As %TimeStamp [ InitialExpression = {$ZDATETIME($ZTIMESTAMP,3,1,3)}, Required ];

/// Default trained model
Property DefaultTrainedModel As %ML.TrainedModel;

/// Index on the model name
Index NameIndex On Name [ Data = Name, PrimaryKey, Type = index, Unique ];

/// 
/// Train an ML model (synchronously)
/// 
Method %Train(data As %SQL.StatementResult, ByRef trainedmodelname As %String, ByRef trainedmodel As %ML.TrainedModel, ByRef trainingrun As %ML.TrainingRun, using As %DynamicObject = {$$$NULLOREF}, notdefault As %Boolean = 0) As %Status
{
	#dim status As %Status = $$$OK
  	#dim provider As %ML.Provider
	#dim trainkey
	#dim gotlock As %Boolean = 0
	#dim key,providerName,value As %String
	#dim configUsingJSON,settings As %Library.DynamicObject
	#dim iter As %Iterator.Object

	Try {
		
		if '$d(trainingrun) { Set trainingrun = ##class(%ML.TrainingRun).%New() }	// Might have been instantiated in TrainModel^%apiDDL
		Set trainingrun.Model = $THIS
		Set:trainingrun.TrainingQuery="" trainingrun.TrainingQuery = ..DefaultTrainingQuery	// Might have been set in TrainModel^%apiDDL
		if $g(trainedmodelname)'="" {		// TRAIN MODEL x AS tx ... specified
			new %ROWCOUNT,%ROWID,%msg
			&sql(delete from %ML.TrainedModel where ModelName = :trainedmodelname)
			if SQLCODE<0 {
				set status=$$$ERROR($$$SQLError,SQLCODE,"Failed to delete %ML.TrainedModel named '"_trainedmodelname_"' with message: "_$g(%msg))
				set trainingrun.RunStatus="failed"
				do MarkTrainingRunFailed(.status)
				quit
			}
			&sql(delete from %ML.TrainingRun where Name = :trainedmodelname)
			if SQLCODE<0 {
				set status=$$$ERROR($$$SQLError,SQLCODE,"Failed to delete %ML.TrainingRun named '"_trainedmodelname_"' with message: "_$g(%msg))
				set trainingrun.RunStatus="failed"
				do MarkTrainingRunFailed(.status)
				quit
			}
			set trainingrun.Name=trainedmodelname	// TRAIN MODEL x AS tx ... specified
		}
		
		
			// get the provider from current's user's ML Configuration
		set providerName=##class(%SYS.ML.Configuration).%GetProviderFromName($system.Context.SQL().MLConfiguration,.status)
		if $$$ISERR(status) {
			do:trainingrun.RunStatus'="failed" MarkTrainingRunFailed(.status)
			quit
		}
		
		// Record the requested provider as soon as we figure it out ... it should be
		// part of the trainingrun even if it doesn't exist
		Set trainingrun.Provider = $S(providerName'="":providerName,1:##class(%ML.Provider).#DEFAULTPROVIDER)

		Set status = ##class(%ML.Provider).%CreateProvider(providerName,.provider)
		if $$$ISERR(status) {
			do:trainingrun.RunStatus'="failed" MarkTrainingRunFailed(.status)
			quit
		}
		
		// define trainingrun.Configuration
		set mlconfig=##class(%SYS.ML.Configuration).NameIndexOpen($system.Context.SQL().MLConfiguration,,.sc)
		if $isobject(mlconfig) { set trainingrun.Configuration=mlconfig } // error if mlconfig=""?

		// Define the provider and settings for this training
		Set trainingrun.Provider = provider.%GetName()
		Set trainingrun.Settings = {}

		// Apply any default settings for this provider
		set settings={}
		do provider.%GetDefaultSettings(.settings)
		set trainingrun.Settings=settings

		// Apply any default settings (DefaultParameters) from the model
		set key=""
		for  {
			set value=..DefaultParameters.GetNext(.key) quit:key=""
			do trainingrun.Settings.%Set(key,value)
		}
		
		// Apply settings from using property of process's current ML Configuration
		if mlconfig.Using'="" {
			set configUsingJSON={}.%FromJSON(mlconfig.Using)
			set iter = configUsingJSON.%GetIterator()
			while iter.%GetNext(.key,.value) { do trainingrun.Settings.%Set(key,value) }
		}

		// Apply the settings from the TRAIN statement (if given)
		If $IsObject(using) {
			set iter = using.%GetIterator()
			while iter.%GetNext(.key,.value) { do trainingrun.Settings.%Set(key,value) }
		}

			// Note, this is the first time the persistent record for TrainingRun exists (unless %CreateProvider failed above).
		Do trainingrun.LogMsg("Starting Training for "_..Name)
		Set status = trainingrun.%Save()
		Quit:$$$ISERR(status)

			// Acquire a lock that will be used to indicate if the TrainingRun is actually in training or if the process no longer exists
			// If another process sees the RunStatus="training" and can acquire the lock, the training process died
			// If another process sees the RunStatus="training" and cannot acquire the lock, the training process is still active
		lock +^IRIS.ML.TrainingRun(trainingrun.%Id()):$zu(115,5)
		if '$test { set status=$$$ERROR($$$MLTrainingRunLock,trainingrun.Name) Quit } else { set gotlock=1 }
		
			// We set the trainingrun.name in %BeginTraining if the trainedmodelname was specified by the statement
		Set status = provider.%BeginTraining($THIS, data, trainingrun, .trainedmodelname, .trainkey)
		if $$$ISERR(status) {
			do:trainingrun.RunStatus'="failed" MarkTrainingRunFailed(.status)
			Quit
		}

		Set status = provider.%WaitForTraining(trainkey, trainingrun, .trainedmodel, -1)
		if $$$ISERR(status) {
			do:trainingrun.RunStatus'="failed" MarkTrainingRunFailed(.status)
			Quit
		}

		If trainingrun.RunStatus = "completed",'notdefault {
			// If training was successful, this becomes the default trained model (unless it was requested this not be the default model)
			// The SQL syntax to specify this is TRAIN <model> [ AS <trainedname> ] NOT DEFAULT ...
			do:..DefaultTrainedModel.ModelName'="" DeleteExtentCQ^%SYS.SQLSRV(..DefaultTrainedModel.ModelName)	// if the default trained model changes, purge cached queries using this default trained model
			Set ..DefaultTrainedModel = trainedmodel
			Set status = ..%Save()
		}

	} Catch (ex) {
		set status = ex.AsStatus()
		do MarkTrainingRunFailed(.status)
	}
	lock:gotlock -^IRIS.ML.TrainingRun(trainingrun.%Id())
	Quit status

MarkTrainingRunFailed(&status)
	if trainingrun.RunStatus'="failed" {
		set trainingrun.RunStatus="failed"
		set:trainingrun.StatusCode=$$$OK trainingrun.StatusCode=status
		set sc=trainingrun.%Save()
		if $$$ISERR(sc) set status=$$$ADDSC(status,sc)
	}
	QUIT
}

/// 
/// Predict
/// 
Method %Predict(rowdata As %List, ByRef result As %Double, contextitem As %RawString) As %Status
{
	#dim status As %Status = $$$OK
	Try {
		set result=""
			// if $g($system.Context.SQL().PredictTrainedModelOref(contextitem))="", that means the PREDICT did not specify a USE clause and we should use the DefaultTrainedMode
		if $g($system.Context.SQL().PredictTrainedModelOref(contextitem))="" { set $system.Context.SQL().PredictTrainedModelOref(contextitem)=..DefaultTrainedModel }
		If '$IsObject($system.Context.SQL().PredictTrainedModelOref(contextitem)) {
			Set status = $$$ERROR($$$MLMissingTrainedModel)
			Quit
		}

		if '$d($system.Context.SQL().PredictTrainedModelOref(contextitem,"%Begin")) {	// only call %Begin for the first row we are predicting
			Set status = $system.Context.SQL().PredictTrainedModelOref(contextitem).%Begin()
			Quit:$$$ISERR(status)
			set $system.Context.SQL().PredictTrainedModelOref(contextitem,"%Begin")=1
		}
		
		Set status = $system.Context.SQL().PredictTrainedModelOref(contextitem).%Predict(rowdata, .result)
		Quit:$$$ISERR(status)
		
		set:$listvalid(result) result=$lg(result,1)	// result is returned as a $List, extract the single value to return byref

	} Catch (ex) {
		Set status = ex.AsStatus()
	}

	// $system.Context.SQL().PredictTrainedModelOref(contextitem).%End() will be called at query close.  We do not close it for each row predicted.  %Begin once in for first row predicted, %End once at end
	
	Quit status
}

/// 
/// Probability
/// 
Method %Probability(rowdata As %List, ByRef result As %Double, ByRef trainedmodel As %ML.TrainedModel = "", expr As %String = 1) As %Status
{
	#dim status As %Status = $$$OK
	#dim tmoref As %ML.TrainedModel = $$$NULLOREF
	Try {
		if trainedmodel'="" { set tmoref=trainedmodel }
		else                { set tmoref=..DefaultTrainedModel }

		If '$IsObject(tmoref) {
			Set status = $$$ERROR($$$MLMissingTrainedModel)
			Quit
		}

		Set status = tmoref.%Begin()
		Quit:$$$ISERR(status)
		
		Set status = tmoref.%Probability(expr,rowdata, .result)
		Quit:$$$ISERR(status)

		set:$listvalid(result) result=$lg(result,1)	// result is returned as a $List, extract the single value to return byref

	} Catch (ex) {
		Set status = ex.AsStatus()
	}

	If $IsObject(tmoref) {
		// NOTE: Always clean up even on error (and we ignore any errors from %End)
		Do tmoref.%End()
	}

	Quit status
}

/// 
/// Bulk Predict
/// 
/// arguments:
/// 	modelname	 - model name
/// 	trainedmodelname - name of %ML.TrainedModel, might be different from the DefaultTrainedModel
/// 	tfn		 - tempfile index
/// 	argspos		 - Positions of the WithColumns in the temp rows, $list(column-positions)
/// 	predpos		 - Position of the predicted value, $list(result-column-positions)
/// 	probpos		 - Position of the probability value, $list(result-column-positions)
/// 	expr		 - expression for probability
/// returns:
/// 	$$$OK on success, otherwise a $$$ERROR(...)
/// 
ClassMethod %PredictAll(modelname As %String, trainedmodelname As %String = "", tfn As %Integer, argspos As %List, predpos As %List = "", probpos As %List = "", expr As %String = 1, mtorder As %List, mtunary As %List) As %Status
{
	#dim status As %Status = $$$OK
	#include ftdefs
	Try {
		#dim counter,i,pos,predict,ptr As %Integer = ""
		#dim raw,result,rowdata As %List
		#dim model As %ML.Model
		#dim tmoref As %ML.TrainedModel
		#dim provider As %String

		Set model = ..NameIndexOpen(modelname,,.status)
		Quit:$$$ISERR(status)

			// if trainedmodelname is given, use that trainedmodel, otherwise use the DefaultTrainedModel
		if trainedmodelname'="" {
			set tmoref=##class(%ML.TrainedModel).NameIndexOpen(trainedmodelname,,.status)
			Quit:$$$ISERR(status)
		} else { set tmoref=model.DefaultTrainedModel }
		If '$IsObject(tmoref) {
			Set status = $$$ERROR($$$MLMissingTrainedModel)
			Quit
		}

		set provider=$p(tmoref.Provider,".",2)
		if $g(tfn)'="",'$d(^IRIS.Temp.SQL(tfn)) { RETURN $$$OK }  // No data in temp file, most likely query returns no data

			// Allow for a custom implementation ...
		if tmoref.ModelType'="timeseries" {
			Set status = tmoref.%PredictAll(tfn,argspos,predpos,probpos,expr)
		}
		else {
			/// let's pass along limitted headers or some info about how to limit headers
			/// let's also pass along datetime col name i.e. BY ()
			Set status = tmoref.%PredictAll(tfn,argspos,predpos,probpos,expr,mtorder,mtunary)
		}
		if status=$$$OK {
			if predpos'="" {	// only for PREDICT, not PROBABILITY
					// Record that we trained a model in Feature Tracker
				do:$d($SYSTEM.Context.SQL().FTKeys)'=11 FTKeysSetup^%apiSQL()
				do $$$FTINCREMENT($system.Context.SQL().FTKeys("IntegratedML.Predict"_provider))
			}
			Quit
		}
		Quit:$$$ERRORCODE(status)'=$$$NotImplemented	// %PredictAll got an error other than NotImplemented

			// %PredictAll returned $$$NotImplemented
			// ONCE all providers have a %PredictAll method, we can eliminate the by-row Predict logic.
			// Bulk %Predict() default implementation - per row
			// As of 03/26/2020, PMML is the only provider without %PredictAll
		
		set predict=''$ll(predpos)	// We can od predict or probability, not both
		Set status = model.DefaultTrainedModel.%Begin()
		For {
			set counter = $ORDER(^IRIS.Temp.SQL(tfn,counter))
			quit:counter=""
				// We need to gather the columns from the tempfile we're predicting on
				// The tempfile will contain other columns needed for the main query
			set raw=^IRIS.Temp.SQL(tfn,counter)
			set rowdata="",ptr=0,i=0
			while $listnext(argspos,ptr,pos) { set i=i+1,$li(rowdata,i)=pos }
			if predict {
				set status=tmoref.%Predict(rowdata, .result)
				quit:$$$ISERR(status)   // Quit the loop ...
					// Inject the predicted value(s) [ likely just one ]
				set ptr=0,i=0
				while $listnext(predpos,ptr,pos) { set i=i+1,$li(raw,pos)=$li(result,i) }
			} else {	// probability
				set status=tmoref.%Probability(,rowdata, .result)	// first arg is FOR clause, defaults to 1
				quit:$$$ISERR(status)   // Quit the loop ...
					// Inject the predicted value(s) [ likely just one ]
				set ptr=0,i=0
				while $listnext(probpos,ptr,pos) { set i=i+1,$li(raw,pos)=$li(result,i) }
			}
				// Replace the updated row
			set ^IRIS.Temp.SQL(tfn,counter)=raw
		}
		// NOTE: Always clean up even on error (and we ignore any errors from %End)
		Do model.DefaultTrainedModel.%End()
		// 'status' will contain any error from %Predict()
	} Catch (ex) {
		Set status = ex.AsStatus()
	}
	RETURN status
}

/// <p><b>Note:</b> Do not call this method directly.
/// Please refer to the SQL syntax as documented in <class>%ML.Model</class></p>
/// 
/// <p>This is the entry point for the <pre>VALIDATE MODEL</pre> command. 
/// After setting up a <class>%ML.ValidationRun</class> instance, this method will hand off
/// to helper methods in <class>%ML.TrainedModel</class> specific to the model's type
/// (e.g. classification or regression).</p>
Method %Validate(trainedModel As %ML.TrainedModel = "", ByRef query As %String = "", ByRef validationRunName As %String = "", using As %DynamicObject = {$$$NULLOREF}) [ Internal ]
{
	#dim status,tSC As %Library.Status
	#dim tQuery As %Library.String
	#dim gotlock as %Library.Integer
	#dim configUsingJSON,settings As %DynamicObject
	set tSC = $$$OK, gotlock=0
	try {
		set:trainedModel="" trainedModel = ..DefaultTrainedModel
		if '$isobject(trainedModel) {
			set tSC = $$$ERROR($$$MLMissingTrainedModel)
			quit
		}
		
		// create ValidationRun record
		set tRun = ##class(%ML.ValidationRun).%New()
		set tRun.Name = $s(validationRunName="":trainedModel.ModelName_"_v"_$i(^IRIS.ML.ValidationRunC(trainedModel.%Id())), 1:validationRunName)
		set tRun.TrainedModel = trainedModel
		set tSC = tRun.LogMsg("Preparing validation query", 1)
		quit:$$$ISERR(tSC)
		
		// sort out query
		set tQuery = ""
		if $d(query)>0 {
			for i = 1:1:query {
				set tQuery = $s(i=1:"",1:tQuery_$$$NL)_query(1)
			}
		} elseif $g(query)'="" {
			set tQuery = query
		} else {
			// default to TrainingQuery if none specified
			set tQuery = trainedModel.TrainingRun.TrainingQuery
		}		
		do tRun.LogMsg("Validation query: "_tQuery,0)
		set tRun.ValidationQuery = tQuery
		set tSC = tRun.%Save()
		quit:$$$ISERR(tSC)
		
		
		// sort out settings
		set settings = {}
		
		// Apply any default settings for this provider
		do ##class(%ML.Provider).%GetProvider(trainedModel.Provider, .tProviderFQN)
		if tProviderFQN="%ML.AutoML.Provider" { do ##class(%ML.AutoML.Provider).%GetDefaultSettings(.settings) }
		elseif tProviderFQN="%ML.DR.Provider" { do ##class(%ML.DR.Provider).%GetDefaultSettings(.settings) }
		elseif tProviderFQN="%ML.H2O.Provider" { do ##class(%ML.H2O.Provider).%GetDefaultSettings(.settings) }
		elseif tProviderFQN="%ML.PMML.Provider" { do ##class(%ML.PMML.Provider).%GetDefaultSettings(.settings) }

		// Apply any default settings (DefaultParameters) from the model
		set key=""
		for  {
			set value=..DefaultParameters.GetNext(.key) quit:key=""
			do settings.%Set(key,value)
		}
		
		// Apply settings from using property of process's current ML Configuration
		set mlconfig=##class(%SYS.ML.Configuration).NameIndexOpen($system.Context.SQL().MLConfiguration,,.sc)
		if mlconfig.Using'="" {
			set configUsingJSON={}.%FromJSON(mlconfig.Using)
			set iter = configUsingJSON.%GetIterator()
			while iter.%GetNext(.key,.value) { do settings.%Set(key,value) }
		}
		
		// Apply the settings from the VALIDATE statement (if given)
		If $IsObject(using) {
			set iter = using.%GetIterator()
			while iter.%GetNext(.key,.value) { do settings.%Set(key,value) }
		}

		set tRun.Settings = settings

		// TODO: pick up training / test split when available from settings (and amend query)
		// 		 otherwise, there's nothing really to pick up.
		// 		 We can't override the provider as it's implied by the TrainedModel.
		
		
		
		// Acquire a lock that will be used to indicate if the ValidationRun is still in progress or if the process no longer exists
		// If another process sees the RunStatus="running" and can acquire the lock, the validating process died
		// If another process sees the RunStatus="running" and cannot acquire the lock, the validating process is still active
		lock +^IRIS.ML.ValidationRun(tRun.%Id()):$zu(115,5)
		if '$test { set status=$$$ERROR($$$MLValidationRunLock,tRun.Name) Quit } else { set gotlock=1 }

		// pick validation method depending on model type
		if trainedModel.ModelType="classification" {
			do tRun.LogMsg("forwarding to "_$classname(trainedModel)_":%ValidateClassifier()")
			set tSC = trainedModel.%ValidateClassifier(tQuery, .tRun, using)
		} elseif trainedModel.ModelType="regression" {
			do tRun.LogMsg("forwarding to "_$classname(trainedModel)_":%ValidateRegression()")
			set tSC = trainedModel.%ValidateRegression(tQuery, .tRun, using)
		} elseif trainedModel.ModelType="timeseries" {
			do tRun.LogMsg("forwarding to "_$classname(trainedModel)_":%ValidateTimeseries()")
			set tSC = trainedModel.%ValidateTimeseries(tQuery, .tRun, using)
		} else {
			set tSC = $$$ERROR($$$GeneralError, "Unknown model type: '"_trainedModel.ModelType_"'")
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	if $isobject($g(tRun)) {
		if $$$ISOK(tSC) {
			do tRun.LogMsg("Finished validating model",0)
		} else {
			do tRun.LogMsg("Unexpected error occurred: "_$system.Status.GetErrorText(tSC),0)
		}
		set tRun.StatusCode = tSC
		set tRun.CompletedAt = $ZDATETIME($ZTIMESTAMP,3,1,3)
		set tRun.RunStatus = $s($$$ISOK(tSC):"completed", 1:"failed")
		do tRun.%Save()
		
		lock:gotlock -^IRIS.ML.ValidationRun(tRun.%Id())
	}
	
	if ($get(%sqlcontext)'= "") && $$$ISERR(tSC) {
		set %sqlcontext.%SQLCode = -400
		set %sqlcontext.%Message = $system.Status.GetErrorText(tSC)
	}
	quit tSC
}

/// 
/// Purge all trained models
/// 
Method %Purge(days = 0) As %Status
{
	set modelid=..%Id()
	if ..DefaultTrainedModel'="" { set dtmid=..DefaultTrainedModel.%Id() } else { set dtmid=-1 }	// get oid of default trained model
	
		// Get the TrainingRun ID of the default trained model
	&sql(select TrainingRun into :dtrid from %ML.TrainedModel where %id=:dtmid)
	if SQLCODE<0 { RETURN $$$ERROR($$$SQLError,SQLCODE,%msg) }

	if 'days {

			// Delete validation metrics for this model except for default trained model
		&sql(delete from %ML.ValidationMetric where ValidationRun->TrainedModel->Model = :modelid and ValidationRun->TrainedModel <> :dtmid)
		if SQLCODE<0 { RETURN $$$ERROR($$$SQLError,SQLCODE,%msg) }
		
			// Delete validation runs for this model except for default trained model
		&sql(delete from %ML.ValidationRun where TrainedModel->Model = :modelid and TrainedModel <> :dtmid)
		if SQLCODE<0 { RETURN $$$ERROR($$$SQLError,SQLCODE,%msg) }
		
			// Delete all trained models for this model except the default trained model
		&sql(delete from %ML.TrainedModel where Model = :modelid and %ID <> :dtmid)
		if SQLCODE<0 { RETURN $$$ERROR($$$SQLError,SQLCODE,%msg) }

			// Delete all training runs for this model except the training run asscoiated with the default trained model
		&sql(delete from %ML.TrainingRun where Model = :modelid and %ID <> :dtrid)
		if SQLCODE<0 { RETURN $$$ERROR($$$SQLError,SQLCODE,%msg) }
		
	} else {
			// model timestamps are UTC time
		set cd=$ztimestamp,ct=$p(cd,",",2),cd=$p(cd,",",1)
		set deletets=$zdatetime(cd-days_","_ct,3,1,3)

			// Delete validation metrics for this model except for default trained model
		&sql(delete from %ML.ValidationMetric where ValidationRun->TrainedModel->Model = :modelid and ValidationRun->CompletedAt < :deletets and ValidationRun->TrainedModel <> :dtmid)
		if SQLCODE<0 { RETURN $$$ERROR($$$SQLError,SQLCODE,%msg) }
		
			// Delete validation runs for this model except for default trained model
		&sql(delete from %ML.ValidationRun where TrainedModel->Model = :modelid and CompletedAt < :deletets and TrainedModel <> :dtmid)
		if SQLCODE<0 { RETURN $$$ERROR($$$SQLError,SQLCODE,%msg) }
			
			// Delete all trained models older than 'days' days for this model except the default trained model
		&sql(delete from %ML.TrainedModel where Model = :modelid and TrainedAt < :deletets and %ID <> :dtmid)
		if SQLCODE<0 { RETURN $$$ERROR($$$SQLError,SQLCODE,%msg) }

			// Delete all training runs for this model older than 'days' days except the training run asscoiated with the default trained model
		&sql(delete from %ML.TrainingRun where Model = :modelid and CompletedAt < :deletets and %ID <> :dtrid)
		if SQLCODE<0 { RETURN $$$ERROR($$$SQLError,SQLCODE,%msg) }

	}
	RETURN $$$OK
}

/// When deleting a model, also delete any %ML.ValidationRun, %ML.ValidationMetric,
/// %ML.TrainingRun and %ML.TrainedModel objects for this Model
Trigger DeleteTrigger [ Event = DELETE, Foreach = row/object ]
{
	new id,trainingid,SQLCODE,%ROWCOUNT,%ROWID,validationid
	set id={ID}
	
		// Make sure model is not currently being trained
	&sql(select %id into :trainingid from %ML.TrainingRun where Model = :id and RunStatus = 'training' and TrainingRunLocked = 1)
	if SQLCODE'=100 { set %ok=0,%msg="Cannot drop Model '"_{Name}_"' because this model has at least one TrainingRun entry with a RunStatus = 'Training'" quit }
		// Make sure model is not currently being validated
	&sql(select %id into :validationid from %ML.ValidationRun where TrainedModel->Model = :id and RunStatus = 'running' and ValidationRunLocked = 1)
	if SQLCODE'=100 { set %ok=0,%msg="Cannot drop Model '"_{Name}_"' because this model has at least one ValidationRun entry with a RunStatus = 'Running'" quit }
		
		// deletion of validation runs and metrics is taken care of in TrainedModel trigger
		// Delete all trained models for this model
	&sql(delete from %ML.TrainedModel where Model = :id)
	if SQLCODE<0 { set %ok=0,%msg="Error deleting %ML.TrainedModel entries for Model '"_{Name}_"': SQLCODE="_$g(SQLCODE,"<NOT DEFINED>")_", %msg="_$g(%msg,"<NOT DEFINED>") quit }
		// Delete all training runs for this model
	&sql(delete from %ML.TrainingRun where Model = :id)
	if SQLCODE<0 { set %ok=0,%msg="Error deleting %ML.TrainingRun entries for Model '"_{Name}_"': SQLCODE="_$g(SQLCODE,"<NOT DEFINED>")_", %msg="_$g(%msg,"<NOT DEFINED>") quit }

		// Delete the %ML.TrainingRun.Name counter for this model
	kill ^IRIS.ML.TrainingRunC(id)
	RETURN
}

Storage Default
{
<Data name="DefaultParameters">
<Attribute>DefaultParameters</Attribute>
<Structure>subnode</Structure>
<Subscript>"DefaultParameters"</Subscript>
</Data>
<Data name="ModelDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>PredictingColumnNames</Value>
</Value>
<Value name="5">
<Value>PredictingColumnTypes</Value>
</Value>
<Value name="6">
<Value>WithColumnNames</Value>
</Value>
<Value name="7">
<Value>WithColumnTypes</Value>
</Value>
<Value name="9">
<Value>DefaultTrainingQuery</Value>
</Value>
<Value name="10">
<Value>CreatedAt</Value>
</Value>
<Value name="11">
<Value>DefaultTrainedModel</Value>
</Value>
<Value name="12">
<Value>WithColumnText</Value>
</Value>
<Value name="13">
<Value>DefaultIDColumnFound</Value>
</Value>
<Value name="14">
<Value>TimeSeries</Value>
</Value>
<Value name="15">
<Value>DateTimeColumn</Value>
</Value>
<Value name="16">
<Value>a</Value>
</Value>
<Value name="17">
<Value>b</Value>
</Value>
<Value name="18">
<Value>TimeStep</Value>
</Value>
<Value name="19">
<Value>ForwardResponse</Value>
</Value>
<Value name="20">
<Value>Forward</Value>
</Value>
</Data>
<DataLocation>^IRIS.ML.ModelD</DataLocation>
<DefaultData>ModelDefaultData</DefaultData>
<IdLocation>^IRIS.ML.ModelD</IdLocation>
<IndexLocation>^IRIS.ML.ModelI</IndexLocation>
<StreamLocation>^IRIS.ML.ModelS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
