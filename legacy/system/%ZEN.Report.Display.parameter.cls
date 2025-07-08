/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a parameter value for use by ReportDisplay tables
Class %ZEN.Report.Display.parameter Extends common [ Deprecated, Inheritance = right, System = 4 ]
{

/// Literal value used for a parameter value.<br>
/// This is used if <property>fieldname</property> is not defined.
Property value As %ZEN.Datatype.string;

/// Name of field (column) in the current query that will
/// supply the value for this item.
Property fieldname As %ZEN.Datatype.classMember(MEMBERTYPE = "SQLCOLUMN");

/// Alternatively to <property>fieldname</property> the number of field (column) in the current query that will supply the value for this item.
Property fieldnum As %ZEN.Datatype.integer;

/// Optional ObjectScript expression that can either be applied
/// to the value of this item (supplied as <var>%val</var>), or to provide an
/// arbitrary value for this item.<br>
/// For example:<br>
/// expression="%val*2"<br>
/// expression="%report.ReportProp"<br>
Property expression As %ZEN.Datatype.expression;

}
