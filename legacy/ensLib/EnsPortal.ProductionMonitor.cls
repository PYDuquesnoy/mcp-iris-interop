/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// This page displays monitoring information for the current running production.
/// 
Class EnsPortal.ProductionMonitor Extends EnsPortal.Template.viewerPage [ System = 4 ]
{

/// User needs USE permissions on the %Ens_Dashboard resource to access this page.
Parameter RESOURCE = "%Ens_Dashboard:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Production Monitor";

/// display text
Property msgGoToMessageViewer As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Go To Message Viewer")} ];

/// Indicate whether toggle button for search pane should be displayed.
Parameter SHOWSEARCHTOGGLE As BOOLEAN = 0;

/// URL parameter specifying list of visible categories
Property allowedCategories As %String(ZENURL = "CATEGORIES");

/// Current selected Category.
Property currCategory As %String;

/// Number of items not shown due to category filtering
Property filteredItemCount As %Integer [ InitialExpression = 0 ];

Property filteredErrCount As %Integer [ InitialExpression = 0 ];

/// Sorting mode: name or id
Property sortMode As %String [ InitialExpression = "Id" ];

/// Dimensions of frame in which this page is displayed (if any)
Property frameWidth As %ZEN.Datatype.integer(ZENURL = "FRAMEWIDTH") [ InitialExpression = 0 ];

Property frameHeight As %ZEN.Datatype.integer(ZENURL = "FRAMEHEIGHT") [ InitialExpression = 0 ];

Property isEmbedded As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Time of last update
Property lastUpdate As %ZEN.Datatype.string [ InitialExpression = {$$$timeLocal} ];

/// Indicates whether auto-update is enabled.
Property autoUpdate As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Used to pass size information to the server.
Property monitorHeight As %ZEN.Datatype.integer;

/// Used to pass size information to the server.
Property monitorWidth As %ZEN.Datatype.integer;

/// ID of Production to display.
Property productionId As %String [ InitialExpression = {..GetCurrentProduction()} ];

/// Width of details pane
Property detailsWidth As %ZEN.Datatype.integer(MAXVAL = 80, MINVAL = 5) [ InitialExpression = 60 ];

Property canViewSearch As %Boolean [ InitialExpression = 0 ];

Property canViewEvents As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(EnsPortal.EventLog).#RESOURCE)} ];

Property canViewSuspended As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(EnsPortal.SuspendedMsg).#RESOURCE)} ];

Property canViewQueues As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(EnsPortal.Queues).#RESOURCE)} ];

Property canViewProduction As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(##class(EnsPortal.ProductionConfig).#RESOURCE)} ];

Property canUpdateProduction As %Boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList("%Ens_ProductionRun:USE,%Ens_ConfigItemRun:USE")} ];

Property canQueryMessages As %Boolean [ InitialExpression = 1 ];

Property canQueryEvents As %Boolean [ InitialExpression = 1 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#lastUpdate {
	font-weight: bold;
}

#monitor {
}

#details {
	background: #E0E0D0;
	border-right: 1px solid gray;
	color: black;
	font-size: 0.7em;
	padding: 5px;
	margin-top: 0px;
	margin-bottom: 10px;
	overflow: auto;
}

#details td {
	font-size: 0.8em;
	vertical-align: middle;
}

.MonitorWrapper {
	border: 1px solid lightgray;
}

.MonitorSummary {
	background: white;
	padding-left: 2px;
	border-left: 1px solid black;
	border-right: 1px solid black;
}

.MonitorSummary table {
	color: navy;
	font-size: 0.7em;
}

.MonitorCaption {
	color: #404040;
	background: gray;
	background-image: url(images/grad-halfgray-10x30.png);
	background-repeat: repeat-x;
	border: 1px solid black;
	font-size: 0.8em;
	font-variant: small-caps;
	font-weight: bold;
	padding: 2px;
	text-align: left;
}

.MonitorScrollBox {
	overflow-y: auto;
	background: white;
}

.MonitorTable {
	background: white;
	border: 1px solid black;
	font-size: 0.8em;
	width: 100%;
	padding-right: 2em;
}

.MonitorTable td {
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
}

.MonitorTable td.Item {
	cursor: pointer;
}

/* item mouse is over */
.ItemHover {
	background: yellow;
}

/* item selected */
.ItemSelected {
	background: teal;
}

.DetailLabel {
	font-weight: bold;
	color: #404040;
	padding-top: 4px;
}

.DetailValue {
	padding-left: 10px;
}

.SummaryLabel {
	font-weight: bold;
}

.Lamp {
	text-align: center;
	color: darkblue;
	width: 20px;
	min-width: 20px;
	font-weight: bold;
}

A.LastUpdate {
	color: #3B84BC;
	text-decoration: none;
}

A.LastUpdate:hover {
	color: darkred;
}

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
<pane xmlns="http://www.intersystems.com/zen" xmlns:EnsPortal="http://www.intersystems.com/EnsPortal" title="">
<timer id="timer" ontimeout="zenPage.updateMonitor(zenThis);" timeout="11000"/>
<vgroup>
<html id="diagramHeader" OnDrawContent="DrawDiagramHeader"/>
<hgroup width="100%" cellVAlign="top">

<!-- This HTML block shows the status tables. -->
<!-- <html id="monitor" width="80%" OnDrawContent="DrawMonitorInfo"/> -->
<html id="monitor" width="auto" OnDrawContent="DrawMonitorInfo"/>
<spacer width="20"/>
</hgroup>
</vgroup>
</pane>
}

XData detailsPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:EnsPortal="http://www.intersystems.com/EnsPortal" title="">
<!-- This HTML block shows the details for the selected item. -->
<vgroup width="30%">
<EnsPortal:activityGraph id="activityGraph" height="50%" />
<timer id="detailsTimer" ontimeout="zenPage.updateDetails(zenThis);" timeout="11000" />
<html id="details" OnDrawContent="DrawDetails"/>
<tablePane id="tblItemDetails" hidden="true"
	rowSelect="false"
    cellSpacing="2" 
	maxRows="10"
	pageSize="10"
	showZebra="true"
	initialExecute="false"
	showValueInTooltip="true"
	dataSource="columns"
	sql="SELECT TOP 10 ID, TimeLogged, ConfigName, Text
	FROM Ens_Util.Log
	WHERE ConfigName=? AND ( (Text %STARTSWITH ?)
	OR (Type = 'Error') )
	ORDER BY ID DESC"
	>
<parameter id="configItemName" name="itemName" value="" />
<parameter id="errorText" value="ERROR" />
<column colName="ID" hidden="true" />
<column colName="ConfigName" hidden="true" />
<column colName="TimeLogged" header="Time Since" OnDrawCell="ShowElapsedTime" />
<column colName="Text" header="Recent Errors" OnDrawCell="TruncateMessageText" />
</tablePane>
<hgroup>
<spacer width="10em" />
<html id="divMessages">
<a class="ribbonSortOption" align="right" style="font-size:10pt" title="View these messages in the Message Viewer page" href="#" onClick="zenPage.gotoMessageViewer();return false;" target="_blank">#(%page.msgGoToMessageViewer)#</a>
<span>  </span><a class="dgmHeaderCmd" title="View all messages in the Message Viewer page" href="#" onClick="window.open(zenLink('EnsPortal.MessageViewer.zen'),'messages');return false;"><img src="images/bullet-ul-excdev.gif"/></a>
</html>
</hgroup>
<tablePane id="tblMessagesProduction" hidden="false"
	rowSelect="false"
    cellSpacing="2" 
	maxRows="100"
	pageSize="100"
	showZebra="true"
	initialExecute="false"
	sql="SELECT TOP 100 ID, SessionId, TimeCreated, Status, SourceConfigName, TargetConfigName
	FROM Ens.MessageHeader
	WHERE ID=SessionId
	ORDER BY SessionId DESC"
	>
<column colName="ID" hidden="true" />
<column colName="SessionId" header="Session" />
<column colName="TimeCreated" header="Date/Time" OnDrawCell="FormatDateTime" />
<column colName="Status" header="Status" />
<column colName="SourceConfigName" header="Source" />
<column colName="TargetConfigName" header="Target" />
</tablePane>
<tablePane id="tblMessagesItem" hidden="true"
	rowSelect="false"
    cellSpacing="2" 
	maxRows="100"
	pageSize="100"
	showZebra="true"
	initialExecute="false"
	sql="SELECT TOP 100 ID, TimeCreated, Status, SourceConfigName, TargetConfigName, MessageBodyClassName, MessageBodyId
    FROM Ens.MessageHeader
    WHERE ID IN (
            SELECT TOP 100 ID
            FROM Ens.MessageHeader
            WHERE SourceConfigName = ?
            ORDER BY ID DESC
        UNION
            SELECT TOP 100 ID
            FROM Ens.MessageHeader
            WHERE TargetConfigName = ?
            ORDER BY ID DESC
    )
    ORDER BY ID DESC">
<parameter id="msgTableSource" name="SourceHost" value="" />
<parameter id="msgTableTarget" name="TargetHost" value="" />
<column colName="ID" header="Header" />
<column colName="TimeCreated" header="Date/Time" OnDrawCell="FormatDateTime" />
<column colName="Status" header="Status" />
<column colName="SourceConfigName" header="Source" />
<column colName="TargetConfigName" header="Target" />
<column colName="MessageBodyClassName" header="Body" />
<column colName="MessageBodyId" header="ID" />
</tablePane>

</vgroup>
</pane>
}

Method GetElapsedTime(pOldTime As %String, Output pElapsedTime As %String) As %Status
{
	Set thenTime = $ZDATETIMEH(pOldTime,3,1)
	Set thenDay = $P(thenTime, ",", 1)
	Set thenSec = $P(thenTime, ",", 2)
	Set thenMoment = (thenDay * 86400) + thenSec
	Set nowTime = $ZTIMESTAMP
	Set nowDay = $P(nowTime, ",", 1)
	Set nowSec = $P(nowTime, ",", 2)
	Set nowMoment = (nowDay * 86400) + nowSec
	Set elapsedMoment = nowMoment - thenMoment
	Set elapsedDay = elapsedMoment \ 86400
	Set elapsedSec = elapsedMoment # 86400
	If elapsedDay > 0 {
		if elapsedDay > 1 {
			Set pElapsedTime = elapsedDay_" days, "_$ZTIME(elapsedSec)
		} else {
			Set pElapsedTime =  elapsedDay_" day, "_$ZTIME(elapsedSec)
		}
	} else {
		Set pElapsedTime =  $ZTIME(elapsedSec)
	}
	Quit $$$OK
}

Method getTimeSinceLastActivity(pItemName As %String) As %String [ ZenMethod ]
{
	Set tSC = ..GetElapsedTime($G(^IRIS.Temp.EnsHostMonitor($namespace,pItemName,"%LastActivity"),$ZTIMESTAMP),.tLastAct)
	Quit tLastAct
}

Method ShowElapsedTime(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Try {
		Set tTimeLoggedUTC=##class(Ens.Util.Log).%OpenId(%query("ID")).TimeLogged
	} Catch {Set tTimeLoggedUTC=%query(pName)}
	Set tSC = ..GetElapsedTime(tTimeLoggedUTC, .tElapsedTime)
	Write tElapsedTime
	Quit $$$OK
}

Method TruncateMessageText(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Set tTruncate=$L($$$Text("ERROR"))
	If $EXTRACT(%query(pName),1,tTruncate)=$$$Text("ERROR") {
		Set tTruncate=tTruncate+1
	} ElseIf $EXTRACT(%query(pName),1,5)="ERROR" {
		Set tTruncate=6
	} Else { Set tTruncate=1}
	If $E(%query(pName),tTruncate,(tTruncate+5))=" <Ens>" Set tTruncate=tTruncate+6
	Write $ZCVT($EXTRACT(%query(pName),tTruncate,64),"O","HTML")
	Quit $$$OK
}

Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()
	Quit $$$OK
}

/// Choose which Production to start with.
ClassMethod GetCurrentProduction() As %String
{
	If $D(%page),$IsObject(%page),%page.productionId'="" { Set tProd = %page.productionId }
	ElseIf $G(%request.Data("PRODUCTION",1))'="" { Set tProd =  %request.Data("PRODUCTION",1) }
	Else  { Set tProd = ##class(EnsPortal.Utils).GetCurrentProductionName() }
	Set:tProd="" tProd = $G(^EnsPortal.Settings($Username,"LastProduction"))

	// Must be a valid production name
	If '$ZNAME(tProd,1) || '##class(Ens.Config.Production).%ExistsId(tProd) { Set tProd = "" }

	Quit tProd
}

/// Draw top portion of results pane.
Method DrawDiagramHeader(pSeed As %String) As %Status
{
	Set tProd = %page.productionId
	// Category selection
	Set c = %page.currCategory
	Set msgAll = $$$TextHTML("All")
	&html<<table><tr>>
	&html<<td nowrap width="15%" class="dgmAction" style="cursor:default" title='#($ZCVT($$$Text("Select a category to filter items shown on the diagram"),"O","HTML"))#'>
		#($$$TextHTML("Category:"))#
		<select id="id_Category" onchange="zenPage.selectCategory(this.value);" class="dgmSelect">>
		Write "<option " Write:c="" "selected=""true""" Write "value="""" title=""",msgAll,""">",msgAll,"</option>"
		If ..allowedCategories '= "" {
			Set tSelectedCat = $P(..allowedCategories,",",1)
			Write "<option " Write:c="" "selected=""true""" Write "value="""" title=""",tSelectedCat,""">",tSelectedCat,"</option>"
			Set catIndex = 2
			For {
				Set cat = $P(..allowedCategories,",",catIndex)
				Quit:cat=""
				Set catIndex = catIndex + 1
				Write "<option " Write:c=cat "selected=""true""" Write "value=""",cat,""" title=""",cat,""">",cat,"</option>"
			}
		} else {
			Try {
				Set tRS = ##class(%ResultSet).%New("Ens.Config.Production:EnumerateCategories")
				Set tSC = tRS.Prepare()
				If $$$ISOK(tSC) {
					Set tSC = tRS.Execute(tProd)
					If $$$ISOK(tSC) {
						While (tRS.Next()) {
							Set cat = $ZCVT(tRS.Get("Category"),"O","HTML")
							Write "<option " Write:c=cat "selected=""true""" Write "value=""",cat,""" title=""",cat,""">",cat,"</option>"
						}
					}
				}
			}
			Catch {
			}
		}
	&html<<td>#($$$TextHTML("Sort by: "))#<select id="id_SortMode" onchange="zenPage.setSortMode(this.value);"><option value="Name">Name</option><option value="Id" selected="true">Number</option></select></td>>
	&html<</select></td>>
	&html<<td><div id="filteredItems"></div></td>>
	&html<</tr></table>>
	&html<</div>>

	Quit $$$OK
}

/// Get the frameWidth, frameHeight allowedCategoriesURL parameters, if specified
Method %OnAfterCreatePage() As %Status
{
	Set ..frameWidth = +$G(%request.Data("FRAMEWIDTH",1))
	Set ..frameHeight = +$G(%request.Data("FRAMEHEIGHT",1))
	If ((..frameWidth > 1) && (..frameHeight > 1)) {
		Set ..isEmbedded = 1
	}
	Set urlo = $G(%request.Data("CATEGORIES",1),"")
	Set urli = $ZCONVERT(urlo,"I","URL")
	Set utfi = $ZCONVERT(urli,"I","UTF8")
	Set ..allowedCategories = utfi
		
	/* Hide if do not have SQL privileges */
	Try {
		Kill SQLCODE
		&sql(%CHECKPRIV SELECT(ID) ON Ens.MessageHeader)
		If SQLCODE'=0 {
			Set ..%GetComponentById("tblMessagesProduction").hidden = 1
			Set ..%GetComponentById("divMessages").hidden = 1
			Set ..canQueryMessages = 0
		} Else {
			Set ..canQueryMessages = 1
		}
		Kill SQLCODE
		&sql(%CHECKPRIV SELECT(ID) ON Ens_Util.Log)
		If SQLCODE'=0 {
			Set ..%GetComponentById("tblItemDetails").hidden = 1
			Set ..canQueryEvents = 0
		} Else {
			Set ..canQueryEvents = 1
		}
	} Catch {}	
	Quit ##super()
}

/// Update the monitor pane.
ClientMethod updateMonitor(timer) [ Language = javascript ]
{
	if (timer && !this.enableAutoRefresh) {
		return;
	}
	var html = zenPage.getComponentById('monitor');
	html.refreshContents(true);
	zenPage.setLastUpdate();

	if (timer && this.autoUpdate) {
		timer.startTimer();
	}
}

ClientMethod gotoMessageViewer() [ Language = javascript ]
{
	var parms = '';
	var details = zenPage.getComponentById('details');
	var seed = details.getProperty('seed');
	if ("" != seed) {
		var seedParts = seed.split("~");
		parms = '?SOURCEORTARGET=' + seedParts[2];
	}
	window.open(zenLink('EnsPortal.MessageViewer.zen' + parms, "_blank"));
}

/// Update the details pane.
ClientMethod updateDetails(timer) [ Language = javascript ]
{
	if (timer && !zenPage.enableAutoRefresh) {
		return;
	}
	var details = zenPage.getComponentById('details');
	var itemSeed = details.getProperty('seed');	
	if (itemSeed != "") {
		var seedParts = itemSeed.split("~")
		var counter = document.getElementById('retryCount');
		if (counter) {
			// Seed is of the form cat~id~name
			var count = this.getItemRetryCount(seedParts[1]);
			counter.innerHTML = count;
		}
		
		var elapsedTime = document.getElementById('lastMsgTime');
		if (elapsedTime) {
			var timeSinceLastAct = zenPage.getTimeSinceLastActivity(seedParts[1]);
			elapsedTime.innerHTML = timeSinceLastAct;
		}
		
		if (zenPage.canQueryEvents) {
			var tbl = zen('tblItemDetails');
			if (tbl) {
				var selectedItem = zenPage.getComponentById('configItemName');
				selectedItem.value=seedParts[1];
				tbl.executeQuery();
			}
		}
		this.updateMessages(seedParts[1]);
	} else {
		this.updateMessages("");
	}
	if (timer && this.autoUpdate) {
		timer.startTimer();
	}
}

/// Update the messages table for the given host item.<br/>
ClientMethod updateMessages(hostName) [ Language = javascript ]
{
	try {
		if ("" == hostName) {
			zen('tblMessagesItem').setHidden(true);
			if (zenPage.canQueryMessages) {
				zen('tblMessagesProduction').setHidden(false);
			}
			else {
				zen('tblMessagesProduction').setHidden(true);
			}
			var msgs = zen('tblMessagesProduction');
		}
		else {
			zen('tblMessagesProduction').setHidden(true);
			if (zenPage.canQueryMessages) {
				zen('tblMessagesItem').setHidden(false);
			}
			else {
				zen('tblMessagesItem').setHidden(true);
			}
			var msgs = zen('tblMessagesItem');
			zen('msgTableSource').value = hostName;
			zen('msgTableTarget').value = hostName;
		}
		if (zenPage.canQueryMessages) {
			msgs.msgNoResult = $$$Text('No results','%ZEN');
			msgs.executeQuery();
		}
		else {
			msgs.msgNoResult = $$$Text('Not privileged','%ZEN');
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in updateMessages');
	}
}

/// Method to get the Date or Time piece from the TimeCreated field.
Method FormatDateTime(table As %ZEN.Component.tablePane, dt As %ZEN.Datatype.string, seed As %ZEN.Datatype.string) As %Status
{
 	Set val = %query(dt)
 	Set today = $ZD(+$H,3)
 	If $P(val," ",1)=today {
	 	Write ..EscapeHTML($P($P(val," ",2),".",1))
 	}
 	Else {
	 	Write ..EscapeHTML($P(val," ",1))
 	}
	Quit $$$OK
}

/// Update retryCount, recent error messages, etc.
Method getItemRetryCount(itemName As %String) As %Integer [ ZenMethod ]
{
	Set tRetrying = 0
	Set tJob="" For { Set tJob = $O(^IRIS.Temp.EnsJobMonitor($namespace,tJob)) Quit:tJob=""
		Set retCount = $G(^IRIS.Temp.EnsJobMonitor($namespace,tJob,itemName,"%Retry"),0) 
		If retCount {
			Set tRetrying = tRetrying + retCount
		}
	}
	Quit tRetrying
}

/// This client event is fired when the page is resized.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	this.adjustSizes();
}

/// This client event is fired when the page is resized.
ClientMethod onresizeHandler(load) [ Language = javascript ]
{
	this.adjustSizes();
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var sidebar = zen('details');
		var divSidebar = sidebar.getEnclosingDiv();
		
		// Check for embedding
		var frameWidth = zenPage.getProperty('frameWidth');
		if (frameWidth < 1) {
			frameWidth = zenGetWindowWidth();
			zenPage.setProperty('frameWidth',frameWidth);
		}
		var frameHeight = zenPage.getProperty('frameHeight');
		if (frameHeight < 1) {
			frameHeight = zenGetWindowHeight();
			zenPage.setProperty('frameHeight',frameHeight);
		}
		
		if ((frameWidth > 0) && (frameHeight > 0)) {
			var winWidth = frameWidth;
			var winHeight = frameHeight;
		} else {
			var winHeight = zenGetWindowHeight();
			var winWidth = zenGetWindowWidth();
		}
		var height = winHeight - this.getTitleAreaHeight();
		zenPage.monitorHeight = height;
		zenPage.monitorWidth = winWidth * 0.7;
		divSidebar.style.height = height - (13*zenIsGecko);
		zen('monitor').refreshContents();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Set the last update field.
/// <var>time</var> is the last update time to display.
ClientMethod setLastUpdate(time) [ Language = javascript ]
{
	if (time) {
		zenPage.lastUpdate = time;
	}
	else {
		time = zenPage.lastUpdate;
	}

	var lu = self.document.getElementById('lastUpdate');
	if (lu){
		lu.innerHTML = time;
	}
}

/// Set autoUpdate mode.
ClientMethod setAutoUpdate(flag) [ Language = javascript ]
{
	flag = (zenPage.enableAutoRefresh && flag);
	zenPage.autoUpdate = flag;
	var graph = zenPage.getComponentById('activityGraph');
	graph.autoUpdate = flag;
	var timer = zenPage.getComponentById('timer');
	var detailsTimer = zenPage.getComponentById('detailsTimer');
	if (flag) {
		zenPage.updateMonitor(timer);
		zenPage.updateDetails(detailsTimer);
		graph.changeTimeFrame();
	}
	else {
		timer.clearTimer();
		detailsTimer.clearTimer();
		graph.getChildById('graphTimer').clearTimer();
	}
}

ClientMethod doUpdateAll() [ Language = javascript ]
{
	zenPage.updateMonitor();
	zenPage.updateDetails();
	var graph = zenPage.getComponentById('activityGraph');
	graph.changeTimeFrame();
}

/// An item has been selected, show details for it.
ClientMethod selectItem(cat, id, name) [ Language = javascript ]
{
	var details = zenPage.getComponentById('details');
	var monitor = zenPage.getComponentById('monitor');
	var oldSeed = details.getProperty('seed');
	var newSeed = cat+"~"+id+"~"+name;
	var graph = zenPage.getComponentById('activityGraph');

	// Previous selection is either toggled or replaced
	var prevSelection = document.getElementById(oldSeed);
	if (prevSelection) {
		prevSelection.className = prevSelection.className.replace(/(?:^|\s)ItemSelected(?!\S)/g , '');
	}

	var errMsgTbl = zenPage.getComponentById('tblItemDetails')
	if (oldSeed == newSeed) // Already selected, so toggle
	{
		details.setProperty('seed',"");
		monitor.setProperty('seed',"");
		graph.setProperty('hidden',false); // Show activity graph
		graph.setConfigName("");
		errMsgTbl.setProperty('hidden', true);
		this.updateMessages("");
	}
	else
	{
		details.setProperty('seed', newSeed);
		monitor.setProperty('seed', newSeed);
		document.getElementById(newSeed).className += " ItemSelected"
	
		// Don't try to show activity graph for queues
		if ((cat == "BusinessService") || (cat == "BusinessOperation"))
		{
			graph.setProperty('hidden', false);
			graph.setConfigName(name);

			if (errMsgTbl) {
				if (zenPage.canQueryEvents) {
					errMsgTbl.setProperty('hidden', false);
					var selectedItem = zenPage.getComponentById('configItemName');
					selectedItem.value=id;
					errMsgTbl.executeQuery();
				}
				else {
					errMsgTbl.setProperty('hidden', true);
				}
			}
		} else {
			graph.setProperty('hidden', true);
			graph.setConfigName("n/a"); // Don't show any graph
			
			if (errMsgTbl) {
				errMsgTbl.setProperty('hidden', true);
			}
		}
		this.updateMessages(id);
	}
}

/// User selected a category for the diagram.
ClientMethod selectCategory(cat) [ Language = javascript ]
{
	zenPage.currCategory = cat;
	var html = zenPage.getComponentById('monitor');
	html.refreshContents(true);
	zenPage.updateFilteredCount(zenPage.filteredItemCount, zenPage.filteredErrCount);
}

ClientMethod setSortMode(mode) [ Language = javascript ]
{
	zenPage.sortMode = mode;
	var html = zenPage.getComponentById('monitor');
	html.refreshContents(true);
}

ClientMethod updateFilteredCount(ctr, errCtr) [ Language = javascript ]
{
	var dispCtr = document.getElementById('filteredItems');
	if (ctr == 0) {
		dispCtr.innerHTML = "&nbsp;";
	} else {
		dispCtr.innerHTML = ctr + " items (" + errCtr + " errors) not in this category";
	}
}

ClassMethod CallEnabler(tItem As %String, tSetting As %Boolean) [ ZenMethod ]
{
	Set tSC = ##class(Ens.Director).EnableConfigItem(tItem, tSetting, 1)
	Quit tSC
}

ClientMethod enableItem(tProduction, tItem) [ Language = javascript ]
{
	this.CallEnabler(tProduction + "||" + tItem, 1);
	var enButton = document.getElementById('enableButton');
	if (enButton) {
		enButton.style = "color: gray;";
	}
	var disButton = document.getElementById('disableButton');
	if (disButton) {
		disButton.style = "color: black;";
	}
	var html = zenPage.getComponentById('monitor');
	html.refreshContents(true);
}

ClientMethod disableItem(tProduction, tItem) [ Language = javascript ]
{
	this.CallEnabler(tProduction + "||" + tItem, 0);
	var enButton = document.getElementById('enableButton');
	if (enButton) {
		enButton.style = "color: black;";
	}
	var disButton = document.getElementById('disableButton');
	if (disButton) {
		disButton.style = "color: gray;";
	}
	var html = zenPage.getComponentById('monitor');
	html.refreshContents(true);
}

/// Draw contents of details region.
/// <var>pSeed</var> contains 
/// category~id~name (~ is a delimiter) for the selected item.
Method DrawDetails(seed As %ZEN.Datatype.string) As %Status
{
	Set tCategory = $P(seed,"~",1)
	Set tID = $P(seed,"~",2)
	Set tSeedID = tID
	Set tName = $P(seed,"~",3)
	Set tSeedName = tName

	Set tLink = ""

	Set tUpdateMsg = $$$TextHTML("Last update: ")
	Set tUpdateHelp = $$$TextHTML("Click here to update")
	
	&html<<div><a title="#(tUpdateHelp)#" class="LastUpdate" style='cursor:pointer;' onclick="zenPage.doUpdateAll();">#(tUpdateMsg)#
		<b><span id="lastUpdate">#(..lastUpdate)#</span></b>
		</a></div>>

	If ..enableAutoRefresh {
		&html<<table><tr><td style="text-size:0.8em;"><input type="checkbox" onclick="zenPage.setAutoUpdate(this.checked);" #($S(..autoUpdate:"checked",1:""))#/>#($$$Text("Auto update"))#</td></tr></table>>
	}
	&html<<hr/>>
	#; ##class(EnsPortal.Utils).resolveProductionStateName() ##class(EnsPortal.Utils).getProductionStateColor()
	Set tProd = $G($$$EnsRuntime("Name"))
	If (tProd'="") {
		&html<<div>#($$$Text("Current production:"))#<br/><b>#($ZCVT(tProd,"O","HTML"))#</b></div>>
	} Else {
		&html<<div>#($$$Text("No production running"))#</div>>
	}

	&html<<hr/>>

	#; construct array of details, and links
	#; tDetails(n) = $LB(caption,value)
	#; tLinks(n) = $LB(caption,url)
	Set n = 0

	If (tCategory = "BusinessService") {
		Set tCat = $$$Text("Business Service")
		Set tDetails($INCREMENT(n)) = $LB(tCat,tName)

		If (tID '= "") {
			If ..canViewEvents Set tLinks($INCREMENT(n)) = $LB($$$Text("Event Log"), ..Link("EnsPortal.EventLog.zen?SOURCE="_$$$URLENCODE(tID)))
			If ..canViewQueues Set tLinks($INCREMENT(n)) = $LB($$$Text("Queue Contents"), ..Link("EnsPortal.Queues.cls?QUEUE="_$$$URLENCODE(tID)))
		}
	} ElseIf (tCategory = "BusinessOperation") {
		Set tCat = $$$Text("Business Operation")
		Set tDetails($INCREMENT(n)) = $LB(tCat,tName)

		If (tID '= "") {
			If ..canViewEvents Set tLinks($INCREMENT(n)) = $LB($$$Text("Event Log"), ..Link("EnsPortal.EventLog.zen?SOURCE="_$$$URLENCODE(tID)))
			If ..canViewQueues Set tLinks($INCREMENT(n)) = $LB($$$Text("Queue Contents"), ..Link("EnsPortal.Queues.cls?QUEUE="_$$$URLENCODE(tID)))
		}
	} ElseIf (tCategory = "Queue") {
		If (tName=$$$Text("**Suspended Messages**")) {
			Set tCat = $$$Text("Suspended Messages")
			Set tDetails($INCREMENT(n)) = $LB(tCat,"")
			If ..canViewSuspended Set tLinks($INCREMENT(n)) = $LB($$$Text("Suspended Messages"), ..Link("EnsPortal.SuspendedMsg.zen"))
		} Else {
			Set tCat = $$$Text("Queue")
			Set tDetails($INCREMENT(n)) = $LB(tCat,tName)
			If ..canViewQueues Set tLinks($INCREMENT(n)) = $LB($$$Text("Queue Contents"), ..Link("EnsPortal.Queues.cls?QUEUE="_$$$URLENCODE(tID)))
		}
	} ElseIf ((tCategory = "EventLog") && ..canQueryEvents) {
		#; get more details
		&sql(SELECT %EXTERNAL(TimeLogged),ConfigName ,Text, SourceMethod,Type
			INTO :tTimeLogged,:tHost,:tText,:tMethod,:tType
			FROM Ens_Util.Log WHERE ID = :tID)

		Set tCat = $Case(tType,2:$$$Text("Error"),3:$$$Text("Warning"),6:$$$Text("Alert"),:$$$Text("Event"))
		Set tDetails($INCREMENT(n)) = $LB(tCat,tID)

		Set tDetails($INCREMENT(n)) = $LB($$$Text("Time"),$G(tTimeLogged))
		Set tDetails($INCREMENT(n)) = $LB($$$Text("Source"),$G(tHost))
		Set tDetails($INCREMENT(n)) = $LB($$$Text("Method"),$G(tMethod))
		Set tDetails($INCREMENT(n)) = $LB($$$Text("Text"),$ZCVT($G(tText),"O","HTML"))

		#; go to Event log, show messages near this one as well
		If ..canViewEvents Set tLinks($INCREMENT(n)) = $LB($$$Text("Event Log"), ..Link("EnsPortal.EventLog.zen?StartId="_$$$URLENCODE(tID-2)_"&EndId="_$$$URLENCODE(tID+2)))
	} Else {
		Set tDetails($INCREMENT(n)) = $LB($$$Text("Production"),"")
	}

	If (tName '= "") {
		#; Add settings details where available
		Set tSC = $$$OK
		Try {
			If (tProd'="") {
				Set tSC = ##class(EnsPortal.Utils).ItemSettings(tProd_"||"_tName, .pData, .pMetaData)
				If $$$ISERR(tSC) Quit
				Set ctxt = ""
				For {
					Set ctxt = $O(pData(ctxt))
					Quit:'ctxt
					If ($LG(pData(ctxt),16) = "Basic") ||
						($LG(pData(ctxt),2) = "PoolSize") ||
						(($LG(pData(ctxt),2) = "Comment") && ($LG(pData(ctxt),3) '= "")) {
						Set tValue = $LG(pData(ctxt),3)
						If (tValue '= "") {
							Set tDetails($INCREMENT(n)) = $LB($LG(pData(ctxt),15),tValue)
						}
					}
				}
			}
		} Catch {
			Set tSC = $$$SystemError
		}

	}
		
	#; describe item
	Set tName = $LG(tDetails(1),1)
	Set tValue = $LG(tDetails(1),2)
	&html<<div>#($$$FormatText($$$Text("Details for %1 %2"),$ZCVT(tName,"O","HTML"),"<b>"_$ZCVT(tValue,"O","HTML")_"</b>"))#</div>>

	#; show set of details
	&html<<table border="0">>
	Set n=""  For { Set n=$O(tDetails(n))  Quit:""=n  Continue:n=1
		Set tName = $LG(tDetails(n),1)
		Set tValue = $LG(tDetails(n),2)
		&html<<tr><td valign="baseline"><div class="DetailLabel">#($ZCVT(tName,"O","HTML"))#</div></td>>
		&html<<td valign="baseline"><div class="DetailValue">#($ZCVT(tValue,"O","HTML"))#</div></td></tr>>
	}
	
	if tSeedName '= "" {
		Set tRetrying = 0
		Set tJob="" For { Set tJob = $O(^IRIS.Temp.EnsJobMonitor($namespace,tJob)) Quit:tJob=""
		Set retCount = $G(^IRIS.Temp.EnsJobMonitor($namespace,tJob,tSeedName,"%Retry"),0) 
		If retCount {
			Set tRetrying = tRetrying + retCount
		}
		}
		If tRetrying {
			&html<<tr><td valign="baseline"><div class="DetailLabel">#($ZCVT("Retrying","O","HTML"))#</div></td>>
			&html<<td valign="baseline"><div id="retryCount" class="DetailValue">#(tRetrying)#</div></td></tr>>
		}
		Set tLastMsg = $G(^IRIS.Temp.EnsHostMonitor($namespace,tSeedName,"%LastActivity"),0)
		If tLastMsg {
			Set tSC  = ..GetElapsedTime(tLastMsg, .tTimeSinceLastMsg)
			&html<<tr><td><div class="DetailLabel">#($ZCVT("Last message processed", "O", "HTML"))#</div></td>>
			&html<<td><div id="lastMsgTime" class="DetailValue">#(tTimeSinceLastMsg)#</div></td></tr>>
		}
	}

	&html<</table><br/>>

	#; show links
	If $Case(tCategory,"BusinessService":1,"BusinessOperation":1,:0) {
		Set tDBId = $Get(^Ens.Runtime("ConfigItem",tSeedID,"%Id"),0)
		if (tDBId > 0) {
			If ..canViewProduction Set tLinks($INCREMENT(n)) = $LB($$$Text("Configure Production"), ..Link("EnsPortal.ProductionConfig.zen?PRODUCTION="_$$$URLENCODE(tProd)_"&HOST="_$$$URLENCODE(tDBId)))
		}
		If ..canUpdateProduction {
			#; Show enable/disable button
			&html<<table border="0"><tr>>
			Set tEnabled = $G(^Ens.Runtime("ConfigItem",tSeedName,"IsEnabled"),1)
			if tEnabled {
				&html<<td><button style="color: gray;" id="enableButton" onclick="zenPage.enableItem('#(tProd)#', '#(tSeedName)#');">Enable</button></td>>
				&html<<td><button id="disableButton" onclick="zenPage.disableItem('#(tProd)#', '#(tSeedName)#');">Disable</button></td>>
			} else {
				&html<<td><button id="enableButton" onclick="zenPage.enableItem('#(tProd)#', '#(tSeedName)#');">Enable</button></td>>
				&html<<td><button style="color: gray;" id="disableButton" onclick="zenPage.disableItem('#(tProd)#', '#(tSeedName)#');">Disable</button></td>>
			}
			&html<</table><br/>>
		}
	}
	
	Set n=""  For { Set n=$O(tLinks(n))  Quit:""=n
		Set tCaption = $LG(tLinks(n),1)
		Set tUrl = $LG(tLinks(n),2)
		If ..isEmbedded {
			&html<<div style="padding-bottom: 5px;"><a target="_blank" class="ribbonSortOption" href="#(..Link(tUrl))#">#(tCaption)#</a></div>>
		} else {
			&html<<div style="padding-bottom: 5px;"><a class="ribbonSortOption" href="#(..Link(tUrl))#">#(tCaption)#</a></div>>
		}
	}
	
	Quit $$$OK
}

/// Acquire and display monitoring data as a series of tables.
Method DrawMonitorInfo(seed As %ZEN.Datatype.string) As %Status
{
	Set tSC = $$$OK

	Try {
		#; get list of user metrics
		Set tUserMetricCount = 0
		Do ..GetUserMetricClasses(.tUserMetrics)

		Set n="" For { Set n=$O(tUserMetrics(n))  Quit:""=n
			Set tMetric = $G(tUserMetrics(n,"Metric"))
			If (tMetric '= "") {
				Set tUserMetricCount = tUserMetricCount + 1
				Set tMetricTitle(tUserMetricCount) = $G(tUserMetrics(n,"Title"),tMetric)
				Set tMetricInstance = $G(tUserMetrics(n,"Instance"))

				Set tSC = ..GetUserMetricInfo(.tMetric,.tStats,.tSummary,tMetricInstance)
				Quit:$$$ISERR(tSC)
				Set tMetricName(tUserMetricCount) = tMetric
			}
		}
		Quit:$$$ISERR(tSC)

		#; gather info
		Set tSC = ..GetHostInfo(.tStats,.tSummary)  Quit:$$$ISERR(tSC)
		Set tSC = ..GetQueueInfo(.tStats,.tSummary)  Quit:$$$ISERR(tSC)
		If ..canQueryEvents Set tSC = ..GetEventLogInfo(.tStats,.tSummary)  Quit:$$$ISERR(tSC)

		Set tCellHeight = ..monitorHeight
		Set:tCellHeight="" tCellHeight = 600
		
		Set tCellWidth = ..frameWidth \ 5
		
		Set tRows = 2 + ((tUserMetricCount+1)\2)
		Set tCellHeight = (tCellHeight / tRows) - 50
		Set tCellHeight = $FN(tCellHeight,"",2)

		#; display the info; use a table to lay out the boxes
		#; &html<<table border="0" width="100%">>
		Set tInfoWidth = $Num((..frameWidth * 0.6),"0")
		&html<<table border="0" width="#(tInfoWidth)#px">>

		&html<<tr valign="top">>

		&html<<td width="1%">&nbsp;</td>>
		&html<<td width="49%">>
		#; &html<<td width="#(tCellWidth)#px">>
		Set tSC = ..DrawInfoTable("BusinessService",.tStats,$$$Text("Incoming Connections"),.tSummary,tCellHeight,seed)
		Quit:$$$ISERR(tSC)
		&html<</td>>

		&html<<td width="1%">&nbsp;</td>>

		&html<<td width="49%">>
		#; &html<<td width="#(tCellWidth)#px">>
		Set tSC = ..DrawInfoTable("BusinessOperation",.tStats,$$$Text("Outgoing Connections"),.tSummary,tCellHeight,seed)
		Quit:$$$ISERR(tSC)

		&html<</td>>
		&html<</tr>>

		&html<<tr valign="top">>
		&html<<td width="1%">&nbsp;</td>>
		&html<<td width="49%">>
		#; &html<<td width="#(tCellWidth)#px">>

		Set tSC = ..DrawInfoTable("Queue",.tStats,$$$Text("Queues"),.tSummary,tCellHeight,seed)
		Quit:$$$ISERR(tSC)
		&html<</td>>
		&html<<td width="1%">&nbsp;</td>>
		&html<<td width="49%">>
		#; &html<<td width="#(tCellWidth)#px">>

		Set tSC = ..DrawInfoTable("EventLog",.tStats,$$$Text("Event Log"),.tSummary,tCellHeight,seed)
		Quit:$$$ISERR(tSC)

		&html<</td>>
		&html<</tr>>
		If (tUserMetricCount>0) {
			For r = 3:1:tRows {
				&html<<tr valign="top">>

				For n = 1:1:2 {
					Set mn = ((r-3)*2) + n
					If (mn <= tUserMetricCount) {
						&html<<td width="1%">&nbsp;</td>>
						&html<<td width="49%">>
						Set tSC = ..DrawInfoTable(tMetricName(mn),.tStats,tMetricTitle(mn),.tSummary,tCellHeight,seed)
						Quit:$$$ISERR(tSC)
						&html<</td>>
					}
				}
				&html<</tr>>
			}
		}
		&html<</table>>

		#; update time field on client
		Set ..lastUpdate = $$$timeLocal
	}
	Catch(ex) {
			Set tSC = ex.AsStatus()
		}
	Quit tSC
}

/// Return a list of Business Metric classes that serve
/// up user dashboard information.<br/>
/// The list of Business Metrics is determined by looking at the 
/// ^Ens.Monitor.Settings global. This takes the following form:
/// <example>
///  Set ^Ens.Monitor.Settings("MetricClasses",1,"Metric") = NameOfMetric
///  Set ^Ens.Monitor.Settings("MetricClasses",1,"Title") = TitleToDisplay
///  Set ^Ens.Monitor.Settings("MetricClasses",1,"Instance") = MetricInstance // (optional)
/// </example>
/// Additional metrics would use a higher second subscript.
Method GetUserMetricClasses(Output pUserSettings)
{
	Merge pUserSettings = ^Ens.Monitor.Settings("MetricClasses")
}

/// Get information from the given business metric cache and place it into
/// <var>pInfo</var> array.<br/>
/// If <var>pMetricInstance</var> is supplied, then it specifies the metric instance
/// to use, otherwise the first (or only) one is used.
Method GetUserMetricInfo(pMetric As %String, ByRef pInfo, ByRef pSummary, pMetricInstance As %String) As %Status
{
	Set tSC = $$$OK

	Try {
		#; get info from metric cache
		If (pMetricInstance '= "") {
			Set tInstance = pMetricInstance
		}
		Else {
			#; find first instance
			Set tInstance = $O($$$EnsMetrics(pMetric,""))
		}
		If (tInstance="") {
			#; identify this as a metric info
			Set tBucket = "$$$METRIC:" _ pMetric
			Set pSummary(tBucket,1) = $LB($$$Text("Status"),$$$Text("No Data"))
			Quit
		}

		#; identify this as a metric info
		Set tBucket = "$$$METRIC:" _ pMetric _ ":" _ tInstance
		
		#; is this metric running
		Set tIsRunning = +$G($$$EnsMetrics(pMetric,tInstance,"%IsRunning"))
		Set tHasData = +$D($$$EnsMetrics(pMetric,tInstance))

		If ('tHasData) {
			Set pSummary(tBucket,1) = $LB($$$Text("Status"),$$$Text("No Data"))
		}
		Else {
			Set pSummary(tBucket,1) = $LB($$$Text("Last Update"),$G($$$EnsMetrics(pMetric,tInstance,"%LastUpdate")))
			If ('tIsRunning) {
				Set pSummary(tBucket,2) = $LB($$$Text("Status"),$$$Text("Not running"))
			}
		}
		Set tProp=""  For { Set tProp=$O($$$EnsMetrics(pMetric,tInstance,tProp))  Quit:""=tProp
			If ($E(tProp,1,1) '= "%") {
				#; metric information
				#; $LB(id,name,type,lamp,icon,value)
				Set tName = tProp
				Set:(tName=+tName) tName=$FN(tName,",")
				Set tMsg = ""
				Set tStatus = $S(tIsRunning:"OK",1:"DISABLED")
				Set tLamp = $Case(tStatus,"OK":"#80FF80","ERROR":"#FF4040","INACTIVE":"#FFFF80",:"#808080")
				Set tIcon = $Case(tStatus,"ERROR":"!","INACTIVE":"-","DISABLED":"X",:"")
				Set tID = tName
				Set tValue = $G($$$EnsMetrics(pMetric,tInstance,tProp))
				Set tSort1 = $Case(tStatus,"OK":3,"ERROR":1,:2)
				Set tSort2 = tName
				Set pInfo(tBucket,tSort1,tSort2,"zzz") = $LB(tID,tName,tStatus,tLamp,tIcon,tValue)
			}
		}
		Quit:$$$ISERR(tSC)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	#; return modified name
	Set:$D(tBucket) pMetric = tBucket

	Quit tSC
}

/// Get information about currently running hosts and place it into
/// <var>pInfo</var> array.
Method GetHostInfo(ByRef pInfo, ByRef pSummary) As %Status
{
	Set tSC = $$$OK
	Try {
		#; summary
		Kill tResult
		Do ##class(EnsPortal.UtilsMonitor).GetServiceSummary(.tResult,0)
		Set pSummary("BusinessService",1) = $LB($$$Text("Last Activity"),$G(tResult("1LastActivityTime")))
		Set pSummary("BusinessService",2) = $LB($$$Text("Completed"),$FN($G(tResult("2ActivitiesCompleted")),","))

		Kill tResult
		Do ##class(EnsPortal.UtilsMonitor).GetOperationSummary(.tResult,0)
		Set pSummary("BusinessOperation",1) = $LB($$$Text("Last Activity"),$G(tResult("1LastActivityTime")))
		Set pSummary("BusinessOperation",2) = $LB($$$Text("Completed"),$FN($G(tResult("2ActivitiesCompleted")),","))
		Set pSummary("BusinessOperation",3) = $LB($$$Text("In Progress"),$FN($G(tResult("3MessagesInProgress")),","))

		#; host information
		#; run query to get stats, then group into buckets
		#dim tRS As %ResultSet
		Set tRS = ##class(%ResultSet).%New()
		Set tRS.ClassName = "Ens.Util.Statistics"
		Set tRS.QueryName = "EnumerateHostStatus"

		Set tSC = tRS.Execute()  Quit:$$$ISERR(tSC)

		Set ..filteredItemCount = 0
		Set ..filteredErrCount = 0
		
		#; List all the categories this user is allowed to view
		If ..allowedCategories '= "" {
			For c = 1:1:$Length(..allowedCategories,",") {
				Set catIndex = $Piece(..allowedCategories,",",c)
				Set tViewableCategoryArray(catIndex) = 1
			}
		}

		While (tRS.Next(.tSC)) {  Quit:$$$ISERR(tSC)
		
			Set tBucket = tRS.Data("Type")
			Set tName = tRS.Data("Name")

			#; Skip internal services & operations
			If (tName = "EnsLib.Testing.Service")||
				(tName = "Ens.ManagerService")||
				(tName = "EnsLib.Background.Service")||
				(tName = "EnsLib.Background.Workflow.Operation")||
				(tName = "Ens.ScheduleService") {
				Continue
			}

			#; Skip non-matching hosts if category specified
			Set tMatch = 0
			Set tId = $Get(^Ens.Runtime("ConfigItem",tName,"%Id"),0)
			If (tId > 0) {
				Set tCategories = ##class(Ens.Config.Item).CategoryGetStored(tId)
				If (..currCategory = "") {
					#; Current category is "All"
					If (..allowedCategories = "") {
						Set tMatch = 1
					} else {
						For i=1:1:$Length(tCategories,",") {
							Set tCat = $ZStrip($Piece(tCategories,",",i),"<>WC")
							If tCat '= "" && $G(tViewableCategoryArray(tCat),0) {
								Set tMatch = 1
								Quit
							}
						}
					}
				} else {
					Set tCleanedCategories=""
					For i=1:1:$Length(tCategories,",") {
						Set tCleanedCategories = tCleanedCategories_"," _ $ZStrip($Piece(tCategories,",",i),"<>WC")
					}
					Set tCategories = tCleanedCategories_","
					Set tCat = ","_%page.currCategory_","
					If tCategories [ tCat {
						Set tMatch = 1
					}
				}
				If 'tMatch {
					Set ..filteredItemCount = ..filteredItemCount+1
					Set tState = $G(^IRIS.Temp.EnsHostMonitor($namespace,tName,"%Status"),-1)
					If (tState = "Error") {
						Set ..filteredErrCount = ..filteredErrCount+1
					}
					Continue
				}
			}
			
			Set tStatus = $ZCVT(tRS.Data("Status"),"U")
			Set tConnState = tRS.Data("AdapterState")

			#; Host status
			Set tLamp = $Case(tStatus,"OK":"#80FF80", "ERROR":"#FF4040", "INACTIVE":"#FFFF80", "RETRY":"#9900CC", :"#808080")
			Set tIcon = $Case(tStatus,"ERROR":"!", "INACTIVE":"-", "DISABLED":"X", :"")
			Set tMsg = $Case(tStatus,"OK":$$$Text("OK"), "ERROR":$$$Text("Error"), "INACTIVE":$$$Text("Inactive"), "":"", :tStatus)

			#; Adapter/Connection State
			Set tCLamp = $S(tConnState[" connected":"#80FF80", tConnState[" disconnected":"#FF4040", tConnState[" listening":"#FFFF80", 1:"#808080")
			Set tCIcon = $S(tConnState[" connected":"+", tConnState[" disconnected":"x", tConnState[" listening":"o", 1:"-")

			#; compose localized Connection State text
			Set (nConn,nDis,nListen)=0
			Set tCMsg=$Case(tConnState,"disabled":$$$Text("disabled"), "n/a":$$$Text("n/a"),"unscheduled":$$$Text("unscheduled"),"not connecting":$$$Text("no jobs"),:"")
			If tCMsg="" {
				Set tState(1)=$P(tConnState,",",1)
				Set tState(2)=$P(tConnState,",",2)
				Set tState(3)=$P(tConnState,",",3)
				For i=1:1:3 {
					Set:tState(i)[" connected" nConn = +tState(i)
					Set:tState(i)[" disconnected" nDis=+tState(i)
					Set:tState(i)[" listening" nListen=+tState(i)
				}
				Set tCMsg=""
				Set:nConn||('nDis&&'nListen) tCMsg=$Case(nConn, 1:$$$Text("1 job connected"), :$$$FormatText($$$Text("%1 jobs connected"),nConn))
				Set tCMsg = tCMsg_$Case(nDis, 0:"", 1:$S(""=tCMsg:"",1:", ")_$$$Text("1 job disconnected"), :$$$FormatText($$$Text("%1 jobs disconnected"),nDis))
				Set tCMsg = tCMsg_$Case(nListen, 0:"", 1:$S(""=tCMsg:"",1:", ")_$$$Text("1 job listening"), :$$$FormatText($$$Text("%1 jobs listening"),nListen))
			}
			#; Assemble sorted pInfo package
			Set tID = tName
			Set tCount = tRS.Data("Count")

			Set tSort1 = $Case(tStatus,"OK":3,"ERROR":1,:2)
			Set tSort2 = $S(nDis:1,1:2)
			If (..sortMode = "Id") {
				Set tSort3 = $G(^Ens.Runtime("ConfigItem",tName,"%Id"),tName)
			} else {
				Set tSort3 = tName
			}

			Set pInfo(tBucket,tSort1,tSort2,tSort3) = $LB(tID,tName,tMsg,tLamp,tIcon,tCount,tCLamp,tCIcon,tCMsg,)
		}
		Quit:$$$ISERR(tSC)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get information about currently running queues and place it into
/// <var>pInfo</var> array under "Queues".
Method GetQueueInfo(ByRef pInfo, ByRef pSummary) As %Status
{
	Set tSC = $$$OK
	Try {
		#; queue information
		Set tRS = ##class(%ResultSet).%New()
		Set tRS.ClassName = "Ens.Queue"
		Set tRS.QueryName = "Enumerate"
		
		Set tSC = tRS.Execute()
		Quit:$$$ISERR(tSC)

		Set n = 0
		Set tTotal = 0
		While (tRS.Next(.tSC)) {
			Quit:$$$ISERR(tSC)

			Set n = n + 1
			Set tCount = tRS.Data("Count")

			#; set lamp color by count
			Set tIcon = ""
			Set tLamp = $S(tCount<1:"#00FF00", tCount<10:"#40A000", tCount<50:"#808000", tCount<200:"orange",1:"#FF4040")
			Set tType = $S(tCount<1:$$$Text("Queue is Empty"), tCount<10:$$$Text("Under 10"), tCount<50:$$$Text("Under 50"), tCount<200:$$$Text("Under 200"),1:$$$Text("Over 200"))
			Set:tCount>=200 tIcon = "!"

			Set tTotal = tTotal + tCount
			Set tName = tRS.Data("Name")
			Set tID = tName

			Set tSort1 = -tCount
			Set tSort2 = tName

			Set tCount = $FN(tCount,",")

			Set pInfo("Queue",tSort1,tSort2,"zzz") = $LB(tID,tName,tType,tLamp,tIcon,tCount)
		}
		Quit:$$$ISERR(tSC)

		#; find suspended messages and add to queue info
		&sql(SELECT COUNT(*) INTO :tSusCount From Ens.MessageHeader WHERE Status = 5)

		Set tName = $$$Text("**Suspended Messages**")
		Set tIcon = "S"
		Set tLamp = $S(tSusCount=0:"#00FF00",1:"orange")
		Set tType = $S(tSusCount<1:$$$Text("None Suspended"), tSusCount<10:$$$Text("Under 10"), tSusCount<50:$$$Text("Under 50"), tSusCount<200:$$$Text("Under 200"),1:$$$Text("Over 200"))

		Set pInfo("Queue",-tSusCount,"zzz","zzz") = $LB(tName,tName,tType,tLamp,tIcon,tSusCount)
		Set tTotal = tTotal + tSusCount

		Set pSummary("Queue",1) = $LB($$$Text("Total Queued Messages"),$FN(tTotal,","))
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get information about top items within the Event Log and place it into
/// <var>pInfo</var> array under "EventLog"
Method GetEventLogInfo(ByRef pInfo, ByRef pSummary) As %Status
{
	Set tSC = $$$OK
	Try {
		#; summary
		Do ##class(EnsPortal.UtilsMonitor).GetLogSummary(.tResult,0)
		Set pSummary("EventLog",2) = $LB($$$Text("Last Error"),$G(tResult("1LastErrorTime")))
		Set pSummary("EventLog",1) = $LB($$$Text("Errors Since Last Start"),$FN($G(tResult("2TotalErrorCount")),","))

		#; run queries to get stats
		Set tStartTime = $G($$$EnsRuntime("StartTime"))
		If tStartTime'="" {
			Set tStartID=0
			Set tSQL = "SELECT TOP 1 ID FROM Ens_Util.Log WHERE TimeLogged >= '"_tStartTime_"' ORDER BY TimeLogged ASC"
			Set tSQLStmnt = ##class(%SQL.Statement).%New()
			Set tSC = tSQLStmnt.%Prepare(tSQL)
			Quit:$$$ISERR(tSC)
			Set tRS = tSQLStmnt.%Execute()	
			If tRS.%Next(.tSC) {
				Quit:$$$ISERR(tSC)
				Set tStartID = tRS.ID
			}	
		} Else {
			Set tStartID=0
		}

		Set tH = $ZTIMESTAMP
		Set tMinutes = (+tH*24*60)+(($P(tH,",",2))\60)

		For tEventType = 2,3,6  { /* Error,Warning,Alert */
			Set tSQL = "SELECT TOP 100 ID, TimeLogged,Type,ConfigName As Source,Text"
			Set tSQL = tSQL _ " FROM Ens_Util.Log "
			Set tSQL = tSQL _ " WHERE Type  ="_tEventType 
			Set:tStartTime'="" tSQL = tSQL _ " AND ID >= "_tStartID
			Set tSQL = tSQL _ " ORDER BY ID DESC"
			Set tSQLStmnt = ##class(%SQL.Statement).%New()
			Set tSC = tSQLStmnt.%Prepare(tSQL)
			Quit:$$$ISERR(tSC)

			Set tRS = tSQLStmnt.%Execute()

			While (tRS.%Next(.tSC)) {
				Quit:$$$ISERR(tSC)

				Set tID = tRS.ID
				Set tEventType = tRS.Type
				Set tText = tRS.Text
				Set:($E(tText,1,5)="ERROR") tText = $P(tText,":",2,999)
				Set tName = tID _ ": " _ tText
				Set tTime = tRS.TimeLogged

				#; find age of event
				Set tTLog = $ZDTH(tTime,3)
				Set tTLogMinutes = (+tTLog*24*60)+(($P(tTLog,",",2))\60)
				Set tAge = tMinutes - tTLogMinutes
				Set tIcon = $S(tEventType=6:"A",tEventType=3:"W",1:"!")
				Set tType = $Case(tIcon,"A":$$$Text("Alert"),"W":$$$Text("Warning"),:$$$Text("Error"))

				Set tMsg = $S(tAge<120:$$$FormatText($$$Text("%1 min"),tAge)
							, tAge>(24*14*60):$$$FormatText($$$Text("%1 wk"),tAge\(24*60*7))
							, 1:$$$FormatText($$$Text("%1 hr"),tAge\60))
				/*Set tLamp = $S(tAge<120:"red"
							, tAge>(24*14*60):"#C04040"
							, 1:"orange")*/
				Set tLamp = $Case(tIcon,"A":"yellow","W":"orange",:"red")

				#; sort by age and event log ID - highest first
				Set tSort1 = tAge
				Set tSort2 = -tID  

				#; $LB(id,name,type,lamp,icon,msg)
				Set pInfo("EventLog",tSort1,tSort2,"zzz") = $LB(tID,tName,tType,tLamp,tIcon,tMsg)
			}
			Quit:$$$ISERR(tSC)
		}
	} Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Render HTML for one category of monitor info.
Method DrawInfoTable(pCategory As %String, ByRef pInfo, pTitle As %String, ByRef pSummary, pCellHeight As %Integer = 200, seed As %ZEN.Datatype.string) As %Status
{
#define ESCJSHTML(%s)  $Replace($Replace($ZCVT(%s,"O","JS"),"<","\x3C"),">","\x3E")

	Set tSC = $$$OK

	Try {
		&html<<div class="MonitorWrapper">>
		&html<<div class="MonitorCaption">#($ZCVT(pTitle,"O","HTML"))#</div>>
		Set tDetailTitle=$Case(pCategory
			,"Queue":$$$Text("Number of messages in this queue")
			,"EventLog":$$$Text("Elapsed time since error was logged")
			,"BusinessService":$$$Text("Number of messages processed since production start")
			,"BusinessOperation":$$$Text("Number of messages processed since production start")
			,:"")
		Set tNumCols=$Case(pCategory
			,"Queue":2
			,"BusinessService":2
			,"BusinessOperation":2
			,:1)
		Set tColSpan=$Case(pCategory
			,"Queue":2
			,"BusinessService":3
			,"BusinessOperation":3
			,:1)

		#; if present, show summary info
		If $D(pSummary(pCategory)) {
			&html<<div class="MonitorSummary"><table border="0" cellpadding="1"><tr>>
			Set k = $O(pSummary(pCategory,""))
			While (k'="") {
				Set tLabel = $LG(pSummary(pCategory,k),1)
				Set tValue = $LG(pSummary(pCategory,k),2)
				&html<<td class="SummaryLabel" nowrap>#($ZCVT(tLabel,"O","HTML"))#:&nbsp;</td><td class="SummaryValue" nowrap>#($ZCVT(tValue,"O","HTML"))#&nbsp;&nbsp;</td>>
				Set k = $O(pSummary(pCategory,k))
			}
			&html<</tr></table></div>>
		}

		#; table of items
		#; mouseout/over logic is needed as IE is not good at hover styles
		Set mlogic = "onmouseover=""this.className+=' ItemHover';"" onmouseout=""this.className=this.className.replace(/(?:^|\s)ItemHover(?!\S)/g , '');"" "
		&html<<div class="MonitorScrollBox" style="height:#(pCellHeight)#px;">>
		&html<<table class="MonitorTable" border="0" cellpadding="0" cellspacing="0">>
		&html<<tr>>
		Set col = 1
		Set tKey="" For { Set tKey = $O(pInfo(pCategory,tKey))  Quit:""=tKey
		  Set tKey2="" For { Set tKey2 = $O(pInfo(pCategory,tKey,tKey2))  Quit:""=tKey2
			Set tKey3="" For { Set tKey3 = $O(pInfo(pCategory,tKey,tKey2,tKey3),1,data)  Quit:""=tKey3
				If (col > tNumCols) {
					#; end of this row
					&html<</tr><tr>>
					Set col = 1
				}
				Set tID = $LG(data,1)
				Set tName = $LG(data,2)
				If (pCategory = "EventLog") {
					Set tShortName = $S($L(tName)>53:$E(tName,1,50)_"...",1:tName)
				}
				Else {
					Set tShortName = $S($L(tName)>53:"..."_$E(tName,$L(tName)-49,$L(tName)),1:tName)
				}
				Set tType=$LG(data,3)
				Set tLampStyle = "background:" _ $LG(data,4,"#C0C0C0") _ ";"
				Set tIcon = $LG(data,5)
				Set tDetail = $LG(data,6)
				Set:tIcon="" tIcon = "&#149;"

				Set:pCategory="Queue"&&(tName["**Suspended") tDetailTitle=$$$Text("Number of Suspended Messages")

				&html<<td class="Lamp" title="#($ZCVT(tType,"O","HTML"))#" style="#(tLampStyle)#">&nbsp;#(tIcon)#&nbsp;</td>>

				Set tIPInfo = ""
				If $Case(pCategory,"BusinessService":1,"BusinessOperation":1,:0) {
					Set tCLampStyle = "background:" _ $LG(data,7,"#C0C0C0") _ ";"
					Set tCIcon = $LG(data,8)
					Set tCMsg = $LG(data,9)
					&html<<td class="Lamp" title="#($ZCVT(tCMsg,"O","HTML"))#" style="#(tCLampStyle)#">&nbsp;#(tCIcon)#&nbsp;</td>>
					Set tIPAddr = $G(^Ens.Runtime("ConfigItem",tName,"Setting","Adapter","IPAddress"),"")
					If (tIPAddr '= "") {
						Set tIPInfo = "; IP Addr: "_tIPAddr
					}
					Set tPort = $G(^Ens.Runtime("ConfigItem",tName,"Setting","Adapter","Port"),"")
					If (tPort '= "") {
						Set tIPInfo = tIPInfo_"; Port: "_tPort
					}
				}
				Set jsCategory=$$$ESCJSHTML(pCategory), jsID=$$$ESCJSHTML(tID), jsName=$S(pCategory="EventLog":"",1:$$$ESCJSHTML(tName))
				Set jsSeed=jsCategory_"~"_jsID_"~"_jsName
				&html<<td id="#(jsSeed)#" class="Item#($S(jsSeed=seed:" ItemSelected",1:""))#" nowrap title="#($ZCVT($S(tShortName=tName:tType, 1:tName),"O","HTML"))# #(tIPInfo)#" onclick="zenPage.selectItem('#(jsCategory)#','#(jsID)#','#(jsName)#');" #(mlogic)#>&nbsp;#($ZCVT(tShortName,"O","HTML"))#&nbsp;</td>>
				&html<<td style="text-align:right;" nowrap title="#($ZCVT(tDetailTitle,"O","HTML"))#">&nbsp;#(tDetail)#&nbsp;</td>>
				Set col = col + 1
			}
		  }
		}
		#; fill the odd box if uneven number
		If (col <= tNumCols) {
			&html<<td colspan="#((1+tColSpan)*(tNumCols+1-col))#" style="background: #F0F0F0;">&nbsp;</td>>
		}
		&html<</tr></table>>
		&html<</div></div>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Intercept xmlHTTP errors and reload page rather than
/// putting up alert box.
ClientMethod onServerMethodError(err, errObject) [ Language = javascript ]
{
	if (errObject && zenPage.enableAutoRefresh) {   // error can only be caused by refresh timer if auto-refresh is enabled
		var code = errObject.code;
		if ((zenPage.limitPopups)&&(code<401)) {
			zenPage.setConnectivityStatusMsg(err);
			window.setTimeout('zenPage.setConnectivityStatusMsg("Re-trying");',11000);
			window.setTimeout('zenPage.testConnectivity();',11000);
			return true;
		}
	}
	top.document.location.reload();
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Production Monitor")
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Production Monitor")
}

}
