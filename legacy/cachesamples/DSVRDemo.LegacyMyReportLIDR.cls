/// An auto-fill reformat of the existing Zen report, MyReport, found in SAMPLES 
Class DSVRDemo.LegacyMyReportLIDR Extends %DeepSee.Report.dataPresenter
{

Parameter DEFAULTMODE = "pdf";

Parameter XSLTMODE = "server";

Parameter DSSHOME = "linked";

Parameter DSSCLASS = "DSVRDemo.LegacyMyReportDSS";

XData ReportModel
{
<reportModel>
<![CDATA[

{package:"DSVRDemo",objClass:"LegacyMyReportLIDR",appName:"",sysName:"DSVRDemo.LegacyMyReportLIDR",name:"My Reformatted Report",desc:"An auto-fill reformat of the existing Zen report, MyReport, found in SAMPLES ",type:"DPR",dssHome:"linked",dssClass:"DSVRDemo.LegacyMyReportDSS",pageModel:
{paper:"letter",orient:"portrait",units:"in",width:612,height:792,left:72,right:72,top:72,bottom:72,header:18,footer:18},dssName:"myReport",t:"_LIDR",s:[
{t:"h",g:"_r",a:true,h:"202pt",w:"468pt",b:1,i:[
{t:"box",gc:
{sa:1,sc:"#000000",so:1,sw:"2",ss:"solid",fa:1,fc:"#ffffff",fo:1,xa:0,ta:0,za:1,zw:466,zh:126,zt:73,zl:1},c:"BOX",url:null,durl:null},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:36,xj:"center",xf:"sans-serif",ta:0,za:1,zw:468,zh:44,zt:74,zl:0},c:"CAPN",f:"!My Reformatted Report",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"left",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:118,zl:246},c:"ATTR",f:"@runTime",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"right",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:118,zl:0},c:"CAPN",f:"!Run time:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"left",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:134,zl:246},c:"ATTR",f:"@runBy",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"right",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:134,zl:0},c:"CAPN",f:"!Run by:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"left",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:150,zl:246},c:"ATTR",f:"@author",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"right",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:150,zl:0},c:"CAPN",f:"!Author:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"left",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:166,zl:246},c:"ATTR",f:"@month",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"right",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:166,zl:0},c:"CAPN",f:"!Month:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"left",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:182,zl:246},c:"ELEM",f:"grandTotal",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"right",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:182,zl:0},c:"CAPN",f:"!Grand total:",fn:""}]},
{t:"h",g:"_p",a:true,h:"59pt",w:"468pt",b:0,i:[
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:106,zh:11,zt:33,zl:50},c:"ATTR",f:"@runTime",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:50,zh:11,zt:33,zl:0},c:"CAPN",f:"!Run time:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:106,zh:11,zt:22,zl:50},c:"ATTR",f:"@runBy",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:50,zh:11,zt:22,zl:0},c:"CAPN",f:"!Run by:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:106,zh:11,zt:11,zl:50},c:"ATTR",f:"@author",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:50,zh:11,zt:11,zl:0},c:"CAPN",f:"!Author:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:106,zh:11,zt:0,zl:50},c:"ATTR",f:"@month",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:50,zh:11,zt:0,zl:0},c:"CAPN",f:"!Month:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:22,xj:"right",xf:"sans-serif",ta:0,za:1,zw:156,zh:26,zt:0,zl:312},c:"CAPN",f:"!My Reformatted Report",fn:""},
{t:"line",gc:
{sa:1,sc:"#000000",so:1,sw:"2",ss:"solid",fa:0,xa:0,ta:0,za:1,zw:466,zh:0,zt:45,zl:0}}]},
{t:"h",g:"SalesRep",a:true,h:"103pt",w:"468pt",b:0,i:[
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:18,xj:"center",xf:"sans-serif",ta:0,za:1,zw:156,zh:21,zt:24,zl:156},c:"ATTR",f:"@name",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:96,zh:14,zt:45,zl:372},c:"ELEM",f:"avg",fn:"#.##"},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:60,zh:14,zt:45,zl:312},c:"CAPN",f:"!Avg:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:96,zh:14,zt:59,zl:372},c:"ELEM",f:"subtotal",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:60,zh:14,zt:59,zl:312},c:"CAPN",f:"!Subtotal:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:96,zh:14,zt:73,zl:372},c:"ELEM",f:"count",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:60,zh:14,zt:73,zl:312},c:"CAPN",f:"!Count:",fn:""},
{t:"line",gc:
{sa:1,sc:"#000000",so:1,sw:"2",ss:"solid",fa:0,xa:0,ta:0,za:1,zw:466,zh:0,zt:88,zl:0}}]},
{t:"t",g:"record",a:true,w:"6.5in",l:"0pt",tw:"468pt",i:[
{t:"c",gcH:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#d3d3d3",fo:1,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:1,tb:false,thb:false,thbd:true,thcd:false,tbcd:false,tbrd:false,tzs:true,tzc:"#e9e9e9",za:1,zw:117,zh:20,zt:0,zl:0},f:"@id",gcB:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:1,tb:false,thb:false,thbd:true,thcd:false,tbcd:false,tbrd:false,tzs:true,tzc:"#e9e9e9",za:1,zw:117,zh:52,zt:20,zl:0},c:"Id"},
{t:"c",gcH:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#d3d3d3",fo:1,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:1,tb:false,thb:false,thbd:true,thcd:false,tbcd:false,tbrd:false,tzs:true,tzc:"#e9e9e9",za:1,zw:117,zh:20,zt:0,zl:117},f:"@number",gcB:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:1,tb:false,thb:false,thbd:true,thcd:false,tbcd:false,tbrd:false,tzs:true,tzc:"#e9e9e9",za:1,zw:117,zh:52,zt:20,zl:117},c:"Number"},
{t:"c",gcH:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#d3d3d3",fo:1,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:1,tb:false,thb:false,thbd:true,thcd:false,tbcd:false,tbrd:false,tzs:true,tzc:"#e9e9e9",za:1,zw:117,zh:20,zt:0,zl:234},f:"customer",gcB:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:1,tb:false,thb:false,thbd:true,thcd:false,tbcd:false,tbrd:false,tzs:true,tzc:"#e9e9e9",za:1,zw:117,zh:52,zt:20,zl:234},c:"Customer"},
{t:"c",gcH:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#d3d3d3",fo:1,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"left",xf:"sans-serif",ta:1,tb:false,thb:false,thbd:true,thcd:false,tbcd:false,tbrd:false,tzs:true,tzc:"#e9e9e9",za:1,zw:117,zh:20,zt:0,zl:351},f:"date",gcB:
{sa:1,sc:"#000000",so:1,sw:1,ss:"solid",fa:1,fc:"#ffffff",fo:0,xa:1,xc:"#000000",xo:1,xb:false,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:1,tb:false,thb:false,thbd:true,thcd:false,tbcd:false,tbrd:false,tzs:true,tzc:"#e9e9e9",za:1,zw:117,zh:52,zt:20,zl:351},c:"Date"}]},
{t:"f",g:"SalesRep",a:true,h:"70pt",w:"468pt",b:1,i:[
{t:"line",gc:
{sa:1,sc:"#000000",so:1,sw:"2",ss:"solid",fa:0,xa:0,ta:0,za:1,zw:466,zh:0,zt:25,zl:0}},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:96,zh:14,zt:28,zl:372},c:"ELEM",f:"avg",fn:"#.##"},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:60,zh:14,zt:28,zl:312},c:"CAPN",f:"!Avg:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:96,zh:14,zt:42,zl:372},c:"ELEM",f:"subtotal",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:60,zh:14,zt:42,zl:312},c:"CAPN",f:"!Subtotal:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:96,zh:14,zt:56,zl:372},c:"ELEM",f:"count",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:12,xj:"right",xf:"sans-serif",ta:0,za:1,zw:60,zh:14,zt:56,zl:312},c:"CAPN",f:"!Count:",fn:""}]},
{t:"f",g:"_r",a:true,h:"65pt",w:"468pt",b:0,i:[
{t:"box",gc:
{sa:1,sc:"#000000",so:1,sw:"2",ss:"solid",fa:1,fc:"#ffffff",fo:1,xa:0,ta:0,za:1,zw:466,zh:38,zt:25,zl:1},c:"BOX",url:null,durl:null},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:16,xj:"center",xf:"sans-serif",ta:0,za:1,zw:468,zh:20,zt:26,zl:0},c:"CAPN",f:"!My Reformatted Report",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"left",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:46,zl:246},c:"ELEM",f:"grandTotal",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:14,xj:"right",xf:"sans-serif",ta:0,za:1,zw:222,zh:16,zt:46,zl:0},c:"CAPN",f:"!Grand total:",fn:""}]},
{t:"f",g:"_p",a:true,h:"47pt",w:"468pt",b:0,i:[
{t:"line",gc:
{sa:1,sc:"#000000",so:1,sw:"2",ss:"solid",fa:0,xa:0,ta:0,za:1,zw:466,zh:0,zt:1,zl:0}},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:106,zh:11,zt:2,zl:50},c:"ATTR",f:"@runTime",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:50,zh:11,zt:2,zl:0},c:"CAPN",f:"!Run time:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:106,zh:11,zt:13,zl:50},c:"ATTR",f:"@runBy",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:50,zh:11,zt:13,zl:0},c:"CAPN",f:"!Run by:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:106,zh:11,zt:24,zl:50},c:"ATTR",f:"@author",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:50,zh:11,zt:24,zl:0},c:"CAPN",f:"!Author:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:106,zh:11,zt:35,zl:50},c:"ATTR",f:"@month",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"left",xf:"sans-serif",ta:0,za:1,zw:50,zh:11,zt:35,zl:0},c:"CAPN",f:"!Month:",fn:""},
{t:"txt",gc:
{sa:0,fa:0,xa:1,xc:"#000000",xo:1,xb:true,xi:false,xu:false,xs:10,xj:"right",xf:"sans-serif",ta:0,za:1,zw:156,zh:12,zt:34,zl:312},c:"CAPN",f:"!My Reformatted Report",fn:""}]}]}
]]></reportModel>
}

XData ReportDisplay [ XMLNamespace = "http://www.intersystems.com/zen/report/display" ]
{

<report xmlns="http://www.intersystems.com/zen/report/display"
name="myReport">
	<init>
		<xslt xslfo="ParagraphFunctions" />
	</init>
<document width="612pt" height="792pt" marginLeft="72" marginRight="72" marginTop="72" marginBottom="72" headerHeight="60pt" regionBeforeExtent="58pt" footerHeight="48pt" regionAfterExtent="46pt" />
<pageheader>
<!-- PAGE HEADER -->
<write>
<![CDATA[
<fo:block font-size="0pt" >
<fo:instream-foreign-object>
<svg:svg width="468pt" height="59pt" viewBox="0 0 468 59" >
<svg:rect x="50" y="33" width="106" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="50" y="41.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@runTime"/>
</svg:text>
<svg:rect x="0" y="33" width="50" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="41.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Run time:
</svg:text>
<svg:rect x="50" y="22" width="106" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="50" y="30.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@runBy"/>
</svg:text>
<svg:rect x="0" y="22" width="50" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="30.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Run by:
</svg:text>
<svg:rect x="50" y="11" width="106" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="50" y="19.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@author"/>
</svg:text>
<svg:rect x="0" y="11" width="50" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="19.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Author:
</svg:text>
<svg:rect x="50" y="0" width="106" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="50" y="8.333333333333334" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@month"/>
</svg:text>
<svg:rect x="0" y="0" width="50" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="8.333333333333334" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Month:
</svg:text>
<svg:rect x="312" y="0" width="156" height="26" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="468" y="18.333333333333332" style="font-size:22;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
My Reformatted Report
</svg:text>
<svg:line x1="0" y1="45" x2="466" y2="45" style="stroke:#000000;stroke-width:2;stroke-opacity:1" />
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
<svg:svg width="468pt" height="47pt" viewBox="0 0 468 47" >
<svg:line x1="0" y1="1" x2="466" y2="1" style="stroke:#000000;stroke-width:2;stroke-opacity:1" />
<svg:rect x="50" y="2" width="106" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="50" y="10.333333333333334" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@runTime"/>
</svg:text>
<svg:rect x="0" y="2" width="50" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="10.333333333333334" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Run time:
</svg:text>
<svg:rect x="50" y="13" width="106" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="50" y="21.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@runBy"/>
</svg:text>
<svg:rect x="0" y="13" width="50" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="21.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Run by:
</svg:text>
<svg:rect x="50" y="24" width="106" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="50" y="32.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@author"/>
</svg:text>
<svg:rect x="0" y="24" width="50" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="32.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Author:
</svg:text>
<svg:rect x="50" y="35" width="106" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="50" y="43.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@month"/>
</svg:text>
<svg:rect x="0" y="35" width="50" height="11" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="0" y="43.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
Month:
</svg:text>
<svg:rect x="312" y="34" width="156" height="12" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="468" y="42.333333333333336" style="font-size:10;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
My Reformatted Report
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
<svg:svg width="468pt" height="202pt" viewBox="0 0 468 202" >
<svg:rect x="1" y="73" width="466" height="126" style="fill-opacity:1;fill:#ffffff;stroke:#000000;stroke-width:2;stroke-opacity:1" />
<svg:rect x="0" y="74" width="468" height="44" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="234" y="104" style="font-size:36;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:middle;" >
My Reformatted Report
</svg:text>
<svg:rect x="246" y="118" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="246" y="129.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@runTime"/>
</svg:text>
<svg:rect x="0" y="118" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="222" y="129.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Run time:
</svg:text>
<svg:rect x="246" y="134" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="246" y="145.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@runBy"/>
</svg:text>
<svg:rect x="0" y="134" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="222" y="145.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Run by:
</svg:text>
<svg:rect x="246" y="150" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="246" y="161.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@author"/>
</svg:text>
<svg:rect x="0" y="150" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="222" y="161.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Author:
</svg:text>
<svg:rect x="246" y="166" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="246" y="177.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="@month"/>
</svg:text>
<svg:rect x="0" y="166" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="222" y="177.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Month:
</svg:text>
<svg:rect x="246" y="182" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="246" y="193.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="grandTotal"/>
</svg:text>
<svg:rect x="0" y="182" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="222" y="193.66666666666666" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Grand total:
</svg:text>
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
]]>
</write>
<pagebreak/>
<!-- end of REPORT HEADER -->
<group name='SalesRep' >
<!-- GROUP HEADER (SalesRep) -->
<write>
<![CDATA[
<fo:block font-size="0pt" >
<fo:instream-foreign-object>
<svg:svg width="468pt" height="103pt" viewBox="0 0 468 103" >
<svg:rect x="156" y="24" width="156" height="21" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="234" y="39" style="font-size:18;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:middle;" >
<xsl:value-of select="@name"/>
</svg:text>
<svg:rect x="372" y="45" width="96" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="468" y="55" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
<xsl:value-of select="format-number(avg,'#.##')" />
</svg:text>
<svg:rect x="312" y="45" width="60" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="372" y="55" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Avg:
</svg:text>
<svg:rect x="372" y="59" width="96" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="468" y="69" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
<xsl:value-of select="subtotal"/>
</svg:text>
<svg:rect x="312" y="59" width="60" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="372" y="69" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Subtotal:
</svg:text>
<svg:rect x="372" y="73" width="96" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="468" y="83" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
<xsl:value-of select="count"/>
</svg:text>
<svg:rect x="312" y="73" width="60" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="372" y="83" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Count:
</svg:text>
<svg:line x1="0" y1="88" x2="466" y2="88" style="stroke:#000000;stroke-width:2;stroke-opacity:1" />
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
]]>
</write>
<!-- end of GROUP HEADER (SalesRep) -->
<!-- Start of REPORT BODY (record) -->
<fo><write><![CDATA[
<fo:table space-after="24pt" border-collapse="collapse" inline-progression-dimension="468">
<fo:table-column column-number="1" column-width="-4pt" />
<fo:table-column column-number="2" column-width="472pt" />
<fo:table-body><fo:table-row><fo:table-cell><fo:block></fo:block></fo:table-cell><fo:table-cell>
]]>
</write></fo>
<table orient='col' group='record' altcolor='#e9e9e9' width='468pt' style='margin-left:2pt;margin-right:2pt;' >
<item field='@id' width='117pt' style='font-size:10;font-family:sans-serif;color:#000000;font-weight:normal;font-style:normal;text-decoration:none;text-align:left;'>
<caption value='Id' style='background-color:#d3d3d3;font-size:12;font-family:sans-serif;color:#000000;font-weight:bold;font-style:normal;text-decoration:none;text-align:left;width:117pt;border-bottom:1pt solid #000000;' />
</item>
<item field='@number' width='117pt' style='font-size:10;font-family:sans-serif;color:#000000;font-weight:normal;font-style:normal;text-decoration:none;text-align:left;'>
<caption value='Number' style='background-color:#d3d3d3;font-size:12;font-family:sans-serif;color:#000000;font-weight:bold;font-style:normal;text-decoration:none;text-align:left;width:117pt;border-bottom:1pt solid #000000;' />
</item>
<item field='customer' width='117pt' style='font-size:10;font-family:sans-serif;color:#000000;font-weight:normal;font-style:normal;text-decoration:none;text-align:left;'>
<caption value='Customer' style='background-color:#d3d3d3;font-size:12;font-family:sans-serif;color:#000000;font-weight:bold;font-style:normal;text-decoration:none;text-align:left;width:117pt;border-bottom:1pt solid #000000;' />
</item>
<item field='date' width='117pt' style='font-size:10;font-family:sans-serif;color:#000000;font-weight:normal;font-style:normal;text-decoration:none;text-align:left;'>
<caption value='Date' style='background-color:#d3d3d3;font-size:12;font-family:sans-serif;color:#000000;font-weight:bold;font-style:normal;text-decoration:none;text-align:left;width:117pt;border-bottom:1pt solid #000000;' />
</item>
</table>
<fo><write><![CDATA[
</fo:table-cell></fo:table-row></fo:table-body></fo:table>
]]>
</write></fo>
<!-- End of REPORT BODY (record) -->
<!-- GROUP FOOTER (SalesRep) -->
<write>
<![CDATA[
<fo:block font-size="0pt" >
<fo:instream-foreign-object>
<svg:svg width="468pt" height="70pt" viewBox="0 0 468 70" >
<svg:line x1="0" y1="25" x2="466" y2="25" style="stroke:#000000;stroke-width:2;stroke-opacity:1" />
<svg:rect x="372" y="28" width="96" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="468" y="38" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
<xsl:value-of select="format-number(avg,'#.##')" />
</svg:text>
<svg:rect x="312" y="28" width="60" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="372" y="38" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Avg:
</svg:text>
<svg:rect x="372" y="42" width="96" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="468" y="52" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
<xsl:value-of select="subtotal"/>
</svg:text>
<svg:rect x="312" y="42" width="60" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="372" y="52" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Subtotal:
</svg:text>
<svg:rect x="372" y="56" width="96" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="468" y="66" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
<xsl:value-of select="count"/>
</svg:text>
<svg:rect x="312" y="56" width="60" height="14" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="372" y="66" style="font-size:12;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Count:
</svg:text>
</svg:svg>
</fo:instream-foreign-object>
</fo:block>
]]>
</write>
<pagebreak/>
<!-- end of GROUP FOOTER (SalesRep) -->
</group>
<!-- REPORT FOOTER -->
<write>
<![CDATA[
<fo:block font-size="0pt" >
<fo:instream-foreign-object>
<svg:svg width="468pt" height="65pt" viewBox="0 0 468 65" >
<svg:rect x="1" y="25" width="466" height="38" style="fill-opacity:1;fill:#ffffff;stroke:#000000;stroke-width:2;stroke-opacity:1" />
<svg:rect x="0" y="26" width="468" height="20" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="234" y="39.333333333333336" style="font-size:16;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:middle;" >
My Reformatted Report
</svg:text>
<svg:rect x="246" y="46" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="246" y="57.666666666666664" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;" >
<xsl:value-of select="grandTotal"/>
</svg:text>
<svg:rect x="0" y="46" width="222" height="16" style="fill:#ffffff;fill-opacity:0;stroke-width:0;" />
<svg:text x="222" y="57.666666666666664" style="font-size:14;font-family:sans-serif;fill:#000000;fill-opacity:1;font-weight:bold;text-anchor:end;" >
Grand total:
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

