/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines an input/output port for a <class>sprite</class> object.<br>
Class %ZEN.SVGComponent.port Extends svgObject [ Deprecated, System = 3 ]
{

/// Type of this port: input or output.<br>
Property type As %ZEN.Datatype.string(VALUELIST = ",input,output");

/// x position of this port.<br>
Property x As %ZEN.Datatype.float [ InitialExpression = 0 ];

/// y position of this port.<br>
Property y As %ZEN.Datatype.float [ InitialExpression = 0 ];

/// List of connectors connected to this port.
Property connectors As list Of connector(XMLPROJECTION = "NONE");

/// Render the svg for this port.
ClientMethod renderPort() [ Language = javascript ]
{
	if (this._sprite) {
		// get group and document from our sprite
		var circle = this._sprite.document.createElementNS(SVGNS,'circle');
		circle.setAttribute('class','input'==this.type?'inputPort':'outputPort');
		circle.setAttribute('cx',this.x);
		circle.setAttribute('cy',this.y);
		circle.setAttribute('r',3);
		this._svgShape = circle;
	
		// add to our owner's group
		this._sprite.svgGroup.appendChild(this._svgShape);
	}
}

/// Internal method: add a connector to this port.
/// Return true if successful.
ClientMethod addConnector(connector) [ Language = javascript ]
{
	this.connectors[this.connectors.length] = connector;
	return true;
}

/// Internal method: update position of all connectors
/// connected to this port.
ClientMethod updateConnectors() [ Language = javascript ]
{
	for (var n = 0; n < this.connectors.length; n++) {
		var connector = this.connectors[n];
		connector.updateConnector();
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var updateSprite = false;

	switch(property) {
	case 'type':
		this.type = value;
		break;

	case 'x':
		this.x = (value=='') ? '' : parseFloat(value);
		if (this._svgShape) {
			this._svgShape.setAttribute('cx',this.x);
			this.updateConnectors();
		}
		break;

	case 'y':
		this.y = (value=='') ? '' : parseFloat(value);
		if (this._svgShape) {
			this._svgShape.setAttribute('cy',this.y);
			this._sprite.updateConnectors();
		}
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}

	// sprite should set the _sprite pointer
	if (updateSprite && this._sprite) {
		this._sprite.render();
	}

	return true;
}

}
