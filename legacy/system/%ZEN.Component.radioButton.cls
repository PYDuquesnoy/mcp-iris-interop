/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// radio button control.<br>
/// This provides a wrapper around the HTML input=radio control with
/// some enhanced capabilities.
Class %ZEN.Component.radioButton Extends control [ Deprecated, System = 3 ]
{

Parameter DEFAULTCONTROLCLASS = "radio";

/// Additional caption displayed next to actual radio button.<br>
/// This is a localized value.
Property caption As %ZEN.Datatype.caption(ZENEXPRESSION = 1);

/// CSS class to apply to the control's caption.
Property captionClass As %ZEN.Datatype.cssClass [ InitialExpression = "radioButtonCaption" ];

/// Defines the value associated with this specific radio button.
/// This is in contrast with the <property>value</property> which
/// defines the value of the entire set of radio buttons.
Property optionValue As %ZEN.Datatype.value(ZENEXPRESSION = 1);

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Caption for radio button." */
a.radioButtonCaption {
	cursor: pointer;
	white-space: nowrap;
	text-decoration: none;
	color: black;
}

/* @doc="Caption for disabled radio button." */
a.radioButtonCaptionDisabled {
	white-space: nowrap;
	color: gray;
	text-decoration: none;
}

a.radioButtonCaption:hover {
	color: red;
}

a.radioButtonCaption:link, .radioButtonCaption:visited, .radioButtonCaption:active {
}

a.radioButtonCaptionDisabled:link, .radioButtonCaptionDisabled:visited, .radioButtonCaptionDisabled:active {
}

</style>
}

Method %DrawHTML()
{
	Set disabled = $S(..disabled||..readOnly:"disabled",1:"")

	#; every group of related buttons has a shared hidden
	#; field that is used for the actual submit value
	#; this makes it easier to use a radioButton in the same
	#; manner as other controls
	#; see if we are the first (lowest index #) button with our name
	If ((..name '= "")&&$IsObject($G(%page))&&(%page.%GetComponentByName(..name)=$this)) {
		&html<<input type="hidden" id="#(..%MakeId("hidden"))#" #(..%Name())# value="#(..value)#"/>>
	}

	#; do not add this to set of events
	#; instead we intercept it and call it from the there
	Set tIgnore("onclick")=""
	Set tIgnore("onchange")=""

	Set tValue = $$$ZENVAL(..value)
	Set tOptValue = $$$ZENVAL(..optionValue)
	Set checked = $Case(tValue=tOptValue,1:"checked=""1""","true":"checked=""1""",:"")
	#; override default name behavior:
	#; we do *not* want submit to process the actual radio button
	Set tCaptionClass = $S(..disabled:"radioButtonCaptionDisabled",1:..captionClass)
	&html<<input type="radio" class="#(..controlClass)#" id="#(..%MakeId("control"))#" #(..%Attr("name",..name))#  #(..%Attr("title",..title))# #(checked)# #(disabled)# value="#($ZCVT(tOptValue,"O","HTML"))#" onclick="return #(..%Self())#.clickButton();" #(..%GetEventHandlers(.tIgnore))#/>>
	if ..caption'="" &html<<a id="#(..%MakeId("caption"))#" class="#(tCaptionClass)#" #(..%Attr("title",..title))# onclick="#(..%Self())#.clickCaption();return false;" href="">#($ZCVT($$$ZENVAL(..caption),"O","HTML"))#&nbsp;</a>>
}

/// Setting value of any radio button, sets value for 
/// other buttons in the same group.
Method valueSet(%val) As %Status
{
	Set i%value = %val

	If (i%name'="") {
		#; Only update other buttons in the context of a page
		If '$isobject($get(%page)) Quit $$$OK
		Set tIndex = $O(%page.%ComponentNames(i%name,""))
		While (tIndex'="") {
			Set:(%page.%Components(tIndex).value'=%val) %page.%Components(tIndex).value = %val
			Set tIndex = $O(%page.%ComponentNames(i%name,tIndex))
		}
	}
	Quit $$$OK
}

/// This method fills in reasonable default values for
/// this control. Used by tools (such as Control Tester) to
/// dynamically create controls.
Method %SetDefaultValues()
{
	Set ..caption = "Radio"
	Set ..optionValue = "RadioOne"
}

/// User click on radio button.
ClientMethod clickButton() [ Language = javascript ]
{
	if (this.disabled) return false;
	if (this.readOnly) return false;

	var btn = this.findElement('control');
	zenASSERT(btn,'Unable to find radio element',arguments);
	var changed = false;

	if (btn.checked) {
		// find hidden field associated with this group and
		// set its value as well as related buttons
		// walk list of components until we find the hidden field
		for (var n in _zenIndex) {
			if (_zenIndex[n] && _zenIndex[n].name == this.name && _zenIndex[n]._type == this._type) {
				_zenIndex[n].value = this.optionValue;

				var hidden = _zenIndex[n].findElement('hidden');
				if (hidden) {
					if (hidden.value != this.optionValue) {
						changed = true;
						hidden.value = this.optionValue;
					}
				}
			}
		}
	}

	// invoke callback(s), if present
	zenInvokeCallbackMethod(this.onclick,this,'onclick');

	// notify
	if (changed) {
		this.onchangeHandler();
	}
	
	return true;
}

/// User click on caption for radio button; select this button.
ClientMethod clickCaption() [ Language = javascript ]
{
	if (this.disabled) return;
	if (this.readOnly) return;

	var rb = this.findElement('control');
	zenASSERT(rb,'Unable to find radioButton element',arguments);
	if (rb.checked) return;
	rb.checked = true;
	
	// make sure hidden field is updated
	this.clickButton();
}

/// Override to get current value of control.
ClientMethod getProperty(property, key) As %String [ Language = javascript ]
{
	var el = this.findElement('hidden');

	switch(property) {
	case 'value':
		if (el) { 
			this.value = el.value;
		}
		return this.normalizeValue(this.value);
	}

	// dispatch
	return this.invokeSuper('getProperty',arguments);
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'readOnly':
	case 'disabled':
		value = (value) ? true : false;
		if (this[property] != value) {
			this[property] = value;
			var rb = this.findElement('control');
			if (rb) {rb.disabled = (this.disabled||this.readOnly); }
			var caption = this.findElement('caption');
			if (caption) {caption.className = this.disabled ? 'radioButtonCaptionDisabled' : this.captionClass; }
		}
		break;
	case 'optionValue':
		this.optionValue = value;
		// update button
		var rb = this.findElement('control');
		rb.value = value;
		rb.checked = (this.optionValue == this.value);
		break;
	case 'value':
		// update master value for group and state of buttons
		for (var n in _zenIndex) {
			if (_zenIndex[n] && _zenIndex[n].name == this.name && _zenIndex[n]._type == this._type) {
				_zenIndex[n].value = value;
				var rb = _zenIndex[n].findElement('control');
				var hidden = _zenIndex[n].findElement('hidden');
				if (hidden) {
					hidden.value = value;
				}
				rb.checked = (_zenIndex[n].optionValue == value);
			}
		}
		break;
	case 'caption':
		var caption = this.findElement('caption');
		this.caption = value;
		caption.innerHTML = zenEscapeHTMLSafe(value);
		break;
	case 'captionClass':
		var caption = this.findElement('caption');
		this.captionClass = value;
		if (caption && !this.disabled) {
			caption.className = value;
		}
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Make sure serialization does not mess with our value.
ClientMethod onSerialize() [ Language = javascript ]
{
	return;
}

}
