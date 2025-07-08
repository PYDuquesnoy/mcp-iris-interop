/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Decision Extends extendableNode [ System = 3 ]
{

Property value As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property displayValue As %DeepSee.PMML.Datatype.String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

Property description As %DeepSee.PMML.Datatype.String(MAXLEN = 20000, XMLPROJECTION = "ATTRIBUTE");

}
