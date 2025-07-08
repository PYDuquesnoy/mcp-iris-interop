/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.Discretize Extends (AbstractExpression, %DeepSee.PMML.Definition.extendableNode) [ System = 3 ]
{

Property field As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property mapMissingTo As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property defaultValue As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property dataType As %DeepSee.PMML.Datatype.DataType(XMLPROJECTION = "ATTRIBUTE");

Property Bins As list Of DiscretizeBin(XMLNAME = "DiscretizeBin", XMLPROJECTION = "ELEMENT");

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
	set pInline = 0, tCode = ""
	
	#define WriteLine(%s) set tCode = $s(tCode="":$c(9), 1:tCode_$c(13,10,9)) _ %s
	
	set tQuote = (..dataType="string") || (..dataType="")
	
	set tFirstCondition = 1
	if (pOverrideSource="") {
		if pArrayFormat {
			$$$WriteLine("set tValue = $g("_pThis_"("_$$$QUOTE(..field)_")"_$s(..mapMissingTo="":"",tQuote:","_$$$QUOTE(..mapMissingTo),1:","_..mapMissingTo)_")")
			$$$WriteLine("set:'$d("_pThis_"("_$$$QUOTE(..field)_")) tStatus = ""missing""")
		} else {
			$$$WriteLine("set tValue = "_pThis_"."_$$$PROPERTYNAME(..field))
			$$$WriteLine("if ("_pThis_".%IsMissing("""_..field_""")) { // missing value")
			if (..mapMissingTo'="") {
				$$$WriteLine($c(9)_"set tValue = "_$s(tQuote:""""_..mapMissingTo_"""", 1:..mapMissingTo))
			} else {
				$$$WriteLine($c(9)_"set tStatus = ""missing""")
			}
			set tFirstCondition = 0
		}
	} else {
		$$$WriteLine("set tValue = "_pOverrideSource)
	}
	
	for i = 1:1:..Bins.Count() {
		#dim tBin As DiscretizeBin = ..Bins.GetAt(i)
		if (tFirstCondition) {
			$$$WriteLine("if "_tBin.Interval.%GetAsCondition("tValue")_" {")
			set tFirstCondition = 0
		} else {
			$$$WriteLine("} elseif "_tBin.Interval.%GetAsCondition("tValue")_" {")
		}
		$$$WriteLine($c(9)_"set tValue = "_$s(tQuote:""""_tBin.binValue_"""", 1:tBin.binValue))
	}
	
	$$$WriteLine("} else { // no matching interval")
	if (..defaultValue'="") {
		$$$WriteLine($c(9)_"set tValue = "_$s(tQuote:""""_..defaultValue_"""", 1:..defaultValue))
	} else {
		$$$WriteLine($c(9)_"set tValue = """", tStatus = ""missing""")
	}
	$$$WriteLine("}")
	
	quit tCode
}

Method %GetInputFields(ByRef pFields) As %Status [ Internal ]
{
	set pFields(..field) = ""
	quit $$$OK
}

}
