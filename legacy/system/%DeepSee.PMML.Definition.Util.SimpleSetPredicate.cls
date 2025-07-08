/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.SimpleSetPredicate Extends Predicate [ System = 3 ]
{

Property field As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE");

Property booleanOperator As %DeepSee.PMML.Datatype.String(VALUELIST = ",isIn,isNotIn", XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property Array As %DeepSee.PMML.Definition.Util.Array(XMLPROJECTION = "ELEMENT") [ Required ];

Method %GetComputeCode(pObj As %String) As %String
{
	do ..Array.ValuesAsArray(.tArray)
	set tList = "", i=""
	for {
		set i = $order(tArray(i),1,tValue)
		quit:i=""
		
		set tList = tList _ $s(tList="":"", 1:",") _ $s(tValue=+tValue:tValue, 1:$$$QUOTE(tValue))
	}
	quit "$s("_$$$PropMissing(pObj,..field)_":$c(0), 1:($lf($lb("_tList_"), "_$$$PropValue(pObj,..field)_")>0))"
}

Method %ValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		if '$d(pDictionary("fields", ..field)) {
			set tSC = $$$ERROR($$$GeneralError, "Unknown field: '"_..field_"'")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %GetAsTree(Output pTree) As %Status [ Internal ]
{
	set pTree = $lb(..field, ..booleanOperator, ..Array.Values)
	quit $$$OK
}

}
