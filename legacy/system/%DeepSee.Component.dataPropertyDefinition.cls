/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a dataProperty definition within a Dashboard widget definition.
/// This is used by the Widget editor. It is not the saved state of the dataProperty.
Class %DeepSee.Component.dataPropertyDefinition Extends %ZEN.Component.object [ System = 3 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// Label displayed for this item within the widget.
Property label As %ZEN.Datatype.caption;

/// Specify how to format the value for this item.
Property format As %ZEN.Datatype.string;

/// Local override of widget subtype (used by meters).
Property subtype As %ZEN.Datatype.string;

/// Width of column within the widget if appropriate.
Property width As %ZEN.Datatype.length;

/// Alignment of text within a column within the widget if appropriate.
/// If not specified, a default alignment is used.
Property align As %ZEN.Datatype.string(VALUELIST = ",left,right,center");

/// If true, then this column supplies the logical value used to identify a row
/// within the score card. This may be used to tie actions to the scorecard.
Property valueColumn As %ZEN.Datatype.boolean;

/// Type of summary to display for this column.
/// If "", then no summary is displayed.
Property summary As %ZEN.Datatype.string(VALUELIST = ",sum,avg,min,max,value");

/// Value to use for summary (if summary is "value").
Property summaryValue As %ZEN.Datatype.string(VALUELIST = ",sum,avg,min,max,value");

/// Style to apply to this property if appropriate.<br>
/// This is a CSS style string: e.g., "color: red;"
Property style As %ZEN.Datatype.style;

/// Specify what to display for this property.
Property display As %ZEN.Datatype.string(VALUELIST = ",itemNo,label,value,arrow,lamp,trendLine,plotBox,hidden");

/// Specify how to display values for this property.<br/>
/// If "value" then the value for the property is displayed.<br/>
/// If "sum" then the total of all values for the property is displayed.<br/>
/// If "target" then the target value is displayed.<br/>
/// If "target%" then the value as a percentage of the target is displayed.<br/>
/// If "sum%" then the value as a percentage of the sum is displayed.<br/>
Property showAs As %ZEN.Datatype.string(VALUELIST = ",value,sum,target,target%,sum%");

/// Value used for this property.
/// This can be a number or the name of the property in data source that supplies the value for this column.
Property dataValue As %ZEN.Datatype.string;

/// Optional. Target value for this property.
/// This is used for columns that display a target value. If this is not supplied,
/// the default target value for the data source is used.<br>
/// This can contain an actual value (numeric) or the name of a property within the dataSource.
Property targetValue As %ZEN.Datatype.string;

/// Optional. Lower threshold value for this property.
/// If this is not supplied, the default value for the data source is used.<br>
/// This can contain an actual value (numeric) or the name of a property within the dataSource.
Property thresholdLower As %ZEN.Datatype.string;

/// Optional. Upper threshold value for this property.
/// If this is not supplied, the default value for the data source is used.<br>
/// This can contain an actual value (numeric) or the name of a property within the dataSource.
Property thresholdUpper As %ZEN.Datatype.string;

/// Optional. Lower range value for this property.
/// If this is not supplied, the default value for the data source is used.<br>
/// This can contain an actual value (numeric) or the name of a property within the dataSource.
Property rangeLower As %ZEN.Datatype.string;

/// Optional. Upper range value for this property.
/// If this is not supplied, the default value for the data source is used.<br>
/// This can contain an actual value (numeric) or the name of a property within the dataSource.
Property rangeUpper As %ZEN.Datatype.string;

/// Optional. Base value for this property.
/// This can contain an actual value (numeric) or the name of a property within the dataSource.
Property baseValue As %ZEN.Datatype.string;

}
