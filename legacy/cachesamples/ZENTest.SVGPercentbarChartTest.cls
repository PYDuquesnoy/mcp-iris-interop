/// Test page for percentbarChart components.
Class ZENTest.SVGPercentbarChartTest Extends ZENTest.SVGChartTest
{

Parameter PAGENAME = "SVG Percent Bar Chart Test Page";

/// This XML block defines the contents of the chart pane.
XData chartPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<svgFrame id="svgFrame" height="400" width="400">
<percentbarChart id="chart" 
	ongetData="return zenPage.getChartData(series);"
    ongetLabelX="return zenPage.getPercentBarXLabels(value);"
	plotAreaStyle="fill: #eeeeee;"
	title="Zen Percent Bar Chart"
	seriesColorScheme="solid"
  	seriesCount="3"
	seriesSize="6"
    appearance="2D"
	seriesNames="North America,Asia,Europe,South America,Africa,Australia"
	width="400" 
	height="400">
<xAxis id="xAxis" /> 
<yAxis id="yAxis"
   baseValue="0"
	minorGridLines="true"/>
</percentbarChart>
</svgFrame>

</pane>
}

}

