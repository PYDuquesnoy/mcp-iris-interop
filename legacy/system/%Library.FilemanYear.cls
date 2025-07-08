/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Custom DATE data type designed to convert FILEMAN format YEAR fields.
/// 	A field defined as a YEAR data type can accept many of the date entries, but only stores the YEAR portion. 
/// 	Example: External: 2016 
///              Internal: 3160000 
/// 
Class %Library.FilemanYear [ ClassType = datatype, ClientDataType = VARCHAR, OdbcType = VARCHAR, SqlCategory = STRING, System = 2 ]
{

Parameter XSDTYPE = "string";

Parameter JSONTYPE = "string";

Parameter COLLATION = "STRING";

ClassMethod XSDToLogical(%val As %String) As %FilemanYear [ CodeMode = generator ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		$$$GENERATE("	Set len=$length(%val)")
		$$$GENERATE("	If len'=10 { If $extract(%val,len)=""Z"" { Set %val=$extract(%val,1,len-1) } ElseIf $case($extract(%val,len-5),""+"":1,""-"":1,:0) { Set %val=$extract(%val,1,len-6) } }")
		$$$GENERATE("	RETURN ##class(%FilemanDate).OdbcToLogical(%val)")
	}
	Else { Set %code=0 }
	Quit $$$OK
}

/// Converts the %FilemanYear value to the canonical SOAP encoded value.
ClassMethod LogicalToXSD(%val As %FilemanYear) As %String [ CodeMode = generator ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(%val="""":"""",1:##class(%FilemanYear).LogicalToOdbc(%val))"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

ClassMethod JSONToLogical(%val As %String) As %FilemanYear [ CodeMode = generator ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(%val="""":"""",1:##class(%FilemanYear).LogicalToOdbc(%val))"

	} Else {
		Set %code=0
	}
	Quit $$$OK
}

/// Converts the logical %FilemanYear value to the JSON string value.
ClassMethod LogicalToJSON(%val As %FilemanYear) As %String [ CodeMode = generator ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(%val="""":"""",1:##class(%FilemanYear).LogicalToOdbc(%val))"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Checks for Invalid format, expects FILEMAN format YEAR (CYY0000).
/// Can handle data on disk in the Fileman TimeStamp format.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %code="$select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val))"
		Quit $$$OK
	}
	 $$$GENERATE($c(9)_"set Arg1=%val RETURN:Arg1="""" $$$OK RETURN:Arg1'?7N.1(1""."".6N) $$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val)")
	 $$$GENERATE($c(9)_"set:$l(Arg1)>7 Arg1=$p(Arg1,""."",1) set:$e(Arg1,4,5)=""00"" $e(Arg1,4,5)=""01"" set:$e(Arg1,6,7)=""00"" $e(Arg1,6,7)=""01""")
	 $$$GENERATE($c(9)_"RETURN $s($zdh(Arg1+17000000,8,,,,,,,"""")'="""":$$$OK,1:$$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val))")
	 RETURN $$$OK
}

/// Converts FILEMAN format YEAR (CYY0000) to DISPLAY format YEAR (YYYY).
/// Can handle data on disk in the Fileman TimeStamp format.
ClassMethod LogicalToDisplay(Arg1 As %Library.FilemanYear = "") As %Library.String [ CodeMode = generator, ServerOnly = 0 ]
{
 		#; Checks Input for Null Value
 	$$$GENERATE($c(9)_"RETURN:Arg1="""" """" RETURN ($e(Arg1)+17)_$e(Arg1,2,3)")
}

/// Converts FILEMAN format YEAR (CYY0000) to ODBC format YEAR (YYYY).
/// Can handle data on disk in the Fileman TimeStamp format.
ClassMethod LogicalToOdbc(Arg1 As %Library.FilemanYear = "") As %Library.String [ CodeMode = generator ]
{
 		#; Checks Input for Null Value
 	$$$GENERATE($c(9)_"RETURN:Arg1="""" """" RETURN ($e(Arg1)+17)_$e(Arg1,2,3)")
}

/// Converts DISPLAY format DATE (DD/MM/YYYY) to FILEMAN format YEAR (CYY0000).
ClassMethod DisplayToLogical(Arg1 As %Library.String) As %Library.FilemanYear [ ServerOnly = 0 ]
{
		#; Version 2003-09-19 DCN
		#; Checks Input for Null value
	RETURN:Arg1="" ""
		#;  Allow FileMan Year format (YYYY), FileMan Date format (CYYMMDD) or FileMan Datetime (CYYMMDD.HHMMSS) to be input here.
	if Arg1?4N { RETURN ($e(Arg1,1,2)-17)_$e(Arg1,3,4)_"0000" }
		#;  Allow FileMan Date format (CYYMMDD) or FileMan Datetime (CYYMMDD.HHMMSS) to be input here.  This allows users typing in values as input to an DISPLAY query to enter FileManDate
		#;  values rather than MM/DD/YYYY DISPLAY values.  The VA requested this ability because they like to use FMDate values as input from ODBC/Display
		#;  If the input value is a 7 digit number, assume it is a FileMan Date logical value already.
	RETURN:Arg1?7N Arg1
		#;  If the input value is a 7 digit number, assume it is a FileMan Date logical value already.
		#;  If the input value is a 7.6 digit value, assume it is a FileMan DateTime logical value already.
	if Arg1?7N || (Arg1?7N1"."6N) { RETURN $e(Arg1,1,3)_"0000" }
		#; Checks Input for Invalid Format.
		#; Expects ODBC format DATE (YYYY-MM-DD)
	if Arg1'?4N1"-"2N1"-"2N||( $zdh(Arg1,3,,4,,,,,"")="") { set %msg="Invalid ODBC Date value ('"_Arg1_"') passed to %FilemanYear.OdbcToLogical method" ztrap "FMD1" }
		#; Returns FILEMAN format YEAR (CYY0000)
	RETURN ($e(Arg1,1,2)-17)_$e(Arg1,3,4)_"0000"
}

/// Converts ODBC format DATE (YYYY-MM-DD) to FILEMAN format YEAR (CYY0000).
ClassMethod OdbcToLogical(Arg1 As %Library.String = "") As %Library.FilemanDate
{
		#; Checks Input for Null Value
	RETURN:Arg1="" ""
		#;  Allow FielMan Year format (YYYY), FileMan Date format (CYYMMDD) or FileMan Datetime (CYYMMDD.HHMMSS) to be input here.  This allows users typing in values as input to an ODBC query to enter FileManDate
		#;  values rather than YYYY-MM-DD ODBC values.  The VA requested this ability because they like to use FMDate values as input from ODBC/Display
		#;  If the input value is a 4 digit number, assume it is a YYYY year value.
	if Arg1?4N { RETURN ($e(Arg1,1,2)-17)_$e(Arg1,3,4)_"0000" }
		#;  If the input value is a 7 digit number, assume it is a FileMan Date logical value already.
		#;  If the input value is a 7.6 digit value, assume it is a FileMan DateTime logical value already.
	if Arg1?7N || (Arg1?7N1"."6N) { RETURN $e(Arg1,1,3)_"0000" }
		#; Checks Input for Invalid Format.
		#; Expects ODBC format DATE (YYYY-MM-DD)
	if Arg1'?4N1"-"2N1"-"2N||( $zdh(Arg1,3,,4,,,,,"")="") { set %msg="Invalid ODBC Date value ('"_Arg1_"') passed to %FilemanYear.OdbcToLogical method" ztrap "FMD1" }
		#; Returns FILEMAN format YEAR (CYY0000)
	RETURN ($e(Arg1,1,2)-17)_$e(Arg1,3,4)_"0000"
}

/// Converts %Date format DATE (+$H) to FILEMAN format YEAR (CYY0000).
ClassMethod DateToLogical(%val As %Library.String = "") As %Library.FilemanYear [ CodeMode = expression, ServerOnly = 1 ]
{
($e($s(%val="":"",1:$zd(%val,8)-17000000),1,3)_"0000")
}

/// Converts %TimeStamp format TIMESTAMP (YYYY-MM-DD HH:MM:SS) to FILEMAN format YEAR (CYY0000).
ClassMethod TimeStampToLogical(%val As %Library.TimeStamp = "") As %Library.FilemanYear [ CodeMode = expression, ServerOnly = 1 ]
{
($e($s(%val="":"",1:$zd($zdh(%val,3,,4),8)-17000000),1,3)_"0000")
}

/// Converts FILEMAN format YEAR (CYY0000) to %Date format DATE (+$H) 
ClassMethod LogicalToDate(%val As %Library.FilemanDate) As %Library.Date [ CodeMode = generator, ServerOnly = 1 ]
{
		#; Strip off TIME if present
			#; Handle invalid system DATE Range
			#; If DATE earlier than January 1, 1841, set DATE to January 1, 1841
				#; Replace invalid "00" MONTH value in FILEMAN format DATE with "01"
					#; Replace invalid "00" DAY value in FILEMAN format DATE with "01"
	$$$GENERATE($c(9)_"set:$l(%val)>7 %val=$p(%val,""."",1)")
	$$$GENERATE($c(9)_"set:$e(%val,1,7)<1401231 $e(%val,1,7)=1401231")
	$$$GENERATE($c(9)_"set:$e(%val,4,5)=""00"" $e(%val,4,5)=""01""")
	$$$GENERATE($c(9)_"set:$e(%val,6,7)=""00"" $e(%val,6,7)=""01""")
	$$$GENERATE($c(9)_"QUIT $s(%val="""":"""",1:$zdh(%val+17000000,8))")
}

}
