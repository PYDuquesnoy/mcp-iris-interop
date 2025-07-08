/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A specialized DeepSee Dashboard widget that displays a user-defined "portlet".
/// A portlet serves users defined HTML or SVG content that is displayed within the widge.
/// The portlet type is specified by the <property>subtype</property> property.<br/>
/// If you wish to create your own portlet, do NOT subclass this component; instead,
/// create a subclass of the <class>%DeepSee.Component.Portlet.abstractPortlet</class> class.
Class %DeepSee.Component.Widget.portlet Extends %DeepSee.Component.Widget.widget [ System = 4 ]
{

/// Style for widget sections
XData Style
{
<style type="text/css">

.portletError {
	background: #f6f8f9;
	padding: 3px;
	color: darkred;
	border: 1px solid #808080;
	box-shadow: 2px 2px 2px #808080;
	position: absolute;
	font-family: arial;
	font-size: 12pt;
	z-index: 10;
}
</style>
}

/// Return information used to list this widget within the "widget catalog".
ClassMethod %GetCatalogInfo(Output pInfo As %List, Output pSubtypeList As %List) As %Status
{
	Kill pInfo,pSubtypeList
	// $LB(name,caption,class,icon)
	Set pInfo = $LB(..%ClassName(0),$$$Text("Portlet","%DeepSee"),..%ClassName(1),"deepsee/door_48.gif")

	// find subclasses of abstract portlet -- these are the subtypes
	// find all subclasses of widget
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Set tSC = tRS.Execute("%DeepSee.Component.Portlet.abstractPortlet")
	If $$$ISERR(tSC) Quit
	Set n = 0
	While (tRS.Next(.tSC)) {
		If $$$ISERR(tSC) Quit
		Set tClassName = $G(tRS.Data("Name"))

		If ($$$comClassDefined(tClassName)) {
			Set tAbstract = +$$$comClassKeyGet(tClassName,$$$cCLASSabstract)
			If ('tAbstract) {
				// get name and icon from portlet class
				Set tName = $classmethod(tClassName,"%OnGetPortletName")
				Set:tName="" tName = $P(tClassName,".",$L(tClassName,".")) 
				Set tIcon = $classmethod(tClassName,"%OnGetPortletIcon")
				Set:tIcon="" tIcon = "deepsee/door_48.gif"
				Set pSubtypeList($I(n)) = $LB(tClassName,tName,,tIcon)
			}
		}
	}
	Quit $$$OK
}

/// Return information on additional "properties" supported by this widget for the given subtype.
ClassMethod %GetWidgetPropertyInfo(pSubtype As %String, Output pInfo As %List, ByRef pSettings) As %Status
{
	// DTB111 - add settings by reference
	Kill pInfo

	// return a list of the form:
	// pInfo(n) = $LB(name,value,type,caption,title)
	// dispatch to portlet class
	Try {
		Set tSC = $classmethod(pSubtype,"%OnGetPortletSettings",.pInfo,.pSettings)
		// + WAL077 -- Add some standard system settings to pInfo, place after
		// DTB110 - remove duplicate analyzer and reorder to match standard widgets
		If $$$comClassDefined("%DeepSee.UI.MDXPDF") {
			Set pInfo($I(pInfo)) = $LB("print",0,"%Boolean",$$$Text("Print","%DeepSee"),$$$Text("Enable printing for this widget","%DeepSee"))		// DTB236
		}
		Set pInfo($I(pInfo)) = $LB("analyzer",1,"%Boolean",$$$Text("Analyzer","%DeepSee"),$$$Text("Enable Analyzer dialog for this pivot","%DeepSee"))
		Set pInfo($I(pInfo)) = $LB("excel",0,"%Boolean",$$$Text("Excel Export","%DeepSee"),$$$Text("Enable Excel export for this pivot","%DeepSee"))
		Set pInfo($I(pInfo)) = $LB("initialExecute",1,"%Boolean",$$$Text("Initial Execute","%DeepSee"),$$$Text("If true, then execute the pivot query when the dashboard is displayed","%DeepSee"))
		// - WAL077
	}
	Catch(ex) {
	}
	Quit $$$OK
}

/// This callback is responsible for creating the contents of the widget.
Method %OnCreateWidget(pGroup As %ZEN.Component.group) As %Status
{
	Set tSC = $$$OK
	Try {
		// + WAL077 -- required by excel/PDF export
		Set ..sessionCookie = %session.CSPSessionCookie
		
		// add invisible div to support style hacking
		// add pivot table to the widget
		Set tHTML = ##class(%ZEN.Component.html).%New()
		Set tHTML.id = ..%MakeWidgetId("test")
		Set tHTML.enclosingStyle = "display:none;"
		Set tSC = pGroup.%AddChild(tHTML)
		If $$$ISERR(tSC) Quit
		// - WAL077
		
		// +DTB111 - make a settings array to expose to the %OnGetPortletSettings callback
		For ii=1:1:..settings.Count() {
			Set tValue = ..settings.GetNext(.tName)
			If ($$$UPPER(tName)="PORTLET") {
				For p = 1:1:$L(tValue,"~") {
					Set tSetting = $P(tValue,"~",p)
					Set tSettings($$$UPPER($P(tSetting,".",1))) = $P(tSetting,".",2)
				}
			}
		}

		// get default values for widget properties
		Do ..%GetWidgetPropertyInfo(..subtype,.tList,.tSettings)
		// -DTB111
		Set n = $O(tList(""))
		While (n'="") {
			Set tName = $LG(tList(n),1)
			Set tPValue(tName) = ..%definition.properties.GetAt(tName)
			Set:tPValue(tName)="" tPValue(tName) = $LG(tList(n),2)
			Set n = $O(tList(n))
		}

		// add portlet to the widget
		Set tClass = ..subtype
		If (tClass = "") {
			Set tPortlet = ##class(%DeepSee.Component.Portlet.abstractPortlet).%New()
		}
		Else {
			Set tPortlet = $classmethod(tClass,"%New")
		}
		// copy settings into portlet
		Merge tPortlet.settings = tPValue

		Set tPortlet.id = ..%MakeWidgetId("portlet")
		Set tPortlet.enclosingStyle = "background: white;"
		Set tSC = pGroup.%AddChild(tPortlet)
		If $$$ISERR(tSC) Quit

		// If we have a data source, create a data controller
		Set tSC = ..%CreateController(pGroup, .tController)
		If $$$ISERR(tSC) Quit
	
		// connect portlet to controller
		If $IsObject(tController) {
			Set:$IsObject(tController) tPortlet.controllerId = tController.id
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This callback is called just before controls are added to the top of the widget.
/// <var>pGroup</var> is the header in which new Zen control can be added.
Method %OnCreateControls(pGroup As %ZEN.Component.group) As %Status
{
	// Added by WAL077 to make excel/pdf export available to portlets
	// get default values for widget properties
	Do ..%GetWidgetPropertyInfo(..subtype,.tList)
	Set n = $O(tList(""))
	While (n'="") {
		Set tName = $LG(tList(n),1)
		Set tPValue(tName) = ..%definition.properties.GetAt(tName)
		Set:tPValue(tName)="" tPValue(tName) = $LG(tList(n),2)
		Set n = $O(tList(n))
	}

	// pdf export
	If (+$G(tPValue("print"))) {
		Set tButton = ##class(%ZEN.Component.image).%New()
		Set tButton.src = "deepsee/ds2_printer_22.png"
		Set tButton.title = $$$Text("Create PDF from this pivot","%DeepSee")
		If (..previewMode) {
			Set tButton.disabled = 1
		}
		Else {
			Set tButton.onclick = "zenPage.getComponent("_..index_").exportPDF();"
		}
		Do pGroup.%AddChild(tButton)
	}

	// excel export
	If (+$G(tPValue("excel"))) {
		Set tButton = ##class(%ZEN.Component.image).%New()
		Set tButton.src = "deepsee/ds2_action_44.png"
		Set tButton.title = $$$Text("Export table to Excel","%DeepSee")
		If (..previewMode) {
			Set tButton.disabled = 1
		}
		Else {
			Set tButton.onclick = "zenPage.getComponent("_..index_").exportExcel();"
		}
		Do pGroup.%AddChild(tButton)
	}

	Quit $$$OK
}

/// If this widget has a data source, create a data controller that
/// will serve this data to the client.<br/>
/// The controller's id is "controller" (within the scope of this widget).
Method %CreateController(pGroup As %ZEN.Component.abstractGroup, Output pController As %ZEN.Auxiliary.abstractController) As %Status
{
	Set tSC = $$$OK
	Try {
		// see if we have a data source
		Set tMsg = ""
		Set pController = ""
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

		If (tKPIClass'="") {
			// add data controller to the widget
			Set pController = ##class(%ZEN.Auxiliary.dataController).%New()
			Set pController.id = ..%MakeWidgetId("controller")
			Set pController.modelClass = tKPIClass
			If (tExt = "metric") {
				Set pController.modelId = ..dataSource
			}
			ElseIf (tExt = "worksheet") {
				Set pController.modelId = ..dataSource
			}
			Set tSC = pGroup.%AddChild(pController)
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
			If '$IsObject(tPivotDef) {
				// Show error on widget
				Set tLabel = ##class(%ZEN.Component.label).%New()
				Set tLabel.value = $$$FormatText($$$Text("The data source '%1' is missing.","%DeepSee"),..dataSource)
				Set tLabel.enclosingClass = "portletError"
				Set tSC = pGroup.%AddChild(tLabel)
				If $$$ISERR(tSC) Quit
			}

			Set tPivotTable = ##class(%DeepSee.Component.pivotTable).%New()
			Set tPivotTable.id = ..%MakeWidgetId("controller")
			Set tPivotTable.hidden = 1
			Set tSC = pGroup.%AddChild(tPivotTable)
			If $$$ISERR(tSC) Quit

			// test for bad pivot
			If $IsObject(tPivotDef) {
				// copy information from the saved item to the graphical pivot
				Set tSC = tPivotDef.%CopyToComponent(tPivotTable)
				If $$$ISERR(tSC) Quit
			}
			
			Set pController = tPivotTable
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Called when page is loaded or widget is resized.
ClientMethod adjustContentSize(load, width, height) [ Language = javascript ]
{
	var portlet = this.findComponent('portlet');
	if (portlet) {
		var portletDiv = portlet.getEnclosingDiv();
		portletDiv.style.width = width-10 + 'px';
		portletDiv.style.height = height + 'px';

		// notify portlet
		if (portlet.adjustContentSize) {
			portlet.adjustContentSize(load,width,height);
		}
	}
}

/// Notification that a filter has changed.
ClientMethod onApplyFilters(refresh) [ Language = javascript ]
{
	// dispatch to portlet
	var portlet = this.findComponent('portlet');
	if (portlet && portlet.onApplyFilters) {
		portlet.onApplyFilters(refresh,this);
	}
}

/// If this widget contains a data controller, return it.
/// This allows for generic capabilities in this base class.
ClientMethod getDataController() [ Language = javascript ]
{
	return this.findComponent('controller');
}

/// Export current query to excel
ClientMethod exportExcel() [ Language = javascript ]
{
	// Added by WAL077 to make excel/pdf export available to portlets
	var table = this.getDataController();
	var widgetDef = this.getDefinition();
	
	if (table && widgetDef) { // JSL4455 - use dashboard filter label name if available
		for (m=0; m < widgetDef.controls.length; m++) {
			var control = widgetDef.controls[m];
			if (control.action == 'applyFilter')  { // at filter control
				for (var n = 0; n < table.filters.length; n++) { // walk filters look for a match
					var filter = table.filters[n];
					if (control.label && control.targetProperty == filter.baseSpec) {
						filter._label = control.label;
					}
				}		
			}
		}
	}

	if (''!==table.kpi) {
		// get filter values
		var filterNames = [];
		var filterValues = [];
		var filterLabels = []; // JSL4455

		var fq = '';
		for (var n = 0; n < table.filters.length; n++) {
			var filter = table.filters[n];
			fq += '&FILTER='+encodeURIComponent(filter.spec)+':'+encodeURIComponent(filter.value);
			if (filter.text!='') {
				filterNames[filterNames.length] = filter.spec;
				var val = filter.text.toString();
				// unquote
				if ('&'==val.charAt(0)) {
					val = val.substring(2,val.length-1);
				}
				filterValues[filterValues.length] = val;
				filterLabels[filterLabels.length] = filter._label; // JSL4455
			}
		}
		for (prop in table.pivotVariables) { // JSL4376
			filterNames[filterNames.length]= prop;
			filterValues[filterValues.length] = table.pivotVariables[prop];
		}
		
		var cl = '';
		if (table.columnList!=='') {
			cl = '&COLUMNLIST=' + encodeURIComponent(table.columnList);
		}

		var url = zenLink('_DeepSee.UI.MDXExcel.zen?KPI=' + encodeURIComponent(table.kpi) + '&SOURCE='+ encodeURIComponent(table.dataSourceName) + fq + cl);
		if (filterNames.length > 0) {
			url += '&FILTERNAMES='+zenPage.CreateParameterNonce(filterNames.join('\n')); //APV017
			url += '&FILTERVALUES='+zenPage.CreateParameterNonce(filterValues.join('\n')); //APV017
			url += '&FILTERLABELS='+encodeURIComponent(filterLabels.join('\n')); // JSL4455
		}

		// title
		var title = table.printTitle;
		var subtitle = table.printSubtitle;
		if (title=='') {
			title = widgetDef.title;
		}

		url += '&TITLE='+encodeURIComponent(title);
		url += '&SUBTITLE='+encodeURIComponent(subtitle);

		// test for listing
		if (table.isDrillThrough) {
			url += '&LISTING=1';

			// JMD1332: preserve selection information
			url += '&SELECTEDRANGE='+encodeURIComponent(table.getSelectedRange()); 
			url += '&SELECTEDITEMS='+encodeURIComponent(table.getSelectedItems());
			url += '&LISTINGSORTCOLUMN='+encodeURIComponent(table.listingSortColumn);
			url += '&LISTINGSORTDIR='+encodeURIComponent(table.listingSortDir);
		}
		
		window.open(url,'excel','');
	}
	else if ((''!=table.cubeName) && (''!=table.queryKey)) {
		var filterNames = [];
		var filterValues = [];
		var filterLabels = []; // JSL4455
		table.getFilterInfo(filterNames, filterValues);
		for (var n = 0; n < table.filters.length; n++) { // JSL4455
			var filter = table.filters[n];
			filterLabels[filterLabels.length] = filter._label; // JSL4455
		}

		for (prop in table.pivotVariables) { // JSL4376
			filterNames[filterNames.length]= prop;
			filterValues[filterValues.length] = table.pivotVariables[prop];
		}

		var nonce = '';
		// WAL023 -- use resolved text
		var mdx = table.GetCurrentQueryText("resolved");  // WAL075 -- use getter method
		if (mdx.toString().length > 500) {
			// avoid long urls for IE!
			nonce = zenPage.CreateQueryNonce(mdx);
			if (nonce.toString().indexOf('ERROR:')>=0) {
				// error
				alert(nonce);
				return;
			}
		}
		if (nonce) {
			var url = '_DeepSee.UI.MDXExcel.zen?NONCE=' + encodeURIComponent(nonce);
		}
		else {
			var url = '_DeepSee.UI.MDXExcel.zen?MDX=' + encodeURIComponent(mdx);
		}

		if (table.listing!='') {
			url += '&LISTINGNAME='+encodeURIComponent(table.listing);
		}

		// JMD1029
		if (table.rowTotals) {
			url += '&ROWTOTALS=1';
		}
		if (table.columnTotals) {
			url += '&COLUMNTOTALS=1';
		}
		if (table.rowTotalAgg!='') {
			url += '&ROWTOTALAGG=' + table.rowTotalAgg;
		}
		if (table.columnTotalAgg!='') {
			url += '&COLUMNTOTALAGG=' + table.columnTotalAgg;
		}

		if (filterNames.length > 0) {
			url += '&FILTERNAMES='+zenPage.CreateParameterNonce(filterNames.join('\n')); //APV017
			url += '&FILTERVALUES='+zenPage.CreateParameterNonce(filterValues.join('\n')); //APV017
			//url += '&FILTERLABELS='+zenPage.CreateParameterNonce(filterLabels.join('\n')); // JSL4455
			
			url += '&FILTERLABELS='+encodeURIComponent(filterLabels.join('\n')); // JSL4455
		}

		// title
		// JMD1000: use printTitle first, then pivot title
		var title = table.printTitle;
		var subtitle = table.printSubtitle;
		if (title=='') {
			title = widgetDef.title;
		}

		url += '&TITLE='+encodeURIComponent(title);
		url += '&SUBTITLE='+encodeURIComponent(subtitle);

		window.open(url,'excel','');
	}
}

/// Export current query to pdf.
/// If we are in chart mode, export the chart.
ClientMethod exportPDF() [ Language = javascript ]
{
	// Added by WAL077 to make excel/pdf export available to portlets
	var url = '';
	var parms = {};
	var filters = [];
	
	var table = this.getDataController();
	// pull print settings from widgetDef.properties;
	var widgetDef = this.getDefinition();

	if (''!==table.kpi) {
		// get filter values
		var filterNames = [];
		var filterValues = [];

		for (var n = 0; n < table.filters.length; n++) {
			var filter = table.filters[n];
			filters[filters.length] = encodeURIComponent(filter.spec)+':'+encodeURIComponent(filter.value);

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
		for (prop in table.pivotVariables) { // JSL4376
			filterNames[filterNames.length]= prop;
			filterValues[filterValues.length] = table.pivotVariables[prop];
		}

		if (table.columnList!=='') {
			parms.COLUMNLIST = table.columnList;
		}

		url = '_DeepSee.UI.MDXPDF.zen'
		parms.KPI = table.kpi;
		parms.SOURCE = table.dataSourceName;
		if (filterNames.length > 0) {
			parms.FILTERNAMES = zenPage.CreateParameterNonce(filterNames.join('\n')); //APV017
			parms.FILTERVALUES = zenPage.CreateParameterNonce(filterValues.join('\n')); //APV017
		}

		// test for listing
		if (table.isDrillThrough) {
			url += '?LISTING=1';
		}
	}
	else if ((''!=table.cubeName) && (''!=table.queryKey)) {
		var filterNames = [];
		var filterValues = [];
		table.getFilterInfo(filterNames, filterValues);

		// WAL023 -- use resolved text
		var mdx = table.GetCurrentQueryText("resolved");  // WAL075 -- use getter method

		var nonce = '';
		if (mdx.toString().length > 10) {
			// avoid long urls for IE!
			nonce = zenPage.CreateQueryNonce(mdx);
			if (nonce.toString().indexOf('ERROR:')>=0) {
				// error
				alert(nonce);
				return;
			}
		}
		if (nonce) {
			parms.NONCE = nonce;
		}
		else {
			parms.MDX = mdx;
		}

		url = '_DeepSee.UI.MDXPDF.zen';
		if (table.rowTotals) {
			parms.ROWTOTALS = 1;
			parms.ROWTOTALAGG = table.columnTotalAgg;
		}
		if (table.columnTotals) {
			parms.COLUMNTOTALS = 1;
			parms.COLUMNTOTALAGG = table.rowTotalAgg;
		}
		if (table.listing!='') {
			parms.LISTINGNAME = table.listing;
		}
		if (filterNames.length > 0) {
			parms.FILTERNAMES = zenPage.CreateParameterNonce(filterNames.join('\n')); //APV017
			parms.FILTERVALUES = zenPage.CreateParameterNonce(filterValues.join('\n')); //APV017
		}

		// find background-color
		var div = this.findComponent('test').getEnclosingDiv();

		var style = table.columnHeaderStyle;
		if (style!='') {
			div.style.cssText = style;
			var bg = div.style.backgroundColor != '' ? 'background-color:'+div.style.backgroundColor+';' : '';
			parms.COLUMNSTYLE = style + bg;
		}
		var style = table.rowHeaderStyle;
		if (style!='') {
			div.style.cssText = style;
			var bg = div.style.backgroundColor != '' ? 'background-color:'+div.style.backgroundColor+';' : '';
			parms.ROWSTYLE = style + bg;
		}
		var style = table.cellStyle;
		if (style!='') {
			div.style.cssText = style;
			var bg = div.style.backgroundColor != '' ? 'background-color:'+div.style.backgroundColor+';' : '';
			parms.CELLSTYLE = style + bg;
		}
		
	}

	// if we are showing a chart, print a chart
	if (this.pivotView=='chart' && !table.isDrillThrough) {
		url = '_DeepSee.UI.ChartPDF.zen';

		// send serialized chart along for printing
		var chart = this.findComponent('svgChart');
		var xml = '';
		if (chart) {
			// JSL4146 - pass along chart series names
			chart.controller = table; // JSL4146
			
			var pnonce = '';
			pnonce = zenPage.CreateParameterNonce(""+chart.getSeriesNames()); // JSL4146 JSL4171
			if (pnonce.toString().indexOf('ERROR:')>=0) {
				// error
				alert(pnonce);
				return;
			}
			parms.SERIESNAMES = pnonce; // JSL4171
			
			if (this.hasDataColors) {
				parms.DATADRIVENSERIESCOLORS = this.chartGetSeriesColorsAsString(chart); // JSL4232 data-driven series colors
			}
			
			// pass along the *actual* axis titles
			var oldXTitle = false;
			if (chart.xAxis && ''==chart.xAxis.title) {
				chart.xAxis.title = chart.getXAxisTitle();
				oldXTitle = true;
			}
			var oldYAxisTitle = [];
			var hasLeft = false;
			var hasRight = false;
			for (var ya = 0; ya < chart.yAxisList.length; ya++) {
				var yAxis = chart.yAxisList[ya];
				if (yAxis && ''==yAxis.title) {
					var which = yAxis.labelPosition=='right'?'right':'left';
					if (yAxis.labelPosition=='right') {
						if (!hasRight) {
							chart.yAxisList[ya].title = chart.getYAxisTitle('right');
							oldYAxisTitle[ya] = true;
							hasRight = true;
						}
					}
					else {
						if (!hasLeft) {
							chart.yAxisList[ya].title = chart.getYAxisTitle('left');
							oldYAxisTitle[ya] = true;
							hasLeft = true;
						}
					}
				}
			}

			var add = {xAxis:'object', yAxisList:'list'};
			var skip = {
				controllerId:true, seriesCount:true, seriesSize:true,
				onelementClick:true
				};
			var xml = chart.objectToXML(chart,chart._type,add,skip);
			// restore axis titles
			if (oldXTitle) {
				chart.xAxis.title = '';
			}
			for (var ya = 0; ya < chart.yAxisList.length; ya++) {
				if (oldYAxisTitle[ya]) {
					chart.yAxisList[ya].title = '';
				}
			}
		}
		// use nonce for XML
		var xnonce = '';
		if (xml.toString().length > 10) { // PDF export involves a lot of param and avoiding long URLs is more of a problem
			// avoid long urls for IE!
			xnonce = zenPage.CreateQueryNonce(xml,'XML');
			if (xnonce.toString().indexOf('ERROR:')>=0) {
				// error
				alert(xnonce);
				return;
			}
		}
		if (xnonce) {
			parms.XNONCE = xnonce;
		}
		else {
			parms.XML = xml;
		}
		
		//+ JSL4144 - set parm corresponding to chartLegend
		var legend = this.findComponent('chartLegend');
		if (legend) {
			parms.LEGENDPOSITION = this.legendPosition; // JSL4163
			parms.LEGENDLABELS = legend.legendLabels;
			parms.LEGENDTITLE = legend.legendTitle;
			var legendLabelArray=parms.LEGENDLABELS.split(",");
			parms.LEGENDCOLORS = '';
			var sep = "";
			for (var i=0; i < legendLabelArray.length; i++) {
				parms.LEGENDCOLORS += sep + chart.getSeriesColor(i);
				sep = ";"
			}

			var pnonce = '';
			pnonce = zenPage.CreateParameterNonce(""+legend.legendStyle);     // JSL4171
			if (pnonce.toString().indexOf('ERROR:')>=0) {
				// error
				alert(pnonce);
				return;
			}
			
			parms.LEGENDSTYLE = pnonce; // JSL4171
		}
		//- JSL4144
		
		parms.WIDGETTITLE = widgetDef.title // JSL4146

	} else {
		if (table.isDrillThrough) {
			/* JSL4250 */var listingFilters=table.listingFilters.join(",")
			var lfArray = [];
			for (var n = 0;n < table.listingFilters.length;n++) {
				var listingFilter = table.listingFilters[n];
				lfArray[lfArray.length] = listingFilter.spec;
			}
		}
		
	}

	// general parms
	if (table) {
		parms.TITLE = table.printTitle;
		// JSL4199 if title is null used title from widgetDef
		if (parms.TITLE == "") {
			if (widgetDef) {
				parms.TITLE = widgetDef.title;
			}
		}
		
		parms.SUBTITLE = table.printSubtitle;

		if (table.showZebra) {
			parms.ZEBRA = 1;
		}
		parms.EVENROWSTYLE = table.evenRowStyle; // JSL4280
		parms.LABELWIDTH = table.printLabelWidth;
		parms.CELLWIDTH = table.printCellWidth;
		parms.ROWCAPTION = table.rowCaptionText;

		if (table.printPageSize) {
			parms.PAGESIZE = table.printPageSize;
		}
		if (table.printOrientation) {
			parms.ORIENTATION = table.printOrientation;
		}
		// JSL4302
		if (typeof table.printSubtitleOn) {
			parms.PRINTSUBTITLEON = table.printSubtitleOn;
		}
		// JSL4320
		if (table.showUser) {
			parms.SHOWUSER = table.showUser
		}
	
		// JSL4219
		if (table.maxRows) {
			parms.MAXROWS = table.maxRows;
		}
		// JSL4218
		if (table.borderLeftCell) {
			parms.BORDERLEFTCELL = table.borderLeftCell;
		}
		if (table.borderRightCell) {
			parms.BORDERRIGHTCELL = table.borderRightCell;
		}
		if (table.borderTopCell) {
			parms.BORDERTOPCELL = table.borderTopCell;
		}
		if (table.borderBottomCell) {
			parms.BORDERBOTTOMCELL = table.borderBottomCell;
		}
		if (table.borderLeftCol) {
			parms.BORDERLEFTCOL = table.borderLeftCol;
		}
		if (table.borderRightCol) {
			parms.BORDERRIGHTCOL = table.borderRightCol;
		}
		if (table.borderTopCol) {
			parms.BORDERTOPCOL = table.borderTopCol;
		}
		if (table.borderBottomCol) {
			parms.BORDERBOTTOMCOL = table.borderBottomCol;
		}
		if (table.borderLeftRow) {
			parms.BORDERLEFTROW = table.borderLeftRow;
		}
		if (table.borderRightRow) {
			parms.BORDERRIGHTROW = table.borderRightRow;
		}
		if (table.borderTopRow) {
			parms.BORDERTOPROW = table.borderTopRow;
		}
		if (table.borderBottomRow) {
			parms.BORDERBOTTOMROW = table.borderBottomRow;
		}

		if (table.showFilters) {
			parms.SHOWFILTERS = table.showFilters;
		}

		if (table.showListingFilters) { // JSL4250
			parms.SHOWLISTINGFILTERS = table.showListingFilters;
		}

		if (table.listingFontSize) { // JSL4279
			parms.LISTINGFONTSIZE = table.listingFontSize;
		}

		if (table.showZebraStripes) { // JSL4256
			parms.SHOWZEBRASTRIPES = table.showZebraStripes;
		}

		if (table.showDate) { // JSL4250
			parms.SHOWDATE = table.showDate;
		}

		if (table.printMarginTop) {
			parms.MARGINTOP = table.printMarginTop;
		}
		if (table.printMarginBottom) {
			parms.MARGINBOTTOM = table.printMarginBottom;
		}
		if (table.printMarginLeft) {
			parms.MARGINLEFT = table.printMarginLeft;
		}
		if (table.printMarginRight) {
			parms.MARGINRIGHT = table.printMarginRight;
		}
	}
	
	// JMD1207
	if (widgetDef && widgetDef.properties) {
		if (widgetDef.properties.printTitle) {
			parms.TITLE = widgetDef.properties.printTitle;
		}
		if (widgetDef.properties.printSubtitle) {
			parms.SUBTITLE = widgetDef.properties.printSubtitle;
		}

		if (widgetDef.properties.printPageSize) {
			parms.PAGESIZE = widgetDef.properties.printPageSize;
		}
		if (widgetDef.properties.printOrientation) {
			parms.ORIENTATION = widgetDef.properties.printOrientation;
		}
		if (widgetDef.properties.printSubtitleOn) {
			parms.PRINTSUBTITLEON = widgetDef.properties.printSubtitleOn;
		}
		if (widgetDef.properties.showUser) { // JSL4320
			parms.SHOWUSER = widgetDef.properties.showUser;
		}
		if (widgetDef.properties.printMarginTop) {
			parms.MARGINTOP = widgetDef.properties.printMarginTop;
		}
		if (widgetDef.properties.printMarginBottom) {
			parms.MARGINBOTTOM = widgetDef.properties.printMarginBottom;
		}
		if (widgetDef.properties.printMarginLeft) {
			parms.MARGINLEFT = widgetDef.properties.printMarginLeft;
		}
		if (widgetDef.properties.printMarginRight) {
			parms.MARGINRIGHT = widgetDef.properties.printMarginRight;
		}
		// JSL419
		if (widgetDef.properties.maxRows) {
			parms.MAXROWS = widgetDef.properties.maxRows;
		}
		// JSL4218
		if (widgetDef.properties.borderLeftCell) {
			parms.BORDERLEFTCELL = widgetDef.properties.borderLeftCell;
		}
		if (widgetDef.properties.borderRightCell) {
			parms.BORDERRIGHTCELL = widgetDef.properties.borderRightCell;
		}
		if (widgetDef.properties.borderTopCell) {
			parms.BORDERTOPCELL = widgetDef.properties.borderTopCell;
		}
		if (widgetDef.properties.borderBottomCell) {
			parms.BORDERBOTTOMCELL = widgetDef.properties.borderBottomCell;
		}
		if (widgetDef.properties.borderLeftCol) {
			parms.BORDERLEFTCOL = widgetDef.properties.borderLeftCol;
		}
		if (widgetDef.properties.borderRightCol) {
			parms.BORDERRIGHTCOL = widgetDef.properties.borderRightCol;
		}
		if (widgetDef.properties.borderTopCol) {
			parms.BORDERTOPCOL = widgetDef.properties.borderTopCol;
		}
		if (widgetDef.properties.borderBottomCol) {
			parms.BORDERBOTTOMCOL = widgetDef.properties.borderBottomCol;
		}
		if (widgetDef.properties.borderLeftRow) {
			parms.BORDERLEFTROW = widgetDef.properties.borderLeftRow;
		}
		if (widgetDef.properties.borderRightRow) {
			parms.BORDERRIGHTROW = widgetDef.properties.borderRightRow;
		}
		if (widgetDef.properties.borderTopRow) {
			parms.BORDERTOPROW = widgetDef.properties.borderTopRow;
		}
		if (widgetDef.properties.borderBottomRow) {
			parms.BORDERBOTTOMROW = widgetDef.properties.borderBottomRow;
		}
		
		// JSL4184
		if (widgetDef.properties.showFilters) {
			parms.SHOWFILTERS = widgetDef.properties.showFilters;
		}
		if (widgetDef.properties.showListingFilters) { // JSL4520
			parms.SHOWLISTINGFILTERS = widgetDef.properties.showListingFilters;
		}
		if (widgetDef.properties.showDate) { // JSL4520
			parms.SHOWDATE = widgetDef.properties.showDate;
		}
		if (widgetDef.properties.listingFontSize) { // JSL4279
			parms.LISTINGFONTSIZE = widgetDef.properties.listingFontSize;
		}
		if (widgetDef.properties.showZebraStripes) { // JSL4526
			parms.SHOWZEBRASTRIPES = widgetDef.properties.showZebraStripes;
		}
		
		if (widgetDef.properties.filterTableStyle) {
			parms.FILTERTABLESTYLE = widgetDef.properties.filterTableStyle;
		}
		if (widgetDef.properties.filterTableCaptionStyle) {
			parms.FILTERTABLECAPTIONSTYLE = widgetDef.properties.filterTableCaptionStyle;
		}
		if (widgetDef.properties.filterTableItemStyle) {
			parms.FILTERTABLEITEMSTYLE = widgetDef.properties.filterTableItemStyle;
		}
		if (widgetDef.properties.nowDisplayFormat) {
			parms.NOWDISPLAYFORMAT = widgetDef.properties.nowDisplayFormat;
		}

	}

	// JMD1332
	if (table.getSelectedRange()) {
		parms.SELECTEDRANGE = table.getSelectedRange();
	}
	if (table.getSelectedItems()) {
		parms.SELECTEDITEMS = table.getSelectedItems();
	}
	if (table.listingSortColumn) {
		parms.LISTINGSORTCOLUMN = table.listingSortColumn;
	}
	if (table.listingSortDir) {
		parms.LISTINGSORTDIR = table.listingSortDir;
	}

	// get filter values - JSL4182
	var filterNames = [];
	var filterValues = [];
	table.getFilterInfo(filterNames,filterValues);
	for (prop in table.pivotVariables) { // JSL4376
		filterNames[filterNames.length]= prop;
		filterValues[filterValues.length] = table.pivotVariables[prop];
	}
	
	/* JSL4196 comment out
	var fq = '';
	for (var n = 0; n < table.filters.length; n++) {
		var filter = table.filters[n];
		fq += '&FILTER='+encodeURIComponent(filter.spec)+':'+encodeURIComponent(filter.value);
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
	*/
	
	// open window to generate PDF
	if (url) {
		url = zenLink(url);
		
		var count = 0;
		var questionflag = url.indexOf('?') >= 0;
		for (var p in parms) {
			if (parms[p]!=='') {
				url += (count || questionflag ?'&':'?') + p + '=' + encodeURIComponent(parms[p]);
				count++;
			}
		}
		/* JSL4196 comment out
		for (var n = 0; n < filters.length; n++) {
			// fq += '&FILTER='+encodeURIComponent(filter.spec)+':'+encodeURIComponent(filter.value);
			url += '&FILTER=' + filters[n];
		}
		*/
		if (filterNames.length > 0) { // JSL4182
			url += '&FILTERNAMES='+zenPage.CreateParameterNonce((filterNames.join('\n'))); //APV017
			url += '&FILTERVALUES='+zenPage.CreateParameterNonce((filterValues.join('\n'))); //APV017
		}
		if (lfArray) {
			if (lfArray.length > 0) {
				url += '&LISTINGFILTERS='+encodeURIComponent(lfArray.join('\n'));
			}
		}
		
		window.open(url,'pdf','');
	}
}

}
