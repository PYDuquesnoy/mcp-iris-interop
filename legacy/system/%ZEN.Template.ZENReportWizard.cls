/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template: New ZEN Report.
Class %ZEN.Template.ZENReportWizard Extends %ZEN.Template.studioTemplate [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "Zen Report";

Parameter TEMPLATETITLE = "Zen Report Wizard";

Parameter TEMPLATEDESCRIPTION = "Create a new Zen Report class.";

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

<tabGroup id="tabGroup">
<tab>
<vgroup labelPosition="left" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<html id="desc" OnDrawContent="%GetDescHTML"/>
<dataCombo label="Package Name:"
		id="ctrlPackage"
		name="Package"
		required="true"
		labelClass="zenRequired"
		title="Package name for the new page"
		editable="true"
		unrestricted="true"
		searchKeyLen="0"
		maxRows="500"
		dropdownWidth="20.0em"
		size="40"
		OnCreateResultSet="CreatePackageRS"
		onchange="zenPage.updateState();"
/>

<text label="Class Name:" 
	id="ctrlClassName"
	name="ClassName"
	size="40"
	required="true"
	labelClass="zenRequired"
	title="Class name for the new page" 
	onchange="zenPage.updateState();"
/>

<dataCombo label="Application:"
		id="ctrlApplication"
		name="Application"
		title="Class name of the application this page belongs to" 
		editable="true"
		unrestricted="true"
		searchKeyLen="0"
		multiColumn="false"
		displayColumns="1"
		valueColumn="1"
		choiceColumn="1"
		maxRows="500"
		size="40"
		dropdownWidth="20.0em"
		OnCreateResultSet="CreateApplicationRS"
		onchange="zenPage.updateState();"
/>

<text label="Report Name:" 
	id="ctrlReportName"
	name="ReportName"
	title="Name of this report" 
	hint="Space is not allowed therefore all spaces will be removed." hintClass="hintText"
	onchange="zenPage.reportNameChanged(zenThis);"
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
</tab>
<tab>
<vgroup labelPosition="left" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<html id="desc2" OnDrawContent="%GetDescHTML2"/>
<textarea label="SQL:" id="ctrlSQL" name="SQL" rows="8" cols="60" />
<!--
<button caption="Query Builder..." onclick="zenPage.launchQueryBuilder();"/>
-->
</vgroup>
</tab>
</tabGroup>
</pane>
}

/// Validate name and strip space if entered.
ClientMethod reportNameChanged(reportNameCtl As %String) [ Language = javascript ]
{
	var string = reportNameCtl.getValue();
	if (string.indexOf(' ') > -1) {
		var newstring = string.replace(/ /g,'');
		reportNameCtl.setValue(newstring);
	}
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("This wizard creates a new Zen Report class."),"<br/>"
	Write $$$TextHTML("Fill in the form below and then press Finish.")
	Quit $$$OK
}

/// Provide contents of description component.
Method %GetDescHTML2(pSeed As %String) As %Status
{
	Write $$$TextHTML("If you wish, you can enter the main SQL statement for the report in the area below."),"<br/>"
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	#; plug in default values
	Do %page.%SetValueById("ctrlPackage",##class(%ZEN.Utils).GetDefaultPackage())
	Do %page.%SetValueById("ctrlApplication",##class(%ZEN.Utils).GetDefaultApplication())
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

ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return true;
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
ClientMethod canGoNext() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	switch(tabNo) {
	case 1:
		return true;
	}
	return false;
}

/// Go to the next page of the template (if there is one).<br>
ClientMethod nextPage() [ Language = javascript ]
{
	if (!this.validateClassName()) {
		return;
	}
	var tabGroup = zenPage.getComponentById('tabGroup');
	tabGroup.showNextTab();
	this.updateState();
}

/// Go to the previous page of the template (if there is one).<br>
ClientMethod previousPage() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	tabGroup.showPreviousTab();
	this.updateState();
}

/// Return true if this template can go to the previous page (i.e., enable
/// the Back button).<br>
ClientMethod canGoBack() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	return (tabGroup.getCurrTabNo() > 1);
}

/// Validation handler for form built-into template.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	return this.validateClassName();
}

ClientMethod validateClassName() [ Language = javascript ]
{
	// test if class name is valid
	var pkgName = zenPage.getComponentById('ctrlPackage').getValue();
	var clsName = zenPage.getComponentById('ctrlClassName').getValue();

	var msg = this.IsValidClassName(pkgName + "." + clsName);

	if ('' != msg) {
		alert(msg);
		zen("ctrlClassName").focus();
		return false;
	}

	return true;
}

/// Launch the query builder dialog.
ClientMethod launchQueryBuilder() [ Language = javascript ]
{
	var parms = new Object();
	parms.ColumnType = 2;
	parms.$NAMESPACE = zenPage.Namespace;
	zenPage.launchPopupWindow(zenLink('%CSP.UI.SQL.QueryBuilderWindow.cls'),'QueryBuilder','resizable,width=500,height=500',parms,this);
}

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.
Method %OnTemplateAction() As %Status
{
	Set tPackage = ..%GetValueByName("Package")
	Set tClassName = ..%GetValueByName("ClassName")
	Set tApplication = ..%GetValueByName("Application")
	Set tDescription = ..%GetValueByName("Description")
	Set tReportName = ..%GetValueByName("ReportName")
	Set tSQL = ..%GetValueByName("SQL")

	Set cls = tPackage_"."_tClassName

	#; create content of new class definition
	Do ..%SetClassName(cls)

	#; update defaults
	Do ##class(%ZEN.Utils).SetDefaultPackage(tPackage)

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

	Write "Class ",cls," Extends %ZEN.Report.reportPage"
	If ((..Language '= "cache") && (..Language '= "objectscript")) {
		Write " [Language = ",..Language,"]"
	}
	Write !
	Write "{",!!
	
	#; APPLICATION
	Write "/// "_$$$Text("Class name of application this report belongs to."),!
	Write "Parameter APPLICATION = """,tApplication,""";",!!

	#; DEFAULT MODE
	
	Write "/// Specifies the default display mode used for this report if",!
	Write "/// the URL parameter, <var>$MODE</var>, is not present.",!
	Write "Parameter DEFAULTMODE As STRING [ Constraint = "",html,tohtml,toxslfo,pdf,xml,xslfo,excel,toexcel,ps,pdfprint,xlsx,tiff,displayxlsx,fo2pdf,foandpdf"", Flags = ENUM ] = ""xml"";",!,!

	
	#; REPORT XML NAMESPACE
	Write "/// "_$$$Text("This is the optional XML namespace used for the report."),!
	Write "Parameter REPORTXMLNAMESPACE = """";",!!

	#; report definition
	Write "/// "_$$$Text("This XML defines the logical contents of this report."),!
	Write "XData ReportDefinition"
	Write " [XMLNamespace=""http://www.intersystems.com/zen/report/definition""]"
	Write !
	Write "{",!
	Write "<report xmlns=""http://www.intersystems.com/zen/report/definition""",!
	Write " name="""_tReportName_""""
	Write " sql="""_tSQL_""""
	Write ">",!
	Write "<!-- add definition of the report here. -->",!
	Write "</report>",!
	Write "}",!
	
	#; report display
	Write "/// "_$$$Text("This XML defines the display for this report."),!
	Write "/// "_$$$Text("This is used to generate the XSLT stylesheets for both HTML and XSL-FO."),!
	Write "XData ReportDisplay"
	Write " [XMLNamespace=""http://www.intersystems.com/zen/report/display""]"
	Write !
	Write "{",!
	Write "<report xmlns=""http://www.intersystems.com/zen/report/display""",!
	Write " name="""_tReportName_""""
	Write ">",!
	Write "<!-- Optional Init element inserts custom XSLT instructions at the top level of the generated XSLT stylesheet. -->",!
    Write "<init ></init>",!
    Write "<!-- Optional Document element specifies page layout and style characteristics. -->",!
    Write "<document width=""8.5in"" height=""11in"" marginLeft=""1.25in"" marginRight=""1.25in"" marginTop=""1.0in"" marginBottom=""1.0in"" ></document>",!
    Write "<!-- Optional Pageheader element. -->",!
    Write "<pageheader ></pageheader>",!
   	Write "<!-- Optional Pagefooter element. Does not apply in HTML output. -->",!
    Write "<pagefooter ></pagefooter>",!
   	Write "<!-- Required Body element. -->",!
    Write "<body>",!
    Write "<!-- add display definition of the report here. -->",!
    Write "</body>",!
	Write "</report>",!
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
