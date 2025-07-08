/// This page uses the SVG Owner Draw component to create a 
/// simple object browser.
Class ZENDemo.SVGBrowser Extends %ZEN.Component.page
{

/// Class name of application this page belongs to.
Parameter APPLICATION = "ZENDemo.Application";

/// Displayed name of this page.
Parameter PAGENAME = "Zen Visual Navigator";

/// Domain used for localization.
Parameter DOMAIN;

/// Id of current item in the diagram.
Property currItemId As %ZEN.Datatype.string(ZENURL = "ID");

/// Id of last visited item in the diagram.
Property lastItemId As %ZEN.Datatype.string;

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
#cityForm {
	background: #404040;
	background-image: url(images/grad-gray-10x500.png);
	background-repeat: repeat-x;
}
</style>
}

/// This XML block defines the contents of this page.
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" xmlns:demo="http://www.intersystems.com/zendemo" title="Zen Visual Navigator Demo">
<demo:demoTitle id="title" title="Zen Visual Navigator"/>
<locatorBar id="locator" OnGetQuickLinks="GetQuickLinks">
<locatorLink caption="Home" title="Home page" href="ZENDemo.Home.cls"/>
<locatorLink caption="Visual Navigator" title="Visual Navigator Demo" />
</locatorBar>

<hgroup>
<vgroup valign="top">
<demo:sidebar text="This Zen page demonstrates the following features:">
<demo:bullet text="Using the SVG userDraw component to create rich graphics" />
<demo:bullet text="Use of server-side methods to update the diagram" />
</demo:sidebar>
</vgroup>

<vgroup valign="top">
<svgFrame id="svgFrame" layout="vertical"
	height="500" width="500" zoomWithWheel="true">
<ownerDraw id="diagram"
	height="500" width="500"
	onrender="zenPage.drawDiagram(zenThis);"/>
</svgFrame>
</vgroup>
<vgroup valign="top">

<form id="cityForm" 
	width="100%" 
	layout="vertical" 
	cellStyle="padding: 4px; padding-left: 5px; padding-right: 5px;" 
	groupStyle="border:1px solid black;">
<titleBox title="City Statistics" titleStyle="background: #CCCCFF;" containerStyle="padding: 0px;" />
<spacer height="5"/>

<text label="Name:" id="Name" name="Name" size="20" readOnly="true"/>
<text label="Population:" id="Population" name="Population" size="20" readOnly="true"/>
<label id="Status" label="Status:" value="OK"/>
</form>

</vgroup>

</hgroup>
</page>
}

/// Update contents of Owner-draw svg component.
ClientMethod selectItem(id) [ Language = javascript ]
{
	this.lastItemId = this.currItemId;
	this.currItemId = id;

	var svg = zenPage.getComponentById('diagram');
	svg.render();
}

/// Owner-draw notification for diagram component.
ClientMethod drawDiagram(svg) [ Language = javascript ]
{
	zenPage.getComponentById('Status').setValue('loading');

	// Get new contents from the server
	this.GetDiagramContents(this.currItemId, this.lastItemId,svg.index);
}

/// Execute server-logic to get SVG contents for Owner-draw component.
ClassMethod GetDiagramContents(pID As %String, pLastID As %String, pIndex As %Integer) [ ZenMethod ]
{
	#; construct a model
	Do ..CreateModel(pID, .tModel)

	#; draw the model
	Do ..CreateDiagram(pIndex, .tModel, pLastID)

	#; update form
	Set tName = pID
	Set tPop = +$G(tModel("Population"))
	&js<
		zenPage.getComponentById('Name').setValue('#(tName)#');
		zenPage.getComponentById('Population').setValue('#(tPop)#');
		zenPage.getComponentById('Status').setValue('OK');
	>
}

/// Create an array that describes the model to be diagrammed.
ClassMethod CreateModel(pID As %String, Output pModel)
{
	#; make sure we have data
	If '$D(^SVGBrowser) {
		Do ..BuildData()
	}

	#; if no id, find first item and use that
	If (pID = "") {
		Set pID = $O(^SVGBrowser(""))
	}

	#; make sure id exists
	If '$D(^SVGBrowser(pID)) {
		Quit
	}

	#; top node
	Set pModel("id") = pID
	Set pModel("Population") = +$G(^SVGBrowser(pID))
	
	#; child nodes: walk down ^SVGBrowser global
	Set n = 0
	Set key = $O(^SVGBrowser(pID,""))
	While (key '= "") {
		#; note that id and label are the same in this case
		Set n = n + 1
		Set pModel("ch",n) = ""
		Set pModel("ch",n,"id") = key
		Set pModel("ch",n,"label") = key

		#; how many connections does this item have?
		Set c = 0
		Set k2 = $O(^SVGBrowser(key,""))
		While (k2 '= "") {
			Set c = c + 1
			Set k2 = $O(^SVGBrowser(key,k2))
		}

		Set:c>1 pModel("ch",n,"count") = c - 1

		Set key = $O(^SVGBrowser(pID,key))
	}
}

/// Given a simple model, draw it by sending
/// JavaScript back to the client.
ClassMethod CreateDiagram(pIndex As %Integer, ByRef pModel, pLastID As %String = "")
{
	#; get the svg component
	&js<var svg = zenPage.getComponent(#(pIndex)#);>

	#; get size of model (number of children)
	Set tSize = $O(pModel("ch",""),-1)

	Set tWidth = 500
	Set tHeight = 500
	Set tRadius = 100
	
	#; in some case, slide over line from label to center
	Set adj = $S(tSize#4=0:45,1:0)	

	#; execute JS to create contents
	#; background
	&js<
		var rect = svg.document.createElementNS(SVGNS,'rect');
		rect.setAttribute('x',0);
		rect.setAttribute('y',0);
		rect.setAttribute('width',#(tWidth)#);
		rect.setAttribute('height',#(tHeight)#);
		rect.setAttribute('style','fill: url(#glow-blueDiag); stroke: gray; stroke-width: 1;');
		svg.svgGroup.appendChild(rect);

		// connector to main label
		var line = svg.document.createElementNS(SVGNS,'line');
		line.setAttribute('x1',#(tWidth/2)#);
		line.setAttribute('y1',#(tHeight/2)#);
		line.setAttribute('x2',#((tWidth/2)-adj)#);
		line.setAttribute('y2',#(28)#);
		line.setAttribute('style','#("fill: none; stroke: black; stroke-width: 2; stroke-dasharray: 4,4;")#');
		svg.svgGroup.appendChild(line);

		// main label
		var text = svg.document.createElementNS(SVGNS,'text');
		text.setAttribute('x',#((tWidth/2)-adj)#);
		text.setAttribute('y',#(25)#);
		text.setAttribute('style','fill: yellow; stroke: none; font-size: 18pt; font-weight: bold;');
		text.setAttribute('text-anchor','middle');

		var textNode = svg.document.createTextNode('#($G(pModel("id")))#');
		text.appendChild(textNode);

		svg.svgGroup.appendChild(text);

		// set up group for coord space
		var group = svg.document.createElementNS(SVGNS,'g');
		group.setAttribute('transform','translate(#(tWidth/2)#,#(tHeight/2)#)');
		svg.svgGroup.appendChild(group);
	>

	#; items

	#; first, draw connectors
	If (tSize > 0) {
		For n = 1:1:tSize {
			Set tAngle = (n-1) * (($ZPI*2)/tSize)
			Do ..DrawConnector(tAngle,+$G(pModel("ch",n,"count")))
		}
	}


	#; main item
	Set id = $G(pModel("id"))
	Do ..DrawItem(id,"main")

	#; related items
	If (tSize > 0) {
		For n = 1:1:tSize {
			Set id = $G(pModel("ch",n,"id"))
			Set label = $G(pModel("ch",n,"label"))
			Set tAngle = (n-1) * (($ZPI*2)/tSize)
			Set tType = $S(pLastID=id:"last",1:"link")
			Do ..DrawItem(id,tType,tAngle,label)
		}
	}

	Quit
}

/// Create svg for a specific connector in the diagram
ClassMethod DrawConnector(pAngle As %Float, pCount As %Integer = 0)
{
	Set tRadius = 100
	Set x = $zcos(pAngle) * tRadius
	Set y = $zsin(pAngle) * tRadius

	&js<
		var line = svg.document.createElementNS(SVGNS,'line');
		line.setAttribute('x1',0);
		line.setAttribute('y1',0);
		line.setAttribute('x2',#(+x)#);
		line.setAttribute('y2',#(+y)#);
		line.setAttribute('style','#("fill: none; stroke: black; stroke-width: 2;")#');
		group.appendChild(line);
	>

	For n = 1:1:pCount {
		
		Set range = (pCount-1) * 10
		
		Set off = (((n-1) * (range/pCount)) - (range/2)) * ($ZPI/180)
		Set a = pAngle + off
		Set x2 = x + ($zcos(a) * 60)
		Set y2 = y + ($zsin(a) * 60)
		
		&js<
			var line = svg.document.createElementNS(SVGNS,'line');
			line.setAttribute('x1',#(+x)#);
			line.setAttribute('y1',#(+y)#);
			line.setAttribute('x2',#(+x2)#);
			line.setAttribute('y2',#(+y2)#);
			line.setAttribute('style','#("fill: none; stroke: red; opacity: 0.9; stroke-width: 1; stroke-dasharray: 2,4;")#');
			group.appendChild(line);
		>
	}
}

/// Create svg for a specific item in the diagram
ClassMethod DrawItem(pID As %String, pType As %String, pAngle As %Float = 0, pLabel As %String = "")
{
	Set tRadius = 100
	If (pType = "main") {
		Set x = 0
		Set y = 0
		Set tFill = "url(#glow-yellow)"
		Set tSize = 18
	}
	ElseIf (pType = "last") {
		Set x = $zcos(pAngle) * tRadius
		Set y = $zsin(pAngle) * tRadius
		Set tFill = "url(#glow-orange)"
		Set tSize = 12
	}
	Else {
		Set x = $zcos(pAngle) * tRadius
		Set y = $zsin(pAngle) * tRadius
		Set tFill = "url(#glow-green)"
		Set tSize = 10
	}

	&js<
		var item = svg.document.createElementNS(SVGNS,'circle');
		item.setAttribute('r',#(tSize)#);
		item.setAttribute('cx',#(+x)#);
		item.setAttribute('cy',#(+y)#);
		item.setAttribute('style','#("stroke: black; stroke-width: 2;")#');
		item.setAttribute('fill','#(tFill)#');

		item.addEventListener('click',new Function('evt','return zenPage.selectItem("#(pID)#");'),false);

		item.addEventListener('mouseover',new Function('evt','evt.target.setAttribute("fill","url(#glow-purple)");'),false);
		item.addEventListener('mouseout',new Function('evt','evt.target.setAttribute("fill","#(tFill)#");'),false);
		group.appendChild(item);
	>

	If ((pType '= "main") && (pLabel '= "")) {
		Set tx = $zcos(pAngle) * (tRadius+20)
		Set ty = $zsin(pAngle) * (tRadius+20)
		
		Set tAnchor = $S((tx<2)&&(tx>-2):"middle",tx>0:"start",1:"end")
		Set yadj = $S(ty>=0:4,1:-2)
		
		&js<
			var text = svg.document.createElementNS(SVGNS,'text');
			text.setAttribute('x',#(+tx)#);
			text.setAttribute('y',#(+ty+yadj)#);
			text.setAttribute('style','#("fill: yellow; stroke: none; font-size: 12pt; font-weight: bold;")#');
			text.setAttribute('text-anchor','#(tAnchor)#');
	
			var textNode = svg.document.createTextNode('#(pLabel)#');
			text.appendChild(textNode);
	
			group.appendChild(text);
		>
	}
}

/// Build sample data for the browser
ClassMethod BuildData()
{
	#; we will create a multi-dimensional array to hold related cities

	#; kill old data
	Kill ^SVGBrowser
	
	#; create list of cities
	Set tCount = 0
	For i=1:1:50 {
		Set tCity = ##class(%PopulateUtils).City()
		If ('$D(tCityList(tCity))) {
			Set tCount = tCount + 1
			Set tCityList(tCity) = tCount
			Set tCityIndex(tCount) = tCity
		}
	}
	
	#; create connections
	Set n = $O(tCityIndex(""))
	While (n '= "") {
		Set tFrom = tCityIndex(n)
		Set ^SVGBrowser(tFrom) = $R(1000000) // population
		
		Set tConnects = $R(4) + $R(8)
		For c=1:1:tConnects {
			Set idx = $R(tCount)+1
			If (idx '= n) {
				Set tTo = $G(tCityIndex(idx))
				If (tTo '= "") {
					Set ^SVGBrowser(tFrom,tTo) = ""
					Set ^SVGBrowser(tTo,tFrom) = ""
				}
			}
		}
		Set n = $O(tCityIndex(n))
	}
}

/// Return an array of quick links to be displayed by the locator bar.
ClassMethod GetQuickLinks(Output pLinks) As %Status
{
	#; dispatch to our application class
	Quit %application.GetQuickLinks(.pLinks)
}

}

