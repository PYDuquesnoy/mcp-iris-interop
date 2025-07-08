/// ZENTest.FormTest
Class ZENTest.FormTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "Form Test Page";

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

.button {
	width: 15.0em;
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
<html><a href="ZENTest.FormTest.cls?$SUBMIT=clear">Link</a>
</html>
<spacer height="25"/>
<hgroup>
<spacer width="100"/>
<form id="MyForm" layout="vertical" 
	onchange="zenPage.formChange(zenThis);">
<html id="indicator"/>
<text label="Name:" id="Name" name="Name" 
	labelClass="required" required="true"/>
<text label="Age:" id="Age" name="Age" hidden="true"
		onvalidate="return zenPage.validateAge(zenThis);" />
<dateText label="Date Of Birth:" id="DOB" name="DOB" />
<dataCombo label="Patient:" id="Patient" name="Patient"
	title="Enter a value and press dropdown button to search for patients..."
	editable="true"
	size="24"
	searchKeyLen="8"
	sql="SELECT ID,Name FROM ZENDemo_Data.Employee WHERE Name %STARTSWITH ? OR (? IS NULL) ORDER BY Name"
	sqlLookup="SELECT Name FROM ZENDemo_Data.Employee WHERE ID = ?" />
<dataCombo label="Doctor:" id="Doctor" name="Doctor"
	editable="true"
	size="24"
	searchKeyLen="3"
	sql="SELECT ID,SSN FROM ZENDemo_Data.Employee WHERE SSN %STARTSWITH ? OR (? IS NULL) ORDER BY SSN"
	sqlLookup="SELECT SSN FROM ZENDemo_Data.Employee WHERE ID = ?" />
<combobox label="Priority:" id="Priority" name="Priority">
<option value="1" text="One"/>
<option value="2" text="Two"/>
</combobox>
<checkbox caption="Enabled" label="Status:" id="Enabled" name="Enabled"
	onvalidate="return zenPage.validateEnabled(zenThis);"
		/>
<radioSet label="Quark:" id="Quark" name="Quark" valueList="Up,Down,Charmed,Strange,Top,Bottom" />
<fieldSet id="custom" legend="User Components" condition="$D(^controls)" />

<hgroup>
<radioButton caption="R1" id="A1" name="A1" optionValue="10"/>
<radioButton caption="R2" name="A1" optionValue="20"/>
<radioButton caption="R3" name="A1" optionValue="30"/>
</hgroup>
<submit caption="Submit" action="save"/>
<button caption="Validate" onclick="zenPage.validateForm();"/>
<submit caption="Save and Go Home" action="save"
	nextPage="ZENTest.HomePage.cls"
	title="Submit this and go back to the main test page."
	 />
<button caption="Programmatic Submit" 
	title="Submit this form programmatically."
	onclick="zenPage.submitForm();"/>

<button caption="Clear Modified" 
	title="Reset the modified state of this form."
	onclick="zenPage.formClearModified();"/>

<button caption="Reset" 
	title="Reset this form."
	onclick="zenPage.resetForm();"/>

<button caption="TEST" 
	onclick="zenPage.test();"/>

</form>
</hgroup>
</page>
}

ClientMethod test() [ Language = javascript ]
{
	var ctrl = zenPage.getComponentById('Age');
	ctrl.setProperty('hidden',!ctrl.getProperty('hidden'));
}

/// Form invalid handler
ClientMethod formInvalid(form, list) [ Language = javascript ]
{
	alert(list.length);
	return false;
}

ClientMethod formChange(form) [ Language = javascript ]
{
	// get mod state of form
	var flag = form.isModified();
	
	// update indicator
	var html = zenPage.getComponentById('indicator');
	html.setProperty('content',flag ? 'Form Modified' : 'Form OK');
}

ClientMethod formClearModified() [ Language = javascript ]
{
	var form = zenPage.getComponentById('MyForm');
	form.clearModified();
}

/// MyMethod
ClientMethod keyPress(combo, evt) [ Language = javascript ]
{
	alert(evt.keyCode);
}

/// validateAge
ClientMethod validateAge(ctrl) [ Language = javascript ]
{
	var value = ctrl.getValue();
	return (value > 0 && value < 120);
}

/// validateEnabled
ClientMethod validateEnabled(ctrl) [ Language = javascript ]
{
	// make sure check box is checked!
	var value = ctrl.getValue();
	return (value == true);
}

/// Submit the form programmatically
ClientMethod submitForm() [ Language = javascript ]
{
	var form = zenPage.getComponentById('MyForm');
	form.submit('save');
}

/// Validate the form programmatically
ClientMethod validateForm() [ Language = javascript ]
{
	var form = zenPage.getComponentById('MyForm');
	form.validate();
}

/// Reset the form programmatically
ClientMethod resetForm() [ Language = javascript ]
{
	var form = zenPage.getComponentById('MyForm');
	form.reset();
}

ClientMethod test1() [ Language = javascript ]
{
	var ctrl = zenPage.getComponentById('Name');
	zenPage.addOverlay();
}

ClientMethod test2() [ Language = javascript ]
{
	var ctrl = zenPage.getComponentById('Name');
	zenPage.removeOverlay();
}

/// This callback is called after the page model is created.
Method %OnAfterCreatePage() As %Status
{
	Set tGroup = ..%GetComponentById("custom")

	If $D(^controls) {

		Set tGroup = ..%GetComponentById("custom")
		Set tInnerGroup = ##class(%ZEN.Component.vgroup).%New()
		Set tInnerGroup.id = "userControls"
		Do tGroup.%AddChild(tInnerGroup)
	
		// create dynamic set of controls
		// ^controls = type^label
		Set key = $O(^controls(""))
		While (key '= "") {
			Set tType = $P(^controls(key),"^",1)
			Set tLabel = $P(^controls(key),"^",2)
	
			Set ctrl = $zobjclassmethod(tType,"%New")
			Set ctrl.label = tLabel
			Set ctrl.name = tLabel
			Do tInnerGroup.%AddChild(ctrl)
			
			Set key = $O(^controls(key))
		}
	}

	// give values to controls
	Do ..%SetValueById("A1",$G(^formTest("A1")))
	Do ..%SetValueById("Name",$G(^formTest("Name")))
	Do ..%SetValueById("Age",$G(^formTest("Age")))
	Do ..%SetValueById("DOB",$G(^formTest("DOB")))
	Do ..%SetValueById("Patient",$G(^formTest("Patient")))
	Do ..%SetValueById("Doctor",$G(^formTest("Doctor")))
	Do ..%SetValueById("Quark",$G(^formTest("Quark")))
	Do ..%SetValueById("Enabled",$G(^formTest("Enabled")))
	Quit $$$OK
}

ClassMethod %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	If (pSubmit.%Action = "save") {
		
		// validate
		If (pSubmit.%GetValue("Name")="BAD") {
			Do pSubmit.%SetError("Name","BAD VALUE")
		}
		If (pSubmit.%GetValue("Age")>120) {
			Do pSubmit.%SetError("Age","OUT OF RANGE")
		}
		If (pSubmit.%GetValue("Quark")="Bottom") {
			Do pSubmit.%SetError("Quark","Not discovered!")
		}

		If (pSubmit.%HasErrors()) {
			#; set form error
			Do pSubmit.%SetError("MyForm","There are errors on this form.")
		}
		Else {
			#; save
			Set ^formTest("Name") = pSubmit.%GetValue("Name")
			Set ^formTest("Age") = pSubmit.%GetValue("Age")
			Set ^formTest("DOB") = pSubmit.%GetValue("DOB")
			Set ^formTest("Patient") = pSubmit.%GetValue("Patient")
			Set ^formTest("Doctor") = pSubmit.%GetValue("Doctor")
			Set ^formTest("Quark") = pSubmit.%GetValue("Quark")
			Set ^formTest("Enabled") = pSubmit.%GetValue("Enabled")
			Set ^formTest("A1") = pSubmit.%GetValue("A1")
		}
	}
	ElseIf (pSubmit.%Action = "clear") {
		// clear data
		Kill ^formTest
	}
	Quit $$$OK
}

}

