/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlx

IncludeGenerator (%occUtility, %sqlx)

/// The <class>%PosixTime</class> data type class represents a timestamp based on the number of seconds since (or before) January 1, 1970 00:00:00.
/// Logical values are stored as signed 64-bit integers and sort chronologically when stored in globals.
/// These values do not overlap with valid ranges of <class>%Date</class>, ensuring no collisions.
/// <p> The logical format is internal and not meant for direct use by end users.
/// %PosixTime is more efficient than <class>%TimeStamp</class>, requiring less disk space and memory, while offering better performance.
/// <p> The supported date range spans from 0001-01-01 00:00:00 to 9999-12-31 23:59:59.999999.
/// Dates before January 1, 1970, are represented with negative logical values. %PosixTime offers precision down to 1 microsecond.
/// <dl>
/// <dd>To convert between <class>%PosixTime</class> and <class>%TimeStamp</class> format, call <method>LogicalToTimeStamp</method>
/// <dd>To convert between <class>%TimeStamp</class> and <class>%PosixTime</class> format, call <method>TimeStampToLogical</method>
/// <dd>To convert between <class>%PosixTime</class> and <class>%Date</class> format, call <method>LogicalToDate</method>.
/// <dd>To convert between <class>%Date</class> and <class>%PosixTime</class> format, call <method>DateToLogical</method>.  A time of 00:00:00 is used.
/// <dd>To convert between <class>%PosixTime</class> and <class>%Time</class> format, call <method>LogicalToTime</method>.
/// <dd>To convert between <class>%Time</class> and <class>%PosixTime</class> format, call <method>TimeToLogical</method>.  The current date is used.
/// <dd>To determine if a value is a valid logical <class>%PosixTime</class> value, call <method>IsValid</method>.
/// <dd>To get the current, local datetime <class>%PosixTime</class> logical value, call <method>CurrentTimeStamp</method>.
/// <dd>To get the current, UTC datetime <class>%PosixTime</class> logical value, call <method>CurrentUTCTimeStamp</method>.
/// <dd>To get a Unix Timestamp value from a <class>%PosixTime</class> logical (local time) value, call <method>LogicalToUnixTime</method>.
/// <dd>To get a <class>%PosixTime</class> logical value from a Unix Timestamp value, call <method>UnixTimeToLogical</method>.
/// </dl>
Class %Library.PosixTime [ ClassType = datatype, ClientDataType = TIMESTAMP, OdbcType = TIMESTAMP, SqlCategory = POSIXTS, System = 2 ]
{

/// The maximum allowed logical value for the data type.  By default, a Logical value of 1406323805406846975, which is 9999-12-31 23:59:59.999999.
Parameter MAXVAL = 1406323805406846975;

/// The minimum allowed logical value for the data type.  By default, a logical value of -6979664624441081856, which is 0001-01-01 00:00:00.
Parameter MINVAL = -6979664624441081856;

/// The format specification for the data type's date component display value.
/// The value of the <var>DATEFORMAT</var> parameter corresponds to the
/// available parameters of the <code>$ZDATETIME</code> and <code>$ZDATETIMEH</code> function's fformat value,
/// which is used to perform the formatting of the time component of the timestamp value.
Parameter DATEFORMAT = 3;

/// The format specification for the data type's time component display value.
/// The value of the <var>TIMEFORMAT</var> parameter corresponds to the
/// available parameters of the <code>$ZDATETIME</code> and <code>$ZDATETIMEH</code> function's tformat value,
/// which is used to perform the formatting of the time component of the timestamp value.
Parameter TIMEFORMAT = 1;

/// XMLTIMEZONE specifies the handling of timezone part of the XML format dateTime.
/// "UTC" means convert to UTC on input.  "IGNORE means ignore the timezone.
Parameter XMLTIMEZONE [ Constraint = "IGNORE,UTC", Flags = ENUM ] = "UTC";

/// XMLDEFAULTVALUE specifies the value to use if the date fails validity check by $zdatetimeh.
/// By default "" is used which will result in an XMLImport error.
/// A dateTime such as "1841-01-1 00:00:00" may be specified to replace dates such as 0001-01-01 00:00:00 which are not valid %TimeStamp dates.
/// For ease of use, specify a %TimeStamp style logical value for XMLDEFAULTVALUE, not a %PosixTime logical value (which is a 64-bit integer).
Parameter XMLDEFAULTVALUE As STRING [ Internal ];

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "dateTime";

/// Declares the default null marker value to use in index subscripts for properties of type %PosixTime
Parameter INDEXNULLMARKER = "-1E19";

/// JSONTYPE is JSON type used for this datatype.
Parameter JSONTYPE = "number";

/// Converts the SOAP encoded input datetime value into a <class>%PosixTime</class> value.
ClassMethod XSDToLogical(%val As %String) As %PosixTime [ CodeMode = generator, ServerOnly = 1 ]
{
		// Encoding function comes from expansion of $$$sqlxPosixTimeEncode in %sqlx.INC == $ZU(1073741924,%val)
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		// QUIT if there is no "T" delimiter
		$$$GENERATE("	QUIT:$length($get(%val),""T"")'=2 ..OdbcToLogical("""_%parameter("XMLDEFAULTVALUE")_""")")
		// Translate "T" to space
		$$$GENERATE("	Set dt=$translate(%val,""T"","" "")")

		// Z indicates this is a UTC time, hence, no timezone adjustment is needed.
		$$$GENERATE("	If $extract(%val,*)=""Z"" { Set dt=$zdatetimeh($extract(dt,1,*-1),3,1,,,,,-672045,,"""") }")

		// This means there is an offset from the UTC time, indicated by "+" or "-".
		$$$GENERATE("	ElseIf $case($extract(%val,*-5),""+"":1,""-"":1,:0) {")
		$$$GENERATE("		QUIT:$extract(%val,*-2)'="":"" ..OdbcToLogical("""_%parameter("XMLDEFAULTVALUE")_""")")
		// dt is datetime without the offset
		$$$GENERATE("		Set dt=$zdatetimeh($extract(dt,1,*-6),3,1,,,,,-672045,,"""")")
		If %parameter("XMLTIMEZONE")'="IGNORE" {
			$$$GENERATE("		QUIT:dt="""" ..OdbcToLogical("""_%parameter("XMLDEFAULTVALUE")_""")")
			// z is the offset in seconds
			$$$GENERATE("		Set d=$piece(dt,"",""),s=$piece(dt,"","",2),z=($extract(%val,*-4,*-3)*60+$extract(%val,*-1,*))*60")
			// update d and s to apply the offset z
			$$$GENERATE("		If $extract(%val,*-5)=""-"" {")
			$$$GENERATE("			Set s=s+z")
			$$$GENERATE("			If s>=(24*60*60) { Set d=d+1,s=s-(24*60*60) }")
			$$$GENERATE("		}")
			$$$GENERATE("		Else {")
			$$$GENERATE("			Set s=s-z")
			$$$GENERATE("			If s<0 { Set d=d-1,s=s+(24*60*60) }")
			$$$GENERATE("		}")
			$$$GENERATE("		Set dt=d_"",""_s")
		}

		// Else, there is no "Z" or offset to account for.
		$$$GENERATE("	} Else {")
		$$$GENERATE("		Set dt=$zdatetimeh(dt,3,1,,,,,-672045,,"""")")			// dt is now in $h/$zts format. or "" if there was an error
		$$$GENERATE("	}")

		$$$GENERATE("	QUIT:dt="""" ..OdbcToLogical("""_%parameter("XMLDEFAULTVALUE")_""")")
				// Now convert from $h/$zts to posix time, then to encoded %PosixTime
		$$$GENERATE("	QUIT $zu(1073741924,(dt-47117)*86400+$p(dt,"","",2))")
	}
	Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the <class>%PosixTime</class> value to the canonical SOAP encoded value.
ClassMethod LogicalToXSD(%val As %PosixTime) As %String [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		$$$GENERATE("	QUIT:%val="""" """"")
		$$$GENERATE("	set val=$zu(1073741925,+%val),time=(val#86400)")
		If %parameter("XMLTIMEZONE")="IGNORE" {
			$$$GENERATE("	QUIT $tr($zdatetime((val\86400+47117-((val<0)&&(time)))_"",""_time,3,1,$l($p(val,""."",2)),,,,,-672045),"" "",""T"")")
		}
		Else {
			$$$GENERATE("	QUIT $tr($zdatetime((val\86400+47117-((val<0)&&(time)))_"",""_time,3,1,$l($p(val,""."",2)),,,,,-672045),"" "",""T"")_""Z""")
		}
	}
	Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts the JSON UNIX time to logical %PosixTime.
ClassMethod JSONToLogical(%val As %BigInt) As %PosixTime [ CodeMode = generator ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		$$$GENERATE("	Quit ##class(%PosixTime).UnixTimeToLogical(%val)")
	} Else {
		Set %code=0
	}
	Quit $$$OK
}

/// Converts the logical %PosixTime value to the JSON integer UNIX time value.
ClassMethod LogicalToJSON(%val As %FilemanTimeStamp) As %BigInt [ CodeMode = generator ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		$$$GENERATE("	Quit ##class(%PosixTime).LogicalToUnixTime(%val)")
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts <var>%val</var>, which represents either a Timestamp in ODBC format, or a Date in ODBC format, into a logical <class>%PosixTime</class> value.
/// <p>Returns the logical <class>%PosixTime</class> value of the ODBC Timestamp string <var>%val</var>.
ClassMethod OdbcToLogical(%val As %RawString) As %Library.PosixTime [ CodeMode = generator, ServerOnly = 1 ]
{
		// Encoding function comes from expansion of $$$sqlxPosixTimeEncode in %sqlx.INC == $ZU(1073741924,%val)
	$$$GENERATE("	RETURN:%val="""" """"")
	$$$GENERATE("	RETURN:$isvalidnum(%val) $decimal(%val)")			// Already in Logical format, maybe.  Doesn't have to be valid.  That will be checked in IsValid.  This does allow or something like PSTime > 1 in a where condition
	$$$GENERATE("	set precision=$l($p(%val,""."",2)),val=$zdatetimeh(%val,3,1,precision,4,,,-672045,,"""")")						// val is now in $h/$zts format
	$$$GENERATE("	if val="""" { set val=$zdatetimeh(%val,-1,1,precision,,,,-672045,,"""") }")	// try with default date format, if successful, val is now in $h/$zts format
	$$$GENERATE("	if val="""" { set val=$$ConvertDATETIMEToTIMESTAMP^%qarfunc(%val,,,$zdate(+$h,2),1) RETURN:$isvalidnum(val) val set val="""" }")	// attempt to convert it from datetime to posixtime
	$$$GENERATE("	if val="""" { set %msg=""Unable to convert ""_%val_"" to a logical %PosixTime value"" ZTRAP ""ODAT"" }")
			// Now convert from $h/$zts to posix time, then to encoded %PosixTime
	$$$GENERATE("	RETURN $zu(1073741924,(val-47117)*86400+$p(val,"","",2))")
	Quit $$$OK
}

/// Converts <var>%val</var>, which represents a logical <class>%PosixTime</class> value into an ODBC format TIMESTAMP value
ClassMethod LogicalToOdbc(%val As %PosixTime) As %TimeStamp [ CodeMode = generator, ServerOnly = 1 ]
{
		// Decoding function comes from expansion of $$$sqlxPosixTimeDecode in %sqlx.INC == $ZU(1073741925,%val)
	$$$GENERATE("	Quit $s(%val="""":"""",1:$zdatetime(($zu(1073741925,+%val)\86400+47117-(($zu(1073741925,+%val)<0)&&($zu(1073741925,+%val)#86400)))_"",""_($zu(1073741925,+%val)#86400),3,1,$l($p($zu(1073741925,+%val),""."",2)),,,,,-672045))")
	Quit $$$OK
}

/// Converts the input value <var>%val</var>, which represents a display timestamp value, in a logical <class>%PosixTime</class> value.
ClassMethod DisplayToLogical(%val As %RawString) As %PosixTime [ CodeMode = generator, ServerOnly = 0 ]
{
		// Encoding function comes from expansion of $$$sqlxPosixTimeEncode in %sqlx.INC == $ZU(1073741924,%val)
	set %code=0
	if %parameter("DATEFORMAT")="" { set dformat=-1 } else { set dformat=%parameter("DATEFORMAT") }
	if %parameter("TIMEFORMAT")="" { set tformat=-1 } else { set tformat=%parameter("TIMEFORMAT") }
		// First convert from DisplayFormat to $H style logical format
	$$$GENERATE("	RETURN:%val="""" """"")
	$$$GENERATE("	RETURN:$isvalidnum(%val) $decimal(%val)")			// Already in Logical format, maybe.  Doesn't have to be valid.  That will be checked in IsValid.  This does allow or something like PSTime > 1 in a where condition
	$$$GENERATE("	set val=$zdatetimeh(%val,"_dformat_","_tformat_",,,,,-672045,,"""")")
	$$$GENERATE("	if val="""" { set val=$$ConvertDATETIMEToTIMESTAMP^%qarfunc(%val,,,$zdate(+$h,2),1) RETURN:$isvalidnum(val) val set val="""" }")	// attempt to convert it from datetime to posixtime
	$$$GENERATE("	if val="""" { set %msg=""Error: '""_%val_""' is an invalid DISPLAY %PosixTime value"" ZTRAP ""ODAT"" }")
		// val is now a valid $H-style value, convert to Posix time, then encoded %PosixTime
	$$$GENERATE("	QUIT $zu(1073741924,(val-47117)*86400+$p(val,"","",2))")
}

/// Converts the value of <var>%val</var>, which is in logical format as the encoded number of seconds since Jan 01, 1970 00:00:00, into a display timestamp string.
ClassMethod LogicalToDisplay(%val As %PosixTime) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
		// Decoding function comes from expansion of $$$sqlxPosixTimeDecode in %sqlx.INC == $ZU(1073741925,%val)
	set %code=0
	if %parameter("DATEFORMAT")="" { set dformat=-1 } else { set dformat=%parameter("DATEFORMAT") }
	if %parameter("TIMEFORMAT")="" { set tformat=-1 } else { set tformat=%parameter("TIMEFORMAT") }
	$$$GENERATE("	Quit $s(%val="""":"""",1:$zdatetime(($zu(1073741925,+%val)\86400+47117-(($zu(1073741925,+%val)<0)&&($zu(1073741925,+%val)#86400)))_"",""_($zu(1073741925,+%val)#86400),"_dformat_","_tformat_",$l($p($zu(1073741925,+%val),""."",2)),,4,,,-672045))")
	QUIT $$$OK
}

/// Tests if the logical value <var>%val</var>, which represents a <class>%PosixTime</class> value, is valid.
/// Input value of a valid <class>%TimeStamp</class> logical value or <class>%Date</class> ODBC value is also allowed.  If <class>%TimeStamp</class> logical value or <class>%Date</class> ODBC value is given, it will first be converted to a <class>%PosixTime</class> value
/// The validation is based on the class parameter settings used for the class attribute this data type is associated with.
/// In this case, <a href="#MAXVAL">MAXVAL</a> and <a href="#MINVAL">MINVAL</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
		// Validation function comes from expansion of $$$sqlxPosixTimeIsValid in %sqlx.INC == $ZU(1073741926,val)
		// If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DTFailure,%val))"
		Quit $$$OK
	}
	$$$GENERATE("	QUIT:%val=""""||($zu(115,13)&&(%val=$c(0))) 1")
		// If a %TimeStamp value was passed in, convert it to %PosixTime to validate.  We will also convert %TimeStamp to %PosixTime in Normalize
		// If a %Date ODBC value was passed in, convert it to %PosixTime to validate.  We will also convert %Date ODBC value to %PosixTime in Normalize
		// If a logical %Date value was passed in, convert it to a %PosixTime to validate.  We will also convert %Date logical value to %PosixTime in Normalize
	$$$GENERATE("	if $e(%val,2,*)[""-"" {")
	$$$GENERATE("		if %val?0.1""-""4N1""-""2N1""-""2N1"" ""2N1"":""2N1"":""2N.e { set precision=$l($p(%val,""."",2)),val=$zdatetimeh(%val,3,1,precision,4,,,-672045,,""Error"") if val=""Error"" { QUIT $$$ERROR($$$DTNotPosix,%val) } set %val=$zu(1073741924,(val-47117)*86400+$p(val,"","",2)) }")
	$$$GENERATE("		elseif %val?0.1""-""4N1""-""2N1""-""2N { set val=$zdatetimeh(%val_"" 00:00:00"",3,1,0,4,,,-672045,,""Error"") if val=""Error"" { QUIT $$$ERROR($$$DTNotPosix,%val) } set %val=$zu(1073741924,(val-47117)*86400+$p(val,"","",2)) }")
	$$$GENERATE("	} elseif %val=(%val\1),%val<2980014,%val>-672046 { set %val=$zu(1073741924,(%val-47117)*86400) }")	// logical %Date value
		// At this point, %val should be a long integer %PosixTime value
	if %parameter("MINVAL")'="" { $$$GENERATE("	QUIT:(%val<"_%parameter("MINVAL")_") $$$ERROR($$$DTMinVal,%val,"_%parameter("MINVAL")_")") }
	if %parameter("MAXVAL")'="" { $$$GENERATE("	QUIT:(%val>"_%parameter("MAXVAL")_") $$$ERROR($$$DTMaxVal,%val,"_%parameter("MAXVAL")_")") }
	$$$GENERATE("	set:$isvalidnum(%val) %val=+%val")	// Make sure the value is in integer and not string format
	$$$GENERATE("	QUIT $s($ZU(1073741926,%val):1,1:$$$ERROR($$$DTNotPosix,%val))")
	QUIT $$$OK
}

/// Converts <var>%val</var> to a normalized <class>%PosixTime</class> value.
/// Input value of a valid <class>%TimeStamp</class> logical value, <class>%Date</class> ODBC value, or <class>%Date</class> logical value is also allowed.  If <class>%TimeStamp</class> logical value , <class>%Date</class> ODBC value, or <class>%Date</class> logical value is given, it will first be converted to a <class>%PosixTime</class> value
ClassMethod Normalize(%val As %RawString) As %PosixTime [ CodeMode = generator, ServerOnly = 1 ]
{
	$$$GENERATE("	QUIT:%val=""""||($zu(115,13)&&(%val=$c(0))) """"")
		// If a %TimeStamp value was passed in, convert it to %PosixTime.  No error reported if a bad value, should have been caught in IsValid
		// If a ODBC %Date value was passed in, convert it to %PosixTime with time of 00:00:00.  No error reported if a bad value, should have been caught in IsValid
	$$$GENERATE("	if $e(%val,2,*)[""-"" {")
	$$$GENERATE("		if %val?0.1""-""4N1""-""2N1""-""2N1"" ""2N1"":""2N1"":""2N.e { set precision=$l($p(%val,""."",2)),val=$zdatetimeh(%val,3,1,precision,4,,,-672045,,"""") if val'="""" { set %val=$zu(1073741924,(val-47117)*86400+$p(val,"","",2)) }}")
	$$$GENERATE("		elseif %val?0.1""-""4N1""-""2N1""-""2N { set val=$zdatetimeh(%val_"" 00:00:00"",3,1,0,4,,,-672045,,"""") if val'="""" { set %val=$zu(1073741924,(val-47117)*86400+$p(val,"","",2)) }}")
	$$$GENERATE("	} elseif %val=(%val\1),%val<2980014,%val>-672046 { set %val=$zu(1073741924,(%val-47117)*86400) }")	// logical %Date value
	$$$GENERATE("	QUIT %val\1")
}

/// Converts a logical <class>%Date</class> value to logical <class>%PosixTime</class> value.
ClassMethod DateToLogical(%val As %Date) As %Library.PosixTime [ CodeMode = expression, ServerOnly = 1 ]
{
$select(%val="":"",1:$zu(1073741924,(%val-47117)*86400))
}

/// Converts a logical <class>%PosixTime</class> value to a logical <class>%Date</class> value.
ClassMethod LogicalToDate(%val As %Library.PosixTime) As %Library.Date [ CodeMode = generator, ServerOnly = 1 ]
{
	$$$GENERATE("	QUIT:%val="""" """" set val=$zu(1073741925,+%val),time=(val#86400) QUIT (val\86400+47117-((val<0)&&(time)))")
}

/// Converts a logical <class>%PosixTime</class> value to a logical <class>%Time</class> value.
ClassMethod LogicalToTime(%val As %Library.PosixTime) As %Library.Time [ CodeMode = generator, ServerOnly = 1 ]
{
	$$$GENERATE("	QUIT:%val="""" """" set val=$zu(1073741925,+%val) QUIT (val#86400)")
}

/// Converts a logical <class>%Time</class> value to a logical <class>%PosixTime</class> value.
ClassMethod TimeToLogical(%val As %Library.Time) As %Library.PosixTime [ CodeMode = expression, ServerOnly = 1 ]
{
$select(%val="":"",1:$zu(1073741924,(+$h-47117)*86400+%val))
}

/// Converts a logical <class>%TimeStamp</class> value to a logical <class>%PosixTime</class> value.
ClassMethod TimeStampToLogical(%val As %Library.TimeStamp) As %Library.PosixTime [ CodeMode = generator, ServerOnly = 1 ]
{
	$$$GENERATE("	QUIT:%val="""" """"  set precision=$l($p(%val,""."",2))")
	$$$GENERATE("	set val=$zdatetimeh(%val,3,1,precision,,,,-672045,,""Error: '""_%val_""' is an invalid %TimeStamp value passed to TimeStampToLogical()"") if $e(val,1,5)=""Error"" { set %msg=val ZTRAP ""ODAT"" }")	// if successful, val is now in $h/$zts format
			// Now convert from $h/$zts to posix time, then to encoded %PosixTime
	$$$GENERATE("	QUIT $zu(1073741924,(val-47117)*86400+$p(val,"","",2))")
	Quit $$$OK
}

/// Converts a logical <class>%PosixTime</class> value to a logical <class>%TimeStamp</class> value.
ClassMethod LogicalToTimeStamp(%val As %Library.PosixTime) As %Library.TimeStamp [ CodeMode = generator, ServerOnly = 1 ]
{
	$$$GENERATE("	Quit $s(%val="""":"""",1:$zdatetime(($zu(1073741925,+%val)\86400+47117-(($zu(1073741925,+%val)<0)&&($zu(1073741925,+%val)#86400)))_"",""_($zu(1073741925,+%val)#86400),3,1,$l($p($zu(1073741925,+%val),""."",2)),,,,,-672045))")
	Quit $$$OK
}

/// Converts a logical <class>%PosixTime</class> value to a Unix time value (number of seconds before or after 01 Jan 1970 00:00:00.000000).
ClassMethod LogicalToUnixTime(%val As %Library.PosixTime) As %Library.Decimal [ CodeMode = generator, ServerOnly = 1 ]
{
		// Convert encoded %PosixTime to $zu(188) format, then convert to UTC $zu(188) time, then output as Unix Time.
	$$$GENERATE("	QUIT:%val="""" """" set val=$zu(1073741925,+%val),time=(val#86400),val=(val\86400+47117-((val<0)&&(time)))_"",""_time QUIT (val-47117)*86400+$p(val,"","",2)")
	RETURN $$$OK
}

/// Converts a a Unix time value (number of seconds before or after 01 Jan 1970 00:00:00.000000 UTC) to a logical local <class>%PosixTime</class> value.
ClassMethod UnixTimeToLogical(%val As %Library.Decimal) As %Library.PosixTime [ CodeMode = generator, ServerOnly = 1 ]
{
		// Convert Unix Time to UTC $zu(188) format, then convert to local $zu(188) format, then output as %PosixTime
	$$$GENERATE("	QUIT:%val="""" """" set time=(%val#86400),val=(%val\86400+47117-((%val<0)&&(time)))_"",""_time QUIT $zu(1073741924,(val-47117)*86400+$p(val,"","",2))")
	RETURN $$$OK
}

/// Returns the current logical <class>%PosixTime</class> value.
ClassMethod CurrentTimeStamp(precision As %Library.Integer = 6) As %Library.PosixTime [ ServerOnly = 1 ]
{
	set val=$zu(188),days=$p(val,","),seconds=$fn($p(val,",",2),"",precision) QUIT $zu(1073741924,(days-47117)*86400+seconds)
}

/// Returns the current logical UTC <class>%PosixTime</class> value.
ClassMethod CurrentUTCTimeStamp(precision As %Library.Integer = 6) As %Library.PosixTime [ ServerOnly = 1 ]
{
	set val=$now(0),days=$p(val,","),seconds=$fn($p(val,",",2),"",precision) QUIT $zu(1073741924,(days-47117)*86400+seconds)
}

}
