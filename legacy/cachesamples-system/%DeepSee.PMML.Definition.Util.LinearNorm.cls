/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.LinearNorm Extends %DeepSee.PMML.Definition.extendableNode [ System = 3 ]
{

Property orig As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property norm As %DeepSee.PMML.Datatype.Number(XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
