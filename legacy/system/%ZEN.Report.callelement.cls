/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
Class %ZEN.Report.callelement Extends reportNode [ Deprecated, System = 4 ]
{

/// Name of method that returns an XML stream to include
Property method As %ZEN.Datatype.string;

/// escape can be nonspace in which case any text with line-feed or space characters is not XML spaced
/// or none in which case no characters are XML spaced but all are enclosed in CDATA
/// or xml in which case the text is XML escaped
Property escape As %ZEN.Datatype.string(VALUELIST = ",xml,none,noneifspace,passthru") [ InitialExpression = "xml" ];

/// When filter is 0, call is skipped
Property filter As %ZEN.Datatype.integer;

/// Name of field (column) in the base query for this report that will
/// supply the value for this item.
/// If this starts with "!" then this is expression that evaluates to field name
Property field As %ZEN.Datatype.classMember(MEMBERTYPE = "SQLCOLUMN");

/// Name of fields (columns) in the base query for this report that will
/// supply the values for this item.
Property fields As %ZEN.Datatype.classMember(MEMBERTYPE = "SQLCOLUMN");

/// Optional ObjectScript expression that can either be applied
/// to the value of this item (supplied as <var>%val</var>), or to provide an
/// arbitrary value for this item.<br>
/// For example:<br>
/// expression="%val*2"<br>
/// expression="..ReportProp"<br>
Property expression As %ZEN.Datatype.expression;

/// return status by reference in last parameter to method
Property hasStatus As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

}
