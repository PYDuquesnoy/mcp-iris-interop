/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// Edit Resource for Management Portal
Class %CSP.UI.Portal.Dialog.Resource Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Dialog.Resource.zen";

/// Displayed name of this page.
Parameter PAGENAME = "ResourceEdit";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Parameter EMSSERVICE = "Security";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

/// When editing an existing resource this is passed in as the resource name.
Property RESOURCENAME As %ZEN.Datatype.string(ZENURL = "RESOURCENAME");

/// If called from Database wizard, then this is set and default to %DB_[RESOURCETYPE].
Property RESOURCETYPE As %ZEN.Datatype.string(ZENURL = "RESOURCETYPE");

Property IsError As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property DBResourcePrefix As %ZEN.Datatype.string;

Property msgPrefix As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("A database resource name must start with %1")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
/* style for title instructions */
div.Description	{
	font-size: 0.9em; 
	padding: 5px;
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
<button id="btnCancel" controlClass="commandButton" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnFinish" controlClass="commandButton" caption="Save" onclick="zenPage.dialogFinish();;"/>
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="2"/>
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<html OnDrawContent="DrawPageTitle" seed=""/>
<group id="editGroup" labelPosition="left" cellStyle="padding-bottom:5px;">
<text id="Name" label="Resource Name" size="70" hint="Required. Enter 1-64 characters."/>
<textarea id="Description" label="Description" rows="5" cols="40"/>
<hgroup label="Public Permission" labelPosition="left">
<checkbox id="PublicPermissionRead" caption="Read" captionClass="normal"/>
<checkbox id="PublicPermissionWrite" caption="Write" captionClass="normal"/>
<checkbox id="PublicPermissionUse" caption="Use" captionClass="normal"/>
</hgroup>
</group>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onstartHandler() [ Language = javascript ]
{
	if (this.IsError) {
		var msg = $$$Text("You do not have security privilege to create or edit a Resource code.");
		this.showMsg(msg);
		zen("btnFinish").setDisabled(true);
		zen("btnFinish").setProperty("controlClass","commandButtonDisabled");
		zen("editGroup").setHidden(true);
		return;
	}
	if (this.RESOURCENAME == "") {
		zen("Name").focus();
	} else {
		zen("Name").setDisabled(true);
		zen("Description").focus();
	}
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		if (this.validate()==false) return false;
		if (this.doSave()==false) return false;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	var resourceName = encodeURIComponent(zen("Name").getValue());
	return resourceName;
}

ClientMethod validate() [ Language = javascript ]
{
	if (this.RESOURCENAME == "") {
		var Name = zen("Name").getValue();
		Name = zenTrim(Name);
		zen("Name").setValue(Name);
		if (Name == "") {
			zen("Name").setProperty("hintClass","redText");
			zen("Name").focus();
			return false;
		}
		// called from Database wizard
		if (this.RESOURCETYPE.length > 0) {
			var PrefixLength = this.DBResourcePrefix.length;
			if (Name.substring(0,PrefixLength) != this.DBResourcePrefix)
			{
				var msg = this.msgPrefix.replace("%1",this.DBResourcePrefix)
				alert(msg);
				zen("Name").focus();
				return false;
			}
		}
	}
	return true;
}

ClientMethod doSave() [ Language = javascript ]
{
	this.resetMsg();
	var proxy = new zenProxy();
	if (this.RESOURCENAME == "") {
		proxy.Name = zen("Name").getValue();
	} else {
		proxy.Name = this.RESOURCENAME;
	}
	proxy.RESOURCENAME = this.RESOURCENAME;
	proxy.Description = zen("Description").getValue();
	proxy.PublicPermission1 = zen("PublicPermissionRead").getValue() ? 1 : 0;
	proxy.PublicPermission2 = zen("PublicPermissionWrite").getValue() ? 1 : 0
	proxy.PublicPermission3 = zen("PublicPermissionUse").getValue() ? 1 : 0
	var result = this.SaveData(proxy);
	if (result.ok != 1) {
		this.showMsg(result.ErrorMessage,true);
		return false;
	}
	return true;
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If %page.RESOURCENAME = "" Quit $$$Text("Create a New Resource Name")
	Quit $$$Text("Edit Resource")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
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
	
	Set RESOURCENAME = ..RESOURCENAME
	Set (PublicPermissionRead,PublicPermissionWrite,PublicPermissionUse) = ""
	Set (ShowRead,ShowWrite,ShowUse) = 1

	// If called from DatabaseEdit page, this is set to the name of the database
	Set RESOURCETYPE = ..RESOURCETYPE
	Set ..DBResourcePrefix = $$$DBResourcePrefix
	If RESOURCENAME '= "" {
		Set tSC = ##class(Security.Resources).Get(RESOURCENAME,.Properties)
		If $$$ISERR(tSC) {
			Set ..IsError = 1
			Quit tSC
		}
		
		Set tTitle = $$$FormatText($$$TextHTML("Edit Definition for Resource %1"),..EscapeHTML(RESOURCENAME))
		Set ..%GetComponentById("Name").value = RESOURCENAME
		Set PublicPermission = Properties("PublicPermission")
		If PublicPermission [ "R" Set ..%GetComponentById("PublicPermissionRead").value = 1
		If PublicPermission [ "W" Set ..%GetComponentById("PublicPermissionWrite").value = 1
		If PublicPermission [ "U" Set ..%GetComponentById("PublicPermissionUse").value = 1
		Set ..%GetComponentById("Description").value = Properties("Description")
		
	 	If $E(RESOURCENAME,1,$l($$$ServiceResourcePrefix))=$$$ServiceResourcePrefix!
	 		($E(RESOURCENAME,1,$l($$$DeepSeeResourcePrefix))=$$$DeepSeeResourcePrefix)!
	 		($E(RESOURCENAME,1,$l($$$AdminResourcePrefix))=$$$AdminResourcePrefix)!
		 	($E(RESOURCENAME,1,$l($$$DeveloperResourcePrefix))=$$$DeveloperResourcePrefix)!
		 	($E(RESOURCENAME,1,$l($$$ApplicationResourcePrefix))=$$$ApplicationResourcePrefix)!
		 	($E(RESOURCENAME,1,$l($$$SystemResourcePrefix))=$$$SystemResourcePrefix)!
		 	($E(RESOURCENAME,1,$l($$$DocDBResourcePrefix))=$$$DocDBResourcePrefix)!
		 	($E(RESOURCENAME,1,$l($$$GatewayResourcePrefix))=$$$GatewayResourcePrefix) !
		 	($E(RESOURCENAME,1,$l($$$IAMResourcePrefix))=$$$IAMResourcePrefix) !
		 	($E(RESOURCENAME,1,$l($$$NativeResourcePrefix))=$$$NativeResourcePrefix) !
		 	($E(RESOURCENAME,1,$l($$$SQLResourcePrefix))=$$$SQLResourcePrefix) !
		 	($E(RESOURCENAME,1,$l($$$SecureShellResourcePrefix))=$$$SecureShellResourcePrefix)  {
		 	Set (ShowRead,ShowWrite) = 0
	 	}
	   	If $E(RESOURCENAME,1,$l($$$DBResourcePrefix))=$$$DBResourcePrefix Set ShowUse = 0

	} Else {
		Set tTitle = $$$Text("Create a New Resource Name")
		If RESOURCETYPE '= "" {
			Set ..%GetComponentById("Name").value = ..DBResourcePrefix_RESOURCETYPE
			Set ShowUse = 0
		}
		Set ..%GetComponentById("PublicPermissionRead").value = 0
	}
	If ShowRead = 0 Set ..%GetComponentById("PublicPermissionRead").hidden = 1
	If ShowWrite = 0 Set ..%GetComponentById("PublicPermissionWrite").hidden = 1
	If ShowUse = 0 Set ..%GetComponentById("PublicPermissionUse").hidden = 1
	Quit $$$OK
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	If %page.RESOURCENAME = "" {
		Set tPageTitle = $$$TextHTML("Create a New Resource Name")_"<br/>"
	} Else {
		Set tPageTitle = $$$FormatText($$$Text("Edit Definition for Resource %1"),..EscapeHTML(%page.RESOURCENAME))_"<br/>"
	}
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit 1
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set PublicPermission = ""
		If pProxy.PublicPermission1 = 1 Set PublicPermission = "R"
		If pProxy.PublicPermission2 = 1 Set PublicPermission = PublicPermission_"W"
		If pProxy.PublicPermission3 = 1 Set PublicPermission = PublicPermission_"U"
		
		If pProxy.RESOURCENAME '= "" {
			Set Properties("Description") = pProxy.Description
			Set Properties("PublicPermission") = PublicPermission
			Set tSC = ##Class(Security.Resources).Modify(pProxy.RESOURCENAME,.Properties)
		} Else {
			Set tSC = ##Class(Security.Resources).Create(pProxy.Name,pProxy.Description,PublicPermission)
		}
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
		If tProxy.ErrorMessage [ "#5805" Set tProxy.ErrorMessage = $$$TextHTML("This name is already used. Please pick a name that is not already defined.")
	}
	Quit tProxy
}

/// This callback, if defined, is called when the user presses the Cancel button.
/// If this returns false, then the dialog is not cancelled.
ClientMethod ondialogCancel() [ Language = javascript ]
{
	if ((this.RESOURCETYPE != "")) {
		// if it is called from the Database Wizard, then reset the radio choice back to origianl
		var opener = this.getOpener();
		if (opener && opener.zen("radR1")) {
			opener.zen("radR1").setProperty("value",1);
			opener.zen("ResourceName").setProperty("readOnly",true);
		}
	}
	return true;
}

}
