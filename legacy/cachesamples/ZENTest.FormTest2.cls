/// ZENTest.FormTest
Class ZENTest.FormTest2 Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Form Test Page (2)";

/// Id of employee to show on form
Property EmpID As %ZEN.Datatype.integer(ZENURL = "ID");

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

.zendiv {
	padding-bottom: 5px;
}

#indicator {
	background: #D0D0FF;
	font-weight: bold;
	border: 1px solid darkblue;
	padding: 2px;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Form Test Page">
<demo:demoTitle id="title" title="Zen Form Test Page" category="Zen Test Suite" />
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="Form Test" title="Form Test Page" />
</locatorBar>

<spacer height="25"/>
<hgroup>
<spacer width="100"/>
<form id="MyForm" layout="vertical" 
	key="#(%page.EmpID)#"
	OnLoadForm="LoadForm"
	OnSubmitForm="SubmitForm"
>
<hgroup cellVAlign="bottom">
<text label="ID:" id="ID" 
	name="ID" onchange="zenPage.reloadForm();" />
</hgroup>

<text label="Name:" id="Name" name="Name" 
	labelClass="required" required="true"/>

<text label="SSN:" id="SSN" name="SSN" 
	labelClass="required" required="true"/>
	
<!-- demonstrate how to use the file selection dialog -->	
<fieldSet legend="File Selection" labelPosition="left">

<text label="File name:" id="txtFilename" name="txtFilename" size="40"/>
<text id="wildcard" label="File type wildcard:" value="*"/>
<checkbox id="showdirectoryonly" label="Show directories only:"/>
<button caption="Browse..." onclick="zenPage.showFileSelectionWindow();"/>

</fieldSet>
<submit caption="Submit" action="save"/>
</form>
</hgroup>
</page>
}

/// Callback to get values for form
Method LoadForm(pKey As %String, ByRef pValues As %String) As %Status
{
	Set emp = ##class(ZENDemo.Data.Employee).%OpenId(pKey)
	If ($IsObject(emp)) {
		Set pValues("ID") = emp.%Id()
		Set pValues("Name") = emp.Name
		Set pValues("SSN") = emp.SSN
	}
	Quit $$$OK
}

/// Callback to process values submitted for form.
ClassMethod SubmitForm(pSubmit As %ZEN.Submit) As %Status
{
	Set tSC = $$$OK

	If (pSubmit.%Action = "save") {
		// validate
		If (pSubmit.%GetValue("Name")="BAD") {
			Do pSubmit.%SetError("Name","BAD VALUE")
			Do pSubmit.%SetValue("SSN",666) // !!!
		}

		If (pSubmit.%HasErrors()) {
			#; set form error
			Do pSubmit.%SetError("MyForm","There are errors on this form.")
		}
		Else {
			Set emp = ##class(ZENDemo.Data.Employee).%OpenId(pSubmit.%FormKey)
			If ($IsObject(emp)) {
				Set emp.Name = pSubmit.%GetValue("Name")
				Set emp.SSN = pSubmit.%GetValue("SSN")
				Set tSC = emp.%Save()
				
			}
		}
		#; pass ID along to new page
		Set %response.Context("ID") = pSubmit.%FormKey
	}
	Quit tSC
}

/// reloadForm:
ClientMethod reloadForm() [ Language = javascript ]
{
	var id = zenPage.getComponentById('ID').getValue();
	var form = zenPage.getComponentById('MyForm');
	form.reload(id);
}

/// Demonstration of launching a file selector window. 
ClientMethod showFileSelectionWindow() [ Language = javascript ]
{
	var Dir = zenPage.getComponentById("txtFilename").getValue();
	var wildcard = zenPage.getComponentById("wildcard").getValue();
	var showdirectoryonly = zenPage.getComponentById("showdirectoryonly").getValue();
	var url = "%ZEN.Dialog.fileSelect.cls?Dir=" + cspEncodeUTF8(Dir) + "&wildcard=" + wildcard;
	if (showdirectoryonly) url = url +"&showdirectoryonly=1";
	zenLaunchPopupWindow(url,'FileSelection','status,scrollbars,resizable,width=500,height=700');
}

/// Returning from file select dialog and setting the value into the Filename field
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		var txtFilename = zenPage.getComponentById("txtFilename");
		txtFilename.setValue(value);
	}
}

}

