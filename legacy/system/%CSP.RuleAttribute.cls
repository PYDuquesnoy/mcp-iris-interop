/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.RuleAttribute</b> class represents the csr:attribute tag within the DOM model for a CSR page.
Class %CSP.RuleAttribute Extends %CSP.RuleElement [ Not ProcedureBlock, System = 3 ]
{

/// Save a rule attribute.
Method RenderStartTag() As %Status
{
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering")
 New sc,name,default,required,type,description
 Set name=..GetAttribute("name")
 Set required=..IsDefined("required")
 If ..IsDefined("default") Set default=..GetAttribute("default")
 If ..IsDefined("type") Set type=..GetAttribute("type")
 If ..IsDefined("description") Set description=..GetAttribute("description")
 Set sc=$$AddAttribute^%cspRule(%compiler.Get("%rulehandle"),name,.default,required,.type,.description)
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
 Quit $select($$$ISOK(sc):$$$SKIPCHILDREN,1:sc)
}

}
