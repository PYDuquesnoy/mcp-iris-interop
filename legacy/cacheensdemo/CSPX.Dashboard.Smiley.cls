/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG-based Smiley Face meter for Dashboard.<br>
Class CSPX.Dashboard.Smiley Extends Meter [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// Minimum width, in logical units, of this meter.
Parameter WIDTH As INTEGER = 50;

/// Minimum height, in logical units, of this meter.
Parameter HEIGHT As INTEGER = 50;

/// Override to change default
Property Width As %Integer(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 100 ];

/// Override to change default
Property Height As %Integer(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 100 ];

ClassMethod OnSVGStyle()
{
	&html<

	.Smiley-face {
		fill: url(#Smiley-faceGrad);
		stroke: none;
		stroke-width: 2px;
		filter: url(#dropShadow);
	}

	.Smiley-eye {
		fill: none;
		stroke: green;
		stroke-width: 2px;
	}

	.Smiley-mouth {
		fill: none;
		stroke: green;
		stroke-width: 2px;
		stroke-linecap: round;
	}
	>
}

/// Draw the script section of this SVG meter
ClassMethod OnSVGScript()
{
	&js<
	
function Smiley_setProperty(property,value)
{
	switch (property) {
	default:
		return false;
	case 'level':
		if (value == this.level) {
			return;
		}
	
		// update level of smile
		this.level = value;
		var id = this.meterId;

		// calculate amount of smile
		// display range is 0 to 5, sweep for sign
		var smile = 0;
		var sweep = 1;
		
		var xeyes = false;
		var brows = false;
		
		var range = this.rangeUpper - this.rangeLower;
		if (range != 0) {
			smile = -((((this.level - this.rangeLower) / range) * 10) - 5);
		}
		
		// max smile
		if (greaterThanEq(smile,5)) {
			smile = 5;
			xeyes = true;
		}
		if (lessThanEq(smile,-5)) {
			smile = -5;
			brows = true;
		}

		if (lessThanEq(smile,0)) {
			sweep = 0;
		}
		
		// work-around for IE math bugs
		if (smile == 0) {
			smile = 0.001;
		}

		// mouth
		var mouth = document.getElementById(id + "_mouth");
		mouth.setAttribute("d", "M 28 55 a 10 " + smile + " 0 1 " + sweep + " 44 0");
		
		// eyes
		if (xeyes) {
			document.getElementById(id + "_reye").setAttribute("style","display:none;");
			document.getElementById(id + "_leye").setAttribute("style","display:none;");
			document.getElementById(id + "_rx").setAttribute("style","");
			document.getElementById(id + "_lx").setAttribute("style","");
		}
		else {
			document.getElementById(id + "_reye").setAttribute("style","");
			document.getElementById(id + "_leye").setAttribute("style","");
			document.getElementById(id + "_rx").setAttribute("style","display:none;");
			document.getElementById(id + "_lx").setAttribute("style","display:none;");
		}

		// brows
		if (brows) {
			document.getElementById(id + "_rbrow").setAttribute("style","");
			document.getElementById(id + "_lbrow").setAttribute("style","");
		}
		else {
			document.getElementById(id + "_rbrow").setAttribute("style","display:none;");
			document.getElementById(id + "_lbrow").setAttribute("style","display:none;");
		}
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
<radialGradient id="Smiley-faceGrad" cx="50" cy="45" r="35" fx="20" fy="20" gradientUnits="userSpaceOnUse" >
<stop offset="0%" style="stop-color:yellow" />
<stop offset="90%" style="stop-color:yellow" />
<stop offset="100%" style="stop-color:darkyellow" />
</radialGradient>

<radialGradient id="Smiley-faceGradRed" cx="50" cy="45" r="35" fx="20" fy="20" gradientUnits="userSpaceOnUse" >
<stop offset="0%" style="stop-color:darkred" />
<stop offset="90%" style="stop-color:darkred" />
<stop offset="100%" style="stop-color:black" />
</radialGradient>
>
}

/// Draw the body of this SVG meter
Method OnSVGBody()
{
	Set id = ..MeterId

	&html<
<svg width="#(..Width)#" height="#(..Height-5)#" viewBox="0 0 100 100">
<circle class="Smiley-face" cx="50" cy="45" r="35" />
<circle id="#(id)#_reye" class="Smiley-eye" cx="33" cy="35" r="3" />
<circle id="#(id)#_leye" class="Smiley-eye" cx="67" cy="35" r="3" />

<path id="#(id)#_rx" class="Smiley-eye" style="display:none;" d="M 31 33 L 35 37 M 31 37 L 35 33" />
<path id="#(id)#_lx" class="Smiley-eye" style="display:none;" d="M 65 33 L 69 37 M 65 37 L 69 33" />

<path id="#(id)#_rbrow" class="Smiley-eye" style="display:none;"
		d="M 28 30 a 1 1.6 -45 1 1 10 3" 
/>

<path id="#(id)#_lbrow" class="Smiley-eye" style="display:none;"
		d="M 72 30 a 1 1.6 45 1 0 -10 3" 
/>

<path id="#(id)#_mouth" class="Smiley-mouth" 
		d="M 28 55 a 10 5 0 1 0 44 0" 
/>
</svg>
	>
}

}
