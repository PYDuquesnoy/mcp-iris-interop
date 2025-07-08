/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Renders a hilo chart.<br>
/// Note: the <property>plotToEdge</property> is always
/// treated as false for hilo charts.
Class %ZEN.Report.Display.Chart.hilowChart Extends chart [ Deprecated, System = 4 ]
{

/// Default value for plotToEdge property.
Parameter DEFAULTPLOTTOEDGE = 0;

/// If true, pivot this chart: display categories vertically
/// and values horizontally.
Property chartPivot As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Draw data series for this chart.
Method renderSeries(ByRef context As %String, XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	If (..dataGroup'="")  {
		Do XSL.WriteLine("<"_..SvgPrefix()_"text fill='red' text-anchor='middle' font-size='2pt' x='"_(..plot.plotWidth/2)_"' y='"_(..plot.plotHeight/2)_"'>")
		Do XSL.WriteLine("  Hilow charts cannot have a dataGroup")
		Do XSL.WriteLine("</"_..SvgPrefix()_"text>")
		Quit $$$OK
	}
	If (..seriesGroup="")  {
		Do XSL.WriteLine("<"_..SvgPrefix()_"text fill='red' text-anchor='middle' font-size='2pt' x='"_(..plot.plotWidth/2)_"' y='"_(..plot.plotHeight/2)_"'>")
		Do XSL.WriteLine("  Hilow charts must have a seriesGroup")
		Do XSL.WriteLine("</"_..SvgPrefix()_"text>")
		Quit $$$OK
	}

	#; **** CHART *****
	Do ##class(chartUtil).renderDrawLowMarker(.context, .delay, ##this,..chartPivot)
	If (..seriesGroup = "")||(..seriesCount'="") {
		Set templatename="hiloseries"_$$$groupNum
		Set scount=$s(..seriesCount="":$l(..seriesNames,","),1:..seriesCount)
		if (scount > 3) {
			Set scount=3
		}
		Do XSL.WriteLine("<xsl:call-template name='"_templatename_"'>")
		Do ..writeWithParams(.XSL)
		Do XSL.WriteLine("  <xsl:with-param name='series' select='"_..seriesCount_"' />")
		Do XSL.WriteLine("</xsl:call-template>")

	} Else {
		Set templatename = ..seriesGroup
		Set mode = "hiloseries"_$$$groupNum
		
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
	Do delay.WriteLine("<xsl:variable name='items' select='$"_$$$seriessize_"' />")
	Do delay.WriteLine("<xsl:variable name='scount' select='$"_$$$seriescount_"' />")
	// make sure we have data
	Do delay.WriteLine("  <xsl:if test='($items &gt; 0) and ($scount &gt; 0)'>")
	Set mode1 = "legend"_$$$groupNum	
	// set up variables
	If '..chartPivot {
		Do delay.WriteLine("    <xsl:variable name='barwid' select='(0.8 div $scount) * ($plotWidth"_mode1_" div $items)' />")
		Do delay.WriteLine("    <xsl:variable name='shift' select='(($series - 1) * $barwid) - ($scount *$barwid) div 2' />")
		Do delay.WriteLine("    <xsl:variable name='dx' select='$plotWidth"_mode1_" div ($scount+1)' />")
		Do delay.WriteLine("    <xsl:variable name='adj' select='$dx div 2' />")
		//Set base = $s(..yAxis.baseValue="":..plot.plotHeight,1:..getPlotY(..yAxis.baseValue)-..plot.plotTop)
		Do delay.WriteLine("    <xsl:variable name='base' select='$"_$$$yBase_"' />")
	} Else {
		Do delay.WriteLine("    <xsl:variable name='barhgt' select='(0.8 div $scount) * ("_..plot.plotHeight_" div $items)' />")
		Do delay.WriteLine("    <xsl:variable name='shift' select='(($series - 1) * $barhgt) - ($scount * $barhgt) div 2' />")
		Do delay.WriteLine("    <xsl:variable name='dy' select='"_..plot.plotHeight_" div ($scount+1)' />")
		Do delay.WriteLine("    <xsl:variable name='adj' select='$dy div 2' />")
		//Set base = $s(..xAxis.baseValue="":0,1:..getPlotX(..xAxis.baseValue)-..plot.plotLeft)
		Do delay.WriteLine("    <xsl:variable name='base' select='$"_$$$xBase_"' />")
	}
	
	Set templatename="hilodata"_$$$groupNum
	
	Set numDataFields = $l(..dataFields,",")
	if (numDataFields > 3) {
		Set numDataFields = 3
	}
	For i=1:1:numDataFields {
		Set data(i)=$p(..dataFields,",",i)
		Set data(i)=$zstrip(data(i),"<>W")
		If $e(data(i))="!" {
			// XPath expression
			Set data(i) = $e(data(i),2,$l(data(i)))
		} Else {
			// literal
			Set data(i) = "'"_data(i)_"'"
		}
	}
	Do delay.WriteLine("      <xsl:call-template name='"_templatename_"'>")
	Do ..writeWithParams(.delay)
	Do delay.WriteLine("        <xsl:with-param name='series' select='$series' />")
	Do delay.WriteLine("        <xsl:with-param name='shift' select='$shift'/>")
	Do delay.WriteLine("        <xsl:with-param name='base' select='$base'/>")
	Do delay.WriteLine("        <xsl:with-param name='adj' select='$adj'/>")
	Do delay.WriteLine("        <xsl:with-param name='item' select='$series' />")
	if (..seriesGroup="") {
		For i=1:1:numDataFields {
			Do delay.WriteLine("        <xsl:with-param name='data"_i_"' select='"_data(i)_"' />")  ;foobar
		}
	} elseif (..seriesCount'="") {
		For i=1:1:numDataFields {
			Do delay.WriteLine("        <xsl:with-param name="_i_"' select='"_..seriesGroup_"[$series]/"_data(i)_"' />")  
		}
	} else {
		For i=1:1:numDataFields {
			Do delay.WriteLine("        <xsl:with-param name='data"_i_"' select='"_data(i)_"' />")  ;foobar
		}

	}
	If '..chartPivot {
		Do delay.WriteLine("        <xsl:with-param name='dx' select='$dx'/>")
	} Else {
		Do delay.WriteLine("        <xsl:with-param name='dy' select='$dy'/>")
	}
	Do delay.WriteLine("      </xsl:call-template>")
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
	For i=1:1:numDataFields {
		Do delay.WriteLine("  <xsl:param name='data"_i_"'/>")
	}
	Do delay.WriteLine("  <xsl:param name='base'/>")
	Do delay.WriteLine("  <xsl:param name='shift'/>")
	Do delay.WriteLine("  <xsl:param name='adj'/>")
	If '..chartPivot {
		Do delay.WriteLine("  <xsl:param name='dx'/>")
	} Else {
		Do delay.WriteLine("  <xsl:param name='dy'/>")
	}
	Do delay.WriteLine("  <xsl:variable name='raw1'>")
	Do delay.WriteLine("  <xsl:choose>")
	Do delay.WriteLine("    <xsl:when test='not($data1)'>0</xsl:when>")
	Do delay.WriteLine("    <xsl:otherwise>")
	Do delay.WriteLine("      <xsl:value-of select='number($data1)'/>")
	Do delay.WriteLine("     </xsl:otherwise>")
	Do delay.WriteLine("  </xsl:choose>")
	Do delay.WriteLine("  </xsl:variable>")

	Do delay.WriteLine("  <xsl:variable name='raw2'>")
	Do delay.WriteLine("  <xsl:choose>")
	Do delay.WriteLine("    <xsl:when test='not($data2)'>0</xsl:when>")
	Do delay.WriteLine("    <xsl:otherwise>")
	Do delay.WriteLine("      <xsl:value-of select='number($data2)'/>")
	Do delay.WriteLine("     </xsl:otherwise>")
	Do delay.WriteLine("  </xsl:choose>")
	Do delay.WriteLine("  </xsl:variable>")

	if (numDataFields=3) {
		Do delay.WriteLine("  <xsl:variable name='raw3'>")
		Do delay.WriteLine("  <xsl:choose>")
		Do delay.WriteLine("    <xsl:when test='not($data3)'>0</xsl:when>")
		Do delay.WriteLine("    <xsl:otherwise>")
		Do delay.WriteLine("      <xsl:value-of select='number($data3)'/>")
		Do delay.WriteLine("     </xsl:otherwise>")
		Do delay.WriteLine("  </xsl:choose>")
		Do delay.WriteLine("  </xsl:variable>")

	}
	
	Do delay.WriteLine("<xsl:variable name='val1' select='$raw1' />")
	Do delay.WriteLine("<xsl:variable name='val2' select='$raw2' />")
	if (numDataFields=3) Do delay.WriteLine("<xsl:variable name='val3' select='$raw3' />")
	Set mode = "legend"_$$$groupNum	
	If '..chartPivot {
		s attribs=""
		s sep=""
		s key="" for  s key=$o(context("SVGATTRS","chart-seriesLine",key)) q:key=""  d
		. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-seriesBar",key)_"'"
		. s sep=" "
		Do delay.WriteLine("<"_..SvgPrefix()_"line class='chart-seriesLine'"_attribs_">")
		Do delay.WriteLine("<xsl:variable name='x' select='$item * $dx' />")
		Do delay.WriteLine("<xsl:variable name='y1'>")
		Do delay.WriteLine("  <xsl:variable name='yraw'>")
		Do delay.WriteLine("    <xsl:call-template name='zenReportGetPlotY"_$$$groupNum_"'>")
		Do ..writeWithParamsNoBase(.delay)
		Do delay.WriteLine("      <xsl:with-param name='val' select='$val1'/>")
		Do delay.WriteLine("    </xsl:call-template>")
		Do delay.WriteLine("  </xsl:variable>")
		Do delay.WriteLine("  <xsl:value-of select='$yraw - "_..plot.plotTop_"' />")
		Do delay.WriteLine("</xsl:variable>")
		Do delay.WriteLine("<xsl:variable name='y2'>")
		Do delay.WriteLine("  <xsl:variable name='yraw'>")
		Do delay.WriteLine("    <xsl:call-template name='zenReportGetPlotY"_$$$groupNum_"'>")
		Do ..writeWithParamsNoBase(.delay)
		Do delay.WriteLine("      <xsl:with-param name='val' select='$val2'/>")
		Do delay.WriteLine("    </xsl:call-template>")
		Do delay.WriteLine("  </xsl:variable>")
		Do delay.WriteLine("  <xsl:value-of select='$yraw - "_..plot.plotTop_"' />")
		Do delay.WriteLine("</xsl:variable>")
		Do delay.WriteLine("<xsl:attribute name='x1'><xsl:value-of select='$x' /></xsl:attribute>")
		Do delay.WriteLine("<xsl:attribute name='y1'><xsl:value-of select='$y1' /></xsl:attribute>")
		Do delay.WriteLine("<xsl:attribute name='x2'><xsl:value-of select='$x ' /></xsl:attribute>")
		Do delay.WriteLine("<xsl:attribute name='y2'><xsl:value-of select='$y2' /></xsl:attribute>")
		if ..plotStyle'="" Do delay.WriteLine("<xsl:attribute name='style'>"_..plotStyle_"</xsl:attribute>")
		Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.delay,..plotStyle)
		
		Do delay.WriteLine("<xsl:attribute name='stroke'>")
		Do delay.WriteLine("  <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
		Do delay.WriteLine("    <xsl:with-param name='series' select='1'/>")
		Do delay.WriteLine("  </xsl:call-template>")
		Do delay.WriteLine("</xsl:attribute>")
		Do delay.WriteLine("</"_..SvgPrefix()_"line>")
		if (numDataFields = 3) {
			Do delay.WriteLine("<xsl:variable name='x' select='$item * $dx' />")
			Do delay.WriteLine("<xsl:variable name='y3'>")
			Do delay.WriteLine("  <xsl:variable name='yraw'>")
			Do delay.WriteLine("    <xsl:call-template name='zenReportGetPlotY"_$$$groupNum_"'>")
			Do ..writeWithParamsNoBase(.delay)
			Do delay.WriteLine("      <xsl:with-param name='val' select='$val3'/>")
			Do delay.WriteLine("    </xsl:call-template>")
			Do delay.WriteLine("  </xsl:variable>")
			Do delay.WriteLine("  <xsl:value-of select='$yraw - "_..plot.plotTop_"' />")
			Do delay.WriteLine("</xsl:variable>")
			Do delay.WriteLine("<xsl:call-template name='zenReportDrawLowMarker"_$$$groupNum_"'>")
			Do delay.WriteLine("  <xsl:with-param name='x' select='$x' />")
			Do delay.WriteLine("  <xsl:with-param name='y' select='$y3' />")
			Do delay.WriteLine("  <xsl:with-param name='shape' select=""'down'""/>")
			Do delay.WriteLine("  <xsl:with-param name='color'>")
			Do delay.WriteLine("    <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
			Do delay.WriteLine("       <xsl:with-param name='series' select='1'/>")
			Do delay.WriteLine("    </xsl:call-template>")
			Do delay.WriteLine("  </xsl:with-param>")
			Do delay.WriteLine("</xsl:call-template>")
		}

	} Else {
		// pivotted
		s attribs=""
		s sep=""
		s key="" for  s key=$o(context("SVGATTRS","chart-seriesBar",key)) q:key=""  d
		. s attribs=" "_attribs_sep_key_"='"_context("SVGATTRS","chart-seriesBar",key)_"'"
		. s sep=" "
		Do delay.WriteLine("<"_..SvgPrefix()_"line class='chart-seriesLine'"_attribs_">")
		Do delay.WriteLine("<xsl:variable name='y' select='$item * $dy' />")
		Do delay.WriteLine("<xsl:variable name='x1'>")
		Do delay.WriteLine("  <xsl:variable name='xraw'>")
		Do delay.WriteLine("    <xsl:call-template name='zenReportGetPlotX"_$$$groupNum_"'>")
		Do ..writeWithParamsNoBase(.delay)
		Do delay.WriteLine("      <xsl:with-param name='val' select='$val1'/>")
		Do delay.WriteLine("    </xsl:call-template>")
		Do delay.WriteLine("  </xsl:variable>")
		Do delay.WriteLine("  <xsl:value-of select='$xraw - $plotLeft"_mode_"' />")
		Do delay.WriteLine("</xsl:variable>")
		Do delay.WriteLine("<xsl:variable name='x2'>")
		Do delay.WriteLine("  <xsl:variable name='xraw'>")
		Do delay.WriteLine("    <xsl:call-template name='zenReportGetPlotX"_$$$groupNum_"'>")
		Do ..writeWithParamsNoBase(.delay)
		Do delay.WriteLine("      <xsl:with-param name='val' select='$val2'/>")
		Do delay.WriteLine("    </xsl:call-template>")
		Do delay.WriteLine("  </xsl:variable>")
		Do delay.WriteLine("  <xsl:value-of select='$xraw - $plotLeft"_mode_"' />")
		Do delay.WriteLine("</xsl:variable>")
		Do delay.WriteLine("<xsl:attribute name='x1'><xsl:value-of select='$x1' /></xsl:attribute>")
		Do delay.WriteLine("<xsl:attribute name='y1'><xsl:value-of select='$y' /></xsl:attribute>")
		Do delay.WriteLine("<xsl:attribute name='x2'><xsl:value-of select='$x2' /></xsl:attribute>")
		Do delay.WriteLine("<xsl:attribute name='y2'><xsl:value-of select='$y' /></xsl:attribute>")
		if ..plotStyle'="" Do delay.WriteLine("<xsl:attribute name='style'>"_..plotStyle_"</xsl:attribute>")
		Do ##class(%ZEN.Report.Display.Chart.chartUtil).outputAttributesFromStyle(.context,.delay,..plotStyle)
		Do delay.WriteLine("<xsl:attribute name='stroke'>")
		Do delay.WriteLine("  <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
		Do delay.WriteLine("    <xsl:with-param name='series' select='1'/>")
		Do delay.WriteLine("  </xsl:call-template>")
		Do delay.WriteLine("</xsl:attribute>")
		Do delay.WriteLine("</"_..SvgPrefix()_"line>")
		if (numDataFields = 3) {
			Do delay.WriteLine("<xsl:variable name='y' select='$item * $dy' />")
			Do delay.WriteLine("<xsl:variable name='x3'>")
			Do delay.WriteLine("  <xsl:variable name='xraw'>")
			Do delay.WriteLine("    <xsl:call-template name='zenReportGetPlotX"_$$$groupNum_"'>")
			Do ..writeWithParamsNoBase(.delay)
			Do delay.WriteLine("      <xsl:with-param name='val' select='$val3'/>")
			Do delay.WriteLine("    </xsl:call-template>")
			Do delay.WriteLine("  </xsl:variable>")
			Do delay.WriteLine("  <xsl:value-of select='$xraw - $plotLeft"_mode_"' />")
			Do delay.WriteLine("</xsl:variable>")
			Do delay.WriteLine("<xsl:call-template name='zenReportDrawLowMarker"_$$$groupNum_"'>")
			Do delay.WriteLine("  <xsl:with-param name='x' select='$x3' />")
			Do delay.WriteLine("  <xsl:with-param name='y' select='$y' />")
			Do delay.WriteLine("  <xsl:with-param name='shape' select=""'down'""/>")
			Do delay.WriteLine("  <xsl:with-param name='color'>")
			Do delay.WriteLine("    <xsl:call-template name='zenReportGetSeriesColor"_$$$groupNum_"'>")
			Do delay.WriteLine("       <xsl:with-param name='series' select='1'/>")
			Do delay.WriteLine("    </xsl:call-template>")
			Do delay.WriteLine("  </xsl:with-param>")
			Do delay.WriteLine("</xsl:call-template>")
		}

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

Storage Default
{
<Data name="hiloChartDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>chartPivot</Value>
</Value>
<Value name="3">
<Value>chartStacked</Value>
</Value>
</Data>
<DataLocation>^%ZEN.Report.Displ8E0.hiloChartD</DataLocation>
<DefaultData>hiloChartDefaultData</DefaultData>
<IdLocation>^%ZEN.Report.Displ8E0.hiloChartD</IdLocation>
<IndexLocation>^%ZEN.Report.Displ8E0.hiloChartI</IndexLocation>
<StreamLocation>^%ZEN.Report.Displ8E0.hiloChartS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
