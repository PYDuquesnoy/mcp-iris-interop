/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - Privileged Routine Applications 
Class %CSP.UI.Portal.Applications.PrivRoutineList Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav, %CSP.UI.Portal.Applications.Utils) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Applications.PrivRoutineList.zen";

Parameter HELPADDRESS = "System Administration,Security,Applications,Privileged Routine Applications";

Parameter EMSSERVICE = "Security";

/// Displayed name of this page.
Parameter PAGENAME = "Privileged Routine Applications";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property ApplicationType As %Integer [ InitialExpression = {$$$AppTypePrivRoutine} ];

Property EditPage As %String [ InitialExpression = {..Link("%25CSP.UI.Portal.Applications.PrivRoutine.zen",,1)} ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<vgroup id="idTable">
<tableNavBar showFilter="false" showPageSize="true" tablePaneId="table" showMaxRows="true"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table" cellSpacing="2"
queryClass="Security.Applications"
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
OnExecuteResultSet="ExecuteApplicationList"
>
<column colName="Name" header="Name" id="NameCol" link="#" onclick="javascript:zenPage.doEdit('#(%query.Name)#');"
title="View or edit application security authorization"/>
<column colName="Enabled" header="Enabled" title="Indicates that this item is enabled."/>
<column colName="Resource" header="Resource" title="Resource used to control access for this item."/>
<column id="LinkDelete" link="javascript:zenPage.doDelete('#(%query.Name)#')" linkCaption="Delete" style="text-align:center;" hidden="#(%page.IsEMSReadOnly)#"/>
<parameter value="*"/>
<parameter value="#(%page.ApplicationType)#"/>
<parameter value=""/>
</tablePane>
</vgroup>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..%GetComponentById("Text1").value = $$$Text("The following is a list of Privileged Routine applications that are currently defined:")
	
	Set ..%GetComponentById("LinkDelete").linkConfirm = ..msgConfirm

	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	#; commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnNew",$$$Text("Create New Privileged Routine Application"),$$$Text("Create a new Privileged Routine application definition"),"zenPage.doEdit('');")

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Privileged Routine Applications")
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
/// Subclasses with extra layers of locator links or other than "Configuration" please override.
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
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_NAMESPACE)))
	Quit $$$OK
}

}
