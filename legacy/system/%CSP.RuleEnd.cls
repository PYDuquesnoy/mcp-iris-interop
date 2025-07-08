/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.RuleEnd</b> class represents the csr:endtag tag within the DOM model for a CSR page.
Class %CSP.RuleEnd Extends %CSP.RuleElement [ Not ProcedureBlock, System = 3 ]
{

/// Writes default tag rendering for the end tag.
Method RenderStartTag() As %Status
{
	If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering")
	Do ..WriteServer($case(%compiler.PageLanguage,"basic":" me.","mvbasic":" %this->",:"	Do ..")_"RenderDefaultEndTag()")
	If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
	Quit $$$SKIPCHILDREN
}

}
