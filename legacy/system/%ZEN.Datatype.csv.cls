/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This datatype represents a string value containing one or more
/// values seperated by commas.
Class %ZEN.Datatype.csv Extends datatype [ Deprecated, System = 3 ]
{

Parameter XMLPROJECTION = "attribute";

Parameter MAXLEN = 1000;

}
