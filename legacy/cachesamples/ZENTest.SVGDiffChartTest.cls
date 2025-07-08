/// Test page for diffChart components.
/// TESTING
Class ZENTest.SVGDiffChartTest Extends ZENTest.SVGChartTest
{

Parameter PAGENAME = "SVG Difference Chart Test Page";

/// This XML block defines the contents of the chart pane.
XData chartPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<svgFrame id="svgFrame" height="400" width="400">
<diffChart id="chart" 
	ongetData="return zenPage.getChartData(series);"
	onelementClick="zenPage.chartElementClick(chart);"
	plotAreaStyle="fill: #eeeeee;"
	title="Zen Difference Chart"
	seriesCount="2"
	seriesSize="10"
    refLineStyle="stroke-dasharray: 5,5; stroke-width: 1;"
    seriesColors="black,lightblue"
	width="400" 
	height="400">
<xAxis id="xAxis" />
<yAxis id="yAxis"
   baseValue="0"
	minorGridLines="true"/>
</diffChart>
</svgFrame>
</pane>
}

}

