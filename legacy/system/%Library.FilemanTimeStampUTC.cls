/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Custom TimeStamp datatype designed to handle internal FileMan UNIVERSAL TIME datatype (CYYMMDD.HHMMSSZZZ).
/// This data type projects proper VARCHAR/STRING meta data to DISPLAY and ODBC Client software.  
/// The conversion methods of this datatype assume a ful FIleMan 22.2 run-time environment is installed, and that the DUZ(2) variable is defined 
/// and DUZ(2) references an INSTITUTION that includes defined COUNTRY and LOCATION TIMEZONE values.
Class %Library.FilemanTimeStampUTC [ ClassType = datatype, ClientDataType = VARCHAR, OdbcType = VARCHAR, SqlCategory = STRING, System = 2 ]
{

Parameter XSDTYPE = "string";

Parameter JSONTYPE = "string";

Parameter COLLATION = "STRING";

ClassMethod XSDToLogical(%val As %String) As %FilemanTimeStamp [ CodeMode = generator ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		$$$GENERATE(" Set len=$length(%val)")
		$$$GENERATE(" If $extract(%val,len)=""Z"" { Set %val=$extract(%val,1,len-1) } ElseIf $case($extract(%val,len-5),""+"":1,""-"":1,:0) { Set %val=$extract(%val,1,len-6) }")
		$$$GENERATE(" Quit:$get(%val)="""" """" Quit:$length(%val,""T"")'=2 """"")
		$$$GENERATE(" Set dt=$translate(%val,""T"",""@""), dt=##class(%FilemanTimeStamp).OdbcToLogical(dt)")
		$$$GENERATE(" Quit:'dt """" Quit dt")
	} 
	Else { Set %code=0 }
	RETURN $$$OK
}

/// Converts the %FilemanTimeStamp value to the canonical SOAP encoded value.
ClassMethod LogicalToXSD(%val As %FilemanTimeStamp) As %String [ CodeMode = generator, ProcedureBlock = 1 ]
{
	If ($$$defClassKeyGet(%class,$$$cCLASSclasstype)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$translate(##class(%FilemanTimeStamp).LogicalToOdbc(%val),""@"",""T"")"
	} Else {
		Set %code=0 
	}
	RETURN $$$OK
}

/// Checks for Invalid Format, expects FileMan UNIVERSAL TIME format (CYYMMDD.HHMMSSZZZ).
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ProcedureBlock = 0, ServerOnly = 0 ]
{
#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %code="$select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val))"
		RETURN $$$OK
	}
	$$$GENERATE($c(9)_"set Arg1=%val RETURN:Arg1="""" $$$OK")
	$$$GENERATE($c(9)_"set return=$$UTC^DIUTC(Arg1,,,,1)")
	$$$GENERATE($c(9)_"if +return=-1 { RETURN $$$ERROR($$$DatatypeValidationFailed,"""_%class_":"_%property_""",%val_"" (error: ""_$p(return,""^"",2)_"")"" ) }")
	$$$GENERATE($c(9)_"RETURN $$$OK")
	RETURN $$$OK
}

/// Converts FileMan UNIVERSAL TIME internal format (CYYMMDD.HHMMSSZZZ) to external UNIVERSAL TIME format (MON DD, YYYY@HH:MM:SS (UTC=-HH:SS)).
ClassMethod LogicalToDisplay(Arg1 As %Library.FilemanTimeStampUTC = "") As %Library.String [ CodeMode = generator, ProcedureBlock = 0, PublicList = DUZ ]
{
 		#; Checks Input for Null Value
	$$$GENERATE($c(9)_"RETURN:Arg1="""" """"")
	$$$GENERATE($c(9)_"set return=$$UTC^DIUTC(Arg1,,,,1)")
		#; If Logical value is invalid, or user's DUZ(2) is not defined or valid, UTY^DIUTC will return an error, for this case return ""
	$$$GENERATE($c(9)_"if $p(return,""^"",1)=-1 { RETURN """" }")
	$$$GENERATE($c(9)_"RETURN $p(return,""^"",2)")
}

/// Converts FileMan UNIVERSAL TIME internal format (CYYMMDD.HHMMSSZZZ) to external UNIVERSAL TIME format (AUG 16, 2016@20:00:16 (UTC-04:00))
ClassMethod LogicalToOdbc(Arg1 As %Library.FilemanTimeStampUTC) As %Library.String [ CodeMode = generator, ProcedureBlock = 0 ]
{
 		#; Checks Input for Null Value
	$$$GENERATE($c(9)_"RETURN:Arg1="""" """"")
	$$$GENERATE($c(9)_"set return=$$UTC^DIUTC(Arg1,,,,1)")
		#; If Logical value is invalid, or user's DUZ(2) is not defined or valid, UTY^DIUTC will return an error, for this case return ""
	$$$GENERATE($c(9)_"if $p(return,""^"",1)=-1 { RETURN """" }")
	$$$GENERATE($c(9)_"RETURN $p(return,""^"",2)")
}

/// Converts FileMan external datetime to FileMan UNIVERSAL TIME internal format (CYYMMDD.HHMMSSZZZ)
/// Input can be standard internal or external VA FileMan DateTime (e.g., NOW, T@12A). The Time portion of the input is required.
ClassMethod DisplayToLogical(Arg1 As %Library.String) As %Library.FilemanTimeStampUTC [ CodeMode = generator, ProcedureBlock = 0, ServerOnly = 0 ]
{
 		#; Checks Input for Null Value
	$$$GENERATE($c(9)_"RETURN:Arg1="""" """"")
	$$$GENERATE($c(9)_"set return=$$UTC^DIUTC(Arg1)")
		#; If Logical value is invalid, or user's DUZ(2) is not defined or valid, UTY^DIUTC will return an error, for this case return ""
	$$$GENERATE($c(9)_"if $p(return,""^"",1)=-1 { set %msg=""%FilemanTimeStampUTC DisplayToLogical() method, $$UTC^DIUTC(""""""_Arg1_"""""") returned '""_$p(return,""^"",2)_""', DUZ(2)=""_$g(DUZ(2),""<not defined>"") ztrap ""FMD1"" }")
	$$$GENERATE($c(9)_"RETURN return")
}

/// Converts FileMan external datetime to FileMan UNIVERSAL TIME internal format (CYYMMDD.HHMMSSZZZ)
/// Input can be standard internal or external VA FileMan DateTime (e.g., NOW, T@12A). The Time portion of the input is required.
ClassMethod OdbcToLogical(Arg1 As %Library.String) As %Library.FilemanTimeStampUTC [ CodeMode = generator, ProcedureBlock = 0 ]
{
 		#; Checks Input for Null Value
	$$$GENERATE($c(9)_"RETURN:Arg1="""" """"")
	$$$GENERATE($c(9)_"set return=$$UTC^DIUTC(Arg1)")
		#; If Logical value is invalid, or user's DUZ(2) is not defined or valid, UTY^DIUTC will return an error, for this case return ""
	$$$GENERATE($c(9)_"if $p(return,""^"",1)=-1 { set %msg=""%FilemanTimeStampUTC OdbcToLogical() method, $$UTC^DIUTC(""""""_Arg1_"""""") returned '""_$p(return,""^"",2)_""', DUZ(2)=""_$g(DUZ(2),""<not defined>"") ztrap ""FMD1"" }")
	$$$GENERATE($c(9)_"RETURN return")
}

}
