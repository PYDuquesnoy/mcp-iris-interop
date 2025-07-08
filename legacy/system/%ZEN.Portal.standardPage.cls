/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%sqlui, %sySystem, %products)

/// This base class provides a standard template for portal pages
/// implemented using Zen.
Class %ZEN.Portal.standardPage Extends (%ZEN.Component.page, %ZEN.Portal.abstractRefreshable) [ Abstract, Deprecated, System = 4 ]
{

Parameter JSINCLUDES = "zenMenusSMP.js";

/// Set this to the appropriate application class.
Parameter APPLICATION = "%ZEN.Portal.Application";

/// SMP favorite icon.
Parameter FAVORITEICON As COSEXPRESSION = "$$$ISCFAVORITEICON";

/// If true, auto-switch namespace to whatever $NAMESPACE is passed in.
Parameter AUTONS As BOOLEAN = 1;

/// Set this to the correct domain.
Parameter DOMAIN = "%Utility";

/// Name of this page.
Parameter PAGENAME = "Standard Portal Page";

/// URL of home page (used in links by many pages via <property>homePage</property>.)
Parameter HOMEPAGE = "/csp/sys/%25CSP.Portal.Home.zen";

/// If true, register visits to this page in the recent list.
Parameter RECENT As BOOLEAN = 1;

/// If true, show the Namespace dropdown.
Parameter SHOWNAMESPACE As BOOLEAN = 1;

/// If this page has multiple views, this is its initial display mode.
Parameter DEFAULTVIEWMODE = "columns";

/// If this page has sort options, this is its initial sort mode.
Parameter DEFAULTSORTMODE = "name";

/// Allow pages to have iframes by not setting x-frame-options: same origin. 
/// Set default for Management Portal as iframes are not allowed.
Parameter IFRAMEALLOWED As BOOLEAN = 0;

/// Include the session Language in the html "lang" attribute. 
Parameter USESESSIONLANG As BOOLEAN = 1;

/// Define the title that will be displayed within subclasses
Property StdTitle As %ZEN.Datatype.string [ InitialExpression = {$P($ZU(86),"*",2) _" - "_..#PAGENAME} ];

/// Product home page URL.
/// Note that multiple portal pages rely on this being a fully formed link.
Property homePage As %ZEN.Datatype.string [ InitialExpression = {..Link(..#HOMEPAGE,,1)_$select('$data(%response.Context("$NAMESPACE")): "$NAMESPACE="_$zcvt($namespace,"O","URL"), 1: "")} ];

/// About page URL
Property aboutPage As %ZEN.Datatype.string [ InitialExpression = {..Link("_CSP.UI.Portal.About.zen")} ];

Property contactPage As %ZEN.Datatype.string [ InitialExpression = {..Link("/csp/sys/%25CSP.UI.Portal.Contact.cls")} ];

/// For pages with steps, this is the current step (1-based).
Property currStep As %ZEN.Datatype.integer [ InitialExpression = 1 ];

/// If this page has "views", this is the current view type.
Property currViewMode As %ZEN.Datatype.string [ InitialExpression = {..#DEFAULTVIEWMODE} ];

/// Current sort mode for this page (if applicable).
Property currSortMode As %ZEN.Datatype.string [ InitialExpression = {..#DEFAULTSORTMODE} ];

/// Current search key value (if applicable).
Property searchKey As %ZEN.Datatype.string;

/// True if the contents of this page need to be saved.
Property pageModified As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Set to true to suppress hyperevent error pop-ups in
/// the event of a connectitivity failure.
Property limitPopups As %ZEN.Datatype.boolean [ InitialExpression = {##class(%CSP.Portal.Utils).%IsConnectivityPopupDisabled()} ];

XData Style
{
<style type="text/css">
body {
	background: #ffffff;
	font-family: Futura,Arial,sans-serif;
}
/* tool ribbon */
.toolRibbon {
	height: 48px;
	background: white;
	float: left;
	vertical-align: middle;
}
.toolRibbonEnd {
	border: 1px solid #f0f0f0;
	width: calc(100% - 2px); /* the second value MUST be equal to the value of the left border width + right border width */
}
/* dark green and bold for ribbon title */
.ribbonTitle {
	color:#00AFA9;
	font-family: Futura,Arial,sans-serif;
	font-size:36px;
	text-align:left;
}

.ribbonLabel {
	vertical-align: middle;
	font-weight: bold;
	font-size: 10pt;
}

.ribbonSortOption:hover,.ribbonSortOptionSelected:hover {
	color: darkred;
}

.ribbonSortOption {
	text-decoration: none;
	color: #5ba4dc;
	font-weight: normal;
}

.ribbonSortOptionSelected {
	text-decoration: none;
	color: #404040;
	background: #FFEEAA;
	font-weight: normal;
}

.viewIconBar {
	vertical-align: bottom;
}

.viewIcon,.viewIconSelected,.viewIconDis,.viewIconHover {
	vertical-align: bottom;
	border: 2px solid white;
	hight: 34px;
	width: 34px;
}

.viewIconSelected {
	border-radius: 2px;
	border: 3px solid #000000;
}

.viewIconHover {
	background: #BFE4E3;
	cursor:pointer;
}

/* Menu Bar */
.csMenuBar {
	 display:block;
	 position:absolute;
	 top:2px;
	 right:1px;
     border:2px solid #333695;
     border-radius:4px;
     color:#333695;
     height:42px;
     width:83px;
	 letter-spacing:0.75px;
	 text-align:center;
}

.csMenuBar-active {
	background:#333695;
}

.csMenuBar-static {
	background:white;
}

.csMenuBarText-active {
	color:white;
}

.csMenuBarText-static {
	color:#333695;
}

.csMenuBarItem {
	background:white;
    cursor:pointer;
    color:#333695;
    font-size:12px;
    font-weight:bold;
    font-family:Futura,Arial,sans-serif;
	letter-spacing:0.75px;
}

.csMenuItem {
	font-family:Futura,Arial,sans-serif;
}

.csActiveMenuItem {
	background: #bfe4e3;
	color: #404040;
}

.shadow {
    background: none;
}

/* Search Box */
#searchDiv {
	position: absolute;
	top: 117px;
	right: 30px;
}

.search-icon {
	width: 22px;
	vertical-align: bottom;
	cursor: pointer;
}

/* @doc="Override ZEN components' default style" */
/* @doc="Text button in combobox." */
.comboboxItem {
	font-size: 12px;
}
.comboboxTextButton {
	vertical-align: middle;
	font-size: 0.75em;
	border: 1px solid #cbcbcb;
	height: 100%;
	background: #404040;
	background-image: none;
}

.comboboxTextButton:hover {
	background: #404000;
	background-image: none;
}

/* @doc="Table displaying combobox dropdown contents." */
/* comboBox */
/* @doc="Headers within combobox dropdown list." */
.comboboxItemSelected {
	width: 100%;
	color: #000000;
	background: #bfe4e3;
	background-image: none;
	border: 1px solid #cbcbcb;
	cursor: pointer;
}

/* @doc="Style for loading message within combobox dropdown." */
.comboboxLoading {
	font-style: italic;
	color: #333695;
}
.comboboxTable th {
	white-space: nowrap;
	padding-right: 3px;
	padding-bottom: 2px;
	font-weight: bold;
	text-align: left;
	border-bottom: 1px solid #cbcbcb;
	background: #ffffff;
	background-image: none;
}
/* listBox */
.listBox {
	font-size: 12px;
	color: #000000;
	background: white;
	border: 1px #cbcbcb solid;
}

/* @doc="Item within listBox." */
.listBoxItem {
	white-space: nowrap;
	width: 100%;
	color: #000000;
	cursor: pointer;
	padding: 1px;
}
/* @doc="Mouse hover over item within combobox dropdown." */
.comboboxItem a:hover {
	color: #000000;
	background: #f7f7f7;
	border: 1px solid #cbcbcb;
}
/* @doc="Selected item within listBox." */
.listBoxItemSelected {
	white-space: nowrap;
	width: 100%;
	color: #000000;
	background: #bfe4e3;
	font-weight: bold;
	cursor: pointer;
	padding: 1px;
}

/* @doc="Selected item with focus within listBox." */
.listBoxItemFocus {
	white-space: nowrap;
	width: 100%;
	font-weight: bold;
	color: #000000;
	background: #bfe4e3;
	background-image: none;
	border: 1px solid #cbcbcb;
	cursor: pointer;
	padding: 1px;
}
.listBoxItem:hover, .listBoxItemSelected:hover, .listBoxItemFocus:hover {
	color: #000000;
	background: #f7f7f7;
}
table.tpTable tr.tpSelected {
	background: #bfe4e3;	
}
</style>
}

/// Contents of this page:
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" 
	xmlns:deepsee="http://www.intersystems.com/deepsee" 
	title="#(%page.StdTitle)#"
	dropEnabled="true"
	dragAndDrop="true">
<group layout="none" containerStyle="position:relative; top:0px; left:0px">
<html id="title" OnDrawContent="DrawTitle"/>
<group layout="none" enclosingStyle="position:absolute; top:19px; right:40px">
<csMenuBar id="mainMenu" width="50px">
<csMenuBarItem caption="Menu">
<contextMenu id="menuHolder">
<!--<csMenuItem id="newDashboard" caption="New Dashboard" onclick="zenPage.newDashboard();" />
<csMenuItem id="analyzer" caption="Analyzer" onclick="zenPage.gotoAnalyzer();" />
-->
</contextMenu>
</csMenuBarItem>
</csMenuBar>
</group>

</group>

<html id="toolRibbon" OnDrawContent="DrawRibbon"/>

<vgroup width="100%" valign="top">
<pane paneName="contentPane" width="100%"/>
</vgroup>

</page>
}

/// Draw the contents of the title area.
/// Dispatch to application class.
Method DrawTitle(pSeed As %String) As %Status [ Final ]
{
	Set tSC = $$$OK

	If +$G(%request.Data("STUDIO",1)) {
		// Studio mode-- no title bar or menu

		Set tMenu = ..%GetComponentById("mainMenu")
		If (tMenu) {
			Set tMenu.hidden = 1
		}
		Quit tSC
	}
	
	Try {
		If $IsObject($G(%application)) {
			i $ZS<$$$MAXBBSZ { d $ZU(163,$$$MAXBBSZ) }
			Set tTitle = ..%OnGetTitle()
			Do ..%GetLocatorLinks(.tLocatorMenu)
			
			Set tProduct = ..%OnGetProductName()
			Do ..%OnGetSmallMenu(.tSmallMenu)
			
			Set tSC = %application.%DrawTitleHTML(tProduct,tTitle,.tSmallMenu,.tLocatorMenu)
		} Else {
			&html<No Application Defined for Page!>
		}
	} Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This method rebuilds context menu on the top left corner.
Method BuildMenu() As %Status
{
	Set tSC = ..GetContextLinks(.tLinks)
	If $$$ISOK(tSC) {
		Set menuHolder = ..%GetComponentById("menuHolder")
		If $IsObject(menuHolder) {
			Set item = $O(tLinks(""))
	 		While (item'="") {		
				Set tCaption = $LG(tLinks(item),1)
				Set tURL = $LG(tLinks(item),2)
				Set tJS = $LG(tLinks(item),3)
				If (tCaption = "") {
					// menu separator
					Set tOption = ##class(%ZEN.Component.csMenuSeparator).%New()
				} Else {
					Set tOption = ##class(%ZEN.Component.csMenuItem).%New()
					Do %page.%AddComponent(tOption)
					Set tOption.caption = tCaption
	                If (tJS'="") {
	                   Set tOption.onclick = tJS
	                }
	                Else {
	                	// make a link
	                	If tURL '= "" {
		                	Set tLink = ##class(%CSP.Page).Link(tURL)
		                	Set tEsp = $P(tLink,"?",2)
		                	If tEsp '= "" {
								Set tLink = $P(tLink,"?")_"?"_$zconvert(tEsp,"O","JS")
							}
		                	Set tOption.onclick = "zenPage.goMenu('"_tLink_"');"
	                	}
	                }
				}
				Do menuHolder.%AddChild(tOption)
		 		Set item = $O(tLinks(item))
	 		}
		}
	}
	Quit tSC
}

/// Define any context links for the page. Sub-class to override.
/// Note that the subclass should call <method>CheckContextLinks</method> to
/// ensure that the user is actually permitted to access all of the links - the pages
/// may have custom resources defined that would prevent the user from seeing the page.
ClassMethod GetContextLinks(Output pLinks) As %Status
{
	Set tSC = $$$OK
	If $IsObject($G(%application)) {
		Set tSC = %application.GetContextLinks(.pLinks)
		If $$$ISERR(tSC) Quit tSC
		Set tSC = ..CheckContextLinks(.pLinks)
		If $$$ISERR(tSC) Quit tSC
	}
	Quit tSC
}

/// Helper method to ensure that the user has sufficient privileges to access the links
/// returned in <method>GetContextLinks</method>. This is especially important for cases where 
/// system administrators have specified custom resources for pages in the portal, as we
/// need to check the custom resources before adding the option to the context menu.
ClassMethod CheckContextLinks(ByRef pLinks) As %Status
{
	Set tItem = ""
	For {
		Set tItem = $order(pLinks(tItem),1,tItemData)
		Quit:(tItem = "")
		Set tLink = $listget(tItemData,2)
		If (tLink = "") && ($listget(tItemData,1) = "") {
			Set tPrevSpacer = ($order(pLinks(tItem),-1,tPrevItem) '= "") && ($listget(tPrevItem,1) = "")
			#; remove the item if it's a spacer and there is nothing before it or after it, or it follows a spacer.
			If tPrevSpacer || ($order(pLinks(tItem),-1) = "") || ($order(pLinks(tItem),1) = "") {
				Kill pLinks(tItem)
			}
		}
		ElseIf tLink '= "" {
			Set tAccess = ##class(%CSP.Portal.Utils).CheckLinkAccess(tLink)
			If $case(tAccess, $$$caNotCSPLink: 0, $$$caCanAccessRes: 0, $$$caUnknownTarget: 0, :1) Kill pLinks(tItem)
		}		
	}
	#; remove the last item if it's a spacer; this catches the case where the items after a spacer are removed 
	If ($order(pLinks(""),-1,tLastItem) '= "") && ($listget(tLastItem,1) = "") Kill pLinks($order(pLinks(""),-1))
	Quit $$$OK
}

/// Define any quick links for the page
ClassMethod GetQuickLinks(Output pLinks) As %Status
{
	Set tSC = $$$OK
	If $IsObject($G(%application)) {
		Set tSC = %application.GetQuickLinks(.pLinks)
	}
	Quit tSC
}

/// Register this visit to the recent items list.
Method %Register() As %Status
{
	Set tSC = $$$OK
	#; register visit
	If (..#RECENT) {
		Set tURL = $ZCVT(%request.URL,"O","URL")
		Try {
			// Swallow error if method not defined
			Set tSC = ##class(%CSP.Portal.Utils).%RegisterRecentItem(..%OnGetPageName(),tURL)
		}
		Catch(ex) {
		}
	}
	Quit tSC
}

Method CheckEnterpriseManager() As %Status
{
	#; If on the EMS manager, Portal pages should redirect to EMS Home.
	#; Note that %OnAfterCreatePage() is overridden in %CSP.UI.Portal.Template so that
	#; SMP pages can be used in the group context.
	;If ##class(%SYS.EMS).IsEMSManagerSMP() {
	;	Set %response.Redirect = ..Link("/csp/ems/Manager.UI.Home.zen")
	;	Quit 1
	;}
	Quit 0
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	
	If ..CheckEnterpriseManager() Quit 1
	
	#; register visit
	Set tSC = ..%Register()
	If $$$ISERR(tSC) Quit tSC
	
	#; The BuildMenu may be called from subclasses, if %OnAfterCreatePage is overriden.
	Set tSC = ..BuildMenu()

	Quit tSC
}

/// Use soft modals for the portal.
ClassMethod %OnUseSoftModals() As %Boolean [ CodeMode = expression ]
{
1
}

Method %OnDrawHTMLMeta() As %Status
{
   	//Ensure that we force Internet Explorer to use its most recent rendering engine.	
	If $$$ZENISIE &html<<meta http-equiv="X-UA-Compatible" content="IE=edge" />>
	Quit $$$OK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
/// Sub-class can override to include extra levels.
Method %GetLocatorLinks(Output pLink) As %Status
{
	
	If $IsObject($G(%application)) {
		Set tSC = %application.GetQuickLinks(.pLinks)
		If $$$ISOK(tSC) {
			Set tPageName = %application.%OnGetProductName()
			Set tURL = pLinks("Home")_"?home="_$G(%request.Data("home",1))
			Set pLink($I(pLink)) = $LB(tPageName,..Link(tURL))
		}
	}
	
	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,..Link($ZCVT(..%ClassName(1),"O","URL")_".zen?home="_$G(%request.Data("home",1))))
	Quit $$$OK
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit "Title"
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit "PageName"
}

/// Get the product name for the page.
Method %OnGetProductName() As %String
{
	If $IsObject($G(%application)) {
		Quit %application.%OnGetProductName()
	}
	Quit "InterSystems"
}

/// Get the contents of the small menu in the title area.
Method %OnGetSmallMenu(Output pMenu)
{
	// $LB(caption,title,script)
	Set pMenu(1) = $LB($$$TextHTML("Home"),$$$TextHTML("Go to the Home page"),"return zenPage.goHome();")
	Set pMenu(2) = $LB($$$TextHTML("About"),$$$TextHTML("Display the About page"),"return zenPage.showAbout();")
	Set pMenu(3) = $LB($$$TextHTML("Help"),$$$TextHTML("Display help for this page"),"return zenPage.showHelp();")
	Set pMenu(4) = $LB($$$TextHTML("Contact"),$$$TextHTML("Contact InterSystems Worldwide Response Center"),"return zenPage.showContact();")
	Set pMenu(5) = $LB($$$TextHTML("Logout"),$$$TextHTML("End this session"),"return zenPage.logout();")
}

/// Draw additional content in the locator bar.
Method DrawLocator(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		// show the namespace selector
		If (..#SHOWNAMESPACE) {
			Set tNSCount = ..%GetAllNamespaces(.tNSList)

			Set tMsgNS = $$$Text("Namespace","%ZEN")
			Set tHelpNS = $$$Text("Change to a different namespace","%ZEN")
			&html<<span title="#(tHelpNS)#">#(tMsgNS)#:>
			&html<<select onchange="zenPage.gotoNamespace(this.value);">>
			Set defaultNS = $namespace
			#;YSD2618 Set tURL = $system.CSP.GetDefaultApp(defaultNS) _ "/" _ %request.PageName
			Set tURL = $system.CSP.GetPortalApp(defaultNS,%request.PageName) _ %request.PageName
			Set tQuery("CSPSHARE") = 1
			Set tURL = ##class(%CSP.Page).Link(tURL,.tQuery)
			Set CSPCHD = $P(tURL,"CSPCHD=",2)
			For n=1:1:tNSCount {
				Set tNS = $G(tNSList(n))
				If (tNS '= "") {
					#;YSD2618 Set tURL = $system.CSP.GetDefaultApp(tNS) _ "/" _ %request.PageName
					Set tURL = $system.CSP.GetPortalApp(defaultNS,%request.PageName) _ %request.PageName
					Set tURL = ##class(%CSP.Page).Link(tURL,.tQuery)
					Set CSPCHD = $P(tURL,"CSPCHD=",2)
					Set tURL = $ZCVT($P(tURL,"?CSPSHARE=1",1),"O","URL")_"?CSPCHD="_CSPCHD_"&CSPSHARE=1"
					Set tSel = $S($namespace=tNS:"selected=""1""",1:"")
					&html<<option #(tSel)# value="#(tURL)#">#(tNS)#</option>>
				}
			}
			&html<</select>>
			&html<</span>>

		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Generic method to get namespaces from the ACTIVE Configuration file.<br>
/// Namespace array is returned by reference.<br>
/// Namespaces that have database dismounted, or Status = 0, are not included.<br>
/// Remote namespaces are included assuming they are active.<br>
ClassMethod %GetAllNamespaces(ByRef pNamespaces As %String) As %Integer [ Internal ]
{
	Set Type = 1   		// 1 - Returns array of namespaces the user has Read or Write privileges in, including SQL privileges
	Set Remote = 0 		// 1 - Return remote namespaces as well
	Set DontConnect = 1	// 1 - Do not attempt to connect 
	
	Do List^%SYS.NAMESPACE(.NspList,Type,Remote,DontConnect)
	Set cnt = 0,ns=""
	For {
		Set ns=$o(NspList(ns)) Quit:ns=""
		Set cnt=cnt+1,pNamespaces(cnt)=ns
	}
	Quit cnt
}

/// Draw the contents of the tool ribbon.
/// This is displayed if a subclass implements the <method>OnGetRibbonInfo</method> callback.
Method DrawRibbon(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tDisplay = 0
		Set tSearchBox = 0
		Set tRibbonTitle = ""
		Set tSC = ..OnGetRibbonInfo(.tDisplay,.tViewIcons,.tSortOptions,.tSearchBox,.tRibbonTitle,.tCommands)
		If $$$ISERR(tSC) Quit

		If ('tDisplay) Quit
	
		&html<<div class="toolRibbon">>
		&html<<table border="0" cellspacing="0" cellpadding="0" style="height:48px;width:100%;"><tr>>

		If (tRibbonTitle '= "") {
			&html<<td width="25%" class="ribbonTitle">&nbsp;&nbsp;<nobr>#(tRibbonTitle)#</nobr>&nbsp;&nbsp;</td>>
		}

		// commands
		If ($D(tCommands)) {
			If ($D(tViewIcons)) {
				&html<<td width="10%">&nbsp;</td>>
			}
			&html<<td align="left" nowrap="1">>
			Set n = $O(tCommands(""))
			While (n'="") {
				Set tID = $LG(tCommands(n),1)
				Set tCaption = $LG(tCommands(n),2)
				Set tTitle = $LG(tCommands(n),3)
				Set tOnClick = $LG(tCommands(n),4)
				Set tHidden = $S($LG(tCommands(n),5):"visibility:hidden;",1:"")
				// n.b. set line-height because of ie! 
				&html<<a id="command_#(tID)#" style="line-height:27px;#(tHidden)#" class="commandButton" href="#" onclick="#(tOnClick)#return false;" title="#(tTitle)#"><nobr>#(tCaption)#</nobr></a>&nbsp;&nbsp;>
				Set n = $O(tCommands(n))
			}
			&html<</td>>
		}

		Set tSC = ..OnDrawRibbon()
		If $$$ISERR(tSC) Quit

		// sort
		If ($D(tSortOptions)) {
			&html<<td style="width:80px;">&nbsp;</td>>
			&html<<td class="ribbonLabel" nowrap="1">#($$$Text("Sort:","%Utility"))#&nbsp;>
			Set n = $O(tSortOptions(""))
			While (n '= "") {
				Set tID = $LG(tSortOptions(n),1)
				Set tText = $LG(tSortOptions(n),2)
				Set tTitle = $LG(tSortOptions(n),3)
				Set tCls = $S(tID=..currSortMode:"ribbonSortOptionSelected",1:"ribbonSortOption")
				&html<&nbsp;<a id="sort_#(tID)#" title="#(tTitle)#" class="#(tCls)#" href="#" onclick="zenPage.setSortMode('#(tID)#');return false;">&nbsp;#(tText)#&nbsp;</a>&nbsp;>
				Set n = $O(tSortOptions(n))
			}
			&html<</td>>
		}
		
		#; icons

		If ($D(tViewIcons)) {
			// view
			Set tTitle = $$$Text("Choose how options should be displayed","%Utility")
			&html<<td style="width:40px;">&nbsp;</td>>
			&html<<td class="ribbonLabel" width="1%" title="#(tTitle)#" nowrap>#($$$Text("View:","%Utility"))#&nbsp;</td>>

			&html<<td nowrap="1">
			<div class="viewIconBar">>
			Set n = $O(tViewIcons(""))
			While (n'="") {
				Set tID = $LG(tViewIcons(n),1)
				Set tHelp = $LG(tViewIcons(n),2)
				Set tIcon = $LG(tViewIcons(n),3)
				// use mouse events so that hover works on ie
				&html<<img id="view_#(tID)#" class="#($S(..currViewMode=tID:"viewIconSelected",1:"viewIcon"))#" title="#(tHelp)#" src="#(tIcon)#" onclick="zenPage.setViewMode('#(tID)#');" onmouseover="this._oldClass=this.className;this.className='viewIconHover';" onmouseout="this.className=this._oldClass;" />>
				Set n = $O(tViewIcons(n))
			}
			&html<</div></td>>
		}
		Else {
			&html<<td style="width:40px;">&nbsp;</td>>
		}

		If (tSearchBox) {
			// Search
			// IE doesn't support event.relatedTarget, setTimeout on blur events to get the source target.
			&html<<td nowrap="1"><div id="searchDiv"><input id="searchBox" type="text" size="12" placeholder="Search" onkeypress="zenPage.searchKeyPress(event);" onkeydown="return zenPage.searchKeyDown(event);" onblur="setTimeout(function(){zenPage.searchBlur(event);},200);"/><img id="search-icon-glass" class="search-icon" alt="" onclick="zenPage.searchBoxHandler(document.getElementById('searchBox').value);" src="#(..Link("images/icon-search.png"))#"/></div></td>>
		}

		&html<</tr></table>>
		&html<</div>>
		/// the next line enables us to display the horizontal line below the ribbon bar across the table width 
		/// which could be wider and require horizontal scroll. We seperated this from the toolsRibbon because 
		/// we want the command buttons for the toolsRibbon bar to show on the left, and not float to the right when table becomes too wide.
		&html<</tr><tr><td colspan="50"><div class="toolRibbonEnd"></td></tr>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// This callback, if implemented returns information used to display
/// the standard ribbon bar.<br/>
/// <var>pDisplay</var> is true if the ribbon should be displayed.<br/>
/// <var>pViewIcons</var> is an array describing "view" buttons to display:
/// pViewIcons(n) = $LB(id,help,icon)<br/>
/// <var>pSortOptions</var> is an array describing "sort" options to display:
/// pSortOptions(n) = $LB(id,caption,help)<br/>
/// <var>pSearch</var> is true if a search box is displayed.<br/>
/// <var>pRibbonTitle</var> is a title to display.<br/>
/// <var>pCommands</var> is an array of command buttons to display:
/// pCommands(n) = $LB(id,caption,help,onclick)
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Quit $$$OK
}

/// This is called in the middle of rendering the tool ribbon.
/// Subclasses can inject their own content into the ribbon by writing it out in this method.
/// This content is best wrapped within a single td element.
/// It can also consist of multiple td elements.
/// <p>
/// To achieve a fixed position for elements within the ribbon, for a fixed width page you can 
/// use a single enclosing td that contains a table and a single tr, 
/// with td elements inside that single tr that contain your content for the ribbon.
/// <p>
/// To achieve a fixed position for elements within the ribbon, 
/// for a page whose width varies depending on its contents (thereby stretching the ribbon)
/// you can use multiple td elements to contain your content and then a final
/// td element that is empty and has width 40% (or so) to push your contents towards the left
/// and keep them in their proper locations.
Method OnDrawRibbon() As %Status
{
	Quit $$$OK
}

/// Custom handler for hyperEvent handlers to be (optionally) less 
/// intrusive if the cause of the error was an auto-refresh timer
/// losing commectivity with the host.
ClientMethod onServerMethodError(err, errObject) [ Language = javascript ]
{
	var doAlert = true;
	if (errObject) {
		var code = errObject.code;
		var serverCode = errObject.serverCode;
		if ((code == 401) && ((serverCode == 864) || (serverCode == 5918))) {
			self.document.location.reload();
			doAlert = false;
		}
		else if ((zenPage.limitPopups)&&(code<401)) { // check to see if this was refresh timer related
			var refreshRate = self.document.getElementById('refreshRate').value;
			if (refreshRate) { //page has defined refresh rate
				if ((document.getElementById("refreshOn"))&&(document.getElementById("refreshOn").checked)) {
					zenPage.setConnectivityStatusMsg(err);
					window.setTimeout('zenPage.setConnectivityStatusMsg("Re-trying");',parseInt(refreshRate*1000));
					window.setTimeout('zenPage.testConnectivity();',parseInt(refreshRate*1000));
					doAlert = false;
				}
			}
		}
	}
	if (doAlert) {
		alert(err);
	}
	return true;
}

ClientMethod testConnectivity() [ Internal, Language = javascript ]
{
	var img = new Image();
	img.onload = function () {
		self.document.location.reload();
	};
	img.onerror = function (e) {
		zenPage.onServerMethodError("Server not responding", {code:0})
	};
	img.src = document.location.origin+'/csp/broker/images/cut.png?rnd='+Math.random();
}

ClientMethod setConnectivityStatusMsg(msg) [ Language = javascript ]
{
	var span = document.getElementById('lostConnectivityWarn');
	if (span) {
		if (msg!='') {
			span.title = msg;
			span.innerHTML = $$$Text("No Connection");
			span.hidden = false;
		} else {
			span.title='';
			span.innerHTML='';
			span.hidden = true;
		}
	}
}

/// Go to the home page.
ClientMethod goHome() [ Language = javascript ]
{
	zenPage.gotoPage(this.homePage);
	return false;
}

/// Go to the menu link.
ClientMethod goMenu(link) [ Language = javascript ]
{
	zenPage.gotoPage(link);
	return false;
}

/// Go to the about page.
ClientMethod showAbout() [ Language = javascript ]
{
	zenPage.gotoPage(this.aboutPage);
	return false;
}

/// Go to the about page.
ClientMethod showContact() [ Language = javascript ]
{
	zenPage.gotoPage(this.contactPage);
	return false;
}

/// Show documentation.
ClientMethod showHelp() [ Language = javascript ]
{
	var url = this.GetDocURL(this.HelpAddress || "Home");
	var wid = self.screen.width;
	var hgt = self.screen.height;
	if (parseInt(navigator.appVersion)>3) {
		if (navigator.appName == "Netscape") {
			wid = window.innerWidth;
			hgt = window.innerHeight;
		}
		if (navigator.appName.indexOf("Microsoft") != -1) {
	 		wid = document.body.offsetWidth;
	 		hgt = document.body.offsetHeight;
		}
	}
	wid = wid * 0.8;
	hgt = hgt * 0.8;
	var top = self.screen.height * 0.1;
	var left = self.screen.width * 0.1;
	//YSD2331 zenLaunchPopupWindow(url,'Help Window','left='+left+',top='+top+',width='+wid+',height='+hgt+',status,scrollbars,resizable,location=1,toolbar=1,menubar=1,modal=no');
	var features = 'left='+left+',top='+top+',width='+wid+',height='+hgt+',status,scrollbars,resizable,location=1,toolbar=1,menubar=1';
	var popup = window.open(url,'HelpWindow',features);
	popup.focus();
	return false;
}

/// This client method, if defined and the AUTOLOGOUT parameter for this
/// page is true, is invoked when the logout timer for this
/// page fires.<br/>
/// If this method return true then the normal page logout behavior will fire.
/// That is, the page will be reloaded causing a login page to appear if the
/// current session has ended.
ClientMethod onlogoutHandler() [ Language = javascript ]
{
	// Ensure that auto-logout is not blocked by onunloadHandler checking for unsaved changes 
	this.pageModified = false;
	return true;
}

/// End the current session. If user has unsaved changes, prompt to save before process logout.
ClientMethod logout() [ Language = javascript ]
{
	var ok = true;
	if (this.pageModified) {
		var msg = $$$Text("There are unsaved changes on this page.","%Utility") + "\n\n"
		+ $$$Text("Are you sure you want to LOGOUT and discard changes?","%Utility");
		var ok = confirm(msg);
		if (ok == true) {
			this.pageModified = false;		
		}
	}
	if (ok == true) {
		document.location = this.DoLogout();
	}
	return false;
}

ClassMethod DoLogout() As %String [ ZenMethod ]
{
	// Logout removes the security context from the session and cleans up login and security token cookies.
	// It calls OnLogout() and leaves the session in existence. 
	Do %session.Logout()
	// Causes OnEndSession() to be called and the session is destroyed
	Set %session.EndSession=1
	Quit $P(##class(%CSP.Page).Link("/csp/sys/%25CSP.Portal.Home.zen"),"?",1)_"?IRISLogout=end"
}

/// Return the height of the title area (titleBar plus locator).
ClientMethod getTitleAreaHeight() [ Language = javascript ]
{
	var hgt = 0;
	try {
		var titleHgt = 0;
		var ribbonHgt = 0;
		var titleDiv = zen('title').getEnclosingDiv();
		if (titleDiv) {
			titleHgt = titleDiv.offsetHeight;
		}
		var ribbonDiv = zen('toolRibbon').getEnclosingDiv();
		if (ribbonDiv && ribbonDiv.children && ribbonDiv.children[0]) {
			ribbonHgt = ribbonDiv.children[0].offsetHeight;
		}
		
		hgt = titleHgt + ribbonHgt;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in getTitleAreaHeight.');
	}
	
	return hgt;
}

/// Change the current display mode for this page.
/// This is called by the icon buttons on the ribbon.
/// This will call the <method>setViewModeHandler</method> within a subclass.
ClientMethod setViewMode(mode) [ Language = javascript ]
{
	if (mode != this.currViewMode) {
		// update icon
		var el = self.document.getElementById('view_'+this.currViewMode);
		if (el) {
			el.className = 'viewIcon';
		}
		var oldmode = this.currViewMode;
		this.currViewMode = mode;
		var el = self.document.getElementById('view_'+this.currViewMode);
		if (el) {
			el.className = 'viewIconSelected';
			el._oldClass = 'viewIconSelected';
		}
		
		this.setViewModeHandler(mode,oldmode);
	}
}

/// Do the actual work of updating the view to match the current view mode.
ClientMethod setViewModeHandler(mode, oldmode) [ Language = javascript ]
{
	// update finder
	var finder = zen('finder');
	if (finder) {
		finder.setViewType(this.currViewMode);
	}
}

/// Change the current sort mode for the page.
ClientMethod setSortMode(mode) [ Language = javascript ]
{
	if (mode != this.currSortMode) {
		var el = self.document.getElementById('sort_'+this.currSortMode);
		if (el) {
			el.className = 'ribbonSortOption';
		}
		this.currSortMode = mode;
		var el = self.document.getElementById('sort_'+this.currSortMode);
		if (el) {
			el.className = 'ribbonSortOptionSelected';
		}
		this.setSortModeHandler(mode);
	}
}

/// Do the actual work of updating the view to match the current sort mode.
ClientMethod setSortModeHandler(mode) [ Language = javascript ]
{
}

/// Set the modified flag for the page.
ClientMethod setModified(flag) [ Language = javascript ]
{
	if (this.pageModified != flag) {
		this.pageModified = flag;
		var span = self.document.getElementById('modifiedIndicator');
		if (span) {
			span.innerHTML = this.pageModified ? '*' : '&nbsp;';
		}
	}
}

/// Set the document name for the page.
ClientMethod setPageTitle(name) [ Language = javascript ]
{
	var txt = self.document.getElementById('pageTitleText');
	if (txt) {
		txt.innerHTML = (name!='') ? (zenEscapeHTML('('+name+')')) : '&nbsp;';
	}
	var span = self.document.getElementById('pageTitleDisplay');
	if (span) {
		span.hidden = (name == '');
	}
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	if (this.pageModified) {
		return $$$Text('Changes have been made on this page.','%Utility')+'\n'+$$$Text('Do you wish to leave the page and discard the changes?','%Utility');
	}
	return true;
}

/// Navigate to a new page in the portal.
ClientMethod navigate(url) [ Language = javascript ]
{
	zenPage.gotoPage(url);
}

/// Navigate to a new namespace in the portal.
ClientMethod gotoNamespace(url) [ Language = javascript ]
{
	zenPage.gotoPage(url);
}

/// Show dialog to switch namespace
ClientMethod switchNamespace() As %String [ Language = javascript ]
{
	zenLaunchPopupWindow(zenLink('%ZEN.Dialog.namespaceSelect.cls'),'switchNamespace','status,scrollbars,resizable=yes,width=500,height=500,location=no');
}

/// Show dialog to change password
ClientMethod changePassword() As %String [ Language = javascript ]
{
	zenLaunchPopupWindow(zenLink('/csp/sys/_CSP.UI.Portal.Dialog.ChangePassword.cls'),'changePassword','status,scrollbars,resizable=yes,width=480,height=500,location=no');
}

/// Show dialog to login to an escalated role
ClientMethod escalateLogin() As %String [ Language = javascript ]
{
	zenLaunchPopupWindow(zenLink('/csp/sys/_CSP.UI.Portal.Dialog.EscalateLogin.cls'),'EscalateLogin','status,scrollbars,resizable=yes,width=480,height=500,location=no');
}

/// Subclass need to include the case "switchNamespace" if it is enabling "Switch" next to namespace.<br>
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") {
		return false;
	}	
	switch(popupName) {
	case 'EscalateLogin':
		window.location.reload();
		break;
	case 'switchNamespace':
		var url = zenPage.GetNewURL(value);
		// do not use this.gotoPage(url) because zenLink will not honor the latest $NAMESPACE you selected, i.e. you may end up with multiple $NAMESPACE on the URL.
		try {
			if (window.location && window.location.assign) window.location.assign(url);
			else self.document.location = url;
		}
		catch (e) {
		}
		break;
	}
}

/// Given new namespace, return new URL with new $NAMESPACE. When changing namespace, always go back to Home page <br>
/// because you don't know if the new namespace has or allows your current page.
ClassMethod GetNewURL(pNS As %String, pPage As %String = "%25CSP.Portal.Home.zen") As %String [ ZenMethod ]
{
	#dim tURL As %String

	#;YSD2650 Set tQuery("CSPSHARE") = 1
	#;YSD2618 Set tURL = $system.CSP.GetDefaultApp(pNS)
	If pPage = "" Set pPage = "%25CSP.Portal.Home.zen"
	Set tURL = $system.CSP.GetPortalApp(pNS,pPage)
	If tURL = "" Quit ""
	Set:$E(tURL,$L(tURL))'="/" tURL = tURL_"/"
	#; pPage maybe passed in as /csp/sys/exp/UtilSysClassList.csp?Recent=1
	#; In such case, we want to use pPage.
	If pPage '[ "/csp/sys/" Set tURL = tURL _ pPage
	Else  Set tURL = pPage
	Set tURL = ##class(%CSP.Page).Link(tURL,,1)
	// Strip off $NAMESPACE from existing URL so only one $NAMESPACE will be built into URL.
	Set tquery = $P(tURL,"?",2)
	If tquery '= "" {
		Set tLen = $L(tquery,"&") - 1
		For tI = 1:1:tLen Set p1 = $P(tquery,"&",tI),p2=$P(p1,"=",1),p3=$p(p1,"=",2) if p2'="" s p(p2)=p3
		Set p("$NAMESPACE") = pNS
		Set tquery = ""
		Set p2 = $O(p(""))
		While p2 '= "" {
			Set tquery = tquery _ p2 _ "=" _ p(p2) _ "&"
			Set p2 = $O(p(p2))
		}
		Set tURL = $P(tURL,"?",1) _ "?" _ tquery
	} Else {
		Set tURL = tURL _ "$NAMESPACE="_pNS
	}
	Set %session.Data("$NAMESPACE") = pNS
	Quit tURL
}

/// Given a HelpAddress, this method finds the DocBook Link and constructs the proper URL for the Doc page and return to the client to be displayed.
ClassMethod GetDocURL(pHelpAddress As %String) As %String [ ZenMethod ]
{
	#; Always link to the portal help page
	Set tURL = "/csp/docbook/DocBook.UI.PortalHelpPage.cls", pHelpAddress = $GET(pHelpAddress)
	#; Determine if we have a local copy of the docbook
	Set tHaveDocbook = 0
	Try {
		Set tHaveDocbook = ($$$GetSecurityApplicationsEnabled($GET($$$SecurityGlobalApplications("/csp/docbook"))) = 1)
	} Catch {} ##; Swallow <PROTECT> and assume we don't have /csp/docbook
	If tHaveDocbook {
		#; Link to the local copy of docbook
		Set tQuery("KEY") = pHelpAddress
		Set tURL = ##class(%CSP.Page).Link(tURL,.tQuery)
	} Else {
		#; Link to docs.intersystems.com
		Set tComponents = $SYSTEM.Version.GetISCComponents()
		Set tURL = "https://docs.intersystems.com/"_
			#; Add correct product
			$CASE($SYSTEM.Version.GetISCProduct(),
                3:$CASE(
                    $LISTFIND(tComponents,"HealthConnect"),
                    0:"hs",:"healthconnect"
                ),
                :$SELECT(  
                    $LISTFIND(tComponents,"Health"):"irisforhealth",
                    $LISTFIND(tComponents,"HealthConnect"):"healthconnect",
                    1:"iris"
                )
            )_
			#; Add correct version
			$SYSTEM.Version.GetMajor()_$SYSTEM.Version.GetMinor()_
			#; Add the page and KEY
			tURL_"?KEY="_$$$URLENCODE(pHelpAddress)
	}
	Return tURL
}

/// Key press in search box.
ClientMethod searchKeyPress(evt) [ Language = javascript ]
{
	//work-around for ie
	var ctrl = self.document.getElementById('searchBox');
	evt = evt ? evt : event;
	if (ctrl && evt.keyCode == zenENTER) {
		zenPage.searchBoxHandler(ctrl.value);
	}
}

/// Key down in search box.
ClientMethod searchKeyDown(evt) [ Language = javascript ]
{
	//work-around for ie
	evt = evt ? evt : event;
	return true;
}

/// Change in search box value. Can be overridden by subclasses.
ClientMethod searchBoxHandler(searchKey) [ Language = javascript ]
{
	this.searchKey = searchKey;
}

/// Blur event in search box.
ClientMethod searchFocus(evt) [ Language = javascript ]
{
}

/// Blur event in search box.
ClientMethod searchBlur(evt) [ Language = javascript ]
{
}

/// Tranforms the link specified by <VAR>link</VAR> into a URL and returns it as a string
ClassMethod GetCSPURL(link As %String) As %String [ ZenMethod ]
{
	Set query("CSPSHARE") = 1
	Set url = ##class(%CSP.Page).Link(link,.query)
	Quit url
}

/// Get the title string to add to the locator row.
/// This should be implemented in a subclass.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return "";
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// overwrite the menu style defined by JS
	var mainMenu=document.getElementById("mainMenu");
	if(mainMenu!=null) {
		mainMenu.parentElement.removeAttribute("style");
	}
	
	var menuBar=document.getElementsByClassName("csMenuBar");
	if(menuBar.length>0) {
		menuBar[0].removeAttribute("style");
	}
	var menuBarItem=document.getElementsByClassName("csMenuBarItem");
	if(menuBarItem.length>0) {
		menuBarItem[0].removeAttribute("style");
		// ZHJ038: Context Menu Shown Unintentionally
		menuBarItem[0].removeAttribute("onmouseover");
		menuBarItem[0].removeAttribute("onmouseout");
		var children=menuBarItem[0].children;
		if(children.length>0){
			for(var i=0; i<children.length; i++) {
				children[i].removeAttribute("style");
				if(i===2) {
					var menuBarText = children[i];
					menuBarText.setAttribute("style", "margin-top:12px;");
				}
			}
		}
	}	

	// Set the page title in the locator bar (breadcrumbs) if there is one
	var title = zenPage.getPageTitle();
	this.setPageTitle(title); 	
	return 1
}

ClientMethod clearEscalation() [ Language = javascript ]
{
	if (zenPage.ReallyClearEscalation()) {
		window.document.location.reload();		
	} else { // go to homepage if our session is no longer valid
		zenPage.goHome();
	}
}

ClassMethod ReallyClearEscalation() As %Boolean [ ZenMethod ]
{
	Set status = $$$OK
	If $System.Context.Security().IsEscalated() {
		Set status = %session.ClearEscalation()
	}

	Return $$$ISOK(status)
}

}
