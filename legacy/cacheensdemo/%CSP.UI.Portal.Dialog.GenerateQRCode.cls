/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.</p>
/// New Phone Provider for Management Portal (popup from edit user)
Class %CSP.UI.Portal.Dialog.GenerateQRCode Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Dialog.GenerateQRCode.zen";

/// Displayed name of this page.
Parameter PAGENAME = "GenerateQRCode";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

Parameter EMSSERVICE = "Users";

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property PID As %String(ZENURL = "PID");

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding:4 6 4 10;">
<spacer height="2"/>
<label id="idRespond" enclosingClass="note" containerStyle="padding-top:10px;padding-left:4px;" hidden="true"/>
<group id="editGroup" labelPosition="left" cellStyle="padding-bottom:5px;">
<html id="htmlContent" OnDrawContent="DrawLogContent"/>
</group>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Generate a new Time-based One-time Password Key")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

/// This method draws content to html. No style is applied. Display content as is.
Method DrawLogContent(filename) As %Status
{
	&html<<pre>>
 	s Text=$ZCVT($$$Text("This will generate a new Time-based One-time Password Key for the user."),"O","HTML")_"<br/><br/>"
 	s Text=Text_$ZCVT($$$Text("If you confirm this action, the current key entered into the user's authenticator"),"O","HTML")_" "
 	s Text=Text_$ZCVT($$$Text("application will no longer work. Before the user is able to log in, they will need"),"O","HTML")_" "
  	s Text=Text_$ZCVT($$$Text("to enter the new key into their authenticator by either scanning the"),"O","HTML")_" "
  	s Text=Text_$ZCVT($$$Text("QR code (barcode), or manually entering the key into their authenticator. Existing"),"O","HTML")_" "
  	s Text=Text_$ZCVT($$$Text("sessions for the user will not be affected by this."),"O","HTML")_"<br/><br/>"
  	s Text=Text_$ZCVT($$$Text("If you cancel this action, the user's existing key in their authenticator"),"O","HTML")_" " 
  	s Text=Text_$ZCVT($$$Text("application will continue to work."),"O","HTML")
	Write Text
	&html<</pre>>
	Quit $$$OK
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return "";
}

/// This callback, if defined, is called when the user presses the OK or Apply action buttons.
/// If this returns false, then the action is cancelled.<br>
ClientMethod ondialogFinish(action) As %Boolean [ Language = javascript ]
{
	try {
		this.resetMsg();
		if (this.doSave()==false) return false;
		this.firePopupAction('apply',this.getDialogValue(),false);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return true;
}

ClientMethod doSave() [ Language = javascript ]
{
	
	var proxy = new zenProxy();
	proxy.PID = this.PID;
	var result = this.SaveData(proxy);
	if (result.ok != 1) {
		this.showMsg(result.ErrorMessage,true);
		return false;
	}
	return true;
}

ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Set PID=pProxy.PID
#;If we generate a new key, then we need to display it on the next login.
	Try {
		Set Properties("HOTPKeyDisplay")=1
		Set Properties("HOTPKeyGenerate")=1
		Set tSC=##Class(Security.Users).Modify(PID,.Properties)
		If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

}
