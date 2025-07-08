/// Zen SVG Slider test page.
Class ZENTest.SVGSliderTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

Parameter PAGENAME = "SVG Slider Test Page";

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
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="SVG Slider Test">
<demo:demoTitle id="title" title="Zen SVG Chart Test Page" category="Zen Test Suite" />

<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="Slider Demo" title="Slider Demo" />
</locatorBar>

<hgroup cellVAlign="top">
<demo:sidebar text="This Zen page demonstrates the following features:">
<demo:bullet text="The SVG slider component" />
<demo:bullet text="How the attributes of the Zen components can be modified dynamically" />
</demo:sidebar>

<hgroup cellVAlign="top">
<vgroup cellVAlign="top">
<svgFrame id="svgFrame" height="400" width="600" layout="horizontal">
<slider id="slider" height="400" 
onchange="zenPage.updateValue(zenThis.getValue());" 
constrained="true" rangeLower="0" rangeUpper="100"/>
<smiley id="meter" height="150" width="150"/>
</svgFrame>
<spacer height="10"/>
<hgroup labelPosition="left">
<text id="value" label="Value:" onchange="zenPage.updateSlider(zenThis.getValue());" value="0" size="5"/>
<spacer width="25"/>
<checkbox id="constrained" value="1" caption="Constrained" onclick="zenPage.setConstrained(zenThis.getValue());"/>
</hgroup>
</vgroup>
<spacer width="25"/>

<vgroup valign="top">

<titleBox title="Slider Attributes" />
<html enclosingClass="msg">Set attribute values of the slider.</html>
<objectInspector id="objectInspector" columnWidth="100"/>
</vgroup>
</hgroup>
</hgroup>
</page>
}

/// Update the contrained property of the slider.
ClientMethod setConstrained(value) [ Language = javascript ]
{
	var slider = zenPage.getComponentById('slider');
	slider.setProperty('constrained',value);
}

/// Update the value of the slider.
ClientMethod updateSlider(value) [ Language = javascript ]
{
	var slider = zenPage.getComponentById('slider');
	slider.setValue(value);

	// show new value of slider
	zenPage.updateValue(slider.getValue());
}

/// Update the value in the text box.
ClientMethod updateValue(value) [ Language = javascript ]
{
	var ctrl = zenPage.getComponentById('value');
	ctrl.setValue(value);

	var meter = zenPage.getComponentById('meter');
	meter.setValue(value);
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	zenPage.inspectElement('slider');
}

/// Point object inspector to given component.
ClientMethod inspectElement(id) [ Language = javascript ]
{
	var obj = zenPage.getComponentById(id);
	var inspector = zenPage.getComponentById('objectInspector');
	inspector.setCurrObject(obj);
}

}

