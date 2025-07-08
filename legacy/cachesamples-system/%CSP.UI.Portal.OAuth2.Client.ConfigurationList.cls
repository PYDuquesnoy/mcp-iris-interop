/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - OAuth2 List page
Class %CSP.UI.Portal.OAuth2.Client.ConfigurationList Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "OAuth 2.0 Client Configurations";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.OAuth2.Client.ConfigurationList.zen";

Parameter HELPADDRESS = "System Administration,Security,OAuth 2.0 Client Configurations,Client Configurations";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.OAuth2.Client.ServerList.zen";

/// Security requirement
Parameter RESOURCE = "%Admin_OAuth2_Client";

Property EditPage As %String [ InitialExpression = {..Link("%25CSP.UI.Portal.OAuth2.Client.Configuration.zen",,1)} ];

/// IssuerEndpointID of the Server for client list.
Property IssuerEndpointID As %String(ZENURL = "IssuerEndpointID");

/// IssuerEndpoint of the Server for client list.
Property IssuerEndpoint As %String(ZENURL = "IssuerEndpoint");

XData Style
{
<style type="text/css">
/* additional style for table pane */
table.tpTable th {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}

table.tpTable td {
	border: 1px solid #F1F0E7;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<vgroup id="idTable">
<tableNavBar id="tableBar" showFilter="false" showMaxRows="true" showPageSize="true" tablePaneId="table" containerStyle="padding-bottom:4px;"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table"
pageSize="0"
maxRows="1000"
fixedHeaders="false"
queryClass="OAuth2.Client"
queryName="ListForServer"
showValueInTooltip="true"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
>

<column colName="ApplicationName" header="Application Name" link="#" onclick="javascript:zenPage.doEdit('#(%query.ApplicationName)#','#(%page.IssuerEndpointID)#','#(%page.IssuerEndpoint)#');"/>
<column colName="ClientType" header="Client Type" />
<column colName="DefaultScope" header="Default Scope"/>
<column id="colDelete" linkCaption="Delete" link="javascript:zenPage.deleteSetting('#(%query.ApplicationName)#');" linkConfirm="Are you sure you want to delete configuration '%1'?" />
<parameter value="#(%page.IssuerEndpointID)#"/>
 </tablePane>
</vgroup>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..lblTitle = $$$FormatText($$$Text("The following is a list of OAuth 2.0 Client configurations for server %1:"),%page.IssuerEndpoint)
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Client Configurations")
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("OAuth 2.0 Client","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnAdd",$$$Text("Create Client Configuration"),$$$Text("Create a new OAuth 2.0 Client configuration for server"),"zenPage.doNew('"_..EscapeHTML(%page.IssuerEndpointID)_"','"_..EscapeHTML(%page.IssuerEndpoint)_"');")

	Quit $$$OK
}

ClientMethod doNew(IssuerEndpointID, IssuerEndpoint) [ Language = javascript ]
{
	try {
		var url = this.EditPage + "isNew=1" + "&IssuerEndpointID="+encodeURIComponent(IssuerEndpointID) + "&IssuerEndpoint="+encodeURIComponent(IssuerEndpoint);
		this.gotoPage(url);
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod doEdit(ApplicationName, IssuerEndpointID, IssuerEndpoint) [ Language = javascript ]
{
	try {
		var url = this.EditPage + "PID="+encodeURIComponent(ApplicationName) + "&IssuerEndpointID="+encodeURIComponent(IssuerEndpointID) + "&IssuerEndpoint="+encodeURIComponent(IssuerEndpoint);
		this.gotoPage(url);
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Delete existing configuration.
ClientMethod deleteSetting(PID) [ Language = javascript ]
{
	try {
		// need to temparily make changesMade to false so that onunload will not prompt
		var ok = this.DeleteItem(PID);
		if (ok == 1) {
			var table = zenPage.getComponentById('table');
			table.setProperty("selectedIndex",-1);
			table.executeQuery();
		} else {
			alert(ok);
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Call server delete method.
ClassMethod DeleteItem(PID) As %String [ ZenMethod ]
{
	Set $ZT="Error"
	Set tSC = ##class(OAuth2.Client).DeleteId(PID)
	If $$$ISERR(tSC) {
		Set ok = $System.Status.GetErrorText(tSC)
	} Else {
		Set ok = 1
	}
	Quit ok
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit $ZCVT($ZE,"O","JS")
}

}
