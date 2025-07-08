/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - Resources 
Class %CSP.UI.Portal.Resources Extends %CSP.UI.Template.List [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Resources.zen";

Parameter HELPADDRESS = "System Administration,Security,Resources";

Parameter EMSSERVICE = "Security";

Property FILETYPE As %String [ InitialExpression = "Resource" ];

/// Displayed name of this page.
Parameter PAGENAME = "Managing Resources";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property msgConfirm As %String [ InitialExpression = {$$$TextJS("Are you sure you want to delete resource code %1?")} ];

Property msgDeleteMsgs As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to delete the selected %1 resource(s)?")} ];

Property msgDBDefault As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("(%DB_%DEFAULT cannot be deleted.)")} ];

/// Resource Name Spec on the Search pane. User can enter any of the following:<br/>
/// <ul>Names - Comma separated list of resource names
/// <li>"*" - All records match</li>
/// <li>"String,String1" - Any records matching one of these elements</li>
/// <li>"String*" - Any record starting with "String"</li>
/// <li>"String,String1*,String2" - Any record matching one of these elements, or starting with "String1"</li>
/// </ul>
Property Spec As %ZEN.Datatype.string [ InitialExpression = "*" ];

/// Read public permission on the Search pane. Default to checked.
Property PermissionRead As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Write public permission on the Search pane. Default to checked.
Property PermissionWrite As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Use public permission on the Search pane. Default to checked.
Property PermissionUse As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// No public permission on the Search pane. Default to checked.
Property PermissionNo As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Store translated targetCol linkCaption for <condition>
Property colDelete As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Delete")} ];

XData Style
{
<style type="text/css">

</style>
}

/// This pane displays the search criteria. We provide defaults and user can change them.
/// User's values are saved and used as future defaults for this user.
/// Subclass to override.
XData searchPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" >

<form name="searchForm" id="searchForm" layout="vertical" cellStyle="padding: 2px 10px; font-size:0.8em;">
<vgroup >
<checkbox id="PermissionRead" label="Public Permissions" labelClass="optionLabel" value="1" caption="Read" captionClass="optionLabel" title="Read public permissions" onclick="zenPage.doSearch();"/>
<checkbox id="PermissionWrite" value="1" caption="Write" captionClass="optionLabel" title="Write public permissions" onclick="zenPage.doSearch();"/>
<checkbox id="PermissionUse" value="1" caption="Use" captionClass="optionLabel" title="Use public permissions" onclick="zenPage.doSearch();"/>
<checkbox id="PermissionNo" value="1" caption="No permissions" captionClass="optionLabel" title="No public permissions" onclick="zenPage.doSearch();"/>
</vgroup>
<html><hr size="1"/></html>
<combobox id="txtSpec" label="Resource Name" labelClass="optionLabel" comboType="timer" editable="true" unrestricted="true" size="19"
title="Enter the first one or more characters then click Search. Enter '*' for all." value="*" onchange="zenPage.doSearch();"/>
<text id="maxRows" label="Maximum rows" labelClass="optionLabel" title="Maximum number of rows to load - cannot be greater than 10000" size="6" value="1000" onchange="zenPage.doSearch();" onkeyup="zenPage.keyUp(zenEvent);"/>

<!-- <button id="btnSearch" caption="Search" onclick="zenPage.doSearch();"/> -->
</form>

</pane>
}

XData resultPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:2px;">
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<tableNavBar showPageSize="true" tablePaneId="table"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);"
/>
<tablePane id="table"
queryClass="Security.Resources"
queryName="List"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
multiSelect="true"
showValueInTooltip="false"
showZebra="true"
valueColumn="Name"
useSnapshot="true"
OnExecuteResultSet="ExecuteRS"
>
<column colName="Name" header="Name"/>
<column colName="Description" header="Description"/>
<column colName="PublicPermission" header="Public Permission"/>
<column colName="Type" hidden="true"/>
<column colName="ResourceType" header="Resource Type"/>
<column linkCaption="Edit" id="LinkEdit" link="#" onclick="zenPage.doEdit('#(%query.Name)#');return false;"
style="text-align:center;" hidden="#(%page.IsEMSReadOnly)#"/>
<column linkCaption="Delete" id="LinkDelete" link="#" onclick="zenPage.doDelete('#(%query.Name)#');return false;"
style="text-align:center;" hidden="#(%page.IsEMSReadOnly)#"/>
<parameter value="*"/>
<parameter value="-1"/>
<parameter value="-1"/>
<parameter value="1"/>
<condition colName="Name" predicate="EQ" value="%DB_%DEFAULT" cellStyle="disabled" targetCol="#(%page.colDelete)#"/>
<condition colName="Name" predicate="EQ" value="%DB_IRISMETRICS" cellStyle="disabled" targetCol="#(%page.colDelete)#"/>

 </tablePane>
</pane>
}

/// User clicked Go to start search. 
ClientMethod doSearch() [ Language = javascript ]
{
	var spec = zen("txtSpec").getValue();
	if (spec=="") spec="*";
	zen("txtSpec").setValue(spec);
	this.Spec = spec;
	
	var maxRows = zenTrim(zen("maxRows").getValue());
	if ((maxRows == "") || (isNaN(maxRows)==true) || (parseInt(maxRows) > 10000)) {
		maxRows = 10000;
	} else {
		maxRows = Math.round(maxRows);
	}
	zen("maxRows").setValue(maxRows);	
	//zen("txtSpec").setProperty("valueList",RecentURLs);
	this.PermissionRead = (zen("PermissionRead").getValue() == true) ? 1 : 0;
	this.PermissionWrite = (zen("PermissionWrite").getValue() == true) ? 1 : 0;
	this.PermissionUse = (zen("PermissionUse").getValue() == true) ? 1 : 0;
	this.PermissionNo = (zen("PermissionNo").getValue() == true) ? 1 : 0;
	var ok = this.SaveSelections("Resources","-1",spec,this.PermissionRead,this.PermissionWrite,this.PermissionUse,this.PermissionNo,maxRows);
	var RecentURLs = this.GetRecentList("Resources");
	zen("txtSpec").setProperty("valueList",RecentURLs);
	var table = zen("table");
	table.setProperty("maxRows",maxRows);
	table.executeQuery();
}

/// Check if user hit [Enter].
ClientMethod keyUp(zenEvent) [ Language = javascript ]
{
	if ((zenEvent.which==13)||(zenEvent.keyCode==13)) {
		this.doSearch();
	}
}

Method GetLastSearch() As %String
{
	Set LastSearch = $G($$$IRISTempMgt($Username,"Resources"))
	If LastSearch = "" Set LastSearch = "-1^*^1^1^1^1^1000"
	If $P(LastSearch,"^",2) = "" Set $P(LastSearch,"^",2) = "*"
	Quit LastSearch
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..%GetComponentById("Text1").value = $$$Text("InterSystems IRIS resources provide access for users based on the rights they hold. The following resources are currently available:")
	
	Set LastSearch = ..GetLastSearch()
	Set (..Spec,..%GetComponentById("txtSpec").value) = $P(LastSearch,"^",2)
	Set (..PermissionRead,..%GetComponentById("PermissionRead").value) = $P(LastSearch,"^",3)
	Set (..PermissionWrite,..%GetComponentById("PermissionWrite").value) = $P(LastSearch,"^",4)
	Set (..PermissionUse,..%GetComponentById("PermissionUse").value) = $P(LastSearch,"^",5)
	Set (..PermissionNo,..%GetComponentById("PermissionNo").value) = $P(LastSearch,"^",6)
	Set (..MaxRows,..%GetComponentById("maxRows").value) = $P(LastSearch,"^",7)
	Set ..searchExpanded = ..GetExpandState("Resources")
	Set ..DocPage = $P(..Link("%25CSP.UI.System.ResourceProfile.cls"),"?$NAMESPACE",1)

	Set valueList = ..GetRecentList("Resources")
	If valueList = "" Set valueList = "*"
	Set tCombo = ..%GetComponentById("txtSpec")
	Set tCombo.valueList = valueList
	
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
	Set pCommands(1) = $LB("btnNew",$$$Text("Create New Resource"),$$$Text("Create a new resource"),"zenPage.doEdit('');")
	Set pCommands(2) = $LB("btnExport",$$$Text("Export"),$$$Text("Export selected resources"),"zenPage.doExport();")
	Set pCommands(3) = $LB("btnImport",$$$Text("Import"),$$$Text("Import resources from a file"),"zenPage.doImport();")
	Set pCommands(4) = $LB("btnDelete",$$$Text("Delete"),$$$Text("Delete selected resources"),"zenPage.doDelete(1);")
	Set pCommands(5) = $LB("btnProfile",$$$Text("Profile"),$$$Text("Display profile for selected resources"),"zenPage.doProfile();")

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Resources")
}

/// Method for executing the query.
Method ExecuteRS(pRS As %Library.ResultSet, Output tSC As %Status, pInfo As %ZEN.Auxiliary.QueryInfo) As %Boolean
{
	Set tSpec = ..Spec
	/// PublicPermissions - Only list those with these type of public permissions, -1 = All<br>
	/// Bit 0 - Read public permission<br>
	/// Bit 1 - Write public permission<br>
	/// Bit 2 - Use public permission<br>
	/// Bit 9 - No public permission<br>
	Set tBit(0) = 1, tBit(1) = 2, tBit(2) = 4, tBit(9) = 512
	Set:..PermissionRead=1 tPublicPermissions = tBit(0)
	Set:..PermissionWrite=1 tPublicPermissions = +$G(tPublicPermissions) + tBit(1)
	Set:..PermissionUse=1 tPublicPermissions = +$G(tPublicPermissions) + tBit(2)
	Set:..PermissionNo=1 tPublicPermissions = +$G(tPublicPermissions) + tBit(9)
	If $G(tPublicPermissions) = "" Set tPublicPermissions = 8
	Set tSC = pRS.Execute(tSpec,tPublicPermissions,-1,1)
	Quit tSC
}

/// Delete selected resource(s).
ClientMethod doDelete(resource) [ Language = javascript ]
{
	// deletion by selecting checkboxes
	if (resource == 1) {
		resource = "";
		var table = zen("table");
		var selectedRows = table.getProperty("selectedRows");
		var count = 0;
		var dbselected = 0;
		var rows = selectedRows.split(",");
		for (var i=0; i<rows.length; i++) {
			if (rows[i]!="") {
				if (rows[i]!="%DB_%DEFAULT") {
					resource = resource + rows[i] + ",";	
					count++;
				} else {
					dbselected = 1; 
				}
			}
		}
		if (resource == "") {
			var msg = $$$Text("No resources selected.");
			if (dbselected) msg = msg + this.msgDBDefault;
			alert(msg);
			return;
		} else {
			var msg = this.msgDeleteMsgs.replace("%1",count);
			if (dbselected) msg = msg + "\n\n" + this.msgDBDefault;
		}
	} else {
		// deletion by clicking the "Delete" link
		var msg = this.msgConfirm.replace("%1",resource);
	}
	if (confirm(msg)==true) {
		var ok = this.Delete(resource);
		if (ok != "") alert(ok);
		this.reloadTable();
	}
}

ClientMethod doEdit(resource) [ Language = javascript ]
{
	var url = '%CSP.UI.Portal.Dialog.Resource.zen';
	var hasQ = false;
	if (resource != "") {
		url = url + "?RESOURCENAME=" + encodeURIComponent(resource);
		hasQ = true;
	}
	zenLaunchPopupWindow(url,'ResourceEdit','status,scrollbars,resizable=yes,width=600,height=600');
}

ClientMethod doExport() [ Language = javascript ]
{
	var table = zen("table");
	var total = table.getProperty("rowCount");	
	if (total < 1) {
		alert($$$Text("Nothing to export."));
		return;	
	}
	var exportAll = 0;
	var selectedRows = table.getProperty("selectedRows");
	var ok = this.PrepareAction("Resource",selectedRows);
	if (ok == 0) {
		var ok = confirm($$$Text("No export resources were selected. Do you want to export All resources?"));
		if (!ok) return;
		exportAll = 1;
	}
	var parms = {
			FILETYPE:"Resource",
			EXPORTALL:exportAll,
			ACTION:"Export",
			$NAMESPACE:"%SYS"
	};
	//open dialog for export criteria
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.ExportResource.zen','Export','status,scrollbars,resizable=yes,width=610,height=700',parms);
}

ClientMethod doImport() [ Language = javascript ]
{
	var parms = {
			FILETYPE:"Resource",
			EXPORTALL:0,
			ACTION:"Import",
			$NAMESPACE:"%SYS"
	};	
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.ExportResource.zen','Import','status,scrollbars,resizable=yes,width=610,height=700',parms);
}

ClientMethod doProfile() [ Language = javascript ]
{
	var table = zen("table");
	var total = table.getProperty("rowCount");	
	if (total < 1) {
		alert($$$Text("Nothing to view."));
		return;	
	}
	var selectedRows = table.getProperty("selectedRows");
	var ok = this.PrepareAction("Resource",selectedRows);
	if (ok == 0) {
		alert($$$Text("No resources were selected. Please select resources that you wish to view profile."));
		return;
	}
	var win = window.open(this.DocPage,"ResourceProfile");
	win.focus();
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	switch(popupName) {
	case 'ResourceEdit':
		this.reloadTable();
		break;
	case 'Import':
		this.reloadTable();
		break;
	}
	return true;
}

ClientMethod reloadTable() [ Language = javascript ]
{
	var table = zen("table");
	table.executeQuery(0);
}

/// Draw the contents of the Table Header (the region between the diagram and the table).
Method DrawTableHeader(pSeed As %String) As %Status
{
	Quit 1
}

/// Delete selected resource/s now.
ClassMethod Delete(resource As %String) As %String [ ZenMethod ]
{
	Set tResult = ""
	Set n = 1
	Set item = $P(resource,",",n)
	While item '= "" {
		Set status = ##Class(Security.Resources).Delete(item)
		If $$$ISERR(status) Set tResult = $S(tResult="":"",1:", ") _ $System.Status.GetErrorText(status)
		Set n = n + 1
		Set item = $P(resource,",",n)
	}
	Quit tResult
}

/// When page is loaded, check if this is a ReadOnly for EMS. If it is then disable the multiple select.<br/>
/// Else disable the checkbox for %DB_%DEFAULT.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.IsEMSReadOnly) {
		this.disableCommandButton('btnDelete');
		this.disableCommandButton('btnImport');
	}
}

}
