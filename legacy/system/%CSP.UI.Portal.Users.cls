/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Security Management - Users
Class %CSP.UI.Portal.Users Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Users.zen";

Parameter HELPADDRESS = "System Administration,Security,Users";

Parameter EMSSERVICE = "Users";

/// Displayed name of this page.
Parameter PAGENAME = "Users";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

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
<tableNavBar id="tableNav" showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true" saveSizeMax="true"
onfilterChange="zenPage.filterChanged(value,zenThis.tablePaneId);" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
title="Enter the leading characters of a user's name followed by [Tab] to filter the list. For example: C for all user names starting with letter 'C'."/>
<tablePane id="table" cellSpacing="2"
queryClass="Security.Users"
queryName="Detail"
dataSource="columns"
fixedHeaders="false"
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
pageSize="0"
>
<parameter value="#(%page.Filter)#"/>
<parameter value="*"/>
<parameter value="*"/>
<parameter value="1"/>
<column colName="Name" header="Name" link="#" onclick="zenPage.doEdit('#(%query.Name)#');return false;"
title="Edit User definition"/>
<column colName="FullName" header="Full Name"/>
<column colName="Enabled" header="Enabled"/>
<column colName="Namespace" header="Namespace"/>
<column colName="Routine" header="Routine"/>
<column colName="Type" header="Type"/>
<column id="Delete" link="javascript:zenPage.doDelete('#(%query.Name)#');" linkCaption="Delete" style="text-align:center;" linkConfirm="Are you sure you want to delete user '%1'?" hidden="#(%page.IsEMSReadOnly)#"/>
<column id="Profile" link="javascript:zenPage.doProfile('#(%query.Name)#');" linkCaption="Profile" style="text-align:center;"/>
<condition colName="Name" predicate="EQ" value="_PUBLIC" cellStyle="disabled" targetCol="#(%page.colDelete)#"/>
<condition colName="Name" predicate="EQ" value="_SYSTEM" cellStyle="disabled" targetCol="#(%page.colDelete)#"/>
<condition colName="Name" predicate="EQ" value="UnknownUser" cellStyle="disabled" targetCol="#(%page.colDelete)#"/>
<condition colName="Name" predicate="EQ" value="_Ensemble" cellStyle="disabled" targetCol="#(%page.colDelete)#"/>
 </tablePane>
 </group>
</pane>
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value, tableID) [ Language = javascript ]
{
	var table = zen(tableID);
	table.parameters[0].value = value;
	table.executeQuery();
	this.Filter = value;
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);
}

ClientMethod doEdit(user) [ Language = javascript ]
{
	var url = '%25CSP.UI.Portal.User.zen?PID='+encodeURIComponent(user);
	this.gotoPage(url);
}

ClientMethod doProfile(user) [ Language = javascript ]
{
	var url = '%25CSP.UI.Portal.UserProfile.zen?PID='+encodeURIComponent(user);
	this.gotoPage(url);
}

ClientMethod doDelete(user) [ Language = javascript ]
{
	var result = this.Delete(user);
	if (result.ok != 1) alert(result.ErrorMessage);
	var table = zen("table");
	table.executeQuery(0);
}

ClassMethod Delete(user As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = ##class(Security.Users).Delete(user)
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
	Set ..lblTitle = $$$Text("The following is a list of user definitions:")
	
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	#; commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnNew",$$$Text("Create New User"),$$$Text("Create a new user"),"zenPage.doEdit('');")
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Users")
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
