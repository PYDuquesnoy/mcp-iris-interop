/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Created using the page template: Default
Class %CSP.UI.Portal.SQL.QButtons.ReportLoaderOutput Extends %CSP.Page [ ProcedureBlock, System = 4 ]
{

Parameter CSPURL = "/csp/sys/exp/%CSP.UI.Portal.SQL.QButtons.ReportLoaderOutput.zen";

/// Set this to the correct domain.
Parameter DOMAIN = "%Utility";

/// Ensure user has %Development:USE
ClassMethod OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit $system.Security.Check($$$DevelopmentResourceName,"USE")
}

/// The <method>OnPage()</method> is called by the CSP dispatcher to generate the
/// page content. For %CSP.StreamServer, since the content type is actually a stream, not HTML
/// we simply write out the stream data.
ClassMethod OnPage() As %Status
{
	Set filename = $Get(%request.Data("FILENAME",1))
	Set namespace = $Get(%request.Data("$NAMESPACE",1))
	Set action = $Get(%request.Data("ACTION",1))
	&html<<html>
	<head>
	<link rel="stylesheet" type="text/css" href="#(..Link("/csp/sys/intersystems.css"))#" title="Standard Style" >
	</head><body>>
	If '##class(%File).Exists(filename) {
		&html<<p>#($$$Text("File does not exist."))#</p>>
		Quit $$$OK
	}
	Write "<p>",$$$FormatText($$$Text("Loading File %1: "),$zconvert(filename,"O","HTML")),"</p>"
	Do %response.Flush()
	Write "<pre>"
	Set namespace = $Get(%request.Data("$NAMESPACE",1))
	Set EscapeObj = ##class(%CSP.HTMLEscape).%New()
	Set tSC = ##class(%SQL.Manager.QButtons.Base).ConsumeReport(filename,"ckd",1,namespace)
	Kill EscapeObj
	Write "<p>",$$$TextHTML("Done"),"</p>"
    Write "</pre>"
    &html<</body></html>>
    Quit $$$OK
}

ClassMethod ShowDetails(filename)
{
	Write "<p>",$$$FormatText($$$Text("File '%1' Details:"),filename),"</p>"
	Set tSC = $$ReadAllFromFile^%SYS.PTools(filename,.QBInfo)
	If $$$ISERR(tSC) {
		Write "<div class='ErrorBox'>",$System.Status.GetErrorText(tSC),"</div>"
		Quit	
	}
	Set index = $O(QBInfo(0))
	While index '= "" {
		Write "<table class='DetailTable'>"
		Set prop = $O(QBInfo(index,"%plan"))
		Set tRow = 0
		While prop '= "" {
			Set value = QBInfo(index,prop)
			If prop = "ClassDefXml" {
				Set value = $lg(value)
			}
			Set tRow = tRow + 1
			Set tClass = $S(tRow#2: "OddRow", 1: "EvenRow")
			Write "<tr class='",tClass,"'><td>",..EscapeHTML(prop),"</td><td>",..EscapeHTML(value),"</td></tr>"
			Set prop = $O(QBInfo(index,prop))	
		}
		Write "</table><br/>"
		Merge %plan = QBInfo(index,"%plan")
		Set sc=$s('$g(%plan):$$$OK,1:$$planHTML^%qaqplan(.%plan))
		Set index = $O(QBInfo(index))
		Write "<div style='padding-top:1cm;'></div>"	
	}
}

}
