/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.RuleClass</b> class implements the csr:class tag for a CSR page.
Class %CSP.RuleClass Extends %CSP.RuleElement [ Not ProcedureBlock, System = 3 ]
{

/// Save the attributes of csr:class for the compiler.
Method RenderStartTag() As %Status
{
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering")
 If ..IsDefined("IMPORT") Do %compiler.Set("%cspclass.IMPORT",..GetAttribute("IMPORT"))
 If ..IsDefined("SUPER") Do %compiler.Set("%cspclass.SUPER",..GetAttribute("SUPER"))
 If ..IsDefined("INCLUDES") Do %compiler.Set("%cspclass.INCLUDES",..GetAttribute("INCLUDES"))
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
 Quit $select($$$ISOK(sc):$$$SKIPCHILDREN,1:sc)
}

}
