/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class represents a reference to a set of strings, possibly annotated with metadata, for use
/// in a TT model.
Class %iKnow.TextTransformation.Model.SetReference Extends node [ Deprecated, System = 3 ]
{

Property name As %String(XMLPROJECTION = "ATTRIBUTE");

Property type As %String(VALUELIST = ",set,xdata", XMLPROJECTION = "ATTRIBUTE");

}
