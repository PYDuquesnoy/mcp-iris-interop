/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An SVG slider control.
/// (This is still experimental and subject to change).
Class %ZEN.SVGComponent.slider Extends meter [ Deprecated, System = 3 ]
{

/// Override viewBoxWidth for this component.
Parameter DEFAULTVIEWBOXWIDTH = 10;

/// Number of tick marks to display within the slider.
Property tickMarks As %ZEN.Datatype.integer(MINVAL = 0) [ InitialExpression = 10 ];

/// If true (the default), then constrain the value of the slider so that it corresponds
/// to one of the tick marks displayed within the slider.
Property constrained As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

XData SVGStyle
{
<style type="text/css">
.slider-body {
	stroke-width: 1px;
	stroke: black;
	fill: darkgray;
	opacity: 0.75;
}

.slider-groove {
	stroke: black;
	stroke-width: 0.25px;
	fill: gray;
}

.slider-thumb {
	stroke: black;
	stroke-width: 0.25px;
	fill: #8080FF;
	stroke-linejoin: round;
}

.slider-thumbHover {
	stroke: black;
	stroke-width: 0.25px;
	fill: #FFFFB0;
	cursor: pointer;
	stroke-linejoin: round;
}

.slider-button {
	stroke: black;
	stroke-width: 0.25px;
	fill: #8080FF;
	stroke-linejoin: round;
}

.slider-buttonHover {
	stroke: black;
	stroke-width: 0.5px;
	stroke-linejoin: round;
	fill: #FFFFB0;
	cursor: pointer;
}

.slider-tick {
	stroke: black;
	stroke-width: 1px;
	opacity: 0.5;
	fill: none;
	stroke-linecap: round;
}
</style>
}

/// Render the inner SVG contents of this component.
ClientMethod renderMeter() [ Language = javascript ]
{
	// we'll set these when a move/drag operation starts
	this._dragFunc = new Function('evt','return zenPage.getComponent('+this.index+').dragThumb(evt);');
	this._thumbPos = 18;

	var body = this.document.createElementNS(SVGNS,'rect');
	body.setAttribute('id',this.makeId('body'));
	body.setAttribute('class','slider-body');
	body.setAttribute('x',0);
	body.setAttribute('y',8);
	body.setAttribute('width',10);
	body.setAttribute('height',74);
	body.setAttribute('rx',2);
	this.svgGroup.appendChild(body);

	// tick marks
	var tcount = parseInt(this.tickMarks,10);
	if (tcount > 0) {
		for (var n = 0; n < (tcount + 1); n++) {
			var yt = 18 + ((54/tcount) * n);
			var tick = this.document.createElementNS(SVGNS,'line');
			tick.setAttribute('class','slider-tick');
			tick.setAttribute('x1', 2);
			tick.setAttribute('x2', 8);
			tick.setAttribute('y1', yt);
			tick.setAttribute('y2', yt);
			this.svgGroup.appendChild(tick);
		}
	}

	// center groove
	var groove = this.document.createElementNS(SVGNS,'rect');
	groove.setAttribute('class','slider-groove');
	groove.setAttribute('x',4.5);
	groove.setAttribute('y',18);
	groove.setAttribute('width',1);
	groove.setAttribute('height',54);
	groove.setAttribute('rx',5);
	this.svgGroup.appendChild(groove);

	// thumb
	var g = this.document.createElementNS(SVGNS,'g');
	g.setAttribute('id',this.makeId('thumb'));
	this.svgGroup.appendChild(g);

	var thumb = this.document.createElementNS(SVGNS,'polyline');
	thumb.setAttribute('class','slider-thumb');
	thumb.setAttribute('id',this.makeId('thumbShape'));
	thumb.setAttribute('points', '-3,-2.5 3,0 -3,2.5 -3,-2.5');
	g.appendChild(thumb);
	thumb.addEventListener('mouseover',new Function('evt','evt.target.setAttribute("class","slider-thumbHover");'),false);
	thumb.addEventListener('mouseout',new Function('evt','evt.target.setAttribute("class","slider-thumb");'),false);
	thumb.addEventListener('mousedown',this._dragFunc,false);

	// up button
	var btn = this.document.createElementNS(SVGNS,'polyline');
	btn.setAttribute('transform', 'translate(5,10)');
	btn.setAttribute('class','slider-button');
	btn.setAttribute('points', '0,0 2.5,5 -2.5,5 0,0');
	this.svgGroup.appendChild(btn);
	btn.addEventListener('mousedown',new Function('evt','which','return zenPage.getComponent('+this.index+').mouseDownHandler(evt,"up");'),false);
	btn.addEventListener('mouseover',new Function('evt','evt.target.setAttribute("class","slider-buttonHover");'),false);
	btn.addEventListener('mouseout',new Function('evt','evt.target.setAttribute("class","slider-button");'),false);

	// down button
	var btn = this.document.createElementNS(SVGNS,'polyline');
	btn.setAttribute('transform', 'translate(5,80)');
	btn.setAttribute('class','slider-button');
	btn.setAttribute('points', '0,0 2.5,-5 -2.5,-5 0,0');
	this.svgGroup.appendChild(btn);
	btn.addEventListener('mousedown',new Function('evt','which','return zenPage.getComponent('+this.index+').mouseDownHandler(evt,"down");'),false);
	btn.addEventListener('mouseover',new Function('evt','evt.target.setAttribute("class","slider-buttonHover");'),false);
	btn.addEventListener('mouseout',new Function('evt','evt.target.setAttribute("class","slider-button");'),false);

	// label
	this.renderLabel('50%',95);

	// move to initial position
	this.updateThumb(false);
}

/// Drag handler for thumb.
ClientMethod dragThumb(evt) [ Language = javascript ]
{
	evt.stopPropagation();
	if (this.disabled) return;

	switch (evt.type) {
	case 'mousedown':
		// capture events, remember animate state
		this.document.documentElement.addEventListener('mousemove',this._dragFunc,false);
		this.document.documentElement.addEventListener('mouseup',this._dragFunc,false);
		this._animate = this.animate
		this.animate = false;

		// get curr position of thumb (relative to canvas)
		var size = this.getSizeAbsolute();
		var currZoom = (size.height / 100) * 100;
		var ty = size.y + this._thumbPos;

		// figure out offset of mouse from thumb...
		this._deltaY = ty - (evt.clientY * (100/currZoom));
	
		// remember start of operation
		this._startY = ty;
		break;
	case 'mousemove':
	case 'mouseup':
		// move thumb
		var size = this.getSizeAbsolute();
		var currZoom = size.height / 100;
		var ty = size.y + this._thumbPos;
		var currZoom = (size.height / 100) * 100;
		var dy = ((evt.clientY * (100/currZoom)) + this._deltaY) - ty;
		if (Math.abs(dy) >= 1) {
			var newvalue = this.getValueForPos(this._thumbPos + dy);
			if (newvalue != this.value) {
				this.setProperty('value',newvalue);
			}
		}
		if ('mouseup' == evt.type) {
			this.onchangeHandler();
			this.document.documentElement.removeEventListener('mousemove',this._dragFunc,false);
			this.document.documentElement.removeEventListener('mouseup',this._dragFunc,false);
			this.animate = this._animate;
		}
		break;
	}
}

/// Mouse down handler for up/down buttons.
ClientMethod mouseDownHandler(evt, which) [ Language = javascript ]
{
	evt.stopPropagation();
	if (this.disabled) return;

	if (this._timerId) {
		window.clearTimeout(this._timerId);
		delete this._timerId;
	}

	this._timerId = window.setTimeout("zenPage.getComponent(" + this.index + ").btnTimerHandler('"+which+"')",250);

	if (this._upFunc) {
		this.document.documentElement.removeEventListener('mouseup',this._upFunc,false);
	}
	this._upFunc = new Function('evt','return zenPage.getComponent('+this.index+').mouseUpHandler(evt,"'+which+'");');
	this.document.documentElement.addEventListener('mouseup',this._upFunc,false);
}

/// Timer handler for up/down buttons.
ClientMethod btnTimerHandler(which) [ Language = javascript ]
{
	delete this._timerId;
	var newvalue = this.findNextTickValue(which);

	if (newvalue != this.value) {
		this._movedByTimer = true;
		this._animate = this.animate
		this.animate = false;
		this.setProperty('value',newvalue);
		this.animate = this._animate;
		this.onchangeHandler();
		this._timerId = window.setTimeout("zenPage.getComponent(" + this.index + ").btnTimerHandler('"+which+"')",175);
	}
}

/// Mouse up handler for up/down buttons.
ClientMethod mouseUpHandler(evt, which) [ Language = javascript ]
{
	evt.stopPropagation();
	if (this.disabled) return;

	if (this._timerId) {
		window.clearTimeout(this._timerId);
		delete this._timerId;
	}

	this.document.documentElement.removeEventListener('mouseup',this._upFunc,false);
	delete this._upFunc;

	if (!this._movedByTimer) {
		var newvalue = this.findNextTickValue(which);
	
		if (newvalue != this.value) {
			this._animate = this.animate
			this.animate = false;
			this.setProperty('value',newvalue);
			this.animate = this._animate;
			this.onchangeHandler();
		}
	}
	delete this._movedByTimer;
}

/// Find the value of the next tick mark (in the direction specified
/// by <var>which</var>).
ClientMethod findNextTickValue(which) [ Language = javascript ]
{
	var newvalue = this.value;
	var delta = 0;
	var tcount = parseInt(this.tickMarks);
	tcount = (tcount > 0) ? tcount : 10;
	delta = (this.rangeUpper - this.rangeLower) / tcount;
	if (delta != 0) {
		switch(which) {
		case 'up':
			newvalue = parseFloat(this.value)+delta;
			newvalue = (newvalue > this.rangeUpper) ? this.rangeUpper : newvalue;
			break;
		case 'down':
			newvalue = parseFloat(this.value)-delta;
			newvalue = (newvalue < this.rangeLower) ? this.rangeLower : newvalue;
			break;
		}
	}
	return newvalue;
}

/// Apply rounding (if needed) to a value that will be applied to the slider.
/// If the slider is constrained, then round the value to the nearest tick mark.
ClientMethod roundValue(value) [ Language = javascript ]
{
	value = parseFloat(value);
	value = isNaN(value) ? 0 : value;
	var tcount = parseInt(this.tickMarks,10);
	var range = (this.rangeUpper - this.rangeLower);
	if (this.constrained && tcount > 0 && range != 0) {
		value -= parseFloat(this.rangeLower);
		value = (range/tcount) * Math.round((value / range) * tcount);
		value += parseFloat(this.rangeLower);
	}

	return value;
}

/// Internal method: get the value that corresponds to screen position <var>p</var>.
ClientMethod getValueForPos(p) [ Internal, Language = javascript ]
{
	p -= 18;
	if (p>=54) {
		p = 54;
	}
	if (p<=0) {
		p = 0;
	}

	return parseFloat(this.rangeLower) + ((parseFloat(this.rangeUpper) - parseFloat(this.rangeLower)) * ((54-p)/54));
}

/// Internal method: update position of thumb.
ClientMethod updateThumb(animate) [ Internal, Language = javascript ]
{
	delete this._timerId;
	var range = this.rangeUpper - this.rangeLower;
	if (null == this.currValue) {
		this.currValue = 0;
	}

	if (animate) {
		// if close enough; round off to final value
		if ((Math.abs(parseFloat(this.value) - parseFloat(this.currValue))<=(range/50))) {
			this.currValue = parseFloat(this.value);
		}
	}
	else {
		this.currValue = parseFloat(this.value);
	}

	// calculate position of thumb
	var ypos = 0;
	if (range != 0) {
		ypos = 54-(((this.currValue - this.rangeLower) / range) * 54);
	}

	// pin thumb against edges
	if (ypos>=54) {
		ypos = 54;
	}
	if (ypos<=0) {
		ypos = 0;
	}

	this._thumbPos = 18+ypos;
	var thumb = this.findSVGElement('thumb');
	if (thumb) {
		thumb.setAttribute("transform", "translate(5," + (this._thumbPos) + ")");
	}

	// if not done, move thumb again
	if (animate && (parseFloat(this.value) != parseFloat(this.currValue))) {
		var speed = (parseFloat(this.value) - parseFloat(this.currValue)) / 2;
		this.currValue = parseFloat(this.currValue) + speed;
		this._timerId = window.setTimeout("zenPage.getComponent(" + this.index + ").updateThumb(true)",50);
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'value':
		value = parseFloat(value);
		value = isNaN(value) ? 0 : value;

		// regular value
		if (this._timerId) {
			window.clearTimeout(this._timerId);
			delete this._timerId;
		}

		// update gauge
		this.value = this.roundValue(value);

		if (null == this.currValue) {
			this.currValue = 0;
		}
	
		// move to intermediate position
		var speed = (parseFloat(this.value) - parseFloat(this.currValue)) / 4;
		this.currValue = parseFloat(this.currValue) + speed;
		this.updateThumb(this.animate);
		break;

	case 'constrained':
		value = value ? true : false;
		this[property] = value;
		break;

	case 'tickMarks':
		value = parseInt(value,10);
		value = isNaN(value) ? 0 : value;
		this[property] = value;
		this.unrender();
		this.render();
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
