/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Studio Template.<br>
/// Create CSP forms for classes.
Class %ZEN.Template.WebFormWizard.Home Extends %ZEN.Template.WebFormWizard.Template [ Deprecated, System = 4 ]
{

Parameter TEMPLATENAME = "Web Form Wizard";

Parameter TEMPLATETITLE = "Web Form Wizard";

Parameter TEMPLATEDESCRIPTION = "Create a CSP form for a Cache class.";

Parameter TEMPLATETYPE = "cls,csp";

/// What type of template.
Parameter TEMPLATEMODE = "template";

/// Display title of this page <title></title>
Parameter PAGETITLE = "Web Form Wizard";

/// Domain used for localization.
Parameter DOMAIN = "%ZEN";

Property sId As %ZEN.Datatype.string [ InitialExpression = {$select($isObject($get(%session)):%session.SessionId,1:$j)} ];

/// User selected class name
Property FullClassName As %ZEN.Datatype.string;

Property TreeTotal As %ZEN.Datatype.integer;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
body {
	overflow: hidden;
}
#ctrlClassName {
	border: 1px gray solid;
	height: 400px;
	overflow: auto;
}
#treeAttr {
	border: 1px gray solid;
	height: 400px;
	width:  240px;
	overflow: auto;	
}
.helpText {
	color:gray;
	font-size:0.8em;	
}
.zenLabel {
	font-size: 0.8em;
	text-decoration: none;
	vertical-align: middle;
}
.caption {
	font-size: 0.8em;
	font-weight: bold;
	vertical-align: middle;
}
#btnR1 input,#btnR2 input,#btnL1 input,#btnL2 input,#btnU1 input,#btnD1 input {
	width: 1.7em;
}
.btnL1 {
	width:  23px;
	height: 23px;
	background-image: url(images/arrow1L.gif);
	background-repeat: no-repeat;
}
.btnL2 {
	width:  23px;
	height: 23px;
	background-image: url(images/arrow2L.gif);
	background-repeat: no-repeat;
}
.btnR1 {
	width:  23px;
	height: 23px;
	background-image: url(images/arrow1R.gif);
	background-repeat: no-repeat;
}
.btnR2 {
	width:  23px;
	height: 23px;
	background-image: url(images/arrow2R.gif);
	background-repeat: no-repeat;
}
.btnU1 {
	width:  23px;
	height: 23px;
	background-image: url(images/arrow1U.gif);
	background-repeat: no-repeat;
}
.btnD1 {
	width:  23px;
	height: 23px;
	background-image: url(images/arrow1D.gif);
	background-repeat: no-repeat;
}


</style>
}

/// This XML block defines the contents of the body pane of this Studio Template.
XData templateBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane id="body" cellStyle="padding-left:10px;">
<tabGroup id="tabGroup">
<tab>
<vgroup labelPosition="top" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<html id="desc" OnDrawContent="%GetDescHTML" />
<label label="Which class would you like to use?" labelClass="caption"/>
<dynaTree id="ctrlClassName" name="ClassName" label="Please select a class:"
  OnGetTreeInfo="PopulateClassList"
  onclick="zenPage.treeClick(0);"
  ondblclick="zenPage.treeClick(1);" 
>
</dynaTree>
</vgroup>
</tab>
<tab>
<vgroup labelPosition="top" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<html id="desc2" OnDrawContent="%GetDescHTML2" seed=""/>
<label label="Which properties would you like to include on the new form?" labelClass="caption"/>
<hgroup id="g1" cellVAlign="middle" hidden="false">
<dynaTree id="treeAttr" name="treeAttr" label="Available Properties:"
  OnGetTreeInfo="PopulateAttributeList"
  onclick="zenPage.moveTo();zenPage.arrowClicked();"
  dragEnabled="false"
  dropEnabled="false"
>
</dynaTree>
<spacer width="4"/>
<vgroup>
<button id="btnR1" controlClass="btnR1" onclick="zenPage.moveTo();zenPage.arrowClicked();"/>
<button id="btnL1" controlClass="btnL1" onclick="zenPage.moveBack();zenPage.arrowClicked();"/>
<spacer height="1"/>
<button id="btnR2" controlClass="btnR2" onclick="zenPage.moveToAll();zenPage.arrowClicked();"/>
<button id="btnL2" controlClass="btnL2" onclick="zenPage.moveBackAll();zenPage.arrowClicked();"/>
</vgroup>
<spacer width="4"/>
<listBox name="lstselect" id="lstselect" label="Selected Properties" 
ondblclick="zenPage.moveBack();zenPage.arrowClicked();" 
listWidth="240px" listHeight="400px" hzScroll="true"  
dragEnabled="true"
dropEnabled="true"
onafterdrag="zenPage.afterDrag(zenThis,dragData);" 
>
</listBox>
<vgroup cellStyle="padding-left:2px;">
<button id="btnU1" controlClass="btnU1" onclick="zenPage.moveUpDown('u');"/>
<button id="btnD1" controlClass="btnD1" onclick="zenPage.moveUpDown('d');"/>
</vgroup>
</hgroup>
<label label="Click the plus sign to open the embedded classes if you want to include them." labelClass="helpText"/>

</vgroup>
</tab>
<tab>
<vgroup labelPosition="top" cellStyle="padding: 2px; padding-left: 5px; padding-right: 5px;">
<label label="You may specify attributes for each selected property." labelClass="caption"/>
<html id="desc3" OnDrawContent="%GetDescHTML3" enclosingClass="zenLabel"/>
<hgroup cellStyle="padding-right:10px" cellVAlign="top" containerStyle="padding-top:10px;">
<listBox name="lstFields" id="lstFields" label="Selected Properties:" labelClass="zenLabel"
listWidth="240px" listHeight="400px" hzScroll="true" onchange="zenPage.lstFieldsClick(zenThis);"
>
</listBox>
<!-- idAttr is disabled until user clicks on a property. Else if user enter something without checking a property it will cause Finish to fail. -->
<fieldSet id="idAttr" legend="Data Type Attribute" enclosingClass="zenLabel" width="240px" 
 cellStyle="padding:4px;" disabled="true">
<text id="sCaption" label="Caption:" size="30" onchange="zenPage.updateAttribute(zenThis);"/>
<checkbox id="iReadOnly" caption="ReadOnly" captionClass="zenLabel" onchange="zenPage.updateAttribute(zenThis);"/>
<fieldSet id="idAttr1" legend="Show reference as" enclosingClass="zenLabel" width="220px" 
 cellStyle="padding:4px;" hidden="true">
<radioSet id="optRef" displayList="Text box,Pull-down menu,Search button,Hyperlink" valueList="0,1,2,3" captionClass="zenLabel" 
value="0" originalValue="0" onclick="zenPage.updateAttribute(zenThis);"/>
</fieldSet>
<vgroup id="idAttr2" enclosingClass="zenLabel" hidden="true">
<text id="iRowHeight" label="Control row height:" size="5" onchange="zenPage.updateAttribute(zenThis);"/>
</vgroup>
<vgroup id="idAttr3" enclosingClass="zenLabel" hidden="true">
<text id="sRowHeight" label="Image height:" size="5" onchange="zenPage.updateAttribute(zenThis);"/>
<text id="sRowWidth" label="Image width:" size="5" onchange="zenPage.updateAttribute(zenThis);"/>
</vgroup>
<vgroup id="idAttr4" enclosingClass="zenLabel" hidden="true">
<select id="lstQueryName" label="Query name:" valueList="" onchange="zenPage.lstQueryNameClick(zenThis);"/>
<select id="lstQueryColumn" label="Column name:" valueList="" onchange="zenPage.lstQueryColumnClick(zenThis);"/>
</vgroup>
</fieldSet>
</hgroup>
</vgroup>
</tab>
</tabGroup>
</pane>
}

/// Moving item in a listbox up and down
ClientMethod moveUpDown(flag) [ Language = javascript ]
{
	var fromCtl = zenPage.getComponentById('lstselect');
	var total = fromCtl.getOptionCount();
	if (total == 0) return;
	var currIndex = fromCtl.selectedIndex;
	if (currIndex < 0) return;
	if (flag == "u") {
		var newIndex = parseInt(currIndex) - 1;
		if (newIndex < 0) return;
	} else {
		var newIndex = parseInt(currIndex) + 1;
		if (newIndex > total) return;
	}
	var ovalue = fromCtl.getOptionValue(currIndex);
	var otext = fromCtl.getOptionText(currIndex);
	var nvalue = fromCtl.getOptionValue(newIndex);
	var ntext = fromCtl.getOptionText(newIndex);
	//setOption(index, value, text, style)
	fromCtl.setOption(newIndex, ovalue, otext);
	fromCtl.setOption(currIndex, nvalue, ntext);
}

/// Select the entire list from tree to the list, marking tree item style as selected
ClientMethod moveToAll() [ Language = javascript ]
{
	var tree = zenPage.getComponentById("treeAttr");
	var toCtl = zenPage.getComponentById("lstselect");
	var nodeCount = tree.getProperty("nodeCount");
	for (var r = 0; r < nodeCount; r++) {
		var anchor = tree.findElement('a_' + r);
		// if this item has already been selected, then skip.
		if(anchor) {
			if (anchor.style.cssText) return;
		}
		// set to lstselect control
		toCtl.appendOption(r,tree.getNodeText(r));
		tree.setNodeStyle(r,'background:white;color:gray;');
	}
}

/// Move item from tree to listbox
ClientMethod moveTo() [ Language = javascript ]
{
	var tree = zenPage.getComponentById("treeAttr");
	var currIndex = tree.getProperty("selectedIndex");
	if (currIndex == -1) return;
	var anchor = tree.findElement('a_' + currIndex);
	// if this item has already been selected, then skip.
	if(anchor) {
		if (anchor.style.cssText) return;
	}
	var nodeCount = this.TreeTotal;
	var toCtl = zenPage.getComponentById("lstselect");
	// set the tree's index into the list value so that you can return;
	var optionValue = currIndex;
	var optionText = tree.getNodeText(currIndex);
	// set to lstselect control
	toCtl.appendOption(optionValue,optionText);
	tree.setNodeStyle(currIndex,'background:white;color:gray;');
	// If this item has children then move all
	/* Do not delete: the following code is working code that can be used
	var anchor = tree.findElement('a_' + currIndex);
	if (anchor) {
		// children = all items that have parent = currIndex
		var item = currIndex + 1;
		while (item < nodeCount) {
			var c = tree.findElement('a_' + item);
			if (c) {
				var n = c.getAttribute('zenParent');
				if ((n == currIndex) && (c.style.cssText=='')) {
					toCtl.appendOption(item,tree.getNodeText(item));
					tree.setNodeStyle(item,'background:white;color:gray;');	
				} else {
					if (n > currIndex) return;
				}
			}
			item++;
		} 
	}
	*/
}

/// Move item from listbox to tree
ClientMethod moveBackAll() [ Language = javascript ]
{
	var optionValue;
	var fromCtl = zenPage.getComponentById("lstselect");		
	var tree = zenPage.getComponentById("treeAttr");
	var total = fromCtl.getOptionCount();
	for (var r = 0; r < total; r++) {
		optionValue = fromCtl.getOptionValue(r);
		tree.setNodeStyle(optionValue,'');
	}
	fromCtl.resetOptions();
}

/// Move item from listbox to tree
ClientMethod moveBack() [ Language = javascript ]
{
	var fromCtl = zenPage.getComponentById("lstselect");		
	var currIndex = fromCtl.selectedIndex;
	if ( (currIndex < 0) || (currIndex >= fromCtl.getOptionCount()) ) return;	
	var optionValue = fromCtl.getOptionValue(currIndex);
	fromCtl.removeOption(currIndex);
	var tree = zenPage.getComponentById("treeAttr");
	tree.setNodeStyle(optionValue,'');
}

/// User clicked one of the arrows or double clicked. 
ClientMethod arrowClicked() [ Language = javascript ]
{
	this.updateState();
}

Method %OnAfterCreatePage() As %Status
{
	Quit $$$OK
}

/// Return true if this template can go to the next page (i.e., enable
/// the Next button).<br>
ClientMethod canGoNext() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var proxy = this.getClassName();
	var flag = false;
	switch(tabNo) {
	case 1:
		if (proxy.Package != null) {
			flag = true;
		}
	case 2:
	// if user selected properties
		var lstselect = zenPage.getComponentById('lstselect').getOptionCount();
		if (lstselect > 0) {	
			flag = true;
		} 
	}
	return flag;
}

/// Return true if this template can go to the previous page (i.e., enable
/// the Back button).<br>
/// This is implemented by subclasses.
ClientMethod canGoBack() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var flag = true;
	switch(tabNo) {
	case 1:
		flag = false;
		break;
	case 2:
		break;
	case 3:
		break;
	}	
	return flag
}

/// Return true if this template can Finish (i.e., enable
/// the Finish button).<br>
/// This is implemented by subclasses.
ClientMethod canFinish() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var flag = false;
	switch(tabNo) {
	case 1:
		break;
	case 2:
	// if user selected properties
		var lstselect = zenPage.getComponentById('lstselect').getOptionCount();
		if (lstselect > 0) {	
			flag = true;
		} 
		break;
	case 3:
		flag = true;
		break;
	}	
	
	return flag;
}

/// This is called when the template is first displayed;
/// This provides a chance to set focus etc.
ClientMethod onstartHandler() [ Language = javascript ]
{
	// give focus to name
	//var ctrl = zenPage.getComponentById('ctrlClassName');
	//if (ctrl) {
	//	ctrl.focus();
		//ctrl.select();
	///}
}

/// Validation handler for form built-into template.
ClientMethod formValidationHandler() [ Language = javascript ]
{
	var lstselect = zenPage.getComponentById('lstselect');
	var total = lstselect.getOptionCount();
	var columns = "";
	for (var r = 0; r < total; r++) {
		if (columns != "") columns = columns + ",";
		columns = columns + lstselect.getOptionText(r);
	}
	if (columns == "") {
		alert("Please select at least one property.");
		return false;
	}
	var ok = this.SavePropList(this.sId, columns);
	return true;
}

ClientMethod hasMultiplePages() [ Language = javascript ]
{
	return true;
}

/// User clicked a selected property in lstFields on tab3.
/// Fill in caption and determine if the reference radiobuttons should be shown.
ClientMethod lstFieldsClick(ctrl) [ Language = javascript ]
{
	try {
		var propname = ctrl.getOptionText(ctrl.selectedIndex);
		var iReadOnly = zenPage.getComponentById("iReadOnly");
		zen("idAttr").setProperty("disabled",false);
		var proxy = this.ShowRef(propname);
		zenPage.getComponentById('sCaption').setValue(proxy.Caption);
		zenPage.getComponentById('idAttr').setProperty("legend", proxy.Legend);	
		var ctrl = "idAttr";
		for(var i=1; i<5; i++) {		
			zenPage.getComponentById(ctrl+i).setHidden(true);
		}
		switch(proxy.frame) {
		case "idAttr1":
			iReadOnly.setHidden(true);
			zenPage.getComponentById("optRef").setValue(proxy.optRef);
			if (proxy.optRef > 0) {
				zenPage.getComponentById("idAttr4").setHidden(false);
				zenPage.getComponentById("lstQueryName").setValue(proxy.sRefQueryName);
				zenPage.getComponentById("lstQueryColumn").setValue(proxy.sRefQueryColumn);			
			}
			break;
		case "idAttr2":
			iReadOnly.setHidden(true);
			break;
		case "idAttr3":
			iReadOnly.setHidden(true);
			zenPage.getComponentById("sRowHeight").setValue(proxy.RowHeight);
			zenPage.getComponentById("sRowWidth").setValue(proxy.RowWidth);
			break;
		default:
			iReadOnly.setHidden(false);
			break;	
		}
		if (proxy.frame != "") zenPage.getComponentById(proxy.frame).setHidden(false);
		iReadOnly.setValue(proxy.ReadOnly);

	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Load selected properties into fields box on tab3
ClientMethod loadFields() [ Language = javascript ]
{
	var lstFields = zenPage.getComponentById('lstFields');
	lstFields.resetOptions();
	var lstselect = zenPage.getComponentById('lstselect');
	var len = lstselect.getOptionCount();
	for(var i=0; i<len; i++) {
		var eText = lstselect.getOptionText(i);
		lstFields.appendOption(eText,eText);
	}
	// hide reference fields and reset caption in case it has been modified
	for(var i=1; i<5; i++) {		
		zenPage.getComponentById("idAttr"+i).setHidden(true);
	}
	zenPage.getComponentById("sCaption").setValue("");
}

/// This is called when the user changes the Location control(s).
ClientMethod locationChange(ctrl) [ Language = javascript ]
{
	var val = ctrl.getValue();
	var cb = zenPage.getComponentById('callback');
	cb.setHidden('serverCallback' != val);
}

/// Load properties for selected table
ClientMethod loadProperties() [ Language = javascript ]
{
	//zenPage.getComponentById('lst').resetOptions();
	zenPage.getComponentById('lstselect').resetOptions();
	//alert(this.Namespace+this.FullClassName);
	//var ok = this.PopulateAttributeList(this.Namespace,this.FullClassName,this.sId);
	var treeAttr = zenPage.getComponentById('treeAttr');
	treeAttr.refreshContents();
}

/// Go to the next page of the template (if there is one).<br>
/// This is implemented by subclasses.
ClientMethod nextPage() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var proxy = this.getClassName();
	switch(tabNo) {
	case 1:
		if (proxy.Package != null) {
			tabGroup.showNextTab();
			var desc2 = zenPage.getComponentById('desc2');
			desc2.setProperty("seed",this.FullClassName);
			desc2.refreshContents();
			this.loadProperties();
			break;
		}
	case 2:
		if (proxy.Package != null) {
			tabGroup.showNextTab();
			this.loadFields();
			break;
		}
	case 3:
		if (proxy.Package != null) {
			break;
		}
	}
	zenPage.updateState();
}

/// Go to the previous page of the template (if there is one).<br>
/// This is implemented by subclasses.
ClientMethod previousPage() [ Language = javascript ]
{
	var tabGroup = zenPage.getComponentById('tabGroup');
	var tabNo = tabGroup.getCurrTabNo();
	var proxy = this.getClassName();
	switch(tabNo) {
	case 1:
		break;
	case 2:
		if (proxy.Package != null) {
			tabGroup.showPreviousTab();
			break;
		}
	case 3:
		if (proxy.Package != null) {
			tabGroup.showPreviousTab();
			break;
		}
	}
	zenPage.updateState();
}

/// Return currently selected package and classname
ClientMethod getClassName() [ Language = javascript ]
{
	var proxy = new zenProxy();	
	var tree = zenPage.getComponentById("ctrlClassName");
	var nodeCount = tree.getProperty("nodeCount");
	var index = tree.getProperty("selectedIndex");
	var pkgindex = tree.getNodeParent(index);
	proxy.Package = tree.getNodeText(pkgindex);
	proxy.ClassName = tree.getNodeText(index);
	this.FullClassName = tree.getNodeValue(index);
	return proxy
}

/// User selected a Query Name for reference class.
/// Save the selection and load the Query Columns field.
ClientMethod lstQueryNameClick(ctrl) [ Language = javascript ]
{
	try {
		var lstFields = zenPage.getComponentById("lstFields");
		var propname = lstFields.getOptionText(lstFields.selectedIndex);
		var val = ctrl.getValue();
		this.SaveAttribute(this.sId,propname,"sRefQueryName",val);
		var valueList = this.PopulateRefPropList(this.sId,propname);
		var lstQueryColumn = zenPage.getComponentById("lstQueryColumn");
		lstQueryColumn.setProperty("showEmpty",true);
		lstQueryColumn.setProperty("valueList",valueList);
		lstQueryColumn.refreshContents();	
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// User selected a Query Column for reference class.
/// Save the selection and enable fields.
ClientMethod lstQueryColumnClick(ctrl) [ Language = javascript ]
{
	try {
		var lstFields = zenPage.getComponentById("lstFields");
		var propname = lstFields.getOptionText(lstFields.selectedIndex);
		var val = ctrl.getValue();
		this.SaveAttribute(this.sId,propname,"sRefQueryColumn",val);
		zenPage.getComponentById("sCaption").setValue(propname+" "+val);
		this.SaveAttribute(this.sId,propname,"sCaption",propname+" "+val);
		lstFields.setProperty("disabled",false);
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// User clicked an item in the tree
ClientMethod treeClick(gonext) [ Language = javascript ]
{
	var proxy = this.getClassName();
	if (proxy.Package != null) {
		zen("btnNext").setDisabled(false);
		zen("btnNext").setProperty("controlClass","commandButton");
		if (gonext==1) this.nextPage();
	} else {
		zen("btnNext").setDisabled(true);
	}
}

/// User changed an attribute field. Save it to temp array.
ClientMethod updateAttribute(ctrl) [ Language = javascript ]
{
	var propname = zenPage.getComponentById("lstFields").getValue();
	var ctrlid = ctrl.getProperty("id");
	if (ctrlid == "optRef") {
		var optRef = ctrl.getValue();
		if (optRef > 0) {
			zenPage.getComponentById("idAttr4").setHidden(false);
			var lstQueryName = zenPage.getComponentById("lstQueryName");
			if (optRef == 1) {
				//zenPage.getComponentById("lstFields").setProperty("disabled",true);
				lstQueryName.setHidden(false);
				// need to load what's already defined if it's already defined
				//zenPage.getComponentById("lstQueryName").resetOptions();
				var valueList = this.PopulateQueryList(this.sId,propname);
				lstQueryName.setProperty("valueList",valueList);
				lstQueryName.refreshContents();				
				//if sRefQueryName has value already, then load the value and QueryColumn list
				//alert(proxy.sRefQueryName + " column="+proxy.sRefQueryColumn);
				//else, clear the column list in case it was loaded by other field
				var lstQueryColumn = zenPage.getComponentById("lstQueryColumn");
				lstQueryColumn.setProperty("showEmpty",false);
				lstQueryColumn.setProperty("valueList","");
				lstQueryColumn.refreshContents();
			} else {
				lstQueryName.setHidden(true);
				var valueList = this.PopulateRefQueryColumn(this.sId,propname);
				if (valueList != "") {
					var lstQueryColumn = zenPage.getComponentById("lstQueryColumn");
					lstQueryColumn.setProperty("showEmpty",false);
					lstQueryColumn.setProperty("valueList",valueList);
					lstQueryColumn.refreshContents();
					var nval = valueList.split(",");
					if (nval[0]!="") {
						var newCaption = propname+" "+nval[0];
						zenPage.getComponentById("sCaption").setValue(newCaption);
						this.SaveAttribute(this.sId,propname,"sCaption",newCaption);
					}
				}			
			}
		} else {
			zenPage.getComponentById("idAttr4").setHidden(true);	
		}
	}
	var val = ctrl.getValue();
	if (ctrlid=="iReadOnly") val = (val==true)?1:0;
	this.SaveAttribute(this.sId,propname,ctrlid,val);
}

/// This method is called when the template is complete. Any
/// output to the principal device is returned to the Studio.
Method %OnTemplateAction() As %Status
{
	Set sId = $Select($isObject($get(%session)):%session.SessionId,1:$j)
	Set tClassName = $P(%session.Data(sId),"^",1)
	Set SelectedPropertyList = $P(%session.Data(sId),"^",2)	
	Set Layout = ##class(%ZEN.Template.WebFormWizard.Settings).GetLayout()
    Do ..WriteFormHeader(sId,tClassName,.Layout)
    Do ..WriteFields(sId,tClassName,.Layout,.bReq)
    Do ..WriteFormFooter(tClassName,.Layout,.bReq)
	Quit $$$OK
}

/// Provide contents of description component for tab1.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("The Web Form Wizard will help you create CSP forms for classes."),"<br/>"
	Write $$$TextHTML("You can utilize the created forms to retrieve and manipulate your data.")
	Quit $$$OK
}

/// Provide contents of description component for tab2.
Method %GetDescHTML2(pSeed As %String) As %Status
{
	Write $$$FormatText($$$Text("You have selected class <b>%1</b> in namespace %2."),pSeed,$namespace),"<br/>"
	Write $$$TextHTML("Now select properties.")
	Quit $$$OK
}

/// Provide contents of description component for tab3.
Method %GetDescHTML3(pSeed As %String) As %Status
{
	Write $$$TextHTML("Click on a property from the Selected Properties box then modify its attributes in the Attribute box on the right.")
	Quit $$$OK
}

/// Build tree for class names 
ClassMethod PopulateClassList(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinitionQuery:FormWizard")
	If '$IsObject(tRS) Quit $$$OK
	Set tSC = tRS.Execute("persistent")
	If $$$ISERR(tSC) Quit tSC
	Set sLastPackage = ""	
	Set tTotal = 0
	While tRS.Next() {		
        Set sFullname = tRS.Get("Name")
        Set sPackage = $P(sFullname,".",1,$L(sFullname,".")-1)
        Set sClassName = $P(sFullname,".",$L(sFullname, "."))
        Set %session.Data("pkg",sPackage,sClassName)=sFullname
        If sLastPackage '= sPackage Set sLastPackage=sPackage,tTotal = tTotal + 1
	}
	Set tItem = 1
	Set tExpanded = 0
	Set sPackage = $O(%session.Data("pkg",""))
	While sPackage '= "" {
		#; pTree(0,"ch") level is the packages level
		Set pTree(0,"ch",tItem) = ""
		#; $LB(text,value,haschildren,link,expanded,icon,tooltip,style)
        Set pTree(tItem) = $LB(sPackage,sPackage,1,,1,,sPackage)
		Set sClassName = $O(%session.Data("pkg",sPackage,""))
		While sClassName '= "" {
			Set tTotal = tTotal + 1
			Set sFullname = %session.Data("pkg",sPackage,sClassName)
			Set pTree(tTotal) = $LB(sClassName,sFullname,0,"",tExpanded,,sFullname)
			Set pTree(tItem,"ch",tTotal) = ""	
			Set sClassName = $O(%session.Data("pkg",sPackage,sClassName))
		}		
		Set sPackage = $O(%session.Data("pkg",sPackage))
		Set tItem = tItem + 1
	}

	Kill %session.Data("pkg")
	
	Quit $$$OK
}

/// Load fields into Available/Selected list boxes.
/// ClassMethod PopulateAttributeList(NAMESPACE, FullClassName, sId) As %Boolean [ ZenMethod ]
ClassMethod PopulateAttributeList(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		If %page.FullClassName = "" Quit
		Set FullClassName = %page.FullClassName
		//If NAMESPACE '= "", NAMESPACE '= $namespace ZN NAMESPACE
		Set sId = $select($isObject($get(%session)):%session.SessionId,1:$j)
		Kill %session.Data(sId)
		#; The parameters
		Set Layout = ##class(%ZEN.Template.WebFormWizard.Settings).GetLayout()
		Set HasStreamCol = 0
		Set tRS = ##class(%ResultSet).%New("%CompiledProperty:PropertyInfo")
		Set tSC = tRS.Execute(FullClassName)
		If $$$ISERR(tSC) Quit
		Set %session.Data(sId) = FullClassName
		For i=1:1:tRS.GetColumnCount() If tRS.GetColumnName(i) = "Stream" Set HasStreamCol = 1 Quit
		Set tRow = 0
		While tRS.Next() {
			Set sName = tRS.GetData(1)
			Set datatype = tRS.Data("Datatype")
			Set sCollection = tRS.Data("Collection")
			#; we can't handle collection of objects yet
			If sCollection '= "", datatype = 0 Continue
			#; %List is not supported so skip it
        	If tRS.Data("Type") = "%Library.List" Continue
        	If HasStreamCol Set sStream = $ZCVT(tRS.Get("Stream"),"L")
        	Else  Set sStream = sCollection
			Set tRow = tRow + 1
			Set %session.Data(sId,sName,"sRequired") = $S(tRS.Data("Required")=1:"*",1:"")
			Set %session.Data(sId,sName,"iRowHeight") = 1
        	Set %session.Data(sId,sName,"sType") = tRS.Data("Type")
			Set %session.Data(sId,sName,"iReadOnly") = 0
            Set %session.Data(sId,sName,"sKeyName") = sName
            Set %session.Data(sId,sName,"sCaption") = tRS.Data("Caption")
  			//Set sName = tRS.GetData(1)

            If sCollection = "list" {
                Set %session.Data(sId,sName,"eKind") = ..#fkList
                Set %session.Data(sId,sName,"iRowHeight") = Layout.CollectionRows
            } ElseIf sCollection = "array" {
                Set %session.Data(sId,sName,"eKind") = ..#fkArray
                Set %session.Data(sId,sName,"iRowHeight") = Layout.CollectionRows
            } ElseIf sStream = "binarystream" {
                Set %session.Data(sId,sName,"eKind") = ..#fkImage
                Set %session.Data(sId,sName,"sRowHeight") = Layout.ImageHeight
                Set %session.Data(sId,sName,"sRowWidth") = Layout.ImageWidth
            } ElseIf sStream = "characterstream" {
                Set %session.Data(sId,sName,"eKind") = ..#fkMultiLine
                Set %session.Data(sId,sName,"iRowHeight") = Layout.MultilineRows
            } ElseIf datatype = 1 {
                Set %session.Data(sId,sName,"eKind") = ..#fkString
			} ElseIf tRS.Data("Serial") = 1 {
                Set %session.Data(sId,sName,"eKind") = ..#fkString
			} Else {
                Set %session.Data(sId,sName,"eKind") = ..#fkReference
                Set %session.Data(sId,sName,"iReadOnly") = 1
			    Set tRefArray(sName) = tRS.Data("Type")
			}
			#; if datatype = 0, it means the Type is another class
			If datatype = 0 Set tRefArray(sName) = tRS.Data("Type"),%session.Data(sId,sName,"sRefClass") = tRS.Data("Type")
            Set %session.Data(sId,sName,"sAttribName") = sName
            If %session.Data(sId,sName,"eKind") = ..#fkString, tRS.Data("Editable") = 0 {
	             Set %session.Data(sId,sName,"eKind") = ..#fkReadOnly
	             Set %session.Data(sId,sName,"iReadOnly") = 1
            }
            Set %session.Data(sId,sName,"iMaxLen") = +tRS.Data("MaxLen")
			If 
		}
		Set tTotal = tRow
	
		#; Loop through the ones that have RefClass and build further array for the tree
		Kill tRS
		Set sRefName = $O(tRefArray(""))
		While sRefName '= "" {
			Set sRefClass = tRefArray(sRefName)
			Set tRS = ##class(%ResultSet).%New("%CompiledProperty:PropertyInfo")
			Set tSC = tRS.Execute(sRefClass)
			If $$$ISERR(tSC) Quit
		    While tRS.Next() {
				//Set %session.Data(sId) = FullClassName
				Set sName = tRS.GetData(1)
				Set tName = sRefName _ "." _ sName
		        Set %session.Data(sId,0,sRefName,tName,"sKeyName") = tName
		        Set %session.Data(sId,0,sRefName,tName,"sCaption") = %session.Data(sId,sRefName,"sCaption") _ " " _ tRS.Data("Caption")
                Set %session.Data(sId,0,sRefName,tName,"eKind") = ..#fkReference
                Set %session.Data(sId,0,sRefName,tName,"sAttribName") = %session.Data(sId,sRefName,"sAttribName")
                Set %session.Data(sId,0,sRefName,tName,"sRefClass") = %session.Data(sId,sRefName,"sRefClass")
                Set %session.Data(sId,0,sRefName,tName,"sRefProperty") = sName
                Set %session.Data(sId,0,sRefName,tName,"iReadOnly") = 1
                //Set tTotal = tTotal + 1
		    }
 			Set sRefName = $O(tRefArray(sRefName))
		}
		Set tItem = 1
		Set tExpanded = 0
		Set sName = 0
		Set sName = $O(%session.Data(sId,sName))
		While sName '= "" {
			#; pTree(0,"ch") level is the packages level
			Set pTree(0,"ch",tItem) = ""
			#; $LB(text,value,haschildren,link,expanded,icon,tooltip,style)
	        Set haschildren = 0
			Set sRefClass = $G(%session.Data(sId,sName,"sRefClass"))
			If sRefClass '= "" Set haschildren = 1
	        Set pTree(tItem) = $LB(sName,sName,haschildren,,0,,sName)
			Set sRefName = sName
			Set tName = $O(%session.Data(sId,0,sRefName,""))
			While tName '= "" {
				Set tTotal = tTotal + 1
				Set sFullname = %session.Data(sId,0,sRefName,tName,"sKeyName")
				Set pTree(tTotal) = $LB(sFullname,sFullname,0,"",tExpanded,,sFullname)
				Set pTree(tItem,"ch",tTotal) = ""	
				Set tName = $O(%session.Data(sId,0,sRefName,tName))
			}		
			Set sName = $O(%session.Data(sId,sName))
			Set tItem = tItem + 1
		}
		Set sRefName = ""
		For  Set sRefName=$O(%session.Data(sId,0,sRefName)) Quit:sRefName=""  Set tName="" For  Set tName=$O(%session.Data(sId,0,sRefName,tName)) Quit:tName=""  Merge %session.Data(sId,tName)=%session.Data(sId,0,sRefName,tName)
		Kill %session.Data(sId,0)
		Set %page.TreeTotal = tTotal
	} While (0)
Done
	If $$$ISERR(tSC) Quit $System.Status.GetErrorText(tSC)
	Quit $$$OK
Trap
	Set $ZT=""	
	Write !,"Error occurred in PopulateAttributeList: ",$ZE,!
	Goto Done
}

/// User wants to create Drop-down for refclass. Return Query Name choices.
ClassMethod PopulateQueryList(sId, sName) As %String [ ZenMethod ]
{
	Set $ZT="Error"
    Set sRefClass = $G(%session.Data(sId,sName,"sRefClass"))
    If sRefClass = "" Quit
    Set lstQueryName = ""
    Set rs = ##class(%ResultSet).%New("%CompiledQuery:QueryInfo")
    Do rs.Execute(sRefClass)
    While rs.Next() {
        If rs.Get("ContainId") {
            Set lstQueryName = lstQueryName _ $S(lstQueryName'="":",",1:"") _ rs.Get("Name")
        }
    }
	Quit lstQueryName
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit tProxy
}

/// User wants to show reference as Pull-down menu and has selected a Query Name. 
/// Return Query Column choices.
ClassMethod PopulateRefPropList(sId, sName) As %String [ ZenMethod ]
{
	Set $ZT="Error"
	Set lstQueryColumn = ""
    Set sRefClass = $G(%session.Data(sId,sName,"sRefClass"))
    Set sRefQueryName = $G(%session.Data(sId,sName,"sRefQueryName"))
    If sRefClass = ""!(sRefQueryName="") Quit lstQueryColumn
    Set rs = ##class(%ResultSet).%New()
    Set rs.ClassName = sRefClass
    Set rs.QueryName = sRefQueryName
    Do rs.Execute()
    For col = 1:1:rs.GetColumnCount() Set lstQueryColumn = lstQueryColumn _ $S(lstQueryColumn'="":",",1:"") _ rs.GetColumnName(col)       
	Quit lstQueryColumn
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit $ZE
}

/// User wants to show reference as Search button or Hyperlink. 
/// Return Query Column choices.
ClassMethod PopulateRefQueryColumn(sId, sName) As %String [ ZenMethod ]
{
	Set $ZT="Error"
	Set lstQueryColumn = ""
    Set sRefClass = $G(%session.Data(sId,sName,"sRefClass"))
    If sRefClass = "" Quit lstQueryColumn
	Set rs = ##class(%ResultSet).%New("%CompiledProperty:PropertyInfo")
	Do rs.Execute(sRefClass)
    While rs.Next() {
    	If rs.Get("Datatype") = 0 ! (rs.Get("Collection") '= "") Continue
      	If rs.Get("Type") = "%Library.List" Continue
		Set lstQueryColumn = lstQueryColumn _ $S(lstQueryColumn'="":",",1:"") _ rs.GetData(1)    
    }
    If $G(%session.Data(sId,sName,"sRefQueryColumn")) = "" Set %session.Data(sId,sName,"sRefQueryColumn") = $P(lstQueryColumn,",",1)
	Quit lstQueryColumn
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit $ZE
}

/// Given property name, decide now what type of attribute we should show.
/// idAttr1 = show reference
/// idAttr2 = show collection or multiline
/// idAttr3 = show image
/// idAttr4 = show Pull-down menu for reference
ClassMethod ShowRef(sName) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error"

	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set sId = $select($isObject($get(%session)):%session.SessionId,1:$j)
	Set eKind = $G(%session.Data(sId,sName,"eKind"))
	Set tProxy.eKind = eKind
	Set tProxy.frame = ""
	Set tProxy.ReadOnly = 0
	Set tProxy.Caption = $G(%session.Data(sId,sName,"sCaption"))
	Set tProxy.Legend = $$$Text("Data Type Attribute") 
	Set tProxy.sRefQueryName = $G(%session.Data(sId,sName,"sRefQueryName"))
	Set tProxy.sRefQueryColumn = $G(%session.Data(sId,sName,"sRefQueryColumn"))
	If eKind = ..#fkString {
		If $G(%session.Data(sId,sName,"iReadOnly")) = 1 Set tProxy.ReadOnly = 1
		Else  Set tProxy.ReadOnly = 0		
	} ElseIf eKind = ..#fkReadOnly {
		Set tProxy.ReadOnly = 1
	} ElseIf eKind = ..#fkReference {
		If $G(%session.Data(sId,sName,"sRefProperty")) '= "" {
			Set tProxy.ReadOnly = 1
		} Else {
			Set tProxy.frame = "idAttr1"
			Set tProxy.Legend = $$$Text("Reference Attribute")
			Set tProxy.optRef = 0	
		}
	} ElseIf eKind = ..#fkRefCombo {
		Set tProxy.frame = "idAttr1"
		Set tProxy.Legend = $$$Text("Reference Attribute")
		Set tProxy.optRef = 1
	} ElseIf eKind = ..#fkRefSearch {
		Set tProxy.frame = "idAttr1"
		Set tProxy.Legend = $$$Text("Reference Attribute")
		Set tProxy.optRef = 2		
	} ElseIf eKind = ..#fkRefLink {
		Set tProxy.frame = "idAttr1"
		Set tProxy.Legend = $$$Text("Reference Attribute")
		Set tProxy.optRef = 3	
	} ElseIf eKind = ..#fkList {
		Set tProxy.frame = "idAttr2"
		Set tProxy.Legend = $$$Text("Collection Attribute") 			
		Set tProxy.RowHeight = $G(%session.Data(sId,sName,"iRowHeight"))
	} ElseIf eKind = ..#fkArray {
		Set tProxy.frame = "idAttr2"
		Set tProxy.Legend = $$$Text("Collection Attribute") 			
		Set tProxy.RowHeight = $G(%session.Data(sId,sName,"iRowHeight"))
	} ElseIf eKind = ..#fkImage {
		Set tProxy.frame = "idAttr3"
		Set tProxy.Legend = $$$Text("Image Attribute") 			
		Set tProxy.RowHeight = $G(%session.Data(sId,sName,"sRowHeight"))
		Set tProxy.RowWidth = $G(%session.Data(sId,sName,"sRowWidth"))
	} ElseIf eKind = ..#fkMultiLine {
		Set tProxy.frame = "idAttr2"
		Set tProxy.Legend = $$$Text("MultiLine Attribute") 			
		Set tProxy.RowHeight = $G(%session.Data(sId,sName,"iRowHeight"))
	}
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit tProxy
}

ClassMethod SaveAttribute(sId, sName, sField, sValue) [ ZenMethod ]
{
	Set $ZT = "Trap"
	Do {
		If sField = "optRef" {
			Set %session.Data(sId,sName,"eKind") = $Case(sValue,0:..#fkReference,1:..#fkRefCombo,2:..#fkRefSearch,:..#fkRefLink)
		} ElseIf sField = "lstQueryName" {
			Set sField = "sRefQueryName"
		} ElseIf sField = "lstQueryName" {
			Set sField = "sRefQueryName"
		} 
		Set %session.Data(sId,sName,sField) = sValue
	} While 0
	Quit
Trap	///
	Set $ZT="" Do BACK^%ETN
	Quit
}

/// Save the selected property list into %session for processing
ClassMethod SavePropList(sId, sValue) As %Boolean [ ZenMethod ]
{
	Set $P(%session.Data(sId),"^",2) = sValue
	Quit 1
}

/// *************************************************************** ///
/// *  The following methods are for generating code for a form.  * ///
/// *************************************************************** ///
/// Check for JavaScript name identifiers. If invalid characters
/// (including foreign language) exist in a property name,
/// then that property name will not be used in the field name
/// on the new generated form. Instead, a "fieldNN" name will be used
/// where NN is the unique "findex" number.
Method ConvertKeyNameToIntName(Key) As %String
{
    Set sMatch1 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_$%."
    Set sMatch2 = sMatch1 _ "1234567890"   
    If sMatch1 '[ $E(Key, 1) Quit ""
    Set intname = ""
    For i = 1:1:$L(Key) {
        Set char = $E(Key,i)
        If char '=  "." {
	        If char = "%" {
	            Set intname = intname _ "sys_"
	    	} Else {
	            If sMatch2 '[ char {
	                 Set intname = ""
	                 Quit
	            }
	            Set intname = intname _ char
	    	}
        }
    }    
    Quit intname
}

/// Loop through the selected properties. Add to search list if the property is searchable
Method GetSearchList(sId, clsName) As %String
{
	Set SelectedPropertyList = $P(%session.Data(sId),"^",2)
	Set GetSearchList = ""
	Set tRow = 0
	Set sName = $P(SelectedPropertyList,",",1)
	While sName '= "" {
		Set sType = $G(%session.Data(sId,sName,"sType"))
		If sType [ "%Library",##class(%CSP.DwxUtils).IsPropertySearchable(clsName,sName) {
			Set GetSearchList = GetSearchList_$S(GetSearchList'="":",",1:"")_sName
		}
		Set tRow = tRow + 1
		Set sName = $P(SelectedPropertyList,",",tRow)
	}
	If GetSearchList = "" Set GetSearchList = " where='%Id()'"
    Else  Set GetSearchList = " where='" _GetSearchList_"'"
	Quit GetSearchList
}

/// Build option list based on user's Settings
Method GetOptionsList(Layout) As %String
{
	Set GetOptionsList = ""
	For i=0:1:3 Set options(i) = ""
	Set options(2) = "nopredicates"
    If Layout.SearchNew = 1 Set options(0) = "popup"
    If Layout.SearchClear = 1 Set options(1) = "clearbtn"
    If Layout.SearchPredicates = 1 Set options(2) = "predicates"
    If Layout.SearchSort = 1 Set options(3) = "sortbox"
    For i = 0:1:3 If options(i) '= "" Set GetOptionsList = GetOptionsList_$S(GetOptionsList'="":",",1:"")_options(i)
	Quit GetOptionsList
}

/// This module is called to heck if ValueList and DisplayList exist. If yes, build SELECT box.
Method GetParameterList(clsName, sIntName)
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
    	Set GetParameterList = ""
    	Set oClass = ##class(%CompiledClass).%OpenId(clsName)
    	If '$IsObject(oClass) Quit
    	Set count = oClass.Properties.Count()
    	If count < 1 Quit
    	Set bFound = 0
    	For i = 1:1:count {
	    	If oClass.Properties.GetAt(i).Name = sIntName {
		    	Set bFound = 1 
		    	Quit
	    	} Else {
            	If $E(oClass.Properties.GetAt(i).Type, 1) '= "%" {
                	Set sSubName = oClass.Properties.GetAt(i).Name
                	Set oSubClass = ##class(%CompiledClass).%OpenId(oClass.Properties.GetAt(i).Type)
                	Set subCount = oSubClass.Properties.Count()
                	For j = 1:1:subCount {
                    	If sSubName & oSubClass.Properties.GetAt(j).Name = sIntName {
                        	Set bFound = 1
                        	Set oClass = oSubClass
                        	Set i = j
                        	Quit
                    	}
                	}
	    		}
    		}
    	}
    	If bFound = 0 Quit
	    Set sValList = oClass.Properties.GetAt(i).Parameters.GetAt("VALUELIST")
	    Set sDispList = oClass.Properties.GetAt(i).Parameters.GetAt("DISPLAYLIST")
	    If sDispList '= "" {
	        Set GetParameterList = sDispList
	    } ElseIf sValList '= "" {
	        Set GetParameterList = sValList
	    }
	} While (0)
Done
	Quit GetParameterList
Trap
	Set $ZT="" Do BACK^%ETN
	Goto Done
}

/// Write out HTML code for form header
Method WriteFormHeader(sId, clsName, Layout)
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
	
    Set formName = "form"
    Set objName = "objForm"
	Set SelectedPropertyList = $P(%session.Data(sId),"^",2)
	
	Write !,"<head>"
    Write !,"<title>Cache Server Page - " _ clsName _ " (" _ $namespace _ ")</title>"
    Write !,"</head>"
    Write !,"<h1 align='center'>" _ clsName _ "</h1>"

    Set sSearchList = ..GetSearchList(sId,clsName)
    Set sOptions = ..GetOptionsList(Layout)
	Do ..WriteJS(sId,clsName,Layout)
	If Layout.SaveMethod > 0 {
        Write !,"<!-- If this is a submit, then the submit button will be defined -->"
        Write !,"<csp:if condition='%request.IsDefined(" _ "submit" _ ")'>"
        Write !,"  <script language='cache' runat='server'>"
        Write !,"    // handle submit of form!"
        Write !,"    New ok,errmsg"
        Write !,"    Set ok = 0"
        Write !,"    Set errmsg = """""
        Write !,"    // invoke save code on form page"
        Write !,"    Set ok = ..formSubmit(.errmsg)"
        Write !,"  </script>"
        Write !,"  <csp:if condition=ok>"
        Write !,"    <!--The form was saved successfully! -->"
        Write !,"  <csp:else>"
        Write !,"    <div><font color='red' size='-1'>The form was not saved due to the following errors:</font></div>"
        Write !,"    <!-- Display the errors; they are in a string separated by \n characters -->"
        Write !,"    <ul>"
        Write !,"    <script language='cache' runat='server'>"
        Write !,"    For i = 1:1:$L(errmsg," _ "\n" _ ") {"
        Write !,"        If ($P(errmsg," _ "\n" _ ",i) '= " _"" _ ") {"
        Write !,"            Write " _ "<li>" _ ",$P(errmsg," _ "\n" _ ",i)"
        Write !,"        }"
        Write !,"    }"
        Write !,"    </script>"
        Write !,"    </ul>"
        Write !,"  </csp:if>"
        Write !,"</csp:if>"
	}
	Write !
    Write !,"<!-- set the domain so error messages could be properly localized -->"
    Write !,"<csp:class DOMAIN='%CSPBind'>"	
	Write !
    Write !,"<!-- use CSP:OBJECT tag to create a reference to an instance of the class -->"
    Write !,"<csp:object name='" _objName_ "' classname='" _clsName_"' OBJID='#(%request.Get(" _ """OBJID""" _ "))#'>"
    Write !
    Write !,"<!-- use csp:search tag to create a javascript function to invoke a search page --> "
    Write !,"<csp:search name='" _formName _"_search' classname='"_clsName_"'"_ sSearchList
    If $L(sOptions) > 1 Write " options='" _sOptions_"'"
    If $L(sOptions, "popup") > 1 Write " onselect='update'"
    Write ">"
    If $L(sOptions, "popup") < 1 Set sOptions = sOptions _ ",popup"
    If $L(sOptions) > 1 Set sOptions = "options='" _sOptions_"'"
    
    #;Build reference search tag
    Set tRow = 1
	Set sName = $P(SelectedPropertyList,",",1)
	While sName '= "" {
		Set eKind = $G(%session.Data(sId,sName,"eKind"))
		If eKind = ..#fkRefSearch ! (eKind = ..#fkRefLink) {
			Set sIntName = $G(%session.Data(sId,sName,"sIntName"))
			If sIntName = "" Set sIntName = ..ConvertKeyNameToIntName(%session.Data(sId,sName,"sKeyName"))
			Set sRefClass = $G(%session.Data(sId,sName,"sRefClass"))
			Set sRefQueryColumn = $G(%session.Data(sId,sName,"sRefQueryColumn"))
			Set sCaption = $G(%session.Data(sId,sName,"sCaption"))

			Write !!
            Write "<csp:search name='find" _ sIntName_"' classname='" _ sRefClass _ "'" 
            Write " where='" _ sRefQueryColumn_"' " _ sOptions _ " caption='" _sCaption _ "'"
            Write " startvalues='" _sIntName _ sRefQueryColumn _ "'"
            Write " onselect='update" _ sIntName_"'>"
		}
		Set tRow = tRow + 1
		Set sName = $P(SelectedPropertyList,",",tRow)
	}
    Write !!,"<form name='" _formName_ "' cspbind='" _objName_"'"
    If Layout.SaveMethod = 0 {

        Write " cspjs='All' onsubmit='return " _ formName _ "_validate();'"
    } ElseIf Layout.SaveMethod = 1 {
        Write " cspjs='Validate' onsubmit='return " _ formName _ "_validate();'"
    } ElseIf Layout.SaveMethod = 2 {
        Write " cspjs='None'"
    }
    Write ">",!,"<center>",!
    Write "<table cellpadding='3'>"
	
	} While (0)
Done
	Quit
Trap
	Set $ZT="" Do BACK^%ETN
	Write $ZE	
	Goto Done
}

/// Write out Javascript code for page
Method WriteJS(sId, clsName, Layout)
{
	Set SelectedPropertyList = $P(%session.Data(sId),"^",2)

    Write !,"<!-- This function is needed by the search button on the form -->"
    Write !,"<script language='javascript'>"
    Write !,"<!--"
    //'Set the update for search the entire form
    If Layout.SaveMethod = 0 {
        Write !,"function update(id)"
        Write !,"{",!,"     #server(..formLoad(id))#;"
        Write !,"     return true;"
        Write !,"}",!
    } Else {
	    /* For running independently
        sFile = TrimDir(frmWizard.txtFilename.text, Right(msDir, 1))
        sFile = Mid(frmWizard.txtFilename.text, Len(sFile) + 1, Len(frmWizard.txtFilename.text) - Len(sFile))
        sTempCode = sTempCode & vbCrLf & "function update(id)" & vbCrLf & "{" & vbCrLf _
        & "     // Please note that your saved CSP page name and the CSP page name in the location url must remain the same. " & vbCrLf _
        & "     // If you save the CSP page to a different name then please change the CSP page name in the location url as well. " & vbCrLf & vbCrLf _
        & "     self.document.location = '" & sFile & "?OBJID='" & " + id;" & vbCrLf _
        & "     return true;" & vbCrLf & "}" & vbCrLf
        */
    }
    
    //'If Reference style exists for Reference fields, build JavaScript functions here
  	Set tRow = 1
  	Set sName = $P(SelectedPropertyList,",",tRow)
	While sName '= "" {
		Set eKind = $G(%session.Data(sId,sName,"eKind"))
		If eKind = ..#fkRefSearch ! (eKind = ..#fkRefLink) {
			Set sIntName = $G(%session.Data(sId,sName,"sIntName"))
			Set sAttribName = $G(%session.Data(sId,sName,"sAttribName"))
			If sIntName = "" Set sIntName = sAttribName
            Write !,"function update" _ sIntName _ "(id)"
            Write !,"{",!,"     #server(..form" _ sAttribName _ "Load(id))#;"
           	Write !,"     return true;",!,"}",!
		}
		Set tRow = tRow + 1
		Set sName = $P(SelectedPropertyList,",",tRow)
	}
	Write !,"// -->",!,"</script>"
}

/// Write out HTML code: Loop through all selected fields
/// Set indicator (bReq) for whether there is at least one required field for footer.
Method WriteFields(sId, clsName, Layout, bReq)
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
	Set bReq = 0
    If Layout.LabelAlignLeft = 0 Set gsAlign = "left"
    Else  Set gsAlign = "right"
    If Layout.Bold = 1 Set sBold1 = "<b>",sBold2 = "</b>"
    Else  Set sBold1 = "",sBold2 = ""
	Set tRow = 1
	Set SelectedPropertyList = $P(%session.Data(sId),"^",2)
  	Set sName = $P(SelectedPropertyList,",",tRow)
	While sName '= "" {
		Set sIntName = ..ConvertKeyNameToIntName(%session.Data(sId,sName,"sKeyName"))
		Set %session.Data(sId,sName,"sIntName") = $S(sIntName'="":sIntName,1:"field"_tRow)
		If $G(%session.Data(sId,sName,"sRequired")) = "*" Set bReq = 1
		Do ..WriteConField(clsName,sId,sName,Layout,gsAlign,sBold1,sBold2)
		Set tRow = tRow + 1
		Set sName = $P(SelectedPropertyList,",",tRow)
	}
	} While (0)
Done
	Quit
Trap
	Set $ZT="" Do BACK^%ETN
	Write $ZE	
	Goto Done
}

/// Write out HTML code: Write out code for individual field
Method WriteConField(clsName, sId, sName, Layout, gsAlign, sBold1, sBold2)
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
	
	Set sProp = $G(%session.Data(sId,sName,"sIntName"))
    Set sRequired = $G(%session.Data(sId,sName,"sRequired"))
    If sRequired = "*" {
        Set sRequiredcsp = " csprequired"
        Set bReq = 1
    } Else {
        Set sRequiredcsp = ""
    }
	Set eKind = $G(%session.Data(sId,sName,"eKind"))  
    Set sCaption = $G(%session.Data(sId,sName,"sCaption"))
    Set sIntName = $G(%session.Data(sId,sName,"sIntName"))
    Set sKeyName = $G(%session.Data(sId,sName,"sKeyName"))
    Set iMaxLen = $G(%session.Data(sId,sName,"iMaxLen"))
    Set iReadOnly = $G(%session.Data(sId,sName,"iReadOnly"))
    Set sRefClass = $G(%session.Data(sId,sName,"sRefClass"))
    Set sRefQueryName = $G(%session.Data(sId,sName,"sRefQueryName"))
    Set sRefQueryColumn = $G(%session.Data(sId,sName,"sRefQueryColumn"))
    Set iRowHeight = $G(%session.Data(sId,sName,"iRowHeight"))
    Set sRowHeight = $G(%session.Data(sId,sName,"sRowHeight"))
    Set sRowWidth = $G(%session.Data(sId,sName,"sRowWidth"))
    Set sType = $G(%session.Data(sId,sName,"sType"))
    If iReadOnly = 1 Set readonly = " readonly"
    Else  Set readonly = ""

    Write !,$C(9),"<tr>"
    Write !,$C(9),$C(9),"<td>"
    If eKind = ..#fkRefSearch {
        Write "<input type='hidden' size='10' name='" _ sIntName _ "ID'"
        Write " cspbind='" _ sKeyName _ "'>"
    } ElseIf eKind = ..#fkRefLink {
        Write "<input type='hidden' size='10' name='" _  sIntName _ "ID'"
        Write " cspbind='" _ sKeyName _ "'>"
        Write !,$C(9),"<a href='javascript:find" _ sIntName _ "();'>"
    } ElseIf iReadOnly = 1 {
        Write "<font color='#666666'>"      //'dark gray for readonly
    }
    Write sBold1 _ "<div align='" _gsAlign _ "'>" _ sRequired _ sCaption _ ":</div>" _ sBold2
    If eKind '= ..#fkRefSearch, eKind '= ..#fkRefLink, iReadOnly = 1 Write "</font>"
    If eKind = ..#fkRefLink Write "</a>"
    Write "</td>"
    Write !,$C(9),$C(9),"<td>"
    If sType [ "Boolean" {
        Write "<input type='checkbox'" _ " name='" _ sIntName _ "' cspbind='" _sKeyName _"'" _ sRequiredcsp _ readonly _ ">"
        Write "</td>"
        Write !,$C(9),"</tr>"
        Quit
    }
    If iMaxLen > 0, iMaxLen < 80 Set nWidth = iMaxLen
    Else  If sType = "%Library.TimeStamp" Set nWidth = 19
    Else  If iMaxLen = 0, eKind '= ..#fkMultiLine Set nWidth = 10
    Else  Set nWidth = 80

	If eKind = ..#fkString ! (eKind = ..#fkReference & (sType = "%Library.String")) {
		#; BuildParameters:
        Set sParameterList = ..GetParameterList(clsName,sIntName)
        If sParameterList = "" {
            Write "<input type='text' name='" _ sIntName _ "' cspbind='" _ sKeyName _ "' size='" _ nWidth _ "'" _ sRequiredcsp _ readonly _ ">"
        } Else {
            Write "<select name='" _ sIntName _ "' cspbind='" _ sKeyName _ "'" _ sRequiredcsp _ ">"
            If sRequiredcsp = "" {
                Write !,$C(9),$C(9),"  <option value=''></option>"
            }
            Set delim = $E(sParameterList, 1)
            Set i = 2
            Set sVal = $P(sParameterList,delim,i)
            While sVal '= "" {
                Write !,$C(9),$C(9), "  <option value='" _ sVal _ "'>" _ sVal _ "</option>"	
	           	Set i = i + 1
	            Set sVal = $P(sParameterList,delim,i)
            }
            Write !,$C(9),$C(9),"</select>"
        }	
	}

    If eKind = ..#fkString {
        //Do ..BuildParameters(sIntName, sKeyName)
    } ElseIf eKind = ..#fkReadOnly {
        Write "<input type='text' name='" _ sIntName _"' cspbind='" _ sKeyName _ "' size='" _ nWidth _"'" _ sRequiredcsp _ readonly _ ">"

    } ElseIf eKind = ..#fkReference {
        If sType = "%Library.String" {
            //Do ..BuildParameters(sIntName, sKeyName)
        } Else {
	        #;sRefTemp
			Write "<input type='text' name='" _ sIntName _"' cspbind="
	        Write "'" _ sKeyName _"'"
	   		Write " size='" _ nWidth _ "'" _ sRequiredcsp _ readonly _ ">"
	        }
    } ElseIf eKind = ..#fkRefCombo {
        Write "<select name='" _ sIntName _"'"
        Write " cspbind='" _ sKeyName _ "' classname='" _ sRefClass _ "' query='" _  sRefQueryName _ "' field='" _ sRefQueryColumn _ "'" _ sRequiredcsp _ ">"
        Write "</select>"
    } ElseIf eKind = ..#fkRefSearch {
	    #;sRefTemp
	    Write "<input type='text' name='" _ sIntName _"' cspbind="
    	If sRefQueryColumn '= "" {
	   		Write "'"_sKeyName _ "." _ sRefQueryColumn _"'"
    	} Else {
        	Write "'" _ sKeyName _"'"
    	}
   		Write " size='" _ nWidth _ "'" _ sRequiredcsp _ readonly _ ">"
		Write !,$C(9)
        Write "<input type='button' name='btnFind'"
        Write " value='",$$$Text("Find"),"' onclick='find" _ sIntName _ "();'>"
    } ElseIf eKind = ..#fkRefLink {
		Write "<input type='text' name='" _ sIntName _"' cspbind="
    	If sRefQueryColumn '= "" {
	   		Write "'"_sKeyName _ "." _ sRefQueryColumn _"'"
    	} Else {
        	Write "'" _ sKeyName _"'"
    	}
   		Write " size='" _ nWidth _ "'" _ sRequiredcsp _ readonly _ ">"
    } ElseIf eKind = ..#fkList {
        Write "<textarea name='" _ sIntName _ "' cspbind='" _ sKeyName _ "' cols='" _ nWidth _ "' rows='" _ iRowHeight _ "'" _ sRequiredcsp _ ">"
        Write "</textarea>"
    } ElseIf eKind = ..#fkArray {
        Write "<textarea name='" _ sIntName _ "' cspbind='" _ sKeyName _ "' cols='" _ nWidth _ "' rows='" _ Layout.iCollectionRows _ "'" _ sRequiredcsp _ ">"
        Write "</textarea>"
    } ElseIf eKind = ..#fkImage {
        Write "<img name='" _ sIntName _ "' cspbind='" _ sKeyName _"'"
        If sRowHeight '= "", sRowHeight '= 0 {
            Write " height='" _ sRowHeight _ "'"
    	}
        If sRowWidth '= "", sRowWidth '= 0 {
            Write " width='" _ sRowWidth _"'"
    	}
        Write ">"
    } ElseIf eKind = ..#fkMultiLine {
        Write "<textarea name='" _ sIntName _ "' cspbind='" _ sKeyName _ "' cols='" _ nWidth _ "' rows='" _ iRowHeight _ "'"_ sRequiredcsp _ ">"
        Write "</textarea>" 
    }
    Write "</td>"
    Write !,$C(9),"</tr>"
  
	} While (0)
Done
	Quit
Trap
	Set $ZT="" Do BACK^%ETN
	Write $ZE
	Goto Done
}

/// Write out HTML code: form footer and finish
Method WriteFormFooter(clsName, Layout, bReq)
{
	Set formName = "form"
	Write !,$C(9),"<tr>"
	Write !,$C(9),$C(9),"<td>&nbsp;</td>"
	Write !,$C(9),$C(9),"<td>"

    If Layout.New {
        If Layout.SaveMethod = 0 {
        	Write "<input type='button' name='btnClear' value='#(%response.GetText("""",""%CSPSearch"",""ClearBtn"",""clear""))#'"," onclick='" _ formName _ "_new();'>"
        } Else {
        	Write "<input type='reset' name='reset' value='#(%response.GetText("""",""%CSPSearch"",""ResetBtn"",""reset""))#'>"

        }
    } Else {
        Write "&nbsp;"
    } 
    If Layout.Save {
        If Layout.SaveMethod = 0 {
          	Write !,$C(9), "<input type='button' name='btnSave' value='#(%response.GetText("""",""%CSPSearch"",""SaveBtn"",""save""))#'"," onclick='" _ formName _ "_save();'>"

        } Else {
           	Write !,$C(9), "<input type='submit' name='submit' value='#(%response.GetText("""",""%CSPSearch"",""SubmitBtn"",""submit""))#'>"

        }
    } Else {
        Write "&nbsp;"
    }
    If Layout.Search {
        Write !,$C(9), "<input type='button' name='btnSearch' value='#(%response.GetText("""",""%CSPSearch"",""SearchBtn"",""search""))#'"," onclick='" _ formName _ "_search();'>"

    } Else {
        Write "&nbsp;"
    }
    Write "</td>"
    #; if at least one is csprequired then bReq is 1
    Write !,$C(9),"</tr>"
    If bReq = 1 {
        Write !,$C(9),"<tr>"
        Write !,$C(9),$C(9),"<td>&nbsp;</td>"
        Write !,$C(9),$C(9),"<td>"
        Write "<font color='#000088' size='2'>"
        Write "#(%response.GetText("""",""%CSPSearch"",""RequiredNote"",""(* Denotes required fields)""))#'","</font></td>"

        Write !,$C(9),"</tr>"
    }
    Write !, "</table>",!,"</center>",!,"</form>",!
	Quit
}

}
