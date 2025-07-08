/// Zen SVG Dashboard Demonstration page
Class ZENDemo.Dashboard Extends %ZEN.Component.page
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENDemo.Application";

/// Displayed name of this page.
Parameter PAGENAME = "Home";

/// Domain used for localization.
Parameter DOMAIN;

/// example of customized style sheet
XData Style
{
<style type="text/css">

#svgFrame {
	border-style: inset;
}

</style>
}

/// Contents of this page:
/// serialized set of Zen component objects
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Zen Demo">
<demo:demoTitle id="title" title="SVG Dashboard Demonstration"/>
<locatorBar id="locator" OnGetQuickLinks="GetQuickLinks">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Dashboard" title="Sample SVG Dashboard" href="ZENDemo.Dashboard.cls"/>
</locatorBar>

<hgroup>
<vgroup valign="top">
<demo:sidebar text="This Zen page demonstrates the following features:">
<demo:bullet text="SVG Charts" />
<demo:bullet text="SVG Meters" />
<demo:bullet text="Ability to work with HTML and SVG Components" />
</demo:sidebar>
</vgroup>

<spacer width="40"/>
<vgroup valign="top">
<spacer height="20"/>

<hgroup>
<html enclosingStyle="margin: 3px; font-size:1.2em; color: darkblue;">This is an example of a Zen Dashboard:</html>
<spacer width="10" />
<button caption="Update" onclick="zenPage.updateData();"/>
</hgroup>
<svgFrame id="svgFrame" 
	width="700" 
	height="400" 
	zoom="100"
	backgroundStyle="fill: black;"
	layout="horizontal">
<lineChart id="chart" 
	width="500" 
	height="400"
	title="Zen Chart"
	backgroundStyle="fill: black;"
	plotAreaStyle="fill: url(#glow-blueDiag);"
	plotStyle="stroke: black;"
	seriesColors="url(#glow-yellow)"
	seriesCount="1"
	seriesSize="12"
	marginRight="5"
	labelStyle="fill:yellow;"
	titleStyle="fill:yellow;"
	chartFilled="true"
	ongetData="return zenPage.getChartData(series);"
	ongetLabelX="return zenPage.getChartLabelX(value);"
	>
<yAxis id="yAxis"
	baseValue="0"
	minValue="-40" 
	maxValue="125" 
	majorUnits="25"
	minorUnits="5"
	title="Requests"
	minorGridLines="true"/>
</lineChart>

<svgGroup layout="vertical">
<speedometer id="speed1" 
	label="Important"
	animate="true"
	labelStyle="fill: yellow;"
	lowLampColor="url(#glow-green)"
	rangeUpper="100" width="125" height="125"/>
<speedometer id="speed2" 
	label="Urgent"
	animate="true"
	labelStyle="fill: yellow;"
	lowLampColor="url(#glow-green)"
	rangeUpper="100" width="125" height="125"/>
<speedometer id="speed3" 
	label="Overdue!"
	animate="true"
	labelStyle="fill: yellow;"
	lowLampColor="url(#glow-green)"
	rangeUpper="100" width="125" height="125"/>
</svgGroup>
</svgFrame>
</vgroup>
</hgroup>
</page>
}

/// Server-side method to calculate new chart data
ClassMethod getNewChartData() [ ZenMethod ]
{
	Set pts = 12
	Set data = ""
	For n = 1:1:pts {
		Set data = data _ $S(data="":"",1:":") _ $R(1000)
	}

	&js<zenPage.updateChart('#(data)#');>
}

/// Callback to provide data for chart.
ClientMethod getChartData(series) [ Language = javascript ]
{
	// generate random data
	// cache it in a local property
	var chart = zenPage.getComponentById('chart');
	if (null == this._data) {
		this._data = new Array(chart.seriesSize);
	}

	// slide data over; generate new value at end
	var value = 50;
	for (var i = 0; i < chart.seriesSize; i++) {
		var x = this._data[i+1];
		if (null != x) {
			value = x;
		}
		else {
			// at end or first-time
			if (Math.random() > 0.9) {
				value += (Math.random() * 50) - 30;
			}
			else {
				value += (Math.random() * 20) - 9;
			}
		}
		this._data[i] = value;
	}

	return this._data;
}

/// Callback to provide labels for chart.
ClientMethod getChartLabelX(val) [ Language = javascript ]
{
	// convert val to time-of-day
	var hour = (parseInt(val) + 8) % 12;
	
	if (hour == 0) {
		return '12pm';
	}
	else if (hour >=8) {
		return hour + 'am';
	}

	return hour + 'pm';
}

/// Update components to show new data
ClientMethod updateData() [ Language = javascript ]
{
	var chart = this.getComponentById("chart");
	zenASSERT(chart,"Unable to find chart",arguments);
	chart.updateChart();

	this.getComponentById("speed1").setValue(Math.random() * 100);
	this.getComponentById("speed2").setValue(Math.random() * 100);
	this.getComponentById("speed3").setValue(Math.random() * 100);
}

/// Return an array of quick links to be displayed by the locator bar.
ClassMethod GetQuickLinks(Output pLinks) As %Status
{
	#; dispatch to our application class
	Quit %application.GetQuickLinks(.pLinks)
}

}

