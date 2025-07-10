/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Rule.Model.when Extends Ens.Rule.Model.base [ System = 3 ]
{

Property condition As %String(MAXLEN = "", XMLPROJECTION = "ATTRIBUTE");

Property actions As list Of Ens.Rule.Model.action(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

Property conditionObject As Ens.Rule.Model.expression(XMLPROJECTION = "NONE");

Property comment As %String(MAXLEN = "", XMLNAME = "comment", XMLPROJECTION = "ATTRIBUTE");

Method conditionSet(pValue As %String) As %Status
{
	set i%condition = $g(pValue)
	set tSC = ##class(Ens.Rule.Model.expression).parse($g(pValue),.tObject,1)
	set ..conditionObject = $g(tObject)
	quit tSC
}

}
