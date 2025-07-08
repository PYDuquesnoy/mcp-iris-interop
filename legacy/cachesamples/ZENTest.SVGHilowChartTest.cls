/// Test page for hilowChart components.
Class ZENTest.SVGHilowChartTest Extends ZENTest.SVGChartTest
{

Parameter PAGENAME = "SVG High/Low Chart Test Page";

/// This XML block defines the contents of the chart pane.
XData chartPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<svgFrame id="svgFrame" height="400" width="400">
<hilowChart id="chart" 
	ongetData="return zenPage.getHilowChartData(series);"
	onelementClick="zenPage.chartElementClick(chart);"
	plotAreaStyle="fill: #eeeeee;"
	title="Zen High/Low Chart"
	seriesColorScheme="solid"
    labelsVisible="true"
  	seriesCount="3"
	seriesSize="10"
	width="400" 
	height="400">
<xAxis id="xAxis" />
<yAxis id="yAxis"
   baseValue="0"
	minorGridLines="true"/>
</hilowChart>
</svgFrame>

</pane>
}

}

