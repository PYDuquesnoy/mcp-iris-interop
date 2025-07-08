/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines a parameter value for use by report groups and calls.
Class %ZEN.Report.parameter Extends (%RegisteredObject, %XML.Adaptor) [ Deprecated, Inheritance = right, System = 3 ]
{

/// XML namespace used for Zen Report definitions.
Parameter NAMESPACE = "http://www.intersystems.com/zen/report/definition";

/// Literal value used for a parameter value.<br>
/// This is used if <property>field</property> is not defined.
Property value As %ZEN.Datatype.string;

/// Name of field (column) in the current query that will
/// supply the value for this item.
Property field As %ZEN.Datatype.classMember(MEMBERTYPE = "SQLCOLUMN");

/// Optional ObjectScript expression that can either be applied
/// to the value of this item (supplied as <var>%val</var>), or to provide an
/// arbitrary value for this item.<br>
/// For example:<br>
/// expression="%val*2"<br>
/// expression="..ReportProp"<br>
Property expression As %ZEN.Datatype.expression;

}
