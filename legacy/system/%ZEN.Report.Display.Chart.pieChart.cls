/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.Chart.pieChart Extends chart [ Deprecated, System = 4 ]
{

/// Optional: comma-delimited list of label values of each slice.
/// If left blank, the series number is used.
Property labelValues As %ZEN.Datatype.csv;

/// On slice output percentage
Property outputPercentage As %ZEN.Datatype.boolean;

/// Optional formatting string for a percentage output.<br>
/// Number formats are specified in the
/// format required for the XPath format-number function.
Property formatPercentage As %ZEN.Datatype.string;

/// Only output percentage on slice, requires outputPrecentage to be set
Property onlyPercentage As %ZEN.Datatype.boolean;

Method renderSeries(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream)
{
	Do ..renderTrigFunctions(.context,.delay)
	if ..labelsVisible Do ..renderGetLabelText(.context,.delay)
	Set mode1 = "legend"_$$$groupNum
		
	;Set gw = ..plot.plotWidth * 0.60
	;Set gh = ..plot.plotHeight * 0.75
	;Set sz = $s(gw > gh:gh/2, 1:gw/2)
	;Set cx = ..plot.plotWidth/2
	;Set cy = ..plot.plotHeight/2
	
	Do delay.WriteLine("<xsl:variable name='gw"_mode1_"' select='$plotWidth"_mode1_" * 0.60'/>")
	Do delay.WriteLine("<xsl:variable name='gh"_mode1_"' select='"_..plot.plotHeight_" * 0.75'/>")
	Do delay.WriteLine("<xsl:variable name='sz"_mode1_"'>")
	Do delay.WriteLine("<xsl:choose>")
	Do delay.WriteLine("<xsl:when test='$gw"_mode1_" > $gh"_mode1_"'>")
	Do delay.WriteLine("<xsl:value-of select='$gh"_mode1_" div 2 '/>")
	Do delay.WriteLine("</xsl:when>")
	Do delay.WriteLine("<xsl:otherwise>")
	Do delay.WriteLine("<xsl:value-of select='$gw"_mode1_" div 2 '/>")
	Do delay.WriteLine("</xsl:otherwise>")
	Do delay.WriteLine("</xsl:choose>")
	Do delay.WriteLine("</xsl:variable>")
	Do delay.WriteLine("<xsl:variable name='cx"_mode1_"' select='$plotWidth"_mode1_" div 2'/>")
	Do delay.WriteLine("<xsl:variable name='cy"_mode1_"' select='"_..plot.plotHeight_" div 2'/>")
	
	Do XSL.WriteLine("<"_..SvgPrefix()_"circle>")
	Do XSL.WriteLine("  <xsl:attribute name='cx'><xsl:value-of select='$cx"_mode1_"'/></xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='cy'><xsl:value-of select='$cy"_mode1_"'/></xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='r'><xsl:value-of select='$sz"_mode1_"'/></xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='style'>stroke:none; fill:darkblue; opacity: 1.0</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,"stroke:none; fill:darkblue; opacity: 1.0")
	Do XSL.WriteLine("</"_..SvgPrefix()_"circle>")
	
	If (..seriesGroup="")  {
		Do XSL.WriteLine("<"_..SvgPrefix()_"text fill='red' text-anchor='middle' font-size='6pt' x='"_(..plot.plotWidth/2)_"' y='"_(..plot.plotHeight/2)_"'>")
		Do XSL.WriteLine("  Pie charts must have a seriesGroup")
		Do XSL.WriteLine("</"_..SvgPrefix()_"text>")
		Quit $$$OK
	}
	if ..labelValues["!" {
		Do XSL.WriteLine("<"_..SvgPrefix()_"text fill='red' text-anchor='middle' font-size='6pt' x='"_(..plot.plotWidth/2)_"' y='"_(..plot.plotHeight/2)_"'>")
		Do XSL.WriteLine("In a pieChart, labelValues must NOT contain an xpath, an expression begginging with ""!""")
		Do XSL.WriteLine("</"_..SvgPrefix()_"text>")
		Quit $$$ERROR($$$GeneralError,"In a pieChart, labelValues must NOT contain an xpath, an expression begginging with ""!""")
	}
#if 0	
	if ..seriesNames'="",$e(..seriesNames)'="!" {
		Do XSL.WriteLine("<"_..SvgPrefix()_"text fill='red' text-anchor='middle' font-size='6pt' x='"_(..plot.plotWidth/2)_"' y='"_(..plot.plotHeight/2)_"'>")
		Do XSL.WriteLine("In a pieChart, seriesNames must contain a single xpath, an expression beginning with ""!""  Use labelValues for literals.")
		Do XSL.WriteLine("</"_..SvgPrefix()_"text>")
		Quit $$$ERROR($$$GeneralError,"In a pieChart, seriesNames must contain a single xpath, an expression beginning with ""!"". Use labelValues for literals.")
	}
	if ..seriesNames'="",$L(..seriesNames,",")'=1 {
		Do XSL.WriteLine("<"_..SvgPrefix()_"text fill='red' text-anchor='middle' font-size='6pt' x='"_(..plot.plotWidth/2)_"' y='"_(..plot.plotHeight/2)_"'>")
		Do XSL.WriteLine("In a pieChart, seriesNames must contain a single xpath, an expression beginning with ""!""")
		Do XSL.WriteLine("</"_..SvgPrefix()_"text>")
		Quit $$$ERROR($$$GeneralError,"In a pieChart, seriesNames must contain a single xpath, an expression beginning with ""!"". Use labelValues for literals.")
	}
#endif		
	
	Set totalpath=..seriesGroup_"/"
	Set:..dataGroup'="" totalpath = totalpath_..dataGroup_"/"
	
	// add first datafield, without the expected leading '!'
	Set totalpath=..qualify(totalpath_$e($p(..dataFields,","),2,*))
	
	Do XSL.WriteLine("<xsl:variable name='total1-"_$$$groupNum_"' select='sum("_totalpath_")' />")
	
	Do XSL.WriteLine("<xsl:if test='$total1-"_$$$groupNum_" &gt; 0'>")
	
	Set mode="chartslices"_$$$groupNum
	
	Do XSL.WriteLine("  <xsl:apply-templates select='"_..qualify(..seriesGroup)_"' mode='"_mode_"'>")
	Do XSL.WriteLine("    <xsl:with-param name='total' select='$total1-"_$$$groupNum_"' />")
	Do XSL.WriteLine("    <xsl:with-param name='seriescount' select='$seriescount' />")
	Do XSL.WriteLine("  </xsl:apply-templates>")
	
	Do XSL.WriteLine("</xsl:if>")
	
	#; *** SERIES ****
	
	Set datafield = $e($p(..dataFields,","),2,*)
	If ..dataGroup="" {
		Set datapath = datafield
	} Else {
		Set datapath = ..dataGroup_"/"_datafield
	}
	
	Do delay.WriteLine("<xsl:template match='"_..qualify(..seriesGroup)_"' mode='"_mode_"'>")
	Do delay.WriteLine("  <xsl:param name='total' select='1' />")
	Do delay.WriteLine("  <xsl:param name='seriescount' />")
	Do delay.WriteLine("  <xsl:variable name='series' select='position()' />")
	Do delay.WriteLine("  <xsl:variable name='pctsubtot'>")
	Do delay.WriteLine("    <xsl:value-of select='sum(preceding-sibling::node()/"_datapath_") div $total' />")
	Do delay.WriteLine("  </xsl:variable>")
	Do delay.WriteLine("  <xsl:variable name='lastpct'>")
	Do delay.WriteLine("    <xsl:value-of select='sum(preceding-sibling::node()[1]/"_datapath_") div $total' />")
	Do delay.WriteLine("  </xsl:variable>")
	Do delay.WriteLine("  <xsl:variable name='mypct'>")
	Do delay.WriteLine("    <xsl:variable name='pctraw'>")
	Do delay.WriteLine("      <xsl:value-of select='sum("_datapath_") div $total' />")
	Do delay.WriteLine("    </xsl:variable>")
	Do delay.WriteLine("    <xsl:choose><xsl:when test='$pctraw &gt;= 1'>")
	Do delay.WriteLine("      <xsl:value-of select='0.99999' />")
	Do delay.WriteLine("    </xsl:when><xsl:otherwise>")
	Do delay.WriteLine("      <xsl:value-of select='$pctraw' />")
	Do delay.WriteLine("    </xsl:otherwise></xsl:choose>")
	Do delay.WriteLine("  </xsl:variable>")
	//Do delay.WriteLine("  <xsl:message><xsl:call-template name='util-sin-"_$$$groupNum_"'><xsl:with-param name='x' select='7 * $pi-"_$$$groupNum_" div 6' /></xsl:call-template></xsl:message>")
	
		#; **** LABELS + LINES****
	
	// this math is ugly.  stolen from %ZEN.SVGComponent.pieChart
	Do delay.WriteLine("  <xsl:variable name='sin'>")
	Do delay.WriteLine("    <xsl:call-template name='util-sin-"_$$$groupNum_"'>")
	Do delay.WriteLine("      <xsl:with-param name='x' select='($pctsubtot + ($mypct div 2)) * 2 * $pi-"_$$$groupNum_"' />")
	Do delay.WriteLine("    </xsl:call-template>")
	Do delay.WriteLine("  </xsl:variable>")
	Do delay.WriteLine("  <xsl:variable name='cos'>")
	Do delay.WriteLine("    <xsl:call-template name='util-cos-"_$$$groupNum_"'>")
	Do delay.WriteLine("      <xsl:with-param name='x' select='($pctsubtot + ($mypct div 2)) * 2 * $pi-"_$$$groupNum_"' />")
	Do delay.WriteLine("    </xsl:call-template>")
	Do delay.WriteLine("  </xsl:variable>")
	Do delay.WriteLine("  <xsl:variable name='f1'>")
	Do delay.WriteLine("    <xsl:choose><xsl:when test='(($sin * $sin) &lt; 0.1) and ($cos &gt; 0)'>")
	Do delay.WriteLine("      <xsl:value-of select='1.1 - $sin * $sin' />")
	Do delay.WriteLine("    </xsl:when><xsl:otherwise>")
	Do delay.WriteLine("      <xsl:value-of select='1.1' />")
	Do delay.WriteLine("    </xsl:otherwise></xsl:choose>")
	Do delay.WriteLine("  </xsl:variable>")
	
	Do delay.WriteLine("  <xsl:variable name='x1'>")
	Do delay.WriteLine("    <xsl:value-of select='format-number($sz"_mode1_" * $f1 * $sin,""##0.###"")' />")
	Do delay.WriteLine("  </xsl:variable>")
	Do delay.WriteLine("  <xsl:variable name='y1'>")
	Do delay.WriteLine("    <xsl:value-of select='format-number($sz"_mode1_" * $f1 * $cos,""##0.###"")' />")
	Do delay.WriteLine("  </xsl:variable>")
	Do delay.WriteLine("  <xsl:variable name='f2'>")
	Do delay.WriteLine("    <xsl:choose><xsl:when test='$lastpct + $mypct &gt; 0.1'>")
	Do delay.WriteLine("      <xsl:value-of select='0.9' />")
	Do delay.WriteLine("    </xsl:when><xsl:when test='$cos &lt; 0.3'>")
	Do delay.WriteLine("      <xsl:value-of select='0.9 - (($series mod 3) * 0.05)' />")
	Do delay.WriteLine("    </xsl:when><xsl:otherwise>")
	Do delay.WriteLine("      <xsl:value-of select='0.9 - (($series mod 3) * 0.1)' />")
	Do delay.WriteLine("    </xsl:otherwise></xsl:choose>")
	Do delay.WriteLine("  </xsl:variable>") 
	Do delay.WriteLine("  <xsl:variable name='x2'>")
	Do delay.WriteLine("    <xsl:choose><xsl:when test='$x1 &lt; 0'>")
	Do delay.WriteLine("      <xsl:value-of select='-1 * $f2 * $plotWidth"_mode1_" div 2' />")
	Do delay.WriteLine("    </xsl:when><xsl:otherwise>")
	Do delay.WriteLine("      <xsl:value-of select='$f2 * $plotWidth"_mode1_" div 2' />")
	Do delay.WriteLine("    </xsl:otherwise></xsl:choose>")
	Do delay.WriteLine("  </xsl:variable>") 
	
	// line
	if ..labelsVisible {
	Do delay.WriteLine("  <"_..SvgPrefix()_"polyline>")
	Do delay.WriteLine("    <xsl:attribute name='points'>")
	Do delay.WriteLine("      <xsl:value-of select=""concat($cx"_mode1_",' ',$cy"_mode1_",' ',$cx"_mode1_" + $x1,' ',$cy"_mode1_" + $y1,' ',$cx"_mode1_" + $x2,' ',$cy"_mode1_" + $y1)"" />")
	Do delay.WriteLine("    </xsl:attribute>")
	Do delay.WriteLine("    <xsl:choose><xsl:when test='($series &gt; 0) and ($seriescount &gt; 5) and (($lastpct + $mypct) &lt; 0.01)'>")
	Do delay.WriteLine("      <xsl:attribute name='style'>display:none</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.delay,"display:none")
	Do delay.WriteLine("    </xsl:when><xsl:otherwise>")
	Do delay.WriteLine("      <xsl:attribute name='style'>stroke-width: 0.25px; opacity: 0.7; fill:none</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.delay,"stroke-width: 0.25px; opacity: 0.7; fill:none")
	Do delay.WriteLine("      <xsl:attribute name='stroke'>")
	Do delay.WriteLine("        <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
	Do delay.WriteLine("          <xsl:with-param name='series' select='$series' />")
	Do delay.WriteLine("        </xsl:call-template>")
	Do delay.WriteLine("      </xsl:attribute>")
	Do delay.WriteLine("   </xsl:otherwise></xsl:choose>")
	Do delay.WriteLine(" </"_..SvgPrefix()_"polyline>")
	}
	
	#; **** SLICES *****
	
	Do delay.WriteLine("  <"_..SvgPrefix()_"path style='stroke-width: 0.1; fill-opacity: 1.0; stroke: gray; "_..plotStyle_"'>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.delay,"stroke-width: 0.1; fill-opacity: 1.0; stroke: gray; "_..plotStyle)
	Do delay.WriteLine("    <xsl:attribute name='fill'>")
	Do delay.WriteLine("      <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
	Do delay.WriteLine("        <xsl:with-param name='series' select='position()' />")
	Do delay.WriteLine("      </xsl:call-template>")
	Do delay.WriteLine("    </xsl:attribute>")
	Do delay.Write("    <xsl:attribute name='transform'>translate(")
	Do delay.Write("<xsl:value-of select='$cx"_mode1_"'/>")
	Do delay.Write(", ")
	Do delay.WriteLine("<xsl:value-of select='$cy"_mode1_"'/>)</xsl:attribute>")
	Do delay.Write("    <xsl:attribute name='d'>")
	Do delay.Write("      M 0 0 L ")
	
	// first edge
	Do delay.Write("      <xsl:call-template name='util-sin-"_$$$groupNum_"'>")
	Do delay.Write("        <xsl:with-param name='x' select='$pctsubtot * $pi-"_$$$groupNum_" * 2' />")
	Do delay.Write("        <xsl:with-param name='r' select='$sz"_mode1_"' />")
	Do delay.Write("      </xsl:call-template>")
	Do delay.Write("      <xsl:value-of select='"" ""' />")
	Do delay.Write("      <xsl:call-template name='util-cos-"_$$$groupNum_"'>")
	Do delay.Write("        <xsl:with-param name='x' select='$pctsubtot * $pi-"_$$$groupNum_" * 2' />")
	Do delay.Write("        <xsl:with-param name='r' select='$sz"_mode1_"' />")
	Do delay.Write("      </xsl:call-template>")

	// arc: first two are semi-major and semi-minor axes (ellipse)
	Do delay.Write("      A ")
	Do delay.Write("<xsl:value-of select='$sz"_mode1_"'/>")
	Do delay.Write("<xsl:text> </xsl:text> ")
	Do delay.Write("<xsl:value-of select='$sz"_mode1_"'/>")
	Do delay.Write("      <xsl:choose><xsl:when test='$mypct &gt;= 0.5'>")
	Do delay.Write("        1 1 0 ")
	Do delay.Write("      </xsl:when><xsl:otherwise>")
	Do delay.Write("        0 0 0 ")
	Do delay.Write("      </xsl:otherwise></xsl:choose>")
	
	// coords of end point
	Do delay.Write("      <xsl:call-template name='util-sin-"_$$$groupNum_"'>")
	Do delay.Write("        <xsl:with-param name='x' select='($pctsubtot + $mypct) * $pi-"_$$$groupNum_" * 2' />")
	Do delay.Write("        <xsl:with-param name='r' select='$sz"_mode1_"' />")
	Do delay.Write("      </xsl:call-template>")
	Do delay.Write("      <xsl:value-of select='"" ""' />")
	Do delay.Write("      <xsl:call-template name='util-cos-"_$$$groupNum_"'>")
	Do delay.Write("        <xsl:with-param name='x' select='($pctsubtot + $mypct) * $pi-"_$$$groupNum_" * 2' />")
	Do delay.Write("        <xsl:with-param name='r' select='$sz"_mode1_"' />")
	Do delay.Write("      </xsl:call-template>")
	
	Do delay.Write("      z")
	Do delay.Write("    </xsl:attribute>")
	
	Do delay.WriteLine("  </"_..SvgPrefix()_"path>")
	
	Do delay.WriteLine("</xsl:template>")
	
	Quit $$$OK
}

Method hasAxes()
{
	Quit 0
}

Method renderGetLabelText(ByRef context As %String, XSL As %GlobalCharacterStream)
{
	Do XSL.WriteLine("<xsl:template name='zenReportGetLabelText"_$$$groupNum_"'>")
	Do XSL.WriteLine("  <xsl:param name='series' select='1' />")
	Do XSL.WriteLine("  <xsl:param name='percentage' select='1' />")
	Set labelValues=..labelValues
	If ..labelValues="" {
		If $e(..seriesNames)="!" {
			if ..outputPercentage {
				if ..formatPercentage="" {
					if '..onlyPercentage {
						Do XSL.WriteLine("<xsl:value-of select='concat("_$e(..seriesNames,2,$l(..seriesNames))_",&quot; &quot;,100*$percentage)' />")
					} else {
						Do XSL.WriteLine("<xsl:value-of select='100*$percentage' />")
					}
				} else {
					if '..onlyPercentage {
						Do XSL.WriteLine("<xsl:value-of select='concat("_$e(..seriesNames,2,$l(..seriesNames))_",&quot; &quot;,format-number(100*$percentage,&quot;"_..formatPercentage_"&quot;))' />")
					} else {
						Do XSL.WriteLine("<xsl:value-of select='format-number(100*$percentage,&quot;"_..formatPercentage_"&quot;)' />")
					}
				}
			}
			else {
				Do XSL.WriteLine("<xsl:value-of select='"_$e(..seriesNames,2,$l(..seriesNames))_"' />")
			}
		} Else {
			if ..seriesNames'="" {
				set labelValues=..seriesNames
			} else {
				Do XSL.WriteLine("      <xsl:value-of select='$series' />")

			}
		}
	}
	if labelValues'="" {
		Do XSL.WriteLine("  <xsl:choose>")
		For i=1:1:$l(labelValues,",") {
			Do XSL.WriteLine("    <xsl:when test='$series = "_i_"'>")
			Set label=$p(labelValues,",",i)
			Set label=$zstrip(label,"<>W")
			if '..outputPercentage {
				If $e(label)="!" {
					Set label=$e(label,2,$l(label))
					Do XSL.WriteLine("      <xsl:value-of select='"_label_"' />")
				} Else {
					Do XSL.WriteLine("      "_label)
				}
			} else {
				if ..formatPercentage="" {
					if '..onlyPercentage {
						if $e(label)="!" {
							Set label=$e(label,2,$l(label))
							Do XSL.WriteLine("<xsl:value-of select='concat("_label_",&quot; &quot;,100*$percentage)' />")
						} else {
							Do XSL.WriteLine("<xsl:value-of select='concat(&quot;"_label_"&quot;,&quot; &quot;,100*$percentage)' />")
						}
					
					} else {
						Do XSL.WriteLine("<xsl:value-of select='100*$percentage' />")
					}
				} else { ; output with formatted percentage
					if '..onlyPercentage {
						if $e(label)="!" {
							Set label=$e(label,2,$l(label))
							Do XSL.WriteLine("<xsl:value-of select='concat("_label_",&quot; &quot;,format-number(100*$percentage,&quot;"_..formatPercentage_"&quot;))' />")
						} else {
								Do XSL.WriteLine("<xsl:value-of select='concat(&quot;"_label_"&quot;,&quot; &quot;,format-number(100*$percentage,&quot;"_..formatPercentage_"&quot;))' />")
						}
					} else {
						Do XSL.WriteLine("<xsl:value-of select='format-number(100*$percentage,&quot;"_..formatPercentage_"&quot;)' />")
					}

				}			
			}
			Do XSL.WriteLine("    </xsl:when>")
		}
		Do XSL.WriteLine("    <xsl:otherwise>")
		if '..outputPercentage {
			Do XSL.WriteLine("      <xsl:value-of select='$series' />")
		} else {
			if ..formatPercentage="" {
				if '..onlyPercentage {
					Do XSL.WriteLine("<xsl:value-of select='concat($series,&quot; &quot;,100*$percentage)' />")
				} else {
					Do XSL.WriteLine("<xsl:value-of select='100*$percentage' />")
				}
			} else {
				if '..onlyPercentage {
					Do XSL.WriteLine("<xsl:value-of select='concat($series,&quot; &quot;,format-number(100*$percentage,&quot;"_..formatPercentage_"&quot;))' />")
				} else {
					Do XSL.WriteLine("<xsl:value-of select='format-number(100*$percentage,&quot;"_..formatPercentage_"&quot;)' />")
				}
			}
		}
		Do XSL.WriteLine("    </xsl:otherwise>")
		Do XSL.WriteLine("  </xsl:choose>")
	}
	Do XSL.WriteLine("</xsl:template>")
}

Method renderTrigFunctions(ByRef context As %String, XSL As %GlobalCharacterStream)
{
	Do XSL.WriteLine("<xsl:variable name='pi-"_$$$groupNum_"' select='3.141592653589793238' />")
	
	// We'll need factorial for taylor series
	Do XSL.WriteLine("<xsl:template name='util-fact-"_$$$groupNum_"'>")
	Do XSL.WriteLine("  <xsl:param name='n' select='0' />")
	Do XSL.WriteLine("  <xsl:param name='acc' select='1' />")
	Do XSL.WriteLine("  <xsl:choose>")
	Do XSL.WriteLine("    <xsl:when test='$n &lt; 0'>")
	Do XSL.WriteLine("      1")
	Do XSL.WriteLine("    </xsl:when><xsl:when test='$n &lt;= 1'>")
	Do XSL.WriteLine("      <xsl:value-of select='$acc' />")
	Do XSL.WriteLine("    </xsl:when><xsl:otherwise>")
	Do XSL.WriteLine("      <xsl:call-template name='util-fact-"_$$$groupNum_"'>")
	Do XSL.WriteLine("        <xsl:with-param name='n' select='$n - 1' />")
	Do XSL.WriteLine("        <xsl:with-param name='acc' select='$n * $acc' />")
	Do XSL.WriteLine("      </xsl:call-template>")
	Do XSL.WriteLine("   </xsl:otherwise>")
	Do XSL.WriteLine("  </xsl:choose>")
	Do XSL.WriteLine("</xsl:template>")
	
	// calculate sine by taylor series
	// actually calculates for circle with radius $r, not unit circle
	// could be optimized by carrying around $lastxn and $lastfact parameters
	// so we could calculate n! by doing n * (n-1) * $lastfact, and similarly
	// for calculating: x^n = x * x * $lastxn.  But with $max so small this
	// seems unnecessary.
	Do XSL.WriteLine("<xsl:template name='util-sin-"_$$$groupNum_"'>")
	Do XSL.WriteLine("  <xsl:param name='x' select='0' />")
	Do XSL.WriteLine("  <xsl:param name='sum' select='0' />")
	Do XSL.WriteLine("  <xsl:param name='r' select='1' />")
	Do XSL.WriteLine("  <xsl:param name='factor' select='1' />")
	Do XSL.WriteLine("  <!-- max=4 gives around 3-4 decimal places of accuracy -->")
	Do XSL.WriteLine("  <xsl:param name='max' select='4' />")
	Do XSL.WriteLine("  <xsl:param name='n' select='0' />")
	Do XSL.WriteLine("  <xsl:choose><xsl:when test='$n &gt; $max'>")
	Do XSL.WriteLine("    <xsl:value-of select='format-number($r * $factor * $sum,""##0.###"")' />")
	Do XSL.WriteLine("  <!-- use symmetry to get $x between 0 and pi/2 -->")
	Do XSL.WriteLine("  </xsl:when><xsl:when test='$x &lt; 0'>")
	Do XSL.WriteLine("    <xsl:call-template name='util-sin-"_$$$groupNum_"'>")
	Do XSL.WriteLine("      <xsl:with-param name='x' select='$x + (2 * $pi-"_$$$groupNum_")' />")
	Do XSL.WriteLine("      <xsl:with-param name='max' select='$max' />")
	Do XSL.WriteLine("      <xsl:with-param name='factor' select='$factor' />")
	Do XSL.WriteLine("      <xsl:with-param name='r' select='$r' />")
	Do XSL.WriteLine("    </xsl:call-template>")
	Do XSL.WriteLine("  </xsl:when><xsl:when test='$x &gt;= (2 * $pi-"_$$$groupNum_")'>")
	Do XSL.WriteLine("    <xsl:call-template name='util-sin-"_$$$groupNum_"'>")
	Do XSL.WriteLine("      <xsl:with-param name='x' select='$x - (2 * $pi-"_$$$groupNum_")' />")
	Do XSL.WriteLine("      <xsl:with-param name='max' select='$max' />")
	Do XSL.WriteLine("      <xsl:with-param name='factor' select='$factor' />")
	Do XSL.WriteLine("      <xsl:with-param name='r' select='$r' />")
	Do XSL.WriteLine("    </xsl:call-template>")
	Do XSL.WriteLine("  </xsl:when><xsl:when test='$x &gt; $pi-"_$$$groupNum_"'>")
	Do XSL.WriteLine("    <xsl:call-template name='util-sin-"_$$$groupNum_"'>")
	Do XSL.WriteLine("      <xsl:with-param name='x' select='$x - $pi-"_$$$groupNum_"' />")
	Do XSL.WriteLine("      <xsl:with-param name='max' select='$max' />")
	Do XSL.WriteLine("      <xsl:with-param name='factor' select='-1 * $factor' />")
	Do XSL.WriteLine("      <xsl:with-param name='r' select='$r' />")
	Do XSL.WriteLine("    </xsl:call-template>")
	Do XSL.WriteLine("  </xsl:when><xsl:when test='$x &gt; ($pi-"_$$$groupNum_" div 2)'>")
	Do XSL.WriteLine("    <xsl:call-template name='util-sin-"_$$$groupNum_"'>")
	Do XSL.WriteLine("      <xsl:with-param name='x' select='$pi-"_$$$groupNum_" - $x' />")
	Do XSL.WriteLine("      <xsl:with-param name='max' select='$max' />")
	Do XSL.WriteLine("      <xsl:with-param name='factor' select='$factor' />")
	Do XSL.WriteLine("      <xsl:with-param name='r' select='$r' />")
	Do XSL.WriteLine("    </xsl:call-template>")
	Do XSL.WriteLine("  </xsl:when><xsl:otherwise>")
	Do XSL.WriteLine("    <!-- y = (-1)^n * x^(2n+1) / (2n+1)! -->")
	Do XSL.WriteLine("    <xsl:variable name='y'>")
	Do XSL.WriteLine("      <!-- ysign = -1 ^ n -->")
	Do XSL.WriteLine("      <xsl:variable name='ysign'>")
	Do XSL.WriteLine("        <xsl:choose><xsl:when test='$n mod 2 = 0'>")
	Do XSL.WriteLine("          1")
	Do XSL.WriteLine("        </xsl:when><xsl:otherwise>")
	Do XSL.WriteLine("          -1")
	Do XSL.WriteLine("        </xsl:otherwise></xsl:choose>")
	Do XSL.WriteLine("      </xsl:variable>")
	Do XSL.WriteLine("      <!-- yfact = (2n + 1)! -->")
	Do XSL.WriteLine("       <xsl:variable name='yfact'>")
	Do XSL.WriteLine("        <xsl:call-template name='util-fact-"_$$$groupNum_"'>")
	Do XSL.WriteLine("          <xsl:with-param name='n' select='2 * $n + 1' />")
	Do XSL.WriteLine("        </xsl:call-template>")
	Do XSL.WriteLine("      </xsl:variable>")
	Do XSL.WriteLine("      <!-- ypower = x ^ (2n+1) -->")
	Do XSL.WriteLine("      <xsl:variable name='ypower'>")
	Do XSL.WriteLine("        <xsl:call-template name='util-power'>")
	Do XSL.WriteLine("          <xsl:with-param name='base' select='$x' />")
	Do XSL.WriteLine("          <xsl:with-param name='power' select='2 * $n + 1' />")
	Do XSL.WriteLine("        </xsl:call-template>")
	Do XSL.WriteLine("      </xsl:variable>")
	Do XSL.WriteLine("      <xsl:value-of select='$ysign * $ypower div $yfact' />")
	Do XSL.WriteLine("    </xsl:variable>")
	Do XSL.WriteLine("    <xsl:call-template name='util-sin-"_$$$groupNum_"'>")
	Do XSL.WriteLine("      <xsl:with-param name='x' select='$x' />")
	Do XSL.WriteLine("      <xsl:with-param name='max' select='$max' />")
	Do XSL.WriteLine("      <xsl:with-param name='factor' select='$factor' />")
	Do XSL.WriteLine("      <xsl:with-param name='n' select='$n + 1' />")
	Do XSL.WriteLine("      <xsl:with-param name='sum' select='$sum + $y' />")
	Do XSL.WriteLine("      <xsl:with-param name='r' select='$r' />")
	Do XSL.WriteLine("    </xsl:call-template>")
	Do XSL.WriteLine("  </xsl:otherwise></xsl:choose>")
	Do XSL.WriteLine("</xsl:template>")
	
	// calculate cosine using the identity: cos(x) = sin(pi/2 - x)
	Do XSL.WriteLine("<xsl:template name='util-cos-"_$$$groupNum_"'>")
	Do XSL.WriteLine("  <xsl:param name='x' select='0' />")
	Do XSL.WriteLine("  <xsl:param name='r' select='1' />")
	Do XSL.WriteLine("  <!-- max=4 gives around 3-4 decimal places of accuracy -->")
	Do XSL.WriteLine("  <xsl:param name='max' select='4' />")
	Do XSL.WriteLine("  <xsl:call-template name='util-sin-"_$$$groupNum_"'>")
	Do XSL.WriteLine("    <xsl:with-param name='x' select='($pi-"_$$$groupNum_" div 2) - $x' />")
	Do XSL.WriteLine("    <xsl:with-param name='max' select='$max' />")
	Do XSL.WriteLine("    <xsl:with-param name='r' select='$r' />")
	Do XSL.WriteLine("  </xsl:call-template>")
	Do XSL.WriteLine("</xsl:template>")
}

Method renderSeriesLabels(context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream)
{
	if '..labelsVisible quit $$$OK
	;Set gw = ..plot.plotWidth * 0.60
	;Set gh = ..plot.plotHeight * 0.75
	;Set sz = $s(gw > gh:gh/2, 1:gw/2)
	;Set cx = ..plot.plotWidth/2
	;Set cy = ..plot.plotHeight/2
	Set mode1 = "legend"_$$$groupNum
	Set mode="labelslices"_$$$groupNum
	
	Set totalpath=..seriesGroup_"/"
	Set:..dataGroup'="" totalpath = totalpath_..dataGroup_"/"
	
	// add first datafield, without the expected leading '!'
	Set totalpath=totalpath_$e($p(..dataFields,","),2,*)
	
	Do XSL.WriteLine("<xsl:variable name='total2' select='sum("_..qualify(totalpath)_")' />")
	
	Do XSL.WriteLine("  <xsl:for-each select='"_..qualify(..seriesGroup)_"'>")
	Do XSL.WriteLine("  <xsl:call-template name='"_"SeriesLabels-"_$$$groupNum_"'>")
	Do XSL.WriteLine("    <xsl:with-param name='total' select='$total2' />")
	Do XSL.WriteLine("    <xsl:with-param name='seriescount' select='$seriescount' />")
	Do XSL.WriteLine("  </xsl:call-template>")
	Do XSL.WriteLine("  </xsl:for-each>")
	#; *** SERIES ****
	
	Set datafield = $e($p(..dataFields,","),2,*)
	If ..dataGroup="" {
		Set datapath = datafield
	} Else {
		Set datapath = ..dataGroup_"/"_datafield
	}

	Do delay.WriteLine("<xsl:template name='"_"SeriesLabels-"_$$$groupNum_"'>")
	Do delay.WriteLine("  <xsl:param name='total' select='1' />")
	Do delay.WriteLine("  <xsl:param name='seriescount' />")
	
	Do delay.WriteLine("  <xsl:variable name='series' select='position()' />")
	Do delay.WriteLine("  <xsl:variable name='pctsubtot'>")
	Do delay.WriteLine("    <xsl:value-of select='sum(preceding-sibling::node()/"_datapath_") div $total' />")
	Do delay.WriteLine("  </xsl:variable>")
	Do delay.WriteLine("  <xsl:variable name='lastpct'>")
	Do delay.WriteLine("    <xsl:value-of select='sum(preceding-sibling::node()[1]/"_datapath_") div $total' />")
	Do delay.WriteLine("  </xsl:variable>")
	Do delay.WriteLine("  <xsl:variable name='mypct'>")
	Do delay.WriteLine("    <xsl:variable name='pctraw'>")
	Do delay.WriteLine("      <xsl:value-of select='sum("_datapath_") div $total' />")
	Do delay.WriteLine("    </xsl:variable>")
	Do delay.WriteLine("    <xsl:choose><xsl:when test='$pctraw &gt;= 1'>")
	Do delay.WriteLine("      <xsl:value-of select='0.99999' />")
	Do delay.WriteLine("    </xsl:when><xsl:otherwise>")
	Do delay.WriteLine("      <xsl:value-of select='$pctraw' />")
	Do delay.WriteLine("    </xsl:otherwise></xsl:choose>")
	Do delay.WriteLine("  </xsl:variable>")
	// this math is ugly.  stolen from %ZEN.SVGComponent.pieChart
	Do delay.WriteLine("  <xsl:variable name='sin'>")
	Do delay.WriteLine("    <xsl:call-template name='util-sin-"_$$$groupNum_"'>")
	Do delay.WriteLine("      <xsl:with-param name='x' select='($pctsubtot + ($mypct div 2)) * 2 * $pi-"_$$$groupNum_"' />")
	Do delay.WriteLine("    </xsl:call-template>")
	Do delay.WriteLine("  </xsl:variable>")
	Do delay.WriteLine("  <xsl:variable name='cos'>")
	Do delay.WriteLine("    <xsl:call-template name='util-cos-"_$$$groupNum_"'>")
	Do delay.WriteLine("      <xsl:with-param name='x' select='($pctsubtot + ($mypct div 2)) * 2 * $pi-"_$$$groupNum_"' />")
	Do delay.WriteLine("    </xsl:call-template>")
	Do delay.WriteLine("  </xsl:variable>")
	Do delay.WriteLine("  <xsl:variable name='f1'>")
	Do delay.WriteLine("    <xsl:choose><xsl:when test='(($sin * $sin) &lt; 0.1) and ($cos &gt; 0)'>")
	Do delay.WriteLine("      <xsl:value-of select='1.1 - $sin * $sin' />")
	Do delay.WriteLine("    </xsl:when><xsl:otherwise>")
	Do delay.WriteLine("      <xsl:value-of select='1.1' />")
	Do delay.WriteLine("    </xsl:otherwise></xsl:choose>")
	Do delay.WriteLine("  </xsl:variable>")
	
	Do delay.WriteLine("  <xsl:variable name='x1'>")
	Do delay.WriteLine("    <xsl:value-of select='format-number($sz"_mode1_" * $f1 * $sin,""##0.###"")' />")
	Do delay.WriteLine("  </xsl:variable>")
	Do delay.WriteLine("  <xsl:variable name='y1'>")
	Do delay.WriteLine("    <xsl:value-of select='format-number($sz"_mode1_" * $f1 * $cos,""##0.###"")' />")
	Do delay.WriteLine("  </xsl:variable>")
	Do delay.WriteLine("  <xsl:variable name='f2'>")
	Do delay.WriteLine("    <xsl:choose><xsl:when test='$lastpct + $mypct &gt; 0.1'>")
	Do delay.WriteLine("      <xsl:value-of select='0.9' />")
	Do delay.WriteLine("    </xsl:when><xsl:when test='$cos &lt; 0.3'>")
	Do delay.WriteLine("      <xsl:value-of select='0.9 - (($series mod 3) * 0.05)' />")
	Do delay.WriteLine("    </xsl:when><xsl:otherwise>")
	Do delay.WriteLine("      <xsl:value-of select='0.9 - (($series mod 3) * 0.1)' />")
	Do delay.WriteLine("    </xsl:otherwise></xsl:choose>")
	Do delay.WriteLine("  </xsl:variable>") 
	Do delay.WriteLine("  <xsl:variable name='x2'>")
	Do delay.WriteLine("    <xsl:choose><xsl:when test='$x1 &lt; 0'>")
	Do delay.WriteLine("      <xsl:value-of select='-1 * $f2 * $plotWidth"_mode1_" div 2' />")
	Do delay.WriteLine("    </xsl:when><xsl:otherwise>")
	Do delay.WriteLine("      <xsl:value-of select='$f2 * $plotWidth"_mode1_" div 2' />")
	Do delay.WriteLine("    </xsl:otherwise></xsl:choose>")
	Do delay.WriteLine("  </xsl:variable>") 
	
	//label
	Do delay.WriteLine("  <"_..SvgPrefix()_"text class='chart-yLabel'>")
	s key="" for  s key=$o(context("SVGATTRS","chart-yLabel",key)) q:key=""  d
	. Do delay.WriteLine("  <xsl:attribute name='"_key_"'>"_context("SVGATTRS","chart-yLabel",key)_"</xsl:attribute>")
	Do delay.WriteLine("    <xsl:attribute name='x'>")
	Do delay.WriteLine("      <xsl:value-of select='$cx"_mode1_" + $x2' />")
	Do delay.WriteLine("    </xsl:attribute>")
	Do delay.WriteLine("    <xsl:attribute name='y'>")
	Do delay.WriteLine("      <xsl:value-of select='$cy"_mode1_" + $y1 - 0.5' />")
	Do delay.WriteLine("    </xsl:attribute>")
	Do delay.WriteLine("    <xsl:choose><xsl:when test='($series &gt; 0) and ($seriescount &gt; 5) and (($lastpct + $mypct) &lt; 0.01)'>")
	Do delay.WriteLine("      <xsl:attribute name='style'>display:none</xsl:attribute>")
	Do delay.WriteLine("    </xsl:when><xsl:otherwise>")
	s labelStyle=..labelStyle_";stroke:black;stroke-width:0.1px"
	Do delay.Write("      <xsl:attribute name='style'>"_labelStyle_";fill:")
	Do delay.Write("        <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
	Do delay.Write("          <xsl:with-param name='series' select='$series' />")
	Do delay.Write("        </xsl:call-template>")
	Do delay.Write("      </xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.delay,labelStyle)
	Do delay.Write("      <xsl:attribute name='fill'>")
	Do delay.Write("      <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
	Do delay.Write("          <xsl:with-param name='series' select='$series' />")
	Do delay.Write("        </xsl:call-template>")
	Do delay.Write("      </xsl:attribute>")
		
	Do delay.WriteLine("   </xsl:otherwise></xsl:choose>")
	Do delay.WriteLine("   <xsl:attribute name='text-anchor'>")
	Do delay.WriteLine("     <xsl:choose><xsl:when test='$x1 &lt; 0'>")
	Do delay.WriteLine("       <xsl:value-of select='""start""' />")
	Do delay.WriteLine("     </xsl:when><xsl:otherwise>")
	Do delay.WriteLine("       <xsl:value-of select='""end""' />")
	Do delay.WriteLine("     </xsl:otherwise></xsl:choose>")
	Do delay.WriteLine("   </xsl:attribute>")
	Do delay.WriteLine("   <xsl:call-template name='zenReportGetLabelText"_$$$groupNum_"'>")
	Do delay.WriteLine("     <xsl:with-param name='series' select='$series' />")
	Do delay.WriteLine("     <xsl:with-param name='percentage' select='$mypct' />")
	Do delay.WriteLine("   </xsl:call-template>")
	Do delay.WriteLine("  </"_..SvgPrefix()_"text>")
	
	Do delay.WriteLine("</xsl:template>")
	
	Quit $$$OK
}

}
