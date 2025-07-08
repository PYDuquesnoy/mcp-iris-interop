/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.NormDiscrete Extends (AbstractExpression, %DeepSee.PMML.Definition.extendableNode) [ System = 3 ]
{

Property field As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property mapMissingTo As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE");

Property value As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property method As %DeepSee.PMML.Datatype.String(VALUELIST = ",indicator", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "indicator" ];

Method %ValidateNames(ByRef pDictionary) As %Status
{
	set tSC = $$$OK
	try {
		
		if (..field'="") && '$d(pDictionary("fields", ..field)) && '$$$DUMMYFIELD(..field) {
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
		quit "("_pOverrideSource_"="""_..value_""")"
	} elseif pArrayFormat {
		set pInline=0
		quit $c(9)_"set tValue = $g("_pThis_"("_$$$QUOTE(..field)_")"_$s(..mapMissingTo="":"",1:","_..mapMissingTo)_")" _
		 	 $c(13,10,9)_"set:'$d("_pThis_"("_$$$QUOTE(..field)_")) tStatus = ""missing"""
	} elseif ..mapMissingTo="" {
		set pInline=0
		quit $c(9)_"set tValue = $s(("_pThis_"."_$$$PROPERTYNAME(..field)_"="""_..value_"""):1, 1:0), tStatus = $s("_pThis_".%IsMissing("""_..field_"""):""missing"", 1:""valid"")"
	} else {
		set pInline=1
		quit "$s("_pThis_".%IsMissing("""_..field_"""):"_..mapMissingTo_", ("_pThis_"."_$$$PROPERTYNAME(..field)_"="""_..value_"""):1, 1:0)"
	}
}

Method %GetInputFields(ByRef pFields) As %Status [ Internal ]
{
	set pFields(..field) = ""
	quit $$$OK
}

}
