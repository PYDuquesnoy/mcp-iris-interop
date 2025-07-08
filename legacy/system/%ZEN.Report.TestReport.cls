/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// 
/// Test case for Zen Report.
Class %ZEN.Report.TestReport Extends (%Persistent, %ZEN.Report.reportPage) [ CompileAfter = (%ZEN.Report.Display.document, %ZEN.Report.Display.report, %ZEN.Report.element, %ZEN.Report.group, %ZEN.Report.parameter, %ZEN.Report.PrintServer, %ZEN.Report.RecordCounter, %ZEN.Report.report, %ZEN.Report.reportGenerator, %ZEN.Report.reportLauncher, %ZEN.Report.reportNode, %ZEN.Report.reportPage, %ZEN.Report.reportSchema, %ZEN.Report.SASchema, %ZEN.Report.Display.att, %ZEN.Report.Display.atthtml, %ZEN.Report.Display.attxslfo, %ZEN.Report.Display.block, %ZEN.Report.Display.body, %ZEN.Report.Display.caption, %ZEN.Report.Display.category, %ZEN.Report.Display.childrenNode, %ZEN.Report.Display.class, %ZEN.Report.Display.container, %ZEN.Report.Display.group, %ZEN.Report.Display.header, %ZEN.Report.Display.p), DependsOn = (%ZEN.Report.Display.document, %ZEN.Report.Display.report, %ZEN.Report.element, %ZEN.Report.group, %ZEN.Report.parameter, %ZEN.Report.PrintServer, %ZEN.Report.RecordCounter, %ZEN.Report.report, %ZEN.Report.reportGenerator, %ZEN.Report.reportLauncher, %ZEN.Report.reportNode, %ZEN.Report.reportPage, %ZEN.Report.reportSchema, %ZEN.Report.SASchema, %ZEN.Report.Display.att, %ZEN.Report.Display.atthtml, %ZEN.Report.Display.attxslfo, %ZEN.Report.Display.block, %ZEN.Report.Display.body, %ZEN.Report.Display.caption, %ZEN.Report.Display.category, %ZEN.Report.Display.childrenNode, %ZEN.Report.Display.class, %ZEN.Report.Display.container, %ZEN.Report.Display.group, %ZEN.Report.Display.header, %ZEN.Report.Display.p), Deprecated, Inheritance = right, System = 4 ]
{

XData ReportDefinition [ XMLNamespace = "http://www.intersystems.com/zen/report/definition" ]
{
<report xmlns="http://www.intersystems.com/zen/report/definition" sql="select %ID FROM %ZEN_Report.TestReport" name="myReport">
<group name="test"/>
</report>
}

Parameter DEFAULTMODE = "pdf";

/// XML description for the display of this report. Used to generate
/// XSlT stylesheets for both HTML and XSL-FO
XData ReportDisplay [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<report xmlns="http://www.intersystems.com/zen/report/display" 
name='myReport' title='Sales Report' style='standard'> 

<document width="8.5in" height="11in" marginLeft="0.50in" marginRight="0.50in" marginTop=".5in" marginBottom="0.5in" > 

</document> 

<body > 
<header> 

<!-- REPORT HEADER --> 

<!-- REPORT HEADER -->
<table width="100%" orient="row"  > <item value="Sales Report" width="3in" />

 </table>


</header> 
<inline> 
This is a test. 
</inline> 
<inline style="font-size:14pt"> 
 14 point text 
</inline> 
<p></p>
</body>
</report>
}

Storage Default
{
<Data name="TestReportDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>%disableBreak</Value>
</Value>
<Value name="3">
<Value>Datasource</Value>
</Value>
<Value name="4">
<Value>ReportXMLNameSpace</Value>
</Value>
<Value name="5">
<Value>ReportXMLNameSpacePrefix</Value>
</Value>
<Value name="6">
<Value>XsltVersion</Value>
</Value>
<Value name="7">
<Value>tohtmlstream</Value>
</Value>
<Value name="8">
<Value>toxslfostream</Value>
</Value>
<Value name="9">
<Value>xmlstream</Value>
</Value>
<Value name="10">
<Value>ReportDir</Value>
</Value>
<Value name="11">
<Value>RenderTimeOut</Value>
</Value>
<Value name="12">
<Value>TimeOut</Value>
</Value>
<Value name="13">
<Value>%display</Value>
</Value>
<Value name="14">
<Value>StripPI</Value>
</Value>
<Value name="15">
<Value>SubReport</Value>
</Value>
<Value name="16">
<Value>MainReport</Value>
</Value>
<Value name="17">
<Value>TooLongText</Value>
</Value>
<Value name="18">
<Value>SuppressExcelHeaders</Value>
</Value>
<Value name="19">
<Value>toexcelstream</Value>
</Value>
<Value name="20">
<Value>TableAltColor</Value>
</Value>
<Value name="21">
<Value>SplitAndMerge</Value>
</Value>
<Value name="22">
<Value>RepeatingElement</Value>
</Value>
<Value name="23">
<Value>CountRepeatingElement</Value>
</Value>
<Value name="24">
<Value>CheckPDFNotZeroLength</Value>
</Value>
<Value name="25">
<Value>SplitOnly</Value>
</Value>
<Value name="26">
<Value>SplitDir</Value>
</Value>
<Value name="27">
<Value>SplitRootName</Value>
</Value>
<Value name="28">
<Value>OutputFileName</Value>
</Value>
<Value name="29">
<Value>UseRawIOForXML</Value>
</Value>
<Value name="30">
<Value>DefaultFontFaceCopyHTML</Value>
</Value>
<Value name="31">
<Value>DefaultFontSizeCopyHTML</Value>
</Value>
<Value name="32">
<Value>SetProcessWideRunTimeMode</Value>
</Value>
<Value name="33">
<Value>isServer</Value>
</Value>
<Value name="34">
<Value>isHTML5</Value>
</Value>
<Value name="35">
<Value>xmlfile</Value>
</Value>
<Value name="36">
<Value>OptionLang</Value>
</Value>
<Value name="37">
<Value>OptionNoComplexScript</Value>
</Value>
<Value name="38">
<Value>OptionRelaxed</Value>
</Value>
<Value name="39">
<Value>OptionDPI</Value>
</Value>
<Value name="40">
<Value>OptionOwnerPassword</Value>
</Value>
<Value name="41">
<Value>OptionUserPassword</Value>
</Value>
<Value name="42">
<Value>OptionNoPrint</Value>
</Value>
<Value name="43">
<Value>OptionNoCopy</Value>
</Value>
<Value name="44">
<Value>OptionNoEdit</Value>
</Value>
<Value name="45">
<Value>OptionNoAnnotations</Value>
</Value>
<Value name="46">
<Value>OptionNoFillInForms</Value>
</Value>
<Value name="47">
<Value>OptionNoAccessContent</Value>
</Value>
<Value name="48">
<Value>OptionNoAssembleDoc</Value>
</Value>
<Value name="49">
<Value>OptionNoPrintHq</Value>
</Value>
<Value name="50">
<Value>OptionEnableAccessibility</Value>
</Value>
<Value name="51">
<Value>OptionPDFProfile</Value>
</Value>
<Value name="52">
<Value>OptionConserve</Value>
</Value>
<Value name="53">
<Value>OptionCachePath</Value>
</Value>
<Value name="54">
<Value>OptionFlush</Value>
</Value>
<Value name="55">
<Value>PrintServer</Value>
</Value>
<Value name="56">
<Value>PrintTimeOut</Value>
</Value>
<Value name="57">
<Value>ExcelServer</Value>
</Value>
<Value name="58">
<Value>ExcelServerTimeOut</Value>
</Value>
<Value name="59">
<Value>PS</Value>
</Value>
<Value name="60">
<Value>NamespaceDeclarations</Value>
</Value>
<Value name="61">
<Value>xmlstylesheet</Value>
</Value>
<Value name="62">
<Value>getxmlstylesheet</Value>
</Value>
<Value name="63">
<Value>xmlstylesheetarg</Value>
</Value>
<Value name="64">
<Value>UseHTML5</Value>
</Value>
<Value name="65">
<Value>UseSemaphore</Value>
</Value>
<Value name="66">
<Value>AggregatesIgnoreNLS</Value>
</Value>
<Value name="67">
<Value>SaxMemSize</Value>
</Value>
<Value name="68">
<Value>PDFMergeMemSize</Value>
</Value>
<Value name="69">
<Value>Mode</Value>
</Value>
<Value name="70">
<Value>FileLifeTime</Value>
</Value>
<Value name="71">
<Value>RenderConnectTimeOut</Value>
</Value>
<Value name="72">
<Value>ConnectTimeOut</Value>
</Value>
<Value name="73">
<Value>RenderDirectlyOnTimeout</Value>
</Value>
<Value name="74">
<Value>OldBehaviorLineFeedOnBreak</Value>
</Value>
</Data>
<DataLocation>^%ZEN.Report.TestReportD</DataLocation>
<DefaultData>TestReportDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%ZEN.Report.TestReportD</IdLocation>
<IndexLocation>^%ZEN.Report.TestReportI</IndexLocation>
<StreamLocation>^%ZEN.Report.TestReportS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
