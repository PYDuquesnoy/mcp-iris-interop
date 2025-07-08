/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// This dialog displays various regression analysis of the values behind a cell within a pivot.
Class %DeepSee.UI.Analysis.Clustering Extends (%DeepSee.UI.Analysis.AbstractAnalysis, %DeepSee.extensions.clusters.DataController, %DeepSee.extensions.clusters.ChartModel) [ CompileAfter = (%ZEN.Generator, %ZEN.SVGComponent.xyClusterChart), System = 4 ]
{

Parameter APPLYBUTTON = 0;

/// Measure to use for analysis.
Property measureNameX As %ZEN.Datatype.string(ZENURL = "MEASURE");

/// Measure to use for analysis.
Property measureNameY As %ZEN.Datatype.string(ZENURL = "MEASURE");

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
<spacer	height="3"/>
<pane paneName="tableControlPane"/>
<spacer	height="3"/>
<pane paneName="clusteringOptions"/>
<spacer	height="3"/>
<pane paneName="status1Pane"/>
<spacer height="2"/>
<pane paneName="status2Pane"/>

<svgFrame id="svg" backgroundStyle="fill:#D0D0D0;" >
<bubbleChart id="chart" 
	ongetData="return zenPage.getChartData(series);"
	backgroundStyle="fill: #D0D0D0;"
	title="Clusters"
	seriesSize="1000"
	seriesCount="9"
	radius="0.75"
	plotStyle="stroke-width: 0px;"
	plotAreaStyle="fill:white;"
	titleStyle="fill:#404040;"
	labelStyle="fill:white;"
	seriesColorScheme="tuscan"
	hasZoom="false"
	width="600" 
	height="400">
<xAxis id="xAxis" />
<yAxis id="yAxis"
	baseValue=""
	minValue="" 
	maxValue="" 
	majorUnits=""
	minorUnits=""
	minorGridLines="true"/>
</bubbleChart>

</svgFrame>

</pane>
}

XData tableControlPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<hgroup id="controlBar" cellVAlign="top" labelPosition="left" cellStyle="padding-left:4px;">
<label label="Measures To Include in Clustering:" labelStyle="font-size:14px;"/>
<spacer width="5"/>
<multiSelectSet id="measures" onchange="zenPage.datasetChanged();"/>
<spacer width="10"/>
<vgroup>
<select id="measureX" label="Input (X) Measure" showEmpty="false" onchange="zenPage.axisChanged();"/>
<spacer height="2"/>
<select id="measureY" label="Response (Y) Measure" showEmpty="false" onchange="zenPage.axisChanged();"/>
</vgroup>
<spacer width="5"/>
</hgroup>
</pane>
}

ClassMethod %GetAnalysisInfo(Output pInfo) As %Status
{
	Set pInfo("caption") = $$$Text("Cluster Analysis")
	Set pInfo("tooltip") = $$$Text("Try distribute records between clusters")
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

ClientMethod getChartData(series) [ Language = javascript ]
{
	var data = zenPage.getData(series);
	//alert(series + ": " + data);
	return data
}

ClientMethod datasetChanged() [ Language = javascript ]
{
	this.datasetHasChanged = 1;
}

ClientMethod run() [ Language = javascript ]
{
	zenPage.setParameters();
	var confirm = zenPage.checkParameters ();
	if (!confirm)
		return;
	
	zen('chart').beginWaitState();
	var sc = zenPage.RunAndUpdate();
	zen('chart').endWaitState();
	zenPage.alertIfError(sc);
	zen('chart').updateChart();
}

ClientMethod axisChanged() [ Language = javascript ]
{
	zen('chart').beginWaitState();
	this.measureNameX = zen('measureX').getValue();
	this.measureNameY = zen('measureY').getValue();
	var sc = zenPage.UpdateView();
	zen('chart').endWaitState();
	zenPage.alertIfError(sc);
	zen('chart').updateChart();
}

ClientMethod methodChanged() [ Language = javascript ]
{
	this.clusteringHasChanged = 1
	zenPage.setParameters();
}

ClientMethod sampleSizeChanged() [ Language = javascript ]
{
	this.clusteringHasChanged = 1
}

ClientMethod nclChanged() [ Language = javascript ]
{
	this.clusteringHasChanged = 1
}

ClientMethod setParameters() [ Language = javascript ]
{
	this.method = zen('method').getValue();
	this.NClusters  = zen('ncl').getValue();
	
	if (this.method == "CLARA") {
		this.sampling = 1;
		this.sampleSize = zen('sample').getValue();
	} else {
		this.sampling = 0;
	}
	//alert(this.method + ":" + this.sampling);

	zen('sample').setDisabled(!(this.sampling));
	
	var measures = zen('measures').getValue();
	this.dimensionality = measures.split(",").length;
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
	var svgHgt = winHeight - 240;
	svg.setProperty("width",svgWid+'px');
	svg.setProperty("height",svgHgt+'px');

	// adjust chart
	var chart = zen('chart');
	if (chart) {
		chart.setProperty("width",svgWid);
		chart.setProperty("height",svgHgt);
	}
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

Method RunAndUpdate() As %ZEN.proxyObject [ ZenMethod ]
{
	#dim sc As %Status
	
	set ..Dataset = ..cubeName_"||"_..queryKey
	
	Set sc = ..%UpdateAll()

	Quit ..ErrObj(sc)
}

Method %OnAfterCreatePage() As %Status
{
	#dim tSC = $$$OK
	#dim tSelect As %ZEN.Component.select
	#dim tMSelect As %ZEN.Component.multiSelectSet
	#dim tChart As %ZEN.SVGComponent.chart
	#dim tValueList, tDisplayList, tDefMeasure, tCountName As %String
	#dim tMeasureXFound, tMeasureYFound, tMCount As %Integer
	#dim ex As %Exception.AbstractException
	#dim tSpecInfo, tQuoted, tMeasures
	#dim k,m As %Integer
	#dim measures As %String
	
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
		Set ..sampleSize   = $G($$$DeepSeeChartsGLVN(..cubeName,"clustering","sampleSize"), 75)
		Set ..NClusters    = $G($$$DeepSeeChartsGLVN(..cubeName,"clustering","NCL"), 3)
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

		Set tMSelect = ..%GetComponentById("measures")
		Set tMSelect.valueList = tValueList
		Set tMSelect.displayList = tDisplayList
		Set measures = $G($$$DeepSeeChartsGLVN(..cubeName,"clustering","measures"),tValueList)
		set tMSelect.value = measures
		
		Set tSelect = ..%GetComponentById("measureX")
		Set tSelect.valueList = tValueList
		Set tSelect.displayList = tDisplayList
		Set tSelect.value = ..measureNameX
		Set tSelect = ..%GetComponentById("measureY")
		Set tSelect.valueList = tValueList
		Set tSelect.displayList = tDisplayList
		Set tSelect.value = ..measureNameY


		If (tMCount=0) {
			Set tChart.title = $$$Text("There are no measures to analyze")
		}

		Set ..Dataset = ..cubeName_"||"_..queryKey
		
		set ..dsCount = ..%EstimateCount(.tSC)
		Set ..%GetComponentById("itemCount").value = $FN(..dsCount,",",0)

		set tSelect = ..%GetComponentById("sample")
		set tSelect.value = ..sampleSize
		set tSelect = ..%GetComponentById("ncl")
		set tSelect.value = ..NClusters
		set tSelect = ..%GetComponentById("method")
		if (..dsCount<300) {
			set tSelect.value = "PAM/SA"
			set ..%GetComponentById("sample").disabled = 1
		} else {
			set tSelect.value = "CLARA"
			set ..%GetComponentById("sample").disabled = 0
		}

		set tSC = ..%Init()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Update value of controls.
Method %UpdateControls() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim select As %ZEN.Component.select
	#dim chart As %ZEN.SVGComponent.chart
	#dim status As %ZEN.Component.label

	set chart = ..%GetComponentById("chart")

	Set ..%GetComponentById("itemCount").value = $FN(..dsCount,",",0)
	//Set ..%GetComponentById("nullCount").value = $FN(..DSNullCount,",",0)
	
	set select = ..%GetComponentById("ncl")
	set select.value = ..%GetCurrentNCL()

	Quit:chart="" tSC

	if ((..Ready=0) || (..NClusters=0)) {
		set:chart'="" chart.seriesCount = 1
		set:chart'="" chart.seriesSize = 0
	
		Quit tSC
	}

	set chart.seriesSize = ..%GetSeriesSize()
	set chart.seriesCount = 4 //(..NClusters) * 2

	set status = ..%GetComponentById("minValue")
	set status.value = ..XMin
	set status = ..%GetComponentById("maxValue")
	set status.value = ..XMax
	
	set status = ..%GetComponentById("minYValue")
	set status.value = ..YMin
	set status = ..%GetComponentById("maxYValue")
	set status.value = ..YMax

	Quit tSC
}

Method %UpdateStatusInfo() As %Status
{
	#dim tSC As %Status = $$$OK
	#dim status As %ZEN.Component.label
	#dim msg As %String
	#dim asw, r, ch, cost As %Double
	#dim model As %DeepSee.extensions.clusters.PAM

	set status = ..%GetComponentById("status")

	set model = ##class(%DeepSee.extensions.clusters.PAM).Open(..Dataset, .tSC)
	Quit:$$$ISERR(tSC)
	
	if (..sampling) {
		set r = model.GetPearsonGammaIndex().calculateForSample(..sampleSize,.tSC)
		Quit:$$$ISERR(tSC) tSC
		set asw = model.GetASWIndex().calculateForSample(..sampleSize,.tSC)
		Quit:$$$ISERR(tSC) tSC
	} else {
		set asw = model.GetASWIndex().calculate(.tSC)
		Quit:$$$ISERR(tSC) tSC
		set r = model.GetPearsonGammaIndex().calculate(.tSC)
		Quit:$$$ISERR(tSC) tSC
		set ch = model.GetCalinskiHarabaszIndex().calculate(.tSC)
		Quit:$$$ISERR(tSC) tSC
	}
	set cost = model.TotalCost()

	set msg = "Total Cost: "_$fn(cost,"",2)
	set msg = msg_". Validity Indices: "
	set msg = msg_"Average Silhouette Width (ASW) = "_$fn(asw,"",3)_"; "
	if ('..sampling) {
		set msg = msg_"Calinski-Harabasz (CH) = "_$fn(ch,"",2)_"; "
	}
	set msg = msg_"PearsonGamma = "_$fn(r,"",3)
	set status.value = msg
	
	Quit tSC
}

/// Execute query and get raw list of valuesX in temp global.
Method %ComputeValues() As %Status
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException
	#dim model As %DeepSee.extensions.clusters.AbstractModel
	#dim factClass As %String
	#dim tFactX, tFactY As %String
	#dim nk, k, i, n As %Integer
	#dim max As %Integer = 1200
	#dim random as %Boolean
	#dim id As %String
	#dim xv, yv
	#dim fact
	
	Try {

		If (..Dataset = "") {
			Quit
		}

		do ..%ClearDataset()
		set model = ##class(%DeepSee.extensions.clusters.PAM).Open(..Dataset,.tSC)
		Quit:$$$ISERR(tSC)

		set factClass = ##class(%DeepSee.Utils).%GetCubeFactClass(..cubeName, .tSC)
		Quit:$$$ISERR(tSC)
		
		set tSC = ..%GetXYFactNames(.tFactX, .tFactY)
		Quit:$$$ISERR(tSC)

		$$$Trace(1,"clustering:"_..Dataset_":fact:x",tFactX)
		$$$Trace(1,"clustering:"_..Dataset_":fact:y",tFactY)
		set nk = ..%GetCurrentNCL()
	
		set n = model.GetCount()
		set random = (n > max)
	
		set ..XMin = ""
		set ..XMax = ""
		set ..YMin = ""
		set ..YMax = ""
		for k = 1:1:nk {
			#dim count As %Integer = 0
		
			set i = ""
			While(1) {
				do model.iterateCluster(k, .i, .id)
				Quit:i=""
				if (random) {
					Continue:($r(n)>max)
				}
				set count = $i(count)
			
				set fact = $zobjclassmethod(factClass,"%OpenId",id)
				set xv = $zobjproperty(fact,tFactX)
				set yv = $zobjproperty(fact,tFactY)
				
				if ((..XMin = "") || (xv < ..XMin)){
					set ..XMin = xv
				}
				if ((..XMax = "") || (xv > ..XMax)){
					set ..XMax = xv
				}
				if ((..YMin = "") || (yv < ..YMin)){
					set ..YMin = yv
				}
				if ((..YMax = "") || (yv > ..YMax)){
					set ..YMax = yv
				}

				do ..%InsertDataPoint(k, xv, yv)
			}
		
			$$$Trace(2,"clustering:"_..Dataset_":Count:"_k,count)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %SetModelData() As %Status
{
	#dim tSC = $$$OK
	#dim ex As %Exception.AbstractException
	#dim tInput, tResponse, tYmax, tYmin As %Float
	#dim tMaxRows, dim, i As %Integer
	#dim tListingFilters, tListingFields
	#dim tDNO, tHNO, tLNO 
	#dim tMDX, tWITH, tClause As %String
	#dim kf, measures, measure, facts, fact As %String
	#dim tSQLRS As %ResultSet
	#dim model As %DeepSee.extensions.clusters.AbstractModel
	#dim tSelect As %ZEN.Component.multiSelectSet


	Try {
		Set ..dsCount = 0
		
		Set tSelect = ..%GetComponentById("measures")
		Set measures = tSelect.value
		Quit:measures=""
		set $$$DeepSeeChartsGLVN(..cubeName,"clustering","measures") = measures
		
		set dim = 0
		While (1) {
			set measure = $p(measures,",",(dim+1))
			Quit:measure=""
			set dim = $i(dim)
			
			Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(..cubeName,"[Measures].["_measure_"]",.tDNO,.tHNO,.tLNO)
			If $$$ISERR(tSC) {
				Set tSC = $$$ERROR($$$GeneralError,"Invalid measure: "_measure)
				Quit
			}
			
			Set tSC = ##class(%DeepSee.Utils).%GetDimensionFact(..cubeName,tDNO,tHNO,0,.fact)
			If (($$$ISERR(tSC)) || (fact="")) {
				Set tSC = $$$ERROR($$$GeneralError,"Invalid measure: "_measure)
				Quit
			}
			
			if (dim=1) {
				set facts = fact
			} else {
				set facts = facts_","_fact
			}
		} 
		Quit:$$$ISERR(tSC)
		$$$Trace(2,"clustering:ds",..Dataset)
		$$$Trace(2,"clustering:"_..Dataset_":measures",measures)
		$$$Trace(2,"clustering:"_..Dataset_":dim",dim)
		$$$Trace(2,"clustering:"_..Dataset_":facts",facts)
		
		Set tMaxRows = 100000
		Set tMDX = "DRILLFACTS MAXROWS "_tMaxRows_" "
		Set tMDX = tMDX_ ..%GetQueryMDX(.tSC)
		If $$$ISERR(tSC) Quit

		Set tMDX = tMDX _ " RETURN %ID," _ facts

		// create new query
		Set tRS = ##class(%DeepSee.ResultSet).%New()
		$$$Trace(1,"clustering:"_..Dataset_":mdx",tMDX)

		Set tSC = tRS.%PrepareMDX(tMDX)
		Set tRS.listingPageSize = tMaxRows
		If $$$ISERR(tSC) Quit

		Set tSC = tRS.%Execute()
		If $$$ISERR(tSC) Quit

		// make sure listing is executed
		Set tSC = tRS.%ExecuteListing()
		If $$$ISERR(tSC) Quit
		$$$Trace(1,"clustering:"_..Dataset_":sql",tRS.%GetListingSQL())

		// use SQL result set to get answers
		Set tSC = tRS.%GetListingResultSet(.tSQLRS,.tListingFields)
		If $$$ISERR(tSC) Quit

		set tSC = ##class(%DeepSee.extensions.clusters.AbstractModel).Delete(..Dataset)
		set model = ##class(%DeepSee.extensions.clusters.PAM).New(..Dataset,tSC)
		
		set tSC = model.SetData(tSQLRS, dim)
		
		set ..dsCount = model.GetCount()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %SetClusteringParameters() As %Status
{
	#dim sc As %Status = $$$OK
	#dim k As %Integer

	set ..sampling = 0
	if (..method="CLARA") {
		set $$$DeepSeeChartsGLVN(..cubeName,"clustering","sampleSize") = ..sampleSize
		set ..sampling = 1
	}

	set $$$DeepSeeChartsGLVN(..cubeName,"clustering","NCL") = ..NClusters

	Quit sc
}

Method %GetXYFactNames(Output tMeasureFactX As %String, Output tMeasureFactY As %String) As %Status
{
	#dim tSC = $$$OK
	#dim tInput, tResponse, tYmax, tYmin As %Float
	#dim tSlicerMeasure, tListingFilters As %String
	#dim tDNO, tHNO, tLNO 
	#dim tMDX, tWITH, tClause As %String
	#dim ex

	Try {
		If (..queryKey = "") {
			Quit
		}

		set tSC = ..%GetFilters(.tListingFilters, .tSlicerMeasure)
		Quit:$$$ISERR(tSC)
		
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

		set $$$DeepSeeChartsGLVN(..cubeName,"measure","X") = ..measureNameX
		set $$$DeepSeeChartsGLVN(..cubeName,"measure","Y") = ..measureNameY
	} Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

Method %EstimateCount(Output pSC As %Status) As %Integer
{
	#dim ex As %Exception.AbstractException
	#dim tListingFilters, tListingFields
	#dim tMDX As %String
	#dim kf As %String
	#dim count as %Integer


	Try {
		Set tMDX = ..%GetQueryMDX(.pSC)
		If $$$ISERR(pSC) Quit
		
		Set tRS = ##class(%DeepSee.ResultSet).%New()

		Set pSC = tRS.%PrepareMDX(tMDX)
		If $$$ISERR(pSC) Quit
		Set pSC = tRS.%Execute()
		If $$$ISERR(pSC) Quit
		Set count = tRS.%GetOrdinalValue(1,1)

	} Catch(ex) {
		Set pSC = ex.AsStatus()
	}
	
	$$$Trace(1,"clustering:"_..Dataset_":%Count",count)
	Quit count
}

Method %GetFilters(Output tListingFilters As %String, tSlicerMeasure As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim ex As %Exception.AbstractException
	#dim c1,c2,r1,r2, tAllCols, tAllRows
	

	Try{	
		Set tRS = ##class(%DeepSee.ResultSet).%New()
		Set tSC = tRS.%PrepareKey(..cubeName,..queryKey)
		If $$$ISERR(tSC) Quit

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
		Set tSC = tRS.%GetFiltersForCellRange(.tListingFilters,r1,c1,r2,c2, .tSlicerMeasure,tAllRows,tAllCols,..sortColumn,..sortDir)
		If $$$ISERR(tSC) Quit

	} Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	
	Quit tSC
}

Method %GetQueryMDX(Output pSC As %Status) As %String
{
	#dim ex As %Exception.AbstractException
	#dim tMDX, tListingFilters, tWITH, kf, tClause As %String = ""
	
	Try{	
		set pSC = ..%GetFilters(.tListingFilters)
		Quit:$$$ISERR(pSC)

		Set tWITH = ""
		Set:..withClause'="" tWITH = " WITH " _ ..withClause _ " "
		Set tMDX = tWITH_" SELECT FROM [" _ ..cubeName _"]"
		Set kf = $O(tListingFilters(""))
		While (kf'="") {
			Set tClause = tListingFilters(kf)
			If (tClause'="") {
				Set tMDX = tMDX _ " %FILTER " _ tClause
			}
			Set kf = $O(tListingFilters(kf))
		}
	} Catch(ex) {
		Set pSC = ex.AsStatus()
	}
	
	Quit tMDX
}

}
