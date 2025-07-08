/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a specialized datatype. On the server
/// this represents a set of items as a piece-delimited string.
/// On the client this is converted to a JavaScript array.
Class %ZEN.Datatype.list Extends datatype [ Deprecated, System = 3 ]
{

/// Delimiter character used for server-side representation.
/// Default is $C(5).
Parameter DELIMITER;

Parameter XMLPROJECTION = "attribute";

Parameter MAXLEN;

}
