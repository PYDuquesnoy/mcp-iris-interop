/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.Methods.Base Extends %RegisteredObject [ Deprecated, System = 4 ]
{

Property Builder As %iKnow.Classification.Builder;

Method %OnNew(pBuilder As %iKnow.Classification.Builder) As %Status
{
	set ..Builder = pBuilder
	quit $$$OK
}

Method %LoadFromModel(pDefinition As %iKnow.Classification.Definition.Classifier) As %Status
{
	quit $$$OK
}

Method %BuildClassificationMethod(ByRef pClassifier As %iKnow.Classification.Definition.Classifier, pIncludeBuilderParams As %Boolean = 1, pVerbose As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		
		set tClassificationMethod = ##class(%iKnow.Classification.Definition.ClassificationMethod).%New()
		set pClassifier.ClassificationMethod = tClassificationMethod
		set tClassificationMethod.method = ..Builder.ClassificationMethod
		set tClassificationMethod.localTermWeights = ..Builder.DocumentVectorLocalWeights
		set tClassificationMethod.normalization = ..Builder.DocumentVectorNormalization
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

/// Callback invoked whenever an entire term at an index has been removed
Method %OnRemoveTerm(pIndex As %Integer) As %Status
{
	quit $$$OK
}

/// Recycle properties from the previous MethodBuilder object if possible
Method %LoadMethodBuilderProperties(pMethodBuilder As Base) As %Status [ Internal ]
{
	quit $$$OK
}

}
