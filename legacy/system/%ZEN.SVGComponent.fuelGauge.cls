/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG fuel gauge meter.
/// This displays a value within a representation of a fuel gauge.
Class %ZEN.SVGComponent.fuelGauge Extends meter [ Deprecated, System = 3 ]
{

/// Text for logo displayed in center of dial.
Property logo As %ZEN.Datatype.caption [ InitialExpression = "Zen" ];

/// Fill color used for low indicator lamp.
Property lowLampColor As %ZEN.Datatype.color [ InitialExpression = "url(#glow-red)" ];

/// Fill color used for high indicator lamp.
Property highLampColor As %ZEN.Datatype.color [ InitialExpression = "url(#glow-red)" ];

/// Optional. Style applied to outer region.
Property outerBodyStyle As %ZEN.Datatype.style;

/// Optional. Style applied to bottom panel.
Property panelStyle As %ZEN.Datatype.style;

/// Optional. Style applied to needle.
Property needleStyle As %ZEN.Datatype.style;

/// Optional. Style applied to level box.
Property levelBoxStyle As %ZEN.Datatype.style;

/// Optional. Style applied to text in level box.
Property levelTextStyle As %ZEN.Datatype.style;

/// Optional. Style applied to logo.
Property logoStyle As %ZEN.Datatype.style;

/// Optional. Numeric format string to apply to the odometer value.
Property format As %ZEN.Datatype.string;

XData SVGStyle
{
<style type="text/css">
.fuelGauge-body {
	stroke: black;
	stroke-width: 1px;
	stroke-linejoin: round;
}

.fuelGauge-body2 {
	stroke: black;
	stroke-width: 1px;
	stroke-linejoin: round;
}

.fuelGauge-tick {
	fill: none;
	stroke: black;
	stroke-width: 1px;
	stroke-linejoin: round;
	stroke-linecap: round;
}

.fuelGauge-needle {
	fill: none;
	stroke: red;
	stroke-width: 2px;
	stroke-linejoin: round;
	stroke-linecap: round;
}

.fuelGauge-shadow {
	fill: none;
	stroke: black;
	stroke-width: 1.8px;
	opacity: 0.1;
	stroke-linejoin: round;
	stroke-linecap: round;
}

.fuelGauge-lamp {
	stroke: #909090;
	stroke-width: 0.4;
}

.fuelGauge-levelTextBox {
	stroke: black;
	stroke-width: 0.8;
}

.fuelGauge-levelText {
	pointer-events: none;
	font-size: 4pt;
	fill: #404040;
	font-weight: bold;
	stroke: none;
	font-family: arial;
}

.fuelGauge-levelTextNeg {
	pointer-events: none;
	font-size: 4pt;
	fill: red;
	font-weight: bold;
	stroke: none;
	font-family: arial;
}

.fuelGauge-logoText {
	pointer-events: none;
	font-size: 5pt;
	fill: gray;
	stroke: none;
	font-family: tahoma verdana;
}
</style>
}

XData SVGDef
{
<defs>
<linearGradient id="fuelGauge-bodyGrad" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#EEEEEE" />
<stop offset="50%" style="stop-color:darkgray" />
<stop offset="90%" style="stop-color:gray" />
</linearGradient>
<radialGradient id="fuelGauge-blueGrad" cx="50" cy="43" r="40" fx="20" fy="20" gradientUnits="userSpaceOnUse" >
<stop offset="0%" style="stop-color:#EEEEFF" />
<stop offset="30%" style="stop-color:#DDDDFF" />
<stop offset="100%" style="stop-color:#9999FF" />
</radialGradient>

<linearGradient id="fuelGauge-levelBoxGrad" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:gray" />
<stop offset="20%" style="stop-color:darkgray" />
<stop offset="90%" style="stop-color:#EEEEEE" />
</linearGradient>

</defs>
}

/// Render the inner SVG contents of this component.
ClientMethod renderMeter() [ Language = javascript ]
{
	// body & lamps
	var body = this.document.createElementNS(SVGNS,'path');
	body.setAttribute('class','fuelGauge-body');
	body.setAttribute('fill','url(#fuelGauge-bodyGrad)');
	body.setAttribute('d','M 20 20 A 50 25 0 0 1 80 20 L 70 80 L 30 80 z');
	body.setAttribute('style',this.outerBodyStyle);

	this.svgGroup.appendChild(body);

	var lamp = this.document.createElementNS(SVGNS,'circle');
	lamp.setAttribute('id',this.makeId('lowLamp'));
	lamp.setAttribute('class','fuelGauge-lamp');
	lamp.setAttribute('fill','none');
	lamp.setAttribute('cx',24.5);
	lamp.setAttribute('cy',22);
	lamp.setAttribute('r',1.8);
	this.svgGroup.appendChild(lamp);

	var lamp = this.document.createElementNS(SVGNS,'circle');
	lamp.setAttribute('id',this.makeId('highLamp'));
	lamp.setAttribute('class','fuelGauge-lamp');
	lamp.setAttribute('fill','none');
	lamp.setAttribute('cx',75.5);
	lamp.setAttribute('cy',22);
	lamp.setAttribute('r',1.8);
	this.svgGroup.appendChild(lamp);

	// ticks
	var tick = this.document.createElementNS(SVGNS,'line');
	tick.setAttribute('class','fuelGauge-tick');
	tick.setAttribute('x1',25);
	tick.setAttribute('y1',25);
	tick.setAttribute('x2',26);
	tick.setAttribute('y2',30);
	this.svgGroup.appendChild(tick);

	var tick = this.document.createElementNS(SVGNS,'line');
	tick.setAttribute('class','fuelGauge-tick');
	tick.setAttribute('x1',37);
	tick.setAttribute('y1',23);
	tick.setAttribute('x2',37.4);
	tick.setAttribute('y2',26);
	this.svgGroup.appendChild(tick);

	var tick = this.document.createElementNS(SVGNS,'line');
	tick.setAttribute('class','fuelGauge-tick');
	tick.setAttribute('x1',50);
	tick.setAttribute('y1',22);
	tick.setAttribute('x2',50);
	tick.setAttribute('y2',27);
	this.svgGroup.appendChild(tick);

	var tick = this.document.createElementNS(SVGNS,'line');
	tick.setAttribute('class','fuelGauge-tick');
	tick.setAttribute('x1',63);
	tick.setAttribute('y1',23);
	tick.setAttribute('x2',62.6);
	tick.setAttribute('y2',26);
	this.svgGroup.appendChild(tick);
	var tick = this.document.createElementNS(SVGNS,'line');

	tick.setAttribute('class','fuelGauge-tick');
	tick.setAttribute('x1',75);
	tick.setAttribute('y1',25);
	tick.setAttribute('x2',74);
	tick.setAttribute('y2',30);
	this.svgGroup.appendChild(tick);

	// logo
	var logo = this.document.createElementNS(SVGNS,'text');
	logo.setAttribute('id',this.makeId('logo'));
	logo.setAttribute('class','fuelGauge-logoText');
	logo.setAttribute('style',this.logoStyle);
	logo.setAttribute('x',50);
	logo.setAttribute('y',43);
	logo.setAttribute('text-anchor','middle');

	var textNode = this.document.createTextNode(this.logo);
	logo.appendChild(textNode);
	this.svgGroup.appendChild(logo);

	// value box
	var rect = this.document.createElementNS(SVGNS,'rect');
	rect.setAttribute('class','fuelGauge-levelTextBox');
	rect.setAttribute('style',this.levelBoxStyle);

	rect.setAttribute('fill','url(#fuelGauge-levelBoxGrad)');
	rect.setAttribute('x',33);
	rect.setAttribute('y',49);
	rect.setAttribute('width',34);
	rect.setAttribute('height',8);
	rect.setAttribute('rx',1);
	this.svgGroup.appendChild(rect);

	var lvlText = this.document.createElementNS(SVGNS,'text');
	lvlText.setAttribute('id',this.makeId('levelText'));
	lvlText.setAttribute('class','fuelGauge-levelText');
	lvlText.setAttribute('style',this.levelTextStyle);
	lvlText.setAttribute('x',65);
	lvlText.setAttribute('y',55);
	lvlText.setAttribute('text-anchor','end');

	var textNode = this.document.createTextNode(this.value);
	lvlText.appendChild(textNode);
	this.svgGroup.appendChild(lvlText);

	// needle
	var shadow = this.document.createElementNS(SVGNS,'line');
	shadow.setAttribute('id',this.makeId('shadow'));
	shadow.setAttribute('class','fuelGauge-shadow');
	shadow.setAttribute('x1',50);
	shadow.setAttribute('y1',28);
	shadow.setAttribute('x2',50);
	shadow.setAttribute('y2',60);
	shadow.setAttribute('transform','rotate(1,50,166)');
	this.svgGroup.appendChild(shadow);

	var needle = this.document.createElementNS(SVGNS,'line');
	needle.setAttribute('id',this.makeId('needle'));
	needle.setAttribute('class','fuelGauge-needle');
	needle.setAttribute('style',this.needleStyle);
	needle.setAttribute('x1',50);
	needle.setAttribute('y1',25);
	needle.setAttribute('x2',50);
	needle.setAttribute('y2',60);
	needle.setAttribute('transform','rotate(0,50,166)');
	this.svgGroup.appendChild(needle);

	// nub
	var nub = this.document.createElementNS(SVGNS,'path');
	nub.setAttribute('class','fuelGauge-body2');
	nub.setAttribute('fill','url(#fuelGauge-bodyGrad)');
	nub.setAttribute('d','M 27 62 A 50 25 0 0 1 73 62 L 70 80 L 30 80 z');
	this.svgGroup.appendChild(nub);
	nub.setAttribute('style',this.panelStyle);

	// label
	this.renderLabel('50%',95);

	this.setProperty('value',this.value);

	// move needle to initial position
	this.updateNeedle(false);
}

/// Internal method: update position of needle
ClientMethod updateNeedle(animate) [ Language = javascript ]
{
	delete this._timerId;

	var range = this._rangeUpper - this._rangeLower;
	var valueIsNaN = isNaN(this.value*1);		// DTB586 - Test the value for a useable value

	if (animate) {
		// if close enough; round off to final value
		if ((Math.abs(this.value*1 - this.currValue*1)<=(range/280))) {
			this.currValue = this.value*1;
		}
	}
	else {
		this.currValue = this.value*1;
	}

	if (isNaN(this.currValue)) {
		// DTB586
		this.currValue = 0;
	}

	// calculate needle angle from level
	// display range is -10 to 10
	var angle = 0;
	if (range != 0) {
		angle = (((this.currValue - this._rangeLower) / range) * 20) - 10;
	}
	
	// pin needle against edges
	if (angle <= -10) {
		angle = -10;
	}
	if (angle >= 10) {
		angle = 10;
	}

	// move needle
	var needle = this.findSVGElement('needle');
	if (needle) {
		needle.setAttribute("transform", "rotate(" + angle + ",50,166)");
	}

	var shadow = this.findSVGElement('shadow');
	if (shadow) {
		shadow.setAttribute("transform", "rotate(" + (angle+1) + ",50,166)");
	}

	// indicator lamps
	var lowLamp = false;
	var highLamp = false;
	if (this.currValue <= this._thresholdLower) {
		lowLamp = true;
	}
	if (this.currValue >= this._thresholdUpper) {
		highLamp = true;
	}

	// indicator lamps
	var lamp = this.findSVGElement('lowLamp');
	if (lamp) {
		lamp.style.visibility = (valueIsNaN ? 'hidden' : 'visible');
		lamp.setAttribute("fill",lowLamp ? this.lowLampColor : 'none');
	}

	var lamp = this.findSVGElement('highLamp');
	if (lamp) {
		lamp.style.visibility = (valueIsNaN ? 'hidden' : 'visible');
		lamp.setAttribute("fill",highLamp ? this.highLampColor : 'none');
	}

	// if not done, move needle again
	if (animate && (this.value*1 != this.currValue*1)) {
		var speed = (this.value*1 - this.currValue*1) / 4;
		this.currValue = this.currValue*1 + speed;
		
		if (!valueIsNaN) {		// DTB586
			this._timerId = window.setTimeout("{var w = zenPage.getComponent(" + this.index + ");if (w) w.updateNeedle(true);}",50);
		}
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'value':
		if (this._timerId) {
			// if we are in the middle of needle move; kill timer
			window.clearTimeout(this._timerId);
			delete this._timerId;
		}

		// update gauge
		this.value = value;
		if ((null == this.currValue)||(isNaN(this.currValue))) {		// DTB586
			this.currValue = 0;
		}

		// text
		var lvl = 0;
		var lvl = this.value * this.scaleFactor;
		var text = this.findSVGElement('levelText');
		text.setAttribute("class",(lvl>=0) ? "fuelGauge-levelText" : "fuelGauge-levelTextNeg");
		if ('' != this.format) {
			var dval = zenFormatNumber(lvl,this.format);
		}
		else {
			var dval = Math.round(lvl);
		}
		
		if (isNaN(dval)) {
			dval = '';		// DTB586
		}
		
		this.setTextNode("levelText",dval);
		var tw = (zenGetBBox(text).width);
		if ((tw>30) || (lvl>=100000000) || (lvl<=-10000000)) {
			// show ### for overflow
			lvl = "\043\043\043\043\043\043";
			this.setTextNode("levelText",lvl);
		}
	
		// move to intermediate needle position
		var speed = (this.value*1 - this.currValue*1) / 4;
		this.currValue = this.currValue*1 + speed;
		this.updateNeedle(this.animate);
		break;

	case 'levelBoxStyle':
	case 'levelTextStyle':
	case 'needleStyle':
	case 'outerBodyStyle':
	case 'panelStyle':
	case 'logoStyle':
	case 'format':
		this[property] = value;
		this.unrender();
		this.render();
		break;

	case 'logo':
		this.logo = value;
		this.setTextNode('logo',this.logo);
		break;

	case 'lowLampColor':
	case 'highLampColor':
		this[property] = value;
		this.updateNeedle(false);
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
