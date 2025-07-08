/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class exposes the functionality of an Hour number level within a time dimension
/// using the hijri (tabular) calendar.
/// This is the hour of the date independent of the actual day. Keys are
/// 0 through 23; displayed values are 12am, 1am, until 11pm.
Class %DeepSee.Time.Hijri.HourNumber Extends %DeepSee.Time.HourNumber [ System = 3 ]
{

Parameter CALENDAR = "hijriTabular";

/// Convert a $H value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case, we convert $H to a day-of-month period number:
/// That is convert to a number one through 31.
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pTimeOffset As %String = "") As %Integer [ CodeMode = expression ]
{
$S(pTime="":"",pTime=$$$DeepSeeNullTimeMarker:$$$DeepSeeNullTimeMarker,1:(+$E($ZDT(pTime,3),12,13)))
}

}
