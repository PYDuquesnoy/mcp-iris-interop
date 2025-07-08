/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Custom Time datatype designed to handle internal FILEMAN format Time (HHMMSS).
///   A field defined as a TIME data type can accept many of the date/time entries, but only stores the TIME portion. 
///   Example:  External: 15:09:43 
///             Internal: 150943 
/// It does not require any extra routines to function
/// 
Class %Library.FilemanTime [ ClassType = datatype, ClientDataType = TIME, OdbcType = TIME, SqlCategory = STRING ]
{

/// The default collation value used for this data type.
Parameter COLLATION = "STRING";

Parameter XSDTYPE = "Time";

Parameter JSONTYPE = "string";

ClassMethod XSDToLogical(%val As %String) As %Library.FilemanTime [ CodeMode = generator ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		$$$GENERATE(" Set len=$length(%val)")
		$$$GENERATE(" If $extract(%val,len)=""Z"" { Set %val=$extract(%val,1,len-1) } ElseIf $case($extract(%val,len-5),""+"":1,""-"":1,:0) { Set %val=$extract(%val,1,len-6) }")
		$$$GENERATE(" Quit:$get(%val)="""" """" Quit:$length(%val,""T"")'=2 """"")
		$$$GENERATE(" Set dt=$translate(%val,""T"","" ""), dt=##class(%FilemanTime).OdbcToLogical(dt)")
		$$$GENERATE(" Quit:'dt """" Quit dt")
	} 
	Else { Set %code=0 }
	Quit $$$OK
}

/// Converts the %FilemanTime value to the canonical SOAP encoded value.
ClassMethod LogicalToXSD(%val As %Library.FilemanTime) As %String [ CodeMode = generator ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$translate(##class(%FilemanTime).LogicalToOdbc(%val),"" "",""T"")"
	} Else {
		Set %code=0 
	}
	Quit $$$OK
}

/// Checks for Invalid Format, expects FILEMAN format Time (HHMMSS, 00:00:01 through 24:00:00).
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %code="$select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val))"
		Quit $$$OK
	}
	$$$GENERATE($c(9)_"set Arg1=%val RETURN:$case(Arg1,"""":1,""240000"":1,:0) $$$OK")  // In FileMan, 240000 is midnight
	$$$GENERATE($c(9)_"RETURN:Arg1'?6N $$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val)")  // must be 6 numbers
	$$$GENERATE($c(9)_"RETURN $s($zth($e(Arg1,1,2)_"":""_$e(Arg1,3,4)_"":""_$e(Arg1,5,6),,"""")'="""":$$$OK,1:$$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val))")   // Make sure it is a valid time
	RETURN $$$OK
}

/// Converts FILEMAN format TimeStamp (HHMMSS) to DISPLAY format TIME HH:MM:SS).
ClassMethod LogicalToDisplay(Arg1 As %Library.FilemanTime = "") As %Library.String [ CodeMode = generator, ServerOnly = 0 ]
{
 		#; Checks Input for Null Value
	$$$GENERATE($c(9)_"RETURN:Arg1="""" """"")
	$$$GENERATE($c(9)_"RETURN:Arg1=""240000"" ""00:00:00""")
	$$$GENERATE($c(9)_"RETURN $ztime($ztimeh($e(Arg1,1,2)_"":""_$e(Arg1,3,4)_"":""_$e(Arg1,5,6)))")
}

/// Converts FILEMAN format Time (HHMMSS) to ODBC format TIME (HH:MM:SS)
ClassMethod LogicalToOdbc(Arg1 As %Library.FilemanTime) As %Library.String [ CodeMode = generator ]
{
 		#; Checks Input for Null Value
	$$$GENERATE($c(9)_"RETURN:Arg1="""" """"")
	$$$GENERATE($c(9)_"RETURN:Arg1=""240000"" ""00:00:00""")
	$$$GENERATE($c(9)_"RETURN $ztime($ztimeh($e(Arg1,1,2)_"":""_$e(Arg1,3,4)_"":""_$e(Arg1,5,6),1),1)")
}

/// Converts DISPLAY format TIME ([MM/DD/YYYY ]HH:MM:SS) to FILEMAN format Time (HHMMSS).
ClassMethod DisplayToLogical(Arg1 As %Library.String) As %Library.FilemanTime [ ServerOnly = 0 ]
{
		#; Check for Null Value
	RETURN:Arg1="" ""
		#;  Allow FileManTimeStamp format (CYYMMDD.HHMMSS) to be input here.  This allows users typing in values as input to an DISPLAY query to enter FileManDate
		#;  values rather than [MM/DD/YYYY ]HH:MM:SS DISPLAY values.  The VA requested this ability because they like to use FMDate values as input from ODBC/Display
		#;  If the input value is a 7.6 digit number, assume it is a FileManTimeStamp logical value already.
	RETURN:Arg1?7N.1".".6N $p(Arg1,".",2)
	RETURN:Arg1?6N Arg1
		#; If there is a " " in the value, assume DATE TIME value and remove DATE
	set:Arg1[" " Arg1=$p(Arg1," ",2)
	RETURN:Arg1="24:00:00" "240000"
		#; check for ODBC TIME value
	if Arg1?2N1":"2N1":"2N {
		if $ztimeh(Arg1,1,"BAD")'="BAD" { RETURN $tr(Arg1,":","") }
	} else {   // check for default Display value
		if $ztimeh(Arg1,,"BAD")'="BAD" { RETURN $tr(Arg1,":","") }
	}
	set %msg="Invalid Display Time value ('"_Arg1_"') passed to %FilemanTime.DisplayToLogical method"
	ztrap "FMD1"
}

/// Converts ODBC format TIMESTAMP (YYYY-MM-DD HH:MM:SS) to FILEMAN format TimeStamp (CYYMMDD.HHMMSS)
ClassMethod OdbcToLogical(Arg1 As %Library.String) As %Library.FilemanTimeStamp
{
		#; Check for Null Value
	RETURN:Arg1="" ""
		#;  Allow FileManTimeStamp format (CYYMMDD.HHMMSS) or FileManTime format(HHMMSS) to be input here.  
		#;  This allows users typing in values as input to an DISPLAY query to enter FileManDate
		#;  values rather than [MM/DD/YYYY ]HH:MM:SS DISPLAY values.  The VA requested this ability because they like to use FMDate values as input from ODBC/Display
		#;  If the input value is a 7.6 digit number, assume it is a FileManTimeStamp logical value already.
	RETURN:Arg1?7N.1".".6N $p(Arg1,".",2)
	RETURN:Arg1?6N Arg1
		#; If there is a " " in the value, assume DATE TIME value and remove DATE
	set:Arg1[" " Arg1=$p(Arg1," ",2)
	RETURN:Arg1="24:00:00" "240000"
		#; check for ODBC TIME value
	if Arg1?2N1":"2N1":"2N {
		if $ztimeh(Arg1,1,"BAD")'="BAD" { RETURN $tr(Arg1,":","") }
	}
	set %msg="Invalid Display Time value ('"_Arg1_"') passed to %FilemanTime.OdbcToLogical method"
	ztrap "FMD1"
}

}
