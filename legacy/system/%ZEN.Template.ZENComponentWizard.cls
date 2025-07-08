/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template:<br>
/// Create a new Zen component class.
Class %ZEN.Template.ZENComponentWizard Extends %ZEN.Template.studioTemplate [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "Zen Component";

Parameter TEMPLATETITLE = "Zen Component Wizard";

Parameter TEMPLATEDESCRIPTION = "Create a new Zen component class.";

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
		title="Package name for the new component"
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
	title="Class name for the new component" 
	onchange="zenPage.updateState();"
/>

<radioSet label="Type:" 
	id="ctrlType"
	name="Type"
	displayList="component,composite,control,svgComponent"
	valueList="component,composite,control,svgComponent"
	labelClass="zenRequired"
	title="Type of component to create" 
	value="component"
/>

<text label="XML Namespace:" 
	id="ctrlXMLNS"
	name="XMLNS"
	title="XML namespace used for this component" 
/>

<textarea label="Description:" 
	id="ctrlDescription"
	name="Description"
	rows="4"
	cols="50"
	title="Description for the new component" 
	onchange="zenPage.updateState();"
/>
</vgroup>
</pane>
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("This wizard creates a new Zen component class."),"<br/>"
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
	
	Set tSuper = $Case(tType,"svgComponent":"%ZEN.SVGComponent",:"%ZEN.Component")
	
	Write "Class ",cls," Extends ",tSuper,".",tType
	If ((..Language '= "cache") && (..Language '= "objectscript")) {
		Write " [Language = ",..Language,"]"
	}
	Write !
	Write "{",!!
	
	#; XML NAMESPACE
	Write "/// "_$$$Text("This is the XML namespace for this component."),!
	Write "Parameter NAMESPACE = """,tXMLNS,""";",!!
	
	#; style sheet
	Write "/// "_$$$Text("This Style block contains component-specific CSS style definitions."),!
	If (tType="svgComponent") {
		Write "XData SVGStyle",!
	}
	Else {
		Write "XData Style",!
	}
	Write "{",!
	Write "<style type=""text/css"">",!
	Write "</style>",!
	Write "}",!!

	If (tType="composite") {
		Write "/// "_$$$Text("Contents of this composite component."),!
		Write "XData Contents"
		Write " [XMLNamespace=""http://www.intersystems.com/zen""]"
		Write !
		Write "{",!
		Write "<composite>",!
		Write "<!-- add definition of composite component here. -->",!
		Write "</composite>",!
		Write "}",!
	}

	If ((tType="control")||(tType="component")) {
		#; %DrawHTML method
		Write "/// "_$$$Text("The %DrawHTML method draws the initial HTML for this component."),!
		Write "Method %DrawHTML()",!
		Write "{",!
		If (..Language="mvbasic") {
			Write $C(9),"! TODO: implement this method",!
			Write $C(9),"Print 'New Component'",!
		}
		ElseIf (..Language="mvbasic") {
			Write $C(9),"' TODO: implement this method",!
			Write $C(9),"Print 'New Component'",!
		}
		Else {
			Write $C(9),"#; TODO: implement this method",!
			Write $C(9),"&html<New Component>",!
			
			If (tType = "control") {
				Write !
				Write $C(9),"#; hidden control to hold control value",!
				Write $C(9),"#; (TODO: remove if not needed)",!
				Write $C(9),"&html<<input type=""hidden"" id=""#(..%MakeId(""hidden""))#"" #(..%Name())# value=""#($ZCVT(..value,""O"",""HTML""))#"">>",!
			}
		}

		#; end of method
		Write "}",!
	}

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
