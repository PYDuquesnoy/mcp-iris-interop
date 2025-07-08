/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This Analytic plug-in computes the PERCENTILE on a given measure for a given cube.
Class %DeepSee.PlugIn.Percentile Extends %DeepSee.KPIPlugIn [ System = 4 ]
{

/// Cube(s) that this plug-in is based on.
Parameter BASECUBE = "*";

Parameter LISTINGSOURCE = "FactTable";

Parameter PLUGINTYPE = "Aggregate";

XData KPI [ XMLNamespace = "http://www.intersystems.com/deepsee/kpi" ]
{
<kpi name="%DeepSee.Percentile" displayName="Percentile" caption="Percentile" >

<filter name="%cube" displayName="Subject Area"/>
<filter name="%measure" displayName="Measure"/>
<filter name="%percentile" displayName="Percentile" defaultValue="50"/>
<property name="PERCENTILE" displayName="Percentile" description="Compute the percentile for a set of values" />

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

		Set tPercentile = 50
		If $IsObject(..%filterValues) {
			If (..%filterValues.%percentile'="") {
				Set tPercentile = ..%filterValues.%percentile
			}
		}

		If (tPercentile > 50) {
			Set tResultCount = $NUMBER((100-tPercentile)*..%factCount/100,0)+1
		}
		Else {
			Set tResultCount = $NUMBER(tPercentile*..%factCount/100,0)+1
		}


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

			// update pct complete
			If (n#10 = 0) {
				Do ..%SetPercentComplete(100*(n/tResultCount))
			}
		}
		// place answer in KPI output
		Set ..%seriesCount = 1
		Set ..%seriesNames(1) = "Total"
		If (tErrMsg'="") {
			Set ..%data(1,"PERCENTILE") = tErrMsg
		}
		Else {
			Set ..%data(1,"PERCENTILE") = $G(tValue)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return an <class>%SQL.StatementResult</class> object that will iterate over the facts used for analysis.
Method %OnGetAnalysisResultSet(Output pRS As %SQL.StatementResult, pSQL As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		// JMD1162
		// Modify listing query so that SQL does the heavy lifting

		Set tFields = $P(..%OnGetListingFields()," ",1)

		// JMD1226
		If (pSQL [ "ERROR: No Measure") {
			Set tSQL = pSQL
		}
		Else {
			// Limit the results to facts that have a non-null value for the measure of interest
			Set pSQL = pSQL _ $S($f(pSQL,"WHERE"):" AND ",1:" WHERE ") _tFields_" IS NOT NULL"

			Set tCountSQL = "SELECT COUNT(*) "_$P(pSQL," ",6,$L(pSQL," "))
			Set tCountRS = ##class(%SQL.Statement).%ExecDirect(,tCountSQL)

			Set:tCountRS.%Next(.tSC) ..%factCount = tCountRS.%GetData(1)

			Set tPercentile = 50
			If $IsObject(..%filterValues) {
				If (..%filterValues.%percentile'="") {
					Set tPercentile = ..%filterValues.%percentile
				}
			}

			If (tPercentile > 50) {
				Set tResultCount = $NUMBER((100-tPercentile)*..%factCount/100,0)+1
				Set tOrderBy = " ORDER BY %EXACT("_tFields_") DESC"
			}
			Else {
				Set tResultCount = $NUMBER(tPercentile*..%factCount/100,0)+1
				Set tOrderBy = " ORDER BY %EXACT("_tFields_")"
			}


			Set tSQL = "SELECT TOP "_tResultCount_" "_$P(pSQL," ",4,$L(pSQL," "))_tOrderBy
		}

		Set tStatement = ##class(%SQL.Statement).%New(,"DEFAULT_SCHEMA")
		Set tStatement.%SelectMode = 0 // odbc-mode

		Set tSC = tStatement.%Prepare(tSQL)
		If $$$ISERR(tSC) {
			// swallow sql error
			Quit
		}

		// execute to get iterator
		Set pRS = tStatement.%Execute()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
