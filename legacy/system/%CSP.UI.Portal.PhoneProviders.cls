/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Security Management - Mobile Phone Service Providers
Class %CSP.UI.Portal.PhoneProviders Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.PhoneProviders.zen";

Parameter HELPADDRESS = "System Administration,Security,Mobile Phone";

Parameter EMSSERVICE = "Users";

/// Displayed name of this page.
Parameter PAGENAME = "Mobile Phone Service Providers";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

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
	border-bottom: 1px solid #F1F0E7;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<group>
<tableNavBar showFilter="false" showPageSize="true" tablePaneId="table" showMaxRows="true" maxRows="1000"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table" cellSpacing="2"
queryClass="%SYS.PhoneProviders"
queryName="List"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
>
<column colName="Name" id="NameCol" link="#" onclick="javascript:zenPage.doEdit('#(%query.Name)#');"/>
<column colName="SMSGateway" header="SMS Gateway"/>
<column id="Delete" link="javascript:zenPage.doDelete('#(%query.Name)#');" linkCaption="Delete" style="text-align:center;" linkConfirm="Are you sure you want to delete phone service provider '%1'?" hidden="#(%page.IsEMSReadOnly)#"/>
 </tablePane>
 </group>
</pane>
}

/// Delete selected provider
ClientMethod doDelete(provider) [ Language = javascript ]
{
	var ok = this.Delete(provider);
	if (ok != "") alert(ok);
	var table = zen("table");
	table.executeQuery(0);
}

ClientMethod doEdit(provider) [ Language = javascript ]
{
	var url = zenLink('%25CSP.UI.Portal.PhoneProvider.zen?PID='+encodeURIComponent(provider));
	this.gotoPage(url);
}

/// Delete selected provider now.
Method Delete(provider) As %String [ ZenMethod ]
{
	Set tResult = ""
	set tSC = ##Class(%SYS.PhoneProviders).Delete(provider)
	If $$$ISERR(tSC) {
		Set tResult = $ZCVT($System.Status.GetErrorText(tSC),"O","JS")
	}
	Quit tResult
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..lblTitle = $$$Text("The following mobile phone service providers are currently available:")
	If ..IsEMSReadOnly {
		Set NameCol = ..%GetComponentById("NameCol")
		Set (NameCol.onclick,NameCol.link) = ""
	}
	
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

	Set tPageName = $$$Text("Security Management","%Utility")
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

	#; commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnNew",$$$Text("Create New Provider"),$$$Text("Create a new phone provider definition"),"zenPage.doEdit('');")
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Mobile Phone Service Providers")
}

}
