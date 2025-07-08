/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Button control.<br>
/// This is a wrapper around the HTML input=button control.<br>
/// The text displayed within the button is defined by the <property>caption</property> property.
/// Typically an application will set the <property>onclick</property> property 
/// (inherited from the <class>control</class>) of the button to
/// a JavaScript expression that is executed when the user clicks the button.
Class %ZEN.Component.button Extends control [ Deprecated, System = 3 ]
{

Parameter DEFAULTCONTROLCLASS = "button";

/// Caption displayed for this button.<br>
/// This is a localized value.
Property caption As %ZEN.Datatype.caption(ZENEXPRESSION = 1);

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Style for button (input)." */
.button {
}
</style>
}

Method %DrawHTML()
{
	Set disabled = $S(..disabled:"disabled",1:"")
	Set tIgnore("onchange") = ""
	&html<<input type="button" class="#(..controlClass)#" id="#(..%MakeId("control"))#" #(..%Attr("title",..title))# #(..%Attr("name",..name))# #(..%Attr("value",..caption))# #(disabled)# #(..%Attr("style",..controlStyle))# #(..%Attr("tabindex",..tabIndex))# #(..%GetEventHandlers(.tIgnore))#/>>
}

/// This method fills in reasonable default values for
/// this control. Used by tools (such as Control Tester) to
/// dynamically create controls.
Method %SetDefaultValues()
{
	Set ..caption = "Button"
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'caption':
		this.caption = value;
		var el = this.findElement('control');
		if (el) {
			el.value = this.caption;
		}
		break;
	case 'value':
		// do not set control value; just internal value
		this.value = value;
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
