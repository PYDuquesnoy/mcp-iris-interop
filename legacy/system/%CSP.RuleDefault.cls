/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.RuleDefault</b> class represents the csr:default tag within the DOM model for a CSR page.
Class %CSP.RuleDefault Extends %CSP.RuleElement [ System = 3 ]
{

/// Writes default tag rendering and remaining code into the 
/// routine builder object in the "End" section.
Method RenderStartTag() As %Status
{
	If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering")
	Set basic=%compiler.IsBasic
	If %compiler.PageLanguage="basic" {
		Do ..WriteServer(" me.RenderDefaultStartTag()")
		Do ..WriteServer(" Return "_$$$PROCESSCHILDREN)
	} ElseIf %compiler.PageLanguage="mvbasic" {
		Do ..WriteServer(" %this->RenderDefaultStartTag()")
		Do ..WriteServer(" Return "_$$$PROCESSCHILDREN)
	} Else {
		Do ..WriteServer("	Do ..RenderDefaultStartTag()")
		Do ..WriteServer("	Quit $$$PROCESSCHILDREN")
	}
	;
	Do ..PopDefaultSection()
	Do ..PushDefaultSection("End")
	; Set element var for compatability
	If %compiler.PageLanguage="basic" {
		Do ..WriteServer(" element=me")
		Do ..WriteServer(" me.RenderDefaultEndTag()")
	} ElseIf %compiler.PageLanguage="mvbasic" {
		Do ..WriteServer(" element=%this")
		Do ..WriteServer(" %this->RenderDefaultEndTag()")
	} Else {
		Do ..WriteServer("	New element Set element=$this")
		Do ..WriteServer("	Do ..RenderDefaultEndTag()")
	}
	If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
	Quit $$$SKIPCHILDREN
}

}
