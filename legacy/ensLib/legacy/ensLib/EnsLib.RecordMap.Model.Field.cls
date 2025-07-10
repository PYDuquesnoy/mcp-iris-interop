/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Server side class to model the Field object used in the RecordMap model.
/// Both fixed width and delimited fields are described by this model.
Class EnsLib.RecordMap.Model.Field Extends EnsLib.RecordMap.Model.RecordProperty [ System = 4 ]
{

/// The datatype to be used for the data. If not specified, a %String type will be used.
Property datatype As %String(XMLPROJECTION = "ATTRIBUTE");

/// Number of characters containing this field's data.
/// Only valid for fixed width RecordMaps.
Property width As %Integer(XMLPROJECTION = "ATTRIBUTE");

/// Indicate whether the generated property should be indexed. This only applies to persistent classes.
Property index As %String(VALUELIST = ",,1,bitmap,idkey,unique", XMLPROJECTION = "ATTRIBUTE");

/// Characters which will follow the field, as can happen with some fixed width formats.
/// Note that if there is not an exact match between the incoming data and these characters, the
/// RecordMap parser will immediately throw an error.
/// Only valid for fixed width RecordMaps.
Property trailingData As %String(XMLPROJECTION = "ATTRIBUTE");

/// List of parameters for datatype. The format is a semicolon-separated list of
/// key/value pairs as follows: <br />
/// &nbsp;&nbsp;PARAM1=value1;PARAM2=value2;FORMAT=2;... <br />
/// Leading and trailing whitespace will be ignored.
/// This will be most useful for datatypes like dates or special numeric types.
/// NOTE: MAXLEN parameters are automatically calculated for fixed width fields.
Property params As %String(MAXLEN = 1000, XMLPROJECTION = "ATTRIBUTE");

/// The SQL column number of the field. This value must either not be specified,
/// or must lie between 2 and 4096 (inclusive) as per the values for the SqlColumnNumber
/// property keyword. The column number is of particular use when importing data 
/// from CSV files or similar data dumps, as the SQL representation can be replicated easily.
Property sqlColumn As %Integer(MAXVAL = 4096, MINVAL = 2, XMLPROJECTION = "ATTRIBUTE");

/// Indicate whether the property is repeating. This only has meaning in delimited Records,
/// and will report an error if enabled for fixed width Records.
Property repeating As EnsLib.RecordMap.Model.DataType.Boolean(XMLPROJECTION = "ATTRIBUTE");

/// Validate the value of the name property - ensure the generated property
/// name requested by the user is valid.
ClassMethod nameIsValid(%val) As %Status
{
	Set tValid = $$$OK
	Set tDotLen = $length(%val,".")
	For i=1:1:tDotLen {
		Set tVal = $piece(%val,".",i)
		Set tFirst = $extract(tVal,1)
		If tFirst = "$" {
			Set tVal = $extract(tVal,2,*)
			Set tFirst = $extract(tVal,1)
		}
		If (tFirst = "%") && (i < tDotLen) { // Only allow %names in final properties
			Set tValid = $$$ERROR($$$PropertyNameInvalid,%val)
			Quit
		}
		// Work around Unicode limitations of $zname
		For j=1:1:$length(tVal) If $ziswide(tVal) Set $extract(tVal,j) = "A"
		If '$zname(tVal, 6) { // ensure valid property names
			Set tValid = $$$ERROR($$$PropertyNameInvalid,%val)
			Quit
		}
	}
	Quit tValid
}

/// Get the object part of the name, which equates to all parts of the name prior to
/// the last ".", with any "$" characters removed.
Method GetObjectName() As %String [ CodeMode = expression ]
{
$TR($piece(..name, ".", 1, $length(..name, ".") - 1), "$", "")
}

/// Get the field part of the name, which equates to the part of the name following
/// the last "." character.
Method GetFieldName() As %String [ CodeMode = expression ]
{
$piece(..name, ".", $length(..name, "."))
}

/// Recursive method to retrieve the greatest depth of this branch of the object graph.
Method GetDepth(Output pHasRepeats As %Boolean) As %Integer [ Internal, ServerOnly = 1 ]
{
	If ..repeating {
		Set pHasRepeats = 1
	}
	Quit 1
}

/// Validate the Field based on the RecordType and which values are permitted for various fields.
Method %OnValidateObject() As %Status [ Private, ProcedureBlock = 1, ServerOnly = 1 ]
{
	If (..RecordType '= "delimited") && (..repeating) {
		Quit $$$ERROR($$$EnsRecordMapErrFieldAttrNotPermitted, "repeating", "delimited")
	}
	If (..RecordType = "delimited") {
		If (..width '= "") {
			Quit $$$ERROR($$$EnsRecordMapErrFieldAttrNotPermitted, "width", "fixed width")
		}
		If (..trailingData '= "") {
			Quit $$$ERROR($$$EnsRecordMapErrFieldAttrNotPermitted, "trailingData", "fixed width")
		}
	}
	If (..GetObjectName() '= "")&&(..index '= "") {
		Quit $$$ERROR($$$EnsRecordMapErrFieldAttrNotPermitted, "index", "top level")
	}
	Quit $$$OK
}

}
