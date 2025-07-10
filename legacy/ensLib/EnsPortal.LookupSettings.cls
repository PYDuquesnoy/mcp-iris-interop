/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen based Lookup Table UI
Class EnsPortal.LookupSettings Extends (EnsPortal.Template.devPage, EnsPortal.Template.scUtils) [ System = 4 ]
{

/// User needs READ permissions on the %Ens_LookupTables resource to access this page.
Parameter RESOURCE = "%Ens_LookupTables:READ";

/// User needs WRITE permissions on the %Ens_LookupTables resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_LookupTables:WRITE";

/// Displayed name of this page.
Parameter PAGENAME = "Lookup Tables";

/// The position (0-based) of the currently selected row.
Property currentRow As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// The name of the lookup table.
Property lookupTable As %ZEN.Datatype.string(MAXLEN = 220, ZENURL = "LookupTable");

/// Is the user permitted to access the fileSelect popup.
Property canViewFileSystem As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_ViewFileSystem","USE")} ];

Property msgDocReadOnly As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("This lookup table is read only.")} ];

Property tipOpen As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Open an existing lookup table")} ];

Property tipNew As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Create a new lookup table")} ];

Property tipSave As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save the current lookup table")} ];

Property tipSaveAs As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save the current lookup table with a different name")} ];

Property tipDelete As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Delete the currently selected lookup table")} ];

Property tipImport As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Import lookup tables from a file")} ];

Property tipImportLegacy As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Import lookup tables from a file that was exported in legacy format (older version)")} ];

Property tipExport As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Export the currently selected lookup table to a file in XML format")} ];

Property writePERMISSION As %ZEN.Datatype.boolean [ InitialExpression = {$System.Security.GetGlobalPermission($namespace,"Ens.LookupTable") [ "WRITE"} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* @doc="Wrapper for listBox." */
#idHTMLDetails {
	overflow-y: auto;	
}

.zenLabel {
	color: #404040;
	font-size: 10pt;
}

.expandoNode a {
	color: #404040;
	font-size: 10pt;
	font-weight: bold;
}

.tnbrTable {
	border: 1px solid #808080;
	background: #D0D0D0;
	background-image: none;
}

#tableGroup {
	overflow: hidden;
	border-right: 1px solid #F0F0F0;
	border-left: 1px solid #F0F0F0;
	border-bottom: 1px solid #F0F0F0;
}

#descriptionPanel {
	width: 200px;
	background: white;
	font-size: 11pt;
	color: #404040;
	padding: 8px;
	padding-bottom: 0px;
	overflow: auto;
}

#detailGroup {
	width: 300px;
	background: #E0E0D0;
	overflow: auto;
	border-right: 1px solid #F0F0F0;
	border-bottom: 1px solid #F0F0F0;
}

#tableGroup {
	overflow-y: auto;
}

.headerRow {
	background-color: #D0D0F0;
}
.tableHeader {
	display: inline-block;
	color: #404040;
	font-weight: bold;
	text-align: left;
	padding: 2px;
	overflow: hidden;
}
.rowSelected {
	background-color: #f3e799;
}
.rowDeleted {
	background-color: #DDD;
	color: #666;
	font-style: italic;
}
.rowModified {
	font-weight: bold;
}

.tableDiv {
	display: inline-block;
	padding: 2px;
	overflow-x: hidden;
}
.deleteDiv {
	width: 20px;
	min-width: 20px;
}
.keyDiv,
.valueDiv,
.origDiv {
	width: 30%;
}
.origDiv {
	font-weight: bold;
}
</style>
}

/// This XML block defines the contents of the main pane.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="pane" hidden="true">
<jsonProvider id="json" OnGetTargetObject="LoadLookupTable" OnSubmitContent="SaveLookupTable" targetClass="%ZEN.proxyObject" />
<hgroup cellVAlign="top">
<html id="descriptionPanel" OnDrawContent="DrawDescription" />
<vgroup id="tableGroup">
<!-- An empty, but padded html component that has the correct id, keeps this space open for adjustSizes() -->
<html id="notASpacer" containerStyle="padding:2px;" />
<vgroup id="contentsGroup" hidden="true" width="100%">
<html id="idHTMLDetails" containerStyle="padding-top:2px;" OnDrawContent="DrawDetails" seed=""/>
</vgroup>
</vgroup>
<vgroup id="detailGroup">
<form id="bpForm" cellStyle="padding:3px;" hidden="true" onchange="zenPage.toggleFormButtons(true);" >
<text label="Key" name="Key" id="txtKey" size="28" hint="Enter a key." onkeydown="zenPage.textControlKeyDown();" onkeyup="zenPage.textControlKeyUp();" />
<text label="Value" name="Value" id="txtValue" size="28" hint="Enter a value." onkeydown="zenPage.textControlKeyDown();" onkeyup="zenPage.textControlKeyUp();" />
<hgroup>
<button controlClass="commandButtonDisabled" id="formApply" caption="Apply" onclick="zenPage.applyChanges();"
		title="Apply the changes to the lookup table" disabled="true" />
<spacer width="10px" />
<button controlClass="commandButtonDisabled" id="formDiscard" caption="Discard" onclick="if (zenPage.canUserModify()) zenPage.clearValues(); zenPage.selectRow(-1);" title="Discard changes to the current key and value" disabled="true" />
</hgroup>
</form>
</vgroup>
</hgroup>
</pane>
}

/// Draw the contents of the description panel.
Method DrawDescription(pSeed As %String) As %Status
{
	Write $$$Text("Each lookup table defines a set of key-value pairs that can be retrieved from rules or data transformations using the Lookup function.")
	Quit $$$OK
}

/// Initialise the table rendering of the page.
ClientMethod loadDetails(loadFromServer) [ Language = javascript ]
{
	if (loadFromServer) {
		this.loadDocument();
	}
	this.drawTableDetails();
	// no values entered
	zenPage.clearValues();
	var addKeyClass = 'reIcon' + (this.readOnly || !this.canEdit ? 'Disabled' : '');
	var addKeyIcon = self.document.getElementById('iconNewKey');
	if (addKeyIcon) addKeyIcon.className = addKeyClass;

	// show/hide details area and key/value working area
	var box = zen("contentsGroup");
	var form = zen("bpForm");
	var hideForm = (this.lookupTable.length == 0);
	box.setHidden(hideForm);
	form.setHidden(hideForm);
}

/// Helper method to create a Zen proxyObject instance to represent the specified lookup table.
ClassMethod GetLookupTableProxy(pLookupTable As %String = "", Output pProxy As %ZEN.proxyObject) As %Status
{
	Set tStatus = $$$OK
	Set tLocked = 0
	Set pProxy = ""
	Try {
		If pLookupTable = "" {
			Quit
		}
		Set tReadOnly = 0
		Try {
			Lock +^Ens.LookupTable(pLookupTable):2
			If '$Test {
				Set tReadOnly = 1
			} Else {
				Set tLocked = 1
			}
		} Catch ex {
			If ex.Name'="<PROTECT>" Throw ex
		}
		Set pProxy = ##class(%ZEN.proxyObject).%New()
		Set pProxy.Timestamp = ##class(Ens.Util.LookupTable).getTimestamp(pLookupTable)
		Set pProxy.ReadOnly = tReadOnly
		Set tValues = ##class(%Library.ListOfObjects).%New()

		Set tKey = ""
		For {
			Set tKey = $order(^Ens.LookupTable(pLookupTable,tKey),1,tValue)
			Quit:(tKey = "")
			Set tProxy = ##class(%ZEN.proxyObject).%New()
			Set tProxy.key = tKey
			Set tProxy.value = tValue
			Set tProxy."_originalValue" = tValue
			Do tValues.Insert(tProxy)
		}
		Set pProxy.values = tValues
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	If tLocked Lock -^Ens.LookupTable(pLookupTable)
	Quit tStatus
}

/// Main method to get a JSON-ready representation of the current lookup table.
Method LoadLookupTable(ByRef pParms, Output pObject As %ZEN.proxyObject) As %Status
{
	Set tStatus = $$$OK
	Set pObject = ""
	Try {
		Set tStatus = ..GetLookupTableProxy(..lookupTable,.tObject)
		If $$$ISERR(tStatus) Quit
		Set pObject = tObject
		If $IsObject(pObject) {
			Set pObject.isNew = ..isNew
			If ..IsSourceControlReadOnly(..GetInternalName()) {
				Set pObject.ReadOnly = 2
			}
		}
	}
	Catch {
		Set tStatus = $$$SystemError
	}
	Quit tStatus
}

/// Save the supplied lookup table.
Method SaveLookupTable(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %ZEN.proxyObject, Output pResponseObject As %RegisteredObject) As %Status
{
	Set tStatus = $$$OK
	Set tLocked = 0
	Set tTranOpen = 0
	Try {
		If (pCommand = "save") || (pCommand = "forcesave") {
			If ..lookupTable = "" {
				Set tStatus = $$$ERROR($$$EnsErrGeneral,"LookupTable cannot be saved without a name.")
				Quit
			}
			Lock +^Ens.LookupTable(..lookupTable):3
			If '$Test {
				Set tStatus = $$$ERROR($$$LockFailedToAcquireExclusive,$name(^Ens.LookupTable(..lookupTable)))
				Quit
			}
			Set tLocked = 1
			If (pCommand = "save") && ##class(Ens.Util.LookupTable).%ExistsTable(..lookupTable) {
				Set tSavedTimestamp = ##class(Ens.Util.LookupTable).getTimestamp(..lookupTable)
				#; Handle non-upgraded cases where timestamp will be ""
				If (tSavedTimestamp '= "") && (tSavedTimestamp '= pSubmitObject.Timestamp) {
					Set pProvider.error = "timestamp"
					Quit
				}
			}
			If ..IsSourceControlReadOnly(..GetInternalName()) {
				Set pProvider.error = $$$Text("Your source control framework has marked this document as read only, so you will not be able to modify this document.")
				Quit
			}
			
			#; Wrap update in a transaction to allow us to revert all changes
			TSTART
			Set tTranOpen = 1
			Set tValues = pSubmitObject.values
			If $IsObject(tValues) && tValues.%IsA("%Library.ListOfObjects") {
				If tValues.Count()=0 {
					Do ##class(Ens.Util.LookupTable).%ClearTable(..lookupTable)
					Do ##class(Ens.Util.LookupTable).updateTimestamp(..lookupTable)
				} Else {
					Set tPos = "", tStatus = $$$OK
					Kill ^||EnsPortalLookup("Update")
					For {
						Set tPair = tValues.GetNext(.tPos)
						Quit:(tPos = "")
						If '$IsObject(tPair) Continue
						Set tStatus = ##class(Ens.Util.LookupTable).%UpdateValue(..lookupTable,tPair.key,tPair.value)
						If $$$ISERR(tStatus) Quit
						Set ^||EnsPortalLookup("Update",tPair.key)=""
					}
					If $$$ISOK(tStatus) {
						Try {
							#; Loop through all in the look up table and remove any that were not 'updated'.
							Set tKey = ""
							For {
								Set tKey = $order(^Ens.LookupTable(..lookupTable,tKey))
								Quit:(tKey = "")
								If '$Data(^||EnsPortalLookup("Update",tKey)) {
									Set tStatus = ##class(Ens.Util.LookupTable).%RemoveValue(..lookupTable,tKey)
									If $$$ISERR(tStatus) Quit 
								}
							}
						} Catch ex {
							Set tStatus = ex.AsStatus()
						}
					}
					Kill ^||EnsPortalLookup("Update")
					If $$$ISERR(tStatus) Quit 
				}
			}
			Else {
				Set tStatus = $$$ERROR($$$EnsErrGeneral,"Invalid JSON structure")
				Quit
			}
			TCOMMIT
			Set tTranOpen = 0
			Set tStatus = ..GetLookupTableProxy(..lookupTable,.pResponseObject)
			If $$$ISERR(tStatus) Quit
		}
		Else {
			Set tStatus = $$$ERROR($$$EnsErrGeneral,"Invalid command")
			Quit
		}
	}
	Catch {
		If tTranOpen {
			#; roll back transaction so the error is committed correctly
			TROLLBACK
			Set tTranOpen = 0
		}
		Set tStatus = $$$SystemError
	}
	If tTranOpen TROLLBACK
	If tLocked Lock -^Ens.LookupTable(..lookupTable)
	Quit tStatus
}

/// strict alphabetical sort used to sort rows in UI.
ClientMethod alphaSort(a, b) [ Language = javascript ]
{
	return a.key.toString().localeCompare(b.key.toString());
}

/// Modified sort, which sorts new, modified, deleted, and then unchanged rows, with alphabetical sorting within each group.
/// A weight is given to each state so it is easy to produce a sort order. The weights are as follows:
/// <ul><li>0 - new entry</li>
/// <li>1 - modified entry</li>
/// <li>2 - deleted entry</li>
/// <li>3 - unchanged entry</li></ul>
ClientMethod modSort(a, b) [ Language = javascript ]
{
	var obj = { "a": a, "b": b };
	var mods = { "a": 3, "b": 3 };
	for (var prop in obj) {
		// check _deleted first as a key can be new, modified AND deleted, but the deletion must have happened last
		if (obj[prop]._deleted) {
			mods[prop] = 2;
		}
		else if (obj[prop]._isNew) {
			mods[prop] = 0;
		}
		else if (obj[prop].value != obj[prop]._originalValue) {
			mods[prop] = 1;
		}
	}
	if (mods.a < mods.b) return -1;
	if (mods.a > mods.b) return 1;
	return zenPage.alphaSort(a,b);
}

/// Render the contents of the detail table.
ClientMethod drawTableDetails() [ Language = javascript ]
{
	this._rowIndex = [];
	this._keyPosIndex = {};
	this._keyIndex = {};
	var values = this.getTableValues();
	var content = '';
	if (values) {
		var html = [];
		html.push('<div id="detailTable" class="tpTable" style="font-size: 0.8em; width: 98%;" cellspacing="2" cellpadding="0" border="0" width="98%">');
		html.push('<div class="headerRow">');
		html.push('<div class="tableHeader deleteDiv">&nbsp;</div>');
		html.push('<div class="tableHeader keyDiv">' + $$$Text('Key') + '</div>');
		html.push('<div class="tableHeader valueDiv">' + $$$Text('Value') + '</div>');
		html.push('<div class="tableHeader origDiv">' + $$$Text('Original Value') + '</div>');
		html.push('</div>');

		if (values.length == 0) {
			html.push('<div class="caption">' + $$$Text('No key-value pairs found') + '</div>');
		}
		else {
			var keySequence = [];
			for (var i = 0; i < values.length; i++) {
				var data = values[i];
				if (data) {
					data._index = i;
					keySequence.push(data);
				}
			}
			var sortSelect = self.document.getElementById('sortSelect');
			var sortFunction = sortSelect && sortSelect.value ? sortSelect.value : 'alphaSort';
			keySequence.sort(zenPage[sortFunction]);
			var index;
			for (var pos = 0; pos < keySequence.length; pos++) {
				this.renderRow(html,pos,keySequence[pos]._index,values);
			}
		}
		html.push('</div>');
		content = html.join('');
	}
	var detailTable = self.document.getElementById('idHTMLDetails');
	if (detailTable) detailTable.innerHTML = content;
}

/// Add the HTML for a row in position <var>pos</var> using the data from position <var>index</index>
/// in the list of values.
ClientMethod renderRow(html, pos, index, values) [ Language = javascript ]
{
	if (!values) {var values = this.getTableValues();}
	if (values && values[index]) {
		var data = values[index];
		this._rowIndex[pos] = data;
		this._keyPosIndex[data.key] = pos;
		this._keyIndex[data.key] = index;
		var renderData = {
			"rowClass": "",
			"title": $$$Text('Delete this key'),
			"onclick": "zenPage.removeRow(" + pos + ");",
			"image": "deepsee/close_a_16.png"
		};
		if (data._deleted) {
			renderData.rowClass = 'rowDeleted';
			renderData.title = $$$Text('Undo delete');
			renderData.onclick = 'zenPage.removeRow(' + pos + ',true);';
			renderData.image = 'deepsee/add_16.png';
		}
		if (data._isNew || (data.value != data._originalValue)) {
			renderData.rowClass += ' rowModified';
		}
		html.push('<div id="row_' + pos + '" class="' + renderData.rowClass + '">');
		html.push('<div class="tableDiv deleteDiv">');
		html.push('<a href="#" title="' + renderData.title + '" onclick="' + renderData.onclick + ' return false;"><img src="' + renderData.image + '" style="vertical-align: text-bottom;" /></a>');
		html.push('</div>');
		html.push('<div id="key_' + pos + '" class="tableDiv keyDiv" onclick="zenPage.selectRow(\'' + pos + '\');">' + zenEscapeHTML(data.key) + '</div>');
		html.push('<div id="val_' + pos + '" class="tableDiv valueDiv" onclick="zenPage.selectRow(\'' + pos + '\');">' + zenEscapeHTML(data.value) + '</div>');
		var origVal = '&nbsp;';
		var origClass = '';
		if (data._isNew) {
			origVal = '*';
			origClass = ' origDiv';
		}
		else if ((data._originalValue != null) && (data._originalValue != data.value)) {
			origVal = data._originalValue;
			origClass = ' origDiv';
		}
		html.push('<div id="orig_' + pos + '" class="tableDiv' + origClass +'" onclick="zenPage.selectRow(\'' + pos + '\');">' + origVal + '</div>');
		html.push('</div>');
	}
}

/// Reset the form programmatically.
ClientMethod clearValues() [ Language = javascript ]
{
	this.toggleFormButtons(false);
	this.currentRow = -1;
	this._currentData = null;
	zen("txtValue").setValue("");
	zen("txtKey").setValue("");
	zen("txtKey").focus();
}

/// Helper method to ensure that the two buttons in the right hand side of the page
/// are toggled together.
ClientMethod toggleFormButtons(enable) [ Language = javascript ]
{
	this.toggleButton('formApply',enable);
	this.toggleButton('formDiscard',enable);
}

/// Toggle whether the button with Id <var>zenId</var> is enabled or disabled.
ClientMethod toggleButton(zenId, enable) [ Language = javascript ]
{
	var button = zen(zenId);
	if (button) {
		enable = !!enable;
		button.setProperty('disabled',!enable);
		var controlClass = 'commandButton' + (enable ? '' : 'Disabled');
		button.setProperty('controlClass',controlClass);
	}
}

/// Prompt the user for the name of a new table to edit.
ClientMethod newTable() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	if (this.pageModified) {
		var doNew = confirm($$$Text('The current lookup table has been modified. Do you wish to discard these changes and create a new lookup table?'));
		if (!doNew) return;
	}

	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.LookupSelect.zen'),this.addPopupSuffix('NewLookup'),'resizable,width=350,height=250');
}

/// Launch a dialog to choose a different table to open.
ClientMethod openTable() [ Language = javascript ]
{
	if (this.pageModified) {
		var doOpen = confirm($$$Text('The current lookup table has been modified. Do you wish to discard these changes and open a different lookup table?'));
		if (!doOpen) return;
	}
	var parms = { MODE: "lookups" };
	zenLaunchPopupWindow(zenLink('_ZEN.Dialog.finderDialog.zen'),this.addPopupSuffix('LookupOpen'),'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// Save the current lookup table.
ClientMethod saveTable() [ Language = javascript ]
{
	if (!this.canUserModify()) return false;
	if (this.lookupTable != '') {
		var values = this.getTableValues();
		if (values && (values.length > 0)) {
			for (var i = values.length - 1; i >= 0; i--) {
				var data = values[i];
				if (data && data._deleted) values.splice(i,1);
			}
		}
		if (zenPage.getIsReadOnly()) {
			// if document turned out to be readOnly, gray out buttons to indicate this
			zenPage.grayOutButtons();
		}
		return this.saveDocument();
	}
	return false;
}

/// Launch popup window to begin 'save as' process
ClientMethod saveTableAs() [ Language = javascript ]
{
	if (!this.canUserModify(true)) return false;
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.LookupSaveAs.zen'),this.addPopupSuffix('LookupSaveAs'),'status,resizable,width=300,height=250');
}

ClassMethod NameCheck(newName) As %String [ ZenMethod ]
{
	Do ##class(Ens.Util.LookupTable).%ExistsTable(newName,1,,.matchName)
	Quit matchName
}

/// Check to see if the new name for this table is already in use before saving.
/// If the new name is already in use, confirm that the user wishes to overwrite the old table of that name.
ClientMethod checkName(newName) [ Language = javascript ]
{
	
	var duplicateName = zenPage.NameCheck(newName);
	if (duplicateName !="") 
	{
		if (zenPage.IsNameReadOnly(newName)) {
			alert($$$FormatText($$$Text('Your source control framework has marked the lookup table %1 as read only, so you will not be able to modify this document.'),newName));
			if (newName == this.lookupTable) {
				// If not a rename, gray out buttons to indicate current document is readOnly
				zenPage.grayOutButtons();
			}
			return; 
		}
		if (!confirm($$$FormatText($$$Text("Lookup table name '%1' is already in use!  Are you sure you want to overwrite this table?"),duplicateName))) {
			return;
		}
		/* Since overwriting do not follow up with remove from source control if source control enabled */
		zenPage.RemoveTable(duplicateName);
	}
	zenPage.renameSave(newName);
	var link = zenLink('EnsPortal.LookupSettings.zen');
	link += (link.indexOf('?') > -1 ? '&' : '?') + 'LookupTable=' + encodeURIComponent(newName+".lut");
	this.setModified(false);
	this.gotoPage(link);
}

ClassMethod IsNameReadOnly(pName As %String) As %Boolean [ ZenMethod ]
{
	Set tName = pName_".LUT"
	Quit ##class(%CSP.Portal.SourceControl.Base).IsSourceControlReadOnly(tName)
}

ClientMethod renameSave(newName) [ Language = javascript ]
{
	if (this.readOnly && (newName != this.lookupTable)) {
		try {
			this.lookupTable = newName;
			this.readOnly = false;
			this.saveTable();
			this.readOnly = true;
		} catch (ex) {
			this.readOnly = true;
		}
	} else {
		this.lookupTable = newName;
		this.saveTable();
	}
}

/// Clear the undo stack.
ClientMethod clearUndoBuffer() [ Language = javascript ]
{
	this._undoBuffer = [];
	this.setModified(false);
	this.toggleUndoIcon(false);
}

/// Helper method to indicate whether there is any data on the undo stack.
ClientMethod canUndo() [ Language = javascript ]
{
	return this._undoBuffer && (this._undoBuffer.length > 0) && (this.canEdit && !this.readOnly);
}

/// Add a copy of the current table state to the undo stack.
ClientMethod addUndoAction(setModified) [ Language = javascript ]
{
	if (!this._undoBuffer) this._undoBuffer = [];
	var tableObject = this.getTableObject();
	if (tableObject) {
		var clone = this.cloneObject(tableObject);
		this._undoBuffer.push(clone);
		if (setModified) this.setModified(true);
		this.toggleUndoIcon(true);
	}
}

/// If the current action can be undone, do so.
ClientMethod undo() [ Language = javascript ]
{
	if (this.canUndo()) {
		this._inUndo = true;
		var tableObject = this._undoBuffer.pop();
		var json = this.getClientModel();
		json.setContentObject(tableObject);
		this.loadDetails();
		this.toggleUndoIcon();
		if (this._undoBuffer.length == 0) {
			this.setModified(false);
		} else {
			this.setModified(true);
		}
		this._inUndo = false;
	}
}

/// Ensure we redraw the diagram if a reload was requested
ClientMethod onDocumentReload(reason) [ Language = javascript ]
{
	if (this._inUndo || this._inReload) return; // avoid recursion
	this._inReload = true;
	this.updateDocumentState(true);
	if (reason == "dataChange") {
		this.loadDetails();
		this.toggleUndoIcon();
		this.setModified(false);
	}
	this._inReload = false;
}

/// Toggle whether the undo icon should be shown or not.
ClientMethod toggleUndoIcon(show) [ Language = javascript ]
{
	if (typeof show != 'boolean') show = this.canUndo();
	var undo = document.getElementById('iconUndo');
	if (undo) undo.className = 'reIcon' + (show ? '' : 'Disabled');
}

/// Create a clone of the given object. Used in the undo logic.
ClientMethod cloneObject(obj, clone) [ Language = javascript ]
{
	var clone = clone ? clone : {};
	for (var i in obj) {
		if ((i == '_parent')||(i == '_index')) {
			// skip back pointers
		}
		else if (null == obj[i]) {
			clone[i] = null;
		}
		else if (typeof obj[i] === 'object') {
			clone[i] = (obj[i].constructor === Array) ? []: {};
			this.cloneObject(obj[i],clone[i]);
		}
		else {
			clone[i] = obj[i];
		}
	}
	return clone;
}

/// Server method to delete table and all its settings
/// accounting for Source Control is applicable.
Method RemoveTable(tableName As %String) As %String [ Internal, ZenMethod ]
{
	#dim tJSONMessage = ""

	#; Check since passed from client page.
	If '##class(Ens.Util.LookupTable).%ExistsTable(tableName) {

		Set tJSONMessage = ..BadRequestMessage()

	} Else {

		Do ..DeleteDoc(tableName,".LUT", .tJSONMessage)

	}

	Return tJSONMessage
}

/// Apply changes from the form back to the JSON model.
ClientMethod applyChanges() [ Language = javascript ]
{
	if (!this.canUserModify()) { return false; }
	var newKey = zen('txtKey').getValue();
	var newValue = zen('txtValue').getValue();
	if (newKey.toString() == '') {
		if (newValue != '') alert($$$Text('You must supply a key.'));
		zen('txtKey').focus();
		return;
	}
	this.addUndoAction(true);
	var values = this.getTableValues();
	// check if we already have this key, if so, update it
	if (typeof this._keyIndex[newKey] == 'number') {
		var oldData = values[this._keyIndex[newKey]];
		if (oldData._deleted) {
			alert($$$FormatText($$$Text("You may not modify key '%1' as it has been deleted. You must add the key back to the table if you wish to modify its value."),newKey));
			zen('txtKey').focus();
			return;
		}
		this._currentData = oldData;
	}
	if (!this._currentData) {
		// adding a new row
		var data = { "key": newKey, "value": newValue, "_isNew": true };
		values.push(data);
	}
	else {
		// key has changed; equivalent to new
		if (this._currentData.key != newKey) {
			this._currentData = null;
			var newData = { "key": newKey, "value": newValue, "_isNew": true };
			values.push(newData);
		}
		else {
			this._currentData.value = newValue;
		}
	}
	this.loadDetails();
	var index = this._keyPosIndex[newKey];
	if (index > -1) this.selectRow(index);
}

/// User selected a row in the lookup table.
ClientMethod selectRow(row) [ Language = javascript ]
{
	if (!this.canUserModify()) { return false; }

	// unselect the old row
	if (zenPage.currentRow > -1) {
		var oldRow = self.document.getElementById("row_" + zenPage.currentRow);
		if (oldRow) oldRow.className = oldRow.className.toString().replace(/ rowSelected/g,'');
	}
	if (zenPage.currentRow == row) { // just clear fields
		zenPage.clearValues();
	}
	else { // select the new row
		var rowObj = self.document.getElementById("row_" + row);
		if (rowObj) rowObj.className = rowObj.className.toString() + ' rowSelected';
		zenPage.currentRow = row;
		zenPage._currentData = this._rowIndex[row];
		if (zenPage._currentData && zenPage._currentData._deleted) {
			zenPage.clearValues();
			return;
		}
		
		// Get the values we need
		var key = '';
		var value = '';
		var origValue = '';
		if (zenPage._currentData) {
			 key = zenPage._currentData.key;
			 value = zenPage._currentData.value;
			 origValue = zenPage._currentData._originalValue;
		}
	
		// Set the values in the form
		zen("txtKey").setValue(key);
		zen("txtValue").setValue(value);
		zen("txtValue").originalValue = origValue;
		this.toggleFormButtons(true);
	}
}

/// User clicked the Delete button for a row.
/// <var>addBack</var> should be used to indicate that a previously deleted key should be
/// added back to the table.
ClientMethod removeRow(row, addBack) [ Language = javascript ]
{
	if (!this.canUserModify()) { return false; }

	var rowData = null;
	if (typeof row == 'number') {
		rowData = this._rowIndex[row];
		addBack = !!addBack;
	}
	else if (zenPage.currentRow == -1) {
		if (this.lookupTable.toString().length > 0) {
			alert($$$Text("Choose a key to remove from the table"));
		}
		else {
			alert($$$Text("Choose a table to work on and a key to remove from that table"));
		}
	}
	else {
		rowData = this._rowIndex[this.currentRow];
	}
	if (rowData && (addBack || !rowData._deleted)) {
		this.addUndoAction(true);
		if (addBack) {
			delete rowData._deleted;
		}
		else {
			rowData._deleted = true;
		}
	}
	this.loadDetails();
}

/// User clicked the Delete button for a table.
ClientMethod deleteTable() [ Language = javascript ]
{
	if (!this.canUserModify()) { return false; }
	if (this.lookupTable.toString() == '') return;
	
	if (zenPage.IsDocReadOnly()) {
		alert($$$Text($$$Text("Your source control framework has marked this document as read only, so you will not be able to delete this document.")));
		// Gray out buttons to indicate document is readOnly
		zenPage.grayOutButtons();
		return false; 
	}

	var ok = confirm($$$FormatText($$$Text("Are you sure you want to delete the table %1?"),this.lookupTable));
	if (!ok) return;

	msg = $$$FormatText($$$Text("This is a full table delete and cannot be reversed. Are you sure you want to delete the table %1?"),this.lookupTable);
	var c1 = $$$Text("Delete");
	var t1 = $$$Text("Delete the table");
	var c3 = $$$Text("Abort");
	var t3 = $$$Text("Abort and Do Not Delete the table");
	var parms = {
		MESSAGE:	msg,
		CAPTION1:	c1,
		TITLE1:		t1,
		CAPTION3:	c3,
		TITLE3:		t3,
		ACTIONBUTTONS:	1
	};
	zenPage.launchPopupWindow(zenLink('EnsPortal.Dialog.Choice.zen'),this.addPopupSuffix('DeleteTable'),'resizable=yes,width=380,height=190',parms);
}

/// Add intermediary Are You Really Sure popup
ClientMethod deleteTableAfterConfirmation() [ Language = javascript ]
{
	/* in case called directly through debugger go through checks again */
	if (!this.canUserModify()) { return false; }
	if (this.lookupTable.toString() == '') return;
	if (zenPage.IsDocReadOnly()) {
		zenPage.grayOutButtons();
		return false; 
	}
	var ret = zenPage.RemoveTable(this.lookupTable);
	if (!this.processDeleteReturn(ret,this.lookupTable)) return false;
	this.gotoPage('EnsPortal.LookupSettings.zen');
}

/// Launch a dialog so the user can choose a file to export the current lookup table to.
ClientMethod exportTable() [ Language = javascript ]
{
	if (!this.canViewFileSystem) {
		alert(this.msgNotPermitted);
		return false;
	}
	if (this.lookupTable.toString().length == 0) {
		alert($$$Text("Select a lookup table to export"));
		return;
	}

	if (this.pageModified) {
		alert($$$Text("There are unsaved changes, please save before exporting"));
		return;
	}
	
	var values = this.getTableValues();
	if (!values || values.length == 0) {
		alert($$$Text("This lookup table is empty, please provide at least one key-value pair"));
		return;
	}

	var lookup = this.lookupTable.toString().split(".").join("_");
 	parms = {
		Dir:zenPage.GetDefaultDir(),
		File:lookup + '.xml'
	}
	zenLaunchPopupWindow(
  	zenLink('%ZEN.Dialog.fileSelect.zen'),
 	this.addPopupSuffix('LookupExportFileSelection'),
  	'status,scrollbars,resizable,width=660,height=700',
  	parms);
}

/// Launch a dialog so the user can choose a file to import a lookup table from.
ClientMethod importTable() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	if (!this.canViewFileSystem) {
		alert(this.msgNotPermitted);
		return false;
	}
	if (this.pageModified) {
		alert($$$Text("There are unsaved changes, please save before importing"));
		return;
	}
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.Import.zen?TYPE=Lookup'),this.addPopupSuffix('ImportLookup'),'status,scrollbars,resizable,width=800,height=800');
}

/// Launch a dialog so the user can choose a file to import a lookup table from, in legacy format (exported from an older version).
ClientMethod importTableLegacy() [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	if (!this.canViewFileSystem) {
		alert(this.msgNotPermitted);
		return false;
	}	
	if (this.pageModified) {
		alert($$$Text("There are unsaved changes, please save before importing"));
		return;
	}
	parms = {
		Dir:zenPage.GetDefaultDir()
	}
	zenLaunchPopupWindow(
  	zenLink('%ZEN.Dialog.fileSelect.zen'),
  	this.addPopupSuffix('LookupImportLegacyFileSelection'),
  	'status,scrollbars,resizable,width=660,height=700',
  	parms);
}

/// Handle various dialogs.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action != "ok") {
			return false;
		}
		popupName = this.removePopupSuffix(popupName);
		switch(popupName) {
			case 'NewLookup':
				if (value.substring(value.length-4).toUpperCase() != '.LUT') value += '.lut';
				// note that we fall through to open the page for both NewLookup and LookupOpen
			case 'LookupOpen':
				var link = zenLink('EnsPortal.LookupSettings.zen');
				link += (link.indexOf('?') > -1 ? '&' : '?') + 'LookupTable=' + encodeURIComponent(value);
				this.setModified(false);
				this.gotoPage(link);
				break;
			case 'LookupExportFileSelection':
				setTimeout(function() {
					zenPage.doExport(value);
				}, 50);
				break;
			case 'LookupImportFileSelection': 
				setTimeout(function() {
					zenPage.doImport(value);
				}, 50);
				break;
			case 'LookupImportLegacyFileSelection': 
				setTimeout(function() {
					zenPage.doImportLegacy(value);
				}, 50);
				break;
			case 'switchNamespace':
				zenPage.changeURLNamespace(value);
				break;
			case 'LookupSaveAs':
				if (value.substring(value.length-4).toUpperCase() == '.LUT') value = value.substring(0,value.length-4);
				zenPage.checkName(value);
				break;
			case 'DeleteTable':
				setTimeout(function() {
					zenPage.deleteTableAfterConfirmation();
				}, 50);
				break;
		}
	} 
	catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Actually perform the export to the specified file.
ClientMethod doExport(filename) [ Language = javascript ]
{
	var fileProblem = zenPage.CheckFilename(filename);
	if (fileProblem == 1) {
		var ok = confirm($$$FormatText($$$Text("Are you sure you want to overwrite the existing file %1?"),filename));
		if (!ok) return;
	}
	else if (fileProblem == 2) {
		fileProblem = zenPage.CreateDirectory(filename);
		if (fileProblem == 2) {
			alert($$$FormatText($$$Text("The directory specified for file %1 does not exist."),filename));
			return;
		}
	}
	var err = zenPage.Export(filename,this.lookupTable);
	if (err === '') {
		alert($$$Text("The lookup table was exported successfully"));
		zenPage.SetDefaultDir(filename);
	}
	else {
		alert($$$Text("Unable to export lookup table") + '\n' + err);
	}
}

/// Import
ClientMethod doImport(filename) [ Language = javascript ]
{
	var parms = {
			FILETYPE: '*.xml'
	};
	
	//open dialog for import criteria
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.Import.zen','Import','status,scrollbars,resizable=yes,width=610,height=700',parms);

	return;

	var err = zenPage.Import(filename);	
	if (err === '')  {
		alert($$$Text("Imported successfully"));
		zenPage.SetDefaultDir(filename);
	}
	else {
		alert($$$Text("Unable to import lookup table(s) from the file") + '\n' + err);
	}
}

/// Import legacy
ClientMethod doImportLegacy(filename) [ Language = javascript ]
{
	var err = zenPage.ImportLegacy(filename);	
	if (err === '')  {
		alert($$$Text("Imported successfully"));
		zenPage.SetDefaultDir(filename);
		// reload only current table
	}
	else {
		alert($$$Text("Unable to import file as lookup table not in legacy format") + '\n' + err);
	}
}

ClassMethod GetDefaultDir() As %String [ ZenMethod ]
{
	Quit $G(^EnsPortal.Settings($USERNAME, "ImportExportDir"))
}

ClassMethod SetDefaultDir(pPathname As %String) [ ZenMethod ]
{
	Set ^EnsPortal.Settings($USERNAME, "ImportExportDir") = ##class(%File).GetDirectory(pPathname, 1)
}

/// Check whether the specified file already exists or is in a non-existent directory.
ClassMethod CheckFilename(filename As %String) As %String [ ZenMethod ]
{
	If ##class(%File).Exists(filename) {
		Quit "1"
	}	
	Else {
		Set tDir = ##class(%File).GetDirectory(filename)
		If '##class(%File).DirectoryExists(tDir) {
			Quit "2"
		}
	}
	Quit "0"
}

ClassMethod CreateDirectory(filename As %String) As %String [ ZenMethod ]
{
	Set tDir = ##class(%File).GetDirectory(filename)
	If '##class(%File).CreateDirectory(tDir) {
		Quit "2"
	}
	Quit "0"
}

/// Export a lookup table in <var>Tablename</var> to file <var>Filename</var>.
ClassMethod Export(Filename As %String, Tablename As %String) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tLocked = 0
	Try {
		Lock +^Ens.LookupTable(Tablename)#"S":2
		If '$Test {
			Set tSC = $$$ERROR($$$LockFailedToAcquireRead,$Name(^Ens.LookupTable(Tablename)))
			Quit
		}
		Set tLocked = 1
		Set tSC = $system.OBJ.Export(Tablename_".LUT", Filename, "-d")
	} Catch ex {
		If ex.Name="<PROTECT>" {
			Set tSC = $$$ERROR($$$LockFailedToAcquireRead,$Name(^Ens.LookupTable(Tablename)))
		} Else {
			Set tSC = ex.AsStatus()
		}
	}
	If tLocked Lock -^Ens.LookupTable(Tablename)#"S"
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

/// Import lookup tables from file <var>Filename</var>.
/// Other types of documents, if any, are skipped.
ClassMethod Import(Filename As %String) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tRS = ##class(%ResultSet).%New("%RoutineMgr:ImportItemList")
	Set tSC = tRS.Execute(Filename)
	If $$$ISERR(tSC) Quit $System.Status.GetErrorText(tSC)
	Set tSC = $$$OK
	Kill Select
	For  {
		Quit:'tRS.Next(.tSC)
		Set Name = tRS.Get("Name")
		If $E(Name,*-3,*)=".LUT" {
			Lock +^Ens.LookupTable(Name):2
			If '$T Set tSC = $$$ERROR($$$LockFailedToAcquireRead,$Name(^Ens.LookupTable(Name))) Quit
			Set Select($E(Name,1,*-4)) = ""
		}
	}
	If $$$ISERR(tSC) Quit $System.Status.GetErrorText(tSC)
	If '$D(Select) Quit $$$ERROR($$$GeneralError,$$$Text("This file does not contain any lookup tables"))
	Set tSC = $system.OBJ.Load(Filename,"-d", .Err, .Loaded, 0, .Select)
	Set Name = ""
	For  {
		Set Name = $O(Select(Name))
		Quit:Name=""
		Lock -^Ens.LookupTable(Name)
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

/// Import lookup tables from file <var>Filename</var>, using legacy XML format, compatible with older versions.
ClassMethod ImportLegacy(Filename As %String) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC =  ##class(Ens.Util.LookupTable).%Import(Filename,"",.Count) // pFileName As %String = "", pForceTableName As %String = "", Output pCount As %Integer) As %Status
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

/// This client event is fired when the page is resized.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	if (load) {
		// Draw the main table
		this.loadDetails();
		this.setReadOnly(this.readOnly || !this.canEdit || !this.writePERMISSION);
	}
	this.adjustSizes();
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		zen('pane').setHidden(false);

		var descDiv = zen('descriptionPanel').getEnclosingDiv();
		var tgDiv = zen('tableGroup').getEnclosingDiv();
		var tableDiv = zen('notASpacer').getEnclosingDiv();
		var detailDiv = zen('detailGroup').getEnclosingDiv();

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();

		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th;

		var tableHgt = hgt - 20;
		var tableWid = winWidth - descDiv.offsetWidth - detailDiv.offsetWidth - 10;

		descDiv.style.height = (tableHgt - 8) + 'px';
		detailDiv.style.height = tableHgt + 'px';
		tgDiv.style.height = tableHgt + 'px';
		tableDiv.style.width = tableWid + 'px';
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Lookup Tables")
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit $Case(..lookupTable,"": $$$Text("Lookup Tables"),:..lookupTable)
}

Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pRibbonTitle = $$$Text("Lookup Table Viewer")
	Set pCommands(1) = $LB("cmdNew",$$$Text("New"),..tipNew,"zenPage.newTable();")
	Set pCommands(2) = $LB("cmdOpen",$$$Text("Open"),..tipOpen,"zenPage.openTable();")
	Set pCommands(3) = $LB("cmdSave",$$$Text("Save"),..tipSave,"zenPage.saveTable();")
	Set pCommands(4) = $LB("cmdSaveAs",$$$Text("Save As"),..tipSaveAs,"zenPage.saveTableAs();")
	Set pCommands(5) = $LB("cmdDelete",$$$Text("Delete"),..tipDelete,"zenPage.deleteTable();")
	Set pCommands(6) = $LB("cmdImport",$$$Text("Import"),..tipImport,"zenPage.importTable();")
	Set pCommands(7) = $LB("cmdImportLegacy",$$$Text("Import Legacy"),..tipImportLegacy,"zenPage.importTableLegacy();")
	Set pCommands(8) = $LB("cmdExport",$$$Text("Export"),..tipExport,"zenPage.exportTable();")
	Quit $$$OK
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Set tUndoTitle = $$$TextHTML("Undo last action")
	Set tSortOrder = $$$TextHTML("Display Order")
	Set tSortAlpha = $$$TextHTML("Alphabetical")
	Set tSortModified = $$$TextHTML("Modified First")
	Set tNewKeyTitle = $$$TextHTML("Add new lookup entry")
	&html<<td style="padding-left:30px;">
		<img id="iconUndo" class="reIconDisabled" title="#(tUndoTitle)#" src="portal/loop_24.gif" onclick="zenPage.undo();" />
	</td>
	<td style="padding-left: 10px;">
		<span style="font-weight: bold; font-size: 0.8em; white-space: nowrap;">#(tSortOrder)#</span>
		<select id="sortSelect" onchange="zenPage.drawTableDetails();">
			<option value="alphaSort" selected="selected">#(tSortAlpha)#</option>
			<option value="modSort">#(tSortModified)#</option>
		</select>
	</td>
	<td style="padding-left: 10px;">
		<img id="iconNewKey" class="reIconDisabled" title="#(tNewKeyTitle)#" src="portal/add_24.gif" onclick="if (zenPage.canUserModify()) zenPage.clearValues();" />
	</td>>
	
	Quit ##super()
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod,
				"RemoveTable": ..#EDITRESOURCE,
				"AfterUserDeleteAction": ..#EDITRESOURCE,
				"CheckFilename": ..#EDITRESOURCE,
				"Import": ..#EDITRESOURCE,
				"SaveLookupTable": ..#EDITRESOURCE,
				: "")
}

ClientMethod setReadOnly(readOnly) [ Language = javascript ]
{
	readOnly = !!readOnly;
	this.readOnly = readOnly;

	var addKeyClass = 'reIcon' + (readOnly || !this.canEdit ? 'Disabled' : '');
	var addKeyIcon = self.document.getElementById('iconNewKey');
	if (addKeyIcon) addKeyIcon.className = addKeyClass;
	this.toggleUndoIcon();

	zen('txtKey').setProperty('disabled',readOnly);
	zen('txtValue').setProperty('disabled',readOnly);
	
	if (readOnly) {
		zen('formApply').setProperty('controlClass','commandButtonDisabled');
		zen('formDiscard').setProperty('controlClass','commandButtonDisabled');
		this.grayOutButtons();
		if (!this.canEdit||!this.writePERMISSION) {
			this.grayOutOneButton('command_cmdNew');
			this.grayOutOneButton('command_cmdSaveAs');
		}
		if (!this.writePERMISSION) {
			this.grayOutOneButton('command_cmdImport');
			this.grayOutOneButton('command_cmdImportLegacy');
		}
	} else {
		var btnSave = document.getElementById('command_cmdSave');
		if (btnSave) {
			btnSave.className = 'commandButton';
			btnSave.onclick = function() { zenPage.saveTable();return false; }
			btnSave.title = this.tipSave;
		}
		var btnDelete = document.getElementById('command_cmdDelete');
		if (btnDelete) {
			btnDelete.className = 'commandButton';
			btnDelete.title = this.tipDelete;
			btnDelete.onclick = function() { zenPage.deleteTable();return false; }
		}
	}
}

/// Call <method>UpdateSCMenu</method>() first in case the document has been modified elsewhere,
/// then display the source control menu based on the contents of the _sourceControlMenu data
/// created by <method>UpdateSCMenu</method>().
ClientMethod showSCMenu() [ Language = javascript ]
{
	this.UpdateSCMenus();
	this.invokeSuper('showSCMenu',arguments);
}

/// Handle a source control menu selection.
ClientMethod chooseSCMenu(menuName, commandName, saveFlags) [ Language = javascript ]
{
	zenPage.wasReadOnly = zenPage.getIsReadOnly();
	this.invokeSuper('chooseSCMenu',arguments);
	zenPage.toggleReadOnly();
}

/// Get the JSON model on the client.
ClientMethod getClientModel() [ Language = javascript ]
{
	return zen('json');
}

/// Return the extension used by Studio for the class/object
ClientMethod getCurrentExtension() [ Language = javascript ]
{
	return '.LUT';
}

/// Return the current name of the class/object being modified
ClientMethod getCurrentName() [ Language = javascript ]
{
	return this.lookupTable;
}

/// Get the main table Javascript object.
ClientMethod getTableObject() [ Language = javascript ]
{
	var table = zen('json').getContentObject();
	this.updateJSONSCReadOnly(table);
	return table;
}

/// Get the list of lookup values.
ClientMethod getTableValues() [ Language = javascript ]
{
	var jsonTable = this.getTableObject();
	if (jsonTable) return jsonTable.values;
	return null;
}

/// Return the internal name of the current document.
Method GetInternalName() As %String
{
	Quit ..lookupTable_".LUT"
}

/// Helper method to ensure that <property>documentTimestamp</property> and
/// <property>readOnly</property> are up to date on the client.
ClientMethod updateDocumentState(alertOnReadOnly) [ Language = javascript ]
{
	this.invokeSuper('updateDocumentState',arguments);
	this.clearUndoBuffer();
	this.loadDetails();
}

/// Normalize the value of <property>lookupTable</property>.
Method %OnAfterCreatePage() As %Status
{
	If $zconvert($extract(..lookupTable,*-3,*),"U") = ".LUT" {
		Set ..lookupTable = $extract(..lookupTable,1,*-4)
	}
	Quit ##super()
}

/// Server method to handle Source Control framework AfterUserAction
Method AfterUserDeleteAction(tableName, pExtension) As %String [ Internal, ZenMethod ]
{
	/* No need to accept client side input for lookup table name */
	Set pExtension = ".LUT"
	Return ##super(..lookupTable, pExtension)
}

}
