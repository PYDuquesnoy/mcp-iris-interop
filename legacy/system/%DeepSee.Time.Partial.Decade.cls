/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a Decade level within a time dimension.<br/>
/// A decade is a group of ten years and is displayed in the format:<br/>
/// "1960s", "1990s".<br/>
/// The key value for a decades also has a trailing "s": &[1990s]<br/>
Class %DeepSee.Time.Partial.Decade Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
{

Parameter CALENDAR As STRING = "partial";

/// Convert a partial date ODBC value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case, we convert partial date to the decade number.
/// The decade number takes the form: 2000s,2010s.
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pOffset As %String = "") As %Integer
{
	//$S(pTime="":"",pTime=$$$DeepSeeNullTimeMarker:$$$DeepSeeNullTimeMarker,pOffset="":(+$E($ZDT(pTime,3),1,3)_"0s"),1:(+$E($ZDT(##class(%DeepSee.Utils).%AddTimeInterval(pTime,pOffset),3),1,3)_"0s"))
	If (pTime="") {
		Set tKey = ""
	}
	ElseIf (pTime=$$$DeepSeeNullTimeMarker) {
		Set tKey = $$$DeepSeeNullTimeMarker
	}
	ElseIf (pOffset="") {
		Set tKey = (+$E(pTime,1,3)_"0s")
	}
	Else {
		Set tYear = $P(pTime,"-",1)
		Set tMonth = $P(pTime,"-",2)
		Set tDay = $P(pTime,"-",3)
		
		If (tMonth&&tDay) {
			Set tTime = $ZDH(tYear_"-"_tMonth_"-"_tDay,3)
			Set tKey = (+$E($ZDT(##class(%DeepSee.Utils).%AddTimeInterval(tTime,pOffset),3),1,3)_"0s")
		}
		Else {
			// Cannot apply an offset to an unkown date!
			Set tKey = (+$E(tYear,1,3)_"0s")
		}
	}

	Quit tKey
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "Decade"
}

/// Convert a level key value to a display value.
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pOffset As %String = "") As %String
{
	Set tValue = ""
	If ($$$UPPER($E(pKey,1,3))="NOW") {
		// + WAL037 (2) pass offset
		Set pKey = ..%ValueToKey(pKey,,pOffset)
		// - WAL037 (2)
	}

	If ((pKey'="")&&(pFormat'="")) {
		Set tH = +$ZDTH(+pKey_"-01-01",3,,,,,,,,"")
		Set tValue = ##class(%DeepSee.Utils).%FormatPartialDate(tH,pFormat)
		// assume format puts "s" in correct place!
	}
	ElseIf ((+pKey<3000)&&(($E(pKey,5)="s")||($E(pKey,5)="S"))) {
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
		
		Set tKey = ..%Convert($ZD($H,3),pOffset)
		If ($P(pValue,"+",2)'="") {
			Set tKey = +tKey + ($P(pValue,"+",2)*10)_"s"
		}
		ElseIf ($P(pValue,"-",2)'="") {
			Set tKey = +tKey - ($P(pValue,"-",2)*10)_"s"
		}
	}
	ElseIf (pFormat'="") {
		Set tH = ##class(%DeepSee.Utils).%UnformatDate(pValue,pFormat)
		Set tKey = ..%Convert($H,"")
	}
	ElseIf ((($E(pValue,5)="S")||($E(pValue,5)="s"))&&(+pValue>1850)&&(+pValue<3000)) {
		Set tKey = (+$E(pValue,1,3))_"0s"
	}
	Quit tKey
}

/// Convert a decade value (starting year of decade) into starting and ending
/// base values (in partial date format).
ClassMethod %KeyToBaseRange(pValue As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	Set (pStart,pEnd) = ""
	Set tSC = $$$OK
	Try {
		If +pValue {
			Set pStart = +pValue_"-01-01"
			Set pEnd = (+pValue+9)_"-12-31"
			If (pOffset'="") {
				Set pStart = ##class(%DeepSee.Utils).%AddTimeInterval(pStart,pOffset)
				Set pEnd = ##class(%DeepSee.Utils).%AddTimeInterval(pEnd,pOffset)
			}
		}
		ElseIf ($$$UPPER(pValue)="NO MEMBER") {
			// DTB689 - Return NO MEMBER as the start and end points
			Set pStart = pValue
			Set pEnd = pValue
		}
		Else {
			// DTB689 - Bad Key: return dummy unknown date
			Set pStart = "2000-00-00"
			Set pEnd = pStart
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
	Set tStart = ..%Convert(pStartRange,"-"_pTimeOffset)
	Set tEnd = ..%Convert(pEndRange,"-"_pTimeOffset)

	Set n = 0
	For d = +tStart:10:+tEnd {
		Set tKey = d_"s"
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
	If 'pKey {
		// DTB689 - Cannot find related key of a bad key!
		Set pRelatedKey = pKey
		Quit $$$OK
	}
	ElseIf (pRelation = "lead") {
		Set pRelatedKey =  +pKey + (10*$S(pOffset="":1,1:+pOffset))_"s"
	}
	ElseIf (pRelation = "lag") {
		Set pRelatedKey =  +pKey - (10*$S(pOffset="":1,1:+pOffset))_"s"
	}
	ElseIf (pRelation = "first") {
		If (pEndKey="") {
			// use index
			Set tSC = ..%GetNthKey(.pRelatedKey, pCube, pFact, pRelation)
		}
		Else {
			Set pRelatedKey = (+$E(pKey,1,3))*10 + (10*$S(pOffset="":0,1:+pOffset))_"s"
		}
	}
	ElseIf (pRelation = "last") {
		If (pEndKey="") {
			Set tSC = ..%GetNthKey(.pRelatedKey, pCube, pFact, pRelation)
		}
		Else {
			Set pRelatedKey = (+$E(pKey,1,3))*10 - (10*$S(pOffset="":0,1:+pOffset))_"s"
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
