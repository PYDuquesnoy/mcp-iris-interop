/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a Quarter number level within a time dimension.
/// This represents the Quarter number (period of 3 months) independent of year.
Class %DeepSee.Time.HijriObserved.QuarterNumber Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
{

Parameter CALENDAR = "hijriObserved";

/// Return true if this level supports a NOW member.
ClassMethod %SupportsNOW() As %Boolean
{
	Quit 1
}

/// Return true if this time level is <b>independent</b> of the actual date.
ClassMethod %IsIndependent() As %Boolean
{
	Quit 1
}

/// Convert a $H value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case, we convert $H to a quarter period number:
/// That is convert to 1,2,3, or 4.
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pTimeOffset As %String = "") As %Integer [ CodeMode = expression ]
{
$S(pTime="":"",pTime=$$$DeepSeeNullTimeMarker:$$$DeepSeeNullTimeMarker,1:1+((+$P($ZDT(pTime,21)," ",2)-1)\3))
}

/// Return the total number of members within this level.<br/>
ClassMethod %Count(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %Integer
{
	Set tCount = 4
	Quit tCount
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "QuarterNumber"
}

/// Convert a level key value to a display value.
/// E.g., Q1
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pOffset As %String = "") As %String
{
	Quit "Q" _ pKey
}

/// Convert a level display value (Qn) to its corresponding key value.
/// Return "" if there is no corresponding key.
ClassMethod %ValueToKey(pValue As %String, pFormat As %String = "", pOffset As %String = "") As %Integer
{
	If ($$$UPPER($E(pValue,1,3))="NOW") {
		Set tQuarter = ..%Convert($H,pOffset)
		If ($P(pValue,"+",2)'="") {
			Set tQuarter = tQuarter + $P(pValue,"+",2)
			While (tQuarter > 4) {
				Set tQuarter = tQuarter - 4
			}
		}
		ElseIf ($P(pValue,"-",2)'="") {
			Set tQuarter = tQuarter - $P(pValue,"-",2)
			While (tQuarter < 1) {
				Set tQuarter = tQuarter + 4
			}
		}
		Quit tQuarter
	}
	Set tKey = $E(pValue,2)
	Quit $S(($L(pValue)=2)&&($E(pValue)="Q")&&$IsValidNum(tKey):tKey,1:"")
}

/// Convert a quarter value (year number) into starting and ending
/// base values (in $H format).<br/>
/// As this dimension is independent of year, we use year 1400 as 
/// the basis of calculations.
ClassMethod %KeyToBaseRange(pValue As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	Set (pStart,pEnd) = ""
	Set tSC = $$$OK
	Try {
		Set tYear = 1400
		Set tStartMonth = ((pValue-1)*3)+1
		Set tEndMonth = tStartMonth + 2
		Set pStart = $ZDTH("1 " _ tStartMonth _ " " _ tYear,21,,,,,,,,"")
		Set tLastDayNo = ##class(%DeepSee.Utils).%HijriDaysInMonth(tYear,tEndMonth,"hijriTabular")
		Set pEnd = $ZDTH(tLastDayNo_" "_tEndMonth_" "_tYear_" 23:59:59",21,,,,,,,,"")
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an array of members of this level.
ClassMethod %GetLevelMembers(Output pList As %List, pCube As %String, pFact As %String, pStartRange As %Date, pEndRange As %Date, pTimeOffset As %String = "", pFormat As %String = "") As %Status
{
	If (pStartRange = "") {
		Quit ..%GetAllMembers(.pList,pCube,pFact,pStartRange,pEndRange,pFormat)
	}

	// Find quarters within given range
	// At most, return 1 through 4
	Set tStart = ..%Convert(pStartRange,pTimeOffset)
	Set tEnd = ..%Convert(pEndRange,pTimeOffset)
	If (tEnd < tStart) {
		Set tStart = 1
		Set tEnd = 4
	}

	Set n = 0
	For q = tStart:1:tEnd {
		Set tKey = q
		Set tValue = ..%KeyToValue(tKey,pFormat,pTimeOffset)
		Set n = n + 1
		Set pList(n) = $LB(tValue,tKey)	// value,key
	}
	Quit $$$OK
}

/// Return, via <var>pRelatedKey</var> a key within this level
/// related to <var>pKey</var>.<br/>
ClassMethod %GetRelatedKey(Output pRelatedKey As %String, pCube As %String, pFact As %String, pKey As %String, pRelation As %String, pOffset As %Integer = "", pEndKey As %String = "", pTimeOffset As %String = "") As %Status
{
	If (pRelation = "lead") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		// Set pRelatedKey = (((pKey + tOffset) - 1) # 4) + 1
		// JMD1510
		if ($e(pKey)="Q") { // JSL4410
			Set pKey=$e(pKey,2,*)
		}
		Set pRelatedKey = pKey + tOffset
		Set:pRelatedKey>4 pRelatedKey = ""
	}
	ElseIf (pRelation = "lag") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		// Set pRelatedKey = (((pKey - tOffset) - 1) # 4) + 1
		// JMD1510
		if ($e(pKey)="Q") { // JSL4410
			Set pKey=$e(pKey,2,*)
		}
		Set pRelatedKey = pKey - tOffset
		Set:pRelatedKey<1 pRelatedKey = ""
	}
	ElseIf (pRelation = "first") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = (((1 + tOffset) - 1) # 4) + 1
	}
	ElseIf (pRelation = "last") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = (((4 - tOffset) - 1) # 4) + 1

	}
	Else {
		Quit ##super(.pRelatedKey,.pCube,pFact,pKey,pRelation,pOffset)
	}

	Quit $$$OK
}

}
