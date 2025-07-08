/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Simple SVG rectangle component.<br>
/// The x and y position of the component are determined by the
/// layout provided by the svgGroup containing this component.<br>
/// Note that this is <em>not</em> the same as an SVG rect element:
/// This is a complete ZEN component with corresponding object in the
/// page object model.
Class %ZEN.SVGComponent.rect Extends svgComponent [ Deprecated, System = 3 ]
{

/// Radius of corners for rectangle.
Property rx As %ZEN.Datatype.length [ InitialExpression = 0 ];

/// Additional style to apply to this shape.
Property style As %ZEN.Datatype.svgStyle;

XData SVGStyle
{
<style type="text/css">
.rect {
	fill: blue;
	stroke: orange;
	opacity: 0.5;
}
</style>
}

/// Render the inner SVG contents of this component.
ClientMethod renderContents() [ Language = javascript ]
{
	// create rect & set its attributes
	var rect = this.document.createElementNS(SVGNS,'rect');
	rect.setAttribute('id',this.makeId('rect'));
	rect.setAttribute('class','rect');
	rect.setAttribute('x',0);
	rect.setAttribute('y',0);
	rect.setAttribute('width',this.width);
	rect.setAttribute('height',this.height);
	rect.setAttribute('rx',this.rx);
	rect.setAttribute('style',this.style);

	// add to our group
	this.svgGroup.appendChild(rect);
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'rx':
	case 'style':
		this[property] = value;
		var el = this.findSVGElement('rect');
		if (el) {
			el.setAttribute(property,value);
		}
		break;
	case 'width':
	case 'height':
		var el = this.findSVGElement('rect');
		if (el) {
			el.setAttribute(property,value);
		}
		return this.invokeSuper('setProperty',arguments);

	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
