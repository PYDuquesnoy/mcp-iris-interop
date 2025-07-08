/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG-based Traffic Light meter for Dashboard.
Class CSPX.Dashboard.IndicatorLamp Extends Meter [ ClassType = "", ProcedureBlock, System = 3 ]
{

Parameter MINHEIGHT = 25;

Parameter MINWIDTH = 50;

Parameter WIDTH = 75;

Parameter HEIGHT = 25;

Parameter SHOWLABEL = 0;

ClassMethod OnSVGStyle()
{
	&html<

	.IndicatorLamp-body {
		fill: black;
		stroke: black;
		stroke-width: 1px;
	}

	.IndicatorLamp-lampHigh {
		fill: url(#IndicatorLamp-highGrad);
		stroke: black;
		stroke-width: 1px;
	}

	.IndicatorLamp-lampLow {
		fill: url(#IndicatorLamp-lowGrad);
		stroke: black;
		stroke-width: 1px;
	}

	.IndicatorLamp-lampOFF {
		fill: gray;
		stroke: black;
		opacity: 0.5;
		stroke-width: 1px;
	}

	.IndicatorLamp-textOFF {
		pointer-events: none;
		font-size: 8;
		fill: black;
		stroke: none;
		font-weight: bold;
	}

	>
}

/// Draw the script section of this SVG meter
ClassMethod OnSVGScript()
{
	&js<
	
function IndicatorLamp_setProperty(property,value)
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
	
		// thresholds depend on direction of range...
		var tlower, tupper;
		if (greaterThanEq(this.rangeUpper,this.rangeLower)) {
			tlower = this.thresholdLower;
			tupper = this.thresholdUpper;
		}
		else {
			tlower = this.thresholdUpper;
			tupper = this.thresholdLower;
		}

		// calculate if lamp should be on
		var lampState = 'OFF';

		if (lessThanEq(this.level,tlower)) {
			// below low thresh:
			lampState = 'Low';
		}
		else if (greaterThanEq(this.level,tupper)) {
			// above high thresh:
			lampState = 'High';
		}
		
		// update lamp
		var lamp = document.getElementById(id + "_lamp");
		lamp.setAttribute("class", "IndicatorLamp-lamp" + lampState);
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

<linearGradient id="IndicatorLamp-highGrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkgreen" />
<stop offset="30%" style="stop-color:#00FF00" />
<stop offset="70%" style="stop-color:#00FF00" />
<stop offset="100%" style="stop-color:darkgreen" />
</linearGradient>

<linearGradient id="IndicatorLamp-lowGrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkred" />
<stop offset="30%" style="stop-color:red" />
<stop offset="70%" style="stop-color:red" />
<stop offset="100%" style="stop-color:darkred" />
</linearGradient>

>
}

/// Draw the body of this SVG meter
Method OnSVGBody()
{
	Set off = (..Width / 2) - 5
	Set id = ..MeterId
	
	&html<
		<rect class="IndicatorLamp-body" x="#((..Width/2)-off)#" y="5" width="#(..Width-10)#" height="16" rx="2" />
		<rect id="#(id)#_lamp" class="IndicatorLamp-lampOFF" x="#((..Width/2)-off)#" y="5" width="#(..Width-10)#" height="16" rx="5" />
		<text id="#(id)#_lampText" class="IndicatorLamp-textOFF" x="#(..Width/2)#" y="16" text-anchor="middle">#(..Label)#</text>
	>
}

}
