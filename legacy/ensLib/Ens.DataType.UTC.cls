/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.DataType.UTC [ ClassType = datatype, ClientDataType = TIMESTAMP, OdbcType = TIMESTAMP, ProcedureBlock, SqlCategory = TIMESTAMP, System = 4 ]
{

ClassMethod LogicalToDisplay(%val As %TimeStamp) As %TimeStamp [ CodeMode = expression ]
{
$s(%val="":"",1:$zdatetime($zdTH($zdatetimeh(%val,3),-3),3,,3))
}

ClassMethod LogicalToOdbc(%val As %TimeStamp) As %TimeStamp [ CodeMode = expression ]
{
$s(%val="":"",1:$zdatetime($zdTH($zdatetimeh(%val,3),-3),3,,3))
}

ClassMethod OdbcToLogical(%val As %TimeStamp) As %TimeStamp [ CodeMode = expression ]
{
$s(%val="":"",1:$zdatetime($zdT($zdatetimeh(%val,3),-3),3,,3))
}

ClassMethod DisplayToLogical(%val As %TimeStamp) As %TimeStamp [ CodeMode = expression ]
{
$s(%val="":"",1:$zdatetime($zdT($zdatetimeh(%val,3),-3),3,,3))
}

ClassMethod timeUTCtoUTCH(%utc As %TimeStamp) As %String [ CodeMode = expression ]
{
$zdatetimeh(%utc,3)
}

ClassMethod timeUTCHtoUTC(%utch As %String) As %TimeStamp [ CodeMode = expression ]
{
$zdatetime(%utch,3,,3)
}

ClassMethod timeUTC() As %TimeStamp [ CodeMode = expression ]
{
$zdatetime($ztimestamp,3,,3)
}

ClassMethod timeUTCH() As %String [ CodeMode = expression ]
{
$ztimestamp
}

ClassMethod timeLocal() As %TimeStamp [ CodeMode = expression ]
{
##class(Ens.DataType.UTC).LogicalToOdbc($zdatetime($ztimestamp,3,,3))
}

ClassMethod timeUTCtoLocal(%utc As %TimeStamp) As %TimeStamp [ CodeMode = expression ]
{
##class(Ens.DataType.UTC).LogicalToOdbc(%utc)
}

ClassMethod timeLocaltoUTC(%utc As %TimeStamp) As %TimeStamp [ CodeMode = expression ]
{
##class(Ens.DataType.UTC).OdbcToLogical(%utc)
}

ClassMethod timeCmp(%t2 As %TimeStamp, %t1 As %TimeStamp) As %Integer [ CodeMode = expression ]
{
$$HorologCmp^EnsUtil($zdatetimeh(%t2,3),$zdatetimeh(%t1,3))
}

ClassMethod timeDiff(%t2 As %TimeStamp, %t1 As %TimeStamp) As %Integer [ CodeMode = expression ]
{
$$HorologDiff^EnsUtil($zdatetimeh(%t2,3),$zdatetimeh(%t1,3))
}

/// Strip off trailing zeros and trailing dot for normalized form
ClassMethod Normalize(%val As %RawString) As %TimeStamp [ ServerOnly = 1 ]
{
	if $p(%val,":",3)'["." quit %val
	for i=1:1:3 quit:$e(%val,*)'="0"  set %val=$e(%val,1,*-1)
	if $e(%val,*)="." set %val=$e(%val,1,*-1)
	quit %val
}

ClassMethod StorageToLogical(%val As %TimeStamp) As %TimeStamp
{
	quit ..Normalize(%val)
}

}
