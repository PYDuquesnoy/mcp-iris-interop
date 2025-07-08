/// Test page for MVC DynaForm.
Class ZENTest.MVCDynaFormTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "MVC Form Test Page";

/// Domain used for localization.
/// Parameter DOMAIN = "ZENTEST";
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

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="MVC Form Test Page">

<demo:demoTitle id="title" title="Zen MVC Form Test Page" category="Zen Test Suite" />
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="MVC Form Test" title="MVC Form Test Page" />
</locatorBar>

<spacer height="25"/>
<hgroup>
<spacer width="100"/>
<dataController id="controller" modelClass="ZENTest.DataModel" modelId="1"/>
<dynaForm id="MyForm" layout="vertical" controllerId="controller"
defaultGroupId="group">

<vgroup id="group"/>

<spacer height="20"/>
<hgroup>
<button caption="Save" onclick="zenPage.saveForm();"/>
</hgroup>
	
</dynaForm>
</hgroup>
</page>
}

/// saveForm
ClientMethod saveForm() [ Language = javascript ]
{
	var form = zenPage.getComponentById('MyForm');
	form.save();
}

}

