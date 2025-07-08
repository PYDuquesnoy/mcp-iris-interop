/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Renders an image into the report display.
Class %ZEN.Report.Display.img Extends (childrenNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// Specifies the source of the image. 
/// 
/// If the src attribute begins with an exclamation point, it is interpreted 
/// as an XPath expression just as in the field attribute of the &lt;item&gt; tag.
/// This allows you to dynamically generate URLs within the XML data, and then
/// use these customized URLs as the image source.  Note: when using ! to dynamically
/// get the image URL, it must be an absolute URL or it will not appear in the PDF
/// report.
Property src As %ZEN.Datatype.uri [ Required ];

/// Specifies the height of the image.
Property height As %ZEN.Datatype.length;

/// Specifies the width of the image.
Property width As %ZEN.Datatype.length;

/// Specifies the height of the image.
Property contentHeight As %ZEN.Datatype.length;

/// Specifies the width of the image.
Property contentWidth As %ZEN.Datatype.length;

/// Specifies the content-type of the image
Property contentType As %ZEN.Datatype.string(XMLNAME = "content-type");

Property altText As %ZEN.Datatype.string(XMLNAME = "alt-text");

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
     d ..%BeginDrawHtml(.context,.XSL,.delay)
	 Set ..src=$zstrip(..src,"<>W")
	 If $e(..src)="!" {
		 Set src="<xsl:value-of select='"_$e(..src,2,$l(..src))_"'/>"
	 } Else {
		 Set src=..src
	 }
	 Do XSL.WriteLine("<img>")
	 Do XSL.WriteLine("<xsl:attribute name='style'>")
	 Do:(..height'="")&&(..contentHeight="") XSL.Write("height:"_..processExclamationPoint(..height)_";")
	 Do:(..width'="")&&(..contentWidth="") XSL.Write("width:"_..processExclamationPoint(..width)_";")
 	 Do:..contentHeight'="" XSL.Write("height:"_..processExclamationPoint(..contentHeight)_";")
	 Do:..contentWidth'="" XSL.Write("width:"_..processExclamationPoint(..contentWidth)_";")
	 Do XSL.WriteLine("</xsl:attribute>")
	 Do XSL.Write("<xsl:attribute name='src'>"_src_"</xsl:attribute></img>")
     d ..%EndDrawHtml(.context,.XSL,.delay)	
	 Quit $$$OK
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Set ..src=$zstrip(..src,"<>W")
	If $e(..src)="!" {
		Set src="<xsl:value-of select='concat(&quot;url(&quot;,"_$e(..src,2,$l(..src))_",&quot;)&quot;)'/>"
	} Else {
		Set src="url("_..%GetAbsoluteURL(..src,.context,1)_")"
	}
	Do XSL.WriteLine("<fo:block>") 
	If 'incell $$$stylefo
	Do XSL.WriteLine("<fo:external-graphic>")
	Do:..altText'="" XSL.WriteLine("<xsl:attribute name='fox:alt-text'>"_..altText_"</xsl:attribute>")
	Do:(..height'="")&&(..contentHeight="") XSL.WriteLine("<xsl:attribute name='height'>"_..processExclamationPoint(..height)_"</xsl:attribute>")
	Do:(..width'="")&&(..contentWidth="") XSL.WriteLine("<xsl:attribute name='width'>"_..processExclamationPoint(..width)_"</xsl:attribute>")
	Do:..contentHeight'="" XSL.WriteLine("<xsl:attribute name='content-height'>"_..processExclamationPoint(..contentHeight)_"</xsl:attribute>")
	Do:..contentWidth'="" XSL.WriteLine("<xsl:attribute name='content-width'>"_..processExclamationPoint(..contentWidth)_"</xsl:attribute>")
	Do:..contentType'="" XSL.WriteLine("<xsl:attribute name='content-type'>"_..processExclamationPoint(..contentType)_"</xsl:attribute>")

	Do XSL.WriteLine("<xsl:attribute name='src'>"_src_"</xsl:attribute></fo:external-graphic>")
	Do XSL.WriteLine("</fo:block>")
	d ..%EndDrawFo(.context,.XSL,.delay)		 
	Quit $$$OK
}

}
