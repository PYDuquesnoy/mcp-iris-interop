/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.GeneralRegression.BaselineStratum Extends node [ System = 3 ]
{

Property value As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property label As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property maxTime As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property Cells As list Of BaselineCell(XMLNAME = "BaselineCell", XMLPROJECTION = "ELEMENT");

}
