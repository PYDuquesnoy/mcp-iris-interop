/// Test page for pieChart components.
Class ZENTest.SVGPieChartTest Extends ZENTest.SVGChartTest
{

Parameter PAGENAME = "SVG Pie Chart Test Page";

/// This XML block defines the contents of the chart pane.
XData chartPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<svgFrame id="svgFrame" height="400" width="400">
<pieChart id="chart" 
	ongetData="return zenPage.getChartData(series);"
	onelementClick="zenPage.chartElementClick(chart);"
	title="Zen Pie Chart"
	plotAreaStyle="fill: #eeeeee;"
	seriesCount="3"
	seriesSize="6"
    plotBy="items"
	seriesColorScheme="solid"
	seriesNames="Products,Services,Training"
	ongetLabelY="return zenPage.getCountryLabels(value);"
	legendVisible="false"
    appearance="2D"
	width="400" 
	height="400">
</pieChart>
</svgFrame>

</pane>
}

}

