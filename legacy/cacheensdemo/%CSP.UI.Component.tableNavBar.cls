/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a tableNavigatorBar component used by SMP.
Class %CSP.UI.Component.tableNavBar Extends %ZEN.Component.tableNavigatorBar [ System = 3 ]
{

Parameter SYSMODULE;

/// This Style block contains component-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// Client-side method to render this control.
/// The difference between this component and tableNavigatorBar is the filter. <br/>
/// In combination with %CSP.UI.Portal.UtilsNav, we use table.lastFilter to set the last filter value of the user here.
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
			this.connect();
			table = this.tablePane;
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
		var filter = table.getProperty('lastFilter');
		
		if (this.showFilter) {
			html[html.length] = '<span class="tnbrFilter">';
			html[html.length] = this.msgFilter + ':&nbsp;';
			html[html.length] = '<input id="'+this.makeId('filter')+'" type="text" size="8" onchange="zenPage.getComponent('+this.index+').onfilterHandler(this.value);" title="' + this.title + '" value="'+filter+'"/>&nbsp;';
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

/// allow someone to reset the filter input.size for this component
ClientMethod setFilterSize(size) [ Language = javascript ]
{
	this.findElement('filter').size = size;
}

}
