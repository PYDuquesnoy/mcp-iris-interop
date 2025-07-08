/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %cspBuild

IncludeGenerator %cspBuild

/// The <CLASS>%CSP.RuleMgr</CLASS> class provides an interface for managing 
/// the rules used by the CSP compiler.
Class %CSP.RuleMgr Extends %RegisteredObject [ Not ProcedureBlock, System = 3 ]
{

/// Return true if the rule exists.
ClassMethod RuleExists(name As %String, family As %String = "csp") As %Boolean
{
 Quit ''$D(^cspRule(family,"rule",name))
}

/// RuleList query returns all rules.
Query RuleList(family As %String = "csp") As %Query(ROWSPEC = "RuleName:%String,Match:%String,Description:%String,Empty:%Integer")
{
}

/// Execute method for RuleList query.
ClassMethod RuleListExecute(ByRef QHandle As %Binary, family As %String = "csp") As %Status
{
 ; qhandle is $LB(family,rulename)
 Set:family="" family="csp"
 Set QHandle=$LB(family,"",0)
 Quit $$$OK
}

/// Close method for RuleList query.
ClassMethod RuleListClose(QHandle As %Binary) As %Status
{
 Quit $$$OK
}

/// Fetch method for RuleList query.
ClassMethod RuleListFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
 New family,rule,match,description,empty,isuser
 Set Row="",AtEnd=0

 Set family=$LG(QHandle,1)
 Set rule=$LG(QHandle,2)
 Set isuser=$LG(QHandle,3)

 If isuser Set rule=$Order($$$uruleRoot(family,rule))
 Else  Set rule=$Order($$$sruleRoot(family,rule))
 If rule="",isuser=0 Set rule=$Order($$$uruleRoot(family,rule)),isuser=1

 Set QHandle=$LB(family,rule,isuser)
 If rule="",isuser=1 Set AtEnd=1 Quit $$$OK

 Set match=$$DumpMatch^%cspRule(family,rule)
 Set description=$G($$$mruleDescription(family,rule))
 Set empty=$G($$$mruleEmpty(family,rule),0)

 ; name,match,description,empty
 Set Row=$LB(rule,match,description,empty)

 Quit $$$OK
}

}
