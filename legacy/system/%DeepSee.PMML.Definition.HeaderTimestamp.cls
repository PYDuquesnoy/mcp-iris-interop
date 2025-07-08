/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.HeaderTimestamp Extends extendableNode [ System = 3 ]
{

Parameter XMLNAME = "Timestamp";

Property value As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "CONTENT");

}
