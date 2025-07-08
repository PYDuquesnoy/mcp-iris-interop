/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines characteristics for a specific cell within a <class>%ZEN.component.grid</class>.
Class %ZEN.Auxiliary.gridCell Extends %ZEN.Component.object [ Deprecated, System = 3 ]
{

/// Row number of this cell (1-based).
Property row As %ZEN.Datatype.integer;

/// Column number of this cell (1-based).
Property column As %ZEN.Datatype.integer;

/// Page number of this cell (1-based).
/// If omitted, then this cell applies to all pages (if more than one).
Property page As %ZEN.Datatype.integer;

/// Style to apply to this cell.<br>
/// This is a CSS style string: e.g., "color: red;"<br>
Property style As %ZEN.Datatype.style;

/// Help text displayed when mouse hovers over this cell.
Property title As %ZEN.Datatype.caption;

/// If true, this cell is readOnly.
Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Format to apply to this cell.<br>
/// This is a DeepSee format string: e.g., "###.##"
Property format As %ZEN.Datatype.string;

}
