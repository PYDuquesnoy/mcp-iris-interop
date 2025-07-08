/// Test page for comboChart components.
Class ZENTest.SVGComboChartTest Extends ZENTest.SVGChartTest
{

Parameter PAGENAME = "SVG Combo Chart Test Page";

/// This XML block defines the contents of the chart pane.
XData chartPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<svgFrame id="svgFrame" height="400" width="400">
<comboChart id="chart" 
	ongetData="return zenPage.getChartData(series);"
	onelementClick="zenPage.chartElementClick(chart);"
	plotAreaStyle="fill: #eeeeee;"
	title="Zen Combo Chart"
    seriesColors="red,teal,blue,orange"
  	seriesCount="4"
	seriesSize="10"
    seriesTypes="area,bar,line,line"
    lineStyle="stroke-width:1px;"
	width="400" 
	height="400">
<xAxis id="xAxis" />
<yAxis id="yAxis"
   baseValue="0"
   minValue="" 
   maxValue="" 
   majorUnits=""
   minorUnits=""
    minorGridLines="true"/>
</comboChart>
</svgFrame>

</pane>
}

}

