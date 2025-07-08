/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Client-side timer object.
/// This component automatically creates a javascript timer object within
/// the client and initializes it when the page is first loaded.
/// The timer is one-shot; after it fires its ontimeout event, you
/// must restart it by calling the client <method>startTimer</method> method.
Class %ZEN.Component.timer Extends component [ Deprecated, System = 3 ]
{

/// this component is not visible.
Parameter DEFAULTVISIBLE = 0;

/// ontimeout event handler:
/// Client code to run when timeout expires.
Property ontimeout As %ZEN.Datatype.eventHandler;

/// Timeout value (in milliseconds).<br>
/// Setting this to 0 will disable the timer.
Property timeout As %ZEN.Datatype.integer(MINVAL = 0);

/// Internal: id of client-side timer object
Property timerid As %ZEN.Datatype.string(XMLPROJECTION = "none") [ Internal ];

/// Start the timer.
ClientMethod startTimer() [ Language = javascript ]
{
	this.clearTimer();
	if (0 != this.timeout && this.ontimeout && this.ontimer != '') {
		var code = this.ontimeout;
		// escape ""
		code = code.replace(/\"/g,'\\\"');
		this.timerid = window.setTimeout('zenFireEvent('+this.index+',"'+code+'","ontimeout");',this.timeout);
	}
}

/// Clear the timer object used by this component.
ClientMethod clearTimer() [ Language = javascript ]
{
	if (this.timerid) {
		window.clearTimeout(this.timerid);
		this.timerid = null;
	}
}

/// This client event is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.startTimer();
}

/// This client method, if present, is called when this component is
/// removed from the page.
ClientMethod onDelete() [ Language = javascript ]
{
	this.clearTimer();
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'timeout':
		// application must call startTimer
		value = parseInt(value,10);
		value = isNaN(value) ? 0 : value;
		this.timeout = value;
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
