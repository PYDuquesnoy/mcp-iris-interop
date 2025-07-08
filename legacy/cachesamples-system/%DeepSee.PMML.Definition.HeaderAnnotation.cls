/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.HeaderAnnotation Extends extendableNode [ System = 3 ]
{

Parameter XMLNAME = "Annotation";

Property value As %DeepSee.PMML.Datatype.String(MAXLEN = 20000, XMLPROJECTION = "CONTENT");

}
