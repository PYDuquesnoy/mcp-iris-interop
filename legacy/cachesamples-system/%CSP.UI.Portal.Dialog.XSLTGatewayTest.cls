/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Dialog popup for Zen Report Render Server actions.
Class %CSP.UI.Portal.Dialog.XSLTGatewayTest Extends %CSP.Portal.standardDialog [ System = 4 ]
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "%CSP.UI.Portal.Application";

Parameter CSPURL = "/csp/sys/mgr/%CSP.UI.Portal.Dialog.XSLTGatewayTest.zen";

/// Security requirement
Parameter RESOURCE = "%Admin_Manage";

/// Displayed name of this page.
Parameter PAGENAME = "Test XSLT Gateway server";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// If true, then this dialog displays a Cancel button.
Parameter CANCELBUTTON = 0;

Property Action As %String;

Property Draw1 As %Boolean [ InitialExpression = 0 ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
body {
	margin: 0px;
}
.cmd {
	font-size: 12px;
	font-family: Courier;
	font-weight: bold;
}
.txt {
	font-size: 0.9em;
	white-space: pre-wrap;
}
pre {
	white-space: pre-wrap;
	word-wrap: break-word;
}
.boxed {
	font-size: 12px;
	white-space: pre-wrap;
	font-family: Courier;
	width: 100%;
	border: 1px solid black;
	overflow: hidden;
}
</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-left:20px;">
<spacer height="10" />
<label label="A sample transformation will now be run using the XSLT Gateway server. Results will appear below:" labelClass="normal" />
<spacer height="10" />
<!-- <label labelClass="cmd" value="Do ##class(XSLT2.Examples).Example1()" />
<spacer height="10" /> -->
<html id="Area1" OnDrawContent="DrawArea1" enclosingClass="boxed" hidden="true" />
<spacer height="10" />
</pane>
}

/// Provide HTML content according to the action.
Method DrawArea1(pSeed As %String) As %Status
{
	If '%page.Draw1 Quit $$$OK

	&html<<pre>>
	Do ..Example1()
	&html<</pre>>
	Quit $$$OK
}

/// This demonstrates a transformation by simply sorting the elements within the XML
/// The difference between this method and the one in XSLT2.Examples is that here
/// we escape the output as it is displayed in HTML contents, and change to namespace SAMPLES.
ClassMethod Example1() As %String
{
    #dim tSC As %Status = $$$OK
    
    #dim e As %Exception.AbstractException
    #dim tOutput As %Stream
    
    try {
        #; Get a stream of XML from the ExampleXML block contained in this class
        Set tSource=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||ExampleXML").Data
        If '$IsObject(tSource) Set tSC=%objlasterror Quit
        
        #; Get a stream of XSL from the ExampleXSL block contained in this class
        Set tXSL=##class(%Dictionary.CompiledXData).%OpenId($classname()_"||Example1XSL").Data
        If '$IsObject(tXSL) Set tSC=%objlasterror Quit
        
        #; Transform the source according to the XSL
        Set tSC=##class(%XML.XSLT2.Transformer).TransformStream(tSource,tXSL,.tOutput)
        If $$$ISERR(tSC) Quit
        
        #; Print the result to the current device, with HTML-escaping
        Set tSC=tOutput.Rewind()
        If $$$ISOK(tSC) {
	        If 'tOutput.Size {
		        Write $$$TextHTML("(No results)"),!
	        }
	        Else {
	        	Set tString=tOutput.Read(tOutput.Size)
	        	Write $ZCVT(tString,"O","HTML")
	        }
        }
        
    } catch (e) {
        Set tSC=e.AsStatus()
    }
       
    If $$$ISERR(tSC) Write $ZCVT($System.Status.GetErrorText(tSC),"O","HTML")
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Test XSLT Gateway server")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return '';
}

/// If the user presses the ENTER key, this popup window will close.
ClientMethod onkeydownHandler(evt) [ Language = javascript ]
{
	if (evt.keyCode == zenESC) {
		zenPage.dialogFinish();
	}
	else if (evt.keyCode == zenENTER) {
		zenPage.dialogFinish();
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	zenSetProp('btnOK','caption',$$$Text("Close"));

	// Run example
	zenPage.Draw1 = 1;
	var html = zen('Area1');
		setTimeout(function() {
			html.refreshContents(true);
			zenSetProp('Area1','hidden',false);
		}, 500);
}

XData ExampleXML
{
<?xml version="1.0" encoding="UTF-8"?>
<world>
<country name="Canada" continent="North America">
<city>Toronto</city>
<city>Vancouver</city>
</country>
<country name="Jamaica" continent="North America">
<city>Kingston</city>
<city>Ocho Rios</city>
</country>
<country name="United States" continent="North America">
<city>Boston</city>
<city>Baltimore</city>
</country>
<country name="United Kingdom" continent="Europe">
<city>London</city>
<city>Glasgow</city>
</country>
<country name="France" continent="Europe">
<city>Paris</city>
<city>Nice</city>
</country>
<country name="Japan" continent="Asia">
<city>Tokyo</city>
<city>Osaka</city>
</country>
</world>
}

XData Example1XSL
{
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"  exclude-result-prefixes="fo xs xdt fn" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xdt="http://www.w3.org/2005/xpath-datatypes">
<xsl:template match="/">
<xsl:element name="world">
<xsl:for-each-group select="//country" group-by="@continent">
<xsl:sort select="@continent" data-type="text" order="ascending"/>
<xsl:variable name="continent" select="@continent"/>
<xsl:apply-templates select="//country[@continent = $continent]" mode="group">
<xsl:sort select="@name" data-type="text" order="ascending"/>
</xsl:apply-templates>
</xsl:for-each-group>
</xsl:element>
</xsl:template>
<xsl:template match="*" mode="group">
<xsl:copy-of select="."/>
</xsl:template>
</xsl:stylesheet>
}

}
