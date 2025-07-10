/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A base class for print requests
Class EnsLib.Printing.ZENReportsPrintRequest Extends EnsLib.Printing.PrintRequest [ System = 4 ]
{

/// Classname of the ZEN Reports class
Property ClassName As Ens.DataType.Class(EXTENDS = "%ZEN.Report.reportPage", MUSTEXIST = 1);

/// Report mode
/// <ul><li>0 = XML</li><li>1 = HTML</li><li>2 = PDF</li><li>3 = ToHTML Stylesheet</li><li>4 = ToXSLFO Stylesheet</li><li>5 = ToXSD Schema</li></ul><br>
Property ReportMode As %Integer(DISPLAYLIST = ",XML,HTML,PDF,HTML/CSS,XSL-FO,XSD", VALUELIST = ",0,1,2,3,4,5") [ Required ];

/// Parameters to the request
Property Parameters As array Of %String;

Storage Default
{
<Data name="Parameters">
<Attribute>Parameters</Attribute>
<Structure>subnode</Structure>
<Subscript>"EnsLib.Printing.ZENReportsPrintRequest.Parameters"</Subscript>
</Data>
<Data name="ZENReportsPrintRequestDefaultData">
<Subscript>"ZENReportsPrintRequest"</Subscript>
<Value name="1">
<Value>Classname</Value>
</Value>
<Value name="2">
<Value>ClassName</Value>
</Value>
<Value name="3">
<Value>ReportMode</Value>
</Value>
</Data>
<DefaultData>ZENReportsPrintRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
