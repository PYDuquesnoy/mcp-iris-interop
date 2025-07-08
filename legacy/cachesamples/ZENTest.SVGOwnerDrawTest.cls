/// Test page for the owner-draw SVG Component.
Class ZENTest.SVGOwnerDrawTest Extends %ZEN.Component.page
{

/// Application this page belongs to.
Parameter APPLICATION = "ZENTest.TestApplication";

/// Displayed name of this page.
Parameter PAGENAME = "SVG Owner-Draw Test";

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

/// This XML defines the contents of this page.
XData Contents
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="SVG OwnerDraw Test Page">
<demo:demoTitle id="title" title="Zen SVG OwnerDraw Test Page" category="Zen Test Suite" />
<locatorBar id="locator">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Test Suite" title="Test Suite" href="ZENTest.HomePage.cls"/>
<locatorLink caption="OwnerDraw" title="OwnerDraw Test Page" />
</locatorBar>

<spacer height="25"/>
<hgroup>
<spacer width="25"/>
<svgFrame id="svgFrame" layout="vertical"
	height="400" width="400">
<ownerDraw id="owner1"
	height="200" width="400" 
	onrender="zenPage.ownerDraw1(zenThis);"/>
<ownerDraw id="owner2"
	height="200" width="400" 
	onrender="zenPage.ownerDraw2(zenThis);"/>
</svgFrame>
</hgroup>

<hgroup>
<spacer width="25"/>
<button caption="Client Update" onclick="zenPage.update('owner1');"/>
<spacer width="10"/>
<button caption="Server Update" onclick="zenPage.update('owner2');"/>
</hgroup>
</page>
}

/// Update contents of Owner-draw svg component.
ClientMethod update(id) [ Language = javascript ]
{
	var svg = zenPage.getComponentById(id);
	svg.render();
}

/// Owner-draw notification for owner1 component.
/// This method creates content using client-side logic.
ClientMethod ownerDraw1(svg) [ Language = javascript ]
{
	// clear contents of ownerDraw component
	svg.unrender();
	
	// create a line; add it to the svg component
	for (var n = 0; n < 30; n++) {
		var line = svg.document.createElementNS(SVGNS,'line');
		line.setAttribute('x1',200);
		line.setAttribute('y1',100);
		line.setAttribute('x2',Math.random() * 400);
		line.setAttribute('y2',Math.random() * 200);
		line.setAttribute('style','stroke: blue; stroke-width: 2;');
		svg.svgGroup.appendChild(line);
	}
}

/// Owner-draw notification for owner2 component.
/// This method creates content using server-side logic.
ClientMethod ownerDraw2(svg) [ Language = javascript ]
{
	// clear contents of ownerDraw component
	svg.unrender();

	// Get new contents from the server
	this.GetSVGContents(svg.index);
}

/// Execute server-logic to get SVG contents for Owner-draw component.
ClassMethod GetSVGContents(pIndex As %Integer) [ ZenMethod ]
{
	#; get the svg component
	&js<var svg = zenPage.getComponent(#(pIndex)#);>
	
	#; execute JS to create contents
	&js<
		var rect = svg.document.createElementNS(SVGNS,'rect');
		rect.setAttribute('x',0);
		rect.setAttribute('y',0);
		rect.setAttribute('width',400);
		rect.setAttribute('height',200);
		rect.setAttribute('style','fill: blue; stroke: gray; stroke-width: 1;');
		svg.svgGroup.appendChild(rect);
	>

	#; lines
	For i=1:1:30 {
		&js<
			var line = svg.document.createElementNS(SVGNS,'circle');
			//line.setAttribute('x1',200);
			//line.setAttribute('y1',100);
			line.setAttribute('r',5);
			line.setAttribute('cx',#(10+$Random(380))#);
			line.setAttribute('cy',#(10+$Random(180))#);
			line.setAttribute('style','#("fill: yellow; stroke: black; stroke-width: 2;")#');
			svg.svgGroup.appendChild(line);
		>
	}
	Quit
}

}

