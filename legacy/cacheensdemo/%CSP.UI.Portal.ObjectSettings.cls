/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - General Object Settings
Class %CSP.UI.Portal.ObjectSettings Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.ObjectSettings.zen";

Parameter HELPADDRESS = "Home,Configuration,General Object Settings";

/// Displayed name of this page.
Parameter PAGENAME = "General Object Settings";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

XData Style
{
<style type="text/css">

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" containerStyle="padding:20px;padding-top:10px;">
<label id="Text1" value="" containerStyle="padding-bottom:4px;"/>

<vgroup valign="top">
<label id="idRespond" enclosingClass="note" value="" hidden="true"/>
<spacer height="2"/>
<form id="form1" 
cellStyle="padding:5px;" enclosingClass="EditForm" valign="top" >
<checkbox id="ThrowSwizzleError" caption="Throw &lt;SWIZZLE FAIL&gt; error when swizzling an object fails" captionClass="zenLabel"
onchange="zenPage.doModified();"
hint="Uncheck this checkbox if you do not wish to see this error generated."/>

</form>

</vgroup>

</pane>
}

/// User clicked one of the Browse buttons.
/// Save the name of the textfield so that when you return you know which textfield to update.
ClientMethod browseSelect(name) [ Language = javascript ]
{
	zenPage.getComponentById('browseselect').setValue(name);
	var Dir = zenPage.getComponentById(name).getValue();
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&showdirectoryonly=1','FileSelect','resizable,width=680,height=750');
}

ClientMethod doSave(option) [ Language = javascript ]
{
	var proxy = new zenProxy();
	proxy.ThrowSwizzleError = (zen("ThrowSwizzleError").getValue() ? 1 : 0);
	var result = this.SaveData(proxy);
	this.afterSave(result);
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set ..%GetComponentById("Text1").value = $$$Text("Use the form below to view or edit general object settings:")
	Set ..%GetComponentById("ThrowSwizzleError").value = $G(^%SYS("ThrowSwizzleError"),0)	

	Quit $$$OK
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("General Object Settings")
}

/// This client event, if present, is fired when the a popup page
/// launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	try {
		if (action == "ok") {
			var name = zenPage.getComponentById("browseselect").getValue();
			zenPage.getComponentById(name).setValue(value);
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
}

/// Check if user really wants to exit if they have not saved changes
ClientMethod onunloadHandler() [ Language = javascript ]
{
	if (this.pageModified == true) {
		return $$$Text('Changes have not been saved permanently. If you navigate to a new page these changes will be lost!');
	}
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	Set $ZT="Error"	
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set tProxy.ok = 0
	Set tProxy.Message = ""
	Set tProxy.ErrorMessage = ""
	Set ^%SYS("ThrowSwizzleError") = pProxy.ThrowSwizzleError
	Set tProxy.ok = 1
	Quit tProxy
Error	///
	Set $ZT="" Do BACK^%ETN
	Set tProxy.ErrorMessage = $ZCVT($ZE,"O","HTML")
	Quit tProxy
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("configuration settings");
}

}
