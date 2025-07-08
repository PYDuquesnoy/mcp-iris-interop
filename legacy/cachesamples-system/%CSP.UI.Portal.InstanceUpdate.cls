/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal 
Class %CSP.UI.Portal.InstanceUpdate Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Create Instances";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.InstanceUpdate.zen";

Parameter HELPADDRESS = "Home,Provider,InstanceUpdate";

Parameter PARENTPAGE = "/csp/sys/mgr/%CSP.UI.Portal.Instances.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property isNew As %ZEN.Datatype.boolean(ZENURL = "isNew") [ InitialExpression = "0" ];

/// ID for edit. Null if adding new credentials.
Property PID As %String(ZENURL = "PID");

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
<select id="InstallKit" label="Install kit to install" hint="Required." onchange="zenPage.doModified();"/>
<label id="Text2" value="Updating the following instances:" containerStyle="padding-bottom:4px;"/>
<tableNavBar id="tableBar" showFilter="false" showMaxRows="true" showPageSize="true" tablePaneId="table" containerStyle="padding-bottom:4px;"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table"
queryClass="Provider.Instances"
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
<column colName="MachineName" header="Machine Name"/>
<column colName="InstanceName" header="Instance Name"/>
<column colName="Directory" header="Directory"/>
<column colName="LastInstall" header="Last Install"/>
<column colName="LastInstallTime" header="Last Install Time"/>
<column colName="LastInstallUsername" header="Last Install Username"/>
<column colName="State" header="State"/>
<column colName="Status" header="Status" hidden="true"/>
<column colName="Error" header="Error"/>
<column colName="CacheGroup" header="CacheGroup"/>
<column colName="CacheUser" header="CacheUser"/>
<column colName="ManagerGroup" header="ManagerGroup"/>
<column colName="SecurityType" header="SecurityType"/>
<column colName="Unicode" header="Unicode"/>
 </tablePane>
</vgroup>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	var PID = this.PID;
}

ClientMethod doModified() [ Language = javascript ]
{
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	If ..PID = "" Set ..isNew = 1
	Set Status = ..PopulateInstanceDropdown(.displayList,.valueList)
	i '$$$ISOK(Status) q Status
	Set ..lblTitle = $$$Text("Use the form below to update existing Provider Instances:")
	Set ..HelpAddress = "Home,Provider Management,Instances,Update Instances"
	Set ..%GetComponentById("InstallKit").displayList = displayList
	Set ..%GetComponentById("InstallKit").valueList = valueList

	Quit $$$OK
}

Method PopulateInstanceDropdown(Output displayList As %String, Output valueList As %String) As %Status
{
 Set (displayList,valueList) = ""
 Set Rset = ##class(%ResultSet).%New("Provider.Installs:List")
 i '$$$ISOK(Rset) d $SYSTEM.Status.DisplayError(%objlasterror) q
 s Status=Rset.Execute("*")
 i '$$$ISOK(Status) q Status
 While Rset.Next(.Status) {
	s Name=Rset.Data("Name")
	s Description= Rset.Data("Description")
	If valueList = "" {
		Set valueList = Name
		Set displayList = ..EscapeHTML(Name_" - "_Description)
	} Else {
		Set valueList = valueList_","_Name
		Set displayList = displayList_","_..EscapeHTML(Name_" - "_Description)
	}
 }
 Quit $$$OK
}

Method PopulateFields(ByRef Properties As %String) As %Status
{
	q 1
}

Method %OnGetPageName() As %String
{
 Quit $$$Text("New Provider Instances")
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Provider Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Instances","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_"?PID="_$ZCVT($G(%request.Data("PID",1)),"O","URL")))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnAdd",$$$Text("Upgrade Instances"),$$$Text("Upgrade Provider Instances"),"zenPage.doNew();")
	// commands: $LB(id,caption,help,onclick)
	Set pCommands(2) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return without saving new changes"),"zenPage.doCancel();")

	Quit $$$OK
}

/// Used to draw title for this page. pHalpAddress is need to build the link for Help for this page.
ClassMethod DrawTitle1(pSeed As %String) As %Status
{
	Do %application.DrawTitle(%page.LocatorHeader_"^"_%page.HelpAddress)
	Quit $$$OK
}

/// Get user selection and send to server to save settings.
ClientMethod doSave() [ Language = javascript ]
{
	var proxy = new zenProxy();
	proxy.LastInstall = zen('InstallKit').getValue();
	var Machines = "";
	var table = zen("table");
	var selectedRows = table.getProperty("selectedRows");
	var rows = selectedRows.split(",");
	for (var i=0; i<rows.length; i++) {
		Machines = Machines + rows[i] + ",";	
	}
	proxy.Machines = Machines;
	var result = this.SaveData(proxy);
	// saved existing app
	this.afterSave(result);
}

ClientMethod doCancel() [ Language = javascript ]
{
	this.setModified(false);
	var opener = this.getOpener();
	if (opener) {
		self.close();
	} else {
		self.document.location = this.ParentURL;
	}
}

/// Save general association data to server
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
		#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Try {
		Set Properties("LastInstall")=pProxy.LastInstall
		Set Properties("State")="Installing"
		f i=1:1:$l(pProxy.Machines,",") {
			s MachineName=$p(pProxy.Machines,",",i)
			i MachineName'="" {
				Set tSC = ##class(Provider.Instances).Create(MachineName,pProxy.InstanceName,.Properties)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
		}
		Set tProxy.ok = 1
	} Catch Error {
		d BACK^%ETN
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

}
