/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%DeepSee, %products)

/// Base class for pages within the DeepSee user portal.
Class %DeepSee.UserPortal.standardPage Extends (%ZEN.Component.page, %ZEN.Portal.abstractRefreshable) [ Abstract, System = 4 ]
{

Parameter JSINCLUDES = "zenCSLM.js,zenESVG.js,DeepSee.js";

/// Set this to the appropriate application class.
Parameter APPLICATION = "%DeepSee.UserPortal.Application";

/// DeepSee favorite icon.
Parameter FAVORITEICON = "portal/ISC_IRIS_icon.ico";

/// Set this to the correct domain.
Parameter DOMAIN = "%DeepSee";

/// All DeepSee pages require %DeepSee_Portal USE.
Parameter RESOURCE = "%DeepSee_Portal,%DeepSee_PortalEdit";

/// Name of this page.
Parameter PAGENAME = "User Portal";

/// URL of home page (used in links).
Parameter HOMEPAGE = "_DeepSee.UserPortal.Home.zen";

/// Starting mode for worklist 1: html or group.
Parameter WORKLIST1MODE = "html";

/// Starting mode for worklist 2: html or group.
Parameter WORKLIST2MODE = "html";

/// Define the title that will be displayed within subclasses
Property StdTitle As %ZEN.Datatype.string [ InitialExpression = {..#PAGENAME} ];

/// URL of the Home Page.
Property homePage As %ZEN.Datatype.string [ InitialExpression = {..#HOMEPAGE} ];

/// About page URL
Property aboutPage As %ZEN.Datatype.string [ InitialExpression = {..Link("_CSP.UI.Portal.About.zen?USERPORTAL=1")} ];

/// ID of alert that launched this page, if any.
Property alertId As %ZEN.Datatype.string(ZENURL = "ALERT");

/// Current search key.
Property searchKey As %ZEN.Datatype.string;

/// URL of viewer page.
Property viewerURL As %ZEN.Datatype.uri;

/// Number of worklist panels to display: 0,1,or 2.
Property worklistCount As %ZEN.Datatype.integer(MAXVAL = 2, MINVAL = 0) [ InitialExpression = 2 ];

/// If true, send e-mail using client-side mailto application.
Property useClientEmail As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Convenience property. Setting this true is equivalent to 
/// NOTITLE=1,NOBORDER=1,NOMODIFY=1,WORKLISTS=0
Property isEmbedded As %ZEN.Datatype.boolean(ZENURL = "EMBED");

/// If true, then do not display the title area of this page.
Property noTitle As %ZEN.Datatype.boolean(ZENURL = "NOTITLE");

/// If true, then do not display the outer border around the desktop area of this page.
Property noBorder As %ZEN.Datatype.boolean(ZENURL = "NOBORDER");

/// If true, then do not allow user to modify this page (this is only a convenience, it is 
/// not enforced by privileges).
Property noModify As %ZEN.Datatype.boolean(ZENURL = "NOMODIFY");

/// If set override the worklist count (number of worklist boxes on side of page). This
/// can be 0,1, or 2.
Property urlWorklistCount As %ZEN.Datatype.integer(ZENURL = "WORKLISTS");

/// If true, user can modify this page.
Property canWrite As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Chart series color scheme.
Property chartSeriesScheme As %ZEN.Datatype.string;

/// Chart series color list.
Property chartSeriesColors As %ZEN.Datatype.string;

/// Local override of company name.
Property companyName As %ZEN.Datatype.string;

/// Local override of company logo.
Property companyLogo As %ZEN.Datatype.string;

/// Local override of company cell style.
Property companyStyle As %ZEN.Datatype.string;

/// Set to true to suppress hyperevent error pop-ups in
/// the event of a connectitivity failure.
Property limitPopups As %ZEN.Datatype.boolean [ InitialExpression = {##class(%CSP.Portal.Utils).%IsConnectivityPopupDisabled()} ];

XData Style
{
<style type="text/css">

#contentsLeft {
	width: 300px;
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
<hgroup id="titleGroup" width="100%" cellVAlign="bottom">
<spacer width="20px"/>
<pane paneName="menuPane" width="100px"/>
<html id="title" OnDrawContent="DrawTitle"/>
</hgroup>

<hgroup id="contentsOuter" enclosingClass="contentsOuter" cellVAlign="top">
<hgroup id="contentsInner" enclosingClass="contentsInner" cellVAlign="top">
<navigator id="navigator"
showSliderValue="true"
showDisclosure="true"
expanded="false"
title="Show or hide additional options"
ongetcontent="return zenPage.navGetContentForLevel(level,key,value);"
onchange="zenPage.navDataChange(key,value,final);"
onarrange="zenPage.navDataArrange(key,swap,final);"
onselect="zenPage.navSelectItem(key,value,which);"
onbuttonclick="zenPage.navHeaderButtonClick(key);"
onclosebuttonclick="zenPage.navCloseButtonClick(key);"
onpopupaction="zenPage.navPopupAction(key,value);"
onexpand="zenPage.navExpand();"
backgroundStyle="opacity:0.1;background-color:rgb(174,141,88);background-image:url(deepsee/ds_navback.png);"
/>

<vgroup id="contentsLeft">
<html id="worklistTitle" enclosingClass="worklistTitle" OnDrawContent="DrawWorklistTitle"/>
<vgroup id="worklistWrapper1" enclosingClass="worklistWrapper">
<html id="worklistDiv1" enclosingClass="worklistHeaderDiv" OnDrawContent="DrawWorklistHeader1"/>
<html id="worklistDiv1HTML" hidden="false" enclosingClass="worklistDiv" OnDrawContent="DrawWorklist1"/>
<vgroup id="worklistDiv1Group" hidden="true" enclosingClass="worklistGroup" cellStyle="padding:2px;"/>
</vgroup>
<group id="worklistWrapper2" enclosingClass="worklistWrapper">
<html id="worklistDiv2" enclosingClass="worklistHeaderDiv" OnDrawContent="DrawWorklistHeader2"/>
<html id="worklistDiv2HTML" enclosingClass="worklistDiv" OnDrawContent="DrawWorklist2"/>
<vgroup id="worklistDiv2Group" hidden="true" enclosingClass="worklistGroup" cellStyle="padding:2px;"/>
</group>
</vgroup>

<vgroup id="contentsRight">
<pane paneName="contentsRightPane"/>
</vgroup>

</hgroup>
</hgroup>
</page>
}

/// This XML defines the menu for this page.
XData menuPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<csMenuBar id="mainMenu" width="100px">
<csMenuBarItem caption="Menu">
<contextMenu id="fileMenu">
<csMenuItem caption="About" onclick="alert('About');" />
</contextMenu>
</csMenuBarItem>
</csMenuBar>
</pane>
}

/// This XML defines the main display area.
XData contentsRightPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
</pane>
}

/// Draw the contents of the title area.
/// Dispatch to application class.
Method DrawTitle(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		If $IsObject($G(%application)) {
			Set tTitle = ..%OnGetTitle()
			Do ..%OnGetSmallMenu(.tSmallMenu)
			Set tSC = %application.%DrawTitleHTML(tTitle,.tSmallMenu)
		}
		Else {
			&html<No Application Defined for Page!>
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Add include files to support color schemes.
Method %OnDrawHTMLHead() As %Status
{
	Do ##class(%DeepSee.UserPortal.Utils).%GetPreferences(.tPrefs)
	Set tScheme = $G(tPrefs("Scheme"))

	// check for URL override
	If ($D(%request.Data("SCHEME",1))) {
		Set tScheme = $$$LOWER($G(%request.Data("SCHEME",1)))
	}

	If (tScheme '= "") {
		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetColorSchemeInfo(tScheme,.tInfo)

		// CSS file
		Set tCSSFile = $G(tInfo("css"))
		If (tCSSFile'="") {
			Write "<link rel=""stylesheet"" type=""text/css"" href="""_tCSSFile_"""/>",!
		}

		// Initializer file for SVG components
		Set tInitFile = $G(tInfo("js"))
		If (tInitFile'="") {
			Write "<script type=""text/javascript"" src="""_tInitFile_"""></script>",!
		}
	}

	Quit $$$OK
}

/// Draw the contents of the worklist title area.
Method DrawWorklistTitle(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Write "Template Page"
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return list of options for work list 1.
Method %OnGetWorklistOptions1(Output pOptions, Output pDefaultMode) As %Status
{
	// $LB(name,class)
	Set pOptions($I(n)) = $LB("alerts","%DeepSee.UserPortal.AlertList")
	Set pOptions($I(n)) = $LB("favorites","%DeepSee.UserPortal.FavoritesList")
	Set pDefaultMode = "alerts"

	Quit $$$OK
}

/// Return list of options for work list 2.
Method %OnGetWorklistOptions2(Output pOptions, Output pDefaultMode) As %Status
{
	// $LB(name,class)
	Set pOptions($I(n)) = $LB("details","%DeepSee.UserPortal.DetailsList")
	Set pOptions($I(n)) = $LB("favorites","%DeepSee.UserPortal.FavoritesList")
	Set pOptions($I(n)) = $LB("recent","%DeepSee.UserPortal.RecentList")
	Set pDefaultMode = "favorites"
	Quit $$$OK
}

/// Draw the header for worklist 1.
Method DrawWorklistHeader1(pSeed As %String) As %Status
{
	Set tDefault = ""
	Set tSC = ..%OnGetWorklistOptions1(.tOptions,.tDefault)
	If $$$ISERR(tSC) Quit tSC
	Set tMode = pSeed
	If (tMode="") {
		Set tMode = tDefault
		Set ..%GetComponentById("worklistDiv1").seed = tDefault
	}

	Quit ..%DrawWorklistHeader(tMode,"worklistDiv1",1,.tOptions)
}

/// Draw the contents of the worklist 1.
Method DrawWorklist1(pSeed As %String) As %Status
{
	Set tDefault = ""
	Set tSC = ..%OnGetWorklistOptions1(.tOptions,.tDefault)
	If $$$ISERR(tSC) Quit tSC

	Set tMode = pSeed
	Set:tMode="" tMode = tDefault

	Quit ..%DrawWorklist(tMode,"worklistDiv1",1,.tOptions)
}

/// Draw the the header for worklist 2.
Method DrawWorklistHeader2(pSeed As %String) As %Status
{
	Set tDefault = ""
	Set tSC = ..%OnGetWorklistOptions2(.tOptions,.tDefault)
	If $$$ISERR(tSC) Quit tSC
	Set tMode = pSeed
	If (tMode="") {
		Set tMode = tDefault
		Set ..%GetComponentById("worklistDiv2").seed = tDefault
	}
	Quit ..%DrawWorklistHeader(tMode,"worklistDiv2",2,.tOptions)
}

/// Draw the contents of the worklist 2.
Method DrawWorklist2(pSeed As %String) As %Status
{
	Set tDefault = ""
	Set tSC = ..%OnGetWorklistOptions2(.tOptions,.tDefault)
	If $$$ISERR(tSC) Quit tSC

	Set tMode = pSeed
	Set:tMode="" tMode = tDefault

	Quit ..%DrawWorklist(tMode,"worklistDiv2",2,.tOptions)
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

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Set ..viewerURL = ##class(%DeepSee.UserPortal.Utils).%GetViewerURL()

	// check for write access
	Set ..canWrite = 1
	If ('$$CheckPortalWriteAccess^%qdsUtils()) {
		Set ..canWrite = 0
	}

	// JMD1260: check for system default values for some settings
	// DTB116: make sure these settings return 1 or 0
	If (..noBorder="") {
		Set ..noBorder = $G(^DeepSee.UserPortalSettings("DashboardNoBorder"),0)
	}
	If (..noTitle="") {
		Set ..noTitle = $G(^DeepSee.UserPortalSettings("DashboardNoTitle"),0)
	}

	If (+..isEmbedded) {
		// set other properties unless user has set them explicitly
		Set:..noTitle=0 ..noTitle = 1
		Set:..noBorder=0 ..noBorder = 1
		Set:+..noModify=0 ..noModify = 1
		Set:..urlWorklistCount="" ..urlWorklistCount = 0
	}

	If (+..noTitle) {
		Set ..%GetComponentById("titleGroup").hidden = 1
		Set %response.Context("NOTITLE") = 1
	}
	If (+..noModify) {
		Set %response.Context("NOMODIFY") = 1
	}
	If ((..urlWorklistCount'="")&&(+..urlWorklistCount>=0)&&(+..urlWorklistCount<=2)) {
		Set ..worklistCount = ..urlWorklistCount
		Set %response.Context("WORKLISTS") = ..urlWorklistCount
	}
	If (+..noBorder) {
		// override styles to remove border
		Set ..%GetComponentById("contentsOuter").enclosingClass = "contentsOuterNoBorder"
		Set ..%GetComponentById("contentsInner").enclosingClass = "contentsInnerNoBorder"

		Set ..%GetComponentById("contentsLeft").enclosingStyle = "background: none;border-right:1px solid #808080;"

		// turn off background color for page
		Set %page.enclosingStyle = "background: none; overflow:hidden;"

		Set %response.Context("NOBORDER") = 1
	}

	If (..#WORKLIST1MODE="group") {
		Set ..%GetComponentById("worklistDiv1HTML").hidden = 1
		Set ..%GetComponentById("worklistDiv1Group").hidden = 0
	}
	If (..#WORKLIST2MODE="group") {
		Set ..%GetComponentById("worklistDiv2HTML").hidden = 1
		Set ..%GetComponentById("worklistDiv2Group").hidden = 0
	}
	
	// pick up chart color scheme
	Set ..chartSeriesScheme	= ""
	Set ..chartSeriesColors	= ""
	Set tScheme = $G(^DeepSee.UserPortalSettings("ChartSeriesScheme"))
	If (tScheme'="") {
		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetChartSeriesSchemeInfo(tScheme,.tSchemeName,.tColorList)
		Set ..chartSeriesScheme	= tSchemeName
		Set ..chartSeriesColors	= tColorList
	}
	
	// JMD1210
	// turn off backing style for IE!
	Set:$$$ZENISIE ..%GetComponentById("navigator").backgroundStyle = ""
	
	Quit tSC
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit "DeepSee Portal"
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit "PageName"
}

/// Get the contents of the small menu in the title area.
Method %OnGetSmallMenu(Output pMenu)
{
	// $LB(caption,title,script)
	Set pMenu($I(n)) = $LB($$$Text("Home"),$$$Text("Go to the Home page"),"zenPage.goHome();")
	Set pMenu($I(n)) = $LB($$$TextHTML("About"),$$$TextHTML("Display the About page"),"return zenPage.showAbout();")
	Set pMenu($I(n)) = $LB($$$Text("Logout"),$$$Text("End this session"),"zenPage.logout();")
}

/// Go to the home page.
ClientMethod goHome() [ Language = javascript ]
{
	zenPage.gotoPage(this.homePage);
}

/// Go to the home page.
ClientMethod showAbout() [ Language = javascript ]
{
	self.document.location = this.aboutPage;
	return false;
}

/// Show documentation.
ClientMethod showHelp() [ Language = javascript ]
{
	alert('Help');
}

/// End the current session.
ClientMethod logout() [ Language = javascript ]
{
	this.DoLogout();
	this.goHome();
}

ClassMethod DoLogout() As %Boolean [ ZenMethod ]
{
	If $System.Version.GetMajor() >= 2011 {
		// Logout removes the security context from the session and cleans up login and security token cookies.
		// It calls OnLogout() and leaves the session in existence. 
		Do %session.Logout()
	}
	// Causes OnEndSession() to be called and the session is destroyed
	Set %session.EndSession=1
	Quit 1
}

/// Return the height of the title area (titleBar plus locator).
ClientMethod getTitleAreaHeight() [ Language = javascript ]
{
	var hgt = 0;
	try {
		var titleDiv = zen('title').getEnclosingDiv();
		hgt = titleDiv.offsetHeight;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in getTitleAreaHeight.');
	}
	
	return hgt;
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

/// View the given alert.
ClientMethod gotoAlert(url) [ Language = javascript ]
{
	if (url!='') {
		zenPage.gotoPage(url);
	}
}

/// View the given favorite.
ClientMethod gotoFavorite(url) [ Language = javascript ]
{
	if (url!='') {
		zenPage.gotoPage(url);
	}
}

/// Add item to favorites
ClientMethod addToFavorites(name) [ Language = javascript ]
{
	zenPage.AddFavorite(name);
	zenPage.updateWorklistType('favorites');
}

/// Remove item from favorites
ClientMethod removeFromFavorites(name) [ Language = javascript ]
{
	zenPage.RemoveFavorite(name);
	zenPage.updateWorklistType('favorites');
}

/// Remove item from recent list.
ClientMethod removeFromRecentList(name) [ Language = javascript ]
{
	zenPage.RemoveRecentItem(name);
	zenPage.updateWorklistType('recent');
}

/// Remove item from alerts.
ClientMethod removeFromAlerts(alertId) [ Language = javascript ]
{
	zenPage.RemoveAlert(alertId);
	zenPage.updateWorklistType('alerts');
}

/// Update the all worklists showing the given type.
ClientMethod updateWorklistType(mode) [ Language = javascript ]
{
	// check what each worklist is showing
	wlist1 = zen('worklistDiv1');
	if (wlist1) {
		this.setWorklistView('worklistDiv1',wlist1.seed);
	}

	wlist2 = zen('worklistDiv2');
	if (wlist2) {
		this.setWorklistView('worklistDiv2',wlist2.seed);
	}
	/* names are not correct !
	wlist1 = zen('worklistDiv1');
	if (wlist1 && wlist1.seed == mode) {
		this.setWorklistView('worklistDiv1',mode);
	}

	wlist2 = zen('worklistDiv2');
	if (wlist2 && wlist2.seed == mode) {
		this.setWorklistView('worklistDiv2',mode);
	}
	*/
}

/// Called when user updates or clicks on an icon in a worklist.
ClientMethod setWorklistView(id, mode, type) [ Language = javascript ]
{
	var header = zen(id);
	if (!header) return;

	if ('undefined' != typeof mode) {
		header.seed = mode;
	}
	header.refreshContents(true);

	var panel = zen(id+'HTML');
	if (!panel) return;

	var group = zen(id+'Group');

	if ('undefined' != typeof mode) {
		panel.seed = mode;
	}

	// what type of panel is showing
	if ('undefined' == typeof type) {
		type = panel.hidden ? 'group' : 'html';
	}

	if (type == 'html') {
		if (group) {
			group.setHidden(true);
		}
		panel.setHidden(false);
		panel.refreshContents(true);

		switch(id) {
		case 'worklistDiv1':
			var list = self.document.getElementById('worklist1');
			if (!this._worklistHeight1) {
				this.adjustSizes();
			}
			if (list) {
				list.style.height = this._worklistHeight1 + 'px';
			}
		case 'worklistDiv2':
			var list = self.document.getElementById('worklist2');
			if (!this._worklistHeight2) {
				this.adjustSizes();
			}
			if (list) {
				list.style.height = this._worklistHeight2 + 'px';
			}
		}
	}
	else {
		if (group) {
			group.setHidden(false);
		}
		panel.setHidden(true);
	}
}

ClassMethod AddFavorite(pName As %String) As %Boolean [ ZenMethod ]
{
	Do ##class(%DeepSee.UserLibrary.Utils).%AddFavorite(pName)
	Quit 1
}

ClassMethod RemoveFavorite(pName As %String) As %Boolean [ ZenMethod ]
{
	Do ##class(%DeepSee.UserLibrary.Utils).%RemoveFavorite(pName)
	Quit 1
}

ClassMethod RemoveAlert(pAlertId As %String) As %Boolean [ ZenMethod ]
{
	Do ##class(%DeepSee.UserPortal.Utils).%DeleteAlert(pAlertId)
	Quit 1
}

ClassMethod RemoveRecentItem(pName As %String) As %Boolean [ ZenMethod ]
{
	Do ##class(%DeepSee.UserLibrary.Utils).%RemoveRecentItem(pName)
	Quit 1
}

/// Update the title for the worklist.
ClientMethod updateWorklistTitle() [ Language = javascript ]
{
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		if (load) {
			this.updateWorklistTitle();
		}
		if (load && this.error!='') {
			alert(this.error);
		}
		this.adjustSizes(load);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes(load) [ Language = javascript ]
{
	try {
		load = zenGet(load,false);

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		var th = this.getTitleAreaHeight();

		var wlists = parseInt(this.worklistCount);
		if (isNaN(wlists)) {
			wlists = 2;
		}

		var nav = this.getNavigator();

		this._topListHeight = 0;
		this._bottomListHeight = 0;

		var outer = zen('contentsOuter');
		var inner = zen('contentsInner');
		if (outer && inner) {

			var gapW = this.noBorder ? 2 : 40;
			var gapH = this.noBorder ? 3 : 20;

			var divOuter = outer.getEnclosingDiv();
			var oh = winHeight - gapH - th;
			var ow = winWidth - gapW;

			if ((oh < 50) || (ow < 50)) {
				divOuter.style.visibility = 'hidden';
				return;
			}
			divOuter.style.visibility = 'visible';
			divOuter.style.height = oh + 'px';
			divOuter.style.width = ow + 'px';

			var divInner = inner.getEnclosingDiv();
			var mgn = this.noBorder ? 0 : 12;
			var innerHgt = winHeight - gapH - (mgn*2) - th;
			divInner.style.marginTop = mgn + 'px';
			divInner.style.height = innerHgt + 'px';
			divInner.style.width = winWidth - gapW + 'px';

			if (nav) {
				nav.setHeight(innerHgt);
			}

			// adjust items in left column
			var left = zen('contentsLeft');
			var leftDiv = left.getEnclosingDiv();
			var lw = this._leftWidth ? this._leftWidth : leftDiv.offsetWidth;
			this._leftWidth = lw; // cache as ie will report a new value each time!
			if (ow < lw || (wlists==0)) {
				lw = 0;
				leftDiv.style.display = 'none';
			}
			else {
				leftDiv.style.display = '';
			}
			var rw = ow - lw;

			if (wlists>0) {
				var wtitle = zen('worklistTitle');
				var wth = wtitle ? wtitle.getEnclosingDiv().offsetHeight : 0;
				var wlist1 = zen('worklistWrapper1');
				var wlist2 = zen('worklistWrapper2');
				var bh = ((innerHgt - wth) / wlists) + 0;
				var bw = lw;
				if (wlist1) {
					var divWlist1 = wlist1.getEnclosingDiv();
					if (bh < 50) {
						divWlist1.style.display = 'none';
					}
					else {
						divWlist1.style.display = '';
						divWlist1.style.height = bh + 'px';

						var divWlistHeader1 = zen('worklistDiv1').getEnclosingDiv();
						var divWlistInner1 = zen('worklistDiv1HTML').getEnclosingDiv();
						var divWlistGroup1 = zen('worklistDiv1Group').getEnclosingDiv();

						// actual content of header
						var wListHdr1 = self.document.getElementById('worklistHeader1');

						if (divWlistHeader1) {
							divWlistHeader1.style.marginLeft = 10 + 'px';
							divWlistHeader1.style.height = wListHdr1.offsetHeight + 'px';
							divWlistHeader1.style.width = bw-30 + 'px';
						}

						if (divWlistInner1) {
							divWlistInner1.style.marginTop = 0 + 'px';
							divWlistInner1.style.marginLeft = 10 + 'px';
							divWlistInner1.style.height = bh-20-wListHdr1.offsetHeight + 'px';
							divWlistInner1.style.width = bw-30 + 'px';
						}
						if (divWlistGroup1) {
							divWlistGroup1.style.marginTop = 0 + 'px';
							divWlistGroup1.style.marginLeft = 10 + 'px';
							divWlistGroup1.style.height = bh-20-wListHdr1.offsetHeight + 'px';
							divWlistGroup1.style.width = bw-30 + 'px';
						}

						var wList1 = self.document.getElementById('worklist1');
						if (wList1) {
							this._worklistHeight1 = bh - 24 - wListHdr1.offsetHeight;
							wList1.style.height =  this._worklistHeight1 + 'px';
							if (load) {
								wList1.scrollTop = 0;
							}
						}
					}
				}
				if (wlist2 && wlists>1) {
					var divWlist2 = wlist2.getEnclosingDiv();
					if (bh < 50) {
						divWlist2.style.display = 'none';
					}
					else {
						divWlist2.style.display = '';
						divWlist2.style.height = bh + 'px';

						var divWlistHeader2 = zen('worklistDiv2').getEnclosingDiv();
						var divWlistInner2 = zen('worklistDiv2HTML').getEnclosingDiv();
						var divWlistGroup2 = zen('worklistDiv2Group').getEnclosingDiv();

						// actual content of header
						var wListHdr2 = self.document.getElementById('worklistHeader2');

						if (divWlistHeader2) {
							divWlistHeader2.style.marginLeft = 10 + 'px';
							divWlistHeader2.style.height = wListHdr2.offsetHeight + 'px';
							divWlistHeader2.style.width = bw-30 + 'px';
						}

						if (divWlistInner2) {
							divWlistInner2.style.marginTop = 0 + 'px';
							divWlistInner2.style.marginLeft = 10 + 'px';
							divWlistInner2.style.height = bh-20-wListHdr2.offsetHeight + 'px';
							divWlistInner2.style.width = bw-30 + 'px';
						}
						if (divWlistGroup2) {
							divWlistGroup2.style.marginTop = 0 + 'px';
							divWlistGroup2.style.marginLeft = 10 + 'px';
							divWlistGroup2.style.height = bh-20-wListHdr2.offsetHeight + 'px';
							divWlistGroup2.style.width = bw-30 + 'px';
						}

						var wList2 = self.document.getElementById('worklist2');
						if (wListHdr2 && wList2) {
							this._worklistHeight2 = bh - 24 - wListHdr2.offsetHeight;
							wList2.style.height =  this._worklistHeight2 + 'px';
							if (load) {
								wList2.scrollTop = 0;
							}
						}
					}
				}
			}

			// let subclasses do more work
			var navWid = nav ? nav.getWidth() : 0;
			this.onAdjustSizes(load,rw-navWid,innerHgt);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Adjust sizes of content area.
ClientMethod onAdjustSizes(load, contentWidth, contentHeight) [ Language = javascript ]
{
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	}
}

/// Draw the contents of a worklist panel within the user portal.<br/>
/// <var>pMode</var> indicates the type of contents to display.<br/>
/// <var>pPanelId</var> is the id of the html component displaying the panel.<br/>
/// <var>pPanelNo</var> is the worklist number.<br/>
/// <var>pOptions</var> is a list of the available options:<br/>
/// pOptions(n) = $LB(name,type,class)
ClassMethod %DrawWorklistHeader(pMode As %String, pPanelId As %String, pPanelNo As %Integer, ByRef pOptions As %List) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		// find current item
		Set (tClass,tTitle,tHeaderMsg,tMethod) = ""
		Set k = $O(pOptions(""))
		While (k'="") {
			Set tName = $LG(pOptions(k),1)
			If (tName = pMode) {
				Set tClass = $LG(pOptions(k),2)
				Quit
			}
			Set k = $O(pOptions(k))
		}

		// dispatch
		If (tClass'="") {
			Set tTitle = $zobjclassmethod(tClass,"%GetTitle")
			Set tHeaderMsg = $zobjclassmethod(tClass,"%GetHeaderMessage")
		}

		// header
		// JMD1343 try to make german fit!
		Set tFontSize = ""
		Set:$L(tTitle)>15 tFontSize = "font-size:14px;"
		&html<
			<div id="worklistHeader#(pPanelNo)#" style="overflow:hidden;">
			<table class="worklistHeaderTable" style="width:100%;" cellspacing="0" border="0" cellpadding="0"><tr>
			<td class="worklistHeaderTitle" style="white-space:nowrap;#(tFontSize)#">#(tTitle)#&nbsp;</td>
			<td class="worklistHeaderMsg" style="width:90%;">#(tHeaderMsg)#&nbsp;</td>
			>

		// icons
		// count # of icons
		Set tIconCount = 0
		Set k = $O(pOptions(""))
		While (k'="") {
			Set tIconCount = tIconCount + 1
			Set k = $O(pOptions(k))
		}

		If (tIconCount>1) {
			Set k = $O(pOptions(""))
			While (k'="") {
				Set (tIcon,tTip,tType) = ""
				Set tName = $LG(pOptions(k),1)
				Set tClass = $LG(pOptions(k),2)
				If (tClass'="") {
					Set tIcon = $zobjclassmethod(tClass,"%GetIcon")
					Set tTip = $zobjclassmethod(tClass,"%GetToolTip")
					Set tType = $zobjclassmethod(tClass,"%GetType")
				}
				If (tIcon'="") {
					Set tIconCls = $S(pMode=tName:"worklistIconCurrent",1:"worklistIcon")
					&html<<td class="#(tIconCls)#"><image src="#(tIcon)#" alt="#(tName)#" title="#(tTip)#" onclick="zenPage.setWorklistView('#(pPanelId)#','#(tName)#','#(tType)#');"/></td>>
				}
				Set k = $O(pOptions(k))
			}
		}
		&html<</tr></table></div>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw the contents of a worklist panel within the user portal.<br/>
/// <var>pMode</var> indicates the type of contents to display (which item in the options list).<br/>
/// <var>pPanelId</var> is the id of the html component displaying the panel.<br/>
/// <var>pPanelNo</var> is the worklist number.<br/>
/// <var>pOptions</var> is a list of the available options:<br/>
/// pOptions(n) = $LB(name,type,class)
ClassMethod %DrawWorklist(pMode As %String, pPanelId As %String, pPanelNo As %Integer, ByRef pOptions As %List) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		// find current item
		Set (tClass,tTitle,tHeaderMsg,tMethod) = ""
		Set k = $O(pOptions(""))
		While (k'="") {
			Set tName = $LG(pOptions(k),1)
			If (tName = pMode) {
				Set tClass = $LG(pOptions(k),2)
				Quit
			}
			Set k = $O(pOptions(k))
		}
		If (tClass'="") {
			// dispatch
			Set tSC = $zobjclassmethod(tClass,"%DrawWorkList",pPanelNo)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Move the given folder item to the trash folder.
Method SendItemToTrash(pName As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		// move the item to the trash folder
		Set tItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pName,.tSC)
		If $$$ISERR(tSC) Quit

		If $IsObject(tItem) {
			// JMD1202 Test for WRITE access
			If ('tItem.%CheckResource("WRITE") || '$System.Security.Check("%DeepSee_PortalEdit","USE")) {
				Set tMsg = $$$Text("You do not hold WRITE permission on this item.")
				Quit
			}

			// Rename and save in the trash folder.
			Set tExt = $P(tItem.fullName,".",$L(tItem.fullName,"."))
			Set tTrashName = "$TRASH" _ $S(tItem.folderName="":"",1:"/") _ tItem.folderName _ "/" _ tItem.name _ "." _ tExt
			Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderItem(tTrashName)
			If $$$ISERR(tSC) Quit
			Set tItem.fullName = tTrashName

			Set tSC = tItem.%Save()
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// Toggle display of work lists.
ClientMethod toggleWorklists() [ Language = javascript ]
{
	if ('undefined' != typeof this._oldworklistCount) {
		this.worklistCount = this._oldworklistCount;
		delete this._oldworklistCount;
	}
	else {
		this._oldworklistCount = this.worklistCount;
		this.worklistCount = (this.worklistCount==0)?2:0;
	}
	this.adjustSizes(false);
}

/// Launch the send alert dialog.
ClientMethod sendAlert() [ Language = javascript ]
{
	var parms = {
			TITLE:this.dashboardTitle,
			DASHBOARD:this.dashboardName
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.SendAlert.zen','SendAlert','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Launch the send email dialog.
ClientMethod sendMail(url, title) [ Language = javascript ]
{
	url = ('undefined' == typeof url) ? self.document.location : url;
	title = ('undefined' == typeof title) ? this.dashboardTitle : title;

	if (this.useClientEmail) {
		var link = 'mailto:';
		link += '?subject='+encodeURIComponent(title);

		// clean up URL
		// replace "localhost" to keep email client happy
		var url2 = url.toString().replace(/localhost/,"127.0.0.1");

		// use _ instead of % to avoid escape issues with email clients
		url2 = url2.replace(/\%25DeepSee/,"_DeepSee");
		link += '&body=';
		link += '%0D';
		link += $$$Text("To view this information click on the following link:")
		link += '%0D';
		link += '%0D';
		link += encodeURIComponent(url2);

		var win = window.open(link,'email');
		if (win && win.open && !win.closed) {
			win.close();
		}
	}
	else {
		// server side

		var parms = {
				TITLE:title,
				URL:url,
				DASHBOARD:this.dashboardName
				};
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.SendMail.zen','SendMail','status,scrollbars,resizable=yes,width=500,height=500',parms);
	}
}

/// Expand or contract of navigator.
ClientMethod navExpand() [ Language = javascript ]
{
	this.onlayoutHandler(false);
}

/// Return an object describing what to display for this level within the navigator.
ClientMethod navGetContentForLevel(level, key) [ Language = javascript ]
{
	var title = level==0 ? '' : key;
	var content = { title: title, items:[] };

	switch (key) {
	case '':
		break;
	}

	return content;
}

/// Change of data value in navigator.
ClientMethod navDataChange(key, value, final) [ Language = javascript ]
{
}

/// Re-arrange of a list in navigator.
ClientMethod navDataArrange(key, swap, final) [ Language = javascript ]
{
}

/// Click on header button in navigator.
ClientMethod navHeaderButtonClick(key) [ Language = javascript ]
{
}

/// Click on close button in navigator.
ClientMethod navCloseButtonClick(key) [ Language = javascript ]
{
}

/// Popup action in navigator.
ClientMethod navPopupAction(key, value) [ Language = javascript ]
{
}

/// Select of item within the navigator.
ClientMethod navSelectItem(key, value, which) [ Language = javascript ]
{
	if (which=='select') {
		var nav = this.getNavigator();
		nav.setExpanded(false);
		nav.popSheet();
	}
}

/// Get the navigator component.
ClientMethod getNavigator() [ Language = javascript ]
{
	return zen('navigator');
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'worklistCount':
		this.worklistCount = parseInt(value);
		this.adjustSizes(false);
		break;

	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

Method %OnDrawHTMLMeta() As %Status
{
	//Ensure that we force Internet Explorer to use its most recent rendering engine.	
	If $$$ZENISIE &html<<meta http-equiv="X-UA-Compatible" content="IE=edge" />>
	Quit $$$OK
}

/// Set the contents of the small message box in the title.
ClientMethod setPortalTitleMsg(msg) [ Language = javascript ]
{
	var td = self.document.getElementById('portalTitleMsg');
	if (td) {
		if (msg) {
			td.style.display = 'block';
			td.innerHTML = msg;
		}
		else {
			td.style.display = 'none';
		}
	}
}

/// Set the HTML contents of the company logo cell in the title.
/// If content is null, restore original content.
ClientMethod setCompanyCell(content) [ Language = javascript ]
{
	var td = self.document.getElementById('portalCompanyCell');
	if (td) {
		if (!this._originalCompanyCell) {
			this._originalCompanyCell = td.innerHTML;
		}
		td.innerHTML = content ? content : this._originalCompanyCell;
	}
}

/// Update the contents of the company cell in the title (if present) to
/// match the local settings of this page.
ClientMethod updateCompanyCell(load) [ Language = javascript ]
{
	var html = [];
	load = zenGet(load,false);

	if (this.companyLogo || this.companyName) {
		html[html.length] = '<div style="'+zenEscapeHTMLSafe(this.companyStyle)+'">';
		if (this.companyLogo) {
			html[html.length] = '<image src="'+zenEscapeHTMLSafe(this.companyLogo)+'" style="height:24px;"/>';
		}
		else if (this.companyName) {
			html[html.length] = zenEscapeHTMLSafe(this.companyName);
		}
		html[html.length] = '</div>';
	}
	this.setCompanyCell(html.join(''));
	if (!load) {
		this.adjustSizes(false);
	}
}

/// Reload this page in an IE-friendly way!
ClientMethod reloadPage() [ Language = javascript ]
{
	try {
		self.document.location.reload();
	}
	catch (ex) {
		// ignore
	}
}

/// Custom handler for hyperEvent handlers to be (optionally) less 
/// intrusive if the cause of the error was an auto-refresh timer
/// losing commectivity with the host.
ClientMethod onServerMethodError(err, errObject) [ Language = javascript ]
{
	// Method implemented by DTB789
	var doAlert = true;
	if (errObject) {
		var code = errObject.code;
		var serverCode = errObject.serverCode;
		if ((code == 401) && ((serverCode == 864) || (serverCode == 5918))) {
			self.document.location.reload();
			doAlert = false;
		}
		else if ((zenPage.limitPopups)&&(code<401)) { // check to see if this was refresh timer related
			zenPage.setConnectivityStatusMsg(err);
			window.setTimeout('zenPage.setConnectivityStatusMsg("Re-trying");',1000);
			window.setTimeout('zenPage.testConnectivity();',1000);
			doAlert = false;
		}
	}
	if (doAlert) {
		alert(err);
	}
	return true;
}

ClientMethod testConnectivity() [ Internal, Language = javascript ]
{
	// Method implemented by DTB789
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
	// Method implemented by DTB789
	var div = document.getElementsByClassName("portalTitleInfoBox");
	if (div && div[0]) {
		var rows = div[0].getElementsByTagName("TR");
		var found = false
		var idx = 0;
		while ((idx<rows.length) && (!found)) {
			var td = rows[idx].lastElementChild;
			if (td.colSpan==4) {
				if (msg!='') {
					var systemStyle = "text-align: center; background: #aa4040; color:#ffffff; font-size:10pt; padding:2px;"
					td.innerHTML='<div title="'+msg+'" style="'+systemStyle+'">No Connection</div>';
				}
				else {
					td.innerHTML='';
				}
				found = true;
			}
			idx++;
		}
	}
}

}
