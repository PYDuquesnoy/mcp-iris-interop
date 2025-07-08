/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template: New ZEN Page.
Class %ZEN.Template.ZENPageWizard Extends %ZEN.Template.studioTemplate [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "Zen Page";

Parameter TEMPLATETITLE = "Zen Page Wizard";

Parameter TEMPLATEDESCRIPTION = "Create a new Zen page class.";

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

#svgFrame {
	border: 1px solid darkblue;
}
.radioSetCaption {
	font-size: 0.8em;
}

/* @doc="Style for disabled radio captions." */
.radioSetCaptionDisabled {
	font-size: 0.8em;
}

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
		size="60"
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
		size="60"
		OnCreateResultSet="CreateApplicationRS"
		onchange="zenPage.updateState();"
/>

<text label="Page Name:" 
	id="ctrlPageName"
	name="PageName"
	title="Logical name used for this page" 
/>
<text label="Page Title:" 
	id="ctrlTitle"
	name="PageTitle"
	title="Title for this page" 
/>
<text label="Domain:" 
	id="ctrlDomain"
	name="Domain"
	title="Localization domain used for captions on this page" 
/>
<textarea label="Description:" 
	id="ctrlDescription"
	name="Description"
	rows="4"
	cols="50"
	title="Description for the new class" 
	onchange="zenPage.updateState();"
/>
<radioSet id="ctrlType" label="Page type:" value="page" 
name="Type"
valueList="page,template" 
displayList="Page,Subclass of Template Page" 
onchange="zenPage.updateForm();"/>
<assistedText id="ctrlSuperClass" name="SuperClass" 
label="Super class:"
controlType="classname" 
controlWidth="450px" 
hidden="true"
listSize="10"
onchange="zenPage.updateState();"
 title="Template super class for the new page"
 />

</vgroup>
</tab>
<tab>
<vgroup labelPosition="left" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<html id="desc2" OnDrawContent="%GetDescHTML2"/>
<hgroup cellVAlign="top">
<spacer width="5"/>
<svgFrame id="svgFrame" layout="vertical"
	height="400" width="420">
<ownerDraw id="samplePages"
	height="400" width="420"
	onrender="zenPage.drawSamplePages(zenThis);"/>
</svgFrame>
<hidden id="ctrlLayoutClass" name="LayoutClass" value="%ZEN.Template.PageGenerator"/>
<hidden id="ctrlLayoutName" name="LayoutName"/>
</hgroup>
<spacer height="25"/>
</vgroup>
</tab>
</tabGroup>
</pane>
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("This wizard creates a new Zen page class."),"<br/>"
	Write $$$TextHTML("Fill in the form below and then press Next to choose from a list of sample page layouts.")
	Quit $$$OK
}

/// Provide contents of description component.
Method %GetDescHTML2(pSeed As %String) As %Status
{
	Write $$$TextHTML("Select an initial page layout and then press Finish."),"<br/>"
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	#; plug in default values
	Do %page.%SetValueById("ctrlPackage",##class(%ZEN.Utils).GetDefaultPackage())
	Do %page.%SetValueById("ctrlApplication",##class(%ZEN.Utils).GetDefaultApplication())
	Do %page.%SetValueById("ctrlDomain",##class(%ZEN.Utils).GetDefaultDomain())
	Quit $$$OK
}

/// Update state of controls on the wizard form.
ClientMethod updateForm() [ Language = javascript ]
{
	var type = zenPage.getComponentById('ctrlType').getValue();
	var sup = zenPage.getComponentById('ctrlSuperClass');
	if ('page' == type) {
		sup.setHidden(true);
	}
	else {
		sup.setHidden(false);
	}
	zenPage.updateState();
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
		var type = zenPage.getComponentById('ctrlType').getValue();
		return ('page' == type);
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

/// Owner-draw notification for owner1 component.
/// This method creates content using client-side logic.
ClientMethod drawSamplePages(svg) [ Language = javascript ]
{
	// clear contents of ownerDraw component
	svg.unrender();

	// Get new contents from the server
	this.GetSVGContents(svg.index);
}

/// Execute server-logic to get SVG contents for Owner-draw component.
ClassMethod GetSVGContents(pIndex As %Integer) [ ZenMethod ]
{
	#; get the svg component
	&js<
		var svg = zenPage.getComponent(#(pIndex)#);
		var frame = zenPage.getComponentById('svgFrame');
		var theDocument = svg.document;
	>

	#; background
	&js< 
		var bg = theDocument.createElementNS(SVGNS,'rect');
		bg.setAttribute('x',0);
		bg.setAttribute('y',0);
		bg.setAttribute('width','100%');
		bg.setAttribute('height','100%');
		bg.setAttribute('fill','#E0E0FF');
		svg.svgGroup.appendChild(bg);
	>

	#; find list of sample pages; draw svg for each;
	Set tSC = ##class(%ZEN.Template.ZENPageList).%GetPageGenerators(.tPages)
	If $$$ISOK(tSC) {
		Set tKey = $O(tPages(""))
		Set x = 10, y = 20, n = 0, hgt = 125
		While (tKey '= "") {
			Set tPage = tPages(tKey)
			Set tPageClass = tPage
			Set tCaption = tKey
			#; execute JS to create page icons
			&js<
				var text = theDocument.createElementNS(SVGNS,'text');
				text.setAttribute('x',#(x+75)#);
				text.setAttribute('y',#(y-4)#);
				text.setAttribute('style','fill: black; stroke: none; font-size: 10pt; font-weight: bold;');
				text.setAttribute('text-anchor','middle');
		
				var textNode = theDocument.createTextNode('#(tCaption)#');
				text.appendChild(textNode);
				svg.svgGroup.appendChild(text);

				var theGroup = theDocument.createElementNS(SVGNS,'g');
				theGroup.setAttribute('transform','translate(#(x)#,#(y)#)');
				// theGroup.setAttribute('opacity','0.5');
				svg.svgGroup.appendChild(theGroup);

				// click handler
				theGroup.addEventListener('click',new Function('zenPage.selectPageLayout("#(tPageClass)#","#(tCaption)#");'),false);
			>
			Set tSC = ##class(%ZEN.Template.ZENPageList).%GetPageSVG(tPage)
			If (n # 2) {
				Set x = 10
				Set y = y + 125
				Set hgt = hgt + 125
			}
			Else {
				Set x = x + 200
			}
			Set n = n + 1
			Set tKey = $O(tPages(tKey))
		}

		&js<
			frame.setProperty('height', #(hgt)#);
			svg.setSize(420, #(hgt)#);
			zenPage.selectPageLayout('%ZEN.Template.PageGenerator','Default');
		>
	}
	Quit
}

/// User selection of a page layout icon
ClientMethod selectPageLayout(cls, name) [ Language = javascript ]
{
	var frame = zenPage.getComponentById('svgFrame');
	var theDocument = frame.getSVGDocument();
	var layoutClass = zenPage.getComponentById('ctrlLayoutClass');
	var layoutName = zenPage.getComponentById('ctrlLayoutName');

	// unhighlight old icon
	if ('' != layoutClass.getValue()) {
		var rect = theDocument.getElementById('icon_' + layoutClass.getValue());
		if (rect) {
			rect.setAttribute('fill','white');
			rect.setAttribute('stroke','blue');
			rect.setAttribute('stroke-width','1');
		}
	}

	layoutClass.setValue(cls);
	layoutName.setValue(name);

	// highlight new icon
	if ('' != layoutClass.getValue()) {
		var rect = theDocument.getElementById('icon_' + layoutClass.getValue());
		if (rect) {
			rect.setAttribute('fill','yellow');
			rect.setAttribute('stroke','blue');
			rect.setAttribute('stroke-width','2');
		}
	}
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
		return false;
	}

	return true;
}

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.
Method %OnTemplateAction() As %Status
{
	#dim tStream As %Library.Stream

	Set tPackage = ..%GetValueByName("Package")
	Set tClassName = ..%GetValueByName("ClassName")
	Set tApplication = ..%GetValueByName("Application")
	Set tDomain = ..%GetValueByName("Domain")
	Set tPageName = ..%GetValueByName("PageName")
	Set tPageTitle = ..%GetValueByName("PageTitle")
	Set tDescription = ..%GetValueByName("Description")

	Set tType = ..%GetValueByName("Type")
	If (tType = "template") {
		Set tSuperClass = ..%GetValueByName("SuperClass")
		Do ..GetPanes(tSuperClass,.tPanes)
	}
	Else {
		Set tSuperClass = "%ZEN.Component.page"
	}

	Set tLayoutClass = ..%GetValueByName("LayoutClass")
	Set tLayoutName = ..%GetValueByName("LayoutName")
	
	Set cls = tPackage_"."_tClassName

	#; create info object
	Set tInfo = ##class(%ZEN.Template.PageGeneratorInfo).%New()
	Set tInfo.ClassName = cls
	Set tInfo.Description = tDescription
	Set tInfo.PageName = tPageName
	Set tInfo.PageTitle = tPageTitle
	
	#; create content of new class definition
	Do ..%SetClassName(cls)
	
	#; update defaults
	Do ##class(%ZEN.Utils).SetDefaultPackage(tPackage)
	Do ##class(%ZEN.Utils).SetDefaultApplication(tApplication)
	Do ##class(%ZEN.Utils).SetDefaultDomain(tDomain)
	
	#; process description
	If (tDescription = "") {
		Write:tLayoutName'="" "/// Created using the page template: ",tLayoutName,!
	}
	Else {
		For i = 1:1:$length(tDescription,$char(13,10)) {
			Set line = $piece(tDescription,$char(13,10),i)
			Write "/// ",line,!
		}
	}
	Write "Class ",cls," Extends ",tSuperClass
	If ((..Language '= "cache") && (..Language '= "objectscript")) {
		Write " [Language = ",..Language,"]"
	}
	Write !
	Write "{",!!
	
	#; APPLICATION
	Write "/// "_$$$Text("Class name of application this page belongs to."),!
	Write "Parameter APPLICATION = """,tApplication,""";",!!
	
	#; PAGENAME
	Write "/// "_$$$Text("Displayed name of this page."),!
	Write "Parameter PAGENAME = """,tPageName,""";",!!
	
	#; DOMAIN
	Write "/// "_$$$Text("Domain used for localization."),!
	Write "Parameter DOMAIN = """,tDomain,""";",!!
	
	#; Get style block from Generator
	Write "/// "_$$$Text("This Style block contains page-specific CSS style definitions."),!
	Write "XData Style",!
	Write "{",!
	Do ##class(%ZEN.Template.ZENPageList).%WriteXDATAStyle(tLayoutClass, tInfo)
	Write "}",!

	If (tType = "template") {
		Set tPane = $O(tPanes(""))
		While (tPane '= "") {
			Write !

			#; Write contents block for each pane
			Write "/// "_$$$Text("This XML block defines the contents of this pane."),!
			Write "XData ",tPane
			Write " [XMLNamespace=""http://www.intersystems.com/zen""]"
			Write !
			Write "{",!
			Write "<pane xmlns=""http://www.intersystems.com/zen"">",!
			Write "</pane>",!
			Write "}",!
			Set tPane = $O(tPanes(tPane))
		}
	}
	Else {
		#; Get contents block from Generator
		Write "/// "_$$$Text("This XML block defines the contents of this page."),!
		Write "XData Contents"
		Write " [XMLNamespace=""http://www.intersystems.com/zen""]"
		Write !
		Write "{",!
		Do ##class(%ZEN.Template.ZENPageList).%WriteXDATAContents(tLayoutClass, tInfo)
		Write "}",!
	}	

	#; Get methods from Generator
	If (..Language = "cache") {
		#; for now, only write out method stubs for ObjectScript
		Do ##class(%ZEN.Template.ZENPageList).%WriteMethods(tLayoutClass, tInfo)
	}

	#; end of class
	Write "}",!

	Quit $$$OK
}

/// Try to find the list of panes in the given page class.
ClassMethod GetPanes(pClass As %String, Output pPanes) [ Internal ]
{
	Set $ZT="Trap"
	New %page,%application
	
	#; create the DOM for the class and find all of its panes
	Set page = $zobjclassmethod(pClass,"%CreatePage")

	Set idx = $O(page.%Components(""))
	While (idx'="") {
		Set tComp = page.%Components(idx)
		If ($IsObject(tComp)&&tComp.%IsA("%ZEN.Component.pane")) {
			Set tName = tComp.paneName
			Set:tName'="" pPanes(tName)=""
		}
		Set idx = $O(page.%Components(idx))
	}

Trap
	Set $ZT=""
	Quit
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

/// Create the result set used by the SuperClass dataCombo.
Method CreateSuperClassRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set tRS = ""
	Set tSC = $$$OK

	Set tRS = ##class(%ResultSet).%New()
	Set tRS.ClassName = "%Dictionary.ClassDefinition"
	Set tRS.QueryName = "SubclassOf"
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
