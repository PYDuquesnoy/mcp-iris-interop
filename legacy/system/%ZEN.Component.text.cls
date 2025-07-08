/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Simple text input control.<br>
/// This is a simple wrapper around the HTML input=text control.
Class %ZEN.Component.text Extends control [ Deprecated, System = 3 ]
{

Parameter DEFAULTCONTROLCLASS = "text";

/// Size of the input area for this text control.
Property size As %ZEN.Datatype.integer(MINVAL = 0);

/// Maximum number of characters allowed within the text control.
Property maxlength As %ZEN.Datatype.integer(MINVAL = 0);

/// Expose placeholder attribute to Zen.
Property placeholder As %ZEN.Datatype.caption;

/// Allow for alternate types of input controls such as telephone, email etc which give more feedback particularly on mobile devices
Property inputtype As %ZEN.Datatype.string(VALUELIST = ",text,email,tel,password,url,search") [ InitialExpression = "text" ];

/// If true, this control has spellcheck enabled. Assuming this is an HTML5 browser implementation. IE9 does not support this.
Property spellcheck As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// This attribute indicates how the value of the control can be automatically completed by the browser.
Property autocomplete As %ZEN.Datatype.string [ InitialExpression = "on" ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Style for text (input)." */
.text {
}
</style>
}

Method %DrawHTML()
{
	Set disabled = $S(..disabled:"disabled",1:"")
	Set ro = $S(..readOnly:"readonly",1:"")
	Set spellcheck = $S(..spellcheck:"spellcheck=""true""",1:"spellcheck=""false""")

	If (..autocomplete=0) Set ..autocomplete = "off"
	If (..autocomplete=1) Set ..autocomplete = "on"
	If (..autocomplete="false") Set ..autocomplete = "off"
	If (..autocomplete="true") Set ..autocomplete = "on"
	
	&html<<input #(..%Attr("type",..inputtype))# class="#(..controlClass)#" #(..%Attr("title",..title))# id="#(..%MakeId("control"))#" #(..%Name())# #(disabled)# #(ro)# #(..%Attr("value",..value))# #(..%Attr("size",..size))# #(..%Attr("maxlength",..maxlength))# #(..%Attr("style",..controlStyle))# #(..%Attr("tabindex",..tabIndex))# #(..%Attr("placeholder",..placeholder))# #(spellcheck)# #(..%Attr("autocomplete",..autocomplete))# #(..%GetEventHandlers())#/>>
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var el = this.findElement('control');

	switch(property) {
	case 'size':
		this.size = value;
		if (el) { el.size = value; }
		break;
	case 'maxlength':
		this.maxlength = value;
		if (el) { el.maxlength = value; }
		break;
	case 'inputtype':
	case 'placeholder':
	case 'spellcheck':
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
