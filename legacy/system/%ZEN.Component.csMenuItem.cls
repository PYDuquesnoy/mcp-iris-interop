/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %ZEN.Component.csMenuItem
Class %ZEN.Component.csMenuItem Extends group [ Deprecated, System = 3 ]
{

Parameter INCLUDEFILES = "zenCSLM.js,zenMenus.js";

/// URI of image to display under normal conditions.
Property icon As %ZEN.Datatype.uri;

/// URI of image to display when option is grayed-out.
Property iconDisabled As %ZEN.Datatype.uri;

/// label normally associated with the menu pick
Property caption As %ZEN.Datatype.caption;

/// If defined, keystroke of caption to invoke functionality when
/// menu is active
Property contextKey As %ZEN.Datatype.string;

/// If defined, global keyboard shortcut to simulate a mouse click
Property key As %ZEN.Datatype.string;

/// URI of alternate image to display under toggled conditions.
Property altIcon As %ZEN.Datatype.uri;

/// If defined, alternate label for a toggled menu pick
Property altCaption As %ZEN.Datatype.string;

/// If defined, global keyboard shortcut to invoke alternate behavior
Property altKey As %ZEN.Datatype.string;

/// If defined, a flag to indicate that a checkmark (instead of an alternate 
/// caption) should be used to indicate a toggled state of the menu pick
Property toggleMode As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If toggleMode is true or an alternate caption has been defined, this flag
/// is used to indicate the current state of the menu pick.  A value of zero
/// indicates the base state (no check mark visible, primary caption in use).
/// A value of 1 indicates that either a check mark is visible or the alternate
/// caption is currently being displayed.  This attribute may also be used 
/// to set the initial state of the menu pick. 
Property toggleState As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// onclick event handler:
/// This event is fired when the mouse is clicked on the csMenuItem or
/// when the key or altKey shortcuts have been typed
Property onclick As %ZEN.Datatype.eventHandler;

XData Style
{
<style type="text/css">
/* @doc="Enclosing div for COMP_NAME." */
.csMenuItem {
    position:absolute;
    cursor:pointer;
    font:12px sans-serif;
    background:white;
    color:black;
    height:20px;
}
</style>
}

Method %DrawHTML()
{
	&html<<div class="csMenuItem" id="#(..%MakeId("csMenuItem"))#" #(..%Attr("title",..title))# #(..%Attr("icon",..icon))# #(..%Attr("grayIcon",..iconDisabled))# #(..%Attr("caption",..caption))# #(..%Attr("contextKey",..contextKey))# #(..%Attr("key",..key))# #(..%Attr("altIcon",..altIcon))# #(..%Attr("altCaption",..altCaption))# #(..%Attr("altKey",..altKey))# #(..%Attr("toggleMode",..toggleMode))# #(..%Attr("onselect",..onclick))# >>
	#; layout children using the default layout.
	Do ##class(%ZEN.LayoutManager).default($this,..tuple)
	&html<</div>>
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
		case "disabled":
			this.disabled = value;
			var div=this.getEnclosingDiv();
			var item = div.item;
			if (!item) return;
			if (value) {
				ZMS.disableMenuOptionNode(item);
			}
			else {
				ZMS.enableMenuOptionNode(item);				
			}
			break;
		case "toggleState":
			if (value!=this.toggleState) {
				var div=this.getEnclosingDiv();
				var item = div.item;
				if (!item) return;
				// ToggleState value will be set in external call
				ZMS.toggleMode(item);
			}
			break;	
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Unpack the short form of the widget as dished up by the web server
/// in to the full DOM subtree used in the browser
ClientMethod initializeClientSideProjection() [ Language = javascript ]
{
    var div=this.getEnclosingDiv();
    ZLM.setLocalAttribute(div,"onclick","");
	for (var k=div.firstChild;k!=null;k=k.nextSibling) {
		if (k.nodeType==1 && k.className=="csMenuItem") {
			ZMS.createMenuItemSubtree(k,20);
			div.item=k;
			k.zenObj = this;
			if (this.disabled) this.setProperty("disabled",this.disabled);
			if (this.toggleState==1) {
				this.toggleState=0;
				this.setProperty("toggleState",1);
			}
			else this.toggleState = 0;
			return;
		}
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// dispatch to get correct disabled handling
	this.invokeSuper('onloadHandler',arguments);
    ZMS.initialize();
	this.initializeClientSideProjection();
}

}
