/// Test case for Zen Report based on composite components.
/// TODO: a future enhancement to this sample will show how to
/// enforce the inclusion of certain report elements. For example,
/// some organization require standard header and footer elements.
/// Commonly these components may have variations depending on page
/// size or type of report.
Class ZENApp.CompositeReport Extends %ZEN.Report.reportPage
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
<report xmlns="http://www.intersystems.com/zen/report/display" xmlns:my="http://www.intersystems.com/zen/report/display/2.0/sample"
name='myReport' title='HelpDesk Sales Report' style='standard'>
<document width="8.5in" height="11in" marginLeft="1.25in" marginRight="1.25in" marginTop="1.0in" marginBottom="1.0in">
</document>

<body>

<my:reportHeader infoSeparator="line:2">
	<!-- REPORT HEADER -->
	<my:reportTitle>#(%display.title)#</my:reportTitle>
	<my:reportSubtitle>Sales by Sales Rep</my:reportSubtitle>
	<my:reportInfo
		month="@month"
		author="@author"
		runBy="@runBy"
		runTime="@runTime"
	/>
</my:reportHeader>

<!-- MAIN REPORT GROUP -->
<group name="SalesRep" pagebreak="true" line='1px'>
<my:detailHeader seller="@name" sellerCaption="Sales Rep:"
				numTransactions="count" numTransactionsCaption="Number of Sales:"
				subtotal="subtotal" subtotalCaption="Total Value of Sales:"
				statistic="avg" statisticCaption="Average Sale:"
/>
<!-- TABLE OF SALES -->
<my:lineItem lineItem="@id" lineItemCaption="Sale ID" 
			date="date"
			purchaser="customer" purchaserCaption="Customer"
			amount="@number"
			subtotal="subtotal"
/>
</group>

<!-- FOOTER -->
<my:reportFooter
	caption="Grand Total:"
	information="grandTotal"
	/>
</body>	
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

