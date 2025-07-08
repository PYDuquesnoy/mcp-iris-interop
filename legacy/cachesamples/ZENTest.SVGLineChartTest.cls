/// Test page for lineChart components.
Class ZENTest.SVGLineChartTest Extends ZENTest.SVGChartTest
{

Parameter PAGENAME = "SVG Line Chart Test Page";

/// This XML block defines the contents of the chart pane.
XData chartPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<svgFrame id="svgFrame" height="400" width="400">
<lineChart id="chart" 
	ongetData="return zenPage.getChartData(series);"
	onelementClick="zenPage.chartElementClick(chart);"
	plotAreaStyle="fill: #eeeeee;"
    bandUpper="60"
    bandUpperStyle="fill: #eeffee"
    bandLower="20"
    bandLowerStyle="fill: #ffeeee"
    borderOffset="30"
	title="Zen Line Chart"
	seriesColorScheme="solid"
	seriesCount="3"
	seriesSize="10"
    lineStyle="stroke-width: 1px;"
    hasZoom="true"
	width="400" 
	height="400">
<xAxis id="xAxis" minorGridLines="true" />
<yAxis id="yAxis" baseValue="0" minorGridLines="true" />
</lineChart>
</svgFrame>

</pane>
}

}

