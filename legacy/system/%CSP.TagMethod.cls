/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Implement SCRIPT LANGUAGE=CACHE METHOD= tag.
Class %CSP.TagMethod Extends %CSP.Rule [ System = 3 ]
{

/// Create a new method based on the children of this script tag.
Method CreateMethod(name As %String, language As %String, classmethod As %Boolean = 1, procedureblock As %Boolean = "") As %Status [ Internal ]
{
	; start method definition
	Set handle=%compiler.Get("%classhandle")
	$$$cspStartMethodImplementationEx(handle,name,statuscode)
	If $$$ISERR(statuscode) Quit statuscode
	; save language 
	Set pageIsBasic=%compiler.IsBasic
	Set pageLanguage=%compiler.PageLanguage
	Set %compiler.PageLanguage=language
	Set %compiler.IsBasic=(language="basic")
	; create code
	Set linesOut=0
	For i=1:1:..Children.Count() {
	 	Set lines=..Children.GetAt(i).Text
	 	If (i=1)&&($e(lines,1,2)=$$$EOL) Set lines=$e(lines,3,$length(lines))
	 	For j=1:1:$l(lines,$$$EOL) {
	 		Set line=$p(lines,$$$EOL,j)
	 		For s=1:1:$l(line)+1 q:$e(line,s)'=" "
			If $e(line,s)=":" {
				Set line=$e(line,s+1,$l(line))
			} Else {
				Set line=" "_line
			}
			// Resolve ##( )## only in a page method, not a rule method
			If %compiler.Get("%rulename")="" {
	 			Set line=$$resolvePP^%cspQuote(line)
			}
			$$$cspAddMethodLine(handle,name,$i(linesOut),line)
	 	}
	}
	$$$cspFinishMethodImplementation(handle,name,linesOut)
	; restore language flag
	Set %compiler.IsBasic=pageIsBasic
	Set %compiler.PageLanguage=pageLanguage
	; set method keywords
	Do SetMethod^%occModify(handle,name,$$$cMETHcodemode,$$$cMETHCODEMODECODE)
	Do SetMethod^%occModify(handle,name,$$$cMETHclassmethod,classmethod)
	If procedureblock'="" Do SetMethod^%occModify(handle,name,$$$cMETHprocedureblock,procedureblock)
	If language'="" Do SetMethod^%occModify(handle,name,$$$cMETHlanguage,language)
	Quit $$$OK
}

/// Writes code into the routine builder object to render the
/// script tag.
Method RenderStartTag() As %Status
{
	Set type=$select($zcvt(..TagName,"U")="CSP:METHOD":"NAME",1:"METHOD")
	Set name=..GetAttribute(type) 
	If name="" Quit $$$SKIPCHILDREN
	If $zcvt(..TagName,"U")'="CSP:METHOD" {
	 	Set language=$zcvt(..GetAttribute("LANGUAGE"),"L")
	} Else {
		 Set language=""
	}
	If '..GetAttribute("CLASSMETHOD",1) && (%compiler.Get("%cspDocObject").Family=$$$cFAMILYCSP) {
		Quit $$$ERROR($$$CSPMustBeClassmethod,..LineNumber)
	}
	Set procedureblock=..GetAttribute("PROCEDUREBLOCK")
	If procedureblock'="" Set procedureblock=''procedureblock
	Set statuscode=..CreateMethod(name,language,''..GetAttribute("CLASSMETHOD",1),procedureblock)
	Set handle=%compiler.Get("%classhandle")
	Do SetMethod^%occModify(handle,name,$$$cMETHformalspec,$tr($zstrip(..GetAttribute("ARGUMENTS"),"<>W"),$c(13,10,9),"   "))
	If $$$ISERR(statuscode) Quit statuscode
	Set key=""
	Do ..TagAttributes.GetNext(.key)
	While key'="" {
	 	If (key'=type)&&(key'="ARGUMENTS")&&(key'="LANGUAGE")&&(key'="RUNAT") {
	 		Set vlist=..TagAttributes.GetAt(key)
	 		Set id=$$$tableSubExtToXMLGet($$$cCLASSmethod,key)
	 		If id'="" Set id=$list(id)
	 		If id'="" {
		 		Do SetMethod^%occModify(handle,name,id,$lg(vlist,1,1))
	 		} Else {
		 		Set statuscode=$$$ERROR($$$CSPUnexpectedAttribute,key,..LineNumber)
		 		Quit
	 		}
	 	}
	 	Do ..TagAttributes.GetNext(.key)
	}
	If $$$ISERR(statuscode) Quit statuscode
	Quit $$$SKIPCHILDREN
}

}
