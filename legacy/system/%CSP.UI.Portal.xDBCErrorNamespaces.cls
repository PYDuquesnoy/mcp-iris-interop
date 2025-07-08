/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Operations - xDBC Error Namespaces 
Class %CSP.UI.Portal.xDBCErrorNamespaces Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.xDBCErrorNamespaces.zen";

Parameter HELPADDRESS = "Home,System Logs,View xDBC Error Log";

/// Displayed name of this page.
Parameter PAGENAME = "xDBC Error Namespaces";

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

Property CurrentColumn As %ZEN.Datatype.string [ InitialExpression = "NAMESPACE" ];

Property ErrorPage As %String [ InitialExpression = {$P(..Link("%25CSP.UI.Portal.xDBCErrors.zen"),"$NAMESPACE=",1)} ];

Property msgConfirm As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to delete all errors from the the selected namespaces?")} ];

XData Style
{
<style type="text/css">
/* additional style for table pane */
#table {
	width: 60%;	
}
table.tpTable th {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}

table.tpTable td {
	border-right: 1px solid #F1F0E7;
	border-top: 1px solid #F1F0E7;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<tableNavBar showPageSize="true" tablePaneId="table" showMaxRows="true"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table"
queryClass="%SQL.Manager.Catalog"
queryName="NamespacesWithXdbcErrors"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
multiSelect="true"
showValueInTooltip="false"
showZebra="true"
valueColumn="NAMESPACE"
useSnapshot="true"
>
<column colName="NAMESPACE" header="Namespace"/>
<column linkCaption="View" link="javascript:zenPage.doView('#(%query.NAMESPACE)#');"
style="text-align:center;"/>

 </tablePane>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..%GetComponentById("Text1").value = $$$Text("The following namespaces contain ODBC or JDBC errors::")

	Quit $$$OK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set tPageName = $$$Text("System")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("System Logs")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = $$$Text("View xDBC Error Log")
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($classname(),"O","URL")_".zen"))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnDelete",$$$Text("Delete"),$$$Text("Delete all xDBC errors in selected namespace"),"zenPage.doDelete();")
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
	Quit $$$Text("xDBC Error Log")
}

/// show errors for selected namespace
ClientMethod doView(namespace) [ Language = javascript ]
{
	try {
		this.gotoPage(this.ErrorPage+"?$NAMESPACE="+encodeURIComponent(namespace));
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
		alert($$$Text("No namespaces selected."));
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

/// Delete selected namespaces now.
ClassMethod Delete(selectedRows) As %String [ ZenMethod ]
{
	Set tmsg = ""
	Set TotalSelected = 0
	Set tTotal = $L(selectedRows,",")
	For tItem = 1:1:tTotal {
		Set NMS = $P(selectedRows,",",tItem)
		If NMS '= "" {
			Set TotalSelected = TotalSelected + 1
			Do KillLastErrorAll^%SYS.SQLSRV(NMS)
		}
	}
	If TotalSelected = 0 Quit $$$Text("No namespaces selected.")
	Quit tmsg
}

}
