/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Actions for Mirrored Databases: Mount, Activate, Catchup, Remove.
Class %CSP.UI.Portal.Dialog.MirrorDBActions Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/op/%CSP.UI.Portal.Dialog.MirrorDBActions.zen";

/// Displayed name of this page.
Parameter PAGENAME = "Actions for Mirrored DB";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

/// Security requirement
Parameter RESOURCE = "%Admin_Operate";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property SelectedMirror As %ZEN.Datatype.string(ZENURL = "SelectedMirror");

/// "M" - Mount, "A" - Activate, "C" - Catchup, "R" - Remove
Property Action As %ZEN.Datatype.string(ZENURL = "Action");

Property IsPrimary As %Integer [ InitialExpression = {$SYSTEM.Mirror.IsPrimary()} ];

/// Number of DBs currently selected
Property NumDBs As %Integer [ InitialExpression = 0 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.link {
	font-size: 0.8em;
	color: #3B84BC;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />

<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnAction" controlClass="commandButtonDisabled" onclick="zenPage.doAction();" disabled="true"/>
<spacer width="5px"/>
<button id="btnCancel" controlClass="commandButton" caption="Cancel" title="Return to the Mirror Monitor" onclick="zenPage.dialogCancel();" />
<button id="btnFinish" controlClass="commandButton" caption="Close" title="Return to the Mirror Monitor" onclick="zenPage.dialogFinish();" hidden="true"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="10"/>
<group id="page1">
<label id="result" controlClass="redText" value="" containerStyle="padding-left:5px;"/>
<label id="msg1"/>
<label id="msg2"/>
<spacer height="5px"/>
<tablePane
id="table"
cellSpacing="2"
queryClass="%CSP.UI.System.Mirror"
queryName="MirroredDatabaseList"
dataSource="columns"
maxRows="1000"
multiSelect="true"
showZebra="true"
valueColumn="Directory"
onmultiselect="zenPage.rowSelect(zenThis.selectedRows);"
>
<parameter value="#(%page.SelectedMirror)#"/>
<parameter value="*"/>
<parameter value="#(%page.Action)#"/>
<column colName="Name" header="Name"/>
<column colName="Directory" header="Directory"/>
<column colName="MirrorStatus" header="Mirror Status" OnDrawCell="DrawMirrorStatus"/>
<column colName="Mounted" hidden="true"/>
<column colName="InActiveMirror" hidden="true"/>
<column colName="ActivationRequired" hidden="true"/>
<column colName="CatchupRunning" hidden="true"/>
<column colName="NeedCatchup" hidden="true"/>
</tablePane>
<spacer height="10px"/>
<checkbox id="chkReadOnly" caption="Mount read only" captionClass="zenLabel" value="0" hidden="true"/>
<checkbox id="chkCatchup" caption="Start mirror catchup" captionClass="zenLabel" value="1" hidden="true" onchange="zenPage.catchupChanged(zenThis.getValue());"/>
<checkbox id="chkBackground" caption="Perform action in the background" captionClass="zenLabel" title="Recommended if selecting multiple databases."/>
</group>
<group id="page2" hidden="true">
<label id="resultText"/>
<link id="taskLink" caption="Click here to view the background tasks page." href="/csp/sys/%25CSP.UI.Portal.BackgroundTaskList.zen" target="_new" hidden="true"/>
</group>
</pane>
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	// this is only invoked from the "Close" button, after actions are done
	// so, just return true to close the dialog.
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return ""
}

ClientMethod catchupChanged(newVal) [ Language = javascript ]
{
	var backgroundCheck = zen('chkBackground');
	if (newVal) {
		backgroundCheck.setValue(true);
		backgroundCheck.setDisabled(true);
	} else {
		if (this.NumDBs >= 5) {
			backgroundCheck.setValue(true);
			backgroundCheck.setDisabled(true);
		} else {
			backgroundCheck.setDisabled(false);
		}
	}
}

/// enable the action button if there are DBs selected. disable otherwise.
ClientMethod rowSelect(selectedRows) [ Language = javascript ]
{
	var dbArray = selectedRows.split(',');
	var button = zen('btnAction');
	this.NumDBs = 0;
	for (var i = 0; i < dbArray.length; i++) {
		if (dbArray[i] != '') {
			this.NumDBs++;
		}
	}
	if ((this.Action == 'M') || (this.Action == 'R')) {
		if (zen('chkCatchup').getValue()) {
			zen('chkBackground').setValue(true);
			zen('chkBackground').setDisabled(true);
		} else {
			if (this.NumDBs >= 5) {
				zen('chkBackground').setValue(true);
				zen('chkBackground').setDisabled(true);
			} else {
				zen('chkBackground').setDisabled(false);
			}
		}
	}
	if (this.NumDBs > 0) {
		button.setProperty('disabled',0);
		button.setProperty('controlClass','commandButton');
	} else {
		button.setProperty('disabled',1);
		button.setProperty('controlClass','commandButtonDisabled');
	}
}

ClientMethod doAction() As %Boolean [ Language = javascript ]
{
	zen('result').setValue('');
	var text = "";
	if (this.NumDBs < 1) {
		text = $$$Text('Please select at least one database');
		alert(text);
		return;
	}
	
	if (zenPage.Action == 'R') {
	text = $$$Text("Access to databases being removed may result in <PROTECT> error, while this action takes place.  Once a mirrored database is removed, it is no longer a valid copy; this is irreversible.")+"\n";
		if (this.IsPrimary == 1) {
			text += $$$Text("If this database is added back to the mirror later, using the same mirror database name, other copies will need to be replaced with this version of the database.");
		} else {
			text += $$$Text("If you decide to restore this database later, you will need to get a copy from one of the other mirror members.");
		}
		text += "\n\n"+$$$Text("Are you sure you want to remove selected databases from the mirror?");
		if (!confirm(text)) return;
	}
	
	var proxy = new zenProxy();
	proxy.Action = this.Action;
	proxy.DBDirs = zen('table').selectedRows;
	proxy.ReadOnly = zen('chkReadOnly').getValue();
	proxy.Catchup = zen('chkCatchup').getValue();
	proxy.Background = zen('chkBackground').getValue();
	var result = this.ReallyDoAction(proxy);
	if (result.status != 1) {
		zen('result').setValue(result.status);
		return;
	}
	
	zen('page1').setHidden(true);
	zen('page2').setHidden(false);
	zen('btnCancel').setHidden(true);
	zen('btnFinish').setHidden(false);
	var button = zen('btnAction');
	button.setProperty('disabled',1);
	button.setProperty('controlClass','commandButtonDisabled');
	
	if (!proxy.Background) {
		zen('resultText').setValue(result.resultText);
	} else {
		zen('resultText').setValue($$$Text("This task will be run in the background."));
		zen('taskLink').setHidden(false);
	}
}

ClassMethod ReallyDoAction(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.status = $$$OK
	Set tProxy.resultText = ""
	
	Try {
		Set count = 0
		For i=1:1:$Length(pProxy.DBDirs,",") {
			Set Dir = $Piece(pProxy.DBDirs,",",i)
			If (Dir = "") Continue
			Set tItems($i(tItems)) = Dir
			Set count = count + 1
		}
		
		If (pProxy.Background = 1) {
			If (pProxy.Action = "R") {
				Set tProxy.status = ##class(%CSP.UI.System.BackgroundTask).RunTask("MirrorRemoveDB",$namespace,.tParms,.tItems,.tJob)
			} ElseIf (pProxy.Action = "M") {
				Set tParms("ReadOnly") = pProxy.ReadOnly
				Set tParms("Catchup") = pProxy.Catchup
				Set tProxy.status = ##class(%CSP.UI.System.BackgroundTask).RunTask("MirrorMountDB",$namespace,.tParms,.tItems,.tJob)
			} Else {
				// If "Catchup", actually send in "Activate & Catchup" so all bases are covered
				Set tParms("Action") = $Case(pProxy.Action,"A":"A",:"AC")
				Set tProxy.status = ##class(%CSP.UI.System.BackgroundTask).RunTask("MirrorActivateCatchupDB",$namespace,.tParms,.tItems,.tJob)
			}
		} Else {
			For i=1:1:count {
				Set Dir = tItems(i)
				If (pProxy.Action = "R") {
					Set tSC = ##class(SYS.MirrorConfiguration).RemoveDatabaseFromMirror(Dir)
				} Else {
					Set tSC = ##class(SYS.Database).MountDatabase(Dir,pProxy.ReadOnly,,pProxy.Catchup)
				}
				Set tProxy.resultText = tProxy.resultText_"<br/>"_..EscapeHTML(Dir)_"..."
				If $$$ISOK(tSC) {
					If (pProxy.Action = "R") {
						Set tProxy.resultText = tProxy.resultText_$$$TextHTML("removed from mirror successfully")
					} Else {
						Set tProxy.resultText = tProxy.resultText_$$$TextHTML("mounted successfully")
					}
				} Else {
					Set tProxy.resultText = tProxy.resultText_..EscapeHTML($System.Status.GetErrorText(tSC))
				}
			}
		}
	} Catch exp {
		Set tSC = exp.AsStatus()
		Set tProxy.status = ..EscapeHTML($System.Status.GetErrorText(tSC))
	}
	Quit tProxy
}

ClassMethod DrawMirrorStatus(pTable As %ZEN.Component.tablePane, pName As %String, pSeed As %String) As %Status
{
	If %query("CatchupRunning") {
		Write $$$TextHTML("Catchup Running")
	} ElseIf %query("Mounted") {
		Write $zcvt(%query(pName),"O","HTML")
	} Else {
		Write $$$TextHTML("Database Dismounted")
	}
	Quit $$$OK
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set msgText = ..%GetComponentById("msg1")
	Set ActionButton = ..%GetComponentById("btnAction")
	Set backgroundCheck = ..%GetComponentById("chkBackground")
	If (..Action = "M") {
		Set msgText.label = $$$Text("Select the database(s) you wish to mount:")
		Set ActionButton.caption = $$$Text("Mount")
		Set ActionButton.title = $$$Text("Mount selected databases")
		Set ..%GetComponentById("chkReadOnly").hidden = 0
		Set ..%GetComponentById("chkCatchup").hidden = 0
		Set backgroundCheck.value = 1
		Set backgroundCheck.disabled = 1
	} ElseIf (..Action = "A") {
		Set msgText.label = $$$Text("Select the database(s) you wish to activate:")
		Set ActionButton.caption = $$$Text("Activate")
		Set ActionButton.title = $$$Text("Activate selected databases")
		Set backgroundCheck.value = 1
		Set backgroundCheck.disabled = 1
	} ElseIf (..Action = "C") {
		Set msgText.label = $$$Text("Select the database(s) you wish to catchup:")
		Set ..%GetComponentById("msg2").label = $$$Text("If a selected database is inactive, it will be activated and then caught up.")
		Set ActionButton.caption = $$$Text("Catchup")
		Set ActionButton.title = $$$Text("Catchup selected databases")
		Set backgroundCheck.value = 1
		Set backgroundCheck.disabled = 1
	} ElseIf (..Action = "R") {
		Set msgText.label = $$$Text("Select the database(s) you wish to remove:")
		Set ActionButton.caption = $$$Text("Remove")
		Set ActionButton.title = $$$Text("Remove selected databases from the mirror")
	}
	
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Set title = $CASE(..Action,"M":$$$Text("Mount Mirrored Databases"),"A":$$$Text("Activate Mirrored Databases"),"C":$$$Text("Catchup Mirrored Databases"),"R":$$$Text("Remove Mirrored Databases"),:$$$Text("Actions for Mirrored DB"))
	Quit title
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen('btnCancel').focus();
}

}
