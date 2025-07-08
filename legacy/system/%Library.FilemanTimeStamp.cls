/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Custom TimeStamp datatype designed to handle internal FILEMAN format TimeStamp (CYYMMDD.HHMMSS).
/// This data type projects proper TIMESTAMP meta data to DISPLAY and ODBC Client software.  
/// It does not require any extra routines to function
Class %Library.FilemanTimeStamp [ ClassType = datatype, ClientDataType = FTIMESTAMP, OdbcType = TIMESTAMP, SqlCategory = FMTIMESTAMP, System = 2 ]
{

/// 1/0 flag which determines if the LogicalToFormat conversions will process imprecise logical FileMan Date values
/// Default setting is STRICTDATA=0
/// Parameter affects the generation of the LogicalToDisplay and LogicalToOdbc methods
/// When STRICTDATA=1, imprecise or invalid dates will not be changed to a valid FileMan Date value.
/// For example, if Logical FileMan Date value is 31110, when STRICTDATA=0 this will translate to 3111001 (Sept 01, 2011).
/// If STRICTDATA=1, this transformation will not take place and the invalid/imprecise Logical value will get an error when converted to Display or Odbc format.
Parameter STRICTDATA As BOOLEAN = 0;

Parameter XSDTYPE = "dateTime";

Parameter JSONTYPE = "string";

ClassMethod XSDToLogical(%val As %String) As %FilemanTimeStamp [ CodeMode = generator ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		$$$GENERATE(" Set len=$length(%val)")
		$$$GENERATE(" If $extract(%val,len)=""Z"" { Set %val=$extract(%val,1,len-1) } ElseIf $case($extract(%val,len-5),""+"":1,""-"":1,:0) { Set %val=$extract(%val,1,len-6) }")
		$$$GENERATE(" Quit:$get(%val)="""" """" Quit:$length(%val,""T"")'=2 """"")
		$$$GENERATE(" Set dt=$translate(%val,""T"","" ""), dt=##class(%FilemanTimeStamp).OdbcToLogical(dt)")
		$$$GENERATE(" Quit:'dt """" Quit dt")
	} 
	Else { Set %code=0 }
	Quit $$$OK
}

/// Converts the %FilemanTimeStamp value to the canonical SOAP encoded value.
ClassMethod LogicalToXSD(%val As %FilemanTimeStamp) As %String [ CodeMode = generator ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$translate(##class(%FilemanTimeStamp).LogicalToOdbc(%val),"" "",""T"")"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Converts DISPLAY format TIMESTAMP (MM/DD/YYYY HH:MM:SS) to FILEMAN format TimeStamp (CYYMMDD.HHMMSS).
ClassMethod DisplayToLogical(Arg1 As %Library.String) As %Library.FilemanTimeStamp [ ServerOnly = 0 ]
{
	 	#; Version 2003-09-19 DCN
		#; Check for Null Value
	quit:Arg1="" ""
		#;  Allow FileMan Date format (CYYMMDD) or FileManTimeStamp format (CYYMMDD.HHMMSS) to be input here.  This allows users typing in values as input to an DISPLAY query to enter FileManDate
		#;  values rather than MM/DD/YYYY [HH:MM:SS] DISPLAY values.  The VA requested this ability because they like to use FMDate values as input from ODBC/Display
		#;  If the input value is a 7[.6] digit number, assume it is a FileManTimeStamp logical value already.
	QUIT:Arg1?7N.1(1".".6N) +Arg1
		#; Check for Invalid Format
		#; Expects DISPLAY format TIMESTAMP (MM/DD/YYYY HH:MM:SS)
		#; But can handle DATE without TIME present
	if Arg1'?2N1"/"2N1"/"4N.1(1" "2N1":"2N1":"2N)||($zdh(Arg1,,,,,,,,"")="") s %msg="Invalid Display TimeStamp value ('"_Arg1_"') passed to %FilemanTimeStamp.DisplayToLogical method" ztrap "FMD1"
		#; Seperates DATE and TIME values
	set Date=$p(Arg1," ",1),Time=$p(Arg1," ",2)
		#; Return FILEMAN format TimeStamp (CYYMMDD) if TIME is not present
	quit:Time="" $zd($zdh(Date,,,4),8)-17000000
		#; Return FILEMAN format TimeStamp (CYYMMDD) if TIME is 00:00:00
	quit:Time="00:00:00" $zd($zdh(Date,,,4),8)-17000000
		#; Return FILEMAN format TimeStamp (CYYMMDD.HHMMSS) if TIME is present
		#; Converts TIME value from DISPLAY to FILEMAN format and strips trailing zeros
	set Time=$zstrip($zstrip(Time,"*",":"),">N",,"123456789")
	quit $zd($zdh(Date,,,4),8)-17000000_"."_Time
}

/// Checks for Invalid Format, expects FILEMAN format TimeStamp (CYYMMDD.HHMMSS).
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %code="$select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val))"
		Quit $$$OK
	}
	 $$$GENERATE(" s Arg1=%val quit:Arg1="""" $$$OK")
	 $$$GENERATE(" quit:Arg1'?7N.1(1""."".6N) $$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val)")
	 $$$GENERATE(" s:$l(Arg1)>7 Arg1=$p(Arg1,""."",1) s:$e(Arg1,4,5)=""00"" $e(Arg1,4,5)=""01"" s:$e(Arg1,6,7)=""00"" $e(Arg1,6,7)=""01""")
	 $$$GENERATE(" quit:$zdh(Arg1+17000000,8,,,,,,,"""")="""" $$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val)")
	 $$$GENERATE(" s Time=$p(%val,""."",2)_""000000"" q:Time="""" $$$OK")
	 $$$GENERATE(" if $e(Time,1,2)=24 q:+$e(Time,3,6)=0 1 q $$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val)")
	 $$$GENERATE(" set Time=$e(Time,1,2)_"":""_$e(Time,3,4)_"":""_$e(Time,5,6)")
	 $$$GENERATE(" q $s($zth(Time,,"""")'="""":$$$OK,1:$$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val))")
	 Quit $$$OK
}

/// Checks for Invalid Format, expects FILEMAN format TimeStamp (CYYMMDD.HHMMSS).
/// Converts FILEMAN format TimeStamp (CYYMMDD.HHMMSS) to DISPLAY format TIMESTAMP (DD/MM/YYYY HH:MM:SS).
ClassMethod LogicalToDisplay(Arg1 As %Library.FilemanTimeStamp = "") As %Library.String [ CodeMode = generator, ServerOnly = 0 ]
{
 		#; Checks Input for Null Value
	$$$GENERATE($c(9)_"QUIT:Arg1="""" """"")
		#; Pad TIME value with Zeros because FILEMAN TimeStamps do not store trailing zeros on disk
	if %parameter("STRICTDATA")=1 {
		$$$GENERATE($c(9)_"set tDate=$p(Arg1,"".""),tTime=$p(Arg1,""."",2)_""000000"" QUIT:$l(tDate)'=7 """"")
		$$$GENERATE($c(9)_"set tTime=$e(tTime,1,2)_"":""_$e(tTime,3,4)_"":""_$e(tTime,5,6)")
	}
	else {
			#; Checks for partial date
		$$$GENERATE($c(9)_"set tDate=$p(Arg1,"".""),tTime=$p(Arg1,""."",2)_""000000""")
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
		$$$GENERATE($c(9)_"set:tDate<1401231 tDate=1401231")
			#; Replace invalid MONTH value in FILEMAN format DATE with "01" or "12"
 		$$$GENERATE($c(9)_"set tMonth=$e(tDate,4,5)")
		$$$GENERATE($c(9)_"set:tMonth=""00"" $e(tDate,4,5)=""01"",tMonth=""01"" set:tMonth>12 $e(tDate,4,5)=""12"",tMonth=12")
			#; Replace invalid DAY value in FILEMAN format DATE with "01" or Max-Month-Date (Feb handled below)
		$$$GENERATE($c(9)_"set tDay=$e(tDate,6,7)")
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
		$$$GENERATE($c(9)_"elseif tDay>31  { set tDay=31,$e(tDate,6,7)=31 }")
	
			#; Check for time stamp of > 23 hours, display it as 235959, Format TIME
		$$$GENERATE($c(9)_"if tTime'="""" {")
		$$$GENERATE($c(9,9)_"set:$e(tTime,1,2)>23 tTime=""235959""")
		$$$GENERATE($c(9,9)_"set:$e(tTime,3,4)>59 $e(tTime,3,4)=""59""")
		$$$GENERATE($c(9,9)_"set:$e(tTime,5,6)>59 $e(tTime,5,6)=""59""")
		$$$GENERATE($c(9,9)_"set tTime=$e(tTime,1,2)_"":""_$e(tTime,3,4)_"":""_$e(tTime,5,6)")
		$$$GENERATE($c(9)_"}")
	}
	$$$GENERATE($c(9)_"if tTime'=""00:00:00"" set tTime=$zth(tTime,,"""") QUIT:tTime="""" """" set tTime=$zt(tTime,,,"""") QUIT:tTime="""" """" // Validate time, if bad, return """"")
	 	#; Return DISPLAY format TIMESTAMP (MM/DD/YYYY HH:MM:SS) for Non-Leap Years
	 			#; $zd YEAROPT parameter "4" forces a 4-digit year for all DATES
	$$$GENERATE($c(9)_"set v=$zdh(tDate+17000000,8,,,,,,,"""") QUIT:v="""" """"")
	$$$GENERATE($c(9)_"QUIT $zd(v,,,4)_"" ""_tTime")
}

/// Converts FILEMAN format TimeStamp (CYYMMDD.HHMMSS) to ODBC format TIMESTAMP (YYYY-MM-DD HH:MM:SS)
ClassMethod LogicalToOdbc(Arg1 As %Library.FilemanTimeStamp) As %Library.String [ CodeMode = generator ]
{
 		#; Checks Input for Null Value
	$$$GENERATE($c(9)_"QUIT:Arg1="""" """"")
		#; Pad TIME value with Zeros because FILEMAN TimeStamps do not store trailing zeros on disk
	if %parameter("STRICTDATA")=1 {
		$$$GENERATE($c(9)_"set tDate=$p(Arg1,"".""),tTime=$p(Arg1,""."",2)_""000000"" QUIT:$l(tDate)'=7 """"")
		$$$GENERATE($c(9)_"set tTime=$e(tTime,1,2)_"":""_$e(tTime,3,4)_"":""_$e(tTime,5,6)")
	}
	else {
			#; Checks for partial date
		$$$GENERATE($c(9)_"set tDate=$p(Arg1,"".""),tTime=$p(Arg1,""."",2)_""000000""")
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
		$$$GENERATE($c(9)_"set:tDate<1401231 tDate=1401231")
			#; Replace invalid MONTH value in FILEMAN format DATE with "01" or "12"
 		$$$GENERATE($c(9)_"set tMonth=$e(tDate,4,5)")
		$$$GENERATE($c(9)_"set:tMonth=""00"" $e(tDate,4,5)=""01"",tMonth=""01"" set:tMonth>12 $e(tDate,4,5)=""12"",tMonth=12")
			#; Replace invalid DAY value in FILEMAN format DATE with "01" or Max-Month-Date (Feb handled below)
		$$$GENERATE($c(9)_"set tDay=$e(tDate,6,7)")
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
		$$$GENERATE($c(9)_"elseif tDay>31  { set tDay=31,$e(tDate,6,7)=31 }")
	
			#; Check for time stamp of > 23 hours, display it as 235959, Format TIME
		$$$GENERATE($c(9)_"if tTime'="""" {")
		$$$GENERATE($c(9,9)_"set:$e(tTime,1,2)>23 tTime=""235959""")
		$$$GENERATE($c(9,9)_"set:$e(tTime,3,4)>59 $e(tTime,3,4)=""59""")
		$$$GENERATE($c(9,9)_"set:$e(tTime,5,6)>59 $e(tTime,5,6)=""59""")
		$$$GENERATE($c(9,9)_"set tTime=$e(tTime,1,2)_"":""_$e(tTime,3,4)_"":""_$e(tTime,5,6)")
		$$$GENERATE($c(9)_"}")
	}
		#; Validate time
	$$$GENERATE($c(9)_"if tTime'=""00:00:00"" set tTime=$zth(tTime,,"""") QUIT:tTime="""" """" set tTime=$zt(tTime,,,"""") QUIT:tTime="""" """" // Validate time, if bad, return """"")
	 	#; Return ODBC format TIMESTAMP (YYYY-MM-DD HH:MM:SS)
	$$$GENERATE($c(9)_"set v=$zdh(tDate+17000000,8,,,,,,,"""") QUIT:v="""" """"")
	$$$GENERATE($c(9)_"QUIT $zd(v,3)_"" ""_tTime")
}

/// Converts ODBC format TIMESTAMP (YYYY-MM-DD HH:MM:SS) to FILEMAN format TimeStamp (CYYMMDD.HHMMSS)
ClassMethod OdbcToLogical(Arg1 As %Library.String) As %Library.FilemanTimeStamp
{
 	#; Version 2003-09-19 DCN
 	#; Checks for Null Value
 quit:Arg1="" ""
		#;  Allow FileMan Date format (CYYMMDD) or FileManTimeStamp format (CYYMMDD.HHMMSS) to be input here.  This allows users typing in values as input to an DISPLAY query to enter FileManDate
		#;  values rather than MM/DD/YYYY [HH:MM:SS] DISPLAY values.  The VA requested this ability because they like to use FMDate values as input from ODBC/Display
		#;  If the input value is a 7[.6] digit number, assume it is a FileManTimeStamp logical value already.
 QUIT:Arg1?7N.1(1".".6N) +Arg1
 	#; Checks for Invalid Format
 	#; Expects ODBC format TIMESTAMP (YYYY-MM-DD HH:MM:SS)
 	#; Can handle DATE without TIME present
 if $e(Arg1,1,19)'?4N1"-"2N1"-"2N.1(1" "2N1":"2N1":"2N) s %msg="Invalid ODBC TimeStamp value ('"_Arg1_"') passed to %FilemanTimeStamp.OdbcToLogical method" ztrap "FMD1"
 	#; Seperates DATE and TIME values
 set Date=$p(Arg1," ",1) if $zdh(Date,3,,4,,,,,"")="" s %msg="Invalid ODBC TimeStamp value ('"_Arg1_"') passed to %FilemanTimeStamp.OdbcToLogical method" ztrap "FMD1"
 set Time=$p(Arg1," ",2)
 	#; Returns FILEMAN format TimeStamp (CYYMMDD) if no TIME is present
 quit:Time="" $zd($zdh(Date,3,,4),8)-17000000
 	#; Returns FILEMAN format TimeStamp (CYYMMDD) if TIME is 00:00:00
 quit:Time="00:00:00" $zd($zdh(Date,3,,4),8)-17000000
	#; Returns FILEMAN format TimeStamp (CYYMMDD.HHMMSS) if TIME is valid
	#; Converts TIME value from ODBC to FILEMAN format and strips trailing zeros
 set Time=$p(Time,".") if $zth(Time,,"")="" s %msg="Invalid ODBC TimeStamp value ('"_Arg1_"') passed to %FilemanTimeStamp.OdbcToLogical method" ztrap "FMD1"
 set Time=$zstrip($zstrip(Time,"*",":"),">N",,"123456789")
 quit $zd($zdh(Date,3,,4),8)-17000000_"."_Time
}

/// Converts Storage FileMan TIMESTAMP (CYYMMDD.HHMMSS) with possible trailing 0's to a Logical canonical value without trailing 0's
/// This is needed so that values with trailing zeros and without can all be compared with ]] properly (they will all be treated as numeric values).
/// LogicalTo**** methods will handle the missing trailing zeros to produce the correct time
ClassMethod StorageToLogical(%val As %Library.String) As %Library.FilemanTimeStamp
{
	Quit $s(%val:+%val,1:%val)
}

}
