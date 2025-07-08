/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for SVG components.<br>
/// Unlike HTML components, SVG components are completely dynamic;
/// all rendering is done using client-side JavaScript.<br>
/// Every component is rendered within its own enclosing group (g) element.
Class %ZEN.SVGComponent.svgComponent Extends %ZEN.Component.object [ Abstract, Deprecated, System = 3 ]
{

/// Internal parameter.
Parameter POSTCOMPILEACTIONS = "schema,SVG";

/// Subclasses can set this to change default visibilty for a component.
Parameter DEFAULTVISIBLE = 1;

/// Default width of this component.
Parameter DEFAULTWIDTH As INTEGER = 100;

/// Default height of this component.
Parameter DEFAULTHEIGHT As INTEGER = 100;

/// Default viewBoxWidth of this component.
Parameter DEFAULTVIEWBOXWIDTH As INTEGER;

/// Default viewBoxHeight of this component.
Parameter DEFAULTVIEWBOXHEIGHT As INTEGER;

/// Subclasses can set this to change the default value for the <property>hidden</property> property for a component.
Parameter DEFAULTHIDDEN As BOOLEAN = 0;

/// Subclasses can set this to change the default value for the <property>boundless</property> property for a component.
Parameter DEFAULTBOUNDLESS As BOOLEAN = 0;

/// Subclasses can set this to change the default value for the <property>preserveAspectRatio/<property> property for a component.
Parameter DEFAULTASPECT As STRING;

/// x position of this component's enclosing group.<br>
/// The actual position of the component depends on the 
/// layout applied by its containing svgGroup.
Property x As %ZEN.Datatype.length [ InitialExpression = 0 ];

/// y position of this component's enclosing group.<br>
/// The actual position of the component depends on the 
/// layout applied by its containing svgGroup.
Property y As %ZEN.Datatype.length [ InitialExpression = 0 ];

/// If position is "fixed", then this shape will not scroll with its canvas
/// nor can it be dragged with the mouse.<br/>
/// This is used for placing fixed controller over the rest of an SVG canvas.
Property position As %ZEN.Datatype.string(VALUELIST = ",fixed,relative", ZENSETTING = 0) [ InitialExpression = "relative" ];

/// Width of this component.<br>
/// This value is used for layout purposes.
/// The actual effect of setting this is up the specific component implementation.
Property width As %ZEN.Datatype.length [ InitialExpression = {..#DEFAULTWIDTH} ];

/// Width of this component.<br>
/// This value is used for layout purposes.
/// The actual effect of setting this is up the specific component implementation.
Property height As %ZEN.Datatype.length [ InitialExpression = {..#DEFAULTHEIGHT} ];

/// If defined, this is used to calculate the width of the
/// viewBox attribute of the enclosing svg element.<br>
Property viewBoxWidth As %ZEN.Datatype.integer [ InitialExpression = {..#DEFAULTVIEWBOXWIDTH} ];

/// If defined, this is used to calculate the height of the
/// viewBox attribute of the enclosing svg element.<br>
Property viewBoxHeight As %ZEN.Datatype.integer [ InitialExpression = {..#DEFAULTVIEWBOXHEIGHT} ];

/// Value to apply for this component's enclosing svg element's
/// preserveAspectRatio attribute.<br>
/// Set this to "none" if you do not want the SVG Engine to preserve the aspect
/// ratio (height relative to width) for this component.
Property preserveAspectRatio As %ZEN.Datatype.string [ InitialExpression = {..#DEFAULTASPECT} ];

/// Client-side property that points to the enclosing SVG group element for this component.
Property svgGroup As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENCLIENTONLY = 1, ZENSETTING = 0);

/// Client-side property that points to SVG document this component is rendered on.
Property document As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENCLIENTONLY = 1, ZENSETTING = 0);

/// If true, this component is hidden. That is, it's enclosing
/// group's display style is set to "none".
Property hidden As %ZEN.Datatype.boolean [ InitialExpression = {..#DEFAULTHIDDEN} ];

/// If true, this component is boundless. That is, it's enclosing
/// svg element is a simple group (g) instead of the usual svg element.
Property boundless As %ZEN.Datatype.boolean(ZENSETTING = 0) [ InitialExpression = {..#DEFAULTBOUNDLESS} ];

/// onclick event handler:
/// This event is fired when the mouse is clicked on the shape.
/// This is the default onclick event for svg components; subclasses
/// may implement more specialized events (such as click on a specific part of the component).
Property onclick As %ZEN.Datatype.eventHandler;

/// Client-side property used to determine if a component is an SVG component.
Property svgComponent As %ZEN.Datatype.boolean(XMLPROJECTION = "none", ZENCLIENTONLY = 1, ZENSETTING = 0) [ InitialExpression = 1 ];

/// Define basic style block to ensure inclusion of core .css file.
XData SVGStyle
{
<style type="text/css">
</style>
}

/// Do not allow HTML methods for SVG components.
Method %DrawHTML() [ Final ]
{
	&html<<div style="color: red; border: 1px solid black; background: white;">An SVG component must be placed within an svgFrame</div>>
}

/// Render the outer SVG enclosing group for this component
/// as well as its inner contents.<br>
/// This is called by the svgFrame when the component
/// is first loaded or created.<br>
/// <var>parent</var> is the parent SVG object this component should be added to.
ClientMethod renderSVG(document, parent) [ Final, Language = javascript ]
{
	zenASSERT(document,"SVG Document is null",arguments);

	// create enclosing group
	this.document = document;
	this.createEnclosingGroup(parent);

	// draw contents of component
	this.render();
}

/// Internal method:<br>
/// create the enclosing group for this component.
ClientMethod createEnclosingGroup(parent) [ Final, Internal, Language = javascript ]
{
	if (this.boundless) {
		this.svgGroup = this.document.createElementNS(SVGNS,'g');
		this.svgGroup.setAttribute('transform','translate('+this.x+','+this.y+')');
	}
	else {
		this.svgGroup = this.document.createElementNS(SVGNS,'svg');
		this.svgGroup.setAttribute('viewBox',this.calculateViewBox());
		this.svgGroup.setAttribute('preserveAspectRatio',zenIsMissing(this.preserveAspectRatio) ? 'none' : this.preserveAspectRatio);
		this.svgGroup.setAttribute('width',this.width);
		this.svgGroup.setAttribute('height',this.height);
		this.svgGroup.setAttribute('x',this.x);
		this.svgGroup.setAttribute('y',this.y);
	}

	// assign id to the enclosing group
	// Use component id for enclosing group; if not defined
	// use zen#, where # is the index number.
	this.svgGroup.setAttribute('id',(''==this.id) ? 'zen_'+this.index : this.id);

	// default click handler
	this.svgGroup.addEventListener('click',this.wrapMethod('clickHandler'),false);

	if (this.hidden) {
		this.svgGroup.setAttribute('style','display: none;');
	}

	// add to parent
	if ('fixed' == this.position) {
		var fg = this.document.getElementById('zenFixedOverlay');
		fg.appendChild(this.svgGroup);
	}
	else {
		parent.appendChild(this.svgGroup);
	}
}

/// Default mouse click handler.
ClientMethod clickHandler(evt) [ Language = javascript ]
{
	evt.stopPropagation();
	return zenInvokeCallbackMethod(this.onclick,this,'onclick');
}

/// Calculate the value of the viewBox attribute of this
/// component's enclosing svg element.<br>
/// Subclasses can override this, should they need to provide
/// a different behavior.
/// The default behavior is to use the width and height of this component
/// to come up with a 1 to 1 coordinate mapping; If the component
/// provides values for the <property>viewboxWidth</property> and 
/// <property>viewboxHeight</property> properties, then these are used to
/// calculate the viewBox (and thus define a fixed coordinate system for the component).
ClientMethod calculateViewBox() [ Language = javascript ]
{
	var vw = ('' == this.viewBoxWidth) ? this.width : this.viewBoxWidth;
	var vh = ('' == this.viewBoxHeight) ? this.height : this.viewBoxHeight;
	return '0 0 ' + vw + ' ' + vh;
}

/// Render the inner SVG contents of this component.
/// This is implemented by subclasses.
ClientMethod renderContents() [ Language = javascript ]
{
}

/// Remove the inner SVG for this component.
ClientMethod unrender() [ Language = javascript ]
{
	if (null == this.svgGroup) {
		return;
	}
	
	if (null == this.svgGroup.childNodes || 0 == this.svgGroup.childNodes.length) {
		return;
	}

	// remove SVG elements within our enclosing group.
	while(null != this.svgGroup.firstChild) {
		this.svgGroup.removeChild(this.svgGroup.firstChild);
	}
}

/// This is not supported for SVG components
ClientMethod refreshContents() [ Final, Language = javascript ]
{
	return;
}

/// Client-side utility method that finds an SVG element with a 
/// component-specific id.
ClientMethod findSVGElement(subid) [ Final, Language = javascript ]
{
	if (null == this.document || '' == this.document) {
		// we are not rendered yet
		return null
	}
	return this.document.getElementById(subid + '_' + this.index);
}

/// Display an overlay for this component to trap mouse events
/// and/or support dragging/resizing with the mouse.<br>
/// <var>mode</var> is the overlay mode:<br>
/// 0: turn off overlay.<br>
/// 1: turn on overlay.<br>
/// 2: turn on overlay, show indication that this component
/// is <em>selected</em>.
/// 3: turn on overlay, show indication that this component
/// can be dragged.
ClientMethod setOverlayMode(mode) [ Language = javascript ]
{
	if (!this.svgGroup) return;

	// get overlay group for this page
	var overGroup = this.document.getElementById('zenOverlay');
	zenASSERT(overGroup,'Unable to find svg overlay group for the page.',arguments);

	// if we have an overlay remove it
	var overlay = this.document.getElementById('overlay_'+this.index);
	if (overlay) {
		overGroup.removeChild(overlay);
		delete this._overlayGroup;
		delete this._overlayRect;
		delete overlay;
	}

	this.overlayMode = mode;

	// now, add an overlay if needed (note we may be called
	// for purpose of recreating the overlay).
	if (mode > 0 && this.position != 'fixed') {
		this.createOverlay();
	}
}

/// Internal method:<br>
/// Render the SVG for the overlay/resize handles.
ClientMethod createOverlay() [ Internal, Language = javascript ]
{
	// get overlay group for this page
	var overGroup = this.document.getElementById('zenOverlay');
	zenASSERT(overGroup,'Unable to find svg overlay group for the page.',arguments);

	// create overlay group
	this._overlayGroup = this.document.createElementNS(SVGNS,'g');
	this._overlayGroup.setAttribute("id",'overlay_'+ this.index);
	this._overlayGroup.setAttribute('style',this.hidden ? 'display: none;' : '');

	overGroup.appendChild(this._overlayGroup);

	// calculate size & position of overlay
	// relative to the canvas
	var size = this.getSizeAbsolute();

	// overlay rect
	var cls = 'zenSvgOverlay';
	switch (this.overlayMode) {
	case 1:
		cls = 'zenSvgOverlay';
		break;
	case 2:
		cls = 'zenSvgOverlaySelected';
		break;
	case 3:
		cls = 'zenSvgOverlayDrag';
		break;
	}
	
	var rect = this.document.createElementNS(SVGNS,"rect");
	rect.setAttribute("x",size.x);
	rect.setAttribute("y",size.y);
	rect.setAttribute("width",size.width);
	rect.setAttribute("height",size.height);
	rect.setAttribute("class",cls);
	rect.setAttribute("id","overlayRect_" + this.index);
	this._overlayRect = rect;
	this._overlayGroup.appendChild(rect);

	rect.addEventListener('mousedown',new Function('evt','return zenPage.getComponent('+this.index+').overlayMouseDownHandler(evt);'),false);
	if (this.overlayMode == 3) {
		/* sizing handles */
		// corners
		this._handleNW = this.createSizingHandle('nw',size.x,size.y);
		this._handleNE = this.createSizingHandle('ne',size.x+size.width,size.y);
		this._handleSW = this.createSizingHandle('sw',size.x,size.y+size.height);
		this._handleSE = this.createSizingHandle('se',size.x+size.width,size.y+size.height);
	
		this._overlayGroup.appendChild(this._handleNE);
		this._overlayGroup.appendChild(this._handleNW);
		this._overlayGroup.appendChild(this._handleSW);
		this._overlayGroup.appendChild(this._handleSE);
	}
}

/// Internal method:<br>
/// Update size & position of overlay if present.
ClientMethod updateOverlay(x, y, width, height) [ Internal, Language = javascript ]
{
	if (this._overlayRect) {
		var rect = this._overlayRect;
		rect.setAttribute("x",x);
		rect.setAttribute("y",y);
		rect.setAttribute("width",width);
		rect.setAttribute("height",height);
	}
	if (this._handleNW) {
		this._handleNW.setAttribute("transform","translate(" + (x) + "," + (y) + ")");
	}
	if (this._handleNE) {
		this._handleNE.setAttribute("transform","translate(" + (x+width) + "," + (y) + ")");
	}
	if (this._handleSW) {
		this._handleSW.setAttribute("transform","translate(" + (x) + "," + (y+height) + ")");
	}
	if (this._handleSE) {
		this._handleSE.setAttribute("transform","translate(" + (x+width) + "," + (y+height) + ")");
	}
}

/// Internal method:<br>
/// Create SVG for one of the sizing "handles."
ClientMethod createSizingHandle(which, x, y) [ Internal, Language = javascript ]
{
	var sz = 8;

	var rect = this.document.createElementNS(SVGNS,"rect");
	rect.setAttribute("transform","translate(" + x + "," + y + ")");
	rect.setAttribute("rx",1);
	rect.setAttribute("x",-sz/2);
	rect.setAttribute("y",-sz/2);
	rect.setAttribute("width",sz);
	rect.setAttribute("height",sz);
	rect.setAttribute("class","zenSizingHandle");

	rect.setAttribute("style","cursor: " + which + "-resize");
	rect.addEventListener('mousedown',new Function('evt','which','return zenPage.getComponent('+this.index+').sizingMouseDownHandler(evt,"'+which+'");'),false);
	return rect;
}

/// Internal method:<br>
/// Overlay mouse down handler.
ClientMethod overlayMouseDownHandler(evt) [ Internal, Language = javascript ]
{
	var frame = this.getFrame();
	if (frame) {
		frame.selectItem(this, evt.ctrlKey);
		if (frame.canDragShapes()) {
			frame.startMove(evt,this);
		}
	}
}

/// Internal: sizing handle mouse down handler.
ClientMethod sizingMouseDownHandler(evt, which) [ Language = javascript ]
{
	var frame = this.getFrame();
	if (frame) {
		frame.selectItem(this, evt.ctrlKey);
		if (frame.canDragShapes()) {
			frame.startResize(evt,this,which);
		}
	}
}

/// Return the svgFrame object this component belongs to.
ClientMethod getFrame() [ Language = javascript ]
{
	if (!this.parent) {		// DTB145 - broaden test for missing parent
		return null;
	}
	else if (this.parent.isOfType('svgFrame')) {
		return this.parent;
	}
	else {
		return this.parent.getFrame();
	}
}

/// Utility method:
/// Find the svg text element with id <var>id</var>
/// and replace its text with <var>str</var>.
ClientMethod setTextNode(id, str) [ Language = javascript ]
{
	if (!this.document) return;

	var text = this.findSVGElement(id);
	if (!text) return;

	// create next text node and replace the current one
	var oldNode = text.firstChild;
	text.removeChild(oldNode);

	var textNode;
	textNode = this.document.createTextNode(str);
	text.appendChild(textNode);
}

/// Utility method:
/// Construct a wrapper around an instance method of this object
/// that can be used as an event listener.
ClientMethod wrapMethod(methodName) [ Language = javascript ]
{
	return new Function('evt','return zenPage.getComponent('+this.index+').'+methodName+'(evt);');
}

/// Return an object containing (as x,y,width, and height properties) 
/// the absolute size and position (relative to the svg 
/// canvas) of this component.
ClientMethod getSizeAbsolute() [ Language = javascript ]
{
	// if we have a parent, start with it
	var size = null;
	if (this.parent && this.parent.getSizeAbsolute) {
		var size = this.parent.getSizeAbsolute();
		size.x += parseFloat(this.x);
		size.y += parseFloat(this.y);
	}
	else {
		var size = new Object();
		size.x = parseFloat(this.x);
		size.y = parseFloat(this.y);
	}
	size.width = parseFloat(this.width);
	size.height = parseFloat(this.height);
	return size;
}

/// Set the x,y position of this component.<br>
/// Applications should not call this method.
ClientMethod setPosition(x, y) [ Language = javascript ]
{
	x = parseFloat(x);
	y = parseFloat(y);

	if (this.x != x || this.y != y) {
		this.x = x;
		this.y = y;
		if (this.svgGroup) {
			this.svgGroup.setAttribute('x',this.x);
			this.svgGroup.setAttribute('y',this.y);
		}
	}

	// update overlay, if present
	if (this._overlayRect) {
		var size = this.getSizeAbsolute();
		this.updateOverlay(size.x,size.y,size.width,size.height);
	}

	if (this.setPositionHandler) {
		this.setPositionHandler();
	}
}

/// Set the size (width and height) of this component.<br>
/// Applications should not call this method.
ClientMethod setSize(w, h) [ Language = javascript ]
{
	w = parseInt(w,10);
	h = parseInt(h,10);
	
	if (this.width != w || this.height != h) {
		this.width = w;
		this.height = h;
		if (this.svgGroup) {
			this.svgGroup.setAttribute('width',this.width);
			this.svgGroup.setAttribute('height',this.height);
			this.svgGroup.setAttribute('viewBox',this.calculateViewBox());
		}
	}
	// update overlay, if present
	if (this._overlayRect) {
		var size = this.getSizeAbsolute();
		this.updateOverlay(size.x,size.y,size.width,size.height);
	}
	
	if (this.setSizeHandler) {
		this.setSizeHandler();
	}
}

/// Notification that this component has been moved.
/// This can be implemented by subclasses. 
ClientMethod setPositionHandler() [ Abstract, Language = javascript ]
{
}

/// Notification that this component has been resized.
/// This can be implemented by subclasses. 
ClientMethod setSizeHandler() [ Abstract, Language = javascript ]
{
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'x':
		this.setPosition(value,this.y);
		break;
	case 'y':
		this.setPosition(this.x,value);
		break;
	case 'width':
	case 'height':
		if (property == 'width') {
			this.setSize(value,this.height);
		}
		else {
			this.setSize(this.width,value);
		}
		// notify parent
		if (this.parent) {
			this.parent.layoutChildren();
		}
		break;
	case 'preserveAspectRatio':
		this[property] = value;
		if (this.svgGroup) {
			this.svgGroup.setAttribute('preserveAspectRatio',zenIsMissing(this.preserveAspectRatio) ? 'none' : this.preserveAspectRatio);
		}
		break;
	case 'viewBoxWidth':
	case 'viewBoxHeight':
		this[property] = (''==value) ? '' : parseInt(value,10);
		if (this.svgGroup) {
			this.svgGroup.setAttribute('viewBox',this.calculateViewBox());
		}
		break;
	case 'hidden':
		value = value ? true : false;
		if (this.hidden != value) {
			this.hidden = value;
			// JMD981: test for "disposed object"
			// JMD1089: remove JMD981!
			if (this.svgGroup) {
				this.svgGroup.setAttribute('style',this.hidden ? 'display: none;' : '');
			}
			// update overlay, if present
			if (this._overlayGroup) {
				this._overlayGroup.setAttribute('style',this.hidden ? 'display: none;' : '');
			}
			// JMD981: test for "disposed object"
			if (this.svgGroup==null) {
				this.parent.layoutChildren();
			}
		}
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}

	return true;
}

/// Begin a wait state for this component.
/// This will display a waiting graphic in the center of this component.
/// The wait state is ended with a call to <method>endWaitState</method>.
ClientMethod beginWaitState() [ Language = javascript ]
{
	if (null == this._waitTimer) {
		this._waitCounter = 0;
		this.drawWaitIcon(this._waitCounter,true);
		this._waitTimer = window.setTimeout("zenPage.getComponent(" + this.index + ").updateWaitState()",250);
	}
}

/// Called by the wait state handler to animate the wait state icon.
ClientMethod updateWaitState() [ Internal, Language = javascript ]
{
	this._waitCounter++;
	this.drawWaitIcon(this._waitCounter,true);
	this._waitTimer = window.setTimeout("zenPage.getComponent(" + this.index + ").updateWaitState()",250);
}

/// Draw the wait state icon for this component.
/// <var>counter</var> is a counter increment each time this method is called.
/// If <var>draw</var> is true, then draw the icon, otherwise only erase it.
ClientMethod drawWaitIcon(counter, draw) [ Internal, Language = javascript ]
{
	if (this.svgGroup) {
		if (this._waitIcon) {
			while(null != this._waitIcon.firstChild) {
				this._waitIcon.removeChild(this._waitIcon.firstChild);
			}
			try {
				this.svgGroup.removeChild(this._waitIcon);
			}
			catch(ex) {
				// swallow error
			}
			delete this._waitIcon;
		}
		if (draw) {
			this._waitIcon = this.document.createElementNS(SVGNS,'g');
			var cx = 50;
			var cy = 50;
			this._waitIcon.setAttribute('transform','translate('+cx+','+cy+')');
			this.svgGroup.appendChild(this._waitIcon);

			var circ = this.document.createElementNS(SVGNS,'circle');
			circ.setAttribute('style','opacity:0.7;fill:rgb(100,100,200);');
			circ.setAttribute('cx',0);
			circ.setAttribute('cy',0);
			circ.setAttribute('r',25);
			this._waitIcon.appendChild(circ);

			var rays = 13;
			for (var r=0; r<rays; r++) {
				var line = this.document.createElementNS(SVGNS,'line');
				if (((r+counter)%rays)==0) {
					line.setAttribute('style','stroke:white;stroke-width:4px;stroke-linejoin:round;stroke-linecap:round;');
				}
				else {
					var op = 0.9 - 0.8*(((r+counter)%rays) / rays);
					line.setAttribute('style','opacity:'+op+';stroke:#D0D0D0;stroke-width:4px;stroke-linejoin:round;stroke-linecap:round;');
				}
				line.setAttribute('x1',15);
				line.setAttribute('x2',22);
				line.setAttribute('y1',0);
				line.setAttribute('y2',0);
				line.setAttribute('transform','rotate('+(-r*(360/rays))+')');
				this._waitIcon.appendChild(line);
			}
		}
	}
}

/// End the current wait state for this component.
ClientMethod endWaitState() [ Language = javascript ]
{
	if (null != this._waitTimer) {
		window.clearTimeout(this._waitTimer);
		delete this._waitTimer;
	}
	delete this._waitCounter;
	this.drawWaitIcon(0,false);
}

}
