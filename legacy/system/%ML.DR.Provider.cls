/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occODBC, %occJava)

/// Implements the QuickML provider
Class %ML.DR.Provider Extends %ML.Provider
{

/// Provider name
Parameter PROVIDERNAME As %String = "DR";

/// Java objects:
Property datarobot As %Net.Remote.Object;

Parameter SQLTYPE As %String [ Constraint = "resultset,query", Flags = ENUM ] = "query";

/// 
/// Adds the default settings for DR to the settings dynamic object
/// 
ClassMethod %GetDefaultSettings(ByRef settings As %DynamicObject)
{
	RETURN	// These were the defaults prior to DPV5776
	#; do:'settings.%IsDefined("quickrun") settings.%Set("quickrun",1)
	do:'settings.%IsDefined("remote") settings.%Set("remote",1)
	RETURN
}

/// Opens JavaGateway and creates the Java objects for H2O
Method %OnInit() As %Status
{
	#dim sc As %Status = $$$OK
	try {
		// building classpath to JAR file
		set classpath = ##class(%ListOfDataTypes).%New()
		Set JARDir = ##class(%Library.File).NormalizeFilename($System.Util.InstallDirectory()_"/dev/java/lib/JDK18")
		set JARName = $$$javaIntegratedMLJAR
		set JARVersion = $piece($piece($translate(JARName,"\","/"),"/",*),"-",3)
		set JARMajorVersion = $piece(JARVersion,".",1)
		if JARMajorVersion '= 2 {
			set sc = $$$ERROR($$$MLGeneralError, "initializeH2O()", "intersystems-integratedml version 2.x is required, but version "_JARVersion_" was found")
			quit
		}
		Set quickmlJARPath = ##class(%Library.File).NormalizeFilename(JARName,JARDir)
		Set quickmlJARPath = ##class(%Library.File).NormalizeFilenameWithSpaces(quickmlJARPath)
	
		do classpath.Insert(quickmlJARPath)

		// making connection to JavaGateway for Java Object
		set gateway = ##class(%Net.Remote.Gateway).%New()
		set sc = gateway.%Connect("",$$$IntegratedMLServerName,$namespace,,classpath)
		Quit:$$$ISERR(sc)
	
		set ..datarobot = ##class(%Net.Remote.Object).%New(gateway,"com.intersystems.ml.DataRobot")
		do ..datarobot.initializeDRJ2()
	} catch (ex){
		set status = ex.AsStatus()
		set sc = $$$EMBEDSC($$$ERROR($$$MLProviderUnavailable,..%GetName()),status)
	}
	quit sc
}

/// Create a ML model
Method %CreateModel(modelName As %String, ByRef model As %ML.Model, ByRef params) As %Status
{
	Set model = ##class(%ML.Model).%New()
	Set model.Provider = $THIS
	Quit $$$OK
}

/// 
/// Returns an instance of %SQL.Statement to be used for the training query
/// 
Method %GetTrainStatement() As %SQL.Statement
{
	Quit ##class(%ML.DeferredStatement).%New()
}

/// Train a DR model
/// data argument is not used for IoC providers
/// name is no longer used.  trainingrun.name is already defined
Method %BeginTraining(model As %ML.Model, data As %SQL.StatementResult, trainingrun As %ML.TrainingRun, ByRef name As %String = "", ByRef trainkey) As %Status
{
	#dim sc As %Status = $$$OK
	try{
		if ($LENGTH(trainingrun.Configuration.url) = 0){
			if ($LENGTH(trainingrun.Configuration.apiToken) = 0){
				set sc = $$$ERROR($$$MLGeneralError,"DataRobot","Please provide your URL and apiToken")
			} else {
				set sc = $$$ERROR($$$MLGeneralError,"DataRobot","Please provide the URL")
			}
		} elseif ($LENGTH(trainingrun.Configuration.apiToken) = 0){
			set sc = $$$ERROR($$$MLGeneralError,"DataRobot","Please provide your apiToken")
		}
		Quit:$$$ISERR(sc)
		
		if ( ..datarobot.datarobotAuth(trainingrun.Configuration.url, trainingrun.Configuration.apiToken) = 0){
			set sc = $$$ERROR($$$MLGeneralError,"DataRobot","authentication failed")
		}
		Quit:$$$ISERR(sc)

		if ($DATA(data.SQL) > 1){
			set sqlText = data.SQL(1)
		} else {
			set sqlText = data.SQL
		}
		Set predictingcolumn = model.PredictingColumnNames.GetAt(1)
		Set:predictingcolumn["." predictingcolumn=$p(predictingcolumn,".",2)	// If qualified, just get the name
		
		do trainingrun.Log.WriteLine("started importing data from IRIS...")
		Set status = trainingrun.%Save()
		Quit:$$$ISERR(status)

		if (name = ""){
			set name = trainingrun.Name
		}
		


		if 'model.TimeSeries {set importData = ..datarobot.importData(sqlText, name)}
		else {
			set predicts = "", idx = 1
			while (model.PredictingColumnNames.GetAt(idx) '= "") {
				set predicts = predicts_model.PredictingColumnNames.GetAt(idx)_","
				set idx = $INCREMENT(idx)
			}
			set importData = ..datarobot.importData(sqlText, name, model.DateTimeColumn, predicts)
		}

		if (importData '= "success"){
			set sc = $$$ERROR($$$MLGeneralError,"Importing data failed:",importData)
		}
		Quit:$$$ISERR(sc)

		do trainingrun.Log.WriteLine("finished importing data & started training...")
		Set status = trainingrun.%Save()
		Quit:$$$ISERR(status)

		#; if (trainingrun.Settings.%Get("quickrun") = ""){
		#; 	d trainingrun.Settings.%Set("quickrun","1")
		#; }
		
		if 'model.TimeSeries {set trainingResult = ..datarobot.trainModel(name, predictingcolumn, trainingrun.Settings.%ToJSON())}
		else {
			set trainingResult = ..datarobot.trainModel(name, trainingrun.Settings.%ToJSON())
			set model.TimeStep = $LIST(trainingResult,6)
			set model.ForwardResponse = $LIST(trainingResult,5)
			set trainingResult = $LIST(trainingResult,1,4)
		}


		if ($LISTGET(trainingResult,1) = "error"){
			set sc = $$$ERROR($$$MLGeneralError,"Training failed:",trainingResult)
		}
		Quit:$$$ISERR(sc)

		// setting trainingrun
		Set trainingrun.CompletedAt = $ZDATETIME($ZTIMESTAMP,3,1,3)
		Set trainingrun.RunStatus = "completed"

		do trainingrun.Log.WriteLine("finished training...")
		Set status = trainingrun.%Save()
		Quit:$$$ISERR(status)

		set trainedmodel = ##class(%ML.DR.TrainedModel).%New()
		Set trainedmodel.ModelName = trainingrun.Name
		Set trainedmodel.Provider = $CLASSNAME()
		Set trainedmodel.Model = model
		Set trainedmodel.TrainingRun = trainingrun
		Set trainedmodel.TrainedAt = trainingrun.CompletedAt
		set trainedmodel.predServer = trainingResult

		set trainedmodel.drjProvider = $THIS

		if (model.TimeSeries) {set trainedmodel.ModelType ="timeseries"}

		set trainkey = trainedmodel
		Set sc = trainedmodel.%Save()
		Quit:$$$ISERR(sc)

	} Catch (ex) {
		set sc = ex.AsStatus()
	}

	Quit sc
}

/// 
/// Check for training complete
/// 
Method %WaitForTraining(ByRef trainkey, trainingrun As %ML.TrainingRun, ByRef trainedmodel As %ML.TrainedModel, timeoutMS As %Integer = -1) As %Status
{
	#dim status As %Status = $$$OK
	Try {

		/// not yet implemented: using H2O trainedModel for now
		// The trainkey is actually the trainedmodel instance from %BeginTraining since we're not async
		If '$IsObject(trainkey) || 'trainkey.%Extends("%ML.DR.TrainedModel") {
			Set status = $$$ERROR($$$MLInvalidTrainKey,trainkey)
			Quit
		}

		Set trainedmodel = trainkey

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

}
