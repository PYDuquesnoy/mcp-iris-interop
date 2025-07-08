/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Configuration - ECP - Application Servers 
Class %CSP.UI.Portal.ECPAppServers Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.ECPAppServers.zen";

Parameter HELPADDRESS = "Home,Configuration,ECP Settings,ECP Application Servers";

Parameter EMSSERVICE = "Config";

/// Displayed name of this page.
Parameter PAGENAME = "ECP Application Servers";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.ECP.zen";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

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
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:10px;">
<group id="pageContainer">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<tableNavBar showFilter="false" showPageSize="true" tablePaneId="table" showMaxRows="true" 
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane
id="table" onheaderClick="return zenPage.columnSort(zenThis.getProperty('currColumn'),zenThis.getProperty('sortOrder'));"
cellSpacing="2"
queryClass="SYS.ECP"
queryName="ClientList"
dataSource="columns"
maxRows="1000"
pageSize="0"
multiSelect="false"
showZebra="true"
useSnapshot="true"
width="800px"
>
<column colName="Client Name" header="Client Name"/>
<column colName="Status" header="Status"/>
<column colName="IP Address" header="Client IP"/>
<column colName="IP Port" header="IP Port"/>
</tablePane>
<group id="ECPSSL">
<group id="ECPSSLPending">
<label id="Text2" value="" containerStyle="padding-bottom:4px;"/>
<tablePane
id="pendtable"
cellSpacing="2"
queryClass="SYS.ECP"
queryName="SSLPendingConnections"
dataSource="columns"
maxRows="1000"
pageSize="0"
multiSelect="false"
showZebra="true"
useSnapshot="true"
width="800px"
>
<column colName="SSLComputerName" header="SSL Computer Name"/>
<column colName="ClientIP" header="Incoming IP"/>
<column name="Authorize" linkCaption="Authorize" link="javascript:zenPage.doAuthorize('#(%query.SSLComputerName)#',1);" style="text-align:center;"/>
<column name="Reject" linkCaption="Reject" link="javascript:zenPage.doAuthorize('#(%query.SSLComputerName)#',0);" style="text-align:center;"/>
</tablePane>
</group>
<group id="ECPSSLAuthorized">
<label id="Text3" value="" containerStyle="padding-bottom:4px;"/>
<tablePane
id="authtable"
cellSpacing="2"
queryClass="SYS.ECP"
queryName="SSLAuthorizedConnections"
dataSource="columns"
maxRows="1000"
pageSize="0"
multiSelect="false"
showZebra="true"
useSnapshot="true"
width="800px"
>
<column colName="SSLComputerName" header="SSL Computer Name"/>
<column name="Delete" linkCaption="Delete" link="javascript:zenPage.doDelete('#(%query.SSLComputerName)#');" style="text-align:center;"/>
</tablePane>
</group>
</group>
</group>
</pane>
}

ClientMethod doAuthorize(CN, authorize) [ Language = javascript ]
{
	var text;
	if (authorize == 1) {
		text = $$$Text("Are you sure you want to authorize SSLComputerName '%1'?");
	} else {
		text = $$$Text("Are you sure you want to reject SSLComputerName '%1'?");
	}
	text = text.replace('%1',CN);
	if (confirm(text)) {
		var st = zenPage.AuthorizeCN(CN,authorize);
		if (st == 1) {
			zenPage.updateView(false);
		} else {
			alert(st);	
		}
	}
}

ClientMethod doDelete(CN) [ Language = javascript ]
{
	var	text = $$$Text("Are you sure you want to delete authorized SSLComputerName '%1'?");
	text = text.replace('%1',CN);
	if (confirm(text)) {
		var st = zenPage.DeleteCN(CN);
		if (st == 1) {
			zenPage.updateView(false);
		} else {
			alert(st);	
		}
	}
}

ClientMethod updateView(InTimer) [ Language = javascript ]
{
	var table = zen("table");
	table.executeQuery();
	table.currColumn = this.CurrentColumn;
	table.sortOrder = this.CurrentSort;
	var query = zenPage.DrawECPSSL();
	if (query == 1) {
		zen("pendtable").executeQuery();
	} else if (query == 2) {
		zen("authtable").executeQuery();
	} else if (query == 3) {
		zen("pendtable").executeQuery();
		zen("authtable").executeQuery();
	}
	this.updateTime();
}

ClassMethod AuthorizeCN(CN As %String, authorize As %Integer) As %String [ ZenMethod ]
{
 	#; This method returns 1 = success; 0,errormsg = fail
 	Set tSC = ##class(SYS.ECP).RemoveFromPendingList(CN,authorize)
 	Quit +tSC
}

ClassMethod DeleteCN(CN As %String) As %String [ ZenMethod ]
{
 	Set tSC = ##class(SYS.ECP).RemoveAuthorizedCN(CN)
 	Quit +tSC
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..%GetComponentById("Text1").value = $$$Text("The following is a list of ECP application servers that are connected to this system:")
	#;SML2649+	
	Set ..%GetComponentById("Text2").value = $$$Text("The following is a list of pending ECP application servers to be authorized or rejected:")	
	Set ..%GetComponentById("Text3").value = $$$Text("The following is a list of authorized SSL Computer Names for ECP application servers:")	
	Do ..DrawECPSSL()
	#;SML2649-
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
	
	Set tPageName = $$$Text("Configuration","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = $$$Text("ECP Settings","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("ECP Application Servers")
}

Method DrawECPSSL() As %Integer [ ZenMethod ]
{
	s rset=##class(%ResultSet).%New("SYS.ECP:SSLPendingConnections")
	d rset.Execute()
	s pendcnt=rset.Next()
	s rset=##class(%ResultSet).%New("SYS.ECP:SSLAuthorizedConnections")
	d rset.Execute()
	s authcnt=rset.Next()
	k rset
	Set ret = 0
	if 'pendcnt&&'authcnt {
		Set ..%GetComponentById("ECPSSL").hidden = 1
	} else {
		Set ..%GetComponentById("ECPSSL").hidden = 0
		if 'pendcnt {
			Set ..%GetComponentById("ECPSSLPending").hidden = 1
		} else {
			Set ..%GetComponentById("ECPSSLPending").hidden = 0
			Set ret = 1
		}
		if 'authcnt {
			Set ..%GetComponentById("ECPSSLAuthorized").hidden = 1
		} else {
			Set ..%GetComponentById("ECPSSLAuthorized").hidden = 0
			Set ret = ret + 2
		}
	}
	Quit ret
}

}
