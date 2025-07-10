/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsUtil

/// Created using the page template: Default
Class Ens.Enterprise.Portal.MonitorStatus Extends (EnsPortal.Template.viewerPage, Ens.Enterprise.Portal.base) [ Inheritance = right, System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Enterprise Monitor";

/// User needs USE permissions on the %Ens_MsgBank_Dashboard resource to view this page.
Parameter RESOURCE = "%Ens_MsgBank_Dashboard:USE";

/// Indicate whether toggle button for search pane should be displayed.
Parameter SHOWSEARCHTOGGLE As BOOLEAN = 0;

/// Flag to indicate whether the detailsPanel is currently hidden.
Property detailsHidden As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property canViewEvents As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(Ens.Enterprise.Portal.MsgBankEventLog).#RESOURCE)} ];

Property canViewMessages As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(Ens.Enterprise.Portal.MsgBankViewer).#RESOURCE)} ];

Property canViewSystems As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(Ens.Enterprise.Portal.SystemList).#RESOURCE)} ];

Property canViewMonitorRoles As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(Ens.Enterprise.Portal.MonitorRoleList).#RESOURCE)} ];

Property canViewSearch As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(Ens.Enterprise.Portal.EnterpriseSearch).#RESOURCE)} ];

Property resultsTableId As %ZEN.Datatype.id [ InitialExpression = "table" ];

Property pageSizeId As %ZEN.Datatype.id [ InitialExpression = "MaxRows" ];

Property pageNumberId As %ZEN.Datatype.id [ InitialExpression = "pageTotal" ];

Property detailsWidth As %ZEN.Datatype.integer(MAXVAL = 80, MINVAL = 5) [ InitialExpression = 80 ];

Property canViewTrace As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MessageTrace","USE")} ];

Property sessionLinkTitle As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Click to view a visual trace of the session")} ];

Property tracePage As %ZEN.Datatype.string [ InitialExpression = "EnsPortal.VisualTrace.zen" ];

Property matchSource As %ZEN.Datatype.string(ZENURL = "SOURCE");

Property startId As %ZEN.Datatype.string(ZENURL = "StartId");

Property endId As %ZEN.Datatype.string(ZENURL = "EndId");

Property roleCategories As %ZEN.Datatype.string;

Property refreshRate As %Integer [ InitialExpression = 0, Internal ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/*fieldSet styles*/
.fieldset{
     background: #FFFFFF;
     border: solid 2px #ebf3ff;
     color: #000000;
     font-size: 1em;
     font-family: helvetica;

}

html {
	overflow: hidden;
}

table.group td.msgBankLink {
	text-align: center;
	padding-left: 30px;
	padding-right: 30px;
}

.disabledMsgBankLink {
	text-decoration: none;
	color: gray;
}

.rowHighlighted {
	background: yellow;
}

.rowSelected {
	background: teal;
}

#table {
	overflow: auto;
}

iframe, #details {
	overflow: hidden;
}

#detailsGroup {
	overflow: visible;
}

#details > iframe {
	overflow: auto;
}

/* Bars */
.bars {
	position:relative; width:100px; height:14px; background:#eee; margin:0 6px;
}
	
.bar {
	line-height:14px; 
	height:14px; 
	font-size: 14px;
	position:absolute; top:0; left:0;
	overflow: hidden
}

.bar-error {background:red;}
.bar-inactive {background:#ffee00;}
.bar-stopped {background:#deffbc;}
.bar-disabled {background:#d0d0d0;}
.bar-ok {background:#20c020;}
.bar-none {background:#000000;}

</style>
}

XData searchPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane hidden="true" >
	</pane>
}

/// This XML block defines the contents of this page.
XData resultsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" title="">
<hgroup width="100%">
<spacer width="1em"/>
<vgroup>
<vgroup id="resultsStatusInfo">
<spacer height="2em"/>
<hgroup>
<spacer width="24px"/>
<html id="refreshLabel"/>
</hgroup>
<spacer height="1em"/>
<hgroup>
<spacer width="24px"/>
<html id="productionLabel"/>
</hgroup>
<spacer height="1em"/>
</vgroup>
<hgroup>
<tablePane id="table" valign="top"
             queryClass="Ens.Enterprise.Portal.MonitorModel"
             queryName="getMatrix"
	         rowSelect="true"
	         multiSelect="false"
	         enableToggleSelect="true"
	         width="30%"
	         onmouseoverClass="rowHighlighted"
	         valueColumn="ClientName"
	         onselectrow="zenPage.selectItem(zenThis.getProperty('value',''))"
	         onunselectrow="zenPage.hideDetailsTable()"
	         showRowSelector="true"
	         useSnapshot="true"
	         maxRows="1000">
<column colName="Color"         OnDrawCell="drawBarGraph" header=" " />
<column colName="ClientName"     header="Client Name" filterType="custom" OnDrawFilter="drawNewClientButton" />
<column colName="QueueCount"	 OnDrawCell="drawQueueCount" header="Queued" />
<column colName="Status"         header="Status" />
<column colName="ProductionName" header="Production Name" OnDrawCell="makeEnsPortalLink" />
<column colName="SystemSpecs"    header="System Management Portal" OnDrawCell="makeSysPortalLink"/>
<column colName="StartTime"      header="Start Time"/>
<column colName="UpdateReason" hidden="true" />
<column colName="WebIPAddress" />
<column colName="Namespace" />
<column colName="HomePage" hidden="true" />
<column colName="HomePath" style="display: none;" header=" "/>
<column colName="SSLConfig" style="display: none;" header=" "/>
<column colName="Version" hidden="true" />
<column colName="QueueThreshold" hidden="true" />
<parameter id="cnameParameter"    value="empty"/>
<parameter id="handlersEnabled" value="1" />
</tablePane>
</hgroup>
</vgroup>
</hgroup>
<timer id="refreshTimer" ontimeout="zenPage.refreshData(zenThis)" timeout="0" />
</pane>
}

XData detailsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<fieldSet id="detailsArea" hidden="true" width="100%" legend=" " valign="top">
<vgroup id="detailLabelArea">
<hgroup>
<html id="detailTable-label"/>
</hgroup>
<html id="updateLabel"/>
</vgroup>
<iframe id="detailsIFrame" src="" scrolling="auto" />
</fieldSet>
</pane>
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	&html<
	<td style="padding-left:6px;width:30px;">
		<image id="iconRefresh" src="deepsee/loop_24.gif" style="position:relative;top:4px" class="icon" title="Refresh Table" onclick="zenPage.refreshData(zenThis);" onmouseover="this.className='iconHover';" onmouseout="this.className='icon';"/>
	</td>
	>
	If ..enableAutoRefresh {
		
		Set msgSeconds = $$$Text("refreshing interval in number of seconds (minimum is 4)")
		Set refreshSeconds = ..refreshRate
		&html<
			<td nowrap style="padding-left:5px;padding-right:20px;">
			<div nowrap>
				<span id="id_refresh" style="font-size:10pt;color:#606060;font-weight:bold;">#($$$TextHTML("Refresh:"))#</span>
				<input style="padding-left:5px;" id="refreshRate" name="refreshRate" type="textbox" title="#(msgSeconds)#" size="2" value="#(refreshSeconds)#" onchange="zenPage.changeRefresh();"><span style="font-size:0.8em;" title="#(msgSeconds)#">&nbsp;#($$$Text("seconds"))#</span>
			</div></td>
			<td style="padding-right:20px;"></td>
		>
	}
	Quit $$$OK
}

/// Reload diagram with a fresh copy.
ClientMethod doRefresh() [ Language = javascript ]
{
	zenPage.refreshData(zenThis);
}

/// User chose a new Auto-Refresh value for the table; set a new timeout value and start the timer
ClientMethod changeRefresh() [ Language = javascript ]
{
	var rate = document.getElementById('refreshRate');
	if (rate) {
		var val = parseInt(rate.value,10);
		if ((val < 4) || isNaN(val)) {
			val = 4;
		}
		// save this rate to server
		this.UpdateAutoRefreshRate(val);
		rate.value = val;
		var timer = zen('refreshTimer'); //get timer
		timer.setProperty('timeout',val*1000); //set timeout
		timer.startTimer(); //restart timer
	}
}

/// Save auto refresh rate (how many seconds user entered) to server.
ClassMethod UpdateAutoRefreshRate(refreshrate As %Integer) [ ZenMethod ]
{
	Set ^EnsPortal.Settings($Username,"AutoRefreshRate",..%GetPageName()) = refreshrate
}

Method %OnAfterCreatePage() As %Status
{
	Set tRefreshTimer = ..%GetComponentById("refreshTimer")
	If $isobject(tRefreshTimer) && ..enableAutoRefresh {
		Set ..refreshRate = $Get(^EnsPortal.Settings($Username,"AutoRefreshRate",..%GetPageName()),4)
		Set tRefreshTimer.timeout = ..refreshRate * 1000
	}
	Set ..roleCategories = ""
	If $roles '= "" {
		// For each role the current user has ...
		For i=1:1:$LENGTH($roles,",") {
			// Get the list of categories, and merge them
			Set tID = $PIECE($roles,",",i)
			Set tCategories = ##class(Ens.Enterprise.MonitorRole).CategoriesGetStored(tID)
			For j=1:1:$LENGTH(tCategories,",") {
				Set tCategory = $PIECE(tCategories,",",j)
				If (tCategory '= "") {
					Set tCatArray(tCategory) = ""
				}
			}
		}
		Set tCat = ""
		Set tCatList = ""
		For {
			Set tCat = $order(tCatArray(tCat))
			Quit:(tCat = "")
			Set tCatList = tCatList _ $LB(tCat)
		}
		Set ..roleCategories = $LTS(tCatList)
	}
	#; Ensure temp data for remote web session tokens is cleaned up when local session ends
	Do ##class(EnsPortal.SessionEvents).Initialize()

	Quit ##super()
}

/// Fired when the page is loaded.
/// refresh the timestamp, the only part of 
/// of a new page reload that isn't query based (so isn't automatic)
/// no need to check the update reason, as no detail tables are shown on a fresh reload
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);

	//update in the refresh timestamp:
	zenPage.displayRefreshTimestamp();
}

/// This client event is fired when the page is resized.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	this.invokeSuper('onlayoutHandler', arguments);
	// Check access to other functions
	if (!zenPage.canViewSystems) {
		var systemsBtn = document.getElementById('command_systemsButton');
		systemsBtn.className = 'commandButtonDisabled';
	}
	if (!zenPage.canViewMonitorRoles) {
		var monitorRolesBtn = document.getElementById('command_monitorRolesButton');
		monitorRolesBtn.className = 'commandButtonDisabled';
	}
	if (!zenPage.canViewSearch) {
		var monitorRolesBtn = document.getElementById('command_msgViewerButton');
		monitorRolesBtn.className = 'commandButtonDisabled';
	}
	if (!zenPage.canViewMessages) {
		var monitorRolesBtn = document.getElementById('command_msgBankViewerButton');
		monitorRolesBtn.className = 'commandButtonDisabled';
	}
	if (!zenPage.canViewEvents) {
		var monitorRolesBtn = document.getElementById('command_msgBankEvtLogButton');
		monitorRolesBtn.className = 'commandButtonDisabled';
	}
	// Adjust table height since super assumes only resultsTable not status section
	this.adjustTableHeight();
}

/// Adjust table height to account for status section
ClientMethod adjustTableHeight() [ Language = javascript ]
{
	try {
		var statusInfo = zenPage.getComponentById('resultsStatusInfo');
		var statusInfoDiv = statusInfo.getEnclosingDiv();
		var statusInfoHgt = statusInfoDiv.offsetHeight;
		var resultsTable = zenPage.getResultsTable();
		var resultsTableDiv = resultsTable.getEnclosingDiv();
		var maxHeight = this.getContentAreaHeight();
		resultsTableDiv.style.height = maxHeight - statusInfoHgt + "px";
	} catch (ex) {}
}

/// hide the details table, and zero out the detail table name
ClientMethod hideDetailsTable() [ Language = javascript ]
{
	//monitor.log('Hiding details');
	var table = zenPage.getComponentById('table');
	//hide the details table and it's labels and controls; and zero out the 
	//session data that holds the information needed to construct the table
	// (to prevent an invalid update reason being displayed)
	//var detailsArea = zenPage.getComponentById('detailsArea');
	//detailsArea.setProperty('hidden',true);
	if (!this.detailsHidden)
		this.toggleDetails();
	this.saveDetailTableName("");
	var detailTable =  zenPage.getComponentById('detailsIFrame');
	detailTable.setProperty('src',"");
}

/// called each time the timer goes off,
/// ensures that the data in the tables is current
/// because the queries are re-run and the page is not actually reloaded,
/// the page does not flicker, and onloadHandler() is not run.
ClientMethod refreshData(timer) [ Language = javascript ]
{
 //refresh the data of the main table:
   var table = zenPage.getComponentById("table");
   table.executeQuery();
                        
  //then; refresh the details table (if it is not up, it doesn't matter)
  //var dtable = zenPage.getComponentById("details");
  //dtable.executeQuery();
 
  //refresh the update reason label: 
  //zenPage.maybeDisplayUpdateReasonLabel();  
         
  //refresh the label showing the data's freshness/generated date and time
  zenPage.displayRefreshTimestamp();
		
  if (this.enableAutoRefresh) {
  	//restart the timer
  	timer.startTimer();
  }
}

/// redisplay the last time that the entire cycle of system status matrices was updated.
ClientMethod displayRefreshTimestamp() [ Language = javascript ]
{
	var html = zenPage.getComponentById('refreshLabel');
	if (html) {
		html.setProperty('content',this.getRefreshLabelText());
	}

	html = zenPage.getComponentById('productionLabel');
	if (html) {
		html.setProperty('content',this.getProductionLabelText());
	}
}

/// display the update reason, if it is blank then set the content
/// of the label to null, if it is present, then prepend label text to it
/// TODO: i18n the label text
ClientMethod displayUpdateReasonLabel(updateReason) [ Language = javascript ]
{
	var updateLabel = zenPage.getComponentById('updateLabel');
  	if (!updateReason) {
	  updateLabel.setProperty('content',"");
  	} else {
	  updateLabel.setProperty('content', '<h4>' + $$$Text('Update Reason') + ': ' + updateReason + "</h4>");
  	}
}

/// this method checks if a details table is up- (is there a details table name?)
/// and if so, then uses that name to get the update reason string, and then
/// displays it.  called by the refresh timer
ClientMethod maybeDisplayUpdateReasonLabel() [ Language = javascript ]
{
	var cname = this.getDetailTableName();
	if (cname !="") {
		zenPage.displayUpdateReasonLabel(this.getUpdateReasonString(cname));
	}
}

/// The input value is the name of the new namespace to switch to.
/// This method will need to be overridden for classes such as EnsPortal.EDIDocumentView 
/// which cannot work without a URL parameter provided.
ClientMethod changeURLNamespace(value) As %String [ Language = javascript ]
{
	/// DDP suggests this is the right destination when a user changes namespaces on this page
	var url = zenPage.GetNewURL(value, "EnsPortal.FindMsgBank.zen?EDIT=1");
	self.document.location = url;
}

Method isEnterpriseProductionRunning(Output pProductionName As %String) As %Boolean
{
	Set tRunningProduction = $G(^Ens.Runtime("Name"))
	Set tIsEnterpriseProd = 0
	Try {
		Set tIsEnterpriseProd = (tRunningProduction '= "") && $classmethod(tRunningProduction,"%Extends","Ens.Enterprise.Production")
	}
	Catch {
		Set tIsEnterpriseProd = 0
	}
	Set pProductionName = $select(tIsEnterpriseProd: tRunningProduction, 1: "")
	Quit tIsEnterpriseProd
}

Method getRefreshLabelText() As %String [ Internal, ZenMethod ]
{
	Set time=$G(^IRIS.Temp.Ens.EntMonitorStatus($namespace,"time"))
	Quit:""=time " "

	Set tIsRunning = ..isEnterpriseProductionRunning()
	Set formattedTime=##class(Ens.Util.Time).ConvertDateTime($$$timeUTCtoLocal(time),"%Q","%A %b %d, at %#I:%M:%S %p")
	If ..enableAutoRefresh {
		Set tText = $$$FormatText($$$Text("Client systems last polled on %1"),formattedTime)
	} Else {
		Set tText = $$$FormatText($$$Text("Client systems data from poll on %1"),formattedTime)
	}
	If tIsRunning {
		Set formattedRefreshTime=##class(Ens.Util.Time).ConvertDateTime($$$timeLocal,"%Q","%#I:%M:%S %p")
		Set tText = "["_$$$FormatText($$$Text("%1"),formattedRefreshTime)_"] "_tText
	}
	
	Quit tText
}

Method getProductionLabelText() As %String [ Internal, ZenMethod ]
{
	Set tIsRunning = ..isEnterpriseProductionRunning(.tProductionName)
	If (tIsRunning) {
		Quit $$$FormatText($$$Text("Running Production '%1' to collect monitor data from configured client systems in namespace (%2) on machine %3"),tProductionName,$namespace,$ZU(110))
	}
	Quit $$$Text("Not currently collecting monitor data from configured client systems") _ " - <br/>" _ $$$FormatText($$$Text("No Message Bank or Enterprise Production is running in this namespace (%1) on machine %2"),$namespace,$ZU(110))
}

Method getUpdateReasonString(cname As %String) As %String [ Internal, ZenMethod ]
{
	set result = $get(^IRIS.Temp.Ens.EntMonitorStatus($namespace,cname,0,"UpdateReason"))
	quit result
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("systemsButton",$$$Text("Enterprise Systems"),$$$Text("Go to Enterprise Systems"),"zenPage.gotoEnterpriseSystems();")
	Set pCommands(2) = $LB("monitorRolesButton",$$$Text("Enterprise Monitor Roles"),$$$Text("Go to Enterprise Monitor Roles"),"zenPage.gotoEnterpriseMonitorRoles();")
	Set pCommands(3) = $LB("msgViewerButton",$$$Text("Enterprise Message Viewer"),$$$Text("Go to Enterprise Message Viewer"),"zenPage.gotoEnterpriseMsgViewer();")
	Set pCommands(4) = $LB("msgBankViewerButton",$$$Text("Message Bank Viewer"),$$$Text("Go to Message Bank Viewer"),"zenPage.gotoMsgBankViewer();")
	Set pCommands(5) = $LB("msgBankEvtLogButton",$$$Text("Message Bank Event Log"),$$$Text("Go to Message Bank Event Log"),"zenPage.gotoMsgBankEvtLog();")
	Quit $$$OK
}

ClientMethod gotoEnterpriseSystemsNewConnection() [ Language = javascript ]
{
	if (zenPage.canViewSystems) {
		window.location.href = zenLink("Ens.Enterprise.Portal.SystemList.zen?NEWCONNECTION=1");
	}
}

ClientMethod gotoEnterpriseSystems() [ Language = javascript ]
{
	if (zenPage.canViewSystems) {
		window.location.href = zenLink("Ens.Enterprise.Portal.SystemList.zen");
	}
}

ClientMethod gotoEnterpriseMonitorRoles() [ Language = javascript ]
{
	if (zenPage.canViewMonitorRoles) {
		window.location.href = zenLink("Ens.Enterprise.Portal.MonitorRoleList.cls");
	}
}

ClientMethod gotoEnterpriseMsgViewer() [ Language = javascript ]
{
	if (zenPage.canViewSearch) {
		window.location.href = zenLink("Ens.Enterprise.Portal.EnterpriseSearch.zen");
	}
}

ClientMethod gotoMsgBankViewer() [ Language = javascript ]
{
	if (zenPage.canViewMessages) {
		window.location.href = zenLink("Ens.Enterprise.Portal.MsgBankViewer.zen");
	}
}

ClientMethod gotoMsgBankEvtLog() [ Language = javascript ]
{
	if (zenPage.canViewEvents) {
		window.location.href = zenLink("Ens.Enterprise.Portal.MsgBankEventLog.zen");
	}
}

/// show the details table (the submatrices) for the connection indicated by the SystemName,
/// and the update reason (if there is one), displays on top of the details table.
/// also, the connection name is stored in the session, for the update reason to be "dynamic"-
/// for it to automatically appear and disappear (without the user having to click the "details" link)
/// when the update reason is present and then not present anymore 
ClientMethod selectItem(SystemName, updateReason) [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	if (table.selectedIndex < 0)
		return;
	var detailTable =  zenPage.getComponentById('detailsIFrame');
	var detailsArea = zenPage.getComponentById('detailsArea');
	var detailsPanel = zenPage.getComponentById('detailsPanel');
	var cnameparameter = zenPage.getComponentById('cnameParameter');
	var prevTableName = cnameparameter.getProperty("value");
	if (this.detailsHidden || (prevTableName != SystemName)) {
		this.saveDetailTableName(SystemName);
		var detailTableLabel = zenPage.getComponentById('detailTable-label');
		cnameparameter.setProperty("value", SystemName);
		detailTableLabel.setProperty('content', '<h3>' + $$$Text('Details For') + ': '+ zenEscapeHTML(SystemName) + "</h3>");
		zenPage.displayUpdateReasonLabel(updateReason);

		detailsArea.setProperty('hidden', false);

		var paneDimensions = zenPage.setIframeSize();

		var rowData = table.getRenderedRowData(table.selectedIndex);

		if (rowData != null) {
			var iframes = document.getElementsByTagName("iframe");
			iframes[0].src = "";
			iframes[0].setAttribute("name", "detailsHTMLiframe");
			iframes[0].setAttribute("id", "detailsHTMLiframe");

			var reqInfo = new zenProxy();
			reqInfo.url = "";
			reqInfo.cspchd = "";

			var prodMonURL = rowData.WebIPAddress + rowData.HomePath.toLowerCase() + "EnsPortal.ProductionMonitor.cls";

			if (!rowData.SSLConfig) {
				prodMonURL = "http://" + prodMonURL;
				reqInfo.useSSL = 0;
			} else {
				prodMonURL = "https://" + prodMonURL;
				reqInfo.useSSL = 1;
			}

			var urlParams = "$NAMESPACE=" + encodeURIComponent(rowData.Namespace) + "&STUDIO=1&FRAMEWIDTH=" + paneDimensions.width + "&FRAMEHEIGHT=" + paneDimensions.height;
			if (zenPage.roleCategories != "") {
				urlParams += "&CATEGORIES=" + encodeURIComponent(zenPage.roleCategories);
			}
			var tSC = this.getRequestInfo(SystemName, prodMonURL, reqInfo);
			if (reqInfo.cspchd != "") {
				prodMonURL = reqInfo.url;
				var iframes = document.getElementsByTagName("iframe");
				iframes[0].src = "deepsee/dsrwait.gif";
				// Use XMLHttpRequest to establish cookie for this url
				var xmlHttpReq = new XMLHttpRequest({anon:true,headers:{Cookie:""}});
				xmlHttpReq.onreadystatechange = function()
					{
						//if (xmlHttpReq.readyState==4 && xmlHttpReq.status==200)
						//{
							//var iframes = document.getElementsByTagName("iframe");
							//iframes[0].contentDocument.write(xmlHttpReq.responseText);
							//iframes[0].contentDocument.close();
						//}
					}
				xmlHttpReq.open("POST", prodMonURL, true);
				xmlHttpReq.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
				urlParams += "&CSPSHARE=1&CSPCHD=" + encodeURIComponent(reqInfo.cspchd);
				xmlHttpReq.send(urlParams);
			}
			prodMonURL += "?" + urlParams;
			iframes[0].src = prodMonURL;
		} else {
			alert($$$Text("Reloading page due to change in Client system table"));
			location.reload(false)
			return;
		}

		if (this.detailsHidden) {
			this.toggleDetails();
		}

		// Adjust results pane height to account for status section
		this.adjustTableHeight();
	}
}

ClientMethod setIframeSize() [ Language = javascript ]
{
	var paneDimensions = {};
	var detailTable =  zenPage.getComponentById('detailsIFrame');
	var detailIFrame = detailTable.findElement('iframe');
		
    // Set size of iframe
    var dtlsDiv = detailTable.getEnclosingDiv();
    var winWidth = zenGetWindowWidth();
    paneDimensions["width"] = parseInt(this.detailsWidth / 100 * winWidth - 60, 10);
    var labelAreaHeight = detailLabelArea.offsetHeight > 0 ? detailLabelArea.offsetHeight : 123;
    paneDimensions["height"] = Math.ceil(this.getContentAreaHeight() - labelAreaHeight);
    detailTable.setProperty('width', paneDimensions.width);
    detailTable.setProperty('height', paneDimensions.height);
    return paneDimensions;
}

ClientMethod getFramePosition(frame, positionArr) [ Language = javascript ]
{
	var frm = zenPage.getComponentById(frame);
	var frmDiv = frm.getEnclosingDiv();
	positionArr[0] = frmDiv.offsetX;
	positionArr[1] = frmDiv.offsetY;
	positionArr[2] = frmDiv.offsetWidth;
	positionArr[3] = frmDiv.offsetHeight;
}

/// If user hides details pane, unselect the current row
ClientMethod onToggleDetails() [ Language = javascript ]
{
	if (this.detailsHidden) {
		var table = zenPage.getComponentById('table');
		table.selectRow(-1);
		var cnameparameter = zenPage.getComponentById('cnameParameter');
		cnameparameter.setProperty("value", "");
	}
}

/// save the name of the details table, null if there is no details table showing
/// this is for retrieving the update reason, so that it can be dynamically displayed
/// when an update reason becomes available, or dynamically "erased" from the screen
/// when the update reason goes away (b/c the system was updated)
ClassMethod saveDetailTableName(SystemName As %String) [ Internal, ZenMethod ]
{
	set %session.Data("DetailTableName") = SystemName
}

/// Get a session CSPCHD for use in connecting with the client machine
ClassMethod getRequestInfo(SystemName As %String, cachedUrl As %String, proxyObj As %ZEN.proxyObject) As %Status [ Internal, ZenMethod ]
{
	#; Look to see if cached and if so return with potentially modified proxyObj 
	If ..haveCachedRequestInfo(SystemName, cachedUrl, .proxyObj) Return $$$OK

	#dim tCSPCHD
	#dim userCredentials,sslConfig
	#dim tURL
	#dim urlParts, path
	#dim errorMessage, status
	#dim header, head, value
	#dim url

	Set tCSPCHD = ""
	Set tClient = ##class(Ens.Enterprise.MonitorClient).%OpenId(SystemName)
	If $IsObject(tClient) {
		Set userCredentials = tClient.SOAPCredentials
		Set sslConfig = tClient.SSLConfig
		Set url=tClient.WebIPAddress _ tClient.HomePath _ "EnsPortal.ProductionMonitor.cls"
		If sslConfig '= "" {
			Set url = "http://"_url
		} Else {
			Set url = "https://"_url 
		}
		Set tURL = "http://"
		Set tObj = ##class(Ens.Config.Credentials).%OpenId(userCredentials)
		If $IsObject(tObj) {
			// Formulate request to get authentication cookie
			// Note that newer systems should pass 'IRISUsername' etc but keep passing 'CacheUserName' for backward compatiblity when talking to older systems
			Set httpRequest = ##class(%Net.HttpRequest).%New()
			Do httpRequest.InsertFormData("CacheUserName",tObj.Username)
			Do httpRequest.InsertFormData("CachePassword",tObj.Password)
			If sslConfig '= "" {
				Set proxyObj.useSSL = 1
				Set tURL = "https://"
				Set httpRequest.Https = 1
				Set httpRequest.SSLConfiguration = $zconvert(sslConfig,"I","UTF8")
				Set proxyObj.sslConfiguration = httpRequest.SSLConfiguration
			}
			Do ##class(%Net.URLParser).Parse(url,.urlParts)
			Set httpRequest.OpenTimeout = 5
			Set httpRequest.Timeout = 5
			Set httpRequest.Server = $get(urlParts("host"))
			If (+$get(urlParts("port"))) Set httpRequest.Port = urlParts("port")
			Set path = $get(urlParts("path"))
			Set path("query") = ""
			Set path("fragment") = ""
			If (path '= "") && ($extract(path,1) '= "/") Set path = "/" _ path
			If ($get(urlParts("query")) '= "") {
				Set path("query") = urlParts("query")
				If ($extract(path("query"),1) '= "?") Set path("query") = "?" _ path("query")
			}
			If ($get(urlParts("fragment")) '= "") {
				Set path("fragment") = urlParts("fragment")
				If ($extract(path("fragment"),1) '= "#") Set path("fragment") = "#" _ path("fragment")
			}
			Set path = path _ path("query") _ path("fragment")
			Set tURL = tURL _ httpRequest.Server _ $Case(httpRequest.Port,"":"", :":" _ httpRequest.Port) _ path
			Set proxyObj.url = tURL
			Set status = httpRequest.Post(path)
			If $$$ISERR(status) {
				Set errorMessage = $system.Status.GetErrorText(status)
				Quit status
			}
			Else {
				Set header = ""
				#dim tClientcspchd
				#dim tSameClientCookiePath = 0
				For  {
					Set header = httpRequest.HttpResponse.GetNextHeader(header)
					Quit:header=""
					Set head = $zconvert($piece(header,":",1),"U")
					If head = "SET-COOKIE" {
						Set value = httpRequest.HttpResponse.GetHeader(header)
						If $zcvt(value,"U")["CSPSESSIONID" {
							#; Decide if going to set into proxObj later if not same cookie path on same server
							Set tClientcspchd = $Piece($Piece(value,";",1),"=",2)
						}
						If $zcvt(value,"U")["PATH" {
							Set tSameClientCookiePath = ..isSameCookiePathAsRequestor(value,$get(urlParts("host")),(+$get(urlParts("port"))),+httpRequest.Https)
						}
					}
				}
				If $Data(tClientcspchd)#2 && 'tSameClientCookiePath Set proxyObj.cspchd = tClientcspchd
			}
		}

		Do ..cacheRequestInfo(SystemName, cachedUrl, proxyObj)

	}
	Quit $$$OK
}

/// Retrieved cached CSPCHD for use in connecting with the client machine
ClassMethod haveCachedRequestInfo(SystemName As %String, url As %String, proxyObj As %ZEN.proxyObject) As %Boolean [ Internal, Private ]
{
	#dim tHaveCached = 0
	#dim serializedProxy
	Try {
		If $Data(^IRIS.Temp.EnsPortal.Data(%session.SessionId,"EntMon",SystemName,url),serializedProxy)#2 {
			Do proxyObj.%ZENDeserialize(##class(%CSP.Page).Decrypt(serializedProxy))

			If (proxyObj.cspchd="") {
				Set tHaveCached = 1
			} ElseIf (..sessionTokenIsValid(proxyObj)) {
				Set tHaveCached = 1
			} Else {
				Set proxyObj.cspchd=""
				Kill ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"EntMon",SystemName,url)
			}
		}
	} Catch { /* ignore cache if errors such as SUBSCRIPT */}
	Return tHaveCached
}

/// Cache CSPCHD for use in connecting with the client machine
ClassMethod cacheRequestInfo(SystemName As %String, url As %String, proxyObj As %ZEN.proxyObject) [ Internal, Private ]
{
	Try {
		Set ^IRIS.Temp.EnsPortal.Data(%session.SessionId,"EntMon",SystemName,url) = ##class(%CSP.Page).Encrypt(proxyObj.%Serialize())
	} Catch { /* ignore cache if errors such as SUBSCRIPT */}
}

/// Check if Session Token still valid against single production monitor page
ClassMethod sessionTokenIsValid(proxyObj As %ZEN.proxyObject) As %Boolean [ Internal, Private ]
{
	#dim isValid = 0
	Try {
		If proxyObj.url'="" {
			Set httpRequest = ##class(%Net.HttpRequest).%New()
			If proxyObj.sslConfiguration '= "" {
				Set httpRequest.Https = 1
				Set httpRequest.SSLConfiguration = proxyObj.sslConfiguration /* already UTF8 converted inbound */
			}
			#dim urlParts
			Do ##class(%Net.URLParser).Parse(proxyObj.url,.urlParts)
			Set httpRequest.OpenTimeout = 5
			Set httpRequest.Timeout = 5
			Set httpRequest.Server = $get(urlParts("host"))
			If (+$get(urlParts("port"))) Set httpRequest.Port = urlParts("port")
			#dim path = urlParts("path")
			#; CSPSHARE to allow including CSP token in the URL
			Set path = path_"?CSPSHARE=1&CSPCHD="_$ZCVT(proxyObj.cspchd,"O","URL")
			#dim status = httpRequest.Get(path)
			If $$$ISOK(status) {
				If $IsObject(httpRequest.HttpResponse) && (httpRequest.HttpResponse.StatusCode=200) {
					Set isValid = 1
				}
			}
		}
	} Catch { /* ignore cache if errors such as SUBSCRIPT */}
	Return isValid
}

ClassMethod isSameCookiePathAsRequestor(pSetCookie As %String, pClientHost As %String, pClientPort As %Integer, pIsSSL As %Boolean) As %Boolean [ Internal ]
{
	#; Examine if we are monitoring production on same instance and avoid getting cookie again if same cookie path.
	#dim tSameServerandCookiePath = 0
	Try {
		#dim tThisPort = +%request.CgiEnvs("SERVER_PORT")
		#dim tThisServerHost = $Piece(%request.CgiEnvs("HTTP_HOST"),":")
		#dim tThisServerHostPort = $Piece(%request.CgiEnvs("HTTP_HOST"),":",2)
		If tThisServerHostPort'="" Set tThisPort = tThisServerHostPort
		If (pClientPort=tThisPort)||('pClientPort&&(('pIsSSL&&(tThisPort=80))||(pIsSSL&&(tThisPort=443))))||('pClientPort&&'tThisPort) {
			If ($zcvt(pClientHost,"l") = tThisServerHost) {
				#dim tClientCookiePath = $zcvt(pSetCookie,"l")
				Set tClientCookiePath = $Piece(tClientCookiePath,"path",2)
				Set tClientCookiePath = $zstrip($Piece($Piece(tClientCookiePath,";",1),"=",2),"<>W")
				If $zcvt(%session.CookiePath,"l")=tClientCookiePath Set tSameServerandCookiePath = 1
			}
		}
	} Catch  {}
	Quit tSameServerandCookiePath
}

Method getDetailTableName() As %String [ Internal, ZenMethod ]
{
	quit $get(%session.Data("DetailTableName"))
}

/// User override of cell-display for tablePane.
/// pName: name of the column- corresponding to the class query
/// this method makes the cell have no content, as the color cell should be blank and just
/// contain the background color that is assigned to it in a conditional statement,
/// which is based upon which color (red, yellow, green, purple, orange) that is the original
/// content of the color cell
Method setColor(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	#; Draw HTML to render table cell.
	&html<&nbsp;>
	Quit $$$OK
}

/// User override of cell-display for tablePane.
/// pTable: handle to the tablePane component
/// pName: name of the column for this class query
/// pSeed: Seed value for this table
/// Draw a split bar graph showing the proportion of states of hosts in the production
Method drawBarGraph(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	#dim color = $Get(%query("Color"))

	#dim numError = +$P(color,",",1)
	#dim numInactive = +$P(color,",",2)
	#dim numStopped = +$P(color,",",3)
	#dim numDisabled = +$P(color,",",4)
	#dim numOk = +$P(color,",",5)

	#dim numTotal = numError + numInactive + numStopped + numDisabled + numOk


	&html<<div class="bars">>
	If (0 = numTotal) {
		&html<<div class="bar bar-none" style="width:100%" />>
	} else {
		/* Stacked bar graph overlay so calculate width then add to previous running width
			First layer = OK so set at 100%
			Second layer Disabled
			Third layer Stopped
			Fourth layer Inactive
			Fifth layer Error
		*/
		#dim widthOk = 100
		#dim widthError = 0
		#dim widthInactive = 0
		#dim widthStopped = 0
		#dim widthDisabled = 0

		/* make minimum width for Errors, Inactive, Stopped and Disabled = 4% so can be seen */
		#dim barMin = 4 ;%

		If (numError>0) {
			Set widthError = (numError / numTotal * 100)
			If (widthError<barMin) Set widthError = barMin
		}

		If (numInactive>0) {
			Set widthInactive = (numInactive / numTotal * 100)
			If (widthInactive<barMin) Set widthInactive = barMin
		}
		Set widthInactive = widthInactive + widthError

		If (numStopped>0) {
			Set widthStopped = (numStopped / numTotal * 100)
			If (widthStopped < barMin) Set widthStopped = barMin
		}
		Set widthStopped = widthStopped + widthInactive

		If (numDisabled>0) {
			Set widthDisabled = (numDisabled / numTotal * 100)
			If (widthDisabled < barMin) Set widthDisabled = barMin
		}
		Set widthDisabled = widthDisabled + widthStopped
		If widthDisabled > 100 Set widthDisabled = 100

		#dim toolTip = ""
		Set:numError toolTip = "Error: "_numError_"; "
		Set:numInactive toolTip = toolTip_"Inactive: "_numInactive_"; "
		Set:numStopped toolTip = toolTip_"Stopped: "_numStopped_"; "
		Set:numDisabled toolTip = toolTip_"Disabled: "_numDisabled_"; "
		Set:numOk toolTip = toolTip_"Ok: "_numOk_"; "
		Set:numTotal'=numOk toolTip = toolTip_"Total: "_numTotal_";"
		// Note: IE ignores the height if the divs are empty, so insert empty comment.
		&html<<div class="bar bar-ok" style="width:#(widthOk)#px; height: 14px;" title="#(toolTip)#"><!-- --></div>>
		&html<<div class="bar bar-disabled" style="width:#(widthDisabled)#px; height: 14px;" title="#(toolTip)#"><!-- --></div>>
		&html<<div class="bar bar-stopped" style="width:#(widthStopped)#px; height: 14px;" title="#(toolTip)#"><!-- --></div>>
		&html<<div class="bar bar-inactive" style="width:#(widthInactive)#px; height: 14px;" title="#(toolTip)#"><!-- --></div>>
		&html<<div class="bar bar-error" style="width:#(widthError)#px; height: 14px;" title="#(toolTip)#"><!-- --></div>>
	}
	&html<</div>>
	Quit $$$OK
}

/// Draw count of queued messages, highlighting near- and over-threshold value with color
Method drawQueueCount(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Set tQueueCount = +$Get(%query(pName),0)
	Set tQueueThreshold = +$Get(%query("QueueThreshold"),0)
	If (0 = tQueueThreshold) {
		set style="color:black;"
		set title="No Queue Threshold specified"
	} elseif (tQueueCount > tQueueThreshold) {
		set style="color:red;"
		set title="Greater than Queue Threshold"
	} elseif tQueueCount > (tQueueThreshold * 0.85) {
		set style="color:orange;"
		set title="Greater than 85% of Queue Threshold"
	} else {
		set style="color:green;"
		set title="Lower than Queue Threshold"
	}
	&html<<div style="#(style)#" title="#($ZCVT(title,"O","HTML"))#">#($ZCVT(tQueueCount,"O","HTML"))#</div>>
	Quit $$$OK
}

/// Draw "+" button to add new enterprise connections
Method drawNewClientButton(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	set NewConnectionLink = ..Link("Ens.Enterprise.Portal.SystemList.zen?NEWCONNECTION=1")
	&html<<a href="#(NewConnectionLink)#"><img border="0" src="deepsee/ds_plus_16.gif" valign="bottom" alt="Create new connection"></img></a>>
	Quit $$$OK
}

/// User override of cell-display for tablePane.
/// pName: name of the column- corresponding to the class query
/// adds a link to the instance name, to the server's management portal
Method makeSysPortalLink(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	#; Draw HTML to render table cell
	set instance = ..EscapeHTML(%query(pName))
	Set ipAddr = %query("WebIPAddress")
	Set Namesp = %query("Namespace")
	
	Set tPath = %query("HomePath")
	Set tPage = %query("HomePage")
	Set tVersion = %query("Version")
	Set tClient = %query("ClientName")
	//only want to have a link if the link is going to a "real" place, at least as far as the code can easily tell
	if (instance="") || ("not enabled"=$E(instance,1,$L("not enabled"))) || (ipAddr="") {
		&html<#(instance)#>  	
	} else {
		Set tClientObj=##class(Ens.Enterprise.MonitorClient).%OpenId(tClient)
		If $IsObject(tClientObj) {
			Set tLink = tClientObj.GetURLPath()_$select(tVersion<2011: "UtilEnsHome.csp", 1: ##class(%Library.EnsembleMgr).#PORTALHOMEPAGE)
		} Else {
			Set tLink = "http://"_ipAddr_$select((tPath '= "") && (tPage '= ""): tPath_tPage, 1: "/csp/"_$zcvt(Namesp,"l")_"/"_$select(tVersion<2011: "UtilEnsHome.csp", 1: ##class(%Library.EnsembleMgr).#PORTALHOMEPAGE))
		}
		&html<<a href="#(..EscapeHTML(tLink))#" target="_blank">#(instance)#</a>>
	}
	Quit $$$OK
}

Method makeEnsPortalLink(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	#; Draw HTML to render table cell
	Set production = %query("ProductionName")
	Set ipAddr = %query("WebIPAddress")
	Set Namesp = %query("Namespace")

	Set tPath = %query("HomePath")
	Set tPage = %query("HomePage")
	Set tVersion = %query("Version")
	Set tClient = %query("ClientName")
	//only want to have a link if the link is going to a "real" place, at least as far as the code can easily tell
	if (production="") || (ipAddr="") {
		&html<&nbsp;>
	} else {
		Set tClientObj=##class(Ens.Enterprise.MonitorClient).%OpenId(tClient)
		If $IsObject(tClientObj) {
			Set tLink = tClientObj.GetURLPath()_$select(tVersion<2011: "CSPX.EnsConfigFrame.cls?$ID1=", 1: "EnsPortal.ProductionConfig.zen?PRODUCTION=")_$$$URLENCODE(production)
		} Else {
			Set tLink = "http://"_ipAddr_$select((tPath '= ""): tPath, 1: "/csp/"_$zcvt(Namesp,"l")_"/")_$select(tVersion<2011: "CSPX.EnsConfigFrame.cls?$ID1=", 1: "EnsPortal.ProductionConfig.zen?PRODUCTION=")_$$$URLENCODE(production)
		}
		&html<<a href="#(..EscapeHTML(tLink))#" target="_blank">#(..EscapeHTML(production))#</a>>
	}
	Quit $$$OK
}

/// User override of cell-display for a the main table- for the details table.
/// this constructs the link for showing the details table, and it is *only*
/// shown if there are details to show- which is determined by if there is 
/// an entry in the "details" column for the query, which should equal the name of the connection
/// for which the details are getting fetched
Method doCustomCell(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	#; Draw HTML to render table cell.
	set updateReason = $zcvt(%query("UpdateReason"),"O", "JS")
	set cname = %query(pName)
	if (cname '= "") {
		&html<<a href="javascript:zenPage.selectItem('#(cname)#','#(updateReason)#');">details</a>>
	} else {
		&html<&nbsp;>
	}
	Quit $$$OK
}

Method %OnGetTitle() As %String
{
	Quit $$$Text("Enterprise Monitor")
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Enterprise Monitor")
}

ClassMethod GetLocator(pTitlePane As %CSP.Util.TitlePane, ByRef pAddress As %String, ByRef pBaseURL As %String = "") As %String
{
	Set tName = $$$Text("Enterprise Status Monitor")
	Set tURL = "/csp/"_$namespace_"/"_$$$CurrentClass_".cls"
	Set pAddress = ..#PAGENAME

	Set tLink = ##class(%CSP.Util.Link).%New()
	Set tLink.Caption = tName
	Set tLink.HREF = tURL
	Do pTitlePane.Locator.Insert(tLink)
	Quit tName
}

}
