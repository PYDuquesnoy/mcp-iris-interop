/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <B>%Boolean</B> data type class represents a boolean value.
/// <p>The logical value of the <B>%Boolean</B> data type is an integer
/// with value of 0 (false) and 1 (true).
Class %Library.Boolean Extends %Integer [ ClientDataType = BOOLEAN, OdbcType = BIT, SqlCategory = INTEGER, System = 2 ]
{

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "boolean";

Parameter JSONTYPE = "boolean";

/// Converts the SOAP encoded input value, which is true, false 1 or 0,
/// into a %Boolean value.
ClassMethod XSDToLogical(%val As %String) As %Boolean [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		$$$GENERATE("	Q $case(%val,""true"":1,""false"":0,1:1,0:0,:"""")")
	}
	Quit $$$OK
}

/// Converts the %Boolean value to the canonical SOAP encoded value.
ClassMethod LogicalToXSD(%val As %Boolean) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		$$$GENERATE("	Q $s(%val:""true"",1:""false"")")
	}
	Quit $$$OK
}

/// Converts the input value <var>%val</var>, which is a string representing
/// a boolean value, into a boolean value.
/// <p>Returns the boolean value of the input string <var>%val</var>.
ClassMethod DisplayToLogical(%val As %String) As %Boolean [ ServerOnly = 0 ]
{
	Quit $s(%val="":"",1:''%val)
}

/// Converts <var>%val</var> to a normalized value.
ClassMethod Normalize(%val As %RawString) As %Integer [ ServerOnly = 1 ]
{
	Quit $s(%val="":"",1:%val\1)
}

/// Tests if the boolean value <var>%val</var> is valid.
ClassMethod IsValid(%val As %RawString = "") As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		$$$GENERATE("	Quit $s(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DTFailure,%val))")
		RETURN $$$OK
	}
		// only "" (null), 1 and 0 are valid
	$$$GENERATE("	Quit $case(%val,"""":1,1:1,0:1,:$$$ERROR($$$DTNotBoolean,%val))")
	RETURN $$$OK
}

/// Converts the value of <var>%val</var>, which is in boolean format, into a display string.
/// <p>Returns the formatted value of <var>%val</var>.
ClassMethod LogicalToDisplay(%val As %Boolean) As %String [ ServerOnly = 0 ]
{
	Quit %val
}

}
