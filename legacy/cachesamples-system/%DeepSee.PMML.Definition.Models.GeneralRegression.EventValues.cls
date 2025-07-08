/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.GeneralRegression.EventValues Extends node [ System = 3 ]
{

Property Values As list Of %DeepSee.PMML.Definition.Util.Value(XMLNAME = "Value", XMLPROJECTION = "ELEMENT");

Property Intervals As list Of %DeepSee.PMML.Definition.Util.Interval(XMLNAME = "Interval", XMLPROJECTION = "ELEMENT");

}
