/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.FieldRef Extends (AbstractExpression, %DeepSee.PMML.Definition.extendableNode) [ System = 3 ]
{

Property field As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property mapMissingTo As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Method %ValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		if '$d(pDictionary("fields", ..field)) && '$$$DUMMYFIELD(..field) {
			set tSC = $$$ERROR($$$GeneralError, "Unknown field: '"_..field_"'")
			quit
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %GetComputeCode(Output pInline As %Boolean = 0, pOverrideSource As %String = "", pThis As %String = ".", pArrayFormat As %Boolean = 0) As %String
{
	if pOverrideSource'="" {
		set pInline = 1
		quit pOverrideSource
	}
	
	if ..mapMissingTo'="" {
		set pInline=1
		if pArrayFormat {
			quit "$g("_pThis_"("_$$$QUOTE(..field)_"), "_$$$QUOTE(..mapMissingTo)_")"
		} else {
			quit "$s("_pThis_".%IsMissing("""_..field_"""):"_$$$QUOTE(..mapMissingTo)_", 1:"_pThis_"."_$$$PROPERTYNAME(..field)_")"
		}
	} else {
		set pInline=0
		if pArrayFormat {
			quit $c(9)_"set tValue = $g("_pThis_"("_$$$QUOTE(..field)_")), tStatus = $d("_pThis_"("_$$$QUOTE(..field)_"))"
		} else {
			quit $c(9)_"set tValue = "_pThis_"."_$$$PROPERTYNAME(..field)_", tStatus = "_pThis_".%GetPropertyStatus("_$$$QUOTE(..field)_")"
		}
	}
}

Method %GetInputFields(ByRef pFields) As %Status [ Internal ]
{
	set pFields(..field) = ""
	quit $$$OK
}

}
