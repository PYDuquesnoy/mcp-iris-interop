/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This Analytic plug-in computes the MEDIAN on a given measure for a given cube.
Class %DeepSee.PlugIn.Median Extends %DeepSee.KPIPlugIn [ System = 4 ]
{

/// Cube(s) that this plug-in is based on.
Parameter BASECUBE = "*";

Parameter LISTINGSOURCE = "FactTable";

Parameter PLUGINTYPE = "Aggregate";

XData KPI [ XMLNamespace = "http://www.intersystems.com/deepsee/kpi" ]
{
<kpi name="%DeepSee.Median" displayName="Median" caption="Median" >

<filter name="%cube" displayName="Subject Area"/>
<filter name="%measure" displayName="Measure"/>
<property name="MEDIAN" displayName="Median" description="Compute the median for a set of values" />

</kpi>
}

/// Get the base query for this plug-in.
Method %OnGetMDX(ByRef pMDX As %String) As %Status
{
	Set tBaseCube = ""

	// Use %cube filter to find the base cube
	If $IsObject(..%filterValues) {
		If (..%filterValues.%cube'="") {
			Set tBaseCube = ..%filterValues.%cube
		}
	}

	If (tBaseCube'="") {
		Set pMDX = "SELECT FROM "_tBaseCube
	}
	Quit $$$OK
}

/// Returns the field list (RETURN clause) of the listing used to supply data for this plug-in.
/// In this case, determine which measure we need.
Method %OnGetListingFields() As %String
{
	Set tBaseCube = ..#BASECUBE
	If $IsObject(..%filterValues) {
		If (..%filterValues.%cube'="") {
			Set tBaseCube = $$$UPPER(..%filterValues.%cube)		// DTB549
		}
	}

	// JMD1124 return error by default
	Set tListingFields = "'ERROR:No Measure' Measure"
	If $IsObject(..%filterValues) {
		If (..%filterValues.%measure'="") {
			Set tMeasure = ..%filterValues.%measure

			// +DTB549 - Use the parser instead of the $Extract approach
			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tBaseCube,.tInfo)
			If $$$ISERR(tSC) Quit
			Set tBaseCube = $$$UPPER(tInfo(1))
			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tMeasure,.tInfo)
			If $$$ISERR(tSC) Quit
			Set tMeasure = $$$UPPER($G(tInfo(1)))
			// -DTB549

			Set tListingFields = "'ERROR:No Measure ("_tMeasure_")' Measure"
		
			// find fact name for measure
			Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tBaseCube,"[Measures].["_tMeasure_"]",.tDNO,.tHNO,.tLNO)
			If $$$ISOK(tSC) {
				Set tSC = ##class(%DeepSee.Utils).%GetDimensionFact(tBaseCube,tDNO,tHNO,0,.tMeasureFact)
				If $$$ISOK(tSC) {
					If (tMeasureFact'="") {
						Set tListingFields = tMeasureFact _ " Measure"
					}
				}
			}
		}
	}
	Quit tListingFields
}

/// Compute the median of values within the result set.
Method %OnCompute(pSQLRS As %SQL.StatementResult, pFactCount As %Integer) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tTotal = ""
		Set tCount = 0
		Set tErrMsg = ""
		Set n = 0

		// sort file for median
		Kill ^||sort("median")

		While (pSQLRS.%Next(.tSC)) {
			If $$$ISERR(tSC) {
				Set tErrMsg = $System.Status.GetErrorText(tSC)
				Quit
			}
			Set n = n + 1

			Set tValue = pSQLRS.Measure
			If ($ZSTRIP($P(tValue,":"),"<>W")="ERROR") {
				Set tErrMsg = $P(tValue,":",2)
				Quit
			}
			
			If (tValue'="") {
				Set tCount = tCount + 1
				Set x = $I(^||sort("median",+tValue))
			}

			// update pct complete
			If (n#100 = 0) {
				Do ..%SetPercentComplete(100*(n/pFactCount))
			}
		}

		// place answer in KPI output
		Set ..%seriesCount = 1
		Set ..%seriesNames(1) = "Total"
		If (tErrMsg'="") {
			Set ..%data(1,"MEDIAN") = tErrMsg
		}
		Else {
			Set ..%data(1,"MEDIAN") = ..Median(tCount)
		}
		Kill ^||sort("median")
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Find the median value within the temp file.
ClassMethod Median(k)
{
	Set tMid1 = k\2
	Set tMid2 = tMid1 + 1
	Set i = 0
	Set tKey1 = ""
	Set tKey = $O(^||sort("median",""),1,tCount)
	While (tKey'="") {
		Set i = i + tCount
		If ((i>=tMid1)&&(tKey1="")) {
			Set tKey1 = tKey
		}
		If (i>=tMid2) Quit
		Set tKey = $O(^||sort("median",tKey),1,tCount)
	}
	If ((k#2=0)&&(tKey1'="")) {
		Set tKey = (tKey+tKey1)/2
	}
	Quit tKey
}

}
