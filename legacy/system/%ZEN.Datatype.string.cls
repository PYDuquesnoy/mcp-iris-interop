/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This datatype represents a string value.
Class %ZEN.Datatype.string Extends datatype [ Deprecated, System = 3 ]
{

Parameter XMLPROJECTION = "attribute";

Parameter MAXLEN = 32000;

/// Define this here to allow overrides in special cases.
Parameter ZENSETTING As BOOLEAN = 1;

}
