/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for SVG meter components.<br>
/// A meter is analogous to a control: it has a value
/// as well as upper and lower ranges and thresholds. The
/// display of the value is implemented by subclasses.
Class %ZEN.SVGComponent.meter Extends (svgComponent, %ZEN.Component.dataView) [ Abstract, Deprecated, Inheritance = right, System = 3 ]
{

/// Default viewBoxWidth of this component.
/// This is set to 100 to provide a default, fixed coordinate system for meters.
Parameter DEFAULTVIEWBOXWIDTH = 100;

/// Default viewBoxHeight of this component.
/// This is set to 100 to provide a fixed coordinate system for meters.
Parameter DEFAULTVIEWBOXHEIGHT = 100;

/// Current value of the meter.
Property value As %ZEN.Datatype.string [ InitialExpression = 0 ];

/// Label displayed by the meter.
Property label As %ZEN.Datatype.caption;

/// Optional: CSS style applied to the meter label.
Property labelStyle As %ZEN.Datatype.svgStyle;

/// If defined, this is the target value for the meter.
/// If this value is numeric, then it is used as the target value.
/// If it is a string, then it is used as the name of a property within the
/// data source connected to this meter.<br/>
/// Certain meters may display this value.
Property targetValue As %ZEN.Datatype.string;

/// Represents the lower value of the meter range.
/// If this value is numeric, then it is used as the value.
/// If it is a string, then it is used as the name of a property within the
/// data source connected to this meter.<br/>
Property rangeLower As %ZEN.Datatype.string;

/// Represents the upper value of the meter range.
/// If this value is numeric, then it is used as the value.
/// If it is a string, then it is used as the name of a property within the
/// data source connected to this meter.<br/>
Property rangeUpper As %ZEN.Datatype.string;

/// Represents the lower threshold level for the meter.
/// If this value is numeric, then it is used as the value.
/// If it is a string, then it is used as the name of a property within the
/// data source connected to this meter.<br/>
Property thresholdLower As %ZEN.Datatype.string;

/// Represents the upper threshold level for the meter.
/// If this value is numeric, then it is used as the value.
/// If it is a string, then it is used as the name of a property within the
/// data source connected to this meter.<br/>
Property thresholdUpper As %ZEN.Datatype.string;

/// The displayed value is determined by multiplying the actual
/// value and this scaling factor.
Property scaleFactor As %ZEN.Datatype.float [ InitialExpression = 1 ];

/// If this meter supports animation, then this controls whether the animation
/// is on or off.
Property animate As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true, disable this meter.
Property disabled As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Optional. If this meter is associated with
/// a <class>%ZEN.Auxiliary.dataController</class>, this specifies the name of the property within the dataController
/// that will provide the value for this control.
Property dataBinding As %ZEN.Datatype.string;

/// If true, hide this meter if it is bound to a non-existant data property.
Property showConditionally As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// onchange event handler:
/// For meters that allow user actions to modify their value,
/// this event handler is called when the user changes the value of the slider.
Property onchange As %ZEN.Datatype.eventHandler;

XData SVGStyle
{
<style type="text/css">

/* labels for meters */
.meter-label {
	pointer-events: none;
	font-size: 8pt;
	fill: #404040;
	stroke: none;
}

</style>
}

/// Render the inner SVG contents of this component.
ClientMethod renderContents() [ Final, Language = javascript ]
{
	// get data from controller, if present.
	this.acquireData();
	
	// draw the contents of the meter.
	this.renderMeter();
}

/// Render the inner SVG contents of this component.
/// Subclasses should implement this method.
ClientMethod renderMeter() [ Language = javascript ]
{
}

/// Short-cut method to get the current value of this meter.
ClientMethod getValue() [ Language = javascript ]
{
	return this.getProperty('value');
}

/// Short-cut method to set the current value of this meter.
ClientMethod setValue(value) [ Language = javascript ]
{
	return this.setProperty('value',value);
}

/// Acquire data for this meter.<br/>
/// If the meter is connected to a dataController, then set the
/// value of the meter to the current value of the dataController
/// property specified by <property>dataBinding</property>.
ClientMethod acquireData() [ Language = javascript ]
{
	var controller = this.getController();
	if (null == controller) {
		// try to connect to dataController
		this.connectToController();
		controller = this.getController();
	}
	if (controller) {

		// JMD 1125
		this._rangeUpper = '';
		this._rangeLower = '';
		this._thresholdUpper = '';
		this._thresholdLower = '';
		this._targetValue = '';

		var data = controller.getDataByName(this.dataBinding);
		if (null==data) {
			if (this.showConditionally && !this.hidden) {
				this.setProperty('hidden',true);
			}
			if (!this.disabled) {
				this.setProperty('disabled',true);
			}
			this.value = '';
		}
		else {
			if (this.showConditionally && this.hidden) {
				this.setProperty('hidden',false);
			}
			if (this.disabled) {
				this.setProperty('disabled',false);
			}
			this.value = data;

			// if the controller provides values for the special properties
			// %thresholdUpper etc, then these supply defaults for the meter

			var d = controller.getDataByName('%rangeUpper');
			if (d&&''==this.rangeUpper) {
				this._rangeUpper = d;
			}
			else if (''!=this.rangeUpper && isNaN(parseFloat(this.rangeUpper))) {
				this._rangeUpper = controller.getDataByName(this.rangeUpper);
			}
			else {
				this._rangeUpper = parseFloat(this.rangeUpper);
				this._rangeUpper = isNaN(this._rangeUpper) ? '' : this._rangeUpper;
			}

			var d = controller.getDataByName('%rangeLower');
			if (d&&''==this.rangeLower) {
				this._rangeLower = d;
			}
			else if (''!=this.rangeLower && isNaN(parseFloat(this.rangeLower))) {
				this._rangeLower = controller.getDataByName(this.rangeLower);
			}
			else {
				this._rangeLower = parseFloat(this.rangeLower);
				this._rangeLower = isNaN(this._rangeLower) ? '' : this._rangeLower;
			}

			var d = controller.getDataByName('%thresholdUpper');
			if (d&&''==this.thresholdUpper) {
				this._thresholdUpper = d;
			}
			else if (''!=this.thresholdUpper && isNaN(parseFloat(this.thresholdUpper))) {
				this._thresholdUpper = controller.getDataByName(this.thresholdUpper);
			}
			else {
				this._thresholdUpper = parseFloat(this.thresholdUpper);
				this._thresholdUpper = isNaN(this._thresholdUpper) ? '' : this._thresholdUpper;
			}

			var d = controller.getDataByName('%thresholdLower');
			if (d&&''==this.thresholdLower) {
				this._thresholdLower = d;
			}
			else if (''!=this.thresholdLower && isNaN(parseFloat(this.thresholdLower))) {
				this._thresholdLower = controller.getDataByName(this.thresholdLower);
			}
			else {
				this._thresholdLower = parseFloat(this.thresholdLower);
				this._thresholdLower = isNaN(this._thresholdLower) ? '' : this._thresholdLower;
			}

			if (''!=this.targetValue && isNaN(parseFloat(this.targetValue))) {
				this._targetValue = controller.getDataByName(this.targetValue);
			}
			else {
				this._targetValue = parseFloat(this.targetValue);
				this._targetValue = isNaN(this._targetValue) ? '' : this._targetValue;
			}
		}
	}
	else {
		// set local copy of range and threshold
		this._rangeLower = parseFloat(this.rangeLower);
		this._rangeUpper = parseFloat(this.rangeUpper);
		this._rangeLower = isNaN(this._rangeLower) ? 0 : this._rangeLower;
		this._rangeUpper = isNaN(this._rangeUpper) ? 100 : this._rangeUpper;

		this._thresholdLower = parseFloat(this.thresholdLower);
		this._thresholdUpper = parseFloat(this.thresholdUpper);
		this._thresholdLower = isNaN(this._thresholdLower) ? 0 : this._thresholdLower;
		this._thresholdUpper = isNaN(this._thresholdUpper) ? 100 : this._thresholdUpper;
		
		this._targetValue = parseFloat(this.targetValue);
		this._targetValue = isNaN(this._targetValue) ? '' : this._targetValue;
	}

	// apply defaults	
	this._thresholdLower = (''==this._thresholdLower) ? 0 : this._thresholdLower;
	this._thresholdUpper = (''==this._thresholdUpper) ? 90 : this._thresholdUpper;
	this._rangeLower = (''==this._rangeLower) ? 0 : this._rangeLower;
	this._rangeUpper = (''==this._rangeUpper) ? 100 : this._rangeUpper;

	return this.value;
}

/// Create the label displayed by this meter.
/// Subclasses should call this from their <method>render</method
/// method.
/// <var>x</var> and <var>y</var> specify the midpoint of the label.
ClientMethod renderLabel(x, y) [ Language = javascript ]
{
	var lblText = this.document.createElementNS(SVGNS,'text');
	lblText.setAttribute('id',this.makeId('label'));
	lblText.setAttribute('class','meter-label');
	lblText.setAttribute('style',this.labelStyle);
	lblText.setAttribute('x',x);
	lblText.setAttribute('y',y);
	lblText.setAttribute('text-anchor','middle');

	var textNode = this.document.createTextNode(this.getLabelText());
	lblText.appendChild(textNode);
	this.svgGroup.appendChild(lblText);

	// JMD1125 adjust font-size so that text fits
	var bbox = zenGetBBox(lblText);
	if (bbox.width*1.1 > this.viewBoxWidth) {
		var fSZ = bbox.height;
		while (bbox.width*1.1 > this.viewBoxWidth && fSZ>3) {
			fSZ *= 0.8;
			lblText.setAttribute('style',this.labelStyle + 'font-size:'+fSZ+'px;');
			var bbox = zenGetBBox(lblText);
		}
	}
}

/// Return the resolved label to display for this meter.
ClientMethod getLabelText() [ Language = javascript ]
{
	// JMD1003
	var label = this.label;
	if ('$auto'==label) {
		var controller = this.getController();
		if (!controller) {
			label = this.dataBinding;
		}
		else {
			// get label from controller
			label = '';
			var labelDim = 1;
			if (controller.getPropertyDim) {
				labelDim = controller.getPropertyDim();
			}
			var props = controller.getDimSize(labelDim);
			for (var p1 = 0; p1 < props; p1++) {
				if (controller.getPropertyName(p1)==this.dataBinding) {
					label = controller.getLabel(p1,labelDim);
					break;
				}
			}
		}
	}
	return label;
}

/// Notification that the dataController associated with this dataView
/// has raised an event.
ClientMethod notifyViewHandler(reason, data1, data2, data3) [ Language = javascript ]
{
	switch(reason) {
	case 'dataChange':
		// see if this is a series we care about
		var controller = this.getController();
		var ds = controller.getProperty('defaultSeries');
		if (null == data3 || ds == data3) {
			var oldTU = this._thresholdUpper;
			var oldTL = this._thresholdLower;
			var oldRU = this._rangeUpper;
			var oldRL = this._rangeLower;
			this.setValue(this.acquireData());
			if ((oldTU != this._thresholdUpper)||(oldRU != this._rangeUpper)||(oldTL != this._thresholdLower)||(oldRL != this._rangeLower)) {
				this.unrender();
				this.render();
			}
		}
		break;
	case 'seriesChange':
	case 'modelChange':
		this.setValue(this.acquireData());
		break;
	}
}

/// This built-in event handler is called by meters that allow user
/// interaction. It raises notification that the meter's value has changed.
ClientMethod onchangeHandler() [ Language = javascript ]
{
	// notify our controller
	var controller = this.getController();
	if (controller && '' != this.dataBinding) {
		this.sendEventToController('propertyChange',this.dataBinding,this.value);
	}
	// call user event handler 
	zenInvokeCallbackMethod(this.onchange,this,'onchange');
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'scaleFactor':
	case 'rangeUpper':
	case 'rangeLower':
	case 'thresholdUpper':
	case 'thresholdLower':
		this[property] = value;
		// force update of meter
		this.setProperty('value',this.value);
		break;

	case 'label':
		this.label = value;
		this.unrender();
		this.render();
		// this.setTextNode('label',this.getLabelText());
		break;

	case 'labelStyle':
		this.labelStyle = value;
		this.unrender();
		this.render();
		/*
		var label = this.findSVGElement('label');
		if (label) {
			label.setAttribute('style',this.labelStyle);
		}
		*/
		break;

	case 'animate':
		this.animate = value ? true : false;
		break

	case 'disabled':
		this.disabled = value ? true : false;
		break

	default:
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
