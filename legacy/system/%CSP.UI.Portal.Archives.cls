/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.Archives Extends %CSP.UI.Portal.Utils [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Archive Targets";

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As %Boolean = 0;

Parameter EMSSERVICE = "Namespace";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Archives.zen";

Parameter HELPADDRESS = "System Administration, Configuration, System Configuration, Archive Targets";

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
	border-top: 1px solid #F1F0E7;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<vgroup id="fld0">
<tableNavBar showFilter="false" showMaxRows="true" showPageSize="true" tablePaneId="table"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
/>
<tablePane id="table" onheaderClick="return zenPage.columnSort(zenThis.getProperty('currColumn'),zenThis.getProperty('sortOrder'));"
fixedHeaders="false"
showValueInTooltip="true"
showZebra="true"
maxRows="1000"
pageSize="0"
valueColumn="Name"
useSnapshot="true"
queryClass="Config.Archives"
queryName="List"
dataSource="columns"
>
<column colName="Name" header="Name"/>
<column colName="Type" header="Type"/>
<column colName="Location" header="Location"/>
<column link="#" linkCaption="Edit" onclick="zenPage.doEdit('#(%query.Name)#');return false;"/>
<column linkCaption="Delete" link="javascript:zenPage.deleteItem('#(%query.Name)#','table');" linkConfirm="Are you sure you want to delete archive target '%1'?" hidden="#(%page.IsEMSReadOnly)#"/>
 </tablePane>
 </vgroup>
 <!-- block to show result -->
<label id="idRespond" enclosingClass="rednote"/>
</pane>
}

ClientMethod doNew() [ Language = javascript ]
{
	try {
		var url = "%25CSP.UI.Portal.Archive.zen?isNew=1";
		this.gotoPage(url);
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod doEdit(archiveName) [ Language = javascript ]
{
	try {
		var url = "%25CSP.UI.Portal.Archive.zen?PID="+encodeURIComponent(archiveName)
		this.gotoPage(url);
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Delete existing item.
ClientMethod deleteItem(archiveName, tableID) [ Language = javascript ]
{
	try {
		var ok = this.DeleteData(archiveName);
		if (ok != 1) {
			zen("idRespond").setValue(ok);
		} else {
			zen("idRespond").setValue("");
			zen(tableID).executeQuery();
		}
	} catch (ex) {
		alert("Error: " + ex);
	}
}

/// Call server delete method.
ClassMethod DeleteData(Name As %String) As %String [ ZenMethod ]
{
	Try {
		Set tSC = ##class(Config.Archives).Delete(Name)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	} Catch Error {
		Set tSC = ..EvalResult(Error.AsStatus())
	}
	Quit tSC
}

ClassMethod DrawLink(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status [ Internal ]
{
	Quit $$$OK
}

/// Subclass can override.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	;Set ..lblTitle = $$$TextHTML("This System has been defined as a archive server for other database servers:")	
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Archive Targets")
}

Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set caption = $$$TextHTML("Create New Archive Target")
	Set pCommands(1) = $LB("btnNew",caption,caption,"zenPage.doNew();")

	Quit $$$OK
}

}
