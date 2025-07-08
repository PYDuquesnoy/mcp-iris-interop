/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// System Management Portal - System Administration - Edit Web Application
Class %CSP.UI.Portal.Applications.Web Extends %CSP.UI.Portal.Applications.EditTemplate [ System = 4 ]
{

///  Displayed name of this page.
Parameter PAGENAME = "Edit Web Application";

Parameter CSPURL = "/csp/sys/sec/%CSP.UI.Portal.Applications.Web.zen";

Parameter HELPADDRESS = "System Administration,Security,Applications,Web Applications";

Parameter EMSSERVICE = "Security";

Parameter PARENTPAGE = "/csp/sys/sec/%CSP.UI.Portal.Applications.WebList.zen";

Property ApplicationType As %Integer [ InitialExpression = {$$$AppTypeCSP} ];

Property IsSysApp As %Boolean [ InitialExpression = 0 ];

Property OldDefaultApp As %String;

Property UserChangedPath As %Boolean [ InitialExpression = 0 ];

Property enableWebType As %String [ InitialExpression = "REST" ];

Property PythonAppProtocol As %String [ InitialExpression = "WSGI" ];

Property NumTabs As %Integer [ InitialExpression = 4 ];

XData Style
{
<style type="text/css">
.checkboxCaption {
	color:#404040;
	font-size:12px;	    
}
.fieldHint {
    color:gray;
    font-size:12px;
    padding-left:5px;
}
/* override the image because this form is too tall */
.EditForm {
	background-image: url('');
}
.mL20 {
	padding-left: 22px;	
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane cellVAlign="top" containerStyle="padding:10px">
<label id="Text1" containerStyle="padding-bottom:4px;"/>
<label id="errmsg" hidden="true" enclosingClass="ErrorBox"/>
<label id="idRespond" enclosingClass="note" value="" hidden="true" containerStyle="padding-bottom:4px;"/>
<link id="newLink" href="%25CSP.UI.Portal.Applications.Web.zen?PID=" caption="Click here to create a new web application." hidden="true" containerStyle="padding-bottom:4px;"/>

<svgFrame id="svgTabArea" height="32" layout="none" backgroundStyle="fill:white;stroke-width:2;" frameStyle="border:none;">
<tabBar id="tabBar" tabCaptions=":General:Application Roles:Matching Roles:Cross-Origin Settings"
 onChange="zenPage.tabChangedWeb(index);"/>
</svgFrame>

<!-- Page 1: Application Edit -->
<vgroup id="page_1" hidden="true" enclosingStyle="padding-left:10px;padding-top:5px;" labelPosition="left">
<form id="fld">
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">

<!-- General settings -->
<text id="Name" label="Name" size="40" onchange="zenPage.updateCookiePath(zenThis.getValue());zenPage.doModified();" hint="Required. (e.g. /csp/appname)" title="Enter an application name using URL syntax, e.g. /csp/appname"/>
<select id="CopyApp"
label="Copy from"
onchange="zenPage.doCopyApp(zenThis.getValue());zenPage.doModified();"
title="Choose an existing application to copy"
/>
<text id="Description" label="Description" size="80" onchange="zenPage.doModified();"/>

<!-- Namespace settings -->
<hgroup id="NamespaceGroup" label="Namespace" labelPosition="left" cellStyle="padding:4px;">
<select id="NameSpace" showEmpty="false" onchange="zenPage.updateDefaultApp(zenThis.getValue());zenPage.doModified();"/>
<spacer width="5px"/>
<label id="idDefaultAppLabel" controlClass="normal" controlStyle="margin-left:5px;"/>
<spacer width="5px"/>
<checkbox id="IsNameSpaceDefault" caption="Namespace Default Application" title="Controls whether an application is its namespace's default application" onchange="zenPage.doModified();"/>
</hgroup>

<!-- Enabled services -->
<checkbox id="Enabled" label="Enable Application" title="Controls whether an application is available" value="1" onchange="zenPage.doModified();" valign="top"/>

<vgroup valign="top" label="Enable">
<radioButton id="RESTEnabled" name="CSPZENEnabled" caption="REST" captionClass="zenLabel" optionValue="REST" title="Controls whether an application supports REST calls." onclick="zenPage.doModified();zenPage.enableWebTypeChanged('REST');" />
<group labelPosition="left" enclosingClass="mL20">
<!-- Dispatch class -->
<text id="DispatchClass" label="Dispatch Class" hint="Required." title="If defined this will dispatch all requests in this Web application to this one class." size="40" onchange="zenPage.doModified();"/>
<checkbox id="RedirectEmptyPath" label="Redirect Empty Path" title="Controls whether application redirects empty paths to '/'." value="0" onchange="zenPage.doModified();"/>
<checkbox id="JWTAuthEnabled" label="Use JWT Authentication" title="Controls whether REST application supports JWT Authentication." value="0" onchange="zenPage.doModified();zenPage.JWTAuthChanged();"/>
</group>

<hgroup id="JWTGrp" align="left" labelPosition="left" enclosingClass="mL20" cellStyle="padding-right:4px;">
<text id="JWTAccessTokenTimeout" label="JWT Access Token Timeout" size="8" onchange="zenPage.doModified();" valign="top"/>
<spacer width="9px"/>
<text id="JWTRefreshTokenTimeout" label="JWT Refresh Token Timeout" size="8" onchange="zenPage.doModified();" valign="top"/>
</hgroup>

<radioButton id="WSGIEnabled" name="CSPZENEnabled" caption="WSGI [Experimental]" captionClass="zenLabel" optionValue="WSGI" title="Controls whether an application is WSGI compliant." onclick="zenPage.doModified();zenPage.enableWebTypeChanged('WSGI');" />
<group labelPosition="left" enclosingClass="mL20">
<!-- WSGI settings -->
<text id="WSGIAppName" label="Application Name" hint="This field should name the file that contains your callable WSGI application." title="WSGI App File Name" size="40" onchange="zenPage.doModified();"/>
<text id="WSGICallable" label="Callable Name" hint="Change only if you have a customized WSGI callable. If this is a django application, this field should usually be 'application' instead." title="WSGI Callable Name" size="40" value="app" onchange="zenPage.doModified();"/>
<hgroup id="WSGIPathGroup" label="WSGI App Directory" hint="The directory containing your WSGI application.">
<text id="WSGIAppLocation" size="65" title="Python Path Addition" onchange="zenPage.doModified();"/>
<button id="WSGIBrowseBtn" caption="Browse..." onclick="zenPage.doBrowse('WSGIAppLocation','*',1);"/>
</hgroup>
<hgroup id="WSGITypeSelection" label="Python Protocol Type" hint="The protocol of your WSGI application." hidden="true"> 
<radioButton id="WSGIMode" name="WSGIType" caption="WSGI" captionClass="zenLabel" optionValue="WSGI" title="Determines the protocol type." onclick="zenPage.doModified();zenPage.PythonProtocolChanged('WSGI');" />
<radioButton id="ASGIMode" name="WSGIType" caption="ASGI" captionClass="zenLabel" optionValue="ASGI" title="Determines the protocol type." onclick="zenPage.doModified();zenPage.PythonProtocolChanged('ASGI');" />
</hgroup>
<checkbox id="WSGIDebug" label="Debug" title="Controls whether a WSGI application is served in Debug mode" value="0" onchange="zenPage.doModified();" />
</group>


<radioButton id="CSPZENEnabled" name="CSPZENEnabled" caption="CSP/ZEN" captionClass="zenLabel" optionValue="CSP" title="Controls whether the application will process CSP/Zen pages." onclick="zenPage.doModified();zenPage.enableWebTypeChanged('CSP');" />
<hgroup labelPosition="left" enclosingClass="mL20" cellStyle="padding-right:4px;">
<checkbox id="DeepSeeEnabled" caption="Analytics" title="Controls whether Analytics is enabled." value="0" onchange="zenPage.doModified();"/>
<checkbox id="InbndWebServicesEnabled" caption="Inbound Web Services" title="Controls whether an application will process web services." value="1" onchange="zenPage.doModified();" valign="top"/>
<checkbox id="CSRFToken" caption="Prevent login CSRF attack" title="Generate a token and cookie in the login page that is validated before accepting any username/password. It also prevents the use of the CSPSHARE=1 URL Parameter to pass the session token in the URL when cookies are required for the application. " value="1" onchange="zenPage.doModified();" valign="top"/>
</hgroup>
</vgroup>

<!-- Security -->
<fieldSet label="Security Settings" labelPosition="left" cellStyle="padding:4px;">
<hgroup label="Resource Required" labelPosition="left">
<select id="Resource"
title="Specifies a resource for which users must have the Use permission (enabled as part of a privilege in a role) in order to run the application."
onchange="zenPage.doModified();"
/>
<spacer width="9px"/>
<text id="GroupById" label="Group By ID" title="A group of applications linked by this ID share authentication." size="40" onchange="zenPage.doModified();" controlStyle="margin-left:4px;"/>
</hgroup>
<hgroup id="AuthGroup" label="Allowed Authentication Methods" title="Specifies the available authentication mechanisms for connecting to the application." cellStyle="padding-right:4px;"/>
<text id="PermittedClasses" label="Permitted Classes" size="130" onchange="zenPage.doModified();"/>

</fieldSet>

<!-- Session settings -->
<fieldSet label="Session Settings" labelPosition="left" cellStyle="padding:4px;">
<hgroup label="Session Timeout" labelPosition="left">
<text id="Timeout" title="The default session timeout in seconds" size="10" value="900" onchange="zenPage.doModified();"/>
<label label="seconds" labelClass="fieldHint"/>
<spacer width="9px"/>
<text id="EventClass" label="Event Class" title="Specifies the default name of the event class (a subclass of %CSP.SessionEvents) whose methods are invoked for web application events, such as a timeout or session termination." size="40" onchange="zenPage.doModified();" controlStyle="margin-left:4px;"/>
<label label=".cls" labelClass="fieldHint"/>
</hgroup>
<hgroup id="CookieGroup" label="Use Cookie for Session" labelPosition="left">
<select id="UseCookies"
title="Whether you want the system to track which session a browser is in by using cookies or a URL-rewriting technique (placing a value in each URL)."
valueList="0,1,2"
displayList="Never,Autodetect,Always"
showEmpty="false"
value="2"
 onchange="zenPage.doModified();"/>
 <spacer width="9px"/>
<select id="CookiePath" label="Session Cookie Path" title="Scope of the session cookie." showEmpty="false" onchange="zenPage.doModified();" controlStyle="margin-left:4px;"/>
 <spacer width="9px"/>
<select id="SessionScope" label="Session Cookie Scope" title="Setting for cross-site transmission restrictions for CSP session cookies."
valueList="0,1,2"
displayList="None,Lax,Strict"
showEmpty="false"
value="2"
 onchange="zenPage.doModified();"/>
 <spacer width="9px"/>
<select id="UserCookieScope" label="User Cookie Scope" 
title="Default setting for cross-site restrictions for user-defined response cookies."
valueList="0,1,2"
displayList="None,Lax,Strict"
showEmpty="false"
value="2"
 onchange="zenPage.doModified();"/>
</hgroup>
</fieldSet>

<!-- CSP file settings -->
<fieldSet id="WebFileSettings" label="CSP File Settings" labelPosition="left" cellStyle="padding:4px;">
<hgroup id="ServeFilesGroup" label="Serve Files" labelPosition="left">
<select id="ServeFiles" 
title="A path from which the stream server is allowed to serve files."
valueList="0,1,2,3"
displayList="No,Always,Always and cached,Use InterSystems security"
showEmpty="false"
value="1"
 onchange="zenPage.doModified();"/>
<spacer width="9px"/>
<text id="ServeFilesTimeout" label="Serve Files Timeout" size="6" value="3600" onchange="zenPage.doModified();" controlStyle="margin-left:4px;"/>
<label label="seconds" labelClass="fieldHint"/>
</hgroup>
<hgroup id="PathGroup" label="Physical Path">
<text id="Path" size="65" title="The directory on the server as an absolute path in which .csp files and other static files are stored." onchange="zenPage.pathChanged(zenThis.getValue());zenPage.doModified();"/>
<button id="PathBrowseBtn" caption="Browse..." onclick="zenPage.doBrowse('Path','*',1);"/>
</hgroup>
<hgroup id="PackageGroup" label="Package Name" labelPosition="left">
<text id="Package" title="The name of a package prefix used by the compiler, for use when generating classes from .csp files.  This name is prepended to the package names used for these classes.  If this field is not specified, the default value of csp is used." size="40" onchange="zenPage.doModified();"/>
<spacer width="9px"/>
<text id="SuperClass" label="Default Superclass" title="The name of the superclass used by the compiler, for use when generating classes from .csp files. The default is %CSP.Page." size="40" onchange="zenPage.doModified();" controlStyle="margin-left:4px;"/>
</hgroup>
<hgroup id="CSPSettingsGroup" labelPosition="left" label="Web Settings" cellStyle="padding:4px;">
<checkbox id="Recurse" caption="Recurse" title="Specifies whether to include subdirectories within this application." value="1" onchange="zenPage.doModified();"/>
<checkbox id="AutoCompile" caption="Auto Compile" title="Specifies whether the server should automatically compile .csp source files or not." value="1" onchange="zenPage.doModified();"/>
<checkbox id="LockCSPName" caption="Lock CSP Name" title="If true, then if two web applications both point to the same namespace and package, then you can only get to the CSP page via the application which it was first loaded from." value="1" onchange="zenPage.doModified();"/>
</hgroup>
</fieldSet>

<!-- Page settings -->
<fieldSet id="CustomPages" label="Custom Pages" labelPosition="left" cellStyle="padding-right:4px;">
<hgroup id="PageGroup" labelPosition="left" label="Login Page">
<text id="LoginPage" title="Name of a custom login page to display. This can be any of the forms: /csp/user/application/mylogin.csp, mylogin.csp, /cspuser/application/mylogin.cls, application.mylogin.cls. " size="40" onchange="zenPage.doModified();"/>
<spacer width="9px"/>
<text id="ChangePasswordPage" label="Change Password Page" title="Name of page to use when changing password." size="40" onchange="zenPage.doModified();" controlStyle="margin-left:4px;"/>
</hgroup>
<text id="ErrorPage" label="Custom Error Page" title="The name of a .csp or .cls page that is displayed if an error occurs when generating a page within this application." size="40" onchange="zenPage.doModified();"/>
</fieldSet>

<!-- hidden field holds MatchRoles if creating a new app copied from an existing one -->
<hidden id="MatchRoles"/>

</group>
</form>
</vgroup>

<!-- Page 2: Application Roles -->
<vgroup id="page_2" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;" labelPosition="left">
<ApplicationRoles id="AppRoleComponent" type="ApplicationRole" PID="#(%page.PID)#" readOnly="#(%page.IsEMSReadOnly)#"/>
</vgroup>

<!-- Page 3: Match Roles -->
<vgroup id="page_3" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;" labelPosition="left">
<ApplicationRoles id="MatchRoleComponent" type="MatchRole" PID="#(%page.PID)#" readOnly="#(%page.IsEMSReadOnly)#"/>
</vgroup>

<!-- Page 4: Cross-Origin Settings -->
<vgroup id="page_4" hidden="true" enclosingStyle="padding-left:10px;padding-top:20px;" labelPosition="left">
<spacer height="10"/>
<group enclosingClass="EditForm" cellStyle="padding:4px;" labelPosition="left">
<group id="CorsComponent">
<hidden id="CorsAllowlist" value=""/>
<html id="tableCorsAllowlist" label="Allowed Origins" OnDrawContent="DrawOriginsTable" seed=""/>
<hgroup>
<text id="newOriginElement" title="Enter origins (scheme+host+port) for allowlist" size="20" onchange="zenPage.doModified();"/>
<button id="addCorsButton" caption="Add New" onclick="zenPage.doAddCors(1);" onchange="zenPage.doModified();"/>
<button id="deleteCorsButton" caption="Delete All" onclick="zenPage.deleteAllCors(1);" onchange="zenPage.doModified();"/>
</hgroup>
<hidden id="Index"/>
</group>
<spacer height="30"/>
<group id="AllowedHeadersComponent">
<hidden id="CorsHeadersList" value=""/>
<html id="tableAllowedHeader" label="Allowed Headers" OnDrawContent="DrawHeadersTable" seed=""/>
<hgroup>
<text id="newHeaderElement" title="Enter allowed headers for Access-Control-Allow-Headers" size="20" onchange="zenPage.doModified();"/>
<button id="addHeaderButton" caption="Add New" onclick="zenPage.doAddCors(2);" onchange="zenPage.doModified();"/>
<button id="deleteHeaderButton" caption="Delete All" onclick="zenPage.deleteAllCors(2);" onchange="zenPage.doModified();"/>
</hgroup>
<hidden id="HeaderIndex"/>
</group>
<spacer height="10"/>
<group>
<checkbox id="CorsCredentialsAllowed" caption="Set Access-Control-Allow-Credentials" captionClass="zenLabel" onchange="zenPage.doModified();zenPage.trimSpace(zenThis);"/>
</group>
</group>
</vgroup>
</pane>
}

/// Set focus to the Name or Description field, disable fields if DispatchClass is defined.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (!this.IsSysApp) {
		zen("Name").focus();
	} else {
		zen("Description").focus();
	}
	//var dispatchClass = zen('DispatchClass').getValue();

	//if (dispatchClass != "") {
	//	this.dispatchClassModified(dispatchClass);
	//}
	
	this.enableWebTypeChanged(this.enableWebType);
	this.PythonProtocolChanged(this.PythonAppProtocol);
	this.JWTAuthChanged();

	zen('page_1').setHidden(false);

	if (this.IsNewSave != 0) {
		this.showMsg($$$Text('Application saved.'),false);
		if (this.IsNewSave == 1) {
			var newLink = zen('newLink');
			newLink.setHidden(false);
		}
		return;
	}
	var hash = parseInt(document.location.hash.slice(1));
	if ((typeof(hash) === 'number') && (hash >= 0) && (hash <= this.NumTabs)) {
		zen('tabBar').tabClicked(hash);
	}

	this.resetMsg();
}

ClientMethod doCopyApp(newApp) [ Language = javascript ]
{
	zenPage.CopyApp(newApp);
	this.enableWebTypeChanged(this.enableWebType);
}

ClientMethod enableWebTypeChanged(value) [ Language = javascript ]
{
	this.enableWebType = value;
	this.setSubEnablers();
	if (value === 'CSP') {
		var ctl = zen('DispatchClass');
		ctl.setProperty("hintClass","helpText");
		ctl.setProperty("controlClass","");
	}
}

ClientMethod PythonProtocolChanged(value) [ Language = javascript ]
{
	this.PythonAppProtocol = value;
	if( value === "WSGI"){
		zen('WSGIMode').setValue('WSGI');
	}
	else {
		zen('ASGIMode').setValue('ASGI');
	}
}

ClientMethod JWTAuthChanged() [ Language = javascript ]
{
	var enabled = zen('JWTAuthEnabled').getValue();
	zen('JWTGrp').setHidden(!enabled);
}

ClientMethod setSubEnablers() [ Language = javascript ]
{
	var flag = (this.enableWebType === "REST");
	var flagClass = (flag) ? 'zenLabelDisabled' : 'checkboxCaption';
	if (flag) {
		zen('RESTEnabled').setValue('REST');
		zen('WSGIAppName').setHidden(true);
		zen('WSGIPathGroup').setHidden(true);
		zen('WSGICallable').setHidden(true);
		zen('WSGIDebug').setHidden(true);
		zen('WSGITypeSelection').setHidden(true);

		// enable Dispatch Class and RedirectEmptyPath when it is REST enabled
	    zen('DispatchClass').setProperty('disabled',!flag);
	    zen('RedirectEmptyPath').setProperty('disabled',!flag);
	    zen('JWTAuthEnabled').setProperty('disabled',!flag);
	    zen('JWTAccessTokenTimeout').setProperty('disabled',!flag);
	    zen('JWTRefreshTokenTimeout').setProperty('disabled',!flag);
		zen('WebFileSettings').setHidden(flag);
	} else if (this.enableWebType === "WSGI"){
		zen('WSGIEnabled').setValue('WSGI');
		zen('DispatchClass').setProperty('disabled', true);
		zen('WSGIAppName').setHidden(false);
		zen('WSGIPathGroup').setHidden(false);
		zen('WSGICallable').setHidden(false);
		zen('WSGIDebug').setHidden(false);
		// zen('WSGITypeSelection').setHidden(false);
		zen('JWTAuthEnabled').setProperty('disabled',true);
	    zen('JWTAccessTokenTimeout').setProperty('disabled',true);
	    zen('JWTRefreshTokenTimeout').setProperty('disabled',true);
		zen('RedirectEmptyPath').setProperty('disabled',true);
		zen('WebFileSettings').setHidden(false);
		zen('PackageGroup').setHidden(true);
		zen('PathGroup').setHidden(true);
		flag = true;
	} else {
		zen('WSGIAppName').setHidden(true);
		zen('WSGIPathGroup').setHidden(true);
		zen('WSGICallable').setHidden(true);
		zen('WSGIDebug').setHidden(true);
		zen('WSGITypeSelection').setHidden(true);
		zen('DispatchClass').setProperty('disabled',!flag);
	    zen('RedirectEmptyPath').setProperty('disabled',!flag);
	    zen('JWTAuthEnabled').setProperty('disabled',!flag);
	    zen('JWTAccessTokenTimeout').setProperty('disabled',!flag);
	    zen('JWTRefreshTokenTimeout').setProperty('disabled',!flag);
		zen('CSPZENEnabled').setValue('CSP');
		zen('WebFileSettings').setHidden(flag);
		zen('PackageGroup').setHidden(flag);
		zen('PathGroup').setHidden(flag);
	}

	// enable CSP related Enable checkboxes only when it is CSP/ZEN enabled 
	zen('DeepSeeEnabled').setProperty('disabled',flag);
	zen('InbndWebServicesEnabled').setProperty('disabled',flag);
	zen('CSRFToken').setProperty('disabled',flag);

	zen('DeepSeeEnabled').setProperty('captionClass',flagClass);
	zen('InbndWebServicesEnabled').setProperty('captionClass',flagClass);
	zen('CSRFToken').setProperty('captionClass',flagClass);

	// hide/show CSP related fields
	zen('PermittedClasses').setHidden(flag);
	zen('CustomPages').setHidden(flag);
}

/// Disable/enable the CSP setting fields if DispatchClass is defined/undefined. (Deprecated)
ClientMethod dispatchClassModified(newClass) [ Deprecated, Language = javascript ]
{
	var fieldArray = ['ServeFiles','ServeFilesTimeout','Path','PathBrowseBtn','Recurse','AutoCompile','LockCSPName','Package','SuperClass','ErrorPage','LoginPage','ChangePasswordPage'];
	for (var n=0; n<fieldArray.length; n++) {
		var component = zen(fieldArray[n]);
		if (newClass == "") {
			component.setProperty('disabled',false);
		} else {
			component.setProperty('disabled',true);
		}
	}
	var groupArray = ['ServeFilesGroup','PathGroup','CSPSettingsGroup','PackageGroup','PageGroup'];
	for (var n=0; n<groupArray.length; n++) {
		var component = zen(groupArray[n]);
		var lbl = component.getLabelElement();
		if (lbl) {
			if (newClass == "") {
				lbl.className = (''==component.labelClass) ? 'zenLabel' : component.labelClass;
			} else  {
				lbl.className = (''==component.labelDisabledClass) ? 'zenLabelDisabled' : component.labelDisabledClass ;
			}
		}
	}
}

/// If the user enters a path, it will not be overwritten by then choosing a CopyFrom application
ClientMethod pathChanged(newPath) [ Language = javascript ]
{
	if (newPath == "") {
		this.UserChangedPath = false;
	} else if (!this.UserChangedPath) {
		this.UserChangedPath = true;
	}
}

/// When the app name changes, redraw the cookie path options
ClientMethod updateCookiePath(newName) [ Language = javascript ]
{
	var oldSynchronousMode = zenSynchronousMode;
	zenSynchronousMode = true;
	// add a trailing slash if necessary
	if ((newName.charAt(newName.length-1)) != "/") newName = newName + "/";
	zenPage.DrawCookiePath(newName);
	zen('CookiePath').setValue(newName);
	zenSynchronousMode = oldSynchronousMode;
}

ClientMethod updateDefaultApp(newNS) [ Language = javascript ]
{
	zenPage.DrawDefaultApp(newNS);
}

ClientMethod doSave() [ Language = javascript ]
{
	if (this.isButtonDisabled("btnSave")) return;
	this.resetMsg();
	zen('newLink').setHidden(true);
	var proxy = new zenProxy();
	proxy.PID = this.PID;
	proxy.Name = zen('Name').getValue();
	proxy.NameSpace = zen('NameSpace').getValue();
	proxy.IsNameSpaceDefault = zen('IsNameSpaceDefault').getValue();
	proxy.OldDefaultApp = this.OldDefaultApp;
	proxy.EventClass = zen('EventClass').getValue();

	var ok = this.validate(proxy);
	if (!ok) return;
	
	var authArray = ['AutheUnauthenticated','AutheCache','AutheK5API','AutheDelegated','AutheLDAP','AutheLoginToken','AutheTwoFactorSMS','AutheTwoFactorPW'];
	for (var n=0; n<authArray.length; n++) {
		var component = zen(authArray[n]);
		if (typeof component !== "undefined") {
			proxy[authArray[n]] = component.getValue();
		}
	}

	proxy.AutoCompile = zen('AutoCompile').getValue();
	proxy.ChangePasswordPage = zen('ChangePasswordPage').getValue();
	proxy.CookiePath = zen('CookiePath').getValue();
	if (proxy.CookiePath == "") proxy.CookiePath = proxy.Name;
	proxy.CorsAllowlist=zen('CorsAllowlist').getValue();
	proxy.CorsCredentialsAllowed=zen('CorsCredentialsAllowed').getValue();
	proxy.CorsHeadersList=zen('CorsHeadersList').getValue();
	proxy.CSPZENEnabled = 1;
	proxy.CSRFToken = zen('CSRFToken').getValue();
	proxy.DeepSeeEnabled = (zen('DeepSeeEnabled').getValue() ? 1 : 0);
	proxy.Description = zen('Description').getValue();
	proxy.DispatchClass = (this.enableWebType === 'REST') ? zen('DispatchClass').getValue().replace(/\s+/g, '') : '';
	proxy.Enabled = zen('Enabled').getValue();
	proxy.ErrorPage = zen('ErrorPage').getValue();
	proxy.GroupById = zen('GroupById').getValue();
	proxy.LockCSPName = zen('LockCSPName').getValue();
	proxy.LoginPage = zen('LoginPage').getValue();
	proxy.Resource = zen('Resource').getValue();
	proxy.Package = zen('Package').getValue();
	proxy.Path = zen('Path').getValue();
	proxy.PermittedClasses = zen('PermittedClasses').getValue();
	proxy.Recurse = (this.enableWebType === 'REST') ? 1 : zen('Recurse').getValue();
	proxy.RedirectEmptyPath = (this.enableWebType === 'REST') ? zen('RedirectEmptyPath').getValue() : 0;
	proxy.JWTAuthEnabled = (this.enableWebType === 'REST') ? zen('JWTAuthEnabled').getValue() : 0;
	proxy.JWTAccessTokenTimeout = zen('JWTAccessTokenTimeout').getValue();
	proxy.JWTRefreshTokenTimeout = zen('JWTRefreshTokenTimeout').getValue();
	proxy.SessionScope = zen('SessionScope').getValue();
	proxy.UserCookieScope = zen('UserCookieScope').getValue();
	proxy.ServeFiles = zen('ServeFiles').getValue();
	proxy.ServeFilesTimeout = zen('ServeFilesTimeout').getValue();
	proxy.SuperClass = zen('SuperClass').getValue();
	proxy.Timeout = zen('Timeout').getValue();
	proxy.UseCookies = zen('UseCookies').getValue();
	proxy.InbndWebServicesEnabled = zen('InbndWebServicesEnabled').getValue();
	proxy.MatchRoles = zen('MatchRoles').getValue();
	proxy.ApplicationType = this.ApplicationType;

	if(this.enableWebType === 'WSGI') {
		proxy.DispatchClass = "%SYS.Python.WSGI"
		proxy.WSGIAppName = zen('WSGIAppName').getValue();
		proxy.WSGICallable = zen('WSGICallable').getValue();
		proxy.WSGIDebug = zen('WSGIDebug').getValue();
		if(this.PythonAppProtocol === "WSGI"){
			proxy.WSGIType = 1;
		} else {
			proxy.WSGIType = 2;
		}
		proxy.WSGIAppLocation = zen('WSGIAppLocation').getValue();
		proxy.Path = zen('WSGIAppLocation').getValue();
		//proxy.Framework = this.Framework;
	}
	else {
		proxy.WSGIAppName = "";
	}

	var result = this.SaveData(proxy);
	if (result.ok != 1) {
		// error case
		this.showMsg(result.ErrorMessage,true);
		return;
	}
	// result.Name is returned from SaveData
	zen('Name').setValue(result.Name);
	this.PID = result.Name;
	this.setModified(false);
	if ((proxy.PID == '') || (proxy.PID != proxy.Name)) {
		if (proxy.PID == '') {
			// new app
			var isNew = 1;
		} else {
			// renamed app
			var isNew = 2;
		}
		var url = zenLink('%25CSP.UI.Portal.Applications.Web.zen?PID='+encodeURIComponent(proxy.Name)+'&new='+isNew);
		this.gotoPage(url);
		return;
	}
	// saved existing app
	this.DrawDefaultApp(proxy.NameSpace);
	this.showMsg($$$Text('Application saved.'),false);
}

ClientMethod validate(proxy) As %Boolean [ Language = javascript ]
{
	var pass = true;
	try {
		var oldSynchronousMode = zenSynchronousMode;
		zenSynchronousMode = true;
		if (!this.validateRequired(zen('Name'),pass,"S")) pass = false;
		if (this.enableWebType == 'REST') {
			// make sure Dispatch Class is defined
			if (!this.validateRequired(zen('DispatchClass'),pass,"S")) pass = false;
		}
		if (this.enableWebType === 'WSGI') {
			var result = this.ValidateWSGI(this.PythonAppProtocol);
			if (result.failed == 1) {
				if (this.PythonAppProtocol === 'ASGI') {
					if (result.atowsgi == 0) {
						alert("Unable to find a2wsgi, make sure to install it with pip in order to use ASGI");
					}
					else if (result.FastAPI == 0) {
						alert("Unable to find FastAPI, make sure to install it with pip in order to use ASGI");
					}
				}
				else {
					alert("Unable to find a WSGI framework, make sure to install one (flask, django) with pip in order to use WSGI");
				}
			}
			// make sure WSGI-compliant App Name is defined
			if (!this.validateRequired(zen('WSGIAppName'),pass,"S")) pass = false;
		}
		if (!pass) {
			this.afterValidate();
			zenSynchronousMode = oldSynchronousMode;
			return pass;
		}
		zenSynchronousMode = oldSynchronousMode;
		
		if (proxy.Name.charAt(0) != "/") {
			zen('Name').focus();
			this.showMsg($$$Text("Please enter a valid Name using URL syntax."),1);
			return false;
		}

        if (/^\/csp\/[-_%\d\p{L}]{1,64}\/(images|portal|deepsee)(\/.*)?$/iu.test(proxy.Name)) {
            zen('Name').focus();
			this.showMsg($$$Text("Name cannot be of the format /csp/{namespace}/(portal|images|deepsee)"),1);
			return false;
        }
		
		if ((proxy.PID != '') && (proxy.PID != proxy.Name)) {
			var warn = zenPage.GiveRenameWarning(proxy.PID,proxy.NameSpace);
			var msg = $$$Text("Are you sure you want to rename this web application?");
			if (warn) {
				if (zenPage.IsEnsembleNamespace(proxy.NameSpace)) {
					msg = msg + "\n\n" + $$$Text("WARNING: You will no longer be able to run Interoperability or Analytics in this namespace.");
				} else {
					msg = msg + "\n\n" + $$$Text("WARNING: You will no longer be able to run Analytics in this namespace.");
				}
			}
			if (!confirm(msg)) {
				return false;
			}
		}
		
		if ((proxy.IsNameSpaceDefault) && (proxy.OldDefaultApp != "") && (proxy.OldDefaultApp != proxy.Name)) {
			var msg = $$$Text("You are changing the default application for namespace %1 to %2. Are you sure you want to do this?");
			msg = msg.replace("%1",proxy.NameSpace);
			msg = msg.replace("%2",proxy.Name);
			msg = msg + "\n\n" + $$$Text("Click OK to continue or Cancel to abort the Save.");
			if (!confirm(msg)) {
				return false;
			}
		}
		
		if (proxy.EventClass) {
			// remove ".cls" if user entered it
			if (proxy.EventClass.toLowerCase().slice(-4) === ".cls") {
				proxy.EventClass = proxy.EventClass.slice(0,-4);
				zen("EventClass").setValue(proxy.EventClass);
			}
			// check if class exists, if not, give warning
			var ok = this.CheckEventClass(proxy.EventClass, proxy.NameSpace);
			if (!ok) {
				pass = confirm($$$Text("Event class does not currently exist. Save anyway?")); 
			}
		}
		
	} catch (ex) {
		alert("Error: " + ex);	
	}
	
	return pass;
}

/// Evaluate whether changing the name of this web app will cause Interoperability and Analytics to become unusable in this namespace
/// based on whether the instance is Interoperability or Analytics enabled and whether this app is the one with a name matching the namespace name
Method GiveRenameWarning(PID As %String, pNamespace As %String) As %Boolean [ ZenMethod ]
{
	Quit:(pNamespace="%SYS")||(pNamespace="DOCBOOK") 0
	Quit:('##class(%Library.EnsembleMgr).IsEnsembleInstalled()&&'($$$comClassDefined("%DeepSee.Utils")&&##class(%DeepSee.Utils).%IsDeepSeeEnabled())) 0
	Quit (PID = $$getDefaultApp^%SYS.cspServer2(pNamespace,1,##class(%Library.EnsembleMgr).IsHealthShareNamespace(pNamespace)))
}

Method IsEnsembleNamespace(pNamespace) As %Boolean [ CodeMode = expression, ZenMethod ]
{
##class(%Library.EnsembleMgr).IsEnsembleNamespace(pNamespace)
}

ClassMethod GetDefaultApp(Nsp As %String) As %String [ ZenMethod ]
{
	Set app = ""
	Set DefApp = $System.CSP.GetDefaultApp(Nsp)
	Set tSC = ##class(Security.Applications).Get(DefApp,.Properties)
	If $$$ISOK(tSC) && ($Get(Properties("IsNameSpaceDefault"),0) = 1) {
		Set app = DefApp
	}
	Quit app
}

Method DrawDefaultApp(Nsp As %String) [ ZenMethod ]
{
	Set appComp = ..%GetComponentById("idDefaultAppLabel")
	Set ..OldDefaultApp = ..GetDefaultApp(Nsp)
	If (..OldDefaultApp '= "") {
		Set appComp.label = $$$FormatText($$$Text("Default Application for %1"),Nsp)_":"
		Set appComp.value = ..OldDefaultApp
	} Else {
		Set appComp.label = ""
		Set appComp.value = ""
	}
}

Method DrawCookiePath(Name As %String) [ ZenMethod ]
{
	Set cpath = Name_$S($E(Name,$L(Name))'="/":"/",1:"")
	Set displayList = "/"
	Set valueList = "/"
	Set cp = 2
	Set thiscp = $P(cpath,"/",cp)
	Set lastcp = "/"
	While thiscp '= "" {
		Set lastcp = lastcp_thiscp_"/"
		Set displayList = displayList_","_..EscapeHTML(lastcp)
		Set valueList = valueList_","_lastcp
		Set cp = cp + 1
		Set thiscp = $P(cpath,"/",cp)
	}
	Set ..%GetComponentById("CookiePath").displayList = displayList
	Set ..%GetComponentById("CookiePath").valueList = valueList
}

Method CopyApp(AppName As %String) As %Status [ ZenMethod ]
{
	Set tSC = ##class(Security.Applications).Get(AppName,.Properties)
	If $$$ISERR(tSC) Quit tSC
	Set AutheArray = ..BuildAutheArray()
	Do ..PopulateFields(1,.Properties,AutheArray)
	Quit $$$OK
}

/// Validate dependencies for a WSGI app
Method ValidateWSGI(protocol As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()
	If protocol = "ASGI" {
		Try {
			Do ##Class(%SYS.Python).Import("a2wsgi")
		}
		Catch exception {
			Set tProxy.failed = 1
			Set tProxy.atowsgi = 0
		}
		Try {
			Do ##Class(%SYS.Python).Import("fastapi")
		}
		Catch exception {
			Set tProxy.failed = 1
			Set tProxy.FastAPI = 0
		}
	}
	else {
		Try {
			Do ##Class(%SYS.Python).Import("flask")
		}
		Catch exception {
			Set tProxy.flask = 0
		}
		Try {
			Do ##Class(%SYS.Python).Import("django")
		}
		Catch exception {
			Set tProxy.django = 0
		}
		if (tProxy.django = 0) && (tProxy.flask = 0) {
			Set tProxy.failed = 1
		}
	}
	Quit tProxy
}

/// Call server save method.
ClassMethod SaveData(pProxy As %ZEN.proxyObject) As %ZEN.proxyObject [ ZenMethod ]
{
	#; Initialize return proxy object
	Set tProxy = ##class(%ZEN.proxyObject).%New()

	Try {
		Set AutheEnabled = 0
		
		If (pProxy.AutheUnauthenticated) Set AutheEnabled = AutheEnabled + $$$AutheUnauthenticated
		If (pProxy.AutheCache) Set AutheEnabled = AutheEnabled + $$$AutheCache
		If (pProxy.AutheK5API) Set AutheEnabled = AutheEnabled + $$$AutheK5API
		If (pProxy.AutheDelegated) Set AutheEnabled = AutheEnabled + $$$AutheDelegated
		If (pProxy.AutheLDAP) Set AutheEnabled = AutheEnabled + $$$AutheLDAP
		If (pProxy.AutheLoginToken) Set AutheEnabled = AutheEnabled + $$$AutheLoginToken
		If (pProxy.AutheTwoFactorPW) Set AutheEnabled = AutheEnabled + $$$AutheTwoFactorPW
		If (pProxy.AutheTwoFactorSMS) Set AutheEnabled = AutheEnabled + $$$AutheTwoFactorSMS

		Set Properties("AutheEnabled") = AutheEnabled
		Set Properties("AutoCompile") = pProxy.AutoCompile
		Set Properties("ChangePasswordPage") = pProxy.ChangePasswordPage
		Set Properties("CookiePath") = pProxy.CookiePath
		Set Properties("CorsAllowlist") = pProxy.CorsAllowlist
		Set Properties("CorsCredentialsAllowed") = pProxy.CorsCredentialsAllowed 
		Set Properties("CorsHeadersList") = pProxy.CorsHeadersList
		Set Properties("CSPZENEnabled") = pProxy.CSPZENEnabled
		Set Properties("CSRFToken") = pProxy.CSRFToken
		Set Properties("DeepSeeEnabled") = pProxy.DeepSeeEnabled
		Set Properties("Description") = pProxy.Description
		Set Properties("DispatchClass") = pProxy.DispatchClass
		Set Properties("Enabled") = pProxy.Enabled
		Set Properties("ErrorPage") = pProxy.ErrorPage
		Set Properties("EventClass") = pProxy.EventClass
		Set Properties("GroupById") = pProxy.GroupById
		Set Properties("iKnowEnabled") = pProxy.DeepSeeEnabled
		Set Properties("InbndWebServicesEnabled") = pProxy.InbndWebServicesEnabled
		Set Properties("IsNameSpaceDefault") = pProxy.IsNameSpaceDefault
		Set Properties("LockCSPName") = pProxy.LockCSPName
		Set Properties("LoginPage") = pProxy.LoginPage
		Set Properties("NameSpace") = pProxy.NameSpace
		Set Properties("Package") = pProxy.Package
		Set Properties("Path") = pProxy.Path
		Set Properties("PermittedClasses") = pProxy.PermittedClasses
		Set Properties("Recurse") = pProxy.Recurse
		Set Properties("RedirectEmptyPath") = pProxy.RedirectEmptyPath
		Set Properties("JWTAuthEnabled") = pProxy.JWTAuthEnabled
		If pProxy.JWTAuthEnabled {
			Set Properties("JWTAccessTokenTimeout")=pProxy.JWTAccessTokenTimeout
			Set Properties("JWTRefreshTokenTimeout")=pProxy.JWTRefreshTokenTimeout
		}
		Set Properties("Resource") = pProxy.Resource
		Set Properties("SessionScope") = pProxy.SessionScope
		Set Properties("UserCookieScope") = pProxy.UserCookieScope
		Set Properties("ServeFiles") = pProxy.ServeFiles
		Set Properties("ServeFilesTimeout") = pProxy.ServeFilesTimeout	
		Set Properties("SuperClass") = pProxy.SuperClass
		Set Properties("Timeout") = pProxy.Timeout
		Set Properties("UseCookies") = pProxy.UseCookies
		Set Properties("WSGIAppName") = pProxy.WSGIAppName
		Set Properties("WSGICallable") = pProxy.WSGICallable
		Set Properties("WSGIAppLocation") = pProxy.WSGIAppLocation
		Set Properties("WSGIDebug") = pProxy.WSGIDebug
		Set Properties("WSGIType") = pProxy.WSGIType
		//Set Properties("Framework") = pProxy.Framework
		
		Set Properties("Type") = pProxy.ApplicationType
		Set tApplication = pProxy.Name
		
		// %SYS.cspServer methods requires "/" on both end of the application name.
		If $E(tApplication,1)'="/" {
			Set tApplication = "/" _ pProxy.Name
		}
		If $E(tApplication,*)'="/" {
			Set tApplication = pProxy.Name _ "/"
		}
		Set AnalyticsChanged = ($$IsDeepSeeEnabled^%SYS.cspServer(tApplication) '= pProxy.DeepSeeEnabled)
		If pProxy.PID = "" {
			Set Properties("MatchRoles") = pProxy.MatchRoles
			Set tSC = ##class(Security.Applications).Create(pProxy.Name,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		} Else {
			//If this is a rename, create new one and delete old one
			If pProxy.PID '= pProxy.Name {
				Set tSC = ##class(Security.Applications).Create(pProxy.Name,.Properties)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
				Set tSC = ##class(Security.Applications).Delete(pProxy.PID)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			} Else {
				// Save the modification to application
				Kill Properties("Type")
				Set tSC = ##class(Security.Applications).Modify(pProxy.Name,.Properties)
				If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
			}
		}

		/// If user is CHANGING the default application from another application to this one for the namespace,
		/// reset the other application's flag to zero.
		If ((pProxy.IsNameSpaceDefault = 1) && (pProxy.OldDefaultApp '= "") && (pProxy.OldDefaultApp '= pProxy.PID)) {
			Kill Properties
			Set Properties("IsNameSpaceDefault") = 0
			Set tSC = ##class(Security.Applications).Modify(pProxy.OldDefaultApp,.Properties)
			If $$$ISERR(tSC) throw ##Class(%Exception.StatusException).CreateFromStatus(tSC)
		}
#;The format of the name may have been modified, get and display the modified value
		Set tSC = ##class(Security.Applications).Get(pProxy.Name,.Properties)
		Set tProxy.Name=$g(Properties("Name"),pProxy.Name)
		Set tProxy.ok = 1
		If (AnalyticsChanged) {
			Do EnableDeepSee^%SYS.cspServer(tApplication, +Properties("DeepSeeEnabled"))
			Do EnableIKnow^%SYS.cspServer(tApplication,+Properties("DeepSeeEnabled"))
		}
	} Catch Error {
		Set tProxy.ok = 0
		Set tProxy.ErrorMessage = ..EvalResult(Error.AsStatus())
	}
	Quit tProxy
}

/// Build a list of available authentication types
ClassMethod BuildAutheArray() As %ListOfDataTypes
{
	Set tSC = ##class(Security.System).Get($$$SystemSecurityName,.SysProperties)
	Set SysAutheEnabled = +SysProperties("AutheEnabled")
	
	Set AutheArray = ##class(%ListOfDataTypes).%New()
	If $zb(SysAutheEnabled,$$$AutheUnauthenticated,1) Do AutheArray.Insert("AutheUnauthenticated^"_$$$AutheUnauthenticated_"^"_$$$AutheUnauthenticatedStr)
	If $zb(SysAutheEnabled,$$$AutheCache,1) Do AutheArray.Insert("AutheCache^"_$$$AutheCache_"^"_$$$AutheCacheStr)
	If $zb(SysAutheEnabled,$$$AutheK5API,1) Do AutheArray.Insert("AutheK5API^"_$$$AutheK5API_"^"_$$$AutheK5APIStr)
    If $zb(SysAutheEnabled,$$$AutheDelegated,1) Do AutheArray.Insert("AutheDelegated^"_$$$AutheDelegated_"^"_$$$AutheDelegatedStr)
    If $zb(SysAutheEnabled,$$$AutheLDAP,1) Do AutheArray.Insert("AutheLDAP^"_$$$AutheLDAP_"^"_$$$AutheLDAPStr)
    If $zb(SysAutheEnabled,$$$AutheTwoFactorPW,1) Do AutheArray.Insert("AutheTwoFactorPW^"_$$$AutheTwoFactorPW_"^"_$$$AutheTwoFactorPWStr)
    If $zb(SysAutheEnabled,$$$AutheTwoFactorSMS,1) Do AutheArray.Insert("AutheTwoFactorSMS^"_$$$AutheTwoFactorSMS_"^"_$$$AutheTwoFactorSMSStr)
	If $zb(SysAutheEnabled,$$$AutheLoginToken,1) Do AutheArray.Insert("AutheLoginToken^"_$$$AutheLoginToken_"^"_$$$AutheLoginTokenStr)
	Quit AutheArray
}

/// Fill in form fields. Used when loading the page for edit or when choosing a copy from app during creation
Method PopulateFields(CopyApp As %Boolean, ByRef Properties As %String, AutheArray As %ListOfDataTypes) As %Status
{
	// If copying an existing application, don't try to make this one the NS default
	If (CopyApp) {
		Set Properties("IsNameSpaceDefault") = 0
	}

	If ($G(Properties("WSGIAppName")) '= "") {
		Set ..enableWebType = "WSGI"
		Set type = $G(Properties("WSGIType"))
		if type = 1 {
			set ..PythonAppProtocol = "WSGI"
		} else {
			set ..PythonAppProtocol = "ASGI"
		}
		//set ..Framework = $G(Properties("Framework"))
	}
	
	// Loop to set all field values
	Set tProperty = ""
	Set tProperty = $O(Properties(tProperty)) 
	While tProperty '= ""  {
		If CopyApp, tProperty = "Name" Set tProperty = $O(Properties(tProperty)) Continue ##; Don't copy the name
		Set Component = ..%GetComponentById(tProperty)
		If $ISO(Component) {
			If ('CopyApp || (tProperty '= "Path") || '..UserChangedPath) {
				Set Component.value = Properties(tProperty)
			}
			If ..IsEMSReadOnly Set Component.disabled = 1
		}
		Set tProperty = $O(Properties(tProperty)) 
	}
	
	Do ..DrawDefaultApp(Properties("NameSpace"))

	// Populate CORS allowlist table and CORS headers table
	Set ..%GetComponentById("tableCorsAllowlist").seed=Properties("CorsAllowlist")
	Set ..%GetComponentById("tableAllowedHeader").seed=Properties("CorsHeadersList")
	Set ..%GetComponentById("CorsAllowlist").value=Properties("CorsAllowlist")
	Set ..%GetComponentById("CorsHeadersList").value=Properties("CorsHeadersList")
	
	// Set values for the authentication options
	Set AutheLDAP = 0
	Set key = ""
	Do {
		Set Authe = AutheArray.GetNext(.key)
		If (Authe '= "") {
			Set comp = ..%GetComponentById($P(Authe,"^",1))
			Set b = +$P(Authe,"^",2)
			Set comp.value = ($zb(+Properties("AutheEnabled"),b,1) = b)
			
			If ((comp.id = "AutheLDAP") && (comp.value = 1)) {
				Set AutheLDAP = 1
			}
	    }
	} While (key '= "")
	If (..PID '= "") || CopyApp {
		If ($G(Properties("DispatchClass")) '= "") {
			If ($G(Properties("WSGIAppName")) '= "") {
				Set ..enableWebType = "WSGI"
			}
			Else {
				Set ..enableWebType = "REST"
			}
		} Else {
			Set ..enableWebType = "CSP"
		}
	}
	Quit $$$OK
}

Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	// Populate the Resource dropdown
	Set tRS = ##class(%ResultSet).%New("Security.Resources:List")
	Do tRS.Execute(,,$$$ServiceResourceType+$$$ApplicationResourceType+$$$UserResourceType)
	Set valueList = ""
	While tRS.Next() {
		Set name = tRS.GetData(1)
		If valueList = "" {
			Set valueList = name
		} Else {
			Set valueList = valueList_","_name
		}
	}
	Set (..%GetComponentById("Resource").displayList,..%GetComponentById("Resource").valueList) = valueList
	Set ..%GetComponentById("PermittedClasses").title = $$$Text("Only permit classes matching this COS pattern to run in application, e.g. ""myservice"" only permits ""myservice.cls""")

	// Populate the Namespace dropdown
	Set tType = 4   		// 4 - Returns array of all namespaces
	Set tRemote = 1 		// 1 - Return remote namespaces as well
	Set tDontConnect = 1	// 1 - Do not attempt to connect 
	Do List^%SYS.NAMESPACE(.Namespaces,tType,tRemote,tDontConnect)
	Set nms = $O(Namespaces(""))
	Set valueList = ""
  	While nms '= "" {
	  	If valueList = "" {
			Set valueList = nms
		} Else {
			Set valueList = valueList_","_nms
		}
	  	Set nms = $O(Namespaces(nms))
  	}
  	Set (..%GetComponentById("NameSpace").displayList,..%GetComponentById("NameSpace").valueList) = valueList
  	
  	// Draw the Authentication Options checkboxes
	Set AutheArray = ..BuildAutheArray()
	Set key = ""
	Do {
		Set Authe = AutheArray.GetNext(.key)
		If (Authe '= "") {
			Kill comp
			Set comp = ##class(%ZEN.Component.checkbox).%New()
			Set comp.id = $P(Authe,"^",1)
			Set comp.caption = $P(Authe,"^",3)
			Set comp.onchange = "zenPage.doModified();"
			If comp.id = "AutheLoginToken" {
				Set comp.title = $$$Text("When entering this application for the first time, the system will attempt to use the authentication of the more recently logged in user.")
			}
			If ..IsEMSReadOnly {
				Set comp.disabled = 1
			}
			Do ..%GetComponentById("AuthGroup").%AddChild(comp)
	    }
	} While (key '= "")
	
	// Set up the Cookie Path select options
	Do ..DrawCookiePath(..PID)

	If ..PID = "" {
		// Creating new application
		Set ..%GetComponentById("Text1").value = $$$TextHTML("Use the following form to create a new web application:")
		Set ..%GetComponentById("svgTabArea").hidden = 1
		Set ..%GetComponentById("svgTabArea").height = 0
		
		Set ..%GetComponentById("NameSpace").value = "USER"
		
		Do ..DrawDefaultApp("USER")
		
		If $ISO(..%GetComponentById("AutheUnauthenticated")) {
			Set ..%GetComponentById("AutheUnauthenticated").value = 1
		}
		
		// Populate the Copy From dropdown
		Set tRS = ##class(%ResultSet).%New("Security.Applications:List")
		Do tRS.Execute("*",$$$AppTypeCSP,"")
		Set valueList = ""
		While tRS.Next() {
			Set name = tRS.GetData(1)
			If valueList = "" {
				Set valueList = name
			} Else {
				Set valueList = valueList_","_name
			}
		}
		Set ..%GetComponentById("JWTAccessTokenTimeout").value = 60
		Set ..%GetComponentById("JWTRefreshTokenTimeout").value = 900

		Set (..%GetComponentById("CopyApp").displayList,..%GetComponentById("CopyApp").valueList) = valueList
	} Else {
		// Editing existing application
		Set ..EditHeader = $$$FormatText($$$Text("Edit definition for web application %1:"),..PID)
		Set ..RolesHeader = $$$FormatText($$$Text("Edit roles for web application %1:"),..PID)
		Set ..%GetComponentById("Text1").value = ..EditHeader
		
		Kill Properties
		Set tSC = ##class(Security.Applications).Get(..PID,.Properties)
		If $$$ISERR(tSC) {
			Set ..%GetComponentById("fld").hidden = 1
			Set ..InvalidParam = 1
			Set ..%GetComponentById("svgTabArea").hidden = 1
			Set ..%GetComponentById("svgTabArea").height = 0
			Quit $$$OK
		}
		Set ..IsSysApp = ($ZB($$$AppTypeSystem,+Properties("Type"),1) = 1)
		Set ..%GetComponentById("Name").value = ..PID

		If (..IsSysApp) {
			Set ..%GetComponentById("Name").disabled = 1
			Set ..%GetComponentById("Name").hint = ""
		}
		
		Set ..%GetComponentById("CopyApp").hidden = 1
		Set ..%GetComponentById("CopyApp").containerStyle = "padding:0;"
		
		// Set the DeepSee, iKnow enabled checkboxes
		Set appName = ..PID _ "/"
		Set DeepSeeEnabled = $$IsDeepSeeEnabled^%SYS.cspServer(appName)
		Set iKnowEnabled = $$IsIKnowEnabled^%SYS.cspServer(appName)
		If (DeepSeeEnabled && iKnowEnabled){
			Set ..%GetComponentById("DeepSeeEnabled").value = 1
		} else {
			Set ..%GetComponentById("DeepSeeEnabled").value = 0
			Set (Properties("DeepSeeEnabled"),Properties("iKnowEnabled")) = 0
		}
		Do ..PopulateFields(0,.Properties,AutheArray)
	}

	If ..IsEMSReadOnly {
		Set ..%GetComponentById("Name").disabled = 1
		Set ..%GetComponentById("PathBrowseBtn").disabled = 1
	}

	Quit $$$OK
}

///  Return the array of links to show in the locator bar.<br/>
///  pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Set NAMESPACE = $G(%session.Data("$NAMESPACE"))
	Set tPageName = $$$Text("System","%Utility")
	Set tURL = ..Link($$$GetHomePage)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Security Management","%Utility")
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = $$$Text("Web Applications","%Utility")
	Set tURL = ..Link(..ParentURL)
	Set pLink($I(pLink)) = $LB(tPageName,tURL)

	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT($className(),"O","URL")_".zen?PID="_..EscapeURL(..PID)_$S(NAMESPACE="":"",1:"&$NAMESPACE="_NAMESPACE)))
	
	Quit $$$OK
}

/// Get the (localized) name of the page.
///  This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Edit Web Application")
}

ClassMethod CheckEventClass(pClassName, pNamespace) As %Boolean [ ZenMethod ]
{
	New $Namespace
	Set $Namespace = pNamespace	
	Quit ##class(%Dictionary.ClassDefinition).%ExistsId(pClassName)
}

/// Get the title string to add to the locator row.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return $$$Text("security settings");
}

/// Wrap the tabChanged() method from %CSP.UI.Portal.Applications.EditTemplate so that the Save button is also usable for the fourth tab
ClientMethod tabChangedWeb(index) [ Language = javascript ]
{
	this.tabChanged(index);
    if (index == 3) {
        this.enableCommandButton("btnSave");
        zen('Text1').setValue(this.EditHeader);
    }
}

/// pSeed holds all the origins to be displayed, separated by ";". This method draws the CORS origins allowlist table and the CORS header tables from the seed. Returns $$$OK when successful. pType=1 means this method is drawing the CORS origins allowlist. pType=2 means this method is drawing the CORS headers table.
Method DrawCorsTable(pType, pSeed As %String) As %Status
{
 	Set totalElements = $SELECT(pSeed="":0,1:$LENGTH(pSeed,","))

	&html<<table class="DetailTable"><thead></thead>>
	For i = 1:1:totalElements {
		Set AllElements(i) = $PIECE(pSeed,",",i)
		Set element = ##class(%CSP.Page).EscapeHTML(AllElements(i))
		Set rowClass = $SELECT(i#2:"rowOdd",1:"rowEven")
		&html<<tbody><tr class="#(rowClass)#">>
		&html<<td>#(element)#</td>>
		&html<<td nowrap style="text-align:left;">>
		&html<->
		&html<</td>>
		Set deleteIndex=i-1 // Off by one because Javascript starts counting at 0
		&html<<td style="text-align:left;"><a href="#" onclick="zenPage.deleteCors('#(pType)#','#(deleteIndex)#')"  class="link">#($$$Text("Delete"))#</a></td>>
		&html<</tr>>
		Set addRowClass = $SELECT(totalElements#2:"rowEven",1:"rowOdd")
	}
	If totalElements = 0 {
		&html<<tr class="rowOdd"><td colspan="4" style="text-align:center;">#($$$Text("None defined"))#.</td></tr></tbody>>
		Set addRowClass = "rowEven"
	}
	Set rowClass = $SELECT(totalElements#2:"rowEven",1:"rowOdd")
	&html<</td>> 
	&html<</table>>
	Quit $$$OK
}

/// pSeed holds all the origins to be displayed, separated by ";". This method is called by content pane and draws the CORS origins table from the seed. Returns $$$OK when successful.
Method DrawOriginsTable(pSeed As %String) As %Status
{
	Set sc=..DrawCorsTable(1,pSeed) // pass in 1 to specify this is the origins table
	Quit sc
}

/// pSeed holds all the headers to be displayed, separated by ";". This method is called by content pane and draws the CORS headers table from the seed. Returns $$$OK when successful.
Method DrawHeadersTable(pSeed As %String) As %Status
{
	Set sc=..DrawCorsTable(2,pSeed) // pass in 2 to specify this is the headers table
	Quit sc
}

/// doAddCors is called when user wants to add an entry to the CORS origins allowlist or CORS headers table. pType=1 means this method is adding to the CORS origins allowlist. pType=2 means this method is adding to the CORS headers table.
ClientMethod doAddCors(pType) [ Language = javascript ]
{
	if (pType==1) {
		var Prompt="Please enter a new allowed incoming origin:";
		var ListName = 'CorsAllowlist';
		var TableName = 'tableCorsAllowlist';
		var textElementName = 'newOriginElement'
	} else {
		var Prompt="Please enter a new allowed header:";
		var ListName = 'CorsHeadersList';
		var TableName = 'tableAllowedHeader';
		var textElementName = 'newHeaderElement';
	}
	var newElement = zen(textElementName).getValue();
	if (newElement) {
		var allowlist = zen(ListName).getValue();
		// for CORS origins allowlist and for CORS headers table, do not allow repeated elements
		var st = zenPage.ValidateNoRepeats(newElement, allowlist);
		// for CORS origins allowlist only, check that origin is properly structured
		if ((pType == 1) && (st == 1)) {
			var st = zenPage.ValidateOrigin(newElement)
		}
		if (st == 1) {
			if (allowlist == "") {
				zen(ListName).setValue(newElement);
			} else {
				zen(ListName).setValue(allowlist+','+newElement);
			}
			var table = zen(TableName);
			table.setProperty('seed',zen(ListName).getValue());
			table.refreshContents();
		} else {
			zen(textElementName).focus()
			this.showMsg(st,true);
		}
	}
}

/// deleteCors removes one element from CORS table and updates the table. Type=1 means this method is deleting from the CORS origins allowlist. pType=2 means this method is deleting from the CORS headers table. DeleteIndex is the index of the table to delete; this value starts counting at 0.
ClientMethod deleteCors(pType,  DeleteIndex) [ Language = javascript ]
{
	if (pType==1) {
		var ListName = 'CorsAllowlist';
		var TableName = 'tableCorsAllowlist';
	} else {
		var ListName = 'CorsHeadersList';
		var TableName = 'tableAllowedHeader';
	}
	var allowlist = zen(ListName).getValue().split(',');
	allowlist.splice(DeleteIndex,1);
	var newList = allowlist.join(',');
	zen(ListName).setValue(newList);
	var table = zen(TableName);
	table.setProperty('seed',zen(ListName).getValue());
	table.refreshContents();
}

/// deleteAllCors removes all elements from a CORS table and updates the table. pType=1 means this method is deleting from the CORS origins allowlist. pType=2 means this method is deleting from the CORS headers table. 
ClientMethod deleteAllCors(pType) [ Language = javascript ]
{
	if (pType==1) {
		var ListName = 'CorsAllowlist';
		var TableName = 'tableCorsAllowlist';
	} else {
		var ListName = 'CorsHeadersList';
		var TableName = 'tableAllowedHeader';
	}
	zen(ListName).setValue('');
	var table = zen(TableName);
	table.setProperty('seed','');
	table.refreshContents();
}

/// ValidateNoRepeats checks that the new element is not a repeat. newElement is the new entry. allowlist is a string of all the elements, separated by ";". Return 1 for a good new element or an error message for a bad new element.
ClientMethod ValidateNoRepeats(newElement,  allowlist) As %String [ Language = javascript ]
{
	var list=allowlist.split(',');
	var found=list.find((element)=>element==newElement);
	if (found == undefined) {
		var tmsg=1;
	} else {
		var tmsg=$$$FormatText('ERROR Duplicate Element: %1', newElement);
	}
	return tmsg;
}

/// ValidateOrigin checks that the new origin is a valid origin with proper schema, host, and port. newOrigin is the new entry. Return $$$OK for a good origin or an error message for a bad origin.
ClassMethod ValidateOrigin(newOrigin As %String) As %String [ ZenMethod ]
{
	Set sc = ##class(Security.Applications).ValidateCorsOrigin(##class(%CSP.Page).EscapeHTML(newOrigin))
	If $$$ISERR(sc) {
		Quit $SYSTEM.Status.GetErrorText(sc)
	} 
	Quit sc
}

}
