/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. 
/// There is no guarantee made about either the behavior or future operation of this class.<p>
/// Automatic HTML Document Generator for InterSystems IRIS classes.
/// 
/// <p>To use, point a browser at: 
/// <a href="http://127.0.0.1:1972/csp/documatic/%25CSP.Documatic.cls" target="_blank">http://127.0.0.1:1972/csp/documatic/%25CSP.Documatic.cls</a>.</p>
/// <p>The documentation for a class can consist of just plain text, or it may have embedded HTML tags.  
/// When present, these tags are also sent to the browser displaying the class page.  
/// Thus, it is possible to exert finer control over the presentation of class information such as
/// list formatting, definitions, even tables.
/// <P>If HTML is used to enhance the display, the user should take care to follow the HTML standard and
/// insert as little markup as necessary to accomplish the job.  The reason for this is that the
/// class documentation may be viewed on many different browsers, each of which has its own
/// extensions.  The closer the HTML is to the standard (and to those features of the standard that all browsers support),
/// the better the chance that the information will appear the same on all displays.
/// <p>Documatic also supports several special tags in addition to those defined by HTML:
/// <ul>
/// <li><b>&lt;CLASS&gt;</b>Classname<b>&lt;/CLASS></b> This produces a link that when clicked on will
/// take you to the documentation for the class named 'Classname'.</li>
/// <li><b>&lt;METHOD></b>Method<b>&lt;/METHOD></b> Produces a link that will take you to the method
/// called 'Method' in the current class. The name of the method will be displayed with trailing parentheses.</li>
/// <li><b>&lt;PROPERTY></b>Property<b>&lt;/PROPERTY></b> Produces a link that will take you to the
/// documentation for property 'Property' in the current class.</li>
/// <li><b>&lt;QUERY></b>Query<b>&lt;/QUERY></b> Produces a link that will take you to the 
/// documentation for the query 'Query' in the current class. The name of the query will be displayed with trailing parentheses.</li>
/// <li><b>&lt;PARAMETER></b>Parameter<b>&lt;/PARAMETER></b> produces a link to the given parameter
/// in the current class.</li>
/// <li><b>&lt;EXAMPLE></b>Set A="Test<b>&lt;/EXAMPLE></b> formats the enclosed text 
/// as a formatted code example, which will include syntax colorizing if possible (using
/// <CLASS>%Library.SyntaxColor</CLASS>).
/// <p>By default, the syntax colorizer treats the example as ObjectScript.
/// To specify another language, include the LANGUAGE attribute. Other languages
/// include SQL, JAVA, and XML.
/// To list the languages currently supported, call the Languages() instance 
/// method of <CLASS>%Library.SyntaxColor</CLASS>:</p>
/// <EXAMPLE>
/// set colorizer=##class(%Library.SyntaxColor).%New()
/// set status=colorizer.Languages(.langlist)
/// zw langlist
/// </EXAMPLE>
/// To suppress syntax colorizing, use <span>&lt;EXAMPLE LANGUAGE=NONE>.</span>
/// </p>
/// <p>NOTE: You can include the other special tags inside &lt;EXAMPLE>, but other HTML 
/// tags are ignored in this context.</p></li>
/// </ul>
Class %CSP.Documatic Extends %CSP.Page [ System = 3 ]
{

Parameter CSPURL = "/csp/documatic/%CSP.Documatic.cls";

Parameter DEFAULTNS = "%SYS";

Parameter EMPTYNS = "-EMPTY NAMESPACE-";

Parameter URL = "%25CSP.Documatic.cls";

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

ClassMethod zzzText(text As %String) As %String [ Internal ]
{
   Quit (text)
}

ClassMethod zzzTextHTML(text As %String) As %String [ Internal ]
{
   Quit ($ZCONVERT(text,"O","HTML"))
}

ClassMethod zzzTextJS(text As %String) As %String [ Internal ]
{
   Quit ($ZCONVERT(text,"O","JS"))
}

/// Returns true if we are talking to an IE browser.
ClassMethod isIE() As %Boolean [ CodeMode = expression, Private ]
{
%request.UserAgent["MSIE"
}

/// Returns true if we should use dynamic HTML.
ClassMethod useDHTML() As %Boolean [ Private ]
{
	Quit:(%request.UserAgent["MSIE") 1
	Quit:(%request.UserAgent["Mozilla/5") 1
	Quit 0
}

ClassMethod ShowInternal() As %Integer [ Internal ]
{
   Quit ((","_$ROLES_",")[",ISC_Internal,")||$get(^%SYS("Studio","ShowHidden"))
}

ClassMethod IsInternal(item, desc As %String) As %Integer [ Internal ]
{
   Quit (desc["**UNPUBLISHED**" || (item.Internal))
}

ClassMethod IsHidden(classname As %String) As %Integer [ Internal ]
{
	Set uname = $ZCVT(classname,"U")
	Set props=$GET(^rINDEXCLASS(uname))
	Quit +$LISTGET(props,4,0)
}

ClassMethod IsObsolete(classname As %String) As %Integer [ Internal ]
{
	If $p(classname, ".", 1) = "%LIBRARY" {
		RETURN 0
	}
	RETURN 1
}

ClassMethod FmtInternal(internal As %Integer) As %String [ Internal ]
{
	Set val="<span class=""external"">"
	Set:(internal) val="<span class=""internal"">"
	Quit val
}

ClassMethod EndFmt(internal As %Integer) As %String [ Internal ]
{
   Quit "</span>"
}

ClassMethod DefaultNS() As %String
{
	Do List^%SYS.NAMESPACE(.ListNS,0,0,1)
	Set ChoiceNS=$ORDER(ListNS(""))
	Quit:(ChoiceNS="") ..#EMPTYNS
	Set:($DATA(ListNS(..#DEFAULTNS))) ChoiceNS=..#DEFAULTNS
	Quit ChoiceNS
}

ClassMethod SwapNS(Namespace As %String) As %Boolean
{
	Kill %NSerror
	If (Namespace=..#EMPTYNS) {
		Quit 0
	}
	Set ns=$namespace
	Set return=0
	Try {
		If ($zcvt(Namespace,"U") = "ENSLIB") && ##class(%Library.EnsembleMgr).IsEnsembleInstalled() {
			Set Namespace = ##class(%Library.EnsembleMgr).GetENSLIB(1)
		}
		Set Namespace = $zcvt(Namespace,"I","URL")
		Set $namespace = Namespace
		If $data(^XYZZZZABC)
		$$$IsClassDefVersionMatched(ismatched)
		If ismatched=0 {
			Write "<h2>",$$$TextHTML("Unable to display documentation because the class definitions in namespace '"),..EscapeHTML($namespace),$$$TextHTML("' need to be upgraded.")_"</h2>"
			Write "<div>Do $system.OBJ.Upgrade()</div>"
			Write "<br><h3>$zversion="_..EscapeHTML($zversion)_"</h3>",!
			Set return=1
		}
	}
	Catch {
		Set %NSerror = $ZE
		Set $namespace = ns
		Set return = 1
	}
	Quit return
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
	background-image: url('#(..Link("/csp/broker/images/docindexgradient.png"))#');
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

.Summary td:hover {
	background: yellow;
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

.Summary a.JS {
	text-decoration: none;
	color: blue;
	font-weight: bold;
}

.Summary a.inherited {
	text-decoration: none;
	color: black;
	font-weight: normal;
	font-style: italic;
}

.Summary a.inheritedJS {
	text-decoration: none;
	color: #2020F0;
	font-weight: normal;
	font-style: italic;
}

.Summary a.className {
	text-decoration: none;
	color: black;
	font-weight: normal;
}

.Summary a.pkgName {
	text-decoration: none;
	color: darkblue;
	font-weight: bold;
}

.Summary a.nsName {
	text-decoration: none;
	color: black;
	font-weight: normal;
}

.Summary td.nsNameCurr {
	background: pink;
}

.Summary td.sysItem {
	background: #F0F0FF;
}

.Summary a.nsNameCurr {
	text-decoration: none;
	color: black;
	font-weight: bold;
}

.Summary a.deprecated {
	text-decoration: line-through;
}

span.deprecated {
	border: 1px solid gray;
    padding: 2px;
    margin-right: 5px;
    border-radius: 5px;
    color: white;
    background-color: gray;
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
	color: darkblue;
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

a.PackageChoice {
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
	padding-bottom: 0%; }

a.SearchResult {
	font-family: Arial, sans-serif; 
	font-size: 10pt; 
	font-weight: bold; 
	text-decoration: none; 
	color: black; 
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
	background-image: url('#(..Link("/csp/broker/images/grad-halfgray-10x500.png"))#');
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
	color: white; 
	background: #287780; 
	font-size: 10pt; 
	border: black solid 1px; 
}
.StorageSlot { 
	color: black; 
	background: #CBE6EB; 
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
	color: white; 
	background: #287780; 
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
span.sqltext { font-family: Courier, Courier-New, monospaced; }
table.internal { color: black; background: #F0F0F0; }
table.external { color: black; background: #FFFFFF; }

.header { font-weight: bold; }

td.LocatorBar {
	color: darkblue;
	font-weight: bold;
	background: #A0B088;
	background-image: url('#(..Link("/csp/broker/images/locatorgradient.png"))#');
	background-repeat: repeat-x;
	border-bottom: 1px darkblue solid;
	padding-bottom: 1px;
}

DIV.Locator {
	font-family: Verdana, Arial, Helvetica, sans-serif;
	font-size: 0.8em;
	font-weight: bold;
	color: darkblue;
	text-decoration: none;
	padding-left: 5px;
}

DIV.Locator A {
	color: darkblue;
	text-decoration: none;
	padding-right: 1px;
	padding-left: 1px;
}

DIV.Locator A:visited {
	color: darkblue;
}

DIV.Locator A:hover {
	color: red;
	background: #FFFAE7;
}

A.buttonStyleON
{
	COLOR: darkblue;
	FONT-FAMILY: Verdana, Arial, Helvetica, sans-serif;
	FONT-SIZE: 12px;
	TEXT-DECORATION: none;
	padding-left: 2px;
	padding-right: 2px;
}
A.buttonStyleON:visited
{
	COLOR: darkblue;
	TEXT-DECORATION: none;
	padding-left: 2px;
	padding-right: 2px;
}
A.buttonStyleON:hover
{
	COLOR: red;
	padding-left: 2px;
	padding-right: 2px;
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
	color: #2f6280;
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


a.hidden, font.hidden {
	color: grey;
}

</style>

 <script language="JavaScript" type="text/javascript">
 function expandIt(Id) {
 whichEl = eval("Id" + Id);
 whichIm = eval("Im" + Id);
 if (whichEl.style.display == 'none') {
 whichEl.style.display = '';
 whichIm.src = "/csp/sys/images/ExpandedMarker.jpg"; }
 else {
 whichEl.style.display = 'none';
 whichIm.src = "/csp/sys/images/ContractedMarker.jpg"; }
 return; }
 
function togglePrivate(flag) {
	var url;
	var s;
	var t;
	url = self.document.location.toString();
	t = url.split('?');
	s = t[1].split('&PRIVATE');
	if (flag) {
		self.document.location = '#(..#URL)#?' + s[0] + '&PRIVATE=1';
	}
	else {
		self.document.location = '#(..#URL)#?' + s[0];
	}
 }

function toggleStorage(flag) {
	var url;
	var s;
	var t;
	url = self.document.location.toString();
	t = url.split('?');
	if (t[1].indexOf('PAGE=STORAGE') != -1) {
		 s = t[1].split('PAGE=STORAGE');
	}
	else if (t[1].indexOf('PAGE=CLASS') != -1) {
		 s = t[1].split('PAGE=CLASS');
	}
	else {
		return;
	}
	
	if (flag) {
		self.document.location = '#(..#URL)#?' + s[0] + 'PAGE=STORAGE' + s[1];
	}
	else {
		self.document.location = '#(..#URL)#?' + s[0] + 'PAGE=CLASS' + s[1];
	}
 }
 </script> >

 Quit $$$OK
}

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

	If '$data(%request.Data("REFERER")),$data(%request.CgiEnvs("HTTP_REFERER")),$piece(%request.CgiEnvs("HTTP_REFERER"),"/",4,5)="csp/documatic",$piece(%request.CgiEnvs("HTTP_REFERER"),"/",6)'["CSP.Documatic.cls" Set %request.Data("REFERER",1)=%request.CgiEnvs("HTTP_REFERER")
	If '$Data(%request.Data("PAGE",1)) Quit ..ServeFrameSet()

	Set page=$Get(%request.Data("PAGE",1))
	
	Quit:page="INDEX" ..ServeIndexPage()
	Quit:page="CLASS" ..ServeClassPage()
	Quit:page="SEARCH" ..ServeSearchPage()
	Quit:page="STORAGE" ..ServeStoragePage()
	
	Write $$$Text("Documatic Error: <b>Invalid PAGE value</b>.")
	Quit $$$OK
}

/// Write out any cookies we want to hold onto.
ClassMethod OnPreHTTP() As %Boolean
{
	If $data(%request.Data("EXPAND",1)) Do %response.SetCookie("EXPAND",%request.Data("EXPAND",1),$ZDate($H+10,2)_" 01:00:00 GMT")

	Set tNS = $G(%request.Data("LIBRARY",1),..DefaultNS())
	Do ..SwapNS(tNS)

	Quit $$$OK
}

/// Renders the frameset (main) page for the document viewer.
ClassMethod ServeFrameSet() As %Status [ Private ]
{
	#; create frames
	#; input:  LIBRARY, CLASSNAME, MEMBER

	Set %library="",classname="",member="",referer="",package=""
	
	Set:$data(%request.Data("CLASSNAME",1)) classname="&CLASSNAME="_..EscapeURL(%request.Data("CLASSNAME",1))
	Set:$data(%request.Data("LIBRARY",1)) %library="&LIBRARY="_..EscapeURL(%request.Data("LIBRARY",1))
	If $data(%request.Data("MEMBER",1),member) Set member="&PRIVATE=1#"_..EscapeURL(member)
	Set:$data(%request.Data("REFERER")) referer="&REFERER="_..EscapeURL(%request.Data("REFERER",1))
	Set:$data(%request.Data("PACKAGE",1)) package="&PACKAGE="_+(%request.Data("PACKAGE",1))

	Set msgTitle = $$$Text("Documatic - Online class documentation")

	&html<<html><title>#(msgTitle)#</title>>

	If $G(%request.Data("SHOWCLASSONLY",1)) = 1 {
		&html<<frameset cols="*">>
		&html<<frame src="#(..#URL)#?PAGE=CLASS&SHOWCLASSONLY=1&#(%library_classname_referer_member_package)#" name="ClassFrame" title="DocPage" >>		 
	} Else {	
		&html<<frameset cols="25%,*">>
		&html<<frame src="#(..#URL)#?PAGE=INDEX#(%library_classname_referer)#" name="IndexFrame" title="Index" MARGINWIDTH=0 MARGINHEIGHT=0 FRAMESPACING=0 FRAMEBORDER=NO>>
		&html<<frame src="#(..#URL)#?PAGE=CLASS#(%library_classname_referer_member_package)#" name="ClassFrame" title="DocPage" >>
	}
	&html<</frameset>>
	&html<</html>>
	
	Quit $$$OK
}

/// Renders the index frame page for the document viewer.
ClassMethod ServeIndexPage() As %Status [ Private ]
{
	#; input:  LIBRARY,EXPAND
	
	Set %library=$get(%request.Data("LIBRARY",1),(..DefaultNS()))
	Set expand=$get(%request.Data("EXPAND",1))
	
	Do ..RenderIndexPage(%library,expand)
	do ..MakeCopyrightDiv()
	
	Quit $$$OK
}

/// Renders the class frame page for the document viewer.
ClassMethod ServeClassPage() As %Status [ Private ]
{
	#; input:  CLASSNAME,LIBRARY
	#; get classname & %library
	Set %library=$get(%request.Data("LIBRARY",1),(..DefaultNS()))

	Set classname=..EscapeHTML($get(%request.Data("CLASSNAME",1)))
	Set PACKAGE = +$get(%request.Data("PACKAGE",1))
	Set cdef="",type="Class",displaytype=$$$Text("Class")

	If classname'="" {
		#; If PACKAGE is defined in the URL or
		#; if the class definition doesn't exist and there is meta data for the package,
		#; then show package info
		If (PACKAGE || ('$$$defClassDefined(classname) && $Data($$$PACKAGE(classname)))) {
			#; is there meta data for this package?
			Set type="Package"
			Set displaytype=$$$Text("Package")
		}
		Else {
			Set cdef=##class(%ClassDefinition).%OpenId(classname)

			#; See if this is a package name. ???
			If ((cdef="")&&('$Data(^rINDEXCLASS($ZCVT(classname,"U"))))) {
				Set type="Package"
				Set displaytype=$$$Text("Package")
			}
		}
	}
	
	#;HEADER
	&html<<html>
<meta name="Generator" content="Documatic">
<title>#(displaytype)# #(classname)#</title>
<head>>
	
	#; STYLE SHEETS
	Do ..ServeStyleSheet()
	
	// special handling when the page was loaded from Studio
	If %session.EventClass="%CSP.StudioTemplateEvent" {
		Write ..HyperEventHead()
		&html<<script type="text/javascript">
		setInterval(()=>#call(..CheckSession())#,60000);
		
		function cspRunServerMethodError(errortext,error) {
			// hyperevent failed: session  must have ended
			top.document.location.reload();
		}
		</script>>
	} Else {
		Do ##class(%CSP.Util.AutoPage).DrawAutoLogout()
	}
	
	&html<</head>>
	
	&html<<body class="Class">>
	
	#; BODY
	#; Do not show banner if this is from a SHOWCLASSONLY is true (e.g. from SMP).
	If $G(%request.Data("SHOWCLASSONLY",1)) '= 1 {
		Do ..RenderBanner($S(classname="":"",1:classname),%library,classname)
	}
	#; Display printer friendly link
	Do ..RenderPrinter()

	&html<<div class="MainDiv">>
	
	If classname="" {
		Do ..RenderNameSpacePage()

	} ElseIf type="Package" {
		Do ..RenderPackagePage(classname)
	} ElseIf cdef="" {
		Set msgUnable = $$$FormatText($$$Text("Unable to find class '%1'."),classname)
		&html<<br><br>#(msgUnable)#>
	} Else {
		Do ..RenderClassPage(cdef,$get(%request.Data("PRIVATE",1)))
	}
	
	#; FOOTER
	&html<</div>>
	&html<<hr/><br/>>
	&html<</body></html>>
	do ..MakeCopyrightDiv()
	
	Quit $$$OK
}

ClassMethod CheckSession()
{
	return
}

/// Renders the class frame page for the document viewer.
ClassMethod ServeStoragePage() As %Status [ Private ]
{
	#; input:  CLASSNAME,LIBRARY
	
	#; get classname & %library
	Set %library=$get(%request.Data("LIBRARY",1),"%SYS")
	Set classname=$get(%request.Data("CLASSNAME",1))
	Set cdef=""
	
	Set:classname'="" cdef=##class(%ClassDefinition).%OpenId(classname)

	#;HEADER
	&html<<html>
<meta name="Generator" content="Documatic">
<title>#(classname)# Storage</title>
<head>>
	
	#; STYLE SHEETS
	Do ..ServeStyleSheet()
	
	&html<</head>>
	
	&html<<body class="Storage">>
	
	#; BODY
	Do ..RenderBanner($S(classname="":$$$Text("Class Reference"),1:classname),%library,classname)
	
	&html<<div class="MainDiv">>

	If classname="" {
		&html<<br><b>#($$$TextHTML("Welcome to the <i>Class Reference"))#</i></b>.
<br><br>#($$$TextHTML("Select a class from the list on the left to view its documentation."))#>
	} ElseIf cdef="" {
		&html<<br><br>#($$$TextHTML("Unable to find class "))#<b>#(..EscapeHTML(classname))#</b>.>
	} Else {
		Do ..RenderStoragePage(cdef)
	}

	#; FOOTER
	&html<</div>>
	&html<<hr/>>
	&html<</body></html>>
	do ..MakeCopyrightDiv()
	
	Quit $$$OK
}

/// Renders the search page for the document viewer.
ClassMethod ServeSearchPage() As %Status [ Private ]
{
	#; input:  LIBRARY
	#; pg1 ask for input
	#; pg2 input = TYPE, MEMBER, SEARCH, CLASSNAME
	
	#; get inputs
	Set %library=$get(%request.Data("LIBRARY",1),"%SYS")
	Set search=$get(%request.Data("SEARCH",1))
	Set type=$get(%request.Data("TYPE",1))
	Set member=$get(%request.Data("MEMBER",1))
	Set cls=$get(%request.Data("CLASSNAME",1))
	
	#; switch to %library namespace
	Set namespace=$namespace
	If ..SwapNS(%library) Quit $$$OK
	
	If type="" { Set title=$$$Text("Search Page") } Else { Set title=$$$Text("Search Results") }
	
	#;HEADER
	Set msgTitle = $$$Text("Documatic Search Page")
	&html<<html>>
	&html<<meta name="Generator" content="Documatic">>
	&html<<title>#(msgTitle)#</title>>
	&html<<head>>
	
	; STYLE SHEETS
	Do ..ServeStyleSheet()
	
	; scripts
	Set msgNoSearch = $$$TextJS("Please enter a name to search for.")
	
	&html<<script language="JavaScript" type="text/javascript">
function showResults() {
// submit the input form-show the results
var idx,search,type,member,cls;

idx = self.document.SearchForm.selSearch.selectedIndex;
idx = (idx > 0 ) ? idx : 0;
search = self.document.SearchForm.selSearch.options[idx].value;

idx = self.document.SearchForm.selType.selectedIndex;
idx = (idx > 0 ) ? idx : 0;
type = self.document.SearchForm.selType.options[idx].value;

var member = self.document.SearchForm.txtMember.value;

idx = self.document.SearchForm.selClassName.selectedIndex;
idx = (idx > 0 ) ? idx : 0;
cls = self.document.SearchForm.selClassName.options[idx].value;

if ((search == 'define' || search == 'implement') && member == '') {
alert('#(msgNoSearch)#');
return; }

self.document.location = '#(..#URL)#' + '?LIBRARY=#(..EscapeURL(%library))#&PAGE=SEARCH' + '&SEARCH=' + encodeURIComponent(search) + '&TYPE=' + encodeURIComponent(type) + '&MEMBER=' + encodeURIComponent(member) + '&CLASSNAME=' + encodeURIComponent(cls);
return; }

function updateControls() {
// enable/disable controls based on query
var idx,value;

idx = self.document.SearchForm.selSearch.selectedIndex;
idx = (idx > 0 ) ? idx : 0;
value = self.document.SearchForm.selSearch.options[idx].value;

if (value == 'derive' || value == 'reference') {
self.document.SearchForm.selType.disabled = true;
self.document.SearchForm.txtMember.disabled = true;
self.document.SearchForm.selClassName.disabled = false; }
else {
self.document.SearchForm.selType.disabled = false;
self.document.SearchForm.txtMember.disabled = false;
self.document.SearchForm.selClassName.disabled = true; }
return; }

</script>>
	
	&html<</head>>
	&html<<body class=Search>>
	
	Do ..RenderBanner(title,%library,cls)
	&html<<div class="MainDiv">>
	
	#; BODY
	If type="" { Do ..SearchForm(%library,cls) } Else { Do ..SearchResults(%library,search,type,member,cls) }
	
	#; FOOTER
	&html<</div>>
	&html<</body></html>>
	do ..MakeCopyrightDiv()
	
	Quit $$$OK
}

/// Renders the search page input form.
ClassMethod SearchForm(%library As %String, class As %String = "") [ Private ]
{
	Set msgMain = $$$FormatText($$$Text("Find all classes in namespace '%1' that meet the following conditions:"),..EscapeHTML(%library))
	Set msgSearchFor = $$$Text("Search for:")
	Set msgName = $$$Text("Name:")
	Set msgType = $$$Text("Type:")
	Set msgClass = $$$Text("Class:")
	Set msgSearch = $$$Text("Search")

	Set msgDEFINE = $$$Text("All classes that DEFINE")
	Set msgIMPLEMENT = $$$Text("All classes that IMPLEMENT")
	Set msgREFERENCE = $$$Text("All classes that REFERENCE")
	Set msgDERIVE = $$$Text("All classes that are DERIVED FROM")

	Set msgMethod = $$$Text("Method")

	Set msgParameter = $$$Text("Parameter")
	Set msgProperty = $$$Text("Property")
	Set msgQuery = $$$Text("Query")

	&html<<br>#(msgMain)#
<br>
<form name="SearchForm" onsubmit="showResults(); return false;">
<table cols="*,100%" cellspacing="5" cellpadding="2">

<tr>
<div name=RowSearch class=DivShow>
<td align="right">
<b>#(msgSearchFor)#</b>
</td>
<td>
<select name="selSearch" onchange="updateControls();">
<option value="define">#(msgDEFINE)#</option>
<option value="implement">#(msgIMPLEMENT)#</option>
<option value="reference">#(msgREFERENCE)#</option>
<option value="derive">#(msgDERIVE)#</option>
</select>
</td>
</div>
</tr>
	
<tr>
<div name="RowType" class="DivShow">
<td align="right">
<b>#(msgType)#</b>
</td>
<td>
<select name="selType">>
	Write "<option value=""method,"_$$$cCLASSmethod_""">"_msgMethod_"</option>",!
	Write "<option value=""parameter,"_$$$cCLASSparameter_""">"_msgParameter_"</option>",!
	Write "<option value=""property,"_$$$cCLASSproperty_""">"_msgProperty_"</option>",!
	Write "<option value=""query,"_$$$cCLASSquery_""">"_msgQuery_"</option>",!
	&html<</select>
</td>
</div>
</tr>
	
<tr>
<div name="RowMember" class="DivShow">
<td align="right">
<b>#(msgName)#</b>
</td>
<td>
<input name="txtMember" type="text" size="30">
</td>
</div>
</tr>

<tr>
<div name="RowClass" class="DivShow">
<td align="right">
<b>#(msgClass)#</b>
</td>
<td>
<select name="selClassName">>
	#; fill option box with list of classes
	Do ..GetClassList(.classlist,1,1)
	
	Set i=""
	For  Set i=$Order(classlist(i)) Quit:i=""  Do
	. Set classname=classlist(i)
	. &html<<option value="#(classname)#" #($S(classname=class:"selected",1:""))#>#(..EscapeHTML(classname))#</option>>
	
	&html<</select>
</td>
</div>
</tr>
<tr>
<td align=right></td>
<td><input name="btnSearch" type="submit" value="#(msgSearch)#"></td>
</tr>
</table>
</form>
	
<script language="JavaScript" type="text/javascript">
updateControls();
</script>>

	Quit
}

/// Renders the search page results form.
ClassMethod SearchResults(%library As %String, search As %String, typestr As %String, member As %String, class As %String) [ Private ]
{
	Set type=$piece(typestr,",")
	Set typestr=$piece(typestr,",",2)
	If (search="define")
	{
		Set query="%CSP.Documatic.DefinedBy"
		Set msg=$$$Text("define the ")_..EscapeHTML(type)_" <b>"_..EscapeHTML(member)_"</b>"
	}
	ElseIf (search="implement")
	{
		Set query="%CSP.Documatic.ImplementedBy"
		Set msg=$$$Text("implement the ")_..EscapeHTML(type)_" <b>"_..EscapeHTML(member)_"</b>"
	}
	ElseIf (search="reference")
	{
		Set query="%CSP.Documatic.ReferencedBy"
		Set msg=$$$Text("reference the class")_" <b>"_..EscapeHTML(class)_"</b>"
	}
	ElseIf (search="derive")
	{
		Set query=""
		Set msg=$$$Text("are derived from the class")_" <b>"_..EscapeHTML(class)_"</b>"
	}
	
	If '$D(query) &html<<b>#($$$TextHTML("Error:</b> No search defined:"))# #(..EscapeHTML(search))#> Quit
	
	Set hdrmsg = $$$Text("Classes in namespace") _ " '" _ ..EscapeHTML(%library) _ "' " _ $$$Text("that ") _ msg _ ":"
	&html<<br>#(hdrmsg)#<br><br>>
	
	#; show derive results in a different way
	If search="derive" Do ..SearchResultsDerive(%library,class) Quit
	
	Set count=0
	Set result=##class(%ResultSet).%New(query)
	
	Do:search="define" result.Execute(typestr,member)
	Do:search="implement" result.Execute(typestr,member)
	Do:search="reference" result.Execute(class)
	
	&html<<br><table class="ClsSearchResult" border="0" cellpadding="0" cellspacing="0">>

	Set prop=""

	While (result.Next()) {
		Set count=count+1
		Set classname=result.GetData(1)
		If search="reference" {
			Set prop="."_result.GetData(2)
			Set member=result.GetData(2)
		}
		&html<<tr class=#($S(count#2:"DarkRow",1:"LightRow"))#>>
		&html<<td align=left nowrap="1">>
		&html<<a href="#(..ClassToUrl(classname,%library,member))#" class="SearchResult" #($S(..isIE():"onmouseover=""this.style.color = 'red'; "" onmouseout=""this.style.color = 'black'; """,1:""))#>> 
		&html<&nbsp;#(..EscapeHTML(classname)_..EscapeHTML(prop))#&nbsp;</a></td><tr> >
	}
	&html<</table>>

	If count=0 {
		&html<<br><b><i>#($$$TextHTML("No classes found."))#</i></b>>
	}
	Quit
}

/// Renders the search page results form for a <i>derived from</i> search.
ClassMethod SearchResultsDerive(%library As %String, base As %String) [ Private ]
{
	#; list all classes derived from 'base'
	Set count=0
	
	#; now walk down results
	&html<<br><table border="1" cellpadding="2">>
	
	Set resultset=##class(%ResultSet).%New("%ClassDefinition:SubclassOf")
	Do resultset.Execute(base)
	While resultset.Next() {
		Set count=count+1,cls=resultset.Data("Name")
		&html<<tr class="#($S(count#2:"DarkRow",1:"LightRow"))#">>
		&html<<td align="left"><nobr>>
		&html<<a href="#(..ClassToUrl(cls,%library))#" class="SearchResult" #($S(..isIE():"onmouseover=""this.style.color = 'red'; "" onmouseout=""this.style.color = 'black'; """,1:""))#>>
		&html<&nbsp;#(..EscapeHTML(cls))#&nbsp;</a></nobr></td><tr> >
	}
	
	&html<</table>>
	
	If count=0 &html<<br><b><i>#($$$TextHTML("No classes found."))#</i></b>>
	
	Quit
}

/// Renders a %library index page. Set <VAR>%library</VAR> to %SYS to 
/// show system index.
ClassMethod RenderIndexPage(%library As %String, expand As %String) As %Status
{
	Set showSystem = +$G(%request.Data("SYSTEM",1),1)
	Set showInternal = ..ShowInternal()

	#; build the list of namespaces
	d List^%SYS.NAMESPACE(.nslist,0)
	If ##class(%Library.EnsembleMgr).IsEnsembleInstalled() {
		Set nslist("ENSLIB") = ""
	}
	
	Set namespace=$namespace
	If ..SwapNS(%library) Quit $$$OK
	$$$CheckRtnIndexExistsQuit(sc)
	Set deprecationPolicy = ##class(%DeprecationPolicy).GetActive()
	Set classname = $Order(^rINDEXCLASS($select(showSystem:"",1:"&")),1,data)
	While (classname '= "") {
		If ('$ListGet(data,4)||(showInternal)&&(deprecationPolicy.IsClassDocVisible($List(data,2)))) {
			Set classlist(classname)=$List(data,2)
		}
		Set classname = $Order(^rINDEXCLASS(classname),1,data)
	}
	Set packagename=""
	For  Set packagename=$$$PACKAGEnext(packagename) Quit:packagename=""  Do
	#; Store any package that do not have classes under it so these will show up on the index
	. Set firstClass = $Order(classlist($ZConvert(packagename,"U")))
	. If firstClass'[($ZConvert(packagename,"U")_"."),firstClass'="" Set classlist($ZConvert(packagename,"U"))=packagename
	
	#; Pull the cookie value if we have one
	If expand="" Set expand=%request.GetCookie("EXPAND")
	
	#; Make sure expand list are elements that exist
	For i=$L(expand,","):-1:1 If $O(classlist($P(expand,",",i)))'[$P(expand,",",i) Set expand=$P(expand,",",1,i-1)_","_$P(expand,",",i+1,$$$MaxPieceNum)
	If $E(expand)'="," Set expand=","_expand
	If $E(expand,$L(expand))'="," Set expand=expand_","
	
	#;HEADER
	Set msg=$$$TextHTML("Documatic Index List")
	&html<<html>>
	&html<<meta name="Generator" content="Documatic">>
	&html<<title>#(msg)#</title>>
	&html<<head>>
	
	#; STYLE SHEETS
	Do ..ServeStyleSheet()
	
	Set hlpNS = $$$Text("Namespace in which to browse classes")
	Set msgClassesIn = $$$Text("Namespace:")

	Set hlpSYS = $$$Text("List classes from system library")
	Set msgSYS = $$$Text("Percent classes:")
	
	&html<<script language="JavaScript" type="text/javascript">
function libListChange() {
var selidx=self.document.Main.libList.selectedIndex;
var library = (selidx < 0) ? 'USER': self.document.Main.libList.options[selidx].value;
var index = '#(..#URL)#' + '?PAGE=INDEX&LIBRARY=' + library;
self.parent.IndexFrame.location = '#(..#URL)#' + '?PAGE=INDEX&EXPAND=,#($S(showSystem:"",1:"&SYSTEM=0"))#&LIBRARY=' + encodeURIComponent(library);
self.top.ClassFrame.location = '#(..#URL)#' + '?PAGE=CLASS&LIBRARY=' + library;
return; }

function toggleSystem(flag) {
	self.parent.IndexFrame.location = '#(..#URL)#' + '?PAGE=INDEX&EXPAND=,&LIBRARY=#(%library)#&SYSTEM=' + (flag?'1':'0');
}

</script>
	
<base target="ClassFrame">
</head>
<body class="Index">
	
<form name="Main">
<table class="IndexLabel" cellpadding="0" cellspacing="0" border="0" width="100%">
<tr valign="middle">
<td valign="middle" align="left" nowrap class="IndexText" title="#(hlpNS)#">#(msgClassesIn)#&nbsp;</td>
<td valign="middle" align="left" width="99%">&nbsp;
<select name="libList" size="1" title="#(hlpNS)#" onchange="libListChange();">>
	Set ns="" For  Set ns=$O(nslist(ns)) Quit:ns=""  Do
	. &html<<option value="#(..EscapeURL(ns))#" #($S($ZCVT(ns,"U")=$ZCVT(%library,"U"):"selected",1:""))#>#(..EscapeHTML(ns))#</option>>
	&html<</select>
</td></tr>
<tr valign="middle">
<td valign="middle" align="left" nowrap class="IndexText" title="#(hlpSYS)#">#(msgSYS)#</td>
<td valign="middle" align="left" width="99%" class="IndexText">&nbsp;<input type="checkbox" #($S(showSystem:"checked",1:""))# onclick="toggleSystem(this.checked);" title="#(hlpSYS)#"/></td>
</tr>
</table>
<hr/>
</form>>
	
	#; write list of classes, use DHTML in IE to make it look slicker
	If ..useDHTML() Do
	. Set i="",previous="",id=0
	. For  Set i=$Order(classlist(i)) Quit:i=""  Do  Set previous=i
	. . Set classname=classlist(i)
	. . For j=1:1:$L(previous,".") Quit:$P(i,".",j)'=$P(previous,".",j)
	. . For k=1:1:$L(previous,".")-j Do
	. . . &html<</div>>
	. . For j=j:1:$L(i,".")-1 Do
	. . . Set tree=$P(i,".",1,j)
	. . . Set id=id+1
	. . . &html<<nobr>>
	. . . &html<#(..spaces(j-1*3))#>
	. . . &html<<a href="#(..PackageToUrl($P(classname,".",1,j),%library))#" class="PackageChoice" onclick="expandIt(#(id)#);" title="Expand/Collapse package #($P(classname,".",1,j))#" onmouseover="this.style.color = 'red';" onmouseout="this.style.color = 'black';">>
	. . . &html<<image id="Im#(id)#" src="/csp/sys/images/ContractedMarker.jpg" height="15" width="16" border="0" align="bottom">>
	. . . &html<#($P(classname,".",j))#>
	. . . &html<</nobr>>
	. . . &html<</a>>
	. . . &html<<br>>
	. . . &html<<div id="Id#(id)#" style="display:none">>
	. . &html<<nobr>>
	. . &html<#(..spaces($L(classname,".")*3))#>
	. . If ..IsHidden(classname) Do
	. . . &html<<a href="#(..ClassToUrl(classname,%library))#" class="IndexChoiceInt" target = "ClassFrame" title="Display documentation on #(classname)#" onmouseover="this.style.color = 'red'; " onmouseout="this.style.color = 'gray'; ">>
	. . Else  Do
	. . . &html<<a href="#(..ClassToUrl(classname,%library))#" class="IndexChoice" target = "ClassFrame" title="Display documentation on #(classname)#" onmouseover="this.style.color = 'red'; " onmouseout="this.style.color = 'black'; ">>
	. . &html<&#149 #($P(classname,".",$L(classname,".")))#>
	. . &html<</a>>
	. . &html<</nobr>>
	. . &html<<br>>
	. For j=1:1:$L(previous,".")-1 Do
	. . &html<</div>>
	
	#; Non DHTML version
	Else  Do
	. &html<<table align="center" width="100%" cellspacing="0" cellpadding="0">>
	. Set i="",previous=""
	. For  Set i=$Order(classlist(i)) Quit:i=""  Do  Set previous=i
	. . Set exit=0
	. . Set classname=classlist(i)
	. . For j=1:1:$L(i,".")-1 Do  Quit:exit
	. . . If $P(i,".",j)=$P(previous,".",j) Quit
	. . . Set tree=$P(i,".",1,j)
	. . . If expand'[(","_tree_",") Do
	. . . . &html<<tr>>
	. . . . &html<<td valign="center" align="left" width="1">>
	. . . . &html<<nobr>>
	. . . . &html<#(..spaces(j-1*3))#>
	. . . . &html<<a href="#(..#URL)#?PAGE=INDEX&LIBRARY=#(..EscapeURL(%library))#&EXPAND=#(..EscapeURL(expand_tree_",")_$s($data(%request.Data("REFERER")):"&REFERER="_..EscapeURL(%request.Data("REFERER",1)),1:""))#" target="IndexFrame" title="Expand/Collapse package #($P(classname,".",1,j))#">>
	. . . . &html<<image src=/csp/sys/images/ContractedMarker.jpg height=15 width=16 border=0 align=bottom ALT="Expand/Collapse package #($P(classname,".",1,j))#">>
	. . . . &html<</a>>
	. . . . &html<</nobr>>
	. . . . &html<</td>>
	. . . . &html<<td valign="center" align="left">>
	. . . . If ..IsHidden(classname) Do
	. . . . . &html<<div class="PackageChoiceInt">>
	. . . . Else  Do
	. . . . . &html<<div class="PackageChoice">>
	. . . . &html<<a href="#(..PackageToUrl($P(classname,".",1,j),%library))#" class="PackageChoice" title="Display package #($P(classname,".",1,j))# information">>
	. . . . &html<<nobr>>
	. . . . &html<#($P(classname,".",j))#>
	. . . . &html<</nobr>>
	. . . . &html<</a>>
	. . . . &html<</div>>
	. . . . &html<</td>>
	. . . . &html<</tr>>
	#; Skip the other items in this unexpanded branch
	. . . . Set i=$Order(classlist((tree_"0")),-1)
	. . . . Set exit=1
	. . . Else  Do
	. . . . &html<<tr>>
	. . . . &html<<td valign="center" align="left" width="1">>
	. . . . &html<<nobr>>
	. . . . &html<#(..spaces(j-1*3))#>
	. . . . &html<<a href="#(..#URL)#?PAGE=INDEX&LIBRARY=#(..EscapeURL(%library))#&EXPAND=#(..EscapeURL($P(expand,","_tree_",",1)_","_$P(expand,","_tree_",",2,999999999))_$s($data(%request.Data("REFERER")):"&REFERER="_..EscapeURL(%request.Data("REFERER",1)),1:""))#" target="IndexFrame" title="Expand/Collapse package #($P(classname,".",1,j))#">>
	. . . . &html<<image src="/csp/sys/images/ExpandedMarker.jpg" height="15" width="16" border="0" align="bottom" alt="Expand/Collapse package #($P(classname,".",1,j))#">>
	. . . . &html<</a>>
	. . . . &html<</nobr>>
	. . . . &html<</td>>
	. . . . &html<<td valign="center" align="left">>
	. . . . If ..IsHidden(classname) Do
	. . . . . &html<<div class="PackageChoiceInt">>
	. . . . Else  Do
	. . . . . &html<<div class="PackageChoice">>
	. . . . &html<<a href="#(..PackageToUrl($P(classname,".",1,j),%library))#" class=PackageChoice title="Display package #($P(classname,".",1,j))# information">>
	. . . . &html<<nobr>>
	. . . . &html<#($P(classname,".",j))#>
	. . . . &html<</nobr>>
	. . . . &html<</a>>
	. . . . &html<</div>>
	. . . . &html<</td>>
	. . . . &html<</tr>>
	. . If exit Quit
	. . &html<<tr valign="center">>
	. . &html<<td valign="center" align="left" width="1">>
	. . &html<<nobr>>
	. . &html<#(..spaces(j*3))#&nbsp&#149>
	. . &html<</td>>
	. . &html<<td>>
	. . If ..IsHidden(classname) Do
	. . . &html<<a href="#(..ClassToUrl(classname,%library))#" class="IndexChoiceInt" target = "ClassFrame" title="Display documentation on #(classname)#">>
	. . Else  Do
	. . . &html<<a href="#(..ClassToUrl(classname,%library))#" class="IndexChoice" target = "ClassFrame" title="Display documentation on #(classname)#">>
	. . &html<#($P(classname,".",$L(classname,".")))#>
	. . &html<</a>>
	. . &html<</nobr>>
	. . &html<</td>>
	. . &html<</tr>>
	
	. &html<</table>>
Done
	
	; FOOTER
	&html<</body></html>>
	
	Quit $$$OK
}

/// Build a list of classes and return it via <VAR>classlist</VAR>.
/// <p>If <VAR>local</VAR> then show local classes.
/// <p>If <VAR>system</VAR> then show system classes.
ClassMethod GetClassList(ByRef classlist As %String, local As %Boolean, system As %Boolean) [ Private ]
{
	Set tShowInternal = ..ShowInternal()
	Set start="",end=""
	If 'system Set start="&"
	If 'local Set end="&"
	#; first create sorted list of classes in local array
	$$$CheckRtnIndexExistsThrow
	Set classname=start
	For  Set classname=$Order(^rINDEXCLASS(classname),1,data) Quit:classname=""  Quit:end'=""&&(classname]end)  Do
	#; filter out classes
	. Set cs=$ListGet(data,3)
	. If (tShowInternal) Do ; Show classes if being transparent
	. . Set classlist(classname)=$List(data,2)
	. . Quit
	. If $ListGet(data,4) Quit  ; Never show hidden classes in index
	. Set classlist(classname)=$List(data,2)
	Quit
}

/// Generate an HTML page for the class <i>cdef</i>.
ClassMethod RenderClassPage(cdef As %ClassDefinition, private As %Boolean) As %Status
{
	Set id=1,last=""
	Set tShowInternal = ..ShowInternal()	
	#; class info
	Do ..RenderClassInfo(cdef)

	#; initial tabs
	#; display logic duplicated below in members
	Set members = ""
	For type="Parameters","Properties","Methods","Queries","Indices","ForeignKeys","Triggers" {
		Set tmp=$property(cdef,type)
		For i=1:1:tmp.Count() {
			Set item=tmp.GetAt(i)
			If type="Parameters" {
				Set desc=$$FindDesc^%occName(item.ClassName,$$$cCLASSparameter,item.Name)
				Set ShowIt=1
				Set:(..IsInternal(item,desc)) ShowIt=0
				Set:(tShowInternal) ShowIt=1
				If ShowIt {
					Set members(type) = $GET(members(type), 0) + 1
				}
			} ElseIf type="Properties" {
				If private||('item.Private)||tShowInternal {
					Set desc=$$FindDesc^%occName(item.ClassName,$$$cCLASSproperty,item.Name)
					Set ShowIt=1
					Set:(..IsInternal(item,desc)) ShowIt=0
					Set:(tShowInternal) ShowIt=1
					If ShowIt {
						Set members(type) = $GET(members(type), 0) + 1
					}
				}
			} ElseIf type="Methods" {
				If private||('item.Private)||tShowInternal {
					Set name=item.Name
					Set desc=$$FindDesc^%occName(item.ClassName,$$$cCLASSmethod,name)
					Set ShowIt = 1
					If (desc '= "") {
						Set ShowIt = 1
					}
					Else {
						#; if there is no description, test if this is a Get/Set property method
						If $length(name)>3,$case($extract(name,$length(name)-2,*),"Get":1,"Set":1,:0) {
							Set pname = $extract(name,1,$length(name)-3)
							Set desc = pname
							If ($LENGTH(pname)>0) {
								If ($$$comMemberDefined(item.ClassName,$$$cCLASSproperty,pname) || $$$defMemberDefined(item.ClassName,$$$cCLASSproperty,pname)) {
									If (private||'$$$defMemberKeyGet(item.ClassName,$$$cCLASSproperty,pname,$$$cPROPprivate)) {
									Set ShowIt = 1
									#; synthesize a method description
									Set desc = "<i>"_$$$FormatText($$$Text("This is a <b>%1</b> accessor method for the <property>%2</property> property."),$extract(name,$length(name)-2,*),pname)_"</i>"
									}
								}
							}
						}
					}
					If ShowIt {
						Set:(..IsInternal(item,desc)) ShowIt=0
					}
					Set:(tShowInternal) ShowIt=1
					If ShowIt {
						Set members(type) = $GET(members(type), 0) + 1
					}
				}
			} ElseIf type="Queries" {
				Set desc=$$FindDesc^%occName(item.ClassName,$$$cCLASSquery,item.Name)
				Set ShowIt=1
				Set:(..IsInternal(item,desc)) ShowIt=0
				Set:(tShowInternal) ShowIt=1
				If ShowIt {
					Set members(type) = $GET(members(type), 0) + 1
				}
			} ElseIf type="Indices" {
				Set desc=$$FindDesc^%occName(item.ClassName,$$$cCLASSindex,item.Name)
				Set ShowIt=1
				Set:(..IsInternal(item,desc)) ShowIt=0
				Set:(tShowInternal) ShowIt=1
				If ShowIt {
					Set members(type) = $GET(members(type), 0) + 1
				}
			} ElseIf type="ForeignKeys" {
				Set desc=$$FindDesc^%occName(item.ClassName,$$$cCLASSfkey,item.Name)
				Set ShowIt=1
				Set:(..IsInternal(item,desc)) ShowIt=0
				Set:(tShowInternal) ShowIt=1
				If ShowIt {
					Set members(type) = $GET(members(type), 0) + 1
				}
			} ElseIf type="Triggers" {
				Set desc=$$FindDesc^%occName(item.ClassName,$$$cCLASStrigger,item.Name)
				Set ShowIt=1
				Set:(..IsInternal(item,desc)) ShowIt=0
				Set:(tShowInternal) ShowIt=1
				If ShowIt {
					Set members(type) = $GET(members(type), 0) + 1
				}
			}
		}
	}
	Do ..RenderLabel("Inventory",.id)
	&html<<table class="Summary" cellpadding="0" cellspacing="0" cols="1">>
	&html<<tr valign="center">>
	For type="Parameters","Properties","Methods","Queries","Indices","ForeignKeys","Triggers" {
		&html<<th align="center">>
		If ($GET(members(type), 0) > 0) {
			Set anchor = "#Anchor_" _ type
			&html<<a href="#(anchor)#">#(type)#</a>>
		}
		Else {
			&html<#(type)#>
		}
		&html<</th>>
	}
	&html<</tr>>
	&html<<tr>>
	For type="Parameters","Properties","Methods","Queries","Indices","ForeignKeys","Triggers" {
		Set tmp=$property(cdef,type)
		If ($GET(members(type), 0) > 0) {
			Set anchor = "#Anchor_" _ type
			&html<<td align="center">>
			&html<<a href="#(anchor)#">#(tmp.Count())#</a>>
		}
		Else {
			&html<<td align="center" class="private">>
		}
		&html<</td>>
	}
	&html<</tr>>
	&html<</table>>
	&html<<br/>>
	&html<<br/></div>>

	#; summary
	Set tClassName = cdef.Name
	If $$$comClassDefined(tClassName) {
		Do ..RenderLabel("Summary",.id)
		Do ..RenderClassSummary(tClassName)
		&html<<br/></div>>
	}

	#; members
	For type="Parameters","Properties","Methods","Queries","Indices","ForeignKeys","Triggers" {
		Set tmp=$property(cdef,type)
		For i=1:1:tmp.Count() {
			Set item=tmp.GetAt(i)
			If type="Parameters" {
				Set desc=$$FindDesc^%occName(item.ClassName,$$$cCLASSparameter,item.Name)
				Set ShowIt=1
				Set:(..IsInternal(item,desc)) ShowIt=0
				Set:(tShowInternal) ShowIt=1
				If ShowIt {
					If last'=type {
						If last'="" &html<<br></div>>
						Do ..RenderLabel(type,.id)
					}
					Do ..RenderParameterInfo(item,desc)
					Set last=type
				}
			} ElseIf type="Properties" {
				If private||('item.Private)||tShowInternal {
					Set desc=$$FindDesc^%occName(item.ClassName,$$$cCLASSproperty,item.Name)
					Set ShowIt=1
					Set:(..IsInternal(item,desc)) ShowIt=0
					Set:(tShowInternal) ShowIt=1
					If ShowIt {
						If last'=type {
							If last'="" &html<<br></div>>
							Do ..RenderLabel(type,.id)
						}
						Do ..RenderPropertyInfo(item,desc)
						Set last=type
					}
				}
			} ElseIf type="Methods" {
				If private||('item.Private)||tShowInternal {
					Set name=item.Name
					Set desc=$$FindDesc^%occName(item.ClassName,$$$cCLASSmethod,name)
					Set ShowIt = 1
					If (desc '= "") {
						Set ShowIt = 1
					}
					Else {
						#; if there is no description, test if this is a Get/Set property method
						If $case($extract(name,$length(name)-2,*),"Get":1,"Set":1,:0) {
							Set pname = $extract(name,1,$length(name)-3)
							Set desc = pname
							If ($LENGTH(pname)>0) {
								If ($$$comMemberDefined(item.ClassName,$$$cCLASSproperty,pname) || $$$defMemberDefined(item.ClassName,$$$cCLASSproperty,pname)) {
									If (private||'$$$defMemberKeyGet(item.ClassName,$$$cCLASSproperty,pname,$$$cPROPprivate)) {
									Set ShowIt = 1
									#; synthesize a method description
									Set desc = "<i>"_$$$FormatText($$$Text("This is a <b>%1</b> accessor method for the <property>%2</property> property."),$extract(name,$length(name)-2,*),pname)_"</i>"
									}
								}
							}
						}
					}
					If ShowIt {
						Set:(..IsInternal(item,desc)) ShowIt=0
					}
					Set:(tShowInternal) ShowIt=1
					If ShowIt {
						If last'=type {
							If last'="" &html<<br></div>>
							Do ..RenderLabel(type,.id)
						}
						Do ..RenderMethodInfo(item,desc)
						Set last=type
					}
				}
			} ElseIf type="Queries" {
				Set desc=$$FindDesc^%occName(item.ClassName,$$$cCLASSquery,item.Name)
				Set ShowIt=1
				Set:(..IsInternal(item,desc)) ShowIt=0
				Set:(tShowInternal) ShowIt=1
				If ShowIt {
					If last'=type {
						If last'="" &html<<br></div>>
						Do ..RenderLabel(type,.id)
					}
					Do ..RenderQueryInfo(item,desc)
					Set last=type
				}
			} ElseIf type="Indices" {
				Set desc=$$FindDesc^%occName(item.ClassName,$$$cCLASSindex,item.Name)
				Set ShowIt=1
				Set:(..IsInternal(item,desc)) ShowIt=0
				Set:(tShowInternal) ShowIt=1
				If ShowIt {
					If last'=type {
						If last'="" &html<<br></div>>
						Do ..RenderLabel(type,.id)
					}
					Do ..RenderIndexInfo(item,desc)
					Set last=type
				}
			} ElseIf type="ForeignKeys" {
				Set desc=$$FindDesc^%occName(item.ClassName,$$$cCLASSfkey,item.Name)
				Set ShowIt=1
				Set:(..IsInternal(item,desc)) ShowIt=0
				Set:(tShowInternal) ShowIt=1
				If ShowIt {
					If last'=type {
						If last'="" &html<<br></div>>
						Do ..RenderLabel(type,.id)
					}
					Do ..RenderForeignKeyInfo(item,desc)
					Set last=type
				}
			} ElseIf type="Triggers" {
				Set desc=$$FindDesc^%occName(item.ClassName,$$$cCLASStrigger,item.Name)
				Set ShowIt=1
				Set:(..IsInternal(item,desc)) ShowIt=0
				Set:(tShowInternal) ShowIt=1
				If ShowIt {
					If last'=type {
						If last'="" &html<<br></div>>
						Do ..RenderLabel(type,.id)
					}
					Do ..RenderTriggerInfo(item,desc)
					Set last=type
				}
			}
		}
	}
	Quit $$$OK
}

/// Generate an HTML page show information on the current namespace.
ClassMethod RenderNameSpacePage() As %Status
{
	Set msgWelcome = $$$Text("Welcome to the Class Reference.")
	Set msgWelcome2 = $$$Text("You can select a class using the list on the left or by selecting a package name from the table below.")
	Set msgNS = $$$Text("You are currently looking at namespace:")
	
	Set tNS = $get(%library,$namespace)
	&html<<br/><div>#(msgWelcome)#</div>>
	&html<<div>#(msgWelcome2)#</div>>
	&html<<br/><div>#(msgNS)#&nbsp;<b>#($ZCVT(tNS,"O","HTML"))#</b></div>>

	Do ..RenderNameSpaceList()

	Set msgMbrs = $$$Text("Packages in this Namespace")
	Do ..RenderPackageInfo(msgMbrs)

	Quit $$$OK
}

/// Generate an HTML page for the package <PARAMETER>packagename</PARAMETER>.
ClassMethod RenderPackagePage(packagename As %String) As %Status
{
	Set msgNS = $$$Text("Namespace:")
	Set msgPkg = $$$Text("Package:")
	Set msgNoInfo = $$$Text("There is no description available for this package.")
	Set msgPre = $$$Text("GlobalPrefix:")
	Set msgSQL = $$$Text("SQL Name:")
	Set msgOwner = $$$Text("Table owner name:")
	Set msgRP = $$$Text("Routine Prefix:")
	
	&html<<p>#(msgNS)#&nbsp;<b>#(..EscapeHTML($get(%library,$namespace)))#</b></p>>

	If '$Data($$$PACKAGE(packagename)) {
		&html<<p>#(msgPkg)#&nbsp;<b>#(..EscapeHTML(packagename))#</b></p>>
		#; there never is a description
		#; &html<<div>#(msgNoInfo)#</div>>
	} Else {
		Set package=##class(%PackageDefinition).%OpenId(packagename)
		If package="" Quit $$$OK
		&html<<p>#(msgPkg)#&nbsp;<b>#(..EscapeHTML(package.Name))#</b>>
		&html<<div>#(..EscapeHTML(package.Description))#</div>>
		&html<<ul><li>#(msgPre)#&nbsp;<b>#(..EscapeHTML(package.GlobalPrefix))#</b></li>>
		&html<<li>#(msgSQL)#&nbsp;<b>#(..EscapeHTML(package.SQLName))#</b></li>>
		&html<<li>#(msgOwner)#&nbsp;<b>#(..EscapeHTML(package.OwnerName))#</b></li>>
		&html<<li>#(msgRP)#&nbsp;<b>#(..EscapeHTML(package.RtnPrefix))#</b></li></ul>>
		&html<</p>>
	}
	
	Set msgMbrs = $$$Text("Members of this Package")
	Do ..RenderPackageInfo(msgMbrs,packagename)
	Quit $$$OK
}

/// Generate HTML table showing contents of the given package.
ClassMethod RenderPackageInfo(pTitle As %String, packagename As %String = "") As %Status
{
	Set showInternal = ..ShowInternal()

	Set hlpClass = $$$Text("Class")
	Set hlpPackage = $$$Text("Package")

	Set deprecationPolicy = ##class(%DeprecationPolicy).GetActive()
	#; get list of contents of this package using ^rINDEXCLASS
	Set seed = ""
	Set:packagename'="" seed = $ZCVT(packagename,"U")_"."
	Set dots = $L(seed,".")
	Set key = $O(^rINDEXCLASS(seed),1,data)
	While ((key '= "")&&($E(key,1,$L(seed)) = seed)) {
		If ('$ListGet(data,4)||(showInternal))&&deprecationPolicy.IsPackageDocVisible($lg(data,2)) {
			Set tName = $LG(data,2)
			Set tIsPkg = $L(tName,".") - dots // same number of dots = class
			If (tIsPkg) {
				Set tName = $P(tName,".",1,dots)
				If ($D(^rINDEXCLASS($ZCVT(tName,"U")))) {
					#; class with same name as package
					#; add to list with * appended
					Set tList(tName_"*") = 0
				}
			}
			Set:tName'="" tList(tName) = tIsPkg
		}
		Set key = $O(^rINDEXCLASS(key),1,data)
	}
	
	#; show contents of package
	If ($D(tList)) {
		Set tCols = 3
		&html<<br/><table class="Summary" border="0" cellspacing="0" cellpadding="1">
		<tr><th colspan="#(tCols)#">#(pTitle)#</th></tr>>
		&html<<tr>>
		Set col = 1
		Set key = $O(tList(""))
		While (key '= "") {
			Set tPageName = $TR(key,"*","") // remove * for duplicate name
			Set cls = ""
			Set url = "%25CSP.Documatic.cls?PAGE=CLASS&LIBRARY="_$ZCVT($get(%library,$namespace),"O","URL")_"&CLASSNAME="_$ZCVT(tPageName,"O","URL")
			Set url = ##class(%CSP.Page).Link(url)
			If $G(tList(key)) {
				Set title = $S($G(tList(key)):hlpPackage,1:hlpClass)
				Set cls = "pkgName"
				Set title = hlpPackage
				Set glyph = "&nbsp;&raquo;"
				Set url = url _ "&PACKAGE=1"
			}
			Else {
				Set cls = "className"
				Set tDeprecated = $$$comClassKeyGet(key,$$$cCLASSdeprecated)
				Set cls = $s(tDeprecated=0:cls, 1:cls_" "_"deprecated")
				Set title = hlpClass
				Set glyph = ""
			}
			#; !!! we *should* look at system flag
			Set sys = $S(tPageName["%":"sysItem",1:"")

			If (col > tCols) {
				&html<</tr><tr>>
				Set col = 1
			}
			&html<<td class="#(sys)#" nowrap><a class="#(cls)#" href="#(url)#" title="#(title)#">#($ZCVT(tPageName,"O","HTML")_glyph)#</a></td>>
			Set col = col + 1
	
			Set key = $O(tList(key))
		}
		&html<</tr>>
		&html<</table>>
		&html<<br>>
	}

	Quit $$$OK
}

/// Generate HTML table showing available namespaces.
ClassMethod RenderNameSpaceList() As %Status
{
	Set msgNS = $$$Text("Available Namespaces")

	#; Get list of namespaces
	Do List^%SYS.NAMESPACE(.tList,0,0,1)

	#; show contents of list
	If ($D(tList)) {
		If ##class(%Library.EnsembleMgr).IsEnsembleInstalled() {
			Set tList("ENSLIB")=""
		}
		Set tNS = $get(%library,$namespace)
		Set tCols = 3
		&html<<br/><table class="Summary" border="0" cellspacing="0" cellpadding="1">
		<tr><th colspan="#(tCols)#">#(msgNS)#</th></tr>>
		&html<<tr>>
		Set col = 1
		Set tPageName = $O(tList(""))
		While (tPageName '= "") {
			Set cls = ""
			Set url = "%25CSP.Documatic.cls?LIBRARY="_$ZCVT(tPageName,"O","URL")
			Set url = ##class(%CSP.Page).Link(url)
			Set cls = $S(tPageName = tNS:"nsNameCurr",1:"nsName")
			Set title = ""

			If (col > tCols) {
				&html<</tr><tr>>
				Set col = 1
			}
			&html<<td class="#(cls)#" nowrap><a target="_top" class="#(cls)#" href="#(url)#" title="#(title)#">#($ZCVT(tPageName,"O","HTML"))#</a></td>>
			Set col = col + 1
	
			Set tPageName = $O(tList(tPageName))
		}
		&html<</tr>>
		&html<</table>>
		&html<<br>>
	}

	Quit $$$OK
}

/// Generate an HTML page for the class <PARAMETER>cdef</PARAMETER> storage definition.
ClassMethod RenderStoragePage(cdef As %ClassDefinition) As %Status
{
	Set show=0
	Set clstype= $$$getClassType($$$NormalizeClassname(cdef.Name))
	Set:clstype=$$$cCLASSCLASSTYPEPERSISTENT show=1
	Set:clstype=$$$cCLASSCLASSTYPESERIAL show=1

	#; class info
	Do ..RenderClassInfo(cdef, 0)
	&html<<br/>>

	#; dispatch to appropriate method
	Quit:show ..RenderStorageDef(cdef)

	Set tMsg = $$$TextHTML("Storage information is not available for class:")
	&html<<br>#(tMsg)# <b>#(cdef.Name)#</b>>
	Quit $$$OK
}

/// Returns an OREF to the current storage definition for the given class.
ClassMethod GetCurrentStorageDef(cdef As %ClassDefinition) As %StorageDefinition [ Private ]
{
   Quit cdef.Storages.GetAt(1)
}

/// Generate an HTML page for the class <i>cdef</i> serial storage definition.
/// <p>Set <VAR>issuper</VAR> true for superclasses of the currently viewed class.
ClassMethod RenderStorageDef(cdef As %ClassDefinition, issuper As %Boolean = 0) As %Status
{
	Set clstype= $$$getClassType($$$NormalizeClassname(cdef.Name))
	Set:clstype=$$$cCLASSCLASSTYPEPERSISTENT msg=$$$TextHTML("Storage structure used for class")
	Set:clstype=$$$cCLASSCLASSTYPESERIAL msg=$$$TextHTML("Serialized state for class")

	#; label, set up outer table
	If 'issuper Do
	. &html<<br>#($G(msg))# <b>#(cdef.Name)#</b>.>
	. If (clstype=$$$cCLASSCLASSTYPEPERSISTENT)&($P(cdef.Super,",")'="%Persistent") &html<<br><br>
	<span class=StoragePtrSuper>#($$$TextHTML("Gray"))#</span><i>#($$$TextHTML(" indicates storage defined by super classes."))#</i>>
	. &html<<br><br><table >>

	#; first render super class storage (for persistent classes)
	If clstype=$$$cCLASSCLASSTYPEPERSISTENT {
		Set superdef=""
		Set super=$P(cdef.Super,",",1)
		Set super=$P(cdef.Super,",",1)
		If ((super '[ ".") && (super '[ "%")) {
			Set super = $P(cdef.Name,".",1,$L(cdef.Name,".")-1) _ "." _ super
		}
		Set super = $$$NormalizeClassname(super)

		Set:(super'="")&(super'="%Persistent") superdef=##class(%ClassDefinition).%OpenId(super)

		If $IsObject(superdef)
		{
			Do ..RenderStorageDef(superdef,1)
		}
	}
	
	#; now render this class' storage
	
	Set sdef=..GetCurrentStorageDef(cdef)
	If sdef="" Write:'issuper "</table>" Quit $$$OK
	
	#; define 'super' style
	Set ss=$S(issuper:"Super",1:"")
	
	Set type=sdef.Type
	Do NormalizeClassnameByDef^%occName(.type,type,"%Storage.Persistent")
	If $$$SQLStorageIsDefault(type)
	{
		Set return = ..RenderDefaultStorageDef(cdef,sdef,ss,"Storage")
	}
	ElseIf $$$SQLStorageIsSerial(type)
	{
		Set return = ..RenderDefaultStorageDef(cdef,sdef,ss,"Serial")
	}
	ElseIf $$$SQLStorageIsSQL(type)
	{
		Set return = ..RenderSQLStorageDef(cdef,sdef,ss,"SQLStorage")
	}

	; close outer table
	If 'issuper &html<</table>>
	
	Quit $$$OK
}

ClassMethod RenderDefaultStorageDef(cdef, sdef, ss, lbl) As %Status
{
	Set ispersistent = 0
	Set clstype= $$$getClassType($$$NormalizeClassname(cdef.Name))
	Set:clstype=$$$cCLASSCLASSTYPEPERSISTENT ispersistent=1

	Set icount=sdef.DataDefinitions.Count()
	For i=1:1:icount
	{
		Set ddef=sdef.DataDefinitions.GetAt(i)
		#; info about this node
		Set glvn=""
		Set:ispersistent glvn=..GetDataLocation(sdef)
		Set:ispersistent glvn=glvn_"(<b>ID</b>"_$S(ddef.Subscript'="":","_ddef.Subscript,1:"")_$S(ddef.Structure="subnode":",<i>n</i>",1:"")_")"
	
		&html<<caption valign="top" align="left"><nobr>#($$$TextHTML("Storage Model: "))#<span class="header">#(lbl)#</span>&nbsp;(<i>#(cdef.Name)#</i>)</nobr></caption>>
		&html<<tr>>
		If ispersistent
		{
			&html<<td>>
			&html<<table>>
			&html<<tr><td class=StoragePtr#(ss)# bgcolor=#($S(ss="":"#CBE6EB",1:"#C0C0C0"))#>>
			&html<<font face="Arial, Helvetica, sans-serif" size=-1>>
			&html<<nobr>&nbsp;#(glvn)#&nbsp;</nobr></font>>
			&html<</td></tr>>
			&html<</table>>
			&html<</td><td> = </td>>
		}
	
		&html<<td>>
		&html<<table>>
		&html<<tr><td> </td></tr>>
		&html<<tr><td bgcolor=#287780 class=#($S(ddef.Structure="listnode":"StorageNode",1:"StorageSingle")_ss)#>>
		&html<<table>>
	
		Set jcount=0 ; trick to avoid loop for node/subnode structures
		If ddef.Structure="subnode"
		{
			&html<<tr>>
			&html<<td class=StorageSlot#(ss)#>>
			&html<<font face="Arial, Helvetica, sans-serif" size=-1>>
			&html<<nobr>&nbsp;#(..EscapeHTML(ddef.Value))#(<i>n</i>)&nbsp;</nobr>>
			&html<</font>>
			&html<</td>>
			&html<<tr>>
			&html<<tr>>
		}
		ElseIf ddef.Structure="node"
		{
			&html<<tr>>
			&html<<td class=StorageSlot#(ss)#>>
			&html<<nobr>&nbsp;#(..EscapeHTML(ddef.Value))#&nbsp;</nobr>>
			&html<</td>>
			&html<<tr>>
		}
		Else
		{
			Set jcount=ddef.ValueList.Count()
		}
		For j=1:1:jcount
		{
			Set vdef=ddef.ValueList.GetAt(j)
			&html<<tr>>
			&html<<td class=StorageSlot#(ss)# bgcolor=#($S(ss="":"#CBE6EB",1:"#C0C0C0"))#>>
			&html<<font face="Arial, Helvetica, sans-serif" size=-1>&nbsp;#(..EscapeHTML(vdef.Value))#&nbsp;</font>>
			&html<</td>>
			&html<<tr>>
		}
		&html<</table>>
		&html<</td></tr>>
		&html<</table>>
		&html<</td></tr>>
	}
	
	Quit $$$OK
}

/// Generate an HTML page for the class <I>cdef</I> serial storage definition.
/// <P>Set <VAR>issuper</VAR> true for superclasses of the currently viewed class.
ClassMethod RenderSQLStorageDef(cdef As %ClassDefinition, sdef, ss, lbl) As %Status
{
	//Write "ClassName: ", sdef.SQLBinding.ClassName, "<br>", !
	//Write "StorageName: ", sdef.SQLBinding.StorageName, "<br>", !
	Set maps = sdef.SQLBinding.Maps
	Set mapslimit = $SELECT((maps=""):0, 1:maps.Count())
	//Write "Maps: ", mapslimit, "<br>", !
	Write $$$TextHTML("Maps: "), mapslimit, "<br>", !
	&html<<CAPTION VALIGN="top"><NOBR>#($$$TextHTML("Storage Model: "))#<SPAN CLASS="header">#(..EscapeHTML(lbl))#</SPAN></NOBR></CAPTION>>
	For mapinx = 1 : 1 : mapslimit
	{
		Set thismap = maps.GetAt(mapinx)
		Set RowRef = thismap.RowReference
		If '$IsObject(thismap) Continue
		Set subscripts = thismap.Subscript
		Set subscriptslimit = $SELECT((subscripts = ""):0, 1:subscripts.Count())
		//Write "<p>", "Map ", mapinx, ": ", thismap.Name, "<br>", !
		Write "<p>", $$$TextHTML("Map "), mapinx, ": ", ..EscapeHTML(thismap.Name), "<br>", !
		//Write "Subscripts: ", subscriptslimit, "<br>", !
		Set subscriptstring = ""
		For subscriptinx = 1 : 1 : subscriptslimit
		{
			//Write "Subscript: ", subscriptinx, "<br>", !
			//Write "Subscript: ", subscriptinx, "<br>", !
			Set thissubscript = subscripts.GetAt(subscriptinx)
			If (thissubscript.Expression '= "")
			{
				//Write "Expression: ", thissubscript.Expression, "<br>", !
				Set:(subscriptstring '= "") subscriptstring = subscriptstring _ ","
				Set subscriptstring = subscriptstring _ thissubscript.Expression
				
				Set RowRef = $REPLACE(RowRef, ("{L" _ subscriptinx _ "}"), thissubscript.Expression)
			}
		}
		If (subscriptstring '= "")
		{
			Set glvn = thismap.Global _ "(" _ subscriptstring _ ")"
		}
		Else
		{
			Set glvn = thismap.Global
		}
		Write:$LENGTH(RowRef) $$$TextHTML("Row Reference: "), RowRef, "<br>", !
		//Write "GLVN: ", glvn, "<br>", !
		Write $$$TextHTML("thismap.Global: "), thismap.Global, "<br>", !
		Kill dstruct
		Set nullindex = 1E-1
		Set mapdata = thismap.Data
		Set mapdatalimit = $SELECT((mapdata = ""):0, 1:mapdata.Count())
		//Write "Data: ", mapdatalimit, "<br>", !
		For mapdatainx = 1 : 1 : mapdatalimit
		{
			//Write "D(", mapdatainx, ")", "<br>", !
			Set thismapdata = mapdata.GetAt(mapdatainx)
			Set node = thismapdata.Node
			Set:(node = "") node = nullindex
			Set piece = thismapdata.Piece
			Set:(piece = "") piece = nullindex
			Set delimiter = thismapdata.Delimiter
			Set:(delimiter = "") delimiter = nullindex
			//Write "Node: ", node, "; ", "Piece: ", piece, "; ", "Delimiter: ", delimiter, "<br>", !
			Set dstruct(node,delimiter,piece) = thismapdata.Name
		}

		&html<<TR>>
		&html<<TD>>
		&html<<TABLE >>
		&html<<TR>>
		&html<<TD CLASS=StoragePtr<%=ss%> bgcolor=<%=$S(ss="":"#CBE6EB",1:"#C0C0C0")%>>>
		&html<<FONT face="Arial, Helvetica, sans-serif" size=-1>>
		&html<<NOBR>&nbsp;<%=glvn%>&nbsp;</NOBR>>
		&html<</FONT>>
		&html<</TD>>
		&html<</TR>>
		&html<</TABLE>>
		&html<</TD>>
		&html<<TD> = </TD>>
		&html<<TD>>
		&html<<TABLE>>
		&html<<TR>>
		&html<<TD> </TD>>
		&html<</TR>>
		&html<<TR>>
		&html<<TD bgcolor=#287780 CLASS=StorageNode<%=ss%>>>
		&html<<TABLE>>
		
		If ($DATA(dstruct) > 0)
		{
			&html<<THEAD>>
			&html<<TR>>
			&html<<TD><SPAN CLASS="tblhdr">#($$$TextHTML("Node"))#</SPAN></TD>>
			&html<<TD><SPAN CLASS="tblhdr">#($$$TextHTML("Delimiter"))#</SPAN></TD>>
			&html<<TD><SPAN CLASS="tblhdr">#($$$TextHTML("Piece"))#</SPAN></TD>>
			&html<<TD><SPAN CLASS="tblhdr">#($$$TextHTML("Name"))#</SPAN></TD>>
			&html<</TR>>
			&html<</THEAD>>
		}
		&html<<TBODY>>

		&html<<TR>>
		Set node = $Order(dstruct(""))
		While node '= "" {
			Set delimiter = $Order(dstruct(node,""))
			While delimiter '= "" {
				Set piece = $Order(dstruct(node,delimiter,""))
				While piece '= "" {
					&html<<TR>>
					
					&html<<TD CLASS=StorageSlot<%=ss%> bgcolor=<%=$S(ss="":"#CBE6EB",1:"#C0C0C0")%>>>
					&html<<FONT face="Arial, Helvetica, sans-serif" size=-1>>
					&html<&nbsp;>
					&html<<%=$Select(node'=nullindex:node,1:"")%>>
					&html<&nbsp;>
					&html<</FONT>>
					&html<</TD>>
					
					&html<<TD CLASS=StorageSlot<%=ss%> bgcolor=<%=$S(ss="":"#CBE6EB",1:"#C0C0C0")%>>>
					&html<<FONT face="Arial, Helvetica, sans-serif" size=-1>>
					&html<&nbsp;>
					&html<<%=$Select(delimiter'=nullindex:delimiter,1:"")%>&nbsp;>
					&html<</FONT>>
					&html<</TD>>
					
					&html<<TD CLASS=StorageSlot<%=ss%> bgcolor=<%=$S(ss="":"#CBE6EB",1:"#C0C0C0")%>>>
					&html<<FONT face="Arial, Helvetica, sans-serif" size=-1>>
					&html<&nbsp;<%=$Select(piece'=nullindex:piece,1:"")%>>
					&html<&nbsp;>
					&html<</FONT>>
					&html<</TD>>
					
					&html<<TD CLASS=StorageSlot<%=ss%> bgcolor=<%=$S(ss="":"#CBE6EB",1:"#C0C0C0")%>>>
					&html<<FONT face="Arial, Helvetica, sans-serif" size=-1>>
					&html<&nbsp;>
					&html<<%=dstruct(node,delimiter,piece)%>>
					&html<&nbsp;>
					&html<</FONT>>
					&html<</TD>>
					
					&html<</TR>>
					
					Set piece = $Order(dstruct(node,delimiter,piece))
				}
				Set delimiter = $Order(dstruct(node,delimiter))
			}
			Set node = $Order(dstruct(node))
		}
		&html<</TR>>
		
		&html<</TBODY>>
		
		&html<</TABLE>>
		&html<</TD>>
		&html<</TR>>
		&html<<TR>>
		&html<<TD> </TD>>
		&html<</TR>>
		&html<</TABLE>>
		&html<</TD>>
		&html<</TR>>

	}
	
	Quit $$$OK
}

/// Find the data location for this storage definition.
ClassMethod GetDataLocation(sdef As %StorageDefinition) As %String [ Private ]
{
	Quit:sdef.DataLocation'="" sdef.DataLocation
	
	#; check super class
	Set cdef=##class(%ClassDefinition).%OpenId(sdef.ClassName)
	Quit:'$IsObject(cdef) ""
	
	Set super=$P(cdef.Super,",",1)
	If ((super '[ ".") && (super '[ "%")) {
		Set super = $P(sdef.ClassName,".",1,$L(sdef.ClassName,".")-1) _ "." _ super
	}
	Set super = $$$NormalizeClassname(super)

	Set cdef=""
	Set:(super'="")&(super'="%Persistent") cdef=##class(%ClassDefinition).%OpenId(super)
	Quit:'$IsObject(cdef) ""

	Set ispersistent = 0
	Set clstype= $$$getClassType($$$NormalizeClassname(cdef.Name))
	Set:clstype=$$$cCLASSCLASSTYPEPERSISTENT ispersistent=1
	If ('ispersistent) Quit ""
	
	Set ret=..GetDataLocation(..GetCurrentStorageDef(cdef))
	
	Quit ret
}

/// Generate the title banner for the current page.
/// <br>pageType=0 means "we're displaying normal content", pageType=1 means "this is the Home page", 
/// pageType=2 means "this is the SearchPage page", pageType=3 means "this is the Getting Started page"
/// pageType=4 means "this is the Master Index page"
ClassMethod RenderBanner(title As %String, %library As %String, class As %String) As %Status [ Private ]
{
	set overalltitle="Class Reference"
	Set cmdDocs = $$$TextHTML("Documentation")
	Set cmdStorage = $$$TextHTML("Storage")
	Set cmdSearch = $$$TextHTML("Search")
	Set cmdDefinition = $$$TextHTML("Definition")
	
	Set urlDocs = ##class(%CSP.Page).Link("/csp/docbook/DocBook.UI.Page.cls")
	Set urlSearch = ##class(%CSP.Page).Link(..#URL_"?PAGE=SEARCH&LIBRARY="_$ZCVT($get(%library,$namespace),"O","URL")_"&CLASSNAME="_$ZCVT(class,"O","URL"))

	Set msgDocs = $$$TextHTML("Go to the DocBook Home Page")
	Set msgSearch = $$$TextHTML("Go to the Class Search Page")

	Set cmdPrivate = $$$Text("Private")
	Set msgPrivate = $$$Text("Show private members of this class")

	Set cmdStorage = $$$Text("Storage")
	Set msgStorage = $$$Text("Show storage for this class")


	&html<<table style="width:100%; border:0px; padding:0px; border-spacing:0px; color:darkblue; margin-left:10px; ">>
	&html<    <tr>>
	//left hand cell in the row has overall title
	&html<       <td>>
   	&html<<div style="font-weight:bold; font-size:1.5em; margin-right:10px; ">#(overalltitle)#</div>>
   	&html<<div style="font-weight:bold; font-size:1em; margin-right:10px; ">#($system.Version.GetProduct())# #($system.Version.GetNumber())#</div>>
	&html<       </td>>

	//right hand cell in the row has the logo
	&html<      <td width="30%" style="text-align:right;">>
	set logofile="/csp/sys/images/IS_HBG_SM_TM-cmyk.svg"
	set logofilealt="InterSystems: The power behind what matters"
	&html<<img src="#(logofile)#" height="75px" alt="#(logofilealt)#" >&nbsp;&nbsp;&nbsp;>
	&html<       </td>>
	&html<    </tr>>

	&html<    <tr>> //next table row has a couple of links
	&html<       <td>>
   	&html<<div>>
    &html<<a target="_top" title="#(msgDocs)#" class="buttonStyleON" href='#(urlDocs)#'>#(cmdDocs)#</a>&nbsp;
           <a title="#(msgSearch)#" class="buttonStyleON" href='#(urlSearch)#'>#(cmdSearch)#</a>>
    &html<</div>>
	&html<       </td>>

	&html<    </tr>>
	&html<</table>>


    //&html<<hr style="color:#D36D00; padding:0px; margin-top:0em; margin-bottom:0em; margin-left: 0em; margin-right: 0em;"></hr>>
    //new table
	&html<<table style="width:100%; border:0px; padding:0px; border-spacing:0px; font-size: 10pt;vertical-align:top; ">>
	///first row is a bold line
	&html<    <tr>>
    &html<       <td colspan="100" style="vertical-align:top;line-height:1px;font-size:0pt; background-color:#D36D00" height="1">>
	&html<       </td>>
	&html<    </tr>>
    
	#; locator
	#; namespace
	Set tLocator=1
	set namespace=$ZCVT($get(%library,$namespace),"U")
	Set tLocator(1) = $LB("",namespace)

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

	//next table row has locator on left and check boxes on the right
	&html<    <tr  >> 
	//the left cell has the locator
	&html<      <td class="LocatorBar" style="padding-bottom:5px; width:70%">>
	&html<         <div align="left" class="Locator" style="font-size: 10pt;">&nbsp;>

	If (tCount > 0) {
		For i = 1:1:tCount {
			Set tLink = "%25CSP.Documatic.cls?PAGE=CLASS&LIBRARY="_$ZCVT($get(%library,$namespace),"O","URL")_"&CLASSNAME="_$ZCVT($LG(tLocator(i),1),"O","URL")
			Set tLink = ##class(%CSP.Page).Link(tLink)
			Set tCaption = $ZCVT($LG(tLocator(i),2),"O","HTML")
			Set tHelp = tCaption
			&html<<nobr>[<a title="#(tHelp)#" href="#(tLink)#">#(tCaption)#</a>]#($S(i=tCount:"",1:"&nbsp;&gt;&nbsp;"))#</nobr>>
		} 
	}
	&html<        </div>>
	&html<       </td>>


	//the right cell has the check boxes
    &html<       <td class="LocatorBar" style="width:30%;font-size:9pt;"  >>
    
	Set isClass = (class'="")&&$$$defClassDefined(class)
	If (isClass) {
		Set private = $S(+$get(%request.Data("PRIVATE",1)):"checked",1:"")
		Set storage = $S("STORAGE"=$get(%request.Data("PAGE",1)):"checked",1:"")
		&html<
		<div style="font-size: 10pt;" align="right">
		<span title="#(msgPrivate)#"><input id="cbPrivate" type="checkbox" onclick="togglePrivate(this.checked);" #(private)# /><span onclick="togglePrivate(!self.document.getElementById('cbPrivate').checked);">#(cmdPrivate)#</span></span>&nbsp;
		<span title="#(msgStorage)#"><input id="cbStorage" type="checkbox" onclick="toggleStorage(this.checked);" #(storage)# /><span onclick="toggleStorage(!self.document.getElementById('cbStorage').checked);">#(cmdStorage)#</span></span>&nbsp;&nbsp;&nbsp;
		</div>
		</td>>
	}

 	&html<    </tr>>
	&html<</table>>
}

ClassMethod MakeCopyrightDiv() [ Internal ]
{
	set copyrightnotice=$$Copyright^%apiOBJ(,""," ")
#;Chop out the word "Copyright". The link below re-adds it. Try to put it on a newtab.
	set copyrightnotice=$p(copyrightnotice," ",2,*)
    &html<<div style="font-size:10pt; margin-left:10px; margin-right:10px;">>
    &html<<A HREF="copyright.pdf" target="_blank" >Copyright</A> #(copyrightnotice)#</div>>
}

ClassMethod RenderBannerOld(title As %String, %library As %String, class As %String) As %Status [ Private ]
{
	Set isClass = (class'="")&&$$$defClassDefined(class)
	Set tBookTitle = $$$TextHTML("Class Reference")
	Set tTitle = ..EscapeHTML(title)

	Set ServerName = $zu(110)
	Set InstanceName = $P($zu(86),"*",2)

	Set cmdDocs = $$$TextHTML("Documentation")
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

	#;Set msgISC = $$$Text("Go to the InterSystems Home Page")

	&html<
   <table width="100%" border="0" cellpadding="0" cellspacing="0" style="font-size: 10pt;">
   <tr>
   <td nowrap width="205" bgcolor="#FFFAE7" valign="bottom" align="left" style='background-repeat: no-repeat; background-image: url("#(##class(%CSP.Page).Link("/csp/sys/images/logo-topl-intersystems.gif"))#");'>
   <nobr>&nbsp;
   <span style="color: gray;">
   <a target="_top" title="#(msgDocs)#" class="buttonStyleON" href='#(urlDocs)#'>#(cmdDocs)#</a>|<a title="#(msgSearch)#" class="buttonStyleON" href='#(urlSearch)#'>#(cmdSearch)#</a>
   </span>
   </nobr>
   </td>
   <td nowrap bgcolor="#FFFAE7" valign="top" align="left" style="padding-left: 20px;">
   <div class="wizardltlabel" style="margin-top:6px;">
   <span style="font-size:11pt; padding-right:5px;">#(tBookTitle)#</span>
   </div>
   <div style="color: darkblue; margin-top:4px; font-weight: bold; font-size:13pt;">#(tTitle)#</div>
   </td>
   <td nowrap width="308" height="78" bgcolor="#FFFAE7" valign="bottom" align="left" style='background-repeat: repeat-y; background-image: url("#(##class(%CSP.Page).Link("/csp/sys/images/opposite-pic-intersys.jpg"))#");'>&nbsp;</td>
   <td width="2%" bgcolor="#388CCC">&nbsp;</td>
   <td bgcolor="#388CCC" valign="bottom">
   <table bgcolor="#388CCC" border="0">
   <tr>
   <td title="#(msgServer)#" class="quote-name" style="text-align: left;" nowrap>
   <span style="color:#FFFAE7; font-size:8pt; padding-right:5px;">#(cmdServer)#:</span>
   <b>#(ServerName)#</b>
   </td>
   </tr>
   <tr>
   <td title="#(msgInstance)#" class="quote-name" style="text-align: left;" nowrap>
   <span style="color:#FFFAE7; font-size:8pt; padding-right:5px;">#(cmdInstance)#:</span>
   <b>#(InstanceName)#</b>
   </td>
   </tr>>
	Do ..DrawUsername()

   &html<
   </table>
   </td>
   <td bgcolor="#388CCC">&nbsp;</td>
	</tr>
	</tr>
	<table width="100%" border="0" cellpadding="0" cellspacing="0" style="font-size: 10pt;">
	<tr>
	<td colspan="#(4+$S(isClass:0,1:1))#" bgcolor="#D36D00"><img src='#(##class(%CSP.Page).Link("/csp/sys/images/spacer.gif"))#' width="100%" height="2" alt="-" border="0"></td>
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
		<span title="#(msgPrivate)#"><input id="cbPrivate" type="checkbox" onclick="togglePrivate(this.checked);" #(private)# /><span onclick="togglePrivate(!self.document.getElementById('cbPrivate').checked);">#(cmdPrivate)#</span></span>&nbsp;
		<span title="#(msgStorage)#"><input id="cbStorage" type="checkbox" onclick="toggleStorage(this.checked);" #(storage)# /><span onclick="toggleStorage(!self.document.getElementById('cbStorage').checked);">#(cmdStorage)#</span></span></td>>
	}

	&html<<td class="LocatorBar">&nbsp;</td></tr>>
	//&html<<tr><td class="LocatorBar" align="center">Debug: </td></tr>>
	&html<</table>>
}

/// Display Printer Friendly Version link
ClassMethod RenderPrinter() [ Private ]
{
	Set tPrintURL = ..Link("%25CSP.Documatic.PrintClass.cls")_"?"_$zcvt($G(%request.CgiEnvs("QUERY_STRING")),"O","HTML")
	Set tPrintImage = ..Link("/csp/broker/deepsee/printer_24.png")
	Set tPrintTitle = $$$TextHTML("Printer Friendly Version")
	&html<<div align="right" valign="middle" style="margin-right:8px;">
	<a href="#(tPrintURL)#" title="#(tPrintTitle)#" target="_top">
	<img src="#(tPrintImage)#" width="24" height="24" border="0"></a></div>>
}

/// Draw username or server name depend on setup.
ClassMethod DrawUsername()
{
	Set msgUser = $$$TextHTML("User")
	Set msgServer = $$$TextHTML("Server")
	Set msgInstance = $$$TextHTML("Instance")
	Set hlpUser = $$$TextHTML("Name of user logged into this session")

	&html<<tr><td title="#(hlpUser)#" class="quote-name" style="text-align: left;">
	<span style="color:#FFFAE7; font-size:8pt; padding-right:5px;">#(msgUser)#:</span><b>#($UserName)#</b></td></tr>
	>
}

/// Generate a label containing the string <PARAMETER>label</PARAMETER>. The <PARAMETER>id</PARAMETER>
/// is a unique index for the DHTML elements to work.
ClassMethod RenderLabel(label As %String, ByRef id As %Integer) As %Status [ Private ]
{
	Set anchor = "Anchor_" _ label
	&html<<a name="#(anchor)#"></a>>

	&html<<table class="Label" cellpadding="0" cellspacing="0" cols="1">>
	&html<<tr valign="center">>
	&html<<td align="left" width="100%" >>

	&html<<a href="#" onclick="expandIt(#(id)#); return false;" class="PackageChoice" title="Expand/Collapse #(label)#" onmouseover="this.style.color = 'red';" onmouseout="this.style.color = 'black';">
	<image id=Im#(id)# src=/csp/sys/images/ExpandedMarker.jpg height=15 width=16 border=0 align=bottom>>

	&html<<nobr><b>#(label)#</b></nobr></a>>
	&html<</td>>
	&html<</tr>>
	&html<</table>>
	&html<<br>>

	&html<<div id="Id#(id)#" class="DivShow" style="">>
	
	Set id=id+1
	
	Quit $$$OK
}

/// Generate a label containing the string <PARAMETER>label</PARAMETER>.
ClassMethod RenderLibraryLabel(label As %String) As %Status [ Private ]
{
	&html<<table bgcolor="#CBE6EB" cellpadding="0" cellspacing="0" cols="2">
<tr valign="center">
<td align="left" width="20">
</td>

<td align="left" width="100%">
<b>#(label)#</b>
</td></tr></table><br>>

	Quit $$$OK
}

/// Generate HTML header for the class <PARAMETER>cdef</PARAMETER>.
ClassMethod RenderClassInfo(cdef As %ClassDefinition, pFull As %Boolean = 1) As %Status [ Private ]
{
	Write "<br><p>",!
	Write "<nobr>"
	
	If cdef.Hidden=1 Write "<font class=""hidden"">hidden " // BDB830
	If cdef.Deprecated=1 Write ..RenderDeprecatedBadge(cdef)
	If cdef.Abstract=1 Write "abstract "
	Set clstype= $$$getClassType($$$NormalizeClassname(cdef.Name))
	If clstype'="",clstype'=$$$cCLASSCLASSTYPESYSTEM Write clstype," "
	
	Write $$$TextHTML("class")," <b>"_cdef.Name_"</b>",!
	If cdef.Super'="" Write $$$TextHTML(" extends ")_..ConvertClassList(cdef.Super),!
	
	If cdef.Hidden=1 Write "</font>" // BDB830
	
	Write "</nobr>"
	
	If clstype=$$$cCLASSCLASSTYPEDATATYPE,cdef.OdbcType'="" {
		Write "<p>",$$$TextHTML("ODBC Type:")," <b>",..EscapeHTML(cdef.OdbcType),"</b></p>",!
	}
	
	If clstype=$$$cCLASSCLASSTYPEPERSISTENT,cdef.SqlTableName'="" {
		Write "<p>",$$$TextHTML("SQL Table Name: ")
		Write ..EscapeHTML(cdef.SqlTableName)
		Write "</p>",!
	}
	
	If clstype=$$$cCLASSCLASSTYPEVIEW {
		If cdef.SqlTableName'="" {
			Write "<dl><dt>",$$$TextHTML("SQL Table Name:"),"<dd>",..EscapeHTML(cdef.SqlTableName),"</dl>",!
		}
		If cdef.ViewQuery'="" {
			Write "<dl><dt>",$$$TextHTML("View Query:"),"<dd>",..EscapeHTML(cdef.ViewQuery),"</dl>",!
		Do ..RenderViewQuery(cdef.ViewQuery)
		}
	}
	
	If (pFull) {
		Do ..RenderDescription(cdef.Name,cdef.Description,"<p>","</p>")
	}

	#; test for generated classes
	Set tGen = $$$comClassKeyGet(cdef.Name,$$$cCLASSgeneratedby)
	If ((tGen '= "") && ($ZCVT($E(tGen,$L(tGen)-3,*),"U") = ".CLS")) {
		Write "<div style=""font-style:italic;"">",$$$FormatText($$$Text("This class was generated by %1."),..ClassToLink($E(tGen,1,$L(tGen)-4),,%library)),"</div><br/>"
	}

	Quit $$$OK
}

/// Generate the metadata info for a ViewQuery
ClassMethod RenderViewQuery(query As %String) [ Private ]
{
	Do ..RenderMTCData(query)
	Quit
	
	Set RS = ##class(%Library.ResultSet).%New("%DynamicQuery:SQL")
	Set sc = RS.Prepare(query)
	If ($SYSTEM.Status.IsError(sc))
	{
		Write "<dl><dt>",$$$TextHTML("Query analysis error:"),"<dd>",..EscapeHTML($SYSTEM.Status.GetErrorText(sc)),"</dl>",!
		Quit
	}

	Write "<dl><dt>",$$$TextHTML("Query analysis error:"),"<dd>"
	Write "<table cols=""4"" border=""1"" cellspacing=""2"">",!
	Write "<thead>",!
	Write "<tr>",!
	Write "<th>Col</th>",!
	Write "<th>Name</th>",!
	Write "<th>Heading</th>",!
	Write "<th>Data Type</th>",!
	Write "</tr>",!
	Write "</thead>",!
	Write "<tbody>",!
	Set colcnt = RS.GetColumnCount()
	Set types=$LISTBUILD("Binary","Date","Double","Handle","Integer","List","LongVarChar","Time","Timestamp","VarChar","Status","BinaryStream","CharacterStream","Numeric","Currency","Boolean","OID","BigInt","FDate","FTimestamp")
	For i=1:1:colcnt
	{
		Set tname=RS.GetColumnName(i)
		Set thdr=RS.GetColumnHeader(i)
		Set ttype=RS.GetColumnType(i)
		If ((ttype<1)||(ttype>$LISTLENGTH(types)))
		{
			Set ttype="<Unknown>"
		}
		Else
		{
			Set ttype=$LISTGET(types,ttype)
		}
		Write "<tr>",!
		Write "<td align=""CENTER"">",i,"</td>"
		Write "<td>",..EscapeHTML(tname),"</td>"
		Write "<td>",..EscapeHTML(thdr),"</td>"
		Write "<td>",..EscapeHTML(ttype),"</td>"
		Write "</tr>",!
	}
	Write "</tbody>",!
	Write "</table>",!
	
	Write "</dl>",!
	Quit
}

/// Use a more primitive mechanism to get the query metadata
ClassMethod RenderMTCData(query As %String) [ Private, ProcedureBlock = 0 ]
{
	; Magic incantation from Aviel
	New data,j,mcurs,mtag,%mmmzzzr,%qscqry,pathout,%switch,sql
	Set sql=0
	Set sql($i(sql)) = query

	Set %qscqry=1
	Set %switc="ODBC"
	Kill mtc
	Set $ZT="NoGetQuery"
	Do comp^%qaqqt("query",.sql,"info","",0,"","%qsc(%qscacn")
	If ($GET(SQLCODE) < 0)
	{
		Write "<dl><dt>",$$$TextHTML("Query analysis error:"),"<dd>SQLCODE = ",$GET(SQLCODE),"</dl>",!
		Quit
	}

	Write "<dl><dt>",$$$TextHTML("Query analysis:"),"<dd>"

	Write "<table cols=""10"" border=""1"" cellspacing=""2"" cellpadding=""2"">",!
	Write "<thead>",!
	Write "<tr>",!
	Write "<th>",$$$TextHTML("Col"),"</th>",!
	Write "<th>",$$$TextHTML("Schema"),"</th>",!
	Write "<th>",$$$TextHTML("Table"),"</th>",!
	Write "<th>",$$$TextHTML("Col Name"),"</th>",!
	Write "<th>",$$$TextHTML("Col Label"),"</th>",!
	Write "<th>",$$$TextHTML("Datatype"),"</th>",!
	Write "<th>",$$$TextHTML("ODBC Type Code"),"</th>",!
	Write "<th>",$$$TextHTML("Length"),"</th>",!
	Write "<th>",$$$TextHTML("Precision"),"</th>",!
	Write "<th>",$$$TextHTML("Scale"),"</th>",!
	Write "</tr>",!
	Write "</thead>",!
	Write "<tbody>",!
	; see %qaqpif2.rtn for the description of the mtc data
	Set colcnt=$GET(mtc(0, 0, "select"))
	For i=1:1:colcnt
	{
		Set coldata=$GET(mtc(0, 0, "select",i,1))
		Set tschema=$PIECE(coldata,$CHAR(1),9)
		Set ttable=$PIECE(coldata,$CHAR(1),11)
		Set tname=$PIECE(coldata,$CHAR(1),17)
		Set tlabel=$PIECE(coldata,$CHAR(1),1)
		Set tctype=$PIECE(coldata,$CHAR(1),13)
		Set totype=$PIECE(coldata,$CHAR(1),16)
		Set tlength=$PIECE(coldata,$CHAR(1),3)
		Set tprecision=$PIECE(coldata,$CHAR(1),4)
		Set tscale=$PIECE(coldata,$CHAR(1),5)
		Write "<tr>",!
		Write "<td align=""CENTER"">",i,"</td>"
		Write "<td>",tschema,"</td>"
		Write "<td>",ttable,"</td>"
		Write "<td>",tname,"</td>"
		Write "<td>",tlabel,"</td>"
		Write "<td>",tctype,"</td>"
		Write "<td align=""CENTER"">",totype,"</td>"
		Write "<td align=""CENTER"">",tlength,"</td>"
		Write "<td align=""CENTER"">",tprecision,"</td>"
		Write "<td align=""CENTER"">",tscale,"</td>"
		Write "</tr>",!
	}
	Write "</tbody>",!
	Write "</table>",!
	
	Write "</dl>",!
	Quit
	
NoGetQuery
	Set $ZT=""
	Write "<dl><dt>Unable to resolve table name</dl>",!
	Quit
}

/// Generate HTML for the method <PARAMETER>mdef</PARAMETER>.
ClassMethod RenderMethodInfo(mdef As %MethodDefinition, desc As %String) As %Status [ Private ]
{
	Set name=mdef.Name
	#; anchor
	Write "<a name="""_name_"""></a>",!
	Write "<a name=""METHOD_"_name_"""></a>",!
	Write ..FmtInternal(..IsInternal(mdef,desc))
	Write "<nobr>&#149 "
	
	If mdef.Deprecated=1 Write ..RenderDeprecatedBadge(mdef)
	If mdef.Abstract Write "abstract "
	If mdef.Private=1 Write "private "
	If mdef.Final=1 Write "final "
	If mdef.ClassMethod=1 Write "class"
	
	Write $$$TextHTML("method")," <b>"_name
	Write "("_..ConvertFormalSpec(mdef.FormalSpec)_")</b>",!
	If mdef.ReturnType'="" {
		Write $$$TextHTML("as ")_..ClassToLink(mdef.ReturnType,,%library)_"</nobr>",!
	} Else {
		Write "</nobr>",!
	}
	Set closeBracket = 0
	If ('((mdef.Language="")||(mdef.Language="cache"))) {
		Write $S(closeBracket:",",1:"[")
		Write " Language = ",mdef.Language
		Set closeBracket = 1
	}
	If (mdef.SQLProc) {
		Write $S(closeBracket:",",1:"[")
		Write " SQLProc = ", mdef.SQLName
		Set closeBracket = 1
	}
	If ($$$comMemberKeyGet(mdef.ClassName,$$$cCLASSmethod,mdef.Name,$$$cMETHwebmethod)) {
		Write $S(closeBracket:",",1:"[")
		Write " WebMethod"
		Set closeBracket = 1
	}
	If ($$$comMemberKeyGet(mdef.ClassName,$$$cCLASSmethod,mdef.Name,$$$cMETHzenmethod)) {
		Write $S(closeBracket:",",1:"[")
		Write " ZenMethod"
		Set closeBracket = 1
	}
	Write:closeBracket " ]"
	
	Write ..EndFmt()
	&html<<blockquote>>
	If (desc'="") {
		Do ..RenderDescription(mdef.ClassName,desc,"","")
	}
	&html<</blockquote>>
	
	Quit $$$OK
}

/// Generate HTML for the class parameter <PARAMETER>pdef</PARAMETER>.
ClassMethod RenderParameterInfo(pdef As %ParameterDefinition, desc As %String) As %Status [ Private ]
{
	#; anchor
	Write "<a name="""_pdef.Name_"""></a>",!
	Write "<a name=""PARAMETER_"_pdef.Name_"""></a>",!
	Write ..FmtInternal(..IsInternal(pdef,desc))
	Write "<nobr>&#149 "

	If pdef.Deprecated=1 Write ..RenderDeprecatedBadge(pdef)
	If pdef.Final=1 Write "final "
	Write "parameter <b>"_pdef.Name_"</b>"

	#; show value
	If pdef.Default'="" {
		Write " = "_..EscapeHTML($zutil(144,1,pdef.Default))
	}
	Write ";",!

	Write "</nobr>",!
	Write ..EndFmt()
	Do ..RenderDescription(pdef.ClassName,desc,"<BLOCKQUOTE>","</BLOCKQUOTE>")

	Quit $$$OK
}

/// Generate HTML for the property <PARAMETER>pdef</PARAMETER>.
ClassMethod RenderPropertyInfo(pdef As %PropertyDefinition, desc As %String) As %Status [ Private ]
{
	#; anchor
	Write "<a name="""_pdef.Name_"""></a>",!
	Write "<a name=""PROPERTY_"_pdef.Name_"""></a>",!
	Write ..FmtInternal(..IsInternal(pdef,desc))
	Write "<nobr>&#149 "
	
	Set collection = ""
	If pdef.Collection="list" Set collection = " list of "
	If pdef.Collection="array" Set collection = " array of "

	If pdef.Deprecated=1 Write ..RenderDeprecatedBadge(pdef)
	Write $S(pdef.Relationship=1:"relationship",1:"property")
	Write " <b>"_pdef.Name_"</b>",!
	If pdef.Type'="" Do
	. Write " as "_collection_..ClassToLink(pdef.Type,,%library)
	. If pdef.Parameters.Count()>0 Do
	. . Write "("
	. . Set pname="",first=1
	. . For  Set pval=pdef.Parameters.GetNext(.pname) Quit:pname=""  Do
	. . . Write $S(first:"",1:",")_pname_"="_..EscapeHTML($zutil(144,1,pval))
	. . . Set first=0
	. . Write ")"
	
	Set params=""
	If pdef.Deprecated Set params=params_$S(params="":"",1:",")_"Deprecated"
	If pdef.Private Set params=params_$S(params="":"",1:",")_"Private"
	If pdef.Calculated Set params=params_$S(params="":"",1:",")_"Calculated"
	If pdef.Final Set params=params_$S(params="":"",1:",")_"Final"
	If pdef.SqlFieldName'="" Set params=params_$S(params="":"",1:",")_"SqlFieldName = "_..EscapeHTML(pdef.SqlFieldName)
	If pdef.InitialExpression'="",pdef.InitialExpression'="""""" Set params=params_$S(params="":"",1:",")_"InitialExpression = "_..EscapeHTML(pdef.InitialExpression)
	If pdef.MultiDimensional Set params=params_$S(params="":"",1:",")_"MultiDimensional"
	If pdef.Required Set params=params_$S(params="":"",1:",")_"Required"
	If pdef.Transient Set params=params_$S(params="":"",1:",")_"Transient"
	If pdef.ReadOnly Set params=params_$S(params="":"",1:",")_"ReadOnly"
	
	If pdef.Relationship=1 {
		Set params=params_$S(params="":"",1:",")_"Inverse = <a href="_..ClassToUrl(pdef.Type,%library)_"#"_pdef.Inverse_">"_pdef.Inverse_"</a>"
		Set params=params_$S(params="":"",1:",")_"Cardinality = "_pdef.Cardinality
	}
	
	If params'="" {
		Write "&nbsp;[ "_params_" ]"
	}
	Write ";"
	
	Write "</nobr>",!
	Write ..EndFmt()
	Do ..RenderDescription(pdef.ClassName,desc,"<blockquote>","</blockquote>")
	Quit $$$OK
}

/// Generate HTML for the query <PARAMETER>qdef</PARAMETER>.
ClassMethod RenderQueryInfo(qdef As %QueryDefinition, desc As %String) As %Status [ Private ]
{
	Write "<a name="""_qdef.Name_"""></a>"
	Write "<a name=""QUERY_"_qdef.Name_"""></a>"
	Write ..FmtInternal(..IsInternal(qdef,desc))
	Write "<nobr>&#149 "
	If qdef.Deprecated=1 Write ..RenderDeprecatedBadge(qdef)
	Write "query <b>"_qdef.Name
	Write "("_..ConvertFormalSpec(qdef.FormalSpec)_")</b>"
	If qdef.Parameters.IsDefined("ROWSPEC") 
	{
		&html<<blockquote>>
		&html<Selects <b>>
		&html<#(..ConvertFormalSpec(qdef.Parameters.GetAt("ROWSPEC")))#>
		&html<</b>>
		&html<</blockquote>>
	}
	&html<</nobr>>
	Set querytext = $ZSTRIP(qdef.SQLQuery, "<>")
	If ($LENGTH(querytext) > 0)
	{
		&html<<blockquote>>
		&html<<b>>
		Write "SQL Query"
		&html<</b>>
		If (+qdef.SQLView)
		{
			Write " as view """, ..EscapeHTML(qdef.SQLViewName), """"
		}
		Write ": ", !
		Write "<br>", !
		Set querylines = $LENGTH(querytext, $CHAR(10))
		For i = 1 : 1 : querylines
		{
			&html<<span class="sqltext">>
			Write ..EscapeHTML($PIECE(querytext, $CHAR(10), i)), !
			&html<</span>>
			Write "<br>", !
		}
		&html<</blockquote>>
	}
	Write ..EndFmt()
	Do ..RenderDescription(qdef.ClassName,desc,"<BLOCKQUOTE>","</BLOCKQUOTE>")
	
	Quit $$$OK
}

/// Generate HTML for the query <PARAMETER>qdef</PARAMETER>.
ClassMethod RenderIndexInfo(idef As %IndexDefinition, desc As %String) As %Status [ Private ]
{
	Write "<a name="""_idef.Name_"""></a>"
	Write "<a name=""INDEX_"_idef.Name_"""></a>"
	Write ..FmtInternal(..IsInternal(idef,desc))
	Write "<nobr>&#149"
	If idef.Deprecated=1 Write ..RenderDeprecatedBadge(idef)
	Write "index <b>("_idef.Name_"</b>"
	Write " on <b>"_idef.Properties_")</b>"
	Set params=""
	If idef.Data'="" Set params=params_$S(params="":"",1:",")_"Data = "_$select(idef.Data[",":"("_idef.Data_")",1:idef.Data)
	If idef.Extent Set params=params_$S(params="":"",1:",")_"Extent"
	If idef.IdKey Set params=params_$S(params="":"",1:",")_"IdKey"
	If idef.PrimaryKey Set params=params_$S(params="":"",1:",")_"PrimaryKey"
	If idef.SQLName'="" Set params=params_$S(params="":"",1:",")_"SqlName = "_idef.SQLName
	If idef.Type'="" Set params=params_$S(params="":"",1:",")_"Type = "_idef.Type
	If idef.Unique Set params=params_$S(params="":"",1:",")_"Unique"
	If params'="" Write "&nbsp;["_params_"]"
	Write ";"
	&html<</nobr>>
	Write ..EndFmt()
	Do ..RenderDescription(idef.ClassName,desc,"<BLOCKQUOTE>","</BLOCKQUOTE>")
	Quit $$$OK
}

/// Generate HTML for the query <PARAMETER>qdef</PARAMETER>.
ClassMethod RenderForeignKeyInfo(idef As %ForeignKeyDefinition, desc As %String) As %Status [ Private ]
{
	Write "<a name="""_idef.Name_"""></a>"
	Write "<a name=""FOREIGNKEY_"_idef.Name_"""></a>"
	Write ..FmtInternal(..IsInternal(idef,desc))
	Write "<nobr>&#149"
	If idef.Deprecated=1 Write ..RenderDeprecatedBadge(idef)
	Write "foreignkey <b>"_idef.Name_"</b>"
	Write " (<b>"_idef.Properties_")</b>"
	&html<</nobr>>
	Write:(idef.SQLName'="") " as "_"<b>"_idef.SQLName_"</b>"
	Write " references "
	Write ..ClassToLink(idef.ReferencedClass,,%library)
	Write " (<b>"_idef.ReferencedKey_"</b>)"
	Write:(idef.OnDelete'="") " OnDelete: "_idef.OnDelete
	Write:((idef.OnDelete'="")&&(idef.OnUpdate'="")) ";"
	Write:(idef.OnUpdate'="") " OnUpdate: "_idef.OnUpdate
	&html<</nobr>>
	Write ..EndFmt()
	Do ..RenderDescription(idef.ClassName,desc,"<BLOCKQUOTE>","</BLOCKQUOTE>")
	Quit $$$OK
}

/// Generate HTML for the query <PARAMETER>qdef</PARAMETER>.
ClassMethod RenderTriggerInfo(idef As %TriggerDefinition, desc As %String) As %Status [ Private ]
{
	;Quit $$$OK
	Write "<a name="""_idef.Name_"""></a>"
	Write "<a name=""TRIGGER_"_idef.Name_"""></a>"
	Write ..FmtInternal(..IsInternal(idef,desc))
	Write "<nobr>&#149"
	If idef.Deprecated=1 Write ..RenderDeprecatedBadge(idef)
	Write "trigger <b>"_idef.Name_"</b>"
	&html<</nobr>>
	Write " ("
	Write "<b>"_idef.Time_"</b> event <b>"_idef.Event_")</b>"
	Write ..EndFmt()
	Do ..RenderDescription(idef.ClassName,desc,"<BLOCKQUOTE>","</BLOCKQUOTE>")
	Quit $$$OK
}

/// Convert a list of class names (such as a <i>super</i> list) to an HTML string with hyperlinks.
ClassMethod ConvertClassList(list As %String) As %String [ Private ]
{
	Set out = ""
	For i= 1 : 1 : $LENGTH(list, ",")
	{
		Set name = $PIECE(list, ",", i)
		Set fqname = "[none]"
		Set:($LENGTH(name) > 0) fqname = ..ClassToLink(name,,%library)
		Set out = out _ $SELECT(i>1:", ",1:"") _ fqname
	}
	
	Quit out
}

/// Convert a formal spec to an HTML string with hyperlinks.
ClassMethod ConvertFormalSpec(spec As %String) As %String [ Private ]
{
	Set out="",type=""
	Set state=0
	
	For pos=1:1:$L(spec) {
		Set c=$E(spec,pos)
		Set s=state
		If (s=0) {
			If ("*"[c) { Set out=out_"Output " }
			ElseIf ("*"[c) { Set out=out_"Output " }
			ElseIf ("&"[c) { Set out=out_"ByRef " }
			ElseIf (","[c) { Set out=out_", " }
			ElseIf (":"[c) {
				Set state=1
				Set type=""
			}
			ElseIf (""""[c) {
				Set out=out_c
				Set state=2
				Set type=""
			}
			Else {
				Set out=out_c
			}
		}
		ElseIf (s=1) {
			If (":"[c) {
				// ClassToLink (<name>, <type>, <dname>)
				Set out=out_$S(type'="":" As "_..ClassToLink(type,,%library),1:"")
				Set state=3
			}
			ElseIf ("=,("[c) {
				Set out=out_$S(type'="":" As "_..ClassToLink(type,,%library),1:"")
				Set out=out_$S(c="=":" = ",c=",":", ",c="(":c,1:" ")
				Set state=0
			}
			ElseIf (" "[c) {
				set c=c	 //no op
			}
			Else {
				Set type=type_c
			}
			
		}
		ElseIf (s=2) {
			If (""""[c) {
				// end of quoted literal
				Set out=out_c
				Set state=0
			}
			Else { Set out=out_c }
		}
		ElseIf (s=3) {
			If ("=,"[c) {
				Set out=out_$S(c="=":" = ",c=",":", ",1:" ")
				Set state=0
			}
		}
	}
	
	If ((state=1)&&(type'="")) { Set out=out_" As "_..ClassToLink(type,,%library) }
	
	Quit out
}

/// Convert a classname to a URL.
/// <br><VAR>anchor</VAR> is an anchor within the page.
/// Normalize this name for package support with the current class name.
ClassMethod ClassToUrl(name As %String, %library As %String = "%SYS", anchor As %String = "") As %String [ Private ]
{
	#; classname is the current class to normalize from
	If $get(%request.Data("CLASSNAME",1))'="" Do NormalizeClassnameByDef^%occName(.name,name,%request.Data("CLASSNAME",1))
	Quit ..#URL_"?PAGE=CLASS&LIBRARY="_..EscapeURL(%library)_"&CLASSNAME="_..EscapeURL(name)_$s($data(%request.Data("REFERER")):"&REFERER="_..EscapeURL(%request.Data("REFERER",1)),1:"")_$S(anchor'="":"#"_anchor,1:"")
}

/// Convert a package name to a URL.
/// <br><VAR>anchor</VAR> is an anchor within the page.
ClassMethod PackageToUrl(name As %String, %library As %String = "%SYS", anchor As %String = "") As %String [ CodeMode = expression, Private ]
{
..#URL_"?PAGE=CLASS&LIBRARY="_..EscapeURL(%library)_"&PACKAGE=1&CLASSNAME="_..EscapeURL(name)_$s($data(%request.Data("REFERER")):"&REFERER="_..EscapeURL(%request.Data("REFERER",1)),1:"")_$S(anchor'="":"#"_anchor,1:"")
}

/// Return <PARAMETER>num</PARAMETER> non breaking spaces '&nbsp'
ClassMethod spaces(num As %Integer) As %String [ Private ]
{
	Set return=""
	For i=1:1:num Set return=return_"&nbsp"
	Quit return
}

/// Convert a classname to an HTML hyperlink.
ClassMethod ClassToLink(name As %String, openhtml As %String = "<", %library As %String = "%SYS") As %String [ CodeMode = expression, Private ]
{
openhtml_"nobr>"_openhtml_"a href="""_..ClassToUrl(name,%library)_""">"_name_openhtml_"/a>"_openhtml_"/nobr>"
}

/// Write a description string out as HTML. Apply substitutions for 
/// documatic tags.
ClassMethod RenderDescription(thisclass As %String, desc As %String, starttag As %String, endtag As %String)
{
 If $zstrip(desc,"<W")="" Write starttag,endtag Quit
 Set stream=##class(%GlobalCharacterStream).%New()

 Write starttag

 Set xml=##class(%CSP.TokenStream).%New()
 Do xml.OpenFromString(desc)
 Set state=""
 Set openhtml="<"
 Set example=0

 For  Quit:xml.NextToken()=0  Set istag=xml.IsTag() Do

 #; Finish of EXAMPLE tag, render the code
 . If example,istag,$ZCVT(xml.Text,"U")[("</EXAMPLE>") Do
 . . If $L(xml.Text)'=$L("</EXAMPLE>") Do stream.Write($E(xml.Text,1,$L(xml.Text)-$L("</EXAMPLE>")))
 #; Put a tab at the start of each line except labels (which start with a ':' symbol) for COS
 . . If lang="COS" Do
 . . . Set formatIn=##class(%GlobalCharacterStream).%New()
 . . . For  Quit:stream.AtEnd  Set i=32000,line=stream.ReadLine(.i) Do:i'=0
 . . . . If line="",stream.AtEnd Quit
 . . . . Do formatIn.WriteLine($S($E(line)=":":$P($E(line,2,*)," ")_$C(9)_$P($E(line,2,*)," ",2,$$$MaxPieceNum),1:$C(9)_line))
 . . . Do ..RenderCode(formatIn,lang,oldStream)
 . . Else  Do
 . . . Set formatIn=##class(%GlobalCharacterStream).%New()
 . . . For  Quit:stream.AtEnd  Set i=32000,line=stream.ReadLine(.i) Do:i'=0
 . . . . If line="",stream.AtEnd Quit
 . . . . Do formatIn.WriteLine($S($E(line)=":":$E(line,2,*),1:line))
 . . . Do ..RenderCode(formatIn,lang,oldStream)
 . . Set stream=oldStream
 . . Kill oldStream
 . . Set example=0
 . . Set openhtml="<"
 . . Set state=""

 . Else  If state'="" Do
 #; If state is set then we are inside a <tag> block so accumulate the text until we get the </tag> entry
 . . If istag,$ZCVT(xml.Text,"U")[("</"_state_">") Do
 . . . If $L(xml.Text)'=$L("</"_state_">") Set text=text_$E(xml.Text,1,$L(xml.Text)-$L("</"_state_">"))
 . . . If state="CLASS" Do stream.Write($S(text=thisclass:openhtml_"b>"_text_openhtml_"/b>",1:..ClassToLink(text,openhtml,$G(%library,""))))
 . . . Else  If state="METHOD" Do stream.Write(openhtml_"nobr>"_openhtml_"a class=MethodLink href=#"_text_">"_$REPLACE(text,"()","")_"()"_openhtml_"/a>"_openhtml_"/nobr>")
 . . . Else  If state="PROPERTY" Do stream.Write(openhtml_"nobr>"_openhtml_"a class=PropertyLink href=#"_text_">"_text_openhtml_"/a>"_openhtml_"/nobr>")
 . . . Else  If state="PARAMETER" Do stream.Write(openhtml_"nobr>"_openhtml_"a class=ParameterLink href=#"_text_">"_text_openhtml_"/a>"_openhtml_"/nobr>")
 . . . Else  If state="QUERY" Do stream.Write(openhtml_"nobr>"_openhtml_"a class=QueryLink href=#"_text_">"_$REPLACE(text,"()","")_"()"_openhtml_"/a>"_openhtml_"/nobr>")
 . . . Else  If state="LINK",link'="" Do stream.Write(openhtml_"a href=/csp/docbook"_$S($E(link)="/":link,1:"/"_link)_">"_text_openhtml_"/a>"_openhtml_"/nobr>")
 . . . Set state=""

 #; Accumulate the text inside the <tag> we are interested in
 . . Else  Set text=text_xml.Text

 #; EXAMPLE tag is a special case
 . Else  If 'example,istag,xml.GetTag()="EXAMPLE" Do
 . . Set example=1
 . . Set oldStream=stream
 . . Set openhtml="<&"
 . . Set stream=##class(%GlobalCharacterStream).%New()
 #; Hack to get language mode from the <EXAMPLE LANGUAGE=BAS> tag
 . . Set lang=$P($P($P($ZCVT(xml.Text,"U"),"LANGUAGE=",2),">")," "),lang=$S(lang="":"COS",1:lang)

 #; Look for opening tags that interest us
 . Else  If istag,'example,",CLASS,METHOD,PROPERTY,PARAMETER,QUERY,LINK,"[(","_xml.GetTag()_",") Do
 . . Set state=xml.GetTag(),text=""
 #; Hack to get the link href, e.g. <link href=/image/classlogo.jpg>
 . . If state="LINK" Do
 . . . Set link=""
 . . . Set find=$F($ZCVT(xml.Text,"U"),"HREF=")
 . . . If find Set link=$P($P($E(xml.Text,find,*)," "),">")

 . Else  Do stream.Write(xml.Text)

 If state'="" Do stream.Write(text)

 #; If oldStream exists then we have not found the </EXAMPLE> tag
 If $D(oldStream) Do
 . Do oldStream.Rewind()
 . Do oldStream.OutputToDevice()

 Do stream.Rewind()
 Do stream.OutputToDevice()
 Write endtag
 Quit
}

/// Color the code in <PARAMETER>streamIn</PARAMETER> based on the language <PARAMETER>lang</PARAMETER>
/// and return the result in the stream <PARAMETER>streamOut</PARAMETER>. If <PARAMETER>lang</PARAMETER>
/// is 'NONE' then it will not try and syntax color the example code.
ClassMethod RenderCode(streamIn As %CharacterStream, lang As %String, streamOut As %AbstractStream)
{
	Set $ZT="TrapColor"

	#; JMD380
	Set lang = $TR(lang,"""","") // strip "

	If lang="NONE" Goto TrapColor
	#; CMT1675
	#; If ('($$$isWINDOWS)) Goto TrapColor
	
	Set synColor=##class(%Library.SyntaxColor).%New()
	Set streamHtmlOut=##class(%GlobalCharacterStream).%New()
	
	#; This will generate the colored output, if it fails (returns FALSE) then display output in plain text
	If 'synColor.Color(streamIn,streamHtmlOut,lang,"") Goto TrapColor
	
	Do streamOut.Write("<div class=""SampleCode"">")
	;Do streamOut.Write(("<pre>" _ lang _ "</pre>"))
	Do streamOut.CopyFrom(streamHtmlOut)
	Do streamOut.Write("</div>")
	Quit
	
	#; If we get an error coloring the routine just display the plain text instead
	#; so this will handle cases where color does not work or is not installed on this platform
TrapColor	  Set $ZT=""
	Do streamOut.Write("<div class=""SampleCode""><pre>")
	#; Make sure the stream is at the start
	Do streamIn.Rewind()
	#; Remove the '<&' and replace with '<' to unescape the tags
	For  Quit:streamIn.AtEnd  Set i=32000 Set line=streamIn.Read(.i) Do
	. Set i=1 For  Set i=$F(line,"<&",i) Quit:'i  Set line=$E(line,1,i-2)_$E(line,i,*)
	. ; CMT1675
	. Do streamOut.Write($zcvt(line,"O","HTML"))
	Do streamOut.Write("</pre></div>")
	Quit
}

/// The <b>DefinedBy</b> query returns a list of class names 
/// that define member <VAR>member</VAR>. <VAR>type</VAR> is the 
/// type of the class member, e.g., "method".
Query DefinedBy(type As %String, member As %String) As %Query(ROWSPEC = "ClassName:%String")
{
}

ClassMethod DefinedByExecute(ByRef QHandle As %Binary, type As %String, member As %String) As %Status
{
	#; qhandle is $LB(type,member,clsname)
	Set QHandle=$LB(type,member,"")
	
	Quit $$$OK
}

ClassMethod DefinedByClose(QHandle As %Binary) As %Status
{
	#; close the result set
	Set QHandle=""
	Quit $$$OK
}

ClassMethod DefinedByFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set type=$LG(QHandle,1)
	Set member=$LG(QHandle,2)
	Set clsname=$LG(QHandle,3)
	Set showInternal = ..ShowInternal()
	
	#; find next class defining this member
	For  Set clsname=$$$defClassNext(clsname) Quit:clsname=""  Quit:$$$defMemberDefined(clsname,type,member)&&(showInternal||'$$$defMemberKeyGet(clsname,type,member,$$$cXXXXinternal))
	
	Set QHandle=$LB(type,member,clsname)
	
	#; done
	If clsname="" Set AtEnd=1,Row="" Quit $$$OK
	
	#; found a class
	Set AtEnd=0,Row=$LB(clsname)
	
	Quit $$$OK
}

/// The <b>ImplementedBy</b> query returns a list of class names 
/// that implement member <VAR>member</VAR>. <VAR>type</VAR> is the 
/// type of the class member, e.g., "method".
Query ImplementedBy(type As %String, member As %String) As %Query(ROWSPEC = "ClassName:%String")
{
}

ClassMethod ImplementedByExecute(ByRef QHandle As %Binary, type As %String, member As %String) As %Status
{
	#; qhandle is $LB(type,member,clsname)
	Set QHandle=$LB(type,member,"")
	
	Quit $$$OK
}

ClassMethod ImplementedByClose(QHandle As %Binary) As %Status
{
	#; close the result set
	Set QHandle=""
	Quit $$$OK
}

ClassMethod ImplementedByFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set type=$LG(QHandle,1)
	Set member=$LG(QHandle,2)
	Set clsname=$LG(QHandle,3)
	Set showInternal = ..ShowInternal()
	
	; find next class defining this member
	For  Set clsname=$$$comClassNext(clsname) Quit:clsname=""  Quit:$$$comMemberDefined(clsname,type,member)&&(showInternal||'$$$comMemberKeyGet(clsname,type,member,$$$cXXXXinternal))
	
	Set QHandle=$LB(type,member,clsname)
	
	; done
	If clsname="" Set AtEnd=1,Row="" Quit $$$OK
	
	; found a class
	Set AtEnd=0,Row=$LB(clsname)
	
	Quit $$$OK
}

/// The <b>ReferencedBy</b> query returns a list of class names 
/// that refer to (has properties of type) <VAR>refclass</VAR>.
Query ReferencedBy(refclass As %String) As %Query(ROWSPEC = "ClassName:%String,Property:%String")
{
}

ClassMethod ReferencedByExecute(ByRef QHandle As %Binary, refclass As %String) As %Status
{
	#; qhandle is $LB(refclass,prop,clsname)
	Set QHandle=$LB(refclass,"","")
	
	Quit $$$OK
}

ClassMethod ReferencedByClose(QHandle As %Binary) As %Status
{
	#; close the result set
	Set QHandle=""
	Quit $$$OK
}

ClassMethod ReferencedByFetch(ByRef QHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status
{
	Set refclass=$LG(QHandle,1)
	Set prop=$LG(QHandle,2)
	Set clsname=$LG(QHandle,3)
	Set found=0
	
	; find next class & property referencing refclass
	For  Quit:found=1  Set:prop="" clsname=$$$defClassNext(clsname) Quit:clsname=""  Do
	. For  Quit:found=1  Set prop=$$$defMemberNext(clsname,$$$cCLASSproperty,prop) Quit:prop=""  Do
	. . If $$$defMemberKeyGet(clsname,$$$cCLASSproperty,prop,$$$cPROPtype)=refclass Set found=1
	
	Set QHandle=$LB(refclass,prop,clsname)
	
	; done
	If clsname="" Set AtEnd=1,Row="" Quit $$$OK
	
	; found a class
	Set AtEnd=0,Row=$LB(clsname,prop)
	
	Quit $$$OK
}

/// Draw HTML for class summary.
ClassMethod RenderClassSummary(pClass As %String) As %Status [ Private ]
{
	Set showInternal = ..ShowInternal()
	Set showPrivate = $get(%request.Data("PRIVATE",1))
	
	#; Note to future coders: Case-sensitive ordering of member
	#; names is intentional!

	Set tClass = pClass
	
	#; test for special cases
	Try {
		If $classmethod(tClass,"%IsA","%ZEN.Component.page") {
			Do ..RenderZenPageInfo(tClass)
		}
		ElseIf $classmethod(tClass,"%IsA","%ZEN.Report.reportPage") {
			Do ..RenderZenReportInfo(tClass)
		}
		ElseIf $classmethod(tClass,"%IsA","%ZEN.application") {
			Do ..RenderZenAppInfo(tClass)
		}
		ElseIf tClass'="%DeepSee.CubeDefinition",$classmethod(tClass,"%IsA","%DeepSee.CubeDefinition") {
			Do ##class(%CSP.Documatic.CubeInfo).RenderCubeInfo(tClass,0)
		}	   
		ElseIf tClass'="%DeepSee.SubjectArea",$classmethod(tClass,"%IsA","%DeepSee.SubjectArea") {
			Do ##class(%CSP.Documatic.CubeInfo).RenderSubjectAreaInfo(tClass,1)
		}
		ElseIf ##class(%Library.EnsembleMgr).IsEnsembleNamespace() {
			If $classmethod(tClass,"%IsA","Ens.Production") {
				Do ##class(Ens.Util.Documatic).RenderProductionInfo(tClass)
			}
			ElseIf $classmethod(tClass,"%IsA","Ens.BusinessProcess") {
				Do ##class(Ens.Util.Documatic).RenderBusinessProcessInfo(tClass)
			}
			ElseIf $classmethod(tClass,"%IsA","Ens.BusinessService") {
				Do ##class(Ens.Util.Documatic).RenderBusinessServiceInfo(tClass)
			}
			ElseIf $classmethod(tClass,"%IsA","Ens.BusinessOperation") {
				Do ##class(Ens.Util.Documatic).RenderBusinessOperationInfo(tClass)
			}
		}
	}
	Catch(ex) {
		Set $ZE = ""
	}
	
	#; find subclasses
	Set tRS = ##class(%ResultSet).%New("%ClassDefinition:SubclassOf")
	Do tRS.Execute(tClass)
	Set tSubCount = 0
	Set tSubMaxLen = 0
	While tRS.Next() {
		Set tSubName = tRS.Data("Name")

		#; test if we are an immediate subclass
		Set tSuper = $$$defClassKeyGet(tSubName,$$$cCLASSsuper)
		Set sc = $$NormalizeClassnameByDef^%occName(.tNmlSuper,tSuper,tSubName)
		If ((","_tNmlSuper_",") [ (","_tClass_",")) {
			Set tSubCount = tSubCount + 1
			Set tSubList(tSubName) = ""
			Set:$L(tSubName)>tSubMaxLen tSubMaxLen = $L(tSubName)
		}
	}

	#; loop over properties
	Set tPropCount = 0
	Set tPropMaxLen = 0
	Set tPropName = $$$comMemberNext(tClass,$$$cCLASSproperty,"")
	While (tPropName '= "") {
		Set tPrivate = +$$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPprivate)
		Set tInternal = +$$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPinternal)

		If ('tPrivate||showPrivate) {
			If ('tInternal||showInternal) {
				Set tPropCount = tPropCount + 1
				Set tPropList(tPropName) = ""
				Set:$L(tPropName)>tPropMaxLen tPropMaxLen = $L(tPropName)
			}
		}
		Set tPropName = $$$comMemberNext(tClass,$$$cCLASSproperty,tPropName)
	}

	#; loop over methods
	Set tMethCount = 0
	Set tMethName = $$$comMemberNext(tClass,$$$cCLASSmethod,"")
	Set tMethMaxLen = 0
	While (tMethName '= "") {
		Set tInternal = +$$$comMemberKeyGet(tClass,$$$cCLASSmethod,tMethName,$$$cMETHinternal)
		Set tPrivate = +$$$comMemberKeyGet(tClass,$$$cCLASSmethod,tMethName,$$$cMETHprivate)

		If ('tPrivate||showPrivate) {
			If ('tInternal||showInternal) {
				#; skip property methods (if there is no origin assume property method)
				If ($$$comMemberKeyGet(tClass,$$$cCLASSmethod,tMethName,$$$cMETHorigin)'="") {
					Set tMethCount = tMethCount + 1
					Set tMethList(tMethName) = ""
					Set:$L(tMethName)>tMethMaxLen tMethMaxLen = $L(tMethName)
				}
			}
		}
		Set tMethName = $$$comMemberNext(tClass,$$$cCLASSmethod,tMethName)
	}

	Set msgSub = $$$Text("Subclasses")
	Set msgProps = $$$Text("Properties")
	Set msgMeths = $$$Text("Methods")
	Set hlpKey = $$$Text("Bold for local member; italics for inherited; shaded for private; blue for client methods; strikethrough for deprecated.")
	Set msgNone = $$$Text("This class has no methods or properties.")
	Set hlpSub = $$$Text("These classes are directly derived from the current class.")

	#; show properties
	If (tPropCount > 0) {
		Set tCols = $S(tPropMaxLen>30:3,tPropMaxLen<15:5,1:4)
		Set:tPropCount<tCols tCols = tPropCount
		&html<<table class="Summary" border="0" cellspacing="0" cellpadding="1">
		<tr><th colspan="#(tCols)#" title="#(hlpKey)#">#(msgProps)#</th></tr>>
		&html<<tr>>
		Set col = 1
		Set tPropName = $O(tPropList(""))
		While (tPropName '= "") {
			Set tPrivate = +$$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPprivate)
			Set tDeprecated = +$$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPdeprecated)
			Set tOrigin = $$$comMemberKeyGet(tClass,$$$cCLASSproperty,tPropName,$$$cPROPorigin)
			Set url = ""
			Set inh = ""
			Set tags = ""
			Set priv = ""
			If (tOrigin '= tClass) {
				Set inh = "inherited"
				Set url = "%25CSP.Documatic.cls?PAGE=CLASS&LIBRARY="_$ZCVT($get(%library,$namespace),"O","URL")_"&CLASSNAME="_$ZCVT(tOrigin,"O","URL")_$S(showPrivate:"&PRIVATE=1",1:"")_"#"_tPropName
				Set url = ##class(%CSP.Page).Link(url)
			}
			Else {
				Set url = "#"_"PROPERTY_"_tPropName
			}
			Set:tPrivate priv = "class=""private"""
			Set:inh'="" tags = "inherited"
			Set:tDeprecated=1 tags=tags_" deprecated"
			Set tags="class="""_$ZSTRIP(tags, "<P")_""""

			If (col > tCols) {
				&html<</tr><tr>>
				Set col = 1
			}
			&html<<td #(priv)# nowrap><a #(tags)# href="#(url)#" title="#(tOrigin)#">#($ZCVT(tPropName,"O","HTML"))#</a></td>>
			Set col = col + 1
	
			Set tPropName = $O(tPropList(tPropName))
		}
		&html<</tr>>
		&html<</table><br/>>
	}

	#; show methods
	If (tMethCount > 0) {
		Set tCols = $S(tMethMaxLen>30:3,tMethMaxLen<15:5,1:4)
		Set:tMethCount<tCols tCols = tMethCount
		&html<<table class="Summary" border="0" cellspacing="0" cellpadding="1">
		<tr><th colspan="#(tCols)#" title="#(hlpKey)#">#(msgMeths)#</th></tr>>
		&html<<tr>>
		Set col = 1
		Set tMethName = $O(tMethList(""))
		While (tMethName '= "") {
			Set tPrivate = +$$$comMemberKeyGet(tClass,$$$cCLASSmethod,tMethName,$$$cMETHprivate)
			Set tDeprecated = +$$$comMemberKeyGet(tClass,$$$cCLASSmethod,tMethName,$$$cMETHdeprecated)
			Set tOrigin = $$$comMemberKeyGet(tClass,$$$cCLASSmethod,tMethName,$$$cMETHorigin)
			Set tLang = $$$comMemberKeyGet(tClass,$$$cCLASSmethod,tMethName,$$$cMETHlanguage)
			Set url = ""
			Set inh = ""
			Set tags = ""
			Set priv = ""
			If (tOrigin '= tClass) {
				Set inh = "inherited"
				Set url = "%25CSP.Documatic.cls?PAGE=CLASS&LIBRARY="_$ZCVT($get(%library,$namespace),"O","URL")_"&CLASSNAME="_$ZCVT(tOrigin,"O","URL")_$S(showPrivate:"&PRIVATE=1",1:"")_"#"_tMethName
				Set url = ##class(%CSP.Page).Link(url)
			}
			Else {
				Set url = "#"_"METHOD_"_tMethName
			}
			
			If ($ZCVT(tLang,"L") = "javascript") {
				Set inh = inh_"JS"
			}
			Set:inh'="" tags = "inherited"
			Set:tDeprecated=1 tags=tags_" deprecated"
			Set tags="class="""_$ZSTRIP(tags, "<P")_""""
			Set:tPrivate priv = "class=""private"""

			If (col > tCols) {
				&html<</tr><tr>>
				Set col = 1
			}
			&html<<td #(priv)# nowrap><a #(tags)# href="#(url)#" title="#(tOrigin)#">#($ZCVT(tMethName,"O","HTML"))#</a></td>>
			Set col = col + 1
	
			Set tMethName = $O(tMethList(tMethName))
		}
		&html<</tr>>
		&html<</table><br/>>
	}

	#; show subclasses
	If (tSubCount > 0) {
		Set tCols = $S(tSubMaxLen>25:3,tSubMaxLen<15:5,1:4)
		Set:tSubCount<tCols tCols = tSubCount
		&html<<table class="Summary" border="0" cellspacing="0" cellpadding="1">
		<tr><th colspan="#(tCols)#" title="#(hlpSub)#">#(msgSub)#</th></tr>>
		&html<<tr>>
		Set col = 1
		Set tSubName = $O(tSubList(""))
		set tShowHidden = ..ShowInternal() // BDB830
		While (tSubName '= "") {
			
			// BDB830
			set tHidden = ..IsHidden(tSubName)
			if tShowHidden || 'tHidden {
				
				Set tDeprecated = $$$comClassKeyGet(tSubName,$$$cCLASSdeprecated)
				Set url = ""
				Set inh = ""
				Set tags = ""
				Set priv = ""
				Set url = "%25CSP.Documatic.cls?PAGE=CLASS&LIBRARY="_$ZCVT($get(%library,$namespace),"O","URL")_"&CLASSNAME="_$ZCVT(tSubName,"O","URL")
				Set url = ##class(%CSP.Page).Link(url)
				Set:inh'="" tags = "inherited"
				set:tHidden tags = $zstrip(tags_" hidden","<W") // BDB830
				Set tags="class="""_$ZSTRIP($s(tDeprecated=0:tags, 1:tags_" "_"deprecated"), "<P")_""""
				If (col > tCols) {
					&html<</tr><tr>>
					Set col = 1
				}
				&html<<td #(priv)# nowrap><a #(tags)# href="#(url)#" title="#("")#">#($ZCVT(tSubName,"O","HTML"))#</a></td>>
				Set col = col + 1
			}
	
			Set tSubName = $O(tSubList(tSubName))
		}
		&html<</tr>>
		&html<</table>>
	}

	If ((tPropCount = 0)&&(tMethCount = 0)&&(tSubCount = 0)) {
		&html<<div style="font-style: italic;">#(msgNone)#</div>>
	}

	Quit $$$OK
}

/// Draw HTML for Zen Report Information.
ClassMethod RenderZenReportInfo(pClass As %String) As %Status [ Private ]
{
	Try {
		Set msgApp = ""
		Set msgPage = $$$Text("This is a Zen Report class.")
		Set tApplication = $$$comMemberKeyGet(pClass,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)
		If (tApplication '= "") {
			If ($E(tApplication)="@") {
				Set tLink = tApplication
			}
			Else {
				Set tLink = ..ClassToLink(tApplication,,$G(%library,$namespace))
			}
			Set msgApp = $$$FormatText($$$Text("It belongs to the application %1."),tLink)
		}
		&html<<div class="SummaryText">#(msgPage)#&nbsp;#(msgApp)#</div>>
		&html<<br>>
	}
	Catch(ex) {
		Write "ERROR: ",$ZE
	}
	Quit $$$OK
}

/// Draw HTML for Zen Page Information.
ClassMethod RenderZenPageInfo(pClass As %String) As %Status [ Private ]
{
	Try {
		Set msgApp = ""
		Set msgPage = $$$Text("This is a Zen Page class.")
		Set tApplication = $$$comMemberKeyGet(pClass,$$$cCLASSparameter,"APPLICATION",$$$cPARAMdefault)
		If (tApplication '= "") {
			If ($E(tApplication)="@") {
				Set tLink = tApplication
			}
			Else {
				Set tLink = ..ClassToLink(tApplication,,$G(%library,$namespace))
			}
			Set msgApp = $$$FormatText($$$Text("It belongs to the application %1."),tLink)
		}
		&html<<div class="SummaryText">#(msgPage)#&nbsp;#(msgApp)#</div>>
		&html<<br>>
	}
	Catch(ex) {
		Write "ERROR: ",$ZE
	}
	Quit $$$OK
}

/// Draw HTML for Zen Application Information.
ClassMethod RenderZenAppInfo(pClass As %String) As %Status [ Private ]
{
	Try {
		Set msgPages = $$$Text("Pages within this Application")
		Set msgApp = $$$Text("This is a Zen Application class.")
		Set hlpKey = ""

		&html<<div class="SummaryText">#(msgApp)#</div><br/>>

		Do ##class(%ZEN.Utils).%GetPagesInApplication(pClass,.tList)

		#; show pages in app
		If ($D(tList)) {
			Set tCols = 3
			&html<<table class="Summary" border="0" cellspacing="0" cellpadding="1">
			<tr><th colspan="#(tCols)#" title="#(hlpKey)#">#(msgPages)#</th></tr>>
			&html<<tr>>
			Set col = 1
			Set tPageName = $O(tList(""))
			While (tPageName '= "") {
				Set url = ""
				Set inh = ""
				Set priv = ""
				Set url = "%25CSP.Documatic.cls?PAGE=CLASS&LIBRARY="_$ZCVT($get(%library,$namespace),"O","URL")_"&CLASSNAME="_$ZCVT(tPageName,"O","URL")
				Set url = ##class(%CSP.Page).Link(url)
				Set:inh="" inh = "class=""inherited"""
				
				If (col > tCols) {
					&html<</tr><tr>>
					Set col = 1
				}
				&html<<td #(priv)# nowrap><a #(inh)# href="#(url)#" title="">#($ZCVT(tPageName,"O","HTML"))#</a></td>>
				Set col = col + 1
		
				Set tPageName = $O(tList(tPageName))
			}
			&html<</tr>>
			&html<</table>>
			&html<<br>>
		}
	}
	Catch(ex) {
	}
	Quit $$$OK
}

ClassMethod RenderDeprecatedBadge(pdef As %AbstractDefinition) As %String [ Private ]
{
	Return "<span class=""deprecated"">deprecated</span>"
}

}
