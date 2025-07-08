/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This plugin can be used to get the variance of distinct values for a given measure
/// in a given cell. For example:<br> 
/// 
/// %KPI("%DeepSee.Variance","VARIANCE",1,"%measure","[Amount Sold]","%CONTEXT")<br>
/// 
/// The above returns the variance of the Revenues contained in the set of facts for a cell.
/// Use the "%measure" parameter to tell the plugin which measure should be used
Class %DeepSee.PlugIn.Variance Extends %DeepSee.KPIPlugIn [ System = 4 ]
{

/// Cube(s) that this plug-in is based on.
Parameter BASECUBE = "*";

Parameter LISTINGSOURCE = "FactTable";

Parameter PLUGINTYPE = "Aggregate";

/// This XData definition defines the KPI.
XData KPI [ XMLNamespace = "http://www.intersystems.com/deepsee/kpi" ]
{
<kpi xmlns="http://www.intersystems.com/deepsee/kpi"
 name="%DeepSee.Variance" sourceType="mdx"
 caption=""
>
<filter name="%cube" displayName="Subject Area"/>
<filter name="%measure" displayName="Measure"/>
<property name="VARIANCE" displayName="Sample Variance" description="Compute the sample variance for a set of values" />
<property name="SAMPLE" displayName="Sample Variance" description="Compute the sample variance for a set of values" />
<property name="POPULATION" displayName="Popuation Variance" description="Compute the population variance for a set of values" />
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
			Set tBaseCube = ..%filterValues.%cube
		}
	}

	// JMD1124 return error by default
	Set tListingFields = "'ERROR:No Measure' Measure"
	If $IsObject(..%filterValues) {
		If (..%filterValues.%measure'="") {
			Set tMeasure = ..%filterValues.%measure
			
			// Use the parser to support both "Item" and "[Item]" formats used in the call
			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tBaseCube,.tInfo)
			If $$$ISERR(tSC) Quit
			Set tBaseCube = $$$UPPER(tInfo(1))
			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(tMeasure,.tInfo)
			If $$$ISERR(tSC) Quit
			Set tMeasure = $$$UPPER($G(tInfo(1)))

			// Initialize with an error message if the requested measure isn't found
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

/// Compute the variance of values within the result set.
Method %OnCompute(pSQLRS As %SQL.StatementResult) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tTotal = ""
		Set tCount = 0
		Set tErrMsg = ""
		Set n = 0

        Set tMsrSum = ""
        Set tMsrSqSum = ""
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

            Set tMsrSum = tMsrSum + tValue
            Set tMsrSqSum = tMsrSqSum + (tValue*tValue)

			// update pct complete
			If (n#10 = 0) {
				Do ..%SetPercentComplete(100*(n/..%factCount))
			}
		}
		// place answer in KPI output
		Set ..%seriesCount = 1
		Set ..%seriesNames(1) = "Total"
		If (tErrMsg'="") {
			Set ..%data(1,"VARIANCE") = tErrMsg
			Set ..%data(1,"SAMPLE") = tErrMsg
			Set ..%data(1,"POPULATION") = tErrMsg
		}
		Else {
			Set ..%data(1,"VARIANCE") = $S(n=0:"",(..%factCount<=1):0,1:$zabs(tMsrSqSum - ((tMsrSum*tMsrSum)/..%factCount))/(..%factCount-1))
			Set ..%data(1,"SAMPLE") = ..%data(1,"VARIANCE")
			Set ..%data(1,"POPULATION") = $S(n=0:"",(..%factCount<=1):0,1:$zabs(tMsrSqSum - ((tMsrSum*tMsrSum)/..%factCount))/..%factCount)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
