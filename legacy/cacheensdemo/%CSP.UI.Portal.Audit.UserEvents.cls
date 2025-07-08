/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Security Management - User Audit Events 
Class %CSP.UI.Portal.Audit.UserEvents Extends %CSP.UI.Portal.Audit.EventsTemplate [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Audit.UserEvents.zen";

Parameter HELPADDRESS = "System Administration,Security,Auditing,Configure User Events";

Parameter EMSSERVICE = "Security";

/// Displayed name of this page.
Parameter PAGENAME = "User-Defined Audit Events";

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<group>
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true" maxRows="1000" 
onfilterChange="zenPage.filterChanged(value);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value);" onMaxRowsChange="zenPage.navMaxRowsChanged(value);"
 title="To filter: enter one or more characters of any column followed by [Tab]."/>
<tablePane id="table" cellSpacing="2"
queryClass="Security.Events"
queryName="ListByFilter"
dataSource="columns"
fixedHeaders="false"
pageSize="0"
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="false"
valueColumn="EventName"
useSnapshot="true"
>
<parameter value="#(%page.Filter)#"/>
<parameter value="0"/>
<parameter value="1"/>
<column colName="EventName" header="Event Name" link="#" onclick="javascript:zenPage.doEdit('#(%query.EventName)#');"
title="Edit audit event"/>
<column colName="Enabled"/>
<column colName="Total"/>
<column colName="Written"/>
<column colName="EnabledBoolean" hidden="true"/>
<column id="Reset" link="javascript:zenPage.doReset('#(%query.EventName)#');" linkCaption="Reset" style="text-align:center;" linkConfirm="Are you sure you want to reset the counter to zero?"/>
<column id="ChangeStatus" link="javascript:zenPage.doChangeStatus('#(%query.EventName)#');" linkCaption="Change Status" style="text-align:center;" hidden="#(%page.IsEMSReadOnly)#"/>
<column id="Delete" link="javascript:zenPage.doDelete('#(%query.EventName)#');" linkCaption="Delete" style="text-align:center;" linkConfirm="Are you sure you want to delete event '%1'?" hidden="#(%page.IsEMSReadOnly)#"/>
<condition colName="EnabledBoolean" predicate="EQ" value="1" rowStyle="background-color:#C5E5C9;"/> 
 </tablePane>
 </group>
</pane>
}

ClientMethod doEdit(event) [ Language = javascript ]
{
	var url = zenLink('%25CSP.UI.Portal.Audit.UserEvent.zen?PID='+encodeURIComponent(event));
	this.gotoPage(url);
}

ClientMethod doDelete(event) [ Language = javascript ]
{
	var result = this.Delete(event);
	if (result.ok != 1) alert(result.ErrorMessage);
	var table = zen("table");
	table.executeQuery(0);
}

ClassMethod Delete(event As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = ##Class(Security.Events).Delete(event)
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
	Set ..lblTitle = $$$Text("The following is a list of user-defined audit events:")
	
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	#; commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnNew",$$$Text("Create New Event"),$$$Text("Create a new audit event"),"zenPage.doEdit('');")
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("User-Defined Audit Events")
}

}
