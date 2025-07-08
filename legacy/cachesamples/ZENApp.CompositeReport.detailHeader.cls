/// This is an example detail header reusable component. A nice enhancement to this
/// would be to make statistic into a list of statistics, with caption attributes. 
/// The actual computation of the statistics is accomplished before running the
/// Display transformations.
Class ZENApp.CompositeReport.detailHeader Extends %ZEN.Report.Display.composite [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/zen/report/display/2.0/sample";

Property seller As %ZEN.Datatype.string;

Property sellerCaption As %ZEN.Datatype.string;

Property numTransactions As %ZEN.Datatype.string;

Property numTransactionsCaption As %ZEN.Datatype.string;

Property subtotal As %ZEN.Datatype.string;

Property subtotalCaption As %ZEN.Datatype.string;

Property statistic As %ZEN.Datatype.string;

Property statisticCaption As %ZEN.Datatype.string;

/// this demponstrates Report Template Expressions. Any template property may
/// be used as an attribute value using the following syntax:
///  attribute="#(..property)#"
/// These property values are processed when the template is
/// included in the page.
XData Display [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<composite xmlns="http://www.intersystems.com/zen/report/display"
		xmlns:my="http://www.intersystems.com/zen/report/display/2.0/sample">
<!-- SALES REP INFO -->
<header>
<line pattern="empty"/>
<table orient="row" width="3.8in" class='table2'>
<item field="#(..seller)#" width="2in"><caption value="#(..sellerCaption)#" width="2in"/></item>
<item field="#(..numTransactions)#"><caption value="#(..numTransactionsCaption)#"/></item>
<item field="#(..subtotal)#" formatNumber='###,###,##0.00;(#)'><caption value="#(..subtotalCaption)#"/></item>
</table>
<line pattern="empty"/>


<!-- AVERAGE/DEVIATION -->
<table orient="col" width="6in" style="border:thin solid gray;" class="invisible">
<table orient="row" width="3in" style="margin-bottom:1em;padding-left:0;" class="table1" align="left">
<item field="#(..statistic)#" class="table1" style="margin-bottom:1em;padding-left:3px;" width="1.7in" formatNumber='###,###,##0.000;(#)'><caption value="#(..statisticCaption)#" style="width:1.3in"/></item>
</table>
</table>
</header>
</composite>
}

}

