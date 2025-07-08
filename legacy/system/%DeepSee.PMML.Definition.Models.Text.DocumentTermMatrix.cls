/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.Text.DocumentTermMatrix Extends %DeepSee.PMML.Definition.node [ System = 3 ]
{

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Property Matrix As %DeepSee.PMML.Definition.Util.Matrix(XMLPROJECTION = "ELEMENT");

}
