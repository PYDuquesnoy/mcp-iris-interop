/// Simple SVG Component Layout Test page
Class ZENTest.SVGLayoutTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

/// Displayed name of this page.
Parameter PAGENAME = "SVG Layout Test";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.button {
	width: 120px;
}

#objectInspector {
	width: 24.0em;
	height: 300px;
	overflow: auto;
	border: 1px solid black;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="SVG Layout Page">
<demo:demoTitle id="title" title="Zen SVG Layout Test Page" category="Zen Test Suite" />
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="SVG Layout" title="SVG Layout" />
</locatorBar>

<spacer height="25"/>
<hgroup cellVAlign="top">
<spacer width="25"/>
<svgFrame id="svgFrame" 
   svgAutoSize="true"
	layout="horizontal"
	height="400" width="800"
	onselectItem="zenPage.itemSelected(item);"
	onmoveItem="zenPage.itemMoved();"
	onresizeItem="zenPage.itemResized();"
	 >

<!-- Set position="fixed" so that the slider will not zoom -->
<slider id="zoomInd" position="fixed" 
x="15" y="15"
height="300" width="30"
tickMarks="11"
value="4"
onchange="zenPage.sliderChange(zenThis);"
rangeLower="0" rangeUpper="11"/>

<rect id="rect1" style="fill: red;" onclick="zenPage.select(zenThis);"/>
<svgGroup id="subGroup">
<rect id="rect4" style="fill: yellow; stroke: orange;" width="50" height="50" onclick="zenPage.select(zenThis);"/>
<rect id="rect5" style="fill: black; stroke: orange;" width="50" height="50" onclick="zenPage.select(zenThis);"/>
<rect id="rect6" style="fill: plum; stroke: orange;" width="50" height="50" onclick="zenPage.select(zenThis);"/>
</svgGroup>
<rect id="rect2" style="fill: green;" onclick="zenPage.select(zenThis);" />
<rect id="rect3" style="fill: blue;" onclick="zenPage.select(zenThis);"/>
<speedometer id="speedometer" 
	animate="true"
	onclick="zenPage.select(zenThis);" 
	width="150" height="150" />
<fuelGauge id="fuelGauge" 
	animate="true"
	onclick="zenPage.select(zenThis);" 
	width="150" height="150" />

<lightBar id="lightBar" 
	animate="true"
	onclick="zenPage.select(zenThis);" 
	width="75" height="150" />
<trafficLight id="trafficLight" 
	animate="true"
	onclick="zenPage.select(zenThis);" 
	width="75" height="150" />

<smiley id="smiley" 
	onclick="zenPage.select(zenThis);" 
	width="150" height="150" />

</svgFrame>
<spacer width="25"/>

<vgroup valign="top">

<titleBox title="Attributes" />
<html enclosingClass="msg">Set attribute values of the selected shape.</html>
<objectInspector id="objectInspector" />
</vgroup>

</hgroup>

<fieldSet legend="TopMost" layout="horizontal">
<spacer width="25"/>
<radioSet
	id="topLayout"
	displayList="No layout,Vertical,Horizontal"
	valueList=",vertical,horizontal"
	value="horizontal"
	onchange="zenPage.changeLayout('svgFrame',zenThis.getValue());"/>
<spacer width="25"/>
<checkbox id="editMode" caption="Edit Mode" onchange="zenPage.editMode(zenThis);"/>
</fieldSet>

<fieldSet legend="SubGroup" layout="horizontal">
<spacer width="25"/>
<radioSet
	displayList="No layout,Vertical,Horizontal"
	valueList=",vertical,horizontal" 
	onchange="zenPage.changeLayout('subGroup',zenThis.getValue());"/>
<spacer width="25"/>
</fieldSet>
<button caption="Set Value" onclick="zenPage.applyTestValue();"/>
</page>
}

/// User has moved the zoom slider.
ClientMethod sliderChange(slider) [ Language = javascript ]
{
	var svg = zenPage.getComponentById('svgFrame');
	
	// Set the zoom level to the current slider value.
	svg.setZoomIndex(slider.value);
	zenPage.updateInspector();
}

/// Apply a random value to the current selected item.
ClientMethod applyTestValue() [ Language = javascript ]
{
	var svg = zenPage.getComponentById('svgFrame');
	var item = svg.getSelectedItem();
	if (item) {
		item.setProperty('value',Math.round(Math.random() * 100));

		zenPage.updateInspector();
	}
}

/// Toggle edit mode.
ClientMethod editMode(cb) [ Language = javascript ]
{
	var svg = zenPage.getComponentById('svgFrame');
	svg.setEditMode((cb.getValue()==1) ? 'drag' : 'none');
}

/// Change layout of specified group
ClientMethod changeLayout(groupId, type) [ Language = javascript ]
{
	var group = zenPage.getComponentById(groupId);
	group.setProperty('layout',type);
	zenPage.updateInspector();
}

/// Select the given item and set the inspector to refer to it.
ClientMethod select(item) [ Language = javascript ]
{
	// if svgFrame is in Edit mode, then clicks are intercepted
	// and this method will not be called.
	var svg = zenPage.getComponentById('svgFrame');
	svg.selectItem(item,false);
}

/// Notification that user has selected an SVG component.
ClientMethod itemSelected(item) [ Language = javascript ]
{
	var inspector = zenPage.getComponentById('objectInspector');
	if (null == item) {
		// select the svgFrame
		item = zenPage.getComponentById('svgFrame');
	}

	inspector.setCurrObject(item);
}

/// Notification that user has moved an SVG component.
ClientMethod itemMoved() [ Language = javascript ]
{
	zenPage.updateInspector();
}

/// Update the object inspector.
ClientMethod updateInspector() [ Language = javascript ]
{
	var inspector = zenPage.getComponentById('objectInspector');
	inspector.update();
}

/// Notification that user has resized an SVG component.
ClientMethod itemResized() [ Language = javascript ]
{
	zenPage.updateInspector();
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// turn off layout; turn on edit mode
	var svg = zenPage.getComponentById('svgFrame');
	svg.setProperty('layout','');
	svg.setProperty('editMode','drag');

	var ctrl = zenPage.getComponentById('topLayout');
	ctrl.setValue('');
	var ctrl = zenPage.getComponentById('editMode');
	ctrl.setValue(1);

	var inspector = this.getComponentById('objectInspector');
	inspector.setCurrObject(svg);
}

}

