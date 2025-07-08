/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Desribes an instance of an AutoPage.<BR>
/// This is a transient object that exists while an AutoPage is being rendered.
/// It describes the layout for an AutoPage. 
/// It also provides a container for any page-related variables.
Class %CSP.Util.PageInstance Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, ServerOnly = 1, System = 4 ]
{

/// HTML Title displayed for this page.
Property Title As %String(MAXLEN = 50);

/// Name of CSP class hosting this page
Property PageClass As %String(MAXLEN = 128, XMLPROJECTION = "none");

/// An array of named Pane objects that describe the various panes for a page.
Property Panes As array Of Pane;

/// An array (integer-subscripted) of values use to identify
/// any objects used within a page (such as the ID for an object
/// or parameters for a query).<BR>
/// These are taken out of the incoming URL using the $IDn parameter.
Property IDValues As %String [ MultiDimensional ];

/// An array of page-directed variables, subscripted by
/// name and number (as a URL parameter is placed within the Request object).<BR>
/// These are taken out of the incoming URL query: 
/// any value starting with $ is assumed to be a page variable.
Property PageVars As %String [ MultiDimensional ];

/// Canonical address used to find this page (e.g., "Home,Configuration").
Property Address As %String(MAXLEN = 200);

Method %OnNew(initval As %String) As %Status [ Private ]
{
	// fill in IDVars and Page Vars from %request
	If ($IsObject($G(%request))) {
		Set n = 1
		While ($D(%request.Data("$ID"_n,1))) {
			Set ..IDValues(n) = %request.Data("$ID"_n,1)
			Set n = n + 1
		}
	}
	
	Quit $$$OK
}

/// Construct a link to another AutoPage
/// If pTargetFrame, this is a link for a specific frame
Method MakeLink(pURL As %String, ByRef pID As %String = "", ByRef pVARS As %String = "") As %String
{
	// id vars
	Set count = $O(pID(""),-1)
	For i=1:1:count {
		Set tQuery("$ID"_i) = $G(pID(i))
	}

	// page vars	
	Set name = $O(pVARS(""))
	While (name '= "") {
		Set tQuery(name) = $G(pVARS(name))
		Set name = $O(pVARS(name))
	}
	
	Set link = ##class(%CSP.Page).Link(pURL,.tQuery)
	Quit link
}

/// Construct a link to a popup window
Method MakePopupLink(pURL As %String, ByRef pID As %String = "", ByRef pVARS As %String = "") As %String
{
	// note double URL escape
	Quit "javascript:launchPopupWindow(" _ $ZCVT(##class(%CSP.Page).QuoteJS(..MakeLink(pURL,.pID,.pVARS)),"O","URL") _ ");"
}

/// Construct a link for a frame popup window
Method MakeFramePopupLink(pURL As %String, ByRef pID As %String = "", ByRef pVARS As %String = "") As %String
{
	// note double URL escape
	Quit "javascript:frames[1].launchPopupWindow(" _ $ZCVT(##class(%CSP.Page).QuoteJS(..MakeLink(pURL,.pID,.pVARS)),"O","URL") _ ");"
}

/// Construct a link for redirecting to an AutoPage with its page-related query.
/// This is used when you need to redirect a page (after a submit, for example).
Method MakeRedirectLink(pURL As %String, pSubmitBtn As %String = "") As %String
{
	// id vars
	Set count = $O(..IDValues(""),-1)
	For i=1:1:count {
		Set %response.Context("$ID"_i) = $G(..IDValues(i))
	}
	
	// make sure frame name is passed along
	If ($G(%request.Data("$FRAME",1)) '= "_top") {
		Set %response.Context("$FRAME") = $G(%request.Data("$FRAME",1))
	}
	//
	// page vars
	
	// pSubmitBtn '= "": set a URL parm indicating that we did a submit and which button it was
	If (pSubmitBtn '= "") {
		Set %response.Context("$SUBMITBTN") = pSubmitBtn
	}
	// the call to redirect will build the actual link
	Quit pURL
}

}
