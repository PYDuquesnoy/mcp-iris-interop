/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.RuleStart</b> class represents the csr:starttag tag within the DOM model for a CSR page.
Class %CSP.RuleStart Extends %CSP.RuleElement [ System = 3 ]
{

/// Writes default tag rendering for the start tag.
Method RenderStartTag() As %Status
{
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering")
 Set doCmd=$case(%compiler.PageLanguage,"basic":" me.","mvbasic":" %this->",:"	Do ..")
 Do ..WriteServer(doCmd_"RenderDefaultStartTag()")
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
 Quit $$$SKIPCHILDREN
}

}
