/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG-based Icon meter for Dashboard.<br>
/// The Icon meter displays a user defined icon. The icon is defined 
/// using SVG; You can define a normal icon and, in addition, you 
/// can define alternate images to display when the meter level is above or below
/// its specified threshold value
Class CSPX.Dashboard.Icon Extends Meter [ ClassType = "", ProcedureBlock, System = 3 ]
{

Parameter MINHEIGHT = 25;

Parameter MINWIDTH = 50;

Parameter WIDTH = 100;

Parameter HEIGHT = 100;

Parameter SHOWLABEL = 0;

/// SVG (xml fragment) that defines the symbol to display for this meter
/// in its normal state (that is, when its value is between the high and
/// low threshold values).
Property ImageNormal As %XML.String(MAXLEN = 20000, XMLPROJECTION = "ELEMENT");

/// SVG (xml fragment) that defines the symbol to display for this meter
/// in its low state (that is, when its value is below its low threshold value).
Property ImageLow As %XML.String(MAXLEN = 20000, XMLPROJECTION = "ELEMENT");

/// SVG (xml fragment) that defines the symbol to display for this meter
/// in its high state (that is, when its value is above its threshold value).
Property ImageHigh As %XML.String(MAXLEN = 20000, XMLPROJECTION = "ELEMENT");

ClassMethod OnSVGStyle()
{
	&html<

	.Icon-body {
		fill: black;
		stroke: gray;
		stroke-width: 1px;
		filter: url(#dropShadow);
	}

	.Icon-symbolHigh {
		fill: url(#Icon-highGrad);
		stroke: black;
		stroke-width: 1px;
	}

	.Icon-symbolLow {
		fill: url(#Icon-lowGrad);
		stroke: black;
		stroke-width: 1px;
	}

	.Icon-symbolOFF {
		fill: black;
		stroke: gray;
		stroke-width: 1px;
	}

	.Icon-text {
		pointer-events: none;
		font-size: 8;
		fill: yellow;
		stroke: none;
	}

	>
}

/// Draw the script section of this SVG meter
ClassMethod OnSVGScript()
{
	&js<
	
function Icon_setProperty(property,value)
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

		// calculate if symbol should be on
		var symbolState = 'OFF';

		if (lessThanEq(this.level,tlower)) {
			// below low thresh:
			symbolState = 'Low';
		}
		else if (greaterThanEq(this.level,tupper)) {
			// above high thresh:
			symbolState = 'High';
		}
		
		// update symbol
		var symbol = document.getElementById(id + "_symbol");
		// !!!symbol.setAttribute("class", "Icon-symbol" + symbolState);

		// find correct image to show
		var image = document.getElementById(id + "_image");
		var imageLow = document.getElementById(id + "_imageLow");
		var imageHigh = document.getElementById(id + "_imageHigh");
		switch(symbolState) {
		case 'Low':
			if (imageLow) {
				imageLow.setAttribute("style","");
				image.setAttribute("style","display: none;");
			}
			else {
				image.setAttribute("style","");
			}
			if (imageHigh) {imageHigh.setAttribute("style","display: none;");}
			break;
		case 'High':
			if (imageHigh) {
				imageHigh.setAttribute("style","");
				image.setAttribute("style","display: none;");
			}
			else {
				image.setAttribute("style","");
			}
			if (imageLow) {imageLow.setAttribute("style","display: none;");}
			break
		default:
			image.setAttribute("style","");
			if (imageLow) {imageLow.setAttribute("style","display: none;");}
			if (imageHigh) {imageHigh.setAttribute("style","display: none;");}
			break;
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

<linearGradient id="Icon-highGrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:darkgreen" />
<stop offset="30%" style="stop-color:#00FF00" />
<stop offset="70%" style="stop-color:#00FF00" />
<stop offset="100%" style="stop-color:darkgreen" />
</linearGradient>

<linearGradient id="Icon-lowGrad" x1="0%" y1="0%" x2="0%" y2="100%">
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

	// backing light	
	&html<
		<rect class="Icon-body" x="#((..Width/2)-off)#" y="5" width="#(..Width-10)#" height="#(..Height-10)#" rx="2" />
		<rect id="#(id)#_symbol" class="Icon-symbolOFF" x="#((..Width/2)-off)#" y="5" width="#(..Width-10)#" height="#(..Height-10)#" rx="5" />
		<text id="#(id)#_symbolText" class="Icon-text" x="#(..Width/2)#" y="#(..Height-8)#" text-anchor="middle">#(..Label)#</text>
	>
	
	// draw user symbols
	&html<<svg id="#(id)#_image" x="#((..Width/2)-off)#" y="5" width="#(..Width-10)#" height="#(..Height-10)#" viewBox="-50 -50 100 100">>
	Write ..ImageNormal	
	&html<</svg>>

	If (..ImageLow'="") {
		&html<<svg style="display:none;" id="#(id)#_imageLow" x="#((..Width/2)-off)#" y="5" width="#(..Width-10)#" height="#(..Height-10)#" viewBox="-50 -50 100 100">>
		Write ..ImageLow	
		&html<</svg>>
	}

	If (..ImageHigh'="") {
		&html<<svg style="display:none;" id="#(id)#_imageHigh" x="#((..Width/2)-off)#" y="5" width="#(..Width-10)#" height="#(..Height-10)#" viewBox="-50 -50 100 100">>
		Write ..ImageHigh	
		&html<</svg>>
	}
}

/// Called by Dashboard class to generate code to
/// create an instance of this object.
/// The object instance is called <var>tMeter</var>.
Method GenerateCode(pCode As %CharacterStream, pLevel As %Integer = 1) As %Status
{
	Do ##super(pCode)
	Do:..ImageNormal'="" pCode.WriteLine(" Set tMeter.ImageNormal=" _ $zu(144,1,..ImageNormal))
	Do:..ImageLow'="" pCode.WriteLine(" Set tMeter.ImageLow=" _ $zu(144,1,..ImageLow))
	Do:..ImageHigh'="" pCode.WriteLine(" Set tMeter.ImageHigh=" _ $zu(144,1,..ImageHigh))
	Quit $$$OK
}

}
