/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG speedometer meter.<br>
/// This displays a value within a representation of a speedometer.<br/>
/// Note: to get the older look of this component, set the <property>stylized</property> true.
Class %ZEN.SVGComponent.speedometer Extends meter [ Deprecated, System = 3 ]
{

/// If true, the odometer will show an independent value; 
/// if false, the odometer will show the same value as the needle.
Property independentOdometer As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, render a stylized speedometer (the classic Zen visualization); 
/// if false, render a more baroque speedometer (the classic DeepSee visualization); 
Property stylized As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, render a thin needle, otherwise
/// use a wider needle.
Property thinNeedle As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If <property>independentOdometer</property> is true,
/// then this is the value displayed in the odometer.
Property odometerValue As %ZEN.Datatype.string;

/// Text for logo displayed in center of dial (for stylized display only).
Property logo As %ZEN.Datatype.caption [ InitialExpression = "Zen" ];

/// Fill color used for low indicator lamp.
Property lowLampColor As %ZEN.Datatype.color [ InitialExpression = "url(#glow-red)" ];

/// Fill color used for high indicator lamp.
Property highLampColor As %ZEN.Datatype.color [ InitialExpression = "url(#glow-red)" ];

/// Optional. Style applied to scale ring values below the low threshold value.
/// This only applies to non-stylized views.
Property lowRangeStyle As %ZEN.Datatype.style;

/// Optional. Style applied to scale ring values above the low threshold value.
/// This only applies to non-stylized views.
Property highRangeStyle As %ZEN.Datatype.style;

/// Optional. Style applied to needle.
Property needleStyle As %ZEN.Datatype.style;

/// Optional. Style applied to nub (circle over center of needle).
Property nubStyle As %ZEN.Datatype.style;

/// Optional. Style applied to outer region.
Property outerCircleStyle As %ZEN.Datatype.style;

/// Optional. Style applied to mid-region circle (where tick marks appear in non-stylized view).
/// This is beneath the "ring".
Property midCircleStyle As %ZEN.Datatype.style;

/// Optional. Style applied to mid-region ring (where tick marks appear in non-stylized view).
Property ringStyle As %ZEN.Datatype.style;

/// Optional. Style applied to inner region.
Property innerCircleStyle As %ZEN.Datatype.style;

/// Optional. Style applied to lines between value labels.
Property separatorStyle As %ZEN.Datatype.style;

/// Optional. Style applied to value labels.
Property valueLabelStyle As %ZEN.Datatype.style;

/// Optional. Style applied to odometer box.
Property odometerBoxStyle As %ZEN.Datatype.style;

/// Optional. Style applied to odometer value.
Property odometerTextStyle As %ZEN.Datatype.style;

/// Numeric format string to apply to the odometer value.
Property odometerFormat As %ZEN.Datatype.string;

XData SVGStyle
{
<style type="text/css">
/* Body in stylized view */
.speedometer-body {
	stroke: black;
	stroke-width: 0.5px;
	stroke-linejoin: round;
}

.speedometer-nub {
	stroke: black;
	stroke-width: 0.25px;
	stroke-linejoin: round;
}

.speedometer-outerCircle {
	stroke: black;
	stroke-width: 0.25px;
	stroke-linejoin: round;
}

.speedometer-midCircle {
	fill: none;
	opacity: 0.25;
	stroke: black;
	stroke-width: 0.25px;
	stroke-linejoin: round;
}

.speedometer-ring {
	fill: none;
	stroke: none;
}

.speedometer-innerCircle {
	fill: white;
	opacity: 0.25;
	stroke: black;
	stroke-width: 0.25px;
	stroke-linejoin: round;
}

/* Tick for non-stylized meter. */
.speedometer-tick {
	fill: none;
	stroke: #404040;
	stroke-width: 0.3px;
	stroke-linejoin: round;
	stroke-linecap: round;
}

/* Seperator line between value labels. */
.speedometer-separator {
	fill: none;
	stroke: #404040;
	opacity: 0.1;
	stroke-width: 0.3px;
	stroke-linejoin: round;
	stroke-linecap: round;
}

/* Target tick mark. */
.speedometer-targetTick {
	fill: none;
	stroke: #404080;
	stroke-width: 0.4px;
	stroke-linejoin: round;
	stroke-linecap: round;
}

/* Minor tick for non-stylized meter. */
.speedometer-minorTick {
	fill: none;
	stroke: #808080;
	stroke-width: 0.1px;
	stroke-linejoin: round;
	stroke-linecap: round;
}

.speedometer-tickThin {
	fill: none;
	stroke: #202020;
	stroke-width: 1px;
	stroke-linejoin: round;
	stroke-linecap: round;
}

.speedometer-tickThick {
	fill: none;
	stroke: black;
	stroke-width: 2px;
	stroke-linejoin: round;
	stroke-linecap: round;
}

.speedometer-needle {
	fill: red;
	stroke: black;
	stroke-width: 0.5px;
	stroke-linejoin: round;
	stroke-linecap: round;
}

.speedometer-shadow {
	fill: black;
	stroke: black;
	stroke-width: 0.5px;
	opacity: 0.1;
	stroke-linejoin: round;
	stroke-linecap: round;
}

.speedometer-lamp {
	stroke: #404040;
	stroke-width: 0.2;
}

.speedometer-lowRange,.speedometer-highRange {
	stroke: none;
	fill: red;
	opacity: 0.75;
}

.speedometer-levelTextBox {
	fill: white;
	stroke: black;
	stroke-width: 0.3;
	opacity: 0.5;
}

/* odometer text */
.speedometer-levelText {
	pointer-events: none;
	font-size: 4pt;
	fill: #606060;
	font-weight: bold;
	stroke: none;
	font-family: arial;
}
.speedometer-levelTextNeg {
	pointer-events: none;
	font-size: 4pt;
	fill: red;
	font-weight: bold;
	stroke: none;
	font-family: arial;
}

.speedometer-logoText {
	pointer-events: none;
	font-size: 5pt;
	fill: gray;
	stroke: none;
	font-family: tahoma verdana;
}

/* Logo in non-stylized view */
.speedometer-logoText2 {
	pointer-events: none;
	font-size: 3pt;
	fill: #606060;
	stroke: none;
	font-family: arial;
}

/* labels in non-stylized view */
.speedometer-labelText {
	pointer-events: none;
	font-size: 4pt;
	fill: black;
	stroke: none;
	font-family: arial;
}

</style>
}

XData SVGDef
{
<defs>
<linearGradient id="speedometer-bodyGrad" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:#EEEEEE" />
<stop offset="50%" style="stop-color:darkgray" />
<stop offset="90%" style="stop-color:gray" />
</linearGradient>

<linearGradient id="speedometer-bodyGrad2" x1="0%" y1="0%" x2="100%" y2="100%">
<stop offset="0%" style="stop-color:gray" />
<stop offset="20%" style="stop-color:darkgray" />
<stop offset="90%" style="stop-color:#EEEEEE" />
</linearGradient>

<radialGradient id="speedometer-blueGrad" cx="50" cy="43" r="40" fx="20" fy="20" gradientUnits="userSpaceOnUse" >
<stop offset="0%" style="stop-color:#EEEEFF" />
<stop offset="30%" style="stop-color:#DDDDFF" />
<stop offset="100%" style="stop-color:#9999FF" />
</radialGradient>

<radialGradient id="speedometer-blueGrad2" cx="50" cy="43" r="4" fx="20" fy="20" gradientUnits="userSpaceOnUse" >
<stop offset="0%" style="stop-color:#EEEEFF" />
<stop offset="30%" style="stop-color:#DDDDFF" />
<stop offset="100%" style="stop-color:#9999FF" />
</radialGradient>

</defs>
}

/// Render the inner SVG contents of this component.
ClientMethod renderMeter() [ Language = javascript ]
{
	if (this.stylized) {
		this.renderMeterStylized();
	}
	else {
		var range = this._rangeUpper - this._rangeLower;
		var delta = range / 10;
		var startVal = this._rangeLower;

		// compute range and labels
		var val = parseFloat(startVal);
		val = isNaN(val) ? 0 : val;
		this._labels = new Array();
		for (var n = 0; n < 11; n++) {
			var dval = this.getNumericAbbreviation(val,this._rangeLower,this._rangeUpper);
			this._labels[n] = dval;
			val += delta;
		}
		this.renderMeterBaroque();
	}

	this.renderOdometer();
	this.renderNeedle();

	// label
	this.renderLabel('50%',95);

	// move needle to initial position
	this.updateNeedle(false);
}

/// Render the inner SVG contents of this component using DeepSee style.
ClientMethod renderMeterBaroque() [ Internal, Language = javascript ]
{
	// outer circle body
	var body = this.document.createElementNS(SVGNS,'circle');
	body.setAttribute('class','speedometer-outerCircle');
	body.setAttribute('fill','url(#speedometer-blueGrad)');
	body.setAttribute('style',this.outerCircleStyle);
	body.setAttribute('cx',50);
	body.setAttribute('cy',43);
	body.setAttribute('r',40);
	this.svgGroup.appendChild(body);

	// lamps
	var lamp = this.document.createElementNS(SVGNS,'circle');
	lamp.setAttribute('id',this.makeId('lowLamp'));
	lamp.setAttribute('class','speedometer-lamp');
	lamp.setAttribute('fill','none');
	lamp.setAttribute('cx',28);
	lamp.setAttribute('cy',73);
	lamp.setAttribute('r',1.6);
	this.svgGroup.appendChild(lamp);

	var lamp = this.document.createElementNS(SVGNS,'circle');
	lamp.setAttribute('id',this.makeId('highLamp'));
	lamp.setAttribute('class','speedometer-lamp');
	lamp.setAttribute('fill','none');
	lamp.setAttribute('cx',72);
	lamp.setAttribute('cy',73);
	lamp.setAttribute('r',1.6);
	this.svgGroup.appendChild(lamp);

	// mid-region circle
	var body = this.document.createElementNS(SVGNS,'circle');
	body.setAttribute('class','speedometer-midCircle');
	body.setAttribute('style',this.midCircleStyle);
	body.setAttribute('cx',50);
	body.setAttribute('cy',43);
	body.setAttribute('r',20);
	this.svgGroup.appendChild(body);

	// inner circle
	var startAngle = -140;
	var endAngle = 140;
	var startAngleRdn = (startAngle-90) * Math.PI/180;
	var endAngleRdn = (endAngle-90) * Math.PI/180;
	var inRadius = 15;
	var outRadius = 20;

	var circle = this.document.createElementNS(SVGNS,'circle');
	circle.setAttribute('class','speedometer-innerCircle');
	circle.setAttribute('style',this.innerCircleStyle);
	circle.setAttribute('cx',50);
	circle.setAttribute('cy',43);
	circle.setAttribute('r',inRadius);
	this.svgGroup.appendChild(circle);

	var ringOutStartX = 50 + (outRadius * Math.cos(startAngleRdn));
	var ringOutStartY = 43 + (outRadius * Math.sin(startAngleRdn));
	var ringOutEndX = 50 + (outRadius * Math.cos(endAngleRdn));
	var ringOutEndY = 43 + (outRadius * Math.sin(endAngleRdn));

	var ringInStartX = 50 + (inRadius * Math.cos(startAngleRdn));
	var ringInStartY = 43 + (inRadius * Math.sin(startAngleRdn));
	var ringInEndX = 50 + (inRadius * Math.cos(endAngleRdn));
	var ringInEndY = 43 + (inRadius * Math.sin(endAngleRdn));

	var ring = this.document.createElementNS(SVGNS,'path');
	ring.setAttribute('class','speedometer-ring');
	ring.setAttribute('style',this.ringStyle);

	var path = 'M ' + ringOutStartX + ' ' + ringOutStartY;
	path += ' A ' +outRadius+' '+outRadius+' 0 1 1 '+ringOutEndX+' '+ringOutEndY;
	path += ' L ' + ringInEndX + ' ' + ringInEndY;
	path += ' A ' +inRadius+' '+inRadius+' 0 1 0 '+ringInStartX+' '+ringInStartY;
	path += ' z';
	ring.setAttribute('d',path);

	this.svgGroup.appendChild(ring);

	var range = this._rangeUpper - this._rangeLower;

	if (this._thresholdLower > this._rangeLower && this._thresholdLower < this._rangeUpper) {
		// lower threshold ring
		var angle = 0;
		if (range != 0) {
			angle = (((this._thresholdLower - this._rangeLower) / range) * 280) - 140;
		}
		if (angle > -141) {
			angle = (angle > 140) ? 140 : angle;
			var rangeAngleRdn = (angle-90) * Math.PI/180;

			var ringOutStartX = 50 + (outRadius * Math.cos(startAngleRdn));
			var ringOutStartY = 43 + (outRadius * Math.sin(startAngleRdn));
			var ringOutEndX = 50 + (outRadius * Math.cos(rangeAngleRdn));
			var ringOutEndY = 43 + (outRadius * Math.sin(rangeAngleRdn));

			var ringInStartX = 50 + (inRadius * Math.cos(startAngleRdn));
			var ringInStartY = 43 + (inRadius * Math.sin(startAngleRdn));
			var ringInEndX = 50 + (inRadius * Math.cos(rangeAngleRdn));
			var ringInEndY = 43 + (inRadius * Math.sin(rangeAngleRdn));

			var ring = this.document.createElementNS(SVGNS,'path');
			ring.setAttribute('class','speedometer-lowRange');
			ring.setAttribute('style',this.lowRangeStyle);

			var largeArc = (angle > 50) ? 1 : 0;
			var path = 'M ' + ringOutStartX + ' ' + ringOutStartY;
			path += ' A ' +outRadius+' '+outRadius+' 0 '+largeArc+' 1 '+ringOutEndX+' '+ringOutEndY;
			path += ' L ' + ringInEndX + ' ' + ringInEndY;
			path += ' A ' +inRadius+' '+inRadius+' 0 '+largeArc+' 0 '+ringInStartX+' '+ringInStartY;
			path += ' z';
			ring.setAttribute('d',path);

			this.svgGroup.appendChild(ring);
		}
	}

	if (this._thresholdUpper < this._rangeUpper && this._thresholdUpper > this._rangeLower) {
		// upper threshold ring
		var angle = 0;
		if (range != 0) {
			angle = (((this._thresholdUpper - this._rangeLower) / range) * 280) - 140;
		}
		if (angle < 139) {
			angle = (angle < -140) ? -140 : angle;
			var rangeAngleRdn = (angle-90) * Math.PI/180;

			var ringOutStartX = 50 + (outRadius * Math.cos(rangeAngleRdn));
			var ringOutStartY = 43 + (outRadius * Math.sin(rangeAngleRdn));
			var ringOutEndX = 50 + (outRadius * Math.cos(endAngleRdn));
			var ringOutEndY = 43 + (outRadius * Math.sin(endAngleRdn));

			var ringInStartX = 50 + (inRadius * Math.cos(rangeAngleRdn));
			var ringInStartY = 43 + (inRadius * Math.sin(rangeAngleRdn));
			var ringInEndX = 50 + (inRadius * Math.cos(endAngleRdn));
			var ringInEndY = 43 + (inRadius * Math.sin(endAngleRdn));

			var ring = this.document.createElementNS(SVGNS,'path');
			ring.setAttribute('class','speedometer-highRange');
			ring.setAttribute('style',this.highRangeStyle);

			var largeArc = (angle < -50) ? 1 : 0;
			var path = 'M ' + ringOutStartX + ' ' + ringOutStartY;
			path += ' A ' +outRadius+' '+outRadius+' 0 '+largeArc+' 1 '+ringOutEndX+' '+ringOutEndY;
			path += ' L ' + ringInEndX + ' ' + ringInEndY;
			path += ' A ' +inRadius+' '+inRadius+' 0 '+largeArc+' 0 '+ringInStartX+' '+ringInStartY;
			path += ' z';
			ring.setAttribute('d',path);

			this.svgGroup.appendChild(ring);
		}
	}

	// ticks & labels
	var n = 0;
	for (var a = -140; a<= 140; a += 28) {
		var tick = this.document.createElementNS(SVGNS,'line');
		tick.setAttribute('class','speedometer-tick');
		tick.setAttribute('x1',50);
		tick.setAttribute('y1',43 - inRadius);
		tick.setAttribute('x2',50);
		tick.setAttribute('y2',43 - outRadius);
		tick.setAttribute('transform','rotate('+a+',50,43)');
		this.svgGroup.appendChild(tick);

		var tx = 50 + ((outRadius+8) * Math.cos((a-90) * (Math.PI/180)));
		var ty = 43 + ((outRadius+8) * Math.sin((a-90) * (Math.PI/180)));

		var lblText = this.document.createElementNS(SVGNS,'text');
		lblText.setAttribute('class','speedometer-labelText');
		lblText.setAttribute('style',this.valueLabelStyle);
		lblText.setAttribute('x',tx);
		lblText.setAttribute('y',ty);
		lblText.setAttribute('text-anchor','middle');

		var textNode = this.document.createTextNode(this._labels[n]);
		lblText.appendChild(textNode);
		this.svgGroup.appendChild(lblText);

		// adjust location of label
		var th = (zenGetBBox(lblText).height);
		lblText.setAttribute('y',ty + (th / 2));
		n++;
	}

	// minor ticks
	for (var a = -140; a<= 140; a += 7) {
		if (a%28 != 0) {
			var tick = this.document.createElementNS(SVGNS,'line');
			tick.setAttribute('class','speedometer-minorTick');
			tick.setAttribute('x1',50);
			tick.setAttribute('y1',43 - inRadius);
			tick.setAttribute('x2',50);
			tick.setAttribute('y2',43 - outRadius);
			tick.setAttribute('transform','rotate('+a+',50,43)');
			this.svgGroup.appendChild(tick);
		}
	}

	// outer separator lines
	var n = 0;
	for (var a = -140; a< 140; a += 28) {
		var tick = this.document.createElementNS(SVGNS,'line');
		tick.setAttribute('class','speedometer-separator');
		tick.setAttribute('style',this.separatorStyle);
		tick.setAttribute('x1',50);
		tick.setAttribute('y1',43 - outRadius);
		tick.setAttribute('x2',50);
		tick.setAttribute('y2',3);
		tick.setAttribute('transform','rotate('+(a+28/2)+',50,43)');
		this.svgGroup.appendChild(tick);
	}

	// target
	if ('' != this._targetValue && (parseFloat(this._targetValue) > parseFloat(this._rangeLower))&& (parseFloat(this._targetValue) < parseFloat(this._rangeUpper))) {
		var angle = -200;
		if (range != 0) {
			angle = (((parseFloat(this._targetValue) - this._rangeLower) / range) * 280) - 140;
		}
		if (angle >= -140 && angle <= 140) {
			var tick = this.document.createElementNS(SVGNS,'line');
			tick.setAttribute('class','speedometer-targetTick');
			tick.setAttribute('x1',50);
			tick.setAttribute('y1',43 - inRadius);
			tick.setAttribute('x2',50);
			tick.setAttribute('y2',3);
			tick.setAttribute('transform','rotate('+angle+',50,43)');
			this.svgGroup.appendChild(tick);
		}
	}
}

/// Render the inner SVG contents of using classic Zen style.
ClientMethod renderMeterStylized() [ Internal, Language = javascript ]
{
	// speedometer body & lamps
	var body = this.document.createElementNS(SVGNS,'path');
	body.setAttribute('class','speedometer-body');
	body.setAttribute('fill','url(#speedometer-bodyGrad)');
	body.setAttribute('d','M 40 80 A 38 38 0 1 1 60 80 z');
	this.svgGroup.appendChild(body);

	var lamp = this.document.createElementNS(SVGNS,'circle');
	lamp.setAttribute('id',this.makeId('lowLamp'));
	lamp.setAttribute('class','speedometer-lamp');
	lamp.setAttribute('fill','none');
	lamp.setAttribute('cx',34.5);
	lamp.setAttribute('cy',72);
	lamp.setAttribute('r',1.8);
	this.svgGroup.appendChild(lamp);

	var lamp = this.document.createElementNS(SVGNS,'circle');
	lamp.setAttribute('id',this.makeId('highLamp'));
	lamp.setAttribute('class','speedometer-lamp');
	lamp.setAttribute('fill','none');
	lamp.setAttribute('cx',65.5);
	lamp.setAttribute('cy',72);
	lamp.setAttribute('r',1.8);
	this.svgGroup.appendChild(lamp);

	// ticks
	var style = "Thin";
	for (var a = -140; a<= 140; a += 14) {
		style = ('Thick' == style) ? 'Thin' : 'Thick';
		var tick = this.document.createElementNS(SVGNS,'line');
		tick.setAttribute('class','speedometer-tick' + style);
		tick.setAttribute('x1',50);
		tick.setAttribute('y1',12);
		tick.setAttribute('x2',50);
		tick.setAttribute('y2',9);
		tick.setAttribute('transform','rotate('+a+',50,43)');
		this.svgGroup.appendChild(tick);
	}
	// logo
	var logo = this.document.createElementNS(SVGNS,'text');
	logo.setAttribute('id',this.makeId('logo'));
	logo.setAttribute('class','speedometer-logoText');
	logo.setAttribute('x',50);
	logo.setAttribute('y',33);
	logo.setAttribute('text-anchor','middle');

	var textNode = this.document.createTextNode(this.logo);
	logo.appendChild(textNode);
	this.svgGroup.appendChild(logo);
}

/// Render the needle.
ClientMethod renderNeedle() [ Internal, Language = javascript ]
{
	var path;
	if (this.stylized) {
	 	if (this.thinNeedle) {
		 	path = 'M 50 12 L 51 55 49 55 z';
	 	}
	 	else {
		 	path = 'M 50 12 L 53 55 50 53 47 55 z';
	 	}
	}
	else {
	 	if (this.thinNeedle) {
	 		path = 'M 50 20 L 51 55 49 55 z';
	 	}
	 	else {
		 	path = 'M 50 20 L 53 55 50 53 47 55 z';
	 	}
	}
	
	// needle
	var shadow = this.document.createElementNS(SVGNS,'path');
	shadow.setAttribute('id',this.makeId('shadow'));
	shadow.setAttribute('class','speedometer-shadow');
	shadow.setAttribute('d',path);
	shadow.setAttribute('transform','rotate(1,50,43)');
	this.svgGroup.appendChild(shadow);

	var needle = this.document.createElementNS(SVGNS,'path');
	needle.setAttribute('id',this.makeId('needle'));
	needle.setAttribute('class','speedometer-needle');
	needle.setAttribute('style',this.needleStyle);
	needle.setAttribute('d',path);
	needle.setAttribute('transform','rotate(0,50,43)');
	this.svgGroup.appendChild(needle);

	// central nub
	if (this.stylized) {
		var nub = this.document.createElementNS(SVGNS,'path');
		nub.setAttribute('class','speedometer-nub');
		nub.setAttribute('fill','url(#speedometer-bodyGrad)');
		nub.setAttribute('d','M 47 51 A 8 8 0 1 1 53 51 z');
	}
	else {
		var nub = this.document.createElementNS(SVGNS,'circle');
		nub.setAttribute('class','speedometer-nub');
		nub.setAttribute('fill','url(#speedometer-blueGrad2)');
		nub.setAttribute('style',this.nubStyle);
		nub.setAttribute('cx',50);
		nub.setAttribute('cy',43);
		nub.setAttribute('r',4);
	}
	this.svgGroup.appendChild(nub);
}

/// Render the odometer.
ClientMethod renderOdometer() [ Internal, Language = javascript ]
{
	// hard-wire size of odometer
	var th = 8;
	var tw = 34;
	var oy = this.stylized ? 58 : 74;
	var tadj = 2;
	var adj = zenIsIE ? 0 : 1;

	// odometer
	var rect = this.document.createElementNS(SVGNS,'rect');
	rect.setAttribute('class','speedometer-levelTextBox');
	rect.setAttribute("style",this.odometerBoxStyle);
	rect.setAttribute('x',50 - tw/2);
	rect.setAttribute('y',oy - th/2);
	rect.setAttribute('width',tw);
	rect.setAttribute('height',th);
	rect.setAttribute('rx',1);
	this.svgGroup.appendChild(rect);

	var lvlText = this.document.createElementNS(SVGNS,'text');
	lvlText.setAttribute('id',this.makeId('levelText'));
	lvlText.setAttribute('x',50 + (tw/2) - 2 + adj);
	lvlText.setAttribute('y',oy - (th/2) + th - tadj);
	lvlText.setAttribute('text-anchor','end');

	var ovalue = this.independentOdometer ? this.odometerValue : this.value;
	lvlText.setAttribute("class",(ovalue>=0) ? "speedometer-levelText" : "speedometer-levelTextNeg");
	lvlText.setAttribute("style",this.odometerTextStyle);

	var textNode = this.document.createTextNode(ovalue);
	lvlText.appendChild(textNode);
	this.svgGroup.appendChild(lvlText);

	// force formatting of value
	this.setProperty('odometerValue',ovalue);
}

/// Internal method: update position of needle
ClientMethod updateNeedle(animate) [ Language = javascript ]
{
	delete this._timerId;
	var valueIsNaN = isNaN(this.value*1);		// DTB585 - Test thevalue for a useable value

	var range = this._rangeUpper - this._rangeLower;
	if ((null == this.currValue)||isNaN(this.currValue)) {
		// DTB585 - Force the current value to be real
		this.currValue = 0;
	}

	if (animate) {
		// if close enough; round off to final value
		if ((Math.abs(this.value*1 - this.currValue*1)<=(range/280))) {
			this.currValue = this.value*1;
		}
	}
	else {
		this.currValue = this.value*1;
	}

	// calculate needle angle from value
	// display range is -140 to 140
	// -180 is used to indicate NaN
	var angle = 0;
	if (range != 0) {
		angle = (((this.currValue - this._rangeLower) / range) * 280) - 140;
	}

	// pin needle against edges
	if (angle>=140) {
		angle = 140;
	}
	if (angle<=-140) {
		angle = -140;
	}
	
	if (valueIsNaN) {
		angle = -180;		// DTB585 - Drop the needle
	}

	var needle = this.findSVGElement('needle');
	if (needle) {
		if (angle) {
			needle.style.visibility = 'visible';		// DTB585
			needle.setAttribute("transform", "rotate(" + angle + ",50,43)");
		}
		else {
			needle.style.visibility = 'hidden';		// DTB585
		}
	}

	var shadow = this.findSVGElement('shadow');
	if (shadow) {
		if (angle) {
			shadow.style.visibility = 'visible';		// DTB585
			shadow.setAttribute("transform", "translate(3,2) rotate(" + angle + ",50,43)");
		}
		else {
			shadow.style.visibility = 'hidden';		// DTB585
		}
	}

	// indicator lamps
	var lowLamp = false;
	var highLamp = false;
	if (this.currValue <= this._thresholdLower) {
		lowLamp = true;
	}
	if (this.currValue >= this._thresholdUpper) {
		highLamp = true;
	}

	// indicator lamps
	var lamp = this.findSVGElement('lowLamp');
	if (lamp) {
		lamp.style.visibility = (valueIsNaN ? 'hidden' : 'visible');		// DTB585
		lamp.setAttribute("fill",lowLamp ? this.lowLampColor : 'none');
	}

	var lamp = this.findSVGElement('highLamp');
	if (lamp) {
		lamp.style.visibility = (valueIsNaN ? 'hidden' : 'visible');		// DTB585
		lamp.setAttribute("fill",highLamp ? this.highLampColor : 'none');
	}

	// if not done, move needle again
	if (animate && (this.value*1 != this.currValue*1)) {
		var speed = (this.value*1 - this.currValue*1) / 4;
		this.currValue = this.currValue*1 + speed;
		if (!valueIsNaN) {
			// DTB585 - If the actual value of the meter is NaN, do not try to move the needle to it!
			this._timerId = window.setTimeout("{var w = zenPage.getComponent(" + this.index + ");if (w) w.updateNeedle(true);}",50);
		}
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'rangeUpper':
	case 'rangeLower':
	case 'thresholdUpper':
	case 'thresholdLower':
	case 'thinNeedle':
	case 'stylized':
	case 'needleStyle':
	case 'lowRangeStyle':
	case 'highRangeStyle':
	case 'nubStyle':
	case 'outerCircleStyle':
	case 'midCircleStyle':
	case 'innerCircleStyle':
	case 'ringStyle':
	case 'separatorStyle':
	case 'valueLabelStyle':
	case 'odometerTextStyle':
	case 'odometerBoxStyle':
	case 'odometerFormat':
		this[property] = value;
		this.unrender();
		this.render();
		break;

	case 'odometerValue':
		var lvl = 0;
		if (this.independentOdometer) {
			this.odometerValue = value;
			var lvl = value * this.scaleFactor;
		}
		else {
			var lvl = this.value * this.scaleFactor;
		}

		// update odometer text
		var text = this.findSVGElement('levelText');
		if (text) {
			text.setAttribute("class",(lvl>=0) ? "speedometer-levelText" : "speedometer-levelTextNeg");
			if ('' != this.odometerFormat) {
				var dval = zenFormatNumber(lvl,this.odometerFormat);
			}
			else {
				var dval = Math.round(lvl);
			}
			this.setTextNode("levelText",(isNaN(dval) ? '' : dval));		// DTB585

			var tw = (zenGetBBox(text).width);
			if ((tw>36) || (lvl>=100000000) || (lvl<=-10000000)) {
				// show ### for overflow
				lvl = "\043\043\043\043\043\043";
				this.setTextNode("levelText",lvl);
			}
		}
		break;

	case 'independentOdometer':
		value = value ? true : false;
		this.independentOdometer = value;
		this.setProperty('odometerValue',this.independentOdometer ? this.odometerValue : this.value);
		break;

	case 'value':
		// regular value
		if (this._timerId) {
			// if we are in the middle of needle move; kill timer
			window.clearTimeout(this._timerId);
			delete this._timerId;
		}

		// update gauge
		this.value = value;

		if (null == this.currValue) {
			this.currValue = 0;
		}
	
		// move to intermediate needle position
		var speed = (this.value*1 - this.currValue*1) / 4;
		this.currValue = this.currValue*1 + speed;
		this.updateNeedle(this.animate);

		if (!this.independentOdometer) {
			this.setProperty('odometerValue',value);		// DTB585
		}
		break;


	case 'logo':
		this.logo = value;
		this.setTextNode('logo',this.logo);
		break;

	case 'lowLampColor':
	case 'highLampColor':
		this[property] = value;
		this.updateNeedle(false);
		break;

	case 'width':
	case 'height':
		return this.invokeSuper('setProperty',arguments);

	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Return a numeric abbreviation for a value.
/// <var>min</var> and <var>max</var> are range that value falls within.
/// E.g., 10K for 10000
ClientMethod getNumericAbbreviation(val, min, max) [ Language = javascript ]
{
	var factor = 1;
	var maxVal = factor * max;
	var minVal = factor * min;
	var absmax = Math.abs(factor * max);
	var absmin = Math.abs(factor * min);
	var test = (absmax > absmin) ? absmax : absmin;
	
	// test for abbreviated labels
	if (test >= 600000000) {
		// billions
		val = Math.round(val / 10000000)/100 + 'G';
	}
	else if (test >= 600000) {
		// millions
		val = Math.round(val / 10000)/100 + 'M';
	}
	else if (test >= 10000) {
		// thousands
		val = Math.round(val / 10)/100 + 'K';
	}
	else if (test >= 100) {
		// no abbrev: round
		val = Math.round(val);
	}
	else {
		// small number, 3 decimal digits
		val = Math.round(val*1000)/1000;
	}
	
	return val;
}

}
