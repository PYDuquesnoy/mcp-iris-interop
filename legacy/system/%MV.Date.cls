/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %occUtility

/// The <b>%MV.Date</b> data type class represents a MultiValue date.<br>
/// <br>
/// The MultiValue start date is 01/01/1968<br>
/// ObjectScript date is 01/01/1841<br>
/// <br>
/// To convert an ObjectScript date ($h) to a MultiValue date:<br>
/// MVdate = ObjectScript date - 46385 <br>
/// <br>
/// To convert a MultiValue date to an ObjectScript date:<br>
/// ObjectScript date = MVdate + 46385 <br>
/// 
Class %MV.Date Extends %DataType [ ClientDataType = MVDATE, OdbcType = DATE, Not ProcedureBlock, SqlCategory = MVDATE, System = 2 ]
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

/// Converts the SOAP encoded input date value into a MV Date value.
ClassMethod XSDToLogical(%val As %String) As %MV.Date [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		$$$GENERATE("	New len")
		$$$GENERATE("	Set len=$length(%val)")
		$$$GENERATE("	If len'=10 {")
		$$$GENERATE("		If $extract(%val,len)=""Z"" {")
		$$$GENERATE("			Set %val=$extract(%val,1,len-1),len=len-1")
		$$$GENERATE("		} ElseIf $case($extract(%val,len-5),""+"":1,""-"":1,:0) {")
		$$$GENERATE("			Set %val=$extract(%val,1,len-6),len=len-6")
		$$$GENERATE("		}")
		$$$GENERATE("	}")
		$$$GENERATE("	If $extract(%val,11,19)=""T00:00:00"" {")
		$$$GENERATE("	    If (len=19)||(($extract(%val,20,21)="".0"")&&($translate($extract(%val,22,len),""0"","""")="""")) {")
		$$$GENERATE("	        Set %val=$extract(%val,1,10)")
		$$$GENERATE("	    }")
		$$$GENERATE("	}")
		$$$GENERATE("	Quit $select(%val="""":"""",1:$zdateh(%val,3,,,,,,,"""")-46385)")
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the MV Date value to the canonical SOAP encoded value.
ClassMethod LogicalToXSD(%val As %MV.Date) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(%val="""":"""",1:$zdate(%val+46385,3))"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the input value <var>%val</var>, which represents a date, into an MV Date format.
/// <p>Returns the logical (MV Date) value of the input string <var>%val</var>.
ClassMethod DisplayToLogical(%val As %String) As %MV.Date [ CodeMode = generator, ServerOnly = 0 ]
{
	n i,len,sep
	s %code=0
	i %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" d  QUIT $$$OK
	. s sep=$e(%parameter("DISPLAYLIST"))
	. s len=$l(%parameter("DISPLAYLIST"),sep)
	. f i=2:1:$l(%parameter("DISPLAYLIST"),sep) $$$GENERATE(" q:%val="_$$$quote($p(%parameter("DISPLAYLIST"),sep,i))_" "_$$$quote($p(%parameter("VALUELIST"),sep,i)))
	. $$$GENERATE(" q """"")
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	i %parameter("FORMAT")="" s %code="$s(%val="""":"""",1:$zdh(%val,,,,,,,,"""")-46385)" QUIT $$$OK
	s %code="$s(%val="""":"""",1:$zdh(%val,"_%parameter("FORMAT")_",,,,,,,"""")-46385)"
	QUIT $$$OK
}

/// Converts <var>%val</var> to a normalized value.
ClassMethod Normalize(%val As %String) As %MV.Date [ CodeMode = expression, ServerOnly = 1 ]
{
%val\1
}

/// Tests if the logical value <var>%val</var>, which represents a date in MV Date format,
/// is valid. The validation is based on the class parameter settings used
/// for the class attribute this data type is associated with.
/// In this case, <a href="#MAXVAL">MAXVAL</a> and <a href="#MINVAL">MINVAL</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	n sep,str,minval
	s %code=0
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	i %parameter("VALUELIST")'="" d   QUIT $$$OK
	. s sep=$e(%parameter("VALUELIST")) ;for now
	. s %code="$select(%val'["""_sep_"""&&("_$$$quote(%parameter("VALUELIST")_sep)_"[("""_sep_"""_%val_"""_sep_""")):$$$OK,1:$$$ERROR($$$DTValueList,%val,"_$$$quote(%parameter("VALUELIST"))_"))"
	s minval=$s(%parameter("MINVAL")="":-46385,%parameter("MINVAL") < -46385:-46385,1:+%parameter("MINVAL"))
	s str="$isvalidnum(%val,0,"_minval_","_%parameter("MAXVAL")_")"
	s %code="$select("_str_":1,'$isvalidnum(%val):$$$ERROR($$$DTNotNum,%val),"
	If %parameter("MAXVAL")'="" {
		Set %code=%code_"%val<"_minval_":$$$ERROR($$$DTMinVal,%val,"_minval_"),1:$$$ERROR($$$DTMaxVal,%val,"_%parameter("MAXVAL")_"))"
	} Else {
		Set %code=%code_"1:$$$ERROR($$$DTMinVal,%val,"_minval_"))"
	}
	QUIT $$$OK
}

/// Converts the value of <var>%val</var>, which is in logical MV Date format, into a display string.
/// The formatting is based on the value of the <a href="#FORMAT">FORMAT</a> parameter.
/// <p>Returns the formatted value of <var>%val</var>.
ClassMethod LogicalToDisplay(%val As %Date) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
	n i,len,sep
	k %code s %code=0
	i %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" d  QUIT $$$OK
	. s sep=$e(%parameter("VALUELIST"))
	. s len=$l(%parameter("VALUELIST"),sep)
	. f i=2:1:$l(%parameter("VALUELIST"),sep) $$$GENERATE(" q:%val="_$$$quote($p(%parameter("VALUELIST"),sep,i))_" "_$$$quote($p(%parameter("DISPLAYLIST"),sep,i)))
	. $$$GENERATE(" q """"")
	s %codemode=$$$cMETHCODEMODEEXPRESSION
	i %parameter("FORMAT")="" s %code="$s(%val="""":"""",1:$zd(%val+46385,,,4))" QUIT $$$OK
	s %code="$s(%val="""":"""",1:$zd(%val+46385,"_%parameter("FORMAT")_",,4))"
	QUIT $$$OK
}

/// Converts <var>%val</var>, which represents a date in logical MV Date format, into ODBC date format.
/// <p>Returns the ODBC date string for the logical (MV Date) value <var>%val</var>.
ClassMethod LogicalToOdbc(%val As %MV.Date = "") As %String [ CodeMode = expression, ServerOnly = 1 ]
{
$s(%val="":"",1:$zd(%val+46385,3))
}

/// Converts <var>%val</var>, which represents a date in ODBC format, into MV Date format.
/// <p>Returns the MV Date value of the ODBC date string <var>%val</var>.
ClassMethod OdbcToLogical(%val As %String = "") As %MV.Date [ ProcedureBlock = 1, ServerOnly = 1 ]
{
	set date=$s(%val="":"",1:$zdh(%val,3,,,,,,,"error: '"_%val_"' is an invalid date value"))
	set:$isvalidnum(date) date=date-46385
	quit date
}

/// Converts %Library.Date value to %MV.Date value
ClassMethod DateToLogical(%val As %Library.Date) As %MV.Date [ CodeMode = expression, ServerOnly = 1 ]
{
$s(%val="":"",1:%val-46385)
}

/// Converts logical %MV.Date value to %Library.Date value
ClassMethod LogicalToDate(%val As %MV.Date) As %Library.Date [ CodeMode = expression, ServerOnly = 1 ]
{
$s(%val="":"",1:%val+46385)
}

}
