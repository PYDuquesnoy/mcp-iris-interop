/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %syMirror

Class %CSP.UI.Portal.Mirror.Dialog.FailoverRemoveOthers Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Mirror.Dialog.FailoverRemoveOthers.zen";

/// Displayed name of this page.
Parameter PAGENAME = "RemoveOtherConfig";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsBackup As %Boolean [ InitialExpression = {$SYSTEM.Mirror.IsBackup()} ];

Property MirrorName As %ZEN.Datatype.string(ZENURL = "PID");

Property MirrorList As %ZEN.Datatype.list;

Property MemberName As %String;

Property AuthorizeText As %String;

Property MemberType As %Integer;

XData Style
{
<style language="text/css">
.radioSetCaption {
    color: black;
    text-decoration: none;
    font-size: 12px;
    cursor: pointer;
}
.radioSetCaption:hover {
    color: #DA4848;
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
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();"/>
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Remove" onclick="zenPage.dialogFinish();"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="10"/>
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<group id="fld" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding:3px;">
<html OnDrawContent="DrawMirrorList"/>
</group>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.InvalidParam) {
		this.showMsg('No other mirror members are configured.',true);
	} else {
		zen('btnFinish').setProperty('controlClass','commandButtonDisabled');
		zen('btnFinish').setProperty('onclick','return false;');
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.MemberType == 0) {
			var text = $$$Text("WARNING! Removing another failover member, the removed failover member won't be able to connects to primary when it is running.\nIf you want to let it re-join the mirror set, you will need to '") + this.AuthorizeText + $$$Text("' this failover member later.\nAre you sure you want to remove this failover member?")
			if (!confirm(text)) return false;
		}
		if (this.doSave()==false) return false;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

/// This callback, if defined, is called when the user presses the Cancel button.
/// If this returns false, then the dialog is not cancelled.
ClientMethod ondialogCancel() [ Language = javascript ]
{
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return true;
}

ClientMethod doChangeMember() [ Language = javascript ]
{
	var memberName = "";
	var radioSet = document.getElementsByName('mirrorRadio');
	for (var i=0; i<radioSet.length; i++) {
		 if (radioSet[i].checked) {
			 var str = radioSet[i].value;
			 memberName = str.substring(0,str.length-2);
			 memberType = str.substring(str.length-1);
			 break;
		 }
	}
	if (memberName) {
		this.MemberName = memberName;
		this.MemberType = memberType;
		zen('btnFinish').setProperty('controlClass','commandButton');
		zen('btnFinish').setProperty('onclick','zenPage.dialogFinish();');
	} else {
		zen('btnFinish').setProperty('controlClass','commandButtonDisabled');
		zen('btnFinish').setProperty('onclick','return false;');
	}
}

ClientMethod doSave() [ Language = javascript ]
{
	var proxy = new zenProxy();
	
	proxy.MirrorName = this.MirrorName;
	proxy.MemberName = this.MemberName;
	
	var result = this.SaveData(proxy);

	if (result.ok == 1) {
		return true;
	} else {
		this.showMsg(result.ErrorMessage);
		return false;
	}
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 1

	Try {
		Set tSC = ##class(Config.MapMirrors).Delete(pProxy.MirrorName,pProxy.MemberName)
		If $$$ISERR(tSC) Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
	} Catch Error {
		Set Message = ..EscapeHTML($System.Status.GetErrorText(Error.AsStatus()))
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = Message
	}
	Quit tProxy
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Remove Other Mirror Member")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

Method DrawMirrorList(pSeed As %String) As %Status
{
	If ..MirrorList = "" Quit $$$OK
	Set labelTxt = $$$TextHTML("Choose a mirror member to remove:")
	&html<<span class="zenLabel">#(labelTxt)#</span><br/>>
	For i=1:1:$LENGTH(..MirrorList,$C(5)) {
		Set mirror = $PIECE(..MirrorList,$C(5),i)
		Set name = $PIECE(mirror,"||",1)
		Set type = $PIECE(mirror,"||",2)
		Set namex = name_","_type
		Set typeDisplay = $case(type,0:$$$Text("Failover"),2:$$$Text("Async"))
		Set disabled = ""
		
		If ..IsBackup && (type=0) {
			Set disabled = "disabled"
		}
		
		&html<<input type="radio" name="mirrorRadio" id="#(name)#" value="#(namex)#" #(disabled)# onchange="zenPage.doChangeMember();"/>
		<label for="#(name)#" class="radioSetCaption">#(name)# (#(typeDisplay)#)</label>>
		If disabled'="" {
			Set disabledText = $$$Text("Backup member is not allowed to remove another failover member which could be primary now.")
			&html<<br/><span class="helpText" style="margin-left:25px;">#(disabledText)#</span>>
		}
		&html<<br/>>
	}
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set mm = ##class(Config.MirrorMember).Open()
	Set ourname = mm.SystemName

	Set rs = ##class(%ResultSet).%New("Config.MapMirrors:List")
	Set tSC = rs.Execute(..MirrorName)
	While (rs.Next()) {
		Set name = rs.Data("Name")
		If name = ourname continue
		Set type = rs.Data("MemberType")
		If ..MirrorList '= "" Set ..MirrorList = ..MirrorList_$C(5)
		Set ..MirrorList = ..MirrorList_name_"||"_type
	}
	
	If ..MirrorList = "" {
		Set ..InvalidParam = 1
	}
	s MirrorsObj=##class(Config.Mirrors).Open(..MirrorName)
	if $s($isobject(MirrorsObj)&&MirrorsObj.UseSSL:1,1:0) {
		s ..AuthorizeText = $$$Text("Authorize")
	} else {
		s ..AuthorizeText = $$$Text("Add")
	}

	Quit $$$OK
}

}
