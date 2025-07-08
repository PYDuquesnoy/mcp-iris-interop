/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A set of SVG-based compass buttons: a set of buttons used
/// for scrolling a region in any of four directions.<br>
Class %ZEN.SVGComponent.compassButtons Extends svgComponent [ Deprecated, System = 3 ]
{

Parameter DEFAULTBOUNDLESS = 1;

/// onbuttonClick event handler:
/// This event handler is called when the user clicks on one of 
/// the buttons displayed by this component.
/// The variable, <var>direction</var>, is passed to the callback and
/// corresponds to which button was pressed. Possible values are:
/// "up","down","left","right",and "home".
Property onbuttonClick As %ZEN.Datatype.eventHandler;

XData SVGStyle
{
<style type="text/css">
.compassButton {
	fill: white;
	stroke: black;
	stroke-width: 1;
}

.compassButtonHover {
	fill: #FFFFB0;
	stroke: black;
	stroke-width: 2;
	cursor: pointer;
}

.compassIcon {
	fill: none;
	stroke: black;
	stroke-width: 1;
}
</style>
}

/// Render the inner SVG contents of this component.
ClientMethod renderContents() [ Language = javascript ]
{
	// render buttons centered on 0,0
	this.renderButton('home',0,0);
	this.renderButton('up',0,-20);
	this.renderButton('down',0,20);
	this.renderButton('left',-20,0);
	this.renderButton('right',20,0);
}

/// Render a single compass button.
ClientMethod renderButton(direction, x, y) [ Language = javascript ]
{
	var wid = 16;
	var hgt = 16;
	
	var rect = this.document.createElementNS(SVGNS,'rect');
	rect.setAttribute('id',this.makeId(direction));
	rect.setAttribute('class','compassButton');
	rect.setAttribute('x',x - wid/2);
	rect.setAttribute('y',y - hgt/2);
	rect.setAttribute('width',wid);
	rect.setAttribute('height',hgt);
	rect.setAttribute('rx',1);
	this.svgGroup.appendChild(rect);

	var icon = null;
	switch(direction) {
	case 'left':
		icon = this.document.createElementNS(SVGNS,'path');
		icon.setAttribute('d','M '+(x+4)+' '+y+' L '+(x-4)+' '+y+'M '+x+' '+(y-4)+' L '+(x-4)+' '+y+' '+x+' '+(y+4));
		break;
	case 'right':
		icon = this.document.createElementNS(SVGNS,'path');
		icon.setAttribute('d','M '+(x-4)+' '+y+' L '+(x+4)+' '+y+'M '+x+' '+(y-4)+' L '+(x+4)+' '+y+' '+x+' '+(y+4));
		break;
	case 'up':
		icon = this.document.createElementNS(SVGNS,'path');
		icon.setAttribute('d','M '+(x)+' '+(y+4)+' L '+(x)+' '+(y-4)+'M '+(x-4)+' '+(y)+' L '+(x)+' '+(y-4)+' '+(x+4)+' '+(y));
		break;
	case 'down':
		icon = this.document.createElementNS(SVGNS,'path');
		icon.setAttribute('d','M '+(x)+' '+(y-4)+' L '+(x)+' '+(y+4)+'M '+(x-4)+' '+(y)+' L '+(x)+' '+(y+4)+' '+(x+4)+' '+(y));
		break;
	case 'home':
		icon = this.document.createElementNS(SVGNS,'circle');
		icon.setAttribute('cx',x);
		icon.setAttribute('cy',y);
		icon.setAttribute('r',wid/4);
		break;
	}

	if (icon) {
		icon.setAttribute('class','compassIcon');
		this.svgGroup.appendChild(icon);
		icon.addEventListener('click',new Function('evt','direction','return zenPage.getComponent('+this.index+').clickHandler(evt,"'+direction+'");'),false);
	}

	rect.addEventListener('click',new Function('evt','direction','return zenPage.getComponent('+this.index+').clickHandler(evt,"'+direction+'");'),false);
	rect.addEventListener('mouseover',new Function('evt','direction','return zenPage.getComponent('+this.index+').mouseoverHandler(evt,"'+direction+'");'),false);
	rect.addEventListener('mouseout',new Function('evt','direction','return zenPage.getComponent('+this.index+').mouseoutHandler(evt,"'+direction+'");'),false);
	return rect;
}

/// Click handler for buttons.
ClientMethod clickHandler(evt, direction) [ Language = javascript ]
{
	evt.stopPropagation();
	return zenInvokeCallbackMethod(this.onbuttonClick,this,'onbuttonClick','direction',direction);
}

/// Mouseover handler for buttons.
ClientMethod mouseoverHandler(evt, direction) [ Language = javascript ]
{
	evt.stopPropagation();
	evt.target.setAttribute('class','compassButtonHover');
}

/// Mouseout handler for buttons.
ClientMethod mouseoutHandler(evt, direction) [ Language = javascript ]
{
	evt.stopPropagation();
	evt.target.setAttribute('class','compassButton');
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
