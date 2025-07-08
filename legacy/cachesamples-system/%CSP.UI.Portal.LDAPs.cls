/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Security Management - LDAPs
Class %CSP.UI.Portal.LDAPs Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.LDAPs.zen";

Parameter HELPADDRESS = "Home,Security Management,Security LDAP configurations";

Parameter EMSSERVICE = "Users";

/// Displayed name of this page.
Parameter PAGENAME = "Security LDAP Configs";

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
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true" 
onfilterChange="zenPage.filterChanged(value);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="To filter: enter one or more characters of the configuration name followed by [Tab]. Star '*' defaults to all."/>
<tablePane id="table" cellSpacing="2"
queryClass="Security.LDAPConfigs"
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
<column colName="Name" header="Login Domain Name" link="#" onclick="javascript:zenPage.doEdit('#(%query.Name)#');"
title="Edit configuration definition"/>
<column colName="LDAP Enabled" header="LDAP Enabled"/>
<column colName="Description" header="Description"/>
<column id="Delete" link="javascript:zenPage.doDelete('#(%query.Name)#');" linkCaption="Delete" style="text-align:center;" linkConfirm="Are you sure you want to delete configuration '%1'?" hidden="#(%page.IsEMSReadOnly)#"/>
 </tablePane>
 </group>
</pane>
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

ClientMethod doTest(LDAP) [ Language = javascript ]
{
	var url = zenLink('%25CSP.UI.Portal.LDAPTest.zen?PID='+encodeURIComponent(LDAP));
	this.gotoPage(url);
}

ClientMethod doEdit(LDAP) [ Language = javascript ]
{
	var url = zenLink('%25CSP.UI.Portal.LDAP.zen?PID='+encodeURIComponent(LDAP));
	this.gotoPage(url);
}

ClientMethod doDelete(LDAP) [ Language = javascript ]
{
	var result = this.Delete(LDAP);
	if (result.ok != 1) alert(result.ErrorMessage);
	var table = zen("table");
	table.executeQuery(0);
}

ClassMethod Delete(LDAP As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = ##Class(Security.LDAPConfigs).Delete(LDAP)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = $ZCVT($System.Status.GetErrorText(Error.AsStatus()),"O","JS")
	}
	Quit tProxy
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

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()
	d ##Class(Security.System).Get(,.Properties)
	i $zb(+Properties("AutheEnabled"),$$$AutheKB,1) {
		Set pCommands(1) = $LB("btnNew",$$$Text("Create New LDAP/Kerberos configuration"),$$$Text("Create a new security LDAP and Kerberos configuration"),"zenPage.doEdit('');")
		Set pRibbonTitle = "Security LDAP/Kerberos Configs"
	} else { 
		Set pCommands(1) = $LB("btnNew",$$$Text("Create New LDAP configuration"),$$$Text("Create a new security LDAP configuration"),"zenPage.doEdit('');")
	}
	#; commands: $LB(id,caption,help,onclick)
	Set pCommands(2) = $LB("btnTest",$$$Text("Test LDAP Authentication"),$$$Text("Test authentication of an LDAP user"),"zenPage.doTest('');")
	
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

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

}
