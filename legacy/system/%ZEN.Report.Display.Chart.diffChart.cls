/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Renders a diff chart.
Class %ZEN.Report.Display.Chart.diffChart Extends chart [ Deprecated, System = 4 ]
{

/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 1;

/// If true, this is a <i>stacked</i> line chart. That is,
/// data series are plotted above one another.<br>
/// Note that negative values are ignored in stacked charts.
Property chartStacked As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, pivot this chart: display categories vertically
/// and values horizontally.
Property chartPivot As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property refLineStyle As %ZEN.Datatype.svgStyle [ InitialExpression = "stroke-dasharray: 1,1;" ];

Method renderSeries(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream)
{
	If (..dataGroup'="")  {
		Do XSL.WriteLine("<"_..SvgPrefix()_"text fill='red' text-anchor='middle' font-size='2pt' x='"_(..plot.plotWidth/2)_"' y='"_(..plot.plotHeight/2)_"'>")
		Do XSL.WriteLine("  Diff charts cannot have a dataGroup")
		Do XSL.WriteLine("</"_..SvgPrefix()_"text>")
		Quit $$$OK
	}
	If (..seriesGroup="")  {
		Do XSL.WriteLine("<"_..SvgPrefix()_"text fill='red' text-anchor='middle' font-size='2pt' x='"_(..plot.plotWidth/2)_"' y='"_(..plot.plotHeight/2)_"'>")
		Do XSL.WriteLine("  Diff charts must have a seriesGroup")
		Do XSL.WriteLine("</"_..SvgPrefix()_"text>")
		Quit $$$OK
	}

	If ..seriesGroup = "" {
		Set seriestemplatename="chartseries"_$$$groupNum
		Do XSL.WriteLine("<xsl:call-template name='"_seriestemplatename_"'>")
		Do ..writeWithParams(.XSL)
		Do XSL.WriteLine("</xsl:call-template>")
	} Else {
		Set seriestemplatename = ..seriesGroup
		Set mode = "chartseries"_$$$groupNum

		; draw polygon with all data points
		Do XSL.WriteLine("<"_..SvgPrefix()_"polygon>")
		s key="" for  s key=$o(context("SVGATTRS","chart-seriesLine",key)) q:key=""  d
		. Do XSL.WriteLine("  <xsl:attribute name='"_key_"'>"_context("SVGATTRS","chart-seriesLine",key)_"</xsl:attribute>")
		Do XSL.WriteLine("      <xsl:attribute name='style'>"_..plotStyle_"</xsl:attribute>")
		Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,..plotStyle)
		Do XSL.WriteLine("      <xsl:attribute name='fill'>")
		Do XSL.WriteLine("        <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
		Do XSL.WriteLine("          <xsl:with-param name='series' select='2'/>")
		Do XSL.WriteLine("        </xsl:call-template>")
		Do XSL.WriteLine("      </xsl:attribute>")
		Do XSL.WriteLine("      <xsl:attribute name='stroke'>")
		Do XSL.WriteLine("        <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
		Do XSL.WriteLine("          <xsl:with-param name='series' select='2'/>")
		Do XSL.WriteLine("        </xsl:call-template>")
		Do XSL.WriteLine("      </xsl:attribute>")
		Do XSL.WriteLine("      <xsl:attribute name='points'>")

		Do XSL.WriteLine("<xsl:apply-templates select='"_..qualify(seriestemplatename)_"[1]' mode='"_mode_"Forward'>")
		Do ..writeWithParams(.XSL)
		Do XSL.WriteLine("</xsl:apply-templates>")
		Do XSL.WriteLine("<xsl:apply-templates select='"_..qualify(seriestemplatename)_"[2]' mode='"_mode_"Reverse'>")
		Do ..writeWithParams(.XSL)
		Do XSL.WriteLine("</xsl:apply-templates>")
		Do XSL.WriteLine("</xsl:attribute>")
		Do XSL.WriteLine("</"_..SvgPrefix()_"polygon>")
		; draw line
		Do XSL.WriteLine("<xsl:apply-templates select='"_..qualify(seriestemplatename)_"[1]' mode='"_mode_"'>")
		Do ..writeWithParams(.XSL)
		Do XSL.WriteLine("</xsl:apply-templates>")

	}	

	#; **** SERIES ****			
	do ..renderSeries1(.context,.XSL,.delay,seriestemplatename,mode_"Reverse",.datatemplatename,2)
	do ..renderSeries1(.context,.XSL,.delay,seriestemplatename,mode_"Forward",.datatemplatename,3)
	do ..renderSeries1(.context,.XSL,.delay,seriestemplatename,mode,.datatemplatename,1)
	#; **** ITEMS *****
	
	// Open template and load in params
	If ..dataGroup="" {
		Do delay.WriteLine("<xsl:template name='"_datatemplatename_"'>")
		Do delay.WriteLine("  <xsl:param name='item' select='1'/>")
	} Else {
		Do delay.WriteLine("<xsl:template match='"_..qualify(datatemplatename)_"' mode='"_mode_"' >")
	}
	Do ..writeLoadParams(.delay)
	Do delay.WriteLine("  <xsl:param name='data'/>")
	Do delay.WriteLine("  <xsl:param name='adj'/>")
	If '..chartPivot {
		Do delay.WriteLine("  <xsl:param name='dx'/>")
	} Else {
		Do delay.WriteLine("  <xsl:param name='dy'/>")
	}
	If ..dataGroup'="" {
		Do delay.WriteLine("  <xsl:variable name='item' select='position()' />")
		Do delay.WriteLine("  <xsl:variable name='item' select='position()' />")
		Do delay.WriteLine("  <xsl:variable name='raw'>")
		Do delay.WriteLine("  <xsl:choose>")
		Do delay.WriteLine("    <xsl:when test='not("_data_")'>0</xsl:when>")
		Do delay.WriteLine("    <xsl:otherwise>")
		Do delay.WriteLine("      <xsl:value-of select='number("_data_")'/>")
		Do delay.WriteLine("     </xsl:otherwise>")
		Do delay.WriteLine("  </xsl:choose>")
		Do delay.WriteLine("  </xsl:variable>")

	} Else {
		Do delay.WriteLine("  <xsl:variable name='raw'>")
		Do delay.WriteLine("  <xsl:choose>")
		Do delay.WriteLine("    <xsl:when test='not($data)'>0</xsl:when>")
		Do delay.WriteLine("    <xsl:otherwise>")
		Do delay.WriteLine("      <xsl:value-of select='number($data)'/>")
		Do delay.WriteLine("     </xsl:otherwise>")
		Do delay.WriteLine("  </xsl:choose>")
		Do delay.WriteLine("  </xsl:variable>")

	}
	
	// For stacked chart, treat negative values as 0
	If ..chartStacked {
		#; should also increase val by summing and adjust base here...
		Do delay.WriteLine("<xsl:variable name='val'>")
		Do delay.WriteLine("  <xsl:choose><xsl:when test='$raw &lt; 0'>")
		Do delay.WriteLine("    0")
		Do delay.WriteLine("  </xsl:when><xsl:otherwise>")
		Do delay.WriteLine("    <xsl:value-of select='$raw' />")
		Do delay.WriteLine("  </xsl:otherwise></xsl:choose>")
		Do delay.WriteLine("</xsl:variable>")
	} Else {
		Do delay.WriteLine("<xsl:variable name='val' select='$raw' />")
	}
	Set mode1 = "legend"_$$$groupNum	
	If '..chartPivot {
		Do delay.WriteLine("<xsl:variable name='x' select='$item * $dx' />")
		Do delay.WriteLine("<xsl:variable name='y'>")
		Do delay.WriteLine("  <xsl:choose><xsl:when test='$"_$$$yRange_" = 0'>")
		Do delay.WriteLine("    <xsl:value-of select='"_..plot.plotBottom_"' />")
		Do delay.WriteLine("  </xsl:when><xsl:otherwise>")
		Do delay.WriteLine("    <xsl:variable name='pct' select='($val - $"_$$$yMin_") div $"_$$$yRange_"' />")
		Do delay.WriteLine("    <xsl:value-of select='((1 - $pct) * "_..plot.plotHeight_")' />")
		Do delay.WriteLine("  </xsl:otherwise></xsl:choose>")
		Do delay.WriteLine("</xsl:variable>")
		
		Do delay.WriteLine("<xsl:value-of select='concat(($x - $adj),"" "",$y,"" "")'/>")

	} Else {
		// pivotted
		Do delay.WriteLine("<xsl:variable name='y' select='$item * $dy' />")
		Do delay.WriteLine("<xsl:variable name='x'>")
		Do delay.WriteLine("  <xsl:choose><xsl:when test='$"_$$$xRange_" = 0'>")
		Do delay.WriteLine("    <xsl:value-of select='0' />")
		Do delay.WriteLine("  </xsl:when><xsl:otherwise>")
		Do delay.WriteLine("    <xsl:variable name='pct' select='($val - $"_$$$xMin_") div $"_$$$xRange_"' />")
		Do delay.WriteLine("    <xsl:value-of select='($pct * $plotWidth"_mode1_")' />")
		Do delay.WriteLine("  </xsl:otherwise></xsl:choose>")
		Do delay.WriteLine("</xsl:variable>")
		Do delay.WriteLine("<xsl:value-of select='concat($x,"" "",($y - $adj),"" "")'/>")
	}
	

	Do delay.Write("</xsl:template>")
	
	
	if ..markersVisible {
		do ..renderMarkers(.context,.XSL,.delay)
	}
		
	Quit $$$OK
}

Method renderSeries1(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, seriestemplatename As %String, mode As %String, ByRef datatemplatename, seriesNumber As %Integer)
{
	#; **** SERIES *****
	If ..seriesGroup="" {
		Do delay.WriteLine("<xsl:template name='"_seriestemplatename_"'>")
	} Else {
		If (seriesNumber=1) {
			Do delay.WriteLine("<xsl:template match='"_..qualify(seriestemplatename)_"' mode='"_mode_"' >")
		} else {
			Do delay.WriteLine("<xsl:template match='"_..qualify(seriestemplatename)_"' mode='"_mode_"' >")
		}
	}

	Do ..writeLoadParams(.delay)

	// if no seriesGroup, we can get series number from position within XML file
	If ..seriesGroup="" {
		Do delay.WriteLine("  <xsl:param name='series' select='1'/>")
	} Else {
		if (seriesNumber=1) {
			Do delay.WriteLine("  <xsl:variable name='series' select='position()' />")
		} else {

		}
	}

	// make sure we have data
	Do delay.WriteLine("  <xsl:if test='($"_$$$seriessize_" &gt; 0) and ($"_$$$seriescount_" &gt; 0)'>")
	Set mode1 = "legend"_$$$groupNum	
	// set up variables
	If '..chartPivot {
		Do delay.WriteLine("    <xsl:variable name='dx'>")
		Do delay.WriteLine("      <xsl:choose><xsl:when test='$"_$$$seriessize_" = 1'>")
		Do delay.WriteLine("        <xsl:value-of select='$plotWidth"_mode1_"' />")
		Do delay.WriteLine("      </xsl:when><xsl:otherwise>")
		Do delay.WriteLine("         <xsl:value-of select='$plotWidth"_mode1_" div ($"_$$$seriessize_" - 1)' />")
		Do delay.WriteLine("      </xsl:otherwise></xsl:choose>")
		Do delay.WriteLine("    </xsl:variable>")
		Do delay.WriteLine("    <xsl:variable name='adj' select='$dx' />")
		Do delay.WriteLine("    <xsl:variable name='base' select='$"_$$$yBase_"' />")
	} Else {
		Do delay.WriteLine("    <xsl:variable name='dy'>")
		Do delay.WriteLine("      <xsl:choose><xsl:when test='$"_$$$seriessize_" = 1'>")
		Do delay.WriteLine("        <xsl:value-of select='"_..plot.plotHeight_"' />")
		Do delay.WriteLine("      </xsl:when><xsl:otherwise>")
		Do delay.WriteLine("         <xsl:value-of select='"_..plot.plotHeight_" div ($"_$$$seriessize_" - 1)' />")
		Do delay.WriteLine("      </xsl:otherwise></xsl:choose>")
		Do delay.WriteLine("    </xsl:variable>")
		Do delay.WriteLine("    <xsl:variable name='adj' select='$dy' />")
		Do delay.WriteLine("    <xsl:variable name='base' select='$"_$$$xBase_"' />")
	}

	// set up series data line
	if (seriesNumber=1) {
		Do delay.WriteLine("    <"_..SvgPrefix()_"polyline class='chart-seriesLine'>")
	s key="" for  s key=$o(context("SVGATTRS","chart-seriesLine",key)) q:key=""  d
	. Do delay.WriteLine("  <xsl:attribute name='"_key_"'>"_context("SVGATTRS","chart-seriesLine",key)_"</xsl:attribute>")
	Do delay.WriteLine("      <xsl:attribute name='style'>"_..plotStyle_"</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.delay,..plotStyle)
	Do delay.WriteLine("      <xsl:attribute name='style'>"_..refLineStyle_"</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.delay,..refLineStyle)
	Do delay.WriteLine("      <xsl:attribute name='fill'>none</xsl:attribute>")
	Do delay.WriteLine("      <xsl:attribute name='stroke'>")
	Do delay.WriteLine("        <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
	if (seriesNumber=1) {
		Do delay.WriteLine("          <xsl:with-param name='series' select='$series'/>")
	} else {
		Do delay.WriteLine("          <xsl:with-param name='series' select='2'/>")
	}
	Do delay.WriteLine("        </xsl:call-template>")
	Do delay.WriteLine("      </xsl:attribute>")
	Do delay.WriteLine("      <xsl:attribute name='points'>")
	}

	If ..dataGroup="" {
		Set datatemplatename="chartdata"_$$$groupNum

		if (seriesNumber'=2) {
			Set init=1
			Set incr=1
			Set term=$l(..dataFields,",")
		} else {
			Set init=$l(..dataFields,",")
			Set incr=-1
			Set term=1
		}
		For i=init:incr:term {
			Set data=$p(..dataFields,",",i)
			Set data=$zstrip(data,"<>W")
			If $e(data)="!" {
				// XPath expression
				Set data = $e(data,2,$l(data))
			} Else {
				// literal
				Set data = "'"_data_"'"
			}
			Do delay.WriteLine("      <xsl:call-template name='"_datatemplatename_"'>")
			Do delay.WriteLine("        <xsl:with-param name='adj' select='$adj'/>")
			Do delay.WriteLine("        <xsl:with-param name='item' select='"_i_"' />")
			Do delay.WriteLine("        <xsl:with-param name='data' select='"_data_"' />")
			Do ..writeWithParams(.delay)
			If '..chartPivot {
				Do delay.WriteLine("        <xsl:with-param name='dx' select='$dx'/>")
			} Else {
				Do delay.WriteLine("        <xsl:with-param name='dy' select='$dy'/>")
			}
			
			Do delay.WriteLine("      </xsl:call-template>")
			
		}


	} Else {
		Set datatemplatename=..dataGroup
		Set mode="chartdata"_$$$groupNum
		
		// dataGroup only supports one dataField
		Set data1 = $p(..dataFields,",")
		// strip expected "!"
		Set data1 = $zstrip(data1,"<>W")
		Set data = $e(data1,2,$l(data1))
		Do delay.WriteLine("    <xsl:apply-templates select='"_..qualify(datatemplatename)_"' mode='"_mode_"' >")
			Do delay.WriteLine("        <xsl:with-param name='adj' select='$adj'/>")
			If '..chartPivot {
				Do delay.WriteLine("        <xsl:with-param name='dx' select='$dx'/>")
			} Else {
				Do delay.WriteLine("        <xsl:with-param name='dy' select='$dy'/>")
			}
			Do ..writeWithParams(.delay)
		Do delay.WriteLine("    </xsl:apply-templates>")
	}
	
	
	if (seriesNumber=1) {
		Do delay.WriteLine("      </xsl:attribute>")
		Do delay.WriteLine("    </"_..SvgPrefix()_"polyline>")
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
}

Method renderMarkers(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream)
{
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
		Do delay.WriteLine("  <xsl:param name='series' select='1'/>")
	} Else {
		Do delay.WriteLine("  <xsl:variable name='series' select='position()' />")
	}

	// make sure we have data
	Do delay.WriteLine("  <xsl:if test='($"_$$$seriessize_" &gt; 0) and ($"_$$$seriescount_" &gt; 0)'>")
	
	// set up variables
	Set mode1 = "legend"_$$$groupNum	
	If '..chartPivot {
		Do delay.WriteLine("    <xsl:variable name='dx'>")
		Do delay.WriteLine("      <xsl:choose><xsl:when test='$"_$$$seriessize_" = 1'>")
		Do delay.WriteLine("        <xsl:value-of select='$plotWidth"_mode1_"' />")
		Do delay.WriteLine("      </xsl:when><xsl:otherwise>")
		Do delay.WriteLine("         <xsl:value-of select='$plotWidth"_mode1_" div ($"_$$$seriessize_" - 1)' />")
		Do delay.WriteLine("      </xsl:otherwise></xsl:choose>")
		Do delay.WriteLine("    </xsl:variable>")
		Do delay.WriteLine("    <xsl:variable name='adj' select='$dx' />")
		Do delay.WriteLine("    <xsl:variable name='base' select='$"_$$$yBase_"' />")
	} Else {
		Do delay.WriteLine("    <xsl:variable name='dy'>")
		Do delay.WriteLine("      <xsl:choose><xsl:when test='$"_$$$seriessize_" = 1'>")
		Do delay.WriteLine("        <xsl:value-of select='"_..plot.plotHeight_"' />")
		Do delay.WriteLine("      </xsl:when><xsl:otherwise>")
		Do delay.WriteLine("         <xsl:value-of select='"_..plot.plotHeight_" div ($"_$$$seriessize_" - 1)' />")
		Do delay.WriteLine("      </xsl:otherwise></xsl:choose>")
		Do delay.WriteLine("    </xsl:variable>")
		Do delay.WriteLine("    <xsl:variable name='adj' select='$dy' />")
		Do delay.WriteLine("    <xsl:variable name='base' select='$"_$$$xBase_"' />")
	}
#if 0 // comments for debugging	
	Do delay.WriteLine(" <xsl:comment>$"_$$$seriessize_"=<xsl:value-of select='$"_$$$seriessize_"'/></xsl:comment>")
	Do delay.WriteLine(" <xsl:comment>$plotWidth"_mode1_"=<xsl:value-of select='$plotWidth"_mode1_"'/></xsl:comment>")
	if '..chartPivot {
		Do delay.WriteLine(" <xsl:comment>dx=<xsl:value-of select='$dx'/></xsl:comment>")
	} else {
		Do delay.WriteLine(" <xsl:comment>dy=<xsl:value-of select='$dy'/></xsl:comment>")
	}
	Do delay.WriteLine(" <xsl:comment>adj=<xsl:value-of select='$adj'/></xsl:comment>")
#endif	
	If ..dataGroup="" {
		Set datatemplatename="markerdata"_$$$groupNum
		
		For i=1:1:$l(..dataFields,",") {
			Set data=$p(..dataFields,",",i)
			Set data=$zstrip(data,"<>W")
			If $e(data)="!" {
				// XPath expression
				Set data = $e(data,2,$l(data))
			} Else {
				// literal
				Set data = "'"_data_"'"
			}
			Do delay.WriteLine("      <xsl:call-template name='"_datatemplatename_"'>")
			Do delay.WriteLine("        <xsl:with-param name='adj' select='$adj'/>")
			Do delay.WriteLine("        <xsl:with-param name='item' select='"_i_"' />")
			Do delay.WriteLine("        <xsl:with-param name='data' select='"_data_"' />")
			Do delay.WriteLine("        <xsl:with-param name='series' select='$series'/>")
			Do ..writeWithParams(.delay)
			If '..chartPivot {
				Do delay.WriteLine("        <xsl:with-param name='dx' select='$dx'/>")
			} Else {
				Do delay.WriteLine("        <xsl:with-param name='dy' select='$dy'/>")
			}
			
			Do delay.WriteLine("      </xsl:call-template>")
		}
	} Else {
		Set datatemplatename=..dataGroup
		Set mode="markerdata"_$$$groupNum
		
		// dataGroup only supports one dataField
		Set data1 = $p(..dataFields,",")
		// strip expected "!"
		Set data1=$zstrip(data1,"<>W")
		Set data = $e(data1,2,$l(data1))
		Do delay.WriteLine("    <xsl:apply-templates select='"_..qualify(datatemplatename)_"' mode='"_mode_"' >")
			Do delay.WriteLine("        <xsl:with-param name='adj' select='$adj'/>")
			If '..chartPivot {
				Do delay.WriteLine("        <xsl:with-param name='dx' select='$dx'/>")
			} Else {
				Do delay.WriteLine("        <xsl:with-param name='dy' select='$dy'/>")
			}
			Do ..writeWithParams(.delay)
			Do delay.WriteLine("        <xsl:with-param name='series' select='$series'/>")
		Do delay.WriteLine("    </xsl:apply-templates>")
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
	If ..dataGroup="" {
		Do delay.WriteLine("<xsl:template name='"_datatemplatename_"'>")
		Do delay.WriteLine("  <xsl:param name='item' select='1'/>")
	} Else {
		Do delay.WriteLine("<xsl:template match='"_..qualify(datatemplatename)_"' mode='"_mode_"' >")
	}
	Do ..writeLoadParams(.delay)
	Do delay.WriteLine("  <xsl:param name='data'/>")
	Do delay.WriteLine("  <xsl:param name='adj'/>")
	If '..chartPivot {
		Do delay.WriteLine("  <xsl:param name='dx'/>")
	} Else {
		Do delay.WriteLine("  <xsl:param name='dy'/>")
	}
	Do delay.WriteLine("  <xsl:param name='series'/>")
	If ..dataGroup'="" {
		Do delay.WriteLine("  <xsl:variable name='item' select='position()' />")
		Do delay.WriteLine("  <xsl:variable name='raw'>")
		Do delay.WriteLine("  <xsl:choose>")
		Do delay.WriteLine("    <xsl:when test='not("_data_")'>0</xsl:when>")
		Do delay.WriteLine("    <xsl:otherwise>")
		Do delay.WriteLine("      <xsl:value-of select='number("_data_")'/>")
		Do delay.WriteLine("     </xsl:otherwise>")
		Do delay.WriteLine("  </xsl:choose>")
		Do delay.WriteLine("  </xsl:variable>")

	} Else {
		Do delay.WriteLine("  <xsl:variable name='raw'>")
		Do delay.WriteLine("  <xsl:choose>")
		Do delay.WriteLine("    <xsl:when test='not($data)'>0</xsl:when>")
		Do delay.WriteLine("    <xsl:otherwise>")
		Do delay.WriteLine("      <xsl:value-of select='number($data)'/>")
		Do delay.WriteLine("     </xsl:otherwise>")
		Do delay.WriteLine("  </xsl:choose>")
		Do delay.WriteLine("  </xsl:variable>")

	}
	
	// For stacked chart, treat negative values as 0
	If ..chartStacked {
		#; should also increase val by summing and adjust base here...
		Do delay.WriteLine("<xsl:variable name='val'>")
		Do delay.WriteLine("  <xsl:choose><xsl:when test='$raw &lt; 0'>")
		Do delay.WriteLine("    0")
		Do delay.WriteLine("  </xsl:when><xsl:otherwise>")
		Do delay.WriteLine("    <xsl:value-of select='$raw' />")
		Do delay.WriteLine("  </xsl:otherwise></xsl:choose>")
		Do delay.WriteLine("</xsl:variable>")
	} Else {
		Do delay.WriteLine("<xsl:variable name='val' select='$raw' />")
	}
	
	If '..chartPivot {
		Do delay.WriteLine("<xsl:variable name='x' select='$item * $dx' />")
		Do delay.WriteLine("<xsl:variable name='y'>")
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
		Do delay.WriteLine("<xsl:with-param name='x' select='$x - $adj' />")
		Do delay.WriteLine("<xsl:with-param name='y' select='$y' />")
		Do delay.WriteLine("<xsl:with-param name='shape'>")
		Do delay.WriteLine("<xsl:call-template name='zenReportGetSeriesMarker"_$$$groupNum_"'>")
		Do delay.WriteLine("<xsl:with-param name='series' select='$series'/>")
		Do delay.WriteLine("</xsl:call-template>")
		Do delay.WriteLine("  </xsl:with-param>")
		Do delay.WriteLine("<xsl:with-param name='color'>")
		Do delay.WriteLine("<xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
		Do delay.WriteLine("<xsl:with-param name='series' select='$series'/>")
		Do delay.WriteLine("</xsl:call-template>")
		Do delay.WriteLine("  </xsl:with-param>")

		Do delay.WriteLine("</xsl:call-template>")

	} Else {
		// pivotted
		Do delay.WriteLine("<xsl:variable name='y' select='$item * $dy' />")
		Do delay.WriteLine("<xsl:variable name='x'>")
		Do delay.WriteLine("  <xsl:choose><xsl:when test='$"_$$$xRange_" = 0'>")
		Do delay.WriteLine("    <xsl:value-of select='0' />")
		Do delay.WriteLine("  </xsl:when><xsl:otherwise>")
		Do delay.WriteLine("    <xsl:variable name='pct' select='($val - $"_$$$xMin_") div $"_$$$xRange_"' />")
		Do delay.WriteLine("    <xsl:value-of select='($pct * $plotWidth"_mode1_")' />")
		Do delay.WriteLine("  </xsl:otherwise></xsl:choose>")
		Do delay.WriteLine("</xsl:variable>")
		#;Do delay.WriteLine("<xsl:value-of select='concat($x,"" "",($y - $adj),"" "")'/>")
		; call draw marker here
		Do delay.WriteLine("<xsl:call-template name='zenReportDrawMarker"_$$$groupNum_"'>")
		Do delay.WriteLine("<xsl:with-param name='x' select='$x' />")
		Do delay.WriteLine("<xsl:with-param name='y' select='$y - $adj' />")
		Do delay.WriteLine("<xsl:with-param name='shape'>")
		Do delay.WriteLine("<xsl:call-template name='zenReportGetSeriesMarker"_$$$groupNum_"'>")
		Do delay.WriteLine("<xsl:with-param name='series' select='$series'/>")
		Do delay.WriteLine("</xsl:call-template>")
		Do delay.WriteLine("  </xsl:with-param>")
		Do delay.WriteLine("<xsl:with-param name='color'>")
		Do delay.WriteLine("<xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
		Do delay.WriteLine("<xsl:with-param name='series' select='$series'/>")
		Do delay.WriteLine("</xsl:call-template>")
		Do delay.WriteLine("  </xsl:with-param>")


		Do delay.WriteLine("</xsl:call-template>")
	}
	

	Do delay.Write("</xsl:template>")
		
	Quit $$$OK
}

/// Return the type of x axis (category or value) used by
/// this chart.
Method getXAxisType() As %String
{
	Quit $s(..chartPivot:"value", 1:"category")
}

/// Return the type of y axis (category or value) used by
/// this chart.
Method getYAxisType() As %String
{
	Quit $s(..chartPivot:"category", 1:"value")
}

}
