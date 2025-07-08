/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG-based Traffic Light meter for Dashboard.<br>
/// Light logic depends on the relative values of <var>RangeLower</var> and 
/// <var>RangeUpper</var> and works as follows:<br>
/// If <var>RangeLower</var> is less than (or equal to) <var>RangeUpper</var>, then 
/// the light is green when the level is less than (or equal to) <var>ThresholdLower</var> and 
/// the light is red when the level is greater than (or equal to) <var>ThresholdUpper</var> otherwise
/// the light is yellow.<br>
/// If <var>RangeLower</var> is greater then <var>RangeUpper</var>, then 
/// the light is red when the level is less than (or equal to) <var>ThresholdLower</var> and 
/// the light is green when the level is greater than (or equal to) <var>ThresholdUpper</var> otherwise
/// the light is yellow.<br>
Class CSPX.Dashboard.TrafficLight Extends Meter [ ClassType = "", ProcedureBlock, System = 3 ]
{

Parameter MINWIDTH = 50;

Parameter WIDTH = 50;

ClassMethod OnSVGStyle()
{
	&html<
	.TrafficLight-body {
		fill: url(#TrafficLight-bodyGrad);
		stroke: black;
		stroke-width: 1px;
		filter: url(#dropShadow);
	}

	.TrafficLight-redLampON {
		fill: url(#TrafficLight-redGrad);
		stroke: black;
		stroke-width: 1px;
	}
	.TrafficLight-redLampOFF {
		fill: #200000;
		stroke: black;
		stroke-width: 1px;
	}
	.TrafficLight-yellowLampON {
		fill: url(#TrafficLight-yellowGrad);
		stroke: black;
		stroke-width: 1px;
	}
	.TrafficLight-yellowLampOFF {
		fill: #202000;
		stroke: black;
		stroke-width: 1px;
	}
	.TrafficLight-greenLampON {
		fill: url(#TrafficLight-greenGrad);
		stroke: black;
		stroke-width: 1px;
	}
	.TrafficLight-greenLampOFF {
		fill: #002000;
		stroke: black;
		stroke-width: 1px;
	}
	
	>
}

/// Draw the script section of this SVG meter
ClassMethod OnSVGScript()
{
	&js<
	
function TrafficLight_setProperty(property,value)
{
	switch (property) {
	default:
		return false;
	case 'level':
		if (value == this.level) {
			return;
		}
	
		// update level of gauge
		this.level = value;
		var id = this.meterId;
		
		// calculate which lamps should be on
		var redState = false;
		var greenState = false;
		var yellowState = false;

		// thresholds depend on direction of range...
		if (greaterThanEq(this.rangeUpper,this.rangeLower)) {
			// normal range direction
			if (lessThanEq(this.level,this.thresholdLower)) {
				greenState = true;
			}
			else if (greaterThanEq(this.level,this.thresholdUpper)) {
				redState = true;
			}
			else {
				yellowState = true;
			}
		}
		else {
			if (lessThanEq(this.level,this.thresholdLower)) {
				redState = true;
			}
			else if (greaterThanEq(this.level,this.thresholdUpper)) {
				greenState = true;
			}
			else {
				yellowState = true;
			}
		}

		// update lamps
		var redLamp = document.getElementById(id + "_redLamp");
		var greenLamp = document.getElementById(id + "_greenLamp");
		var yellowLamp = document.getElementById(id + "_yellowLamp");
		
		redLamp.setAttribute("class",redState ? "TrafficLight-redLampON" : "TrafficLight-redLampOFF");
		greenLamp.setAttribute("class",greenState ? "TrafficLight-greenLampON" : "TrafficLight-greenLampOFF");
		yellowLamp.setAttribute("class",yellowState ? "TrafficLight-yellowLampON" : "TrafficLight-yellowLampOFF");
		break;
	}

	return true;
}
	>
}

/// Draw the defs section of this SVG meter
ClassMethod OnSVGDefs()
{
	&html<
<linearGradient id="TrafficLight-bodyGrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="50%" style="stop-color:darkgray" />
<stop offset="90%" style="stop-color:gray" />
</linearGradient>

<linearGradient id="TrafficLight-redGrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkred" />
<stop offset="30%" style="stop-color:#FF0000" />
<stop offset="70%" style="stop-color:#FF0000" />
<stop offset="100%" style="stop-color:darkred" />
</linearGradient>

<linearGradient id="TrafficLight-yellowGrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="30%" style="stop-color:#FFFF00" />
<stop offset="70%" style="stop-color:#FFFF00" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="TrafficLight-greenGrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkgreen" />
<stop offset="60%" style="stop-color:#00FF00" />
<stop offset="100%" style="stop-color:darkgreen" />
</linearGradient>
>
}

/// Draw the body of this SVG meter
Method OnSVGBody()
{
	Set id = ..MeterId

	&html<
		<rect class="TrafficLight-body" x="#((..Width/2)-15)#" y="8" width="30" height="74" rx="5" />
		<circle id="#(id)#_redLamp" class="TrafficLight-redLampOFF" cx="#(..Width/2)#" cy="22" r="10" />
		<circle id="#(id)#_yellowLamp" class="TrafficLight-yellowLampOFF" cx="#(..Width/2)#" cy="45" r="10" />
		<circle id="#(id)#_greenLamp" class="TrafficLight-greenLampOFF" cx="#(..Width/2)#" cy="68" r="10" />
	>
}

}
