/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is used to represent any captions that are displayed to a user.
/// Any properties of this type are automatically localized.
Class %ZEN.Datatype.caption Extends datatype [ Deprecated, System = 3 ]
{

Parameter ZENLOCALIZE = 1;

Parameter XMLPROJECTION = "attribute";

Parameter MAXLEN = 1000;

}
