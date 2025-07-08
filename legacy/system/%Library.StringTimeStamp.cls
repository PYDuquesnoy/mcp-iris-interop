/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %occUtility

/// The <b>%StringTimeStamp</b> data type class represents a time stamp value.
/// <p>The logical value of the <b>%TimeStamp</b> data type is in <code>YYYY-MM-DD HH:MM:SS</code> format.
Class %Library.StringTimeStamp Extends %DataType [ ClientDataType = TIMESTAMP, SqlCategory = TIMESTAMP, System = 2 ]
{

/// Used for enumerated (multiple-choice) attributes.
/// <var>VALUELIST</var> is either a null string ("") or a delimiter
/// separated list (where the delimiter is the first character) of logical values.
/// If a non-null value is present, then the attribute is restricted to values
/// in the list, and the validation code simply checks to see if the value is in the list.
Parameter VALUELIST;

/// The maximum allowed logical value for the data type.
Parameter MAXVAL;

/// The minimum allowed logical value for the data type.
Parameter MINVAL;

/// Used for enumerated (multiple-choice) attributes.
/// Used in conjunction with the <a href="#VALUELIST">VALUELIST</a> parameter for enumerated
/// (multiple-choice) attributes. <var>DISPLAYLIST</var>, if not null,
/// represents the display values for the attribute corresponding with
/// the logical values listed in <var>VALUELIST</var>.
/// <p>The display values are returned by the <a href="#LogicalToDisplay">LogicalToDisplay</a> method.
Parameter DISPLAYLIST;

/// XMLTIMEZONE specifies the handling of timezone part of the XML format dateTime.
/// "UTC" means convert to UTC on input.  "IGNORE means ignore the timezone.
Parameter XMLTIMEZONE [ Constraint = "IGNORE,UTC", Flags = ENUM ] = "UTC";

/// XMLDEFAULTVALUE specifies the value to use if the date fails validity check by $zdatetimeh.
/// By default "" is used which will result in an XMLImport error.
/// A dateTime such as "1841-01-1 00:00:00" may be specified to replace dates such as 0001-01-01 00:00:00 
/// which are not valid %TimeStamp dates.
Parameter XMLDEFAULTVALUE As STRING [ Internal ];

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "dateTime";

/// JSONTYPE is JSON type used for this datatype.
Parameter JSONTYPE = "string";

/// Converts the SOAP encoded input dateTime value into a %TimeStamp value.
ClassMethod XSDToLogical(%val As %String) As %StringTimeStamp [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		$$$GENERATE(" If $length($get(%val),""T"")'=2 Quit """"")
		$$$GENERATE(" Set dt=$translate(%val,""T"","" "")")
		$$$GENERATE(" Set len=$length(%val)")
		$$$GENERATE(" If $extract(%val,len)=""Z"" {")
		$$$GENERATE("   Set dt=$extract(dt,1,len-1)")
		$$$GENERATE(" } ElseIf $case($extract(%val,len-5),""+"":1,""-"":1,:0) {")
		$$$GENERATE("   If $extract(%val,len-2)'="":"" Quit """"")
		$$$GENERATE("   Set dt=$piece($extract(dt,1,len-6),""."")")
		If %parameter("XMLTIMEZONE")'="IGNORE" {
			$$$GENERATE("   Set t=$zdatetimeh(dt,3,1,,,,,,,"""") If t="""" Quit """_%parameter("XMLDEFAULTVALUE")_"""")
			$$$GENERATE("   Set d=$piece(t,"","")")
			$$$GENERATE("   Set s=$piece(t,"","",2)")
			$$$GENERATE("   Set z=($extract(%val,len-4,len-3)*60+$extract(%val,len-1,len))*60")
			$$$GENERATE("   If $extract(%val,len-5)=""-"" {")
			$$$GENERATE("     Set s=s+z")
			$$$GENERATE("     If s>=(24*60*60) Set d=d+1,s=s-(24*60*60)")
			$$$GENERATE("   } Else {")
			$$$GENERATE("     Set s=s-z")
			$$$GENERATE("     If s<0 Set d=d-1,s=s+(24*60*60)")
			$$$GENERATE("   }")
			$$$GENERATE("   Quit $zdatetime(d_"",""_s,3,1,0,,,,,,,"""")")
		}
		$$$GENERATE(" }")
		$$$GENERATE(" If $zdatetimeh(dt,3,1,,,,,,,"""")="""" Quit """_%parameter("XMLDEFAULTVALUE")_"""")
		$$$GENERATE(" Quit $piece(dt,""."")")
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the %StringTimeStamp value to the canonical SOAP encoded value.
ClassMethod LogicalToXSD(%val As %StringTimeStamp) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		If %parameter("XMLTIMEZONE")="IGNORE" {
			Set %code="$translate(%val,"" "",""T"")"
		} Else {
			Set %code="$select(%val="""":"""",1:$translate(%val,"" "",""T"")_""Z"")"
		}
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts <var>%val</var>, which represents either a Timestamp in ODBC format,
/// or a Date in ODBC format, into a logical Timestamp value.
/// <p>Returns the logical Timestamp value of the ODBC Timestamp string <var>%val</var>.
ClassMethod OdbcToLogical(%val As %String) As %TimeStamp [ CodeMode = expression, ServerOnly = 1 ]
{
$s(%val="":"",$zdth(%val,3,,,,,,,,"")'="":$zdt($zdth(%val,3),3),$zdth(%val,-1,,,,,,,,"")'="":$zdt($zdth(%val,-1),3),1:%val)
}

/// Converts the input value <var>%val</var>, which represents a timestamp value,
/// to <code>YYYY-MM-DD HH:MM:SS</code> format.
/// <p>Returns the value of the input string <var>%val</var> as a timestamp
/// value (<code>YYYY-MM-DD HH:MM:SS</code> format).
ClassMethod DisplayToLogical(%val As %String) As %TimeStamp [ CodeMode = generator, ServerOnly = 0 ]
{
	if %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("DISPLAYLIST"),%parameter("VALUELIST"))
	} Else {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="%val"
	}
	QUIT $$$OK
}

/// Tests if the logical value <var>%val</var>, which represents a timestamp
/// value in <code>YYYY-MM-DD HH:MM:SS</code> format, is valid.
/// The validation is based on the class parameter settings used for the
/// class attribute this data type is associated with.
/// In this case, <a href="#MAXVAL">MAXVAL</a> and <a href="#MINVAL">MINVAL</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		$$$comSubMemberKeyGetLvar(origin,%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT",$$$cXXXXorigin)
		$$$GENERATE("	Q $select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DatatypeValidationError,"""_origin_""",%val))")
		Quit $$$OK
	}
	s %code=0
	i %parameter("VALUELIST")'="" d   QUIT $$$OK
	. s %codemode=$$$cMETHCODEMODEEXPRESSION
	. s sep=$e(%parameter("VALUELIST")) ;for now
	. s %code="(%val'["""_sep_""")&("_$$$quote(%parameter("VALUELIST")_sep)_"[("""_sep_"""_%val_"""_sep_"""))"
	$$$GENERATE(" i %val=(%val\1) s %val=$zd(%val,3,,,,,,,""error"")_"" 00:00:00""")
	$$$GENERATE(" i $l(%val)=10 s %val=%val_"" 00:00:00""")
	$$$GENERATE(" i $l(%val)=8 s %val=$zd($h,3)_"" ""_%val")
	s retexp="($l(%val)>18)&''$zdth(%val,3,,,,,,,,"""")"
	i %parameter("MAXVAL")'="" s retexp=retexp_"&&(%val']"""_%parameter("MAXVAL")_""")"
	i %parameter("MINVAL")'="" s retexp=retexp_"&&("""_%parameter("MINVAL")_"""']%val)"
	$$$GENERATE(" q $select("_retexp_":1,1:$$$ERROR($$$DatatypeValidationError,""%StringTimeStamp"",%val))")
	QUIT $$$OK
}

/// Converts the value of <var>%val</var>, which is in logical format <code>YYYY-MM-DD HH:MM:SS</code>,
/// into a display string.
/// The formatting is based on the value of the FORMAT parameter.
/// <p>Returns the formatted value of <var>%val</var>.
ClassMethod LogicalToDisplay(%val As %TimeStamp) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
	if %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("VALUELIST"),%parameter("DISPLAYLIST"))
	} Else {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="%val"
	}
	QUIT $$$OK
}

/// Transforms integer values into timestamp.
ClassMethod Normalize(%val As %RawString) As %TimeStamp [ CodeMode = expression, ServerOnly = 1 ]
{
$s(%val="":"",%val=(%val\1):$zd(%val,3,,,,,,,"error")_" 00:00:00",$l(%val)=8:$zd($h,3)_" "_%val,$l(%val)=10:%val_" 00:00:00",1:%val)
}

}
