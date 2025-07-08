/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.TargetValue Extends extendableNode [ System = 3 ]
{

Property value As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property displayValue As %DeepSee.PMML.Datatype.String(MAXLEN = 2000, XMLPROJECTION = "ATTRIBUTE");

Property priorProbability As %DeepSee.PMML.Datatype.ProbNumber(XMLPROJECTION = "ATTRIBUTE");

Property defaultValue As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE");

}
