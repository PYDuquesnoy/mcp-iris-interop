/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - Configuration - Source Control
Class %CSP.UI.Portal.SourceControl Extends %CSP.UI.Template.List
{

/// Allow to change namespaces for this page.
Parameter AUTONS As BOOLEAN = 1;

/// Displayed name of this page.
Parameter PAGENAME = "Source Control Settings";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.SourceControl.zen";

Parameter HELPADDRESS = "Home,Configuration,Source Control Settings";

Property FILETYPE As %String [ InitialExpression = "SourceControl" ];

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property NSSelected As %String;

Property TotalNamespaces As %Integer;

Property TitleMsg As %String [ InitialExpression = {$$$Text("The source control for namespace %1 is defined below.")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* light purple for Administration pages. 
   See %CSP.UI.Portal.Utils for Operations
   See %CSP.UI.Template.List and %CSP.UI.Template.Property for Explorer pages 
.ribbonTitle {
	background: #D2CFDF;
}*/
table.NSTable {
	font-size: 0.8em;
}

td.NSNormal {
	cursor: hand;
	padding: 5px;
}

td.NSSelected {
	background: rgb(249,243,204);
	cursor: hand;
	font-size: 12pt;
	font-weight: bold;
	padding: 5px;
}
table.DetailTable	{ 
	border: 1px #888888 solid;
	font-size: 0.9em;
}
table.DetailTable th {
	background:white;
	color: #888888;
	font-weight: bold;
	padding: 5px;
	text-align: center;
}
table.DetailTable td { 
	padding: 4px;
}
</style>
}

XData searchPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding: 2px 10px;"  >
<text id="txtSpec" label="NAMESPACES" onchange="zenPage.doFilter();" 
title="Enter a partial name to filter the namespace list. Case insensitive." />
<html id="menuGroup" OnDrawContent="DrawMenu"/>
</pane>
}

XData resultPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<label id="Text1" value="" containerStyle="padding-left:10px;"/>
<hgroup>
<vgroup id="idTable" valign="top">
</vgroup>
<vgroup valign="top" cellStyle="padding-left:10px;">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-left:10px;padding-bottom:2px;"/>
<label id="lblEditTitle" controlClass="editTitle" value=""/>
<html id="htmlSCContent" OnDrawContent="DrawSCContent"/>
</vgroup>
</hgroup>
</pane>
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Source Control Settings")
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..%GetComponentById("Text1").value = $$$FormatText($$$Text("The source control for namespace %1 is defined below."),$Namespace)

	Set (..%GetComponentById("txtSpec").value, ..%GetComponentById("menuGroup").seed) = $G($$$IRISTempMgt($Username,"Source Control Settings"))
	Quit $$$OK
}

Method OnDrawRibbon() As %Status
{
	Quit $$$OK
}

/// Draw the contents of the Table Header (the region between the diagram and the table).
Method DrawTableHeader(pSeed As %String) As %Status
{
	Quit 1
}

/// Draw Namespaces list in the search pane. If pSeed is not null, then show only those that match it.
Method DrawMenu(pSeed) As %Status
{
	Set $$$IRISTempMgt($Username,"Source Control Settings") = pSeed
	&html<<table class="NSTable" cellspacing="8">>
	Set tCnt = ##class(%CSP.Util.SMNavigatorPane).GetAllNamespaces(.Namespaces)
	If pSeed '= "" {
		Set tTotal = 0
		Set lSeed = $ZCVT(pSeed,"L")
		For i=1:1:tCnt If $ZCVT(Namespaces(i),"L") [ lSeed Set tTotal = tTotal + 1 Set nms(tTotal) = Namespaces(i)
		Kill Namespaces
		Merge Namespaces = nms
		Set tCnt = tTotal
	}
	Set %page.TotalNamespaces = tCnt
	For i=1:1:tCnt {
		Set menuId = "menu_"_i
		Set cls = $S(Namespaces(i) = $Namespace:"NSSelected",1:"NSNormal")
		&html<<tr><td id="#(menuId)#" onclick="zenPage.doNamespace('#(i)#','#($ZCVT(Namespaces(i),"O","JS"))#');" class="#(cls)#" onmouseover="style.color='rgb(218,72,72)';style.cursor='pointer';" onmouseout="style.color=''" >#($ZCVT(Namespaces(i),"O","HTML"))#</td></tr>> 
	}
	&html<</table>>
	Quit 1
}

/// Draw html content for source control for current or selected namespace.
Method DrawSCContent(pNamespace) As %Status
{
	If pNamespace = "" Set pNamespace = $Namespace
	Set tNone = $$$Text("NONE")
	Set cmdDocumentation = $$$Text("Documentation")
	Set linkDoc1 = $P(##class(%CSP.Page).Link("/csp/sys/exp/UtilExpClass.csp"),"$NAMESPACE",1)_"?$NAMESPACE="_$zconvert(pNamespace,"O","URL")
	Set (CurrentSource,tCurrentSource) = ##class(%Studio.SourceControl.Interface).SourceControlClassGet(pNamespace)
	If CurrentSource = "" Set tCurrentSource = tNone
	&html<<h3>#($$$Text("Current source control class:"))# &nbsp; #($ZCVT(tCurrentSource,"O","HTML"))#</h3>>
	&html<<p>#($$$Text("To change the class, check the radio button of the name from the following list then click the [Save] button."))#</p>>
	&html<<form id="SCForm" name="SCForm"><table class="DetailTable" border="1" cellpadding="2" cellspacing="0" >>
	&html<<tr><th>#($$$Text("Source Control Class Name"))#</th><th>#($$$Text("Description"))#</th>>
	&html<<tr><td class="DetailValue">
	<input type="radio" id="Choices" name="Choices" value="" #($S(CurrentSource="":"checked",1:""))# onclick="javascript:zenPage.scChanged(this.value);">#(tNone)#</td><td class="DetailValue">&nbsp;</td></tr>>
	If pNamespace '= $namespace {
		Set tOldNamespace = $namespace
		Set $Namespace = pNamespace	
	}
	Set tRS = ##class(%ResultSet).%New("%Studio.SourceControl.Interface:ExtensionClasses")
	Do tRS.Execute()
	While tRS.Next() {
		Set name = tRS.GetData(1)
		Set linkDoc2 = linkDoc1_"&$ID1="_name
		&html<<tr><td nowrap class="DetailValue" ><input type="radio" name="Choices" value="#(name)#" #($S(CurrentSource=name:"checked",1:""))# onclick="javascript:zenPage.scChanged(this.value);">#($ZCVT(name,"O","HTML"))#</td>>
		&html<<td nowrap class="DetailValue" valign="bottom"><a href="#(linkDoc2)#" target="top">#($ZCVT(cmdDocumentation,"O","HTML"))#<a></td></tr>>
	}
	&html<</table></form>>

	If $G(tOldNamespace) Set $Namespace = tOldNamespace
	
	Quit $$$OK
}

/// User wants to filter namespaces list.
ClientMethod doFilter() [ Language = javascript ]
{
	var value = zen("txtSpec").getValue();
	var html = zen("menuGroup");
	html.seed = value;
	html.refreshContents();
}

/// Get user input and send to server to save settings.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		// if user has not changed anything then quit
		if (!this.pageModified) return true;
		// now get the selected namespace and the new value and save
		var namespace = this.NSSelected;
		var form = self.document.getElementById("SCForm");
		var len = form.Choices.length;
		var value = "";
		for (var n=0; n<len; n++) {
			if (form.Choices[n].checked) value = form.Choices[n].value;
		}
		var proxy = this.SaveData(namespace,value);
		if (proxy.ok == 1) {
			this.setModified(false);
			this.updateSCContent(namespace);
			return true;
		} else {
			this.showMsg(proxy.ErrorMessage,1);
			return false;
		}
	} 
  catch(ex) {
	alert("ERROR: " + ex);
	}
}

/// User clicked on a new namespace. Check if user has unsaved changes. If yes, then prompt to save. 
ClientMethod doNamespace(menuIndex, namespace) [ Language = javascript ]
{
	// If save fails, message is displayed and abort going to new namespace.
	if (this.pageModified) {
		var msg = $$$Text("Save change first?");
		if (confirm(msg)) {
			if (!this.doSave()) return;
		} else {
			this.setModified(false);
		}
	}
	/// display source control info for the newly selected namespace.
	var msg = this.TitleMsg;
	msg = msg.replace("%1",namespace);
	zen("Text1").setValue(msg);
	var total = this.TotalNamespaces;
	var tclass = "";
	for (var m = 1; m <= total; m++) {
		tclass = (m != menuIndex) ? "NSNormal" : "NSSelected";
		self.document.getElementById("menu_"+m).className = tclass;
	}
	this.updateSCContent(namespace);
	this.NSSelected = namespace;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.showExpand();
	this.adjustSizes();
	zen("txtSpec").focus();
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	this.adjustSizes();
}

ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var searchDiv = zen('searchPane').getEnclosingDiv();
		searchDiv.style.display = 'block';
		var menuDiv = zen('menuGroup').getEnclosingDiv();
		
		// find size of window
		var winWidth = zenGetWindowWidth();
		var winHeight = zenGetWindowHeight();
		var propWidth = (this.searchExpanded) ? 180 : 5;
		searchDiv.style.width = propWidth + 'px';
		var propHeight = winHeight - 180;
		propHeight = Math.max(propHeight,100);
		menuDiv.style.height = propHeight + 'px';

	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

ClientMethod scChanged(scValue) [ Language = javascript ]
{
	this.doModified();
}

/// Given the newly seleted namespace, update the source control content
ClientMethod updateSCContent(namespace) [ Language = javascript ]
{
	var html = zen("htmlSCContent");
	html.seed = namespace;
	html.refreshContents();
}

ClassMethod SaveData(namespace, value) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error"
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set status = ##class(%Studio.SourceControl.Interface).SourceControlClassSet(value,namespace)
	If $$$ISERR(status) {
		Set tProxy.ErrorMessage = $System.Status.GetErrorText(status)
	} Else {
		Set tProxy.ok = 1
	}
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
