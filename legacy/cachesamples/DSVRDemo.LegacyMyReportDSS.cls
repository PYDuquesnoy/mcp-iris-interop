/// DSVR DSS module interfacing to MyReport of SAMPLES
Class DSVRDemo.LegacyMyReportDSS Extends %DeepSee.Report.dataSchemaInterface
{

Parameter DEFAULTMODE = "xml";

Parameter XSLTMODE = "server";

XData ReportDSS
{
<reportDSS>
<![CDATA[

{t:"r",n:"myReport",dataCollector:"ZENApp.MyReport",a:[
{t:"a",n:"runTime"},
{t:"a",n:"runBy"},
{t:"a",n:"author"},
{t:"a",n:"month"}],i:[
{t:"i",n:"grandTotal"},
{t:"g",n:"SalesRep",a:[
{t:"a",n:"name"}],i:[
{t:"i",n:"count"},
{t:"i",n:"subtotal"},
{t:"i",n:"avg"},
{t:"g",n:"record",a:[
{t:"a",n:"id"},
{t:"a",n:"number"}],i:[
{t:"i",n:"date"},
{t:"i",n:"customer"}]}]}]}
]]></reportDSS>
}

}

