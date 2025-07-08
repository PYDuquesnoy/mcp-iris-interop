/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines characteristics for a column within a <class>%ZEN.component.grid</class>.
Class %ZEN.Auxiliary.gridColumn Extends %ZEN.Component.object [ Deprecated, System = 3 ]
{

/// Logical name of column.
Property columnName As %ZEN.Datatype.string;

/// Label displayed for column. This overrides the value from a data controller.
Property label As %ZEN.Datatype.caption;

/// Width of column.
Property width As %ZEN.Datatype.length;

/// Style to apply to cells in this column.<br>
/// This is a CSS style string: e.g., "color: red;"
/// Note that column style overrides row style.
Property style As %ZEN.Datatype.style;

/// Help text displayed when mouse hovers over this column.
/// Note that column title overrides row title.
Property title As %ZEN.Datatype.caption;

/// If true, cells in this column are readOnly.
Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, this column is not displayed.
Property hidden As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Format to apply to cells in this column.<br>
/// This is a DeepSee format string: e.g., "###.##"
/// Note that column format overrides row format.
Property format As %ZEN.Datatype.string;

/// Default value to apply to (empty) cells in this column.<br/>
/// This value is applied <i>after</i> the row value.
Property value As %ZEN.Datatype.string;

/// Priority of this column.<br/>
/// This lets you control the precedence of column-based attributes (style, format, value).
/// By default (when the priority values are equal) column-based attributes have 
/// precedence over row-based attributes.
/// If the column has a higher or equal-valued priority, then it takes precedence.
Property priority As %ZEN.Datatype.integer(MAXVAL = 2, MINVAL = 0) [ InitialExpression = 1 ];

/// Optional.
/// Type of cells in this column. Used by DeepSee worksheets.
Property type As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// Optional.
/// If the column type is "enum", this is a csv list of allowed values. Used by DeepSee worksheets.
Property valueList As %ZEN.Datatype.csv(XMLPROJECTION = "none");

/// Optional.
/// Information on how to lookup values for this column. Used by DeepSee worksheets.
Property lookupSpec As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// Optional.
/// Default logical value used for this column. Used by DeepSee worksheets.
Property logicalValue As %ZEN.Datatype.string(XMLPROJECTION = "none");

}
