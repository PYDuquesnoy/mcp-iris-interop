/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template:<br>
/// Create a new DeepSee KPI class.
Class %DeepSee.Template.DeepSeeKPIWizard Extends %ZEN.Template.studioTemplate [ System = 4 ]
{

Parameter TEMPLATENAME = "DeepSee KPI";

Parameter TEMPLATETITLE = "DeepSee KPI Wizard";

Parameter TEMPLATEDESCRIPTION = "Create a new DeepSee KPI class.";

Parameter TEMPLATETYPE = "cls";

/// What type of template.
Parameter TEMPLATEMODE = "new";

/// Domain used for localization.
Parameter DOMAIN = "%DeepSee";

Parameter HELPID = "D2MODADV_ch_kpi";

Property ResourcePage As %String [ InitialExpression = {..Link("_DeepSee.UI.Dialog.GetResource.cls?CSPSHARE=1")} ];

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
		title="Package name for the new KPI class"
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
	title="Class name for the new KPI class" 
	onchange="zenPage.updateState();"
/>

<text label="KPI Caption:" 
	id="ctrlKPICaption"
	name="KPICaption"
	size="40"
	title="Caption for the new KPI" 
	onchange="zenPage.updateState();"
/>

<text label="KPI Name:" 
	id="ctrlKPIName"
	name="KPIName"
	size="40"
	title="Logical name for the new KPI" 
	hint="Such as, MyFolder/MyKPI"
	hintClass="hintText"
	onchange="zenPage.updateState();"
/>

<textarea label="Description:" 
	id="ctrlDescription"
	name="Description"
	rows="3"
	cols="50"
	title="Description for the new class" 
	onchange="zenPage.updateState();"
/>
<text label="Domain:"
   id="ctrlDomain"
   name="Domain"
   size="50"
   title="Localization domain to which this KPI belongs"
	onchange="zenPage.updateState();"
/>
<hgroup cellVAlign="bottom" label="Resource:" labelPosition="left">
<text 
   id="ctrlResource"
   name="Resource"
   size="50"
   title="Security resource requirement for the new KPI"
	onchange="zenPage.updateState();"
/>
<image id="btndetailCubeResource" src="deepsee/zoom_16.png" onclick="zenPage.editItem('KPIResource');"/>
</hgroup>

<radioSet label="Source Type:" 
	id="ctrlSourceType"
	name="SourceType" 
	hint="Specifies where the data for this KPI comes from"
	hintClass="hintText"
	value="mdx"
	valueList="mdx,sql,manual"/>

<hgroup cellVAlign="top" labelPosition="top" hint="One entry per line" hintClass="hintText">
<textarea label="Properties"
	id="ctrlProperties"
	rows="6"
	name="Properties"/>

<spacer width="5"/>
<textarea label="Filters"
	id="ctrlFilters"
	rows="6"
	name="Filters"/>

<spacer width="5"/>
<textarea label="Actions"
	id="ctrlActions"
	rows="6"
	name="Actions"/>
</hgroup>
</vgroup>
</pane>
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("This wizard creates a new DeepSee KPI class."),"<br/>"
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

ClientMethod editItem(what) [ Language = javascript ]
{
	var element = zen("ctrlPackage").getValue();
	var classname = zen("ctrlClassName").getValue();
	if (classname != "") element = element + "." + classname;
	var uiclass = this.ResourcePage;
	var parms = {
			CUBE:"",
			ELEMENT:element,
			DATASOURCE:zen("ctrlClassName").getValue(),
			SELECTEDCLASS:zen("ctrlClassName").getValue(),
			VALUE:zen('ctrlResource').getValue(),
			WHAT:what
			};
	zenLaunchPopupWindow(uiclass,what,'status,scrollbars,resizable=yes,width=640,height=680',parms);
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	if (popupName == "KPIResource") {
		zen('ctrlResource').setValue(value);	
	}
}

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.
Method %OnTemplateAction() As %Status
{
	Set tPackage = ..%GetValueByName("Package")
	Set tClassName = ..%GetValueByName("ClassName")
	Set tDescription = ..%GetValueByName("Description")
	Set tKPIName = ..%GetValueByName("KPIName")
	Set tKPICaption = ..%GetValueByName("KPICaption")
	Set tDomain = ..%GetValueByName("Domain")
	Set tResource = ..%GetValueByName("Resource")
	Set tSourceType = ..%GetValueByName("SourceType")
	Set tProperties = ..%GetValueByName("Properties")
	Set tFilters = ..%GetValueByName("Filters")
	Set tActions = ..%GetValueByName("Actions")
	Set tQuery = ""
	
	Set cls = tPackage_"."_tClassName
	
	#; create content of new class definition
	Do ..%SetClassName(cls)
	
	#; update defaults
	Do ##class(%ZEN.Utils).SetDefaultPackage(tPackage)
	Do ##class(%ZEN.Utils).SetDefaultApplication(cls)
	
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
	Write "Class ",cls," Extends %DeepSee.KPI"
	If ((..Language '= "cache") && (..Language '= "objectscript")) {
		Write " [Language = ",..Language,"]"
	}
	Write !
	Write "{",!!
	Write "Parameter DOMAIN = """,tDomain,""";",!!
	Write "Parameter RESOURCE = """,tResource,""";",!!
	
	#; KPI definitions
	Write "/// "_$$$Text("This XData definition defines the KPI."),!
	Write "XData KPI [ XMLNamespace = ""http://www.intersystems.com/deepsee/kpi"" ]",!
	Write "{",!
	Write "<kpi xmlns=""http://www.intersystems.com/deepsee/kpi""",!
 	Write " name="""_tKPIName_""" sourceType="""_tSourceType_"""",!
 	Write " caption="""_tKPICaption_"""",!
	If (tSourceType="sql") {
	 	Write " sql="""_tQuery_"""",!
	}
	ElseIf (tSourceType="sql") {
	 	Write " mdx="""_tQuery_"""",!
	}
	Write ">",!

	#; properties
	For i = 1:1:$length(tProperties,$char(13,10)) {
		Set tProp = $piece(tProperties,$char(13,10),i)
		If (tProp'="") {
			&html<<property name="#(tProp)#" displayName="#(tProp)#" columnNo="#(i)#"/>>
		}
	}

	#; filters
	For i = 1:1:$length(tFilters,$char(13,10)) {
		Set tFilter = $piece(tFilters,$char(13,10),i)
		If (tFilter'="") {
			&html<<filter name="#(tFilter)#" displayName="#(tFilter)#" filterProperty=""/>>
		}
	}

	#; actions
	For i = 1:1:$length(tActions,$char(13,10)) {
		Set tAction = $piece(tActions,$char(13,10),i)
		If (tAction'="") {
			&html<<action name="#(tAction)#" displayName="#(tAction)#"/>>
		}
	}

	&html<</kpi>>

	Write "}",!
	
	#; methods (based on source type)
	Write "/// Notification that this KPI is being executed.",!
	Write "/// This is a good place to override properties, such as range and threshold.",!
	Write "Method %OnLoadKPI() As %Status",!
	Write "{",!
	Write $C(9),"Quit $$$OK",!
	Write "}",!
	Write !

	If (tSourceType="sql") {
		Write "/// Return an SQL statement to execute.",!
		Write "Method %OnGetSQL(ByRef pSQL As %String) As %Status",!
		Write "{",!
		Write $C(9),"Quit $$$OK",!
		Write "}",!
		Write !
	}

	If (tSourceType="mdx") {
		Write "/// Return an MDX statement to execute.",!
		Write "Method %OnGetMDX(ByRef pMDX As %String) As %Status",!
		Write "{",!
		Write $C(9),"Quit $$$OK",!
		Write "}",!
		Write !
	}

	Write "/// This callback is invoked from a dashboard when an action defined by this dashboard is invoked.",!
	Write "ClassMethod %OnDashboardAction(pAction As %String, pContext As %ZEN.proxyObject) As %Status",!
	Write "{",!
	Write $C(9),"// pAction is the name of the action (as defined in the XML list).",!
	Write $C(9),"// pContext contains information from the client",!
	Write $C(9),"// and can be used to return information.",!
	Write $C(9),"Quit $$$OK",!
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
