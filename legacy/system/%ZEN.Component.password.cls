/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Simple password input control.<br>
/// This is a simple wrapper around the HTML input=password control.
Class %ZEN.Component.password Extends text [ Deprecated, System = 3 ]
{

Parameter DEFAULTCONTROLCLASS = "password";

/// This attribute indicates how the value of the control can be automatically completed by the browser.
Property autocomplete As %ZEN.Datatype.string [ InitialExpression = "new-password" ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Style for password (input)." */
.password {
}
</style>
}

Method %DrawHTML()
{
	// note: do *not* provide a value to the client
	Set disabled = $S(..disabled:"disabled",1:"")
	Set ro = $S(..readOnly:"readonly",1:"")
	&html<<input type="password" class="#(..controlClass)#" id="#(..%MakeId("control"))#" #(..%Attr("title",..title))# #(..%Name())# #(..%Attr("size",..size))# #(..%Attr("maxlength",..maxlength))# #(disabled)# #(ro)# #(..%Attr("style",..controlStyle))# #(..%Attr("tabindex",..tabIndex))# #(..%Attr("autocomplete",..autocomplete))# #(..%GetEventHandlers())#/>>
}

}
