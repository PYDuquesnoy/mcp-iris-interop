/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Security Management - System Audit Events 
Class %CSP.UI.Portal.Audit.SystemEvents Extends %CSP.UI.Portal.Audit.EventsTemplate [ System = 4 ]
{

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Audit.SystemEvents.zen";

Parameter HELPADDRESS = "System Administration,Security,Auditing,Configure System Events";

/// Displayed name of this page.
Parameter PAGENAME = "System Audit Events";

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<hgroup cellStyle="padding:6px;">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:0px;"/>
<button id="btnAuditWizard" caption=" Selective SQL Auditing Wizard " controlClass="commandButton" onclick="zenPage.doSelWizard();"/>
</hgroup>
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
<parameter value="1"/>
<parameter value="1"/>
<column colName="EventName" header="Event Name"/>
<column colName="Enabled"/>
<column colName="Total"/>
<column colName="Written"/>
<column colName="EnabledBoolean" hidden="true"/>
<column id="Reset" link="javascript:zenPage.doReset('#(%query.EventName)#');" linkCaption="Reset" style="text-align:center;" linkConfirm="Are you sure you want to reset the counter to zero?"/>
<column id="ChangeStatus" link="javascript:zenPage.doChangeStatus('#(%query.EventName)#');" linkCaption="Change Status" style="text-align:center;" hidden="#(%page.IsEMSReadOnly)#"/>
<condition colName="EventName" predicate="EQ" value="%System/%SQL/DynamicStatement" rowStyle="display: none;"/>
<condition colName="EventName" predicate="EQ" value="%System/%SQL/EmbeddedStatement" rowStyle="display: none;"/>
<condition colName="EventName" predicate="EQ" value="%System/%SQL/XDBCStatement" rowStyle="display: none;"/>
<condition colName="EventName" predicate="EQ" value="%System/%SQL/Query" rowStyle="display: none;"/>
<condition colName="EventName" predicate="EQ" value="%System/%SQL/DDL" rowStyle="display: none;"/>
<condition colName="EventName" predicate="EQ" value="%System/%SQL/DML" rowStyle="display: none;"/>
<condition colName="EventName" predicate="EQ" value="%System/%SQL/Utility" rowStyle="display: none;"/>

<condition colName="EnabledBoolean" predicate="EQ" value="1" rowStyle="background-color:#C5E5C9;"/>
 </tablePane>
 </group>
</pane>
}

ClientMethod doSelWizard() [ Language = javascript ]
{
	var parms = new Object();
	parms.ALREADYON = [];
	var listOfKeys = [
		'DynamicStatementQuery',
		'DynamicStatementDDL',
		'DynamicStatementDML',
		'DynamicStatementUtility',
		'EmbeddedStatementQuery',
		'EmbeddedStatementDDL',
		'EmbeddedStatementDML',
		'EmbeddedStatementUtility',
		'XDBCStatementQuery',
		'XDBCStatementDDL',
		'XDBCStatementDML',
		'XDBCStatementUtility'
	];
	for (var key of listOfKeys) {
		if (zenPage.doGetStatus("%System/%SQL/"+key) == 1) {
			parms.ALREADYON.push(key);
		}
	}
	zenPage.launchPopupWindow(
    zenLink('%CSP.UI.Portal.Audit.SelectiveWizard.zen'),
    'Selective SQL Auditing Wizard',
    'status,scrollbars,resizable=yes,width=500,height=520', parms);
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState()
	Set ..lblTitle = $$$Text("The following is a list of system audit events:")
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("System Audit Events ")
}

ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
  if (popupName === 'Selective SQL Auditing Wizard') {
	for (var key in value) {
		if (value[key] != zenPage.doGetStatus("%System/%SQL/"+key)) {
			zenPage.doChangeStatus("%System/%SQL/"+key);
		}
	}
  }
}

}
