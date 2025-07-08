/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.SVM.VectorInstance Extends node [ System = 4 ]
{

Property id As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property Array As %DeepSee.PMML.Definition.Util.AbstractArray(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

}
