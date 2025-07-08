/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Renders a bar chart.<br>
/// Note: the <property>plotToEdge</property> is always
/// treated as false for bar charts.
Class %ZEN.Report.Display.Chart.barChart Extends chart [ Deprecated, System = 4 ]
{

/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 0;

/// If true, this is a <i>stacked</i> bar chart. That is,
/// data series are plotted on top of one another.<br>
/// If false, then data series are plotted side-by-side.<br>
/// Note that negative values are ignored in stacked charts.<br>
/// <span style='font-weight:bold'>NOT CURRENTLY IMPLEMENTED</span>
Property chartStacked As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, pivot this chart: display categories vertically
/// and values horizontally.
Property chartPivot As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Draw data series for this chart.
Method renderSeries(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	s tSC=$$$OK
	if ..seriesGroup'="" {
		s tSC=..renderSeriesGroupBarChart(.context,.XSL,.delay)
	} else {
		s tSC=..renderDataGroupBarChart(.context,.XSL,.delay)
	}
	quit tSC
}

Method renderSeriesGroupBarChart(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	#; **** CHART *****
	If (..seriesGroup = "")||(..seriesCount'="") {
		Set templatename="chartseries"_$$$groupNum
		Set scount=$s(..seriesCount="":$l(..seriesNames,","),1:..seriesCount)

		For i=1:1:scount {
			Do XSL.WriteLine("<xsl:call-template name='"_templatename_"'>")
			Do ..writeWithParams(.XSL)
			Do XSL.WriteLine("  <xsl:with-param name='series' select='"_i_"' />")
			Do XSL.WriteLine("</xsl:call-template>")
		}
	} Else {
		Set templatename = ..seriesGroup
		Set mode = "chartseries"_$$$groupNum
		
		Do XSL.WriteLine("<xsl:apply-templates select='"_..qualify(templatename)_"' mode='"_mode_"'>")
		Do ..writeWithParams(.XSL)
		Do XSL.WriteLine("</xsl:apply-templates>")
	}	
	
	#; **** SERIES *****
	If (..seriesGroup="")||(..seriesCount'="") {
		Do delay.WriteLine("<xsl:template name='"_templatename_"'>")
	} Else {
		Do delay.WriteLine("<xsl:template match='"_..qualify(templatename)_"' mode='"_mode_"' >")
	}
	
	Do ..writeLoadParams(.delay)
	
	// if no seriesGroup, we can get series number from XPath position()
	If (..seriesGroup="") {
		Do delay.WriteLine("  <xsl:param name='series'/>")
	}
	elseif (..seriesGroup'="")&&(..seriesCount'="") {
		Do delay.WriteLine("  <xsl:param name='series'/>")
	} Else {
		Do delay.WriteLine("  <xsl:variable name='series' select='position()' />")
		
	}
	
	// copy globals to local variables (mostly not to have to keep reusing the macro for readability)
	Do delay.WriteLine("  <xsl:variable name='items' select='$"_$$$seriessize_"' />")
	Do delay.WriteLine("  <xsl:variable name='scount' select='$"_$$$seriescount_"' />")
	
	// make sure we have data
	Do delay.WriteLine("  <xsl:if test='($items &gt; 0) and ($scount &gt; 0)'>")
	
	// set up variables
	If '..chartPivot {
		If ..chartStacked {
			Set mode = "legend"_$$$groupNum
			Do delay.WriteLine("    <xsl:variable name='barwid' select='0.8 * $plotWidth"_mode_" div $items' />")
			Do delay.WriteLine("    <xsl:variable name='shift' select='-$barwid div 2' />")
		} Else {
			Set mode = "legend"_$$$groupNum
			Do delay.WriteLine("    <xsl:variable name='barwid' select='(0.8 div $scount) * ($plotWidth"_mode_" div $items)' />")
			Do delay.WriteLine("    <xsl:variable name='shift' select='(($series - 1) * $barwid) - ($scount *$barwid) div 2' />")
		}
		Do delay.WriteLine("    <xsl:variable name='dx' select='$plotWidth"_mode_" div $items' />")
		Do delay.WriteLine("    <xsl:variable name='adj' select='$dx div 2' />")
		//Set base = $s(..yAxis.baseValue="":..plot.plotHeight,1:..getPlotY(..yAxis.baseValue)-..plot.plotTop)
		Do delay.WriteLine("    <xsl:variable name='base' select='$"_$$$yBase_"' />")
	} Else {
		If ..chartStacked {
			Do delay.WriteLine("    <xsl:variable name='barhgt' select='0.8 * "_..plot.plotHeight_" div $items' />")
			Do delay.WriteLine("    <xsl:variable name='shift' select='-$barhgt div 2' />")
		} Else {
			Do delay.WriteLine("    <xsl:variable name='barhgt' select='(0.8 div $scount) * ("_..plot.plotHeight_" div $items)' />")
			Do delay.WriteLine("    <xsl:variable name='shift' select='(($series - 1) * $barhgt) - ($scount * $barhgt) div 2' />")
		}
		Do delay.WriteLine("    <xsl:variable name='dy' select='"_..plot.plotHeight_" div $items' />")
		Do delay.WriteLine("    <xsl:variable name='adj' select='$dy div 2' />")
		//Set base = $s(..xAxis.baseValue="":0,1:..getPlotX(..xAxis.baseValue)-..plot.plotLeft)
		Do delay.WriteLine("    <xsl:variable name='base' select='$"_$$$xBase_"' />")
	}
	
	If ..dataGroup="" {
		Set templatename="chartdata"_$$$groupNum
		
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
			Do delay.WriteLine("      <xsl:call-template name='"_templatename_"'>")
			Do ..writeWithParams(.delay)
			Do delay.WriteLine("        <xsl:with-param name='series' select='$series' />")
			Do delay.WriteLine("        <xsl:with-param name='shift' select='$shift'/>")
			Do delay.WriteLine("        <xsl:with-param name='base' select='$base'/>")
			Do delay.WriteLine("        <xsl:with-param name='adj' select='$adj'/>")
			Do delay.WriteLine("        <xsl:with-param name='item' select='"_i_"' />")
			if (..seriesGroup="") {
				Do delay.WriteLine("        <xsl:with-param name='data' select='"_data_"' />")  ;foobar
			} elseif (..seriesCount'="") {
				Do delay.WriteLine("        <xsl:with-param name='data' select='"_..seriesGroup_"[$series]/"_data_"' />")  ;foobar
			} else {
				Do delay.WriteLine("        <xsl:with-param name='data' select='"_data_"' />")  ;foobar
			}
			If '..chartPivot {
				Do delay.WriteLine("        <xsl:with-param name='dx' select='$dx'/>")
				Do delay.WriteLine("        <xsl:with-param name='barwid' select='$barwid'/>")
			} Else {
				Do delay.WriteLine("        <xsl:with-param name='dy' select='$dy'/>")
				Do delay.WriteLine("        <xsl:with-param name='barhgt' select='$barhgt'/>")
			}
			Do delay.WriteLine("      </xsl:call-template>")
		}
	} Else {
		Set templatename=..dataGroup
		Set mode="chartdata"_$$$groupNum
		
		// dataGroup only supports one dataField
		Set data1 = $p(..dataFields,",")
		// strip expected "!"
		Set data1=$zstrip(data1,"<>W")
		Set data = $e(data1,2,$l(data1))
		Do delay.WriteLine("    <xsl:apply-templates select='"_..qualify(templatename)_"' mode='"_mode_"' >")
		Do ..writeWithParams(.delay)
		Do delay.WriteLine("        <xsl:with-param name='series' select='$series' />")
		Do delay.WriteLine("        <xsl:with-param name='shift' select='$shift'/>")
		Do delay.WriteLine("        <xsl:with-param name='base' select='$base'/>")
		Do delay.WriteLine("        <xsl:with-param name='adj' select='$adj'/>")
		If '..chartPivot {
			Do delay.WriteLine("        <xsl:with-param name='dx' select='$dx'/>")
			Do delay.WriteLine("        <xsl:with-param name='barwid' select='$barwid'/>")
		} Else {
			Do delay.WriteLine("        <xsl:with-param name='dy' select='$dy'/>")
			Do delay.WriteLine("        <xsl:with-param name='barhgt' select='$barhgt'/>")
		}
		Do delay.WriteLine("    </xsl:apply-templates>")
	}
	Do delay.WriteLine("  </xsl:if>")
	Do delay.WriteLine("</xsl:template>")
			
	#; **** ITEMS *****
	
	// Open template and load in params
	If ..dataGroup="" {
		Do delay.WriteLine("<xsl:template name='"_templatename_"'>")
		Do delay.WriteLine("  <xsl:param name='item'/>")
	} Else {
		Do delay.WriteLine("<xsl:template match='"_..qualify(templatename)_"' mode='"_mode_"' >")
		
	}
	Do ..writeLoadParams(.delay)
	Do delay.WriteLine("  <xsl:param name='series'/>")
	Do delay.WriteLine("  <xsl:param name='data'/>")
	Do delay.WriteLine("  <xsl:param name='base'/>")
	Do delay.WriteLine("  <xsl:param name='shift'/>")
	Do delay.WriteLine("  <xsl:param name='adj'/>")
	If '..chartPivot {
		Do delay.WriteLine("  <xsl:param name='dx'/>")
		Do delay.WriteLine("  <xsl:param name='barwid'/>")
	} Else {
		Do delay.WriteLine("  <xsl:param name='dy'/>")
		Do delay.WriteLine("  <xsl:param name='barhgt'/>")
	}
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
		s attribs=""
		s sep=""
		s key="" for  s key=$o(context("SVGATTRS","chart-seriesBar",key)) q:key=""  d
		. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-seriesBar",key)_"'"
		. s sep=" "
		Do delay.WriteLine("<"_..SvgPrefix()_"rect class='chart-seriesBar'"_attribs_">")
		Do delay.WriteLine("<xsl:variable name='x' select='$item * $dx' />")
		/*If ..yAxis.range = 0 {
			Do delay.WriteLine("<xsl:variable name='y' select='"_..plot.plotBottom_"' />")
		} Else {
			Do delay.WriteLine("<xsl:variable name='pct' select='($val - $"_$$$yMin_") div $"_$$$yRange_"' />")
			Do delay.WriteLine("<xsl:variable name='y' select='"_..plot.plotBottom_" - ($pct * "_..plot.plotHeight_")' />")
		}*/
		Do delay.WriteLine("<xsl:variable name='y'>")
		Do delay.WriteLine("  <xsl:variable name='yraw'>")
		Do delay.WriteLine("    <xsl:call-template name='zenReportGetPlotY"_$$$groupNum_"'>")
		Do ..writeWithParamsNoBase(.delay)
		Do delay.WriteLine("      <xsl:with-param name='val' select='$val'/>")
		Do delay.WriteLine("    </xsl:call-template>")
		Do delay.WriteLine("  </xsl:variable>")
		Do delay.WriteLine("  <xsl:value-of select='$yraw - "_..plot.plotTop_"' />")
		Do delay.WriteLine("</xsl:variable>")
		Do delay.WriteLine("<xsl:variable name='top'>")
		Do delay.WriteLine("  <xsl:choose><xsl:when test='$y &lt;= $base' >")
		Do delay.WriteLine("    <xsl:value-of select='$y' />")
		Do delay.WriteLine("  </xsl:when><xsl:otherwise>")
		Do delay.WriteLine("    <xsl:value-of select='$base' />")
		Do delay.WriteLine("  </xsl:otherwise></xsl:choose></xsl:variable>")
		
		Do delay.WriteLine("<xsl:variable name='hgt'>")
		Do delay.WriteLine("  <xsl:choose><xsl:when test='$y &lt;= $base' >")
		Do delay.WriteLine("    <xsl:value-of select='$base - $y' />")
		Do delay.WriteLine("  </xsl:when><xsl:otherwise>")
		Do delay.WriteLine("    <xsl:value-of select='$y - $base' />")
		Do delay.WriteLine("  </xsl:otherwise></xsl:choose></xsl:variable>")
		
		Do delay.WriteLine("<xsl:attribute name='x'><xsl:value-of select='$x - $adj + $shift' /></xsl:attribute>")
		Do delay.WriteLine("<xsl:attribute name='y'><xsl:value-of select='$top' /></xsl:attribute>")
		Do delay.WriteLine("<xsl:attribute name='width'><xsl:value-of select='$barwid' /></xsl:attribute>")
		Do delay.WriteLine("<xsl:attribute name='height'><xsl:value-of select='$hgt' /></xsl:attribute>")
		if ..plotStyle'="" Do delay.WriteLine("<xsl:attribute name='style'>"_..plotStyle_"</xsl:attribute>")
		Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.delay,..plotStyle)
		
		Do delay.WriteLine("<xsl:attribute name='fill'>")
		Do delay.WriteLine("  <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
		Do delay.WriteLine("    <xsl:with-param name='series' select='$series'/>")
		Do delay.WriteLine("  </xsl:call-template>")
		Do delay.WriteLine("</xsl:attribute>")
		Do delay.WriteLine("</"_..SvgPrefix()_"rect>")

	} Else {
		// pivotted
		s attribs=""
		s sep=""
		s key="" for  s key=$o(context("SVGATTRS","chart-seriesBar",key)) q:key=""  d
		. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-seriesBar",key)_"'"
		. s sep=" "
		Do delay.WriteLine("<"_..SvgPrefix()_"rect class='chart-seriesBar'"_attribs_">")
		Do delay.WriteLine("<xsl:variable name='y' select='$item * $dy' />")
		/*If ..xAxis.range = 0 {
			Do delay.WriteLine("<xsl:variable name='x' select='0' />")
		} Else {
			Do delay.WriteLine("<xsl:variable name='pct' select='($val - "_..xAxis.minValue_") div "_..xAxis.range_"' />")
			Do delay.WriteLine("<xsl:variable name='x' select='($pct * "_..plot.plotWidth_")' />")
		}*/
		Do delay.WriteLine("<xsl:variable name='x'>")
		Do delay.WriteLine("  <xsl:variable name='xraw'>")
		Do delay.WriteLine("    <xsl:call-template name='zenReportGetPlotX"_$$$groupNum_"'>")
		Do ..writeWithParamsNoBase(.delay)
		Do delay.WriteLine("      <xsl:with-param name='val' select='$val'/>")
		Do delay.WriteLine("    </xsl:call-template>")
		Do delay.WriteLine("  </xsl:variable>")
		Set mode = "legend"_$$$groupNum
		Do delay.WriteLine("  <xsl:value-of select='$xraw - $plotLeft"_mode_"' />")
		Do delay.WriteLine("</xsl:variable>")
		Do delay.WriteLine("<xsl:variable name='left'>")
		Do delay.WriteLine("  <xsl:choose><xsl:when test='$x &lt;= $base' >")
		Do delay.WriteLine("    <xsl:value-of select='$x' />")
		Do delay.WriteLine("  </xsl:when><xsl:otherwise>")
		Do delay.WriteLine("    <xsl:value-of select='$base' />")
		Do delay.WriteLine("  </xsl:otherwise></xsl:choose></xsl:variable>")
		
		Do delay.WriteLine("<xsl:variable name='wid'>")
		Do delay.WriteLine("  <xsl:choose><xsl:when test='$x &lt;= $base' >")
		Do delay.WriteLine("    <xsl:value-of select='$base - $x' />")
		Do delay.WriteLine("  </xsl:when><xsl:otherwise>")
		Do delay.WriteLine("    <xsl:value-of select='$x - $base' />")
		Do delay.WriteLine("  </xsl:otherwise></xsl:choose></xsl:variable>")
		
		Do delay.WriteLine("<xsl:attribute name='x'><xsl:value-of select='$left' /></xsl:attribute>")
		Do delay.WriteLine("<xsl:attribute name='y'><xsl:value-of select='$y - $adj + $shift' /></xsl:attribute>")
		Do delay.WriteLine("<xsl:attribute name='width'><xsl:value-of select='$wid' /></xsl:attribute>")
		Do delay.WriteLine("<xsl:attribute name='height'><xsl:value-of select='$barhgt' /></xsl:attribute>")
		if ..plotStyle'="" Do delay.WriteLine("<xsl:attribute name='style'>"_..plotStyle_"</xsl:attribute>")
		Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.delay,..plotStyle)
		Do delay.WriteLine("<xsl:attribute name='debug'><xsl:value-of select='$data' /></xsl:attribute>")
		Do delay.WriteLine("<xsl:attribute name='fill'>")
		Do delay.WriteLine("  <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
		Do delay.WriteLine("    <xsl:with-param name='series' select='$series'/>")
		Do delay.WriteLine("  </xsl:call-template>")
		Do delay.WriteLine("</xsl:attribute>")
		Do delay.WriteLine("</"_..SvgPrefix()_"rect>")
	}
	
	Do delay.Write("</xsl:template>")
		
	Quit $$$OK
}

Method renderDataGroupBarChart(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	#; **** CHART *****
	
	Set scount=$s(..seriesCount="":$s(..seriesNames="":$l(..dataFields,","),1:$l(..seriesNames,",")),1:..seriesCount)

	For j=1:1:scount {
		Set templatename="chartseries"_$$$groupNum
		Do XSL.WriteLine("<xsl:call-template name='"_templatename_"_"_j_"'>")
		Do ..writeWithParams(.XSL)
		Do XSL.WriteLine("  <xsl:with-param name='series' select='"_j_"' />")
		Do XSL.WriteLine("</xsl:call-template>")
	
		Do delay.WriteLine("<xsl:template name='"_templatename_"_"_j_"'>")
	
		Do ..writeLoadParams(.delay)
	
		// if no seriesGroup, we can get series number from XPath position()
		Do delay.WriteLine("  <xsl:param name='series'/>")
	
		// copy globals to local variables (mostly not to have to keep reusing the macro for readability)
		Do delay.WriteLine("  <xsl:variable name='items' select='$"_$$$seriessize_"' />")
		Do delay.WriteLine("  <xsl:variable name='scount' select='$"_$$$seriescount_"' />")
	
		// make sure we have data
		Do delay.WriteLine("  <xsl:if test='($items &gt; 0) and ($scount &gt; 0)'>")
	
		// set up variables
		If '..chartPivot {
			If ..chartStacked {
				Set mode = "legend"_$$$groupNum
				Do delay.WriteLine("    <xsl:variable name='barwid' select='0.8 * $plotWidth"_mode_" div $items' />")
				Do delay.WriteLine("    <xsl:variable name='shift' select='-$barwid div 2' />")
			} Else {
				Set mode = "legend"_$$$groupNum
				Do delay.WriteLine("    <xsl:variable name='barwid' select='(0.8 div $scount) * ($plotWidth"_mode_" div $items)' />")
				Do delay.WriteLine("    <xsl:variable name='shift' select='(($series - 1) * $barwid) - ($scount *$barwid) div 2' />")
			}
			Do delay.WriteLine("    <xsl:variable name='dx' select='$plotWidth"_mode_" div $items' />")
			Do delay.WriteLine("    <xsl:variable name='adj' select='$dx div 2' />")
			//Set base = $s(..yAxis.baseValue="":..plot.plotHeight,1:..getPlotY(..yAxis.baseValue)-..plot.plotTop)
			Do delay.WriteLine("    <xsl:variable name='base' select='$"_$$$yBase_"' />")
		} Else {
			If ..chartStacked {
				Do delay.WriteLine("    <xsl:variable name='barhgt' select='0.8 * "_..plot.plotHeight_" div $items' />")
				Do delay.WriteLine("    <xsl:variable name='shift' select='-$barhgt div 2' />")
			} Else {
				Do delay.WriteLine("    <xsl:variable name='barhgt' select='(0.8 div $scount) * ("_..plot.plotHeight_" div $items)' />")
				Do delay.WriteLine("    <xsl:variable name='shift' select='(($series - 1) * $barhgt) - ($scount * $barhgt) div 2' />")
			}
			Do delay.WriteLine("    <xsl:variable name='dy' select='"_..plot.plotHeight_" div $items' />")
			Do delay.WriteLine("    <xsl:variable name='adj' select='$dy div 2' />")
			//Set base = $s(..xAxis.baseValue="":0,1:..getPlotX(..xAxis.baseValue)-..plot.plotLeft)
			Do delay.WriteLine("    <xsl:variable name='base' select='$"_$$$xBase_"' />")
		}
	

		Set templatename=..dataGroup
		Set mode="chartdata"_$$$groupNum_"_"_j
	
		Set data1 = $p(..dataFields,",",j)
		Set data1=$zstrip(data1,"<>W")
		// strip expected "!"
		Set data = $e(data1,2,$l(data1))
		Do delay.WriteLine("    <xsl:apply-templates select='"_..qualify(templatename)_"' mode='"_mode_"' >")
		Do ..writeWithParams(.delay)
		Do delay.WriteLine("        <xsl:with-param name='series' select='$series' />")
		Do delay.WriteLine("        <xsl:with-param name='shift' select='$shift'/>")
		Do delay.WriteLine("        <xsl:with-param name='base' select='$base'/>")
		Do delay.WriteLine("        <xsl:with-param name='adj' select='$adj'/>")
		If '..chartPivot {
			Do delay.WriteLine("        <xsl:with-param name='dx' select='$dx'/>")
			Do delay.WriteLine("        <xsl:with-param name='barwid' select='$barwid'/>")
		} Else {
			Do delay.WriteLine("        <xsl:with-param name='dy' select='$dy'/>")
			Do delay.WriteLine("        <xsl:with-param name='barhgt' select='$barhgt'/>")
		}
		Do delay.WriteLine("    </xsl:apply-templates>")

		Do delay.WriteLine("  </xsl:if>")
		Do delay.WriteLine("</xsl:template>")
			
		#; **** ITEMS *****
	
		Do delay.WriteLine("<xsl:template match='"_..qualify(templatename)_"' mode='"_mode_"' >")
		
		Do ..writeLoadParams(.delay)
		Do delay.WriteLine("  <xsl:param name='series'/>")
		Do delay.WriteLine("  <xsl:param name='data'/>")
		Do delay.WriteLine("  <xsl:param name='base'/>")
		Do delay.WriteLine("  <xsl:param name='shift'/>")
		Do delay.WriteLine("  <xsl:param name='adj'/>")
		If '..chartPivot {
			Do delay.WriteLine("  <xsl:param name='dx'/>")
			Do delay.WriteLine("  <xsl:param name='barwid'/>")
		} Else {
			Do delay.WriteLine("  <xsl:param name='dy'/>")
			Do delay.WriteLine("  <xsl:param name='barhgt'/>")
		}
		Do delay.WriteLine("  <xsl:variable name='item' select='position()' />")
		Do delay.WriteLine("  <xsl:variable name='raw'>")
		Do delay.WriteLine("  <xsl:choose>")
		Do delay.WriteLine("    <xsl:when test='not("_data_")'>0</xsl:when>")
		Do delay.WriteLine("    <xsl:otherwise>")
		Do delay.WriteLine("      <xsl:value-of select='number("_data_")'/>")
		Do delay.WriteLine("     </xsl:otherwise>")
		Do delay.WriteLine("  </xsl:choose>")
		Do delay.WriteLine("  </xsl:variable>")
	
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
			s attribs=""
			s sep=""
			s key="" for  s key=$o(context("SVGATTRS","chart-seriesBar",key)) q:key=""  d
			. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-seriesBar",key)_"'"
			. s sep=" "
			Do delay.WriteLine("<"_..SvgPrefix()_"rect class='chart-seriesBar'"_attribs_">")
			Do delay.WriteLine("<xsl:variable name='x' select='$item * $dx' />")
			/*If ..yAxis.range = 0 {
				Do delay.WriteLine("<xsl:variable name='y' select='"_..plot.plotBottom_"' />")
			} Else {
				Do delay.WriteLine("<xsl:variable name='pct' select='($val - $"_$$$yMin_") div $"_$$$yRange_"' />")
				Do delay.WriteLine("<xsl:variable name='y' select='"_..plot.plotBottom_" - ($pct * "_..plot.plotHeight_")' />")
			}*/
			Do delay.WriteLine("<xsl:variable name='y'>")
			Do delay.WriteLine("  <xsl:variable name='yraw'>")
			Do delay.WriteLine("    <xsl:call-template name='zenReportGetPlotY"_$$$groupNum_"'>")
			Do ..writeWithParamsNoBase(.delay)
			Do delay.WriteLine("      <xsl:with-param name='val' select='$val'/>")
			Do delay.WriteLine("    </xsl:call-template>")
			Do delay.WriteLine("  </xsl:variable>")
			Do delay.WriteLine("  <xsl:value-of select='$yraw - "_..plot.plotTop_"' />")
			Do delay.WriteLine("</xsl:variable>")
			Do delay.WriteLine("<xsl:variable name='top'>")
			Do delay.WriteLine("  <xsl:choose><xsl:when test='$y &lt;= $base' >")
			Do delay.WriteLine("    <xsl:value-of select='$y' />")
			Do delay.WriteLine("  </xsl:when><xsl:otherwise>")
			Do delay.WriteLine("    <xsl:value-of select='$base' />")
			Do delay.WriteLine("  </xsl:otherwise></xsl:choose></xsl:variable>")
		
			Do delay.WriteLine("<xsl:variable name='hgt'>")
			Do delay.WriteLine("  <xsl:choose><xsl:when test='$y &lt;= $base' >")
			Do delay.WriteLine("    <xsl:value-of select='$base - $y' />")
			Do delay.WriteLine("  </xsl:when><xsl:otherwise>")
			Do delay.WriteLine("    <xsl:value-of select='$y - $base' />")
			Do delay.WriteLine("  </xsl:otherwise></xsl:choose></xsl:variable>")
		
			Do delay.WriteLine("<xsl:attribute name='x'><xsl:value-of select='$x - $adj + $shift' /></xsl:attribute>")
			Do delay.WriteLine("<xsl:attribute name='y'><xsl:value-of select='$top' /></xsl:attribute>")
			Do delay.WriteLine("<xsl:attribute name='width'><xsl:value-of select='$barwid' /></xsl:attribute>")
			Do delay.WriteLine("<xsl:attribute name='height'><xsl:value-of select='$hgt' /></xsl:attribute>")
			if ..plotStyle'="" Do delay.WriteLine("<xsl:attribute name='style'>"_..plotStyle_"</xsl:attribute>")
			Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.delay,..plotStyle)
		
			Do delay.WriteLine("<xsl:attribute name='fill'>")
			Do delay.WriteLine("  <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
			Do delay.WriteLine("    <xsl:with-param name='series' select='$series'/>")
			Do delay.WriteLine("  </xsl:call-template>")
			Do delay.WriteLine("</xsl:attribute>")
			Do delay.WriteLine("</"_..SvgPrefix()_"rect>")

		} Else {
			// pivotted
			s attribs=""
			s sep=""
			s key="" for  s key=$o(context("SVGATTRS","chart-seriesBar",key)) q:key=""  d
			. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-seriesBar",key)_"'"
			. s sep=" "
			Do delay.WriteLine("<"_..SvgPrefix()_"rect class='chart-seriesBar'"_attribs_">")
			Do delay.WriteLine("<xsl:variable name='y' select='$item * $dy' />")
			/*If ..xAxis.range = 0 {
				Do delay.WriteLine("<xsl:variable name='x' select='0' />")
			} Else {
				Do delay.WriteLine("<xsl:variable name='pct' select='($val - "_..xAxis.minValue_") div "_..xAxis.range_"' />")
				Do delay.WriteLine("<xsl:variable name='x' select='($pct * "_..plot.plotWidth_")' />")
			}*/
			Do delay.WriteLine("<xsl:variable name='x'>")
			Do delay.WriteLine("  <xsl:variable name='xraw'>")
			Do delay.WriteLine("    <xsl:call-template name='zenReportGetPlotX"_$$$groupNum_"'>")
			Do ..writeWithParamsNoBase(.delay)
			Do delay.WriteLine("      <xsl:with-param name='val' select='$val'/>")
			Do delay.WriteLine("    </xsl:call-template>")
			Do delay.WriteLine("  </xsl:variable>")
			Set mode = "legend"_$$$groupNum
			Do delay.WriteLine("  <xsl:value-of select='$xraw - $plotLeft"_mode_"' />")
			Do delay.WriteLine("</xsl:variable>")
			Do delay.WriteLine("<xsl:variable name='left'>")
			Do delay.WriteLine("  <xsl:choose><xsl:when test='$x &lt;= $base' >")
			Do delay.WriteLine("    <xsl:value-of select='$x' />")
			Do delay.WriteLine("  </xsl:when><xsl:otherwise>")
			Do delay.WriteLine("    <xsl:value-of select='$base' />")
			Do delay.WriteLine("  </xsl:otherwise></xsl:choose></xsl:variable>")
		
			Do delay.WriteLine("<xsl:variable name='wid'>")
			Do delay.WriteLine("  <xsl:choose><xsl:when test='$x &lt;= $base' >")
			Do delay.WriteLine("    <xsl:value-of select='$base - $x' />")
			Do delay.WriteLine("  </xsl:when><xsl:otherwise>")
			Do delay.WriteLine("    <xsl:value-of select='$x - $base' />")
			Do delay.WriteLine("  </xsl:otherwise></xsl:choose></xsl:variable>")
		
			Do delay.WriteLine("<xsl:attribute name='x'><xsl:value-of select='$left' /></xsl:attribute>")
			Do delay.WriteLine("<xsl:attribute name='y'><xsl:value-of select='$y - $adj + $shift' /></xsl:attribute>")
			Do delay.WriteLine("<xsl:attribute name='width'><xsl:value-of select='$wid' /></xsl:attribute>")
			Do delay.WriteLine("<xsl:attribute name='height'><xsl:value-of select='$barhgt' /></xsl:attribute>")
			if ..plotStyle'="" Do delay.WriteLine("<xsl:attribute name='style'>"_..plotStyle_"</xsl:attribute>")
			Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.delay,..plotStyle)
			Do delay.WriteLine("<xsl:attribute name='debug'><xsl:value-of select='$data' /></xsl:attribute>")
			Do delay.WriteLine("<xsl:attribute name='fill'>")
			Do delay.WriteLine("  <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
			Do delay.WriteLine("    <xsl:with-param name='series' select='$series'/>")
			Do delay.WriteLine("  </xsl:call-template>")
			Do delay.WriteLine("</xsl:attribute>")
			Do delay.WriteLine("</"_..SvgPrefix()_"rect>")
		}
	
		Do delay.Write("</xsl:template>")
	}		
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
