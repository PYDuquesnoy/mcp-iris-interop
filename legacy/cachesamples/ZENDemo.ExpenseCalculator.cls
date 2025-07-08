/// This example uses the dynamic grid control and a stacked
/// bar chart to create a simple expense report calculator.
Class ZENDemo.ExpenseCalculator Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENDemo.Application";

Parameter PAGENAME = "Expense Calculator";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

/// Default list of days names to display in the chart.
/// By defining this as a caption, it will automatically be
/// added to the localization database.
Property dayList As %ZEN.Datatype.caption [ InitialExpression = "Sun,Mon,Tue,Wed,Thu,Fri,Sat" ];

XData Style
{
<style type="text/css">

#calculator {
	border: 1px solid darkblue;
	overflow: auto;
}


/* Column labels for dynaGrid. */
table.dynaGrid th.dynaGridLabel,
table.dynaGrid th.dynaGridRow,
table.dynaGrid th.dynaGridColumn {
	color: black;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

table.dynaGrid th.dynaGridLabel:hover,
table.dynaGrid th.dynaGridRow:hover,
table.dynaGrid th.dynaGridColumn:hover {
	color: white;
	background: black;
}

.button {
	width: 180px;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Zen Expense Calculator">
<demo:demoTitle id="title" title="Zen Expense Calculator" />
<locatorBar id="locator" OnGetQuickLinks="GetQuickLinks">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Expense Calculator" title="Expense Calculator" href="ZENDemo.ExpenseCalculator.cls"/>
</locatorBar>

<hgroup>
<vgroup valign="top">
<demo:sidebar text="This Zen page demonstrates the following features:">
<demo:bullet text="Using the Dynamic Grid component" />
<demo:bullet text="Use of a Zen chart to visualize changing data" />
<demo:bullet text="How user events within SVG components (mouse click on the bar chart) can be used to to modify HTML components" />
</demo:sidebar>
</vgroup>
<spacer width="10"/>
<vgroup valign="top">
<spacer height="10"/>
<dynaGrid id="calculator" 
	OnCreateDataSet="CreateDataSet"
	gridLabel="Expenses"
	rowLabelWidth="200"
	onchange="zenPage.calcCellChange(zenThis);"
	ondrawcell="return zenPage.calcCellDraw(zenThis,data);"
>
<gridColumn label="Mon" width="100" />
<gridColumn label="Tue" width="100" />
<gridColumn label="Wed" width="100" />
<gridColumn label="Thu" width="100" />
<gridColumn label="Fri" width="100" />
<gridColumn label="Total" width="100" readOnly="true" style="background:#D0D0FF;font-weight: bold;"/>

<gridRow label="Breakfast" />
<gridRow label="Lunch" />
<gridRow label="Dinner" />
<gridRow label="Other" />
<gridRow label="Total" readOnly="true" style="background:#D0D0FF;font-weight: bold;"/>
</dynaGrid>	

<spacer height="10"/>

<svgFrame id="svgFrame" 
	height="400" 
	width="700" 
	backgroundStyle="fill: black;"
	layout="horizontal">
<barChart id="chart" 
	height="400"
	width="700" 
	title="Expenses By Day"
	titleStyle="fill: black;"
	backgroundStyle="fill: url(#glow-silver);"
	plotAreaStyle="fill: #AAAAFF; fill-opacity:0.2;"
	plotStyle="stroke: black;"
	labelStyle="fill: black;"
	legendStyle="fill: white; fill-opacity:0.2;"
	seriesColors="url(#glow-blueHz),url(#glow-greenHz),url(#glow-yellowHz),url(#glow-redHz),url(#glow-purpleHz)"
	seriesNames="Breakfast,Lunch,Dinner,Other"
	seriesCount="4"
	seriesSize="5"
	chartStacked="true"
	marginLeft="15"
	marginRight="20"
	marginTop="8"
	marginBottom="15"
	ongetData="return zenPage.getChartData(series);"
	ongetLabelX="return zenPage.getChartLabelX(value);"
	onelementClick="zenPage.chartElementClick(chart);"
	legendVisible="true"
	legendX="83"
	legendY="8"
	legendHeight=""
	legendWidth="17"
	>
<xAxis id="xAxis" 
	labelAngle="-45"
	title="Day of Week"
/>
<yAxis id="yAxis"
	baseValue="0"
	minValue="" 
	maxValue="" 
	majorUnits=""
	minorUnits=""
	title="US Dollars"
	minorGridLines="true"/>
</barChart>

</svgFrame>
<spacer height="10"/>
</vgroup>
</hgroup>
</page>
}

/// Server-side callback to provide initial data for the dynaGrid.
Method CreateDataSet(pGrid As %ZEN.Component.dynaGrid, pDataSet As %ZEN.Auxiliary.dataSet) As %Status
{
	#; fill in contents of dataSet
	#; This is a 2-D data structure

	#; fill in initial data for Monday
	Do pDataSet.%SetValue(10,1,1)
	Do pDataSet.%SetValue(4.5,2,1)
	Do pDataSet.%SetValue(8,3,1)
	Do pDataSet.%SetValue(12.95,4,1)
	Quit $$$OK
}

/// cellChange: called when cell is changed
ClientMethod calcCellChange(grid) [ Language = javascript ]
{
	// compute sum of cells
	var rows = grid.getRowCount();
	var cols = grid.getColumnCount();

	var total = 0;

	// first get totals of columns
	for (var c = 1; c < cols; c++) {
		var subtotal = 0;
		for (var r = 1; r < rows; r++) {
			var value = parseFloat(grid.getCellValue(r,c));
			value = isNaN(value) ? 0 : value;
			subtotal += value;
		}

		// set total cell
		grid.setCellValue(subtotal,rows,c);
		total += subtotal;
	}

	// next get totals of rows
	for (var r = 1; r < rows; r++) {
		var subtotal = 0;
		for (var c = 1; c < cols; c++) {
			var value = parseFloat(grid.getCellValue(r,c));
			value = isNaN(value) ? 0 : value;
			subtotal += value;
		}

		// set total cell
		grid.setCellValue(subtotal,r,cols);
	}

	// total
	grid.setCellValue(total,rows,cols);
	
	// update chart
	var chart = zenPage.getComponentById('chart');
	chart.updateChart();
}

/// cellDraw: called when cell is about to be drawn in dynaGrid
ClientMethod calcCellDraw(grid, data) [ Language = javascript ]
{
	// if we need to know the cell # being drawn, we
	// can get it via grid.row and grid.column.

	if (''==data) {
		return '&nbsp;';
	}
	else if (parseInt(data) < 0) {
		// negative #
		return '<span style="color:red;">('+data+')</span>';
	}
	else if (!isNaN(parseInt(data))) {
		// #
		var s = data.toString().split('.');
		if (s.length == 1) {
			return data + '.00';
		}
		else if (s.length == 2 && s[1].length==1) {
			return data + '0';
		}
		return data;
	}
	
	return data;
}

/// Callback to provide data for chart.
ClientMethod getChartData(series) [ Language = javascript ]
{
	var chart = zenPage.getComponentById('chart');
	var grid = zenPage.getComponentById('calculator');

	var data = new Array(chart.seriesSize);

	// get value from column cell
	var rows = grid.getRowCount();
	var cols = grid.getColumnCount();

	for (var c = 1; c < cols; c++) {
		var value = parseFloat(grid.getCellValue(series+1,c));
		value = isNaN(value) ? 0 : value;
		data[c-1] = value;
	}

	return data;
}

/// Callback to provide labels for chart.
ClientMethod getChartLabelX(val) [ Language = javascript ]
{
	var days = this.dayList.split(',');
	var day = days[val+1]; // val=0 for monday

	return (null==day) ? '?' : day;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// force grid to calculate, give it focus
	var grid = zenPage.getComponentById('calculator');
	zenPage.calcCellChange(grid);
	grid.focus();
}

/// User mouse click on an element in the bar chart.<br>
/// We will move the corresponding cell in the grid.
ClientMethod chartElementClick(chart) [ Language = javascript ]
{
	var series = chart.getSelectedSeries();
	var item = chart.getSelectedItem();

	if (!isNaN(parseInt(series)) && !isNaN(parseInt(item))) {
		var grid = zenPage.getComponentById('calculator');
		grid.selectCell(series+1,item+1);
		grid.focus();
	}
}

/// Return an array of quick links to be displayed by the locator bar.
ClassMethod GetQuickLinks(Output pLinks) As %Status
{
	#; dispatch to our application class
	Quit %application.GetQuickLinks(.pLinks)
}

}

