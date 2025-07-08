/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal
Class %CSP.UI.Portal.Installs Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Installs.zen";

Parameter HELPADDRESS = "Home,Provider,Installs";

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Installs";

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
queryClass="Provider.Installs"
queryName="List"
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
<column colName="Name" header="Name"/>
<column colName="Description" header="Description"/>
<column colName="Product" header="Product"/>
<column colName="Version" header="Version"/>
<column colName="BuildNumber" header="BuildNumber"/>
<column colName="Platform" header="Platform"/>
<column colName="Type" header="Type"/>
<column colName="TarFile" header="TarFile"/>
<column linkCaption="Edit" link="%25CSP.UI.Portal.Install.zen?PID=#(%query.Name)#" />
<column id="colDelete" linkCaption="Delete" link="javascript:zenPage.deleteSetting('#(%query.Name)#');" linkConfirm="Are you sure you want to delete Install '%1'?" />
 </tablePane>
</vgroup>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..lblTitle = $$$Text("The following is a list of Provider Installs:")

	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Provider Installs")
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Provider Management","%Utility") 
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

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnAdd",$$$Text("Create New Provider Installs"),$$$Text("Create a new Provider Install"),"zenPage.doNew();")

	Quit $$$OK
}

/// Used to draw title for this page. pHalpAddress is need to build the link for Help for this page.
ClassMethod DrawTitle1(pSeed As %String) As %Status
{
	Do %application.DrawTitle(%page.LocatorHeader_"^"_%page.HelpAddress)
	Quit $$$OK
}

/// User clicked the "Edit" link which is there for clearity and consistency. No need to do anything here as onselectrow is going to kick in.
ClientMethod doNew() [ Language = javascript ]
{
	try {
		this.gotoPage("%25CSP.UI.Portal.Install.zen?isNew=1");
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// User clicked the "Edit" link which is there for clearity and consistency. No need to do anything here as onselectrow is going to kick in.
ClientMethod editSetting(PID) [ Language = javascript ]
{
	try {
		this.gotoPage("%25CSP.UI.Portal.Install.zen?PID="+encodeURIComponent(PID));
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Delete existing mapping.
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
	Set tSC = ##class(Provider.Installs).Delete(PID)
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
