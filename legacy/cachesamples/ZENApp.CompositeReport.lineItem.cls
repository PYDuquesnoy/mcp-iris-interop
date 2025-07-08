/// This is an example of how to create a line item report composite. Even though using
/// the primitive Zen Report Display components is not too complicated, it is a lot of 
/// detail in the high-level report display block that can be more easily reused and
/// maintained. The composite Display block may be changed without recompiling the Report
/// Display itself.
Class ZENApp.CompositeReport.lineItem Extends %ZEN.Report.Display.composite [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/zen/report/display/2.0/sample";

Property lineItem As %ZEN.Datatype.string;

Property lineItemCaption As %ZEN.Datatype.string;

Property date As %ZEN.Datatype.string;

Property purchaser As %ZEN.Datatype.string;

Property purchaserCaption As %ZEN.Datatype.string;

Property amount As %ZEN.Datatype.string;

Property subtotal As %ZEN.Datatype.string;

/// this demponstrates Report Template Expressions. Any template property may
/// be used as an attribute value using the following syntax:
///  attribute="#(property)#"
/// These property values are processed when the template is
/// included in the page.
XData Display [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<composite xmlns="http://www.intersystems.com/zen/report/display"
		xmlns:my="http://www.intersystems.com/zen/report/display/2.0/sample">
<table orient="col" group="record" width="6in" class="table4" altcolor="#DFDFFF">
<item special="number" width=".45in" style="color: darkblue;">
<caption value="#" />
</item>
<item field="#(..lineItem)#" width=".7in" style="border:none;padding-right:4px">
<caption value="#(..lineItemCaption)#"/>
</item>
<item field="#(..date)#" width="1.5in" style="padding-left: 4px;">
<caption value="Date"/>
</item>
<item field="#(..purchaser)#" width="2.65in">
<caption value="#(..purchaserCaption)#"/>
</item>
<item caption="Amount" width=".7in" style="text-align:right;" field="#(..amount)#" formatNumber='###,###,##0.00;(#)'>
<caption value="Amount"/>
<summary field="#(..subtotal)#" style="font-weight:bold;text-align:right" formatNumber='###,###,##0.00;(#)'/>
</item>
</table>
</composite>
}

}

