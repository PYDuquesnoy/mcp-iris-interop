/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Rule.Model.send Extends Ens.Rule.Model.action [ System = 3 ]
{

Property transform As %String(MAXLEN = "", XMLPROJECTION = "ATTRIBUTE");

Property target As %String(MAXLEN = "", XMLPROJECTION = "ATTRIBUTE");

}
