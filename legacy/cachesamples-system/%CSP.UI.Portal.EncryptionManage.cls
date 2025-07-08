/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Manage Existing Encryption Key File. You may view existing adminstrators defined for a key file,
/// delete or add more administrators to an existing key file.
Class %CSP.UI.Portal.EncryptionManage Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Manage Encryption Key File";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.EncryptionManage.zen";

Parameter HELPADDRESS = "System Administration,Encryption,Manage Encryption Key File";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

/// This is the current key file name after user clicked the OK button.
Property CurrentKeyFile As %String;

/// This is the current key list from the current key file.
Property CurrentKeyList As %String;

Property LocatorHeader As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Manage Encryption Key File")} ];

Property lblDefined As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Administrators Defined in Key File %1")} ];

Property lblKeyTable As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Encryption Keys Defined in Key File %1")} ];

Property lblDelete As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to delete administrator %1 from %2?")} ];

Property lblDeleted As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Deleted administrator: ")} ];

XData Style
{
<style type="text/css">
table.DetailTable { 
	font-size: 12px;
	border: 1px #cbcbcb solid;
}
table.DetailTable th { 
	font-weight: bold;		
	background:white; 
	color: #888888;
	text-align: center;
	padding: 2px;
}
table.DetailTable td { 
	font-weight: normal;		
	padding: 2px;
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
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<hgroup id="id_Key" labelPosition="left" label="Key File" cellVAlign="top" >
<text id="txtKeyFile" size="60" maxlength="50" hint="Required."/>
<button id="btnBrowse" caption="Browse..." onclick="zenPage.browseSelect('txtKeyFile','*');"/>
</hgroup>
<button id="btnSave" caption="OK" onclick="zenPage.doOK();"/>
<html><hr size="1"/></html>
<vgroup>
<label id="idDefined"/>
<html id="htmlAdmin" OnDrawContent="DrawAdmin">
</html>
<label id="idKeyTable" containerStyle="padding-top:20px;"/>
<html id="htmlKeys" OnDrawContent="DrawKeys">
</html>
<label id="lblDeleted" controlClass="greennote" value=""/>
</vgroup>
</group>
</form>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..%GetComponentById("Text1").value = $$$Text("Manage existing encryption key file:")
	Set ..%GetComponentById("txtKeyFile").value = $G(%session.Data("EncryptionKeyFile"))
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
	var url = zenLink('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard)
	zenLaunchPopupWindow(url,'FileSelect','resizable,width=680,height=750');
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen("txtKeyFile").focus();
}

ClientMethod doAdd(what) [ Language = javascript ]
{
	try {
		var file = zen("txtKeyFile").getValue();
		var url = zenLink('%CSP.UI.Portal.Dialog.EncAddAdmin.zen?FILE='+encodeURIComponent(file)+'&WHAT='+what);
		zenLaunchPopupWindow(url,'AddAdmin','resizable,width=600,height=600');
	} 
  catch(ex) {
	alert("ERROR: " + ex);
	}
}

ClientMethod doDelete(deleteUser) [ Language = javascript ]
{
	try {
		var file = this.CurrentKeyFile;
		var confirmstring = this.lblDelete;
		confirmstring = confirmstring.replace(/%1/,deleteUser);
		confirmstring = confirmstring.replace(/%2/,file);
		var ok = confirm(confirmstring);
		if (!ok) return;
		var proxy = this.AdminRemove(file,deleteUser);
		if (proxy.ok != 1) {
			this.showMsg(proxy.ErrorMessage,1);
			return;
		}
		this.loadAdmin();
		if (zen("idRespond").getValue() == "") {
			zen("lblDeleted").setValue(this.lblDeleted + deleteUser);
		}
	} 
  catch(ex) {
	alert("ERROR: " + ex);
	}
}

ClientMethod doDeleteKey(deleteKey) [ Language = javascript ]
{
	try {
		var confirmstring = $$$Text("If this is the only key file containing this key, all data encrypted with this key will be permanently inaccessible.") + "\n\n" +
		$$$Text("Are you sure you want to delete key identifier %1?");
		confirmstring = confirmstring.replace(/%1/,deleteKey);
		var ok = confirm(confirmstring);
		if (!ok) return;
		var proxy = this.KeyRemove(this.CurrentKeyFile,deleteKey);
		if (proxy.ok != 1) {
			this.showMsg(proxy.ErrorMessage,1);
			return;
		}
		this.loadAdmin();
	} 
  catch(ex) {
	alert("ERROR: " + ex);
	}
}

/// Load key file.
ClientMethod doOK() [ Language = javascript ]
{
	try {
		var pass = true;
		if (!this.validateRequired(zen('txtKeyFile'),pass,"S")) pass = false;
		if (!pass) {
			this.afterValidate();
			return;
		}
		this.loadAdmin();
	} 
  catch(ex) {
	alert("ERROR: " + ex);
	}
}

/// Load or reload Key and Admin tables after user clicked OK for Key File, or after Add or Delete.
ClientMethod loadAdmin() [ Language = javascript ]
{
	zen("lblDeleted").setValue('');
	var txtFile = zen("txtKeyFile").getValue();
	var proxy = this.LoadFile(txtFile);
	if (proxy.ok == 1) {
		this.CurrentKeyFile = txtFile;
		this.CurrentKeyList = proxy.KeyList;		
		var label = this.lblDefined.replace("%1",txtFile);
		zen("idDefined").setValue(label);
		var label = this.lblKeyTable.replace("%1",txtFile);
		zen("idKeyTable").setValue(label);
		zen("htmlAdmin").setProperty("seed",proxy.AdmList);
		zen("htmlKeys").setProperty("seed",proxy.KeyList);
	} else {
		this.showMsg(proxy.ErrorMessage,1);
	}
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action != 'ok') return false;
		switch(popupName) {
		case 'FileSelect':
			zen('txtKeyFile').setValue(value);
			break;
		case 'AddAdmin':
			this.loadAdmin();
			break;
		}

	} catch (ex) {
		alert("Error: " + ex);	
	}
}

ClassMethod AdminRemove(KeyFile, Username) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = $$AdminRemove^EncryptionKey(KeyFile,Username)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

ClassMethod KeyRemove(KeyFile, KeyID) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = $$KeyRemove^EncryptionKey(KeyFile,KeyID)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

/// Load key file
ClassMethod LoadFile(KeyFile) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
#;Don't load the admins set into the file by unattended encryption
		Set AdminList = $$AdminList^EncryptionKey(KeyFile,.tSC,1)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
		Set tProxy.AdmList = AdminList
		Set KeyList = $$KeyList^EncryptionKey(KeyFile,.tSC)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.KeyList = KeyList
		Set %session.Data("EncryptionKeyFile") = KeyFile
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

Method DrawAdmin(pSeed As %String) As %Status
{
	If pSeed = "" Quit 1
	Set AdminList = pSeed
	Set lblDelete = $$$Text("Delete")
	Set total = $L(AdminList,",")
	&html<
	<table class="DetailTable" border="1" cellpadding="2" cellspacing="0" >>
	&html<<tr><th nowrap>#($$$Text("Count"))#</th><th nowrap>#($$$Text("Administrator"))#</th>>
	If total > 1 &html<<th>&nbsp;</th>>
	&html<</tr>>

	For i = 1:1:total {
		Set User = $P(AdminList,",",i)
		&html<<tr><td>#(i)#</td><td nowrap>#(User)#</td>>
		If total>1 &html<<td nowrap><input type="button" value="#(lblDelete)#" onclick="zenPage.doDelete('#(User)#')"></td>>
		&html<</tr>>
 	}
 	If total = 0 &html<<tr><td colspan="4" nowrap>#($$$Text("None defined."))#</td></tr>>
 	&html<<tr><td colspan="4" align="center"><input type="button" name="Add" value='#($$$Text("Add"))#' onclick="zenPage.doAdd('adm');"></td></tr>> 

	&html<</table>>
	Quit $$$OK
}

Method DrawKeys(pSeed As %String) As %Status
{
	If pSeed = "" Quit 1
	If '$d(%session.Data("EncryptionKeyFile")) Quit 1
	Set KeyList = pSeed
	Set lblDelete = $$$Text("Delete")
	Set total = $L(KeyList,",")
	Set KeyFile = %session.Data("EncryptionKeyFile")
	Set titleDelete = $$$Text("Delete this key from the Key File")
	&html<
	<table class="DetailTable" border="1" cellpadding="2" cellspacing="0" >>
	&html<<tr><th nowrap>#($$$Text("Count"))#</th><th nowrap>#($$$Text("Key Identifier"))#</th><th nowrap>#($$$Text("Bit length"))#</th><th nowrap>#($$$Text("Description"))#</th>>
	If total > 1 &html<<th>&nbsp;</th>>
	&html<</tr>>
	If KeyList'="" {
	For i = 1:1:total {
		Set Key = $P(KeyList,",",i)
		Set KeyLen=$$KeyLenGet^EncryptionKey(KeyFile,Key,.status)
		Set tDesc = $$KeyDescGet^EncryptionKey(KeyFile,Key,.status)
		If $$$ISERR(status) Set tDesc = $System.Status.GetErrorText(status)
		&html<<tr><td align="center">#(i)#</td><td nowrap>#(Key)#</td><td nowrap>#(KeyLen)#</td>>
 		If ((KeyFile="")||($$KeyfileVersion^EncryptionKey(KeyFile)>1.0)) {
			&html<<td>
			#($ZCVT(tDesc,"O","HTML"))#
			</td>>
			&html<<td nowrap>
			<input type="button" title="#(titleDelete)#" value="#(lblDelete)#" onclick="zenPage.doDeleteKey('#(Key)#')">
			</td>>
 		}
		&html<</tr>>
 	}
	}
 	If total = 0 &html<<tr><td colspan="5" nowrap>#($$$Text("None defined."))#</td></tr>>
 	If ((KeyFile="")||($$KeyfileVersion^EncryptionKey(KeyFile)>1.0)) {
 		&html<<tr><td colspan="5" align="center"><input type="button" name="Add" value='#($$$Text("Add"))#' onclick="zenPage.doAdd('key');"></td></tr>> 
 	}

	&html<</table>>
	Quit $$$OK
}

}
