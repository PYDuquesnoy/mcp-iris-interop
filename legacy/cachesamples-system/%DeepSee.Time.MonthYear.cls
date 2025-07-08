/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a Month level within a time dimension.
/// This represents a specific month within a specific year.
Class %DeepSee.Time.MonthYear Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
{

Parameter DIMTYPE = "month";

/// Convert a $H value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case, we convert $H to a logical year+month number:
/// That is, Year+Month in the form YYYYMM
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pTimeOffset As %String = "") As %Integer [ CodeMode = expression ]
{
$S(pTime="":"",pTime=$$$DeepSeeNullTimeMarker:$$$DeepSeeNullTimeMarker,1:(+$E($ZDT(pTime,3),1,4))_$$$iscPadZero($E($ZDT(pTime,3),6,7),2))
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "MonthYear"
}

/// Convert a level key value to a display value.
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pTimeOffset As %String = "") As %String
{
	Set tValue = ""
	Try {
		If ($$$UPPER($E(pKey,1,3))="NOW") {
			Set pKey = ..%ValueToKey(pKey)
		}
		If ($L(pKey)=6) {
			// key must have 6 digits
			If ((pKey'="")&&(pFormat'="")) {
				Set tH = $ZDTH($E(pKey,1,4) _ "-" _ $E(pKey,5,6) _ "-01",3)
				Set tValue = ##class(%DeepSee.Utils).%FormatDate(tH,pFormat)
			}
			Else {
				Set tH = $ZDTH($E(pKey,1,4) _ "-" _ $E(pKey,5,6) _ "-01",3)
				Set tText = $ZDT(tH,6) 	// e.g.; Jul 4 2008
				Set tValue = $P(tText," ",1) _ "-" _ $P(tText," ",3)
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
			Set tKey = ..%Convert($H)
			Set tYear = +$E(tKey,1,4)
			Set tMonth =  +$E(tKey,5,6)
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
			Set tKey = tYear_$$$iscPadZero(tMonth,2)
			Quit
		}

		If (pFormat'="") {
			Set tH = ##class(%DeepSee.Utils).%UnformatDate(pValue,pFormat)
			Set tKey = $S(tH="":"",1:$ZDT(tH,3))
			Set:tKey'="" tKey = $E(tKey,1,4)_ $$$iscPadZero($E(tKey,6,7),2)
		}
		Else {
			// Mmm-Yyyy
			Set pValue = $TR(pValue," ","-")
			Set Mmm = $P(pValue,"-",1)
			Set y = +$P(pValue,"-",2)

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
/// base values (in $H format).
ClassMethod %KeyToBaseRange(pKey As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	Set (pStart,pEnd) = ""
	Set tSC = $$$OK
	Try {
		// JMD1409
		If (pKey=$$$DeepSeeNullTimeMarker) {
			Quit
		}

		Set tYear = +$E(pKey,1,4)
		Set tMonth =  +$E(pKey,5,6)
		Set pStart = $ZDTH(tYear_"-"_$$$iscPadZero(tMonth,2)_"-01",3,,,,,,,,"")
		Set pEnd = $ZDTH(tYear_"-"_$$$iscPadZero(tMonth,2)_"-"_$$$iscPadZero($$$iscDaysInMonth(tYear,tMonth),2)_" 23:59:59",3,,,,,,,,"")

		If (pOffset'="") {
			Set pStart = ##class(%DeepSee.Utils).%AddTimeInterval(pStart,pOffset)
			Set pEnd = ##class(%DeepSee.Utils).%AddTimeInterval(pEnd,pOffset)
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
		Set:tDate'="" tDate = +$ZDTH($E(tDate,1,4)_"-"_$E(tDate,5,6)_"-01",3)
		If ((tDate'="")&&(tDate>+pStartRange)) {
			Set pStartRange = tDate
		}
		If (pEndRange'="") {
			Do ..%GetAllMembers(.tEndList,pCube,pFact,"LAST")
			Set tDate = $LG($G(tEndList(1)),2)
			Set:tDate'="" tDate = +$ZDTH($E(tDate,1,4)_"-"_$E(tDate,5,6)_"-28",3)
			If ((tDate'="")&&(tDate<+pEndRange)) {
				Set pEndRange = tDate
			}
		}
	}

	Set tStartKey = ..%Convert(pStartRange,"-"_pTimeOffset)
	Set tEndKey = ..%Convert(pEndRange,"-"_pTimeOffset)
	Set tStartYear = +$E(tStartKey,1,4)
	Set tEndYear = +$E(tEndKey,1,4)

	Set n = 0
	For y = tStartYear:1:tEndYear {
		Set tStartMonth =  $S(y=tStartYear:+$E(tStartKey,5,6),1:1)
		Set tEndMonth =  $S(y=tEndYear:+$E(tEndKey,5,6),1:12)
		For m = tStartMonth:1:tEndMonth {
			Set tKey = y_$$$iscPadZero(m,2)
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
	If (pKey=$$$DeepSeeNullTimeMarker) {
		Set pRelatedKey = pKey
		Quit $$$OK
	}

	Set tYear = +$E(pKey,1,4)
	Set tMonth =  +$E(pKey,5,6)
	If (pRelation = "lead") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		Set tYear = tYear + (tOffset\12)
		Set tMonth = tMonth + (tOffset # 12)
		If (tMonth > 12) {
			Set tYear = tYear + 1
			Set tMonth = tMonth - 12
		}
		Set pRelatedKey = tYear _ $$$iscPadZero(tMonth,2)
	}
	ElseIf (pRelation = "lag") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		Set tYear = tYear - (tOffset\12)
		Set tMonth = tMonth - (tOffset # 12)
		If (tMonth < 1) {
			Set tYear = tYear - 1
			Set tMonth = tMonth + 12
		}
		Set pRelatedKey = tYear _ $$$iscPadZero(tMonth,2)
	}
	ElseIf (pRelation = "first") {
		If (pEndKey="") {
			Set tSC = ..%GetNthKey(.pRelatedKey, pCube, pFact, pRelation)
		}
		Else {
			Set tOffset = $S(pOffset="":0,1:+pOffset)
			Set tMonth = tMonth + (tOffset # 12)
			Set pRelatedKey = tYear _ $$$iscPadZero(tMonth,2)
		}
	}
	ElseIf (pRelation = "last") {
		If (pEndKey="") {
			Set tSC = ..%GetNthKey(.pRelatedKey, pCube, pFact, pRelation)
		}
		Else {
			Set tYear = +$E(pEndKey,1,4)
			Set tOffset = $S(pOffset="":0,1:+pOffset)
			Set tMonth =  +$E(pEndKey,5,6) - (tOffset # 12)
			Set pRelatedKey = tYear _ $$$iscPadZero(tMonth,2)
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
