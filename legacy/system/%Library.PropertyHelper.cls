/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally to hold property/field values needed for computed fields
/// An object is needed in order for Python computed fields to access the values of other fields in the row/object
/// This is similar to %Library.TriggerHelper
Class %Library.PropertyHelper Extends %RegisteredObject [ Language = objectscript ]
{

/// Holds the field names/values that can be referenced by the Compute code
Property fields As %String(MAXLEN = 250) [ MultiDimensional ];

Method getfield(fieldname As %RawString) As %RawString [ Language = objectscript ]
{
	RETURN $get(..fields($zcvt(fieldname,"L")))
}

}
