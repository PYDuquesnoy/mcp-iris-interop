/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%DeepSee, %IKPublic)

Class %iKnow.DeepSee.UI.Analysis.Entities Extends %iKnow.DeepSee.UI.Analysis.AbstractAnalysis [ Deprecated, System = 4 ]
{

Property selectedCell As %ZEN.Datatype.integer;

Property term As %ZEN.Datatype.string;

Property SkipListIds As %ZEN.Datatype.integer;

Property backgroundTimerInterval As %ZEN.Datatype.integer [ InitialExpression = 500 ];

Property sortMode As %ZEN.Datatype.string [ InitialExpression = "spread" ];

Property includeSimilar As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property spreadAsPercentage As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Parameter BUILDCELLFILTERS [ Internal ] = 1;

Parameter ENTITYCOUNT As INTEGER = 20;

ClassMethod %GetAnalysisInfo(Output pInfo) As %Status
{
	Set pInfo("caption") = $$$Text("Entity Analysis")
	Set pInfo("tooltip") = $$$Text("Display the iKnow Entity Analysis page")
	Set pInfo("icon") = "portal/logo_48x48.png"
	Set pInfo("rank") = ""
	Quit $$$OK
}

///  Contents of the dialog body.
XData dialogBodyContent [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<vgroup width="100%" height="100%">
<hgroup id="grpControls" labelPosition="left" >
<pane paneName="paneSelMeasure" />
<spacer width="20" />
<assistedText id="txtTerm" name="txtTerm" label="Analyze string:"
   isSuggestedDataComplete="true" hideGhost="true" triggerChars=""
   controlStyle="background-color:#FFFFFF;" controlWidth="200px"
	onUpdateDataClient="zenPage.inputTermClient(base)"
	 title="Enter a string to be added to the analysis" />
<spacer width="10" />
<button caption="analyze" onclick="zenPage.analyzeStringClient();return;" />
</hgroup>
<spacer height="10" />
<tabGroup width="100%" height="100%" id="tabs" showTabBar="true" disabled="true">
<tab layout="vertical" caption="Overview" cellStyle="padding:5px" >
<hgroup labelPosition="left" width="100%" cellStyle="padding-left:5px;" cellAlign="right" >
<select id="radSortMode" label="Select by" valueList="spread,BM25,TFIDF" value="spread" 
labelStyle="opacity: 0.7;" controlStyle="opacity: 0.7;" showEmpty="false"
onchange="zenPage.onChangeSortMode(zenThis.getValue());" align="left"
 title="Measure to use for selecting top 20 entities and calculate rectangle size" />
<select id="selProbCat" label="Color-code by" showEmpty="false" align="right"
labelStyle="opacity: 0.7;margin-left:30px;" controlStyle="opacity: 0.7;"
onchange="zenPage.onChangeColorCode(zenThis.getValue());"
 title="Color-code rectangles using term indicator probability for this filter" />
<hidden id="hidEntities" />
<hidden id="hidSpread" />
<hidden id="hidProb" />
</hgroup>
<svgFrame id="svg" width="600" height="375">
<treeMapChart id="chart" seriesCount="1"
 	ongetData="return zenPage.getChartData(series,'spread');"
 	ongetColorScaleData="return zenPage.getChartData(series,'prob');"
 	ongetLabelY="return zenPage.getChartLabel(value,'entity');"
 	onelementClick="return zenPage.onElementClick(zenThis);"
 	seriesColors="rgb(222,0,0),rgb(240,240,120),rgb(0,222,100)"
 	width="600" height="400" labelsVisible="true" showPercentage="false"
 	marginBottom="0" marginLeft="0" marginRight="0" marginTop="0" >
</treeMapChart>
</svgFrame>
</tab>
<tab layout="vertical" caption="Cell breakdown" cellStyle="padding:5px" 
id="tabBreakdown" disabled="true" >
<hgroup labelPosition="left" cellAlign="right">
<checkbox onchange="zenPage.onChangeIncludeSimilar(zenThis.getValue());" 
labelStyle="opacity: 0.7;" controlStyle="opacity: 0.7;"
label="Include similar entities" 
 title="Include similar entities for frequency and spread" />
<checkbox onchange="zenPage.onChangeSpreadPercent(zenThis.getValue());"
labelStyle="opacity: 0.7;margin-left:30px;" controlStyle="opacity: 0.7;"
label="Spread as %" title="Show spread as % of cell fact count" />
<hidden id="hidCells" />
<hidden id="hidDetailData" />
</hgroup>
<svgFrame id="svg2" width="600" height="400">
<barChart id="detail" title="Cell breakdown" 
	seriesCount="5" seriesNames="entities,entity freq,entity spread,cell probability,dominance"
 	ongetData="return zenPage.getChartData(series, 'detail');"
 	ongetLabelX="return zenPage.getChartLabel(value,'cell');"
 	onelementClick="return zenPage.onDetailElementClick(zenThis);"
 	appearance="2D" width="100%" height="100%"
 	labelsVisible="true" seriesSize="1" seriesYAxes="0,1,2,3,4"
 	chartStacked="false">
<xAxis title="Click a bar to see the list of entities for the selected cell" />
<yAxis id="yCount" title="distinct entity count" />
<yAxis id="yFreq" title="entity frequency" />
<yAxis id="ySpread" title="entity spread" />
<yAxis id="yProb" title="cell probability for this entity" />
<yAxis id="yDominance" title="semantic dominance" />
</barChart>
</svgFrame>
</tab>
<tab layout="vertical" caption="Entities" cellStyle="padding:5px" disabled="true" 
id="tabEntities" >
<tablePane id="tblEntities" OnExecuteResultSet="ExecuteEntitiesQuery"
	 queryClass="%iKnow.Queries.EntityQAPI" queryName="GetSimilar" 
	 showRowSelector="false" autoExecute="false">
<column colName="entUniId" hidden="true" />
<column colName="entity" />
<column colName="frequency" />
<column colName="spread" />
</tablePane>
<hgroup align="right">
<button caption="&lt;&lt;" title="Previous page" onclick="zenPage.previousPageClient();return;" />
<spacer width="10" />
<button caption="&gt;&gt;" title="Next page" onclick="zenPage.nextPageClient();return;" />
</hgroup>
</tab>
</tabGroup>
</vgroup>
</pane>
}

Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("iKnow Analysis")
}

Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Analyze the unstructured data for a cell with iKnow.")
}

Method OnAfterCreatePage() As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		set tCount = $g(%session.Data("_cells"),0), tCells = "", tValueList = ""
		for i = 1:1:tCount {
			set tCells = tCells _ "," _ $li(%session.Data("_cells", i),3)
			set tValueList = tValueList _ "," _ i
		}
		if (tCount>1) {
			set tCells = "total" _ tCells
			set tCount = tCount+1
			set tValueList = 0 _ tValueList
		} else {
			set tCells = "total", tValueList = 0
		}
		
		do ..%SetValueById("hidCells", tCells)
		set ..%GetComponentById("detail").seriesSize = tCount
		
		set tSelProbCat = ..%GetComponentById("selProbCat")
		if (tCount > 1) {
			set tSelProbCat.value = 1
			set tSelProbCat.displayList = tCells
			set tSelProbCat.valueList = tValueList
		} else {
			set tSelProbCat.hidden = 1
		}
		
		set ..%GetComponentById("chart").seriesSize = ..#ENTITYCOUNT
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	
	quit tSC
}

Method OnChangeMeasure(pMeasure As %String) As %Status [ Private ]
{
	set tSC = $$$OK
	try {
		// BDB320 - set Skiplist ID
		set tSkipListName = $$$GETIKPDSSKIPLIST(..domain)
		
		if (tSkipListName'="") {
			// BDB387 - use cross-domain Skiplist
			set tBLDomainId = $s($$$IKVERSIONATLEAST(..domain,$$$IKVERSIONXDOMAIN):0, 1:..domain)
			set tBLID = ##class(%iKnow.Utils.MaintenanceAPI).GetSkipListId(tBLDomainId, tSkipListName)
			
			// BDB754 - fall-back to in-domain ones for iKnow-managed domains
			if (tBLID <= 0) {
				set ..SkipListIds = ##class(%iKnow.Utils.MaintenanceAPI).GetSkipListId(..domain, tSkipListName)
			} else {
				set ..SkipListIds = tBLID * $s(tBLDomainId:1, 1:-1)
			}
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method PopulateChart(pEntities As %String = "") As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		quit:'..domain
		
		// rebuild entities
		set tSC = ..%RunBackgroundMethod("BuildEntityList", ..domain, ..filter, ..SkipListIds, ..sortMode, pEntities)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod BuildEntityList(pDomainId As %Integer, pFilter As %String, pSkipListIds As %String, pMode As %String = "spread", pEntities As %String = "") As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		do ..%SetBackgroundMethodStatus("loading...")
		
		set tFilter = ##class(%iKnow.Filters.Filter).RestoreFilterFromString(pFilter)
		set tFilteredSourceCount = ##class(%iKnow.Queries.SourceAPI).GetCountByDomain(pDomainId, pFilter)
		
		set tEntities = "", tSpreads = "", tProbs = ""
		if (pEntities="") {
			
			if (pMode = "spread") {
				set tSC = ##class(%iKnow.Queries.EntityAPI).GetTop(.tResult, pDomainId, 1, ..#ENTITYCOUNT, tFilter, $$$FILTERSPREADANDSORT, $$$SORTBYSPREAD,,, pSkipListIds)
				quit:$$$ISERR(tSC)
				set tScorePos = 4
			} elseif (pMode = "BM25") {
				set tSC = ##class(%iKnow.Queries.EntityAPI).GetTopBM25(.tResult, pDomainId, 1, ..#ENTITYCOUNT, tFilter)
				quit:$$$ISERR(tSC)
				set tScorePos = 3
			} elseif (pMode = "TFIDF") {
				set tSC = ##class(%iKnow.Queries.EntityAPI).GetTopTFIDF(.tResult, pDomainId, 1, ..#ENTITYCOUNT, tFilter)
				quit:$$$ISERR(tSC)
				set tScorePos = 3
			}
			
			set i = ""
			for {
				set i = $order(tResult(i), 1, tInfo)
				quit:i=""
			
				set tEntities = tEntities _ $li(tInfo,2,2)
				set tSpreads = tSpreads _ $li(tInfo,tScorePos,tScorePos)
				set tProbs = tProbs _ $lb(##class(%iKnow.Queries.EntityAPI).GetNBProbabilityInternal(pDomainId, $li(tInfo,1), tFilter,, .tSC))
				quit:$$$ISERR(tSC)
			}
			quit:$$$ISERR(tSC)
		}
			
		set tExtraCount = $length(pEntities,","), tBLCount = $s(pSkipListIds="":0, 1:$length(pSkipListIds,","))
		for i = 1:1:tExtraCount {
			set tEntity = $piece(pEntities,",",i)
			continue:tEntity=""
			continue:$lf(tEntities,tEntity)
			
			set tEntityId = ##class(%iKnow.Queries.EntityAPI).GetId(pDomainId, tEntity)
			continue:'tEntityId  // continue if we treat similar items too
			
			// ignore Skiplists for manually-added entries!
			/*set tSkip = 0
			for j = 1:1:tBLCount {
				set tBLId = $piece(pSkipListIds,",",j)
				set tSkip = ##class(%iKnow.Utils.MaintenanceAPI).SkiplistContainsString(pDomainId, tBLId, tEntity, .tSC)
				quit:$$$ISERR(tSC)
				quit:tSkip
			}
			quit:$$$ISERR(tSC)
			continue:tSkip*/
			
			set tEntities = tEntities _ $lb(tEntity)
			//if (pMode="spread") {
				set tScore = ##class(%iKnow.Queries.EntityAPI).GetSpread(pDomainId, tEntityId,, pFilter, tSC)
			//} else {
				// TODO
			//}
			set tSpreads = tSpreads _ $lb(tScore)
			quit:$$$ISERR(tSC)
			set tProbs = tProbs _ $lb(##class(%iKnow.Queries.EntityAPI).GetNBProbabilityInternal(pDomainId, tEntityId, tFilter,, .tSC))
			quit:$$$ISERR(tSC)
		}
		quit:$$$ISERR(tSC)
		
		// append results
		set tResults("entities") = tEntities
		set tResults("spread") = tSpreads
		set tResults("prob") = tProbs
		set tResults("type") = "chart"
		
		// now store the results
		kill ^IRIS.Temp.IKT.Bgr(+$j)
		merge ^IRIS.Temp.IKT.Bgr(+$j) = tResults
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	set ^IRIS.Temp.IKT.Bgr(+$j) = tSC
	do ..%EndBackgroundMethod()
	quit tSC
}

Method PopulateDetails(pString As %String) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		set tCellCount = $g(%session.Data("_cells")), tFilters = ""
		for i = 1:1:tCellCount {
			set tFilters = tFilters _ $li(%session.Data("_cells",i),4,4)
		}
		set:tCellCount>1 tFilters = $lb(..filter) _ tFilters
		
		set tSC = ..%RunBackgroundMethod("BuildDetails", ..domain, tFilters, pString, ..SkipListIds, ..includeSimilar, ..spreadAsPercentage)
		quit:$$$ISERR(tSC)
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

ClassMethod BuildDetails(pDomainId As %Integer, pFilters As %List, pString As %String = "", pSkipListIds As %String, pIncludeSimilar As %Boolean = 0, pSpreadPercent As %Boolean = 0) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		do ..%SetBackgroundMethodStatus("loading...")
		
		set tEntUniId = ##class(%iKnow.Queries.EntityAPI).GetId(pDomainId, pString)
		
		set tFilterCount = $ll(pFilters)
		set (tDistinctCounts, tTotalFreq, tTotalSpread, tProbs, tDominance) = ""
		for i = 1:1:tFilterCount {
			set tFilter = ##class(%iKnow.Filters.Filter).RestoreFilterFromString($li(pFilters,i))
			set tSourceCount = $s($isobject(tFilter):tFilter.FilteredSourceCount, 1:##class(%iKnow.Queries.SourceAPI).GetCountByDomain(pDomainId))
			
			if (pIncludeSimilar) {
				set tData = ##class(%iKnow.Queries.EntityAPI).GetSimilarCounts(pDomainId, pString, tFilter,, pSkipListIds, .tSC)
				quit:$$$ISERR(tSC)
			
				set tDistinctCounts = tDistinctCounts _ $li(tData,1,1)
				set tTotalFreq = tTotalFreq _ $li(tData,2,2)
				
				set tSpread = $li(tData,3)
				set:pSpreadPercent&&tSourceCount tSpread = tSpread / tSourceCount
				set tTotalSpread = tTotalSpread _ $lb(tSpread)
			} else {
				set tSC = ##class(%iKnow.Queries.EntityAPI).GetSimilarIds("^||%IKQ.SimilarIds", pDomainId, pString, tFilter,, pSkipListIds)
				quit:$$$ISERR(tSC)
				set c = 0, ent=""
				for { set ent = $o(^||%IKQ.SimilarIds(ent))  q:ent=""  set c = c+1 }
				set tDistinctCounts = tDistinctCounts _ $lb(c)
				kill ^||%IKQ.SimilarIds, c, ent
				
				if (tEntUniId) {
					set tTotalFreq = tTotalFreq _ $lb(+##class(%iKnow.Queries.EntityAPI).GetFrequency(pDomainId, tEntUniId,,, tFilter))
					set tSpread = +##class(%iKnow.Queries.EntityAPI).GetSpread(pDomainId, tEntUniId,, tFilter)
					set:pSpreadPercent&&tSourceCount tSpread = tSpread / tSourceCount
					set tTotalSpread = tTotalSpread _ $lb(tSpread)
				} else {
					set tTotalFreq = tTotalFreq _ $lb(0)
					set tTotalSpread = tTotalSpread _ $lb(0)
				}
			}
			
			continue:tEntUniId<=0
			
			set tProbs = tProbs _ $lb(##class(%iKnow.Queries.EntityAPI).GetNBProbabilityInternal(pDomainId, tEntUniId, tFilter,, .tSC))
			
			set tEntDom = ##class(%iKnow.Semantics.DominanceAPI).GetDomainValue(pDomainId, tEntUniId, $$$SDCONCEPT)
			set tEntDom = tEntDom * ##class(%iKnow.Queries.EntityAPI).GetSpread(pDomainId, tEntUniId,, tFilter) / tFilter.FilteredSourceCount
			set tDominance = tDominance _ $lb(tEntDom)
		}
		quit:$$$ISERR(tSC)
		set tResults("count") = tDistinctCounts
		set tResults("freq") = tTotalFreq
		set tResults("spread") = tTotalSpread
		set tResults("prob") = tProbs
		set tResults("dom") = tDominance
		
		// now store the results
		set tResults("type") = "detail"
		kill ^IRIS.Temp.IKT.Bgr(+$j)
		merge ^IRIS.Temp.IKT.Bgr(+$j) = tResults
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	set ^IRIS.Temp.IKT.Bgr(+$j) = tSC
	do ..%EndBackgroundMethod()
	quit tSC
}

ClassMethod %OnFinishBackgroundTask(pTaskID As %String)
{
	merge tData = ^IRIS.Temp.IKT.Bgr(pTaskID)
	
	if $$$ISERR(tData) {
		set tError = $zconvert($system.Status.GetErrorText(tData),"O","JS")
		&js<alert('Error fetching data:\n#(tError)#');>
		quit
	}
	
	set tType = $g(tData("type"))
	if (tType = "chart") { // main treeMap
	
		set tEntities = $zconvert($lts(tData("entities")),"O","JS")
		set tSpread = $zconvert($lts(tData("spread")),"O","JS")
		set tProb = $zconvert($lts(tData("prob")),"O","JS")
		set tMaxRows = $ll(tData("entities"))
		
		&js<
			var sc = zen('hidEntities').setValue('#(tEntities)#');
			sc = zen('hidSpread').setValue('#(tSpread)#');
			sc = zen('hidProb').setValue('#(tProb)#');
			if (zen('chart').getProperty('seriesSize')!=#(tMaxRows)#) sc = zen('chart').setProperty('seriesSize',#(tMaxRows)#);
			zenPage.refreshDataClient();
		>
	
	} elseif (tType = "detail") { // detail barChart
	
		set tDetailData = $lts(tData("count")) _"^"_ $lts(tData("freq")) _"^" _ $lts(tData("spread"))
		set tDetailData = tDetailData  _"^"_ $lts(tData("prob"))  _"^"_ $lts(tData("dom"))
		set tDetailData = $zconvert(tDetailData,"O","JS")
		
		&js<
			var sc = zen('hidDetailData').setValue('#(tDetailData)#');
			zenPage.refreshDataClient();
		>
	}
	
	kill ^IRIS.Temp.IKT.Bgr(pTaskID)
}

ClientMethod onChangeMeasureClient() [ Language = javascript ]
{
	zen('tabBreakdown').setProperty('disabled',1);
	zen('tabEntities').setProperty('disabled',1);
	zenPage.PopulateChart('');
}

Method InputTerm(pBase As %String) As %String [ ZenMethod ]
{
	set tSC = ##class(%iKnow.Queries.EntityAPI).GetSimilar(.tResult, ..domain, pBase)
	quit:$$$ISERR(tSC) ""
	
	set tResultString = "", i=""
	for {
		set i = $order(tResult(i),1,tData)
		quit:i=""
		set tResultString = tResultString_","_$li(tData,2)
	}
	quit tResultString
}

ClientMethod inputTermClient(base) [ Language = javascript ]
{
	if ((base == null) || (base.length < 3))
		return '';
	return zenPage.InputTerm(base);
}

ClientMethod removeEntityClient(entity) [ Language = javascript ]
{
	var entitiesChanged = false;
	var entities = zen('hidEntities').getValue().split(',');
	var pos = entities.indexOf(string);
	if (pos<0) return;
	
	var newEntities = new Array(entities.length-1);
	for (i = 0; i<entities.length-1; i++) {
		newEntities[i] = entities[ (i<pos) ? i : i+1 ];
	}
	zen('hidEntities').setValue(newEntities.join(','));
	
	if (entitiesChanged)
		zenPage.PopulateChart(newEntities.join(','));
}

ClientMethod analyzeStringClient(string) [ Language = javascript ]
{
	if ((string == null) || (string == '')) {
		var string = zen('txtTerm').getValue();
	} else {
		zen('txtTerm').setValue(string);
	}
	var sc = zenPage.setProperty('term', string);
	
	if (zen('tabs').getCurrTabNo()==1) {
		var entities = zen('hidEntities').getValue();
		var entitiesChanged = false;
		if (entities.split(',').indexOf(string)<0) {
			entities = entities+','+string;
			sc = zen('hidEntities').setValue(entities);
			entitiesChanged = true;
		}
		
		if (entitiesChanged)
			zenPage.PopulateChart(entities);
	} else {
		zenPage.PopulateDetails(string);
		zen('detail').setProperty('title', $$$Text('Cell breakdown for entity')+': "'+string+'"');
	}
}

ClientMethod refreshDataClient() [ Language = javascript ]
{
	switch (zen('tabs').getCurrTabNo()) {
		case 1:
			if (!zen('selProbCat').getProperty('hidden')) {
				var sc = zen('selProbCat').setValue(1);
				zenPage.onChangeColorCode(1);
			} else {
				zen('svg').refreshContents();
			}
			break;
		case 2:
		case 3:
			zen('tblEntities').refreshContents();
			zen('svg2').refreshContents();
			break;
	}
}

///  Adjust sizes of components on the page.
ClientMethod adjustSize() [ Language = javascript ]
{
	try {
		var svg1 = zen('svg');
		var svg2 = zen('svg2');
		var chart1 = zen('chart');
		var chart2 = zen('detail');
		var tabs = zen('tabs');
		
		var ctrlHeight = zen('grpControls').getEnclosingDiv().offsetHeight;
		
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		
		var svgHeight1 = winHeight - 70 - ctrlHeight;
		var svgHeight2 = winHeight - 70 - ctrlHeight;
		svg1.setProperty('height', svgHeight1);
		chart1.setProperty('height', svgHeight1);
		svg2.setProperty('height', svgHeight2);
		chart2.setProperty('height', svgHeight2);
		tabs.setProperty('height', svgHeight2);
		
		var svgWidth = winWidth - 40;
		svg1.setProperty('width', svgWidth);
		chart1.setProperty('width', svgWidth);
		svg2.setProperty('width', svgWidth);
		chart2.setProperty('width', svgWidth);
		tabs.setProperty('width', svgWidth+5);
		
	} catch(ex) {
		zenExceptionHandler(ex,arguments,$$$Text('Error in adjustSizes'));
	}
}

ClientMethod onElementClick(chart) [ Language = javascript ]
{
	var string = zenPage.getChartLabel(chart.getSelectedItem(),'entity');
	var sc = zen('tabBreakdown').setProperty('disabled',false);
	sc = zen('tabs').showTab(2);
	zenPage.analyzeStringClient(string);
}

ClientMethod onDetailElementClick(chart) [ Language = javascript ]
{
	if (chart.getSelectedItem()<0) { return; }
	var sc = zenPage.setProperty('selectedCell', chart.getSelectedItem());
	zen('tabEntities').setProperty('disabled',false);
	zen('tabs').showTab(3);
	var sc = zenPage.ChangePage(0);
	zen('tblEntities').refreshContents();
}

Method ExecuteEntitiesQuery(pRS As %Library.ResultSet, ByRef tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	if (..selectedCell) {
		set tCellFilter = $lg($g(%session.Data("_cells",..selectedCell)),4)
	} else {
		set tCellFilter = ..filter
	}
	set tSC = pRS.Execute(..domain, ..term, ..page, 12, tCellFilter, $$$FILTERALLANDSORT,, ..SkipListIds)
	quit 1
}

Method ChangePage(mode As %Integer) As %Status [ ZenMethod ]
{
	if ('mode) {
		set ..page = 1
	} else {
		set ..page = ..page + mode
		set:..page<1 ..page = 1
	}
	quit $$$OK
}

ClientMethod previousPageClient() [ Language = javascript ]
{
	var sc = zenPage.ChangePage(-1);
	zen('tblEntities').refreshContents();
}

ClientMethod nextPageClient() [ Language = javascript ]
{
	var sc = zenPage.ChangePage(1);
	zen('tblEntities').refreshContents();
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	zenPage.PopulateChart();
}

ClientMethod getChartLabel(index, src) [ Language = javascript ]
{
	var labels = zen((src=='entity') ? 'hidEntities' : 'hidCells').getValue();
	if (labels == null) return '';
	return labels.split(',')[index];
}

ClientMethod getChartData(series, src) [ Language = javascript ]
{
	var data = zen((src=='prob') ? 'hidProb' : (src=='spread') ? 'hidSpread' : 'hidDetailData').getValue();
	if (data == null) return new Array(0);
	data = data.split('^');
	if (data.length <= series) return new Array(0);
	return data[series].split(',');
}

ClientMethod onChangeSortMode(mode) [ Language = javascript ]
{
	var sc = zenPage.setProperty('sortMode',mode); 
	zenPage.PopulateChart('');
}

ClientMethod onChangeColorCode(cell) [ Language = javascript ]
{
	var probs = zenPage.GetEntityProbabilities(zen('hidEntities').getValue(), cell)
	var sc = zen('hidProb').setValue(probs);
	sc = zen('svg').refreshContents();
}

Method GetEntityProbabilities(pEntities As %String, pCellId As %Integer) As %String [ ZenMethod ]
{
	set tProbs = "", tEntCount = $l(pEntities,","), tDomainId = ..domain
	if (pCellId) {
		set tFilter = $lg($g(%session.Data("_cells",pCellId)),4)
	} else {
		set tFilter = ..filter
	}
	set:(tFilter'="")&&'$isobject(tFilter) tFilter = ##class(%iKnow.Filters.Filter).RestoreFilterFromString(tFilter)
	
	for i = 1:1:tEntCount {
		set tEntUniId = ##class(%iKnow.Queries.EntityAPI).GetIdInternal(tDomainId, $p(pEntities,",",i))
		set tProbs = tProbs _ "," _ ##class(%iKnow.Queries.EntityAPI).GetNBProbabilityInternal(tDomainId, tEntUniId, tFilter)
	}
	quit $e(tProbs,2,*)
}

ClientMethod onChangeIncludeSimilar(value) [ Language = javascript ]
{
	var sc = zenPage.setProperty('includeSimilar', value);
	zenPage.PopulateDetails(zenPage.getProperty('term'));
	zenPage.refreshDetailCaptions(value, zenPage.getProperty('spreadAsPercentage'));
}

ClientMethod onChangeSpreadPercent(percent) [ Language = javascript ]
{
	var sc = zenPage.setProperty('spreadAsPercentage', percent);
	zenPage.PopulateDetails(zenPage.getProperty('term'));
	zenPage.refreshDetailCaptions(zenPage.getProperty('includeSimilar'), percent);
}

ClientMethod refreshDetailCaptions(includeSimilar, spreadPercent) [ Language = javascript ]
{
	if (spreadPercent) {
		var seriesNames = includeSimilar ? "entities,total freq,total spread %,cell probability,dominance" : "entities,entity freq,entity spread %,cell probability,dominance";
	} else {
		var seriesNames = includeSimilar ? "entities,total freq,total spread,cell probability,dominance" : "entities,entity freq,entity spread,cell probability,dominance";
	}
	zen('detail').setProperty('seriesNames', seriesNames);
	zen('yFreq').setProperty('title', includeSimilar ? 'total entity frequency' : 'entity frequency');
	zen('ySpread').setProperty('title', (includeSimilar ? 'total entity spread' : 'entity spread') + (spreadPercent ? ' %' : ''));
}

}
