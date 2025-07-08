/// Model-View-Controller form demo page.
/// This page uses the Zen MVC mechanism to create a form.
Class ZENMVC.MVCForm Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENMVC.MVCApplication";

Parameter PAGENAME = "MVC Form Page";

/// This defines the ID of the initial object to display.
/// You can pass this in via the URL parameter, <var>ID</var>, if you like.
Property ObjID As %ZEN.Datatype.integer(ZENURL = "ID") [ InitialExpression = 1 ];

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

#group1, #group2 {
	border: 1px solid darkblue;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="MVC Form Page">
<demo:demoTitle id="title" title="MVC Form Demonstration"/>
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="MVC Form" title="MVC Form Demo" />
</locatorBar>
<hgroup>
<vgroup valign="top">
<demo:sidebar text="This page demonstrates the following features:">
<demo:bullet text="Using the Zen dataController component to automatically link data from a server-side Data Model to components on a web page." />
<demo:bullet text="A form whose fields are bound to the properties supplied by the dataController." />
</demo:sidebar>
</vgroup>
<spacer width="10"/>

<vgroup valign="top">
<spacer height="10"/>

<dataController id="source" 
	modelClass="ZENMVC.FormDataModel" modelId="#(%page.ObjID)#"/>

<hgroup labelPosition="left">
<spacer width="10"/>
<text label="ID:" id="objid" value="#(%page.ObjID)#" size="4" onchange="zenPage.findObject();" />
<button caption="Load" onclick="zenPage.findObject();" />
</hgroup>
<spacer height="10"/>

<hgroup>
<form id="MyForm" layout="vertical" 
	controllerId="source" valign="top"
>
<text label="Name:" id="Name" name="Name" 
	dataBinding="Name"
	labelClass="required" required="true"/>

<text label="SSN:" id="SSN" name="SSN" 
	dataBinding="SSN"
	labelClass="required" required="true"/>

<dataCombo label="City:" id="City" name="City" 
	dataBinding="City"
	/>

<textarea label="Memo:" id="Memo" name="Memo" 
	dataBinding="Memo"
/>
<button caption="Save" onclick="zenPage.save();" />
</form>
<spacer width="50"/>
</hgroup>
</vgroup>
</hgroup>

</page>
}

/// save model to database
ClientMethod save() [ Language = javascript ]
{
	// validate and save form
	var form = zenPage.getComponentById('MyForm');
	form.save();
}

/// Find and load the object whose id is in the objid text box.
ClientMethod findObject() [ Language = javascript ]
{
	var ctrl = zenPage.getComponentById('objid');
	var id = ctrl.getValue();
	var controller = zenPage.getComponentById('source');
	controller.setModelId(id);
}

}

