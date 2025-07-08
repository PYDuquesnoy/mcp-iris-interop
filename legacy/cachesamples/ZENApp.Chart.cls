/// ZENApp.Chart
/// This is page displays chart data for the Help Desk sample application.
/// Note that this page extends the <class>ZENApp.TemplatePage</class>
/// class; this is a template that provides a standardized 
/// look & feel for the application.
Class ZENApp.Chart Extends ZENApp.TemplatePage
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENApp.SampleApp";

/// Displayed name of this page.
Parameter PAGENAME = "Chart";

/// Domain used for localization.
Parameter DOMAIN = "ZENAPP";

/// Localized list of months to use for chart labels.
Property monthList As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

/* style for menu pane */
#treeMenu {
	height: 20.0em;
	width: 10.0em;
	overflow: auto;
	border: 1px solid darkblue;
	background: #EEEEEE;
}

/* style for message box */
#msgBox {
	height: 8.0em;
	width: 10.0em;
	overflow: auto;
	border: 1px solid darkblue;
	background: white;
}

</style>
}

/// This XML block defines the contents of the menu pane.
XData menuPane
{
<pane id="zzz">
<dynaTree
	id="treeMenu"
	dataGlobal="%helpDeskMenu"
/>
</pane>
}

/// This XML block defines the contents of the message pane.
/// Here we use an HTML component and call a server-method to
/// get the message contents.
/// We use a timer to force periodic updates of the message box.
XData messagePane
{
<pane>
<timer id="timer" 
	ontimeout="zenPage.msgTimer(zenThis);" 
	timeout="10000"/>

<titleBox title="Messages" />

<html id="msgBox" OnDrawContent="DrawMessage" />
</pane>
}

/// This XML block defines the contents of the table pane.
XData tablePane
{
<pane>
<titleBox title="Customer Incidents By Month" 
		subtitle="This chart shows customer incidents by month." />

<svgFrame id="svg" width="700" height="500" layout="horizontal">
<barChart id="chart"
	backgroundStyle="fill: #000060;"
	plotAreaStyle="fill: url(#glow-silver);" 
	seriesColors="url(#glow-blue)"
	ongetData="return zenPage.getChartData(series);"
	ongetLabelX="return zenPage.getChartLabelX(value);"
	title="Customer Service Incidents"
	seriesCount="1"
	seriesSize="12"
	width="700" 
	height="500">
<xAxis id="xAxis" />
<yAxis id="yAxis"
	minValue="0" 
	maxValue="100" 
	majorUnits="25"
	minorUnits="5"
	minorGridLines="true"/>
</barChart>
</svgFrame>

</pane>
}

/// This XML block defines the contents of the details pane.
XData detailPane
{
<pane>
</pane>
}

/// This class method callback is called just before the server-side page 
/// object is created.
ClassMethod %OnBeforeCreatePage() As %Status
{
	#; Make sure array that defines the menu tree is defined
	#; (use a local and not a global)
	Kill %helpDeskMenu

	#; Create items to graph items by priority
	For p="All","Low","High","Critical" {
		Set %helpDeskMenu("Priority",p) = "javascript:zenPage.setChartCategory('"_$S(p="All":"",1:p)_"');"
	}

	Quit $$$OK
}

/// Draw the HTML that will be displayed within the
/// MessageBox
Method DrawMessage(pSeed As %String) As %Status
{
	#; create a random message
	Set tColors = $LB("red","green","blue","black","orange")
	Set tColor = $LG(tColors,$R($LL(tColors))+1)

	Set tMsgs = $LB("Fresh coffee in kitchen!","Company share price has gone up.","The boss is coming!","Customer crisis!","Lunch Time!")
	Set tMsg = $LG(tMsgs,$R($LL(tMsgs))+1)

	&html<#($ZDT($H,11))#<div style="color: #(tColor)#;">#(tMsg)#</div>>
	
	Quit $$$OK
}

/// MessageBox timer has fired.
ClientMethod msgTimer(timer) [ Language = javascript ]
{
	var html = this.getComponentById('msgBox');
	zenASSERT(html,"Unable to find html object",arguments);
	
	// update contents of message box
	html.refreshContents();

	timer.startTimer();
}

/// Server-side method to calculate new chart data
/// Returns a ":" delimited list of values.
ClassMethod calculateChartData(pPriority As %String = "") As %String [ ZenMethod ]
{
	#; Get incident data by month

	Set tRS = ##Class(%ResultSet).%New()
	Set tSQL = "SELECT COUNT(*) As C FROM ZENApp_Data.Incident"
	If (pPriority'="") {
		Set tSQL = tSQL _ " WHERE Priority = '"_pPriority_"'"
	}
	Set tSQL = tSQL _ " GROUP BY MONTH(CreateDate)"

	Set tSC = tRS.Prepare(tSQL)
	If $$$ISERR(tSC) {
		&js<alert('Error preparing query: #($ZCVT($ZE,"O","JS"))#\n #(tSQL)#');>
	}
	Set tSC = tRS.Execute()
	If $$$ISERR(tSC) {
		&js<alert('Error executing query: #($ZCVT($ZE,"O","JS"))#');>
	}

	Set data = ""
	While (tRS.Next()) {
		Set data = data _ $S(data="":"",1:":") _ tRS.Data("C")
	}	
	Set tRS = ""

	Quit data
}

/// Update chart to display data for given category.
ClientMethod setChartCategory(cat) [ Language = javascript ]
{
	var chart = this.getComponentById("chart");
	zenASSERT(chart,"Unable to find chart",arguments);

	// get new data from server, store in client variable
	var data = this.calculateChartData(cat);
	
	if ('' == data) {
		delete this._clientData;
	}
	else {
		this._clientData = data.split(':');
	}

	// adjust scales
	var yAxis = this.getComponentById("yAxis");
	if ('' == cat) {
		yAxis.setProperty('maxValue',200);
	}
	else {
		yAxis.setProperty('maxValue',100);
	}

	chart.updateChart();
}

/// Callback to provide labels for chart.
ClientMethod getChartLabelX(val) [ Language = javascript ]
{
	// return month out of month list
	return this.monthList.split(',')[val];
}

/// Callback to provide data for chart.
ClientMethod getChartData(series) [ Language = javascript ]
{
	// see if we have a client side copy of the data
	if (this._clientData) {
		return this._clientData;
	}

	// else create empty data
	var data = new Array(12);
	for (var i = 0; i < 12; i++) {
		data[i] = 0;
	}
	return data;
}

}

