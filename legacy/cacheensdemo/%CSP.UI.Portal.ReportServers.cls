/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Report Server
Class %CSP.UI.Portal.ReportServers Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Reports (Logi Analytics)";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.ReportServers.zen";

Parameter HELPADDRESS = "Home,Configuration,Reports (Logi Analytics)";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

XData Style
{
<style type="text/css">
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<spacer height="10" />
<label id="idRespond" enclosingClass="errorNote" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<tableNavBar showFilter="false" showMaxRows="true" showPageSize="true" tablePaneId="table"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table"
queryClass="%Report.ServerDefinition"
queryName="ByName"
dataSource="columns"
fixedHeaders="false"
ondblclick="javascript:zenPage.doEdit();"
pageSize="0"
maxRows="1000"
showValueInTooltip="false"
showZebra="true"
valueColumn="ID"
useSnapshot="true"
width ="600"
>
<parameter value="" />
<column colName="ID" hidden="true"/>
<column colName="Name" header="Name"/>
<column colName="Host" header="Host"/>
<column colName="Port" header="Port" style="text-align: left;"/>
<column linkCaption="Edit" link="#" onclick="zenPage.doEdit(#(%query.ID)#);"/>
<column linkCaption="Configure" link="#" onclick="zenPage.doConfigure(#(%query.ID)#);"/>
 </tablePane>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
    Set (..LocatorHeader,..StdTitle) = $$$Text("InterSystems Reports")
	Set ..lblTitle = $$$Text("Server definitions define how to connect to InterSystems Reports, powered by Logi Analytics" _ $CHAR(174) _ ". A list of defined report servers is shown below:")
	
	Quit $$$OK
}

/// Add a new row
ClientMethod doAdd() [ Language = javascript ]
{
	try {
		zenPage.gotoPage('%25CSP.UI.Portal.ReportServer.zen?isNew=1');
	} catch (ex) {
		zenPage.showMsg("Error: " + ex);	
	}
}

/// Edit the current row
ClientMethod doEdit(PID) [ Language = javascript ]
{
	if (PID === undefined) {
		var PID = zenPage.getComponentById('table').getValue();
	}
	
	try {
		zenPage.gotoPage('%25CSP.UI.Portal.ReportServer.zen?PID='+encodeURIComponent(PID));
	} catch (ex) {
		zenPage.showMsg('Error: ' + ex);	
	}
}

ClientMethod doConfigure(PID) [ Language = javascript ]
{
    if (PID === undefined) {
        var PID = zenPage.getComponentById('table').getValue();
    }
    try {
        zenPage.gotoPage('%25CSP.UI.Portal.ReportServerConfiguration.zen?PID='+encodeURIComponent(PID));
    } catch (ex) {
        zenPage.showMsg('Error: ' + ex);    
	}
}

///  Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick,disabled)
	Set pCommands(1) = $LB("btnAdd",$$$Text("New Report Server"),$$$Text("Add a new server definition"),"zenPage.doAdd();")

	Quit $$$OK
}

}
