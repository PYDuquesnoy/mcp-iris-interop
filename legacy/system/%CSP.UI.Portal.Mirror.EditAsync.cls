/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Zen page for System Management Portal - Edit Async
Class %CSP.UI.Portal.Mirror.EditAsync Extends (%CSP.UI.Portal.Template, %CSP.UI.Portal.Mirror.Utils) [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Displayed name of this page.
Parameter PAGENAME = "Edit Async Configurations";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mirror.EditAsync.zen";

Parameter HELPADDRESS = "Home,Configuration,Edit Mirror";

Property MirrorName As %String;

Property MemberName As %String;

Property OldMemberType As %Integer;

Property OldPurgeSetting As %Boolean;

Property NoFilter As %Boolean;

/// Keep track of the number of databases whose FailoverDB flags we could clear
Property NumFlagSetDBs As %Integer;

/// Store translated targetCol linkCaption for <condition>
Property colAuthorize As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Authorize Pending DN Updates")} ];

/// Check if user has manage privilege
Property CanManage As %ZEN.Datatype.boolean [ InitialExpression = {$System.Security.Check("%Admin_Manage","USE")} ];

Property lblText2 As %String;

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
	border-bottom: 1px solid #F1F0E7;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<jsonProvider id="jsonValidationInfo" OnGetTargetObject="GetValidationInfo">
 </jsonProvider>
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<label id="pendingmsg" hidden="true" enclosingClass="ErrorBox"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group id="AsyncEdit" enclosingClass="EditForm" cellStyle="padding:4px;">
<fieldSet label="Mirror Member Information" valign="top" containerStyle="padding:4px;" cellStyle="padding:3px;" labelPosition="left">
<label id="Text2" value="" containerStyle="padding-bottom:4px;"/>
<label id="MemberName" label="Mirror Member Name" controlClass="normal"/>
<group id="groupAsync">
<select id="MemberType" label="Async Member System Type" valueList="0,1,2" displayList="Disaster Recovery (DR),Read-Only Reporting,Read-Write Reporting" value="0" showEmpty="false" onchange="zenPage.updateType(zenThis.getValue());"/>
<group id="ClearFailoverDBGroup" hidden="true" labelPosition="left" hint="If selected, all mirrored databases will be made read/write.">
<select id="ClearFailoverDB" label="Clear FailoverDB Flag for All Mirrored Databases?" valueList="0,1" displayList="No,Yes" value="0" showEmpty="false" onchange="zenPage.doModified();"/>
</group>
<select id="JournalUseSystemSetting" hidden="true" label="Mirror Journal File Retention" valueList="0,1" displayList="Purge files when no longer needed,Purge files using local journal file purge criteria" showEmpty="false" onchange="zenPage.doModified();"/>
<hgroup label="SSL/TLS Configuration">
<link id="linkSSL" onclick="zenPage.openSSL();return false;" href="#" enclosingClass="smpLink"/>
<button id="verifySSL" caption="Verify SSL" onclick="zenPage.verifySSL(); return false;" />
</hgroup>
<label id="X509DN" label="X.509 Distinguished Name" controlClass="normal" hidden="true"/>
</group> 
<label id="Text3" value="#(%page.lblText2)#" containerStyle="padding-bottom:4px;"/>
<html>
<div id="failureMessage"></div>
</html>
</fieldSet>
</group>
<spacer height="20px"/>
<tablePane id="MirrorTable" cellSpacing="2"
queryClass="SYS.Mirror"
queryName="MirrorTrackedByAsyncMember"
label="Mirrors this async member belongs to"
labelStyle="display:block;padding-bottom:5px;"
enclosingStyle="width:70%;min-width:700px;"
dataSource="columns"
fixedHeaders="false"
maxRows="100"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="Name"
useSnapshot="false"
>
<column colName="Name" header="Name" link="#" onclick="zenPage.doEdit('#(%query.Name)#');return false;"/>
<column colName="AgentAddress" header="Agent Address"/>
<column colName="AgentPort" header="Agent Port"/>
<column colName="InstanceDirectory" header="Instance Directory"/>
<column colName="Filter" header="Dejournal Filter" hidden="#(%page.NoFilter)#"/>
<column colName="DNUpdates" hidden="true"/>
<column linkCaption="Leave Mirror" link="#" onclick="zenPage.doStopTracking('#(%query.Name)#');return false;"/>
<column linkCaption="Authorize Pending DN Updates" link="#" onclick="zenPage.doDNUpdates('#(%query.Name)#');return false;"/>
<column linkCaption="Edit Dejournal Filter" link="#" onclick="zenPage.EditDejrnFilter('#(%query.Name)#');return false;" hidden="#(%page.NoFilter)#"/>
<parameter value="*"/>
<condition colName="DNUpdates" predicate="EQ" value="0" cellStyle="disabled" targetCol="#(%page.colAuthorize)#"/>
</tablePane>
 <spacer height="20px"/>
 <tablePane id="DBTable" cellSpacing="2"
queryClass="Config.Databases"
queryName="MirrorDatabaseList"
label="Mirrored Databases"
labelStyle="display:block;padding-bottom:5px;"
enclosingStyle="width:70%;min-width:700px;"
dataSource="columns"
fixedHeaders="false"
maxRows="100"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="MirrorDBName"
useSnapshot="false"
>
<column colName="Mirror" header="Mirror"/>
<column colName="MirrorDBName" header="Database Name"/>
<column colName="Directory" header="Location"/>
<column colName="MirrorFailoverDB" header="FailoverDB Flag" OnDrawCell="DrawFailoverDB"/>
<column OnDrawCell="DrawClearLink"/>
<parameter value="*"/>
 </tablePane>
</form>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	// get validation info and save a local copy for later use
	var json = zen('jsonValidationInfo').getContentObject();
	this._validationInfo = json;
	var msg = '';
	if (json.error) {
		msg = json.error;
		// foundemental error occurred getting validation data, page cannot continue, so display error then go back home.
		alert(json.error);
		window.location.href = this.homePage;
		return;
	}
	if (json.failedCount > 0) {
		// validation failed. Now disable fields when needed.
		zen("groupAsync").setHidden(true);
		zen("MirrorTable").setHidden(true);
		zen("DBTable").setHidden(true);
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
	}
	else {
		zen("MemberType").focus();
		if (this.DisableSave) {
			this.disableCommandButton("btnSave");
			this.disableCommandButton("btnJoin");
			this.disableCommandButton("btnClear");
			this.disableCommandButton("btnRemove");
		}
		if (zen("MemberType").getValue() == 0) {
			this.disableCommandButton("btnJoin");
		}
		if (this.IsEMSReadOnly) {
			this.disableCommandButton("btnSave");
			this.disableCommandButton("btnJoin");
			this.disableCommandButton("btnClear");
			this.disableCommandButton("btnRemove");
		}
	}
}

/// If we are currently a DR member, keep track of whether we're changing to reporting
ClientMethod updateType(newVal) [ Language = javascript ]
{
	if (newVal == 0 && zenPage.OldMemberType != 0) {
		var rc = this.DRMemberValidation(this.MemberName);
		if (rc != "") {
			alert(rc);
			zen('MemberType').setValue(zenPage.OldMemberType)
			zen('ClearFailoverDBGroup').setHidden(true);
			zen('JournalUseSystemSetting').setHidden(false);
			return;
		}
		rc = this.CheckDejournalFilter(this.MemberName)
		if (rc !="") {
			if (!confirm(rc)) {
				zen('MemberType').setValue(zenPage.OldMemberType)
				zen('JournalUseSystemSetting').setHidden(false);
				return;
			}
		}
	}
	if (zenPage.OldMemberType != 2) {
		if (newVal == 2) {
			zen('ClearFailoverDBGroup').setHidden(false);
		} else {
			zen('ClearFailoverDBGroup').setHidden(true);
		}
	}
	if (newVal == 0) {
		zen('JournalUseSystemSetting').setHidden(true);
	} else {
		zen('JournalUseSystemSetting').setHidden(false);
	}
	this.doModified();
}

/// Overriding for DN redraw
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if ((popupName == "SSL") && (action == "ok")) {
			this.SSLDefined = 1;
			zen("linkSSL").setProperty("caption", $$$Text("Edit SSL/TLS"));
			zenPage.UpdateDN();
		}
		if ((popupName == "StopTracking") && (action == "ok")) {
			zen("MirrorTable").executeQuery();
		}
		if (popupName == "Edit") {
			// don't check for action because the user may have saved a network address and then clicked cancel
			zen("MirrorTable").executeQuery();
		}
		if (popupName == "EditFilter") {
			// don't check for action because the user may have saved a network address and then clicked cancel
			zen("MirrorTable").executeQuery();
		}
		if ((popupName == "Remove") && (action == "ok")) {
			zenPage.doCancel();
		}
		if ((popupName == "DNUpdates") && (action == "ok")) {
			zenPage.RefreshPendingMessage();
		}
		if (popupName == 'RemoveLocalConfig') {
			window.location.href = this.homePage;
		}
		if ((popupName == 'JoinNewMember') || (popupName == 'NodeAddressEdit')) {
			window.location.reload(true);
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClientMethod doEdit(mirrorName) [ Language = javascript ]
{
	// check if editing this node is allowed or not
	var editAllowed = true;
	if (this._validationInfo) {
		var json = this._validationInfo;
		if (json.failedCount > 0) {
			if (json.failures) {
				for (var i=0; i<json.failures.length; i++) {
					var data = json.failures[i];
					if (data.failureCode != "TIMEOUT" && data.mirrorName == mirrorName) {
						editAllowed = false;
						break;
					}
				}
			}
		}
	}
	if (editAllowed) {	
		var url = zenLink('%CSP.UI.Portal.Mirror.Dialog.AsyncEdit.zen?MirrorName='+encodeURIComponent(mirrorName)+'&MemberName='+encodeURIComponent(zenPage.MemberName));
		zenLaunchPopupWindow(url,'Edit','resizable,width=1000,height=600');
	} else {
		var msg = $$$FormatText($$$Text("Editing of '%1' under the current Mirror condition is not allowed."),mirrorName);
		alert(msg);	
	}
}

ClientMethod doStopTracking(mirrorName) [ Language = javascript ]
{
	if (this.IsEMSReadOnly) {
		return;
	}
	var url = zenLink('%CSP.UI.Portal.Mirror.Dialog.AsyncStopTracking.zen?MirrorName='+encodeURIComponent(mirrorName));
	zenLaunchPopupWindow(url,'StopTracking','resizable,width=1000,height=700');
}

ClientMethod doDNUpdates(mirrorName) [ Language = javascript ]
{
	if (!zenPage.AnyDNUpdates(mirrorName)) {
		var alertText = $$$Text('There is no pending DN updates.');
		alert(alertText);
		return;
	}
	var url = zenLink('%CSP.UI.Portal.Mirror.Dialog.DNUpdates.zen?MirrorName='+encodeURIComponent(mirrorName));
	zenLaunchPopupWindow(url,'DNUpdates','resizable,width=1000,height=700');
}

ClientMethod EditDejrnFilter(mirrorName) [ Language = javascript ]
{
	var url = zenLink('%CSP.UI.Portal.Mirror.Dialog.EditFilter.zen?MirrorName='+encodeURIComponent(mirrorName)+'&NodeName='+encodeURIComponent(zenPage.MemberName));
	zenLaunchPopupWindow(url,'EditFilter','resizable,width=1000,height=700');
}

ClientMethod doRemove() [ Language = javascript ]
{
	var url = zenLink('%CSP.UI.Portal.Mirror.Dialog.AsyncRemoveConfig.zen');
	zenLaunchPopupWindow(url,'Remove','resizable,width=1000,height=700');
}

ClientMethod doJoin() [ Language = javascript ]
{
	zenPage.gotoPage('%25CSP.UI.Portal.Mirror.JoinAsync.zen');
}

ClientMethod doClearFlag(dbName, dir) [ Language = javascript ]
{
	var confirmText = $$$Text('Clear FailoverDB flag for database %1?');
	confirmText = confirmText.replace(/%1/g,dbName);
	if (!confirm(confirmText)) {
		return;
	}
	
	var st = zenPage.ClearFailoverDBFlag(dir);
	if (st = 1) {
		zen('DBTable').executeQuery();
	} else {
		alert(st);
	}
}

ClientMethod doClearAll() [ Language = javascript ]
{
	var canClear = zenPage.CanClear();
	if (!canClear) {
		var alertText = $$$Text('Cannot clear the FailoverDB flag on a Disaster Recovery member');
		alert(alertText);
		return;
	}
	if (zenPage.NumFlagSetDBs == 0) {
		var alertText = $$$Text('There are no databases to clear');
		alert(alertText);
		return;
	}
	var confirmText = $$$Text('Clear FailoverDB flag for all mirrored databases?');
	if (!confirm(confirmText)) {
		return;
	}
	
	var st = zenPage.ClearFailoverDBFlagAll();
	if (st = 1) {
		zen('DBTable').executeQuery();
	} else {
		alert(st);
	}
}

ClientMethod doSave() [ Language = javascript ]
{
	var proxy = new zenProxy();
	
	proxy.MemberName = zen("MemberName").getValue();
	proxy.MemberType = zen("MemberType").getValue();
	proxy.JournalUseSystemSetting = zen("JournalUseSystemSetting").getValue();
	proxy.ClearFailoverDB = zen("ClearFailoverDB").getValue();
	
	proxy.OldPurgeSetting = zenPage.OldPurgeSetting;
	proxy.OldMemberType = zenPage.OldMemberType;
	
	var ok = this.validateSave(proxy);
	if (!ok) return;

	var result = this.SaveData(proxy);

	if (result.ok == 1) {
		var alertText = $$$Text("Changes saved.");
		if (result.Message != "") {
			alertText = alertText + "\n" + result.Message;
		}
		alert(alertText);
		location.reload(true);
	} else {
		this.showMsg(result.ErrorMessage);
	}
}

ClientMethod verifySSL() [ Language = javascript ]
{
	var proxy = zenPage.SSLverification(zenPage.MirrorName);
	if (proxy.ok == 1) {
		alert(proxy.message);
	} else {
		alert(proxy.error);
	}
}

ClientMethod validateSave(proxy) [ Language = javascript ]
{
	this.resetMsg('');
	zen("idRespond").setProperty("controlClass","redText");
	
	return true;
}

Method UpdateDN() As %Status [ ZenMethod ]
{
	Set tSC = ##class(SYS.MirrorConfiguration).DoSSLConfigurationsExist(.cn)
	If $$$ISOK(tSC) {
		Set ..%GetComponentById("X509DN").value = cn
		Set ..%GetComponentById("X509DN").hidden = 0
	}
	Quit tSC
}

Method UpdateDejrnFilter(mirname As %String, Filter As %String) As %Status [ ZenMethod ]
{
	s mm=##class(Config.MirrorMember).Open()
	s ourname=mm.SystemName
	s mm=##class(Config.MapMirrors).Open(mirname,ourname,,,.tSC)
	if '$IsObject(mm) Quit tSC
	s mm.DejournalFilter = Filter
	s tSC=mm.%Save()
	Quit tSC
}

ClassMethod CanClear() As %Boolean [ ZenMethod ]
{
	Quit ##class(Config.MirrorMember).AllowClearFailoverDBFlag()
}

ClassMethod ClearFailoverDBFlag(dir As %String) As %String [ ZenMethod ]
{
	Set tSC = ##class(SYS.Database).ClearMirrorFailoverDB(dir)
	If $$$ISERR(tSC) Set tSC = $ZCVT($System.Status.GetErrorText(tSC),"O","JS")
	Quit tSC
}

ClassMethod ClearFailoverDBFlagAll() As %String [ ZenMethod ]
{
	Set tSC = ##class(Config.MirrorMember).ClearFailoverDBForNonDRAsyncMember()
	If $$$ISERR(tSC) Set tSC = $ZCVT($System.Status.GetErrorText(tSC),"O","JS")
	Quit tSC
}

ClassMethod DRMemberValidation(SystemName) As %String [ ZenMethod ]
{
	Set rc=##class(SYS.MirrorConfiguration).DRMemberValidation(SystemName)
	If '$$$ISOK(rc) {
		Set errcode=+$SYSTEM.Status.GetErrorCodes(rc)
		if errcode=$$$ERRORCODE($$$NonFailoverDBIsNotAllowed) {
			Quit $$$Text("This member cannot become a DR async because the FailoverDB flag is cleared on at least one mirrored database. To make this member a DR async, first remove all such databases from the mirror on this member, then change the member type to DR async, and finally restore the databases from a backup made on a failover member to add them back to the mirror.")
		} elseif errcode=$$$ERRORCODE($$$TooManyMirrorOnDR) {
			Quit $$$Text("This member cannot become a DR async because this member has joined more than one mirror set.")
		} else {
			Quit $$$Text("This member cannot become a DR async for Unknown reason")
		}
	}
	Set rc=##class(SYS.Mirror).CheckISCAgent()
	If '$$$ISOK(rc) Quit $$$Text("This member cannot become a DR async because error on ISCAgent :")_$SYSTEM.Status.GetErrorText(rc)
	Quit ""
}

ClassMethod CheckDejournalFilter(SystemName) As %String [ ZenMethod ]
{
	Set mirname=##class(Config.Mirrors).GetMirrorName()
	Set mm=##class(Config.MapMirrors).Open(mirname,SystemName,,,.rc)
	#;SML2044+
	Set text=""
	If mm.DejournalFilter'="" {
		Set text=$$$FormatText($$$Text("The currently configured DejournalFilter '%1' will be removed after changing async member type from Reporing to DR. You need to reconfigure it if you decide to change it back to Reporting type later."),mm.DejournalFilter)
	}
	If +##class(%SYS.Journal.System).IsJournalEncryptionEnabled() {
		Set text=text_$c(13)_$$$Text("The journal encryption is currently enabled, DR member must have same encryption key as failover members have. Please make sure the encryption key matched with failover members' key otherwise the DR member will not be able to connect to primary.")
	}
	If text'="" Set text=text_$c(13)_$$$Text("Are you sure you want to change it to DR type?")
	#;SML2044-
	Quit text
}

Method DrawClearLink(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Set %page.NumFlagSetDBs = 0
	
	// Only fill the cell if the flag is set and we're not a DR member
	If (##class(Config.MirrorMember).AllowClearFailoverDBFlag() && (%query("MirrorFailoverDB") = 1)) {
		Set Obj = ##class(SYS.Database).%OpenId(%query("Directory"),,.tSC)
		If '$iso(Obj) Quit tSC
		#;SML2316 ;Allow changing DB when not connecting to primary.
		If Obj.MirrorNoWrite||Obj.MirrorActivationRequired {
			Set text = $$$TextHTML("Cannot Clear Flag")
			Set titleText = $$$TextHTML("The flag cannot be cleared because the database is not activated")
			&html<<span title="#(titleText)#">#(text)#</span>>
		} Else {
			Set %page.NumFlagSetDBs = %page.NumFlagSetDBs + 1
			Set dbName = $zconvert($zconvert(%query("MirrorDBName"),"O","JS"),"O","HTML")
			Set dir = $zconvert($zconvert(%query("Directory"),"O","JS"),"O","HTML")
			Set text = $$$TextHTML("Clear Flag")
			&html<<a onclick="zenPage.doClearFlag('#(dbName)#','#(dir)#');return false;" href="#">#(text)#</a>>
		}
	}
	Quit $$$OK
}

ClassMethod DrawFailoverDB(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	Write $SELECT(%query(pName):"Set",1:"Cleared")
	Quit $$$OK
}

///  Save general association data to server.<br/>
///  Returns proxy.ok = 1 (save successful) or 0 (error occurred)<br/>
///  proxy.ErrorMessage (save failed and display this error message).
///  If proxy.ok is 1 and no messages returned then we return to SMP home.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 1
	Set tProxy.Message = ""

	Try {
		Set mir = ##class(Config.MirrorMember).Open(,,.tSC)
		If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set mir.AsyncUseSystemPurgeInterval = pProxy.JournalUseSystemSetting
		Set mir.AsyncMemberType = pProxy.MemberType
		
		Set tSC = mir.%Save()
		If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		If (pProxy.OldMemberType '= pProxy.MemberType) {
			If (pProxy.ClearFailoverDB = 1) {
				#; We're changing from DR to reporting and want to clear failoverDB
				Set tSC = ##class(Config.MirrorMember).ClearFailoverDBForNonDRAsyncMember()
				If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
			If (pProxy.MemberType = 0) {
				#; We're changing from reporting to DR
				Set numDBs = ##class(SYS.MirrorConfiguration).GetListOfNonFailoverDB(.DBs)
				If (numDBs > 0) {
					If (numDBs > 1) {
						Set message1 = $$$FormatText($$$Text("There are %1 mirrored databases with theFailoverDB flag cleared."),numDBs)
						Set message2 = " "_$$$Text("You should remove or reset these databases before this DR member can be promoted to failover member.")
					} Else {
						Set message1 = $$$Text("There is 1 mirrored database with theFailoverDB flag cleared.")
						Set message2 = " "_$$$Text("You should remove or reset this database before this DR member can be promoted to failover member.")
					}
					Set tProxy.Message = message1_message2
				}
			}
		}

		If ((pProxy.OldPurgeSetting = 1) && (pProxy.JournalUseSystemSetting = 0)) {
			#;see if there are files we can clean up
			Do PURGE^JRNUTIL
		}
		
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

/// Set Locator bar and determine whether to show change password option.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..lblTitle = $$$Text("Use the form below to edit this async member's configuration")_":"
	Set %page.MirrorName = ##class(Config.Mirrors).GetMirrorName()
	Set mir = ##class(Config.MirrorMember).Open()
	if (mir.AsyncMemberGUID = "") {
		Set tSC = $$$ERROR($$$MirrorAsyncMemberNotConfigured)
	    Do ..DisplayError(tSC)
		Quit $$$OK
	}

	Set (..%GetComponentById("MemberName").value,%page.MemberName) = mir.SystemName
	Set (..%GetComponentById("MemberType").value,%page.OldMemberType) = mir.AsyncMemberType
	Set (..%GetComponentById("JournalUseSystemSetting").value,%page.OldPurgeSetting) = +(mir.AsyncUseSystemPurgeInterval)
	#;SML2065 ; Display the journal setting prompt for non-DR member.
	if mir.AsyncMemberType Set ..%GetComponentById("JournalUseSystemSetting").hidden = 0
	
	if %page.SSLDefined {
		Do ..UpdateDN()
	}
	
	#;SML1939
	Set %page.NoFilter = '$SYSTEM.Mirror.AsyncMemberType()
	
	Set tSC = ..GetSSLLink(.linkSSL, .labelSSL)
	If $$$ISERR(tSC) {
		Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	}
	Set %page.SSLLink = linkSSL
	Set ..%GetComponentById("linkSSL").caption = labelSSL

	If ..IsEMSReadOnly {
		Set idlist="MemberType,ClearFailoverDB,JournalUseSystemSetting,linkSSL"
		For id=1:1:$l(idlist,",") {
			Set ..%GetComponentById($p(idlist,",",id)).disabled = 1
		}
	}
	
	Do ..RefreshPendingMessage()
	Quit 1
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Edit Async Configurations")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()
	Set failedCnt = ##class(SYS.MirrorConfiguration).LookupLocalValidationFailures(.failure,0)

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnSave",$$$Text("Save"),$$$Text("Save changes to the mirror member information."),"zenPage.doSave();")
	Set pCommands(2) = $LB("btnCancel",$$$Text("Cancel"),$$$Text("Return without saving new changes"),"zenPage.doCancel();")
	If failedCnt = 0 {
		Set pCommands(3) = $LB("btnJoin",$$$Text("Join a Mirror"),$$$Text("Join an existing mirror as an async member."),"zenPage.doJoin();")
		Set pCommands(4) = $LB("btnRemove",$$$Text("Remove Mirror Configuration"),$$$Text("Remove all mirror configuration information from this instance."),"zenPage.doRemove();")
		Set pCommands(5) = $LB("btnClear",$$$Text("Clear FailoverDB Flags"),$$$Text("Clear the FailoverDB Flag on all mirrored databases."),"zenPage.doClearAll();")
	}
	Quit $$$OK
}

Method RefreshPendingMessage() As %Status [ ZenMethod ]
{
	Set mlist=""
	Set rs = ##class(%ResultSet).%New("SYS.Mirror:MirrorTrackedByAsyncMember")
	Do rs.Execute("*")
	while rs.Next() {
		Set mirname = rs.Data("Name")
		If ..AnyDNUpdates(mirname) {
			Set mlist = mlist_$s(mlist="":mirname,1:","_mirname)
		}
	}
	If mlist'="" {
		Set ..%GetComponentById("pendingmsg").value = $$$Text("There are pending DN updates in mirror set ")_mlist_$$$Text(". Please use 'Authorize Pending DN Updates' link in the mirror set(s) to update the SSL DN changes.")
		Set ..%GetComponentById("pendingmsg").hidden = 0
	} else {
		Set ..%GetComponentById("pendingmsg").hidden = 1
	}
	Quit $$$OK
}

/// Return server info per validation checks for failure. 
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

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
