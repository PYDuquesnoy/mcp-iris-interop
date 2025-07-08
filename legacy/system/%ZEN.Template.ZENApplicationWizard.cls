/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template:<br>
/// Create a new Zen application class.
Class %ZEN.Template.ZENApplicationWizard Extends %ZEN.Template.studioTemplate [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "Zen Application";

Parameter TEMPLATETITLE = "Zen Application Wizard";

Parameter TEMPLATEDESCRIPTION = "Create a new Zen application class.";

Parameter TEMPLATETYPE = "cls";

/// What type of template.
Parameter TEMPLATEMODE = "new";

Parameter TEMPLATEGROUP = "Zen";

/// Domain used for localization.
Parameter DOMAIN = "%ZEN";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// This XML block defines the contents of the body pane of this Studio Template.
XData templateBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="body">

<vgroup labelPosition="left" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<html id="desc" OnDrawContent="%GetDescHTML"/>
<dataCombo label="Package Name:"
		id="ctrlPackage"
		name="Package"
		required="true"
		labelClass="zenRequired"
		title="Package name for the new application"
		editable="true"
		unrestricted="true"
		searchKeyLen="0"
		maxRows="500"
		size="40"
		dropdownWidth="20.0em"
		OnCreateResultSet="CreatePackageRS"
		onchange="zenPage.updateState();"
/>

<text label="Class Name:" 
	id="ctrlClassName"
	name="ClassName"
	size="40"
	required="true"
	labelClass="zenRequired"
	title="Class name for the new application" 
	onchange="zenPage.updateState();"
/>

<text label="Application Name:" 
	id="ctrlAppName"
	name="AppName"
	size="40"
	title="Display name for the new application" 
	onchange="zenPage.updateState();"
/>
<textarea label="Description:" 
	id="ctrlDescription"
	name="Description"
	rows="4"
	cols="50"
	title="Description for the new class" 
	onchange="zenPage.updateState();"
/>

</vgroup>
</pane>
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("This wizard creates a new Zen application class."),"<br/>"
	Write $$$TextHTML("Fill in the form below and then press Finish to create a new class.")
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	#; plug in default values
	Do %page.%SetValueById("ctrlPackage",##class(%ZEN.Utils).GetDefaultPackage())
	Quit $$$OK
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	// give focus to name
	var ctrl = zenPage.getComponentById('ctrlClassName');
	if (ctrl) {
		ctrl.focus();
		ctrl.select();
	}
}

/// Validation handler for form built-into template.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	// test if class name is valid
	var pkgName = zenPage.getComponentById('ctrlPackage').getValue();
	var clsName = zenPage.getComponentById('ctrlClassName').getValue();

	var msg = this.IsValidClassName(pkgName + "." + clsName);

	if ('' != msg) {
		alert(msg);
		return false;
	}

	return true;
}

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.
Method %OnTemplateAction() As %Status
{
	Set tPackage = ..%GetValueByName("Package")
	Set tClassName = ..%GetValueByName("ClassName")
	Set tDescription = ..%GetValueByName("Description")
	Set tApplicationName = ..%GetValueByName("AppName")
	
	Set cls = tPackage_"."_tClassName
	
	#; create content of new class definition
	Do ..%SetClassName(cls)
	
	#; update defaults
	Do ##class(%ZEN.Utils).SetDefaultPackage(tPackage)
	Do ##class(%ZEN.Utils).SetDefaultApplication(cls)
	
	#; process list of pages!!!
	Set homePage = ""
	/*
	Set pages = $get(%request.Data("PAGES",1))
	For i = 1:1:$length(pages,$char(13,10)) {
		Set page = $piece(pages,$char(13,10),i)
		If (page '= "") {
			Set:homePage="" homePage = page _".cls"
			Do ##class(%ZEN.Utils).CreateZENPageClass(page,cls)
		}
	}
	*/
	
	#; process description
	If (tDescription = "") {
		Write "/// ",cls,!
	}
	Else {
		For i = 1:1:$length(tDescription,$char(13,10)) {
			Set line = $piece(tDescription,$char(13,10),i)
			Write "/// ",line,!
		}
	}
	Write "Class ",cls," Extends %ZEN.application"
	If ((..Language '= "cache") && (..Language '= "objectscript")) {
		If (..Language '= "" ) {
			Write " [Language = ",..Language,"]"
		}
	}
	Write !
	Write "{",!!
	
	#; APPLICATION NAME
	Write "/// "_$$$Text("This is the name of this application."),!
	Write "Parameter APPLICATIONNAME = """,tApplicationName,""";",!!
	
	#; HOME PAGE (use first page in list of pages!)
	Write "/// "_$$$Text("This is the URL of the main starting page of this application."),!
	Write "Parameter HOMEPAGE = """,homePage,""";",!!
	
	#; style sheet
	Write "/// "_$$$Text("This Style block contains application-wide CSS style definitions."),!
	Write "XData Style",!
	Write "{",!
	Write "<style type=""text/css"">",!
	Write "</style>",!
	Write "}",!
	
	#; end of class
	Write "}",!

	Quit $$$OK
}

/// Create the result set used by the Package dataCombo.
Method CreatePackageRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set tRS = ""
	Set tSC = $$$OK

	Set tRS = ##class(%ResultSet).%New()
	Set tRS.ClassName = "%ZEN.Utils"
	Set tRS.QueryName = "EnumeratePackages"
	Quit tRS
}

}
