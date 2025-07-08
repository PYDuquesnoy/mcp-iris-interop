/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This lets a user create and edit worksheets.
/// A worksheet can be used as a source of KPI values or to drive dashboards.
Class %DeepSee.UI.WorksheetBuilder Extends %DeepSee.UI.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Worksheet Manager";

/// If this page has multiple views, this is its initial display mode.
Parameter DEFAULTVIEWMODE;

Parameter DOCBOOKID = "D2MODADV_ch_worksheet";

/// Pick up formula code.
Parameter JSINCLUDES = "dsparser.js";

/// Name of worksheet being viewed.
Property worksheetName As %String(ZENURL = "WORKSHEET");

/// Indicates what the cell value editor is showing: "cell","row", or "column".
Property whichCell As %String;

/// Local copy of worksheet object.
Property %model As %DeepSee.UserLibrary.Worksheet;

/// If true, user cannot modify the current worksheet.
/// Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];
/// If true, user can modify (non-read-only) worksheet.
/// Property canWrite As %ZEN.Datatype.boolean [ InitialExpression = 1 ];
/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

.dynaGridWrapper {
	border: 1px solid #808080;
}

body {
	background: #F8F8F8;
}

.dgCellInner {
	font-size: 12pt;
}

.zenLabel, .checkboxCaption {
	color: #404040;
	font-size: 10pt;
}
.zenLabelDisabled {
	color: #808080;
	font-size: 10pt;
}

.zenHint {
	color: #606060;
	font-size: 8pt;
}

#editGroup {
	opacity: 0.0;
	-webkit-transition-property: opacity;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;
}

#cellValue input {
	font-size: 16px;
	color: #606060;
	border-radius: 4px;
}

#help {
	padding: 10px;
	font-size: 12px;
	color: #606060;
}

#worksheet {
	width: 500px;
	height: 200px;
	border: 10px solid #E0E0E0;
	border-radius: 5px;
}

.termItemEven {
	width: 100%;
	background: #F8F8F8;
	color: #404040;
	font-family: arial;
	border-bottom: 1px solid #D0D0D0;
}

.termItemOdd {
	width: 100%;
	color: #404040;
	font-family: arial;
	border-bottom: 1px solid #D0D0D0;
}

.tlHeader {
	position: relative;
	height: 40px;
	vertical-align: middle;
	border-bottom: 1px solid white;
	padding: 4px;
	background: #808080;
	color: #F0F0F0;
	font-size: 10pt;
	font-weight: bold;
}

.tlBody {
	position: absolute;
	top: 40px;
	bottom: 0px;
	left:0px;
	right: 0px;
	background: #D0D0D0;
}

.tlItem,
.tlItemSelected {
	position: relative;
	padding: 4px;
	height: 25px;
	vertical-align: middle;
	font-size: 20px;
	color: #404040;
	background: #F0F0F0;
	border-bottom: 1px solid #D0D0D0;
}

.tlItemSelected {
	color: #F0F0F0;
	background: rgb(53,107,141);
}

.tlItem:hover {
	background: #E8E8E8;
}

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:deepsee="http://www.intersystems.com/deepsee">

<!-- data for worksheet -->
<jsonProvider id="json"
	OnGetTargetObject="GetWorksheetContent" OnSubmitContent="SubmitWorksheet">
<parameter id="pWorksheet" paramName="worksheet" />
</jsonProvider>

<hgroup id="mainGroup" cellVAlign="top">

<navigator id="navigator" 
expanded="false"
showDisclosure="true"
onexpand="zenPage.onlayoutHandler(false);"
onchange="zenPage.dataChange(key,value,final);"
onselect="zenPage.selectItem(key,value);"
onbuttonclick="zenPage.headerButtonClick(key);"
onclosebuttonclick="zenPage.closeButtonClick(key);"
ongetcontent="return zenPage.getContentForLevel(level,key,value);"
backgroundStyle="opacity:0.1;background-color:rgb(174,141,88);background-image:url(deepsee/ds_navback.png);"
/>

<vgroup id="editGroup">
<hgroup cellVAlign="middle" cellStyle="padding:2px;">
<spacer width="10"/>
<text id="cellValue" value="" onchange="zenPage.cellControlChange();"/>
<button caption="OK" onclick="zenPage.cellControlChange();"/>
<spacer width="10"/>
<button controlClass="commandButton" caption="Add Row" onclick="zenPage.addRow();"/>
<button controlClass="commandButton" caption="Add Column" onclick="zenPage.addColumn();"/>
<spacer width="30"/>
<button controlClass="commandButtonRemove" caption="Remove Row" onclick="zenPage.removeRow();"/>
<button controlClass="commandButtonRemove" caption="Remove Column" onclick="zenPage.removeColumn();"/>
</hgroup>
<dataGrid id="worksheet" hasFormulas="true"
	columnWidth="150" ongetcontroller="return zenPage;"
	onheaderclick="return zenPage.headerClick(which,index);"
	onkeydown="return zenPage.gridKeyDown(zenEvent);"
	onselectcell="zenPage.selectCell(row,col);"
	ondrawcell="return zenPage.getCellOverride(row,col);"
	selectMode="cells" multiSelect="true">
</dataGrid>
</vgroup>

</hgroup>
</pane>
}

/// Draw the help panel.
Method DrawHelp(pSeed As %String) As %Status
{
	&html<<div>>
	Write $$$TextHTML("A worksheet defines a table of data values that you can use with your Analytics applications.")
	&html<</div>>

	&html<<div>>
	Write $$$TextHTML("Use the Open command to load an existing worksheet or New to create a new one.")
	&html<</div>>
	Quit $$$OK
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $S(..worksheetName="":$$$Text("Untitled Worksheet"),1:..worksheetName)
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Worksheet Builder","%DeepSee")
}

/// Get the product name for the page.
Method %OnGetProductName() As %String
{
	Quit "DeepSee"
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Worksheet Builder")

	// commands
	// $LB(id,caption,help,onclick)

	// !!!
	Set pCommands(1) = $LB("cmdNew",$$$Text("New"),$$$Text("Create a new worksheet"),"zenPage.newWorksheet();")
	Set pCommands(2) = $LB("cmdOpen",$$$Text("Open"),$$$Text("Open an existing worksheet"),"zenPage.changeWorksheet();")
	Set pCommands(3) = $LB("cmdSave",$$$Text("Save"),$$$Text("Save this worksheet"),"zenPage.saveWorksheet(false);")
	Set pCommands(4) = $LB("cmdSaveAs",$$$Text("Save As"),$$$Text("Save a copy of this worksheet"),"zenPage.saveWorksheet(true);")
	Set pCommands(5) = $LB("cmdRemove",$$$Text("Delete"),$$$Text("Delete this worksheet"),"zenPage.deleteWorksheet();")
	// !!! Set pCommands(6) = $LB("cmdExport",$$$Text("Export"),$$$Text("Export this worksheet in CSV format"),"zenPage.exportWorksheet();")
	Quit $$$OK
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		if (load) {
			this.applyModelToGrid();
			this.selectCell(1,1);
			this.getGrid().focus();
		}
		this.adjustSizes();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Get the navigator component.
ClientMethod getNavigator() [ Language = javascript ]
{
	return zen('navigator');
}

/// Apply saved attributes to the grid component.
/// There is a copy of this method in the worksheet widget.
ClientMethod applyModelToGrid() [ Language = javascript ]
{
	var model = this.getModel();
	var grid = this.getGrid();
	if (model) {
		grid.style = zenGet(model.style);
		grid.format = zenGet(model.format);
		grid.selectMode = zenGet(model.selectMode);

		grid.columnWidth = zenGet(model.columnWidth,150);
		grid.columnHeaderStyle = zenGet(model.columnHeaderStyle);
		grid.rowHeaderStyle = zenGet(model.rowHeaderStyle);
		grid.showZebra = zenGet(model.showZebra) ? true : false;

		grid.evenRowBackground = zenGet(model.evenRowBackground,'#F8F8F8');
		grid.evenRowColor = zenGet(model.evenRowColor);
		grid.oddRowBackground = zenGet(model.oddRowBackground);
		grid.oddRowColor = zenGet(model.oddRowColor);
		grid.currCellBackground = zenGet(model.currCellBackground,'#D0D0FF');
		grid.currCellColor = zenGet(model.currCellColor,'black');
		grid.render();
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var editDiv = zen('editGroup').getEnclosingDiv();
		var grid = this.getGrid();

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		var th = this.getTitleAreaHeight();

		var fh = winHeight - th - 25;

		// update navigator
		var navigator = this.getNavigator();
		navigator.setHeight(fh);

		grid.setSize(winWidth - 50 - navigator.getWidth(),fh-75);

		// reveal
		editDiv.style.opacity = 1.0;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// This class method callback is called just before the server-side page 
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##super()
		If $$$ISERR(tSC) Quit
		
		If ($G(%request.Data("home",1))'="") {
			Set %response.Context("home") = %request.Data("home",1)
		}

		// JMD1490
		If (..worksheetName[".worksheet") {
			Set ..worksheetName = $P(..worksheetName,".",1,$L(..worksheetName,".")-1)
		}

		Set tParm = ..%GetComponentById("pWorksheet")
		Set tParm.value = ..worksheetName

		// load model
		If $IsObject(..%model) {
			Set tWorksheet = ..%model
		}
		Else {
			Set tParms("worksheet") = ..worksheetName
			Set tSC = ..GetWorksheetContent(.tParms,.tWorksheet)
		}

		// test for write access
		If $IsObject(tWorksheet) {
			If ((tWorksheet.resource'="")&&'$System.Security.Check(tWorksheet.resource,"WRITE")) {
				Set ..readOnly = 1
			}

			Set tSC = ##class(%DeepSee.UserLibrary.Utils).%RegisterRecentItem("worksheet",tWorksheet.fullName)
			If $$$ISERR(tSC) Quit
		}

		// JMD1221
		// turn off backing style for IE!
		Set:$$$ZENISIE ..%GetComponentById("navigator").backgroundStyle = ""
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Launch the worksheet finder dialog.
ClientMethod changeWorksheet() [ Language = javascript ]
{
	if (this.pageModified) {
		if (!confirm($$$Text('There are unsaved changes, do you wish to continue?'))) {
			return;
		}
	}
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=worksheets','Worksheet','status,scrollbars,resizable=yes,width=800,height=600');
}

/// Launch the subject area finder.
ClientMethod browseSubjectAreas() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=subjectAreas','SubjectArea','status,scrollbars,resizable=yes,width=800,height=600');
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'switchNamespace':
		var homeurl = zenLink("/csp/sys/%25CSP.Portal.Home.zen");
		var url = zenPage.GetNewURL(value,"_DeepSee.UI.WorksheetBuilder.zen");
		if (url == "" || value == "%SYS") url = homeurl;
		try {
			self.document.location = url;
		}
		catch(ex) {
		}
		break;
	case 'ColorWheel':
		zenPage.getNavigator().applyValue(value,true);
		break;

	case 'SubjectArea':
		// strip off extension
		var name = '';
		var s = value.toString().split('.');
		s.length = s.length-1;
		name = s.join('.');
		zen('ctrlSubject').setValue(name);
		break;

	case 'Worksheet':
		// strip off extension
		var name = '';
		var s = value.toString().split('.');
		s.length = s.length-1;
		name = s.join('.');

		if (name != this.worksheetName) {
			try {
				self.document.location = zenLink('_DeepSee.UI.WorksheetBuilder.cls' + '?WORKSHEET=' + encodeURIComponent(name));
			}
			catch (ex) {
			}
		}
		break;
	case 'WorksheetSave':
		var json = zen('json');
		var model = this.getModel();

		var rename = (this.worksheetName!=this._oldName);
		var ok = json.submitContent('save','%ZEN.proxyObject')
		if (!ok) {
			alert(json.getError());
		}
		else {
			this.setModified(false);
			if (rename) {
				// show new item
				try {
					self.document.location = zenLink('_DeepSee.UI.WorksheetBuilder.cls' + '?WORKSHEET=' + encodeURIComponent(this.worksheetName));
				}
				catch(ex) {
				}
			}
			else {
				this.getNavigator().refreshTopSheet();
			}
		}
		break;
	}
}

/// Test if the user has write privilege.
ClientMethod canUserModify() [ Language = javascript ]
{
	if (!this.canWrite) {
		alert($$$Text('You are not authorized to save worksheets.'));
		return false;
	}
	if (this.readOnly) {
		alert($$$Text('This worksheet is read only.'));
		return false;
	}
	return true
}

/// If true, user cannot modify the current worksheet.
Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, user can modify (non-read-only) worksheet.
Property canWrite As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Change in search box value. Can be overridden by subclasses.
ClientMethod searchBoxHandler(searchKey) [ Language = javascript ]
{
	this.searchKey = searchKey;
	this.updateList();
}

/// Get the json-supplied data model.
ClientMethod getModel() [ Language = javascript ]
{
	return zen('json').getContentObject();
}

/// Click on header in grid.
ClientMethod headerClick(which, index) [ Language = javascript ]
{
	// we are also going to get a selectCell event,
	// so set up for that!
	if (which=='column') {
		this.whichCell = 'columnClick';
	}
	else if (which=='row') {
		this.whichCell = 'rowClick';
	}
	return true;
}

/// Add a row to the grid
ClientMethod addRow() [ Language = javascript ]
{
	var grid = this.getGrid();
	var model = this.getModel();

	var index = grid.currRow-1;
	if (model && this.canUserModify()) {
		// header
		if (!model.rowHeaders) {
			model.rowHeaders = [];
			index = 0;
		}
		var newHeader = {name:model.rowHeaders.length+1};
		model.rowHeaders.push(newHeader);
		this.setModified(true);

		// data
		if (!model.values) {
			model.values = [];
		}
		var newRow = [];
		for (var c = 0; c < model.columnHeaders.length; c++) {
			newRow[c] = '';
		}
		model.values.push(newRow);
		grid.render();
	}
}

/// Add a column to the grid
ClientMethod addColumn() [ Language = javascript ]
{
	var grid = this.getGrid();
	var model = this.getModel();

	var index = grid.currColumn-1;
	if (model && this.canUserModify()) {
		// header
		if (!model.columnHeaders) {
			model.columnHeaders = [];
			index = 0;
		}
		var newHeader = {name:'Column ' + (model.columnHeaders.length+1)};
		model.columnHeaders.push(newHeader);
		this.setModified(true);

		// data
		if (!model.values) {
			model.values = [];
		}
		for (var r = 0; r < model.rowHeaders.length; r++) {
			model.values[r].push('');
		}
		grid.render();
	}
}

/// Remove a row from the grid.
ClientMethod removeRow() [ Language = javascript ]
{
	var grid = this.getGrid();
	var model = this.getModel();

	var index = grid.currRow-1;
	if (model && this.canUserModify()) {
		// header
		if (model.rowHeaders && model.rowHeaders.length>1  && confirm($$$Text('Do you wish to delete the selected row?'))) {
			model.rowHeaders.splice(index,1);
			this.setModified(true);
			// data
			if (model.values) {
				model.values.splice(index,1);
			}
		}
		grid.render();
	}
}

/// Remove a column from the grid.
ClientMethod removeColumn() [ Language = javascript ]
{
	var grid = this.getGrid();
	var model = this.getModel();

	var index = grid.currColumn-1;
	if (model && this.canUserModify()) {
		// header
		if (model.columnHeaders && model.columnHeaders.length>1 && confirm($$$Text('Do you wish to delete the selected column?'))) {
			model.columnHeaders.splice(index,1);
			this.setModified(true);
			// data
			if (model.values) {
				for (var r = 0; r < model.rowHeaders.length; r++) {
					model.values[r].splice(index,1);
				}
			}
		}
		grid.render();
	}
}

/// Create a new worksheet.
ClientMethod newWorksheet() [ Language = javascript ]
{
	if (this.pageModified) {
		if (!confirm($$$Text('There are unsaved changes, do you wish to continue?'))) {
			return;
		}
	}
	try {
		self.document.location = zenLink('_DeepSee.UI.WorksheetBuilder.cls');
	}
	catch(ex) {
	}
}

/// Export the worksheet.
ClientMethod exportWorksheet() [ Language = javascript ]
{
	if (this.pageModified) {
		if (!confirm($$$Text('There are unsaved changes, do you wish to continue?'))) {
			return;
		}
	}
	window.open(zenLink('_DeepSee.UI.WorksheetExport.cls' + '?WORKSHEET=' + encodeURIComponent(this.worksheetName)));
}

/// Delete the worksheet.
ClientMethod deleteWorksheet() [ Language = javascript ]
{
	if (confirm($$$Text('Do you wish to delete this worksheet?'))) {
		alert(this.Delete(this.worksheetName));
		try {
			self.document.location = zenLink('_DeepSee.UI.WorksheetBuilder.cls');
		}
		catch(ex) {
		}
	}
}

/// Launch the save worksheet dialog.
ClientMethod saveWorksheet(showDialog) [ Language = javascript ]
{
	if (!this.canUserModify()) {
		return;
	}

	var model = this.getModel();
	
	this._oldName = this.worksheetName;

	if (showDialog || this.worksheetName==='') {
		// show save dialog
		var parms = {
				WORKSHEET:this.worksheetName,
				DESC:model.description,
				RESOURCE:model.resource,
				OWNER:model.owner,
				LOCKED:model.locked?1:0,
				PUBLIC:model.public?1:0,
				WORDS:model.keywords
				};
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.WorksheetSave.zen','WorksheetSave','status,scrollbars,resizable=yes,width=700,height=600',parms);
	}
	else {
		this.onPopupAction('WorksheetSave','','');
	}
}

/// Get content object for JSON provider.
Method GetWorksheetContent(ByRef pParameters, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		If $IsObject(..%model) {
			Set pObject = ..%model
			Quit
		}
	
		Set tWorksheetName = $G(pParameters("worksheet"))
		Set tSC = ##class(%DeepSee.WorksheetEngine).%LoadWorksheet(tWorksheetName,0,.pObject)
		If $$$ISERR(tSC) Quit

		Set ..%model = pObject
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Object submit handler JSON provider.
/// This is called when the client saves the worksheet.
Method SubmitWorksheet(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, ByRef pResponseObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tName = pSubmitObject.name
		Set tFolder = pSubmitObject.folderName
		If (tName'="") {
			Set tWorksheetName = tFolder _ $S(tFolder="":"",1:"/") _ tName _ ".worksheet"
			Set tSC = ##class(%DeepSee.WorksheetEngine).%SaveWorksheet(tWorksheetName,pSubmitObject)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Delete a worksheet.
Method Delete(pName As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	
	Set tMsg = $$$Text("Worksheet deleted.")
	If (pName'="") {
		Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderItem(pName_".worksheet")
		If $$$ISERR(tSC) {
			Set tMsg = $System.Status.GetErrorText(tSC)
		}
	}
	Quit tMsg
}

/// This callback is called when the upload form on this page is submitted.
/// <var>pSubmit</var> is a <class>%ZEN.Submit</class> object
/// containing details of the form submit.<br/>
ClassMethod %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tName = pSubmit.%GetValue("Name")
		Set tStream = pSubmit.%GetStream("File")

		If ((tName'="")&&($IsObject(tStream))) {
			Set tSC = ##class(%DeepSee.TermList).%ImportCSV(tStream,tName,0)
		}
		Set %response.Context("WORKSHEET") = tName
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Change to value in cell value control.
ClientMethod cellControlChange() [ Language = javascript ]
{
	var value = zen('cellValue').getValue();
	if (!isNaN(parseInt(value,10)) && (value==parseInt(value,10))) {
		value = parseInt(value,10);
	}
	if (!isNaN(parseFloat(value)) && (value==parseFloat(value))) {
		value = parseFloat(value);
	}
	
	var grid = this.getGrid();
	var model = this.getModel();

	// apply value directly to model
	var model = this.getModel();

	if (model) {
		switch (this.whichCell) {
		case 'row':
			if (model.rowHeaders) {
				if (model.rowHeaders[grid.currRow-1].name != value) {
					this.setModified(true);
				}
				model.rowHeaders[grid.currRow-1].name = value;
			}
			break;
		case 'column':
			if (model.columnHeaders) {
				if (model.columnHeaders[grid.currColumn-1].name != value) {
					this.setModified(true);
				}
				model.columnHeaders[grid.currColumn-1].name = value;
			}
			break;
		default:
			if (model.values) {
				if (model.values[grid.currRow-1][grid.currColumn-1] != value) {
					this.setModified(true);
				}
				model.values[grid.currRow-1][grid.currColumn-1] = value;
			}
			break;
		}
		grid.render();
	}
}

/// Get cell override.
ClientMethod getCellOverride(row, col) [ Language = javascript ]
{
	var info = null;
	// test for cell overrides
	var model = this.getModel();
	if (model && model.cells && model.cells.length) {
		for (var n = 0; n < model.cells.length; n++) {
			var cell = model.cells[n];
			if (cell && cell.row==row && cell.column == col) {
				info = {};
				if (cell.format) {
					info.format = cell.format;
				}
				if (cell.style) {
					info.style = cell.style;
				}
				break;
			}
		}
	}
	return info;
}

/// Select cell handler.
ClientMethod selectCell(row, col) [ Language = javascript ]
{
	var grid = this.getGrid();

	switch (this.whichCell) {
	case 'rowClick':
		this.whichCell = 'row';
		var value = grid.getRowDescriptor(row-1).name;
		break;
	case 'columnClick':
		this.whichCell = 'column';
		var value = grid.getColumnDescriptor(col-1).name;
		break;
	default:
		this.whichCell = 'cell';
		var value = grid.getCellData(row-1,col-1);
		break;
	}

	zen('cellValue').setValue(value);
}

/// Get the grid component.
ClientMethod getGrid() [ Language = javascript ]
{
	return zen('worksheet');
}

/// Key down handler for grid.
ClientMethod gridKeyDown(evt) [ Language = javascript ]
{
	var grid = this.getGrid();
	if (evt.ctrlKey && evt.keyCode == 67) {
		// copy
		this._clipboard = grid.getCellData(grid.getCurrRow()-1,grid.getCurrColumn()-1);
	}
	else if (evt.ctrlKey && evt.keyCode == 86) {
		// paste
		if (this._clipboard) {
			grid.setCellValue(this._clipboard,grid.getCurrRow()-1,grid.getCurrColumn()-1);
		}
	}
	else if (evt.ctrlKey && evt.keyCode == 88) {
		// cut
		this._clipboard = grid.getCellValue(grid.getCurrRow()-1,grid.getCurrColumn()-1);
		grid.setCellValue('',grid.getCurrRow()-1,grid.getCurrColumn()-1);
	}
	return true;
}

/// Return an array of row descriptors (or null).
ClientMethod getRowDescriptors() [ Language = javascript ]
{
	var model = this.getModel();
	if (model && model.rowHeaders) {
		return model.rowHeaders;
	}
	return null;
}

/// Return an array of column descriptors (or null).
ClientMethod getColumnDescriptors() [ Language = javascript ]
{
	var model = this.getModel();
	if (model && model.columnHeaders) {
		return model.columnHeaders;
	}
	return null;
}

/// Controller API
ClientMethod getDimSize(dim) [ Language = javascript ]
{
	var model = this.getModel();
	if (model) {
		switch (dim) {
		case 1:
			// rows
			return (model.rowHeaders && model.rowHeaders.length) ? model.rowHeaders.length : 1;
		case 2:
			// columns
			return (model.columnHeaders && model.columnHeaders.length) ? model.columnHeaders.length : 1;
		}
	}
	return '';
}

/// dataSet API
/// Get the label at position n (0-based) in the given
/// dimension (1,2, or 3).
ClientMethod getLabel(n, dim) [ Language = javascript ]
{
	var model = this.getModel();

	switch (dim) {
	case 1:
		if (model && model.rowHeaders) {
			return model.rowHeaders[n].name;
		}
		break;
	case 2:	
		if (model && model.columnHeaders) {
			return model.columnHeaders[n].name;
		}
		break;
	}
	return '';
}

/// dataSet API
/// Return the data contained in the specified location.
/// Location is 0-based;
ClientMethod getData(d1, d2, d3) [ Language = javascript ]
{
	var value = '';
	var model = this.getModel();

	if (model && model.values) {
		value = model.values[d1] ? model.values[d1][d2] : '';
	}
	return value;
}

/// dataBag API
/// Get a data value, by property name, from this dataController.
ClientMethod getDataByName(prop, series) [ Language = javascript ]
{
	var value = '';
	var model = this.getModel();

	if (model && model.values) {
		// find col # for prop
		var cols = model.values[series].length;
		var col = -1;
		for (var n = 0; n < cols; n++) {
			if (model.columnHeaders[n].name == prop) {
				col = n;
				break;
			}
		}
		if (col>=0) {
			value = model.values[series][col];
		}
	}
	return value;
}

/// Given a 0-based index, return the corresponding property name.
ClientMethod getPropertyName(n) [ Language = javascript ]
{
	var model = this.getModel();
	if (model && model.columnHeaders && model.columnHeaders[n]) {
		return model.columnHeaders[n].name;
	}
	return '';
}

/// Notification from the dataGrid.
ClientMethod notifyController(source, reason, prop, value, row) [ Language = javascript ]
{
	var model = this.getModel();

	if (model && model.values) {
		// find col # for prop
		var cols = model.values[row] ? model.values[row].length : 0;
		var col = -1;
		for (var n = 0; n < cols; n++) {
			if (model.columnHeaders[n].name == prop) {
				col = n;
				break;
			}
		}
		if (col>=0) {
			if (model.values[row][col] != value) {
				this.setModified(true);
			}
			model.values[row][col] = value;
			this.selectCell(row+1,col+1);
		}
	}
	return value;
}

/// Return an object describing what to display for this level within the navigator.
ClientMethod getContentForLevel(level, key, value) [ Language = javascript ]
{
	var title = level==0 ? $$$Text('Worksheet') : key;
	var content = { title: title, items:[] };
	var grid = this.getGrid();
	var navigator = this.getNavigator();
	var model = this.getModel();

	// key may take the form <item>:keyNo
	var keyNo = '';
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		key = t[0];
		keyNo = parseInt(t[1]);
	}

	// get attribute name from key
	var t = key.toString().split('-');
	t.splice(0,1);
	var attr = t.join('-');

	switch (key) {
	case '':
		// root
		content.items[content.items.length] = {display:'caption', caption:$$$Text('General'), action:'drill', key:'General'};
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Style'), action:'drill', key:'Style'};
		break;

	case 'General':
		content.title = $$$Text('General');
		var locked = false;

		// show name read-only
		var folder = zenGet(model.folderName);
		var name = zenGet(model.name);
		if (folder) {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Folder','%DeepSee'), value:folder};
		}
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Name','%DeepSee'), value:name};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title','%DeepSee'), value:zenGet(model.title), edit:'string', key:'wsTitle'};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Locked','%DeepSee'), edit:'switch', value:zenGet(model.locked), key:'wsLocked', help:$$$Text('If true, then further changes to this item are not allowed without unlocking it.','%DeepSee')};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Public','%DeepSee'), edit:'switch', value:zenGet(model.public), key:'wsPublic', help:$$$Text('If true, this dashboard is listed in the portal home page','%DeepSee'), disabled:locked};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Owner','%DeepSee'), edit:'', action:'', value:zenGet(model.owner), key:'wsOwner'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Resource','%DeepSee'), edit:'', value:zenGet(model.resource), action:'', key:'wsResource', help:$$$Text('Name of resource used to grant access to this item.','%DeepSee')};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Category','%DeepSee'), edit:'string', value:zenGet(model.category), key:'wsCategory'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Description','%DeepSee'), edit:'string', value:zenGet(model.description), key:'wsDescription'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Keywords','%DeepSee'), edit:'string', value:zenGet(model.keywords), key:'wsKeywords'};
		break;

	case 'Style':
		content.title = $$$Text('Style');
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Stripes'), edit:'switch', value:zenGet(grid.showZebra),	key:'showZebra'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Column Labels'), edit:'switch', value:zenGet(grid.showColumnLabels),	key:'showColumnLabels', labelStyle:'font-size:13pt;'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Row Labels'), edit:'switch', value:zenGet(grid.showRowLabels),	key:'showRowLabels'};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Select Mode'), edit:'choice', value:zenGet(grid.selectMode),	key:'selectMode', valueList:'cells,rows', displayList:'Cells,Rows'};
		// content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Row Selector'), edit:'switch', value:zenGet(grid.showRowSelector),	key:'showRowSelector'};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Column Width','%DeepSee'), edit:'slider-toggle', value:zenGet(grid.columnWidth), key:'columnWidth', minValue:0, maxValue:500};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Label Width','%DeepSee'), edit:'slider-toggle', value:zenGet(grid.rowLabelWidth), key:'rowLabelWidth', minValue:0, maxValue:500};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Format'), edit:'string', action:'drill', value:zenGet(grid.format),	key:'format'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Cell Style'), action:'drill', value:zenGet(grid.style),	key:'style', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Row Style'), action:'drill', value:zenGet(grid.rowHeaderStyle),	key:'rowHeaderStyle', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Column Style'), action:'drill', value:zenGet(grid.columnHeaderStyle),	key:'columnHeaderStyle', text:''};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Even Color'), action:'drill', value:zenGet(grid.evenRowColor),	key:'evenRowColor', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Even BG'), action:'drill', value:zenGet(grid.evenRowBackground),	key:'evenRowBackground', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Odd Color'), action:'drill', value:zenGet(grid.oddRowColor),	key:'oddRowColor', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Odd BG'), action:'drill', value:zenGet(grid.oddRowBackground),	key:'oddRowBackground', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Selected Color'), action:'drill', value:zenGet(grid.currCellColor),	key:'currCellColor', text:''};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Selected BG'), action:'drill', value:zenGet(grid.currCellBackground),	key:'currCellBackground', text:''};
		break;

	case 'format':
		// choose a format
		content.title = $$$Text('Numeric Format','%DeepSee');
		var list = [
			{ caption:$$$Text('###','%DeepSee'), value:'###'},
			{ caption:$$$Text('###.#','%DeepSee'), value:'###.#'},
			{ caption:$$$Text('###.##','%DeepSee'), value:'###.##'},
			{ caption:$$$Text('###.###','%DeepSee'), value:'###.###'},
			{ caption:$$$Text('#,##','%DeepSee'), value:'#,##'},
			{ caption:$$$Text('#,##.#','%DeepSee'), value:'#,##.#'},
			{ caption:$$$Text('#,##.##','%DeepSee'), value:'#,##.##'},
			{ caption:$$$Text('#,##.###','%DeepSee'), value:'#,##.###'},
			{ caption:$$$Text('##.##%','%DeepSee'), value:'##.##%'},
		];
		content.html = navigator.getChooserListHTML(list,key,value,$$$Text('Format','%DeepSee'),$$$Text('Choose a numeric format','%DeepSee'));
		break;

	case 'enclosingStyle':
	case 'style':
	case 'rowHeaderStyle':
	case 'columnHeaderStyle':
	case 'gridTitleStyle':
		content.title = $$$Text('Style');
		var style = zenGet(grid[attr]);
		var info = navigator.parseStyle(value);

		var color = info.color;
		var background = info.backgroundColor;
		var fontFamily = info.fontFamily;
		var fontSize = info.fontSize;
		var align = zenGet(info.textAlign);
		
		var fs = [];
		if (info.bold) { fs[fs.length] = 'bold'; }
		if (info.underline) { fs[fs.length] = 'underline'; }
		if (info.italic) { fs[fs.length] = 'italic'; }
		if (info.smallCaps) { fs[fs.length] = 'smallCaps'; }
		if (info.shadow) { fs[fs.length] = 'shadow'; }
		var fontStyle = fs.join(',');
		var opacity = zenGet(info.opacity);
		opacity = opacity === '' ? 1.0 : opacity;
		var which = key;
		var idx = '';

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Color','%DeepSee'), action:'drill', value:'',	key:which+'-color'+idx, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+color+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background','%DeepSee'), action:'drill', value:'',	key:which+'-background'+idx, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+background+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font','%DeepSee'), action:'drill', value:fontFamily,	key:which+'-font-family'+idx, valueStyle:'font-size:13px;font-family:'+fontFamily+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font Size','%DeepSee'), edit:'slider-toggle', value:fontSize,	key:which+'-font-size'+idx, minValue:2, maxValue:75, stepSize:1};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text Style','%DeepSee'), edit:'choice-multi', value:fontStyle,	key:which+'-textStyle'+idx, valueList:'bold,italic,smallCaps,shadow', displayList:'B,I,Cc,S', valueStyle:'font-size:12px;font-family:times new roman;',  choiceStyles:'font-weight:900;^font-style:italic;^font-variant:small-caps;^text-shadow:1px 1px 2px #F0F0F0;'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Align','%DeepSee'), edit:'choice', value:align,	key:which+'-text-align'+idx, valueList:',left,center,right', displayList:',&#9664;,&#9632;,&#9654;'};
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Padding','%DeepSee'), edit:'slider-toggle', value:zenGet(info.padding),	key:which+'-padding'+idx, minValue:0, maxValue:25};
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Width','%DeepSee'), edit:'slider-toggle', value:zenGet(info.width),	key:which+'-width'+idx, minValue:0, maxValue:1200};
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Height','%DeepSee'), edit:'slider-toggle', value:zenGet(info.height),	key:which+'-height'+idx, minValue:0, maxValue:250};
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Opacity','%DeepSee', edit:'slider-toggle', value:opacity,		key:which+'-opacity'+idx, minValue:0, maxValue:1};
		break;

	case 'evenRowColor':
	case 'evenRowBackground':
	case 'oddRowColor':
	case 'oddRowBackground':
	case 'currCellColor':
	case 'currCellBackground':
	case 'enclosingStyle-color':
	case 'style-color':
	case 'rowHeaderStyle-color':
	case 'columnHeaderStyle-color':
	case 'gridTitleStyle-color':
	case 'enclosingStyle-background':
	case 'style-background':
	case 'rowHeaderStyle-background':
	case 'columnHeaderStyle-background':
	case 'gridTitleStyle-background':
		content.title = $$$Text('Color');
		// choose a color
		content.html = navigator.getColorChooserHTML(key,value,'html');
		break;

	case 'enclosingStyle-font-family':
	case 'style-font-family':
	case 'rowHeaderStyle-font-family':
	case 'columnHeaderStyle-font-family':
	case 'gridTitleStyle-font-family':
		content.title = $$$Text('Font','%DeepSee');

		// choose a font
		var t = key.toString().split('-');
		var which = t[1];
		content.html = navigator.getFontChooserHTML(which+'-font-family',value);
		break;
	}

	return content;
}

/// Data change in navigator
ClientMethod dataChange(key, value, final) [ Language = javascript ]
{
	var grid = this.getGrid();
	var navigator = this.getNavigator();
	var model = this.getModel();

	// key may take the form <item>:keyNo
	var keyNo = 0;
	if (key.toString().indexOf(':')>0) {
		var t = key.split(':');
		key = t[0];
		keyNo = parseInt(t[1]);
	}

	// pull apart key
	var t = key.toString().split('-');
	var attr = t[0];

	t.splice(0,1);
	var k2 = t.join('-');

	// apply change
	switch (attr) {
	case 'wsLocked':
		// don't set model.locked until we save!
		// !!! this.setProperty('dashboardLocked',value);
		navigator.refreshTopSheet();
		this.setModified(true);
		break;

	case 'wsPublic':
		model.public = value;
		this.setModified(true);
		break;

	case 'wsTitle':
		if (final) {
			model.title = value;
			this.setModified(true);
		}
		break;

	case 'wsOwner':
		if (final) {
			this.dashboardOwner = value;
			model.owner = value;
			this.setModified(true);
		}
		break;

	case 'wsResource':
		if (final) {
			this.dashboardResource = value;
			model.resource = value;
			this.setModified(true);
		}
		break;
	case 'wsCategory':
		if (final) {
			model.category = value;
			this.setModified(true);
		}
		break;
	case 'wsDescription':
		if (final) {
			model.description = value;
			this.setModified(true);
		}
		break;
	case 'wsKeywords':
		if (final) {
			model.keywords = value;
			this.setModified(true);
		}
		break;

	case 'evenRowBackground':
	case 'evenRowColor':
	case 'oddRowBackground':
	case 'oddRowColor':
	case 'currCellBackground':
	case 'currCellColor':
		grid.setProperty(attr,value);
		// apply to model
		if (final && model[attr] != value) {
			model[attr] = value;
			this.setModified(true);
		}
		break;


	case 'evenRowStyle':
	case 'rowHeaderStyle':
	case 'columnHeaderStyle':
	case 'style':
		var style = zenGet(grid[attr]);
		switch(k2) {
		case 'color':
		case 'background':
		case 'font-family':
		case 'opacity':
		case 'displayed':
		case 'text-align':
			style = navigator.setStyleIntoCSS(style,k2,value);
			break;
		case 'textStyle':
			var styleValues = {};
			var cv = value.toString().split(',');
			for (var n = 0; n < cv.length; n++) {
				styleValues[cv[n]] = true;
			}
			var list = ['bold','underline','italic','smallCaps','shadow'];
			for (var n = 0; n < list.length; n++) {
				style = navigator.setStyleIntoCSS(style,list[n],styleValues[list[n]]?true:false);
			}
			break;

		case 'border-radius':
		case 'font-size':
		case 'padding':
		case 'margin':
		case 'top':
		case 'left':
		case 'height':
		case 'width':
			value = value!=='' ? value+'px' : value;
			style = navigator.setStyleIntoCSS(zenGet(style),k2,value);
			break;
		}
		grid.setProperty(attr,style);

		// apply to model
		if (final && model[attr] != style) {
			model[attr] = style;
			this.setModified(true);
		}
		break;

	case 'selectMode':
	case 'showRowSelector':
	default:
		grid.setProperty(attr,value);
		// apply to model
		if (final && model[attr] != value) {
			model[attr] = value;
			this.setModified(true);
		}
		break;
	}
}

/// Item selected in navigator.
ClientMethod selectItem(key, value) [ Language = javascript ]
{
}

/// Launch the color chooser.
ClientMethod launchColorChooser() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.ColorWheel.zen','ColorWheel','status,scrollbars,resizable=yes,width=400,height=650');
}

/// Test for additional resources.
ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	// DTB287 - Redirect to the error page if privileges are not met
	Set tUse = $System.Security.Check("%DeepSee_PortalEdit","USE")
	
	If 'tUse {
		Set %response.Redirect = ##class(%DeepSee.Utils).%GetErrorPageURL("Privilege")
	}
	
	Quit tUse
}

}
