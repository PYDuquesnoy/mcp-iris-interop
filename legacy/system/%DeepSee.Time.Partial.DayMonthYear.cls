/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a Day level within a time dimension.
/// This is a specific day value that includes month and year.
Class %DeepSee.Time.Partial.DayMonthYear Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
{

Parameter DIMTYPE;

Parameter CALENDAR As STRING = "partial";

/// Convert a partial date ODBC value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case we convert partial date to the form YYYY-MM-DD.
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pTimeOffset As %String = "") As %Integer
{
	//$S(pTime="":"",pTime=$$$DeepSeeNullTimeMarker:$$$DeepSeeNullTimeMarker,1:pTime)
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
		Set tDay = +$P(pTime,"-",3)
		
		Set tKey = tYear _ "-" _ $$$iscPadZero(tMonth,2) _ "-" _ $$$iscPadZero(tDay,2)
	}
	
	Quit tKey
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "DayMonthYear"
}

/// Convert a level key value (yyyy[-mm[-dd]]) to a display value. Partial dates support.
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pTimeOffset As %String = "") As %String
{
	If ($$$UPPER($E(pKey,1,3))="NOW") {
		Set pKey = ..%ValueToKey(pKey)
	}

	Set tYear = $P(pKey,"-",1)
	Set tMonth = $P(pKey,"-",2)
	Set tDay = $P(pKey,"-",3)
	
	If (tDay'="")&&(tDay'="00") {
		If (pFormat'="") {
			// Format supplied
			Set tText = ##class(%DeepSee.Utils).%FormatPartialDate(pKey,pFormat)
		}
		Else {
			// Format is not supplied but the key is complete
			Set tHorologDate = $ZDH(pKey,3)
			Set tFormat = ..%FormatToZDTCode("",6)
			Set tText = $ZDT(tHorologDate,tFormat)
		}
	}
	Else {
		If (pFormat="") {
			Set pFormat = "mmm dd yyyy"
		}

		Set tText = ##class(%DeepSee.Utils).%FormatPartialDate(pKey,pFormat)
	}

	Quit tText
}

/// Convert a level display value to its corresponding key value.
/// Return "" if there is no corresponding key.
ClassMethod %ValueToKey(pValue As %String, pFormat As %String = "", pOffset As %String = "") As %Integer
{
	Set tKey = ""

	Try {
		// Mmm Dd (Yyyy)
		// Make sure we return "" if this is NOT a valid date
		If ($$$UPPER($E(pValue,1,3))="NOW") {
			Set tKeyH = $H
			// JMD986: special case for NOW-1y
			Set tInterval = $E(pValue,4,$L(pValue))
			If (tInterval'="") {
				Set tUnits = $Case($$$UPPER($E(pValue,$L(pValue))),"Y":"y","M":"m",:"")
				If (tUnits'="") {
					Set tInterval = $E(tInterval,1,$L(tInterval)-1)
				}
				Else {
					Set tUnits = "d"
				}
				Set tKeyH = ##class(%DeepSee.Utils).%AddTimeInterval(tKeyH,tInterval_tUnits)
			}
			Set tKey = $ZD(tKeyH,3)
		}
		ElseIf (pFormat'="") {
			Set tKey = ##class(%DeepSee.Utils).%UnformatPartialDate(pValue,pFormat)
		}
		Else {
			Set tKey = $ZDTH(pValue,..%FormatToZDTCode("",6),,,,,,,,"")
		}
	}
	Catch {
		Set tKey = ""
	}
	Quit tKey
}

/// Convert a day of month ($H) into starting and ending
/// base values (in $H format).
ClassMethod %KeyToBaseRange(pKey As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	// JMD1409
	If (pKey=$$$DeepSeeNullTimeMarker) {
		Set (pStart,pEnd) = ""
	}
	Else {
		// JMD947: return complete range of day
		Set pStart = pKey
		Set pEnd = pKey
	}
	Quit $$$OK
}

/// Return an array of members of this level.
ClassMethod %GetLevelMembers(Output pList As %List, pCube As %String, pFact As %String, pStartRange As %Date, pEndRange As %Date, pTimeOffset As %String = "", pFormat As %String = "") As %Status
{
	If (pStartRange = "") {
		Quit ..%GetAllMembers(.pList,pCube,pFact,pStartRange,pEndRange,pFormat)
	}
	Set tCubeIndex = $$$DeepSeeIndex(pCube)		// DTB521
	
	// JMD1330 if slicer or nonempty in context, limit to values in the index
	// DTB185 - If the start and end keys are the same, do not recalculate
	Set tNonEmpty = $S($IsObject($G(%axisObject))&&%axisObject.nonEmpty:1,1:0)
	Set tUseMinimalSet = (tNonEmpty || +$G(%isSlicer))
	If ((pTimeOffset="") && tUseMinimalSet) && '(pStartRange=pEndRange) {
		// JMD1374: skip if we are being asked for one value
		// this makes Lag/Lead work on bogus dates
		If (pStartRange'=pEndRange) {
			Do ..%GetAllMembers(.tStartList,pCube,pFact,"FIRST")
			Set tDate = $LG($G(tStartList(1)),2)
			If ((tDate'="")&&(tDate]]pStartRange)) {
				Set pStartRange = tDate
			}
			If (pEndRange'="") {
				Do ..%GetAllMembers(.tEndList,pCube,pFact,"LAST")
				Set tDate = $LG($G(tEndList(1)),2)
				If ((tDate'="")&&(pEndRange]]tDate)) {
					Set pEndRange = tDate
				}
			}
		}
	}
	
	Set n = 0
	Set tKey = pStartRange
	While (tKey'="")&&((pEndRange]]tKey)||(pEndRange=tKey)) {		// DTB688 - Include ranges that start and end on the same date
		If (tUseMinimalSet || 'tNonEmpty) {
			Set tValue = ..%KeyToValue(tKey,pFormat)
			Set pList(n) = $LB(tValue,tKey)	// value,key
		}
		set n = n+1
		
		Set tKey = $O($$$DeepSeeIndexGLVN(tCubeIndex,pFact,tKey))
	}
	
	// DTB521 - Fill in the original endpoints if no data was found in the range
	If '$D(pList) {
		Set pList(1) = $LB("NO MEMBER","NO MEMBER")
	}
	
	Quit $$$OK
}

/// Return, via <var>pRelatedKey</var> a key within this level
/// related to <var>pKey</var>.<br/>
ClassMethod %GetRelatedKey(Output pRelatedKey As %String, pCube As %String, pFact As %String, pKey As %String, pRelation As %String, pOffset As %Integer = "", pEndKey As %String = "", pTimeOffset As %String = "") As %Status
{
	// DTB686 - Check for partial key
	Set tYear = +$P(pKey,"-",1)
	Set tMonth = +$P(pKey,"-",2)
	Set tDay = +$P(pKey,"-",3)
	
	Set tIncomplete=0
	If ('tMonth)||('tDay){
		Set tIncomplete = 1
	}
	Else {
		Set tKeyH = $ZDH(pKey,3)
	}

	If (pKey=$$$DeepSeeNullTimeMarker)||tIncomplete {
		Set pRelatedKey = pKey
	}
	ElseIf (pRelation = "lead") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		Set pRelatedKey = $ZD(tKeyH + tOffset,3)		// DTB686
	}
	ElseIf (pRelation = "lag") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		Set pRelatedKey = $ZD(tKeyH - tOffset,3)		// DTB686
	}
	ElseIf (pRelation = "first") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = $ZD(tKeyH + tOffset,3)		// DTB686
	}
	ElseIf (pRelation = "last") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = $ZD($ZDH(pEndKey,3) - tOffset,3)		// DTB686
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
