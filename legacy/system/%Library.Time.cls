/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %occUtility

/// The <b>%Time</b> data type class represents a time value.
/// <p>The logical value of the <b>%Time</b> data type is the number of seconds past midnight.
Class %Library.Time Extends %DataType [ ClientDataType = TIME, OdbcType = TIME, SqlCategory = TIME, System = 2 ]
{

/// The format specification for the data type's display value.
/// The value of the <var>FORMAT</var> parameter corresponds to the
/// available parameters of the <code>$ZDATETIME</code> and <code>$ZDATETIMEH</code> functions,
/// which are used to perform the formatting.
Parameter FORMAT;

/// The maximum allowed logical value for the data type.
Parameter MAXVAL;

/// The minimum allowed logical value for the data type.
Parameter MINVAL;

/// The number of decimal places of precision to keep for %Time values.
/// If "" then keep whatever precision is provided by the caller.
Parameter PRECISION;

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

/// XMLTIMEZONE specifies the handling of timezone part of the XML format dateTime.
/// "UTC" means convert to UTC on input.  "IGNORE means ignore the timezone.
Parameter XMLTIMEZONE [ Constraint = "IGNORE,UTC", Flags = ENUM ] = "UTC";

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "time";

Parameter JSONTYPE = "string";

/// Converts the SOAP encoded input time value into a %Time value.
ClassMethod XSDToLogical(%val As %String) As %Time [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		$$$GENERATE(" If $get(%val)="""" Quit """"")
		$$$GENERATE(" If $length(%val,""T"")=2 Set %val=$piece(%val,""T"",2)")
		$$$GENERATE(" Set len=$length(%val)")
		$$$GENERATE(" If $extract(%val,len)=""Z"" {")
		$$$GENERATE("   Set %val=$extract(%val,1,len-1)")
		$$$GENERATE(" } ElseIf $case($extract(%val,len-5),""+"":1,""-"":1,:0) {")
		$$$GENERATE("   If $extract(%val,len-2)'="":"" Quit """"")
		If %parameter("XMLTIMEZONE")="IGNORE" {
			$$$GENERATE("   Set %val=$extract(%val,1,len-6)")
		} Else {
			$$$GENERATE("   Set s=$ztimeh($extract(%val,1,len-6),1,"""",1) If s="""" Quit """"")
			$$$GENERATE("   Set z=($extract(%val,len-4,len-3)*60+$extract(%val,len-1,len))*60")
			$$$GENERATE("   If $extract(%val,len-5)=""-"" {")
			$$$GENERATE("     Set s=s+z")
			$$$GENERATE("   } Else {")
			$$$GENERATE("     Set s=s-z")
			$$$GENERATE("   }")
			If $get(%parameter("PRECISION"))="" {
				$$$GENERATE("   Quit s#86400")
			} Else {
				$$$GENERATE("   Quit $fnumber(s#86400,"""","_$get(%parameter("PRECISION"))_")")
			}
		}
		$$$GENERATE(" }")
		If $get(%parameter("PRECISION"))="" {
			$$$GENERATE(" Quit $ztimeh(%val,1,"""",1)")
		} Else {
			$$$GENERATE(" Quit $fnumber($ztimeh(%val,1,"""",1),"""","_$get(%parameter("PRECISION"))_")")
		}
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the %Time value to the canonical SOAP encoded value.
ClassMethod LogicalToXSD(%val As %Time) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		If %parameter("XMLTIMEZONE")="IGNORE" {
			Set %code="$select(%val="""":"""",1:$ztime(%val,1,"_$select($get(%parameter("PRECISION"))="":"$l($p(%val,""."",2))",1:$get(%parameter("PRECISION")))_",,1))"
		} Else {
			Set %code="$select(%val="""":"""",1:$ztime(%val,1,"_$select($get(%parameter("PRECISION"))="":"$l($p(%val,""."",2))",1:$get(%parameter("PRECISION")))_",,1)_""Z"")"
		}
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the input value <var>%val</var>, which represents a time value,
/// into a logical time value (number of seconds since midnight).
/// <p>Returns the value of the input string <var>%val</var> as a
/// logical time value (number of seconds since midnight).
ClassMethod DisplayToLogical(%val As %String) As %Time [ CodeMode = generator, ServerOnly = 0 ]
{
	if %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("DISPLAYLIST"),%parameter("VALUELIST"))
	} else {
		if %parameter("FORMAT")="" {
			$$$GENERATE(" quit:%val="""" """" s %val=$ztimeh(%val,,""Error: '""_%val_""' is an invalid DISPLAY Time value"") q:%val||(%val=0) "_$select($get(%parameter("PRECISION"))="":"%val",1:"$fnumber(%val,"""","_$get(%parameter("PRECISION"))_")")_" s %msg=%val ZTRAP ""OTIM""")
		} else {
			$$$GENERATE(" quit:%val=""""||($zu(115,13)&&(%val=$c(0))) """" s %val=$ztimeh(%val,"_%parameter("FORMAT")_",""Error: '""_%val_""' is an invalid DISPLAY Time value"") q:%val||(%val=0) "_$select($get(%parameter("PRECISION"))="":"%val",1:"$fnumber(%val,"""","_$get(%parameter("PRECISION"))_")")_" s %msg=%val ZTRAP ""OTIM""")
		}
	}
	QUIT $$$OK
}

/// Tests if the logical value <var>%val</var>, which represents a time value
/// (number of seconds since midnight), is valid.
/// The validation is based on the class parameter settings used for the class
/// attribute this data type is associated with.
/// In this case, <a href="#MAXVAL">MAXVAL</a> and <a href="#MINVAL">MINVAL</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DTFailure,%val))"
		Quit $$$OK
	}
	kill %code set %code=0
	set %codemode=$$$cMETHCODEMODEEXPRESSION
	if %parameter("VALUELIST")'="" {
		set sep=$e(%parameter("VALUELIST")) ;for now
		set %code="$select($zu(115,13)&&(%val=$c(0)):$$$OK,%val'["""_sep_"""&&("_$$$quote(%parameter("VALUELIST")_sep)_"[("""_sep_"""_%val_"""_sep_""")):$$$OK,1:$$$ERROR($$$DTValueList,%val,"_$$$quote(%parameter("VALUELIST"))_"))"
		QUIT $$$OK
	}
	Set min=%parameter("MINVAL"),max=%parameter("MAXVAL")
	If min=""||(min<0) { Set min=0 }
	If max=""||(max>86400) { Set max=86400 }
		#; If max was not specified, we want to allow any value larger than 0 and less than 86400.  If 86399.99999999999... is rounder to 86400, that will report an error too.  I think this allows to a precision of 12 to be supported
	Set %code="$select($zu(115,13)&&(%val=$c(0)):$$$OK,$isvalidnum(%val,,"_min_","_max_")"_$select(max=86400:"&&(%val<86400)",1:"")_":1,'$isvalidnum(%val):$$$ERROR($$$DTNotNum,%val),%val<"_min_":$$$ERROR($$$DTMinVal,%val,"_min_"),1:$$$ERROR($$$DTMaxVal,+%val,"_max_"))"
	QUIT $$$OK
}

/// Converts the value of <var>%val</var>, which is a logical time value
/// (number of seconds since midnight), into a display string. The formatting is based
/// on the value of the <var>FORMAT</var> parameter.
/// Returns the formatted value of <var>%val</var>.
ClassMethod LogicalToDisplay(%val As %Time) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
	If %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		Do GenerateValConv^%occLibrary(%parameter("VALUELIST"),%parameter("DISPLAYLIST"))
	} Else {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(%val="""":"""",1:$ztime(%val,"_$select(%parameter("FORMAT")="":"",1:%parameter("FORMAT"))_","_$select($get(%parameter("PRECISION"))="":"$l($p(%val,""."",2))",1:$get(%parameter("PRECISION")))_"))"
	}
	QUIT $$$OK
}

/// Converts <var>%val</var>, which represents a logical time value
/// (number of seconds since midnight), into ODBC time format.
/// <p>Returns the ODBC time string for the logical time value <var>%val</var>.
ClassMethod LogicalToOdbc(%val As %Time = "") As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %codemode=$$$cMETHCODEMODEEXPRESSION
	Set %code="$select(%val="""":"""",1:$ztime(%val,,"_$select($get(%parameter("PRECISION"))="":"$l($p(%val,""."",2))",1:$get(%parameter("PRECISION")))_",,1))"
}

/// Converts <var>%val</var>, which represents a time in ODBC format,
/// into a logical time value (number of seconds since midnight).
/// <p>Returns the logical time value of the ODBC time string <var>%val</var>.
ClassMethod OdbcToLogical(%val As %String = "") As %Time [ CodeMode = generator, ServerOnly = 1 ]
{
	$$$GENERATE("	quit:%val=""""||($zu(115,13)&&(%val=$c(0))) """"  quit:$isvalidnum(%val) %val s %val=$ztimeh(%val,,""Error: '""_%val_""' is an invalid ODBC/JDBC Time value"",1) q:%val||(%val=0) "_$select($get(%parameter("PRECISION"))="":"%val",1:"$fnumber(%val,"""","_$get(%parameter("PRECISION"))_")")_" s %msg=%val ZTRAP ""OTIM""")
}

/// Converts <var>%val</var> to a normalized value.
ClassMethod Normalize(%val As %RawString) As %Time [ CodeMode = generator, ServerOnly = 1 ]
{
	Set %codemode=$$$cMETHCODEMODEEXPRESSION
	Set %code="$select($zu(115,13)&&(%val=$c(0)):"""",1:"_$select($get(%parameter("PRECISION"))="":"+%val",1:"+$fnumber(%val,"""","_$get(%parameter("PRECISION"))_")")_")"
}

}
