/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.RuleAction</b> class represents the csr:action tag within the DOM model for a CSR page.
Class %CSP.RuleAction Extends %CSP.RuleElement [ Not ProcedureBlock, System = 3 ]
{

/// Writes code into the routine builder object that will prepare
/// the children of the csr:action tag.
Method RenderStartTag() As %Status
{
 If '%compiler.IsDefined("%pagebuilder") Quit $$$SKIPCHILDREN

 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering")
 Do ..TrimChildren()
 ; Delay creation of builder object to
 Set %builder=%compiler.Get("%pagebuilder")
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
 Quit $$$PROCESSCHILDREN
}

/// Default rendering of the end tag is a no operation
Method RenderEndTag() As %Status
{
 kill %builder
 Quit $$$OK
}

}
