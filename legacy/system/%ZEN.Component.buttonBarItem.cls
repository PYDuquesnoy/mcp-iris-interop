/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %ZEN.Component.buttonBarItem
Class %ZEN.Component.buttonBarItem Extends component [ Deprecated, System = 3 ]
{

Parameter INCLUDEFILES = "zenCSLM.js,zenMenus.js";

/// URI of image to display under normal conditions.
Property icon As %ZEN.Datatype.uri;

/// URI of image to display when option is grayed-out.
Property iconDisabled As %ZEN.Datatype.uri;

/// If defined, roll over tooltip to display when button is enabled
Property caption As %ZEN.Datatype.string;

/// onclick event handler:
/// This event is fired when the mouse is clicked on the buttonBarItem.
Property onclick As %ZEN.Datatype.eventHandler;

XData Style
{
<style type="text/css">
/* @doc="Enclosing div for COMP_NAME." */
.buttonBarItem {
    display:block;
    cursor:pointer;
    font: 12px sans-serif;
    background: #e0e0e0;
    color: black;
}

.zenToolTip {
    background: white;
    border:2px ridge #0000aa;
    font:12px sans-serif;
}

</style>
}

Method %DrawHTML()
{
	
	&html<<div class="buttonBarItem" id="#(..%MakeId("buttonBarItem"))#" #(..%Attr("icon",..icon))# #(..%Attr("grayIcon",..iconDisabled))# #(..%Attr("caption",..caption))# #(..%Attr("onselect",..onclick))# ></div>>
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
