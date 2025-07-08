/// This component just presents a simple name-value pair. The reason that
/// this is called a footer, is that the report Display XML should be as human
/// readable as possible when using the composite paradigm. Further, a separate
/// custom group component could be used to enforce that certain report components
/// are place in a particular type of report.
Class ZENApp.CompositeReport.reportFooter Extends %ZEN.Report.Display.composite [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/zen/report/display/2.0/sample";

Property caption As %ZEN.Datatype.caption;

Property information As %ZEN.Datatype.string;

/// this demponstrates Report Template Expressions. Any template property may
/// be used as an attribute value using the following syntax:
///  attribute="#(property)#"
/// These property values are processed when the template is
/// included in the page.
XData Display [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{
<composite xmlns="http://www.intersystems.com/zen/report/display"
		xmlns:my="http://www.intersystems.com/zen/report/display/2.0/sample">
<table orient="row" class="table1" width="2.5in">
<item  caption="#(%composite.caption)#" field="#(%composite.information)#" />
</table>
</composite>
}

}

