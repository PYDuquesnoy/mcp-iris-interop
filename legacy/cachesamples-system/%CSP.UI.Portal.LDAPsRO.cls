/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Security Management - LDAPsRO
Class %CSP.UI.Portal.LDAPsRO Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.LDAPsRO.zen";

Parameter HELPADDRESS = "Home,View LDAP configurations";

Parameter EMSSERVICE = "Users";

/// Displayed name of this page.
Parameter PAGENAME = "Security LDAP Configs";

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

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
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true" 
onfilterChange="zenPage.filterChanged(value);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="To filter: enter one or more characters of the configuration name followed by [Tab]. Star '*' defaults to all."/>
<tablePane id="table" cellSpacing="2"
queryClass="%SYS.LDAP"
queryName="List"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="false"
valueColumn="Name"
useSnapshot="true"
>
<parameter value="#(%page.Filter)#"/>
<parameter value="1"/>
<column colName="Name" header="Login Domain Name" link="#" onclick="javascript:zenPage.doDisplay('#(%query.Name)#');"
title="Display configuration definition"/>
<column colName="LDAP Enabled" header="LDAP Enabled"/>
<column colName="Description" header="Description"/>
 </tablePane>
 </group>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	d ##Class(Security.System).Get(,.Properties)
	i $zb(+Properties("AutheEnabled"),$$$AutheKB,1) {
		Set ..lblTitle = $$$Text("The following user LDAP/Kerberos configurations are currently available:")
	} else {
		Set ..lblTitle = $$$Text("The following user LDAP configurations are currently available:")
	}
	
	Quit $$$OK
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value) [ Language = javascript ]
{
	var table = zen("table");
	table.parameters[0].value = value;
	table.executeQuery();
	this.Filter = value;
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);
}

ClientMethod doDisplay(LDAP) [ Language = javascript ]
{
	var url = zenLink('%25CSP.UI.Portal.LDAPRO.zen?PID='+encodeURIComponent(LDAP));
	this.gotoPage(url);
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	d ##Class(Security.System).Get(,.Properties)
	i $zb(+Properties("AutheEnabled"),$$$AutheKB,1) {
		Quit $$$Text("Security LDAP/Kerberos configurations")
	} else {
		Quit $$$Text("Security LDAP configurations")
	}
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

}
