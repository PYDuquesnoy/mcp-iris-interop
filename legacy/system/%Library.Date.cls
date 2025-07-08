/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %occUtility

/// The <b>%Date</b> data type class represents a date.
/// The logical value of the <b>%Date</b> data type is in InterSystems IRIS <code>$H</code> format.
Class %Library.Date Extends %DataType [ ClientDataType = DATE, OdbcType = DATE, SqlCategory = DATE, System = 2 ]
{

/// The format specification for the data type's display value.
/// The value of the <var>FORMAT</var> parameter corresponds to the
/// available parameters of the <code>$ZDATE</code> and <code>$ZDATEH</code> functions,
/// which are used to perform the formatting.
Parameter FORMAT;

/// The maximum allowed logical value for the data type.
Parameter MAXVAL;

/// The minimum allowed logical value for the data type.
Parameter MINVAL;

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

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "date";

Parameter JSONTYPE = "string";

/// Converts the SOAP encoded input date value into a %Date value.
ClassMethod XSDToLogical(%val As %String) As %Date [ CodeMode = generator, ServerOnly = 1 ]
{
    If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
        $$$GENERATE("   Set len=$length(%val)")
        $$$GENERATE("   If len'=10 {")
        $$$GENERATE("       If $extract(%val,len)=""Z"" {")
        $$$GENERATE("           Set %val=$extract(%val,1,len-1),len=len-1")
        $$$GENERATE("       } ElseIf $case($extract(%val,len-5),""+"":1,""-"":1,:0) {")
        $$$GENERATE("           Set %val=$extract(%val,1,len-6),len=len-6")
        $$$GENERATE("       }")
        $$$GENERATE("   }")
        $$$GENERATE("   If $extract(%val,11,19)=""T00:00:00"" {")
        $$$GENERATE("       If (len=19)||(($extract(%val,20,21)="".0"")&&($translate($extract(%val,22,len),""0"","""")="""")) {")
        $$$GENERATE("           Set %val=$extract(%val,1,10)")
        $$$GENERATE("       }")
        $$$GENERATE("   }")
        $$$GENERATE("   Quit $select(%val="""":"""",1:$zdateh(%val,3,,,,,"_$s(%parameter("MINVAL")="":-672045,1:%parameter("MINVAL"))_","_%parameter("MAXVAL")_",""""))")
    } Else {
        Set %code=0 
    }
    Quit $$$OK
}

/// Converts the %Date value to the canonical SOAP encoded value.
ClassMethod LogicalToXSD(%val As %Date) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
    If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
        $$$GENERATE("   quit $select(%val="""":"""",1:$zdate(%val,3,,,,,"_$s(%parameter("MINVAL")="":-672045,1:%parameter("MINVAL"))_"))")
    }
    Quit $$$OK
}

/// Converts the JSON input date value into a %Date value.
ClassMethod JSONToLogical(%val As %String) As %Date [ CodeMode = generator, ServerOnly = 1 ]
{
    If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
        $$$GENERATE("   Quit $select(%val="""":"""",1:$zdateh(%val,3,,,,,"_$s(%parameter("MINVAL")="":-672045,1:%parameter("MINVAL"))_","_%parameter("MAXVAL")_",""""))")
	} Else {
		Set %code=0
	}
    Quit $$$OK
}

/// Converts the %Date value to the canonical JSON value.
ClassMethod LogicalToJSON(%val As %Date) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
    If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
        $$$GENERATE("   quit $select(%val="""":"""",1:$zdate(%val,3,,,,,"_$s(%parameter("MINVAL")="":-672045,1:%parameter("MINVAL"))_"))")
	} Else {
		Set %code=0
    }
    Quit $$$OK
}

/// Converts <var>%val</var> to a normalized value.
ClassMethod Normalize(%val As %RawString) As %Date [ ServerOnly = 1 ]
{
   Quit $s($zu(115,13)&&(%val=$c(0)):"",1:%val\1)
}

/// Tests if the logical value <var>%val</var>, which represents a date in <code>$H</code> format,
/// is valid. The validation is based on the class parameter settings used
/// for the class attribute this data type is associated with.
/// In this case, <a href="#MAXVAL">MAXVAL</a> and <a href="#MINVAL">MINVAL</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		$$$GENERATE("	Q $s(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DTFailure,%val))")
		Quit $$$OK
	}
	i %parameter("VALUELIST")'="" d   QUIT $$$OK
	. s sep=$e(%parameter("VALUELIST")) ;for now
	. $$$GENERATE("	Q $s(%val'["""_sep_"""&&("_$$$quote(%parameter("VALUELIST")_sep)_"[("""_sep_"""_%val_"""_sep_""")):$$$OK,1:$$$ERROR($$$DTValueList,%val,"_$$$quote(%parameter("VALUELIST"))_"))")
	s minval=$s(%parameter("MINVAL")<-672045:-672045,%parameter("MINVAL")="":-672045,1:%parameter("MINVAL")) 
	s maxval=$s(%parameter("MAXVAL")>2980013:2980013,%parameter("MAXVAL")="":2980013,1:%parameter("MAXVAL")) 

	s str="$isvalidnum(%val,0,"_minval_","_maxval_")"
	s code="$s($zu(115,13)&&(%val=$c(0)):1,"_str_":1,'$isvalidnum(%val):$$$ERROR($$$DTNotNum,%val),"
	Set code=code_"%val<"_minval_":$$$ERROR($$$DTMinVal,%val,"_minval_"),1:$$$ERROR($$$DTMaxVal,%val,"_maxval_"))"
	$$$GENERATE("	Q "_code)
	QUIT $$$OK
}

/// Converts the value of <var>%val</var>, which is in logical <code>$H</code> format, into a display string.
/// The formatting is based on the value of the <a href="#FORMAT">FORMAT</a> parameter.
/// <p>Returns the formatted value of <var>%val</var>.
ClassMethod LogicalToDisplay(%val As %Date) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
	#dim format As %Integer
	kill %code set %code=0
	if %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("VALUELIST"),%parameter("DISPLAYLIST"))
		QUIT $$$OK
	}
	if %parameter("FORMAT")="" { set format=-1 } else { set format=%parameter("FORMAT") }
	$$$GENERATE($c(9)_"Quit $select(%val="""":"""",%val'?0.1""-""4N1""-""2N1""-""2N.1(1"" ""2N1"":""2N1"":""2N.1(1"".""0.9N)):$zdate(%val,"_format_",,4,,,-672045),1:$$FormatJulian^%qarfunc(%val,"_format_"))")
	QUIT $$$OK
}

/// Converts the input value <var>%val</var>, which represents a date, into <code>$H</code> format.
/// <p>Returns the logical (<code>$H</code>) value of the input string <var>%val</var>.
ClassMethod DisplayToLogical(%val As %String) As %Date [ CodeMode = generator, ServerOnly = 0 ]
{
	if %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("DISPLAYLIST"),%parameter("VALUELIST"))
		QUIT $$$OK
	}
	if %parameter("FORMAT")="" { 
		$$$GENERATE(" q:%val="""" """" quit:$isvalidnum(%val,0,-672045,2980013) %val set %val=$zdateh(%val,,,,,,-672045,,""Error: '""_%val_""' is an invalid DISPLAY Date value"") q:%val||(%val=0) %val s %msg=%val ZTRAP ""ODAT""")
	}
	else { 
		$$$GENERATE(" q:%val=""""||($zu(115,13)&&(%val=$c(0))) """" quit:$isvalidnum(%val,0,-672045,2980013) %val set %val=$zdateh(%val,"_%parameter("FORMAT")_",,,,,-672045,,""Error: '""_%val_""' is an invalid DISPLAY Date value"") q:%val||(%val=0) %val s %msg=%val ZTRAP ""ODAT""")
	}
	QUIT $$$OK
}

/// Converts <var>%val</var>, which represents a date in logical <code>$H</code> format, into ODBC date format.
/// <p>Returns the ODBC date string for the logical (<code>$H</code>) value <var>%val</var>.
///   Assume if the value is already in ODBC DATE format or ODBC TIMESTAMP format, just return tge ODBC DATE format portion of the value.
///   This value may have come from a gateway query or is used by TO_DATE(val,"J") for Julian dates
ClassMethod LogicalToOdbc(%val As %Date = "") As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	$$$GENERATE($c(9)_"Quit $select(%val="""":"""",%val'?0.1""-""4N1""-""2N1""-""2N.1(1"" ""2N1"":""2N1"":""2N.1(1"".""0.9N)):$zdate(%val,3,,,,,-672045),1:$piece(%val,"" "",1))")
	QUIT $$$OK
}

/// Converts <var>%val</var>, which represents a date in ODBC format, into <code>$H</code> format.
/// <p>Returns the <code>$H</code> value of the ODBC date string <var>%val</var>.
ClassMethod OdbcToLogical(%val As %String = "") As %Date [ CodeMode = generator, ServerOnly = 1 ]
{
	$$$GENERATE(" quit:%val=""""||($zu(115,13)&&(%val=$c(0))) """" quit:$isvalidnum(%val,0,-672045,2980013) %val set %val=$zdateh(%val,3,,,,,-672045,,""Error: '""_%val_""' is an invalid ODBC/JDBC Date value"") q:%val||(%val=0) %val s %msg=%val ZTRAP ""ODAT""")
}

}
