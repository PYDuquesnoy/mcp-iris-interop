/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

/// Base implementation of SVG group behavior.
Class %ZEN.SVGComponent.abstractSVGGroup Extends %XML.Adaptor [ Abstract, Deprecated, PropertyClass = %ZEN.componentParameters, System = 3 ]
{

/// XML namespace used for library components.
Parameter NAMESPACE = "http://www.intersystems.com/zen";

/// Subclasses can set this to change default layout for a group.
Parameter DEFAULTLAYOUT As STRING;

/// Set of svg components within this group.
Property children As list Of svgComponent(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE", ZENSETTING = 0);

/// Specifies how components within this group should be layed out.<br/>
/// "none" indicates that no layout is provided.<br/>
/// "vertical" indicates that components within this group are layed out vertically.<br/>
/// "horizontal" indicates that components within this group are layed out horizontally.<br/>
/// "flow" indicates that components within this group are placed within multiple rows. 
/// Items are placed horizontally until the width of the container is exceeded and then components are placed on the next row.<br/>
Property layout As %ZEN.Datatype.string(VALUELIST = ",vertical,horizontal,flow,none") [ InitialExpression = {..#DEFAULTLAYOUT} ];

/// If true, this group and its children are disabled.
Property disabled As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Internal property.<br/>
/// If true, this group was only partially serialized on the client
/// (it is the ancestor of the object being serialized) 
/// and we should ignore changes made to the children array when
/// shipping changes back to the client.
Property %partial As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0, Internal ];

/// Draw an enclosing SVG group and then render the SVG children of the group.
ClientMethod renderSVG(document, parent) [ Final, Language = javascript ]
{
	this.document = document;

	// create enclosing group
	if (null == parent) {
		// we are the top group;
		this.svgRoot = this.document.getElementById('zenRoot');
		this.svgGroup = this.document.getElementById('zenCanvas');

		// insert the background rectangle (this lets us set a background style
		// and catch mouse events in a portable way

		var rect = this.document.createElementNS(SVGNS,'rect');
		rect.setAttribute('id','zenBackground');
		rect.setAttribute('x',0);
		rect.setAttribute('y',0);
		rect.setAttribute('width','100%');
		rect.setAttribute('height','100%');
		if (null != this.backgroundStyle) {
			rect.setAttribute('style',this.backgroundStyle);
		}

		// add to our group (as first element)
		this.svgGroup.insertBefore(rect, this.svgGroup.firstChild);
		this.svgBackground = rect;
	}
	else {
		this.createEnclosingGroup(parent);
	}

	// draw children
	for (var n = 0; n < this.children.length; n++) {
		var child = this.children[n];
		child.renderSVG(this.document,this.svgGroup);
	}

	this.layoutChildren();
}

/// Apply layout to the child components within this group.
/// Updates the value of width and height for this group;
ClientMethod layoutChildren() [ Language = javascript ]
{
	var height = 0;
	var width = 0;

	switch(this.layout) {
	case 'vertical':
		var x=0,y=0;
		for (var n = 0; n < this.children.length; n++) {
			var child = this.children[n];
			if ('relative' == child.position && !child.hidden) {
				child.setPosition(x,y);
				if (child.layoutChildren) {
					// group: layout will update size
					child.layoutChildren();
				}
				y += parseInt(child.height,10);
				width = (parseInt(child.width,10) > width) ? parseInt(child.width,10) : width;
			}
		}
		height = y;
		break;
	case 'horizontal':
		var x=0,y=0;
		for (var n = 0; n < this.children.length; n++) {
			var child = this.children[n];
			if ('relative' == child.position && !child.hidden) {
				child.setPosition(x,y);
				if (child.layoutChildren) {
					// group: layout will update size
					child.layoutChildren();
				}
				x += parseInt(child.width,10);
				height = (parseInt(child.height,10) > height) ? parseInt(child.height,10) : height;
			}
		}
		width = x;
		break;
	case 'flow':
		var flowWidth = this.width;
		var x=0,y=0;
		for (var n = 0; n < this.children.length; n++) {
			var child = this.children[n];
			if ('relative' == child.position && !child.hidden) {
				child.setPosition(x,y);
				if (child.layoutChildren) {
					// group: layout will update size
					child.layoutChildren();
				}
				var cw = parseInt(child.width,10);
	
				// if this shape falls over the edge, then move to the next row
				if (x > 0 && (x+cw) > flowWidth) {
					x = 0;
					y = height;
					child.setPosition(x,y);
					if (child.layoutChildren) {
						child.layoutChildren();
					}
					cw = parseInt(child.width,10);
				}
				x += cw;
				height = ((y + parseInt(child.height,10)) > height) ? (y+parseInt(child.height,10)) : height;
				width = (x > width) ? x : width;
			}
		}
		break;

	case 'none':
	default:
		// free-form layout: calculate our size
		for (var n = 0; n < this.children.length; n++) {
			var child = this.children[n];
			if ('relative' == child.position && !child.hidden) {
				// make sure handles move
				child.setPosition(child.x,child.y);
				if (child.layoutChildren) {
					// group: layout will update size
					child.layoutChildren();
				}
				width = ((parseInt(child.x,10)+parseInt(child.width,10)) > width) ? parseInt(child.width,10)+parseInt(child.x,10) : width;
				height = ((parseInt(child.y,10)+parseInt(child.height,10)) > height) ? parseInt(child.height,10)+parseInt(child.y,10) : height;
			}
		}
		break;
	}
	
	// update our bounding box
	if (this.setBoundingBox) {
		this.setBoundingBox(width, height);
	}
}

/// Set overlay mode for each child of this group.
ClientMethod setOverlayMode(mode) [ Language = javascript ]
{
	this.overlayMode = mode;

	for (var n = 0; n < this.children.length; n++) {
		this.children[n].setOverlayMode(mode);
	}
}

/// Add a child component <var>pComponent</var> to this group.
/// This is called when the server component tree is being created.
/// This also adds <var>pComponent</var> to the page that this group 
/// belongs to; this group must be added to a page before adding any child
/// components to it. In addition, the <property>id</property> property
/// of the component <em>must</em> be set before calling this method.
Method %AddChild(pComponent As %ZEN.Component.object)
{
	#; add component to page
	If $IsObject(%page) {
		Do %page.%AddComponent(pComponent)
	}

	#; link component to composite, if possible
	If $IsObject($G(%composite)) {
		Set pComponent.composite = %composite
	}

	#; add component to our list of children
	Do ..children.Insert(pComponent)
	Set pComponent.parent = ##this
}

/// Remove child component <var>pComponent</var> from this group.
/// Returns true if the component was found and removed.
Method %RemoveChild(pComponent As %ZEN.Component.object) As %Boolean
{
	#; find child in our list of children
	Set tFound = 0
	For n=1:1:..children.Count() {
		If (pComponent = ..children.GetAt(n)) {
			#; remove component from our list of children
			Do ..children.RemoveAt(n)
			Set tFound = 1
			Quit
		}
	}

	#; this is not our child
	Quit:'tFound 0

	#; remove component from the page
	If $IsObject(..%page) {
		Do ..%page.%RemoveComponent(pComponent)
	}

	#; clear our parent
	Set pComponent.parent = ""
}

/// Client-side method.<br>
/// Dynamically add a component to this group on the client.
ClientMethod addChild(component) [ Language = javascript ]
{
	zenASSERT(component && zenIsComponent(component),'Invalid component',arguments);
	
	if (!component.isOfType('svgComponent')) {
		alert('Only SVG components can be added to svg groups');
		return;
	}

	this.children[this.children.length] = component;
	component.parent = this;
	
	// render the new component (if we are rendered)
	if (this.document && this.svgGroup) {
		component.renderSVG(this.document,this.svgGroup);
	}
}

/// Client-side method.<br>
/// Dynamically remove a component from this group on the client.
ClientMethod removeChild(component) [ Language = javascript ]
{
	// get the page to do the work
	zenPage.deleteComponent(component);
}

/// Apply the given value to the specified property for
/// this group and all of its children.<br>
/// Note that this will not work for 'disabled'; for that
/// use <method>setProperty</method>.
ClientMethod setPropertyAll(property, value, value2) [ Language = javascript ]
{
	if ('disabled' == property) return;
	
	this.setProperty(property, value, value2);

	// pass to all of our children
	for (var n = 0; n < this.children.length; n++) {
		var child = this.children[n];
		if (child.setPropertyAll) {
			child.setPropertyAll(property,value,value2);
		}
		else {
			child.setProperty(property,value,value2);
		}
	}
}

}
