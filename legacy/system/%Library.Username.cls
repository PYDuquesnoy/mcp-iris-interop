/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %occUtility

/// The <b>%String</b> data type class represents a string.
/// <p>The logical value of the <b>%String</b> data type is a string.
Class %Library.Username Extends (%DataType, %String) [ System = 2 ]
{

/// The maximum number of characters the string can contain.
Parameter MAXLEN As INTEGER = 160;

}
