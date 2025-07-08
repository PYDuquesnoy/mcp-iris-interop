/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.GeneralRegression.BaseCumHazardTables Extends node [ System = 3 ]
{

Property maxTime As %DeepSee.PMML.Datatype.RealNumber(XMLPROJECTION = "ATTRIBUTE");

Property BaselineStratum As list Of BaselineStratum(XMLPROJECTION = "ELEMENT");

Property BaselineCells As list Of BaselineCell(XMLNAME = "BaselineCell", XMLPROJECTION = "ELEMENT");

}
