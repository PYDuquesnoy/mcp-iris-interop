/// 
Class DSVRDemo.FilmDCR Extends (%DeepSee.Report.dataCollector, %DeepSee.Report.dataSchemaInterface)
{

/// Genre of film to report
Property Genre As %String(ZENURL = "GENRE");

Parameter DEFAULTMODE = "xml";

Parameter XSLTMODE = "server";

XData ReportDCR
{
<reportDCR>
<![CDATA[

{package:"DSVRDemo",objClass:"FilmDCR",appName:"",sysName:"DSVRDemo.FilmDCR",name:"",desc:"",type:"DCR",dataSrc:"Cinema.Film",sql:
{src:"Cinema.Film",fld:["Title","TicketsSold","Category->CategoryName AS Category_CategoryName","ID","Description","Length","PlayingNow","Rating"],w:"(Category->CategoryName = ?) OR (? IS NULL)",ob:["Category->CategoryName","Title"],p:["..Genre","..Genre"],op:null},prop:[
{n:"Genre",t:"%String",z:"GENRE",d:"Genre of film to report",i:""}],meth:
{},tree:
{n:"_root",t:"gp",k:[
{n:"runBy",t:"at",e:"$UserName"},
{n:"Genre",t:"at",e:"..Genre"},
{n:"TotalFilms",t:"ag",f:"Title",o:"COUNT"},
{n:"TotalTicketsSold",t:"ag",f:"TicketsSold",o:"SUM"},
{n:"runTime",t:"at",e:"$ZDT($H,3)"},
{n:"FilmsByGenre",t:"gp",br:"Category->CategoryName",k:[
{n:"TitleCount",t:"ag",f:"Title",o:"COUNT"},
{n:"TotalSeats",t:"ag",f:"TicketsSold",o:"SUM"},
{n:"CategoryName",t:"at",f:"Category->CategoryName"},
{n:"FilmDetail",t:"gp",s:"Title",k:[
{n:"sysID",t:"el",f:"ID"},
{n:"Description",t:"el",f:"Description"},
{n:"Length",t:"el",f:"Length"},
{n:"PlayingNow",t:"el",f:"PlayingNow"},
{n:"Rating",t:"el",f:"Rating"},
{n:"Title",t:"el",f:"Title"},
{n:"TicketsSold",t:"el",f:"TicketsSold"}]}]}]},dataCls:"Cinema.Film"}
]]></reportDCR>
}

XData ReportDSS
{
<reportDSS>
<![CDATA[

{t:"r",n:"FilmDCRData",dataFileName:"",dataCollector:"DSVRDemo.FilmDCR",onExtractData:"",onGetDataAge:"",a:[
{t:"a",n:"runBy"},
{t:"a",n:"Genre"},
{t:"a",n:"runTime"}],i:[
{t:"i",n:"TotalFilms"},
{t:"i",n:"TotalTicketsSold"},
{t:"g",n:"FilmsByGenre",a:[
{t:"a",n:"CategoryName"}],i:[
{t:"i",n:"TitleCount"},
{t:"i",n:"TotalSeats"},
{t:"g",n:"FilmDetail",a:
{},i:[
{t:"i",n:"sysID"},
{t:"i",n:"Description"},
{t:"i",n:"Length"},
{t:"i",n:"PlayingNow"},
{t:"i",n:"Rating"},
{t:"i",n:"Title"},
{t:"i",n:"TicketsSold"}]}]}]}
]]></reportDSS>
}

/// XML that defines the contents of this report.
XData ReportDefinition [ XMLNamespace = "http://www.intersystems.com/zen/report/definition" ]
{
<report xmlns="http://www.intersystems.com/zen/report/definition"
name="FilmDCRData"
sql='SELECT Title,TicketsSold,Category->CategoryName AS Category_CategoryName,ID,Description,Length,PlayingNow,Rating
	FROM Cinema.Film
	WHERE (Category->CategoryName = ?) OR (? IS NULL)
	ORDER BY Category_CategoryName,Title
'>
<parameter expression="..Genre"/>
<parameter expression="..Genre"/>
<attribute name="runBy" expression="$UserName" />

<attribute name="Genre" expression="..Genre" />

<aggregate name="TotalFilms" type="COUNT" field="Title" />

<aggregate name="TotalTicketsSold" type="SUM" field="TicketsSold" />

<attribute name="runTime" expression="$ZDT($H,3)" />

<group name="FilmsByGenre" breakOnField="Category_CategoryName" >
<aggregate name="TitleCount" type="COUNT" field="Title" />
<aggregate name="TotalSeats" type="SUM" field="TicketsSold" />
<attribute name="CategoryName" field="Category_CategoryName" />
<group name="FilmDetail" >
<element name="sysID" field="ID" />
<element name="Description" field="Description" />
<element name="Length" field="Length" />
<element name="PlayingNow" field="PlayingNow" />
<element name="Rating" field="Rating" />
<element name="Title" field="Title" />
<element name="TicketsSold" field="TicketsSold" />
</group>
</group>

</report>
}

}

