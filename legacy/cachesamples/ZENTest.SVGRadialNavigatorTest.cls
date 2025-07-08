/// Test page for the <class>%ZEN.SVGComponent.radialNavigator</class> SVG Component.
Class ZENTest.SVGRadialNavigatorTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

/// Displayed name of this page.
Parameter PAGENAME = "SVG radialNavigator Test";

/// Domain used for localization.
Parameter DOMAIN = "ZENTEST";

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

.button {
	width: 120px;
}

div.objectInspectorDiv {
	width: 30.0em;
	height: 400px;
}

</style>
}

/// This XML defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="SVG radialNavigator Test Page">
<demo:demoTitle id="title" title="Zen SVG radialNavigator Test Page" category="Zen Test Suite" />
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="Radial Navigator" title="Radial Navigator Test Page" />
</locatorBar>

<spacer height="25"/>
<hgroup>
<spacer width="25"/>
<svgFrame id="svgFrame" layout="vertical"
	height="500" width="500">
<radialNavigator id="navigator" mainLabel="Navigator"
	height="500" width="500" 
>
<radialNode caption="Node 1" style="fill: green;"/>
<radialNode caption="Node 2"/>
<radialNode caption="Node 3"/>
</radialNavigator>
</svgFrame>

<spacer width="20"/>

<vgroup valign="top">

<titleBox title="Attributes" />
<html enclosingClass="msg">Set attribute values of the Navigator.</html>
<objectInspector id="objectInspector" />
</vgroup>
</hgroup>

<hgroup>
<spacer width="25"/>
<button caption="Client Update" onclick="zenPage.clientUpdate();"/>
<spacer width="10"/>
<button caption="Server Update" onclick="zenPage.serverUpdate();"/>
</hgroup>
</page>
}

/// clientUpdate.
ClientMethod clientUpdate() [ Language = javascript ]
{
	var nav = zenPage.getComponentById('navigator');
	var node = zenPage.createComponent('radialNode');
	node.caption = 'New Node';
	nav.appendNode(node);
}

/// serverUpdate: call server method to update Navigator
ClientMethod serverUpdate() [ Language = javascript ]
{
	//cspRunServerDebugWindow = true;
	var nav = zenPage.getComponentById('navigator');
	nav.clearNodes();
	var ok = this.UpdateNav(nav);
	nav.renderContents();
}

/// Rebuild the array of nodes used by the Navigator
ClassMethod UpdateNav(nav As %ZEN.SVGComponent.radialNavigator) As %Boolean [ ZenMethod ]
{
	//Set tOld = nav.nodes.Count()
	//Do nav.nodes.Clear()
	
	#Dim %page As %ZEN.Component.page
	
	Set tCount = $R(10 + 20)
	
	For n=1:1:tCount {
		Set tNode = ##class(%ZEN.Auxiliary.radialNode).%New()
		Do %page.%AddComponent(tNode)
		Set tNode.caption = "Node " _ $R(999)
		Do nav.nodes.Insert(tNode)
	}

	Quit 1
}

/// Select the Navigator for inspecting.
ClientMethod onloadHandler() [ Language = javascript ]
{
	var inspector = zenPage.getComponentById('objectInspector');
	var nav = zenPage.getComponentById('navigator');
	inspector.setCurrObject(nav);
}

}

