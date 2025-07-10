/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Projection.Rule Extends %Projection.AbstractProjection [ ClassType = "", ProcedureBlock, System = 4 ]
{

ClassMethod CreateProjection(classname As %String, ByRef parameters As %String) As %Status
{
	if classname="Ens.Rule.Definition" quit $$$OK
	;
	set tSC=$$$OK
	set tLocked = 0
	try {
		; ^IRIS.TempEnsRule("class",classname) is setup in Ens.Rule.Generation
		set alias=$g(^IRIS.TempEnsRule("class",classname))
		;
		lock +^Ens.Rule:1
		if ('$test) {
			set tSC=$$$ERROR($$$LockFailedToAcquireExclusive)
			quit
		}
		set tLocked = 1
		;
		set tSC = ..ValidateAlias(classname,alias)
		Quit:$$$ISERR(tSC)
		;
		if alias'="" set ^Ens.Rule("alias",alias)=classname
		set ^Ens.Rule("class",classname)=alias
		;
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	if tLocked {
		lock -^Ens.Rule
	}
	quit tSC
}

/// General-purpose method to ensure that there are no alias collisions.
ClassMethod ValidateAlias(classname As %String = "", alias As %String = "") As %Status
{
	set tSC = $$$OK
	try {
		if classname="" quit
		if alias'="" {
			if $d(^Ens.Rule("alias",alias),classname2)#2 && (classname2'=classname) {
				set tSC=$$$ERROR($$$EnsErrRuleAliasConflict,alias,classname,classname2)
				quit
			}
			if $d(^Ens.Rule("class",alias),alias2)#2 && (alias2="") {
				set tSC=$$$ERROR($$$EnsErrRuleAliasAsClassname,alias,classname)
				quit
			}
		}
		elseif (alias="") && $d(^Ens.Rule("alias",classname),classname2)#2 {
			set tSC=$$$ERROR($$$EnsErrRuleClassnameAsAlias,classname,classname2)
			quit
		}
	} catch {
		Set tSC = $$$SystemError
	}
	quit tSC
}

ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean, modified As %String) As %Status
{
	set alias=$g(^Ens.Rule("class",classname))
	if alias'="" kill ^Ens.Rule("alias",alias)
	kill ^Ens.Rule("class",classname)
	quit $$$OK
}

/// Return the class name for the rule class or alias supplied in <var>alias</var>.
ClassMethod ResolveRuleAlias(alias As %String = "") As %String
{
	if $g(alias)="" quit ""
	if $d(^Ens.Rule("alias",alias),classname)#2 quit classname
	if $d(^Ens.Rule("class",alias))'=0 quit alias
	#;account for mapped rules that have not been compiled locally
	if ##class(%Dictionary.CompiledClass).%ExistsId(alias) quit alias
	quit ""
}

/// Retrieve all known rule classes and aliases in subscripts of <var>list</var>.
/// In the case of aliases, the class name is returned as the value at the alias's subscript.
ClassMethod GetRuleNameList(Output list As %String) As %String
{
	set name=""
	for {
		set name=$order(^Ens.Rule("class",name))
		quit:name=""
		set list(name)=""
	}
	set name=""
	for {
		set name=$order(^Ens.Rule("alias",name),1,classname)
		quit:name=""
		set list(name)=classname
	}
	quit $$$OK
}

}
