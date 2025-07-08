/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for SVG sprites.<br>
/// A sprite is a shape that can be placed on an svgCanvas
/// and connected to other sprites. Sprites form the basis of
/// an svg-based graphical editor.
Class %ZEN.SVGComponent.sprite Extends svgComponent [ Deprecated, System = 3 ]
{

/// List of input/output ports.
/// Each port is the terminator of a connection to another sprite.
Property ports As list Of port(XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

/// Radius of sprite corners.
Property rx As %ZEN.Datatype.integer(MINVAL = 0) [ InitialExpression = 0 ];

/// Additional style to apply to the primary sprite shape.
Property style As %ZEN.Datatype.svgStyle;

/// Text displayed in center of the sprite.
Property caption As %ZEN.Datatype.caption;

XData SVGStyle
{
<style type="text/css">
.sprite {
	fill: white;
	stroke: darkblue;
	stroke-width: 2px;
}
.spriteShadow {
	fill: black;
	stroke: black;
	opacity: 0.5;
	stroke-width: 1px;
}
.inputPort {
	fill: lightblue;
	stroke: darkblue;
	stroke-width: 1px;
}
.outputPort {
	fill: lightblue;
	stroke: darkblue;
	stroke-width: 1px;
}

.sprite-caption {
	pointer-events: none;
	font-size: 10pt;
	fill: black;
	stroke: none;
	font-family: "lucida sans unicode";
}

</style>
}

/// Render the inner SVG contents of this sprite.
ClientMethod renderContents() [ Language = javascript ]
{
	// create shadow rect & set its attributes
	var rect = this.document.createElementNS(SVGNS,'rect');
	rect.setAttribute('class','spriteShadow');
	rect.setAttribute('rx',this.rx);
	rect.setAttribute('x',12);
	rect.setAttribute('y',12);
	rect.setAttribute('width',this.width-20);
	rect.setAttribute('height',this.height-20);
	this._svgShadowRect = rect;

	// add to our group
	this.svgGroup.appendChild(rect);

	// create sprite rect & set its attributes
	// this is inset from our bounding rect
	var rect = this.document.createElementNS(SVGNS,'rect');
	rect.setAttribute('class','sprite');
	rect.setAttribute('style',this.style);
	rect.setAttribute('rx',this.rx);
	rect.setAttribute('x',10);
	rect.setAttribute('y',10);
	rect.setAttribute('width',this.width-20);
	rect.setAttribute('height',this.height-20);
	this._svgShape = rect;

	// add to our group
	this.svgGroup.appendChild(rect);

	// caption
	var caption = this.document.createElementNS(SVGNS,'text');
	caption.setAttribute('id',this.makeId('caption'));
	caption.setAttribute('class','sprite-caption');
	caption.setAttribute('x',this.width / 2);
	caption.setAttribute('y',this.height / 2);
	caption.setAttribute('text-anchor','middle');

	var textNode = this.document.createTextNode(this.caption);
	caption.appendChild(textNode);
	this.svgGroup.appendChild(caption);

	this._caption = caption;

	// create ports
	this.createPorts();
}

/// Create the set of ports for this sprite.
ClientMethod createPorts() [ Language = javascript ]
{
	this.createPort('input',this.width/2,5);
	this.createPort('output',this.width/2,this.height-5);
	this.createPort('input2',5,this.height/2);
	this.createPort('output2',this.width-5,this.height/2);
}

/// Create a port for this sprite.
ClientMethod createPort(type, x, y) [ Language = javascript ]
{
	var port = zenPage.createComponent('port');
	if (port) {
		port.type = type;
		port.x = x;
		port.y = y;
		port._sprite = this;
		this.ports[this.ports.length] = port;
		port.renderPort(this.svgGroup);
	}
}

/// Get the specificied port by port number (0-based).
ClientMethod getPort(portno) [ Language = javascript ]
{
	return this.ports[portno];
}

/// Notification that this component has been moved.
ClientMethod setPositionHandler() [ Language = javascript ]
{
	this.updateConnectors();
}

/// Notification that this component has been resized.
ClientMethod setSizeHandler() [ Language = javascript ]
{
	// adjust position/size of sprite
	if (this._svgShape) {
		this._svgShape.setAttribute('x',10);
		this._svgShape.setAttribute('y',10);
		this._svgShape.setAttribute('width',this.width-20);
		this._svgShape.setAttribute('height',this.height-20);

		if (this._svgShadowRect) {
			this._svgShadowRect.setAttribute('x',12);
			this._svgShadowRect.setAttribute('y',12);
			this._svgShadowRect.setAttribute('width',this.width-20);
			this._svgShadowRect.setAttribute('height',this.height-20);
		}

		if (this._caption) {
			this._caption.setAttribute('x',this.width / 2);
			this._caption.setAttribute('y',this.height / 2);
		}			

		// move ports
		var port;
		port = this.getPort(0);
		if (port) {
			port.setProperty('x',this.width/2);
		}

		port = this.getPort(1);
		if (port) {
			port.setProperty('x',this.width/2);
			port.setProperty('y',this.height - 5);
		}

		port = this.getPort(2);
		if (port) {
			port.setProperty('x',5);
			port.setProperty('y',this.height/2);
		}

		port = this.getPort(3);
		if (port) {
			port.setProperty('x',this.width-5);
			port.setProperty('y',this.height/2);
		}
	}	

	// update connectors
	this.updateConnectors();
}

/// Internal method: update position of all connectors
/// attached to this sprite.
ClientMethod updateConnectors() [ Language = javascript ]
{
	for (var n = 0; n < this.ports.length; n++) {
		var port = this.ports[n];
		port.updateConnectors();
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'style':
		this.style = value;
		if (this._svgShape) {
			this._svgShape.setAttribute('style',this.style);
		}
		break;
	case 'caption':
		this.caption = value;
		this.setTextNode('caption',this.caption);
		break;
	case 'rx':
		this.rx = parseInt(value,10);
		if (this._svgShape) {
			this._svgShape.setAttribute('rx',this.rx);
		}
		if (this._svgShadowRect) {
			this._svgShadowRect.setAttribute('rx',this.rx);
		}
		break;
	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
