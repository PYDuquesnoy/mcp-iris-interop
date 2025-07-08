/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a specialized type of group that is used
/// to place a set of SVG components within a page.<br>
/// Only groups and SVG components can be places within an svgFrame.
/// An error will occur if an HTML component is placed within
/// an svgFrame.
Class %ZEN.SVGComponent.svgFrame Extends (%ZEN.Component.component, %ZEN.SVGComponent.abstractSVGGroup) [ Deprecated, Inheritance = right, System = 3 ]
{

/// Default width of frame in parent page.
Parameter DEFAULTWIDTH = 300;

/// Default height of frame in parent page.
Parameter DEFAULTHEIGHT = 100;

/// Internal parameter.
/// This is a list of which post-compile actions this component
/// is registered for.
Parameter POSTCOMPILEACTIONS = "schema,SVG";

/// User defined style used for the svgFrame.
Property frameStyle As %ZEN.Datatype.style;

/// Edit mode of this frame.
/// This specifies how the pointer device (mouse) will interact with
/// shapes on this frame.<br/>
/// "none" - no interaction.<br/>
/// "select" - a mouse click will select a shape.<br/>
/// "drag" - the mouse can select and move the shape.<br/>
Property editMode As %ZEN.Datatype.string(VALUELIST = ",none,select,drag") [ InitialExpression = "none" ];

/// If true, then the size of the svg canvas (the backing rectangle
/// for this frame) will be automatically
/// calculated (and updated) based on its contents.<br/>
/// The minimum size of the canvas is based on the values of <property>svgWidth</property>
/// and <property>svgHeight</property>.<br/>
/// If false, the size is based on the values of <property>svgWidth</property>
/// and <property>svgHeight</property>.<br/>
/// If the <property>dragCanvas</property> is true, then this property will be ignored.
Property svgAutoSize As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true, then the user can use the pointing device (mouse) to drag
/// the canvas of this frame. This will update the values of the 
/// <property>offsetX</property> and <property>offsetY</property> properties and 
/// move the shapes on the canvas.<br/>
Property dragCanvas As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Width (in pixels) of svg canvas.
/// If not specified, then the width of the svg canvas will be
/// the width of this frame. 
Property svgWidth As %ZEN.Datatype.integer(MINVAL = 0);

/// Height (in pixels) of svg canvas.
/// If not specified, then the height of the svg canvas will be
/// the height of this frame. 
Property svgHeight As %ZEN.Datatype.integer(MINVAL = 0);

/// Internal property used to store the computed width
/// of the svg canvas when auto-size is enabled.
Property autoWidth As %ZEN.Datatype.integer(MINVAL = 0, XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// Internal property used to store the computed height
/// of the svg canvas when auto-size is enabled.
Property autoHeight As %ZEN.Datatype.integer(MINVAL = 0, XMLPROJECTION = "none", ZENSETTING = 0) [ Internal ];

/// Zoom level as a percentage (100 equals no zoom).
Property zoom As %ZEN.Datatype.float(MINVAL = 1) [ InitialExpression = 100 ];

/// This is a comma-delimited list of suggested zoom levels.<br/>
/// These values are used by the <method>zoomIn</method> and <method>zoomOut</method> methods.
Property zoomLevels As %ZEN.Datatype.csv [ InitialExpression = "10,25,50,75,100,125,150,175,200,300,400,500" ];

/// If true, then this frame will automatically zoom in and out in response to
/// mouse wheel events (FireFox only).
Property zoomWithWheel As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Client-side property that points to the enclosing SVG root element (top svg element).
Property svgRoot As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENCLIENTONLY = 1, ZENSETTING = 0);

/// Client-side property that points to the enclosing SVG group element.
Property svgGroup As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENCLIENTONLY = 1, ZENSETTING = 0);

/// Client-side property that points to SVG document embedded within this element.
Property document As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENCLIENTONLY = 1, ZENSETTING = 0);

/// Client-side property that points to SVG window object embedded within this element.
Property svgWindow As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENCLIENTONLY = 1, ZENSETTING = 0);

/// CSS style used for the background of this frame.<br/>
/// Note: this background style must include a fill value or else
/// mouse events within this frame will not work correctly.
Property backgroundStyle As %ZEN.Datatype.svgStyle [ InitialExpression = "fill: white;" ];

/// Primary selected svg component within this frame (if any).<br>
/// If there are multiple selected items, this is the most recent selection.
Property selectedItem As %ZEN.SVGComponent.svgComponent(XMLPROJECTION = "NONE", ZENSETTING = 0);

/// Set of currently selected svg components within this frame.
Property selectedItems As list Of %ZEN.SVGComponent.svgComponent(XMLPROJECTION = "NONE", ZENSETTING = 0);

/// onselectItem event handler:
/// This event is fired when the user changes the number of
/// selected items on this frame (either by selecting or unselecting an item).
/// A variable, <var>item</var>, is passed to this event handler and refers to the
/// item most recently selected or unselected.
Property onselectItem As %ZEN.Datatype.eventHandler;

/// onmoveItem event handler:
/// This event is fired when this frame is in drag mode and the user 
/// moves one or more selected items.<br>
/// Refer to the <property>selectedItems</property> property for the list of items.<br/>
/// A variable, <var>done</var>, is passed to this event handler and indicates if the
/// if the operation is completed.
Property onmoveItem As %ZEN.Datatype.eventHandler;

/// onresizeItem event handler:
/// This event is fired when this frame is in drag mode and the user 
/// resizes one or more selected items.<br>
/// Refer to the <property>selectedItems</property> property for the list of items.<br/>
/// A variable, <var>done</var>, is passed to this event handler and indicates if the
/// if the operation is completed.
Property onresizeItem As %ZEN.Datatype.eventHandler;

/// ondragCanvas event handler:
/// This event is fired as the user drags the background canvas using a pointing device.<br>
/// A variable, <var>done</var>, is passed to this event handler and indicates if the
/// if the operation is completed.
Property ondragCanvas As %ZEN.Datatype.eventHandler;

/// onmouseWheel event handler:
/// This event is fired as the user moves the wheel on their mouse over the 
/// background rectangle of this frame.<br/>
/// Currently only available in FireFox.
Property onmouseWheel As %ZEN.Datatype.eventHandler;

/// onzoom event handler:
/// This event is fired whenever the zoom level for this frame is changed.<br/>
Property onzoom As %ZEN.Datatype.eventHandler;

/// If true, all mouse operations (sizing and dragging) will be constrained
/// to lie on the "grid" defined by <property>gridX</property> and
/// <property>gridY</property>.
Property snapToGrid As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If <property>snapToGrid</property> is true, this defines the width
/// of each cell in the sizing grid.
Property gridX As %ZEN.Datatype.integer [ InitialExpression = 25 ];

/// If <property>snapToGrid</property> is true, this defines the height
/// of each cell in the sizing grid.
Property gridY As %ZEN.Datatype.integer [ InitialExpression = 25 ];

/// Optional. Specifies the name of the CSP page class (subclass of svgPage)
/// that renders the SVG content wrapper within this svgFrame.
Property svgPage As %ZEN.Datatype.className(ZENSETTING = 0);

/// User-defined list of parameters. These are passed on
/// as URL parameters to the CSP Page class that renders the SVG contents.<br/>
/// Note: In early versions of Zen, the xml attribute used to identify
/// items within this array was called "key"; it was later changed to
/// "paramName" to be consistent with other components.
Property parameters As array Of %ZEN.Auxiliary.parameter(XMLKEYNAME = "paramName", XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

/// This is the offset, along the x axis, of the coordinates of this frame
/// from its upper, left-hand corner.
Property offsetX As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// This is the offset, along the y axis, of the coordinates of this frame
/// from its upper, left-hand corner.
Property offsetY As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// Internal property used to indicate that this frame is using 
/// inline SVG.
Property inlineSVG As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
</style>
}

/// Called just after this form is added to the page.<br>
/// Make sure that the page's useSVG flag is set.
Method %OnAddToPageAfter() As %Status
{
	Set:$IsObject($G(%page)) %page.useSVG = 1
	Set:$IsObject($G(%page)) ..inlineSVG = %page.inlineSVG
	Quit $$$OK
}

Method %DrawHTML()
{
	#; set up link to SVG wrapper page
	Set query("$PAGECLASS") = $zobjclass(%page)
	Set query("$SVGCLASSES") = %page.SVGClassList
	Set query("$PARENTIDX") = ..index
	Set query("$USERSVGPACKAGES") = %page.UserSVGPackageList
	Set query("$WIDTH") = $S(..svgWidth="":"100%",1:..svgWidth)
	Set query("$HEIGHT") = $S(..svgHeight="":"100%",1:..svgHeight)
	Set query("$NAMESPACE") = $namespace

	#; pick up additional URL params from our parameter collection
	Set tKey = ""
	Do ..parameters.GetNext(.tKey)
	While (tKey '= "") {
		Set tParam = ..parameters.GetAt(tKey)
		Set query(tKey) = $$$ZENVAL(tParam.value)
		Do ..parameters.GetNext(.tKey)
	}

	If (..svgPage '= "") {
		Set url = ..svgPage _ ".cls"
	}
	Else {
		Set url = "%ZEN.SVGComponent.svgPage.cls"
	}

	#; make sure link to inner page includes CSP goodies
	#; do not use %Link as we need this link in design mode.
	Set url = ##class(%CSP.Page).Link($ZCVT(url,"O","URL"),.query)
	Set url = $ZCVT(url,"O","XML") // escape for XHTML

	//<embed class="svgFrame" style="#(..frameStyle)#" id="#(..%MakeId("frame"))#" type="image/svg+xml" src="#(url)#" height="#(..height)#" width="#(..width)#">

	#; Newer versions of IE do not calculate the size of the
	#; embedded SVG plug-in correctly, so we have to resort to
	#; wrapping a div element around the embed tag.
	#; We don't need this for FireFox, but it is simpler to
	#; have one implementation.
	#; Also, M$ engineers don't have to pass the scroll bar
	#; test, so we have to manage that as well...

	#; calculate size of div and embed elements
	Set divWidth = +..width
	Set divHeight = +..height
	Set embedWidth = $S(..svgWidth="":divWidth,1:..svgWidth)
	Set embedHeight = $S(..svgHeight="":divHeight,1:..svgHeight)
	Set overflowX = $S(divWidth=embedWidth:"hidden",1:"auto")
	Set overflowY = $S(divHeight=embedHeight:"hidden",1:"auto")

	If (..inlineSVG) {
		Set tCls = ..svgPage
		Set:tCls="" tCls = "%ZEN.SVGComponent.svgPage"
		Set svgPage = $zobjclassmethod(tCls,"%New")
		&html<
		<div class="svgFrame" id="#(..%MakeId("svgdiv"))#"
		style="overflow-x:#(overflowX)#; overflow-y:#(overflowY)#; height:#(divHeight)#px;width:#(divWidth)#px;#(..frameStyle)#">
		<div id="#(..%MakeId("frame"))#" style="overflow:hidden;height:#(embedHeight)#px;width:#(embedWidth)#px;">>
		Do svgPage.%DrawSVGDocument(.query,1)
		&html<</div></div>>

	}
	Else {
		&html<
		<div class="svgFrame" id="#(..%MakeId("svgdiv"))#"
		style="overflow-x:#(overflowX)#; overflow-y:#(overflowY)#; height:#(divHeight)#px;width:#(divWidth)#px;#(..frameStyle)#">
		<embed style="overflow:hidden;" id="#(..%MakeId("frame"))#" type="image/svg+xml" src="#(url)#" height="#(embedHeight)#" width="#(embedWidth)#"/>
		</div>>
	}
	#; do not process children of group; that happens on the client
}

/// Return the embedded SVG document object.
ClientMethod getSVGDocument() [ Language = javascript ]
{
	if (this.inlineSVG) {
		return document;
	}
	var embed = this.findElement("frame");
	if (embed) {
		return embed.getSVGDocument();
	}
	return null;
}

/// Notification that the embedded SVG page is loaded.
ClientMethod svgLoadHandler(win) [ Language = javascript ]
{

	// set up client-side references to svg document etc
	var doc = this.getSVGDocument();
	// trap for occasional IE 11 Permission denied accessing this.document
	try {if (this.document==doc) return;} catch (ex) {}
	this.document = doc;
	this.svgWindow = win;

	// now render our group and our children
	// note that zenCanvas will be the enclosing group for this
	// topmost group.
	this.renderSVG(this.document,null);

	// define event handlers for the background
	this.svgBackground.addEventListener('mousedown',new Function('evt','return zenPage.getComponent('+this.index+').mousedownHandler(evt);'),false);

	// mouse wheel (fireFox only)
	this.svgRoot.addEventListener('DOMMouseScroll', new Function('evt','return zenPage.getComponent('+this.index+').mousewheelHandler(evt);'), false);

	// we'll set these when a move/drag operation starts
	this._mmHandler = new Function('evt','return zenPage.getComponent('+this.index+').mousemoveHandler(evt);');
	this._muHandler = new Function('evt','return zenPage.getComponent('+this.index+').mouseupHandler(evt);');

	// initialize set of client-only properties used
	// for mouse operations
	this._mouseTarget = null;
	this._currOperation = null;
	this._isMoved = false;
	this._deltaX = 0;
	this._deltaY = 0;
	this._startX = 0;
	this._startY = 0;

	// force update of edit mode
	this._runtimeEditMode = 'none';
	var mode = this.editMode;
	this.editMode = '';
	this.setEditMode(mode);

	if (this.zoom != 100) {
		this.setProperty('zoom',this.zoom);
	}
}

/// Set the size of the bounding box of this group.<br/>
/// This is called by the layout manager.
/// Applications should not call this directly.
ClientMethod setBoundingBox(width, height) [ Internal, Language = javascript ]
{
	// if we are in autosize mode, set the size of the svg canvas
	if (this.svgAutoSize) {
		width = parseInt(width,10);
		height = parseInt(height,10);

		var minw = (this.svgWidth == '') ? 0 : this.svgWidth;
		var minh = (this.svgHeight == '') ? 0 : this.svgHeight;

		// remember this computed size
		this.autoWidth = (width > minw) ? width : minw;
		this.autoHeight = (height > minh) ? height : minh;

		// apply new size
		this.setFrameSize(this.width,this.height);
	}
}

/// Set the edit mode of the frame.
ClientMethod setEditMode(mode) [ Language = javascript ]
{
	if (zenPage.designMode) {
		// force edit mode
		this._runtimeEditMode = 'drag';
	}
	else {
		this._runtimeEditMode = mode;
		if (mode == this.editMode) {
			return;
		}
	}

	this.editMode = mode;

	switch (this._runtimeEditMode) {
	case 'none':
		this.setOverlayMode(0);
		break;
	case 'select':
		this.setOverlayMode(1);
		this.selectItem(null);
		break;
	case 'drag':
		this.setOverlayMode(1);
		this.selectItem(null);
		break;
	default:
		alert('setEditMode: unknown edit mode:\n' + this._runtimeEditMode);
		break;
	}
}

/// Select the specified item.<br>
/// <var>item</var> must be a component within this frame.<br>
/// If <var>add</var> is true, add (or remove if already selected) 
/// the item to the set of selected items, otherwise select 
/// only the item.<br>
/// If <var>item</var> is null, unselect all items.
ClientMethod selectItem(item, add) [ Language = javascript ]
{
	var itemreq = item;
	
	if (add) {
		// if selected, unselect this item.
		for (var i = 0; i < this.selectedItems.length; i++) {
			if (this.selectedItems[i] == item) {
				this.selectedItems.splice(i,1);
				item.setOverlayMode(this._runtimeEditMode=='none' ? 0 : 1);
				item = null;
				break;
			}
		}
	}
	else {
		// test for reselect of current item
		if (item && this.isSelected(item)) {
			return;
		}
	}

	if (!add) {
		// unselect previous items
		for (var i = 0; i < this.selectedItems.length; i++) {
			var old = this.selectedItems[i];
			this.selectedItems[i] = null;

			// unselect
			if (old) {
				old.setOverlayMode(this._runtimeEditMode=='none' ? 0 : 1);
			}
		}
		
		// reset list
		this.selectedItems.length = 0;
	}

	this.selectedItem = '';

	// update new item
	if (item) {
		this.selectedItem = item;
		// add new item to list
		this.selectedItems[this.selectedItems.length] = item;
		item.setOverlayMode(this._runtimeEditMode=='drag' ? 3 : 2);
	}

	// if design mode, notify designer
	if (zenPage.designMode) {
		alert('selectItem: ' + top.zenPage.selectComponent);
		//zenPage.selectComponent(zenPage,this,event);
	}

	// callback method (for subclasses)
	var notify = true;
	if (this.selectItemHandler) {
		notify = this.selectItemHandler(itemreq,add);
	}

	// raise event
	if (notify) {
		zenInvokeCallbackMethod(this.onselectItem,this,'onselectItem','item',itemreq);
	}
}

/// Notification that an item has been selected.
/// This can be implemented by a subclass.
/// If this method is defined and returns false, the onselectItem
/// callback will not be fired.
ClientMethod selectItemHandler(item, add) [ Abstract, Language = javascript ]
{
}

/// Test if given item is selected.
ClientMethod isSelected(item) [ Language = javascript ]
{
	if (null == item) {
		return false;
	}
	for (var i = 0; i < this.selectedItems.length; i++) {
		if (this.selectedItems[i] == item) {
			return true;
		}
	}
	return false;
}

/// Return the current selected item within this frame.
/// If no item is selected, return null. If more than one item
/// is selected, return the primary selection (last item selected).
ClientMethod getSelectedItem() [ Language = javascript ]
{
	return ('' == this.selectedItem) ? null : this.selectedItem;
}

/// Return the set of currently selected items within this frame
/// as an array of components.
ClientMethod getSelectedItems() [ Language = javascript ]
{
	return this.selectedItems;
}

/// Return true if shapes can be dragged on this frame.
ClientMethod canDragShapes() [ Language = javascript ]
{
	return ('drag' == this._runtimeEditMode);
}

/// Mouse wheel event handler for this frame.
ClientMethod mousewheelHandler(evt) [ Language = javascript ]
{
	evt.stopPropagation();
	evt.preventDefault()

	var delta = 0;
	var cx = evt.clientX;
	var cy = evt.clientY;
	if (!evt) {
		evt = window.event;
	}
	if (evt.wheelDelta) {
		delta = evt.wheelDelta/120;
		if (window.opera) {	delta = -delta; }
	}
	else if (evt.detail) {
		delta = -evt.detail/3;
		cx = evt.clientX /15;
		cy = evt.clientY /15;
	}
	
	if (this.zoomWithWheel) {
		if (delta < 0) { this.zoomIn(cx,cy); }
		else if (delta > 0) { this.zoomOut(cx,cy); }
	}

	// raise event
	zenInvokeCallbackMethod(this.onmouseWheel,this,'onmouseWheel','delta',delta);
}

/// Mouse down handler for this frame.
ClientMethod mousedownHandler(evt) [ Language = javascript ]
{
	if (evt.target == this.svgBackground) {
		// click on canvas: unselect all items
		this.selectItem(null);
		if (this.dragCanvas) {
			this.startDragCanvas(evt);
		}
	}
}

/// Start of move shape(s) operation.
ClientMethod startMove(evt, shape) [ Language = javascript ]
{
	// start move operation for selected item(s)
	this._mouseTarget = shape;
	this._currOperation = 'move';
	this._isMoved = false;
	
	var currZoom = this.zoom;
	
	// get curr position of shape (relative to canvas)
	var size = shape.getSizeAbsolute();
	
	// figure out offset of mouse from shape...
	this._deltaX = size.x - (evt.clientX * (100/currZoom));
	this._deltaY = size.y - (evt.clientY * (100/currZoom));
	
	// remember start of operation
	this._startX = size.x;
	this._startY = size.y;

	// turn on mouse handlers
	this.svgRoot.addEventListener('mousemove',this._mmHandler,false);
	this.svgRoot.addEventListener('mouseup',this._muHandler,false);
}

/// Start of drag canvas operation.
ClientMethod startDragCanvas(evt) [ Language = javascript ]
{
	// start drag canvas operation
	this._currOperation = 'dragCanvas';
	this._isMoved = false;
	
	var currZoom = this.zoom;
	
	// figure out offset of mouse from shape...
	this._deltaX = this.offsetX - (evt.clientX * (100/currZoom));
	this._deltaY = this.offsetY - (evt.clientY * (100/currZoom));
	
	// remember start of operation
	this._startX = this.offsetX;
	this._startY = this.offsetY;

	// turn on mouse handlers
	this.svgRoot.addEventListener('mousemove',this._mmHandler,false);
	this.svgRoot.addEventListener('mouseup',this._muHandler,false);
}

/// Start of resize operation.
ClientMethod startResize(evt, shape, which) [ Language = javascript ]
{
	// start resize operation for selected item(s)
	this._mouseTarget = shape;
	this._currOperation = 'resize';
	this._sizingHandle = which;
	this._isMoved = false;

	var currZoom = this.zoom;
	
	// get curr position of shape (relative to canvas)
	var size = shape.getSizeAbsolute();
	
	// figure out offset of mouse from shape...
	this._deltaX = size.x - (evt.clientX * (100/currZoom));
	this._deltaY = size.y - (evt.clientY * (100/currZoom));
	
	// remember start of operation
	this._startX = size.x;
	this._startY = size.y;

	// turn on mouse handlers
	this.svgRoot.addEventListener('mousemove',this._mmHandler,false);
	this.svgRoot.addEventListener('mouseup',this._muHandler,false);
}

/// Mouse move handler for frame.
ClientMethod mousemoveHandler(evt) [ Language = javascript ]
{
	var currZoom = this.zoom;
	
	var oldEvent = zenEvent;
	zenEvent = evt ? evt : window.event;

	switch (this._currOperation) {
	case 'move':
		if (this._mouseTarget) {
			// move handles for selected shapes
			var size = this._mouseTarget.getSizeAbsolute();
			var dx = ((evt.clientX * (100/currZoom)) + this._deltaX) - size.x;
			var dy = ((evt.clientY * (100/currZoom)) + this._deltaY) - size.y;

			// test for minimum movement
			if (dx*dx > 4 || dy*dy > 4) {
				if (this.snapToGrid && this.gridX > 0 && this.gridY > 0) {
					dx = Math.floor(dx / this.gridX) * this.gridX;
					dy = Math.floor(dy / this.gridY) * this.gridY;
				}

				this._isMoved = true;
				for (var i = 0; i < this.selectedItems.length; i++) {
					var item = this.selectedItems[i];
					var size = item.getSizeAbsolute();
					item.updateOverlay(size.x + dx,size.y + dy,size.width,size.height);
				}
				zenInvokeCallbackMethod(this.onmoveItem,this,'onmoveItem','done',false);
			}
		}
		break;
	case 'dragCanvas':
		// move handles for selected shapes
		var dx = ((evt.clientX * (100/currZoom)) + this._deltaX) - this.offsetX;
		var dy = ((evt.clientY * (100/currZoom)) + this._deltaY) - this.offsetY;

		// test for minimum movement (no snap to grid for drag)
		if (dx*dx > 4 || dy*dy > 4) {
			this._isMoved = true;
			this.setOffsets(this.offsetX + dx,this.offsetY + dy);
			zenInvokeCallbackMethod(this.ondragCanvas,this,'ondragCanvas','done',false);
		}
		break;

	case 'resize':
		if (this._mouseTarget) {
			// move handles for selected shapes
			var size = this._mouseTarget.getSizeAbsolute();
			var dx = ((evt.clientX * (100/currZoom)) + this._deltaX) - size.x;
			var dy = ((evt.clientY * (100/currZoom)) + this._deltaY) - size.y;

			// test for minimum movement
			var x,y,w,h;
			if (dx*dx > 4 || dy*dy > 4) {
				this._isMoved = true;
				if (this.snapToGrid && this.gridX > 0 && this.gridY > 0) {
					dx = Math.floor(dx / this.gridX) * this.gridX;
					dy = Math.floor(dy / this.gridY) * this.gridY;
				}
				for (var i = 0; i < this.selectedItems.length; i++) {
					var item = this.selectedItems[i];
					var size = item.getSizeAbsolute();
					switch(this._sizingHandle) {
					case 'ne':
						w = size.width + dx;
						h = size.height - dy;
						x = size.x;
						y = (h > 0) ? size.y + dy : size.y + size.height;
						break;
					case 'nw':
						w = size.width - dx;
						h = size.height - dy;
						x = (w > 0) ? size.x + dx : size.x + size.width;
						y = (h > 0) ? size.y + dy : size.y + size.height;
						break;
					case 'se':
						w = size.width + dx;
						h = size.height + dy;
						x = size.x;
						y = size.y;
						break;
					case 'sw':
						w = size.width - dx;
						h = size.height + dy;
						x = (w > 0) ? size.x + dx : size.x + size.width;
						y = size.y;
						break;
					}
	
					// test for min size
					w = (w < 0) ? 0 : w;
					h = (h < 0) ? 0 : h;
					item.updateOverlay(x,y,w,h);
				}
				zenInvokeCallbackMethod(this.onresizeItem,this,'onresizeItem','done',false);
			}
		}
		break;

	default:
		break;
	}
	zenEvent = oldEvent;
}

/// Mouse up handler for frame.
ClientMethod mouseupHandler(evt) [ Language = javascript ]
{
	var currZoom = this.zoom;

	var oldEvent = zenEvent;
	zenEvent = evt ? evt : window.event;

	switch (this._currOperation) {
	case 'move':
		if (this._isMoved && this._mouseTarget) {

			// move selected shapes
			var size = this._mouseTarget.getSizeAbsolute();
			var dx = ((evt.clientX * (100/currZoom)) + this._deltaX) - size.x;
			var dy = ((evt.clientY * (100/currZoom)) + this._deltaY) - size.y;

			if (this.snapToGrid && this.gridX > 0 && this.gridY > 0) {
				dx = Math.floor(dx / this.gridX) * this.gridX;
				dy = Math.floor(dy / this.gridY) * this.gridY;
			}
			for (var i = 0; i < this.selectedItems.length; i++) {
				var item = this.selectedItems[i];
				this.moveItem(item,dx,dy);
			}
			zenInvokeCallbackMethod(this.onmoveItem,this,'onmoveItem','done',true);
		}
 		break;
	case 'dragCanvas':
		if (this._isMoved) {
			var dx = ((evt.clientX * (100/currZoom)) + this._deltaX) - this.offsetX;
			var dy = ((evt.clientY * (100/currZoom)) + this._deltaY) - this.offsetY;
			this.setOffsets(this.offsetX + dx,this.offsetY + dy);
			zenInvokeCallbackMethod(this.ondragCanvas,this,'ondragCanvas','done',true);
		}
		break;

	case 'resize':
		if (this._isMoved && this._mouseTarget) {
			// resize selected shapes
			var size = this._mouseTarget.getSizeAbsolute();
			var dx = ((evt.clientX * (100/currZoom)) + this._deltaX) - size.x;
			var dy = ((evt.clientY * (100/currZoom)) + this._deltaY) - size.y;

			if (this.snapToGrid && this.gridX > 0 && this.gridY > 0) {
				dx = Math.floor(dx / this.gridX) * this.gridX;
				dy = Math.floor(dy / this.gridY) * this.gridY;
			}
			var x,y,w,h;
			for (var i = 0; i < this.selectedItems.length; i++) {
				var item = this.selectedItems[i];
				var size = item.getSizeAbsolute();
				switch(this._sizingHandle) {
				case 'ne':
					w = size.width + dx;
					h = size.height - dy;
					x = 0;
					y = (h > 0) ? dy : size.height;
					break;
				case 'nw':
					w = size.width - dx;
					h = size.height - dy;
					x = (w > 0) ? dx : size.width;
					y = (h > 0) ? dy : size.height;
					break;
				case 'se':
					w = size.width + dx;
					h = size.height + dy;
					x = 0;
					y = 0;
					break;
				case 'sw':
					w = size.width - dx;
					h = size.height + dy;
					x = (w > 0) ? dx : size.width;
					y = 0;
					break;
				}

				// test for min size
				w = (w < 0) ? 0 : w;
				h = (h < 0) ? 0 : h;

				// adjust size and position
				item.setProperty('width',w);
				item.setProperty('height',h);
				this.moveItem(item,x,y);
			}
			zenInvokeCallbackMethod(this.onresizeItem,this,'onresizeItem','done',true);
		}
 		break;
	}
	zenEvent = oldEvent;

	this._isMoved = false;
	this._mouseTarget = null;
	this._currOperation = null;
	this._sizingHandle = null;

	// turn off mouse events
	this.svgRoot.removeEventListener('mousemove',this._mmHandler,false);
	this.svgRoot.removeEventListener('mouseup',this._muHandler,false);
}

/// Move the given component to a new position (depending on its parent's layout options).
ClientMethod moveItem(item, dx, dy) [ Language = javascript ]
{
	if (!item) return;

	// move item
	item.setPosition(parseFloat(item.x) + parseFloat(dx), parseFloat(item.y) + parseFloat(dy));

	// if item's parent defines layout, adjust accordingly
	var group = item.parent;
	if (group) {
		switch(group.layout) {
		case 'vertical':
			// sort members of group by y position
			if (group.children.length > 1) {
				group.children.sort(function(a,b) { return a.y - b.y; });
				group.layoutChildren();
			}
			break;
		case 'horizontal':
			// sort members of group by x position
			if (group.children.length > 1) {
				group.children.sort(function(a,b) { return a.x - b.x; });
				group.layoutChildren();
			}
			break;
		case 'flow':
			// sort members of group by x and y position
			if (group.children.length > 1) {
				group.children.sort(function(a,b) { return a.x - b.x; });
				group.children.sort(function(a,b) { return a.y - b.y; });
				group.layoutChildren();
			}
			break;
		default:
			group.layoutChildren();
			break;
		}
	}

	// update overlay for item
	var size = item.getSizeAbsolute();
	item.updateOverlay(size.x,size.y,size.width,size.height);
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'width':
		this.setFrameSize(value,this.height);
		break;
	case 'height':
		this.setFrameSize(this.width,value);
		break;

	case 'svgHeight':
	case 'svgWidth':
		value = (''==value) ? '' : parseFloat(value);
		this[property] = value;
		this.setFrameSize(this.width,this.height);
		break;

	case 'layout':
		if (this.layout != value) {
			this.layout = value;
			this.layoutChildren();
		}
		break;

	case 'backgroundStyle':
		this.backgroundStyle = value;
		if (this.svgBackground) {
			this.svgBackground.setAttribute('style',this.backgroundStyle);
		}
		break;

	case 'editMode':
		this.setEditMode(value);
		break;

	case 'zoomLevels':
		this.zoomLevels = value;
		break;

	case 'snapToGrid':
		value = value ? true : false;
		this[property] = value;
		break;

	case 'gridX':
	case 'gridY':
		value = parseInt(value,10);
		this[property] = value;
		break;
		
	case 'offsetX':
		value = parseFloat(value);
		this.setOffsets(value,this.offsetY);
		break;

	case 'offsetY':
		value = parseFloat(value);
		this.setOffsets(this.offsetX,value);
		break;

	case 'svgAutoSize':
		value = value ? true : false;
		this.svgAutoSize = value;
		this.setFrameSize(this.width,this.height);
		break;

	case 'frameStyle':
		this.frameStyle = value;
		var div = this.findElement('svgdiv');
		if (div) {
			div.style.cssText = this.frameStyle;
		}
		break;

	case 'zoomWithWheel':
	case 'dragCanvas':
		value = value ? true : false;
		this[property] = value;
		break;

	case 'zoom':
		this.setZoom(value);
		break;

	default:
		// dispatch (always return true to avoid refresh)
		this.invokeSuper('setProperty',arguments);
		return true;
	}
	return true;
}

/// Internal method.<br/>
/// Set the width and height of this frame.
/// Applications should use setProperty('width') or setProperty('height').<br/>
/// This method adjusts the size of the various coordinate-defining components
/// that make up this frame: the div element used to house the frame on
/// the web page; the embed element that contains the svg document; the top-level
/// svg element, and the background (canvas) rectangle.
ClientMethod setFrameSize(w, h) [ Internal, Language = javascript ]
{
	try {
		if (this.inlineSVG) {
			// !!!
			return;
		}
		
		this.width = parseInt(w,10);
		this.height = parseInt(h,10);

		var div = this.findElement('svgdiv');
		var embed = this.findElement('frame');

		// JMD794 -- avoid i.e. trouble
		if (this.width <= 0) {
			this.width = 1;
		}
		if (this.height <= 0) {
			this.height = 1;
		}

		// find canvas size, scaled and unscaled
		var cwid, chgt, cwidScaled, chgtScaled;
		if (this.svgAutoSize) {
			// use computed size, with minimum specified by svgWidth/Height
			cwid = this.autoWidth;
			chgt = this.autoHeight;
			if ('' != this.svgWidth) {
				cwid = (this.autoWidth < parseInt(this.svgWidth,10)) ? parseInt(this.svgWidth,10) : this.autoWidth;
			}
			if ('' != this.svgHeight) {
				chgt = (this.autoHeight < parseInt(this.svgHeight,10)) ? parseInt(this.svgHeight,10) : this.autoHeight;
			}
		}
		else {
			// use svgSize, default to frame size
			cwid = (''==this.svgWidth) ? this.width : parseInt(this.svgWidth,10);
			chgt = (''==this.svgHeight) ? this.height : parseInt(this.svgHeight,10);
		}

		// scaled size
		var cwidScaled = cwid * (this.zoom / 100);
		var chgtScaled = chgt * (this.zoom / 100);

		var ovx = 'auto';
		var ovy = 'auto';
		var rwid = cwid;
		var rhgt = chgt;

		// does canvas overflow the frame?
		// don't let it be smaller than the frame
		if (this.width >= cwidScaled) {
			ovx = 'hidden';
			cwidScaled = this.width;
			rwid = this.width * (100 / this.zoom);
		}
		if (this.height >= chgtScaled) {
			ovy = 'hidden';
			chgtScaled = this.height;
			rhgt = this.height * (100 / this.zoom);
		}

		// apply html sizes
		if (div && embed) {
			div.style.width = this.width + 'px';
			div.style.overflowX = ovx;
			embed.width = cwidScaled;
			div.style.height = this.height + 'px';
			div.style.overflowY = ovy;
			embed.height = chgtScaled;
		}

		// set size of root svg element
		if (this.svgRoot) {
			this.svgRoot.setAttribute('width',cwidScaled);
			this.svgRoot.setAttribute('height',chgtScaled);
		}

		// background rect
		if (this.svgBackground) {
			var rect = this.svgBackground;
			rect.setAttribute('width',rwid);
			rect.setAttribute('height',rhgt);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// Internal method.
/// Update transformation applied to the canvas scaling group.
ClientMethod updateScalingGroup() [ Internal, Language = javascript ]
{
	// update background rect
	if (this.svgBackground) {
		var rect = this.svgBackground;
		rect.setAttribute('x',-this.offsetX);
		rect.setAttribute('y',-this.offsetY);
	}

	if (this.document) {
		var scale = this.document.getElementById('zenScalingGroup');
		if (scale) {
			var xform = '';
			if (this.zoom != 100) {
				xform = xform + ' scale(' + parseFloat(this.zoom)/100 + ')';
			}
			if (this.offsetX != 0 || this.offsetY != 0) {
				xform = xform + ' translate(' + parseFloat(this.offsetX) + ', ' + parseFloat(this.offsetY) + ')';
			}
			scale.setAttribute('transform',xform);
		}
	}
}

/// Set the x and y offsets for this frame.
/// This specifies how far the upper left corner of the frame is translated.
ClientMethod setOffsets(x, y) [ Language = javascript ]
{
	this.offsetX = parseFloat(x);
	this.offsetY = parseFloat(y);
	this.updateScalingGroup();
}

/// Set the zoom level of this frame to given percentage value.
ClientMethod setZoom(value) [ Language = javascript ]
{
	value = parseFloat(value);
	value = (value < 1) ? 1 : value;
	this.zoom = value;
	zenInvokeCallbackMethod(this.onzoom,this,'onzoom','zoom',this.zoom);
	this.updateScalingGroup();
	this.layoutChildren();
	this.setFrameSize(this.width,this.height);
}

/// Set the zoom level for this frame to the next higher value 
/// (as compared with the current level)
/// in the <property>zoomLevels</property> list.<br/>
/// <var>x</var> and <var>y</var>, if defined, are the center point for
/// the zoom. If not defined, the center of the frame is used.
ClientMethod zoomIn(x, y) [ Language = javascript ]
{
	x = (null == x) ? this.width / 2 : x;
	y = (null == y) ? this.height / 2 : y;
	
	var newZoom = -1;
	var currZoom = parseFloat(this.zoom);
	var zooms = this.zoomLevels.split(',');
	for (var z = 0; z < zooms.length; z++) {
		if (parseFloat(zooms[z]) > currZoom) {
			newZoom = parseFloat(zooms[z]);
			this._zoomIndex = z;
			break;
		}
	}
	if (newZoom == -1) {
		newZoom = parseFloat(zooms[zooms.length-1]);
		this._zoomIndex = zooms.length-1;
	}
	if (this.dragCanvas) {
		var deltaX = (x * (100/this.zoom)) - (x * (100/newZoom));
		var deltaY = (y * (100/this.zoom)) - (y * (100/newZoom));
		this.offsetX = parseFloat(this.offsetX) - parseFloat(deltaX);
		this.offsetY = parseFloat(this.offsetY) - parseFloat(deltaY);
	}

	this.setZoom(newZoom);
}

/// Set the zoom level for this frame to the next lower value 
/// (as compared with the current level)
/// in the <property>zoomLevels</property> list.<br/>
/// <var>x</var> and <var>y</var>, if defined, are the center point for
/// the zoom. If not defined, the center of the frame is used.
ClientMethod zoomOut(x, y) [ Language = javascript ]
{
	x = (null == x) ? this.width / 2 : x;
	y = (null == y) ? this.height / 2 : y;

	var newZoom = -1;
	var currZoom = parseFloat(this.zoom);
	var zooms = this.zoomLevels.split(',');
	for (var z = zooms.length - 1; z >= 0; z--) {
		if (parseFloat(zooms[z]) < currZoom) {
			newZoom = parseFloat(zooms[z]);
			this._zoomIndex = z;
			break;
		}
	}
	if (newZoom == -1) {
		newZoom = parseFloat(zooms[0]);
		this._zoomIndex = 0;
	}

	if (this.dragCanvas) {
		var deltaX = (x * (100/this.zoom)) - (x * (100/newZoom));
		var deltaY = (y * (100/this.zoom)) - (y * (100/newZoom));
		this.offsetX = parseFloat(this.offsetX) - parseFloat(deltaX);
		this.offsetY = parseFloat(this.offsetY) - parseFloat(deltaY);
	}

	this.setZoom(newZoom);
}

/// This will zoom this canvas to the (0-based) zoom index (i.e., entry in the <property>zoomLevels</property> array)
/// specified by <var>idx</var>.<br/>
/// <var>x</var> and <var>y</var>, if defined, are the center point for
/// the zoom. If not defined, the center of the frame is used.
ClientMethod setZoomIndex(idx, x, y) [ Language = javascript ]
{
	x = (null == x) ? this.width / 2 : x;
	y = (null == y) ? this.height / 2 : y;

	var zooms = this.zoomLevels.split(',');
	idx = parseInt(idx,10);
	idx = (idx < 0) ? 0 : idx;
	idx = (idx >= zooms.length) ? zooms.length - 1: idx;
	this._zoomIndex = idx;

	newZoom = parseFloat(zooms[idx]);
	if (this.dragCanvas) {
		var deltaX = (x * (100/this.zoom)) - (x * (100/newZoom));
		var deltaY = (y * (100/this.zoom)) - (y * (100/newZoom));
		this.offsetX = parseFloat(this.offsetX) - parseFloat(deltaX);
		this.offsetY = parseFloat(this.offsetY) - parseFloat(deltaY);
	}
	this.setZoom(newZoom);
}

/// Return current zoom index of this frame.
ClientMethod getZoomIndex(x) [ Language = javascript ]
{
	if (null == this._zoomIndex) {
		var currZoom = parseFloat(this.zoom);
		var zooms = this.zoomLevels.split(',');
		this._zoomIndex = zooms.length-1;
		for (var z = 0; z < zooms.length; z++) {
			if (parseFloat(zooms[z]) > currZoom) {
				this._zoomIndex = z;
				break;
			}
		}
	}
	
	return this._zoomIndex;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	if (this.inlineSVG) {
		// create inline svg components
		this.svgLoadHandler(self);
	}
}

}
