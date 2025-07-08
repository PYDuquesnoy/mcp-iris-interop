/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Workflow InBox page.<br/>
/// Shows the list of current workflow tasks for the current user.
Class %DeepSee.UserPortal.Workflow Extends %DeepSee.UserPortal.standardPage [ System = 4 ]
{

/// Name of this page.
Parameter PAGENAME = "Workflow Inbox";

/// URL of home page (used in links).
Parameter HOMEPAGE = "_DeepSee.UserPortal.Home.zen";

/// Starting view for worklist 1.
Parameter WORKLIST1VIEW;

/// Starting view for worklist 2.
Parameter WORKLIST2VIEW;

/// Item id of current item.
Property currItemId As %String(ZENURL = "ID");

/// Message from form submit handler.
Property lastMessage As %String(ZENURL = "MSG");

/// Percentage height of task list.
Property hzSplit As %Integer [ InitialExpression = 70 ];

/// Last update message.
Property lastUpdateMsg As %String;

Property namespace As %ZEN.Datatype.string [ InitialExpression = {$namespace} ];

XData CSS3Style
{
<style type="text/css">

#contentsLeft {
	width: 300px;
}

#foldersFooter {
	margin: 0px;
	padding: 0px;
	height: 250px;
	background: white;
	background-image: none;
	background-repeat: repeat-x;
	border-top: 1px solid #808080;
	overflow: auto;
}

table.listTable th {
	text-align: left;
	color: #606060;
	font-size: 11pt;
	font-weight: bold;
	padding-top: 2px;
	padding-bottom: 2px;
}

.taskDetailDiv {
	padding: 0px;
}

.taskDetailTitle {
	color: #D08080;
	font-size: 12pt;
}

table.taskDetailTitleTable {
	background: #F8F8F8;
	border-bottom: 1px solid #F0F0F0;
	width: 100%;
}

table.taskDetailTitleTable td {
	padding: 5px;
}

table.taskDetailTable {
	width: 100%;
}

table.taskDetailTable td {
	padding-left: 5px;
	padding-right: 5px;
}

table td.taskDetailLabel {
	color: #808080;
	font-size: 9pt;
	padding-top: 5px;
}

table td.taskDetailValue {
	color: #606060;
	font-size: 11pt;
}

.EmptyMsg {
	padding: 20px;
	font-size: 20px;
	color: #D08080;
}

.rowHover {
	background: #FFEEAA;
}

table.listTable td {
	padding: 2px;
	font-size: 10pt;
	border-bottom: 1px solid #F0F0F0;
}

table.listTable td a {
	color: inherit;
}

.newItem {
	background: #80DD80;
	color: #404040;
	border: 1px solid #808080;
	border-radius: 2px;
	text-align: center;
	font-variant: small-caps;
	font-size: 8pt;
	padding-left: 2px;
	padding-right: 2px;
background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#FFEEAA), color-stop(1.0,#FFCC88));
background: -moz-linear-gradient(top, #A0FFA0, #80DD80);
	background: linear-gradient(top, #A0FFA0, #80DD80);
}

.prioHighest {
	color: red;
	text-align: left;
	font-weight: bold;
	padding-left: 2px;
	padding-right: 2px;
}

.prioHigh {
	color: darkred;
	text-align: left;
	font-weight: bold;
	padding-left: 2px;
	padding-right: 2px;
}

.prioLow {
	color: #808080;
	text-align: left;
	padding-left: 2px;
	padding-right: 2px;
}

.prioVeryLow {
	color: #A0A0A0;
	text-align: left;
	padding-left: 2px;
	padding-right: 2px;
}

#taskDisclosure {
	text-decoration: none;
	color: #606060;
	font-size: 18pt;
}

#taskDisclosure:hover {
	color: black;
	background: #FFEEAA;
}

.taskForm {
	padding-top: 10px;
	padding-bottom: 10px;
}

.taskForm table td {
	color: #404040;
	font-size: 10pt;
}

#lastUpdate {
	color: #606060;
	font-size: 8pt;
	padding-left: 30px;
}

.submitMsg {
	color: #D06060;
	padding: 5px;
}

</style>
}

XData Style
{
<style type="text/css">

#contentsLeft {
	width: 300px;
}

#foldersFooter {
	margin: 0px;
	padding: 0px;
	height: 250px;
	background: white;
	background-image: none;
	background-repeat: repeat-x;
	border-top: 1px solid #808080;
	overflow: auto;
}

table.listTable th {
	text-align: left;
	color: #606060;
	font-size: 11pt;
	font-weight: bold;
	padding-top: 2px;
	padding-bottom: 2px;
}

.taskDetailDiv {
	padding: 0px;
}

.taskDetailTitle {
	color: #D08080;
	font-size: 12pt;
}

table.taskDetailTitleTable {
	background: #F8F8F8;
	border-bottom: 1px solid #F0F0F0;
	width: 100%;
}

table.taskDetailTitleTable td {
	padding: 5px;
}

table.taskDetailTable {
	width: 100%;
}

table.taskDetailTable td {
	padding-left: 5px;
	padding-right: 5px;
}

table td.taskDetailLabel {
	color: #808080;
	font-size: 9pt;
	padding-top: 5px;
}

table td.taskDetailValue {
	color: #606060;
	font-size: 11pt;
}

.EmptyMsg {
	padding: 20px;
	font-size: 20px;
	color: #D08080;
}

.rowHover {
	background: #FFEEAA;
}

table.listTable td {
	padding: 2px;
	font-size: 10pt;
	border-bottom: 1px solid #F0F0F0;
}

table.listTable td a {
	color: inherit;
}

.newItem {
	background: #80DD80;
	color: #404040;
	border: 1px solid #808080;
	-moz-border-radius: 2px;
	border-radius: 2px;
	text-align: center;
	font-variant: small-caps;
	font-size: 8pt;
	padding-left: 2px;
	padding-right: 2px;
}

.newItem:not([ie]) {
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#FFEEAA), color-stop(1.0,#FFCC88));
	background: -moz-linear-gradient(top, #A0FFA0, #80DD80);
}

.prioHighest {
	color: red;
	text-align: left;
	font-weight: bold;
	padding-left: 2px;
	padding-right: 2px;
}

.prioHigh {
	color: darkred;
	text-align: left;
	font-weight: bold;
	padding-left: 2px;
	padding-right: 2px;
}

.prioLow {
	color: #808080;
	text-align: left;
	padding-left: 2px;
	padding-right: 2px;
}

.prioVeryLow {
	color: #A0A0A0;
	text-align: left;
	padding-left: 2px;
	padding-right: 2px;
}

#taskDisclosure {
	text-decoration: none;
	color: #606060;
	font-size: 18pt;
}

#taskDisclosure:hover {
	color: black;
	background: #FFEEAA;
}

.taskForm {
	padding-top: 10px;
	padding-bottom: 10px;
}

.taskForm table td {
	color: #404040;
	font-size: 10pt;
}

#lastUpdate {
	color: #606060;
	font-size: 8pt;
	padding-left: 30px;
}

.submitMsg {
	color: #D06060;
	padding: 5px;
}

</style>
}

/// This XML defines the menu for this page.
XData menuPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<csMenuBar id="mainMenu" width="100px">
<csMenuBarItem caption="Menu">
<contextMenu id="fileMenu">
<csMenuItem id="smp" caption="Management Portal" onclick="zenPage.gotoSMP();" />
</contextMenu>
</csMenuBarItem>
</csMenuBar>
</pane>
}

/// This XML defines the main display area.
XData contentsRightPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshTimerHandler(zenThis);"/>
<html id="foldersHeader" OnDrawContent="DrawTaskHeader"/>
<html id="foldersList" OnDrawContent="DrawTaskList" onrefresh="zenPage.listRefreshed();"/>
<html id="foldersFooter" OnDrawContent="DrawTaskDetails" seed="#(%page.currItemId)#"/>
</pane>
}

/// Draw the contents of the worklist title area.
Method DrawWorklistTitle(pSeed As %String) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		Set tUserName = ##class(%DeepSee.UserPortal.Utils).%GetUserName()
		Write $$$FormatTextHTML($$$Text("Inbox for %1"),tUserName)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw the contents of the Task Header area.
Method DrawTaskHeader(pSeed As %String) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		Set hlpRefresh = $$$Text("Refresh your inbox","%DeepSee")
		Set hlpSearch = $$$Text("Search for items","%DeepSee")

		Set msgRefresh = $$$Text("refresh","%DeepSee")
		Set msgSearch = $$$Text("Search","%DeepSee")
		Set msgGo = $$$Text("Go","%DeepSee")
		
		Set ..lastUpdateMsg = $$$Text("Last update:")_"&nbsp;"_##class(%DeepSee.UserPortal.Utils).%FormatDate($H)

		&html<<div class="foldersHeaderDiv">
		<div style="padding-bottom:3px;">
		<image class="icon" style="vertical-align:bottom;" title="#(hlpRefresh)#" src="deepsee/loop_24.gif" onclick="zenPage.refreshFolders();"/>&nbsp;&nbsp;
		<nobr><input id="searchBox" type="text" size="40" value="#(msgSearch)#" style="color:silver;" onfocus="zenPage.activateSearchBox();" onchange="zenPage.doSearch();" onkeypress="zenPage.searchKeyPress(event);"/>		<input class="commandButton" title="#(hlpSearch)#" type="button" value="#(msgGo)#" onclick="zenPage.doSearch();"/></nobr>
		<span id="lastUpdate" nowrap="1">#(..lastUpdateMsg)#</span>
		</div>
		</div>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw the contents of the Task Details area.
Method DrawTaskDetails(pSeed As %String) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		// pSeed is the worklist item id
		If '##class(%Library.EnsembleMgr).IsEnsembleNamespace() {
			&html<<div class="taskDetailDiv" style="padding:5px; color:#404040;">>
			Write $$$TextHTML("Ensemble is not available in this namespace.","%DeepSee")
			&html<</div>>
			Quit
		}
		Set tItem = $classmethod("EnsLib.Workflow.Worklist","%OpenId",pSeed)

		&html<<div class="taskDetailDiv">>
		If ('$IsObject(tItem)) {
			Set tMsg = $$$TextHTML("No item is selected","%DeepSee")
			Set tState = ""
			Set tOwner = ""
		}
		Else {
			Set tMsg = $$$TextHTML("Details for selected item","%DeepSee")

			// what state are we in?
			Set tOwner = tItem.Task.%TaskStatus.AssignedTo
			If (tOwner = "") {
				Set tState = "unowned"
			}
			ElseIf (tOwner = $UserName) {
				Set tState = "owned"
			}
			Else {
				// owned by someone else
				Set tState = "other"
			}
		}

		Set msgAccept = $$$TextHTML("Accept")
		
		Set hlpAccept = $$$TextHTML("Add this task to your worklist")
		Set hlpDisc = $$$TextHTML("Expand or contract the size of the details panel")

		&html<<form id="taskForm" method="post">>

		// pass along values to make sure ZEN submit logic kicks in
		&html<<input type="hidden" id="taskSubmit" name="$SUBMIT" value=""/>>
		&html<<input type="hidden" name="$ITEMID" value="#($ZCVT(pSeed,"O","HTML"))#"/>>
		
		&html<<table class="taskDetailTitleTable" cellspacing="0" cellpadding="0">>
		&html<<tr>>
		&html<<td class="taskDetailTitle" width="20%">>
		&html<<a id="taskDisclosure" href="#" title="#(hlpDisc)#" onclick="zenPage.toggleDetails();return false;">+</a>&nbsp;>
		&html<#(tMsg)#</td>>

		&html<<td width="80%" align="left">>

		If ($IsObject(tItem)) {
			// determine what buttons to show
			If (tState = "unowned") {
				Do $classmethod("EnsLib.Workflow.FormEngine","ShowAcceptButton",tItem)
			}	 
			ElseIf (tState = "owned") {
				Do $classmethod("EnsLib.Workflow.FormEngine","ShowActionButtons",tItem)
			}
		}
		&html<&nbsp;</td>>

		&html<</tr>>
		&html<</table>>
		
		If (..lastMessage'="") {
			&html<<div class="submitMsg">#($ZCVT(..lastMessage,"O","HTML"))#</div>>
		}
		Set ..lastMessage = ""

		If ($IsObject(tItem)) {
			
			// JMD1096
			// convert to local time
			Set tTime = ""
			If (tItem.TimeCreated'="") {
				Set tLocalH = $ZDTH(tItem.TimeCreatedLogicalToDisplay(tItem.TimeCreated),3)
				Set tTime = ##class(%DeepSee.UserPortal.Utils).%FormatDate(tLocalH)
			}
			Set tPriority = ""

			&html<<table class="taskDetailTable" border="0" cellspacing="0" cellpadding="0">>
			&html<<tr>>
			&html<<td class="taskDetailLabel">#($$$TextHTML("Subject"))#</td>>
			&html<<td class="taskDetailLabel">#($$$TextHTML("Priority"))#</td>>
			&html<<td class="taskDetailLabel">#($$$TextHTML("Assigned To"))#</td>>
			&html<<td class="taskDetailLabel">#($$$TextHTML("Time Created"))#</td>>
			&html<<td class="taskDetailLabel">#($$$TextHTML("Role"))#</td>>
			&html<</tr>>

			&html<<tr>>
			&html<<td class="taskDetailValue"><b>#($ZCVT(tItem.Task.%Subject,"O","HTML"))#</b>&nbsp;</td>>
			&html<<td class="taskDetailValue">>
			If (+tPriority) {
				Set tDisp = $Case(tPriority,1:$$$TextHTML("Highest"),2:$$$TextHTML("High"),3:"",4:$$$TextHTML("Low"),:$$$TextHTML("Very low"))
				Set tCls = $Case(tPriority,1:"prioHighest",2:"prioHigh",3:"",4:"prioLow",:"prioVeryLow")
				&html<<div class="#(tCls)#">#(tDisp)#</div>>
			}
			&html<&nbsp;</td>>
			If (tState = "unowned") {
				&html<<td class="taskDetailValue"><i>#($$$TextHTML("Unassigned"))#</i></td>>
			}
			ElseIf (tState = "owned") {
				&html<<td class="taskDetailValue"><b>#($ZCVT(tOwner,"O","HTML"))#</b>&nbsp;</td>>
			}
			Else {
				&html<<td class="taskDetailValue">#($ZCVT(tOwner,"O","HTML"))#&nbsp;</td>>
			}
			&html<<td class="taskDetailValue">#(tTime)#&nbsp;</td>>
			&html<<td class="taskDetailValue">#($ZCVT(tItem.Role.Name,"O","HTML"))#&nbsp;</td>>
			&html<</tr>>

			&html<<tr>>
			&html<<td colspan="4" class="taskDetailLabel">#($$$TextHTML("Message"))#</td>>
			&html<</tr>>

			Set message=$Replace($TR($Replace($ZCVT(tItem.Task.%Message,"O","HTML"),$C(13,10),$C(10)),$C(13),$C(10)),$C(10),"<br/>"_$C(13,10))
			&html<<tr>>
			&html<<td colspan="4" class="taskDetailValue">#(message)#&nbsp;</td>>
			&html<</tr>>

			&html<</table>>

			If (tState = "owned") {
				Do ..ShowForm(tItem,tState)
			}
			&html<</form>>
		}
		&html<</div>>

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw the contents of the Task List area.
Method DrawTaskList(pSeed As %String) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		Set hlpNew = $$$TextHTML("You have not looked at this item")

		Set tSearch = $$$UPPER(..searchKey)

		// update clock
		Set ..lastUpdateMsg = $$$Text("Last update:")_"&nbsp;"_##class(%DeepSee.UserPortal.Utils).%FormatDate($H)

		Set tSC = ..%GetWorkflowTasksForUser(.tList,.tColumns,..searchKey)
		If $$$ISERR(tSC) Quit

		If '$D(tList) {
			&html<<div class="EmptyMsg">#($$$TextHTML("You have no workflow tasks","%DeepSee"))#</div>>
			Quit
		}

		&html<<div id="folderList">
		<table class="listTable" width="100%" cellspacing="0" border="0" cellpadding="0">>
		&html<<tr class="listHeader">>
			&html<<th style="width:30px;text-align:right;padding-right:4px;color:#808080;">#</th>>

		// list tasks
		Set c = $O(tColumns(""))
		While (c'="") {
			Set tColumn = $G(tColumns(c))
			If (tColumn = "") {
				&html<<th>&nbsp;</th>>
			}
			Else {
				Set tCaption = $LG(tColumn,1)
				Set tType = $LG(tColumn,2)
				If (tType="id") {
				}
				Else {
					If (tType="action") {
						Set tCaption = ""
					}
					&html<<th>#($ZCVT(tCaption,"O","HTML"))#&nbsp;</th>>
				}
			}
			Set c = $O(tColumns(c))
		}
		&html<</tr>>

		// tasks
		Set tRowCount = 0
		Set r = $O(tList(""))
		While (r'="") {
			Set tRow = $G(tList(r))
			Set tRowCount = tRowCount + 1
			Set tCls = $S(tRowCount#2:"listRowOdd",1:"listRowEven")
			Set tTip = ""
			Set tRowId = $LG(tRow,1)  	// id must be first row!
			Set tStyle = $S((tRowId=..currItemId):"color:white;background:rgb(53,107,141);",1:"")

			&html<<tr id="frow_#($ZCVT(tRowId,"O","HTML"))#" class="#(tCls)#" style="#(tStyle)#" title="#(tTip)#" onclick="zenPage.selectItem('#($ZCVT(tRowId,"O","HTML"))#');" onmouseover="this.className='rowHover';" onmouseout="this.className='#(tCls)#';">>
			&html<<td style="width:30px;text-align:right;padding-right:4px;color:#808080;">#(tRowCount)#</td>>

			Set c = $O(tColumns(""))
			While (c'="") {
				Set tColumn = $G(tColumns(c))
				Set tCaption = $LG(tColumn,1)
				Set tType = $LG(tColumn,2)
				Set tFlag = $LG(tColumn,3)

				Set tValue = $LG(tRow,c)
				If (tType = "id") {
				}
				ElseIf (tType = "new") {
					If (tValue="*") {
						&html<<td style="width:20px;" nowrap="1"><div title="#(hlpNew)#" class="newItem">#($$$TextHTML("New"))#&nbsp;</div></td>>
					}
					Else {
						&html<<td>&nbsp;</td>>
					}
				}
				ElseIf (tType = "priority") {
					If (+tValue) {
						Set tDisp = $Case(tValue,1:$$$TextHTML("Highest"),2:$$$TextHTML("High"),3:"",4:$$$TextHTML("Low"),:$$$TextHTML("Very low"))
						Set tCls = $Case(tValue,1:"prioHighest",2:"prioHigh",3:"",4:"prioLow",:"prioVeryLow")
						&html<<td style="width:20px;" nowrap="1"><div class="#(tCls)#">#(tDisp)#&nbsp;</div></td>>
					}
					Else {
						&html<<td>&nbsp;</td>>
					}
				}
				ElseIf (tType = "action") {
					&html<<td><a href="#" onclick="zenPage.invokeAction('#($ZCVT(tFlag,"O","HTML"))#','#($ZCVT(tRowId,"O","HTML"))#');return false;">#($ZCVT(tCaption,"O","HTML"))#</a>&nbsp;</td>>
				}
				Else {
					&html<<td>#($ZCVT(tValue,"O","HTML"))#&nbsp;</td>>
				}
				Set c = $O(tColumns(c))
			}
			&html<</tr>>
			Set r = $O(tList(r))
		}

		&html<</table>>
		&html<<br/></div>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK

	Try {
		// check privileges
		Do CheckPortalUseAccess^%qdsUtils()

		Set tSC = ##super()
		If $$$ISERR(tSC) Quit

		If (+..isEmbedded) {
			Set ..%GetComponentById("navigator").hidden = 1
		}

		// override title
		Set ..title = $ZCVT($G(^DeepSee.UserPortalSettings("PageTitle"),$$$Text("Workflow","%DeepSee")),"O","HTML")

		// Remove smp links if not a developer
		If '$System.Security.Check("%Development","U") {
			Set tMenu = ..%GetComponentById("smp")
			If $IsObject(tMenu) {
				Do tMenu.parent.%RemoveChild(tMenu)
			}
		}
		
		If ..enableAutoRefresh {
			Set ..%GetComponentById("refreshTimer").timeout = 11000
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Workflow Inbox")
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Workflow Inbox")
}

/// Refresh timer has fired.
ClientMethod refreshTimerHandler(timer) [ Language = javascript ]
{
	this.refreshTasks();
	timer.startTimer();
}

/// Called whenever task list is refreshed..
ClientMethod listRefreshed() [ Language = javascript ]
{
	var span = self.document.getElementById('lastUpdate');
	if (span) {
		span.innerHTML = this.lastUpdateMsg;
	}
}

/// Reload the task list.
ClientMethod refreshTasks() [ Language = javascript ]
{
	var tasks = zen('foldersList');
	tasks.refreshContents();
}

/// Activate the search text box;
ClientMethod activateSearchBox() [ Language = javascript ]
{
	var ctrl = self.document.getElementById('searchBox');
	if (ctrl && ctrl.style.color=='silver') {
		ctrl.style.color = '';
		ctrl.value = '';
	}
}

/// Key press in search box.
ClientMethod searchKeyPress(evt) [ Language = javascript ]
{
	// work-around for ie
	evt = evt ? evt : event;
	if (evt.keyCode == zenENTER) {
		zenPage.doSearch();
	}
}

/// Perform a search.
ClientMethod doSearch() [ Language = javascript ]
{
	var ctrl = self.document.getElementById('searchBox');
	if (ctrl && ctrl.style.color=='silver') {
		return;
	}
	this.searchKey = ctrl.value;
	this.refreshTasks();
}

/// Adjust sizes of content area.
ClientMethod onAdjustSizes(load, contentWidth, contentHeight) [ Language = javascript ]
{
	try {
		// folders
		var fHeader = zen('foldersHeader');
		var fList = zen('foldersList');
		var fFooter = zen('foldersFooter');
		if (fHeader && fList && fFooter) {
			var fHeaderDiv = fHeader.getEnclosingDiv();
			var fListDiv = fList.getEnclosingDiv();
			var fFooterDiv = fFooter.getEnclosingDiv();
			
			var availableH = contentHeight - fHeaderDiv.offsetHeight;

			if (availableH < 0) {
				fListDiv.style.display = 'none';
				fFooterDiv.style.display = 'none';
			}
			else {
				var flh = availableH * (parseInt(this.hzSplit)/100);
				var fth = availableH - flh;

				fListDiv.style.display = '';
				fFooterDiv.style.display = '';
				fListDiv.style.height = flh + 'px';
				fFooterDiv.style.height = fth + 'px';
				fListDiv.style.width = contentWidth + 'px';
				fFooterDiv.style.width = contentWidth + 'px';
				fHeaderDiv.style.width = contentWidth + 'px';
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onAdjustSizes');
	}
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	}
}

/// Update the title for the dashboard.
ClientMethod updateWorklistTitle() [ Language = javascript ]
{
	var html = zen('worklistTitle');
	html.refreshContents();
}

/// Update the details panel if the taskid is not the same as URL
ClientMethod updateDetails(taskid) [ Language = javascript ]
{
	let url = new URL(window.location.href);
	var differentTask = true;
	var embedParam = false;
	for (const [key, value] of url.searchParams.entries()) {
		if (key=='ID') {
			if (value == taskid) {
				differentTask = false;
				break;
			}
		}
		if (key=='EMBED') {
			embedParam = true;
			var embedValue = value;
		}
	}
	if (differentTask) window.location.href = `${url.origin}${url.pathname}?ID=${taskid}`+(embedParam ? `&EMBED=${embedValue}`: '');
}

/// Invoke an action on a row.
ClientMethod invokeAction(type, rowid) [ Language = javascript ]
{
}

/// Make details section big or little.
ClientMethod toggleDetails() [ Language = javascript ]
{
	var a = self.document.getElementById('taskDisclosure');
	if (this.hzSplit!=30) {
		a.innerHTML = '-';
		this.setSplit(30);
	}
	else {
		a.innerHTML = '+';
		this.setSplit(70);
	}
}

/// Invoke an action on a row.
ClientMethod setSplit(split) [ Language = javascript ]
{
	if (this.hzSplit!=split) {
		this._targetSplit = parseInt(split);
		this._deltaSplit = Math.round((this.hzSplit - this._targetSplit) / 10);
		this.startSplitTimer();
	}
}

/// Start the split timer.
ClientMethod startSplitTimer() [ Language = javascript ]
{
	zenPage.clearSplitTimer();
	zenPage._splitTimerId = self.setTimeout("zenPage.splitTimerHandler()",25);
}

/// Stop the split timer.
ClientMethod clearSplitTimer() [ Language = javascript ]
{
	if (zenPage._splitTimerId) {
		self.clearTimeout(zenPage._splitTimerId);
		zenPage._splitTimerId = null;
	}
}

/// Action for split timer.
ClientMethod splitTimerHandler() [ Language = javascript ]
{
	this.hzSplit -= this._deltaSplit;
	if (Math.abs(this.hzSplit - this._targetSplit) < 5) {
		this.hzSplit = this._targetSplit;
	}
	this.adjustSizes(false);
	if (this.hzSplit != this._targetSplit) {
		this.startSplitTimer();
	}
}

/// Click on item in task list.
ClientMethod selectItem(id) [ Language = javascript ]
{
	var tr = self.document.getElementById('frow_' + this.currItemId);
	if (tr) {
		tr.style.color = '';
		tr.style.background = '';
	}
	this.currItemId = id;
	var tr = self.document.getElementById('frow_' + this.currItemId);
	if (tr) {
		tr.style.color = 'white';
		tr.style.background = 'rgb(53,107,141)';
	}
	this.updateDetails(id);
}

/// Return list of options for work list 1.
Method %OnGetWorklistOptions1(Output pOptions, Output pDefaultMode) As %Status
{
	// $LB(name,class)
	Set pOptions($I(n)) = $LB("alerts","%DeepSee.UserPortal.AlertList")
	Set pOptions($I(n)) = $LB("favorites","%DeepSee.UserPortal.FavoritesList")
	Set pDefaultMode = "alerts"

	Quit $$$OK
}

/// Return list of options for work list 2.
Method %OnGetWorklistOptions2(Output pOptions, Output pDefaultMode) As %Status
{
	// $LB(name,class)
	Set pOptions($I(n)) = $LB("favorites","%DeepSee.UserPortal.FavoritesList")
	Set pOptions($I(n)) = $LB("recent","%DeepSee.UserPortal.RecentList")
	Set pDefaultMode = "favorites"
	Quit $$$OK
}

/// Return list of workflow tasks for the current user.
ClassMethod %GetWorkflowTasksForUser(Output pList, Output pColumns, pSearchKey As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Set pSearchKey = $$$UPPER(pSearchKey)

		// columns: $LB(name,type,flag)
		Set pColumns($I(c)) = $LB("","id")
		Set pColumns($I(c)) = $LB("","new")
		Set pColumns($I(c)) = $LB($$$Text("Priority"),"priority")
		Set pColumns($I(c)) = $LB($$$Text("Subject"))
		Set pColumns($I(c)) = $LB($$$Text("Message"))
		Set pColumns($I(c)) = $LB($$$Text("Role"))
		Set pColumns($I(c)) = $LB($$$Text("Assigned to"))
		Set pColumns($I(c)) = $LB($$$Text("Time Created"))
		Set pColumns($I(c)) = $LB($$$Text("Age"))

		If (##class(%Library.EnsembleMgr).IsEnsembleNamespace()) {
			Set tCount = 0
			Set tRS = ##class(%ResultSet).%New()
			Set tRS.ClassName = "EnsLib.Workflow.Engine"
			Set tRS.QueryName = "ListTasksForCurrentUser"
			Set tSC = tRS.Execute()
			If $$$ISERR(tSC) Quit

			While (tRS.Next()) {
				Set tSubject = tRS.Get("Subject")
				Set tMessage = tRS.Get("Message")
				Set tAssignedTo = tRS.Get("AssignedTo")
				Set tRoleName = tRS.Get("RoleName")
				Set tSkip = 0
				If (pSearchKey'="") {
					If (($$$UPPER(tSubject)'[pSearchKey)&&($$$UPPER(tMessage)'[pSearchKey)&&($$$UPPER(tAssignedTo)'[pSearchKey)&&($$$UPPER(tRoleName)'[pSearchKey)) {
						Set tSkip = 1
					}
				}

				If ('tSkip) {
					Set tCount = tCount + 1
					Set tTimeCreated = tRS.Get("TimeCreated")
					If (tTimeCreated '= "") {
						#; Get into local time - %FormatDate() accepts ODBC dates
						Set tTimeCreated = ##class(EnsLib.Workflow.Worklist).TimeCreatedLogicalToOdbc(tTimeCreated)
					}
					Set tTimeCreated = ##class(%DeepSee.UserPortal.Utils).%FormatDate(tTimeCreated)
					Set pList($I(r)) = $LB(tRS.Get("ID"),tRS.Get("New"),tRS.Get("Priority"),
						tSubject,tMessage,tRoleName,tAssignedTo,tTimeCreated,tRS.Get("Age"))
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Show form for this worklist item
Method ShowForm(pItem As %RegisteredObject, pState As %String) As %Status
{
	Set tSC = $$$OK
	Set tTask = pItem.Task

	If ($classmethod("EnsLib.Workflow.FormEngine","HasForm",tTask)) {
		&html<<div class="taskForm">>
		Set tSC = $classmethod("EnsLib.Workflow.FormEngine","DrawHTMLForm",tTask,%request.URL)
		&html<</div>>
	}
	Quit tSC
}

/// Called by action buttons on the detail form.
ClientMethod actionButtonHandler(action, confirmMsg) [ Language = javascript ]
{
	if (confirmMsg && (confirmMsg != '')) {
		if (!confirm(confirmMsg)) {
			return false;
		}
	}
	var form = self.document.getElementById('taskForm');

	// test for user-callback (from CSP form template)
	if (self.onAction) {
		if (!self.onAction(form,action)) {
			return false;
		}
	}
	var hsub = self.document.getElementById('taskSubmit');
	if (form && hsub) {
		hsub.value = action;
		form.submit();
	}
	return true;
}

/// Submit handler-- this processes submits of the task form.
ClassMethod %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	Set tSC = $$$OK
	Try {
		// dispatch
		Set tSC = $classmethod("EnsLib.Workflow.FormEngine","%OnSubmit",pSubmit, .tMsg)

		// make sure we return to this page
		Set tItemId = $G(%request.Data("$ITEMID",1))
		Set pSubmit.%NextPage = "_DeepSee.UserPortal.Workflow.zen?ID="_$ZCVT(tItemId,"O","URL")
		If $G(%request.Data("EMBED",1))=1 Set pSubmit.%NextPage = pSubmit.%NextPage_"&EMBED=1"
		If (tMsg'="") {
			Set %response.Context("MSG") = tMsg
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Show the System Management portal.
ClientMethod gotoSMP() [ Language = javascript ]
{
	zenPage.gotoPage('/csp/sys/%25CSP.Portal.Home.zen' + (this.namespace != '' ? ('?$NAMESPACE=' + this.namespace) : ''));
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	var form = self.document.getElementById('taskForm');

	// test for user-callback (from CSP form template)
	if (self.onLoad) {
		self.onLoad(form)
	}
	this.refreshTasks();
	return true;
}

Method downloadLink() As %String [ ZenMethod ]
{

	#dim ex As %Exception.AbstractException
	#dim tReturn = ""
	
	Try {
		#dim tDispatchToClass = $classmethod("EnsLib.Workflow.Worklist","%OpenId",..currItemId)
		Set tDispatchToClass = tDispatchToClass.Task
		Set tReturn = $method(tDispatchToClass,"downloadLink")
	} Catch ex {
		Set tReturn = ""
	}

	Quit tReturn
}

}
