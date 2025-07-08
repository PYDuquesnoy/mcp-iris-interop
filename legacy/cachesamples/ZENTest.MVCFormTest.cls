/// Test page for MVC Form.
Class ZENTest.MVCFormTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "MVC Form Test Page";

Parameter DOMAIN = "ZENTEST";

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
<form id="MyForm" layout="vertical" controllerId="controller">

<!-- changing this will automatically change the dataController id -->
<text label="ID:" id="id" name="id" 
	dataBinding="%id" size="5"/>

<text label="Name:" id="Name" name="Name" 
	labelClass="required" required="true" 
	dataBinding="Name"/>

<text label="City:" id="City" name="City" 
	dataBinding="City"/>

<textarea label="Memo:" id="Memo" name="Memo" rows="8" cols="30"
	dataBinding="Memo"/>

<radioSet label="Sex:" id="Sex" name="Sex" 
	dataBinding="Sex" valueList="Male,Female,Other,Unknown"/>

<text label="Employee:" id="Employee" name="Employee" size="5"
	dataBinding="Employee"/>

<spacer height="20"/>
<hgroup>
<button caption="Save" onclick="zenPage.saveForm();"/>
</hgroup>
	
</form>

</hgroup>

</page>
}

/// saveForm
ClientMethod saveForm() [ Language = javascript ]
{
	var form = zenPage.getComponentById('MyForm');
	form.save();
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	/*
	Set img = ..%GetComponentById("Picture")
	Set id=##class(%FileCharacterStream).GetStreamIdForFile("\temp\zentitle.jpg")
	Set img.streamId = id
	*/
	
	/// !!!
	Set %session.Preserve = 1

	Quit $$$OK
}

}

