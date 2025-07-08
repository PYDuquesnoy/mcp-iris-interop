/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.SupportVectorMachineModel Extends AbstractModel [ System = 4 ]
{

Property threshold As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

Property svmRepresentation As %DeepSee.PMML.Datatype.String(VALUELIST = ",Coefficients,SupportVectors", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "SupportVectors" ];

Property classificationMethod As %DeepSee.PMML.Datatype.String(VALUELIST = ",OneAgainstAll,OneAgainstOne", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "OneAgainstAll" ];

Property MiningSchema As %DeepSee.PMML.Definition.MiningSchema(XMLPROJECTION = "ELEMENT") [ Required ];

Property Output As %DeepSee.PMML.Definition.Output(XMLPROJECTION = "ELEMENT");

Property ModelStats As %DeepSee.PMML.Definition.ModelStats(XMLPROJECTION = "ELEMENT");

Property ModelExplanation As %DeepSee.PMML.Definition.ModelExplanation(XMLPROJECTION = "ELEMENT");

Property Targets As %DeepSee.PMML.Definition.Targets(XMLPROJECTION = "ELEMENT");

Property LocalTransformations As %DeepSee.PMML.Definition.LocalTransformations(XMLPROJECTION = "ELEMENT");

Property KernelType As %DeepSee.PMML.Definition.Models.SVM.KernelType(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

Property VectorDictionary As %DeepSee.PMML.Definition.Models.SVM.VectorDictionary(XMLPROJECTION = "ELEMENT");

Property SVMs As list Of %DeepSee.PMML.Definition.Models.SVM.SupportVectorMachine(XMLNAME = "SupportVectorMachine", XMLPROJECTION = "ELEMENT");

Property ModelVerification As %DeepSee.PMML.Definition.ModelVerification(XMLPROJECTION = "ELEMENT");

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		if ..VectorDictionary.numberOfVectors && (..VectorDictionary.numberOfVectors'=..VectorDictionary.Instances.Count()) {
			set tSC = $$$ERROR($$$GeneralError, "If set, numberOfVectors should correspond to the number of VectorInstances defined")
			quit
		}
		
		set tDimensionality = ..VectorDictionary.Fields.FieldRefs.Count()
		if ..VectorDictionary.Fields.numberOfFields && (..VectorDictionary.Fields.numberOfFields '= tDimensionality) {
			set tSC = $$$ERROR($$$GeneralError, "If set in VectorFields, numberOfFields should correspond to the number of FieldRefs defined")
			quit
		}
		
		for i = 1:1:..VectorDictionary.Instances.Count() {
			#dim tInstance As %DeepSee.PMML.Definition.Models.SVM.VectorInstance = ..VectorDictionary.Instances.GetAt(i)
			if (tInstance.Array.n '= tDimensionality) {
				set tSC = $$$ERROR($$$GeneralError, "VectorInstance array length should match the number of fields in VectorFields")
				quit
			}
		}
		quit:$$$ISERR(tSC)
		
		for i = 1:1:..SVMs.Count() {
			
			#dim tSVM as %DeepSee.PMML.Definition.Models.SVM.SupportVectorMachine = ..SVMs.GetAt(i)
			if tSVM.SupportVectors.numberOfSupportVectors && (tSVM.SupportVectors.numberOfSupportVectors '= tSVM.SupportVectors.Vectors.Count()) {
				set tSC = $$$ERROR($$$GeneralError, "If set in SupportVectors, numberOfSupportVectors should equal the number of nested SupportVector elements")
				quit
			}
			
			if tSVM.SupportVectors.numberOfAttributes && (tSVM.SupportVectors.numberOfAttributes '= tDimensionality) {
				set tSC = $$$ERROR($$$GeneralError, "If set in SupportVectors, numberOfAttributes should equal the number of FieldRef elements in VectorFields")
				quit
			}
			
			if tSVM.Coefficients.numberOfCoefficients && (tSVM.Coefficients.numberOfCoefficients '= tSVM.Coefficients.Coefficients.Count()) {
				set tSC = $$$ERROR($$$GeneralError, "If set in Coefficients, numberOfCoefficients should equal the number of nested Coefficient elements")
				quit
			}
			
		}
		quit:$$$ISERR(tSC)
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod %GetModelClass() As %String [ Internal ]
{
	quit "%DeepSee.PMML.Model.SVM"
}

Method %OnValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		for i = 1:1:..VectorDictionary.Fields.FieldRefs.Count() {
			set tSC = ..VectorDictionary.Fields.FieldRefs.GetAt(i).%ValidateNames(.pDictionary)
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
