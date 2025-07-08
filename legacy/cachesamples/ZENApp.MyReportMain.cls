/// Version of MyReport that uses the <call> element
/// Duplicates MyReport ReportDefinition XData block.
/// Uses <call> only in the ReportDisplay XData block.
/// Does not use the subreportname attribute in <call>
Class ZENApp.MyReportMain Extends %ZEN.Report.reportPage
{

/// Author of the report.
Property ReportAuthor As %String [ InitialExpression = "BOB" ];

/// Month (1 to 12) to run this report for. "" for all months.
Property Month As %Integer(MAXVAL = 12, MINVAL = 1, ZENURL = "MONTH");

Parameter XSLTMODE = "server";

/// XML that defines the contents of this report.
XData ReportDefinition [ XMLNamespace = "http://www.intersystems.com/zen/report/definition" ]
{
<report xmlns="http://www.intersystems.com/zen/report/definition"
name='myReport'
sql="SELECT ID,Customer,Num,SalesRep,SaleDate 
	FROM ZENApp_Report.Invoice 
	WHERE (Month(SaleDate) = ?) OR (? IS NULL)
	ORDER BY SalesRep,SaleDate">
<parameter expression='..Month'/>
<parameter expression='..Month'/>
<attribute name='runTime' expression='$ZDT($H,3)' />
<attribute name='runBy' expression='$UserName' />
<attribute name='author' expression='..ReportAuthor' />
<aggregate name='grandTotal' type="SUM" field='Num' />
<attribute name='month' expression='..GetMonth()' />
<group name='SalesRep' breakOnField='SalesRep'>
<attribute name='name' field='SalesRep' />
<aggregate name='count' type="COUNT" field='Num' />
<aggregate name='subtotal' type="SUM" field='Num' />
<aggregate name='avg' type="AVG" field='Num' />
<group name="record">
<attribute name='id' field='ID' />
<attribute name='number' field='Num' />
<element name='date' field='SaleDate' />
<element name='customer' field='Customer' />
</group>
</group>
</report>
}

/// XML description for the display of this report. Used to generate
/// XSlT stylesheets for both HTML and XSL-FO
XData ReportDisplay [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<report xmlns="http://www.intersystems.com/zen/report/display" 
name='myReport' title='HelpDesk Sales Report' style='standard'>
<body>
<header> 
<!-- Combined REPORT HEADER -->
<p class="banner1">HelpDesk: Summary and Detail Reports</p>
<fo><line pattern="empty"/><line pattern="empty"/></fo>
</header>

<call method="GetSummary" subreport="SummaryReport" />

<call method="GetDetail" subreport="DetailReport" />

</body>	
</report>
}

/// Method for ReportDisplay from Summary report
Method GetSummary(mode) As %GlobalCharacterStream [ ProcedureBlock = 0 ]
{
 set (tSC,rpt,stream)=""
 set rpt=##class(ZENApp.MyReportSummary).%New()
 if rpt {
   set rpt.SubReport="SummaryReport" 
    set tSC=rpt.GenerateStream(.stream,mode)
 }
 if $$$ISERR(tSC) {set stream=""}
 quit stream
}

///  Method for ReportDisplay from Full report
Method GetDetail(mode) As %GlobalCharacterStream [ ProcedureBlock = 0 ]
{
 set (tSC,rpt,stream)=""
 set rpt=##class(ZENApp.MyReport).%New()
 if rpt {
    set rpt.SubReport="DetailReport" 
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

