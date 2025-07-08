/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG indicator lamp meter.<br>
/// This meter displays a stylized lamp displaying a label. When its value
/// is above the the <property>threshholdUpper</property> value, the lamp
/// will turn on.<br>
/// This control looks best when its height is one quarter of its width.
Class %ZEN.SVGComponent.indicatorLamp Extends meter [ Deprecated, System = 3 ]
{

/// Override viewBoxWidth for this component.
Parameter DEFAULTVIEWBOXWIDTH = 100;

/// Override viewBoxHeight for this component.
Parameter DEFAULTVIEWBOXHEIGHT = 25;

/// Style applied to lamp when the meter value is below the low threshold.
Property lowStyle As %ZEN.Datatype.svgStyle [ InitialExpression = "fill: url(#glow-red);" ];

/// Style applied to lamp when the meter value is between the high and low threshold values.
Property normalStyle As %ZEN.Datatype.svgStyle [ InitialExpression = "fill: url(#glow-blue);" ];

/// Style applied to lamp when the meter value is above the high threshold.
Property highStyle As %ZEN.Datatype.svgStyle [ InitialExpression = "fill: url(#glow-green);" ];

XData SVGStyle
{
<style type="text/css">
.indicatorLamp-body {
	stroke: black;
	stroke-width: 1px;
}

.indicatorLamp-text {
	pointer-events: none;
	font-size: 10pt;
	fill: black;
	stroke: none;
	font-weight: bold;
}

</style>
}

/// Render the inner SVG contents of this component.
ClientMethod renderMeter() [ Language = javascript ]
{
	var body = this.document.createElementNS(SVGNS,'rect');
	body.setAttribute('class','indicatorLamp-body');
	body.setAttribute('fill','black');
	body.setAttribute('x',5);
	body.setAttribute('y',2.5);
	body.setAttribute('width',90);
	body.setAttribute('height',20);
	body.setAttribute('rx',2);
	this.svgGroup.appendChild(body);
	
	var rect = this.document.createElementNS(SVGNS,'rect');
	rect.setAttribute('id',this.makeId('lamp'));
	rect.setAttribute('class','indicatorLamp-body');
	rect.setAttribute('x',5);
	rect.setAttribute('y',2.5);
	rect.setAttribute('width',90);
	rect.setAttribute('height',20);
	rect.setAttribute('rx',5);
	this.svgGroup.appendChild(rect);

	// label
	var label = this.document.createElementNS(SVGNS,'text');
	label.setAttribute('id',this.makeId('label'));
	label.setAttribute('class','indicatorLamp-text');
	label.setAttribute('style',this.labelStyle);
	label.setAttribute('x',50);
	label.setAttribute('y',18);
	label.setAttribute('text-anchor','middle');

	var textNode = this.document.createTextNode(this.label);
	label.appendChild(textNode);
	this.svgGroup.appendChild(label);

	// set initial color of lamp
	this.updateLamp();
}

/// Internal method: update lamp
ClientMethod updateLamp() [ Language = javascript ]
{
	// calculate how lamp should display
	// thresholds depend on direction of range...
	var tlower = parseFloat(this.thresholdLower);
	var tupper = parseFloat(this.thresholdUpper);

	// calculate color for lamp
	var style = this.normalStyle;
	var value = parseFloat(this.value);

	if (parseFloat(this.rangeUpper) >= parseFloat(this.rangeLower)) {
		if (value <= tlower) {
			style = this.lowStyle;
		}
		else if (value >= tupper) {
			style = this.highStyle;
		}
	}
	else {
		// reverse orientation
		if (value <= tupper) {
			style = this.lowStyle;
		}
		else if (value >= tlower) {
			style = this.highStyle;
		}
	}	

	// update lamp
	var lamp = this.findSVGElement("lamp");
	lamp.setAttribute("style", style);
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {

	case 'value':
		this.value = value;
		this.updateLamp();
		break;

	case 'labelStyle':
	case 'lowStyle':
	case 'highStyle':
	case 'normalStyle':
		this[property] = value;
		this.updateLamp();
		break;

	case 'width':
	case 'height':
		return this.invokeSuper('setProperty',arguments);

	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
