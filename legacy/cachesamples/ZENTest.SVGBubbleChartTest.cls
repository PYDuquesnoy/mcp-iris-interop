/// Test page for bubbleChart components.
Class ZENTest.SVGBubbleChartTest Extends ZENTest.SVGChartTest
{

Parameter PAGENAME = "SVG Bubble Chart Test Page";

/// This XML block defines the contents of the chart pane.
XData chartPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<svgFrame id="svgFrame" height="400" width="400">
<bubbleChart id="chart" 
	ongetData="return zenPage.getBubbleChartData(series);"
	onelementClick="zenPage.chartElementClick(chart);"
	plotAreaStyle="fill: #eeeeee;"
	title="Zen Bubble Chart"
	seriesColorScheme="solid"
  	seriesCount="5" 
    xCenterValue="80"
	seriesSize="10"
    radius="3"
    showRegression="true"
	lineStyle="stroke:black; stroke-width:1px;"
	width="400" 
	height="400">
<xAxis id="xAxis" />
<yAxis id="yAxis"
   baseValue="0"
	minorGridLines="true"/>
</bubbleChart>
</svgFrame>

</pane>
}

}

