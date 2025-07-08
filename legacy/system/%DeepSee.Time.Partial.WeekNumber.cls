/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a ISO 8601 week number level within a time dimension.
/// This represents the Week number (1 through 53) independent of year.
Class %DeepSee.Time.Partial.WeekNumber Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
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
/// In this case, we convert a prtial date to a week number:
/// That is convert to a number 1 through 53. If the partial date is not complete,
/// it will be converted to the "0" week number for Unknown.
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pTimeOffset As %String = "") As %Integer
{
	//$S(pTime="":"",pTime=$$$DeepSeeNullTimeMarker:$$$DeepSeeNullTimeMarker,1:##class(%DeepSee.Time.Partial.WeekYear).ISOWEEKNUM(pTime))
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
			Set tKey = ##class(%DeepSee.Time.Partial.WeekYear).ISOWEEKNUM(pTime)
		}
		Else {
			// The week cannot be determined
			Set tKey = 0
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
	Quit "WeekNumber"
}

/// Convert a level key value to a display value.
/// E.g., "1"
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pOffset As %String = "") As %String
{
	Set tValue = ""
	Try {
		If ($$$UPPER($E(pKey,1,3))="NOW") {
			Set pKey = ..%ValueToKey(pKey,,pOffset)
		}
		
		If ((pKey'="")&&(+pKey>=0)&&(+pKey<54)) {
			Set tValue = +pKey
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
			Set tKey = +pValue
		}
	}
	Catch {
		Set tKey = ""
	}
	Quit tKey
}

/// Convert a logical week number into starting and ending
/// base values (in partial date ODBC format).<br/>
/// As this dimension is independent of year, we use year 1998 (a 53-week year) as 
/// the basis of calculations.
ClassMethod %KeyToBaseRange(pKey As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	Set (pStart,pEnd) = ""
	Set tSC = $$$OK
	Try {
		If 'pKey {
			// DTB688 - Account for unknown key
			Set pStart = "1998-00-00"
			Set pEnd = "1998-00-00"
		}
		Else {
			Set tWeek = "1998W"_$$$iscPadZero(pKey,2)
			Do ##class(%DeepSee.Time.Partial.WeekYear).ISOWEEKToRange(tWeek,.pStart,.pEnd)
			
			// DTB688 - ISO weeks can begin and end in a different year! Do not let this happen with the week numbers
			If ("1998-01-01" ]] pStart) {
				Set pStart = "1998-01-01"
			}
			If (pEnd ]] "1998-12-31") {
				Set pEnd = "1998-12-31"
			}
		}
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

	// Find weeks within given range
	// At most, return 0 through 53
	Set tStart = ..%Convert(pStartRange,pTimeOffset)
	Set tEnd = ..%Convert(pEndRange,pTimeOffset)
	If (tEnd < tStart) {
		Set tStart = 0
		Set tEnd = 53
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
		Set pRelation=pKey
	}
	ElseIf (pRelation = "lead") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		//Set pRelatedKey = (((pKey + tOffset) - 1) # 53) + 1
		// JMD1510
		Set pRelatedKey = pKey + tOffset
		Set:pRelatedKey>53 pRelatedKey = ""
	}
	ElseIf (pRelation = "lag") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		//Set pRelatedKey = (((pKey - tOffset) - 1) # 53) + 1
		// JMD1510
		Set pRelatedKey = pKey - tOffset
		Set:pRelatedKey<1 pRelatedKey = ""
	}
	ElseIf (pRelation = "first") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = (((pKey + tOffset) - 1) # 53) + 1
	}
	ElseIf (pRelation = "last") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = (((pEndKey - tOffset) - 1) # 53) + 1
	}
	Else {
		Quit ##super(.pRelatedKey,.pCube,pFact,pKey,pRelation,pOffset,pEndKey,pTimeOffset)
	}
	Quit $$$OK
}

}
