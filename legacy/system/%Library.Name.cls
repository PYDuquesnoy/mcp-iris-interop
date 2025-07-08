/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The <b>%Name</b> data type class represents a string containing a name.
/// <p>The logical value of the <b>%Name</b> data type is a string of the form "lastname,firstname".
/// <p>The <b>%Name</b> data type has special indexing support when used in conjunction
/// with the <CLASS>%Storage.Persistent</CLASS> class
/// (see the <a href="#INDEXSUBSCRIPTS">INDEXSUBSCRIPTS</a> parameter).
Class %Library.Name Extends %DataType [ SqlCategory = NAME, System = 2 ]
{

/// The default collation value used for this data type.
Parameter COLLATION [ Constraint = ",ALPHAUP,EXACT,MINUS,MVR,PLUS,SPACE,COLLATE,SQLSTRING,SQLUPPER,STRING,TRUNCATE,UPPER,", Flags = ENUMEDIT ] = "SQLUPPER";

/// The maximum number of characters the string can contain.
Parameter MAXLEN As INTEGER = 25;

/// The number of subscripts used by the attribute in indices.
/// This parameter, if present, tells the methods of the
/// <class>%Storage.Persistent</class> class (that is, the default storage structure) the
/// number of subscripts used by the attribute in indices, using a comma
/// as a delimiter in the property value.
/// <p>The <b>%Name</b> data type has the value 2 for <var>INDEXSUBSCRIPTS</var>,
/// meaning the 1st comma piece of the name (the last name)
/// is stored as the first subscript and the 2nd comma piece of the name
/// (the first name) is stored as the second subscript.
Parameter INDEXSUBSCRIPTS = 2;

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "string";

/// JSONTYPE is JSON type used for this datatype.
Parameter JSONTYPE = "string";

/// Converts the input value <var>%val</var>, which is a string representing
/// a name, into the internal format.
/// <p>Returns the internal value of the input string <var>%val</var>.
ClassMethod DisplayToLogical(%val As %String = "") As %Name [ CodeMode = expression, ServerOnly = 0 ]
{
%val
}

/// Tests if the logical value <var>%val</var>, which is a string, is valid.
/// The validation is based on the class parameter settings used
/// for the class attribute this data type is associated with.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DTFailure,%val))"
		Quit $$$OK
	}
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	s %code=1
	i %parameter("MAXLEN")'="" s %code="$select($length(%val)'>"_%parameter("MAXLEN")_":1,1:$$$ERROR($$$DTMaxLen,%val,"_%parameter("MAXLEN")_"))"
	QUIT $$$OK
}

/// Converts the value of <var>%val</var> into a display string.
/// <p>Returns the formatted value of <var>%val</var>.
ClassMethod LogicalToDisplay(%val As %Name = "") As %String [ CodeMode = expression, ServerOnly = 0 ]
{
%val
}

}
