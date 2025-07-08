/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Implement CSR:PROPERTY tag that defines a property in the rule class.
/// The NAME attribute specifies the name of the property.
/// The following additional attributes of the property are supported:
/// description
/// final      
/// initial
/// multidimensional
/// private 
/// transient
/// type        
Class %CSP.RuleProperty Extends %CSP.RuleElement [ Not ProcedureBlock, System = 3 ]
{

/// Add the specified property to the rule class that is being created.
Method RenderStartTag() As %Status
{
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering")
 New handle,name,sc
 Set handle=%compiler.Get("%classhandle")
 Set name=..GetAttribute("name")
 Set sc=$$AddProperty^%occModify(handle,name)
 Quit:$$$ISERR(sc) sc
 If ..IsDefined("description") {
 Set sc=$$SetProperty^%occModify(handle,name,$$$cPROPdescription,..GetAttribute("description"))
 Quit:$$$ISERR(sc) sc
 }
 If ..IsDefined("final") {
 Set sc=$$SetProperty^%occModify(handle,name,$$$cPROPfinal,..GetAttribute("final",1))
 Quit:$$$ISERR(sc) sc
 }
 If ..IsDefined("initial") {
 Set sc=$$SetProperty^%occModify(handle,name,$$$cPROPinitialexpression,..GetAttribute("initial"))
 Quit:$$$ISERR(sc) sc
 }
 If ..IsDefined("multidimensional") {
 Set sc=$$SetProperty^%occModify(handle,name,$$$cPROPmultidimensional,..GetAttribute("multidimensional",1))
 Quit:$$$ISERR(sc) sc
 }
 If ..IsDefined("private") {
 Set sc=$$SetProperty^%occModify(handle,name,$$$cPROPprivate,..GetAttribute("private",1))
 Quit:$$$ISERR(sc) sc
 }
 If ..IsDefined("transient") {
 Set sc=$$SetProperty^%occModify(handle,name,$$$cPROPtransient,..GetAttribute("transient",1))
 Quit:$$$ISERR(sc) sc
 }
 If ..IsDefined("type") {
 Set sc=$$SetProperty^%occModify(handle,name,$$$cPROPtype,..GetAttribute("type"))
 Quit:$$$ISERR(sc) sc
 }
 If $$$isLOG("r") $$$LOGSTR(..%ClassName()_": rendering finished")
 Quit $select($$$ISOK(sc):$$$SKIPCHILDREN,1:sc)
}

}
