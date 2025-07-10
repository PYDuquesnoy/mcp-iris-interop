/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Rule.Model.foreach Extends Ens.Rule.Model.action [ System = 3 ]
{

Property propertypath As %String(MAXLEN = "", XMLPROJECTION = "ATTRIBUTE");

Property whens As list Of Ens.Rule.Model.when(XMLNAME = "when", XMLPROJECTION = "ELEMENT");

Property otherwise As Ens.Rule.Model.otherwise;

}
