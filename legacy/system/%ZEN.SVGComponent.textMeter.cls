/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG text meter.<br/>
/// This meter displays a value as text within a rectangular region.<br/>
/// This control looks best when its height is one quarter of its width.
Class %ZEN.SVGComponent.textMeter Extends meter [ Deprecated, System = 3 ]
{

/// Override viewBoxWidth for this component.
Parameter DEFAULTVIEWBOXWIDTH = 100;

/// Override viewBoxHeight for this component.
Parameter DEFAULTVIEWBOXHEIGHT = 25;

/// Additional style applied to the background of this meter.
Property backgroundStyle As %ZEN.Datatype.svgStyle;

/// Numeric format string to apply to the value.
Property format As %ZEN.Datatype.string;

/// Style applied to text when the meter value is below the low threshold.
Property lowStyle As %ZEN.Datatype.svgStyle [ InitialExpression = "fill: #804040;" ];

/// Style applied to text when the meter value is between the high and low threshold values.
Property normalStyle As %ZEN.Datatype.svgStyle [ InitialExpression = "fill: #404040;" ];

/// Style applied to text when the meter value is above the high threshold.
Property highStyle As %ZEN.Datatype.svgStyle [ InitialExpression = "fill: #404080;" ];

XData SVGStyle
{
<style type="text/css">
.textMeter-body {
	stroke: #808080;
	stroke-width: 0.5px;
	fill: white;
}

/* value text */
.textMeter-text {
	pointer-events: none;
	font-size: 9pt;
	fill: #404040;
	stroke: none;
}

/* label text */
.textMeter-label {
	pointer-events: none;
	font-size: 4pt;
	fill: #606060;
	stroke: none;
}

</style>
}

/// Render the inner SVG contents of this component.
ClientMethod renderMeter() [ Language = javascript ]
{
	// JMD1125 call unrender
	this.unrender();
	var body = this.document.createElementNS(SVGNS,'rect');
	body.setAttribute('class','textMeter-body');
	body.setAttribute('style',this.backgroundStyle);	
	body.setAttribute('x',5);
	body.setAttribute('y',5);
	body.setAttribute('width',90);
	body.setAttribute('height',20);
	body.setAttribute('rx',2);
	this.svgGroup.appendChild(body);

	// value
	var label = this.document.createElementNS(SVGNS,'text');
	label.setAttribute('id',this.makeId('text'));
	label.setAttribute('class','textMeter-text');
	label.setAttribute('style',this.normalStyle);

	label.setAttribute('x',50);
	label.setAttribute('y',22.5);
	label.setAttribute('text-anchor','middle');

	var textNode = this.document.createTextNode('');
	label.appendChild(textNode);
	this.svgGroup.appendChild(label);

	// label
	var label = this.document.createElementNS(SVGNS,'text');
	label.setAttribute('id',this.makeId('label'));
	label.setAttribute('class','textMeter-label');
	label.setAttribute('style',this.labelStyle);
	label.setAttribute('x',50);
	label.setAttribute('y',12);
	label.setAttribute('text-anchor','middle');

	// JMD1003
	var textNode = this.document.createTextNode(this.getLabelText());
	label.appendChild(textNode);
	this.svgGroup.appendChild(label);

	// set initial style of meter
	this.updateMeter();
}

/// Internal method: update the meter.
ClientMethod updateMeter() [ Internal, Language = javascript ]
{
	// calculate how meter should display
	// thresholds depend on direction of range...
	var tlower = parseFloat(this._thresholdLower);
	var tupper = parseFloat(this._thresholdUpper);

	// calculate style for text
	var style = this.normalStyle;
	var value = parseFloat(this.value);

	if (parseFloat(this._rangeUpper) >= parseFloat(this._rangeLower)) {
		if (value <= tlower) {
			style += this.lowStyle;
		}
		else if (value >= tupper) {
			style += this.highStyle;
		}
	}
	else {
		// reverse orientation
		if (value <= tupper) {
			style += this.lowStyle;
		}
		else if (value >= tlower) {
			style += this.highStyle;
		}
	}	

	// update text
	var text = this.findSVGElement("text");
	text.setAttribute("style", style);

	var value = this.value;
	if ('' !== this.format) {
		value = zenFormatNumber(value,this.format);
	}
	this.setTextNode("text",value);
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'labelStyle':
	case 'backgroundStyle':
		this[property] = value;
		this.render();
		break;

	case 'value':
		this.value = value;
		this.updateMeter();
		break;

	case 'format':
	case 'lowStyle':
	case 'highStyle':
	case 'normalStyle':
		this[property] = value;
		this.updateMeter();
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
