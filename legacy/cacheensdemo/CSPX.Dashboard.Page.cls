/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An SVG-based dashboard displaying a set of controls.<br>
/// This class generates the SVG document needed to display
/// a dashboard.
/// Users should not use this class directly.
Class CSPX.Dashboard.Page Extends %CSP.Page [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Parameter CONTENTTYPE = "image/svg-xml";

ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	// Avoid IE HTTP 1.1 bugs
	Set %response.HTTPVersion = "HTTP/1.0"

	// Workaround for HTTPS
	If (%request.Secure) {
		Do %response.SetHeader("Cache-Control","private")
	}

	// force output to be UTF-8
	Set %response.CharSet="UTF-8"

	// prevent session blocking
	Do %session.Unlock()

	Quit 1
}

ClassMethod OnPage() As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"

	Do {
		// get dashboard object
		Set tClass = $G(%request.Data("CLASS",1))
		Set tSC = $zobjclassmethod(tClass,"CreateDashboard",.tDashboard)
		If ($$$ISERR(tSC)) Quit

		Do tDashboard.RenderSVG()
	} While(0)
Done
	Quit tSC
Trap
	Set $ZT=""
	Write "<ERROR>Error rendering dashboard: ",$ZCVT($ZE,"O","HTML"),"</ERROR>",!
	Goto Done
}

}
