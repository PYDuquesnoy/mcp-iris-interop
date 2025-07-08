/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG light bar meter.<br>
/// This displays a value within a representation of a LED light bar.<br>
/// This control looks best when its width is half of its height.
Class %ZEN.SVGComponent.lightBar Extends meter [ Deprecated, System = 3 ]
{

/// Override viewBoxWidth for this component.
Parameter DEFAULTVIEWBOXWIDTH = 50;

/// Fill color used for low indicator lamp.
Property lowLampColor As %ZEN.Datatype.color [ InitialExpression = "url(#glow-red)" ];

/// Fill color used for high indicator lamp.
Property highLampColor As %ZEN.Datatype.color [ InitialExpression = "url(#glow-red)" ];

/// Optional. Style applied to outer region.
Property outerBodyStyle As %ZEN.Datatype.style;

XData SVGStyle
{
<style type="text/css">
.lightBar-body {
	stroke: black;
	stroke-width: 1px;
}

.lightBar-lampON {
	stroke: black;
	stroke-width: 1px;
}

.lightBar-lampOFF {
	stroke: black;
	stroke-width: 1px;
}

/* indicator */
.lightBar-lamp {
	stroke: #505050;
	stroke-width: 0.4;
}
</style>
}

XData SVGDef
{
<defs>
<linearGradient id="lightBar-bodyGrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="50%" style="stop-color:darkgray" />
<stop offset="90%" style="stop-color:gray" />
</linearGradient>
</defs>
}

/// Render the inner SVG contents of this component.
ClientMethod renderMeter() [ Language = javascript ]
{
	// body & lamps
	var body = this.document.createElementNS(SVGNS,'rect');
	body.setAttribute('class','lightBar-body');
	body.setAttribute('fill','url(#lightBar-bodyGrad)');
	body.setAttribute('style',this.outerBodyStyle);
	body.setAttribute('x',10);
	body.setAttribute('y',8);
	body.setAttribute('width',30);
	body.setAttribute('height',74);
	body.setAttribute('rx',5);
	this.svgGroup.appendChild(body);

	var lamp = this.document.createElementNS(SVGNS,'circle');
	lamp.setAttribute('id',this.makeId('lowLamp'));
	lamp.setAttribute('class','lightBar-lamp');
	lamp.setAttribute('fill','none');
	lamp.setAttribute('cx',14);
	lamp.setAttribute('cy',76.5);
	lamp.setAttribute('r',2);
	this.svgGroup.appendChild(lamp);

	var lamp = this.document.createElementNS(SVGNS,'circle');
	lamp.setAttribute('id',this.makeId('highLamp'));
	lamp.setAttribute('class','lightBar-lamp');
	lamp.setAttribute('fill','none');
	lamp.setAttribute('cx',14);
	lamp.setAttribute('cy',13);
	lamp.setAttribute('r',2);
	this.svgGroup.appendChild(lamp);

	// underlying bars + bars
	var y = 11;
	for (var n = 9; n >= 0; n--) {
		var color = (n>=8 ? '#200000;' : (n>=7 ? '#202000;' : '#002000;'));
		var bar = this.document.createElementNS(SVGNS,'rect');
		bar.setAttribute('class','lightBar-lampOFF');
		bar.setAttribute('fill',color);
		bar.setAttribute('x',18);
		bar.setAttribute('y',y);
		bar.setAttribute('width',14);
		bar.setAttribute('height',5);
		bar.setAttribute('rx',2);
		this.svgGroup.appendChild(bar);

		var bar = this.document.createElementNS(SVGNS,'rect');
		bar.setAttribute('id',this.makeId('lamp_'+n));
		bar.setAttribute('class','lightBar-lampON');
		bar.setAttribute('fill','none');
		bar.setAttribute('x',18);
		bar.setAttribute('y',y);
		bar.setAttribute('width',14);
		bar.setAttribute('height',5);
		bar.setAttribute('rx',2);
		this.svgGroup.appendChild(bar);

		y += 7;
	}

	// label
	this.renderLabel('50%',95);

	// move to initial position
	this.updateLamps(false);
}

/// Internal method: update lamps
ClientMethod updateLamps(animate) [ Language = javascript ]
{
	delete this._timerId;

	var range = this._rangeUpper - this._rangeLower;
	if (null == this.currValue) {
		this.currValue = 0;
	}

	if (animate) {
		// if close enough; round off to final value
		if ((Math.abs(this.value*1 - this.currValue*1)<=(range/50))) {
			this.currValue = this.value*1;
		}
	}
	else {
		this.currValue = this.value*1;
	}

	// calculate number of bars to show
	// display range is 0 to 10
	
	var bars = 0;
	var fraction = 0;
	if (range != 0) {
		bars = (((this.currValue - this._rangeLower) / range) * 10);
		fraction = bars - Math.floor(bars);
	}
		
	// clip
	if (bars <= 0) {
		bars = 0;
	}
	if (bars >= 10) {
		bars = 10;
	}

	// turn on lamps
	for (var n = 0; n != 10; n++) {
		var off = (n >= bars);
		var lamp = this.findSVGElement('lamp_' + n);
		if (n <=6 ) {
			lamp.setAttribute("fill",(off) ? "none" : "url(#glow-green)");
		}
		else if (n == 7) {
			lamp.setAttribute("fill",(off) ? "none" : "url(#glow-yellow)");
		}
		else {
			lamp.setAttribute("fill",(off) ? "none" : "url(#glow-red)");
		}

		// fractional value
		if ((n == Math.floor(bars)) && (fraction != 0)) {
			lamp.setAttribute("fill-opacity", (0.0 + (fraction / 1)));
		}
		else {
			lamp.setAttribute("fill-opacity", 1.0);
		}
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
		lamp.setAttribute("fill",lowLamp ? this.lowLampColor : 'none');
	}

	var lamp = this.findSVGElement('highLamp');
	if (lamp) {
		lamp.setAttribute("fill",highLamp ? this.highLampColor : 'none');
	}

	// if not done, move needle again
	if (animate && (this.value*1 != this.currValue*1)) {
		var speed = (this.value*1 - this.currValue*1) / 2;
		this.currValue = this.currValue*1 + speed;
		this._timerId = window.setTimeout("zenPage.getComponent(" + this.index + ").updateLamps(true)",50);
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {

	case 'value':
		// regular value
		if (this._timerId) {
			// if we are in the middle of update; kill timer
			window.clearTimeout(this._timerId);
			delete this._timerId;
		}

		// update gauge
		this.value = value;

		if (null == this.currValue) {
			this.currValue = 0;
		}
	
		// move to intermediate position
		var speed = (this.value*1 - this.currValue*1) / 4;
		this.currValue = this.currValue*1 + speed;
		this.updateLamps(this.animate);
		break;

	case 'outerBodyStyle':
		this[property] = value;
		this.unrender();
		this.render();
		break;

	case 'lowLampColor':
	case 'highLampColor':
		this[property] = value;
		this.updateLamps(false);
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
