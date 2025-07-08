/// Model-View-Controller dyanamic form demo page.
/// This page uses the Zen MVC mechanism to create a dynamic form.
Class ZENMVC.MVCDynaForm Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENMVC.MVCApplication";

Parameter PAGENAME = "MVC Dynamic Form Page";

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

.zenLabel {
	padding-top: 2px;
	font-size: 0.8em;
	color: darkblue;
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
<demo:bullet text="A set of forms are linked to the dataController. Changes in data are automatically propagated to all the forms." />
</demo:sidebar>
</vgroup>
<spacer width="10"/>

<vgroup valign="top">
<spacer height="10"/>

<dataController id="source" 
	modelClass="ZENMVC.Person" modelId=""/>

<hgroup>

<dynaForm id="MyForm" controllerId="source" valign="top"/>
</hgroup>
<hgroup>
<spacer width="100"/>
<button caption="Previous" onclick="zenPage.previousObject();" />
<spacer width="20"/>
<button caption="Next" onclick="zenPage.nextObject();" />
<spacer width="20"/>
<button caption="Save" onclick="zenPage.save();" />
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

/// Point controller to next object.
ClientMethod nextObject() [ Language = javascript ]
{
	var controller = zenPage.getComponentById('source');
	var id = controller.getProperty('modelId');
	id = parseInt(id) + 1;
	id = (id >= 3) ? 1 : id;
	controller.setProperty('modelId',id);
}

/// Point controller to previous object.
ClientMethod previousObject() [ Language = javascript ]
{
	var controller = zenPage.getComponentById('source');
	var id = controller.getModelId();
	id = parseInt(id) - 1;
	id = (id <= 0) ? 3 : id;
	controller.setModelId(id);
}

}

