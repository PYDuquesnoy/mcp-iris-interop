/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specifies settings for an axis for a <class>%ZEN.SVGComponent.chart</class> component.<br>
Class %ZEN.Auxiliary.axis Extends %ZEN.Component.object [ Deprecated, System = 3 ]
{

/// In order for collection of y-axes to work, the default name for this
/// must be yAxis. 
Parameter XMLNAME = "yAxis";

/// Minimum value along this axis.<br>
/// If this is missing (""), then the value will be automatically calculated.
Property minValue As %ZEN.Datatype.float;

/// Maximum value along this axis.<br>
/// If this is missing (""), then the value will be automatically calculated.
Property maxValue As %ZEN.Datatype.float;

/// Optional title to display along this axis.
Property title As %ZEN.Datatype.caption;

/// Base value for this axis. For charts with filled regions
/// (such as bar or area plots), this specifies where the base
/// of the filled region should be plotted.<br>
/// If this is missing (""), then the base value will be the bottom of the plot area.
Property baseValue As %ZEN.Datatype.float;

/// Major units along this axis. This specifies how major gridlines will be spaced along this axis.<br>
/// If this is missing (""), then the value will be automatically calculated.
Property majorUnits As %ZEN.Datatype.float(MINVAL = 0);

/// Minor units along this axis. This specifies how minor gridlines will be spaced along this axis.<br>
/// If this is missing (""), then the value will be automatically calculated.
Property minorUnits As %ZEN.Datatype.float(MINVAL = 0);

/// Label units along this axis. This specifies how labels will be spaced along this axis.<br>
/// If this is missing (""), then the value will be automatically calculated.
Property labelUnits As %ZEN.Datatype.float(MINVAL = 0);

/// Number of degrees that labels for this axis should be rotated.
Property labelAngle As %ZEN.Datatype.float [ InitialExpression = 0 ];

/// Specifies whether gridlines should be displayed for each major unit.
Property majorGridLines As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Specifies whether gridlines should be displayed for each minor unit.
Property minorGridLines As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Optional: style used for labels along this axis.
Property labelStyle As %ZEN.Datatype.svgStyle;

/// Optional: style used for major grid lines along this axis.
Property majorGridStyle As %ZEN.Datatype.svgStyle;

/// Optional: style used for minor grid lines along this axis.
Property minorGridStyle As %ZEN.Datatype.svgStyle;

/// Optional: specifies on which side of the chart the labels for this axis will appear.
/// For a y-axis, only "left" and "right" are used.
/// For an x-axis, only "top" and "bottom" are used.
Property labelPosition As %ZEN.Datatype.string(VALUELIST = ",left,right,top,bottom");

/// Optional: define addition control over how labels are displayed for this axis.<br/>
/// "" (auto) shows a value or category label.<br/>
/// "percent" shows a value label as a percentage (1 = 100%).<br/>
Property axisType As %ZEN.Datatype.string(VALUELIST = ",percent");

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var updateChart = false;

	switch(property) {
	case 'minValue':
	case 'maxValue':
	case 'baseValue':
	case 'majorUnits':
	case 'minorUnits':
	case 'labelUnits':
	case 'labelAngle':
		this[property] = (value=='') ? '' : parseFloat(value);
		updateChart = true;
		break;

	case 'majorGridLines':
	case 'minorGridLines':
		this[property] = value ? true : false;
		updateChart = true;
		break;

	case 'labelStyle':
	case 'majorGridStyle':
	case 'minorGridStyle':
	case 'title':
	case 'labelPosition':
	case 'axisType':
		this[property] = value;
		updateChart = true;
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}
	
	if (updateChart && !zenIsMissing(this.parent)) {
		this.parent.unrender();
		this.parent.render();
	}

	return true;
}

}
