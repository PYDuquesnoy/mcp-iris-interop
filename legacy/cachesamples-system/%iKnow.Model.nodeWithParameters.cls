/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Model.nodeWithParameters Extends %iKnow.Model.node [ Abstract, Deprecated, System = 3 ]
{

Relationship parameters As array Of %iKnow.Model.parameter(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE") [ Cardinality = many, Inverse = parent ];

}
