/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.GeneralRegression.PPCovMatrix Extends node [ System = 3 ]
{

Property type As %DeepSee.PMML.Datatype.String(VALUELIST = ",model,robust", XMLPROJECTION = "ATTRIBUTE");

Property Cells As list Of PPCovCell(XMLNAME = "PPCovCell", XMLPROJECTION = "ELEMENT");

}
