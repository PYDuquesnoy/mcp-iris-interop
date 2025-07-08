/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Util.MatCell Extends %DeepSee.PMML.Definition.node [ System = 3 ]
{

Property row As %DeepSee.PMML.Datatype.IntNumber(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property col As %DeepSee.PMML.Datatype.IntNumber(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property value As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "CONTENT");

}
