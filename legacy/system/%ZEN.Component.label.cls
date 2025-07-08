/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Simple label control.
/// A label passively displays a static text value.
/// The value of the label is submitted
/// along with other controls on a form.
Class %ZEN.Component.label Extends control [ Deprecated, System = 3 ]
{

Parameter DEFAULTCONTROLCLASS = "labelText";

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Style for labelText component." */
.labelText {
}
</style>
}

/// Override to get current value of control.
ClientMethod getProperty(property, key) As %String [ Language = javascript ]
{
	var el = this.findElement('label');

	switch(property) {
	case 'value':
		if (el) { 
			this.value = this.unformatValue ? this.unformatValue(el.value) : el.value;
		}
		return this.normalizeValue(this.value);
	}

	// dispatch
	return this.invokeSuper('getProperty',arguments);
}

Method %DrawHTML()
{
	&html<<input type="hidden" id="#(..%MakeId("label"))#" #(..%Name())# #(..%Attr("value",..value))#/>>
	Set tValue = $$$ZENVAL(..value)
	Set tTitle=$$$ZENVAL(..%Attr("title",..title))
	&html<<span id="#(..%MakeId("control"))#" #($S(tTitle'="":tTitle,1:""))# class="#(..controlClass)#" style="#(..controlStyle)#" #(..%GetEventHandlers(.tIgnore))#>#($ZCVT(tValue,"O","HTML"))#</span>>
}

/// This method fills in reasonable default values for
/// this control. Used by tools (such as Control Tester) to
/// dynamically create controls.
Method %SetDefaultValues()
{
	Set ..value = "MyLabel"
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var el = this.findElement('label');
	var span = this.findElement('control');

	switch(property) {
	case 'value':
		this.value = value;
		if (el) {el.value = value;}
		if (span) {span.innerHTML =  zenEscapeHTMLSafe(value);}
		break;
	case 'controlClass':
		this.controlClass = value;
		if (span) { span.className = this.controlClass;}
		break;
	case 'controlStyle':
		this.controlStyle = value;
		if (span) { span.style.cssText = value;	}
		break;	
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

ClientMethod onSerialize() [ Language = javascript ]
{
 
	var el = this.findElement('label');
	if (el) {
		this.value = this.normalizeValue(this.unformatValue ? this.unformatValue(el.value) : el.value);
	}
}

}
