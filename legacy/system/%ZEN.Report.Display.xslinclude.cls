/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The &lt;xslinclude&gt; tag provides a mechanism for including
/// external XSLT stylesheets in the PDF report.
Class %ZEN.Report.Display.xslinclude Extends node [ Deprecated, System = 4 ]
{

/// Specifies the location of the external XSLT stylesheet.<br>
/// Multiple stylesheets can be linked by entering a 
/// comma-delimited list.
Property href As %ZEN.Datatype.uri;

Property makeAbsoluteURL As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Do ..%NormalizeList(..href,.hrefs)
	Set idx=$o(hrefs(""))
	while (idx'="") {
		s url=..%GetAbsoluteURL(idx,.context,1)
		Set tCSPtoFile=0
		if $D(%request) {
			Set tCSPtoFile=$G(%request.Data("$CSPTOFILE",1),0)
		}

		if $D(%session)&&'tCSPtoFile {
			s sep="?"
			i url["?" s sep="&"
			s url=url_sep_"CSPCHD="_%session.CSPSessionCookie_"&CSPSHARE=1"
		} else {
			if (tCSPtoFile) {
				set tStatus=##class(%ZEN.Report.Display.node).CSPLinkToFileLink(idx, .url, "xsl")
			} else {
				if ..makeAbsoluteURL {
					set tStatus=##class(%ZEN.Report.Display.node).CSPLinkToFileLink(idx, .url, "xsl",1) ; Prodlog 107232
				}
			}
		}
		Do XSL.WriteLine("<xsl:include href='"_$zcvt(url,"O","XML")_"'/>")
		Set idx=$o(hrefs(idx))
	}
	d ..%EndDrawFo(.context,.XSL,.delay)	
	Quit $$$OK
}

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	Quit $$$OK
}

Method %NormalizeList(list As %String, ByRef array) As %Status
{
	For i=1:1:$l(list,",") {
		Set item=$p(list,",",i)
		Set:item'="" array(item)=""
	}

	Quit $$$OK
}

}
