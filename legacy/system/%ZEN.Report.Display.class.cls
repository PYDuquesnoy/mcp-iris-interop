/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>Specifies a style class for the report display.  Classes represent
/// CSS classes for HTML reports, and attribute-sets for PDF reports.</P>
/// 
/// <p>When naming a class, one should use something of the form "tag.class".
/// The tags refer directly to HTML tags like &lt;td&gt;, &lt;th&gt;, &lt;table&gt;, &lt;a&gt;, &lt;p&gt;, etc.
/// In the HTML report, this converts directly to CSS so that the cells of 
/// a table take on the style of td.theirclass, the header row/column takes
/// on the style of th.theirclass, etc.  In the PDF report, the tag names are
/// different, but the use-attribute-set attribute is automatically adjusted
/// to take this into account.  That is, a table cell with class="test" will
/// use the style defined by the tag &lt;class name="td.test"/&gt;.  Similarly
/// for &lt;th&gt;, &lt;table&gt;, &lt;td&gt;, &lt;a&gt;, &lt;p&gt;.</p>
Class %ZEN.Report.Display.class Extends childrenNode [ Deprecated, System = 4 ]
{

/// CSS class name. See class description for details.
Property name As %ZEN.Datatype.cssClass [ Required ];

Property children As list Of %ZEN.Report.Display.att(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
		Set sc=$$$OK
		d ..tagChildren()
		d ..%BeginDrawFo(.context,.XSL,.delay)		
		Set:..name'="" context("class",..name)=""
		Do XSL.WriteLine("<xsl:attribute-set name='"_..name_"'>")
		Set j=..children.Next("")
		While j'="" {
			Set att=..children.GetAt(j)
			d ..updateFromTemplate(.att)			
			Set sc=att.%DrawToXSLFO(.context,.XSL,.delay) Quit:$$$ISERR(sc)
			Set j=..children.Next(j)
		}
		Do XSL.WriteLine("</xsl:attribute-set>")
		d ..%EndDrawFo(.context,.XSL,.delay)			
		Quit sc
}

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
		Set sc=$$$OK
		d ..tagChildren()
		d ..%BeginDrawHtml(.context,.XSL,.delay)		
		Do XSL.WriteLine(..name_" {")
		Set j=..children.Next("")
		While j'="" {
			Set att=..children.GetAt(j)
			d ..updateFromTemplate(.att)	
			Set sc=att.%DrawToHTML(.context,.XSL,.delay) Quit:$$$ISERR(sc)
			Set j=..children.Next(j)
		}
		Do XSL.WriteLine("}")
		d ..%EndDrawHtml(.context,.XSL,.delay)	
		Quit sc
}

}
