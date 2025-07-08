/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %occUtility

/// The <b>%TimeStamp</b> data type class represents a time stamp value.
/// The logical value of this data type is in ODBC format: 
/// <pre>YYYY-MM-DD HH:MM:SS.nnnnnnnnn</pre> 
/// For example, the following expression returns the current date and
/// time in the format needed for this data type: <code>$zdatetime($horolog,3)</code>.
/// See the documentation for <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$ZDATETIME">$zdatetime</a>
/// and <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=OBJECTSCRIPT+$HOROLOG">$horolog</a>.
/// <p>The function $System.SQL.Functions.DATEDIFF() can be used to return intervals between two %TimeStamp values.  
/// The function $System.SQL.Functions.DATEADD() can be used to add a certain number of date parts (such as years, hours, or days) 
/// to a specified timestamp. See the class <class>%SYSTEM.SQL.Functions</class> for details.
Class %Library.TimeStamp Extends %DataType [ ClientDataType = TIMESTAMP, OdbcType = TIMESTAMP, SqlCategory = TIMESTAMP, System = 2 ]
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
/// "UTC" means convert to UTC on input.  "IGNORE" means ignore the timezone.
Parameter XMLTIMEZONE [ Constraint = "IGNORE,UTC", Flags = ENUM ] = "UTC";

/// XMLDEFAULTVALUE specifies the value to use if the date fails validity check by $zdatetimeh.
/// By default "" is used which will result in an XMLImport error.
/// A dateTime such as "1841-01-1 00:00:00" may be specified to replace dates such as 0001-01-01 00:00:00 
/// which are not valid %TimeStamp dates.
Parameter XMLDEFAULTVALUE As STRING [ Internal ];

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "dateTime";

Parameter JSONTYPE = "string";

/// Converts the SOAP encoded input dateTime value into a %TimeStamp value.
ClassMethod XSDToLogical(%val As %String) As %TimeStamp [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		$$$GENERATE("	If $length($get(%val),""T"")'=2 Quit """"")
		$$$GENERATE("	Set dt=$translate(%val,""T"","" "")")
		$$$GENERATE("	Set len=$length(%val)")
		$$$GENERATE("	If $extract(%val,len)=""Z"" {")
		$$$GENERATE("		Set dt=$extract(dt,1,len-1)")
		$$$GENERATE("	} ElseIf $case($extract(%val,len-5),""+"":1,""-"":1,:0) {")
		$$$GENERATE("		If $extract(%val,len-2)'="":"" Quit """"")
		$$$GENERATE("		Set dt=$extract(dt,1,len-6)")
		if %parameter("MINVAL")="" { set mindate=0 }
		else { set mindate=$zdateh($p(%parameter("MINVAL")," ",1),3,,,,,-672045,,"") set:mindate="" mindate=0 }
		If %parameter("XMLTIMEZONE")'="IGNORE" {
			$$$GENERATE("		Set f=$piece(dt,""."",2) If f'="""" Set f="".""_f,dt=$piece(dt,""."")")
			$$$GENERATE("		Set t=$zdatetimeh(dt,3,1,,,,,"_mindate_",,"""") If t="""" Quit """_%parameter("XMLDEFAULTVALUE")_"""")
			$$$GENERATE("		Set d=$piece(t,"","")")
			$$$GENERATE("		Set s=$piece(t,"","",2)")
			$$$GENERATE("		Set z=($extract(%val,len-4,len-3)*60+$extract(%val,len-1,len))*60")
			$$$GENERATE("		If $extract(%val,len-5)=""-"" {")
			$$$GENERATE("			Set s=s+z")
			$$$GENERATE("			If s>=(24*60*60) Set d=d+1,s=s-(24*60*60)")
			$$$GENERATE("		} Else {")
			$$$GENERATE("			Set s=s-z")
			$$$GENERATE("			If s<0 Set d=d-1,s=s+(24*60*60)")
			$$$GENERATE("		}")
			$$$GENERATE("		Set dt=$zdatetime(d_"",""_s,3,1,0,,,,,"_mindate_",,"""")")
			$$$GENERATE("		Quit $select(dt="""":"""",1:dt_f)")
		}
		$$$GENERATE("	}")
		$$$GENERATE("	If $zdatetimeh(dt,3,1,,,,,"_mindate_",,"""")="""" Quit """_%parameter("XMLDEFAULTVALUE")_"""")
		$$$GENERATE("	Quit dt")
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the %TimeStamp value to the canonical SOAP encoded value.
ClassMethod LogicalToXSD(%val As %TimeStamp) As %String [ CodeMode = generator, ServerOnly = 1 ]
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
ClassMethod OdbcToLogical(%val As %String) As %TimeStamp [ ServerOnly = 1 ]
{
	Quit:%val="" ""
	If $zdatetimeh(%val,3,,,,,,-672045,,"")'="" {
		Set %val=$zdatetime($zdatetimeh(%val,3,,,,,,-672045),3,,$l($p(%val,".",2)),,,,,-672045)
	} elseif $zdatetimeh(%val,-1,,,,,,-672045,,"")'="" {
		Set %val=$zdatetime($zdatetimeh(%val,-1,,,,,,-672045),3,,$l($p(%val,".",2)),,,,,-672045)
	}
	Quit $s(%val'[".":%val,1:$zstrip($zstrip(%val,">","0"),">","."))
}

/// Converts the input value <var>%val</var>, which represents a Display timestamp value,
/// to <code>YYYY-MM-DD HH:MM:SS[.nnnnnnnnn]</code> format.
/// The Logical value and Display values are the same unless there are <a href="#VALUELIST">VALUELIST</a> and <a href="#DISPLAYLIST">DISPLAYLIST</a> parameters specified.
/// <p>Returns the value of the input string <var>%val</var> as a Logical timestamp value (<code>YYYY-MM-DD HH:MM:SS[.nnnnnnnnn]</code> format).
ClassMethod DisplayToLogical(%val As %String) As %TimeStamp [ CodeMode = generator, ServerOnly = 0 ]
{
	If %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("DISPLAYLIST"),%parameter("VALUELIST"))
	} Else {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="%val"
	}
	QUIT $$$OK
}

/// Tests if the logical value <var>%val</var>, which represents a timestamp
/// value in <code>YYYY-MM-DD HH:MM:SS[.nnnnnnnn]</code> format, is valid.
/// The validation is based on the class parameter settings used for the
/// class attribute this data type is associated with.
/// In this case, <a href="#MAXVAL">MAXVAL</a> and <a href="#MINVAL">MINVAL</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DTFailure,%val))"
		Quit $$$OK
	}
	If %parameter("VALUELIST")'="" {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set sep=$extract(%parameter("VALUELIST"))
		Set %code="$select($zu(115,13)&&(%val=$c(0)):$$$OK,%val'["""_sep_"""&&("_$$$quote(%parameter("VALUELIST")_sep)_"[("""_sep_"""_%val_"""_sep_""")):$$$OK,1:$$$ERROR($$$DTValueList,%val,"_$$$quote(%parameter("VALUELIST"))_"))"
	} Else {
		if %parameter("MINVAL")="" { set mindate=0 }
		else { set mindate=$zdateh($p(%parameter("MINVAL")," ",1),3,,,,,-672045,,"") set:mindate="" mindate=0 }
		$$$GENERATE("	RETURN:$zu(115,13)&&(%val=$c(0)) $$$OK")
			// if %val is an integer, assume it is a +%Horolog value and add a time of 00:00:00. If %val is an ODBC %Time value, add the current date. If %val is an ODBC %Date value, add a time of 00:00:00
		$$$GENERATE("	Set val=%val,%val=$select(%val=(%val\1):$zdate(%val,3,,,,,"_mindate_",,""error"")_"" 00:00:00"",%val?1.2N1"":""2N1"":""2N.1(1"".""1.N):$zdate($h,3,,,,,"_mindate_")_"" ""_%val,$length(%val)=10:%val_"" 00:00:00"",1:%val)")
		$$$GENERATE("	Quit:($length(%val)<19||($zdatetimeh(%val,3,,,,,,"_mindate_",,"""")="""")) $$$ERROR($$$DTTimeStamp,val)")
		If %parameter("MINVAL")'="" { $$$GENERATE("	If """_%parameter("MINVAL")_"""]%val Quit $$$ERROR($$$DTMinVal,%val,"""_%parameter("MINVAL")_""")") }
		If %parameter("MAXVAL")'="" { $$$GENERATE("	If %val]"""_%parameter("MAXVAL")_""" Quit $$$ERROR($$$DTMaxVal,%val,"""_%parameter("MAXVAL")_""")") }
		$$$GENERATE("	Quit $$$OK")
	}
	QUIT $$$OK
}

/// Converts the value of <var>%val</var>, which is in logical format <code>YYYY-MM-DD HH:MM:SS[.nnnnnnnnn]</code>, into a display string.
/// The Logical value and Display values are the same unless there are <a href="#VALUELIST">VALUELIST</a> and <a href="#DISPLAYLIST">DISPLAYLIST</a> parameters specified.
/// <p>Returns the Display Timestamp value of the Logical Timestamp string <var>%val</var>.
ClassMethod LogicalToDisplay(%val As %TimeStamp) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
	If %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("VALUELIST"),%parameter("DISPLAYLIST"))
	} Else {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="%val"
	}
	QUIT $$$OK
}

/// Transforms Logical Date or ODBC Date values into timestamp.
/// Date only values are converted to Timestamp values with a time of 00:00:00.
/// Time only values are converted to TImestamp value with a date of current date
ClassMethod Normalize(%val As %RawString) As %TimeStamp [ CodeMode = expression, ServerOnly = 1 ]
{
$s(%val="":"",$zu(115,13)&&(%val=$c(0)):"",%val=(%val\1):$zdate(%val,3,,,,,-672045,,"error")_" 00:00:00",%val?1.2N1":"2N1":"2N.1(1"."1.N):$zdate($h,3)_" "_$s(+$p(%val,".",2)=0:%val,1:$p(%val,".")_+("."_$e($p(%val,".",2),1,9))),$l(%val)=10:%val_" 00:00:00",$zdatetimeh(%val,3,,,,,,-672045,,"")="":"error",1:$zdatetime($zdatetimeh($p(%val,"."),3,,,,,,-672045,,""),3,,,,,,,-672045)_$s(+$p(%val,".",2)=0:"",1:+("."_$e($p(%val,".",2),1,9))))
}

}
