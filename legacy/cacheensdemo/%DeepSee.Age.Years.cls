/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements an age-in-years level within a age dimension.
Class %DeepSee.Age.Years Extends %DeepSee.Age.AbstractLevel [ System = 3 ]
{

/// Convert a $H value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case we convert $H to age relative to today (age-based rollup dimensions need to
/// be rebuilt, so there is no point in using a fixed reference date).
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pTimeOffset As %String = "") As %Integer
{
	Quit:(pTime="") ""
	Quit ##class(%DeepSee.Utils).%ComputeAge(pTime,+$H,"years")
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "Years"
}

/// Convert a level key value to a display value.
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pOffset As %String = "") As %String
{
	Quit:(pKey="") ""
	Quit $J(pKey,2) _ " year(s)"
}

/// Convert a level display value to its corresponding key value.
/// Return "" if there is no corresponding key.
ClassMethod %ValueToKey(pValue As %String, pFormat As %String = "", pOffset As %String = "") As %Integer
{
	Quit:(pValue="") ""
	Quit +pValue
}

/// Convert a year value (age in years) into starting and ending base values (in $H format).
ClassMethod %KeyToBaseRange(pKey As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	Set (pStart,pEnd) = ""
	Set tSC = $$$OK
	Try {
		// key is age in years
		// convert to age in days (for both ends of the year) relative to the reference point

		// find start/end dates for the given age
		Set tStartDate = +##class(%DeepSee.Utils).%AddTimeInterval(+$H,-pKey_"y")
		Set tEndDate = +##class(%DeepSee.Utils).%AddTimeInterval(+$H,-(pKey+1)_"y")+1

		Set pStart = $H-tStartDate
		Set pEnd = $H-tEndDate
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given a pair of base values (in $H format) find a key value that lies within the range.
ClassMethod %BaseRangeToKey(Output pKey As %String, pStart As %Date, pEnd As %Date, pOffset As %String = "") As %Status
{
	Set pKey = ""
	Set tSC = $$$OK
	Try {
		// start and end are age in days from reference point
		Set tStart = pStart+$$$dsReferenceTime
		Set pKey = 	##class(%DeepSee.Utils).%ComputeAge(tStart,+$H,"years")
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

	Do ..%BaseRangeToKey(.tStart,+$H-pStartRange-$$$dsReferenceTime,+$H-pStartRange-$$$dsReferenceTime)
	Do ..%BaseRangeToKey(.tEnd,+$H-pEndRange-$$$dsReferenceTime,+$H-pEndRange-$$$dsReferenceTime)

	If (tStart > tEnd) {
		Set x = tStart
		Set tStart = tEnd
		Set tEnd = x
	}

	Set n = 0
	For y = tStart:1:tEnd {
		Set tKey = y
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
		Quit ##super(.pRelatedKey,.pCube,pFact,pKey,pRelation,pOffset)
	}

	Quit $$$OK
}

}
