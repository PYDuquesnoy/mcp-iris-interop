/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines an XML element within a ZEN Report.
Class %ZEN.Report.element Extends valueNode [ Deprecated, System = 3 ]
{

/// escape can be nonspace in which case any text with line-feed or space characters is not XML spaced
/// or none in which case no characters are XML spaced but all are enclosed in CDATA
/// or xml in which case the text is XML escaped
Property escape As %ZEN.Datatype.string(VALUELIST = ",xml,none,noneifspace,passthru,html") [ InitialExpression = "xml" ];

/// When filter is 0, element is skipped
Property filter As %ZEN.Datatype.integer;

/// True if Excel numeric field
Property isExcelNumber As %ZEN.Datatype.boolean;

/// True if Excel date field
Property isExcelDate As %ZEN.Datatype.boolean;

/// True if Excel time field
Property isExcelTime As %ZEN.Datatype.boolean;

/// if non-null is display number format of element value, only effective when mode="xlsx"
Property excelNumberFormat As %ZEN.Datatype.string;

Property fieldType As %ZEN.Datatype.string(VALUELIST = ",literal,stream") [ InitialExpression = "literal" ];

Property excelName As %ZEN.Datatype.string;

}
