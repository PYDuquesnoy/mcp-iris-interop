/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the Workflow Task Browser page of the ZEN application.
Class EnsPortal.WFTasklist Extends EnsPortal.Template.listPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Workflow Task List";

/// This XML block defines the contents of the table pane.
XData ListPane
{
<pane>
<hgroup>
<spacer width="20" />
<vgroup valign="top">
<spacer height="20" />
<!--<spacer height="10" />-->
<tablePane id="table" 
    cellSpacing="2"
	enclosingStyle="font-size:0.8em;"
	queryClass="EnsPortal.WFTasklist"
	queryName="Enumerate"
	useSnapshot="true"
	showZebra="true"
	nowrap="false"
	pageSize="10000"
	showRowNumbers="false"
	valueColumn="TaskId"
	maxRows="10000" 
	showRowSelector="true"
	onselectrow="zenPage.selectItem(zenThis);"
	ondblclick="zenPage.dblSelectItem(zenThis);"
	onmouseoverClass="tpMouseOver"
	>
	<parameter id="filter" value=""/>
	<parameter id="queryMethod" value="Tasklist"/>
	<parameter id="queryClass" value="EnsLib.Workflow.Engine"/>
<column header="Task ID" colName="TaskId" style="text-align:left;" onclick="zenPage.showItem('#(%query.TaskId)#');" />
<column header="Role Name" colName="RoleName" />
<column colName="IsComplete" hidden="true" />
<column header="Status" colName="Status" />
<column header="Priority" colName="Priority" />
<column header="Source" colName="Source" />
<column header="Assigned To" colName="AssignedTo" />
<column header="Subject" colName="Subject"/>
<column header="Time Created" colName="TimeCreated" />
<column header="Time Completed" colName="TimeCompleted" />
<column header="Duration" colName="Duration"/>
<condition id="condUnassigned" colName="Status" predicate="EQ" value="Unassigned" cellStyle="background: yellow;" />
<condition id="condAssigned" colName="Status" predicate="EQ" value="Assigned" cellStyle="background: #AAAAFF;" />
<condition id="condCancelled" colName="Status" predicate="EQ" value="Cancelled" cellStyle="background: orange; color: #808080;" />
<condition id="condDiscarded" colName="Status" predicate="EQ" value="Discarded" cellStyle="background: #FFA0A0; color: #808080;" />
<condition id="condCompleted" colName="Status" predicate="EQ" value="Completed" cellStyle="background: #D0D0D0; color: #808080;" />
<condition id="condIsComplete" colName="IsComplete" predicate="EQ" value="1" cellStyle="disabled;" />
</tablePane>
<spacer height="3"/>
</vgroup>
<spacer width="20" />
<vgroup valign="top" align="left">
<spacer height="20" />
<iframe id="contentFrame" frameBorder="false"
	   src="" 
	   width="350"
	   hidden="true"
/>
<spacer height="3"/>
</vgroup>
</hgroup>
</pane>
}

/// Class query with filter added.
/// Override this in order to add rowspec specific to the list being displayed 
Query Enumerate(Filter As %String = "", QueryMethod As %String, QueryClass As %String) As %Query(ROWSPEC = "TaskId,RoleName,IsComplete,Status,Priority,Source,AssignedTo,Subject,TimeCreated,TimeCompleted,Duration") [ SqlProc ]
{
}

/// toggle detailTable for a selected row.
ClientMethod selectItem(row) [ Language = javascript ]
{
	if (typeof row == 'object') this.selectedId = row.getValue();
	else this.selectedId = -1;
	
	if (this.selectedId > 0) zenPage.showItem(this.selectedId);
	else zenPage.hideItem();
}

/// double click detailTable for a selected row.
ClientMethod dblSelectItem(row) [ Language = javascript ]
{
	if (typeof row == 'object') this.selectedId = row.getValue();
	else this.selectedId = -1;
	
	if (this.selectedId > 0) zenPage.launchAssign(this.selectedId);
}

/// show detailTable for a selected task
ClientMethod showItem(taskId) [ Language = javascript ]
{
		var frame = zen('contentFrame');
		frame.setProperty('src','EnsPortal.MessageContents.zen?HeaderClass=EnsLib.Workflow.TaskResponse&HeaderId='+taskId);
		frame.setHidden(0);
		zenPage.onlayoutHandler();
}

/// hide detailTable 
ClientMethod hideItem() [ Language = javascript ]
{
		var frame = zen('contentFrame');
		frame.setHidden(1);
		zenPage.onlayoutHandler();
}

ClientMethod assignButton() [ Language = javascript ]
{
	var val = zen('table').getProperty('value');
	if (val.length > 0) zenPage.launchAssign(val);
	else alert($$$Text("First choose a task from the table, then click Assign Task to assign that task to a workflow user."));
}

ClientMethod launchAssign(taskId) [ Language = javascript ]
{
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.WorkflowTaskAssign.zen?TASK='+taskId),this.addPopupSuffix('WFAssign'),'status,scrollbars,resizable=yes,width=400,height=400');
}

ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") {
		return false;
	}
	popupName = this.removePopupSuffix(popupName);
	switch (popupName) {
		case 'WFAssign':
			if (value == 'Changed') zen("table").executeQuery(); // refresh the display table
			break;
		case 'switchNamespace':
			zenPage.changeURLNamespace(value);
			break;
	}
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Workflow Task List","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 1
	Set pRibbonTitle = ..%OnGetPageName()
	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("assignTask",$$$Text("Assign Task"),$$$Text("Assign the currently selected task to a workflow user"),"zenPage.assignButton();")
	Set pCommands(2) = $LB("hideDetail",$$$Text("Hide Details"),$$$Text("Hide the display of workflow message details"),"zenPage.hideItem();")
	Quit $$$OK
}

/// The layout for this page is different from that for other list pages because of the iframe
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		var pane = zen('ListPane');
		var paneDiv = pane.getEnclosingDiv();
		var tabDiv = zen('table').getEnclosingDiv();
		var content = zen('contentFrame');

		paneDiv.style.overflowX = "visible";

		var wid = zenGetWindowWidth() -60- 355*!(zen('contentFrame').getProperty('hidden'));
		if (!(((zenBody.scrollHeight) == (zenBody.offsetHeight)) && (zenBody.scrollTop == 0))) {
			wid = wid - 17;
		}
		if (wid > 300) {
			tabDiv.style.width = wid + 'px';
			paneDiv.style.overflowX = "visible";
			tabDiv.style.overflowX = "auto";
		}
		else {
			tabDiv.style.width = table.scrollWidth + 17*(!(((table.scrollHeight) == (table.offsetHeight)) && (table.scrollTop == 0))) + 'px';
			tabDiv.style.overflowX = "visible";
		}
		
		var winHeight = zenGetWindowHeight();
		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th -23 - 2*(!zenIsGecko) - 2*(zenIsIE);
		
		if (!(((zenBody.scrollWidth) == (zenBody.offsetWidth)) && (zenBody.scrollLeft == 0))) {
			hgt = hgt - 17;
		}
				
		if (hgt > 200) {
			// let table scroll while buttons remain fixed
			if (!(((table.scrollWidth) == (table.offsetWidth)) && (table.scrollLeft == 0))) {
				tabHgt = hgt - 17;
			}
			else tabHgt = hgt;
			tabDiv.style.height = tabHgt + 'px';
			tabDiv.style.overflowY = "auto";
			content.setProperty('height',hgt-17);
		}
		else {
			// the table would be too small to be of much use if we didn't allow entire page to scroll
			hgt = table.scrollHeight + 17 * (!(((table.scrollWidth) == (table.offsetWidth)) && (table.scrollLeft == 0)));
			if ((hgt > 200) || (zen('contentFrame').getProperty('hidden'))) {
				tabDiv.style.height = hgt + 'px';
				content.setProperty('height',table.scrollHeight+17*(!zenIsGecko && !zenIsIE)-17*(zenIsGecko));
			}
			else {
				tabDiv.style.height = 200 + 'px';
				content.setProperty('height',200);
			}
			tabDiv.style.overflowY = "visible";
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler.');
	}
}

}
