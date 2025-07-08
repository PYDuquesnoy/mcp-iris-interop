/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %products

/// Base Zen application class for portal pages implemented using Zen.
Class %ZEN.Portal.Application Extends %ZEN.application [ Deprecated, System = 4 ]
{

/// This is the name of this application.
Parameter APPLICATIONNAME = "InterSystems Portal";

Parameter DOMAIN = "%Utility";

/// This is the URL of the main starting page of this application.
Parameter HOMEPAGE = "/csp/sys/%25CSP.Portal.Home.zen";

/// This Style block contains application-wide CSS style definitions for css3
XData CSS3Style
{
<style type="text/css">
/* YSD3631 Everything below the header remains the same with these exceptions:
Links change to InterSystems blue: #333695  
Beige background of right column panels change to light gray: #F0F0F0
*/
body {
	font-family: Futura,Arial,sans-serif;
}
/* overrider locator bar style (skipped by YSD3631 as it is not currently used by SMP */
.locatorBarTable td {
	background: rgb(53,107,141);
	background-image: none;
	background-repeat: repeat-x;
	border-bottom: 1px darkblue solid;
	padding-bottom: 1px;
	color: white;
}

.locatorBarLinks {
	color: white;
}
.locatorBarLinks a {
	color: white;
}
.locatorBarLinks a:visited {
	color: white;
}
.locatorBarLinks a:hover {
	color: darkred;
	background: #FFFAE7;
}
.locatorBarSelect {
	color: white;
}
/* style for "Management Portal" */
.portalName {
	color:#000000;
	font-family: Futura,Arial,sans-serif; 
	font-size:18px;
	text-align:left;
	text-valign: middle;
	position: absolute;
	left: 300px;
	top: 20px;
}
.portalPropertyPanelTitle {
	color: white;
	font-size: 12pt;
	padding: 5px;
}

.portalPropertyPanelCommands {
	color: white;
	background: rgb(53,107,141);
	width: 100px;
	text-align: center;
	font-size: 9pt;
	border: 1px solid #CBCBCB;
}
.portalTitle {
	width: 100%;
	height: 100px;
	position: relative;
	box-shadow:0 2px 8px 0 rgba(0,0,0,0.12);
	box-sizing: border-box;
}

.portalTitleInfoBox {
	left: 20px;
	position: absolute;
	top: 70px;
	width: calc(100% - 20px); /* the second value MUST be equal to the value of the left property */
}

.portalTitleInfoLabel {
	font-family: Futura,Arial,sans-serif;
	font-size: 14px;
	font-weight: bold;	
	color: #000000;
	padding: 2px 2px;
}

.portalTitleInfoVal {
	font-family: Futura,Arial,sans-serif;
	font-size: 14px;
	font-weight: 400;
	color: #000000;
	padding: 4px 12px 4px 2px;
}

.portalLostConnectivityWarn {
	font-family: Futura,Arial,sans-serif;
	font-size: 13px;
	font-weight: bold;
	letter-spacing: 0.75px;
	text-align: center;	
	background: #aa4040;
	color:#ffffff;
	border-radius: 4px;
	padding: 6px 20px;
	margin-left: 20px;
}

/* style to show "Development System" or "Live System", etc. */
#portalServerFlag {
	float: left;	
}
.portalTitleServerFlag {
	border: 2px solid #333695;
	border-radius: 4px;
	color: #000000;
	font-family: Futura,Arial,sans-serif;
	font-size: 12px;
	font-weight: 600;
	letter-spacing: 0.75px;
	padding: 4px 20px;
}
.portalTitleServerFlagLive {
	color: #da4848;  /* red */
	border: 2px solid #da4848;
}
.portalTitleListBox {
	position: absolute;
	top: 5px;
	left: 20px;
	font-size: 9pt;	
}

.portalTitleMenuBox {
	position: relative;
	top: 20px;
	left: 600px;
	font-size: 14px;
}
/* attemp to make small links and mainMenu not to overlap */
#portalTitleMenuBox {
	position: absolute;
	left: 50%;
	min-width: 350px; 
}
#mainMenu {
	position: absolute;
	left: 95%;
	top: 8px;
}
@media all and (max-width: 980px) {
    #portalTitleMenuBox {
        margin-left: 0px;
        left: 600px;
    }
    #mainMenu {
        margin-left: 0px;
        left: 1210px;
    }
}
.pageTitleText {
	color: #333695;
	font-family: Futura,Arial,sans-serif;
	font-size: 12px;
	font-weight: 550;
	text-decoration: none;
}
.portalTitleLink {
	color: #000000;
	font-family: Futura,Arial,sans-serif;
	font-size: 11pt;
	font-weight: 600;
	padding: 2px;
	text-decoration: none;
}

.portalServerLink {
	color: #333695;
	font-family: Futura,Arial,sans-serif;
	font-size: 12px;
	font-weight: 550;
	text-decoration: underline;
}
.portalLocatorLink {
	text-decoration: none;
}
.portalTitleLink:hover,.portalServerLink:hover,.portalLocatorLink:hover {
	color: #00A09A;
	transition: color 0.03 ease;
}

.portalTitleTabBox {
	position: absolute;
	color: white;
	font-size: 16px;
	bottom: 0px;
	left: 20px;
	width: 300px;
	height: 25px;
	padding-left: 15px;
	padding-right: 15px;
	padding: 5px;

	border-top-right-radius: 5px;
	border-top-left-radius: 5px;

	overflow: hidden;
}

.portalLogoBox {
	position: absolute;
	top: 0px;
	padding: 3px;
	padding-bottom: 4px;
	padding-right: 15px;
	left: 10px;
	width:210px;
	z-index: 3;
}
.topLine {
	border-top: 2px solid #333695;
}
.portalLogo {
	position: relative;
	top: 0px;
	left: 10px;
	padding: 2px;
	padding-left: 5px;
	padding-right: 5px;
	width:210px;
	height:50px;
	font-weight: bold;
	font-size: 12pt;
}

/* overrides of Finder styles */
.finderItemSelected {
	background: #bfe4e3;
	border: 1px solid #cbcbcb;
	color: #303030;
}
.finderItemSelected a {
	color: #303030;
}
.finderListRowSelected {
	background: #bfe4e3;  /*#2F6280;*/
}

.finderItem, .finderItemOdd,.finderItemSelected, .finderItemDisabled {
	border: 1px solid #CBCBCB;
}
.finderItem a, .finderItemOdd a {
	color: #303030;
}
.finderItem a:hover, .finderItemOdd a:hover, .finderItemSelected a:hover {
	color: #303030;
} 


/* command button styles */
.commandButton,.commandButtonRemove,.commandButtonDisabled {
	color: #333695;
    cursor: pointer;
    background: #ffffff;
	border: 2px solid #333695;
	border-radius: 4px;
	font-size: 12px;
	font-weight: 600;
	letter-spacing: 0.75px;
	text-align: center;
	text-decoration: none;
	padding: 6px 20px;
}
.commandButtonRemove {
	background: #333695;
	color: white;
}

.commandButtonDisabled {
	background: #ffffff;
	color: #979797;
	cursor: default;
	border: 2px solid #c5c5c5;
}

.commandButton:hover {
	border: 2px solid #00A09A;
	color: #00A09A;
	transition: color 0.03 ease;
}

.commandButtonRemove:hover {
	border: 2px solid white;
}

img {
	border: none;
}

/* overrides of tablePane */
table.tpTable {
	font-size: 12px;
	border: 2px solid #F1F0E7;
	padding: 2px;
}

/* @doc="Column header." */
table.tpTable th {
	color: #3b84bc;
	border: none;
	background: white;
	font-weight: bold;
	text-align: left;
	padding: 2px;
	overflow: hidden;
}

/* @doc="Selected column header." */
table.tpTable th.tpHdrSelected {
	color: #3b84bc;
	background: white;
}

table.tpTable td {
	border: none;
	padding: 2px;
	overflow: hidden;
}

table.tpTable tr.tpSelected td {
	font-weight: normal;
	border: none;
	padding-top: 2px;
	padding-bottom: 2px;
}

table.tpTable tr.tpSelected {
	color: black;
	border: none;
	background: #F3E799;
	background-image: none;
}
 
/* @doc="Style for rows when not using zebra styling." */
.tpRow {
	color: black;
	background: white;
}

/* @doc="Style for odd-rows when using zebra styling." */
.tpOdd {
	color: black;
	background: #F0F0F0;
}
/* @doc="Style for even-rows when using zebra styling." */
.tpEven {
	color: black;	
	background: white;
}

/* @doc="Cell containing a link." */
.tpAction {
	font-size: 0.9em;
}

.tpAction a {
	white-space: nowrap;
	color: #3b84bc;
}

.tpAction a:hover {
	color: #98923a;
}

.tpAction a:link {
	color: #3b84bc;
}

.tpAction a:active {
	color: #3b84bc;
}

/* @doc="Table around navigator bar." */
.tnbrTable {
	background: #DBE0E6;
	border: 1px solid #F1F0E7;
	border-radius:3px;
	padding: 1px;
}
/* @doc="Buttons within navigator bar." */
.tnbrPagingButtons {
	border: 1px solid #B0B0B0;
}
.tnbrFilter {
	color: #404040;
}
.tnbrFilter input {
	border: 1px solid #B0B0B0;
	padding-left: 2px;
}
/* @doc="Row count indicator." */
.tnbrFound {
	color: #404040;
}
/* combo boxes and dateText */
.comboboxInput {
	border-top: 1px solid #cbcbcb;
	border-bottom: 1px solid #cbcbcb;
	border-left: 1px solid #cbcbcb;
	border-right: none;
}

.comboboxDropDown {
	border: 1px solid #cbcbcb;
}

.comboboxImgButton {
	border-top: 1px solid #cbcbcb;
	border-bottom: 1px solid #cbcbcb;
	border-left: none;
	border-right: 1px solid #cbcbcb;
}

.comboboxTextButton {
	border: 1px solid #cbcbcb;
}
/* override the default green/blue color with ISC blue */
.modalGroup.modalGroupDialog {
	background: #333695;
}
.modalGroupTitle {
	border-bottom: 1px #333695 solid;
}
 .modalGroupTitle td {
	color: #333695;
}
/* the effect of the following is to not show text in the top edge in modal dialog */
.modalGroupIframe {
	background: #333695;
}

</style>
}

/// This Style block contains application-wide CSS style definitions.
XData Style
{
<style type="text/css">
body {
	font-family: Futura,Arial,sans-serif;
}
.formTitle {
	color:#000000;
	font-family: Futura,Arial,sans-serif; 
	font-size: 18px;
	font-weight: bold;
	letter-spacing: 0.75px;
	margin: 20px;
}
/* overrider locator bar style */
.locatorBarTable td {
	background: rgb(53,107,141);
	background-image: none;
	background-repeat: repeat-x;
	border-bottom: 1px darkblue solid;
	padding-bottom: 1px;
	color: white;
}

.locatorBarLinks {
	color: white;
}
.locatorBarLinks a {
	color: white;
}
.locatorBarLinks a:visited {
	color: white;
}
.locatorBarLinks a:hover {
	color: darkred;
	background: #FFFAE7;
}
.locatorBarSelect {
	color: white;
}


.portalPropertyPanelTitle {
	color: white;
	font-size: 12pt;
	padding: 5px;
}

.portalPropertyPanelCommands {
	color: white;
	background: rgb(53,107,141);
	width: 100px;
	text-align: center;
	font-size: 9pt;
	border: 1px solid #CBCBCB;
}

.portalTitle {
	width: 100%;
	height: 100px;
	position: relative;
	box-shadow:0 2px 8px 0 rgba(0,0,0,0.12);
	box-sizing: border-box;
}

.portalTitleInfoBox {
	position: absolute;
	bottom: 0px;
	left: 350px;
	box-shadow:0 2px 8px 0 rgba(0,0,0,0.12);
}

.portalTitleInfoLabel {
	padding-left: 10px;
	font-size: 9pt;	
	color: #606060;
	text-align: left;
}

.portalTitleInfoVal {
	font-size: 9pt;	
	color: black;
	text-align: left;
	font-weight: bold;
}

.portalLostConnectivityWarn {
	font-family: Futura,Arial,sans-serif;
	font-size: 13px;
	font-weight: bold;
	letter-spacing: 0.75px;
	text-align: center;	
	background: #aa4040;
	color:#ffffff;
	border-radius: 4px;
	padding: 6px 20px;
	margin-left: 20px;
}

.portalTitleListBox {
	position: absolute;
	top: 5px;
	left: 20px;
	font-size: 9pt;	
}

.portalTitleMenuBox {
	position: absolute;
	top: 20px;
	left: 900px;
	font-size: 14px;
}
.portalTitleLink {
	color: #000000;
	font-family: Futura,Arial,sans-serif;
	font-size: 14px;
	font-weight: 600;
	padding: 2px;
	text-decoration: none;
}
.pageTitleText {
	color: #333695;
	font-family: Futura,Arial,sans-serif;
	font-size: 12px;
	font-weight: 550;
	text-decoration: none;
}
.portalServerLink {
	color: #333695;
	font-family: Futura,Arial,sans-serif;
	font-size: 12px;
	font-weight: 550;
	text-decoration: underline;
}
.portalLocatorLink {
	text-decoration: none;
}
.portalTitleLink:hover,.portalServerLink:hover,.portalLocatorLink:hover {
	color: #00A09A;
	transition: color 0.03 ease;
}
.portalTitleTabBox {
	position: absolute;
	color: white;
	font-size: 16px;
	bottom: 0px;
	left: 20px;
	width: 300px;
	height: 25px;
	padding-left: 15px;
	padding-right: 15px;
	padding: 5px;

	border-top-right-radius: 5px;
	border-top-left-radius: 5px;

	overflow: hidden;
}

.portalLogoBox {
	position: absolute;
	top: 0px;
	padding: 3px;
	padding-bottom: 4px;
	padding-right: 15px;
	left: 10px;
	width:210px;
	z-index: 3;
}
.topLine {
	border-top: 2px solid #333695;
}
.portalLogo {
	position: relative;
	top: 0px;
	left: 10px;
	padding: 2px;
	padding-left: 5px;
	padding-right: 5px;
	width:210px;
	height:50px;
	font-weight: bold;
	font-size: 12pt;
}

/* overrides of Finder styles */
.finderItemSelected {
	background: #bfe4e3;
	border: 1px solid #cbcbcb;
	color: #303030;
}
.finderItemSelected a {
	color: #303030;
}
.finderListRowSelected {
	background: #bfe4e3;  /*#2F6280;*/
}
.finderItem, .finderItemOdd,.finderItemSelected, .finderItemDisabled {
	border-bottom: 1px solid #CBCBCB;
}
.finderItem a, .finderItemOdd a {
	color: #303030;
}

/* command button styles */
.commandButton {
	background: #FFFFFF;
	color: #333695;
	text-decoration: none;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	border-radius: 4px;
 	border: 1px solid #333695;
}

.commandButton,.commandButtonRemove,.commandButtonDisabled {
	color: #333695;
    cursor: pointer;
    background: #ffffff;
	border: 2px solid #333695;
	border-radius: 4px;
	font-size: 12px;
	font-weight: 600;
	letter-spacing: 0.75px;
	text-align: center;
	text-decoration: none;
	padding: 6px 20px;
}
.commandButtonRemove {
	background: #333695;
	color: white;
}

.commandButtonDisabled {
	background: #ffffff;
	color: #979797;
	cursor: none;
	border: 2px solid #979797;
}

.commandButton:hover {
	border: 2px solid #00A09A;
	color: #00A09A;
	transition: color 0.03 ease;
}

.commandButtonRemove:hover {
	border: 4px solid white;
}

img {
	border: none;
}

/* overrides of tablePane */
table.tpTable {
	font-family: Futura,Arial,sans-serif;	font-size: 12px;
	border: 2px solid #CBCBCB;
	padding: 2px;
}

/* @doc="Column header." */
table.tpTable th {
	color: #3b84bc;
	border: none;
	background: white;
	font-weight: bold;
	text-align: left;
	padding: 2px;
	overflow: hidden;
}

/* @doc="Selected column header." */
table.tpTable th.tpHdrSelected {
	color: #3b84bc;
	background: white;
}

table.tpTable td {
	border: none;
	padding: 2px;
	overflow: hidden;
}

table.tpTable tr.tpSelected td {
	font-weight: normal;
	border: none;
	padding-top: 2px;
	padding-bottom: 2px;
}

table.tpTable tr.tpSelected {
	color: black;
	border: none;
	background: #F3E799;
	background-image: none;
}
 
/* @doc="Style for rows when not using zebra styling." */
.tpRow {
	color: black;
	background: white;
}

/* @doc="Style for odd-rows when using zebra styling." */
.tpOdd {
	color: black;
	background: #F1F0E7;
}
/* @doc="Style for even-rows when using zebra styling." */
.tpEven {
	color: black;	
	background: white;
}

/* @doc="Cell containing a link." */
.tpAction {
	font-size: 0.9em;
}

.tpAction a {
	white-space: nowrap;
	color: #3b84bc;
}

.tpAction a:hover {
	color: #98923a;
}

.tpAction a:link {
	color: #3b84bc;
}

.tpAction a:active {
	color: #3b84bc;
}

/* @doc="Table around navigator bar." */
.tnbrTable {
	border: 1px solid #CBCBCB;
	background: #DCE7F1;
	padding: 1px;
}
/* @doc="Buttons within navigator bar." */
.tnbrPagingButtons {
	border: 1px solid #CBCBCB;
}

/* combo boxes and dateText */
.comboboxInput {
	border-top: 1px solid #cbcbcb;
	border-bottom: 1px solid #cbcbcb;
	border-left: 1px solid #cbcbcb;
	border-right: none;
}

.comboboxDropDown {
	border: 1px solid #cbcbcb;
}

.comboboxImgButton {
	border-top: 1px solid #cbcbcb;
	border-bottom: 1px solid #cbcbcb;
	border-left: none;
	border-right: 1px solid #cbcbcb;
}

.comboboxTextButton {
	border: 1px solid #cbcbcb;
}
/* override the default green/blue color with ISC blue */
.modalGroup.modalGroupDialog {
	background: #333695;
}
.modalGroupTitle {
	border-bottom: 1px #333695 solid;
}
 .modalGroupTitle td {
	color: #333695;
}
/* the effect of the following is to not show text in the top edge in modal dialog */
.modalGroupIframe {
	background: #333695;
}

</style>
}

/// Define any context links for the context menu in the header
/// piece 1: caption (if left null, a menu seperator will be built)
/// piece 2: URL (this is required entry)
/// piece 3: JS function name (if defined is a javascript to call such as "zenPage.save()")
/// Note that all security processing is performed in the page's CheckContextLinks() method.
ClassMethod GetContextLinks(Output pLinks) As %Status
{
	// create list of jump targets and associated URL
	Set tDBSecurity = $System.Security.Check("%DB_IRISSYS","READ,WRITE")
	Set tDBSecurityRead = $System.Security.Check("%DB_IRISSYS","READ")
	// Manager tasks
	If tDBSecurity {
		// Manager tasks
		Set pLinks($I(n)) = $LB($$$Text("Configure Namespaces"),"/csp/sys/mgr/%25CSP.UI.Portal.Namespaces.zen","")
		Set pLinks($I(n)) = $LB($$$Text("Configure Databases"),"/csp/sys/mgr/%25CSP.UI.Portal.Databases.zen","")
		Set pLinks($I(n)) = $LB($$$Text("Configure Memory"),"/csp/sys/mgr/%25CSP.UI.Portal.MemoryStartup.zen","")
		Set pLinks($I(n)) = $LB("","","")

		// Security tasks
		Set pLinks($I(n)) = $LB($$$Text("Manage Web Applications"),"/csp/sys/sec/%25CSP.UI.Portal.Applications.WebList.zen","")
		Set pLinks($I(n)) = $LB($$$Text("Manage Users"),"/csp/sys/sec/%25CSP.UI.Portal.Users.zen","")
		Set pLinks($I(n)) = $LB($$$Text("Manage Roles"),"/csp/sys/sec/%25CSP.UI.Portal.Roles.zen","")
		Set pLinks($I(n)) = $LB($$$Text("Manage Services"),"/csp/sys/sec/%25CSP.UI.Portal.Services.zen","")
		Set pLinks($I(n)) = $LB($$$Text("Manage Resources"),"/csp/sys/sec/%25CSP.UI.Portal.Resources.zen","")
		Set pLinks($I(n)) = $LB("","","")
	}
	
	// Explorer tasks
	If tDBSecurity||(($NAMESPACE '= "%SYS")&&($E($NAMESPACE,1,2)'="^^")) {
		Set pLinks($I(n)) = $LB($$$Text("View SQL"),"/csp/sys/exp/%25CSP.UI.Portal.SQL.Home.zen","")
		Set pLinks($I(n)) = $LB($$$Text("View Classes"),"/csp/sys/exp/%25CSP.UI.Portal.ClassList.zen","")
		Set pLinks($I(n)) = $LB($$$Text("View Routines"),"/csp/sys/exp/%25CSP.UI.Portal.RoutineList.zen","")
		Set pLinks($I(n)) = $LB($$$Text("View Globals"),"/csp/sys/exp/%25CSP.UI.Portal.GlobalList.zen","")
		Set pLinks($I(n)) = $LB("","","")
	}

	// Operator tasks
	Set:tDBSecurityRead pLinks($I(n)) = $LB($$$Text("View System Dashboard"),"/csp/sys/op/UtilDashboard.csp","")
	If tDBSecurity {
		Set pLinks($I(n)) = $LB($$$Text("Manage Locks"),"/csp/sys/op/%25CSP.UI.Portal.Locks.zen","")
		Set pLinks($I(n)) = $LB($$$Text("View Processes"),"/csp/sys/op/%25CSP.UI.Portal.Processes.zen","")
		Set pLinks($I(n)) = $LB($$$Text("View Messages Log"),"/csp/sys/op/UtilSysConsoleLog.csp","")
	}
	#; The Background Tasks CSP page needs an extra check because it does not have its own resource, and should not be shown to users without %Admin_Operate:USE.
	Set:tDBSecurity&&$system.Security.Check("%Admin_Operate","USE") pLinks($I(n)) = $LB($$$Text("View Background Tasks"),"/csp/sys/%25CSP.UI.Portal.BackgroundTaskList.zen","")

	Quit $$$OK
}

/// Provide any quick links for pages.
ClassMethod GetQuickLinks(Output pLinks) As %Status
{
	Set pLinks("Home") = ..#HOMEPAGE
	Quit $$$OK
}

/// Draw the HTML contents of the title area for portal pages.
/// pProduct may contain specific product logo if passed in as the second piece.
/// pContextMenu is passed in for CSP pages only!
ClassMethod %DrawTitleHTML(pProduct As %String, pTitle As %String, ByRef pSmallMenu, ByRef pLocatorMenu, ByRef pContextMenu) As %Status
{
	Set tProductLogo = $P(pProduct,"^",2)
	Set tProduct = $P(pProduct,"^",1)
	If tProductLogo = "" {
		Set tProductLogo = $$$LOGO1 			//"portal/InterSystems IRIS.png"
		If $System.Version.GetISCProduct() = $$$HealthShareProductKey {
			Set tProductLogo = $$$PRODUCT3LOGO	//"portal/HealthShareLogo210x50.png"
		} ElseIf (tProduct = "TrakCare") {
			Set tProductLogo = $$$PRODUCT4LOGO
		}
	}
	&html<<div class="topLine"></div>>
	&html<<div class="portalTitle">	
		<div class="portalLogoBox">
		<img class="portalLogo" src='#(tProductLogo)#' alt='#(tProduct)#'></img>
		</div>
		<div class="portalName">#($$$TextHTML("Management Portal"))#
		</div>
		>
		
	#; place holder for menus
	#; small menu for all:
	Do ..%DrawSmallMenu(.pSmallMenu, .pLocatorMenu)
	#; context menu for CSP pages:
	Set item = $O(pContextMenu(""))
	If item '= "" {
		&html<
		<div style="position:relative; top:0px; left:0px;">
		<div id="mainMenu" style="width:50px;">
		<div id="menuBar" class="csMenuBar">
		<div>
		<div id="menuName" class="csMenuBarItem" caption='#($$$TextHTML("Menu"))#' >
		<div id="menuHolder" class="contextMenu" >
		>
		While item '= "" {
			Set tCaption = $LG(pContextMenu(item),1)
			Set (tURL,tFinalURL) = $LG(pContextMenu(item),2)
			Set tFinalURL = ##class(%CSP.Page).Link(tURL)
			If tURL '= tFinalURL {
				Set tEsp = $P(tFinalURL,"?",2)
				Set tURL = $P(tFinalURL,"?")_"?"_$zconvert(tEsp,"O","JS")
			}
			If (tCaption = "") {
				&html<<div class="csMenuSeparator"></div>>
			} Else {
				&html<<div class="csMenuItem" onselect="self.document.location='#(tURL)#'" caption='#(tCaption)#'></div>>
			}
			Set item = $O(pContextMenu(item))
		}
		#; close contextMenu:
		&html<</div>>  //close menuHolder
		&html<</div>>  //close menuName
		&html<</div>>  //close div
		&html<</div>>  //close menuBar
		&html<</div>>  //close mainMenu
		&html<</div>>  //close parent div
	}
	&html<</div>>      // close portalTitle
	Do ..%DrawTitleServerHTML(pProduct, pTitle, .pSmallMenu, .pLocatorMenu)
	
	Do ..%DrawLocatorMenu(.pLocatorMenu)

	Quit $$$OK
}

/// This method draws the server/namespace/user/license/instance information inside the title pane.
/// pProduct may contain specific server name if passed in as the third piece (for HS debug purposes).
ClassMethod %DrawTitleServerHTML(pProduct As %String, pTitle As %String, ByRef pSmallMenu, ByRef pLocatorMenu) As %Status
{
	#; show which server we are connected to
	Set tInstance = $P($ZU(86),"*",2)
	Set tLicensedTo = $$DisplayName^%SYS.LICENSE
	Set tUserName = $UserName
	Set tServerName = $P(pProduct,"^",3)
	If tServerName = "" {
		Set tServerName = $zu(110)
	}
	Set msgInstance = $ZCVT($ZV,"O","HTML")
	#; Do not display "Switch" link if CanShowSwitch is false
	Set CanShowSwitch = ..CanShowSwitch(%request.PageName)
	
	&html<
	
	<div id="serverRow" class="portalTitleInfoBox">
		<span class="portalTitleInfoLabel" nowrap="1">#($$$TextHTML("Server"))#</span>
		<span class="portalTitleInfoVal" nowrap>#($ZCVT(tServerName,"O","HTML"))#&nbsp;</span>
		
		<span class="portalTitleInfoLabel" nowrap="1">#($$$TextHTML("Namespace"))#</span>>
		If CanShowSwitch {
			Set tSwitch = $$$TextHTML("Switch namespace")
			Set tCode = "zenPage.switchNamespace();"
			&html<<a class="portalServerLink" title="#(tSwitch)#" href="#" onclick="#(tCode)#return false;">#($namespace)#</a>&nbsp;&nbsp;>
		} else {
			&html<<span class="portalTitleInfoVal" nowrap>#($namespace)#&nbsp;&nbsp;</span>>
		}
		Do ..DrawUsername()
		Do ..DrawEscalationRole()
		&html<<span class="portalTitleInfoLabel" nowrap="1">#($$$TextHTML("Licensed To"))#</span>
		<span class="portalTitleInfoVal" nowrap>#($ZCVT(tLicensedTo,"O","HTML"))#&nbsp;</span>
		<span class="portalTitleInfoLabel" nowrap="1" title="#(msgInstance)#">#($$$TextHTML("Instance"))#</span>
		<span class="portalTitleInfoVal" nowrap>#($ZCVT(tInstance,"O","HTML"))#&nbsp;</span>
		<span class="portalLostConnectivityWarn" id="lostConnectivityWarn" nowrap hidden></span>>
	&html<</div>>  //close serverRow

	Quit $$$OK
}

ClassMethod DrawServerFlag()
{
	Set tSystemMode = $G(^%SYS("SystemMode"))
	Set tSystemStyle = "portalTitleServerFlag"
	Set tSystemMsg = ""
	If (tSystemMode = "LIVE") {
		Set tSystemMsg = $$$TextHTML("Live System")
		Set tSystemStyle = "portalTitleServerFlag portalTitleServerFlagLive"
	}
	ElseIf (tSystemMode = "TEST") {
		Set tSystemMsg = $$$TextHTML("Test System")
	}
	ElseIf (tSystemMode = "FAILOVER") {
		Set tSystemMsg = $$$TextHTML("Failover System")
	}
	ElseIf (tSystemMode = "DEVELOPMENT") {
		Set tSystemMsg = $$$TextHTML("Development System")
	}
	ElseIf (tSystemMode '= "") {
		// show value as a string
		Set tSystemMsg = $ZCVT(tSystemMode,"O","HTML")
	}
	If tSystemMsg '= "" {
		&html<<span id="portalServerFlag" class="#(tSystemStyle)#">#(tSystemMsg)#</span>>
	}
}

/// Draw username with (or without) link to change password. The link is built only for the Home page.
ClassMethod DrawUsername()
{
	Set msgUser = $$$TextHTML("User")
	Set hlpUser = $$$TextHTML("Name of user logged into this session")
	Set hlpLink = $$$TextHTML("Change password")
	Set tUserName = $Username
	Set tCode = "zenPage.changePassword();"
	Set IsHome = $Case(%request.PageName,"%CSP.Portal.Home.zen":1,"UtilHome.csp":1,:0)
	&html<<span class="portalTitleInfoLabel" title="#(hlpUser)#" nowrap="1">
	#(msgUser)#
	</span>
	<span class="portalTitleInfoVal" nowrap="1">>
	If IsHome {
		&html<<a class="portalServerLink" href="#" onclick="#(tCode)#return false;" title="#(hlpLink)#">#($ZCVT(tUserName,"O","HTML"))#</a>>
	} Else {
		&html<#($ZCVT(tUserName,"O","HTML"))#>
	}
	&html<&nbsp;</span>>
}

ClassMethod DrawEscalationRole()
{
	Set hlpRole = $$$TextHTML("Escalation Role")
	Set hlpLink = $$$TextHTML("Escalate Security Context")
	Set escRoleNone = $$$TextHTML("(none)")
	Set escRoleLogout = $$$TextHTML("Remove")
	Set hlpLogout = $$$TextHTML("Log out of the current escalated context")
	Set escRole = $System.Context.Security().EscalationRole
	Set IsHome = $Case(%request.PageName,"%CSP.Portal.Home.zen":1,"UtilHome.csp":1,:0)
	If (escRole'="") || ($$GetEscalationRoles^%SYS.SECURITY'="") {
		&html<<span class="portalTitleInfoLabel" title="#(hlpRole)#" nowrap="1">#(hlpRole)#</span>
		<span class="portalTitleInfoVal" nowrap="1">>
		If IsHome {
			&html<<a class="portalServerLink" href="#" onclick="zenPage.escalateLogin(); return false;" title="#(hlpLink)#">#($select(escRole'="":escRole, 1:escRoleNone))#</a>>
			If escRole'="" &html<&nbsp;(<a href="#" onclick="zenPage.clearEscalation(); return false;" title="#(hlpLogout)#">#(escRoleLogout)#</a>)>
		} Else {
			&html<#($select(escRole'="":escRole, 1:escRoleNone))#>
		}
		&html<&nbsp;</span>>
	}
}

/// Draw small menu at the top of the title area.
ClassMethod %DrawSmallMenu(ByRef pMenu As %String, ByRef pLocatorMenu As %String)
{
	// pMenu takes the form:
	// pMenu(1) = $LB("Caption","title","script")
	&html<<div id="portalTitleMenuBox" class="portalTitleMenuBox">>
	&html<<img height="1px" width="32px" src="images/spacer.gif"/>>
	Do ..DrawServerFlag()
	Set tCount = 0
	Set n = $O(pMenu(""))
	While (n '= "") {
		If (tCount > 0) {
			&html<<span>&nbsp;&nbsp;&nbsp;</span>>
		}
		Set tCount = tCount + 1
		Set tCaption = $LG(pMenu(n),1)
		Set tTitle = $LG(pMenu(n),2)
		Set tCode = $LG(pMenu(n),3)
		&html<<a class="portalTitleLink" title="#(tTitle)#" href="#" onclick="#(tCode)#">#($ZCVT(tCaption,"O","HTML"))#</a>>
		Set n = $O(pMenu(n))
	}
	&html<<img height="1px" width="32px" src="images/spacer.gif"/>>
	&html<</div>>
}

/// Draw bread-crumb links
ClassMethod %DrawLocatorMenu(ByRef pLocatorMenu As %String)
{
	Set tCount = 0
	Set n = $O(pLocatorMenu(""))
	#; if this is on the home page, don't display the Home locator link.
	If n '= "",$O(pLocatorMenu(n)) '= "" {
			&html<<div id="locatorRow">>
		While (n '= "") {
			If (tCount > 0) {
				&html<<span>&gt;</span>>
			} Else {
				&html<<span>&nbsp;&nbsp;&nbsp;&nbsp;</span>>
			}
			Set tCount = tCount + 1
			Set tCaption = $LG(pLocatorMenu(n),1)
			Set tCode = $LG(pLocatorMenu(n),2)
			// remove possible isGoHome in case it came in from the %request.Context
			Set tCode = $P(tCode,"&isGoHome=1",1)_$P(tCode,"&isGoHome=1",2)
			Set tCode = $ZCVT(tCode,"O","HTML")
			&html<<a class="portalServerLink portalLocatorLink" href="#(tCode)#">#($ZCVT(tCaption,"O","HTML"))#</a>>
			Set n = $O(pLocatorMenu(n))
		}
		&html<<span id="pageTitleDisplay" hidden="true">&nbsp;-&nbsp;<span class="pageTitleText"><span id="pageTitleText">&nbsp;</span><span id="modifiedIndicator">&nbsp;</span></span></span>>
		&html<</div>>
	}
}

/// Get the product name for the page. May be called from none-Zen classes in SMP.
ClassMethod %OnGetProductName() As %String
{
	// Test for product
	If (##class(%Library.EnsembleMgr).IsHealthShareInstalled()) {
		Quit "HealthShare"
	}
	ElseIf (##class(%Library.EnsembleMgr).IsEnsembleInstalled()) {
		Quit "Ensemble"
	} 
	ElseIf $E($G(%request.Data("home",1)),1,7) = "DEEPSEE" {
		Quit "DeepSee"
	}	
	Quit "IRIS"
}

/// Checks to see if Interoperability is enabled in any accessible namespace
ClassMethod EnsembleLoaded() As %Integer [ Internal ]
{
	// This replicates the check in %Library.EnsembleMgr
	// without the restriction of checking to see if it
	// is enabled in the current namespace
	Quit:($DATA(^%SYS("Ensemble")) > 0) 1
	
    // test for faking it
    Quit:($DATA(^DocBook.Config("EnsembleLoaded")) > 0) $GET(^DocBook.Config("EnsembleLoaded"), 0)
    
    // nope
    Quit 0
}

/// Checks to see if HealthShare is loaded in any accessible namespace
ClassMethod HealthShareLoaded() As %Integer [ Internal ]
{
	// This replicates the check in %Library.EnsembleMgr
	// without the restriction of checking to see if it
	// is enabled in the current namespace
	Quit:($DATA(^%SYS("HealthShare")) > 0) 1
	
    // test for faking it
    Quit:($DATA(^DocBook.Config("HealthShareLoaded")) > 0) $GET(^DocBook.Config("HealthShareLoaded"), 0)
    
    // nope
    Quit 0
}

/// Determine if the "Switch" link for namespace can be shown. Return 1 if yes, and 0 if not.
ClassMethod CanShowSwitch(PageName) As %Boolean
{
	Try {
		Set CanShowSwitch = 0
		/// If user logged in without any role, cannot use switch namespace
		If $Roles = "" Quit
		/// Do not display "Switch" link for most SMP options. Show only Tools and iKnow under /csp/sys/exp/
		Set WebApp = $system.CSP.GetPortalApp("%SYS",PageName)
		If ($E(PageName,1,4)="Util") || (WebApp = "/csp/sys/sec/") || (WebApp = "/csp/sys/mgr/") || ((WebApp = "/csp/sys/op/")&&(PageName'["SQL.Logs"))  Quit
		If $E(PageName,1,14) = "%CSP.UI.Portal",PageName'["SQL.",PageName'["iKnow" Quit
		If PageName [ "HS." Quit
		/// Check security for namespace dialog
  		Set Resources = $G(^oddDEF("%ZEN.Dialog.namespaceSelect","p","RESOURCE",22))
  		If Resources = "" Quit
  		/// If user has at least one of the resources, then we can show. Otherwise we cannot.
  		For n = 1:1:$L(Resources,",") Set r = $P(Resources,",",n) If r'="",$System.Security.Check(r,"USE") Set CanShowSwitch = 1 Quit
 	} Catch errobj {
	 	/// most likely it's <PROTECT>
	 	///s ^IRIS.Temp("error")=errobj.Name_"^"_errobj.Code_"^"_errobj.Location_"^"_errobj.Data
  		Set CanShowSwitch = 0
 	}
 	Quit CanShowSwitch
}

}
