/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This datatype represents a numeric value.
/// Note: this is really a string used to hold a numeric value.
Class %ZEN.Datatype.float Extends datatype [ ClientDataType = DOUBLE, Deprecated, System = 3 ]
{

Parameter XMLPROJECTION = "attribute";

Parameter MAXLEN;

/// The maximum allowed logical value for the data type.
Parameter MAXVAL;

/// The minimum allowed logical value for the data type.
Parameter MINVAL;

}
