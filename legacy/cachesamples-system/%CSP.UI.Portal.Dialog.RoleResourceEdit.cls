/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Dialog to edit resource permissions in a role
Class %CSP.UI.Portal.Dialog.RoleResourceEdit Extends %CSP.UI.Portal.Dialog.WizardTemplate [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Dialog.RoleResourceEdit.zen";

Parameter RESOURCE = "%Admin_Secure:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Edit Role Resource";

Parameter EMSSERVICE = "Security";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property NewResources;

/// Role name
Property PID As %ZEN.Datatype.string(ZENURL = "PID");

Property CurrPermissions As %ZEN.Datatype.string(ZENURL = "permissions");

/// Resource name
Property ResourceName As %ZEN.Datatype.string(ZENURL = "resource");

Property CopyFromPID As %ZEN.Datatype.string(ZENURL = "copyFromPID");

Property CopyNewPID As %ZEN.Datatype.string(ZENURL = "copyNewPID");

Property CopyNewDesc As %ZEN.Datatype.string(ZENURL = "copyNewDesc");

Property EscalationOnly As %ZEN.Datatype.boolean(ZENURL = "escalationOnly");

Property IsDBResource As %Boolean [ InitialExpression = 0 ];

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

/// Contents of this page:
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" width="100%" height="100%" 
	title="#(%page.dialogTitle)#">
<html id="header" OnDrawContent="%DrawTitle" />

<pane paneName="dialogBody" id="body" />
<hgroup id="footer" width="100%" cellAlign="right">
<hgroup id="buttonHolder" cellAlign="right">
<button id="btnApply" hidden="#(%page.hideApplyButton)#" caption="Apply" onclick="zenPage.dialogApply();" />
<spacer width="5" />
<button id="btnCancel" hidden="#(%page.hideCancelButton)#" caption="Cancel" onclick="zenPage.dialogCancel();" />
<spacer width="5" />
<button id="btnOK" caption=" OK " onclick="zenPage.dialogFinish();" />
<spacer width="10" />
</hgroup>
</hgroup>
</page>
}

/// This XML block defines the contents of this page.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="2"/>
<html OnDrawContent="DrawPageTitle" seed=""/>
<label id="idRespond" controlClass="redText" value="" containerStyle="padding-left:5px;"/>
<vgroup width="100%">
<form cellStyle="padding:2px;" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding-top:2px;" labelPosition="left" hidden="false">
<label id="Resource" label="Resource Name" value="#(%page.ResourceName)#" controlClass="normal"/>
<label id="Description" label="Description" controlClass="normal"/>
<html id="Permissions" label="Permissions" OnDrawContent="DrawPermissions"/>
</form>
</vgroup>
</pane>
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return encodeURIComponent(this.NewResources);
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		this.resetMsg();
		
		var rInput = document.getElementById("PermR");
		var wInput = document.getElementById("PermW");
		var uInput = document.getElementById("PermU");
		
		var SelectedPermissions = "";
		if ((rInput != null) && (rInput.checked == true)) SelectedPermissions = "R";
		if ((wInput != null) && (wInput.checked == true)) SelectedPermissions = SelectedPermissions + "W";
		if ((uInput != null) && (uInput.checked == true)) SelectedPermissions = SelectedPermissions + "U";
		
		var proxy = new zenProxy();
		proxy.PID = this.PID;
		proxy.ResourceName = this.ResourceName;
		proxy.SelectedPermissions = SelectedPermissions;
		proxy.CopyFromPID = this.CopyFromPID;
		proxy.CopyNewPID = this.CopyNewPID;
		proxy.CopyNewDesc = this.CopyNewDesc;
		proxy.EscalationOnly = this.EscalationOnly;
		
		var result = this.SaveData(proxy);
		if (result.ok != 1) {
			this.showMsg(result.ErrorMessage,true);
			return false;
		} else {
			this.NewResources = result.NewResourceList;
			return true;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

ClientMethod writeChanged(newVal) [ Language = javascript ]
{
	var readBox = document.getElementById('PermR');
	if (newVal) {
		readBox.disabled = true;
		readBox.checked = true;
	} else {
		readBox.disabled = false;
	}
}

Method DrawPermissions(seed As %String) As %Status
{
	Try {
		Set (ShowRW,ShowUse) = 1
		If $E(..ResourceName,1,$l($$$ServiceResourcePrefix))=$$$ServiceResourcePrefix!
			($E(..ResourceName,1,$l($$$DeepSeeResourcePrefix))=$$$DeepSeeResourcePrefix)!
			($E(..ResourceName,1,$l($$$AdminResourcePrefix))=$$$AdminResourcePrefix)!
			($E(..ResourceName,1,$l($$$DeveloperResourcePrefix))=$$$DeveloperResourcePrefix)!
			($E(..ResourceName,1,$l($$$ApplicationResourcePrefix))=$$$ApplicationResourcePrefix)!
			($E(..ResourceName,1,$l($$$SystemResourcePrefix))=$$$SystemResourcePrefix)!
			($E(..ResourceName,1,$l($$$DocDBResourcePrefix))=$$$DocDBResourcePrefix)!
			($E(..ResourceName,1,$l($$$GatewayResourcePrefix))=$$$GatewayResourcePrefix)!
			($E(..ResourceName,1,$l($$$IAMResourcePrefix))=$$$IAMResourcePrefix)!
			($E(..ResourceName,1,$l($$$NativeResourcePrefix))=$$$NativeResourcePrefix)!
			($E(..ResourceName,1,$l($$$SQLResourcePrefix))=$$$SQLResourcePrefix)!
			($E(..ResourceName,1,$l($$$SecureShellResourcePrefix))=$$$SecureShellResourcePrefix){
		 	Set ShowRW = 0
		}
		If $E(..ResourceName,1,$l($$$DBResourcePrefix))=$$$DBResourcePrefix {
			Set ..IsDBResource = 1
			Set ShowUse = 0
		}

		Set CurrPrivs = ..CurrPermissions
		
		If ShowRW {
			Set PermR = $SELECT(CurrPrivs["R":"checked",1:"")
			Set PermW = $SELECT(CurrPrivs["W":"checked",1:"")
			Set (DisabledR,OnChangeW) = ""
			If ..IsDBResource {
				Set OnChangeW = "onchange=""zenPage.writeChanged(document.getElementById('PermW').checked);"""
				If (PermW'="")&&(PermR'="") {
					Set DisabledR = "disabled"
				}
			}
			&html<<label class="normal"><input type="checkbox" id="PermR" #(PermR)# #(DisabledR)#>#($$$TextHTML("Read"))#</label>>
			&html<<label class="normal"><input type="checkbox" id="PermW" #(PermW)# #(OnChangeW)#>#($$$TextHTML("Write"))#</label>>
		}
		If ShowUse {
			Set PermU = $SELECT(CurrPrivs["U":"checked",1:"")
			&html<<label class="normal"><input type="checkbox" id="PermU" #(PermU)#>#($$$TextHTML("Use"))#</label>>
		}
		
		Set tSC = $$$OK
	} Catch Error {
		Set tSC = Error.AsStatus()
	}
	Quit tSC
}

/// Save column priv data to server
/// If this is to revoke column priv, then pRevoke = 1, pPrivs and pGrant will be null.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ErrorMessage = ""
	
	Try {
		If pProxy.PID'="" {
			Set tSC = ##class(Security.Roles).Get(pProxy.PID,.Properties)
		} Else {		
			Set tSC = ##class(Security.Roles).Get(pProxy.CopyFromPID,.Properties)
		}
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set CurrResources = Properties("Resources")
		Set GrantedRoles = Properties("GrantedRoles")
		Kill Properties
		
		// rebuild the resource list, replacing the old privs for this resource with the new
		Set Properties("Resources") = ""

		For i=1:1:$LENGTH(CurrResources,",") {
			Set Resource = $P(CurrResources,",",i)
			If ($P(Resource,":",1) = pProxy.ResourceName) {
				// matched resource
				If pProxy.SelectedPermissions = "" {
					// if all unchecked, don't include this resource in the new list
					continue
				}
				Set $PIECE(Resource,":",2) = pProxy.SelectedPermissions
			}
			If Properties("Resources") '= "" Set Properties("Resources") = Properties("Resources")_","
			Set Properties("Resources") = Properties("Resources")_Resource
		}
		Set tProxy.NewResourceList = Properties("Resources")
		
		If pProxy.PID'="" {
			Set tSC = ##class(Security.Roles).Modify(pProxy.PID,.Properties)
		} Else {
			Set tSC = ##class(Security.Roles).Create(pProxy.CopyNewPID,pProxy.CopyNewDesc,Properties("Resources"),GrantedRoles,pProxy.EscalationOnly)
		}
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		If tProxy.ErrorMessage = "" {
			Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
		}
	}
	Quit tProxy
}

/// Set Locator bar and determine whether to show change password option.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set tSC = ##class(Security.Resources).Get(..ResourceName,.Properties)
	If $$$ISERR(tSC) Quit tSC
	
	Set ..%GetComponentById("Description").value = Properties("Description")

	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Edit resource permissions")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClassMethod DrawPageTitle(pSeed As %String) As %Status
{
	Set roleName = $SELECT(%page.PID'="":..EscapeHTML(%page.PID),1:..EscapeHTML(%page.CopyNewPID))
	Set tPageTitle = $$$FormatText($$$TextHTML("Edit permissions for role %1"),roleName)_"<br/>"
	&html<<div class="Description">#(tPageTitle)#</div>
	<hr size="1"/>>
	Quit $$$OK
}

}
