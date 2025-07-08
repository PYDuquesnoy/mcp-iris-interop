/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - OAuth2 List page
Class %CSP.UI.Portal.OAuth2.Client.ServerList Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "OAuth 2.0 Client Descriptions";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.OAuth2.Client.ServerList.zen";

Parameter HELPADDRESS = "System Administration,Security,OAuth 2.0,Client";

/// Security requirement
Parameter RESOURCE = "%Admin_OAuth2_Client";

Property EditPage As %String [ InitialExpression = {..Link("%25CSP.UI.Portal.OAuth2.Client.ServerConfiguration.zen",,1)} ];

Property ClientPage As %String [ InitialExpression = {..Link("%25CSP.UI.Portal.OAuth2.Client.ConfigurationList.zen",,1)} ];

/// Store translated targetCol linkCaption for <condition>
Property colDelete As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Delete")} ];

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
queryClass="OAuth2.ServerDefinition"
queryName="List"
showValueInTooltip="true"
showZebra="true"
valueColumn="IssuerEndpoint"
useSnapshot="true"
>
<column colName="ID" header="ID" hidden="true" />
<column colName="IssuerEndpoint" header="Issuer Endpoint" link="#" onclick="javascript:zenPage.doEdit('#(%query.ID)#','#(%query.IssuerEndpoint)#');" />
<column id="colClients" linkCaption="Client Configurations" link="javascript:zenPage.showClients('#(%query.ID)#','#(%query.IssuerEndpoint)#');" style="text-align:center;" />
<column colName="ClientCount" header="Client Count" style="text-align:left;"/>
<column id="colDelete" linkCaption="Delete" link="javascript:zenPage.deleteSetting('#(%query.ID)#');" linkConfirm="Are you sure you want to delete server configuration '%1'?" style="text-align:center;" />
<parameter value="*"/>
<condition colName="ClientCount" predicate="GT" value="0" cellStyle="disabled" targetCol="#(%page.colDelete)#"/> 
 </tablePane>
</vgroup>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..lblTitle = $$$Text("The following is a list of OAuth 2.0 server descriptions:")

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("OAuth 2.0 Client")
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
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
	Set pCommands(1) = $LB("btnAdd",$$$Text("Create Server Description"),$$$Text("Create a new OAuth 2.0 server description"),"zenPage.doNew();")

	Quit $$$OK
}

ClientMethod doNew() [ Language = javascript ]
{
	try {
		var url = this.EditPage + "isNew=1";
		this.gotoPage(url);
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod doEdit(IssuerEndpointID, IssuerEndpoint) [ Language = javascript ]
{
	try {
		var url = this.EditPage + "PID="+encodeURIComponent(IssuerEndpointID);
		this.gotoPage(url);
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod showClients(IssuerEndpointID, IssuerEndpoint) [ Language = javascript ]
{
	try {
		var url = this.ClientPage + "IssuerEndpointID="+encodeURIComponent(IssuerEndpointID) + "&IssuerEndpoint="+encodeURIComponent(IssuerEndpoint);
		this.gotoPage(url);
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Delete existing configuration.
ClientMethod deleteSetting(IssuerEndpointID) [ Language = javascript ]
{
	try {
		// need to temparily make changesMade to false so that onunload will not prompt
		var ok = this.DeleteItem(IssuerEndpointID);
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
	Set tSC = ##class(OAuth2.ServerDefinition).DeleteId(PID)
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
