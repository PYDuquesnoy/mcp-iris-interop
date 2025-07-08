/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syMirror

/// System Management Portal - System Operations - Mirror Monitor 
Class %CSP.UI.Portal.Mirror.Monitor Extends (%CSP.UI.Portal.Utils, %CSP.UI.Portal.Mirror.Utils) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.Mirror.Monitor.zen";

Parameter HELPADDRESS = "Home,Mirror Monitor";

/// Displayed name of this page.
Parameter PAGENAME = "Mirror Monitor";

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

/// True on the secondary failover member, when it is connected
Property CanDisconnect As %Boolean [ InitialExpression = 0 ];

/// True on the secondary failover member, when it is disconnected
Property CanConnect As %Boolean [ InitialExpression = 0 ];

/// True on the secondary failover member, when it hasn't been added to the primary
Property IsNotSetUp As %Boolean [ InitialExpression = 0 ];

Property IsPrimary As %Integer [ InitialExpression = {$SYSTEM.Mirror.IsPrimary()} ];

Property IsDR As %Integer [ InitialExpression = 0 ];

Property DemoteOther As %Boolean [ InitialExpression = 0 ];

/// 0 - not a mirror member <br>
/// 1 - failover mirror member <br>
/// 2 - async mirror member
Property MirrorMemberType As %Integer [ InitialExpression = {$System.Mirror.IsMember()} ];

/// Failover member's mirror name
Property MirrorName As %String;

/// Current 'no failover' state.
Property DefinedPrimary As %String;

/// Candidate of the new DefinedPrimary.
Property NewDefinedPrimary As %String;

/// Member name of local system.
Property MyMemberName As %String;

/// 1 - display 'Clear/Set No Failover' button, 0 - don't display
Property NoFailoverBtn As %Integer [ InitialExpression = 0 ];

/// 1 - The DefinedPrimary is the special name of No Partner No Failover promotion.
Property IsNoPartnerNoFailover As %Integer [ InitialExpression = 0 ];

/// The currently selected mirror on an async member
Property SelectedMirror As %String [ InitialExpression = "*" ];

Property ThisMemberName As %ZEN.Datatype.string [ InitialExpression = "n/a" ];

Property ThisMemberECP As %ZEN.Datatype.string [ InitialExpression = "n/a" ];

Property ThisMemberPrivateAddress As %ZEN.Datatype.string [ InitialExpression = "n/a" ];

Property OtherMemberName As %ZEN.Datatype.string [ InitialExpression = "n/a" ];

Property OtherMemberECP As %ZEN.Datatype.string [ InitialExpression = "n/a" ];

Property OtherMemberPrivateAddress As %ZEN.Datatype.string [ InitialExpression = "n/a" ];

/// Failover member's mirror name
Property ReceivedData As %String [ InitialExpression = "0,0,0" ];

/// Number of mirror set configured.
Property NumberOfMirrorSet As %Integer [ InitialExpression = 0 ];

Property VirtualIP As %String;

Property VirtualInterface As %String;

Property DownList As %String;

Property PromoteErrorText As %String;

/// Store translated targetCol linkCaption for <condition>
Property colMount As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Mount")} ];

Property colActivate As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Activate")} ];

Property colCatchup As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Catchup")} ];

Property colRemove As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Remove")} ];

Property colDownload As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Download")} ];

/// Check if user has manage privilege
Property CanManage As %ZEN.Datatype.boolean [ InitialExpression = {$System.Security.Check("%Admin_Manage","USE")} ];

/// If server encountered failure that cannot be ignored.
Property failedCnt As %ZEN.Datatype.boolean [ InitialExpression = {##class(SYS.MirrorConfiguration).LookupLocalValidationFailures(.failure,0)} ];

XData Style
{
<style type="text/css">
/* additional style for table pane */
table.tpTable th {
	border-right: 1px solid #F1F0E7;
	border-bottom: 1px solid #F1F0E7;
}

table.tpTable td {
	border-right: 1px solid #F1F0E7;
	border-top: 1px solid #F1F0E7;
}
#checkFailure {
	border: 1px solid #da4848;
	border-radius: 5px;
	margin: 10px;
	padding: 10px;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane containerStyle="padding:20px;padding-top:10px;">
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<group id="fld" layout="none">
<timer id="refreshTimer" timeout="0" ontimeout="zenPage.refreshHandler();"/>
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group id="checkFailure" hidden="true">
<label id="Text3"/>
<html>
<div id="failureMessage"></div>
</html>
</group>
<jsonProvider id="jsonValidationInfo" OnGetTargetObject="GetValidationInfo">
 </jsonProvider>
<hgroup id="FailoverInfoGroup">
<fieldSet labelPosition="left" label="Mirror Failover Member Information" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<hgroup>
<vgroup>
<label label=" "/>
<label label="Mirror Member Name"/>
<label label="Superserver Address"/>
<label label="Mirror Private Address"/>
</vgroup>
<spacer width="5px"/>
<vgroup>
<label value="This Failover Member" controlClass="normal" controlStyle="text-decoration:underline;"/>
<label id="ThisMemberName" value="n/a" controlClass="normal"/>
<label id="ThisMemberECP" value="n/a" controlClass="normal"/>
<label id="ThisMemberPrivateAddress" value="n/a" controlClass="normal"/>
</vgroup>
<spacer width="5px"/>
<vgroup>
<label value="Other Failover Member" controlClass="normal" controlStyle="text-decoration:underline;"/>
<label id="OtherMemberName" value="n/a" controlClass="normal"/>
<label id="OtherMemberECP" value="n/a" controlClass="normal"/>
<label id="OtherMemberPrivateAddress" value="n/a" controlClass="normal"/>
</vgroup>
</hgroup>
</fieldSet>
<fieldSet labelPosition="left" label="Arbiter Connection Status" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<label id="ArbiterNode" label="Arbiter Address" controlClass="normal"/>
<label id="FailoverMode" label="Failover Mode" controlClass="normal"/>
<label id="ConnectionStatus" label="Connection Status" controlClass="normal"/>
</fieldSet>
</hgroup>

<group id="AsyncInfoGroup" hidden="true" labelPosition="left" enclosingStyle="padding-top:5px;">
<label id="MemberName" label="Async Member Name" controlClass="normal"/>
<label id="MemberType" label="Async Member Type" controlClass="normal"/>
</group>

<group id="VirtualAddressGroup" hidden="true" labelPosition="top" enclosingStyle="padding-top:5px;">
<fieldSet labelPosition="left" label="Virtual Address Information" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<label id="VIPAddress" label="IP Address" controlClass="normal"/>
<label id="VIPMask" label="Mask (CIDR format)" controlClass="normal"/>
<label id="VIPInterface" label="Network Interface" controlClass="normal"/>
</fieldSet>
</group>

<group id="AsyncMirrorTableGroup" hidden="true">
<fieldSet labelPosition="left" label="Mirrors this async member belongs to" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<tablePane
id="AsyncMirrorTable"
cellSpacing="2"
dataSource="columns"
maxRows="1000"
multiSelect="false"
showZebra="true"
>
<parameter value="*"/>
<column colName="Name" header="Mirror Name"/>
<column colName="AgentAddress" header="Agent Address"/>
<column colName="AgentPort" header="Agent Port"/>
<column colName="InstanceDirectory" header="Instance Directory"/>
<column colName="Status" header="Status"/>
<column colName="StatusInt" hidden="true"/>
<column colName="JournalLatency" header="Journal Transfer"/>
<column colName="DatabaseLatency" header="Dejournaling"/>
<column linkCaption="Details" link="javascript:zenPage.doDetails('#(%query.Name)#');" style="text-align:center;"/>
<column OnDrawCell="DrawConnectLink"/>
<!-- Do not show Details link if status is Down. -->
<!--condition colName="StatusInt" predicate="NEQ" value="1" cellStyle="disabled" targetCol="Details"/-->
</tablePane>
</fieldSet>
</group>

<group id="MembersForFailover">
<fieldSet labelPosition="top" label="Mirror Member Status" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<tablePane
id="FailoverMemberTable"
cellSpacing="2"
dataSource="columns"
maxRows="1000"
multiSelect="false"
showZebra="true"
rowSelect="false"
permitClientSQL="true"
>
<parameter value=""/>
<column colName="MemberName" header="Member Name"/>
<column colName="CurrentRole" header="Member Type"/>
<column colName="CurrentStatus" header="Status"/>
<column colName="JournalTimeLatency" header="Journal Transfer"/>
<column colName="DatabaseTimeLatency" header="Dejournaling"/>
<column colName="X509DN" header="X.509 DN"/>
</tablePane>
<label id="NoFailoverState" controlClass="normal" containerStyle="font-weight:bold;" hidden="true"/>
<label id="FailoverJournalRate" label="Incoming Journal Transfer Rate for This Member (over refresh interval)" controlClass="normal" hidden="true"/>
</fieldSet>
</group>

<group id="MembersForAsync" hidden="true">
<fieldSet id="MembersForAsyncFS" labelPosition="top" label="Mirror Member Status" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<tablePane
id="AsyncMemberTable"
cellSpacing="2"
dataSource="columns"
maxRows="1000"
multiSelect="false"
showZebra="true"
rowSelect="false"
permitClientSQL="true"
>
<parameter id="memberMirrorParam" value="#(%page.SelectedMirror)#"/>
<column colName="MemberName" header="Member Name"/>
<column colName="DisplayType" header="Member Type"/>
<column colName="DisplayStatus" header="Status"/>
<column colName="JournalTimeLatency" header="Journal Transfer"/>
<column colName="DatabaseTimeLatency" header="Dejournaling"/>
</tablePane>
<label id="AsyncJournalRate" label="Incoming Journal Transfer Rate for This Member (over refresh interval)" controlClass="normal" hidden="true"/>
</fieldSet>
</group>

<group id="MissingMirroredDB" hidden="true">
<fieldSet id="MissingMirroredDBFS" labelPosition="left" label="Missing Mirrored Databases Report" labelClass="redText" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<tablePane
id="MissingDBTable"
queryClass="SYS.Mirror"
queryName="MissingMirroredDatabases"
cellSpacing="2"
dataSource="columns"
maxRows="1000"
multiSelect="false"
showZebra="true"
rowSelect="false"
>
<parameter id="missingDBMirrorParam" value=""/>
<column colName="Name" header="Mirrored Database Name"/>
</tablePane>
</fieldSet>
</group>

<group id="DBGroup">
<fieldSet id="DBGroupFS" labelPosition="top" label="Mirrored Databases" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;">
<tableNavBar showFilter="true" showPageSize="true" tablePaneId="dbTable" showMaxRows="true" 
onfilterChange="zenPage.filterChanged(value);"
saveSizeMax="true" onPageSizeChange="zenPage.navPageSizeChanged(value,'dbTable');" onMaxRowsChange="zenPage.navMaxRowsChanged(value,'dbTable');"
title="Enter the leading characters of a database name followed by [Tab] to filter the list. For example: C for all database names starting with letter 'C'."/>
<tablePane
id="dbTable"
cellSpacing="2"
queryClass="%CSP.UI.System.Mirror"
queryName="MirroredDatabaseList"
dataSource="columns"
maxRows="1000"
multiSelect="false"
showZebra="true"
useSnapshot="true"
>
<parameter id="dbMirrorParam" value="#(%page.SelectedMirror)#"/>
<parameter value="#(%page.Filter)#"/>
<parameter value=""/>
<column colName="Name" header="Name"/>
<column colName="Directory" header="Directory"/>
<column colName="MirrorStatus" header="Status"/>
<column colName="LastDejournalRecord" header="Next Record To Dejournal (Time, Filename, Offset)"/>
<column colName="Mounted" hidden="true"/>
<column colName="InActiveMirror" hidden="true"/>
<column colName="ActivationRequired" hidden="true"/>
<column colName="CatchupRunning" hidden="true"/>
<column colName="NeedCatchup" hidden="true"/>
<column colName="Downloading" hidden="true"/>
<column colName="NeedDownload" hidden="true"/>
<column name="Mount" linkCaption="Mount" link="javascript:zenPage.doMount('#(%query.Name)#','#(%query.Directory)#');" style="text-align:center;"/>
<column name="Activate" linkCaption="Activate" link="javascript:zenPage.doActivate('#(%query.Name)#','#(%query.Directory)#');" style="text-align:center;"/>
<column name="Catchup" linkCaption="Catchup" link="javascript:zenPage.doCatchup('#(%query.Name)#','#(%query.Directory)#',#(%query.ActivationRequired)#);" style="text-align:center;"/>
<column name="Download" linkCaption="Download" link="javascript:zenPage.doDownload('#(%query.Name)#','#(%query.Directory)#');" style="text-align:center;"/>
<column name="remove" linkCaption="Remove" link="javascript:zenPage.doRemove('#(%query.Name)#','#(%query.Directory)#');" style="text-align:center;" hidden="#(%page.failedCnt)#"/>

<!-- only show mount if dismounted -->
<condition colName="Mounted" predicate="NEQ" value="0" cellStyle="disabled" targetCol="#(%page.colMount)#"/>

<!-- if db is dismounted, no actions can be performed -->
<condition colName="Mounted" predicate="EQ" value="0" cellStyle="disabled" targetCol="#(%page.colActivate)#"/>
<condition colName="Mounted" predicate="EQ" value="0" cellStyle="disabled" targetCol="#(%page.colCatchup)#"/>
<condition colName="Mounted" predicate="EQ" value="0" cellStyle="disabled" targetCol="#(%page.colRemove)#"/>
<condition colName="Mounted" predicate="EQ" value="0" cellStyle="disabled" targetCol="#(%page.colDownload)#"/>

<!-- if the database is in the active mirror, can't activate or catchup -->
<condition colName="NeedCatchup" predicate="EQ" value="0" cellStyle="disabled" targetCol="#(%page.colCatchup)#"/>

<!-- if activation is not required, can't activate -->
<condition colName="ActivationRequired" predicate="EQ" value="0" cellStyle="disabled" targetCol="#(%page.colActivate)#"/>

<!-- if download is in progress, can't download -->
<condition colName="NeedDownload" predicate="EQ" value="0" cellStyle="disabled" targetCol="#(%page.colDownload)#"/>

<!-- if catchup is running, no actions can be performed -->
<condition colName="CatchupRunning" predicate="EQ" value="1" cellStyle="disabled" targetCol="#(%page.colActivate)#"/>
<condition colName="CatchupRunning" predicate="EQ" value="1" cellStyle="disabled" targetCol="#(%page.colCatchup)#"/>
<condition colName="CatchupRunning" predicate="EQ" value="1" cellStyle="disabled" targetCol="#(%page.colRemove)#"/>
<condition colName="CatchupRunning" predicate="EQ" value="1" cellStyle="disabled" targetCol="#(%page.colDownload)#"/>

<!-- if mirror DB is in downloading state, no actions other than Download can be performed -->
<condition colName="Downloading" predicate="EQ" value="1" cellStyle="disabled" targetCol="#(%page.colActivate)#"/>
<condition colName="Downloading" predicate="EQ" value="1" cellStyle="disabled" targetCol="#(%page.colCatchup)#"/>
<condition colName="Downloading" predicate="EQ" value="1" cellStyle="disabled" targetCol="#(%page.colDownload)#"/>

</tablePane>
<hgroup labelPosition="left" label="Click 'Go' to perform an action on multiple databases" hidden="#(%page.failedCnt)#" >
<select id="action" displayList="--Select an action--,Mount,Activate,Catchup,Remove" valueList="0,M,A,C,R" showEmpty="false"/>
<spacer width="5px"/>
<button caption="Go" onclick="zenPage.doAction(zen('action').getValue());"/>
</hgroup>
</fieldSet>
</group>

</group>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	var json = zen('jsonValidationInfo').getContentObject();
	this._validationInfo = json;
	if (json.failedCount > 0) {
		json.CanManage = this.CanManage;
		var proxy = this.getFailureMessages(json);
		if (proxy.msg) {
			zen('Text3').setValue('');
			var msg = proxy.msg;
			if (proxy.list) {
				msg += proxy.list;
			}	
			var failureMessage = document.getElementById("failureMessage");
			failureMessage.innerHTML = msg;
		}
		zen('checkFailure').setHidden(false);
		return;	
	}
	if (!zenPage.NoFailoverBtn) {
		document.getElementById("command_btnNoFailover").style.visibility = "hidden";
	}
	if (!zenPage.IsNotSetUp) {
 		if (zenPage.MirrorMemberType == 1) {
			if (this.IsPrimary != 1) {
				var table = zen("MissingDBTable");
				var total = table.getProperty("rowCount");
				if (total > 0) {
					zen("MissingMirroredDB").setHidden(false);
				}
				if (!this.IsEMSReadOnly) {
					document.getElementById("command_btnPromote").style.visibility = "visible";
					document.getElementById("command_btnPromote").innerHTML = "<nobr>"+$$$Text("Demote To DR Member")+"</nobr>";
					document.getElementById("command_btnPromote").title = $$$Text("Demote this failover member to a DR member.");
				}
			}
			if (!this.IsEMSReadOnly) {
				if (this.DemoteOther) {
					document.getElementById("command_btnDemote").style.visibility = "visible";
				} else {
					document.getElementById("command_btnDemote").style.visibility = "hidden";
				}
			}
			document.getElementById("command_btnJournal").style.visibility = "visible";
			if ((zenPage.CanConnect) || (zenPage.CanDisconnect)) {
				document.getElementById("command_btnConnect").style.visibility = "visible";
				if (zenPage.CanDisconnect) {
					document.getElementById("command_btnConnect").innerHTML = "<nobr>"+$$$Text("Stop Mirror On This Member")+"</nobr>";
					document.getElementById("command_btnConnect").title = $$$Text("Stop mirror in this backup member.");
				}
			}
			if (zenPage.NoFailoverBtn) {
				document.getElementById("command_btnNoFailover").style.visibility = "visible";
				if (zenPage.DefinedPrimary == '') {
					document.getElementById("command_btnNoFailover").innerHTML = "<nobr>"+$$$Text("Set No Failover")+"</nobr>";
					document.getElementById("command_btnNoFailover").title = $$$Text("Set 'no failover' in the mirror.");
				} else {
					document.getElementById("command_btnNoFailover").innerHTML = "<nobr>"+$$$Text("Clear No Failover")+"</nobr>";
					document.getElementById("command_btnNoFailover").title = $$$Text("Clear 'no failover' in the mirror.");
				}
			}
		} else if (zenPage.NumberOfMirrorSet == 1) {
			if ((zenPage.CanConnect) || (zenPage.CanDisconnect)) {
				document.getElementById("command_btnConnect").style.visibility = "visible";
				if (zenPage.CanDisconnect) {
					document.getElementById("command_btnConnect").innerHTML = "<nobr>"+$$$Text("Stop Mirror On This Member")+"</nobr>";
					document.getElementById("command_btnConnect").title = $$$Text("Stop mirror in this async member.");
				} else {
					document.getElementById("command_btnConnect").title = $$$Text("Start mirror in this async member.");
				}
			}
			if (zenPage.IsDR == 1) {
				if (!this.IsEMSReadOnly) {
					document.getElementById("command_btnPromote").style.visibility = "visible";
				}
				document.getElementById("command_btnJournal").style.visibility = "visible";
			}
			if (!this.IsEMSReadOnly) {
				document.getElementById("command_btnDemote").style.visibility = "hidden";
			}
			zenPage.doDetails(zenPage.MirrorName);
		}
	}
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	try {
		switch(popupName) {
			case 'dbActions':
			case 'MountDB':
			case 'AuthAsync':
				zenPage.updateView(false,true);
				break;
			case 'Promote':
				// Successfully become a failover member, need to refresh the screen.
				zenPage.IsDR = 0;
				zenPage.MirrorMemberType = 1;
				zenPage.RefreshFailoverInfo();
				zenPage.onloadHandler();
				zenPage.updateView(false,true);
				break;
			case 'RemoveLocalConfig':
				window.location.href = this.homePage;
				break;
			case 'JoinNewMember':
			case 'NodeAddressEdit':
				window.location.reload(true);
				break;
		}
	} catch (ex) {
			alert("Error: " + ex);
	}

	return true;
}

/// Update / Reload tables. This overrides the one in Portal.Utils.
ClientMethod updateView(InTimer, NoCompress) [ Language = javascript ]
{
	zen('dbTable').executeQuery();
	var RefreshCompress = 0;
	if (!NoCompress) {
		RefreshCompress = 1;
	}
	
	if (zenPage.MirrorMemberType == 1) {
		if (this.IsPrimary != 1) {
			zenPage.CheckMissingDB();
		}
		zen('FailoverMemberTable').executeQuery();
		zenPage.DrawFailoverInfo(RefreshCompress);
		if (!this.IsEMSReadOnly) {
			if (this.DemoteOther) {
				document.getElementById("command_btnDemote").style.visibility = "visible";
			} else {
				document.getElementById("command_btnDemote").style.visibility = "hidden";
			}
		}
	} else {
		if (this.NumberOfMirrorSet > 1) {
			var mirrorTable = zen('AsyncMirrorTable');
			var currMirror = mirrorTable.selectedIndex;
			var syncMode = zenSynchronousMode;
			zenSynchronousMode = true;
			mirrorTable.executeQuery();
			mirrorTable.setProperty('selectedIndex',currMirror);
			zenSynchronousMode = syncMode;
		}
		if (this.IsDR == 1) {
			zenPage.CheckMissingDB();
		}
		if (RefreshCompress == 1) {
			zenPage.GetCompressRate(zenPage.SelectedMirror,1);
		}
		zen('AsyncMemberTable').executeQuery();
		zenPage.DrawAsyncInfo();
	}
	zenPage.updateTime();
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value) [ Language = javascript ]
{
	var table = zen("dbTable");
	if (value.indexOf("*") == -1) {
		value += "*";
	}
	table.parameters[1].value = value;
	table.executeQuery();
}

ClientMethod doJournal() [ Language = javascript ]
{
	var url = 'UtilSysJournalsMirror.csp';
	this.gotoPage(url);
}

ClientMethod doMount(dbName, dbDir) [ Language = javascript ]
{
	var url = '%CSP.UI.Portal.Dialog.DBActions.zen?Dir=' + encodeURIComponent(dbDir) + '&DBName=' + encodeURIComponent(dbName) + '&ACTION=Mount';
	zenLaunchPopupWindow(url,'MountDB','resizable,width=500,height=600');
}

ClientMethod doActivate(dbName, dbDir) [ Language = javascript ]
{
	var text = $$$Text("Are you sure you want to activate database %1?");
	text = text.replace('%1',dbName);
	if (confirm(text)) {
		var st = zenPage.ActivateDB(dbDir);
		if (st == 1) {
			zenPage.updateView(false,true);
		} else {
			alert(st);	
		}
	}
}

ClientMethod doCatchup(dbName, dbDir, actReq) [ Language = javascript ]
{
	var text = $$$Text("Are you sure you want to run catchup for database %1?");
	text = text.replace('%1',dbName);
	if (confirm(text)) {
		var st = zenPage.CatchupDB(dbDir,actReq);
		if (st == 1) {
			text = $$$Text("This job is running in the background. You may view background tasks to see the status and result.");
			alert(text);
			zenPage.updateView(false,true);
		} else {
			alert(st);	
		}
	}
}

ClientMethod doDownload(dbName, dbDir) [ Language = javascript ]
{
	var text = $$$Text("Are you sure you want to run download for database %1?");
	text = text.replace('%1',dbName);
	if (confirm(text)) {
		var st = zenPage.DownloadDB(dbDir,zenPage.MirrorName,dbName);
		if (st == 1) {
			text = $$$Text("This job is running in the background. You may view background tasks to see the status and result.");
			alert(text);
			zenPage.updateView(false,true);
		} else {
			alert(st);	
		}
	}
}

ClientMethod doRemove(dbName, dbDir) [ Language = javascript ]
{
   var text = $$$Text("Access to databases being removed may result in <PROTECT> error, while this action takes place.  Once a mirrored database is removed, it is no longer a valid copy; this is irreversible.")+"\n";
	if (this.IsPrimary == 1) {
		text += $$$Text("If this database is added back to the mirror later, using the same mirror database name, other copies will need to be replaced with this version of the database.");
	} else {
		text += $$$Text("If you decide to restore this database later, you will need to get a copy from one of the other mirror members.");
	}
	text += "\n\n"+$$$Text("Are you sure you want to remove database %1 from the mirror?");
	text = text.replace('%1',dbName);
	if (confirm(text)) {
		var st = zenPage.RemoveDB(dbDir);
		if (st == 1) {
			zenPage.updateView(false,true);
		} else {
			alert(st);	
		}
	}
}

ClientMethod doAction(action) [ Language = javascript ]
{
	if (action == 0) return;
	var url = '%CSP.UI.Portal.Dialog.MirrorDBActions.zen?SelectedMirror='+encodeURIComponent(zenPage.SelectedMirror)+'&Action='+encodeURIComponent(action);
	zenLaunchPopupWindow(url,'dbActions','status,scrollbars,resizable=yes,width=600,height=500');
}

ClientMethod doAuth(PID) [ Language = javascript ]
{
	var url = '%CSP.UI.Portal.Dialog.MirrorAuthorizedAsync.zen?PID='+encodeURIComponent(PID);
	zenLaunchPopupWindow(url,'AuthAsync','status,scrollbars,resizable=yes,width=650,height=500');
}

ClientMethod doDetails(mirName) [ Language = javascript ]
{
	var textDB = $$$Text("Mirrored Databases for %1");
	textDB = textDB.replace('%1',mirName);
	var textMember = $$$Text("Mirror Member Status for %1");
	textMember = textMember.replace('%1',mirName);
	zen('MembersForAsyncFS').setProperty('label',textMember);
	zen('DBGroupFS').setProperty('label',textDB);
	zenPage.GetCompressRate(mirName,1);
	
	var syncMode = zenSynchronousMode;
	zenSynchronousMode = true;
	zenPage.SelectedMirror = mirName;
	zen('memberMirrorParam').value = mirName;
	zen('AsyncMemberTable').executeQuery();
	zen('dbMirrorParam').value = mirName;
	zen('dbTable').executeQuery();
	zenSynchronousMode = syncMode;
	if (this.IsDR == 1) {
		zenPage.CheckMissingDB();
	}
	
	
	zen('MembersForAsync').setHidden(false);
	zen('DBGroup').setHidden(false);
}

ClientMethod doConnect(mirrorName, canDisconnect) [ Language = javascript ]
{
	var isFailover = (mirrorName == '');
	if (isFailover) {
		mirrorName = zenPage.MirrorName;
		canDisconnect = zenPage.CanDisconnect;
	}
	
	var st = zenPage.ProcessConnect(mirrorName,canDisconnect);
	if (st != 1) {
		alert(st);
		return;
	} else {
		if (canDisconnect == false) {
			var text = $$$Text("Mirror has been started. It may take a few seconds to connect to primary member.");
		} else {
			var text = $$$Text("Mirror has been stopped. It may take a few seconds to finish.");
		}
		alert(text);
		if (isFailover || canDisconnect) {
			document.location.reload(true);
		} else {
			window.setTimeout(function() { zenPage.updateView(); }, 5000);
		}
	}
}

ClientMethod doDemote() [ Language = javascript ]
{
	// Demote failover to DR.
	var text = $$$Text("Are you sure you want to demote the other failover member to a DR member?");
	if (confirm(text)) {
		var st = zenPage.DemotePartner(zenPage.MirrorName);
		if (st == 1) {
			zenPage.RefreshFailoverInfo();
			zenPage.onloadHandler();
			zenPage.updateView(false,true);
			if (!this.IsEMSReadOnly) {
				document.getElementById("command_btnDemote").style.visibility = "hidden";
			}
			alert($$$Text("Demoting the other failover member to DR member succeeded."));
		} else {
			alert(st);	
		}
	}
}

ClientMethod doPromote() [ Language = javascript ]
{
	if (zenPage.IsDR == 1) {
		// Promote DR to failover member.
		// Firt, check if any warning messages need to be displayed.
		// Prompt user to confirm the request.
		var virtualinterface = "";
		var warnmsg = zenPage.CheckPromoteWarn(zenPage.MirrorName);
		if (!confirm(warnmsg + $$$Text("Are you sure you want to promote this system to a failover member?"))) {
			return;
		}
		var jrnon = zenPage.CheckJournaling();
		if (jrnon == 0) {
			//Journaling is not running, cannot promote
			alert($$$Text("Journaling must be started before this system can be promoted to a failover member."));
			return;
		}
		var vipact = zenPage.CheckVIP(zenPage.MirrorName);
		if (vipact != 0) {
			if (vipact == 1) {
				// VIP configured, but no interface available to support this VIP.
				var text = $$$Text("WARNING: There is no network interface could acquire virtual IP '%1'.\n It is likely because all network interfaces do not have matched subnet for '%2'.\n This promoted failover member won't acquire virtual IP when it becomes primary.\n Do you want to continue?");
				text = text.replace('%1',zenPage.VirtualIP);
				text = text.replace('%2',zenPage.VirtualIP);
				if (!confirm(text)) {
					return;
				}
				virtualinterface = "NoMatchedSubnet";
			} else if (vipact == 2) {
				// VIP configured, system has interface for the VIP, but mirror did configure interface yet.
				//var text = $$$Text("The configured virtual IP address is '%1'.\n You must configure a network interface for this IP.");
				//text = text.replace('%1',zenPage.VirtualIP);
				//alert(text);
			} else if (vipact == 3) {
				// VIP and interface configured, but the interface can't support this VIP.
				//var text = $$$Text("Current configured network interface is '%1'.\n It could not acquire virtual IP '%2'. So you must change it.");
				//text = text.replace('%1',zenPage.VirtualInterface);
				//text = text.replace('%2',zenPage.VirtualIP);
				virtualinterface = zenPage.VirtualInterface;
				//alert(text);
			} else if (vipact == 4) {
				// VIP and interface configured, the interface can support the VIP.
				//var text = $$$Text("Current configured network interface is '%1' for virtual IP '%2'.\n Do you want to change the network interface?");
				//text = text.replace('%1',zenPage.VirtualInterface);
				//text = text.replace('%2',zenPage.VirtualIP);
				//if (!confirm(text)) {
					// Set it to zero so we don't get pop up windows.
				//	vipact = 1;
				//} else {
					virtualinterface = zenPage.VirtualInterface;
				//}
			} else if (vipact == 5) {
				alert($$$Text("The 'arping' command is missing, you need to install iputils-arping package in order to inform routers outside sub-net that a new VIP is available."));
				return;
			}
			// Now we need to ask users to configure a network interface.
			// Popup Window to select network interface and promote.
			if (vipact != 1) {
				zenPage.doPromotePage(vipact,virtualinterface + '^' + zenPage.VirtualIP,"");
				return;
			}
		}
		// Now VIP configured, try to promote.
		var rc = zenPage.PromoteToFailoverMember(virtualinterface)
		if (rc == 1) {
			// Successfully become a failover member, need to refresh the screen.
			zenPage.IsDR = 0;
			zenPage.MirrorMemberType = 1;
			zenPage.RefreshFailoverInfo();
			zenPage.onloadHandler();
			zenPage.updateView(false,true);
			alert($$$Text("Promoting to failover member succeeded."));
			return;
		}
		if (rc == 2) {
			alert($$$Text("Promotion failed with error: ") + zenPage.PromoteErrorText);
			return;
		}
		// rc is 3 which means some failover member is down, we need to ask user to  select partner.
		zenPage.doPromotePage(0,"",zenPage.DownList);
		return;
	} else {
		// Demote failover to DR.
		var text = $$$Text("Are you sure you want to demote this system to a DR member?");
		if (confirm(text)) {
			var st = zenPage.DemoteToDR(zenPage.MirrorName);
			if (st == 1) {
				alert($$$Text("Demoting to DR member succeeded."));
				zenPage.IsDR = 1;
				zenPage.MirrorMemberType = 2;
				zenPage.SelectedMirror = zenPage.MirrorName;
				zenPage.doDetails(zenPage.MirrorName);
				zenPage.DrawAsyncInfo();
				if ((zenPage.CanConnect) || (zenPage.CanDisconnect)) {
					document.getElementById("command_btnConnect").style.visibility = "visible";
					if (zenPage.CanDisconnect) {
						document.getElementById("command_btnConnect").innerHTML = "<nobr>"+$$$Text("Stop Mirror On This Member")+"</nobr>";
						document.getElementById("command_btnConnect").title = $$$Text("Stop mirror in this async member.");
					} else {
						document.getElementById("command_btnConnect").title = $$$Text("Start mirror in this async member.");
					}
				}
				zenPage.NoFailoverBtn = 0;
				document.getElementById("command_btnNoFailover").style.visibility = "hidden";
				if (!this.IsEMSReadOnly) {
					document.getElementById("command_btnPromote").innerHTML = "<nobr>"+$$$Text("Promote To Failover Member")+"</nobr>";
					document.getElementById("command_btnPromote").title = $$$Text("Promote this DR member to a failover member.");
					document.getElementById("command_btnDemote").style.visibility = "hidden";
				}
			} else {
				alert(st);	
			}
		}
	}
}

ClientMethod doPromotePage(vipact, InterfaceSeed, DownList) [ Language = javascript ]
{
	var url = '%CSP.UI.Portal.Dialog.MirrorPromote.zen?InterfaceSeed=' + encodeURIComponent(InterfaceSeed) + '&DownList=' + encodeURIComponent(DownList) + '&VIPAct=' + encodeURIComponent(vipact);
	zenLaunchPopupWindow(url,'Promote','resizable,width=500,height=600');
}

ClientMethod CheckMissingDB() [ Language = javascript ]
{
	var table = zen("MissingDBTable");
	table.executeQuery();
	var total = table.getProperty("rowCount");
	if (total > 0) {
		zen("MissingMirroredDB").setHidden(false);
	} else {
		zen("MissingMirroredDB").setHidden(true);
	}
}

ClientMethod doNoFailover() [ Language = javascript ]
{
	var text;
	if (zenPage.DefinedPrimary == '') {
		text = $$$Text("Setting 'no failover' will prevent %1 member from becoming a primary member when the primary is down.\n");
		if (this.IsPrimary != 1) {
			text = text.replace('%1',$$$Text("this"));
		} else {
			text = text.replace('%1',$$$Text("the other"));
		}
		text = text + $$$Text("Are you sure you want to set 'no failover'?");
	} else {
		if (this.IsNoPartnerNoFailover != 1) {
			text = $$$Text("Clearing the 'no failover' will allow %1 member to become primary when the primary is down.\n");
			if (zenPage.MyMemberName == zenPage.DefinedPrimary) {
				text = text.replace('%1',$$$Text("the other"));
			} else {
				text = text.replace('%1',$$$Text("this"));
			}
		} else {
			var rc = zenPage.MultipleFailover(zenPage.MirrorName)
			if (rc == 1) {
				text = $$$Text("Clearing 'no failover' will allow either failover member to become primary. If you want this member to be the first to become primary, ensure that the other member is shut down before proceeding.\n");
			} else {
				text = $$$Text("Clearing 'no failover' will allow this member to become primary.\n");
			}
		}
		text = text + $$$Text("Are you sure you want to clear 'no failover'?");
	}
	if (confirm(text)) {
		var sc = zenPage.ChangeNoFailover(zenPage.MirrorName);
		if (sc.charAt(0) == '1') {
			text = $$$Text("The other failover member '%1' is unreachable. ");
			text = text.replace('%1',sc.substring(1));
		    text = text + $$$Text("We can't clear 'no failover' on the other failover member. ");
		    text = text + $$$Text("If you choose to clear 'no failover' on this failover member, ");
		    text = text + $$$Text("then this member will try to become primary and the other member ");
		    text = text + $$$Text("will clear its 'no failover' when it is restarted and contacts this member.\n");
		    text = text + $$$Text("Do you want clear 'no failover' on this failover member?");
		    if (confirm(text)) {
			    sc = zenPage.ClearNoFailover(zenPage.MirrorName);
		    } else {
			    sc = "";
		    }
		}
		if (sc != "") {
			alert(sc);
		}
		zenPage.DrawNoFailoverInfo();
		if (zenPage.NoFailoverBtn) {
			document.getElementById("command_btnNoFailover").style.visibility = "visible";
			if (zenPage.DefinedPrimary == '') {
				document.getElementById("command_btnNoFailover").innerHTML = "<nobr>"+$$$Text("Set No Failover")+"</nobr>";
				document.getElementById("command_btnNoFailover").title = $$$Text("Set 'no failover' in the mirror.");
			} else {
				document.getElementById("command_btnNoFailover").innerHTML = "<nobr>"+$$$Text("Clear No Failover")+"</nobr>";
				document.getElementById("command_btnNoFailover").title = $$$Text("Clear 'no failover' in the mirror.");
			}
		} else {
			document.getElementById("command_btnNoFailover").style.visibility = "hidden";
		}
	}
}

Method DrawConnectLink(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Set mirName = %query("Name")
	Set espName = $zconvert($zconvert(mirName,"O","JS"),"O","HTML")
	If ##class(SYS.Mirror).IsMirrorStarted(mirName) {
		Set cmdDisconnect = $$$TextHTML("Stop Mirror On This Member")
		&html<<a href="#" onclick="zenPage.doConnect('#(espName)#',1);return false;" style="text-align:center;white-space:nowrap;">#(cmdDisconnect)#</a>>
	} Else {
		Set cmdConnect = $$$TextHTML("Start Mirror On This Member")
		&html<<a href="#" onclick="zenPage.doConnect('#(espName)#',0);return false;" style="text-align:center;white-space:nowrap;">#(cmdConnect)#</a>>
	}
	Quit $$$OK
}

Method DrawMirrorStatus(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If %query("CatchupRunning") {
		Write $$$TextHTML("Catchup Running")
	} ElseIf %query("Mounted") {
		Write $zconvert(%query(pName),"O","HTML")
	} Else {
		Write $$$TextHTML("Database Dismounted")
	}
	Quit $$$OK
}

ClassMethod ProcessConnect(mirrorName As %String, canDisconnect As %Boolean) As %String [ ZenMethod ]
{
	If canDisconnect {
		Set tSC = ##class(SYS.Mirror).StopMirror(mirrorName)
	} Else {
		Set tSC = ##class(SYS.Mirror).StartMirror(mirrorName)
		// We need to hang a bit so we could get correct IsMirrorStarted() value.
		H 3
	}

	If $$$ISERR(tSC) Quit ..EscapeHTML($System.Status.GetErrorText(tSC))
	
	Quit $$$OK
}

ClassMethod ActivateDB(Dir As %String) As %String [ ZenMethod ]
{
	If '$SYSTEM.Security.Check($$$AdminManageResourceName,$$$PermUseName) {
		Quit $$$Text("Activate database required %Admin_Manage:USE privilege.")
	}
 	#; This method returns 1 = success; 0,errormsg = fail
 	Set tSC = $SYSTEM.Mirror.DBActivate(Dir)
 	If tSC {
	 	If ##class(Config.MirrorMember).IsReadWriteReportingMember() {
		 	Do $SYSTEM.Mirror.ClearFailoverDBFlag(Dir)
	 	}
		#;SML2678+ Get the mirror DB name.
		s dbobj=##Class(SYS.Database).%OpenId(Dir,,.Status)
		s mirdbname=$s($$$ISERR(Status):"",1:dbobj.MirrorDBName)
		d ##Class(%SYS.Audit).WriteToAuditFile($$$SourceSystem,$$$TypeSystem,$$$NameConfigChange,Dir,"Activate mirrored database "_mirdbname)
		#;SML2678-
	 	Quit $$$OK
 	}
 	Quit $P(tSC,",",2)
}

ClassMethod CatchupDB(Dir As %String, ActReq As %Boolean) As %String [ ZenMethod ]
{
 	Set tParms("Action") = $CASE(ActReq,1:"AC",:"C")
 	Set tItems(1) = Dir
 	Set tSC = ##class(%CSP.UI.System.BackgroundTask).RunTask("MirrorActivateCatchupDB",$namespace,.tParms,.tItems,.tJob)
 	If $$$ISERR(tSC) Quit $ZCVT($System.Status.GetErrorText(tSC),"O","JS")
 	Quit $$$OK
}

ClassMethod DownloadDB(Dir As %String, MirrorSetName As %String, MirrorDBName As %String) As %String [ ZenMethod ]
{
 	Set tParms("MirrorSetName") = MirrorSetName
 	Set tParms("MirrorDBName") = MirrorDBName
 	Set tItems(1) = Dir
 	Set tSC = ##class(%CSP.UI.System.BackgroundTask).RunTask("MirrorDownloadDB",$namespace,.tParms,.tItems,.tJob)
 	If $$$ISERR(tSC) Quit $ZCVT($System.Status.GetErrorText(tSC),"O","JS")
 	Quit $$$OK
}

ClassMethod RemoveDB(Dir As %String) As %String [ ZenMethod ]
{
 	Set tSC = ##class(SYS.Mirror).RemoveMirroredDatabase(Dir)
 	If $$$ISERR(tSC) Quit $ZCVT($System.Status.GetErrorText(tSC),"O","JS")
 	Quit $$$OK
}

Method CheckVIP(mirname) As %Integer [ ZenMethod ]
{
 	#; Check what we need to do with the VIP.
 	#; Return 0 - No VIP configured.
 	#;        1 - VIP configured, but no interface available to support this VIP.
 	#;        2 - VIP configured, system has interface for the VIP, but mirror did configure interface yet.
 	#;        3 - VIP and interface configured, but the interface can't support this VIP.
 	#;        4 - VIP and interface configured, the interface can support the VIP.
 	#;        5 - 'arping' command is missing, an't promote until it is installed.
	s cls=##class(Config.Mirrors).Open(mirname)
	s vip=cls.VirtualAddress,cls="",virtualinterface=""
	if vip="" Quit 0
	#;SML2743
	if '$SYSTEM.INetInfo.CheckArpingInstalled() Quit 5
	s ..VirtualIP = vip
	s MemberObj=##class(Config.MirrorMember).Open()
	s virtualinterface=MemberObj.VirtualAddressInterface
	s MemberObj=""
	Set tList = ##class(%SYSTEM.INetInfo).GetListOfConfiguredInterfaces(1,vip)
	if tList="" Quit 1
 	if virtualinterface=""||(virtualinterface=$$$NoMatchedSubnet) Quit 2
 	s ..VirtualInterface = virtualinterface
	if $$$ISOK(##class(SYS.MirrorConfiguration).ValidateVirtualAddress(vip,0,virtualinterface)) Quit 4
	Quit 3
}

Method CheckJournaling() As %Integer [ ZenMethod ]
{
	quit +$ZU(78,22)  ; 1 if journaling is enabled, 0 if not
}

ClassMethod CheckPromoteWarn(mirname) As %String [ ZenMethod ]
{
	Set msg=""
	if $zu(156,11) {
		s msg=$$$Text("There are locks of mirrored databases in this system. Promoting the system to failover member will remove these locks and owners of these locks will get <LOCKLOST> error.")
		s msg=msg_$c(13)_$c(13)
	}
	s nfailover=0
 	Set rs=##class(%ResultSet).%New("Config.MapMirrors:List")
 	s rc=rs.Execute(mirname)
 	if rc {
 	   While (rs.Next()) {
	      if rs.Data("MemberType")=$$$FailoverMemberType s nfailover=nfailover+1
 	   }
    }
 	s rs=""
 	if nfailover=2 {
	 	s msg=msg_$$$Text("There are two failover members configured, promoting this system will demote the backup member to DR async member.")
		s msg=msg_$c(13)_$c(13)
 	}
 	Quit msg
}

Method PromoteToFailoverMember(virtualinterface) As %Integer [ ZenMethod ]
{
	s DownList="",..DownList=""
	s rc=##class(SYS.MirrorConfiguration).PromoteToFailoverMember("",.DownList,"",0,virtualinterface)
	s ..DownList = DownList
	if $$$ISOK(rc) Quit 1
	if DownList="" {
		S ..PromoteErrorText=$SYSTEM.Status.GetErrorText(rc)
		Quit 2
	}
	Quit 3
}

Method DemotePartner(MirrorName) As %String [ ZenMethod ]
{
 	#; This method returns 1 = success; 0,errormsg = fail
 	Set tSC = ##class(SYS.Mirror).DemotePartner()
 	If $$$ISOK(tSC) {
	 	Quit $$$OK
 	}
 	Quit $SYSTEM.Status.GetErrorText(tSC)
}

Method DemoteToDR(MirrorName) As %String [ ZenMethod ]
{
 	#; This method returns 1 = success; 0,errormsg = fail
 	Set tSC = ##class(SYS.MirrorConfiguration).DemoteToAsyncMember("")
 	If $$$ISOK(tSC) {
		Set ..%GetComponentById("Text1").value = $$$Text("This system is an Async member")
		Set ..%GetComponentById("FailoverInfoGroup").hidden = 1
		Set ..%GetComponentById("MembersForFailover").hidden = 1
		Set ..%GetComponentById("AsyncMemberTable").queryClass = "SYS.Mirror"
		Set ..%GetComponentById("AsyncMemberTable").queryName = "MemberStatusList"
		Set ..%GetComponentById("AsyncInfoGroup").hidden = 0
		If ##class(SYS.Mirror).IsMirrorStarted(..MirrorName) {
			// system is connected
			Set ..CanDisconnect = 1
			Set ..CanConnect = 0
		} Else {
			// system is disconnected
			Set ..CanConnect = 1
			Set ..CanDisconnect = 0
		}
	 	Quit $$$OK
 	}
 	Quit $SYSTEM.Status.GetErrorText(tSC)
}

Method RefreshFailoverInfo() As %Status [ ZenMethod ]
{
	Set ..%GetComponentById("FailoverInfoGroup").hidden = 0
	Set ..%GetComponentById("MembersForFailover").hidden = 0
	Set ..%GetComponentById("AsyncInfoGroup").hidden = 1
	Set ..%GetComponentById("MembersForAsync").hidden = 1
	Set ..%GetComponentById("Text1").value = $$$FormatText($$$Text("This system is a failover member in mirror %1"),..MirrorName)
	Set tSC = ..DrawFailoverInfo(1)
	If $$$ISERR(tSC) {
		Set ..%GetComponentById("errmsg").value = $System.Status.GetErrorText(tSC)
		Set ..%GetComponentById("errmsg").hidden = 0
		Set ..%GetComponentById("fld").hidden = 1
		Quit 0
	}
	
	If ..IsPrimary = 1 {
		// system is the primary failover member
	} ElseIf $SYSTEM.Mirror.IsBackup() = 1 {
		// system is the secondary failover member
		Set ..CanDisconnect = 1
		Set ..%GetComponentById("FailoverJournalRate").hidden = 0
	} Else {
		If ##class(SYS.Mirror).IsMirrorStarted(..MirrorName) {
			// system is connected
			Set ..CanDisconnect = 1
		} Else {
			// system is disconnected
			Set ..CanConnect = 1
			Set ..CanDisconnect = 0
		}
	}
	Set ..%GetComponentById("FailoverMemberTable").queryClass = "%CSP.UI.System.Mirror"
	Set ..%GetComponentById("FailoverMemberTable").queryName = "MemberStatusList"
	Quit $$$OK
}

Method DrawFailoverInfo(RefreshCompress) As %Status [ ZenMethod ]
{
	Set tSC = ##class(SYS.Mirror).GetFailoverMemberStatus(.thisSys,.thatSys)
	If $$$ISERR(tSC) {
		Quit tSC
	}
	s NumFO = 0
	If $G(thisSys) '= "" {
		Set ..%GetComponentById("ThisMemberName").value = $LG(thisSys,1)
		Set ..%GetComponentById("ThisMemberECP").value = $P($LG(thisSys,6),"|",1)
		Set ..%GetComponentById("ThisMemberPrivateAddress").value = $P($LG(thisSys,5),"|",1)
		s NumFO=NumFO+1
	}
	If $G(thatSys) '= "" {
		Set ..%GetComponentById("OtherMemberName").value = $LG(thatSys,1)
		Set ..%GetComponentById("OtherMemberECP").value = $P($LG(thatSys,6),"|",1)
		Set ..%GetComponentById("OtherMemberPrivateAddress").value = $P($LG(thatSys,5),"|",1)
		s NumFO=NumFO+1
	} 
	#;SML2856 ; Check if we allow to demote other failover member.
	s ..DemoteOther = (NumFO > 1) && ($SYSTEM.Mirror.IsPrimary() || ('$SYSTEM.Mirror.IsBackup() && '..OtherIsPrimary(..MirrorName)))

	Set mir = ##class(Config.Mirrors).Open(..MirrorName)
	Set arbiteraddr = $P(mir.ArbiterNode,"^",1)
	If arbiteraddr = "" {
		Set ..%GetComponentById("ArbiterNode").value = $$$Text("Arbiter not configured")
	} Else {
		Set ..%GetComponentById("ArbiterNode").value = arbiteraddr
	}

	Set mode = $SYSTEM.Mirror.FailoverRule()
	If mode = $$$ArbiterControlledMirrorFailover {
		Set modeString = $$$Text("Arbiter Controlled")
	} ElseIf mode = $$$AgentControlledMirrorFailover {
		Set modeString = $$$Text("Agent Controlled")
	} Else {
		Set modeString = $$$Text("User Controlled")
	}
	Set ..%GetComponentById("FailoverMode").value = modeString
	
	Set state = $SYSTEM.Mirror.ArbiterState()
	Set thisConnected = $SELECT($ZB(+state,+$$$ArbiterConnected,1)'=0:1,1:0)
	Set otherConnected = $SELECT($ZB(+state,+$$$ArbiterPeerConnected,1)'=0:1,1:0)
	
	If 'thisConnected {
		Set stateString = $$$Text("This member is not connected to the arbiter")
	} ElseIf 'otherConnected {
		Set stateString = $$$Text("Only this member is connected to the arbiter")
	} Else {
		Set stateString = $$$Text("Both failover members are connected to the arbiter")
	}
	Set ..%GetComponentById("ConnectionStatus").value = stateString
	If ..IsPrimary = 1 {
		// system is the primary failover member
		Set ..%GetComponentById("FailoverJournalRate").hidden = 1
	} Else {
		// system is the secondary failover member
		Set ..%GetComponentById("FailoverJournalRate").hidden = 0
	}
	If RefreshCompress do ..GetCompressRate(..MirrorName,0)
	if mir.VirtualAddress'="" {
		Set ..%GetComponentById("VirtualAddressGroup").hidden = 0
		Set ..%GetComponentById("VIPAddress").value = $p(mir.VirtualAddress,"/")
		Set ..%GetComponentById("VIPMask").value = $p(mir.VirtualAddress,"/",2)
		Set x=##class(Config.MirrorMember).Open()
		if $IsObject(x) {
			Set ..%GetComponentById("VIPInterface").value = x.VirtualAddressInterface
		}
	} else {
		Set ..%GetComponentById("VirtualAddressGroup").hidden = 1
	}
	
	s rc=..DrawNoFailoverInfo()
	Quit $$$OK
}

Method DrawAsyncInfo() As %Status [ ZenMethod ]
{
	Set mir = ##class(Config.MirrorMember).Open()
	Set ..%GetComponentById("MemberName").value = mir.SystemName
	
	Set memberType = mir.AsyncMemberType
	Set ..%GetComponentById("MemberType").value = $CASE(memberType,0:$$$Text("Disaster Recovery (DR)"),1:$$$Text("Read-Only Reporting"),2:$$$Text("Read-Write Reporting"),:$$$Text("Unknown"))
	Set ..IsDR = (memberType = 0)
	
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Do ..%GetNavTableState(..%GetPageName()_"^dbTable")
		
	If ..MirrorMemberType = 0 {
		// Not a mirror member
		Set ..%GetComponentById("errmsg").value = $$$Text("This system is not a mirror member.")
		Set ..%GetComponentById("errmsg").hidden = 0
		Set ..%GetComponentById("fld").hidden = 1
		Quit $$$OK
	}
	Set ..NumberOfMirrorSet = ##class(Config.Mirrors).NumberOfMirrorSet()
	If ..MirrorMemberType = 2 {
		// Async member
		Set ..%GetComponentById("Text1").value = $$$Text("This system is an Async member")
		Set ..%GetComponentById("FailoverInfoGroup").hidden = 1
		Set ..%GetComponentById("MembersForFailover").hidden = 1
		Set ..%GetComponentById("AsyncMemberTable").queryClass = "SYS.Mirror"
		Set ..%GetComponentById("AsyncMemberTable").queryName = "MemberStatusList"
		Set ..%GetComponentById("AsyncInfoGroup").hidden = 0
		Set ..%GetComponentById("DBGroup").hidden = 1
		If ..NumberOfMirrorSet>1 {
			Set ..%GetComponentById("AsyncMirrorTable").queryClass = "SYS.Mirror"
			Set ..%GetComponentById("AsyncMirrorTable").queryName = "MirrorTrackedByAsyncMember"
			Set ..%GetComponentById("AsyncMirrorTableGroup").hidden = 0
		} else {
			Set ..SelectedMirror = ##class(Config.Mirrors).GetMirrorName()
			Set ..MirrorName = ..SelectedMirror
			If ##class(SYS.Mirror).IsMirrorStarted(..MirrorName) {
				// system is connected
				Set ..CanDisconnect = 1
				Set ..CanConnect = 0
			} Else {
				// system is disconnected
				Set ..CanConnect = 1
				Set ..CanDisconnect = 0
			}
		}
		
		
		Set tSC = ..DrawAsyncInfo()
		If $$$ISERR(tSC) {
			Set ..%GetComponentById("errmsg").value = $System.Status.GetErrorText(tSC)
			Set ..%GetComponentById("errmsg").hidden = 0
			Set ..%GetComponentById("fld").hidden = 1
			Quit $$$OK
		}
	} Else {
		// Failover member
		Set mir = ##class(Config.MirrorMember).Open()
		Set ValidatedMember = mir.ValidatedMember
		Set ..MyMemberName = mir.SystemName
		Set ..MirrorName = ##class(Config.Mirrors).GetMirrorName()
		If ..MirrorName = "" {
			Set ..%GetComponentById("errmsg").value = $System.Status.GetErrorText($$$ERROR($$$MirrorSetNameNotDefined))
			Set ..%GetComponentById("errmsg").hidden = 0
			Set ..%GetComponentById("fld").hidden = 1
			Quit 0
		}
		#;SML2755 ; Setup SelectedMirror so the DB list query can get the mirrored daatabses only for the mirror set.
		Set ..SelectedMirror = ..MirrorName
		Set ..%GetComponentById("Text1").value = $$$FormatText($$$Text("This system is a failover member in mirror %1"),..MirrorName)
		
		Set tSC = ..DrawFailoverInfo(1)
		If $$$ISERR(tSC) {
			Set ..%GetComponentById("errmsg").value = $System.Status.GetErrorText(tSC)
			Set ..%GetComponentById("errmsg").hidden = 0
			Set ..%GetComponentById("fld").hidden = 1
			Quit 0
		}
		
		If ..IsPrimary = 1 {
			// system is the primary failover member
		} ElseIf $SYSTEM.Mirror.IsBackup() = 1 {
			// system is the secondary failover member
			Set ..CanDisconnect = 1
			Set ..%GetComponentById("FailoverJournalRate").hidden = 0
		} Else {
			If ##class(SYS.Mirror).IsMirrorStarted(..MirrorName) {
				// system is connected
				Set ..CanDisconnect = 1
			} Else {
				// system is disconnected
				Set ..CanConnect = 1
				Set ..CanDisconnect = 0
			}
			If 'ValidatedMember {
				// system is not set up on the primary
				Set ..IsNotSetUp = 1
				Set ..%GetComponentById("MembersForFailover").hidden = 1
				Set ..%GetComponentById("DBGroup").hidden = 1
				Set ..%GetComponentById("Text1").value = $$$FormatText($$$Text("This system is configured as a failover member in mirror %1 but it needs to be added on the first failover member."),..MirrorName)
			}
			
		}
		If '..IsNotSetUp {
			Set ..%GetComponentById("FailoverMemberTable").queryClass = "%CSP.UI.System.Mirror"
			Set ..%GetComponentById("FailoverMemberTable").queryName = "MemberStatusList"
		}
	}
		
	$$$SetRefreshTimer
	Quit $$$OK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_NAMESPACE)))
	Quit $$$OK
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()
	
	// commands: $LB(id,caption,help,onclick,hidden)
	If %page.failedCnt = 0 {
		Set pCommands(1) = $LB("btnJournal",$$$Text("View Mirror Journal Files"),$$$Text("View Mirror Journal Files."),"zenPage.doJournal();",1)
		Set pCommands(2) = $LB("btnConnect",$$$Text("Start Mirror On This Member"),$$$Text("Start mirror in this backup member."),"zenPage.doConnect('','');",1)
		Set pCommands(3) = $LB("btnNoFailover",$$$Text("Set No Failover"),$$$Text("Set 'no failover' for the mirror."),"zenPage.doNoFailover();",1)
		If '..IsEMSReadOnly Set pCommands(4) = $LB("btnPromote",$$$Text("Promote To Failover Member"),$$$Text("Promote this DR member to a failover member."),"zenPage.doPromote();",1)
		If '..IsEMSReadOnly Set pCommands(5) = $LB("btnDemote",$$$Text("Demote Other Member"),$$$Text("Demote the other failover member to a DR member."),"zenPage.doDemote();",1)
	}

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Mirror Monitor")
}

/// Add to the contents of the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Do ..DrawAutoRefresh(..%GetPageName())
	Quit $$$OK
}

/// Overriden to add tabId and tableId to the page name to distinguish the type for the page.
ClientMethod navPageSizeChanged(value, tableId) [ Language = javascript ]
{
	this.TablePageSize = value;
	this.UpdateTableNavState(this.Filter,value,this.TableMaxRows,tableId);
}

/// Overriden to add tabId and tableId to the page name to distinguish the type for the page.
ClientMethod navMaxRowsChanged(value, tableId) [ Language = javascript ]
{
	this.TableMaxRows = value;
	this.UpdateTableNavState(this.Filter,this.TablePageSize,value,tableId);
}

/// Used to Save tableNavBar values, add MapType to the page name to distinguish the type for the page.
ClassMethod UpdateTableNavState(pFilter As %String, pPageSize As %Integer, pMaxRows As %Integer, ptableId As %String) [ ZenMethod ]
{
	Set $$$IRISTempMgt($Username,..%GetPageName()_"^"_ptableId,"TableNavState") = $lb(pFilter,pPageSize,pMaxRows)
}

Method GetCompressRate(mirrorName As %String, Async As %Integer) As %Status [ ZenMethod ]
{
	If ..IsPrimary = 1 Quit $$$OK
	If Async,mirrorName'=..SelectedMirror Set ..ReceivedData="0,0,0"
	Set prev=..ReceivedData
	Set IntervalText=$$$Text("Interval Rate is "),AverageText=$$$Text("Average Rate is ")
	Set miridx = $SYSTEM.Mirror.MirrorNameToIndex(mirrorName,0)
	if miridx>=0 {
		Set curtime=$ZH
		#;SML2201+ ; Use function 7 to get the info.
		Set cur=$SYSTEM.Mirror.GetInfo(7,miridx)
		Set recv=+$p(cur,",",1),recvcmp=+$p(cur,",",2)
		#;SML2201-
		If +prev>recv Set $p(prev,",",1)=0
		If +$p(prev,",")=0 {
			Set Text=$$$Text("--- (will be displayed on refresh)")
		} else {
			Set timediff=curtime-$p(prev,",",3),intervaltext=$$$Text(" (")_(timediff\1)_$$$Text("s interval)")
			Set journalbyte=recv-prev
			Set datatext=$J(journalbyte/1024/timediff,0,2)_$$$Text(" KB/s")
			if recvcmp=0 {
				Set Text=datatext
			} else {
				Set cmpbyte=recvcmp-$p(prev,",",2)
				Set Text=$J(cmpbyte/1024/timediff,0,2)_$$$Text(" KB/s network; ")_datatext_$$$Text(" journal; compression ratio ")_$J($s(cmpbyte=0:0,1:journalbyte/cmpbyte),0,2)_$$$Text(":1")
			}
			Set Text=Text_intervaltext
		}
		s ..ReceivedData=recv_","_recvcmp_","_curtime
	} else {
		Set Text=$$$Text("Can't find mirror set name ")_mirrorName
	}
	if Async {
		Set ..%GetComponentById("AsyncJournalRate").hidden = 0
		Set ..%GetComponentById("AsyncJournalRate").value = Text
	} else {
		Set ..%GetComponentById("FailoverJournalRate").value = Text
	}
	Quit $$$OK
}

Method DrawNoFailoverInfo() As %Status [ ZenMethod ]
{
	s mirname = ..MirrorName
	s cls=##class(Config.Mirrors).Open(mirname)
	s primary=cls.DefinedPrimary
	s ..DefinedPrimary=primary
	Set ..%GetComponentById("NoFailoverState").hidden = 1
	s ..NoFailoverBtn = 1
	if primary="" {
		if $SYSTEM.Mirror.IsPrimary() {
			#; This system is the primary.
			s name=$LG($G(^SYS("MIRRORSET",mirname,"Member",0)))
			#; 'name' should never be null here.
			if name="" goto bad
		} else {
			s systemcnt=$G(^SYS("MIRRORSET",mirname,"Member"),0)
			if 'systemcnt goto bad
			s info=$G(^SYS("MIRRORSET",mirname,"Member",1))
			s name=$lg(info,1)
			if info=""||(name="") goto bad
			s rc=$$GetStatus^MIRRORCTL(mirname,$$$MemberInfo(1,info))
			s status=$LG(rc)  
			if status'="PRIMARY" goto bad
		}
		Set ..NewDefinedPrimary = name
	} else {
		Set ..%GetComponentById("NoFailoverState").hidden = 0
		if $e(primary)=":" {
			Set ..IsNoPartnerNoFailover = 1
			Set ..%GetComponentById("NoFailoverState").value = $$$Text("The mirror is set to 'no failover'.")
		} else {
			Set ..IsNoPartnerNoFailover = 0
			Set ..%GetComponentById("NoFailoverState").value = $$$Text("The mirror is set to 'no failover' with ")_primary_$$$Text(" defined as primary.")
		}
	}
	
	Quit $$$OK
bad Set ..NoFailoverBtn = 0
	Quit $$$OK
}

Method ClearNoFailover(mirname As %String) As %String [ ZenMethod ]
{
	s cls=##class(Config.Mirrors).Open(mirname)
	s cls.DefinedPrimary = ""
	s rc=cls.%Save()
    if $$$ISERR(rc) Quit $$$Text("Failed to save cleared DefinedPrimary value, rc = ")_$System.Status.GetErrorText(rc)
	d post^MIRRORCOMM(mirname,0,0,"CLRDEFPRIMARY:")
    quit $$$Text("The 'no failover' is cleared on this failover member.")
}

Method ChangeNoFailover(mirname As %String) As %String [ ZenMethod ]
{
	s cls=##class(Config.Mirrors).Open(mirname)
	s primary=cls.DefinedPrimary
	if primary'=..DefinedPrimary goto bad
	if primary="" {
		if $SYSTEM.Mirror.IsPrimary() {
			#; This system is the primary.
			s name=$LG($G(^SYS("MIRRORSET",mirname,"Member",0)))
			#; 'name' should never be null here.
			if name="" goto bad
		} else {
			s systemcnt=$G(^SYS("MIRRORSET",mirname,"Member"),0)
			if 'systemcnt goto bad
			s info=$G(^SYS("MIRRORSET",mirname,"Member",1))
			s name=$lg(info,1)
			if info=""||(name="") goto bad
			s rc=$$GetStatus^MIRRORCTL(mirname,$$$MemberInfo(1,info))
			s status=$LG(rc)  
			if status'="PRIMARY" goto bad
		}
		if (..NewDefinedPrimary '= name) goto bad
	    s rc=$$SetMirrorNoFailover^MIRRORCTL(name)
	    if $LG(rc)'="OK" quit $$$Text("Failed to set 'no failover', error: ")_$lg(rc,2)
	} else {
	    s rc=$$ClearMirrorNoFailover^MIRRORCTL("")
	    #;SML2585 ; Return something special '1'+FailoverMemberName to indicate the unreachable failver.
	    if $LG(rc)="TIMEOUT" quit 1_$LG($G(^SYS("MIRRORSET",mirname,"Member",1)))
	    if $LG(rc)'="OK" quit $$$Text("Failed to clear 'no failover', error: ")_$lg(rc,2)
	}
	Quit ""
bad
	Quit $$$Text("The 'no failover' has been changed before your action, nothing is changed by you.")
}

ClassMethod MultipleFailover(mirname As %String) As %Integer [ ZenMethod ]
{
	Quit $s($G(^SYS("MIRRORSET",mirname,"Member"),0)>0:1,1:0)
}

Method GetValidationInfo(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Set pObject = ##class(%ZEN.proxyObject).%New()
	Try {
		Set pObject = $$$NULLOREF
		Set tSC = ##class(%CSP.UI.Portal.Mirror.Utils).ValidateMirror(.pObject)
		If $$$ISERR(tSC) {
			Quit	
		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod OtherIsPrimary(mirname As %String) As %Integer [ ZenMethod ]
{
	s rc=$$GetStatus^MIRRORCTL(mirname,1,1)
	Quit $LG(rc)="PRIMARY"
}

}
