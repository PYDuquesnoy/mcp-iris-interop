/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This page displays background tasks without the main header.
Class %CSP.UI.Portal.BackgroundTasks Extends (%ZEN.Component.page, %ZEN.Portal.abstractRefreshable) [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

/// Displayed name of this page.
Parameter PAGENAME = "BackgroundTasks";

/// Domain used for localization.
Parameter DOMAIN;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="">
<html id="header" OnDrawContent="%DrawTitle" />
<tablePane id="table" queryClass="%CSP.UI.System.BackgroundTask" queryName="EnumerateTasks"
showZebra="true" >
<column colName="SysBGTaskId" hidden="true"/>
</tablePane>
<timer id="timer" ontimeout="zenPage.timeout(zenThis);" timeout="0"/>
</page>
}

/// This client event, if present, is fired when the page is loaded.
/// Start the timer so we can refresh the table if AutoRefresh is enabled.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);
		
	if (zenPage.enableAutoRefresh) {
		var timer = zenPage.getComponentById('timer');	
		timer.setProperty('timeout',5000);
		timer.startTimer();
	}
}

ClientMethod timeout(timer) [ Language = javascript ]
{
	zenPage.doRefresh();
	if (zenPage.enableAutoRefresh) {
		timer.startTimer();
	}
}

ClientMethod doRefresh() [ Language = javascript ]
{
	var table = zen('table');
	table.refreshContents();
	var header = zen('header');
	header.refreshContents();
}

/// Provide HTML for standard template html title box.
Method %DrawTitle(pSeed As %String) As %Status
{
	// Get text line for page; subclass can customize this behavior
	Set tText = $$$Text("Current Background Tasks","%ZEN")

	Set msgUpdate = $$$Text("Last update: ","%ZEN")
	Set hlpUpdate = $$$Text("Click here to refresh this table.","%ZEN")
	Set hlpTime = $$$Text("Time when the contents of this page were last refreshed.","%ZEN")

	// show descriptive text
	&html<<table border="0" cols="2" cellpadding="3" width="80%"><tr>
		<td align="left" class="Text1">#($ZCVT(tText,"O","HTML"))#:</td>
		<td align="left" class="Text" nowrap width="30%" style='cursor:pointer;' valign="bottom">
		<div align="left" width="100%" style="border: 1px solid darkblue; background: white; padding: 0px; vertical-align: middle;">
		<span style="color: darkblue; font-size: 8pt;padding: 2px; vertical-align: middle;">
		<a title="#($ZCVT(hlpUpdate,"O","HTML"))#" onclick="zenPage.doRefresh();">&#032;#($ZCVT(msgUpdate,"O","HTML"))#</a>
		<span id="lastupdate" title="#($ZCVT(hlpTime,"O","HTML"))#" style="font-weight: bold;">#($ZDT($ZU(188),3,,3))#</span>
		</span>
		</div>
		</td>
		</tr>
		</table>>	
	
	Quit $$$OK
}

}
