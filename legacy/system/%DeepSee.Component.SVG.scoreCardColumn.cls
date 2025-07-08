/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines characteristics for a column within a <class>%DeepSee.Component.SVG.scoreCard</class> component.
Class %DeepSee.Component.SVG.scoreCardColumn Extends %ZEN.Component.object [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// Default header label displayed for column.
Property label As %ZEN.Datatype.caption;

/// Caption to display within the cell for this column.
Property cellCaption As %ZEN.Datatype.caption;

/// If true, then this column supplies the logical value used to identify a row
/// within the score card. This may be used to tie actions to the scorecard.
Property valueColumn As %ZEN.Datatype.boolean;

/// Type of summary to display for this column.<br/>
/// If "", then no summary is displayed.<br/>
/// "sum" computes and displays the sum of the values within the column.<br/>
/// "avg" computes and displays the average of the values within the column.<br/>
/// "min" finds and displays the minimum of the values within the column.<br/>
/// "max" finds and displays the maximum of values within the column.<br/>
/// "value" evaluates and displays the value of the <property>summaryValue</property> property.<br/>
Property summary As %ZEN.Datatype.string(VALUELIST = ",sum,avg,min,max,value");

/// Value to use for the summary of the column (if <property>summary</property> is "value").<br/>
/// This can be a literal number, a literal string (enclosed within ""), 
/// the name of the property in data source that supplies the value for this column,
/// or an expression (starting with =).
Property summaryValue As %ZEN.Datatype.string;

/// Width of column.
Property width As %ZEN.Datatype.length;

/// Alignment of text (and footer) within this column.
/// If not specified, a default alignment is used.
Property align As %ZEN.Datatype.string(VALUELIST = ",left,right,center");

/// Alignment of header text within this column.
/// If not specified, a default alignment is used.
Property headerAlign As %ZEN.Datatype.string(VALUELIST = ",left,right,center");

/// Style to apply to cells in this column.<br>
/// This is a CSS style string: e.g., "color: red;"
/// Note that column style overrides row style.
Property style As %ZEN.Datatype.style;

/// Specify what to display in this column.
Property display As %ZEN.Datatype.string(VALUELIST = ",itemNo,label,value,arrow,lamp,trendLine,trendBars,plotBox,hidden");

/// Specify how to display values for this column.<br/>
/// If "value" then the value for the column is displayed.<br/>
/// If "conditional" then the value for the column is displayed <b>if</b> the property this columns depends on exists.<br/>
/// If "sum" then the total of all values for the column is displayed.<br/>
/// If "target" then the target value is displayed.<br/>
/// If "target%" then the value as a percentage of the target is displayed.<br/>
/// If "sum%" then the value as a percentage of the sum is displayed.<br/>
Property showAs As %ZEN.Datatype.string(VALUELIST = ",value,conditional,sum,target,target%,sum%");

/// Specify how to format a numeric value for this property.
Property format As %ZEN.Datatype.string;

/// Value used for this column.<br/>
/// This can be a literal number, a literal string (enclosed within ""), 
/// the name of the property in data source that supplies the value for this column,
/// or an expression (starting with =).
Property dataValue As %ZEN.Datatype.string;

/// Optional. Target value for this column.
/// This is used for columns that display a target value. If this is not supplied,
/// the default target value for the data source is used.<br>
/// This can contain an actual value (numeric) or the name of a property within the dataSource.
Property targetValue As %ZEN.Datatype.string;

/// Optional. Base value for this column.
/// This is used for columns that display values graphically, such as a plotBox.
/// If this is defined, then values are plotted against this base value.
/// Typically this is set to 0 to display negative values as bars in the opposite direction.
/// This can contain an actual value (numeric) or the name of a property within the dataSource.
Property baseValue As %ZEN.Datatype.string;

/// Optional. Lower threshold value for this column.
/// If this is not supplied, the default value for the data source is used.<br>
/// This can contain an actual value (numeric) or the name of a property within the dataSource.
Property thresholdLower As %ZEN.Datatype.string;

/// Optional. Upper threshold value for this column.
/// If this is not supplied, the default value for the data source is used.<br>
/// This can contain an actual value (numeric) or the name of a property within the dataSource.
Property thresholdUpper As %ZEN.Datatype.string;

/// Optional. Lower range value for this column.
/// If this is not supplied, the default value for the data source is used.<br>
/// This can contain an actual value (numeric) or the name of a property within the dataSource.
Property rangeLower As %ZEN.Datatype.string;

/// Optional. Upper range value for this column.
/// If this is not supplied, the default value for the data source is used.<br>
/// This can contain an actual value (numeric) or the name of a property within the dataSource.
Property rangeUpper As %ZEN.Datatype.string;

}
