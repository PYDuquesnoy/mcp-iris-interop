/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a Year level within a time dimension.
Class %DeepSee.Time.Year Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
{

Parameter DIMTYPE = "year";

/// Convert a $H value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case, we convert $H to the year number.
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pOffset As %String = "") As %Integer [ CodeMode = expression ]
{
$S(pTime="":"",pOffset="":+$E($ZDT(pTime,3),1,4),1:+$E($ZDT(##class(%DeepSee.Utils).%AddTimeInterval(pTime,pOffset),3),1,4))
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "Year"
}

/// Convert a level key value to a display value.
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pOffset As %String = "") As %String
{
	If ($$$UPPER($E(pKey,1,3))="NOW") {
		Set pKey = ..%ValueToKey(pKey,,pOffset)
	}

	// if there are more than 4 digits, then this is not a year
	If ($L(pKey)>4) {
		Quit ""
	}
	If ((pKey'="")&&(pFormat'="")) {
		Set tH = +$ZDTH(pKey_"-01-01",3,,,,,,,,"")
		Set tValue = ##class(%DeepSee.Utils).%FormatDate(tH,pFormat)
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
	Set tKey = ""

	If ($$$UPPER($E(pValue,1,3))="NOW") {
		
		// + WAL037 -- find the offset sign and invert it
		Set i=1 Set tOrigSign="" While($E(pOffset,i)?1P) {  Set tOrigSign = tOrigSign_$e(pOffset,i) Set i = $i(i) }
		Set tSign = $CASE(tOrigSign,"":"-","+":"-","-":"","--":"-",:"Unknown") 
		If ((tSign'="Unknown")&&(pOffset'="")) {
			Set pOffset = tSign _ $E(pOffset,$L(tOrigSign)+1,9999999)	
		}
		// - WAL037
	
		Set tKey = ..%Convert($H,pOffset)
		If ($P(pValue,"+",2)'="") {
			Set tKey = tKey + $P(pValue,"+",2)
		}
		ElseIf ($P(pValue,"-",2)'="") {
			Set tKey = tKey - $P(pValue,"-",2)
		}
	}
	ElseIf (pFormat'="") {
		Set tH = ##class(%DeepSee.Utils).%UnformatDate(pValue,pFormat)
		Set tKey = $S(tH="":"",1:+$ZDT(tH,3))
	}
	ElseIf ((+pValue>1900)&&(+pValue<3000)) {
		Set tKey = +pValue
	}
	Quit tKey
}

/// Convert a year value (year number) into starting and ending
/// base values (in $H format).
ClassMethod %KeyToBaseRange(pValue As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	Set (pStart,pEnd) = ""
	Set tSC = $$$OK
	Try {
		// JMD1409
		If (pValue=$$$DeepSeeNullTimeMarker) {
			Quit
		}

		Set pStart = $ZDTH(pValue_"-01-01",3,,,,,,,,"")
		Set pEnd = $ZDTH(pValue_"-12-31 23:59:59",3,,,,,,,,"")

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
ClassMethod %GetLevelMembers(Output pList As %List, pCube As %String, pFact As %String, pStartRange As %Date, pEndRange As %Date, pOffset As %String = "", pFormat As %String = "") As %Status
{
	If (pStartRange = "") {
		Quit ..%GetAllMembers(.pList,pCube,pFact,pStartRange,pEndRange,pFormat)
	}

	// JMD1330 if slicer or nonempty in context, limit to values in the index
	// DTB185 - If the start and end keys are the same, do not recalculate
	Set tNonEmpty = $S($IsObject($G(%axisObject))&&%axisObject.nonEmpty:1,1:0)
	If ((pOffset="") && (tNonEmpty || +$G(%isSlicer))) && '(pStartRange=pEndRange) {
		Do ..%GetAllMembers(.tStartList,pCube,pFact,"FIRST")
		Set tDate = $LG($G(tStartList(1)),2)
		Set:tDate'="" tDate = +$ZDTH(tDate_"-01-01",3)
		If ((tDate'="")&&(tDate>+pStartRange)) {
			Set pStartRange = tDate
		}
		If (pEndRange'="") {
			Do ..%GetAllMembers(.tEndList,pCube,pFact,"LAST")
			Set tDate = $LG($G(tEndList(1)),2)
			Set:tDate'="" tDate = +$ZDTH(tDate_"-12-31",3)
			If ((tDate'="")&&(tDate<+pEndRange)) {
				Set pEndRange = tDate
			}
		}
	}

	Set tStart = ..%Convert(pStartRange,"-"_pOffset)
	Set tEnd = ..%Convert(pEndRange,"-"_pOffset)

	Set n = 0
	For y = tStart:1:tEnd {
		Set tKey = y
		Set tValue = ..%KeyToValue(tKey,pFormat,pOffset)
		Set n = n + 1
		Set pList(n) = $LB(tValue,tKey)	// value,key
	}
	Quit $$$OK
}

/// Return, via <var>pRelatedKey</var> a key within this level
/// related to <var>pKey</var>.<br/>
ClassMethod %GetRelatedKey(Output pRelatedKey As %String, pCube As %String, pFact As %String, pKey As %String, pRelation As %String, pOffset As %Integer = "", pEndKey As %String = "", pTimeOffset As %String = "") As %Status
{
	Set tSC = $$$OK
	
	// JMD1409
	If (pKey=$$$DeepSeeNullTimeMarker) {
		Set pRelatedKey = pKey
	}
	ElseIf (pRelation = "lead") {
		Set pRelatedKey =  pKey + $S(pOffset="":1,1:+pOffset)
	}
	ElseIf (pRelation = "lag") {
		Set pRelatedKey =  pKey - $S(pOffset="":1,1:+pOffset)
	}
	ElseIf (pRelation = "first") {
		If (pEndKey="") {
			// use index
			Set tSC = ..%GetNthKey(.pRelatedKey, pCube, pFact, pRelation)
		}
		Else {
			Set pRelatedKey = pKey + pOffset
		}
	}
	ElseIf (pRelation = "last") {
		If (pEndKey="") {
			Set tSC = ..%GetNthKey(.pRelatedKey, pCube, pFact, pRelation)
		}
		Else {
			Set pRelatedKey = pEndKey - pOffset
		}
	}
	Else {
		Quit ##super(.pRelatedKey,.pCube,pFact,pKey,pRelation,pOffset,pEndKey,pTimeOffset)
	}
	Quit tSC
}

/// Return true if this level supports a NOW member.
ClassMethod %SupportsNOW() As %Boolean
{
	Quit 1
}

}
