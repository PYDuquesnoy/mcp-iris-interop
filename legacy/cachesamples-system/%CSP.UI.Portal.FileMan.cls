/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - FileMan wizard
/// <p>Note: The FileMan toolset is available and fully supported in InterSystems IRIS for existing FileMan users.
/// InterSystems recommends against starting new development projects using FileMan.</p>
Class %CSP.UI.Portal.FileMan Extends (%CSP.UI.Portal.FileManTemplate, %CSP.UI.Portal.UtilsNav) [ Deprecated, System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "FileMan Wizard";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.FileMan.zen";

Parameter HELPADDRESS = "Home,SQL,FileMan Wizard";

/// Cancel return to this parent page
Parameter PARENTPAGE = "/csp/sys/exp/%CSP.UI.Portal.SQL.Home.zen";

/// Security requirement
Parameter RESOURCE = "%Development";

/// Switch namespace for this page
Parameter AUTONS As BOOLEAN = 1;

Property msgConfirmCancel As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Do you want to keep your file selections in the cart for future use in this session? Click [OK] to keep or [Cancel] to discard selections.")} ];

Property msgSelectAll As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("All files shown in table added to cart.")} ];

Property msgMapAll As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to map all files shown in the current table to classes?")} ];

Property DefaultLogFile As %ZEN.Datatype.string;

Property LogsPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/exp/UtilFileManLog.csp")} ];

Property TasksPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/%25CSP.UI.Portal.BackgroundTaskList.zen")} ];

XData Style
{
<style type="text/css">
.EditForm {
	background-image: url('');	
}
</style>
}

/// The page contains three blocks:
/// 1. The titleBar, which is drawn here
/// 2. The locatorBar, which is drawn here the Home page. You may add more locator links in subsequent pages
/// 3. The detailPane, which is the main content of your page.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" title="#(%page.StdTitle)#" valign="top">
<vgroup valign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-left:10px;padding-top:4px;padding-bottom:4px;"/>
<html id="idHTMLResult" OnDrawContent="DrawResult" hidden="true"/>
<vgroup id="fld1">
<hgroup valign="bottom">
<label label="Step 1 -" labelStyle="padding-left:10px;font-weight:bold;"/>
<label id="idStep1" label="Use the form below to view or edit the settings that define how FileMan data structures are converted to InterSystems class definition:" labelClass="caption"/>
</hgroup>
<pane paneName="configPane"/>
</vgroup>
<pane paneName="detailPane"/>
</vgroup>

</pane>
}

XData detailPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top">

<spacer height="1"/>
<vgroup id="fld2" hidden="true" containerStyle="padding-left:14px">
<hgroup valign="bottom">
<label label="Step 2 -" labelStyle="font-weight:bold;"/>
<label id="idStep2" label="Select FileMan files to map:" labelClass="caption" />
</hgroup>
<form id="thisForm" cellStyle="padding:5px;" layout="vertical" valign="top" enclosingClass="EditForm" >

<hgroup id="idFileName" labelPosition="top" label="Enter a file name (full or partial):" labelClass="caption" cellVAlign="top" cellStyle="padding-left:4px;">
<text id="txtFileName" name="txtFileName" size="30" value="" hint="Case sensitive."/>
<button id="btnSearch" name="btnSearch" caption="Search" containerStyle="padding-left:2px;" onclick="zenPage.doSearch();"/>
</hgroup>
<html><hr size="1"/></html>

<hgroup cellVAlign="top">
<vgroup id="idTable" hidden="false">
<tableNavBar id="tableNav" showFilter="false" showPageSize="true" showMaxRows="true" tablePaneId="table"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table" label="Select file(s) to map:" labelClass="caption"
 queryClass="%FileMan.File"
 queryName="ListFilesByName"
 bodyHeight="250px"
 dataSource="columns"
 fixedHeaders="false"
 pageSize="0"
 maxRows="1000"
 multiSelect="false"
 showFilters="true"
 showZebra="true"
 showValueInTooltip="true"
 showRowNumbers="false"
 useKeys="true"
 useSnapshot="true"
 valueColumn="NUMBER"
 dragEnabled="false"
 dropEnabled="false"
>
<column id="C1" colName="NAME" header="NAME"/>
<column id="C2" colName="NUMBER" header="NUMBER"/>
<column linkCaption="Select" link="javascript:zenPage.doSelect('#(%query.NUMBER)#');" cellTitle="Select individual fields from file"  />
<column linkCaption="Add to Cart" link="javascript:zenPage.doAddCart('#(%query.NUMBER)#');" cellTitle="Add file to cart with all fields"/>
<parameter id="parSearchMask" value="%%"/>
</tablePane>
<hgroup cellAlign="even">
<hgroup cellStyle="padding:2px;">
<button id="btnMapAll" name="btnMapAll" caption="Map All" onclick="zenPage.doMapAll();" disabled="true" title="Start processing to map all files in this table"/>
<button id="btnSelAll" name="btnSelAll" caption="Select All" onclick="zenPage.doSelAll();" disabled="true" title="Select all files from this table and add to cart"/>
</hgroup>
<hgroup cellStyle="padding:2px;">
	<button id="btnBack2" caption="Back" onclick="zenPage.doNext(1);"/>
	<button id="btnNext2" caption="Next" onclick="zenPage.doNext(3);" disabled="true"/>
	<button caption="Cancel" onclick="zenPage.doCancel();"/>
</hgroup>
</hgroup>
<label id="idAdded" align="right" controlClass="normal" value=""/>
</vgroup>
<vgroup id="g1" label="" cellStyle="padding:6px;" hidden="true">
<hgroup cellVAlign="middle">
<listBox name="lst" id="lst" label="Fields Not to Map" labelClass="caption"  
ondblclick="zenPage.arrowMoved(zenThis);zenPage.arrowClick('lst','lstselect');" 
listWidth="200px" listHeight="200px" hzScroll="true">
</listBox>
<spacer width="4"/>
<vgroup>
<button id="btnR1" caption="&gt;" onclick="zenPage.arrowClicked('lst');zenPage.arrowClick('lst','lstselect');"/>
<button id="btnL1" caption="&lt;" onclick="zenPage.arrowClicked('lstselect');zenPage.arrowClick('lstselect','lst');"/>
<spacer height="1"/>
<button id="btnR2" caption="&gt;&gt;" onclick="zenPage.arrowClickAll('lst','lstselect');zenPage.arrowClicked('lst');"/>
<button id="btnL2" caption="&lt;&lt;" onclick="zenPage.arrowClickAll('lstselect','lst');zenPage.arrowClicked('lstselect');"/>
</vgroup>
<spacer width="4"/>
<listBox name="lstselect" id="lstselect" label="Map These Fields" labelClass="caption" 
ondblclick="zenPage.arrowMoved(zenThis);zenPage.arrowClick('lstselect','lst');"
listWidth="200px" listHeight="200px" hzScroll="true">
</listBox>
</hgroup>
<button id="btnAddMap" name="btnAddMap" caption="Add to Cart" onclick="zenPage.doAddCart();" align="center" title="Click to add this file to be mapped"/>
</vgroup>
</hgroup>
</form>
</vgroup>
<vgroup id="fld3" hidden="true">
<hgroup valign="bottom">
<label label="Step 3 -" labelStyle="font-weight:bold;"/>
<label id="idStep3" label="View cart. Review selected files below and click 'Finish' to complete the mapping:" labelClass="caption"/>
</hgroup>
<form id="finishForm" cellStyle="padding:5px;" layout="vertical" valign="top" enclosingClass="EditForm" >
<hgroup enclosingStyle="background:#CBE6EB;border:1px gray solid;" cellStyle="padding-left:5px;" labelPosition="left">
<image id="imgReturn" src="/csp/broker/images/SmLeftArrow.png" width="15" height="15" alt="Remove all selections from the cart." onclick="zenPage.upOneLevel();"/>
<link id="linkReturn" href="javascript:zenPage.doDeleteAll();" caption="Clear Cart" containerStyle="font-size:0.7em;" title="Remove all selections from the cart."/>
<spacer width="4px"/>

<image id="imgDelete" src="/csp/broker/images/cut.png" width="16" height="16" alt="Remove a selected file from the cart." onclick="zenPage.deleteContext();"/>
<link id="linkDelete" href="javascript:zenPage.doDelete();" caption="Remove File" containerStyle="font-size:0.7em;" title="Remove a selected file from the cart." />
</hgroup>
<dynaTree
	id="tree" label="Fields selected to be mapped are shown in sub-node in the tree. If no specific fields shown, all fields for the file will be mapped." labelClass="caption"
	showLines="true"
	OnGetTreeInfo="GetTreeInfo"
	onupdate="zenPage.treeCount();" hint="To remove a file, click on the file name then click 'Remove File'. To remove all files, click 'Clear Cart'.">
</dynaTree>
<html><hr size="1"/></html>
<hgroup cellAlign="right">
<hgroup cellStyle="padding:2px;">
	<button id="btnBack3" caption="Back" onclick="zenPage.doNext(2);"/>
	<button id="btnFinish" caption="Finish" onclick="zenPage.doFinish(1);"/>
	<button caption="Cancel" onclick="zenPage.doCancel();"/>
</hgroup>
</hgroup>
</form>
</vgroup>

</pane>
}

/// Add selected FileNumber to cart.
/// Check to see if User unselected any to not to map. If yes, then save the selected fields.
ClientMethod doAddCart() [ Language = javascript ]
{
	/// Find selected row and display Text in the Cart list and save Value for later.
	var table = zenPage.getComponentById("table");
	var selectedIndex = table.getProperty("selectedIndex");
	var rowData = table.getRowData(selectedIndex);
	var pid = rowData["NUMBER"];
	var count = zenPage.getComponentById("lst").getOptionCount();
	var selected = rowData["NAME"];
	if (count > 0) {
		var lstselect = zenPage.getComponentById("lstselect");
		var selcount = lstselect.getOptionCount();
		for (i=0;i<selcount;i=i+1) {
			if (lstselect.getOptionValue(i)) {
				selected = selected + "^" + lstselect.getOptionValue(i) + "|" + lstselect.getOptionText(i);
			}
		}
	}
	this.SaveToCart(pid,selected);
	zenPage.getComponentById("g1").setHidden(true);
	zenPage.getComponentById("btnNext2").setProperty("disabled",false);
	this.toggleMapAll(true);
	var added = this.GetText(pid);
	var idAdded = zenPage.getComponentById("idAdded");
	idAdded.setValue(added);
	idAdded.setHidden(false);
}

/// Moving a list item from one box to the next, then remove it from the original box
ClientMethod arrowClick(from, to) [ Language = javascript ]
{
	var fromCtl = zenPage.getComponentById(from);
	var currIndex = fromCtl.selectedIndex;
	if ( (currIndex < 0) || (currIndex >= fromCtl.getOptionCount()) ) return;	
	var optionValue = fromCtl.getOptionValue(currIndex);
	var optionText = fromCtl.getOptionText(currIndex);
	var toCtl = zenPage.getComponentById(to);
	toCtl.appendOption(optionValue,optionText);
	
	fromCtl.removeOption(currIndex);
}

ClientMethod arrowClicked(id) [ Language = javascript ]
{
	zenPage.arrowMoved(zenPage.getComponentById(id));
}

/// Moving the entire list from one box to the next, then remove it from the original box
ClientMethod arrowClickAll(from, to) [ Language = javascript ]
{
	var fromCtl = zenPage.getComponentById(from);
	var toCtl = zenPage.getComponentById(to);
	var total = fromCtl.getOptionCount();
	for (var r = 0; r < total; r++) {
		toCtl.appendOption(fromCtl.getOptionValue(r),fromCtl.getOptionText(r));
	}
	fromCtl.resetOptions();
}

/// User double clicked one of the listboxes. Update imply message. 
ClientMethod arrowMoved(thisObj) [ Language = javascript ]
{
	try {
		var selection = thisObj.getValue();
		//var ok = this.GetImplied(selection);
		//zenPage.getComponentById("result").setProperty("value",ok);
		//zenPage.getComponentById("result").setHidden(0);
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// User clicked Cancel. Check if user has selected any files. If yes, prompt user
/// whether they want to keep the selection.
ClientMethod doCancel() [ Language = javascript ]
{
	// if user did not click "Save as Default" then values are used for this mapping only and let go.
	this.setModified(false);
	var ok = 1;
	var count = this.HasSelection();
	if (count > 0) {
		var ok = confirm(this.msgConfirmCancel);
		if (ok == false) {
			ok = this.ClearCart();
		}	
	}
	zenPage.gotoPage(this.ParentURL);
}

/// Delete one selection from tree.
/// If no selections left then go back to previous page.
ClientMethod doDelete() [ Language = javascript ]
{
	try {
		var tree = zenPage.getComponentById("tree");
		var nodeCount = tree.getProperty("nodeCount");
		var index = tree.getProperty("selectedIndex");
		if (index >= nodeCount) {
			var parent = tree.getNodeParent(index);
			if (parent > 0) {
				index = parent;
				tree.setProperty("selectedIndex",index);
			}
		}
		//var pid = zenPage.getComponentById("PID").getValue();
		var pid = tree.getProperty("value");
		if (index < 0) {
			return;
		}		
		var ok = this.RemoveCart(pid);
		if (ok == 1) {
			tree.refreshContents();
		} else {
			// go back to previous page
			this.doNext(2);
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// User clicked "Clear Cart". Clear all items in the cart and return to previous page.
ClientMethod doDeleteAll() [ Language = javascript ]
{
	var ok = this.ClearCart();
	this.doNext(2);
	zenPage.getComponentById("btnNext2").setProperty("disabled",true);
	this.toggleMapAll(false);
}

/// User clicked "Finish". Map selected items in the cart - call server method to job off in the background.
ClientMethod doFinish(isFinish) [ Language = javascript ]
{
	// Get parameters and pass to server 
	var proxy = this.getParameters();
	var filename = zenPage.getComponentById("txtFileName").getValue();
	var job = this.MapSelected(proxy,isFinish,filename);
	var html = zenPage.getComponentById('idHTMLResult');
	html.setHidden(false);
	//YSD2089 html.refreshContents();
	//YSD2132 html.setProperty('seed',isFinish+"^"+filename+"^"+job);
	html.seed = isFinish+"^"+filename+"^"+job;
	html.refreshContents();
	zenPage.getComponentById("btnFinish").setProperty("disabled",true);
}

/// User clicked "Map All". Map All that are shown in the current table.
ClientMethod doMapAll() [ Language = javascript ]
{
	var ok = confirm(this.msgMapAll);
	if (ok) {
		//var filename = zenPage.getComponentById("txtFileName").getValue();
		this.toggleMapAll(false);
		this.doFinish(0);
	}
}

/// User clicked "Next" or "Back". page number pass in is the target page number.
ClientMethod doNext(page) [ Language = javascript ]
{
	var fld;
	for (var x = 1; x <= 3; x++) {
		fld = "fld" + x;
		if (x != page) zenPage.getComponentById(fld).setHidden(true);
		else zenPage.getComponentById(fld).setHidden(false);
	}
	if (page == 3) {
		this.treeLoad();
	} else {
		/// after user clicked "Finish" and then clicked "Back", we clear the cart.
		if (page == 2) {
			zenPage.getComponentById("txtFileName").focus();
			if (zenPage.getComponentById("btnFinish").getProperty("disabled") == true) {
				ok = this.ClearCart();
				zenPage.getComponentById("btnNext2").setProperty("disabled",true);
			}
		}
	}
	/// if page changes, then hide the result message.
	zenPage.getComponentById('idHTMLResult').setHidden(true);
	zenPage.getComponentById("idAdded").setHidden(true);
}

/// User clicked "Select All". Add all that are shown in the current table to the cart.
ClientMethod doSelAll() [ Language = javascript ]
{
	var filename = zenPage.getComponentById("txtFileName").getValue();
	this.SelectAll(filename);
	zenPage.getComponentById("btnNext2").setProperty("disabled",false);
	this.toggleMapAll(true);
	this.showResult(this.msgSelectAll);
}

/// User clicked "Search". Get user file name (partial is okay) and refresh table.
ClientMethod doSearch() [ Language = javascript ]
{
	this.getComponentById("idTable").setHidden(false);
	//var flag = (locale=="")?true:false;
	var filename = zenPage.getComponentById("txtFileName").getValue();
	var table = zenPage.getComponentById("table");
	table.parameters[0].value = filename;
	table.executeQuery();
	this.toggleMapAll(false);
	this.showResult("");
}

/// User clicked "Select". Show Fields for the selected File Number.
ClientMethod doSelect(id) [ Language = javascript ]
{
	var idFields = zenPage.getComponentById("g1");
	idFields.setHidden(false);
	idFields.setProperty("label",id);
	zenPage.getComponentById('lst').resetOptions();
	zenPage.getComponentById('lstselect').resetOptions();
	var ok = this.UpdateDetails(id);
	this.showResult("");
}

ClientMethod doView(option) [ Language = javascript ]
{
	var url = "";
	switch (option) {
		case '1':
			url = this.LogsPage;
			break;
		case '2':
			url = this.TasksPage;
			break;
	}
	document.location = url;
}

/// disable or enable buttons for MapAll and SelectAll
ClientMethod toggleMapAll(flag) [ Language = javascript ]
{
	zenPage.getComponentById("btnMapAll").setProperty("disabled",flag);
	zenPage.getComponentById("btnSelAll").setProperty("disabled",flag);
}

/// Show or hide tree.
ClientMethod expandNode(node) [ Language = javascript ]
{
	var tree = zenPage.getComponentById("tree");
	tree.toggleExpanded(node);
}

/// load tree 
ClientMethod treeLoad() [ Language = javascript ]
{
	var tree = this.getComponentById('tree');
	tree.refreshContents();
}

/// After running action, display error message or refresh page.
ClientMethod displayResult(ok) [ Language = javascript ]
{
	if (ok != 1) {
		alert(ok);
	} else {
		zenPage.gotoPage(this.ParentURL);		
	}
}

/// Update action result. If text is passed in, show it. Otherwise set it to nothing.
ClientMethod showResult(text) [ Language = javascript ]
{
	zenPage.getComponentById("idAdded").setValue(text);
}

/// Set Locator bar and determine whether to show change password option.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	
	Do ..LoadProperties()

	Set ..lblTitle = $ZCVT($$$FormatText($$$Text("The FileMan wizard will help you map FileMan files to InterSystems classes. (Namespace %1)"),$namespace),"O","HTML")

	If $O(%session.Data("FileMan","")) '= "" {
		Set ..%GetComponentById("btnNext2").disabled = 0
	}
	Set ..DefaultLogFile = ..Link("UtilFileManLog.csp")

	Quit 1
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("FileMan Wizard")
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("SQL","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($classname(),"O","URL")_".zen?$NAMESPACE="_$G(%session.Data("$NAMESPACE"))))
	Quit $$$OK
}

/// Actually write out result.
/// When the page is first opened, seed is null.
/// When it's called from Prepare, seed = action^the selected locale.
Method DrawResult(seed As %String) As %Status
{
	If seed = "" Quit $$$OK
	Set $ZT = "Trap"
	Do {
		Set isFinish = $P(seed,"^",1)
		Set filename = $P(seed,"^",2)
		Set job = $P(seed,"^",3)
		&html<<pre class="brownnote">>
		If isFinish = "0" Write !,$$$FormatText($$$Text("Map all files with filename begin with %1."),$zconvert(filename,"O","HTML"))
		Else  Write !,$$$TextHTML("Map selected files.")
		Write !,$$$FormatText($$$Text("Background job, %1, started."),$zconvert(job,"O","HTML"))
		Set tLink = ..Link("/csp/sys/%25CSP.UI.Portal.BackgroundTaskList.zen")
		Set msg = $$$TextHTML("Click here to view the background tasks page.")
		&html<<br><a href="#(tLink)#" target="newWin">#(msg)#</a>>
		&html<</pre>>

	} While(0)
Done
	Quit $$$OK
Trap
	Set $ZT=""	
	Write !,$$$Text("Error occurred"),": ",$zconvert($ZE,"O","HTML"),!
	Goto Done
}

/// Clear cart completely.
ClassMethod ClearCart() As %Boolean [ ZenMethod ]
{
	Kill %session.Data("FileMan")
	Quit 1
}

/// Remove a selection from cart.
ClassMethod RemoveCart(pid) As %String [ ZenMethod ]
{
	Kill %session.Data("FileMan",pid)
	Quit ..HasSelection()
}

ClassMethod HasSelection() As %Boolean [ ZenMethod ]
{
	If $O(%session.Data("FileMan","")) '= "" Quit 1
	Quit 0
}

/// Select all files based on partial filename match.
ClassMethod SelectAll(filename As %String) As %String [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Set tRS = ##class(%ResultSet).%New("%FileMan.File:ListFilesByName")
		Set tSC = tRS.Execute(filename)
		If $$$ISERR(tSC) Quit
		Kill tParms,tItems
		Set tParms("NAMESPACE") = $namespace
		For  Quit:'tRS.Next()  If tRS.Data("NUMBER")'="" Set %session.Data("FileMan",tRS.Data("NUMBER")) = tRS.Data("NAME")
	} While (0)
Done
	If $$$ISERR(tSC) Quit $System.Status.GetErrorText(tSC)
	Quit $$$OK
Trap
	Set $ZT=""	
	Quit "Error occurred in SelectAll: "_$ZE
	Goto Done
}

/// Start background job to map one of the following:
/// 1) user has specific file selections (isFinish=1); or
/// 2) user clicked "Map All" to map all files in a particular (search) table (isFinish=0 and filename is not null).
ClassMethod MapSelected(proxy As %ZEN.proxyObject, isFinish, filename) As %String [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Kill tParms,tItems
		Set tParms("NAMESPACE") = $namespace
		// need to add code to go through Fields!!!
		If isFinish = 1 {
			Merge tItems = %session.Data("FileMan")
		} Else {
			Set tRS = ##class(%ResultSet).%New("%FileMan.File:ListFilesByName")
			Set tSC = tRS.Execute(filename)
			If $$$ISERR(tSC) Quit
			For  Quit:'tRS.Next()  If tRS.Data("NUMBER")'="" Set tItems(tRS.Data("NUMBER")) = ""		
		}
		If $O(tItems("")) '= "" {
			Set tParms("owner") = proxy.owner
			Set tParms("package") = proxy.package
			Set tParms("superClasses") = proxy.superClasses
			Set tParms("tableNameFormat") = proxy.tableNameFormat
			Set tParms("childTableNameFormat") = proxy.childTableNameFormat
			Set tParms("dateType") = proxy.dateType
			Set tParms("datetimeType") = proxy.datetimeType
			Set tParms("strictData") = proxy.strictData
			Set tParms("expandPointers") = proxy.expandPointers
			Set tParms("expandSetOfCodes") = proxy.expandSetOfCodes
			Set tParms("variablePointerValueField") = proxy.variablePointerValueField
			Set tParms("setOfCodesEnum") = proxy.setOfCodesEnum
			Set tParms("requiredType") = proxy.requiredType
			Set tParms("extendedMapping") = proxy.extendedMapping
			Set tParms("ienFieldName") = proxy.ienFieldName
			Set tParms("retainClass") = proxy.retainClass
			Set tParms("recursion") = proxy.recursion
			Set tParms("wpIsList") = proxy.wpIsList
			Set tParms("readonly") = proxy.readonly
			Set tParms("logFile") = proxy.logFile
			Set tParms("compile") = proxy.compile
			Set tParms("compileQSpec") = proxy.compileQSpec
			Set tParms("deleteQSpec") = proxy.deleteQSpec
			Set tParms("display") = proxy.display
		
 			Set status = ##class(%CSP.UI.System.BackgroundTask).RunTask("FileMan",tParms("NAMESPACE"),.tParms,.tItems,.tJob)
			Kill %session.Data("FileMan")
		} 
	} While (0)
	If $O(tItems("")) = "" Quit $$$Text("No files selected.")
Done
	If $$$ISERR(tSC) Quit $System.Status.GetErrorText(tSC)
	Quit +$G(tJob)
Trap
	Set $ZT=""	
	Quit "Error occurred in MapSelected: "_$ZE
	Goto Done
}

/// Final call from the background job to create classes.
ClassMethod CreateClasses(ByRef pParms As %String, ByRef pItems As %String) As %Status
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		Kill pFields,tItems
		Set EventDesc = "FileMan"
		Set EventData = "FileMan files:"_$$$CRLF
		Set tItem = ""
		For  Set tItem = $O(pItems(tItem)) Quit:tItem=""  If pItems(tItem) '= "" Set tValue = pItems(tItem) For cnt=2:1:$L(tValue,"^") Set tField=$P(tValue,"^",cnt) If $P(tField,"|")'="" Set tFields(tItem,$P(tField,"|")) = 0
 		Do $$$PatEventRows(.EventData,.pItems)
 		$$$SMPAuditChange
 		Do ##class(%SYSTEM.OBJ.FM2Class).Some(.pItems,.pParms,.tFields,.classCount)
 		Set tClassCreated = $$$FormatText($$$Text("%1 classes created"),classCount)
 		Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details") = ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Details")_" "_tClassCreated
		Set ^|"%SYS"|IRIS.Temp.MgtPortalTask($J,"Status") = $$$Text("Done")
	} While(0)
Done
	Quit tSC
Trap
	Set $ZT=""	
	Do ##class(%CSP.UI.SQL.LinkWizardResultPage).LogMsg($ZE,"ERROR")
	Goto Done
}

/// If pSelected is null, then map all fields.
/// pSelected is a string with fields delimited by "^" with the first piece to be the NAME of the file.
ClassMethod SaveToCart(pid, pSelected) [ ZenMethod ]
{
	Set %session.Data("FileMan",pid) = pSelected
}

/// Load fields into Available/Selected list boxes.
ClassMethod UpdateDetails(pid) As %Boolean [ ZenMethod ]
{
	Set $ZT = "Trap"
	Set tSC = $$$OK
	Do {
		#; Check if this file has already been selected. If yes, whether it has specific fields mapped.
		Set tSelected = $P($G(%session.Data("FileMan",pid)),"^",2,999)
		Set tField = ""
		For cnt = 1:1 Set tField = $P(tSelected,"^",cnt) Quit:tField=""  If $P(tField,"|")'="" Set tFields($P(tField,"|")) = 0
		Set tRS = ##class(%ResultSet).%New("%FileMan.Field:AllFieldsByName")
		Set tSC = tRS.Execute(pid)
		If $$$ISERR(tSC) Quit
		While tRS.Next() {
			Set tText = $ZCVT(tRS.Data("NAME"),"O","JS") _ "("_tRS.Data("NUMBER")_")"
			If tSelected=""!(tSelected'=""&($G(tFields(tRS.Data("NUMBER")))=0)) {
				&js< zenPage.getComponentById("lstselect").appendOption('#(tRS.Data("NUMBER"))#','#(tText)#'); >
			} Else {
				&js< zenPage.getComponentById("lst").appendOption('#(tRS.Data("NUMBER"))#','#(tText)#'); >				
			}
		}

	} While (0)
Done
	If $$$ISERR(tSC) Quit $System.Status.GetErrorText(tSC)
	Quit $$$OK
Trap
	Set $ZT=""	
	Write !,"Error occurred in UpdateDetails: ",$zconvert($ZE,"O","HTML"),!
	Goto Done
}

ClassMethod GetText(pid) As %String [ ZenMethod ]
{
	If pid = "" Quit pid
	Set tText = $$$FormatText($$$Text("%1 added to cart."),pid)
	Quit tText
}

/// Build tree for cart. If specific numbers are selected show them in sub tree.
/// The first piece of %session.Data("FileMan",t) is NAME of the file
ClassMethod GetTreeInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set PID = $O(%session.Data("FileMan",""))
	If PID = "" Quit 1
	Set lblSelected = $$$Text("Selected Files")
	Set pTree(0,"ch",1) = ""
	Set pTree(1) = $LB(lblSelected,"Selected Files",1,"",1,,"")
	Set tItem = 2
	Set tExpanded = 0
	#; Find the total number of files so the sub tree's beginning number can be determined
	Set t = "" For tTotal=2:1 Set t=$O(%session.Data("FileMan",t)) Quit:t=""
	While PID '= "" {
		Set pTree(1,"ch",tItem) = ""		
		Set t1 = %session.Data("FileMan",PID)
		Set tName = "("_PID_") "_$P(t1,"^",1)
		Set tChildren = $S($P(t1,"^",2)="":0,1:1)
		#; $LB(text,value,haschildren,link,expanded,icon,tooltip,style)
		Set tNode = tItem-1
		Set tLink = $S(tChildren:"javascript:zenPage.expandNode('"_tNode_"')",1:"")
		Set pTree(tItem) = $LB(tName,PID,tChildren,tLink,tExpanded,,PID)
		Set tSub = 2
		Set tTS = $P(t1,"^",tSub)
		While tTS '= "" {
			Set tNumber = $P(tTS,"|",1)
			Set pTree(tTotal) = $LB($P(tTS,"|",2),tNumber,0,"",tExpanded,,tNumber)
			Set pTree(tItem,"ch",tTotal) = ""
			Set tSub = tSub + 1
			Set tTS = $P(t1,"^",tSub)
			Set tTotal = tTotal + 1
		}
		Set PID = $O(%session.Data("FileMan",PID))	
		Set tItem = tItem + 1	
	}
	Quit $$$OK
}

/// check total Abstract Syntax tree count for presentation context.
/// this method is triggled from onupdate from the tree control.
ClientMethod treeCount() [ Language = javascript ]
{
	if (zenPage.getComponentById("tree").getProperty("nodeCount")<1) {
		//this.toggleDelete(true);
	} else {
		//this.toggleDelete(false);
	}
}

/// show or hide image and link Delete for presentation context
ClientMethod toggleDelete(flag) [ Language = javascript ]
{
	zenPage.getComponentById('imgDelete').setHidden(flag);
	zenPage.getComponentById('linkDelete').setHidden(flag);
}

/// Examine if user hit the Return key. If yes, start the search.
/// This method handles all keydown events on the window. 
ClientMethod onkeydownHandler(evt) [ Language = javascript ]
{
	//Works for both IE and NS.
	if (13 == evt.keyCode) {
		this.doSearch();
	}
	return true;
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnViewLog",$$$Text("View Log"),$$$Text("To view the default log file"),"zenPage.doView('1');")
	Set pCommands(2) = $LB("btnViewTasks",$$$Text("View Background Tasks"),$$$Text("To view the background tasks"),"zenPage.doView('2');")

	Quit $$$OK
}

}
