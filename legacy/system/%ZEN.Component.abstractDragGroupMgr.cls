/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %ZEN.Component.abstractDragGroupMgr
/// This is a parent class to house common functionality for all of the activeGroups
/// that are expected to have instances of DragGroup as their only immediate children
Class %ZEN.Component.abstractDragGroupMgr Extends activeGroup [ Deprecated, System = 3 ]
{

Parameter INCLUDEFILES = "zenCSLM.js";

/// To be compatible with the static layout manager the enclosing class
/// has to be the generic activeGroup rather than the specific type of 
/// dragGroup manager such as desktopGroup.
/// The desktopGroup (et al.) is the one used for tuning attributes of 
/// the absolutely  positioned elements.
Parameter DEFAULTENCLOSINGCLASS = "activeGroup";

/// The logical name of the manager with respect to the external JavaScript 
/// code that actually manages the space 
Property groupName As %ZEN.Datatype.string [ InitialExpression = "dragMgr" ];

XData Style
{
<style type="text/css">
</style>
}

Method %DrawHTML()
{
	&html<<div class="#(..groupName)#Group" id="#(..%MakeId(..groupName))#" style="width:100%; height:100%; position:absolute;">>
	Do ##class(%ZEN.LayoutManager).default($this,..tuple)
	&html<</div>>
}

/// Send one of several predefined signals to each of the active DragGroup windows associated
/// with this group.  Valid signals to pass include: <p />
/// "resize" - call the onresize handler (if any) for each window <br />
/// "disableCoverplate" - hide the event trapper coverplate from all windows
/// "disableResize" - remove the resize pip from the lower right corners of the windows <br />
/// "disableMaxToggle" - reset mouse clicks on the header to the default (drag) behavior <br />
/// "enableCoverplate" - force an invisible event trapper to cover the window to prevent contents from seeing events<br />
/// "enableMaxToggle" - redefine the window header to be a maximize button rather than a drag handle<br/>
/// "enableResize" - restore the resize pip to the lower right corners of the windows <br />
/// "removeDragHeader" - completely hide the drag handle and resize the window to use the recovered space<br />
/// "restoreDragHeader" - restore the drag handle and resize the window to account for the newly used space<br />
/// "setBodyStyle" - given a JSON representation of a style object in value, add the given rules to the existing style of the drag body<br />
/// "setHeaderStyle" - given a JSON representation of a style object in value, add the given rules to the existing style of the drag header<br />
/// "setHeaderLayout" - set the headerLayout property of all children to the given value
/// "processAppMessage" - simply pass the value given to the dragGroup children, subclasses of dragGroup
///    can override the default processAppMessage() method to extend the broadcast facility to address
///    application specific signals
ClientMethod broadcast(signal, value) [ Language = javascript ]
{
	var div = this.getEnclosingDiv();
	var mgr = div.firstChild.engine;
	if (!mgr) return(0); // Children not yet initialized
	var k = mgr.kidList;
	if (!k) return(0); // No one to talk to

	var lastKid = k.length-1;
	switch(signal) {
		case "resize":
				for (var i=lastKid;i>=0;i--) if (k[i].zenObj) k[i].zenObj.onresizeHandler();
			break;
		case "disableResize":
				for (var i=lastKid;i>=0;i--) if (k[i].zenObj) k[i].zenObj.disableResize();
			break;
		case "enableResize":
				for (var i=lastKid;i>=0;i--) if (k[i].zenObj) k[i].zenObj.enableResize();
			break;
		case "disableHeaderMaxToggle":
				for (var i=lastKid;i>=0;i--) if (k[i].zenObj) k[i].zenObj.disableHeaderMaxToggle();
			break;
		case "enableHeaderMaxToggle":
				for (var i=lastKid;i>=0;i--) if (k[i].zenObj) k[i].zenObj.enableHeaderMaxToggle();
			break;
		case "removeDragHeader":
				for (var i=lastKid;i>=0;i--) if (k[i].zenObj) k[i].zenObj.removeWindowChrome();
			break;
		case "restoreDragHeader":
				for (var i=lastKid;i>=0;i--) if (k[i].zenObj) k[i].zenObj.resetWindowChrome();
			break;
		case "setBodyStyle":
				//var styleObj = ZLM.jsonParse(value);
				//if (styleObj) {
				for (var i=lastKid;i>=0;i--) {
					if (k[i].zenObj) {
						k[i].zenObj.setBodyStyle(value);
					}
				}
			break;
		case "setHeaderStyle":
				for (var i=lastKid;i>=0;i--) {
					if (k[i].zenObj) {
						k[i].zenObj.setHeaderStyle(value);
					}
				}
			break;
		case "setHeaderLayout":				
				for (var i=lastKid;i>=0;i--) if (k[i].zenObj) k[i].zenObj.setProperty("headerLayout",value);
			break;
		case "enableCoverplate":
				for (var i=lastKid;i>=0;i--) if (k[i].zenObj) k[i].zenObj.enableCoverplate();
			break;
		case "disableCoverplate":
				for (var i=lastKid;i>=0;i--) if (k[i].zenObj) k[i].zenObj.disableCoverplate();
			break;
		case "processAppMessage":
				for (var i=lastKid;i>=0;i--) if (k[i].zenObj) k[i].zenObj.processAppMessage(value);
			break;
}
return(1);

// message sent
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

/// This forces the initial managerEngine pointer to null, subclasses should
/// reinitialize this on page load.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// dispatch to get correct disabled handling
	this.invokeSuper('onloadHandler',arguments);
	this.managerEngine = null;
}

/// Find the client-side group manager engine for this projection 
ClientMethod getGroupManager() [ Language = javascript ]
{
	if (!this.managerEngine) {
		var manager = ZLM.getGroupManager(this.groupName+"_"+this.index);
		if (manager) {
			this.managerEngine=manager.engine;
		}
	}
	return(this.managerEngine);
}

/// Programmatically give the "focus" to the given drag group 
ClientMethod bringToFront(dragGroup) [ Language = javascript ]
{
	var mgr = this.getGroupManager();
	var node = dragGroup.getEnclosingDiv();
	if (node && mgr && mgr.bringToFront) {
		mgr.bringToFront(node);
	}
}

/// Force a refresh of the grid size based of the current geometries
ClientMethod forceRefresh() [ Language = javascript ]
{
	var mgr = this.getGroupManager();
	if (mgr && mgr.resize) mgr.resize();
}

/// Return the HTML node used as the backdrop for the snapGrid.
ClientMethod getWallpaperDiv() [ Language = javascript ]
{
	var mgr = this.getGroupManager();
	if (mgr && mgr.getWallpaperDiv) return(mgr.getWallpaperDiv());
	return(null);
}

}
