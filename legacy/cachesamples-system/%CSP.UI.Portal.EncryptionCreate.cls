/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Create Encryption Key and Key File. 
Class %CSP.UI.Portal.EncryptionCreate Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Create New Encryption Key File";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.EncryptionCreate.zen";

Parameter HELPADDRESS = "System Administration,Encryption,Create New Encryption Key";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

Property LocatorHeader As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Create Encryption Key File")} ];

Property msgPassword As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("The two Passwords are not the same. Please type them again.")} ];

XData Style
{
<style type="text/css">
table.WarningTable	{ 
	font-size: 0.9em;
	border: gray solid 1px; 
}
/* override the image because this form is too tall */
.EditForm {
	background-image: url('');
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld" autocomplete="false">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<hgroup id="id_Key" labelPosition="left" label="Key File" cellVAlign="top" >
<text id="txtKeyFile" size="80" hint="Required. Enter a new file name." onchange="zenPage.doModified();"/>
<button id="btnBrowse" caption="Browse..." onclick="zenPage.browseSelect('txtKeyFile','*');"/>
</hgroup>
<text id="txtAdmName" label="Administrator Name" size="60" maxlength="50" hint="Required." onchange="zenPage.doModified();"/>
<text inputtype="password" id="Password1" label="Password" hint="Required." onchange="zenPage.doModified();"/>
<text inputtype="password" id="Password2" label="Confirm Password" hint="Required." onchange="zenPage.doModified();"/>
<select id="selCipher" label="Cipher Security Level" hint="Required." valueList="16,24,32" displayList="128-bit,192-bit,256-bit" showEmpty="false" originalValue="16" onchange="zenPage.doModified();"/> 
<textarea id="txtDescription" label="Key Description" cols="60" rows="5"/>
<html id="htmlNote" OnDrawContent="DrawNote" enclosingStyle="max-width:800px;"/>
<html id="idWarning" OnDrawContent="DrawWarning" hidden="false"/>
</group>
</form>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..%GetComponentById("Text1").value = $$$Text("Fill out the following form to create a new encryption key and key file:")
	Set ..%GetComponentById("txtAdmName").value = $Username

	Quit $$$OK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Encryption")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen"_$S(NAMESPACE="":"",1:"?$NAMESPACE="_$ZCVT(NAMESPACE,"O","URL"))))
	Quit $$$OK
}

/// User clicked one of the Browse buttons.
/// Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	var Dir = zen('txtKeyFile').getValue();
	var url = zenLink('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard);
	zenLaunchPopupWindow(url,'FileSelect','resizable,width=680,height=750');
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen("txtKeyFile").focus();
}

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var pass = true;
	var showMessage = true;
	try {
		if (!this.validateRequired(zen('txtKeyFile'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('txtAdmName'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('Password1'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('Password2'),pass,"S")) pass = false;
		
		var ctl = zen('Password2');
		if (zen('Password1').getValue() != ctl.getValue()) {
			ctl.setProperty("hintClass","redText");
			ctl.setProperty("controlClass","zenInvalid");
			if (pass) {
				this.showMsg(this.msgPassword,1);
				showMessage = false;
				zen('Password2').focus();
			}
			pass = false;
		} else {
			ctl.setProperty("hintClass","helpText");
			ctl.setProperty("controlClass","");
		}

		if (!pass && showMessage) {
			this.afterValidate();
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;
	
	return pass;
}

/// Get user selection and send to server to save settings.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		zenPage.resetMsg();
		var ok = zenPage.validate();
		if (!ok) return;
		
		var proxy = new zenProxy();
		proxy.KeyFile = zen("txtKeyFile").getValue();
		proxy.Username = zen("txtAdmName").getValue();
		proxy.Password = zen("Password1").getValue();
		proxy.KeyLength = zen("selCipher").getValue();
		proxy.Version = "2.0";
		proxy.Description = zen("txtDescription").getValue();
		var result = this.SaveData(proxy);
		if (result.ok == 1) {
			zen("htmlNote").setProperty("seed",result.keyID);
			zen("idWarning").setProperty("seed",zen("txtKeyFile").getValue());
			zen("idWarning").setHidden(false);
			zen("txtKeyFile").setDisabled(true);
			zen("id_Key").setProperty("labelClass","disablednormal");
			zen("btnBrowse").setDisabled(true);
			zen("txtAdmName").setDisabled(true);
			zen("Password1").setDisabled(true);
			zen("Password2").setDisabled(true);
			zen("selCipher").setDisabled(true);
			zen("txtDescription").setDisabled(true);		
			zenPage.disableCommandButton("btnSave");
			this.setModified(false);
		} else {
			zenPage.showMsg(result.ErrorMessage,1);
		}
	} catch(ex) {
		alert("ERROR: " + ex);
	}
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			zen('txtKeyFile').setValue(value);
			this.doModified();
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Save general data to server
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set keyID = $$Create^EncryptionKey(pProxy.KeyFile,pProxy.Username,pProxy.Password,pProxy.KeyLength,.tSC,pProxy.Version,pProxy.Description)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.keyID = keyID
		Set %session.Data("EncryptionKeyFile") = pProxy.KeyFile
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	
	Quit tProxy
}

Method DrawNote(pSeed As %String) As %Status
{
	&html<<table class="WarningTable"><td style="font-weight:bold;font-size:0.9em;">>
	If pSeed = "" {
		&html<#($$$Text("NOTE:"))#</td></tr>
		<tr><td>
		#($$$Text("The new database encryption key you are about to create will be unique.  It will not be usable with any existing encrypted databases or related files."))#
		<b>#($$$Text("If all key files containing this new key are lost, all data encrypted with this key will be permanently inaccessible."))#</b>
		#($$$Text(" You should be prepared to make a backup copy after the new key file is created."))#>
	} Else {
		Set keyID = $$$FormatText($$$Text("New encryption key ID: %1"),pSeed)
		&html<#($zconvert(keyID,"O","HTML"))#>
	}
	&html<</td></tr></table>>
	Quit 1
}

Method DrawWarning(pSeed As %String) As %Status
{
	If pSeed = "" Quit 1
	Set RemoteFileName = pSeed
	Set helpAddAdm = $$$Text("Click here to go to the page where you can add administrators for this key file.")
	&html<<table width="600" class="WarningTable"><tr>
	<td class="rednote">#($$$Text("WARNING:"))#</td><tr>
	<tr><td>
	#($$$Text("The new encryption key that you have just created is unique."))#
	<b>#($$$Text("If all key files containing this new key are lost, all data encrypted with this key will be permanently inaccessible."))#</b>
	<p><b>#($$$Text("It is strongly recommended that you do the following:"))#</b></p>
	<ul>
	<li class="smpLink"><a href='#(..Link("%25CSP.UI.Portal.EncryptionManage.zen",,1))#RemoteFileName=#(..EscapeURL(RemoteFileName))#&OK=Save' title="#(helpAddAdm)#" class="link" style="font-size:0.9em;">#($$$Text("Add an emergency recovery administrator to this key file."))#</a></li>
	<li>#($$$Text("Make a backup copy of the key file on a removable device such as a USB drive or CD."))#</li>
	<li>#($$$Text("Store the backup copy along with a written record of the emergency recovery password in a secure location."))#</li>
	</li></ul>
	</td></tr>
	<tr><td>#($$$Text("This key has not been activated. You can do that separately for database and/or managed key encryption."))#
	</td></tr></table>>
	Quit 1
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
