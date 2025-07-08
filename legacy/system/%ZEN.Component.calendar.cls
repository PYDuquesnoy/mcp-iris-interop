/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A calendar control.<br>
/// This is a custom control built out of HTML primitives.<br>
/// The value associated with this control is in %Timestamp format:
/// YYYY-MM-DD
Class %ZEN.Component.calendar Extends control [ Deprecated, System = 3 ]
{

/// Do not include in "form" module.
Parameter SYSMODULE;

/// Localization domain
Parameter DOMAIN = "%ZEN";

/// Starting year displayed by year selector in calendar.
/// If not defined, default is 10 years previous to now
/// or the year portion of <property>minDate</property> if defined.
Property startYear As %ZEN.Datatype.integer(MINVAL = 1600);

/// Ending year displayed by year selector in calendar.
/// If not defined, default is 30 years after now
/// or the year portion of <property>maxDate</property> if defined.
Property endYear As %ZEN.Datatype.integer(MAXVAL = 9999);

/// Optional.
/// If specified, this is the earliest date allowed by the calendar.
/// This is a date in the form "YYYY-MM-DD".<br>
/// Note that setting this does not effect what years are displayed
/// by the calendar; that is controlled by the <property>startYear</property> 
/// and </property>endYear</property> properties.
Property minDate As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// Optional.
/// If specified, this is the latest date allowed by the calendar.
/// This is a date in the form "YYYY-MM-DD".<br>
/// Note that setting this does not effect what years are displayed
/// by the calendar; that is controlled by the <property>startYear</property> 
/// and </property>endYear</property> properties.
Property maxDate As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// List of localized day abbreviations shown at top of calendar.
Property dayList As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

/// List of localized month names shown at top of calendar.
Property monthList As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

/// Specified which day of the week (Sunday=0, Saturday = 6) is displayed as
/// the starting day of the week.<br>
/// This allows for customizing the calendar for locales where weeks start with
/// other days of the week.
Property firstDayOfWeek As %ZEN.Datatype.integer(MAXVAL = 6, MINVAL = 0) [ InitialExpression = 0 ];

/// Year displayed by control.
Property year As %ZEN.Datatype.integer;

/// Month (1 to 12) displayed by control.
Property month As %ZEN.Datatype.integer(MAXVAL = 12, MINVAL = 1);

/// Size of the gap between the month and year indicators.<br>
/// Setting this provides a way to adjust the overall size of the
/// calendar.
Property gapWidth As %ZEN.Datatype.length [ InitialExpression = "40px" ];

/// If true, then this calendar will display a single month
/// and provide no way for the user to change month and year.
Property fixedMonth As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, then this calendar will also display and allow the user
/// to edit the time of day portion of a date. In this case, the value
/// used by this control will be in xDBC timestamp format:
/// YYYY-MM-DD HH:MM:SS
Property showTime As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If specified and <property>showTime</property> is true, and the value
/// supplied does not include a time portion, this will be
/// used as the initial time displayed in the popup calendar.
Property defaultTime As %ZEN.Datatype.string;

/// Localized caption for time input box (see <property>showTime</property>).
Property timeCaption As %ZEN.Datatype.caption;

/// If true, then allow the user to select multiple days by pressing the CTRL key
/// when clicking on a date. The most recent selection is used as the value of the
/// control. The list of multiple values is placed into the <property>listOfValues</property>
/// array.
Property multiSelect As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, then allow the user to select ranges of days by pressing the SHIFT key
/// when clicking on a date. The most recent selection is used as the value of the
/// control. The start and end values are placed into the <property>listOfValues</property>
/// array and <property>isRange</property> will be set true.
Property rangeSelect As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Indicates that the current list of values contains a date range.
Property isRange As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// List of current selected values (when in multi-select mode).
/// If a range is selected, then this list will contain the starting and ending values for the range.
Property listOfValues As list Of %ZEN.Datatype.string(XMLPROJECTION = "none");

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Outer table for calendar." */
table.calendarOutline {
	border: 1px black solid;
	text-align: center;
	background: white;
	font-family: arial;
}

/* @doc="Inner table for calendar." */
table.calendar {
	border: 1px black solid;
	text-align: center;
}

/* @doc="Gap (td) between the year and month elements." */
.calendarGap {
	background: #F0F0F0;
}

/* @doc="Style for month and year when calendar is in fixedMonth mode." */
span.calendarLabel {
	padding-left: 2px;
	padding-right: 2px;
	font-weight: bold;
	color: #404040;
}
 
/* @doc="Table headers for calendar." */
table.calendar th {
	border-bottom: 1px gray solid;
	padding-left: 2px;
	padding-right: 2px;
	font-weight: bold;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

/* @doc="Disabled table headers for calendar." */
table.calendar th.calendarDisabled {
	color: #808080;
	background: #E0E0E0;
}

/* @doc="Empty cells within calendar." */
table.calendar td.calendarEmpty {
	border-bottom: 1px gray solid;
	border-right: 1px gray solid;
	padding-left: 2px;
	padding-right: 2px;
	padding-bottom: 1px;
	background: #F0F0F0;
}

/* each day of week can have its own style */
table.calendar td.calendarDay0,
table.calendar td.calendarDay1,
table.calendar td.calendarDay2,
table.calendar td.calendarDay3,
table.calendar td.calendarDay4,
table.calendar td.calendarDay5,
table.calendar td.calendarDay6
{
	border-bottom: 1px gray solid;
	border-right: 1px gray solid;
	padding-left: 2px;
	padding-right: 2px;
	padding-bottom: 1px;
	color: #404040;
	cursor: pointer;
}

/* @doc="Selected cell in calendar." */
table.calendar td.calendarSelected {
	border-bottom: 1px gray solid;
	border-right: 1px gray solid;
	padding-left: 2px;
	padding-right: 2px;
	padding-bottom: 0px;
	font-weight: bold;
	cursor: pointer;
	background: rgb(47,98,128);
	color: white;
}

table.calendar td.calendarSelected:hover {
	background: rgb(47,98,128);
	color: orange;
}

table.calendar td.calendarDay0:hover,
table.calendar td.calendarDay1:hover,
table.calendar td.calendarDay2:hover,
table.calendar td.calendarDay3:hover,
table.calendar td.calendarDay4:hover,
table.calendar td.calendarDay5:hover,
table.calendar td.calendarDay6:hover
{
	background: #FFEEAA;
	border-bottom: 1px gray solid;
	border-right: 1px gray solid;
	padding-left: 2px;
	padding-right: 2px;
	color: #404040;
	cursor: pointer;
}

/* @doc="Current day in calendar." */
table.calendar td.calendarToday {
	border-bottom: 1px gray solid;
	border-right: 1px gray solid;
	padding-left: 2px;
	padding-right: 2px;
	padding-bottom: 0px;
	font-weight: bold;
	color: black;
	cursor: pointer;
}

table.calendar td.calendarToday:hover {
	background: #FFEEAA;
}

/* @doc="Next or previous link in calendar." */
table.calendar td.calendarLink {
	border-bottom: 1px gray solid;
	border-right: 1px gray solid;
	padding-left: 2px;
	padding-right: 2px;
	padding-bottom: 1px;
	background: #F0F0F0;
	color: #404040;
	cursor: pointer;
}

table.calendar td.calendarLink:hover {
	background: #FFEEAA;
}

/* @doc="Disabled cells in calendar." */
table.calendar td.calendarDisabled {
	border-bottom: 1px gray solid;
	border-right: 1px gray solid;
	padding-left: 2px;
	padding-right: 2px;
	padding-bottom: 1px;
	color: #808080;
	background: #E0E0E0;
}

select.calendarSelect {
	color: #404040;
}

.calendarTimeDiv {
	font-size: 0.8em;
	padding: 1px;
}

</style>
}

Method %DrawHTML()
{
	#; if there are expressions for these props, evaluate
	Set ..minDate = $$$ZENVAL(..minDate)
	Set ..maxDate = $$$ZENVAL(..maxDate)
	
	#; if year and date are not set, set them here
	Set:..month="" ..month=+$E($ZDT($H,3),6,7)
	Set:..year="" ..year=$E($ZDT($H,3),1,4)

	#; if localized properties have not been set, set them
	Set:..dayList="" ..dayList = $$$Text("S,M,T,W,T,F,S")
	Set:..monthList="" ..monthList = $$$Text("January,February,March,April,May,June,July,August,September,October,November,December")
	Set:..timeCaption="" ..timeCaption = $$$Text("Time:")

	Do ##super()
}

/// Client-side method to render control.
ClientMethod renderContents() [ Language = javascript ]
{
	this.renderCalendarAll();
}

/// Called when user changes month or year.
/// Does not change current value of calandar.
ClientMethod changeMonth() [ Language = javascript ]
{
	var selYear = this.findElement('calendarYear');
	var selMonth = this.findElement('calendarMonth');
	if (!selYear || !selMonth) return;

	var year = selYear.value;
	var month = selMonth.value;

	this.year = ('' == year) ? this.year : year;
	this.month = ('' == month) ? this.month : month; 
	this.renderCalendar();
}

/// Move back one month; do not change current value;
ClientMethod prevMonth() [ Language = javascript ]
{
	if (this.readOnly || this.disabled) return;
	if (this.month == 1 && this.year == this.findStartYear()) return;

	this.month--;
	if (this.month <= 0) {
		this.month = 12;
		this.year--;
	}
	var selYear = this.findElement('calendarYear');
	var selMonth = this.findElement('calendarMonth');
	selYear.value = this.year;
	selMonth.value = this.month;
	this.renderCalendar();
}

/// Move forward one month; do not change current value;
ClientMethod nextMonth() [ Language = javascript ]
{
	if (this.readOnly || this.disabled) return;
	if (this.month == 12 && this.year == this.endYear) return;
	this.month++;
	if (this.month > 12) {
		this.month = 1;
		this.year++;
	}
	var selYear = this.findElement('calendarYear');
	var selMonth = this.findElement('calendarMonth');
	selYear.value = this.year;
	selMonth.value = this.month;
	this.renderCalendar();
}

/// Called when user clicks on a day.
ClientMethod selectDay(day, evt) [ Language = javascript ]
{
	if (this.readOnly || this.disabled) return;

	if (null == day) {
		// use current day
		this.listOfValues.length = 0;
		day = parseInt(this.value.substr(8,2),10);
		if (isNaN(day)) {
			var now = new Date();
			day = now.getDate();
		}
	}

	// update value
	this.value = this.year + '-' + ((this.month < 10) ? '0' : '') + this.month + '-' + ((day < 10) ? '0' : '') + day;
	evt = evt ? evt : window.event;

	if (this.rangeSelect && (this.multiSelect && evt && !evt.ctrlKey)) {
		if (evt && evt.shiftKey && this.listOfValues.length >= 1) {
			// add to range
			this.isRange = true;
			this.listOfValues.length = 2;
			this.listOfValues[1] = this.value;

			// sort
			if (this.listOfValues[0]>this.listOfValues[1]) {
				var swap = this.listOfValues[0];
				this.listOfValues[0] = this.listOfValues[1];
				this.listOfValues[1] = swap;
			}
		}
		else {
			this.isRange = false;
			this.listOfValues.length = 0;
			this.listOfValues[0] = this.value;
		}
	}
	else if (this.multiSelect) {
		if (evt && evt.ctrlKey && !this.isRange) {
			// first see if value is already in the list
			var exists = false;
			for (var n = 0; n < this.listOfValues.length; n++) {
				if (this.listOfValues[n] == this.value) {
					exists = true;
					break;
				}
			}
			if (!exists) {
				this.listOfValues[this.listOfValues.length] = this.value;
			}
		}
		else {
			this.listOfValues.length = 1;
			this.listOfValues[0] = this.value;
		}
		this.isRange = false;
	}
	else {
		this.isRange = false;
		this.listOfValues.length = 1;
		this.listOfValues[0] = this.value;
	}		

	if (this.showTime) {
		var t = this.findElement('time').value;
		t = zenNormalizeTime(t);
		if ('' == t && '' != this.defaultTime) {
			t = this.defaultTime; // if null, initialize time with defaultTime
		}
		if ('' != t) {
			this.value += ' ' + t;
		}
		this.findElement('time').value = t;
	}

	this.findElement('control').value = this.value;
	this.renderCalendar();

	// notify
	this.onchangeHandler();
}

/// Fill in contents of entire calendar (month and year drop downs).
ClientMethod renderCalendarAll() [ Language = javascript ]
{
	// test if we have not been rendered yet
	if (this.getEnclosingDiv() == null) return;

	// get localized strings
	if ('' == this.monthList) {
		this.monthList = zenText('zenMonthNames');
	}
	if ('' == this.dayList) {
		this.dayList = zenText('zenDayShortNames');
	}
	
	if (zenIsMissing(this.startYear)) this.startYear = this.findStartYear();
	if (zenIsMissing(this.year)) {
		var now = new Date();
		this.year = now.getFullYear();
	}
	if (zenIsMissing(this.month)) {
		var now = new Date();
		this.month = now.getMonth()+1;
	}

	// find year & month of control value
	var year = this.year;
	var month = this.month;
	var tTime = '';
	if ('' != this.value) {
		year = parseInt(this.value.substr(0,4),10);
		month = parseInt(this.value.substr(5,2),10);
	}
	if (this.showTime) {
		var tTime = this.value.substr(11);
		tTime = zenNormalizeTime(tTime);
		if ('' == tTime && '' != this.defaultTime) {
			tTime = this.defaultTime;
		}
	}

	// build HTML to show current month
	var html = new Array();

	// use hidden control to make sure there is a value to submit
	html[html.length] = '<input type="hidden" id="'+this.makeId('control')+'" name="'+ this.sysName() +'" value="'+this.value+'"\/>';

	html[html.length] = '<table class="calendarOutline" title="'+this.title+'" border="1" cellspacing="0" cellpadding="0">';
	html[html.length] = '<tr><td align="left">';

	var months = this.monthList.split(',');
	if (this.fixedMonth) {
		// show fixed month name
		var mname = (months[month-1]==null ? '' : months[month-1]);
		html[html.length] = '<span class="calendarLabel">' + mname + '</span>';
	}
	else {
		// show choice of months
		html[html.length] = '<select class="calendarSelect" id="'+this.makeId('calendarMonth')+'" onchange="zenPage.getComponent('+this.index+').changeMonth();">';
		for (var m = 0; m < 12; m++) {
			var mname = (months[m]==null ? '' : months[m]);
			html[html.length] = '<option value="'+(m+1)+'" '+ ((m+1)==month ? 'selected="1"' : '') +'>'+mname+'<\/option>';
		}
		html[html.length] = '</select>';
	}
	html[html.length] = '</td><td class="calendarGap" width="'+this.gapWidth+'">&#160;</td><td align="right">';
	if (this.fixedMonth) {
		// show fixed year
		html[html.length] = '<span class="calendarLabel">' + year + '</span>';
	}
	else {
		// show choice of years
		html[html.length] = '<select class="calendarSelect" id="'+this.makeId('calendarYear')+'" onchange="zenPage.getComponent('+this.index+').changeMonth();">';
	
		for (y = this.findStartYear(); y <= this.findEndYear(); y++) {
			html[html.length] = '<option value="'+y+'" '+(y==year ? 'selected="1"' : '') + '>'+y+'<\/option>';
		}
		html[html.length] = '</select>';
	}
	html[html.length] = '</td></tr><tr><td align="center" colspan="3">';

	// div to hold actual calendar table; this is created using DHTML
	// on client
	html[html.length] = '<div id="'+this.makeId('calendarDiv')+'"></div>';
	html[html.length] = '</td></tr></table>';

	// show time
	if (this.showTime) {
		html[html.length] = '<div class="calendarTimeDiv" id="'+this.makeId('timeDiv')+'">'+this.timeCaption+'<input id="'+this.makeId('time')+'" type="text" size="6" '+(this.disabled?'disabled ':'')+(this.readOnly?'readonly ':'')+'onkeypress="zenPage.getComponent('+this.index+').timeKeyHandler(event);" onchange="zenPage.getComponent('+this.index+').timeChangeHandler(event);" value="'+tTime+'"/></div>';
	}

	this.getEnclosingDiv().innerHTML = html.join('');

	// fill in bottom part
	this.renderCalendar();
}

/// Fill in contents of calendar
ClientMethod renderCalendar() [ Language = javascript ]
{
	// fill in div tag
	var div = this.findElement('calendarDiv');
	if (!div) return;

	zenASSERT(div,"Unable to find calendarDiv.",arguments);

	// build HTML to show current month
	var html = new Array();
	html[html.length] = '<table class="calendar" width="100%" border="0" cellpadding="0" cellspacing="0">';

	// headers
	var days = this.dayList.split(',');
	html[html.length] = '<tr>';
	for (var d = 0; d < 7; d++) {
		var dnum = (d + parseInt(this.firstDayOfWeek,10)) % 7;
		var dname = (days[dnum]==null || days[dnum]=='') ? '&#160;' : days[dnum];
		html[html.length] = '<th '+(this.disabled?'class="calendarDisabled"':'')+'>' + dname + '</th>';
	}
	html[html.length] = '</tr>';

	// get info on current value of control
	var tYear = parseInt(this.value.substr(0,4),10);
	var tMonth = parseInt(this.value.substr(5,2),10);
	var tDay = parseInt(this.value.substr(8,2),10);

	if ('' != this.minDate) {
		var minD = zenParseDate(this.minDate);
		if (-1 != minD) {
			var minYear = parseInt(minD.substr(0,4),10);
			var minMonth = parseInt(minD.substr(5,2),10);
			var minDay = parseInt(minD.substr(8,2),10);
		}
	}
	if ('' != this.maxDate) {
		var maxD = zenParseDate(this.maxDate);
		if (-1 != maxD) {
			var maxYear = parseInt(maxD.substr(0,4),10);
			var maxMonth = parseInt(maxD.substr(5,2),10);
			var maxDay = parseInt(maxD.substr(8,2),10);
		}
	}

 	// get info on displayed month:
	var currMonth = new Date(this.year,this.month - 1);
	var firstDay = currMonth.getDay();

	var daysInMonth = [31,28,31,30,31,30,31,31,30,31,30,31];

	// get value of now
	var now = new Date();

	// is this a leap year?
	if (this.year%4 == 0) {
		if (this.year%100 == 0 && this.year%400 != 0) {
			// skip these
		}
		else {
			daysInMonth[1] = 29;
		}
	} 

	// place next/prev month links in last 2 cells
	var adj = firstDay - parseInt(this.firstDayOfWeek,10);
	adj = (adj < 0) ? adj + 7 : adj;
	var prevCell = 41 - adj;
	var nextCell = 42 - adj;

	if (this.fixedMonth) {
		// disable next/prev month
		prevCell = -100;
		nextCell = -100;
	}

	// days: 6 rows
	var val = '';
	var dayno = parseInt(this.firstDayOfWeek,10) - firstDay;
	dayno = dayno > 0 ? dayno - 7: dayno;
	for (var r = 0; r < 6; r++) {
		html[html.length] = '<tr>';
		for (var d = 0; d < 7; d++) {
			var dnum = (d + parseInt(this.firstDayOfWeek,10)) % 7;
			dayno++;
			var cell = (dayno>0 && dayno <= daysInMonth[this.month-1]) ? dayno : '';
			
			if ('' == cell) {
				if (dayno == prevCell) {
					html[html.length] = '<td class="' + (this.disabled?"calendarDisabled":"calendarLink") + '" onclick="zenPage.getComponent(' + this.index + ').prevMonth();">&#171;</td>';
				}
				else if (dayno == nextCell) {
					html[html.length] = '<td class="' + (this.disabled?"calendarDisabled":"calendarLink") + '" onclick="zenPage.getComponent(' + this.index + ').nextMonth();">&#187;</td>';
				}
				else {
					html[html.length] = '<td class="'+(this.disabled?"calendarDisabled":"calendarEmpty")+'">&#160;</td>';
				}
			}
			else {
				var onclk = ' onmousedown="zenPage.getComponent(' + this.index + ').selectDay('+dayno+',event);"';
				var style;
				if (this.disabled) {
					style = 'class="calendarDisabled"';
				}
				else if (maxYear && ((this.year > maxYear) || (this.year == maxYear && this.month > maxMonth) || (this.year == maxYear && this.month == maxMonth && dayno > maxDay))) {
					style = 'class="calendarDisabled"';
					onclk = '';
				}
				else if (minYear && ((this.year < minYear) || (this.year == minYear && this.month < minMonth) || (this.year == minYear && this.month == minMonth && dayno < minDay))) {
					style = 'class="calendarDisabled"';
					onclk = '';
				}
				else if (this.year == tYear && this.month == tMonth && dayno == tDay) {
					style = 'class="calendarSelected"';
				}
				else if (this.year == now.getFullYear() && this.month == (now.getMonth()+1) && dayno == now.getDate()) {
					style = 'class="calendarToday"';
				}
				else {
					style = 'class="calendarDay'+dnum+'"';
				}

				// check for multi-select
				if (this.multiSelect && !this.isRange && this.listOfValues.length > 1) {
					for (var n = 0; n < this.listOfValues.length; n++) {
						var tListYear = parseInt(this.listOfValues[n].substr(0,4),10);
						var tListMonth = parseInt(this.listOfValues[n].substr(5,2),10);
						var tListDay = parseInt(this.listOfValues[n].substr(8,2),10);
						if (this.year == tListYear && this.month == tListMonth && dayno == tListDay) {
							style = 'class="calendarSelected"';
						}
					}
				}
				// check for range
				if (this.rangeSelect && this.isRange && this.listOfValues.length == 2) {
					var test = this.year+'-'+(this.month<10?'0':'')+this.month+'-'+(dayno<10?'0':'')+dayno;
					if (test >= this.listOfValues[0] && test <= this.listOfValues[1]) {
						style = 'class="calendarSelected"';
					}
				}

				html[html.length] = '<td ' + style + onclk + '>' + cell + '</td>';
			}
		}
		html[html.length] = '</tr>';
	}

	html[html.length] = '</table>';

	div.innerHTML = html.join("");
}

/// Take a date value in xDBC format (YYYY-MM-DD) and, if valid
/// set the value of this control to the date.
ClientMethod parseDate(value) [ Language = javascript ]
{
	var tYear = parseInt(value.substr(0,4),10);
	var tMonth = parseInt(value.substr(5,2),10);
	var tDay = parseInt(value.substr(8,2),10);
	var tTime = '';
	
	if (this.showTime) {
		var tTime = value.substr(11);
		tTime = zenNormalizeTime(tTime);
	}

	// simple validation, then let Date object do it
	if (tYear >= this.findStartYear() && tYear <= this.findEndYear() &&
		tMonth >= 1 && tMonth <= 12 &&
		tDay >= 1 && tDay <= 31) {
			
		var d = new Date(tYear,tMonth-1,tDay);

		// get normalized values back
		this.year = d.getFullYear();
		this.month = d.getMonth() + 1;

		// update comboboxes
		var selYear = this.findElement('calendarYear');
		var selMonth = this.findElement('calendarMonth');

		if (selYear && selMonth) {
			selYear.value = this.year;
			selMonth.value = this.month;
		}

		if (this.showTime) {
			var ctrl = this.findElement('time');
			if (ctrl) {
				ctrl.value = tTime;
			}
		}

		// recompute value
		value = this.year+'-'+(this.month<10?'0':'')+this.month+'-'+(d.getDate()<10?'0':'')+d.getDate()+(''==tTime?'':' ')+tTime;
	}
	else {
		// invalid or out-of-range date
		value = '';
	}
	
	return value;
}

/// Compute the starting year displayed by this calendar.
ClientMethod findStartYear() [ Language = javascript ]
{
	var ret = null;
	
	if ('' == this.startYear) {
		// compute
		if ('' != this.minDate) {
			var minD = zenParseDate(this.minDate);
			if (-1 != minD) {
				ret = parseInt(minD.substr(0,4),10);
			}
		}
		if (null == ret) {
			var now = new Date();
			ret = now.getFullYear() - 10;
		}
	}
	else {
		ret = this.startYear;
	}
	
	return ret;
}

/// Compute the ending year displayed by this calendar.
ClientMethod findEndYear() [ Language = javascript ]
{
	var ret = null;

	if ('' == this.endYear) {
		// compute
		if ('' != this.maxDate) {
			var maxD = zenParseDate(this.maxDate);
			if (-1 != maxD) {
				ret = parseInt(maxD.substr(0,4),10);
			}
		}
		if (null == ret) {
			var now = new Date();
			ret = now.getFullYear() + 30;
		}
	}
	else {
		ret = this.endYear;
	}
	
	return ret;
}

/// Handler for keypress event in time control.
ClientMethod timeKeyHandler(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;

	// trap ENTER key
	switch(evt.keyCode) {
	case zenENTER:
		this.selectDay(null,evt);
		return false;
	default:
		break;
	}
	return true;
}

/// Handler for change event in time control.
ClientMethod timeChangeHandler(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	this.selectDay(null,evt);
	return true;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var el = this.findElement('control');

	switch(property) {
	case 'value':
		// value should be a date string or ''
		// try and parse into components
		this.listOfValues.length = 0;
		this.isRange = false;
		if (value != '') {
			value = this.parseDate(value);
			this.listOfValues[this.listOfValues.length] = value;
		}
		if (el) el.value = value;
		this.value = value;
		this.renderCalendar();
		break;
	case 'month':
		value = parseInt(value,10);
		value = (value < 1) ? 1 : value;
		value = (value > 12) ? 12 : value;
		this.month = value;
		this.renderCalendarAll();
		break;
	case 'year':
		value = parseInt(value,10);
		value = (value < this.findStartYear()) ? this.findStartYear() : value;
		value = (value > this.findEndYear()) ? this.findEndYear() : value;
		this.year = value;
		this.renderCalendarAll();
		break;
	case 'readOnly':
		value = value ? true : false;
		this.readOnly = value;
		if (el) el.readOnly = value;
		break;
	case 'startYear':
		if ('' != value) {
			value = parseInt(value,10);
			if (isNaN(value)) {
				value = '';
			}
			else {
				value = value < 1600 ? 1600 : value;
			}
		}
		this.startYear = value;
		this.renderCalendarAll();
		break;
	case 'endYear':
		if ('' != value) {
			value = parseInt(value,10);
			if (isNaN(value)) {
				value = '';
			}
			else {
				value = parseInt(value,10);
				value = value > 9999 ? 9999 : value;
			}
		}
		this.endYear = value;
		this.renderCalendarAll();
		break;
	case 'minDate':
	case 'maxDate':
		if (value != '') {
			var v = zenParseDate(value);
			value = (-1 == v) ? '' : v;
		}
		this[property] = value;
		this.renderCalendarAll();
		break;
	case 'monthList':
		this.monthList = value;
		this.renderCalendarAll();
		break;
	case 'dayList':
		this.dayList = value;
		this.renderCalendar();
		break;
	case 'timeCaption':
		this.timeCaption = value;
		this.renderCalendar();
		break;
	case 'firstDayOfWeek':
		value = parseInt(value,10);
		value = (value < 0) ? 0 : value;
		value = (value > 6) ? 6 : value;
		this.firstDayOfWeek = value;
		this.renderCalendar();
		break;
	case 'gapWidth':
		this.gapWidth = value;
		this.renderCalendarAll();
		break;
	case 'fixedMonth':
		this.fixedMonth = value ? true : false;
		this.renderCalendarAll();
		break;
	case 'showTime':
		this.showTime = value ? true : false;
		this.renderCalendarAll();
		break;
	case 'defaultTime':
		this.defaultTime = zenNormalizeTime(value);
		this.renderCalendarAll();
	case 'multiSelect':
		this.multiSelect = value ? true : false;
		break;
	case 'rangeSelect':
		this.rangeSelect = value ? true : false;
		break;
	case 'disabled':
		value = value ? true : false;
		this.disabled = value;
		var year = this.findElement('calendarYear');
		var month = this.findElement('calendarMonth');
		year.disabled = value;
		month.disabled = value;
		// update el so that default control methods work...
		el.disabled = value; 
		if (this.showTime) {
			this.renderCalendarAll();
		}
		else {
			this.renderCalendar();
		}

		// dispatch to disable labels
		return this.invokeSuper('setProperty',arguments);
	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
