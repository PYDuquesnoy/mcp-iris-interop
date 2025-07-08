/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.ModelVerificationFields Extends extendableNode [ System = 3 ]
{

Property Extension As list Of %DeepSee.PMML.Definition.Extension(XMLPROJECTION = "ELEMENT");

Property Fields As list Of %DeepSee.PMML.Definition.ModelVerificationField(XMLNAME = "VerificationField", XMLPROJECTION = "ELEMENT");

}
