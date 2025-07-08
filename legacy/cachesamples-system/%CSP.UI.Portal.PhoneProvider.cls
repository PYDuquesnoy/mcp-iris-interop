/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - Security Management - Mobile Phone Service Providers
Class %CSP.UI.Portal.PhoneProvider Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Edit Phone Provider";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.PhoneProvider.zen";

Parameter HELPADDRESS = "System Administration,Security,Mobile Phone";

Parameter EMSSERVICE = "Users";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.PhoneProviders.zen";

Parameter RECENT = 0;

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<label id="lblName" label="Service Provider" controlClass="normal"/>
<text id="Name" label="Service Provider" size="50" hint="Required." onchange="zenPage.doModified();"/>
<text id="SMSGateway" label="SMS Gateway" size="50" hint="Required." onchange="zenPage.doModified();"/>
</group>
</form>
</pane>
}

ClientMethod doSave() [ Language = javascript ]
{
	this.resetMsg();
	
	if (!this.validate()) {
		this.afterValidate();
		return;
	}
	
	var proxy = new zenProxy();
	proxy.PID = this.PID;
	proxy.Name = zen('Name').getValue();
	proxy.SMSGateway = zen('SMSGateway').getValue();

	var result = this.SaveData(proxy);
	this.afterSave(result);
}

ClientMethod validate() [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var pass = true;
	try {
		if (!this.validateRequired(zen('Name'),pass,"S")) pass = false;
		if (!this.validateRequired(zen('SMSGateway'),pass,"S")) pass = false;
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;
	
	return pass;
}

///  Save general association data to server.<br/>
///  Returns proxy.ok = 1 (save successful) or 0 (error occurred)<br/>
///  proxy.Message (save successful, with warning message: require restart)<br/>
///  proxy.ErrorMessage (save failed and display this error message).
///  If proxy.ok is 1 and no messages returned then we return to Database list page.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set Properties("SMSGateway") = pProxy.SMSGateway
		
		If pProxy.PID '= "" {
			Set tSC = ##class(%SYS.PhoneProviders).Modify(pProxy.PID,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} Else {
			Set tSC = ##class(%SYS.PhoneProviders).Create(pProxy.Name,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set (..%GetComponentById("lblName").value,..%GetComponentById("Name").value) = ..PID
	
	If ..PID '= "" {
		Set ..%GetComponentById("Text1").value = $$$FormatText($$$Text("Edit definition for phone service provider %1:"),..PID)
		
		Set tSC = ##class(%SYS.PhoneProviders).Get(..PID,.Properties)
		If $$$ISERR(tSC) {
			Set ..%GetComponentById("fld").hidden = 1
			Set ..InvalidParam = 1
			Quit $$$OK
		}		
		
		Set tProperty = ""
		Set tProperty = $O(Properties(tProperty)) 
		While tProperty '= ""  {
			Set Component = ..%GetComponentById(tProperty)
			If $ISO(Component) {
				Set Component.value = Properties(tProperty)
				If ..IsEMSReadOnly Set Component.disabled = 1
			}
			Set tProperty = $O(Properties(tProperty)) 
		}
		
		Set ..%GetComponentById("Name").hidden = 1
	} Else {
		Set ..%GetComponentById("Text1").value = $$$Text("Use the form below to create a phone service provider:")
		
		Set ..%GetComponentById("lblName").hidden = 1
	}
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Edit Phone Provider")
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) <br/>
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Mobile Phone Service Providers","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)
	
	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

}
