/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %iKnow.Classification.Definition.MetadataProperty Extends node [ Deprecated, System = 3 ]
{

/// The name of the metadata field to include in the analysis.
Property name As %String(XMLPROJECTION = "ATTRIBUTE") [ Required ];

}
