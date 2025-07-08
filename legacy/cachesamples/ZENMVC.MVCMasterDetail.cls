/// Model-View-Controller MasterDetail page.
/// This page uses the Zen MVC mechanism to create a simple Master-Detail page.
Class ZENMVC.MVCMasterDetail Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENMVC.MVCApplication";

Parameter PAGENAME = "MVC Master-Detail Page";

/// Localized string that will be available to the client.
Property deleteMsg As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Ok to delete this record?","ZENDEMO")} ];

/// Domain used for localization.
/// Parameter DOMAIN = "";
XData Style
{
<style type="text/css">

#userControls {
	height: 200px;
	overflow: auto;
}

.required {
	font-weight: bold;
}

.required:after {
	content: " (required)";
	font-style: italic;
	font-size: 0.8em;
	
}

#indicator {
	background: #D0D0FF;
	font-weight: bold;
	border: 1px solid darkblue;
	padding: 2px;
}

#table {
	width: 800px;
	border: 1px solid darkblue;
}

#myForm {
	width: 800px;
	border: 1px solid black;
	background: #404040;
	background-image: url(images/grad-gray-10x500.png);
	background-repeat: repeat-x;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="MVC Master Detail Page">
<demo:demoTitle id="title" title="MVC Master Detail Demonstration"/>
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="MVC Master Detail" title="MVC Master Detail Demo" />
</locatorBar>

<hgroup valign="top">
<vgroup valign="top">
<demo:sidebar text="This page demonstrates the following features:">
<demo:bullet text="Using the Zen dataController component to automatically link data from a server-side Data Model to components on a web page." />
<demo:bullet text="A tablePane is used to display the results of an SQL query." />
<demo:bullet text="A form is bound to the dataController." />
<demo:bullet text="When the user selects a row in the table, the object id of the dataController is changed. This causes new data to be loaded and applied to the linked form." />
</demo:sidebar>
</vgroup>

<spacer width="10"/>

<vgroup valign="top">
<spacer height="10"/>

<dataController id="source" 
	modelClass="ZENMVC.FormDataModel" modelId="#(%url.ID)#"/>
<tableNavigatorBar tablePaneId="table" 
	showPageSize="true"
	showFilter="false" onfilterChange="zenPage.filterChanged(value);" />
<spacer height="10"/>
<tablePane id="table" 
	caption="Master Table"
	tableName="ZENDemo_Data.Patient"
	useSnapshot="true"
	showFilters="true"
	showQuery="false"
	showZebra="true"
	pageSize="20"
	fixedHeaders="true"
	bodyHeight="13.0em"
	headerLayout="filtersOnTop"
	valueColumn="ID"
	value="#(%url.ID)#"
	maxRows="1000"
	useKeys="true"
	onselectrow="zenPage.rowSelected(zenThis,which);"
	>
<column colName="ID" width="25"/>
<column colName="Name" width="180" filterType="text"/>
<column colName="SSN" width="100" filterType="text"/>
<column colName="MaritalStatus" width="20" filterType="text"/>
<column colName="City" colExpression="Home_City" width="100" filterType="text"/>
<column colName="State" colExpression="Home_State" width="25" filterType="text" filterOp="="/>

</tablePane>
<spacer height="10"/>
<hgroup>
<form id="myForm" layout="vertical" controllerId="source">
<hgroup>
<vgroup valign="top">
<text label="ID:" id="ID" name="ID" 
	dataBinding="%id" size="5"
	readOnly="true"/>

<text label="Name:" id="Name" name="Name" 
	dataBinding="Name" size="30"
	labelClass="required" required="true"/>

<text label="SSN:" id="SSN" name="SSN" 
	dataBinding="SSN"
	size="15"
	labelClass="required" required="true"/>
</vgroup>
<spacer width="10"/>
<vgroup valign="top">

<text label="City:" id="City" name="City" 
	size="12"
	dataBinding="City"
	/>

<text label="State:" id="State" name="State" 
	size="2"
	dataBinding="State"
	/>
	
<select label="MaritalStatus:" id="MaritalStatus1" name="MaritalStatus" 
	dataBinding="MaritalStatus"
	valueList="S,M,D,W,O" displayList="Single,Married,Divorced,Widowed,Other"/>
</vgroup>
</hgroup>

<spacer height="10"/>
<hgroup>
<button caption="New" onclick="zenPage.newItem();" />
<spacer width="10"/>
<button caption="Save" onclick="zenPage.saveItem();" />
<spacer width="10"/>
<button caption="Cancel" onclick="zenPage.cancel();" />
<spacer width="10"/>
<button caption="Delete" onclick="zenPage.deleteItem();" />
<spacer width="10"/>
<button caption="Action" onclick="zenPage.invokeAction();" />
</hgroup>
</form>
<spacer width="50"/>
</hgroup>
</vgroup>
</hgroup>
</page>
}

/// Filter changed in table navigator
ClientMethod filterChanged(value) [ Language = javascript ]
{
	alert(value);
}

/// Row in Master table select; update controller.
/// <var>which</var> indicates how this event was fired.
ClientMethod rowSelected(table, which) [ Language = javascript ]
{
	if ('keypress' == which) {
		// defer this action in case the user is arrowing through a number of items
		var id = table.getValue();
		var action = new Function("zenPage.getComponentById('source').setProperty('modelId','"+id+"');"); 
		zenSetDeferredAction(action,200);
	}
	else {
		// select immediately
		var id = table.getValue();
		var controller = zenPage.getComponentById('source');
		controller.setProperty('modelId',id);
	}
}

/// Create new object via dataModel
ClientMethod newItem() [ Language = javascript ]
{
	var controller = zenPage.getComponentById('source');
	controller.createNewObject();
}

/// save form to database
ClientMethod saveItem() [ Language = javascript ]
{
	var form = zenPage.getComponentById('myForm');
	form.save();

	var table = zenPage.getComponentById('table');
	table.executeQuery(true);
}

/// cancel the current action
ClientMethod cancel() [ Language = javascript ]
{
	var form = zenPage.getComponentById('myForm');
	form.reset();

	var table = zenPage.getComponentById('table');
	table.selectRow(-1);

	var controller = zenPage.getComponentById('source');
	controller.setProperty('modelId','');
}

/// Delete current item from database
ClientMethod deleteItem() [ Language = javascript ]
{
	if (confirm(this.deleteMsg)) {
		var controller = zenPage.getComponentById('source');
		controller.deleteId(controller.getModelId());
	
		var table = zenPage.getComponentById('table');
		table.executeQuery(true);
	}
}

/// Invoke an action on the dataModel
ClientMethod invokeAction() [ Language = javascript ]
{
	var controller = zenPage.getComponentById('source');
	controller.invokeAction('log');
}

}

