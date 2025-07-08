/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Utility class that is used to find DocBook entries that correspond to 
/// Management Portal Pages.
Class %CSP.Util.Librarian [ Abstract, System = 4 ]
{

/// Find closest link to DocBook page given an array contain topic information.
/// pID(1) is a category, pID(2) is a sub-category.
ClassMethod FindDocBookLink(ByRef pID As %String, pReturnType As %String = 0) As %String
{
	Set tDocId = ""
	Set tDocAnchor = ""
	Set tTopic = $G(pID(1))
	Set tSub = $G(pID(2))
	Set tURL = ##class(%CSP.Page).Link("/csp/docbook/DocBook.UI.Page.cls")
	
	If (tTopic = "Config") {
		Set tDocId = "RACS_Settings"
		
		// config page item
		// find internal source name for item in Config.Settings global
		Set t1 = $P(tSub,".",1)
		Set t2 = $P(tSub,".",2)

		If ((t1'="")&&(t2'="")) {
			Set tDocAnchor = "RACS_" _ $LG($G(^Config.Settings(t1,t2)),1)
		}
	}
	ElseIf (tTopic = "MgtPortal") {
		// this is the *real* code
		Set tURL = ##class(%CSP.Page).Link("/csp/docbook/DocBook.UI.PortalHelpPage.cls")
		Set tDocId = tSub
	}

	// make sure there are no % chars in anchor
	Set tDocAnchor = $TR(tDocAnchor,"%","")
	
	// If pReturnType '= 0 (for %CSP.Portal.Home) then return without js function name
	If pReturnType = 0 Quit "javascript:showDocumentation(" _ ##class(%CSP.Page).QuoteJS(tDocId) _ "," _ ##class(%CSP.Page).QuoteJS(tDocAnchor) _ ","_ ##class(%CSP.Page).QuoteJS(tURL) _");"
	Else  Quit tDocId _ "_" _ tDocAnchor _ "_"_ tURL
}

}
