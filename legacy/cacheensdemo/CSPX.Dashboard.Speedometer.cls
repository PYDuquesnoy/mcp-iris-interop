/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG-based Speedometer meter for Dashboard.
Class CSPX.Dashboard.Speedometer Extends Meter [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// Optional source (property name) for the odometer displayed within the speedometer.
Property OdometerProperty As %String(MAXLEN = 64, XMLPROJECTION = "ATTRIBUTE");

ClassMethod OnSVGStyle()
{
	&html<
	.Speedometer-body {
		fill: url(#Speedometer-bodyGrad);
		stroke: black;
		stroke-width: 1px;
		stroke-linejoin: round;
		filter: url(#dropShadow);
	}

	.Speedometer-body2 {
		fill: url(#Speedometer-bodyGrad);
		stroke: black;
		stroke-width: 0.8px;
		stroke-linejoin: round;
	}

	.Speedometer-tickThin {
		fill: none;
		stroke: #202020;
		stroke-width: 1px;
		stroke-linejoin: round;
		stroke-linecap: round;
	}

	.Speedometer-tickThick {
		fill: none;
		stroke: black;
		stroke-width: 2px;
		stroke-linejoin: round;
		stroke-linecap: round;
	}

	.Speedometer-needle {
		fill: red;
		stroke: black;
		stroke-width: 1px;
		stroke-linejoin: round;
		stroke-linecap: round;
	}

	.Speedometer-shadow {
		fill: black;
		stroke: black;
		stroke-width: 1px;
		opacity: 0.1;
		stroke-linejoin: round;
		stroke-linecap: round;
	}

	.Speedometer-fuelLampON {
		fill: url(#Speedometer-lampGrad);
		stroke: #404040;
		stroke-width: 0.4;
	}

	.Speedometer-fuelLampOFF {
		fill: none;
		stroke: #404040;
		stroke-width: 0.4;
	}

	.Speedometer-levelTextBox {
		fill: url(#Speedometer-bodyGrad2);
		stroke: black;
		stroke-width: 0.8;
	}

	.Speedometer-levelText {
		pointer-events: none;
		font-size: 8;
		fill: black;
		font-weight: bold;
		stroke: none;
		font-family: courier-new;
	}
	.Speedometer-levelTextNeg {
		pointer-events: none;
		font-size: 8;
		fill: red;
		font-weight: bold;
		stroke: none;
		font-family: courier-new;
	}

	.Speedometer-logoText {
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
<linearGradient id="Speedometer-bodyGrad" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#EEEEEE" />
<stop offset="50%" style="stop-color:darkgray" />
<stop offset="90%" style="stop-color:gray" />
</linearGradient>

<linearGradient id="Speedometer-bodyGrad2" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:gray" />
<stop offset="20%" style="stop-color:darkgray" />
<stop offset="90%" style="stop-color:#EEEEEE" />
</linearGradient>

<linearGradient id="Speedometer-lampGrad" x1="0%" y1="0%" x2="0%" y2="100%">
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
	
function Speedometer_setProperty(property,value,idx)
{
	switch (property) {
	default:
		return false;
	case 'level':
		var updateOdometer = false;
		var id = this.meterId;
		if (1 == idx) {
			// request to set odometer property
			if (this.propertyCount == 1) {
				return;
			}
			updateOdometer = true;
		}
		else {
			// regular level
			if (value == this.level) {
				return;
			}
			if (this.timerId) {
				window.clearTimeout(this.timerId);
				this.timerId = null;
			}
	
			// update level of gauge
			this.level = value;

			if (this.propertyCount == 1) {
				updateOdometer = true;
			}
		
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
			lamp.setAttribute("class",lowLamp ? "Speedometer-fuelLampON" : "Speedometer-fuelLampOFF");
	
			var lamp = document.getElementById(id + "_highFuelLamp");
			lamp.setAttribute("class",highLamp ? "Speedometer-fuelLampON" : "Speedometer-fuelLampOFF");
	
			if (null == this.currLevel) {
				this.currLevel = 0;
			}
	
			// find intermediate needle position
			var speed = (this.level*1 - this.currLevel*1) / 4;
			this.currLevel = this.currLevel*1 + speed;
			this.setProperty('updateLevel',0);
		}

		if (updateOdometer) {
			// update odometer text
			var lvl = value * this.scaleFactor;
			var text = document.getElementById(id + "_levelText");
			text.setAttribute("class",greaterThanEq(lvl,0) ? "Speedometer-levelText" : "Speedometer-levelTextNeg");
	
			if (greaterThanEq(lvl,10000000) || lessThanEq(lvl,-1000000)) {
				lvl = "\043\043\043\043\043\043";
			}
			else {
				lvl = Math.round(lvl);
			}
			setTextNode(id + "_levelText",lvl);
		}
		break;

	case 'updateLevel':
		// update internal level of meter
		this.timerId = null;

		var range = this.rangeUpper - this.rangeLower;

		// round off if close enough
		if (lessThanEq(Math.abs(this.level*1 - this.currLevel*1),(range/280))) {
			this.currLevel = this.level*1;
		}

		var id = this.meterId;

		// calculate needle angle from level
		// display range is -140 to 140

		var angle = 0;
		if (range != 0) {
			angle = (((this.currLevel - this.rangeLower) / range) * 280) - 140;
		}

		// pin needle against edges
		if (greaterThanEq(angle,140)) {
			angle = 140;
		}
		if (lessThanEq(angle,-140)) {
			angle = -140;
		}
		
		var needle = document.getElementById(id + "_needle");
		needle.setAttribute("transform", "rotate(" + angle + ",50,43)");

		var shadow = document.getElementById(id + "_shadow");
		if (shadow) {
			shadow.setAttribute("transform", "translate(3,2) rotate(" + angle + ",50,43)");
		}

		// if not done, move needle again
		if (this.level*1 != this.currLevel*1) {
			var speed = (this.level*1 - this.currLevel*1) / 4;
			this.currLevel = this.currLevel*1 + speed;
			this.timerId = window.setTimeout("Speedometer_updateNeedle('" + id + "')",50);
		}
		break;
	}
	return true;
}

function Speedometer_updateNeedle(meterId)
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
	
	// HCR056 centers the Speedometer based on the Width
	Set w = +..Width Set:w<100 w = 100
	Set move = (w\2)-50
	&html<
		<g transform="translate(#(move)#,0)">
	>
	
	&html<
		<path class="Speedometer-body" d="M 40,80 A 38 38 0 1 1 60 80 z" />
		<circle id="#(id)#_lowFuelLamp" class="Speedometer-fuelLampOFF" cx="34.5" cy="72" r="1.8" />
		<circle id="#(id)#_highFuelLamp" class="Speedometer-fuelLampOFF" cx="65.5" cy="72" r="1.8" />
	>

	// ticks
	For a = -140:14:140 {
		Set style = $S($G(style)="Thick":"Thin",1:"Thick")
		&html<<line class="Speedometer-tick#(style)#" x1="50" y1="12" x2="50" y2="9" transform="rotate(#(a)#,50,43)"/>>
	}
	
	// logo
	&html<<text class="Speedometer-logoText" x="50" y="33" text-anchor="middle">IRIS</text>>

	&html<
		<rect class="Speedometer-levelTextBox" x="32" y="55" width="35" height="8" rx="1" />
		<text id="#(id)#_levelText" class="Speedometer-levelText" x="67" y="62" text-anchor="end">#(..Level)#</text>
	>
	// odometer lines
	Set x = 62.4
	For n = 1:1:6 {
		&html<<line style="stroke:gray; stroke-width:0.1;" x1="#(x)#" y1="55.5" x2="#(x)#" y2="62.5" />>
		Set x = x - 4.9
	}
	&html<
		<path id="#(id)#_shadow" class="Speedometer-shadow" d="M 50,12 L 53,55 50,53 47,55 z" transform="rotate(1,50,43)" />
		<path id="#(id)#_needle" class="Speedometer-needle" d="M 50,12 L 53,55 50,53 47,55 z" transform="rotate(0,50,43)" />
		<path class="Speedometer-body2" d="M 47,51 A 8 8 0 1 1 53 51 z" />
	>
	
	&html<
		</g>
	>
}

/// Called by Dashboard class to generate code to
/// create an instance of this object.
/// The object instance is called <var>tMeter</var>.
Method GenerateCode(pCode As %CharacterStream, pLevel As %Integer = 1) As %Status
{
	Do ##super(pCode)
	If (..OdometerProperty'="") {
		Do pCode.WriteLine(" Set tMeter.OdometerProperty=""" _ ..OdometerProperty _ """")
		Do pCode.WriteLine(" Set tMeter.PropertyCount=2")
	}
	Quit $$$OK
}

}
