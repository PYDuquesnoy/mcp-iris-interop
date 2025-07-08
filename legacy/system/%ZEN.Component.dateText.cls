/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Input control specialized for handling date values.<br>
/// This displays a text box as well as a button that
/// displays a popup calendar.<br>
/// When the user enters a value into this control, it will
/// be converted into the closest matching date value or 
/// and invalid date message.<br>
/// Setting the <property>value</property> property of this control, will bypass
/// date matching.<br/>
/// The value of this control is always in the canonical form: YYYY-MM-DD,
/// you can, however, <em>display</em> a different format by setting the <property>format</property>
/// property.
Class %ZEN.Component.dateText Extends control [ Deprecated, System = 3 ]
{

Parameter DEFAULTCONTROLCLASS = "dateTextInput";

/// Localization domain
Parameter DOMAIN = "%ZEN";

/// Localized "invalid date" message displayed by control.
Property invalidDateMessage As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Invalid Date","%ZEN")} ];

/// Size of the input area for this control.
Property size As %ZEN.Datatype.integer(MINVAL = 0) [ InitialExpression = 15 ];

/// Optional.
/// If specified, this is the earliest date allowed by the calendar.
/// This is a date in the form "YYYY-MM-DD".<br>
Property minDate As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// Optional.
/// If specified, this is the latest date allowed by the calendar.
/// This is a date in the form "YYYY-MM-DD".<br>
Property maxDate As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// If true, then this calendar will also display and allow the user
/// to edit the time of day portion of a date. In this case, the value
/// used by this control will be in xDBC timestamp format:
/// YYYY-MM-DD HH:MM:SS
Property showTime As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If specified and <property>showTime</property> is true, and the value
/// supplied does not include a time portion, this will be
/// used as the initial time displayed in the popup calendar.
Property defaultTime As %ZEN.Datatype.string(ZENEXPRESSION = 1);

/// List of localized day abbreviations shown at top of calendar.
/// If specified, this is passed on the popup calendar.
Property dayList As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

/// List of localized month names shown at top of calendar.
/// If specified, this is passed on the popup calendar.
Property monthList As %ZEN.Datatype.csv(ZENLOCALIZE = 1);

/// Localized caption for time input box (see <property>showTime</property>).
/// If specified, this is passed on the popup calendar.
Property timeCaption As %ZEN.Datatype.caption;

/// Specified which day of the week (Sunday=0, Saturday = 6) is displayed as
/// the starting day of the week.<br>
/// This allows for customizing the calendar for locales where weeks start with
/// other days of the week.
/// This is passed on the popup calendar.
Property firstDayOfWeek As %ZEN.Datatype.integer(MAXVAL = 6, MINVAL = 0) [ InitialExpression = 0 ];

/// onshowPopup event handler:
/// This event is fired just before the popup calendar is displayed.
/// It provides an opportunity to pass additional settings to the
/// popup calendar.<br>
/// The argument, <var>settings</var>, passed to this callback, is 
/// an object (associative array). Property values within this 
/// object are passed on as setting to the calendar control.<br>
/// For example:<br>
/// settings['gapWidth'] = '100px';
Property onshowPopup As %ZEN.Datatype.eventHandler;

/// Optional. Specifies the display format used for this component.
/// (Note that the internal value of this control is always YYYY-MM-DD).
/// Possible values are:<br/>
/// <ul>
/// <li>"YMD" - Year,Month,Day</li>
/// <li>"MDY" - Month,Day,Year</li>
/// <li>"DMY" - Day,Month,Year</li>
/// </ul>
Property format As %ZEN.Datatype.string(MAXLEN = 3, VALUELIST = ",MDY,DMY,YMD", ZENEXPRESSION = 1) [ InitialExpression = "YMD" ];

/// Optional. Specifies the separator character used between date segments.
/// Note, if time is also displayed, the time separator is <em>always</em> ":".
Property separator As %ZEN.Datatype.string(MAXLEN = 1, VALUELIST = ",-,/,., ", ZENEXPRESSION = 1) [ InitialExpression = "-" ];

/// Optional. URL of the "show calendar" icon displayed within this control.
Property image As %ZEN.Datatype.uri [ InitialExpression = "portal/calendar_48.gif" ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* @doc="Style for div around active dateText control" */
.dateTextDiv {
	border: 1px solid #8080D0;
	background: white;
	height: 18px;
}

/* @doc="Style for dateText input control." */
.dateTextInput {
	border: none;
}

.dateTextIcon {
	padding: 0px;
	width: 18px;
	height: 18px;
}

.dateTextIcon:hover {
	padding: 0px;
	background: #FFEEAA;
}

</style>
}

Method %DrawHTML()
{
	#; do not add this to set of events
	Set tIgnore("onchange")=""
	Set tIgnore("onkeydown")=""

	Set disabled = $S(..disabled:"disabled",1:"")
	Set ro = $S(..readOnly:"readonly",1:"")
	Set bflag = $S(..readOnly:"readonly",1:"")
	
	#; if localized properties have not been set, set them
	Set:..dayList="" ..dayList = $$$Text("S,M,T,W,T,F,S")
	Set:..monthList="" ..monthList = $$$Text("January,February,March,April,May,June,July,August,September,October,November,December")
	Set:..timeCaption="" ..timeCaption = $$$Text("Time:")

	#; if there are expressions for these props, evaluate
	Set ..minDate = $$$ZENVAL(..minDate)
	Set ..maxDate = $$$ZENVAL(..maxDate)
	Set ..format = $$$ZENVAL(..format)
	Set ..separator = $$$ZENVAL(..separator)
	If ..showTime {
		Set ..defaultTime = $$$ZENVALHTML(..defaultTime)
	}
	Else {
		Set ..defaultTime = ""
	}

	#; Get value
	Set tValue = $$$ZENVAL(..value)

	#; do not let #()# expression go to client
	Set ..value = tValue

	#; Validate and normalize defaultTime
	Set tDefaultTime = ..defaultTime
	Set tTime = $ztimeh(tDefaultTime,1,-1)
	If tTime'=-1 {
		Set tDefaultTime = $ztime(tTime,1)
		Set ..defaultTime = tDefaultTime
	}

	#; Add defaultTime to value if value is non-null and does not contain a time part, and defaultTime is a valid non-null time
	Set tDisplayValue = tValue
	If (tDisplayValue'="") && (tDefaultTime'="") {
		Set tUnformatted = $Tr(tDisplayValue,"/. ","---") // allowed date separators
		If $P(tUnformatted,"-",4,99)="" {
			Set tDisplayValue = tDisplayValue_" "_tDefaultTime
			Set ..value = tDisplayValue
		}
	}

	// JMDXXX: use layout from selector control
	/*
	&html<<table border="1" cellspacing="0" cellpadding="0">>
	#; render as one line as CR will mess up the display
	&html<<tr><td style="white-space: nowrap"><input class="#(..controlClass)#" type="text" size="#(+..size)#" id="#(..%MakeId("control"))#" #(..%Attr("title",..title))# #(..%Name())# #(disabled)# #(ro)# #(..%Attr("value",tDisplayValue))# #(..%Attr("tabindex",..tabIndex))# #(..%Attr("style",..controlStyle))# #(..%GetEventHandlers(.tIgnore))# onkeydown="return #(..%Self())#.keydownHandler(event);" onchange="#(..%Self())#.ondatechangeHandler();"/><img src="images/datetext.gif" id="#(..%MakeId("image"))#" onclick="#(..%Self())#.showDateSelector();" class="comboboxImgButton"/></td></tr>>
	&html<</table>>
	*/

	Set tTitle = $$$Text("Display calendar.","%ZEN")
	Set tIcon = ..image
	&html<<div class="dateTextDiv" id="#(..%MakeId("div"))#" style="opacity:0.1;width:#((..size*7)+22)#px;"><nobr>
	<input type="text" class="#(..controlClass)#" #(..%Attr("title",..title))# id="#(..%MakeId("control"))#" #(..%Name())# #(disabled)# #(ro)# #(..%Attr("value",..value))# #(..%Attr("size",..size))# #(..%Attr("style",..controlStyle))# #(..%Attr("tabindex",..tabIndex))# #(..%GetEventHandlers(.tIgnore))# onkeydown="return #(..%Self())#.keydownHandler(event);" onchange="#(..%Self())#.ondatechangeHandler();"/><image class="dateTextIcon" align="top" src="#(tIcon)#" id="#(..%MakeId("icon"))#" title="#(tTitle)#" onclick="#(..%Self())#.showDateSelector('#(..defaultTime)#');"/>
	</nobr></div>>
}

/// onchange handler for this component.
ClientMethod ondatechangeHandler() [ Language = javascript ]
{
	var ctrl = this.findElement('control');
	zenASSERT(ctrl,'Unable to find input element',arguments);

	// parse date entered by user:
	var v = zenParseDate(this.unformatValue(ctrl.value),this.showTime,this.format,this.separator);
	ctrl.value = (-1 == v) ? this.invalidDateMessage : v;

	// notify
	this.onchangeHandler();
}

/// Apply formatting to get displayed date value.
ClientMethod formatValue(val) [ Language = javascript ]
{
	if ('' != val) {
		if (-1 == val) {
			val = this.invalidDateMessage;
		}
		else {
			val = zenParseDate(val,this.showTime,this.format,this.separator);
		}
	}
	return val
}

/// Remove formatting to get logical date value.
ClientMethod unformatValue(val) [ Language = javascript ]
{
	if (this.invalidDateMessage == val) {
		val = -1;
	}
	else if ('' != val) {
		// Be a bit more forgiving of the separator used for user input
		var v=val.toString();
		v=v.replace(/\//g,'-');
		v=v.replace(/\./g,'-');
		v=v.replace(/ /g,'-');
		// n.b., later, we will put the space back before the time portion

		// pull formatted value apart
		var t = v.split('-');
		if (t.length>2) {
			switch (this.format) {
			case 'DMY':
				val = t[2] + this.separator + t[1] + this.separator + t[0];
				break;
			case 'MDY':
				val = t[2] + this.separator + t[0] + this.separator + t[1];
				break;
			case 'YMD':
				val = t[0] + this.separator + t[1] + this.separator + t[2];
				break;
			}
		}
		if (this.showTime && t[3]) {
			val += ' ' + zenNormalizeTime(t[3]);			
		}
		val = zenParseDate(val,this.showTime,'YMD','-');
	}
	return val
}

/// Display date selector for this control.
ClientMethod showDateSelector(defaultTime) [ Language = javascript ]
{
	if (this.disabled || this.readOnly) return;

	// get control value
	var ctrl = this.findElement('control');
	zenASSERT(ctrl,'Unable to find input element',arguments);
	var value = ctrl.value;

	// find position of control
	var left = zenGetLeft(ctrl) - zenGetLeftScroll(ctrl);

	// adjust for window scroll bars
	left += zenGetPageScrollLeft(this.window);

	var group = zenPage.createComponent('modalGroup');
	group.setProperty('onaction','zenPage.getComponent('+this.index+').applyDate(group);');

	// find position of control element
	var iHgt = ctrl.offsetHeight;
	var wScrollTop = zenGetPageScrollTop();
	var top;
	var obj = zenGetPageOffsets(ctrl);

	var dHgt = 200; //have to use default height of calendar popup, as it hasn't been rendered so far
	var hgt = zenGetWindowHeight();
	var uSpace = obj.top - wScrollTop;	
	var dSpace = hgt-uSpace-iHgt-2;

	if (dHgt>dSpace) { // dropdown won't fit as is
		if (dSpace>uSpace) {
			top = obj.top+iHgt;
		}
		else {
			top = obj.top-dHgt;
		}
	}		
	else {  // Dropdown is fine where it is but need to be in page coordinates
		top = obj.top+iHgt;
	}	

	// additional parameters for calendar
	var calParms = new Object();
	if ('' != this.minDate) {
		var minD = zenParseDate(this.minDate);
		if (-1 != minD) {
			var year = parseInt(minD.substr(0,4),10);
			calParms['minDate'] = this.minDate;
			calParms['startYear'] = year;
		}
	}
	if ('' != this.maxDate) {
		var maxD = zenParseDate(this.maxDate);
		if (-1 != maxD) {
			var year = parseInt(maxD.substr(0,4),10);
			calParms['maxDate'] = this.maxDate;
			calParms['endYear'] = year;
		}
	}

	// provide canonical value for calendar
	if ('' != value) {
		value = this.unformatValue(value);
		value = (-1 == value) ? '' : value;
	}

	if ('' == value) {
		// missing value, show current month
		var now = new Date();
		calParms['year'] = now.getFullYear();
		calParms['month'] = now.getMonth() + 1;
	}

	calParms['dayList'] = this.dayList;
	calParms['monthList'] = this.monthList;
	calParms['firstDayOfWeek'] = this.firstDayOfWeek;

	if (this.showTime) {
		calParms['timeCaption'] = this.timeCaption;
		calParms['showTime'] = this.showTime;
		calParms['defaultTime'] = this.defaultTime;
	}

	// invoke callback
	zenInvokeCallbackMethod(this.onshowPopup,this,'onshowPopup','settings',calParms);

	// show the calendar
	group.show('','calendar',value,top,left,null,null,calParms);
}

/// Apply the value from the popup to the input control.
ClientMethod applyDate(group) [ Language = javascript ]
{
	var value = group.getValue();
	var oldval = this.value;

	// update control
	var ctrl = this.findElement('control');
	ctrl.value = this.formatValue(value);
	this.value = value;
	
	// notify
	if (oldval != this.value) {
		// notify
		this.onchangeHandler();
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var el = this.findElement('control');

	switch(property) {
	case 'value':
		this.value = value;
		if (el) {
			el.value = this.formatValue(value);
		}
		break;

	case 'format':
	case 'separator':
		this[property] = value;
		if (el) {
			el.value = this.formatValue(this.value);
		}
		break;

	case 'showTime':
		value = value ? true : false;
		this.showTime = value;
		break;

	case 'defaultTime':
		this.defaultTime = zenNormalizeTime(value);
		break;

	case 'disabled':
	case 'readOnly':
		// first pass up to super class
		this.invokeSuper('setProperty',arguments);

		// then set state of button
		var btn = this.findElement('btn');
		if (btn) {
			btn.disabled = this.readOnly || this.disabled;
		}
		break;

	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// This method is called by the form validation mechanism to test
/// if the current contents of this control are valid.<br>
ClientMethod isValid() [ Language = javascript ]
{
	// check if we have a valid date
	var value = this.getValue();
	if ('' == value) return true;
	
	var d = zenParseDate(value,this.showTime);
	if (-1 == d) return false;

	// range check
	if (('' != this.minDate)||('' != this.maxDate)) {
		var currD = zenStringToDate(value);
	}
	if ('' != this.minDate) {
		var minD = zenStringToDate(this.minDate);
		if (minD.getTime() > currD.getTime()) return false;
	}
	if ('' != this.maxDate) {
		var maxD = zenStringToDate(this.maxDate);
		if (maxD.getTime() < currD.getTime()) return false;
	}

	return true;
}

/// Make sure that value is formatted correctly.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.setValue(this.value);
	this.adjustSize();
}

/// This client callback is called just from refreshContents
/// just after the new HTML is delivered from the server.
ClientMethod onRefreshContents() [ Language = javascript ]
{
	this.setValue(this.value);
}

ClientMethod keydownHandler(evt) [ Language = javascript ]
{
/// Key down handler; trap ESC to avoid IE issues.
	var ret = true;
	evt = evt ? evt : event;

	// prevent ESC
	if (evt.keyCode==zenESC) {
		if (event) {
			event.returnValue = false;
			return false;
		}
	}

	if ('' != this.onkeydown) {
		// stash event, run the code
		var oldEvent = zenEvent;
		zenEvent = evt;
		ret = zenInvokeCallbackMethod(this.onkeydown,this,'onkeydown');
		zenEvent = oldEvent;
	}
	return ret;
}

/// This client event, if present, is fired when the containing group is made visible.
ClientMethod onDisplayHandler() [ Language = javascript ]
{
	this.adjustSize();
}

/// Adjust size of control.
ClientMethod adjustSize() [ Language = javascript ]
{
	var el = this.findElement('control');
	var icon = this.findElement('icon');
	var div = this.findElement('div');
	if (el && icon && div) {
		div.style.opacity = 1.0;
		icon.style.width = el.offsetHeight + 'px';
		icon.style.height = el.offsetHeight + 'px';
		div.style.height = el.offsetHeight+2 + 'px';
		div.style.width = el.offsetWidth + el.offsetHeight+4 + 'px';
	}
}

}
