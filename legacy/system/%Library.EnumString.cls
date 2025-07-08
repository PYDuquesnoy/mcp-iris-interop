/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %occUtility

/// The <b>%EnumString</b> data type class represents a string.
/// This is a specialized type of <b>%String</b> that allows you to define an enumerated
/// set of possible values (using the DISPLAYLIST and VALUELIST parameters).
/// Unlike the regular <b>%String</b> class, the display values for this property are used
/// when columns of this type are queried via ODBC.
/// <p>The logical value of the <b>%EnumString</b> data type is a string.
Class %Library.EnumString Extends %DataType [ System = 2 ]
{

/// The default collation value used for this data type.
/// Note that if you specify a truncation length and also a <parameter>VALUELIST</parameter> then your truncation length must
/// be longer or equal to your longest VALUELIST value
Parameter COLLATION [ Constraint = ",ALPHAUP,EXACT,MINUS,MVR,PLUS,SPACE,SQLSTRING,SQLUPPER,STRING,TRUNCATE,UPPER", Flags = ENUMEDIT ];

/// COLLATIONTARGET is the collation that will be used for the property after
/// an ALTER TABLE ... CONVERT STORAGETYPE statement. This parameter is for internal use only.
Parameter COLLATIONTARGET As STRING [ Internal ];

/// The maximum number of characters the string can contain.
Parameter MAXLEN As INTEGER = 50;

/// The minimum number of characters the string can contain.
Parameter MINLEN As INTEGER;

/// A pattern which the string should match.
/// <p>The value of <var>PATTERN</var> should be a valid
/// ObjectScript pattern match expression.
Parameter PATTERN;

/// Determines whether to truncate the string to MAXLEN characters.
Parameter TRUNCATE As BOOLEAN = 0;

/// Used for enumerated (multiple-choice) attributes.
/// <var>VALUELIST</var> is either a null string ("") or a delimiter
/// separated list (where the delimiter is the first character) of logical values.
/// If a non-null value is present, then the attribute is restricted to values
/// in the list, and the validation code simply checks to see if the value is in the list.
Parameter VALUELIST;

/// Used for enumerated (multiple-choice) attributes.
/// Used in conjunction with the <a href="#VALUELIST">VALUELIST</a> parameter for enumerated
/// (multiple-choice) attributes. <var>DISPLAYLIST</var>, if not null,
/// represents the display values for the attribute corresponding with
/// the logical values listed in <var>VALUELIST</var>.
/// <p>The display values are returned by the <a href="#LogicalToDisplay">LogicalToDisplay</a> method.
Parameter DISPLAYLIST;

/// XML element content "MIXED" for mixed="true" and "STRING" or "ESCAPE" for mixed="false".
/// If CONTENT="STRING" (default) XML special characters are put in a CDATA section during XML export.
/// If CONTENT="ESCAPE" XML special characters are escaped during XML export.
/// If CONTENT="ESCAPE-C14N" XML special characters are escaped during XML export using 
/// the translate table, XMLC, specified for XML Canonicalizaton.
/// The main difference is that CR is escaped as &amp;#13; 
Parameter CONTENT [ Constraint = "MIXED,STRING,ESCAPE,ESCAPE-C14N", Flags = ENUM ] = "STRING";

/// Controls the translate table used to escape content when CONTENT="MIXED" is specified.
Parameter ESCAPE [ Constraint = "HTML,XML", Flags = ENUM ] = "XML";

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "string";

/// JSONTYPE is JSON type used for this datatype.
Parameter JSONTYPE = "string";

/// Converts the input value <var>%val</var>, which is a string, into the logical string format.
/// Returns the logical value of the input string <var>%val</var>.
ClassMethod DisplayToLogical(%val As %String) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
	s %code=0
	if %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("DISPLAYLIST"),%parameter("VALUELIST"))
		QUIT $$$OK
	}
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	s %code="%val"
	QUIT $$$OK
}

/// Converts the input value <var>%val</var>, which is a string, into the logical string format.
/// Converts DISPLAYLIST entries to their cooresponding VALUELIST value.
/// If there is no entry specified for the given value in the DISPLAYLIST, the input value is returned.  
/// If this input value does not match a value in the VALUELIST a validation error will probably be returned upon filing or saving.
/// <p>Returns the logical value of the input string <var>%val</var>.
ClassMethod OdbcToLogical(%val As %String) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	s %code=0
	if %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("DISPLAYLIST"),%parameter("VALUELIST"))
		QUIT $$$OK
	}
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	s %code="%val"
	QUIT $$$OK
}

/// Truncates value <var>%val</var> to <a href="#MAXLEN">MAXLEN</a>, characters.
ClassMethod Normalize(%val As %RawString) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	s str=""
	s %code=0
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	i %parameter("TRUNCATE"),%parameter("MAXLEN")'="" s str="$e(%val,1,"_(+%parameter("MAXLEN"))_")"
	i str="" s %code="%val" QUIT $$$OK
	s %code=str
	QUIT $$$OK
}

/// Tests if the logical value <var>%val</var>, which is a string, is valid.
/// The validation is based on the class parameter settings used for the class attribute this data type is associated with.
/// In this case, <a href="#MINLEN">MINLEN</a>, <a href="#MAXLEN">MAXLEN</a>, <a href="#VALUELIST">VALUELIST</a>, and <a href="#PATTERN">PATTERN</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
		#; Validate MAXLEN parameter - either NULL, "", or a positive integer
	If ($Get(%parameter("MAXLEN")) '= "") && (('$isvalidnum(%parameter("MAXLEN"),,1)) || (((+%parameter("MAXLEN")\1)) '= +%parameter("MAXLEN"))) { Quit $$$ERROR($$$DatatypeParameterIntegerNotPositive,%class_"::"_%property,"MAXLEN",%parameter("MAXLEN")) }
		#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DTFailure,%val))"
		Quit $$$OK
	}
	s %code=0
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	i %parameter("VALUELIST")'="" d   QUIT $$$OK
	. s sep=$e(%parameter("VALUELIST")) ;for now
	. s %code="$select(%val'["""_sep_"""&&("_$zutil(144,1,%parameter("VALUELIST")_sep)_"[("""_sep_"""_%val_"""_sep_""")):$$$OK,1:$$$ERROR($$$DTValueList,%val,"_$zutil(144,1,%parameter("VALUELIST"))_"))"
	s str="",err=""
	If %parameter("MINLEN")'="" {
		Set str=str_"($s(%val'=$c(0):$length(%val),1:0)'<"_(+%parameter("MINLEN"))_")"
		If %parameter("PATTERN")="",%parameter("MAXLEN")=""||(%parameter("TRUNCATE")) {
			Set err="1"
		} Else {
			Set err="$s(%val'=$c(0):$length(%val),1:0)<"_(+%parameter("MINLEN"))
		}
		Set err=err_":$$$ERROR($$$DTMinLen,%val,"_(+%parameter("MINLEN"))_")"
	}
	If '%parameter("TRUNCATE"),%parameter("MAXLEN")'="" {
		Set str=str_"&&($length(%val)'>"_(+%parameter("MAXLEN"))_")"
		If %parameter("PATTERN")="" {
			Set err=err_$select(err="":"",1:",")_"1"
		} Else {
			Set err=err_$select(err="":"",1:",")_"$length(%val)>"_(+%parameter("MAXLEN"))
		}
		Set err=err_":$$$ERROR($$$DTMaxLen,%val,"_(+%parameter("MAXLEN"))_")"
	}
	If %parameter("PATTERN")'="" Set str=str_"&&(%val?"_%parameter("PATTERN")_")",err=err_$select(err="":"",1:",")_"1:$$$ERROR($$$DTPattern,%val,"_$zutil(144,1,%parameter("PATTERN"))_")"
	i str="" s %code=1 QUIT $$$OK
	i $e(str,1,2)="&&" s str=$e(str,3,$l(str))
	s %code="$select("_str_":1,"_err_")"
	QUIT $$$OK
}

/// Converts the value of <var>%val</var>, which is in logical format, into a display string. Removes all the null characters from the string.
/// <p>Returns the string value of <var>%val</var>.
ClassMethod LogicalToDisplay(%val As %String) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
	s %code=0
	if %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("VALUELIST"),%parameter("DISPLAYLIST"),%parameter("COLLATION"))
		QUIT $$$OK
	}
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	s %code="$tr(%val,$c(0),"""")"
	QUIT $$$OK
}

/// Converts the value of <var>%val</var>, which is in logical format, into a display string.
/// Converts VALUELIST entries to their cooresponding DISPLAYLIST value.
/// <p>Returns the string value of <var>%val</var>.
ClassMethod LogicalToOdbc(%val As %String) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	s %code=0
	if %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("VALUELIST"),%parameter("DISPLAYLIST"),%parameter("COLLATION"))
		QUIT $$$OK
	}
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	s %code="%val"
	QUIT $$$OK
}

}
