/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Page for registering a PEX component
Class EnsPortal.PEXComponents Extends EnsPortal.Template.viewerPage [ System = 4 ]
{

Parameter PAGENAME = "Production EXtensions";

/// Search criteria from the client.<br/>
/// This is a proxy object whose contents are filled in from the search form
/// by the <method>doSearch</method> method. It is expected that the search
/// query will use this information to determine what results to display.
Property searchCriteria As %ZEN.proxyObject [ InitialExpression = {$$$NULLOREF} ];

Property resultsTableId As %ZEN.Datatype.id [ InitialExpression = "resultsTable" ];

Property tempPortalNode As %ZEN.Datatype.string;

/// User needs WRITE permissions on the %Ens_Code resource to view this page.
Parameter RESOURCE = "%Ens_Code:WRITE";

XData Style
{
<style type="text/css">
/* div around results table */
#resultsTable {
	height: 610px;
	overflow-y: scroll;
}
/* style for table */
#table {
	overflow: auto;
}

/* div around details table */
#detailsTabGroup .tabGroupBar {
	padding-top: 2px;
}

/* details pane style */
#detailsGroup {
	overflow: auto;
}

.labelRequired {
	font-size: 0.8em;
	font-weight: bold;
}

/* slight adjustments to tpTable */
table.tpTable, table.eventInfoTable {
	padding-top: 5px;
	border: none;
}

table.propListTable {
	width: 100%;
	border: 1px solid #C0C0C0;
	background: white;
}
.rowEven {
}
.rowOdd {
	background: #F0F0F0;
}
table.propListTable th {
	border-bottom: 1px solid #C0C0C0;
	color: #404040;
	font-size: 9pt;
	font-weight: bold;
	background: #E0E0E0;
	text-align: left;
	padding: 1px;
}
table.propListTable td {
	border-bottom: 1px solid #C0C0C0;
	color: #404040;
	font-size: 9pt;
	text-align: left;
	padding: 1px;
}

</style>
}

/// Contents of Search panel.
/// This should be overridden in subclasses.
/// The search pane should contain a form with id="searchForm" and
/// invoke the <method>doSearch</method> method when a search is requested.
XData searchPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<form id="searchForm" labelPosition="top" cellStyle="padding:3px;">
<button controlClass="commandButton" caption="Filter" onclick="zenPage.doSearch();"/>

<hgroup label="Component Type" containerStyle="padding:10px 10px 0px 10px;">
<spacer height="2"/>
<vgroup cellStyle="font-size:0.8em">
<checkbox name="Service" id="Service" caption="Business Services" value="1"/>
<checkbox name="Process" id="Process" caption="Business Processes" value="1"/>
<checkbox name="Operation" id="Operation" caption="Business Operations" value="1"/>
<checkbox name="InboundAdapter" id="InboundAdapter" caption="Inbound Adapters" value="1"/>
<checkbox name="OutboundAdapter" id="OutboundAdapter" caption="Outbound Adapters" value="1"/>
</vgroup>
</hgroup>

<hgroup label="Language" containerStyle="padding:10px 10px 0px 10px;">
<vgroup cellStyle="font-size:0.8em">
<checkbox name="Java" id="Java" caption="Java" value="1"/>
<checkbox name="Python" id="Python" caption="Python" value="1"/>
<checkbox name="DotNet" id="DotNet" caption=".NET" value="1"/>
</vgroup>
</hgroup>

</form>
</pane>
}

/// This pane displays services in the Registry. User may click on a row and details are displayed to the side.
XData resultsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<vgroup valign="top">
<!--<spacer height="5"/>-->
<tablePane id="resultsTable"
	useSnapshot="true"
	pageSize="50"
	cellSpacing="2"
	dataSource="columns"
	showZebra="true"
	valueColumn="Classname"
	maxRows="1500"
	useKeys="true"
	showQuery="false"
	onupdate="zenPage.onUpdate(zenThis);"
	onselectrow="zenPage.onSelectItem(zenThis);"
	onunselectrow="zenPage.onSelectItem(zenThis);"
	nowrap="true"
	onmouseoverClass="tpMouseOver"
	enableToggleSelect="true"
	initialExecute="false"
	OnCreateResultSet="GetResultSet"
	unlockSession="true"
	>
<!-- provide header values for all columns so they can be localized -->
<column header="Remote Class Name" colName="RemoteClass" title="Name of the remote component" style="text-align:left;"/>
<column header="Language" colName="Language" title="Language in which the remote component is implemented"/>
<column header="Proxy Name" colName="Classname" title="Name of the proxy class for use in Production Configuration" style="text-align:left;" />
<column header="Component Type" colName="Type" title="Business Service, Process, or Operation, or Inbound or Outbound Adapter" style="text-align:left;"/>
</tablePane>
</vgroup>
</pane>
}

XData detailsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<!-- Get Service Definition in JSON format -->
<jsonProvider id="component"
	OnGetTargetObject="GetPEXComponent"
>
<parameter id="componentId" paramName="componentId" value=""/>
</jsonProvider>

<tabGroup id="detailsTabGroup" showTabBar="true" remember="true">
<tab id="tabSummary" caption="Details" title="Remote component details">
<form id="summaryForm" labelPosition="top" cellStyle="padding:3px;">
<spacer height="5" />
<label label="Select a component to view its details" labelClass="labelBold"/>
<spacer height="15"/>
<hgroup id="lblsTotal">
<label label="Total PEX Components:"/>
<spacer width="2"/>
<label id="lblTotalItems" label="0"/>
</hgroup>
<spacer height="3" />
<hgroup>
<label label="Listed Components:"/>
<spacer width="2"/>
<label id="lblSelectedItems" label="0"/>
</hgroup>
</form>

<form id="detailsForm" labelPosition="top" cellStyle="padding:1px;padding-left:5px;">
<spacer height="6" />
<hgroup id="grpName">
<label id="ctl_.Name" controlClass="labelBold" controlStyle="font-weight:bold;"/>
</hgroup>
<hgroup id="grpLastUpdated">
<label id="lblLastUpdated" controlClass="labelRequired" value="Last Updated:"/>
<spacer width="5"/>
<label id="ctl_.LastUpdated" controlStyle="font-size:0.8em"/>
</hgroup>
<spacer height="5"/>
<vgroup id="grpRemoteClassname">
<label id="lblRemoteClassname" controlClass="labelRequired" value="Remote Class:"/>
<hgroup><spacer width="5"/>
<label id="ctl_.RemoteClassname" controlStyle="font-size:0.8em"/>
</hgroup>
</vgroup>
<spacer id="descSpacer" height="5" hidden="true"/>
<vgroup id="grpDescription">
<label id="lblDescription" controlClass="labelRequired" value="Description:" title="Description of this remote component"/>
<hgroup><spacer width="5"/><label id="ctl_.Description" controlStyle="font-size:0.8em"/></hgroup>
</vgroup>
<hgroup id="grpURL">
<label id="lblItemURL" controlClass="labelRequired" value="URL:" title="URL which points to more information about this remote component"/>
<spacer width="5"/>
<link id="ctl_.URL" style="font-size:0.8em"/>
</hgroup>
<spacer height="5"/>
<hgroup id="grpLanguageServer">
<label id="lblLanguageServer" controlClass="labelRequired" value="External Language Server:"/>
<spacer width="5"/>
<label id="ctl_.LanguageServer" controlStyle="font-size:0.8em"/>
</hgroup>
<vgroup id="grpAdapter">
<spacer height="5"/>
<hgroup>
<label id="lblAdapter" controlClass="labelRequired" value="Adapter:"/>
<spacer width="5"/>
<label id="ctl_.Adapter" controlStyle="font-size:0.8em"/>
</hgroup>
</vgroup>
 <spacer height="7"/>
<html label="Settings:" id="gSettingsList" labelClass="labelRequired" title="List of properties for the remote component"/>
<spacer height="6"/>
<html label="CLASSPATHS:" id="gClasspathsList" labelClass="labelRequired" title="List of extra CLASSPATHS needed to run the remote component"/>

<spacer height="10"/>
</form>
</tab>

<tab id="tabActions" caption="Actions" title="Actions you can take on this PEX Component">
<spacer height="10" />
<hgroup id="grpDelete" cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/our_process_a_48.gif"/>
<vgroup>
<button id="btnDelete" caption="Unregister" controlClass="commandButton" title="Delete the currently selected component from the Registry" onclick="zenPage.deletePEXComponent();"/>
<label controlClass="zenLabel" label="Unregister this component"/>
<spacer height="10" />
</vgroup>
</hgroup>
<hgroup id="grpUpdate" cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/software_development_48.gif"/>
<vgroup>
<button id="btnUpdate" caption="Update" controlClass="commandButton" title="Update the record of this component in order for changes to the class to be reflected on the Production Configuration Page" onclick="zenPage.updateComponent();"/>
<label controlClass="zenLabel" label="Update this component"/>
<spacer height="10" />
</vgroup>
</hgroup>
</tab>
</tabGroup>
</pane>
}

/// Handle the client-side rendering the of the right hand pane.
ClientMethod layoutTabGroup() [ Language = javascript ]
{
/// This is primarily due to IE as it shrinks the contents div without this intervention.
/// The function only adjusts the size of the tab group is not hidden.
	if (!this.detailsHidden) {
		var detailsTabGroup = zen('detailsTabGroup');
		var tabsDiv = detailsTabGroup.getEnclosingDiv();
		var winHeight = zenGetWindowHeight();
		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th - 20;
		if (!(((zenBody.scrollWidth) == (zenBody.offsetWidth)) && (zenBody.scrollLeft == 0))) {
			var hgt = hgt - 20;
		}

		var detailsPanel = zen('detailsPanel');
		var detailsDiv = detailsPanel.getEnclosingDiv();
		var paneWidth = detailsDiv.offsetWidth;

		var tabBar = detailsTabGroup.getTabBarElement();
		hgt = hgt - tabBar.offsetHeight;
		tabsDiv.style.height = hgt + 'px';

		// prevent IE resize logic
		detailsTabGroup.ieResizeBody = function() { return; };

		detailsTabGroup.setBodySize(hgt,paneWidth);
		tabsDiv.style.width = paneWidth + 'px';
	}
}

/// Adjust sizes of components on the page.
/// Do this differently for PEX than for other children of EnsPortal.Template.viewerPage (hence the override).
/// In this case the details pane does not change size when the search pane is minimized.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		var searchPanel = zen('searchPanel');
		var results = zenPage.getResultsTable();
		var detailsPanel = zen('detailsPanel');
		var divSearchPanel = searchPanel.getEnclosingDiv();
		var divResults = results.getEnclosingDiv();
		var divDetailsPanel = detailsPanel.getEnclosingDiv();
		var divDetailsGroup = zen('detailsGroup').getEnclosingDiv();
		var divSearchGroup = zen('searchGroup').getEnclosingDiv();

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();

		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th;

		divResults.style.height = hgt + 'px';
		divSearchPanel.style.height = hgt + 'px';
		divDetailsPanel.style.height = (hgt - 30) + 'px';
		divDetailsGroup.style.height = hgt + 'px';
		divSearchGroup.style.height = hgt + 'px';

		// detail expander
		var detailExpanderWidth = 0;
		var detailExpander = zen('detailExpander');
		if (detailExpander) {
			detailExpanderWidth = detailExpander.getEnclosingDiv().offsetWidth + 10 + (zenIsIE * 12);
		}
		if (!this.detailsHidden) {
			detailsWidth = 600;
			divDetailsGroup.style.width = detailsWidth + 'px';
			divDetailsPanel.style.width = detailsWidth - detailExpanderWidth - 15 - (zenIsIE * 5) + 'px';
		}
		else {
			var arrow = document.getElementById('detailExpanderArrow');
			arrow.innerHTML = '&#171;';
			detailsPanel.setHidden(true);
			divDetailsGroup.style.width = detailExpanderWidth + 'px';
		}

		// search expander
		var searchExpanderWidth = 0;
		var searchExpander = zen('searchExpander');
		if (searchExpander) {
			searchExpanderWidth = searchExpander.getEnclosingDiv().offsetWidth + 10 + (zenIsIE * 12);
		}

		if (!this.searchHidden) {
			if (((divSearchPanel.scrollHeight) == (divSearchPanel.offsetHeight)) && (divSearchPanel.scrollTop == 0 )) {
				var searchWidth = 250;
			}
			else {
				var searchWidth = 260;
			}
			var innerSearchWidth = searchWidth;
			divSearchGroup.style.width = innerSearchWidth + searchExpanderWidth + 15 + (zenIsIE * 5) + 'px';
			divSearchPanel.style.width = innerSearchWidth + 'px';
		}
		else {
			var arrow = document.getElementById('searchExpanderArrow');
			arrow.innerHTML = '&#187;';
			searchPanel.setHidden(true);
			divSearchGroup.style.width = searchExpanderWidth + 'px';
		}

		var resultsWidth = winWidth - divSearchGroup.offsetWidth - divDetailsGroup.offsetWidth;
		resultsWidth = (resultsWidth <= 0 ? 1 : resultsWidth);
		divResults.style.width = resultsWidth + 'px';

		// adjust for scrollbar across width of page
		if (!(((zenBody.scrollWidth) == (zenBody.offsetWidth)) && (zenBody.scrollLeft == 0))) {
			var resultsWidth = zenBody.scrollWidth - divSearchGroup.offsetWidth - divDetailsGroup.offsetWidth;
			resultsWidth = (resultsWidth <= 0 ? 1 : resultsWidth);
			divResults.style.width = resultsWidth  + 'px';

			var hgt = hgt - 20;
			divResults.style.height = hgt + 'px';
			divSearchPanel.style.height = hgt + 'px';
			divDetailsPanel.style.height = (hgt - 30) + 'px';
			divDetailsGroup.style.height = hgt + 'px';
			divSearchGroup.style.height = hgt + 'px';
		}

		this.layoutTabGroup();
		this.adjustExpanderText();

		if (load) { // ensure we update the navigation buttons after first load
			this.updateNavigationButtons();
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler.');
	}
}

ClientMethod updateActions() [ Language = javascript ]
{
	try {
		var itmSelected = (zen('resultsTable').selectedIndex > -1);
		if (itmSelected) {
			var cls = "commandButton";
			zen('btnUpdate').setProperty('title','Update the currently selected remote component');
			zen('btnDelete').setProperty('title','Delete the currently selected remote component from the Registry');
		} else {
			var cls = "commandButtonDisabled";
			zen('btnUpdate').setProperty('title','First select a remote component to perform actions on it.');
			zen('btnDelete').setProperty('title','First select a remote component to perform actions on it.');
		}
		zen('grpUpdate').setProperty('disabled',!itmSelected);
		zen('btnUpdate').setProperty('controlClass',cls);

		zen('grpDelete').setProperty('disabled',!itmSelected);
		zen('btnDelete').setProperty('controlClass',cls);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in updateActions');
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);
	if (!this.canEdit) {
		var btns = ['btnDelete','btnUpdate'];
		for (var i in btns) {
			var btn = btns[i];
			if (zen(btn)) {
				zen(btn).setProperty('controlClass','commandButtonDisabled');
				zen(btn).setProperty('title','');
			}
		}
		var newBtn = document.getElementById('command_newButton');
		newBtn.className = 'commandButtonDisabled';
		newBtn.title = '';
	}
	if (zenIsIE) { // avoid IE resize bug
		var results = zen('table');
		if (results) {
			results.packRowsIE = function() { return null; };
		}
	}
	
	zenPage.searchCriteria = null;
	
	// always execute search here, as initialExecute is false for the table,
	// and we need to ensure that the rest of the page can be loaded
	zenPage.resetForm();
	zenPage.doSearch();
	// make it so that clicking to the right of the buttons in the ribbon bar deselects the selected row in the results table
	toolRibbon.children[0].children[0].children[0].children[0].children[2].setAttribute("onClick","zen('resultsTable').selectRow(-1);");
}

ClientMethod doSearch() [ Language = javascript ]
{
	this.invokeSuper('doSearch');

	setTimeout('zenPage.updateCounts();',50);
}

ClientMethod updateCounts() [ Language = javascript ]
{
	var counts = zenPage.GetTotalCount();
	zen('lblTotalItems').setProperty('label',counts);
	var pane = zen('resultsTable');
	zen('lblSelectedItems').setProperty('label',pane.rowCount);
}

Method GetTotalCount() As %Integer [ ZenMethod ]
{
	Quit ##class(EnsLib.PEX.Utils).Count()
}

/// populate detailTable for the selected row or no selected row
ClientMethod onSelectItem() [ Language = javascript ]
{
	var selected = (zen('resultsTable').selectedIndex > -1);

	var table=zen('resultsTable');
	var sform = zen('summaryForm');
	var dform = zen('detailsForm');
	
	if (selected) {
		this.populateControls();
		sform.setProperty('hidden',true);
		dform.setProperty('hidden',false);
	} else {
		sform.setProperty('hidden',false);
		dform.setProperty('hidden',true);
	}
	this.updateActions();
}

ClientMethod populateControls() [ Language = javascript ]
{
	zen('grpURL').setProperty('hidden',true);
	zen('grpAdapter').setProperty('hidden',true);
	zen('descSpacer').setProperty('hidden',true);
	
	var parm = zen('componentId');
	parm.value = zen('resultsTable').value;
	var json = this.getComponentById('component');
	json.reloadContents();
	var obj = json.getContentObject();
	
	if (obj instanceof Object) {
		for (var attr in obj) {
			var ctl = zen("ctl_."+attr);
			if (ctl) {
				if (("" === zenEscapeHTML(obj[attr])) && zen('grp'+attr)) {
					zen('grp'+attr).setProperty('hidden',true);
				} else {
					if (zen('grp'+attr)) {
						zen('grp'+attr).setProperty('hidden',false);
					}
					if ("URL"==attr) {
						ctl.setProperty('href',obj[attr]);
						ctl.setProperty('caption',obj[attr]);
						zen('descSpacer').setProperty('hidden',false);
					} else {
						ctl.setValue(zenEscapeHTML(obj[attr]));
						if ("Description"==attr) {
							zen('descSpacer').setProperty('hidden',false);
						}
					}
				}
			}
		}
		this.renderSettingsTable(obj.Settings);
		this.renderClasspathsTable(obj.Classpaths);
	}
}

/// Update the contents of the Attributes table.
ClientMethod renderSettingsTable(settings) [ Language = javascript ]
{
	var table = zen('gSettingsList');
	var html = [];

	html.push('<table class="propListTable" border="0" cellspacing="0">');
	html.push('<tr>');
	html.push('<th>' + $$$Text('Name') + '</th>');
	html.push('<th>' + $$$Text('Default Value') + '</th>');
	html.push('<th>' + $$$Text('Type') + '</th>');
	html.push('</tr>');

	if (settings) {
		var n = 0;
		for (var key in settings) {
			var prop = settings[key];

			html.push('<tr class="'+((n%2)?'rowOdd':'rowEven')+'">');
			html.push('<td');
			
			var desc = zenGet(prop.Description);
			var title = "";
			if ("" != desc) {
				var title = zenPage.htmlToTooltip(desc.substring(0,127));
				if (desc.length > 128) title = title + "...";
				title = title + " [" + $$$Text("Click for Popup") + "]";
				html.push(' title="' + title + '"');
				var help = "zenPage.HTMLPopup('" + key + "');"
				html.push(' onclick="' + help + '" style="cursor:pointer;"');
			} else if (zenGet(prop.Name) != prop.LocalizedName) {
				var title = zenPage.htmlToTooltip(prop.Name);
				html.push(' title="' + title + '"');
			}
			
			html.push('>'+zenEscapeHTML(zenGet(prop.LocalizedName)) + '&nbsp;</td>');
			if (zenGet(prop.Default).length > 30) {
				var displayVal = zenGet(prop.Default).substring(0,30)+'...'
				html.push('<td title="'+zenPage.htmlToTooltip(zenGet(prop.Default))+'">' + zenEscapeHTML(displayVal) + '&nbsp;</td>');
			} else {
				html.push('<td>' + zenEscapeHTML(zenGet(prop.Default)) + '&nbsp;</td>');
			}
			html.push('<td>' + zenEscapeHTML(zenGet(prop.Type)) + '&nbsp;</td>');
			html.push('</tr>');
			n = n + 1;
		}
		if (!n) {
			html.push('<tr class="rowEven">');
			html.push('<td colspan="4"><i>' + $$$Text('No settings defined') + '</i></td>');
			html.push('</tr>');
		}
	} else {
		html.push('<tr class="rowEven">');
		html.push('<td colspan="4"><i>' + $$$Text('No settings defined') + '</i></td>');
		html.push('</tr>');
	}
	html.push('</table>');
	table.setContent(html.join(''));
}

/// Update the contents of the Attributes table.
ClientMethod renderClasspathsTable(classpaths) [ Language = javascript ]
{
	var table = zen('gClasspathsList');
	var html = [];

	html.push('<table class="propListTable" border="0" cellspacing="0">');

	if (classpaths) {
		var n = 0;
		for (var key in classpaths) {
			var file = classpaths[key];

			html.push('<tr class="'+((n%2)?'rowOdd':'rowEven')+'">');
			html.push('<td>' + zenEscapeHTML(zenGet(file)) + '&nbsp;</td>');
			html.push('</tr>');
			n = n + 1;
		}
		if (!n) {
			html.push('<tr class="rowEven">');
			html.push('<td colspan="4"><i>' + $$$Text('No extra CLASSPATHS defined') + '</i></td>');
			html.push('</tr>');
		}
	} else {
		html.push('<tr class="rowEven">');
		html.push('<td colspan="4"><i>' + $$$Text('No extra CLASSPATHS defined') + '</i></td>');
		html.push('</tr>');
	}
	html.push('</table>');
	table.setContent(html.join(''));
}

/// Helper method to set up popup for each setting's online help
ClientMethod HTMLPopup(key) [ Language = javascript ]
{
	var json = this.getComponentById('component');
	var obj = json.getContentObject();
	var settings = obj.Settings;
	var prop = settings[key];

	zenPage._helpText = prop.Description; // store in a property for future use by the popup dialog EnsPortal.Dialog.TooltipPopup
	
	var url=zenLink('EnsPortal.Dialog.TooltipPopup.zen');
	
	var parms = {
		KEY: prop.Name,
		LOCALIZEDNAME: prop.LocalizedName
	};
	
	zenPage.launchPopupWindow(url,this.addPopupSuffix('tooltip'),'status,scrollbars,resizable=yes,width=500,height=300',parms);
}

/// Helper method to interpret HTML setting descriptions for display as tooltips
/// Taken from EnsPortal.ProductionConfig
ClientMethod htmlToTooltip(input) [ Language = javascript ]
{
	input = input.replace(/'/g,'\'');
	input = input.replace(/\n/g,' ');
	input = input.replace(/\r/g,' ');

	input = input.replace(/<p>/g,'\r\n\r\n');
	input = input.replace(/<p\/>/g,'\r\n\r\n');
	input = input.replace(/<br>/g,'\r\n');
	input = input.replace(/<br\/>/g,'\r\n');
	input = input.replace(/<li>/g,' - ');

	input = input.replace(/<.*>/g,'');

	input = input.replace(/&lt;/g,'<');
	input = input.replace(/&gt;/g,'>');
	input = input.replace(/&apos;/g,'\'');
	input = input.replace(/"/g,'\'');
	input = input.replace(/&quot;/g,'\'');
	input = input.replace(/&amp;/g,'&');
	input = input.replace(/&nbsp;/g,' ');
	input = input.replace(/  +/g,' ');
	// strip leading \r\n sequences
	while ('\r\n' == input.substring(0,2)) {
		input = input.substring(2);
	}
	return input;
}

/// Reset the form programmatically
ClientMethod resetForm() [ Language = javascript ]
{
	var filters = ['Service','Process','Operation','InboundAdapter','OutboundAdapter','Java','Python','DotNet'];
	for (box in filters) {
		var chk = zen(filters[box]);
		chk.setValue(true);
	}
}

Method GetPEXComponent(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	#dim tSC As %Status = $$$OK
	// create object for details from currently selected component
	Set tComponentName = $G(pParms("componentId"))
	Quit:tComponentName="" $$$OK
	Set tSC = ##class(EnsLib.PEX.Utils).GetComponentProxy(tComponentName,.pObject)
	Quit tSC
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("newButton",$$$Text("Register New Component"),$$$Text("Register a new Production EXtensions component"),"zenPage.newComponent();")
	Set pCommands(2) = $LB("prevButton",$$$Text("Previous"),$$$Text("Show the previous page of results"),"zenPage.getNextData(false);")
	Set pCommands(3) = $LB("nextButton",$$$Text("Next"),$$$Text("Show the next page of results"),"zenPage.getNextData(true);")
	Quit $$$OK
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	#dim tSC = $$$OK
	#dim tRegistering As %Boolean = (..tempPortalNode'="")
	#dim tStatus As %String = $Select(tRegistering:$G(@..tempPortalNode@("Status")),1:"")
			
	&html<
		<td style="width:150px;"/><div>&nbsp;</div><td>
		>
	If 'tRegistering {
		#; hide status
		&html<
			<div id="regStatusText" class="statusHeading" hidden="true"></div>
		>
	} Else {
		Set:(""'=tStatus) tStatus=tStatus_"..."
		&html<
			<div id="regStatusText" class="statusHeading">#(tStatus)#</div>
		>
	}
	
	#; Allow for manual refresh
	If '..enableAutoRefresh {
		#dim tRefresh As %Status = $$$TextHTML("Refresh the table to show the updated list of registered components")
		If tRegistering {
			&html<
				<td nowrap style="padding-left:50px;">
				<image id="refreshRegResult" src="deepsee/loop_24.gif" class="icon" title="#(tRefresh)#" onclick="zenPage.doRefresh();" onmouseover="this.className='iconHover';" onmouseout="this.className='icon';"/>
				</td>

			>
		} Else {
			#; make hidden
			&html<
				<td nowrap style="padding-left:50px;">
				<image id="refreshRegResult" src="deepsee/loop_24.gif" hidden="true" class="icon" title="#(tRefresh)#" onclick="zenPage.doRefresh();" onmouseover="this.className='iconHover';" onmouseout="this.className='icon';"/>
				</td>
			>
		}
	}
	
	&html<</td>>
		

	Quit tSC
}

/// Callback that is executed to create the resultset for the main table.
Method GetResultSet(Output pSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set pSC = $$$OK
	Set tRS = ##class(%Library.ResultSet).%New()
	Set tRS.ClassName = "EnsLib.PEX.Utils"
	Set tRS.QueryName = "EnumeratePEXComponents"
	Set pSC = tRS.Execute(..searchCriteria)
	Set pInfo.queryExecuted = 1
	Quit:$$$ISERR(pSC) $$$NULLOREF
	Quit tRS
}

/// User clicked the Search button
ClientMethod onSearchHandler() [ Language = javascript ]
{
	var table = this.getResultsTable();
	table.setProperty('clearSnapshot',true);
	table.setProperty('currPage',1);
}

/// override resultsTable TablePane methods
ClientMethod onUpdate(table) [ Language = javascript ]
{
	table.selectRow = zenPage.selectRow;
	setTimeout('zenPage.onAfterSearch();',50);
}

/// Overrides TablePane method
ClientMethod selectRow(row, scroll, which) [ Language = javascript ]
{
	zenPage.changeRow = (row != this.selectedIndex);
	this.invokeSuper('selectRow',arguments);
}

/// Unregister a PEX component.  This will delete the proxy class, but not the original remote class
ClientMethod deletePEXComponent() [ Language = javascript ]
{
	if (!this.checkEdit()) return false;
	
	var cls = zen('resultsTable').value;
	if (""==cls) {
		alert('No component selected. Please select a remote component in order to unregister it.');
		return;
	}
	var ok = zenPage.DoDeleteComponent(cls);
	if (""==ok) {
		alert($$$FormatText($$$Text("Successfully un-registered remote component '%1'"),cls));
	} else {
		alert($$$FormatText($$$Text("Error un-registering remote component '%1' :"),cls)+'\n'+ok);
	}
	
	zenPage.doSearch();
	zen('resultsTable').selectRow(-1);
}

Method DoDeleteComponent(pClassname As %String) As %String [ ZenMethod ]
{
	#dim tSC As %Status = $$$OK
	#dim tError As %String = ""
	#dim ex As %Exception.AbstractException
	
	Try {
		Set tSC = ##class(EnsLib.PEX.Utils).DeleteComponentProxy(pClassname)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	If $$$ISERR(tSC) {
		Set tError = $system.Status.GetOneStatusText(tSC,1)
	}
	
	Quit tError
}

/// Register a PEX component
ClientMethod newComponent() [ Language = javascript ]
{
	if (!this.checkEdit()) return false;
	
	var url = this.GetRegistrationLink();
	zenPage.launchPopupWindow(url,this.addPopupSuffix('registerNew'),'status,scrollbars,resizable=yes,width=800,height=600');
}

/// Register a PEX component
ClientMethod updateComponent() [ Language = javascript ]
{
	if (!this.checkEdit()) return false;
	
	var cls = zen('resultsTable').value;
	var url = this.GetRegistrationLink(cls);
	zenPage.launchPopupWindow(url,this.addPopupSuffix('updateExisting'),'status,scrollbars,resizable=yes,width=800,height=600');
}

Method GetRegistrationLink(pClassname As %String = "") As %String [ ZenMethod ]
{
	If (""'=pClassname) {
		Set tQuery("CLASS")=pClassname
	} Else {
		Set tQuery("NEW")=1
	}
	Quit ..Link("EnsPortal.Dialog.PEXRegistration.cls",.tQuery)
}

ClassMethod DoRegisterClass(pClassname As %String, pELS As %String, pClasspaths As %String = "", pProxy As %String = "", pOverwrite As %Boolean = 0, pTempPortalNode As %String, pBounce As %Boolean = 0) As %Status
{
	Do ..%SetBackgroundMethodStatus("Registering")
	Set tSC = ##class(EnsLib.PEX.Utils).RegisterComponent(pClassname,pELS,pClasspaths,pOverwrite,pProxy,pBounce)
	If $$$ISERR(tSC) {
		Set @pTempPortalNode@("Msg") = $Select(pOverwrite:$$$FormatText($$$Text("Error updating remote component '%1' : "),pClassname),1:$$$FormatText($$$Text("Error registering remote component '%1' : "),pClassname))_$System.Status.GetErrorText(tSC)
	} Else {
		Set @pTempPortalNode@("Msg") = $Select(pOverwrite:$$$FormatText($$$Text("Successfully updated remote component '%1'"),pClassname),1:$$$FormatText($$$Text("Successfully registered remote component '%1'"),pClassname))
	}
	Do ..%EndBackgroundMethod()
}

/// This is called when the client clicks OK.
Method RegisterClassInBackground(pClassname As %String, pELS As %String, pClasspaths As %String = "", pProxy As %String = "", pOverwrite As %Boolean = 0, pBounce As %Boolean = 0) [ ZenMethod ]
{
	Set tTempPortalCounter = ##class(EnsPortal.SessionEvents).GetTempNode()
	Set tTempPortalNode = ##class(EnsPortal.SessionEvents).GetReference(tTempPortalCounter) /* ^IRIS.Temp.EnsPortal.Data(%sessionid,0,tTempCounter) */
	Set tTempPortalNode = $name(@tTempPortalNode@(..pageId,$Job))
	Set ..tempPortalNode = tTempPortalNode
	#; Status appears at the top of the page while the registration/update is ongoing
	Set @tTempPortalNode@("Status") = $Select(pOverwrite:"Updating component",1:"Registering component")
	#; Msg will appear in an alert popup once registration/update completes or fails
	Set @tTempPortalNode@("Msg") = ""
	Set tSC = ..%RunBackgroundMethod("DoRegisterClass",pClassname,pELS,pClasspaths,pProxy,pOverwrite,tTempPortalNode,pBounce)
	Quit 1
}

ClientMethod doRefresh() [ Language = javascript ]
{
	if (this._bgTaskID) {
		zenPage.MonitorBackgroundTask(this._bgTaskID);
	}
	return;
}

ClientMethod doUpdateRegStatus() [ Language = javascript ]
{
	var statusEle = document.getElementById('regStatusText');
	var refreshBtn = document.getElementById('refreshRegResult');
	
	if ("" == zenPage.tempPortalNode) {
		// not currently registering/updating anything
		statusEle.hidden = true;
		if (refreshBtn) {
			refreshBtn.hidden = true;
		}
	} else {
		var status = zenPage.GetStatus();
		statusEle.innerHTML = status + '...';
		statusEle.hidden = false;
		if (refreshBtn) {
			refreshBtn.hidden = false;
		}
	}
}

ClassMethod %OnFinishBackgroundTask(pTaskID As %String)
{
	
	&js<
		var old = zenSynchronousMode;
		zenSynchronousMode = true;
		alert(zenPage.GetMessage());
		zenPage.resetForm();
		zenPage.doSearch();
		zenPage.ClearTempPortalNode();
		setTimeout('zenPage.doUpdateRegStatus();',50);
		zenSynchronousMode = old;
	>
}

Method GetMessage() As %String [ ZenMethod ]
{
	Quit @..tempPortalNode@("Msg")
}

Method GetStatus() As %String [ ZenMethod ]
{
	Quit @..tempPortalNode@("Status")
}

Method ClearTempPortalNode() [ ZenMethod ]
{
	Kill @..tempPortalNode
	Set ..tempPortalNode = ""
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Production EXtensions", "Ensemble")
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit ""
}

/// Returning from file select and setting the value into the appropriate field.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") return false;
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'registerNew' :
		case 'updateExisting' :
			// add relevant status message to the top bar
			setTimeout('zenPage.doUpdateRegStatus();',50);
			// switch to the details tab so user can see results of update
			zen('detailsTabGroup').currTab = 1;
			zen('detailsTabGroup').refreshContents();
			zenPage.layoutTabGroup();
			break;
		case 'switchNamespace':
			zenPage.changeURLNamespace(value);
			break;
	}
}

}
