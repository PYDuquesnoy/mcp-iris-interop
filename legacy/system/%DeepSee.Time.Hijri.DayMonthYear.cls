/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a Day level within a time dimension.
/// This is a specific day value that includes month and year.
Class %DeepSee.Time.Hijri.DayMonthYear Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
{

Parameter DIMTYPE = "day";

Parameter CALENDAR = "hijriTabular";

/// Convert a $H value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case we convert full $H to the day portion of $H.
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pTimeOffset As %String = "") As %Integer [ CodeMode = expression ]
{
$S(pTime="":"",pTime=$$$DeepSeeNullTimeMarker:$$$DeepSeeNullTimeMarker,1:pTime\1)
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "DayMonthYear"
}

/// Convert a level key value ($H date) to a display value.
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pTimeOffset As %String = "") As %String
{
	If ($$$UPPER($E(pKey,1,3))="NOW") {
		Set pKey = ..%ValueToKey(pKey)
	}

	Set tText = $ZDT(+pKey,18)

	Quit tText
}

/// Convert a level display value to its corresponding key value.
/// Return "" if there is no corresponding key.
ClassMethod %ValueToKey(pValue As %String, pFormat As %String = "", pOffset As %String = "") As %Integer
{
	Set tKey = ""

	Try {
		// Mmm Dd (Yyyy)
		// Make sure we return "" if this is NOT a valid date
		If ($$$UPPER($E(pValue,1,3))="NOW") {
			Set tKey = $H
			// JMD986: special case for NOW-1y
			Set tInterval = $E(pValue,4,$L(pValue))
			If (tInterval'="") {
				Set tUnits = $Case($$$UPPER($E(pValue,$L(pValue))),"Y":"y","M":"m",:"")
				If (tUnits'="") {
					Set tInterval = $E(tInterval,1,$L(tInterval)-1)
				}
				Else {
					Set tUnits = "d"
				}
				Set tKey = ##class(%DeepSee.Utils).%AddHijriTimeInterval(tKey,tInterval_tUnits,..#CALENDAR)
			}
		}
		Else {
			Set tKey = $ZDTH(pValue,18)
		}
		Set:tKey'="" tKey = +tKey
	}
	Catch {
		Set tKey = ""
	}
	Quit tKey
}

/// Convert a day of month ($H) into starting and ending
/// base values (in $H format).
ClassMethod %KeyToBaseRange(pKey As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	// JMD1409
	If (pKey=$$$DeepSeeNullTimeMarker) {
		Set (pStart,pEnd) = ""
	}
	Else {
		// JMD947: return complete range of day
		Set pStart = pKey
		Set pEnd = pKey_",86399"
	}
	Quit $$$OK
}

/// Return an array of members of this level.
ClassMethod %GetLevelMembers(Output pList As %List, pCube As %String, pFact As %String, pStartRange As %Date, pEndRange As %Date, pTimeOffset As %String = "", pFormat As %String = "") As %Status
{
	If (pStartRange = "") {
		Quit ..%GetAllMembers(.pList,pCube,pFact,pStartRange,pEndRange,pFormat)
	}
	
	// JMD1330 if slicer or nonempty in context, limit to values in the index
	// DTB185 - If the start and end keys are the same, do not recalculate
	Set tNonEmpty = $S($IsObject($G(%axisObject))&&%axisObject.nonEmpty:1,1:0)
	If ((pTimeOffset="") && (tNonEmpty || +$G(%isSlicer))) && '(pStartRange=pEndRange) {
		// JMD1374: skip if we are being asked for one value
		// this makes Lag/Lead work on bogus dates
		If (pStartRange'=pEndRange) {
			Do ..%GetAllMembers(.tStartList,pCube,pFact,"FIRST")
			Set tDate = $LG($G(tStartList(1)),2)
			If ((tDate'="")&&(tDate>+pStartRange)) {
				Set pStartRange = tDate
			}
			If (pEndRange'="") {
				Do ..%GetAllMembers(.tEndList,pCube,pFact,"LAST")
				Set tDate = $LG($G(tEndList(1)),2)
				If ((tDate'="")&&(tDate<+pEndRange)) {
					Set pEndRange = tDate
				}
			}
		}
	}

	Set n = 0
	For d = +pStartRange:1:+pEndRange {
		Set tKey = d
		Set tValue = ..%KeyToValue(tKey,pFormat)
		Set n = n + 1
		Set pList(n) = $LB(tValue,tKey)	// value,key
	}
	Quit $$$OK
}

/// Return, via <var>pRelatedKey</var> a key within this level
/// related to <var>pKey</var>.<br/>
ClassMethod %GetRelatedKey(Output pRelatedKey As %String, pCube As %String, pFact As %String, pKey As %String, pRelation As %String, pOffset As %Integer = "", pEndKey As %String = "", pTimeOffset As %String = "") As %Status
{
	If (pKey=$$$DeepSeeNullTimeMarker) {
		Set pRelatedKey = pKey
	}
	ElseIf (pRelation = "lead") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		Set pRelatedKey = pKey + tOffset
	}
	ElseIf (pRelation = "lag") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		Set pRelatedKey = pKey - tOffset
	}
	ElseIf (pRelation = "first") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = pKey + tOffset
	}
	ElseIf (pRelation = "last") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = pEndKey - tOffset
	}
	Else {
		Quit ##super(.pRelatedKey,.pCube,pFact,pKey,pRelation,pOffset,pEndKey,pTimeOffset)
	}

	Quit $$$OK
}

/// Return true if this level supports a NOW member.
ClassMethod %SupportsNOW() As %Boolean
{
	Quit 1
}

}
