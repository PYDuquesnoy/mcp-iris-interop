/// Test page for a custom SVG Component.
Class ZENTest.SVGComponentTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

/// Displayed name of this page.
Parameter PAGENAME = "SVG Custom Component Test";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

.button {
	width: 120px;
}

</style>
}

XData SVGStyle
{
<style type="text/css">
</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" xmlns:test="http://www.intersystems.com/zentest" title="SVG Custom Component Test Page" >
<demo:demoTitle id="title" title="Zen SVG Custom Component Test Page" category="Zen Test Suite" />
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="SVG Custom Component" title="SVG Custom Component" />
</locatorBar>

<spacer height="25"/>
<hgroup cellVAlign="top">
<spacer width="25"/>
<svgFrame id="svgFrame" layout="vertical"
	height="400" width="400">
<test:customSVGComponent id="myComponent"/>
</svgFrame>
</hgroup>

<hgroup>
<spacer width="25"/>
<button caption="Change Size" onclick="zenPage.changeSize();"/>
<spacer width="10"/>
<button caption="Change Style" onclick="zenPage.changeStyle();"/>
</hgroup>
</page>
}

/// Change the size of the custom SVG component.
ClientMethod changeSize() [ Language = javascript ]
{
	var svg = zenPage.getComponentById('myComponent');
	svg.setSize(Math.random()*200+ 10,Math.random()*200 + 10);
}

/// Change the style of the custom SVG component.
ClientMethod changeStyle() [ Language = javascript ]
{
	var svg = zenPage.getComponentById('myComponent');
	var style = svg.getProperty('style');
	style = ('fill: red;' == style) ? 'fill: green;' : 'fill: red;';
	svg.setProperty('style',style);
}

}

