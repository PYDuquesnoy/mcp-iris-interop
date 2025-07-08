/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG traffic light meter.<br>
/// This displays a value within a stylized representation of a trafic light.<br>
/// The light logic depends on the relative values of the <property>rangeLower</property> and 
/// <property>rangeUpper</property> properties and works as follows:<br>
/// If <property>rangeLower</property> is less than (or equal to) <property>rangeUpper</property>, then 
/// the light is green when the level is less than (or equal to) <property>thresholdLower</property> and 
/// the light is red when the level is greater than (or equal to) <property>thresholdUpper</property> otherwise
/// the light is yellow.<br>
/// If <property>rangeLower</property> is greater then <property>rangeUpper</property>, then 
/// the light is red when the level is less than (or equal to) <property>thresholdLower</property> and 
/// the light is green when the level is greater than (or equal to) <property>thresholdUpper</property> otherwise
/// the light is yellow.<br>
/// This control looks best when its width is half of its height.
Class %ZEN.SVGComponent.trafficLight Extends meter [ Deprecated, System = 3 ]
{

/// Optional. Style applied to outer region.
Property outerBodyStyle As %ZEN.Datatype.style;

/// Override viewBoxWidth for this component.
Parameter DEFAULTVIEWBOXWIDTH = 50;

XData SVGStyle
{
<style type="text/css">
.trafficLight-body {
	stroke: black;
	stroke-width: 1px;
}

.trafficLight-lamp {
	stroke: black;
	stroke-width: 1px;
}

</style>
}

XData SVGDef
{
<defs>
<linearGradient id="trafficLight-bodyGrad" x1="0%" y1="0%" x2="0%" y2="100%">
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
	body.setAttribute('class','trafficLight-body');
	body.setAttribute('fill','url(#trafficLight-bodyGrad)');
	body.setAttribute('style',this.outerBodyStyle);
	body.setAttribute('x',10);
	body.setAttribute('y',8);
	body.setAttribute('width',30);
	body.setAttribute('height',74);
	body.setAttribute('rx',5);
	this.svgGroup.appendChild(body);
	
	var lamp = this.document.createElementNS(SVGNS,'circle');
	lamp.setAttribute('id',this.makeId('redLamp'));
	lamp.setAttribute('class','trafficLight-lamp');
	lamp.setAttribute('fill','#200000');
	lamp.setAttribute('cx',25);
	lamp.setAttribute('cy',22);
	lamp.setAttribute('r',10);
	this.svgGroup.appendChild(lamp);

	var lamp = this.document.createElementNS(SVGNS,'circle');
	lamp.setAttribute('id',this.makeId('yellowLamp'));
	lamp.setAttribute('class','trafficLight-lamp');
	lamp.setAttribute('fill','#202000');
	lamp.setAttribute('cx',25);
	lamp.setAttribute('cy',45);
	lamp.setAttribute('r',10);
	this.svgGroup.appendChild(lamp);

	var lamp = this.document.createElementNS(SVGNS,'circle');
	lamp.setAttribute('id',this.makeId('greenLamp'));
	lamp.setAttribute('class','trafficLight-lamp');
	lamp.setAttribute('fill','#002000');
	lamp.setAttribute('cx',25);
	lamp.setAttribute('cy',68);
	lamp.setAttribute('r',10);
	this.svgGroup.appendChild(lamp);

	// label
	this.renderLabel(25,95);

	// move to initial position
	this.updateLamps();
}

/// Internal method: update lamps
ClientMethod updateLamps() [ Language = javascript ]
{
	// calculate which lamps should be on
	var redState = false;
	var greenState = false;
	var yellowState = false;

	// thresholds depend on direction of range...
	if (parseFloat(this.rangeUpper) >=parseFloat( this.rangeLower)) {
		// normal range direction
		if (parseFloat(this.value) <= parseFloat(this.thresholdLower)) {
			greenState = true;
		}
		else if (parseFloat(this.value) >= parseFloat(this.thresholdUpper)) {
			redState = true;
		}
		else {
			yellowState = true;
		}
	}
	else {
		if (parseFloat(this.value) <= parseFloat(this.thresholdLower)) {
			redState = true;
		}
		else if (parseFloat(this.value) >= (this.thresholdUpper)) {
			greenState = true;
		}
		else {
			yellowState = true;
		}
	}

	// update lamps
	var redLamp = this.findSVGElement("redLamp");
	var greenLamp = this.findSVGElement("greenLamp");
	var yellowLamp = this.findSVGElement("yellowLamp");
	
	redLamp.setAttribute("fill",redState ? "url(#glow-red)" : "#200000");
	greenLamp.setAttribute("fill",greenState ? "url(#glow-green)" : "#002000");
	yellowLamp.setAttribute("fill",yellowState ? "url(#glow-yellow)" : "#202000");
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {

	case 'outerBodyStyle':
		this[property] = value;
		this.unrender();
		this.render();
		break;

	case 'value':
		this.value = value;
		this.updateLamps();
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
