/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a Quarter level within a time dimension.
/// This represents a quarter (3 month period) within a specific year.
Class %DeepSee.Time.Hijri.QuarterYear Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
{

Parameter CALENDAR = "hijriTabular";

Parameter DIMTYPE = "quarter";

/// Convert a $H value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case, we convert $H to a logical year+quarter number:
/// That is, Year+Quarter in the form YYYYQ
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pOffset As %String = "") As %Integer
{
	Quit:pTime="" ""
	Quit:pTime=$$$DeepSeeNullTimeMarker $$$DeepSeeNullTimeMarker
	If (pOffset'="") {
		// + WAL132 -- use hijri utility
		Set pTime = ##class(%DeepSee.Utils).%AddHijriTimeInterval(pTime,pOffset,..#CALENDAR)
	}
	// + WAL132
	Set tTime = $ZDT(pTime,19)
	Set tMonth = $P(tTime," ",2)
	Set tYear = $P(tTime," ",3)
	Quit tYear_(((tMonth-1)\3)+1)
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "QuarterYear"
}

/// Convert a level key value to a display value.
/// Q1 2008
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pTimeOffset As %String = "") As %String
{
	If ($$$UPPER($E(pKey,1,3))="NOW") {
		// + WAL037 (2) pass offset
		Set pKey = ..%ValueToKey(pKey,,pTimeOffset)
		// - WAL037 (2)
	}

	// if there are not 5 digits, then this is not a qtr-year
	If ($L(pKey)'=5) {
		Quit ""
	}

	// + WAL132 -- should be the same for hijri, keys looks the same as gregorian
	Set tYear = +$E(pKey,1,4)
	Set tQuarter = +$E(pKey,5)

	If ((tQuarter<1)||(tQuarter>4)) {
		Quit ""
	}

	// + WAL132 -- no hijri formatting for now
	//If ((pKey'="")&&(pFormat'="")) {
	//	Set tStartMonth = ((tQuarter-1)*3)+1
	//	Set tEndMonth = tStartMonth + 2
	//	Set tH = $ZDTH(tYear_"-"_$$$iscPadZero(tStartMonth,2)_"-01",3,,,,,,,,"")
	//	Quit ##class(%DeepSee.Utils).%FormatDate(tH,pFormat)
	//}
	//Else {
		Quit "Q" _ tQuarter _ " " _ tYear
	//}
}

/// Convert a level display value (Qn YYYY) to its corresponding key value.
/// Return "" if there is no corresponding key.
ClassMethod %ValueToKey(pValue As %String, pFormat As %String = "", pOffset As %String = "") As %Integer
{
	Set tKey = ""
	Try {
		If ($$$UPPER($E(pValue,1,3))="NOW") {
			
			// + WAL037 -- find the offset sign and invert it
			Set i=1 Set tOrigSign="" While($E(pOffset,i)?1P) {  Set tOrigSign = tOrigSign_$e(pOffset,i) Set i = $i(i) }
			Set tSign = $CASE(tOrigSign,"":"-","+":"-","-":"","--":"-",:"Unknown") 
			If ((tSign'="Unknown")&&(pOffset'="")) {
				Set pOffset = tSign _ $E(pOffset,$L(tOrigSign)+1,9999999)	
			}
			// - WAL037
			
			Set tKey = ..%Convert($H,pOffset)
			Set tYear = +$E(tKey,1,4)
			Set tQuarter =  +$E(tKey,5,5)
			If ($P(pValue,"+",2)'="") {
				Set tQuarter = tQuarter + $P(pValue,"+",2)
				While (tQuarter > 4) {
					Set tYear = tYear + 1
					Set tQuarter = tQuarter - 4
				}
			}
			ElseIf ($P(pValue,"-",2)'="") {
				Set tQuarter = tQuarter - $P(pValue,"-",2)
				While (tQuarter < 1) {
					Set tYear = tYear - 1
					Set tQuarter = tQuarter + 4
				}
			}
			Set tKey = tYear_tQuarter
			Quit
		}

		/* + WAL132 -- no hijri formatting for now
		If (pFormat'="") {
			Set tH = ##class(%DeepSee.Utils).%UnformatDate(pValue,pFormat)
			Set tKey = $S(tH="":"",1:$ZDT(tH,3))
			Set:tKey'="" tKey = $E(tKey,1,4)_ (1+(((+$E(tKey,6,7)-1)\3)))
		}
		Else {
		*/
			Set tQtr = +$E(pValue,2)
			If ((tQtr>0)&&(tQtr<5)) {
				Set tYear = +$P(pValue," ",2)
				If (tYear = "") {
					// + WAL132
					//Set tYear = +$ZDT($H,3)
					Set tYear = $P($ZDT($H,19)," ",3)
				}
				Set tKey = tYear_tQtr
			}
		//}
	}
	Catch {
		Set tKey = ""
	}
	Quit tKey
}

/// Convert a year value (year number) into starting and ending
/// base values (in $H format).
ClassMethod %KeyToBaseRange(pKey As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	Set (pStart,pEnd) = ""
	Set tSC = $$$OK
	Try {
		Set tYear = +$E(pKey,1,4)
		Set tQuarter = +$E(pKey,5)
		Set tStartMonth = ((tQuarter-1)*3)+1
		Set tEndMonth = tStartMonth + 2
		
		Set pStart = $ZDTH("1 "_tStartMonth_" "_tYear,19,,,,,,,,"")
		Set tLastDay = ##class(%DeepSee.Utils).%HijriDaysInMonth(tYear,tEndMonth,..#CALENDAR)	// DTB183
		Set pEnd = $ZDTH(tLastDay_" "_tEndMonth_" " _ tYear _" 23:59:59",19,,,,,,,,"")		// DTB181 - Use end month for this quarter

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

	// invert offset
	Set tStartKey = ..%Convert(pStartRange,"-"_pTimeOffset)
	Set tEndKey = ..%Convert(pEndRange,"-"_pTimeOffset)

	// start and end may cross year boundaries
	Set tStartYear = +$E(tStartKey,1,4)
	Set tEndYear = +$E(tEndKey,1,4)

	Set n = 0
	For y = tStartYear:1:tEndYear {
		Set tStartQtr =  $S(y=tStartYear:+$E(tStartKey,5),1:1)
		Set tEndQtr =  $S(y=tEndYear:+$E(tEndKey,5),1:4)
		For q = tStartQtr:1:tEndQtr {
			Set tKey = y_q
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
	Set tYear = +$E(pKey,1,4)
	Set tQuarter = +$E(pKey,5)
	If (pRelation = "lead") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		Set tYear = tYear + (tOffset\4)
		Set tQuarter = tQuarter + (tOffset # 4)
		If (tQuarter > 4) {
			Set tYear = tYear + 1
			Set tQuarter = tQuarter - 4
		}
	}
	ElseIf (pRelation = "lag") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		Set tYear = tYear - (tOffset\4)
		Set tQuarter = tQuarter - (tOffset # 4)
		If (tQuarter < 1) {
			Set tYear = tYear - 1
			Set tQuarter = tQuarter + 4
		}
	}
	ElseIf (pRelation = "first") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set tQuarter = 1 + (tOffset # 4)
	}
	ElseIf (pRelation = "last") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set tQuarter = 4 - (tOffset # 4)
	}
	Else {
		Quit ##super(.pRelatedKey,.pCube,pFact,pKey,pRelation,pOffset)
	}

	Set pRelatedKey = tYear _ tQuarter

	Quit $$$OK
}

/// Return true if this level supports a NOW member.
ClassMethod %SupportsNOW() As %Boolean
{
	Quit 1
}

}
