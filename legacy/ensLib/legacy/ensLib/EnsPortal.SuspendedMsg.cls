/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsConstants

/// This is the Suspended Messages page of the ZEN application.
Class EnsPortal.SuspendedMsg Extends EnsPortal.Template.listPage [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Suspended Messages";

/// User needs USE permissions on the %Ens_MessageHeader resource to view this page.
Parameter RESOURCE = "%Ens_MessageHeader:USE";

/// Flag to indicate whether a user may discard or delete messages.
Property canDiscard As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MessageDiscard","USE")} ];

/// Flag to indicate whether a user may resend messages.
Property canResend As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MessageResend","USE")} ];

/// Flag to indicate whether a user may edit and resend messages.
Property canEditResend As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MessageEditResend","USE")} ];

/// Flag to indicate whether a user may access the Visual Trace pages.
Property canViewTrace As %ZEN.Datatype.boolean [ InitialExpression = {$system.Security.Check("%Ens_MessageTrace","USE")} ];

/// This XML block defines the contents of the table pane.
XData ListPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<hgroup valign="top">
<spacer width="20" />
<vgroup valign="top"> 
<spacer height="20" />
<tablePane id="table" 
    cellSpacing="2"
    queryClass="EnsPortal.SuspendedMsg"
    queryName="Enumerate"
	fixedHeaders="false"
	maxRows="100000"
	multiSelect="true"
	showRowNumbers="false"
	showQuery="false"
	showZebra="true"
	useKeys="true"
	useSnapshot="true"
	valueColumn="ID"
	>
	<parameter id="filter" value=""/>
	<parameter id="queryMethod" value="InitQuery"/>
	<parameter id="queryClass" value="EnsPortal.SuspendedMsg"/>
	<column header="ID" colName="ID" width="90" style="text-align:left;" onclick="zenPage.showItem('#(%query.ID)#');"  />
	<column header="Time Created" colName="TimeCreated" width="180" />
	<column header="Session" colName="SessionId" width="90" style="text-align:left;" 
       onclick="zenPage.showTrace('#(%query.SessionId)#');" 
       title="Identifier for the session in which the message was sent"
        cellTitle="Click to view a visual trace of the session"  />
	<column header="Error?" colName="Error" width="70" />
	<column header="Source Configuration Name" colName="Source" width="100" />
	<column header="Target Configuration Name" colName="Target" width="200" />
</tablePane>
<spacer height="3"/>
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

Query InitQuery() As %SQLQuery
{
	SELECT TOP 2000 ID,TimeCreated,SessionId,
	CASE IsError WHEN 1 THEN 'Yes' 
	ELSE 'No' END As Error,SourceConfigName As Source, TargetConfigName As Target
	FROM Ens.MessageHeader 
	WHERE Status = 'Suspended'
}

/// Class query with filter added.
/// Override this in order to add rowspec specific to the list being displayed 
Query Enumerate(Filter As %String = "", QueryMethod As %String, QueryClass As %String) As %Query(ROWSPEC = "ID,TimeCreated,SessionId,Error,Source,Target") [ SqlProc ]
{
}

/// show detailTable for a selected task
ClientMethod showItem(msgId) [ Language = javascript ]
{
	var frame = zen('contentFrame');
	frame.setProperty('src','EnsPortal.MessageContents.zen?HeaderClass=Ens.MessageHeader&HeaderId='+msgId);
	frame.setHidden(0);
	zenPage.onlayoutHandler();
}

/// User clicked a link for Trace. Display the Visual Trace page in a popup,
/// so user can click the arrows to go from session to session without losing his/her place in the Event Log.
ClientMethod showTrace(session) [ Language = javascript ]
{
	if (!this.canViewTrace) {
		alert(this.msgNotPermitted);
		return false;
	}
	// zenPage.gotoPage('EnsPortal.VisualTrace.zen?SESSIONID='+session);
	// zenPage.launchPopupWindow(zenLink('EnsPortal.VisualTrace.zen?SESSIONID=' + escape(session)));
	if (session != '') {
		window.open(zenLink('EnsPortal.VisualTrace.zen?SESSIONID=' + escape(session)));
	}
}

/// User selected a new row in the table
ClientMethod doResubmit() [ Language = javascript ]
{
	if (!this.canResend) {
		alert(this.msgNotPermitted);
		return false;
	}
	// Get the values and find out how many
	var tab = zen('table')
	var sel = tab.selectedRows.split(',');
	var len = sel.length;
	var found = 0;
	var val = "";
	for (i=0; i<len; i++) {
		if (sel[i] != "") {
			if (found > 0) val += ',';
			val += sel[i];
			found++;
		}
	}
	
	// Use the values
	if (found == 0) alert($$$Text('Please select one or more messages to resubmit.'));
	else {
		var ret = "";
		sel = val.split(',');
		for (i=0; i<found; i++) {
			ret = ret + zenPage.ResubmitMessage(sel[i]);
		}
		if (ret == "") {
			if (found == 1) alert($$$Text('The selected message has been resubmitted.'));
			else if (found > 1) alert($$$Text('The selected messages have been resubmitted'));
			tab.setProperty('selectedRows','');
			tab.setProperty('selectedIndex',-1);
			tab.executeQuery();
		}
		else {
			alert(ret);
		}
	}
}

/// Adapted from the old CSP page
Method ResubmitMessage(pHeaderId As %String) As %String [ ZenMethod ]
{
	Set tStatus = ##class(Ens.MessageHeader).ResubmitMessage(pHeaderId)
	If $$$ISOK(tStatus) {
		Set tMsg = ""
	} 
	Else {
		Do $system.Status.DecomposeStatus(tStatus,.err)
		Set tMsg = $$$LocalizeText("Ensemble","ResubmitFailed","Resubmit suspended message ID '%1' failed: %2",pHeaderId,$G(err(1))) _ $C(13,10)
	}
	Quit tMsg
}

/// User selected a new row in the table
ClientMethod doEdit() [ Language = javascript ]
{
	if (!this.canEditResend) {
		alert(this.msgNotPermitted);
		return false;
	}
	// Get the values and find out how many
	var tab = zen('table')
	var sel = tab.selectedRows.split(',');
	var len = sel.length;
	var found = 0;
	var val = "";
	for (i=0; i<len; i++) {
		if (sel[i] != "") {
			if (found > 0) val += ',';
			val += sel[i];
			found++;
		}
	}
	
	// Use the values
	if (found == 0) alert($$$Text('Please select one message to edit and resubmit.'));
	else if (found == 1) {
		zenPage.gotoPage(zenLink('EnsPortal.MessageResendEdit.zen?HDR=' + val + '&SUSP=1'));
	}
	else if (found > 1) alert($$$Text('Please select only one message to edit and resubmit.'));
}

/// User selected a new row in the table
ClientMethod doDiscard() [ Language = javascript ]
{
	if (!this.canDiscard) {
		alert(this.msgNotPermitted);
		return false;
	}
	// Get the values and find out how many
	var tab = zen('table')
	var sel = tab.selectedRows.split(',');
	var len = sel.length;
	var found = 0;
	var val = "";
	for (i=0; i<len; i++) {
		if (sel[i] != "") {
			if (found > 0) val += ',';
			val += sel[i];
			found++;
		}
	}
	
	// Use the values
	if (found == 0) alert($$$Text('Please select one or more messages to discard.'));
	else {
		var ret = "";
		sel = val.split(',');
		for (i=0; i<found; i++) {
			ret = ret + zenPage.DiscardMessage(sel[i]);
		}
		if (ret == "") {
			if (found == 1) alert($$$Text('The selected message has been discarded from the suspended list.'));
			else if (found > 1) alert($$$Text('The selected messages have been discarded from the suspended list.'));
			tab.setProperty('selectedRows','');
			tab.setProperty('selectedIndex',-1);
			tab.executeQuery();
		}
		else {
			alert(ret);
		}
	}
}

/// Adapted from the old CSP page
Method DiscardMessage(pHeaderId As %String) As %String [ ZenMethod ]
{
	Set tObj = ##class(Ens.MessageHeader).%OpenId(pHeaderId)
	If $isobject(tObj) {
		Do tObj.SetStatus($$$eMessageStatusDiscarded)
		Set tStatus=tObj.%Save()
		If $$$ISOK(tStatus) {
			Set tMsg = ""
		} 
		Else {
			Do $system.Status.DecomposeStatus(tStatus,.err)
			Set tMsg = $$$LocalizeText("Ensemble","DiscardFailed","Discard suspended message ID '%1' failed: %2",pHeaderId,$G(err(1))) _ $C(13,10)
		}
	} 
	Else {
		Set tMsg = $$$LocalizeText("Ensemble","DiscardFailed","Discard suspended message ID '%1' failed: %2",pHeaderId,"Object failed on open") _ $C(13,10)
	}
	Quit tMsg
}

/// User selected a new row in the table
ClientMethod doDelete() [ Language = javascript ]
{
	if (!this.canDiscard) {
		alert(this.msgNotPermitted);
		return false;
	}
	// Get the values and find out how many
	var tab = zen('table')
	var sel = tab.selectedRows.split(',');
	var len = sel.length;
	var found = 0;
	var val = "";
	for (i=0; i<len; i++) {
		if (sel[i] != "") {
			if (found > 0) val += ',';
			val += sel[i];
			found++;
		}
	}
	
	// Use the values
	if (found == 0) alert($$$Text('Please select one or more messages to delete.'));
	else {
		var ret = "";
		sel = val.split(',');
		for (i=0; i<found; i++) {
			ret = ret + zenPage.DeleteMessage(sel[i]);
		}
		if (ret == "") {
			if (found == 1) alert($$$Text('The selected message has been deleted from the database.'));
			else if (found > 1) alert($$$Text('The selected messages have been deleted from the database.'));
			tab.setProperty('selectedRows','');
			tab.setProperty('selectedIndex',-1);
			tab.executeQuery();
		}
		else {
			alert(ret);
		}
	}
}

/// Adapted from the old CSP page
Method DeleteMessage(pHeaderId As %String) As %String [ ZenMethod ]
{
	Set tStatus = ##class(Ens.MessageHeader).%DeleteId(pHeaderId)
	If $$$ISOK(tStatus) {
		Set tMsg = ""
	} Else {
		Do $system.Status.DecomposeStatus(tStatus,.err)
		Set tMsg = $$$LocalizeText("Ensemble","DeleteFailed","Delete suspended message ID '%1' failed: %2",pHeaderId,$G(err(1))) _ $C(13,10)
	}
	Quit tMsg
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Suspended Messages","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 1
	Set pRibbonTitle = ..%OnGetPageName()
	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnResubmit",$$$Text("Resubmit"),$$$Text("Resend all selected messages"),"zenPage.doResubmit();")
	Set pCommands(2) = $LB("btnEdit",$$$Text("Edit and Resubmit"),$$$Text("Edit a single message before resubmitting"),"zenPage.doEdit();")
	Set pCommands(3) = $LB("btnDiscard",$$$Text("Discard"),$$$Text("Remove all selected messages from list on the Suspended Messages page"),"zenPage.doDiscard();")
	Set pCommands(4) = $LB("btnDelete",$$$Text("Delete"),$$$Text("Permanently delete all selected messages from the database"),"zenPage.doDelete();")
	Quit $$$OK
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod,
				"DeleteMessage": "%Ens_MessageDiscard:USE",
				"DiscardMessage": "%Ens_MessageDiscard:USE",
				"ResubmitMessage": "%Ens_MessageResend:USE",
				: "")
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
		var hgt = winHeight - th -23-2*(!zenIsGecko) - 2*(zenIsIE);
		
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
