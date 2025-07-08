/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.ReportUtil

/// Utility class that renders the various utility templates needed by a chart.
/// Note: utility templates of the form 'zenReport...' have a number added to
/// the template name to identify which chart they are a part of.
Class %ZEN.Report.Display.Chart.chartUtil Extends %RegisteredObject [ Deprecated, System = 4 ]
{

/// Entry method that renders all of the utility tempaltes provided by the other
/// methods in this clas.
ClassMethod renderUtils(context As %String, XSL As %GlobalCharacterStream, chart As chart, plot As plot)
{
	Do ##class(chartUtil).renderGetPlotX(.context, .XSL, chart, plot)
	Do ##class(chartUtil).renderGetPlotY(.context, .XSL, chart, plot)
	Do ##class(chartUtil).renderDrawMarker(.context, .XSL, chart)
	Do ##class(chartUtil).renderGetSeriesColor(.context, .XSL, chart)
	Do ##class(chartUtil).renderGetSeriesCount(.context, .XSL, chart)
	Do ##class(chartUtil).renderGetSeriesSize(.context, .XSL, chart)
	Do ##class(chartUtil).renderGetXLabelText(.context, .XSL, chart)
	Do ##class(chartUtil).renderGetYLabelText(.context, .XSL, chart)
	Do ##class(chartUtil).renderDrawXLabels(.context, .XSL, chart, plot)
	Do ##class(chartUtil).renderDrawYLabels(.context, .XSL, chart, plot)
	Do ##class(chartUtil).renderGridLinesTemplates(.context, .XSL, chart, plot)
	Do ##class(chartUtil).renderGetMaxMinValue(.context, .XSL, chart, plot)
	
	// add these utilities only once per report
	If '$d(context("hasChart")) {
		Set context("hasChart")=""
		
		Do ##class(chartUtil).renderFindScaleUnits(.XSL, chart)
		Do ##class(chartUtil).renderPower(.XSL, chart)
		
		// Templates below are from 
		// XSLT Cookbook, Second Edition by Sal Mangano.  
		// Copyright 2006 O'Reilly Media, Inc., 0-596-00974-7 
		Do ##class(chartUtil).renderMaxMin(.XSL, chart)
		Do ##class(chartUtil).renderLog(.XSL, chart)
	}
	
	Quit $$$OK
}

/// Renders the zenReportFindScaleUnits template which
/// finds the best scale units to use for given range.
ClassMethod renderFindScaleUnits(XSL As %GlobalCharacterStream, chart As chart)
{
	Do XSL.WriteLine("<xsl:template name='zenReportFindScaleUnits'>")
	Do XSL.WriteLine("  <xsl:param name='val' select='0'/>")
	Do XSL.WriteLine("  <xsl:choose><xsl:when test='$val &gt; 1'>")
	Do XSL.WriteLine("    <xsl:variable name='log'>")
	Do XSL.WriteLine("      <xsl:call-template name='util-log10'>")
	Do XSL.WriteLine("        <xsl:with-param name='number' select='$val' />")
	Do XSL.WriteLine("      </xsl:call-template>")
	Do XSL.WriteLine("    </xsl:variable>")
	Do XSL.WriteLine("    <xsl:variable name='f' select='floor($log)' />")
	Do XSL.WriteLine("    <xsl:choose><xsl:when test='($log - $f) &gt; 0.65' >")
	Do XSL.WriteLine("      <xsl:variable name='pow'>")
	Do XSL.WriteLine("        <xsl:call-template name='util-power'>")
	Do XSL.WriteLine("          <xsl:with-param name='base' select='10' />")
	Do XSL.WriteLine("          <xsl:with-param name='power' select='$f + 1' />")
	Do XSL.WriteLine("        </xsl:call-template>")
	Do XSL.WriteLine("      </xsl:variable>")
	Do XSL.WriteLine("      <xsl:value-of select='$pow div 5' />")
	Do XSL.WriteLine("    </xsl:when><xsl:otherwise>")
	Do XSL.WriteLine("      <xsl:variable name='pow'>")
	Do XSL.WriteLine("        <xsl:call-template name='util-power'>")
	Do XSL.WriteLine("          <xsl:with-param name='base' select='10' />")
	Do XSL.WriteLine("          <xsl:with-param name='power' select='$f' />")
	Do XSL.WriteLine("        </xsl:call-template>")
	Do XSL.WriteLine("      </xsl:variable>")
	Do XSL.WriteLine("      <xsl:value-of select='$pow div 2' />")
	Do XSL.WriteLine("    </xsl:otherwise></xsl:choose>")
	Do XSL.WriteLine("  </xsl:when><xsl:otherwise>")
	Do XSL.WriteLine("    <xsl:value-of select='1' />")
	Do XSL.WriteLine("  </xsl:otherwise></xsl:choose>")
	Do XSL.WriteLine("</xsl:template>")
}

/// Renders the 'util-power' template which raises 'base' to
/// the power 'power.'  Warning: very slow implementation.
ClassMethod renderPower(XSL As %GlobalCharacterStream, chart As chart)
{
	Do XSL.WriteLine("<xsl:template name='util-power'>")
	Do XSL.WriteLine("	<xsl:param name='base'/>")
	Do XSL.WriteLine("	<xsl:param name='power'/>")
	Do XSL.WriteLine("	<xsl:choose>")
	Do XSL.WriteLine("		<xsl:when test='$power &lt;= 0'>")
	Do XSL.WriteLine("			<xsl:value-of select='1'/>")
	Do XSL.WriteLine("		</xsl:when>")
	Do XSL.WriteLine("		<xsl:otherwise>")
	Do XSL.WriteLine("			<xsl:variable name='temp'>")
	Do XSL.WriteLine("				<xsl:call-template name='util-power'>")
	Do XSL.WriteLine("					<xsl:with-param name='base' select='$base'/>")
	Do XSL.WriteLine("					<xsl:with-param name='power' select='$power - 1'/>")
	Do XSL.WriteLine("				</xsl:call-template>")
	Do XSL.WriteLine("			</xsl:variable>")
	Do XSL.WriteLine("			<xsl:value-of select='$base * $temp'/>")
	Do XSL.WriteLine("		</xsl:otherwise>")
	Do XSL.WriteLine("	</xsl:choose>")
	Do XSL.WriteLine("</xsl:template>")
}

/// Renders the 'zenReportGetPlotX' template.  This template takes 'val'
/// as a parameter, and returns the x coordinate within the chart.
ClassMethod renderGetPlotX(context As %String, XSL As %GlobalCharacterStream, chart As chart, plot As plot)
{
	Do XSL.WriteLine("<xsl:template name='zenReportGetPlotX"_$$$groupNum_"'>")
	Do chart.writeLoadParamsNoBase(.XSL)
	Do XSL.WriteLine("  <xsl:param name='val'/>")
	Do XSL.WriteLine("  <xsl:variable name='pct'>")
	Do XSL.WriteLine("    <xsl:choose><xsl:when test='$"_$$$xRange_" = 0'>")
	Do XSL.WriteLine("      0")
	Do XSL.WriteLine("    </xsl:when><xsl:otherwise>")
	Do XSL.WriteLine("      <xsl:value-of select='($val - $"_$$$xMin_") div $"_$$$xRange_"' />")
	Do XSL.WriteLine("    </xsl:otherwise></xsl:choose>")
	Do XSL.WriteLine("  </xsl:variable>") 
	Set mode = "legend"_$$$groupNum
	Do XSL.WriteLine("  <xsl:value-of select='$plotLeft"_mode_" + ($pct * $plotWidth"_mode_")'/>")
	Do XSL.WriteLine("</xsl:template>")
}

/// Renders the 'zenReportGetPlotY' template.  This template takes 'val'
/// as a parameter, and returns the y coordinate within the chart.
ClassMethod renderGetPlotY(context As %String, XSL As %GlobalCharacterStream, chart As chart, plot As plot)
{
		// Parameters: val, yRange, yMinValue
	Do XSL.WriteLine("<xsl:template name='zenReportGetPlotY"_$$$groupNum_"'>")
	Do chart.writeLoadParamsNoBase(.XSL)
	Do XSL.WriteLine("  <xsl:param name='val'/>")
	Do XSL.WriteLine("  <xsl:variable name='pct'>")
	Do XSL.WriteLine("    <xsl:choose><xsl:when test='$"_$$$yRange_" = 0'>")
	Do XSL.WriteLine("      0")
	Do XSL.WriteLine("    </xsl:when><xsl:otherwise>")
	Do XSL.WriteLine("      <xsl:value-of select='($val - $"_$$$yMin_") div $"_$$$yRange_"' />")
	Do XSL.WriteLine("    </xsl:otherwise></xsl:choose>")
	Do XSL.WriteLine("  </xsl:variable>") 
	Do XSL.WriteLine("  <xsl:value-of select='"_plot.plotBottom_" - ($pct * "_plot.plotHeight_")'/>")
	Do XSL.WriteLine("</xsl:template>")
}

/// Renders the 'util-min' and 'util-max' templates, which both take
/// a 'nodes' parameter and return the maximum value across the nodes.
ClassMethod renderMaxMin(XSL As %GlobalCharacterStream, chart As chart)
{
	// There are EXSLT functions which do the same thing, but they are
	// re-implemented here for compatability.  I originally used a faster
	// divide-and-conquer style algorithm, but FOP was running into
	// framestack issues so we do it the old-fashioned way.  The moral of
	// the story is that if there is a lot of data, the range values
	// on the value axis should be calculated in an aggregate in the data
	// and referenced using !count style maxValue/minValue attributes.
	
	Do XSL.WriteLine("<xsl:template name='util-min'>")
	Do XSL.WriteLine("   <xsl:param name='nodes' select='/chart.' />")
	Do XSL.WriteLine("   <xsl:choose>")
	Do XSL.WriteLine("      <xsl:when test='count($nodes)=0'>NaN</xsl:when>")
	Do XSL.WriteLine("      <xsl:otherwise>")
	Do XSL.WriteLine("         <xsl:for-each select='$nodes'>")
	Do XSL.WriteLine("            <xsl:sort data-type='number' />")
	Do XSL.WriteLine("            <xsl:if test='position() = 1'>")
	Do XSL.WriteLine("               <xsl:value-of select='number(.)' />")
	Do XSL.WriteLine("            </xsl:if>")
	Do XSL.WriteLine("         </xsl:for-each>")
	Do XSL.WriteLine("      </xsl:otherwise>")
	Do XSL.WriteLine("   </xsl:choose>")
	Do XSL.WriteLine("</xsl:template>")
	
	Do XSL.WriteLine("<xsl:template name='util-max'>")
	Do XSL.WriteLine("   <xsl:param name='nodes' select='/chart.' />")
	Do XSL.WriteLine("   <xsl:choose>")
	Do XSL.WriteLine("      <xsl:when test='count($nodes)=0'>NaN</xsl:when>")
	Do XSL.WriteLine("      <xsl:otherwise>")
	Do XSL.WriteLine("         <xsl:for-each select='$nodes'>")
	Do XSL.WriteLine("            <xsl:sort data-type='number' />")
	Do XSL.WriteLine("            <xsl:if test='position() = last()'>")
	Do XSL.WriteLine("               <xsl:value-of select='number(.)' />")
	Do XSL.WriteLine("            </xsl:if>")
	Do XSL.WriteLine("         </xsl:for-each>")
	Do XSL.WriteLine("      </xsl:otherwise>")
	Do XSL.WriteLine("   </xsl:choose>")
	Do XSL.WriteLine("</xsl:template>")
}

/// Renders the 'util-log10' (log base 10) and 'util-log' (natural log) templates,
/// both of which take a 'number' parameter.
ClassMethod renderLog(ByRef XSL As %GlobalCharacterStream, chart As chart)
{
	Do XSL.WriteLine("<!-- Computes log10 (base 10) of number-->")
	Do XSL.WriteLine("<xsl:template name='util-log10'>")
	Do XSL.WriteLine("	<xsl:param name='number' select='1'/>")
	Do XSL.WriteLine("	<xsl:param name='n' select='0'/> <!-- book keeping for whole part of result -->")
	
	Do XSL.WriteLine("	<xsl:choose>")
	Do XSL.WriteLine("		<xsl:when test='$number &lt;= 0'> <!-- Logarithms are undefined for 0 and negative numbers -->")
	Do XSL.WriteLine("			<xsl:value-of select='NaN'/>")
	Do XSL.WriteLine("		</xsl:when>")
	Do XSL.WriteLine("		<xsl:when test='$number &lt; 1'>  <!-- Fractional numbers have negative logs -->")
	Do XSL.WriteLine("			<xsl:call-template name='util-log10'>")
	Do XSL.WriteLine("				<xsl:with-param name='number' select='$number * 10'/>")
	Do XSL.WriteLine("				<xsl:with-param name='n' select='$n - 1'/>")
	Do XSL.WriteLine("			</xsl:call-template>")
	Do XSL.WriteLine("		</xsl:when>")
	Do XSL.WriteLine("		<xsl:when test='$number > 10'> <!-- Numbers greater than 10 have logs greater than 1 -->")
	Do XSL.WriteLine("			<xsl:call-template name='util-log10'>")
	Do XSL.WriteLine("				<xsl:with-param name='number' select='$number div 10'/>")
	Do XSL.WriteLine("				<xsl:with-param name='n' select='$n + 1'/>")
	Do XSL.WriteLine("			</xsl:call-template>")
	Do XSL.WriteLine("		</xsl:when>")
	Do XSL.WriteLine("		<xsl:when test='$number = 10'> ")
	Do XSL.WriteLine("			<xsl:value-of select='$n + 1'/>")
	Do XSL.WriteLine("		</xsl:when>")
	Do XSL.WriteLine("		<xsl:otherwise>		<!-- We only need to know how to compute for numbers in range [1,10) -->")
	Do XSL.WriteLine("			<xsl:call-template name='util-log10-util'>")
	Do XSL.WriteLine("				<xsl:with-param name='number' select='$number'/>")
	Do XSL.WriteLine("				<xsl:with-param name='n' select='$n'/>")
	Do XSL.WriteLine("			</xsl:call-template>")
	Do XSL.WriteLine("		</xsl:otherwise>")
	Do XSL.WriteLine("	</xsl:choose>")
	
	Do XSL.WriteLine("</xsl:template>")
	Do XSL.WriteLine("<!-- Computes log (natural) of number-->")
	Do XSL.WriteLine("<xsl:template name='util-log'>")
	Do XSL.WriteLine("	<xsl:param name='number' select='1'/>")
	Do XSL.WriteLine("	<xsl:variable name='log10-e' select='0.4342944819'/>")
	Do XSL.WriteLine("	<xsl:variable name='log10'>")
	Do XSL.WriteLine("		<xsl:call-template name='util-log10'>")
	Do XSL.WriteLine("			<xsl:with-param name='number' select='$number'/>")
	Do XSL.WriteLine("		</xsl:call-template>")
	Do XSL.WriteLine("	</xsl:variable>")
	Do XSL.WriteLine("	<xsl:value-of select='$log10 div $log10-e'/>")
	Do XSL.WriteLine("</xsl:template>")
	Do XSL.WriteLine("<!-- Computes log to base b of number-->")
	Do XSL.WriteLine("<xsl:template name='util-log-b'>")
	Do XSL.WriteLine("	<xsl:param name='number' select='1'/>")
	Do XSL.WriteLine("	<xsl:param name='base' select='2'/>")
	Do XSL.WriteLine("	<xsl:variable name='log10-base'>")
	Do XSL.WriteLine("		<xsl:call-template name='util-log10'>")
	Do XSL.WriteLine("			<xsl:with-param name='number' select='$base'/>")
	Do XSL.WriteLine("		</xsl:call-template>")
	Do XSL.WriteLine("	</xsl:variable>")
	Do XSL.WriteLine("	<xsl:variable name='log10'>")
	Do XSL.WriteLine("		<xsl:call-template name='util-log10'>")
	Do XSL.WriteLine("			<xsl:with-param name='number' select='$number'/>")
	Do XSL.WriteLine("		</xsl:call-template>")
	Do XSL.WriteLine("	</xsl:variable>")
	Do XSL.WriteLine("	<xsl:value-of select='$log10 div $log10-base'/>")
	Do XSL.WriteLine("</xsl:template>")
	Do XSL.WriteLine("<!-- Computes log10 of numbers in the range [1,10) and returns the result + n-->")
	Do XSL.WriteLine("<xsl:template name='util-log10-util'>")
	Do XSL.WriteLine("	<xsl:param name='number'/>")
	
	Do XSL.WriteLine("	<xsl:param name='n'/>")
	
	Do XSL.WriteLine("	<xsl:param name='frac' select='0'/> <!-- book keeping variable for fractional part -->")
	Do XSL.WriteLine("	<xsl:param name='k' select='0'/>      <!-- iteration counter -->")
	Do XSL.WriteLine("	<xsl:param name='divisor' select='2'/> <!-- successive powers of 2 used to build up frac -->")
	Do XSL.WriteLine("	<xsl:param name='maxiter' select='38'/> <!-- Number of iterations. 38 is more than sufficient to get at least 10 dec place prec -->")
	Do XSL.WriteLine("	<xsl:variable name='x' select='$number * $number'/>")
	
	Do XSL.WriteLine("	<xsl:choose>")
	Do XSL.WriteLine("		<xsl:when test='$k >= $maxiter'>")
	Do XSL.WriteLine("			<!-- Round to 10 decimal places -->")
	Do XSL.WriteLine("			<xsl:value-of select='$n + round($frac * 10000000000) div 10000000000'/> ")
	Do XSL.WriteLine("		</xsl:when>")
	Do XSL.WriteLine("		<xsl:when test='$x &lt; 10'>")
	Do XSL.WriteLine("			<xsl:call-template name='util-log10-util'>")
	Do XSL.WriteLine("				<xsl:with-param name='number' select='$x'/>")
	Do XSL.WriteLine("				<xsl:with-param name='n' select='$n'/>")
	Do XSL.WriteLine("				<xsl:with-param name='k' select='$k + 1'/>")
	Do XSL.WriteLine("				<xsl:with-param name='divisor' select='$divisor * 2'/>")
	Do XSL.WriteLine("				<xsl:with-param name='frac' select='$frac'/>")
	Do XSL.WriteLine("				<xsl:with-param name='maxiter' select='$maxiter'/>")
	Do XSL.WriteLine("			</xsl:call-template>")
	Do XSL.WriteLine("		</xsl:when>")
	Do XSL.WriteLine("		<xsl:otherwise>")
	Do XSL.WriteLine("			<xsl:call-template name='util-log10-util'>")
	Do XSL.WriteLine("				<xsl:with-param name='number' select='$x div 10'/>")
	Do XSL.WriteLine("				<xsl:with-param name='n' select='$n'/>")
	Do XSL.WriteLine("				<xsl:with-param name='k' select='$k + 1'/>")
	Do XSL.WriteLine("				<xsl:with-param name='divisor' select='$divisor * 2'/>")
	Do XSL.WriteLine("				<xsl:with-param name='frac' select='$frac + (1 div $divisor)'/>")
	Do XSL.WriteLine("				<xsl:with-param name='maxiter' select='$maxiter'/>")
	Do XSL.WriteLine("			</xsl:call-template>")
	Do XSL.WriteLine("		</xsl:otherwise>")
	Do XSL.WriteLine("	</xsl:choose>")
	Do XSL.WriteLine("</xsl:template>")
}

/// Renders the 'zenReportGetSeriesColor' template which takes a 'series'
/// parameter.  Color is determined by choosing the corresponding item
/// in the list seriesColors.  Color selection wraps around when the
/// seriesColors list is exhausted.
ClassMethod renderGetSeriesColor(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, chart As chart, cc As %String = "")
{
	Do XSL.WriteLine("<xsl:template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
	Do XSL.WriteLine("  <xsl:param name='series' select='0' />")
	Do XSL.WriteLine("  <xsl:choose>")
	If cc="" Set cc=chart.getColorCount()
	For i=0:1:cc-1 {
		Do XSL.Write("    <xsl:when test='$series mod "_cc_" = "_i_"'>")
		Set color=chart.getSeriesColor(i)
		Set color=$zstrip(color,"<>W")
		if $e(color)'="!" {
			Do XSL.Write(color)
		} else {
			Do XSL.WriteLine("<xsl:value-of select='"_$e(color,2,$L(color))_"'/>")
		}
		Do XSL.WriteLine("</xsl:when>")
	}
	Do XSL.WriteLine("  </xsl:choose>")
	Do XSL.WriteLine("</xsl:template>")
	
	Quit $$$OK
}

/// Renders the 'zenReportGetXLabelText' template, which takes an 'item'
/// parameter and returns the appropriate label text.
ClassMethod renderGetXLabelText(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, chart As chart)
{
	Do XSL.WriteLine("<xsl:template name='zenReportGetXLabelText"_$$$groupNum_"'>")
	Do XSL.WriteLine("  <xsl:param name='item' select='1' />")
	If chart.xAxis.labelGroup'="" {
		Do XSL.WriteLine("  <xsl:for-each select='("_chart.xAxis.labelGroup_")[$item]' >")
		Do XSL.WriteLine("      <xsl:value-of select='"_chart.xAxis.labelValue_"' />")
		Do XSL.WriteLine("  </xsl:for-each>")
	} else {
		If chart.xAxis.labelValues="" {
			Do XSL.WriteLine("  <xsl:value-of select='$item' />")
		} Else {
			Do XSL.WriteLine("  <xsl:choose>")
			For i=1:1:$l(chart.xAxis.labelValues,",") {
				Do XSL.WriteLine("    <xsl:when test='$item = "_i_"'>")
				Set label=$p(chart.xAxis.labelValues,",",i)
				Set label=$zstrip(label,"<>W")
				If $e(label)="!" {
					Set label=$e(label,2,$l(label))
					Do XSL.WriteLine("      <xsl:value-of select='"_label_"' />")
				} Else {
					Do XSL.WriteLine("      "_label)
				}
				Do XSL.WriteLine("    </xsl:when>")
			}
			Do XSL.WriteLine("    <xsl:otherwise>")
			if (chart.xAxis.labelValues="")||(chart.xAxis.labelValues=$c(0)) Do XSL.WriteLine("      <xsl:value-of select='$item' />")
			Do XSL.WriteLine("    </xsl:otherwise>")
			Do XSL.WriteLine("  </xsl:choose>")
		}
	}
	Do XSL.WriteLine("</xsl:template>")
}

/// Renders the 'zenReportGetYLabelText' template, which takes an 'item'
/// parameter and returns the appropriate label text.
ClassMethod renderGetYLabelText(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, chart As chart)
{
	Do XSL.WriteLine("<xsl:template name='zenReportGetYLabelText"_$$$groupNum_"'>")
	Do XSL.WriteLine("  <xsl:param name='item' select='1' />")
	If chart.yAxis.labelGroup'="" {
		Do XSL.WriteLine("  <xsl:for-each select='"_chart.yAxis.labelGroup_"[$item]' >")
		Do XSL.WriteLine("      <xsl:value-of select='"_chart.yAxis.labelValue_"' />")
		Do XSL.WriteLine("  </xsl:for-each>")
	} else {
		If chart.yAxis.labelValues="" {
			Do XSL.WriteLine("  <xsl:value-of select='$item' />")
		} Else {
			Do XSL.WriteLine("  <xsl:choose>")
			For i=1:1:$l(chart.yAxis.labelValues,",") {
				Do XSL.WriteLine("    <xsl:when test='$item = "_i_"'>")
				Set label=$p(chart.yAxis.labelValues,",",i)
				Set label=$zstrip(label,"<>W")
				If $e(label)="!" {
					Set label=$e(label,2,$l(label))
					Do XSL.WriteLine("      <xsl:value-of select='"_label_"' />")
				} Else {
					Do XSL.WriteLine("      "_label)
				}
				Do XSL.WriteLine("    </xsl:when>")
			}
			Do XSL.WriteLine("    <xsl:otherwise>")
			Do XSL.WriteLine("      <xsl:value-of select='$item' />")
			Do XSL.WriteLine("    </xsl:otherwise>")
			Do XSL.WriteLine("  </xsl:choose>")
		}
	}
	Do XSL.WriteLine("</xsl:template>")
}

/// Renders the 'zenReportDrawMarker' template, which creates a plot marker.
/// This template takes 'shape', 'color', 'x', and 'y' parameters.
/// Shape can be 'up','down','circle','square'.
ClassMethod renderDrawMarker(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, chart As chart)
{
	Do XSL.WriteLine("<xsl:template name='zenReportDrawMarker"_$$$groupNum_"'>")
	Do XSL.WriteLine("  <xsl:param name='shape' select=""'circle'"" />")
	Do XSL.WriteLine("  <xsl:param name='color' select=""'black'"" />")
	Do XSL.WriteLine("  <xsl:param name='x' select='0' />")
	Do XSL.WriteLine("  <xsl:param name='y' select='0' />")
	Do XSL.WriteLine("  <xsl:choose>")
	Do XSL.WriteLine("    <xsl:when test=""$shape = 'square'"">") 
	Do XSL.WriteLine("      <"_..SvgPrefix()_"rect x='-0.75' y='-0.75' width='1.5' height='1.5'>")
	Do XSL.WriteLine("        <xsl:call-template name='zenReportMarkerAttributes"_$$$groupNum_"'>")
	Do XSL.WriteLine("          <xsl:with-param name='color' select='$color' />")
	Do XSL.WriteLine("          <xsl:with-param name='x' select='$x' />")
	Do XSL.WriteLine("          <xsl:with-param name='y' select='$y' />")
	Do XSL.WriteLine("        </xsl:call-template>")
	Do XSL.WriteLine("      </"_..SvgPrefix()_"rect>")
	Do XSL.WriteLine("    </xsl:when><xsl:when test=""$shape = 'circle'"">")
	Do XSL.WriteLine("      <"_..SvgPrefix()_"circle cx='0' cy='0' r='0.75'>")
	Do XSL.WriteLine("        <xsl:call-template name='zenReportMarkerAttributes"_$$$groupNum_"'>")
	Do XSL.WriteLine("          <xsl:with-param name='color' select='$color' />")
	Do XSL.WriteLine("          <xsl:with-param name='x' select='$x' />")
	Do XSL.WriteLine("          <xsl:with-param name='y' select='$y' />")
	Do XSL.WriteLine("        </xsl:call-template>")
	Do XSL.WriteLine("      </"_..SvgPrefix()_"circle>")
	Do XSL.WriteLine("    </xsl:when><xsl:when test=""$shape = 'down'"">")
	Do XSL.WriteLine("      <"_..SvgPrefix()_"polyline points='-1,-1 1,-1 0,1 -1,-1'>")
	Do XSL.WriteLine("        <xsl:call-template name='zenReportMarkerAttributes"_$$$groupNum_"'>")
	Do XSL.WriteLine("          <xsl:with-param name='color' select='$color' />")
	Do XSL.WriteLine("          <xsl:with-param name='x' select='$x' />")
	Do XSL.WriteLine("          <xsl:with-param name='y' select='$y' />")
	Do XSL.WriteLine("        </xsl:call-template>")	
	Do XSL.WriteLine("      </"_..SvgPrefix()_"polyline>")
	Do XSL.WriteLine("    </xsl:when><xsl:when test=""$shape = 'up'"">")
	Do XSL.WriteLine("      <"_..SvgPrefix()_"polyline points='-1,1 1,1 0,-1 -1,1'>")
	Do XSL.WriteLine("        <xsl:call-template name='zenReportMarkerAttributes"_$$$groupNum_"'>")
	Do XSL.WriteLine("          <xsl:with-param name='color' select='$color' />")
	Do XSL.WriteLine("          <xsl:with-param name='x' select='$x' />")
	Do XSL.WriteLine("          <xsl:with-param name='y' select='$y' />")
	Do XSL.WriteLine("        </xsl:call-template>")	
	Do XSL.WriteLine("      </"_..SvgPrefix()_"polyline>")
	Do XSL.WriteLine("    </xsl:when>")
	Do XSL.WriteLine("  </xsl:choose>")
	Do XSL.WriteLine("</xsl:template>")
	
	Set scale=""
	If chart.markerScale'="" Set scale="scale("_chart.markerScale_","_chart.markerScale_")"		
	
	Do XSL.WriteLine("<xsl:template name='zenReportMarkerAttributes"_$$$groupNum_"'>")
	Do XSL.WriteLine("  <xsl:param name='color' select=""'black'"" />")
	Do XSL.WriteLine("  <xsl:param name='x' select='0' />")
	Do XSL.WriteLine("  <xsl:param name='y' select='0' />")
	s key="" for  s key=$o(context("SVGATTRS","chart-seriesLine",key)) q:key=""  d
	. Do XSL.WriteLine("  <xsl:attribute name='"_key_"'>"_context("SVGATTRS","chart-seriesLine",key)_"</xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='class'>chart-seriesLine</xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='transform'>")
	Do XSL.WriteLine("    <xsl:variable name='x1'>")
	Do XSL.WriteLine("      <xsl:choose>")
	Do XSL.WriteLine("         <xsl:when test='not($x)'>0</xsl:when>")
	Do XSL.WriteLine("         <xsl:otherwise>")
	Do XSL.WriteLine("           <xsl:value-of select='$x'/>")
	Do XSL.WriteLine("         </xsl:otherwise>")
	Do XSL.WriteLine("      </xsl:choose>")
	Do XSL.WriteLine("    </xsl:variable>")
	Do XSL.WriteLine("    <xsl:value-of select='concat(&quot;translate(&quot;,$x1, &quot;,&quot;, $y,&quot;)&quot;,&quot;"_scale_"&quot;)' />")
	Do XSL.WriteLine("  </xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='stroke'><xsl:value-of select='$color' /></xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='fill'>white</xsl:attribute>")
	Do XSL.WriteLine("  <xsl:attribute name='fill-opacity'>1.0</xsl:attribute>")
	if chart.markerStyle'="" Do XSL.WriteLine("  <xsl:attribute name='style'>"_chart.markerStyle_"</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,chart.markerStyle)
	Do XSL.WriteLine("</xsl:template>")

	Do XSL.WriteLine("<xsl:template name='zenReportGetSeriesMarker"_$$$groupNum_"'>")
	Do XSL.WriteLine("  <xsl:param name='series' select='0' />")
	Do XSL.WriteLine("  <xsl:choose>")
	Set cc=$L(chart.markerShapes,",")
	For i=1:1:cc {
		Do XSL.Write("    <xsl:when test='$series mod "_cc_" = "_(i-1)_"'>")
		Do XSL.Write($P(chart.markerShapes,",",i))
		Do XSL.WriteLine("</xsl:when>")
	}
	Do XSL.WriteLine("  </xsl:choose>")
	Do XSL.WriteLine("</xsl:template>")

	
	Quit $$$OK
}

ClassMethod renderDrawLowMarker(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, chart As chart, pivot)
{
	Set points="0,1 0,-1 1,0 0,1"
	Do XSL.WriteLine("<xsl:template name='zenReportDrawLowMarker"_$$$groupNum_"'>")
	Do XSL.WriteLine("  <xsl:param name='shape' select=""'circle'"" />")
	Do XSL.WriteLine("  <xsl:param name='color' select=""'black'"" />")
	Do XSL.WriteLine("  <xsl:param name='x' select='0' />")
	Do XSL.WriteLine("  <xsl:param name='y' select='0' />")
	if pivot 
	{
		Do XSL.WriteLine("      <"_..SvgPrefix()_"polyline points='-1,0 1,0 0,1 -1,0'>")
	} else {
		Do XSL.WriteLine("      <"_..SvgPrefix()_"polyline points='0,1 0,-1 1,0 0,1'>")
	}
	Do XSL.WriteLine("        <xsl:call-template name='zenReportMarkerAttributes"_$$$groupNum_"'>")
	Do XSL.WriteLine("          <xsl:with-param name='color' select='$color' />")
	Do XSL.WriteLine("          <xsl:with-param name='x' select='$x' />")
	Do XSL.WriteLine("          <xsl:with-param name='y' select='$y' />")
	Do XSL.WriteLine("        </xsl:call-template>")	
	Do XSL.WriteLine("      </"_..SvgPrefix()_"polyline>")
	Do XSL.WriteLine("</xsl:template>")
}

/// Renders the 'zenReportGetSeriesCount' template which returns the number of series.
/// Within a template, it is more efficient to use the $seriescount global variable
/// than re-invoke this template.
ClassMethod renderGetSeriesCount(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, chart As chart)
{
	Do XSL.WriteLine("<xsl:template name='zenReportGetSeriesCount"_$$$groupNum_"'>")
	Set chart.seriesCount=$zstrip(chart.seriesCount,"<>W")
	If $e(chart.seriesCount)="!" {
		Do XSL.WriteLine("<xsl:value-of select='"_$e(chart.seriesCount,2,$l(chart.seriesCount))_"' />")
	} ElseIf chart.seriesCount'="" {
		Do XSL.WriteLine("<xsl:value-of select='"_chart.seriesCount_"'/>")
	} ElseIf chart.seriesGroup'="" {
		Do XSL.WriteLine("<xsl:value-of select='count("_..qualify(chart.seriesGroup,.context)_")' />")
	} ElseIf chart.dataGroup'="",chart.%Extends("%ZEN.Report.Display.Chart.lineChart")||chart.%Extends("%ZEN.Report.Display.Chart.barChart") {		
		Do XSL.WriteLine("<xsl:value-of select='"_$l(chart.dataFields,",")_"' />")
	} Else {
		Do XSL.WriteLine("<xsl:value-of select='"_$l(chart.seriesNames,",")_"' />")
	}
	Do XSL.WriteLine("</xsl:template>")
}

/// Renders the 'zenReportGetSeriesSize' template which returns the number of series.
/// Within a template, it is more efficient to use the $seriessize global variable
/// than re-invoke this template.
ClassMethod renderGetSeriesSize(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, chart As chart)
{
	Do XSL.WriteLine("<xsl:template name='zenReportGetSeriesSize"_$$$groupNum_"'>")
	Set chart.seriesSize=$zstrip(chart.seriesSize,"<>W")
	If $e(chart.seriesSize)="!" {
		Do XSL.WriteLine("<xsl:value-of select='"_$e(chart.seriesSize,2,$l(chart.seriesSize))_"' />")
	} ElseIf chart.seriesSize'="" {
		Do XSL.WriteLine("<xsl:value-of select='"_chart.seriesSize_"' />")
	} ElseIf chart.dataGroup="" {
		if chart.%Extends("%ZEN.Report.Display.Chart.hilowChart") {
			Do XSL.WriteLine("<xsl:value-of select='count("_chart.seriesGroup_")' />")
		} else {
			Do XSL.WriteLine("<xsl:value-of select='"_$l(chart.dataFields,",")_"' />")
		}
	} ElseIf chart.seriesGroup="" {
		; 02-25-2011 reason why data counted twice Prodlog 86265		
		Do XSL.WriteLine("<xsl:value-of select='count("_..qualify("descendant::"_chart.dataGroup,.context)_")' />")
		;Do XSL.WriteLine("<xsl:value-of select='count("_..qualify(chart.xpath_"/"_chart.dataGroup,.context)_")' />")
		
	} Else {
		Set path=..qualify(""_chart.seriesGroup_"[$i]/"_chart.dataGroup)
		Do XSL.WriteLine("  <xsl:param name='i' select='1' />")
		Do XSL.WriteLine("  <xsl:param name='ss' select='0' />")
		Do XSL.WriteLine("  <xsl:param name='seriescount' />")
		Do XSL.WriteLine("  <xsl:choose><xsl:when test='$i &gt; $seriescount'>")
		Do XSL.WriteLine("    <xsl:value-of select='$ss' />")
		Do XSL.WriteLine("  </xsl:when><xsl:otherwise>")
		Do XSL.WriteLine("    <xsl:variable name='thisseriessize' select='count("_..qualify(path,.context)_")'/>")
		Do XSL.WriteLine("    <xsl:variable name='newmax'>")
		Do XSL.WriteLine("      <xsl:choose><xsl:when test='$thisseriessize &gt; $ss'>")
		Do XSL.WriteLine("        <xsl:value-of select='$thisseriessize'/>")
		Do XSL.WriteLine("      </xsl:when><xsl:otherwise>")
		Do XSL.WriteLine("        <xsl:value-of select='$ss'/>")
		Do XSL.WriteLine("      </xsl:otherwise></xsl:choose>")
		Do XSL.WriteLine("    </xsl:variable>")
		Do XSL.WriteLine("    <xsl:call-template name='zenReportGetSeriesSize"_$$$groupNum_"'>")
		Do XSL.WriteLine("      <xsl:with-param name='i' select='$i + 1' />")
		Do XSL.WriteLine("      <xsl:with-param name='ss' select='$newmax' />")
		Do XSL.WriteLine("      <xsl:with-param name='seriescount' select='$seriescount' />")
		Do XSL.WriteLine("    </xsl:call-template>")
		Do XSL.WriteLine("  </xsl:otherwise></xsl:choose>")
	}
	Do XSL.WriteLine("</xsl:template>")
}

/// Renders the 'zenReportXValueLabels' and 'zenReportXCategoryLabels' templates.
/// These loop over the data and display the appropriate labels.
ClassMethod renderDrawXLabels(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, chart As chart, plot As plot)
{
	Do XSL.WriteLine("<xsl:template name='zenReportXValueLabels"_$$$groupNum_"'>")
	Do chart.writeLoadParams(.XSL)
	Set mode = "legend"_$$$groupNum
	Do XSL.WriteLine("  <xsl:param name='oldx' select='$plotLeft"_mode_"' />")
		Do XSL.WriteLine("  <xsl:param name='dx' />")
	Do XSL.WriteLine("  <xsl:param name='adj' />")

		
	Do XSL.WriteLine("  <xsl:param name='count' select='0'/>")
	Do XSL.WriteLine("  <xsl:param name='start' />")
	Do XSL.WriteLine("  <xsl:param name='end' />")
	Do XSL.WriteLine("  <xsl:param name='unit' />")
	Do XSL.WriteLine("    <xsl:variable name='x' select='$oldx + $dx' />")
		
	Do XSL.WriteLine("  <xsl:if test='($start &lt;= $end) and ($count &lt; 200)'>")
	Do XSL.WriteLine("    <"_..SvgPrefix()_"text class='chart-xLabel'>")
	s tAtt=""
	if chart.labelStyle'="" s tAtt=chart.labelStyle_";"
	if chart.xAxis.labelStyle'="" s tAtt=tAtt_chart.xAxis.labelStyle_";"
	if tAtt'="" Do XSL.WriteLine("      <xsl:attribute name='style'>"_tAtt_"</xsl:attribute>")
	s key="" for  s key=$o(context("SVGATTRS","chart-xLabel",key)) q:key=""  d
	. Do XSL.WriteLine("  <xsl:attribute name='"_key_"'>"_context("SVGATTRS","chart-xLabel",key)_"</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,tAtt)
	Do XSL.WriteLine("      <xsl:attribute name='text-anchor'>"_chart.xAxis.textAnchor_"</xsl:attribute>")
	Do XSL.WriteLine("      <xsl:attribute name='y'>"_(plot.plotBottom + chart.xAxis.labelDisplacement + 4)_"</xsl:attribute>")
	Do XSL.WriteLine("      <xsl:attribute name='x'>")
	Do XSL.WriteLine("        <xsl:call-template name='zenReportGetPlotX"_$$$groupNum_"'>")
	Do chart.writeWithParamsNoBase(.XSL)
	Do XSL.WriteLine("          <xsl:with-param name='val' select='$start' />")
	Do XSL.WriteLine("        </xsl:call-template>")
	Do XSL.WriteLine("      </xsl:attribute>")
	If chart.xAxis.labelAngle {
		Do XSL.WriteLine("      <xsl:attribute name='transform'><xsl:value-of select='concat(""rotate("_chart.xAxis.labelAngle_","",$x - $adj,"","_(plot.plotBottom+chart.xAxis.labelDisplacement+4)_")"")' /></xsl:attribute>")
	}
	Do XSL.WriteLine("      <xsl:call-template name='zenReportGetXLabelText"_$$$groupNum_"'>")
	Do XSL.WriteLine("        <xsl:with-param name='item' select='$start' />")
	Do XSL.WriteLine("      </xsl:call-template>")
	Do XSL.WriteLine("    </"_..SvgPrefix()_"text>")
	Do XSL.WriteLine("    <xsl:call-template name='zenReportXValueLabels"_$$$groupNum_"'>")
	Do chart.writeWithParams(.XSL)
	Do XSL.WriteLine("      <xsl:with-param name='start' select='$start + $unit' />")
	Do XSL.WriteLine("      <xsl:with-param name='end' select='$end' />")
	Do XSL.WriteLine("      <xsl:with-param name='count' select='$count + 1' />")
	Do XSL.WriteLine("      <xsl:with-param name='unit' select='$unit' />")
	Do XSL.WriteLine("    </xsl:call-template>")
	Do XSL.WriteLine("  </xsl:if>")
	Do XSL.WriteLine("</xsl:template>")
	
	Do XSL.WriteLine("<xsl:template name='zenReportXCategoryLabels"_$$$groupNum_"'>")
	Do chart.writeLoadParams(.XSL)
	Set mode = "legend"_$$$groupNum
	Do XSL.WriteLine("  <xsl:param name='oldx' select='$plotLeft"_mode_"' />")
	Do XSL.WriteLine("  <xsl:param name='n' select='0' />")
	Do XSL.WriteLine("  <xsl:param name='dx' />")
	Do XSL.WriteLine("  <xsl:param name='adj' />")
	Do XSL.WriteLine("  <xsl:param name='items' />")
	Do XSL.WriteLine("  <xsl:if test='$n &lt;= $items'>")
	Do XSL.WriteLine("    <xsl:variable name='x' select='$oldx + $dx' />")
	Do XSL.WriteLine("    <xsl:if test='$n mod $"_$$$xLabelUnits_" = 0'>")
	Do XSL.WriteLine("      <"_..SvgPrefix()_"text class='chart-xLabel'>")
	s tAtt=""
	if chart.labelStyle'="" s tAtt=chart.labelStyle_";"
	if tAtt'="" Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,tAtt)	
	if tAtt'="" Do XSL.WriteLine("        <xsl:attribute name='style'>"_tAtt_"</xsl:attribute>")
	if chart.xAxis.labelStyle'="" s tAtt=tAtt_chart.xAxis.labelStyle_";"
	if tAtt'="" Do XSL.WriteLine("        <xsl:attribute name='style'>"_tAtt_"</xsl:attribute>")
	s key="" for  s key=$o(context("SVGATTRS","chart-xLabel",key)) q:key=""  d
	. Do XSL.WriteLine("  <xsl:attribute name='"_key_"'>"_context("SVGATTRS","chart-xLabel",key)_"</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,tAtt)		
	Do XSL.WriteLine("        <xsl:attribute name='text-anchor'>"_chart.xAxis.textAnchor_"</xsl:attribute>")
	Do XSL.WriteLine("        <xsl:attribute name='x'><xsl:value-of select='$x - $adj' /></xsl:attribute>")
	Do XSL.WriteLine("        <xsl:attribute name='y'>"_(plot.plotBottom+chart.xAxis.labelDisplacement + 4)_"</xsl:attribute>")
	If chart.xAxis.labelAngle {
		Do XSL.WriteLine("        <xsl:attribute name='transform'><xsl:value-of select='concat(""rotate("_chart.xAxis.labelAngle_","",$x - $adj,"","_(plot.plotBottom+chart.xAxis.labelDisplacement+4)_")"")' /></xsl:attribute>")
	}
	Do XSL.WriteLine("        <xsl:call-template name='zenReportGetXLabelText"_$$$groupNum_"'>")
	Do XSL.WriteLine("          <xsl:with-param name='item' select='$n + 1' />")
	Do XSL.WriteLine("        </xsl:call-template>")
	Do XSL.WriteLine("      </"_..SvgPrefix()_"text>")
	Do XSL.WriteLine("    </xsl:if>")
	Do XSL.WriteLine("    <xsl:call-template name='zenReportXCategoryLabels"_$$$groupNum_"'>")
	Do chart.writeWithParams(.XSL)
	Do XSL.WriteLine("      <xsl:with-param name='oldx' select='$x' />")
	Do XSL.WriteLine("      <xsl:with-param name='dx' select='$dx' />")
	Do XSL.WriteLine("      <xsl:with-param name='adj' select='$adj' />")
	Do XSL.WriteLine("      <xsl:with-param name='items' select='$items' />")
	Do XSL.WriteLine("      <xsl:with-param name='n' select='$n + 1' />")
	Do XSL.WriteLine("    </xsl:call-template>")
	Do XSL.WriteLine("  </xsl:if>")
	Do XSL.WriteLine("</xsl:template>")
}

/// Renders the 'zenReportYValueLabels' and 'zenReportYCategoryLabels' templates.
/// These loop over the data and display the appropriate labels.
ClassMethod renderDrawYLabels(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, chart As chart, plot As plot)
{
	Do XSL.WriteLine("<xsl:template name='zenReportYValueLabels"_$$$groupNum_"'>")
	Do chart.writeLoadParams(.XSL)
	Do XSL.WriteLine("  <xsl:param name='count' select='0'/>")
	Do XSL.WriteLine("  <xsl:param name='start' />")
	Do XSL.WriteLine("  <xsl:param name='end' />")
	Do XSL.WriteLine("  <xsl:param name='unit' />")
	Do XSL.WriteLine("  <xsl:if test='($start &lt;= $end) and ($count &lt; 200)'>")
	Do XSL.WriteLine("    <"_..SvgPrefix()_"text class='chart-yLabel'>")
	s tAtt=""
	if chart.labelStyle'="" s tAtt=chart.labelStyle_";"
	if chart.yAxis.labelStyle'="" s tAtt=tAtt_chart.yAxis.labelStyle_";"
	if tAtt'="" Do XSL.WriteLine("      <xsl:attribute name='style'>"_tAtt_"</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,tAtt)	
	s key="" for  s key=$o(context("SVGATTRS","chart-yLabel",key)) q:key=""  d
	. Do XSL.WriteLine("  <xsl:attribute name='"_key_"'>"_context("SVGATTRS","chart-yLabel",key)_"</xsl:attribute>")
	Do XSL.WriteLine("      <xsl:attribute name='text-anchor'>end</xsl:attribute>")
	Set mode = "legend"_$$$groupNum
	Do XSL.WriteLine("  <xsl:attribute name='x'><xsl:value-of select='$plotLeft"_mode_" - (4+"_chart.yAxis.labelDisplacement_")'/></xsl:attribute>")
	Do XSL.WriteLine("      <xsl:variable name='y'>")
	Do XSL.WriteLine("        <xsl:call-template name='zenReportGetPlotY"_$$$groupNum_"'>")
	Do chart.writeWithParamsNoBase(.XSL)
	Do XSL.WriteLine("          <xsl:with-param name='val' select='$start' />")
	Do XSL.WriteLine("        </xsl:call-template>")
	Do XSL.WriteLine("      </xsl:variable>")
	Do XSL.WriteLine("      <xsl:attribute name='y'><xsl:value-of select='$y + 1' /></xsl:attribute>")
	If chart.yAxis.labelAngle {
		Do XSL.WriteLine("      <xsl:attribute name='transform'><xsl:value-of select='concat(""rotate("_chart.yAxis.labelAngle_","", $plotLeft"_mode_", "","", $y + 1,"")"")' /></xsl:attribute>")
	}
	Do XSL.WriteLine("      <xsl:call-template name='zenReportGetYLabelText"_$$$groupNum_"'>")
	Do XSL.WriteLine("        <xsl:with-param name='item' select='$start' />")
	Do XSL.WriteLine("      </xsl:call-template>")
	Do XSL.WriteLine("    </"_..SvgPrefix()_"text>")
	Do XSL.WriteLine("    <xsl:call-template name='zenReportYValueLabels"_$$$groupNum_"'>")
	Do chart.writeWithParams(.XSL)
	Do XSL.WriteLine("      <xsl:with-param name='start' select='$start + $unit' />")
	Do XSL.WriteLine("      <xsl:with-param name='end' select='$end' />")
	Do XSL.WriteLine("      <xsl:with-param name='count' select='$count + 1' />")
	Do XSL.WriteLine("      <xsl:with-param name='unit' select='$unit' />")
	Do XSL.WriteLine("    </xsl:call-template>")
	Do XSL.WriteLine("  </xsl:if>")
	Do XSL.WriteLine("</xsl:template>")
	
	Do XSL.WriteLine("<xsl:template name='zenReportYCategoryLabels"_$$$groupNum_"'>")
	Do chart.writeLoadParams(.XSL)
	Do XSL.WriteLine("  <xsl:param name='oldy' select='"_plot.plotTop_"' />")
	Do XSL.WriteLine("  <xsl:param name='n' select='0' />")
	Do XSL.WriteLine("  <xsl:param name='dy' />")
	Do XSL.WriteLine("  <xsl:param name='adj' />")
	Do XSL.WriteLine("  <xsl:param name='items' />")
	Do XSL.WriteLine("  <xsl:if test='$n &lt;= $items'>")
	Do XSL.WriteLine("    <xsl:variable name='y' select='$oldy + $dy' />")
	Do XSL.WriteLine("    <xsl:if test='$n mod $"_$$$yLabelUnits_" = 0'>")
	Do XSL.WriteLine("      <"_..SvgPrefix()_"text class='chart-yLabel'>")
	s tAtt=""
	if chart.labelStyle'="" s tAtt=chart.labelStyle_";"
	if chart.yAxis.labelStyle'="" s tAtt=tAtt_chart.yAxis.labelStyle_";"
	if tAtt'="" Do XSL.WriteLine("        <xsl:attribute name='style'>"_tAtt_"</xsl:attribute>")
	Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.XSL,tAtt)	
	s key="" for  s key=$o(context("SVGATTRS","chart-yLabel",key)) q:key=""  d
	. Do XSL.WriteLine("  <xsl:attribute name='"_key_"'>"_context("SVGATTRS","chart-yLabel",key)_"</xsl:attribute>")
	Do XSL.WriteLine("        <xsl:attribute name='text-anchor'>end</xsl:attribute>")
	Do XSL.WriteLine("        <xsl:attribute name='y'><xsl:value-of select='$y - $adj' /></xsl:attribute>")
	Set mode = "legend"_$$$groupNum
	Do XSL.WriteLine("  <xsl:attribute name='x'><xsl:value-of select='$plotLeft"_mode_" - (4+"_chart.yAxis.labelDisplacement_")'/></xsl:attribute>")
	If chart.xAxis.labelAngle {
		Do XSL.WriteLine("        <xsl:attribute name='transform'><xsl:value-of select='concat(""rotate("_chart.yAxis.labelAngle_","", $plotLeft"_mode_" div 2, "","", $y - $adj,"")"")' /></xsl:attribute>")
	}
	
	Do XSL.WriteLine("        <xsl:call-template name='zenReportGetYLabelText"_$$$groupNum_"'>")
	Do XSL.WriteLine("          <xsl:with-param name='item' select='$n + 1' />")
	Do XSL.WriteLine("        </xsl:call-template>")
	Do XSL.WriteLine("      </"_..SvgPrefix()_"text>")
	Do XSL.WriteLine("    </xsl:if>")
	Do XSL.WriteLine("    <xsl:call-template name='zenReportYCategoryLabels"_$$$groupNum_"'>")
	Do chart.writeWithParams(.XSL)
	Do XSL.WriteLine("      <xsl:with-param name='oldy' select='$y' />")
	Do XSL.WriteLine("      <xsl:with-param name='dy' select='$dy' />")
	Do XSL.WriteLine("      <xsl:with-param name='adj' select='$adj' />")
	Do XSL.WriteLine("      <xsl:with-param name='items' select='$items' />")
	Do XSL.WriteLine("      <xsl:with-param name='n' select='$n + 1' />")
	Do XSL.WriteLine("    </xsl:call-template>")
	Do XSL.WriteLine("  </xsl:if>")
	Do XSL.WriteLine("</xsl:template>")
}

/// Renders the 'zenReportYValueLines', 'zenReportYCategoryLines', 
/// 'zenReportXValueLines', and 'zenReportXCategoryLines' templates
/// which are invoked as necessary to draw the gridlines.
ClassMethod renderGridLinesTemplates(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, chart As chart, plot As plot)
{
	Set mode = "legend"_$$$groupNum
	Set yPathAddition="concat(' M ', $plotLeft"_mode_" ,' ', $y, ' L "_plot.plotRight_" ', $y)"
	;Set yPathAddition="concat(' M "_plot.plotLeft_" ', $y, ' L "_plot.plotRight_" ', $y)"
	#;  ******* Y VALUE LINES ********
	Set yAxisType=chart.getYAxisType()
	If yAxisType="value" {
		Do XSL.WriteLine("<xsl:template name='zenReportYValueLines"_$$$groupNum_"'>")
		Do chart.writeLoadParams(.XSL)
		Do XSL.WriteLine("  <xsl:param name='start' />")
		Do XSL.WriteLine("  <xsl:param name='end' />")
		Do XSL.WriteLine("  <xsl:param name='count' select='0' />")
		Do XSL.WriteLine("  <xsl:param name='unit' />")
		Do XSL.WriteLine("  <xsl:if test='$count &lt; 200'>")
		Do XSL.WriteLine("    <xsl:if test='$start &lt;= $end'>")
		Do XSL.WriteLine("      <xsl:variable name='y'>")
		Do XSL.WriteLine("        <xsl:call-template name='zenReportGetPlotY"_$$$groupNum_"'>")
		Do chart.writeWithParamsNoBase(.XSL)
		Do XSL.WriteLine("          <xsl:with-param name='val' select='$start' />")
		Do XSL.WriteLine("        </xsl:call-template>")
		Do XSL.WriteLine("      </xsl:variable>")
		Do XSL.WriteLine("      <xsl:value-of select="""_yPathAddition_""" />")
		Do XSL.WriteLine("      <xsl:call-template name='zenReportYValueLines"_$$$groupNum_"'>")
		Do chart.writeWithParams(.XSL)
		Do XSL.WriteLine("        <xsl:with-param name='count' select='$count + 1' />")
		Do XSL.WriteLine("        <xsl:with-param name='start' select='$start + $unit' />")
		Do XSL.WriteLine("        <xsl:with-param name='end' select='$end' />")
		Do XSL.WriteLine("        <xsl:with-param name='unit' select='$unit' />")
		Do XSL.WriteLine("      </xsl:call-template>")
		Do XSL.WriteLine("    </xsl:if>")
		Do XSL.WriteLine("  </xsl:if>")
		Do XSL.WriteLine("</xsl:template>")
	} ElseIf yAxisType="category" {
		#; ********** Y CATEGORY LINES *****************
		Do XSL.WriteLine("<xsl:template name='zenReportYCategoryLines"_$$$groupNum_"'>")
		Do chart.writeLoadParams(.XSL)
		Do XSL.WriteLine("  <xsl:param name='oldy' select='"_plot.plotTop_"' />")
		Do XSL.WriteLine("  <xsl:param name='dy' />")
		Do XSL.WriteLine("  <xsl:param name='items' />")
		Do XSL.WriteLine("  <xsl:param name='n' select='0' />")
		Do XSL.WriteLine("  <xsl:param name='majorLines' select='true()' />")
		Do XSL.WriteLine("  <xsl:if test='$n &lt; $items'>")
		Do XSL.WriteLine("    <xsl:variable name='y' select='$oldy + $dy' />")
		Do XSL.WriteLine("    <xsl:choose><xsl:when test='$majorLines'>")
		Do XSL.WriteLine("      <xsl:if test='$n mod $"_$$$yMajorUnits_" = 0'>")
		Do XSL.WriteLine("        <xsl:value-of select="""_yPathAddition_""" />")
		Do XSL.WriteLine("      </xsl:if>")
		Do XSL.WriteLine("    </xsl:when><xsl:otherwise>")
		Do XSL.WriteLine("      <xsl:if test='$n mod $"_$$$yMinorUnits_" = 0'>")
		
		
		If chart.yAxis.majorGridLines {
			Do XSL.WriteLine("        <xsl:if test='$n mod $"_$$$yMajorUnits_" != 0'>")
			Do XSL.WriteLine("          <xsl:value-of select="""_yPathAddition_""" />")
			Do XSL.WriteLine("        </xsl:if>")
		} Else {
			Do XSL.WriteLine("        <xsl:value-of select="""_yPathAddition_""" />")
		}
		Do XSL.WriteLine("      </xsl:if>")
		Do XSL.WriteLine("    </xsl:otherwise></xsl:choose>")	
		
		Do XSL.WriteLine("    <xsl:call-template name='zenReportYCategoryLines"_$$$groupNum_"'>")
		Do chart.writeWithParams(.XSL)
		Do XSL.WriteLine("      <xsl:with-param name='oldy' select='$y' />")
		Do XSL.WriteLine("      <xsl:with-param name='dy' select='$dy' />")
		Do XSL.WriteLine("      <xsl:with-param name='items' select='$items' />")
		Do XSL.WriteLine("      <xsl:with-param name='n' select='$n + 1' />")
		Do XSL.WriteLine("      <xsl:with-param name='majorLines' select='$majorLines' />")
		Do XSL.WriteLine("    </xsl:call-template>")
		Do XSL.WriteLine("  </xsl:if>")
		Do XSL.WriteLine("</xsl:template>")
	}
	
	Set xPathAddition="concat(' M ', $x, ' "_plot.plotTop_" L ', $x, ' "_plot.plotBottom_" ')"
	#;  ******* X VALUE LINES ********
	Set xAxisType=chart.getXAxisType()
	If xAxisType="value" {
		Do XSL.WriteLine("<xsl:template name='zenReportXValueLines"_$$$groupNum_"'>")
		Do chart.writeLoadParams(.XSL)
		Do XSL.WriteLine("  <xsl:param name='start' />")
		Do XSL.WriteLine("  <xsl:param name='end' />")
		Do XSL.WriteLine("  <xsl:param name='count' select='0' />")
		Do XSL.WriteLine("  <xsl:param name='unit' />")
		Do XSL.WriteLine("  <xsl:if test='$count &lt; 200'>")
		Do XSL.WriteLine("    <xsl:if test='$start &lt;= $end'>")
		Do XSL.WriteLine("      <xsl:variable name='x'>")
		Do XSL.WriteLine("        <xsl:call-template name='zenReportGetPlotX"_$$$groupNum_"'>")
		Do chart.writeWithParamsNoBase(.XSL)
		Do XSL.WriteLine("          <xsl:with-param name='val' select='$start' />")
		Do XSL.WriteLine("        </xsl:call-template>")
		Do XSL.WriteLine("      </xsl:variable>")
		Do XSL.WriteLine("      <xsl:value-of select="""_xPathAddition_""" />")
		Do XSL.WriteLine("      <xsl:call-template name='zenReportXValueLines"_$$$groupNum_"'>")
		Do chart.writeWithParams(.XSL)
		Do XSL.WriteLine("        <xsl:with-param name='count' select='$count + 1' />")
		Do XSL.WriteLine("        <xsl:with-param name='start' select='$start + $unit' />")
		Do XSL.WriteLine("        <xsl:with-param name='end' select='$end' />")
		Do XSL.WriteLine("        <xsl:with-param name='unit' select='$unit' />")
		Do XSL.WriteLine("      </xsl:call-template>")
		Do XSL.WriteLine("    </xsl:if>")
		Do XSL.WriteLine("  </xsl:if>")
		Do XSL.WriteLine("</xsl:template>")
	
	#; ********** X CATEGORY LINES *****************
	} ElseIf  xAxisType="category" {
		Do XSL.WriteLine("<xsl:template name='zenReportXCategoryLines"_$$$groupNum_"'>")
		Do chart.writeLoadParams(.XSL)
		Set mode = "legend"_$$$groupNum
		Do XSL.WriteLine("  <xsl:param name='oldx' select='$plotLeft"_mode_"' />")
		Do XSL.WriteLine("  <xsl:param name='dx' />")
		Do XSL.WriteLine("  <xsl:param name='items' />")
		Do XSL.WriteLine("  <xsl:param name='n' select='1' />")
		Do XSL.WriteLine("  <xsl:param name='majorLines' select='true()' />")
		Do XSL.WriteLine("  <xsl:if test='$n &lt; $items'>")
		Do XSL.WriteLine("    <xsl:variable name='x' select='$oldx + $dx' />")
		Do XSL.WriteLine("    <xsl:choose><xsl:when test='$majorLines'>")
		Do XSL.WriteLine("      <xsl:if test='$n mod $"_$$$xMajorUnits_" = 0'>")
		Do XSL.WriteLine("        <xsl:value-of select="""_xPathAddition_""" />")
		Do XSL.WriteLine("      </xsl:if>")
		Do XSL.WriteLine("    </xsl:when><xsl:otherwise>")
		
		Do XSL.WriteLine("      <xsl:if test='$n mod $"_$$$xMinorUnits_" = 0'>")
		
		
		
		If chart.xAxis.majorGridLines {
			Do XSL.WriteLine("        <xsl:if test='$n mod $"_$$$xMajorUnits_" != 0'>")
			Do XSL.WriteLine("          <xsl:value-of select="""_xPathAddition_""" />")
			Do XSL.WriteLine("        </xsl:if>")
		} Else {
			Do XSL.WriteLine("        <xsl:value-of select="""_xPathAddition_""" />")
		}
		
		Do XSL.WriteLine("      </xsl:if>")
		Do XSL.WriteLine("    </xsl:otherwise></xsl:choose>")
		Do XSL.WriteLine("    <xsl:call-template name='zenReportXCategoryLines"_$$$groupNum_"'>")
		Do chart.writeWithParams(.XSL)
		Do XSL.WriteLine("      <xsl:with-param name='oldx' select='$x' />")
		Do XSL.WriteLine("      <xsl:with-param name='dx' select='$dx' />")
		Do XSL.WriteLine("      <xsl:with-param name='items' select='$items' />")
		Do XSL.WriteLine("      <xsl:with-param name='n' select='$n + 1' />")
		Do XSL.WriteLine("      <xsl:with-param name='majorLines' select='$majorLines' />")
		Do XSL.WriteLine("    </xsl:call-template>")

		Do XSL.WriteLine("  </xsl:if>")
		Do XSL.WriteLine("</xsl:template>")
	}
}

/// Renders the 'zenReportGetMinValue' and 'zenReportGetMaxValue' templates
/// which return the minimum and maximum data values across all series.
ClassMethod renderGetMaxMinValue(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, chart As chart, plot As plot)
{
	Set basepath=""
	If chart.seriesGroup'="" Set basepath=basepath_chart.seriesGroup_"/"
	If chart.dataGroup'="" Set basepath=basepath_chart.dataGroup_"/"
	;Set fields=$s(chart.dataGroup="":$l(chart.dataFields,","),1:1) 7-29-10
	Set fields=$l(chart.dataFields,",")
	
	if 'chart.%Extends("%ZEN.Report.Display.Chart.xyChart") {
		Set xpath=""
		For i=1:1:fields {
			Set field=$p(chart.dataFields,",",i)
			Set field=$zstrip(field,"<>W")
			Continue:$e(field)'="!"
			Set xpath=xpath_"//"_basepath_$e(field,2,$l(field))_" | "
		}
		Set ypath=""
		For i=1:1:fields {
			Set field=$p(chart.dataFields,",",i)
			Set field=$zstrip(field,"<>W")
			Continue:$e(field)'="!"
			Set ypath=ypath_"//"_basepath_$e(field,2,$l(field))_" | "
		}
	} else {
		Set xpath=""
		For i=1:1:1 {
			Set field=$p(chart.dataFields,",",i)
			Set field=$zstrip(field,"<>W")
			Continue:$e(field)'="!"
			Set xpath=xpath_"//"_basepath_$e(field,2,$l(field))_" | "
		}
		Set ypath=""
		For i=2:1:fields {
			Set field=$p(chart.dataFields,",",i)
			Set field=$zstrip(field,"<>W")
			Continue:$e(field)'="!"
			Set ypath=ypath_"//"_basepath_$e(field,2,$l(field))_" | "
		}
		
	}
	Set xpath=$e(xpath,1,$l(xpath)-2)
	Set ypath=$e(ypath,1,$l(ypath)-2)
	Do XSL.WriteLine("<xsl:template name='zenReportGetXMinValue"_$$$groupNum_"'>")
	Do XSL.WriteLine("  <xsl:call-template name='util-min'>")
	Do XSL.WriteLine("    <xsl:with-param name='nodes' select='"_..qualify(xpath,.context)_"' />")
	Do XSL.WriteLine("  </xsl:call-template>")
	Do XSL.WriteLine("</xsl:template>")
	Do XSL.WriteLine("<xsl:template name='zenReportGetXMaxValue"_$$$groupNum_"'>")
	Do XSL.WriteLine("  <xsl:call-template name='util-max'>")
	Do XSL.WriteLine("    <xsl:with-param name='nodes' select='"_..qualify(xpath,.context)_"' />")
	Do XSL.WriteLine("  </xsl:call-template>")
	Do XSL.WriteLine("</xsl:template>")
	Do XSL.WriteLine("<xsl:template name='zenReportGetYMinValue"_$$$groupNum_"'>")
	Do XSL.WriteLine("  <xsl:call-template name='util-min'>")
	Do XSL.WriteLine("    <xsl:with-param name='nodes' select='"_..qualify(ypath,.context)_"' />")
	Do XSL.WriteLine("  </xsl:call-template>")
	Do XSL.WriteLine("</xsl:template>")
	Do XSL.WriteLine("<xsl:template name='zenReportGetYMaxValue"_$$$groupNum_"'>")
	Do XSL.WriteLine("  <xsl:call-template name='util-max'>")
	Do XSL.WriteLine("    <xsl:with-param name='nodes' select='"_..qualify(ypath,.context)_"' />")
	Do XSL.WriteLine("  </xsl:call-template>")
	Do XSL.WriteLine("</xsl:template>")
}

ClassMethod qualify(xpath As %String, ByRef context As %String)
{
	Quit ##class(%ZEN.Report.group).Qualify(xpath,$g(context("xmlnamespaceprefix")))
}

/// following need for IE support
ClassMethod outputAttributesFromStyle(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, style As %String)
{
	;style='stroke-width: 0.1; fill-opacity: 1.0; stroke: gray;'
	If style="" Quit
	For i=1:1:$Length(style,";") {
	 Set keyValuePair=$Translate($Piece(style,";",i)," ")
	 Set key=$Piece(keyValuePair,":")
	 Set value=$Piece(keyValuePair,":",2)
	 If key'="",value'="" Do XSL.WriteLine("  <xsl:attribute name='"_key_"'>"_value_"</xsl:attribute>")
	}
}

ClassMethod SvgPrefix()
{
	quit $s(%report.isHTML5:"",1:"svg:")
}

}
