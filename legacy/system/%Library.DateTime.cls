/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>The %Library.DateTime datatype used mainly for T-SQL migrations and maps datetime/smalldatetime behavior to the %TimeStamp datatype.
/// %DateTime is the same as %TimeStamp (is a sub-class or %TimeStamp) with extra logic in the DisplayToLogical and OdbcToLogical methods to handle imprecise datetime input T-SQL applications are accustomed to.
/// </p>
/// <p>The formats supported for %DateTime can be broken into date formats and time formats.
/// Date formats can be further broken into alphabetic formats and numeric formats.
/// </p>
/// <p>Display and Odbc formats for alphabetic date values that are supported are as follows:
/// </p>
/// <pre>
/// 	Apr[il] [15][,] 1996	
/// 	Apr[il] 15[,] [19]96 	
/// 	Apr[il] 1996 [15]	
/// 		
/// 	[15] Apr[il][,] 1996 
/// 	15 Apr[il][,][19]96 
/// 	15 [19]96 apr[il]
/// 	[15] 1996 apr[il]	
/// 		
/// 	1996 APR[IL] [15]	
/// 	1996 [15] APR[IL]	
/// </pre>
/// 	
/// <p>If you specify only the last two digits of the year, values less than the last two digits of the value of the two digit year cutoff configuration option are in the same century as the cutoff year. 
/// Values greater than or equal to the value of this option are in the century that precedes the cutoff year. 
/// For example, if two digit year cutoff is 2050 (default), 25 is interpreted as 2025 and 50 is interpreted as 1950. 
/// To avoid any ambiguity. use four-digit years.
/// If the day is missing, the first day of the month is supplied.
/// </p>
/// 
/// <p>The %Library.DateTime datatype also allows you to specify date data with a numeric month specified. 
/// For example, 9/13/98 represents the thirteenth day of September, 1998. 
/// When using numeric date format, specify the month, day, and year in a string with slash marks (/), hyphens (-), or periods (.) as separators. 
/// </p>
/// <p>This string must appear in the following form:
/// </p>
/// <pre>	
/// 	number separator number separator number [time] [time]
/// 	
/// 	These numeric formats are valid:
/// 	
/// 	[0]4/15/[19]96 -- (mdy)
/// 	[0]4-15-[19]96 -- (mdy)
/// 	[0]4.15.[19]96 -- (mdy)
/// 	[04]/[19]96/15 -- (myd)
/// 	
/// 	15/[0]4/[19]96 -- (dmy)
/// 	15/[19]96/[0]4 -- (dym)
/// 	[19]96/15/[0]4 -- (ydm)
/// 	[19]96/[04]/15 -- (ymd)
/// </pre>	
/// <p>The default order for the date is mdy. You can change the date order with the DATEFORMAT parameter.
/// The setting for the DATEFORMAT parameter determines how date values are interpreted. 
/// If the order does not match the setting, the values are not interpreted as dates (because they are invalid dates), or the values are misinterpreted.
/// For example, 11/10/09 can be interpreted as one of six dates, depending on the DATEFORMAT parameter setting:   mdy, dmy, ymd, ydm, myd, and dym
/// </p>
/// <p> %DateTime recognizes the following formats for time data in Display and Odbc mode: </p>
/// <pre>	
/// 	14:30
/// 	14:30[:20:999]
/// 	14:30[:20.9]
/// 	4am
/// 	4 PM
/// 	[0]4[:30:20:500]AM
/// </pre>
/// <p> You can specify a suffix of AM or PM to indicate if the time value is before or after 12 noon. The case of AM or PM is ignored.
/// Hours can be specified using either a 12-hour or 24-hour clock.
/// </p>
/// <p>This is how the hour values are interpreted: 
/// </p>	
/// <p> - The hour value of 0 represents the hour after midnight (AM), regardless of whether or not you specify AM. You cannot specify PM when the hour equals 0.
/// </p>	
/// <p> - Hour values from 1 through 11 represent the hours before noon if neither AM nor PM is specified. 
/// They also represent the hours before noon when AM is specified. They represent hours after noon if PM is specified.
/// </p>	
/// <p> - The hour value 12 represents the hour that starts at noon if neither AM nor PM is specified. If AM is specified, it represents the hour that starts at midnight. 
/// If PM is specified, it represents the hour that starts at noon. For example: 12:01 is 1 minute after noon, as is 12:01 PM, while 12:01 AM is 1 minute after midnight. 
/// Specifying 12:01 AM is the same as specifying 00:01 or 00:01 AM.
/// </p>	
/// <p> - Hour values from 13 through 23 represents hours after noon if AM or PM is specified. They also represent the hours after noon when PM is specified. 
/// You cannot specify AM when the hour value is from 13 through 23.
/// </p>
/// <p> - An hour value of 24 is not valid, use 12:00 AM or 00:00 to represent midnight. </p> 
/// <p>Milliseconds can be preceded by either a colon (:) or a period (.). If preceded by a colon, the number means thousandths-of-a-second. 
/// If preceded by a period, a single digit means tenths-of-a-second, two digits mean hundredths-of-a-second, and three digits mean thousandths-of-a-second. 
/// For example, 12:30:20:1 indicates twenty and one-thousandth seconds past 12:30; 12:30:20.1 indicates twenty and one-tenth seconds past 12:30.
/// </p>
Class %Library.DateTime Extends %TimeStamp [ ClientDataType = TIMESTAMP, OdbcType = TIMESTAMP, SqlCategory = TIMESTAMP, System = 3 ]
{

/// Order of the date parts when a numeric date format is specified for the Display or Odbc input value. Valid parameters are mdy, dmy, ymd, ydm, myd, and dym.  The default DATEFORMAT is mdy.
Parameter DATEFORMAT = "mdy";

/// Tests if the logical value <var>%val</var>, which represents a timestamp
/// value in <code>YYYY-MM-DD HH:MM:SS[.nnnnnnnn]</code> format, is valid.
/// The validation is based on the class parameter settings used for the
/// class attribute this data type is associated with.
/// In this case, <a href="#MAXVAL">MAXVAL</a> and <a href="#MINVAL">MINVAL</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
		#; convert input value to a %TimeStamp
		#; tsval should now be a %TimeStamp value
	If %parameter("VALUELIST")'="" {
		$$$GENERATE("	set tsval=$$ConvertDATETIMEToTIMESTAMP^%qarfunc(%val,"""_%parameter("DATEFORMAT")_""")")
		Set sep=$extract(%parameter("VALUELIST"))
		$$$GENERATE("	RETURN $select($zu(115,13)&&(tsval=$c(0)):$$$OK,tsval'["""_sep_"""&&("_$$$quote(%parameter("VALUELIST")_sep)_"[("""_sep_"""_tsval_"""_sep_""")):$$$OK,1:$$$ERROR($$$DTValueList,tsval,"_$$$quote(%parameter("VALUELIST"))_"))")
	} Else {
		if %parameter("MINVAL")="" { set mindate=-672045 }
		else { set mindate=$zdateh($p(%parameter("MINVAL")," ",1),3,,,,,-672045,,"") set:mindate="" mindate=-672045 }
		set maxdate=""
		if %parameter("MAXVAL")'="" { set maxdate=$zdateh($p(%parameter("MAXVAL")," ",1),3,,,,,-672045,,"") }
		$$$GENERATE("	RETURN:$zdatetimeh(%val,3,,,,,,,,"""")'="""" $$$OK")	// Already a valid %DateTime value, no need for further checking, don't use -672045 for mindate for this check
		$$$GENERATE("	set tsval=$$ConvertDATETIMEToTIMESTAMP^%qarfunc(%val,"""_%parameter("DATEFORMAT")_""")")
		$$$GENERATE("	RETURN:($length(tsval)<19||($zdatetimeh(tsval,3,,,,,,"_mindate_",,"""")="""")) $$$ERROR($$$DTDateTime,%val_"" (""_tsval_"")"")")
		If %parameter("MINVAL")'="" { $$$GENERATE("	If """_%parameter("MINVAL")_"""]tsval RETURN $$$ERROR($$$DTMinVal,tsval,"""_%parameter("MINVAL")_""")") }
		If %parameter("MAXVAL")'="" { $$$GENERATE("	If tsval]"""_%parameter("MAXVAL")_""" RETURN $$$ERROR($$$DTMaxVal,tsval,"""_%parameter("MAXVAL")_""")") }
		$$$GENERATE("	RETURN $$$OK")
	}
	QUIT $$$OK
}

/// Transforms TSQL datetime values into timestamp.
/// Date values are converted to Timestamp values with a time of 00:00:00.
ClassMethod Normalize(%val As %RawString) As %TimeStamp [ CodeMode = generator, ServerOnly = 1 ]
{
	$$$GENERATE("	if $zdatetimeh(%val,3,,,,,,,,"""")'="""" {")				// Already a valid %DateTime value, don't use -672045 for mindate for this check
	$$$GENERATE("		if %val?4N1""-""2N1""-""2N { RETURN %val_"" 00:00:00"" }")	// Turn ODBC DATE into %DateTime
	$$$GENERATE("		if %val[""T"" { set %val=$tr(%val,""T"","" "") }")
	$$$GENERATE("		RETURN $zstrip(%val,"">W"",$s(%val[""."":""0"",1:""""))")
	$$$GENERATE("	}")
	$$$GENERATE("	set tsval=$$ConvertDATETIMEToTIMESTAMP^%qarfunc(%val,"""_%parameter("DATEFORMAT")_""")")
	$$$GENERATE("	RETURN:tsval=""""||($zu(115,13)&&(tsval=$c(0))) """"")
	$$$GENERATE("	set intval=$zdatetimeh(tsval,3,1,,,,,-672045,,"""") RETURN:intval="""" ""error""")
	$$$GENERATE("	RETURN $zdatetime(intval,3,1,+$l($p(tsval,""."",2)),,,,,-672045)")
}

/// Converts the input value <var>%val</var>, which represents a Display timestamp value,
/// to <code>YYYY-MM-DD HH:MM:SS[.nnnnnnnnn]</code> format.
/// The Logical value and Display values are the same unless there are <a href="#VALUELIST">VALUELIST</a> and <a href="#DISPLAYLIST">DISPLAYLIST</a> parameters specified.
/// <p>Returns the value of the input string <var>%val</var> as a Logical timestamp value (<code>YYYY-MM-DD HH:MM:SS[.nnnnnnnnn]</code> format).
ClassMethod DisplayToLogical(%val As %String) As %TimeStamp [ CodeMode = generator, ServerOnly = 0 ]
{
	if %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("DISPLAYLIST"),%parameter("VALUELIST"))
		QUIT $$$OK
	}
	$$$GENERATE($c(9)_"quit $$ConvertDATETIMEToTIMESTAMP^%qarfunc(%val,"""_%parameter("DATEFORMAT")_""")")
	QUIT $$$OK
}

/// Converts <var>%val</var>, which represents either a Timestamp in ODBC format,
/// or a Date in ODBC format, into a logical Timestamp value.
/// <p>Returns the logical Timestamp value of the ODBC Timestamp string <var>%val</var>.
ClassMethod OdbcToLogical(%val As %String) As %TimeStamp [ CodeMode = generator, ServerOnly = 0 ]
{
	#; First convert any DateTime supported input values to a value timestamp value
	$$$GENERATE($c(9)_"set %val=$$ConvertDATETIMEToTIMESTAMP^%qarfunc(%val,"""_%parameter("DATEFORMAT")_""")")
	#;                                if a valid timestamp value, return it with proper precision                               or if the value is in the locale's default date format, convert and return it                   value assumed to be in timestamp format, strip any trailing 0's and possibly trailing "."'s
	$$$GENERATE($c(9)_"quit:%val="""" """" if $zdth(%val,3,,,,,,,,"""")'="""" { s %val=$zdt($zdth(%val,3),3,,$l($p(%val,""."",2))) } elseif $zdth(%val,-1,,,,,,,,"""")'="""" { s %val=$zdt($zdth(%val,-1),3,,$l($p(%val,""."",2))) } quit $s(%val'[""."":%val,1:$zstrip($zstrip(%val,"">"",""0""),"">"","".""))")
	Quit $$$OK
}

}
