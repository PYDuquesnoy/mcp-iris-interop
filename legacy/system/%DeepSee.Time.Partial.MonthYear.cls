/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a Month level within a time dimension.
/// This represents a specific month within a specific year.
Class %DeepSee.Time.Partial.MonthYear Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
{

Parameter DIMTYPE = "month";

Parameter CALENDAR As STRING = "partial";

/// Convert a partial date ODBC value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case, we convert partial date to a logical year+month number:
/// That is, Year+Month in the form YYYY-MM
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pTimeOffset As %String = "") As %Integer
{
	//Quit $S(pTime="":"",pTime=$$$DeepSeeNullTimeMarker:$$$DeepSeeNullTimeMarker,1:$P(pTime,"-",1,2))
	If (pTimeOffset'="") {
		Set pTime = ##class(%DeepSee.Utils).%AddTimeInterval(pTime,pTimeOffset)
	}
	If (pTime="") {
		Set tKey = ""
	}
	ElseIf (pTime=$$$DeepSeeNullTimeMarker) {
		Set tKey = $$$DeepSeeNullTimeMarker
	}
	Else {
		Set tYear = +$P(pTime,"-",1)
		Set tMonth = +$P(pTime,"-",2)
		
		Set tKey = tYear _ "-" _ $$$iscPadZero(tMonth,2)
	}
	
	Quit tKey
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "MonthYear"
}

/// Convert a level key value (yyyy[-mm]) to a display value.
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pTimeOffset As %String = "") As %String
{
	Set tValue = ""
	Try {
		If ($$$UPPER($E(pKey,1,3))="NOW") {
			Set pKey = ..%ValueToKey(pKey)
		}
		
		If $L(pKey)=4 {
			// 4-digit key is an unkown month. Normalize the key.
			Set pKey = pKey _ "-00"
		}

		If ($L(pKey)=7) {
			// key must have 7 digits
			If ((pKey'="")&&(pFormat'="")) {
				Set tValue = ##class(%DeepSee.Utils).%FormatPartialDate(pKey,pFormat)
			}
			Else {
				Set tValue = ##class(%DeepSee.Utils).%FormatPartialDate(pKey,"mmm yyyy")
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
			Set tKey = ..%Convert($ZD($H,3))
			Set tYear = +$P(tKey,"-",1)
			Set tMonth =  +$P(tKey,"-",2)
			If ($P(pValue,"+",2)'="") {
				Set tMonth = tMonth + $P(pValue,"+",2)
				While (tMonth > 12) {
					Set tYear = tYear + 1
					Set tMonth = tMonth - 12
				}
			}
			ElseIf ($P(pValue,"-",2)'="") {
				Set tMonth = tMonth - $P(pValue,"-",2)
				While (tMonth < 1) {
					Set tYear = tYear - 1
					Set tMonth = tMonth + 12
				}
			}
			Set tKey = tYear_"-"_$$$iscPadZero(tMonth,2)
			Quit
		}

		If (pFormat'="") {
			Set tH = ##class(%DeepSee.Utils).%UnformatPartialDate(pValue,pFormat)
			Set tKey = $S(tH="":"",1:$ZDT(tH,3))
			Set:tKey'="" tKey = $E(tKey,1,4) _ "-" _ $$$iscPadZero($E(tKey,6,7),2)
		}
		Else {
			// Yyyy-Mmm
			Set pValue = $TR(pValue," ","-")
			Set Mmm = $P(pValue,"-",2)
			Set y = +$P(pValue,"-",1)

			If (y < 1841) Quit  // most likely mm-dd-yyyy
	
			Set h = $ZDTH(Mmm_" 1 "_y,6,,,,,,,,"")
			If (h '= "") {
				Set tMonth = $E($ZDT(h,3),6,7)
				Set tKey = y_$$$iscPadZero(tMonth,2)
			}
		}
	}
	Catch {
		Set tKey = ""
	}
	Quit tKey
}

/// Convert a month-year value (month-year number) into starting and ending
/// base values (in partial date format).
ClassMethod %KeyToBaseRange(pKey As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	Set (pStart,pEnd) = ""
	Set tSC = $$$OK
	Try {
		// JMD1409
		If (pKey=$$$DeepSeeNullTimeMarker) {
			Quit
		}

		Set tYear = +$P(pKey,"-",1)
		Set tMonth =  +$P(pKey,"-",2)
		
		If 'tMonth {
			// DTB688 - Unknown key returns the unknown date as start and end points
			Set pStart = tYear _ "-00-00"
			Set pEnd = pStart
		}
		Else {
			Set pStart = tYear_"-"_$$$iscPadZero(tMonth,2)_"-01"
			Set pEnd = tYear_"-"_$$$iscPadZero(tMonth,2)_"-"_$$$iscPadZero($$$iscDaysInMonth(tYear,tMonth),2)

			If (pOffset'="") {
				Set pStart = ##class(%DeepSee.Utils).%AddTimeInterval(pStart,pOffset)
				Set pEnd = ##class(%DeepSee.Utils).%AddTimeInterval(pEnd,pOffset)
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

	// JMD1330 if slicer or nonempty in context, limit to values in the index
	// DTB185 - If the start and end keys are the same, do not recalculate
	Set tNonEmpty = $S($IsObject($G(%axisObject))&&%axisObject.nonEmpty:1,1:0)
	If ((pTimeOffset="") && (tNonEmpty || +$G(%isSlicer))) && '(pStartRange=pEndRange) {
		Do ..%GetAllMembers(.tStartList,pCube,pFact,"FIRST")
		Set tDate = $LG($G(tStartList(1)),2)
		Set tMonth = +$P(tDate,"-",2)
		
		If (tDate'="")&&(tMonth) {
			Set tDate = tDate_"-01"
		}
		Else {
			// DTB688 - Unknown dates collate first
			Set tDate = tDate _ "-00"
		}
		
		If ((tDate'="")&&(tDate]]pStartRange)) {
			Set pStartRange = tDate
		}
		If (pEndRange'="") {
			Do ..%GetAllMembers(.tEndList,pCube,pFact,"LAST")
			Set tDate = $LG($G(tEndList(1)),2)
			Set tYear = +$P(tDate,"-",1)
			Set tMonth = +$P(tDate,"-",2)
			
			If (tDate'="")&&(tMonth) {
				Set tDate = tDate_"-28"
			}
			Else {
				// DTB688 - Assign the final date of the year as the stand-in for an unknown month
				Set tDate = tYear _ "-12-31"
			}
			
			If ((tDate'="")&&(pEndRange]]tDate)) {
				Set pEndRange = tDate
			}
		}
	}

	Set tStartKey = ..%Convert(pStartRange,"-"_pTimeOffset)
	Set tEndKey = ..%Convert(pEndRange,"-"_pTimeOffset)
	Set tStartYear = +$P(tStartKey,"-",1)
	Set tEndYear = +$P(tEndKey,"-",1)

	Set n = 0
	For y = tStartYear:1:tEndYear {
		Set tStartMonth =  $S(y=tStartYear:$P(tStartKey,"-",2),1:1)
		Set tEndMonth =  $S(y=tEndYear:$P(tEndKey,"-",2),1:12)
		For m = tStartMonth:1:tEndMonth {
			Set tKey = y_"-"_$$$iscPadZero(m,2)
			Set tValue = ..%KeyToValue(tKey,pFormat,pTimeOffset)
			Set n = n + 1
			Set pList(n) = $LB(tValue,tKey)	// value,key
		}
	}
	Quit $$$OK
}

/// Return, via <var>pRelatedKey</var>, a key within this level related to <var>pKey</var>.<br/>
ClassMethod %GetRelatedKey(Output pRelatedKey As %String, pCube As %String, pFact As %String, pKey As %String, pRelation As %String, pOffset As %Integer = "", pEndKey As %String = "", pTimeOffset As %String = "") As %Status
{
	// JMD1409
	Set tYear = +$P(pKey,"-",1)
	Set tMonth = +$P(pKey,"-",2)		// DTB686 - Check for unknown key
	
	If (pKey=$$$DeepSeeNullTimeMarker)||('tMonth) {
		Set pRelatedKey = pKey
		Quit $$$OK
	}
	ElseIf (pRelation = "lead") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		Set tYear = tYear + (tOffset\12)
		Set tMonth = tMonth + (tOffset # 12)
		If (tMonth > 12) {
			Set tYear = tYear + 1
			Set tMonth = tMonth - 12
		}
		Set pRelatedKey = tYear _ "-" _ $$$iscPadZero(tMonth,2)		// DTB686
	}
	ElseIf (pRelation = "lag") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		Set tYear = tYear - (tOffset\12)
		Set tMonth = tMonth - (tOffset # 12)
		If (tMonth < 1) {
			Set tYear = tYear - 1
			Set tMonth = tMonth + 12
		}
		Set pRelatedKey = tYear _ "-" _ $$$iscPadZero(tMonth,2)		// DTB686
	}
	ElseIf (pRelation = "first") {
		If (pEndKey="") {
			Set tSC = ..%GetNthKey(.pRelatedKey, pCube, pFact, pRelation)
		}
		Else {
			Set tOffset = $S(pOffset="":0,1:+pOffset)
			Set tMonth = tMonth + (tOffset # 12)
			Set pRelatedKey = tYear _ "-" _ $$$iscPadZero(tMonth,2)		// DTB686
		}
	}
	ElseIf (pRelation = "last") {
		If (pEndKey="") {
			Set tSC = ..%GetNthKey(.pRelatedKey, pCube, pFact, pRelation)
		}
		Else {
			Set tYear = +$P(pEndKey,"-",1)
			Set tOffset = $S(pOffset="":0,1:+pOffset)
			Set tMonth =  +$P(pEndKey,"-",2) - (tOffset # 12)
			Set pRelatedKey = tYear _ "-" _ $$$iscPadZero(tMonth,2)		// DTB686
		}
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
