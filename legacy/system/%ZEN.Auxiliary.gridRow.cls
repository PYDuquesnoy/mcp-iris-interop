/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines characteristics for a row within a <class>%ZEN.component.grid</class>.
Class %ZEN.Auxiliary.gridRow Extends %ZEN.Component.object [ Deprecated, System = 3 ]
{

/// Logical name of row.
Property rowName As %ZEN.Datatype.string;

/// Label displayed for column. This overrides the value from a data controller.
Property label As %ZEN.Datatype.caption;

/// Style to apply to cells in this row.<br>
/// This is a CSS style string: e.g., "color: red;"<br>
/// This style is applied <i>before</i> the column style.
Property style As %ZEN.Datatype.style;

/// Height of row. This is used for the height attribute of
/// the <tr> element for this row;
Property height As %ZEN.Datatype.length;

/// Help text displayed when mouse hovers over this row.
Property title As %ZEN.Datatype.caption;

/// If true, cells in this row are readOnly.
Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, this row is not displayed.
Property hidden As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Format to apply to cells in this row.<br>
/// This is a DeepSee format string: e.g., "###.##"
/// This format is applied <i>before</i> the column format.
Property format As %ZEN.Datatype.string;

/// Default value to apply to (empty) cells in this row.<br/>
/// This value is applied <i>before</i> the column value.
Property value As %ZEN.Datatype.string;

/// Priority of this row.<br/>
/// This lets you control the precedence of row-based attributes (style, format, value).
/// By default (when the priority values are equal) column-based attributes have 
/// precedence over row-based attributes.
/// If the row has a higher valued priority, then it takes precedence.
Property priority As %ZEN.Datatype.integer(MAXVAL = 2, MINVAL = 0) [ InitialExpression = 1 ];

}
