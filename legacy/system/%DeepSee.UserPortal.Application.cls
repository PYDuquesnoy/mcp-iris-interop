/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base Zen application class for the DeepSee UserPortal.
/// This is used by the HomePage, and Dashboard viewer pages.
Class %DeepSee.UserPortal.Application Extends (%ZEN.application, %CSP.Portal.SourceControl.Base) [ System = 4 ]
{

/// This is the name of this application.
Parameter APPLICATIONNAME = "DeepSee Portal";

/// This is the default company name displayed within this application.
Parameter COMPANYNAME = "InterSystems";

Parameter DOMAIN = "%DeepSee";

/// This is the URL of the main starting page of this application.
Parameter HOMEPAGE = "_DeepSee.UserPortal.Home.zen";

/// This Style block contains application-wide CSS 3 style definitions.
XData Style
{
<style type="text/css">
body {
	font-family: arial;
}

.zenBody {
	background: white;
}

/* scroll bar overload */
::-webkit-scrollbar {
	width: 10px;
	height: 10px;
}

::-webkit-scrollbar-track {
    -webkit-box-shadow: inset 0 0 6px rgba(0,0,0,0.3); 
    -webkit-border-radius: 10px;
    border-radius: 10px;
}

::-webkit-scrollbar-thumb {
    -webkit-border-radius: 10px;
    border-radius: 10px;
    background: rgba(100,110,130,0.5); 
    -webkit-box-shadow: inset 0 0 6px rgba(0,0,0,0.5); 
}

/* Wrapper div for dynaGrid. */
.dynaGridWrapper {
	border: 1px solid #A0A0A0;
}

/* menu overrides */
div.csMenuBar {
	color: #404040;
	border: none;
	margin-bottom: 2px;
	text-align: center;
	border-radius: 3px;
}

.csActiveMenuItem {
	color: black;
	background: #FFEEAA;
	border: 1px solid silver;
	border-radius: 3px;
}

/* outer group around contents */
.contentsOuter {
	margin-left: 20px;
	width: 0px;
	border: 1px solid black;
	border-radius: 10px;
	background: rgb(53,107,141);
	visibility: hidden;
}

/* inner div around contents (wraps contents) */
.contentsInner {
	background: white;
	color: #404040;
	overflow: hidden;
}

/* outer group around contents (no border mode) */
.contentsOuterNoBorder {
	width: 0px;
	background: none;
	visibility: hidden;
}

/* inner div around contents (no border mode) */
.contentsInnerNoBorder {
	background: none;
	color: #404040;
	overflow: hidden;
}

/* div around left-hand column */
#contentsLeft {
	background: rgb(220,231,241);
	overflow: hidden;
}

/* div around right-hand column */
#contentsRight {
}

#foldersHeader {
	background: #C0C0C0;
	background-image: url(images/grad-halfgray-10x100.png);
	background-repeat: repeat-x;
}

#foldersList {
	background: white;
	overflow: hidden;
}

#foldersList:hover {
	overflow: auto;
}

/* items within work lists */
table.worklistTable {
	border-bottom: 1px solid #F0F0F0;
}

#foldersFooter {
	margin: 0px;
	padding: 0px;
	height: 20px;
	background: #C0C0C0;
	background-image: url(images/grad-halfgray-10x100.png);
	background-repeat: repeat-x;
}

.foldersHeaderDiv {
	padding: 10px;
	overflow: hidden;
	white-space:nowrap;
}

/* worklist title div */
.worklistTitle {
	padding: 10px;
	font-family: Arial;
	font-size: 24px;
	color: rgb(0,0,0);
	overflow: hidden;
}

/* wrapper for worklist*/
.worklistWrapper {
}


/* html container for worklist header */
.worklistHeaderDiv {
	border-left: 1px solid #808080;
	border-right: 1px solid #808080;
	border-top: 1px solid #808080;
	border-bottom: none;
	border-top-right-radius: 5px;
	border-top-left-radius: 5px;
	background: white;
}

/* html container for worklist*/
.worklistDiv, .worklistGroup {
	border-left: 1px solid #808080;
	border-right: 1px solid #808080;
	border-bottom: 1px solid #808080;
	border-top: none;
	border-bottom-right-radius: 5px;
	border-bottom-left-radius: 5px;
	background: white;
}

.worklistGroup {
	overflow: auto;
	border-top: 1px solid #F0F0F0;
}

/* div within worklist panel */
.worklist {
	overflow: hidden;
	border-top: 1px solid #F0F0F0;
	border-bottom: 1px solid #F0F0F0;
}

.worklist:hover {
	overflow: auto;
}

.worklistHeaderTitle {
	font-weight: bold;
	font-size: 20px;
	color: #606060;
}

.worklistHeaderMsg {
	font-size: 12px;
	text-align: center;
}

.worklistHeaderAll {
	color: blue;
	font-size: 12px;
}

table.worklistHeaderTable td {
	padding: 2px;
	padding-bottom: 5px;
}

tr.worklistHeader th {
	text-align: left;
	color: black;
	font-size: 14px;
	font-weight: bold;
}

td.worklistSmall {
	font-size: 12px;
}

tr.worklistRowEven {
}

tr.worklistRowOdd {
	background: rgb(236,236,236);
}

tr.worklistRowHover {
	background: #FFEEAA;
}

table.worklistTable td, table.worklistTable th {
	padding: 2px;
}

td.worklistIcon,td.worklistIconCurrent {
	padding: 0px;
}

td.worklistIcon:hover,td.worklistIconCurrent:hover {
	background: #FFEEAA;
}

td.worklistIconCurrent {
	background: #F0F0FF;
	border: 1px solid #D0D0F0;
	border-radius: 5px;
}

td.worklistIcon img,td.worklistIconCurrent img {
	height: 24px;
	width: 24px;
	padding: 2px;
}

td.worklistIcon img {
	opacity:0.8;
}

td.worklistIcon img:hover,td.worklistIconCurrent img:hover {
	opacity:1.0;
}

table.listTable td a {
	color: #404040;
	text-decoration: none;
}

table.listTable td a:hover {
	color: #404040;
	text-decoration: underline;
}

table.listTable td a:active {
	text-shadow: 2px 2px 8px #8080D0, -2px -2px 8px #8080D0;
}

.workListType {
	font-size: 12px;
	color: #404080;
	font-variant: small-caps;
}

.workListKeyWord {
	font-size: 12px;
}

/* styles for specific lists */
.favFolder {
	font-size: 12px;
}

.favName {
	font-weight: bold;
	font-size: 14px;
}

.favDate {
	font-size: 12px;
}

/* folder list */
table.listTable {
}

table.listTable th {
	text-align: left;
	color: black;
	font-size: 16px;
	font-weight: bold;
	padding-top: 2px;
	padding-bottom: 2px;
	padding-right: 2px;
}

table.listTable td {
	padding-right: 4px;
}

tr.listRowEven,
tr.listRowOdd {
	-webkit-transition-property: background;
	-webkit-transition-duration: 0.25s;
	-webkit-transition-timing-function: ease;

	-moz-transition-property: background;
	-moz-transition-duration: 0.25s;
	-moz-transition-timing-function: ease;

	transition-property: background;
	transition-duration: 0.25s;
	transition-timing-function: ease;
}

tr.listRowEven {
}

tr.listRowOdd {
	background: rgb(236,236,236);
}

tr.listRowEven:hover,
tr.listRowOdd:hover {
	background: #FFEEAA;
}

tr.listRowEven:active,
tr.listRowOdd:active {
	background: #FFF8CC;
}

.portalTitle {
	width: 100%;
	vertical-align: middle;
}

.portalTitleTable {
	width: 100%;
	margin-top: 10px;
}

table td.portalTitleMainMenu {
	font-size: 10pt;
	text-align: center;
	padding-left: 2px;
	padding-right: 2px;
}

.portalTitleMainMenuLink {
	color: black;
	text-decoration: none;
	border: 1px solid black;
}

.portalTitleMainMenuLink:hover {
	background: #FFEEAA;
}

td.portalTitleInfoLabel {
	padding-left: 10px;
	font-size: 9pt;	
	color: #808080;
	text-align: right;
}

td.portalTitleInfoVal {
	font-size: 9pt;	
	color: #404040;
	text-align: left;
	font-weight: bold;
}

td.portalTitleMsg {
	background: #808080;
	font-size: 14px;
	color: yellow;
	width: 150px;
	padding: 2px;
	border-radius: 3px;
	text-align: center;
	font-variant: small-caps;
	white-space: nowrap;
}

td.portalTitleMsg img {
	opacity: 0.8;
}

td.portalTitleMsg img:hover {
	opacity: 1.0;
}

td.portalTitleMsg img:active {
	box-shadow: 2px 2px 8px #8080D0, -2px -2px 8px #8080D0;
}

td.portalTitleMenuBox {
	font-size: 9pt;	
}

.portalTitleLink {
	font-size: 9pt;	
	color: blue;
	text-decoration: none;
}

.portalTitleLink:hover {
	color: darkred;
}

td.portalLogo {
	color: #404040;
	font-weight: bold;
	font-size: 12pt;
	padding: 2px;
	padding-left: 5px;
	padding-right: 5px;
	text-align: center;
}

/* command button styles */
.commandButton {
	background: rgb(53,107,141);
	color: white;
	text-decoration: none;
	padding: 1px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 5px;
 	border-top: 1px solid lightgray;
    border-left: 1px solid lightgray;
    border-right: 2px solid gray;
    border-bottom: 2px solid gray;
}

.commandButtonRemove {
	background: darkred;
	color: white;
	text-decoration: none;
	padding: 1px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 5px;
 	border-top: 1px solid lightgray;
    border-left: 1px solid lightgray;
    border-right: 2px solid gray;
    border-bottom: 2px solid gray;
}

.commandButtonDisabled {
	background: darkgray;
	color: gray;
	text-decoration: none;
	padding: 1px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 5px;
}

.commandButton:hover {
	color: white;
	background: rgb(73,127,151);
}

.commandButtonRemove:hover {
	color: white;
	background: #808080;
}

img {
	border: none;
}


/* overrides of tablePane */
table.tpTable {
	border: none;
}

table.tpTable td {
	border-right: 1px solid #F0F0F0;
	border-bottom: 1px solid #F0F0F0;
	padding: 2px;
	overflow: hidden;
}

table.tpTable tr.tpSelected td {
	font-weight: normal;
	border-right: 1px solid #F0F0F0;
	border-bottom: 1px solid rgb(47,98,128);
	padding-top: 2px;
	padding-bottom: 2px;
}

table.tpTable tr.tpSelected {
	color: white;
	background: rgb(47,98,128);
	background-image: none;
}

.tpOdd {
	color: black;
	background: white;
}
.tpEven {
	color: black;
	background: #F0F0F0;
}

/* combo boxes and dateText */
.comboboxInput {
	border-top: 1px solid #8080F0;
	border-bottom: 1px solid #8080F0;
	border-left: 1px solid #8080F0;
	border-right: none;
}

.comboboxDropDown {
	border: 1px solid #8080F0;
}

.comboboxImgButton {
	border-top: 1px solid #8080F0;
	border-bottom: 1px solid #8080F0;
	border-left: none;
	border-right: 1px solid #8080F0;
}

.comboboxTextButton {
	border: 1px solid #8080F0;
}

a.CompanyLink {
	text-decoration: none;
	color: inherit;
}

.detailLabel {
	font-size: 8pt;
	font-weight: bold;
	color: #606060;
	padding: 2px;
	background: #F0F0F0;
}

.detailValue {
	font-size: 10pt;
	padding: 2px;
	color: #202020;
	border-bottom: 1px solid #D0D0D0;
}

.icon {
	opacity: 0.8;
}

.icon:hover {
	opacity: 1.0;
	background: #FFEEAA;
	border-radius: 3px;
}

.icon:active {
	background: white;
	box-shadow: 2px 2px 4px white, -2px -2px 4px white;
}

/* navigator */
.navHeader {
}

</style>
}

/// Provide any quick links for pages.
ClassMethod GetQuickLinks(Output pLinks) As %Status
{
	Set pLinks("Home") = ..#HOMEPAGE
	Quit $$$OK
}

/// Draw the HTML contents of the title area for portal pages.
Method %DrawTitleHTML(pTitle As %String, ByRef pSmallMenu) As %Status
{
	// Get information on this server
	Do ..%GetServerInfo(.tServerInfo)

	// Get local preferences
	Do ##class(%DeepSee.UserPortal.Utils).%GetPreferences(.tPrefs)
	Set tCompany = $G(tPrefs("CompanyName"),..#COMPANYNAME)
	Set tCompanyImage = $G(tPrefs("CompanyImage"))
	Set tCompanyStyle = $G(tPrefs("CompanyNameStyle"))
	Set tCompanyLink = $G(tPrefs("CompanyLink"))

	Set tInstance = $G(tServerInfo("instance"))
	Set tLicensedTo = $G(tServerInfo("licensedTo"))
	Set tNamespace = $G(tServerInfo("namespace"))
	Set tUserName = $G(tServerInfo("user"))

	&html<<div class="portalTitle">>
	&html<<table class="portalTitleTable" border="0" cellpadding="0"><tr>>

	&html<<td>&nbsp;</td>>

	#; message box
	&html<<td nowrap="1" id="portalTitleMsg" class="portalTitleMsg" style="display:none;">>
	&html<</td>>

	&html<<td>&nbsp;</td>>

	#; small menu
	&html<<td nowrap="1">>
	Do ..%DrawSmallMenu(.pSmallMenu)
	&html<</td>>
	
	If %page.%IsA("%DeepSee.UserPortal.DashboardViewer") {
		// DTB103 - the classmethod draws <td> elements containing the source control buttons
		// Only draw the buttons on the dashboard editor
		Do:(%page.canWrite) ..%DrawSourceControlCommands()		// DTB646 -  Check privileges for source control button display
		&html<<td width="20%">&nbsp;</td>>
	}

	&html<
		<td nowrap="1" align="right" width="10%" class="portalTitleInfoLabel">#($$$Text("User"))#:</td><td class="portalTitleInfoVal" nowrap="1" width="15%">#($zcvt(tUserName,"O","HTML"))#&nbsp;</td>
		<td nowrap="1" align="right" width="10%" class="portalTitleInfoLabel">#($$$Text("Licensed to"))#:</td><td class="portalTitleInfoVal" nowrap="1" width="15%">#(tLicensedTo)#&nbsp;</td>
	>

	#; JMD1186: give cell an id so pages can override it
	&html<<td id="portalCompanyCell" width="20%" class="portalLogo" title="Powered by InterSystems IRIS Analytics" nowrap="1"><div style="#(tCompanyStyle)#">>
	If (tCompanyLink'="") {
		&html<<a class="CompanyLink" target="_blank" href="#(tCompanyLink)#">>
	}
	If (tCompanyImage '="") {
		&html<<image src="#(tCompanyImage)#" alt="#($ZCVT(tCompany,"O","HTML"))#"/>>
	}
	Else {
		Write $ZCVT(tCompany,"O","HTML")
	}
	If (tCompanyLink'="") {
		&html<</a>>
	}
	&html<</div></td>>
	&html<<td>&nbsp;</td>>
	&html<</tr></table>>
	&html<</div>>
	Quit $$$OK
}

/// Get information about this server, return it via the array <var>pInfo</var>
Method %GetServerInfo(Output pInfo)
{
	Set pInfo("instance") = $P($ZU(86),"*",2)
	Set pInfo("licensedTo") = $ZCVT($$CustomerName^%SYS.LICENSE,"O","HTML")
	Set pInfo("user") = $UserName
	Set pInfo("namespace") = $namespace
}

/// Draw small menu at the top of the title area.
Method %DrawSmallMenu(ByRef pMenu As %String)
{
	// pMenu takes the form:
	// pMenu(1) = $LB("Caption","title","script")
	&html<<div class="portalTitleMenuBox">>
	Set tCount = 0
	Set n = $O(pMenu(""))
	While (n '= "") {
		If (tCount > 0) {
			&html<<span>|</span>>
		}
		Set tCount = tCount + 1
		Set tCaption = $LG(pMenu(n),1)
		Set tTitle = $LG(pMenu(n),2)
		Set tCode = $LG(pMenu(n),3)
		&html<<a class="portalTitleLink" title="#(tTitle)#" href="#" onclick="#(tCode)#return false;">#($ZCVT(tCaption,"O","HTML"))#</a>>
		Set n = $O(pMenu(n))
	}
	&html<</div>>
}

/// Get the company name for the page.
Method %OnGetCompanyName() As %String
{
	Quit ..#COMPANYNAME
}

}
