/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A specialized DeepSee Dashboard widget that displays a visual scorecard.
Class %DeepSee.Component.Widget.scoreCardWidget Extends (%DeepSee.Component.Widget.widget, %DeepSee.Component.ScoreCardContent) [ System = 4 ]
{

/// Return information used to list this widget within the "widget catalog".
ClassMethod %GetCatalogInfo(Output pInfo As %List, Output pSubtypeList As %List) As %Status
{
	Kill pInfo,pSubtypeList
	// $LB(name,caption,class,icon,ranking)
	Set pInfo = $LB(..%ClassName(0),$$$Text("ScoreCard","%DeepSee"),..%ClassName(1),"deepsee/spreadsheet_48.gif",2)

	// $LB(name,caption)
	Set pSubtypeList($I(n)) = $LB("regular",$$$Text("Regular","%DeepSee"),,"deepsee/spreadsheet_48.gif")
	Set pSubtypeList($I(n)) = $LB("big",$$$Text("Big","%DeepSee"),,"deepsee/spreadsheet_48.gif")

	Quit $$$OK
}

/// Return information on additional "properties" supported by this widget for the given subtype.
ClassMethod %GetWidgetPropertyInfo(pSubtype As %String, Output pInfo As %List) As %Status
{
	Kill pInfo
	Set pInfo($I(pInfo)) = $LB("analyzer",1,"%Boolean",$$$Text("Analyzer","%DeepSee"),$$$Text("Enable Analyzer dialog for this scorecard","%DeepSee"))
	
	// DTB250 - Add print
	Set pInfo($I(pInfo)) = $LB("print",0,"%Boolean",$$$Text("Print","%DeepSee"),$$$Text("Enable printing for this scorecard","%DeepSee"))
	Quit $$$OK
}

/// This callback is responsible for creating the contents of the widget.
Method %OnCreateWidget(pGroup As %ZEN.Component.group) As %Status
{
	Set tSC = $$$OK
	Try {
		// DTB565 - required by excel/PDF export
		Set ..sessionCookie = %session.CSPSessionCookie
		
		// see if we have a data source
		Set tMsg = ""
		Set tController = ""
		Set tKPIClass = ""
		Set tDataSource = ..dataSource
		Set tExt = $P(tDataSource,".",$L(tDataSource,"."))
		If (tExt = "kpi") {
			Set tName = $P(tDataSource,".",1,$L(tDataSource,".")-1)
			Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
		}
		ElseIf (tExt = "metric") {
			Set tKPIClass = "Ens.BusinessMetricKPI"
		}
		ElseIf (tExt = "worksheet") {
			Set tKPIClass = "%DeepSee.KPIWorksheet"
		}

		Set tInvert = 1
		If (tKPIClass'="") {
			// add data controller to the widget
			Set tController = ##class(%ZEN.Auxiliary.dataController).%New()
			Set tController.id = ..%MakeWidgetId("controller")
			Set tController.modelClass = tKPIClass
			If (tExt = "metric") {
				Set tController.modelId = ..dataSource
			}
			ElseIf (tExt = "worksheet") {
				Set tController.modelId = ..dataSource
			}
			Set tSC = pGroup.%AddChild(tController)
			If $$$ISERR(tSC) Quit
			Set tInvert = 0
		}
		ElseIf (tExt="pivot") {
			// saved pivot
			// create a hidden pivotTable and use it as the controller
			Set tPivotDef=""
			If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(..dataSource)) {
				// DTB580 - Only set the folder item if we know it exists
				Set tPivotDef = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(..dataSource,.tSC)
				If $$$ISERR(tSC) Quit
			}
			If '$IsObject(tPivotDef) Quit

			Set tPivotTable = ##class(%DeepSee.Component.pivotTable).%New()
			Set tPivotTable.id = ..%MakeWidgetId("controller")
			Set tPivotTable.hidden = 1
			Set tSC = pGroup.%AddChild(tPivotTable)
			If $$$ISERR(tSC) Quit

			// copy information from the saved item to the graphical pivot
			Set tSC = tPivotDef.%CopyToComponent(tPivotTable)
			If $$$ISERR(tSC) Quit
			
			Set tController = tPivotTable
			Set tInvert = 1
		}
		Else {
			Set tMsg = $$$Text("ScoreCard is not connected to a data source","%DeepSee")
		}

		// add an SVG frame to the widget
		Set tFrame = ##class(%ZEN.SVGComponent.svgFrame).%New()
		Set tFrame.id = ..%MakeWidgetId("svgFrame")
		Set tFrame.layout = "flow"
		Set tSC = pGroup.%AddChild(tFrame)
		If $$$ISERR(tSC) Quit

		Set tCard = ##class(%DeepSee.Component.SVG.scoreCard).%New()
		Set tCard.id = ..%MakeWidgetId("scoreCard")
		Set tCard.pivotData = tInvert
		Do tFrame.%AddChild(tCard)
		// hide until after page is loaded
		Set tCard.hidden = 1

		If $IsObject(tController) {
			If (..subtype = "big") {
				Set tCard.cardSize = "big"
			}

			Set tCard.title = ""
			Set tCard.controllerId = tController.id
			Set tCard.onclickrow = "zenPage.getComponent("_..index_").rowClickHandler(row,value);"

			Set tColumnCount = ..%definition.dataProperties.Count()
			If (tColumnCount = 0) {
				// !!!
				//Set tCard.title = $$$Text("No properties defined","%DeepSee")
			}
			Else {
				For c=1:1:tColumnCount {
					Set tDataPropertyDef = ..%definition.dataProperties.GetAt(c)

					Set tColumn = ##class(%DeepSee.Component.SVG.scoreCardColumn).%New()
					Set tColumn.label = tDataPropertyDef.label
					Set tColumn.format = tDataPropertyDef.format
					Set tColumn.style = tDataPropertyDef.style
					Set tColumn.display = tDataPropertyDef.display
					Set tColumn.showAs = tDataPropertyDef.showAs
					Set tColumn.summary = tDataPropertyDef.summary
					Set tColumn.summaryValue = tDataPropertyDef.summaryValue
					Set tColumn.valueColumn = tDataPropertyDef.valueColumn
					Set tColumn.dataValue = tDataPropertyDef.dataValue
					Set tColumn.targetValue = tDataPropertyDef.targetValue
					Set tColumn.rangeLower = tDataPropertyDef.rangeLower
					Set tColumn.rangeUpper = tDataPropertyDef.rangeUpper
					Set tColumn.baseValue = tDataPropertyDef.baseValue
					Set tColumn.thresholdLower = tDataPropertyDef.thresholdLower
					Set tColumn.thresholdUpper = tDataPropertyDef.thresholdUpper
					Set tColumn.width = tDataPropertyDef.width
					Set tColumn.align = tDataPropertyDef.align
					Do tCard.columns.Insert(tColumn)
					Do:$IsObject($G(%page)) %page.%AddComponent(tColumn)
				}
			}
		}

		// JMD1128 See if there are overrides; test theme first
		Set tOverride = ""
		Set tJSON = ""
		Set tOverrideSource = ""
		If (..%definition.themeOverrides.%IsA("%Collection.AbstractArray")) {
			Set tJSON = ..%definition.themeOverrides.GetAt("scoreCard")
		}
		Else {
			// JSON provider
			Set tJSON = $property(..%definition.themeOverrides,"scoreCard")
		}
		Set:tJSON'="" tOverrideSource = "theme"

		If ($IsObject(..%definition.overrides)) {
			If (..%definition.overrides.%IsA("%Collection.AbstractArray")) {
				If (..%definition.overrides.GetAt("scoreCard")'="") {
					Set tJSON = ..%definition.overrides.GetAt("scoreCard")
					Set tOverrideSource = "local"
				}
			}
			Else {
				// JSON provider
				If ($property(..%definition.overrides,"scoreCard")) {
					Set tJSON = $property(..%definition.overrides,"scoreCard")
					Set tOverrideSource = "local"
				}
			}
		}

		If (tJSON'="") {
			Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%ParseJSON(tJSON,,.tOverride)
			If $$$ISERR(tSC) Quit
		}

		If ($IsObject(tOverride) && (tOverride."_type"= "scoreCard")) {
			// apply override properties
			Do tOverride.%CopyToArray(.tOverArray)
			Set p = $O(tOverArray(""))
			While (p'="") {
				If ($IsObject(tOverArray(p))) {
					If (p="columns") {
						// only apply columns if they are local
						// otherwise we change the data displayed!
						If (tOverrideSource="local") {
							Set tColList = tOverArray(p)
							Do tCard.columns.Clear()
							For cno=1:1:tColList.Count() {
								Set tColumn = ##class(%DeepSee.Component.SVG.scoreCardColumn).%New()
								Do tCard.columns.Insert(tColumn)
								Do:$IsObject($G(%page)) %page.%AddComponent(tColumn)

								Kill tColArray
								Do tColList.GetAt(cno).%CopyToArray(.tColArray)
								Set ap = $O(tColArray(""))
								While (ap'="") {
									If ($E(ap)'="_") {
										Set $Property(tColumn,ap) = tColArray(ap)
									}
									Set ap = $O(tColArray(ap))
								}
							}
						}
					}
				}
				ElseIf ($E(p)'="_") {
					Set $Property(tCard,p) = tOverArray(p)
				}
				Set p = $O(tOverArray(p))
			}
		}

		// apply invert after overrides
		Set tCard.pivotData = tInvert
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Called when page is loaded or widget is resized.
ClientMethod adjustContentSize(load, width, height) [ Language = javascript ]
{
	var svg = this.findComponent('svgFrame');
	if (!svg) return;

	var adjW = 4;
	var adjH = 0;

	var svgDiv = svg.getEnclosingDiv();
	svgDiv.style.width = width + 'px';
	svgDiv.style.height = height + 'px';

	// adjust size of svg frame
	var svgWid = width - adjW;
	var svgHgt = height - adjH;
	if (svgWid != svg.width) {
		svg.setProperty("width",svgWid+'px');
	}
	if (svgHgt != svg.height) {
		svg.setProperty("height",svgHgt+'px');
	}

	// adjust card
	var card = this.findComponent('scoreCard');
	if (card) {
		// n.b. the order these calls is important for the server refresh case
		if (card.hidden) {
			card.setProperty("hidden",false);
		}
		if (card.cardHeight) {
			if (card.cardHeight != card.height) {
				card.setProperty("height",card.cardHeight);
			}
		}
		else {
			if (svgHgt != card.height) {
				card.setProperty("height",svgHgt);
			}
		}
		if (svgWid != card.width) {
			card.setProperty("width",svgWid);
		}
	}
}

/// If this widget contains a data controller, return it.
/// This allows for generic capabilities in this base class.
ClientMethod getDataController() [ Language = javascript ]
{
	return this.findComponent('controller');
}

/// If this widget contains a data controller, return it.
Method %GetDataController() As %ZEN.Auxiliary.abstractController
{
	Quit ..%FindComponent("controller")
}

/// Test if this widget is ready to be resized.
ClientMethod isReady() [ Internal, Language = javascript ]
{
	var controller = this.getDataController();
	if (controller && controller.hasData) {
		return controller.hasData();
	}
	return true;
}

/// Click handler for row in scoreCard.
ClientMethod rowClickHandler(row, value) [ Internal, Language = javascript ]
{
	// update curr values
	this.currValue = value;
	this.currSeriesNo = parseInt(row) + 1;

	// What event to raise?
	this.raiseEventHandler('click');
}

/// Return an object describing what to display for this level within the navigator.
/// Invoked from dashboard viewer.
ClientMethod navGetContentForLevel(level, key, value) [ Internal, Language = javascript ]
{
	var content = { title:'', items:[] };

	// key may take the form key:no
	var ckey = key;		// make local copy of key
	var keyNo = 0;
	if (ckey.toString().indexOf(':')>0) {
		var t = ckey.split(':');
		ckey = t[0];
		keyNo = parseInt(t[1]);
	}

	switch (ckey) {
	case 'WidgetSettings':
		// get common content
		content = this.invokeSuper('navGetContentForLevel',arguments);

		// scorecard specific
		content.items[content.items.length] = {display:'section', caption:$$$Text('Scorecard Settings','%DeepSee') };
		content.items[content.items.length] = {display:'image-caption-hz', image:'deepsee/spreadsheet_48.gif', caption:$$$Text('Scorecard','%DeepSee'), action:'drill', key:'widget-card-ScoreCardSettings'};
		break;

	default:
		// pull key apart; dispatch on second piece
		var kt = ckey.toString().split('-');
		switch(kt[1]) {
		case 'common':
			// dispatch to super class
			content = this.invokeSuper('navGetContentForLevel',arguments);
			break;
		case 'card':
			// dispatch
			var chart = this.findComponent('scoreCard');
			if (!chart) {
				content.items[content.items.length] = {display:'info', caption:$$$Text('Scorecard is not Connected to a Data Source','%DeepSee'), captionStyle:'color:darkred;white-space: normal;width:260px;', style:'height:150px;' };
			}
			else {
				// pull 'widget-' off of key
				var kt = ckey.toString().split('-');
				kt.splice(0,1);
				var k2 = kt.join('-');
				k2 = (keyNo==='') ? k2 : (k2 + ':' + keyNo);
				content = this.scorecardGetContentForLevel(zenPage.getNavigator(),chart,level,k2,'');

				// add prefix to the returned keys
				if (content.items) {
					for (var n = 0; n < content.items.length; n++) {
						var k = content.items[n].key;
						if (k) {
							content.items[n].key = 'widget-' + k;
						}
					}
				}
			}
			break;
		}
	}

	return content;
}

/// Click on header button in navigator.
ClientMethod navHeaderButtonClick(key) [ Language = javascript ]
{
	var ckey = key;
	var kt = ckey.toString().split('-');
	var target = kt[0];

	switch(target) {
	case 'card':
		var chart = this.findComponent('scoreCard');
		this.scorecardHeaderButtonClick(zenPage.getNavigator(),chart,key);
		break;
	default:
		// send to super
		this.invokeSuper('navHeaderButtonClick',arguments);
		break;
	}
}

/// Click on close button in navigator.
ClientMethod navCloseButtonClick(key) [ Language = javascript ]
{
	// pull 'widget-' off of key
	var ckey = key;
	var kt = ckey.toString().split('-');
	kt.splice(0,1);
	var k2 = kt.join('-');
	var target = kt[0];

	switch(target) {
	case 'card':
		var chart = this.findComponent('scoreCard');
		var oc = chart.columns.length;
		this.scorecardCloseButtonClick(zenPage.getNavigator(),chart,k2);
		if (oc!=chart.columns.length) {
			// column deleted
			zenPage.setModified(true);
			this.navDataChange('widget-card-columnRemove','',true);
		}
		break;
	default:
		// send to super
		this.invokeSuper('navCloseButtonClick',arguments);
		break;
	}
}

/// Re-arrange of a list in navigator.
ClientMethod navDataArrange(key, swap, final) [ Language = javascript ]
{
	// pull 'widget-' off of key
	var kt = key.toString().split('-');
	kt.splice(0,1);
	var k2 = kt.join('-');

	var chart = this.findComponent('scoreCard');
	this.scorecardDataArrange(zenPage.getNavigator(),chart,k2,swap,final);
	if (final) {
		zenPage.setModified(true);
		this.navDataChange('widget-card-columnMoved','',true);
	}
}

/// Change of data value in navigator.
ClientMethod navDataChange(key, value, final) [ Language = javascript ]
{
	// pull 'widget-' off of key
	var ckey = key;
	var kt = ckey.toString().split('-');
	kt.splice(0,1);
	var k2 = kt.join('-');
	var target = kt[0];

	// now test 2nd piece of key
	switch (target) {
	case 'common':
		this.invokeSuper('navDataChange',arguments);
		break;
	case 'card':
		var svg = this.findComponent('svgFrame');
		var chart = this.findComponent('scoreCard');
		this.scorecardDataChange(zenPage.getNavigator(),svg,chart,k2,value,final);
		if (final) {
			var widgetDef = this.getDefinition();
			if (widgetDef) {
				// update overrides
				// ignore properties in the skip list
				skip = {
					parent:true, window:true, controller:true, 
					superClass:true, controllerId:true, height:true,
					seriesSize:true, seriesCount:true,
					seriesNames:true, yAxisList:true
				}
				var jsonOver = this.componentToJSON(chart,0,skip);
				if (zenGet(widgetDef.themeOverrides['scoreCard'])!=jsonOver) {
					widgetDef.overrides['scoreCard'] = jsonOver;
				}
				else {
					delete widgetDef.overrides['scoreCard'];
				}
			}
		}
		break;
	}
}

/// Test if there are any style overrides for this widget.
ClientMethod hasOverrides() [ Language = javascript ]
{
	var def = this.getDefinition();
	return (def&&def.overrides['scoreCard']) ? true : false;
}

/// Reset any style overrides for this widget.
ClientMethod resetOverrides() [ Language = javascript ]
{
	var def = this.getDefinition();
	if (def && def.overrides['scoreCard']) {
		delete def.overrides['scoreCard'];
		if (zenPage.recreateWidget) {
			zenPage.recreateWidget(this.widgetKey);
		}
	}
}

/// Return an array of current style overrides for this widget.
/// Used to save to a theme.
ClientMethod getOverrides() [ Language = javascript ]
{
	var overrides = {};
	var def = this.getDefinition();
	if (def) {
		if (def.themeOverrides['scoreCard']) {
			overrides['scoreCard'] = def.themeOverrides['scoreCard'];
		}
		if (def.overrides['scoreCard']) {
			overrides['scoreCard'] = def.overrides['scoreCard'];
		}
	}

	return overrides;
}

/// PDF export for SVG using the svgImageProvider
ClientMethod exportPDF(printMultiple, preserveTempFiles) [ Language = javascript ]
{
	// Method added by DTB250
	var parms = {};
	var table = this.getDataController();
	// pull print settings from widgetDef.properties;
	var widgetDef = this.getDefinition();
	
	printMultiple = (printMultiple) ? printMultiple : false;				// DTB251 - For multi-tab browser display
	preserveTempFiles = (preserveTempFiles) ? preserveTempFiles : false;	// DTB251 - For merging into a single PDF
	
	// Find filter values and names from the data source
	var filterNames = [];
	var filterValues = [];

	if (''!==table.kpi) {
		if (table&&table.filters) {
			// get filter values
			for (var n = 0; n < table.filters.length; n++) {
				var filter = table.filters[n];
				if (filter.text!='') {
					filterNames[filterNames.length] = filter.spec;
					var val = filter.text.toString();
					// unquote
					if ('&'==val.charAt(0)) {
						val = val.substring(2,val.length-1);
					}
					filterValues[filterValues.length] = val;
				}
			}
		}
		else {
			// Try to print filters from the widget state
			for (var filter in this.filterText) {
				var filterValue = this.filterText[filter]
				if (filterValue) {
					filterNames[filterNames.length] = filter;
					filterValues[filterValues.length] = filterValue;
				}
			}	
		}
		
		// Try to add pivot variables
		for (prop in table.pivotVariables) {
			filterNames[filterNames.length]= prop;
			filterValues[filterValues.length] = table.pivotVariables[prop];
		}
	}
	else if ((''!=table.cubeName) && (''!=table.queryKey)) {
		table.getFilterInfo(filterNames, filterValues);
	}
	
	// Convert the filters into a single table that can be printed
	var util = zenPage.getComponentById("svgUtil");
	
 	parms.title = widgetDef.title;
 	parms.filterTable = util.prepareFilterTable(filterNames,filterValues);
 	parms.preserveTempFiles = preserveTempFiles;		// DTB251 - Add option to preserve temp files
 	parms.printMultiple = printMultiple;				// DTB251 - Communicate multiple widget print to the printer
	
	this.prepareSvgPrintParameters(parms);				// DTB565 - Normalize the printing parameters
	
	this.printSVGContent(this.id+'/svgFrame',parms);
}

/// This callback is called just before controls are added to the top of the widget.
/// <var>pGroup</var> is the header in which new Zen control can be added.
Method %OnCreateControls(pGroup As %ZEN.Component.group) As %Status
{
	// get default values for widget properties
	Do ..%GetWidgetPropertyInfo(..subtype,.tList)
	Set n = $O(tList(""))
	While (n'="") {
		Set tName = $LG(tList(n),1)
		Set tPValue(tName) = ..%definition.properties.GetAt(tName)
		Set:tPValue(tName)="" tPValue(tName) = $LG(tList(n),2)
		Set n = $O(tList(n))
	}
	
	// DTB250 - Add pdf export
	If (+$G(tPValue("print"))) {
		Set tButton = ##class(%ZEN.Component.image).%New()
		Set tButton.src = "deepsee/ds2_printer_22.png"
		Set tButton.title = $$$Text("Create PDF from this scorecard","%DeepSee")
		If (..previewMode) {
			Set tButton.disabled = 1
		}
		Else {
			Set tButton.onclick = "zenPage.getComponent("_..index_").exportPDF();"
		}
		Do pGroup.%AddChild(tButton)
	}
	
	Quit $$$OK
}

/// Notification to subclasses that filter has changed.
ClientMethod onApplyFilters(refresh) [ Internal, Language = javascript ]
{
	// Method Added by DTB977
	if (this.currSeriesNo > 0) {
		// A series was selected prior to invoking a filtering operation. Clear that prior selection.
		var card = this.findComponent('scoreCard');
		if (card) {
			card.selectRow(-1);
		}
		this.currSeriesNo = null;
		this.currValue = null;
	}
}

}
