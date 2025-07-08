/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Renders a line chart.
Class %ZEN.Report.Display.Chart.lineChart Extends chart [ Deprecated, System = 4 ]
{

/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 1;

/// Specifies whether the area under the line is filled (as
/// in an area chart) or not filled (as in a line chart).
Property chartFilled As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, this is a <i>stacked</i> line chart. That is,
/// data series are plotted above one another.<br>
/// Note that negative values are ignored in stacked charts.
Property chartStacked As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, pivot this chart: display categories vertically
/// and values horizontally.
Property chartPivot As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Method renderSeries(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
	if ..dataGroup="" {
		quit ..renderSeriesLine(.context,.XSL,.delay,..dataFields,1)
	} else {
		for i=1:1:$L(..dataFields,",") {
			Set tDataFields=$P(..dataFields,",",i)
			Set tSC=..renderSeriesLine(.context,.XSL,.delay,tDataFields,i)
			if $$$ISERR(tSC) quit 
		}
		if $$$ISERR(tSC) quit tSC
	}
	quit $$$OK
}

Method renderSeriesLine(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, pDataFields As %String, i As %Integer) As %Status
{
	If ..seriesGroup = "" {
		Set seriestemplatename="chartseries"_$$$groupNum_i
		Do XSL.WriteLine("<xsl:call-template name='"_seriestemplatename_"'>")
		Do ..writeWithParams(.XSL)
		Do XSL.WriteLine("</xsl:call-template>")
	} Else {
		Set seriestemplatename = ..seriesGroup
		Set mode = "chartseries"_$$$groupNum

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
		Do delay.WriteLine("  <xsl:param name='series' select='"_i_"'/>")
	} Else {
		Do delay.WriteLine("  <xsl:variable name='series' select='position()' />")
	}

	// make sure we have data
	Do delay.WriteLine("  <xsl:if test='($"_$$$seriessize_" &gt; 0) and ($"_$$$seriescount_" &gt; 0)'>")
	if 1 {; ..dataGroup="" {
		Do delay.WriteLine("  <xsl:if test='$series &lt;= $"_$$$seriescount_"'>")
	}
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

	// set up series data line
	if '..chartFilled Do delay.WriteLine("    <"_..SvgPrefix()_"polyline class='chart-seriesLine'>")
	if ..chartFilled Do delay.WriteLine("    <"_..SvgPrefix()_"polygon class='chart-seriesLine'>")
	s key="" for  s key=$o(context("SVGATTRS","chart-seriesLine",key)) q:key=""  d
	. Do delay.WriteLine("  <xsl:attribute name='"_key_"'>"_context("SVGATTRS","chart-seriesLine",key)_"</xsl:attribute>")
	Do delay.WriteLine("      <xsl:attribute name='style'>"_..plotStyle_"</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.delay,..plotStyle)
	if '..chartFilled Do delay.WriteLine("      <xsl:attribute name='fill'>none</xsl:attribute>")
	if ..chartFilled {
		Do delay.WriteLine("      <xsl:attribute name='fill'>")
		Do delay.WriteLine("        <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
		Do delay.WriteLine("          <xsl:with-param name='series' select='$series'/>")
		Do delay.WriteLine("        </xsl:call-template>")
		Do delay.WriteLine("      </xsl:attribute>")
	}
	Do delay.WriteLine("      <xsl:attribute name='stroke'>")
	Do delay.WriteLine("        <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
	Do delay.WriteLine("          <xsl:with-param name='series' select='$series'/>")
	Do delay.WriteLine("        </xsl:call-template>")
	Do delay.WriteLine("      </xsl:attribute>")
	Do delay.WriteLine("      <xsl:attribute name='points'>")

	If ..dataGroup="" {
		Set datatemplatename="chartdata"_$$$groupNum
		if ..chartFilled {
			Set finalline = "finalline"_$$$groupNum
		}
		
		For i=1:1:$l(pDataFields,",") {
			Set data=$p(pDataFields,",",i)
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
		if ..chartFilled {
				Do delay.WriteLine("      <xsl:call-template name='"_finalline_"'>")
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
		Set mode="chartdata"_$$$groupNum_i
		if ..chartFilled {
			Set finalline = "finalline"_$$$groupNum_"_"_i
		}
		
		// dataGroup only supports one dataField
		Set data1 = $p(pDataFields,",")
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
		if ..chartFilled {
				Do delay.WriteLine("      <xsl:apply-templates select='"_..qualify(datatemplatename)_"' mode='"_finalline_"'>")
				Do delay.WriteLine("        <xsl:with-param name='adj' select='$adj'/>")
				Do delay.WriteLine("        <xsl:with-param name='item' select='"_i_"' />")
				Do delay.WriteLine("        <xsl:with-param name='data' select='"_data_"' />")
				Do ..writeWithParams(.delay)
				If '..chartPivot {
					Do delay.WriteLine("        <xsl:with-param name='dx' select='$dx'/>")
				} Else {
					Do delay.WriteLine("        <xsl:with-param name='dy' select='$dy'/>")
				}
				
				Do delay.WriteLine("      </xsl:apply-templates>")
		}

	}
	Do delay.WriteLine("      </xsl:attribute>")
	if '..chartFilled Do delay.WriteLine("    </"_..SvgPrefix()_"polyline>")
	if ..chartFilled Do delay.WriteLine("    </"_..SvgPrefix()_"polygon>")
	
	If ..seriesGroup="" {
		Do delay.WriteLine("    <xsl:if test='$series &lt; $"_$$$seriescount_"'>")
		Do delay.WriteLine("      <xsl:call-template name='"_seriestemplatename_"'>")
		Do delay.WriteLine("        <xsl:with-param name='series' select='$series + 1' />")
		Do delay.WriteLine("      </xsl:call-template>")
		Do delay.WriteLine("    </xsl:if>")
	}
	if 1 {; ..dataGroup="" {
		Do delay.WriteLine("  </xsl:if>")
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
	
	if ..chartFilled {
		// Open template and load in params
		If ..dataGroup="" {
			Do delay.WriteLine("<xsl:template name='"_finalline_"'>")
			Do delay.WriteLine("  <xsl:param name='item' select='1'/>")
		} Else {
			Do delay.WriteLine("<xsl:template match='"_..qualify(datatemplatename)_"' mode='"_finalline_"'>")
			;Do delay.WriteLine("  <xsl:param name='item' select='position()'/>")

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
			Do delay.WriteLine("  <xsl:variable name='raw'>")
			Do delay.WriteLine("  <xsl:choose>")
			Do delay.WriteLine("    <xsl:when test='not("_data_")'>0</xsl:when>")
			Do delay.WriteLine("    <xsl:otherwise>")
			Do delay.WriteLine("      <xsl:value-of select='number("_data_")'/>")
			Do delay.WriteLine("     </xsl:otherwise>")
			Do delay.WriteLine("  </xsl:choose>")
			Do delay.WriteLine("  </xsl:variable>")
			Do delay.WriteLine("  <xsl:if test='$item=last()'>")
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
			Do delay.WriteLine("    <xsl:value-of select='"_..plot.plotBottom_"' />")
			Do delay.WriteLine("</xsl:variable>")
			
			Do delay.WriteLine("<xsl:value-of select='concat(($x - $adj),"" "",$y,"" "")'/>")
	
			Do delay.WriteLine("<xsl:variable name='x1' select='$dx' />")
			Do delay.WriteLine("<xsl:variable name='y1'>")
			Do delay.WriteLine("    <xsl:value-of select='"_..plot.plotBottom_"' />")
			Do delay.WriteLine("</xsl:variable>")
			
			Do delay.WriteLine("<xsl:value-of select='concat(($x1 - $adj),"" "",$y1,"" "")'/>")
	
		} Else {
			// pivotted
			Do delay.WriteLine("<xsl:variable name='y' select='$item * $dy' />")
			Do delay.WriteLine("<xsl:variable name='x'>")
			Do delay.WriteLine("    <xsl:value-of select='0' />")
			Do delay.WriteLine("</xsl:variable>")
			Do delay.WriteLine("<xsl:value-of select='concat($x,"" "",($y - $adj),"" "")'/>")
			Do delay.WriteLine("<xsl:variable name='y1' select='1 * $dy' />")
			Do delay.WriteLine("<xsl:variable name='x1'>")
			Do delay.WriteLine("    <xsl:value-of select='0' />")
			Do delay.WriteLine("</xsl:variable>")
			Do delay.WriteLine("<xsl:value-of select='concat($x1,"" "",($y1 - $adj),"" "")'/>")

		}
		
		if ..dataGroup'="" {
			Do delay.WriteLine("  </xsl:if>")
		}
		Do delay.Write("</xsl:template>")
	}	
	
	if ..markersVisible {
		do ..renderMarkers(.context,.XSL,.delay,pDataFields,i)
	}
		
	Quit $$$OK
}

Method renderMarkers(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, pDataFields As %String, pI As %Integer)
{
	Set mode1 = "legend"_$$$groupNum	
	If ..seriesGroup = "" {
		Set seriestemplatename="chartmarkers"_$$$groupNum_pI
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
		Do delay.WriteLine("  <xsl:param name='series' select='"_pI_"'/>")
	} Else {
		Do delay.WriteLine("  <xsl:variable name='series' select='position()' />")
	}

	// make sure we have data
	Do delay.WriteLine("  <xsl:if test='($"_$$$seriessize_" &gt; 0) and ($"_$$$seriescount_" &gt; 0)'>")
	
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

	If ..dataGroup="" {
		Set datatemplatename="markerdata"_$$$groupNum
		
		For i=1:1:$l(pDataFields,",") {
			Set data=$p(pDataFields,",",i)
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
		Set mode="markerdata"_$$$groupNum_pI
		
		// dataGroup only supports one dataField
		Set data1 = $p(pDataFields,",")
		Set data1=$zstrip(data1,"<>W")
		// strip expected "!"
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
			Do delay.WriteLine("        <xsl:with-param name='item' select='"_pI_"' />")
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
		if ..dataGroup'="" {
			Do delay.WriteLine("<xsl:with-param name='series' select='$series - 1'/>")
		} else {
			Do delay.WriteLine("<xsl:with-param name='series' select='$series'/>")
		}
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
		Do delay.WriteLine("<xsl:call-template name='zenReport "_$$$groupNum_"'>")
		if ..dataGroup'="" {
			Do delay.WriteLine("<xsl:with-param name='series' select='$series - 1'/>")
		} else {
			Do delay.WriteLine("<xsl:with-param name='series' select='$series'/>")
		}
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
