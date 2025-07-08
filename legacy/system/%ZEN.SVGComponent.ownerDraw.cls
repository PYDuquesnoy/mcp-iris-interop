/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Owner-draw svg component.<br>
/// This is an empty SVG component whose contents are filled dynamically
/// by invoking a run-time callback method.<br>
Class %ZEN.SVGComponent.ownerDraw Extends svgComponent [ Deprecated, System = 3 ]
{

/// onrender event handler:
/// This event is fired by the render method and can supply
/// the content displayed by this component.
Property onrender As %ZEN.Datatype.eventHandler;

/// Render the inner SVG contents of this component.
ClientMethod renderContents() [ Language = javascript ]
{
	if (this.svgGroup) {
		// dispatch to user callback
		zenInvokeCallbackMethod(this.onrender,this,'onrender');
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
