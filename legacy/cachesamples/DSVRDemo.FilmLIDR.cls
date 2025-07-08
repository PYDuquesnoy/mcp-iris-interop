/// 
Class DSVRDemo.FilmLIDR Extends %DeepSee.Report.dataPresenter
{

Parameter DEFAULTMODE = "pdf";

Parameter XSLTMODE = "server";

Parameter DSSHOME = "linked";

Parameter DSSCLASS = "DSVRDemo.FilmDCR";

XData ReportModel
{
<reportModel>
<![CDATA[

{package:"DSVRDemo",objClass:"FilmLIDR",appName:"",sysName:"DSVRDemo.FilmLIDR",name:"",desc:"",type:"DPR",dssHome:"linked",dssClass:"DSVRDemo.FilmDCR",dssName:"FilmDCRData",t:"_LIDR",s:[
{t:"h",g:"_r",a:true,h:"97pt",w:"468pt",b:0,i:[
{t:"box",gc:
{sa:1,sc:"#ffff00",so:1,sw:"3",ss:"dotted",fa:1,fc:"#20007f",fo:1,xa:0,ta:0,za:1,zw:439,zh:50,zt:2,zl:14},c:"BOX",url:null,durl:null},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#ffff7f",xo:1,xb:true,xi:true,xu:false,xs:28,xj:"left",xf:"sans-serif",ta:0,za:1,zw:205,zh:32,zt:11,zl:129},c:"CAPN",f:"!Box Office Zen",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:140,zh:14,zt:55,zl:151},c:"CAPN",f:"!Total ticket sales by genre",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:131,zh:14,zt:71,zl:45},c:"CAPN",f:"!Number of title released: ",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:93,zh:14,zt:71,zl:275},c:"CAPN",f:"!Total ticket sales: ",fn:""},
{t:"line",gc:
{sa:1,sc:"#000000",so:1,sw:"3",ss:"solid",fa:0,xa:0,ta:0,za:1,zw:468,zh:0,zt:89,zl:0}},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:65,zh:14,zt:70,zl:179},c:"ELEM",f:"TotalFilms",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:96,zh:15,zt:70,zl:371},c:"ELEM",f:"TotalTicketsSold",fn:""}]},
{t:"h",g:"_p",a:true,h:"22pt",w:"468pt",b:0,i:[
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:9,xj:"left",xf:"sans-serif",ta:0,za:1,zw:97,zh:14,zt:2,zl:8},c:"CAPN",f:"!Genre Breakdown",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:9,xj:"left",xf:"sans-serif",ta:0,za:1,zw:71,zh:14,zt:2,zl:385},c:"CAPN",f:"!Total Seats Sold",fn:""},
{t:"line",gc:
{sa:1,sc:"#000000",so:0.5147058823529411,sw:1,ss:"solid",fa:0,xa:0,ta:0,za:1,zw:468,zh:0,zt:16,zl:0}}]},
{t:"h",g:"FilmsByGenre",a:true,h:"107pt",w:"468pt",b:0,i:[
{t:"box",gc:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#20007f",fo:1,xa:0,ta:0,za:1,zw:64,zh:64,zt:3,zl:22},c:"BOX",url:null,durl:null},
{t:"box",gc:
{sa:1,sc:"#ffff7f",so:1,sw:"5",ss:"solid",fa:1,fc:"#20007f",fo:1,xa:0,ta:0,za:1,zw:46,zh:43,zt:14,zl:32},c:"BOX",url:null,durl:null},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#00007f",xo:1,xb:true,xi:false,xu:false,xs:24,xj:"left",xf:"sans-serif",ta:0,za:1,zw:302,zh:32,zt:6,zl:95},c:"ATTR",f:"@CategoryName",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:87,zh:14,zt:39,zl:95},c:"CAPN",f:"!Titles Released:",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:65,zh:14,zt:54,zl:95},c:"CAPN",f:"!Total Seats:",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:63,zh:14,zt:37,zl:192},c:"ELEM",f:"TitleCount",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:66,zh:14,zt:53,zl:192},c:"ELEM",f:"TotalSeats",fn:""}]},
{t:"t",g:"FilmDetail",a:true,w:"6.5in",l:"8pt",tw:"449pt",i:[
{t:"c",gcH:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#bfbfff",fo:1,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:1,tb:true,thb:true,thbd:true,thcd:true,tbcd:true,tbrd:true,tzs:false,tzc:"#bfffcf",za:1,zw:114,zh:20,zt:0,zl:8},f:"Title",gcB:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"serif",ta:1,tb:true,thb:true,thbd:true,thcd:true,tbcd:true,tbrd:true,tzs:false,tzc:"#bfffcf",za:1,zw:114,zh:52,zt:20,zl:8},c:"TITLE"},
{t:"c",gcH:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#bfbfff",fo:1,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:1,tb:true,thb:true,thbd:true,thcd:true,tbcd:true,tbrd:true,tzs:false,tzc:"#bfffcf",za:1,zw:187,zh:20,zt:0,zl:122},f:"Description",gcB:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"serif",ta:1,tb:true,thb:true,thbd:true,thcd:true,tbcd:true,tbrd:true,tzs:false,tzc:"#bfffcf",za:1,zw:187,zh:52,zt:20,zl:122},c:"DESCRIPTION"},
{t:"c",gcH:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#bfbfff",fo:1,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:1,tb:true,thb:true,thbd:true,thcd:true,tbcd:true,tbrd:true,tzs:false,tzc:"#bfffcf",za:1,zw:98,zh:20,zt:0,zl:309},f:"TicketsSold",gcB:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"right",xf:"serif",ta:1,tb:true,thb:true,thbd:true,thcd:true,tbcd:true,tbrd:true,tzs:false,tzc:"#bfffcf",za:1,zw:98,zh:52,zt:20,zl:309},c:"SALES"},
{t:"c",gcH:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#bfbfff",fo:1,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:1,tb:true,thb:true,thbd:true,thcd:true,tbcd:true,tbrd:true,tzs:false,tzc:"#bfffcf",za:1,zw:50,zh:20,zt:0,zl:407},f:"Rating",gcB:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"center",xf:"serif",ta:1,tb:true,thb:true,thbd:true,thcd:true,tbcd:true,tbrd:true,tzs:false,tzc:"#bfffcf",za:1,zw:50,zh:52,zt:20,zl:407},c:"RATING"}]},
{t:"f",g:"FilmsByGenre",a:true,h:"158pt",w:"468pt",b:1,i:[
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#20007f",xo:1,xb:true,xi:false,xu:false,xs:16,xj:"left",xf:"sans-serif",ta:0,za:1,zw:54,zh:22,zt:11,zl:25},c:"CAPN",f:"!Genre: ",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#20007f",xo:1,xb:true,xi:false,xu:false,xs:16,xj:"left",xf:"sans-serif",ta:0,za:1,zw:171,zh:26,zt:10,zl:83},c:"ATTR",f:"@CategoryName",fn:""},
{t:"line",gc:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:0,xa:0,ta:0,za:1,zw:227,zh:0,zt:28,zl:8}},
{t:"chart",url:"deepsee/line_chart_24.png",c:"column",cIdx:1,n:"Seats Sold by Genre",grp:"FilmDetail",udg:1,df:["!TicketsSold"],sn:"",sLgd:0,sLbl:1,bw:0,mt:12,mr:21,ml:20,mb:32,tx:42,ty:3,lx:80,ly:10,lh:20,lw:20,XA:
{lbl:"",fld:["Title"],title:"",txtAnchor:"begin",lblAngle:"45",mnVD:"0",mGL:"false"},YA:
{lbl:"",fld:[""],title:"",txtAnchor:"begin",lblAngle:"0",mnVD:"0",mGL:"false"},gc:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#20007f",fo:1,xa:1,xc:"#ffff7f",xo:1,xb:false,xi:false,xu:false,xs:8,xj:"left",xf:"sans-serif",ta:0,za:1,zw:219,zh:138,zt:14,zl:238}}]},
{t:"f",g:"_r",a:true,h:"102pt",w:"468pt",b:0,i:[
{t:"box",gc:
{sa:1,sc:"#ffff7f",so:1,sw:"5",ss:"dotted",fa:1,fc:"#20007f",fo:1,xa:0,ta:0,za:1,zw:420,zh:89,zt:7,zl:26},c:"BOX",url:null,durl:null},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#ffff40",xo:1,xb:false,xi:false,xu:false,xs:14,xj:"center",xf:"Broadway",ta:0,za:1,zw:410,zh:18,zt:14,zl:31},c:"CAPN",f:"!End Of",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#ffff00",xo:1,xb:false,xi:false,xu:false,xs:34,xj:"center",xf:"Broadway",ta:0,za:1,zw:407,zh:42,zt:29,zl:32},c:"CAPN",f:"!Box Office Zen Report",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#ffff40",xo:1,xb:false,xi:false,xu:false,xs:15,xj:"center",xf:"Broadway",ta:0,za:1,zw:407,zh:20,zt:69,zl:32},c:"CAPN",f:"!Hope you enjoyed the show",fn:""}]},
{t:"f",g:"_p",a:true,h:"26pt",w:"468pt",b:0,i:[
{t:"line",gc:
{sa:1,sc:"#ff0000",so:1,sw:"3",ss:"solid",fa:0,xa:0,ta:0,za:1,zw:468,zh:0,zt:9,zl:0}},
{t:"pagenum",gc:
{sa:0,fa:1,fc:"#ffffff",fo:1,xa:1,xc:"#000000",xo:1,xb:true,xi:true,xu:false,xs:12,xj:"center",xf:"sans-serif",ta:0,za:1,zw:89,zh:15,zt:3,zl:191},c:"PAGENUM",f:null,fmt:"# of ##"}]}],pageModel:
{paper:"letter",orient:"portrait",units:"in",width:612,height:792,left:72,right:72,top:72,bottom:72,header:0,footer:0}}
]]></reportModel>
}

XData ReportDisplay [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{

<report xmlns="http://www.intersystems.com/zen/report/display"
name="FilmDCRData">
	<init>
		<xslt xslfo="ParagraphFunctions" />
	</init>
<document width="612pt" height="792pt" marginLeft="72" marginRight="72" marginTop="72" marginBottom="72" headerHeight="22pt" regionBeforeExtent="20pt" footerHeight="27pt" regionAfterExtent="25pt" />
<pageheader>
<!-- PAGE HEADER -->
<write>
<![CDATA[
<fo:block font-size="0pt" >
<fo:instream-foreign-object>
<svg:svg width="468pt" height="22pt" viewBox="0 0 468 22" >
<svg:rect x="8" y="2" width="97" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="8" y="9.5" style="font-size:9;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
Genre Breakdown
</svg:text>
<svg:rect x="385" y="2" width="71" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="385" y="9.5" style="font-size:9;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
Total Seats Sold
</svg:text>
<svg:line x1="0" y1="16" x2="468" y2="16" style="stroke:#000000;stroke-width:1;stroke-opacity:0.5147058823529411" />
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
]]>
</write>
<!-- end of PAGE HEADER -->
</pageheader>
<pagefooter>
<!-- PAGE FOOTER -->
<write>
<![CDATA[
<fo:block font-size="0pt" >
<fo:table border-collapse="collapse" inline-progression-dimension="468pt" table-layout="fixed">
<fo:table-column column-width="191pt" />
<fo:table-column column-width="89pt" />
<fo:table-column column-width="188pt" />
<fo:table-body>
<fo:table-row height="3pt">
<fo:table-cell padding="0pt" number-columns-spanned="3" number-rows-spanned="1">
<fo:block font-size="0pt">
<fo:instream-foreign-object height="3pt" width="468pt">
<svg:svg width="468pt" height="3pt" viewBox="0 0 468 3" >
<svg:line x1="0" y1="9" x2="468" y2="9" style="stroke:#ff0000;stroke-width:3;stroke-opacity:1" />
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
</fo:table-cell>
</fo:table-row>
<fo:table-row height="15pt">
<fo:table-cell padding="0pt" number-columns-spanned="1" number-rows-spanned="1">
<fo:block font-size="0pt">
<fo:instream-foreign-object height="15pt" width="191pt">
<svg:svg width="191pt" height="15pt" viewBox="0 3 191 15" >
<svg:line x1="0" y1="9" x2="468" y2="9" style="stroke:#ff0000;stroke-width:3;stroke-opacity:1" />
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
</fo:table-cell>
<fo:table-cell padding="0pt" number-columns-spanned="1" number-rows-spanned="1" display-align="center"  background-color="#ffffff" >
<fo:block font-size="0pt" text-align="center" >
]]>
</write>
<item special="page-number-of" style="font-size:12pt;font-family:sans-serif;color:#000000;font-weight:bold;font-style:italic;text-align:center;width:89;height:15;" />
<write>
<![CDATA[
</fo:block>
</fo:table-cell>
<fo:table-cell padding="0pt" number-columns-spanned="1" number-rows-spanned="1">
<fo:block font-size="0pt">
<fo:instream-foreign-object height="15pt" width="188pt">
<svg:svg width="188pt" height="15pt" viewBox="280 3 188 15" >
<svg:line x1="0" y1="9" x2="468" y2="9" style="stroke:#ff0000;stroke-width:3;stroke-opacity:1" />
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
</fo:table-cell>
</fo:table-row>
<fo:table-row height="8pt">
<fo:table-cell padding="0pt" number-columns-spanned="3" number-rows-spanned="1">
<fo:block font-size="0pt">
<fo:instream-foreign-object height="8pt" width="468pt">
<svg:svg width="468pt" height="8pt" viewBox="0 18 468 8" >
<svg:line x1="0" y1="9" x2="468" y2="9" style="stroke:#ff0000;stroke-width:3;stroke-opacity:1" />
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
</fo:table-cell>
</fo:table-row>
</fo:table-body>
</fo:table>
</fo:block>
]]>
</write>
<!-- end of PAGE FOOTER -->
</pagefooter>
<body>
<!-- REPORT HEADER -->
<write>
<![CDATA[
<fo:block font-size="0pt" >
<fo:instream-foreign-object>
<svg:svg width="468pt" height="97pt" viewBox="0 0 468 97" >
<svg:rect x="14" y="2" width="439" height="50" style="fill-opacity:1;fill:#20007f;stroke:#ffff00;stroke-width:3;stroke-opacity:1;stroke-dasharray:3,3" />
<svg:rect x="129" y="11" width="205" height="32" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="129" y="34.33333333333333" style="font-size:28;font-family:sans-serif;fill:#ffff7f;fill-opacity:1;font-weight:bold;font-style:italic;" >
Box Office Zen
</svg:text>
<svg:rect x="151" y="55" width="140" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="151" y="65" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
Total ticket sales by genre
</svg:text>
<svg:rect x="45" y="71" width="131" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="45" y="81" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
Number of title released: 
</svg:text>
<svg:rect x="275" y="71" width="93" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="275" y="81" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
Total ticket sales: 
</svg:text>
<svg:line x1="0" y1="89" x2="468" y2="89" style="stroke:#000000;stroke-width:3;stroke-opacity:1" />
<svg:rect x="179" y="70" width="65" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="179" y="80" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
<xsl:value-of select="TotalFilms"/>
</svg:text>
<svg:rect x="371" y="70" width="96" height="15" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="371" y="80" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
<xsl:value-of select="TotalTicketsSold"/>
</svg:text>
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
]]>
</write>
<!-- end of REPORT HEADER -->
<group name='FilmsByGenre' >
<!-- GROUP HEADER (FilmsByGenre) -->
<write>
<![CDATA[
<fo:block font-size="0pt" >
<fo:instream-foreign-object>
<svg:svg width="468pt" height="107pt" viewBox="0 0 468 107" >
<svg:rect x="22" y="3" width="64" height="64" style="fill-opacity:1;fill:#20007f;stroke:#000000;stroke-width:1;stroke-opacity:1" />
<svg:rect x="32" y="14" width="46" height="43" style="fill-opacity:1;fill:#20007f;stroke:#ffff7f;stroke-width:5;stroke-opacity:1" />
<svg:rect x="95" y="6" width="302" height="32" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="95" y="26" style="font-size:24;font-family:sans-serif;fill:#00007f;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@CategoryName"/>
</svg:text>
<svg:rect x="95" y="39" width="87" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="95" y="49" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
Titles Released:
</svg:text>
<svg:rect x="95" y="54" width="65" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="95" y="64" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
Total Seats:
</svg:text>
<svg:rect x="192" y="37" width="63" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="192" y="47" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
<xsl:value-of select="TitleCount"/>
</svg:text>
<svg:rect x="192" y="53" width="66" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="192" y="63" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
<xsl:value-of select="TotalSeats"/>
</svg:text>
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
]]>
</write>
<!-- end of GROUP HEADER (FilmsByGenre) -->
<!-- Start of REPORT BODY (FilmDetail) -->
<fo><write><![CDATA[
<fo:table space-after="24pt" border-collapse="collapse" inline-progression-dimension="468">
<fo:table-column column-number="1" column-width="4pt" />
<fo:table-column column-number="2" column-width="464pt" />
<fo:table-body><fo:table-row><fo:table-cell><fo:block></fo:block></fo:table-cell><fo:table-cell>
]]>
</write></fo>
<table orient='col' group='FilmDetail' width='449pt' style='margin-left:2pt;margin-right:2pt;border:1pt solid #000000;' >
<item field='Title' width='114pt' style='font-size:12;font-family:serif;color:#000000;font-weight:normal;font-style:normal;text-decoration:none;text-align:left;border-bottom:1pt solid #000000;border-right:1pt solid #000000;'>
<caption value='TITLE' style='background-color:#bfbfff;font-size:12;font-family:sans-serif;color:#000000;font-weight:bold;font-style:normal;text-decoration:none;text-align:left;width:114pt;border-top:1pt solid #000000;border-left:1pt solid #000000;border-bottom:1pt solid #000000;border-right:1pt solid #000000;' />
</item>
<item field='Description' width='187pt' style='font-size:12;font-family:serif;color:#000000;font-weight:normal;font-style:normal;text-decoration:none;text-align:left;border-bottom:1pt solid #000000;border-right:1pt solid #000000;'>
<caption value='DESCRIPTION' style='background-color:#bfbfff;font-size:12;font-family:sans-serif;color:#000000;font-weight:bold;font-style:normal;text-decoration:none;text-align:left;width:187pt;border-top:1pt solid #000000;border-bottom:1pt solid #000000;border-right:1pt solid #000000;' />
</item>
<item field='TicketsSold' width='98pt' style='font-size:12;font-family:serif;color:#000000;font-weight:normal;font-style:normal;text-decoration:none;text-align:right;border-bottom:1pt solid #000000;border-right:1pt solid #000000;'>
<caption value='SALES' style='background-color:#bfbfff;font-size:12;font-family:sans-serif;color:#000000;font-weight:bold;font-style:normal;text-decoration:none;text-align:right;width:98pt;border-top:1pt solid #000000;border-bottom:1pt solid #000000;border-right:1pt solid #000000;' />
</item>
<item field='Rating' width='50pt' style='font-size:12;font-family:serif;color:#000000;font-weight:normal;font-style:normal;text-decoration:none;text-align:center;border-bottom:1pt solid #000000;'>
<caption value='RATING' style='background-color:#bfbfff;font-size:12;font-family:sans-serif;color:#000000;font-weight:bold;font-style:normal;text-decoration:none;text-align:left;width:50pt;border-top:1pt solid #000000;border-left:1pt solid #000000;border-bottom:1pt solid #000000;' />
</item>
</table>
<fo><write><![CDATA[
</fo:table-cell></fo:table-row></fo:table-body></fo:table>
]]>
</write></fo>
<!-- End of REPORT BODY (FilmDetail) -->
<!-- GROUP FOOTER (FilmsByGenre) -->
<write>
<![CDATA[
<fo:block font-size="0pt" >
<fo:table border-collapse="collapse" inline-progression-dimension="468pt" table-layout="fixed">
<fo:table-column column-width="238pt" />
<fo:table-column column-width="219pt" />
<fo:table-column column-width="11pt" />
<fo:table-body>
<fo:table-row height="14pt">
<fo:table-cell padding="0pt" number-columns-spanned="3" number-rows-spanned="1">
<fo:block font-size="0pt">
<fo:instream-foreign-object height="14pt" width="468pt">
<svg:svg width="468pt" height="14pt" viewBox="0 0 468 14" >
<svg:rect x="25" y="11" width="54" height="22" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="25" y="24.333333333333336" style="font-size:16;font-family:sans-serif;fill:#20007f;fill-opacity:1;font-weight:bold;" >
Genre: 
</svg:text>
<svg:rect x="83" y="10" width="171" height="26" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="83" y="23.333333333333336" style="font-size:16;font-family:sans-serif;fill:#20007f;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@CategoryName"/>
</svg:text>
<svg:line x1="8" y1="28" x2="235" y2="28" style="stroke:#000000;stroke-width:1;stroke-opacity:1" />
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
</fo:table-cell>
</fo:table-row>
<fo:table-row height="138pt">
<fo:table-cell padding="0pt" number-columns-spanned="1" number-rows-spanned="1">
<fo:block font-size="0pt">
<fo:instream-foreign-object height="138pt" width="238pt">
<svg:svg width="238pt" height="138pt" viewBox="0 14 238 138" >
<svg:rect x="25" y="11" width="54" height="22" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="25" y="24.333333333333336" style="font-size:16;font-family:sans-serif;fill:#20007f;fill-opacity:1;font-weight:bold;" >
Genre: 
</svg:text>
<svg:rect x="83" y="10" width="171" height="26" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="83" y="23.333333333333336" style="font-size:16;font-family:sans-serif;fill:#20007f;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@CategoryName"/>
</svg:text>
<svg:line x1="8" y1="28" x2="235" y2="28" style="stroke:#000000;stroke-width:1;stroke-opacity:1" />
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
</fo:table-cell>
<fo:table-cell padding="0pt" number-columns-spanned="1" number-rows-spanned="1">
<fo:block font-size="0pt">
]]>
</write>
<barChart width="219" height="138" backgroundStyle="fill:#20007f;stroke-width:0.7246376811594203;stroke:#000000;" titleStyle="font-size:5.797101449275362;font-family:sans-serif;fill:#ffff7f;fill-opacity:1;" legendVisible="false" labelsVisible="true" labelStyle="font-size:4.3478260869565215;font-family:sans-serif;fill:#ffff7f;fill-opacity:1;;" marginTop="12" marginLeft="20" marginRight="21" marginBottom="32" titleX="42" titleY="3"
	title="Seats Sold by Genre"
	dataFields="!TicketsSold"
	dataGroup="FilmDetail"
	>
<xaxis
	labelValue="Title" labelGroup="FilmDetail"
	labelAngle="45"
	textAnchor="begin"
	minValueDisplacement="0"
	majorGridLines="false"
/>
<yaxis
	labelAngle="0"
	textAnchor="begin"
	minValueDisplacement="0"
	majorGridLines="false"
/>
</barChart>
<write>
<![CDATA[
</fo:block>
</fo:table-cell>
<fo:table-cell padding="0pt" number-columns-spanned="1" number-rows-spanned="1">
<fo:block font-size="0pt">
<fo:instream-foreign-object height="138pt" width="11pt">
<svg:svg width="11pt" height="138pt" viewBox="457 14 11 138" >
<svg:rect x="25" y="11" width="54" height="22" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="25" y="24.333333333333336" style="font-size:16;font-family:sans-serif;fill:#20007f;fill-opacity:1;font-weight:bold;" >
Genre: 
</svg:text>
<svg:rect x="83" y="10" width="171" height="26" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="83" y="23.333333333333336" style="font-size:16;font-family:sans-serif;fill:#20007f;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@CategoryName"/>
</svg:text>
<svg:line x1="8" y1="28" x2="235" y2="28" style="stroke:#000000;stroke-width:1;stroke-opacity:1" />
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
</fo:table-cell>
</fo:table-row>
<fo:table-row height="6pt">
<fo:table-cell padding="0pt" number-columns-spanned="3" number-rows-spanned="1">
<fo:block font-size="0pt">
<fo:instream-foreign-object height="6pt" width="468pt">
<svg:svg width="468pt" height="6pt" viewBox="0 152 468 6" >
<svg:rect x="25" y="11" width="54" height="22" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="25" y="24.333333333333336" style="font-size:16;font-family:sans-serif;fill:#20007f;fill-opacity:1;font-weight:bold;" >
Genre: 
</svg:text>
<svg:rect x="83" y="10" width="171" height="26" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="83" y="23.333333333333336" style="font-size:16;font-family:sans-serif;fill:#20007f;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@CategoryName"/>
</svg:text>
<svg:line x1="8" y1="28" x2="235" y2="28" style="stroke:#000000;stroke-width:1;stroke-opacity:1" />
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
</fo:table-cell>
</fo:table-row>
</fo:table-body>
</fo:table>
</fo:block>
]]>
</write>
<pagebreak/>
<!-- end of GROUP FOOTER (FilmsByGenre) -->
</group>
<!-- REPORT FOOTER -->
<write>
<![CDATA[
<fo:block font-size="0pt" >
<fo:instream-foreign-object>
<svg:svg width="468pt" height="102pt" viewBox="0 0 468 102" >
<svg:rect x="26" y="7" width="420" height="89" style="fill-opacity:1;fill:#20007f;stroke:#ffff7f;stroke-width:5;stroke-opacity:1;stroke-dasharray:5,5" />
<svg:rect x="31" y="14" width="410" height="18" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="236" y="25.666666666666664" style="font-size:14;font-family:Broadway;fill:#ffff40;fill-opacity:1;text-anchor:middle;" >
End Of
</svg:text>
<svg:rect x="32" y="29" width="407" height="42" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="235.5" y="57.33333333333333" style="font-size:34;font-family:Broadway;fill:#ffff00;fill-opacity:1;text-anchor:middle;" >
Box Office Zen Report
</svg:text>
<svg:rect x="32" y="69" width="407" height="20" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="235.5" y="81.5" style="font-size:15;font-family:Broadway;fill:#ffff40;fill-opacity:1;text-anchor:middle;" >
Hope you enjoyed the show
</svg:text>
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
]]>
</write>
<!-- end of REPORT FOOTER -->
</body>
</report>
}

}

