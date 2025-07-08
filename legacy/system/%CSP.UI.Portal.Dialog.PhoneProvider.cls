/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// New Phone Provider for Management Portal (popup from edit user)
Class %CSP.UI.Portal.Dialog.PhoneProvider Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Dialog.PhoneProvider.zen";

/// Displayed name of this page.
Parameter PAGENAME = "PhoneProviderEdit";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Parameter EMSSERVICE = "Users";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="2"/>
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<group id="editGroup" labelPosition="left" cellStyle="padding-bottom:5px;">
<text id="Name" label="Service Provider" size="50" hint="Required."/>
<text id="SMSGateway" label="SMS Gateway" size="50" hint="Required."/>
</group>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zen("Name").focus();
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		this.resetMsg();
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
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	var pass = true;
	try {
		var ctl = zen("Name");
		var ctlValue = ctl.getValue()
		ctlValue = zenTrim(ctlValue);
		ctl.setValue(ctlValue);
		if (ctlValue == "") {
			ctl.setProperty("hintClass","redText");
			ctl.setProperty("controlClass","zenInvalid");
			if (pass) ctl.focus();
			pass = false;
		} else {
			ctl.setProperty("hintClass","helpText");
			ctl.setProperty("controlClass","");
		}
		
		ctl = zen("SMSGateway");
		ctlValue = ctl.getValue()
		ctlValue = zenTrim(ctlValue);
		ctl.setValue(ctlValue);
		if (ctlValue == "") {
			ctl.setProperty("hintClass","redText");
			ctl.setProperty("controlClass","zenInvalid");
			if (pass) ctl.focus();
			pass = false;
		} else {
			ctl.setProperty("hintClass","helpText");
			ctl.setProperty("controlClass","");
		}
	} catch (ex) {
		alert("Error: " + ex);	
	}
	zenSynchronousMode = oldSynchronousMode;
	
	return pass;
}

ClientMethod doSave() [ Language = javascript ]
{
	var proxy = new zenProxy();
	proxy.Name = zen('Name').getValue();
	proxy.SMSGateway = zen('SMSGateway').getValue();
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
	Quit $$$Text("Create a New Mobile Phone Provider")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set Properties("SMSGateway") = pProxy.SMSGateway
		
		Set tSC = ##class(%SYS.PhoneProviders).Create(pProxy.Name,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)

		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

}
