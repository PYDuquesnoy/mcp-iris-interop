/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %CSP.UI.Portal.LDAPTest Extends %CSP.UI.Portal.Template [ System = 4 ]
{

/// Do not switch namespace for this page: it needs to stay in %SYS
Parameter AUTONS As BOOLEAN = 0;

/// Displayed name of this page.
Parameter PAGENAME = "Test LDAP Authentication";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.LDAPs.zen";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.LDAPTest.zen";

Parameter HELPADDRESS = "Home,Security Management,Security LDAP configurations,Test LDAP Authentication";

Parameter EMSSERVICE = "Users";

Parameter RECENT = 0;

Property IsTest As %Boolean [ InitialExpression = 0 ];

/// Security requirement
Parameter RESOURCE = "%Admin_Secure";

Property IsEditForm As %Boolean [ InitialExpression = 1 ];

XData Style
{
<style type="text/css">
/* override the image because this form is too tall */
.EditForm {
	background-image: url('');
}
a.radioSetCaption {
	vertical-align:baseline;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" value="#(%page.lblTitle)#" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<form id="fld">
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<hgroup id="LDAPTest" labelPosition="left" label="Username" >
<text id="LDAPTestUsername" label="" hint="Enter a Username or Username@domain.com" size="50" />
</hgroup>
<hgroup id="LDAPTest1" labelPosition="left" label="Password" >
<text inputtype="password" id="LDAPTestPassword" label="" />
<spacer width="5px"/>
<button id="TestLDAP" caption="Test" containerStyle="padding-left:2px;" onclick="zenPage.doTest();"/>
</hgroup>
<textarea id="TestResults" label="Test Results" cols="120" rows="20" readOnly="true" />
</group>
</form>
</pane>
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.hideCommandButton('btnSave');
	this.resetMsg();
	zen('LDAPTestUsername').focus();
}

/// Returning from file select OR qualifers dialog and setting the value into the appropriate field.
/// The id of the field that needs to be updated is saved in "dialogClicked".
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action == "ok") {
		zen(popupName).setValue(value);		
		zenPage.doModified();
	}
}

/// Save current item.
ClientMethod doTest() [ Language = javascript ]
{
	try {
		this.resetMsg();
		let proxy = new zenProxy();
		proxy.Username = zen('LDAPTestUsername').getValue();
		proxy.Password = zen('LDAPTestPassword').getValue();

		let TestResults = zen('TestResults')
		TestResults.setValue("Please wait, starting background process to perform LDAP authentication")
		setTimeout(() => {
			let result = zenPage.DoLDAPTest(proxy);
			TestResults.setValue(result.TestText);
		}, 0);
	} catch (ex) {
		alert("Error doTest: " + ex);
	}
}

ClassMethod DoLDAPTest(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	Try {
		s tmsg="Please wait, starting background process to perform LDAP authentication"
 		s Index=$i(^IRIS.Temp)
 		j TESTBACKGROUND1^%SYS.LDAP(pProxy.Username,pProxy.Password,Index)::5 
		i '$T {
	 		Set tmsg=tmsg_$c(13,10)_"Unable to start background process"
	 		g Exit
 		}
 		l -^LDAPTEST
 		s tmsg=tmsg_$c(13,10)_"Waiting for LDAP authentication to start"
 		h 5
 		l +^LDAPTEST
 		s Index1=""
 		f  {
	 		s Index1=$o(^IRIS.Temp(Index,Index1),1,Data) q:Index1=""
			s tmsg=tmsg_$c(13)_$c(10)_Data
 		}
Exit
		l -^LDAPTEST
 		k ^IRIS.Temp(Index)
		Set tProxy.TestText = tmsg
		Set tProxy.ok = 1
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

ClassMethod IsWindows() As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	i $$$ISWINDOWS {
		s tProxy.iswindows=1
	} else {
		s tProxy.iswindows=0
	}
	q tProxy
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Test LDAP Authentication")
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
	
	Set tPageName = $$$Text("Security LDAP Configurations")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_..EscapeURL(NAMESPACE))))
	Quit $$$OK
}

/// The test may run longer than the default timeout on the csp gateway. 
/// Increase the timeout to an hour when we press the "Test" button.
ClassMethod OnPreHyperEvent(class As %String, method As %String) As %Status [ ServerOnly = 1 ]
{
 Set %response.Timeout = 3600
 q ##super(class,method)
}

}
