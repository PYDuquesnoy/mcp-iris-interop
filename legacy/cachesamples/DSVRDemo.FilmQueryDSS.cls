/// undefined
Class DSVRDemo.FilmQueryDSS Extends %DeepSee.Report.sqlQueryDSS
{

Parameter DEFAULTMODE = "xml";

Parameter XSLTMODE = "server";

XData ReportDSS
{
<reportDSS>
<![CDATA[

{t:"r",n:"ListFilms",dataCollector:"DSVRDemo.FilmQueryDSS",a:[
{t:"a",n:"runTime"},
{t:"a",n:"runBy"}],i:[
{t:"g",n:"Results",i:[
{t:"i",n:"TotalCount"},
{t:"i",n:"AveAllTicketsSold"},
{t:"i",n:"MaxAllTicketsSold"},
{t:"i",n:"MinAllTicketsSold"},
{t:"i",n:"SumAllTicketsSold"},
{t:"g",n:"DataByCategoryName",a:[
{t:"a",n:"CategoryName"}],i:[
{t:"i",n:"GroupCount"},
{t:"i",n:"AveTicketsSoldByCategoryName"},
{t:"i",n:"MaxTicketsSoldByCategoryName"},
{t:"i",n:"MinTicketsSoldByCategoryName"},
{t:"i",n:"SumTicketsSoldByCategoryName"},
{t:"g",n:"Detail",a:[
{t:"a",n:"ID"}],i:[
{t:"i",n:"Title"},
{t:"i",n:"TicketsSold"},
{t:"i",n:"Description"},
{t:"i",n:"Length"},
{t:"i",n:"PlayingNow"},
{t:"i",n:"Rating"}]}]}]}]}
]]></reportDSS>
}

XData QueryInterfaceModel
{
<qiModel>
<![CDATA[

{headerInfo:
{type:"SQLDSS"},CLASS_NAME:"DSVRDemo.FilmSQL",PROCEDURE_TYPE:"query",METHOD_OR_QUERY_NAME:"ListFilms",NUMBER_INPUT_PARAMS:"0",NUMBER_INPUT_OUTPUT_PARAMS:"0",NUMBER_OUTPUT_PARAMS:"0",RETURN_VALUE:"",PROCEDURE_INTERFACE:"1",NUMBER_OF_COLUMNS:"8",INPUT_PARAMETERS:"",INPUT_OUTPUT_PARAMETERS:"",OUTPUT_PARAMETERS:"",RESULTSET_COLUMNS:"ID INTEGER, Title VARCHAR, TicketsSold INTEGER, CategoryName VARCHAR, Description VARCHAR, Length INTEGER, PlayingNow BIT, Rating VARCHAR",SCHEMA:"DSVRDemo",PROC_NAME:"FilmSQL_ListFilms",GROUPBY:[
{gFld:"CategoryName",gName:"CategoryName",gDown:0}],SORTBY:[
{cName:"Title",cDown:0}],FLDS:[
{cName:"ID",cType:"INTEGER",xName:"ID",isNum:false,cAggr:
{Count:1,Ave:0,Sum:0,Min:0,Max:0}},
{cName:"Title",cType:"VARCHAR",xName:"Title",isNum:false,cAggr:
{Count:0,Ave:0,Sum:0,Min:0,Max:0}},
{cName:"TicketsSold",cType:"INTEGER",xName:"TicketsSold",isNum:true,cAggr:
{Count:0,Ave:1,Sum:1,Min:1,Max:1}},
{cName:"CategoryName",cType:"VARCHAR",xName:"CategoryName",isNum:false,cAggr:
{Count:0,Ave:0,Sum:0,Min:0,Max:0}},
{cName:"Description",cType:"VARCHAR",xName:"Description",isNum:false,cAggr:
{Count:0,Ave:0,Sum:0,Min:0,Max:0}},
{cName:"Length",cType:"INTEGER",xName:"Length",isNum:true,cAggr:
{Count:0,Ave:0,Sum:0,Min:0,Max:0}},
{cName:"PlayingNow",cType:"BIT",xName:"PlayingNow",isNum:false,cAggr:
{Count:0,Ave:0,Sum:0,Min:0,Max:0}},
{cName:"Rating",cType:"VARCHAR",xName:"Rating",isNum:false,cAggr:
{Count:0,Ave:0,Sum:0,Min:0,Max:0}}]}
]]></qiModel>
}

/// XML that defines the contents of this report.
XData ReportDefinition [ XMLNamespace = "http://www.intersystems.com/zen/report/definition" ]
{
<report xmlns='http://www.intersystems.com/zen/report/definition'
	queryClass='DSVRDemo.FilmSQL' queryName='ListFilms' top='1' name='ListFilms'>
	<attribute name='runTime' expression='$ZDT($H,3)' />
	<attribute name='runBy' expression='$UserName' />
	<group name='Results' queryClass='DSVRDemo.FilmSQL' queryName='ListFilms'  orderby='CategoryName,Title' >
<aggregate name='TotalCount' type='CUSTOM' field='ID' class='%ZEN.Report.Aggregate.CountDistinct'/>
<aggregate name='AveAllTicketsSold' type='AVG' field='TicketsSold' />
<aggregate name='MaxAllTicketsSold' type='MAX' field='TicketsSold' />
<aggregate name='MinAllTicketsSold' type='MIN' field='TicketsSold' />
<aggregate name='SumAllTicketsSold' type='SUM' field='TicketsSold' />
<group name='DataByCategoryName' breakOnField='CategoryName' >
<attribute name='CategoryName' field='CategoryName'/>
<aggregate name='GroupCount' type='CUSTOM' field='ID' class='%ZEN.Report.Aggregate.CountDistinct'/>
<aggregate name='AveTicketsSoldByCategoryName' type='AVG' field='TicketsSold' />
<aggregate name='MaxTicketsSoldByCategoryName' type='MAX' field='TicketsSold' />
<aggregate name='MinTicketsSoldByCategoryName' type='MIN' field='TicketsSold' />
<aggregate name='SumTicketsSoldByCategoryName' type='SUM' field='TicketsSold' />
<group name='Detail' >
<attribute name='ID' field='ID'/>
<element name='Title' field='Title'/>
<element name='TicketsSold' field='TicketsSold'/>
<element name='Description' field='Description'/>
<element name='Length' field='Length'/>
<element name='PlayingNow' field='PlayingNow'/>
<element name='Rating' field='Rating'/>
</group>
</group>
	</group>
</report>
}

}

