/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.NaiveBayesModel Extends AbstractModel [ System = 3 ]
{

Property threshold As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property MiningSchema As %DeepSee.PMML.Definition.MiningSchema(XMLPROJECTION = "ELEMENT") [ Required ];

Property Output As %DeepSee.PMML.Definition.Output(XMLPROJECTION = "ELEMENT");

Property ModelStats As %DeepSee.PMML.Definition.ModelStats(XMLPROJECTION = "ELEMENT");

Property ModelExplanation As %DeepSee.PMML.Definition.ModelExplanation(XMLPROJECTION = "ELEMENT");

Property Targets As %DeepSee.PMML.Definition.Targets(XMLPROJECTION = "ELEMENT");

Property LocalTransformations As %DeepSee.PMML.Definition.LocalTransformations(XMLPROJECTION = "ELEMENT");

Property BayesInputs As %DeepSee.PMML.Definition.Models.NaiveBayes.BayesInputs(XMLPROJECTION = "ELEMENT");

Property BayesOutput As %DeepSee.PMML.Definition.Models.NaiveBayes.BayesOutput(XMLPROJECTION = "ELEMENT");

Property ModelVerification As %DeepSee.PMML.Definition.ModelVerification(XMLPROJECTION = "ELEMENT");

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Method %OnValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		#dim tBayesInput As %DeepSee.PMML.Definition.Models.NaiveBayes.BayesInput
		for i = 1:1:..BayesInputs.BayesInput.Count() {
			set tBayesInput = ..BayesInputs.BayesInput.GetAt(i)
			if (tBayesInput.fieldName'="") && '$d(pDictionary("fields", tBayesInput.fieldName)) {
				set tSC = $$$ERROR($$$GeneralError, "BayesInput references a field that doesn't exist: '"_tBayesInput.fieldName_"'")
				quit
			}
			if $isobject(tBayesInput.DerivedField) {
				if '$isobject(tBayesInput.DerivedField.Expression) {
					set tSC = $$$ERROR($$$GeneralError, "BayesInput's DerivedField should have an Expression element")
					quit
				} elseif ('tBayesInput.DerivedField.Expression.%Extends("%DeepSee.PMML.Definition.Util.Discretize")) {
					set tSC = $$$ERROR($$$GeneralError, "BayesInput's DerivedField can only use Discretize expressions.")
					quit
				}
				set tSC = tBayesInput.DerivedField.Expression.%ValidateNames(.pDictionary)
				quit:$$$ISERR(tSC)
			}
		}
		quit:$$$ISERR(tSC)
		
		
		if (..BayesOutput.fieldName'="") && '$d(pDictionary("fields", ..BayesOutput.fieldName)) {
			set tSC = $$$ERROR($$$GeneralError, "BayesOutput references a field that doesn't exist: '"_..BayesOutput.fieldName_"'")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
