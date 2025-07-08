/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG-based Fuel Gauge meter for Dashboard.
Class CSPX.Dashboard.FuelGauge Extends Meter [ ClassType = "", ProcedureBlock, System = 3 ]
{

ClassMethod OnSVGStyle()
{
	&html<
	.FuelGauge-body {
		fill: url(#FuelGauge-bodyGrad);
		stroke: black;
		stroke-width: 1px;
		stroke-linejoin: round;
		filter: url(#dropShadow);
	}

	.FuelGauge-body2 {
		fill: url(#FuelGauge-bodyGrad);
		stroke: black;
		stroke-width: 1px;
		stroke-linejoin: round;
	}

	.FuelGauge-tick {
		fill: none;
		stroke: black;
		stroke-width: 1px;
		stroke-linejoin: round;
		stroke-linecap: round;
	}

	.FuelGauge-needle {
		fill: none;
		stroke: red;
		stroke-width: 2px;
		stroke-linejoin: round;
		stroke-linecap: round;
	}

	.FuelGauge-shadow {
		fill: none;
		stroke: black;
		stroke-width: 1.8px;
		opacity: 0.1;
		stroke-linejoin: round;
		stroke-linecap: round;
	}

	.FuelGauge-fuelLampON {
		fill: url(#FuelGauge-lampGrad);
		stroke: #909090;
		stroke-width: 0.4;
	}

	.FuelGauge-fuelLampOFF {
		fill: none;
		stroke: #909090;
		stroke-width: 0.4;
	}

	.FuelGauge-levelTextBox {
		fill: url(#Speedometer-bodyGrad2);
		stroke: black;
		stroke-width: 0.8;
	}

	.FuelGauge-levelText {
		pointer-events: none;
		font-size: 8;
		fill: black;
		font-weight: bold;
		stroke: none;
		font-family: courier-new;
	}

	.FuelGauge-levelTextNeg {
		pointer-events: none;
		font-size: 8;
		fill: red;
		font-weight: bold;
		stroke: none;
		font-family: courier-new;
	}

	.FuelGauge-logoText {
		pointer-events: none;
		font-size: 5;
		fill: gray;
		stroke: none;
		font-family: tahoma verdana;
	}

	>
}

/// Draw the defs section of this SVG meter
ClassMethod OnSVGDefs()
{
	&html<
<linearGradient id="FuelGauge-bodyGrad" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#EEEEEE" />
<stop offset="50%" style="stop-color:darkgray" />
<stop offset="90%" style="stop-color:gray" />
</linearGradient>

<linearGradient id="FuelGauge-lampGrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkred" />
<stop offset="30%" style="stop-color:#FF0000" />
<stop offset="70%" style="stop-color:#FF0000" />
<stop offset="100%" style="stop-color:darkred" />
</linearGradient>

>
}

ClassMethod OnSVGScript()
{
	&js<
	
function FuelGauge_setProperty(property,value)
{
	switch (property) {
	default:
		return false;
	case 'level':
		if (value == this.level) {
			return;
		}
	
		if (this.timerId) {
			window.clearTimeout(this.timerId);
			this.timerId = null;
		}

		// update level of gauge
		this.level = value;
		
		var id = this.meterId;

		// indicator lamps
		var lowLamp = false;
		var highLamp = false;
		if (lessThanEq(this.level,this.thresholdLower)) {
			lowLamp = true;
		}
		if (greaterThanEq(this.level,this.thresholdUpper)) {
			highLamp = true;
		}

		// indicator lamps
		var lamp = document.getElementById(id + "_lowFuelLamp");
		lamp.setAttribute("class",lowLamp ? "FuelGauge-fuelLampON" : "FuelGauge-fuelLampOFF");

		var lamp = document.getElementById(id + "_highFuelLamp");
		lamp.setAttribute("class",highLamp ? "FuelGauge-fuelLampON" : "FuelGauge-fuelLampOFF");
		
		// update text
		var lvl = this.level * this.scaleFactor;
		var text = document.getElementById(id + "_levelText");
		text.setAttribute("class",greaterThanEq(lvl,0) ? "FuelGauge-levelText" : "FuelGauge-levelTextNeg");

		if (greaterThanEq(lvl,100000) || lessThanEq(lvl,-100000)) {
			lvl = "\043\043\043\043\043";
		}
		setTextNode(id + "_levelText",lvl);

		if (null == this.currLevel) {
			this.currLevel = 0;
		}
		// find intermediate needle position
		var speed = (this.level*1 - this.currLevel*1) / 4;
		this.currLevel = this.currLevel*1 + speed;
		this.setProperty('updateLevel',0);
		break;

	case 'updateLevel':
		// update internal level of meter
		this.timerId = null;

		var range = this.rangeUpper - this.rangeLower;
		// round off if close enough
		if (lessThanEq(Math.abs(this.level*1 - this.currLevel*1),(range/280))) {
			this.currLevel = this.level*1;
		}

		// calculate needle angle from level
		// display range is -10 to 10
		
		var angle = 0;
		var range = this.rangeUpper - this.rangeLower;
		if (range != 0) {
			angle = (((this.currLevel - this.rangeLower) / range) * 20) - 10;
		}
		
		// pin needle against edges
		if (lessThanEq(angle,-10)) {
			angle = -10;
		}
		if (greaterThanEq(angle,10)) {
			angle = 10;
		}

		// move needle
		var id = this.meterId;

		var needle = document.getElementById(id + "_needle");
		needle.setAttribute("transform", "rotate(" + angle + ",50,166)");

		var shadow = document.getElementById(id + "_shadow");
		shadow.setAttribute("transform", "rotate(" + (angle+1) + ",50,166)");

		// if not done, move needle again
		if (this.level*1 != this.currLevel*1) {
			var speed = (this.level*1 - this.currLevel*1) / 4;
			this.currLevel = this.currLevel*1 + speed;
			this.timerId = window.setTimeout("FuelGauge_updateNeedle('" + id + "')",50);
		}
		break;
	}

	return true;
}

function FuelGauge_updateNeedle(meterId)
{
	if (meterList[meterId]) {
		meterList[meterId].setProperty('updateLevel',0);
	}
}
	>
}

/// Draw the body of this SVG meter
Method OnSVGBody()
{
	Set id = ..MeterId
	
	// HCR056 centers the FuelGauge based on the Width
	Set w = +..Width Set:w<100 w = 100
	Set move = (w\2)-50
	&html<
		<g transform="translate(#(move)#,0)">
	>
	
	&html<
		<path class="FuelGauge-body" d="M 20,20 A 50 25 0 0 1 80 20 L 70,80 L 30,80 z" />

		<circle id="#(id)#_lowFuelLamp" class="FuelGauge-fuelLampOFF" cx="24.5" cy="22" r="1.8" />
		<circle id="#(id)#_highFuelLamp" class="FuelGauge-fuelLampOFF" cx="75.5" cy="22" r="1.8" />

		<line class="FuelGauge-tick" x1="25" y1="25" x2="26" y2="30" />
		<line class="FuelGauge-tick" x1="37" y1="23" x2="37.4" y2="26" />
		<line class="FuelGauge-tick" x1="50" y1="22" x2="50" y2="27" />
		<line class="FuelGauge-tick" x1="63" y1="23" x2="62.6" y2="26" />
		<line class="FuelGauge-tick" x1="75" y1="25" x2="74" y2="30" />

		<text class="FuelGauge-logoText" x="50" y="43" text-anchor="middle">IRIS</text>

		<rect class="FuelGauge-levelTextBox" x="33" y="49" width="34" height="8" rx="1" />
		<text id="#(id)#_levelText" class="FuelGauge-levelText" x="66" y="56" text-anchor="end">#(..Level)#</text>

		<line id="#(id)#_shadow" class="FuelGauge-shadow" x1="50" y1="28" x2="50" y2="60" transform="rotate(1,50,166)" />
		<line id="#(id)#_needle" class="FuelGauge-needle" x1="50" y1="25" x2="50" y2="60" transform="rotate(0,50,166)" />
		
		<path class="FuelGauge-body2" d="M 27,62 A 50 25 0 0 1 73 62 L 70,80 L 30,80 z" />
	>
	
	&html<
		</g>
	>
}

}
