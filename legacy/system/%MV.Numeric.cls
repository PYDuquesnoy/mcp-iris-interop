/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Data type class to handle the MultiValue masked decimal (MD) conversion codes
Class %MV.Numeric Extends %Numeric [ ClientDataType = NUMERIC, OdbcType = NUMERIC, Not ProcedureBlock, SqlCategory = NUMERIC, System = 2 ]
{

/// The number of decimal place to shift (as with the MultiValue MD conversion)
Parameter DESCALE;

ClassMethod LogicalToStorage(%val As %MV.Numeric) As %String [ CodeMode = generator ]
{
	set %code=0
	set %codemode=$$$cMETHCODEMODEEXPRESSION
	if $isvalidnum(%parameter("DESCALE")) {
		set %code = "$s(%val="""":%val,1:%val*"_((10**(%parameter("DESCALE")\1)))_")"
	} else {
		set %code="%val"
	}
	QUIT $$$OK
}

ClassMethod StorageToLogical(%val As %String) As %MV.Numeric [ CodeMode = generator ]
{
	set %code=0
	set %codemode=$$$cMETHCODEMODEEXPRESSION
	if $isvalidnum(%parameter("DESCALE")) {
		set %code = "$s(%val="""":%val,1:%val/"_((10**(%parameter("DESCALE")\1)))_")"
	} else {
		set %code="%val"
	}
	QUIT $$$OK
}

}
