/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.Rule.Model.constraint Extends Ens.Rule.Model.action [ System = 3 ]
{

Property name As %String(MAXLEN = "", XMLPROJECTION = "ATTRIBUTE");

Property value As %String(MAXLEN = "", XMLPROJECTION = "ATTRIBUTE");

}
