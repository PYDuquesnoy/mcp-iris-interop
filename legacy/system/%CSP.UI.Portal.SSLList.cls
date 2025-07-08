/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - SSL/TLS Configurations List
Class %CSP.UI.Portal.SSLList Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ System = 4 ]
{

/// Class name of application this page belongs to.
/// Parameter APPLICATION = "%CSP.UI.Portal.Application";
/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "SSL/TLS Configurations";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.SSLList.zen";

Parameter HELPADDRESS = "System Administration,Security,SSL/TLS Configurations";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property EditPage As %String [ InitialExpression = {..Link("%25CSP.UI.Portal.SSL.zen",,1)_"isNew=1"} ];

Property EditPageMirror As %String [ InitialExpression = {..Link("%25CSP.UI.Portal.SSL.zen",,1)_"PID=%25MirrorServer"} ];

/// Store translated targetCol linkCaption for <condition>
Property colDelete As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Delete")} ];

Property colEdit As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Edit")} ];

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
queryClass="Security.SSLConfigs"
queryName="List"
showValueInTooltip="true"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
>
<column colName="Name" header="Name" OnDrawCell="DrawName"/>
<column colName="Description" header="Description"/>
<column colName="Enabled" header="Enabled"/>
<column colName="Type" header="Type"/>
<column colName="EnabledInternal" hidden="true"/>
<column colName="TypeInternal" hidden="true"/>
<column linkCaption="Edit" link="%25CSP.UI.Portal.SSL.zen?PID=#(%query.Name)#" />
<column id="colDelete" linkCaption="Delete" link="javascript:zenPage.deleteSetting('#(%query.Name)#');" linkConfirm="Are you sure you want to delete configuration '%1'?" />
<parameter value="*"/>
<condition colName="Name" predicate="EQ" value="%MirrorClient" cellStyle="disabled" targetCol="#(%page.colEdit)#"/> 
<condition colName="Name" predicate="EQ" value="%MirrorServer" cellStyle="disabled" targetCol="#(%page.colEdit)#"/> 
<condition colName="Name" predicate="EQ" value="%MirrorClient" cellStyle="disabled" targetCol="#(%page.colDelete)#"/> 
<condition colName="Name" predicate="EQ" value="%MirrorServerX" cellStyle="disabled" targetCol="#(%page.colDelete)#"/> 
<condition colName="Name" predicate="EQ" value="%MirrorServerX" cellStyle="disabled" targetCol="#(%page.colEdit)#"/> 

 </tablePane>
</vgroup>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..lblTitle = $$$Text("The following is a list of SSL/TLS configurations:")
	
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("SSL/TLS Configurations")
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
	Set pCommands(1) = $LB("btnAdd",$$$Text("Create New Configuration"),$$$Text("Create a new SSL/TLS configuration"),"zenPage.doNew(0);")

	// If service for Mirror is enabled, and %MirrorClient is not defined, then show Mirror link. OW, hide it.
	If $$IsMirrorServiceEnabled^MIRRORCTL(),'..MirrorManaged() {
		Set caption = $$$Text("Create Configurations for Mirror")
		If ($$$ISOK(##class(SYS.MirrorConfiguration).DoSSLConfigurationsExist())) Set caption = $$$TextHTML("Edit Configurations for Mirror")
		Set pCommands(2) = $LB("btnAddMirror",caption,caption,"zenPage.doNew(1);")
	}
	Quit $$$OK
}

ClassMethod DrawName(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Write ..EscapeHTML(%query("Name"))
	#; signal to disable edit/delete columns
	If %query("Name")="%MirrorServer",..MirrorManaged() {
		Set %query("Name")="%MirrorServerX"
	}
	Quit $$$OK
}

ClientMethod doNew(isMirror) [ Language = javascript ]
{
	try {
		var url = (!isMirror) ? this.EditPage : this.EditPageMirror;
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
	Set tSC = ##class(Security.SSLConfigs).%DeleteId(PID)
	If $$$ISERR(tSC) {
		Set ok = $System.Status.GetErrorText(tSC)
	} Else {
		Set ok = 1
		//%MirrorClient and %MirrorServer should be deleted together.		
		If PID = "%MirrorServer" {
			Set tSC = ##class(Security.SSLConfigs).%DeleteId("%MirrorClient")
			If $$$ISERR(tSC) Set ok = $System.Status.GetErrorText(tSC)		
		}
	}
	Quit ok
Error	///
	Set $ZT="" Do BACK^%ETN
	Quit $ZCVT($ZE,"O","JS")
}

ClassMethod MirrorManaged() As %Boolean [ ZenMethod ]
{
	;Quit ##class(EMS.Instance).Restricted("Config.Mirrors")
	q 0
}

}
