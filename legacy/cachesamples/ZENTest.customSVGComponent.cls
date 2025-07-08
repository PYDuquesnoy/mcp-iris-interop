/// An example of a custom SVG component.
Class ZENTest.customSVGComponent Extends %ZEN.SVGComponent.svgComponent [ System = 4 ]
{

/// This is the XML namespace for this component.
Parameter NAMESPACE = "http://www.intersystems.com/zentest";

/// Additional style to apply to this shape.
Property style As %ZEN.Datatype.style;

/// SVG styles used by this component
XData SVGStyle
{
<style type="text/css">
.customSVGComponent {
	fill: url(#myGrad);
	stroke: black;
	stroke-width: 2px;
}
</style>
}

/// SVG defs used by this component.
XData SVGDef
{
<defs>
<linearGradient id="myGrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkblue" />
<stop offset="30%" style="stop-color:#FF00FF" />
<stop offset="70%" style="stop-color:#FF00FF" />
<stop offset="100%" style="stop-color:darkred" />
</linearGradient>

</defs>
}

/// Render the inner SVG contents of this component.
ClientMethod renderContents() [ Language = javascript ]
{
	// create an svg shape & set its attributes
	var rect = this.document.createElementNS(SVGNS,'rect');
	rect.setAttribute('id',this.makeId('rect'));
	rect.setAttribute('class','customSVGComponent');
	rect.setAttribute('x',0);
	rect.setAttribute('y',0);
	rect.setAttribute('width',this.width);
	rect.setAttribute('height',this.height);
	rect.setAttribute('style',this.style);

	// add to our group
	this.svgGroup.appendChild(rect);
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
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

