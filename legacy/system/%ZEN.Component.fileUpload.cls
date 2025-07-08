/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// File upload control.<br>
/// This is a simple wrapper around the HTML input=file control.
Class %ZEN.Component.fileUpload Extends control [ Deprecated, System = 3 ]
{

Parameter DEFAULTCONTROLCLASS = "fileUpload";

/// Size of the input area for this control.
Property size As %ZEN.Datatype.integer(MINVAL = 0);

/// Optional comma-separated list of MIME types that can be uploaded.
/// This is used as the ACCEPT attribute for the HTML INPUT element used
/// for this component.
Property accept As %ZEN.Datatype.csv;

/// Allow multiple fileuploads at once. Default is false. Requires HTML5 to work.
Property multiple As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Maximum number of characters allowed within the control.
Property maxlength As %ZEN.Datatype.integer(MINVAL = 0);

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Style for fileUpload control" */
.fileUpload {
}
</style>
}

Method %DrawHTML()
{
	Set disabled = $S(..disabled:"disabled",1:"")
	Set ro = $S(..readOnly:"readonly",1:"")
	Set multiple = $S(..multiple:"multiple=""multiple""",1:"")	
	&html<<input type="file" class="#(..controlClass)#" id="#(..%MakeId("control"))#" #(..%Attr("title",..title))# #(..%Name())# #(multiple)# #(disabled)# #(ro)# #(..%Attr("size",..size))# #(..%Attr("accept",..accept))# #(..%Attr("maxlength",..maxlength))# #(..%Attr("style",..controlStyle))# #(..%Attr("tabindex",..tabIndex))# #(..%GetEventHandlers())#/>>
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
	case 'accept':
		this.accept = value;
		if (el) { el.accept = value; }
		break;
	case 'maxlength':
		this.maxlength = value;
		if (el) { el.maxlength = value; }
		break;
	case 'value':
		// programmatically setting the value 
		// to anything but empty string is a security
		// violation in modern browsers
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
