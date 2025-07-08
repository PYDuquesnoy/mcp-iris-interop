/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Multi-line text input control.
/// This is a simple wrapper around the HTML textarea control.<br>
/// Note that many browsers do not cope well with long lines 
/// of unbroken text (i.e., greater than 4K characters with no white space.)
Class %ZEN.Component.textarea Extends control [ Deprecated, System = 3 ]
{

Parameter DEFAULTCONTROLCLASS = "textarea";

/// Number of rows in the textarea control.
Property rows As %ZEN.Datatype.integer(MINVAL = 0);

/// Number of columns in the textarea control.
Property cols As %ZEN.Datatype.integer(MINVAL = 0);

/// Internal property.<br>
/// Keep track of whether user has modified this control.
Property modFlag As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// If true, this control has spellcheck enabled. Assuming this is an HTML5 browser implementation. IE9 does not support this.
Property spellcheck As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Style for textarea." */
.textarea {
}
</style>
}

Method %DrawHTML()
{
	Set disabled = $S(..disabled:"disabled",1:"")
	Set ro = $S(..readOnly:"readonly",1:"")
	Set spellcheck = $S(..spellcheck:"spellcheck=""true""",1:"spellcheck=""false""")


	#; Note: we do not set the contents of this control here on the initial display
	#; instead we set it on the client from the JS object
	#; to avoid sending two copies of the data
	#; if tuple is defined, then we are in a repeating group and need to project a value
	#; if there is an expression, we should also project a value
	Set tValue = $S($G(%zenContext)="method":$$$ZENVALHTML(..value),..tuple'="":$$$ZENVALHTML(..value),1:"")
	If (..tuple="") {
		// make sure expression is eval'd
		Set ..value = $$$ZENVALHTML(..value)
	}
	&html<<textarea id="#(..%MakeId("control"))#" class="#(..controlClass)#" #(..%Attr("title",..title))# #(..%Name())# #(..%Attr("cols",..cols))# #(..%Attr("rows",..rows))# #(disabled)# #(ro)# #(spellcheck)# #(..%Attr("style",..controlStyle))# #(..%Attr("tabindex",..tabIndex))# #(..%GetEventHandlers())#>#(tValue)#</textarea>>
}

/// This client event is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// copy value from JS object to HTML control
	var el = this.findElement('control');
	if (el) {
		el.value = this.value;
	}
}

/// Return true if the current value of this control is different
/// than its orginal value.<br>
/// Override default implementation.
ClientMethod isModified() [ Language = javascript ]
{
	return (''==this.originalValue) ? this.modFlag : (this.originalValue != this.value);
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var el = this.findElement('control');

	switch(property) {
	case 'originalValue':
		// intercept attempt to clear the mod flag
		this.modFlag = false;

		// only keep original value for *small* textareas
		if ('string'==typeof this.value && this.value.length < 50) {
			this.originalValue = this.value;
		}
		else {
			this.originalValue = '';
		}
		break;
	case 'rows':
		this.rows = value;
		if (el) { el.rows = value; }
		break;
	case 'cols':
		this.cols = value;
		if (el) { el.cols = value; }
		break;
	case 'spellcheck':
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// This built-in event handler is called by the HTML control
/// associated with the control to raise notification that 
/// the control's value has changed.
/// Override to set our modified flag.
ClientMethod onchangeHandler() [ Language = javascript ]
{
	this.modFlag = true;
	return this.invokeSuper('onchangeHandler',arguments);
}

}
