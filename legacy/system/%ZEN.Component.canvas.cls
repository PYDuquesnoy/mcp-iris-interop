/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// HTML5 Canvas Element.<br/>
/// This is a wrapper around the HTML5 Canvas element.<br/>
/// This only works with an HTML5 browser that supports the Canvas element.
Class %ZEN.Component.canvas Extends component [ Deprecated, System = 3 ]
{

/// onrender event handler:
/// This event is fired by the render method and can supply
/// the content displayed by this component.
/// As a convenience, the event is passed an argument, context, which is the graphic context of the canvas
/// element.
Property onrender As %ZEN.Datatype.eventHandler;

/// Fallback HTML content to display. This is diplayed in browsers that do not support the Canvas element.
Property content As %ZEN.Datatype.html(CONTENT = "MIXED", ESCAPE = "HTML", XMLPROJECTION = "content");

Method %DrawHTML()
{
	&html<<canvas id="#(..%MakeId("canvas"))#" #(..%Attr("title",..title))# #(..%Attr("width",..width))# #(..%Attr("height",..height))#>>
	Write ..content
	&html<</canvas>>

	// cause client-side render to be called
	Do ##super()
}

/// Render the contents of this component's canvas.
ClientMethod renderContents() [ Language = javascript ]
{
	var ctx = this.getContext();

	// dispatch to user callback
	zenInvokeCallbackMethod(this.onrender,this,'onrender','context',ctx);
}

/// Return the 2D drawing context for this canvas element.<br/>
/// Returns null if the browser does not support the canvas element.
ClientMethod getContext() [ Language = javascript ]
{
	var canvas = this.findElement('canvas');
	return canvas.getContext ? canvas.getContext('2d') : null;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'content':
		var canvas = this.findElement('canvas');
		canvas.innerHTML = value;
		break;
	case 'onrender':
		this.onrender = value;
		break;

	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
		break;
	}
	return true;
}

}
