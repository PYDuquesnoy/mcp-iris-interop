/// Example of a CRUD (create, read, update, delete) base class.<br/>
/// This class provides a basic template for the look and feel of a
/// series of data entry pages.<br/>
/// To use:
/// <ol>
/// <li>Create a subclass of this template class,</li>
/// <li>Set the MODELCLASS parameter to the name of your DataModel class,</li>
/// <li>Set the LOOKUPTABLE parameter to the SQL table name used to show the pick list of objects,</li>
/// <li>Set the LOOKUPCOLUMN parameter (default is "Name") to the SQL column name used in the pick list</li>
/// </ol>
Class ZENMVC.CRUDTemplate Extends %ZEN.Component.page [ Abstract ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENMVC.MVCApplication";

/// Displayed name of this page.
Parameter PAGENAME;

/// Domain used for localization.
Parameter DOMAIN;

/// Name of MVC DataModel class that supplies data for the form.
Parameter MODELCLASS As STRING;

/// SQL name of table that provides contents of the lookup table.
Parameter LOOKUPTABLE As STRING;

/// SQL name of column to display withn the lookup table.
Parameter LOOKUPCOLUMN As STRING = "Name";

/// ID of object to edit.
/// This can be passed in as a URL parameter.
Property ObjectID As %String(ZENURL = "ID");

/// Holds the name of the model class.
/// This should be set to the name of a DataModel class.
Property ModelClass As %String [ InitialExpression = {..#MODELCLASS} ];

/// Holds the name of the lookup table.
/// This should be the name of an SQL table.
Property LookupTable As %String [ InitialExpression = {..#LOOKUPTABLE} ];

/// Holds the name of the lookup column.
/// This should be the name of a column within the lookup table.
Property LookupColumn As %String [ InitialExpression = {..#LOOKUPCOLUMN} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

/* style for title bar */
#title {
	background: #404040;
	background-image: url(images/grad-gray-10x500.png);
	background-repeat: repeat-x;
	border-bottom: 1px solid black;
	text-align: center;
}

#titleBox {
	color: #202020;
	border: none;
	font-family: Arial;
	font-size: 20pt;
	font-weight: bold;
}

#navBar .tnbrTable {
	width: 500px;
}

#pickList {
	width: 500px;
}

.CRUDTemplate-title-text {
	color: #202020;
	font-family: Arial;
	font-size: 2.0em;
	font-weight: bold;
	padding: 5px;
	padding-left: 50px;
}

.CRUDTemplate-subtitle-text {
	font-size: 8pt;
}

#formGroup {
	border: 1px solid black;
	padding: 0px;
	background: #C0C0C0;
	background-image: url(images/grad-halfgray-10x500.png);
	background-repeat: repeat-x;
}

#btnGroup {
	padding: 2px;
}

.zenLabel {
	font-family: arial;
	font-weight: bold;
}

/* Input box of combobox. */
.comboboxInput {
	border: blue 1px solid;
}

a.radioSetCaption,span.checkboxCaption {
}

/* Table around navigator bar. */
.tnbrTable {
}


</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo">
<demo:demoTitle id="title" title="MVC Form Template Demonstration"/>
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="MVC Template Form" title="MVC Form Template Demo" />
</locatorBar>
<hgroup>
<vgroup valign="top">
<demo:sidebar text="This page demonstrates the following features:">
<demo:bullet text="Using a base template class to define a set of common behaviors." />
<demo:bullet text="Creating a simple form page by creating a subclass of the template class and supplying some parameter values." />
<demo:bullet text="You can use the filter box at the top of the item list to filter the set of choices." />
</demo:sidebar>
</vgroup>
<vgroup valign="top">
<spacer height="20"/>
<hgroup cellVAlign="top">
<spacer width="20"/>
<vgroup>
<tableNavigatorBar id="navBar" tablePaneId="pickList"/>
<tablePane id="pickList" tableName="#(%page.LookupTable)#"
caption="Items"
useKeys="true" 
useSnapshot="true" 
showZebra="true"
showQuery="false"
showFilters="true"
showRowNumbers="true"
valueColumn="ID"
pageSize="15"
maxRows="5000"
headerLayout="headersOnTop"
onselectrow="zenPage.rowSelected(zenThis,which);">
<column colName="ID" hidden="true"/>
<column id="displayColumn" 
colName="#(%page.LookupColumn)#" 
filterType="text" width="200"/>
</tablePane>
</vgroup>
<spacer width="10"/>
<vgroup id="formGroup">
<dataController id="controller" modelClass="#(%page.ModelClass)#" modelId="#(%page.ObjectID)#"/>
<dynaForm id="form" controllerId="controller" labelPosition="left"
cellStyle="padding: 3px;">
<titleBox id="titleBox" title="#(%page.title)#" titleStyle="border:none;" />
</dynaForm>
<hgroup id="btnGroup" cellAlign="right" width="100%">
<button id="btnNew" caption="New" title="Create a new item" onclick="zenPage.newItem();"/>
<spacer width="10"/>
<button id="btnSave" caption="Save" title="Save the current item" onclick="zenPage.saveItem();"/>
<spacer width="10"/>
<button id="btnCancel" caption="Cancel" title="Cancel the current edit operation" onclick="zenPage.cancelItem();"/>
<spacer width="10"/>
<button id="btnDelete" caption="Delete" title="Delete the current item" onclick="zenPage.deleteItem();"/>
<spacer width="10"/>
</hgroup>
</vgroup>
</hgroup>
</vgroup>
</hgroup>
</page>
}

/// Row selected in pick list; update controller.
/// <var>which</var> indicates how this event was fired.
ClientMethod rowSelected(table, which) [ Language = javascript ]
{
	if ('keypress' == which) {
		// defer this action in case the user is arrowing through a number of items
		var id = table.getValue();
		var action = new Function("zenPage.showObject('"+id+"');"); 
		zenSetDeferredAction(action,200);
	}
	else {
		// select immediately
		var id = table.getValue();
		zenPage.showObject(id);
	}
}

/// Load the object with the given id into the form.
ClientMethod showObject(id) [ Language = javascript ]
{
	var controller = zenPage.getComponentById('controller');
	controller.setModelId(id);
}

/// Create a new item to edit.
ClientMethod newItem() [ Language = javascript ]
{
	var controller = zenPage.getComponentById('controller');
	controller.createNewObject();
}

/// Cancel current edit.
ClientMethod cancelItem() [ Language = javascript ]
{
	if (confirm('Do you wish to cancel the current operation?')) {
		var controller = zenPage.getComponentById('controller');
		var id = controller.getModelId();
		controller.setModelId(id);
	}
}

/// Delete current item from database
ClientMethod deleteItem() [ Language = javascript ]
{
	var controller = zenPage.getComponentById('controller');
	var id = controller.getModelId();

	if ('' == id) {
		alert('Nothing selected to delete.');
	}
	else if (confirm('Do you wish to delete this item?')) {
		controller.deleteId(id);

		var table = zenPage.getComponentById('pickList');
		table.executeQuery();
	}
}

ClientMethod saveItem() [ Language = javascript ]
{
	var form = zenPage.getComponentById('form');
	form.save();

	// refresh the table
	var table = zenPage.getComponentById('pickList');
	table.executeQuery();
}

}

