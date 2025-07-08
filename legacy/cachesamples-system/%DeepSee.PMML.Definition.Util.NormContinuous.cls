/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.NormContinuous Extends (AbstractExpression, %DeepSee.PMML.Definition.extendableNode) [ System = 3 ]
{

Property mapMissingTo As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE");

Property field As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property outliers As %DeepSee.PMML.Datatype.OutlierTreatmentMethod(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "asIs" ];

Property LinearNorms As list Of LinearNorm(XMLNAME = "LinearNorm", XMLPROJECTION = "ELEMENT") [ Required ];

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
	
	if (pOverrideSource'="") {
		$$$WriteLine("set tValue = "_pOverrideSource)
	} elseif pArrayFormat {
		$$$WriteLine("set tValue = $g("_pThis_"("_$$$QUOTE(..field)_")"_$s(..mapMissingTo="":"",1:","_..mapMissingTo)_")")
		$$$WriteLine("set:'$d("_pThis_"("_$$$QUOTE(..field)_")) tStatus = ""missing""")
	} elseif (..mapMissingTo'="") {
		$$$WriteLine("set tValue = $s("_pThis_".%IsMissing("""_..field_"""):"_..mapMissingTo_", 1:"_pThis_"."_$$$PROPERTYNAME(..field)_")")
	} else {
		$$$WriteLine("set tValue = "_pThis_"."_$$$PROPERTYNAME(..field)_", tStatus = "_pThis_".%GetPropertyStatus("""_..field_""")")
	}
	
	set tCount = ..LinearNorms.Count()
	$$$WriteLine("if (tValue = """") {}")
	$$$WriteLine("elseif (tValue < "_..LinearNorms.GetAt(1).orig_") {")
	if (..outliers = "asMissingValues") {
		$$$WriteLine($c(9)_"set tValue = """", tStatus = ""missing""")
	} elseif (..outliers = "asExtremeValues") {
		$$$WriteLine($c(9)_"set tValue = "_..LinearNorms.GetAt(1).norm)
	} else {
		set n1 = ..LinearNorms.GetAt(1), n2 = ..LinearNorms.GetAt(2)
		set x1 = n1.orig, x2 = n2.orig, y1 = n1.norm, y2 = n2.norm
		if (y1=y2) {
			$$$WriteLine($c(9)_"set tValue = "_y1)
		} else {
			$$$WriteLine($c(9)_"set tValue = "_y1_" + (((tValue-"_x1_")/("_x2_"-"_x1_"))*("_y2_"-"_y1_"))")
		}
	}
	
	for i = 1:1:..LinearNorms.Count()-1 {
		set n1 = ..LinearNorms.GetAt(i), n2 = ..LinearNorms.GetAt(i+1)
		set x1 = n1.orig, x2 = n2.orig, y1 = n1.norm, y2 = n2.norm
		
		$$$WriteLine("} elseif (tValue <= "_x2_") {")
		if (y1=y2) {
			$$$WriteLine($c(9)_"set tValue = "_y1)
		} else {
			$$$WriteLine($c(9)_"set tValue = "_y1_" + (((tValue-"_x1_")/("_x2_"-"_x1_"))*("_y2_"-"_y1_"))")
		}
	}
	
	$$$WriteLine("} else {")
	if (..outliers = "asMissingValues") {
		$$$WriteLine($c(9)_"set tValue = """", tStatus = ""missing""")
	} elseif (..outliers = "asExtremeValues") {
		$$$WriteLine($c(9)_"set tValue = "_..LinearNorms.GetAt(tCount).norm)
	} else {
		set n1 = ..LinearNorms.GetAt(tCount-1), n2 = ..LinearNorms.GetAt(tCount)
		set x1 = n1.orig, x2 = n2.orig, y1 = n1.norm, y2 = n2.norm
		if (y1=y2) {
			$$$WriteLine($c(9)_"set tValue = "_y1)
		} else {
			$$$WriteLine($c(9)_"set tValue = "_y1_" + (((tValue-"_x1_")/("_x2_"-"_x1_"))*("_y2_"-"_y1_"))")
		}
	}
	$$$WriteLine("}")
	
	quit tCode
}

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		 if ..LinearNorms.Count() < 2 {
			set tSC = $$$ERROR($$$GeneralError, "NormContinuous should have at least 2 nested LinearNorm elements") 
			quit
		 }
		 
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method %GetInputFields(ByRef pFields) As %Status [ Internal ]
{
	set pFields(..field) = ""
	quit $$$OK
}

}
