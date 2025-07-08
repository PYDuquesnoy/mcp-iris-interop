/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Pivot table controller.<br/>
/// This component is linked to a pivotTable and displays a set of lists that
/// can be used to specify the data that is to be plotted by the pivotTable (such
/// as rows and columns).<br/>
Class %DeepSee.Component.pivotController Extends %ZEN.Component.component [ System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// Set this to the correct domain.
Parameter DOMAIN = "%DeepSee";

/// id of <class>%DeepSee.Component.pivotTable</class> component this
/// controller is associated with.<br>
/// Note: if this component is placed within a composite element, then the
/// pivotTable must be within the same composite element.
Property pivotTableId As %ZEN.Datatype.id(COMPONENTTYPE = "pivotTable");

Property miniAnalyzer As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Name of column with selected item.
Property selectedColumn As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// Path (idx1_idx2_idx3) of selected item or ''.
Property selectedItem As %ZEN.Datatype.string(XMLPROJECTION = "none");

Property rowsHeight As %ZEN.Datatype.string(XMLPROJECTION = "none") [ InitialExpression = "75px" ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* Table around entire controller */
table.dsptcTable {
	border-top: 1px #808080 solid;
	border-right: 1px #808080 solid;
	background: white;
	width:100%;
	/*height:125px; /* WAL183 */
	/*width: 100%; WAL176*/ 
}

table.dsptcTable td {
	/* width: 25%; WAL176 */
	border-left: 1px solid gray;
}

.dspctMessage {
	border: 1px solid #808080;
	background: #FFEEAA;
	border-radius: 4px;
	padding-left:3px;
	padding-right:3px;
	color: #606060;
}

.dsptcBody {
	height: 75px;
	/*height:100%; /* WAL183 */
	/*height: 75px; /* WAL194 */
	overflow: auto;
}

.dsptcBodySelected {
	background: #D0D0F0;
	height: 75px;
	overflow: auto;
}

.dsptcArrow {
	font-size: 24px;
	font-weight: bold;
	color: #404040;
}

.dsptcArrow:hover {
	background: #FFEEAA;
}

.dsptcArrow:active {
	text-shadow: -1px 1px 8px #FFFFCC, 1px -1px 8px #FFFFFF;
}

table.dsptcHeaderTable {
	font-size: 11pt;
	font-weight: bold;
	color: #404040;
	background: #C0C0C0;
	background-image: url(images/grad-halfgray-10x30.png);
	background-repeat: repeat-x;
	border: none;
	border-bottom: 1px solid #B0B0B0;
	width: 100%;
	height: 30px;
}

table.dsptcHeaderTable td {
	padding-left: 5px;
	padding-right: 5px;
	border: none;
	white-space:nowrap; /* WAL218 */
}

/* item in column */
.dsptcItem {
	color: #404040;
	font-size: 9pt;
	font-weight: bold;
	padding-right: 2px;
}

.dsptcItem a {
	color: #404040;
	text-decoration: none;
}

.dsptcItem input[type=checkbox],
.dsptcItemSelected input[type=checkbox] {
	vertical-align: middle;
	position: relative;
	bottom: 1px;
}

.dsptcItem img,
.dsptcItemSelected img {
	vertical-align: bottom;
	position: relative;
	bottom: 1px;
}

.dsptcItemSelected {
	background: #D0D0F0;
	color: black;
	font-size: 9pt;
	font-weight: bold;
	padding-right: 2px;
}

.dsptcItemSelected a {
	color: black;
	text-decoration: none;
}

/* drop target */
.dsptcDrop {
	font-size: 10pt;
	padding-right: 2px;
}

.dsptcDrop a {
	color: #C0C0C0;
	font-style: italic;
	text-decoration: none;
}

.dsptcItem a:hover,
.dsptcDrop a:hover {
	color: #606060;
	background: #FFEEAA;
}

/* header area */
.dsptcHeaderDiv {
	overflow: hidden;
	text-align: left;
	font-weight: bold;

	background: #C0C0C0;
	background-image: url(images/grad-halfgray-10x100.png);
	background-repeat: repeat-x;
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	height: 100%;
}

table td.dsptDrillCaption {
	font-size: 10pt;
	color: #606060;
	padding-left:10px;
}

table td.dsptDrillItem {
	padding-left:10px;
	border: 1px solid gray;
	background: #F0F0F0;
	border-radius: 3px;
}

/* dimension name in drill item */
.dsptDrillDim {
	font-size: 9px;
	color: #606060;
}

/* member name in drill item */
.dsptDrillMbr {
	font-size: 9px;
	color: #404040;
	font-weight: bold;
}

.iconSep {
	margin-left: 7px;
	margin-right: 7px;
	color: #F0F0F0;
	font-size: 18px;
	text-shadow: #C0C0C0 1px 1px 0px;
	vertical-align: top;
}

/* WAL176 */
.hzResizeBar {
	position:absolute;
	top:0px;
	bottom:0px;
	width:10px;
	cursor:ew-resize;
}

.vtResizeBar {
	position:absolute;
	left:0px;
	right:0px;
	height:10px;
	cursor:ns-resize;
}

#controllerTableArea {
	position:relative;
}

/* WAL176 */

</style>
}

Method %DrawHTML()
{
	Do ##super()
}

/// Return the pivotTable this controller is currently connected to.
ClientMethod getPivotTable() [ Language = javascript ]
{
	return this.pivotTable;
}

/// Client-side method to render this control.
ClientMethod renderContents() [ Language = javascript ]
{
	// test if we have not been rendered yet
	if (this.getEnclosingDiv() == null) return;

	this.getEnclosingDiv().style.visibility = 'hidden';

	// build DHTML for the component
	var html = new Array();
	var pivot = this.pivotTable;
	if (pivot) {
		html[html.length] = '<div style="height:34px;" id="'+this.makeId('toolbar')+'">';
		html[html.length] = this.getHeaderHTML();
		html[html.length] = '</div>';
	}

	html[html.length] = '<div id="controllerTableArea">'; // WAL176

	html[html.length] = '<div style="'+((!pivot||!pivot.isDrillThrough||!pivot.canDrillThrough()||!pivot.canUseListingFields)?'':'display:none;')+'" id="'+this.makeId('pivotColumns')+'"><table class="dsptcTable" border="0" cellpadding="3" cellspacing="0"><tr>';
	if (null == pivot) {
		// disconnected
		html[html.length] = '<td align="left" valign="center" nowrap="1">&nbsp;';
		html[html.length] = $$$Text('Not connected');
		html[html.length] = '</td>';
	}
	else {
		var drillLevel = pivot.getDrillLevel();
		var manual = pivot.dataSource=='manual';
		var style = manual ? 'style="background:#F0F0F0;"' : '';

		// rows
		html[html.length] = '<td valign="top" '+style+' id="'+this.makeId('rowsTD')+'">';
		html[html.length] = this.getRowsHTML();
		html[html.length] = '</td>';

		// columns
		html[html.length] = '<td valign="top" '+style+' id="'+this.makeId('columnsTD')+'">';
		html[html.length] = this.getColumnsHTML();
		html[html.length] = '</td>';

		// measures
		html[html.length] = '<td valign="top" '+style+' id="'+this.makeId('measuresTD')+'">';
		html[html.length] = this.getMeasuresHTML();
		html[html.length] = '</td>';

		// filters
		html[html.length] = '<td valign="top" id="'+this.makeId('filtersTD')+'">';
		html[html.length] = this.getFiltersHTML();
		html[html.length] = '</td>';
	}
	html[html.length] = '</tr></table></div>';

	if (pivot && pivot.canDrillThrough() && pivot.canUseListingFields) {
		// listing columns
		html[html.length] = '<div style="'+(pivot.isDrillThrough?'':'display:none;')+'" id="'+this.makeId('listingColumns')+'"><table class="dsptcTable" border="0" cellpadding="3" cellspacing="0"><tr>';
		// rows
		html[html.length] = '<td valign="top" id="'+this.makeId('fieldsTD')+'">';
		html[html.length] = this.getFieldsHTML();
		html[html.length] = '</td>';

		html[html.length] = '</tr></table></div>';
	}
	
	// + WAL176
	if (this.miniAnalyzer!=true) { // WAL238 -- don't draw resize bars for mini-Analyzer
		html[html.length] = '<div id="col_1_2" class="hzResizeBar" onmousedown="ZLM.drag(this,event);">';
		html[html.length] = '</div>';

		html[html.length] = '<div id="col_2_3" class="hzResizeBar" onmousedown="ZLM.drag(this,event);">';
		html[html.length] = '</div>';
		
		html[html.length] = '<div id="col_3_4" class="hzResizeBar" onmousedown="ZLM.drag(this,event);">';
		html[html.length] = '</div>';
		
		html[html.length] = '<div id="bottomResize" class="vtResizeBar" onmousedown="ZLM.drag(this,event);">';
		html[html.length] = '</div>';
	}
	// - WAL176
	
	html[html.length] = '</div>';

	// render
	this.getEnclosingDiv().innerHTML = html.join('');
	this.getEnclosingDiv().style.visibility = 'visible';
}

/// Get html for the fields column.
ClientMethod getFieldsHTML() [ Internal, Language = javascript ]
{
	var pivot = this.pivotTable;
	var drillLevel = pivot?pivot.getDrillLevel():0;
	var html = [];
	var hlpRow = $$$Text('Specify columns to display within a listing');
	var hlpAddRow = $$$Text('Add a field to the listing');
	var hlpClear = $$$Text('Clear this list');
	var hlpAddBlank = $$$Text('Add the selected field in the member tree to this listing');
	var hlpMoveUp = $$$Text('Move current element up in this list');
	var hlpMoveDown = $$$Text('Move current element down in this list');
	var msgDropRow = $$$Text('Drop custom listing field here');

	html[html.length] = '<table class="dsptcHeaderTable" title="'+hlpRow+'" cellspacing="0" id="rows_header"><tr><td>' + $$$Text('Custom Listing Fields') + '</td>';
	html[html.length] = '<td align="right" width="90%" nowrap="1">';

	var enb = this.itemCanMoveUp('fields',this.selectedItem);
	html[html.length] = this.getIconHTML('fieldUp',enb,'iconUp16',hlpMoveUp,'zenPage.getComponent('+this.index+').moveItemUp(\'fields\');');
	html[html.length] = '&nbsp;';

	var enb = this.itemCanMoveDown('fields',this.selectedItem);
	html[html.length] = this.getIconHTML('fieldDown',enb,'iconDown16',hlpMoveDown,'zenPage.getComponent('+this.index+').moveItemDown(\'fields\');');
	html[html.length] = '&nbsp;';

	html[html.length] = this.getIconHTML('fieldAdd',true,'iconAdd16',hlpAddBlank,'zenPage.getComponent('+this.index+').addBlankLevel(\'fields\');');
	html[html.length] = '&nbsp;';

	var enb = (this.pivotTable.listingFields && this.pivotTable.listingFields.length > 0);
	html[html.length] = this.getIconHTML('fieldClear',enb,'iconClose16',hlpClear,'zenPage.getComponent('+this.index+').clearLevels(\'fields\');');
	html[html.length] = '</td>';
	html[html.length] = '</tr></table>';
	var cls = (this.selectedColumn=='fields'&&this.selectedItem=='') ? 'dsptcBodySelected' : 'dsptcBody';
	var style = this.pivotTable.listing=='$$$CUSTOM' ? '' : 'background:#F0F0F0;';
	html[html.length] = '<div class="'+cls+'" style="'+style+'" id="fields_body">';

	html[html.length] = this.getLevelHTML('fields',msgDropRow,this.pivotTable.listingFields,0);

	html[html.length] = '</div>';
	return html.join('');
}

/// Get html for the rows column.
ClientMethod getRowsHTML() [ Internal, Language = javascript ]
{
	var pivot = this.pivotTable;
	var drillLevel = pivot?pivot.getDrillLevel():0;
	var html = [];
	var hlpRow = $$$Text('Specify items to display for the rows in the table');
	var hlpAddRow = $$$Text('Add a row to the table');
	var hlpClear = $$$Text('Clear this list');
	var hlpAddBlank = $$$Text('Add the selected element in the member tree to this list');
	var hlpRowOptions = $$$Text('Set options for rows within the table');
	var hlpMoveUp = $$$Text('Move current element up in this list');
	var hlpMoveDown = $$$Text('Move current element down in this list');
	var msgDropRow = $$$Text('Drop row here');

	html[html.length] = '<table class="dsptcHeaderTable" title="'+hlpRow+'" cellspacing="0" id="rows_header"><tr><td>' + $$$Text('Rows') + '</td>';
	html[html.length] = '<td align="right" width="90%" nowrap="1">';

	var enb = this.itemCanMoveUp('rows',this.selectedItem);
	html[html.length] = this.getIconHTML('rowUp',enb,'iconUp16',hlpMoveUp,'zenPage.getComponent('+this.index+').moveItemUp(\'rows\');');
	html[html.length] = '&nbsp;';

	var enb = this.itemCanMoveDown('rows',this.selectedItem);
	html[html.length] = this.getIconHTML('rowDown',enb,'iconDown16',hlpMoveDown,'zenPage.getComponent('+this.index+').moveItemDown(\'rows\');');
	html[html.length] = '&nbsp;';

	html[html.length] = this.getIconHTML('rowAdd',true,'iconAdd16',hlpAddBlank,'zenPage.getComponent('+this.index+').addBlankLevel(\'rows\');');
	html[html.length] = '&nbsp;';

	// show different icon if option is turned on
	var img = (pivot.rowAxisOptions.suppress8020||pivot.rowAxisOptions.headEnabled||pivot.rowAxisOptions.orderEnabled||pivot.rowAxisOptions.filterEnabled||pivot.rowAxisOptions.aggEnabled) ? 'iconColumn16on' : 'iconColumn16';

	html[html.length] = this.getIconHTML('rowOptions',true,img,hlpRowOptions,'zenPage.getComponent('+this.index+').setAxisOptions(\'rows\');');
	html[html.length] = '&nbsp;';

	var enb = (this.pivotTable.rowLevels && this.pivotTable.rowLevels.length > 0);
	html[html.length] = this.getIconHTML('rowClear',enb,'iconClose16',hlpClear,'zenPage.getComponent('+this.index+').clearLevels(\'rows\');');
	html[html.length] = '</td>';
	html[html.length] = '</tr></table>';
	var cls = (this.selectedColumn=='rows'&&this.selectedItem=='') ? 'dsptcBodySelected' : 'dsptcBody';
	html[html.length] = '<div class="'+cls+'" style="height:'+this.rowsHeight+'" id="rows_body">'; // WAL194

	html[html.length] = this.getLevelHTML('rows',msgDropRow,this.pivotTable.rowLevels,drillLevel);

	html[html.length] = '</div>';
	return html.join('');
}

/// Get html for the columns column.
ClientMethod getColumnsHTML() [ Internal, Language = javascript ]
{
	var pivot = this.pivotTable;
	var drillLevel = pivot?pivot.getDrillLevel():0;
	var html = [];
	var hlpCol = $$$Text('Specify items to display for the columns in the table');
	var hlpAddCol = $$$Text('Add a column to the table');
	var hlpClear = $$$Text('Clear this list');
	var hlpAddBlank = $$$Text('Add the selected element in the member tree to this list');
	var hlpColOptions = $$$Text('Set options for columns within the table');
	var hlpMoveUp = $$$Text('Move current element up in this list');
	var hlpMoveDown = $$$Text('Move current element down in this list');
	var msgDropCol = $$$Text('Drop column here');

	html[html.length] = '<table class="dsptcHeaderTable" title="'+hlpCol+'" cellspacing="0" id="cols_header">';
	html[html.length] = '<tr><td>' + $$$Text('Columns') + '</td>';
	html[html.length] = '<td align="right" width="90%" nowrap="1">';

	var enb = this.itemCanMoveUp('cols',this.selectedItem);
	html[html.length] = this.getIconHTML('colUp',enb,'iconUp16',hlpMoveUp,'zenPage.getComponent('+this.index+').moveItemUp(\'cols\');');
	html[html.length] = '&nbsp;';
	var enb = this.itemCanMoveDown('cols',this.selectedItem);
	html[html.length] = this.getIconHTML('colDown',enb,'iconDown16',hlpMoveDown,'zenPage.getComponent('+this.index+').moveItemDown(\'cols\');');
	html[html.length] = '&nbsp;';

	html[html.length] = this.getIconHTML('colAdd',true,'iconAdd16',hlpAddBlank,'zenPage.getComponent('+this.index+').addBlankLevel(\'cols\');');
	html[html.length] = '&nbsp;';

	// show different icon if option is turned on
	var img = (pivot.columnAxisOptions.suppress8020||pivot.columnAxisOptions.headEnabled||pivot.columnAxisOptions.orderEnabled||pivot.columnAxisOptions.filterEnabled||pivot.columnAxisOptions.aggEnabled) ? 'iconColumn16on' : 'iconColumn16';
	html[html.length] = this.getIconHTML('colClear',true,img,hlpColOptions,'zenPage.getComponent('+this.index+').setAxisOptions(\'cols\');');
	var enb = (this.pivotTable.columnLevels && this.pivotTable.columnLevels.length>0);
	html[html.length] = '&nbsp;';
	html[html.length] = this.getIconHTML('colClose',enb,'iconClose16',hlpClear,'zenPage.getComponent('+this.index+').clearLevels(\'cols\');');
	html[html.length] = '</td>';
	html[html.length] = '</tr></table>';
	var cls = (this.selectedColumn=='cols'&&this.selectedItem=='') ? 'dsptcBodySelected' : 'dsptcBody';
	html[html.length] = '<div class="'+cls+'" style="height:'+this.rowsHeight+'" id="cols_body">'; // WAL194

	html[html.length] = this.getLevelHTML('cols',msgDropCol,this.pivotTable.columnLevels,'');

	html[html.length] = '</div>';
	return html.join('');
}

/// Get html for the measures column.
ClientMethod getMeasuresHTML() [ Internal, Language = javascript ]
{
	var html = [];
	var pivot = this.pivotTable;

	var hlpMsr = $$$Text('Specify measures to display');
	var hlpAddMsr = $$$Text('Add a measure to the table');
	var hlpClear = $$$Text('Clear this list');
	var hlpAddBlank = $$$Text('Add the selected element in the member tree to this list');
	var hlpMoveUp = $$$Text('Move current element up in this list');
	var hlpMoveDown = $$$Text('Move current element down in this list');
	var hlpMsrOptions = $$$Text('Set options for measures within the table');

	var msgDropMsr = $$$Text('Drop measure here');
	html[html.length] = '<table class="dsptcHeaderTable" title="'+hlpMsr+'" cellspacing="0" id="msrs_header"><tr><td>' + $$$Text('Measures') + '</td><td align="right" width="90%" nowrap="1">&nbsp;';

	var enb = this.itemCanMoveUp('msrs',this.selectedItem);
	html[html.length] = this.getIconHTML('msrUp',enb,'iconUp16',hlpMoveUp,'zenPage.getComponent('+this.index+').moveItemUp(\'msrs\');');
	html[html.length] = '&nbsp;';
	var enb = this.itemCanMoveDown('msrs',this.selectedItem);
	html[html.length] = this.getIconHTML('msrDown',enb,'iconDown16',hlpMoveDown,'zenPage.getComponent('+this.index+').moveItemDown(\'msrs\');');
	html[html.length] = '&nbsp;';

	html[html.length] = this.getIconHTML('msrAdd',true,'iconAdd16',hlpAddBlank,'zenPage.getComponent('+this.index+').addBlankLevel(\'msrs\');');
	html[html.length] = '&nbsp;';

	// JMD1456
	// show different icon if option is turned on
	var img = ((pivot.measureLocation=='rows')||(pivot.hideMeasures!=1)) ? 'iconColumn16on' : 'iconColumn16';
	html[html.length] = this.getIconHTML('msrOptions',true,img,hlpMsrOptions,'zenPage.getComponent('+this.index+').setAxisOptions(\'msrs\');');

	var enb = (this.pivotTable.measures && this.pivotTable.measures.length > 0);
	html[html.length] = this.getIconHTML('msrClear',enb,'iconClose16',hlpClear,'zenPage.getComponent('+this.index+').clearLevels(\'msrs\');');
	html[html.length] = '</td>' + '</tr></table>';

	var cls = (this.selectedColumn=='msrs'&&this.selectedItem=='') ? 'dsptcBodySelected' : 'dsptcBody';
	html[html.length] = '<div class="'+cls+'" style="height:'+this.rowsHeight+'" id="msrs_body">'; // WAL194

	html[html.length] = this.getLevelHTML('msrs',msgDropMsr,this.pivotTable.measures,'');

	html[html.length] = '</div>';
	return html.join('');
}

/// Get html for the filters column.
ClientMethod getFiltersHTML() [ Internal, Language = javascript ]
{
	var html = [];
	var img = 'iconColumn16';

	var hlpFilter = $$$Text('Specify what is used to filter the table');
	var hlpAddFil = $$$Text('Add a filter to the table');
	var hlpClear = $$$Text('Clear this list');
	var hlpAddBlank = $$$Text('Add the selected element in the member tree to this list');
	var hlpMoveUp = $$$Text('Move current element up in this list');
	var hlpMoveDown = $$$Text('Move current element down in this list');

	var hlpFilterOptions = $$$Text('Add advanced filter to the table');
	var msgDropFil = $$$Text('Drop filter here');
	var hlpFilterOptions = $$$Text('Add advanced filter to the table');

	html[html.length] = '<table class="dsptcHeaderTable" title="'+hlpFilter+'" cellspacing="0" id="filters_header"><tr><td>' + $$$Text('Filters','%DeepSee') + '</td>';
	html[html.length] = '<td align="right" width="90%" nowrap="1">';

	var enb = this.itemCanMoveUp('filters',this.selectedItem);
	html[html.length] = this.getIconHTML('ftrUp',enb,'iconUp16',hlpMoveUp,'zenPage.getComponent('+this.index+').moveItemUp(\'filters\');');
	html[html.length] = '&nbsp;';
	var enb = this.itemCanMoveDown('filters',this.selectedItem);
	html[html.length] = this.getIconHTML('ftrDown',enb,'iconDown16',hlpMoveDown,'zenPage.getComponent('+this.index+').moveItemDown(\'filters\');');
	html[html.length] = '&nbsp;';

	html[html.length] = this.getIconHTML('ftrAdd',true,'iconAdd16',hlpAddBlank,'zenPage.getComponent('+this.index+').addBlankLevel(\'filters\');');
	html[html.length] = '&nbsp;';

	html[html.length] = this.getIconHTML('ftrOptions',true,img,hlpFilterOptions,'zenPage.getComponent('+this.index+').setFilterOptions();');
	html[html.length] = '&nbsp;';
	var enb = (this.pivotTable.filters && this.pivotTable.filters.length > 0);
	html[html.length] = this.getIconHTML('ftrClear',enb,'iconClose16',hlpClear,'zenPage.getComponent('+this.index+').clearLevels(\'filters\');');
	html[html.length] = '</td>' + '</tr></table>';
	var cls = (this.selectedColumn=='filters'&&this.selectedItem=='') ? 'dsptcBodySelected' : 'dsptcBody';
	html[html.length] = '<div class="'+cls+'" style="height:'+this.rowsHeight+'" id="filters_body">'; // WAL194

	html[html.length] = this.getLevelHTML('filters',msgDropFil,this.pivotTable.filters,'');

	html[html.length] = '</div>';
	return html.join('');
}

/// Get html to create an icon.
ClientMethod getIconHTML(id, enabled, imgId, help, click) [ Internal, Language = javascript ]
{
	var cls = enabled ? 'dsptIcon' : 'dsptIconDisabled';
	if (click!='') {
		click = 'if(this.className==\'dsptIcon\'){'+click+'} return false;';
	}
	else {
		click = 'return false;';
	}
	// no hover color for ie in quirks mode!
	var url = this.getIcon(imgId);

	var style = 'padding-right:4px;';
	if (imgId.indexOf('24')>=0) {
		style += 'height:22px;';
	}
	else if (imgId.indexOf('16')>=0) {
		style += 'height:12px;';
	}

	if (imgId.indexOf('Swap')>=0) {
		style += 'width:22px;';
	}
	
	return '<img id="'+(id?this.makeId(id):'')+'" style="'+style+'" class="'+cls+'" title="'+help+'" onclick="'+click+'" src="'+url+'"/>';
}

/// Get html to create an icon with a dropdown menu.
ClientMethod getDropdownIconHTML(id, enabled, imgId, help, options) [ Internal, Language = javascript ]
{
	// Method added by DP-402897
	var cls = enabled ? 'dsptIconDropdown' : 'dsptIconDisabled';
	// no hover color for ie in quirks mode!
	var imgUrl = this.getIcon(imgId);

	var style = 'padding-right:4px;';
	if (imgId.indexOf('24')>=0) {
		style += 'height:22px;';
	}
	else if (imgId.indexOf('16')>=0) {
		style += 'height:12px;';
	}

	if (imgId.indexOf('Swap')>=0) {
		style += 'width:22px;';
	}
	
	var dropId = (id?this.makeId(id+'DropDown'):'');
	var html = [];
	
	// Create a div that has a permanently displayed button and a dropdown menu
	html.push('<div id="'+(id?this.makeId(id):'')+'">');
	html.push('<img style="'+style+'" class="'+cls+'" title="'+help+'" onclick="zenPage.toggleExportMenu(\''+dropId+'\');" src="'+imgUrl+'"/>');
	
	html.push('<div id="'+dropId+'" class="dsptIconDropdownMenu" style="display:none;">');
	
	// Add the menu options to the dropdown menu
	for ( n=0; n<options.length; n++) {
		var optionDef = '';
		optionDef += '<a';
		optionDef += (options[n].click) ? ' onclick="zenPage.toggleExportMenu(\''+dropId+'\');'+options[n].click+'"' : '';
		optionDef += (options[n].hover) ? ' title="'+options[n].hover+'"' : '';
		optionDef += '>';
		optionDef += options[n].name
		optionDef += '</a>';
		
		html.push(optionDef);
	}

	html.push('</div>');		// Drop-down div
	html.push('</div>');		// Overall div
	
	return html;
}

/// Fill an array of HTML with the contents of the header area.
ClientMethod getHeaderHTML() [ Internal, Language = javascript ]
{
	var pivot = this.pivotTable;
	var html = [];
	html[html.length] = '<div class="dsptcHeaderDiv">';

	// icon bar
	var hlpReset = $$$Text("Reset the table");
	var hlpCancel = $$$Text("Cancel a running query");
	var hlpRefresh = $$$Text("Refresh the table");
	var hlpRefresh2 = $$$Text("Refresh the table-there are unapplied changes to this pivot");
	var hlpOptions = $$$Text("Set options for the pivot table");
	var hlpQuery = $$$Text("Show the current query for the pivot table");
	var hlpDrill = $$$Text("Show a detail listing for the current selected cell(s)");
	var hlpPivot = $$$Text("Show the pivot table");
	var hlpBack = $$$Text("Go back to previous view");
	var hlpForward = $$$Text("Go forward to next view");
	var hlpSwap = $$$Text("Swap rows and columns");
	var hlpFormat = $$$Text("Define conditional formatting rules");
	var hlpChart = $$$Text("Modify chart appearance");
	var hlpExcel = $$$Text("Microsoft Excel (.xls)");
	var hlpExport = $$$Text("Export current results");
	var hlpAnalyze = $$$Text("Show an analysis of the current selected cell(s)");
	var hlpPDF = $$$Text("Export current results to printable PDF format");
	var hlpCSV = $$$Text("Comma delimited (.csv)");		// DP-402897
	var hlpEnhCSV = $$$Text("Comma delimited with filters and additional pivot information (.csv)")		// DP-402897
	var hlpConfigPDF = $$$Text("Configure PDF export for this pivot");
	var hlpCopy = $$$Text("Copy the selected pivot level item");
	var hlpPaste = $$$Text("Paste pivot level after selected pivot level item");
	var hlpPasteUnder = $$$Text("Paste pivot level under the selected pivot level item");
	var hlpAutoExecOn = $$$Text("Turn on auto-execute mode");
	var hlpAutoExecOff = $$$Text("Turn off auto-execute mode");
	var space = '<span class="iconSep">|</span>'

	html[html.length] = '<table><tr>';
	html[html.length] = '<td nowrap="1"><div class="dsptIconBar">';
	if (zenPage.showDimensionTree) {
		var title = $$$Text('Toggle display of dimension tree','%DeepSee');
		var arrow = zenPage.showDimensions ? '&laquo;' : '&raquo;';
		html[html.length] = '<span id="dimArrow" title="'+title+'" class="dsptcArrow" onclick="zenPage.showDimensionTree(!zenPage.showDimensions);">'+arrow+'</span>&nbsp;';
	}

	html[html.length] = this.getIconHTML('icReset',true,'iconHome24',hlpReset,'zenPage.getComponent('+this.index+').resetTable();');

	if ("automatic"==pivot.dataSource) {
		html[html.length] = this.getIconHTML('icBack',pivot.canGoBack(),'iconBack24',hlpBack,'zenPage.getComponent('+this.index+').getPivotTable().goBack();');
		html[html.length] = this.getIconHTML('icFwd',pivot.canGoForward(),'iconForward24',hlpForward,'zenPage.getComponent('+this.index+').getPivotTable().goForward();');
	}

	var icon = pivot.changesPending ? 'iconRefresh24on' : 'iconRefresh24';
	html[html.length] = this.getIconHTML('icRefresh',true,icon,hlpRefresh,'zenPage.getComponent('+this.index+').getPivotTable().executeQuery(true);');

	html[html.length] = space;

	// copy & paste
	var enb = (this.selectedColumn!='');
	html[html.length] = this.getIconHTML('icCopy',enb,'iconCopy24',hlpCopy,'zenPage.getComponent('+this.index+').copyItem();');

	var enb = this._clipboard&&this.selectedColumn!='';
	html[html.length] = this.getIconHTML('icPaste',enb,'iconPaste24',hlpPaste,'zenPage.getComponent('+this.index+').pasteItem(\'after\');');

	var enb = this._clipboard&&(this.selectedColumn=='rows'||this.selectedColumn=='cols')&&this.selectedItem!='';
	html[html.length] = this.getIconHTML('icPasteDown',enb,'iconPasteDown24',hlpPasteUnder,'zenPage.getComponent('+this.index+').pasteItem(\'under\');');

	// swap
	var enb = ((pivot.drillLevels.length==0)&&((pivot.rowLevels&&pivot.rowLevels.length>0)||(pivot.columnLevels&&pivot.columnLevels.length>0)));
	html[html.length] = this.getIconHTML('icSwap',enb,'iconSwap24',hlpSwap,'zenPage.getComponent('+this.index+').swapRows();');

	html[html.length] = space;

	if (pivot.canDrillThrough()) {
		var icon = pivot.isDrillThrough ? 'iconListing24On':'iconListing24';
		var enb = pivot.isDrillThrough ? true : ''!==pivot.selectedRange;
		var hlp = pivot.isDrillThrough ? hlpPivot : hlpDrill;
		html[html.length] = this.getIconHTML('icListing',enb,icon,hlpDrill,'zenPage.getComponent('+this.index+').drillThrough();');
	}

	if (zenPage.showBreakdown) {
		html[html.length] = this.getIconHTML('icBreakdown',''!==pivot.selectedRange,'iconAnalysis24',hlpAnalyze,'zenPage.showBreakdown();');
	}

	if (zenPage.showQuery) {
		// JMD1031
		icon = pivot.dataSource=='automatic' ? 'iconScript24' : 'iconScript24on';

		html[html.length] = this.getIconHTML('icQuery',true,icon,hlpQuery,'zenPage.showQuery();');
	}
	if (zenPage.exportExcel) {
		if (zenPage.exportCSV) {
			// DP-402897 - If the containing page also supports CSV export, provide an export menu instead
			// of the default Excel export under the export icon
			var dropDownOptions = [
									{"name":"Excel","click":"zenPage.exportExcel();","hover":hlpExcel},
									{"name":"CSV","click":"zenPage.exportCSV(true);","hover":hlpCSV},
									{"name":$$$Text("CSV with Heading"),"click":"zenPage.exportCSV();","hover":hlpEnhCSV}
									];
			
			var menuHtml = this.getDropdownIconHTML('exportMenu',true,'iconExcel24',hlpExport,dropDownOptions);
			
			// End the current <td> and start another one that will contain the menu button. This is
			// necessary to prevent the vetical statcking of the divs within the <td> 
			html.push('</div></td><td>');
			for ( n=0; n<menuHtml.length; n++) {
				html[html.length] = menuHtml[n];
			}
			// Close out the menu <td> and start another for the remaining menu items
			html.push('</td><td><div class="dsptIconBar">');
		}
		else {
			html[html.length] = this.getIconHTML('icExcel',true,'iconExcel24',hlpExcel,'zenPage.exportExcel();');
		}
	}
	if (zenPage.exportPDF && zenPage.hasPDF) {
		html[html.length] = this.getIconHTML('icPDF',true,'iconPrinter24',hlpPDF,'zenPage.exportPDF();');
	}
	

	html[html.length] = space;

	if (zenPage.showPivotOptions) {
		html[html.length] = this.getIconHTML('icOptions',true,'iconPivotOptions24',hlpOptions,'zenPage.showPivotOptions();');
	}
	if (zenPage.exportPDF && zenPage.hasPDF) {
		html[html.length] = this.getIconHTML('icPrintConfig',true,'iconPrintConfig24',hlpConfigPDF,'zenPage.showPDFOptions();');
	}

	if (zenPage.showChartOptions) {
		html[html.length] = this.getIconHTML('icChartOptions',true,'iconChartOptions24',hlpChart,'zenPage.showChartOptions();');
	}
	if (zenPage.showFormatOptions) {
		var icon = pivot.hasFormatRules() ? 'iconFormat24on' : 'iconFormat24';
		html[html.length] = this.getIconHTML('icFormat',true,icon,hlpFormat,'zenPage.showFormatOptions();');
	}

	html[html.length] = space;

	if (false && zenPage.toggleAutoExecute) {
		var icon = pivot.autoExecute ? 'iconAutoExec24on' : 'iconAutoExec24';
		var hlp = pivot.autoExecute ? hlpAutoExecOff : hlpAutoExecOn;
		html[html.length] = this.getIconHTML('icAutoExec',true,icon,hlpAutoExecOff,'zenPage.toggleAutoExecute();');
	}

	html[html.length] = this.getIconHTML('icCancel',true,'iconCancel24',hlpCancel,'zenPage.getComponent('+this.index+').getPivotTable().cancelQuery();');

	html[html.length] = '</div></td>';

	// message box
	html[html.length] = '<td nowrap="1"><div id="'+this.makeId('message')+'"/></td>';

	// drill levels
	html[html.length] = '<td id="'+this.makeId('drillLevels')+'">';
	html[html.length] = this.getDrillLevelHTML();
	html[html.length] = '</td>';

	html[html.length] = '</tr></table>';
	html[html.length] = '</div>';

	return html.join('');
}

/// Toggle the drillThrough mode of the table.
ClientMethod drillThrough() [ Internal, Language = javascript ]
{
	var pivot = this.getPivotTable();
	pivot.drillThrough();
	this.updateToolbar();
}

/// Get drill level HTML.
ClientMethod getDrillLevelHTML() [ Internal, Language = javascript ]
{
	var pivot = this.pivotTable;
	var hlpRemove = $$$Text("Remove this drill level");

	var html = [];
	if (pivot.drillLevels.length > 0) {
		html[html.length] = '<table><tr>';
		html[html.length] = '<td class="dsptDrillCaption" nowrap="1">' + $$$Text('Drill down:') + '</td>';
		for (var n = 0; n < pivot.drillLevels.length; n++) {
			// DP-432611 - First split by "/" to account for a potential crossjoin in the axis, then read values of
			// the final piece which is the active drilldown target
			var cj = pivot.drillLevels[n].text.toString().split('/');
			var t = cj[cj.length-1].split(':');
			
			// JMD1366 prevent undefined
			if (!t[1]) {
				t[1] = '';
			}
			// DTB081 - escape angle brackets if there is a <> pair  
			if ( (t[1].indexOf('<') > -1) && (t[1].indexOf('>') > -1) ) {
				t[1] = t[1].replace('<', "&lt;");
         		t[1] = t[1].replace('>', "&gt;");
			}
 
			html[html.length] = '<td class="dsptDrillItem" nowrap="1" valign="middle">';

			html[html.length] = '<table border="0" cellspacing="0"><tr>';
			html[html.length] = '<td onclick="zenPage.getComponent('+this.index+').gotoDrillLevel('+n+');"><div class="dsptDrillDim">'+t[0]+'</div><div class="dsptDrillMbr">' + t[1] +'</div></td>';
			html[html.length] = '<td>';
			html[html.length] = this.getIconHTML('drill_'+n,true,'iconClose16',hlpRemove,'zenPage.getComponent('+this.index+').removeDrillLevel('+n+');');
			html[html.length] = '</td>';
			html[html.length] = '</tr></table>';
			html[html.length] = '</td>';
		}
		html[html.length] = '</tr></table>';
	}
	return html.join('');
}

/// Fill an array of HTML with the contents of the given level list.
ClientMethod getLevelHTML(which, dropMsg, array, drillLevel, depth, parent) [ Internal, Language = javascript ]
{
	drillLevel = ('undefined' == typeof drillLevel) ? '' : drillLevel;
	depth = ('undefined' == typeof depth) ? 0 : depth;
	var html = new Array();
	var childrenAllowed = ('rows'==which || 'cols'==which);
	var optionsAllowed = ('rows'==which || 'cols'==which || 'msrs'==which);
	var hlpAddChild = $$$Text('Drop an item here to make it a child of this item');
	var hlpOptions = $$$Text('Set options for this item');
	var hlpAdvancedFilter = $$$Text('Edit this advanced filter');
	var hlpRemove = $$$Text('Remove this item');

	var selectedItem = '';
	if ((this.selectedColumn==which)&&(this.selectedItem!='')) {
		selectedItem = this.selectedItem;
	}
	
	var key = '';
	if (array) {
		for (var n = 0; n < array.length; n++) {
			var level = array[n];
			// add pointers to levels to help navigate
			level._index = n;
			if (null != parent) {
				level._parent = parent;
			}
			
			if (!level.transient) {
				key = n;
				var p = level._parent;
				while (null != p) {
					key = p._index + '_' + key;
					p = p._parent;
				}

				if ((drillLevel=='')||(level.drillLevel == drillLevel)) {
					var cls = (key==selectedItem && selectedItem !== '') ? 'dsptcItemSelected' : 'dsptcItem';
					html[html.length] = '<div class="'+cls+'" style="padding-left:'+(5+depth*10)+'px;" id="'+which+'_'+key+'" onclick="zenPage.getComponent('+this.index+').selectItem(\''+which+'\',\''+key+'\');">';
					var text = (level.caption && '' !==level.caption) ? level.caption : level.text;
					// JMD943: truncate long names
					if (text.length && text.length > 25) {
						text = text.substr(0,25)+'...';
					}
					var tstyle = '';
					switch(level.levelType) {
					case 'value':
						text = (level.levelCaption && '' !==level.levelCaption) ? level.levelCaption : level.value.toString().substring(0,15);
						tstyle = 'color:#408040;'
						break;
					case 'mdx':
						// JMD1276
						if (level.value.toString().toLowerCase().substr(0,10)=='$variable.') {
							text = (level.levelCaption && '' !==level.levelCaption) ? level.levelCaption : level.value.substr(10);
						}
						else {
							text = (level.levelCaption && '' !==level.levelCaption) ? level.levelCaption : 'MDX';
						}
						tstyle = 'color:#404080;'
						break;
					case 'space':
						text = 'space';
						tstyle = 'color:#808080;'
						break;
					}

					// JMD1456
					if ('filters' == which) {
						if (zenGet(level.enabled,true)) {
							var checked = 'checked="checked" ';
						}
						else {
							var checked = '';
							tstyle += 'color:#808080;';
						}
						html[html.length] = '<input title="'+$$$Text('Enable this filter') + '" type="checkbox" '+checked +' onclick="zenPage.getComponent('+this.index+').enableItem(event,\''+which+'\',\''+key+'\');return false;" />';
					}
					html[html.length] = '<a href="#" onclick="zenPage.getComponent('+this.index+').selectItem(\''+which+'\',\''+key+'\');return false;" style="'+tstyle+'">' + zenEscapeXML(text) + '</a>';
					if (childrenAllowed) {
						// drop target to add a child
						html[html.length] = '<a id="'+which+'child_'+key+'" href="#" onclick="return false;">&nbsp;' + '<img class="dsptIcon" style="height:12px;" src="'+this.getIcon('iconJoin16')+'" title="'+hlpAddChild+'" onclick="zenPage.getComponent('+this.index+').addChildToElement(\''+which+'\',\''+key+'\');" />' + '&nbsp;</a>';
					}

					// options button
					if (optionsAllowed) {
						// only show options for sets:
						// or namedSets
						// !!! not true: now we show this for every level
						if (true || (level.spec.toString().indexOf('.')==-1)||(level.spec.toUpperCase().indexOf('.MEMBERS')!=-1)||(level.spec.toUpperCase().indexOf('.ALLMEMBERS')!=-1)||(level.spec.toUpperCase().indexOf('.%TOPMEMBERS')!=-1)) {
							// show different icon if option is turned on
							var img = (level.levelCaption!=''||level.levelFormat!=''||level.levelStyle!=''||level.levelHeaderStyle!=''||level.levelSummary!=''||level.headEnabled||level.orderEnabled||level.filterEnabled||level.aggEnabled||level.aggFunction) ? 'iconColumn16on' : 'iconColumn16';
							html[html.length] = this.getIconHTML('',true,img,hlpOptions,'zenPage.getComponent('+this.index+').setLevelOptions(\''+which+'\',\''+key+'\');');
						}
					}
					else if ('filters' == which && (level.advanced)) {
						// if this is a named filter, then its spec will be '%FILTER'
						// JMD1453: always show options
						if (true || level.spec != '%FILTER') {
							// advanced filter
							var img = 'iconColumn16on';
							html[html.length] = this.getIconHTML('',true,img,hlpAdvancedFilter,'zenPage.getComponent('+this.index+').setFilterOptions(\''+key+'\');');
						}
					}

					// delete button
					html[html.length] = this.getIconHTML('',true,'iconClose16',hlpRemove,'zenPage.getComponent('+this.index+').removeLevel(\''+which+'\',\''+key+'\');');
					html[html.length] = '</div>';

					if (level.childLevels && level.childLevels.length > 0) {
						html[html.length] = this.getLevelHTML(which,dropMsg,level.childLevels,drillLevel,depth+1,level);
					}
				}
			}
		}
	}
	html[html.length] = '<div id="'+which+'append_'+key+'" class="dsptcDrop" style="padding-left:'+(5+depth*10)+'px;"><a href="#" onclick="zenPage.getComponent('+this.index+').selectItem(\''+which+'\',\'\');return false;">' + dropMsg + '</a></div>';

	return html.join('');
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'pivotTableId':
		if (this.pivotTable && this.pivotTable.removeController) {
			this.pivotTable.removeController();
			this.pivotTable = null;
		}
		this.pivotTableId = value;
		if (this.composite) {
			this.pivotTable = this.composite.getChildById(this.pivotTableId);
		}
		else {
			this.pivotTable = zenPage.getComponentById(this.pivotTableId);
		}
		if (this.pivotTable && this.pivotTable.addController) {
			this.pivotTable.addController(this);
		}
		this.renderContents();
		break;

	default:
		this.invokeSuper('setProperty',arguments);
		break;
	}
}

/// Called by the associated pivotTable when it changes state.
ClientMethod updateState(which) [ Internal, Language = javascript ]
{
	which = zenGet(which);
	var pivot = this.pivotTable;
	
	// DTB905 - Update the current MDX nodes to reflect the current state of the object
	pivot.SetCurrentQueryText('current',pivot.SynthesizeMDX());
	pivot.SetCurrentQueryText('resolved',pivot.SynthesizeMDX());
	var manual = pivot.dataSource == 'manual';

	// JMD1023 Update more selectively
	this.updateToolbar();

	// update columns
	var div = this.findElement('rowsTD');
	div.style.background = manual ? '#F0F0F0' : '';
	if (div && (which==''||which=='rows')) {
		div.innerHTML = this.getRowsHTML();
	}
	var div = this.findElement('columnsTD');
	div.style.background = manual ? '#F0F0F0' : '';
	if (div && (which==''||which=='cols')) {
		div.innerHTML = this.getColumnsHTML();
	}
	var div = this.findElement('measuresTD');
	div.style.background = manual ? '#F0F0F0' : '';
	if (div && (which==''||which=='msrs')) {
		div.innerHTML = this.getMeasuresHTML();
	}
	var div = this.findElement('filtersTD');
	if (div && (which==''||which=='filters')) {
		div.innerHTML = this.getFiltersHTML();
	}
	
	var div = this.findElement('fieldsTD');
	if (div && (which==''||which=='fields')) {
		div.innerHTML = this.getFieldsHTML();
	}

	// drill levels
	var div = this.findElement('drillLevels');
	if (div && (which=='')) {
		div.innerHTML = this.getDrillLevelHTML();
	}
	
	if (zenPage.setModified) {
		zenPage.setModified(true);
	}
}

/// Update a toolbar icon.
ClientMethod updateIcon(id, enabled, image, hlp) [ Internal, Language = javascript ]
{
	var icon = this.findElement(id);
	if (icon) {
		icon.className = enabled ? 'dsptIcon' : 'dsptIconDisabled';
		if (image) {
			icon.src = this.getIcon(image);
		}
		if (hlp) {
			icon.title = hlp;
		}
	}
}

/// Update state of buttons in toolbar.
ClientMethod updateToolbar() [ Internal, Language = javascript ]
{
	// JMD1023: update in place
	var hlpDrill = $$$Text("Show a detail listing for the current selected cell(s)");
	var hlpPivot = $$$Text("Show the pivot table");
	var hlpAutoExecOn = $$$Text("Turn on auto-execute mode");
	var hlpAutoExecOff = $$$Text("Turn off auto-execute mode");

	if (zenPage.showDimensionTree) {
		var span = self.document.getElementById('dimArrow');
		if (span) {
			span.innerHTML = zenPage.showDimensions ? '&laquo;' : '&raquo;';
		}
	}

	var pivot = this.pivotTable;
	this.updateIcon('icBack',pivot.canGoBack());
	this.updateIcon('icFwd',pivot.canGoForward());

	var icon = pivot.changesPending ? 'iconRefresh24on' : 'iconRefresh24';
	this.updateIcon('icRefresh',true,icon);

	// JMD1362: hide/show listing fields
	// show pivot or listing columns
	var divPivot = this.findElement('pivotColumns');
	var divListing = this.findElement('listingColumns');
	if (pivot.isDrillThrough && pivot.canUseListingFields) {
		if (divPivot) {
			divPivot.style.display = 'none';
		}
		if (divListing) {
			divListing.style.display = 'block';
		}
	}
	else {
		if (divPivot) {
			divPivot.style.display = 'block';
		}
		if (divListing) {
			divListing.style.display = 'none';
		}
	}

	// copy & paste
	var enb = (this.selectedColumn!='');
	this.updateIcon('icCopy',enb);

	var enb = this._clipboard&&this.selectedColumn!='';
	this.updateIcon('icPaste',enb);

	var enb = this._clipboard&&(this.selectedColumn=='rows'||this.selectedColumn=='cols')&&this.selectedItem!='';
	this.updateIcon('icPasteDown',enb);

	// swap
	var enb = ((pivot.drillLevels.length==0)&&((pivot.rowLevels&&pivot.rowLevels.length>0)||(pivot.columnLevels&&pivot.columnLevels.length>0)));
	this.updateIcon('icSwap',enb);

	var icon = pivot.dataSource=='automatic' ? 'iconScript24' : 'iconScript24on';
	this.updateIcon('icQuery',true,icon);

	var icon = pivot.isDrillThrough ? 'iconListing24On':'iconListing24';
	var enb = pivot.isDrillThrough ? true : ''!==pivot.selectedRange;
	var hlp = pivot.isDrillThrough ? hlpPivot : hlpDrill;
	this.updateIcon('icListing',enb,icon,hlp);

	this.updateIcon('icBreakdown',''!==pivot.selectedRange);
	var icon = pivot.hasFormatRules() ? 'iconFormat24on' : 'iconFormat24';
	this.updateIcon('icFormat',true,icon);

	var icon = pivot.autoExecute ? 'iconAutoExec24on' : 'iconAutoExec24';
	var hlp = pivot.autoExecute ? hlpAutoExecOff : hlpAutoExecOn;
	this.updateIcon('icAutoExec',true,icon,hlp);
}

/// Click handler for add button.
ClientMethod addLevel(which) [ Language = javascript ]
{
}

/// Click handler for remove level button.
ClientMethod removeLevel(which, key) [ Language = javascript ]
{
	if (!this.pivotTable) return;
	var pivot = this.pivotTable;
	var filterChanged = false;
	var listingFields = false;

	var array = null;
	switch(which) {
	case 'fields':
		array = pivot.listingFields;
		listingFields = true;
		break;
	case 'rows':
		array = pivot.rowLevels;
		break;
	case 'cols':
		array = pivot.columnLevels;
		break;
	case 'msrs':
		array = pivot.measures;
		break;
	case 'filters':
		array = pivot.filters;
		filterChanged = true;
		break;
	}

	if (array) {
		// find item to remove
		var idx = key.toString().split('_');
		for (var n = 0; n < (idx.length - 1); n++) {
			if (null != idx[n+1]) {
				array = array[idx[n]].childLevels;
			}
		}

		if (array[idx[idx.length-1]]) {
			// check for pivot variable
			if (array[idx[idx.length-1]].spec && array[idx[idx.length-1]].spec.toString().toLowerCase().substr(0,10)=='$variable.') {
				filterChanged = true;
			}
		
			// unselect all levels
			if (which == this.selectedColumn) {
				this.selectedItem = '';
				this.selectedColumn = '';
			}

			if (!listingFields) {
				pivot.pushState();
			}
			else {
				pivot.listing = '$$$CUSTOM';
			}
			array.splice(idx[idx.length-1],1);
			if (!listingFields && pivot.isDrillThrough) {
				pivot.mdx = '';
				pivot.isDrillThrough = false;
			}
			pivot.executeQuery(pivot.autoExecute);
		}
	}
	if (filterChanged) {
		if (zenPage.UpdateFilterControls) {
			var msg = zenPage.UpdateFilterControls(pivot.cubeName,zen('filterGroup'),pivot);
			if (''!==msg) {
				alert(msg);
			}
		}
	}
}

/// Click handler for axis options button.
ClientMethod setAxisOptions(which) [ Language = javascript ]
{
	if (!this.pivotTable) return;
	var pivot = this.pivotTable;

	var target = null;
	switch(which) {
	case 'rows':
		target = pivot.rowAxisOptions;
		break;
	case 'cols':
		target = pivot.columnAxisOptions;
		break;
	case 'msrs':
		// show measures options (using options dialog)
		var parms = new Object();
		this._target = target;
		parms.MODE = 'measures';
		parms.INDEX = this.index;
		parms.TEXT = which;
		parms.SPEC = '';
		parms.CUBE = pivot.cubeName;
		parms.MEASURELOCATION = pivot.measureLocation;
		parms.HIDEMEASURES = pivot.hideMeasures;  // + WAL114

		parms.PIVOTNAME = '';
		if (zenPage.pivotName) {
			parms.PIVOTNAME = zenPage.pivotName;
		}

		zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotLevelOptions.zen','MeasureOptions','status=no,scrollbars,resizable=yes,width=500,height=600',parms,this);
		break;
	}

	if (target) {
		// options dialog
		var parms = new Object();
		this._target = target;
		parms.MODE = 'axis';
		parms.INDEX = this.index;
		parms.TEXT = which;
		parms.SPEC = '';
		parms.CUBE = pivot.cubeName;

		parms.HEAD = target.headEnabled ? 1 : 0;
		parms.HEADCOUNT = target.headCount;
		parms.FILTER = target.filterEnabled ? 1 : 0;
		parms.FILTEREXPR = target.filterExpression;
		parms.ORDER = target.orderEnabled ? 1 : 0;
		parms.ORDEREXPR = target.orderExpression;
		parms.ORDERDIR = target.orderDirection;
		parms.SUPPRESS = target.suppress8020 ? 1 : 0;

		parms.DRILLDOWNSPEC = target.drilldownSpec;

		parms.AGG = target.aggEnabled ? 1 : 0;
		parms.AGGFUNC = target.aggFunction;
		parms.AGGFUNCPARM = target.aggFunctionParm;

		parms.LEVELCAPTION = target.levelCaption;
		parms.LEVELFORMAT = target.levelFormat;
		parms.LEVELTYPE = target.levelType;
		parms.LEVELSTYLE = target.levelStyle;
		parms.LEVELHEADERSTYLE = target.levelHeaderStyle;
		parms.LEVELSUMMARY = target.levelSummary;

		parms.PIVOTNAME = '';
		if (zenPage.pivotName) {
			parms.PIVOTNAME = zenPage.pivotName;
		}

		zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotLevelOptions.zen','AxisOptions','status=no,scrollbars,resizable=yes,width=500,height=600',parms,this);
	}
}

/// Click handler for filter options button.
ClientMethod setFilterOptions(idx) [ Language = javascript ]
{
	if (!this.pivotTable) return;
	var pivot = this.pivotTable;

	// remember if we are editing an existing filter
	var expression = '';
	this._target = null;
	if (null != idx) {
		this._target = pivot.filters[idx];
		expression = pivot.filters[idx].spec;
	}

	if (expression == '%FILTER') {
		// named filter
		var parms = {
			NAMEDFILTER:1,
			CUBE:pivot.cubeName,
			EXPRESSION:'',
			FILTERNAME:pivot.filters[idx].text
		};
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.AdvancedFilter.zen','NamedFilter','status=no,scrollbars,resizable=yes,width=700,height=600',parms,this);
	}
	else {
		// options dialog
		var parms = {
			CUBE:pivot.cubeName,
			EXPRESSION:expression
		};
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.AdvancedFilter.zen','FilterOptions','status=no,scrollbars,resizable=yes,width=900,height=600',parms,this);
	}
}

/// Click handler for level options button.
ClientMethod setLevelOptions(which, key) [ Language = javascript ]
{
	if (!this.pivotTable) return;
	var pivot = this.pivotTable;

	var array = null;
	switch(which) {
	case 'rows':
		array = pivot.rowLevels;
		break;
	case 'cols':
		array = pivot.columnLevels;
		break;
	case 'msrs':
		array = pivot.measures;
		break;
	}
	
	if (array) {
		// find item
		var target = null;
		var idx = key.toString().split('_');
		for (var n = 0; n < idx.length; n++) {
			target = array[idx[n]];
			if (null != idx[n+1]) {
				array = array[idx[n]].childLevels;
			}
		}

		if (target) {
			// options dialog
			var parms = new Object();
			this._target = target;
			parms.MODE = 'level';
			parms.INDEX = this.index;
			parms.TEXT = target.text;
			parms.SPEC = target.spec;
			parms.CUBE = pivot.cubeName;

			parms.HEAD = target.headEnabled ? 1 : 0;
			parms.HEADCOUNT = target.headCount;
			parms.FILTER = target.filterEnabled ? 1 : 0;
			parms.FILTEREXPR = target.filterExpression;
			parms.ORDER = target.orderEnabled ? 1 : 0;
			parms.ORDEREXPR = target.orderExpression;
			parms.ORDERDIR = target.orderDirection;
			parms.SUPPRESS = target.suppress8020 ? 1 : 0;
			parms.DRILLDOWNSPEC = target.drilldownSpec;

			parms.AGG = target.aggEnabled ? 1 : 0;
			parms.AGGFUNC = target.aggFunction;
			parms.AGGFUNCPARM = target.aggFunctionParm;
			parms.LEVELCAPTION = target.levelCaption;
			parms.LEVELFORMAT = target.levelFormat;
			parms.LEVELTYPE = target.levelType;
			parms.VALUE = target.value;
			parms.LEVELSTYLE = target.levelStyle;
			parms.LEVELHEADERSTYLE = target.levelHeaderStyle;
			parms.LEVELSUMMARY = target.levelSummary;

			parms.PIVOTNAME = '';
			if (zenPage.pivotName) {
				parms.PIVOTNAME = zenPage.pivotName;
			}
			zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotLevelOptions.zen','LevelOptions','status=no,scrollbars,resizable=yes,width=500,height=650',parms,this);
		}
	}
}

/// This client event is fired when the a popup page launched from this component fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (!this.pivotTable) return;
	var pivot = this.pivotTable;
	
	switch(popupName) {
	case 'NamedFilter':
		if (null != this._target) {
			// check for rename
			if (value != this._target.text) {
				this._target.text = value;
				if (zenPage.updateMemberTree) {
					zenPage.updateMemberTree();
				}		
			}
		}
		pivot.executeQuery(pivot.autoExecute);
		break;

	case 'FilterOptions':
		if (''!=value) {
			pivot.pushState();
			if (null != this._target) {
				// edit
				parm = this._target;
			}
			else {
				// append new filter
				var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
				pivot.filters[pivot.filters.length] = parm;
				parm.text = $$$Text('Advanced filter');
				if (action=='apply') {
					this._target = parm;
				}
			}
			parm.spec = value;
			parm.advanced = true;
			var drillLevel = pivot.getDrillLevel();
			parm.drillLevel = drillLevel;
			if (pivot.isDrillThrough) {
				pivot.mdx = '';
				pivot.isDrillThrough = false;
			}
			pivot.selectedRange = '';
			pivot.executeQuery(pivot.autoExecute);
		}
		break;

	case 'MeasureOptions':
		// + WAL114
		pivot.measureLocation = value.measureLocation;
		pivot.hideMeasures = value.hideMeasures;
		pivot.executeQuery(pivot.autoExecute);
		// - WAL114
		break;

	case 'AxisOptions':
	case 'LevelOptions':
		if (this._newTarget) {
			pivot.pushState();

			// apply new values to level/axis
			this._target.headEnabled = this._newTarget.headEnabled;
			this._target.headCount = this._newTarget.headCount;
			this._target.orderEnabled = this._newTarget.orderEnabled;
			this._target.orderExpression = this._newTarget.orderExpression;
			this._target.orderDirection = this._newTarget.orderDirection;
			this._target.filterEnabled = this._newTarget.filterEnabled;
			this._target.filterExpression = this._newTarget.filterExpression;
			this._target.aggEnabled = this._newTarget.aggEnabled;
			this._target.aggFunction = this._newTarget.aggFunction;
			this._target.aggFunctionParm = this._newTarget.aggFunctionParm;
			this._target.levelCaption = this._newTarget.levelCaption;
			this._target.levelFormat = this._newTarget.levelFormat;
			this._target.levelType = this._newTarget.levelType;
			this._target.value = this._newTarget.value;
			this._target.levelStyle = this._newTarget.levelStyle;
			this._target.levelHeaderStyle = this._newTarget.levelHeaderStyle;
			this._target.levelSummary = this._newTarget.levelSummary;
			this._target.suppress8020 = this._newTarget.suppress8020;
			this._target.spec = this._newTarget.spec;
			this._target.drilldownSpec = this._newTarget.drilldownSpec;

			if (pivot.isDrillThrough) {
				pivot.mdx = '';
				pivot.isDrillThrough = false;
			}
			pivot.executeQuery(pivot.autoExecute);
			delete this._newTarget;
		}
		break;
	}
}

/// Click handler for drill level.
ClientMethod gotoDrillLevel(idx) [ Language = javascript ]
{
	if (!this.pivotTable) return;
	this.pivotTable.gotoDrillLevel(idx);
}

/// Click handler for drill level remove.
ClientMethod removeDrillLevel(idx) [ Language = javascript ]
{
	if (!this.pivotTable) return;
	this.pivotTable.removeDrillLevel(idx);
}

/// Click handler for clear button.
ClientMethod clearLevels(which) [ Language = javascript ]
{
	if (!this.pivotTable) return;
	var pivot = this.pivotTable;
	var filterChanged = false;
	var listingFields = false;

	var array = null;
	var options = null;
	switch(which) {
	case 'rows':
		array = 'rowLevels';
		options = pivot.rowAxisOptions;
		break;
	case 'cols':
		array = 'columnLevels';
		options = pivot.columnAxisOptions;
		break;
	case 'msrs':
		array = 'measures';
		break;
	case 'fields':
		array = 'listingFields';
		listingFields = true;
		break;
	case 'filters':
		array = 'filters';
		filterChanged = true;
		break;
	}

	if ((null!=options && (options.headEnabled || options.orderEnabled || options.filterEnabled)) 
		|| ((null!=array) && pivot[array] && pivot[array].length > 0)) {

		// unselect
		if (which == this.selectedColumn) {
			this.selectedItem = '';
			this.selectedColumn = '';
		}

		if (!listingFields) {
			pivot.pushState();
		}
		if (null!=options) {
			options.headEnabled = false;
			options.orderEnabled = false;
			options.filterEnabled = false;
			options.aggEnabled = false;
		}
		if ((null!=array) && pivot[array] && pivot[array].length > 0) {
			pivot[array] = new Array();
		}
		if (!listingFields && pivot.isDrillThrough) {
			pivot.mdx = '';
			pivot.isDrillThrough = false;
		}
		if (!listingFields || pivot.isDrillThrough) {
			pivot.executeQuery(pivot.autoExecute);
		}
		else {
			this.updateState('fields');
		}
	}
	if (filterChanged) {
		if (zenPage.UpdateFilterControls) {
			var msg = zenPage.UpdateFilterControls(pivot.cubeName,zen('filterGroup'),pivot);
			if (''!==msg) {
				alert(msg);
			}
		}
	}
}

/// Click handler for add selected item button.
/// If nothing selected, adds a space.
ClientMethod addBlankLevel(which) [ Language = javascript ]
{
	if (!this.pivotTable) return;
	var pivot = this.pivotTable;
	var listingFields = false;

	var treeItem = null;
	if (zenPage.getSelectedTreeValue) {
		treeItem = zenPage.getSelectedTreeValue();
		if (treeItem && (treeItem.value=='' || (treeItem.value=='%FILTER' && which!='filters'))) {
			treeItem = null;
		}
	}

	var array = null;
	var value = treeItem ? treeItem.value : '';

	// find dimension name
	// check for pivot variable
	var isPivotVariable = false;
	var varName = '';
	isPivotVariable = (value.toString().toLowerCase().substr(0,10)=='$variable.');
	if (isPivotVariable) {
		var dimName = '';
		varName = value.substr(11);
	}
	else {
		var s = value.toString().split('.');
		var dimName = s[0] ? s[0].toUpperCase() : '';
	}

	switch(which) {
	case 'fields':
		array = pivot.listingFields;
		listingFields = true;
		break;
	case 'rows':
		array = pivot.rowLevels;
		break;
	case 'cols':
		array = pivot.columnLevels;
		break;
	case 'msrs':
		if (treeItem) {
			array = pivot.measures;
		}
		break;
	case 'filters':
		var fmsg = this.isValidFilter(dimName,value);
		if (fmsg) {
			alert(fmsg);
			return;
		}
		if (treeItem) {
			array = pivot.filters;
		}
		break;
	}

	var isField = (value.toString().substr(0,9)=='$$$FIELD:');
	if (isField) {
		if (!listingFields) {
			return;
		}
		pivot.listing = '$$$CUSTOM';
	}
	else if (!isField && listingFields) {
		return;
	}

	if (null!=array) {
		if (!listingFields) {
			pivot.pushState();
		}

		var drillLevel = pivot.getDrillLevel();

		// PFS014 - Initialize parm before if statements
		// append
		var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
		parm.drillLevel = drillLevel;
		
		if (isField) {
			// PFS014 - Incorporate logic from DTB309 here as well
			// remove $$$FIELD:
			var t = value.toString().split(':');
			t.splice(0,1);							// Remove the $$$FIELD token
			var fieldExpr = t.splice(0,1)[0];		// DTB309 - The field expression cannot contain the ':' character, so it will now be the first piece
			value = '$$$FIELD:'+t.join(':');		// DTB309 - Remaining is the name, which may contain ':'. Replace the $$$FIELD token in front
			pivot.listing = '$$$CUSTOM';

			parm.spec = fieldExpr;					// Field expression for building the custom SQL query
			parm.value = value;						// DTB309 - Logical value. Store for lookup in other locales
			parm.text = treeItem.text;				// Current display value
		} else if (treeItem) {
			parm.spec = value;
			parm.text = treeItem.text;

			// if this is a named filter, then its value will be '%FILTER'
			if (treeItem.value == '%FILTER') {
				parm.advanced = true;
			}
		}
		else {
			parm.spec = '';
			parm.text = '';
			parm.levelType = 'space';
		}
		array[array.length] = parm;

		// pivot variable
		if (isPivotVariable && parm) {
			parm.levelType = 'mdx';
			parm.value = value;
		}

		if ('filters' == which) {
			// call this first to get filter captions!
			if (zenPage.UpdateFilterControls) {
				var msg = zenPage.UpdateFilterControls(pivot.cubeName,zen('filterGroup'),pivot);
				if (''!==msg) {
					alert(msg);
				}
			}
		}
		if (!listingFields || pivot.isDrillThrough) {
			pivot.executeQuery(pivot.autoExecute);
		}
		else {
			this.updateState('fields');
		}
	}
}

/// Test if a spec can be used as a filter. Return '' if ok else return an error message.
ClientMethod isValidFilter(dimName, value) [ Language = javascript ]
{
	var msg = '';
	if ((dimName == '[MEASURES]')||(dimName == 'MEASURES')||(dimName == '[%QUALITYMEASURE]')||(dimName == '%QUALITYMEASURE')) {
		msg = $$$Text('Measure cannot be used as a filter');
	}
	else if (value.toUpperCase().indexOf('.%TOPMEMBERS') != -1) {
		msg = $$$Text('Only a level within a dimension can be used as a filter');
	}
	else if (value.toUpperCase().indexOf('.CURRENTMEMBER') != -1) {
		msg = $$$Text('Dimension property cannot be used as a filter');
	}
	else if (value.toUpperCase().substr(0,5) == '%KPI(') {
		// JMD1418
		msg = $$$Text('Plug-in cannot be used as a filter');
	}
	return msg;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// set up association with pivotTable
	this.setProperty('pivotTableId',this.pivotTableId);
}

/// Drop handler. This is called when an item is dropped onto the controller.
ClientMethod dropStartHandler(dragData) [ Language = javascript ]
{
	var value = dragData.value;
	var text = dragData.text;
	var pivot = this.pivotTable;
	var noExec = false;

	if (!pivot) return;
	var drillLevel = pivot.getDrillLevel();

	// DTB268 - Strip any %SHAREDx token
	if (value.indexOf('%SHARED')>-1) {
		// DTB715 - Snip the %SHARED token from the spec
		var valueArray = value.toString().split('.');
		for (n in valueArray) {
			if (valueArray[n].indexOf('%SHARED')>-1) {
				valueArray.splice(n,1);
			}
		}
		value = valueArray.join('.');
	}

	// check for special relationship marker
	if (value.toString().substr(0,2)=='@@') {
		return;
	}

	// check for fields marker
	var isField = (value.toString().substr(0,9)=='$$$FIELD:');
	
	// if listing, skip
	if (value.toString().substr(0,11)=='$$$LISTING:') {
		return;
	}

	// check for pivot variable
	var isPivotVariable = false;
	var varName = '';
	if (!isField) {
		isPivotVariable = (value.toString().toLowerCase().substr(0,10)=='$variable.');
		if (isPivotVariable) {
			varName = value.substr(11);
		}
	}

	// if dragData._targetType is defined, then our caller is passing this value to us
	if (dragData._targetType) {
		tgtType = dragData._targetType;
	}
	else {
		// determine target
		var el = ZLM.getDragInnerDestination();
		var tgtId = el.id;

		while ('' == tgtId) {
			el = el.parentNode;
			tgtId = el.id;
			if (!el.parentNode) {
				break;
			}
		}
		var tgtIndex = -1;
		var tgtType = '';
		var parentIndex = -1;
		var idx;

		if (tgtId) {
			// pull apart id: which_i1_i2_...
			idx = tgtId.split('_');

			tgtIndex = isNaN(idx[1]) ? -1 : idx[1];
			tgtType = idx[0];
		}
		else if ('' == tgtId) {
			return;
		}
		dragData.targetItem = tgtId;
	}

	// find dimension name
	if (isPivotVariable) {
		var dimName = '';
	}
	else {
		var s = value.toString().split('.');
		var dimName = s[0] ? s[0].toUpperCase() : '';
	}

	var changed = false;
	var filterChanged = false;
	// check for pivot variable
	if (isPivotVariable) {
		filterChanged = true;
	}

	if (isField) {
		var t = value.toString().split(':');
		t.splice(0,1);							// Remove the $$$FIELD token
		var fieldExpr = t.splice(0,1)[0];		// DTB309 - The field expression cannot contain the ':' character, so it will now be the first piece
		value = '$$$FIELD:'+t.join(':');		// DTB309 - Remaining is the name, which may contain ':'. Replace the $$$FIELD token in front
		pivot.listing = '$$$CUSTOM';

		if ((tgtType=='fields')||(tgtType=='fieldsappend')) {
			if (('fields' == tgtType)&&tgtIndex >= 0 && pivot.listingFields[tgtIndex]) {
				pivot.listingFields[tgtIndex].spec = fieldExpr;		// Field expression for building the custom SQL query
				pivot.listingFields[tgtIndex].value = value;		// DTB309 - Logical value. Store for lookup in other locales
				pivot.listingFields[tgtIndex].text = text;			// Current display value
			}
			else {
				// create
				var msr = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
				msr.spec = fieldExpr;		// Field expression for building the custom SQL query
				msr.value = value;			// DTB309 - Logical value. Store for lookup in other locales
				msr.text = text;			// Current display value
				pivot.listingFields[pivot.listingFields.length] = msr;
			}

			if (pivot.controller) {
				pivot.controller.updateState('fields');
			}
			if (pivot.isDrillThrough) {
				pivot.executeQuery(pivot.autoExecute);
			}
		}
		else {
			alert($$$Text('Custom listing fields can only be added to listings'));
		}
		return;
	}

	switch(tgtType) {
	case 'msrs':
	case 'msrsappend':
		if ((dimName == '[MEASURES]')||(dimName == 'MEASURES')||
			(dimName == '[%QUALITYMEASURE]')||(dimName == '%QUALITYMEASURE')) {
			pivot.pushState();
			if (('msrs' == tgtType)&&tgtIndex >= 0 && pivot.measures[tgtIndex]) {
				pivot.measures[tgtIndex].spec = value;
				pivot.measures[tgtIndex].text = text;
				pivot.measures[tgtIndex].drillLevel = drillLevel;
			}
			else {
				// create
				var msr = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
				msr.spec = value;
				msr.text = text;
				msr.drillLevel = drillLevel;
				pivot.measures[pivot.measures.length] = msr;
			}
			changed = true;
		}
		else {
			alert($$$Text("Only measures can be placed in the measures list"));
		}
		break;
	case 'rows':
	case 'rowschild':
	case 'rowsappend':
	case 'cols':
	case 'colschild':
	case 'colsappend':
		if (value == '%FILTER') {
			alert($$$Text("Named filters can only be placed in the filters list"));
		}
		else {
			var parm = null;
			pivot.pushState();
			var array = (('rows'==tgtType)||('rowsappend'==tgtType)||('rowschild'==tgtType)) ? pivot.rowLevels : pivot.columnLevels;
			var target = null;
			for (var n = 1; n < idx.length; n++) {
				target = array[idx[n]];
				if (null == target) break;
				if (null != idx[n+1]) {
					array = array[idx[n]].childLevels;
				}
			}
			if (target) {
				if (('rowsappend'==tgtType)||('colsappend'==tgtType)) {
					// append
					parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
					parm.spec = value;
					parm.text = text;
					parm.drillLevel = drillLevel;
					array[array.length] = parm;
				}
				else if (('rowschild'==tgtType)||('colschild'==tgtType)) {
					// add child
					parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
					parm.spec = value;
					parm.text = text;
					parm.drillLevel = drillLevel;
					target.childLevels[target.childLevels.length] = parm;
				}
				else {
					// replace
					target.spec = value;
					target.text = text;
				}
			}
			else {
				// append
				parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
				parm.spec = value;
				parm.text = text;
				parm.drillLevel = drillLevel;
				array[array.length] = parm;
			}
			if (isPivotVariable && parm) {
				parm.levelType = 'mdx';
				parm.value = value;
			}
			changed = true;
		}
		break;
	case 'filters':
	case 'filtersappend':
		var fmsg = this.isValidFilter(dimName,value);
		if (fmsg) {
			alert(fmsg);
			return false;
		}
		if ((dimName != '[MEASURES]')&&(dimName != 'MEASURES')&&(dimName != '[%QUALITYMEASURE]')&&(dimName != '%QUALITYMEASURE')) {
			var parm = null;
			pivot.pushState();
			if (value.toUpperCase().indexOf('.MEMBERS') != -1) {
				// no actual change to the query; don't execute
				noExec = true;
			}
			if (('filters' == tgtType)&&tgtIndex >= 0 && pivot.filters[tgtIndex]) {
				parm = pivot.filters[tgtIndex];
				parm.spec = value;
				parm.text = text;
				parm.value = '';
				parm.key = '';
			}
			else {
				// append
				var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
				parm.spec = value;
				parm.text = text;
				parm.drillLevel = drillLevel;
				pivot.filters[pivot.filters.length] = parm;
			}
			
			// if this is a named filter, then its value will be '%FILTER'
			if (value == '%FILTER') {
				parm.advanced = true;
			}
			changed = true;
			filterChanged = true;
			if (isPivotVariable && parm) {
				parm.levelType = 'mdx';
				parm.value = value;
			}
		}
		break;

	default:
		break;
	}

	if (filterChanged) {
		// call this first to get filter captions!
		if (zenPage.UpdateFilterControls) {
			var msg = zenPage.UpdateFilterControls(pivot.cubeName,zen('filterGroup'),pivot);
			if (''!==msg) {
				alert(msg);
			}
		}
	}

	if (changed) {
		if (pivot.isDrillThrough) {
			pivot.mdx = '';
			// JMD933: pivot.isDrillThrough = false;
		}
		pivot.selectedRange = '';
		pivot.sortColumn = 0;
		pivot.sortDir = 'ASC';
		if (!noExec) {
			pivot.executeQuery(pivot.autoExecute);
		}
		else {
			pivot.updateController();
		}
	}
	return true;
}

/// Hide the message box.
ClientMethod hideMessage() [ Language = javascript ]
{
	var div = this.findElement('message');
	if (div) {
		// PFS092 - Remove innerHTML so printing to PDF does not pick this up
		div.innerHTML = '';
		div.style.display = 'none';
	}
}

/// Display the pivot status message box.
ClientMethod showMessage(pivot, msg, pct, listing, units) [ Language = javascript ]
{
	units = zenGet(units,'%');
	var div = this.findElement('message');
	if (div) {
		var html = '';
		html += '<table class="dspctMessage"><tr>';
		if (listing) {
			// listing message
			html += '<td><i>' + msg + '</i></td>';
		}
		else {
			pct = parseFloat(pct);
			pct = isNaN(pct) ? '0' : (Math.round(pct*100)/100);

			html += '<td style="font-size:10pt;"><i>' + msg + '</i></td>';
			html += '<td class="dsptPct" style="font-size:12pt;font-weight:bold;">' + pct + '<span style="font-size:12pt;">'+units+'</span></td>';

			// progress bar
			var pos = (pivot.queryCalls % 10) * 10;
			html += '<td style="width:100px;border:1px solid darkblue;overflow:hidden;"><div style="border:1px solid #808080;border-radius:3px; background:rgb(47,98,128); color:rgb(47,98,128); font-size: 8pt; width:10px; left:'+pos+'px;position:relative;">X</div></td>';
		}
		html += '</tr></table>';

		div.innerHTML = html;
		div.style.display = 'block';
	}
}

/// Select the given item.
ClientMethod selectItem(which, item) [ Language = javascript ]
{
	this.selectedColumn = which;
	this.selectedItem = item;
	this.updateState(which);
}

/// Enable the given item.
ClientMethod enableItem(evt, which, item) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt.preventDefault) {
		evt.preventDefault();
	}
	var pivot = this.getPivotTable();
	var array = null;
	switch(which) {
	case 'filters':
		array = pivot.filters;
		break;
	}
	if (array && array[item]) {
		array[item].enabled = !array[item].enabled;
		this.updateState(which);
		pivot.executeQuery(pivot.autoExecute);
		if (zenPage.UpdateFilterControls) {
			var msg = zenPage.UpdateFilterControls(pivot.cubeName,zen('filterGroup'),pivot);
		}
	}
}

/// Move the current item up.
ClientMethod moveItemUp(which) [ Language = javascript ]
{
	if (this.selectedColumn!=which) return;

	var filterChanged = false;	
	var pivot = this.getPivotTable();
	var array = null;
	switch(this.selectedColumn) {
	case 'fields':
		array = pivot.listingFields;
		break;
	case 'rows':
		array = pivot.rowLevels;
		break;
	case 'cols':
		array = pivot.columnLevels;
		break;
	case 'msrs':
		array = pivot.measures;
		break;
	case 'filters':
		array = pivot.filters;
		break;
	}

	if (array && this.selectedItem !== '') {
		// find item to move
		var key = this.selectedItem;
		var idx = key.toString().split('_');
		for (var n = 0; n < (idx.length - 1); n++) {
			if (null != idx[n+1]) {
				array = array[idx[n]].childLevels;
			}
		}

		var no = parseInt(idx[idx.length-1]);
		if (array[no] && no > 0) {
			var swap = array[no-1];
			if (swap) {
				pivot.pushState();
				array[no-1] = array[no];
				array[no] = swap;

				// move selection along with item
				idx[idx.length-1] = no - 1;
				this.selectedItem = idx.join('_');

				pivot.executeQuery(pivot.autoExecute);
				this.updateState();
				if (this.selectedColumn=='filters') {
					filterChanged = true;
				}
			}
		}
	}
	if (filterChanged) {
		if (zenPage.UpdateFilterControls) {
			var msg = zenPage.UpdateFilterControls(pivot.cubeName,zen('filterGroup'),pivot);
			if (''!==msg) {
				alert(msg);
			}
		}
	}
}

/// Move the current item down.
ClientMethod moveItemDown(which) [ Language = javascript ]
{
	if (this.selectedColumn!=which) return;

	var filterChanged = false;	
	var pivot = this.getPivotTable();
	var array = null;
	switch(this.selectedColumn) {
	case 'fields':
		array = pivot.listingFields;
		break;
	case 'rows':
		array = pivot.rowLevels;
		break;
	case 'cols':
		array = pivot.columnLevels;
		break;
	case 'msrs':
		array = pivot.measures;
		break;
	case 'filters':
		array = pivot.filters;
		break;
	}

	if (array && this.selectedItem !== '') {
		// find item to move
		var key = this.selectedItem;
		var idx = key.toString().split('_');
		for (var n = 0; n < (idx.length - 1); n++) {
			if (null != idx[n+1]) {
				array = array[idx[n]].childLevels;
			}
		}

		var no = parseInt(idx[idx.length-1]);
		if (array[no] && no < (array.length - 1)) {
			var swap = array[no+1];
			if (swap) {
				pivot.pushState();
				array[no+1] = array[no];
				array[no] = swap;
				// move selection along with item
				idx[idx.length-1] = no + 1;
				this.selectedItem = idx.join('_');

				pivot.executeQuery(pivot.autoExecute);
				this.updateState(this.selectedColumn);
				if (this.selectedColumn=='filters') {
					filterChanged = true;
				}
			}
		}
	}
	if (filterChanged) {
		if (zenPage.UpdateFilterControls) {
			var msg = zenPage.UpdateFilterControls(pivot.cubeName,zen('filterGroup'),pivot);
			if (''!==msg) {
				alert(msg);
			}
		}
	}
}

/// Test if an item can move up.
ClientMethod itemCanMoveUp(which, key) [ Language = javascript ]
{
	if (this.selectedColumn!=which) return false;
	
	var pivot = this.getPivotTable();
	var array = null;
	switch(this.selectedColumn) {
	case 'fields':
		array = pivot.listingFields;
		break;
	case 'rows':
		array = pivot.rowLevels;
		break;
	case 'cols':
		array = pivot.columnLevels;
		break;
	case 'msrs':
		array = pivot.measures;
		break;
	case 'filters':
		array = pivot.filters;
		break;
	}

	if (array && key !== '') {
		// find item to move
		var idx = key.toString().split('_');
		for (var n = 0; n < (idx.length - 1); n++) {
			if (null != idx[n+1]) {
				array = array[idx[n]].childLevels;
			}
		}

		var no = parseInt(idx[idx.length-1]);
		if (array[no] && no > 0) {
			return true;
		}
	}
	return false;
}

/// Test if an item can move down.
ClientMethod itemCanMoveDown(which, key) [ Language = javascript ]
{
	if (this.selectedColumn!=which) return false;
	
	var pivot = this.getPivotTable();
	var array = null;
	switch(this.selectedColumn) {
	case 'fields':
		array = pivot.listingFields;
		break;
	case 'rows':
		array = pivot.rowLevels;
		break;
	case 'cols':
		array = pivot.columnLevels;
		break;
	case 'msrs':
		array = pivot.measures;
		break;
	case 'filters':
		array = pivot.filters;
		break;
	}

	if (array && key !== '') {
		// find item to move
		var idx = key.toString().split('_');
		for (var n = 0; n < (idx.length - 1); n++) {
			if (null != idx[n+1]) {
				array = array[idx[n]].childLevels;
			}
		}

		var no = parseInt(idx[idx.length-1]);
		if (array[no] && no < (array.length - 1)) {
			return true;
		}
	}
	return false;
}

/// Copy pivot level item.
ClientMethod copyItem() [ Language = javascript ]
{
	if (this.selectedColumn=='') return;

	// find the item
	var pivot = this.getPivotTable();
	var array = null;
	switch(this.selectedColumn) {
	case 'fields':
		array = pivot.listingFields;
		break;
	case 'rows':
		array = pivot.rowLevels;
		break;
	case 'cols':
		array = pivot.columnLevels;
		break;
	case 'msrs':
		array = pivot.measures;
		break;
	case 'filters':
		array = pivot.filters;
		break;
	}

	if (array && this.selectedItem !== '') {
		// find item to copy
		var key = this.selectedItem;
		var idx = key.toString().split('_');
		for (var n = 0; n < (idx.length - 1); n++) {
			if (null != idx[n+1]) {
				array = array[idx[n]].childLevels;
			}
		}

		var no = parseInt(idx[idx.length-1]);
		
		if (array[no]) {
			// copy the current item
			this._clipboard = array[no].clone();
			this.updateState(this.selectedColumn);
		}
	}
}

/// Paste pivot level item.
ClientMethod pasteItem(where) [ Language = javascript ]
{
	if (!this._clipboard) return;

	// paste item into selected column
	// find the current item
	var pivot = this.getPivotTable();
	var array = null;
	switch(this.selectedColumn) {
	case 'fields':vot
		array = pi.listingFields;
		break;
	case 'rows':
		array = pivot.rowLevels;
		break;
	case 'cols':
		array = pivot.columnLevels;
		break;
	case 'msrs':
		array = pivot.measures;
		break;
	case 'filters':
		array = pivot.filters;
		break;
	}

	// test for illegal paste
	if ('%FILTER'==this._clipboard.spec && this.selectedColumn!='filters') {
		alert($$$Text('Named filters can only be placed in the filters list'));
		return;
	}

	if (array) {
		// find item to paste after
		var key = this.selectedItem;
		if (this.selectedItem=='') {
			var no = 0;
		}
		else {
			var idx = key.toString().split('_');
			for (var n = 0; n < (idx.length - 1); n++) {
				if (null != idx[n+1]) {
					array = array[idx[n]].childLevels;
				}
			}

			var no = parseInt(idx[idx.length-1]);
		}

		if (array[no] || array.length==0) {
			pivot.pushState();

			var newItem = this._clipboard.clone(true);
			if ('under'==where) {
				if (!array[no].childLevels) {
					array[no].childLevels = [];
				}
				array[no].childLevels.splice(0,0,newItem);
			}
			else {
				// paste item after selected item
				array.splice(no+1,0,newItem);

				// select new item
				if (this.selectedItem!='') {
					idx[idx.length-1] = no + 1;
					this.selectedItem = idx.join('_');
				}
			}

			pivot.executeQuery(pivot.autoExecute);
			this.updateState(this.selectedColumn);
		}
	}
}

/// Reset the pivot table.
ClientMethod resetTable() [ Language = javascript ]
{
	this.selectedItem = '';
	this.selectedColumn = '';
	var pivot = this.getPivotTable();
	pivot.resetTable();

	// JMD1226 reset listing columns
	if (pivot.canUseListingFields) {
		// show pivot or listing columns
		var divPivot = this.findElement('pivotColumns');
		var divListing = this.findElement('listingColumns');
		if (divPivot) {
			divPivot.style.display = 'block';
		}
		if (divListing) {
			divListing.style.display = 'none';
		}
	}
}

/// Build the list of icons used by this component.
ClientMethod buildIconList() [ Language = javascript ]
{
	if (true) {
		this._iconList = {
			iconJoin16:'deepsee/ds2_arrow_southeast_44.png',
			iconUp16:'deepsee/ds2_arrow_north_44.png',
			iconDown16:'deepsee/ds2_arrow_south_44.png',
			iconAdd16:'deepsee/ds2_plus_44.png',
			iconColumn16:'deepsee/ds2_gear_44.png',
			iconColumn16on:'deepsee/ds2_gear2_44.png',
			iconClose16:'deepsee/ds2_x_44.png',
			iconHome24:'deepsee/ds2_house_44.png',
			iconBack24:'deepsee/ds2_arrow_west_44.png',
			iconForward24:'deepsee/ds2_arrow_east_44.png',
			iconRefresh24:'deepsee/ds2_refresh_44.png',
			iconRefresh24on:'deepsee/ds2_redo_44.png',
			iconCopy24:'deepsee/ds2_upload_44.png',
			iconPaste24:'deepsee/ds2_download_44.png',
			iconPasteDown24:'deepsee/ds2_arrow_southeast_44.png',
			iconSwap24:'deepsee/ds2_circle_bothways_44.png',
			iconListing24On:'deepsee/ds2_list_44.png',
			iconListing24:'deepsee/ds2_binoculars_44.png',
			iconAnalysis24:'deepsee/ds2_stats_44.png',
			iconScript24:'deepsee/ds2_sketchbook_44.png',
			iconScript24on:'deepsee/ds2_compose_44.png',
			iconExcel24:'deepsee/ds2_action_44.png',
			iconPrinter24:'deepsee/ds2_printer_44.png',
			iconCSV24:'deepsee/open_widget.png',		// DP-402897
			iconPivotOptions24:'deepsee/ds2_wrench2_44.png',
			iconPrintConfig24:'deepsee/ds2_ruler_44.png',
			iconChartOptions24:'deepsee/ds2_linechart_44.png',
			iconFormat24:'deepsee/ds2_sun_44.png',
			iconFormat24on:'deepsee/ds2_sun_44.png',
			iconCancel24:'deepsee/ds2_circle_x_44.png',
			iconAutoExec24on:'deepsee/ds2_todo_44.png',
			iconAutoExec24:'deepsee/ds2_todo_44.png'
		}
	}
	else {
		this._iconList = {
			iconJoin16:'deepsee/ds_join_16.gif',
			iconUp16:'deepsee/up_16.png',
			iconDown16:'deepsee/up_16.png',
			iconAdd16:'deepsee/add_16.png',
			iconColumn16:'deepsee/column_16.gif',
			iconColumn16on:'deepsee/column_fav_16.gif',
			iconClose16:'deepsee/close_a_16.gif',
			iconHome24:'deepsee/home_24.png',
			iconBack24:'deepsee/ds_back_24.gif',
			iconForward24:'deepsee/ds_forward_24.gif',
			iconRefresh24:'deepsee/loop_24.gif',
			iconRefresh24on:'deepsee/loop_fav_24.gif',
			iconCopy24:'portal/copy_24.gif',
			iconPaste24:'portal/paste_24.gif',
			iconPasteDown24:'portal/paste_down_24.gif',
			iconSwap24:'deepsee/swap_24.gif',
			iconListing24On:'deepsee/table_header_24.gif',
			iconListing24:'deepsee/views_24.gif',
			iconAnalysis24:'deepsee/show_wireframe_zoom_24.gif',
			iconScript24:'deepsee/script_24.png',
			iconScript24on:'deepsee/script_fav_24.gif',
			iconExcel24:'deepsee/excel_24.gif',
			iconPrinter24:'deepsee/printer_24.png',
			iconPivotOptions24:'deepsee/gear_24.png',
			iconPrintConfig24:'deepsee/printer_config_24.gif',
			iconChartOptions24:'deepsee/line_chart_24.png',
			iconFormat24:'deepsee/vcq_24.gif',
			iconFormat24on:'deepsee/vcq_fav_24.gif',
			iconCancel24:'deepsee/cancel_24.png',
			iconAutoExec24on:'deepsee/window_refresh_24.gif',
			iconAutoExec24:'deepsee/window_lock_24.gif'
		}
	}
}

/// Return the url of the icon with the given id.
ClientMethod getIcon(id) [ Language = javascript ]
{
	if (!this._iconList) {
		this.buildIconList();
	}
	var icon = this._iconList[id];
	return icon ? icon : 'deepsee/cube_48.gif';
}

/// User pressed on the swap button.
ClientMethod swapRows() [ Internal, Language = javascript ]
{
	this.getPivotTable().swapRowsAndColumns();
	var icon = this.findElement('icSwap');
	if (icon) {
		this._swapAngle = (null == this._swapAngle) ? 360 : this._swapAngle+360;
		icon.style.WebkitTransform='rotate('+this._swapAngle+'deg)';
	}
}

/// User click on "join" arrow.
ClientMethod addChildToElement(which, key) [ Internal, Language = javascript ]
{
	if (!this.pivotTable) return;
	var pivot = this.pivotTable;

	var treeItem = null;
	if (zenPage.getSelectedTreeValue) {
		treeItem = zenPage.getSelectedTreeValue();
		if (treeItem && (treeItem.value=='' || (treeItem.value=='%FILTER' && which!='filters'))) {
			treeItem = null;
		}
	}
	if (!treeItem) {
		return;
	}

	var idx = key.toString().split('_');
	var array = null;
	switch(which) {
	case 'rows':
		array = pivot.rowLevels;
		break;
	case 'cols':
		array = pivot.columnLevels;
		break;
	default:
		break;
	}

	if (null!=array) {
		var target = null;
		for (var n = 0; n < idx.length; n++) {
			target = array[idx[n]];
			if (null == target) break;
			if (null != idx[n+1]) {
				array = array[idx[n]].childLevels;
			}
		}
		if (target) {
			pivot.pushState();

			var drillLevel = pivot.getDrillLevel();

			// add child
			var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
			parm.drillLevel = drillLevel;
			parm.spec = treeItem.value;
			parm.text = treeItem.text;
			target.childLevels[target.childLevels.length] = parm;
			pivot.executeQuery(pivot.autoExecute);
		}
	}
}

}
