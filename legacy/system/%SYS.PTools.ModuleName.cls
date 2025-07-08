/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %SYS.PTools.Stats

Class %SYS.PTools.ModuleName Extends %String [ ClassType = datatype, ClientDataType = VARCHAR, OdbcType = VARCHAR, SqlCategory = STRING, System = 4 ]
{

/// The maximum allowed logical value for the data type.
Parameter MAXVAL;

/// The minimum allowed logical value for the data type.
Parameter MINVAL;

/// Tests if the logical value <var>%val</var>, which represents an SQL Module is valid.
/// The validation is based on the class parameter settings used for the class attribute this 
/// data type is associated with.
/// In this case, <a href="#MAXVAL">MAXVAL</a> and <a href="#MINVAL">MINVAL</a>.
ClassMethod IsValid(%val As %RawString) As %Status [ CodeMode = generator, ServerOnly = 0 ]
{
	#; If subclass has a IsValidDT then call this
	if %property'="",$$$comSubMemberDefined(%class,$$$cCLASSproperty,%property,$$$cPROPmethod,"IsValidDT") {
		$$$GENERATE(" QUIT $s(##class("_%class_")."_$$$QN(%property_"IsValidDT")_"(%val):1,1:$$$ERROR($$$DTFailure,%val))")
		Quit $$$OK
	}
	set minval=$s(%parameter("MINVAL")<-1:-1,%parameter("MINVAL")="":-1,1:%parameter("MINVAL"))
	set maxval=$s(%parameter("MAXVAL")>1000:1000,%parameter("MAXVAL")="":1000,1:%parameter("MAXVAL"))

	set str="$isvalidnum(%val,0,"_minval_","_maxval_")"
	set code="$s($zu(115,13)&&(%val=$c(0)):1,"_str_":1,'$isvalidnum(%val):$$$ERROR($$$DTNotNum,%val),"
	Set code=code_"%val<"_minval_":$$$ERROR($$$DTMinVal,%val,"_minval_"),1:$$$ERROR($$$DTMaxVal,%val,"_maxval_"))"
	$$$GENERATE(" QUIT "_code)
	QUIT $$$OK
}

/// Converts the input value <var>%val</var>, which represents an SQL Module in display format (String), into an SQL Module # (logical format).
/// <p>Returns the logical value of the input string <var>%val</var>.
ClassMethod DisplayToLogical(%val As %String) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
#INCLUDE %SYS.PTools.Stats

    $$$GENERATE(" QUIT "_$$$ModuleNameExtToIntQ)
    QUIT $$$OK
}

/// Converts the value of <var>%val</var>, which represents an SQL Module in logical format (Integer), into an SQL Module Name (display string).
/// <p>Returns the display value of input string <var>%val</var>.
ClassMethod LogicalToDisplay(%val As %String) As %String [ CodeMode = generator, ServerOnly = 0 ]
{
    $$$GENERATE(" QUIT "_$$$ModuleNameIntToExtQ)
    QUIT $$$OK
}

/// Converts the input value <var>%val</var>, which represents an SQL Module in ODBC format (String), into an SQL Module # (logical format).
/// <p>Returns the ODBC logical value of the input string <var>%val</var>.
ClassMethod OdbcToLogical(%val As %String = "") As %String [ CodeMode = generator, ServerOnly = 1 ]
{
    $$$GENERATE(" QUIT "_$$$ModuleNameExtToIntQ)
    QUIT $$$OK
}

/// Converts the value of <var>%val</var>, which represents an SQL Module in logical format (Integer), into an SQL Module Name (ODBC VARCHAR).
/// <p>Returns the ODBC display value of input string <var>%val</var>.
ClassMethod LogicalToOdbc(%val As %String = "") As %String [ CodeMode = generator, ServerOnly = 1 ]
{
    $$$GENERATE(" QUIT "_$$$ModuleNameIntToExtQ)
    QUIT $$$OK
}

}
