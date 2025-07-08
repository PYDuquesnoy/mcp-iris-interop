Class ZENApp.ZenReportPercentBarChart Extends %ZEN.Report.reportPage
{

/// Class name of application this report belongs to.
Parameter APPLICATION;

/// This is the default display mode for this report.
Parameter DEFAULTMODE = "html";

/// This XML defines the logical contents of this report.
XData ReportDefinition [ XMLNamespace = "http://www.intersystems.com/zen/report/definition" ]
{
<report xmlns="http://www.intersystems.com/zen/report/definition"
 name="test" runonce="true">
 <!-- dummy ReportDefinition, all data is gotten from callback methods ongetXXX -->
</report>
}

/// This XML defines the display for this report.
/// This is used to generate the XSLT stylesheets for both HTML and XSL-FO.
XData ReportDisplay [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<report xmlns="http://www.intersystems.com/zen/report/display"
 name="test"  title="Percent Bar Chart">
 <document width="8.5in" height="11in" marginLeft="1.25in" marginRight="1.25in" marginTop="1.0in" marginBottom="1.0in" headerHeight="1in" >
  </document>

<body>
<cpercentbarChart id="chart1b" 
appearance="2D"
	chartPivot="true"
	ongetSeriesName ="getSeriesName"
	valueLabelsVisible="true"
	ongetLabelX="getSeriesNameX"	
	ongetLabelY="getSeriesNameY"
	width="500" height="400" plotStyle="stroke-width:1;" seriesCount="4" seriesSize="3" ongetData="getChartData"  >
	<yAxis majorGridLines="true"></yAxis>
	</cpercentbarChart>
</body>
</report>
}

/// Get chart data
Method getChartData(ByRef data, chartObject)
{
	for i=1:1:3 Set data(0,i-1) = $LI($LB( 34, 18, 27),i)
	for i=1:1:3 Set data(1,i-1) = $LI($LB( 43, 14, 24),i)
	for i=1:1:3 Set data(2,i-1) = $LI($LB( 43, 16, 27),i)
	for i=1:1:3 Set data(3,i-1) = $LI($LB( 45, 13, 34),i)
}

/// Get X axis label name
Method getSeriesNameX(value, chartObject)
{
	if ..%GetComponentById("chart1b").chartPivot {
		quit value
	} else {
		quit $LI($LB(1991,1992,1993,1994),value+1)
	}
}

/// Get Y axis label name
Method getSeriesNameY(value, yAxisNo, chartObject)
{
	if ..%GetComponentById("chart1b").chartPivot {
		quit $LI($LB(1991,1992,1993,1994),value+1)
	} else {
		quit value
	}
}

/// Get series name
Method getSeriesName(sno, chartObject)
{
	quit $LI($LB("Oats","Barley","Wheat"),sno+1)
}

}

