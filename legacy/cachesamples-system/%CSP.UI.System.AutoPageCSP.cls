/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Base class used by CSP pages that work within the AutoPage framework.
Class %CSP.UI.System.AutoPageCSP Extends %CSP.Page [ Abstract, System = 3 ]
{

/// Default Charset
Parameter CHARSET = "UTF-8";

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

/// Name of the page to use for logins
Parameter LOGINPAGE = "%CSP.Login.cls";

/// Name of this page
Parameter PAGENAME;

/// Name of the parent page (used for the locator bar)
Parameter PARENTPAGE;

/// Write out the title pane for this page
ClassMethod WriteTitlePane(pTitle As %String)
{
	Set tInstance = ##class(%CSP.Util.PageInstance).%New()
	Set tInstance.Title = ..GetPageName()
	Set tInstance.PageClass = $classname()

	Set tTitlePane = ##class(%CSP.Util.SMTitlePane).%New()
	Set tTitlePane.Text = tInstance.Title
	
	// Title pane
	If ($IsObject($G(tTitlePane))) {
		Set tName = ..GetLocator(tTitlePane,.tAddress)
		Set tInstance.Address = tAddress

		// If Title is null then use the last page name in the header title
		If tTitlePane.Text = "", tName '= "" Set tTitlePane.Text = tName
		Do tTitlePane.DrawBODY(tInstance)
	}
	Do ##class(%CSP.Util.AutoPage).RegisterRecent(tTitlePane.Text)
}

ClassMethod OnPreHTTP() As %Boolean
{
	Do SetIO^%NLS($$MapCharset^%NLS(..#CHARSET))

	// remove session lock to prevent blocking
	Do %session.Unlock()

	// test for autoform submit (for login)
	Set tSubmitBtn = ##class(%CSP.Util.AutoForm).DoSubmit()

	// test for login
	If ((..#LOGINPAGE '= "") && (%session.Username = "")) {
		// if this is not the login page, then go there

		If (..#LOGINPAGE '= %request.PageName) {
			// check if we are called from a frame...
			Set tf = $G(%request.Data("$FRAME",1))
			If (tf = "_top") {
				Set tf = ""
			}
			
			Set %response.Redirect = ..#LOGINPAGE _ "?$ID1=" _ ..EscapeURL(%request.URL _ "?$ID1=" _ $G(%request.Data("$ID1",1)) _ $S(tf="":"",1:"&$FRAME=" _ tf))
			Quit 1
		}
	}
	ElseIf ((tSubmitBtn = "$AUTOFORM_LOGIN") && (%session.Username '= "") && $D(%request.Data("$ID1",1))) {
		// redirect to original desination after login
		Set %response.Redirect = %request.Data("$ID1",1)
		Quit 1
	}

	Quit 1
}

/// Get the list of items for the locator bar.
ClassMethod GetLocator(pTitlePane As %CSP.Util.TitlePane, ByRef pAddress As %String, ByRef pBaseURL As %String = {%request.URL}) As %String
{
	Set tParent = ..#PARENTPAGE
	Set tName = ..GetPageName()
	Set tURL = ..#CSPURL
	Set pAddress = ..#PAGENAME
	
	// get parent page locator
	Set tParentClass = $System.CSP.GetClassName(tParent,pBaseURL)
	If (tParentClass '= "") {
		Set pBaseURL=$$CSPNormalizeURL^%SYS.cspServer(tParent,pBaseURL)
		Set tReqURL=%request.URL, %request.URL=pBaseURL
		Do $classmethod(tParentClass,"GetLocator",pTitlePane,.tAddress) ; ,pBaseURL) -if parent page classes support the extra arg
		Set %request.URL=tReqURL
		Set:tAddress'="" pAddress = tAddress _ "," _ pAddress
	}

	Set tLink = ##class(%CSP.Util.Link).%New()
	Set tLink.Caption = tName
	Set tLink.HREF = tURL
	Do pTitlePane.Locator.Insert(tLink)

	Quit tName
}

/// Return localized version of PageName
ClassMethod GetPageName() As %String [ CodeMode = objectgenerator ]
{
	Do %code.WriteLine(" Quit $$$Text("""_$G(%parameter("PAGENAME"),"N/A")_""")")
	Quit $$$OK
}

}
