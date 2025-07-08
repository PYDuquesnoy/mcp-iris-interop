/// Test page for stacked barChart components.
Class ZENTest.SVGStackedBarChartTest Extends ZENTest.SVGChartTest
{

Parameter PAGENAME = "SVG Stacked Bar Chart Test Page";

/// This XML block defines the contents of the chart pane.
XData chartPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<svgFrame id="svgFrame" height="400" width="400">
<barChart id="chart" 
	ongetData="return zenPage.getChartData(series);"
	onelementClick="zenPage.chartElementClick(chart);"
	plotAreaStyle="fill: #eeeeee;"
	title="Zen Stacked Bar Chart"
	seriesColorScheme="solid"
    chartStacked="true"
  	seriesCount="3"
	seriesSize="10"
	width="400" 
	height="400">
<xAxis id="xAxis" />
<yAxis id="yAxis"
   baseValue="0"
	minorGridLines="true"/>
</barChart>
</svgFrame>
</pane>
}

}

