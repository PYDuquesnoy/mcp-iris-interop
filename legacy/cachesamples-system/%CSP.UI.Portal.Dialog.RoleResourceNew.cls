/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Dialog to add new resources to a role
Class %CSP.UI.Portal.Dialog.RoleResourceNew Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Dialog.RoleResourceNew.zen";

Parameter RESOURCE = "%Admin_Secure:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Add Role Resources";

/// Domain used for localization.
Parameter DOMAIN = "%Utility";

Parameter EMSSERVICE = "Security";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Property CurrResources As %String;

/// Role name
Property PID As %String(ZENURL = "PID");

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
</style>
}

/// This XML block defines the contents of this page.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<spacer height="2"/>
<label id="idRespond" controlClass="redText" value="" containerStyle="padding-left:5px;"/>
<vgroup width="100%">
<form cellStyle="padding:2px;" enclosingClass="EditForm" enclosingStyle="margin-left:3px;padding-top:2px;" labelPosition="left" hidden="false">
<html id="SelectBox" OnDrawContent="DrawSelectBox"/>
</form>
</vgroup>
</pane>
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return encodeURIComponent(this.CurrResources);
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		this.resetMsg();
		
		var selectList = document.getElementById("Resources");
		var len = selectList.length;
		var selectedResources = "";
		for (var i=0;i<len;i++) {	
			if (selectList.options[i].selected == true) {
				selectedResources = selectedResources+selectList.options[i].value+",";
			}
		}
		
		var proxy = new zenProxy();
		proxy.PID = this.PID;
		proxy.CurrResources = this.CurrResources;
		proxy.NewResources = selectedResources;
		
		var result = this.SaveData(proxy);
		if (result.ok != 1) {
			this.showMsg(result.ErrorMessage,true);
			return false;
		} else {
			this.CurrResources = result.NewResourceList;
			return true;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

Method DrawSelectBox(seed As %String) As %Status
{
	Try {
		For n = 1:1:$L(..CurrResources,",") {
			Set res = $P(..CurrResources,",",n)
			If res '= "" {
				Set resArray($P(res,":")) = 1 
			}
		}
		&html<<div class="zenLabel">#($$$Text("Available Resources"))#</div>
		<select id="Resources" size="25" multiple>>
		Set tRS = ##class(%ResultSet).%New("Security.Resources:List")
		Set tSC = tRS.Execute("*",,)
		// show only the ones that are not assigned to the role yet.
		While tRS.Next() {
			Set tName = tRS.GetData(1)
			If $G(resArray(tName))="" {
				&html<<option value="#(tName)#">#(..EscapeHTML(tName))#</option>>	
			}
		}
		&html<</select>>
		
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
		Set NewRes = ""

		// parse out and find default permission for each resource
		For i=1:1:$LENGTH(pProxy.NewResources,",") {
			Set Resource = $P(pProxy.NewResources,",",i)
			If ##class(Security.Resources).Exists(Resource) {
				Set PublicPermission = ..GetPermission(Resource)
				Set NewRes = NewRes_","_Resource_":"_PublicPermission
			}
		}
		If pProxy.CurrResources = "" {
			Set Properties("Resources") = $P(NewRes,",",2,*)
		} Else {
			Set Properties("Resources") = pProxy.CurrResources_NewRes
		}
		Set tProxy.NewResourceList = Properties("Resources")
		
		Set tSC = ##class(Security.Roles).Modify(pProxy.PID,.Properties)
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

ClassMethod GetPermission(Resource As %String) As %String
{
	Set Permission = ""
	// Following code copied from ^SECURITY 
	// Getting default permission from a given Resource
	i $e(Resource,1)'="%" s Permission="RWU"
	e  i $e(Resource,1,$l($$$DBResourcePrefix))=$$$DBResourcePrefix s Permission="RW"
	e  i $e(Resource,1,$l($$$ServiceResourcePrefix))=$$$ServiceResourcePrefix s Permission="U"
	e  i $e(Resource,1,$l($$$DeepSeeResourcePrefix))=$$$DeepSeeResourcePrefix s Permission="U"
	e  i $e(Resource,1,$l($$$AdminResourcePrefix))=$$$AdminResourcePrefix s Permission="U"
	e  i $e(Resource,1,$l($$$DeveloperResourcePrefix))=$$$DeveloperResourcePrefix s Permission="U"
	e  i $e(Resource,1,$l($$$ApplicationResourcePrefix))=$$$ApplicationResourcePrefix s Permission="U"
	e  i $e(Resource,1,$l($$$SystemResourcePrefix))=$$$SystemResourcePrefix s Permission="U"
	e  i $e(Resource,1,$l($$$DocDBResourcePrefix))=$$$DocDBResourcePrefix s Permission="U"
	e  i $e(Resource,1,$l($$$GatewayResourcePrefix))=$$$GatewayResourcePrefix s Permission="U"
	e  i $e(Resource,1,$l($$$IAMResourcePrefix))=$$$IAMResourcePrefix s Permission="U"
	e  i $e(Resource,1,$l($$$NativeResourcePrefix))=$$$NativeResourcePrefix s Permission="U"
	e  i $e(Resource,1,$l($$$SQLResourcePrefix))=$$$SQLResourcePrefix s Permission="U"
	e  i $e(Resource,1,$l($$$SecureShellResourcePrefix))=$$$SecureShellResourcePrefix s Permission="U"
	Quit Permission
}

/// Set Locator bar and determine whether to show change password option.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set tSC = ##class(Security.Roles).Get(..PID,.Properties)
	If $$$ISERR(tSC) Quit tSC
	
	Set ..CurrResources = Properties("Resources")

	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$FormatText($$$TextHTML("Assign resources to role %1"),..EscapeHTML(..PID))
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

}
