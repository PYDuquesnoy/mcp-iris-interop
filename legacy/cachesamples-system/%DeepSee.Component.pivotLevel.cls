/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines an axis, measure, or filter level
/// within a <class>%DeepSee.Component.pivotTable</class> component.
Class %DeepSee.Component.pivotLevel Extends %ZEN.Component.object [ System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// This specifies the dimension level displayed for this level
/// of the pivot table.<br/>
/// For example, "[Product]" or "[Time].[Year]"
Property spec As %ZEN.Datatype.string;

/// For filters, indicates if a filter is enabled.
Property enabled As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true, then <property>spec</property> contains an "advanced" specification
/// (such as an advanced filter).
Property advanced As %ZEN.Datatype.boolean;

/// If true, then is a filter that was passed in from a widget and should
/// not be saved as part of the pivot state.
Property transient As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Key value of the current dimension level.<br/>
/// This can be a comma-delimited list of keys:<br/>
/// "14,25"<br/>
/// If there are multiple keys, they may be encoded as an MDX set. "{A,B}"
Property key As %ZEN.Datatype.string;

/// Drill-level at which this level was defined.
Property drillLevel As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// Internal property used to track order in which filters are displayed.
Property position As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ Internal ];

/// Used to track the dimension number for a filter.
Property filterDim As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ Internal ];

/// Used to track the hierarchy number for a filter.
Property filterHier As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ Internal ];

/// Name value of the current dimension level.<br/>
/// This can be a comma-delimited list of delimited values:
/// "[2005],[2006]"
Property value As %ZEN.Datatype.string;

/// Optional display name for this level. This is the text displayed by the pivot table
/// when a level is used a filter.
Property text As %ZEN.Datatype.caption;

/// Optional caption for this level.
/// This is used to hold the level caption when this level is used a filter.
Property caption As %ZEN.Datatype.caption;

/// Original spec for a filter (used to find caption).
Property baseSpec As %ZEN.Datatype.string(XMLPROJECTION = "none") [ Internal ];

/// Children of this level.
Property childLevels As list Of pivotLevel(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", ZENSETTING = 0);

/// If true, apply the 80/20 suppression to this level.
Property suppress8020 As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, apply the HEAD function to this level.
Property headEnabled As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Count argument for HEAD function.
Property headCount As %ZEN.Datatype.integer;

/// If true, apply the FILTER function to this level.
Property filterEnabled As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Filter expression for FILTER function.
Property filterExpression As %ZEN.Datatype.string;

/// If true, apply the ORDER function to this level.
Property orderEnabled As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Sort expression for ORDER function.
Property orderExpression As %ZEN.Datatype.string;

/// Direction argument for ORDER function.
Property orderDirection As %ZEN.Datatype.string [ InitialExpression = "BDESC" ];

/// If true, apply the Aggregate function to this level.
Property aggEnabled As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Aggregate function.
Property aggFunction As %ZEN.Datatype.string;

/// Parameter for aggregate function (if any)
Property aggFunctionParm As %ZEN.Datatype.string;

/// Optional caption to apply to this element.
Property levelCaption As %ZEN.Datatype.string;

/// Optional format to apply to this element.
Property levelFormat As %ZEN.Datatype.string;

/// For row/column options, indicates the type of member defined.
Property levelType As %ZEN.Datatype.string(VALUELIST = ",value,space,mdx");

/// Optional CSS style to apply to this element.
Property levelStyle As %ZEN.Datatype.style;

/// Optional CSS style to apply to header's for this element.
Property levelHeaderStyle As %ZEN.Datatype.style;

/// Optional pivot table summary to use for this element.
/// If the pivotTable displays rowTotals or columnTotals, then this will override the
/// summary aggregate used.<br/>
/// The value can be sum,min,max,count,avg,pct.
Property levelSummary As %ZEN.Datatype.string;

/// Drilldown spec.
Property drilldownSpec As %ZEN.Datatype.string;

/// Create a clone of this object.
ClientMethod clone(ascomp) [ Internal, Language = javascript ]
{
	var clone;
	if (ascomp) {
		// create as a component
		clone = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
	}
	else {
		// transient object
		clone = new Object();
		clone.clone = _DeepSee_Component_pivotLevel_clone;
	}
	clone.spec = this.spec;
	clone.key = this.key;
	clone.value = this.value;
	clone.text = this.text;
	clone.caption = this.caption;
	clone.advanced = this.advanced;
	clone.filterDim = this.filterDim;
	clone.filterHier = this.filterHier;
	clone.suppress8020 = this.suppress8020;
	clone.drilldownSpec = this.drilldownSpec;
	clone.headEnabled = this.headEnabled;
	clone.headCount = this.headCount;
	clone.filterEnabled = this.filterEnabled;
	clone.filterExpression = this.filterExpression;
	clone.orderEnabled = this.orderEnabled;
	clone.orderExpression = this.orderExpression;
	clone.orderDirection = this.orderDirection;
	clone.drillLevel = this.drillLevel;
	clone.aggEnabled = this.aggEnabled;
	clone.aggFunction = this.aggFunction;
	clone.aggFunctionParm = this.aggFunctionParm;
	clone.levelCaption = this.levelCaption;
	clone.levelFormat = this.levelFormat;
	clone.levelType = this.levelType;
	clone.levelStyle = this.levelStyle;
	clone.levelHeaderStyle = this.levelHeaderStyle;
	clone.levelSummary = this.levelSummary;

	clone.enabled = this.enabled;

	// JMD1007
	clone.transient = this.transient;

	clone.childLevels = new Array();
	for (var n = 0; n < this.childLevels.length; n++) {
		clone.childLevels[n] = this.childLevels[n].clone(ascomp ? true : false);
	}
	return clone;
}

}
