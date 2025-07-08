/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Security Management - Services
Class %CSP.UI.Portal.Services Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Services.zen";

Parameter HELPADDRESS = "System Administration,Security,Services";

Parameter EMSSERVICE = "Security";

/// Displayed name of this page.
Parameter PAGENAME = "Services";

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
<hgroup valign="top">
<vgroup valign="top">
<tableNavBar showFilter="false" showMaxRows="true" showPageSize="true" tablePaneId="table"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table" cellSpacing="2"
queryClass="Security.Services"
queryName="Detail"
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
<parameter value="*"/>
<column colName="Name" header="Name" id="NameCol" link="#" onclick="javascript:zenPage.doEdit('#(%query.Name)#');"/>
<column colName="Enabled" header="Enabled"/>
<column colName="Public" header="Public"/>
<column colName="Authentication Methods" header="Authentication Methods"/>
<column colName="Allowed Connections" header="Allowed Connections"/>
<column colName="Description" header="Description"/>
<column colName="EnabledBoolean" hidden="true"/>
<column colName="HttpOnlyCookies" hidden="true"/>
<condition colName="EnabledBoolean" predicate="EQ" value="0" rowStyle="background: #CCCCCC;"/> 
 </tablePane>
 </vgroup>
</hgroup>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..lblTitle = $$$Text("Services are the primary means by which users and computers connect to InterSystems IRIS. The following services are currently available:")
	
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

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Services")
}

ClientMethod doEdit(service) [ Language = javascript ]
{
	var url = '%CSP.UI.Portal.Dialog.Service.zen?PID='+encodeURIComponent(service);
	zenLaunchPopupWindow(url,'ServiceEdit','status,scrollbars,resizable=yes,width=650,height=800');
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if ((action != 'ok') || (popupName != 'ServiceEdit')) return false;
	var table = zen("table");
	table.executeQuery(0);
	return true;
}

}
