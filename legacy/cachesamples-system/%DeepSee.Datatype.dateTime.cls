/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Used to represent dates within DeepSee.
/// This datatype can contain a complete $H value with days and seconds.
Class %DeepSee.Datatype.dateTime Extends %TimeStamp [ System = 3 ]
{

/// Converts <var>%val</var> to a normalized internal $Horolog value.
ClassMethod Normalize(%val As %RawString) As %DeepSee.Datatype.dateTime [ CodeMode = expression, ServerOnly = 1 ]
{
$s( %val="":"", %val=(%val\1):%val_",0", %val="0,0":%val, $zdatetime(%val,3,,,,,,,-672045,,"")="":"error", $zdatetimeh($zdatetime(%val,3,,,,,,,-672045,,""),3)="0,0":"error", 1:$zdatetimeh($zdatetime($p(%val,"."),3,,,,,,-672045),3,,,,,,-672045,,"")_$s(+$p(%val,".",2)=0:"",1:+("."_$e($p(%val,".",2),1,9))) )
}

/// Validate logical $H value, ignore parameters.
ClassMethod IsValid(%val As %RawString) As %Status [ ServerOnly = 1 ]
{
	// $ZDT will accept bogus dates, such as "ABC"; test for this
	Set tDay = $P(%val,",",1)
	Set tSec = $P(%val,",",2)
	If ((tDay'="")&&('$IsValidNum(tDay)||(tDay<=0))) {	// DTB311 - Reject negative and 0
		Quit $$$ERROR($$$DTNotNum,%val)
	}
	If ((tSec'="")&&'$IsValidNum(tSec)) {
		Quit $$$ERROR($$$DTNotNum,%val)
	}
	
	QUIT $S($ZDT(%val,3,,,,,,,,,"X")'="X":$$$OK,1:$$$ERROR($$$DTNotNum,%val))
}

/// Converts the value of <var>%val</var>, which is in logical $Horolog format, into a display string on ODBC format <code>YYYY-MM-DD HH:MM:SS[.nnnnnnnnn]</code>.
ClassMethod LogicalToDisplay(%val As %TimeStamp) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
	If %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("VALUELIST"),%parameter("DISPLAYLIST"))
	} Else {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$zdt(%val,3,,$l($p(%val,""."",2)))"
	}
	QUIT $$$OK
}

/// Converts the value of <var>%val</var>, which is in logical $Horolog format, into an ODBC string <code>YYYY-MM-DD HH:MM:SS[.nnnnnnnnn]</code>.
ClassMethod LogicalToOdbc(%val As %TimeStamp) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
	If %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("VALUELIST"),%parameter("DISPLAYLIST"))
	} Else {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$zdt(%val,3,,$l($p(%val,""."",2)))"
	}
	QUIT $$$OK
}

/// Converts the input value <var>%val</var>, which represents a Display dateTime value,
/// to internal $Horolog format.
ClassMethod DisplayToLogical(%val As %String) As %DeepSee.Datatype.dateTime [ CodeMode = generator, ServerOnly = 0 ]
{
	If %parameter("VALUELIST")'="",%parameter("DISPLAYLIST")'="" {
		do GenerateValConv^%occLibrary(%parameter("DISPLAYLIST"),%parameter("VALUELIST"))
	} Else {
		Set %codemode=$$$cMETHCODEMODEEXPRESSION
		Set %code="$zdth(%val,3)"
	}
	QUIT $$$OK
}

/// Converts <var>%val</var>, which represents either a dateTime value in ODBC format,
/// or a Date in ODBC format, into a logical dateTime value in $Horolog format.
ClassMethod OdbcToLogical(%val As %String) As %DeepSee.Datatype.dateTime [ ServerOnly = 1 ]
{
	Quit:%val="" ""
	If $zdatetimeh(%val,3,,,,,,-672045,,"")'="" {
		Set %val=$zdatetime($zdatetimeh(%val,3,,,,,,-672045),3,,$l($p(%val,".",2)),,,,,-672045)
	} elseif $zdatetimeh(%val,-1,,,,,,-672045,,"")'="" {
		Set %val=$zdatetime($zdatetimeh(%val,-1,,,,,,-672045),3,,$l($p(%val,".",2)),,,,,-672045)
	}
	Quit $s(%val'[".":$zdth(%val,3),1:$zdth($zstrip($zstrip(%val,">","0"),">","."),3))
}

}
