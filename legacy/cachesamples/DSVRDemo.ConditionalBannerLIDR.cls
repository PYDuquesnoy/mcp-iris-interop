/// 
Class DSVRDemo.ConditionalBannerLIDR Extends %DeepSee.Report.dataPresenter
{

Parameter DEFAULTMODE = "pdf";

Parameter XSLTMODE = "server";

Parameter DSSHOME = "linked";

Parameter DSSCLASS = "DSVRDemo.FilmDCR";

XData ReportModel
{
<reportModel>
<![CDATA[

{package:"DSVRDemo",objClass:"ConditionalBannerLIDR",appName:"",sysName:"DSVRDemo.ConditionalBannerLIDR",name:"Annotated Box Office",desc:"",type:"DPR",dssHome:"linked",dssClass:"DSVRDemo.FilmDCR",pageModel:
{paper:"letter",orient:"portrait",units:"in",width:612,height:792,left:72,right:72,top:72,bottom:72,header:18,footer:18},dssName:"FilmDCRData",t:"_LIDR",s:[
{t:"h",g:"_r",a:true,h:"205pt",w:"468pt",b:1,i:[
{t:"box",gc:
{sa:1,sc:"#000000",so:1,sw:"2",ss:"solid",fa:1,fc:"#ffffff",fo:1,xa:0,ta:0,za:1,zw:466,zh:126,zt:73,zl:1},c:"BOX",url:null,durl:null},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:36,xj:"center",xf:"sans-serif",ta:0,za:1,zw:468,zh:44,zt:74,zl:0},c:"CAPN",f:"!Annotated Box Office",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"left",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:118,zl:246},c:"ATTR",f:"@runBy",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"right",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:118,zl:0},c:"CAPN",f:"!Run by:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"left",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:134,zl:246},c:"ATTR",f:"@Genre",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"right",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:134,zl:0},c:"CAPN",f:"!Genre:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"left",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:150,zl:246},c:"ATTR",f:"@runTime",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"right",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:150,zl:0},c:"CAPN",f:"!Run time:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"left",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:166,zl:246},c:"ELEM",f:"TotalTicketsSold",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"right",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:166,zl:0},c:"CAPN",f:"!Total tickets sold:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"left",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:182,zl:246},c:"ELEM",f:"TotalFilms",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"right",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:182,zl:0},c:"CAPN",f:"!Total films:",fn:""}]},
{t:"h",g:"_p",a:true,h:"43pt",w:"468pt",b:0,i:[
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:86,zh:11,zt:22,zl:70},c:"ATTR",f:"@runBy",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:70,zh:11,zt:22,zl:0},c:"CAPN",f:"!Run by:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:86,zh:11,zt:11,zl:70},c:"ATTR",f:"@Genre",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:70,zh:11,zt:11,zl:0},c:"CAPN",f:"!Genre:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:86,zh:11,zt:0,zl:70},c:"ATTR",f:"@runTime",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:70,zh:11,zt:0,zl:0},c:"CAPN",f:"!Run time:",fn:""},
{t:"line",gc:
{sa:1,sc:"#000000",so:1,sw:"2",ss:"solid",fa:0,xa:0,ta:0,za:1,zw:466,zh:0,zt:34,zl:0}}]},
{t:"h",g:"FilmsByGenre",a:true,h:"74pt",w:"468pt",b:0,i:[
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:78,zh:14,zt:45,zl:78},c:"ELEM",f:"TitleCount",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:78,zh:14,zt:45,zl:0},c:"CAPN",f:"!Title count:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:18,xj:"center",xf:"sans-serif",ta:0,za:1,zw:156,zh:21,zt:24,zl:156},c:"ATTR",f:"@CategoryName",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:78,zh:14,zt:45,zl:390},c:"ELEM",f:"TotalSeats",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:78,zh:14,zt:45,zl:312},c:"CAPN",f:"!Total seats:",fn:""},
{t:"line",gc:
{sa:1,sc:"#000000",so:1,sw:"2",ss:"solid",fa:0,xa:0,ta:0,za:1,zw:466,zh:0,zt:60,zl:0}}]},
{t:"b",g:"FilmDetail",a:true,h:"71pt",w:"468pt",b:0,i:[
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:257,zh:16,zt:4,zl:3},c:"ELEM",f:"Title",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:66,zh:19,zt:0,zl:265},c:"CAPN",f:"!Rating",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:66,zh:29,zt:19,zl:265},c:"ELEM",f:"Rating",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:66,zh:19,zt:0,zl:330},c:"CAPN",f:"!Length",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:66,zh:29,zt:19,zl:330},c:"ELEM",f:"Length",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:208,zh:19,zt:36,zl:3},c:"CAPN",f:"!Description",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:208,zh:29,zt:52,zl:3},c:"ELEM",f:"Description",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:56,zh:19,zt:0,zl:409},c:"CAPN",f:"!Sales",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:56,zh:29,zt:19,zl:409},c:"ELEM",f:"TicketsSold",fn:""}],cb:[
{t:"f",g:"_r",c:"../@CategoryName=\'Comedy\' and TicketsSold&gt;10000",h:"63pt",w:"468pt",b:0,rh:0,i:[
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:298,zh:14,zt:7,zl:90},c:"CAPN",f:"!Comedies are often cheap to make so good sales usually ",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:131,zh:14,zt:23,zl:163},c:"CAPN",f:"!translate into pure profit.",fn:""},
{t:"line",gc:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:0,xa:0,ta:0,za:1,zw:468,zh:0,zt:2,zl:0}},
{t:"line",gc:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:0,xa:0,ta:0,za:1,zw:468,zh:0,zt:41,zl:0}}]},
{t:"f",g:"_r",c:"(../@CategoryName=\'Action\' or ../@CategoryName=\'Comedy\') and TicketsSold&lt;1000",h:"82pt",w:"468pt",b:0,rh:0,i:[
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:181,zh:14,zt:8,zl:14},c:"CAPN",f:"!Pacing is a major consideration for ",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:87,zh:14,zt:8,zl:200},c:"ATTR",f:"../@CategoryName",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:98,zh:14,zt:23,zl:12},c:"CAPN",f:"!The running time of ",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:54,zh:13,zt:23,zl:120},c:"ELEM",f:"Length",fn:""},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:279,zh:14,zt:37,zl:18},c:"CAPN",f:"!may have negatively impacted box office performance",fn:""},
{t:"box",gc:
{sa:1,sc:"#000000",so:1,sw:"3",ss:"solid",fa:1,fc:"#ffff00",fo:1,xa:0,ta:0,za:1,zw:141,zh:46,zt:5,zl:310},c:"BOX",url:null,durl:null},
{t:"txt",gc:
{sa:0,fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:true,xi:true,xu:false,xs:25,xj:"center",xf:"sans-serif",ta:0,za:1,zw:126,zh:26,zt:15,zl:319},c:"CAPN",f:"!NOTE!!!",fn:""}]}]},
{t:"f",g:"FilmsByGenre",a:true,h:"41pt",w:"468pt",b:1,i:[
{t:"line",gc:
{sa:1,sc:"#000000",so:1,sw:"2",ss:"solid",fa:0,xa:0,ta:0,za:1,zw:466,zh:0,zt:25,zl:0}},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:78,zh:14,zt:28,zl:78},c:"ELEM",f:"TitleCount",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:0,za:1,zw:78,zh:14,zt:28,zl:0},c:"CAPN",f:"!Title count:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:78,zh:14,zt:28,zl:390},c:"ELEM",f:"TotalSeats",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:78,zh:14,zt:28,zl:312},c:"CAPN",f:"!Total seats:",fn:""}]},
{t:"f",g:"_r",a:true,h:"82pt",w:"468pt",b:0,i:[
{t:"box",gc:
{sa:1,sc:"#000000",so:1,sw:"2",ss:"solid",fa:1,fc:"#ffffff",fo:1,xa:0,ta:0,za:1,zw:466,zh:54,zt:25,zl:1},c:"BOX",url:null,durl:null},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:16,xj:"center",xf:"sans-serif",ta:0,za:1,zw:468,zh:20,zt:26,zl:0},c:"CAPN",f:"!Annotated Box Office",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"left",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:46,zl:246},c:"ELEM",f:"TotalTicketsSold",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"right",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:46,zl:0},c:"CAPN",f:"!Total tickets sold:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"left",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:62,zl:246},c:"ELEM",f:"TotalFilms",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"right",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:62,zl:0},c:"CAPN",f:"!Total films:",fn:""}]},
{t:"f",g:"_p",a:true,h:"37pt",w:"468pt",b:0,i:[
{t:"line",gc:
{sa:1,sc:"#000000",so:1,sw:"2",ss:"solid",fa:0,xa:0,ta:0,za:1,zw:466,zh:0,zt:1,zl:0}},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:86,zh:11,zt:2,zl:70},c:"ATTR",f:"@runBy",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:70,zh:11,zt:2,zl:0},c:"CAPN",f:"!Run by:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:86,zh:11,zt:13,zl:70},c:"ATTR",f:"@Genre",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:70,zh:11,zt:13,zl:0},c:"CAPN",f:"!Genre:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:86,zh:11,zt:24,zl:70},c:"ATTR",f:"@runTime",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:70,zh:11,zt:24,zl:0},c:"CAPN",f:"!Run time:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"right",xf:"sans-serif",ta:0,za:1,zw:156,zh:12,zt:23,zl:312},c:"CAPN",f:"!Annotated Box Office",fn:""}]}]}
]]></reportModel>
}

XData ReportDisplay [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{

<report xmlns="http://www.intersystems.com/zen/report/display"
name="FilmDCRData">
	<init>
		<xslt xslfo="ParagraphFunctions" />
	</init>
<document width="612pt" height="792pt" marginLeft="72" marginRight="72" marginTop="72" marginBottom="72" headerHeight="43pt" regionBeforeExtent="41pt" footerHeight="37pt" regionAfterExtent="35pt" />
<pageheader>
<!-- PAGE HEADER -->
<write>
<![CDATA[
<fo:block font-size="0pt" >
<fo:instream-foreign-object>
<svg:svg width="468pt" height="43pt" viewBox="0 0 468 43" >
<svg:rect x="70" y="22" width="86" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="70" y="30.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@runBy"/>
</svg:text>
<svg:rect x="0" y="22" width="70" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="30.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Run by:
</svg:text>
<svg:rect x="70" y="11" width="86" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="70" y="19.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@Genre"/>
</svg:text>
<svg:rect x="0" y="11" width="70" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="19.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Genre:
</svg:text>
<svg:rect x="70" y="0" width="86" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="70" y="8.333333333333334" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@runTime"/>
</svg:text>
<svg:rect x="0" y="0" width="70" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="8.333333333333334" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Run time:
</svg:text>
<svg:line x1="0" y1="34" x2="466" y2="34" style="stroke:#000000;stroke-width:2;stroke-opacity:1" />
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
<fo:instream-foreign-object>
<svg:svg width="468pt" height="37pt" viewBox="0 0 468 37" >
<svg:line x1="0" y1="1" x2="466" y2="1" style="stroke:#000000;stroke-width:2;stroke-opacity:1" />
<svg:rect x="70" y="2" width="86" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="70" y="10.333333333333334" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@runBy"/>
</svg:text>
<svg:rect x="0" y="2" width="70" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="10.333333333333334" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Run by:
</svg:text>
<svg:rect x="70" y="13" width="86" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="70" y="21.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@Genre"/>
</svg:text>
<svg:rect x="0" y="13" width="70" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="21.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Genre:
</svg:text>
<svg:rect x="70" y="24" width="86" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="70" y="32.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@runTime"/>
</svg:text>
<svg:rect x="0" y="24" width="70" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="32.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Run time:
</svg:text>
<svg:rect x="312" y="23" width="156" height="12" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="468" y="31.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Annotated Box Office
</svg:text>
</svg:svg>
</fo:instream-foreign-object>
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
<svg:svg width="468pt" height="205pt" viewBox="0 0 468 205" >
<svg:rect x="1" y="73" width="466" height="126" style="fill-opacity:1;fill:#ffffff;stroke:#000000;stroke-width:2;stroke-opacity:1" />
<svg:rect x="0" y="74" width="468" height="44" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="234" y="104" style="font-size:36;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:middle;" >
Annotated Box Office
</svg:text>
<svg:rect x="246" y="118" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="246" y="129.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@runBy"/>
</svg:text>
<svg:rect x="0" y="118" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="222" y="129.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Run by:
</svg:text>
<svg:rect x="246" y="134" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="246" y="145.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@Genre"/>
</svg:text>
<svg:rect x="0" y="134" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="222" y="145.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Genre:
</svg:text>
<svg:rect x="246" y="150" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="246" y="161.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@runTime"/>
</svg:text>
<svg:rect x="0" y="150" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="222" y="161.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Run time:
</svg:text>
<svg:rect x="246" y="166" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="246" y="177.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="TotalTicketsSold"/>
</svg:text>
<svg:rect x="0" y="166" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="222" y="177.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Total tickets sold:
</svg:text>
<svg:rect x="246" y="182" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="246" y="193.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="TotalFilms"/>
</svg:text>
<svg:rect x="0" y="182" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="222" y="193.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Total films:
</svg:text>
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
]]>
</write>
<pagebreak/>
<!-- end of REPORT HEADER -->
<group name='FilmsByGenre' >
<!-- GROUP HEADER (FilmsByGenre) -->
<write>
<![CDATA[
<fo:block font-size="0pt" >
<fo:instream-foreign-object>
<svg:svg width="468pt" height="74pt" viewBox="0 0 468 74" >
<svg:rect x="78" y="45" width="78" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="78" y="55" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="TitleCount"/>
</svg:text>
<svg:rect x="0" y="45" width="78" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="55" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Title count:
</svg:text>
<svg:rect x="156" y="24" width="156" height="21" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="234" y="39" style="font-size:18;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:middle;" >
<xsl:value-of select="@CategoryName"/>
</svg:text>
<svg:rect x="390" y="45" width="78" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="468" y="55" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
<xsl:value-of select="TotalSeats"/>
</svg:text>
<svg:rect x="312" y="45" width="78" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="390" y="55" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Total seats:
</svg:text>
<svg:line x1="0" y1="60" x2="466" y2="60" style="stroke:#000000;stroke-width:2;stroke-opacity:1" />
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
]]>
</write>
<!-- end of GROUP HEADER (FilmsByGenre) -->
<group name='FilmDetail' >
<!-- REPORT BODY (FilmDetail) -->
<write>
<![CDATA[
<fo:block font-size="0pt">
<fo:instream-foreign-object>
<svg:svg width="468pt" height="71pt" viewBox="0 0 468 71" >
<svg:rect x="3" y="4" width="257" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="3" y="14" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="Title"/>
</svg:text>
<svg:rect x="265" y="0" width="66" height="19" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="265" y="10" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Rating
</svg:text>
<svg:rect x="265" y="19" width="66" height="29" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="265" y="27.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
<xsl:value-of select="Rating"/>
</svg:text>
<svg:rect x="330" y="0" width="66" height="19" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="330" y="10" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Length
</svg:text>
<svg:rect x="330" y="19" width="66" height="29" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="330" y="27.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
<xsl:value-of select="Length"/>
</svg:text>
<svg:rect x="3" y="36" width="208" height="19" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="3" y="46" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Description
</svg:text>
<svg:rect x="3" y="52" width="208" height="29" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="3" y="60.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
<xsl:value-of select="Description"/>
</svg:text>
<svg:rect x="409" y="0" width="56" height="19" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="409" y="10" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Sales
</svg:text>
<svg:rect x="409" y="19" width="56" height="29" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="409" y="27.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
<xsl:value-of select="TicketsSold"/>
</svg:text>
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
]]>
</write>
<!-- end of REPORT BODY (FilmDetail) -->
<!-- CONDITIONAL REPORT BODY (FilmDetail) -->
<write>
<![CDATA[
<fo:block font-size="0pt" keep-with-previous.within-page="always">
<xsl:if test="../@CategoryName='Comedy' and TicketsSold&gt;10000" >
<fo:instream-foreign-object>
<svg:svg width="468pt" height="63pt" viewBox="0 0 468 63" >
<svg:rect x="90" y="7" width="298" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="90" y="17" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
Comedies are often cheap to make so good sales usually 
</svg:text>
<svg:rect x="163" y="23" width="131" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="163" y="33" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
translate into pure profit.
</svg:text>
<svg:line x1="0" y1="2" x2="468" y2="2" style="stroke:#000000;stroke-width:1;stroke-opacity:1" />
<svg:line x1="0" y1="41" x2="468" y2="41" style="stroke:#000000;stroke-width:1;stroke-opacity:1" />
</svg:svg>
</fo:instream-foreign-object>
</xsl:if>
</fo:block>
]]>
</write>
<!-- end of CONDITIONAL REPORT BODY (FilmDetail) -->
<!-- CONDITIONAL REPORT BODY (FilmDetail) -->
<write>
<![CDATA[
<fo:block font-size="0pt" keep-with-previous.within-page="always">
<xsl:if test="(../@CategoryName='Action' or ../@CategoryName='Comedy') and TicketsSold&lt;1000" >
<fo:instream-foreign-object>
<svg:svg width="468pt" height="82pt" viewBox="0 0 468 82" >
<svg:rect x="14" y="8" width="181" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="14" y="18" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
Pacing is a major consideration for 
</svg:text>
<svg:rect x="200" y="8" width="87" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="200" y="18" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
<xsl:value-of select="../@CategoryName"/>
</svg:text>
<svg:rect x="12" y="23" width="98" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="12" y="33" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
The running time of 
</svg:text>
<svg:rect x="120" y="23" width="54" height="13" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="120" y="33" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
<xsl:value-of select="Length"/>
</svg:text>
<svg:rect x="18" y="37" width="279" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="18" y="47" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;" >
may have negatively impacted box office performance
</svg:text>
<svg:rect x="310" y="5" width="141" height="46" style="fill-opacity:1;fill:#ffff00;stroke:#000000;stroke-width:3;stroke-opacity:1" />
<svg:rect x="319" y="15" width="126" height="26" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="382" y="35.83333333333333" style="font-size:25;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;font-style:italic;text-anchor:middle;" >
NOTE!!!
</svg:text>
</svg:svg>
</fo:instream-foreign-object>
</xsl:if>
</fo:block>
]]>
</write>
<!-- end of CONDITIONAL REPORT BODY (FilmDetail) -->
</group>
<!-- GROUP FOOTER (FilmsByGenre) -->
<write>
<![CDATA[
<fo:block font-size="0pt" >
<fo:instream-foreign-object>
<svg:svg width="468pt" height="41pt" viewBox="0 0 468 41" >
<svg:line x1="0" y1="25" x2="466" y2="25" style="stroke:#000000;stroke-width:2;stroke-opacity:1" />
<svg:rect x="78" y="28" width="78" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="78" y="38" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="TitleCount"/>
</svg:text>
<svg:rect x="0" y="28" width="78" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="38" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Title count:
</svg:text>
<svg:rect x="390" y="28" width="78" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="468" y="38" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
<xsl:value-of select="TotalSeats"/>
</svg:text>
<svg:rect x="312" y="28" width="78" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="390" y="38" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Total seats:
</svg:text>
</svg:svg>
</fo:instream-foreign-object>
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
<svg:svg width="468pt" height="82pt" viewBox="0 0 468 82" >
<svg:rect x="1" y="25" width="466" height="54" style="fill-opacity:1;fill:#ffffff;stroke:#000000;stroke-width:2;stroke-opacity:1" />
<svg:rect x="0" y="26" width="468" height="20" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="234" y="39.333333333333336" style="font-size:16;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:middle;" >
Annotated Box Office
</svg:text>
<svg:rect x="246" y="46" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="246" y="57.666666666666664" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="TotalTicketsSold"/>
</svg:text>
<svg:rect x="0" y="46" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="222" y="57.666666666666664" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Total tickets sold:
</svg:text>
<svg:rect x="246" y="62" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="246" y="73.66666666666667" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="TotalFilms"/>
</svg:text>
<svg:rect x="0" y="62" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="222" y="73.66666666666667" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Total films:
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

