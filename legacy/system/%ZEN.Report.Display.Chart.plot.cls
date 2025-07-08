/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.ReportUtil

/// Internal use only.  Each chart creates a plot object to keep track of 
/// information about its plot area.
Class %ZEN.Report.Display.Chart.plot Extends %RegisteredObject [ Deprecated, System = 4 ]
{

Property plotWidth As %ZEN.Datatype.float;

Property plotHeight As %ZEN.Datatype.float;

Property plotTop As %ZEN.Datatype.float;

Property plotBottom As %ZEN.Datatype.float;

Property plotLeft As %ZEN.Datatype.float;

Property plotRight As %ZEN.Datatype.float;

Property yGridType As %ZEN.Datatype.string;

Property xGridType As %ZEN.Datatype.string;

Method calculateRangeValues(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, chart As %ZEN.Report.Display.Chart.chart)
{
	Set mode = "legend"_$$$groupNum
	Set ..plotLeft = chart.marginLeft
	if ('chart.legendAutoPosition) {
		Do delay.WriteLine("<xsl:variable name='plotLeft"_mode_"' select='"_..plotLeft_"'/>")
	} else {
		Do delay.WriteLine("<xsl:variable name='plotLeft"_mode_"' select='$legendwidth"_mode_"'/>")
	}
	Set ..plotRight = 100 - chart.marginRight
	Set ..plotTop = chart.marginTop
	Set ..plotBottom = 100 - chart.marginBottom - chart.xAxis.labelDisplacement
	Set ..plotWidth = 100 - chart.marginLeft - chart.marginRight
	if ('chart.legendAutoPosition) {
		Do delay.WriteLine("<xsl:variable name='plotWidth"_mode_"' select='"_..plotWidth_"'/>")
	} else {
		Do delay.WriteLine("<xsl:variable name='plotWidth"_mode_"' select='100 - $plotLeft"_mode_" - "_chart.marginRight_"'/>")
	}

	Set ..plotHeight = 100 - chart.marginTop - chart.marginBottom - chart.xAxis.labelDisplacement
	
	Do XSL.WriteLine("<xsl:variable name='"_$$$seriescount_"'><xsl:call-template name='zenReportGetSeriesCount"_$$$groupNum_"'/></xsl:variable>")
	Do XSL.WriteLine("<xsl:variable name='"_$$$seriessize_"'>")
	Do XSL.WriteLine("  <xsl:call-template name='zenReportGetSeriesSize"_$$$groupNum_"'>")
	Set chart.seriesSize=$zstrip(chart.seriesSize,"<>W")
	If $e(chart.seriesSize)="!" {
	} ElseIf chart.seriesSize'="" {
	} ElseIf chart.dataGroup="" {
	} ElseIf chart.seriesGroup="" {
	} Else {
		Do XSL.WriteLine("   <xsl:with-param name='seriescount' select='$seriescount' />")
	}
	Do XSL.WriteLine("  </xsl:call-template>")
	Do XSL.WriteLine("</xsl:variable>")
	
	If 'chart.hasAxes() Quit $$$OK
	
	Set ..yGridType = chart.getYAxisType()
	Set ..xGridType = chart.getXAxisType()
	
	// Get value range for value axes that do not supply maxValue or minValue.
	Do:..needsXDataMax(chart) XSL.WriteLine("<xsl:variable name='"_$$$dataXMax_"'><xsl:call-template name='zenReportGetXMaxValue"_$$$groupNum_"'/></xsl:variable>")
	Do:..needsXDataMin(chart) XSL.WriteLine("<xsl:variable name='"_$$$dataXMin_"'><xsl:call-template name='zenReportGetXMinValue"_$$$groupNum_"'/></xsl:variable>")
	Do:..needsYDataMax(chart) XSL.WriteLine("<xsl:variable name='"_$$$dataYMax_"'><xsl:call-template name='zenReportGetYMaxValue"_$$$groupNum_"'/></xsl:variable>")
	Do:..needsYDataMin(chart) XSL.WriteLine("<xsl:variable name='"_$$$dataYMin_"'><xsl:call-template name='zenReportGetYMinValue"_$$$groupNum_"'/></xsl:variable>")

	
	// Get raw max/min values for value axis/axes
	Set chart.xAxis.maxValue=$zstrip(chart.xAxis.maxValue,"<>W")
	Set chart.xAxis.minValue=$zstrip(chart.xAxis.minValue,"<>W")
	Set chart.yAxis.maxValue=$zstrip(chart.yAxis.maxValue,"<>W")
	Set chart.yAxis.minValue=$zstrip(chart.yAxis.minValue,"<>W")
	Set chart.xAxis.maxValueDisplacement=$zstrip(chart.xAxis.maxValueDisplacement,"<>W")
	Set chart.xAxis.minValueDisplacement=$zstrip(chart.xAxis.minValueDisplacement,"<>W")
	Set chart.yAxis.maxValueDisplacement=$zstrip(chart.yAxis.maxValueDisplacement,"<>W")
	Set chart.yAxis.minValueDisplacement=$zstrip(chart.yAxis.minValueDisplacement,"<>W")

	If ..yGridType="value" {
		If chart.yAxis.maxValue'="" {
			If $e(chart.yAxis.maxValue)="!" {
				Set maxval=$e(chart.yAxis.maxValue,2,$l(chart.yAxis.maxValue))
			} Else {
				Set maxval=chart.yAxis.maxValue
			}
			Do XSL.WriteLine("<xsl:variable name='"_$$$yRangeMax_"' select='"_maxval_"' />")
		} Else {
			if (chart.yAxis.maxValueDisplacement="") {
				Do XSL.WriteLine("<xsl:variable name='"_$$$yRangeMax_"' select='$"_($$$dataYMax)_"' />")
			} else {
				if ($e(chart.yAxis.maxValueDisplacement,$L(chart.yAxis.maxValueDisplacement))'="%") {
					Set dy=chart.yAxis.maxValueDisplacement
					Do XSL.WriteLine("<xsl:variable name='"_$$$yRangeMax_"' select='$"_($$$dataYMax)_" + "_dy_"' />")
				} else {
					If chart.yAxis.minValue'="" {
						If $e(chart.yAxis.minValue)="!" {
							Set minval=$e(chart.yAxis.minValue,2,$l(chart.yAxis.minValue))
						} Else {
							Set minval=chart.yAxis.minValue
						}
					} else {
						Set minval="$"_$$$dataYMin
					}
					Set dy = "(($"_$$$dataYMax_" - "_minval_") * ("_$e(chart.yAxis.maxValueDisplacement,1,$L(chart.yAxis.maxValueDisplacement)-1)_" ) div 100.00)"
					Do XSL.WriteLine("<xsl:variable name='"_$$$yRangeMax_"' select='$"_($$$dataYMax)_" + "_dy_"' />")
				}
			}
		}
		If chart.yAxis.minValue'="" {
			If $e(chart.yAxis.minValue)="!" {
				Set minval=$e(chart.yAxis.minValue,2,$l(chart.yAxis.minValue))
			} Else {
				Set minval=chart.yAxis.minValue
			}
			Do XSL.WriteLine("<xsl:variable name='"_$$$yRangeMin_"' select='"_minval_"' />")
		} Else {
			if (chart.yAxis.minValueDisplacement="") {
				Do XSL.WriteLine("<xsl:variable name='"_$$$yRangeMin_"' select='$"_$$$dataYMin_"' />")
			} else {
				if ($e(chart.yAxis.minValueDisplacement,$L(chart.yAxis.minValueDisplacement))'="%") {
					Set dy=chart.yAxis.minValueDisplacement
					Do XSL.WriteLine("<xsl:variable name='"_$$$yRangeMin_"' select='$"_$$$dataYMin_" + "_dy_"' />")
				} else {
					If chart.yAxis.maxValue'="" {
						If $e(chart.yAxis.maxValue)="!" {
							Set maxval=$e(chart.yAxis.maxValue,2,$l(chart.yAxis.maxValue))
						} Else {
							Set maxval=chart.yAxis.maxValue
						}
					} else {
						Set maxval="$"_$$$dataYMax
					}
					Set dy = "(("_maxval_" - $"_$$$dataYMin_") * ("_$e(chart.yAxis.minValueDisplacement,1,$L(chart.yAxis.minValueDisplacement)-1)_" ) div 100.00)"
					Do XSL.WriteLine("<xsl:variable name='"_$$$yRangeMin_"' select='$"_($$$dataYMin)_" + "_dy_"' />")

				}
			}
		}
	}
	
	If ..xGridType="value" {
		If chart.xAxis.maxValue'="" {
			If $e(chart.xAxis.maxValue)="!" {
				Set maxval=$e(chart.xAxis.maxValue,2,$l(chart.xAxis.maxValue))
			} Else {
				Set maxval=chart.xAxis.maxValue
			}
			Do XSL.WriteLine("<xsl:variable name='"_$$$xRangeMax_"' select='"_maxval_"' />")
		} Else {
			if (chart.xAxis.maxValueDisplacement="") {
				Do XSL.WriteLine("<xsl:variable name='"_$$$xRangeMax_"' select='$"_($$$dataXMax)_"' />")
			} else {
				if ($e(chart.xAxis.maxValueDisplacement,$L(chart.xAxis.maxValueDisplacement))'="%") {
					Set dx=chart.xAxis.maxValueDisplacement
					Do XSL.WriteLine("<xsl:variable name='"_$$$xRangeMax_"' select='$"_($$$dataXMax)_" + "_dx_"' />")
				} else {
					If chart.xAxis.minValue'="" {
						If $e(chart.xAxis.minValue)="!" {
							Set minval=$e(chart.xAxis.minValue,2,$l(chart.xAxis.minValue))
						} Else {
							Set minval=chart.xAxis.minValue
						}
					} else {
						Set minval="$"_$$$dataXMin
					}
					Set dx = "(($"_$$$dataXMax_" - "_minval_")*"_$e(chart.xAxis.maxValueDisplacement,1,$L(chart.xAxis.maxValueDisplacement)-1)_" div 100.00)"
					Do XSL.WriteLine("<xsl:variable name='"_$$$xRangeMax_"' select='$"_($$$dataXMax)_" + "_dx_"' />")
				}
			}
		}
		If chart.xAxis.minValue'="" {
			If $e(chart.xAxis.minValue)="!" {
				Set minval=$e(chart.xAxis.minValue,2,$l(chart.xAxis.minValue))
			} Else {
				Set minval=chart.xAxis.minValue
			}
			Do XSL.WriteLine("<xsl:variable name='"_$$$xRangeMin_"' select='"_minval_"' />")
			
		} else {
			if (chart.xAxis.minValueDisplacement="") {
				Do XSL.WriteLine("<xsl:variable name='"_$$$xRangeMin_"' select='$"_($$$dataXMin)_"' />")
			} else {

				if ($e(chart.xAxis.minValueDisplacement,$L(chart.xAxis.minValueDisplacement))'="%") {
					Set dx=chart.xAxis.minValueDisplacement
					Do XSL.WriteLine("<xsl:variable name='"_$$$xRangeMin_"' select='$"_$$$dataXMin_" + "_dx_"' />")
				} else {
					If chart.xAxis.maxValue'="" {
						If $e(chart.xAxis.maxValue)="!" {
							Set maxval=$e(chart.xAxis.maxValue,2,$l(chart.xAxis.maxValue))
						} Else {
							Set maxval=chart.xAxis.maxValue
						}
					} else {
						Set maxval="$"_$$$dataXMax
					}
					Set dx = "(("_maxval_" - $"_$$$dataXMin_")*"_$e(chart.xAxis.minValueDisplacement,1,$L(chart.xAxis.minValueDisplacement)-1)_" div 100.00)"
					Do XSL.WriteLine("<xsl:variable name='"_$$$xRangeMin_"' select='$"_($$$dataXMin)_" + "_dx_"' />")
	
				}
			}
		}
	}
	
	// Get Y Major Units
	If chart.yAxis.majorUnits '= "" {
		if $e(chart.yAxis.majorUnits)'="!" {
			Do XSL.WriteLine("<xsl:variable name='"_$$$yMajorUnits_"' select='"_chart.yAxis.majorUnits_"' />")
		} else {
			Do XSL.WriteLine("<xsl:variable name='"_$$$yMajorUnits_"'>")
			Do XSL.WriteLine("<xsl:value-of select='"_$e(chart.yAxis.majorUnits,2,*)_"' />")
			Do XSL.WriteLine("</xsl:variable>")

		}
	} Else {
		If ..yGridType="category" {
			Do XSL.WriteLine("<xsl:variable name='"_$$$yMajorUnits_"' select='ceiling($"_$$$seriessize_" div 10)' />")
		} Else {
			Do XSL.WriteLine("<xsl:variable name='"_$$$yMajorUnits_"'>")
			Do XSL.WriteLine("  <xsl:call-template name='zenReportFindScaleUnits'>")
			Do XSL.WriteLine("    <xsl:with-param name='val' select='$"_$$$yRangeMax_" - $"_$$$yRangeMin_"' />")
			Do XSL.WriteLine("  </xsl:call-template>")
			Do XSL.WriteLine("</xsl:variable>")
		}
	}
	
	// Get Y Minor Units
	If chart.yAxis.minorUnits '= "" {
		if $e(chart.yAxis.minorUnits)'="!" {
			Do XSL.WriteLine("<xsl:variable name='"_$$$yMinorUnits_"' select='"_chart.yAxis.minorUnits_"' />")
		} else {
			Do XSL.WriteLine("<xsl:variable name='"_$$$yMinorUnits_"'>")
			Do XSL.WriteLine("<xsl:value-of select='"_$e(chart.yAxis.minorUnits,2,*)_"' />")
			Do XSL.WriteLine("</xsl:variable>")
			
		}
	} Else {
		Do XSL.WriteLine("<xsl:variable name='"_$$$yMinorUnits_"' select='$"_$$$yMajorUnits_" div 5' />")
	}
	
	// Get Y Label Units
	If chart.yAxis.labelUnits '= "" {
		if $e(chart.yAxis.labelUnits)'="!" {
			Do XSL.WriteLine("<xsl:variable name='"_$$$yLabelUnits_"' select='"_chart.yAxis.labelUnits_"' />")
		} else {
			Do XSL.WriteLine("<xsl:variable name='"_$$$yLabelUnits_"'>")
			Do XSL.WriteLine("<xsl:value-of select='"_$e(chart.yAxis.labelUnits,2,*)_"' />")
			Do XSL.WriteLine("</xsl:variable>")
		}
	} Else {
		Do XSL.WriteLine("<xsl:variable name='"_$$$yLabelUnits_"' select='$"_$$$yMajorUnits_"' />")
	}
	
	// Get X Major Units
	If chart.xAxis.majorUnits '= "" {
		if $e(chart.xAxis.majorUnits)'="!" {
			Do XSL.WriteLine("<xsl:variable name='"_$$$xMajorUnits_"' select='"_chart.xAxis.majorUnits_"' />")
		} else {
			Do XSL.WriteLine("<xsl:variable name='"_$$$xMajorUnits_"'>")
			Do XSL.WriteLine("<xsl:value-of select='"_$e(chart.xAxis.majorUnits,2,*)_"' />")
			Do XSL.WriteLine("</xsl:variable>")

		}
	} Else {
		If ..xGridType="category" {
			Do XSL.WriteLine("<xsl:variable name='"_$$$xMajorUnits_"' select='ceiling($"_$$$seriessize_" div 10)' />")
		} Else {
	
			Do XSL.WriteLine("<xsl:variable name='"_$$$xMajorUnits_"'>")
			Do XSL.WriteLine("  <xsl:call-template name='zenReportFindScaleUnits'>")
			Do XSL.WriteLine("    <xsl:with-param name='val' select='$"_$$$xRangeMax_" - $"_$$$xRangeMin_"' />")
			Do XSL.WriteLine("  </xsl:call-template>")
			Do XSL.WriteLine("</xsl:variable>")
		}
	}
	
	// Get X Minor Units
	If chart.xAxis.minorUnits '= "" {
		if $e(chart.xAxis.minorUnits)'="!" {
			Do XSL.WriteLine("<xsl:variable name='"_$$$xMinorUnits_"' select='"_chart.xAxis.minorUnits_"' />")
		} else {
			Do XSL.WriteLine("<xsl:variable name='"_$$$xMinorUnits_"'>")
			Do XSL.WriteLine("<xsl:value-of select='"_$e(chart.xAxis.minorUnits,2,*)_"' />")
			Do XSL.WriteLine("</xsl:variable>")
			
		}
	} Else {
		Do XSL.WriteLine("<xsl:variable name='"_$$$xMinorUnits_"' select='$"_$$$xMajorUnits_" div 5' />")
	}
	
	// Get X Label Units
	If chart.xAxis.labelUnits '= "" {
		if $e(chart.xAxis.labelUnits)'="!" {
			Do XSL.WriteLine("<xsl:variable name='"_$$$xLabelUnits_"' select='"_chart.xAxis.labelUnits_"' />")
		} else {
			Do XSL.WriteLine("<xsl:variable name='"_$$$xLabelUnits_"'>")
			Do XSL.WriteLine("<xsl:value-of select='"_$e(chart.xAxis.labelUnits,2,*)_"' />")
			Do XSL.WriteLine("</xsl:variable>")

		}
	} Else {
		Do XSL.WriteLine("<xsl:variable name='"_$$$xLabelUnits_"' select='$"_$$$xMajorUnits_"' />")
	}
	
	// Finalize Y Axis Max/Min
	If (..yGridType="value") { 
		Do XSL.WriteLine("<xsl:variable name='"_$$$yMax_"'>")
		If chart.xAxis.maxValue="" {
			Do XSL.WriteLine("  <xsl:choose><xsl:when test='$"_$$$yMajorUnits_" = 0'>")
			Do XSL.WriteLine("    <xsl:value-of select='$"_$$$yRangeMax_"'/>")
			Do XSL.WriteLine("  </xsl:when><xsl:otherwise>")
			Do XSL.WriteLine("    <xsl:value-of select='ceiling($"_$$$yRangeMax_" div $"_$$$yMajorUnits_") * $"_$$$yMajorUnits_"' />")
			Do XSL.WriteLine("  </xsl:otherwise></xsl:choose>")
		} Else {
			Do XSL.WriteLine("  <xsl:value-of select='$"_$$$yRangeMax_"' />")
		}
		Do XSL.WriteLine("</xsl:variable>")
		
		Do XSL.WriteLine("<xsl:variable name='"_$$$yMin_"'>")
		If chart.xAxis.minValue="" {
			Do XSL.WriteLine("  <xsl:choose><xsl:when test='$"_$$$yMajorUnits_" = 0'>")
			Do XSL.WriteLine("    <xsl:value-of select='$"_$$$yRangeMin_"'/>")
			Do XSL.WriteLine("  </xsl:when><xsl:otherwise>")
			Do XSL.WriteLine("    <xsl:value-of select='floor($"_$$$yRangeMin_" div $"_$$$yMajorUnits_") * $"_$$$yMajorUnits_"' />")
			Do XSL.WriteLine("  </xsl:otherwise></xsl:choose>")
		} Else {
			Do XSL.WriteLine("  <xsl:value-of select='$"_$$$yRangeMin_"' />")
		}
		Do XSL.WriteLine("</xsl:variable>")
		Do XSL.WriteLine("<xsl:variable name='"_$$$yRange_"' select='$"_$$$yMax_" - $"_$$$yMin_"' />")
	} Else {
		Do XSL.WriteLine("<xsl:variable name='"_$$$yRange_"' select='0' />")
		Do XSL.WriteLine("<xsl:variable name='"_$$$yMin_"' select='0' />")
		Do XSL.WriteLine("<xsl:variable name='"_$$$yMax_"' select='0' />")
	}
	
	// Finalize X Axis Max/Min
	If (..xGridType="value") { 
		Do XSL.WriteLine("<xsl:variable name='"_$$$xMax_"'>")
		If chart.xAxis.maxValue="" {
			Do XSL.WriteLine("  <xsl:choose><xsl:when test='$"_$$$xMajorUnits_" = 0'>")
			Do XSL.WriteLine("    <xsl:value-of select='$"_$$$xRangeMax_"'/>")
			Do XSL.WriteLine("  </xsl:when><xsl:otherwise>")
			Do XSL.WriteLine("    <xsl:value-of select='ceiling($"_$$$xRangeMax_" div $"_$$$xMajorUnits_") * $"_$$$xMajorUnits_"' />")
			Do XSL.WriteLine("  </xsl:otherwise></xsl:choose>")
		} Else {
			Do XSL.WriteLine("  <xsl:value-of select='$"_$$$xRangeMax_"' />")
		}
		Do XSL.WriteLine("</xsl:variable>")
		
		Do XSL.WriteLine("<xsl:variable name='"_$$$xMin_"'>")
		If chart.xAxis.minValue="" {
			Do XSL.WriteLine("  <xsl:choose><xsl:when test='$"_$$$xMajorUnits_" = 0'>")
			Do XSL.WriteLine("    <xsl:value-of select='$"_$$$xRangeMin_"'/>")
			Do XSL.WriteLine("  </xsl:when><xsl:otherwise>")
			Do XSL.WriteLine("    <xsl:value-of select='floor($"_$$$xRangeMin_" div $"_$$$xMajorUnits_") * $"_$$$xMajorUnits_"' />")
			Do XSL.WriteLine("  </xsl:otherwise></xsl:choose>")
		} Else {
			Do XSL.WriteLine("  <xsl:value-of select='$"_$$$xRangeMin_"' />")
		}
		Do XSL.WriteLine("</xsl:variable>")
		Do XSL.WriteLine("<xsl:variable name='"_$$$xRange_"' select='$"_$$$xMax_" - $"_$$$xMin_"' />")
	} Else {
		Do XSL.WriteLine("<xsl:variable name='"_$$$xRange_"' select='0' />")
		Do XSL.WriteLine("<xsl:variable name='"_$$$xMin_"' select='0' />")
		Do XSL.WriteLine("<xsl:variable name='"_$$$xMax_"' select='0' />")
	}
	
	// Set up default base values
	If chart.yAxis.baseValue="" {
		Do XSL.WriteLine("<xsl:variable name='"_$$$yBase_"' select='"_..plotHeight_"' />")
	} Else {
		Do XSL.WriteLine("<xsl:variable name='"_$$$yBase_"'>")
		Do XSL.WriteLine("  <xsl:variable name='yBaseRaw'>")
		Do XSL.WriteLine("    <xsl:call-template name='zenReportGetPlotY"_$$$groupNum_"'>")
		Do chart.writeWithParamsNoBase(.XSL)
		Do XSL.WriteLine("      <xsl:with-param name='val' select='"_chart.yAxis.baseValue_"' />")
		Do XSL.WriteLine("    </xsl:call-template>")
		Do XSL.WriteLine("  </xsl:variable>")
		Do XSL.WriteLine("  <xsl:value-of select='$yBaseRaw - "_..plotTop_"' />")
		Do XSL.WriteLine("</xsl:variable>")
	}

	If chart.xAxis.baseValue="" {
		Do XSL.WriteLine("<xsl:variable name='"_$$$xBase_"' select='0' />")
	} Else {
		Do XSL.WriteLine("<xsl:variable name='"_$$$xBase_"'>")
		Do XSL.WriteLine("  <xsl:variable name='xBaseRaw'>")
		Do XSL.WriteLine("    <xsl:call-template name='zenReportGetPlotX"_$$$groupNum_"'>")
		Do chart.writeWithParamsNoBase(.XSL)
		Do XSL.WriteLine("      <xsl:with-param name='val' select='"_chart.xAxis.baseValue_"' />")
		Do XSL.WriteLine("    </xsl:call-template>")
		Do XSL.WriteLine("  </xsl:variable>")
		Do XSL.WriteLine("  <xsl:value-of select='$xBaseRaw - $plotLeft"_mode_"' />")
		Do XSL.WriteLine("</xsl:variable>")
	}
	
	Quit $$$OK
}

Method needsXDataMax(chart As chart) As %Boolean
{
	If ..xGridType = "value" && (chart.xAxis.maxValue="") Quit 1
	Quit 0
}

Method needsXDataMin(chart As chart) As %Boolean
{
	If ..xGridType = "value" && (chart.xAxis.minValue="") Quit 1
	Quit 0
}

Method needsYDataMax(chart As chart) As %Boolean
{
	If ..yGridType = "value" && (chart.yAxis.maxValue="") Quit 1
	Quit 0
}

Method needsYDataMin(chart As chart) As %Boolean
{
	If ..yGridType = "value" && (chart.yAxis.minValue="") Quit 1
	Quit 0
}

}
