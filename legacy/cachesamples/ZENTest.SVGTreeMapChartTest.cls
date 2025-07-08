/// Test page for treeMapChart.
Class ZENTest.SVGTreeMapChartTest Extends ZENTest.SVGChartTest
{

Parameter PAGENAME = "SVG Tree Map Chart Test Page";

/// This XML block defines the contents of the chart pane.
XData chartPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<svgFrame id="svgFrame" height="400" width="400">
<treeMapChart id="chart" 
	ongetData="return zenPage.getChartData(series);"
	onelementClick="zenPage.chartElementClick(chart);"
	title="Zen Tree Map Chart"
	seriesCount="4"
	seriesSize="6"
    seriesColorScheme="pastel"
	ongetLabelY="return zenPage.getCountryLabels(value);"
    legendVisible="false"
    appearance="2D"
	width="400" 
	height="400">
</treeMapChart>
</svgFrame>

</pane>
}

}

