/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sqlui, %sySystem, %products)

/// Provide a default login and security-token pages for CSP applications.
/// User can override the look of this page by creating a subclass and 
/// overriding the DrawTitle method and the LOGINTITLE parameters.<br><br>
/// CORS processing for CSP pages that do not inherit from %CSP.REST is also provided here.
/// To turn on CORS assign the application's login page to be a subclass %CSP.Login
/// that has the HandleCorsRequest parameter = 1.
/// In addition, OnHandleCorsRequest and/or OnHandleOptionsRequest methods may be overridden
/// in order to override the default behavior for the application.
Class %CSP.Login Extends %CSP.Page [ System = 3 ]
{

/// This parameter influences the CORS support for the CSP application that has this login page assigned.
/// If set to true (1) then CORS processing is ON. Otherwise CORS processing is OFF.
Parameter HandleCorsRequest;

/// Name of stylesheet used for login page.<br/>
/// Not used by default page: styles come from the DrawSTYLE method.
Parameter STYLESHEET;

/// Title displayed for login page.<br>
/// Users can override this value to customize the login page.
Parameter LOGINTITLE = "Login Page";

/// Home favorite icon.
Parameter FAVORITEICON As COSEXPRESSION = "$$$ISCFAVORITEICON";

/// Login page localization domain
Parameter DOMAIN = "%UtilityLogin";

/// Output the default login page as HTML
ClassMethod OnPage() As %Status
{
	Set %Status = $$$OK
	Try  {
		/// CORS processing is required for the login page
		If ..#HandleCorsRequest=1 {
			// Dispatch CORS
			Set %Status=..ProcessCorsRequest(%request.URL)
			If $$$ISERR(%Status) Quit
	            
			// Support OPTIONS verb
			If %request.Method="OPTIONS" {
				If %response.Language="" Set %response.Language="en"
				// Don't want the session token
				Set %response.OutputSessionToken=0
				Set %Status=..OnHandleOptionsRequest("/"_$extract(%request.URL,$length(%request.Application)+1,*))
				If $$$ISOK(%Status) Set %Status=%response.WriteHTTPHeader()
	            Quit
	        }
		}

		/// CSP Applications now allow for two-factor authentication. This requires two-pages 
		/// in the login page: the password page and the security token page.
		Set wantLoginPage = $G(%request.Data("IRISLoginPage",1),1)
		If (wantLoginPage) {
			Set %Status = ..OnLoginPage()
		}
		Else {
			Set %Status = ..OnSecurityTokenPage()
		}

	} Catch (e) {
		Set %Status = e.AsStatus()
	}
	
	Quit %Status
}

ClassMethod OnLoginPage() As %Status
{
	// text strings
	Set ConfigName = $P($zu(86),"*",2)
	// get key, lookup in localization global
	Set tLang = $$$SessionLanguage
	Set tTitle = $$FormatText^%occMessages($$$GetSysMessage(tLang,..#DOMAIN,"logintitle","Login %1"),ConfigName)
	Set tPrompt = $$$GetSysMessage(tLang,..#DOMAIN,"loginenter","Please login")
	Set tUserName = $$$GetSysMessage(tLang,..#DOMAIN,"loginusername","User Name")
	Set tPassword = $$$GetSysMessage(tLang,..#DOMAIN,"loginpassword","Password")
	Set tLogin = $$$GetSysMessage(tLang,..#DOMAIN,"login","LOGIN")
	Set OtherAutheEnabled = $$OtherAuthEnabled^%SYS.cspServer(%request)
	&html<<html #($$$HTMLLangAttr)#>>
	Do ..DrawHEAD(tTitle)

	&html<
		<body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0" onload="pageLoad();">
		<div id="content">>
 
	Do ..DrawTitle(tTitle)

 	&html<
 	<div style="background-color:#FBFBFB;">
 	<table border="0" cellpadding="10" align="center" class="LayoutTable">
 	<tr>
	<td align="center">
 	<table border="0" width="100%" cellpadding="5" cellspacing="0">>
 	&html<<tr><td style="height:90px;"><br/></td></tr>>
 	
 	&html<<tr><td><center>>

  If OtherAutheEnabled = 1 {
	// Show standard login form

	&html<
	
	<form name="Login" method="post" action="#($ZConvert($G(%request.Data("Error:FullURL",1)),"O","HTML"))#" autocomplete="off">>

	Write ..InsertHiddenFields($ZConvert($G(%request.Data("Error:URL",1)),"O","HTML"))

	&html<
	<table class="login" border="0" cellspacing="10" cellpadding="10" >
	<tr valign="bottom">
	<td nowrap class="loginCaption">#(tUserName)#</td>
	<td><input type="text" size="30" name="IRISUsername" autocomplete="off" value="#($ZCVT($get(%request.Data("IRISUsername",1)),"O","HTML"))#"/>
 	</td>
 	</tr>
	<tr valign="bottom">
	<td nowrap class="loginCaption">#(tPassword)#</td>
	<td><input type="password" size="30" name="IRISPassword" autocomplete="off"/>
	</td>
	</tr>
	<tr><td>&nbsp;</td>
	 <td style="text-align:right"><input type="submit" name="IRISLogin" class="button" value="#(tLogin)#" style="width:120px;"></td>
	</tr>
	</table>
	</form></center></div>>

  }  // End OtherAutheEnabled = 1 block
  Else {
	  // This is accessed when IRIS is installed with minimum security and user clicked Logout.
	  Set msg1 = $$$GetSysMessage(tLang,..#DOMAIN,"loginclickhere","Please click here to log in.")
	  Set tLink = ..Link("/csp/sys/UtilHome.csp")
	&html<
	<a href="#(tLink)#" class="loginlink">#(msg1)#</a>
	</center>
	</td>
	</tr>
	</table>
	>
  }

 	// test for error
 	Set tMsg = $Get(%request.Data("Error:ErrorCode",1))
 	If ((tMsg'="")&&($SYSTEM.Status.GetErrorCodes(tMsg)'[$$$ERRORCODE($$$RequireAuthentication))) {
 		&html<<tr><td><center>>
 		Do ShowError^%apiCSP(tMsg)
 		&html<</center></td></tr>>
 	}

 	&html<</td></tr><tr><td style="height:180px;"><br/></td></tr></table></div></div></body></html>>

 	Quit $$$OK
}

/// Draw the HEAD section of the login page.<br>
/// Users can override this method to customize the login page.
ClassMethod DrawHEAD(pTitle = "")
{
	&html<<head>
	<title>#(pTitle)#</title>>

	// link in stylesheet specified by parameter
	If (..#STYLESHEET '= "") {
		&html<<link rel="stylesheet" type="text/css" href="#(..Link(..#STYLESHEET))#">>
	}
	If (..#FAVORITEICON '= "") {
		&html<<link rel="icon" type="image/ico" href="#(..Link(..#FAVORITEICON))#">>
	}
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
	</script>>
	If ##class(%ZEN.Utils).%BrowserSupportsHTML5(%request.UserAgent) {
		Do ..DrawCSS3STYLE()
	}
	Else {
		Do ..DrawSTYLE()
	}
	&html<</head>>
}

/// Draw the title section of the login page.<br>
/// <var>pTitle</var> is the title for the page.<br>
/// Users can override this method to customize the login page.
ClassMethod DrawTitle(pTitle As %String)
{
	Set tLang = $$$SessionLanguage
	Set tAction = $$$GetSysMessage(tLang,..#DOMAIN,"login","Login")
	Set msgs("title") = pTitle
	Set msgs("tAction") = tAction
	
	Do ..DrawTitleSection( .msgs )
}

/// Draw the title section of the security token page.<br>
/// <var>pTitle</var> is the title for the page.<br>
/// Users can override this method to customize the security token page.
ClassMethod DrawSTTitle(pTitle As %String)
{
	Set tLang = $$$SessionLanguage
	Set tAction = $$$GetSysMessage(tLang,..#DOMAIN,"loginsecurityttoken","Security Token")
	Set msgs("title") = pTitle
	Set msgs("tAction") = tAction
	
	Do ..DrawTitleSection( .msgs )
}

/// Draw the title section of the page.<br>
/// <var>pTitle</var> is the title for the page.<br>
/// Users can override this method to customize the page title section.
ClassMethod DrawTitleSection(ByRef msgs As %String)
{
	Set tLang = $$$SessionLanguage
	Set cmdServer = $$$GetSysMessage(tLang,..#DOMAIN,"loginserver","Server")
	Set cmdInstance = $$$GetSysMessage(tLang,..#DOMAIN,"logininstance","Instance")
	Set msgServer = $$$GetSysMessage(tLang,..#DOMAIN,"loginmsgserver","Name of the machine this system is running on")

	Set InstanceName = $zconvert($P($zu(86),"*",2),"O","HTML")
	Set ProductName = $$$TextHTML("Management Portal")
	Set tProductLogo = $$$ISCLOGINICON 	// calculated in %products based on product installed
	Set home = %request.URL
	If home '= "" Set ProductName = ##class(%CSP.UI.Portal.Template).%GetProductName()
	Set tBy = $$$GetSysMessage(tLang,..#DOMAIN,"loginlogoalt","InterSystems IRIS Data Platform")
	
	&html<<table class="portalTitle" id="group_1" width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
	<td align="left" valign="top">
	<div class="portalLogoBox">
	<img src='#(tProductLogo)#' width="40" height="40" alt="#(tBy)#"></img>
	</div>
	</td>
	</tr>
	<tr>
	<td width="99%" align="left">
		<table border="0">
		<tr>
		<td class="portalTitleInfoLabel" style="padding-top:20px;">#(cmdInstance)#:</td><td class="portalTitleInfoVal" style="padding-top:20px;">#(InstanceName)#&nbsp;</td>
		</tr>
		</table>
	</td>

	</table>>
}

ClassMethod OnErrorSetup(ByRef skipheader As %Boolean) As %Boolean [ ProcedureBlock = 1 ]
{
	If $get(%request.Data("CharSet",1))'="" Set %response.CharSet=$get(%request.Data("CharSet",1))
	#; HyperEvent error handling is performed by the CSP server and the error page currently in use.
	Quit 1
}

ClassMethod OnSecurityTokenPage() As %Status
{
	// text strings
	Set ConfigName = $P($zu(86),"*",2)
	// get key, lookup in localization global
	Set tLang = $$$SessionLanguage
	Set tTitle = $$FormatText^%occMessages($$$GetSysMessage(tLang,..#DOMAIN,"sectoktitle","Security Token %1"),ConfigName)
	Set Application = $extract(%request.AppMatch,1,*-1)
	s Status=$$GetSecurityApplicationInfo^%SYS.SECURITY(Application,.Properties)
	s AutheEnabled=+Properties("AutheEnabled")
	Set tSecurityToken = $$$GetSysMessage(tLang,..#DOMAIN,"sectok","Security Token")
	i $zb(AutheEnabled,$$$AutheTwoFactorSMS,1) Set tSecurityToken = $$$GetSysMessage(tLang,..#DOMAIN,"sectok","Security Token")
	i $zb(AutheEnabled,$$$AutheTwoFactorPW,1) Set tSecurityToken = $$$GetSysMessage(tLang,..#DOMAIN,"sectokver","Verification Code")
	Set tSubmit = $$$GetSysMessage(tLang,..#DOMAIN,"sectoksubmit","Submit")
	Set tCancel = $$$GetSysMessage(tLang,..#DOMAIN,"sectokcancel","Cancel")
	&html<<meta http-equiv="X-UA-Compatible" content="IE=edge" />>
	&html<<html #($$$HTMLLangAttr)#><head><title>#(tTitle)#</title>>

	Do ..DrawSTHEAD()

 	&html<</head>
 	   <body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0" onload="pageSTLoad();">>

	Do ..DrawSTTitle(tTitle)
	// Show standard login form
 	&html<<div id="content">
 	<table border="0" cellpadding="10" align="center" class="LayoutTable">
 	<tr>
	<td colspan="10" align="left">
	<table border="0" width="100%" cellpadding="0" cellspacing="0">
	>
	s Status=$$$OK
	i $zb(AutheEnabled,$$$AutheTwoFactorPW,1) {
		s Status=$$GenerateQRCode^%SYS.SECURITY(%request.Data("IRISUsername",1),,.QRCode,.Code,.Account,.Issuer,.DisplayQRCode)
	} else {
		s DisplayQRCode=0
	}
    i DisplayQRCode {
		s Text=$$$Text("The system administrator has enabled Two-factor authentication for your account.")_"<br><br>"
		s Text=Text_$$$Text("Your Two-factor authentication requires the use of an authenticator application.")_"<br>"
		s Text=Text_$$$Text("These applications require you to enter a Time-based One-time Password key.")_"<br><br>"
		i ($$$ISOK(Status)) {
			s Text=Text_$$$Text("If your authenticator application supports scanning a QR code (barcode) to enter the key, ")_"<br>"
			s Text=Text_$$$Text("you can enter the key by scanning the following QR code:")_"<br>"
		}
		&html<<tr><td style="height:60px;"><br/></td></tr>>
		&html<#(Text)#<br>>
		s Text=""
		i ($$$ISOK(Status)) {
			&html<<image id="qrcode" width="150" height="150" src="#(QRCode)#">>
    		s Text="<br><br>"_$$$Text("Once you have scanned the QR code, enter the 6-digit verification code generated by your authenticator application.")_"<br><br>" 
    		s Text=Text_$$$Text("If you cannot scan the QR code, then you must enter the following information into your authenticator manually,")_"<br>"
		} else {
    		s Text="<br><br>"_Text_$$$Text("You must enter the following information into your authenticator manually,")_"<br>"
		}
   		s Text=Text_$$$Text("then enter the 6-digit verification code generated by your authenticator application.")_"<br><br>"
    	s Text=Text_$$$Text("Issuer:")_" "_Issuer_"<br>"
    	s Text=Text_$$$Text("Account:")_" "_Account_"<br>"
    	s Text=Text_$$$Text("Base 32 Time-based OTP Key:")_" "_Code
    
		&html<#(Text)#>
	} else {

	 	&html<<tr><td style="height:60px;"><br/></td></tr>>
	
	}
	&html<<tr><td><center>
	<form name="SecurityToken" method="post" action="#($G(%request.Data("Error:FullURL",1)))#" autocomplete="off">>

	Write ..InsertHiddenFields($G(%request.Data("Error:URL",1)))
	
	&html<
	<table class="login" cellpadding="5" >
	<tr><td align="center">&nbsp;</td></tr>
	<tr><td class="loginCaption" nowrap="1">#(tSecurityToken)#</div>
 	<input type="password" size="30" name="IRISSecurityToken" autocomplete="off" value="#($ZCVT($get(%request.Data("IRISSecurityToken",1)),"O","HTML"))#">
 	</td>
 	</td>
 	</tr>
 	<tr><td>&nbsp;</td></tr>
	<tr>
 	<td nowrap="1" style="padding-bottom:10px;" align="right">
 		<input type="submit" class="button" name="IRISSecuritySubmit" value="#(tSubmit)#">&nbsp;
	 	<input type="submit" class="button" name="IRISSecurityCancel" value="#(tCancel)#">&nbsp;
	 </td>
	</tr>
	</table>
	</form>>
	// test for error
	Set tMsg = $Get(%request.Data("Error:ErrorCode",1))
 	If ((tMsg'="")&&($SYSTEM.Status.GetErrorCodes(tMsg)'[$$$ERRORCODE($$$CSPPendingTwoFactorAuthentication))) {
	 	Do ShowError^%apiCSP(tMsg)
 	}

	&html<</td></tr></table></div></body></html>>

	Quit $$$OK
}

/// Draw the HEAD section of the security token page.<br>
/// Users can override this method to customize the security token page.
ClassMethod DrawSTHEAD()
{
	// link in stylesheet specified by parameter
	If (..#STYLESHEET '= "") {
		&html<<link rel="stylesheet" type="text/css" href="#(..Link(..#STYLESHEET))#">>
	}
	// js functions
	&html<<script language="javascript">
	// called when page is loaded
	function pageSTLoad()
	{
		// see if we can give focus to the Security Token field:
		if (self.document.SecurityToken && self.document.SecurityToken.IRISSecurityToken) {
			self.document.SecurityToken.IRISSecurityToken.focus();
			self.document.SecurityToken.IRISSecurityToken.select();
		}
		return true;
	}
	</script>>
	If ##class(%ZEN.Utils).%BrowserSupportsHTML5(%request.UserAgent) {
		Do ..DrawCSS3STYLE()
	}
	Else {
		Do ..DrawSTYLE()
	}
}

/// Draw the style definitions for the login page.<br>
/// Users can override this method to customize the login page.
ClassMethod DrawCSS3STYLE()
{
 	&html<
 	<style type="text/css">
body {
	background: #ECEEF3;
	font-family: Futura,Arial,sans-serif;
	font-size: 14px;
	overflow: hidden;
}

input {
	border: 1px solid #979797;
	border-radius:4px;
	font-size: 14px;
	height: 25px;
	width: 219px;	
}
#content {
	background: #FBFBFB;
	border-top: solid 5px #333695;
	border-right: 1px solid #cbcbcb;
	border-bottom: 1px solid #cbcbcb;
	border-left: 1px solid #cbcbcb;
	border-radious: 5px;
	margin: 30 50;
	padding-bottom: 50px;
}
table.LayoutTable {
	background:#ffffff;
	border: 1px solid #cbcbcb;
	border-radius:4px;
	font-size: 14px;
	height: auto;
	width: 90%;
	margin: 20 50;
}

.portalTitle {
	background: white;
	height: 80px;
	position: relative;	
	width: 100%;
}

.portalTitleInfoLabel {
	color: #000000;
	font-size: 14px;
	font-weight: 600;
	padding-left: 50px;
}

.portalTitleInfoVal {
	color: #000000;
	font-size: 14px;
}

table.login	{ 
}
table.login td.loginCaption {
	color: #000000;
	font-size: 14px;
}

/* Logout message */
h3 {
	color: rgb(67,67,67);
	font-size: 12px;
	font-weight: bold;
}

div.loginPrompt {
	color: #D0D0D0;
	font-size: 16pt;
	padding: 0px;
	padding-bottom: 5px;
	text-align: center;
	text-shadow: black 1px 1px 1px;
}

div.isc {
	color: #808080;
	font-size: 10pt;
	padding-top: 2px;
	text-shadow: #6374AB 1px 1px 1px;
}
.portalLogoBox {
	position: static;
	padding: 20px 50px;
	box-shadow:0 2px 8px 0 rgba(0,0,0,0.12);
}
.loginlink {
	color: rgb(52,108,141);
}
.button {
	background: white;
	color: #333695;
    cursor: pointer;
	border: 2px solid #333695;
	border-radius: 4px;
	font-size: 12px;
	letter-spacing: 0.75px;
	text-align: center;
	text-decoration: none;
	padding: 2px 16px;
}
.button:hover {
	border: 2px solid #00A09A;
	color: #00A09A;
}
</style>>
}

/// Draw the style definitions for the login page.<br>
/// Users can override this method to customize the login page.
ClassMethod DrawSTYLE()
{
 	&html<
 	<style type="text/css">
body {
	background: #ECEEF3;
	font-family: Futura,Arial,sans-serif;
	font-size: 14px;
	overflow: hidden;
}

input {
	border: 1px solid #979797;
	border-radius:4px;
	font-size: 14px;
	height: 25px;
	width: 219px;	
}
#content {
	background: #FBFBFB;
	border-top: solid 5px #333695;
	border-right: 1px solid #cbcbcb;
	border-bottom: 1px solid #cbcbcb;
	border-left: 1px solid #cbcbcb;
	border-radious: 5px;
	margin: 30 50;
	padding-bottom: 50px;
}
table.LayoutTable {
	background:#ffffff;
	border: 1px solid #cbcbcb;
	border-radius:4px;
	font-size: 14px;
	height: auto;
	width: 90%;
	margin: 20 50;
}

.portalTitle {
	background: white;
	height: 80px;
	position: relative;	
	width: 100%;
}

.portalTitleInfoLabel {
	color: #000000;
	font-size: 14px;
	font-weight: 600;
	padding-left: 50px;
}

.portalTitleInfoVal {
	color: #000000;
	font-size: 14px;
}

table.login	{ 
}
table.login td.loginCaption {
	color: #000000;
	font-size: 14px;
}

/* Logout message */
h3 {
	color: rgb(67,67,67);
	font-size: 12px;
	font-weight: bold;
}

div.loginPrompt {
	color: #D0D0D0;
	font-size: 16pt;
	padding: 0px;
	padding-bottom: 5px;
	text-align: center;
	text-shadow: black 1px 1px 1px;
}

div.isc {
	color: #808080;
	font-size: 10pt;
	padding-top: 2px;
	text-shadow: #6374AB 1px 1px 1px;
}
.portalLogoBox {
	position: static;
	padding: 20px 50px;
	box-shadow:0 2px 8px 0 rgba(0,0,0,0.12);
}
.loginlink {
	color: rgb(52,108,141);
}
.button {
	background: white;
	color: #333695;
    cursor: pointer;
	border: 2px solid #333695;
	border-radius: 4px;
	font-size: 12px;
	letter-spacing: 0.75px;
	text-align: center;
	text-decoration: none;
	padding: 2px 16px;
}
.button:hover {
	border: 2px solid #00A09A;
	color: #00A09A;
}
</style>>
}

/// Determine if this request requires CORS processing and if so, dispatch to OnHandleCorsRequest
ClassMethod ProcessCorsRequest(url As %String, requireCors As %String = "") As %Status [ Internal, Private ]
{
    #dim sc As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    Try {
	    Set handlecorsrequest=$zconvert(..#HandleCorsRequest,"U")
        
        #; Parameter over-rides
        If (handlecorsrequest="FALSE")||(handlecorsrequest="0") {
            
            #; Override says DO NOT handle
            Quit
        }

        If (handlecorsrequest="TRUE")||(handlecorsrequest="1") {
            
            #; Override says DO handle
            Set sc=..OnHandleCorsRequest(url)
            Quit
        }
        
        #; Parameter is NOT set, honor ROUTE cors setting.  For use by %CSP.REST.
        If requireCors="true" {
            
            Set sc=..OnHandleCorsRequest(url)
            Quit
        }
        
    } Catch (e) {
        Set sc=e.AsStatus()
    }
    Quit sc
}

/// This methods provides handling of the options request for this CSP application.
/// Note carefully: If authentication is required then this method will be
/// called before login and as such will have only limited privileges.
ClassMethod OnHandleOptionsRequest(url As %String) As %Status
{
    #; Simply dispatch to the default implementation
    Quit ..HandleDefaultOptionsRequest(url)
}

/// Handle an OPTIONS request for this CSP application
ClassMethod HandleDefaultOptionsRequest(url As %String) As %Status [ Internal, Private ]
{
    #dim sc As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim supportedVerbs As %String
    
	Try {
		Set %response.ContentType=""
		Set supportedVerbs=""
		Set sc=..SupportedVerbs(url,.supportedVerbs)
		Do %response.SetHeader("Allow",supportedVerbs)       
    } Catch (e) {
		Set %response.Status="404 Not Found"
		Set sc=$$$OK
    }
    Quit sc
}

/// This is the CORS request handler. User should override this method in their login page
/// if they don't want the default behavior.
ClassMethod OnHandleCorsRequest(url As %String) As %Status
{
	// The default implementation is simply to dispatch to the default handler
    Quit ..HandleDefaultCorsRequest(url)
}

/// Provide reasonable default handling for a CORS-enabled request for those who
/// 'JUST WANT IT TO WORK'.
/// The allowlist must be populated and the origin must be found in the allowlist
/// for CORS headers to be added to the response.
ClassMethod HandleDefaultCorsRequest(url As %String) As %Status [ Internal, Private ]
{
    #dim sc As %Status = $$$OK
    #dim e As %Exception.AbstractException
    #dim %request As %CSP.Request
    #dim %response As %CSP.Response
    #dim origin,headers,method As %String
    
    Try {
        // Get the origin
        Set origin=$Get(%request.CgiEnvs("HTTP_ORIGIN"))

		If origin'="" {
			Set corsAllowlist = $$$GetSecurityApplicationsCorsAllowlist(%request.AppData)
			// search is case-insensitive
			Set found=($LISTFIND($ZCONVERT(corsAllowlist,"U"),$ZCONVERT(origin,"U")))||($LISTFIND(corsAllowlist,"*"))

			If found=0 {
				// If not found, check if found for alternate port options. 
				// If the incoming origin has no port, this code also checks for the same origin with a port assumed from the scheme
				// If the incoming origins has a scheme's default port, this code also checks for the same origin without a port defined. 
				Do ##class(%Net.URLParser).Decompose($ZCONVERT(origin,"U"),.tComponents)
				If $get(tComponents("scheme"))="HTTP", '$data(tComponents("port")) {
					Set tComponents("port")=80
				} Elseif $get(tComponents("scheme"))="HTTPS", '$data(tComponents("port")) {
					Set tComponents("port")=443
				} Elseif $get(tComponents("scheme"))="HTTP", $get(tComponents("port"))=80 {
					Set tComponents("port")=""
				} Elseif $get(tComponents("scheme"))="HTTPS", $get(tComponents("port"))=443 {
					Set tComponents("port")=""
				}
				Set tComponents("netloc")=""
				Set originNormalized = ##class(%Net.URLParser).Compose(.tComponents)
				Set found=$LISTFIND($ZCONVERT(corsAllowlist,"U"),$ZCONVERT(originNormalized,"U"))
			}

			If found'=0 {
				// If here, origin is defined; allowlist is defined; and the origin is in allowlist

				// Allow requested origin
	        	Do %response.SetHeaderIfEmpty("Access-Control-Allow-Origin",origin)

	        	// Set allow credentials
	        	Set addCredAllowed = $$$GetSecurityApplicationsCorsCredentialsAllowed(%request.AppData)
	        	If addCredAllowed {
	        		Do %response.SetHeaderIfEmpty("Access-Control-Allow-Credentials","true")
	        	}

		        // Allow requested headers
		        Set headers = $$$GetSecurityApplicationsCorsHeadersList(%request.AppData)
		        If headers'="" {
		        	Do %response.SetHeaderIfEmpty("Access-Control-Allow-Headers",$LISTTOSTRING(headers))
		        }
		        
		        // Allow requested method
		        Set sc = ..SupportedVerbs(url,.method)
		       	Do %response.SetHeaderIfEmpty("Access-Control-Allow-Methods",method)
			} 
		}
    } Catch (e) {
        Set sc=e.AsStatus()
    }
    Quit sc
}

/// By default all methods are supported.
ClassMethod SupportedVerbs(url, Output verbs As %String) As %Status
{
	Set verbs="OPTIONS,GET,HEAD,POST,PUT,DELETE,TRACE,CONNECT"
	Quit $$$OK
}

/// Determine if we need login CSRF tokens and if so add them.
/// If a login page subclass overrides this method it should call this implementation
/// to ensure we set the login CSRF tokens if needed.
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	If '$$UseCSRFtoken^%SYS.cspServer(%request.AppData) RETURN 1
	Set token=##class(%OAuth2.Utils).Base64UrlEncode($system.Encryption.GenCryptRand(12))
	Set %response.Context("IRISSessionToken")=token
	Set cookiepath=%session.CookiePath
	If $extract(cookiepath,*)'="/" Set cookiepath=cookiepath_"/"
	Set sameSite=$$$GetCookieScopeString(%session.SessionScope)
	Do %response.SetCookie("IRISSessionToken",token,,$zcvt($zcvt(cookiepath,"O","UTF8"),"O","URL"),,%request.Secure,1,sameSite)
	RETURN 1
}

}
