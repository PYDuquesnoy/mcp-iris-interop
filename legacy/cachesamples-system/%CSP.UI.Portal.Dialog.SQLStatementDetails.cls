/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// SQL Statement Details view and freeze plan for Management Portal
Class %CSP.UI.Portal.Dialog.SQLStatementDetails Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.Dialog.SQLStatementDetails.zen";

/// Displayed name of this page.
Parameter PAGENAME = "SQLStatementDetails";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 1;

/// Security requirement
Parameter RESOURCE = "%Development";

Property NAMESPACE As %ZEN.Datatype.string(ZENURL = "NAMESPACE");

/// Schema name, may or may not be available.
Property SCHEMA As %ZEN.Datatype.string(ZENURL = "SCHEMA");

Property STMTHASH As %ZEN.Datatype.string(ZENURL = "STMTHASH");

Property OpenInTab As %ZEN.Datatype.string(ZENURL = "OpenInTab");

/// Store translated targetCol linkCaption for <condition>
Property colCompile As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Compile Routine")} ];

Property hashError As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property PlanState As %ZEN.Datatype.integer;

Property expTitle As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Click to expand or collapse this group")} ];

Property lblYes As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Yes")} ];

Property lblNo As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("No")} ];

Property ViewStatsPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/exp/%25CSP.UI.Portal.SQL.QButtons.RuntimeStats.zen",,1)} ];

/// When editing, this is passed in.
/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#body {
	background: white;
}
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
}
.expandoNode {
    padding-top: 20px;
}
.expandoNode a:link {
	color: #000000;
	font-weight: bold;
}
.expandoNode a:hover {
	color: #000000;
	background: #ffffff;
	font-weight: bold;
}
.text {
	background: #f8f8f8;
	border: 1px solid #cbcbcb;
	border-radius:4px;	
}
#buttonHolder {
	margin-left: 17px;	
}
.note {
	color: #4D3926;
	font-size: 12px;
}
.textNote {
	border: 1px solid #4D3926;
	border-radius: 0.15em;
	font-size:0.8em;
	padding: 2px;
}
.textNoteHide {
	border: none;
	padding: 2px;
}
.commandButtonDisabled {
	padding: 6px;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />
<hgroup width="100%" cellAlign="left">
<hgroup id="buttonHolder" cellAlign="left" cellStyle="padding-right:4px;">
<button id="btnFreezePlan" caption="Freeze Plan" onclick="zenPage.doFreezePlan();" title="Click this button to freeze this query plan for the statement.  Plans in a state of Unfrozen/Parallel, or statements that reference an external table may not be frozen."/>
<button id="btnUnFreezePlan" caption="Un-Freeze Plan" onclick="zenPage.doUnFreezePlan();" title="Click this button to un-freeze the frozen query plan for the statement."/>
<button id="btnClearStatistics" controlClass="commandButton" caption="Clear SQL Statistics" onclick="zenPage.doClearStatistics();" title="Click this button to clear the SQL statistics associated with this statement."/>
<button id="btnExport" controlClass="commandButton" caption="Export" onclick="zenPage.doExport();" title="Click this button to export the statement plan."/>
<button id="btnRefreshPage" controlClass="commandButton" caption="Refresh Page" onclick="zenPage.doRefreshPage();" title="Click this button to refresh the contents of this page."/>
<spacer width="10"/>
<button id="btnClose" controlClass="commandButton" caption="Close" hidden="true" onclick="zenPage.dialogCancel();"/>
<button id="btnQueryTest" controlClass="commandButton" caption="Query Test" hidden="true" onclick="zenPage.doQueryTest();" title="Click this button to go to the SQL Performance Tool's Query Test page to run this query."/>
</hgroup>
</hgroup>
<pane paneName="dialogBody" id="body" />

</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;" cellVAlign="top">
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<vgroup id="content" valign="top">
<expando id="expando1" caption="Statement Details" childIndent="18px" imageContracted="csp/broker/images/icon-arrow-blue-right.png" imageExpanded="/csp/broker/images/icon-arrow-blue-down.png" expanded="true" onclick="zenPage.saveExpState();" valign="top" title="#(%page.expTitle)#" >
<group id="statementGroup1" >
<spacer height="4"/>
<hgroup valign="middle" >
<group labelPosition="left" valign="top" cellAlign="even">
<text id="txtSQLStatementID" label="SQL Statement ID" size="12" disabled="true" title="The unique identifier (ID) for the statement in the SQL Statement Index."/>
</group>
<spacer width="10"/>
<group labelPosition="left" valign="top" cellAlign="even">
<text id="txtHash" label="Statement hash" size="30" readOnly="true" value="test" title="The computed hash value for the statement used as the ID in the SQL Statement Index."/>
</group>
<spacer width="10"/>
<group labelPosition="left" valign="top" cellAlign="even">
<text id="txtPlanFirst" label="Date first seen" size="10" disabled="true" title="Date we first recorded statistics for this query."/>
</group>
</hgroup>
<hgroup valign="middle" >
<group labelPosition="left" valign="top" cellAlign="even">
<text id="txtPlanState" label="Plan state" size="20" disabled="true" title="Describes if the plan for this statement has been frozen and if so which type of freeze it was."/>
<text id="txtPlanCount" label="Execution count" hidden="false" size="10" disabled="true" title="Total number of times this query has been run."/>
<text id="txtPlanAverageCount" label="Execution count/day" size="10" disabled="true" title="Average number of times this query has been run per day."/>
</group>
<spacer width="10"/>
<group labelPosition="left" valign="top" cellAlign="even">
<text id="txtPlanTotal" label="Total time" size="10" disabled="true" title="Total time spent running this query (s)."/>
<text id="txtPlanAverage" label="Average time" size="10" disabled="true" title="Average time running this query (s)."/>
<text id="txtPlanStdDev" label="Stddev time" size="10" disabled="true" title="Standard deviation of time running this query (s)."/>
</group>
<spacer width="10"/>
<group labelPosition="left" valign="top" cellAlign="even">
<text id="txtPlanFrozenDifferent" label="Frozen plan different" size="10" disabled="true" title="If yes, the frozen plan differs from the unfrozen plan"/>
<text id="txtPlanRowCount" label="Row Count" hidden="false" size="10" disabled="true" title="Total %ROWCOUNT from running this query."/>
<text id="txtPlanAverageRowCount" label="Row Count/day" hidden="false" size="10" disabled="true" title="Average %ROWCOUNT from running this query per day."/>
<text id="txtPlanCommands" label="Commands Executed" hidden="false" size="10" disabled="true" title="Total ObjectScript commands executed from running this query."/>
<text id="txtPlanAverageCommands" label="Commands Executed/day" hidden="false" size="10" disabled="true" title="Average ObjectScript commands execute from running this query per day."/>
</group>
<spacer width="10"/>
<group valign="top" cellAlign="even">
<button id="btnRefreshFrozen" controlClass="commandButton" caption="Check Frozen" hidden="true" onclick="zenPage.doCheckFrozen();" title="Click this button to check if the frozen plan is different to the current plan."/>
</group>
</hgroup>
</group>
</expando>
<expando id="expando2" caption="Compile Settings" childIndent="18px" imageContracted="csp/broker/images/icon-arrow-blue-right.png" imageExpanded="/csp/broker/images/icon-arrow-blue-down.png" expanded="true" onclick="zenPage.saveExpState();" valign="top" title="#(%page.expTitle)#" >
<vgroup id="statementGroup2" >
<hgroup labelPosition="left" valign="middle" cellAlign="even">
<group labelPosition="left" valign="top" cellAlign="even">
<text id="txtCompileMode" label="Select mode" size="10" disabled="true" title="SELECTMODE the statement was compiled with."/>
<text id="txtUserName" label="Username" size="20" disabled="true" title="Username at the time the query was constructed."/>
<text id="txtClientIP" label="Client IP Address" size="30" disabled="true" title="Client IP address that caused the query to be built."/>
</group>
<spacer width="10"/>
<group labelPosition="left" valign="top" cellAlign="even">
<text id="txtDefaultSchema" label="Default schema(s)" size="30"  disabled="true" title="Comma separated list of default schema named defined for the process that compiled this statement."/>
<text id="txtSchemaPath" label="Schema path" size="30" disabled="true" title="Comma separated list of schema names specified as the schema path for the compilation of this statement."/>
<text id="txtClientName" label="Client Name" size="30" disabled="true" title="Client name that caused the query to be built."/>
</group>
<spacer width="10"/>
<group labelPosition="left" valign="top" cellAlign="even">
<text id="txtPlanVersion" label="Version" size="30" readOnly="true" title="System version that was installed when this plan was last saved."/>
<text id="txtPlanTS" label="Timestamp" size="22" readOnly="true" title="Timestamp for when this plan was last saved."/>
<text id="txtClientApp" label="Client Application" size="30" disabled="true" title="Client application name that caused the query to be built."/>
</group>
</hgroup>
<hgroup labelPosition="left" valign="middle" cellAlign="even">
<text id="txtCallStack" label="Call Stack" size="100" disabled="true" title="Call stack at the time the query was built."/>
</hgroup>
<hgroup id="grpPlanError"  valign="middle" hidden="true" labelPosition="left" cellAlign="even">
<text id="txtPlanError" label="Plan error" size="30" disabled="true" title="Error recorded for this frozen plan." controlStyle="color:red; background: yellow;"/>
<button id="btnClearPlanError" caption="Clear Error" onclick="zenPage.doClearPlanError();" title="Click this button to clear the plan error and attempt to use the frozen plan again.  If the problem that results in the plan error has not been corrected, the error will remain.  If the problem has been corrected, the error state will be cleared and the plan can once again be used."/>
</hgroup>
</vgroup>
</expando>
<!-- Show Statement Location Details -->
<expando id="expando3" caption="Statement is Defined in the Following Routines" childIndent="18px" imageContracted="csp/broker/images/icon-arrow-blue-right.png" imageExpanded="csp/broker/images/icon-arrow-blue-down.png" expanded="true" onclick="zenPage.saveExpState();" valign="top" title="#(%page.expTitle)#" >
<hgroup id="statementGroup3">
<tablePane id="tblLocations"
queryClass="%SQL.Manager.Catalog"
queryName="StatementLocations"
initialExecute="true"
maxRows="1000"
showZebra="true"
useSnapshot="false"
fixedHeaders="false"
showRowSelector="false"
cellSpacing="2"
align="center"
>
<column colName="ROUTINE" header="Routine" title="Routine Name This Statement is Defined In."/>
<column colName="CONTAINER_TYPE" header="Type" title="Class Method, MAC Routine, etc.  Type of object this statement is defined in."/>
<column colName="COMPILE_DATETIME" header="Last Compile Time" title="Date and time of when this routine was last compiled."/>
<column colName="RUNTIMEROUTINE" header="Runtime Routine" title="Name of routine cached query implementation is in."/>
<column linkCaption="Compile Routine" id="compileRoutine" 
link="javascript:zenPage.doCompileRoutine('#(%query.ROUTINE)#','#(%page.NAMESPACE)#');" 
cellTitle="Compile the routine that contains this SQL statement."
/>
<condition colName="CONTAINER_TYPE" predicate="EQ" value="Class Method" cellStyle="disabled" targetCol="#(%page.colCompile)#"/>
<parameter value="#(%page.STMTHASH)#"/>
</tablePane>
<spacer width="4"/>
<image id="imgRefresh3" src="csp/broker/deepsee/ds2_refresh_44.png" valign="top" width="16" height="16" title="Refresh routine listing" onclick="zenPage.doRefreshTable('tblLocations');"  disabled="false"/>
</hgroup>
</expando>
<expando id="expando4" caption="Statement Uses the Following Relations" childIndent="18px" imageContracted="csp/broker/images/icon-arrow-blue-right.png" imageExpanded="csp/broker/images/icon-arrow-blue-down.png" expanded="true" onclick="zenPage.saveExpState();" valign="top" title="#(%page.expTitle)#" >
<hgroup id="statementGroup4">
<tablePane id="tblRelations"
queryClass="%SQL.Manager.Catalog"
queryName="StatementRelations"
initialExecute="true"
maxRows="1000"
showZebra="true"
useSnapshot="false"
fixedHeaders="false"
showRowSelector="false"
cellSpacing="5"
align="center"
>
<column colName="TABLE_NAME" header="Table or View Name" title="Table or view name or relation used by this statement."/>
<column colName="TABLE_TYPE" header="Type" title="Type of this relation: Table or View."/>
<column colName="COMPILE_DATETIME" header="Last Compile Time" title="Date and time of when this class was last compiled."/>
<column colName="CLASSNAME" header="Classname" hidden="false" title="Name of the class that projected this table or view definition."/>
<column linkCaption="Compile Class" id="compileClass" 
link="javascript:zenPage.doCompileClass('#(%query.CLASSNAME)#','#(%page.NAMESPACE)#');" 
cellTitle="Compile the class that projected this SQL relation." 
/>
<parameter value="#(%page.STMTHASH)#"/>
</tablePane>
<spacer width="4"/>
<image id="imgRefresh4" src="csp/broker/deepsee/ds2_refresh_44.png"  valign="top" width="16" height="16" title="Refresh table/view listing" onclick="zenPage.doRefreshTable('tblRelations');"  disabled="false"/>
</hgroup>
</expando>
<expando id="expando5" hidden="true" childIndent="18px" imageContracted="csp/broker/images/icon-arrow-blue-right.png" imageExpanded="csp/broker/images/icon-arrow-blue-down.png" expanded="true" onclick="zenPage.saveExpState();" valign="top">
<group id="statementGroup5">
<textarea id="StatementText"  showLabel="false" label="Statement Text" rows="10" cols="80" hidden="true"
readOnly="true"/>
</group>
</expando>

<expando id="expando6" width="100%" caption="Statement Text and Query Plan" childIndent="18px" imageContracted="csp/broker/images/icon-arrow-blue-right.png" imageExpanded="csp/broker/images/icon-arrow-blue-down.png" expanded="true" onclick="zenPage.saveExpState();" valign="top" title="#(%page.expTitle)#" >
<hgroup>
<html id="statementGroup7" seed="0" OnDrawContent="DrawShowPlan"/>
<group id="compareGroup" hidden="true" valign="top">
<html id="statementGroup8" seed="1" OnDrawContent="DrawShowPlan"/>
</group>
</hgroup>
</expando>
</vgroup>
</pane>
}

ClientMethod ondialogCancel() [ Language = javascript ]
{
	return true;
}

ClientMethod saveExpState() [ Language = javascript ]
{
	// save state of expandos
	var expId;
	var expValue;
	var expandoList = "";
	for (n=1; n<7; n++) {
		expId = "expando" + n;
		if (zen(expId)) {
			expValue = zen(expId).expanded ? 1 : 0;
			expandoList += expValue + ',';
		}		
	}
	var ok = this.SaveExpando(expandoList);
	return true;
}

/// Goto the Test Query tab and put the statement text in
ClientMethod doQueryTest() [ Language = javascript ]
{
	var delim = (this.ViewStatsPage.indexOf('?$NAMESPACE') == -1) ? '?' : '&';
	url = this.ViewStatsPage + delim + 'openTab=1';
	var win = window.open(url,'_self');
	win.focus();
}

ClassMethod SaveExpando(pExpandoList) As %Status [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,..%GetPageName(),"ExpandoState") = pExpandoList
	Quit 1
}

/// When the current plan is frozen, then we show un-frozen plan on the side for easy comparison
ClassMethod DrawShowPlan(pShowCompare) As %Status
{
	Set pText=1
	Set pText(1)=%session.Data($Username,"SQL","StatementText")
	If +$G(pShowCompare) = 0 {
		Set tFrozenPlan = +$g(%session.Data($Username,"SQL","StatementPlanState"))
	} Else {
		Set tFrozenPlan = 0	
	}
	&html<
    <style type="text/css">
   pre { white-space: normal; }
   </style>>
	&html<<table cellpadding="0" cellspacing="1" border="0" width="100%">>
	&html<<tr bgcolor="#818181"><td valign="top" align="center">>

	if '$g(%session.Data($Username,"SQL","StatementPlanError")) {	// No frozen plan error
		if $case($e($$$StripLeadingWhiteSpace($$$UPPER(pText(1))),1,6),"UPDATE":1,"DELETE":1,:0),pText(1)[" WHERE CURRENT OF " {
			Set tPlan = ##class(%SQL.Manager.ShowPlan).ShowPlanError(.pText,$$$Text("There is no Query Plan for positioned UPDATE or DELETE statements"))
		}
		else {
			Set SelectMode=$g(%session.Data($Username,"SQL","StatementSelectMode")) set:SelectMode="Logical" SelectMode=""
			Set tPlan = ##class(%SQL.Manager.ShowPlan).ShowPlan(.pText,$g(%session.Data($Username,"SQL","StatementPackages")),0,tFrozenPlan,SelectMode,,$g(%session.Data($Username,"SQL","StatementSchemaPath")),,,,+$G(pShowCompare),,1,,$g(%session.Data($Username,"SQL","noRTPC")))
		}
	}
	else {
		Set tPlan = ##class(%SQL.Manager.ShowPlan).ShowPlanError(.pText)
	}

	&html<#(tPlan)#>
	&html<</table>>
	Quit $$$OK
}

Method FreezePlan() As %String [ ZenMethod ]
{
	#dim hash,%msg,packages,sql,switch,tmsg As %String
	#dim returnVal,SQLCODE As %Integer
	
	New %msg
	Set hash=..STMTHASH
	set:hash[" " hash=$tr(hash," ","+")
	If $$HasExternalTable^%SYS.SQLSRV(hash) {
		Set tmsg=%msg
		QUIT tmsg
	}
	Set returnVal=$$FreezePlan^%SYS.SQLSRV(hash,,.SQLCODE,.%msg)
	If returnVal {
		Set state=$$$Text("Frozen/Explicit")
		Set ..%GetComponentById("txtPlanState").value = state
		Set ..%GetComponentById("btnFreezePlan").disabled = 1
		Set ..%GetComponentById("btnUnFreezePlan").disabled = 0
		Do ..RecheckFrozenPlan(hash)
		Set %session.Data($Username,"SQL","StatementPlanState") = 1
		Set %page.PlanState = 1
		Set tmsg=""
	}
	Else {
		Set tmsg="ERROR:  SQLCODE = "_$g(SQLCODE,"<NOT DEFINED>")_", %msg = "_$g(%msg,"<NOT DEFINED>")
	}
	QUIT tmsg
}

ClientMethod doFreezePlan() [ Language = javascript ]
{
	zen("idRespond").setHidden(true);
	var ok = this.FreezePlan();
	if (ok != "") {
		this.showMsg(ok,true);
	}
	zen('statementGroup2').refreshContents();
	zen('statementGroup7').refreshContents();
	this.checkButtonStatus();
	this.showCompare(1);
	this.updateParentTable();
}

Method UnFreezePlan() As %String [ ZenMethod ]
{
	#dim hash,%msg,tmsg,PlanVersion,v As %String
	#dim returnVal,SQLCODE As %Integer
	
	New %msg
	Set hash=..STMTHASH
	set:hash[" " hash=$tr(hash," ","+")
	Set returnVal=$$UnfreezePlan^%SYS.SQLSRV(hash,,.SQLCODE,.%msg)
	If returnVal {
		Set state=$$$Text("Unfrozen")
		Set ..%GetComponentById("txtPlanState").value = state
		Set ..%GetComponentById("btnFreezePlan").disabled = $$HasExternalTable^%SYS.SQLSRV(hash)	// if there is an external table, disable btnFreezePlan
		Set ..%GetComponentById("btnUnFreezePlan").disabled = 1
		Set ..%GetComponentById("txtPlanError").value = ""
		Set ..%GetComponentById("grpPlanError").hidden = 1
		Set %session.Data($Username,"SQL","StatementPlanError")=0
		Set %session.Data($Username,"SQL","StatementPlanState")=0
		Set PlanVersion=$zv
		Set v=$SYSTEM.Version.GetMajor(PlanVersion)_"."_$SYSTEM.Version.GetMinor(PlanVersion)_"."_$case($SYSTEM.Version.GetPoint(PlanVersion),"":0,:$SYSTEM.Version.GetPoint(PlanVersion))_"."_$SYSTEM.Version.GetBuildNumber(PlanVersion)
		Set ..%GetComponentById("txtPlanVersion").value = v
		Set ..%GetComponentById("txtPlanVersion").size = $l(v)+3
		Set ..%GetComponentById("txtPlanVersion").title = $$$FormatText($$$Text("This is the version that was installed when this plan was last saved.  The entire version string for this plan is: '%1'"),PlanVersion)
		Set ..%GetComponentById("txtPlanFrozenDifferent").hidden = 1
		//Set ..%GetComponentById("btnRefreshFrozen").hidden = 1
		Set tmsg=""
	}
	Else {
		Set tmsg="ERROR:  ,SQLCODE = "_$g(SQLCODE,"<NOT DEFINED>")_", %msg = "_$g(%msg,"<NOT DEFINED>")
	}
	QUIT tmsg
}

ClientMethod doUnFreezePlan() [ Language = javascript ]
{
	zen("idRespond").setHidden(true);
	var ok = this.UnFreezePlan();
	if (ok != "") {
		this.showMsg(ok,true);
	}
	zen('statementGroup2').refreshContents();
	zen('statementGroup7').refreshContents();
	this.checkButtonStatus();
	zen('compareGroup').setProperty('hidden',true);
	this.updateParentTable();
}

Method ClearSQLStatistics() As %String [ ZenMethod ]
{
	#dim hash,%msg,packages,sql,switch,tmsg As %String
	#dim returnVal,SQLCODE As %Integer
	
	New %msg
	Set hash=..STMTHASH
	set:hash[" " hash=$tr(hash," ","+")
	Set returnVal=$$ClearStats^%SYS.SQLSRV(hash,.SQLCODE,.%msg)
	If returnVal {
		Set tmp=..%GetComponentById("txtPlanCount"),tmp.value=""
		Set tmp=..%GetComponentById("txtPlanTotal"),tmp.value=""
		Set tmp=..%GetComponentById("txtPlanAverage"),tmp.value=""
		Set tmp=..%GetComponentById("txtPlanStdDev"),tmp.value=""
		Set tmp=..%GetComponentById("txtPlanAverageCount"),tmp.value=""
		Set tmp=..%GetComponentById("txtPlanFirst"),tmp.value=""
		Set tmp=..%GetComponentById("txtPlanRowCount"),tmp.value=""
		Set tmp=..%GetComponentById("txtPlanAverageRowCount"),tmp.value=""
		Set tmp=..%GetComponentById("txtPlanCommands"),tmp.value=""
		Set tmp=..%GetComponentById("txtPlanAverageCommands"),tmp.value=""
		Set tmsg=$$$FormatText($$$Text("SQL statistics for SQL statement with hash ID '%1' have been removed."),hash)
	}
	Else {
		Set tmsg="ERROR:  SQLCODE = "_$g(SQLCODE,"<NOT DEFINED>")_", %msg = "_$g(%msg,"<NOT DEFINED>")
	}
	QUIT tmsg
}

ClientMethod doClearStatistics() [ Language = javascript ]
{
	var tmsg = this.ClearSQLStatistics();
	this.showMsg(tmsg,false);
	zen('statementGroup1').refreshContents();
	this.updateParentTable();
}

ClientMethod doRefreshTable(tablename) [ Language = javascript ]
{
	var table = zen(tablename);
	table.refreshContents();
}

Method CompileClassSetClassname(classname As %String) As %String [ ZenMethod ]
{
	Kill %session.Data($Username,"SQLStatementClass")
	Set %session.Data($Username,"SQLStatementClass","selectedRows",1)=classname_".cls"
	Set %session.Data($Username,"SQLStatementClass","selectedRows")=1
	Set %session.Data($Username,"SQLStatementClass","TotalSelected")=1
	QUIT 1
}

ClientMethod doCompileClass(classname, namespace) [ Language = javascript ]
{
	var ok = this.CompileClassSetClassname(classname);
	var parms = {
			MODE:"models",
			FILETYPE:"SQLStatementClass",
			COMPILEALL:0,
			$NAMESPACE:namespace
	};
	
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.Compile.zen','Compile','status,scrollbars,resizable=yes,width=610,height=700',parms);
}

Method CompileRoutineSetRoutineName(rtnname As %String) As %String [ ZenMethod ]
{
	Kill %session.Data($Username,"SQLStatementRoutine")
	Set %session.Data($Username,"SQLStatementRoutine","selectedRows",1)=rtnname_".mac"
	Set %session.Data($Username,"SQLStatementRoutine","selectedRows")=1
	Set %session.Data($Username,"SQLStatementRoutine","TotalSelected")=1
	QUIT 1
}

ClientMethod doCompileRoutine(rtnname, namespace) [ Language = javascript ]
{
	var ok = this.CompileRoutineSetRoutineName(rtnname);
	var parms = {
			MODE:"models",
			FILETYPE:"SQLStatementRoutine",
			COMPILEALL:0,
			$NAMESPACE:namespace
	};
	
	zenLaunchPopupWindow('%CSP.UI.Portal.Dialog.Compile.zen','Compile','status,scrollbars,resizable=yes,width=610,height=700',parms);
}

ClientMethod doExport() [ Language = javascript ]
{
	var hash = zen('txtHash').getValue();
	var parms = {
			HASH:hash,
			EXPORTALL:0,
			$NAMESPACE:this.NAMESPACE
	};
	
	zenLaunchPopupWindow('%CSP.UI.Portal.SQL.ExportStatement.zen','Export','status,scrollbars,resizable=yes,width=610,height=700',parms);
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("SQL Statement Details")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This client event is fired when the a popup page launched from this page fires an action.
/// action - StatementRefresh is for when returning from compiling a routine or class.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(action) {
	case 'StatementRefresh':
		var ok = this.RefreshStatementMetadata();
		this.doRefreshTable('tblLocations');
		this.doRefreshTable('tblRelations');
		zen('statementGroup1').refreshContents();
		break;
	default:
	}
}

/// This client event is fired when the Refresh button is clicked
ClientMethod doRefreshPage() [ Language = javascript ]
{
	zen("idRespond").setHidden(true);	
	var ok = this.RefreshStatementMetadata();
	if (this.hashError) {
		this.showMsg($$$Text("Statement with this hash not present"),true);
	}	
	this.doRefreshTable('tblLocations');
	this.doRefreshTable('tblRelations');
	zen('statementGroup1').refreshContents();
	zen('statementGroup2').refreshContents();
	zen('statementGroup7').refreshContents();
}

/// This client event is fired when the Check Frozen button is clicked (this button is deprecated)
ClientMethod doCheckFrozen() [ Language = javascript ]
{
	var same = this.RecheckFrozenPlan();
	if (same == -1) {
		this.showMsg($$$Text("Unable to detemine if this statement is the same as the frozen plan or not"),false);
		return;	
	}
	this.showMsg($$$Text("Plan recheck completed"),false);
	zen('statementGroup1').refreshContents();
}

/// This client event is fired when the ClearPlanError button is clicked
ClientMethod doClearPlanError() [ Language = javascript ]
{
	var ok = this.ClearPlanError();
	this.doRefreshPage();
}

/// This method forces a recheck of frozen plan
Method RecheckFrozenPlan(hash) As %Status [ ZenMethod ]
{
	If hash = "" {
		Set hash = ..STMTHASH
		// For reasons unknown to me, then the hash is used as the 
		Set:hash[" " hash=$tr(hash," ","+")
	}
	Do StatementSame^%SYS.SQLSRV(hash,.same,1)
	If same = -1 {
		Set ..%GetComponentById("txtPlanFrozenDifferent").hidden = 1
		Set ..%GetComponentById("txtPlanFrozenDifferent").value = ""
	} Else {
		Set ..%GetComponentById("txtPlanFrozenDifferent").hidden = 0
		Set ..%GetComponentById("txtPlanFrozenDifferent").value = $S(same:%page.lblNo,1:%page.lblYes)
	}
	Quit $$$OK
}

Method ClearPlanError() As %Status [ ZenMethod ]
{
	Set hash = ..STMTHASH
		// For reasons unknown to me, then the hash is used as the 
	Set:hash[" " hash=$tr(hash," ","+")
	Do UpdateSQLIndex^%SYS.SQLSRV(hash,"")	// Clear the error in the statement index
	Set ..%GetComponentById("txtPlanError").value = ""
	Set ..%GetComponentById("grpPlanError").hidden = 1
	Set %session.Data($Username,"SQL","StatementPlanError") = 0
	Quit $$$OK
}

Method RefreshStatementMetadata() As %Status [ ZenMethod ]
{
	Set hash=..STMTHASH
		// For reasons unknown to me, then the hash is used as the 
	Set:hash[" " hash=$tr(hash," ","+")
	Set ret = ##class(%SQL.Manager.Catalog).GetStatementInfo(hash,,,,.PlanState,,,, .PlanTS, .PlanVersion, .PlanError,,.Count,.Total,.Average,.StdDev,.FirstStat,.AverageCount,.PlanFrozenDifferent,,.RowCount,.AverageRowCount,,,,,,.Commands,.AverageCommands,.SQLStatementID)
	Set %page.PlanState = PlanState
	If 'ret {
		Set %page.hashError = 1
	}
	If $case(PlanState,1:1,2:1,:0) || ($$HasExternalTable^%SYS.SQLSRV(hash)) {	// Frozen, or has external table and cannot be frozen
		Set ..%GetComponentById("btnFreezePlan").disabled = 1
		Set ..%GetComponentById("btnUnFreezePlan").disabled = 0
	}
	ElseIf $case(PlanState,3:1,"":1,:0) {	// Plan State is not defined (INSERT?), or "Unfrozen/Parallel"
		Set ..%GetComponentById("btnFreezePlan").disabled = 1
		Set ..%GetComponentById("btnUnFreezePlan").disabled = 1
	}
	Else {
		Set ..%GetComponentById("btnFreezePlan").disabled = 0
		Set ..%GetComponentById("btnUnFreezePlan").disabled = 1
	}
	Set DisplayPlanState=$case(PlanState,1:$$$Text("Frozen/Explicit"),2:$$$Text("Frozen/Upgrade"),3:$$$Text("Unfrozen/Parallel"),:$$$Text("Unfrozen"))
	Set ..%GetComponentById("txtPlanState").value = DisplayPlanState
	If PlanState=1||(PlanState=2) {
		Do ..RecheckFrozenPlan(hash)
	} Else {
		Set ..%GetComponentById("txtPlanFrozenDifferent").hidden = 1
		//Set ..%GetComponentById("btnRefreshFrozen").hidden = 1
	}
	If PlanVersion'="" {
		Set v=$SYSTEM.Version.GetMajor(PlanVersion)_"."_$SYSTEM.Version.GetMinor(PlanVersion)_"."_$case($SYSTEM.Version.GetPoint(PlanVersion),"":0,:$SYSTEM.Version.GetPoint(PlanVersion))_"."_$SYSTEM.Version.GetBuildNumber(PlanVersion)
		Set ..%GetComponentById("txtPlanVersion").value = v
		Set ..%GetComponentById("txtPlanVersion").disabled = 1
		Set ..%GetComponentById("txtPlanVersion").size = $l(v)+3
		Set ..%GetComponentById("txtPlanVersion").title = $$$FormatText($$$Text("This is the version that was installed when this plan was last saved.  The entire version string for this plan is: '%1'"),PlanVersion)
	}
	Else {
		Set ..%GetComponentById("txtPlanVersion").hidden = 1
	}
	If PlanError'="" {	// display plan error
		Set ..%GetComponentById("txtPlanError").value = PlanError
		Set ..%GetComponentById("grpPlanError").hidden = 0
		Set ..%GetComponentById("txtPlanError").size = $l(PlanError)+3
	}
	Else {	// No plan error
		Set ..%GetComponentById("txtPlanError").value = ""
		Set ..%GetComponentById("grpPlanError").hidden = 1
	}
	If PlanTS="" {	// never frozen
		Set ..%GetComponentById("txtPlanTS").value = ""
		Set ..%GetComponentById("txtPlanTS").hidden = 1
	}
	Else {
		Set ..%GetComponentById("txtPlanTS").value = PlanTS
		Set ..%GetComponentById("txtPlanTS").hidden = 0
	}
	Set tmp=..%GetComponentById("txtSQLStatementID"),tmp.value=SQLStatementID
	Set tmp=..%GetComponentById("txtPlanCount"),tmp.value = Count
	Set tmp=..%GetComponentById("txtPlanTotal"),tmp.value = Total
	Set tmp=..%GetComponentById("txtPlanRowCount"),tmp.value = RowCount
	Set tmp=..%GetComponentById("txtPlanAverageRowCount"),tmp.value = ..GetDisplayAverageCount(AverageRowCount)
	Set tmp=..%GetComponentById("txtPlanCommands"),tmp.value = Commands
	Set tmp=..%GetComponentById("txtPlanAverageCommands"),tmp.value = ..GetDisplayAverageCount(AverageCommands)
	Set tmp=..%GetComponentById("txtPlanAverage"),tmp.value = Average
	If $L(Average) > 13 Set tmp.size = $L(Average)
	Set tmp=..%GetComponentById("txtPlanStdDev"),tmp.value = StdDev
	Set tmp=..%GetComponentById("txtPlanAverageCount"),tmp.value = ..GetDisplayAverageCount(AverageCount)
	If FirstStat'="" Set FirstStat=$zd(FirstStat,3)
	Set tmp=..%GetComponentById("txtPlanFirst"),tmp.value = FirstStat
	Set %session.Data($Username,"SQL","StatementPlanError") = (PlanError'="")
	Quit $$$OK
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set %page.SCHEMA = ..SCHEMA
	Set hash=..STMTHASH
	// For reasons unknown to me, then the hash is used as the 
	Set:hash[" " hash=$tr(hash," ","+")
	Set ret=##class(%SQL.Manager.Catalog).GetStatementInfo(hash, .RoutineList, .RelationList, .Statement, .PlanState, .DefaultSchema, .SchemaPath, .SelectMode, .PlanTS, .PlanVersion, .PlanError,,.Count,.Total,.Average,.StdDev,.FirstStat,.AverageCount,.PlanFrozenDifferent,.RuntimeRoutineList,.RowCount,.AverageRowCount,.UserName,.ClientName,.ClientIP,.ClientApp,.CallStack,.Commands,.AverageCommands,.SQLStatementID)
	set ptr=0,allResultSetDynamicSQL=1
    while $LISTNEXT(RuntimeRoutineList,ptr,value) {
	    set value = $p(value,".",1,*-1), QueryType=$lg($g($$$CQ("QueryRoutine",value)),1)
	    if QueryType'=10 {set allResultSetDynamicSQL=0 quit}
    }
    set %session.Data($Username,"SQL","noRTPC") = allResultSetDynamicSQL
    Set %page.PlanState = PlanState
	If 'ret {
		Set %page.hashError = 1
	}
	If $case(PlanState,1:1,2:1,:0) || ($$HasExternalTable^%SYS.SQLSRV(hash)) {	// Frozen, or has external table and cannot be frozen
		Set ..%GetComponentById("btnFreezePlan").disabled = 1
		Set ..%GetComponentById("btnUnFreezePlan").disabled = 0
	}
	ElseIf $case(PlanState,3:1,"":1,:0) {	// Plan State is not defined (INSERT?), or "Unfrozen/Parallel"
		Set ..%GetComponentById("btnFreezePlan").disabled = 1
		Set ..%GetComponentById("btnUnFreezePlan").disabled = 1
	}
	Else {
		Set ..%GetComponentById("btnFreezePlan").disabled = 0
		Set ..%GetComponentById("btnUnFreezePlan").disabled = 1
	}
	Set SelectMode=$case($$$LOWER(SelectMode),"%runtime":"Runtime","%odbc":"ODBC","%external":"Display","%intext":"IntExt","%fdbms":"FDBMS",:"Logical")
	Set DisplayPlanState=$case(PlanState,1:$$$Text("Frozen/Explicit"),2:$$$Text("Frozen/Upgrade"),3:$$$Text("Unfrozen/Parallel"),:$$$Text("Unfrozen"))
	Set ..%GetComponentById("txtSQLStatementID").value=SQLStatementID
	Set ..%GetComponentById("txtHash").value = hash
	Set ..%GetComponentById("txtHash").disabled = 0
	Set ..%GetComponentById("txtHash").size = $l(hash)+6
	Set ..%GetComponentById("txtCompileMode").value = SelectMode
	Set ..%GetComponentById("txtDefaultSchema").value = DefaultSchema
	Set ..%GetComponentById("txtDefaultSchema").size = $l(DefaultSchema)+3
	Set ..%GetComponentById("txtSchemaPath").value = SchemaPath
	Set ..%GetComponentById("txtSchemaPath").size = $l(SchemaPath)+3
	Set ..%GetComponentById("txtPlanState").value = DisplayPlanState
	Set ..%GetComponentById("txtUserName").value = UserName
	Set ..%GetComponentById("txtUserName").size = $l(UserName)+3
	Set ..%GetComponentById("txtClientName").value = ClientName
	Set ..%GetComponentById("txtClientName").size = $l(ClientName)+3
	Set ..%GetComponentById("txtClientIP").value = ClientIP
	Set ..%GetComponentById("txtClientIP").size = $l(ClientIP)+3
	Set ..%GetComponentById("txtClientApp").value = ClientApp
	Set ..%GetComponentById("txtClientApp").size = $l(ClientApp)+3
	Set ..%GetComponentById("txtCallStack").value = CallStack
	If PlanState=1||(PlanState=2) {
		// If frozen, force a recheck
		Do ..RecheckFrozenPlan(hash)
	} Else {
		Set ..%GetComponentById("txtPlanFrozenDifferent").hidden = 1
		//Set ..%GetComponentById("btnRefreshFrozen").hidden = 1
	}
	If PlanVersion'="" {
		Set v=$SYSTEM.Version.GetMajor(PlanVersion)_"."_$SYSTEM.Version.GetMinor(PlanVersion)_"."_$case($SYSTEM.Version.GetPoint(PlanVersion),"":0,:$SYSTEM.Version.GetPoint(PlanVersion))_"."_$SYSTEM.Version.GetBuildNumber(PlanVersion)
		Set ..%GetComponentById("txtPlanVersion").value = v
		Set ..%GetComponentById("txtPlanVersion").size = $l(v)+3
		Set ..%GetComponentById("txtPlanVersion").title = $$$FormatText($$$Text("This is the version that was installed when this plan was last saved.  The entire version string for this plan is: '%1'"),PlanVersion)
	}
	Else {
		Set ..%GetComponentById("txtPlanVersion").hidden = 1
	}
	If PlanError'="" {	// display plan error
		Set ..%GetComponentById("txtPlanError").value = PlanError
		Set ..%GetComponentById("grpPlanError").hidden = 0
		Set ..%GetComponentById("txtPlanError").size = $l(PlanError)+3
	}
	Else {	// No plan error
		Set ..%GetComponentById("txtPlanError").value = ""
		Set ..%GetComponentById("grpPlanError").hidden = 1
	}
	If PlanState {
		Set ..%GetComponentById("txtPlanTS").value = PlanTS
	}
	ElseIf PlanTS="" {	// never frozen
		Set ..%GetComponentById("txtPlanTS").value = ""
		Set ..%GetComponentById("txtPlanTS").hidden = 1
	}
	Else {
		Set ..%GetComponentById("txtPlanTS").value = PlanTS
		Set ..%GetComponentById("txtPlanTS").hidden = 0
		Set ..%GetComponentById("txtPlanTS").size = $l(PlanTS)
	}
	Set tmp=..%GetComponentById("txtPlanCount"),tmp.value = Count
	Set tmp=..%GetComponentById("txtPlanTotal"),tmp.value = Total
	Set tmp=..%GetComponentById("txtPlanAverage"),tmp.value = Average
	If $L(Average) > 13 Set tmp.size = $L(Average)
	Set tmp=..%GetComponentById("txtPlanStdDev"),tmp.value = StdDev
	Set tmp=..%GetComponentById("txtPlanRowCount"),tmp.value = RowCount
	Set tmp=..%GetComponentById("txtPlanAverageRowCount"),tmp.value = ..GetDisplayAverageCount(AverageRowCount)
	Set tmp=..%GetComponentById("txtPlanCommands"),tmp.value = Commands
	Set tmp=..%GetComponentById("txtPlanAverageCommands"),tmp.value = ..GetDisplayAverageCount(AverageCommands)
	If FirstStat'="" {
		Set FirstStat=$zd(FirstStat,3)
	}
	Set tmp=..%GetComponentById("txtPlanFirst"),tmp.value = FirstStat
	Set tmp=..%GetComponentById("txtPlanAverageCount"),tmp.value = ..GetDisplayAverageCount(AverageCount)
	Set %session.Data($Username,"SQL","StatementText") = $g(Statement)
	Set %session.Data($Username,"SQL","StatementPlanError") = (PlanError'="")
	Set %session.Data($Username,"SQL","StatementPlanState") = PlanState
	Set %session.Data($Username,"SQL","StatementSelectMode") = SelectMode
	Set %session.Data($Username,"SQL","StatementSchemaPath") = $listfromstring(SchemaPath)
	If $G(DefaultSchema)'="" {
		Set tmp=$listfromstring(DefaultSchema),packages=""
		For i=1:1:$ll(tmp) { Set packages=packages_$lb($$GetPackage^%apiDDL($lg(tmp,i))) }
		Set %session.Data($Username,"SQL","StatementPackages") = packages
	}
	Else {
		Set %session.Data($Username,"SQL","StatementPackages") = ""
	}
	Set tExpandoState = $G($$$IRISTempMgt($Username,..%GetPageName(),"ExpandoState"))
	If tExpandoState '= "" {
		For n = 1:1:6 {
			Set ..%GetComponentById("expando"_n).expanded = $P(tExpandoState,",",n)
		}
	}
	Quit $$$OK
}

ClientMethod onloadHandler(load) [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	try {
		if (this.hashError) {
			this.showMsg($$$Text("Statement with this hash not present"),true);
		}
		if (this.OpenInTab == 1) {
			zen('btnQueryTest').setHidden(false);	
		} else {
			zen('btnClose').setHidden(false);	
		}
		this.checkButtonStatus();
		this.showCompare(0);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onloadHandler');
	}
}

ClientMethod checkButtonStatus() [ Language = javascript ]
{
	var buttons = "btnFreezePlan,btnUnFreezePlan,btnClearStatistics";
	var buttonArray = buttons.split(",");
	var btnName;
	var button;
	for (var n=0; n<buttonArray.length; n++) {
		btnName = buttonArray[n];
		button = zen(btnName);
		if (button.disabled) {	
			button.setProperty('controlClass','commandButtonDisabled');
		} else {
			button.setProperty('controlClass','commandButton');
		}
	}
}

ClientMethod showCompare(reload) [ Language = javascript ]
{
	var state = parseInt(this.PlanState);
	if (state == 1 || state == 2) {
		if (reload) {
			var html = zen('statementGroup8');
			html.seed = 1;
			html.refreshContents();		
		}
		zen('compareGroup').setProperty('hidden',false);
	}
}

ClientMethod updateParentTable() [ Language = javascript ]
{
	var opener = this.getOpener();
	if (opener) {
		opener.zenPage.statementRefresh();
	}
}

/// This will return the exact same AverageCount as from StatementIndexAll fo %SQL.Manager.Catalog
ClassMethod GetDisplayAverageCount(averagecount)
{
	RETURN $s(averagecount="":"",averagecount\1=+averagecount:+averagecount,1:$fnumber(averagecount,"",4-$zlog($zabs(averagecount)+0.001)))
}

}
