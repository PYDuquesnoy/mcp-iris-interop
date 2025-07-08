/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - SQL Performance Tool - Troubleshooting Report Loader
Class %CSP.UI.Portal.SQL.QButtons.ReportLoader Extends (%CSP.UI.Template.Property, %CSP.UI.Portal.SQL.QButtons.Utils) [ System = 4 ]
{

/// Switch namespace $NAMESPACE is present
Parameter AUTONS As BOOLEAN = 1;

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.SQL.QButtons.ReportLoader.zen";

Parameter HELPADDRESS = "Home,Import SQL Troubleshooting Report";

/// Displayed name of this page.
Parameter PAGENAME = "SQL.QButtons.ReportLoader";

/// Security requirement
Parameter RESOURCE = "%Development";

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

Property msgConfirm As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you wish to import customer report into namespace %1?")} ];

XData Style
{
<style type="text/css">
/* make the Create New Namespace link more visible */
body { 
	font-size: 1em;
}
a.link {
	font-size: 12px;
	text-decoration: underline;	
}
#output {
	min-width:  300px;
	min-height: 300px;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding-top:10px;padding-left:20px;">
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-left:10px;"/>
<hgroup cellStyle="padding-top: 10px;">
<label label="Step-1. You may wish to load the report into a new namespace. Click the link to create a new namespace first:" labelClass="caption"/>
<link id="linkNamespace" caption="Create New Namespace" title="Go to the new namespace page to create a new namespace." href="" />
</hgroup>

<spacer height="2"/>

<hgroup cellStyle="padding-top: 10px;">
<label label="Step-2. Switch to the Namespace where you wish to load the report. Click the link 'Switch' to select a namespace." labelClass="caption"/>
</hgroup>

<vgroup cellStyle="padding-top:10px;">
<label label="Step-3. Enter the file name and then click the 'Import' button." labelClass="caption"/>

<vgroup cellStyle="padding-left:40px;">
<hgroup label="File Name" cellVAlign="top" labelPosition="left" >
<text id="FileName" size="70" value="" hint="Enter the path and name of the XML file where the troubleshooting report resides" hintClass="helpText"/>
<button caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('FileName','*.xml');"/>
</hgroup>
<spacer height="10"/>
<iframe id="output" hidden="true"/>
</vgroup>
</vgroup>

</pane>
}

/// User clicked the Browse button.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	var Dir = zen(name).getValue();
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.cls?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard,'FileSelect','resizable,width=680,height=750');
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {		
	
		this.adjustSizes();	
	
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		
		var frame = zen("output");
		var frameWidth = winWidth - 300;
		frameWidth = Math.max(frameWidth,100);
		frame.setProperty("width",frameWidth + "px");
		var frameHeight = winHeight - 400;
		frameHeight = Math.max(frameHeight,100);
		frame.setProperty("height",frameHeight + "px");

	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen("FileName").focus();
}

ClientMethod doAction(action) [ Language = javascript ]
{
	this.resetMsg();
	var filename = zen("FileName").getValue();
	if (filename == "") {
		this.showMsg($$$Text("File name is empty. Please enter a file name."),true);
		zen("FileName").focus();
		return false;
	}
	if (action == "import") {
		var msg = this.msgConfirm.replace("%1",this.NAMESPACE);
		var msg = msg + "\n\n" + $$$Text("Importing may take a few seconds and result will be displayed on the page.");
		if (!confirm(msg)) {
			return;
		}
	} 
	zen('output').setHidden(false);
	var url = "_CSP.UI.Portal.SQL.QButtons.ReportLoaderOutput.zen?FILENAME=" + encodeURIComponent(filename)+"&$NAMESPACE=" + encodeURIComponent(this.NAMESPACE) + '&ACTION=' + action;	
	zen('output').setProperty('src',url);
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..%GetComponentById("Text1").value = $$$Text("Use this page to import a SQL troubleshooting report from a customer.")
	
	Set %page.NAMESPACE = $G(%request.Data("$NAMESPACE",1))
	If %page.NAMESPACE = "" Set %page.NAMESPACE = $namespace

	Set ..%GetComponentById("linkNamespace").href = ..Link("/csp/sys/mgr/%25CSP.UI.Portal.Namespace.zen")
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnSQL",$$$Text("SQL Home"),$$$Text("Goto the SQL Home page"),"zenPage.gotoPToolsPage('sqlhome');")
	Set pCommands(2) = $LB("btnImport",$$$Text("Import"),$$$Text("Import report now"),"zenPage.doAction('import');")
	Set pCommands(3) = $LB("btnPreview",$$$Text("View File Details"),$$$Text("View report details"),"zenPage.doAction('view');")

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Import Report")
}

///  Return the array of links to show in the locator bar.<br/>
///  pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("SQL Performance Tools","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_NAMESPACE)))
	Quit $$$OK
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") return;
	switch(popupName) {
	case 'switchNamespace':
		var url = zenPage.GetNewURL(value,"%25CSP.UI.Portal.SQL.QButtons.ReportLoader.zen");
		this.NAMESPACE = value;
		// do not use this.gotoPage(url) because zenLink will not honor the latest $NAMESPACE you selected, i.e. you may end up with multiple $NAMESPACE on the URL.
		self.document.location = url;
		break;
	case 'FileSelect':
		zen('FileName').setValue(value);
		this.resetMsg();
		break;
	}
}

}
