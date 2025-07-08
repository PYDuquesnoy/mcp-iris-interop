/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class displays a printer friendly version of the class definition.<br/>
/// User may click the "print" link to choose printer, etc.<br/>
/// Other links are disabled except the section labels, such as "Summary", where user may click
/// to collapse the label if they do not wish to print that section.
Class %CSP.Documatic.PrintClass Extends %CSP.Documatic [ System = 4 ]
{

Parameter CSPURL = "/csp/documatic/%CSP.Documatic.PrintClass.cls";

Parameter URL = "%25CSP.Documatic.PrintClass.cls";

/// Event handler for <b>PAGE</b> event: this is invoked in order to  
/// display a csp page. This method is called to render a class document to a browser.
ClassMethod OnPage() As %Status
{
	#; input:  PAGE,LIBRARY, CLASSNAME

	#; test for namespace error

	If $D(%NSerror) {
		Set tNS = $G(%request.Data("LIBRARY",1),..DefaultNS())

		Write "<h2>"_$$$TextHTML("$USERNAME: ")_$USERNAME_"</h2><br/>"
		Write "<h2>"_$$$TextHTML("$ROLES: ")_$ROLES_"</h2><br/>"
		Write "<h2>",$$$TextHTML("Namespace: ")_..EscapeHTML(tNS)_"</h2><br/>"
		Write "<h2>",$$$TextHTML("Unable to display documentation from this namespace because swapping to it generates an error")_"</h2><p>"
		Write "<ul><h3>",$ZCVT(%NSerror,"O","HTML"),"</h3></ul>"
		Quit $$$OK
	}

	Set ReqUrl = %request.URL
	
	Set page=$Get(%request.Data("PAGE",1))
	
	Quit:page="CLASS" ..ServeClassPage()
	
	Quit $$$OK
}

/// Renders the style sheet used by the doc viewer.
ClassMethod ServeStyleSheet() As %Status [ Private ]
{
	#; grad: 200x10 CBE6EB->A0B0D0
 ; STYLE SHEETS
 &html<<style type="text/css">
body {
	margin: 0px;
	font-family: verdana,arial,helvetica,sans-serif;
	color: black;
	background: white;
}
body.Class {   }

body.Index { 
	background: #CBE6EB;
	background-position: right;
	background-repeat: repeat-y;
}
body.Storage { }
body.About { }
body.Search { }

.Summary {
	background: #C0C0C0;
	margin-left: 0px;
	margin-right: 10px;
	border: 1px solid black;
	font-size: 0.8em;
	width: 80%;
}

.SummaryText {
	font-size: 0.8em;
}

.Summary td {
	padding-left: 8px;
	padding-right: 8px;
	background: white;
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
}

.Summary td.private {
	background: #D0D0D0;
}

.Summary th {
	padding-left: 8px;
	padding-right: 8px;
	background: #D0D0FF;
	text-align: left;
	border-right: 1px solid gray;
	border-bottom: 1px solid gray;
}

.Summary a {
	text-decoration: none;
	color: black;
	font-weight: bold;
	display: block;
	width: 100%;
}


div.MainDiv {
	padding-left: 40px;
	padding-right: 40px;
	line-height: 120%;
}

table.ClassBanner { 
	color: white; background: #287780; 
	font-size: 24pt;
}
table.Label { 
	color: black; 
	background: #CBE6EB;
	font-size: 12pt;
	width: 90%;
	border-top: 1px solid #A0C0CB;
}

.IndexLabel {
	padding-left: 20px;
	color: black;
	background: none;
	font-size: 12pt;
	font-weight: bold;
	padding-top: 2%;
	padding-bottom: 2%;
}
table.VersionInfo { color: black; background: #DBF6FB; font-size: 10pt; }

.DivShow { display: block; }
.DivHide { display: none; }

table.ClsSearchResult {
	border: 1px solid black;
}

table.ClsSearchResult td {
	border-bottom: 1px solid gray;
	border-right: 1px solid gray;
	padding: 2px;
	padding-left: 5px;
	padding-right: 5px;
}

table.ClsSearchResult td a:hover {
	color: red;
}

.DarkRow { background: #DDDDDD; }
.LightRow { background: #EEEEEE; }

.IndexText {
	font-weight: bold;
	font-size: 0.8em;
}

div.IndexChoice { 
	font-family: Helvetica,Arial,sans-serif; 
	font-size: 12pt; 
	font-weight: bold; 
	color: black; 
	background: none; 
	border-color: black; 
	border-width: 1px; 
	border-style: none; 
	padding-left: 3%; 
	padding-right: 3%; 
	padding-top: 0%; 
	padding-bottom: 0%; }


div.SampleCode {
	color: black;
	border: 1px solid black;
	font-family: courier new,courier,monospace;
	font-size: 1.2em;
	text-align: left;
	line-height: 125%;
	margin-top: 20px;
	margin-bottom: 10px;
	padding-left: 10px; padding-top: 0px; padding-bottom: 0px;
	background: #C0C0C0;
	background-repeat: repeat-x;
	overflow-x: auto;
}

.StoragePtr { 
	color: black; 
	background: #CBE6EB; 
	font-size: 10pt; 
	border: black solid 1px; 
}
.StorageNode { 
	color: black; 
	background: white; 
	font-size: 10pt; 
	border: black solid 1px; 
}
.StorageSlot { 
	color: black; 
	background: white; 
	font-size: 10pt; 
	border: black solid 1px; 
}
.StorageSingle { }

.StoragePtrSuper { 
	color: black; 
	background: #C0C0C0; 
	font-size: 10pt; 
	border: black solid 1px; 
}
.StorageNodeSuper { 
	color: black; 
	background: white; 
	font-size: 10pt; 
	border: black solid 1px; 
}
.StorageSlotSuper { 
	color: black; 
	background: #C0C0C0; 
	font-size: 10pt; 
	border: black solid 1px; 
}
.StorageSingleSuper { }

a.MethodLink {font-weight: bold; text-decoration: none; }
a.PropertyLink {font-style: italic; text-decoration: none; }
a.QueryLink {font-weight: bold; text-decoration: none; }
a.ParameterLink {font-style: italic; text-decoration: none; }
 
span.internal {
	display: block;
	background: white; 
	color: #808080;
	border-top: 1px solid #DDDDFF; 
	padding-top: 3px;
}
span.external {
	display: block;
	background: white; 
	color: black; 
	border-top: 1px solid #DDDDFF; 
	padding-top: 3px;
}
span.tblhdr {
	color: white; 
	font-weight: bold;
	font-size: 0.8em;
}
table.internal { color: black; background: #F0F0F0; }
table.external { color: black; background: #FFFFFF; }

.header { font-weight: bold; }

/* disable generic a link tag */
a {
    pointer-events: none;
    cursor: default;		
}
td.LocatorBar {
	font-weight: bold;
	background: white;
	background-repeat: repeat-x;
	border-bottom: 1px black solid;
	padding-bottom: 1px;
}

DIV.Locator {
	font-family: Verdana, Arial, Helvetica, sans-serif;
	font-size: 0.8em;
	font-weight: bold;
	color: black;
	text-decoration: none;
	padding-left: 5px;
}

DIV.Locator A {
    pointer-events: none;
	color: black;
	text-decoration: none;
	padding-right: 1px;
	padding-left: 1px;
}
a.PackageChoice {
	pointer-events: auto;
	cursor: pointer;
	font-family: Arial, sans-serif; 
	font-size: 12pt; 
	font-weight: bold; 
	text-decoration: none; 
	color: black; 
	background: none; 
	border-color: black; 
	border-width: 0px; 
	border-style: none; 
	padding-left: 3%; 
	padding-right: 3%; 
	padding-top: 0%; 
	padding-bottom: 0%; }

a.PackageChoiceInt {
	font-family: Arial, sans-serif; 
	font-size: 12pt; 
	font-weight: bold; 
	text-decoration: none; 
	color: gray; 
	background: none; 
	border-color: black; 
	border-width: 0px; 
	border-style: none; 
	padding-left: 3%; 
	padding-right: 3%; 
	padding-top: 0%; 
	padding-bottom: 0%; }
	
a.IndexChoiceInt {
	font-family: Arial, sans-serif; 
	font-size: 10pt; 
	font-weight: bold; 
	text-decoration: none; 
	color: gray; 
	background: none; 
	border-color: black; 
	border-width: 0px; 
	border-style: none; 
	padding-left: 3%; 
	padding-right: 3%; 
	padding-top: 0%; 
	padding-bottom: 0%; }
	
a.IndexChoice {
	font-family: Arial, sans-serif; 
	font-size: 10pt; 
	font-weight: bold; 
	text-decoration: none; 
	color: black; 
	background: none; 
	border-color: black; 
	border-width: 0px; 
	border-style: none; 
	padding-left: 3%; 
	padding-right: 3%; 
	padding-top: 0%; 
	padding-bottom: 0%; 
}
.hier {
	color: #2f6280;
	font-size: 12px;
	font-weight: normal;
	margin-left: 40px;
}
.lev {
	color: #404040;
	font-size: 12px;
	font-weight: normal;
	margin-left: 70px;	
}
.pro {
	color: #9c9a8c;
	font-size: 12px;
	font-weight: normal;
	margin-left: 100px;
}
.indent1 {
	color: #404040;
	font-size: 12px;
	font-weight: normal;
	margin-left: 16px;	
}
table.DetailTable {
	font-size: 11px;
	margin-top: 10px; margin-right: 20px; margin-bottom:10px;
	border: 1px #888888 solid;
}
table.DetailTable th {
	font-size: 12px;
	text-align: left;
	background: #f1f0e7;
	padding: 3 5 3 5;
	border-bottom: 1px #888888 solid;
}
table.DetailTable td {
	text-align: left;
	padding: 3 5 3 5;
}
table.DetailTable tr.DarkRow { background: #F1F0E7; }
table.DetailTable tr.LiteRow { background: white; }
table.DetailTable tr.DiffRow { background: #F3E799; }

</style>
<script language="JavaScript" type="text/javascript">
 function expandIt(Id) {
 whichEl = eval("Id" + Id);
 whichIm = eval("Im" + Id);
 if (whichEl.style.display == 'none') {
 whichEl.style.display = '';
 whichIm.src = "../docbook/ExpandedMarker.jpg"; }
 else {
 whichEl.style.display = 'none';
 whichIm.src = "../docbook/ContractedMarker.jpg"; }
 return; }
 </script>
>
 Quit $$$OK
}

ClassMethod RenderBanner(title As %String, %library As %String, class As %String) As %Status [ Private ]
{
	Set isClass = (class'="")&&$$$defClassDefined(class)
	Set tBookTitle = $$$TextHTML("Class Reference")
	Set tTitle = ..EscapeHTML(title)

	Set ServerName = $zu(110)
	Set InstanceName = $P($zu(86),"*",2)

	Set cmdDocs = $$$TextHTML("DocBook")
	Set cmdStorage = $$$TextHTML("Storage")
	Set cmdSearch = $$$TextHTML("Search")
	Set cmdDefinition = $$$TextHTML("Definition")
	
	Set urlDocs = ##class(%CSP.Page).Link("/csp/docbook/DocBook.UI.Page.cls")
	Set urlSearch = ##class(%CSP.Page).Link(..#URL_"?PAGE=SEARCH&LIBRARY="_$ZCVT($get(%library,$namespace),"O","URL")_"&CLASSNAME="_$ZCVT(class,"O","URL"))

	Set msgDocs = $$$TextHTML("Go to the Documentation Home Page")
	Set msgSearch = $$$TextHTML("Go to the Class Search Page")

	Set cmdPrivate = $$$Text("Private")
	Set msgPrivate = $$$Text("Show private members of this class")

	Set cmdStorage = $$$Text("Storage")
	Set msgStorage = $$$Text("Show storage for this class")

	Set cmdServer = $$$TextHTML("Server")
	Set cmdInstance = $$$TextHTML("Instance")

	Set msgServer = $$$TextHTML("Name of the machine this system is running on")
	Set msgInstance = $$$TextHTML("Configuration name of this system")

	&html<
   <table width="100%" border="0" cellpadding="0" cellspacing="0" style="font-size: 10pt;">
   <tr>
   <td nowrap width="100" bgcolor="white" valign="top" align="left" >&nbsp;
   </td>
   <td nowrap bgcolor="white" valign="top" align="left" style="padding-left: 20px;">
   <div class="wizardltlabel" style="margin-top:6px;"><span style="font-size:11pt; padding-right:5px;">#(tBookTitle)#</span></div>
   <div style="margin-top:4px; font-weight: bold; font-size:13pt;">#(tTitle)#</div>
   </td>
   <td valign="bottom">
   <table border="0">
	<tr><td title="#(msgServer)#" class="quote-name" style="text-align: left;" nowrap><span style="font-size:8pt; padding-right:5px;">#(cmdServer)#:</span><b>#(ServerName)#</b></td></tr>
	<tr><td title="#(msgInstance)#" class="quote-name" style="text-align: left;" nowrap><span style="font-size:8pt; padding-right:5px;">#(cmdInstance)#:</span><b>#(InstanceName)#</b></td></tr>>
	Do ..DrawUsername()
   &html<
   </table>
   </td>
   <td>&nbsp;</td>
	</tr>
	</tr>
	<table width="100%" border="0" cellpadding="0" cellspacing="0" style="font-size: 10pt;">
	<tr>
	<td colspan="#(4+$S(isClass:0,1:1))#" bgcolor="black"><img src='#(##class(%CSP.Page).Link("/csp/sys/images/spacer.gif"))#' width="100%" height="2" alt="-" border="0"></td>
	</tr>
	<tr>>

	#; locator
	#; namespace
	Set tLocator=1
	Set tLocator(1) = $LB("",$get(%library,$namespace))

	#; pull apart class name
	Set tLink = ""
	If (class '= "") {
		For n = 1:1:$L(class,".") {
			Set tLocator=tLocator+1
			Set tName = $P(class,".",n)
			Set tLink = tLink _ $S(tLink="":"",1:".") _ tName
			Set tLocator(tLocator) = $LB(tLink,tName)
		}
	}
	Set tCount = +$G(tLocator)

	&html<<td class="LocatorBar" colspan="2" valign="middle">>
	&html<<div align="left" class="Locator">&nbsp;>

	If (tCount > 0) {
		For i = 1:1:tCount {
			Set tLink = "%25CSP.Documatic.cls?PAGE=CLASS&LIBRARY="_$ZCVT($get(%library,$namespace),"O","URL")_"&CLASSNAME="_$ZCVT($LG(tLocator(i),1),"O","URL")
			Set tLink = ##class(%CSP.Page).Link(tLink)
			Set tCaption = $ZCVT($LG(tLocator(i),2),"O","HTML")
			Set tHelp = tCaption
			&html<<nobr>[<a title="#(tHelp)#" href="#(tLink)#">#(tCaption)#</a>]#($S(i=tCount:"",1:"&nbsp;&gt;&nbsp;"))#</nobr>>
		} 
	}
	&html<</div>>
	&html<</td>>

	If (isClass) {
		Set private = $S(+$get(%request.Data("PRIVATE",1)):"checked",1:"")
		Set storage = $S("STORAGE"=$get(%request.Data("PAGE",1)):"checked",1:"")
		&html<<td class="LocatorBar" align="right">
		<span title="#(msgPrivate)#"><input id="cbPrivate" type="checkbox" #(private)# /><span>#(cmdPrivate)#</span></span>&nbsp;
		<span title="#(msgStorage)#"><input id="cbStorage" type="checkbox" #(storage)# /><span>#(cmdStorage)#</span></span></td>>
	}
	&html<</table>>
}

/// Draw username or server name depend on setup.
ClassMethod DrawUsername()
{
	Set msgUser = $$$TextHTML("User")
	Set msgServer = $$$TextHTML("Server")
	Set msgInstance = $$$TextHTML("Instance")
	Set hlpUser = $$$TextHTML("Name of user logged into this session")

	&html<<tr><td title="#(hlpUser)#" style="text-align: left;">
	<span style="font-size:8pt; padding-right:5px;">#(msgUser)#:</span><b>#($UserName)#</b></td></tr>
	>
}

/// Display Printer link
ClassMethod RenderPrinter() [ Private ]
{
	Set tPrintImage = ..Link("/csp/broker/deepsee/printer_24.png")
	Set tPrintTitle = $$$TextHTML("Print")
	&html<<div align="right" valign="moddle" style="margin-right:8px;">
	<a href="javascript:window.print();" title="#(tPrintTitle)#" target="_top" style="pointer-events:auto;cursor:pointer;">
	<img src="#(tPrintImage)#" width="24" height="24" border="0"></a></div>>
}

}
