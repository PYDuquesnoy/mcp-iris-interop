/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a specialized type of <class>%ZEN.SVGComponent.svgFrame</class> that can
/// contain a set of <class>sprite</class> objects.<br>
/// This provides the basics needed for an svg-based graphical editor.
Class %ZEN.SVGComponent.svgCanvas Extends %ZEN.SVGComponent.svgFrame [ Deprecated, System = 3 ]
{

/// List of connectors on this canvas.
Property connectors As list Of connector(XMLPROJECTION = "NONE");

/// If true, display rulers along the left and top of this canvas.
Property showRulers As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Width of vertical ruler. This value is multiplied
/// with <property>rulerMajor</property> to get the actual size.
Property rulerWidth As %ZEN.Datatype.float [ InitialExpression = 8.5 ];

/// Height of vertical ruler. This value is multiplied
/// with <property>rulerMajor</property> to get the actual size.
Property rulerHeight As %ZEN.Datatype.float [ InitialExpression = 11.0 ];

/// Number of units per major ruler tick mark.
/// This must be a multiple of <property>rulerMinor</property>
/// or no major tick marks will show.
Property rulerMajor As %ZEN.Datatype.integer [ InitialExpression = 100 ];

/// Number of units per minor ruler tick mark.
Property rulerMinor As %ZEN.Datatype.integer [ InitialExpression = 25 ];

/// CSS style used to draw rulers.
Property rulerStyle As %ZEN.Datatype.style [ InitialExpression = "stroke:gray;" ];

/// Create a new sprite on this canvas and return it.
ClientMethod createSprite(type, x, y) [ Language = javascript ]
{
	var sprite = zenPage.createComponent(type);
	if (null != sprite) {
		sprite.setProperty('x',x);
		sprite.setProperty('y',y);
		this.addChild(sprite);
	}	
	return sprite;
}

/// Create a new connector on this canvas and return it.
ClientMethod createConnector(type) [ Language = javascript ]
{
	var connector = zenPage.createComponent(type);
	if (connector) {
		this.connectors[this.connectors.length] = connector;
		connector.renderConnector(this);
	}

	return connector;
}

/// Return true if shapes can be dragged on this frame.
ClientMethod canDragShapes() [ Language = javascript ]
{
	return true;
}

/// Notification that the embedded SVG page is loaded.
ClientMethod svgLoadHandler(win) [ Language = javascript ]
{
	this.invokeSuper('svgLoadHandler',arguments);

	// create rulers and other adornments
	var group = this.document.createElementNS(SVGNS,'g');

	// add to page just after background rect.
	this.svgGroup.insertBefore(group, this.svgBackground.nextSibling);

	this.rulerGroup = group;
	this.drawRulers(group);
}

/// Draw set of rulers.
ClientMethod drawRulers() [ Language = javascript ]
{
	var group = this.rulerGroup;
	if (!group) return;

	while(null != group.firstChild) {
		group.removeChild(group.firstChild);
	}
	if (!this.showRulers) return;

	var gridWidth = parseFloat(this.rulerWidth);
	var gridHeight = parseFloat(this.rulerHeight);
	var gridMajor = parseInt(this.rulerMajor);
	var gridMinor = parseInt(this.rulerMinor);

	var rect = this.document.createElementNS(SVGNS,'rect');
	rect.setAttribute('x',0);
	rect.setAttribute('y',0);
	rect.setAttribute('width',gridWidth*gridMajor);
	rect.setAttribute('height',gridHeight*gridMajor);
	rect.setAttribute('style','fill: none; stroke:black; stroke-width:0.5; stroke-dasharray:2,2;');
	group.appendChild(rect);

	// hz
	for (var x = 0; x < gridWidth*gridMajor; x += gridMinor) {
		var isMajor = (x%gridMajor == 0);
		var line = this.document.createElementNS(SVGNS,'line');
		line.setAttribute('x1',x);
		line.setAttribute('x2',x);
		line.setAttribute('y1',0);
		line.setAttribute('y2',isMajor ? 20 :10);
		line.setAttribute('style',this.rulerStyle);
		group.appendChild(line);	
	}
	// vt
	for (var y = 0; y < gridHeight*gridMajor; y += gridMinor) {
		var isMajor = (y%gridMajor == 0);
		var line = this.document.createElementNS(SVGNS,'line');
		line.setAttribute('x1',0);
		line.setAttribute('x2',isMajor ? 20 :10);
		line.setAttribute('y1',y);
		line.setAttribute('y2',y);
		line.setAttribute('style',this.rulerStyle);
		group.appendChild(line);	
	}
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'showRulers':
	case 'rulerWidth':
	case 'rulerHeight':
	case 'rulerMinor':
	case 'rulerMajor':
	case 'rulerStyle':
		this[property] = value;
		this.drawRulers();
		break;

	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
