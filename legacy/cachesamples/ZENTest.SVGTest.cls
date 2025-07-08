/// Simple SVG Component Test page
Class ZENTest.SVGTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

/// Displayed name of this page.
Parameter PAGENAME = "SVG Test";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

.button {
	width: 40px;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="SVG Test Page">
<demo:demoTitle id="title" title="Zen SVG Component Test Page" category="Zen Test Suite" />

<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="SVG" title="SVG Test Page" />
</locatorBar>

<spacer height="25"/>
<hgroup>
<spacer width="25"/>
<svgFrame id="svgFrame" height="400" width="400">
<rect id="rect1" rx="5" onclick="zenPage.toggleStyle(zenThis);"/>
<rect id="rect2" rx="5" onclick="zenPage.toggleStyle(zenThis);"/>
</svgFrame>
</hgroup>

<hgroup>
<spacer width="25"/>
<button caption="&lt;&lt;" onclick="zenPage.moveLeft();"/>
<spacer width="5"/>
<button caption="&gt;&gt;" onclick="zenPage.moveRight();"/>
<spacer width="5"/>
<button caption="-" onclick="zenPage.makeSmaller();"/>
<spacer width="5"/>
<button caption="+" onclick="zenPage.makeBigger();"/>
<spacer width="5"/>
<button caption="Add" onclick="zenPage.createRect();"/>
</hgroup>
</page>
}

/// Move rect to the right
ClientMethod moveRight() [ Language = javascript ]
{
	var rect = zenPage.getComponentById('rect1');
	rect.setProperty('x',(rect.getProperty('x')*1)+10);
}

/// Move rect to the left
ClientMethod moveLeft() [ Language = javascript ]
{
	var rect = zenPage.getComponentById('rect1');
	rect.setProperty('x',(rect.getProperty('x')*1)-10);
}

/// Make rect bigger
ClientMethod makeBigger() [ Language = javascript ]
{
	var rect = zenPage.getComponentById('rect1');
	rect.setProperty('width',rect.getProperty('width')*1.1);
	rect.setProperty('height',rect.getProperty('height')*1.1);
}

/// Make rect smaller
ClientMethod makeSmaller() [ Language = javascript ]
{
	var rect = zenPage.getComponentById('rect1');
	rect.setProperty('width',rect.getProperty('width')*0.9);
	rect.setProperty('height',rect.getProperty('height')*0.9);
}

/// Toggle style of rectangle
ClientMethod toggleStyle(rect) [ Language = javascript ]
{
	var style = rect.getProperty('style');
	rect.setProperty('style',(''==style)?'fill: yellow;':'');
}

/// Create a new rect
ClientMethod createRect() [ Language = javascript ]
{
	var frame = zenPage.getComponentById('svgFrame');

	var rect = this.createComponent('rect');
	rect.setProperty('rx',10);
	rect.setProperty('x',Math.random()*200);
	rect.setProperty('y',Math.random()*200);
	rect.setProperty('style','fill: green; opacity: 0.25;');
	frame.addChild(rect);
}

}

