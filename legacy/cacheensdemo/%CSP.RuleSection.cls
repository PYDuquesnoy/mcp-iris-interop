/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.RuleSection</b> class represents the csr:section tag within the DOM model for a CSR page.
Class %CSP.RuleSection Extends %CSP.RuleElement [ Not ProcedureBlock, System = 3 ]
{

/// Writes code into the routine builder object that will 
/// put the child lines in a new section.
Method RenderStartTag() As %Status
{
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": start tag rendering")
 Do ..TrimChildren()
 Do ..WriteServer($case(%compiler.PageLanguage,"basic":" me.","mvbasic":" %this->",:"	Do ..")_"PushDefaultSection("_$$Quote^%cspQuote(..GetAttribute("NAME")_","_..GetAttribute("BLOCK",0))_")")
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
 Quit $$$PROCESSCHILDREN
}

/// Writes code into the routine builder object that will 
/// resume sending output to the previous section.
Method RenderEndTag() As %Status
{
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": end tag rendering")
 Do ..WriteServer($case(%compiler.PageLanguage,"basic":" me.","mvbasic":" %this->",:"	Do ..")_"PopDefaultSection()")
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
 Quit $$$OK
}

}
