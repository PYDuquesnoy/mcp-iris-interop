/// Zen SVG Chart test page.
/// This is an abstract base class from which the actual chart test pages
/// are created.
Class ZENTest.SVGChartTest Extends %ZEN.Component.page [ Abstract ]
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "SVG Chart Test Page";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

XData Style
{
<style type="text/css">

#objectInspector {
	border: 1px solid darkblue;
	height: 400px;
	width: 400px;
	overflow: auto;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="SVG Chart Test">
<demo:demoTitle id="title" title="Zen SVG Chart Test Page" category="Zen Test Suite" />

<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="Chart Demo" title="Chart Demo" />
</locatorBar>

<hgroup cellVAlign="top">
<demo:sidebar text="This Zen page demonstrates the following features:">
<demo:bullet text="How you can place dynamic charts within web page using the Zen chart components" />
<demo:bullet text="How the attributes of the Zen chart components can be modified dynamically" />
</demo:sidebar>

<hgroup cellVAlign="top">
<!-- subclass will provide contents of this pane -->
<vgroup cellVAlign="top">
<pane paneName="chartPane"/>
<hgroup>
<spacer width="50"/>
<button caption="Update" 
	title="Provide new data for this chart"
	onclick="zenPage.updateChart();" />
</hgroup>
<spacer height="25"/>
<vgroup>
<hgroup>
<link caption="areaChart" href="ZENTest.SVGAreaChartTest.cls"/>
<spacer width="25"/>
<link caption="barChart" href="ZENTest.SVGBarChartTest.cls"/>
<spacer width="25"/>
<link caption="percentbarChart" href="ZENTest.SVGPercentbarChartTest.cls"/>
<spacer width="25"/>
<link caption="stackedbarChart" href="ZENTest.SVGStackedBarChartTest.cls"/>
</hgroup>
<hgroup>
<link caption="bubbleChart" href="ZENTest.SVGBubbleChartTest.cls"/>
<spacer width="25"/>
<link caption="comboChart" href="ZENTest.SVGComboChartTest.cls"/>
<spacer width="25"/>
<link caption="diffChart" href="ZENTest.SVGDiffChartTest.cls"/>
<spacer width="25"/>
<link caption="hilowChart" href="ZENTest.SVGHilowChartTest.cls"/>
</hgroup>
<hgroup>
<link caption="lineChart" href="ZENTest.SVGLineChartTest.cls"/>
<spacer width="25"/>
<link caption="pieChart" href="ZENTest.SVGPieChartTest.cls"/>
<spacer width="25"/>
<link caption="xyChart" href="ZENTest.SVGxyChartTest.cls"/>
<spacer width="25"/>
<link caption="treeMapChart" href="ZENTest.SVGTreeMapChartTest.cls"/>
</hgroup>
<hgroup>
<link caption="bullseyeChart" href="ZENTest.SVGBullseyeChartTest.cls"/>
</hgroup>
</vgroup>
</vgroup>
<spacer width="25"/>

<vgroup valign="top">

<titleBox title="Chart Attributes" />
<html enclosingClass="msg">Set attribute values of the chart.</html>
<radioSet id="element" 
	valueList="chart,xAxis,yAxis"
	displayList="Chart,X axis,Y axis"
	value="chart"
	onchange="zenPage.inspectElement(zenThis.getValue());"
	/>
<objectInspector id="objectInspector" columnWidth="100"/>
</vgroup>

</hgroup>
</hgroup>
</page>
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	zenPage.inspectElement('chart');
}

/// Point object inspector to given component.
ClientMethod inspectElement(id) [ Language = javascript ]
{
	var obj = zenPage.getComponentById(id);
	var inspector = zenPage.getComponentById('objectInspector');
	inspector.setCurrObject(obj);
}

ClientMethod updateChart(idx) [ Language = javascript ]
{
	// connect inspector to chart
	var chart = zenPage.getComponentById('chart');
	chart.updateChart();
}

/// Callback to provide data for chart.
ClientMethod getChartData(series) [ Language = javascript ]
{
	var chart = zenPage.getComponentById('chart');
	var data = new Array(chart.seriesSize);
	var value = 50;
	
	for (var i = 0; i < chart.seriesSize; i++) {
		if (Math.random() > 0.9) {
			value += (Math.random() * 50) - 35;
		}
		else {
			value += (Math.random() * 20) - 9;
		}
		data[i] = value;
	}
	return data;
}

/// Callback to provide data for bubble chart.
ClientMethod getBubbleChartData(series) [ Language = javascript ]
{
	var chart = zenPage.getComponentById('chart');
	var data = new Array(chart.seriesSize);
	var value = 50;
	if (series == 0) // x values
	{
		for (var i = 0; i < chart.seriesSize; i++) {
		
			value += i;
	
			data[i] = value;
		}
	}
    if (series == 1) // y values
	{
		for (var i = 0; i < chart.seriesSize; i++) {
		
			value += (Math.random() * 20) - 9;
		    data[i] = value;
	    }
	}
    if (series == 2) // radius
	{
		for (var i = 0; i < chart.seriesSize; i++) {
			data[i] = 0;
		}
	}
    if (series == 3) // color
	{
		for (var i = 0; i < chart.seriesSize; i++) {
			data[i] = (i%3)?"group 1":"group 2"
		}
	}
    if (series == 4) // opacity
	{
		data[1] = 1;
		data[2] = 4;
		data[3] = 1;
		data[4] = 1;
		data[5] = 4;
		data[6] = 1;
		data[7] = 4;
		data[8] = 4;
		data[9] = 4; 
	}
	return data;
}

/// Callback to provide data for hilow chart.
ClientMethod getHilowChartData(series) [ Language = javascript ]
{
	var chart = zenPage.getComponentById('chart');
	var data = new Array(chart.seriesSize);
	var value = 50;

if (series == 0) // high
	{
		for (var i = 0; i < chart.seriesSize; i++) {
		
			value = (Math.random() * 10) + 200;
	
			data[i] = value;
		}
	}
    if (series == 1) // low
	{
		
		for (var i = 0; i < chart.seriesSize; i++) {
		
			value = (Math.random() * 10) + 50;
	
			data[i] = value;
		}
	}
    if (series == 2) // mid
	{
		for (var i = 0; i < chart.seriesSize; i++) {
		
			value = (Math.random() * 50) + 100;
	
			data[i] = value;
		}

	}
	return data;
}

/// Callback to provide data for bullseye chart.
ClientMethod getBullseyeChartData(series) [ Language = javascript ]
{
	var chart = zenPage.getComponentById('chart');
	var data = new Array(chart.seriesSize);
	var value = 50;

if (series == 0) // high
	{
		for (var i = 0; i < chart.seriesSize; i++) {
		
			value = (Math.random() * 1000) + (i * 100);
	
			data[i] = value;
		}
	}
    if (series == 1) // low
	{
		
		for (var i = 0; i < chart.seriesSize; i++) {
		
			value = (Math.random() * 500) + (i * 500);
	
			data[i] = value;
		}
	}
    if (series == 2) // mid
	{
		for (var i = 0; i < chart.seriesSize; i++) {
		
			value = (Math.random() * 10) + (i * 100);
	
			data[i] = value;
		}

	}
	return data;
}

/// Return labels
ClientMethod getCountryLabels(value) [ Language = javascript ]
{
	var label = null;
	
	switch(parseInt(value)) {
	case 0:
		label = 'North America';
		break;
	case 1:
		label = 'Asia';
		break;
	case 2:
		label = 'Europe';
		break;
	case 3:
		label = 'South America';
		break;
	case 4:
		label = 'Africa';
		break;
	case 5:
		label = 'Australia';
		break;
	}
	
	return label;
}

/// Return label displayed on the X axis for the Percent Bar Chart.
ClientMethod getPercentBarXLabels(value) [ Language = javascript ]
{
	var label = null;
	
    switch(parseInt(value)) {
	case 0:
		label = "Products";
		break;
	case 1:
		label = "Services";
		break;
	case 2:
		label = "Training";
		break;
	}
	return label;
}

/// chartElementClick
ClientMethod chartElementClick(chart) [ Language = javascript ]
{
	var series = chart.getSelectedSeries();
	var item = chart.getSelectedItem();

	if (!isNaN(parseInt(series)) && !isNaN(parseInt(item))) {
		alert('You have selected item ' + item + ' in series ' + series + '.');
	}
}

}

