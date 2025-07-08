/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.DiscretizeBin Extends %DeepSee.PMML.Definition.extendableNode [ System = 3 ]
{

Property binValue As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property Interval As Interval(XMLPROJECTION = "ELEMENT");

}
