/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.RegressionModel Extends %DeepSee.PMML.Definition.Models.AbstractModel [ System = 3 ]
{

Property modelType As %DeepSee.PMML.Datatype.String(VALUELIST = ",linearRegression,stepwisePolynomialRegression,logisticRegression", XMLPROJECTION = "ATTRIBUTE");

Property targetFieldName As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE");

Property normalizationMethod As %DeepSee.PMML.Datatype.String(VALUELIST = ",none,simplemax,softmax,logit,probit,cloglog,exp,loglog,cauchit", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "none" ];

Property MiningSchema As %DeepSee.PMML.Definition.MiningSchema(XMLPROJECTION = "ELEMENT") [ Required ];

Property Output As %DeepSee.PMML.Definition.Output(XMLPROJECTION = "ELEMENT");

Property ModelStats As %DeepSee.PMML.Definition.ModelStats(XMLPROJECTION = "ELEMENT");

Property ModelExplanation As %DeepSee.PMML.Definition.ModelExplanation(XMLPROJECTION = "ELEMENT");

Property Targets As %DeepSee.PMML.Definition.Targets(XMLPROJECTION = "ELEMENT");

Property LocalTransformations As %DeepSee.PMML.Definition.LocalTransformations(XMLPROJECTION = "ELEMENT");

Property RegressionTables As list Of %DeepSee.PMML.Definition.Models.Regression.RegressionTable(XMLNAME = "RegressionTable", XMLPROJECTION = "ELEMENT");

Property ModelVerification As %DeepSee.PMML.Definition.ModelVerification(XMLPROJECTION = "ELEMENT");

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Method %OnValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		set tTargetFieldName = ..targetFieldName
		if (tTargetFieldName = "") {
			for {
				set tTargetFieldName = $order(pDictionary("fields", tTargetFieldName))
				quit:tTargetFieldName=""
				quit:$$$PMMLusageTypeIsTarget($g(pDictionary("fields", tTargetFieldName, "usageType")))
			}
		} elseif '$$$PMMLusageTypeIsTarget($g(pDictionary("fields", ..targetFieldName, "usageType"))) {
			set tSC = $$$ERROR($$$GeneralError, "if set, targetVariableName should correspond to a predicted MiningField")
			quit
		}
		
		// BDB881 - also accept implicit target field
		if (tTargetFieldName="") && $isobject(..Output) {
			for i = 1:1:..Output.OutputFields.Count() {
				#dim tOutputField As %DeepSee.PMML.Definition.OutputField = ..Output.OutputFields.GetAt(i)
				if (tOutputField.feature="predictedValue") {
					set tTargetFieldName = tOutputField.name, 
						tTargetFieldOptype = tOutputField.optype
					quit
				}
			}
		} elseif (tTargetFieldName'="") {
			set tTargetFieldOptype = $g(pDictionary("fields", tTargetFieldName, "optype"), $s(..functionName="classification":"categorical",1:"continuous"))
		}
		
		
		if (tTargetFieldName="") {
			set tSC = $$$ERROR($$$GeneralError, "No target field for this model")
			quit
		}
		
		#dim tRegTable As %DeepSee.PMML.Definition.Models.Regression.RegressionTable
		for i = 1:1:..RegressionTables.Count() {
			set tRegTable = ..RegressionTables.GetAt(i)
			
			if (tTargetFieldOptype'="continuous") {
				if (tRegTable.targetCategory="") {
					set tSC = $$$ERROR($$$GeneralError, "targetCategory is a required field for RegressionTable")
					quit
				}
				
				if $d(tCategories(tRegTable.targetCategory)) {
					set tSC = $$$ERROR($$$GeneralError, "targetCategory must be unique for each RegressionTable in a RegressionModel")
					quit
				}
				set tCategories(tRegTable.targetCategory) = ""
			}
			
			
			// Validate field refs
			#dim tNumPredictor As %DeepSee.PMML.Definition.Models.Regression.NumericPredictor
			for j = 1:1:tRegTable.NumericPredictors.Count() {
				set tNumPredictor = tRegTable.NumericPredictors.GetAt(j)
				if '$d(pDictionary("fields", tNumPredictor.name)) {
					set tSC = $$$ERROR($$$GeneralError, "NumericPredictor name not found in the Data Dictionary: '"_tNumPredictor.name_"'")
					quit
				}
			}
			for j = 1:1:tRegTable.CategoricalPredictors.Count() {
				set tCatPredictor = tRegTable.CategoricalPredictors.GetAt(j)
				if '$d(pDictionary("fields", tCatPredictor.name)) {
					set tSC = $$$ERROR($$$GeneralError, "CategoricalPredictor name not found in the Data Dictionary: '"_tCatPredictor.name_"'")
					quit
				}
			}
			#dim tPredictorTerm As %DeepSee.PMML.Definition.Models.Regression.PredictorTerm
			for j = 1:1:tRegTable.PredictorTerms.Count() {
				set tPredictorTerm = tRegTable.PredictorTerms.GetAt(j)
				
				for k = 1:1:tPredictorTerm.FieldRefs.Count() {
					set tFieldRef = tPredictorTerm.FieldRefs.GetAt(k)
					if '$d(pDictionary("fields", tFieldRef.field)) {
						set tSC = $$$ERROR($$$GeneralError, "PredictorTerm references a field not found in the Data Dictionary: '"_tFieldRef.field_"'")
						quit
					}
				}
				quit:$$$ISERR(tSC)
				
				if (tPredictorTerm.name'="") && $d(pDictionary("fields", tPredictorTerm.name)) {
					set tSC = $$$ERROR($$$GeneralError, "PredictorTerm name should be unique: '"_tPredictorTerm.name_"'")
					quit
				}
			}
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
