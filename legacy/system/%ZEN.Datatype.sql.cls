/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a string containing an SQL statement.
Class %ZEN.Datatype.sql Extends datatype [ Deprecated, System = 3 ]
{

Parameter XMLPROJECTION = "attribute";

/// Make sure client does not see SQL queries
Parameter ZENENCRYPT = 1;

Parameter MAXLEN = 32000;

}
