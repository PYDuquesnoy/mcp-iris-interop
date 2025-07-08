/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// SVG Container component.
/// A group is used to contain and layout a set of child SVG components.
Class %ZEN.SVGComponent.svgGroup Extends (svgComponent, abstractSVGGroup) [ Deprecated, Inheritance = right, System = 3 ]
{

/// Set the size of the bounding box of this group.
/// Applications should not call this directly.
ClientMethod setBoundingBox(width, height) [ Language = javascript ]
{
	width = parseInt(width,10);
	height = parseInt(height,10);

	if (width != this.width || height != this.height) {
		this.setSize(width,height);
		this.parent.layoutChildren();
	}
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'layout':
		if (this.layout != value) {
			this.layout = value;
			this.layoutChildren();
		}
		break;

	case 'width':
	case 'height':
		// swallow: this is calculated from size of children
		break;

	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
