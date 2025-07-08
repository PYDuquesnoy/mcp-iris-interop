/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syGluedef

Class %Library.UTC Extends %DataType [ ClientDataType = TIMESTAMP, OdbcType = TIMESTAMP, SqlCategory = TIMESTAMP, System = 2 ]
{

ClassMethod LogicalToDisplay(%val As %TimeStamp) As %TimeStamp [ CodeMode = expression ]
{
..ConvertUTCtoLocal(%val)
}

ClassMethod DisplayToLogical(%val As %TimeStamp) As %TimeStamp [ CodeMode = expression ]
{
..ConvertLocaltoUTC(%val)
}

ClassMethod LogicalToOdbc(%val As %TimeStamp) As %TimeStamp [ CodeMode = expression ]
{
..ConvertUTCtoLocal(%val)
}

ClassMethod OdbcToLogical(%val As %TimeStamp) As %TimeStamp [ CodeMode = expression ]
{
..ConvertLocaltoUTC(%val)
}

ClassMethod StorageToLogical(%val As %TimeStamp) As %TimeStamp [ CodeMode = expression ]
{
..Normalize(%val)
}

/// Convert timstamp to horolog value
ClassMethod ConvertTimeStampToHorolog(%timestamp As %TimeStamp) As %String [ CodeMode = expression ]
{
$zdatetimeh(%timestamp,3,,,,,,,,0)
}

/// Convert horolog to timstamp value
ClassMethod ConvertHorologToTimeStamp(%horolog As %String) As %TimeStamp [ CodeMode = expression ]
{
$zdatetime(%horolog,3,,3)
}

/// Return the current UTC timestamp
ClassMethod NowUTC() As %TimeStamp [ CodeMode = expression ]
{
..ConvertHorologToTimeStamp($ztimestamp)
}

/// Return the current local timestamp
ClassMethod NowLocal() As %TimeStamp [ CodeMode = expression ]
{
..ConvertUTCtoLocal(..NowUTC())
}

/// Convert UTC timestamp to local timestamp
ClassMethod ConvertUTCtoLocal(%timestamp As %TimeStamp) As %TimeStamp [ CodeMode = expression ]
{
$s(%timestamp="":"",1:..ConvertHorologToTimeStamp($zdth(..ConvertTimeStampToHorolog(%timestamp),-3)))
}

/// Convert local timestamp to UTC timestamp
ClassMethod ConvertLocaltoUTC(%timestamp As %TimeStamp) As %TimeStamp [ CodeMode = expression ]
{
$s(%timestamp="":"",1:..ConvertHorologToTimeStamp($zdt(..ConvertTimeStampToHorolog(%timestamp),-3)))
}

/// Compare two timestamps, return 0 if equal, >0 if %t1 is later, <0 if %t2 is later
ClassMethod Compare(%t1 As %TimeStamp, %t2 As %TimeStamp) As %Integer [ CodeMode = expression ]
{
..Diff(%t1,%t2)
}

/// Return the number of seconds difference between two timestamps.
/// if '%later' is earlier than '%earlier' then the result is a negative number.
ClassMethod Diff(%later As %TimeStamp, %earlier As %TimeStamp) As %Integer
{
	set laterH=..ConvertTimeStampToHorolog(%later)
	set earlierH=..ConvertTimeStampToHorolog(%earlier)
	quit ($p(laterH,",",1)-$p(earlierH,",",1))*(24*3600)+$p(laterH,",",2)-$p(earlierH,",",2)
}

/// Strip off trailing zeros and trailing dot for normalized form
ClassMethod Normalize(%val As %RawString) As %TimeStamp [ ServerOnly = 1 ]
{
	if $p(%val,":",3)'["." quit %val
	for i=1:1:3 quit:$e(%val,*)'="0"  set %val=$e(%val,1,*-1)
	if $e(%val,*)="." set %val=$e(%val,1,*-1)
	quit %val
}

/// Seconds since Jan 1 1970. Minimum timestamp="47117,0"
ClassMethod SecondsSinceUnixEpoch(TimeStamp As %String = {$ztimestamp}) As %Integer
{
#;47117=days from December 31, 1840 to Jan 1 1970
	i $ZDATETIME(TimeStamp,,,,,,,,47117 /* mindate */)
	q +TimeStamp-47117*(60*60*24)+$p($p(TimeStamp,",",2),".")
}

/// Seconds since Dec 31, 1840. Minimum timestamp="0,0"
ClassMethod SecondsSinceCOSEpoch(TimeStamp As %String = {$ztimestamp}) As %Integer
{
	i $ZDATETIME(TimeStamp,,,,,,,,0 /* mindate */)
	q +TimeStamp*(60*60*24)+$p($p(TimeStamp,",",2),".")
}

/// Seconds since Jan 1 1601. Minimum timestamp="0,0"
ClassMethod SecondsSinceWin32Epoch(TimeStamp As %String = {$ztimestamp}) As %Integer
{
#;7573564800=Calculated seconds from jan 1 1601 until 12/31/1840
	q 7573564800+..SecondsSinceCOSEpoch(TimeStamp)
}

/// 100-nanoseconds since Jan 1 1601. Matches Windows FILETIME. Minimum timestamp="0,0"
ClassMethod Win32EpochFILETIME(TimeStamp As %String = {$ztimestamp}) As %Integer
{
	q ..SecondsSinceWin32Epoch(TimeStamp)*10000000
}

/// Converts a Windows FILETIME value to a $H value. 
/// Minimum FILETIME=75735648000000000 = 12/31/1840 = "0,0"
ClassMethod Win32EpochFILETIMEtoLocalH(Win32EpochFILETIME As %String) As %TimeStamp
{
	s SecondsSinceWin32Epoch=Win32EpochFILETIME/10000000
	i SecondsSinceWin32Epoch<1 Ztrap $$$APPERROR($$$ERFUNCT)
	s SecondsSinceCOSEpoch=SecondsSinceWin32Epoch-7573564800
	i SecondsSinceCOSEpoch<0 Ztrap $$$APPERROR($$$ERFUNCT)
	s Days=SecondsSinceCOSEpoch\(24*60*60)
	s Seconds=SecondsSinceCOSEpoch#(24*60*60)
	q Days_","_Seconds
}

}
