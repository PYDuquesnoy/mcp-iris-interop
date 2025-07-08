/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Display.link Extends (contentNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

Property children As list Of node(XMLPROJECTION = "NONE");

Property destination As %ZEN.Datatype.string;

Property internal As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property name As %ZEN.Datatype.string;

/// show-destination attribute of fo:basic-link
Property showDestination As %ZEN.Datatype.string(XMLNAME = "show-destination") [ InitialExpression = "replace" ];

/// indicate-destination attribute of fo:basic-link
Property indicateDestination As %ZEN.Datatype.string(XMLNAME = "indicate-destination") [ InitialExpression = "false" ];

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, incell As %Boolean = 0) As %Status
{
	set sc=$$$OK
	do ..%BeginDrawHtml(.context,.XSL,.delay)	
	do XSL.WriteLine("<a>") $$$stylehtml
	if ..destination'="" {
		Set destination = ..destination
		if ..internal {
			Set destination = "concat(&quot;#&quot;,"_..destination_")"
		}
		do XSL.WriteLine("<xsl:attribute name='href'>")
		do XSL.WriteLine("<xsl:value-of select='"_destination_"'/>")
		do XSL.WriteLine("</xsl:attribute>")
	}
	if ..name'=""{
		do XSL.WriteLine("<xsl:attribute name='name'>")
		do XSL.WriteLine("<xsl:value-of select='"""_..name_"""'/>")
		do XSL.WriteLine("</xsl:attribute>")
	}
	if ..content'=$c(0) Do XSL.WriteLine("<![CDATA["_..content_"]]>")
	Do XSL.WriteLine("</a>")
	do ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit sc
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	set sc=$$$OK
	do ..%BeginDrawFo(.context,.XSL,.delay)
	do XSL.WriteLine("<fo:basic-link"_$$$applyclass("link",.context)_">") 
	If 'incell $$$stylefo
	if ..destination'="",..internal=0 {
		do XSL.WriteLine("<xsl:attribute name='external-destination'>")
		do XSL.WriteLine("<xsl:value-of select='"_..destination_"'/>")
		do XSL.WriteLine("</xsl:attribute>")
	}
	if ..destination'="",..internal=1 {
		do XSL.WriteLine("<xsl:attribute name='internal-destination'>")
		do XSL.WriteLine("<xsl:value-of select='"_..destination_"'/>")
		do XSL.WriteLine("</xsl:attribute>")
	
	}
	Do XSL.WriteLine("<xsl:attribute name='show-destination'>"_..showDestination_"</xsl:attribute>")
	Do XSL.WriteLine("<xsl:attribute name='indicate-destination'>"_..indicateDestination_"</xsl:attribute>")

	if ..content'=$c(0) Do XSL.WriteLine("<![CDATA["_..content_"]]>")
	Do XSL.WriteLine("</fo:basic-link>")
	do ..%EndDrawFo(.context,.XSL,.delay)		
	Quit sc
}

}
