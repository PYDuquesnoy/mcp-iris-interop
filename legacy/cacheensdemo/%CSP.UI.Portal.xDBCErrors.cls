/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Operations - xDBC Error Namespaces 
Class %CSP.UI.Portal.xDBCErrors Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 1;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.xDBCErrors.zen";

Parameter HELPADDRESS = "Home,System Logs,View xDBC Error Log";

Parameter PARENTPAGE = "/csp/sys/op/%CSP.UI.Portal.xDBCErrorNamespaces.zen";

/// Displayed name of this page.
Parameter PAGENAME = "xDBC Errors";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

Property AllowSelectRow As %ZEN.Datatype.boolean [ InitialExpression = "0" ];

Property NAMSPACE As %ZEN.Datatype.string(ZENURL = "$NAMESPACE");

Property CurrentColumn As %ZEN.Datatype.string [ InitialExpression = "DATE_TIME" ];

Property DetailsPage As %String [ InitialExpression = {$P(..Link("%25CSP.UI.Portal.xDBCErrors.zen"),"$NAMESPACE=",1)} ];

Property msgConfirm As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to delete the selected errors from this namespace?")} ];

XData Style
{
<style type="text/css">
/* additional style for table pane */
table.tpTable th {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}

table.tpTable td {
	border-right: 1px solid #F1F0E7;
	border-top: 1px solid #F1F0E7;
}
#htmlDetails {
	border: 1px solid #F1F0E7;
	width: 400px;
	height: 400px;
	overflow: auto;	
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<hgroup valign="top">
<vgroup valign="top">
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true"
onfilterChange="zenPage.filterChanged(value);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="Enter a partial string then hit [Tab] to filter the list." 
/>
<tablePane id="table"
queryClass="%SQL.Manager.Catalog"
queryName="XdbcErrors"
dataSource="columns"
fixedHeaders="false"
maxRows="1000"
multiSelect="true"
showValueInTooltip="false"
showZebra="true"
valueColumn="PROCESS_ID"
useSnapshot="true"
onselectrow="zenPage.doSelectRow(zenThis.getValue());"
>
<column colName="DATE_TIME" header="Date_Time"/>
<column colName="PROCESS_ID" hidden="true"/>
<column colName="SQLCODE" header="SQL Code"/>
<column colName="IRIS_ERROR" header="Error"/>
<column colName="LOCATION" header="Location"/>
<column colName="MESSAGE" header="Message"/>
<column colName="CONNECTION_INFO" header="Connection Information"/>
<column colName="PROTOCOL" header="Protocol"/>
<column colName="DisplayPID" header="Process ID"/>
<column linkCaption="Details" link="javascript:zenPage.doView('#(%query.PROCESS_ID)#');"
style="text-align:center;"/>
<parameter id="tnspace" value="#(%page.NAMSPACE)#"/>
<parameter id="tfilter" value="#(%page.Filter)#" />
 </tablePane>
 </vgroup>
 <spacer width="4"/>
 <vgroup id="idCode" valign="top" hidden="true">
<hgroup cellStyle="padding-right:10px;">
<checkbox id="chkAllowSelectRow" caption="show details when clicking on a row" captionClass="normal" onchange="zenPage.allowSelectRow(zenThis.getValue());"/>
</hgroup>
<html id="htmlDetails" OnDrawContent="DrawDetails"/>
</vgroup>
</hgroup>
</pane>
}

ClientMethod allowSelectRow(flag) [ Language = javascript ]
{
	this.AllowSelectRow = flag;
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value) [ Language = javascript ]
{
	var table = zen("table");
	table.parameters[1].value = value;
	table.executeQuery();
	table.currColumn = this.CurrentColumn;
	table.sortOrder = this.CurrentSort;	
	this.Filter = value;
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.updateTime();
	this.onresizeHandler();
}

/// This client event, if present, is fired when the page is resized.
ClientMethod onresizeHandler() [ Language = javascript ]
{
		return;

	// calculate width and height for iframe's size.
	var winWidth = zenGetWindowWidth();
	var winHeight = zenGetWindowHeight();
	var wd = (winWidth / 2) - 200;
	var ht = winHeight - 210;	
	if (wd < 100) wd = 100;
	if (ht < 100) ht = 100;
	var frame = zen("output");
	frame.setProperty("width",wd+"px");
	frame.setProperty("height",ht+"px");
}

ClientMethod doSelectRow(processId) [ Language = javascript ]
{
	if (this.AllowSelectRow) this.doView(processId);
	return;
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..%GetComponentById("Text1").value = $$$FormatText($$$Text("ODBC or JDBC errors in namespace %1:"),$namespace)

	Quit $$$OK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("System Logs")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("View xDBC Error Log")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnDelete",$$$Text("Delete"),$$$Text("Delete selected xDBC errors in current namespace"),"zenPage.doDelete();")
	Quit $$$OK
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("xDBC Errors")
}

/// show details of a particular error
ClientMethod doView(processId) [ Language = javascript ]
{
	try {
		zen('idCode').setHidden(false);	
		var html = zen("htmlDetails");
		html.seed = processId;
		html.refreshContents();
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Update table.
ClientMethod updateView() [ Language = javascript ]
{
	window.location.reload();
}

ClientMethod doDelete() [ Language = javascript ]
{
	var table = zen("table");
	var selectedRows = table.getProperty("selectedRows");
	var selected = "";
	var count = 0;
	var rows = selectedRows.split(",");
	for (var i=0; i<rows.length; i++) {
		if (rows[i]!="") {
			selected = selected + rows[i] + ",";	
			count++;
		}
	}
	if (selected == "") {
		alert($$$Text("No process selected."));
		return;
	} else {
		var msg = this.msgConfirm;
		if (confirm(msg) == false) {
			return;
		}
	}
	var ok = this.Delete(selected);
	if (ok != "") {
		alert(ok);
		return;	
	} else {
		this.updateView();
	}
}

/// Delete selected errors now.
ClassMethod Delete(selectedRows) As %String [ ZenMethod ]
{
	Set tTotal = $L(selectedRows,",")
	For tItem = 1:1:tTotal {
		Set tProc = $P(selectedRows,",",tItem)
		If tProc '= "" {
			Do KillLastErrorOne^%SYS.SQLSRV(tProc)
		}
	}
	Quit ""
}

ClassMethod DrawDetails(pProcess) As %Status
{
	Quit:pProcess="" 1
	If pProcess '= "" {
		Set Error = $G(^%sqlcq($namespace,"LastError",pProcess))
		Set tmsg = ""
	} Else {
		Set Error=""
		Set tmsg = $$$TextHTML("Process ID unavailable. Unable to get xDBC error details.")
	}
	&html<<h5>#($$$Text("Namespace"))#: #($namespace)#<br/>>
	&html<#($$$Text("Process"))#: #($zconvert(pProcess,"O","HTML"))#<br/>>
	&html<#($$$Text("Error"))#:</h5>>	
	&html<#($ZCVT(Error,"O","HTML"))#>
	If tmsg '= "" &html<<div class="rednote">#(tmsg)#</div>>
	Quit 1
}

}
