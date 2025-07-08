/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A specialized input control for handling date values.<br>
/// This control allows the user to view and edit a date value
/// via a set of comboboxes, one for year, month, and day of month.
/// This is useful for cases like birth dates or expiration dates
/// where a popup calendar (as in the <class>dateText</class> component)
/// is cumbersome.<br/>
/// The logical value of this control takes the standard form
/// YYYY-MM-DD. You can change the order of the year, month, and day
/// dropdows using the <property>format</property> property.<br/>
/// Note that the standard HTML events (onfocus, onclick, etc.) are fired
/// for <em>each</em> of the select controls that make up this component.<br/>
/// Setting <property>readOnly</property> to true has the same effect
/// as disabling this component; this is the standard HTML behavior
/// for select controls.
Class %ZEN.Component.dateSelect Extends control [ Deprecated, System = 3 ]
{

Parameter DEFAULTCONTROLCLASS = "dateSelect";

/// Localization domain
Parameter DOMAIN = "%ZEN";

/// This is a string that specifies the order in which the date
/// components are to be displayed.<br/>
/// Possible values are:<br/>
/// <ul>
/// <li>"MDY" - Month,Day,Year</li>
/// <li>"DMY" - Day,Month,Year</li>
/// <li>"YMD" - Year,Month,Day</li>
/// <li>"YDM" - Year,Day,Month</li>
/// <li>"DM" - Day,Month</li>
/// <li>"MD" - Month,Day</li>
/// <li>"YM" - Year,Month</li>
/// <li>"MY" - Month,Year</li>
/// <li>"Y" - Year</li>
/// <li>"M" - Month</li>
/// </ul>
Property format As %ZEN.Datatype.string(MAXLEN = 3, VALUELIST = ",MDY,DMY,YMD,DM,MD,YM,MY,Y,M", ZENEXPRESSION = 1) [ InitialExpression = "MDY" ];

/// Optional.
/// If specified, this is the earliest year allowed by the calendar.
/// If not specified, 1900 is used.
Property minYear As %ZEN.Datatype.integer(ZENEXPRESSION = 1);

/// Optional.
/// If specified, this is the latest year allowed by the calendar.
/// If not specified, the current year plus 20 is used.
Property maxYear As %ZEN.Datatype.integer(ZENEXPRESSION = 1);

/// List of localized month names shown in the month combo box.
Property monthList As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

/// If true (default is false) show the first 3 characters of month
/// names in the month dropdown.
/// Note, you can also control this by setting the value of the
/// <property>monthList</property> property.
Property shortMonth As %ZEN.Datatype.boolean(ZENLOCALIZE = 1) [ InitialExpression = 0 ];

/// If true (default id false) show the ordinal month number along
/// with month names in the month dropdown.
Property showMonthNumber As %ZEN.Datatype.boolean(ZENLOCALIZE = 1) [ InitialExpression = 0 ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* @doc="Table used to layout elements within dateSelect." */
.dateSelectTable {
}

/* @doc="Combobox within dateSelect." */
.dateSelect {
}

</style>
}

Method %DrawHTML()
{
	#; do not add this to set of events
	Set tIgnore("onchange")=""

	// Get value
	Set tValue = $$$ZENVAL(..value)
	Set tYear = +$E(tValue,1,4)
	Set:tYear<1840 tYear = ""
	Set tMonth = +$E(tValue,6,7)
	Set tDay = +$E(tValue,9,10)

	#; use hidden control to make sure there is a value to submit
	&html<<input type="hidden" id="#(..%MakeId("control"))#" #(..%Name())# value="#($ZCVT(tValue,"O","HTML"))#"/>>

	Set tValue = ..value
	#; <select> does not support readOnly
	#; so we use disabled for both
	Set disabled = $S(..disabled||..readOnly:"disabled",1:"")
	
	#; if localized properties have not been set, set them
	Set:..monthList="" ..monthList = $$$Text("January,February,March,April,May,June,July,August,September,October,November,December")

	Set msgYear = $$$TextHTML("Year","%ZEN")
	Set msgMonth = $$$TextHTML("Month","%ZEN")
	Set msgDay = $$$TextHTML("Day","%ZEN")

	#; if there are expressions for these props, evaluate
	Set ..minYear = $$$ZENVAL(..minYear)
	Set ..maxYear = $$$ZENVAL(..maxYear)
	Set tShortMonth = +$$$ZENVAL(..shortMonth)
	Set tMonthNo = +$$$ZENVAL(..showMonthNumber)
	Set tFormat = $$$ZENVAL(..format)

	Set tStartYear = $S(..minYear="":1900,1:..minYear)
	Set tEndYear = $S(..maxYear="":+$ZDT($H,3)+20,1:..maxYear)

	&html<<table class="dateSelectTable" #(..%Attr("title",..title))# border="0" cellspacing="0" cellpadding="0"><tr>>

	If (tFormat = "MDY") { Do Month,Day,Year }
	ElseIf (tFormat = "DMY") { Do Day,Month,Year }
	ElseIf (tFormat = "YMD") { Do Year,Month,Day }
	ElseIf (tFormat = "YDM") { Do Year,Day,Month }
	ElseIf (tFormat = "DM") { Do Day,Month }
	ElseIf (tFormat = "MD") { Do Month,Day }
	ElseIf (tFormat = "YM") { Do Year,Month }
	ElseIf (tFormat = "MY") { Do Month,Year }
	ElseIf (tFormat = "Y") { Do Year }
	ElseIf (tFormat = "M") { Do Month }
	Else { &html<<td>#($$$TextHTML("Invalid Format","%ZEN"))#</td>> }
	Goto Done
Year
	&html<<td><select id="#(..%MakeId("year"))#" class="#(..controlClass)#" title="#(msgYear)#" onchange="zenPage.getComponent(#(..index)#).ondatechangeHandler('year');" #(..%Attr("tabindex",..tabIndex))# #(..%Attr("style",..controlStyle))# #(disabled)# #(..%GetEventHandlers(.tIgnore))#>>
	&html<<option value=""></option>>
	For y = tStartYear:1:tEndYear {
		&html<<option value="#(y)#" #($S(y=tYear:"selected=""1""",1:""))#>#(y)#</option>>
	}
	&html<</select></td>>
	Quit

Month
	&html<<td><select id="#(..%MakeId("month"))#" class="#(..controlClass)#" title="#(msgMonth)#" onchange="zenPage.getComponent(#(..index)#).ondatechangeHandler('month');" #(..%Attr("tabindex",..tabIndex))# #(..%Attr("style",..controlStyle))# #(disabled)# #(..%GetEventHandlers(.tIgnore))#>>
	&html<<option value=""></option>>
	For m = 1:1:12 {
		Set mName = $P(..monthList,",",m)
		Set:tShortMonth mName = $E(mName,1,3)
		Set:tMonthNo mName = mName_" ("_m_") "
		&html<<option value="#(m)#" #($S(m=tMonth:"selected=""1""",1:""))#>#(mName)#</option>>
	}
	&html<</select></td>>
	Quit

Day
	&html<<td><select id="#(..%MakeId("day"))#" class="#(..controlClass)#" title="#(msgDay)#" onchange="zenPage.getComponent(#(..index)#).ondatechangeHandler('day');" #(..%Attr("tabindex",..tabIndex))# #(..%Attr("style",..controlStyle))# #(disabled)# #(..%GetEventHandlers(.tIgnore))#>>
	&html<<option value=""></option>>
	For d = 1:1:31 {
		&html<<option value="#(d)#" #($S(d=tDay:"selected=""1""",1:""))#>#(d)#</option>>
	}
	&html<</select></td>>
	Quit

Done
	&html<</tr></table>>
}

/// onchange handler for this component.
ClientMethod ondatechangeHandler(which) [ Internal, Language = javascript ]
{
	var year = this.findElement('year');
	var month = this.findElement('month');
	var day = this.findElement('day');

	// if any value gets set to '', clear them all
	switch(which) {
	case 'year':
		if (year.value=='') {
			if (month) { month.value = ''; }
			if (day) { day.value = ''; }
		}
		break;
	case 'month':
		if (month.value=='') {
			if (year) { year.value = ''; }
			if (day) { day.value = ''; }
		}
		break;
	case 'day':
		if (day.value=='') {
			if (month) { month.value = ''; }
			if (year) { year.value = ''; }
		}
		break;
	}

	var yearVal = year ? parseInt(year.value) : '';
	var monthVal = month ? parseInt(month.value) : '';
	var dayVal = day ? parseInt(day.value) : '';
	yearVal = isNaN(yearVal) ? '' : yearVal;
	monthVal = isNaN(monthVal) ? '' : monthVal;
	dayVal = isNaN(dayVal) ? '' : dayVal;

	// default for non-showing items
	if ((yearVal=='')&&(this.format=='MD' || this.format=='DM' || this.format=='M')) {
		var now = new Date();
		yearVal = now.getFullYear();
	}

	if ((dayVal=='')&&(this.format=='YM' || this.format=='MY' || this.format=='M' || this.format=='Y')) {
		dayVal = 1;
	}

	if ((monthVal=='')&&(this.format=='Y')) {
		monthVal = 1;
	}

	// see if this is a complete date
	var complete = this.isCompleteDate();

	if (!complete) {
		this.value = 'missing';
	}
	else if ((yearVal=='')&&(monthVal=='')&&(dayVal=='')) {
		this.value = '';
	}
	else {
		var d = new Date(yearVal,monthVal-1,dayVal);
		d.setYear(yearVal);
		d.setMonth(monthVal-1);
		d.setDate(dayVal);
		
		if (d.getMonth() != (monthVal - 1)) {
			// js has adjusted the date!
			d.setDate((monthVal==2) ? 28 : 30);
			if (day) {
				day.value = (monthVal==2) ? 28 : 30;
			}
			d.setMonth(monthVal - 1);
		}
		this.value = zenDateToString(d);
	}

	if (day && 'day' != which) {
		this.updateDayList();
	}

	var el = this.findElement('control');
	if (el) {
		el.value = this.value;
	}

	// notify
	this.onchangeHandler();
}

/// Return displayed year value.
ClientMethod getYear() [ Language = javascript ]
{
	var year = this.findElement('year');
	return (year ? year.value : '');
}

/// Return displayed month value.
ClientMethod getMonth() [ Language = javascript ]
{
	var month = this.findElement('month');
	return (month ? month.value : '');
}

/// Return displayed day value.
ClientMethod getDay() [ Language = javascript ]
{
	var day = this.findElement('day');
	return (day ? day.value : '');
}

/// Internal method to update the elements in the year drop down.
ClientMethod updateYearList() [ Internal, Language = javascript ]
{
	var year = this.findElement('year');
	if (year) {
		var now = new Date();

		var tYear = parseInt(this.value.substr(0,4),10);
		year.options.length = 0;
		var minY = parseInt(this.minYear,10);
		var maxY = parseInt(this.maxYear,10);
		minY = isNaN(minY) ? 1900 : minY;
		maxY = isNaN(maxY) ? (now.getFullYear() + 20) : maxY;
		minY = (minY < 1840) ? 1840 : minY;
		maxY = (maxY > 3000) ? 3000 : maxY;

		year.options[year.options.length] = new Option('','');
		for (var y = minY; y <= maxY; y++) {
			year.options[year.options.length] = new Option(y,y,false,y==tYear);
		}
	}
}

/// Internal method to update the elements in the day drop down.
ClientMethod updateDayList() [ Internal, Language = javascript ]
{
	var year = this.getYear();
	if (year=='') {
		var now = new Date();
		year = now.getFullYear();
	}
	var month = this.getMonth();
	if (month=='') {
		month = 1;
	}

	var day = this.findElement('day');
	if (day) {
		var tDay = day.value;
		day.options.length = 0;

		var daysInMonth = [31,28,31,30,31,30,31,31,30,31,30,31];

		// is this a leap year?
		if (year%4 == 0) {
			if (year%100 == 0 && year%400 != 0) {
				// skip these
			}
			else {
				daysInMonth[1] = 29;
			}
		}

		day.options[day.options.length] = new Option('','');
		for (var d = 1; d <= daysInMonth[month-1]; d++) {
			day.options[day.options.length] = new Option(d,d,false,d==tDay);
		}
	}
}

/// Test if this is an complete date;
/// either all values are provided or no values are
/// provided.
ClientMethod isCompleteDate() [ Language = javascript ]
{
	var year = this.findElement('year');
	var month = this.findElement('month');
	var day = this.findElement('day');

	var control = 0;
	var blank = 0;
	if (year) {
		control++;
		if (year.value=="") { blank++; }
	}
	if (month) {
		control++;
		if (month.value=="") { blank++; }
	}
	if (day) {
		control++;
		if (day.value=="") { blank++; }
	}

	if ((blank>0)&&(blank!=control)) {
		return false;
	}
	return true;
}

ClientMethod isValid() [ Language = javascript ]
{
	var d = zenParseDate(this.getValue());
	if (-1 == d) return false;
	return true;
}

/// Client-side method to give input focus to this control.
ClientMethod focus() [ Language = javascript ]
{
	var el = null;

	// give focus to first select
	switch (this.format.charAt(0)) {
	case 'Y':
		el = this.findElement('year');
		break;
	case 'M':
		el = this.findElement('month');
		break;
	case 'D':
		el = this.findElement('day');
		break;
	}
	if (el) {
		try {
			el.focus();
		}
		catch(ex) {
		}
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var el = this.findElement('control'); // hidden
	var year = this.findElement('year');
	var month = this.findElement('month');
	var day = this.findElement('day');

	switch(property) {
	case 'value':
		// value should be a date string or ''
		var yearVal = '';
		var monthVal = '';
		var dayVal = '';
		if (value != '') {
			var now = new Date();
			value = value.toString();
			yearVal = parseInt(value.substr(0,4),10);
			yearVal = (isNaN(yearVal) ? now.getFullYear() : yearVal);
			monthVal = parseInt(value.substr(5,2),10);
			monthVal = (isNaN(monthVal) ? 1 : monthVal);
			dayVal = parseInt(value.substr(8,2),10);
			dayVal = (isNaN(dayVal) ? 1 : dayVal);
		}
		if (el) { el.value = value; }
		if (year) { year.value = yearVal; }
		if (month) { month.value = monthVal; }
		if (day) {
			day.value = dayVal;
			this.updateDayList();
		}
		break;

	case 'minYear':
	case 'maxYear':
		this[property] = value;
		this.updateYearList();
		break;

	case 'controlClass':
		this.controlClass = value;
		if (year) { year.className = (this.invalid ? 'zenInvalid' : this.controlClass);}
		if (month) { month.className = (this.invalid ? 'zenInvalid' : this.controlClass);}
		if (day) { day.className = (this.invalid ? 'zenInvalid' : this.controlClass);}
		break;
	case 'controlStyle':
		this.controlStyle = value;
		if (year) { year.style.cssText = value;	}
		if (month) { month.style.cssText = value; }
		if (day) { day.style.cssText = value;	}
		break;
	case 'disabled':
		value = (value) ? true : false;
		this.disabled = value;
		var d = (this.readOnly || this.disabled);
		if (year) { year.disabled = d; }
		if (month) { month.disabled = d; }
		if (day) { day.disabled = d; }
		// change label style
		var lbl = this.getLabelElement();
		if (lbl) {
			if (this.disabled) {
				lbl.className = 'zenLabelDisabled';
			}
			else {
				lbl.className = (''==this.labelClass) ? 'zenLabel' : this.labelClass;
			}
		}
		break;
	case 'readOnly':
		value = (value) ? true : false;
		this.readOnly = value;
		var d = (this.readOnly || this.disabled);
		if (year) { year.disabled = d; }
		if (month) { month.disabled = d; }
		if (day) { day.disabled = d; }
		break;

	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
