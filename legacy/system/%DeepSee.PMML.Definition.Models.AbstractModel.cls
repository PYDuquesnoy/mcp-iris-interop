/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Elements are defined in the subclasses, to ensure the right element sequence
Class %DeepSee.PMML.Definition.Models.AbstractModel Extends %DeepSee.PMML.Definition.extendableNode [ Abstract, System = 3 ]
{

Property modelName As %DeepSee.PMML.Datatype.String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE", XSDTYPE = "xs:string");

Property functionName As %DeepSee.PMML.Datatype.MiningFunction(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property algorithmName As %DeepSee.PMML.Datatype.String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE", XSDTYPE = "xs:string");

Property isScorable As %DeepSee.PMML.Datatype.Boolean(XMLPROJECTION = "ATTRIBUTE");

Method %ValidateNames(ByRef pGlobalDictionary) As %Status [ Final ]
{
	set tSC = $$$OK
	try {
		
		set tSC = ..MiningSchema.%GetDictionary(.pGlobalDictionary, .tLocalDictionary)
		quit:$$$ISERR(tSC)
		
		// BDB839 - pick up global transformations and append to local transformations
		if $isobject($g(%PMMLTransformations)) && %PMMLTransformations.DerivedFields.Count() {
			
			set:'$isobject(..LocalTransformations) ..LocalTransformations = ##class(%DeepSee.PMML.Definition.LocalTransformations).%New()
			
			// exclude the ones that are (re)defined in the LT or MS
			for i = 1:1:..LocalTransformations.DerivedFields.Count() {
				set tSkip(..LocalTransformations.DerivedFields.GetAt(i).name)=""
			}
			for i = 1:1:..MiningSchema.MiningFields.Count() {
				set tSkip(..MiningSchema.MiningFields.GetAt(i).name)=""
			}
			
			merge tDerivedDictionary = tLocalDictionary("fields")
			#dim tDerivedField as %DeepSee.PMML.Definition.DerivedField
			for i = 1:1:%PMMLTransformations.DerivedFields.Count() {
				set tDerivedField = %PMMLTransformations.DerivedFields.GetAt(i)
				continue:$d(tSkip(tDerivedField.name))
				
				// first check if all the inputs for the DerivedField are present in the mining schema
				kill tInputFields
				if '$d(%PMMLTransformations("inputs",i)) { // do this only once
					continue:'$isobject(tDerivedField.Expression)
					do tDerivedField.Expression.%GetInputFields(.tInputFields)
					merge %PMMLTransformations("inputs",i) = tInputFields
				} else {
					merge tInputFields = %PMMLTransformations("inputs",i)
				}
				set tInputFieldName = ""
				for {
					set tInputFieldName = $order(tInputFields(tInputFieldName))
					quit:tInputFieldName=""
					quit:'$d(tDerivedDictionary(tInputFieldName))
				}
				
				if tInputFieldName'="" {
					// this means we ran into a missing input field
					continue
				} else {
					// this means we got through the entire list and found all inputs
					set tDerivedDictionary(tDerivedField.name)=""
					set tSC = ..LocalTransformations.DerivedFields.Insert(tDerivedField)
					quit:$$$ISERR(tSC)
				}
			}
		}
		
		if $isobject(..LocalTransformations) {
			set tSC = ..LocalTransformations.%ValidateNames(.tLocalDictionary)
			quit:$$$ISERR(tSC)
		}
		
		if $isobject(..Targets) {
			set tSC = ..Targets.%ValidateNames(.tLocalDictionary)
			quit:$$$ISERR(tSC)
		}
		
		if $isobject(..Output) {
			set tSC = ..Output.%ValidateNames(.tLocalDictionary)
			quit:$$$ISERR(tSC)
		}
		
		// TODO: ModelStats
		// TODO: ModelExplanation
		// TODO: ModelVerification
		
		set tSC = ..%OnValidateNames(.tLocalDictionary)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %OnValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %GetModelClass() As %String [ CodeMode = objectgenerator, Internal ]
{
	set tClassName = %compiledclass.Name
	do %code.WriteLine("	quit "_$$$QUOTE("%DeepSee.PMML.Model."_$e($p(tClassName,".",*),1,*-5)))
}

Method %IsOutputFeatureSupported(pFeature As %String, pValue As %String = "", Output pSC As %Status) As %Boolean [ Internal ]
{
	set pSC = $$$OK
	set tOutputField = ##class(%DeepSee.PMML.Definition.OutputField).%New()
	set tOutputField.name = "dummy", tOutputField.feature = pFeature, tOutputField.value=pValue
	quit $classmethod(..%GetModelClass(), "%IsOutputFieldSupported", $this, tOutputField, .pSC)
}

}
