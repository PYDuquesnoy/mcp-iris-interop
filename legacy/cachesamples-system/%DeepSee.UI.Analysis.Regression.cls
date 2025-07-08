/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This dialog displays various regression analysis of the values behind a cell within a pivot.
Class %DeepSee.UI.Analysis.Regression Extends %DeepSee.UI.Analysis.AbstractAnalysis [ CompileAfter = (%ZEN.Generator, %ZEN.SVGComponent.xyFitChart), System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Measure to use for analysis.
Property measureNameX As %ZEN.Datatype.string(ZENURL = "MEASURE");

/// Measure to use for analysis.
Property measureNameY As %ZEN.Datatype.string(ZENURL = "MEASURE");

/// Array of X values to plot.
Property valuesX As list Of %ZEN.Datatype.float;

/// Array of Y values to plot.
Property valuesY As list Of %ZEN.Datatype.float;

Property XMin As %ZEN.Datatype.float;

Property XMax As %ZEN.Datatype.float;

Property YMin As %ZEN.Datatype.float;

Property YMax As %ZEN.Datatype.float;

/// Regression values
Property R As %ZEN.Datatype.float;

Property Slope As %ZEN.Datatype.float;

Property SlopeErr As %ZEN.Datatype.float;

Property Intercept As %ZEN.Datatype.float;

Property InterceptErr As %ZEN.Datatype.float;

Property Fit As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">

.zenLabel {
	color: #404040;
	font-size: 10px;
}

.checkboxCaption {
	color: #404040;
	font-size: 12px;
}

</style>
}

/// Contents of the dialog body.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<hgroup id="controlBar" cellVAlign="top" labelPosition="left" cellStyle="padding-left:4px;">
<select id="measureX" label="Input (X) Measure" showEmpty="false" onchange="zenPage.measureChange();"/>
<spacer width="5"/>
<select id="measureY" label="Response (Y) Measure" showEmpty="false" onchange="zenPage.measureChange();"/>
<spacer width="5"/>
<select id="fit" label="Fit: " showEmpty="true" onchange="zenPage.fitChange();"/>
</hgroup>
<hgroup>
<spacer width="5"/>
<label label="Items:"/>
<spacer width="1"/>
<label id="itemCount" value=""/>
<spacer width="5"/>
<label label="Missing:"/>
<spacer width="1"/>
<label id="nullCount" value=""/>
<spacer width="5"/>
<label id="xlabel" label="X:" />
<spacer width="2"/>
<label value="[" />
<label id="minValue" value=""/>
<spacer width="2"/>
<label value=";"/>
<label id="maxValue" value=""/>
<label value="]"/>
</hgroup>
<spacer height="2"/>
<hgroup cellVAlign="top" labelPosition="left" cellStyle="padding-left:4px;">
<label id="Equation" label="Equation: " value="" hidden="true"/>
<spacer width="5"/>
<label id="Correlation" label="Correlation Coefficient = " value="" hidden="true"/>
<spacer width="5"/>
<select id="confidence" label="Confidence Level: " hidden="true" showEmpty="true" onchange="zenPage.confidenceChange();"/>
</hgroup>

<!--
	ongetLabelX="return zenPage.getXLabel(value);"
-->

<svgFrame id="svg" backgroundStyle="fill:#D0D0D0;" >
<xyFitChart id="chart" 
	ongetData="return zenPage.getChartData(series);"
	backgroundStyle="fill: #D0D0D0;"
	labelsVisible="true"
	seriesCount="3"
	autoScaleText="false"
	seriesSize="50"
	plotStyle="stroke-width: 0px;"
	plotAreaStyle="fill:white;"
	plotToEdge="true"
	gridStyle="stroke: #A0A0A0;"
	title="Analysis"
	titleStyle="fill:#404040;"
	labelStyle="fill:white;"
	axisTitleStyle="fill:black; opacity: 1.0;"
	axisLineStyle="stroke: white;"
	seriesColors="blue,red,red"
	marginBottom="10"
	width="700" 
	height="400">
<xAxis id="xAxis"
	majorUnits=""
	majorGridLines="true"
	minorGridLines="false"
	title="Input"
	minValue=""
/>
<yAxis id="yAxis" title="Response"/>
</xyFitChart>

</svgFrame>

</pane>
}

ClassMethod %GetAnalysisInfo(Output pInfo) As %Status
{
	Set pInfo("caption") = $$$Text("Regression")
	Set pInfo("tooltip") = $$$Text("Show charts of values and their regression analysis")
	Set pInfo("icon") = "portal/chart_xy.png"
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Pivot Analysis")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Analyze a cell within a Pivot Table.")
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	this.updateMeasureSelect();
}

/// Change in measureX value.
ClientMethod measureChange() [ Language = javascript ]
{
	zen('chart').beginWaitState();
	this.measureNameX = zen('measureX').getValue();
	this.measureNameY = zen('measureY').getValue();
	if (this.measureNameX=="" || this.measureNameY=="") {
		return
	}
	var msg = zenPage.UpdateValues();
	if ('' != msg) {
		alert(msg);
	}
	zen('chart').endWaitState();
	//zen('svg').refreshContents();
	zen('chart').updateChart();
	this.updateMeasureSelect();
}

ClientMethod fitChange() [ Language = javascript ]
{
	this.Fit = zen('fit').getValue();
	if (this.Fit != "") {
		zen('chart').beginWaitState();
		var msg = zenPage.UpdateValues();
		if ('' != msg) {
			alert(msg);
		}
		zen('chart').endWaitState();
	}
}

Method %OnAfterCreatePage() As %Status
{
	#dim tSC = $$$OK
	#dim tSelect As %ZEN.Component.select
	#dim tValueList, tDisplayList, tDefMeasure As %String
	#dim tMeasureXFound, tMeasureYFound, tMCount As %Integer
	
	Try {
		If (..cubeName="") Quit

		Set tChart = ..%GetComponentById("chart")

		// try to find measureX name
		If (..measureNameX'="") {
			Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(..measureNameX,.tSpecInfo,.tQuoted)
			If $$$ISERR(tSC) {
				Set ..measureNameX = ""
			}
			Else {
				Set k = $O(tSpecInfo(""),-1)
				Set ..measureNameX = $$$UPPER(tSpecInfo(k))
			}
		}

		// list of measures
		Set tSC = ##class(%DeepSee.Utils).%GetCubeMeasures(..cubeName,.tMeasures)
		If $$$ISERR(tSC) Quit

		Set tCountName = $$$UPPER(##class(%DeepSee.Utils).%GetCountName(..cubeName,.tSC))
		If $$$ISERR(tSC) Quit

		Set tMCount = 0
		Set tDefMeasure = ""
		Set tMeasureXFound = 0
		Set tMeasureYFound = 0
		Set tValueList = ""
		Set tDisplayList = ""
		Set ..measureNameX = $G($$$DeepSeeChartsGLVN(..cubeName,"measure","X"))
		Set ..measureNameY = $G($$$DeepSeeChartsGLVN(..cubeName,"measure","Y"))
		Set m = $O(tMeasures(""))
		While (m'="") {
			#dim tName As %String
			Set tName = $LG(tMeasures(m),1)
			#dim tCaption = $LG(tMeasures(m),2)
			#dim tType = $LG(tMeasures(m),3)
			#dim tHidden = $LG(tMeasures(m),4)

			If (tHidden) { 
				Set m = $O(tMeasures(m))
				Continue
			}
			If (((tType="number")||(tType="integer"))&&($$$UPPER(tName)'=tCountName)) {
				Set tDisplayList = tDisplayList _ $S(tValueList="":"",1:",") _ tCaption
				Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ $$$UPPER(tName)
				Set tMCount = tMCount + 1
				If (tDefMeasure="") {
					Set tDefMeasure = $$$UPPER(tName)
				}
				If (..measureNameX = $$$UPPER(tName)) {
					Set tMeasureXFound = tMCount
				}
				If (..measureNameY = $$$UPPER(tName)) {
					Set tMeasureYFound = tMCount
				}
			}
			Set m = $O(tMeasures(m))
		}

		If ('tMeasureXFound || (..measureNameX="")) {
			Set ..measureNameX = tDefMeasure
		}
		If ('tMeasureYFound || (..measureNameY="")) {
			Set ..measureNameY = tDefMeasure
		}

		Set tSelect = ..%GetComponentById("measureX")
		Set tSelect.valueList = tValueList
		Set tSelect.displayList = tDisplayList
		Set tSelect.value = ..measureNameX
		Set tSelect = ..%GetComponentById("measureY")
		Set tSelect.valueList = tValueList
		Set tSelect.displayList = tDisplayList
		Set tSelect.value = ..measureNameY

		Set tSelect = ..%GetComponentById("fit")
		Set tSelect.valueList = "line,exp,log,power"
		Set tSelect = ..%GetComponentById("confidence") 
		Set tSelect.valueList = "0.5,0.6,0.7,0.9,0.95,0.98,0.99,0.995,0.998,0.999"
		Set tSelect.displayList = "50%,60%,70%,90%,95%,98%,99%,99.5%,99.8%,99.9%"

		If (tMCount=0) {
			Set tChart.title = $$$Text("There are no measures to analyze")
		}

		Set tSC = ..%ComputeValues(.tCount,.tNullCount,.tMinValue,.tMaxValue)
		If $$$ISERR(tSC) {
			Set tSC = $$$OK
			Quit
		}

		Set tSelect.value = $$$UPPER(..measureNameX)

		Do ..%UpdateControls(tCount,tNullCount,tMinValue,tMaxValue)
		Do ..%ComputeChartValues()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Update value of controls.
Method %UpdateControls(pCount As %Integer, pNullCount As %Integer, pMinValue As %Double, pMaxValue As %Double)
{
	Set ..%GetComponentById("itemCount").value = $FN(pCount,",",0)
	Set ..%GetComponentById("nullCount").value = $FN(pNullCount,",",0)
	Set ..%GetComponentById("xlabel").label = ..measureNameX
	Set ..%GetComponentById("minValue").value = $FN(pMinValue,",",2)
	Set ..%GetComponentById("maxValue").value = $FN(pMaxValue,",",2)

	//Set ..%GetComponentById("chart").xAxis.minValue = pMinValue * 0.9
	//Set ..%GetComponentById("chart").xAxis.maxValue = pMaxValue * 1.1
	
	if (..R'="") {
		Set ..%GetComponentById("chart").hasFit = 1
		Set ..%GetComponentById("Correlation").hidden = 0
		Set ..%GetComponentById("Equation").hidden = 0
		Set ..%GetComponentById("confidence").hidden = 0
		
		Do ..%UpdateEquation()
	} else {
		Set ..%GetComponentById("chart").hasFit = 0
	}
}

Method UpdateConfidence() As %Status [ ZenMethod ]
{
	Quit ..%UpdateEquation()
}

Method %UpdateEquation() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim eb, ea, c As %Float
	#dim sign, y0 As %String

	Set eb = ..SlopeErr
	Set ea = ..InterceptErr
	
	set c = ..%GetComponentById("confidence").value
	if ((c '= "") && (ea '= "") && (eb '= "")) {
		#dim tChart = ..%GetComponentById("chart")
		#dim n = tChart.seriesSize
		#dim t As %Float
		
		set t = $$$T(c,n)
		set ea = " +/- "_..%Round(t * ea) 
		set eb = " +/- "_..%Round(t * eb) 
	} else {
		set ea = ""
		set eb = ""
	}
	

	Set y0 = ..Intercept
	if (y0 < 0) {
		Set sign = "-"
		Set y0 = - y0
	} else {
		Set sign = "+"
	}
	
	Set ..%GetComponentById("Correlation").value = $FN(..R,",",2)
	if ((..Fit="exp") ||(..Fit="power")){
		Set y0 = ..%Round($zexp(..Intercept))
	} else {
		Set y0 = ..%Round(y0)
	}
	if (ea'="") {
		Set y0 = "("_y0_ea_")"
	}
	#dim tSlope = ..%Round(..Slope)
	if (eb'="") {
		Set tSlope = "("_tSlope_eb_")"
	}

	if (..Fit="line") {
		Set ..%GetComponentById("Equation").value = "Y = " _ tSlope _ " * X " _ sign _ " " _ y0
	} Elseif (..Fit="log"){
		Set ..%GetComponentById("Equation").value = "Y = " _ tSlope _ " * ln (X) " _ sign _ " " _ y0
	} Elseif (..Fit="exp"){
		Set ..%GetComponentById("Equation").value = "Y = " _ y0 _ " * exp ("_ tSlope _"*X) " 
	} Elseif (..Fit="power"){
		Set ..%GetComponentById("Equation").value = "Y = " _ y0 _ " * X ^ "_ tSlope 
	}

	Quit tSC
}

/// Compute chart valuesX.
Method %ComputeChartValues()
{
	#dim tSeriesSize, n As %Integer
	#dim tChart As %ZEN.SVGComponent.chart
	#dim tXAxis, tYAxis As %ZEN.Auxiliary.axis
	
	Do ..valuesX.Clear()
	Do ..valuesY.Clear()
	Do ..xLabels.Clear()
	
	Set tSeriesSize = $g(^||Result,0)
	if (tSeriesSize > 1000) {
		Set tSeriesSize = 1000
	}

	// build array of plot valuesX & labels
	For n = 1:1:tSeriesSize {
		Do ..valuesX.Insert(..%Round(^||Result(n,0)))
		Do ..valuesY.Insert(..%Round(^||Result(n,1)))
	}
	
	Kill ^||Result
	Kill ^||Histogram

	Set tChart = ..%GetComponentById("chart")
	Set tChart.seriesSize = tSeriesSize
	If (..measureNameX'="") {
		Set tChart.title = "Plot: "_..measureNameY_" versus "_..measureNameX
	}
	
	Set tXAxis = ..%GetComponentById("xAxis")
	If $IsObject(tXAxis) {
		Set tXAxis.title = ..measureNameX
		//Set ^dbgXT = tXAxis.title
	} else {
		//Set ^dbgXT = "NONE"
	}
	Set tYAxis = ..%GetComponentById("yAxis")
	If $IsObject(tYAxis) {
		Set tYAxis.title = ..measureNameY
	}
}

/// Recompute chart values.
Method UpdateValues() As %String [ ZenMethod ]
{
	set $$$DeepSeeChartsGLVN(..cubeName,"measure","X") = ..measureNameX
	set $$$DeepSeeChartsGLVN(..cubeName,"measure","Y") = ..measureNameY
	Set tMsg = ""
	Set tSC = ..%ComputeValues(.tCount,.tNullCount,.tMinValue,.tMaxValue)
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
		Quit tMsg
	}
	if (..Fit'="") {
		Set tSC = ..%ComputeRegression()
		If $$$ISERR(tSC) {
			Set tMsg = $System.Status.GetErrorText(tSC)
			Quit tMsg
		}
	}

	Do ..%UpdateControls(tCount,tNullCount,tMinValue,tMaxValue)
	//If ((tMinValue="")||(tMaxValue="")) Quit ""

	Do ..%ComputeChartValues()
	Quit ""
}

/// Execute query and get raw list of valuesX in temp global.
Method %ComputeValues(Output pCount As %Integer, Output pNullCount As %Integer, Output pMinValue As %Double, Output pMaxValue As %Double) As %Status
{
	#dim tSC = $$$OK
	#dim tInput, tResponse, tYmax, tYmin As %Float
	#dim tMeasureFactX, tMeasureFactY, tSlicerMeasure As %String
	#dim tMaxRows As %Integer
	#dim tListingFilters, tListingFields
	#dim tDNO, tHNO, tLNO 
	#dim tMDX, tWITH, tClause As %String
	#dim kf As %String
	#dim tSQLRS As %ResultSet
	#dim tAllCols, tAllRows
	#dim ex
	
	Try {
		Kill ^||Result
		Set pMinValue = ""
		Set pMaxValue = ""
		Set pCount = 0
		Set pNullCount = 0

		If (..queryKey = "") {
			Quit
		}

		// re-open existing query
		Set tRS = ##class(%DeepSee.ResultSet).%New()
		Set tSC = tRS.%PrepareKey(..cubeName,..queryKey)
		If $$$ISERR(tSC) Quit

		// create drill through out of current query
		if (1) {
			#dim c1,c2,r1,r2
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
		}

		If (..measureNameX="") {
			Set ..measureNameX = tSlicerMeasure
		}

		If (..measureNameX="") {
			Quit
		}
		
		// find fact name for measureX
		Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(..cubeName,"[Measures].["_..measureNameX_"]",.tDNO,.tHNO,.tLNO)
		If $$$ISERR(tSC) {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid X measure name")
			Quit
		}

		Set tSC = ##class(%DeepSee.Utils).%GetDimensionFact(..cubeName,tDNO,tHNO,0,.tMeasureFactX)
		If $$$ISERR(tSC) {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid X measure name")
			Quit
		}
		
		If (tMeasureFactX="") {
			Quit
		}

		Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(..cubeName,"[Measures].["_..measureNameY_"]",.tDNO,.tHNO,.tLNO)
		If $$$ISERR(tSC) {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid Y measure name")
			Quit
		}

		Set tSC = ##class(%DeepSee.Utils).%GetDimensionFact(..cubeName,tDNO,tHNO,0,.tMeasureFactY)
		If $$$ISERR(tSC) {
			Set tSC = $$$ERROR($$$GeneralError,"Invalid Y measure name")
			Quit
		}
		
		If (tMeasureFactY="") {
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
		Set tMDX = tMDX _ " RETURN " _ tMeasureFactX_","_tMeasureFactY

		// create new query
		Set tRS = ##class(%DeepSee.ResultSet).%New()
		$$$Trace(1,"regression:mdx",tMDX)

		Set tSC = tRS.%PrepareMDX(tMDX)
		Set tRS.listingPageSize = tMaxRows
		If $$$ISERR(tSC) Quit

		Set tSC = tRS.%Execute()
		If $$$ISERR(tSC) Quit

		// make sure listing is executed
		//set ^dbgMXR = tRS.%Query.%MaxListingRows
		Set tSC = tRS.%ExecuteListing()
		If $$$ISERR(tSC) Quit
		$$$Trace(1,"regression:sql",tRS.%GetListingSQL())

		// use SQL result set to get answers
		Set tSC = tRS.%GetListingResultSet(.tSQLRS,.tListingFields)
		If $$$ISERR(tSC) Quit

		// Get values
		Set tYmax = ""
		Set tYmin = ""
		While (tSQLRS.%Next(.tSC)) {
			If $$$ISERR(tSC) Quit
			Set tInput = tSQLRS.%GetData(1)
			Set tResponse = tSQLRS.%GetData(2)
			If (tInput="" || tResponse="") {
				Set pNullCount = pNullCount + 1
			}
			Else {
				Set pCount = pCount + 1
				Set:((pMinValue="")||(tInput<pMinValue)) pMinValue = tInput
				Set:((pMaxValue="")||(tInput>pMaxValue)) pMaxValue = tInput
				Set:((tYmin="")||(tResponse<tYmin)) tYmin = tInput
				Set:((tYmax="")||(tResponse>tYmax)) tYmax = tInput
				Set ^||Result(pCount,0) = tInput
				Set ^||Result(pCount,1) = tResponse
			}
		}
		Set ^||Result = pCount
		Set ..XMin = pMinValue
		Set ..XMax = pMaxValue
		Set ..YMax = tYmax
		Set ..YMin = tYmin
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClientMethod confidenceChange() [ Language = javascript ]
{
	zenPage.UpdateConfidence()
}

/// Adjust size and position of components on this page.
ClientMethod adjustSize() [ Language = javascript ]
{
	this.invokeSuper('adjustSize',arguments);

	var winHeight = zenGetWindowHeight();
	var winWidth = zenGetWindowWidth();

	var svg = zen('svg');

	// adjust size of svg frame
	var svgWid = winWidth - 70;
	if (svgWid<600){
		svgWid = 600
	}
	var svgHgt = winHeight - 100;
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
	if (series == 0)
		return this.valuesX;
	else if (series == 1)
		return this.valuesY;
	else
		return zenPage.getLineData()
}

ClientMethod getLineData() [ Language = javascript ]
{
	var chart = zenPage.getComponentById('chart');
	var fit = zenPage.Fit

	var x0, x1;
	
	x0 = zenPage.XMin;
	x1 = zenPage.XMax;
	
	var a0 = zenPage.Intercept;
	var a1 = zenPage.Slope;
	var n  = chart.seriesSize;
	
	//alert(x0 + " : " + x1 + " : " + n);

	var data = new Array(n);

	var d = (x1 - x0)/n;
	var offset = 0;
	if (zenPage.XMin <= 0) {
		offset = zenPage.XMin - 0.01;
	}
	var yOffset = 0;
	if (zenPage.YMin <= 0) {
		yOffset = zenPage.YMin - 0.01;
	}
	
	var y;
	for (var i = 0; i < n; i++) {
		var dx = d * i
		var x = x0 + dx + offset;
		if (fit == "line") {
			y = a0 + a1 * x 
			y = y + yOffset;
		} else if (fit == "exp") {
			y = a0 + a1 * x 
			y = Math.exp(y);
			y = y + yOffset;
		} else if (fit == "log") {
			y = a0 + a1 * Math.log(x) 
			y = y + yOffset;
		} else if (fit == "power") {
			y = a0 + a1 * Math.log(x) 
			y = Math.exp(y);
			y = y + yOffset;
		} else {
			y = 0;
		}
		
		data[i] = y;
	}
	
	//alert(data);
	return data;
}

/// Callback to provide x label for the chart.
ClientMethod getXLabel(val) [ Language = javascript ]
{
	//alert(val);
	return val;
	//return this.xLabels[val] ? this.xLabels[val] : '';
}

/// Update state of the measureX select control
ClientMethod updateMeasureSelect() [ Language = javascript ]
{
	var sel = zen('measureX');
	var ctrl = sel.findElement('control');
	if ('' == this.measureNameX) {
		ctrl.value = 'Select a measure';
		ctrl.style.color = 'red';
	}
	else {
	}
}

Method %ComputeRegression() As %Status
{
	#dim tSC As %Status
	#dim Sx, Sx2, Sy, Sy2, Sxy, S2e, S2b, S2a, den  As %Float
	#dim x, y As %Float
	#dim N, i As %Integer
	
	Set N = ^||Result
	Quit:N<2
	
	Set Sx 	= 0
	Set Sx2 = 0
	Set Sy 	= 0
	Set Sy2 = 0
	Set Sxy = 0
	
	For i = 1:1:N {
		set tSC = ..%GetPair(i, .x, .y)
		Quit:$$$ISERR(tSC)
		
		Set Sx 	= Sx + x
		Set Sx2 = Sx2 + (x*x)

		Set Sy 	= Sy + y
		Set Sy2 = Sy2 + (y*y)
		
		Set Sxy = Sxy + (x*y)
	}
	Quit:$$$ISERR(tSC) tSC
	
	Quit:Sx2=0 $$$OK
	
	Set ..Slope = (((N * Sxy) - (Sx * Sy)) / ((N * Sx2) - (Sx * Sx)))
	Set ..Intercept = (Sy - (..Slope * Sx)) / N
	$$$Trace(1,"regression:slope:",..Slope)
	$$$Trace(1,"regression:intercept:",..Intercept)
	Set den = (((N * Sy2) - (Sy * Sy)))
	if (den = 0) {
		if (..Slope = 0) {
			set ..R = 1
		} else {
			set tSC = $$$ERROR($$$GeneralError,"Internal Error calculating regression")
			Quit tSC
		}
	} else {
		Set ..R = ..Slope * $zsqr(((N * Sx2) - (Sx * Sx)) / den)
	}
	
	If (N > 2) {
		Set S2e = ((N*Sy2) - (Sy * Sy) - ((..Slope)*(..Slope)*((N*Sx2) - (Sx * Sx))))/(N*(N-2))
		Set S2b = (N * S2e)/((N*Sx2) - (Sx * Sx))
		Set S2a = S2b * Sx2 /N
		Set ..SlopeErr = $zsqr(S2b)
		Set ..InterceptErr = $zsqr(S2a)
	} else {
		Set ..SlopeErr = ""
		Set ..InterceptErr = ""
	}
	
	Quit $$$OK
}

Method %GetPair(i As %Integer, Output x As %Float, Output y As %Float) As %Status
{
	#dim tSC As %Status = $$$OK 
	
	Set x = ^||Result(i,0)
	Set y = ^||Result(i,1)
	if (..Fit="line") {
	} elseif (..Fit="exp") {
		if (..YMin <= 0) {
			Set y = y - ..YMin + 0.01
		}
		if (y<=0) {
			Set tSC = $$$ERROR($$$GeneralError,"Negative Values")
		} else {
			Set y = $zln(y)
		}
	} elseif (..Fit="log") {
		if (..XMin <= 0) {
			Set x = x - ..XMin + 0.01
		}
		if (x<=0) {
			Set tSC = $$$ERROR($$$GeneralError,"Negative Values")
		} else {
			Set x = $zln(x)
		}
	} elseif (..Fit="power") {
		if (..XMin <= 0) {
			Set x = x - ..XMin + 0.01
		}
		if (..YMin <= 0) {
			Set y = y - ..YMin + 0.01
		}
		if (y<=0 || x <= 0) {
			Set tSC = $$$ERROR($$$GeneralError,"Negative Values")
		} else {
			Set x = $zln(x)
			Set y = $zln(y)
		}
	}
	
	Quit tSC
}

ClassMethod %Round(x As %Float) As %Float
{
	Quit $s($zabs(x)<0.0001:x,
			$zabs(x)<0.001:$fn(x,"",5),
			$zabs(x)<0.01:$fn(x,"",4),
			$zabs(x)<0.1:$fn(x,"",3),
			1:$fn(x,"",2)
		)
}

}
