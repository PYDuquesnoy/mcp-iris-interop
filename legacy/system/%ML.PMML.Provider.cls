/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This Provider does not <i>train</i> models based on a dataset, but can be used to 
/// <i>import</i> a model built elsewhere and exported to the <a href="http://dmg.org/">Predictive 
/// Modeling Markup Language</a> standard, as <a href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25ML.PMML.Provider">supported
/// in InterSystems IRIS</a>.</p>
/// <p>Supported USING parameters:</p>
/// <ul>
/// <li><tt>class_name</tt>: <class>%DeepSee.PMML.Definition</class> subclass containing the PMML definition</li>
/// <li><tt>file_name</tt>: directory path to a file containing the PMML definition</li>
/// <li><tt>model_name</tt>: if the PMML definition contains multiple models, optinally specify the name of the one to use</li>
/// </ul>
/// <p>Either <tt>class_name</tt> or <tt>file_name</tt> must be provided. <tt>model_name</tt> is optional</p>
Class %ML.PMML.Provider Extends %ML.Provider
{

/// Provider name
Parameter PROVIDERNAME As %String = "PMML";

/// 
/// Train an ML model
/// 
Method %BeginTraining(model As %ML.Model, data As %SQL.StatementResult, trainingrun As %ML.TrainingRun, ByRef name As %String = "", ByRef trainkey) As %Status
{
	set tSC = $$$OK
	try {
		set tPMMLClassName = trainingrun.Settings."class_name", 
			tPMMLModelName = trainingrun.Settings."model_name", 
			tPMMLFileName = trainingrun.Settings."file_name"
			
		if tPMMLFileName'="" {
			if tPMMLClassName="" {
				set i="", tPMMLClassName = "IRIS.ML.PMML.ImportedClass"
				while $$$defClassDefined(tPMMLClassName_i) { set i = i+1 }
				set tPMMLClassName = tPMMLClassName_i
			}
			set tSC = ##class(%DeepSee.PMML.Utils).CreateFromFile(tPMMLFileName, tPMMLClassName, 0, 1, 0)
			quit:$$$ISERR(tSC)
		}
		
		// do we have a PMML class name?
		if tPMMLClassName="" {
			set tSC = $$$ERROR($$$GeneralError, "No PMML class name provided")
			quit
		}
		
		// does it exist?
		if '$$$defClassDefined(tPMMLClassName) {
			set tSC = $$$ERROR($$$ClassDoesNotExist, tPMMLClassName)
			quit
		}
		
		// does it inherit from the right class?
		if '$classmethod(tPMMLClassName, "%Extends", "%DeepSee.PMML.Definition") {
			set tSC = $$$ERROR($$$GeneralError, "Class '"_tPMMLClassName_"' does not extend '%DeepSee.PMML.Definition'")
			quit
		}
		
		// sanity-test by instantiating the model / definition
		#dim tPMMLDefinition as %DeepSee.PMML.Definition.PMML
		set tSC = $classmethod(tPMMLClassName, "%GetDefinition", .tPMMLDefinition)
		quit:$$$ISERR(tSC)
		#dim tModelInstance as %DeepSee.PMML.Model.AbstractModel
		set tSC = $classmethod(tPMMLClassName, "%GetModelInstance", tPMMLModelName, .tModelInstance)
		quit:$$$ISERR(tSC)
		#dim tModelDefinition as %DeepSee.PMML.Definition.Models.AbstractModel
		set tSC = tModelInstance.%GetDefinition(.tModelDefinition)
		quit:$$$ISERR(tSC)
		
		set trainingrun.CompletedAt = $ZDATETIME($ZTIMESTAMP,3,1,3)
		set trainingrun.StatusCode = $$$OK
		set trainingrun.RunStatus = "completed"
		
		set tTrainedModel = ##class(%ML.PMML.TrainedModel).%New()
		set tTrainedModel.ModelName = trainingrun.Name
		set tTrainedModel.Provider = $CLASSNAME()
		set tTrainedModel.Model = model
		set tTrainedModel.TrainingRun = trainingrun
		set tTrainedModel.TrainedAt = trainingrun.CompletedAt
		set tTrainedModel.ModelType = tModelDefinition.functionName
		do tTrainedModel.ModelInfo.SetAt(tModelDefinition.functionName, "ProblemType")
		
		// resolve package detail
		set tPackage = tModelDefinition.algorithmName
		if ($zstrip(tPackage,"*W")="") && $isobject(tPMMLDefinition.Header) && $isobject(tPMMLDefinition.Header.Application) {
			set tPackage = tPMMLDefinition.Header.Application.name _ " " _ tPMMLDefinition.Header.Application.version
		}
		if ($zstrip(tPackage,"*W")="") && $isobject(tPMMLDefinition.Header) {
			set tPackage = tPMMLDefinition.Header.description
		}
		do:$zstrip(tPackage,"*W")'="" tTrainedModel.ModelInfo.SetAt(tPackage, "Package")
		
		// resolve model type detail
		set tModelType = $piece($classname(tModelDefinition),".",*)
		set tModelType = $case(tModelType, 
			"GeneralRegression":tModelDefinition.modelType,
			"Regression":tModelDefinition.modelType,
			"MiningModel":"Composite",
			:tModelType)
		do tTrainedModel.ModelInfo.SetAt(tModelType, "ModelType")
		
		set tTrainedModel.PMMLClassName = tPMMLClassName
		set tTrainedModel.PMMLModelName = tPMMLModelName
		set tSC = tTrainedModel.%Save()
		quit:$$$ISERR(tSC)
		set tSC = trainingrun.%Save()
		quit:$$$ISERR(tSC)
		
		set trainkey = tTrainedModel
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %WaitForTraining(ByRef trainkey, trainingrun As %ML.TrainingRun, ByRef trainedmodel As %ML.TrainedModel, timeoutMS As %Integer = -1) As %Status
{
	set trainedmodel = $g(trainkey)
	quit $$$OK
}

}
