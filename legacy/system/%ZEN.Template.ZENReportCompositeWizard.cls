/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template:<br>
/// Create a new Zen Report Composite class.
Class %ZEN.Template.ZENReportCompositeWizard Extends %ZEN.Template.studioTemplate [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "Zen Report Composite";

Parameter TEMPLATETITLE = "Zen Report Composite Wizard";

Parameter TEMPLATEDESCRIPTION = "Create a new Zen report composite class.";

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
XData templateBody
{
<pane id="body">

<vgroup labelPosition="left" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<html id="desc" OnDrawContent="%GetDescHTML"/>
<dataCombo label="Package Name:"
		id="ctrlPackage"
		name="Package"
		required="true"
		labelClass="zenRequired"
		title="Package name for the new report composite"
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
	title="Class name for the new report composite" 
	onchange="zenPage.updateState();"
/>

<text label="XML Namespace:" 
	id="ctrlXMLNS"
	name="XMLNS"
	size="65"
	title="XML namespace used for this report composite" 
/>

<textarea label="Description:" 
	id="ctrlDescription"
	name="Description"
	rows="4"
	cols="50"
	title="Description for the new report composite" 
	onchange="zenPage.updateState();"
/>
</vgroup>
</pane>
}

/// Provide contents of description composite.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("This wizard creates a new Zen report composite class."),"<br/>"
	Write $$$TextHTML("Fill in the form below and then press Finish to create a new class.")
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	#; plug in default values
	Do %page.%SetValueById("ctrlPackage",##class(%ZEN.Utils).GetDefaultPackage())
	Do %page.%SetValueById("ctrlXMLNS",##class(%ZEN.Utils).GetDefault("XMLNamespace"))
	
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
	Set tXMLNS = ..%GetValueByName("XMLNS")
	Set tType = ..%GetValueByName("Type")
	
	Set cls = tPackage_"."_tClassName
	
	#; create content of new class definition
	Do ..%SetClassName(cls)
	
	#; update defaults
	Do ##class(%ZEN.Utils).SetDefaultPackage(tPackage)
	Do ##class(%ZEN.Utils).SetDefault("XMLNamespace",tXMLNS)
	
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
	
	Set tSuper = "%ZEN.Report.Display.composite"
	
	Write "Class ",cls," Extends ",tSuper
	If ((..Language '= "cache") && (..Language '= "objectscript")) {
		Write " [Language = ",..Language,"]"
	}
	Write !
	Write "{",!!
	
	#; XML NAMESPACE
	Write "/// "_$$$Text("This is the XML namespace for this report composite."),!
	Write "Parameter NAMESPACE = """,tXMLNS,""";",!!
	
	Write "/// "_$$$Text("Contents of this composite."),!
	Write "XData Display"
	Write " [XMLNamespace=""http://www.intersystems.com/zen/report/display""]"
	Write !
	Write "{",!
	Write "<composite xmlns=""http://www.intersystems.com/zen/report/display"">",!
	Write "<!-- add definition of composite here. -->",!
	Write "</composite>",!
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

/// Create the result set used by the Application dataCombo.
Method CreateApplicationRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set tRS = ""
	Set tSC = $$$OK

	Set tRS = ##class(%ResultSet).%New()
	Set tRS.ClassName = "%ZEN.Utils"
	Set tRS.QueryName = "EnumerateApplications"
	Quit tRS
}

}
