/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Data Element Encryption Key. You may activate or deactivate a data element encryption key.
Class %CSP.UI.Portal.EncryptionManaged Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Data Element Encryption";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.EncryptionManaged.zen";

Parameter HELPADDRESS = "System Administration,Encryption,Data Element Encryption";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property browseselect As %String;

Property LocatorHeader As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Data Element Encryption")} ];

Property PageURL As %ZEN.Datatype.string;

Property lblDeactivate As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to deactivate key %1?")} ];

/// This is the max number allowed to be activated.
Property MaxAllowed As %ZEN.Datatype.integer;

/// This is the actual number already activated.
Property CurrentlyActivated As %ZEN.Datatype.integer;

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
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<html id="htmlIDs" OnDrawContent="DrawIDs"/>
<form id="fld" autocomplete="false">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group id="form1" enclosingClass="EditForm" label="Fill out the following form to activate a data element encryption key:" cellStyle="padding:4px;" hidden="true" labelPosition="left">
<hgroup id="id_Key" labelPosition="left" label="Key File" cellVAlign="top" >
<text id="txtKeyFile" size="60" maxlength="50" hint="Required."/>
<button id="btnBrowse" caption="Browse..." containerStyle="padding-left:2px;" onclick="zenPage.browseSelect('txtKeyFile','*');"/>
</hgroup>
<text id="txtAdmName" label="Administrator Name" size="60" maxlength="50" hint="Required."/>
<text inputtype="password" id="Password1" label="Password" hint="Required."/>
<html><hr size="1"/></html>
<hgroup>
<button id="btnSave" caption="Activate" onclick="zenPage.doSave();"/>
<button caption="Cancel" onclick="zenPage.doCancel();"/>
</hgroup>
</group>
</form>
</pane>
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set MKEncKeyIDList = $System.Security.System.GetMKEncKeyIDList()
	If MKEncKeyIDList = "" {
		Set ..%GetComponentById("Text1").value = $$$Text("No data element encryption key is activated.")
	} Else {
		Set ..%GetComponentById("Text1").value = $S($L(MKEncKeyIDList,",")>1:$$$Text("Activated data element encryption key identifiers:"),1:$$$Text("Activated data element encryption key identifier:"))
	}
	#; Set properly escaped page url to property so that refresh page can readily use it.
	Set ..PageURL = $ZCVT(..Link(..#CSPURL),"O","URL")		
	#; Set the max data element encryption keys can be simultaneously activated
	Set ..MaxAllowed = $$$MAXNUMMKENCKEYS
	Set ..CurrentlyActivated = +$L($System.Security.System.GetMKEncKeyIDList(),",")
	Quit 1
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);	
	if (this.CurrentlyActivated >= this.MaxAllowed) {
		this.disableCommandButton("btnActivate");
	}
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
	zenPage.browseselect = name;
	var Dir = zen(name).getValue();
	var url = zenLink('%ZEN.Dialog.fileSelect.cls?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard);
	zenLaunchPopupWindow(url,'FileSelect','resizable,width=680,height=750');
}

/// User clicked the "Activate Key" button. Show the form to Activate.
ClientMethod doActivate() [ Language = javascript ]
{
	try {
		zen("form1").setHidden(false);
		zen("txtKeyFile").focus();
	}
	 catch(ex) {
	alert("ERROR: " + ex);
	}
}

/// Hide edit forms.
ClientMethod doCancel() [ Language = javascript ]
{
	zen("form1").setHidden(true);
	this.resetMsg();
}

/// User clicked the "Deactivate". Process only if confirmed.
ClientMethod doDeactivate(MKEncKeyID) [ Language = javascript ]
{
	try {
		this.resetMsg();
		var confirmstring = this.lblDeactivate;
		confirmstring = confirmstring.replace(/%1/,MKEncKeyID);
		var ok = confirm(confirmstring);
		if (!ok) return;
		var proxy = this.DeactivateKey(MKEncKeyID);
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

ClientMethod validate() As %Boolean [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var pass = true;
	try {
		if (!this.validateRequired(zen('txtKeyFile'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('txtAdmName'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('Password1'),pass,"S")) pass = false;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;
	
	return pass;
}

/// Get user selection and send to server to activate key.
ClientMethod doSave() [ Language = javascript ]
{
	try {
		this.resetMsg();
		var ok = zenPage.validate();
		if (!ok) {
			this.afterValidate();
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

ClientMethod refreshPage() [ Language = javascript ]
{
	this.gotoPage(this.PageURL);
}

/// Save general data to server
ClassMethod ActivateKey(KeyFile, Username, Password) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error"
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tSC = $$ActivateMK^EncryptionKey(KeyFile,Username,Password)
	If $$$ISERR(tSC) Set tProxy.ErrorMessage = $System.Status.GetErrorText(tSC)
	Else  Set tProxy.ok = 1
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			var name = zenPage.browseselect;
			zen(name).setValue(value);
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

Method DrawIDs(pSeed As %String) As %Status
{
	Set MKEncKeyIDList = $System.Security.System.GetMKEncKeyIDList()
	If MKEncKeyIDList = "" Quit $$$OK
	Set titleDeact = $$$Text("Deactive this key")
	Set total = $L(MKEncKeyIDList,",")
	Set lblDeactivate = $$$Text("Deactivate")
	&html<<form>
	<table class="DetailTable" border="1" cellpadding="2" cellspacing="0" >>
	&html<<tr><th nowrap>#($$$Text("Count"))#</th><th nowrap>#($$$Text("Identifier"))#</th><th>&nbsp;</th>>
	&html<</tr>>

	For i = 1:1:total {
		Set MKEncKeyID = $P(MKEncKeyIDList,",",i)
		&html<<tr><td align="center">#(i)#</td><td nowrap>#(MKEncKeyID)#</td>>
		&html<<td><input type="button" value="#(lblDeactivate)#" title="#(titleDeact)#" onclick="zenPage.doDeactivate('#(MKEncKeyID)#')"></td>>

		&html<</tr>>
 	}
 	If total = 0 &html<<tr><td colspan="4" nowrap>#($$$Text("None"))#</td></tr>>
 	Set tMaxAllowed = $$$FormatText($$$Text("A maximum of %1 data element encryption keys can be simultaneously activated."),%page.MaxAllowed)
	&html<</table></form><p>#($zconvert(tMaxAllowed,"O","HTML"))#</p>>
	Quit $$$OK
}

/// Save general data to server
ClassMethod DeactivateKey(MKEncKeyID) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set tSC = $$DeactivateMK^EncryptionKey(MKEncKeyID)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = ..%OnGetPageName()

	// commands: $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("btnActivate",$$$Text("Activate Key"),$$$Text("Activate data element encryption key"),"zenPage.doActivate();")
	Quit $$$OK
}

}
