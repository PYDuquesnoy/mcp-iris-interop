/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is used to represent a server-side class name.
Class %ZEN.Datatype.className Extends datatype [ Deprecated, System = 3 ]
{

Parameter XMLPROJECTION = "attribute";

/// If defined, indicates that this should be a subclass of the given class.
Parameter SUBCLASSOF As STRING;

Parameter MAXLEN = 250;

}
