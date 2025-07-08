/// Model-View-Controller Meter demo page.
/// This page uses the Zen MVC mechanism to connect data to several meters.
Class ZENMVC.MVCMeters Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENMVC.MVCApplication";

Parameter PAGENAME = "MVC Meter Page";

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
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="MVC Meter Page">
<demo:demoTitle id="title" title="MVC Meter Demonstration"/>
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="MVC Meters" title="MVC Meter Demo" />
</locatorBar>

<hgroup valign="top">
<vgroup valign="top">
<demo:sidebar text="This page demonstrates the following features:">
<demo:bullet text="Using the Zen dataController component to automatically link data from a server-side Data Model to components on a web page." />
<demo:bullet text="A dynaGrid component is linked to the dataController. Changes in the grid are automatically propagated to other linked components." />
<demo:bullet text="A set of SVG meters are linked to the dataController and automatically change state in response to data changes." />
<demo:bullet text="The Previous and Next buttons change the id of the data object linked to the dataController." />
</demo:sidebar>
</vgroup>

<spacer width="10"/>

<dataController id="source" modelClass="ZENMVC.ChartDataModel" modelId="1"/>

<vgroup valign="top">
<spacer height="10"/>

<hgroup id="btnGroup">
<button caption="Previous" onclick="zenPage.previousObject();" />
<spacer width="20"/>
<button caption="Next" onclick="zenPage.nextObject();" />
</hgroup>

<spacer height="25"/>

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
	backgroundStyle="fill: darkblue; stroke: black;"
	layout="horizontal">
<speedometer id="m1" 
	controllerId="source"
	height="150"
	width="150" 
	dataBinding="P1"
	label="P1"
	labelStyle="fill: yellow;"
	/>

<trafficLight id="m2" 
	controllerId="source"
	height="150"
	width="75" 
	dataBinding="P2"
	label="P2"
	labelStyle="fill: yellow;"
	/>

<smiley id="m3" 
	controllerId="source"
	height="150"
	width="150" 
	dataBinding="P3"
	label="P3"
	labelStyle="fill: yellow;"
	/>

<lightBar id="m4" 
	controllerId="source"
	height="150"
	width="75" 
	dataBinding="P4"
	label="P4"
	labelStyle="fill: yellow;"
	/>

<lightBar id="m5" 
	controllerId="source"
	height="150"
	width="75" 
	dataBinding="P5"
	label="P5"
	labelStyle="fill: yellow;"
	/>

<svgGroup layout="vertical">
<svgSpacer height="10"/>

<indicatorLamp id="mi4" 
	controllerId="source"
	height="25"
	width="100" 
	dataBinding="P4"
	thresholdLower="10"
	thresholdUpper="90"
	label="Lamp P4"
	normalStyle="fill:url(#glow-yellow);"
	/>

<indicatorLamp id="mi5" 
	controllerId="source"
	height="25"
	width="100" 
	dataBinding="P5"
	thresholdLower="10"
	thresholdUpper="90"
	label="Lamp P5"
	normalStyle="fill:url(#glow-silver);"
	/>

<indicatorLamp id="mi6" 
	controllerId="source"
	height="25"
	width="100" 
	dataBinding="P6"
	thresholdLower="10"
	thresholdUpper="90"
	label="Lamp P6"
	/>

<indicatorLamp id="mi7" 
	controllerId="source"
	height="25"
	width="100" 
	dataBinding="P7"
	rangeUpper="0"
	rangeLower="100"
	thresholdLower="90"
	thresholdUpper="10"
	label="Lamp P7"
	/>
</svgGroup>
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

