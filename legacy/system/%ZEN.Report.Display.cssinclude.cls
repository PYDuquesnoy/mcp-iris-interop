/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The &lt;cssinclude&lt; tag provides a mechanism for including
/// external CSS stylesheets in the HTML report.
Class %ZEN.Report.Display.cssinclude Extends node [ Deprecated, System = 4 ]
{

/// Specifies the location of the external css stylesheet.
/// Note: some browsers will have trouble if the file
/// does not end in .css.<br>
/// Multiple stylesheets can be linked by entering a 
/// comma-delimited list.
Property href As %ZEN.Datatype.uri;

Property makeAbsoluteURL As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	Quit $$$OK
}

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
   d ..%BeginDrawHtml(.context,.XSL,.delay)
   Do ..%NormalizeList(..href,.hrefs)
   Set idx=$o(hrefs(""))
   while (idx'="") {
      s url=..%GetAbsoluteURL(idx,.context)
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
            set tStatus=##class(%ZEN.Report.Display.node).CSPLinkToFileLink(idx, .url, "css")
         } else {
	         if ..makeAbsoluteURL {
		         set tStatus=##class(%ZEN.Report.Display.node).CSPLinkToFileLink(idx, .url, "css",1)
	         }
         }
      }
      Do XSL.WriteLine("<link rel='stylesheet' type='text/css' href='"_$zcvt(url,"O","HTML")_"'/>")
      Set idx=$o(hrefs(idx))
   }
   d ..%EndDrawHtml(.context,.XSL,.delay)
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
