/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a DayOfWeek level within a time dimension.
/// This represents the DayOfWeek number (1 through 7) independent of year.
Class %DeepSee.Time.Partial.DayOfWeek Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
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
/// In this case, we convert partial to a day of week number:
/// That is convert to a number 1 through 7.
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pTimeOffset As %String = "") As %Integer
{
	// tFirstDayofWeek = 0 to 6 (Sunday to Saturday)
	set tFirstDayOfWeek=(-($system.SQL.DAYOFWEEK(62997)-1)#7 + 1 )#7
	
	Set tYear = +$P(pTime,"-",1)
	Set tMonth = +$P(pTime,"-",2)
	Set tDay = +$P(pTime,"-",3)
	
	If (pTime="") {
		Set tDayOfWeek = ""
	}
	ElseIf (pTime=$$$DeepSeeNullTimeMarker) {
		Set tDayOfWeek = $$$DeepSeeNullTimeMarker
	}
	ElseIf (tYear && tMonth && tDay) {
		Set tDayOfWeek = $ZD($ZDH(tYear_"-"_tMonth_"-"_tDay,3),10) + 1
		Set tDayOfWeek = tDayOfWeek-1-tFirstDayOfWeek#7+1
	}
	Else {
		Set tDayOfWeek = 0
	}
	
	// adjust tDay based on tFirstDayOfWeek
	Quit tDayOfWeek
}

/// Return the total number of members within this level.<br/>
ClassMethod %Count(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %Integer
{
	Set tCount = 7
	Quit tCount
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "DayOfWeek"
}

/// Convert a level key value to a display value.
/// E.g., "Monday"
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pOffset As %String = "") As %String
{
	// tFirstDayofWeek = 0 to 6 (Sunday to Saturday)
	set tFirstDayOfWeek=(-($system.SQL.DAYOFWEEK(62997)-1)#7 + 1 )#7
	Set tValue = ""
	Try {
		If ($$$UPPER($E(pKey,1,3))="NOW") {
			Set pKey = ..%ValueToKey(pKey,pFormat,pOffset)
		}
		
		If ((pKey>=1) && (pKey<=7)) {
			// 2000-10-08 is a Sunday, so use 2000-10 for the month
			Set tH = $ZDTH("2000-10-" _ $$$iscPadZero(7+pKey+tFirstDayOfWeek,2),3)
			If pFormat="d" {
				Set tText = pKey			// e.g.; 1
			}
			ElseIf pFormat="dd" {
				Set tText = $$$iscPadZero(pKey,2)		// e.g.; 01
			}
			ElseIf pFormat="ddd" {
				// Short day name
				Set tText = $ZDT(tH,11) 	// e.g.; Mon
			}
			Else  {
				// default format to full day name
				Set tText = $ZDT(tH,12) 	// e.g.; Monday
			}
			
			Set tValue = $P(tText," ",1)
		}
		ElseIf ('pKey) {
			// Unknown day of week
			If pFormat="d" {
				Set tValue = pKey			// e.g.; 1
			}
			ElseIf pFormat="dd" {
				Set tValue = $$$iscPadZero(pKey,2)		// e.g.; 01
			}
			ElseIf pFormat="ddd" {
				// Short day name
				Set tValue = $E($$$Text("Unknown"),1,3) 	// e.g.; Unk
			}
			Else  {
				// default format to full day name
				Set tValue = $$$Text("Unknown") 	// e.g.; Unknown
			}
		}

	}
	Catch(ex) {
		Set tValue = ""
	}
	
	Quit tValue
}

/// Convert a level display value (n) to its corresponding key value.
/// Return "" if there is no corresponding key.
ClassMethod %ValueToKey(pValue As %String, pFormat As %String = "", pOffset As %String = "") As %Integer
{
	Set tKey = ""
	Try {
		If ($$$UPPER($E(pValue,1,3))="NOW") {
			Set tDay = ..%Convert($ZD($H,3),pOffset)

			If ($P(pValue,"+",2)'="") {
				Set tDay = tDay + $P(pValue,"+",2)
				While (tDay > 7) {
					Set tDay = tDay - 7
				}
			}
			ElseIf ($P(pValue,"-",2)'="") {
				Set tDay = tDay - $P(pValue,"-",2)
				While (tDay < 1) {
					Set tDay = tDay + 7
				}
			}
			
			Set tKey = tDay
		} 
		Else {
			// Day of Week
			If pFormat="d" {
				Set tKey = pValue
			}
			ElseIf pFormat = "dd" {
				Set tKey = +pValue
			}
			If pFormat="ddd" {
				If (pValue=$E($$$Text("Unknown"),1,3)) {
					Set tKey=0
				}
				Else {
					Set tKey = ##class(%DeepSee.Utils).%DayOfWeekToNumber(pValue,0)
				}
			} Else {
				If (pValue=$$$Text("Unknown")) {
					Set tKey=0
				}
				Else {
					Set tKey = ##class(%DeepSee.Utils).%DayOfWeekToNumber(pValue,1)
				}
			}
		}
	}
	Catch {
		Set tKey = ""
	}
	Quit tKey
}

/// Convert a logical day of week number into starting and ending
/// base values (in partial date format).<br/>
/// As this dimension is independent of year, we use year 2000 as 
/// the basis of calculations.
ClassMethod %KeyToBaseRange(pKey As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	Set (pStart,pEnd) = ""
	Set tSC = $$$OK
	Try {
		// 2000-01-02 is a Sunday
		Set tYear = 2000
		Set tMonth = 1
		set tDay = $S('+pKey:0,1:pKey+1) 		// DTB688
		Set pStart = tYear_"-"_$$$iscPadZero(tMonth,2)_"-"_$$$iscPadZero(tDay,2)
		Set pEnd = pStart
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
		quit ..%GetAllMembers(.pList,pCube,pFact,pStartRange,pEndRange,pFormat)
	}

	// Find days of week within given range
	// At most, return 1 through 7
	Set tUseAll = 0
	Set tStartDay = +$P(pStartRange,"-",3)
	Set tEndDay = +$P(pEndRange,"-",3)
	If 'tStartDay || 'tEndDay || (($ZDH(pEndRange,3)-$ZDH(pStartRange,3))>6) {
		Set tUseAll = 1
	}

	Set tStart = ..%Convert(pStartRange,pTimeOffset)
	Set tEnd = ..%Convert(pEndRange,pTimeOffset)
	If (tEnd < tStart) || tUseAll {
		Set tStart = 0		// DTB688 - Include Unknown
		Set tEnd = 7
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
		// DTB686 - Unknown key
		Set pRelatedKey=pKey
	}
	ElseIf (pRelation = "lead") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		// JMD1510
		Set pRelatedKey = pKey + tOffset
		Set:pRelatedKey>7 pRelatedKey = ""
	}
	ElseIf (pRelation = "lag") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		// JMD1510
		Set pRelatedKey = pKey - tOffset
		Set:pRelatedKey<1 pRelatedKey = ""
	}
	ElseIf (pRelation = "first") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = (((pKey + tOffset) - 1) # 7) + 1
	}
	ElseIf (pRelation = "last") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = (((pEndKey - tOffset) - 1) # 7) + 1
	}
	Else {
		Quit ##super(.pRelatedKey,.pCube,pFact,pKey,pRelation,pOffset,pEndKey,pTimeOffset)
	}
	Quit $$$OK
}

}
