/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsUtil

/// This is the Message Bank Event Log page of the ZEN application.
Class Ens.Enterprise.Portal.MsgBankEventLog Extends (EnsPortal.EventLog, Ens.Enterprise.Portal.base) [ Inheritance = right, System = 4 ]
{

/// User needs USE privilege on the %Ens_MsgBank_EventLog resource to view this page.
Parameter RESOURCE = "%Ens_MsgBank_EventLog:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Message Bank Event Log";

/// Comma-separated list of additional JS include files for the page - for Event Details popup.
Parameter JSINCLUDES = "ensemble/Ensemble_Utils.js";

Property canViewTrace As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MsgBank_MessageTrace","USE")} ];

Property tracePage As %ZEN.Datatype.string [ InitialExpression = "Ens.Enterprise.Portal.VisualTrace.zen" ];

/// This pane displays event log activity table. User may click on a row and details are displayed to the side.
XData resultsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<vgroup valign="top">
<!--<spacer height="5"/>-->
<tablePane id="table" 
	dataSource="columns"
	tableName="Ens_Enterprise_MsgBank.Log"
	useSnapshot="false"
	showZebra="true"
	valueColumn="ID"
	maxRows="30"
	useKeys="true"
	showQuery="false"
	onselectrow="zenPage.selectItem(zenThis);"
	nowrap="true" 
	onmouseoverClass="tpMouseOver"
	enableToggleSelect="true"
	onupdate="setTimeout('zenPage.onAfterSearch();',50);"
	unlockSession="true"
	>
<!-- provide header values for all columns so they can be localized -->
<column header="ID" colName="ID" style="text-align:left;" width="90"
		title="Message Bank Log Event ID"/>
<column header="Time Logged" colName="TimeLogged999" id="idTimeLogged999" width="135" colExpression="{fn RIGHT(%EXTERNAL(TimeLogged),999)}" 
		title="Time the event was noted in the log" hidden="true" />
<column header="Time Logged" colName="TimeLogged12" id="idTimeLogged12" width="135" colExpression="{fn RIGHT(%EXTERNAL(TimeLogged),12)}" 
		title="Time the event was noted in the log" />
<!-- need to sort out the SQL details here -->
<!--<column header="Client" colName="Client" colExpression="(Name FROM Ens_Enterprise_MsgBank.Node WHERE ID = log.NodeId)" />-->
<column header="Type" colName="Type" style="text-align:left;" width="90" OnDrawCell="DrawLocalType"
		title="Alert, Assert, Error, Info, Trace, or Warning"/>
<column header="Session" colName="SessionId" width="90"
        title="Message Bank Session ID"
        link=" "
        OnDrawCell="DrawSessionCell" />
<column header="Job" colName="Job" width="90"
        title="System job in which the event occurred"
        OnDrawCell="DrawMethodCell" />
<column header="Source" colName="ConfigName" width="180"
        title="Configuration name of the item that triggered the event"
        OnDrawCell="DrawMethodCell" />
<column header="Text" colName="Text"
        title="Descriptive text logged with the event"
        OnDrawCell="DrawTextCell" />
<column colName="TraceCat" hidden="true"/>
<column colName="SourceClass" hidden="true"/>
<column colName="SourceMethod" hidden="true"/>
<!-- we will not be switching colors by user preference; we will always use zebra plus 1-column color coding -->
<condition id="condAlert" colName="Type" predicate="EQ" value="Alert" targetCol="Type" cellStyle="background: yellow; color: darkred; font-weight: bold;" />
<condition id="condError" colName="Type" predicate="EQ" value="Error" targetCol="Type" cellStyle="background: pink; color: darkred; font-weight: bold;" />
<condition id="condWarning" colName="Type" predicate="EQ" value="Warning" targetCol="Type" cellStyle="background: orange; color: darkred; font-weight: bold;" />
<condition id="condAssert" colName="Type" predicate="EQ" value="Assert" targetCol="Type" cellStyle="background: silver; color: darkred; font-weight: bold;" />
<condition id="condTrace" colName="Type" predicate="EQ" value="Trace" targetCol="Type" cellStyle="background: lightblue; color: darkblue; font-weight: bold;" />
<!-- it does not work to have a condition Type EQ Info and also have Method EQ Start/StopProduction so no condition on Type EQ Info -->
<condition id="condStart" colName="SourceMethod" predicate="EQ" value="StartProduction" targetCol="Type" cellStyle="background: lightgreen; color: darkgreen; font-weight: bold;" />
<condition id="condStop" colName="SourceMethod" predicate="EQ" value="StopProduction" targetCol="Type" cellStyle="background: lightgreen; color: darkgreen; font-weight: bold;" />
</tablePane>
<!-- set default auto refresh to "None" -->
<timer id="timer" ontimeout="zenPage.timeout(zenThis);" timeout="0"/>
</vgroup>
</pane>
}

/// Server-side method to write out the content for the SessionId column.
/// The main purpose is to ensure that links to the Visual Trace diagram are only included
/// for events which occurred as part of a session.
Method DrawSessionCell(table As %ZEN.Component.tablePane, name As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
	Set tSessionId = $get(%query("SessionId"))
	If tSessionId = "" {
		&html<&nbsp;>
	} Else {
		/* If wanted to Display Client Session Id then we will change second tSessionId to $E(tSessionId,4,*) */
		&html<<a class="sessionLink" title="#(..EscapeHTML(..sessionLinkTitle))#" onclick="zenPage.showTrace('#($ZCVT($ZCVT(tSessionId,"O","JS"),"O","HTML"))#',true,event); return false;">#(..EscapeHTML(tSessionId))#</a>>
	}
	Quit $$$OK
}

/// Control for ConfigName
XData configNameControl [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<text name="ConfigName" id="ConfigName" label="Source Config Item" size="18" containerStyle="padding:0px 3px 0px 0px;"
		title="Choose and enter values in these fields, then click the Search button."
		/>
</pane>
}

/// Server-side callback to provide data for the details table
ClassMethod DrawEventDetails(pSeed As %String) As %Status
{
	Quit ##class(EnsPortal.Utils).DrawEventInfo(pSeed,1,1,1)
}

/// User clicked the Purge button
ClientMethod startPurge() [ Language = javascript ]
{
	var conf = $$$Text("Are you sure you want to purge the Message Bank Event Log now?");
	var nan = $$$Text("Value entered for number of days is not a number.");
	var npos = $$$Text("Value entered for number of days is not a positive number.");
	var count = $$$Text("Number of records purged:");
	var fail = $$$Text("Message Bank Event Log purge did not succeed:");

	zenPage.countReset(); // update current count
	if (confirm(conf)) {
		// find out how many days back to purge
		var num = zen('keepDays').getValue();
		if (isNaN(num)) {
			alert(nan);
			return false;
		}
		else if (num < 0) {
			alert(npos);
			return false;
		}
		
		// do the purge and process the results
		var ret = zenPage.DoPurge(num);
		if (ret[0] == '-') { // our failure code
			alert(fail + ' ' + ret.substring(1));
		}
		else {
			if (parseInt(ret) > 0) {
				zenPage.doSearch(); // refresh the display
				zenPage.countReset(); // update current count
			}
			alert(count + " " + ret); // confirm purge
		}
	}
	return true;
}

/// Fill search criteria defaults
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	// Override captions from EnsPortal.EventLog
	Set tPurgeExpando = ..%GetComponentById("expPurge")
	Set tPurgeExpando.caption = $$$TextHTML("Purge Message Bank Event Log")

	Set tLogTotal = ..%GetComponentById("logTotal")
	Set tLogTotal.title = $$$TextHTML("Total number of Message Bank Event Log entries. To update, double-click the field.")

	Set tKeepDays = ..%GetComponentById("keepDays")
	Set tKeepDays.title = $$$TextHTML("Set a value to avoid purging the most recent Message Bank Event Log entries.")

	Set tStartPurgeButton = ..%GetComponentById("startPurgeButton")
	Set tStartPurgeButton.title = $$$TextHTML("Start purging Message Bank Event Log entries.")

	Quit $$$OK
}

Method GetSearchCriteria() As %String [ CodeMode = expression, Private ]
{
$get(^IRIS.Temp.EnsPortal($Username,"MsgBankEventLog","SearchCriteria"),"Newest First^999^^1,1,1,1,1,1^500^0,0,0,0,0^1")
}

Method GetColumnsAndFrom(timeFormat As %String) As %String
{
	If $get(timeFormat) = "" Set timeFormat = 999
	Quit "ID,{fn RIGHT(%EXTERNAL(TimeLogged),999)} TimeLogged999,{fn RIGHT(%EXTERNAL(TimeLogged),12)} TimeLogged12,Type,SessionId,Job,ConfigName,Text,TraceCat,SourceClass,SourceMethod FROM Ens_Enterprise_MsgBank.Log "
}

ClassMethod GetCount() As %Integer [ ZenMethod ]
{
	Quit ##class(Ens.Enterprise.MsgBank.Purge).EventLogCount()
	Quit 0
}

/// Perform the purge operation and if there is an error, return the message
/// to JavaScript by prepending the message with a '-'. If no error then 
/// return the zero or positive number of entries deleted, as a string.
ClassMethod DoPurge(keep As %Integer) As %String [ ZenMethod ]
{
	Set LogsDeleted = 0
	Set status = ##class(Ens.Enterprise.MsgBank.Log).Purge(.LogsDeleted,keep)

	If ($$$ISERR(status)) {
		Quit "-" _ $ZCVT($System.Status.GetErrorText(status),"O","JS") 
		}
	Else {
		Quit LogsDeleted 
	}
	Quit 0
}

ClassMethod SetDefaultString(pDefaults As %String = "") [ Private ]
{
	If pDefaults = "" {
		Kill ^IRIS.Temp.EnsPortal($username,"MsgBankEventLog","SearchCriteria")
	}
	Else {
		Set ^IRIS.Temp.EnsPortal($username,"MsgBankEventLog","SearchCriteria") = pDefaults
	}
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Message Bank Event Log")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("searchButton",$$$Text("Search"),$$$Text("Search and view events that have been archived in the Message Bank Event Log using the current criteria"),"zenPage.doSearch();")
	Set pCommands(2) = $LB("resetButton",$$$Text("Reset"),$$$Text("Reset the Message Bank Event Log search criteria to their default values"),"zenPage.formReset();")
	Set pCommands(3) = $LB("prevButton",$$$Text("Previous"),$$$Text("Show the previous page of results, based on the Page Size"),"zenPage.getNextData(false);")
	Set pCommands(4) = $LB("nextButton",$$$Text("Next"),$$$Text("Show the next page of results, based on the Page Size"),"zenPage.getNextData(true);")
	Set pCommands(5) = $LB("viewButton",$$$Text("Viewer"),$$$Text("Search and view messages that have been archived in the Message Bank"),"zenPage.gotoPage('Ens.Enterprise.Portal.MsgBankViewer.zen');")
	Quit $$$OK
}

}
