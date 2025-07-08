/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Database Encryption Keys. Activate, Deactivate database encryption key and configure startup options.
Class %CSP.UI.Portal.EncryptionDatabase Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Database Encryption";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.EncryptionDatabase.zen";

Parameter HELPADDRESS = "System Administration,Encryption,Database Encryption";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property browseselect As %String;

Property LocatorHeader As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Database Encryption")} ];

Property PageURL As %ZEN.Datatype.string;

Property lblDeactivate As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to deactivate key %1?")} ];

/// Current activated default key.
Property DefaultKey As %String;

/// Current activated key for journals.
Property JournalKey As %String;

/// List of Current activated keys delimited by commas. 
Property KeyList As %String;

/// List of currently activated key lengths, comma delimited.
Property KeyLenList As %String;

/// Key File for Unattended.
Property KeyFileName As %String;

/// Wheter to allow multiple DB Encryption (restrict it in 2013.2 and allow for 2014.1+)
Property AllowMultiDB As %Boolean [ InitialExpression = 1 ];

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
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>
<spacer height="2"/>

<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>

<!-- Show activated keys -->
<html id="keyTable" OnDrawContent="DrawIDs"/>

<spacer height="4"/>
<group id="formContainer" cellStyle="padding:4px;">
<!-- The following form is for activating a key -->
<form id="form1" autocomplete="false" enclosingClass="EditForm" hidden="true" label="Fill out the following form to activate a database encryption key" 
cellStyle="padding:4px;" labelPosition="left">
<hgroup id="id_Key" labelPosition="left" label="Key File" cellVAlign="top" >
<text id="txtKeyFile" size="60" maxlength="50" hint="Required."/>
<button id="btnBrowse" caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('txtKeyFile','*');"/>
</hgroup>
<text id="txtAdmName" label="Administrator Name" size="60" maxlength="50" hint="Required."/>
<text inputtype="password" id="Password1" label="Password" hint="Required."/>
<html><hr size="1"/></html>
<hgroup>
	<button id="btnSave" caption="Activate" onclick="zenPage.doSave();"/>
	<spacer width="2"/>
	<button caption="Cancel" onclick="zenPage.doCancel();"/>
</hgroup>
</form>

<!-- The following form is for configuring Startup Settings -->
<form id="form2" autocomplete="false" enclosingClass="EditForm" hidden="true" cellStyle="padding:4px;">
<fieldSet label="Startup Options" labelPosition="left" cellStyle="padding:5px;">
<select id="selStartup" label="Key Activation at Startup" valueList="0,1,2" displayList="None,Interactive,Unattended (NOT RECOMMENDED)" 
showEmpty="false" value="0" onchange="zenPage.doOptions(zenThis.getValue());zenPage.doModified();"/>
<combobox id="selKMIP" label="KMIP Server" editable="false" unrestricted="true" size="19"
hidden="true" onchange="zenPage.doModified();"/>
<vgroup id="id_Options" labelPosition="left" hidden="true" cellStyle="padding-top:2px;">
<hgroup id="id_Key2" hidden="false" labelPosition="left" label="Key File" cellVAlign="top" >
<text id="txtKeyFile2" size="60" maxlength="50" hint="Required." onchange="zenPage.doFileChange();"/>
<button id="btnBrowse2" caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('txtKeyFile2','*');"/>
</hgroup>
<text id="txtAdmName2" label="Administrator Name" size="60" maxlength="50" hint="Required." onchange="zenPage.doModified();"/>
<text inputtype="password" id="Password2" label="Password" hint="Required." onchange="zenPage.doModified();"/>
</vgroup>
</fieldSet>
<fieldSet id="fldOption" hidden="true" label="Optionally Encrypted Data" labelPosition="left" cellStyle="padding:5px;">
<select id="selIRISTemp" label="Encrypt IRISTEMP and IRISLOCALDATA Databases" valueList="0,1" displayList="No,Yes" showEmpty="false" value="0"
hint="This will take effect upon next restart of the system." onchange="zenPage.doModified();"/>
<select id="selJournalFile" label="Encrypt Journal Files" valueList="0,1" displayList="No,Yes" showEmpty="false" value="0"
hint="This will take effect upon next restart of the system OR when the journal file is next switched." onchange="zenPage.doModified();"/>
<select id="selAuditEncrypt" label="Encrypt Audit Log" valueList="0,1" displayList="No,Yes" showEmpty="false" value="0"
hint="This will take effect immediately." onchange="zenPage.doModified();"/>
<html OnDrawContent="DrawWarning"/>
</fieldSet>
<hgroup>
	<button id="btnSave2" caption="Save" onclick="zenPage.doSaveStartup();"/>
	<spacer width="2"/>
	<button caption="Cancel" onclick="zenPage.doCancel();"/>
</hgroup>
</form>
</group>

</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..DefaultKey = $$$GetDBEncKeyID
#;	WDS504 - Get key to use for new encrypted journal files
	Set ..JournalKey = $System.Security.System.GetJrnEncKeyID(2)
	If ..DefaultKey = "" {
		Set ..%GetComponentById("Text1").value = $$$Text("No database encryption key is activated.")
	} Else {
		Set ..KeyList = $System.Security.System.GetDBEncKeyIDList()
		Set ..KeyLenList = $System.Security.System.GetDBEncKeyLenList()
		Set ..%GetComponentById("Text1").value = $S($L(..KeyList,",")>1:$$$Text("Activated database encryption keys:"),1:$$$Text("Activated database encryption key:"))
	}
	Set ..%GetComponentById("form2").label = $$$Text("Configure startup and other options for encrypted databases:")
	#; Set properly escaped page url to property so that refresh page can readily use it.
	Set ..PageURL = $ZCVT(..Link(..#CSPURL),"O","URL")	
	#; Load default values
	s valueList=""
	Set Rset = ##class(%ResultSet).%New("Security.KMIPServer:List")
 	i '$$$ISOK(Rset)
 	s Status=Rset.Execute()
 	i '$$$ISOK(Status)					
	While Rset.Next(.Status) {
		s valueList=valueList_Rset.Data("Name")_","
	}
	i valueList'="" {
		Set tCombo = ..%GetComponentById("selKMIP")
		Set tCombo.valueList = $e(valueList,1,*)
		Set ..%GetComponentById("selStartup").valueList="0,1,2,3" 
		Set ..%GetComponentById("selStartup").displayList="None,Interactive,Unattended (NOT RECOMMENDED),KMIP Server"
	}
	Set sys = ##class(Security.System).%OpenId("SYSTEM")
	Set ..%GetComponentById("selStartup").value = sys.DBEncStartMode
	Set ..%GetComponentById("selKMIP").value = sys.DBEncStartKMIPServer
	Set ..%GetComponentById("selIRISTemp").value = sys.DBEncIRISTemp
	Set ..%GetComponentById("selJournalFile").value = sys.DBEncJournal
	Set ..%GetComponentById("selAuditEncrypt").value = sys.AuditEncrypt
	Set (..KeyFileName,..%GetComponentById("txtKeyFile2").value) = sys.DBEncStartKeyFile
	If sys.DBEncStartUsername '= "" {
		Set ..%GetComponentById("txtAdmName2").hidden = 1
		Set ..%GetComponentById("Password2").hidden = 1
	}
	If sys.DBEncStartMode > 0 {
		Set ..%GetComponentById("fldOption").hidden = 0
		If sys.DBEncStartMode = 3 Set ..%GetComponentById("selKMIP").hidden = 0
	}
	Set ..AllowMultiDB = +$SYSTEM.Version.GetNumber() >= 2014.1

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

Method DrawWarning(pSeed As %String) As %Status
{
	&html<<div class="rednote">#($$$TextHTML("WARNING: Changing the encryption state of your audit log will erase existing audit data."))#</div>>
	Quit $$$OK
}

/// User clicked one of the Browse buttons.
/// Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name, wildcard) [ Language = javascript ]
{
	zenPage.browseselect = name;
	var Dir = zen(name).getValue();
	var url = zenLink('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard);
	zenLaunchPopupWindow(url,'FileSelect','resizable,width=680,height=750');
}

/// User clicked the "Activate Key" button. Show the form to Activate.
ClientMethod doActivate() [ Language = javascript ]
{
	try {
		zen("form1").setHidden(false);
		zen("form2").setHidden(true);
		zen("txtKeyFile").focus();
	}
	catch(ex) {
	alert("ERROR: " + ex);
	}
}

/// User clicked the "Deactivate Key" button. Process only if confirmed.
ClientMethod doDeactivate(KeyID) [ Language = javascript ]
{
	try {
		var confirmstring = this.lblDeactivate;
		confirmstring = confirmstring.replace(/%1/,KeyID);
		var ok = confirm(confirmstring);
		if (!ok) return;
		var proxy = this.DeactivateKey(KeyID);
		if (proxy.ok == 1) {
			this.refreshPage();
		} else {
			this.showMsg(proxy.ErrorMessage,1);
		}		
	}
	catch(ex) {
	alert("ERROR: " + ex);
	}
}

/// User changed Key File. Enable fields if file name is changed.
ClientMethod doFileChange() [ Language = javascript ]
{
	var keyFile = zen("txtKeyFile2").getValue();
	if (this.KeyFileName != keyFile) {
		this.doModified();
		zen("txtAdmName2").setHidden(false);
		zen("Password2").setHidden(false);
		zen("txtAdmName2").focus();
	}
}

/// User selected a Startup option. Show or hide related fields based on selection.
ClientMethod doOptions(option) [ Language = javascript ]
{
	try {
		switch(option) {
		case '0':
			zen("fldOption").setHidden(true);
			zen("id_Options").setHidden(true);
			zen("selKMIP").setHidden(true);
			break;	
		case '1':
			zen("fldOption").setHidden(false);
			zen("id_Options").setHidden(true);
			zen("selKMIP").setHidden(true);
			break;
		case '2':
			zen("fldOption").setHidden(false);
			zen("id_Options").setHidden(false);
			zen("selKMIP").setHidden(true);
			zen("txtKeyFile2").focus();
			break;
		case '3':
			zen("fldOption").setHidden(false);
			zen("id_Options").setHidden(true);
			zen("selKMIP").setHidden(false);
			break;
		}
	}
	catch(ex) {
	alert("ERROR: " + ex);
	}
}

/// User clicked the "Configure Startup Settings" button. Show the form to configure.
ClientMethod doConfigure() [ Language = javascript ]
{
	try {
		zen("form1").setHidden(true);
		zen("form2").setHidden(false);
		zen("selStartup").focus();
	}
	catch(ex) {
	alert("ERROR: " + ex);
	}
}

/// User clicked the "Set Default" button to change default key id.
ClientMethod doDefault(KeyID, use) [ Language = javascript ]
{
	try {
		if (use == 1) {
			var confirmstring = $$$Text("Are you sure you want to set identifier %1 to be the default key?");	
		} else {
			var confirmstring = $$$Text("Are you sure you want to set identifier %1 to be the key for encrypted journal files?");
		}
		confirmstring = confirmstring.replace(/%1/,KeyID);
		var ok = confirm(confirmstring);
		if (!ok) return;
		
		var proxy = this.SetDefaultKey(KeyID, use);
		if (proxy.ok == 1) {
			this.refreshPage();
		} else {
			this.showMsg(proxy.ErrorMessage,1);
		}				
	}
	catch(ex) {
	alert("ERROR: " + ex);
	}
}

/// Reload page.
ClientMethod refreshPage() [ Language = javascript ]
{
	this.gotoPage(this.PageURL);
}

/// Get user selection and send to server to activate key.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		this.resetMsg();
		var pass = true;
		if (!this.validateRequired(zen("txtKeyFile"),pass,"S")) pass = false;
		if (!this.validateRequired(zen("txtAdmName"),pass,"S")) pass = false;
		if (!this.validateRequired(zen("Password1"),pass,"S")) pass = false;
		if (!pass) {
			// display standard error message on top
			this.showMsg(this.ValidationErrorMsg,1);
			var field = this.FirstFailed;
			zen(field).focus();
			return;
		}	
		var proxy = this.ActivateKey(zen("txtKeyFile").getValue(),zen("txtAdmName").getValue(),zen("Password1").getValue());
		if (proxy.ok == 1) {
			this.setModified(false);
			this.refreshPage();
		} else {
			this.showMsg(proxy.ErrorMessage,1);
		}
	} 
  catch(ex) {
	alert("ERROR: " + ex);
	}
}

/// Get user selection and send to server to save.
ClientMethod doSaveStartup() [ Language = javascript ]
{
	try {
		this.resetMsg();
		var option = zen("selStartup").getValue();
		var pass = true;
		var JournalFile = 0;
		var IRISTemp = 0;
		var AuditEncrypt = 0;
		var KeyFile = "";
		var Username = "";
		var Password =  "";
		switch(option) {
		case '0':		
			break;	
		case '1':
			JournalFile = zen("selJournalFile").getValue();
			IRISTemp = zen("selIRISTemp").getValue();
			AuditEncrypt = zen("selAuditEncrypt").getValue();
			break;
		case '2':
			// if file is not changed then skip validation
			KeyFile = zen("txtKeyFile2").getValue();
			if (KeyFile == "" || this.KeyFileName != KeyFile) {
				if (!this.validateRequired(zen("txtKeyFile2"),pass,"S")) pass = false;
				if (!this.validateRequired(zen("txtAdmName2"),pass,"S")) pass = false;
				if (!this.validateRequired(zen("Password2"),pass,"S")) pass = false;
			}
			if (!pass) {
				// display standard error message on top
				this.showMsg(this.ValidationErrorMsg,1);
				var field = this.FirstFailed;
				zen(field).focus();
				break;
			} 
			Username = zen("txtAdmName2").getValue();
			Password = zen("Password2").getValue();
			JournalFile = zen("selJournalFile").getValue();
			IRISTemp = zen("selIRISTemp").getValue();
			AuditEncrypt = zen("selAuditEncrypt").getValue();
			break;
		case '3':
			KeyFile = zen("selKMIP").getValue();
			if (KeyFile == "") {
				if (!this.validateRequired(zen("selKMIP"),pass,"S")) pass = false;
			}
			if (!pass) {
				// display standard error message on top
				this.showMsg(this.ValidationErrorMsg,1);
				var field = this.FirstFailed;
				zen(field).focus();
				break;
			} 
			JournalFile = zen("selJournalFile").getValue();
			IRISTemp = zen("selIRISTemp").getValue();
			AuditEncrypt = zen("selAuditEncrypt").getValue();
			break;	
		}
		if (!pass) {
			return;
		}
		var proxy = this.SaveStartup(option, JournalFile, IRISTemp, AuditEncrypt, KeyFile, Username, Password);
		if (proxy.ok == 1) {
			this.setModified(false);
			this.refreshPage();
		} else {
			this.showMsg(proxy.ErrorMessage,1);
		}
	} 
  catch(ex) {
	alert("ERROR: " + ex);
	}
}

/// Hide edit forms.
ClientMethod doCancel() [ Language = javascript ]
{
	zen("form1").setHidden(true);
	zen("form2").setHidden(true);
}

/// Multiple DB Encryption is allowed starting from 2014.1.
/// And Configure Startup Settings is always allowed.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);	
	if (this.DefaultKey != "" && !this.AllowMultiDB) {
			this.disableCommandButton("btnActivate");	
	}
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			var name = zenPage.browseselect;
			zen(name).setValue(value);
			if (name == "txtKeyFile2") {
				this.doFileChange();
			}
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Save general data to server
ClassMethod DeactivateKey(pKeyID) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = $$DeactivateDB^EncryptionKey(pKeyID)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

/// Save general data to server
ClassMethod ActivateKey(pKeyFile, pUsername, pPassword) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = $$ActivateDB^EncryptionKey(pKeyFile,pUsername,pPassword)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

/// Save startup settings to server.
ClassMethod SaveStartup(pMode, pJournalFile, pIRISTemp, pAuditEncrypt, pKeyFile, pUsername, pPassword) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set sys = ##class(Security.System).%OpenId("SYSTEM")
		Set tSC = $$ConfigStart^DATABASE1(pMode,pJournalFile,pIRISTemp,pKeyFile,pUsername,pPassword,pAuditEncrypt)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

/// Set new default key to server.
ClassMethod SetDefaultKey(pKeyID, use) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()	
	Try {
		Set sys=##class(Security.System).%OpenId("SYSTEM")
		If use = 1 {
			Set tSC = $System.Security.System.SetDBEncKeyDefault(pKeyID)
			Set sys.DBEncDefaultKeyID = pKeyID
		} Else {
			Set tSC = $System.Security.System.SetJrnEncKey(pKeyID)
			Set sys.DBEncJournalKeyID = pKeyID
		}
		Do sys.%Save()
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

/// Draw activated databases encryption key identifier table
Method DrawIDs(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	If %page.DefaultKey = "" Quit tSC
	Set KeyList = %page.KeyList
	Set KeyLenList = %page.KeyLenList
	Set tTotalKeys = $L(KeyList,",")
	&html<<form>
	<table class="DetailTable" border="1" cellpadding="2" cellspacing="0" >>
	&html<<tr><th nowrap>#($$$Text("Count"))#</th><th nowrap>#($$$Text("Identifier"))#</th><th nowrap>#($$$Text("Bit length"))#</th><th>&nbsp;</th><td>&nbsp;</td>>
	&html<</tr>>
	Set cmdDeact = $$$Text("Deactivate")
	Set cmdSetDef = $$$Text("Set Default")
	Set cmdSetJournal = $$$Text("Set Journal")
	Set titleDeact = $$$Text("Deactivate this key")
	Set titleDefault = $$$Text("Make this key the default key for new databases")
	Set titleJournal = $$$Text("Make this key the key for new encrypted journal files")
	Set n = 1
	Set tKeyID = $P(KeyList,",",n)
	Set tKeyLen = $P(KeyLenList,",",n)
	While tKeyID '= "" {
		&html<<tr>
		<td align="center">#(..EscapeHTML(n))#</td>
		<td>#(..EscapeHTML(tKeyID))#</td>
		<td align="center">#(..EscapeHTML(tKeyLen))#</td>
		<td align="center">>
		If tKeyID = %page.DefaultKey &html<(#($$$TextHTML("Default key for new encrypted databases"))#)<br/>>
		If tKeyID = %page.JournalKey &html<(#($$$TextHTML("Key for encrypted journal files"))#)>
		If %page.DefaultKey '= tKeyID, %page.JournalKey '= tKeyID &html<&nbsp;>
		&html<</td>>
		&html<<td nowrap>>
		&html<<input type="button" title="#(titleDefault)#" value="#(cmdSetDef)#" #($S(tKeyID=%page.DefaultKey:"disabled",1:""))# onclick="zenPage.doDefault('#(tKeyID)#',1)">>
		&html<<input type="button" title="#(titleJournal)#" value="#(cmdSetJournal)#" #($S(tKeyID=%page.JournalKey:"disabled",1:""))# onclick="zenPage.doDefault('#(tKeyID)#',2)">>
		#; enable Deactivate button for the default key only when that is the last key left
		Set tDisable = ""
		If tKeyID = %page.DefaultKey ! (tKeyID = %page.JournalKey) Set tDisable = "disabled"
		If $L(KeyList,",") = 1 Set tDisable = ""
		&html<<input type="button" title="#(titleDeact)#" value="#(cmdDeact)#" #(tDisable)# onclick="zenPage.doDeactivate('#(tKeyID)#')">>
		&html<</td></tr>>
		Set n = n + 1
		Set tKeyID = $P(KeyList,",",n)
		Set tKeyLen = $P(KeyLenList,",",n)
	}
	&html<</table></form>>
	Quit tSC
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnActivate",$$$Text("Activate Key"),$$$Text("Activate database encryption key"),"zenPage.doActivate();")
	Set pCommands(2) = $LB("btnConfigure",$$$Text("Configure Startup Settings"),$$$Text("Configure settings for encrypted databases"),"zenPage.doConfigure();")
	Quit $$$OK
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
