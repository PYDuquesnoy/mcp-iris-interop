/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class exposes the functionality of a Minute number level within a time dimension
/// using the hijri (tabular) calendar.
/// This is the minute of the date independent of the actual day. Keys are
/// 0 through 1339; displayed values are 00:00 through 23:59
Class %DeepSee.Time.Hijri.MinuteNumber Extends %DeepSee.Time.MinuteNumber
{

Parameter CALENDAR = "hijriTabular";

/// Convert a $H value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case, we convert $H to a minute:
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pTimeOffset As %String = "") As %Integer [ CodeMode = expression ]
{
$S(pTime="":"",pTime=$$$DeepSeeNullTimeMarker:$$$DeepSeeNullTimeMarker,1:$p(pTime,",",2)\60)
}

}
