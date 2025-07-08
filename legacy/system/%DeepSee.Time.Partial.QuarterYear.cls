/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a Quarter level within a time dimension.
/// This represents a quarter (3 month period) within a specific year.
Class %DeepSee.Time.Partial.QuarterYear Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
{

Parameter DIMTYPE = "quarter";

Parameter CALENDAR As STRING = "partial";

/// Convert a partial date ODBC value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case, we convert partial to a logical year+quarter number:
/// That is, Year+Quarter in the form YYYY-Q
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pOffset As %String = "") As %Integer
{
	Quit:pTime="" ""
	Quit:pTime=$$$DeepSeeNullTimeMarker $$$DeepSeeNullTimeMarker
	If (pOffset'="") {
		Set pTime = ##class(%DeepSee.Utils).%AddTimeInterval(pTime,pOffset)
	}
	Set tTime = pTime
	Set tYear = $P(tTime,"-",1)
	Set tMonth = $P(tTime,"-",2)
	If 'tMonth {
		Set tKey = tYear _ "-0"
	}
	Else {
		Set tKey = (tYear_"-"_(1+((tMonth-1)\3)))
	}
	Quit tKey
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "QuarterYear"
}

/// Convert a level key value to a display value.
/// Qx yyyy
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pTimeOffset As %String = "") As %String
{
	If ($$$UPPER($E(pKey,1,3))="NOW") {
		// + WAL037 (2) pass offset
		Set pKey = ..%ValueToKey(pKey,,pTimeOffset)
		// - WAL037 (2)
	}

	// if there are not 6 digits, then this is not a partial qtr-year
	If ($L(pKey)'=6) {
		Quit ""
	}

	Set tYear = +$P(pKey,"-",1)
	Set tQuarter = +$P(pKey,"-",2)

	If ((tQuarter<0)||(tQuarter>4)) {
		Quit ""
	}

	If ((pKey'="")&&(pFormat'="")) {
		If (tQuarter=0) {
			Set tStartMonth = 0
			Set tEndMonth = 0
		}
		Else {
			Set tStartMonth = ((tQuarter-1)*3)+1
			Set tEndMonth = tStartMonth + 2
		}
		Set tH = tYear _ "-" _ $$$iscPadZero(tStartMonth,2) _ "-01"
		//Set tH = $ZDTH(tYear_"-"_$$$iscPadZero(tStartMonth,2)_"-01",3,,,,,,,,"")
		Quit ##class(%DeepSee.Utils).%FormatPartialDate(tH,pFormat)
	}
	Else {
		Quit $E($$$Text("Quarter")) _ tQuarter _ " " _ tYear
	}
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
			Set tKey = ..%Convert($ZD($H,3),pOffset)
			
			Set tYear = +$P(tKey,"-",1)
			Set tQuarter =  +$P(tKey,"-",2)
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
			Set tKey = tYear_"-"_tQuarter
			Quit
		}

		If (pFormat'="") {
			Set tH = ##class(%DeepSee.Utils).%UnformatDate(pValue,pFormat)
			Set tKey = $S(tH="":"",1:$ZDT(tH,3))
			Set:tKey'="" tKey = $E(tKey,1,4)_ (1+(((+$E(tKey,6,7)-1)\3)))
		}
		Else {
			Set tQtr = +$E(pValue,2)
			If ((tQtr>0)&&(tQtr<5)) {
				Set tYear = +$P(pValue," ",2)
				If (tYear = "") {
					Set tYear = +$ZDT($H,3)
				}
				Set tKey = tYear_"-"_tQtr
			}
		}
	}
	Catch {
		Set tKey = ""
	}
	Quit tKey
}

/// Convert a year value (year number) into starting and ending
/// base values (in partial date format).
ClassMethod %KeyToBaseRange(pKey As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	Set (pStart,pEnd) = ""
	Set tSC = $$$OK
	Try {
		Set tYear = $P(pKey,"-",1)
		Set tQuarter = $P(pKey,"-",2)
		If 'tQuarter {
			// DTB688 - Unknown key returns the unknown date as start and end points
			Set pStart = tYear _ "-00-00"
			Set pEnd = pStart
		}
		Else {
			Set tStartMonth = ((tQuarter-1)*3)+1
			Set tEndMonth = tStartMonth + 2
			Set pStart = tYear_"-"_$$$iscPadZero(tStartMonth,2)_"-01"
			Set pEnd = tYear_"-"_$$$iscPadZero(tEndMonth,2)_"-"_$$$iscPadZero($$$iscDaysInMonth(tYear,tEndMonth),2)
		
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

	// invert offset
	Set tStartKey = ..%Convert(pStartRange,"-"_pTimeOffset)
	Set tEndKey = ..%Convert(pEndRange,"-"_pTimeOffset)

	// start and end may cross year boundaries
	Set tStartYear = +$P(tStartKey,"-",1)
	Set tEndYear = +$P(tEndKey,"-",1)

	Set n = 0
	For y = tStartYear:1:tEndYear {
		Set tStartQtr =  $S(y=tStartYear:+$P(tStartKey,"-",2),1:0)
		Set tEndQtr =  $S(y=tEndYear:+$P(tEndKey,"-",2),1:4)
		For q = tStartQtr:1:tEndQtr {
			Set tKey = y_"-"_q
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
	Set tYear = +$P(pKey,"-",1)
	Set tQuarter = +$P(pKey,"-",2)
	If ('tQuarter) {
		// DTB686 - Unknown key
		Set pRelatedKey = pKey
		Quit $$$OK
	}
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

	Set pRelatedKey = tYear _ "-" _ tQuarter		// DTB686 - Partial date format

	Quit $$$OK
}

/// Return true if this level supports a NOW member.
ClassMethod %SupportsNOW() As %Boolean
{
	Quit 1
}

}
