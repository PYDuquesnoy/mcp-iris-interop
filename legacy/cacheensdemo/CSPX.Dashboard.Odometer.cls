/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG-based Odometer for Dashboard.
Class CSPX.Dashboard.Odometer Extends Meter [ ClassType = "", ProcedureBlock, System = 3 ]
{

Parameter MINHEIGHT = 25;

Parameter MINWIDTH = 50;

Parameter HEIGHT = 25;

Parameter WIDTH = 75;

ClassMethod OnSVGStyle()
{
	&html<
	.Odometer-body {
		fill: url(#Odometer-bodyGrad);
		stroke: black;
		stroke-width: 1px;
	}

	.Odometer-levelTextBox {
		fill: url(#Odometer-bodyGrad2);
		stroke: black;
		stroke-width: 0.8;
	}

	.Odometer-levelText {
		pointer-events: none;
		font-size: 8;
		fill: black;
		font-weight: bold;
		stroke: none;
		font-family: courier-new;
	}
	.Odometer-levelTextNeg {
		pointer-events: none;
		font-size: 8;
		fill: red;
		font-weight: bold;
		stroke: none;
		font-family: courier-new;
	}
	>
}

/// Draw the defs section of this SVG meter
ClassMethod OnSVGDefs()
{
	&html<
<linearGradient id="Odometer-bodyGrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:#EEEEEE" />
<stop offset="50%" style="stop-color:darkgray" />
<stop offset="90%" style="stop-color:gray" />
</linearGradient>

<linearGradient id="Odometer-bodyGrad2" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="0%" style="stop-color:gray" />
<stop offset="20%" style="stop-color:darkgray" />
<stop offset="90%" style="stop-color:#EEEEEE" />
</linearGradient>
>
}

ClassMethod OnSVGScript()
{
	&js<
	
function Odometer_setProperty(property,value)
{
	switch (property) {
	default:
		return false;
	case 'level':
		if (value == this.level) {
			return;
		}
		
		// update level
		this.level = value;
		var id = this.meterId;
		
		// update odometer text
		var lvl = this.level * this.scaleFactor;
		var text = document.getElementById(id + "_levelText");
		text.setAttribute("class",greaterThanEq(lvl,0) ? "Odometer-levelText" : "Odometer-levelTextNeg");

		if (greaterThanEq(lvl,10000000) || lessThanEq(lvl,-1000000)) {
			lvl = "\043\043\043\043\043\043";
		}
		else {
			lvl = Math.round(lvl);
		}
		setTextNode(id + "_levelText",lvl);

		break;
	}
	return true;
}
>
}

/// Draw the body of this SVG meter
Method OnSVGBody()
{
	// figure out number of digits
	Set tUp = $ZABS(..RangeUpper)
	Set tLow = $ZABS(..RangeLower)
	Set tMax = $S((tUp > tLow):tUp,1:tLow)

	If (tMax > 0) {
		Set digits = $ZLOG(tMax)+1
	}
	Else {
		Set digits = 2
	}

	Set off = (..Width / 2) - 5
	&html<<rect class="Odometer-body" x="#((..Width/2)-off)#" y="1" width="#(..Width-10)#" height="10" rx="2" />>
	
	Do ..DrawOdometer(..MeterId, "Odometer", ..Width/2, 2, digits)
}

/// Utility method for drawing odometer box.
/// This is called by other meters as well.
/// <var>pClass</var> is name of meter using the odometer
/// <var>pCenterX</var> is x (center) placement of odometer
/// <var>pTop</var> is y (top) placement of odometer
/// <var>pDigits</var> is number of digits within the odometer
ClassMethod DrawOdometer(id As %Integer, pClass As %String, pCenterX As %Integer, pTop As %Integer, pDigits As %Integer = 6)
{
	Set width = (pDigits + 1) * 5
	
	&html<
		<rect class="#(pClass)#-levelTextBox" x="#(pCenterX-(width/2))#" y="#(pTop)#" width="#(width)#" height="8" rx="1" />
		<text id="#(id)#_levelText" class="#(pClass)#-levelText" x="#(pCenterX+(width/2))#" y="#(pTop+7)#" text-anchor="end">0</text>
	>
	// odometer lines
	Set x = pCenterX + (width/2)
	For n = 1:1:pDigits {
		Set x = x - 4.85
		&html<<line style="stroke:gray; stroke-width:0.1;" x1="#(x)#" y1="#(pTop+.5)#" x2="#(x)#" y2="#(pTop+7.5)#" />>
	}
}

}
