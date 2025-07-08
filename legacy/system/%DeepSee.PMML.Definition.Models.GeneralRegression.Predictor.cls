/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %DeepSee.PMML.Definition.Models.GeneralRegression.Predictor Extends node [ System = 3 ]
{

Property name As %DeepSee.PMML.Datatype.FieldName(XMLPROJECTION = "ATTRIBUTE") [ Required ];

Property contrastMatrixType As %DeepSee.PMML.Datatype.String(XMLPROJECTION = "ATTRIBUTE");

Property Categories As Categories(XMLPROJECTION = "ELEMENT");

Property ContrastMatrix As %DeepSee.PMML.Definition.Util.Matrix(XMLNAME = "Matrix", XMLPROJECTION = "ELEMENT");

/// Adds node-specific validation checks
Method %OnValidateObject(force As %Integer) As %Status [ Private, ServerOnly = 1 ]
{
	set tSC = $$$OK
	try {
		
		// TODO: contrast matrix input checking?
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

}
