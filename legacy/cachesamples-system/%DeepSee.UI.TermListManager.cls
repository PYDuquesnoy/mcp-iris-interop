/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// DeepSee term list manager page.
/// This page lets you view and edit "term lists" (lookup tables used by DeepSee models).
Class %DeepSee.UI.TermListManager Extends %DeepSee.UI.standardPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Term List Manager";

/// If this page has multiple views, this is its initial display mode.
Parameter DEFAULTVIEWMODE;

Parameter DOCBOOKID = "D2MODADV_ch_term_list";

Parameter RESOURCE = "%DeepSee_PortalEdit";

/// Name of term list.
Property termListName As %ZEN.Datatype.string(ZENURL = "TERMLIST");

Property replaceExisting As %ZEN.Datatype.string(ZENURL = "REPLACE");

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

#propertyGroup {
	position: relative;
	width: 320px;
	opacity: 0.0;
	-webkit-transition-property: opacity;
	-webkit-transition-duration: 0.5s;
	-webkit-transition-timing-function: ease;
	-moz-transition-property: opacity;
	-moz-transition-duration: 0.5s;
	-moz-transition-timing-function: ease;

	border-left: 1px solid #808080;
	border-right: 1px solid #808080;
	border-bottom: 1px solid #808080;
	overflow: auto;
background: #f6f8f9; /* Old browsers */
background: -moz-linear-gradient(-45deg,  #f6f8f9 0%, #e5ebee 50%, #d7dee3 51%, #f5f7f9 100%); /* FF3.6+ */
background: -webkit-gradient(linear, left top, right bottom, color-stop(0%,#f6f8f9), color-stop(50%,#e5ebee), color-stop(51%,#d7dee3), color-stop(100%,#f5f7f9)); /* Chrome,Safari4+ */
background: -webkit-linear-gradient(-45deg,  #f6f8f9 0%,#e5ebee 50%,#d7dee3 51%,#f5f7f9 100%); /* Chrome10+,Safari5.1+ */
background: -o-linear-gradient(-45deg,  #f6f8f9 0%,#e5ebee 50%,#d7dee3 51%,#f5f7f9 100%); /* Opera 11.10+ */
background: -ms-linear-gradient(-45deg,  #f6f8f9 0%,#e5ebee 50%,#d7dee3 51%,#f5f7f9 100%); /* IE10+ */
background: linear-gradient(-45deg,  #f6f8f9 0%,#e5ebee 50%,#d7dee3 51%,#f5f7f9 100%); /* W3C */
filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#f6f8f9', endColorstr='#f5f7f9',GradientType=1 ); /* IE6-9 fallback on horizontal gradient */
}

.gridLabel {
	color: #808080;
	padding: 3px;
	font-size: 24px;
}

#help {
	padding: 10px;
	font-size: 12px;
	color: #606060;
}

#termList {
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

<!-- data for current term list -->
<jsonProvider id="json" contentType="array" propertyList="key,value"
	OnGetTargetObject="GetTermListContent" OnSubmitContent="SubmitTermList">
<parameter id="pTermList" paramName="termlist" />
</jsonProvider>

<hgroup id="mainGroup" cellVAlign="top">

<vgroup id="editGroup">
<dataGrid id="termList" label="Terms" labelClass="gridLabel" 
	columnWidth="150" controllerId="json" 
	onheaderclick="return zenPage.headerClick(which,index);"
	onkeydown="return zenPage.gridKeyDown(zenEvent);"
	selectMode="cells" multiSelect="false" format="" alwaysString="true">
<columnDescriptor id="gcKey" value="=[@key]" caption="Key"/>
<columnDescriptor id="gcValue" value="=[@value]" caption="Value"/>
</dataGrid>
</vgroup>

<vgroup id="propertyGroup">
<html id="help" OnDrawContent="DrawHelp"/>
<form id="theForm" labelPosition="top" cellStyle="padding: 3px;" onchange="zenPage.formChanged(control);">
<text id="ctrlCaption" size="30" label="Caption"/>
<hgroup cellVAlign="top" label="Subject Area" hint="Optional name of the subject area that uses this term list" cellStyle="padding-right:3px;" >
<text id="ctrlSubject" size="30"/>
<image src="deepsee/ds2_magnify_18.png" width="16px" onclick="zenPage.browseSubjectAreas();" title="Choose a subject area"/>
</hgroup>
<textarea id="ctrlDescription" label="Description" rows="2" cols="22"/>
<text id="ctrlPattern" label="Pattern"  size="40" hint="Pattern to apply to values: e.g. [Outlet].[*]"/>
<checkbox id="ctrlHideValue" caption="Hide Value Column"/>
<spacer height="2"/>
<hgroup id="columnGroup" label="Field Name" cellVAlign="top" hint="Enter name of field to add or remove" cellStyle="padding-right:3px;">
<text id="ctrlColumnName" />
<image src="deepsee/ds2_plus_16.png" width="16px" onclick="zenPage.addColumn();" title="Add an additional field"/>
<image src="deepsee/ds2_x_44.png" width="16px" onclick="zenPage.deleteColumn();" title="Delete this field"/>
</hgroup>
<spacer height="2"/>
<hgroup id="btnGroup" cellVAlign="top">
<button caption="Add Term" controlClass="commandButton" onclick="zenPage.addRow();" />
<button caption="Remove Term" controlClass="commandButtonRemove" onclick="zenPage.removeRow();"/>
</hgroup>
</form>
<form id="uploadForm" enctype="multipart/form-data" labelPosition="top" cellStyle="padding: 3px;">
<hidden id="ctrlHidden" name="Name"/>
<fileUpload id="ctrlUpload" label="CSV File to import" name="File" onchange="zenPage.changeTermListFromUpload();" size="30" accept=".csv,.xls,.xlsx"/>
<hidden id="ctrlName" name="FileName"/>
<submit id="btnImport" caption="Import"/>
</form>

</vgroup>

</hgroup>
</pane>
}

/// Draw the help panel.
Method DrawHelp(pSeed As %String) As %Status
{
	&html<<div>>
	Write $$$TextHTML("A term list defines a set of key/value pairs that you can use with your data models.")
	&html<</div>>

	&html<<div>>
	Write $$$TextHTML("Use the Open command to load an existing term list or New to create a new one.")
	&html<</div>>
	Quit $$$OK
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $S(..termListName="":"Term List",1:..termListName)
}

/// Get the title string to add to the locator row.
/// This should be implemented in a subclass.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return zenPage.termListName;
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Term List Manager","%DeepSee")
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
	Set pRibbonTitle = $$$Text("Term List Manager")

	// commands
	// $LB(id,caption,help,onclick)

	Set pCommands(1) = $LB("cmdNew",$$$Text("New"),$$$Text("Create a new term list"),"zenPage.newTermList();")
	Set pCommands(2) = $LB("cmdOpen",$$$Text("Open"),$$$Text("Open an existing term list"),"zenPage.changeTermList();")
	Set pCommands(3) = $LB("cmdSave",$$$Text("Save"),$$$Text("Save this term list"),"zenPage.saveTermList(false);")
	Set pCommands(4) = $LB("cmdSaveAs",$$$Text("Save As"),$$$Text("Save a copy this term list"),"zenPage.saveTermList(true);")
	Set pCommands(5) = $LB("cmdRemove",$$$Text("Delete"),$$$Text("Delete this term list"),"zenPage.deleteTermList();")
	Set pCommands(6) = $LB("cmdExport",$$$Text("Export"),$$$Text("Export this term list in CSV format"),"zenPage.exportTermList();")
	Quit $$$OK
}

Method overwriteTermList(pStreamId As %Integer, pTermListName) As %Status [ ZenMethod ]
{
	Set tSC = $$$OK
	Try {
		Set tStream = ##class(%Stream.GlobalCharacter).%OpenId(pStreamId)
		If ($IsObject(tStream)) {
			Set tSC = ##class(%DeepSee.TermList).%ImportCSV(tStream,pTermListName,0)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()	
	}
	Quit tSC
}

Method getTermListNameFromStream(pStreamId As %Integer) As %String [ ZenMethod ]
{
	Set tStreamName = ""
	Set tStream = ##class(%Stream.GlobalCharacter).%OpenId(pStreamId)
	If ($IsObject(tStream)) {
		Set tSC = ##class(%DeepSee.TermList).%GetTermListNameFromStream(tStream,.tStreamName)
		If $$$ISERR(tSC) Quit
	}
	Quit tStreamName
}

Method termListExists(pTermListName As %String) As %Boolean [ ZenMethod ]
{
	Quit ##class(%DeepSee.TermList).%TermListExists(pTermListName)
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		// + WAL041
		var replacementStreamId = zenPage.replaceExisting;
		if (replacementStreamId != '') {
			var streamName = zenPage.getTermListNameFromStream(replacementStreamId);
			var openTermList = zenPage.termListName		
			if (confirm($$$Text('Overwrite existing Term List: ') + streamName + '?')) {
				zenPage.overwriteTermList(replacementStreamId,openTermList);
				self.document.location = zenLink('_DeepSee.UI.TermListManager.cls' + '?TERMLIST=' + encodeURIComponent(streamName));
			}
			else {	
				self.document.location = zenLink('_DeepSee.UI.TermListManager.cls' + '?TERMLIST=' + encodeURIComponent(openTermList));
			}
		}
		// - WAL041
		if (load) {
			this.updateForm();
			var model = zen('json').getContentObject();
			if (model) {
				this.hideValueColumn(model.hideValue);
			}
		}
		this.adjustSizes();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var editDiv = zen('editGroup').getEnclosingDiv();
		var propsDiv = zen('propertyGroup').getEnclosingDiv();
		var grid = this.getGrid();

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		var th = this.getTitleAreaHeight();

		var fh = winHeight - th - 25;

		propsDiv.style.height = fh + 'px';
		propsDiv.style.width = 320 + 'px';

		grid.setSize(winWidth - 320 - 50,fh-50);
		
		// reveal
		editDiv.style.opacity = 1.0;
		propsDiv.style.opacity = 1.0;
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
		
		Set tParm = ..%GetComponentById("pTermList")
		Set tParm.value = ..termListName

		If ($G(%request.Data("home",1))'="") {
			Set %response.Context("home") = %request.Data("home",1)
		}


		// wrapper object
		If (..termListName'="") {
			Set tID = $$$UPPER(..termListName)
			Set tFieldList = $G(^DeepSee.TermList(tID,"fieldList"))
			
			// add columns for additional fields
			Set tJSON = ..%GetComponentById("json")
			Set tGrid = ..%GetComponentById("termList")
			For n=1:1:$L(tFieldList,"^") {
				Set tField = $P(tFieldList,"^",n)
				If (tField'="") {
					Set tJSON.propertyList = tJSON.propertyList _ "," _ tField

					Set tColDesc = ##class(%ZEN.Auxiliary.gridColumnDescriptor).%New()
					Set tColDesc.caption = tField
					Set tColDesc.value = "=[@"_tField_"]"
					Do %page.%AddComponent(tColDesc)
					Do tGrid.columnDescriptors.Insert(tColDesc)
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Launch the term list finder dialog.
ClientMethod changeTermList() [ Language = javascript ]
{
	if (this.pageModified) {
		if (!confirm($$$Text('There are unsaved changes, do you wish to continue?'))) {
			return;
		}
	}
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=termlists','TermList','status,scrollbars,resizable=yes,width=800,height=600');
}

/// User has selected a new term list.
ClientMethod changeTermListFromUpload() [ Language = javascript ]
{
	var fileName = zen('ctrlUpload').getValue();
	if (fileName==''){ //special case to handle the file name reset on clicking cancel in Chromium-based browsers
		zen('btnImport').setProperty('disabled',true);
		zen('ctrlName').setValue(fileName);
		return;
	}
	zen('btnImport').setProperty('disabled',false);
	// pull off the file name (different for each browser)
	fileName = fileName.toString().replace(/\\/g,'/');
	var t = fileName.split('/');
	fileName = t[t.length-1]; 
	var ext = fileName.substr(fileName.lastIndexOf('.')+1).toLowerCase()
	var allowedTypes=['csv','xls','xlsx']
	
	if (allowedTypes.includes(ext)){
		zen('ctrlName').setValue(fileName);
	}
	else{
		zen('btnImport').setProperty('disabled',true);
		alert('Invalid file type. The file must be of one of the following types: '+allowedTypes.join(', '));
	}
}

/// Launch the subject area finder.
ClientMethod browseSubjectAreas() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=subjectAreas','SubjectArea','status,scrollbars,resizable=yes,width=800,height=600');
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	switch(popupName) {
	case 'switchNamespace':
		var homeurl = zenLink("/csp/sys/%25CSP.Portal.Home.zen");
		var url = zenPage.GetNewURL(value,"_DeepSee.UI.TermListManager.zen");
		if (url == "" || value == "%SYS") url = homeurl;
		try {
			self.document.location = url;
		}
		catch(ex) {
		}
		break;
	case 'SubjectArea':
		// strip off extension
		var name = '';
		var s = value.toString().split('.');
		s.length = s.length-1;
		name = s.join('.');
		zen('ctrlSubject').setValue(name);
		break;

	case 'TermList':
		// strip off extension
		var name = '';
		var s = value.toString().split('.');
		s.length = s.length-1;
		name = s.join('.');

		if (name != this.termlistName) {
			try {
				self.document.location = zenLink('_DeepSee.UI.TermListManager.cls' + '?TERMLIST=' + encodeURIComponent(name));
			}
			catch(ex) {
			}
		}
		break;
	}
}

/// Test if the user has write privilege.
ClientMethod canUserModify() [ Language = javascript ]
{
	return true
}

/// Change in search box value. Can be overridden by subclasses.
ClientMethod searchBoxHandler(searchKey) [ Language = javascript ]
{
	this.searchKey = searchKey;
	this.updateList();
}

/// Update details form.
ClientMethod updateForm() [ Language = javascript ]
{
	// update the form
	var model = zen('json').getContentObject();
	if (model) {
		zen('theForm').setHidden(false);
		zen('ctrlHidden').setValue(model.name);
		zen('ctrlCaption').setValue(model.caption);
		zen('ctrlSubject').setValue(model.subjectArea);
		zen('ctrlPattern').setValue(model.pattern);
		zen('ctrlDescription').setValue(model.description);
		zen('ctrlColumnName').setValue('');
		zen('ctrlHideValue').setValue(model.hideValue);
	}
	else {
		zen('theForm').setHidden(true);
		zen('ctrlHidden').setValue('');
		zen('ctrlCaption').setValue('');
		zen('ctrlSubject').setValue('');
		zen('ctrlPattern').setValue('');
		zen('ctrlDescription').setValue('');
		zen('ctrlColumnName').setValue('');
		zen('ctrlHideValue').setValue(false);
	}
}

/// Change to details form.
ClientMethod formChanged(ctrl) [ Language = javascript ]
{
	// not a change to a control
	if (!ctrl) {
		return;
	}
	
	// copy changes to model
	var model = zen('json').getContentObject();
	if (model) {
		model.caption = zen('ctrlCaption').getValue();
		model.subjectArea = zen('ctrlSubject').getValue();
		model.pattern = zen('ctrlPattern').getValue();
		model.description = zen('ctrlDescription').getValue();
		model.hideValue = zen('ctrlHideValue').getValue();
		if (ctrl.id == 'ctrlHideValue') {
			this.hideValueColumn(model.hideValue);
		}
		this.setModified(true);
	}
}

/// Hide/show the value column.
ClientMethod hideValueColumn(flag) [ Language = javascript ]
{
	var col = zen('gcValue');
	if (col && col.hidden!=flag) {
		col.hidden = flag;
		zenPage.getGrid().render();
	}
}

/// Arrow handler for grid.
ClientMethod arrowHandler(which) [ Language = javascript ]
{
	switch (which) {
	case 'rows':
		this.addRow();
		break;
	case 'columns':
		this.addColumn();
		break;
	}
}

/// Add a new record.
ClientMethod addRow() [ Language = javascript ]
{
	var model = zen('json').getContentObject();
	if (model && model.children) {
		var record = {key:'New Key',value:''};
		if (!model.fieldList || model.fieldList == '') {
			record.value = '';
		}
		else {
			var fields = model.fieldList.toString().split('^');
			for (var f = 0; f < fields.length; f++) {
				if (fields[f]!='') {
					record[fields[f]] = '';
				}
			}
		}
		
		model.children[model.children.length] = record;
		zen('json').setContentObject(model);
		this.setModified(true);
	}
	else {
		alert($$$Text('Please open or create a term list first'));
	}
}

/// Remove a record.
ClientMethod removeRow() [ Language = javascript ]
{
	var currRow = zenPage.getGrid().currRow;

	var model = zen('json').getContentObject();
	if (model && model.children && currRow>0) {
		model.children.splice(currRow-1,1);
		zen('json').setContentObject(model);
		this.setModified(true);
	}
}

/// Click on header in grid.
ClientMethod headerClick(which, index) [ Language = javascript ]
{
	if (which=='column') {
		zen('ctrlColumnName').setValue(zen('json').getLabel(index-1,2));
	}
	return true;
}

/// Add a new column.
ClientMethod addColumn() [ Language = javascript ]
{
	var model = zen('json').getContentObject();
	var name = zen('ctrlColumnName').getValue();
	if (name == '') {
		this._counter = this._counter ? this._counter+1 : 1;
		name = 'NewField'+this._counter;
	}

	if (name.toUpperCase() == 'KEY' || name.toUpperCase() == 'VALUE') {
		alert($$$Text('You cannot add a field called key or value.'));
		return;
	}

	if (model && model.children) {
		var fields = model.fieldList?model.fieldList.toString().split('^'):null;
		if (fields) {
			// test for duplicate
			for (var f = 0; f < fields.length; f++) {
				if (fields[f].toUpperCase() == name.toUpperCase()) {
					alert($$$FormatText($$$Text('There is already a field with the name \'%1\'.'),name));
					return;
				}
			}	
			fields[fields.length] = name;
		}
		else {
			fields = [name];
		}

		model.fieldList = fields.join('^');
		for (var n = 0; n < model.children.length; n++) {
			if (model.children[n]) {
				model.children[n][name] = '';
			}
		}

		// force json to recompute meta data!
		zen('json').setContentObject(model);
		this.setModified(true);

		// add a column to the grid
		var grid = zenPage.getGrid();
		var colDesc = zenPage.createComponent('columnDescriptor');
		grid.columnDescriptors[grid.columnDescriptors.length] = colDesc;
		colDesc.caption = name;
		colDesc.value = '=[@'+name+']';
		grid.render();
	}
}

/// Delete a new column.
ClientMethod deleteColumn() [ Language = javascript ]
{
	var model = zen('json').getContentObject();
	var name = zen('ctrlColumnName').getValue();
	if (name == '') {
		alert($$$Text('Select a column to delete'));
		return;
	}
	if (name == 'key' || name=='value') {
		alert($$$Text('You cannot delete the key or value columns'));
		return;
	}
	
	if (!confirm($$$FormatText($$$Text('Do you wish to delete column \'%1\'?'),name))) {
		return;
	}

	if (model && model.children) {
		var fields = model.fieldList.toString().split('^');
		for (var f = 0; f < fields.length; f++) {
			if (fields[f]==name) {
				fields.splice(f,1);
				break;
			}
		}
		model.fieldList = fields.length>1?fields.join('^'):fields[0];
		for (var n = 0; n < model.children.length; n++) {
			if (model.children[n]) {
				delete model.children[n][name];
			}
		}

		// force json to recompute meta data!
		zen('json').setContentObject(model);
		this.setModified(true);

		// remove column from the grid
		var expr = '=[@'+name+']';
		var grid = zenPage.getGrid();
		for (var n = 0; n < grid.columnDescriptors.length; n++) {
			if (grid.columnDescriptors[n] && grid.columnDescriptors[n].value==expr) {
				grid.columnDescriptors.splice(n,1);
			}
		}
		grid.render();
	}
}

/// Create a new term list.
ClientMethod newTermList() [ Language = javascript ]
{
	if (this.pageModified) {
		if (!confirm($$$Text('There are unsaved changes, do you wish to continue?'))) {
			return;
		}
	}
	// JMD1054 prevent IE undefined!
	var name = prompt($$$Text('What is the name of the new term list?'),'');
	if (name=='') {
		return;
	}
	try {
		self.document.location = zenLink('_DeepSee.UI.TermListManager.cls' + '?TERMLIST=' + encodeURIComponent(name));
	}
	catch(ex) {
	}
}

/// Export the termlist.
ClientMethod exportTermList() [ Language = javascript ]
{
	if (this.pageModified) {
		if (!confirm($$$Text('There are unsaved changes, do you wish to continue?'))) {
			return;
		}
	}
	window.open(zenLink('_DeepSee.UI.TermListExport.cls' + '?TERMLIST=' + encodeURIComponent(this.termListName)));
}

/// Delete the termlist.
ClientMethod deleteTermList() [ Language = javascript ]
{
	if (confirm($$$Text('Do you wish to delete this term list?'))) {
		alert(this.Delete(this.termListName));
		try {
			self.document.location = zenLink('_DeepSee.UI.TermListManager.cls');
		}
		catch(ex) {
		}
	}
}

/// Save the termlist.
ClientMethod saveTermList(rename) [ Language = javascript ]
{
	var json = zen('json');
	var model = zen('json').getContentObject();

	// validate?
	if (rename) {
		var name = prompt($$$Text('What is the name of the copy of this term list?'));
		if (name == '' || name == null) {
			return;
		}
		
		// + WAL041
		var defined = zenPage.termListExists(name);
		if (defined && !confirm($$$Text('Overwrite existing Term List: ') + name + '?')) {
			return;	
		}
		// - WAL041
		
		model.name = name;
	}

	var ok = json.submitContent('save','%ZEN.proxyObject')
	if (!ok) {
		alert(json.getError());
	}
	else {
		this.setModified(false);
		if (rename) {
			// show new item
			try {
				self.document.location = zenLink('_DeepSee.UI.TermListManager.cls' + '?TERMLIST=' + encodeURIComponent(name));
			}
			catch(ex) {
			}
		}
		else {
			alert($$$Text('Term list saved'));
		}
	}
}

/// Get content object for JSON provider.
Method GetTermListContent(ByRef pParameters, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tTermList = $G(pParameters("termlist"))
		If (tTermList="") Quit

		Set tID = $$$UPPER(tTermList)

		// wrapper object
		Set pObject = ##class(%ZEN.proxyObject).%New()
		Set pObject.name = tTermList
		Set pObject.caption = $G(^DeepSee.TermList(tID,"caption"))
		Set pObject.pattern = $G(^DeepSee.TermList(tID,"pattern"))
		Set pObject.description = $G(^DeepSee.TermList(tID,"description"))
		Set pObject.fieldList = $G(^DeepSee.TermList(tID,"fieldList"))
		Set pObject.subjectArea = $G(^DeepSee.TermList(tID,"subjectArea"))
		Set pObject.hideValue = $G(^DeepSee.TermList(tID,"hideValue"))

		Set pObject.children = ##class(%Library.ListOfObjects).%New()

		Set tFieldList = "value^"_pObject.fieldList

		// read values directly from global
		Set k = $O(^DeepSee.TermList(tID,"data",""))
		While (k'="") {
			Set tItem = ##class(%ZEN.proxyObject).%New()
			Do pObject.children.Insert(tItem)
			Set tItem.key = k

			// loop over fields
			For f = 1:1:$L(tFieldList,"^") {
				Set tField = $P(tFieldList,"^",f)
				If (tField'="") {
					Set tValue = $G(^DeepSee.TermList(tID,"data",k,$$$UPPER(tField)))
					Set $property(tItem,tField) = tValue
				}
			}
			Set k = $O(^DeepSee.TermList(tID,"data",k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Object submit handler JSON provider.
/// This is called when the client saves the term list.
Method SubmitTermList(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, ByRef pResponseObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tName = pSubmitObject.name
		Set tCaption = pSubmitObject.caption
		Set tPattern = pSubmitObject.pattern
		Set tDesc = pSubmitObject.description
		Set tFieldList = pSubmitObject.fieldList
		Set tSubjectArea = pSubmitObject.subjectArea
		Set tHideValue = pSubmitObject.hideValue
		
		// JMD1170
		Set:tFieldList=0 tFieldList = ""

		// delete
		Set tSC = ##class(%DeepSee.TermList).%DeleteTermList(tName)
		If $$$ISERR(tSC) Quit

		// recreate
		Set tSC = ##class(%DeepSee.TermList).%CreateTermList(tName,tCaption,tFieldList,tPattern,tDesc,tSubjectArea,tHideValue)
		If $$$ISERR(tSC) Quit

		// Loop over submitted items; add to term list via API
		For j=1:1:pSubmitObject.children.Count() {
			Set tItem = pSubmitObject.children.GetAt(j)
			Do tItem.%CopyToArray(.tArray)
			Set tKey = $G(tArray("key"))
			Kill tArray("key")
			If (tKey'="") {
				Set p = $O(tArray(""))
							
				// + WAL115 -- if for some reason there are no values for this key add a dummy
				If (p="") {
					Set p = "value"
					Set tArray(p) = ""	
				}
				// - WAL115
				
				While (p'="") {
					Set tSC = ##class(%DeepSee.TermList).%SetValue(tName,tKey,$G(tArray(p)),p)
					If $$$ISERR(tSC) Quit
					Set p = $O(tArray(p))
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Delete a term list.
Method Delete(pName As %String) As %String [ ZenMethod ]
{
	Set tMsg = $$$Text("Termlist deleted.")
	Set tSC = ##class(%DeepSee.TermList).%DeleteTermList(pName)
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
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
		Set tName = pSubmit.%GetValue("FileName")
		Set tStream = pSubmit.%GetStream("File")
		Set tExt = $ZCVT($P(tName, ".",*),"L")
		Set tAllowedTypes = $lb("csv", "xls", "xlsx")
		If '$LF(tAllowedTypes, tExt){
			Set tSC=$$$ERROR($$$InvalidFileType, """"_tExt_""". Valid file types are: "_$ListToString(tAllowedTypes, ", "))
			Quit
		}
		
		// + WAL041 -- set tName to empty so that we don't overwrite current termlist
		Set tOrigName = tName
		Set tName = ""
		
		If (($IsObject(tStream))) {
			
			Set tStreamName = ""
			
			Set tSC = ##class(%DeepSee.TermList).%GetTermListNameFromStream(tStream,.tStreamName)
			If $$$ISERR(tSC) Quit
			
			Set tAlreadyExists = ##class(%DeepSee.TermList).%TermListExists(tStreamName,.tSC)
			If $$$ISERR(tSC) Quit
			
			If ('tAlreadyExists) {
				do tStream.Rewind()
				Set tSC = ##class(%DeepSee.TermList).%ImportCSV(tStream,.tName,0)
				If $$$ISERR(tSC) Quit
			}
		}
		If ($G(tAlreadyExists,0)'=0) {
			
			Set tSaveStream = ##class(%Stream.GlobalCharacter).%New()
			Set tSC = tSaveStream.CopyFrom(tStream)
			If $$$ISERR(tSC) Quit

			Set tSC = tSaveStream.%Save()
			If $$$ISERR(tSC) Quit

			Set %response.Context("REPLACE") = tSaveStream.Id
			Set %response.Context("TERMLIST") = tOrigName
		}
		Else {
			Set %response.Context("TERMLIST") = tName
		}
		// - WAL041
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the grid component.
ClientMethod getGrid() [ Language = javascript ]
{
	return zen('termList');
}

/// Key down handler for grid.
ClientMethod gridKeyDown(evt) [ Language = javascript ]
{
	var grid = this.getGrid();
	if (evt.ctrlKey && evt.keyCode == 67) {
		// copy
		this._clipboard = grid.getCellValue(grid.getCurrRow()-1,grid.getCurrColumn()-1);
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
