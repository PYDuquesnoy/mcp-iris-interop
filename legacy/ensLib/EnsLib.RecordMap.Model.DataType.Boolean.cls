/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Force values of 0 and 1 for boolean values instead of "true" and "false".
Class EnsLib.RecordMap.Model.DataType.Boolean Extends %Boolean [ System = 4 ]
{

/// Converts the %Boolean value to the canonical SOAP encoded value.
ClassMethod LogicalToXSD(%val As %Boolean) As %String [ ServerOnly = 1 ]
{
	Quit %val
}

/// Converts the SOAP encoded input value, which is true, false 1 or 0,
/// into a %Boolean value.
ClassMethod XSDToLogical(%val As %String) As %Boolean [ ServerOnly = 1 ]
{
	Quit $s(%val=1:1, %val="true":1, %val=0:0, %val="false":0)
}

}
