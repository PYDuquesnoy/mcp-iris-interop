/// Test page for bullseyeChart components.
Class ZENTest.SVGBullseyeChartTest Extends ZENTest.SVGChartTest
{

Parameter PAGENAME = "SVG Bullseye Chart Test Page";

/// This XML block defines the contents of the chart pane.
XData chartPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<svgFrame id="svgFrame" height="400" width="400">
<bullseyeChart id="chart" 
	ongetData="return zenPage.getBullseyeChartData(series);"
	onelementClick="zenPage.chartElementClick(chart);"
	plotAreaStyle="fill: #eeeeee;"
	title="Zen Bullseye Chart"
    labelValue="value"
  	seriesCount="3" 
	seriesSize="3"
	width="400" 
	height="400">
</bullseyeChart>
</svgFrame>

</pane>
}

}

