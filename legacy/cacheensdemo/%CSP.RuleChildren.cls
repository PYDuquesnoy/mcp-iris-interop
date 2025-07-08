/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.RuleChildren</b> class represents the csr:children tag within the DOM model for a CSR page.
Class %CSP.RuleChildren Extends %CSP.RuleElement [ System = 3 ]
{

/// Writes remaining code into the routine builder object
/// in the "End" section.
Method RenderStartTag() As %Status
{
	If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering")
	If %compiler.PageLanguage["basic" {
		Do ..WriteServer(" Return "_$$$PROCESSCHILDREN)
	} Else {
		Do ..WriteServer("	Quit $$$PROCESSCHILDREN")
	}
	Do ..PopDefaultSection()
	Do ..PushDefaultSection("End")
	; Set element var for compatability
	If %compiler.PageLanguage="basic" {
		Do ..WriteServer(" element=me")
	} ElseIf %compiler.PageLanguage="mvbasic" {
		Do ..WriteServer(" element=%this")
	} Else {
		Do ..WriteServer("	New element Set element=$this")
	}
	If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
	Quit $$$SKIPCHILDREN
}

}
