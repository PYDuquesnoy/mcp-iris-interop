/// Simple SVG Sprint Component Test page
Class ZENTest.SVGSpriteTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

/// Displayed name of this page.
Parameter PAGENAME = "SVG Sprite Test";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

#objectInspector {
	border: 1px solid darkblue;
	width: 20.0em;
	height: 500px;
	overflow-y: scroll;
	overflow-x: hidden;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="SVG Sprite Test Page" import="%ZEN.SVGComponent.sprite">
<demo:demoTitle id="title" title="Zen SVG Sprite Test Page" category="Zen Test Suite" />
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="SVG Sprite Test" title="SVG Sprite Test" />
</locatorBar>

<spacer height="25"/>
<hgroup cellVAlign="top">

<spacer width="25"/>
<svgCanvas id="svgCanvas" 
	layout="horizontal"
	backgroundStyle="fill: blue; opacity: 0.1;"
	height="600" width="800"
	editMode="select"
	dragCanvas="true"
	zoomWithWheel="true"
	onselectItem="zenPage.itemSelected(item);"
	ondragCanvas="zenPage.updateInspector();"
	onmouseWheel="zenPage.updateInspector();"
	onmoveItem="zenPage.updateInspector();"
	onresizeItem="zenPage.updateInspector();"
	 />
<spacer width="25"/>

<vgroup valign="top">

<titleBox title="Attributes" />
<html enclosingClass="msg">Set attribute values of the selected shape.</html>
<objectInspector id="objectInspector" />
</vgroup>

</hgroup>

</page>
}

/// Select the given item and set the inspector to refer to it.
ClientMethod select(item) [ Language = javascript ]
{
	var svg = zenPage.getComponentById('svgCanvas');
}

/// Select the given sprite
ClientMethod selectSprite(sprite) [ Language = javascript ]
{
	var canvas = zenPage.getComponentById('svgCanvas');
	canvas.selectItem(sprite);
	sprite.setOverlayMode(3);
}

/// Notification that user has selected an SVG component.
ClientMethod itemSelected(item) [ Language = javascript ]
{
	var inspector = zenPage.getComponentById('objectInspector');
	if (null == item) {
		// select the svgCanvas
		item = zenPage.getComponentById('svgCanvas');
	}

	inspector.setCurrObject(item);
}

/// Update values in the inspector.
ClientMethod updateInspector() [ Language = javascript ]
{
	var inspector = zenPage.getComponentById('objectInspector');
	inspector.update();
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.initializeCanvas();
}

ClientMethod initializeCanvas() [ Language = javascript ]
{
	var canvas = zenPage.getComponentById('svgCanvas');
	if ((!canvas) || !canvas.document) {
		// ensure we don't execute code before the SVG document has been fully loaded
		setTimeout('zenPage.initializeCanvas();',10);
		return;
	}

	var inspector = this.getComponentById('objectInspector');
	inspector.setCurrObject(canvas);
	
	// create initial set of sprites & connectors
	var sprite = new Array();

	sprite[0] = canvas.createSprite('sprite',200,100);
	sprite[0].setProperty('onclick','zenPage.selectSprite(zenThis);');
	
	sprite[1] = canvas.createSprite('sprite',200,300);
	sprite[2] = canvas.createSprite('sprite',400,100);
	sprite[3] = canvas.createSprite('sprite',400,300);

	/*
	var connect = canvas.createConnector('connector');
	connect.addOutput(sprite[0],1);
	connect.addInput(sprite[1],0);
		
	var connect = canvas.createConnector('connector');
	connect.addOutput(sprite[2],1);
	connect.addInput(sprite[3],0);
	*/

	var connect = canvas.createConnector('connector');
	connect.addOutput(sprite[0],1);
	//connect.addOutput(sprite[2],1);
	connect.addInput(sprite[1],0);
	//connect.addInput(sprite[3],0);

	// turn off layout; turn on edit mode
	canvas.setProperty('layout','');
	canvas.setProperty('editMode','drag');
}

}

