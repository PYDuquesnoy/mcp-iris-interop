/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements an ISO 8601 year and week level within a time dimension.
/// This represents the week number (0 through 53) of a given year.<br/>
/// The key value for this level takes the form "YYYYWnn"
Class %DeepSee.Time.Partial.WeekYear Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
{

Parameter DIMTYPE = "week";

Parameter CALENDAR As STRING = "partial";

/// Return true if this level supports a NOW member.
ClassMethod %SupportsNOW() As %Boolean
{
	Quit 1
}

/// Convert a partial date value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case, we convert yyyy-mm-dd to an ISO Week: YYYYWnn
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pTimeOffset As %String = "") As %Integer
{
	//$S(pTime="":"",pTime=$$$DeepSeeNullTimeMarker:$$$DeepSeeNullTimeMarker,1:##class(%DeepSee.Time.Partial.WeekYear).ISOWEEK(pTime))
	If (pTime="") {
		Set tKey = ""
	}
	ElseIf (pTime=$$$DeepSeeNullTimeMarker) {
		Set tKey = $$$DeepSeeNullTimeMarker
	}
	Else {
		Set tYear = +$P(pTime,"-",1)
		Set tMonth = +$P(pTime,"-",2)
		Set tDay = +$P(pTime,"-",3)
		
		If (tMonth&&tDay) {
			Set tKey = ##class(%DeepSee.Time.Partial.WeekYear).ISOWEEK(pTime)
		}
		Else {
			// The week cannot be determined
			Set tKey = tYear _ "W00"
		}
	}

	Quit tKey
}

/// Return the total number of members within this level.<br/>
ClassMethod %Count(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %Integer
{
	Set tCount = 54		// 53 weeks + 1 "unknown"
	Quit tCount
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "WeekYear"
}

/// Convert a level key value to a display value.
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pOffset As %String = "") As %String
{
	Set tValue = ""
	Try {
		// test for valid key
		If ($$$UPPER($E(pKey,1,3))="NOW") {
			// Convert the special NOW member to the format of an indexed key
			Set pKey = ..%ValueToKey(pKey,,pOffset)
		}
		If (pKey'="") {		// DP-403993 - Added to match the logic in %DeepSee.Time.WeekYear
			Set tYear = +$E(pKey,1,4)
			If $IsValidNum(tYear) {
				// The key will have a normalized "W" so they are the same in all languages.
				// The value will have the first letter of the localized translation of "Week".
				Set tWeek = +$P(pKey,"W",2)
				If $IsValidNum(tWeek) {
					If ((tWeek>=0)&&(tWeek<=..ISOWEEKSINYEAR(tYear))) {
						Set tValue = tYear_$E($$$Text("Week"))_$$$iscPadZero(tWeek,2)
					}
				}
			}
		}
	}
	Catch(ex) {
		Set tValue = ""
	}
	Quit tValue
}

/// Convert a level display value to its corresponding key value.
/// Return "" if there is no corresponding key.
ClassMethod %ValueToKey(pValue As %String, pFormat As %String = "", pOffset As %String = "") As %Integer
{
	Set tKey = ""
	Try {
		If ($$$UPPER($E(pValue,1,3))="NOW") {
			If ($P(pValue,"+",2)'="") {
				Set tNOWH = $H + ($P(pValue,"+",2)*7)
			}
			ElseIf ($P(pValue,"-",2)'="") {
				Set tNOWH = $H - ($P(pValue,"-",2)*7)
			}
			Else {
				Set tNOWH = $H
			}
			Set tKey = ..%Convert($ZD(tNOWH,3),pOffset)
		}
		Else {
			Set tYear = +$E(pValue,1,4)
			If $IsValidNum(tYear) {
				// The key will have a normalized "W" so they are the same in all languages.
				// The value will have the first letter of the localized translation of "Week".
				Set tWeek = +$P(pValue,$E($$$Text("Week")),2)
				If $IsValidNum(tWeek) {
					Set tKey = tYear_"W"_$$$iscPadZero(tWeek,2)
				}
			}
		}
	}
	Catch {
		Set tKey = ""
	}
	Quit tKey
}

/// Convert a week into starting and ending base values (in partial date ODBC format).<br/>
ClassMethod %KeyToBaseRange(pKey As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	Set (pStart,pEnd) = ""
	Set tSC = $$$OK
	Try {
		// JMD1482
		If (pKey=$$$DeepSeeNullTimeMarker) {
			Quit
		}
		Do ..ISOWEEKToRange(pKey,.pStart,.pEnd)
		
		Set pStart = pStart
		Set pEnd = pEnd
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

	// Find weeks within range
	Set tStart = ..%Convert(pStartRange,pTimeOffset)
	Set tEnd = ..%Convert(pEndRange,pTimeOffset)
	Set tStartYear = +$E(tStart,1,4)
	Set tEndYear = +$E(tEnd,1,4)

	Set n = 0
	For y = tStartYear:1:tEndYear {
		Set tStartWeek = $S(y=tStartYear:+$P(tStart,"W",2),1:1)
		Set tEndWeek = $S(y=tEndYear:+$P(tEnd,"W",2),1:..ISOWEEKSINYEAR(y))
		For w = tStartWeek:1:tEndWeek {
			Set tKey = y_"W"_$$$iscPadZero(w,2)
			Set tValue = ..%KeyToValue(tKey,pFormat,pTimeOffset)
			Set n = n + 1
			Set pList(n) = $LB(tValue,tKey)	// value,key
		}
	}
	Quit $$$OK
}

/// Return, via <var>pRelatedKey</var> a key within this level
/// related to <var>pKey</var>.<br/>
ClassMethod %GetRelatedKey(Output pRelatedKey As %String, pCube As %String, pFact As %String, pKey As %String, pRelation As %String, pOffset As %Integer = "", pEndKey As %String = "", pTimeOffset As %String = "") As %Status
{
	Do ..ISOWEEKToRange(pKey,.tStart,.tEnd)

	Set tWeek = +$P(pKey,"W",2)
	
	If ('tWeek) {
		// DTB686 - Unknown key
		Set pRelatedKey = pKey
	}
	ElseIf (pRelation = "lead") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		Set tOffsetStart = $ZD($ZDH(tStart,3)+(tOffset*7),3)
		Set pRelatedKey = ..%Convert(tOffsetStart,pOffset)		// DTB686
	}
	ElseIf (pRelation = "lag") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		Set tOffsetStart = $ZD($ZDH(tStart,3)-(tOffset*7),3)
		Set pRelatedKey = ..%Convert(tOffsetStart,pOffset)		// DTB686
	}
	ElseIf (pRelation = "first") {
		If (pEndKey="") {
			Set tSC = ..%GetNthKey(.pRelatedKey, pCube, pFact, pRelation)
		}
		Else {
			Set tOffset = $S(pOffset="":0,1:+pOffset)
			Set tOffsetStart = $ZD($ZDH(tStart,3)+(tOffset*7),3)
			Set pRelatedKey = ..%Convert(tOffsetStart,pTimeOffset)
		}
	}
	ElseIf (pRelation = "last") {
		If (pEndKey="") {
			Set tSC = ..%GetNthKey(.pRelatedKey, pCube, pFact, pRelation)
		}
		Else {
			Do ..ISOWEEKToRange(pEndKey,.tStart,.tEnd)
			Set tOffset = $S(pOffset="":0,1:+pOffset)
			Set tOffsetEnd = $ZD($ZDH(tEnd,3)-(tOffset*7),3)
			Set pRelatedKey = ..%Convert(tOffsetEnd,pTimeOffset)
		}
	}
	Else {
		Quit ##super(.pRelatedKey,.pCube,pFact,pKey,pRelation,pOffset,pEndKey,pTimeOffset)
	}
	Quit $$$OK
}

/// Return the number of ISO weeks within a given year.
ClassMethod ISOWEEKSINYEAR(pYear As %Integer) As %Integer
{
	// Find DOW for Jan 1 and Dec 31
	Set tDOWJan1 = +$P($ZDT($ZDTH(pYear_"-01-01",3),10)," ",1)
	Set tDOWDec31 = +$P($ZDT($ZDTH(pYear_"-12-31",3),10)," ",1)

	// If either day is a thursday, then the year has 53 weeks
	Quit $S((tDOWJan1=4)||(tDOWDec31=4):53,1:52)
}

/// Return the ISO day of week for a given ODBC date value: Monday = 1, Sunday = 7.
ClassMethod ISODOW(pDate As %String) As %Integer
{
	Set tYear = +$P(pDate,"-",1)
	Set tMonth = +$P(pDate,"-",2)
	Set tDay = +$P(pDate,"-",3)
	
	If (tMonth)&&(tDay) {
		Set tDOW = +$P($ZDT($ZDH(pDate,3),10)," ",1)
		Quit $S(tDOW=0:7,1:tDOW)
	}
	Else {
		Quit 0		// "Unknown" date component, unable to assign an ISO D.O.W.
	}
}

/// Compute the ISO week number (with no year) for a given ODBC date value.
ClassMethod ISOWEEKNUM(pDate As %String) As %Integer
{
	// WAL125 -- protect against null value or 0
	If (pDate="") {
		Quit ""
	}
	ElseIf ((+pDate)=0) {
		Quit 0
	}
	Do ..ISOWEEK(pDate,.tWeek)
	Quit tWeek
}

/// Compute the ISO week number and corresponding year for a given ODBC partial date value.
/// Returns the ISO compatible display form of the week: YYYYWnn.<br/>
ClassMethod ISOWEEK(pDate As %String, Output pWeek As %Integer, Output pYear As %Integer) As %String
{
	// JMD1482
	If ((+pDate)=0) {
		Quit ""
	}
	Set tYear = +$P(pDate,"-",1)
	Set tMonth = +$P(pDate,"-",2)
	Set tDay = +$P(pDate,"-",3)
	
	If 'tMonth||'tDay {
		// The week number cannot be known if the date is not complete
		Quit tYear_"W00"
	}

	Set tDateH = $ZDH(pDate,3)

	// find first thursday in given year
	Set pYear = tYear
	Set tJAN1H = +$ZDTH(pYear_"-01-01",3)
	Set tJAN1DOW = ..ISODOW($ZD(tJAN1H,3))
	If (tJAN1DOW<=4) {
		Set tFirstThuH = tJAN1H + (4 - tJAN1DOW)
	}
	Else {
		Set tFirstThuH = tJAN1H + (11 - tJAN1DOW)
	}

	// find thursday in *this* week
	Set tThisDOW = ..ISODOW(pDate)
	Set tThuH = tDateH + (4 - tThisDOW)

	// number of weeks between thursdays
	Set pWeek = ((tThuH - tFirstThuH)\7)+1

	If (pWeek<1) {
		Set pYear = pYear - 1
		Set pWeek = ..ISOWEEKSINYEAR(pYear)
	}
	ElseIf ((pWeek>52)&&(..ISOWEEKSINYEAR(pYear)<53)) {
		Set pYear = pYear + 1
		Set pWeek = 1
	}
	Quit pYear_"W"_$$$iscPadZero(pWeek,2)
}

/// For a given ISOWEEK (YYYYWnn), find its start and end dates. Dates are returned in ODBC format
ClassMethod ISOWEEKToRange(pWeek As %String, Output pStart As %String, Output pEnd As %String)
{
	Set pStart="",pEnd=""
	Quit:pWeek=""
	Set tYear = +$E(pWeek,1,4)
	Set tWeek = +$P(pWeek,"W",2)

	// find first thursday in given year
	Set tJAN1H = $ZDH(tYear_"-01-01",3)
	Set tJAN1DOW = ..ISODOW($ZD(tJAN1H,3))
	If (tJAN1DOW<=4) {
		Set tFirstThuH = tJAN1H + (4 - tJAN1DOW)
	}
	Else {
		Set tFirstThuH = tJAN1H + (11 - tJAN1DOW)
	}

	// Find monday of first week in year and add week offset to it
	If ('tWeek) {
		// DTB686 -  Unknown key
		Set pStart = tYear _ "-00-00"
		Set pEnd = pStart
	}
	Else {
		Set tStart = (tFirstThuH - 3) + ((tWeek-1)*7)
		Set pStart = $ZD(tStart,3)
		Set pEnd = $ZD(tStart+6,3)
	}
}

}
