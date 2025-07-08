/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines an xml attribute within a ZEN Report.
Class %ZEN.Report.attribute Extends valueNode [ Deprecated, Final, System = 3 ]
{

/// escape can be nonspace in which case any text with line-feed or space characters is not XML spaced
/// or none in which case no characters are XML spaced but all are enclosed in CDATA
/// or xml in which case the text is XML escaped
Property escape As %ZEN.Datatype.string(VALUELIST = ",xml,none,noneifspace") [ InitialExpression = "xml" ];

/// When filter is 0, attribute is skipped
Property filter As %ZEN.Datatype.integer;

}
