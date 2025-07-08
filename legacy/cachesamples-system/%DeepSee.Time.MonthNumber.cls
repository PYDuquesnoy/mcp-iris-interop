/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class implements a Month number level within a time dimension.
/// This represents the Month number (1 through 12) independent of year.
Class %DeepSee.Time.MonthNumber Extends %DeepSee.Time.AbstractLevel [ System = 3 ]
{

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

/// Convert a $H value to the logical value used for this level.
/// This is used within the computed field logic for properties
/// within a fact table based on this level.<br/>.
/// In this case, we convert $H to a month number:
/// That is convert to a number 1 through 12.
ClassMethod %Convert(pTime As %DeepSee.Datatype.dateTime, pTimeOffset As %String = "") As %Integer [ CodeMode = expression ]
{
$S(pTime="":"",pTime=$$$DeepSeeNullTimeMarker:$$$DeepSeeNullTimeMarker,1:(+$E($ZDT(pTime,3),6,7)))
}

/// Return the total number of members within this level.<br/>
ClassMethod %Count(pCube As %String, pDimNo As %Integer, pHierNo As %Integer, pLevelNo As %Integer) As %Integer
{
	Set tCount = 12
	Quit tCount
}

/// Return the user-visible name of this level.
ClassMethod %GetName() As %String
{
	Quit "MonthNumber"
}

/// Convert a level key value to a display value.
/// E.g., "January"
ClassMethod %KeyToValue(pKey As %Integer, pFormat As %String = "", pOffset As %String = "") As %String
{
	Set tValue = ""
	Try {
		
		If (pKey '= "") {
			Set tH = $ZDTH("2000-" _ $$$iscPadZero(pKey,2) _ "-01",3)
			If (pFormat'="") {
				// DTB344 - Add date format support
				Set tValue = ##class(%DeepSee.Utils).%FormatDate(tH,pFormat)
			}
			Else {
				Set tText = $ZDT(tH,9) 	// e.g.; July 4 2008
				Set tValue = $P(tText," ",1)
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
			Set tMonth = ..%Convert($H,pOffset)
			If ($P(pValue,"+",2)'="") {
				Set tMonth = tMonth + $P(pValue,"+",2)
				While (tMonth > 12) {
					Set tMonth = tMonth - 12
				}
			}
			ElseIf ($P(pValue,"-",2)'="") {
				Set tMonth = tMonth - $P(pValue,"-",2)
				While (tMonth < 1) {
					Set tMonth = tMonth + 12
				}
			}
			Set pValue = tMonth
			
			// Monthname
			Set h = $ZDTH(pValue_" 1 "_2000,6,,,,,,,,"")
		}
		ElseIf (pFormat'="") {
			// DTB344 - Time Format cannot help if NOW was used, but it can be applied to anything else
			Set h = ##class(%DeepSee.Utils).%UnformatDate(pValue,pFormat)
		}
		Else {
			// Monthname
			Set h = $ZDTH(pValue_" 1 "_2000,6,,,,,,,,"")
		}
		
		If (h '= "") {
			Set tKey = +$E($ZDT(h,3),6,7)
		}
	}
	Catch {
		Set tKey = ""
	}
	Quit tKey
}

/// Convert a logical month number into starting and ending
/// base values (in $H format).<br/>
/// As this dimension is independent of year, we use year 2000 as 
/// the basis of calculations.
ClassMethod %KeyToBaseRange(pKey As %String, Output pStart As %Date, Output pEnd As %Date, pOffset As %String = "") As %Status
{
	Set (pStart,pEnd) = ""
	Set tSC = $$$OK
	Try {
		Set tYear = 2000
		Set tMonth = pKey
		Set pStart = $ZDTH(tYear_"-"_$$$iscPadZero(tMonth,2)_"-01",3,,,,,,,,"")
		Set pEnd = $ZDTH(tYear_"-"_$$$iscPadZero(tMonth,2)_"-"_$$$iscPadZero($$$iscDaysInMonth(tYear,tMonth),2)_" 23:59:59",3,,,,,,,,"")
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

	// Find months within given range
	// At most, return 1 through 12
	Set tStart = ..%Convert(pStartRange,pTimeOffset)
	Set tEnd = ..%Convert(pEndRange,pTimeOffset)
	If (tEnd < tStart) {
		Set tStart = 1
		Set tEnd = 12
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
	If (pRelation = "lead") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		//Set pRelatedKey = (((pKey + tOffset) - 1) # 12) + 1
		// JMD1510
		Set pRelatedKey = pKey + tOffset
		Set:pRelatedKey>12 pRelatedKey = ""
	}
	ElseIf (pRelation = "lag") {
		Set tOffset = $S(pOffset="":1,1:+pOffset)
		//Set pRelatedKey = (((pKey - tOffset) - 1) # 12) + 1
		// JMD1510
		Set pRelatedKey = pKey - tOffset
		Set:pRelatedKey<1 pRelatedKey = ""
	}
	ElseIf (pRelation = "first") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = (((pKey + tOffset) - 1) # 12) + 1
	}
	ElseIf (pRelation = "last") {
		Set tOffset = $S(pOffset="":0,1:+pOffset)
		Set pRelatedKey = (((pEndKey - tOffset) - 1) # 12) + 1
	}
	Else {
		Quit ##super(.pRelatedKey,.pCube,pFact,pKey,pRelation,pOffset,pEndKey,pTimeOffset)
	}
	Quit $$$OK
}

}
