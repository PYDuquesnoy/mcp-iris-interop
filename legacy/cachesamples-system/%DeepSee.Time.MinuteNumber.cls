/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a Minute level within a time dimension.
/// This is the minute of the date independent of the actual day. Keys are
/// 0 through 1339; displayed values are 00:00 through 23:59
Class %DeepSee.Time.MinuteNumber Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
{

/// Return true if this time level is <b>independent</b> of the actual date.
ClassMethod %IsIndependent() As %Boolean
{
	Quit 1
}

/// Return the number of seconds in one unit of this time level.
ClassMethod %GetPeriodLength() As %Integer
{
	Quit 60
}

/// Convert a $H value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case, we convert $H to a minute:
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pTimeOffset As %String = "") As %Integer [ CodeMode = expression ]
{
$S(pTime="":"",pTime=$$$DeepSeeNullTimeMarker:$$$DeepSeeNullTimeMarker,1:$p(pTime,",",2)\60)
}

/// Return the total number of members within this level.<br/>
ClassMethod %Count(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %Integer
{
	Set tCount = 1440
	Quit tCount
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "MinuteNumber"
}

/// Convert a level key value to a display value.
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pOffset As %String = "") As %String
{
	If ($$$UPPER($E(pKey,1,3))="NOW") {
		Set pKey = ..%ValueToKey(pKey,,pOffset)
	}
	If (((+pKey*60)>86399)||(+pKey<0)) {
		// not a minute key
		Quit ""
	}
	Quit $zt(pKey*60,2)
}

/// Convert a level display value to its corresponding key value.
/// Return "" if there is no corresponding key.
ClassMethod %ValueToKey(pValue As %String, pFormat As %String = "", pOffset As %String = "") As %Integer
{
	Set tKey = ""

	If ($$$UPPER($E(pValue,1,3))="NOW") {
		Set tKey = ..%Convert($H,pOffset)
		If ($P(pValue,"+",2)'="") {
			Set tKey = tKey + $P(pValue,"+",2)
		}
		ElseIf ($P(pValue,"-",2)'="") {
			Set tKey = tKey - $P(pValue,"-",2)
		}
	}
	Else {
		Try {
			Set tKey = $zth(pValue)\60
		}
		Catch(ex) {
			Set tKey = ""
		}
	}
	Quit tKey
}

/// Convert a minute number into starting and ending
/// base values (in $H format).<br/>
/// As this dimension is independent of year, we use year 2000 as 
/// the basis of calculations.
ClassMethod %KeyToBaseRange(pKey As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	Set (pStart,pEnd) = ""
	Set tSC = $$$OK
	Try {
		// We need $H format, but the day does not matter
		// so we just use 58074, which is 2000-01-01
		Set pStart = pKey*60 
		Set pEnd = pStart+59
		Set pStart = 58074_","_pStart 
		Set pEnd = 58074_","_pEnd
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

	// Find minutes within given range
	// At most, return 0 through 1439
	Set tStart = ..%Convert(pStartRange)
	Set tEnd = ..%Convert(pEndRange)

	If (tEnd < tStart) {
		Set tStart = 0
		Set tEnd = 1439
	}

	Set n = 0
	For q = tStart:1:tEnd {
		Set tKey = q
		Set tValue = ..%KeyToValue(tKey)
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
		Set pRelatedKey = ((pKey + tOffset) # 1440)
	}
	ElseIf (pRelation = "lag") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		Set pRelatedKey = ((pKey - tOffset) # 1440)
	}
	ElseIf (pRelation = "first") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = ((pKey + tOffset) # 1440)
	}
	ElseIf (pRelation = "last") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = ((pEndKey - tOffset) # 1440)
	}
	Else {
		Quit ##super(.pRelatedKey,.pCube,pFact,pKey,pRelation,pOffset)
	}
	Quit $$$OK
}

/// Return true if this level supports a NOW member.
ClassMethod %SupportsNOW() As %Boolean
{
	Quit 1
}

}
