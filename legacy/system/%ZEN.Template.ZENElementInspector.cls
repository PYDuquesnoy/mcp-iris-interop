/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template:<br>
/// Insert a new ZEN Element within an XData definition.
Class %ZEN.Template.ZENElementInspector Extends %ZEN.Template.studioTemplate [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "Zen Element Wizard";

Parameter TEMPLATETITLE = "Zen Element Wizard";

Parameter TEMPLATEDESCRIPTION = "Inserts a Zen XML element within a Contents document.";

Parameter TEMPLATETYPE = "cls";

/// What type of template.
Parameter TEMPLATEMODE = "template";

/// Domain used for localization.
Parameter DOMAIN = "%ZEN";

/// Localized label for edit button.
Property editLabel As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Edit...")} ];

/// Portion of selected text *before* the target element.
Property preText As %ZEN.Datatype.string;

/// Portion of selected text *after* the target element.
Property postText As %ZEN.Datatype.string;

/// Name of the target element from selectedText.
Property elName As %ZEN.Datatype.string;

/// Array of attributes and values from the target element. 
Property attrs As array Of %ZEN.Datatype.string;

/// Class name of selected element.
Property currElementClass As %ZEN.Datatype.string;

/// Name of selected element.
Property currElementName As %ZEN.Datatype.string;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

body {
	overflow: hidden;
}

.ClassHelp {
	margin-top: 5px;
	margin-bottom: 5px;
	font-weight: bold;
}

.ClassDescription {
	line-height: 1.2;
}

.eiEditButton, .eiEditButtonHover {
	width: 100%;
	color: black;
	text-align:center;
	border:1px solid black;
	font-size: 0.8em;
}

.eiEditButton {
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

.eiEditButtonHover {
	background: yellow;
}

/* Column labels for dynaGrid. */
table.dynaGrid th.dynaGridColumn,
table.dynaGrid th.dynaGridRow,
table.dynaGrid th.dynaGridLabel {
	color: black;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}


</style>
}

/// This XML block defines the contents of the body pane of this Studio Template.
XData templateBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="body">
<tabGroup id="tabGroup" onshowTab="zenPage.tabChange(zenThis);">
<tab>
<vgroup labelPosition="left" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<html id="desc" OnDrawContent="%GetDescHTML"/>
<dataCombo label="Element:"
		id="ctrlElement"
		name="Element"
		title="XML element name of the component to insert" 
		editable="false"
		unrestricted="false"
		searchKeyLen="0"
		multiColumn="true"
		displayColumns="2,1"
		columnHeaders="Component,Class"
		valueColumn="1"
		choiceColumn="2"
		required="true"
		labelClass="zenRequired"
		maxRows="500"
		dropdownWidth="40.0em"
		OnCreateResultSet="CreateElementRS"
		onchange="zenPage.elementChange(zenThis);"
/>
<html id="helpElement" OnDrawContent="%GetElementHelpHTML" onrefresh="zenPage.htmlRefreshHandler();"/>
</vgroup>

</tab>
<tab>
<hidden id="ctrlProperties" name="Properties" />
<hidden id="ctrlPreText" name="PreText" />
<hidden id="ctrlPostText" name="PostText" />
<dynaGrid id="gridProperties"
	gridLabel="Property"
	ondrawcell="return zenPage.drawPropCell(zenThis,data);"
	rowLabelWidth="250"
	 scrollIntoView="true"
	onsubmit="zenPage.computeGridValue(zenThis);"
>
<gridColumn width="200" />
<gridColumn width="50" />
</dynaGrid>
<spacer height="20"/>
</tab>
</tabGroup>

</pane>
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("This wizard inserts a Zen element within an Xdata block of a Zen page class.")
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	#; parse selected text into element and attributes
	
	Set pre = ""
	Set post = ""
	Set tag = ""

	#; not supported
	Set ..SelectedText = ""

	If (..SelectedText '= "") {
		Set tokens = ##class(%CSP.TokenStream).%New()
		Do tokens.OpenFromString(..SelectedText)
		While (tokens.NextToken()) {
			If (tag = "") {
				If tokens.IsTag() {
					Set tag = tokens.Tag
					Do tokens.GetAttrs(.ats)
				}
				Else {
					Set pre = pre _ tokens.Text
				}
			}
			Else {
				Set t = tokens.Text
				#; if tokens has extra CR/LF, take it off
				If ($E(t,$L(t)-1,$L(t)) = $C(13,10)) {
					Set t = $E(t,1,$L(t)-2)
				}
				Set post = post _ t
			}
		}
		#; put CR/LF back if needed!
		If ($E(..SelectedText,$L(..SelectedText)-1,$L(..SelectedText)) = $C(13,10)) {
			Set post = post _ $C(13,10)
		}
	}
	
	#; build set of attrs & values
	Set key = $order(ats(""))
	While (key '= "") {
		/*
		Merge attrs(key) = ats(key)
		If ($G(ats(key,"type")) = "boolean") {
			Set:('$data(ats(key,"value"))) ats(key,"value") = "1"
		}
		*/
		Do ..attrs.SetAt($G(ats(key,"value")),key)
		Set key = $order(ats(key))
	}

	Set ..preText = pre
	Set ..postText = post
	Set ..elName = tag

	#; initial value of combo box
	#; convert elName to ClassName !!!
	
	#; !!!
	If (..elName '= "") {
		Set cb = ..%GetComponentById("ctrlElement")
		Set cb.text = ..elName
		Set cb.value = "%ZEN.Component."_..elName
		// Do ..%SetValueById("ctrlElement","%ZEN.Component."_..elName)

		#; start on page 2 of tab
		Set tg = ..%GetComponentById("tabGroup")
		Set tg.currTab = 2
	}

	#; place values into hidden controls for later submit
	Do ..%SetValueById("ctrlPreText",pre)
	Do ..%SetValueById("ctrlPostText",post)

	Quit $$$OK
}

/// Notification that the element combo has changed.
ClientMethod elementChange(cb) [ Language = javascript ]
{
	this.currElementClass = cb.getValue();
	this.currElementName = cb.getOptionText(cb.selectedIndex);

	// update help
	var html = zenPage.getComponentById('helpElement');
	html.setProperty('seed',cb.getValue());
	html.refreshContents();
	this.updateState();
}

/// htmlRefreshHandler
/// This is called when the HTML help component is refreshed from the server.
ClientMethod htmlRefreshHandler() [ Language = javascript ]
{
	// clean up links to documatic
	var links = self.document.links;
	for (var n = 0; n < links.length; n++) {
		var href = links[n].href;
		// Note: IE7 returns links with %25 in them!
		if ((-1 != href.indexOf('%CSP.Documatic'))||(-1 != href.indexOf('%25CSP.Documatic'))) {
			// change url & target of link
			var h = href.split('?');
			h[0] = '/csp/documatic/%25CSP.Documatic.cls';
			links[n].href = h.join('?');
			links[n].target = 'Documatic';
		}
	}
}

/// Provide contents of element help component.
Method %GetElementHelpHTML(pSeed As %String = "") As %Status
{
	If (pSeed = "") {
		Write "<i>",$$$TextHTML("No element selected.","%ZEN"),"</i>"
	}
	Else {
		&html<<div class="ClassHelp">#(pSeed)#</div>
		<div class="ClassDescription">>
		Do ##class(%ZEN.Utils).%DrawClassDescription(pSeed)
		&html<</div>>
	}

	Quit $$$OK
}

/// Notification that a new tab was selected.
ClientMethod tabChange(tabGroup) [ Language = javascript ]
{
	var tabNo = tabGroup.getCurrTabNo();

	switch(tabNo) {
	case 2:
		// update property grid
		var cls = this.currElementClass;
		var grid = zenPage.getComponentById('gridProperties');
		var dataSet = grid.getDataSet();
		
		// get set of properties for this element
		var list = this.GetElementInfo(cls);
		var props = list.split(',');
	
		dataSet.redim(2, props.length, 2);
		for (var n = 0; n < props.length; n++) {
			dataSet.setLabel(props[n], n, 1);

			// get value of attribute
			var value = zenGet(this.attrs[props[n]]);
			dataSet.setData(value,n,0);
		}
		grid.render();
		break;
	}

	// adjust layout
	this.adjustSize();
}

/// called when cell is about to be drawn in dynaGrid
ClientMethod drawPropCell(grid, data) [ Language = javascript ]
{
	// if we need to know the cell # being drawn, we
	// can get it vis grid.row and grid.column.
	if (grid.column == 2) {
		// show edit button
		return '<div class="eiEditButton" onmouseover="this.className=\'eiEditButtonHover\';" onmouseout="this.className=\'eiEditButton\';" onclick="zenPage.getComponent('+this.index+').showValueEditor('+(grid.row-1)+');">'+this.editLabel+'</div>';
	}
	return data;
}

/// Launch property editor.
/// <var>propNo</var> is index of property in dataSet.
ClientMethod showValueEditor(propNo) [ Language = javascript ]
{
	try {
		var grid = zenPage.getComponentById('gridProperties');
		grid.selectCell(propNo+1,0);
	
		var dataSet = grid.getDataSet();
		var clsName = this.currElementClass;
		var name  = this.currElementName;

		var value = dataSet.getData(propNo,0);
		var prop = dataSet.getLabel(propNo,1);
	
		// create throw-away object instance so we can look up
		// the type of the setting
		var ns = '';
		var component = null;
	
		// look up component class in classIndex
		var type = 'string';
		var idx = ('' == ns) ? name : (ns+'/'+name);
		var cls = _zenClassIdx[idx];

		if (cls != null && prop != '') {
			// create an instance so we can get the list of settings
			component = zenCreate(cls,-1,'');
			if (null != component && component.getSettings) {
				var settings = new Array();
				component.getSettings(settings);
				if (settings[prop]) {
					type = settings[prop];
				}
				delete component;
			}
		}
	
		var parms = new Object();
		parms.property = prop;
		parms.className = clsName;
		parms.value = value;
		parms.type = type;

		zenPage.launchPopupWindow(zenLink('%ZEN.Dialog.componentValueEditor.cls'),'ValueEditor','resizable,width=600,height=500',parms,this);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in ElementInspector:showValueEditor');
	}
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch (action) {
	case 'ok':
	case 'apply':
		var grid = zenPage.getComponentById('gridProperties');
		var row = grid.getCurrRow();
		grid.setCellValue(value, row, 1);
		break;
	}
}

/// Return csv-list of properties for the given element.
ClassMethod GetElementInfo(pClass As %String) As %String [ ZenMethod ]
{
	#; get attributes for class
	Set tRS = ##class(%ResultSet).%New("%ZEN.Utils:ComponentDetails")
	Set tSC = tRS.%Execute(pClass)

	Set tList = ""

	While (tRS.%Next()) {
		Set tName = $G(tRS.Data("Name"))
		Set tList = tList _ $S(tList="":"",1:",") _ tName
	}

	Set tRS = ""
	Quit tList
}

/// Convert the value within the property grid to something 
/// we can submit!
ClientMethod computeGridValue(grid) [ Language = javascript ]
{
	var dataSet = grid.getDataSet();
	var state = '';
	var size = dataSet.getDimSize(1);
	for (var n = 0; n < size; n++) {
		if (dataSet.getData(n,0) != '') {
			state += ' ' + dataSet.getLabel(n,1) + '="' + dataSet.getData(n,0) + '"';
		}
	}

	// apply value to hidden control
	var ctrl = zenPage.getComponentById('ctrlProperties');
	ctrl.setProperty('value',state);
}

/// Validation handler for form built-into template.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	return true;
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
		// if user selects an element, we can go to the next tab
		return ('' != this.currElementClass);
	}

	return false;
}

/// Return true if this template can go to the previous page (i.e., enable
/// the Back button).<br>
ClientMethod canGoBack() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');

	return (tabGroup.getCurrTabNo() > 1);
}

/// Go to the next page of the template (if there is one).<br>
ClientMethod nextPage() [ Language = javascript ]
{
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

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	// make sure first page is initialized
	this.elementChange(zenPage.getComponentById('ctrlElement'));
}

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.
Method %OnTemplateAction() As %Status
{
	Set tPre = ..%GetValueByName("PreText")
	Set tPost = ..%GetValueByName("PostText")
	Set tElement = ..%GetValueByName("Element")
	Set tAttrs = ..%GetValueByName("Properties")
	
	Set tTag = $P(tElement,".",$L(tElement,"."))

	Write tPre
	Write "<",tTag,tAttrs,"/>"
	Write tPost
	Quit $$$OK
}

/// Create the result set used by the Element dataCombo.
Method CreateElementRS(Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %ResultSet
{
	Set tRS = ""
	Set tSC = $$$OK

	Set tRS = ##class(%ResultSet).%New()
	Set tRS.ClassName = "%ZEN.Utils"
	Set tRS.QueryName = "EnumerateComponents"
	Quit tRS
}

}
