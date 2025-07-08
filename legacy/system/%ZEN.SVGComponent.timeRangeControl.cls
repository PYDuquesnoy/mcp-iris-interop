/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG time range control.
/// This lets a user select a range of dates along a simple time line.
/// This is typically used to control another component, such as a chart
/// or time line.<br/>
/// The selected date range is specified by the <property>startRange</property> and
/// <property>endRange</property> properties. These are modified as the user interacts with the
/// control.<br/>
/// The <property>onchange</property> event will be fired whenever the user modifies the 
/// time range.<br/>
/// The height of this component should be set to 40.<br/>
/// 
Class %ZEN.SVGComponent.timeRangeControl Extends svgComponent [ Deprecated, System = 3 ]
{

/// Time scale to display.
Property timeScale As %ZEN.Datatype.string(VALUELIST = ",years,months,days,hours") [ InitialExpression = "years" ];

/// Earliest time displayed on the time line (as YYYY-MM-DD HH:MM:SS). Rounded to current time scale.
Property startTime As %ZEN.Datatype.string [ InitialExpression = {+$ZDT($H,3)-10} ];

/// Latest time displayed on the time line (as YYYY-MM-DD HH:MM:SS). Rounded to current time scale.
Property endTime As %ZEN.Datatype.string [ InitialExpression = {+$ZDT($H,3)+5} ];

/// Start of current time range (as YYYY-MM-DD HH:MM:SS).
/// This is modified as the user interacts with the control.
Property startRange As %ZEN.Datatype.string;

/// End of current time range (as YYYY-MM-DD HH:MM:SS).
/// This is modified as the user interacts with the control.
Property endRange As %ZEN.Datatype.string;

/// Optional. Specifies the display format used for this component.
/// (Note that the internal value of this control is always YYYY-MM-DD).
/// Possible values are:<br/>
/// <ul>
/// <li>"YMD" - Year,Month,Day</li>
/// <li>"MDY" - Month,Day,Year</li>
/// <li>"DMY" - Day,Month,Year</li>
/// </ul>
Property dateFormat As %ZEN.Datatype.string(MAXLEN = 3, VALUELIST = ",MDY,DMY,YMD") [ InitialExpression = "YMD" ];

/// Time notation used for time values.
Property timeNotation As %ZEN.Datatype.string(MAXLEN = 3, VALUELIST = ",12h,24h") [ InitialExpression = "12h" ];

/// onchange event handler:
/// This event handler is called as the user changes the value of this control.
/// The <var>final</var> parameter is passed to this event indicating if the value
/// is the final value (at the end of the current action).
/// The <var>which</var> parameter is passed to this event indicating how the value
/// as been changed: 'translate' (move to new start time), or 'scale' (change in time scale).
Property onchange As %ZEN.Datatype.eventHandler;

/// This event handler is fired when the user clicks on the config icon (which
/// is only displayed if this event is defined).
Property onconfig As %ZEN.Datatype.eventHandler;

/// SVG style applied to "thumb" of scroll bar.
Property thumbStyle As %ZEN.Datatype.style [ InitialExpression = "fill:url(#glow-silver);" ];

XData SVGStyle
{
<style type="text/css">

/* background of the timeline */
.trc-backingRect {
	fill: white;
	stroke: none;
	stroke-width: 1px;
}

/* background of the scrollbar */
.trc-scrollTrack {
	fill: #D0D0D0;
	fill-opacity: 1.0;
	stroke: #404040;
	stroke-width: 0.5px;
}

/* thumb of the scrollbar */
.trc-thumb {
	fill-opacity: 0.8;
	fill: #C0C0C0;
	stroke: #404040;
	stroke-width: 0.5px;
}

.trc-thumbHover {
	fill-opacity: 1.0;
	fill: #C0C0C0;
	stroke: #404040;
	stroke-width: 0.5px;
}

/* ridge in thumb of the scrollbar */
.trc-scrollRidge {
	fill: black;
	stroke: none;
}

/* gear icon */
.trc-gear {
	fill: rgb(100,100,120);
	stroke: none;
}

/* background of the time cells */
.trc-cellBackground {
	fill: white;
	opacity: 1.0;
	stroke: none;
}

/* rect over each cell: must have a fill */
.trc-cellRect {
	fill: blue;
	opacity: 0.05;
	stroke: none;
}

.trc-cellRectHover {
	fill: blue;
	opacity: 0.15;
	stroke: none;
}

.trc-cellOverlay {
	fill: rgb(228,228,228);
	opacity: 0.7;
	stroke: none;
}

.trc-grabber {
	fill: yellow;
	fill-opacity: 0.8;
	stroke: #404040;
	stroke-width: 2px;
	cursor: ew-resize;
}

.trc-grabberHover {
	fill: yellow;
	fill-opacity: 1.0;
	stroke: black;
	stroke-width: 2px;
	cursor: ew-resize;
}

.trc-cellOutline {
	fill: none;
	stroke: darkblue;
	stroke-width: 1px;
	stroke-linecap: round;
	stroke-linejoin: round;
}

/* major tick line within the timeline */
.trc-majorTick {
	fill: none;
	stroke: #606060;
	stroke-width: 1.5px;
}

.trc-minorTick {
	fill: none;
	stroke: #808080;
	stroke-width: 1px;
}

text.trc-tickLabel {
	fill: #404040;
	stroke: none;
	font-family: arial;
	font-size: 12px;
	pointer-events: none;
}

rect.trc-buttonRect {
	fill-opacity: 0;
	stroke: none;
}

.trc-buttonRectHover {
	fill: #F0F0F0;
	stroke: #808080;
	stroke-width: 1px;
}

.trc-buttonIcon {
	fill: #404040;
	stroke: none;
}


</style>
}

/// Reset the timeline to its initial state.
ClientMethod reset() [ Language = javascript ]
{
	this.render();
}

/// Render the inner SVG contents of this component.
ClientMethod renderContents() [ Language = javascript ]
{
	if (zenIsMissing(this.document)) return;
	this.unrender();

	// used for computations
	this._date1900 = new Date(1900,0,1,0,0,0,0);

	// we'll set these when a move/drag operation starts
	this._dragThumbFunc = new Function('evt','return zenPage.getComponent('+this.index+').dragThumb(evt);');
	this._dragGrabber1Func = new Function('evt','return zenPage.getComponent('+this.index+').dragGrabber(evt,1);');
	this._dragGrabber2Func = new Function('evt','return zenPage.getComponent('+this.index+').dragGrabber(evt,2);');

	var width = parseInt(this.width);
	var height = parseInt(this.height);
	if (width <=0) return;
	if (height <=0) return;

	// size for time line grid marks
	var btnWid = 24;
	var scrollHgt = 15;
	var cellHeight = 25;

	// find range of time to display
	var startTime = this.startTime;
	// year only?
	startTime = startTime ? (parseInt(startTime)==startTime?startTime+'-01-01':startTime) : startTime;
	var endTime = this.endTime;
	endTime = endTime ? (parseInt(endTime)==endTime?endTime+'-12-31':endTime) : endTime;

	var startDate = zenStringToDate(startTime);
	var endDate = zenStringToDate(endTime);
	startDate = startDate ? startDate : new Date(2000,0,1,0,0,0,0);
	endDate = endDate ? endDate : new Date(startDate.getFullYear(),11,31,0,0,0,0);

	// find array of units to display as well as 
	// the length of the plot area in seconds.
	var units = [];
	var startUnits,endUnits;

	switch (this.timeScale) {
	case 'months':
		// months since 1900
		var minorTicks = 4;
		this._timeDelta	= 7 * 24 * 3600;
		startUnits = ((startDate.getFullYear()-1900)*12) + Math.floor(startDate.getMonth());
		endUnits = ((endDate.getFullYear()-1900)*12) + Math.floor(endDate.getMonth());
		for (var month = startUnits; month <= endUnits+1; month++) {
			var year = parseInt(Math.floor(month/12)) + 1900;
			var d = new Date(year,(month%12),1,0,0,0,0);
			var caption = _zenResource['zenMonthShortNames'].split(',')[(month%12)];
			if ((month%12==0||month%12==6)||(month==startUnits)) {
			 	caption += ('-' + (year));
			}
			if ((endUnits-startUnits)<4) {
				// show tick for every day
				var daysInMonth = [31,28,31,30,31,30,31,31,30,31,30,31];
				if ((year%4==0) && !(year%100==0 && year%400!=0)) {
					daysInMonth[1] = 29;
				} 
				minorTicks = daysInMonth[month%12];
			}
			units[units.length] = {secs:d.getTime()/1000,caption:caption,unit:month,minorTicks:minorTicks};
		}
		break;
	case 'days':
		// days since 1900
		this._timeDelta	= 1 * 24 * 3600;
		startUnits = (startDate - this._date1900)/(24*60*60*1000);
		endUnits = (endDate - this._date1900)/(24*60*60*1000);
		for (var day = startUnits; day <= endUnits+1; day++) {
			var d = new Date(1900,0,1,0,0,0,0);
			d.setDate(this._date1900.getDate() + day);
			var caption = zenDateToString(d,false,this.dateFormat);
			units[units.length] = {secs:d.getTime()/1000,caption:caption,unit:day,minorTicks:24};
		}
		break;
	case 'hours':
		// hours since 1900
		this._timeDelta	= 1 * 3600;
		startUnits = (startDate - this._date1900)/(60*60*1000);
		endUnits = (endDate - this._date1900)/(60*60*1000);
		// get hours from dates if present
		var t = startTime ? parseInt(startTime.split(' ')[1]) : null;
		var startHours = t&&!isNaN(t) ? t : 0;
		var t = endTime ? parseInt(endTime.split(' ')[1]) : null;
		var endHours = t&&!isNaN(t) ? t : 0;
		startUnits += startHours;
		endUnits += endHours;

		for (var hour = startUnits; hour <= endUnits+1; hour++) {
			var d = new Date(1900,0,1,0,0,0,0);
			d.setTime(d.getTime() + (hour*60*60*1000));
			var hours = hour%24;
			var caption = '';
			if (this.timeNotation=='24h') {
				hours = (hours<10) ? ('0'+hours) : hours; 
				caption = hours+':00';
			}
			else {
				var post = hours>=12 ? 'pm' : 'am';
				hours = (hours==0) ? 12 : (hours>12) ? hours-12 : hours; 
				caption = hours+post;
			}
			units[units.length] = {secs:d.getTime()/1000,caption:caption,unit:hour,minorTicks:60};
		}
		break;
	case 'years':
	default:
		this._timeDelta	= 365 * 24 * 3600;
		startUnits = startDate.getFullYear();
		endUnits = endDate.getFullYear();
		for (var year = startUnits; year <= endUnits+1; year++) {
			var d = new Date(year,0,1,0,0,0,0);
			units[units.length] = {secs:d.getTime()/1000,caption:year,unit:year,minorTicks:4};
		}
		break;
	}

	var startSecs = units[0].secs;
	var endSecs = units[units.length-1].secs;
	var plotWidth = width - (btnWid*2);
	var	timeUnits = endUnits - startUnits + 1;
	var cellWidth = plotWidth / timeUnits;		// guess
	var spanSecs = (endSecs-startSecs);
	var pixPerSec = spanSecs>0 ? (plotWidth/spanSecs) : 0;

	var marginBottom = 4;
	var majorHeight = 24;
	var minorHeight = 10;
	var gridBottom = height - marginBottom;

	// background rectangle
	var backingRect = this.document.createElementNS(SVGNS,'rect');
	backingRect.setAttribute('class','trc-backingRect');
	backingRect.setAttribute('x',0);
	backingRect.setAttribute('y',0);
	backingRect.setAttribute('width',width);
	backingRect.setAttribute('height',height);
	this.svgGroup.appendChild(backingRect);

	// group to hold the time cells
	var timeCellGroup = this.document.createElementNS(SVGNS,'g');

	// group to hold the time cell rectangles
	var timeCellRectGroup = this.document.createElementNS(SVGNS,'g');

	// group to hold scrollbar
	var scrollGroup = this.document.createElementNS(SVGNS,'g');

	// back of scroll bar
	var scrollRect = this.document.createElementNS(SVGNS,'rect');
	scrollRect.setAttribute('class','trc-scrollTrack');
	scrollRect.setAttribute('x',0);
	scrollRect.setAttribute('y',0);
	scrollRect.setAttribute('width',width);
	scrollRect.setAttribute('height',scrollHgt);
	scrollGroup.appendChild(scrollRect);

	// thumb
	var thumbX = btnWid;
	var thumbWid = 0;
	var thumb = this.document.createElementNS(SVGNS,'rect');
	thumb.setAttribute('class','trc-thumb');

	// firefox does not work with url in style sheet!
	thumb.setAttribute('style',this.thumbStyle);
	thumb.setAttribute('x',thumbX);
	thumb.setAttribute('y',1);
	thumb.setAttribute('rx',1);
	thumb.setAttribute('width',thumbWid);
	thumb.setAttribute('height',scrollHgt-2);
	scrollGroup.appendChild(thumb);
	this._thumb = thumb;

	thumb.addEventListener('mouseover',new Function('evt','evt.target.setAttribute("class","trc-thumbHover");'),false);
	thumb.addEventListener('mouseout',new Function('evt','evt.target.setAttribute("class","trc-thumb");'),false);
	thumb.addEventListener('mousedown',this._dragThumbFunc,false);

	// ridges
	this._ridges = [];
	for (var r = 0; r < 3; r++) {
		var ridge = this.document.createElementNS(SVGNS,'rect');
		ridge.setAttribute('class','trc-scrollRidge');
		ridge.setAttribute('x',thumbX + thumbWid/2 + ((r-1)*3));
		ridge.setAttribute('y',3);
		ridge.setAttribute('width',1);
		ridge.setAttribute('height',scrollHgt-6);
		scrollGroup.appendChild(ridge);
		this._ridges[r] = ridge;
		ridge.addEventListener('mousedown',this._dragThumbFunc,false);
	}

	// buttons
	// left
	var ix = btnWid/2;
	var iy = scrollHgt/2;

	var f1Click = new Function('evt','return zenPage.getComponent('+this.index+').scrollBtnClick(evt,1);')
	var f1Over = new Function('evt','return zenPage.getComponent('+this.index+').scrollBtnOver(evt,1);')
	var f1Out = new Function('evt','return zenPage.getComponent('+this.index+').scrollBtnOut(evt,1);')
	var f2Click = new Function('evt','return zenPage.getComponent('+this.index+').scrollBtnClick(evt,2);')
	var f2Over = new Function('evt','return zenPage.getComponent('+this.index+').scrollBtnOver(evt,2);')
	var f2Out = new Function('evt','return zenPage.getComponent('+this.index+').scrollBtnOut(evt,2);')

	var brect = this.document.createElementNS(SVGNS,'rect');
	brect.setAttribute('class','trc-buttonRect');
	brect.setAttribute('id',this.makeId('btn1'));
	brect.setAttribute('x',0);
	brect.setAttribute('y',0);
	brect.setAttribute('width',btnWid);
	brect.setAttribute('height',scrollHgt);
	scrollGroup.appendChild(brect);

	brect.addEventListener('click',f1Click,false);
	brect.addEventListener('mouseover',f1Over,false);
	brect.addEventListener('mouseout',f1Out,false);

	var icon = this.document.createElementNS(SVGNS,'path');
	icon.setAttribute('class','trc-buttonIcon');
	icon.setAttribute('d','M '+(ix+4)+' '+iy+' L '+(ix-4)+' '+iy+'M '+ix+' '+(iy-4)+' L '+(ix-4)+' '+iy+' '+ix+' '+(iy+4));
	scrollGroup.appendChild(icon);

	icon.addEventListener('click',f1Click,false);
	icon.addEventListener('mouseover',f1Over,false);
	icon.addEventListener('mouseout',f1Out,false);

	// right
	var ix = width-(btnWid/2);

	var brect = this.document.createElementNS(SVGNS,'rect');
	brect.setAttribute('class','trc-buttonRect');
	brect.setAttribute('id',this.makeId('btn2'));
	brect.setAttribute('x',width-btnWid);
	brect.setAttribute('y',0);
	brect.setAttribute('width',btnWid);
	brect.setAttribute('height',scrollHgt);
	scrollGroup.appendChild(brect);

	brect.addEventListener('click',f2Click,false);
	brect.addEventListener('mouseover',f2Over,false);
	brect.addEventListener('mouseout',f2Out,false);

	var icon = this.document.createElementNS(SVGNS,'path');
	icon.setAttribute('class','trc-buttonIcon');
	icon.setAttribute('d','M '+(ix-4)+' '+iy+' L '+(ix+4)+' '+iy+'M '+ix+' '+(iy-4)+' L '+(ix+4)+' '+iy+' '+ix+' '+(iy+4));
	scrollGroup.appendChild(icon);

	icon.addEventListener('click',f2Click,false);
	icon.addEventListener('mouseover',f2Over,false);
	icon.addEventListener('mouseout',f2Out,false);

	// draw the grid line (time cells)

	// background rectangle for cells
	var cellRect = this.document.createElementNS(SVGNS,'rect');
	cellRect.setAttribute('class','trc-cellBackground');
	cellRect.setAttribute('x',btnWid);
	cellRect.setAttribute('y',0);
	cellRect.setAttribute('width',width>btnWid*2?(width-(btnWid*2)):0);
	cellRect.setAttribute('height',cellHeight);
	timeCellGroup.appendChild(cellRect);

	// if many timeUnits, do not label each one 
	var labelFreq = 1;
	if (cellWidth < 75) {
		switch (this.timeScale) {
		case 'years':
		default:
			labelFreq = 5;
			break;
		case 'months':
			labelFreq = 3;
			if (cellWidth < 30) {
				labelFreq = 12;
			}
			if (cellWidth < 12) {
				labelFreq = 24;
			}
			break;
		case 'days':
			labelFreq = 7;
			if (cellWidth < 25) {
				labelFreq = 14;
			}
			if (cellWidth < 10) {
				labelFreq = 60;
			}
			break;
		case 'hours':
			labelFreq = 3;
			if (cellWidth < 25) {
				labelFreq = 6;
			}
			break;
		}
	}

	if (cellWidth>2) {
		for (var unit = 0; unit < units.length-1; unit++) {
			var info = units[unit];
			var x = ((info.secs-startSecs) * pixPerSec) + btnWid;
			var x2 = ((units[unit+1].secs-startSecs) * pixPerSec) + btnWid;
			var cWidth = x2-x;
			if (cWidth<=0) {
				continue;
			}

			switch (this.timeScale) {
			case 'years':
			default:
				caption = unit;
				break;
			case 'months':
				var year = parseInt(Math.floor(unit/12)) + 1900;
				caption = _zenResource['zenMonthShortNames'].split(',')[(unit%12)];
				if ((unit%12==0||unit%12==6)||(unit==startUnits)) {
				 	caption += ('-' + (year));
				}
				break;
			case 'days':
				var d = new Date(1900,0,1,0,0,0,0);
				d.setDate(this._date1900.getDate() + Math.floor(unit));
				caption = zenDateToString(d,false,this.dateFormat);
				break;
			case 'hours':
				var hours = unit%24;
				if (this.timeNotation=='24h') {
					hours = (hours<10) ? ('0'+hours) : hours; 
					caption = hours+':00';
				}
				else {
					var post = hours>=12 ? 'pm' : 'am';
					hours = (hours==0) ? 12 : (hours>12) ? hours-12 : hours; 
					caption = hours+post;
				}
				break;
			}

			// Major tick
			var tick = this.document.createElementNS(SVGNS,'line');
			tick.setAttribute('class','trc-majorTick');
			tick.setAttribute('x1',x);
			tick.setAttribute('x2',x);
			if (unit%labelFreq==0) {
				tick.setAttribute('y1',cellHeight-majorHeight);
				tick.setAttribute('y2',cellHeight);
			}
			else {
				tick.setAttribute('y1',cellHeight-majorHeight);
				tick.setAttribute('y2',cellHeight-majorHeight+minorHeight);
			}
			timeCellGroup.appendChild(tick);

			// label
			if (unit%labelFreq==0 && info.caption) {
				var lblText = this.document.createElementNS(SVGNS,'text');
				lblText.setAttribute('class','trc-tickLabel');
				lblText.setAttribute('x',x+4);
				lblText.setAttribute('y',cellHeight-3);
				var textNode = this.document.createTextNode(info.caption);
				lblText.appendChild(textNode);
				timeCellGroup.appendChild(lblText);
			}

			// minor ticks
			var minorCount = labelFreq==1?info.minorTicks:0;
			if (minorCount>1) {
				var freq = Math.floor(10 / (cWidth/minorCount)) + 1;
				for (var j = 1; j < minorCount; j++) {
					if ((j%freq)==0) {
						var xm = x + (j*(cWidth/minorCount));

						var tick = this.document.createElementNS(SVGNS,'line');
						tick.setAttribute('class','trc-minorTick');
						tick.setAttribute('x1',xm);
						tick.setAttribute('x2',xm);
						tick.setAttribute('y1',cellHeight-majorHeight);
						tick.setAttribute('y2',cellHeight-majorHeight+minorHeight);
						timeCellGroup.appendChild(tick);
					}
				}
			}
		
			// rectangle to catch mouse click
			var unitRect = this.document.createElementNS(SVGNS,'rect');
			unitRect.setAttribute('class','trc-cellRect');
			unitRect.setAttribute('id',this.makeId('rect_'+info.unit));
			unitRect.setAttribute('x',x);
			unitRect.setAttribute('y',0);
			unitRect.setAttribute('width',cWidth);
			unitRect.setAttribute('height',cellHeight);
			timeCellRectGroup.appendChild(unitRect);

			var fClick = new Function('evt','return zenPage.getComponent('+this.index+').unitRectClick(evt,'+info.unit+');')
			var fOver = new Function('evt','return zenPage.getComponent('+this.index+').unitRectOver(evt,'+info.unit+');')
			var fOut = new Function('evt','return zenPage.getComponent('+this.index+').unitRectOut(evt,'+info.unit+');')
			unitRect.addEventListener('click',fClick,false);
			unitRect.addEventListener('mouseover',fOver,false);
			unitRect.addEventListener('mouseout',fOut,false);
		}
	}

	// cover plates to clip time line
	var plate = this.document.createElementNS(SVGNS,'rect');
	plate.setAttribute('class','trc-backingRect');
	plate.setAttribute('x',0);
	plate.setAttribute('y',0);
	plate.setAttribute('width',btnWid);
	plate.setAttribute('height',cellHeight);
	timeCellGroup.appendChild(plate);
	
	var plate = this.document.createElementNS(SVGNS,'rect');
	plate.setAttribute('class','trc-backingRect');
	plate.setAttribute('x',width-btnWid);
	plate.setAttribute('y',0);
	plate.setAttribute('width',btnWid);
	plate.setAttribute('height',cellHeight);
	timeCellGroup.appendChild(plate);

	// overlay
	var overBefore = this.document.createElementNS(SVGNS,'rect');
	overBefore.setAttribute('class','trc-cellOverlay');
	overBefore.setAttribute('x',btnWid);
	overBefore.setAttribute('y',0);
	overBefore.setAttribute('width',0);
	overBefore.setAttribute('height',cellHeight);
	timeCellGroup.appendChild(overBefore);
	this._overBefore = overBefore;

	var overAfter = this.document.createElementNS(SVGNS,'rect');
	overAfter.setAttribute('class','trc-cellOverlay');
	overAfter.setAttribute('x',thumbX+thumbWid);
	overAfter.setAttribute('y',0);
	overAfter.setAttribute('width',0);
	overAfter.setAttribute('height',cellHeight);
	timeCellGroup.appendChild(overAfter);
	this._overAfter = overAfter;

	// outline path
	var outline = this.document.createElementNS(SVGNS,'path');
	outline.setAttribute('class','trc-cellOutline');
	timeCellGroup.appendChild(outline);
	this._outline = outline;

	// grabber
	var grabber1 = this.document.createElementNS(SVGNS,'rect');
	grabber1.setAttribute('class','trc-grabber');
	grabber1.setAttribute('x',thumbX-4);
	grabber1.setAttribute('y',3);
	grabber1.setAttribute('rx',5);
	grabber1.setAttribute('width',8);
	grabber1.setAttribute('height',cellHeight-6);
	timeCellRectGroup.appendChild(grabber1);
	this._grabber1 = grabber1;
	grabber1.addEventListener('mouseover',new Function('evt','evt.target.setAttribute("class","trc-grabberHover");'),false);
	grabber1.addEventListener('mouseout',new Function('evt','evt.target.setAttribute("class","trc-grabber");'),false);
	grabber1.addEventListener('mousedown',this._dragGrabber1Func,false);

	var grabber2 = this.document.createElementNS(SVGNS,'rect');
	grabber2.setAttribute('class','trc-grabber');
	grabber2.setAttribute('x',thumbX+thumbWid-4);
	grabber2.setAttribute('y',3);
	grabber2.setAttribute('rx',5);
	grabber2.setAttribute('width',8);
	grabber2.setAttribute('height',cellHeight-6);
	timeCellRectGroup.appendChild(grabber2);
	this._grabber2 = grabber2;
	grabber2.addEventListener('mouseover',new Function('evt','evt.target.setAttribute("class","trc-grabberHover");'),false);
	grabber2.addEventListener('mouseout',new Function('evt','evt.target.setAttribute("class","trc-grabber");'),false);
	grabber2.addEventListener('mousedown',this._dragGrabber2Func,false);

	// move time cells to bottom
	var tcy = height - cellHeight - scrollHgt;

	timeCellGroup.setAttribute('transform','translate(0,'+tcy+')');
	this.svgGroup.appendChild(timeCellGroup);

	timeCellRectGroup.setAttribute('transform','translate(0,'+tcy+')');
	this.svgGroup.appendChild(timeCellRectGroup);

	var sy = height - scrollHgt;
	scrollGroup.setAttribute('transform','translate(0,'+sy+')');
	this.svgGroup.appendChild(scrollGroup);

	if (this.onconfig) {
		// "gear" icon
		var g = this.document.createElementNS(SVGNS,'g');
		g.setAttribute('transform','translate(11,5) scale(0.03, -0.03)');
		timeCellRectGroup.appendChild(g);
		var gear = this.document.createElementNS(SVGNS,'path');
		gear.setAttribute('d','M 0 0 c0 -47 -49 -74 -90 -50 -49 28 -96 -17 -60 -58 16 -18 17 -26 7 -48 -14 -33 -26 -42 -54 -42 -20 0 -23 -5 -23 -40 0 -35 3 -40 23 -40 34 0 47 -13 53 -51 4 -25 1 -39 -10 -48 -14 -12 -14 -15 1 -37 17 -27 45 -31 65 -10 10 10 20 11 43 3 35 -12 45 -24 45 -54 0 -20 5 -23 40 -23 35 0 40 3 40 23 0 28 9 40 42 54 22 10 30 9 49 -8 12 -10 23 -19 25 -19 2 0 15 12 29 26 25 25 25 25 6 52 -29 42 -5 91 47 92 19 0 22 5 22 40 0 35 -3 40 -22 40 -30 0 -41 9 -55 42 -10 22 -9 30 7 51 17 22 18 26 4 45 -17 25 -49 28 -70 7 -12 -12 -20 -12 -42 -2 -33 14 -42 25 -42 55 0 19 -5 22 -40 22 -35 0 -40 -3 -40 -22z m86 -144 c40 -19 66 -70 58 -113 -6 -27 -46 -80 -63 -82 -3 0 -17 -2 -29 -5 -36 -6 -89 23 -106 60 -24 50 -7 109 40 137 33 20 62 21 100 3z');
		gear.setAttribute('class','trc-gear');
		g.appendChild(gear);

		// rect to grab click 
		var evtRect = this.document.createElementNS(SVGNS,'rect');
		evtRect.setAttribute('x',-350);
		evtRect.setAttribute('y',-600);
		evtRect.setAttribute('width',btnWid/0.03);
		evtRect.setAttribute('height',btnWid/0.03);
		evtRect.setAttribute('style','fill:transparent; stroke:none;');
		g.appendChild(evtRect);

		var gClick = new Function('evt','return zenPage.getComponent('+this.index+').onconfigHandler();');
		evtRect.addEventListener('click',gClick,false);
	}

	// set up info for scroll bar and other methods
	this._startSecs = startSecs;
	this._endSecs = endSecs;
	this._plotWidth = plotWidth;
	this._spanSecs  = spanSecs;
	this._pixPerSec = pixPerSec;

	// set location of scroll bar
	this.updateScrollbar();
}

/// Resize all elements related to current range.
ClientMethod updateScrollbar() [ Language = javascript ]
{
	var width = parseInt(this.width);
	var height = parseInt(this.height);
	if (width <=0) return;
	if (height <=0) return;
	
	var btnWid = 24;
	var scrollHgt = 16;
	var cellHeight = 25;

	// compute thumb size
	var cellWidth = this._cellWidth;

	var startRange = this.startRange;
	var endRange = this.endRange;
	var startRangeDate = zenStringToDate(startRange);
	var endRangeDate = zenStringToDate(endRange);

	if (!startRangeDate || !endRangeDate) {
		var startX = btnWid;
		var endX = btnWid;
	}
	else {
		// convert range to pixels
		var startUnits = this._startUnits;
		var endUnits = this._endUnits;
		var	timeUnits = endUnits - startUnits + 1;

		if (this.timeScale=='hours') {
			// get hours from dates if present
			var t = startRange ? parseInt(startRange.split(' ')[1]) : null;
			var startHours = t&&!isNaN(t) ? t : 0;
			var t = endRange ? parseInt(endRange.split(' ')[1]) : null;
			var endHours = t&&!isNaN(t) ? t : 0;
			if (startHours) {
				startRangeDate.setTime(startRangeDate.getTime()+(startHours*3600*1000));
			}
			if (endHours) {
				endRangeDate.setTime(endRangeDate.getTime()+(endHours*3600*1000));
			}
		}

		// find outer and inner ranges in seconds (since 1900)
		var pixPerSec = this._pixPerSec;
		var offset = this._startSecs;
		var startX = pixPerSec * ((startRangeDate.getTime()/1000) - offset) + btnWid;
		var endX = pixPerSec * ((endRangeDate.getTime()/1000) - offset) + btnWid;

		startX = startX > btnWid ? startX : btnWid;
		endX = endX < (width-btnWid) ? endX : width-btnWid;
		endX = endX > startX ? endX : startX;
	}

	var thumbX = startX;
	var thumbWid = endX - startX;
	thumbWid = thumbWid > 0 ? thumbWid : 0;

	this._thumbPos = thumbX;
	this._thumbWid = thumbWid;
	
	if (this._thumb) {
		this._thumb.setAttribute('x',thumbX);
		this._thumb.setAttribute('width',thumbWid<10?10:thumbWid);
	}
	if (this._ridges) {
		for (var r = 0; r < this._ridges.length; r++) {
			this._ridges[r].setAttribute('x',thumbX + thumbWid/2 + ((r-1)*3));
			if (thumbWid < 10) {
				this._ridges[r].setAttribute('style','display:none;');
			}
			else {
				this._ridges[r].setAttribute('style','');
			}
		}
	}
	
	if (this._overBefore) {
		this._overBefore.setAttribute('x',0);
		this._overBefore.setAttribute('width',thumbX);
	}
	if (this._overAfter) {
		this._overAfter.setAttribute('x',thumbX+thumbWid);
		this._overAfter.setAttribute('y',0);
		this._overAfter.setAttribute('width',width>(thumbX+thumbWid)?width-(thumbX+thumbWid):0);
	}
	
	if (this._outline) {
		var outline = 'M '+0+','+0+' L '+thumbX+','+0;
		outline += ' '+thumbX+','+(cellHeight)+' '+(thumbX+thumbWid)+','+(cellHeight);
		outline += ' '+(thumbX+thumbWid)+','+0+' '+(width)+','+0;
		this._outline.setAttribute('d',outline);
	}

	if (this._grabber1) {
		this._grabber1.setAttribute('x',thumbX-3);
	}
	if (this._grabber2) {
		this._grabber2.setAttribute('x',thumbX+thumbWid-3);
	}
}

/// Return the time value (as yyyy-mm-dd [hh]) for the given x position on the time line.
ClientMethod getTimeForPos(x) [ Language = javascript ]
{
	var width = parseInt(this.width);
	var btnWid = 24;

	// find position in seconds
	var posSecs = 0;
	if (x <= btnWid) {
		posSecs = this._startSecs;
	}
	else if (x >= (width-btnWid)) {
		posSecs = this._endSecs;
	}
	else {
		var pct = (x-btnWid)/(width-(btnWid*2));
		posSecs = Math.floor(this._startSecs + (pct*(this._endSecs-this._startSecs)));
	}

	var dt = new Date(1900,0,1,0,0,0,0);
	dt.setTime(posSecs*1000);
	var time = zenDateToString(dt);
	switch (this.timeScale) {
	case 'hours':
		var hour = (Math.floor(posSecs/(3600)))%24;
		// adjust for UTC!!! (not right-- causes jumps!)
		var tzone = dt.getTimezoneOffset()/60;
		hour -= tzone;
		hour = hour%24;
		hour = hour<0 ? 24+hour : hour;
		time = time + ' ' + ((hour<10)?'0'+hour:hour) + ':00';
		break;
	}
	
	return time;
}

/// Raise onchange event.
ClientMethod onchangeHandler(final, which) [ Language = javascript ]
{
	// call user event handler 
	zenInvokeCallbackMethod(this.onchange,this,'onchange','final',final,'which',which);
}

/// Raise onconfig event.
ClientMethod onconfigHandler() [ Language = javascript ]
{
	// call user event handler 
	zenInvokeCallbackMethod(this.onconfig,this,'onconfig');
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'width':
	case 'height':
		return this.invokeSuper('setProperty',arguments);

	case 'startTime':
	case 'endTime':
	case 'dateFormat':
	case 'timeNotation':
	case 'thumbStyle':
		this[property] = value;
		this.render();
		break;

	case 'startRange':
	case 'endRange':
		this[property] = value;
		this.updateScrollbar();
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Click on scroll button.
ClientMethod scrollBtnClick(evt, which) [ Language = javascript ]
{
	evt.preventDefault();
	if (this.startRange && this.endRange) {
		var startDate = zenStringToDate(this.startRange);
		var endDate = zenStringToDate(this.endRange);
		var delta = (this._timeDelta ? this._timeDelta : 0) * 1000;
		if (which==1) {
			startDate.setTime(startDate.getTime()-delta);
			endDate.setTime(endDate.getTime()-delta);
		}
		else {
			startDate.setTime(startDate.getTime()+delta);
			endDate.setTime(endDate.getTime()+delta);
		}
		this.startRange = zenDateToString(startDate);
		this.endRange = zenDateToString(endDate);
		this.updateScrollbar();
		this.onchangeHandler(true,'translate');
	}
}

/// Mouse over scroll button.
ClientMethod scrollBtnOver(evt, which) [ Language = javascript ]
{
	evt.stopPropagation();
	var btn = this.findSVGElement('btn'+which);
	if (btn) {
		btn.setAttribute('class','trc-buttonRectHover');
	}
}

/// Mouse out of scroll button.
ClientMethod scrollBtnOut(evt, which) [ Language = javascript ]
{
	evt.stopPropagation();
	var btn = this.findSVGElement('btn'+which);
	if (btn) {
		btn.setAttribute('class','trc-buttonRect');
	}
}

/// Mouse over cell rect.
ClientMethod unitRectOver(evt, which) [ Language = javascript ]
{
	evt.stopPropagation();
	if (!this._inDrag) {
		var rect = this.findSVGElement('rect_'+which);
		if (rect) {
			rect.setAttribute('class','trc-cellRectHover');
		}
	}
}

/// Mouse out of cell rect.
ClientMethod unitRectOut(evt, which) [ Language = javascript ]
{
	evt.stopPropagation();
	if (!this._inDrag) {
		var rect = this.findSVGElement('rect_'+which);
		if (rect) {
			rect.setAttribute('class','trc-cellRect');
		}
	}
}

/// Mouse click on cell rect.
ClientMethod unitRectClick(evt, which) [ Language = javascript ]
{
	// set range to current cell
	switch(this.timeScale) {
	case 'years':
		this.startRange = which + '-01-01';
		this.endRange = which + '-12-31';
		break;
	case 'months':
		var year = parseInt(Math.floor(which/12)) + 1900;
		var month = which%12;

		var daysInMonth = [31,28,31,30,31,30,31,31,30,31,30,31];
		if ((year%4==0) && !(year%100==0 && year%400!=0)) {
			daysInMonth[1] = 29;
		} 

		var dmonth = month + 1;
		var dday = 1;
		this.startRange = year+'-'+((dmonth<10)?'0'+dmonth:dmonth)+'-'+((dday<10)?'0'+dday:dday);

		var dday = daysInMonth[month];
		this.endRange = year+'-'+((dmonth<10)?'0'+dmonth:dmonth)+'-'+((dday<10)?'0'+dday:dday);
		break;
	case 'days':
		var day = which;
		var d = new Date(1900,0,1,0,0,0,0);
		d.setDate(this._date1900.getDate() + Math.floor(day));
		this.startRange = zenDateToString(d);

		var d = new Date(1900,0,1,0,0,0,0);
		d.setDate(this._date1900.getDate() + Math.floor(day) + 1);
		this.endRange = zenDateToString(d);
		break;

	case 'hours':
		var day = Math.floor(which / 24);
		var hour = which % 24;
		
		var d = new Date(1900,0,1,0,0,0,0);
		d.setDate(this._date1900.getDate() + Math.floor(day));
		this.startRange = zenDateToString(d) + ' ' + ((hour<10)?'0'+hour:hour) + ':00';

		this.endRange = zenDateToString(d) + ' ' + ((hour<10)?'0'+hour:hour) + ':59';
		break;

	default:
		break;
	}

	this.render();
	this.onchangeHandler(true,'translate');
}

/// Drag handler for thumb.
ClientMethod dragThumb(evt) [ Language = javascript ]
{
	evt.preventDefault();
	evt.stopPropagation();
	if (this.disabled) return;

	switch (evt.type) {
	case 'mousedown':
		// capture events
		this.document.documentElement.addEventListener('mousemove',this._dragThumbFunc,false);
		this.document.documentElement.addEventListener('mouseup',this._dragThumbFunc,false);

		// get curr position of thumb (relative to canvas)
		var size = this.getSizeAbsolute();
		var tx = size.x + this._thumbPos;

		// figure out offset of mouse from thumb...
		this._deltaX = tx - evt.clientX;
	
		// remember start of operation
		this._startX = tx;

		this._inDrag = true;
		break;
	case 'mousemove':
	case 'mouseup':
		// move thumb
		var size = this.getSizeAbsolute();
		var tx = size.x + this._thumbPos;
		var dx = evt.clientX + this._deltaX - tx;
		
		if (Math.abs(dx) >= 1) {
			var startRange = this.startRange;
			var newTime = this.getTimeForPos(this._thumbPos + dx);
			if (newTime != startRange) {
				var delta = zenStringToDate(newTime) - (startRange ? zenStringToDate(startRange) : (this._startSecs*1000));
				// move end range
				if (this.endRange) {
					// don't let end move past the edge
					var d = zenStringToDate(this.endRange);
					d.setTime(d.getTime() + delta);
					var test = (d.getTime()/1000);
					if (this._endSecs && test > this._endSecs) {
						var span = zenStringToDate(this.endRange) - (startRange ? zenStringToDate(startRange) : (this._startSecs*1000));
						var d = new Date(1900,0,1,0,0,0,0);
						d.setTime(this._endSecs*1000);
						this.endRange = zenDateToString(d);
						var d2 = zenStringToDate(this.endRange);
						d2.setTime(d2.getTime() - span);
						newTime = zenDateToString(d2);
					}
					else {
						this.endRange = zenDateToString(d);
					}
				}
				else {
					this.endRange = newTime;
				}
				this.setProperty('startRange',newTime);
			}
		}
		if ('mouseup' == evt.type) {
			this.onchangeHandler(true,'translate');
			this.document.documentElement.removeEventListener('mousemove',this._dragThumbFunc,false);
			this.document.documentElement.removeEventListener('mouseup',this._dragThumbFunc,false);
			this._inDrag = false;
		}
		else {
			this.onchangeHandler(false,'translate');
		}
		break;
	}
}

/// Drag handler for grabber.
ClientMethod dragGrabber(evt, which) [ Language = javascript ]
{
	evt.preventDefault();
	evt.stopPropagation();
	if (this.disabled) return;

	switch (evt.type) {
	case 'mousedown':
		// capture events
		if (which==1) {
			this.document.documentElement.addEventListener('mousemove',this._dragGrabber1Func,false);
			this.document.documentElement.addEventListener('mouseup',this._dragGrabber1Func,false);
		}
		else {
			this.document.documentElement.addEventListener('mousemove',this._dragGrabber2Func,false);
			this.document.documentElement.addEventListener('mouseup',this._dragGrabber2Func,false);
		}

		this._inDrag = true;

		// get curr position of grabber (relative to canvas)
		var size = this.getSizeAbsolute();
		if (which==1) {
			var tx = size.x + this._thumbPos;
		}
		else {
			var tx = size.x + this._thumbPos + this._thumbWid;
		}

		// figure out offset of mouse from grabber...
		this._deltaX = tx - evt.clientX;
	
		// remember start of operation
		this._startX = tx;
		break;
	case 'mousemove':
	case 'mouseup':
		// move grabber
		var size = this.getSizeAbsolute();
		if (which==1) {
			var tx = size.x + this._thumbPos;
		}
		else {
			var tx = size.x + this._thumbPos + this._thumbWid;
		}
		var dx = evt.clientX + this._deltaX - tx;
		if (Math.abs(dx) >= 1) {
			if (which==1) {
				// move start
				var startRange = this.startRange;
				var newTime = this.getTimeForPos(this._thumbPos + dx);
				if (newTime != startRange) {
					this.setProperty('startRange',newTime);
				}
			}
			else {
				if (dx<-this._thumbWid) {
					dx = -this._thumbWid;
				}
				// move end
				var endRange = this.endRange;
				var newTime = this.getTimeForPos(this._thumbPos+this._thumbWid+dx);
				if (newTime != endRange) {
					this.setProperty('endRange',newTime);
				}
			}
		}
		if ('mouseup' == evt.type) {
			this.onchangeHandler(true,'scale');
			if (which==1) {
				this.document.documentElement.removeEventListener('mousemove',this._dragGrabber1Func,false);
				this.document.documentElement.removeEventListener('mouseup',this._dragGrabber1Func,false);
			}
			else {
				this.document.documentElement.removeEventListener('mousemove',this._dragGrabber2Func,false);
				this.document.documentElement.removeEventListener('mouseup',this._dragGrabber2Func,false);
			}
			this._inDrag = false;
		}
		else {
			this.onchangeHandler(false,'scale');
		}
		break;
	}
}

/// Set the start and end time range dates and update.
/// If <var>endRange</var> is not provided, update it to preserve the current time range using
/// <var>startRange</var> as a new starting time.<br/>
/// Time values are in 'yyyy-mm-dd' format.
ClientMethod setTimeRange(startRange, endRange) [ Language = javascript ]
{
	if (!endRange) {
		// year only?
		startRange = startRange ? (parseInt(startRange)==startRange?startRange+'-01-01':startRange) : startRange;
		var endRange = this.endRange;
		endRange = endRange ? (parseInt(endRange)==endRange?endRange+'-12-31':endRange) : endRange;

		var startDate = zenStringToDate(startRange);
		var endDate = zenStringToDate(endRange);
		startDate = startDate ? startDate : new Date(2000,0,1,0,0,0,0);
		endDate = endDate ? endDate : new Date(startDate.getFullYear(),11,31,0,0,0,0);
		var delta = endDate-startDate;
		startDate.setTime(startDate.getTime()+delta);
		endRange = zenDateToString(startDate);
	}
	
	this.startRange = startRange;
	this.endRange = endRange;
	this.render();
}

}
