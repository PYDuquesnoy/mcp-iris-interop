/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a string containing a server-side expression.
Class %ZEN.Datatype.expression Extends datatype [ Deprecated, System = 3 ]
{

Parameter XMLPROJECTION = "attribute";

/// The language used for this expression.
Parameter LANGUAGE As STRING = "OBJECTSCRIPT";

Parameter MAXLEN = 2000;

}
