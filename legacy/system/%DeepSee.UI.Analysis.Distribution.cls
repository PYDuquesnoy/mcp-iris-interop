/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This dialog displays various breakdowns of the values behind a cell within a pivot.
Class %DeepSee.UI.Analysis.Distribution Extends %DeepSee.UI.Analysis.AbstractAnalysis [ System = 4 ]
{

/// Set this to false to prevent this analysis from being listed.
Parameter PUBLISHED As Boolean = 1;

/// Return an array of information about this analysis:<br/>
/// pInfo("caption") - localized caption for this item.<br/>
/// pInfo("tooltip") - localized tooltip for this item.<br/>
/// pInfo("icon") - icon for this item.<br/>
/// pInfo("rank") - optional rank; lower numbers are displayed first.<br/>
ClassMethod %GetAnalysisInfo(Output pInfo) As %Status
{
	Set pInfo("caption") = $$$Text("Distribution")
	Set pInfo("tooltip") = $$$Text("Show the distribution of values")
	Set pInfo("icon") = ""
	Set pInfo("rank") = ""
	Quit $$$OK
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<hgroup id="controlBar" cellVAlign="top" labelPosition="left" cellStyle="padding-left:4px;">
<select id="measure" label="Measure" showEmpty="false" onchange="zenPage.measureChange();"/>
<spacer width="5"/>
<label id="itemCount" label="Items:" value=""/>
<spacer width="5"/>
<label id="nullCount" label="Missing:" value=""/>
<spacer width="5"/>
<label id="minValue" label="Min value:" value=""/>
<spacer width="5"/>
<label id="maxValue" label="Max value:" value=""/>
<spacer width="5"/>
<label id="avgValue" label="Avg:" value=""/>
<spacer width="5"/>
</hgroup>

<svgFrame id="svg" backgroundStyle="fill:#D0D0D0;">
<lineChart id="chart" 
	ongetData="return zenPage.getChartData(series);"
	ongetLabelX="return zenPage.getXLabel(value);"
	backgroundStyle="fill: #D0D0D0;"
	labelsVisible="true"
	seriesCount="1"
	autoScaleText="false"
	seriesSize="50"
	chartStacked="false"
	chartFilled="true"
	plotStyle="stroke-width: 0.5; fill-opacity:0.75;"
	plotAreaStyle="fill:white;"
	gridStyle="stroke: #A0A0A0;"
	title="Analysis"
	titleStyle="fill:#404040;"
	labelStyle="fill:white;"
	axisTitleStyle="fill:black; opacity: 1.0;"
	axisLineStyle="stroke: white;"
	seriesColors="#8080FF"
	marginBottom="10"
	width="600" 
	height="400">
<xAxis id="xAxis"
	majorUnits="10"
	majorGridLines="true"
	minorGridLines="false"
	title="Value"
/>
<yAxis title="Number of records"/>
</lineChart>

</svgFrame>

</pane>
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	this.updateMeasureSelect();
}

/// Change in measure value.
ClientMethod measureChange() [ Language = javascript ]
{
	zen('chart').beginWaitState();
	this.measureName = zen('measure').getValue();
	var msg = zenPage.UpdateValues();
	if ('' != msg) {
		alert(msg);
	}
	zen('chart').endWaitState();
	zen('chart').updateChart();
	this.updateMeasureSelect();
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		If (..cubeName="") Quit

		Set tChart = ..%GetComponentById("chart")

		// try to find measure name
		If (..measureName'="") {
			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(..measureName,.tSpecInfo,.tQuoted)
			If $$$ISERR(tSC) {
				Set ..measureName = ""
			}
			Else {
				Set k = $O(tSpecInfo(""),-1)
				Set ..measureName = $$$UPPER(tSpecInfo(k))
			}
		}

		// list of measures
		Set tSC = ##class(%DeepSee.Utils).%GetCubeMeasures(..cubeName,.tMeasures)
		If $$$ISERR(tSC) Quit

		Set tCountName = $$$UPPER(##class(%DeepSee.Utils).%GetCountName(..cubeName,.tSC))
		If $$$ISERR(tSC) Quit

		Set tMCount = 0
		Set tDefMeasure = ""
		Set tMeasureFound = 0
		Set tValueList = ""
		Set tDisplayList = ""
		Set m = $O(tMeasures(""))
		While (m'="") {
			Set tName = $LG(tMeasures(m),1)
			Set tCaption = $LG(tMeasures(m),2)
			Set tType = $LG(tMeasures(m),3)
			Set tHidden = $LG(tMeasures(m),4)		// DTB523

			// +DTB523
			If (tHidden) { 
				Set m = $O(tMeasures(m))
				Continue
			}
			// -DTB523
			
			If (((tType="number")||(tType="integer"))&&($$$UPPER(tName)'=tCountName)) {
				Set tDisplayList = tDisplayList _ $S(tValueList="":"",1:",") _ tCaption
				Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ $$$UPPER(tName)
				Set tMCount = tMCount + 1
				If (tDefMeasure="") {
					Set tDefMeasure = $$$UPPER(tName)
				}
				If (..measureName = $$$UPPER(tName)) {
					Set tMeasureFound = 1
				}
			}
			Set m = $O(tMeasures(m))
		}

		If ('tMeasureFound || (..measureName="")) {
			Set ..measureName = tDefMeasure
		}

		Set tSelect = ..%GetComponentById("measure")
		Set tSelect.valueList = tValueList
		Set tSelect.displayList = tDisplayList

		If (tMCount=0) {
			Set tChart.title = $$$Text("There are no measures to analyze")
		}

		Set tSC = ..%ComputeValues(.tCount,.tNullCount,.tMinValue,.tMaxValue,.tSum)
		If $$$ISERR(tSC) {
			Set tSC = $$$OK
			Quit
		}

		Set tSelect.value = $$$UPPER(..measureName)

		Do ..%UpdateControls(tCount,tNullCount,tMinValue,tMaxValue,tSum)
		Do ..%ComputeChartValues(tMinValue,tMaxValue)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Update value of controls.
Method %UpdateControls(pCount As %Integer, pNullCount As %Integer, pMinValue As %Double, pMaxValue As %Double, pSum As %Double)
{
	Set ..%GetComponentById("itemCount").value = $FN(pCount,",",0)
	Set ..%GetComponentById("nullCount").value = $FN(pNullCount,",",0)
	Set ..%GetComponentById("minValue").value = $FN(pMinValue,",",2)
	Set ..%GetComponentById("maxValue").value = $FN(pMaxValue,",",2)

	Set tAvg = $S(pCount=0:0,1:pSum/pCount)
	Set ..%GetComponentById("avgValue").value = $FN(tAvg,",",2)
}

/// Compute chart values.
Method %ComputeChartValues(pMinValue As %Double, pMaxValue As %Double)
{
	Set tBuckets = 50
	Set tRange1 = +pMaxValue - +pMinValue
	Set tScale = tBuckets
	If (tRange1 > 0) {
		// axis is rounded off to units of Scale
		Set L10 = $ZLOG(tRange1)
		Set f = +$E($P(L10,".",2),1,3)	// fractional part of log
		Set L10 = L10\1
		Set m = $S(f<=301:2,f<=698:5,1:10)
		Set tScale = $ZPOWER(10,L10) * m
	}

	// round off min and max using scale
	If (pMinValue >= 0) {
		Set tMinValueRnd = (((pMinValue)\tScale)) * tScale
	}
	Else {
		Set tMinValueRnd = -((((-pMinValue-1)\tScale)+1) * tScale)
	}
	Set tMaxValueRnd = (((pMaxValue-1)\tScale)+1) * tScale

	Set tRange = tMaxValueRnd - tMinValueRnd
	If (tRange = 0) {
		Set tRange = 1
	}

	Set tBucketSize = tRange / tBuckets

	// put values into buckets
	// each bucket is centered on a value: 
	// values above and below the center value go into the bucket
	// slots start at 1
	Set k = $O(^||Result(""),1,tValue)
	While (k'="") {
		If (tValue'="") {
			Set tSlot = ((((tValue-(tBucketSize/2))-tMinValueRnd)/tRange)*tBuckets\1) + 1
			Set x = $I(^||Histogram(tSlot))
		}
		Set k = $O(^||Result(k),1,tValue)
	}

	Do ..values.Clear()
	Do ..xLabels.Clear()

	// build array of plot values & labels
	For n = 1:1:tBuckets {
		Do ..values.Insert(+$G(^||Histogram(n)))
		Do ..xLabels.Insert(tMinValueRnd + (tBucketSize * (n-1)))
	}
	
	Kill ^||Result
	Kill ^||Histogram

	Set tChart = ..%GetComponentById("chart")
	Set tChart.seriesSize = tBuckets
	If (..measureName'="") {
		Set tChart.title = $$$Text("Distribution of records by value")
	}
	Set tXAxis = ..%GetComponentById("xAxis")
	If $IsObject(tXAxis) {
		Set tXAxis.majorUnits = tBuckets / 10
	}
}

/// Recompute chart values.
Method UpdateValues() As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = ..%ComputeValues(.tCount,.tNullCount,.tMinValue,.tMaxValue,.tSum)
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
		Quit tMsg
	}

	Do ..%UpdateControls(tCount,tNullCount,tMinValue,tMaxValue,tSum)
	//If ((tMinValue="")||(tMaxValue="")) Quit ""

	Do ..%ComputeChartValues(tMinValue,tMaxValue)
	Quit ""
}

/// Execute query and get raw list of values in temp global.
Method %ComputeValues(Output pCount As %Integer, Output pNullCount As %Integer, Output pMinValue As %Double, Output pMaxValue As %Double, Output pSum As %Double) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill ^||Result
		Set pMinValue = ""
		Set pMaxValue = ""
		Set pCount = 0
		Set pSum = 0
		Set pNullCount = 0

		If (..queryKey = "") {
			Quit
		}

		// re-open existing query
		Set tRS = ##class(%DeepSee.ResultSet).%New()
		Set tSC = tRS.%PrepareKey(..cubeName,..queryKey)
		If $$$ISERR(tSC) Quit

		// create drill through out of current query
		Set r1 = +$P(..selectedRange,",",1)
		Set c1 = +$P(..selectedRange,",",2)
		Set r2 = +$P(..selectedRange,",",3)
		Set c2 = +$P(..selectedRange,",",4)
		Set tAllRows = +$P(..selectedRange,",",5)
		Set tAllCols = +$P(..selectedRange,",",6)
		Set:r1=0 r1=1
		Set:c1=0 c1=1
		Set:r2=0 r2=r1
		Set:c2=0 c2=c1
		// JMD1468 pass sort col and dir
		Set tSC = tRS.%GetFiltersForCellRange(.tListingFilters,r1,c1,r2,c2,.tSlicerMeasure,tAllRows,tAllCols,..sortColumn,..sortDir)
		If $$$ISERR(tSC) Quit

		If (..measureName="") {
			Set ..measureName = tSlicerMeasure
		}

		If (..measureName="") {
			Quit
		}
		
		// find fact name for measure
		Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(..cubeName,"[Measures].["_..measureName_"]",.tDNO,.tHNO,.tLNO)
		If $$$ISERR(tSC) {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid measure name")
			Quit
		}

		Set tSC = ##class(%DeepSee.Utils).%GetDimensionFact(..cubeName,tDNO,tHNO,0,.tMeasureFact)
		If $$$ISERR(tSC) {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid measure name")
			Quit
		}
		
		If (tMeasureFact="") {
			Quit
		}

		Set tWITH = ""
		Set:..withClause'="" tWITH = " WITH " _ ..withClause _ " "

		Set tMaxRows = 100000
		Set tMDX = "DRILLFACTS MAXROWS "_tMaxRows_tWITH_" SELECT FROM [" _ tRS.%GetCubeName() _"]"
		Set kf = $O(tListingFilters(""))
		While (kf'="") {
			Set tClause = tListingFilters(kf)
			If (tClause'="") {
				Set tMDX = tMDX _ " %FILTER " _ tClause
			}
			Set kf = $O(tListingFilters(kf))
		}
		Set tMDX = tMDX _ " RETURN " _ tMeasureFact

		// create new query
		Set tRS = ##class(%DeepSee.ResultSet).%New()

		Set tSC = tRS.%PrepareMDX(tMDX)
		If $$$ISERR(tSC) Quit

		Set tSC = tRS.%Execute()
		If $$$ISERR(tSC) Quit

		// make sure listing is executed
		Set tSC = tRS.%ExecuteListing()
		If $$$ISERR(tSC) Quit

		// use SQL result set to get answers
		Set tSC = tRS.%GetListingResultSet(.tSQLRS,.tListingFields)
		If $$$ISERR(tSC) Quit

		// Get values
		While (tSQLRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set tValue = tSQLRS.%GetData(1)
			If (tValue="") {
				Set pNullCount = pNullCount + 1
			}
			Else {
				Set pSum = pSum + tValue
				Set pCount = pCount + 1
				Set:((pMinValue="")||(tValue<pMinValue)) pMinValue = tValue
				Set:((pMaxValue="")||(tValue>pMaxValue)) pMaxValue = tValue
				Set ^||Result(pCount) = tValue
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Adjust size and position of components on this page.
ClientMethod adjustSize() [ Language = javascript ]
{
	this.invokeSuper('adjustSize',arguments);

	var winHeight = zenGetWindowHeight();
	var winWidth = zenGetWindowWidth();

	var svg = zen('svg');

	// adjust size of svg frame
	var svgWid = winWidth - 25;
	var svgHgt = winHeight - 60;
	svg.setProperty("width",svgWid+'px');
	svg.setProperty("height",svgHgt+'px');

	// adjust chart
	var chart = zen('chart');
	if (chart) {
		chart.setProperty("width",svgWid);
		chart.setProperty("height",svgHgt);
	}
}

/// Callback to provide data for the chart.
ClientMethod getChartData(series) [ Language = javascript ]
{
	return this.values;
}

/// Callback to provide x label for the chart.
ClientMethod getXLabel(val) [ Language = javascript ]
{
	return this.xLabels[val] ? this.xLabels[val] : '';
}

/// Update state of the measure select control
ClientMethod updateMeasureSelect() [ Language = javascript ]
{
	var sel = zen('measure');
	var ctrl = sel.findElement('control');
	if ('' == this.measureName) {
		ctrl.value = 'Select a measure';
		ctrl.style.color = 'red';
	}
	else {
	}
}

}
