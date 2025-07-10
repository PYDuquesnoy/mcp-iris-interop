/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Display activity numbers and charts by last minute, last hour, last day, last month or Year.
Class EnsPortal.ActivityVolumeAndDuration Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// User needs USE permissions on the %Ens_Dashboard resource to access this page.
Parameter RESOURCE = "%Ens_Dashboard:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Activity Volume And Duration";

Property winHeight As %Integer [ InitialExpression = 750 ];

Property winWidth As %Integer [ InitialExpression = 1600 ];

Property currentPeriod As %String [ InitialExpression = "Minute" ];

Property refreshRate As %Integer [ InitialExpression = 0 ];

/// This XML block defines the contents of this pane.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" align="left" valign="middle">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<timer id="dummyTimer" timeout="0" ontimeout="zenPage.testConnectivity();zenThis.startTimer();"/>
<spacer height="10px" />
<label id="msgText1" value="Period from 1/1/2014 until 12/31/2030" enclosingClass="message" hidden="true" />
<spacer height="10px" />
<vgroup id="msgText2" hidden="true">
<label value="No data for the selected period" enclosingClass="message" />
<spacer height="10px" />
</vgroup>
<iframe id="chartFrame" frameBorder="false" width="#(%page.winWidth)#" height="#(%page.winHeight)#" enclosingStyle="margin-left:20px;" />
</pane>
}

XData Style
{
<style type="text/css">
.message {
	font-size: 14px;
	margin-left: 50px;
}

.messageError {
	font-size: 18px;
	color: darkred;
	margin-left: 50px;
	margin-top: 20px;
}
</style>
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
	Do ##class(Ens.DeepSee.ActivityVolumeAndDurationKPI).GetPeriod(..currentPeriod, .begin, .end)
	Set tMsg = ..%GetComponentById("msgText1")
	Set tMsg.value = $$$FormatText($$$Text("Period from %1 until %2"),begin,end)
	Set tChartFrame = ..%GetComponentById("chartFrame")
	If ##class(%DeepSee.Utils).%IsDeepSeeEnabled() {
		Kill tQuery
		Set tChartFrame.src = ..Link("_DeepSee.UserPortal.DashboardViewer.zen?EMBED=1&NOBORDER=1&DASHBOARD=Ens%2FAnalytics%2FActivityVolumeAndDuration.dashboard", .tQuery) // &SETTINGS=FILTER:Period."_..currentPeriod
	}
	Else {
		Set txt1 = ..%GetComponentById("msgText1")
		Set txt1.value = "Analytics is not currently enabled for this namespace, therefore dashboards cannot be displayed."
		Set txt1.enclosingClass = "messageError"
		Set txt1.hidden = 0
	}
	Quit $$$OK
}

/// Switch the chart to the one corresponding to the button clicked (Minute, Hour, Day, Week, Month or Year).
ClientMethod displayChart(current) [ Language = javascript ]
{
	zenPage.updateType(current);
	var frame = zenPage("chartFrame");
	frame.src = zenLink("_DeepSee.UserPortal.DashboardViewer.zen?EMBED=1&NOBORDER=1&DASHBOARD=Ens%2FAnalytics%2FActivityVolumeAndDuration.dashboard") // &SETTINGS=FILTER:Period." + current
}

/// Update ribbon button styles, disabling 'current' and enabling all others.
ClientMethod updateType(current) [ Language = javascript ]
{
	return;

	(document.getElementById('command_cmdMinute')).className = 'commandButton';
	(document.getElementById('command_cmdHour')).className = 'commandButton';
	(document.getElementById('command_cmdDay')).className = 'commandButton';
	(document.getElementById('command_cmdWeek')).className = 'commandButton';
	(document.getElementById('command_cmdMonth')).className = 'commandButton';
	(document.getElementById('command_cmdYear')).className = 'commandButton';

	var indicator = document.getElementById('modifiedIndicator');

	switch (current) {
		case 'Minute':
			(document.getElementById('command_cmdMinute')).className = 'commandButtonDisabled';
			indicator.innerHTML = " - " + $$$Text("Minute")
			break;
		case 'Hour':
			(document.getElementById('command_cmdHour')).className = 'commandButtonDisabled';
			indicator.innerHTML = " - " + $$$Text("Hour")
			break;
		case 'Day':
			(document.getElementById('command_cmdDay')).className = 'commandButtonDisabled';
			indicator.innerHTML = " - " + $$$Text("Day")
			break;
		case 'Week':
			(document.getElementById('command_cmdWeek')).className = 'commandButtonDisabled';
			indicator.innerHTML = " - " + $$$Text("Week")
			break;
		case 'Month':
			(document.getElementById('command_cmdMonth')).className = 'commandButtonDisabled';
			indicator.innerHTML = " - " + $$$Text("Month")
			break;
		case 'Year':
			(document.getElementById('command_cmdYear')).className = 'commandButtonDisabled';
			indicator.innerHTML = " - " + $$$Text("Year")
			break;
		default:
			break;
	}
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Activity Volume And Duration")
	Quit $$$OK
}

Method OnDrawRibbon() As %Status
{
	If ##class(%DeepSee.Utils).%IsDeepSeeEnabled() {
		If ..enableAutoRefresh {
			Set tRibbonMessage = $$$TextHTML("Dashboard auto-refreshes every 60 seconds.")
		}
		Else {
			Set tRibbonMessage = $$$TextHTML("Click the Refresh button to update the dashboard.")
		}
		&html<
		<td nowrap style="padding-left:30px;">
		<span id="msgRibbon" style="font-size:10pt;color:#606060;">#(tRibbonMessage)#</span>
		</td>
		>
	}
	Quit $$$OK
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Activity Volume And Duration")
}

Method %OnGetTitle() As %String
{
	Quit $$$Text("Activity Volume And Duration")
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zenPage.winHeight = zenGetWindowHeight()-30;
	zenPage.winWidth = zenGetWindowWidth()-60;
	zenPage.updateType('Minute');
	var chart = zen('chartFrame');
	if (chart) {
		if (zenPage.winHeight>750) chart.setProperty('height',zenPage.winHeight);
		if (zenPage.winWidth>1600) chart.setProperty('width',zenPage.winWidth);
	}

	if (zenPage.enableAutoRefresh) {
		zen('dummyTimer').setProperty('timeout',60000);
		zen('dummyTimer').startTimer();
		zenPage.refreshRate = 5;
	}
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		if (!load) {
			zenPage.winHeight = zenGetWindowHeight()-30;
			zenPage.winWidth = zenGetWindowWidth()-60;
			var chart = zen('chartFrame');
			if (chart) {
				if (zenPage.winHeight>750) chart.setProperty('height',zenPage.winHeight);
				if (zenPage.winWidth>1600) chart.setProperty('width',zenPage.winWidth);
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler.');
	}
}

}
