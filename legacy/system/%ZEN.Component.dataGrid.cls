/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Implements a component for viewing and editing tabular data.<br/>
/// This is an HTML5 component; it will only correctly run on HTML5 compliant browsers.
Class %ZEN.Component.dataGrid Extends (control, dataView) [ Deprecated, System = 3 ]
{

/// Pick up formula code.
Parameter INCLUDEFILES = "dsparser.js";

/// Do not include in "form" module.
Parameter SYSMODULE;

Parameter DEFAULTENCLOSINGCLASS As STRING = "dataGrid";

/// Domain used for localization.
Parameter DOMAIN = "%ZEN";

/// Optional row descriptors for this grid.
Property rowDescriptors As list Of %ZEN.Auxiliary.gridRowDescriptor(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE", ZENSETTING = 0);

/// Optional column descriptors for this grid.
Property columnDescriptors As list Of %ZEN.Auxiliary.gridColumnDescriptor(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE", ZENSETTING = 0);

/// Optional descriptor for the summary row.
Property summaryRow As %ZEN.Auxiliary.gridRowDescriptor(XMLNAME = "summaryRow", ZENSETTING = 0);

/// For sortable tables, this is the column used for sorting results (1-based).
Property sortColumn As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// For sortable tables, this is the order to sort values within the
/// current column. Values can be "", "asc" (ascending), or "desc" (descending).
Property sortOrder As %ZEN.Datatype.string(VALUELIST = ",asc,desc");

/// Indicates where column-wise sorting should occur.
/// This can be "client" or "server".
Property sortMode As %ZEN.Datatype.string(VALUELIST = ",client,server") [ InitialExpression = "client" ];

/// Indicates where data paging should occur.
Property pagingMode As %ZEN.Datatype.string(VALUELIST = ",client,server") [ InitialExpression = "client" ];

/// If true, display a check box in each row to allow selection of the row.
Property showRowSelector As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, the user can resize columnns with the mouse.
Property canResizeColumns As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// This property contains a csv-list of the row numbers (1-based) in which the row selector checkbox is
/// currently set.<br/>
/// If all rows are checked, it is set to "all".
Property checkedRows As %ZEN.Datatype.csv;

/// Optional title to display along top of grid.
Property gridTitle As %ZEN.Datatype.caption;

/// Optional style to apply to grid title.
Property gridTitleStyle As %ZEN.Datatype.style;

/// Optional style to apply to grid status area.
Property gridStatusStyle As %ZEN.Datatype.style;

/// Specifies whether column labels should be displayed.
Property showColumnLabels As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Width used for row labels. This is a number of pixels.
/// If not defined, then a width is calculated.
Property rowLabelWidth As %ZEN.Datatype.integer;

/// This is the default width (in pixels) used for columns that do not supply a width.
/// If not defined, then a width is calculated.
Property columnWidth As %ZEN.Datatype.integer;

/// This is the default height (in pixels) used for rows that do not supply a height.
/// If not defined, then the height is calculated.
Property rowHeight As %ZEN.Datatype.integer;

/// Specifies whether row labels should be displayed.
Property showRowLabels As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// This specifies how parent row labels with multiple child labels are displayed.<br/>
/// If true, then one parent label is displayed for each set of children.
/// If false, then the parent row label is repeated for each child.
Property rowLabelSpan As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// This specifies how parent column labels with multiple child labels are displayed.<br/>
/// If true, then one parent label is displayed for each set of children.
/// If false, then the parent row label is repeated for each child.
Property columnLabelSpan As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// onheaderclick event handler:
/// If defined, this event is fired when
/// the user clicks on a row or column header.
/// The variable <var>which</var> will indicate which header is clicked: "row" or "column".
/// The variable <var>index</var> will indicate the ordinal number of the header (1-based).
Property onheaderclick As %ZEN.Datatype.eventHandler;

/// This is the row number (1-based) of the current selected cell.
Property currRow As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// This is the column number (1-based) of the current selected cell.
Property currColumn As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// This is the current "page" when this grid is paging through data.
/// Use the <method>getCurrPage</method> method to view this.
Property currPage As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// This is the current "page" size when this grid is paging through data.
/// Use the <method>getPageSize</method> method to view this.
Property pageSize As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// This specifies the current selected range of cells as a
/// comma-separated list of integers. The list is of the form:<br/>
/// startRow,startCol,endRow,endCol<br/>
/// All cells numbers are 1-based.<br/>
/// If the range is equal to "", then no cells are selected.<br/>
/// This is only used if <property>multiSelect</property> is true.
Property selectedRange As %ZEN.Datatype.csv;

/// This is the column number (1-based) of the column that supplies the
/// value for a row within the table.
Property valueColumn As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// Specifies how selection works within the grid.<br/>
/// If "rows", then the user selects entire rows at a time.<br/>
/// If "cells", then the user can select and move between individual cells.<br/>
Property selectMode As %ZEN.Datatype.string(VALUELIST = ",rows,cells") [ InitialExpression = "rows" ];

/// If supplied, this is a key used to filter results that are already on the client.
Property filterKey As %ZEN.Datatype.string;

/// If true, users can select a range of cells in the grid.
Property multiSelect As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, this grid will display formula values when a cell is edited. Otherwise
/// the current value of the cell is displayed.
Property hasFormulas As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Default format to apply to cells in this grid.<br/>
/// This is a DeepSee format string: e.g., "###.##"
/// This is overridden by row and column-level formatting.
Property format As %ZEN.Datatype.string;

/// Sometimes datagrid is *never* used to enter numbers only strings, for instance diagnostic codes with 0s trailing to the left or after a decimal point
Property alwaysString As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Additional style to apply to cells in this grid.<br/>
/// This is applied before any row and column-level styles.
Property style As %ZEN.Datatype.style;

/// Additional style to apply to column headers in this grid.<br/>
Property columnHeaderStyle As %ZEN.Datatype.style;

/// Additional style to apply to row headers in this grid.<br/>
Property rowHeaderStyle As %ZEN.Datatype.style;

/// Specify whether zebra striping should be applied to the grid.
Property showZebra As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Background color to apply to even rows when zebra striping is on.
Property evenRowBackground As %ZEN.Datatype.style [ InitialExpression = "#F8F8F8" ];

/// Foreground color to apply to even rows when zebra striping is on.
Property evenRowColor As %ZEN.Datatype.style;

/// Style to apply to odd rows when zebra striping is on.
/// Background color to apply to odd rows when zebra striping is on.
Property oddRowBackground As %ZEN.Datatype.style;

/// Foreground color to apply to odd rows when zebra striping is on.
Property oddRowColor As %ZEN.Datatype.style;

/// Background color of cells when mouse is over them.
Property cellHoverColor As %ZEN.Datatype.string [ InitialExpression = "#EEEEEE" ];

/// Background color to apply to the current cell.
Property currCellBackground As %ZEN.Datatype.style [ InitialExpression = "#D0D0FF" ];

/// Foreground color to apply to the current cell.
Property currCellColor As %ZEN.Datatype.style [ InitialExpression = "#000000" ];

/// ondrawcell event handler:
/// If defined, this event is fired when
/// a cell is about to be drawn.
/// The event is passed <var>value</var>, <var>row</var>, and <var>col</var> (1-based).
/// If this event handler returns a value, then it is used to render the cell contents.<br/>
/// The return of this event is either null, in which case the default rendering is used for the cell
/// or an object with any of the following properties:<br/>
/// <var>content</var> - HTML to display within the cell.<br/>
/// <var>align</var> - horizontal alignment for the cell.<br/>
/// <var>style</var> - CSS style for the cell.<br/>
/// <var>format</var> - format string for the cell (ignored if content is supplied).<br/>
/// <var>image</var> - image for the cell (ignored if content is supplied).<br/>
/// <var>type</var> - type for the cell (ignored if content is supplied).<br/>
/// <var>value</var> - value for the cell (ignored if content is supplied).<br/>
Property ondrawcell As %ZEN.Datatype.eventHandler;

/// onselectcell event handler:<br/>
/// If defined, this event is fired when the user navigates to a new cell.<br/>
/// The current cell row and column number is updated before this call is made.<br/>
/// The event handler is passed 2 variables, <var>row</var> and <var>col</var>, which
/// contain the row and column number of the current cell (1-based).
Property onselectcell As %ZEN.Datatype.eventHandler;

/// onselectrow event handler:<br/>
/// If defined, this event is fired when the user toggles any of the visible row 
/// selector checkboxes within the grid<br/>
/// The event handler is passed one variable, <var>range</var>, a string enumerating
/// the currently checked rows.  This range has two special values: "" indicating that 
/// no rows are currently checked, or the reserved value "all" indicating that all rows
/// have been checked.  Between these extremes, the range parameter will become a CSV string
/// listing the (1-based) indices of the currently checked rows.<br/>
/// As this event is linked to the toggling of the row selectors, it only fires if 
/// <var>showRowSelector</var> is true 
Property onselectrow As %ZEN.Datatype.eventHandler;

/// onchangecell event handler:<br/>
/// If defined, this event is fired when the user finished editing a cell value.<br/>
/// The current cell row and column number is updated before this call is made.<br/>
/// The event handler is passed <var>value</var> (the new cell value). It should return
/// the value to be placed into the cell or null to cancel the edit.
Property onchangecell As %ZEN.Datatype.eventHandler;

/// ongetfunctions event handler:<br/>
/// If defined, this event is fired when the formula engine for this component is initialized.<br/>
/// It should return a list of additional functions that can be evaluated by the formula engine.
Property ongetfunctions As %ZEN.Datatype.eventHandler [ Internal ];

/// onaction event handler:<br/>
/// If defined, this event is fired when the user executes an action within a cell
/// (such as clicking on a column-defined checkbox, button, or link.)<br/>
/// The current cell row and column number is updated before this call is made.<br/>
/// The event handler is passed 3 variables, <var>row</var>, <var>name</var>, and <var>value</var>, which
/// contain the row number of the current cell (1-based), the logical name of the column, and the current value of the
/// action control, if applicable.
Property onaction As %ZEN.Datatype.eventHandler;

/// ongetlookupdata event handler:<br/>
/// Return a javascript array of data to display within the popup for a lookup column.
/// This can be any array of object or literal values.
Property ongetlookupdata As %ZEN.Datatype.eventHandler;

/// ongettitle event handler:
/// If defined, this event returns the HTML that will be displayed within the
/// title area of this grid (top of grid). This supercedes the <property>gridTitle</property>
/// property if defined.
Property ongettitle As %ZEN.Datatype.eventHandler;

/// ongetstatus event handler:
/// If defined, this event returns the HTML that will be displayed within the
/// status area of this grid (bottom of grid).
Property ongetstatus As %ZEN.Datatype.eventHandler;

/// onfiltercell event handler:<br/>
/// If defined, this event is fired when the user enters a new filter key.<br/>
/// The event handler is passed an object, <var>info</var>, with the properties
/// row,col,value, and key. The event handler should return true if the row containing the
/// cell matches the filter or false otherwise.
Property onfiltercell As %ZEN.Datatype.eventHandler;

Property lblSearch As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Search")} ];

Property lblWorking As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Working")} ];

Property lblErrorRenderContents As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Error in renderContents.")} ];

Property lblErrorRenderSkeleton As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Error in renderSkeleton.")} ];

Property lblErrorRenderCells As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Error in renderCells.")} ];

Property lblErrorAdjustSizes As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Error in adjustSizes.")} ];

Property lblErrorSelectCell As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Error in selectCell.")} ];

/// Setting this to 0 will disable code execution when loading and rendering the grid
/// This is useful when you want to enter = and not a formula in a particular column. This is a grid wide setting
Property useEngine As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// defines style sheet used by this component.
XData Style
{
<style type="text/css">

.dataGrid {
	font-family: arial;
	font-size: 12px;
	color: #404040;
	border: 1px solid #D0D0D0;
	background: #F0F0F0;
	width: 620px;
	height: 500px;
	opacity: 0.0;

	-webkit-transition-property: opacity;
	-webkit-transition-duration: 0.25s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity;
	-moz-transition-duration: 0.25s;
	-moz-transition-timing-function: ease;

	background: #C0C0C0;
	overflow: hidden;

	-webkit-user-select: none;
	-khtml-user-select: none;
	-moz-user-select: none;
	-o-user-select: none;
	user-select: none;
}

/* wrapper within enclosing div */
.dgWrapper {
	position: relative;
}

/* layer underneath data grid */
.dgCellsUnder {
	position: absolute;
	overflow: hidden;
	background: white;
}

.dgDiv,
.dgDivCells,
.dgDivSummary,
.dgDivSummaryHeader,
.dgDivColumnHeader {
	position: absolute;
	overflow: hidden;
}

.dgDivColumnHeader {
	background: none;
	border-bottom: 1px solid #D0D0D0;
}

.dgDivSummary {
	font-weight: bold;
}

.dgNub {
	border-right: 1px solid #D0D0D0;
	border-bottom: 1px solid #D0D0D0;
	background: none;
	position: absolute;

	background: #C0C0C0;
	background-image: url(images/grad-halfgray-10x30.png);
	background-repeat: repeat-x;
}

.dgTitle, .dgStatus {
	background: none;
	position: absolute;
}

.dgTitle {
	border-bottom: 1px solid #D0D0D0;
}

div.dgHdr, div.dgHdrSelected {
	border-right: 1px solid #D0D0D0;
	border-bottom: 1px solid #D0D0D0;
	background: none;
	position: absolute;
	overflow: hidden;
	font-weight: bold;
	background: #C0C0C0;
	background-image: url(images/grad-halfgray-10x30.png);
	background-repeat: repeat-x;
}

div.dgHdr:hover, div.dgHdrSelected:hover {
	background: #E0E0E0;
}

div.dgHdrSelected {
	background: #D0D0FF;
}

.dgCellEditor {
	border:1px solid blue;
}

/* column header style */
div.dgHdrColInner {
	position: absolute;
	padding: 2px;
	padding-left: 3px;
	padding-right: 3px;
	bottom: 0px;
	white-space: nowrap;
}

/* row header style */
div.dgHdrRowInner {
	position: absolute;
	padding: 3px;
	padding-left: 3px;
	padding-right: 3px;
	min-width: 50px;
}

/* outer wrapper for individual cell */
.dgCell {
	border-right: 1px solid #D0D0D0;
	border-bottom: 1px solid #D0D0D0;
	position: absolute;
	overflow: hidden;
}

.dgCell,.dgHdr {
	-webkit-transition-property: background;
	-webkit-transition-duration: 0.25s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0.25s;
	-moz-transition-timing-function: ease;
}

.dgCell {
}

/* style for data cell */
.dgCellInner {
	position: absolute;
	padding: 2px;
	padding-left: 3px;
	padding-right: 3px;
	white-space: nowrap;
	overflow: hidden;
	min-width: 25px;
}

/* style for non-text cells */
.dgCellInnerImage {
	z-index: 10;
	position: absolute;
	padding: none;
	display: block;
	white-space: nowrap;
	overflow: hidden;
	min-width: 16px;
	min-height: 16px;
	font-size: 10px;
}

/* selector: indicates current row or cell */
.dgSelector {
	z-index: 1;
	position: absolute;
	border: 2px solid rgb(100,100,140);
	border-radius: 2px;
	width: 100px;
	height: 25px;
	background: none;
}

/* selector: indicates current row or cell */
.dgSelectorFocus {
	z-index: 1;
	position: absolute;
	border: 2px solid rgb(100,140,180);
	border-radius: 2px;
	width: 100px;
	height: 25px;
	background: none;
}

/* sizing handle for selector */
.dgSizeHandle {
	z-index: 3;
	position: absolute;
	border: 1px solid white;
	background: black;
	width: 4px;
	height: 4px;
	cursor: se-resize;
}

/* action icon within cell selector */
.dgAction {
	z-index: 2;
	position: absolute;
	border: 1px solid #808080;
	cursor: pointer;
	overflow: hidden;


	width:24px;
	height:24px;
	background-color: #D0D0F8;
	background-image: url('deepsee/zoom_24.png');
	background-repeat:no-repeat;
	background-position:center;
}

.dgAction:hover {
	background-color: #F0F0FF;
}

.dgVtScroll {
	z-index: 2;
	position: absolute;
	width: 20px;
	overflow-y: scroll;
	overflow-x: hidden;
}
.dgVtScrollInner {
	height: 100px;
	width: 15px;
}
.dgHzScroll {
	z-index: 2;
	position: absolute;
	height: auto;
	overflow-x: scroll;
	overflow-y: hidden;
}
.dgHzScrollInner {
	height: 0px;
	width: 100px;
}

/* column resize handle */
.dgResize {
	cursor: e-resize;
	z-index: 100;
	width: 4px;
	background: none;
	position: absolute;
}

.dgOverlay {
	position: absolute;
	z-index: 100;
	opacity: 0.0;
	-webkit-transition-property: opacity;
	-webkit-transition-duration: 0.2s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity;
	-moz-transition-duration: 0.2s;
	-moz-transition-timing-function: ease;
}

.dgMsg {
	background: white;
	width: 150px;
	padding: 10px;
	color: #404040;
	border: 1px solid #D0D0D0;
	box-shadow: 2px 2px 2px #808080;
	border-radius: 4px;
}

.dgWaitBox {
	background: #F8F8FF;
	width: 150px;
	padding: 5px;
	color: #404040;
	font-size: 10px;
	border: 1px solid #D0D0D0;
	box-shadow: 2px 2px 2px #808080;
	border-radius: 4px;
}

.dgPageDiv {
	height: 20px;
	font-size: 10px;
	color: #606060;
	position: relative;
	-webkit-user-select: none;
	-khtml-user-select: none;
	-moz-user-select: none;
	-o-user-select: none;
	user-select: none;
}

.dgPageButton,
.dgPageButtonDis,
.dgPageButtonCurr {
	font-family: arial;
	border: 1px solid rgb(200,200,200);/*fallback*/
	border: 1px solid rgba(200,200,200,0.6);
	border-radius: 2px;
	position: absolute;
	padding: 0px;
	top: 0px;
	height: 14px;
	font-size: 8px;
	text-align: center;
	background: rgb(200,200,200);/*fallback*/
	background: rgba(200,200,200,0.5);
	-webkit-transition-property: background;
	-webkit-transition-duration: 0.25s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: background;
	-moz-transition-duration: 0.25s;
	-moz-transition-timing-function: ease;
}

.dgPageButtonCurr {
	background:#F0F0F0;
	font-weight: bold;
}

.dgPageButtonDis {
	opacity: 0.5;
}

.dgPageButton:hover {
	background: #FFEEAA;
}

.dgPageButton:active {
	background: white;
	box-shadow: -1px 1px 8px #FFFFCC, 1px -1px 8px #FFFFFF;
}

/* lookup div within popup */
.dgLookupResults {
	border-top: 1px solid #D0D0D0;
}

table.dgLookupResultTable {
	width: 100%;
	color: #404040;
	background: white;
	font-size: 12px;
	font-family: arial;
	border-bottom: 1px solid #D0D0D0;
}

table.dgLookupResultTable td {
	border-bottom: 1px solid #F0F0F0;
	padding: 2px;
	padding-left: 4px;
	padding-right: 4px;
}

table.dgLookupResultTable tr {
	-webkit-transition-property: background;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
}

table.dgLookupResultTable tr.dgLookupOdd:hover,
table.dgLookupResultTable tr.dgLookupEven:hover {
	background: #FFEEAA;
	color: #404040;

	-moz-transition-property: background;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;
}

table.dgLookupResultTable tr.dgLookupSelected:hover {
	color: #FFFFFF;
}

.dgLookupOdd {
}

.dgLookupEven {
	background: #F4F4F4;
}

.dgLookupSelected {
	background: rgb(53,107,141);
	color: #F0F0F0;
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,rgb(53,107,141)), color-stop(100%,rgb(33,87,121)));
}

/* image item within popup */
.dgLookupImage {
	max-width: 96px;
	max-height: 96px;
}

/* filter control within popup */
.dgLookupFilter {
	font-size: 10px;
	color: #404040;
}

</style>
}

/// Initialize additional client-side values
ClientMethod onCreate() [ Language = javascript ]
{
	// initialize additional properties
	this.hasFocus = false;
	this.cellHasFocus = false;
	this.F2Mode = false;
	this.currEditType = null;
}

/// Initialize the calculation engine.
ClientMethod initEngine() [ Language = javascript ]
{
	// pass an instance of *this* grid to provide data for the engine
	if (!this._engine) {
		this._engine = new dsFormulaEngine(this);

		// callback to add more functions
		if (this.ongetfunctions) {
			var funcSet = zenInvokeCallbackMethod(this.ongetfunctions,this,'ongetfunctions');
			if (funcSet) {
				this._engine.parser.setFunctionSet(funcSet);
			}
		}
	}
}

/// Recalculate values of cells using the formula engine.
ClientMethod recalc() [ Language = javascript ]
{
	if (this._engine) {
		this._engine.recalc();
	}
}

/// Evaluate a single expression (outside of the general set of cells).
ClientMethod evaluate(expr, row, col) [ Language = javascript ]
{
	var value = '';
	if (this._engine) {
		value = this._engine.evaluate(expr,row,col);
		value = (value===null) ? expr : value;
	}
	return value;
}

/// Client-side method to render this component.
ClientMethod renderContents() [ Language = javascript ]
{
	try {
		var controller = this.getController();
		if (null == controller) {
			// try to connect to dataController
			this.connectToController();
			controller = this.getController();
		}

		var encDiv = this.getEnclosingDiv();
		// test if we have not been rendered yet
		if (encDiv == null) return;

		// get meta data
		this.buildRowIndex();
		this.buildColumnIndex();

		if (this.useEngine) this.initEngine();

		// render main divs for the grid
		this.renderSkeleton();

		// render data (headers and cells) within the grid
		this.renderCells(true);

		this.adjustSizes();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,this.lblErrorRenderContents);
	}
}

/// Render the main divs (without content).
ClientMethod renderSkeleton() [ Internal, Language = javascript ]
{
	try {
		var encDiv = this.getEnclosingDiv();
		var encHgt = encDiv.offsetHeight;
		var encWid = encDiv.offsetWidth;

		// build HTML for grid
		var html = [];
		html[html.length] = '<div id="'+this.makeId('wrapper')+'" class="dgWrapper" onclick="zenPage.getComponent('+this.index+').focus();">';

		// insert invisible input to catch key events
		html[html.length] = '<div style="top:0px;left:0px;position:absolute; display:block; height:0px; width:0px; overflow:hidden; font-size:0px; line-height:0px;" >';
		html[html.length] = '<input type="text" tabindex="'+this.tabIndex+'" id="'+this.makeId('invisible')+'" onkeydown="return zenPage.getComponent('+this.index+').gridKeyDownHandler(event);" onkeypress="return zenPage.getComponent('+this.index+').gridKeyPressHandler(event);" onfocus="zenPage.getComponent('+this.index+').gridKeyFocus();" onblur="zenPage.getComponent('+this.index+').gridKeyBlur();"/>';
		html[html.length] = '</div>';

		// overlay for messages
		html[html.length] = '<div id="'+this.makeId('overlay')+'" class="dgOverlay"></div>';

		// title
		var titleHTML = null;
		if (this.ongettitle!='') {
			titleHTML = zenInvokeCallbackMethod(this.ongettitle,this,'ongettitle');
		}
		else if (this.gridTitle != '') {
			titleHTML = zenEscapeHTML(this.gridTitle);
		}
		if (titleHTML) {
			html[html.length] = '<div id="'+this.makeId('title')+'" style="'+this.gridTitleStyle+'" class="dgTitle">';
			html[html.length] = titleHTML;
			html[html.length] = '</div>';
		}

		var cellHgt = parseInt(this.rowHeight,10);
		cellHgt = isNaN(cellHgt) ? 20 : cellHgt;
		var cellWid = parseInt(this.columnWidth,10);

		// adjust for border etc.
		var cellPadH = 1;
		var cellPadW = 1;

		var scrollWid = 22;
		var scrollHgt = 22;

		// n.b. these values are replaced in adjustSizes
		var colHeaderHgt = 40;
		var rowHeaderWid = 125;
		var dataWid = encWid > (rowHeaderWid+scrollWid) ? (encWid-(rowHeaderWid+scrollWid)-4): 0;
		var dataHgt = encHgt > (colHeaderHgt+scrollHgt) ? (encHgt-(colHeaderHgt+scrollHgt)-4): 0;;

		var nubDivTop = 0;
		var nubDivLeft = 0;
		var nubDivWid = rowHeaderWid;
		var nubDivHgt = colHeaderHgt;

		var chDivTop = 0;
		var chDivLeft = rowHeaderWid;
		var chDivWid = dataWid;
		var chDivHgt = colHeaderHgt;

		var rhDivTop = colHeaderHgt;
		var rhDivLeft = 0;
		var rhDivWid = rowHeaderWid;
		var rhDivHgt = dataHgt;

		var dataDivTop = colHeaderHgt;
		var dataDivLeft = rowHeaderWid;
		var dataDivWid = dataWid;
		var dataDivHgt = dataHgt;

		// upper nub
		html[html.length] = '<div id="'+this.makeId('nub')+'" class="dgNub" style="top:'+nubDivTop+'px;left:'+nubDivLeft+'px;width:'+nubDivWid+'px;height:'+(nubDivHgt-1)+'px;">';
		html[html.length] = '&nbsp;';
		html[html.length] = '</div>';

		// column headers
		if (this.showColumnLabels) {
			html[html.length] = '<div id="'+this.makeId('colHdrs')+'" class="dgDivColumnHeader" style="top:'+chDivTop+'px;left:'+chDivLeft+'px;width:'+chDivWid+'px;height:'+(chDivHgt-1)+'px;">';
			html[html.length] =	'</div>';
		}

		// row headers
		if (this.showRowLabels) {
			html[html.length] = '<div id="'+this.makeId('rowHdrs')+'" class="dgDiv" style="top:'+rhDivTop+'px;left:'+rhDivLeft+'px;width:'+rhDivWid+'px;height:'+rhDivHgt+'px;"/>';
			html[html.length] = '</div>';
		}

		// undercoat for cells
		// this is a div underneath the data area that can be styled
		html[html.length] = '<div id="'+this.makeId('cellsUnder')+'" class="dgCellsUnder" style="top:'+dataDivTop+'px;left:'+dataDivLeft+'px;width:'+dataDivWid+'px;height:'+dataDivHgt+'px;">';
		html[html.length] = '</div>';

		// data
		html[html.length] = '<div id="'+this.makeId('cells')+'" class="dgDivCells" style="top:'+dataDivTop+'px;left:'+dataDivLeft+'px;width:'+dataDivWid+'px;height:'+dataDivHgt+'px;">';

		// div used to indicate current selection
		html[html.length] = '<div id="'+this.makeId('selector')+'" class="dgSelector" onclick="zenPage.getComponent('+this.index+').selectorClickHandler(event);" ondblclick="zenPage.getComponent('+this.index+').selectorDblClickHandler(event);" >';
		html[html.length] = '</div>';

		// "action" icon within selector
		if (true) {
			html[html.length] = '<div id="'+this.makeId('action')+'" class="dgAction" onclick="zenPage.getComponent('+this.index+').showPopup();">';
			html[html.length] = '</div>';
		}

		// div used for sizing handle for selector
		if (this.multiSelect) {
			html[html.length] = '<div id="'+this.makeId('sizeHandle')+'" class="dgSizeHandle" onmousedown="zenPage.getComponent('+this.index+').sizeHandleMouseDown(event);" >';
			html[html.length] = '</div>';
		}

		// inner div scrolls within the outer div
		html[html.length] = '<div id="'+this.makeId('cellsInner')+'">';
		html[html.length] = '</div>';

		html[html.length] = '</div>';

		// vt scrollbar
		html[html.length] = '<div id="'+this.makeId('vtScroll')+'" class="dgVtScroll" style="top:'+dataDivTop+'px;left:'+(dataDivLeft+dataDivWid)+'px;height:'+dataDivHgt+'px;" onscroll="zenPage.getComponent('+this.index+').cellScrollVt();">';
		html[html.length] = '<div id="'+this.makeId('vtScrollInner')+'" class="dgVtScrollInner" >&nbsp;</div>';
		html[html.length] = '</div>';

		// hz scrollbar
		html[html.length] = '<div id="'+this.makeId('hzScroll')+'" class="dgHzScroll" style="top:'+(dataDivTop+dataDivHgt+1)+'px;left:'+(dataDivLeft+1)+'px;width:'+dataDivWid+'px;" onscroll="zenPage.getComponent('+this.index+').cellScrollHz();">';
		html[html.length] = '<div id="'+this.makeId('hzScrollInner')+'" class="dgHzScrollInner" >&nbsp;</div>';
		html[html.length] = '</div>';

		// (floating) summary header and row
		if (this.summaryRow) {
			if (this.showRowLabels) {
				html[html.length] = '<div id="'+this.makeId('summaryHdr')+'" class="dgDivSummaryHeader" />';
				html[html.length] = '</div>';
			}

			html[html.length] = '<div id="'+this.makeId('summary')+'" class="dgDivSummary"/>';
			html[html.length] = '</div>';
		}

		// status area
		var statusHTML = '';
		if (this.ongetstatus!='') {
			statusHTML = zenInvokeCallbackMethod(this.ongetstatus,this,'ongetstatus');
		}
		html[html.length] = '<div id="'+this.makeId('status')+'" style="'+this.gridStatusStyle+'" class="dgStatus">';
		html[html.length] = statusHTML;
		html[html.length] = '<div id="'+this.makeId('paging')+'" style="position:absolute;right:20px;width:0px;">';
		html[html.length] = '</div>';
		html[html.length] = '</div>';

		// end wrapper
		html[html.length] = '</div>';
		encDiv.innerHTML = html.join('');
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,this.lblErrorRenderSkeleton);
	}
}

/// Utility for pulling specific settings out of a user defined style string
ClientMethod extractUserStyleSetting(styleStr, attr) [ Internal, Language = javascript ]
{
	var value = null;
	if (styleStr.length) {
		var styleS = styleStr.split(" ").join("");
		var styleArr = styleStr.split(";");
		var len = styleArr.length;
		for (var i=0;i<len;i++) {
			var nvp = styleArr[i].split(":");
			if (nvp[0]==attr) value=nvp[1];
		}
	}
	return(value);
}

/// Render the data and headers within the grid.
ClientMethod renderCells(recalc) [ Internal, Language = javascript ]
{
	try {
		recalc = zenGet(recalc,false);
		var controller = this.getController();
		var html = [];

		if (!this._rowDescIndex) {
			this.buildRowIndex();
		}
		if (!this._columnDescIndex) {
			this.buildColumnIndex();
		}

		this._sortIndex = null;
		if (recalc) {
			this.recalc();
		}

		if (this.filterKey!='' || (this.sortMode=='client' && this.sortOrder!='' && this.sortColumn>0)) {
			this.buildSortIndex();
		}

		var dataIndexCorrected = false;
		var array = this.getColumnDescriptors();
		if (this._engine && array && array.length>0) {
			var dataIndexCorrected = true;	
		}

		var cols = this.getColumnCount();
		var rows = this.getRowsOnPage();
		if (parseInt(this.currRow,10) > rows) {
			this.currRow = rows;
			this.selectedRange = '';
		}

		// !!!
		// adjust for border etc.
		var cellPadH = 1;
		var cellPadW = 1;

		var cellHgt = parseInt(this.rowHeight,10);
		cellHgt = isNaN(cellHgt) ? 20 : cellHgt;
		var cellWid = parseInt(this.columnWidth,10);
		cellWid = isNaN(cellWid) ? 50 : cellWid;
		var colHeaderHgt = 40;
		
		var uHeight = this.extractUserStyleSetting(this.columnHeaderStyle,"height");
		if (uHeight && uHeight.indexOf("px")>0) {
			this.columnHeaderStyle = "display:block;"+this.columnHeaderStyle;
			colHeaderHgt = parseInt(uHeight,10);
		}
		
		var rowHeaderWid = 150;
		var offset = this.getRowOffset();

		// remember if user has adjusted column widths
		if (!this._columnWidths) {
			this._columnWidths = [];
		}

		// assemble list of checkbox values
		if (this.showRowSelector) {
			if (this.checkedRows == 'all') {
				var cbAll = true;
			}
			else {
				var cbAll = false;
				var cbList = {};
				var list = this.checkedRows.toString().split(',');
				for (var t = 0; t < list.length; t++) {
					cbList[list[t]-1] = true;
				}
			}
		}

		// keep track of parent cells
		var colParents = {};
		var rowParents = {};

		// column headers
		var div = this.findElement('colHdrs');
		if (div) {
			html = [];
			var cy = 0;
			var cx = cellPadW;

			/* check box */
			if (this.showRowSelector) {
				var checked = cbAll ? 'checked="1"' : '';
				html[html.length] = '<div id="'+this.makeId('ch_0_'+'cb')+'" class="dgHdr" style="top:'+cy+'px;left:'+cx+'px;width:'+cellWid+'px;height:'+colHeaderHgt+'px;" >';
				html[html.length] = '<div class="dgHdrColInner">';
				html[html.length] = '<input '+checked+' type="checkbox" id="'+this.makeId('cball')+'" onclick="zenPage.getComponent('+this.index+').cbClick(\'all\');" />'
				html[html.length] = '</div>';
				html[html.length] = '</div>';
			}

			// label resize
			if (this.canResizeColumns) {
				html[html.length] = '<div id="'+this.makeId('rszlabel')+'" class="dgResize" onmousedown="zenPage.getComponent('+this.index+').resizeMouseDown(event,-1);" ondblclick="zenPage.getComponent('+this.index+').resizeMouseDblClick(event,-1);">&nbsp;</div>';
			}

			for (var c = 0; c < cols; c++) {
				var cInfo = this.getColumnInfo(c);
				if (cInfo) {
					// column header
					var label = cInfo.caption ? cInfo.caption : cInfo.name ? cInfo.name : '';
					var align = cInfo.headerAlign ? cInfo.headerAlign : '';
					if (align == '') {
						align = cInfo.align ? cInfo.align : '';
					}
					var hstyle = cInfo.headerStyle ? cInfo.headerStyle : '';
				}
				else {
					var label = '';
					var align = '';
					var hstyle = '';
				}

				var ctr = '';
				var istyle = '';
				switch(align) {
				case 'left':
					istyle = 'left:0px;';
					break;
				case 'right':
					istyle = 'right:0px;';
					break;
				case 'center':
					// defer to adjust size method
					ctr = 'centered="1"';
					break;
				}

				var style = this.columnHeaderStyle + hstyle;
				style = (style.toString().indexOf('background')>=0) ? (style + 'background-image:none;') : style;
				html[html.length] = '<div id="'+this.makeId('ch_0_'+c)+'" class="dgHdr" '+ctr+' style="'+style+'top:'+cy+'px;left:'+cx+'px;width:'+cellWid+'px;height:'+colHeaderHgt+'px;" onclick="zenPage.getComponent('+this.index+').columnClickHandler(event,'+c+');" ondblclick="zenPage.getComponent('+this.index+').columnDblClickHandler(event,'+c+');">';
				html[html.length] = '<div class="dgHdrColInner" style="'+istyle+'">';
				// show sort arrow
				if (this.sortOrder!='' && c == this.sortColumn-1) {
					//html[html.length] = this.sortOrder=='asc' ? '&#9652;' : '&#9662;';
					html[html.length] = '<span style="font-weight:bold;">' + (this.sortOrder=='asc' ? '&darr;' : '&uarr;') + '</span>';
				}
				else {
					html[html.length] = '&nbsp;';
				}
				html[html.length] = (label==='')?'&nbsp;':zenEscapeXML(label);
				html[html.length] = '</div>';

				html[html.length] = '</div>';

				// column resize handles
				if (this.canResizeColumns) {
					html[html.length] = '<div id="'+this.makeId('rsz_'+c)+'" class="dgResize" onmousedown="zenPage.getComponent('+this.index+').resizeMouseDown(event,'+c+');" ondblclick="zenPage.getComponent('+this.index+').resizeMouseDblClick(event,'+c+');">&nbsp;</div>';
				}

				// are there nested headers above this one?
				var parent = cInfo._parent;
				var pdepth = 0;
				while (parent && !colParents[parent._key]) {
					pdepth++;
					if (this.columnLabelSpan) {
						colParents[parent._key] = true;
					}

					var style = this.columnHeaderStyle;
					var istyle = '';
					html[html.length] = '<div id="'+this.makeId('ch_'+pdepth+'_'+c)+'" class="dgHdr" '+ctr+' style="'+style+'top:'+cy+'px;left:'+cx+'px;width:'+cellWid+'px;height:'+colHeaderHgt+'px;" onclick="zenPage.getComponent('+this.index+').columnClickHandler(event,'+c+');">';
					html[html.length] = '<div class="dgHdrColInner" style="'+istyle+'">';
					html[html.length] = '&nbsp;';
					html[html.length] = zenEscapeXML(parent.caption);
					html[html.length] = '</div>';

					html[html.length] = '</div>';

					parent = parent._parent;
				}

				cx += (cellWid+cellPadW);
			}
			div.innerHTML = html.join('');
		}

		// row header labels (in nub)
		var hdrLabels = this.getRowHeaderLabels();
		
		if (hdrLabels.length) {
			var div = this.findElement('nub');
			if (div) {
				html = [];
				for (var hx = 0; hx < hdrLabels.length; hx++) {
					var style = '';
					html[html.length] = '<div id="'+this.makeId('nub_'+hx)+'" class="dgHdr" style="'+style+'">';
					html[html.length] = '<div class="dgHdrRowInner">';
					html[html.length] = zenEscapeXML(hdrLabels[hx]);
					html[html.length] = '</div>';
					html[html.length] = '</div>';
				}
				div.innerHTML = html.join('');
			}
		}

		// row headers
		var div = this.findElement('rowHdrs');
		if (div) {
			html = [];
			var cy = 0;
			var cx = 0;
			for (var ri = 0; ri < rows; ri++) {
				// row header
				var r = this._sortIndex ? this._sortIndex[ri+offset].row : ri+offset;
				var rInfo = this.getRowInfo(r);
				if (rInfo) {
					var label = rInfo.caption ? rInfo.caption : rInfo.name ? rInfo.name : '';
				}
				else {
					var label = r + 1;
				}

				var style = this.rowHeaderStyle;
				style = (style.toString().indexOf('background')>=0) ? (style + 'background-image:none;') : style;
				html[html.length] = '<div id="'+this.makeId('rh_0_'+ri)+'" class="dgHdr" style="'+style+'top:'+cy+'px;left:'+cx+'px;width:'+rowHeaderWid+'px;height:'+cellHgt+'px;" onclick="zenPage.getComponent('+this.index+').rowClickHandler(event,'+ri+');" ondblclick="zenPage.getComponent('+this.index+').rowDblClickHandler(event,'+ri+');">';
				html[html.length] = '<div class="dgHdrRowInner">';
				html[html.length] = (label==='') ? '&nbsp;' : zenEscapeXML(label);
				html[html.length] = '</div>';
				html[html.length] = '</div>';

				// are there nested headers above this one?
				var parent = rInfo._parent;
				var pdepth = 0;
				while (parent && !rowParents[parent._key]) {
					pdepth++;
					if (this.rowLabelSpan && this.sortColumn==0) {
						// let parent span children
						rowParents[parent._key] = true;
					}

					var style = this.rowHeaderStyle;
					var istyle = '';
					html[html.length] = '<div id="'+this.makeId('rh_'+pdepth+'_'+ri)+'" class="dgHdr" style="'+style+'top:'+cy+'px;left:'+cx+'px;width:'+rowHeaderWid+'px;height:'+cellHgt+'px;" onclick="zenPage.getComponent('+this.index+').rowClickHandler(event,'+ri+');" ondblclick="zenPage.getComponent('+this.index+').rowDblClickHandler(event,'+ri+');">';
					html[html.length] = '<div class="dgHdrRowInner">';
					html[html.length] = zenEscapeXML(parent.caption);
					html[html.length] = '</div>';
					html[html.length] = '</div>';

					parent = parent._parent;
				}

				cy += (cellHgt+cellPadH);
			}
			div.innerHTML = html.join('');
		}

		// cells
		var div = this.findElement('cellsInner');
		if (div) {
			html = [];
			var cy = 0;
			for (var ri = 0; ri < rows; ri++) {
				var r = this._sortIndex ? this._sortIndex[ri+offset].row : ri+offset;
				var rInfo = this.getRowInfo(r);
				var rFormat = rInfo&&rInfo.format ? rInfo.format : '';
				var rStyle = rInfo&&rInfo.style ? rInfo.style : '';
				var rPrio = rInfo&&rInfo.priority ? rInfo.priority : 0;

				var cx = cellPadW;
				/* check box */
				if (this.showRowSelector) {
					var style = rStyle;
					var istyle = '';
					html[html.length] = '<div id="'+this.makeId('c_'+ri+':'+'cb')+'" class="dgCell" style="'+style+'">';
					html[html.length] = '<div class="dgCellInner" style="'+istyle+'">';
					var checked = cbAll||(cbList&&cbList[r]) ? 'checked="1"' : '';
					html[html.length] = '<input '+checked+' type="checkbox" id="'+this.makeId('cb_'+r)+'" onclick="zenPage.getComponent('+this.index+').cbClick('+r+');" />';
					html[html.length] = '</div>';
					html[html.length] = '</div>';
					cx += (cellWid+cellPadW);
				}
				for (var c = 0; c < cols; c++) {
					var cInfo = this.getColumnInfo(c);
					var cFormat = cInfo&&cInfo.format ? cInfo.format : '';
					var cStyle = cInfo&&cInfo.style ? cInfo.style : '';
					var cPrio = cInfo&&cInfo.priority ? cInfo.priority : 1;
					var cType = cInfo&&cInfo.type ? cInfo.type : 'string';
					var cAlign = cInfo&&cInfo.align ? cInfo.align : '';
					var cName = cInfo&&cInfo.name ? cInfo.name : '';
					var cImage = cInfo&&cInfo.image ? cInfo.image : '';

					if (!dataIndexCorrected && cInfo && cInfo._key) {
						var dataColIdx = parseInt(cInfo._key.split(":")[1])
						var value = this.getCellValue(r,dataColIdx);	
					}
					else {
						var value = this.getCellValue(r,c);	
					}

					// test for user callback
					var userContent = '';
					var userInfo = this.getCellContent(value,r,c);
					if (userInfo) {
						if ('object' == typeof userInfo) {
							if ('undefined' != typeof userInfo.content) {
								cType = 'user';
								userContent = userInfo.content;
								cAlign = 'left';
							}
							else {
								value = 'undefined' != typeof userInfo.value ? userInfo.value : value;
								cType = 'undefined' != typeof userInfo.type ? userInfo.type : cType;
							}
							cAlign = 'undefined' != typeof userInfo.align ? userInfo.align : cAlign;
							cStyle = 'undefined' != typeof userInfo.style ? userInfo.style : cStyle;
							cFormat = 'undefined' != typeof userInfo.format ? userInfo.format : cFormat;
							cImage = 'undefined' != typeof userInfo.image ? userInfo.image : cImage;
						}
						else {
							cType = 'user';
							userContent = userInfo;
							cAlign = 'left';
						}
					}

					var format = (cPrio>rPrio) ? cFormat : rFormat;
					format = format ? format : this.format;
					var cellStyle = this.style + ((cPrio>rPrio) ? rStyle+cStyle : cStyle+rStyle);

					var sinfo = {};
					if (cellStyle!='') {
						// some styles are applied to the inner div
						var so = this.splitStyle(cellStyle,sinfo);
						var cellStyleInner = so.inner;
						cellStyle = so.outer;
					}
					else {
						var cellStyleInner = '';
					}

					if (cAlign=='') {
						if (sinfo.textAlign) {
							// get align from style
							var align = sinfo.textAlign;
						} 
						else if (cType=='image' || cType=='button' || cType=='checkbox' || cType=='link') {
							var align = 'center';
						}
						else {
							var align = 'number'==typeof value ? 'right' : 'left';
						}
					}
					else {
						var align = cAlign;
					}
					var ctr = '';
					var istyle = '';
					switch(align) {
					case 'left':
						istyle = 'left:0px;';
						break;
					case 'right':
						istyle = 'right:0px;';
						break;
					case 'center':
						// defer to adjust size method
						ctr = 'centered="1"';
						break;
					}

					var events = ' onclick="zenPage.getComponent('+this.index+').cellClickHandler('+(ri+1)+','+(c+1)+',event);" ondblclick="zenPage.getComponent('+this.index+').cellDblClickHandler('+(ri+1)+','+(c+1)+',event);" onmouseover="zenPage.getComponent('+this.index+').cellMouseOver('+(ri+1)+','+(c+1)+',event);" onmouseout="zenPage.getComponent('+this.index+').cellMouseOut('+(ri+1)+','+(c+1)+',event);"'
					var style = 'top:'+cy+'px;left:'+cx+'px;width:'+cellWid+'px;height:'+cellHgt+'px;text-align:'+align+';';
					if (this.showZebra) {
						if (ri%2) {
							style += (this.evenRowColor!='') ? 'color:'+this.evenRowColor+';' : '';
							style += (this.evenRowBackground!='') ? 'background-color:'+this.evenRowBackground+';' : '';
						}
						else {
							style += (this.oddRowColor!='') ? 'color:'+this.oddRowColor+';' : '';
							style += (this.oddRowBackground!='') ? 'background-color:'+this.oddRowBackground+';' : '';
						}
					}
					style += cellStyle;
					istyle += cellStyleInner;

					html[html.length] = '<div id="'+this.makeId('c_'+ri+':'+c)+'" class="dgCell" '+ctr+' style="'+style+'" '+events+' origStyle="'+style+'">';

					// make sure clickable items have z-index above selector!
					switch(cType) {
					case 'image':
						html[html.length] = '<div class="dgCellInnerImage" style="'+istyle+'">';
						if (''===value) {
							var ic = 1;
						}
						else {
							var ic = parseInt(value,10);
							ic = !value || value<0 ? 0 : (value > 10) ? 10 : value;
						}
						if (cImage) {
							// is image a formula?
							if (cImage.toString().charAt(0)=='=') {
								cImage = this.evaluate(cImage,ri,c);
							}
							if (cImage) {
								for (var icx = 0; icx < ic; icx++) {
									html[html.length] = '<image src="'+cImage+'"/>';
								}
							}
						}
						html[html.length] = '</div>';
						break;
					case 'checkbox':
						var checked = value ? true : false;
						html[html.length] = '<div class="dgCellInnerImage" style="'+istyle+'">';
						html[html.length] = '<input type="checkbox" '+(checked?'checked="1"':'')+' onclick="zenPage.getComponent('+this.index+').cellActionHandler('+(ri+1)+',\''+cName+'\',this.checked);" />';
						html[html.length] = '</div>';
						break;
					case 'button':
						// caption is value
						// use image if supplied
						if (cImage) {
							html[html.length] = '<div class="dgCellInnerImage" style="'+istyle+'">';
							// is image a formula?
							if (cImage.toString().charAt(0)=='=') {
								cImage = this.evaluate(cImage,ri,c);
							}
							if (cImage) {
								html[html.length] = '<input type="image" src="'+cImage+'" onclick="zenPage.getComponent('+this.index+').cellActionHandler('+(ri+1)+',\''+cName+'\',true);"/>';
							}
							html[html.length] = '</div>';
						}
						else if (value!=='') {
							html[html.length] = '<input class="dgCellInnerImage" type="button" value="'+value+'"onclick="zenPage.getComponent('+this.index+').cellActionHandler('+(ri+1)+',\''+cName+'\',true);" />';
						}
						break;
					case 'link':
						if (value!=='') {
							html[html.length] = '<a href="#" class="dgCellInnerImage" onclick="zenPage.getComponent('+this.index+').cellActionHandler('+(ri+1)+',\''+cName+'\',true);return false;">'+value+'</a>';
						}
						else {
							html[html.length] = '<div class="dgCellInnerImage" style="'+istyle+'">';
							html[html.length] = '</div>';
						}
						break;
					case 'user':
						html[html.length] = '<div class="dgCellInner" style="'+istyle+'">';
						html[html.length] = userContent;
						html[html.length] = '</div>';
						break;
					case 'string':
					default:
						html[html.length] = '<div class="dgCellInner" style="'+istyle+'">';
						// test for 'value
						if (value.toString().charAt(0)=='\'') {
							html[html.length] = value.toString().substring(1);
						}
						else {
							html[html.length] = zenEscapeXML((format=='' || this.alwaysString ) ? value : zenFormatNumber(value,format)); // JSL4534
						}
						html[html.length] = '</div>';
						break;
					}

					html[html.length] = '</div>';
					cx += (cellWid+cellPadW);
				}
				cy += (cellHgt+cellPadH);
			}
			div.innerHTML = html.join('');
		}

		// summary row header
		var div = this.findElement('summaryHdr');
		if (div) {
			html = [];
			var label = this.summaryRow.caption ? this.summaryRow.caption : this.name;
			html[html.length] = '<div id="'+this.makeId('rh_sum')+'" class="dgHdr">';
			html[html.length] = '<div class="dgHdrRowInner">';
			html[html.length] = zenEscapeXML(label);
			html[html.length] = '</div>';
			html[html.length] = '</div>';
			div.innerHTML = html.join('');
		}

		// summary row
		var div = this.findElement('summary');
		if (div) {
			html = [];
			var cy = 0;
			var cx = cellPadW;

			/* check box */
			if (this.showRowSelector) {
				html[html.length] = '<div id="'+this.makeId('sum_cb')+'" class="dgHdr" style="top:'+cy+'px;left:'+cx+'px;width:'+cellWid+'px;height:'+colHeaderHgt+'px;" >';
				html[html.length] = '<div class="dgHdrColInner">';
				html[html.length] = '&nbsp;'
				html[html.length] = '</div>';
				html[html.length] = '</div>';
			}

			for (var c = 0; c < cols; c++) {
				var cInfo = this.getColumnInfo(c);
				var label = '';
				html[html.length] = '<div id="'+this.makeId('sum_'+c)+'" class="dgHdr" style="top:'+cy+'px;left:'+cx+'px;width:'+cellWid+'px;height:'+colHeaderHgt+'px;">';
				html[html.length] = '<div class="dgHdrColInner">';
				html[html.length] = zenEscapeXML(label);
				html[html.length] = '</div>';
				html[html.length] = '</div>';
				cx += (cellWid+cellPadW);
			}
			div.innerHTML = html.join('');
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,this.lblErrorRenderCells);
	}
}

/// Test for override of cell content.
/// This may be overridden by subclasses.
ClientMethod getCellContent(value, r, c) [ Internal, Language = javascript ]
{
	var userInfo = null;
	if (this.ondrawcell) {
		userInfo = zenInvokeCallbackMethod(this.ondrawcell,this,'ondrawcell','value',value,'row',r+1,'col',c+1);
	}
	return userInfo;
}

/// Return the HTML for the paging buttons.
ClientMethod getPagingHTML() [ Language = javascript ]
{
	var html = [];
	var pageSize = this.getPageSize();
	if (pageSize > 0) {
		var pageCount = this.getPageCount();
		if (pageCount>1) {
			var currPage = this.getCurrPage();
			var btnPad = 5;
			var btnWid = 18;

			// compute array of buttons
			var buttons = [];
			for (var n = 0; n < pageCount; n++) {
				buttons.splice(n,0,n+1);
			}

			// if too many, remove some: 1 ... a b c ... N
			if (pageCount > 7) {
				if (currPage < 5) {
					var startNo = null;
					var endNo = 5;
				}
				else if (currPage > pageCount - 5) {
					var startNo = pageCount - 5;
					var endNo = null;
				}
				else {
					var startNo = currPage - 2;
					var endNo = currPage + 1;
				}

				if (endNo!==null) {
					for (var n = endNo+1; n < pageCount; n++) {
						buttons.splice(endNo,1);
					}
					buttons.splice(endNo,0,'');
				}
				if (startNo!==null) {
					for (var n = 1; n < startNo; n++) {
						buttons.splice(1,1);
					}
					buttons.splice(1,0,'');
				}
			}

			// add prev, next
			var prevChar = '&#9668;';
			var nextChar = '&#9658;';

			buttons.splice(0,0,prevChar);
			buttons[buttons.length] = nextChar;

			var x = 0;
			var wid = (btnWid + btnPad) * buttons.length;

			html[html.length] = '<div class="dgPageDiv" id="'+this.makeId('pagingDiv')+'" style="width:'+wid+'px;">';
			for (var n = 0; n < buttons.length; n++) {
				x += btnWid + btnPad;
				if (buttons[n] == '') {
					html[html.length] = '<div style="position:absolute;text-align:center;width:'+btnWid+'px;top:2px;left:'+x+'px;">...</div>';
				}
				else {
					var cls = (currPage==buttons[n]) ? 'dgPageButtonCurr' : 'dgPageButton';
					var onclick = '';
					if (buttons[n]==prevChar) {
						if (currPage<=1) {
							cls = 'dgPageButtonDis';
						}
						else {
							onclick = 'onclick="zenPage.getComponent('+this.index+').prevPage();"';
						}
					}
					else if (buttons[n]==nextChar) {
						if (currPage<pageCount) {
							onclick = 'onclick="zenPage.getComponent('+this.index+').nextPage();"';
						}
						else {
							cls = 'dgPageButtonDis';
						}
					}
					else {
						onclick = 'onclick="zenPage.getComponent('+this.index+').setCurrPage('+buttons[n]+');"';
					}
					html[html.length] = '<input type="button" class="'+cls+'" style="width:'+btnWid+'px;top:2px;left:'+x+'px;" '+onclick+' value="'+buttons[n]+'" />';
				}
			}
			html[html.length] = '</div>';
		}
	}
	return html.join('');
}

/// Return the (resolved) value of the given cell (0-based).
ClientMethod getCellValue(r, c) [ Internal, Language = javascript ]
{
	var value = '';
	var array = this.getColumnDescriptors();
	if (this._engine && array && array.length>0) {
		// dispatch to engine
		value = this._engine.getCellValue(r,c);
	}
	else {
		var controller = this.getController();
		value = controller ? controller.getData(r,c) : '';
	}
	// JMD1238
	if ('undefined' == typeof value) {
		value = '';
	}
	return value;
}

/// Set the value of grid cell; Row and column are 0-based.
ClientMethod setCellValue(value, r, c) [ Language = javascript ]
{
	// if there is a controller, notify it
	var controller = this.getController();
	if (controller) {
		// try to preserve type of value!
		if (!this.alwaysString && (!isNaN(parseFloat(value)) && (value==parseFloat(value)))) { // JSL4534
			value = parseFloat(value);
		}

		// try to find out what property is in this column
		var propName = null;
		var cInfo = this.getColumnInfo(parseInt(c,10));
		if (cInfo && cInfo.value) {
			// assume "=[@prop]" is a prop name
			propName = '';
			var t = cInfo.value.toString();
			if (t.substr(0,3)=='=[@') {
				propName = t.substr(3,t.length-4);
			}
		}

		if (propName == null) {
			// use name for this column
			propName = controller.getPropertyName(parseInt(c,10));
		}

		if (propName && propName !== '') {

			// prevent notify from updating grid
			this._inSetValue = true;

			// translate thru sort index !!!
			var rx = this._sortIndex ? this._sortIndex[parseInt(r,10)].row : (parseInt(r,10));
			this.sendEventToController('propertyChange',propName,value,rx);

			this._inSetValue = false;
		}
	}

	// rerender grid
	this.updateCells(false,true,10);
}

/// Set the client-side filter key.
ClientMethod setFilterKey(key, update) [ Language = javascript ]
{
	update = zenGet(update,true);
	if (this.filterKey != key) {
		this.filterKey = key;
		if (update) {
			this.updateCells(false,true,200);
		}
	}
}

/// Reset and re-render the entire grid contents.
ClientMethod updateGrid(reset) [ Language = javascript ]
{
	reset = 'undefined' == typeof reset ? true : reset;
	if (reset) {
		delete this._columnWidths;
		this.selectedRange = '';
		this.currColumn = 1;
		this.currRow = 1;
		this.sortOrder = '';
		this.sortColumn = 0;
		this.currPage = 1;
		this.filterKey = '';
	}
	this.render();
}

/// Re-render the data cells within this grid.<br/>
/// If <var>immediate</var> is true, execute immediately. Otherwise
/// use a timer.<br/>
ClientMethod updateCells(immediate, reindex, delay) [ Language = javascript ]
{
	delay = zenGet(delay,1);
	if (reindex) {
		this.buildRowIndex();
		this.buildColumnIndex();
	}
	
	if (this._updateTimer) {
		window.clearTimeout(this._updateTimer);
		delete this._updateTimer;
	}
	
	this.beginWait();
	if (immediate) {
		this.reallyUpdateCells();
	}
	else {
		this._updateTimer = window.setTimeout('zenPage.getComponent('+this.index+').reallyUpdateCells();',delay);
	}
}

/// Do the actual work of rerendering the data within this grid.
ClientMethod reallyUpdateCells() [ Internal, Language = javascript ]
{
	delete this._updateTimer;
	this.renderCells(true);
	this.adjustSizes();
	this.endWait();
}

/// Set the size of this component (in pixels).
ClientMethod setSize(width, height) [ Internal, Language = javascript ]
{
	var div = this.getEnclosingDiv();
	div.style.width = width + 'px';
	div.style.height = height + 'px';
	this.adjustSizes();
}

/// Helper function to define the method getComputedStyle() is the browser
/// does not already have an innate one (i.e. IE8)
ClientMethod defineGetComputedStyle() [ Internal, Language = javascript ]
{
	if (!window.getComputedStyle) {
	    window.getComputedStyle = function(el, pseudo) {
	        this.el = el;
	        this.getPropertyValue = function(prop) {
	            var re = /(\-([a-z]){1})/g;
	            if (prop == 'float') prop = 'styleFloat';
	            if (re.test(prop)) {
	                prop = prop.replace(re, function () {
	                    return arguments[2].toUpperCase();
	                });
	            }
	            return el.currentStyle[prop] ? el.currentStyle[prop] : null;
	        }
	        return this;
	    }
	}
}

/// Helper function for AdjustSizes to address special logic needs of interactive 
/// Column width resizing.
ClientMethod adjustSizesInColumnResize(sz) [ Internal, Language = javascript ]
{
	// use stashed values
	sz.rHdrWid = this._last_rHdrWid;
	sz.cHdrHgt = this._last_cHdrHgt;
	sz.cSumHgt = this._last_cSumHgt;
	sz.cbWid = this._last_cbWid;
	sz.cwid = this._last_cwid;
	sz.rhgt = this._last_rhgt;

	// apply new column width
	sz.firstCol = zenPage._columnIndex;
	sz.cwid[sz.firstCol] = this._columnWidths[sz.firstCol];
}

/// Helper method to service the Paging and Status DIVs when processing an 
/// AdjustSizes request.  Note: this call may change the value of sz.encHgt.
ClientMethod adjustSizesAreasPagingStatus(sz, pagingDiv, statusDiv) [ Internal, Language = javascript ]
{
	if (pagingDiv) {
		pagingDiv.innerHTML = this.getPagingHTML();

		var pagingInnerDiv = this.findElement('pagingDiv');
		if (pagingInnerDiv) {
			// slide paging buttons over
			pagingDiv.style.width = pagingInnerDiv.offsetWidth + 'px';
			if (pagingInnerDiv.offsetWidth > sz.encWid) {
				pagingDiv.style.display = 'none';
			}
			else {
				pagingDiv.style.display = 'block';
			}
		}
	}

	var statusHgt = statusDiv ? statusDiv.offsetHeight : 0;
	var pgHgt = (pagingDiv?pagingDiv.offsetHeight:0);
	
	statusHgt = statusHgt > pgHgt ? statusHgt : pgHgt;
	sz.encHgt -= statusHgt;
}

/// Helper function for adjustSizes.  This snippet walks over the column headers
/// to update the cwid entries of the sizing object based on attribute settings
/// or, in their absence, actual rendered avatars.  In addition, the column header height
/// cHdrHgt, is updated to reflect the maximum bounds of any of the cells visited.
ClientMethod adjustSizesColumnHeaders(sz, cols) [ Internal, Language = javascript ]
{
	var cDesc = this.getColumnDescriptors();
	var cDescIdx = 0;
	var cDescLen = 0;
	if (cDesc.length) cDescLen = cDesc.length;

	for (var c = 0; c < cols; c++) {

		// Check for default column guidance, keeping in mind not all columns
		// referenced in the columnDescripters are visible
		var desc = null;
		while (cDesc && cDescIdx<cDescLen && cDesc[cDescIdx].hidden ) cDescIdx++;
		if (cDescIdx < cDescLen) desc = cDesc[cDescIdx];
		cDescIdx++;

		var outer = this.findElement('ch_0_'+c);
		if (outer) {
			var cell = outer.firstChild;
			var cw = cell.offsetWidth;
			
			if (this._columnWidths && this._columnWidths[c]) {
				cw = this._columnWidths[c];
			}
			else {
				// If a manual override is not in effect, check to
				// see if there are any rendering hints in the column
				// descriptor.
				if (desc && desc.width && desc.width!="") {
					cw = parseInt(desc.width);
				}
				else {
					if (this.columnWidth!=='') {
						cw = parseInt(this.columnWidth,10);
					}
				}
			}
			sz.cwid[c] = cw;
			
			var ch = cell.offsetHeight;
			sz.cHdrHgt = (ch > sz.cHdrHgt) ? ch : sz.cHdrHgt;
		}
	}
}

/// Helper function for adjustSizes.  This snippet walks over the rows and row headers
/// to update the rhgt and rHdrWid entries of the sizing object based on attribute settings
/// or, in their absence, actual rendered avatars.  
ClientMethod adjustSizesRowHeaders(sz, rows, hdrLabels) [ Internal, Language = javascript ]
{
	// row header labels (in nub)
	var hlLen = hdrLabels.length;
	if (hlLen) {
		for (var hx = 0; hx < hlLen; hx++) {
			var outer = this.findElement('nub_'+hx);
			if (outer) {
				var cell = outer.firstChild;
				var rw = cell.offsetWidth;
				sz.rHdrWid[hx] = (rw > sz.rHdrWid[hx]) ? rw : sz.rHdrWid[hx];
			}
		}
	}
	for (var r = 0; r < rows; r++) {
		var d = 0;
		var searchId = 'rh_'+d+'_'+r;
		if (this.showRowLabels==false) searchId = 'c_'+r+':'+d;
		var outer = this.findElement(searchId);
		while (outer) {
			var cell = outer.firstChild;
			var rh = cell.offsetHeight;
			if (sz.rHdrHgt>0) rh = sz.rHdrHgt;

			sz.rhgt[r] = rh;
			var rw = cell.offsetWidth;
			sz.rHdrWid[d] = (rw > sz.rHdrWid[d]) ? rw : sz.rHdrWid[d];
			d++;
			var searchId = 'rh_'+d+'_'+r;
			if (this.showRowLabels==false) searchId = 'c_'+r+':'+d;
			var outer = this.findElement(searchId);
		}
	}
}

/// Helper function for adjustSizes.  This snippet walks over various elements that comprise
/// the summary row, sets the attribute cSumHgt and may upwardly adjust the values of
/// cwid and rHdrHgt depending on current values and its own rendering needs.
ClientMethod adjustSizesSummaryRow(sz, cols) [ Internal, Language = javascript ]
{
	var outer = this.findElement('rh_sum');
	if (outer) {
		var cell = outer.firstChild;
		var rh = cell.offsetHeight;
		sz.cSumHgt = rh;
		var rw = cell.offsetWidth;
		sz.rHdrWid[0] = (rw > sz.rHdrWid[0]) ? rw : sz.rHdrWid[0];
	}

	for (var c = 0; c < cols; c++) {
		var outer = this.findElement('sum_'+c);
		if (outer) {
			var cell = outer.firstChild;
			var cw = cell.offsetWidth;
			if (this._columnWidths && this._columnWidths[c]) {
				cw = this._columnWidths[c];
			}
			sz.cwid[c] = cw > sz.cwid[c] ? cw : sz.cwid[c];
			var ch = cell.offsetHeight;
			sz.cSumHgt = (ch > sz.cSumHgt) ? ch : sz.cSumHgt;
		}
	}
}

/// Helper function for adjustSizes.  This snippet walks over actual data cells
/// and may upwardly adjust the values of cwid and rhgt depending on current values
/// rendering needs.
ClientMethod adjustSizesDataCells(sz, cols, rows) [ Internal, Language = javascript ]
{
	for (var r = 0; r < rows; r++) {
		var rh = 0;
		for (var c = 0; c < cols; c++) {
			var outer = this.findElement('c_'+r+':'+c);
			if (outer) {
				var cell = outer.firstChild;
				var cw = cell.offsetWidth;
				if (this._columnWidths && this._columnWidths[c]) {
					cw = this._columnWidths[c];
				}
				var ch = cell.offsetHeight;
				sz.cwid[c] = (!sz.cwid[c] || cw > sz.cwid[c]) ? cw : sz.cwid[c];
				sz.rhgt[r] = (!sz.rhgt[r] || ch > sz.rhgt[r]) ? ch : sz.rhgt[r];
			}
		}
	}
}

/// Initialize sizing object with the current style contraints we need to satisfy
ClientMethod initializeSizingObject(inResize, encDiv, titleDiv) [ Internal, Language = javascript ]
{
	var sz = {};
	// try to find size of our border
	var style = window.getComputedStyle(encDiv,null);

	var bdLeft = parseInt(style.getPropertyValue("border-left-width"),10);
	var bdRight = parseInt(style.getPropertyValue("border-right-width"),10);
	var bdTop = parseInt(style.getPropertyValue("border-top-width"),10);
	var bdBottom = parseInt(style.getPropertyValue("border-bottom-width"),10);

	// set the high tide mark for the enclosing area, later processing my shrink these bounds
	sz.encHgt = encDiv.offsetHeight - (bdLeft + bdRight);
	sz.encWid = encDiv.offsetWidth - (bdTop + bdBottom);

	sz.colDepth = (this._columnDepth?this._columnDepth:1);
	sz.rowDepth = (this._rowDepth?this._rowDepth:1);

	// array of row label widths
	// 0 is innermost
	sz.rHdrWid = [];
	for (var rh = 0; rh < sz.rowDepth; rh++) {
		sz.rHdrWid[rh] = (this.rowLabelWidth=='') ? 0 : parseInt(this.rowLabelWidth,10);
	}

	// These will be set to more useful values in adjustSizesColumnHeaders
	sz.cHdrHgt = 0;

	var uHeight = this.extractUserStyleSetting(this.columnHeaderStyle,"height");
	if (uHeight && uHeight.indexOf("px")>0) {
		sz.cHdrHgt = parseInt(uHeight,10);
	}

	sz.cwid = [];

	sz.cSumHgt = 0;

	sz.rHdrHgt = 0;
	var uHeight = this.extractUserStyleSetting(this.rowHeaderStyle,"height");
	if (uHeight && uHeight.indexOf("px")>0) {
		sz.rHdrHgt = parseInt(uHeight,10);
	}
	if (this.rowHeight!='') {
		var rh = parseInt(this.rowHeight,10);
		if (rh>sz.rHdrHgt) sz.rHdrHgt = rh;
	}

	sz.rhgt = [];
	sz.firstCol = 0;

	sz.titleHgt = titleDiv ? titleDiv.offsetHeight : 0;

	// checkbox
	if (!inResize && this.showRowSelector) {
		var outer = this.findElement('ch_0_'+'cb');
		if (outer) {
			var cell = outer.firstChild;
			sz.cbWid = cell.offsetWidth;
		}
	}
	else {
		sz.cbWid = 0;
	}
	
	return(sz);
}

/// Adjust sizes of this component.
ClientMethod adjustSizes() [ Internal, Language = javascript ]
{
	try {
		var inResize = zenPage._componentIndex!=null && zenPage._columnIndex>=0;

		var controller = this.getController();
		var cols = this.getColumnCount();
		var rows = this.getRowsOnPage();
		var hdrLabels = this.getRowHeaderLabels();

		var encDiv = this.getEnclosingDiv();
		var titleDiv = this.findElement('title');

		// ie8 workaround
		if (!window.getComputedStyle) this.defineGetComputedStyle();

		// define a local object to facilitate passing geometry values between helper methods
		var sz = this.initializeSizingObject(inResize,encDiv,titleDiv);
	
		// if we are resizing columns, then use special logic
		if (inResize) this.adjustSizesInColumnResize(sz);

		// Status & Paging area ==================
		var pagingDiv = this.findElement('paging');
		var statusDiv = this.findElement('status');
		this.adjustSizesAreasPagingStatus(sz, pagingDiv,statusDiv);

		// get the row number (0-based) of the current visible top row.
		var offset = this.getRowOffset();

		if (!inResize) {
			// Find col header size and column widths
			this.adjustSizesColumnHeaders(sz,cols);
		
			// Find row header size and nub widths
			this.adjustSizesRowHeaders(sz,rows,hdrLabels);
		
			// find summary sizes;
			if (this.summaryRow) this.adjustSizesSummaryRow(sz, cols);

			// loop over rows; adjust heights and find widths of each column
			this.adjustSizesDataCells(sz, cols, rows);
		}

		// APPLICATION OF NEW SETTINGS STARTS...
		
		// hide main div so that we can apply styling more quickly
		// use hidden so that offsetSize will work!
		encDiv.style.visibility = 'hidden';

		// stash sizes so we can use them during column resize
		this._last_rHdrWid = sz.rHdrWid;
		this._last_cHdrHgt = sz.cHdrHgt;
		this._last_cSumHgt = sz.cSumHgt;
		this._last_cbWid = sz.cbWid;
		this._last_cwid = sz.cwid;
		this._last_rhgt = sz.rhgt;

		// now go back and apply sizes
		// column headers
		var cx = 0;
		if (this.showRowSelector) {
			var outer = this.findElement('ch_0_'+'cb');
			if (outer) {
				outer.style.left = cx + 'px';
				outer.style.width = (sz.cbWid-1) + 'px';
				outer.style.height = (sz.cHdrHgt-1) + 'px';
				var inner = outer.firstChild;
				if (inner.offsetHeight < outer.offsetHeight) {
					inner.style.top = (outer.offsetHeight-inner.offsetHeight)/2 + 'px';
				}
				else {
					inner.style.top = 0 + 'px';
				}
			}
			cx += sz.cbWid;
		}

		// column headers
		for (var c = 0; c < cols; c++) {
			if (c >= sz.firstCol) {
				var cInfo = this.getColumnInfo(c);
				var cInfo2 = cInfo;
				// visit every level of headers
				var d = 0;
				while (cInfo2) {
					var outer = this.findElement('ch_'+d+'_'+c);
					if (outer) {
						outer.style.left = cx + 'px';
						if (this.columnLabelSpan) {
							// span header over children
							var awid = 0;
							for (var aw = c; aw < c + (cInfo2._colSpan?cInfo2._colSpan:1); aw++) {
								awid += sz.cwid[aw];
							}
							outer.style.width = (awid-1) + 'px';
						}
						else {
							outer.style.width = (sz.cwid[c]-1) + 'px';
						}
						outer.style.top = sz.cHdrHgt*(cInfo2._depth?cInfo2._depth:0) + 'px';
						outer.style.height = ((sz.cHdrHgt)*(cInfo2._rowSpan?cInfo2._rowSpan:1)-1) + 'px';
						// center 
						var inner = outer.firstChild;
						if (outer.getAttribute('centered')) {
							inner.style.left = ((inner.offsetWidth < outer.offsetWidth) ? (outer.offsetWidth-inner.offsetWidth)/2 : 0) + 'px';
						}
						cInfo2 = cInfo2._parent;
					}
					else {
						cInfo2 = null;
					}
					d++;
				}
			}
			cx += sz.cwid[c];

			// resize handle
			if (c >= sz.firstCol) {
				var rsz = this.findElement('rsz_'+c);
				if (rsz) {
					rsz.style.left = (cx-2) + 'px';
					rsz.style.top = sz.cHdrHgt*(cInfo._depth?cInfo._depth:0) + 'px';
					rsz.style.height = (sz.cHdrHgt-1)*(cInfo._rowSpan?cInfo._rowSpan:1) + 'px';
				}
			}
		}

		// for convenience, offset for each level of row header
		var rOffset = [];
		var rx = 0;
		for (var rh = 0; rh<sz.rowDepth; rh++) {
			rOffset[rh] = rx;
			rx += sz.rHdrWid[sz.rowDepth-rh-1];
		}

		// row header labels (in nub)
		if (hdrLabels.length) {
			for (var hx = 0; hx < hdrLabels.length && hx < sz.rowDepth; hx++) {
				var outer = this.findElement('nub_'+hx);
				if (outer) {
					outer.style.width = sz.rHdrWid[sz.rowDepth - hx - 1] + 'px';
					outer.style.left = rOffset[hx] + 'px';
					outer.style.height = (sz.cHdrHgt-1) + 'px';
				}
			}
		}

		// row headers
		var cy = 0;
		for (var ri = 0; ri < rows; ri++) {
			var r = this._sortIndex ? this._sortIndex[ri+offset].row : ri+offset;
			var rInfo = this.getRowInfo(r);
			var rInfo2 = rInfo;

			// visit every level of headers
			var d = 0;
			while (rInfo2) {
				var outer = this.findElement('rh_'+d+'_'+ri);
				if (outer) {
					outer.style.top = cy + 'px';
					if (this.rowLabelSpan && this.sortColumn==0) {
						// span parent over children
						var ahgt = 0;
						// ri not r
						for (var ah = ri; ah < ri + (rInfo2._rowSpan?rInfo2._rowSpan:1); ah++) {
							ahgt += sz.rhgt[ah];
						}
						outer.style.height = (ahgt-1) + 'px';
					}
					else {
						// ri not r
						outer.style.height = (sz.rhgt[ri]-1) + 'px';
					}

					var awid = 0;
					var cspan = (rInfo2._colSpan?rInfo2._colSpan:1);
					var rdep = (rInfo2._depth?rInfo2._depth:0);
					for (var aw = rdep; aw < rdep + cspan; aw++) {
						awid += sz.rHdrWid[sz.rowDepth - aw - 1];
					}
					outer.style.width = awid + 'px';
					outer.style.left = rOffset[rdep] + 'px';

					var inner = outer.firstChild;
					if (inner.offsetHeight < outer.offsetHeight) {
						inner.style.top = (outer.offsetHeight-inner.offsetHeight)/2 + 'px';
					}
					else {
						inner.style.top = 0 + 'px';
					}
					// center
					if (outer.getAttribute('centered')) {
						inner.style.left = ((inner.offsetWidth < outer.offsetWidth) ? (outer.offsetWidth-inner.offsetWidth)/2 : 0) + 'px';
					}
					rInfo2 = rInfo2._parent;
				}
				else {
					rInfo2 = null;
				}
				d++;
			}
			// ri not r 
			cy += sz.rhgt[ri];
		}

		// cells
		var totalHgt = 0;
		var totalWid = 0;
		var cy = 0;
		var cbWidStr = (sz.cbWid-1) + 'px';
		for (var ri = 0; ri < rows; ri++) {
			var r = this._sortIndex ? this._sortIndex[ri+offset].row : ri+offset;
			var cx = 0;
			if (this.showRowSelector) {
				var outer = this.findElement('c_'+ri+':'+'cb');
				if (outer) {
					outer.style.top = cy + 'px';
					outer.style.left = cx + 'px';
					outer.style.width = cbWidStr;
					// ri not r
					outer.style.height = (sz.rhgt[ri]-1) + 'px';
					var inner = outer.firstChild;
					if (inner.offsetHeight < outer.offsetHeight) {
						inner.style.top = (outer.offsetHeight-inner.offsetHeight)/2 + 'px';
					}
					if (inner.offsetWidth < outer.offsetWidth) {
						inner.style.left = (outer.offsetWidth-inner.offsetWidth)/2 + 'px';
					}
				}
				cx += sz.cbWid;
				if (ri==0) {
					totalWid += sz.cbWid;
				}

			}
			for (var c = 0; c < cols; c++) {
				if (c >= sz.firstCol) {
					var outer = this.findElement('c_'+ri+':'+c);
					if (outer) {
						outer.style.top = cy + 'px';
						// ri not r
						outer.style.height = sz.rhgt[ri]-1 + 'px';
						outer.style.left = cx + 'px';
						outer.style.width = sz.cwid[c]-1 + 'px';
						var inner = outer.firstChild;
						if (inner.offsetHeight < outer.offsetHeight) {
							inner.style.top = (outer.offsetHeight-inner.offsetHeight)/2 + 'px';
						}
						// center 
						if (outer.getAttribute('centered')) {
							inner.style.left = ((inner.offsetWidth < outer.offsetWidth) ? (outer.offsetWidth-inner.offsetWidth)/2 : 0) + 'px';
						}
					}
				}
				cx += sz.cwid[c];
				if (ri==0) {
					totalWid += sz.cwid[c];
				}
			}
			/// ri not r
			cy += sz.rhgt[ri];
			totalHgt += sz.rhgt[ri];
		}

		// summary row
		if (this.summaryRow) {
			var outer = this.findElement('rh_sum');
			if (outer) {
				outer.style.top = '0px';
				outer.style.height = (sz.cSumHgt-1) + 'px';
				outer.style.width = (sz.rHdrWid[0]-1) + 'px';
				var inner = outer.firstChild;
				if (inner.offsetHeight < outer.offsetHeight) {
					inner.style.top = (outer.offsetHeight-inner.offsetHeight)/2 + 'px';
				}
			}

			var cx = 0;
			if (this.showRowSelector) {
				var outer = this.findElement('sum_cb');
				if (outer) {
					outer.style.left = cx + 'px';
					outer.style.width = (sz.cbWid-1) + 'px';
					outer.style.height = (sz.cSumHgt-1) + 'px';
					var inner = outer.firstChild;
					if (inner.offsetHeight < outer.offsetHeight) {
						inner.style.top = (outer.offsetHeight-inner.offsetHeight)/2 + 'px';
					}
				}
				cx += sz.cbWid;
			}

			for (var c = 0; c < cols; c++) {
				if (c >= sz.firstCol) {
					var outer = this.findElement('sum_'+c);
					if (outer) {
						outer.style.top = 0 + 'px';
						outer.style.left = cx + 'px';
						outer.style.width = (sz.cwid[c]-1) + 'px';
						outer.style.height = (sz.cSumHgt-1) + 'px';
					}
				}
				cx += sz.cwid[c];
			}
		}

		// adjust skeleton divs
		// adjust for border etc.
		var cellPadH = 1;
		var cellPadW = 1;

		var nubDiv = this.findElement('nub');
		var rhDiv = this.findElement('rowHdrs');
		var chDiv = this.findElement('colHdrs');
		var cellDiv = this.findElement('cells');
		var vtDiv = this.findElement('vtScroll');
		var hzDiv = this.findElement('hzScroll');
		var vtInnerDiv = this.findElement('vtScrollInner');
		var hzInnerDiv = this.findElement('hzScrollInner');
		var cellsInner = this.findElement('cellsInner');
		var sumDiv = this.findElement('summary');
		var sumHdrDiv = this.findElement('summaryHdr');

		var scrollWid = 22;
		var scrollHgt = 22;

		var colHeaderHgt = sz.cHdrHgt * sz.colDepth;
		var rowHeaderWid = 0;
		for (var rh = 0; rh < sz.rowDepth; rh++) {
			rowHeaderWid += sz.rHdrWid[rh];
		}
		var dataWid = sz.encWid > (rowHeaderWid+scrollWid) ? (sz.encWid-(rowHeaderWid+scrollWid)-4): 0;

		// if there are not enough rows to scroll, then place the summary
		// after the last rows, else make a gap between the cells and bottom scrollbar
		// and tuck it in there.
		var dataHgt = sz.encHgt > (sz.titleHgt+colHeaderHgt+scrollHgt+sz.cSumHgt) ? (sz.encHgt-(sz.titleHgt+colHeaderHgt+scrollHgt+sz.cSumHgt)-4): 0;

		if (totalHgt > dataHgt) {
			// place summary on bottom
			var summaryHgt = sz.cSumHgt;
			var summaryTop = sz.titleHgt + colHeaderHgt + dataHgt;
		}
		else {
			var summaryHgt = 0;
			var dataHgt = sz.encHgt > (sz.titleHgt + colHeaderHgt + scrollHgt + summaryHgt) ? (sz.encHgt-(sz.titleHgt + colHeaderHgt + scrollHgt + summaryHgt)-4): 0;
			var summaryTop = sz.titleHgt + colHeaderHgt + totalHgt;
		}

		// label resize handle
		var rsz = this.findElement('rszlabel');
		if (rsz) {
			rsz.style.top = sz.titleHgt + 'px';
			rsz.style.height = (colHeaderHgt) + 'px';
		}

		var nubDivTop = sz.titleHgt;
		var nubDivLeft = 0;
		var nubDivWid = rowHeaderWid;
		var nubDivHgt = colHeaderHgt;

		var chDivTop = sz.titleHgt;
		var chDivLeft = rowHeaderWid;
		var chDivWid = dataWid;
		var chDivHgt = colHeaderHgt;

		var rhDivTop = sz.titleHgt+colHeaderHgt;
		var rhDivLeft = 0;
		var rhDivWid = rowHeaderWid;
		var rhDivHgt = dataHgt;

		var dataDivTop = sz.titleHgt+colHeaderHgt;
		var dataDivLeft = rowHeaderWid;
		var dataDivWid = dataWid;
		var dataDivHgt = dataHgt;

		var sumHdrDivTop = summaryTop;
		var sumHdrDivLeft = 0;
		var sumHdrDivWid = rowHeaderWid;
		var sumHdrDivHgt = sz.cSumHgt;

		var sumDivTop = summaryTop;
		var sumDivLeft = rowHeaderWid;
		var sumDivWid = totalWid < dataDivWid ? totalWid : dataDivWid;
		var sumDivHgt = sz.cSumHgt;

		var vtDivTop = sz.titleHgt+colHeaderHgt;
		var vtDivLeft = dataDivLeft + dataDivWid;
		var vtDivWid = scrollWid;
		var vtDivHgt = dataHgt;

		var hzDivTop = dataDivTop + dataDivHgt + summaryHgt;
		var hzDivLeft = dataDivLeft;
		var hzDivWid = dataDivWid;
		var hzDivHgt = scrollHgt;

		if (titleDiv) {
			// !!!! 6?
			titleDiv.style.width = (rowHeaderWid+dataWid+scrollWid-6) + 'px';
		}
		if (statusDiv) {
			statusDiv.style.top = (hzDivTop + scrollHgt) + 'px';
			statusDiv.style.width = (rowHeaderWid+dataWid+scrollWid-6) + 'px';
		}

		if (nubDiv) {
			nubDiv.style.top = nubDivTop + 'px';
			nubDiv.style.left = nubDivLeft + 'px';
			nubDiv.style.width = nubDivWid + 'px';
			nubDiv.style.height = nubDivHgt + 'px';
		}
		if (rhDiv) {
			rhDiv.style.top = rhDivTop + 'px';
			rhDiv.style.left = rhDivLeft + 'px';
			rhDiv.style.width = rhDivWid + 'px';
			rhDiv.style.height = rhDivHgt + 'px';
		}
		if (chDiv) {
			chDiv.style.top =  chDivTop + 'px';
			chDiv.style.left = chDivLeft + 'px';
			chDiv.style.width = chDivWid + 'px';
			chDiv.style.height = chDivHgt + 'px';
		}
		if (sumDiv) {
			sumDiv.style.top =  sumDivTop + 'px';
			sumDiv.style.left = sumDivLeft + 'px';
			sumDiv.style.width = sumDivWid + 'px';
			sumDiv.style.height = sumDivHgt + 'px';
		}
		if (sumHdrDiv) {
			sumHdrDiv.style.top =  sumHdrDivTop + 'px';
			sumHdrDiv.style.left = sumHdrDivLeft + 'px';
			sumHdrDiv.style.width = sumHdrDivWid + 'px';
			sumHdrDiv.style.height = sumHdrDivHgt + 'px';
		}
		if (cellDiv) {
			cellDiv.style.top = dataDivTop + 'px';
			cellDiv.style.left = dataDivLeft + 'px';
			cellDiv.style.width = dataDivWid + 'px';
			cellDiv.style.height = dataDivHgt + 'px';

			var cellsUnderDiv = this.findElement('cellsUnder');
			if (cellsUnderDiv) {
				cellsUnderDiv.style.top = dataDivTop + 'px';
				cellsUnderDiv.style.left = dataDivLeft + 'px';
				cellsUnderDiv.style.width = dataDivWid + 'px';
				cellsUnderDiv.style.height = dataDivHgt + 'px';
			}
		}
		if (vtDiv) {
			vtDiv.style.top = vtDivTop + 'px';
			vtDiv.style.left = vtDivLeft + 'px';
			vtDiv.style.width = vtDivWid + 'px';
			vtDiv.style.height = vtDivHgt + 'px';
		}
		if (hzDiv) {
			hzDiv.style.top = hzDivTop + 'px';
			hzDiv.style.left = hzDivLeft + 'px';
			hzDiv.style.width = hzDivWid + 'px';
			hzDiv.style.height = hzDivHgt + 'px';
		}

		// scroll bars
		if (vtInnerDiv) {
			vtInnerDiv.style.height = totalHgt + 'px';
			vtDiv.style.opacity = totalHgt>vtDivHgt?1.0:0.5;
		}
		if (hzInnerDiv) {
			hzInnerDiv.style.width = totalWid + 'px';
			hzDiv.style.opacity = totalWid>hzDivWid?1.0:0.5;
		}

		// wheel handler
		if (cellsInner) {
			var handler = new Function('evt','zenPage.getComponent('+this.index+').wheelHandler(evt);');
		
			if (cellsInner.addEventListener) {
				cellsInner.addEventListener('DOMMouseScroll', handler, false);  
				cellsInner.addEventListener('mousewheel', handler, false);
			}
			else if(cellsInner.attachEvent) {
				cellsInner.attachEvent('onmousewheel', handler);
			}
		}

		if (this.currRow>0 && this.selectedRange=='' && 'rows' == this.selectMode) {
			var p = [this.currRow,1,this.currRow,this.getColumnCount()];
			this.selectedRange = p.join(',');
		}

		// render the div
		encDiv.style.display = 'block';
		encDiv.style.visibility = 'visible';

		this.highlightCells(true);
		if (this.selectedRange!='') {
			var p = this.selectedRange.split(',');
			this.moveCellSelector(p[0],p[1],p[2],p[3]);
		}
		else {
			this.moveCellSelector(this.currRow,this.currColumn);
		}

		// reveal
		encDiv.style.opacity = 1.0;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,this.lblErrorAdjustSizes);
	}
}

/// Return number of displayed rows in this grid.<br/>
/// If <var>filtered</var> (the default), return only filtered results.
ClientMethod getRowCount(filtered) [ Language = javascript ]
{
	if (this.pagingMode=='server') {
		var controller = this.getController();
		if (controller && controller.getRecordCount) {
			return controller.getRecordCount();
		}
		return 0;
	}
	filtered = 'undefined' == typeof filtered ? true : filtered;
	if (filtered && this.filterKey !='' && this._sortIndex) {
		return this._sortIndex.length;
	}

	return this._rowCount ? this._rowCount : 1;
}

/// Return number of displayed columns in this grid.
ClientMethod getColumnCount() [ Language = javascript ]
{
	return this._columnCount ? this._columnCount : 1;
}

/// Mouse wheel handler.
ClientMethod wheelHandler(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	var wheelDelta = evt.detail ? evt.detail * -1 : evt.wheelDelta;
	var vtScroll = this.findElement('vtScroll');
	if (vtScroll) {
		var c1 = this.findElement('cell_1:1');
		var d = c1 ? c1.offsetHeight : 40;
		vtScroll.scrollTop = vtScroll.scrollTop + ((wheelDelta>0) ? -d : d);
		this.cellScrollVt();
	}
}

/// Vertical Scroll handler.
ClientMethod cellScrollVt() [ Language = javascript ]
{
	var vtScroll = this.findElement('vtScroll');
	var bottomLeft = this.findElement('rowHdrs');
	var bottomRight = this.findElement('cells');
	if (bottomLeft && vtScroll) {
		bottomLeft.scrollTop = vtScroll.scrollTop;
	}
	if (bottomRight && vtScroll) {
		bottomRight.scrollTop = vtScroll.scrollTop;
	}
}

/// Horizontal Scroll handler..
ClientMethod cellScrollHz() [ Language = javascript ]
{
	var hzScroll = this.findElement('hzScroll');
	var topRight = this.findElement('colHdrs');
	var bottomRight = this.findElement('cells');
	var summary = this.findElement('summary');
	if (topRight && hzScroll) {
		topRight.scrollLeft = hzScroll.scrollLeft;
	}
	if (bottomRight && hzScroll) {
		bottomRight.scrollLeft = hzScroll.scrollLeft;
	}
	if (summary && hzScroll) {
		summary.scrollLeft = hzScroll.scrollLeft;
	}
}

/// Mouse double-click handler for column resize.
ClientMethod resizeMouseDblClick(evt, index) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (this._columnWidths) {
		delete this._columnWidths[index];
		this.adjustSizes();
	}
}

/// Mouse down handler for column resize.
ClientMethod resizeMouseDown(evt, index) [ Language = javascript ]
{
	// index < 0 is label resize
	evt = evt ? evt : window.event;
	if (evt.preventDefault) {
		evt.preventDefault();
	}

	// connect mouse handlers to window
	if (document.onmousemove != this.resizeMouseMove) {
		this._oldMouseMove = document.onmousemove;
		document.onmousemove = this.resizeMouseMove;
	}
	if (document.onmouseup != this.resizeMouseUp) {
		this._oldMouseUp = document.onmouseup;
		document.onmouseup = this.resizeMouseUp;
	}

	zenPage._startX = evt.clientX;
	if (index < 0) {
		var rnub = this.findElement('nub');
		if (rnub) {
			var rowDepth = (this._rowDepth?this._rowDepth:1);
			zenPage._startWid = rnub.offsetWidth/rowDepth;
		}
		else {
			zenPage._startWid = 0;
		}
	}
	else {
		var ch = this.findElement('ch_0_'+index);
		if (ch) {
			zenPage._startWid = ch.offsetWidth;
		}
	}
	zenPage._componentIndex = this.index;
	zenPage._columnIndex = index;
}

/// Mouse up handler for resize handle (connected to window).
ClientMethod resizeMouseUp(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;

	var index = zenPage._columnIndex;
	var dataGrid = zenPage._componentIndex===null?null:zenPage.getComponent(zenPage._componentIndex);

	// remove mouse handlers from window
	if (this._oldMouseMove) {
		document.onmousemove = this._oldMouseMove;
	}
	this._oldMouseMove = null;
	if (this._oldMouseUp) {
		document.onmouseup = this._oldMouseUp;
	}
	this._oldMouseUp = null;
	zenPage._componentIndex = null;
	zenPage._columnIndex = null;
	zenPage._startX = null;
	zenPage._startWid = null;

	if (dataGrid) {
		dataGrid.adjustSizes();
	}
}

/// Mouse move handler for column resize.
ClientMethod resizeMouseMove(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	var index = zenPage._columnIndex;
	var dataGrid = zenPage._componentIndex===null?null:zenPage.getComponent(zenPage._componentIndex);
	if (dataGrid) {
		if (index < 0) {
			dataGrid.rowLabelWidth = zenPage._startWid + (evt.clientX - zenPage._startX);
			dataGrid.adjustSizes();
		}
		else {
			var ch = dataGrid.findElement('ch_0_'+index);
			if (ch) {
				dataGrid._columnWidths[index] = zenPage._startWid + (evt.clientX - zenPage._startX);
				dataGrid._columnWidths[index] = dataGrid._columnWidths[index] <= 1 ? 1 : dataGrid._columnWidths[index];
				dataGrid.adjustSizes();
			}
		}
	}
}

/// Mouse down handler for selector resize.
ClientMethod sizeHandleMouseDown(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;

	// connect mouse handlers to window
	if (document.onmousemove != this.resizeMouseMove) {
		this._oldMouseMove = document.onmousemove;
		document.onmousemove = this.sizeHandleMouseMove;
	}
	if (document.onmouseup != this.resizeMouseUp) {
		this._oldMouseUp = document.onmouseup;
		document.onmouseup = this.sizeHandleMouseUp;
	}

	zenPage._startX = evt.clientX;
	zenPage._startY = evt.clientY;
	zenPage._componentIndex = this.index;
	this._handleMove = true;
}

/// Mouse up handler for size handle (connected to window).
ClientMethod sizeHandleMouseUp(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;

	var dataGrid = zenPage._componentIndex===null?null:zenPage.getComponent(zenPage._componentIndex);
	dataGrid._handleMove = false;
	dataGrid.focus();

	// remove mouse handlers from window
	if (this._oldMouseMove) {
		document.onmousemove = this._oldMouseMove;
	}
	this._oldMouseMove = null;
	if (this._oldMouseUp) {
		document.onmouseup = this._oldMouseUp;
	}
	this._oldMouseUp = null;
	zenPage._componentIndex = null;
	zenPage._startX = null;
	zenPage._startY = null;
}

/// Mouse move handler for selector resize.
ClientMethod sizeHandleMouseMove(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;

	var dataGrid = zenPage._componentIndex===null?null:zenPage.getComponent(zenPage._componentIndex);
	if (dataGrid) {
		var deltaX = 40;
		var deltaY = 20;
		if (evt.clientX > (zenPage._startX + deltaX)) {
			dataGrid.selectCell(dataGrid.currRow,dataGrid.currColumn+1,false,true);
			zenPage._startX = evt.clientX;
		}
		else if (evt.clientX < (zenPage._startX - deltaX)) {
			dataGrid.selectCell(dataGrid.currRow,dataGrid.currColumn-1,false,true);
			zenPage._startX = evt.clientX;
		}
		if (evt.clientY > (zenPage._startY + deltaY)) {
			dataGrid.selectCell(dataGrid.currRow+1,dataGrid.currColumn,false,true);
			zenPage._startY = evt.clientY;
		}
		if (evt.clientY < (zenPage._startY - deltaY)) {
			dataGrid.selectCell(dataGrid.currRow-1,dataGrid.currColumn,false,true);
			zenPage._startY = evt.clientY;
		}
	}
}

/// Focus passed to the grid's invisible edit control.
ClientMethod gridKeyFocus() [ Language = javascript ]
{
	this.hasFocus = true;

	// highlight current cell
	this.selectCell(this.currRow,this.currColumn,false,true);
}

/// Focus taken from the grid's invisible edit control.
ClientMethod gridKeyBlur() [ Language = javascript ]
{
	this.hasFocus = false;

	// highlight current cell
	this.selectCell(this.currRow,this.currColumn,false,false);
}

/// Process keydown event within the grid's invisible edit control.
ClientMethod gridKeyDownHandler(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	var ret = true;

	var row = this.currRow;
	var col = this.currColumn;

	this._modKey = evt.ctrlKey;

	// test for user callback
	if ('' != this.onkeydown) {
		ret = zenFireEvent(this.index, this.onkeydown, 'onkeydown', evt);
		if (!ret) return ret;
	}

	// trap keys
	switch(evt.keyCode) {
	case zenENTER:
		ret = false;
		if (this.isCellEditable(row,col)) {
			this.editCell();
		}
		break;
	case zenF2:
		// start editing in F2 mode
		ret = false;
		if (this.isCellEditable(row,col)) {
			this.F2Mode = true;
			this.editCell(this.getCellEditData(row-1,col-1));
		}
		break;

	case zenPAGEUP:
		ret = false;
		this.prevPage();
		break;
	case zenPAGEDN:
		ret = false;
		this.nextPage();
		break;

	case zenEND:
		ret = false;
		this.moveToCell(evt.ctrlKey ? 'ctrl-end' : 'end',evt.shiftKey);
		break;

	case zenHOME:
		// home
		ret = false;
		this.moveToCell(evt.ctrlKey ? 'ctrl-home' : 'home',evt.shiftKey);
		break;

	case zenUP:
		ret = false;
		this.moveToCell('up',evt.shiftKey);
		break;
	case zenDOWN:
		ret = false;
		this.moveToCell('down',evt.shiftKey);
		break;
	case zenLEFT:
		ret = false;
		this.moveToCell('left',evt.shiftKey);
		break;
	case zenRIGHT:
		ret = false;
		this.moveToCell('right',evt.shiftKey);
		break;
	case zenDELETE:
		this.editCell('');
		break;
	case zenTAB:
		break;

	default:
		break;
	}

	if (!ret) {
		this.killEvent(evt);
	}

	return ret;
}

/// Process keypress event within the grid's invisible edit control.
ClientMethod gridKeyPressHandler(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	var ret = true;

	var row = this.currRow;
	var col = this.currColumn;

	// test for user callback
	if ('' != this.onkeypress) {
		ret = zenFireEvent(this.index, this.onkeypress, 'onkeypress', evt);
		if (!ret) return ret;
	}
	// JMD809
	if (evt.ctrlKey || evt.altKey) {
	}
	else {
		var charCode = ('undefined' == typeof evt.charCode) || (evt.charCode===null) ? evt.keyCode : evt.charCode;
		// start editing on keypress
		if (charCode >= 32) {
			ret = false;
			if (this.isCellEditable(row,col)) {
				var seed = charCode ? String.fromCharCode(charCode) : null;
				this.editCell(seed);
			}
		}
	}

	if (!ret) {
		this.killEvent(evt);
	}

	return ret;
}

/// Process key up event within the grid's cell edit control.
ClientMethod cellEditKeyUpHandler(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	var ret = true;
	if ('' != this.oneditkeyup) {
		ret = zenFireEvent(this.index, this.oneditkeyup, 'oneditkeyup', evt);
	}
	return ret;
}

/// Process keys pressed within the grid's cell edit control.
ClientMethod cellEditKeyHandler(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	var ret = true;

	/* !!!
	if ('' != this.oneditkeydown) {
		ret = zenFireEvent(this.index, this.oneditkeydown, 'oneditkeydown', evt);
		if (!ret) {
			return false;
		}
	}
	*/

	this._modKey = false;

	// trap keys
	switch(evt.keyCode) {
	case zenF2:
		ret = false;
		this.F2Mode = !this.F2Mode;
		break;

	case zenUP:
		ret = false;
		this.stopEditCell(false);
		this.moveToCell('up');
		this.focus();
		break;
	case zenDOWN:
		ret = false;
		this.stopEditCell(false);
		this.moveToCell('down');
		this.focus();
		break;
	case zenLEFT:
		// left: ignore if F2 mode or 1 column
		if (!this.F2Mode) {
			ret = false;
			this.stopEditCell(false);
			this.moveToCell('left');
			this.focus();
		}
		break;
	case zenRIGHT:
		// right: ignore if F2 mode or 1 column
		if (!this.F2Mode) {
			ret = false;
			this.stopEditCell(false);
			this.moveToCell('right');
			this.focus();
		}
		break;

	case zenESC:
		ret = false;
		this.stopEditCell(true);
		this.focus();
		break;

	case zenENTER:
		ret = false;
		this.stopEditCell(false);
		this.focus();
		break;
	}

	if (!ret) {
		this.killEvent(evt);
	}		

	return ret;
}

/// Client-side method to give input focus to this control.
ClientMethod focus() [ Language = javascript ]
{
	if (this._popupVisible) {
		return;
	}

	// give focus to invisible control
	var inv = this.findElement('invisible');
	if (inv) {
		setTimeout("document.getElementById('"+inv.id+"').focus();",100)
	}
}

/// Move to a new, editable, cell. <var>dir</var> is "up","down","left","right","end",or "home".
/// Returns true if move was successful.<br/>
/// <var>updateRange</var> indicates that we are in "select range" mode.
ClientMethod moveToCell(dir, updateRange) [ Language = javascript ]
{
	var ret = false;
	updateRange = 'undefined' == typeof updateRange ? false : updateRange;

	var row = this.currRow;
	var col = this.currColumn;
	var colCount = this.getColumnCount();
	var rowCount = this.getRowsOnPage();

	switch(dir) {
	case 'up':
		row--;
		while (row > 0) {
			if (this.isCellVisible(row,col)) {
				if (col >= 0) {
					this.selectCell(row,col,true,updateRange);
				}
				ret = true;
				break;
			}
			row--;
		}
		break;
	case 'down':
		row++;
		while (row <= rowCount) {
			if (this.isCellVisible(row,col)) {
				if (col >= 0) {
					this.selectCell(row,col,true,updateRange);
				}
				ret = true;
				break;
			}
			row++;
		}
		break;
	case 'left':
		col--;
		while (col > 0) {
			if (this.isCellVisible(row,col)) {
				if (row < 0) {
					//this.columnLabelHandler(col);
				}
				else {
					this.selectCell(row, col,true,updateRange);
				}
				ret = true;
				break;
			}
			col--;
		}
		break;
	case 'right':
		col++;
		while (col <= colCount) {
			if (col>0 && this.isCellVisible(row,col)) {
				if (row >= 0) {
					this.selectCell(row, col,true,updateRange);
				}
				ret = true;
				break;
			}
			col++;
		}
		break;
	case 'home':
		row = 1;
		while (row < rowCount) {
			if (this.isCellVisible(row,col)) {
				if (col >= 0) {
					this.selectCell(row, col,true,updateRange);
				}
				ret = true;
				break;
			}
			row++;
		}
		break;
	case 'end':
		row = rowCount;
		while (row > 0) {
			if (this.isCellVisible(row,col)) {
				if (col >= 0) {
					this.selectCell(row, col,true,updateRange);
				}
				ret = true;
				break;
			}
			row--;
		}
		break;
	case 'ctrl-home':
		col = 1;
		while (col < colCount) {
			if (this.isCellVisible(row,col)) {
				if (row >= 0) {
					this.selectCell(row, col,true,updateRange);
				}
				ret = true;
				break;
			}
			col++;
		}
		break;
	case 'ctrl-end':
		col = colCount;
		while (col > 0) {
			if (this.isCellVisible(row,col)) {
				if (row < 0) {
					//this.columnLabelHandler(col);
				}
				else {
					this.selectCell(row, col,true,updateRange);
				}
				ret = true;
				break;
			}
			col--;
		}
		break;
	}

	return ret;
}

/// Make the specified cell the current cell.<br/>
/// <var>row</var> and <var>col</var> are 1-based.<br/>
/// If <var>notify</var> is true, then raise an onSelectCell event.<br/>
ClientMethod selectCell(row, col, notify, updateRange) [ Language = javascript ]
{
	try {
		var oldRange = this.selectedRange;
		var newRange = this.selectedRange;

		if (this.multiSelect) {
			if (updateRange && '' != newRange) {
				// update size of selected range
				var p = newRange.split(',');
				if (parseInt(this.currRow,10) == parseInt(p[2],10)) {
					if (row >= p[0]) {
						p[2] = row;
					}
					else {
						p[0] = row;
					}
				}
				else {
					if (row <= parseInt(p[2],10)) {
						p[0] = row;
					}
					else {
						p[2] = row;
					}
				}
				if ('rows' == this.selectMode) {
					p[1] = 1;
					p[3] = this.getColumnCount();
				}
				else {
					if (this.currColumn == p[3]) {
						if (col >= parseInt(p[1],10)) {
							p[3] = col;
						}
						else {
							p[1] = col;
						}
					}
					else {
						if (col <= parseInt(p[3],10)) {
							p[1] = col;
						}
						else {
							p[3] = col;
						}
					}
				}
				newRange = p.join(',');
			}
			else {
				var p = [row,col,row,col];
				if ('rows' == this.selectMode) {
					p[1] = 1;
					p[3] = this.getColumnCount();
				}
				newRange = p.join(',');
			}
		}
		else if ('rows' == this.selectMode) {
			// selected range is entire row
			var p = [row,1,row,this.getColumnCount()];
			newRange = p.join(',');
		}
		else {
			newRange = '';
		}

		//if (oldRange != newRange) {
			this.highlightCells(false);
			this.selectedRange = newRange;
		//}

		// notify
		this.currRow = row;
		this.currColumn = col;
		if (notify) {
			this.selectCellHandler(row,col);
		}

		this.highlightCells(true);

		// move selector
		if (this.selectedRange!='') {
			var p = this.selectedRange.split(',');
			this.moveCellSelector(p[0],p[1],p[2],p[3]);
		}
		else {
			this.moveCellSelector(row,col);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,this.lblErrorSelectCell);
	}
}

/// Notification that user is about to move to a new cell.
ClientMethod selectCellHandler(r, c) [ Language = javascript ]
{
	zenInvokeCallbackMethod(this.onselectcell,this,'onselectcell','row',r,'col',c);
}

/// Notification that user has fired a cell action.
ClientMethod cellActionHandler(r, name, value) [ Language = javascript ]
{
	zenInvokeCallbackMethod(this.onaction,this,'onaction','row',r,'name',name,'value',value);
}

/// Hilight (or unhighlight) the current selected cell headers.
ClientMethod highlightCells(flag) [ Language = javascript ]
{
	if (this.selectedRange!='') {
		var p = this.selectedRange.split(',');
	}
	else {
		p = [this.currRow,this.currColumn,this.currRow,this.currColumn];
	}

	// row headers
	for (var r = parseInt(p[0],10); r<=parseInt(p[2],10);r++) {
		var outer = this.findElement('rh_0_'+(r-1));
		if (outer) {
			outer.className = flag ? 'dgHdrSelected' : 'dgHdr';
		}
	}
	// col headers
	// don't highlight if rows mode
	if (!flag || this.selectMode!='rows') {
		for (var c = parseInt(p[1],10); c<=parseInt(p[3],10);c++) {
			var outer = this.findElement('ch_0_'+(c-1));
			if (outer) {
				outer.className = flag ? 'dgHdrSelected' : 'dgHdr';
			}
		}
	}

	// selected cells

	// current cell
	var cellCurr = this.findElement('c_'+(parseInt(this.currRow,10)-1)+':'+(parseInt(this.currColumn,10)-1));
	if (cellCurr) {
		if (flag) {
			cellCurr.style.color = this.currCellColor;
			cellCurr.style.backgroundColor = this.currCellBackground;
		}
		else {
			// use overlay div to parse original style
			var div = this.findElement('overlay');
			if (div) {
 				var orig = cellCurr.getAttribute('origStyle');
				div.style.cssText = orig;
				cellCurr.style.color = div.style.color;
				cellCurr.style.backgroundColor = div.style.backgroundColor;
			}
		}
	}
}

/// Move the cell selector to the given cells (1-based).
ClientMethod moveCellSelector(startRow, startCol, endRow, endCol) [ Language = javascript ]
{
	endRow = zenGet(endRow,startRow);
	endCol = zenGet(endCol,startCol);

	var div = this.findElement('selector');
	if (!div) return;

	var szHandle = this.findElement('sizeHandle');
	var actionIcon = this.findElement('action');
	div.className = this.hasFocus||this._handleMove ? 'dgSelectorFocus' : 'dgSelector';

	var cellsDiv = this.findElement('cells');
	var vtScroll = this.findElement('vtScroll');
	var hzScroll = this.findElement('hzScroll');

	// turn off by default
	if (szHandle) {
		szHandle.style.display = 'none';
	}
	if (actionIcon) {
		actionIcon.style.display = 'none';
	}

	if (startRow <= 0 || startCol <= 0) {
		div.style.display = 'none';
		// reset scroll
		cellsDiv.scrollTop = 0;
		cellsDiv.scrollLeft = 0;
		
		vtScroll.scrollTop = 0;
		hzScroll.scrollLeft = 0;
	}
	else {
		var cellTL = this.findElement('c_'+(startRow-1)+':'+(startCol-1));
		if (!cellTL) {
			div.style.display = 'none';
		}
		else {
			div.style.display = 'block';
			if (endRow == startRow && endCol == startCol) {
				var cellBR = cellTL;
			}
			else {
				var cellBR = this.findElement('c_'+(endRow-1)+':'+(endCol-1));
			}
			if (cellTL&&cellBR) {
				var top = cellTL.offsetTop;
				var left = cellTL.offsetLeft;
				var hgt = (cellBR.offsetTop - cellTL.offsetTop) + cellBR.offsetHeight;
				var wid = (cellBR.offsetLeft - cellTL.offsetLeft) + cellBR.offsetWidth;

				div.style.top = top-1 + 'px';
				div.style.left = left-1 + 'px';
				div.style.width = wid-2 + 'px';
				div.style.height = hgt-2 + 'px';

				if (szHandle) {
					szHandle.style.display = 'block';
					szHandle.style.top = top+hgt-3 + 'px';
					szHandle.style.left = left+wid-3 + 'px';
				}

				// scroll curr cell into view (if needed)
				var cellCurr = this.findElement('c_'+(parseInt(this.currRow,10)-1)+':'+(parseInt(this.currColumn,10)-1));
				if (cellCurr) {

					if (actionIcon) {
						var cInfo = this.getColumnInfo(parseInt(this.currColumn,10)-1);
						if (!cInfo || cInfo.type != 'lookup' || cInfo.readOnly) {
							actionIcon.style.display = 'none';
						}
						else {
							actionIcon.style.display = 'block';
							actionIcon.style.top = cellCurr.offsetTop + 'px';
							actionIcon.style.left = (cellCurr.offsetLeft + cellCurr.offsetWidth - actionIcon.offsetWidth) + 'px';
							actionIcon.style.height = (cellCurr.offsetHeight-2) + 'px';
						}	
					}
					var top = cellCurr.offsetTop;
					var bottom = cellCurr.offsetTop + cellCurr.offsetHeight;
					if (bottom > (cellsDiv.offsetHeight+cellsDiv.scrollTop)) {
						cellsDiv.scrollTop = (bottom - cellsDiv.offsetHeight);
						vtScroll.scrollTop = (bottom - cellsDiv.offsetHeight);
					}
					else if (top < cellsDiv.scrollTop) {
						cellsDiv.scrollTop = top;
						vtScroll.scrollTop = top;
					}

					var left = cellCurr.offsetLeft;
					var right = cellCurr.offsetLeft + cellCurr.offsetWidth;
					if (right > (cellsDiv.offsetWidth+cellsDiv.scrollLeft)) {
						cellsDiv.scrollLeft = (right - cellsDiv.offsetWidth);
						hzScroll.scrollLeft = (right - cellsDiv.offsetWidth);
					}
					else if (left < cellsDiv.scrollLeft) {
						cellsDiv.scrollLeft = left;
						hzScroll.scrollLeft = left;
					}
				}
			}
		}
	}
}

/// Handler for the dynamic cell editor control to allow the user to
/// click the mouse to initially position the cursor and, thereafter,
/// use left and right arrow keys to move within the edited string.
ClientMethod cellInputClickHandler(event) [ Internal, Language = javascript ]
{
	this.F2Mode = true;
	this.killEvent(event);
}

/// Display edit control in the current cell.
/// If <var>defval</var> is defined, then use it as the initial value in the editor.
/// <var>which</var> indicates what type of cell is being edited: "row" (row label), "column" 
/// (column label), otherwise a data cell.
ClientMethod editCell(defval, which) [ Language = javascript ]
{
	var value;
	var r = parseInt(this.currRow,10);
	var c = parseInt(this.currColumn,10);
	which = ('undefined'==typeof which) ? 'cell' : which;
	defval = ('undefined'==typeof defval) ? null : defval;

	if ((which=='cell') && !this.isCellEditable(r,c)) {
		// not editable
		return;
	}

	var cellCurr = null;
	if (r > 0 && c > 0) {
		switch(which) {
		case 'row':
			break;
		case 'column':
			break;
		default:
			cellCurr = this.findElement('c_'+(r-1)+':'+(c-1));
			value = defval ? defval : this.getCellEditData(r-1,c-1);
			break;
		}

		this.currEditType = which;
		var div = this.getCellSelector();

		// create edit control within the selector
		if (cellCurr && div) {
			var isLookup = false;
			var cInfo = this.getColumnInfo(c-1);
			var type = cInfo.type ? cInfo.type : 'string';

			var html = [];
			switch(type) {
			case 'lookup':
				this.showPopup();
				break;
			case 'image':
				break;
			case 'string':
			default:
				html[html.length] = '<input id="'+this.makeId('cellEditor')+'" class="dgCellEditor" type="text" onclick="zenPage.getComponent('+this.index+').cellInputClickHandler(event);" onkeydown="zenPage.getComponent('+this.index+').cellEditKeyHandler(event);" onkeyup="zenPage.getComponent('+this.index+').cellEditKeyUpHandler(event);" onblur="zenPage.getComponent('+this.index+').cellEditBlur();"/>';

				break;
			}
			div.innerHTML = html.join('');

			var celledit = this.getCellEditor();
			if (celledit) {
				celledit.value = value;

				celledit.style.width = cellCurr.clientWidth-1 + 'px';
				celledit.style.height = cellCurr.clientHeight-1 + 'px';
				var inner = cellCurr.firstChild;
				if (inner) {
					celledit.style.fontFamily = cellCurr.style.fontFamily;
					celledit.style.fontSize = inner.style.fontSize;
					celledit.style.color = cellCurr.style.color;
				}

				celledit.style.padding = '0px';

				this.cellHasFocus = true;

				// give focus to control
				if (celledit.focus) {
					celledit.focus();
				}
				// force cursor to end of control
				if (defval) {
					if (celledit.setSelectionRange) {
						var ln = value.toString().length;
						celledit.setSelectionRange(ln,ln);
					}
					else { // ie!
						celledit.value = celledit.value;
					}
				}
				// select
				if (!defval && celledit.select) {
					celledit.select();
				}
			}
		}
	}
}

/// Focus taken from the grid's cell edit control.
ClientMethod cellEditBlur() [ Language = javascript ]
{
	this.stopEditCell();
}

/// Stop editing of the current cell.<br>
/// If <var>cancel</var> is true, then do not save current control value.
ClientMethod stopEditCell(cancel) [ Language = javascript ]
{
	cancel = (null==cancel) ? false : cancel;
	var value;
	var type = 'cell';

	var div = this.getCellSelector();
	if (div && this.cellHasFocus) {
		// get rid of edit control in cell; save value
		this.cellHasFocus = false;
		this.F2Mode = false;
		var cell = this.getCellEditor();
		if (cell) {
			switch(this.currEditType) {
			case 'row':
				break;
			case 'column':
				break;
			default:
				value = cancel ? (this.getCellValue(parseInt(this.currRow,10)-1,parseInt(this.currColumn,10)-1)) : cell.value;
				if (!cancel) {
					// invoke cell onchangecell callback, if present
					if (this.onchangecell) {
						var ret = zenInvokeCallbackMethod(this.onchangecell,this,'onchangecell','value',value);
						if (ret!==null) {
							value = ret;
						}
						else {
							cancel = true;
						}
					}
				}
				if (!cancel) {
					this.setCellValue(value, parseInt(this.currRow,10) + this.getRowOffset() - 1, parseInt(this.currColumn,10) - 1);
				}
				break;
			}

		}
		div.innerHTML = '';
		this.currEditType = null;

		// invoke grid-wide onchange callback, if present
		if (!cancel && this.onchange) {
			zenInvokeCallbackMethod(this.onchange,this,'onchange','which',type);
		}

		// give focus back to invisible control
		this.focus();
	}
}

/// Return the html element for the current cell editor, if there is one.
ClientMethod getCellEditor() [ Language = javascript ]
{
	return this.findElement('cellEditor');
}

/// Return the html element for the current cell selector, if there is one.
ClientMethod getCellSelector() [ Language = javascript ]
{
	return this.findElement('selector');
}

/// Return whether a given cell can be edited; Row and column are 1-based.
ClientMethod isCellEditable(r, c) [ Language = javascript ]
{
	if ('rows' == this.selectMode || this.readOnly) {
		return false;
	}

	var canEdit = true;
	var cInfo = this.getColumnInfo(parseInt(c,10)-1);
	if (cInfo) {
		switch(cInfo.type) {
		case 'image':
		case 'button':
		case 'link':
		case 'checkbox':
			canEdit = false;
			break;
		default:
			canEdit = !cInfo.readOnly;
			break;
		}
	}
	return canEdit;
}

/// Return whether a given cell is visible; Row and column are 1-based.
ClientMethod isCellVisible(r, c) [ Internal, Language = javascript ]
{
	return true;
}

/// Mouse over for a cell.
ClientMethod cellMouseOver(row, col, evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if ('rows' == this.selectMode) {
		var startCol = 0;
		var endCol = this.getColumnCount();
	}
	else {
		var startCol = col-1;
		var endCol = startCol;
	}
	for (var c = startCol; c <= endCol; c++) {
		var outer = this.findElement('c_'+(row-1)+':'+(c));
		if (outer) {
			outer.style.backgroundColor = this.cellHoverColor;
		}
	}
}

/// Mouse out for a cell.
ClientMethod cellMouseOut(row, col, evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if ('rows' == this.selectMode) {
		var startCol = 0;
		var endCol = this.getColumnCount();
	}
	else {
		var startCol = col-1;
		var endCol = startCol;
	}
	for (var c = startCol; c <= endCol; c++) {
		var outer = this.findElement('c_'+(row-1)+':'+(c));
		if (outer) {
			// use overlay div to parse original style
			var div = this.findElement('overlay');
			if (div) {
 				var orig = outer.getAttribute('origStyle');
				div.style.cssText = orig;
				outer.style.backgroundColor = div.style.backgroundColor;
			}
		}
	}
}

/// User has clicked on the cell selector.
ClientMethod selectorClickHandler(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	this.focus();
}

/// User has dbl-clicked on the cell selector.
ClientMethod selectorDblClickHandler(evt) [ Language = javascript ]
{
	this.cellDblClickHandler(this.currRow,this.currColumn,evt);
}

/// User has clicked on a cell.
ClientMethod cellClickHandler(row, col, evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	this.focus();
	this.selectCell(row,col,true,evt.shiftKey);
}

/// User has dbl-clicked on a cell.
ClientMethod cellDblClickHandler(row, col, evt) [ Language = javascript ]
{
	// invoke callback if present
	// if callback returns false do not edit cell
	var edit = true;
	if ('' != this.ondblclick) {
		edit = zenFireEvent(this.index, this.ondblclick, 'ondblclick', evt);
	}

	if (edit) {
		this.editCell();
	}
}

/// Build the client-side sort index for this grid.
/// This also takes care of filterKey filtering, if needed.
ClientMethod buildSortIndex() [ Internal, Language = javascript ]
{
	var col = parseInt(this.sortColumn,10)-1;
	var cc = this.getColumnCount();
	var okey = this.filterKey.toString();
	var key = this.filterKey.toString().toLowerCase();

	if ((col >= 0) || key!='') {
		// all rows
		this._sortIndex = [];
		var rows = this.getRowCount(false);
		for (var r = 0; r < rows; r++) {
			var include = true;
			if (key!='') {
				// test for inclusion
				include = false;
				for (c = 0; c < cc; c++) {
					var val = this.getCellValue(r,c);
					
					// test for callback
					if (this.onfiltercell!='') {
						var info = {
							row:r,
							col:c,
							value:val,
							key:okey
						};
						include = zenInvokeCallbackMethod(this.onfiltercell,this,'onfiltercell','info',info);
						if (include) {
							break;
						}
					}
					else if (val.toString().toLowerCase().indexOf(key)>=0) {
						include = true;
						break;
					}
				}
			}

			if (include) {
				this._sortIndex[this._sortIndex.length] = {row:r, value:col>=0?this.getCellValue(r,col):''};
			}
		}

		if (col >=0 && this._sortIndex.length>0) {
			this._sortIndex.sort(function(a,b) { return (a.value)>(b.value)?1:-1});
			if ('desc'==this.sortOrder) {
				this._sortIndex.reverse();
			}
		}
	}
}

/// Resolve all row descriptors for this grid into a set of row info objects that
/// are used for actual rendering.
ClientMethod buildRowIndex() [ Internal, Language = javascript ]
{
	this._rowDescIndex = null;
	this._rowLeafIndex = null;
	this._rowCount = 0;
	this._rowDepth = 1;
	
	var controller = this.getController();
	var dcount = this.getRowDescriptorCount();
	if (dcount<=0) {
		// if there are no row descriptors, do not build an index
		// we will consume rows directly from the data controller
		this._rowCount = controller ? controller.getDimSize(1) : 1;
	}
	else {
		// loop over descriptors; build index of visible rows
		// get array of leaf nodes to start
		var list = [];
		var dimInfo = { depth: 1 };
		var array = this.getRowDescriptors();
		this.buildRowLeafIndex(array,list,dimInfo,1,null);
		this._rowDepth = dimInfo.depth;

		// now build row index: map displayed row to info
		this._rowDescIndex = [];		
		for (var n = 0; n < list.length; n++) {
			var info = list[n];
			this._rowDescIndex[this._rowDescIndex.length] = info;
		}
		this._rowCount = this._rowDescIndex.length;
	}
}

/// Build a list of leaf row descriptors (with spanning headers if needed).
/// Return the number of leaf nodes.
ClientMethod buildRowLeafIndex(rowArray, list, dimInfo, depth, parent) [ Internal, Language = javascript ]
{
	var count = 0;
	for (var n = 0; n < rowArray.length; n++) {
		var info = rowArray[n];
		if (info) {
			info._colSpan = 1;	// set later
			info._depth = -1;

			info._key = depth+':'+n;
			info._parent = parent;

			if (info.rows && info.rows.length) {
				// recurse
				var cc = this.buildRowLeafIndex(info.rows,list,dimInfo,depth+1,info);
				count += cc;
				info._rowSpan = cc;
			}
			else {
				// leaf node
				list[list.length] = info;
				count++;
				if (depth>dimInfo.depth) {
					dimInfo.depth = depth;
				}
				info._rowSpan = 1;
			}
		}
	}

	// when complete, adjust colSpan and depth
	if (depth==1) {
		for (var n = 0; n<list.length; n++) {
			var info = list[n];

			// walk up chain of parents; build colspans
			var chain = [];
			var p = info;
			while (p) {
				chain[chain.length] = p;
				p = p._parent;
			}

			// walk down chain; add extra span to leaf
			for (j = chain.length-1; j>=0; j--) {
				var info = chain[j];
				info._depth = chain.length - j - 1;
				if (j > 0) {
					info._colSpan = 1;
				}
				else {
					info._colSpan = dimInfo.depth - chain.length + 1;
				}
			}
		}
	}
	return count;
}

/// Return the number of row descriptors.
ClientMethod getRowDescriptorCount() [ Language = javascript ]
{
	var array = this.getRowDescriptors();
	return array ? array.length : 0;
}

/// Return an object containing the descriptor for row <var>r</var> (0-based).
/// <var>r</var> is an index into the actual set of row descriptors.
ClientMethod getRowDescriptor(r) [ Language = javascript ]
{
	var array = this.getRowDescriptors();
	return array ? array[r] : null;
}

/// Return an array of row descriptors (or null).
ClientMethod getRowDescriptors() [ Language = javascript ]
{
	// some data controller (pivots) can supply descriptor info
	var controller = this.getController();
	if (controller && controller.getRowDescriptors) {
		return controller.getRowDescriptors();
	}
	return this.rowDescriptors;
}

/// Return an array of column descriptors (or null).
ClientMethod getColumnDescriptors() [ Language = javascript ]
{
	// some data controllers (pivots) can supply descriptor info
	var controller = this.getController();
	if (controller && controller.getColumnDescriptors) {
		return controller.getColumnDescriptors();
	}
	return this.columnDescriptors;
}

/// Return an object containing display information for row <var>r</var> (0-based).
/// <var>r</var> is a resolved row number within the current page!!!.
ClientMethod getRowInfo(r) [ Language = javascript ]
{
	var rInfo = null;
	if (this._rowDescIndex) {
		rInfo = this._rowDescIndex[r];
	}
	else {
		var array = this.getRowDescriptors();
		rInfo = array ? array[r] : null;
	}

	if (rInfo) {
		// decorate
		rInfo._index = r;
	}
	else {
		var controller = this.getController();
		rInfo = { caption: controller?controller.getLabel(r,1):'', _index:r };
	}
	return rInfo;
}

/// Resolve all column descriptors for this grid into a set of column info objects that
/// are used for actual rendering.
ClientMethod buildColumnIndex() [ Internal, Language = javascript ]
{
	this._columnDescIndex = null;
	this._columnLeafIndex = null;
	this._columnCount = 0;
	this._columnDepth = 1;

	var controller = this.getController();
	var dcount = this.getColumnDescriptorCount();
	if (dcount<=0) {
		// if there are no descriptors, do not build an index
		// we will consume columns directly from the data controller
		this._columnCount = controller ? controller.getDimSize(2) : 1;
	}
	else {
		// loop over descriptors; build index of visible columns
		// get array of leaf nodes to start
		var list = [];
		var dimInfo = { depth: 1 };
		var array = this.getColumnDescriptors();
		this.buildColumnLeafIndex(array,list,dimInfo,1,null);
		this._columnDepth = dimInfo.depth;

		// now build column index: map displayed column to info
		this._columnDescIndex = [];
		for (var n = 0; n < list.length; n++) {
			var info = list[n];
			this._columnDescIndex[this._columnDescIndex.length] = info;
		}
		this._columnCount = this._columnDescIndex.length;
	}
}

/// Build a list of leaf node column descriptors.
/// Return the number of leaf nodes.
ClientMethod buildColumnLeafIndex(columnArray, list, dimInfo, depth, parent) [ Internal, Language = javascript ]
{
	var count = 0;
	for (var n = 0; n < columnArray.length; n++) {
		var info = columnArray[n];
		if (info && !info.hidden) {
			info._rowSpan = 0;	// set later
			info._depth = -1;

			info._key = depth+':'+n;
			info._parent = parent;

			if (info.columns && info.columns.length) {
				// recurse
				var cc = this.buildColumnLeafIndex(info.columns,list,dimInfo,depth+1,info);
				count += cc;
				info._colSpan = cc;
			}
			else {
				// leaf node
				list[list.length] = info;
				count++;
				if (depth>dimInfo.depth) {
					dimInfo.depth = depth;
				}
				info._colSpan = 1;
			}
		}
	}
	
	// when complete, adjust rowSpan and depth
	if (depth==1) {
		for (var n = 0; n<list.length; n++) {
			var info = list[n];

			// walk up chain of parents; build rowspans
			var chain = [];
			var p = info;
			while (p) {
				chain[chain.length] = p;
				p = p._parent;
			}

			// walk down chain; add extra span to leaf
			for (j = chain.length-1; j>=0; j--) {
				var info = chain[j];
				info._depth = chain.length - j - 1;
				if (j > 0) {
					info._rowSpan = 1;
				}
				else {
					info._rowSpan = dimInfo.depth - chain.length + 1;
				}
			}
		}
	}
	return count;
}

/// Return the number of column descriptors.
ClientMethod getColumnDescriptorCount() [ Language = javascript ]
{
	var array = this.getColumnDescriptors();
	return array ? array.length : 0;
}

/// Return an object containing the descriptor for column <var>c</var> (0-based).
/// <var>c</var> is an index into the actual set of column descriptors.
ClientMethod getColumnDescriptor(c) [ Language = javascript ]
{
	var array = this.getColumnDescriptors();
	return array ? array[c] : null;
}

/// Return an object containing display information for column <var>c</var> (0-based).
/// If there are nested columns, this always refers to the bottom-most set of columns.
ClientMethod getColumnInfo(c) [ Language = javascript ]
{
	var cInfo = null;
	if (this._columnDescIndex) {
		cInfo = this._columnDescIndex[c];
	}
	else {
		var array = this.getColumnDescriptors();
		cInfo = array ? array[c] : null;
	}

	if (cInfo) {
		// decorate
		cInfo._index = c;
	}
	else {
		var controller = this.getController();
		cInfo = { caption: controller?controller.getLabel(c,2):'', _index:c };
	}
	return cInfo;
}

/// Test if this grid is in "design" mode;.
ClientMethod getDesignMode() [ Internal, Language = javascript ]
{
	return false;
}

/// Return number of data "pages" within this grid.
ClientMethod getPageCount() [ Internal, Language = javascript ]
{
	var pageCount = 1;
	var pageSize = this.getPageSize();
	if (pageSize > 0) {
		var rows = this.getRowCount();
		pageCount = Math.ceil(rows / pageSize);
	}
	return pageCount;
}

/// Return number of rows on the current "page".
ClientMethod getRowsOnPage() [ Internal, Language = javascript ]
{
	var pageSize = this.getPageSize();
	if (pageSize <= 0) {
		var rows = this.getRowCount();
	}
	else {
		var rc = this.getRowCount();
		var currPage = this.getCurrPage();
		if (rc <= 0) {
			var rows = 0;
		}
		else if (currPage < this.getPageCount()) {
			var rows = pageSize;
		}
		else {
			var rows = rc % pageSize;
			rows = (rows <= 0) ? pageSize : rows;
		}
	}
	return rows;
}

/// Return size of data "pages" within this grid.
/// 0 indicates no paging is used.
ClientMethod getPageSize() [ Internal, Language = javascript ]
{
	if (this.pagingMode=='server') {
		var controller = this.getController();
		if (controller && controller.getPageSize) {
			return controller.getPageSize();
		}
		return 0;
	}
	return parseInt(this.pageSize,10);
}

/// Set the size of data "pages" within this grid.
/// 0 indicates no paging is used.
ClientMethod setPageSize(pageSize) [ Internal, Language = javascript ]
{
	this.pageSize = parseInt(pageSize,10);
	this.render();
}

/// Number of the current "page" when paging (1-based).
ClientMethod getCurrPage() [ Internal, Language = javascript ]
{
	if (this.pagingMode=='server') {
		var controller = this.getController();
		if (controller && controller.getCurrPage) {
			return controller.getCurrPage();
		}
		return 1;
	}
	return parseInt(this.currPage,10);
}

/// Set the current "page" when paging (1-based).
ClientMethod setCurrPage(page) [ Internal, Language = javascript ]
{
	page = parseInt(page,10);
	if (page < 1) {
		page = 1;
	}
	else if (page > this.getPageCount()) {
		page = this.getPageCount();
	}
	if (page != this.currPage) {
		if (this.pagingMode=='server') {
			var controller = this.getController();
			if (controller && controller.setCurrPage) {
				controller.setCurrPage(page);
			}
			this.currPage = page;
			if (controller.reloadContents) {
				controller.reloadContents();
			}
		}
		else {
			this.currPage = page;
			this.updateCells();
		}
	}
}

/// Show next page in grid.
ClientMethod nextPage() [ Language = javascript ]
{
	this.setCurrPage(parseInt(this.currPage,10) + 1);
}

/// Show previous page in grid.
ClientMethod prevPage() [ Language = javascript ]
{
	this.setCurrPage(parseInt(this.currPage,10) - 1);
}

/// When paging, return the row number (0-based) of the current visible top row.
ClientMethod getRowOffset() [ Internal, Language = javascript ]
{
	return (parseInt(this.currPage,10)-1) * parseInt(this.pageSize,10);
}

/// User has clicked on a row header.
ClientMethod rowClickHandler(evt, row) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	row = parseInt(row,10) + 1;

	var ok = true;
	if ('' != this.onheaderclick) {
		ok = zenInvokeCallbackMethod(this.onheaderclick,this,'onheaderClick','which','row','index',row);
	}

	if (ok) {
		// select this row
		this.highlightCells(false);
		var p = [row,1,row,this.getColumnCount()];
		this.selectedRange = p.join(',');
		this.selectCell(row,1,true,true);
	}
}

/// User has double-clicked on a row header.
ClientMethod rowDblClickHandler(evt, row) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
}

/// User has clicked on a column header.
ClientMethod columnClickHandler(evt, col) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	col = parseInt(col,10) + 1;
	var ok = true;
	if ('' != this.onheaderclick) {
		ok = zenInvokeCallbackMethod(this.onheaderclick,this,'onheaderClick','which','column','index',col);
	}

	if (ok) {
		// select this column
		this.highlightCells(false);
		var p = [1,col,this.getRowCount(),col];
		this.selectedRange = p.join(',');
		this.selectCell(1,col,true,true);
	}
}

/// User has double-clicked on a column header.
ClientMethod columnDblClickHandler(evt, col) [ Language = javascript ]
{
	evt = evt ? evt : window.event;

	// !!! test if this column can sort

	/* 
	if (colInfo && colInfo.disableSort) {
		// no sort, but invoke callback anyway
		if ('' != this.onheaderClick) {
			zenInvokeCallbackMethod(this.onheaderClick,this,'onheaderClick');
		}
		return;
	}
	*/

	if (this.sortColumn == (col+1)) {
		// change sort order
		switch (this.sortOrder) {
		case 'asc':
			this.sortOrder = 'desc';
			break;
		case 'desc':
			// end sort
			this.sortOrder = '';
			this.sortColumn = 0;
			break;
		default:
			this.sortOrder = 'asc';
			break;			
		}
	}
	else {
		// new column
		this.sortColumn = col+1;
		this.sortOrder = 'asc';
	}

	// !!! notify controller !!!
	if (this.sortMode == 'client') {
		this.updateCells(false,true);
	}
	return true;
}

/// Split a css value into the style values into styles for an inner and outer cell div.
ClientMethod splitStyle(style, info) [ Internal, Language = javascript ]
{
	var result = { inner:'', outer:'', background:'' };
	var enc = this.getEnclosingDiv();
	var encStyle = enc.style.cssText;

	// use div to pull apart styles
	enc.style.cssText = style;

	if (info && enc.style.textAlign!='') {
		info.textAlign = enc.style.textAlign;
	}

	if (enc.style.fontSize!='') {
		result.inner += 'font-size:' + enc.style.fontSize + ';';
		enc.style.fontSize = '';
	}
	if (enc.style.padding!='') {
		result.inner += 'padding:' + enc.style.padding + ';';
		enc.style.padding = '';
	}
	if (enc.style.margin!='') {
		result.inner += 'margin:' + enc.style.margin + ';';
		enc.style.margin = '';
	}

	if (enc.style.background!='') {
		background = enc.style.background;
	}

	// place all other styles into outer style
	result.outer = enc.style.cssText;

	// restore
	enc.style.cssText = encStyle;
	return result;
}

/// User click on a row selector check box.
ClientMethod cbClick(which) [ Internal, Language = javascript ]
{
	this.checkedRows = '';
	var rows = this.getRowsOnPage();

	var cbAll = this.findElement('cball');
	if (which=='all') {
		if (cbAll) {
			// !!! paging
			for (var r = 0; r < rows; r++) {
				var cb = this.findElement('cb_'+r);
				if (cb) {
					cb.checked = cbAll.checked;
				}
			}
			if (cbAll.checked) {
				this.checkedRows = 'all';
			}
		}		
	}
	else {
		if (cbAll) {
			cbAll.checked = false;
		}
		var list = [];
		for (var r = 0; r < rows; r++) {
			var cb = this.findElement('cb_'+r);
			if (cb && cb.checked) {
				list[list.length] = r + 1;
			}
		}
		this.checkedRows = list.join(',');
	}
	zenInvokeCallbackMethod(this.onselectrow,this,'onselectrow','range',this.checkedRows);
}

/// Display a message for this form.
ClientMethod showMessage(msg) [ Language = javascript ]
{
	this.showOverlay('<div class="dgMsg">'+msg+'</msg>');
}

/// Hide the message for this form.
ClientMethod hideMessage() [ Language = javascript ]
{
	this.hideOverlay();
}

/// Start "wait" state for this grid.
ClientMethod beginWait() [ Language = javascript ]
{
	this.showOverlay('<div class="dgWaitBox">'+this.lblWorking+'...</div>');
}

/// End "wait" state for this grid.
ClientMethod endWait() [ Language = javascript ]
{
	this.hideOverlay();
}

/// Show the given content in the overlay for this grid.
ClientMethod showOverlay(content) [ Language = javascript ]
{
	var div = this.findElement('overlay');
	if (div) {
		var encDiv = this.getEnclosingDiv();
		div.innerHTML = content;
		div.style.display = 'block';
		div.style.opacity = 1.0;
		div.style.top = encDiv.offsetHeight/3 - div.offsetHeight/2 + 'px';
		div.style.left = encDiv.offsetWidth/4 - div.offsetWidth/2 + 'px';
	}
}

/// Hide the overlay for this grid.
ClientMethod hideOverlay() [ Language = javascript ]
{
	var div = this.findElement('overlay');
	if (div) {
		div.innerHTML = '';
		div.style.opacity = 0.0;
		div.style.display = 'none';
	}
}

/// Notification that the dataController associated with this grid
/// has raised an event.
ClientMethod notifyViewHandler(reason, data1, data2, data3) [ Language = javascript ]
{
	switch(reason) {
	case 'dataChange':
		// data changed in dataController: data1 is name of property or null
		// this.updateCells();
		if (!this._inSetValue) {
			this.updateGrid(false);
		}
		break;
	case 'seriesChange':
		// default series changed in dataController.
		break;
	case 'modelChange':
		// model (meta-data) changed in dataController.
		this.updateGrid();
		break;
	}
}

/// Number of rows.
/// Part of formula provider API.
ClientMethod getCellRowCount() [ Internal, Language = javascript ]
{
	return this.getRowCount(false);
}

/// Number of columns.
/// Part of formula provider API.
ClientMethod getCellColumnCount() [ Internal, Language = javascript ]
{
	return this.getColumnCount();
}

/// Column name (0-based).
/// Part of formula provider API.
ClientMethod getCellColumnName(c) [ Internal, Language = javascript ]
{
	var cInfo = this.getColumnInfo(c);
	return cInfo && cInfo.name ? cInfo.name : '';
}

/// Get the value to display within the cell editor.
/// This is either the raw value (which may be a formula) or the resolved value
/// depending on the hasFormulas property.
ClientMethod getCellEditData(r, c) [ Internal, Language = javascript ]
{
	// map row to real row #
	r = parseInt(r,10) + this.getRowOffset();
	var rx = this._sortIndex ? this._sortIndex[r].row : r;

	if (this.hasFormulas) {
		return this.getCellData(rx,c);
	}
	else {
		return this.getCellValue(rx,c);
	}
}

/// Get raw cell value (0-based).
/// Part of formula provider API.
ClientMethod getCellData(r, c) [ Internal, Language = javascript ]
{
	var controller = this.getController();
	var cInfo = this.getColumnInfo(c);
	var value = '';
	if (cInfo && ('undefined'!=typeof cInfo.value) && cInfo.value!=='') {
		value = cInfo.value;
	}
	else if (controller) {
		value = controller.getData(r,c);
	}
	return value;
}

/// Get raw cell value from controller (row is 0-based).
/// Part of formula provider API.
ClientMethod getCellExternalData(r, prop) [ Internal, Language = javascript ]
{
	var controller = this.getController();
	var rx = this._sortIndex ? this._sortIndex[parseInt(r,10)].row : r;
	var value = controller ? controller.getDataByName(prop,rx) : '';
	return value;
}

/// Return the value (using the <property>valueColumn</property>) of the
/// given row (1-based).
ClientMethod getRowValue(row) [ Language = javascript ]
{
	var r = parseInt(row,10) - 1 + this.getRowOffset();
	var rx = this._sortIndex ? this._sortIndex[r].row : r;
	var c = parseInt(this.valueColumn,10) - 1;
	return this.getCellValue(rx,c);
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'value':
		this.value = value;
		break;

	case 'enclosingStyle':
		this.enclosingStyle = value;
		this.getEnclosingDiv().style.cssText = value;
		this.render();
		break;

	case 'readOnly':
	case 'disabled':
	case 'showColumnLabels':
	case 'showRowLabels':
	case 'showZebra':
	case 'showRowSelector':
	case 'canResizeColumns':
	case 'rowLabelSpan':
	case 'columnLabelSpan':
		value = value ? true : false;
		this[property] = value;
		this.render();
		break;
	case 'style':
	case 'selectMode':
	case 'currPage':
	case 'rowLabelWidth':
	case 'format':
	case 'style':
	case 'columnHeaderStyle':
	case 'rowHeaderStyle':
	case 'selectedRangeBackground':
	case 'selectedCellBackground':
	case 'selectedCellColor':
	case 'rowHeaderStyle':
	case 'rowHeight':
	case 'gridTitle':
	case 'gridTitleStyle':
	case 'evenRowBackground':
	case 'evenRowColor':
	case 'oddRowBackground':
	case 'oddRowColor':
	case 'columnWidth':
	case 'currCellColor':
	case 'currCellBackground':
		this[property] = value;
		this.render();
		break;
	case 'controllerId':
		// pass this change on to dataView
		this.setControllerId(value);
		break;

	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Display the dropdown popup window.<br/>
/// <var>spec</var> is an object with any of the following properties:<br/>
/// top - top edge of popup.<br/>
/// left - left edge of popup.<br/>
/// parentDiv - if supplied, use this to place the popup.<br/>
/// value - current logical value.<br/>
/// data - array of data elements to display; can be an array of objects or literal values.<br/>
/// propertyList - if data contains objects, this is a csv-list of properties to display.<br/>
/// idProperty - if data contains objects, this the name of the property supplying the id value.<br/>
/// textProperty - if data contains objects, this the name of the property supplying the display value.<br/>
/// title - title to display in popup.<br/>
/// applyValue - function to call a value is selected within the popup.<br/>
ClientMethod showPopup(spec) [ Language = javascript ]
{
	spec = spec ? spec : {};
	var value = zenGet(spec.value,'');
	var top = spec.top ? spec.top : null;
	var left = spec.left ? spec.left : null;

	spec.idProperty = spec.idProperty ? spec.idProperty : 'id';
	spec.textProperty = spec.textProperty ? spec.textProperty : 'text';

	var contextParms = {};

	// get info about current column
	var cInfo = this.getColumnInfo(this.currColumn - 1);
	if (cInfo) {
		contextParms.name = cInfo.name;
		contextParms.aux = cInfo.aux;
	}

	spec.data = zenInvokeCallbackMethod(this.ongetlookupdata,this,'ongetlookupdata','context',contextParms);

	if (spec.parentDiv) {
		top = zenGetTop(spec.parentDiv) + spec.parentDiv.offsetHeight - zenGetTopScroll(spec.parentDiv);
		left = zenGetLeft(spec.parentDiv) - zenGetLeftScroll(spec.parentDiv);
	}

	var hgt = zenGetWindowHeight();
	var dSpace = hgt-top;	
	var dropDownHgt = 275;

	if (dropDownHgt > dSpace) {
		top = hgt - dropDownHgt;
	}

	// create modal group; remember it for later use
	var group = this._group;
	if (!group) {
		group = zenPage.createComponent('modalGroup');
	}
	this._group = group;

	group.onshowGroup = 'zenPage.getComponent('+this.index+').showGroupHandler();';
	group.onhideGroup = 'zenPage.getComponent('+this.index+').hideGroupHandler();';

	// callback to get contents of the popup
	// pass spec to callback via group
	group._spec = spec
	var func = new Function('group','return zenPage.getComponent('+this.index+').getPopupContent(group);');

	this._applyFunction = null;
	if (spec.applyFunction && 'function' == typeof spec.applyFunction) {
		this._applyFunction = spec.applyFunction;
	}

	this._popupVisible = true;
	group.show(spec.title?spec.title:this.lblSearch,'callback',func,top,left);
}

/// Value applied from popup.
ClientMethod applyValue(value, text) [ Language = javascript ]
{
	if (this._applyFunction && 'function' == typeof this._applyFunction) {
		this._applyFunction(value,text);
		this._applyFunction = null;
	}
	else {
		var cancel = false;
		if (this.onchangecell) {
			var ret = zenInvokeCallbackMethod(this.onchangecell,this,'onchangecell','value',value);
			value = ret;
			if (ret==null) cancel = true;
		}
		var r = parseInt(this.currRow,10) + this.getRowOffset()-1;
		var c = parseInt(this.currColumn,10)-1;
		var currValue = this.getCellValue(r,c);
		if (!cancel && (value != currValue)) {
			this.setCellValue(value, r, c);
			if (this.onchange) {
				zenInvokeCallbackMethod(this.onchange,this,'onchange','which','cell');
			}
		}
	}
	zenPage.endModal();
}

/// Return the content for the popup/dropdown.
ClientMethod getPopupContent(group) [ Language = javascript ]
{
	var spec = group._spec;
	var html = [];

	// header
	var showFilter = true;
	var hstyle = showFilter ? 'white-space:nowrap;' : 'height:0px; width:0px; overflow:hidden; font-size:0px; line-height:0px';
	html[html.length] = '<div style="'+hstyle+'" nowrap="1">'

	// filter input control
	html[html.length] = '<input id="'+this.makeId('filter')+'" class="dgLookupFilter" onkeydown="return zenPage.getComponent('+this.index+').filterKeyDown(event);" onkeyup="return zenPage.getComponent('+this.index+').filterKeyUp(event);" type="text"/>';
	html[html.length] = '</div>';

	// search results
	html[html.length] = '<div id="'+this.makeId('lookupResults')+'" class="dgLookupResults" style="height:200px; overflow-x:auto;overflow-y:scroll;" id="'+this.makeId('results')+'">';
	html[html.length] = this.getLookupTableHTML(spec);
	html[html.length] = '</div>';

	var info = {
		style:'width:auto;background:#F0F0F0;',
		content: html.join('')
	};
	return info;
}

/// Get the HTML contents of the popup lookup table.
ClientMethod getLookupTableHTML(spec, filter) [ Internal, Language = javascript ]
{
	filter = zenGet(filter);
	filter = filter.toString().toLowerCase();
	var array = spec ? spec.data : null;
	var value = spec ? spec.value : null;

	// index of item within popup
	this._selectedIndex = -1;
	this._itemCount = 0;

	// map displayed row# to data row#
	this._rowIndex = [];

	var styles = null;
	if (spec.styleList && spec.styleList!=='') {
		styles = spec.styleList.toString().split(',');
	}

	var html = [];
	if (!array || !array.length) {
		html[html.length] = '<div>';
		html[html.length] = $$$Text('Nothing to show!');
		html[html.length] = '</div>';
	}
	else {
		html[html.length] = '<table id="'+this.makeId('table')+'" class="dgLookupResultTable" cellspacing="0" border="0" cellpadding="0">';
		for (var n = 0; n < array.length; n++) {
			var record = array[n];
			if ('object' == typeof record) {
				var id = spec.idProperty&&spec.idProperty!=='' ? record[spec.idProperty] : null;
				var text = spec.textProperty&&spec.textProperty!=='' ? record[spec.textProperty] : null;
				id = (null === id || 'undefined' == typeof id) ? n : id;
				text = (null === text || 'undefined' == typeof text) ? id : text;
				var image = spec.imageProperty&&spec.imageProperty!=='' ? record[spec.imageProperty] : null;
			}
			else {
				var id = record;
				var text = record;
				var image = null;
			}

			// get values to display
			var values = [];
			if ('object' == typeof record) {
				if (image) {
				}
				else if (spec.propertyList && spec.propertyList!=='') {
					// multiple values
					var t = spec.propertyList.toString().split(',');
					for (var i = 0; i < t.length; i++) {
						values[i] = record[t[i]];
					}
				}
				else {
					values[0] = text;
				}
			}
			else {
				values[0] = record;
			}

			// filter?
			var skip = false;
			if (filter!='') {
				skip = true;
				for (var i = 0; i < values.length; i++) {
					if (values[i].toString().toLowerCase().indexOf(filter)>=0) {
						skip = false;
						break;
					}
				}
			}

			if (!skip) {
				this._rowIndex[this._itemCount] = n;
				var cls = this._itemCount%2 ? 'dgLookupEven' : 'dgLookupOdd';
				if (id == value) {
					cls = 'dgLookupSelected';
					this._selectedIndex = this._itemCount;
				}

				html[html.length] = '<tr class="'+cls+'" id="'+this.makeId('tr_'+this._itemCount)+'" onclick="zenPage.getComponent('+this.index+').applyValue(\''+id+'\',\''+text+'\');">';

				if (image) {
					html[html.length] = '<td>' + '<image class="dgLookupImage" src="'+image+'"/>' + '</td>';
				}
				else {
					for (var i = 0; i < values.length; i++) {
						var style = styles&&styles[i] ? styles[i] : '';
						html[html.length] = '<td style="'+style+'">' + zenEscapeXML(values[i]) + '</td>';
					}
				}
				html[html.length] = '</tr>';
				this._itemCount++;
			}
		}
		html[html.length] = '</table>';
	}
	return html.join('');
}

/// Apply contents of filter control.
ClientMethod applyFilter() [ Internal, Language = javascript ]
{
	this._selectedIndex = -1;
	var ctrl = this.findElement('filter');
	if (ctrl) {
		var table = this.findElement('table');
		var tw = table ? table.offsetWidth : 150;

		var div = this.findElement('lookupResults');
		if (div) {
			div.innerHTML = this.getLookupTableHTML(this._group._spec,ctrl.value);
			div.scrollTop = 0;
			var table = this.findElement('table');
			if (table) {
				table.style.width = tw + 'px';
			}
		}
		ctrl.focus();
	}
}

/// Utility to stop the propagation of an event to other handlers
ClientMethod killEvent(evt) [ Internal, Language = javascript ]
{
	if (evt.preventDefault) {
		evt.preventDefault();
	}
	if (evt.stopPropagation) {
		evt.stopPropagation();
	}
	else {
		evt.cancelBubble = true;
	}
}

/// Keydown in popup.
ClientMethod filterKeyDown(evt) [ Internal, Language = javascript ]
{
	evt = evt ? evt : window.event;
	var ret = true;

	// trap keys
	switch(evt.keyCode) {
	case zenESC:
		ret = false;
		zenPage.endModal();
		break;
	case zenENTER:
		ret = false;
		var spec = this._group._spec;
		var array = spec ? spec.data : null;
		if (this._selectedIndex>=0 && array && array[this._selectedIndex]) {
			var rno = this._rowIndex[this._selectedIndex]
			var record = array[rno];
			if ('object' == typeof record) {
				var id = spec.idProperty&&spec.idProperty!=='' ? record[spec.idProperty] : null;
				var text = spec.textProperty&&spec.textProperty!=='' ? record[spec.textProperty] : null;
				id = (null === id) ? n : id;
				text = (null === text) ? id : text;
			}
			else {
				var id = record;
				var text = record;
			}
			this.applyValue(id,text);
		}
		break;
	case zenDOWN:
		var index = this._selectedIndex>=0 ? this._selectedIndex+1 : 0;
		if (index < this._itemCount) {
			this.selectPopupItem(index);
		}
		ret = false;
		break;
	case zenUP:
		var index = this._selectedIndex>=1 ? this._selectedIndex-1 : 0;
		if (index >= 0) {
			this.selectPopupItem(index);
		}
		ret = false;
		break;
	case zenPAGEUP:
		this.selectPopupItem(0);
		ret = false;
		break;
	case zenPAGEDN:
		this.selectPopupItem(this._itemCount - 1);
		ret = false;
		break;
	default:
		break;
	}

	if (!ret) {
		this.killEvent(evt);
	}

	return ret;
}

/// Key up in popup.
ClientMethod filterKeyUp(evt) [ Internal, Language = javascript ]
{
	evt = evt ? evt : window.event;
	var ret = true;

	// trap keys
	switch(evt.keyCode) {
	case zenESC:
	case zenENTER:
	case zenDOWN:
	case zenUP:
	case zenPAGEUP:
	case zenPAGEDN:
		ret = false;
		break;
	default:
		this.applyFilter();
		break;
	}

	return ret;
}

/// Notification that the popup group is displayed.
ClientMethod showGroupHandler() [ Language = javascript ]
{
	// adjust size of popup
	var div = this._group.getFloatingDiv();
	if (div) {
		var table = this.findElement('table');
		var tw = table ? table.offsetWidth : 150;
		if (tw < 150) {
			tw = 150;
			if (table) {
				table.style.width = tw + 'px';
			}
		}

		var sd = this.getSearchDiv();
		if (sd) {
			sd.style.width = tw + 20 + 'px';

			div.style.border = '5px solid rgb(53,107,141)';
			div.style.width = sd.offsetWidth + (10) + 'px';
			var ctrl = this.findElement('filter');
			if (ctrl) {
				ctrl.style.width = sd.offsetWidth<160?sd.offsetWidth-40:140 + 'px';
			}
		}
	}

	// give focus to popup
	var ctrl = this.findElement('filter');
	if (ctrl) {
		ctrl.focus();
	}

	// try to make selected item visible
	if (this._selectedIndex>=0) {
		this.selectPopupItem(this._selectedIndex);
	}
}

/// Notification that the popup group is hidden.
ClientMethod hideGroupHandler() [ Language = javascript ]
{
	this._popupVisible = false;
	this.focus();
}

/// Find the search results div (wrapper around lookup results table).
ClientMethod getSearchDiv() [ Internal, Language = javascript ]
{
	return this.findElement('lookupResults');
}

/// Select an item within the popup (used by keyboard handling).
ClientMethod selectPopupItem(index) [ Language = javascript ]
{
	if ('undefined' != typeof this._selectedIndex && this._selectedIndex>=0) {
		var tr = this.findElement('tr_'+this._selectedIndex);
		if (tr) {
			tr.className = index%2 ? 'dgLookupOdd' : 'dgLookupEven';
		}
	}

	this._selectedIndex = index;

	if (this._selectedIndex>=0) {
		var tr = this.findElement('tr_'+this._selectedIndex);
		if (tr) {
			tr.className = 'dgLookupSelected';
		}
	}

	// scroll item into view
	var div = this.findElement('dgLookupResults');
	if (tr && div) {
		var top = tr.offsetTop;
		var bottom = tr.offsetTop + tr.offsetHeight;
		if (bottom > (div.offsetHeight+div.scrollTop)) {
			div.scrollTop = (bottom - div.offsetHeight);
		}
		else if (top < div.scrollTop) {
			div.scrollTop = top;
		}
	}
}

/// Return the array of row header labels to be displayed in the upper left nub.
ClientMethod getRowHeaderLabels() [ Language = javascript ]
{
	var hdrLabels = [];
	var controller = this.getController();
	if (controller && controller.getRowCaptions) {
		hdrLabels = controller.getRowCaptions();
	}
	return hdrLabels;
}

/// Return the number of the current row (1 based).
ClientMethod getCurrRow() [ Language = javascript ]
{
	return parseInt(this.currRow,10);
}

/// Return the number of the current column (1 based).
ClientMethod getCurrColumn() [ Language = javascript ]
{
	return parseInt(this.currColumn,10);
}

}
