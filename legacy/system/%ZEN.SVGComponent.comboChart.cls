/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an SVG <class>chart</class> component that displays a combination of
/// line and bar chart information.<br/>
/// This chart displays one or more data series each of which can be presented as lines
/// or bars.<br/>
/// Pivotted combo charts are not supported.
Class %ZEN.SVGComponent.comboChart Extends %ZEN.SVGComponent.barChart [ Deprecated, System = 3 ]
{

/// Default appearance of this component.
Parameter DEFAULTAPPEARANCE = "2D";

/// Comma-delimited list of types indicating how each series within the chart should be displayed.
/// Possible types are "line", "area", "target", and "bar". If a type is not supplied, the type is "bar".
/// "target" draws a target bar across any bars series.
Property seriesTypes As %ZEN.Datatype.csv;

/// Return the type (how a series should be displayed) for the given data series (0-based).
ClientMethod getSeriesType(series) [ Language = javascript ]
{
	var t = this.seriesTypes.toString().split(',');
	var type = t[series] ? t[series] : (this.isTimeBased()?'line':'bar');
	return type;
}

/// For line/bar charts with stacked bars, indicate which "group" should
/// be used for computing axis ranges.
ClientMethod getRangeGroupForSeries(series) [ Language = javascript ]
{
	var group = '';

	// JMD1208
	var multipleOffset = (this.currMultiple?this.currMultiple:0);

	switch (this.getSeriesType(series+multipleOffset)) {
	case 'target':
	case 'bar':
		if (this.useSumForRange()) {
			// add up as stacked bars
			group = 'bar';
		}
		else {
			group = 'none';
		}
		break;
	case 'area':
		group = 'none';
		break;
	case 'line':
	default:
		// count independently
		group = 'none';
		break;
	}
	return group;
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'seriesTypes':
		this[property] = value;
		this.render();
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
	}

	return true;
}

/// Test if this is a combo chart.
ClientMethod isCombo() [ Language = javascript ]
{
	return true;
}

/// Test if a time-based x axis should be used.
/// This is overridden in subclasses.
ClientMethod isTimeBased() [ Language = javascript ]
{
	return this.chartPivot ? false : this.timeBased;
}

}
