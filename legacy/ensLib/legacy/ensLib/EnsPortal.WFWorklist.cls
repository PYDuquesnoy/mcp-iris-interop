/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the Workflow Work List page of the ZEN application.
Class EnsPortal.WFWorklist Extends EnsPortal.Template.listPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Current Workflow Worklist";

/// This XML block defines the contents of the table pane.
XData ListPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
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
	queryClass="EnsPortal.WFWorklist"
	queryName="Enumerate"
	useSnapshot="true"
	showZebra="true"
	pageSize="10000"
	showRowNumbers="false"
	valueColumn="TaskId"
	maxRows="10000" 
	showRowSelector="true"
	onselectrow="zenPage.selectItem(zenThis);"
	onmouseoverClass="tpMouseOver"
	>
	<parameter id="filter" value=""/>
	<parameter id="queryMethod" value="Worklist"/>
	<parameter id="queryClass" value="EnsLib.Workflow.Engine"/> 
<!-- provide header values for all columns so they can be localized -->
<column header="Item ID" colName="ItemId" />
<column header="Task ID" colName="TaskId" style="text-align:left;" onclick="zenPage.showItem('#(%query.TaskId)#');" />
<column header="User Name" colName="UserName" />
<column header="Role Name" colName="RoleName" />
<column header="Priority" colName="Priority" style="text-align:left;"/>
<column header="Time Created" colName="TimeCreated" />
<column header="Age" colName="Age" />
<column header="Assigned To" colName="AssignedTo" />
<column header="Subject" colName="Subject" />
</tablePane>
<spacer height="3" />
</vgroup>
<spacer width="20" />
<vgroup valign="top" align="left">
<spacer height="20"/>
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
Query Enumerate(Filter As %String = "", QueryMethod As %String, QueryClass As %String) As %Query(ROWSPEC = "ItemId,TaskId,UserName,RoleName,Priority,TimeCreated,Age,AssignedTo,Subject") [ SqlProc ]
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

/// show detailTable for a selected task
ClientMethod showItem(taskId) [ Language = javascript ]
{
		var frame = zen('contentFrame');
		frame.setProperty('src','EnsPortal.MessageContents.zen?HeaderClass=EnsLib.Workflow.TaskResponse&HeaderId='+taskId);
		frame.setHidden(0);
		zenPage.onlayoutHandler();
}

/// hide detailTable 
ClientMethod hideItem(taskId) [ Language = javascript ]
{
		var frame = zen('contentFrame');
		frame.setHidden(1);
		zenPage.onlayoutHandler();
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Current Workflow Worklist","Ensemble")
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
