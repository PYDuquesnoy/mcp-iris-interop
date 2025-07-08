/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG-based LightBar meter for Dashboard.
Class CSPX.Dashboard.LightBar Extends Meter [ ClassType = "", ProcedureBlock, System = 3 ]
{

Parameter MINWIDTH = 50;

Parameter WIDTH = 50;

ClassMethod OnSVGStyle()
{
	&html<
	.LightBar-body {
		fill: url(#LightBar-bodyGrad);
		stroke: black;
		stroke-width: 1px;
		filter: url(#dropShadow);
	}

	.LightBar-redLampON {
		fill: url(#LightBar-redGrad);
		stroke: black;
		stroke-width: 1px;
	}
	.LightBar-redLampOFF {
		fill: #200000;
		stroke: black;
		stroke-width: 1px;
	}

	.LightBar-yellowLampON {
		fill: url(#LightBar-yellowGrad);
		stroke: black;
		stroke-width: 1px;
	}
	.LightBar-yellowLampOFF {
		fill: #202000;
		stroke: black;
		stroke-width: 1px;
	}
	.LightBar-greenLampON {
		fill: url(#LightBar-greenGrad);
		stroke: black;
		stroke-width: 1px;
	}
	.LightBar-greenLampOFF {
		fill: #002000;
		stroke: black;
		stroke-width: 1px;
	}
	
	.LightBar-lampON {
		fill: url(#LightBar-redGrad);
		stroke: #505050;
		stroke-width: 0.4;
	}

	.LightBar-lampOFF {
		fill: none;
		stroke: #505050;
		stroke-width: 0.4;
	}

	>
}

/// Draw the script section of this SVG meter
ClassMethod OnSVGScript()
{
	&js<
	
function LightBar_setProperty(property,value)
{
	switch (property) {
	default:
		return false;
	case 'level':
		if ((value == this.level)) {
			return;
		}

		// update level of gauge
		this.level = value;
		var id = this.meterId;
		
		// calculate number of bars to show
		// display range is 0 to 10
		
		var bars = 0;
		var fraction = 0;
		var range = this.rangeUpper - this.rangeLower;
		if (range != 0) {
			bars = (((this.level - this.rangeLower) / range) * 10);
			fraction = bars - Math.floor(bars);
		}
		
		// clip
		if (lessThanEq(bars,0)) {
			bars = 0;
		}
		if (greaterThanEq(bars,10)) {
			bars = 10;
		}

		// turn on lamps
		for (var n = 0; n != 10; n++) {
			var off = greaterThanEq(n,bars);
			var lamp = document.getElementById(id + "_lamp_" + n);
			if (lessThanEq(n,6)) {
				lamp.setAttribute("class",(off) ? "LightBar-greenLampOFF" : "LightBar-greenLampON");
			}
			else if (n == 7) {
				lamp.setAttribute("class",(off) ? "LightBar-yellowLampOFF" : "LightBar-yellowLampON");
			}
			else {
				lamp.setAttribute("class",(off) ? "LightBar-redLampOFF" : "LightBar-redLampON");
			}

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
		if (lessThanEq(this.level,this.thresholdLower)) {
			lowLamp = true;
		}
		if (greaterThanEq(this.level,this.thresholdUpper)) {
			highLamp = true;
		}
		
		// indicator lamps
		var lamp = document.getElementById(id + "_lowLamp");
		lamp.setAttribute("class",lowLamp ? "LightBar-lampON" : "LightBar-lampOFF");

		var lamp = document.getElementById(id + "_highLamp");
		lamp.setAttribute("class",highLamp ? "LightBar-lampON" : "LightBar-lampOFF");
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
<linearGradient id="LightBar-bodyGrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="50%" style="stop-color:darkgray" />
<stop offset="90%" style="stop-color:gray" />
</linearGradient>

<linearGradient id="LightBar-redGrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkred" />
<stop offset="30%" style="stop-color:#FF0000" />
<stop offset="70%" style="stop-color:#FF0000" />
<stop offset="100%" style="stop-color:darkred" />
</linearGradient>

<linearGradient id="LightBar-yellowGrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#808000" />
<stop offset="30%" style="stop-color:#FFFF00" />
<stop offset="70%" style="stop-color:#FFFF00" />
<stop offset="100%" style="stop-color:#808000" />
</linearGradient>

<linearGradient id="LightBar-greenGrad" x1="0%" y1="0%" x2="0%" y2="100%">
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
		<rect class="LightBar-body" x="#((..Width/2)-15)#" y="8" width="30" height="74" rx="5" />
	>
	
	// underlying-bars
	Set y = 11
	For n = 9:-1:0 {
		Set color = $Case(n,9:"red",8:"red",7:"yellow",:"green")
		&html<<rect class="LightBar-#(color)#LampOFF" x="#((..Width/2)-7)#" y="#(y)#" width="14" height="5" rx="2" />>
		Set y = y + 7
	}

	// bars
	Set y = 11
	For n = 9:-1:0 {
		Set color = $Case(n,9:"red",8:"red",7:"yellow",:"green")
		&html<<rect id="#(id)#_lamp_#(n)#" class="LightBar-#(color)#LampOFF" x="#((..Width/2)-7)#" y="#(y)#" width="14" height="5" rx="2" />>
		Set y = y + 7
	}

	// indicators
	&html<
		<circle id="#(id)#_highLamp" class="LightBar-lampOFF" cx="#((..Width/2)-11)#" cy="13" r="2" />
		<circle id="#(id)#_lowLamp" class="LightBar-lampOFF" cx="#((..Width/2)-11)#" cy="76.5" r="2" />
	>
}

}
