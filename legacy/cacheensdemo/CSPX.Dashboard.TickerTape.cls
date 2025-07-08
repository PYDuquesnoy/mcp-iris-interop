/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG-based TickerTape meter for Dashboard.<br>
/// The TickerTape displays recent values of metric property
/// as pieces of text sliding across a ticker tape display. Individual
/// elements are colored differently in order to visually differentiate them.
/// Repeating values are not displayed. There is no guarantee that
/// any specific element will be displayed; that is function of when the
/// metric property is updated and when the dashboard refreshes itself.
Class CSPX.Dashboard.TickerTape Extends Meter [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// Minimum width, in logical units, of this meter.
Parameter MINWIDTH As INTEGER = 10;

/// Minimum height, in logical units, of this meter.
Parameter MINHEIGHT As INTEGER = 25;

/// CSS Style applied to ticker text. E.g. "fill: blue;"
Property TextStyle As %String(MAXLEN = 100, XMLPROJECTION = "ATTRIBUTE");

ClassMethod OnSVGStyle()
{
	&html<

	.TickerTape-rect {
		stroke-width: 1px;
		stroke: gray;
		fill: black;
	}

	.TickerTape-Text {
		pointer-events: none;
		font-size: 8;
		stroke: none;
		font-family: tahoma;
	}
	>
}

ClassMethod OnSVGScript()
{
	&js<
	
function TickerTape_setProperty(property,value,idx)
{
	switch (property) {
	default:
		return false;
	case 'level':
		if (this.level == value || value == 0 || value == '') {
			return;
		}
		// stop timer
		if (null != this.timerId) {
			window.clearTimeout(this.timerId);
		}
		this.timerId = null;
		this.level = value;
		var colorArray = new Array("white","orange","yellow");            
		var numColors = colorArray.length;

		// create text node
		if (!this.textNodes) {
			this.textNodes = new Array();
			this.counter = 0; // used to calculate colors
		}
		var group = document.getElementById(this.meterId + "_TextGroup");

		var text = document.createElement("text");
		text.setAttribute("class","TickerTape-Text");
		text.setAttribute("style","fill: " + colorArray[this.counter++ % numColors] + ";" + this.textStyle);
		text.setAttribute("y", this.height - 17);
		
		// place text after last element
		var x;
		if (this.textNodes.length == 0) {
			x = this.width;
		}
		else {
			var last = this.textNodes[this.textNodes.length-1];
			x = last.getAttribute("x")*1 + last.getComputedTextLength()*1 + 5;
			x = lessThanEq(x,this.width) ? this.width : x;
		}
		text.setAttribute("x", x);

		// create the text node and append it
		var textNode = document.createTextNode(value);
		text.appendChild(textNode);
		this.textNodes[this.textNodes.length] = text;
		group.appendChild(text);

		// restart ticker timer
		this.timerId = window.setTimeout("TickerTape_timerHandler('" + this.meterId + "')",100);
		break;
	}
	return true;
}

function TickerTape_timerHandler(meterId)
{
	if (meterList[meterId]) {
		var meter = meterList[meterId];
		meter.timerId = null;
		var group = document.getElementById(meter.meterId + "_TextGroup");

		if (meter.textNodes) {
			var speed = meter.textNodes.length * 0.5;
			speed = lessThanEq(speed,1) ? 1 : speed;
			for (var n=0; lessThanEq(n,meter.textNodes.length-1); n++) {
				var txt = meter.textNodes[n];
				if (txt) {
					txt.setAttribute("x",txt.getAttribute("x") - speed);
					if (lessThanEq(txt.getAttribute("x"),txt.getComputedTextLength()*-1)) {
						// remove node
						group.removeChild(txt);
						meter.textNodes.splice(n,1);
					}
				}
			}
			
			if (0 == meter.textNodes.length) {
				// for constant values, force repeat
				meter.level = null;
			}
		}
	
		// reset timer
		meter.timerId = window.setTimeout("TickerTape_timerHandler('" + meterId + "')",100);
	}
}

>
}

/// Draw the body of this SVG meter
Method OnSVGBody()
{
	Set id = ..MeterId
	Set x = 5
	Set y = 0

	&html<
		<rect id="#(id)#_outerRect" class="TickerTape-rect" rx="2" x="#(x)#" y="#(y)#" width="#(..Width-10)#" height="#(..Height-13)#"/>
		<svg x="#(x)#" y="#(y)#" width="#(..Width-10)#" height="#(..Height-13)#">
			<g id="#(id)#_TextGroup" />
		</svg>
	>
}

/// Called by Dashboard class to generate code to
/// create an instance of this object.
/// The object instance is called <var>tMeter</var>.
Method GenerateCode(pCode As %CharacterStream, pLevel As %Integer = 1) As %Status
{
	Do ##super(pCode)
	If (..TextStyle'="") {
		Do pCode.WriteLine(" Set tMeter.TextStyle=""" _ ..TextStyle _ """")
	}
	Quit $$$OK
}

}
