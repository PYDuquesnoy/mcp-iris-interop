/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS.
/// You should not make direct use of it within your applications.
/// There is no guarantee made about either the behavior or future operation of this class.<p>
/// 
/// The <b>%CSP.RuleDescription</b> class represents the csr:description tag within the DOM model for a CSR page.
Class %CSP.RuleDescription Extends %CSP.RuleElement [ Not ProcedureBlock, System = 3 ]
{

/// Save description of rule.
Method RenderStartTag() As %Status [ Internal ]
{
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering")
 Do ..TrimChildren()
 New sc,description
 Set description=$select(..Children.Count()=0:"",
 1:..Children.GetAt(1).Text)
 Set sc=$$SetRule^%cspRule(%compiler.Get("%rulehandle"),$$$cRULEdescription,description)
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
 Quit $select($$$ISOK(sc):$$$SKIPCHILDREN,1:sc)
}

}
