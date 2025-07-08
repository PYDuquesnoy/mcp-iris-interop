/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Boolean checkbox control<br>
/// This uses an HTML input=check control plus it displays a
/// caption (<property>caption</property>) next to the checkbox
/// and detects user mouse click on caption.<br>
/// Unlike an HTML checkbox, this checkbox always submits a value.
/// It submits a value of 1 or 0 to the server; The client side
/// value is either true or false.
Class %ZEN.Component.checkbox Extends control [ Deprecated, System = 3 ]
{

Parameter DOMAIN = "%ZEN";

Parameter DEFAULTCONTROLCLASS = "checkbox";

Parameter DEFAULTCLIENTTYPE = "boolean";

/// Additional caption displayed next to actual checkbox.<br>
/// This is a localized value.
Property caption As %ZEN.Datatype.caption(ZENEXPRESSION = 1);

/// CSS class to apply to the control's caption.
Property captionClass As %ZEN.Datatype.cssClass [ InitialExpression = "checkboxCaption" ];

/// If this is true then no checkbox will be built. Instead, it will write "Yes" or "No" based on the checkbox's value.
Property readonlyNobox As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Style for checkbox control." */
.checkbox {
}

/* @doc="Caption for checkbox." */
span.checkboxCaption {
	cursor: pointer;
	white-space: nowrap;
}
</style>
}

Method %DrawHTML()
{
	Set disabled = $S(..disabled:"disabled",1:"")

	#; to avoid usual problems with HTML checkbox
	#; we use a hidden control to hold the actual value
	&html<<input type="hidden" id="#(..%MakeId("hidden"))#" #(..%Name())# value="#(+..value)#"/>>

	#; do not add onclick to set of events
	#; instead we intercept it and call it from there
	#; also handle onchange special to deal with IE
	Set tIgnore("onclick")=""
	Set tIgnore("onchange")=""

	#; evaluate value (if need be) 
	Set tValue = $$$ZENVAL(..value)
	Set ..onclick = $$$ZENVALJS(..onclick)
	Set ..onchange = $$$ZENVALJS(..onchange)

	Set tChecked = $Case(+tValue,1:"checked=""1""",:"")
	If '..readonlyNobox {
		&html<<span style="white-space: nowrap;"><input type="checkbox" class="#(..controlClass)#" #(..%Attr("title",..title))# id="#(..%MakeId("control"))#" #(tChecked)# #(disabled)# onclick="return #(..%Self())#.clickCheckbox();" #(..%Attr("tabindex",..tabIndex))# #(..%GetEventHandlers(.tIgnore))#/><span class="#(..captionClass)#" id="#(..%MakeId("caption"))#" #(..%Attr("title",..title))# #(..%Attr("tabindex",..tabIndex))# onclick="#(..%Self())#.clickCaption();">#($ZCVT($$$ZENVAL(..caption),"O","HTML"))#&nbsp;</span></span>>
	} Else {
		&html<<span style="white-space: nowrap;" class="#(..controlClass)#" #(..%Attr("title",..title))#>#($S(+tValue=1:$$$TextHTML("Yes"),1:$$$TextHTML("No")))#<span class="#(..captionClass)#" id="#(..%MakeId("caption"))#" #(..%Attr("title",..title))# #(..%Attr("tabindex",..tabIndex))#>#($ZCVT($$$ZENVAL(..caption),"O","HTML"))#&nbsp;</span></span>>
	}
}

/// This method fills in reasonable default values for
/// this control. Used by tools (such as Control Tester) to
/// dynamically create controls.
Method %SetDefaultValues()
{
	Set ..caption = "Checkbox"
}

/// User click on checkbox; update hidden value;
ClientMethod clickCheckbox() [ Language = javascript ]
{
	if (this.readOnly) return false;

	var cb = this.findElement('control');
	zenASSERT(cb,'Unable to find checkbox element',arguments);

	var hidden = this.findElement('hidden');
	zenASSERT(hidden,'Unable to find hidden element',arguments);
	hidden.value = cb.checked ? '1' : '0';
	this.value = cb.checked;

	// invoke callback(s), if present
	zenInvokeCallbackMethod(this.onclick,this,'onclick');
	// notify
	this.onchangeHandler();
	return true;
}

/// Get current value for serial state.
ClientMethod onSerialize() [ Language = javascript ]
{
	var cb = this.findElement('control');
	if (cb) {
		this.value = cb.checked;
	}
}

/// User click on caption for checkbox; toggle value;
ClientMethod clickCaption() [ Language = javascript ]
{
	if (this.disabled) return;
	if (this.readOnly) return;

	var cb = this.findElement('control');
	zenASSERT(cb,'Unable to find checkbox element',arguments);
	cb.checked = !cb.checked;
	
	var hidden = this.findElement('hidden');
	zenASSERT(hidden,'Unable to find hidden element',arguments);
	hidden.value = cb.checked ? '1' : '0';
	this.value = cb.checked;

	// invoke callback(s), if present
	zenInvokeCallbackMethod(this.onclick,this,'onclick');
	// notify
	this.onchangeHandler();
}

/// Override to get value of control
ClientMethod getProperty(property, key) As %String [ Language = javascript ]
{
	switch(property) {
	case 'value':
		// ignore value of control
		return this.normalizeValue(this.value);
	}

	// dispatch
	return this.invokeSuper('getProperty',arguments);
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var el = this.findElement('control');
	var hidden = this.findElement('hidden');

	switch(property) {
	case 'value':
		value = this.normalizeValue(value);
		this.value = value;
		if (el) { el.checked = value; }
		if (hidden) { hidden.value = value ? '1' : '0'; }
		break;
	case 'caption':
		var caption = this.findElement('caption');
		this.caption = value;
		if (caption) { caption.innerHTML = zenEscapeHTMLSafe(value); }
		break;
	case 'captionClass':
		var caption = this.findElement('caption');
		this.captionClass = value;
		if (caption) { caption.className = value; }
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
