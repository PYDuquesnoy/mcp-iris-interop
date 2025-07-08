/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a string containing the name of a global:
/// ^abc
Class %ZEN.Datatype.glvn Extends datatype [ Deprecated, System = 3 ]
{

Parameter XMLPROJECTION = "attribute";

/// Make sure client does not see global names.
Parameter ZENENCRYPT = 1;

Parameter MAXLEN = 255;

}
