/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG TimeLine component.
/// This displays a series of "events" along a time line.
Class %ZEN.SVGComponent.timeLine Extends svgComponent [ Deprecated, System = 3 ]
{

/// Earliest displayed time (as YYYY-MM-DD HH:MM:SS).
Property startTime As %ZEN.Datatype.string;

/// Latest displayed time (as YYYY-MM-DD HH:MM:SS).
Property endTime As %ZEN.Datatype.string;

/// "Birth date" (as YYYY-MM-DD HH:MM:SS).
/// If provided, then a time bar showing current age is also displayed.
Property birthDate As %ZEN.Datatype.string;

/// Id of selected item.
Property selectedId As %ZEN.Datatype.string;

/// Chart title.
Property title As %ZEN.Datatype.string;

/// Optional. Specifies the display format used for this component.
/// (Note that the internal value of this control is always YYYY-MM-DD).
/// Possible values are:<br/>
/// <ul>
/// <li>"YMD" - Year,Month,Day</li>
/// <li>"MDY" - Month,Day,Year</li>
/// <li>"DMY" - Day,Month,Year</li>
/// </ul>
Property dateFormat As %ZEN.Datatype.string(MAXLEN = 3, VALUELIST = ",MDY,DMY,YMD") [ InitialExpression = "YMD" ];

/// Height (in pixels) of a time span box on the time line.
Property spanHeight As %ZEN.Datatype.integer [ InitialExpression = 20 ];

/// Left margin (in pixels).
Property marginLeft As %ZEN.Datatype.integer [ InitialExpression = 20 ];

/// Right margin (in pixels).
Property marginRight As %ZEN.Datatype.integer [ InitialExpression = 20 ];

/// ongetdata event handler:
/// This defines the client-side code that returns
/// an graph of javascript objects used to provide the contents of this view.
Property ongetdata As %ZEN.Datatype.eventHandler;

/// onselect event handler:
/// This event handler is called when the user selects a new item within the timeline.
Property onselect As %ZEN.Datatype.eventHandler;

/// onrenderitem event handler:
/// This event handler is called when an event is plotted and makes it possible to plot
/// custom content on the time line.
Property onrenderitem As %ZEN.Datatype.eventHandler;

XData SVGStyle
{
<style type="text/css">

/* background of the timeline */
rect.timeLine-backingRect {
	fill: white;
	stroke: none;
	stroke-width: 1px;
}

/* background of the vertical scroll bar */
rect.timeLine-scrollBox {
	fill: none;
	stroke: #808080;
	stroke-width: 0.25px;
}

rect.timeLine-scrollBar {
	fill: #D0D0D0;
	stroke: none;
	stroke-width: 1px;
}

rect.timeLine-scrollBarHover {
	fill: #808080;
	stroke: none;
	stroke-width: 1px;
}

/* background of the time cells */
rect.timeLine-cellBackground {
	fill: white;
	stroke: none;
}

/* background of the age bar cells */
rect.timeLine-ageBackground {
	fill: #F0F0F0;
	stroke: none;
}

/* background of the title area */
rect.timeLine-titleBackground {
	fill: rgb(231,192,80);
	fill-opacity: 0.5;
	stroke: none;
}

/* title */
text.timeLine-title {
	fill: #804040;
	stroke: none;
	font-family: arial;
	font-weight: bold;
	font-size: 18px;
	pointer-events: none;
}

/* info box */
text.timeLine-infoBoxText {
	fill: #404080;
	stroke: none;
	font-family: arial;
	font-size: 12px;
	pointer-events: none;
}

/* major tick line within the timeline */
line.timeLine-majorTick {
	fill: none;
	stroke: #606060;
	stroke-width: 1.5px;
	stroke-linecap: round;
}

line.timeLine-minorTick {
	fill: none;
	stroke: #808080;
	stroke-width: 1px;
	stroke-linecap: round;
}

text.timeLine-tickLabel {
	fill: #404040;
	stroke: none;
	font-family: arial;
	font-size: 12px;
	pointer-events: none;
}

/* text within tag */
.timeLine-tagLabel {
	fill: #404040;
	stroke: none;
	font-family: arial;
	font-size: 10px;
	font-weight: bold;
	pointer-events: none;
}

/* shape behind tag text */
.timeLine-tag {
	fill: rgb(190,226,250);
	stroke: #808080;
	stroke-width: 1px;
}

line.timeLine-connector {
	fill: none;
	stroke: #606060;
	opacity: 0.25;
	stroke-width: 1px;
	stroke-linecap: round;
}

.timeLine-ageBox-even {
	fill: rgb(231,192,80);
	stroke: #606060;
	opacity: 0.25;
	stroke-width: 1px;
	stroke-linecap: round;
}

.timeLine-ageBox-odd {
	fill: rgb(210,156,80);
	stroke: #606060;
	opacity: 0.25;
	stroke-width: 1px;
	stroke-linecap: round;
}

text.timeLine-ageLabel {
	fill: #606060;
	stroke: none;
	font-family: arial;
	font-size: 16px;
	pointer-events: none;
}

text.timeLine-ageUnits {
	fill: #606060;
	stroke: none;
	font-family: arial;
	font-size: 10px;
	pointer-events: none;
}

/* span box for event */
rect.timeLine-span {
	fill: rgb(231,192,80);
	stroke: #808080;
	stroke-width: 1px;
}

text.timeLine-itemCaption {
	fill: #404040;
	stroke: none;
	font-family: arial;
	font-size: 16px;
	pointer-events: none;
}

</style>
}

/// Set the timeline start and end dates and update.
/// Time values are in 'yyyy-mm-dd' format.
/// This prevents the repaint that would happen if start and end dates are set separately.
/// If <var>endTime</var> is not provided, update it to preserve the current time range using
/// <var>startTime</var> as a new starting time.<br/>
/// If <var>reset</var> is true, clear the internal structures used to compute the locations
/// of the time events.<br/>
/// If <var>which</var> is provided, it specifies whether the change is "translate" or "scale"
/// (to make it easy to connect to a timeRange controller).
ClientMethod setTimeRange(startTime, endTime, reset, which) [ Language = javascript ]
{
	which = zenGet(which,'');
	if (zenGet(reset,false)) {
		this._sortedModel = null;
		this._yScroll = 0;
		which = '';
	}
	
	if (!endTime) {
		// year only?
		startTime = startTime ? (parseInt(startTime)==startTime?startTime+'-01-01':startTime) : startTime;
		var endTime = this.endTime;
		endTime = endTime ? (parseInt(endTime)==endTime?endTime+'-12-31':endTime) : endTime;

		var startDate = zenStringToDate(startTime);
		var endDate = zenStringToDate(endTime);
		startDate = startDate ? startDate : new Date(2000,0,1,0,0,0,0);
		endDate = endDate ? endDate : new Date(startDate.getFullYear(),11,31,0,0,0,0);
		var delta = endDate-startDate;
		startDate.setTime(startDate.getTime()+delta);
		endTime = zenDateToString(startDate);
	}

	this.startTime = startTime;
	this.endTime = endTime;

	// can we slide?
	if (which == 'translate') {
		var slideGroup = this.findSVGElement('dataSlideGroup');
		if (slideGroup && this._offset) {
			// has span secs changed?
			var startDate = zenStringToDate(startTime);
			var endDate = zenStringToDate(endTime);
			if (!startDate) {
				startDate = zenStringToDate('2000-01-01');
			}
			if (!endDate) {
				endDate = zenStringToDate('2010-12-31');
			}
			var offset = (startDate)/1000;
			var xOffset = (this._offset - offset) * this._pixPerSec;
			var y = -this._yScroll;
			this._xOffset = xOffset;
			slideGroup.setAttribute('transform','translate('+xOffset+','+y+')');

			// render axes and time label
			this.renderTimeCells();
			var boxText = startDate.toLocaleDateString() + ' to ' + endDate.toLocaleDateString();
			this.setTextNode('infoBox',boxText);
			return;
		}
	}

	this.render();
}

/// Render the inner SVG contents of this component.
ClientMethod renderContents() [ Language = javascript ]
{
	if (zenIsMissing(this.document)) return;

	this._yScroll = zenGet(this._yScroll,0);
	this._xOffset = 0;

	this.unrender();
	var width = parseInt(this.width);
	var height = parseInt(this.height);

	// we'll set these when a move/drag operation starts
	this._dragThumbFunc = new Function('evt','return zenPage.getComponent('+this.index+').dragThumb(evt);');

	// used for computations
	this._date1900 = new Date(1900,0,1,0,0,0,0);

	var marginRight = parseInt(this.marginRight);
	marginRight = isNaN(marginRight) ? 0 : marginRight;
	var marginLeft = parseInt(this.marginLeft);
	marginLeft = isNaN(marginLeft) ? 0 : marginLeft;

	var marginTop = 0;
	var marginBottom = 4;
	var cellHeight = 25;
	var ageHeight = 25;
	var majorHeight = 24;
	var minorHeight = 10;

	var startTime = this.startTime;
	var endTime = this.endTime;
	var startDate = zenStringToDate(startTime);
	var endDate = zenStringToDate(endTime);
	if (!startDate) {
		startDate = zenStringToDate('2000-01-01');
	}
	if (!endDate) {
		endDate = zenStringToDate('2010-12-31');
	}

	// find scroll offset
	var offset = (startDate)/1000;
	this._offset = offset;

	// background rectangle
	var backingRect = this.document.createElementNS(SVGNS,'rect');
	backingRect.setAttribute('class','timeLine-backingRect');
	backingRect.setAttribute('x',0);
	backingRect.setAttribute('y',0);
	backingRect.setAttribute('width',width);
	backingRect.setAttribute('height',height);
	this.svgGroup.appendChild(backingRect);

	// reset selected item
	backingRect.addEventListener('click',new Function('evt','return zenPage.getComponent('+this.index+').itemClick(evt,\'\');'),false);

	// title rectangle
	var titleRect = this.document.createElementNS(SVGNS,'rect');
	titleRect.setAttribute('class','timeLine-titleBackground');
	titleRect.setAttribute('x',0);
	titleRect.setAttribute('y',0);
	titleRect.setAttribute('width',width);
	this.svgGroup.appendChild(titleRect);

	// info box
	var boxText = startDate.toLocaleDateString() + ' to ' + endDate.toLocaleDateString();
	var lblText = this.document.createElementNS(SVGNS,'text');
	lblText.setAttribute('id',this.makeId('infoBox'));
	lblText.setAttribute('class','timeLine-infoBoxText');
	lblText.setAttribute('x',width - 100);
	lblText.setAttribute('y',10);
	var textNode = this.document.createTextNode(boxText);
	lblText.appendChild(textNode);
	this.svgGroup.appendChild(lblText);

	var bbox = zenGetBBox(lblText);
	var tw = lblText.getComputedTextLength();
	var th = bbox.height;
	lblText.setAttribute('x',width - (tw+marginRight));
	lblText.setAttribute('y',th + 2);
	if (tw>width/2) {
		lblText.setAttribute('style','display:none;');
	}
	marginTop = th+4;

	// title
	var lblText = this.document.createElementNS(SVGNS,'text');
	lblText.setAttribute('class','timeLine-title');
	lblText.setAttribute('x',marginLeft);
	lblText.setAttribute('y',10);
	var textNode = this.document.createTextNode(this.title);
	lblText.appendChild(textNode);
	this.svgGroup.appendChild(lblText);

	var bbox = zenGetBBox(lblText);
	var tw = lblText.getComputedTextLength();
	var th = bbox.height;
	lblText.setAttribute('y',th);
	marginTop = marginTop > (th+6) ? marginTop : (th+6);

	titleRect.setAttribute('height',marginTop);

	// time cells: age and time cells on top/bottom
	this._marginTop = marginTop;
	this.renderTimeCells();

	// group to hold the data
	var dataGroup = this.document.createElementNS(SVGNS,'svg');
	dataGroup.setAttribute('x',marginLeft);
	dataGroup.setAttribute('width',width>(marginRight + marginLeft)?width - (marginRight + marginLeft):0);
	dataGroup.setAttribute('y',marginTop+ageHeight);
	dataGroup.setAttribute('height',height - (marginTop + marginBottom + cellHeight + ageHeight));
	this.svgGroup.appendChild(dataGroup);

	// group for sliding data
	var dataSlideGroup = this.document.createElementNS(SVGNS,'g');
	dataSlideGroup.setAttribute('id',this.makeId('dataSlideGroup'));
	dataGroup.appendChild(dataSlideGroup);

	// now plot the timeline data
	this.renderData(dataSlideGroup,marginTop);

	dataSlideGroup.setAttribute('transform','translate(0,'+(-this._yScroll)+')');

	// vertical scrollbar
	var dataHeight = height - (marginTop + marginBottom + cellHeight + ageHeight);
	if (this._maxHeight > dataHeight) {
		var sw = 12;
		var scrollBox = this.document.createElementNS(SVGNS,'rect');
		scrollBox.setAttribute('class','timeLine-scrollBox');
		scrollBox.setAttribute('x',width-sw);
		scrollBox.setAttribute('y',marginTop+ageHeight);
		scrollBox.setAttribute('width',sw);
		scrollBox.setAttribute('height',dataHeight);
		this.svgGroup.appendChild(scrollBox);

		var sh = (dataHeight/this._maxHeight) * dataHeight;

		var maxScroll = this._maxHeight-dataHeight;
		var maxSB = dataHeight-sh;
		var sy = (marginTop+ageHeight) + (this._yScroll/maxScroll)*maxSB;

		this._thumbPos = sy;
		this._thumbHgt = sh;
		this._thumbOffset = (marginTop+ageHeight);
		this._thumbMin = 0;
		this._thumbMax = maxSB;
		this._thumbScale = (maxScroll/maxSB);

		var thumb = this.document.createElementNS(SVGNS,'rect');
		thumb.setAttribute('id',this.makeId('thumb'));
		thumb.setAttribute('class','timeLine-scrollBar');
		thumb.setAttribute('rx',2);
		thumb.setAttribute('x',width-sw+1);
		thumb.setAttribute('y',sy);
		thumb.setAttribute('width',sw-2);
		thumb.setAttribute('height',sh);
		this.svgGroup.appendChild(thumb);

		thumb.addEventListener('mouseover',new Function('evt','evt.target.setAttribute("class","timeLine-scrollBarHover");'),false);
		thumb.addEventListener('mouseout',new Function('evt','evt.target.setAttribute("class","timeLine-scrollBar");'),false);
		thumb.addEventListener('mousedown',this._dragThumbFunc,false);
	}
}

/// Render the time cells on the top/bottom.
ClientMethod renderTimeCells() [ Language = javascript ]
{
	// unrender
	var timeCellGroup = this.findSVGElement('timeCellGroup');
	if (timeCellGroup) {
		while(timeCellGroup.firstChild) {
			timeCellGroup.removeChild(timeCellGroup.firstChild);
		}
	}
	var ageCellGroup = this.findSVGElement('ageCellGroup');
	if (timeCellGroup) {
		while(ageCellGroup.firstChild) {
			ageCellGroup.removeChild(ageCellGroup.firstChild);
		}
	}
	
	var startDate = this._startDate;
	var startDate = this._startDate;

	var width = parseInt(this.width);
	var height = parseInt(this.height);

	var marginRight = parseInt(this.marginRight);
	marginRight = isNaN(marginRight) ? 0 : marginRight;
	var marginLeft = parseInt(this.marginLeft);
	marginLeft = isNaN(marginLeft) ? 0 : marginLeft;

	var marginTop = this._marginTop;
	var marginBottom = 4;
	var cellHeight = 25;
	var ageHeight = 25;
	var majorHeight = 24;
	var minorHeight = 10;

	// find time scale to display
	var startTime = this.startTime;
	var endTime = this.endTime;
	var startDate = zenStringToDate(startTime);
	var endDate = zenStringToDate(endTime);
	if (!startDate) {
		startDate = zenStringToDate('2000-01-01');
	}
	if (!endDate) {
		endDate = zenStringToDate('2010-12-31');
	}
	// get span of timeline in seconds
	var spanSecs = (endDate - startDate)/1000;

	// pick major units based on delta
	var majorUnits = 'years';
	var minorUnits = 'quarters';
	var startUnits = 0;
	var endUnits = 0;

	if (spanSecs > (31536000*20)) {
		majorUnits = 'decades';
		minorUnits = 'years';
		startUnits = Math.floor((startDate.getFullYear() - 1900) / 10);
		endUnits = Math.floor((endDate.getFullYear() - 1900) / 10);
	}
	else if (spanSecs > (31536000*4)) {
		majorUnits = 'years';
		minorUnits = 'quarters';
		startUnits = startDate.getFullYear() - 1900;
		endUnits = endDate.getFullYear() - 1900;
	}
	else if (spanSecs > (31536000*2)) {
		majorUnits = 'years';
		minorUnits = 'months';
		startUnits = startDate.getFullYear() - 1900;
		endUnits = endDate.getFullYear() - 1900;
	}
	else if (spanSecs > (31536000)) {
		majorUnits = 'quarters';
		minorUnits = 'months';
		startUnits = ((startDate.getFullYear()-1900)*4) + Math.floor(startDate.getMonth()/4);
		endUnits = ((endDate.getFullYear()-1900)*4) + Math.floor(endDate.getMonth()/4);
	}
	else if (spanSecs > (24 * 3600 * 10)) {
		majorUnits = 'months';
		minorUnits = 'days';
		startUnits = ((startDate.getFullYear()-1900)*12) + Math.floor(startDate.getMonth());
		endUnits = ((endDate.getFullYear()-1900)*12) + Math.floor(endDate.getMonth());
	}
	else {
		spanSecs = spanSecs > (24*60*60) ? spanSecs :(24*60*60);
		majorUnits = 'days';
		minorUnits = 'hours';

		// days since 1900
		startUnits = (startDate - this._date1900)/(24*60*60*1000);
		endUnits = (endDate - this._date1900)/(24*60*60*1000);
	}

	// group to hold the time cells
	var timeCellGroup = this.document.createElementNS(SVGNS,'g');
	timeCellGroup.setAttribute('id',this.makeId('timeCellGroup'));

	// background rectangle for time cells (tick marks)
	var cellRect = this.document.createElementNS(SVGNS,'rect');
	cellRect.setAttribute('class','timeLine-cellBackground');
	cellRect.setAttribute('x',0);
	cellRect.setAttribute('y',0);
	cellRect.setAttribute('width',width);
	cellRect.setAttribute('height',cellHeight);
	timeCellGroup.appendChild(cellRect);

	// time to compute ages from
	var hasAgeBar = false;
	var birthDate = this.birthDate ? zenStringToDate(this.birthDate) : null;
	if (birthDate) {
		hasAgeBar = true;		
		var startAge = this.computeAge(birthDate,startDate);
		var endAge = this.computeAge(birthDate,endDate);

		var ageUnits = 'years';
		var ageStartUnits = startAge.years;
		var ageEndUnits = endAge.years;
	}

	if (hasAgeBar) {
		// group to hold the age cells
		var ageCellGroup = this.document.createElementNS(SVGNS,'g');
		ageCellGroup.setAttribute('id',this.makeId('ageCellGroup'));
		this.svgGroup.appendChild(ageCellGroup);

		// background rectangle for age cells
		var cellRect = this.document.createElementNS(SVGNS,'rect');
		cellRect.setAttribute('class','timeLine-ageBackground');
		cellRect.setAttribute('x',0);
		cellRect.setAttribute('y',0);
		cellRect.setAttribute('width',width);
		cellRect.setAttribute('height',ageHeight);
		ageCellGroup.appendChild(cellRect);
	}

	// tick marks
	var plotWidth = width - (marginLeft+marginRight);

	// find pixels/sec
	this._pixPerSec = spanSecs>0 ? (plotWidth/spanSecs) : 0;

	// find scroll offset
	var offset = (startDate)/1000;

	if (plotWidth>0) {
		// time bar
		for (var cell = startUnits; cell <= endUnits; cell++) {
			var info = this.getCellInfo(cell,majorUnits,minorUnits,cell-startUnits);
			var x = (this._pixPerSec * (info.startSecs-offset)) + marginLeft;

			// Major tick
			var tick = this.document.createElementNS(SVGNS,'line');
			tick.setAttribute('class','timeLine-majorTick');
			tick.setAttribute('x1',x);
			tick.setAttribute('x2',x);
			tick.setAttribute('y1',cellHeight-majorHeight);
			tick.setAttribute('y2',cellHeight);
			timeCellGroup.appendChild(tick);

			// label
			var lblText = this.document.createElementNS(SVGNS,'text');
			lblText.setAttribute('class','timeLine-tickLabel');
			lblText.setAttribute('x',x+4);
			lblText.setAttribute('y',cellHeight-3);
			var textNode = this.document.createTextNode(info.caption);
			lblText.appendChild(textNode);
			timeCellGroup.appendChild(lblText);

			var lastxm = 0;
			for (var j = 0; j < info.minorTicks.length; j++) {
				var xm = (this._pixPerSec * (info.minorTicks[j]-offset)) + marginLeft;
				if (lastxm==0 || (xm-lastxm) > 3) {
					var tick = this.document.createElementNS(SVGNS,'line');
					tick.setAttribute('class','timeLine-minorTick');
					tick.setAttribute('x1',xm);
					tick.setAttribute('x2',xm);
					tick.setAttribute('y1',cellHeight-majorHeight);
					tick.setAttribute('y2',cellHeight-majorHeight+minorHeight);
					timeCellGroup.appendChild(tick);
					lastxm = xm;
				}
			}
		}

		if (hasAgeBar) {
			// age bar
			// test for years or months
			if ((ageEndUnits-ageStartUnits)<3 && ageEndUnits>=0 && ageEndUnits < 3) {
				ageUnits = 'months';
				ageStartUnits = ageStartUnits*12;
				ageEndUnits = (ageEndUnits+1)*12;
			}
			ageStartUnits = ageStartUnits < 0 ? 0 : ageStartUnits;

			var lastxd = 0;

			for (var cell = ageStartUnits; cell <= ageEndUnits; cell++) {
				// convert age to local date
				if (ageUnits == 'months') {
					var unitCaption = ' mo';
					var yr1 = Math.floor(cell/12);
					var yr2 = Math.floor((cell+1)/12);
					var m1 = Math.floor(cell%12);
					var m2 = Math.floor((cell+1)%12);
					var ld = new Date(birthDate.getFullYear()+yr1,m1,birthDate.getDate(),0,0,0,0);
					var ld2 = new Date(birthDate.getFullYear()+yr2,m2,birthDate.getDate(),0,0,0,0);
					var ageSecs = (ld.getTime()/1000);
					var ageSecs2 = (ld2.getTime()/1000);
					var x1 = (this._pixPerSec * (ageSecs-offset)) + marginLeft;
					var x2 = (this._pixPerSec * (ageSecs2-offset)) + marginLeft;
				}
				else {
					var unitCaption = ' yrs';
					var ld = new Date(birthDate.getFullYear()+cell,birthDate.getMonth(),birthDate.getDate(),0,0,0,0);
					var ld2 = new Date(birthDate.getFullYear()+cell+1,birthDate.getMonth(),birthDate.getDate(),0,0,0,0);
					var ageSecs = (ld.getTime()/1000);
					var ageSecs2 = (ld2.getTime()/1000);
					var x1 = (this._pixPerSec * (ageSecs-offset)) + marginLeft;
					var x2 = (this._pixPerSec * (ageSecs2-offset)) + marginLeft;
				}

				// age box
				var abox = this.document.createElementNS(SVGNS,'rect');
				abox.setAttribute('class',(cell%2==0)?'timeLine-ageBox-even':'timeLine-ageBox-odd');
				abox.setAttribute('x',x1);
				abox.setAttribute('y',0);
				abox.setAttribute('width',x2-x1>0?x2-x1:0);
				abox.setAttribute('height',ageHeight);
				ageCellGroup.appendChild(abox);

				if (lastxd==0 || ((x1-lastxd) > 10)) {
					// label
					var lblText = this.document.createElementNS(SVGNS,'text');
					lblText.setAttribute('class','timeLine-ageLabel');
					lblText.setAttribute('x',x1+4);
					lblText.setAttribute('y',ageHeight-6);
					var textNode = this.document.createTextNode(cell);
					lblText.appendChild(textNode);
					ageCellGroup.appendChild(lblText);

					var atw = lblText.getComputedTextLength();

					// units
					if (lastxd==0 || (x2-x1)>(atw+10)) {
						var lblText = this.document.createElementNS(SVGNS,'text');
						lblText.setAttribute('class','timeLine-ageUnits');
						lblText.setAttribute('x',x1+4+atw+2);
						lblText.setAttribute('y',ageHeight-6);
						var textNode = this.document.createTextNode(unitCaption);
						lblText.appendChild(textNode);
						ageCellGroup.appendChild(lblText);
					}
					lastxd = x1+4+atw+2;
				}
			}
		}
	}

	// move time cells to bottom
	var tcy = height - cellHeight;
	timeCellGroup.setAttribute('transform','translate(0,'+tcy+')');
	this.svgGroup.appendChild(timeCellGroup);

	if (hasAgeBar) {
		var tcy = height - (cellHeight+ageHeight);
		ageCellGroup.setAttribute('transform','translate(0,'+marginTop+')');
	}
	else {
		ageHeight = 0;
	}
}

/// Render the actual time line data.
ClientMethod renderData(dataGroup, marginTop) [ Language = javascript ]
{
	var width = parseInt(this.width);
	var height = parseInt(this.height);
	
	// height for scroll bar
	this._maxHeight = 0;

	// array of span items by item id
	this._spanItems = {};

	// get model and sort by time
	var model = this.getModel();
	var range = {};
	if (this._sortedModel) {
		var sortedModel = this._sortedModel;
	}
	else {
		var sortedModel = this.sortModel(model,range);
		this._sortedModel = sortedModel;
	}
	range.startTime = range.startTime ? range.startTime : new Date();
	range.endTime = range.endTime ? range.endTime : range.startTime;

	// find range of times for the time line
	var startTime = this.startTime ? zenStringToDate(this.startTime) : range.startTime;
	var endTime = this.endTime ? zenStringToDate(this.endTime) : range.endTime;
	var currTime = this.currTime ? zenStringToDate(this.currTime) : startTime;

	// now plot items within the "user" area
	var firstGroup = null;
	var offset = this._offset;

	if (sortedModel) {
		// render items (without real placement, that happens later)
		for (var n = 0; n < sortedModel.length; n++) {
			var item = sortedModel[n];

			// find time range for this item
			var startSecs = item.startTime ? item.startTime.getTime()/1000 : null;
			var endSecs = item.endTime ? item.endTime.getTime()/1000 : null;

			if (startSecs!==null) {
				// container for item
				item.group = this.document.createElementNS(SVGNS,'g');
				dataGroup.appendChild(item.group);
				if (!firstGroup) {
					firstGroup = item.group;
				}
				
				if (item.id) {
					this._spanItems[item.id] = item;
					item.group.addEventListener('click',new Function('evt','return zenPage.getComponent('+this.index+').itemClick(evt,\''+item.id+'\');'),false);
				}

				var x1 = (this._pixPerSec * (startSecs-offset));
				var x2 = endSecs ? ((this._pixPerSec * (endSecs-offset))) : x1;
				var len = x2>x1 ? x2 - x1 : 0;

				var size = {width: 0, height: 0};
				this.renderOneItem(item.group,item,len,size);
				item.x = x1;
				item.width = size.width;
				item.height = size.height;
			}
		}

		// place items into bands
		// each band is an array of non-overlapping boxes
		var bands = [];
		for (var n = 0; n < sortedModel.length; n++) {
			var item = sortedModel[n];
			if (item.group) {
				// find band for item
				var placed = false;
				for (var b = 0; b < bands.length; b++) {
					var overlap = false;
					for (var slotNo = 0; slotNo < bands[b].length; slotNo++) {
						var slot = bands[b][slotNo];
						if (item.x < (slot.x+slot.width) && (item.x+item.width) > slot.x) {
							overlap = true;
							break;
						}
					}
					if (!overlap) {
						// add slot to band
						placed = true;
						bands[b][bands[b].length] = {x:item.x,width:item.width,height:item.height};
						item.band = b;
						break;
					}
				}
				if (!placed) {
					// new band
					item.band = bands.length;
					bands[bands.length] = [{x:item.x,width:item.width,height:item.height}];
				}
			}
		}

		// set up height for each band
		var y = marginTop;
		var bandY = [];
		for (var b = 0; b < bands.length; b++) {
			bandY[b] = y;
			var hgt = 10;
			for (var slotNo = 0; slotNo < bands[b].length; slotNo++) {
				if (bands[b][slotNo].height > hgt) {
					hgt = bands[b][slotNo].height;
				}
			}
			y += hgt+10;
		}

		this._maxHeight = y;

		// move items into final place
		for (var n = 0; n < sortedModel.length; n++) {
			var item = sortedModel[n];
			var y = bandY[item.band];
			if (item.group) {
				item.group.setAttribute('transform','translate('+item.x+','+y+')');
			}

			// connector from grid (place under boxes)
			if (firstGroup) {
				var tick = this.document.createElementNS(SVGNS,'line');
				tick.setAttribute('class','timeLine-connector');
				tick.setAttribute('x1',item.x);
				tick.setAttribute('x2',item.x);
				tick.setAttribute('y1',y);
				tick.setAttribute('y2',height);
				dataGroup.insertBefore(tick,firstGroup);
			}
		}
	}
}

/// Render one item on the timeline.
/// <var>group</var> is the svg group to append to.
/// <var>length</var> is the length (in pixels) of the time range to plot..
/// Return the size of the rendered item via <var>size</var>.
ClientMethod renderOneItem(group, item, length, size) [ Language = javascript ]
{
	// time span
	var spanHeight = parseInt(this.spanHeight);

	// if item defines height, use it:
	if (item.spanHeight) {
		spanHeight = parseInt(item.spanHeight);
	}

	var userRendered = false;
	if (this.onrenderitem) {
		size.width = length;
		size.height = spanHeight;
		item.document = this.document;
		userRendered = zenInvokeCallbackMethod(this.onrenderitem,this,'onrenderitem','group',group,'item',item,'size',size);
		item.document = null;
	}
	if (!userRendered) {
		if (length > 0) {
			// backing shape
			var span = this.document.createElementNS(SVGNS,'rect');
			span.setAttribute('class','timeLine-span');
			span.setAttribute('x',0);
			span.setAttribute('y',0);
			span.setAttribute('rx',0);
			span.setAttribute('width',length);
			span.setAttribute('height',spanHeight);
			if (item.style) {
				span.setAttribute('style',item.style);
			}
			else {
				span.setAttribute('style','fill:none;');
			}
			group.appendChild(span);

			// overlay shape
			var span = this.document.createElementNS(SVGNS,'rect');
			span.setAttribute('class','timeLine-span');
			span.setAttribute('x',0);
			span.setAttribute('y',0);
			span.setAttribute('rx',0);
			span.setAttribute('width',length);
			span.setAttribute('height',spanHeight);
			span.setAttribute('opacity',item.style ? 0.25 : 1.0);
			group.appendChild(span);
		}
		else {
			spanHeight = 0;
		}

		size.width = length;
		size.height = spanHeight;

		// tag (marker)
		var fh = spanHeight * 0.6;
		fh = (fh > 12) ? 12 : fh;
		if (item.tag!=='' && fh>4) {
			var tag = this.document.createElementNS(SVGNS,'rect');
			tag.setAttribute('class','timeLine-tag');
			tag.setAttribute('x',0);
			tag.setAttribute('y',0);
			tag.setAttribute('rx',2);
			tag.setAttribute('width',0);
			tag.setAttribute('height',0);
			group.appendChild(tag);

			var text = this.document.createElementNS(SVGNS,"text");
			group.appendChild(text);
			text.setAttribute("x",0);
			text.setAttribute("y",0);
			text.setAttribute("text-anchor","middle");
			text.setAttribute("class","timeLine-tagLabel");

			text.setAttribute("style",'font-size:'+fh+'px;' + item.tagStyle);

			var textNode = this.document.createTextNode(item.tag);
			text.appendChild(textNode);

			var bbox = zenGetBBox(text);
			var tw = text.getComputedTextLength();
			var th = bbox.height*1.1;
			var ty = -th/2;
			tw = tw < 10 ? 10 : tw;

			text.setAttribute('x',(tw/2)+2);
			text.setAttribute('y',ty+th-(th/4));
			tag.setAttribute('x',-1);
			tag.setAttribute('y',-th/2);
			var bw = ((tw)*1.2)+4;
			tag.setAttribute('width',bw);
			tag.setAttribute('height',(th));
			if (bw > size.width) {
				size.width = bw;
			}
		}
	}

	// caption
	if (item.caption) {
		var text = this.document.createElementNS(SVGNS,"text");
		group.appendChild(text);
		text.setAttribute("x",2);
		text.setAttribute("y",0);
		text.setAttribute("class","timeLine-itemCaption");

		if (item.captionStyle) {
			text.setAttribute("style",item.captionStyle);
		}

		var textNode = this.document.createTextNode(item.caption);
		text.appendChild(textNode);

		var bbox = zenGetBBox(text);
		var tw = text.getComputedTextLength();
		var th = bbox.height * 1.2;

		text.setAttribute("y",spanHeight+th);

		size.width = size.width>tw ? size.width : tw;
		size.height = spanHeight + th;
	}
}

/// Return information about a cell within the grid line.
ClientMethod getCellInfo(cell, majorUnits, minorUnits, index) [ Language = javascript ]
{
	var caption = '';		// caption for cell
	var startSecs = 0;		// number of secs at start of cell

	// minor ticks is an array of starting seconds
	var minorTicks = [];

	switch(majorUnits) {
	case 'decades':
		var year = (parseInt(cell)*10) + 1900;
		caption = year;
		var d = new Date(year,0,1,0,0,0,0);
		startSecs = d.getTime()/1000;

		switch(minorUnits) {
		default:
		case 'years':
			for (var n = 1; n <= 9; n++) {
				var dt = new Date(year+n,0,1,0,0,0,0);
				minorTicks[minorTicks.length] = dt.getTime()/1000;
			}
			break;
		}
		break;

	case 'years':
		var year = parseInt(cell) + 1900;
		caption = year;
		var d = new Date(year,0,1,0,0,0,0);
		startSecs = d.getTime()/1000;

		switch(minorUnits) {
		default:
		case 'quarters':
			for (var n = 1; n <= 3; n++) {
				var dt = new Date(year,n*3,1,0,0,0,0);
				minorTicks[minorTicks.length] = dt.getTime()/1000;
			}
			break;
		case 'months':
			for (var n = 1; n <= 11; n++) {
				var dt = new Date(year,n,1,0,0,0,0);
				minorTicks[minorTicks.length] = dt.getTime()/1000;
			}
			break;
		}
		break;
	case 'quarters':
		var year = parseInt(Math.floor(cell/4)) + 1900;
		caption = 'Q' + (cell%4+1);
		if ((cell%4==0)||index==0) {
			caption += ('-' + year);
		}
		var d = new Date(year,(cell%4)*3,1,0,0,0,0);
		startSecs = d.getTime()/1000;

		// months
		for (var n = 1; n <= 2; n++) {
			var dt = new Date(year,((cell%4)*3)+n,1,0,0,0,0);
			minorTicks[minorTicks.length] = dt.getTime()/1000;
		}
		break;
	case 'months':
		var year = parseInt(Math.floor(cell/12)) + 1900;
		caption = _zenResource['zenMonthShortNames'].split(',')[(cell%12)];
		if ((cell%12==0||cell%12==6)||(index==0)) {
		 	caption += ('-' + (year));
		}
		var d = new Date(year,(cell%12),1,0,0,0,0);
		startSecs = d.getTime()/1000;
		var daysInMonth = [31,28,31,30,31,30,31,31,30,31,30,31];
		if ((year%4==0) && !(year%100==0 && year%400!=0)) {
			daysInMonth[1] = 29;
		} 

		// days
		for (var n = 1; n < daysInMonth[cell%12]; n++) {
			var dt = new Date(year,(cell%12),n,0,0,0,0);
			minorTicks[minorTicks.length] = dt.getTime()/1000;
		}
		break;
	case 'days':
		var d = new Date(1900,0,1,0,0,0,0);
		d.setDate(this._date1900.getDate() + Math.floor(cell));
		startSecs = d.getTime()/1000;
		caption = zenDateToString(d,false,this.dateFormat);

		// hours
		for (var n = 1; n < 24; n+=1) {
			var dt = new Date(1900,0,1,0,0,0,0);
			dt.setTime(d.getTime() + (n*3600*1000));
			minorTicks[minorTicks.length] = dt.getTime()/1000;
		}
		break;
	}
	return { caption:caption, startSecs:startSecs, minorTicks:minorTicks  };
}

/// Get the model used to drive the user portion of the time line.
ClientMethod getModel() [ Language = javascript ]
{
	// See if there is user-supplied data to drive the control
	var model = null;
	if (this.ongetdata!='') {
		model = zenInvokeCallbackMethod(this.ongetdata,this,'ongetdata');
	}
	return model;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'width':
	case 'height':
		return this.invokeSuper('setProperty',arguments);

	case 'title':
	case 'birthDate':
	case 'startTime':
	case 'endTime':
	case 'dateFormat':
		this[property] = value;
		this.render();
		break;

	case 'spanHeight':
		this[property] = parseInt(value);
		this.render();
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Take the user-supplied data model and sort it by time.
/// Return a sorted and decorated model.
/// Also find earliest and latest times and return via <var>range</var> object.
ClientMethod sortModel(model, range) [ Language = javascript ]
{
	var sortedModel = [];
	range.startTime = null;
	range.endTime = null;

	// copy model into new model
	if (model && model.children) {
		for (var n = 0; n < model.children.length; n++) {
			var newItem = {};
			var item = model.children[n];
			if (item.startTime) {
				newItem.startTime = zenStringToDate(item.startTime);
			}
			else {
				// error: missing start time
				newItem.startTime = new Date();
			}
			if (item.endTime) {
				newItem.endTime = zenStringToDate(item.endTime);
			}
			else {
				newItem.startTime = newItem.startTime;
			}

			newItem.id = item.id ? item.id : null;
			newItem.caption = item.caption ? item.caption : '';
			newItem.style = item.style ? item.style : '';
			newItem.captionStyle = item.captionStyle ? item.captionStyle : '';
			newItem.spanHeight = item.height ? item.height : '';
			newItem.tag = item.tag ? item.tag : '';

			var skip = {startTime:true,endTime:true,id:true,caption:true,
				style:true,captionStyle:true,height:true,tag:true};

			// copy additional properties into newItem
			for (var p in item) {
				if (!skip[p]) {
					newItem[p] = item[p] ? item[p] : '';
				}
			}
			
			sortedModel[sortedModel.length] = newItem;

			// range
			range.startTime = !range.startTime || newItem.startTime<range.startTime ? newItem.startTime : range.startTime;
			range.endTime = !range.endTime || newItem.endTime>range.endTime ? newItem.endTime : range.endTime;
		}
	}

	// sort model
	sortedModel.sort(function(a,b) { return a.startTime - b.startTime; });

	return sortedModel;
}

/// Click on item.
ClientMethod itemClick(evt, newId) [ Language = javascript ]
{
	evt.preventDefault();
	this.selectItem(newId);
	zenInvokeCallbackMethod(this.onselect,this,'onselect','id',newId);
}

/// Select an item.
ClientMethod selectItem(newId) [ Language = javascript ]
{
	if (this._spanItems && this.selectedId!=newId) {

		this.selectedId=newId;

		// select
		for (var id in this._spanItems) {
			var item = this._spanItems[id];
			if (item.group) {
				var opacity = (newId===null||newId==='') ? 1.0 : (newId==id?1.0:0.5);
				item.group.setAttribute('opacity',opacity);
			}
		}
	}
}

/// Compute the age between currDate and birthDate, return it as an object.
ClientMethod computeAge(birthDate, currDate) [ Language = javascript ]
{
	var currYear = currDate.getFullYear() ;
	var currMonth = currDate.getMonth();
	var currDay = currDate.getDate();

	var bYear = birthDate.getFullYear() ;
	var bMonth = birthDate.getMonth();
	var bDay = birthDate.getDate();
	
	var ageYears = currYear - bYear;
	var ageMonths = 0;
	var ageDays = 0;
	var year = currYear;
	var daysInMonth = [31,28,31,30,31,30,31,31,30,31,30,31];
	if ((year%4==0) && !(year%100==0 && year%400!=0)) {
		daysInMonth[1] = 29;
	} 
	var dim = daysInMonth[currMonth>0?currMonth-1:11];

	if (currMonth == bMonth) {
		if (currDay == bDay) {
		}
		else if (currDay < bDay) {
			ageYears--;
			ageDays = (dim+currDay) - bDay;
		}
		else {
			ageDays = currDay - bDay;
		}
	}
	else if (currMonth < bMonth) {
		ageYears--;
		ageMonths = (currMonth+12) - bMonth;
		if (currDay == bDay) {
		}
		else if (currDay < bDay) {
			ageMonths--;
			ageDays = (dim+currDay) - bDay;
		}
		else {
			ageDays = currDay - bDay;
		}
	}
	else {
		ageMonths = currMonth - bMonth;
		if (currDay == bDay) {
		}
		else if (currDay < bDay) {
			ageMonths--;
			ageDays = (dim+currDay) - bDay;
		}
		else {
			ageDays = currDay - bDay;
		}
	}
	return {years:ageYears, months:ageMonths, days: ageDays};
}

/// Drag handler for vertical scrollbar thumb.
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
		var ty = size.y + this._thumbPos;

		// figure out offset of mouse from thumb...
		this._deltaY = ty - evt.clientY;
	
		// remember start of operation
		this._startY = ty;

		this._inDrag = true;
		break;
	case 'mousemove':
	case 'mouseup':
		// move thumb
		var size = this.getSizeAbsolute();
		var ty = size.y + this._thumbPos;
		var dy = evt.clientY + this._deltaY - ty;
		if (Math.abs(dy) >= 1) {
			// move scroll bar
			var thumb = this.findSVGElement('thumb');
			var y = this._thumbPos+dy-this._thumbOffset;
			y = y>this._thumbMax ? this._thumbMax : y;
			y = y<this._thumbMin ? this._thumbMin : y;
			thumb.setAttribute('y',y + this._thumbOffset);
			this._yScroll = y * this._thumbScale;
			var slideGroup = this.findSVGElement('dataSlideGroup');
			if (slideGroup) {
				var xOffset = zenGet(this._xOffset,0);
				slideGroup.setAttribute('transform','translate('+xOffset+','+(-this._yScroll)+')');
			}
		}
		if ('mouseup' == evt.type) {
			this.document.documentElement.removeEventListener('mousemove',this._dragThumbFunc,false);
			this.document.documentElement.removeEventListener('mouseup',this._dragThumbFunc,false);
			this._inDrag = false;
			this.render();
		}
		break;
	}
}

}
