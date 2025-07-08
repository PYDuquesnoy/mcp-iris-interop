/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Custom DATE data type designed to convert FILEMAN format (CYYMMDD) dates.
/// This data type projects proper DATE meta-data to DISPLAY and ODBC client software.
/// It does not require any extra routines to function
Class %Library.FilemanDate [ ClassType = datatype, ClientDataType = FDATE, OdbcType = DATE, SqlCategory = FMDATE, System = 2 ]
{

/// 1/0 flag which determines if the LogicalToFormat conversions will process imprecise logical FileMan Date values
/// Default setting is STRICTDATA=0
/// Parameter affects the generation of the LogicalToDisplay and LogicalToOdbc methods
/// When STRICTDATA=1, imprecise or invalid dates will not be changed to a valid FileMan Date value.
/// For example, if Logical FileMan Date value is 31110, when STRICTDATA=0 this will translate to 3111001 (Sept 01, 2011).
/// If STRICTDATA=1, this transformation will not take place and the invalid/imprecise Logical value will get an error when converted to Display or Odbc format.
Parameter STRICTDATA As BOOLEAN = 0;

Parameter XSDTYPE = "date";

Parameter JSONTYPE = "string";

ClassMethod XSDToLogical(%val As %String) As %FilemanDate [ CodeMode = generator ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		$$$GENERATE("	Set len=$length(%val)")
		$$$GENERATE("	If len'=10 { If $extract(%val,len)=""Z"" { Set %val=$extract(%val,1,len-1) } ElseIf $case($extract(%val,len-5),""+"":1,""-"":1,:0) { Set %val=$extract(%val,1,len-6) } }")
		$$$GENERATE("	Quit ##class(%FilemanDate).OdbcToLogical(%val)")
	}
	Else { Set %code=0 }
	Quit $$$OK
}

/// Converts the %FilemanDate value to the canonical SOAP encoded value.
ClassMethod LogicalToXSD(%val As %FilemanDate) As %String [ CodeMode = generator ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(%val="""":"""",1:##class(%FilemanDate).LogicalToOdbc(%val))"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

ClassMethod JSONToLogical(%val As %String) As %FilemanDate [ CodeMode = generator ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(%val="""":"""",1:##class(%FilemanDate).LogicalToOdbc(%val))"

	} Else {
		Set %code=0
	}
	Quit $$$OK
}

/// Converts the logical %FilemanDate value to the JSON string value.
ClassMethod LogicalToJSON(%val As %FilemanDate) As %String [ CodeMode = generator ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(%val="""":"""",1:##class(%FilemanDate).LogicalToOdbc(%val))"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts DISPLAY format DATE (DD/MM/YYYY) to FILEMAN format DATE (CYYMMDD).
ClassMethod DisplayToLogical(Arg1 As %Library.String) As %Library.FilemanDate [ ServerOnly = 0 ]
{
		#; Version 2003-09-19 DCN
		#; Checks Input for Null value
	quit:Arg1="" ""
		#;  Allow FileMan Date format (CYYMMDD) or FileMan Datetime (CYYMMDD.HHMMSS) to be input here.  This allows users typing in values as input to an DISPLAY query to enter FileManDate
		#;  values rather than MM/DD/YYYY DISPLAY values.  The VA requested this ability because they like to use FMDate values as input from ODBC/Display
		#;  If the input value is a 7 digit number, assume it is a FileMan Date logical value already.
	QUIT:Arg1?7N Arg1
		#;  If the input value is a 7.6 digit value, assume it is a FileMan DateTime logical value already.
	QUIT:Arg1?7N1"."6N $p(Arg1,".")
		#; Checks Input for Invalid Format.
		#; Expects DISPLAY format DATE (DD/MM/YYYY).
	quit:Arg1'?1.2N1"/"1.2N1"/"4N ""
		#; Returns FILEMAN format DATE (CYYMMDD)
	quit:$zdh(Arg1,,,,,,,,"")="" ""
	quit $zd($zdh(Arg1),8)-17000000
}

/// Checks for Invalid format, expects FILEMAN format DATE (CYYMMDD).
/// Can handle data on disk in the Fileman TimeStamp format.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %code="$select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val))"
		Quit $$$OK
	}
	 $$$GENERATE(" s Arg1=%val quit:Arg1="""" $$$OK quit:Arg1'?7N.1(1""."".6N) $$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val)")
	 $$$GENERATE(" s:$L(Arg1)>7 Arg1=$p(Arg1,""."",1) s:$e(Arg1,4,5)=""00"" $e(Arg1,4,5)=""01"" s:$e(Arg1,6,7)=""00"" $e(Arg1,6,7)=""01""")
	 $$$GENERATE(" quit $s($zdh(Arg1+17000000,8,,,,,,,"""")'="""":$$$OK,1:$$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val))")
	 Quit $$$OK
}

/// Converts FILEMAN format DATE (CYYMMDD) to DISPLAY format DATE (DD/MM/YYYY).
/// Can handle data on disk in the Fileman TimeStamp format.
ClassMethod LogicalToDisplay(Arg1 As %Library.FilemanDate) As %Library.String [ CodeMode = generator, ServerOnly = 0 ]
{
 		#; Checks Input for Null Value
 	$$$GENERATE($c(9)_"QUIT:Arg1="""" """"")
	if %parameter("STRICTDATA")=1 {
		$$$GENERATE($c(9)_"set tDate=$p(Arg1,""."") QUIT:$l(tDate)'=7 """"")
	}
	else {
			#; Pad TIME value with Zeros because FILEMAN TimeStamps do not store trailing zeros on disk
		$$$GENERATE($c(9)_"set tDate=$p(Arg1,""."")")
			#; Checks for partial date
		$$$GENERATE($c(9)_"if $l(tDate)<7 {")
		$$$GENERATE($c(9,9)_"set:$l(tDate)=2 tDate=$e($zd($h,3)-1700)_tDate_""0101"" 	// tDate is current 2 year date, add current century and Jan 01")
		$$$GENERATE($c(9,9)_"set:$l(tDate)=3 tDate=tDate_""0101""			// tDate is CYY, add Jan 01")
		$$$GENERATE($c(9,9)_"set:$l(tDate)=4 tDate=$e($zd($h,3)-1700)_tDate_""01""	// tDate is YYMM, add current century and Jan 1")
		$$$GENERATE($c(9,9)_"set:$l(tDate)=5 tDate=tDate_""01""			// tDate is CYYMM, add Jan 01")
		$$$GENERATE($c(9)_"}")
			#; Checks Input for Invalid Format
			#; Expects FILEMAN format TimeStamp (CYYMMDD.HHMMSS)
			#; Allows for TimeStampS where DATE is exact, but TIME is optional (i.e. S %DT="ETX" in Data Dictionary)
		$$$GENERATE($c(9)_"QUIT:$l(tDate)'=7 """"")
			#; Handle invalid system DATE Range
			#; If DATE earlier than January 1, 1841, set DATE to January 1, 1841
		$$$GENERATE($c(9)_"set:tDate<1401231 tDate=1401231					// If date is earlier than Jan 1, 1841, set date to Jane 1, 1841")
			#; Replace invalid MONTH value in FILEMAN format DATE with "01" or "12"
	 	$$$GENERATE($c(9)_"set tMonth=$e(tDate,4,5)")
	 	$$$GENERATE($c(9)_"set:tMonth=""00"" $e(tDate,4,5)=""01"",tMonth=""01"" set:tMonth>12 $e(tDate,4,5)=""12"",tMonth=12	// Handle invalid months")
			#; Replace invalid DAY value in FILEMAN format DATE with "01" or Max-Month-Date (Feb handled below)
		$$$GENERATE($c(9)_"set tDay=$e(tDate,6,7)						// make sure day is valid")
		$$$GENERATE($c(9)_"set:tDay=""00"" $e(tDate,6,7)=""01""")
		$$$GENERATE($c(9)_"if $case(tMonth,""04"":1,""06"":1,""09"":1,""11"":1,:0),tDay>30 { set tDay=30,$e(tDate,6,7)=30 }")
		$$$GENERATE($c(9)_"elseif tMonth=""02"",tDay>28 {")
				#; Convert FILEMAN format Input Arg1(CYYMMDD) to 4 digit year
	 	$$$GENERATE($c(9,9)_"set tYear=$e(tDate,1)+17_$e(tDate,2,3)")
	 			#; Validate Leap Year
			 		#; Return ODBC format TIMESTAMP (YYYY-MM-DD HH:MM:SS)
		$$$GENERATE($c(9,9)_"if ((tYear#4=0)&&((tYear#100'=0)||(tYear#400=0))) { set:tDay>29 $e(tDate,6,7)=""29"" }")
		 		#; Not a Valid Leap Year, Correct DAY to "28"
		$$$GENERATE($c(9,9)_"else { set $e(tDate,6,7)=""28"" }")
		$$$GENERATE($c(9)_"}")
		$$$GENERATE($c(9)_"elseif tDay>31 { set tDay=31,$e(tDate,6,7)=31 }")
	}
 		#; Return ODBC format DATE (YYYY-MM-DD)
		#; $zd YEAROPT parameter "4" forces a 4-digit year for all DATES
	$$$GENERATE($c(9)_"set v=$zdh(tDate+17000000,8,,,,,,,"""") QUIT:v="""" """"")
	$$$GENERATE($c(9)_"QUIT $zd(v,,,4)")
}

/// Converts FILEMAN format DATE (CYYMMDD) to ODBC format DATE (YYYY-MM-DD).
/// Can handle data on disk in the Fileman TimeStamp format.
ClassMethod LogicalToOdbc(Arg1 As %Library.FilemanDate) As %Library.String [ CodeMode = generator ]
{
 		#; Checks Input for Null Value
	$$$GENERATE($c(9)_"QUIT:Arg1="""" """"")
		#; Pad TIME value with Zeros because FILEMAN TimeStampS do not store trailing zeros on disk
	if %parameter("STRICTDATA")=1 {
		$$$GENERATE($c(9)_"set tDate=$p(Arg1,""."") QUIT:$l(tDate)'=7 """"")
	}
	else {
		$$$GENERATE($c(9)_"set tDate=$p(Arg1,""."")")
			#; Checks for partial date
		$$$GENERATE($c(9)_"if $l(tDate)<7 {")
		$$$GENERATE($c(9,9)_"set:$l(tDate)=2 tDate=$e($zd($h,3)-1700)_tDate_""0101"" 	// tDate is current 2 year date, add current century and Jan 01")
		$$$GENERATE($c(9,9)_"set:$l(tDate)=3 tDate=tDate_""0101""			// tDate is CYY, add Jan 01")
		$$$GENERATE($c(9,9)_"set:$l(tDate)=4 tDate=$e($zd($h,3)-1700)_tDate_""01""	// tDate is YYMM, add current century and Jan 1")
		$$$GENERATE($c(9,9)_"set:$l(tDate)=5 tDate=tDate_""01""			// tDate is CYYMM, add Jan 01")
		$$$GENERATE($c(9)_"}")
			#; Checks Input for Invalid Format
			#; Expects FILEMAN format TimeStamp (CYYMMDD.HHMMSS)
			#; Allows for TimeStampS where DATE is exact, but TIME is optional (i.e. S %DT="ETX" in Data Dictionary)
		$$$GENERATE($c(9)_"QUIT:$l(tDate)'=7 """"")
			#; Handle invalid system DATE Range
			#; If DATE earlier than January 1, 1841, set DATE to January 1, 1841
		$$$GENERATE($c(9)_"set:tDate<1401231 tDate=1401231					// If date is earlier than Jan 1, 1841, set date to Jane 1, 1841")
			#; Replace invalid MONTH value in FILEMAN format DATE with "01" or "12"
 		$$$GENERATE($c(9)_"set tMonth=$e(tDate,4,5)")
		$$$GENERATE($c(9)_"set:tMonth=""00"" $e(tDate,4,5)=""01"",tMonth=""01"" set:tMonth>12 $e(tDate,4,5)=""12"",tMonth=12	// Handle invalid months")
			#; Replace invalid DAY value in FILEMAN format DATE with "01" or Max-Month-Date (Feb handled below)
		$$$GENERATE($c(9)_"set tDay=$e(tDate,6,7)						// make sure day is valid")
		$$$GENERATE($c(9)_"set:tDay=""00"" $e(tDate,6,7)=""01""")
		$$$GENERATE($c(9)_"if $case(tMonth,""04"":1,""06"":1,""09"":1,""11"":1,:0),tDay>30 { set tDay=30,$e(tDate,6,7)=30 }")
		$$$GENERATE($c(9)_"elseif tMonth=""02"",tDay>28 {")
				#; Convert FILEMAN format Input Arg1(CYYMMDD) to 4 digit year
 		$$$GENERATE($c(9,9)_"set tYear=$e(tDate,1)+17_$e(tDate,2,3)")
	 			#; Validate Leap Year
			 		#; Return ODBC format TIMESTAMP (YYYY-MM-DD HH:MM:SS)
 		$$$GENERATE($c(9,9)_"if ((tYear#4=0)&&((tYear#100'=0)||(tYear#400=0))) { set:tDay>29 $e(tDate,6,7)=""29"" }")
		 		#; Not a Valid Leap Year, Correct DAY to "28"
		$$$GENERATE($c(9,9)_"else { set $e(tDate,6,7)=""28"" }")
		$$$GENERATE($c(9)_"}")
		$$$GENERATE($c(9)_"elseif tDay>31 { set tDay=31,$e(tDate,6,7)=31 }")
	}
 		#; Return ODBC format TIMESTAMP (YYYY-MM-DD HH:MM:SS) for Non-Leap Years
		 	#; $zd YEAROPT parameter "4" forces a 4-digit year for all DATES
	$$$GENERATE($c(9)_"set v=$zdh(tDate+17000000,8,,,,,,,"""") QUIT:v="""" """"") 
	$$$GENERATE($c(9)_"QUIT $zd(v,3,,4)")
}

/// Converts ODBC format DATE (YYYY-MM-DD) to FILEMAN format DATE (CYYMMDD).
ClassMethod OdbcToLogical(Arg1 As %Library.String) As %Library.FilemanDate
{
		#; Version 2003-09-19 DCN
		#; Checks Input for Null Value
	quit:Arg1="" ""
		#;  Allow FileMan Date format (CYYMMDD) or FIleMan Datetime (CYYMMDD.HHMMSS) to be input here.  This allows users typing in values as input to an ODBC query to enter FileManDate
		#;  values rather than YYYY-MM-DD ODBC values.  The VA requested this ability because they like to use FMDate values as input from ODBC/Display
		#;  If the input value is a 7 digit number, assume it is a FileMan Date logical value already.
	QUIT:Arg1?7N Arg1
		#;  If the input value is a 7.6 digit value, assume it is a FileMan DateTime logical value already.
	QUIT:Arg1?7N1"."6N $p(Arg1,".")
		#; Checks Input for Invalid Format.
		#; Expects ODBC format DATE (YYYY-MM-DD)
	if Arg1'?4N1"-"2N1"-"2N||( $zdh(Arg1,3,,4,,,,,"")="") s %msg="Invalid ODBC Date value ('"_Arg1_"') passed to %FilemanDate.OdbcToLogical method" ztrap "FMD1"
		#; Returns FILEMAN format DATE (CYYMMDD)
	quit $zd($zdh(Arg1,3,,4),8)-17000000
}

/// Converts %Date format DATE (+$H) to FILEMAN format DATE (CYYMMDD).
ClassMethod DateToLogical(%val As %Library.String) As %Library.FilemanDate [ CodeMode = expression, ServerOnly = 1 ]
{
$s(%val="":"",1:$zd(%val,8)-17000000)
}

/// Converts %TimeStamp format TIMESTAMP (YYYY-MM-DD HH:MM:SS) to FILEMAN format DATE (CYYMMDD).
ClassMethod TimeStampToLogical(%val As %Library.TimeStamp) As %Library.FilemanDate [ CodeMode = expression, ServerOnly = 1 ]
{
$s(%val="":"",1:$zd($zdh(%val,3,,4),8)-17000000)
}

/// Converts FILEMAN format DATE (CYYMMDD) to %Date format DATE (+$H) 
ClassMethod LogicalToDate(%val As %Library.FilemanDate) As %Library.Date [ CodeMode = generator, ServerOnly = 1 ]
{
		#; Strip off TIME if present
			#; Handle invalid system DATE Range
			#; If DATE earlier than January 1, 1841, set DATE to January 1, 1841
				#; Replace invalid "00" MONTH value in FILEMAN format DATE with "01"
					#; Replace invalid "00" DAY value in FILEMAN format DATE with "01"
	$$$GENERATE($c(9)_"set:$l(%val)>7 %val=$p(%val,""."",1)")
	if %parameter("STRICTDATA")'=1 {
		$$$GENERATE($c(9)_"set:$e(%val,1,7)<1401231 $e(%val,1,7)=1401231")
		$$$GENERATE($c(9)_"set:$e(%val,4,5)=""00"" $e(%val,4,5)=""01""")
		$$$GENERATE($c(9)_"set:$e(%val,6,7)=""00"" $e(%val,6,7)=""01""")
	}
	$$$GENERATE($c(9)_"QUIT $s(%val="""":"""",1:$zdh(%val+17000000,8))")
}

}
