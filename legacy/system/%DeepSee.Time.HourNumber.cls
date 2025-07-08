/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements an Hour number level within a time dimension.
/// This is the hour of the date independent of the actual day. Keys are
/// 0 through 23; displayed values are 12am, 1am, until 11pm.
Class %DeepSee.Time.HourNumber Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
{

/// Return true if this time level is <b>independent</b> of the actual date.
ClassMethod %IsIndependent() As %Boolean
{
	Quit 1
}

/// Return the number of seconds in one unit of this time level.
ClassMethod %GetPeriodLength() As %Integer
{
	Quit 3600
}

/// Convert a $H value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case, we convert $H to a day-of-month period number:
/// That is convert to a number one through 31.
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pTimeOffset As %String = "") As %Integer [ CodeMode = expression ]
{
$S(pTime="":"",pTime=$$$DeepSeeNullTimeMarker:$$$DeepSeeNullTimeMarker,1:(+$E($ZDT(pTime,3),12,13)))
}

/// Return the total number of members within this level.<br/>
ClassMethod %Count(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %Integer
{
	Set tCount = 24
	Quit tCount
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "HourNumber"
}

/// Convert a level key value to a display value.
/// E.g., "1am" or "11pm"
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pOffset As %String = "") As %String
{
	If ($$$UPPER($E(pKey,1,3))="NOW") {
		Set pKey = ..%ValueToKey(pKey,,pOffset)
	}
	If ((+pKey<0)||(+pKey>24)) {
		Quit ""
	}
	Quit $S(pKey=0:"12am",pKey=12:"12pm",(pKey>=12):(pKey-12)_"pm",1:pKey_"am")
}

/// Convert a level display value to its corresponding key value.
/// Return "" if there is no corresponding key.
ClassMethod %ValueToKey(pValue As %String, pFormat As %String = "", pOffset As %String = "") As %Integer
{
	set tKey = ""
	
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
		Set h = +pValue
		If (h > 0) {
			Set h = $S($$$LOWER(pValue)["pm":h+12,h=12:0,1:h)
			Set:h=24 h=12
			If ($IsValidNum(h)&&(h=(h\1))&&(h>=0)&&(h<24)) {
				set tKey = h
			}
		}
	}
	Quit tKey
}

/// Convert a hour-of-day number into starting and ending
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
		Set tDay = 1
		Set tHour = $TR($J(pKey,2)," ",0)
		Set pStart = $ZDTH(tYear_"-"_$$$iscPadZero(tMonth,2)_"-"_$$$iscPadZero(tDay,2)_" "_tHour,3,,,,,,,,"")
		Set pEnd = $ZDTH(tYear_"-"_$$$iscPadZero(tMonth,2)_"-"_$$$iscPadZero(tDay,2)_" "_tHour_":59:59",3,,,,,,,,"")
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

	// Find hours within given range
	// At most, return 0 through 23
	Set tStart = ..%Convert(pStartRange)
	Set tEnd = ..%Convert(pEndRange)

	If (tEnd < tStart) {
		Set tStart = 0
		Set tEnd = 23
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
		//Set pRelatedKey = ((pKey + tOffset) # 24)
		// JMD1510
		Set pRelatedKey = pKey + tOffset
		Set:pRelatedKey>24 pRelatedKey = ""
	}
	ElseIf (pRelation = "lag") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		//Set pRelatedKey = ((pKey - tOffset) # 24)
		// JMD1510
		Set pRelatedKey = pKey - tOffset
		Set:pRelatedKey<1 pRelatedKey = ""
	}
	ElseIf (pRelation = "first") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = ((pKey + tOffset) # 24)
	}
	ElseIf (pRelation = "last") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = ((pEndKey - tOffset) # 24)
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
