/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a Day number level within a time dimension.
/// This is the day of the month independent of year (1 through 31).
Class %DeepSee.Time.Partial.DayNumber Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
{

Parameter CALENDAR As STRING = "partial";

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

/// Convert a partial date ODBC value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case, we convert partial date to a day-of-month period number:
/// That is convert to a number one through 31.
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pTimeOffset As %String = "") As %Integer [ CodeMode = expression ]
{
$S(pTime="":"",pTime=$$$DeepSeeNullTimeMarker:$$$DeepSeeNullTimeMarker,1:(+$P(pTime,"-",3)))
}

/// Return the total number of members within this level.<br/>
ClassMethod %Count(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %Integer
{
	Set tCount = 32
	Quit tCount
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "DayNumber"
}

/// Convert a level key value to a display value.
/// E.g., 1 or 30
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pOffset As %String = "") As %String
{
	Set x = 1
	
	If ($$$UPPER($E(pKey,1,3))="NOW") {
		Set pKey = ..%ValueToKey(pKey,pFormat,pOffset)
	}
	
	If ('pKey)&&(pFormat'="") {
		Set tValue = ##class(%DeepSee.Utils).%FormatPartialDate("2000-01-"_$$$iscPadZero(pKey,2),pFormat)
	}
	Else {
		Set tValue = pKey
	}
	Quit tValue
}

/// Convert a level display value to its corresponding key value.
/// Return "" if there is no corresponding key.
ClassMethod %ValueToKey(pValue As %String, pFormat As %String = "", pOffset As %String = "") As %Integer
{
	If ($$$UPPER($E(pValue,1,3))="NOW") {
		Set tKey = +$H
		If ($P(pValue,"+",2)'="") {
			Set tKey = tKey + $P(pValue,"+",2)
		}
		ElseIf ($P(pValue,"-",2)'="") {
			Set tKey = tKey - $P(pValue,"-",2)
		}
		Quit ..%Convert($ZD(tKey,3),pOffset)
	}

	If ($IsValidNum(pValue)&&(pValue=(pValue\1))&&(pValue>=0)&&(pValue<=31)) {
		Quit +pValue
	}
	ElseIf (pFormat'="") {
		// Attempt to resolve an "unknown"
		Quit +$P(##class(%DeepSee.Utils).%UnformatPartialDate(pValue,pFormat),"-",3)
	}

	Quit ""
}

/// Convert a day-of-month number into starting and ending
/// base values (in $H format).<br/>
/// As this dimension is independent of year, we use year 2000 as 
/// the basis of calculations.
ClassMethod %KeyToBaseRange(pKey As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	Set (pStart,pEnd) = ""
	Set tSC = $$$OK
	Try {
		Set tYear = 2000
		Set tMonth = 1
		Set tDay = pKey
		Set pStart = tYear_"-"_$$$iscPadZero(tMonth,2)_"-"_$$$iscPadZero(tDay,2)
		Set pEnd = pStart
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an array of members of this level.<br/>
/// As this dimension is independent of year, we use Jan 2000 as 
/// the basis of calculations.
ClassMethod %GetLevelMembers(Output pList As %List, pCube As %String, pFact As %String, pStartRange As %Date, pEndRange As %Date, pTimeOffset As %String = "", pFormat As %String = "") As %Status
{
	If (pStartRange = "") {
		Quit ..%GetAllMembers(.pList,pCube,pFact,pStartRange,pEndRange,pFormat)
	}

	// Find days within given range
	// At most, return 1 through 31
	Set tStart = ..%Convert(pStartRange,pTimeOffset)
	Set tEnd = ..%Convert(pEndRange,pTimeOffset)
	If (tEnd < tStart) {
		Set tStart = 1
		Set tEnd = 31
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
	If ('pKey) {
		// DTB686 - Unknown value
		Set pRelatedKey=pKey
	}
	ElseIf (pRelation = "lead") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		//Set pRelatedKey = (((pKey + tOffset) - 1) # 31) + 1
		// JMD1510
		Set pRelatedKey = pKey + tOffset
		Set:pRelatedKey>31 pRelatedKey = ""
	}
	ElseIf (pRelation = "lag") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		//Set pRelatedKey = (((pKey - tOffset) - 1) # 31) + 1
		// JMD1510
		Set pRelatedKey = pKey - tOffset
		Set:pRelatedKey<1 pRelatedKey = ""
	}
	ElseIf (pRelation = "first") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = (((pKey + tOffset) - 1) # 31) + 1
	}
	ElseIf (pRelation = "last") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = (((pEndKey - tOffset) - 1) # 31) + 1
	}
	Else {
		Quit ##super(.pRelatedKey,.pCube,pFact,pKey,pRelation,pOffset)
	}
	Quit $$$OK
}

}
