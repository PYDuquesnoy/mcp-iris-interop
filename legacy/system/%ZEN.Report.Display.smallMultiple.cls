/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.Display.smallMultiple Extends %ZEN.Report.Display.childrenNode [ Deprecated, System = 4 ]
{

Parameter XMLNAME = "small-multiple";

/// num-rows: number of rows in table holding small multiple
Property numrows As %ZEN.Datatype.integer(XMLNAME = "num-rows");

/// num-cols: number of columns in table holding small multiple
Property numcols As %ZEN.Datatype.integer(XMLNAME = "num-cols");

/// table-class: table CSS class or attribute-set
Property tableClass As %ZEN.Datatype.cssClass(XMLNAME = "table-class");

/// table-style: table CSS style
Property tableStyle As %ZEN.Datatype.style(MAXLEN = 2048, XMLNAME = "table-style");

/// table-width: table width
Property tableWidth As %ZEN.Datatype.string(XMLNAME = "table-width");

/// row-class: row CSS class or attribute-set
Property rowClass As %ZEN.Datatype.cssClass(XMLNAME = "row-class");

/// row-style: row CSS style
Property rowStyle As %ZEN.Datatype.style(XMLNAME = "row-style");

/// row-width: row width
Property rowWidth As %ZEN.Datatype.string(XMLNAME = "row-width");

/// col-class: column CSS class or attribute set
Property colClass As %ZEN.Datatype.cssClass(XMLNAME = "col-class");

/// col-style: column CSS style
Property colStyle As %ZEN.Datatype.style(XMLNAME = "col-style");

/// col-width: column width
Property colWidth As %ZEN.Datatype.string(XMLNAME = "col-width");

/// name: name of small-multiple defaults to "small-multiple".  Must be specified to have more than one on a page.
Property name As %ZEN.Datatype.string(XMLNAME = "name") [ InitialExpression = "small-multiple" ];

/// fill-order is used to define how the small multiple is filled by the temporary tree defined by the group which is a collection of 
/// zr:small-multiple XML elements; horizontal means that as elements are encountered, they should fill a small mutiple across rows before 
/// moving down columns; vertical means the first column on the small multiple should be filled before moving on to the next. The default is horizontal.
Property fillOrder As %ZEN.Datatype.string(VALUELIST = ",horizontal,vertical", XMLNAME = "fill-order") [ InitialExpression = "horizontal" ];

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)	
	Set sc=$$$OK
	if (+$g(%context("smallmultiplexsl")) = 0) {
		Do ##class(%ZEN.Report.Display.report).%CopyReportPageXdata(.delay,"SmallMultipleCommonXSL") ; Common XSL for small-multipe
		Do ##class(%ZEN.Report.Display.report).%CopyReportPageXdata(.delay,"SmallMultipleHTMLXSL") ; Common XSL for small-multiple
		Set %context("smallmultiplexsl")=1
	}
	Do delay.WriteLine("<xsl:template name='"_..name_"'>")
	Do delay.WriteLine("<xsl:param name='repeating-content'/>")
	Do delay.WriteLine("<xsl:param name='pos' select='1'/>")
	Do delay.WriteLine("<xsl:choose>")
	Do delay.WriteLine("<xsl:when test='$pos > count($repeating-content/zr:small-multiple)'>")
	Do delay.WriteLine("</xsl:when>")
	Do delay.WriteLine("<xsl:otherwise>")
	Do delay.WriteLine("<table>") Do ..HTMLStyle(.context,.delay,.delay2,..tableStyle,..tableClass,..tableWidth)
	for i=1:1:..numrows {
		Do delay.WriteLine("<tr>") Do ..HTMLStyle(.context,.delay,.delay2,..rowStyle,..rowClass,..rowWidth)
		for j=1:1:..numcols {
			Do delay.WriteLine("<td>") Do ..HTMLStyle(.context,.delay,.delay2,..colStyle,..colClass,..colWidth)
			if ..fillOrder = "horizontal" {
				Do delay.WriteLine("<xsl:copy-of select='$repeating-content/zr:small-multiple[position()=$pos+"_((i-1)*..numcols+(j-1))_"]/*'/>")
			} else {
				Do delay.WriteLine("<xsl:copy-of select='$repeating-content/zr:small-multiple[position()=$pos+"_((j-1)*..numrows+(i-1))_"]/*'/>")
			}
			Do delay.WriteLine("</td>")
		}
		Do delay.WriteLine("</tr>")
		
		
	}
	Do delay.WriteLine("</table>")
	Do delay.WriteLine("<xsl:call-template name='"_..name_"'>")
	Do delay.WriteLine("<xsl:with-param name='repeating-content' select='$repeating-content'/>")
	Do delay.WriteLine("<xsl:with-param name='pos' select='$pos+"_(..numrows*..numcols)_"'/>")
	Do delay.WriteLine("</xsl:call-template>")
	Do delay.WriteLine("</xsl:otherwise>")
	Do delay.WriteLine("</xsl:choose>")
	Do delay.WriteLine("</xsl:template>")
	
	Do XSL.WriteLine("<xsl:call-template name='"_..name_"'>")
	Do XSL.WriteLine("<xsl:with-param name='repeating-content' select='$"_..name_"'/>")
    Do XSL.WriteLine("</xsl:call-template>")
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit sc
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Set sc=$$$OK
	if (+$g(%context("smallmultiplexsl")) = 0) {
		Do ##class(%ZEN.Report.Display.report).%CopyReportPageXdata(.delay,"SmallMultipleCommonXSL") ; Common XSL for small-multipe
		Do ##class(%ZEN.Report.Display.report).%CopyReportPageXdata(.delay,"SmallMultipleFOXSL") ; Common XSL for small-multiple
		Set %context("smallmultiplexsl")=1
	}
	
	Do delay.WriteLine("<xsl:template name='"_..name_"'>")
	Do delay.WriteLine("<xsl:param name='repeating-content'/>")
	Do delay.WriteLine("<xsl:param name='pos' select='1'/>")
	Do delay.WriteLine("<xsl:choose>")
	Do delay.WriteLine("<xsl:when test='$pos > count($repeating-content/zr:small-multiple)'>")
	Do delay.WriteLine("</xsl:when>")
	Do delay.WriteLine("<xsl:otherwise>")
	Do delay.WriteLine("<fo:table"_..ApplyClass(..tableClass,"table",.context)_" keep-together.within-page='1'>") Do ..XSLFOStyle(.context,.delay,.delay2,..tableStyle,..tableClass,..tableWidth)
	Do delay.WriteLine("<fo:table-body>")	
	for i=1:1:..numrows {
		Do delay.WriteLine("<fo:table-row>") Do ..XSLFOStyle(.context,.delay,.delay2,..rowStyle,..rowClass,..rowWidth)
		for j=1:1:..numcols {
			Do delay.WriteLine("<fo:table-cell"_..ApplyClass(..colClass,"td",.context)_">") Do ..XSLFOStyle(.context,.delay,.delay2,..colStyle,..colClass,..colWidth)
			Do delay.WriteLine("<fo:block>")
			Do delay.WriteLine("<xsl:copy-of select='$repeating-content/zr:small-multiple[position()=$pos+"_((i-1)*..numcols+(j-1))_"]/*'/>")
			Do delay.WriteLine("</fo:block>")
			Do delay.WriteLine("</fo:table-cell>")
		}
		Do delay.WriteLine("</fo:table-row>")
		
		
	}
	Do delay.WriteLine("</fo:table-body>")	
	Do delay.WriteLine("</fo:table>")	

	Do delay.WriteLine("<xsl:call-template name='"_..name_"'>")
	Do delay.WriteLine("<xsl:with-param name='repeating-content' select='$repeating-content'/>")
	Do delay.WriteLine("<xsl:with-param name='pos' select='$pos+"_(..numrows*..numcols)_"'/>")
	Do delay.WriteLine("</xsl:call-template>")
	Do delay.WriteLine("</xsl:otherwise>")
	Do delay.WriteLine("</xsl:choose>")
	Do delay.WriteLine("</xsl:template>")
	
	Do XSL.WriteLine("<xsl:call-template name='"_..name_"'>")
	Do XSL.WriteLine("<xsl:with-param name='repeating-content' select='$"_..name_"'/>")
    Do XSL.WriteLine("</xsl:call-template>")

	Quit sc
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit sc
}

}
