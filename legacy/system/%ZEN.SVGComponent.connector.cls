/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for SVG connector.<br>
/// A connector is used to display connections between sprites.
Class %ZEN.SVGComponent.connector Extends svgObject [ Deprecated, System = 3 ]
{

/// Additional style to apply to the primary connector shape.
Property style As %ZEN.Datatype.style;

/// List of input ports this connector is connected to.
Property inputs As list Of port(XMLPROJECTION = "NONE");

/// List of output ports this connector is connected to.
Property outputs As list Of port(XMLPROJECTION = "NONE");

XData SVGStyle
{
<style type="text/css">
.connector {
	fill: none;
	stroke: darkblue;
	stroke-width: 1px;
}
</style>
}

/// Render the inner SVG contents of this connector.
ClientMethod renderConnector(canvas) [ Language = javascript ]
{
	if (null == this._svgPath) {
		// create connector shape (use a path)
		this._svgPath = canvas.document.createElementNS(SVGNS,'path');
		this._svgPath.setAttribute('class','connector');
		this._svgPath.setAttribute('style',this.style);

		// add to the underlay group for the page
		var underGroup = canvas.document.getElementById('zenUnderlay');
		zenASSERT(underGroup,'Unable to find svg underlay group for the page.',arguments);
		underGroup.appendChild(this._svgPath);
	}

	this.updateConnector();
}

/// Update the shape used to define the connector
/// This can be overridded by subclasses.
ClientMethod updateConnector() [ Language = javascript ]
{
	if (null != this._svgPath) {
		var d = '';

		if (this.outputs.length > 0 && this.inputs.length > 0) {
			// find start/end points
			// (these have to be converted to canvas coordinates)
			var tsx = 0,tsy = 0;
			var sx = new Array(this.outputs.length);
			var sy = new Array(this.outputs.length);
			for (var n = 0; n < this.outputs.length; n++) {
				var port = this.outputs[n];
				var sprite = port._sprite;
				var size = sprite.getSizeAbsolute();
				sx[n] = parseFloat(size.x + port.x);
				sy[n] = parseFloat(size.y + port.y);
				tsx += sx[n];
				tsy += sy[n];
			}
			tsx = tsx / this.outputs.length;
			tsy = tsy / this.outputs.length;

			var tex = 0,tey = 0;
			var ex = new Array(this.inputs.length);
			var ey = new Array(this.inputs.length);
			for (var n = 0; n < this.inputs.length; n++) {
				var port = this.inputs[n];
				var sprite = port._sprite;
				var size = sprite.getSizeAbsolute();
				ex[n] = parseFloat(size.x + port.x);
				ey[n] = parseFloat(size.y + port.y);
				tex += ex[n];
				tey += ey[n];
			}
			tex = tex / this.inputs.length;
			tey = tey / this.inputs.length;

			// find mid points
			//var m1x = (tex + tsx) / 2;
			var m1x = tsx;
			var m1y = (tey>tsy) ? tsy + (tey-tsy)/2 : tey + (tsy-tey)/2;
			//var m2x = m1x;
			//var m2y = (tey>tsy) ? tey - (tey-tsy)/2 : tsy - (tsy-tey)/2;
			var m2x = tex;
			var m2y = m1y;
			for (var n = 0; n < this.outputs.length; n++) {
				d += 'M ' + sx[n] + ' ' + sy[n] + ' L ' + m1x + ' ' + m1y + ' ';
			}
			for (var n = 0; n < this.inputs.length; n++) {
				d += 'M ' + ex[n] + ' ' + ey[n] + ' L ' + m2x + ' ' + m2y + ' ';
			}
			d += 'M ' + m1x + ' ' + m1y + ' L ' + m2x + ' ' + m2y + ' ';
		}
		if (d) {
			this._svgPath.setAttribute('d',d);
		}
	}
}

/// Return the maximum number of inputs allowed for this connector.
ClientMethod getMaxInputs() [ Language = javascript ]
{
	return 5;
}

/// Return the maximum number of outputs allowed for this connector.
ClientMethod getMaxOutputs() [ Language = javascript ]
{
	return 5;
}

/// Public API: Add an input to this connector.
ClientMethod addInput(sprite, portno) [ Language = javascript ]
{
	if (this.inputs.length < this.getMaxInputs()) {
		var port = sprite.getPort(portno);
		if (port) {
			if (port.addConnector(this)) {
				this.inputs[this.inputs.length] = port;
				this.updateConnector();
			}
		}
	}
}

/// Public API: Add an output to this connector.
ClientMethod addOutput(sprite, portno) [ Language = javascript ]
{
	if (this.outputs.length < this.getMaxOutputs()) {
		var port = sprite.getPort(portno);
		if (port) {
			if (port.addConnector(this)) {
				this.outputs[this.outputs.length] = port;
				this.updateConnector();
			}
		}
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'style':
		this.style = value;
		if (this._svgPath) {
			this._svgPath.setAttribute('style',this.style);
		}
		break;
	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
