/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

///  This component draws an HTML table based on the contents
///  of a query. This can either be a pre-built class query or
///  an SQL statement.<br>
///  The is a base class that provides the underlying mechanisms
///  used by more complex table panes.
Class %ZEN.Component.simpleTablePane Extends (component, querySource) [ Abstract, Deprecated, Inheritance = right, System = 3 ]
{

Parameter SYSMODULE = "table";

///  If true and multiSelect is false, then clicking on the selected row un-selects it.
Property enableToggleSelect As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

///  If true, then row numbers are displayed.
Property showRowNumbers As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

///  If true, then a column indicating the selected row is displayed.
Property showRowSelector As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

///  If true, then display rows using alternating colors.
Property showZebra As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

///  If true, then the user can select a row within the table.
Property rowSelect As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

///  If true, then the user can select multiple rows within the table.
///  An extra column, containing checkboxes, will be displayed to
///  indicate which rows are selected.
Property multiSelect As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

///  If true (the default) then the query associated with this tablePane
///  will be executed when the table is first displayed. Otherwise the
///  tablePane will execute the query on demand.
Property initialExecute As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

///  Index (row number) of current selected row (0 based).
Property selectedIndex As %ZEN.Datatype.integer [ InitialExpression = -1 ];

///  For multi-select tables, this is the set of which rows are
///  selected.<br>
///  The value of this property is a csv-list of values
///  corresponding to which row is selected.<br>
///  For selected items the list contains the current user-defined logical value 
///  for the row (as specified by the <property>valueColumn</property>).<br>
///  For unselected items the list contains an empty string.
Property selectedRows As %ZEN.Datatype.string(XMLPROJECTION = "none");

///  Logical value of current selected row within the table.
///  Do not access this directly; use getProperty('value') instead.
Property value As %ZEN.Datatype.string(ZENEXPRESSION = 1);

///  onselectrow event handler:
///  This event is fired when a new row is selected.
///  This event is passed a variable, <var>which</var>, which indicates
///  how the row was selected: "", "click" or "keypress".
Property onselectrow As %ZEN.Datatype.eventHandler;

///  onunselectrow event handler:
///  This event is fired when the currently selected row is unselected.
Property onunselectrow As %ZEN.Datatype.eventHandler;

///  onmultiselect event handler:
///  This event is fired the user changes the set of multiply-selected rows.
Property onmultiselect As %ZEN.Datatype.eventHandler;

///  ondblclick event handler:
///  This event is fired when a row is double-clicked.
Property ondblclick As %ZEN.Datatype.eventHandler;

///  Internal property used to track focus.
Property hasFocus As %ZEN.Datatype.boolean(XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

///  Class to be appended to the class name of the row when the user moves 
///  his/her mouse over the row.
Property onmouseoverClass As %ZEN.Datatype.cssClass;

///  defines style sheet used by this component
XData Style
{
<style type="text/css">

/* @doc="Main table for tablePane" */
table.tpTable {
	background: white;
	border: 1px solid black;
	font-family: arial;
	width: 100%;
	table-layout: fixed;
	empty-cells: show;
}

/* @doc="Caption above table."*/
table.tpTable caption { 
	font-weight: bold;
	text-align: left;
	padding: 2px;
	border: 1px solid black;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

/* @doc="Column header." */
table.tpTable th {
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	color: black;
	font-weight: bold;
	text-align: left;
	padding: 2px;
	overflow: hidden;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

/* @doc="Default height for rows in the body: */
.ie11 table.tpTable tbody tr {
	height:1em;
}

/* @doc="Selected column header." */
table.tpTable th.tpHdrSelected {
	color: white;
	background: #F0F0F0;
	background-image: url(images/grad-gray2-10x100.png);
	background-repeat: repeat-x;
}

table.tpTable td {
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
	padding: 2px;
	overflow: hidden;
	/*text-overflow: ellipsis;*/
}

table.tpTable tr.tpSelected td {
	border-top: 1px solid black;
	border-bottom: 2px solid black;
	padding-top: 1px;
	padding-bottom: 1px;
}

/* @doc="Selected row within table." */
table.tpTable tr.tpSelected {
	color: black;
	background: #404040;
	background-image: url(images/grad-yellow-10x100.png);
	background-repeat: repeat-x;
}

/* @doc="Style used for table body outside of cells within the table." */
.tpBody {
	background: #DDDDDD;
}

/* @doc="Style used for table body outside of cells within the table when using fixed headers." */
.tpBodyFixed {
	background: #DDDDDD;
	overflow-x:hidden;
	overflow-y:auto;
}
 
/* @doc="Style for rows when not using zebra styling." */
.tpRow {
	color: darkblue;
	background: white;
}

/* @doc="Style for odd-rows when using zebra styling." */
.tpOdd {
	color: darkblue;
	background: white;
}

/* @doc="Style for even-rows when using zebra styling." */
.tpEven {
	color: darkblue;
	background: #DDDDFF;
}

/* @doc="Cell containing a string value." */
.tpStr {

}

/* @doc="Cell containing numeric value." */
.tpNum {
	text-align: right;
}

/* @doc="Cell containing the current row selector." */
.tpSel {
	text-align: center;
	font-weight: bold;
}

/* @doc="Cell containing the row number." */
.tpRNum {
	text-align: right;
}

/* @doc="Cell containing a link." */
.tpAction {
}

.tpAction a {	
	color: darkblue;
}

.tpAction a:hover {
	color: darkblue;
}

.tpAction a:link {
	color: darkblue;
}

.tpAction a:active {
	color: darkblue;
}

/* @doc="Cell displaying No Results message." */
table td.tpNoResults {
	font-style: italic;
	color: #202060;
	background: white;
}

/* @doc="Extra padding cell at bottom of table." */
table td.tpPadRow {
	background: white;
}

/* @doc="Table containing filter controls." */
table.tpFilterLayout {
	border: none;
}

/* @doc="Cell within table containing filter controls." */
table.tpFilterLayout td {
	border: none;
	background: none;
}

/* @doc="Filter control." */
.tpFilter {
	/*width: 100%;*/
	font-size: 0.8em;
}

/* @doc="Filter control for date values." */
.tpFilterDate {
	font-size: 0.8em;
}

/* @doc="Filter control with focus." */
.tpFilter:focus {
	background: #FFFFE0;
}

/* @doc="Label for filter control." */
.tpFilterLabel {
	font-size: 0.6em;
	font-weight: normal;
	text-align: right;
}

/* @doc="Button in filter section." */
.tpFilterButton {
	vertical-align: middle;
	border: 1px solid black;
	font-size: 0.6em;
}

.tpFilterButton:hover {
	background: #FFFF80;
}

</style>
}

///  Draw innerHTML for this component (without enclosing div).
Method %DrawHTML()
{
	#; create result set
	#; create QueryInfo object to hold query info
	Set tInfo = ##class(%ZEN.Auxiliary.QueryInfo).%New()
	Set tRS = ..%CreateResultSet(.tSC,tInfo,..initialExecute)
	Set ..initialExecute = 1
	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,tSC)
		Quit
	}
	Set tSC = ..%DrawTable(tRS)

	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML(##this,tSC)
		Quit
	}

	Set tRS = ""
}

///  Draw the table.
Method %DrawTable(pRS As %ResultSet) As %Status
{
	Set tSC = $$$OK

	&html<<table class="tpTable" border="0" cellspacing="0" cellpadding="0">>
	&html<<tr>>
	If (..showRowSelector) {
		&html<<th>&nbsp;&nbsp;&nbsp;</th>>
	}
	If (..showRowNumbers) {
		&html<<th>#</th>>
	}

	if pRS.%IsA("%Library.ResultSet") {
		Set tCols = pRS.GetColumnCount()
		For c = 1:1:tCols { &html<<th>&nbsp;#($ZCVT(pRS.GetColumnHeader(c),"O","HTML"))#&nbsp;</th>> }
	}
	else {
		Set tCols = pRS.%ResultColumnCount
		For c = 1:1:tCols { &html<<th>&nbsp;#($ZCVT(pRS.%Metadata.columns.GetAt(c).label,"O","HTML"))#&nbsp;</th>> }
	}
	&html<</tr>>

	// fetch
	Set tRow = 0
	While (pRS.%Next(.tSC) && ((..maxRows = 0) || (tRow < ..maxRows))) {
		Quit:$$$ISERR(tSC)
		Set tRow = tRow + 1

		Set tStatus = ""

		If (..showZebra) {
			Set tStatus = $S(tRow#2=0:"tpEven",1:"tpOdd")
		}

		If (tStatus '= "") {
			Set tRowCls = "class="""_tStatus_""""
		}
		Else {
			Set tRowCls = ""
		}
		
		// check onmouseover/onmouseout behaviour
		If (..onmouseoverClass '= "") {
			Set tMouseover = "onmouseover=""zenPage.getComponent('"_..index_"').onmouseHandler('"_(tRow-1)_"',true);"" onmouseout=""zenPage.getComponent('"_..index_"').onmouseHandler('"_(tRow-1)_"',false);"""
		}
		Else {
			Set tMouseover = ""
		}

		&html<<tr #(tRowCls)# id="#(..%MakeId("tr_"_(tRow-1)))#" onclick="zenPage.getComponent(#(..index)#).selectRow(#(tRow-1)#,true,'click');" #(tMouseover)#>>
		If (..showRowSelector) {
			&html<<td id="#(..%MakeId("selector_"_(tRow-1)))#">&nbsp;</td>>
		}
		If (..showRowNumbers) {
			&html<<td align="right">#(tRow)#</td>>
		}

		For c = 1:1:tCols {
			&html<<td>&nbsp;#($ZCVT(pRS.%GetData(c),"O","HTML"))#</td>>
		}
		&html<</tr>>
	}
	&html<</table>>

	Quit tSC
}

///  For multi-select table, test if a given row (0-based)
///  is selected.
ClientMethod isRowSelected(row) [ Language = javascript ]
{
	// convert local row # to set of all rows
	var idx = row;
	if (!isNaN(this.pageSize)) {
		idx = row + ((this.currPage-1) * this.pageSize);
	}
	var list = this.selectedRows.split(',');
	return (list[idx]!=null && list[idx]!='');
}

///  For multi-select tables, select or unselect the given row (0-based)
///  depending on the value of <var>flag</var>.
///  Updates the corresponding checkbox.
ClientMethod selectMultiRow(row, flag) [ Language = javascript ]
{
	// convert local row # to set of all rows
	var idx = row;
	if (!isNaN(this.pageSize)) {
		idx = row + ((this.currPage-1) * this.pageSize);
	}

	// find checkbox in this page (skip rows that do not have checkbox built)
	var rcb = this.findElement('cb_'+row);
	if (rcb) {
		rcb.checked = flag;
		// try to find logical value of selected row
		// if the given row is not available on the client, do not select.
		var val = '';
		var tr = this.findElement("tr_" + row);
		if (tr) {
			val = tr.getAttribute('zenValue');
		}

		var list = this.selectedRows.split(',');
		list[idx] = flag ? val : '';
		this.selectedRows = list.join(',');

	}
}

///  For multi-select tables, mark all (visible) rows as 
///  selected or unselected depending on the value of <var>flag</var>.
ClientMethod selectAllMultiRows(flag) [ Language = javascript ]
{
	var rowCount = ('' == this.pageSize || 0 == this.pageSize) ? parseInt(this.rowCount.split(' ')[0]) : this.pageSize;
	for (var row = 0; row < rowCount; row++) {
		this.selectMultiRow(row, flag);
	}
}

///  Internal method.
///  Update the selectedRows checkboxes to match the value
///  in the selectedRows property.
ClientMethod updateRowSelectBoxes() [ Internal, Language = javascript ]
{
	// break apart list of selections
	var list = this.selectedRows.split(',');

	// loop over set of (visible) checkboxes
	var rowCount = (this.pageSize > this.rowCount) ? this.pageSize : this.rowCount;
	
	for (var row = 0; row < rowCount; row++) {
		var idx = row + ((this.currPage-1) * this.pageSize);
		var sel = (list[idx]!=null && list[idx]!='') ? true : false;
		var rcb = this.findElement('cb_'+row);
		if (rcb) {
			rcb.checked = sel;
		}
	}
}

///  Click handler for header checkbox for multi-select table.
ClientMethod cbHeaderClick(cb) [ Internal, Language = javascript ]
{
	// set/reset all row select checkboxes
	this.selectAllMultiRows(cb.checked);

	zenInvokeCallbackMethod(this.onmultiselect,this,'onmultiselect');
}

///  Click handler for multi-select checkbox.
ClientMethod cbClick(cb, row) [ Internal, Language = javascript ]
{
	this.ignoreClick = true; // transient flag
	this.selectMultiRow(row,cb.checked);

	zenInvokeCallbackMethod(this.onmultiselect,this,'onmultiselect');
}

///  Handler for clicks within a row.
ClientMethod clickHandler(row) [ Internal, Language = javascript ]
{
	this.selectRow(row,false,'click');
	this.focus();
}

///  Handler for double-clicks within a row.
ClientMethod dblclickHandler() [ Internal, Language = javascript ]
{
	// invoke callback, if present
	zenInvokeCallbackMethod(this.ondblclick,this,'ondblclick');
}

///  Client-side method to select the given row (0-based) in the table.
///  If <var>scroll</var> is true, scroll the new row into view.
///  If <var>which</var> is present, it is passed along to the user event notification.
ClientMethod selectRow(row, scroll, which) [ Language = javascript ]
{
	if (!this.rowSelect) {
		if (this.multiSelect && !this.ignoreClick) {
			// multi-select only; toggle multiselect for row
			this.selectMultiRow(row,!this.isRowSelected(row));
			zenInvokeCallbackMethod(this.onmultiselect,this,'onmultiselect');
		}
		// do nothing more
		this.ignoreClick = false;
		return;
	}

	this.ignoreClick = false;

	var changed = (row != this.selectedIndex);
	// unhighlight current selected
	if ((this.selectedIndex >= 0)&&(changed || this.enableToggleSelect)) {
		var tr = this.findElement("tr_" + this.selectedIndex);
		if (tr) {
			tr.className = this.trClass ? this.trClass : '';
		}

		// selector
		var selector = this.findElement("selector_" + this.selectedIndex);
		if (selector) {
			selector.innerHTML="&nbsp;";
		}
		// invoke callback, if present
		which = ('undefined' == typeof which) ? '' : which;
		zenInvokeCallbackMethod(this.onunselectrow,this,'onunselectrow','which',which);
		this.selectedIndex = -1;
		this.value = ""; // PFD, 2013/02/04 - Clear the value property
		if (!changed) return;
	}
	
	this.selectedIndex = row;
	if (changed || this.enableToggleSelect) {
		this.value = '';

		// update new selection
		if (this.selectedIndex >= 0) {
			var tr = this.findElement("tr_" + this.selectedIndex);
			if (tr) {
				// stash current background
				if (this._rowClassIndex && (this._rowClassIndex[row] != null)) {
					this.trClass = this._rowClassIndex[row];
					delete this._rowClassIndex[row];
				}
				else {
					this.trClass = tr.className;
				}
				tr.className = 'tpSelected';	

				if (scroll) {
					zenScrollIntoView(this.findElement('tpBody'),tr);
				}

				// get logical value of row
				this.value = tr.getAttribute('zenValue');
			}

			// selector
			var selector = this.findElement("selector_" + this.selectedIndex);
			if (selector) {
				selector.innerHTML="&raquo;";
			}
		}

		// invoke callback, if present
		if (this.enableToggleSelect || changed) {
			which = ('undefined' == typeof which) ? '' : which;
			zenInvokeCallbackMethod(this.onselectrow,this,'onselectrow','which',which);
		}
	}
	else if (this.onmouseoverClass && (this.onmouseoverClass != '')) {
		if (!this._rowClassIndex) {
			this._rowClassIndex =  new Object();
		}
		// remember this row's style for when we mouse out
		var thisClass = '';
		if (tr && tr.className) {
			thisClass = tr.className;
		}
		this._rowClassIndex[row] = thisClass;
	}
}

///  Internal method.<br>
///  Applications should use the <method>executeQuery</method> of the
///  <class>tablePane</class> class.<br>
///  Call to the server and update the contents of the tablePane.
///  This is a wrapper around the <method>refreshContents</method> method.
ClientMethod refreshTable(sync) [ Internal, Language = javascript ]
{
	// do not refresh if we are already refreshing
	if (null == this.progressBarTimerId) {
		this.refreshContents(sync);
	
		// display progress bar, if needed
		this.startProgressBar();
	}
}

///  Called after refreshContents-- make sure row is selected.
ClientMethod onRefreshContents() [ Internal, Language = javascript ]
{
	this.stopProgressBar();

	// THIS WORKAROUND SHOULD NOT BE NEEDED ANY LONGER
	// THE RELATED RENDERING BUG HAS BEEN FIXED BY MOZILLA
	//if (this.showZebra) { //PL 66143
	//	var tBody = this.window.document.getElementById("tpBody_"+this.index);
	//    if (tBody) tBody.style.backgroundColor="transparent";
	// }
	
	if (!this.rowSelect) {
		var idx = this.selectedIndex;
		this.selectedIndex = -1; // force change
		this.selectRow(idx,false);
	}
	else {
		this.selectedIndex = -1;
	}

	// notify navigator, if present
	if (this.navigator && this.navigator.updateState) {
		this.navigator.updateState();
	}

	if (this.hasFocus) {
		// defer grant of focus
		self.setTimeout("zenPage.getComponent("+this.index+").focus()",50);
	}
}

///  This is called whenever we are updated from the server.
ClientMethod onupdateHandler() [ Internal, Language = javascript ]
{
	if (this.showZebra) { // PL66143
		var tBody = this.window.document.getElementById("tpBody_"+this.index);
	    if (tBody) tBody.style.backgroundColor="transparent";
	}

	// test for refresh request
	if (this.refreshRequired && this.executeQuery) {
		this.refreshRequired = false;
		this.executeQuery(true);
		return;
	}

	// notify navigator, if present
	if (this.navigator && this.navigator.updateState) {
		this.navigator.updateState();
	}
}

///  Set the value of a named property.<br>
///  Assume that subclasses that simply wrap HTML controls
///  have named the control 'control' or else have overridden
///  this method.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'enableToggleSelect':
		value = value ? true : false;
		if (value != this.enableToggleSelect) {
			this.enableToggleSelect = value;
			this.refreshTable();
		}
		break;
	case 'rowSelect':
		value = value ? true : false;
		if (value != this.rowSelect) {
			this.rowSelect = value;
			this.refreshTable();
		}
		break;
	case 'multiSelect':
		value = value ? true : false;
		if (value != this.multiSelect) {
			this.multiSelect = value;
			this.refreshTable();
		}
		break;
	case 'selectedRows':
		if (value != this.selectedRows) {
			this.selectedRows = value;
			if (this.multiSelect) {
				this.updateRowSelectBoxes();
			}
		}
		break;
	case 'selectedIndex':
		// use false flag to keep table from *jumping* to new row
		this.selectRow(value,false);
		break;
	case 'showRowNumbers':
		value = value ? true : false;
		if (value != this.showRowNumbers) {
			this.showRowNumbers = value;
			this.refreshTable();
		}
		break;
	case 'showRowSelector':
		value = value ? true : false;
		if (value != this.showRowSelector) {
			this.showRowSelector = value;
			this.refreshTable();
		}
		break;
	case 'showZebra':
		value = value ? true : false;
		if (value != this.showZebra) {
			this.showZebra = value;
			this.refreshTable();
		}
		break;
	case 'initialExecute':
		this.initialExecute = value ? true : false;
		break;
	case 'value': // readonly
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

///  Client-side method to input focus to this control.
///  Implemented by subclasses.
ClientMethod focus() [ Language = javascript ]
{
}

///  Client-side method to return the logical value associated with this table.
ClientMethod getValue() As %String [ Final, Language = javascript ]
{
	return this.getProperty('value');
}

///  Handler for onmouseover and onmouseout events for a given row.
///  The handler only takes action if <property>onmouseoverClass</property>
///  is specified, and adds the value of this property to the current value for the
///  row's class.
ClientMethod onmouseHandler(row, over) [ Language = javascript ]
{
	if (this.onmouseoverClass == '') {
		return;
	}
	
	if (!this._rowClassIndex) {
		this._rowClassIndex = new Object();
	}
	
	var tr = this.findElement('tr_'+row);
	if (tr) {
		if (tr.className.indexOf('tpSelected') == -1) {
			if (over) {
				this._rowClassIndex[row] = tr.className;
				var otherClasses = '';
				var restrictedNames = ',' + (this.showZebra ? 'tpOdd,tpEven,' : '') + this.onmouseoverClass + ',';
				var test = tr.className.split(' ');
				for (var i = 0; i < test.length; i++) {
					if ((test[i] != '') && (restrictedNames.indexOf(','+test[i]+',') == -1)) {
						otherClasses = otherClasses + ' ' + test[i];
					}
				}
				tr.className = this.onmouseoverClass + otherClasses;
			}
			else {
				if ((this._rowClassIndex[row] != '') && (this._rowClassIndex[row] != null)) {
					tr.className = this._rowClassIndex[row];
					delete this._rowClassIndex[row];
				}
				else if (this.showZebra) {
					if (tr.className.indexOf('tpOdd') > -1) {
						tr.className = 'tpOdd';
					}
					else if (tr.className.indexOf('tpEven') > -1) {
						tr.className = 'tpEven';
					}
					else {
						tr.className = '';
					}
				}
				else {
					tr.className = '';
				}
			}
		}
		else if (typeof tr.className == 'string') {
			var classes = tr.className.split(' ');
			var newClasses = [];
			while (classes.length > 0) {
				var currClass = classes.shift();
				if ((currClass != '') && (currClass != 'tpSelected')) {
					newClasses[newClasses.length] = currClass;
				}
			}
			var newClass = newClasses.join(' ');
			if (newClass != '') {
				this._rowClassIndex[row] = newClass;
			}
			else {
				delete this._rowClassIndex[row];
			}
		}
	}
}

}
