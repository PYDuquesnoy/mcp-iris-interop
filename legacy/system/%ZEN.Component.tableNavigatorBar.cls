/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This composite component displays a navigation bar
/// (paging information and links to pages) for
/// a <class>%ZEN.Component.tablePane</class>.<br>
Class %ZEN.Component.tableNavigatorBar Extends component [ Deprecated, System = 3 ]
{

Parameter SYSMODULE = "table";

/// Localization domain
Parameter DOMAIN = "%ZEN";

/// id of <class>%ZEN.Component.tablePane</class> component this
/// navigator is associated with.<br>
/// Note: if this component is placed within a composite element, then the
/// tablePane must be within the same composite element.
Property tablePaneId As %ZEN.Datatype.id(COMPONENTTYPE = "tablePane");

/// This is the maximum number of page number "buttons" to display within
/// the navigator. The default is 5.<br/>
/// If set to less than 1, then 1 is used.
Property maxButtons As %ZEN.Datatype.integer [ InitialExpression = 5 ];

/// This is the maximum page size that a user can enter within
/// the navigator. The default is 1000.
Property maxPageSize As %ZEN.Datatype.integer [ InitialExpression = 1000 ];

/// This is the maximum rows that a user can enter within the navigator.
/// The default is 100000. Designer may override this, but end user's entry cannot be greater than this number.
Property navmaxRows As %ZEN.Datatype.integer [ InitialExpression = 100000 ];

/// This is the maximum rows that the associated table can load. Value can be changed from the "Max rows" field.
/// The default is 1000.
Property maxRows As %ZEN.Datatype.integer [ InitialExpression = 1000 ];

/// If true, show a filter input box as part of the navigator.
/// This filter box does not do anything on its own, you need to assign
/// an onfilterChange event to make this happen.
Property showFilter As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, let users control the page size of the table pane using
/// the navigator.
Property showPageSize As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, let users control the maximum rows of the table pane using
/// the navigator.
Property showMaxRows As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, it will invoke user function to save pageSize and maxRows and
/// designer should provide call backs for onPageSizeChange and onMaxRowsChange. 
Property saveSizeMax As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Localized "Filter" message.
Property msgFilter As %ZEN.Datatype.caption;

/// Localized "page size" message.
Property msgPageSize As %ZEN.Datatype.caption;

/// Localized "max rows" message.
Property msgMaxRows As %ZEN.Datatype.caption;

/// Localized "Results" message.
Property msgFound As %ZEN.Datatype.caption;

/// Localized "Page" message.
Property msgPage As %ZEN.Datatype.caption;

/// Localized "of" found message.
Property msgOf As %ZEN.Datatype.caption;

/// Localized "first page" message.
Property msgFirstPage As %ZEN.Datatype.caption;

/// Localized "last page" message.
Property msgLastPage As %ZEN.Datatype.caption;

/// Localized "next page" message.
Property msgNextPage As %ZEN.Datatype.caption;

/// Localized "previous page" message.
Property msgPreviousPage As %ZEN.Datatype.caption;

/// onfilterChange event handler:
/// This event is fired when the user changes the value in the
/// filter box displayed by this navigator.
/// <var>value</var> is passed to this callback and is the 
/// current value of the filter control.
Property onfilterChange As %ZEN.Datatype.eventHandler;

/// onPageSizeCghange event handler:
/// This event is fired when user changes the value in the "Page size" box 
/// displayed by this navigator.
/// <var>value</var> is passed to this callback and is the 
/// current value of the "Page size" control.
Property onPageSizeChange As %ZEN.Datatype.eventHandler;

/// onMaxRowsChange event handler:
/// This event is fired when user changes the value in the "Max rows" box 
/// displayed by this navigator.
/// <var>value</var> is passed to this callback and is the 
/// current value of the "Max rows" control.
Property onMaxRowsChange As %ZEN.Datatype.eventHandler;

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* @doc="Table around navigator bar." */
.tnbrTable {
	border: 1px solid black;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
	padding: 1px;
}

/* @doc="Buttons within navigator bar." */
.tnbrPagingButtons {
	color: black;
	background: white;
	border: 1px solid #404040;
	padding: 1px;
	margin-left: 5px;
	font-size: 0.7em;
}

/* @doc="Link within navigator bar." */
.tnbrPageLink {
	color: black;
	padding-left: 5px;
	padding-right: 5px;
}

/* @doc="Disabled link within navigator bar." */
.tnbrPageLinkDisabled {
	color: #B0B0B0;
	padding-left: 5px;
	padding-right: 5px;
}

/* @doc="Current page button within navigator bar." */
.tnbrPageLinkCurr {
	color: black;
	font-weight: bold;
	padding-left: 4px;
	padding-right: 4px;
	border-left: 1px black solid;
	border-right: 1px black solid;

	background: #404000;
	background-image: url(images/grad-yellow-10x100.png);
	background-repeat: repeat-x;
}

/* @doc="Row count indicator." */
.tnbrFound {
	color: #202020;
	font-weight: bold;
	font-size: 0.7em;
}

/* @doc="Filter and page size control." */
.tnbrFilter {
	color: #202020;
	padding-right: 10px;
	font-weight: bold;
	font-size: 0.7em;
}

.tnbrFilter input {
	color: #202020;
	font-size: 0.9em;
	border: 1px solid #404040;
}

</style>
}

Method %DrawHTML()
{
	#; if localized properties have not been set, set them
	Set:..msgFilter="" ..msgFilter = $$$Text("Filter")
	Set:..msgPageSize="" ..msgPageSize = $$$Text("Page size")
	Set:..msgFound="" ..msgFound = $$$Text("Results")
	Set:..msgPage="" ..msgPage = $$$Text("Page")
	Set:..msgOf="" ..msgOf = $$$Text("of")
	Set:..msgFirstPage="" ..msgFirstPage = $$$Text("Go to first page")
	Set:..msgLastPage="" ..msgLastPage = $$$Text("Go to last page")
	Set:..msgNextPage="" ..msgNextPage = $$$Text("Go to next page")
	Set:..msgPreviousPage="" ..msgPreviousPage = $$$Text("Go to previous page")
	Set:..msgMaxRows="" ..msgMaxRows = $$$Text("Max rows")
		
	Do ##super()
}

/// Client-side method to render this control.
ClientMethod renderContents() [ Language = javascript ]
{
	// test if we have not been rendered yet
	if (this.getEnclosingDiv() == null) return;

	// build DHTML for the component
	var html = new Array();
	html[html.length] = '<table class="tnbrTable" border="0" cellpadding="3" cellspacing="0"><tr>';

	html[html.length] = '<td align="left" valign="center" nowrap>&nbsp;';
	var table = this.tablePane;
	if (null == table) {
		// try to connect
		if (this.tablePaneId!='') {
			var target=null;
			if (this.composite) {
				target = this.composite.getChildById(this.tablePaneId);
			}
			else {
				target = zenPage.getComponentById(this.tablePaneId);
			}
			if (target) {
				this.connect();
				table = this.tablePane;
			}
		}
	}

	if (null == table) {
		// disconnected
		html[html.length] = 'Not connected';
	}
	else {
		// get stats from table
		var rowCount = table.getProperty('rowCount');
		var pageSize = table.getProperty('pageSize');
		var maxRows = table.getProperty('maxRows');
		
		if (this.showFilter) {
			html[html.length] = '<span class="tnbrFilter">';
			html[html.length] = this.msgFilter + ':&nbsp;';
			html[html.length] = '<input id="'+this.makeId('filter')+'" type="text" size="8" onchange="zenPage.getComponent('+this.index+').onfilterHandler(this.value);" title="' + this.title + '"/>&nbsp;';
			html[html.length] = '</span>';
		}

		if (this.showPageSize) {
			html[html.length] = '<span class="tnbrFilter">';
			html[html.length] = this.msgPageSize + ':&nbsp;';
			html[html.length] = '<input id="'+this.makeId('pgsize')+'" type="text" size="4" onchange="zenPage.getComponent('+this.index+').onpageSizeHandler(this);" value="'+pageSize+'"/>&nbsp;';
			html[html.length] = '</span>';
		}
		
		if (this.showMaxRows) {
			html[html.length] = '<span class="tnbrFilter">';
			html[html.length] = this.msgMaxRows + ':&nbsp;';
			html[html.length] = '<input id="'+this.makeId('maxrows')+'" type="text" size="4" onchange="zenPage.getComponent('+this.index+').onmaxRowsHandler(this);" value="'+maxRows+'"/>&nbsp;';
			html[html.length] = '</span>';
		}

		html[html.length] = '<span class="tnbrFound">';
		html[html.length] = this.msgFound + ':&nbsp;<span id="'+this.makeId('rowCount')+'">' + rowCount;
		html[html.length] = '</span></span>&nbsp;';

		html[html.length] = '<span id="'+this.makeId('tnbrPagingSpan')+'">';
		html[html.length] = this.renderButtons();
		html[html.length] = '</span>';
		
	}

	html[html.length] = '</td>';
	html[html.length] = '<td align="right" width="5%">&nbsp;</td></tr></table>';

	// render
	this.getEnclosingDiv().innerHTML = html.join('');
}

/// Render HTML for paging buttons.
ClientMethod renderButtons() [ Language = javascript ]
{
	if (this.getEnclosingDiv() == null) { return ''; }
	var table = this.tablePane;
	if (null == table) { return ''; }

	// get stats from table
	var pageNo = table.getProperty('currPage');
	var pageCount = table.getPageCount();

	var html = new Array();
	html[html.length] = '<span class="tnbrPagingButtons">';
	html[html.length] = '&nbsp;' + this.msgPage + ':&nbsp;';

	if (pageNo > 1) {
		html[html.length] = '<a title="'+this.msgFirstPage+'" class="tnbrPageLink" style="cursor:pointer;" onmousedown="zenPage.getComponent(' + this.index + ').gotoPage(\'first\');"><b>|&#8249;</b></a>';
		html[html.length] = '<a title="'+this.msgPreviousPage+'" class="tnbrPageLink" style="cursor:pointer" onmousedown="zenPage.getComponent(' + this.index + ').gotoPage(\'prev\');"><b>&#8249;&#8249;</b></a>';
	}
	else {
		html[html.length] = '<a class="tnbrPageLinkDisabled"><b>|&#8249;</b></a>';
		html[html.length] = '<a class="tnbrPageLinkDisabled"><b>&#8249;&#8249;</b></a>';
	}

	// create set of page buttons
	var maxButtons = parseInt(this.maxButtons,10);
	maxButtons = (maxButtons < 1) ? 1 : maxButtons;
	var startPage = ((Math.floor((pageNo-1)/maxButtons)) * maxButtons) + 1;
	var endPage = startPage + (maxButtons - 1);
	endPage = (endPage>pageCount) ? pageCount : endPage;

	for (var p = startPage; p <= endPage; p++) {
		var cls = (p==pageNo) ? 'tnbrPageLinkCurr' : 'tnbrPageLink';
		html[html.length] = '<a class="'+cls+'" style="cursor:pointer;" onmousedown="return zenPage.getComponent(' + this.index + ').gotoPage('+p+');">'+p+'</a>';
	}

	if (pageNo < pageCount) {
		html[html.length] = '<a title="'+this.msgNextPage+'" class="tnbrPageLink" style="cursor:pointer;" onmousedown="zenPage.getComponent(' + this.index + ').gotoPage(\'next\');"><b>&#8250;&#8250;</b></a>';
		html[html.length] = '<a title="'+this.msgLastPage+'" class="tnbrPageLink" style="cursor:pointer;" onmousedown="zenPage.getComponent(' + this.index + ').gotoPage(\'last\');"><b>&#8250;|</b></a>';
	}
	else {
		html[html.length] = '<a class="tnbrPageLinkDisabled"><b>&#8250;&#8250;</b></a>';
		html[html.length] = '<a class="tnbrPageLinkDisabled"><b>&#8250;|</b></a>';
	}

	html[html.length] = this.msgOf + '&nbsp;' + pageCount + '&nbsp;';
	return html.join('');
}

/// This method is called from the associated tablePane when
/// it changes state. The navigator responds by updating the
/// state of its controls.
ClientMethod updateState() [ Language = javascript ]
{
	var span = this.findElement('tnbrPagingSpan');
	if (span) {
		// update buttons
		span.innerHTML = this.renderButtons();
		// update controls
		if (this.tablePane) {
			var ctrl = this.findElement('pgsize');
			if (ctrl) {
				ctrl.value = this.tablePane.getProperty('pageSize');
			}
			var sp = this.findElement('rowCount');
			if (sp) {
				sp.innerHTML = this.tablePane.getProperty('rowCount');
			}
		}
	}
	else {
		// draw everything
		this.renderContents();
	}
}

/// Event handler for filter box.
/// This method is called when the value of the filter box changes.
ClientMethod onfilterHandler(value) [ Language = javascript ]
{
	// invoke user callback
	zenInvokeCallbackMethod(this.onfilterChange,this,'onfilterChange','value',value);
}

/// Event handler for page size box.
/// This method is called when the value of the page size box changes.
ClientMethod onpageSizeHandler(ctrl) [ Language = javascript ]
{
	// normalize value in control
	var size = parseInt(ctrl.value,10);
	size = isNaN(size) ? 0 : size;
	size = (size < 0) ? 0 : size;
	size = (size > this.maxPageSize) ? this.maxPageSize : size; 
	ctrl.value = size;
	ctrl.focus();

	if (null == this.tablePane) return;
	this.tablePane.setProperty('pageSize',size);
	if (this.saveSizeMax) {
		zenInvokeCallbackMethod(this.onPageSizeChange,this,'onPageSizeChange','value',size);
	}
}

/// Event handler for maxRows box.
/// This method is called when the value of the maxRows box changes.
ClientMethod onmaxRowsHandler(ctrl) [ Language = javascript ]
{
	// normalize value in control
	var size = parseInt(ctrl.value,10);
	size = isNaN(size) ? this.maxRows : size;
	size = (size < 0) ? this.maxRows : size;
	size = (size > this.navmaxRows) ? this.navmaxRows : size; 
	ctrl.value = size;
	ctrl.focus();

	if (null == this.tablePane) return;
	this.tablePane.setProperty('maxRows',size);
	this.tablePane.executeQuery();
	if (this.saveSizeMax) {
		zenInvokeCallbackMethod(this.onMaxRowsChange,this,'onMaxRowsChange','value',size);
	}
}

/// Move to the specified page in the associated tablePane.
/// where can be 'first','last','next','prev' or a page number.
ClientMethod gotoPage(where) [ Language = javascript ]
{
	if (null == this.tablePane) return;

	// dispatch to tablePane
	switch(where) {
	case 'first':
		this.tablePane.firstPage();
		break;
	case 'last':
		this.tablePane.lastPage();
		break;
	case 'next':
		this.tablePane.nextPage();
		break;
	case 'prev':
		this.tablePane.previousPage();
		break;
	default:
		var page = parseInt(where,10);
		if (!isNaN(page)) {
			this.tablePane.gotoPage(page);
		}
		break;
	}
	
	return true;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'tablePaneId':
		if (this.tablePane && this.tablePane.removeNavigator) {
			this.tablePane.removeNavigator();
			this.tablePane = null;
		}
		this.tablePaneId = value;
		if (this.composite) {
			this.tablePane = this.composite.getChildById(this.tablePaneId);
		}
		else {
			this.tablePane = zenPage.getComponentById(this.tablePaneId);
		}
		if (this.tablePane && this.tablePane.addNavigator) {
			this.tablePane.addNavigator(this);
		}
		this.updateState();
		break;

	case 'maxButtons':
		this.maxButtons = parseInt(value,10);
		this.render();
		break;

	case 'showFilter':
		this.showFilter = value ? true : false;
		this.render();
		break;

	case 'maxPageSize':
		this.maxPageSize = parseInt(value,10);
		break;

	case 'maxRows':
		this.maxRows = parseInt(value,10);
		break;

	case 'navmaxRows':
		this.navmaxRows = parseInt(value,10);
		break;

	default:
		this.invokeSuper('setProperty',arguments);
		break;
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.connect();
}

/// Connect to table pane.
ClientMethod connect() [ Language = javascript ]
{
	// set up association with tablePane
	this.setProperty('tablePaneId',this.tablePaneId);
	if (this.showMaxRows) {
		if (null == this.tablePane) return;
		this.maxRows = this.tablePane.getProperty("maxRows");
	}
}

}
