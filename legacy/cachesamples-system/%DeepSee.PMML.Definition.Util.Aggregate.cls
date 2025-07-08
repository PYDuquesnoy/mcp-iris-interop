/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.Aggregate Extends (AbstractExpression, %DeepSee.PMML.Definition.extendableNode) [ System = 3 ]
{

Property field As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property function As %DeepSee.PMML.Datatype.String(VALUELIST = ",count,sum,average,min,max,multiset", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property groupField As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE");

Property sqlWhere As %DeepSee.PMML.Datatype.String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

Method %ValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		if '$d(pDictionary("fields", ..field)) {
			set tSC = $$$ERROR($$$GeneralError, "Unknown field: '"_..field_"'")
			quit
		}
		
		if (..groupField'="") && '$d(pDictionary("fields", ..groupField)) {
			set tSC = $$$ERROR($$$GeneralError, "Unknown field: '"_..groupField_"'")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %GetComputeCode(Output pInline As %Boolean = 0, pOverrideSource As %String = "", pThis As %String = ".", pArrayFormat As %Boolean = 0) As %String
{
	set pInline = 0 // TODO
	quit "	// <Aggregate> is currently not implemented"
}

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	quit $$$ERROR($$$NotImplemented)
}

Method %GetInputFields(ByRef pFields) As %Status [ Internal ]
{
	set pFields(..field) = ""
	quit $$$OK
}

}
