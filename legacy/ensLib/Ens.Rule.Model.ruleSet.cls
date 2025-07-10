/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Rule.Model.ruleSet Extends Ens.Rule.Model.base [ System = 3 ]
{

Property name As %String(MAXLEN = "", XMLPROJECTION = "ATTRIBUTE");

Property actions As list Of Ens.Rule.Model.action(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

Property effectiveBegin As %String(MAXLEN = "", XMLPROJECTION = "ATTRIBUTE");

Property effectiveEnd As %String(MAXLEN = "", XMLPROJECTION = "ATTRIBUTE");

}
