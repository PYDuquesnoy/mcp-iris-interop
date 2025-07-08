/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Extend to this class for pages that use tablePane as main component and needs auto-refresh to be shown on the ribbon bar.
/// 
/// For example, Home->Operations->Databases or Processes.
/// 
Class %CSP.UI.Portal.Utils Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.UtilsNav) [ Abstract, System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Template with Auto-Refresh";

Property CurrentColumn As %ZEN.Datatype.string;

Property CurrentSort As %ZEN.Datatype.string [ InitialExpression = "asc" ];

Property captionLastUpdate As %ZEN.Datatype.string [ InitialExpression = {$$$TextJS("Last update: ")} ];

XData Style
{
<style type="text/css">
/* light blue for Operations pages
.ribbonTitle {
	background: #C7E4EC;
}*/
</style>
}

/// *****        Refresh Feature for tablePane pages in SMP     ***** <br/>          
/// <p>The following methods are used by pages that want to display Refresh on/off and allow to enter refresh rate (number of seconds.) 
/// Sub-classes may over-ride them but please do not modify them unless you take care of all pages that use them and test each page thoroughly. 
/// When used, the tablePane on your page may be refreshed at the rate you define, and will remember the state, rate, current column and sort order.</p>
/// <p>To use this feature, do the following (see %CSP.UI.Portal.OpDatabases.cls for example):</p>
/// <ul> 
/// <li>Class extend to %CSP.UI.Portal.Utils</li>
/// <li>Add the following code: <code><timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/></code></li><br/> 
/// <li>Use tablePane with id="table" and add event onheaderClick for column sort.</li><br/> 
/// <li>Add to %OnAfterCreatePage to get TableState and AutoRefreshRate set into timeout.</li><br/> 
/// <li>In method OnDrawRibbon, add <code>Do ..DrawAutoRefresh(..%GetPageName())</code></li><br/> 
/// <li>Override updateView() if your class has Filter turned on for tableNavigatorBar.</li><br/> 
/// </ul> 
/// This method can be called from OnDrawRibbon of your UI Zen page. Pass in the page name which should be consistent with how the temp global is saved.
ClassMethod DrawAutoRefresh(pRefreshName)
{
	Set msgSeconds = $$$Text("refreshing interval in number of seconds (5 - 36000)")
	Set tRefresh = $$$TextHTML("Refresh the table")
	Set tSeconds = $$$TextHTML("sec")
	Set tImage = ##class(%CSP.Page).Link("deepsee/loop_24.gif")
	Set tState = $G($$$IRISTempMgt($Username,pRefreshName,"AutoRefreshState"),0)
	Set tRate = $G($$$IRISTempMgt($Username,pRefreshName,"AutoRefreshRate"),10)
	Set tLastTime = ..LastUpdateTime()
	&html<<td style="padding-left:20px;"><img src="#(tImage)#" class="icon" title="#(tRefresh)#" onclick="zenPage.updateView();" onmouseover="this.className='iconHover';" onmouseout="this.className='icon';"/></td>>
	&html<<td style="padding-left:2px;padding-right:20px;" nowrap><div id="formRefresh" name="formRefresh">>
	If ##class(%CSP.Portal.Utils).%IsAutoRefreshEnabled() {
		&html<
			<span id="id_refresh" style="font-size:10pt;color:#606060;font-weight:bold;">#($$$TextHTML("Refresh:"))#</span>
			<input id="refreshOff" name="refreshonoff" type="radio" #($S(tState=0:"checked",1:""))# onclick="return zenPage.setRefreshMode(false);"/><span onclick="zenPage.setRefreshMode(false);">#($$$Text("off"))#</span>
			<input id="refreshOn" name="refreshonoff" type="radio" #($S(tState=1:"checked",1:""))# onclick="return zenPage.setRefreshMode(true);"/><span onclick="zenPage.setRefreshMode(true);">#($$$Text("on"))#</span>
			<input id="refreshRate" name="refreshRate" type="number" min="5" max="36000" title="#(msgSeconds)#" size="2" value="#(tRate)#" onchange="zenPage.setRefreshRate(this.value);" onkeypress="zenPage.refreshkeyUp(event,this.value);"><span style="font-size:0.8em;">&nbsp;#(tSeconds)#</span>		
		>
	} 
	&html<<span id="id_refresh_time" style="font-size:10pt;color:#606060;font-weight:bold;">#(tLastTime)#</span>>
	&html<</div></td>>
	Quit
}

/// User clicked a column header to sort. Save that so we can come back to it when page is refreshed.
ClientMethod columnSort(currColumn, sortOrder) [ Language = javascript ]
{
	this.CurrentColumn = currColumn;
	this.CurrentSort = sortOrder;
	this.UpdateTableState(currColumn,sortOrder);
	this.updateView();
}

/// Check if user hit [Enter] on refreshRate textbox.
ClientMethod refreshkeyUp(evnt, value) [ Language = javascript ]
{
	var ok = false;
	if (evnt.keyCode) {
		if (evnt.keyCode == 13) ok = true;
	} 
	if (evnt.which) {
		if (evnt.which == 13) ok = true;
	}
	if (ok) {
		this.setRefreshRate(value);	
	}
}

/// Turn auto-refresh mode on and off.
ClientMethod setRefreshMode(newMode) [ Language = javascript ]
{
	if (newMode) {
		var refreshRate = self.document.getElementById("refreshRate").value;
		// now convert it to milliseconds
		refreshRate = parseInt(refreshRate*1000);
		// then start the timer
		zen('refreshTimer').setProperty('timeout',refreshRate);
		zen('refreshTimer').startTimer();
	}
	else {
		// user turned refresh off - clear timer
		zen('refreshTimer').clearTimer();
	}
	// update flags on the server
	this.UpdateAutoRefreshState((newMode==true) ? 1 : 0);	
	return true;
}

/// This method returns current date and time in $ZDT($ZU(188),3,,3) format
ClientMethod getTime() [ Language = javascript ]
{
	var date = new Date();
	var now = date.getFullYear() + "-" + (this.zeroFill(date.getMonth()+1)) + "-" + this.zeroFill(date.getDate()) + " " + this.zeroFill(date.getHours()) + ":" + this.zeroFill(date.getMinutes()) +  ":" + this.zeroFill(date.getSeconds()) + "." + date.getMilliseconds();
	return now;
}

ClientMethod zeroFill(value) [ Language = javascript ]
{
	if (value < 10) return "0"+value;
	return value;
}

ClientMethod updateTime() [ Language = javascript ]
{
	var now = this.captionLastUpdate + this.getTime();
	self.document.getElementById("id_refresh_time").innerHTML = now;
}

/// Table auto-refresh timer handler.
ClientMethod refreshHandler() [ Language = javascript ]
{
	var refresh = document.getElementById('id_refresh');
	if (refresh) {
		refresh.style.backgroundColor = '#D0F8D0';
	}
	this.updateView(true);
	if (refresh) {
		zen('refreshTimer').startTimer();
		refresh.style.backgroundColor = '';
	}
}

/// User changed refresh rate. Validate it and save value to server.
ClientMethod setRefreshRate(newRate) [ Language = javascript ]
{
	try {
		var refreshRate = zenTrim(newRate);
		if ((refreshRate == "") || (isNaN(refreshRate)==true) || (refreshRate < 5) || (refreshRate > 36000)){
			// 10 seconds default refresh interval
			refreshRate = 10;
			self.document.getElementById('refreshRate').value = refreshRate;
		} 
		// save this rate to server
		this.UpdateAutoRefreshRate(refreshRate);
		// if refresh is turned on, then reset the timer
		if (document.getElementById("refreshOn").checked) {
			zen('refreshTimer').clearTimer();
			zenPage.setRefreshMode(true);
		}
	}
	catch (ex) {
		zenExceptionHandler(ex,arguments,'Error in setRefreshRate');
	}
}

/// Update / Reload table. Subclass may override this method. Do not modify this method unless you are going to take care of all pages that use it.
ClientMethod updateView() [ Language = javascript ]
{
	var table = zen("table");
	table.executeQuery();
	table.currColumn = this.CurrentColumn;
	table.sortOrder = this.CurrentSort;
	this.updateTime();
}

ClassMethod LastUpdateTime() As %String [ ZenMethod ]
{
	Quit $$$FormatText($$$Text("Last update: %1"),$ZDT($ZU(188),3,,3))
}

/// Save auto refresh rate (how many seconds user entered) to server.
ClassMethod UpdateAutoRefreshRate(refreshrate As %Integer) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,..%GetPageName(),"AutoRefreshRate") = refreshrate
}

/// Save auto refresh state (Refresh on or off) ito server.
ClassMethod UpdateAutoRefreshState(refreshstate) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,..%GetPageName(),"AutoRefreshState") = refreshstate
}

/// Save current column and state to server so that when page is refreshed or reloaded the sort and state remain the same.
ClassMethod UpdateTableState(currColumn As %String, sortOrder As %String) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,..%GetPageName(),"TableState") = $lb(currColumn,sortOrder)
}

/// *****      End of Refresh Feature for tablePane    ***** 
/// ********************************************************///
/// If Refresh Feature is turned on, then clearTimer before exist.
ClientMethod onunloadHandler() [ Language = javascript ]
{
	if (this.pageModified) {
		return $$$Text('Changes have been made on this page.')+'\n'+$$$Text('Do you wish to leave the page and discard the changes?');
	}
	if (zen('refreshTimer')) {
		zen('refreshTimer').clearTimer();	
	}
	return true;
}

/// Use this method to build a meter for Dashboard. (See example for usage in %CSP.UI.Portal.ProcessDetails.cls)
ClassMethod BuildMeter(pLabel, pProperty, pWidth, pLink, pDetails) As %CSP.Util.HTMLValueMeter
{
	Set tMeter = ##class(%CSP.Util.HTMLValueMeter).%New()
	Set tMeter.Label = pLabel
	Set tMeter.Property = pProperty
	Set tMeter.Width = pWidth
	Set tMeter.Link = pLink
	Set tMeter.Detail = pDetails
	Quit tMeter
}

/// Be sure to do ##super() when overriding.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	$$$SetRefreshTimer
	Set TableState = $G($$$IRISTempMgt($Username,..%GetPageName(),"TableState"))
	If TableState'="" {
		Set ..CurrentColumn = $lg(TableState,1),..CurrentSort = $lg(TableState,2)
		Set ..%GetComponentById("table").currColumn = ..CurrentColumn
		Set ..%GetComponentById("table").sortOrder = ..CurrentSort
	}
	Do ..%GetNavTableState()	
	Quit $$$OK
}

}
