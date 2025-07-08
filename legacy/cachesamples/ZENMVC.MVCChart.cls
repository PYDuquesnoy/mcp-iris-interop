/// Model-View-Controller demo page.
/// This page uses the Zen MVC mechanism to connect data to several charts.
Class ZENMVC.MVCChart Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENMVC.MVCApplication";

Parameter PAGENAME = "MVC Chart Page";

/// Domain used for localization.
/// Parameter DOMAIN = "";
XData Style
{
<style type="text/css">
#btnGroup .button {
	width: 150px;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="MVC Chart Page">
<demo:demoTitle id="title" title="MVC Chart Demonstration"/>
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="MVC Chart" title="MVC Chart Demo" />
</locatorBar>

<hgroup>
<vgroup valign="top">
<demo:sidebar text="This page demonstrates the following features:">
<demo:bullet text="Using the Zen dataController component to automatically link data from a server-side Data Model to components on a web page." />
<demo:bullet text="A dynaGrid component is linked to the dataController. Changes in the grid are automatically propagated to other linked components." />
<demo:bullet text="A set of SVG charts are linked to the dataController and automatically change state in response to data changes." />
<demo:bullet text="The Previous and Next buttons change the id of the data object linked to the dataController." />
<demo:bullet text="The Change Model button causes the dataController to connect to a different type of dataModel class." />
</demo:sidebar>
</vgroup>
<spacer width="10"/>

<vgroup valign="top">
<spacer height="10"/>

<hgroup id="btnGroup">
<button caption="Previous" onclick="zenPage.previousObject();" />
<spacer width="20"/>
<button caption="Next" onclick="zenPage.nextObject();" />
<spacer width="20"/>
<button caption="Change Model" onclick="zenPage.changeModel();" />
</hgroup>

<spacer height="25"/>
<dataController id="source" modelClass="ZENMVC.ChartDataModel" modelId="1"/>

<hgroup>
<dynaGrid id="dynaGrid" 
	gridLabel="dynaGrid"
	controllerId="source"
	rowLabelWidth="225"
	columnWidth="150"
/>

</hgroup>
<spacer height="25"/>

<svgFrame id="svgFrame" 
	height="300" 
	width="900" 
	backgroundStyle="fill: black;"
	layout="horizontal">
<pieChart id="chart1" 
	controllerId="source"
	height="300"
	width="300" 
	title="Pie Chart"
	titleStyle="fill: black;"
	backgroundStyle="fill: url(#glow-silver);"
	plotAreaStyle="fill: white;"
	labelStyle="fill: black;"
	legendVisible="true"
	legendX="83"
	legendY="8"
	legendHeight=""
	legendWidth="15"
	>
</pieChart>

<barChart id="chart2" 
	controllerId="source"
	height="300"
	width="300" 
	chartPivot="false"
	title="Bar Chart"
	titleStyle="fill: black;"
	backgroundStyle="fill: url(#glow-silver);"
	plotAreaStyle="fill: white;"
	plotStyle="stroke-width: 0.1; stroke: black;"
	seriesColorScheme="bright"
	labelStyle="fill: black;"
	legendVisible="true"
	legendX="83"
	legendY="8"
	legendHeight=""
	legendWidth="15"
	>
</barChart>

<lineChart id="chart3" 
	controllerId="source"
	height="300"
	width="300" 
	chartFilled="true"
	chartStacked="true"
	title="Line Chart"
	titleStyle="fill: black;"
	backgroundStyle="fill: url(#glow-silver);"
	plotAreaStyle="fill: white;"
	plotStyle="stroke-width: 0.8; fill-opacity: 0.25;"
	labelStyle="fill: black;"
	legendVisible="true"
	legendX="83"
	legendY="8"
	legendHeight=""
	legendWidth="15"
	>
	</lineChart>
</svgFrame>
</vgroup>
</hgroup>
</page>
}

/// Point controller to next object.
ClientMethod nextObject() [ Language = javascript ]
{
	var controller = zenPage.getComponentById('source');
	var id = controller.getProperty('modelId');
	id = parseInt(id) + 1;
	id = (id >= 3) ? 1 : id;
	controller.setProperty('modelId',id);
}

/// Point controller to previous object.
ClientMethod previousObject() [ Language = javascript ]
{
	var controller = zenPage.getComponentById('source');
	var id = controller.getProperty('modelId');
	id = parseInt(id) - 1;
	id = (id <= 0) ? 3 : id;
	controller.setProperty('modelId',id);
}

/// Point controller to a different model class.
ClientMethod changeModel() [ Language = javascript ]
{
	var controller = zenPage.getComponentById('source');
	var model = controller.getProperty('modelClass');
	model = ('ZENMVC.ChartDataModel' == model) ? 'ZENMVC.ChartDataModel2' : 'ZENMVC.ChartDataModel';
	controller.setProperty('modelClass',model);
}

}

