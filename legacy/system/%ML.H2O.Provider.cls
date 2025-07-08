/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occODBC, %occJava)

/// Implements the QuickML provider
Class %ML.H2O.Provider Extends %ML.Provider
{

/// Provider name
Parameter PROVIDERNAME As %String = "H2O";

/// Java objects:
/// h2o: The Main class with QuickML Specific functions
/// dataframe: sql and row data converted to H2O Dataframe objects
Property h2o As %Net.Remote.Object;

Parameter SQLTYPE As %String [ Constraint = "resultset,query", Flags = ENUM ] = "query";

Parameter SQLPUBLICSECURITY = "{""Provider_GetModel"":""E""}";

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
		
		set ..h2o = ##class(%Net.Remote.Object).%New(gateway,"com.intersystems.ml.H2O")
		try {
			do ..h2o.initializeH2O2()
		} catch (ex){
			set sc = $$$ERROR($$$MLGeneralError,"initializeH2O()","failed. Please check documentation for further details.")
			quit
		}
	} catch (ex){
		set status = ex.AsStatus()
		set sc = $$$EMBEDSC($$$ERROR($$$MLProviderUnavailable,..%GetName()),status)
	}
	quit sc
}

/// 
/// Adds the default settings for H2O to the settings dynamic object
/// 
ClassMethod %GetDefaultSettings(ByRef settings As %DynamicObject)
{
	RETURN	// These were the defaults prior to DPV5776
	do:'settings.%IsDefined("MaxModels") settings.%Set("MaxModels",5)
	RETURN
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

/// Train an H2O model
/// data argument is not used for IoC providers
/// name is no longer used.  trainingrun.name is already defined
Method %BeginTraining(model As %ML.Model, data As %SQL.StatementResult, trainingrun As %ML.TrainingRun, ByRef name As %String = "", ByRef trainkey) As %Status
{
	#dim sc As %Status = $$$OK
	try{		
		if ($DATA(data.SQL) > 1){
			set sqlText = data.SQL(1)
		} else {
			set sqlText = data.SQL
		}
		
		if ($DATA(data.SQLCOUNT) > 1){
			set sqlCount = data.SQLCOUNT(1)
		} else {
			set sqlCount = data.SQLCOUNT
		}

		Set predictingcolumn = model.PredictingColumnNames.GetAt(1)
		Set:predictingcolumn["." predictingcolumn=$p(predictingcolumn,".",2)	// If qualified, just get the name

		// Start logging in TrainingRun.Log
		do trainingrun.Log.WriteLine("started importing data from IRIS...")
		Set sc = trainingrun.%Save()
		Quit:$$$ISERR(sc)
		
		// importing IRIS Data into H2O -----------------------------------------------
		do ..h2o.importData(sqlText, sqlCount, predictingcolumn,trainingrun.Settings.%ToJSON())
		
		if (..h2o.progress("import") = 0){
			set sc = $$$ERROR($$$MLGeneralError,"importData()","failed to import data")
			Set trainingrun.RunStatus = "failed"
			Set trainingrun.StatusCode = sc
			Set trainingrun.CompletedAt = $ZDATETIME($ZTIMESTAMP,3,1,3)
			do trainingrun.Log.WriteLine("failed to import data...")
		}
		else {
			do trainingrun.Log.WriteLine("finished importing data & started training...")
		}
		Set sc = trainingrun.%Save()
		Quit:$$$ISERR(sc)
		
		If trainingrun.RunStatus = "failed" {
			Set sc = trainingrun.StatusCode
			Quit
		}
		
		// start training models -------------------------------------------
		do ..h2o.trainModel(trainingrun.Settings.%ToJSON())
		
		if (..h2o.progress("training") = -1){
			set sc = $$$ERROR($$$MLGeneralError,"trainModel()","failed to train a model.")
		}
		else {
			try {
				while (..h2o.progress("training") = 0){
					do trainingrun.Log.WriteLine(..h2o.trainingLog())
					Set sc = trainingrun.%Save()
					Quit:$$$ISERR(sc)
					hang 0.5
				}
				set modelStream = ..h2o.getTrainedModel()
				if (modelStream = ""){
					set errorMsg = ..h2o.trainingLog()
					if (errorMsg = "fail"){
						set sc = $$$ERROR($$$MLGeneralError,"getTrainedModel()","failed to train models. Please check the training dataset.")
						Quit
					} else {
						set sc = $$$ERROR($$$MLGeneralError,"getTrainedModel()",errorMsg)
						Quit
					}
				}
			} catch {
				set sc = $$$ERROR($$$MLGeneralError,"JavaGateway","failed. Please consider increasing your Java heap size")
			}
		}
		
		Set trainingrun.CompletedAt = $ZDATETIME($ZTIMESTAMP,3,1,3)
		
		// updating TrainingRun
		if ($$$ISERR(sc)){
			Set trainingrun.RunStatus = "failed"
			Set trainingrun.StatusCode = sc
		}
		else {
			Set trainingrun.RunStatus = "completed"
			do trainingrun.Log.WriteLine(..h2o.trainingLog())
		}
		Set sc = trainingrun.%Save()
		Quit:$$$ISERR(sc)
		
		If trainingrun.RunStatus = "failed" {
			Set sc = trainingrun.StatusCode
			Quit
		}

		set trainedmodel = ##class(%ML.H2O.TrainedModel).%New()
		Set trainedmodel.Provider = $CLASSNAME()
		Set trainedmodel.Model = model
		Set trainedmodel.ModelName = trainingrun.Name
		Set trainedmodel.TrainingRun = trainingrun
		Set trainedmodel.TrainedAt = trainingrun.CompletedAt
		set trainedmodel.ByteStream = modelStream.%getall()
		set trainedmodel.h2oProvider = $THIS
		
		Set sc = trainedmodel.%Save()
		Quit:$$$ISERR(sc)
		
		set trainkey = trainedmodel
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

		// The trainkey is actually the trainedmodel instance from %BeginTraining since we're not async
		If '$IsObject(trainkey) || 'trainkey.%Extends("%ML.H2O.TrainedModel") {
			Set status = $$$ERROR($$$MLInvalidTrainKey,trainkey)
			Quit
		}

		Set trainedmodel = trainkey

	} Catch (ex) {
		set status = ex.AsStatus()
	}

	Quit status
}

ClassMethod getModel(modelId As %String) As %Stream.GlobalBinary [ SqlProc ]
{
	if '$$$UseModelPriv($username, 0), '$$$ManageModelPriv($username, 0) {
		set sc = $$$ERROR($$$OperationRequiresOneOfTwo, "%USE_MODEL", "%MANAGE_MODEL")
		throw ##class(%Exception.StatusException).CreateFromStatus(sc)
	}
 	set trainedmodel = ##class(%ML.H2O.TrainedModel).%OpenId(modelId)
 	return trainedmodel.ByteStream
}

}
