/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.RuleDocument</b> class represents a CSR rule.
Class %CSP.RuleDocument Extends %CSP.Document [ System = 3 ]
{

/// Setup CSR file for compiling.  No %CSP.PageBuilder is yet
/// defined, so no output will be written to any CSR class.
Method RenderStartTag() As %Status
{
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": start tag rendering")
 Set sc=$$$OK
 Kill %builder   ; just to make sure no problems during testing
 If '$$IsFamilyDefined^%apiCSP($$$cFAMILYDEFAULT) {
	Set sc=$$AddFamily^%cspRule($$$cFAMILYDEFAULT,,,,1)
 }
 Quit $select($$$ISOK(sc):$$$PROCESSCHILDREN,1:sc)
}

/// Compile of CSR file complete.  
/// Check for duplicate rules.
Method RenderEndTag() As %Status
{
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": end tag rendering")
 Set (isSystem,isLocal)=0
 Set rulename=%compiler.NextByKey("%CSPRules","")
 while rulename'="" {
	If $extract(rulename)="%" {
		Set isSystem=1
	} Else {
		Set isLocal=1
	}
	Set rulename=%compiler.NextByKey("%CSPRules",rulename)
 }
 If isSystem && isLocal Quit $$$ERROR($$$CSPRuleMixed)
 Merge qstruct=%compiler.qstruct
 Set sc=$$CompileFamily^%apiCSP($$$cFAMILYDEFAULT,isSystem,.qstruct)
 If $$$ISOK(sc)&&%compiler.IsDefinedByKey("%CSPRule","duplicate") {
	Quit $$$ERROR($$$CSPRuleDuplicate,%compiler.GetByKey("%CSPRule","duplicate"))
 }
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
 Quit sc
}

}
