/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Renders a xy chart (scatter plot).
Class %ZEN.Report.Display.Chart.xyChart Extends chart [ Deprecated, System = 4 ]
{

/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 1;

Method renderSeries(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream)
{

	do ..renderMarkers(.context,.XSL,.delay)
		
	Quit $$$OK
}

Method renderMarkers(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream)
{
	Set mode1 = "legend"_$$$groupNum
		
	If ..seriesGroup = "" {
		Set seriestemplatename="chartmarkers"_$$$groupNum
		Do XSL.WriteLine("<xsl:call-template name='"_seriestemplatename_"'>")
		Do ..writeWithParams(.XSL)
		Do XSL.WriteLine("</xsl:call-template>")
	} Else {
		Set seriestemplatename = ..seriesGroup
		Set mode = "chartmarkers"_$$$groupNum

		Do XSL.WriteLine("<xsl:apply-templates select='"_..qualify(seriestemplatename)_"' mode='"_mode_"'>")
		Do ..writeWithParams(.XSL)
		Do XSL.WriteLine("</xsl:apply-templates>")
	}	

	#; **** SERIES *****
	If ..seriesGroup="" {
		Do delay.WriteLine("<xsl:template name='"_seriestemplatename_"'>")
	} Else {
		Do delay.WriteLine("<xsl:template match='"_..qualify(seriestemplatename)_"' mode='"_mode_"' >")
	}

	Do ..writeLoadParams(.delay)

	// if no seriesGroup, we can get series number from position within XML file
	If ..seriesGroup="" {
		Do delay.WriteLine("  <xsl:variable name='series' select='position()' />")
	} Else {
		Do delay.WriteLine("  <xsl:param name='series' select='1'/>")
	}

	// make sure we have data
	Do delay.WriteLine("  <xsl:if test='($"_$$$seriessize_" &gt; 0) and ($"_$$$seriescount_" &gt; 0)'>")
	
	// set up variables
	Do delay.WriteLine("    <xsl:variable name='dx'>")
	Do delay.WriteLine("      <xsl:choose><xsl:when test='$"_$$$seriessize_" = 1'>")
	Do delay.WriteLine("        <xsl:value-of select='$plotWidth"_mode1_"' />")
	Do delay.WriteLine("      </xsl:when><xsl:otherwise>")
	Do delay.WriteLine("         <xsl:value-of select='$plotWidth"_mode1_" div ($"_$$$seriessize_" - 1)' />")
	Do delay.WriteLine("      </xsl:otherwise></xsl:choose>")
	Do delay.WriteLine("    </xsl:variable>")
	Do delay.WriteLine("    <xsl:variable name='adj' select='$dx' />")
	Do delay.WriteLine("    <xsl:variable name='base' select='$"_$$$yBase_"' />")
	Set datatemplatename="markerdata"_$$$groupNum

	Set xdata=$p(..dataFields,",",1)
	Set xdata=$zstrip(xdata,"<>W")
	If $e(xdata)="!" {
		// XPath expression
		Set xdata = $e(xdata,2,$l(xdata))
	} Else {
		// literal
			Set xdata = "'"_xdata_"'"
	}
			
	For i=2:1:$l(..dataFields,",") {
		Set data=$p(..dataFields,",",i)
		Set data=$zstrip(data,"<>W")
		If $e(data)="!" {
			// XPath expression
			Set data = $e(data,2,$l(data))
		} Else {
			// literal
			Set data = "'"_data_"'"
		}
		Do delay.WriteLine("<xsl:if test='string(number("_data_"))!=""NaN"" and string(number("_xdata_"))!=""NaN""'>")
		Do delay.WriteLine("      <xsl:call-template name='"_datatemplatename_"'>")
		Do delay.WriteLine("        <xsl:with-param name='adj' select='$adj'/>")
		Do delay.WriteLine("        <xsl:with-param name='item' select='"_(i-1)_"' />")
		Do delay.WriteLine("        <xsl:with-param name='xdata' select='"_xdata_"' />")
		Do delay.WriteLine("        <xsl:with-param name='data' select='"_data_"' />")
		Do delay.WriteLine("        <xsl:with-param name='series' select='"_(i-1)_"'/>")
		Do ..writeWithParams(.delay)
		Do delay.WriteLine("        <xsl:with-param name='dx' select='$dx'/>")
		Do delay.WriteLine("      </xsl:call-template>")
		Do delay.WriteLine("</xsl:if>")
	}
	If ..seriesGroup="" {
		Do delay.WriteLine("    <xsl:if test='$series &lt; $"_$$$seriescount_"'>")
		Do delay.WriteLine("      <xsl:call-template name='"_seriestemplatename_"'>")
		Do delay.WriteLine("        <xsl:with-param name='series' select='$series + 1' />")
		Do delay.WriteLine("      </xsl:call-template>")
		Do delay.WriteLine("    </xsl:if>")
	}
	Do delay.WriteLine("  </xsl:if>")
	Do delay.WriteLine("</xsl:template>")
			
	#; **** ITEMS *****
	
	// Open template and load in params
	Do delay.WriteLine("<xsl:template name='"_datatemplatename_"'>")
	Do delay.WriteLine("  <xsl:param name='item' select='1'/>")
	Do ..writeLoadParams(.delay)
	Do delay.WriteLine("  <xsl:param name='xdata'/>")
	Do delay.WriteLine("  <xsl:param name='data'/>")
	Do delay.WriteLine("  <xsl:param name='adj'/>")
	Do delay.WriteLine("  <xsl:param name='dx'/>")
	Do delay.WriteLine("  <xsl:param name='series'/>")
	Do delay.WriteLine("  <xsl:variable name='xraw' select='number($xdata)' />")
	Do delay.WriteLine("  <xsl:variable name='raw' select='number($data)' />")

	
	Do delay.WriteLine("<xsl:variable name='xval' select='$xraw' />")
	Do delay.WriteLine("<xsl:variable name='val' select='$raw' />")
	
	Do delay.WriteLine("<xsl:variable name='x'>")
	Do delay.WriteLine("  <xsl:choose><xsl:when test='$"_$$$xRange_" = 0'>")
	Set mode = "legend"_$$$groupNum
	Do delay.WriteLine("    <xsl:value-of select='$plotLeft"_mode_"' />")
	Do delay.WriteLine("  </xsl:when><xsl:otherwise>")
	Do delay.WriteLine("    <xsl:variable name='pct' select='($xval - $"_$$$xMin_") div $"_$$$xRange_"' />")
	Do delay.WriteLine("    <xsl:value-of select='(($pct) * $plotWidth"_mode1_")' />")
	Do delay.WriteLine("  </xsl:otherwise></xsl:choose>")
	Do delay.WriteLine("</xsl:variable>")
	o delay.WriteLine("<xsl:variable name='y'>")
	Do delay.WriteLine("  <xsl:choose><xsl:when test='$"_$$$yRange_" = 0'>")
	Do delay.WriteLine("    <xsl:value-of select='"_..plot.plotBottom_"' />")
	Do delay.WriteLine("  </xsl:when><xsl:otherwise>")
	Do delay.WriteLine("    <xsl:variable name='pct' select='($val - $"_$$$yMin_") div $"_$$$yRange_"' />")
	Do delay.WriteLine("    <xsl:value-of select='((1 - $pct) * "_..plot.plotHeight_")' />")
	Do delay.WriteLine("  </xsl:otherwise></xsl:choose>")
	Do delay.WriteLine("</xsl:variable>")
	
	#;Do delay.WriteLine("<xsl:value-of select='concat(($x - $adj),"" "",$y,"" "")'/>")
	; call draw marker here
	Do delay.WriteLine("<xsl:call-template name='zenReportDrawMarker"_$$$groupNum_"'>")
	Do delay.WriteLine("<xsl:with-param name='x' select='$x' />")
	Do delay.WriteLine("<xsl:with-param name='y' select='$y' />")
	Do delay.WriteLine("<xsl:with-param name='shape'>")
	Do delay.WriteLine("<xsl:call-template name='zenReportGetSeriesMarker"_$$$groupNum_"'>")
	Do delay.WriteLine("<xsl:with-param name='series' select='$series - 1'/>")
	Do delay.WriteLine("</xsl:call-template>")
	Do delay.WriteLine("  </xsl:with-param>")
	Do delay.WriteLine("<xsl:with-param name='color'>")
	Do delay.WriteLine("<xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
	Do delay.WriteLine("<xsl:with-param name='series' select='$series'/>")
	Do delay.WriteLine("</xsl:call-template>")
	Do delay.WriteLine("  </xsl:with-param>")

	Do delay.WriteLine("</xsl:call-template>")

	

	Do delay.Write("</xsl:template>")
		
	Quit $$$OK
}

/// Return the type of x axis (category or value) used by
/// this chart.
Method getXAxisType() As %String
{
	Quit "value"
}

/// Return the type of y axis (category or value) used by
/// this chart.
Method getYAxisType() As %String
{
	Quit "value"
}

}
