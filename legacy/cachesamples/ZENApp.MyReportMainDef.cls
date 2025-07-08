/// Example: using the <call> element 
/// Uses <call> only in the ReportDefinition XData block.
/// Calls ZENApp.MyReport to get XML, generates summary report.
/// Works OK for HTML, doesn't work for PDF because of 'rooted' issue
/// which is fixed in 2011, but present in 2010
Class ZENApp.MyReportMainDef Extends %ZEN.Report.reportPage
{

/// Author of the report.
Property ReportAuthor As %String [ InitialExpression = "BOB" ];

/// Month (1 to 12) to run this report for. "" for all months.
Property Month As %Integer(MAXVAL = 12, MINVAL = 1, ZENURL = "MONTH");

Parameter XSLTMODE = "server";

Parameter DEFAULTMODE = "pdf";

/// XML that defines the contents of this report.
XData ReportDefinition [ XMLNamespace = "http://www.intersystems.com/zen/report/definition" ]
{
<report xmlns="http://www.intersystems.com/zen/report/definition"
name='Report' runonce="true">

<call method="GetSub" />

</report>
}

/// XML description for the display of this report. Used to generate
/// XSlT stylesheets for both HTML and XSL-FO
XData ReportDisplay [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<report xmlns="http://www.intersystems.com/zen/report/display" 
name='Report' title='HelpDesk Sales Report' style='standard'>
<document width="8.5in" height="11in" marginLeft="1.25in" marginRight="1.25in" marginTop="1.0in" marginBottom="1.0in">
</document>

<body>
<group name="myReport">
<header> 
<!-- REPORT HEADER -->
<p class="banner1">HelpDesk Sales Report: Summary</p>
<fo><line pattern="empty"/><line pattern="empty"/></fo>
<table orient="row" width="3.45in" class='table1'>
<item value="Sales by Sales Rep" width="2in">
<caption value="Title:" width="1.35in"/>
</item>
<item field="@month" caption="Month:"/>
<item field="@author" caption="Author:"/>
<item field="@runBy" caption="Prepared By:"/>
<item field="@runTime" caption="Time:"/>
</table>
</header>

<!-- MAIN REPORT GROUP -->
<group name="SalesRep">

<!-- SALES REP INFO -->
<header>
<line pattern="empty"/>
<table orient="row" width="3.8in" class='table2'>
<item field="@name" width="2in"><caption value="Sales Rep:" width="2in"/></item>
<item field="count"><caption value="Number of Sales:"/></item>
<item field="subtotal" formatNumber='###,###,##0.00;(#)'><caption value="Total Value of Sales:"/></item>
<item field="avg" formatNumber='###,###,##0.000;(#)'><caption value="Average Sale:"/></item> 
</table>
<line pattern="empty"/>
</header>


</group>

<!-- FOOTER -->
<table orient="row" class="table1" width="2.5in">
<item caption="Grand Total:" field="grandTotal" />
</table>
</group>
</body>	
</report>
}

/// Method for ReportDefinition from Daily report
Method GetSub() As %GlobalCharacterStream
{
 set stream=""
 set rpt=##class(ZENApp.MyReport).%New()
 i $isobject(rpt) 
 {
     set tSC=rpt.GenerateStream(.stream,0)
 }
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

