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
/// date matching.
Class EnsPortal.Component.packageText Extends %ZEN.Component.control [ System = 4 ]
{

Parameter DEFAULTCONTROLCLASS = "comboboxInput";

/// Localized "invalid date" message displayed by control.
Property invalidDateMessage As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Invalid Date","%ZEN")} ];

/// Optional.
/// If specified, this is the earliest date allowed by the calendar.
/// This is a date in the form "YYYY-MM-DD".<br>
Property minDate As %ZEN.Datatype.string;

/// Optional.
/// If specified, this is the latest date allowed by the calendar.
/// This is a date in the form "YYYY-MM-DD".<br>
Property maxDate As %ZEN.Datatype.string;

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

Parameter USECOMMONDIRECTORY = 1;

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* text button in dateText */
.dateTextButton {
	vertical-align: middle;
	font-size: 0.7em;
	height: 100%;
}
</style>
}

Method %DrawHTML()
{
	#; do not add this to set of events
	Set tIgnore("onchange")=""

	Set disabled = $S(..disabled:"disabled",1:"")
	Set ro = $S(..readOnly:"readonly",1:"")
	Set bflag = $S(..readOnly:"readonly",1:"")
	
	#; if there are expressions for these props, evaluate
	Set ..minDate = $$$ZENVAL(..minDate)
	Set ..maxDate = $$$ZENVAL(..maxDate)

	&html<<table border="0" cellspacing="0" cellpadding="0">>
	#; render as one line as CR will mess up the display
	//&html<<tr><td style="white-space: nowrap"><input class="#(..controlClass)#" type="text" size="12" id="#(..%MakeId("control"))#" #(..%Name())# #(disabled)# #(ro)# #(..%Attr("value",..value))# #(..%GetEventHandlers(.tIgnore))# onchange="zenPage.getComponent(#(..index)#).ondatechangeHandler();"><img src='#(##class(%CSP.Page).Link("/csp/broker/images/datetext.gif"))#' id="#(..%MakeId(""))#" onclick="zenPage.getComponent(#(..index)#).showDateSelector();" class="comboboxImgButton"/></td></tr>>
	&html<<tr><td style="white-space: nowrap"><input class="#(..controlClass)#" type="text" size="12" id="#(..%MakeId("control"))#" #(..%Name())# #(disabled)# #(ro)# #(..%Attr("value",..value))# #(..%GetEventHandlers(.tIgnore))# onchange="zenPage.getComponent(#(..index)#).ondatechangeHandler();"><img src='#(##class(%CSP.Page).Link("/csp/broker/images/dot.gif"))#' id="#(..%MakeId(""))#" onclick="zenPage.getComponent(#(..index)#).showDateSelector();" class="comboboxImgButton"/></td></tr>>

	&html<</table>>
}

/// onchange handler for this component.
ClientMethod ondatechangeHandler() [ Language = javascript ]
{
	var ctrl = this.findElement('control');
	zenASSERT(ctrl,'Unable to find input element',arguments);

	// parse date entered by user:
	var v = zenParseDate(ctrl.value);
	ctrl.value = (-1 == v) ? this.invalidDateMessage : v;

	// notify
	this.onchangeHandler();
}

/// Display date selector for this control.
ClientMethod showDateSelector() [ Language = javascript ]
{
	if (this.disabled || this.readOnly) return;

	// get control value
	var ctrl = this.findElement('control');
	zenASSERT(ctrl,'Unable to find input element',arguments);
	var value = ctrl.value;

	// find position of control
	var top,left;
	var top = zenGetTop(ctrl) + ctrl.offsetHeight - zenGetTopScroll(ctrl);
	var left = zenGetLeft(ctrl) - zenGetLeftScroll(ctrl);

	// adjust for window scroll bars
	top += document.body.scrollTop;
	left += document.body.scrollLeft;

	var group = zenPage.createComponent('modalGroup');
	group.setProperty('onaction','zenPage.getComponent('+this.index+').applyDate(group);');

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
	ctrl.value = value;
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
			el.value = value;
		}
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
	
	var d = zenParseDate(value);
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

}
