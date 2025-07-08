/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An editable grid control.<br/>
/// The data and size of the grid is provided by the
/// <class>%ZEN.Auxiliary.dataSet</class> associated with
/// the grid.<br/>
/// The first dimension of the dataSet supplies rows, the 
/// second supplies columns. The third dimension, if present,
/// supplies "pages" for the grid. (One page is visible at a time).
Class %ZEN.Component.dynaGrid Extends (control, dataView) [ Deprecated, System = 3 ]
{

/// Do not include in "form" module.
Parameter SYSMODULE;

/// Subclasses can set this to change default css class used for grids.
Parameter DEFAULTGRIDCLASS As STRING = "dynaGrid";

/// Default value for the <property>gridLabel</property> property.
Parameter DEFAULTGRIDLABEL As STRING;

/// Default value for the <property>rowLabelWidth</property> property in pixels.
Parameter DEFAULTROWLABELWIDTH As INTEGER = 100;

/// Default value for the <property>columnWidth</property> property in pixels.
Parameter DEFAULTCOLUMNWIDTH As INTEGER = 100;

/// Default value for the <property>showArrows</property> property.
Parameter DEFAULTSHOWARROWS As BOOL = 0;

/// Optional CSS class for the table containing the grid.
Property gridClass As %ZEN.Datatype.cssClass [ InitialExpression = {..#DEFAULTGRIDCLASS} ];

/// Data displayed by this grid control.
Property dataSet As %ZEN.Auxiliary.dataSet(ZENSETTING = 0);

/// Additional specification for columns within the grid.
Property columns As list Of %ZEN.Auxiliary.gridColumn(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE", ZENSETTING = 0);

/// Additional specification for rows within the grid.
Property rows As list Of %ZEN.Auxiliary.gridRow(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE", ZENSETTING = 0);

/// Additional specification for cells within the grid.
/// This allows cell-by-cell overrides of formats and styles.
Property cells As list Of %ZEN.Auxiliary.gridCell(XMLPROJECTION = "ELEMENT", XMLREF = 1, XMLTYPECONSTRAINT = "CHOICE", ZENSETTING = 0);

/// Caption to display in upper, left label cell. 
Property gridLabel As %ZEN.Datatype.caption [ InitialExpression = {..#DEFAULTGRIDLABEL} ];

/// If true, the user can double-click on row and column labels and edit their value.
Property editLabels As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Specifies whether column labels should be displayed.
Property showColumnLabels As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Width used for row labels. This may be specified as either a fixed width in pixels
/// or as a percentage of the total space allocated for the component.
Property rowLabelWidth As %ZEN.Datatype.length [ InitialExpression = {..#DEFAULTROWLABELWIDTH} ];

/// This is the default width (in pixels) used for columns that do not supply a width.
Property columnWidth As %ZEN.Datatype.length [ InitialExpression = {..#DEFAULTCOLUMNWIDTH} ];

/// Specifies whether row labels should be displayed.
Property showRowLabels As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Specifies whether the add rows and columns arrows should be displayed.
Property showArrows As %ZEN.Datatype.boolean [ InitialExpression = {..#DEFAULTSHOWARROWS} ];

/// onarrowclick event handler:
/// If defined, this event is fired when
/// the user clicks on a row or column arrow.
/// The variable which will indicate which arrow is clicked.
Property onarrowclick As %ZEN.Datatype.eventHandler;

/// This is the row number (1-based) of the current selected cell.
Property currRow As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// This is the column number (1-based) of the current selected cell.
Property currColumn As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// This specifies the current selected range of cells as a
/// comma-separated list of integers. The list is of the form:<br/>
/// startRow,startCol,endRow,endCol<br/>
/// All cells numbers are 1-based.<br/>
/// If the range is equal to "", then no cells are selected.<br/>
/// This is only used if <property>multiSelect</property> is true.
Property selectedRange As %ZEN.Datatype.csv;

/// If true, users can select a range of cells in the grid.
Property multiSelect As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// In case of 3-dimensional dataSet, this is the current
/// "page" (third dimension) being displayed. (1-based).
Property currPage As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// If true, use the zenScrollIntoView function to try and make the
/// current cell visible.<br>
Property scrollIntoView As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true (the default), then the contents of cells within the grid will not
/// word wrap (by setting the nowrap attribute for the cell's td element).
Property nowrap As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// oneditcell event handler:
/// If defined, this event is fired when
/// a cell is about to be edited.
/// If this event handler returns a value, then it is used
/// as DHTML to render the cell editor.
Property oneditcell As %ZEN.Datatype.eventHandler;

/// ondrawcell event handler:
/// If defined, this event is fired when
/// a cell is about to be drawn.
/// If this event handler returns a value, then it is used
/// as DHTML to render the cell contents.
Property ondrawcell As %ZEN.Datatype.eventHandler;

/// onchangecell event handler:
/// If defined, this event is fired when
/// the user changes the value of a cell.
Property onchangecell As %ZEN.Datatype.eventHandler;

/// onclickrow event handler:
/// If defined, this event is fired when
/// the user clicks on a row label.
Property onclickrow As %ZEN.Datatype.eventHandler;

/// onclickcolumn event handler:
/// If defined, this event is fired when
/// the user clicks on a column label.
Property onclickcolumn As %ZEN.Datatype.eventHandler;

/// onclicklabel event handler:
/// If defined, this event is fired when
/// the user clicks on grid label cell in the upper left.
Property onclicklabel As %ZEN.Datatype.eventHandler;

/// onselectcell event handler:
/// If defined, this event is fired when the user navigates to a new cell.<br/>
/// The current cell row and column number is updated before this call is made.<br/>
/// The event handler is passed 2 variables, <var>row</var> and <var>col</var>, which
/// contain the row and column number of the current cell (1-based).
Property onselectcell As %ZEN.Datatype.eventHandler;

/// ongetcellvalue event handler:
/// If defined, this event is fired to get the value to display in the current cell.<br/>
/// The current cell row and column number is updated before this call is made.<br/>
/// The event handler is passed 3 variables, <var>row</var> and <var>col</var>, which
/// contain the row and column number of the current cell (1-based); and <var>data</var>,
/// which is the value for the cell provided by the grid's data set.<br/>
/// If not defined or if this event return handler returns null, then the value from the
/// grid's data set is used.<br/>
/// This callback is also invoked when the value of a cell is directly set by 
/// the <method>setCellValue</method> method.<br/>
/// This is different than the <property>ondrawcell</property> event, which returns the actual HTML to display within a cell.
Property ongetcellvalue As %ZEN.Datatype.eventHandler;

/// onrender event handler:
/// If defined, this event is fired just before the grid is rendered.<br/>
Property onrender As %ZEN.Datatype.eventHandler;

/// ondblclick event handler:
/// This event is fired when the mouse is double-clicked on the control.
Property ondblclick As %ZEN.Datatype.eventHandler;

/// onkeyup event handler for default cell edit control.
Property oneditkeyup As %ZEN.Datatype.eventHandler;

/// onkeydown event handler for default cell edit control.
Property oneditkeydown As %ZEN.Datatype.eventHandler;

/// onchangepage event handler:
/// If defined, this event is fired when
/// the user clicks on the next or previous page buttons for a 3D grid.
/// If this callback returns false, the page change will not happen.
Property onchangepage As %ZEN.Datatype.eventHandler;

/// Name of Server-side callback method to call to information
/// for each node of this tree.<br>
/// This must be the name of a server-only method in the page
/// class that contains this component.
Property OnCreateDataSet As %ZEN.Datatype.delegator(FORMALSPEC = "pGrid:%ZEN.Component.dynaGrid,pDataSet:%ZEN.Auxiliary.dataSet", RETURNTYPE = "%Status");

/// Default format to apply to cells in this grid.<br/>
/// This is a DeepSee format string: e.g., "###.##"
/// This is overridden by row and column-level formatting.
Property format As %ZEN.Datatype.string;

/// Additional style to apply to cells in this grid.<br/>
/// This is applied before any row and column-level styles.
Property style As %ZEN.Datatype.style;

/// Additional style to apply to column headers in this grid.<br/>
Property columnHeaderStyle As %ZEN.Datatype.style;

/// Additional style to apply to row headers in this grid.<br/>
Property rowHeaderStyle As %ZEN.Datatype.style;

/// Specify whether cell borders should be "all" (the default) or "none".<br/>
Property borders As %ZEN.Datatype.string(VALUELIST = ",all,none") [ InitialExpression = "all" ];

/// Specify whether zebra striping should be applied to the grid.
Property showZebra As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Background color applied to the selected cell range.
Property selectedRangeBackground As %ZEN.Datatype.style [ InitialExpression = "rgb(87,138,168)" ];

/// Background color applied to the selected cell.
Property selectedCellBackground As %ZEN.Datatype.style [ InitialExpression = "rgb(47,98,128)" ];

/// Color applied to the selected cell range.
Property selectedCellColor As %ZEN.Datatype.style [ InitialExpression = "white" ];

/// defines style sheet used by this component.
XData Style
{
<style type="text/css">

/* @doc="Wrapper div for dynaGrid." */
.dynaGridWrapper {
	border: 1px solid black;
	overflow: hidden;
}

/* @doc="Main table for dynaGrid." */
table.dynaGrid {
	background: white;
	color: #404040;
	table-layout: fixed;
	padding: 0px;
	width: 100%;
}

/* @doc="Main table for disabled dynaGrid." */
table.dynaGridDisabled {
	background: #D0D0D0;
	color: #606060;
	table-layout: fixed;
	padding: 0px;
	width: 100%;
}

/* @doc="Label for dynaGrid." */
table.dynaGrid th.dynaGridLabel,
table.dynaGridDisabled th.dynaGridLabel {
	border-left: 1px solid gray;
	border-bottom: 1px solid gray;
	padding: 1px;
	padding-left: 3px;
	padding-right: 3px;
	cursor: pointer;
	background: #DDDDDD;
	text-align: left;
	white-space: nowrap;
	font-style: italic;
	overflow: hidden;
}

table.dynaGridDisabled th.dynaGridLabel {
	background: #DDDDDD;
}

/* @doc="Column labels for dynaGrid." */
table.dynaGrid th.dynaGridColumn,
table.dynaGridDisabled th.dynaGridColumn {
	border-left: 1px solid gray;
	border-bottom: 1px solid gray;
	padding: 1px;
	padding-left: 3px;
	padding-right: 3px;
	cursor: pointer;
	background: #DDDDDD;
	text-align: left;
	white-space: nowrap;
	overflow: hidden;
}

table.dynaGridDisabled th.dynaGridColumn {
	background: #DDDDDD;
}

table.dynaGrid tr.dynaGridRowEven {
	background: #F8F8F8;
}
table.dynaGrid tr.dynaGridRowOdd {
}

/* @doc="Row labels for dynaGrid." */
table.dynaGrid th.dynaGridRow,
table.dynaGridDisabled th.dynaGridRow {
	border-left: 1px solid gray;
	border-bottom: 1px solid gray;
	padding: 1px;
	padding-left: 3px;
	padding-right: 3px;
	cursor: pointer;
	background: #DDDDDD;
	text-align: left;
	white-space: nowrap;
	overflow: hidden;
}

table.dynaGridDisabled th.dynaGridRow {
	background: #DDDDDD;
}

/* @doc="Cells within dynaGrid." */
table.dynaGrid td,
table.dynaGridDisabled td {
	border-left: 1px solid gray;
	border-bottom: 1px solid gray;
	padding: 0px;
	margin: 0px;
	cursor: pointer;
	text-align: right;
}

table.dynaGrid td div, table.dynaGridDisabled td div {
	height: 100%;
	width: 90%;
	padding: 0px;
	padding-left: 2px;
	padding-right: 2px;
	margin: 0px;
	overflow: hidden;
	vertical-align: middle;
 	border: none;
}

/* @doc="Current cell with focus within dynaGrid." */
table.dynaGrid td div.focus {
	color: white;
	background: rgb(53,107,141);
}

/* @doc="Selected cell within dynaGrid." */
table.dynaGrid td div.selected {
	color: white;
	background: rgb(53,107,131);
}

/* @doc="Input control within dynaGrid." */
.dynaGridInput {
 	border: none;
	background: #FFFFA0;
}

/* @doc="Input control (with focus) within dynaGrid." */
.dynaGridInput:focus {
	background: #FFFFE0;
}

</style>
}

Method %OnNew(initvalue As %RawString) As %Status [ Private, ProcedureBlock = 1 ]
{
	#; make sure we have a dataSet property
	Set ..dataSet = ##class(%ZEN.Auxiliary.dataSet).%New(2)
	Do:$IsObject($G(%page)) %page.%AddComponent(..dataSet)
	Quit $$$OK
}

/// Client-side method to render this component.
ClientMethod renderContents() [ Language = javascript ]
{
	try {
		var controller = this.getController();
		if (null == controller) {
			// try to connect to dataController
			this.connectToController();
		}

		zenInvokeCallbackMethod(this.onrender,this,'onrender');

		var encDiv = this.getEnclosingDiv();
		// test if we have not been rendered yet
		if (encDiv == null) return;

		// build HTML for grid
		var html = new Array();

		// extra wrapper div to make ie happy
		html[html.length] = '<div id="'+this.makeId('wrapper')+'" class="dynaGridWrapper">';

		// use hidden control to make sure there is a value to submit
		html[html.length] = '<input type="hidden" id="'+this.makeId('control')+'" name="'+this.name+'" value="'+this.value+'"/>';

		var gcls = this.disabled ? 'dynaGridDisabled' : this.gridClass;
		html[html.length] = '<table id="'+this.makeId('table')+'" class="'+gcls+'" border="0" cellspacing="0" cellpadding="0">';

		var dataSet = this.getDataSet();
		var cols = dataSet.getDimSize(2);
		if (cols < 2) {
			this.F2Mode = true;
		}
		else {
			this.F2Mode = false;
		}

		if (zenIsMissing(dataSet)) {
			html[html.length] = '<tr><td>dynaGrid has no data.</td></tr>';
		}
		else {
			zenASSERT(dataSet.getDimensions()>0,"dataSet must have at least one dimension.",arguments);

			// if there are cell overrides, organize them
			// cellInfo[page][row][col]
			var cellInfo = null;
			if (this.cells.length) {
				cellInfo = [];
				for (var k = 0; k < this.cells.length; k++) {
					var info = this.cells[k];
					var page = parseInt(info.page!==''?info.page:1,10);
					var row = parseInt(info.row!==''?info.row:1,10);
					var col = parseInt(info.column!==''?info.column:1,10);
					if (!cellInfo[page]) {
						cellInfo[page] = [];
					}
					if (!cellInfo[page][row]) {
						cellInfo[page][row] = [];
					}
					cellInfo[page][row][col] = info;
				}
			}

			// column headers
			if (this.showColumnLabels) {
				html[html.length] = '<tr>';
				if (this.showRowLabels) {
					// gridLabel in corner
					var glbl;
					if (dataSet.getDimensions() > 2) {
						// 3-D grid: show page label
						glbl = dataSet.getLabel(this.currPage-1,3);
						glbl = (''==glbl? this.currPage : glbl);
						glbl = '<a onclick="zenPage.getComponent('+this.index+').previousPage();">&laquo;</a>' + '&nbsp;' + '<a onclick="zenPage.getComponent('+this.index+').nextPage();">&raquo;</a>&nbsp;' + glbl;

					}
					else {
						glbl = (''==this.gridLabel?'&nbsp;':this.gridLabel);
					}
					var glblstyle = this.columnHeaderStyle;
					if (this.borders=='none') {
						glblstyle += 'border:none;';
					}
					html[html.length] = '<th nowrap="1" id="gridLabel_'+this.index+'" style="'+glblstyle+'" class="dynaGridLabel"'+'onclick="zenPage.getComponent('+this.index+').gridLabelHandler();">'+glbl+'</th>';
				}
				for (var c = 0; c < cols; c++) {
					var cinfo = this.getColumnInfo(c);
					if (cinfo && cinfo.hidden) continue;

					var data = cinfo ? cinfo.label : '';
					data = ('' == data) ? dataSet.getLabel(c,2) : data;
					data = ('' == data) ? '&nbsp;' : data;
					var thstyle = this.columnHeaderStyle;
					if (this.borders=="none") {
						thstyle += 'border: none;';
					}
					var thtip = '';
					var dbl = 'ondblclick="zenPage.getComponent('+this.index+').columnLabelDblClickHandler('+(c+1)+');"';
					html[html.length] = '<th nowrap="1" style="'+thstyle+'" id="thCol_'+(c+1)+'_'+this.index+'" class="dynaGridColumn"'+' '+dbl+' onclick="zenPage.getComponent('+this.index+').columnLabelHandler('+(c+1)+');">' + data + '</th>';
				}
				if (this.showArrows) {
					var rowCount = 2;
					for (var r = 0; r < dataSet.getDimSize(1); r++) {
						var rinfo = this.getRowInfo(r);
						if (rinfo && rinfo.hidden) continue;
						rowCount++;
					}
					html[html.length] = '<td class="dynaGridArrow" style="width: 24px; text-align:center;padding:2px;" rowspan="'+rowCount+'" title="'+$$$Text('Add column')+'" onclick="zenPage.getComponent('+this.index+').arrowHandler(\'columns\');">' + '<input type="image" src="images/arrowBR.png"/>' + '</td>';
				}
				html[html.length] = '</tr>';
			}

			// data: D1(rows) D2(cols)
			for (var r = 0; r < dataSet.getDimSize(1); r++) {
				var rinfo = this.getRowInfo(r);
				if (rinfo && rinfo.hidden) continue;

				var rprio = (null!=rinfo && rinfo.priority!=='') ? parseInt(rinfo.priority,10) : 1;
				var rformat = (null!=rinfo&&''!==rinfo.format) ? rinfo.format : this.format;
				var rstyle = '';
				if (this.borders=="none") {
					rstyle += 'border: none;';
				}
				rstyle += this.style + ((null!=rinfo&&null!=rinfo.style) ? rinfo.style : '');
				var rvalue = (null!=rinfo&&null!=rinfo.value) ? rinfo.value : '';
				var rtip = (null!=rinfo&&null!=rinfo.title) ? rinfo.title : '';
				var rro = (null!=rinfo&&null!=rinfo.readOnly) ? rinfo.readOnly : false;
				var rhgt = (null!=rinfo&&null!=rinfo.height) ? (''!=rinfo.height?' height="'+rinfo.height+'"':'') : '';
				var rcls = '';
				if (this.showZebra) {
					rcls = ' class="'+((r%2)?'dynaGridRowOdd':'dynaGridRowEven')+'"';
				}
				html[html.length] = '<tr'+rhgt+rcls+'>';

				// label
				if (this.showRowLabels) {
					var thstyle = this.rowHeaderStyle;
					if (this.borders=="none") {
						thstyle += 'border: none;';
					}
					if (this.showZebra) {
						thstyle += 'background: none;';
					}
					var data = rinfo ? rinfo.label : '';
					data = ('' == data) ? dataSet.getLabel(r,1) : data;
					data = ('' == data) ? '&nbsp;' : data;
					var dbl = 'ondblclick="zenPage.getComponent('+this.index+').rowLabelDblClickHandler('+(r+1)+');"';
					html[html.length] = '<th nowrap="1" style="'+thstyle+'" id="thRow_'+(r+1)+'_'+this.index+'" class="dynaGridRow"'+' '+dbl+' onclick="zenPage.getComponent('+this.index+').rowLabelHandler('+(r+1)+');">' + data + '</th>';
				}

				for (var c = 0; c < cols; c++) {
					var cinfo = this.getColumnInfo(c);
					if (cinfo && cinfo.hidden) continue;

					var tdstyle = rstyle;
					var tdformat = rformat;
					var tdvalue = rvalue;
					var cprio = 1;
					var tdtip = rtip;
					var cro = (null!=cinfo) ? cinfo.readOnly : false;
					if (null!=cinfo) {
						cprio = (cinfo.priority==='') ? 1 : parseInt(cinfo.priority,10);
						if ('undefined' != typeof cinfo.value && cinfo.value!=='') {
							if (cprio >= rprio) {
								tdvalue = cinfo.value;
							}
						}
						if ('undefined' != typeof cinfo.format && cinfo.format!=='') {
							if (cprio >= rprio) {
								tdformat = cinfo.format;
							}
						}
						if (cprio >= rprio) {
							tdstyle = tdstyle + cinfo.style;
						}
						else {
							tdstyle = cinfo.style + tdstyle;
						}
						if (cprio >= rprio) {
							tdtip = (''!=cinfo.title) ? cinfo.title : tdtip;
						}
					}

					var events = ' onclick="zenPage.getComponent('+this.index+').cellClickHandler('+(r+1)+','+(c+1)+',event);" ondblclick="zenPage.getComponent('+this.index+').cellDblClickHandler('+(r+1)+','+(c+1)+',event);"'
					var data = dataSet.getData(r,c,this.currPage-1);
					if (data==='' && tdvalue!=='') {
						data = tdvalue;
					}
					if (this.ongetcellvalue!='') {
						var ndata = zenInvokeCallbackMethod(this.ongetcellvalue,this,'ongetcellvalue','row',r+1,'col',c+1,'data',data);
						if (ndata !== null) {
							data = ndata;
						}
					}

					var page = 0;
					if (cellInfo && cellInfo[page+1]&&cellInfo[page+1][r+1]&&cellInfo[page+1][r+1][c+1]) {
						var clinfo = cellInfo[page+1][r+1][c+1];
						if (clinfo.style!='') {
							tdstyle = clinfo.style;
						}
						if (clinfo.format!='') {
							tdformat = clinfo.format;
						}
						if(clinfo.title!='') {
							tdtip=clinfo.title;
						}						
						
					}

					data = data!==null ? data : '';
					data = this.getCellContents(data,r+1,c+1);

					if ('' != tdstyle) {
						tdstyle = ' style="'+tdstyle+'"';
					}
					if ('' != tdtip) {
						tdtip = ' title="'+tdtip+'"';
					}

					var cls = (this.currRow == (r+1) && this.currColumn == (c+1)) ? ' class="selected"' : '';

					data = (tdformat!='') ? zenFormatNumber(data,tdformat) : data;
					
					html[html.length] = '<td ' + (this.nowrap ? 'nowrap="1" ' : '') + 'valign="middle"'+tdstyle+tdtip+'>';
					html[html.length] = '<div id="td_'+(r+1)+'_'+(c+1)+'_'+this.index+'" '+events+cls+'>'+data+'</div>';
					html[html.length] = '</td>';
				}
				html[html.length] = '</tr>';
			}
		}

		if (this.showArrows) {
			var colCount = cols + 1;
			html[html.length] = '<tr>';
			html[html.length] = '<td class="dynaGridArrow" style="text-align:center;padding:2px;" colspan="'+colCount+'"  title="'+$$$Text('Add row')+'" onclick="zenPage.getComponent('+this.index+').arrowHandler(\'rows\');">' + '<input type="image" src="images/arrowBD.png"/>' + '</td>';
			html[html.length] = '</tr>';
		}
		html[html.length] = '</table>';

		// insert invisible input to catch key events
		// SAM107 implement equivalent styling to that removed by JMD625 to fix blank line problem without breaking chrome
		//html[html.length] = '<div style="position:relative; display:block; height:0px; width:0px; overflow:hidden; fontSize:0px; lineHeight:0px" >';
		html[html.length] = '<div style="top:0px;left:0px;position:absolute; display:block; height:0px; width:0px; overflow:hidden; font-size:0px; line-height:0px" >';
		// JMD625: remove style so that Chrome will give focus!
		//html[html.length] = '<input type="text" id="'+this.makeId('invisible')+'" style="top:0px;left:0px;position:absolute; border: 0px solid green;width:0;height:0;" onkeydown="zenPage.getComponent('+this.index+').gridKeyDownHandler(event);" onkeypress="zenPage.getComponent('+this.index+').gridKeyPressHandler(event);" onfocus="zenPage.getComponent('+this.index+').gridKeyFocus();" onblur="zenPage.getComponent('+this.index+').gridKeyBlur();"/>';
		html[html.length] = '<input type="text" tabindex="'+this.tabIndex+'" id="'+this.makeId('invisible')+'"  onkeydown="return zenPage.getComponent('+this.index+').gridKeyDownHandler(event);" onkeypress="return zenPage.getComponent('+this.index+').gridKeyPressHandler(event);" onfocus="zenPage.getComponent('+this.index+').gridKeyFocus();" onblur="zenPage.getComponent('+this.index+').gridKeyBlur();"/>';
		html[html.length] = '</div>';

		html[html.length] = '</div>';
	
		encDiv.innerHTML = html.join('');
		this.adjustSizes();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in renderContents.');
	}
}

/// Calculate the pixels needed to render the edge of a given cell, including
/// (potentially) the space needed for the margins, borders and padding
ClientMethod getEdgeWidth(node, margins, borders, padding) [ Language = javascript ]
{
	var t=0;
	try {
		if (!node) {
			var s = '';
		}
		else if (node.currentStyle) { // IE Style
			var s=node.currentStyle;
		}
		else { //W3C style
			var s=window.getComputedStyle(node,null);	
		}
		if (s==null) {
		}
		else {
			if (margins) {
				var x=parseInt(s.marginLeft,10);
				if (!isNaN(x)) t+=x;
				var x=parseInt(s.marginRight,10);
				if (!isNaN(x)) t+=x;
			}
			if (borders && s.borderStyle!="none") {
				var x=parseInt(s.borderRightWidth,10);
				if (!isNaN(x)) t+=x;
				var x=parseInt(s.borderLeftWidth,10);
				if (!isNaN(x)) t+=x;
			}
			if (padding) {
				var x=parseInt(s.paddingRight,10);
				if (!isNaN(x)) t+=x;
				var x=parseInt(s.paddingLeft,10);
				if (!isNaN(x)) t+=x;
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in getEdgeWidth.');
	}
	return(t);
}

/// Get the defined width of a node as specified in the CSS
ClientMethod getCSSWidthSpec(node) [ Language = javascript ]
{
	try {
		var r = [];
		r[0]={};
		r[0].selectorText="this";
		r[0].style=node.style;
		var rule=null;
		if (node.id!=null) {
			var id="#"+node.id;
			for(var i=document.styleSheets.length-1;i>=0;i--) {
				var s={};
				s.ss=document.styleSheets[i];

				if (s.ss.href!=null && s.ss.href.indexOf("://")>0) {
					if (s.ss.href.indexOf("http")!=0 && s.ss.href.indexOf("file")!=0) continue;
					if (window.location && s.ss.href.indexOf(window.location.host)<0) continue;
				}

				if (s.ss && s.ss.cssRules) s.rules=s.ss.cssRules;
				else s.rules=s.ss.rules;
				if (!s.rules) continue;
				for (var j=s.rules.length-1;j>=0;j--) {
					if (s.rules[j].selectorText==id) rule=s.rules[j];
				}	
			}
		}
		if (rule!=null) r.push(rule);
		rule=null;
		className="."+node.className;
		for(var i=document.styleSheets.length-1;i>=0;i--) {
			var s={};
			s.ss=document.styleSheets[i];
			
			if (s.ss.href!=null && s.ss.href.indexOf("://")>0) {
				if (s.ss.href.indexOf("http")!=0 && s.ss.href.indexOf("file")!=0) continue;
				if (window.location && s.ss.href.indexOf(window.location.host)<0) continue;
			}

			if (s.ss.cssRules) s.rules=s.ss.cssRules;
			else s.rules=s.ss.rules;
			if (!s.rules) continue;
			for (var j=s.rules.length-1;j>=0;j--) {
				// Needed to add defensive code because 
				// the HTML5 introduces some "rule" entries
				// that don't have selectorText defined
				var selectorText = s.rules[j].selectorText;
				if (selectorText && selectorText.indexOf(className)>=0) {
					r.push(s.rules[j]);
				}
			}	
		}
		for (var i=0;i<r.length;i++) {
			if (r[i].style.width) return(r[i].style.width);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in getCSSWidthSpec');
	}
	return("auto");
}

/// Adjust the column sizes of this grid.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		// find available width and divy it up
		var dataSet = this.getDataSet();
		var cols = dataSet.getDimSize(2);
		var rows = dataSet.getDimSize(1);
	
		var encDiv = this.getEnclosingDiv();
		var wrapper = this.findElement("wrapper");
		var tbl = this.findElement("table");

		var dEdgeW = this.getEdgeWidth(encDiv,0,1,1);
		var wEdgeW = this.getEdgeWidth(wrapper,0,1,1);
		var tEdgeW = this.getEdgeWidth(tbl,1,1,1);
	
		var colW = parseFloat(this.columnWidth);
		var rlW = parseFloat(this.rowLabelWidth);
		
		var defWidth=null;
		if (window.getComputedStyle) var defWidth=this.getCSSWidthSpec(encDiv);
		else var defWidth=encDiv.currentStyle.width;
	
		var insideW=null;
		if (encDiv.offsetWidth>0) var insideW=encDiv.offsetWidth-dEdgeW;
		else {
			if (!(defWidth.indexOf) || defWidth.indexOf("px")>0) var insideW=parseFloat(defWidth)-dEdgeW;
		}
	
		if (this.showRowLabels && insideW && this.rowLabelWidth.indexOf("%")>0) {
			rlW = Math.floor(insideW*rlW/100);
		}
		var cHead=[]; //Array of nodes governing size of individual columns
		if (this.showRowLabels) {  // If the first column is row labels, pick it up
			if (this.showColumnLabels) {
				var th = this.findElement("gridLabel");
				if (th) cHead.push(th);
			}
			else {
				var div = this.findElement("thRow_1");
				if (div) cHead.push(div);
			}
		}
		for (var c = 0; c < cols; c++) { // now get top cells for all the data columns
			if (this.showColumnLabels) {
				var th = this.findElement("thCol_"+(c+1));
				// even if null, add to list!
				cHead.push(th);
			}
			else {
				var div = this.findElement("td_1_" + (c+1));
				if (div && div.parentNode) {
					cHead.push(div.parentNode);
				}
				else {
					cHead.push(null);
				}
			}
		}

		// Now find out how wide each column is supposed to be
		var wide = [];
		var unit = [];
		var sumPercent = 0; // total percentage widths
		var sumFixed = 0; // total pixels reserved for the interior of fixed width columns
		var edgeSum = 0; // total pixels reserved for cell separators and row labels (if any)
		var minWedge = 100; // smallest percentage specified wedge
		if (this.showRowLabels) edgeSum = rlW+this.getEdgeWidth(cHead[0],0,1,1);
		for (var c = 0; c < cols; c++) {
			var cinfo = this.getColumnInfo(c);
			if (cinfo && cinfo.hidden) continue;
			edgeSum += cHead[c] ? this.getEdgeWidth(cHead[c],0,1,1) : 0;

			if (cinfo && !isNaN(parseFloat(cinfo.width))) {
				wide[c] = parseFloat(cinfo.width);
				unit[c] = cinfo.width.indexOf ? (cinfo.width.indexOf('%')<0) : true;
				if (unit[c]) sumFixed += wide[c];
				else {
					sumPercent+=wide[c];
					if (wide[c]<minWedge) minWedge=wide[c];
				}
			}
			else {
				if (!isNaN(parseFloat(colW))){
					wide[c] = colW;
					unit[c] = true;
					sumFixed += colW;
				} else {
					
				}
			}
		}

		// Now resolve issues with percentages. 	For any width marked as a percentage
		// convert it to a pixel value and correct the units flag
		if (sumPercent>0) { // extra processing required
			if (sumPercent==100 || sumFixed==0) {
				var percentScale = 100 / sumPercent;
				if (insideW==null) {
					var oneUnit=(colW/(minWedge))*percentScale;
					for (var c=0;c<wide.length;c++) {
						if (!unit[c]) {
							wide[c]=Math.floor(wide[c]*oneUnit);
							unit[c]=true;
						}
					}
				}
				else {
					// bound this by the enclosing div size (hopefully specified)
					var space=percentScale*(insideW-edgeSum)/100;
					// space should now be the max space within the enclosing div tp play with
					for (var c=0;c<wide.length;c++) {
						wide[c]=Math.floor(space*wide[c]);
						unit[c]=true;
					}
				}
			}
			else {
				// only some of the columns are percentage based, need to balance
				// size of data area based on fixed elements
				var oneUnit=sumFixed/(100-sumPercent);
				for (var c=0;c<wide.length;c++) {
					if (!unit[c]) {
						wide[c]=Math.floor(wide[c]*oneUnit);
						unit[c]=true;
					}
				}
			
			}
		}
	
		// Address case where rowLabel width is percentage a when total grid size is unbounded
		if (this.showRowLabels && insideW==null && this.rowLabelWidth.indexOf("%")>0) {
			insideW=0;
			for (var c=0;c<wide.length;c++) insideW+=wide[c];
			edgeSum -= rlW;
			rlW = Math.floor(insideW*rlW/100);
			edgeSum += rlW;
		}

		// FINALLY update the table to reflect the desired geometry
		if (this.showRowLabels) {
			cHead[0].style.width=rlW+"px";
			var ofs=1;
		}
		else {
			ofs=0;
		}
		var w=edgeSum;
		var dyn=false;
		for (var c = 0; c < cols; c++) {
			var cinfo = this.getColumnInfo(c);
			if ((cinfo && !cinfo.hidden) || !cinfo) {
				if (wide[c]<0) wide[c]=0;
				if (cHead[ofs] && (!isNaN(wide[c]))) {
					cHead[ofs].style.width=wide[c]+"px";
				}
				if (!isNaN(wide[c])){
					w+=wide[c];
				} else {
					dyn=true;
				}
			}
			ofs++;
		}
		if (dyn){
			wrapper.style.width="100%";
			encDiv.style.width="100%";
		} else {
			wrapper.style.width=(w+(this.showArrows?30:0))+"px";
		}
	
		
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes.');
	}
}

/// Return an object containing display information for row <var>r</var>
/// (0-based).
ClientMethod getRowInfo(r) [ Language = javascript ]
{
	return this.rows[r];
}

/// Return an object containing display information for column <var>c</var>
/// (0-based).
ClientMethod getColumnInfo(c) [ Language = javascript ]
{
	return this.columns[c];
}

/// Return the cell descriptor for the given cell (if any).
/// (0-based).
ClientMethod getCellInfo(page, row, col) [ Language = javascript ]
{
	var cinfo = null;
	// loop and find
	for (var n = 0; n < this.cells.length; n++) {
		var item = this.cells[n];
		if (item && (item.page==(page+1)||item.page==='') && item.row == (row+1) && item.column == (col+1)) {
			cinfo = item;
			break;
		}
	}
	return cinfo;
}

/// Prepares data for display within a given cell.
/// If there is an <method>ondrawcell</method> callback,
/// it is invoked. This callback has a chance to chance the contents
/// that will be displayed within the cell.
ClientMethod getCellContents(data, r, c) [ Language = javascript ]
{
	// test for user callback
	var usercode = '';
	if (this.ondrawcell) {
		// set up transient row & column properties to
		// pass information to the callback
		this.row = r;
		this.column = c;
		usercode = zenInvokeCallbackMethod(this.ondrawcell,this,'ondrawcell','data',data);
		delete this.row;
		delete this.column;
	}
	if (usercode && '' != usercode) {
		data = usercode;
	}
	else {
		if ('' === data) {
			data = '&nbsp;';
		}
		else {
			data = zenEscapeXML(data);
		}
	}

	return data;
}

/// This callback provides a way to fill in
/// the dataSet object used to provide values for this grid.
Method %CreateDataSet() As %Status
{
	Set $ZT="Trap"
	Set tSC = $$$OK

	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (..OnCreateDataSet '= "")) {
		#; dispatch
		Set tSC = $zobjmethod(tHost,..OnCreateDataSet,##this,..dataSet)
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// Initialize additional client-side values
ClientMethod onCreate() [ Language = javascript ]
{
	// initialize additional properties
	this.currDiv = null;
	this.hasFocus = false;
	this.cellHasFocus = false;
	this.F2Mode = false;
	this.currEditType = null;
}

/// Notification that the dataController associated with this dataView
/// has raised an event.
ClientMethod notifyViewHandler(reason, data1, data2, data3) [ Language = javascript ]
{
	switch(reason) {
	case 'dataChange':
	case 'modelChange':
		// some change in dataController
		this.render();
		break;
	case 'seriesChange':
		break;
	}
}

/// Return the dataSet object associated with this grid.
ClientMethod getDataSet() [ Language = javascript ]
{
	var controller = this.getController();
	return (controller ? controller : this.dataSet);
}

/// Return row number (1-based) of the most recently selected row.
ClientMethod getCurrRow() [ Language = javascript ]
{
	return this.currRow;
}

/// Return column number (1-based) of the most recently selected column.
ClientMethod getCurrColumn() [ Language = javascript ]
{
	return this.currColumn;
}

/// Display edit control in the current cell.
/// If <var>defval</var> is defined, then use it as the initial value in the editor.
/// <var>which</var> indicates what type of cell is being edited: "row" (row label), "column" 
/// (column label), otherwise a data cell.
ClientMethod editCell(defval, which) [ Language = javascript ]
{
	var value;
	var r = this.currRow;
	var c = this.currColumn;
	which = ('undefined'==typeof which) ? 'cell' : which;
	defval = ('undefined'==typeof defval) ? null : defval;

	if ((which=='cell') && !this.isCellEditable(r,c)) {
		// not editable
		return;
	}

	if (r > 0 && c > 0) {
		switch(which) {
		case 'row':
			var div = this.findElement("thRow_"+r);
			zenASSERT(div,"Unable to find div element",arguments);
			var dataSet = this.getDataSet();
			value = (dataSet) ? dataSet.getLabel(r-1,1) : '';
			div.innerHTML = this.getEditCellHTML(r,0,value,'row');
			break;
		case 'column':
			var div = this.findElement("thCol_"+c);
			zenASSERT(div,"Unable to find div element",arguments);
			var dataSet = this.getDataSet();
			value = (dataSet) ? dataSet.getLabel(c-1,2) : '';
			div.innerHTML = this.getEditCellHTML(0,c,value,'column');
			break;
		default:
			var div = this.findElement("td_"+r + "_" + c);
			zenASSERT(div,"Unable to find div element",arguments);
			value = (null!=defval) ? defval : this.getCellValue(r,c);
			div.innerHTML = this.getEditCellHTML(r,c,value);
			break;
		}

		this.oldOnclick = div.onclick;
		div.onclick = '';
		this.currDiv = div;
		this.currEditType = which;

		// have font style for editor match the cell
		var style = '';
		if (div.parentNode && div.parentNode.style) {
			if (div.parentNode.style.fontSize!='') {
				style += 'font-size:' + div.parentNode.style.fontSize + ';';
			}
			if (div.parentNode.style.fontFamily!='') {
				style += 'font-family:' + div.parentNode.style.fontFamily + ';';
			}
		}

		// set size of control
		var celledit = this.window.document.getElementById("cellEditor");
		var w = div.parentNode.offsetWidth-1;
		var h = div.parentNode.offsetHeight-(zenIsIE ? 4 : 2);
		
		// JMD
		if (div.parentNode.style.paddingTop) {
			var pad = parseInt(div.parentNode.style.paddingTop);
			if (!isNaN(pad)) {
				h -= pad;
			}
		}
		if (div.parentNode.style.paddingBottom) {
			var pad = parseInt(div.parentNode.style.paddingBottom);
			if (!isNaN(pad)) {
				h -= pad;
			}
		}

		celledit.style.cssText = 'width:'+w+'px;height:'+h+'px;' + style;
		this.cellHasFocus = true;

		// give focus to control
		if (celledit.focus) {
			celledit.focus();
		}
		// force cursor to end of control
		if ('undefined' != typeof value) {
			if (celledit.setSelectionRange) {
				var ln = value.toString().length;
				celledit.setSelectionRange(ln,ln);
			}
			else { // ie!
				var v = celledit.value;
				celledit.value = '';
				celledit.value = v;
			}
		}
		// select
		if (null == defval && celledit.select) {
			celledit.select();
		}
	}
}

/// Return the HTML that renders the cell editor for the given cell.
/// <var>r</var> and <var>c</var> are 1-based.
/// If <var>r</var> is 0, then we are editing a column header;
/// If <var>c</var> is 0, then we are editing a row header;
/// <var>which</var> indicates what is being edited (see editCell).
ClientMethod getEditCellHTML(r, c, value, which) [ Language = javascript ]
{
	which = ('undefined'==typeof which) ? 'cell' : which;

	// test for user callback
	var html = '';
	var usercode = '';
	if (this.oneditcell) {
		usercode = zenInvokeCallbackMethod(this.oneditcell,this,'oneditcell','value',value,'which',which);
	}
	if (usercode && '' != usercode) {
		html = usercode;
	}
	else {
		html = '<input class="dynaGridInput" id="cellEditor" type="text" value="'+zenEscapeXML(value)+'" onkeydown="zenPage.getComponent('+this.index+').cellEditKeyHandler(event);" onkeyup="zenPage.getComponent('+this.index+').cellEditKeyUpHandler(event);" onblur="zenPage.getComponent('+this.index+').stopEditCell();" />';
	}
	return html;
}

/// Stop editing of the current cell.<br>
/// If <var>cancel</var> is true, then do not save current control value.
ClientMethod stopEditCell(cancel) [ Language = javascript ]
{
	cancel = (null==cancel) ? false : cancel;
	var value;
	var type = 'cell';
	
	if (this.currDiv && this.cellHasFocus) {
		// get rid of edit control in cell; save value
		this.cellHasFocus = false;
		this.F2Mode = false;
		var cell = this.window.document.getElementById("cellEditor");
		zenASSERT(cell,"Unable to find cellEditor control",arguments);
		if (cell) {
			if (this.currEditType == 'row') {
				type = 'row';
				var dataSet = this.getDataSet();
				var oldLabel = (dataSet) ? dataSet.getLabel(this.currRow-1,1) : '';
				value = !cancel ? cell.value : oldLabel;
				this.currDiv.onclick = this.oldOnclick;
				this.setLabelValue(value,'row',this.currRow);
				cell.value = '';
			}
			else if (this.currEditType == 'column') {
				type = 'column';
				var dataSet = this.getDataSet();
				var oldLabel = (dataSet) ? dataSet.getLabel(this.currColumn-1,2) : '';
				value = !cancel ? cell.value : oldLabel;
				this.currDiv.onclick = this.oldOnclick;
				this.setLabelValue(value,'column',this.currColumn);
				cell.value = '';
			}
			else {
				value = !cancel ? cell.value : this.getCellValue(this.currRow, this.currColumn);
				this.currDiv.onclick = this.oldOnclick;
				this.setCellValue(value, this.currRow, this.currColumn);
				cell.value = '';
			}
			// invoke cell onchangecell callback, if present
			if (!cancel) {
				zenInvokeCallbackMethod(this.onchangecell,this,'onchangecell','which',type);
			}
		}

		this.currDiv = null;
		this.currEditType = null;

		// invoke grid-wide onchange callback, if present
		zenInvokeCallbackMethod(this.onchange,this,'onchange','which',type);

		// give focus back to invisible control
		this.focus();
	}
}

/// Return the html element for the current cell editor, if there is one.
ClientMethod getCellEditor() [ Language = javascript ]
{
	return this.window.document.getElementById("cellEditor");
}

/// Return whether a given cell can be edited; Row and column are 1-based.
ClientMethod isCellEditable(r, c) [ Language = javascript ]
{
	if (this.disabled) return false;
	var rinfo = this.getRowInfo(r-1);
	var rro = (null!=rinfo) ? rinfo.readOnly : false;
	var rhide = (null!=rinfo) ? rinfo.hidden : false;
	var cinfo = this.getColumnInfo(c-1);
	var cro = (null!=cinfo) ? cinfo.readOnly : false;
	var chide = (null!=cinfo) ? cinfo.hidden : false;
	return !this.readOnly && !cro && !rro && !chide && !rhide;
}

/// Return whether a given cell is visible; Row and column are 1-based.
ClientMethod isCellVisible(r, c) [ Language = javascript ]
{
	var rinfo = this.getRowInfo(r-1);
	var rhide = (null!=rinfo) ? rinfo.hidden : false;
	var cinfo = this.getColumnInfo(c-1);
	var chide = (null!=cinfo) ? cinfo.hidden : false;
	return !chide && !rhide;
}

/// Return number of rows in this grid.
ClientMethod getRowCount() [ Language = javascript ]
{
	var dataSet = this.getDataSet();
	return zenIsMissing(dataSet) ? 0 : dataSet.getDimSize(1);
}

/// Return number of columns in this grid.
ClientMethod getColumnCount() [ Language = javascript ]
{
	var dataSet = this.getDataSet();
	return zenIsMissing(dataSet) ? 0 : dataSet.getDimSize(2);
}

/// Return number of "pages" in this grid.
ClientMethod getPageCount() [ Language = javascript ]
{
	var dataSet = this.getDataSet();
	return zenIsMissing(dataSet) ? 0 : dataSet.getDimSize(3);
}

/// Return value of grid cell; Row and column are 1-based.
ClientMethod getCellValue(r, c) [ Language = javascript ]
{
	var dataSet = this.getDataSet();
	return zenIsMissing(dataSet) ? '' : dataSet.getData(r-1,c-1,this.currPage-1);
}

/// Set the value of grid cell; Row and column are 1-based.
ClientMethod setCellValue(value, r, c) [ Language = javascript ]
{
	var dataSet = this.getDataSet();
	if (!zenIsMissing(dataSet)) {
		// original value goes to data set
		dataSet.setData(value,r-1,c-1,this.currPage-1);

		// transpose value via callback;
		if (this.ongetcellvalue!='') {
			var ndata = zenInvokeCallbackMethod(this.ongetcellvalue,this,'ongetcellvalue','row',r,'col',c,'data',value);
			if (ndata !== null) {
				value = ndata;
			}
		}

		// if there is a controller, notify it
		var controller = this.getController();
		if (controller) {
			// note: series # is 1-based
			var series = c;
			if (controller.OnRenderJSON) series--; //adjust for JSON provider
			this.sendEventToController('propertyChange',controller.getPropertyName(r-1),value,series);
		}
	}

	var div = this.findElement("td_"+r + "_" + c);
	if (div) {
		value = this.getCellContents(value,r,c);
		// check for format
		var rinfo = this.getRowInfo(r);
		var cinfo = this.getColumnInfo(c);
		var format = (cinfo&&cinfo.format!='') ? cinfo.format : (rinfo&&rinfo.format!='') ? rinfo.format : this.format;
		format = ('undefined' == typeof format) ? '' : format;

		value = (format!=='') ? zenFormatNumber(value,format) : value;
		div.innerHTML = value;
	}
}

/// Set the value of grid label; <var>index</var> is 1-based. <var>which</var> is "row" or "column".
ClientMethod setLabelValue(value, which, index) [ Language = javascript ]
{
	var dataSet = this.getDataSet();
	if (!zenIsMissing(dataSet)) {
		dataSet.setLabel(value,index-1,(which=='row') ? 1 : 2);

		// if there is a controller, notify it!!!
		var controller = this.getController();
		if (controller) {
			// note: series # is 1-based
			// this.sendEventToController('propertyChange',controller.getPropertyName(r-1),value,c);
		}
	}

	if (which == 'row') {
		var div = this.findElement("thRow_"+index);
	}
	else {
		var div = this.findElement("thCol_"+index);
	}
	if (div) {
		// value = this.getCellContents(value,r,c);
		div.innerHTML = value;
	}
}

/// If implemented, this callback method is called at page render-time
/// when this component is added to a page.
Method %OnAddToPageAfter() As %Status
{
	Do ..%ApplyDefaultLabels()
	
	#; invoke user callback
	Quit ..%CreateDataSet()
}

/// Client-side method to input focus to this control.
ClientMethod focus() [ Language = javascript ]
{
	//FKH: the enclosing divs scrollpostion is not valid if elements above that have been dynamically 
	//enlarged.
	var scrollTop,scrollLeft;
	if(typeof pageYOffset!= 'undefined'){
        //most browsers except IE before #9
        scrollTop=pageYOffset;
        scrollLeft=pageXOffset;
    }
    else{
        var B= document.body; //IE 'quirks'
        var D= document.documentElement; //IE with doctype
        D= (D.clientHeight)? D: B;
        scrollTop=D.scrollTop;
        scrollLeft=D.scrollLeft;
    }
	// give focus to invisible control
	var inv = this.findElement('invisible');
	var div = this.getEnclosingDiv();
	if (inv) {
		inv.focus();
	}
	window.scrollTo(scrollLeft,scrollTop);
}

/// Applies the row and column labels defined by the 
/// <property>rows</property> and <property>columns</property>
/// collections.
Method %ApplyDefaultLabels()
{
	Set tCount = ..rows.Count()
	For r=1:1:tCount {
		Set tRow = ..rows.GetAt(r)
		If ($IsObject(tRow) && (tRow.label'="")) {
			Do ..dataSet.%SetLabel(tRow.label,r,1)
		}
	}

	Set tCount = ..columns.Count()
	For c=1:1:tCount {
		Set tCol = ..columns.GetAt(c)
		If ($IsObject(tCol) && (tCol.label'="")) {
			Do ..dataSet.%SetLabel(tCol.label,c,2)
		}
	}
}

/// This method fills in reasonable default values for
/// this control. Used by tools (such as Control Tester) to
/// dynamically create controls.
Method %SetDefaultValues()
{
	#; row labels
	Do ..dataSet.%SetLabel("1",1,1)
	Do ..dataSet.%SetLabel("2",2,1)

	#; column labels
	Do ..dataSet.%SetLabel("A",1,2)
	Do ..dataSet.%SetLabel("B",2,2)

	#; data
	Do ..dataSet.%SetValue(11,1,1)
	Do ..dataSet.%SetValue(21,2,1)
	Do ..dataSet.%SetValue(12,1,2)
	Do ..dataSet.%SetValue(22,2,2)
}

/// User has clicked on a cell.
ClientMethod cellClickHandler(row, col, evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (this.multiSelect) {
		if (evt.ctrlKey && '' != this.selectedRange) {
			// expand range
			var p = this.selectedRange.split(',');
			p[0] = (row < p[0]) ? row : p[0];
			p[1] = (col < p[1]) ? col : p[1];
			p[2] = (row > p[2]) ? row : p[2];
			p[3] = (col > p[3]) ? col : p[3];
			this.selectCellRange(p[0],p[1],p[2],p[3]);
		}
		else {
			this.selectCellRange(row,col,row,col);
		}
	}
	this.selectCell(row,col,true);
	this.focus();
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

/// User has clicked on the grid label.
ClientMethod gridLabelHandler() [ Language = javascript ]
{
	this.focus();
	zenInvokeCallbackMethod(this.onclicklabel,this,'onclicklabel');
}

/// User has clicked on a row label.
ClientMethod rowLabelHandler(row) [ Language = javascript ]
{
	this.focus();
	this.selectCell(row,-1,true);
	if (this.multiSelect) {
		this.selectCellRange(row,1,row,this.getColumnCount());
	}
	zenInvokeCallbackMethod(this.onclickrow,this,'onclickrow','row',row);
}

/// User has double-clicked on a row label.
ClientMethod rowLabelDblClickHandler(row) [ Language = javascript ]
{
	if (this.editLabels) {
		this.editCell(null,'row');
	}
}

/// User has clicked on a column label.
ClientMethod columnLabelHandler(col) [ Language = javascript ]
{
	this.focus();
	this.selectCell(-1,col,true);
	if (this.multiSelect) {
		this.selectCellRange(1,col,this.getRowCount(),col);
	}
	zenInvokeCallbackMethod(this.onclickcolumn,this,'onclickcolumn','column',col);
}

/// User has double-clicked on a column label.
ClientMethod columnLabelDblClickHandler(col) [ Language = javascript ]
{
	if (this.editLabels) {
		this.editCell(null,'column');
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'value':
		// update internal value used for submit
		var el = this.findElement('control');
		if (el) {
			el.value = value;
		}
		this.value = value;
		break;

	case 'nowrap':
	case 'readOnly':
	case 'disabled':
	case 'showColumnLabels':
	case 'showRowLabels':
	case 'showZebra':
		value = value ? true : false;
		this[property] = value;
		this.render();
		break;
	case 'currPage':
	case 'rowLabelWidth':
	case 'format':
	case 'style':
	case 'columnHeaderStyle':
	case 'rowHeaderStyle':
	case 'borders':
	case 'selectedRangeBackground':
	case 'selectedCellBackground':
	case 'selectedCellColor':
	case 'rowHeaderStyle':
		this[property] = value;
		this.render();
		break;
	case 'gridLabel':
		this.gridLabel = value;
		var th = this.findElement("gridLabel");
		if (th) {
			th.innerHTML = (''==this.gridLabel) ? '&nbsp;' : this.gridLabel;
		}
		break;
	case 'controllerId':
		// pass this change on to dataView
		this.setControllerId(value);
		break;
	case 'editLabels':
		this.editLabels = value;
		break;

	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Get the value of a property for a cell descriptor of this grid.
/// pageno, rowno, and colno are 1-based.
ClientMethod getCellProperty(pageno, rowno, colno, property) [ Language = javascript ]
{
	if (pageno < 1 || rowno < 1 || colno < 1) return '';
	var cinfo = this.getCellInfo(pageno-1,rowno-1,colno-1);
	if (null == cinfo) {
		return '';
	}
	return cinfo.getProperty(property);
}

/// Set the value of a property for a cell descriptor of this grid.
/// pageno, rowno, and colno are 1-based.
ClientMethod setCellProperty(pageno, rowno, colno, property, value) [ Language = javascript ]
{
	if (pageno < 1 || rowno < 1 || colno < 1) return;
	var cinfo = this.getCellInfo(pageno-1,rowno-1,colno-1);
	if (null == cinfo) {
		// create a cell descriptor
		cinfo = zenPage.createComponent('gridCell');
		cinfo.page = pageno;
		cinfo.row = rowno;
		cinfo.column = colno;
		this.cells[this.cells.length] = cinfo;
	}

	cinfo.setProperty(property,value);
	this.render();
	return true;
}

/// Get the value of a property for a column descriptor of this grid.
ClientMethod getColumnProperty(colno, property) [ Language = javascript ]
{
	if (colno < 1) return '';
	var cinfo = this.columns[colno-1];
	if (null == cinfo) return ''
	return cinfo.getProperty(property);
}

/// Set the value of a property for a column descriptor of this grid.
ClientMethod setColumnProperty(colno, property, value) [ Language = javascript ]
{
	if (colno < 1) return;
	var cinfo = this.getColumnInfo(colno-1);
	if (null == cinfo) {
		// create a columns descriptor
		cinfo = zenPage.createComponent('gridColumn');
		this.columns[colno-1] = cinfo;
	}

	cinfo.setProperty(property,value);
	if ('width' == property) {
		this.adjustSizes();
	}
	else {
		this.render();
	}
	return true;
}

/// Get the value of a property for a row descriptor of this grid.
ClientMethod getRowProperty(rowno, property) [ Language = javascript ]
{
	if (rowno < 1) return '';
	var rinfo = this.getRowInfo(rowno-1);
	if (null == rinfo) return ''
	return rinfo.getProperty(property);
}

/// Set the value of a property for a row descriptor of this grid.
ClientMethod setRowProperty(rowno, property, value) [ Language = javascript ]
{
	if (rowno < 1) return;
	var rinfo = this.getRowInfo(rowno-1);
	if (null == rinfo) {
		// create a row descriptor
		rinfo = zenPage.createComponent('gridRow');
		this.rows[rowno-1] = rinfo;
	}

	rinfo.setProperty(property,value);
	this.render();
	return true;
}

/// For 3-D grid, move to the next page of the grid.
ClientMethod nextPage() [ Language = javascript ]
{
	var dataSet = this.getDataSet();
	if (dataSet.getDimensions() < 3) {
		return;
	}

	var page = this.getProperty('currPage')*1;
	page = (page>=dataSet.getDimSize(3)) ? 1 : (page+1);

	if (this.onchangepage!='') {
		if (!zenInvokeCallbackMethod(this.onchangepage,this,'onchangepage','page',page)) {
			return;
		}
	}
	this.setProperty('currPage',page);
}

/// For 3-D grid, move to the previous page of the grid.
ClientMethod previousPage() [ Language = javascript ]
{
	var dataSet = this.getDataSet();
	if (dataSet.getDimensions() < 3) {
		return;
	}
	var page = this.getProperty('currPage')*1;
	page = (page == 1) ? dataSet.getDimSize(3) : (page-1);
	if (this.onchangepage!='') {
		if (!zenInvokeCallbackMethod(this.onchangepage,this,'onchangepage','page',page)) {
			return;
		}
	}
	this.setProperty('currPage',page);
}

/// Move to a new, editable, cell. <var>dir</var> is "up","down","left","right"
/// Returns true if move was successful.
ClientMethod moveToCell(dir) [ Language = javascript ]
{
	var ret = false;

	var row = this.currRow;
	var col = this.currColumn;
	var rowCount = this.getRowCount();
	var colCount = this.getColumnCount();

	switch(dir) {
	case 'up':
		row--;
		while (row > 0) {
			if (this.isCellVisible(row,col)) {
				this.selectCell(row,col,true);
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
				this.selectCell(row, col,true);
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
				this.selectCell(row, col,true);
				ret = true;
				break;
			}
			col--;
		}
		break;
	case 'right':
		col++;
		while (col <= colCount) {
			if (this.isCellVisible(row,col)) {
				this.selectCell(row, col,true);
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
				this.selectCell(row, col,true);
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
				this.selectCell(row, col,true);
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
				this.selectCell(row, col,true);
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
				this.selectCell(row, col,true);
				ret = true;
				break;
			}
			col--;
		}
		break;
	}

	if (this.multiSelect && ret) {
		if (this._modKey && '' != this.selectedRange) {
			// expand range
			var p = this.selectedRange.split(',');
			p[0] = (row < p[0]) ? row : p[0];
			p[1] = (col < p[1]) ? col : p[1];
			p[2] = (row > p[2]) ? row : p[2];
			p[3] = (col > p[3]) ? col : p[3];
			this.selectCellRange(p[0],p[1],p[2],p[3]);
		}
		else {
			this.selectCellRange(row,col,row,col);
		}
		this._modKey = false;
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

	if ('' != this.oneditkeydown) {
		ret = zenFireEvent(this.index, this.oneditkeydown, 'oneditkeydown', evt);
		if (!ret) {
			return false;
		}
	}

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
		if (evt.preventDefault) {
			evt.preventDefault();
		}
		evt.cancelBubble = true;
	}		

	return ret;
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
			this.editCell();
		}
		break;

	case zenPAGEUP:
	case zenPAGEDN:
		break;

	case zenEND:
		ret = false;
		this.moveToCell(evt.ctrlKey ? 'ctrl-end' : 'end');
		break;

	case zenHOME:
		// home
		ret = false;
		this.moveToCell(evt.ctrlKey ? 'ctrl-home' : 'home');
		break;

	case zenUP:
		ret = false;
		this.moveToCell('up');
		break;
	case zenDOWN:
		ret = false;
		this.moveToCell('down');
		break;
	case zenLEFT:
		ret = false;
		this.moveToCell('left');
		break;
	case zenRIGHT:
		ret = false;
		this.moveToCell('right');
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
		if (evt.preventDefault) {
			evt.preventDefault();
		}
		evt.cancelBubble = true;
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
		// JMD850
		var charCode = (('undefined'==typeof evt.charCode) || (evt.charCode===null)) ? evt.keyCode : evt.charCode;
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
		if (evt.preventDefault) {
			evt.preventDefault();
		}
		evt.cancelBubble = true;
	}

	return ret;
}

/// Make the specified cell the current cell.<br/>
/// <var>r</var> and <var>c</var> are 1-based.<br/>
/// If <var>notify</var> is true, then raise an onSelectCell event.
ClientMethod selectCell(r, c, notify) [ Language = javascript ]
{
	try {
		// unhighlight old cell
		if (this.currRow > 0 && this.currColumn > 0) {
			var div = this.findElement("td_"+this.currRow + "_" + this.currColumn);
			if (div) {
				div.className = '';
			}
		}

		// notify
		this.currRow = r;
		this.currColumn = c;
		if (notify) {
			this.selectCellHandler(r,c);
		}

		// highlight new cell
		if (this.currRow > 0 && this.currColumn > 0) {
			var div = this.findElement("td_"+this.currRow + "_" + this.currColumn);
			if (div) {
				div.className = this.hasFocus ? 'focus' : 'selected';
				if (this.hasFocus && this.scrollIntoView) {
					// make cell visible; if we move to an edge, try to make labels visible
					var flag = false;
					if (this.currColumn == 1) {
						var lbl = this.findElement((this.currRow==1) ? "gridLabel" : "thRow_"+this.currRow);
						if (lbl) {
							zenScrollIntoView(this.getEnclosingDiv(),lbl);
							flag = true;
						}
					}
					else if (this.currRow == 1) {
						var lbl = this.findElement((this.currColumn==1) ? "gridLabel" : "thCol_"+this.currColumn);
						if (lbl) {
							zenScrollIntoView(this.getEnclosingDiv(),lbl);
							flag = true;
						}
					}

					if (!flag) {
						zenScrollIntoView(this.getEnclosingDiv(),div.parentNode);
					}
				}
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in selectCell.');
	}
}

/// Notification that user is about to move to a new cell.
ClientMethod selectCellHandler(r, c) [ Language = javascript ]
{
	zenInvokeCallbackMethod(this.onselectcell,this,'onselectcell','row',r,'col',c);
}

/// Focus passed to the grid's invisible edit control.
ClientMethod gridKeyFocus() [ Language = javascript ]
{
	this.hasFocus = true;

	// highlight current cell
	this.selectCell(this.currRow,this.currColumn,false);
}

/// Focus taken from the grid's invisible edit control.
ClientMethod gridKeyBlur() [ Language = javascript ]
{
	this.hasFocus = false;

	// highlight current cell
	this.selectCell(this.currRow,this.currColumn,false);
}

/// Return the range of selected cells or null if nothing selected.
/// The range is returned as an array of startRow,startCol,endRow,endCol.
ClientMethod getSelectedRange() [ Language = javascript ]
{
	if (''==this.selectedRange) {
		return null;
	}
	return this.selectedRange.split(',');
}

/// Set the selected cell range. Addresses are 1-based.<br/>
ClientMethod selectCellRange(startRow, startCol, endRow, endCol) [ Language = javascript ]
{
	// unselect current range
	if ('' != this.selectedRange) {
		var p = this.selectedRange.split(',');
		for (var r = parseInt(p[0]); r <= parseInt(p[2]); r++) {
			for (var c = parseInt(p[1]); c <= parseInt(p[3]); c++) {
				var cell = this.findElement('td_'+r+'_'+c);
				if (cell) {
					var color = cell._oldColor ? cell._oldColor : '';
					cell.style.color = color;
					var bg = cell._oldBackground ? cell._oldBackground : '';
					cell.style.background = bg;
				}
			}
		}
	}

	var total = 0;
	var cellCount = 0;

	if ('' == startRow) {
		this.selectedRange = '';
	}
	else {
		this.selectedRange = startRow + ',' + startCol + ',' + endRow + ',' + endCol;
		var p = this.selectedRange.split(',');
		for (var r = parseInt(p[0]); r <= parseInt(p[2]); r++) {
			for (var c = parseInt(p[1]); c <= parseInt(p[3]); c++) {
				var cell = this.findElement('td_'+r+'_'+c);
				if (cell) {
					cellCount++;
					if (cell.getAttribute && cell.getAttribute('zenValue')) {
						total += parseFloat(cell.getAttribute('zenValue'));
					}
					cell._oldColor = cell.style.color;
					cell._oldBackground = cell.style.background;
					cell.style.color = this.selectedCellColor;
					if (c==this.currColumn && r == this.currRow) {
						cell.style.background = this.selectedCellBackground;
					}
					else {
						cell.style.background = this.selectedRangeBackground;
					}
				}
			}
		}
	}
}

/// Click handler for arrows.
ClientMethod arrowHandler(which) [ Internal, Language = javascript ]
{
	zenInvokeCallbackMethod(this.onarrowclick,this,'onarrowclick','which',which);
}

}
