/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// If an element within a table has a &lt;caption&gt; tag as a child, it defines
/// the data that will be placed in the header row or column for that
/// element.  If no element within a table has a &lt;caption&gt; tag, no footer
/// row/column is generated.  If one does not desire special styling for
/// the caption, one can also use a caption attribute on most tags as
/// a short-hand.
Class %ZEN.Report.Display.caption Extends item [ Deprecated, System = 4 ]
{

Property group As %ZEN.Datatype.string(XMLPROJECTION = "none");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

Method %DrawCellToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
	if (..grouppath="") {
		Set sc=..%DrawCellToHTML1(.context,.XSL,.delay)
	} else {
		Set mode="caption"
		Do XSL.WriteLine("<xsl:apply-templates select='"_..qualify(..grouppath)_"' mode='"_mode_"' />")		
		Set delay2=##class(%GlobalCharacterStream).%New()
		Do delay.WriteLine("<xsl:template match='"_..qualify(..grouppath)_"' mode='"_mode_"'>")
		Set sc=..%DrawCellToHTML1(.context,.delay,.delay2)
		Do delay.WriteLine("</xsl:template>")
		Do delay.CopyFrom(delay2)

	}
	Quit sc
}

Method %DrawCellToHTML1(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
	
	Set sc = ..%BeginHTMLIf(.context, .XSL, .delay)
	q:'$$$ISOK(sc) sc
	if ..colcount'="" {	
		$$$varNumInc
		Do XSL.WriteLine("<xsl:variable name='tr"_$$$varNum_"'>")
		Do XSL.WriteLine("<![CDATA[")
		Do XSL.WriteLine("<tr>")
		Do XSL.WriteLine("]]>")
		Do XSL.WriteLine("</xsl:variable>")
		Do XSL.WriteLine("<xsl:variable name='etr"_$$$varNum_"'>")
		Do XSL.WriteLine("<![CDATA[")
		Do XSL.WriteLine("</tr>")
		Do XSL.WriteLine("]]>")
		Do XSL.WriteLine("</xsl:variable>")
		Do XSL.WriteLine("<xsl:if test='(position() mod "_..colcount_")=1 or (("_..colcount_") = 1)'>")
		Do XSL.WriteLine("<xsl:value-of select='$tr"_$$$varNum_"' disable-output-escaping='yes'/>")
		Do XSL.WriteLine("</xsl:if>")
	}

	Do XSL.WriteLine("<th>") Do ..%StyleHTML(.context,.XSL,.delay,"",1)
	q:'$$$ISOK(sc) sc
	Set sc = ..%DrawToHTML(.context, .XSL, .delay,1)
	q:'$$$ISOK(sc) sc
	Do XSL.WriteLine("</th>")
	if ..colcount'="" {
		Do XSL.WriteLine("<xsl:if test='(position() mod "_..colcount_") = 0'>")
		Do XSL.WriteLine("<xsl:value-of select='$etr"_$$$varNum_"' disable-output-escaping='yes'/>")
		Do XSL.WriteLine("</xsl:if>")
	}
	
	Set sc = ..%EndHTMLIf(.context, .XSL, .delay)
	q:'$$$ISOK(sc) sc
	
	q sc
}

Method %DrawCellFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
	if (..grouppath="") {
		Set sc=..%DrawCellFO1(.context, .XSL, .delay)
		Quit sc
	} else {
		$$$captionNumInc
		Set mode="caption"_$$$captionNum
		Do XSL.WriteLine("<xsl:apply-templates select='"_..qualify(..grouppath)_"' mode='"_mode_"' />")		
		Set delay2=##class(%GlobalCharacterStream).%New()
		Do delay.WriteLine("<xsl:template match='"_..qualify(..grouppath)_"' mode='"_mode_"'>")
		Set sc=..%DrawCellFO1(.context, .delay, .delay2)		
		Do delay.WriteLine("</xsl:template>")
		Do delay.CopyFrom(delay2)
		Quit sc

	}
}

Method %DrawCellFO1(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
		Set sc = ..%BeginFOIf(.context, .XSL, .delay)	
		q:'$$$ISOK(sc) sc	
#if 0		
		if ..colcount'="" {
			$$$varNumInc
			Do XSL.WriteLine("<xsl:variable name='ctr"_$$$varNum_"'>")
			Do XSL.WriteLine("<![CDATA[")
			Do XSL.WriteLine("<fo:table-row>")
			Do XSL.WriteLine("]]>")
			Do XSL.WriteLine("</xsl:variable>")
			Do XSL.WriteLine("<xsl:variable name='cetr"_$$$varNum_"'>")
			Do XSL.WriteLine("<![CDATA[")
			Do XSL.WriteLine("</fo:table_row>")
			Do XSL.WriteLine("]]>")
			Do XSL.WriteLine("</xsl:variable>")
			Do XSL.WriteLine("<xsl:if test='(position() mod "_..colcount_") = 1'>")
			Do XSL.WriteLine("<xsl:value-of select='$ctr"_$$$varNum_"' disable-output-escaping='yes'/>")
			Do XSL.WriteLine("</xsl:if>")
		}
#endif
		Do XSL.WriteLine("<!-- cell for caption -->")
		if ..breakOnLineFeed {
			Set ..linefeedTreatment="preserve"
		}

		Do XSL.WriteLine("<fo:table-cell "_$$$applyclass("th",.context)_">") Do ..%StyleXSLFO(.context,.XSL,.delay, 1,1) 
		if ..colcount'="" {
			Do XSL.WriteLine("<xsl:if test='(position() mod "_..colcount_") = 0'>")
			Do XSL.WriteLine("<xsl:attribute name='ends-row'>true</xsl:attribute>")
			Do XSL.WriteLine("</xsl:if>")
		}

		Do XSL.WriteLine("<fo:block"_$s(..linefeedTreatment'="":" linefeed-treatment='"_..linefeedTreatment_"'",1:"")_">")
		q:'$$$ISOK(sc) sc
		Set sc= ..%DrawToXSLFO(.context,.XSL,.delay,1)
		q:'$$$ISOK(sc) sc
		Do XSL.WriteLine("</fo:block></fo:table-cell>")
#if 0		
		if ..colcount'="" {
			Do XSL.WriteLine("<xsl:if test='(position() mod "_..colcount_") = 0'>")
			Do XSL.WriteLine("<xsl:value-of select='$cetr"_$$$varNum_"' disable-output-escaping='yes'/>")
			Do XSL.WriteLine("</xsl:if>")
		}
#endif
		Set sc = ..%EndFOIf(.context, .XSL, .delay)	
		q:'$$$ISOK(sc) sc	
		Quit sc
}

}
