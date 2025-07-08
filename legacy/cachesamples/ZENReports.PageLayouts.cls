/// Test case for Zen Report.
Class ZENReports.PageLayouts Extends %ZEN.Report.reportPage
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
<report xmlns="http://www.intersystems.com/zen/report/definition" name='myReport' runonce="true">
<attribute name='runTime' expression='$ZDT($H,3)' />
<attribute name='runBy' expression='$UserName' />
<attribute name='author' expression='..ReportAuthor' />
<group name='Sales' sql="SELECT ID,Customer,Num,SalesRep,SaleDate 
	FROM ZENApp_Report.Invoice 
	WHERE (Month(SaleDate) = ?) OR (? IS NULL)
	ORDER BY SalesRep,SaleDate">
<parameter expression='..Month'/>
<parameter expression='..Month'/>
<attribute name='month' expression='..GetMonth()' />
<aggregate name='grandTotal' type="SUM" field='Num' />
<group name="SalesRep" breakOnField="SalesRep">
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
</group>
<group name="ByNumber" sql="SELECT ID,Customer,Num,SalesRep,SaleDate 
	FROM ZENApp_Report.Invoice 
	WHERE ((Month(SaleDate) = ?) OR (? IS NULL)) AND (Num > 0)
	ORDER BY Num,Customer">
<parameter expression='..Month'/>
<parameter expression='..Month'/>
<group name="NumbRecs" breakOnField="Num">
<attribute name='number' field='Num' />
<group name="record">
<attribute name='id' field='ID' />
<attribute name='name' field='SalesRep' />
<element name='date' field='SaleDate' />
<element name='customer' field='Customer' />
</group>
</group>
</group>
<group name="ByDate" sql="SELECT ID,Customer,Num,SaleDate 
	FROM ZENApp_Report.Invoice 
	WHERE ((Month(SaleDate) = ?) OR (? IS NULL)) AND (Num = 0)
	ORDER BY SaleDate">
<parameter expression='..Month'/>
<parameter expression='..Month'/>
<group name="DateRecs"  breakOnField="SaleDate">
<attribute name='date' field='SaleDate' />
<group name="record">
<attribute name='id' field='ID' />
<element name='number' field='Num' />
<element name='customer' field='Customer' />
</group>
</group>
</group>
</report>
}

/// XML description for the display of this report. Used to generate
/// XSlT stylesheets for both HTML and XSL-FO
XData ReportDisplay [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<report xmlns="http://www.intersystems.com/zen/report/display" name='myReport' 
title='HelpDesk Sales Report' style='standard' >

<section name="myReport" sectionName="Sales" primaryGroup="Sales/SalesRep">
<pagemaster>
<masterreference masterReference="first" pagePosition="first">
<document width="8.5in" height="11in" 
marginLeft="1.25in" marginRight="1.25in"
 marginTop="1.0in" marginBottom="1.0in" headerHeight="2.0in">
</document>
<pageheader>
<p class="banner1">HelpDesk Sales Report</p>
<fo><line pattern="empty"/><line pattern="empty"/></fo>
<table orient="row" width="3.5in" class='table1'>
<item value="Sales by Sales Rep" width="2in">
<caption value="Title:" width="1.35in"/>
</item>
<item field="/myReport/Sales/@month" caption="Month:"/>
<item field="/myReport/@author" caption="Author:"/>
<item field="/myReport/@runBy" caption="Prepared By:"/>
<item field="/myReport/@runTime" caption="Time:"/>
</table>
</pageheader>
</masterreference>
<masterreference masterReference="rest" pagePosition="rest">
<document width="8.5in" height="11in" marginLeft="1.25in" 
marginRight="1.25in" marginTop="1.0in" 
marginBottom="1.0in" headerHeight=".75in">
</document>
<pageheader>
<table orient="col" layout="fixed" width="6in">
<item style="text-align:left" value="Sales Report" /> 
<item style="text-align:right" special="page-number-of-with-xpath" field="@name" />
</table>
</pageheader>
</masterreference>
</pagemaster>
<body genLastPageIdOn="@name">
<group name="Sales/SalesRep" primaryGroup="true">
<!-- SALES REP INFO -->
<header>
<line pattern="empty"/>
<table orient="row" width="3.8in" class='table2'>
<item field="@name" width="2in"><caption value="Sales Rep:" width="2in"/></item>
<item field="count"><caption value="Number of Sales:"/></item>
<item field="subtotal" formatNumber='###,###,##0.00;(#)'><caption value="Total Value of Sales:"/></item>
</table>
<line pattern="empty"/>


<!-- AVERAGE/DEVIATION -->
<table orient="col" width="6in" style="border:thin solid gray;" class="invisible">
<table orient="row" width="3in" style="margin-bottom:1em;padding-left:0;" class="table1" align="left">
<item field="avg" class="table1" style="margin-bottom:1em;padding-left:3px;" width="1.7in" formatNumber='###,###,##0.000;(#)'><caption value="Average Sale:" style="width:1.3in"/></item>
</table>
</table>
</header>

<!-- TABLE OF SALES -->
<table orient="col" group="record" width="6in" class="table4" altcolor="#DFDFFF" oldSummary="false">
<item special="number" width=".45in" style="color: darkblue;">
<caption value="#" />
</item>
<item field="@id" width=".7in" style="border:none;padding-right:4px">
<caption value="Sale ID"/>
</item>
<item field="date" width="1.5in" style="padding-left: 4px;">
<caption value="Date"/>
</item>
<item field="customer" width="2.65in">
<caption value="Customer"/>
</item>
<item caption="Amount" width=".7in" style="text-align:right;" field="@number" formatNumber='###,###,##0.00;(#)'>
<caption value="Amount"/>
<summary style="font-style:italic;text-align:right;background-color:yellow" value=" "/>
<summary style="font-style:italic;text-align:right;background-color:purple" value=" "/>
<summary style="font-style:italic;text-align:right;background-color:orange" value=" "/>
<summary field="subtotal" style="font-style:italic;text-align:right;background-color:blue" formatNumber='###,###,##0.00;(#)'/>
<summary field="subtotal" style="font-weight:bold;text-align:right;background-color:red" formatNumber='###,###,##0.00;(#)'/>
</item>
</table>
</group>
</body>	
</section>
<section name="myReport" sectionName="ByNumber" primaryGroup="ByNumber" >
<pagemaster>
<masterreference masterReference="first" pagePosition="first">
<document width="8.5in" height="11in" marginLeft="1.25in" marginRight="1.25in" 
marginTop="1.0in" marginBottom="1.0in" headerHeight="1.0in" footerHeight="1.0in">
</document>
<pageheader>
<p class="banner1">Sales Report: Number of Sales</p>
</pageheader>
<pagefooter>
<table orient="col" layout="fixed" width="6in">
<item style="text-align:left" value="Sales Report" /> 
<item style="text-align:right" special="page-number-of-with-xpath" field="NumbRecs" />
</table>
</pagefooter>
</masterreference>
<masterreference masterReference="rest" pagePosition="rest">
<document width="8.5in" height="11in" marginLeft="1.25in" marginRight="1.25in" 
marginTop="1.0in" marginBottom="1.0in" footerHeight="1.0in">
</document>
<pageheader>
</pageheader>
<pagefooter>
<table orient="col" layout="fixed" width="6in">
<item style="text-align:left" value="Sales Report" /> 
<item style="text-align:right" special="page-number-of-with-xpath" field="NumbRecs" />
</table>
</pagefooter>
</masterreference>
<masterreference masterReference="last" pagePosition="last">
<document width="8.5in" height="11in" marginLeft="1.25in" marginRight="1.25in" 
marginTop="1.0in" marginBottom="1.0in" footerHeight="2.0in">
</document>
<pageheader>	
</pageheader>
<pagefooter>
<table orient="row" class="table1" width="2.5in">
<item caption="Grand Total:" field="/myReport/Sales/grandTotal" />
</table>
<fo><line pattern="empty"/><line pattern="empty"/></fo>
<table orient="col" layout="fixed" width="6in">
<item style="text-align:left" value="Sales Report" /> 
<item style="text-align:right" special="page-number-of-with-xpath" field="NumbRecs" />
</table>
</pagefooter>
</masterreference>
</pagemaster>
<body genLastPageIdOn="NumbRecs">
<!-- MAIN REPORT GROUP -->
<group name="ByNumber" primaryGroup="true">
<group name="NumbRecs" pagebreak="true" >

<!-- SALES REP INFO -->
<header>
<line pattern="empty"/>
<table orient="row" width="3.8in" class='table2'>
<item field="@number" width="2in"><caption value="Number of Sales:" width="2in"/></item>
</table>
<line pattern="empty"/>
</header>

<!-- TABLE OF SALES -->
<table orient="col" group="record" width="6in" class="table4" altcolor="#DFDFFF" oldSummary="false">
<item special="number" width=".4in" style="color: darkblue;">
<caption value="#" />
</item>
<item field="@id" width=".6in" style="border:none;padding-right:4px">
<caption value="Sale ID"/>
</item>
<item field="date" width="1.5in" style="padding-left: 4px;">
<caption value="Date"/>
</item>
<item field="customer" width="2.5in">
<caption value="Customer"/>
</item>
<item field="@name" width="1in">
<caption value="Sales Rep" width="2in"/>
</item>
</table>
</group>
</group>
</body>	
</section>
<section name="myReport" sectionName="ByDate" primaryGroup="ByDate" >
<pagemaster>
<masterreference masterReference="NumbA" pagePosition="any">
<document width="8.5in" height="11in" marginLeft="1.25in" marginRight="1.25in" 
marginTop="1.0in" marginBottom="1.0in" headerHeight="1.0in" footerHeight="1.0in">
</document>
<pageheader>
<p class="banner1">Sales Report: Date of Sale</p>
</pageheader>
<pagefooter>
<table orient="col" layout="fixed" width="6in">
<item style="text-align:left" value="Sales Report" /> 
<item style="text-align:right" special="page-number-of-with-xpath" field="DateRecs" />
</table>
</pagefooter>
</masterreference>
</pagemaster>
<body genLastPageIdOn="DateRecs">
<!-- MAIN REPORT GROUP -->
<group name="ByDate" primaryGroup="true">
<group name="DateRecs">
<foblock keepCondition="keep-together.within-page='always'">
<!-- SALES REP INFO -->
<header>
<line pattern="empty"/>
<table orient="row" width="4in" class='table2'>
<item field="@date" width="2in"><caption value="Date of Sales:" width="2in"/></item>
</table>
<line pattern="empty"/>
</header>

<!-- TABLE OF SALES -->
<table orient="col" group="record" width="4in" class="table4" altcolor="#DFDFFF" oldSummary="false">
<item special="number" width=".4in" style="color: darkblue;">
<caption value="#" />
</item>
<item field="@id" width=".6in" style="border:none;padding-right:4px">
<caption value="Sale ID"/>
</item>
<item field="customer" width="3in">
<caption value="Customer"/>
</item>
</table>
</foblock>
</group>
</group>
</body>	
</section>
</report>
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

