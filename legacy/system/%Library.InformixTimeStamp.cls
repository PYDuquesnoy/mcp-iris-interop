/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

IncludeGenerator %occUtility

/// The <b>%Library.InformixTimeStamp</b> data type class represents a time stamp value.
/// <p>The logical value of the <b>%Library.InformixTimeStamp</b> data type is in <code>YYYY-MM-DD HH:MM:SS.nnnnnnnnn</code> format.
Class %Library.InformixTimeStamp Extends %DataType [ ClientDataType = TIMESTAMP, OdbcType = TIMESTAMP, Not ProcedureBlock, SqlCategory = TIMESTAMP, System = 2 ]
{

/// XMLTIMEZONE specifies the handling of timezone part of the XML format dateTime.
/// "UTC" means convert to UTC on input.  "IGNORE means ignore the timezone.
Parameter XMLTIMEZONE [ Constraint = "IGNORE,UTC", Flags = ENUM ] = "UTC";

/// Declares the XSD type used when projecting XML Schemas.
Parameter XSDTYPE = "dateTime";

Parameter JSONTYPE = "string";

/// The %Library.InformixTimeStamp data type is composed of a contiguous sequence of fields that represents 
/// each component of time you want to record and uses the following syntax:
///      DATETIME largest_qualifier TO smallest_qualifier 
/// The largest_qualifier and smallest_qualifier can be any one of the fields:
/// 
/// 	Qualifier Field 	Valid Entries
/// 	YEAR			A year numbered from 1 to 9,999 (A.D.)
/// 	MONTH			A month numbered from 1 to 12
/// 	DAY			A day numbered from 1 to 31, as appropriate to the month
/// 	HOUR			An hour numbered from 0 (midnight) to 23
/// 	MINUTE			A minute numbered from 0 to 59
/// 	SECOND			A second numbered from 0 to 59
/// 	FRACTION		A decimal fraction of a second with up to 5 digits of precision. 
/// 				The default precision is 3 digits (a thousandth of a second). 
/// 				Other precisions are indicated explicitly by writing FRACTION(n), where n is the desired number of digits from 1 to 5. .
Parameter LARGEQUAL;

Parameter SMALLQUAL;

/// Converts the SOAP encoded input dateTime value into a %TimeStamp value.
ClassMethod XSDToLogical(%val As %String) As %TimeStamp [ CodeMode = generator, ServerOnly = 1 ]
{
	If ($$$getClassType(%class)=$$$cCLASSCLASSTYPEDATATYPE) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"XMLENABLED",$$$cPARAMdefault) || $$$comMemberKeyGet(%class,$$$cCLASSparameter,"%JSONENABLED",$$$cPARAMdefault) {
		If %parameter("XMLTIMEZONE")="IGNORE" {
			$$$GENERATE(" New len,dt")
		} Else {
			$$$GENERATE(" New len,dt,d,f,s,t,z")
		}
		$$$GENERATE(" If $length($get(%val),""T"")'=2 Quit """"")
		$$$GENERATE(" Set dt=$translate(%val,""T"","" "")")
		$$$GENERATE(" Set len=$length(%val)")
		$$$GENERATE(" If $extract(%val,len)=""Z"" {")
		$$$GENERATE("   Set dt=$extract(dt,1,len-1)")
		$$$GENERATE(" } ElseIf $case($extract(%val,len-5),""+"":1,""-"":1,:0) {")
		$$$GENERATE("   If $extract(%val,len-2)'="":"" Quit """"")
		$$$GENERATE("   Set dt=$extract(dt,1,len-6)")
		If %parameter("XMLTIMEZONE")'="IGNORE" {
			$$$GENERATE("   Set f=$piece(dt,""."",2) If f'="""" Set f="".""_f,dt=$piece(dt,""."")")
			$$$GENERATE("   Set t=$zdatetimeh(dt,3,1,,,,,,,"""") If t="""" Quit """"")
			$$$GENERATE("   Set d=$piece(t,"","")")
			$$$GENERATE("   Set s=$piece(t,"","",2)")
			$$$GENERATE("   Set z=($extract(%val,len-4,len-3)*60+$extract(%val,len-1,len))*60")
			$$$GENERATE("   If $extract(%val,len-5)=""-"" {")
			$$$GENERATE("     Set s=s+z")
			$$$GENERATE("     If s>=(24*60*60) Set d=d+1,s=s-(24*60*60)")
			$$$GENERATE("   } Else {")
			$$$GENERATE("     Set s=s-z")
			$$$GENERATE("     If s<0 Set d=d-1,s=s+(24*60*60)")
			$$$GENERATE("   }")
			$$$GENERATE("   Set dt=$zdatetime(d_"",""_s,3,1,0,,,,,,,"""")")
			$$$GENERATE("   Quit $select(dt="""":"""",1:dt_f)")
		}
		$$$GENERATE(" }")
		$$$GENERATE(" If $zdatetimeh(dt,3,1,,,,,,,"""")="""" Quit """"")
		$$$GENERATE(" Quit dt")
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

/// Transforms integer values into timestamp.
ClassMethod Normalize(%val As %RawString) As %TimeStamp [ CodeMode = expression, ServerOnly = 1 ]
{
$s(%val="":"",$zu(115,13)&&(%val=$c(0)):"",%val=(%val\1):$zd(%val,3,,,,,,,"error")_" 00:00:00",%val?1.2N1":"2N1":"2N.1(1"."1.N):$zd($h,3)_" "_%val,$l(%val)=10:%val_" 00:00:00",%val[".":$zstrip($zstrip(%val,">W","0 "),">","."),1:$zstrip(%val,">W"))
}

/// Tests if the logical value <var>%val</var>, which represents an Informix Timestamp
/// value in <code>YYYY-MM-DD HH:MM:SS[.nnnnn]</code> format, is valid.
/// Valid formats include:
///   - TimeStamp value in the format YYYY-MM-DD HH:MI:SS[.nnnnn]
///   - Integer value that represents +$Horolog, will be converted to the date portion of the Informix TimeStamp value
///   - Time value of the form HH:MM:SS[.nnnnn], will default the date portion of the Informix Timestamp to today's date
///   - Date value in the format YYYY-MM-DD, , will be converted to the date portion of the Informix TimeStamp value
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	#; If subclass has a IsValidDT then call this
	If %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$select(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DTFailure,%val))"
		Quit $$$OK
	}
	s %code=0
	$$$GENERATE($c(9)_"Quit:$zu(115,13)&&(%val=$c(0)) $$$OK")
	$$$GENERATE($c(9)_"Set val=%val")
	if %parameter("SMALLQUAL")="HOUR" {
		$$$GENERATE($c(9)_"if %val?.e2N Set %val=%val_"":00:00""")	// Add on 00:00 minutes and seconds
	}
	elseif %parameter("SMALLQUAL")="MINUTE" {
		$$$GENERATE($c(9)_"if %val?.e2N1"":""2N Set %val=%val_"":00""")	// Add on 00 seconds
	}
	$$$GENERATE($c(9)_"Set %val=$select(%val=(%val\1):$zd(%val,3,,,,,,,""error"")_"" 00:00:00"",%val?1.2N1"":""2N1"":""2N.1(1"".""1.N):$zd($h,3)_"" ""_%val,$length(%val)=10:%val_"" 00:00:00"",1:%val)")
	$$$GENERATE($c(9)_"Quit:($length(%val)<19||($zdth(%val,3,,,,,,,,"""")="""")) $$$ERROR($$$DTTimeStamp,val)")
	$$$GENERATE($c(9)_"Quit $$$OK")
	QUIT $$$OK
}

}
