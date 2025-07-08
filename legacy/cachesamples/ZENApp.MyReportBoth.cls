/// Test case for Zen Report.
/// Uses <call> in BOTH the ReportDisplay and the ReportDefinition XData blocks.
/// This main report combines two independent reports.
/// Each subreport extracts different data, and formats it differently
/// Works OK for HTML, doesn't work for PDF because of 'rooted' issue
/// which is fixed in 2011, but present in 2010
Class ZENApp.MyReportBoth Extends %ZEN.Report.reportPage
{

/// Author of the report.
Property ReportAuthor As %String [ InitialExpression = "BOB" ];

/// Month (1 to 12) to run this report for. "" for all months.
Property Month As %Integer(MAXVAL = 12, MINVAL = 1, ZENURL = "MONTH");

Parameter XSLTMODE = "server";

Parameter DEFAULTMODE = "html";

/// XML that defines the contents of this report.
XData ReportDefinition [ XMLNamespace = "http://www.intersystems.com/zen/report/definition" ]
{
<report xmlns="http://www.intersystems.com/zen/report/definition"
name='myReport' runonce="true">
<attribute name='runTime' expression='$ZDT($H,3)' />
<attribute name='month' expression='..GetMonth()' />
<attribute name='author' expression='..ReportAuthor' />
<attribute name='runBy' expression='$UserName' />
<call method="GetSubDaily" />
<call method="GetSubRep" />
</report>
}

/// XML description for the display of this report. Used to generate
/// XSlT stylesheets for both HTML and XSL-FO
XData ReportDisplay [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<report xmlns="http://www.intersystems.com/zen/report/display" 
name='myReport' title='HelpDesk Combined Sales Report' style='standard'>
<document width="8.5in" height="11in" marginLeft="1.25in" marginRight="1.25in" marginTop="1.0in" marginBottom="1.0in">
</document>

<body>
<header> 
<!-- COMBINED REPORT HEADER -->
<p class="banner1">HelpDesk Combined Sales Report</p>
<fo><line pattern="empty"/><line pattern="empty"/></fo>
<table orient="row" width="3.45in" class='table1'> 
<item value="Combined Sales" width="2in">
<caption value="Title:" width="1.35in"/>
</item>
<item field="@month" caption="Month:"/>
<item field="@author" caption="Author:"/>
<item field="@runBy" caption="Prepared By:"/>
<item field="@runTime" caption="Time:"/>
</table>
</header>

<call method="GetSubDailyDspl" subreport="DailyReport" subreportname="myReportByDay" />
<call method="GetSubRepDspl" subreport="RepReport" subreportname="myReportByRep" />

</body>
</report>
}

/// Method for ReportDefinition from Daily report
Method GetSubDaily() As %GlobalCharacterStream [ ProcedureBlock = 0 ]
{
 set (tSC,rpt,stream)=""
 set rpt=##class(ZENApp.MyReportByDay).%New()
 i rpt {
     set tSC=rpt.GenerateStream(.stream,0)
 }
 if $$$ISERR(tSC) {set stream=""}
 quit stream
}

/// Method for ReportDisplay from Daily report
Method GetSubDailyDspl(mode) As %GlobalCharacterStream [ ProcedureBlock = 0 ]
{
 set (tSC,rpt,stream)=""
 set rpt=##class(ZENApp.MyReportByDay).%New()
 if rpt {
   set rpt.SubReport="DailyReport"
   set rpt.MainReport="myReport" 
   set tSC=rpt.GenerateStream(.stream,mode)
 }
 if $$$ISERR(tSC) {set stream=""}
 quit stream
}

/// Method for ReportDefinition from Sales Rep report
Method GetSubRep() As %GlobalCharacterStream [ ProcedureBlock = 0 ]
{
 set (tSC,rpt,stream)=""
 set rpt=##class(ZENApp.MyReportByRep).%New()
 i rpt {
     set tSC=rpt.GenerateStream(.stream,0)
 }
 if $$$ISERR(tSC) {set stream=""}
 quit stream
}

///  Method for ReportDisplay from Sales Rep report
Method GetSubRepDspl(mode) As %GlobalCharacterStream [ ProcedureBlock = 0 ]
{
 set (tSC,rpt,stream)=""
 set rpt=##class(ZENApp.MyReportByRep).%New()
 if rpt {
    set rpt.SubReport="RepReport" 
    set rpt.MainReport="myReport" 
    set tSC=rpt.GenerateStream(.stream,mode)
 }
 if $$$ISERR(tSC) {set stream=""}
 quit stream
}

/// Return a formatted version of the month property.
Method GetMonth() As %String
{
	If (..Month="") Quit "ALL"
	
	#; convert to month name:
	Set tDT = "2006-"_$TR($J(..Month,2)," ","0")_"-01"
	Set tDT = $ZDTH(tDT,3) // convert to $H
	Set tDT = $ZDT(tDT,5) // convert to MMM format
	Quit $E(tDT,1,3)
}

}

