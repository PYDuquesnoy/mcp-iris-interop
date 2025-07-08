/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%CSP.TagSection</b> class is the default class representing
/// a tag that starts a new section
Class %CSP.TagSection Extends %CSP.Element [ Not ProcedureBlock, System = 3 ]
{

/// Setup new section at time of OnMatch.
ClassMethod OnMatch(rule As %CSP.Rule) As %Status
{
 Set rule.NewSection=$zcvt(rule.TagName,"U")
 Quit $$$OK
}

}
