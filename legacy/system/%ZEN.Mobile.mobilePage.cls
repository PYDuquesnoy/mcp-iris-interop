/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sqlui, %sySystem)

/// This base class provides a standard template for pages on mobile devices
/// implemented using Zen.
Class %ZEN.Mobile.mobilePage Extends %ZEN.Component.page [ Deprecated, LegacyInstanceContext, System = 3 ]
{

Parameter JSINCLUDES = "zenCSLM.js";

/// Set this to the appropriate application class.
Parameter APPLICATION = "%ZEN.Portal.Application";

/// If true, auto-switch namespace to whatever $NAMESPACE is passed in.
Parameter AUTONS As BOOLEAN = 0;

/// Set this to the correct domain.
Parameter DOMAIN = "%Utility";

/// Name of this page.
Parameter PAGENAME = "Standard Mobile Page";

/// Default maximum extent of this page
Parameter DEFAULTEXTENTWIDTH = "device-width";

/// Default maximum extent of this page
Parameter DEFAULTEXTENTHEIGHT = "device-height";

/// Default maximum scale factor
Parameter DEFAULTMAXSCALE = 1.0;

/// Default minimum scale factor
Parameter DEFAULTMINSCALE = 1.0;

/// Default setting for user scaling
Parameter DEFAULTUSERSCALABLE = "no";

/// Default setting for hiding the URL bar on small screens (where possible)
Parameter DEFAULTHIDEURL = 1;

/// Default setting for prevent default processing of page level gestures
Parameter DEFAULTPREVENTGESTURES = 0;

Parameter DEFAULTLAYOUT = "none";

Property extentWidth As %ZEN.Datatype.integer [ InitialExpression = {..#DEFAULTEXTENTWIDTH} ];

Property extentHeight As %ZEN.Datatype.integer [ InitialExpression = {..#DEFAULTEXTENTHEIGHT} ];

Property maxScale As %ZEN.Datatype.integer [ InitialExpression = {..#DEFAULTMAXSCALE} ];

Property minScale As %ZEN.Datatype.integer [ InitialExpression = {..#DEFAULTMINSCALE} ];

Property userScalable As %ZEN.Datatype.string [ InitialExpression = {..#DEFAULTUSERSCALABLE} ];

Property simulatedDeviceWidth As %ZEN.Datatype.integer [ InitialExpression = 480 ];

Property simulatedDeviceHeight As %ZEN.Datatype.integer [ InitialExpression = 320 ];

Property hideURLBar As %ZEN.Datatype.integer [ InitialExpression = {..#DEFAULTHIDEURL} ];

Property preventDefaultGestures As %ZEN.Datatype.integer [ InitialExpression = {..#DEFAULTPREVENTGESTURES} ];

Property bodyScrollTop As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">
</style>
}

/// Use soft modals for the portal.
ClassMethod %OnUseSoftModals() As %Boolean [ CodeMode = expression ]
{
1
}

/// This method is used by the default OnDrawHTMLMeta() callback to generate 
/// the contents of the viewport meta tag 
Method %GenerateMetaContent() As %String
{
	Set tStr = "width="_..extentWidth_", initial-scale=1.0, maximum-scale="_..maxScale
	if (..maxScale'=..minScale) {
		Set tStr = tStr_", minimum-scale="_..minScale
	}
	Set tStr = tStr_", user-scalable="_..userScalable
	Quit tStr
}

/// This callback is called at the start of the HTML HEAD section of the page (just after the title).<br/>
/// It allows a page to write out meta tags, if desired.
/// (default implementation is a simple expression).
Method %OnDrawHTMLMeta() As %Status
{
	//&html<<meta name="apple-mobile-web-app-capable" content="yes" />>
	
	&html<<meta name="viewport" content="#(..%GenerateMetaContent())#" />>
	// force ie9
	&html<<meta http-equiv="X-UA-Compatible" content="IE=9" />>
	Quit $$$OK
}

ClientMethod isDesktopBrowser() [ Language = javascript ]
{
	var ua = navigator.userAgent;
	var ua = ua.toLowerCase();
	if (ua.indexOf("mobile")>=0) return(false);
	if (ua.indexOf("windows")>=0) return(true);
	if (ua.indexOf("os x")>=0) return(true);
	if (ua.indexOf("linux")>=0) return(true);
	if (ua.indexOf("solaris")>=0) return(true);
	if (ua.indexOf("bsd")>=0) return(true);
	return(false);
}

ClientMethod getNativeWindowWidth() [ Language = javascript ]
{
	if (this.isDesktopBrowser()) return(this.simulatedDeviceWidth);
	return(window.innerWidth);
}

ClientMethod getNativeWindowHeight() [ Language = javascript ]
{
	if (this.isDesktopBrowser()) return(this.simulatedDeviceHeight);
	return(window.innerHeight);
}

ClientMethod getBodyScrollTop() [ Language = javascript ]
{
       
	var win = window;
	var d = document;
	return (win.pageYOffset || d.compatMode === 'CSS1Compat' && d.documentElement.scrollTop || d.body.scrollTop || 0);
}

ClientMethod updateMetaSettings() [ Language = javascript ]
{
	var meta = window.document.querySelector( "meta[name=viewport]" );
    var initialContent = meta && meta.getAttribute( "content" );
    if (!meta) return;
    var tArr = [];
	if (zenPage.orientation=="portrait") {
		tArr.push("width="+this.extentWidth+", initial-scale=1.0");
	}
	else {
		tArr.push("width="+this.extentHeight+", initial-scale=1.0");	
	}
    tArr.push(", maximum-scale="+this.maxScale);
    if (this.maxScale != this.minScale) {
	    tArr.push(", minimum-scale="+this.minScale);
    }
    tArr.push(", user-scalable="+this.userScalable);
     
    var newSettings=tArr.join("");
    meta.setAttribute("content",newSettings);
}

ClientMethod initDeviceInterface() [ Final, Language = javascript ]
{
	if (window.DeviceMotionEvent==undefined) {
		zenPage.featureDeviceMotion = false;
	}
	else {
		zenPage.featureDeviceMotion = true;
		window.addEventListener("devicemotion",function(event){zenPage.fireOnDeviceMotionEvent(event);});
	}
	var body = document.getElementsByTagName("body")[0];
	body.setAttribute("onorientationchange","zenPage.fireOnRotateEvent();");
	body.setAttribute("ontouchstart","zenPage.fireOnTouchStartEvent(event);");
	body.setAttribute("ontouchend","zenPage.ontouchendHandler(event);");
	body.setAttribute("ontouchmove","zenPage.ontouchmoveHandler(event);");
}

ClientMethod fireOnDeviceMotionEvent(event) [ Final, Language = javascript ]
{
	zenPage.ondevicemotionHandler(event);
}

/// Client-side method: fire onload event for every component that defines one.
/// This are fired in reverse order, so that the page's handler is called last.
ClientMethod fireOnLoadEvent() [ Final, Language = javascript ]
{
	zenPage.initDeviceInterface();
	
	
	// initialize layout manager if applicable
	if (this.dragAndDrop && ZLM) {
		ZLM.initDataDragDrop();
	}

	for (var n = _zenIndex.length - 1; n >= 0; n--) {
		if (_zenIndex[n] && _zenIndex[n].onloadHandler) {
			_zenIndex[n].onloadHandler();
		}
	}
	if (this.isDesktopBrowser()) this.hideURLBar = false;
	
	this.fireOnRotateEvent();
    if (zenPage.hideURLBar && zenPage.userScalable=="no") {
	    setTimeout("window.scrollTo(0,1);",0);
    }
	return true;
}

ClientMethod fireOnRotateEvent() [ Language = javascript ]
{
	var w = this.getNativeWindowWidth();
	var h = this.getNativeWindowHeight();
	var meta = window.document.querySelector( "meta[name=viewport]" );
    var initialContent = meta && meta.getAttribute( "content" );
	if (w>h) {
		zenPage.orientation ="landscape";
  			if (h<400 && zenPage.hideURLBar && zenPage.userScalable=="no") {
	  			h+=60; // iOS specific value need to check Android and others;
   			}
	}
    else {
	    zenPage.orientation="portrait";
  			if (w<400 && zenPage.hideURLBar && zenPage.userScalable=="no") {
	  			h+=60; // iOS specific value need to check Android and others;
   			}
    }
	zenPage.activeWidth = w;
	zenPage.activeHeight = h;
	
    var zb = document.getElementById("zenBody");
    var s = zb.style;
    s.position="absolute";
    s.display="block";
    s.width=w+"px";
    s.height=h+"px";
    s.border="1px solid black";
    if (zenPage.hideURLBar && zenPage.userScalable=="no") {
	    s.overflow = "hidden";
	    window.scrollTo(0,1);
    }
    this.updateMetaSettings();
	this.onrotateHandler();
}

/// Call the (potentially redefined) ontouchstartHandler for the page and
/// implmenet the preventDefaultGesture logic as needed
ClientMethod fireOnTouchStartEvent(event) [ Language = javascript ]
{
	this.ontouchstartHandler(event);
	if (this.preventDefaultGestures==true) event.preventDefault();
}

/// This method may be redefined to specify custom handling of touch start events
ClientMethod ontouchstartHandler(event) [ Language = javascript ]
{
}

/// This method may be redefined to specify custom handling of touch move events
ClientMethod ontouchmoveHandler(event) [ Language = javascript ]
{
}

/// This method may be redefined to specify custom handling of touch end events
ClientMethod ontouchendHandler(event) [ Language = javascript ]
{
}

/// This method may be redfined to specify custom handling when the orientation
/// of the mobile device changes
ClientMethod onrotateHandler() [ Language = javascript ]
{
}

/// This method may be redefined to specify custom handling of device motion events
ClientMethod ondevicemotionHandler(event) [ Language = javascript ]
{
}

ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
}

}
