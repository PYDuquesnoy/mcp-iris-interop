/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.SparseArrayInt Extends SparseArray [ System = 3 ]
{

Parameter XMLNAME = "INT-SparseArray";

Property defaultValue As %DeepSee.PMML.Datatype.IntNumber(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 0 ];

Property Entries As %DeepSee.PMML.Datatype.String(MAXLEN = 32000, XMLNAME = "INT-Entries", XMLPROJECTION = "ELEMENT");

}
