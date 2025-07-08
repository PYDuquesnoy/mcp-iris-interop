/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG tabBar control
Class %ZEN.SVGComponent.tabBar Extends svgComponent [ Deprecated, System = 3 ]
{

/// height of the total tab header
Property height As %ZEN.Datatype.length [ InitialExpression = 32 ];

/// the maximum width of the tabs (from bottom to bottom) as multiples of the height
Property maxOneTabWidth As %ZEN.Datatype.integer [ InitialExpression = 200 ];

/// the index of the selected tab
Property selectedIndex As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// The captions for the tabs. The first character is the string separator.
Property tabCaptions As %ZEN.Datatype.caption;

/// The method to call after the selected tab is changed
Property onChange As %ZEN.Datatype.eventHandler;

/// is this property is true, then users are allowed to add and remove tabs.
Property dynamic As %ZEN.Datatype.boolean;

/// The method to call after a tab is deleted
Property onDeleteTab As %ZEN.Datatype.eventHandler;

/// The method to call after a new tab is added
Property onNewTab As %ZEN.Datatype.eventHandler;

XData SVGStyle
{
<style type="text/css">
.tabBarFrontTab   { fill:#FFFFFF; stroke:#888888; }
.tabBarBackTabs   { fill:#C0D9F8; stroke:#888888; }
.tabBarBackground { fill:#A5BFE4; stroke:#A5BFE4; }
.tabBarBaseline   { fill:#888888; stroke:#888888; }
.tabBarCaption    { fill:#000000; stroke:none; font-family:arial; font-size:9pt; }
.tabBarButtonFore      { fill:#888888; stroke:#888888; }
.tabBarButtonDotFront  { fill:#FFFFFF; stroke:#FFFFFF; }
.tabBarButtonDotBack   { fill:#C0D9F8; stroke:#C0D9F8; }
.tabBarButtonForeHover { fill:#FFFFFF; stroke:#FFFFFF; }
.tabBarButtonDotHover  { fill:#AAAAAA; stroke:#AAAAAA; }
</style>
}

/// Render the inner SVG contents of this component.
ClientMethod renderContents() [ Language = javascript ]
{
	this.drawTabs();
}

ClientMethod drawTabs() [ Language = javascript ]
{
	var tabDataArray = this.tabCaptions.substr(1).split(this.tabCaptions.substr(0,1));
	var TABAREAHEIGHT = parseInt(this.height);
	// TABOVERLAP is the amount the front tab covers the back tab
	var TABOVERLAP = TABAREAHEIGHT*0.4;
	var tabCount = tabDataArray.length;
	// tabWidth is the width of a tab. From botton left tip to bottom right tip
	var tabWidth = Math.min((this.width-100+(tabCount-1)*TABOVERLAP)/tabCount,this.maxOneTabWidth);

	// if there is no svgGroup, we can't do anything
	if ( !this.svgGroup ) { return; }

	// remove all children
	for ( var child = this.svgGroup.firstChild; child != null ; child = this.svgGroup.firstChild ) {
		this.svgGroup.removeChild(child);
	}
	// draw background
	var rect = this.document.createElementNS(SVGNS,"rect");
	rect.setAttribute("x",0);
	rect.setAttribute("y",0);
	rect.setAttribute("width",this.width);
	rect.setAttribute("height",TABAREAHEIGHT);
	rect.setAttribute("class","tabBarBackground");
	this.svgGroup.appendChild(rect);

	// normalize this.selectedIndex
	this.selectedIndex = parseInt(this.selectedIndex);
	// draw un-focused tabs
	for ( var i=0 ; i<this.selectedIndex ; i++ ) {
		this.drawOneTab(i,tabWidth,false);
	}
	for ( var i=tabDataArray.length-1 ; i>this.selectedIndex ; i-- ) {
		this.drawOneTab(i,tabWidth,false);
	}
	// draw focused tab
	this.drawOneTab(this.selectedIndex,tabWidth,true);
	// draw plus
	if ( this.dynamic ) {
		this.drawPlus(tabWidth);
	}
	// draw the base line, there are 2 sections
	var line = this.document.createElementNS(SVGNS,"line");
	line.setAttribute("x1",0);
	line.setAttribute("y1",TABAREAHEIGHT);
	line.setAttribute("x2",(this.selectedIndex)*(tabWidth-TABOVERLAP));
	line.setAttribute("y2",TABAREAHEIGHT);
	line.setAttribute("class","tabBarBaseline");
	this.svgGroup.appendChild(line);
	var line = this.document.createElementNS(SVGNS,"line");
	line.setAttribute("x1",(this.selectedIndex)*(tabWidth-TABOVERLAP)+tabWidth);
	line.setAttribute("y1",TABAREAHEIGHT);
	line.setAttribute("x2",this.width);
	line.setAttribute("y2",TABAREAHEIGHT);
	line.setAttribute("class","tabBarBaseline");
	this.svgGroup.appendChild(line);
	return;
}

ClientMethod drawOneTab(index, tabWidth, isActive) [ Language = javascript ]
{
	var tabDataArray = this.tabCaptions.substr(1).split(this.tabCaptions.substr(0,1));
	var TABAREAHEIGHT = parseInt(this.height);
	var TABHEIGHT = TABAREAHEIGHT*0.8;			// height of the individual tabs
	var TABRADIUS = TABAREAHEIGHT;				// the radius of the tab side curve
	var TABTOPREDUCTION = TABAREAHEIGHT*0.8;	// The amout the tab top width is smaller than the bottom width
	var TABTEXTMARGIN = TABAREAHEIGHT*0.5;		// the margin of tha tab text
	var TABOVERLAP = TABAREAHEIGHT*0.4;			// the amount the top tab covers the bottom tab

	if ( index<0 ) return;
	if ( index>tabDataArray.length ) return;

	var name = tabDataArray[index];
	var caption = name;
	var x = index*(tabWidth-TABOVERLAP);
	var buttonWidth = this.dynamic?TABHEIGHT:0;

	var group = this.document.createElementNS(SVGNS,"g");
	group.setAttribute("onclick","zenPage.getComponent("+this.index+").tabClicked("+index+");");
	this.svgGroup.appendChild(group);

	var path = this.document.createElementNS(SVGNS,"path");
	if ( isActive ) {
		path.setAttribute("class","tabBarFrontTab");
	} else {
		path.setAttribute("class","tabBarBackTabs");
	}
	d = "M " + x + " " + (TABAREAHEIGHT);
	d = d + " A " + TABRADIUS + " " + TABRADIUS + " 0 0 0 " + (x+(TABTOPREDUCTION)/4) + " " + (TABAREAHEIGHT-TABHEIGHT/2);
	d = d + " A " + TABRADIUS + " " + TABRADIUS + " 1 0 1 " + (x+(TABTOPREDUCTION)/2) + " " + (TABAREAHEIGHT-TABHEIGHT);
	d = d + " h " + (tabWidth-TABTOPREDUCTION);
	d = d + " A " + TABRADIUS + " " + TABRADIUS + " 1 0 1 " + (x+tabWidth-(TABTOPREDUCTION)/4) + " " + (TABAREAHEIGHT-TABHEIGHT/2);
	d = d + " A " + TABRADIUS + " " + TABRADIUS + " 0 0 0 " + (x+tabWidth) + " " + (TABAREAHEIGHT);
	path.setAttribute("d",d);
	group.appendChild(path);

	var textValue = this.document.createElementNS(SVGNS,"text");
	textValue.setAttribute("class","tabBarCaption");
	textValue.appendChild(this.document.createTextNode(caption));
	group.appendChild(textValue);
	textValue.setAttribute("x",x+TABTEXTMARGIN);

	//???? how to place the text exactly in the middle? based on the text height (which is derived from text font)?
	var bboxHeight = 0;
	try { bboxHeight = textValue.getBBox().height; } catch(err) {}
	textValue.setAttribute("y",TABAREAHEIGHT-(TABHEIGHT/2)+(bboxHeight/2)-3);

	var clipRect = this.document.getElementById("clipRect_"+(index+1));
	if ( clipRect == null ) {
		var clipDefs = this.document.createElementNS(SVGNS,"defs");
		var clipPath = this.document.createElementNS(SVGNS,"clipPath");
		clipPath.setAttribute("id","clipPath_"+(index+1));
		clipRect = this.document.createElementNS(SVGNS,"rect");
		clipRect.setAttribute("id","clipRect_"+(index+1));
		clipPath.appendChild(clipRect);
		clipDefs.appendChild(clipPath);
		this.svgGroup.appendChild(clipDefs);
	}
	clipRect.setAttribute("x",x+TABTEXTMARGIN);
	clipRect.setAttribute("y",TABAREAHEIGHT-TABHEIGHT);
	clipRect.setAttribute("height",TABHEIGHT);
	clipRect.setAttribute("width",Math.max(tabWidth-TABTEXTMARGIN*2-buttonWidth*3/4, 0));
	textValue.setAttribute("clip-path","url(#clipPath_"+(index+1)+")");

	// draw cross for deletion of the tab
	if ( this.dynamic &&  tabDataArray.length>1 ) {
		var cx = x+tabWidth-TABTEXTMARGIN/2-buttonWidth/2;
		var cy = TABAREAHEIGHT-TABHEIGHT/2;
		var dot = this.document.createElementNS(SVGNS,"circle");
		dot.setAttribute("cx",cx);
		dot.setAttribute("cy",cy);
		dot.setAttribute("r",buttonWidth/4);
		dot.setAttribute("id",this.makeId("dot-"+index))
		if ( isActive ) {
			dot.setAttribute("class","tabBarButtonDotFront");
		} else {
			dot.setAttribute("class","tabBarButtonDotBack");
		}
		group.appendChild(dot);
		var line = this.document.createElementNS(SVGNS,"line");
		line.setAttribute("x1",cx-buttonWidth/8);
		line.setAttribute("y1",cy-buttonWidth/8);
		line.setAttribute("x2",cx+buttonWidth/8);
		line.setAttribute("y2",cy+buttonWidth/8);
		line.setAttribute("id",this.makeId("lineA-"+index))
		line.setAttribute("class","tabBarButtonFore");
		group.appendChild(line);
		var line = this.document.createElementNS(SVGNS,"line");
		line.setAttribute("x1",cx-buttonWidth/8);
		line.setAttribute("y1",cy+buttonWidth/8);
		line.setAttribute("x2",cx+buttonWidth/8);
		line.setAttribute("y2",cy-buttonWidth/8);
		line.setAttribute("id",this.makeId("lineB-"+index))
		line.setAttribute("class","tabBarButtonFore");
		group.appendChild(line);
		// this is the cover circle that handles all the moue events
		var dot = this.document.createElementNS(SVGNS,"circle");
		dot.setAttribute("cx",cx);
		dot.setAttribute("cy",cy);
		dot.setAttribute("r",buttonWidth/4);
		dot.setAttribute("style","opacity:0.01");
		dot.setAttribute("onmouseover","zenPage.getComponent("+this.index+").buttonMouseOver("+index+");");
		dot.setAttribute("onmouseout","zenPage.getComponent("+this.index+").buttonMouseOut("+index+");");
		dot.setAttribute("onclick","zenPage.getComponent("+this.index+").buttonDeleteClicked("+index+");");
		group.appendChild(dot);
	}
	return;
}

ClientMethod drawPlus(tabWidth) [ Language = javascript ]
{
	var tabDataArray = this.tabCaptions.substr(1).split(this.tabCaptions.substr(0,1));
	var TABAREAHEIGHT = parseInt(this.height);
	var TABHEIGHT = TABAREAHEIGHT*0.8;			// height of the individual tabs
	var TABRADIUS = TABAREAHEIGHT;				// the radius of the tab side curve
	var TABTOPREDUCTION = TABAREAHEIGHT*0.8;	// The amout the tab top width is smaller than the bottom width
	var TABTEXTMARGIN = TABAREAHEIGHT*0.5;		// the margin of tha tab text
	var TABOVERLAP = TABAREAHEIGHT*0.4;			// the amount the top tab covers the bottom tab

	var index = tabDataArray.length;
	var x = index*(tabWidth-TABOVERLAP);
	var buttonWidth = TABHEIGHT;

	var group = this.document.createElementNS(SVGNS,"g");
	this.svgGroup.appendChild(group);

	// draw plus for adding new tab
	if ( this.dynamic ) {
		var cx = x+TABTEXTMARGIN/2+buttonWidth/2;
		var cy = TABAREAHEIGHT-TABHEIGHT/2;
		var dot = this.document.createElementNS(SVGNS,"circle");
		dot.setAttribute("cx",cx);
		dot.setAttribute("cy",cy);
		dot.setAttribute("r",buttonWidth/4);
		dot.setAttribute("id",this.makeId("dot-"+index))
		dot.setAttribute("class","tabBarButtonDotBack");
		group.appendChild(dot);
		var line = this.document.createElementNS(SVGNS,"line");
		line.setAttribute("x1",cx-buttonWidth/8);
		line.setAttribute("y1",cy);
		line.setAttribute("x2",cx+buttonWidth/8);
		line.setAttribute("y2",cy);
		line.setAttribute("id",this.makeId("lineA-"+index))
		line.setAttribute("class","tabBarButtonFore");
		group.appendChild(line);
		var line = this.document.createElementNS(SVGNS,"line");
		line.setAttribute("x1",cx);
		line.setAttribute("y1",cy-buttonWidth/8);
		line.setAttribute("x2",cx);
		line.setAttribute("y2",cy+buttonWidth/8);
		line.setAttribute("id",this.makeId("lineB-"+index))
		line.setAttribute("class","tabBarButtonFore");
		group.appendChild(line);
		// this is the cover circle that handles all the moue events
		var dot = this.document.createElementNS(SVGNS,"circle");
		dot.setAttribute("cx",cx);
		dot.setAttribute("cy",cy);
		dot.setAttribute("r",buttonWidth/4);
		dot.setAttribute("style","opacity:0.01");
		dot.setAttribute("onmouseover","zenPage.getComponent("+this.index+").buttonMouseOver("+index+");");
		dot.setAttribute("onmouseout","zenPage.getComponent("+this.index+").buttonMouseOut("+index+");");
		dot.setAttribute("onclick","zenPage.getComponent("+this.index+").buttonNewClicked("+index+");");
		group.appendChild(dot);
	}
	return;
}

ClientMethod buttonMouseOver(index) [ Language = javascript ]
{
	this.document.getElementById(this.makeId("dot-"+index)).setAttribute("class","tabBarButtonDotHover");
	this.document.getElementById(this.makeId("lineA-"+index)).setAttribute("class","tabBarButtonForeHover");
	this.document.getElementById(this.makeId("lineB-"+index)).setAttribute("class","tabBarButtonForeHover");
	return;
}

ClientMethod buttonMouseOut(index) [ Language = javascript ]
{
	if ( index == this.selectedIndex ) {
		this.document.getElementById(this.makeId("dot-"+index)).setAttribute("class","tabBarButtonDotFront");
	} else {
		this.document.getElementById(this.makeId("dot-"+index)).setAttribute("class","tabBarButtonDotBack");
	}
	this.document.getElementById(this.makeId("lineA-"+index)).setAttribute("class","tabBarButtonFore");
	this.document.getElementById(this.makeId("lineB-"+index)).setAttribute("class","tabBarButtonFore");
	return;
}

ClientMethod buttonDeleteClicked(index) [ Language = javascript ]
{
	var delimiter = this.tabCaptions.substr(0,1);
	var array = this.tabCaptions.substr(1).split(delimiter);
	var caption = array.splice(index,1);
	this.tabCaptions = delimiter + array.join(delimiter);
	if ( this.selectedIndex>=array.length ) { this.selectedIndex = array.length-1; }
	this.drawTabs();
	this.skipTabClicked = true;
	;
	var callbackHandler = this.onDeleteTab;
	if ( callbackHandler.substr(0,7) != "return " ) { callbackHandler = "return " + callbackHandler; }
	zenInvokeCallbackMethod(callbackHandler,this,"onDeleteTab","index",index,"caption",caption);
	;
	return;
}

ClientMethod buttonNewClicked(index) [ Language = javascript ]
{
	var delimiter = this.tabCaptions.substr(0,1);
	var array = this.tabCaptions.substr(1).split(delimiter);
	array.splice(array.length,0,$$$Text("New Tab"));
	this.tabCaptions = delimiter + array.join(delimiter);
	this.drawTabs();
	;
	var callbackHandler = this.onNewTab;
	if ( callbackHandler.substr(0,7) != "return " ) { callbackHandler = "return " + callbackHandler; }
	zenInvokeCallbackMethod(callbackHandler,this,"onNewTab","index",index);
	;
	return;
}

ClientMethod tabClicked(index) [ Language = javascript ]
{
	var skipTabClick = this.skipTabClicked
	this.skipTabClicked = false;
	if ( skipTabClick ) { return; }
	;
	this.selectedIndex = index;
	this.drawTabs();
	;
	var callbackHandler = this.onChange;
	if ( callbackHandler.substr(0,7) != "return " ) { callbackHandler = "return " + callbackHandler; }
	zenInvokeCallbackMethod(callbackHandler,this,"onChange","index",index);
	;
	return;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var value = this.invokeSuper("setProperty",arguments);
	this.drawTabs();
	return value;
}

}
