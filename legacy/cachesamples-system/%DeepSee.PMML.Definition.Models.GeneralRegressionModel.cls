/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.GeneralRegressionModel Extends AbstractModel [ System = 3 ]
{

Property targetVariableName As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE");

Property modelType As %DeepSee.PMML.Datatype.String(VALUELIST = ",regression,generalLinear,multinomialLogistic,ordinalMultinomial,generalizedLinear,CoxRegression", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property targetReferenceCategory As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property cumulativeLink As %DeepSee.PMML.Datatype.CumulativeLinkFunction(XMLPROJECTION = "ATTRIBUTE");

Property linkFunction As %DeepSee.PMML.Datatype.LinkFunction(XMLPROJECTION = "ATTRIBUTE");

Property linkParameter As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

Property trialsVariable As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE");

Property trialsValue As %DeepSee.PMML.Datatype.IntNumber(XMLPROJECTION = "ATTRIBUTE");

Property distribution As %DeepSee.PMML.Datatype.String(VALUELIST = ",binomial,gamma,igauss,negbin,normal,poisson,tweedie", XMLPROJECTION = "ATTRIBUTE");

Property distParameter As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

Property offsetVariable As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE");

Property offsetValue As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

Property modelDF As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

Property endTimeVariable As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE");

Property startTimeVariable As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE");

Property subjectIDVariable As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE");

Property statusVariable As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE");

Property baselineStrataVariable As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE");

Property MiningSchema As %DeepSee.PMML.Definition.MiningSchema(XMLPROJECTION = "ELEMENT") [ Required ];

Property Output As %DeepSee.PMML.Definition.Output(XMLPROJECTION = "ELEMENT");

Property ModelStats As %DeepSee.PMML.Definition.ModelStats(XMLPROJECTION = "ELEMENT");

Property ModelExplanation As %DeepSee.PMML.Definition.ModelExplanation(XMLPROJECTION = "ELEMENT");

Property Targets As %DeepSee.PMML.Definition.Targets(XMLPROJECTION = "ELEMENT");

Property LocalTransformations As %DeepSee.PMML.Definition.LocalTransformations(XMLPROJECTION = "ELEMENT");

Property ParameterList As %DeepSee.PMML.Definition.Models.GeneralRegression.ParameterList(XMLPROJECTION = "ELEMENT");

Property FactorList As %DeepSee.PMML.Definition.Models.GeneralRegression.FactorList(XMLPROJECTION = "ELEMENT");

Property CovariateList As %DeepSee.PMML.Definition.Models.GeneralRegression.CovariateList(XMLPROJECTION = "ELEMENT");

Property PPMatrix As %DeepSee.PMML.Definition.Models.GeneralRegression.PPMatrix(XMLPROJECTION = "ELEMENT");

Property PPCovMatrix As %DeepSee.PMML.Definition.Models.GeneralRegression.PPCovMatrix(XMLPROJECTION = "ELEMENT");

Property ParamMatrix As %DeepSee.PMML.Definition.Models.GeneralRegression.ParamMatrix(XMLPROJECTION = "ELEMENT");

Property EventValues As %DeepSee.PMML.Definition.Models.GeneralRegression.EventValues(XMLPROJECTION = "ELEMENT");

Property BaseCumHazardTables As %DeepSee.PMML.Definition.Models.GeneralRegression.BaseCumHazardTables(XMLPROJECTION = "ELEMENT");

Property ModelVerification As %DeepSee.PMML.Definition.ModelVerification(XMLPROJECTION = "ELEMENT");

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Method %OnValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		if (..targetVariableName'="") && '$$$PMMLusageTypeIsTarget(pDictionary("fields", ..targetVariableName, "usageType")) {
			set tSC = $$$ERROR($$$GeneralError, "if set, targetVariableName should correspond to a predicted MiningField")
			quit
		}
		
		if (..modelType'="CoxRegression") && $isobject(..ParameterList) && '..ParameterList.Parameters.Count() {
			set tSC = $$$ERROR($$$GeneralError, "At least one Parameter should be defined for a General Regression model (except when modelType=CoxRegression)")
			quit
		}
		
		if $isobject(..ParameterList) {
			for i = 1:1:..ParameterList.Parameters.Count() {
				set tParameter = ..ParameterList.Parameters.GetAt(i)
				set pDictionary("parameters", tParameter.name) = ""
			}
		}
		
		if $isobject(..FactorList) {
			for i = 1:1:..FactorList.Predictors.Count() {
				set tPredictor = ..FactorList.Predictors.GetAt(i)
				if '$d(pDictionary("fields", tPredictor.name)) {
					set tSC = $$$ERROR($$$GeneralError, "Unknown predictor field in FactorList: '"_tPredictor.name_"'")
					quit
				}
				if $g(pDictionary("fields", tPredictor.name, "optype"))'="categorical" {
					set tSC = $$$ERROR($$$GeneralError, "Predictors in FactorList should be categorical")
					quit
				}
				set pDictionary("predictors", tPredictor.name) = ""
			}
			quit:$$$ISERR(tSC)
		}
		
		if $isobject(..CovariateList) {
			for i = 1:1:..CovariateList.Predictors.Count() {
				set tPredictor = ..CovariateList.Predictors.GetAt(i)
				if '$d(pDictionary("fields", tPredictor.name)) {
					set tSC = $$$ERROR($$$GeneralError, "Unknown predictor field in CovariateList: '"_tPredictor.name_"'")
					quit
				}
				set pDictionary("predictors", tPredictor.name) = ""
			}
			quit:$$$ISERR(tSC)
		}
		
		if (..functionName'="classification") && (..functionName'="regression") {
			set tSC = $$$ERROR($$$GeneralError, "functionName can only be 'classification' or 'regression'")
			quit
		}
		
		for tProp = "trialsVariable", "offsetVariable", "endTimeVariable", "startTimeVariable", "subjectIDVariable", "statusVariable", "baselineStrataVariable" {
			set tPropValue = $property($this, tProp)
			if (tPropValue'="") && '$d(pDictionary("fields", tPropValue)) {
				set tSC = $$$ERROR($$$GeneralError, "Unknown field: '"_tPropValue_"' ("_tProp_")")
				quit
			}
		}
		quit:$$$ISERR(tSC)
		
		if (..trialsVariable'="") && (..trialsValue'="") {
			set tSC = $$$ERROR($$$GeneralError, "Only trialsVariable or trialsValue can be present, not both")
			quit
		}
		
		if (..offsetVariable'="") && (..offsetValue'="") {
			set tSC = $$$ERROR($$$GeneralError, "Only offsetVariable or offsetValue can be present, not both")
			quit
		}
		
		if $isobject(..PPMatrix) {
			for i = 1:1:..PPMatrix.Cells.Count() {
				set tCell = ..PPMatrix.Cells.GetAt(i)
				if '$d(pDictionary("predictors", tCell.predictorName)) {
					set tSC = $$$ERROR($$$GeneralError, "Unknown predictor field: '"_tCell.predictorName_"'")
					quit
				}
				if '$d(pDictionary("parameters", tCell.parameterName)) {
					set tSC = $$$ERROR($$$GeneralError, "Unknown parameter field: '"_tCell.parameterName_"'")
					quit
				}
			}
			quit:$$$ISERR(tSC)
		}
		
		if $isobject(..ParamMatrix) {
			for i = 1:1:..ParamMatrix.Cells.Count() {
				set tCell = ..ParamMatrix.Cells.GetAt(i)
				if '$d(pDictionary("parameters", tCell.parameterName)) {
					set tSC = $$$ERROR($$$GeneralError, "Unknown parameter field: '"_tCell.parameterName_"'")
					quit
				}
			}
			quit:$$$ISERR(tSC)
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
