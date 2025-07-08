/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.Value Extends DataFieldRange [ System = 3 ]
{

Property value As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property displayValue As %DeepSee.PMML.Datatype.String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

Property property As %DeepSee.PMML.Datatype.String(VALUELIST = ",valid,invalid,missing", XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = "valid" ];

}
