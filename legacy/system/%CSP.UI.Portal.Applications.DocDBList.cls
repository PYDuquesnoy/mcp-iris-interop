/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Security Management - Doc DB Applications 
Class %CSP.UI.Portal.Applications.DocDBList Extends %CSP.UI.Portal.Audit.EventsTemplate [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Applications.DocDBList.zen";

Parameter HELPADDRESS = "System Administration,Security,Applications,Configure Doc DB Applications";

Parameter EMSSERVICE = "Security";

/// Displayed name of this page.
Parameter PAGENAME = "Doc DB Applications";

Property msgConfirm As %String [ InitialExpression = {$$$TextJS("Are you sure you want to delete Doc DB application '%1'?")} ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<vgroup id="idTable">
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true" maxRows="1000" 
onfilterChange="zenPage.filterChanged(value,zenThis.tablePaneId);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
 title="To filter: enter one or more characters of any column followed by [Tab]."/>
<tablePane id="table" 
queryClass="Security.DocDBs"
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
<column colName="Name" header="Name" id="NameCol" link="#" onclick="javascript:zenPage.doEdit('#(%query.Name)#','#(%query.Namespace)#');" title="View or edit Doc DB application security authorization"/>
<column colName="Namespace" header="Namespace" title="Namespace associated with this item."/>
<column colName="Enabled" header="Enabled" title="Indicates that this item is enabled."/>
<column colName="Resource" header="Resource" title="Resource used to control access for this item."/>
<column colName="Description" header="Description" title="Description of the Doc DB application."/>
<column id="LinkDelete" link="javascript:zenPage.doDelete('#(%query.Name)#','#(%query.Namespace)#')" linkCaption="Delete" style="text-align:center;" hidden="#(%page.IsEMSReadOnly)#"/>
<parameter value="*"/>
<parameter value="*"/>
<parameter value="#(%page.Filter)#"/>
</tablePane>
</vgroup>
</pane>
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value, tableID) [ Language = javascript ]
{
	var table = zen(tableID);
	if (value=="*") value="";
	//Filter is 3rd parameter
	table.parameters[2].value = value;
	table.executeQuery();
	table.currColumn = this.CurrentColumn;
	table.sortOrder = this.CurrentSort;
	this.Filter = value;
	this.UpdateTableNavState(value,this.TablePageSize,this.TableMaxRows);
}

ClientMethod doEdit(Name, Namespace) [ Language = javascript ]
{
	var url = zenLink('%25CSP.UI.Portal.Applications.DocDB.zen?PID='+encodeURIComponent(Name+"&"+Namespace));
	this.gotoPage(url);
}

ClientMethod doDelete(Name, Namespace) [ Language = javascript ]
{
	var result = this.Delete(Name,Namespace);
	if (result.ok != 1) alert(result.ErrorMessage);
	var table = zen("table");
	table.executeQuery(0);
}

ClassMethod Delete(Name As %String, Namespace As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = ##Class(Security.DocDBs).Delete(Name,Namespace)
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
	Set ..%GetComponentById("Text1").value = $$$Text("The following is a list of Doc DB applications that are currently defined:")

	Set ..%GetComponentById("LinkDelete").linkConfirm = ..msgConfirm
	i ..Filter="*" s ..Filter=""

	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	#; commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnNew",$$$Text("Create New Doc DB Application"),$$$Text("Create a new Doc DB Aplication"),"zenPage.doEdit('','');")
	
	Quit $$$OK
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

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Doc DB Applications")
}

}
