/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Login page with password change.
Class %CSP.PasswordChange Extends %CSP.Login [ System = 4 ]
{

/// Login page localization domain
Parameter DOMAIN = "%UtilityPasswordChange";

/// Output the default login page as HTML
ClassMethod OnPage() As %Status
{
	// text strings
	Set ConfigName = $P($zu(86),"*",2)
	// get key, lookup in localization global
	Set lang = $get(^%SYS("LANGUAGE","CURRENT"),"en")
	Set title = $$FormatText^%occMessages($$$GetSysMessage(lang,..#DOMAIN,"logintitle","Password Change %1"),ConfigName)
	Set prompt = $$$GetSysMessage(lang,..#DOMAIN,"loginenter","Please enter your user name and existing password and new password to change passwords and login")
	Set userName = $$$GetSysMessage(lang,..#DOMAIN,"loginusername","User Name")
	Set password = $$$GetSysMessage(lang,..#DOMAIN,"loginpassword","Password")
	Set passwordrepeat = $$$GetSysMessage(lang,..#DOMAIN,"loginpasswordrepeat","Retype Password")
	Set oldpassword  = $$$GetSysMessage(lang,..#DOMAIN,"loginoldpassword","Old Password")
	Set login = $$$GetSysMessage(lang,..#DOMAIN,"login","Login")
	Set logout = $$$GetSysMessage(lang,..#DOMAIN,"loginlogout","You are logged out")
	Set usernameneeded = $$$GetSysMessage(lang,..#DOMAIN,"usernameneeded","Provide a username")
	Set passwordmatch = $$$GetSysMessage(lang,..#DOMAIN,"passwordmatch","New password fields do not match")
	Set differentpassword = $$$GetSysMessage(lang,..#DOMAIN,"differentpassword","Must pick a new password different from old one")
	&html<<html>>

	Do ..DrawHEAD(title)
	
	// js functions
	&html<<script language="javascript">
// called when page is loaded
function pageLoad()
{
	// see if we can give focus to the UserName field:
	if (self.document.Login && self.document.Login.IRISUsername) {
		self.document.Login.IRISUsername.focus();
		self.document.Login.IRISUsername.select();
	}

	return true;
}

function validateSubmit()
{
	if (self.document.Login.IRISUsername.value == '') {
		alert('#(usernameneeded)#');
		self.document.Login.IRISUsername.select();
		return false;
	}
	if (self.document.Login.IRISPassword.value != self.document.getElementById('IRISRepeatPassword').value) {
		alert('#(passwordmatch)#');
		self.document.Login.IRISPassword.select();
		return false;
	}
	if (self.document.Login.IRISPassword.value == self.document.Login.IRISOldPassword.value) {
		alert('#(differentpassword)#');
		self.document.Login.IRISPassword.select();
		return false;
	}
	return true;
}

	</script>>
 
 &html<</head>
 	<body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0" onload="pageLoad();">
 	>
 
	Do ..DrawTitle(title)

	// Show standard login form
 	&html<<table border="0" align="center">
 	<tr>
	<td colspan="10" align="center">
 	<table border="0" class="LayoutMain" width="100%" cellpadding="0" cellspacing="0">
 	<tr><td class="LayoutContentCol" width="80%" align="left"><br>
	<div class="Text1" style="padding-bottom: 5px; color: darkblue; font-size: 0.9em;">#(prompt)#:</div>
	</td></tr>
	<tr><td align="center">
	<form name="Login" method="post" action="#($get(%request.Data("Error:FullURL",1)))#" autocomplete="off" onsubmit="return validateSubmit();">>

	Write ..InsertHiddenFields($get(%request.Data("Error:URL",1)))

	&html<
	<table class="AutoForm">
	<tr><td> 
	<tr class="AutoForm" valign="center">
	<td class="AutoFormCaption" nowrap>#(userName)#:</td>
	<td class="AutoFormControl" nowrap>
 		<input type="text" size="40" name="IRISUsername" autocomplete="off" value="#($zconvert($get(%request.Data("IRISUsername",1)),"O","HTML"))#">&nbsp;
 	</td>
 	</tr>
	<tr class="AutoForm" valign="center">
	<td class="AutoFormCaption" nowrap>#(oldpassword)#:</td>
	<td class="AutoFormControl" nowrap>
 		<input type="password" size="40" name="IRISOldPassword" autocomplete="off">&nbsp;
 	</td>
 	</tr>
	<tr>
	<td class="AutoFormCaption" nowrap>#(password)#:</td>
	<td class="AutoFormControl" nowrap>
		<input type="password" size="40" name="IRISPassword" autocomplete="off">&nbsp;
	</td>
	</tr>
	<tr class="AutoForm" valign="center">
	<td class="AutoFormCaption" nowrap>#(passwordrepeat)#:</td>
	<td class="AutoFormControl" nowrap>
 		<input type="password" size="40" id="IRISRepeatPassword" autocomplete="off">&nbsp;
 	</td>
 	</tr>
	<tr>
 	<td>&nbsp;</td>
	 <td><input type="submit" name="IRISLogin" value="#(login)#"></td>
	</tr>
	</table>
	</form>>

	// test for error
	Set tMsg = $Get(%request.Data("Error:ErrorCode",1))
 	If (tMsg'="") {
	 	If $SYSTEM.Status.GetErrorCodes(tMsg)[$$$ERRORCODE($$$RequireAuthentication)||($SYSTEM.Status.GetErrorCodes(tMsg)=$$$ERRORCODE($$$PasswordChangeRequired)) {
	 		Do DecomposeStatus^%apiOBJ(tMsg,.errorlist)
			If $get(errorlist(1,"embeddederror",1))'="" {
				Set tMsg=errorlist(1,"embeddederror",1)
			} Else {
				Set tMsg=""
			}
	 	}
		If $SYSTEM.Status.GetErrorCodes(tMsg)[$$$ERRORCODE($$$UserPasswordInvalidFormat) {
			// We show this, as it's more helpful than just "Password change failed" with no explanation
			Set tMsg=$$$ERROR($$$UserPasswordInvalidFormat)
		}
		If tMsg'="" Do ShowError^%apiCSP(tMsg)
 	}

	&html<</body></html>>

	Quit $$$OK
}

}
