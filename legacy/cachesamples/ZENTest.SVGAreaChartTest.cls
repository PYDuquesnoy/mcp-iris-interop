/// Test page for area Chart components.
Class ZENTest.SVGAreaChartTest Extends ZENTest.SVGChartTest
{

Parameter PAGENAME = "SVG Area Chart Test Page";

/// This XML block defines the contents of the chart pane.
XData chartPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<svgFrame id="svgFrame" height="400" width="400">
<lineChart id="chart" 
	ongetData="return zenPage.getChartData(series);"
	onelementClick="zenPage.chartElementClick(chart);"
	plotAreaStyle="fill: #eeeeee;"
	title="Zen Area Chart"
	seriesCount="1"
	seriesSize="10"
    seriesColorScheme="solid"
    chartFilled="true"
	width="400" 
	height="400">
<xAxis id="xAxis" />
<yAxis id="yAxis"
   baseValue="0"
	minorGridLines="true"/>
</lineChart>
</svgFrame>

</pane>
}

}

