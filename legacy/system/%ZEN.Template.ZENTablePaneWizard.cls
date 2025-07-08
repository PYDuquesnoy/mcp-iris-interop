/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template:<br>
/// Inserts a new tablePane definition within an XData definition.
Class %ZEN.Template.ZENTablePaneWizard Extends %ZEN.Template.studioTemplate [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "Zen TablePane Wizard";

Parameter TEMPLATETITLE = "Zen TablePane Wizard";

Parameter TEMPLATEDESCRIPTION = "Inserts a Zen tablePane definition within a Contents document.";

Parameter TEMPLATETYPE = "cls";

/// What type of template.
Parameter TEMPLATEMODE = "template";

/// Domain used for localization.
Parameter DOMAIN = "%ZEN";

/// %session.CSPSessionCookie passed as CSPCHD for Browse dialog
Property CSPSessionCookie As %String [ InitialExpression = {%session.CSPSessionCookie} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

/* Default style for labels. */
.zenLabel {
	color: darkblue;
	font-size: 0.8em;
	font-weight: bold;
}

.zenLabelDisabled {
	color: gray;
	font-size: 0.8em;
	font-weight: normal;
}

#inspectorGroup {
	height: 300px;
	width: 500px;
	overflow: auto;
}

</style>
}

/// This XML block defines the contents of the body pane of this Studio Template.
XData templateBody
{
<pane id="body">
<tabGroup id="tabGroup" onshowTab="zenPage.tabChange(zenThis);">
<tab>
<html id="desc" OnDrawContent="%GetDescHTML"/>
<vgroup labelPosition="left" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<hidden id="results" name="results" />

<radioButton caption="Table" name="dataSource" id="rbTable" optionValue="table"
	onchange="zenPage.dataSourceChange(zenThis);"/>
<text id="txtTable" disabled="true" label="Table name:" size="40"/>

<radioButton caption="Class query" name="dataSource" id="rbQuery" optionValue="query"
	onchange="zenPage.dataSourceChange(zenThis);"/>
<text id="txtQueryClass" disabled="true" label="Query class:" size="40"/>
<text id="txtQueryName" disabled="true" label="Query name:" size="40"/>
</vgroup>

</tab>
<tab>
<vgroup valign="top">
<html id="desc2" OnDrawContent="%GetDescHTML2"/>
<spacer height="5"/>
<hgroup cellVAlign="top">
<vgroup valign="top">
<titleBox title="Columns" />
<textarea rows="8" id="taColumns" onchange="zenPage.columnChange(zenThis);" />
</vgroup>
<spacer width="10"/>
<vgroup id="inspectorGroup" valign="top">
<titleBox title="tablePane Attributes" />
<objectInspector id="objectInspector" 
	showAll="false"
	onedit="zenPage.editProperty();"/>
</vgroup>
</hgroup>

<tablePane id="tablePane"
	permitClientSQL="true"
/>
</vgroup>

</tab>
</tabGroup>

</pane>
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("This wizard inserts a new Zen tablePane definition within an Xdata block of a Zen page class."),"<br/>"
	Write $$$TextHTML("Select the source of the query for this tablePane and then press Next."),"<br/>"
	Quit $$$OK
}

/// Provide contents of description component.
Method %GetDescHTML2(pSeed As %String) As %Status
{
	Write $$$TextHTML("Adjust the settings of the tablePane. Press Finish when complete.")
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Quit $$$OK
}

/// This client event, if present, is fired when the page 
/// is first loaded or whenever it is resized.<br>
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	this.adjustSize();

	// adjust size of tablePane
	var pane = zenPage.getComponentById('tablePane');
	var winWidth = zenGetWindowWidth();

	var sz = winWidth - 350;
	pane.setProperty('width',sz);
}

/// Notification that the columns list has changed.
ClientMethod columnChange(ta) [ Language = javascript ]
{
	// update columns for table
	this._tablePane.columns.length = 0;
	var colList = ta.getValue().split('\n');
	for (var n = 0; n < colList.length; n++) {
		if ('' != colList[n]) {
			var column = zenPage.createComponent('column');
			column.setProperty('colName',colList[n]);
			this._tablePane.columns[this._tablePane.columns.length] = column;
		}
	}

	this._tablePane.executeQuery();
}

/// Notification that the data source has changed.
ClientMethod dataSourceChange(rb) [ Language = javascript ]
{
	var ds = rb.getValue();

	switch (ds) {
	case 'table':
		zenPage.getComponentById('txtTable').setDisabled(false);
		zenPage.getComponentById('txtQueryClass').setDisabled(true);
		zenPage.getComponentById('txtQueryName').setDisabled(true);
		break;
	case 'query':
		zenPage.getComponentById('txtTable').setDisabled(true);
		zenPage.getComponentById('txtQueryClass').setDisabled(false);
		zenPage.getComponentById('txtQueryName').setDisabled(false);
		break;
	default:
		zenPage.getComponentById('txtTable').setDisabled(true);
		zenPage.getComponentById('txtQueryClass').setDisabled(true);
		zenPage.getComponentById('txtQueryName').setDisabled(true);
		break;
	}
	
	this.updateState();
}

/// Notification that a new tab was selected.
ClientMethod tabChange(tabGroup) [ Language = javascript ]
{
	var tabNo = tabGroup.getCurrTabNo();

	switch(tabNo) {
	case 2:
		// set data source for table
		var ds = zenPage.getComponentById('rbTable').getValue();
		switch (ds) {
		case 'table':
			var encName = this.GetEncName(zenPage.getComponentById('txtTable').getValue());
			this._tablePane.setProperty('tableName',encName);
			this._tablePane.setProperty('queryClass','');
			this._tablePane.setProperty('queryName','');
			break;
		case 'query':
			this._tablePane.setProperty('tableName','');
			var encName = this.GetEncName(zenPage.getComponentById('txtQueryClass').getValue());
			this._tablePane.setProperty('queryClass',encName);
			this._tablePane.setProperty('queryName',zenPage.getComponentById('txtQueryName').getValue());
			break;
		default:
			this._tablePane.setProperty('tableName','');
			this._tablePane.setProperty('queryClass','');
			this._tablePane.setProperty('queryName','');
			break;
		}
	
		// update table
		this._tablePane.executeQuery();

		// point inspector
		var inspector = zenPage.getComponentById('objectInspector');
		inspector.setCurrObject(this._tablePane);

		break;
	}

	// adjust layout
	this.adjustSize();
}

/// Validation handler for form built-into template.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	return true;
}

ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return true;
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
ClientMethod canGoNext() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	
	switch(tabNo) {
	case 1:
		// if user selects a data source, we can go to the next tab
		return true
	}

	return false;
}

/// Return true if this template can go to the previous page (i.e., enable
/// the Back button).<br>
ClientMethod canGoBack() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');

	return (tabGroup.getCurrTabNo() > 1);
}

/// Go to the next page of the template (if there is one).<br>
ClientMethod nextPage() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	tabGroup.showNextTab();
	this.updateState();
}

/// Go to the previous page of the template (if there is one).<br>
ClientMethod previousPage() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	tabGroup.showPreviousTab();
	this.updateState();
}

/// User has pressed edit button in the objectInspector.
ClientMethod editProperty() [ Language = javascript ]
{
	var inspector = this.getComponentById('objectInspector');

	// request to edit a property
	var obj = inspector.getCurrObject();
	var mbr = inspector.getCurrMember();
	
	zenASSERT(obj,'No object to edit',arguments);
	zenASSERT(mbr,'No object property to edit',arguments);
	
	if ('id' == mbr) {
		alert('Editing of id value is not allowed on this page.');
		return;
	}

	// launch the built-in component value editor dialog
	var value = obj.getProperty(mbr);
	var mbrType = inspector.getCurrMemberType();
	if (mbrType == 'boolean') {
		value = (value) ? '1' : '0';
	}

	var parms = new Object();
	parms.property = mbr;
	parms.className = obj._serverClass;
	parms.value = value;
	parms.type = mbrType;
	var link = '%ZEN.Dialog.componentValueEditor.cls?CSPCHD=' + this.CSPSessionCookie + '&CSPSHARE=1';
	zenPage.launchPopupWindow(link,'ValueEditor','resizable,width=500,height=500',parms,this);
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	var inspector = this.getComponentById('objectInspector');
	switch (action) {
	case 'ok':
	case 'apply':
		var obj = inspector.getCurrObject();
		var mbr = inspector.getCurrMember();
		var mbrType = inspector.getCurrMemberType();
		if (mbrType == 'boolean') {
			value = ('1' == value) ? true : false;
		}

		var handled = obj.setProperty(mbr,value);
		if (!handled && obj.refreshContents) {
			// if object did not handle set, go to server!
			obj.refreshContents();
		}
		inspector.setCurrObject(obj);
		if ('ok' == action) {
			inspector.setCurrMember('');
		}
		break;
	}
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	// Get reference to table pane (its id may change!)
	this._tablePane = zenPage.getComponentById('tablePane');
}

/// This is called when the template is finished;
ClientMethod onfinishHandler() [ Language = javascript ]
{
	// get XML version of tablePane, store in hidden field
	var ctrl = zenPage.getComponentById('results');
	ctrl.setValue(this.SerializeTable(this._tablePane));
	return true;
}

/// Convert table to xml representation.
ClassMethod SerializeTable(pTable As %ZEN.Component.tablePane) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tState = ""
	Set $ZT="Trap"
	Do {
		#; serialize to xml
		Set tStream = ##class(%Stream.TmpCharacter).%New()
		Set pTable.permitClientSQL = 0
		Set tSC = ##class(%ZEN.Utils).%ObjectToXML(tStream,pTable,.tNS)
		If $$$ISERR(tSC) Quit
		
		Set tState = tStream.Read(30000)
	} While(0)
Done
	Quit tState
Trap
	Set $ZT=""
	Set tState = ""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.
Method %OnTemplateAction() As %Status
{
	Write ..%GetValueByName("results")
	Quit $$$OK
}

/// Return encrypted table name or query name
ClassMethod GetEncName(pTableName) As %String [ ZenMethod ]
{
	Set EncName = ""
	Set $ZT="Trap"
	Do {
		Set EncName = ..Encrypt(pTableName)
	} While(0)
Done
	Quit EncName
Trap
	Set $ZT=""
	Set EncName = ""
	Goto Done
}

}
