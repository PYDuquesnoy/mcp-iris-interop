/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.TextModel Extends AbstractModel [ System = 3 ]
{

Property numberOfTerms As %DeepSee.PMML.Datatype.IntNumber(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property numberOfDocuments As %DeepSee.PMML.Datatype.IntNumber(MINVAL = 0, XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property MiningSchema As %DeepSee.PMML.Definition.MiningSchema(XMLPROJECTION = "ELEMENT") [ Required ];

Property Output As %DeepSee.PMML.Definition.Output(XMLPROJECTION = "ELEMENT");

Property ModelStats As %DeepSee.PMML.Definition.ModelStats(XMLPROJECTION = "ELEMENT");

Property ModelExplanation As %DeepSee.PMML.Definition.ModelExplanation(XMLPROJECTION = "ELEMENT");

Property Targets As %DeepSee.PMML.Definition.Targets(XMLPROJECTION = "ELEMENT");

Property LocalTransformations As %DeepSee.PMML.Definition.LocalTransformations(XMLPROJECTION = "ELEMENT");

Property Dictionary As %DeepSee.PMML.Definition.Models.Text.Dictionary(XMLNAME = "TextDictionary", XMLPROJECTION = "ELEMENT");

Property Corpus As %DeepSee.PMML.Definition.Models.Text.Corpus(XMLNAME = "TextCorpus", XMLPROJECTION = "ELEMENT");

Property DocumentTermMatrix As %DeepSee.PMML.Definition.Models.Text.DocumentTermMatrix(XMLPROJECTION = "ELEMENT");

Property Normalization As %DeepSee.PMML.Definition.Models.Text.Normalization(XMLNAME = "TextModelNormalization", XMLPROJECTION = "ELEMENT");

Property Similarity As %DeepSee.PMML.Definition.Models.Text.Similarity(XMLNAME = "TextModelSimilarity", XMLPROJECTION = "ELEMENT");

Property ModelVerification As %DeepSee.PMML.Definition.ModelVerification(XMLPROJECTION = "ELEMENT");

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		if (..numberOfDocuments'=..DocumentTermMatrix.Matrix.nbRows) {
			set tSC = $$$ERROR($$$GeneralError, "DocumentTermMatrix row count does not match numberOfDocuments")
			quit
		}
		
		if (..numberOfTerms'=..DocumentTermMatrix.Matrix.nbCols) {
			set tSC = $$$ERROR($$$GeneralError, "DocumentTermMatrix column count does not match numberOfTerms")
			quit
		}
		
		if (..numberOfTerms'=..Dictionary.Terms.Length()) {
			set tSC = $$$ERROR($$$GeneralError, "TextDictionary array length does not match numberOfTerms")
			quit
		}
		
		set tInputMap = ""
		for i = 1:1:..Extension.Count() {
			set tExtension = ..Extension.GetAt(i)
			for j = 1:1:tExtension.iscExtensions.Count() {
				set tExtensionElem = tExtension.iscExtensions.GetAt(j)
				if (tExtensionElem.%Extends("%DeepSee.PMML.Definition.Extension.TextModelInput")) {
					set tInputMap = tExtensionElem
					quit
				}
			}
			quit:$isobject(tInputMap)
		}
		if $isobject(tInputMap) {
			if '$isobject(tInputMap.Fields) || 'tInputMap.Fields.Length() {
				set tSC = $$$ERROR($$$GeneralError, "X-TextModelInput should list at least one input field")
				quit
			}
			
			if (tInputMap.inputType="terms") && (tInputMap.Fields.Length()'=..numberOfTerms) {
				set tSC = $$$ERROR($$$GeneralError, "When X-TextModelInput has inputType=terms, the number of mapped fields should equal the number of terms for this TextModel")
				quit
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %OnValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		set tInputMap = ""
		for i = 1:1:..Extension.Count() {
			set tExtension = ..Extension.GetAt(i)
			for j = 1:1:tExtension.iscExtensions.Count() {
				set tExtensionElem = tExtension.iscExtensions.GetAt(j)
				if (tExtensionElem.%Extends("%DeepSee.PMML.Definition.Extension.TextModelInput")) {
					set tInputMap = tExtensionElem
					quit
				}
			}
			quit:$isobject(tInputMap)
		}
		if $isobject(tInputMap) {
			set tSC = tInputMap.Fields.ValuesAsArray(.tFields)
			quit:$$$ISERR(tSC)
			
			for i = 1:1:tFields {
				if '$d(pDictionary("fields", tFields(i))) {
					set tSC = $$$ERROR($$$GeneralError, "Unknown text input field: '"_tFields(i)_"'")
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
