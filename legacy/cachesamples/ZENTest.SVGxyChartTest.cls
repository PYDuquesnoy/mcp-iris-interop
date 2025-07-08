/// Test page for xyChart components.
Class ZENTest.SVGxyChartTest Extends ZENTest.SVGChartTest
{

Parameter PAGENAME = "SVG XY Chart Test Page";

/// This XML block defines the contents of the chart pane.
XData chartPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<svgFrame id="svgFrame" height="400" width="400">
<xyChart id="chart" 
	ongetData="return zenPage.getChartData(series);"
	onelementClick="zenPage.chartElementClick(chart);"
	plotAreaStyle="fill: #eeeeee;"
	title="Zen XY Chart"
	seriesCount="4"
	seriesSize="15"
    seriesColorScheme="solid"
	plotStyle="stroke:none;"
	width="400" 
	height="400">
<xAxis id="xAxis" />
<yAxis id="yAxis"
   baseValue="0"
	minorGridLines="true"/>
</xyChart>
</svgFrame>

</pane>
}

/// chartElementClick
ClientMethod chartElementClick(chart) [ Language = javascript ]
{
	var series = chart.getSelectedSeries();
	var item = chart.getSelectedItem();

	if (!isNaN(parseInt(series)) && !isNaN(parseInt(item))) {
		alert('You have selected item ' + item + ' in series ' + (parseInt(series)+1) + '.');
	}
}

}

