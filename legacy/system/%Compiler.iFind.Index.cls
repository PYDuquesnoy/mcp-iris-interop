/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %IFInclude

Class %Compiler.iFind.Index [ Abstract, System = 2 ]
{

ClassMethod GenerateGlobalNames(pClass As %String(MAXLEN=""), pIndex As %String(MAXLEN=""))
{
	set tAddress = $Order($$$EXTADDR($$$pEXT,pClass,""))
	while (tAddress '= "") && ($Get($$$EXTADDRindex($$$pEXT,pClass,tAddress)) '= pIndex) {
		set tAddress = $Order($$$EXTADDR($$$pEXT,pClass,tAddress))
	}
	if tAddress '= "" {
			// Build index location
		set tBaseGlobal = $$$EXTADDRglobal($$$pEXT,pClass,tAddress)
		set tExtended = ""
		set tSub = $order($$$EXTADDRSUB($$$pEXT,pClass,pIndex,""))
		while (tSub '= "") && ($Get($$$EXTADDRSUBliteral($$$pEXT,pClass,pIndex,tSub))) {
			set tExtended = tExtended _ "," _ $$$EXTADDRSUBexpression($$$pEXT,pClass,pIndex,tSub)
			set tSub = $order($$$EXTADDRSUB($$$pEXT,pClass,pIndex,tSub))
		}
		if tExtended '= "" { set tExtended = "(" _ $Extract(tExtended,2,*) _ ")" }
		set $$$EXTIDXGLOBAL($$$pEXT,pClass,pIndex,$$$IFGLOBALINDEXLOC) = tBaseGlobal _ tExtended
	}
}

ClassMethod GetDataGlobalAndColumn(pClass As %String(MAXLEN=""), pIndex As %String(MAXLEN=""), ByRef pFetchCode As %String(MAXLEN="") = "", ByRef pStreamLoc As %String(MAXLEN="") = "", ByRef pCalcCode As %String(MAXLEN=""), ByRef pType As %String(MAXLEN="") = "")
{
	set pFetchCode="", pStreamLoc="", pCalcCode=""
	
	set tProp = $$$EXTIDXPROP($$$pEXT, pClass, pIndex, 1)
	set pType = $$$EXTPROPtype($$$pEXT, pClass, tProp)
	set pFetchCode = $get($$$EXTPROPondisk($$$pEXT, pClass, tProp))
	if (pFetchCode="") {
		// Calculated Field
		set pFetchCode = $$$EXTPROPondisk($$$pEXT, pClass, "%%CLASSNAME")
		if ($get($$$EXTPROPlogicalexpression($$$pEXT, pClass, tProp)) '= "") {
			set pCalcCode = tProp_"Get()"
		}
		//set pCalcCode = $$$EXTPROPlogicalexpression($$$pEXT, pClass, tProp)
	}
	
	if ($$$comClassKeyGet(pType,$$$cCLASSsqlcategory)'=$$$cCLASSSQLCATEGORYSTRING) {
		set pStreamLoc = $$$EXTPROPstreamlocation($$$pEXT, pClass, tProp)
	}
}

ClassMethod GetGlobalForAppend(pClass, pIndex, pGlobal) As %String(MAXLEN="")
{
	set tGlobalRef = $Get($$$EXTIDXGLOBAL($$$pEXT,pClass,pIndex,pGlobal))
	quit $Select(tGlobalRef="":"",$Extract(tGlobalRef,*) = ")":$Extract(tGlobalRef,1,*-1)_",",1:tGlobalRef_"(")
}

}
