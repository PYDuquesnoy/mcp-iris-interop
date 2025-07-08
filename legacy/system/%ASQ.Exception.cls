/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ASQ.Exception Extends %Exception.SQL
{

/// Override this method to provide a custom conversion of an exception to an SQLCODE value
Method OnAsSQLCODE() As %Integer [ CodeMode = expression, Private ]
{
..Code
}

/// This returns a string that represents the SQL %msg string. Users should feel free
/// to modify the format and content in subclasses
Method SQLMessageString(pLevel As %Integer = 0) As %String
{
	Quit ..Data
}

}
