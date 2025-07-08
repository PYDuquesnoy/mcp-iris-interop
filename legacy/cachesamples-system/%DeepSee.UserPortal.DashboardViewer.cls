/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The DeepSee DashBoard viewer page.<br/>
/// This page displays a saved DeepSee dashboard.
/// Invoke this page using the URL:<br/>
/// _DeepSee.UserPortal.DashboardViewer.zen?DASHBOARD=dashboardname<br/>
/// Where <var>dashboardname</var> is the <b>full</b> name of the dashboard: e.g.,
/// "folder/name.dashboard"<br/>
/// This class should be considered as *internal*; subclassing is not supported.
Class %DeepSee.UserPortal.DashboardViewer Extends (%DeepSee.UserPortal.standardPage, %CSP.Portal.SourceControl.Base) [ System = 4 ]
{

/// Name of this page.
Parameter PAGENAME = "Dashboard Viewer";

/// Starting mode for worklist 1: html or group.
Parameter WORKLIST1MODE = "group";

/// Pick up formula code.
Parameter JSINCLUDES = "zenCSLM.js,zenESVG.js,DeepSee.js,dsparser.js";

/// Name of the currently displayed dashboard.
/// Use XDASHBOARD to use a session encrypted value for this.
Property dashboardName As %ZEN.Datatype.string(ZENURL = "DASHBOARD");

/// Token to load unsaved pivot state
Property autosave As %ZEN.Datatype.string(ZENURL = "AUTOSAVE");

/// Token to ignore autosave behavior (used with "Clear My Settings")
Property autosaveOverride As %ZEN.Datatype.string;

/// Folder for autosave items
Property tempStorageRoot As %ZEN.Datatype.string [ InitialExpression = "$Temp/Dashboard/" ];

/// Title of the currently displayed dashboard.
Property dashboardTitle As %ZEN.Datatype.string;

/// border of widgets in dashboard
Property widgetBorders As %ZEN.Datatype.string [ InitialExpression = "1px solid #F0F0F0" ];

/// Whether borders of widgets are on or off
Property widgetBordersToggle As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Whether border is none, inherit or "width style color"
Property widgetBordersSwitch As %ZEN.Datatype.string [ InitialExpression = "edit" ];

/// color of widgets border
Property widgetBordersColor As %ZEN.Datatype.string [ InitialExpression = "#F0F0F0" ];

/// style of widgets border, e.g. solid, dashed, dotted
Property widgetBordersStyle As %ZEN.Datatype.string [ InitialExpression = "solid" ];

/// width of widgets border 
Property widgetBordersWidth As %ZEN.Datatype.string [ InitialExpression = "1" ];

/// Localized title of the currently displayed dashboard.
Property dashboardTitleLocal As %ZEN.Datatype.string;

/// Description of the currently displayed dashboard.
Property dashboardDescription As %ZEN.Datatype.string;

/// Locked state of the currently displayed dashboard.
Property dashboardLocked As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Public state of the currently displayed dashboard.
Property dashboardPublic As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true, the dashboard uses the new snapGrid desktop and ignores the
/// the <property>dashboardSnapTo</property> property.
Property dashboardSnapGrid As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Is dashboard in "snap to" mode.
Property dashboardSnapTo As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Is dashboard uses snap grid, then this is then number of grid rows.
Property dashboardGridRows As %ZEN.Datatype.integer [ InitialExpression = 2 ];

/// Is dashboard uses snap grid, then this is then number of grid columns.
Property dashboardGridCols As %ZEN.Datatype.integer [ InitialExpression = 2 ];

/// Does this dashboard allow the user to move and resize widgets.
Property dashboardResize As %ZEN.Datatype.boolean(ZENURL = "RESIZE") [ InitialExpression = 1 ];

/// Does this dashboard allow the user to modify widgets.
Property dashboardModify As %ZEN.Datatype.boolean(ZENURL = "MODIFY") [ InitialExpression = 1 ];

/// Keywords for the currently displayed dashboard.
Property dashboardKeywords As %ZEN.Datatype.string;

/// Owner of the currently displayed dashboard.
Property dashboardOwner As %ZEN.Datatype.string;

/// Resource for the currently displayed dashboard.
Property dashboardResource As %ZEN.Datatype.string;

/// Book cover spec of the currently displayed dashboard.
Property dashboardBookCover As %ZEN.Datatype.string;

/// Category for the currently displayed dashboard.
Property dashboardCategory As %ZEN.Datatype.string;

/// Current user name.
Property userName As %ZEN.Datatype.string(MAXLEN = 160) [ InitialExpression = {$UserName} ];

/// If true, user cannot modify the current dashboard.
Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Instance of dashboard definition.
Property %dashboard As %DeepSee.Dashboard.Definition(XMLPROJECTION = "none");

/// If true, show alert message to trace filter events.
Property trace As %ZEN.Datatype.boolean(ZENURL = "TRACE") [ InitialExpression = 0 ];

/// If true, widgets display a title bar.
Property showTitleBar As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Specify opacity of title bars.
Property titleBarOpacity As %ZEN.Datatype.float(XMLPROJECTION = "attribute");

/// Specify color of title bars.
Property titleBarColor As %ZEN.Datatype.color(XMLPROJECTION = "attribute");

/// Specify opacity of title bars for selected widgets.
Property selectedTitleBarOpacity As %ZEN.Datatype.float(XMLPROJECTION = "attribute");

/// Specify color of title bar for selected widgets.
Property selectedTitleBarColor As %ZEN.Datatype.color(XMLPROJECTION = "attribute");

/// Specify color of title bar text.
Property titleBarTextColor As %ZEN.Datatype.color(XMLPROJECTION = "attribute");

/// Specify color of title bar text for selected widgets.
Property selectedTitleBarTextColor As %ZEN.Datatype.color(XMLPROJECTION = "attribute");

/// Specify font of title bar text
Property titleBarFont As %ZEN.Datatype.string(XMLPROJECTION = "attribute");

/// Copy of db settings saved for this dashboard.
Property dbsettings As %ZEN.Datatype.string [ Internal, MultiDimensional ];

/// This is used when launching a dashboard from an email alert.
Property nonce As %ZEN.Datatype.string(ZENURL = "NONCE");

/// Track any activeWhen values for widget controls.
Property activeWhenArray As array Of %ZEN.Datatype.string [ Internal ];

/// Key of selected widget.
Property currWidgetKey As %ZEN.Datatype.string [ Internal ];

/// Name used to save a widget to the catalog!
Property widgetTemplateName As %ZEN.Datatype.string;

/// Description of the widget (if any). Used for save to catalog.
Property widgetDescription As %ZEN.Datatype.string;

/// Widget owner. Used for save to catalog.
Property widgetOwner As %ZEN.Datatype.string(MAXLEN = 255);

/// Widget resource. Used for save to catalog.
Property widgetResource As %ZEN.Datatype.string(MAXLEN = 255);

/// Keywords of the saved widget (if any). Used for save to catalog.
Property widgetKeywords As %ZEN.Datatype.string;

/// Container for the current save mode for source control.
Property saveAction As %ZEN.Datatype.string;

/// If the dashboard is in multi-print mode, there is master widget which defines the
/// page margins and other overall settings in the pdf report. This property is the container
/// for the reference to that widget.
Property printMasterWidgetId As %ZEN.Datatype.string;

/// Container for the page size when printing widgets in multi-print mode.
Property printPageSize As %ZEN.Datatype.string [ InitialExpression = "8.5x11 in" ];

/// Container for the page orientation when printing widgets in multi-print mode.
Property printPageOrientation As %ZEN.Datatype.string [ InitialExpression = "portrait" ];

/// Container for the page's left margin when printing widgets in multi-print mode.
Property printMarginLeft As %ZEN.Datatype.string [ InitialExpression = "0.5in" ];

/// Container for the page's right margin when printing widgets in multi-print mode.
Property printMarginRight As %ZEN.Datatype.string [ InitialExpression = "0.5in" ];

/// Container for the page's top margin when printing widgets in multi-print mode.
Property printMarginTop As %ZEN.Datatype.string [ InitialExpression = "0.5in" ];

/// Container for the page's bottom margin when printing widgets in multi-print mode.
Property printMarginBottom As %ZEN.Datatype.string [ InitialExpression = "0.5in" ];

/// When creating multiple temp files, a token is generated that is unique to the
/// CSP session. Temporary files incoporate this token to avoid concurrency problems.
Property tempFileToken As %ZEN.Datatype.string;

/// Debugging property. Setting this to true will prevent the pdf viewer from deleting
/// temporary files used for printing when launched.
Property pdfPreserveTempFiles As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Indicates whether or not the page had to generate widget names on load.
Property widgetNamesAdded As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">

body {
	visibility: hidden;
}

#desktop {
	width: 800px;
	height: 550px;
	background: none;
}

#contentsLeft {
	width: 280px;
}

a.radioSetCaption {
	font-size: 12px;
	vertical-align: middle;
}

.zenLabel {
	font-size: 11px;
	color: #404040;
}

.svgFrame {
	border: none;
}

.EmptyMsg {
	padding: 20px;
	font-size: 20px;
	color: #808080;
}

.dragGroup {
	background: #F0F0F0;
	border: 1px solid #F0F0F0;
	overflow: hidden;
}

.dragChildren {
	overflow: hidden; 
}

.zenDesktopGhostPane {
	border: solid #F0F0FD 1px;
	background: #F8F8FD;
}

.dbName {
	font-size: 12px;
}

.dbTitle {
}

.dsActionButton {
	margin-left: 4px;
	color: #E0E0E0;
	background: rgb(53,107,141);
	border-radius: 2px;
	border: 1px solid black;
}

.dsActionButton:hover {
	background: rgb(53,107,141);
	color: white;
	background-image: url(portal/button_hover.png);
	background-repeat: repeat-x;
}

.dsActionButtonDisabled {
	margin-left: 4px;
	color: #808080;
	background: #D0D0D0;
	border-radius: 2px;
	border: 1px solid #808080;
}

/* !!! */
.ztb-menuBar {
	background: rgb(53,107,141);
	filter: none;
}

.ztb-menuItemSelected-1 {
	background: rgb(242,246,248); /* Old browsers */
	/* IE9 SVG, needs conditional override of 'filter' to 'none' */
	background: url(data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiA/Pgo8c3ZnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgdmlld0JveD0iMCAwIDEgMSIgcHJlc2VydmVBc3BlY3RSYXRpbz0ibm9uZSI+CiAgPGxpbmVhckdyYWRpZW50IGlkPSJncmFkLXVjZ2ctZ2VuZXJhdGVkIiBncmFkaWVudFVuaXRzPSJ1c2VyU3BhY2VPblVzZSIgeDE9IjAlIiB5MT0iMCUiIHgyPSIwJSIgeTI9IjEwMCUiPgogICAgPHN0b3Agb2Zmc2V0PSIwJSIgc3RvcC1jb2xvcj0iI2YyZjZmOCIgc3RvcC1vcGFjaXR5PSIxIi8+CiAgICA8c3RvcCBvZmZzZXQ9IjUwJSIgc3RvcC1jb2xvcj0iI2Q4ZTFlNyIgc3RvcC1vcGFjaXR5PSIxIi8+CiAgICA8c3RvcCBvZmZzZXQ9IjUxJSIgc3RvcC1jb2xvcj0iI2I1YzZkMCIgc3RvcC1vcGFjaXR5PSIxIi8+CiAgICA8c3RvcCBvZmZzZXQ9IjEwMCUiIHN0b3AtY29sb3I9IiNlMGVmZjkiIHN0b3Atb3BhY2l0eT0iMSIvPgogIDwvbGluZWFyR3JhZGllbnQ+CiAgPHJlY3QgeD0iMCIgeT0iMCIgd2lkdGg9IjEiIGhlaWdodD0iMSIgZmlsbD0idXJsKCNncmFkLXVjZ2ctZ2VuZXJhdGVkKSIgLz4KPC9zdmc+);
	background: -moz-linear-gradient(top,  rgba(242,246,248,1) 0%, rgba(216,225,231,1) 50%, rgba(181,198,208,1) 51%, rgba(224,239,249,1) 100%); /* FF3.6+ */
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,rgba(242,246,248,1)), color-stop(50%,rgba(216,225,231,1)), color-stop(51%,rgba(181,198,208,1)), color-stop(100%,rgba(224,239,249,1))); /* Chrome,Safari4+ */
	background: -webkit-linear-gradient(top,  rgba(242,246,248,1) 0%,rgba(216,225,231,1) 50%,rgba(181,198,208,1) 51%,rgba(224,239,249,1) 100%); /* Chrome10+,Safari5.1+ */
	background: -o-linear-gradient(top,  rgba(242,246,248,1) 0%,rgba(216,225,231,1) 50%,rgba(181,198,208,1) 51%,rgba(224,239,249,1) 100%); /* Opera 11.10+ */
	background: -ms-linear-gradient(top,  rgba(242,246,248,1) 0%,rgba(216,225,231,1) 50%,rgba(181,198,208,1) 51%,rgba(224,239,249,1) 100%); /* IE10+ */
	background: linear-gradient(to bottom,  rgba(242,246,248,1) 0%,rgba(216,225,231,1) 50%,rgba(181,198,208,1) 51%,rgba(224,239,249,1) 100%); /* W3C */
	filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#f2f6f8', endColorstr='#e0eff9',GradientType=0 ); /* IE6-8 */
	border-bottom: 1px solid rgb(242,246,248);
	border-top-left-radius: 10px;
	border-top-right-radius: 10px;
}

</style>
}

/// This XML defines the menu for this page.
XData menuPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen"
xmlns:deepsee="http://www.intersystems.com/deepsee">
<!-->DTB250 - add svg image provider component<-->
<deepsee:deepseeSvgImageProvider id="svgUtil"/>
<deepsee:deepseeCSVProvider id="csvUtil"/>
<timer id="autosaveTimer" ontimeout="zenPage.runAutosave();" timeout="2000"/>
<csMenuBar id="mainMenu" width="100px">
<csMenuBarItem caption="Menu">
<contextMenu id="fileMenu">
<csMenuItem id="newDashboard" caption="New Dashboard" title="Create a new dashboard" onclick="zenPage.newDashboard();" />
<csMenuItem id="openDashboard" caption="Find Dashboard..." title="View a different dashboard" onclick="zenPage.openDashboard();"  />
<csMenuItem id="deleteDashboard" caption="Delete Dashboard" title="Delete this dashboard" onclick="zenPage.deleteDashboard();"  />
<csMenuSeparator/>
<csMenuItem id="saveSettings" caption="Save My Settings" title="Save current settings such as widget positions and filter choices" onclick="zenPage.saveSettings(); alert('Settings saved.'); zenPage.setModified(false);"/>
<csMenuItem id="clearSettings" caption="Clear My Settings" title="Clear local settings and return this dashboard to its original state" onclick="zenPage.clearSettings(); alert('Settings cleared.');"/>
<!-->WAL123<-->
<csMenuItem id="clearAutosaveState" caption="Clear Autosave State" title="Clear local settings and return this dashboard to its original state" onclick="zenPage.clearAutosaveState(); alert('Autosave state cleared.');"/>
<!-->WAL123<-->
<csMenuSeparator/>
<csMenuItem id="saveDashboard" caption="Save" title="Save this dashboard" onclick="zenPage.saveDashboard(false);"/>
<csMenuItem id="saveDashboardOptions" caption="Save With Options..." title="Show the save dialog for this dashboard" onclick="zenPage.saveDashboard(true);"/>
<csMenuItem id="saveDashboardAs" caption="Save As..." title="Save a copy of this dashboard" onclick="zenPage.saveCopyOfDashboard();"/>
<csMenuItem id="addToFavorites" caption="Add To Favorites" title="Add this dashboard to the favorites list" onclick="zenPage.addThisToFavorites();"/>
<csMenuItem id="editBookCover" caption="Design Book Cover" title="Design a book cover for this dashboard" onclick="zenPage.designBookCover();"/>
<csMenuSeparator/>
<csMenuItem id="newWidget" caption="Add New Widget..." title="Add a new visual widget to this dashboard" onclick="zenPage.newWidget();"/>
<csMenuItem id="addFromCatalog" caption="Add Widget From Catalog..." title="Add a widget from the catalog to this dashboard" onclick="zenPage.addWidgetFromCatalog();"  />
<csMenuItem id="saveToCatalog" caption="Save Widget To Catalog..." title="Save the selected widget to the widget catalog " onclick="zenPage.saveWidgetToCatalog();" />
<csMenuItem id="saveToTheme" caption="Save Widget To Theme..." title="Save the selected widget to the theme catalog" onclick="zenPage.saveWidgetToTheme();" />
<csMenuSeparator/>
<csMenuItem id="analyzer" caption="Analyzer" title="Go to the Analyzer" onclick="zenPage.gotoAnalyzer();" />
<csMenuSeparator/>
<csMenuItem id="email" caption="Email Dashboard" title="Email this dashboard" onclick="zenPage.mailDashboard();" />
<csMenuItem id="alert" caption="Send Alert" title="Send an alert to another user" onclick="zenPage.sendAlert();" />
<csMenuSeparator/>
<csMenuItem id="worklists" caption="Hide/Show Worklists" title="Hide or show the worklist for this page" onclick="zenPage.toggleWorklists();" />
 </contextMenu>
 </csMenuBarItem>
</csMenuBar>
</pane>
}

/// This XML defines the main display area.
XData contentsRightPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">

<!-- definition of this dashboard -->
<jsonProvider id="jsonDbDefinition" OnGetTargetObject="GetDbDefinition" OnSubmitContent="SubmitDashboardDef"/>

<!-- set of available widgets -->
<jsonProvider id="jsonWidgetTypeList" OnGetArray="GetWidgetTypeList"/>

<!-- misc. list of options -->
<jsonProvider id="jsonOptionList" OnGetArray="GetOptionList">
<parameter id="jsonOptionWhich" paramName="which"/> 
<parameter id="jsonOptionSpec" paramName="spec"/> 
<parameter id="jsonOptionSettings" paramName="settings"/>
</jsonProvider>

<!-- dashboard contents get loaded here: width is reset later -->
<group id="desktopGroup" width="500" height="200" layout="none"/>
</pane>
}

/// Translate encrypted URL parameters
ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	If $D(%request.Data("XDASHBOARD",1)) {
		Set %request.Data("DASHBOARD",1) = ##class(%CSP.Page).Decrypt($G(%request.Data("XDASHBOARD",1)))
	}
	If $D(%request.Data("XSETTINGS",1)) {
		Set %request.Data("SETTINGS",1) = ##class(%CSP.Page).Decrypt($G(%request.Data("XSETTINGS",1)))
	}
	If $D(%request.Data("XEMBED",1)) {
		Set %request.Data("EMBED",1) = ##class(%CSP.Page).Decrypt($G(%request.Data("XEMBED",1)))
	}
	If $D(%request.Data("XWORKLISTS",1)) {
		Set %request.Data("WORKLISTS",1) = ##class(%CSP.Page).Decrypt($G(%request.Data("XWORKLISTS",1)))
	}
	Quit 1
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		// DTB646 - check privileges
		Do CheckPortalUseAccess^%qdsUtils()
		$$$dsTrackFeature("DashboardViewer")		// DTB393

		Set tWrite = $$CheckPortalWriteAccess^%qdsUtils()
		If ('tWrite) {
			Set ..canWrite = 0
		}
		Set ..readOnly = 0	
		
		// make sure soft modals are on
		Set ..useSoftModals = 1

		Set tSC = ##super()
		If $$$ISERR(tSC) Quit

		// Remove email menu item if not enabled
		Set tMailEnabled = +$G(^DeepSee.UserPortalSettings("MailEnabled"))
		If ('tMailEnabled) {
			Set tMenu = ..%GetComponentById("email")
			If $IsObject(tMenu) {
				Do tMenu.parent.%RemoveChild(tMenu)
			}
		}
		Else {
			// set flag to indicate how email is sent
			If (tMailEnabled = 2) {
				Set ..useClientEmail = 1
			}
			Else {
				Set ..useClientEmail = 0
			}
		}

		// pull out URL settings
		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetSettingsFromURL(.tSettings)
		If $$$ISERR(tSC) Quit

		// audit
		If (..dashboardName'="") {
			Set tSC = ##class(%DeepSee.Utils).%RunServerAuditCode(..dashboardName)
			If $$$ISERR(tSC) Quit
		}

		// JMD1276 get pivot variable default values from url
		// organized by target name
		New %dsPivotVariables
		Set tTarget = $O(tSettings(""))
		While (tTarget'="") {
			If $D(tSettings(tTarget,"VARIABLE")) {
				Set tPivotVar = tSettings(tTarget,"VARIABLE")
				For p = 1:1:$L(tPivotVar,"~") {
					Set tSpec = $P(tPivotVar,"~",p)
					If (tSpec'="") {
						Set tVarName = $$$LOWER($P(tSpec,".",1))
						Set tVarValue = $P(tSpec,".",2,999)
						If (tVarName'="") {
							Set %dsPivotVariables(tTarget,tVarName) = tVarValue
						}
					}
				}
			}
			Set tTarget = $O(tSettings(tTarget))
		}
		
		// + WAL116 -- move this up from original location
		// + WAL053
		If ($G(^DeepSee.UserPortalSettings("autosaveUserPortal")) && (..autosave="")) {	
			Set ..autosave = $UserName
		}
		If ((..autosave = $UserName) || ($$$UPPER(..autosave) = "$USERNAME")) {
			Set ..autosave = "Autosave:"_$UserName
		}
		// - WAL053
		// - WAL116

		// + WAL108 -- if autosave, load the dashboard with the autosave name
		//             only if the dashboard actually exists
		Set tLoadDashboardName = ..dashboardName
		If (..autosave'="") {
			Set tLoadDashboardName = ..tempStorageRoot_..autosave_"/"_tLoadDashboardName
						
			// + WAL108
			Set ..dashboardName = $E(tLoadDashboardName,$L(..tempStorageRoot)+1,*)
			Set ..dashboardName = $E(..dashboardName,$L(..autosave)+2,*)
			// - WAL108	
			
			Set tExists = ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(tLoadDashboardName)
			If ('tExists) {
				Set tLoadDashboardName = ..dashboardName
			}
		}
		// - WAL108
								
		// load the dashboard
		//Set tSC = ..%LoadDashboard(.tDashboard,..dashboardName)
		Set tSC = ..%LoadDashboard(.tDashboard,tLoadDashboardName) // WAL108
		If $$$ISERR(tSC) Quit

		// DTB441 - Remember if a dashboard was actually requested, and if it was loaded
		Set tDashboardRequested = (..dashboardName'="")
		Set tDashboardLoaded = $IsObject(tDashboard)

		// JMD1202
		If '$IsObject(tDashboard) {
			Set tDashboard = ##class(%DeepSee.Dashboard.Definition).%New()
			Set tDashboard.snapGrid = 1
		}

		Set ..%dashboard = tDashboard
		
		// make sure new props default correctly
		If (tDashboard.showTitleBar="") {
			Set tDashboard.showTitleBar = 1
		}

		If ((+..noModify)) {
			Set ..readOnly = 1
		}

		// check privileges
		Do CheckFolderUseAccess^%qdsUtils(tDashboard)
		
		Set tWrite = $$CheckFolderWriteAccess^%qdsUtils(tDashboard)
		If ('tWrite||('..canWrite)) {
			Set ..readOnly = 1
		}
		
		If ..IsSourceControlReadOnly(..GetInternalName()) {
			Set ..readOnly=2		// DTB646
		}

		If ('$$CheckAnalyzerViewAccess^%qdsUtils()) {
			Set tMenu = ..%GetComponentById("analyzer")
			If $IsObject(tMenu) {
				Do tMenu.parent.%RemoveChild(tMenu)
			}
		}

		If ('..canWrite) {
			Set tMenu = ..%GetComponentById("newDashboard")
			If $IsObject(tMenu) {
				Do tMenu.parent.%RemoveChild(tMenu)
			}
		}

		// Remove edit/save menu items if read-only
		If (..readOnly) {
			Set editOptions = $listbuild("deleteDashboard","saveDashboard","saveDashboardAs","saveDashboardOptions","addFromCatalog","addWidget","newWidget","editBookCover","saveToCatalog","saveToTheme")
			For i=1:1:$listlength(editOptions) {
				Do ..removeMenuOption($list(editOptions, i))
			} 
			
			// no navigator for read-only
			Set tNavigator = ..%GetComponentById("navigator")
			If $IsObject(tNavigator) {
				Set tNavigator.hidden = 1
			}
		}

		// DTB471 - Examine the dashboard definition to see if any widgets need to have names added.
		// If any names were automatically assigned communicate that to the client for user notification.
		Set tSC = ##class(%DeepSee.UserPortal.Utils).AddWidgetNames(tDashboard,.tNewWidgetNames)
		If $$$ISERR(tSC) Quit
		Set ..widgetNamesAdded = $D(tNewWidgetNames)

		// if we are here because of an alert, clear its new flag
		If (..alertId'="") {
			Set tAlert = ##class(%DeepSee.UserPortal.Data.Alert).%OpenId(..alertId)
			If $IsObject(tAlert) {
				Set tAlert.isNew = 0
				Do tAlert.%Save()
			}
		}

		If $IsObject(tDashboard) {
			Set tSC = ##class(%DeepSee.UserLibrary.Utils).%RegisterRecentItem("dashboard",tDashboard.fullName)
			If $$$ISERR(tSC) Quit

			// see if there are any dashboard settings saved for this dashboard
			If (""'=tDashboard.fullName) {
				Set tUser = $S(..nonce="":$UserName,1:..nonce)
				
				// + WAL053
				If (..autosave '= "") { 
					Set tUser = ..autosave 
								
					// WAL108 -- send in the $Temp name of the dashboard instead of the 
					//           actual name
					If ($E(tDashboard.fullName,1,5)'="$Temp") {
						Set tLoadDashboardName = ..tempStorageRoot_..autosave_"/"_tDashboard.fullName
					}
				}
				Else {
					Set tLoadDashboardName = tDashboard.fullName	
				}
				
				// - WAL053
								
				// WAL108 -- the autosave dashboard doesn't exist yet the settings will just be empty
				Set tSC = ##class(%DeepSee.UserPortal.Utils).%LoadDashboardSettings(.tDBSettings,tLoadDashboardName,tUser)
				If $$$ISERR(tSC) Quit
				
				// + WAL187 -- give the "master" dashboard a chance to override the autosave dashboard if necessary
				//             ..dashboardName contains the name of the master dashboard
				If (..autosave'="") {
					Set tOriginalUserName = $S(..nonce="":$UserName,1:..nonce)
					Set tSC = ##class(%DeepSee.UserPortal.Utils).%LoadDashboardSettings(.tOriginalDBSettings,..dashboardName,tOriginalUserName)
					If $$$ISERR(tSC) Quit

					Set tTimestamp = $G(tOriginalDBSettings("timestamp"))
					Set tClearSettingsTimestamp = $G(tOriginalDBSettings("clearSettingsTimestamp"))
					If (tTimestamp > tClearSettingsTimestamp) {
						If (+$G(^DeepSee.AutosaveSettingsTimestamp(..dashboardName,..autosave)) < tTimestamp) {
							// These are the two types of settings:
							// Set pSettings(tKey,"controls",tControl.aux,"value") = tControl.value
							// Set pDBSettings(tKey,"homeRowL") = $P(tWidget.widgetLayout,":",2)
							Set tWidgetIdx = $O(tOriginalDBSettings(""))
							While (tWidgetIdx'="") {
								Set tSettingIdx = $O(tOriginalDBSettings(tWidgetIdx,""))
								While (tSettingIdx'="") {
									// If there is a setting in the original dashboard and not in the autosave version, use the original setting
									If (($G(tOriginalDBSettings(tWidgetIdx,tSettingIdx))'="")) { // && ($G(tDBSettings(tWidgetIdx,tSettingIdx))="")
										Set tDBSettings(tWidgetIdx,tSettingIdx) = tOriginalDBSettings(tWidgetIdx,tSettingIdx)	
									}
									If (tSettingIdx="controls") {
										Set tControlIdx = $O(tOriginalDBSettings(tWidgetIdx,tSettingIdx,""))
										While (tControlIdx'="") {
											// If there is a setting in the original dashboard and not in the autosave version, use the original setting
											If (($G(tOriginalDBSettings(tWidgetIdx,tSettingIdx,tControlIdx,"value"))'="")) { //  && ($G(tDBSettings(tWidgetIdx,tSettingIdx,tControlIdx,"value"))="")
												Set tDBSettings(tWidgetIdx,tSettingIdx,tControlIdx,"value") = tOriginalDBSettings(tWidgetIdx,tSettingIdx,tControlIdx,"value")
											}
											Set tControlIdx = $O(tOriginalDBSettings(tWidgetIdx,tSettingIdx,tControlIdx))	
										}
									}
									Set tSettingIdx = $O(tOriginalDBSettings(tWidgetIdx,tSettingIdx))
								}
								Set tWidgetIdx = $O(tOriginalDBSettings(tWidgetIdx))
							}
						}
						Set ^DeepSee.AutosaveSettingsTimestamp(..dashboardName,..autosave) = tTimestamp
					}
					ElseIf (tClearSettingsTimestamp > tTimestamp) {
						If (+$G(^DeepSee.AutosaveSettingsTimestamp(..dashboardName,..autosave)) < tClearSettingsTimestamp) {
							Kill tDBSettings	
						}
						Set ^DeepSee.AutosaveSettingsTimestamp(..dashboardName,..autosave) = tClearSettingsTimestamp
					}
				}
				// - WAL187
			}
		}
		Else {
			// use new item to pick up any default values
			Set tDashboard = ##class(%DeepSee.Dashboard.Definition).%New()
			Set tDashboard.snapGrid = 1
			//Set tDashboard.backgroundColor = "white" // JSL4479 (done in InitialExpression and onload)
		}

		// indicate presence of local settings in menu
		// DTB431 - Check for presence of actual settings when deciding whether or not to disable the Clear My Settings option.
		Merge tDBSettingsActual = tDBSettings
		Kill tDBSettingsActual("clearSettingsTimestamp")
		If '$D(tDBSettingsActual) {
			Set tMenu = ..%GetComponentById("clearSettings")
			If $IsObject(tMenu) {
				Set tMenu.disabled = 1
			}
		}
		
		// + WAL123 -- this is how you disable a menu item
		If ((..autosave="") || ($E(tDashboard.fullName,1,6) '= "$Temp/")) {
			Set tMenu = ..%GetComponentById("clearAutosaveState")
			If $IsObject(tMenu) {
				Set tMenu.disabled = 1
			}	
		}
		// - WAL123

		If ('..readOnly) {
			// see if there are widgets in the catalog
			Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetWidgetTemplateList(.tWList,.tWCount,1)
			If $$$ISERR(tSC) Quit

			If ($G(tWCount)=0) {
				Set tMenu = ..%GetComponentById("addFromCatalog")
				If $IsObject(tMenu) {
					Set tMenu.disabled = 1
				}
			}
		}

		// get original value of name and locked
		Set ..dashboardName = tDashboard.fullName
		Set ..dashboardLocked = tDashboard.locked
		
		// WAL108 -- transform the dashboard name back to the name of the original
		//           dashboard so the user doesn't see this as an autosave dashboard
		If ((..autosave'="") && ($E(tDashboard.fullName,1,6) = "$Temp/")) {
			Set tRootLength = $L(..tempStorageRoot)
			Set ..dashboardName = $E(tDashboard.fullName,tRootLength+1,*)
			Set ..dashboardName = $E(..dashboardName,$L(..autosave)+2,*)
		}
		// WAL108

		// localized copy of title
		Set ..dashboardTitleLocal = ##class(%DeepSee.UserPortal.Utils).%ResolveText(tDashboard.title)

		// copies of other properties
		Set ..dashboardTitle = tDashboard.title
		Set ..dashboardKeywords = tDashboard.keywords
		Set ..dashboardDescription = tDashboard.description
		Set ..dashboardPublic = tDashboard.public
		Set ..worklistCount = tDashboard.worklistCount
		Set ..dashboardOwner = tDashboard.owner
		Set ..dashboardBookCover = tDashboard.%GetCoverSpec()
		Set ..dashboardCategory = tDashboard.category
		Set ..dashboardSnapTo = $S(tDashboard.snapTo="":1,1:tDashboard.snapTo)
		Set ..dashboardSnapGrid = $S(tDashboard.snapGrid="":0,1:tDashboard.snapGrid)
		Set ..dashboardResource = tDashboard.resource
		Set ..showTitleBar = $S(tDashboard.showTitleBar="":1,1:tDashboard.showTitleBar)
		
		// + WAL101
		Set ..titleBarColor = tDashboard.titleBarColor
		Set ..titleBarOpacity = tDashboard.titleBarOpacity
		Set ..selectedTitleBarColor = tDashboard.selectedTitleBarColor
		Set ..selectedTitleBarOpacity = tDashboard.selectedTitleBarOpacity
		Set ..titleBarTextColor = tDashboard.titleBarTextColor
		Set ..selectedTitleBarTextColor = tDashboard.selectedTitleBarTextColor
		Set ..titleBarFont = tDashboard.titleBarFont
		// - WAL101

		// JMD1186
		Set ..companyName = tDashboard.companyName
		Set ..companyLogo = tDashboard.companyLogo
		Set ..companyStyle = tDashboard.companyStyle

		// JMD1084: If URL turns these off, they stay off!
		Set:..dashboardModify ..dashboardModify = $S(tDashboard.canModify="":1,1:tDashboard.canModify)
		Set:..dashboardResize ..dashboardResize = $S(tDashboard.canResize="":1,1:tDashboard.canResize)

		Set ..dashboardGridRows = $S(tDashboard.gridRows="":2,1:tDashboard.gridRows)
		Set ..dashboardGridCols = $S(tDashboard.gridCols="":2,1:tDashboard.gridCols)

		// JSL4482: Allow settable widget borders
		Set ..widgetBorders = tDashboard.widgetBorders // JSL4482
		Set ..widgetBordersToggle = tDashboard.widgetBordersToggle // JSL4482
		Set ..widgetBordersColor = tDashboard.widgetBordersColor // JSL4482
		Set ..widgetBordersStyle = tDashboard.widgetBordersStyle // JSL4482
		Set ..widgetBordersSwitch = tDashboard.widgetBordersSwitch // JSL4482
		Set ..widgetBordersWidth = tDashboard.widgetBordersWidth // JSL4482

		If $D(tDBSettings("worklistCount")) {
			Set ..worklistCount = +$G(tDBSettings("worklistCount"))
		}

		If ((..urlWorklistCount'="")&&(+..urlWorklistCount>=0)&&(+..urlWorklistCount<=2)) {
			Set ..worklistCount = ..urlWorklistCount
		}

		// callback
		Set tGroup = ..%GetComponentById("worklistDiv1Group")
		Set tSC = ..%OnCreateControls(tDashboard,tGroup)
		If $$$ISERR(tSC) Quit

		// create desktop component
		Set tDesktopGroup = ..%GetComponentById("desktopGroup")

		// !!! Add toolbar if needed
		If (0) {
			Set tToolbar = ##class(%ZEN.Component.toolbar).%New()
			Set tToolbar.id = "toolbar"
			Set tToolbar.ongetdata = "return zenPage.getToolbarData();"
			Set tSC = tDesktopGroup.%AddChild(tToolbar)
			If $$$ISERR(tSC) Quit
		}

		// JMD996
		If (..dashboardSnapGrid) {
			Set tDesktop = ##class(%ZEN.Component.snapGrid).%New()
			Set tDesktop.rows = tDashboard.gridRows
			Set tDesktop.cols = tDashboard.gridCols
			Set:+(tDesktop.rows)<=0 tDesktop.rows = 2
			Set:+(tDesktop.cols)<=0 tDesktop.cols = 2
		}
		Else {
			If (..dashboardSnapTo) {
				Set tDesktop = ##class(%ZEN.Component.desktop).%New()
			}
			Else {
				Set tDesktop = ##class(%ZEN.Component.corkboard).%New()
			}
		}
		Set tDesktop.id = "desktop"
		Set tSC = tDesktopGroup.%AddChild(tDesktop)
		If $$$ISERR(tSC) Quit

		// attach unselect event to background
		// !!! conflicts with headerDrag
		Set tDesktopGroup.onclick="zenPage.widgetSelected(zenEvent,'');"

		// load widgets
		If $IsObject(tDesktop) {
			Set tWidgetCount = tDashboard.widgets.Count() // + WAL168
			If ((tWidgetCount = 0)&&(..autosave="")) {    // + WAL168
				// nothing to show
				Set tHTML = ##class(%ZEN.Component.html).%New()
				If ('tDashboardRequested) {
					Set tHTML.content = "<div class=""EmptyMsg"">"_$$$Text("No Dashboard has been selected.")_"<br/>"_$$$Text("Use the menu to create a new dashboard or to find an existing one.","%DeepSee")_"</div>"
				}
				ElseIf (tDashboardRequested&&'tDashboardLoaded) {
					// DTB441 - User tried to load a dashboard but couldn't
					Set tHTML.content = "<div class=""EmptyMsg"">"_$$$Text("The requested dashboard does not exist or you do not have permission to view it.","%DeepSee")_"<br/>"_$$$Text("Use the menu to create a new dashboard or to find an existing one.","%DeepSee")_"</div>"
				}
				Else {
					Set tHTML.content = "<div class=""EmptyMsg"">"_$$$Text("This dashboard is empty.")_"<br/>"_$$$Text("Use the menu to add widgets to the dashboard.","%DeepSee")_"</div>"
				}
				Do tDesktopGroup.%AddChild(tHTML)
				Set tDesktop.hidden = 1
			}
			Else {
				Set tSC = ..%CreateWidgets(tDashboard,tDesktop,.tSettings,.tDBSettings,.tAddedWidget)
				// + WAL168 -- handle case where new dashboard is in autosave mode
				//             This case means the neither the autosave nor actual dashboard have
				//             any widgets -- we need to check with the actual dashboard in the case
				//             of autosave before concluding this (tAddedWidget)
				If ((..autosave'="")&&(tWidgetCount=0)&('tAddedWidget)) {
					Set tHTML = ##class(%ZEN.Component.html).%New()
					If ('tDashboardRequested) {
						Set tHTML.content = "<div class=""EmptyMsg"">"_$$$Text("No Dashboard has been selected.","%DeepSee")_"<br/>"_$$$Text("Use the menu to create a new dashboard or to find an existing one.","%DeepSee")_"</div>"
					}
					ElseIf (tDashboardRequested&&'tDashboardLoaded) {
						// DTB441 - User tried to load a dashboard but couldn't
						Set tHTML.content = "<div class=""EmptyMsg"">"_$$$Text("The requested dashboard does not exist or you do not have permission to view it.","%DeepSee")_"<br/>"_$$$Text("Use the menu to create a new dashboard or to find an existing one.","%DeepSee")_"</div>"
					}
					Else {
						Set tHTML.content = "<div class=""EmptyMsg"">"_$$$Text("This dashboard is empty.","%DeepSee")_"<br/>"_$$$Text("Use the menu to add widgets to the dashboard.","%DeepSee")_"</div>"
					}
					Do tDesktopGroup.%AddChild(tHTML)
					Set tDesktop.hidden = 1
				}
				// - WAL168
				If $$$ISERR(tSC) Quit
			}
		}

		// DTB355 - Create a session-derived token for use in temp files
		Set ..tempFileToken = $ZCRC(%session.%Id(),7)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Helper method to remove a menu option.
/// Used to remove edit/save options in read-only mode.
Method removeMenuOption(option As %String)
{
	Set tMenu = ..%GetComponentById(option)
	If $IsObject(tMenu) {
		Do tMenu.parent.%RemoveChild(tMenu)
	}
}

/// Return list of options for work list 1.
Method %OnGetWorklistOptions1(Output pOptions, Output pDefaultMode) As %Status
{
	// $LB(name,class)
	// N.B., Filters are always in workgroup 1
	Set pOptions($I(k)) = $LB("filters","%DeepSee.UserPortal.FilterList")
	Set pDefaultMode = "filters"

	If +$G(^DeepSee.UserPortalSettings("Worklist")) {
		Set n = $O(^DeepSee.UserPortalSettings("Worklist","DashboardViewer",1,""))
		While (n'="") {
			// $LB(name,class)
			Set pOptions($I(k)) = $LB("option"_n,^DeepSee.UserPortalSettings("Worklist","DashboardViewer",1,n))
			Set n = $O(^DeepSee.UserPortalSettings("Worklist","DashboardViewer",1,n))
		}	
	}
	If (..alertId'="") {
		Set pOptions($I(k)) = $LB("alertInfo","%DeepSee.UserPortal.AlertInfo")
	}

	Quit $$$OK
}

/// Return list of options for work list 2.
Method %OnGetWorklistOptions2(Output pOptions, Output pDefaultMode) As %Status
{
	Set pDefaultMode = ""
	If +$G(^DeepSee.UserPortalSettings("Worklist")) {
		Set n = $O(^DeepSee.UserPortalSettings("Worklist","DashboardViewer",2,""))
		While (n'="") {
			// $LB(name,class)
			Set pOptions($I(k)) = $LB("option"_n,^DeepSee.UserPortalSettings("Worklist","DashboardViewer",2,n))
			Set:pDefaultMode="" pDefaultMode = "option"_n
			Set n = $O(^DeepSee.UserPortalSettings("Worklist","DashboardViewer",2,n))
		}	
	}
	Else {
		Quit ##super(.pOptions,.pDefaultMode)
	}
	Quit $$$OK
}

/// Open (or create) an instance of dashboard definition that defines the contents
/// of this dashboard.
Method %LoadDashboard(Output pDashboard As %DeepSee.Dashboard.Definition, pDashboardName As %String) As %Status
{
	Set pDashboard = ""
	Set tSC = $$$OK
	Try {
		Set pDashboard = ##class(%DeepSee.Dashboard.Utils).%OpenDashboard(pDashboardName,.tSC)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set pDashboard = ""
	}

	Quit tSC
}

/// Create the dashboard widgets and add them to the desktop.<br/>
/// <var>pURLSettings</var> is an array of settings values pulled out of the URL.<br/>
/// <var>pDBSettings</var> is an array of saved dashboard settings values.
Method %CreateWidgets(pDashboard As %DeepSee.Dashboard.Definition, pDesktop As %ZEN.Component.desktop, ByRef pURLSettings As %String, ByRef pDBSettings As %String, ByRef pAddedWidget As %String) As %Status
{
	Set tSC = $$$OK
	Set tHasPortlets = 0
	Try {
		New %tKeyToWidget
		If ($IsObject(pDashboard)) {
			Set tGroup = ..%GetComponentById("worklistDiv1Group")

			// build index of widget names to dataSources (for links)
			// and index of names to widget number
			Set tAllNames = ""
			
			// + WAL153 -- If autosave dashboard has one fewer widget, insert widget from master
			//             definition into autosave definition before rendering the page
			Set pAddedWidget = 0 // + WAL168
			If ($E(pDashboard.fullName,1,6)="$Temp/") {
				Set tMasterDashboardName = $E(pDashboard.fullName,$L(..tempStorageRoot_..autosave_"/")+1,*)
				Set tMasterDashboard = ##class(%DeepSee.Dashboard.Utils).%OpenDashboard(tMasterDashboardName,.tSC)
				If $IsObject(tMasterDashboard) {
					If (tMasterDashboard.widgets.Count()=(pDashboard.widgets.Count()+1)) {
						Do pDashboard.widgets.Insert(tMasterDashboard.widgets.GetAt(tMasterDashboard.widgets.Count()))
						Do pDashboard.%Save()
						Set pAddedWidget = 1 // + WAL168
					}	
				}
			}
			// - WAL153
			
			Set tWidgetCount = pDashboard.widgets.Count()
			For n = 1:1:tWidgetCount {
				Set tWidgetDef = ..%dashboard.widgets.GetAt(n)

				// make sure new props default correctly
				If (tWidgetDef.showToolbar="") {
					Set tWidgetDef.showToolbar = 1
				}

				Set tWidgetName = tWidgetDef.name
				Set:tWidgetName="" tWidgetName = "$widget"_n
				If (tWidgetName'="") {
					// Nothing prevents 2 widgets with the same name!
					Set tWidgetIndex(tWidgetName,n) = ""
					
					// +DTB111 - make note of the existence of any portlets
					If (tWidgetDef.type="portlet") {
						Set tHasPortlets = 1
					}
					// -DTB111
					
					Set tAllNames = tAllNames _ $S(tAllNames="":"",1:",") _ tWidgetName
					Set tDataSourceIndex(tWidgetName) = tWidgetDef.%GetDataSource()
				}
			}
			
			// get list of FILTERS from URL organized by target name
			Set tTarget = $O(pURLSettings(""))
			While (tTarget'="") {
				If $D(pURLSettings(tTarget,"FILTER")) {
					Set tURLFilter = pURLSettings(tTarget,"FILTER")
					For p = 1:1:$L(tURLFilter,"~") {
						Set tSpec = $P(tURLFilter,"~",p)
						If (tSpec'="") {
							// pull spec into spec(s) and value(s)
							Do ..%ParseFilterSpec(tSpec,.tFSpec,.tFKey,.tFValue)
							If ($D(tFSpec)) {
								Set k = $O(tFSpec(""))
								While (k'="") {
									// keys for MDX, value for KPI!
									Set tURLFilterList(tTarget,$$$UPPER($G(tFSpec(k)))) = $S($G(tFKey(k))="":$G(tFValue(k)),1:$G(tFKey(k)))
									Set k = $O(tFSpec(k))
								}
							}
						}
					}
				}
		
				// +DTB111 - if portlets exist on the dashboard, prepare any settings defined in the URL
				If (tHasPortlets&&$D(pURLSettings(tTarget,"PORTLET"))) {
					Set tURLPortletSettings(tTarget) = pURLSettings(tTarget,"PORTLET")
				}
				// -DTB111
				Set tTarget = $O(pURLSettings(tTarget))
			}

			// build list of all filters
			// as well as list of controls that belong on the dashboard
			For n = 1:1:tWidgetCount {
				// + WAL189 -- see if kpi-based widget has default filter values
				Set tDataSource = $S(tWidgetDef.localDataSource'="":tWidgetDef.localDataSource,1:tWidgetDef.dataSource)
				Set tDataSourceType = $$$LOWER($P(tDataSource,".",$L(tDataSource,".")))
				If (tDataSourceType="kpi") {
					Set tName = $P(tDataSource,".",1,$L(tDataSource,".")-1)
					Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
					
					If (tKPIClass'="") {
						Kill tKPIFilterList
						// get list of filters to see which allow multi-select
						Set tSC = $zobjclassmethod(tKPIClass,"%GetFilterList",.tKPIFilterList)
						If $$$ISERR(tSC) Quit
						Set k = $O(tKPIFilterList(""))
						While (k'="") {
							Set tFilterName = $LG(tKPIFilterList(k),1)
							Set tMulti = +$LG(tKPIFilterList(k),4)
							Set tDefault = $LG(tKPIFilterList(k),7) // WAL189 -- default filter value // WAL189 (2) remove +
							Set tFilterMulti(tFilterName) = tMulti
							Set tFilterDefault(tFilterName) = tDefault // WAL189
							Set k = $O(tKPIFilterList(k))
						}
					}	
				}
				// - WAL189
				
				Set tWidgetDef = ..%dashboard.widgets.GetAt(n)
				Set tWidgetName = tWidgetDef.name
				Set:(tWidgetDef.key="") tWidgetDef.key = $ZCRC(tWidgetName,7)		// DTB544 - Failsafe in case the widget doesn't have a key yet
				Set:tWidgetName="" tWidgetName = "$widget"_n
				Set tControlCount = tWidgetDef.controls.Count()
				For c = 1:1:tControlCount {
					Set tControlDef = tWidgetDef.controls.GetAt(c)
					Set tFilterName = tControlDef.targetProperty
					Set tFilterDefault = ""

					If (tFilterName'="") {
						// set default value for filter from control definition
						Set tFilterValue = tControlDef.value
						
						// + WAL189 -- if the control doesn't define a default filter value, check to see if the kpi class does
						If ((tDataSourceType="kpi") && (tFilterValue="")) {
							Set tFilterValue = $G(tFilterDefault(tFilterName))
						}
						// - WAL189

						If ($E(tFilterValue)="@") {
							// user-defined setting
							Set tFilterValue = $E(tFilterValue,2,$L(tFilterValue))
							Set tFilterValue = ##class(%DeepSee.UserPortal.Utils).%GetUserSetting(tFilterValue)
							Set tFilterDefault = tFilterValue
						}

						// check for overrides saved in DBSettings
						If ((tWidgetDef.key'="")&&(tControlDef.controlKey'="")) {
							If ($D(pDBSettings(tWidgetDef.key,"controls",tControlDef.controlKey,"value"))) {
								// user-defined setting
								Set tFilterValue = $G(pDBSettings(tWidgetDef.key,"controls",tControlDef.controlKey,"value"))
							}
						}

						// !!! click event !!!
						If ((tControlDef.action = "applyFilter")||
							(tControlDef.action = "setFilter") ||
							(tControlDef.action = "")) {
								
							Set tTargetList = tControlDef.target
							Set:tTargetList="" tTargetList = tWidgetName
							
							// + WAL043 (2)
							If ($D(tURLFilterList("*",$$$UPPER(tFilterName)))) {
								Set tFilterValue = tURLFilterList("*",$$$UPPER(tFilterName))
								Set tAppliedStarFilters($$$UPPER(tFilterName),tTargetList) = ""
							}
							// Specific target overrides "*"
							If ($D(tURLFilterList(tTargetList,$$$UPPER(tFilterName)))) {
								Set tFilterValue = tURLFilterList(tTargetList,$$$UPPER(tFilterName))
								Kill tURLFilterList(tTargetList,$$$UPPER(tFilterName))
							}
							// - WAL043 (2)

							Set:tTargetList="*" tTargetList = tAllNames

							If (tTargetList="") {
								// target refers to owner and owner has no name
								Set tFilterSet(n,tFilterName) = tFilterValue
								Set:tFilterDefault'="" tFilterDefault(n,tFilterName) = tFilterDefault
							}
							Else {
								For t = 1:1:$L(tTargetList,",") {
									Set tTarget = $P(tTargetList,",",t)
									// there could be a space within the list
									Set:tTarget="" tTarget = tWidgetName
									If (tTarget'="") {
										Set idx = $O(tWidgetIndex(tTarget,""))
										While (idx'="") {
											Set tFilterSet(idx,tFilterName) = tFilterValue
											Set:tFilterDefault'="" tFilterDefault(idx,tFilterName) = tFilterDefault
											Set idx = $O(tWidgetIndex(tTarget,idx))
										}
									}
									Else {
										// target refers to owner and owner has no name
										Set tFilterSet(n,tFilterName) = tFilterValue
										Set:tFilterDefault'="" tFilterDefault(n,tFilterName) = tFilterDefault
									}
								}
							}
						}
					} // filterName
				}
				
				// +DTB111 - add URL settings to portlets
				If (tWidgetDef.type="portlet") {
					// Add star (*) settings to this widget
					Set tPortletSettings = $G(tURLPortletSettings("*"))
					For ii=1:1:$L(tPortletSettings,"~") {
						Set tPortletSetting = $P(tPortletSettings,"~",ii)
						Do tWidgetDef.properties.SetAt($P(tPortletSetting,".",2),$P(tPortletSetting,".",1))
					}
					
					// Add settings specifically targeting this widget
					Set tPortletSettings = $G(tURLPortletSettings(tWidgetName))	// DTB123 - use normalized tWidgeName
					For ii=1:1:$L(tPortletSettings,"~") {
						Set tPortletSetting = $P(tPortletSettings,"~",ii)
						Do tWidgetDef.properties.SetAt($P(tPortletSetting,".",2),$P(tPortletSetting,".",1))
					}
				}
				// -DTB111
			}
			
			// + WAL043 (2)
			// Kill applied star filters so they aren't applied as general filters
			Set tFSpec = $O(tAppliedStarFilters(""))
			While (tFSpec '="") {
				Kill tURLFilterList("*",tFSpec)
				Set tFSpec = $O(tAppliedStarFilters(tFSpec))
			}
			// - WAL043 (2)

			// add widgets to page
			For n = 1:1:tWidgetCount {
				Set tWidgetDef = ..%dashboard.widgets.GetAt(n)

				// place settings for this widget in dbsettings
				Kill ..dbsettings
				If (tWidgetDef.key'="") {
					Merge ..dbsettings = pDBSettings(tWidgetDef.key)
				}

				// JMD1074 apply localDataSource from settings
				If ($G(..dbsettings("localDataSource"))'="") {
					Set tWidgetDef.localDataSource = ..dbsettings("localDataSource")
				}

				// resolve data linkage, if any: override local datasource
				If (tWidgetDef.dataLink'="") {
					Set tWidgetDef.localDataSource = $G(tDataSourceIndex(tWidgetDef.dataLink))
				}

				// create actual widget from definition
				Set tSC = tWidgetDef.%CreateVisualWidget(.tWidget,.pURLSettings)
				If $$$ISERR(tSC) Quit

				// anything left in the tURLFilter list is general filter without a control
				// place this in the "click filter" spec!
				Set tGeneralFilter = ""
				Set kc = 0
				Set kt = $O(tURLFilterList(""))
				While (kt'="") {
					If ((kt="*")||(kt=tWidgetDef.name)) {
						Set kf = $O(tURLFilterList(kt,""))
						While (kf'="") {
							Set kc = kc + 1
							// keys are already escaped
							Set kv = $S(($E(tURLFilterList(kt,kf),1)="&"):tURLFilterList(kt,kf),1:"["_tURLFilterList(kt,kf)_"]")
							Set tGeneralFilter = tGeneralFilter _ $S(tGeneralFilter="":"",1:",") _ kf _ "." _ kv
							Set kf = $O(tURLFilterList(kt,kf))
						}
					} 
					Set kt = $O(tURLFilterList(kt))
				}
				Set:kc>1 tGeneralFilter = "("_tGeneralFilter_")"

				Set tWidget.clickFilterSpec = tGeneralFilter

				// local list of widgets
				Set tWidgetList(n) = tWidget

				Set tWidget.id = "$widget_" _ n

				// JMD996: turn off move and resize if needed
				If ('..dashboardResize) {
					Set tWidget.moveEnabled = 0
					Set tWidget.resizeEnabled = 0
				}

				// if no name, use the id
				Set:tWidget.name="" tWidget.name = tWidget.id
		
				// select handler for widget
				Set tWidget.onwindowgrab = "zenPage.widgetSelected(zenEvent,'"_tWidget.widgetKey_"');"

				// See if we have a cube name
				Set tCubeName = ""
				If ($D(tFilterSet(n))) {
					Set tDS = tWidgetDef.localDataSource
					Set:tDS="" tDS = tWidgetDef.dataSource
					If (tDS '= "") {
						If ($P(tDS,".",$L(tDS,"."))="pivot") {
							Set tPivot = ""
							If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(tDS)) {
								// DTB580 - Only set the folder item if we know it exists
								Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tDS,.tSC)
								If $$$ISERR(tSC) Quit
							}
							If $IsObject(tPivot) {
								// ignore missing pivot: deal with it further on
								Set tCubeName = tPivot.%GetCubeName()
							}
						}
					}
				}
				// apply filter state to the widget
				// make sure there is a filter entry for every control connected
				// to this widget
				Set f = $O(tFilterSet(n,""))
				While (f'="") {
					Set tKey = $G(tFilterSet(n,f))
					Do tWidget.filterState.SetAt(tKey,f)
					Set tText = tKey
					// get display name for key
					If ((tCubeName'="")&&(tKey'="")) {
						// tKey could be a range of 2 values
						For q = 1:1:$L(tKey,":") {
							Set tfSC = ##class(%DeepSee.Utils).%GetLevelNameForKey(tCubeName,f,$P(tKey,":",q),.tText2)
							If $$$ISOK(tfSC) {
								Set tText = $S(q>1:tText_":"_tText2,1:tText2)
							}
							Quit:q>=2
						}
					}
					ElseIf ((tDS'="")&&(tKey'="")) {
						// get display name for filter key from KPI
						Kill tXFilters
						Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetMembersForFilter(tDS,f,.tXFilters)
						If $$$ISERR(tSC) Quit

						Set a = $O(tXFilters(""))
						While (a'="") {
							If ($LG(tXFilters(a),2)=tKey) {
								Set tText = $LG(tXFilters(a),1)
								Quit
							}
							Set a = $O(tXFilters(a))
						}
					}
					Do tWidget.filterText.SetAt(tText,f)
					Do tWidget.filterDefault.SetAt($G(tFilterDefault(n,f)),f)
					Set f = $O(tFilterSet(n,f))
				}

				// copy saved filters settings into widget
				Set tFSpec = ""
				Set tFValue = tWidgetDef.filterState.GetNext(.tFSpec)
				While (tFSpec '= "") {
					If (tFValue'="") {
						Do tWidget.filterState.SetAt(tFValue,tFSpec)
					}
					Set tFValue = tWidgetDef.filterState.GetNext(.tFSpec)
				}

				Set tKey = tWidget.widgetKey

				// local index of names to keys
				If ((tKey'="")&&(tWidget.name'="")) {
					Set tNameToKey(tWidget.name) = tKey
					Set %tKeyToWidget(tKey) = tWidget
				}
				// index used to point linked widgets to their master
				If ((tKey'="")&&(tWidgetDef.dataLink'="")) {
					Set tLinkList(tKey,tWidgetDef.dataLink) = tWidget
				}

				// create common controls within dashboard itself
				If ($IsObject(tGroup)) {
					Set tSC = ..%CreateControls("dashboard",tWidgetDef.controls,tGroup,tWidget)
					If $$$ISERR(tSC) Quit
				}

				// apply overrides from DBsettings
				If (tKey'="") {
					Set:$G(pDBSettings(tKey,"width"))'="" tWidgetDef.width = $G(pDBSettings(tKey,"width"))
					Set:$G(pDBSettings(tKey,"height"))'="" tWidgetDef.height = $G(pDBSettings(tKey,"height"))
					Set:$G(pDBSettings(tKey,"top"))'="" tWidgetDef.top = $G(pDBSettings(tKey,"top"))
					Set:$G(pDBSettings(tKey,"left"))'="" tWidgetDef.left = $G(pDBSettings(tKey,"left"))

					Set:$G(pDBSettings(tKey,"colSpanL"))'="" tWidgetDef.colSpanL = $G(pDBSettings(tKey,"colSpanL"))
					Set:$G(pDBSettings(tKey,"rowSpanL"))'="" tWidgetDef.rowSpanL = $G(pDBSettings(tKey,"rowSpanL"))
					Set:$G(pDBSettings(tKey,"homeRowL"))'="" tWidgetDef.homeRowL = $G(pDBSettings(tKey,"homeRowL"))
					Set:$G(pDBSettings(tKey,"homeColL"))'="" tWidgetDef.homeColL = $G(pDBSettings(tKey,"homeColL"))
					Set:$G(pDBSettings(tKey,"maximized"))'="" tWidgetDef.maximized = $G(pDBSettings(tKey,"maximized"))
				}

				If (..dashboardSnapGrid) {
					// JMD1044: use specific properties for snap grid
					Set:tWidgetDef.homeRowL'="" tWidget.homeRow = tWidgetDef.homeRowL
					Set:tWidgetDef.homeColL'="" tWidget.homeCol = tWidgetDef.homeColL
					Set:tWidgetDef.colSpanL'="" tWidget.colSpan = tWidgetDef.colSpanL
					Set:tWidgetDef.rowSpanL'="" tWidget.rowSpan = tWidgetDef.rowSpanL
					Set:tWidgetDef.maximized'="" tWidget.maximized = tWidgetDef.maximized
					Set tMaxRows = 30
					Set tMaxCols = 30
					If (+tWidget.rowSpan<1) { Set tWidget.rowSpan = 1 }
					If (+tWidget.colSpan<1) { Set tWidget.colSpan = 1 }
					If (+tWidget.rowSpan>tMaxRows) { Set tWidget.rowSpan = 1 }
					If (+tWidget.colSpan>tMaxCols) { Set tWidget.colSpan = 1 }
					If (+tWidget.homeRow>tMaxRows) { Set tWidget.homeRow = 0 }
					If (+tWidget.homeCol>tMaxCols) { Set tWidget.homeCol = 0 }
				}
				Else {
					Set:tWidgetDef.width'="" tWidget.width = tWidgetDef.width
					Set:tWidgetDef.height'="" tWidget.height = tWidgetDef.height
					Set:tWidgetDef.width'="" tWidget.enclosingStyle = tWidget.enclosingStyle _ "width:"_tWidgetDef.width_"px;"
					Set:tWidgetDef.height'="" tWidget.enclosingStyle = tWidget.enclosingStyle _ "height:"_tWidgetDef.height_"px;"
					Set:tWidgetDef.top'="" tWidget.enclosingStyle = tWidget.enclosingStyle _ "top:"_tWidgetDef.top_"px;"
					Set:tWidgetDef.left'="" tWidget.enclosingStyle = tWidget.enclosingStyle _ "left:"_tWidgetDef.left_"px;"
					Set:tWidgetDef.maximized'="" tWidget.maximized = tWidgetDef.maximized
				}
				Set tSC = pDesktop.%AddChild(tWidget)
				If $$$ISERR(tSC) Quit
			}
			If $$$ISERR(tSC) Quit

			// creates links for linked widgets
			Set tKey = $O(tLinkList(""))
			While (tKey'="") {
				Set tName = $O(tLinkList(tKey,""))
				While (tName'="") {
					Set tSlave = tLinkList(tKey,tName)
					Set tMasterKey = $G(tNameToKey(tName))
					Set tSlave.linkWidgetKey = tMasterKey
					Set tName = $O(tLinkList(tKey,tName))
				}
				Set tKey = $O(tLinkList(tKey))
			}

			// apply filter values
			For n = 1:1:tWidgetCount {
				Set tWidget = $G(tWidgetList(n))
				If $IsObject(tWidget) {
					// if there are saved filter values, make sure they are applied
					Set tSC = tWidget.%ApplyFilters()
					If $$$ISERR(tSC) Quit
				}
			}
		}
		If $$$ISERR(tSC) Quit
		
		Set tSC = ..%OnCreateWidgets(pDashboard,pDesktop)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Kill %tKeyToWidget
	Quit tSC
}

/// Nofication that <method>%CreateWidgets</method> was called.
Method %OnCreateWidgets(pDashboard As %DeepSee.Dashboard.Definition, pDesktop As %ZEN.Component.desktop) As %Status
{
	Quit $$$OK
}

/// Utility method. Create a set of controls from the given list and add them to the given group.
/// <var>pWidget</var> is the name of the widget the controls are in.<br/>
/// If <var>pWhich</var> is "dashboard", then add the controls to the dashboard.<br/>
ClassMethod %CreateControls(pWhich As %String, pControls As %ListOfObjects, pGroup As %ZEN.Component.group, pWidget As %DeepSee.Component.Widget.widget = "") As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tIsDBViewer = 0

		// Copy over relevant portion of dbsettings
		If ($IsObject($G(%page))&&(%page.%IsA("%DeepSee.UserPortal.DashboardViewer"))) {
			Merge tDBSettings = %page.dbsettings("controls")
			Set tIsDBViewer = 1
			// !!! ok on refresh???
		}
		
		// + WAL083 (4) -- referenced later in the case of set/choose chart type controls
		do ##class(%DeepSee.Dashboard.Utils).%GetChartTypeInfo("%DeepSee.Component.Widget.pivot",.tChartTypeList)
		// - WAL083 (4)

		Set tPlaceOnWidget = (pWhich="widget")
		Set tDataSource = ""
		Set tCubeName = ""
		Set tWidgetName = ""
		If ($IsObject(pWidget) && $IsObject(pWidget.%definition)) {
			//Set tDataSource = pWidget.%definition.%GetDataSource()
			// JMD1128 definition *might* be a proxy object without this method!
			Set tDataSource = $S(pWidget.%definition.localDataSource'="":pWidget.%definition.localDataSource,1:pWidget.%definition.dataSource)
			Set tWidgetName = pWidget.name
		}

		// Get extension
		Set tDataSourceType = $$$LOWER($P(tDataSource,".",$L(tDataSource,".")))
		If ((tDataSourceType = "kpi")||(tDataSourceType = "metric")||(tDataSourceType = "worksheet")) {
			If (tDataSourceType = "kpi") {
				Set tName = $P(tDataSource,".",1,$L(tDataSource,".")-1)
				Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
			}
			ElseIf (tDataSourceType = "worksheet") {
				Set tKPIClass = "%DeepSee.KPIWorksheet"
			}
			Else {
				Set tKPIClass = "Ens.BusinessMetricKPI"
			}
			If (tKPIClass'="") {
				// get list of filters to see which allow multi-select
				Set tSC = $zobjclassmethod(tKPIClass,"%GetFilterList",.tFilterList)
				If $$$ISERR(tSC) Quit
				Set k = $O(tFilterList(""))
				While (k'="") {
					Set tFilterName = $LG(tFilterList(k),1)
					Set tMulti = +$LG(tFilterList(k),4)
					Set tDefault = $LG(tFilterList(k),7) // WAL189 -- default filter value // WAL189 (2) remove +
					Set tFilterMulti(tFilterName) = tMulti
					Set tFilterDefault(tFilterName) = tDefault // WAL189
					Set k = $O(tFilterList(k))
				}
			}
		}
		ElseIf ((tDataSourceType = "pivot")||(tDataSourceType = "cube")) {
			// JMD1276: me *may* need the cube name
			If (tDataSourceType = "pivot") {
				Set tPivot = ""
				If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(tDataSource)) {
					// DTB580 - Only set the folder item if we know it exists
					Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tDataSource,.tSC)
					If $$$ISERR(tSC) Quit
				}
				If $IsObject(tPivot) {
					Set tCubeName = $$$UPPER(tPivot.%GetCubeName())
				}
			}
			Else {
				Set tCubeName = $$$UPPER($P(tDataSource,".",1,$L(tDataSource,".")-1))
			}
		}

		If ($IsObject(pControls)) {
			// add controls to the group
			Set tControlCount = pControls.Count()
			For n = 1:1:tControlCount {
				Set tControlDef = pControls.GetAt(n)
				Set tDefaultValue = tControlDef.value
				Set:tControlDef.location="" tControlDef.location = "widget" // default

				If (tControlDef.location="click") {
					If $IsObject(pWidget) {
						if ('pWidget.clickTargets.Find(tControlDef.target)) { // JSL4444 - add this condition so one doesn't add to click target twice
							Do pWidget.clickTargets.Insert(tControlDef.target)
							Do pWidget.clickActions.Insert(tControlDef.action)
							Do pWidget.clickActive.Insert(tControlDef.activeWhen)		// DTB584
						}
						Do pWidget.clickTargetProperties.Insert(tControlDef.targetProperty)
					}
					Continue
				}

				Set tHidden = 0
				If (tPlaceOnWidget && (tControlDef.location'="widget")) {
					Continue
				}
				ElseIf ('tPlaceOnWidget && (tControlDef.location'="dashboard")) {
					Continue
				}

				// determine action and control type: apply defaults
				Set tAction = tControlDef.action
				Set:tAction="" tAction = "applyFilter"
				Set tType = tControlDef.type
				Set:tType="" tControlType = "auto"
				Set tLabel = tControlDef.label
				Set tLabelIcon = ""
				// JMD1118
				Set tTitle = ##class(%DeepSee.UserPortal.Utils).%ResolveText(tControlDef.title)
				Set tControlSize = tControlDef.size
				Set tControlReadOnly = tControlDef.readOnly

				If ($E(tLabel) = "@") {
					// name starting with "@" is name of user-defined icon
					Set tLabelIcon = ##class(%DeepSee.UserPortal.Utils).%GetUserIcon($E(tLabel,2,$L(tLabel)))
					Set tLabel = ""
				}
				Else {
					// JMD1118 localize label
					Set tLabel = ##class(%DeepSee.UserPortal.Utils).%ResolveText(tLabel)
				}

				Set tControl = ""
				Set tControlType = "select"
				Set tValueList = ""
				Set tDisplayList = ""
				Set tMultiSelect = 1

				If (tHidden) {
					Set tControlType = "hidden"
				}
				ElseIf (tType = "custom") {
					Set tControlType = "custom"
				}
				ElseIf (tType = "timer") {
					Set tControlType = "timer"
				}
				ElseIf (tType = "hidden") {
					Set tControlType = "hidden"
				}
				ElseIf (tType = "auto") {
					If (tAction = "applyFilter") {
						If ((tDataSourceType'="kpi")&&(tDataSourceType'="metric")&&(tDataSourceType'="worksheet")) {
							Set tControlType = "searchBox"
						}
						Else {
							Set tControlType = "searchBox"
							Set:tControlDef.targetProperty'="" tMultiSelect = $G(tFilterMulti(tControlDef.targetProperty))
						}
					}
					ElseIf (tAction = "setFilter") {
						If ((tDataSourceType'="kpi")&&(tDataSourceType'="metric")&&(tDataSourceType'="worksheet")) {
							Set tControlType = "searchBox"
						}
						Else {
							Set tControlType = "searchBox"
							Set:tControlDef.targetProperty'="" tMultiSelect = $G(tFilterMulti(tControlDef.targetProperty))
						}
					}
					ElseIf (tAction = "applyVariable") {
						// JMD1276
						Set tControlType = "searchBox"
						Set tMultiSelect = 0
						Set:tControlDef.size="" tControlSize = 5

						// figure out best type of control to use
						Set tPVarName = $P(tControlDef.targetProperty,".",2)
						If ((tCubeName'="")&&(tPVarName'="")) {

							Kill tVInfo
							Set tSC = ##class(%DeepSee.Utils).%GetPivotVariableInfo(tCubeName,tPVarName,.tVInfo)
							Set tVarType = $G(tVInfo("type"))
							Set tVSourceType = $G(tVInfo("sourceType"))
							Set tValueList = $G(tVInfo("valueList"))
							Set tDisplayList = $G(tVInfo("displayList"))
							If ((tValueList="")&&(tVSourceType="manual")&&(tVarType'="day")) {
								Set tControlType = "text"
								If ((tVarType'="string")&&(tVarType'="expression")) {
									Set:tControlDef.size="" tControlSize = 3
								}
							}
							// check for value passed in from URL
							Set tPVarName = $$$LOWER(tPVarName)
							If ($D(%dsPivotVariables("*",tPVarName))) {
								Set tDefaultValue = $G(%dsPivotVariables("*",tPVarName))
							}
							If ((tWidgetName'="")&&$D(%dsPivotVariables(tWidgetName,tPVarName))) {
								Set tDefaultValue = $G(%dsPivotVariables(tWidgetName,tPVarName))
							}
							// JMD1322: check for value saved in db settings
							// this overrides default and URL
							If (tControlDef.controlKey'="") {
								If $D(tDBSettings(tControlDef.controlKey,"value")) {
									Set tDefaultValue = $G(tDBSettings(tControlDef.controlKey,"value"))
								}
							}

							// JMD1322: make sure pivot table sees default value
							If (tDefaultValue'="") {
								Set %dsPivotVariables(tWidgetName,tPVarName) = tDefaultValue
							}
						}
					}
					ElseIf (tAction = "setDataSource") {
						// JMD1139
						Set tControlType = "button"
					}
					ElseIf ((tAction = "chooseDataSource")||(tAction = "chooseRowSpec")||(tAction = "chooseColumnSpec")) {
						// JMD1139
						Set tControlType = "select"
						
						Set tValueList = ""
						Set tDisplayList = ""

						// load list from termlist
						Set tTermList = tControlDef.targetProperty
						If (tTermList'="") {
							Set tTermList = $P(tTermList,".",1)
							Set tSC = ##class(%DeepSee.TermList).%GetValueArray(tTermList,.tArray)
							If $$$ISERR(tSC) Quit
							
							Set k = $O(tArray(""))
							While (k'="") {
								Set tValueList = tValueList_","_tArray(k)
								Set tDisplayList = tDisplayList_","_k
								Set k = $O(tArray(k))
							}
						}
					}
					ElseIf (tAction="printWidget") {
						// DTB251
						Set tControlType = "button"
					}
					Else {
						Set tControlType = "button"
					}
				}
				ElseIf (tType = "button") {
					Set tControlType = "button"
				}
				ElseIf (tType = "dropdown") {
					Set tControlType = "select"
				}
				ElseIf (tType = "radioSet") {
					Set tControlType = "radioSet"
				}
				ElseIf (tType = "searchBox") {
					Set tControlType = "searchBox"
				}

				// items that load from termlists
				If ((tAction = "chooseDataSource")||(tAction = "chooseRowSpec")||(tAction = "chooseColumnSpec")) {
					Set tValueList = ""
					Set tDisplayList = ""

					// load list from termlist
					Set tTermList = tControlDef.targetProperty
					If (tTermList'="") {
						Set tTermList = $P(tTermList,".",1)
						Set tSC = ##class(%DeepSee.TermList).%GetValueArray(tTermList,.tArray)
						If $$$ISERR(tSC) Quit
						
						Set k = $O(tArray(""))
						// DP-415309 - Omit leading blank from the chooseDataSource lists
						While (k'="") {
							Set tValueList = tValueList_$S(((tAction="chooseDataSource")&&'$L(tValueList)):"",1:",")_tArray(k)
							Set tDisplayList = tDisplayList_$S(((tAction="chooseDataSource")&&'$L(tDisplayList)):"",1:",")_k
							Set k = $O(tArray(k))
						}

						// DP-415309 - If the current data source is not in the completed chooseDataSource lists, add it
						If (tAction = "chooseDataSource")&&(tValueList'[tDataSource) {
							Set tValueList = tDataSource _ "," _ tValueList
							Set tDisplayList = $P(tDataSource,".",1,*-1) _"," _ tDisplayList
						}
					}
				}

				// pivot attributes override other settings
				If ((tAction = "setRowCount")||(tAction = "setColumnCount")) {
					If ((tType = "dropdown")||(tType="radioSet")) {
						Set tControlType = "select"
						Set tNums = "1,3,5,10,15,20,25,50,100"
						Set tValueList = ","_tNums
						Set tDisplayList = $$$Text("All")_","_tNums
					}
					Else {
						Set tControlType = $Case(tType,"hidden":"hidden",:"text")		// DTB791
						Set:tControlSize="" tControlSize = 3
					}
				}
				ElseIf ((tAction = "setRowSort")||(tAction = "setColumnSort")) {
					Set:tType'="radioSet" tControlType = "select"
					Set tValueList = ",BDESC,BASC"
					Set tDisplayList = $$$Text("Sort,Decreasing,Increasing")
				}
				// + WAL083 -- Here we are adding a control to the widget header or dashboard worklist
				//             "chooseChartType" actions show a dropdown list of chart types
				//             "setChartType" actions are not handled specifically because they are rendered as buttons (the default)
				ElseIf(tAction = "chooseChartType") {
					Set:tType'="radioSet" tControlType = "select"
					// tControlDef.targetProperty is a comma separated list of chart types
					Set tValueList = ","_tControlDef.targetProperty
					// + WAL083 (4) -- use the display list here so the dropdown shows the display name
					Set tTheseCharts = tControlDef.targetProperty
					Set:($G(tLabel)="") tLabel = $$$Text("Chart Type") // WAL083 (5) -- render a default label if one hasn't been defined
					If ($G(tTheseCharts)'="") {
						For i=1:1:$L(tTheseCharts,",") {
							Set tThisChart = $P(tTheseCharts,",",i)
							If (tThisChart = "table") {
								Set tDisplayName = $$$Text("Table") // WAL083 (5) -- switch from "Pivot Table" to "Table"
							}
							ElseIf ($G(tChartTypeList(tThisChart)) '= "") {
								Set tDisplayName = $LG(tChartTypeList(tThisChart),1)
							}	
							Set tDisplayList = $S($G(tDisplayList)'="":$G(tDisplayList)_","_tDisplayName,1:","_tDisplayName)
						}
					}
					Else {
						Set tDisplayList = tValueList	
					}
					// - WAL083 (4)
				}
				// - WAL083

				// Create the control
				// DTB834 - Initializa variables that might be tested later depending on type
				Set tClassName = ""
				Set tCustom = 0
				Set tControl = $$$NULLOREF
				If (tControlType = "custom") {
					// DTB834 - Custom controls may declare their type in order to take advantage 
					// of type-specific initialization to follow.
					Set tClassName = "%ZEN.Component.text"
					If (tControlDef.controlClass '= "") {
						Set tClassName = tControlDef.controlClass
						If (tClassName'[".") {
							Set tClassName = "%ZEN.Component." _ tClassName
						}
					}
					Set tControl = $zobjclassmethod(tClassName,"%New")
					If '$IsObject(tControl) {
						Set tSC = $$$ERROR($$$GeneralError,"Failed to create custom control: "_tClassName)
						$$$ThrowStatus(tSC)
					}
					
					// DTB834 - Custom control was successfuly instantiated, signal the initialization
					// for the specific type
					Set tCustom = 1
					$$$dsSafePropertyRef(tControl,"type",tTypeValue,tPropertyExists)		// DTB973 - Test the 'type' property without causing an error
					Set tControlType = $S((tPropertyExists&&(tTypeValue'="")):tTypeValue,tControl.%IsA("%ZEN.Component.button"):"button",1:"text")
				}
				
				If (tControlType = "timer") {
					Set:($G(tClassName)="") tClassName = "%ZEN.Component.timer"						// DTB834
					Set:('$IsObject(tControl)) tControl = $zobjclassmethod(tClassName,"%New")		// DTB834
					Set tControl.timeout = tControlDef.timeout * 1000
					If ($IsObject(pWidget) && pWidget.previewMode) {
						Set tControl.timeout = 0
					}
				}
				ElseIf (tControlType = "hidden") {
					Set:('$IsObject(tControl)) tControl = ##class(%ZEN.Component.hidden).%New()		// DTB834
					If (tControlDef.controlKey'="") {
						If $D(tDBSettings(tControlDef.controlKey,"value")) {
							Set tDefaultValue = $G(tDBSettings(tControlDef.controlKey,"value"))
						}
					}
				}
				ElseIf (tControlType = "text") {
					Set:('$IsObject(tControl)) tControl = ##class(%ZEN.Component.text).%New()		// DTB834
					If (tControlDef.controlKey'="") {
						If $D(tDBSettings(tControlDef.controlKey,"value")) {
							Set tDefaultValue = $G(tDBSettings(tControlDef.controlKey,"value"))
						}
					}
					Set tControl.readOnly = tControlReadOnly
					If ($IsObject(pWidget) && pWidget.previewMode) {
						Set tControl.readOnly = 1
					}
				}
				ElseIf ((tControlType = "select")||(tControlType = "radioSet")) {
					Set:tValueList="" tValueList = tControlDef.valueList
					Set:tDisplayList="" tDisplayList = tControlDef.displayList
					Set tDefaultFilterValue = ""

					If (((tAction="applyFilter")||(tAction="setFilter")||(tAction="applyVariable"))&&(tValueList="")) {
						/* get drop down list from data source */
						Set tValueList = ""
						Set tDisplayList = ""

						Kill tFilters
						Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetMembersForFilter(tDataSource,tControlDef.targetProperty,.tFilters,.tDefaultFilterValue)
						If $$$ISERR(tSC) Quit

						Set a = $O(tFilters(""))
						While (a'="") {
							Set tDisplayList = tDisplayList _ $S(tDisplayList="":"",1:",") _ $Replace($LG(tFilters(a),1),",","\,")
							Set tVal = $LG(tFilters(a),2)
							Set tValueList = tValueList _ $S(tValueList="":"",1:",") _ $Replace(tVal,",","\,")
							Set a = $O(tFilters(a))
						}
						Set:tDisplayList'="" tDisplayList = ","_tDisplayList
						Set:tValueList'="" tValueList = ","_tValueList
					}

					If (tControlType = "radioSet") {
						Set:('$IsObject(tControl)) tControl = ##class(%ZEN.Component.radioSet).%New()		// DTB834
						Set tControl.emptyCaption = $$$Text("Default")
					}
					Else {
						Set:('$IsObject(tControl)) tControl = ##class(%ZEN.Component.select).%New()		// DTB834
						Set tControl.showEmpty = 0
					}
					Set tControl.valueList = tValueList
					Set tControl.displayList = tDisplayList
					Set tControl.readOnly = tControlReadOnly
					// WAL025
					If (tAction="applyVariable") {
					}
					Else {
						If ($IsObject(pWidget) && (tControlDef.targetProperty'="")) {
							Set tDefaultValue = pWidget.filterState.GetAt(tControlDef.targetProperty)
						}

						If (tControlDef.controlKey'="") {
							If $D(tDBSettings(tControlDef.controlKey,"value")) {
								Set tDefaultValue = $G(tDBSettings(tControlDef.controlKey,"value"))
							}
						}
						Set:tDefaultValue="" tDefaultValue = tDefaultFilterValue
					}
				}
				ElseIf (tControlType = "searchBox") {
					Set tDefaultFilterValue = ""

					Set:('$IsObject(tControl)) tControl = ##class(%DeepSee.Component.searchBox).%New()		// DTB834
					Set tControl.editable = 1
					Set tControl.size = 10	// may get overridden below
					Set tControl.multiSelect = tMultiSelect
					Set tControl.dataSourceName = tDataSource
					Set tControl.filterName = tControlDef.targetProperty
					Set tControl.readOnly = tControlReadOnly
					Set tControl.valueRequired = tControlDef.valueRequired		// DTB140

					Set tControl.buttonTitle = tTitle

					// JMD1276
					Set tControl.valueList = tValueList
					Set tControl.displayList = tDisplayList

					// JMD900 !!! notify on kpi !!!
					If ($IsObject(pWidget) && (tDataSourceType'="XXXkpi") && (tDataSourceType'="metric") && (tDataSourceType'="worksheet")) {
						Set tControl.onshowdropdown = "zenPage.filterDropDown(zenThis,'"_$ZCVT(pWidget.widgetKey,"O","JS")_"','"_$ZCVT(tDataSource,"O","JS")_"');"
					}
					If ($IsObject(pWidget) && pWidget.previewMode) {
						Set tControl.previewMode = 1
					}

					If (tAction="applyVariable") {
					}
					Else {
						If ($IsObject(pWidget) && (tControlDef.targetProperty'="")) {
							Set tDefaultValue = pWidget.filterState.GetAt(tControlDef.targetProperty)
						}

						If (tControlDef.controlKey'="") {
							If $D(tDBSettings(tControlDef.controlKey,"value")) {
								Set tDefaultValue = $G(tDBSettings(tControlDef.controlKey,"value"))
							}
						}
						Set:tDefaultValue="" tDefaultValue = tDefaultFilterValue
					}
				}
				ElseIf (tControlType = "button") {		// DTB834 - Actually test for type "button"
					// button
					Set tIcon = ""
					If (tLabelIcon '= "") {
						Set tIcon = tLabelIcon
					}
					ElseIf (tLabel = "") {
						// use image, if possible
						Set tIcon = $Case(tControlDef.action,
							"refresh":"deepsee/ds2_refresh_44.png",
							"reloadDashboard":"deepsee/ds2_house_44.png",
							"showGeoListing":"deepsee/ds2_planet_44.png",
							"showListing":"deepsee/ds2_binoculars_44.png",
							"showIKnowMsrValue":"deepsee/ds2_radar_24.png",
							"showBreakdown":"deepsee/ds2_stats_44.png",
							"printWidget":"deepsee/ds2_printer_44.png",		// DTB251
							:"")
						// + WAL083 (4) -- if this is a set chart type action without a label,
						//                 see if we can find the image corresponding to the chart type
						//                 if we don't find the chart type, we'll see a button
						If (tAction = "setChartType") {
							Set tThisChart = tControlDef.targetProperty
							If (($G(tThisChart)'="") && ($G(tChartTypeList(tThisChart))'="")) {
								Set tIcon = $LG(tChartTypeList(tThisChart),3)	
							}
							Else {
								Set tIcon = ""
							}
						}
						// - WAL083 (4)
					}
					If (tIcon '= "") {
						Set:('$IsObject(tControl)) tControl = ##class(%ZEN.Component.image).%New()		// DTB834
						Set tControlType = "image"
						Set tControl.src = tIcon
					}
					Else {
						Set:('$IsObject(tControl)) tControl = ##class(%ZEN.Component.button).%New()		// DTB834
						Set tControl.controlClass = "dsActionButton"
						Set tControlType = "button"
						If ($IsObject(pWidget) && pWidget.previewMode) {
							Set tControl.disabled = 1
						}
					}
				}

				If $IsObject(tControl) {
					// stash key in aux property
					Set tControl.aux = tControlDef.controlKey

					// stash activeWhen info
					If (tIsDBViewer && (tControlDef.activeWhen'="")) {
						Do %page.activeWhenArray.SetAt(tControlDef.activeWhen,tControlDef.controlKey)
					}

					// apply size, if applicable
					If ((tControlSize'="")&&(tControl.%IsA("%ZEN.Component.text"))) {
						Set tControl.size = tControlSize
					}
					ElseIf ((tControlSize'="")&&(tControl.%IsA("%ZEN.Component.select"))) {
						Set tControl.controlStyle = tControl.controlStyle _ "width:"_tControlSize_"em;"
					}

					// add event handler
					Set tTarget = tControlDef.target
					Set tTargetProperty = tControlDef.targetProperty
					If ((tTarget = "")&&$IsObject(pWidget)) {
						// connect to containing widget
						Set tTarget = pWidget.name
					}
					// use dataBinding to track which action/target this control is bound to
					// map all filters to "filter"
					Set tBindType = $Case(tAction,"applyFilter":"filter","setFilter":"filter",:tAction)
					If (tControl.%IsA("%ZEN.Component.control")) {
						Set tControl.dataBinding = tBindType _ "/" _ tTargetProperty
					}
					Else {
						Set tControl.aux = tBindType _ "/" _ tTargetProperty
					}

					If (pWidget.previewMode) {
						Set tCode = ""
					}
					Else {
						Set tCode = "zenPage.dashboardEventHandler(zenPage.findWidgetByKey("_pWidget.widgetKey_"),'control',zenThis,'"_tAction_"','"_$ZCVT(tTarget,"O","JS")_"','"_$ZCVT(tTargetProperty,"O","JS")_"','"_$ZCVT($G(tVarType),"O","JS")_"');"
					}
					If ((tControlType = "button")||(tControlType = "image")) {
						Set tControl.onclick = tCode
					}
					ElseIf (tControlType = "timer") {
						Set tControl.ontimeout = tCode
					}
					ElseIf (tControlType '= "hidden") {
						Set tControl.onchange = tCode
					}

					If (pWhich="widget") {
						Set tControl.id = pWidget.id _ "/control/"_$S(tControlDef.name="":n,1:tControlDef.name)
					}
					Else {
						Set tControl.id = "control/"_$S(tControlDef.name="":n,1:tControlDef.name)_"/"_pWidget.id
					}
					If (tControlType = "button") {
						Set tControl.caption = tLabel
					}
					ElseIf ((tControlType = "text")||(tControlType = "select")||(tControlType = "radioSet")||(tControlType = "searchBox")) {
						Set tControl.label = tLabel
					}

					// if label is an icon; create an image for it
					If ((tLabelIcon '= "")&&(tControlType '= "image")) {
						Set tIconControl = ##class(%ZEN.Component.image).%New()
						Set tIconControl.src = tLabelIcon
						Set tIconControl.title = tTitle
						Set tSC = pGroup.%AddChild(tIconControl)
						If $$$ISERR(tSC) Quit
					}

					If (tControl.%IsA("%ZEN.Component.control")) {
						// WAL189 -- give kpi's a chance to pass their default values as defined in KPI class
						Set:((tDefaultValue="") && (tDataSourceType="kpi") && (tControlDef.targetProperty'="")) tDefaultValue = $G(tFilterDefault(tControlDef.targetProperty)) // WAL189 (2)
						Set:(tAction = "chooseDataSource") tDefaultValue = tDataSource		// DP-415309
						
						Set tControl.value = tDefaultValue
						Set tControl.name = tControlDef.action
						Set tControl.title = tTitle
					}
					Set tSC = pGroup.%AddChild(tControl)
					If $$$ISERR(tSC) Quit

					// register control index with widget
					If ($IsObject(pWidget)) {
						Do pWidget.controlIndices.Insert(tControl.index)
					}
				}
				If $$$ISERR(tSC) Quit
			}
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Nofication that <method>CreateControls</method> was called.
Method %OnCreateControls(pDashboard As %DeepSee.Dashboard.Definition, pGroup As %ZEN.Component.group) As %Status
{
	Quit $$$OK
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("DeepSee Dashboard")
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("DeepSee Dashboard")
}

/// Adjust sizes of content area.
ClientMethod onAdjustSizes(load, contentWidth, contentHeight) [ Language = javascript ]
{
	try {
		if (load) {
			this.updateCompanyCell(load);

			// turn off @^#*@& backspace key
			document.onkeydown = function (e) {
				e = e ? e : window.event;
				if (e && e.stopPropagation) {
					e.stopPropagation();
				}
				if ((e.keyCode==8 || e.keyCode==13) &&
					(e.target && e.target.tagName) &&
					(e.target.tagName != "TEXTAREA") && 
					(e.target.tagName != "INPUT")) { 
					return false;
				}
			};

			if ('' !==this.alertId) {
				// show alert info
				zenPage.setWorklistView('worklistDiv1','alertInfo','html');
			}
		}
		zenModalBackground = 'none';
		var desktopGroup = zen('desktopGroup');
		if (desktopGroup) {
			var desktopGroupDiv = desktopGroup.getEnclosingDiv();
			if (desktopGroupDiv) {		// DTB558
				desktopGroupDiv.style.height = contentHeight + 'px';
				desktopGroupDiv.style.width = contentWidth + 'px';
			}
		}

		var toolbarH = 0;
		var toolbar = zen('toolbar');
		if (toolbar) {
			var toolbarDiv = toolbar.getEnclosingDiv();
			if (toolbarDiv) {		// DTB558
 				toolbarDiv.style.width = contentWidth + 'px';
			}
			toolbarH = toolbarDiv.offsetHeight;
		}

		var desktop = zen('desktop');
		if (desktop) {
			var desktopDiv = desktop.getEnclosingDiv();
			if (desktopDiv) {		// DTB558
				desktopDiv.style.height = (contentHeight-toolbarH) + 'px';
				desktopDiv.style.width = contentWidth + 'px';
			}

			// set size of corkboard
			var resized = false;
			if (desktopDiv.firstChild) {
				desktopDiv.firstChild.style.position = 'relative';
				desktopDiv.firstChild.style.top = '0px';
				desktopDiv.firstChild.style.left = '0px';
			
				desktopDiv.firstChild.style.height = (contentHeight-toolbarH) + 'px';
				desktopDiv.firstChild.style.width = contentWidth + 'px';

				// JMD1053 force resize of desktop
				var mgr = desktopDiv.firstChild.engine;
				if (mgr && mgr.resize) {
					mgr.resize();
					resized = true;
				}
			}

			// JMD1269 avoid call to refresh
			if (desktop.forceRefresh && !resized) {
				desktop.forceRefresh();
			}
		}
		
		this.setTitleBar(this.showTitleBar);		// DTB447 - Always call this

		if (self.document.body) {		// DTB558
			self.document.body.style.visibility = 'visible';
		}

		// set maximized state of widget, if needed
		if (desktop) {
			for (var n = 0; n < desktop.children.length; n++) {
				var widget = desktop.children[n];
				if (widget && widget.getEnclosingDiv()) {
					if (!load) {
						// sync widget def to window
						// JMD1268 sync max state
						if (widget.getEnclosingDiv().maximized) {
							widget.maximized = true;
						}
						else {
							// JMD1337: if not max, then clear the flag
							widget.maximized = false;
						}
					}

					if (widget.maximize && widget.maximized) {
						// only one gets maximized
						widget.maximize(null);
						break;
					}
				}
			}
			if (desktop.broadcast) {
				desktop.broadcast('resize');
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onAdjustSizes');
	}
}

/// Expand or contract of navigator.
ClientMethod navExpand() [ Language = javascript ]
{
	// JMD1128: remember maximized state of widgets
	var desktop = zen('desktop');
	if (desktop) {
		for (var n = 0; n < desktop.children.length; n++) {
			var widget = desktop.children[n];
			if (widget && widget.maximize) {
				var div = widget.getEnclosingDiv();
				if (div) {
					widget.maximized = div.maximized ? true : false;
				}
			}
		}
	}

	this.onlayoutHandler(false);
}

/// For the given widget, return a list of all widgets linked to it.
ClientMethod getSlaveList(masterWidget) [ Internal, Language = javascript ]
{
	var slaveList = new Array();
	var desktop = zen('desktop');
	if (masterWidget && desktop) {
		for (var n = 0; n < desktop.children.length; n++) {
			var widget = desktop.children[n];
			if (widget && widget.controlEventHandler && widget.linkWidgetKey==masterWidget.widgetKey) {
				slaveList[slaveList.length] = widget;
			}
		}
	}
	return slaveList;
}

/// Central handler for control events on this dashboard.
/// This is called whenever a control is modified (or otherwise activated).
/// This is also called when a widget raises an event.<br/>
/// <var>sourceWidget</var> is the widget that raised the event.<br/>
/// <var>which</var> is either 'control' for controls or 'click' for click on widget element.
/// Return true if the event was handled.
ClientMethod dashboardEventHandler(sourceWidget, which, control, action, target, targetProperty, varType) [ Language = javascript ]
{
	// JMD1276: pass along "type" for variables
	varType = zenGet(varType);

	var value = '';
	var text = '';	// sometimes there is a display value to pass along
	this._sourceControl = null;
	if ('control'==which) {
		// *control* is the control that fired the event
		value = (control && control.getValue) ? control.getValue() : '';

		// jmd: special case for select control!
		if (control._type=='select') {
			text = control.getOptionText(control.getSelectedIndex());
		}
		else {
			text = (control && null!=control.text) ? control.text : value;
		}
		// make this control available to widgets
		this._sourceControl = control;

		// JMD1276: cast value according to type
		if (control instanceof _DeepSee_Component_searchBox) {
			// DTB568 - This only applies to searchBox
			switch(varType) {
			case 'number':
				value = parseFloat(value);
				value = isNaN(value) ? '' : value;
				control.setValue(value);
				break;
			case 'integer':
				value = parseInt(value,10);
				value = isNaN(value) ? '' : value;
				control.setValue(value);
				break;
			case 'year':
				value = parseInt(value,10);
				value = isNaN(value) ? '' : value;
				if (value && value.toString().length!=4) {
					value = '';
				}
				control.setValue(value);
				break;
			}
		}
	}
	else if ('click'==which) {
		// *control* is the value of the event
		value = (control) ? control : '$$$CLEAR';		// DTB648 - Add token to communicate to differentiate between an empty clickFilter and one being actively cleared
	}

	if (this.trace) {
		alert('Dashboard event dispatch:\n' + '\nWhich: '+ which + '\nAction: '+ action + '\nTarget: '+ target + '\nTargetProperty: '+ targetProperty + '\nValue: ' + value);
	}

	// loop over widgets; these are the children of the desktop.
	// split apart list of targets
	// build list of target widgets
	var widgetList = new Array();
	var targetList = target.toString().split(',');
	for (var t = 0; t < targetList.length; t++) {
		var targetVal = targetList[t];
		var targets = 0;
		var desktop = zen('desktop');
		if (desktop) {
			for (var n = 0; n < desktop.children.length; n++) {
				var widget = desktop.children[n];
				
				// JMD1021 sync max state of widget
				// JMD1176 test for encDiv
				if (widget && widget.getEnclosingDiv()) {
					widget.maximized = widget.getEnclosingDiv().maximized ? true : false; 
				}
				if (widget && widget.getEnclosingDiv() && (widget.name==targetVal||targetVal=='*') && widget.controlEventHandler) {
					widgetList[widgetList.length] = widget;
					targets++;
				}
			}
			if (targets==0 && targetVal!='*') {
				// notify user that nothing happened
				var msg = $$$FormatText($$$Text('No widget with the name \'%1\' was found so this action was not processed.'),targetVal);
				alert(msg);
				return false;
			}
		}
	}

	// invoke actions; check for dashboard-wide actions
	switch(action) {
	case 'newWindow':
	case 'navigate':
	case 'alert':
	case 'popup':
		var url = targetProperty;
		// apply substitutions to url
		// $$$VALUELIST = list of values for selected rows
		// $$$LISTINGIDS (deprecated-- use $$$VALUELIST)
		// $$$CURRVALUE = current value of widget (i.e., selected row)
		// $$$FILTERS = current value of widget filters: "filter:value~filter:value"

		// get subst values from first target widget
		if (widgetList[0]) {
			if (url.indexOf('$$$CURRVALUE')!=-1) {
				var CURRVALUE = widgetList[0].getParameterValue('CURRVALUE');
				url = url.replace(/\$\$\$CURRVALUE/g,CURRVALUE);
			}

			if (url.indexOf('$$$VALUELIST')!=-1) {
				var VALUELIST = widgetList[0].getParameterValue('VALUELIST');
				url = url.replace(/\$\$\$VALUELIST/g,VALUELIST);
			}

			if (url.indexOf('$$$LISTINGIDS')!=-1) {
				var VALUELIST = widgetList[0].getParameterValue('VALUELIST');
				url = url.replace(/\$\$\$LISTINGIDS/g,VALUELIST);
			}

			if (url.indexOf('$$$FILTERS')!=-1) {
				var FILTERS = widgetList[0].getParameterValue('FILTERS');
				// + WAL055
				// since list terminates with '~' last element of array is empty
				var filterList = decodeURIComponent(FILTERS).split('\n');  // WAL069 -- getParameterValue now uses default delimiters
				var outputFilterList = [];
				for (i=0;i < filterList.length; i++) {
					var filterInfo = filterList[i].split('\t');  // WAL069 -- getParameterValue now uses default delimiters
					if ((filterInfo[1] != '') && 'undefined' != typeof filterInfo[1]) {
						outputFilterList[outputFilterList.length] = filterInfo[0] + '.' + filterInfo[1];
					}
				}
				FILTERS = '';
				for (i=0;i < outputFilterList.length; i++) {
					if (i > 0) { FILTERS += '~'; }
					FILTERS += encodeURIComponent(outputFilterList[i]);
				}
				// - WAL055
				url = url.replace(/\$\$\$FILTERS/g,FILTERS);
			}
			
			// + WAL162 -- implement filter-like handling for pivot variables
			if (url.indexOf('$$$VARIABLES')!=-1) {
				var VARIABLES = widgetList[0].getParameterValue('VARIABLES');
				var variableList = decodeURIComponent(VARIABLES).split('\n');
				var outputVariableList = [];
				for (i=0;i < variableList.length; i++) {
					var variableInfo = variableList[i].split('\t');
					if ((variableInfo[1] != '') && 'undefined' != typeof variableInfo[1]) {
						outputVariableList[outputVariableList.length] = variableInfo[0] + '.' + variableInfo[1];
					}
				}
				VARIABLES = '';
				for (i=0;i < outputVariableList.length; i++) {
					if (i > 0) { VARIABLES += '~'; }
					VARIABLES += encodeURIComponent(outputVariableList[i]);
				}
				url = url.replace(/\$\$\$VARIABLES/g,VARIABLES);
			}
			// - WAL162
		}

		if ('navigate' == action) {
			zenPage.gotoPage(url);
		}
		else if ('newWindow' == action) {
			window.open(url,"_blank");
		}
		else if ('alert' == action) {
			// JMD1051
			alert(t.join(':'));
		}
		else if ('popup' == action) {
			// JMD1063
			zenLaunchPopupWindow(url,'ActionPopup','status,scrollbars,resizable=yes,width=800,height=600');
		}
		break;

	case 'viewDashboard':
		var url = this.viewerURL;
		if (''!=targetProperty) {
			url = url + ((url.indexOf('?')!=-1) ? '&' : '?') + 'DASHBOARD=' + encodeURIComponent(targetProperty);
		}
		zenPage.gotoPage(url);
		break;
	case 'printWidget':
		// DTB252 - Handle printing with an option to print multiple widgets 
		// to a single file
		
		// DTB574 - Prune widget list to include only printable widgets
		var len = widgetList.length;
		for (var n = 0; n < len; n++) {
			if (widgetList[n].exportPDF) {		// DTB570 - Change test
				widgetList.push(widgetList[n]);
			}
		}
		widgetList.splice(0,len);
		
		var multipleWidgets = (widgetList.length>1)
		zenPage.printMasterWidgetId = widgetList[0].id;
		
		var preserveTempFiles = (zenPage.pdfPreserveTempFiles);		// DTB252 - Use this to preserve merged temp files
		
		// Use the page's SVG image provider to merge xslfo output
		var svgUtil = zen('svgUtil');	
		var printKey = zenPage.tempFileToken;		// DTB355 - Use common token
		var targetFile = '';
		var sourceFiles = '';
		var mergedFile = svgUtil.makeSVGFileName('printMerge' + printKey + '.xsl');
		
		for (var n = 0; n < widgetList.length; n++) {
			widgetList[n].controlEventHandler(which,action,targetProperty,multipleWidgets,text);
			if (multipleWidgets) {
				if (0==n) {
					targetFile = svgUtil.makeSVGFileName(widgetList[n].id+'-print'+zenPage.tempFileToken+'.xsl');		// DTB355 - Add tempFilteToken to file name
				}
				else {
					sourceFiles = sourceFiles + (sourceFiles.length ? '||' : '') + svgUtil.makeSVGFileName(widgetList[n].id+'-print'+zenPage.tempFileToken+'.xsl');		// DTB355 - Add tempFilteToken to file names
				}
			}
		}
		
		if (multipleWidgets) {
			svgUtil.MergeXSLFiles(mergedFile,targetFile,sourceFiles);
			// Creat a randomized temp file name to prevent interference between separate requests
			var pdfName = 'printMerge' + printKey + '.pdf'
			var pdfFile = svgUtil.makeSVGFileName(pdfName);
			
			svgUtil.ConvertXSLToPDF(mergedFile,pdfFile);
			
			// Launch the viewer on pdfFile
			var url = '_DeepSee.UI.MDXPDF.zen';
			url = url + '?FILEPDFROOT=' + encodeURIComponent(pdfFile.split('.').slice(0,-1).join('.') || pdfFileName);
			if (preserveTempFiles) {
				url = url + '&$NODELETE=1';
			}
			
			var w = window.open(url,'pdf','');
			
			// DTB252 - Use the cleanup routines in the SVG image provider utility to 
			// remove individual widget temp files.
			// The merged files will get cleaned up by MDXPDF
			if (!preserveTempFiles) {
				for (var n = 0; n < widgetList.length; n++) {
					var purgeFile = svgUtil.makeSVGFileName(widgetList[n].id+'-print'+zenPage.tempFileToken+'.xsl');		// DTB355 - Add tempFilteToken to file names
					svgUtil.RemoveFile(purgeFile);
				}
			}
		}
		break;
	default:
		for (var n = 0; n < widgetList.length; n++) {
			widgetList[n].controlEventHandler(which,action,targetProperty,value,text);
		}
		break;
	}

	this._sourceControl = null;

	if (control && 'timer' == control._type) {
		// restart timer
		control.startTimer();
	}
	return true;
}

/// Dispatch the given action to all widgets in the list <var>target</var>.
/// <var>currWidget</var> is the current widget (used to resolve empty target names).
ClientMethod dispatchAction(which, currWidget, target, action, targetProperty, value, text) [ Internal, Language = javascript ]
{
	text = ('undefined' == typeof text) ? '' : text;
	// loop over widgets; children of desktop
	var desktop = zen('desktop');
	if (desktop) {
		// split apart list of targets
		var targetList = target.toString().split(',');
		for (var t = 0; t < targetList.length; t++) {
			var targetVal = targetList[t];
			var targets = 0;
			for (var n = 0; n < desktop.children.length; n++) {
				var widget = desktop.children[n];
				if (widget && widget.controlEventHandler && 
					((widget.name==targetVal)||(targetVal=='*')||(targetVal===''&&widget==currWidget))) {
					widget.controlEventHandler(which,action,targetProperty,value,text);
					targets++;
				}
			}
			if (targets==0) {
				// notify user that nothing happened
				var msg = 'No widget with the name \'' + targetVal + '\' was found so this action was not processed.';
				alert(msg);
			}
		}
	}
}

/// This handles any actions that were not handled by the widgets on the dashboard.
/// This is done by sending the event to the server-side dataSource.
ClientMethod actionHandler(widget, dataSource, action) [ Language = javascript ]
{
	// fill in context object to send data to server
	var context = new zenProxy();
	context.command = '';
	context.textList = '';
	context.value = '';

	context.currSeriesNo = widget.currSeriesNo;
	context.currItemNo = widget.currItemNo;
	context.currValue = widget.currValue;
	context.currValueName = widget.currValueName;
	context.valueList = widget.getParameterValue('VALUELIST');
	context.currFilterSpec = widget.currFilterSpec; // + Alessandro Marin && WAL127
	
	// JMD: additional context to recreate MDX statement
	var dc = widget.getDataController();
	context.cubeName = dc.cubeName ? dc.cubeName : '';
	context.mdx = dc.GetCurrentQueryText ? dc.GetCurrentQueryText() : '';  // WAL075 -- use getter method  // WAL109 test from dc.GetCurrentQueryText() to dc.GetCurrentQueryText

	// + WAL161 -- add pivot variables to context
	var pivotVariables = new zenProxy();
	if (dc.pivotVariables) {
		for (pVar in dc.pivotVariables) {
			pivotVariables[pVar] = dc.pivotVariables[pVar];
		}
	}
	// - WAL161
	
	// + DTB476 - Add filter control settings
	var filters = new zenProxy();
	for (f in dc.filters) {
		filters[dc.filters[f].spec] = (dc.filters[f].key ? dc.filters[f].key : dc.filters[f].value);		// DTB496
	}
	// - DTB476

	var msg = this.SendActionToDataSource(dataSource,action,context,pivotVariables,filters); // + WAL161, DTB476

	if ('' != msg) {
		alert(msg);
	}
	else {
		// test for commands from server
		// a command string takes the form:
		// command:target:value;command:target:value;
		// there may be a parallel structure called textList which contains
		// the *text* values for filter values in the command list!

		var textList = context.textList.toString().split(';');

		var commandString = context.command.toString();
		// look for \; escapes
		commandString = commandString.replace(/\\;/g,'\x07');

		var commands = commandString.split(';');
		for (var c = 0; c < commands.length; c++) {
			// unescape \;
			var txt = commands[c].replace(/\x07/g,';');
			var t = txt.split(':');
			var command = t[0];
			t.splice(0,1);

			if (''!==command) {
				// invoke actions
				switch(command) {
				case 'setFilter':
				case 'applyFilter':
					// command:target:filterProp:value;
					var target = t[0] ? t[0] : '';
					t.splice(0,1);
					var filterProp = t[0] ? t[0] : '';
					t.splice(0,1);
					var value = t.join(':');
					var text = textList[c] ? textList[c] : value;
					this.dispatchAction('action',widget,target,command,filterProp,value,text);
					break;

				case 'refresh':
					// command:target;
					var target = t.join(':');
					this.dispatchAction('action',widget,target,command,'','');
					break;
				case 'navigate':
					// command:url;
					var url = t.join(':');
					zenPage.navigate(url);
					break;
				case 'newWindow':
					// command:url;
					var url = t.join(':');
					window.open(url);
					break;
				case 'alert':
					// JMD1051
					alert(t.join(':'));
					break;
				case 'popup':
					// JMD1063
					var url = t.join(':');
					zenLaunchPopupWindow(url,'ActionPopup','status,scrollbars,resizable=yes,width=800,height=600');
					break;
				case '':
					break;
				default:
					alert('Unrecognized action command: ' + command);
					break;
				}
			}
		}
	}
}

/// Dispatch DataSource Action back to server-side class.<br/>
/// <var>pContext</var> is a proxy object that carries the server action back to the client.
ClassMethod SendActionToDataSource(pDataSource As %String, pAction As %String, pContext As %ZEN.proxyObject, pPivotVariables As %ZEN.proxyObject = "", pFilters As %ZEN.proxyObject = "") As %String [ Internal, ZenMethod ]
{
	Set tMsg = ""
	Set tSC = $$$OK
	Try {
		#; dispatch to datasource
		If (pDataSource'="") {
			Set pContext.pivotVariables = pPivotVariables // + WAL161 -- combine pivot variable information with other context
			Set pContext.filters = pFilters		// DTB476 - Add filter control settings to the context
			Set pContext.dataSource = pDataSource		// DTB543 - Add datasource to the context
			
			Set tExt = $P(pDataSource,".",$L(pDataSource,"."))
			If (tExt = "kpi") {
				Set tName = $P(pDataSource,".",1,$L(pDataSource,".")-1)
				Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
				If (tKPIClass'="") {
					Set tSC = $zobjclassmethod(tKPIClass,"%InvokeDashboardAction",pAction,pContext,pDataSource)
					If $$$ISERR(tSC) Quit
				}
			}
			ElseIf (tExt = "worksheet") {
				Set tKPIClass = "%DeepSee.KPIWorksheet"
				Set tSC = $zobjclassmethod(tKPIClass,"%InvokeDashboardAction",pAction,pContext,pDataSource)
				If $$$ISERR(tSC) Quit
			}
			ElseIf (tExt = "metric") {
				Set tKPIClass = "Ens.BusinessMetricKPI"
				Set tSC = $zobjclassmethod(tKPIClass,"%InvokeDashboardAction",pAction,pContext,pDataSource)
				If $$$ISERR(tSC) Quit
			}
			ElseIf (tExt = "pivot") {
				// dispatch to KPI associated with cube
				Set tPivot = ""
				If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(pDataSource)) {
					// DTB580 - Only set the folder item if we know it exists
					Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pDataSource,.tSC)
					If $$$ISERR(tSC) Quit
				}
				If '$IsObject(tPivot) {
					Quit
				}

				Set tCube = tPivot.%GetCubeName()
				Set tActionClass = ##class(%DeepSee.Utils).%GetCubeActionClass(tCube)
				If (tActionClass'="") {
					Set tSC = $zobjclassmethod(tActionClass,"%InvokeDashboardAction",pAction,pContext)
					If $$$ISERR(tSC) Quit
				}
			}

			// get text value for filters, if possible
			Set tCommand = pContext.command
			Set tTextList = ""
			For p = 1:1:$L(tCommand,";") {
				Set tItem = $P(tCommand,";",p)
				Set tItemAction = $P(tItem,":",1)
				If ((tItemAction="applyFilter")||(tItemAction="setFilter")) {
					Set tFilter = $P(tItem,":",3)
					Set tKey = $P(tItem,":",4)
					Set $P(tTextList,",",p) = ..%GetDisplayValue(pDataSource,tFilter,tKey)
				}
			}
			Set:tTextList'="" pContext.textList = tTextList
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

/// Utility method. Find the display method for a given filter value.
ClassMethod %GetDisplayValue(pDataSource As %String, pFilterName As %String, pValue As %String) As %String [ Internal ]
{
	Set tText = pValue
	Try {
		Set tCubeName = ""

		// what kind of data source is in play?
		If (pDataSource'="") {
			Set tDataSourceName = pDataSource
			If (tDataSourceName'[".") {
	  			Set tDataSourceName=tDataSourceName_".cube"
	  		}
			Set tExt = $P(tDataSourceName,".",$L(tDataSourceName,"."))

			If ((tExt = "pivot")||(tExt = "cube")) {
				If (tExt = "pivot") {
					Set tPivot = ""
					If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(tDataSourceName)) {
						// DTB580 - Only set the folder item if we know it exists
						Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tDataSourceName,.tSC)
						If $$$ISERR(tSC) Quit
					}
					If $IsObject(tPivot) {
						Set tCubeName = $$$UPPER(tPivot.%GetCubeName())
					}
				}
				Else {
					Set tCubeName = $$$UPPER($P(tDataSourceName,".",1,$L(tDataSourceName,".")-1))
				}
			}
			ElseIf ((tExt="kpi")||(tExt="metric")||(tExt="worksheet")) {
				If (tExt="kpi") {
					Set tName = $P(tDataSourceName,".",1,$L(tDataSourceName,".")-1)
					Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
				}
				ElseIf (tExt="worksheet") {
					Set tKPIClass = "%DeepSee.KPIWorksheet"
				}
				Else {
					Set tKPIClass = "Ens.BusinessMetricKPI"
				}
				If (tKPIClass'="") {
					Set tText = $classmethod(tKPIClass,"%GetFilterDisplayValue",pFilterName,pValue)
				}
				Else {
					Set tText = $ZSTRIP(pValue,"<>W")
					If ($E(tText,1,2)="&[") {
						// work-around: take off "&[ ]"
						Set tText = $E(pValue,3,$L(pValue)-1)
					}
				}
			}
		}

		If (tCubeName'="") {
			Set tSC = ##class(%DeepSee.Utils).%GetLevelNameForKey(tCubeName,pFilterName,pValue,.tText)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Set tText = $System.Status.GetOneErrorText(tSC)
	}
	Quit tText
}

/// Delete this dashboard.
ClientMethod deleteDashboard() [ Language = javascript ]
{
	if (this.isReadOnly()) {
		alert($$$Text('This dashboard is read only and cannot be modified'));
		return;
	}
	if (''!=this.dashboardName) {
		if (confirm($$$Text('Do you want to delete this dashboard?'),false)) {
			var msg = zenPage.SendItemToTrash(this.dashboardName);
			if ('' != msg) {
				alert(msg);
			}
			else {
				zenPage.gotoPage(this.homePage);
			}
		}
	}
}

/// Launch the dashboard finder.
ClientMethod openDashboard() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=dashboards','DashboardOpen','status,scrollbars,resizable=yes,width=800,height=600');
}

/// Create a new dashboard.
ClientMethod newDashboard() [ Language = javascript ]
{
	// show save dialog
	// pass along current name so we can pick up its folder name!
	zenPage.dashboardLocked = false;		// DP-430387
	var parms = {
			NEW:1,
			DASHBOARD:this.dashboardName,
			TITLE:'',
			WORDS:'',
			DESC:''
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.DashboardSave.zen','DashboardNew','status,scrollbars,resizable=yes,width=700,height=800',parms);
}

/// Save the dashboard settings for the current user (save my settings).
ClientMethod saveSettings(user) [ Language = javascript ]
{
	user = ('undefined' == typeof user) ? '' : user;
	if (''!=this.dashboardName) {
		this.getWidgetLayout();
		var msg = this.SaveDashboardSettings(user);
		if (msg!="") {
			alert(msg);
		}
		zen('clearSettings').setProperty('disabled',false);
	}
}

/// Clear saved dashboard settings.
ClientMethod clearSettings() [ Language = javascript ]
{
	if (''!=this.dashboardName) {
		var msg = this.ClearDashboardSettings();
		if (msg!="") {
			alert(msg);
		}
		// + WAL053
		if (this.autosave != '') {
			this.autosaveOverride=1;
		}
		// - WAL053
		this.reloadDashboard();
	}
}

/// Remove any autosave state associated with this dashboard -- the dashboard
/// should load fresh
ClientMethod clearAutosaveState() [ Language = javascript ]
{
	var autosaveItems = new zenProxy;
	var dashboardName = this.dashboardName;;
	if (dashboardName.indexOf('$Temp/')==-1) { 
		dashboardName = this.tempStorageRoot+this.autosave+'/'+this.dashboardName; 
	}
	autosaveItems.dashboard = dashboardName;
	// + WAL123 -- remove the pointer to the autosaved version of the pivot table
	var def = this.getDefinition();
	var desktop = zen('desktop');
	if (desktop) {
		for (var n = 0; n < desktop.children.length; n++) {
			var widget = desktop.children[n];
			var pivot = widget.findComponent('table');
			if (pivot) {
				var autosavePivotName = widget.dataSource;
				if (autosavePivotName.indexOf('$Temp/')==-1) { // WAL112 (2) -- check the pivot name, not the dashboard name
					autosavePivotName = '$Temp/DashboardPivot/'+this.autosave+'/'+n+'/'+widget.dataSource; 
				}
				autosaveItems['widget'+n] = autosavePivotName;
			}
		}
	}
	var status = this.ClearDashboardAutosaveState(autosaveItems,zenPage.dashboardName,zenPage.autosave);
	// call clear settings which will delete the settings, set
	// the autosave override and reload the dashboard
	this.clearSettings();
}

Method ClearDashboardAutosaveState(pAutosaveItems As %ZEN.proxyObject, pDashboardName As %String, pAutosave As %String) As %Status [ ZenMethod ]
{
	Do pAutosaveItems.%CopyToArray(.tArray)
	Set tName = $O(tArray(""))
	While (tName'="") {
		Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderItem(tArray(tName))
		Set tName = $O(tArray(tName))	
	}
	Kill ^DeepSee.AutosaveSettingsTimestamp(pDashboardName,pAutosave) // WAL187 -- make sure to inherit master settings on refresh
	Quit $$$OK
}

/// Launch the save dialog.
/// If <var>show</var> is true, show the dialog.
ClientMethod saveDashboard(show, autosaveDashboard) [ Language = javascript ]
{
	if (this.isReadOnly()) {
		alert($$$Text('This dashboard is read only and cannot be modified.'));
		return;
	}

	this._oldSnapGrid = this.dashboardSnapGrid;
	this._oldSnapTo = this.dashboardSnapTo;
	this._oldName = this.dashboardName;

	this._oldResize = this.dashboardResize;
	this._oldModify = this.dashboardModify;

	this.getWidgetLayout();

	if (show || ('' == this.dashboardName)) {
		// show save dialog
		var parms = {
				DASHBOARD:this.dashboardName,
				TITLE:this.dashboardTitle,
				WORDS:this.dashboardKeywords,
				DESC:this.dashboardDescription,
				OWNER:this.dashboardOwner,
				RESOURCE:this.dashboardResource,
				LAYOUT:this.worklistCount,
				SNAPGRID:this.dashboardSnapGrid?1:0,
				SNAPTO:this.dashboardSnapTo?1:0,
				RESIZE:this.dashboardResize?1:0,
				MODIFY:this.dashboardModify?1:0,
				GRIDROWS:this.dashboardGridRows,
				GRIDCOLS:this.dashboardGridCols,
				LOCKED:this.dashboardLocked?1:0,
				CATEGORY:this.dashboardCategory,
				PUBLIC:this.dashboardPublic?1:0
				};
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.DashboardSave.zen','DashboardSave','status,scrollbars,resizable=yes,width=700,height=800',parms);
	}
	else {
		var def = this.getDefinition();
		if (def.locked && zenPage.dashboardLocked) {
			alert($$$Text('This dashboard is locked and cannot be saved without first unlocking it.'));
			return false;
		}
		// + WAL153 -- make sure that standard dashboards don't point to the autosave or $Temp
		//             versions of a pivot
		if ((autosaveDashboard==undefined)||(autosaveDashboard!=1)) {
			for (var i = 0; i < def.widgets.length; ++i) {
				if ((def.widgets[i])&&(def.widgets[i].dataSource.indexOf('$Temp/')!=-1)) {
					var dataSourceName = def.widgets[i].dataSource;
					var dataSourceNames = dataSourceName.split('/');
					dataSourceNames.splice(0,4);
					def.widgets[i].dataSource = dataSourceNames.join('/');
				}
			}
		}
		// - WAL153
		
		// save without dialog
		this.onPopupAction('DashboardSave','',(autosaveDashboard ? 'autoSave' : ''));
	}
}

/// Perform an autosave of the current dashboard, filed under the current user
ClientMethod runAutosave() [ Language = javascript ]
{
	// Method added by DP-427970
	var timer = zen('autosaveTimer');
	var autosaveOverride = ('undefined' == typeof this.autosaveOverride) ? '' : this.autosaveOverride;

	// NB: In general the page fails if there is no dashboardName and doesn't get to this point,
	// but even so this method will avoid autosave if it has no dashboardName to work with
	if ((this.dashboardName!='')&&(this.autosave!='')&&(!this.autosaveOverride)) {
		var origName = this.dashboardName;
		if (this.dashboardName.indexOf('$Temp/')==-1) { 
			this.dashboardName = this.tempStorageRoot+this.autosave+'/'+this.dashboardName; 
		}
		// WAL112 - save copies of all of the widgets as well
		// this way we preserve pivot table state that is saved with the pivot
		// instead of with the widget. Examples are:
		// - listing state, whether or not this is a listing
		// - drill state, which drill down operations have been performed 
		var def = this.getDefinition();
		var desktop = zen('desktop');
		if (desktop) {
			for (var n = 0; n < desktop.children.length; n++) {
				var widget = desktop.children[n];
				var pivot = widget.findComponent('table');
				if (pivot) {
					var autosavePivotName = widget.dataSource;
					// +PFS008 - Only autosave temp version of data source if type is a pivot
					var autosavePivotNameArray = autosavePivotName.split(".");
					if (autosavePivotNameArray[autosavePivotNameArray.length-1]=="pivot") {
						if (autosavePivotName.indexOf('$Temp/')==-1) { // WAL112 (2) -- check the pivot name, not the dashboard name
							autosavePivotName = '$Temp/DashboardPivot/'+this.autosave+'/'+n+'/'+widget.dataSource; // WAL123 -- differentiate between two widgets displaying the same pivot
						}
						var status = this.SavePivotTable(pivot,autosavePivotName);
						if (def.widgets[n]) def.widgets[n].dataSource = autosavePivotName; // + WAL153 -- protect
					}
					// -PFS008
				}
			}
		}
		// - WAL112
		if (!zenPage.isReadOnly()) {
			// DTB833 - Don't attempt a save if the dashbaord cannot be modified
			zenPage.saveDashboard(false,1); // WAL153 -- second argument shows that we are doing an autosave save 
		}
		zenPage.saveSettings(this.autosave); // WAL108 -- save the settings for the $Temp version as well
		this.dashboardName = origName;

		timer.startTimer();
	}
	else {
		// If autosave is not on or there is no dashboard, turn the timer off
		this.autosaveOverride = '';	
		timer.timeout = 0;
	}
}

/// Launch the save as dialog.
ClientMethod saveCopyOfDashboard() [ Language = javascript ]
{
	if (this.isReadOnly()) {
		alert($$$Text('This dashboard is read only and cannot be copied.'));
		return;
	}

	this._oldSnapGrid = this.dashboardSnapGrid;
	this._oldSnapTo = this.dashboardSnapTo;
	this._oldResize = this.dashboardResize;
	this._oldModify = this.dashboardModify;
	this._oldName = this.dashboardName;
	this.getWidgetLayout();

	// show save dialog
	var parms = {
			DASHBOARD:this.dashboardName,
			CATEGORY:this.dashboardCategory,
			TITLE:this.dashboardTitle,
			WORDS:this.dashboardKeywords,
			SNAPTO:this.dashboardSnapTo?1:0,
			SNAPGRID:this.dashboardSnapGrid?1:0,
			RESIZE:this.dashboardResize?1:0,
			MODIFY:this.dashboardModify?1:0,
			GRIDROWS:this.dashboardGridRows,
			GRIDCOLS:this.dashboardGridCols,
			LAYOUT:this.worklistCount,
			SAVEAS:1,
			DESC:this.dashboardDescription,
			LOCKED:0
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.DashboardSave.zen','DashboardSaveCopy','status,scrollbars,resizable=yes,width=700,height=800',parms);
}

/// Invoke widget catalog dialog.
ClientMethod addWidgetFromCatalog() [ Language = javascript ]
{
	if (''==this.dashboardName) {
		alert($$$Text('Please save the dashboard before adding widgets to it'));
		return;
	}
	if (this.isReadOnly()||!this.dashboardModify) {
		alert($$$Text('This dashboard is read only and cannot be modified'));
		return;
	}

	this.getWidgetLayout();

	var parms = {
			DASHBOARD:this.dashboardName
			};

	zenLaunchPopupWindow('_DeepSee.UI.Dialog.WidgetCatalog.zen','DashboardAddItemFromCatalog','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Invoke the widget wizard dialog to add a new widget to the dashboard.
ClientMethod newWidget() [ Language = javascript ]
{
	if (''==this.dashboardName) {
		alert($$$Text('Please save the dashboard before adding widgets to it'));
		return;
	}
	if (this.isReadOnly()||!this.dashboardModify) {
		alert($$$Text('This dashboard is read only and cannot be modified'));
		return;
	}

	this.getWidgetLayout();

	// get list of all widget names
	var nameList = [];
	var widgetCount = 0;
	var desktop = zen('desktop');
	if (desktop) {
		for (var n = 0; n < desktop.children.length; n++) {
			var widget = desktop.children[n];
			if (widget && widget.name) {
				nameList[nameList.length] = widget.name;
			}
			if (widget && widget.applyFilters) {
				widgetCount++;
			}
		}
	}

	// show add item dialog
	var parms = {
			NAMES:nameList.join(','),
			COUNT:widgetCount,
			DASHBOARD:this.dashboardName
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.WidgetWizard.zen','DashboardNewWidget','status,scrollbars,resizable=yes,width=1000,height=700',parms);
}

/// Invoke dialog-version of Analyzer.
ClientMethod showAnalyzerDialog(key, datasource, local) [ Internal, Language = javascript ]
{
	// save current state
	if (!zenPage.isReadOnly()) {
		// DTB310 - Only attempt save if the user has edit rights
		zenPage.saveDashboard(false);
	}

	this._localName = '';
	this._widgetKey = key;

	if (''==local) {
		// create a local name
		var dbname = this.dashboardName.split('.')[0];
		this._localName = '$LOCAL/'+dbname+'/'+this.userName+'/'+key+'.pivot';
	}
	else {
		// use local as actual so that changes are made to it
		datasource = local;
	}

	var filterState = '';
	var widget = this.findWidgetByKey(key);
	if (widget && widget.getFilterState) {
		filterState = widget.getFilterState();
	}

	// show analyzer dialog
	var parms = {
			PIVOT:datasource,
			LOCALNAME:this._localName,
			FILTERSTATE:filterState,
			KEY:key
			};

	zenLaunchPopupWindow('_DeepSee.UI.Dialog.Analyzer.zen','Analyzer','status,scrollbars,resizable=yes,width=1000,height=700',parms);
}

/// Submit handler for the dashboard definition.
/// This is called when the dashboard is saved.
Method SubmitDashboardDef(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %DeepSee.Dashboard.Definition, ByRef pResponseObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		If ((pCommand["DashboardSave")||(pCommand["DashboardSaveCopy")||(pCommand["DashboardNew")) {
			// save
			Set tDeleteSettings = 0
			Set tCreateCopy = (pCommand [ "DashboardSaveCopy")
			Set tCreateNew = (pCommand [ "DashboardNew")

			Set tDashboardName = pSubmitObject.fullName
			// +DTB103 - source control
			Set tReadOnly = 0
			If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(tDashboardName)) {
				Set tSavedDashboard = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tDashboardName,.tSC)
				If ($$$ISERR(tSC)) Quit
			}		
			
			// WAL153 -- exempt autosave pivots from this condition in following line
			If (..sourceControlEnabled&&($E(pCommand,1,5) '= "force")&&($E(tDashboardName,1,6)'="$Temp/")) {	// DTB105 - add sourceControlEnabled condition
				If $zdatetime(tSavedDashboard.timeModified,3,,6) '= $zdatetime(pSubmitObject.Timestamp,3,,6) {
					Set pProvider.error = "timestamp"
					Quit
				}
			}
			// -DTB103

			// save dashboard
			// tDashboardName is the original name of the dashboard
			If (tCreateCopy && (tDashboardName'="")) {
				// test for overwrite
				Set tOriginalDashboard = ""
				If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(tDashboardName)) {
					// DTB580 - Only set the folder item if we know it exists
					Set tOriginalDashboard = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tDashboardName,.tSC)
					If $$$ISERR(tSC) Quit
				}
				If '$IsObject(tOriginalDashboard) {
					Set tSC = $$$ERROR($$$GeneralError,"Unable to open dashboard: ",tDashboardName)
					Quit
				}
				Set tExists = ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(..dashboardName)
				If (tExists=2) {
					Set tMsg = $$$Text("Dashboard name is already in use")
					Quit
				}
				ElseIf (tExists=1) {
					Set tMsg = ..SendItemToTrash(..dashboardName)
					If (tMsg'="") Quit
				}

				// new dashboard with current widget list
				Set tDashboard = ##class(%DeepSee.Dashboard.Definition).%New()
				Set tDashboard.snapGrid = 1
				Set tDashboard.widgets = tOriginalDashboard.widgets
				Set tDeleteSettings = 1
			}
			Else {
				// JMD1255: use ..dashboardName
				Set tDashboard = ""
				If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(..dashboardName)) {
					// DTB580 - Only set the folder item if we know it exists
					Set tDashboard = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(..dashboardName,.tSC)
					If $$$ISERR(tSC) Quit
				}
				If (tCreateNew && $IsObject(tDashboard)) {
					// send old version to trash
					Set tMsg = ..SendItemToTrash(..dashboardName)
					If (tMsg'="") Quit
				}
				If ('$IsObject(tDashboard)||tCreateNew) {
					Set tDashboard = ##class(%DeepSee.Dashboard.Definition).%New()
					Set tDashboard.snapGrid = 1
				}
				If $$$ISERR(tSC) Quit
			}
			If pSubmitObject.companyLogo?.E1"://".E{ //Don't allow remote images
				Set tSC=$$$ERROR($$$RemoteFileNotAllowed, "Company Logo")
				Quit
			}
			If pSubmitObject.backgroundImage?.E1"://".E{ 
				Set tSC=$$$ERROR($$$RemoteFileNotAllowed, "Background Image")
				Quit
			}
			Set tDashboard.fullName = ..dashboardName
			Set tDashboard.title = pSubmitObject.title
			Set tDashboard.widgetBorders = pSubmitObject.widgetBorders // JSL4482
			Set tDashboard.widgetBordersToggle = pSubmitObject.widgetBordersToggle // JSL4482
			Set tDashboard.widgetBordersColor = pSubmitObject.widgetBordersColor // JSL4482
			Set tDashboard.widgetBordersStyle = pSubmitObject.widgetBordersStyle // JSL4482
			Set tDashboard.widgetBordersSwitch = pSubmitObject.widgetBordersSwitch // JSL4482
			Set tDashboard.widgetBordersWidth = pSubmitObject.widgetBordersWidth // JSL4482
			Set tDashboard.keywords = pSubmitObject.keywords
			Set tDashboard.description = pSubmitObject.description
			
			// + WAL101
			Set tDashboard.titleBarColor = pSubmitObject.titleBarColor
			Set tDashboard.titleBarOpacity = pSubmitObject.titleBarOpacity
			Set tDashboard.selectedTitleBarColor = pSubmitObject.selectedTitleBarColor
			Set tDashboard.selectedTitleBarOpacity = pSubmitObject.selectedTitleBarOpacity
			Set tDashboard.titleBarTextColor = pSubmitObject.titleBarTextColor
			Set tDashboard.selectedTitleBarTextColor = pSubmitObject.selectedTitleBarTextColor
			Set tDashboard.titleBarFont = pSubmitObject.titleBarFont
			// - WAL101

			Set tDashboard.locked = pSubmitObject.locked
			Set tDashboard.public = pSubmitObject.public
			Set tDashboard.worklistCount = pSubmitObject.worklistCount
	
			Set tDashboard.owner = pSubmitObject.owner
			Set tDashboard.resource = pSubmitObject.resource
			Set tDashboard.snapTo = pSubmitObject.snapTo
			Set tDashboard.snapGrid = pSubmitObject.snapGrid

			Set tDashboard.canModify = pSubmitObject.canModify
			Set tDashboard.canResize = pSubmitObject.canResize
			Set tDashboard.gridRows = pSubmitObject.gridRows
			Set tDashboard.gridCols = pSubmitObject.gridCols
			Set tDashboard.bookCover = pSubmitObject.bookCover
			Set tDashboard.category = pSubmitObject.category
			Set tDashboard.showTitleBar = pSubmitObject.showTitleBar
			
			Set tDashboard.companyName = pSubmitObject.companyName
			Set tDashboard.companyLogo = pSubmitObject.companyLogo
			Set tDashboard.companyStyle = pSubmitObject.companyStyle
			
			Set tDashboard.backgroundColor = pSubmitObject.backgroundColor // JSL4479
			Set tDashboard.backgroundImage = pSubmitObject.backgroundImage // JSL4479
			Set tDashboard.backgroundRepeat = pSubmitObject.backgroundRepeat // JSL4479
			Set tDashboard.backgroundSize = pSubmitObject.backgroundSize // JSL4479
			Set tDashboard.backgroundOpacity = $s(pSubmitObject.backgroundOpacity="":1,1:pSubmitObject.backgroundOpacity) // JSL4479 and JSL4483
			
			// always delete user settings on save
			Set tDeleteSettings = 1

			If (tCreateNew) {
				Set tDeleteSettings = 1
				Do tDashboard.widgets.Clear()
			}
			Else {
				Do tDashboard.widgets.Clear()

				// copy widget definitions over
				For n=1:1:pSubmitObject.widgets.Count() {
					Set tWidgetDef = pSubmitObject.widgets.GetAt(n)
					Do tDashboard.widgets.Insert(tWidgetDef)
					
					// JMD1413
					If (tWidgetDef.resetDataSource) {
						Set tSC = ##class(%DeepSee.UserPortal.Utils).%ClearLocalDataSource(..dashboardName,tWidgetDef.key)
						If $$$ISERR(tSC) Quit
						Set tWidgetDef.resetDataSource = 0
					}
				}
			}

			// clear any user settings when we save
			// this prevents old filter values from causing trouble
			// JMD1074 save any localDataSource values!
			If (tDeleteSettings) {
				Set tSC = ##class(%DeepSee.UserPortal.Utils).%ClearDashboardSettings(..dashboardName,,1)
				If $$$ISERR(tSC) Quit
			}

			Set tSC = tDashboard.%Save()
			If $$$ISERR(tSC) Quit
			Set pResponseObject = pSubmitObject
			Set pResponseObject.Timestamp = $ZDT(tDashboard.timeModified,3,,6)
			
			If ..IsSourceControlReadOnly(..GetInternalName()) {
				Set pResponseObject.ReadOnly = 2
			}
			Else {
				Set pResponseObject.ReadOnly = tReadOnly
			}
		}
		ElseIf (pCommand="WidgetSaveToCatalog") {
			// pInfo is a proxyObject containing widget info
			Set tWidgetDef = ""
			If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(..widgetTemplateName)) {
				// DTB580 - Only set the folder item if we know it exists
				Set tWidgetDef = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(..widgetTemplateName,.tSC)
				If $$$ISERR(tSC) Quit
			}
			If '$IsObject(tWidgetDef) {
				Set tWidgetDef = ##class(%DeepSee.Dashboard.WidgetTemplate).%New()
			}
			If $$$ISERR(tSC) Quit

			// find widget definition to save
			For n=1:1:pSubmitObject.widgets.Count() {
				Set tDef = pSubmitObject.widgets.GetAt(n)
				If (tDef.key = ..currWidgetKey) {
					Set tWidgetDef.widget = tDef
					Quit
				}
			}

			Set tWidgetDef.owner = ..widgetOwner
			Set tWidgetDef.resource = ..widgetResource
			Set tWidgetDef.fullName = ..widgetTemplateName
			Set tWidgetDef.description = ..widgetDescription
			Set tWidgetDef.keywords = ..widgetKeywords

			Set tSC = tWidgetDef.%Save()
			If $$$ISERR(tSC) Quit

			Set tSC = ##class(%DeepSee.UserLibrary.Utils).%RegisterRecentItem("folder",tWidgetDef.folderName)
			If $$$ISERR(tSC) Quit
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError,"Unknown command: " _ pCommand)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Clear settings for the current dashboard.
Method ClearDashboardSettings() As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		Set tDashboard = ##class(%DeepSee.Dashboard.Utils).%OpenDashboard(..dashboardName,.tSC)
			If ('$$$ISERR(tSC)&&$IsObject(tDashboard)) {
			// - WAL211
			// + WAL053
			Set tUser = $S((..autosave'=""):..autosave,1:$UserName)
			// DTB431 - Set the dashboard name differently depending on the autosave setting
			If (..autosave'="") {
				Set tDashboardName = ..tempStorageRoot_..autosave_"/"_tDashboard.fullName // WAL211
			}
			Else {
				Set tDashboardName = tDashboard.fullName
			}

			// - WAL053
			Set tSC = ##class(%DeepSee.UserPortal.Utils).%ClearDashboardSettings(tDashboardName,tUser)
			If $$$ISERR(tSC) Quit
			// + WAL187 -- make sure all autosave dashboards pick up the fact that settings have been cleared
			If (..autosave="") {
				Set ^DeepSee.DashboardSettings(..dashboardName,tUser,"clearSettingsTimestamp") = $REPLACE($H,",",".")	
			}
			// - WAL187
			// + WAL211 -- also kill the master settings
			Else {
				Set tSC = ##class(%DeepSee.UserPortal.Utils).%ClearDashboardSettings(..dashboardName,$USERNAME)
				If $$$ISERR(tSC) Quit
			} 
			// - WAL211
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

/// Save settings for the current dashboard.
Method SaveDashboardSettings(pUser As %String = "") As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		Set tSC = ..%GetDashboardSettings(.tSettings)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%DeepSee.UserPortal.Utils).%SaveDashboardSettings(.tSettings,..dashboardName,pUser)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// Get array of "dashboard" settings for this dashboard.
Method %GetDashboardSettings(ByRef pDBSettings As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pDBSettings
		// dashboard-wide settings
		Set pDBSettings("worklistCount") = ..worklistCount
		
		Set pDBSettings("timestamp") = $REPLACE($H,",",".") // WAL187 -- mark when these settings were saved, used by autosave

		// walk over list of visual widgets
		Set tDesktop = ..%GetComponentById("desktop")
		For n=1:1:tDesktop.children.Count() {
			Set tWidget = tDesktop.children.GetAt(n)
			If (tWidget.%IsA("%DeepSee.Component.Widget.widget")) {
				Set tKey = tWidget.widgetKey
				If (tKey'="") {
					If (..dashboardSnapGrid) {
						// JMD1044
						Set pDBSettings(tKey,"homeRowL") = $P(tWidget.widgetLayout,":",2)
						Set pDBSettings(tKey,"homeColL") = $P(tWidget.widgetLayout,":",3)
						Set pDBSettings(tKey,"colSpanL") = $P(tWidget.widgetLayout,":",4)
						Set pDBSettings(tKey,"rowSpanL") = $P(tWidget.widgetLayout,":",5)
						Set pDBSettings(tKey,"maximized") = +$P(tWidget.widgetLayout,":",6)
					}
					Else {
						Set pDBSettings(tKey,"top") = $P(tWidget.widgetLayout,":",2)
						Set pDBSettings(tKey,"left") = $P(tWidget.widgetLayout,":",3)
						Set pDBSettings(tKey,"width") = $P(tWidget.widgetLayout,":",4)
						Set pDBSettings(tKey,"height") = $P(tWidget.widgetLayout,":",5)
						Set pDBSettings(tKey,"maximized") = +$P(tWidget.widgetLayout,":",6)
					}

					// JMD1074 If localDataSource exists; get it
					If (..dashboardName'="") {
						Set tLocalDataSource = $G(^DeepSee.DashboardSettings(..dashboardName,$UserName,tKey,"localDataSource"))
					}

					Kill tWidgetSettings
					Set tSC = tWidget.%GetWidgetSettings(.tWidgetSettings)
					If $$$ISERR(tSC) Quit
					Merge pDBSettings(tKey) = tWidgetSettings

					// JMD1074 reapply
					If ($G(tLocalDataSource)'="") {
						Set pDBSettings(tKey,"localDataSource") = tLocalDataSource
					}
				}
			}
		}
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Change the local datasource for one widget and save it to local settings.
Method SaveWidget(pWidgetKey As %String, pLocalDataSource As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		// JMD1074
		If (pLocalDataSource="") {
			Kill ^DeepSee.DashboardSettings(..dashboardName,$UserName,pWidgetKey,"localDataSource")
		}
		Else {
			Set ^DeepSee.DashboardSettings(..dashboardName,$UserName,pWidgetKey,"localDataSource") = pLocalDataSource
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

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'DashboardNewWidget':
	case 'DashboardEditItem':
	case 'DashboardAddItemFromCatalog':
	case 'DashboardAddItem':
		// redisplay with new widget
		this.reloadPage();
		break;

	case 'DashboardOpen':
		var url = this.viewerURL;
		url = url + ((url.indexOf('?')!=-1) ? '&' : '?') + 'DASHBOARD=' + encodeURIComponent(value);
		// + WAL053
		var autosave ='';
		if (this.autosave != '') {
			autosave = '&AUTOSAVE='+this.autosave;
		}
		url += autosave;
		// - WAL053
		zenPage.gotoPage(url);
		break;

	case 'DashboardNew':
	case 'DashboardSave':
	case 'DashboardSaveCopy':
		var isModified = this.pageModified; 
		this.getWidgetLayout();

		// apply locked state
		var def = this.getDefinition();
		def.locked = zenPage.dashboardLocked;

		// apply other changes from dialog
		// copy name to def *after* save
		
		def.title = zenPage.dashboardTitle;
		def.public = zenPage.dashboardPublic;
		def.owner = zenPage.dashboardOwner;
		def.resource = zenPage.dashboardResource;
		def.category = zenPage.dashboardCategory;		// DTB102
		def.keywords = zenPage.dashboardKeywords;
		def.description = zenPage.dashboardDescription;

		// don't send folder back as json
		def.folder = null;

		// + WAL053
		var autosave ='';
		if (this.autosave != '') {
			autosave = '&AUTOSAVE='+this.autosave;
		}
		// - WAL053

		if (popupName=='DashboardNew') {
			// JMD1202: clear out old name before save
			def.fullName = '';
			def.snapGrid = true;
			def.gridRows = 10;
			def.gridCols = 10;
		}
		
		zenPage.saveAction = popupName;		// DTB103
		var ok = zenPage.saveDocument();
		if ('autoSave'==value) {
			// DP-427970 - Reset the modified flag if this was an autosave
			this.setModified(isModified);
		}

		if (!ok) {
			var msg = zen('jsonDbDefinition').getError();
			if (msg != 'timestamp') {
				// DTB103 source control will interact with the user regarding a timestamp 
				// conflict, show save errors.
 				//alert(msg);			// DTB140 - saveDocument reports errors in an alert already
			}
		}
		else {
			def.fullName = zenPage.dashboardName;
			if ((popupName=='DashboardNew') || (this._oldName != this.dashboardName)) {
				// saved with new name
				this.setModified(false);
				var url = this.viewerURL;
				url = url + ((url.indexOf('?')!=-1) ? '&' : '?') + 'DASHBOARD=' + encodeURIComponent(this.dashboardName);
				url += autosave;
				this._leavingPage = true;
				zenPage.gotoPage(url);
			}
			else if (this._forceReload||(def.snapTo != this.dashboardSnapTo)||(def.snapGrid != this.dashboardSnapGrid)) {
				// change of snapTo et al requires reload
				this.setModified(false);
				var url = this.viewerURL;
				url = url + ((url.indexOf('?')!=-1) ? '&' : '?') + 'DASHBOARD=' + encodeURIComponent(this.dashboardName);
				url += autosave;
				this._leavingPage = true;
				zenPage.gotoPage(url);
			}
			else if ('autoSave'!=value) {
				this.setModified(false);
			}
		}
		break;
	case 'WidgetSaveToCatalog':
		// save via json
		var def = this.getDefinition();
		def.folder = null;
		var json = zen('jsonDbDefinition');
		var ok = json.submitContent(popupName);
		if (!ok) {
			alert(json.getError());
		}
		break;

	case 'WidgetSaveToTheme':
		var widget = this.getCurrWidget();
		var wdef = this.getWidgetDefinition(widget.widgetKey);
		// get overrides from widget
		if (widget) {
			var overrides = widget.getOverrides();
			var proxy = new zenProxy();
			for (var p in overrides) {
				proxy[p] = overrides[p];
			}
			// clear local overrides
			widget.resetOverrides(true);

			// use saved theme
			wdef.theme = value;

			var msg = this.SaveTheme(value,proxy);
			if (msg) {
				alert(msg);
			}

			// make sure theme is applied
			this._forceReload = 1;
			this.setModified(true);
			this.recreateWidget(this.currWidgetKey);
		}
		break;

	case 'Analyzer':
		if (value) {
			// reset
			var msg = this.SaveWidget(this._widgetKey,'');
			if (msg!="") {
				alert(msg);
			}
		}
		else if ('' != this._localName) {
			// save widget with new local dataSource name
			var msg = this.SaveWidget(this._widgetKey,this._localName);
			if (msg!="") {
				alert(msg);
			}
		}

		this._localName = '';
		this._widgetKey = '';

		// redisplay with new data
		this.reloadPage();
		break;
	case 'CoverEdit':
		this.dashboardBookCover = value;
		var def = this.getDefinition();
		def.bookCover = value;

		// save the dashboard
		this.saveDashboard(false);
		break;
		
	case 'AddControl':
		this.setModified(true);
		zenPage.recreateWidget(zenPage.currWidgetKey,'AddControl');  //  + WAL064 -- pass 'AddControl'
		this._forceReload = false;
		break;

	case 'AddDataProperty':
		this._forceReload = true;
		this.saveDashboard(false);
		//var nav = this.getNavigator();
		//nav.refreshTopSheet();
		break;

	case 'WidgetPrintOptions':
		// value is an object
		var options = value;
		var widget = this.getCurrWidget();
		var wdef = this.getWidgetDefinition(widget.widgetKey);
		if (wdef) {
			// save print settings to widget def properties
			wdef.properties.printTitle = options.printTitle;
			wdef.properties.printSubtitle = options.printSubtitle;
			wdef.properties.printSubtitleOn = options.printSubtitleOn; // JSL4302
			wdef.properties.showUser = options.showUser;
			wdef.properties.printPageSize = options.printPageSize;
			wdef.properties.printOrientation = options.printOrientation;
			wdef.properties.printMarginTop = options.printMarginTop;
			wdef.properties.printMarginBottom = options.printMarginBottom;
			wdef.properties.printMarginLeft = options.printMarginLeft;
			wdef.properties.printMarginRight = options.printMarginRight;
			wdef.properties.chartMarginTop = options.chartMarginTop;
			wdef.properties.chartMarginBottom = options.chartMarginBottom;
			wdef.properties.chartMarginLeft = options.chartMarginLeft;
			wdef.properties.chartMarginRight = options.chartMarginRight;
			// JSL4219
			wdef.properties.maxRows = options.maxRows;
			// JSL4218
			wdef.properties.borderLeftCell = options.borderLeftCell;
			wdef.properties.borderRightCell = options.borderRightCell;
			wdef.properties.borderTopCell = options.borderTopCell;
			wdef.properties.borderBottomCell = options.borderBottomCell;
			wdef.properties.borderLeftCol = options.borderLeftCol;
			wdef.properties.borderRightCol = options.borderRightCol;
			wdef.properties.borderTopCol = options.borderTopCol;
			wdef.properties.borderBottomCol = options.borderBottomCol;
			wdef.properties.borderLeftRow = options.borderLeftRow;
			wdef.properties.borderRightRow = options.borderRightRow;
			wdef.properties.borderTopRow = options.borderTopRow;
			wdef.properties.borderBottomRow = options.borderBottomRow;
			
			// + WAL100 -- include font style
			wdef.properties.fontFamilyCell = options.fontFamilyCell;
			wdef.properties.fontSizeCell = options.fontSizeCell;
			wdef.properties.fontFamilyCol = options.fontFamilyCol;
			wdef.properties.fontSizeCol = options.fontSizeCol;
			wdef.properties.fontFamilyRow = options.fontFamilyRow;
			wdef.properties.fontSizeRow = options.fontSizeRow;
			// - WAL100
			
			wdef.properties.filterRowCount = options.filterRowCount;
			wdef.properties.showFilters = options.showFilters; 
			wdef.properties.filterTableStyle = options.filterTableStyle; // JSL4184
			wdef.properties.filterTableCaptionStyle = options.filterTableCaptionStyle;
			wdef.properties.filterTableItemStyle = options.filterTableItemStyle;
	
			wdef.properties.nowDisplayFormat = options.nowDisplayFormat; // JSL4308
						
			wdef.properties.showListingFilters = options.showListingFilters; // JSL4250
			wdef.properties.showDate = options.showDate; // JSL4250
			wdef.properties.showZebraStripes = options.showZebraStripes; // JSL4256
			wdef.properties.listingFontSize = options.listingFontSize; // JSL4279
			this.setModified(true);
		}
		break;
	case 'ColorWheel':
		zenPage.getNavigator().applyValue(value,true);
		break;
	}
}

/// Find a widget given its key.
ClientMethod findWidgetByKey(key) [ Internal, Language = javascript ]
{
	var currWidget = null;
	var desktop = zen('desktop');
	var currWidget = null;
	if (desktop) {
		for (var n = 0; n < desktop.children.length; n++) {
			var widget = desktop.children[n];
			if (widget && key==widget.widgetKey) {
				currWidget = widget;
				break;
			}
		}
	}
	return currWidget;
}

/// Update the title for the dashboard.
ClientMethod updateWorklistTitle() [ Language = javascript ]
{
	var html = zen('worklistTitle');
	var content = new Array();

	if ('' == this.dashboardName) {
		content[content.length] = '<div class="dbTitle">' + $$$Text('New Dashboard') + '</div>';
		self.document.title = $$$Text('New Dashboard');
	}
	else {
		// get short name
		var s = this.dashboardName.toString().split('.');
		// var t = s[s.length-1].toString().split('.');
		var name = s[0];
		if ((name.toString().indexOf('$$$')>=0) || (this.dashboardTitleLocal && this.dashboardTitleLocal!=this.dashboardTitle)) {
			// don't show name if localized
			name = '';
		}
		content[content.length] = '<div class="dbName">' + zenEscapeXML(name) + '</div>';
		content[content.length] = '<div class="dbTitle">' + zenEscapeXML(this.dashboardTitleLocal) + '</div>';

		// set title in browser as well
		self.document.title = ''==this.dashboardTitleLocal ? name : this.dashboardTitleLocal;
		if (this.isReadOnly()) {
			self.document.title += ' ['+$$$Text('Read only')+']';
		}
	}

	html.setContent(content.join(''));
}

/// Get the current size and position of each widget and place it within the widget.
/// Also make sure that the subtype class is current.
ClientMethod getWidgetLayout() [ Language = javascript ]
{
	var desktop = zen('desktop');
	if (desktop) {
		var adj = zenPage.dashboardSnapTo ? 1.1 : 1.0;
		if (this.dashboardSnapGrid) {
			adj = 1.0;
		}

		for (var n = 0; n < desktop.children.length; n++) {
			var widget = desktop.children[n];
			if (widget) {
				var div = widget.getEnclosingDiv();
				var wdef = this.getWidgetDefinition(widget.widgetKey);

				// make sure subtype class is current
				if (wdef) {
					wdef.subtypeClass = widget.getSubtypeClass();
				}

				if (div) {
					var max = div.maximized ? 1 : 0;
					if (this.dashboardSnapGrid) {
						var state = widget.widgetKey;
						if (div.oRefL) {
							var oref = div.oRefL;
							var top = isNaN(oref.top) ? 0 : oref.top;
							var left = isNaN(oref.left) ? 0 : oref.left;
							var wid = isNaN(oref.width) ? 1 : oref.width;
							var hgt = isNaN(oref.height) ? 1 : oref.height;
							state = widget.widgetKey + ":" + top + ":" + left + ":" + wid + ":" + hgt + ":" + max;

							// put size into directly into widget def
							if (wdef) {
								wdef.homeRowL = top;
								wdef.homeColL = left;
								wdef.colSpanL = wid;
								wdef.rowSpanL = hgt;
								wdef.maximized = max;
							}
						}
					}
					else {
						var state = widget.widgetKey + ":" + (div.offsetTop*adj) + ":" + div.offsetLeft + ":" + div.offsetWidth + ":" + div.offsetHeight + ":" + max;
						// put size into directly into widget def
						if (wdef) {
							wdef.top = div.offsetTop*adj;
							wdef.left = div.offsetLeft;
							wdef.width = div.offsetWidth;
							wdef.height = div.offsetHeight;
							wdef.maximized = max;
						}
					}
					widget.widgetLayout = state;
				}
			}
		}
	}
}

/// Add this dashboard to the favorites list.
ClientMethod addThisToFavorites() [ Language = javascript ]
{
	if (''==this.dashboardName) {
		alert($$$Text('Please save the dashboard first'));
		return;
	}
	zenPage.AddFavorite(this.dashboardName);
	zenPage.updateWorklistType('favorites');
}

/// Show the analyzer page.
ClientMethod gotoAnalyzer() [ Language = javascript ]
{
	zenPage.gotoPage('_DeepSee.UserPortal.Analyzer.zen');
}

/// Execute a drill down for the given widget.
ClientMethod drillDown(widget, dataSource) [ Language = javascript ]
{
	var t = dataSource.toString().split('.');
	var ext = t[t.length-1];
	switch(ext) {
	case 'dashboard':
		// view new page
		var url = this.viewerURL;
		url = url + ((url.indexOf('?')!=-1) ? '&' : '?') + 'DASHBOARD=' + encodeURIComponent(dataSource);

		// pick up filters from widget
		var rowSpec = widget.getParameterValue('ROWSPEC');
		var colSpec = widget.getParameterValue('COLUMNSPEC');

		// Build settings list (escape ; and ~ !!!)
		var filters="";
		if ('' != rowSpec) {
			filters += encodeURIComponent(rowSpec);
		}
		if ('' != colSpec) {
			filters += (filters!=''?'~':'') + encodeURIComponent(colSpec);
		}

		if (''!=filters) {
			url += '&SETTINGS=FILTER:' + filters+';';
		}

		zenPage.gotoPage(url);
		break;
	default:
		// send back to widget
		widget.executeDrillDown(dataSource);
		break;
	}
}

/// Test if this page is in read only mode.
ClientMethod isReadOnly() [ Language = javascript ]
{
	return this.readOnly;
}

/// Drop down is about to appear for searchBox control.
ClientMethod filterDropDown(ctrl, widgetKey, dataSource) [ Language = javascript ]
{
	try {
		var widget = zenPage.findWidgetByKey(widgetKey);
		if (!widget) return;

		var t = dataSource.toString().split('.');
		var isKPI = (t[t.length-1]=='kpi');

		// get list of current filter values for same data source
		var specList = [];
		var keyList = [];
		var collectedSpecs = [];		// DTB644 - Add tracking of which specs have already been added

		// JMD1145 (2) do not use *this* controls filter
		var thisFilter = '';
		if (ctrl._type == 'searchBox') {
			thisFilter = ctrl.filterName;
		}

		// JMD1145 get filter state from controls...
		var arr = widget.getFilterStateArray();
		for (var p in arr) {
			if ((p!=thisFilter) && (arr[p]!=='') && (!collectedSpecs[p])) {
				collectedSpecs[p]=1;		// DTB644
				specList[specList.length] = p;
				keyList[keyList.length] = arr[p];
			}
		}
		
		// DTB613 - Restore this block of code, modeling after the analogous %DeepSee.UI.Analyzer:filterDropDown code.
		var pivot = widget.getDataController();
		// JMD1008 Test if this is a pivot!
		if (pivot && pivot.filters && !isKPI) {
			for (var n = 0; n < pivot.filters.length; n++) {
				var filter = pivot.filters[n];

				if ((filter)&&(filter.enabled)) {		// DTB636
					if (filter.key != '') {
						var spec = filter.spec;
						if (spec.toUpperCase().indexOf('.MEMBERS')!=-1) {
							// strip off .members
							var s = spec.split('.');
							s.length--;
							spec = s.join('.'); 
						}

						// DTB616 - If a filter that is set on the dashboard then the baseSpec is set. Use this to determine whether
						// or not the filter setting came from the pivot datasource
						var setInDashboard = (filter.baseSpec)
						
						if (setInDashboard) {
							if ((ctrl.filterName.toUpperCase() != filter.baseSpec.toUpperCase()) && (!collectedSpecs[filter.baseSpec])) {
								collectedSpecs[filter.baseSpec]=1;		// DTB644
								specList[specList.length] = filter.baseSpec;
								keyList[keyList.length] = filter.key;
							}
						}
						else {
							if (spec && (!collectedSpecs[spec])) {
								collectedSpecs[spec]=1;		// DTB644
								specList[specList.length] = spec;
								keyList[keyList.length] = filter.key;
							}
						}
					}
					else if (filter.spec != '') {
						// JMD947: use advanced filters for restriction
						var spec = filter.spec.toString();
						while (spec.charCodeAt(spec.length-1)==10) {
							spec = spec.substr(0,spec.length-1);
						}
						if ((spec[0]=='{' && spec[spec.length-1]=='}')||(spec[spec.length-1]==')')) {
							specList[specList.length] = spec;
							keyList[keyList.length] = '';
						}
					}
				}
			}
		}
		
		if (widget && (widget.clickFilterSpec!='')) {
			// DTB644 - Include the widget's onClick filter
			specList[specList.length] = widget.clickFilterSpec;
			keyList[keyList.length] = '';
		}
		else if (pivot && (pivot.contextFilterSpec!='')) {
			// DTB648 - Check the pivot controller for a context filter
			specList[specList.length] = pivot.contextFilterSpec;
			keyList[keyList.length] = '';
		}
		
		ctrl.relatedFilterSpecs = specList;
		ctrl.relatedFilterKeys = keyList;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in filterDropDown');
	}
	return true;
}

/// Utility method.<br/>
/// Pull apart a filter spec, as we may get from a URL, into a spec and key or value:<br/>
/// [Outlet].[Country].[France] ==> "[Outlet].[Country]","[France]"<br/>
/// {[HOMED].[H1].[ZIP].[32006],[HOMED].[H1].[ZIP].[32007]} ==> "[HOMED].[H1].[ZIP]","{&[32006],&[32007]}" <br/>
/// Note that an array of results is returned. If the spec contains a tuple, each piece is
/// put into its own array node (pIndex is used to track how many pieces there are).<br/>
ClassMethod %ParseFilterSpec(pSpec As %String, Output pFSpec As %String, Output pFKey As %String, Output pFValue As %String, ByRef pIndex As %Integer = 0) As %Status
{
	// for now, assume last piece is value
	Set:pIndex=0 pIndex = 1
	Set pSpec = $ZSTRIP(pSpec,"<>W")
	Set pFSpec(pIndex) = pSpec // default
	Set pFValue(pIndex) = ""
	Set pFKey(pIndex) = ""

	// test for {} sets
	// these are ORs and are assumed to be based on the same levels
	If ($E(pSpec,1)="{") {
		Set pSpec = $E(pSpec,2,$L(pSpec)-1)
		// n.b. commas must be escaped as ,,
		Set tSpec = $Replace(pSpec,",,",$C(1))
		For n = 1:1:$L(tSpec,",") {
			Set tItem = $P(tSpec,",",n)
			Set tItem = $Replace(tItem,$C(1),",,")
			Kill tFSpec,tFKey,tFValue
			Set tSC = ..%ParseFilterSpec(tItem,.tFSpec,.tFKey,.tFValue,.pIndex)
			If (n=1) {
				Set pFSpec(pIndex) = $G(tFSpec(1))
			}
			// JMD1122
			// Set pFKey(pIndex) = pFKey(pIndex) _ $S(pFKey(pIndex)="":"",1:",") _ "&["_$S($G(tFKey(1))'="":$G(tFKey(1)),1:$G(tFValue(1)))_"]"
			If ($G(tFKey(1))'="") {
				Set pFKey(pIndex) = pFKey(pIndex) _ $S(pFKey(pIndex)="":"",1:",") _ $G(tFKey(1))
			}
			ElseIf ($G(tFValue(1))'="") {
				Set pFValue(pIndex) = pFValue(pIndex) _ $S(pFValue(pIndex)="":"",1:",") _ $G(tFValue(1))
			}
		}
		Set:$G(pFKey(pIndex))'="" pFKey(pIndex) = "{"_pFKey(pIndex)_"}"
		// JMD1122
		Set:$G(pFValue(pIndex))'="" pFValue(pIndex) = "{"_pFValue(pIndex)_"}"
		Quit tSC
	}

	// test for () tuples
	// these are split into separate filters
	If ($E(pSpec,1)="(") {
		Set pSpec = $E(pSpec,2,$L(pSpec)-1)
		// n.b. commas must be escaped as ,,
		Set tSpec = $Replace(pSpec,",,",$C(1))
		For n = 1:1:$L(tSpec,",") {
			Set tItem = $P(tSpec,",",n)
			Set tItem = $Replace(tItem,$C(1),",,")
			Kill tFSpec,tFKey,tFValue
			Set tSC = ..%ParseFilterSpec(tItem,.tFSpec,.tFKey,.tFValue,.pIndex)
			Set k = $O(tFSpec(""))
			While (k'="") {
				Set pFSpec(pIndex) = $G(tFSpec(k))
				Set pFKey(pIndex) = $G(tFKey(k))
				Set pFValue(pIndex) = $G(tFValue(k))
				Set pIndex = pIndex + 1
				Set k = $O(tFSpec(k))
			}
		}
		Quit tSC
	}

	Set tState = 0
	Set p = $L(pSpec)

	// work backwards!
	While (p > 0) {
		Set ch = $E(pSpec,p)
		If (tState = 0) {
			If (ch = "]") {
				Set tState = 1
			}
			Else {
				Set tState = 4
			}
		}
		ElseIf(tState = 1) {
			// ]
			If (ch = "[") {
				Set tState = 2
			}
		}
		ElseIf(tState = 2) {
			// []
			If (ch = ".") {
				Set pFSpec(pIndex) = $E(pSpec,1,p-1)
				Set pFValue(pIndex) = $E(pSpec,p+2,$L(pSpec)-1)		// remove []
				Quit
			}
			ElseIf (ch="&") {
				Set tState = 3
			}
		}
		ElseIf(tState = 3) {
			// &[]
			If (ch = ".") {
				Set pFSpec(pIndex) = $E(pSpec,1,p-1)
				Set pFKey(pIndex) = $E(pSpec,p+1,$L(pSpec))
				Quit
			}
			// JMD1122
			ElseIf(ch=",") {
				Set tState = 0
			}
		}
		ElseIf(tState = 4) {
			// JMD1122
			If (ch = "]") {
				Set tState = 1
			}
			ElseIf (ch = ".") {
				Set pFSpec(pIndex) = $E(pSpec,1,p-1)
				Set pFValue(pIndex) = $E(pSpec,p+1,$L(pSpec))
				Quit
			}
		}
		Set p = p - 1
	}
	Quit $$$OK
}

/// email this dashboard.
ClientMethod mailDashboard() [ Language = javascript ]
{
	if (''==this.dashboardName) {
		alert($$$Text('Please save this dashboard before mailing it'));
		return;
	}

	// save settings using nonce
	var nonce = Math.floor(Math.random()*10000000000);
	this.saveSettings(nonce);

	var x = self.document.location.href;
	var url = x.split('?')[0];
	url = url + '?DASHBOARD='+encodeURIComponent(this.dashboardName)+'&NONCE='+nonce;

	var title = this.dashboardTitle==''?$$$Text('DeepSee Dashboard'):this.dashboardTitle;

	this.sendMail(url,title);
}

/// Reload the dashboard (show current saved state)
ClientMethod reloadDashboard() [ Language = javascript ]
{
	this.reloadPage();
}

/// Provide contents of the dimension tree.
/// Used by pivot widget.
ClassMethod GetDimensionInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tDataSource = $G(pParms("DataSource"))
		Set tMemberSource = $G(pParms("MemberSource"))

		If (tMemberSource'="") {
			// get values from member source
			// !!!
			Set tDataSource = "Test/ValueList.worksheet"
			Set tSC = ##class(%DeepSee.AbstractKPI).%GetKPIValueArray(tMemberSource,.tValues,$LB("Name","Value","Group"))
			If $$$ISERR(tSC) Quit

			// organize into groups
			Set tGroupCount = 0
			Set k = $O(tValues(""))
			While (k'="") {
				Set tGroup = $LG(tValues(k),3)
				Set:tGroup="" tGroup = "*"
				If '$D(tGroups(tGroup),tGroupId) {
					Set tGroups(tGroup) = k
					Set tGroupId = k
					Set:tGroup'="*" tGroupCount = tGroupCount + 1
				}
				Set tGroupList(tGroupId,k) = k
				Set k = $O(tValues(k))
			}		

			// emit tree
			Set g = $O(tGroupList(""))
			While (g'="") {
				Set k = $O(tGroupList(g,""))
				If (tGroupCount = 0) {
					Set tParent = 0
				}
				ElseIf (k'="") {
					Set tGroup = $LG(tValues(k),3)
					Set:tGroup="" tGroup = $$$Text("Other","%DeepSee")
					Set pTree($I(pTree)) = $LB(tGroup,"",1,"")
					Set pTree(0,"ch",pTree) = ""
					Set tParent = pTree
				}
				While (k'="") {
					Set tName = $LG(tValues(k),1)
					Set tValue = $LG(tValues(k),2)
					If (tName'="") {
						Set pTree($I(pTree)) = $LB(tName,tValue,0,"")
						Set pTree(tParent,"ch",pTree) = ""
					}
					Set k = $O(tGroupList(g,k))
				}
				Set g = $O(tGroupList(g))
			}
		}
		ElseIf(tDataSource'="") {
			// use primary data source (if pivot)
			Set tPivot = ""
			If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(tDataSource)) {
				// DTB580 - Only set the folder item if we know it exists
				Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tDataSource,.tSC)
				If $$$ISERR(tSC) Quit
			}
			If $IsObject(tPivot)&&(tPivot.%IsA("%DeepSee.Dashboard.Pivot")) {
				// get local calc members
				For n = 1:1:tPivot.calculatedMembers.Count() {
					Set tCalcMbr = tPivot.calculatedMembers.GetAt(n)
					If ((tCalcMbr.dimension'="")&&(tCalcMbr.memberName'="")) {
						Set tCalcMbrs($$$UPPER(tCalcMbr.dimension),$$$UPPER(tCalcMbr.memberName)) = $LB(tCalcMbr.dimension,tCalcMbr.memberName,tCalcMbr.valueExpression)
					}
				}
				// skip measures (arg 4)
				Set tSC = ##class(%DeepSee.Utils).%GetMemberTree(tPivot.cubeName,.pTree,,1,pRoot,.tCalcMbrs,.tNamedSets)
				If $$$ISERR(tSC) Quit
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Notification that this widget is being closed.
ClientMethod widgetClosing() [ Internal, Language = javascript ]
{
	//alert($$$Text("This widget is hidden. To permanently delete it, save the dashboard."))
}

/// Raise the resize method for all widgets except <var>skip</var>.
ClientMethod invokeAdjustSizes(skip) [ Internal, Language = javascript ]
{
	try {
		// JMD859
		var desktop = zen('desktop');
		if (desktop) {
			for (var n = 0; n < desktop.children.length; n++) {
				var widget = desktop.children[n];
				if (widget && widget!=skip && widget.adjustSizes) {
					widget.adjustSizes(false);
				}
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in invokeAdjustSizes');
	}
}

/// Turn title bars on or off.
ClientMethod setTitleBar(flag) [ Internal, Language = javascript ]
{
	this.showTitleBar = flag;
	var desktop = zen('desktop');
	if (desktop) {
		for (var n = 0; n < desktop.children.length; n++) {
			var widget = desktop.children[n];
			if (widget && widget.showDragHeader) {
				widget.showDragHeader(flag);
				if (''!==zenGet(widget.showTitleBar)) {
					// DTB447 - Widget has individual control of its titleBar
					widget.showDragHeader(widget.showTitleBar);
				}
			}
		}
	}
	this.showCurrentGrid();
}

/// Return an object describing what to display for this level within the navigator.
ClientMethod navGetContentForLevel(level, key, value) [ Language = javascript ]
{
	var content = { title: '', items:[] };
	var def = this.getDefinition();
	var widget = this.getCurrWidget();
	var navigator = this.getNavigator(); // JSL4479
	var locked = zenGet(zenPage.dashboardLocked,false) || this.isReadOnly();

	// treat "closed" widget as missing
	if (widget && !widget.getEnclosingDiv()) {
		widget = null;
	}

	// key for widget may take the form WidgetSettings~widgetKey
	var widgetKey = '';
	if (key.toString().indexOf('~')>0) {
		var t = key.split('~');
		key = t[0];
		widgetKey = t[1];
	}

	switch (key) {
	case '':
		content.title = $$$Text('Dashboard Editor','%DeepSee');
		// root
		content.items[content.items.length] = {display:'image-caption', image:'deepsee/ds2_gear_44.png', caption:$$$Text('Dashboard Settings'), action:'drill', key:'DashboardSettings'};
		content.items[content.items.length] = {display:'image-caption', image:'deepsee/ds2_linechart_44.png', caption:$$$Text('Widgets'), action:'drill', key:'WidgetList',disabled:locked};
		break;

	case 'DashboardSettings':
		content.title = $$$Text('Dashboard Settings','%DeepSee');

		// show name read-only
		var fname = zenGet(zenPage.dashboardName);
		fname = fname.toString().split('.')[0];
		var t = fname.split('/');
		var name = t[t.length-1];
		t.length--;
		var folder = t.join('/');

		if (folder) {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Folder','%DeepSee'), value:folder};
		}
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Name','%DeepSee'), value:name};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Locked','%DeepSee'), edit:'switch', value:zenGet(zenPage.dashboardLocked), key:'dbLocked', help:$$$Text('If ON, then further changes to this item are not allowed without unlocking it','%DeepSee')};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Public','%DeepSee'), edit:'switch', value:zenGet(def.public), key:'dbPublic', help:$$$Text('If ON, this dashboard is listed in the portal home page','%DeepSee'), disabled:locked};

		content.items[content.items.length] = {display:'caption', caption:$$$Text('Page Settings'), action:'drill', key:'PageSettings',disabled:locked};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title','%DeepSee'), edit:'string', value:zenGet(def.title), key:'dbTitle'};
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Widget borders','%DeepSee'), edit:'string', value:zenGet(def.widgetBorders), key:'dbWidgetBorders'}; // JSL4482
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Widget borders','%DeepSee'), action:'drill', value:zenGet(this.widgetBordersSwitch), key:'widgetBorders', action:'drill'}; // JSL4482
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Owner','%DeepSee'), edit:'string', action:'drill', value:zenGet(def.owner), key:'dbOwner'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Resource','%DeepSee'), edit:'string', value:zenGet(def.resource), action:'drill', key:'dbResource', help:$$$Text('Name of resource used to grant access to this item.','%DeepSee')};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Category','%DeepSee'), edit:'string', value:zenGet(def.category), key:'dbCategory'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Description','%DeepSee'), edit:'string', value:zenGet(def.description), key:'dbDescription'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Keywords','%DeepSee'), edit:'string', value:zenGet(def.keywords), key:'dbKeywords'};

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Resize','%DeepSee'), edit:'switch', value:zenGet(def.canResize), key:'dbResize', help:$$$Text('If ON, widgets can be resized','%DeepSee'), disabled:locked};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Modify','%DeepSee'), edit:'switch', value:zenGet(def.canModify), key:'dbModify', help:$$$Text('If ON, widgets can be modified','%DeepSee'), disabled:locked};

		// + WAL101
		var showTitleBar = zenGet(zenPage.showTitleBar) ? $$$Text('On','%DeepSee') : $$$Text('Off','%DeepSee');
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title Bars','%DeepSee'), action:'drill', value:showTitleBar, key:'showTitleBar', disabled:locked, help:$$$Text('If ON, show the widget title bars','%DeepSee')};
		// - WAL101
		
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Widget borders','%DeepSee'), edit:'switch', value:zenGet(this.widgetBordersToggle), key:'widgetBordersToggle', help:$$$Text('If ON, show the widget borders','%DeepSee')}; // JSL4482

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Work Lists','%DeepSee'), edit:'choice', value:zenGet(def.worklistCount),		key:'worklistCount', valueList:'0,1,2', displayList:'0,1,2', help:$$$Text('Specify how many worklists to display','%DeepSee'), disabled:locked};
		
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background','%DeepSee'), action:'drill', key:'background', help:$$$Text('Specify background color of Dashboard','%DeepSee'), disabled:locked}; // JSL4479
		
		var style = (def.snapGrid!=zenPage.dashboardSnapGrid) ? 'background:#D0D0FF;' : '';
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Scalable Grid','%DeepSee'), edit:'switch', value:zenGet(def.snapGrid), key:'dbSnapGrid', help:$$$Text('If ON, automatically align widgets onto a scalable grid','%DeepSee'), disabled:locked, style:style};
		if (def.snapGrid!=zenPage.dashboardSnapGrid) {
			content.items[content.items.length] = {display:'info', caption:$$$Text('Save Dashboard to Activate','%DeepSee')};
		}

		if (def.snapGrid) {
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Grid Rows','%DeepSee'), edit:'stepper-value', value:zenGet(def.gridRows),			key:'gridRows', minValue:1, maxValue:20, disabled:locked};
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Grid Columns','%DeepSee'), edit:'stepper-value', value:zenGet(def.gridCols),	key:'gridColumns', minValue:1, maxValue:20, disabled:locked};
		}
		else {
			var style = (def.snapTo!=zenPage.dashboardSnapTo) ? 'background:#D0D0FF;' : '';
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Snap Into Place','%DeepSee'), edit:'switch', value:zenGet(def.snapTo), key:'dbSnapTo', help:$$$Text('If ON, then widgets automatically snap into position when moved','%DeepSee'), disabled:locked, style:style};
			if (def.snapTo!=zenPage.dashboardSnapTo) {
				content.items[content.items.length] = {display:'info', caption:$$$Text('Save Dashboard to Activate','%DeepSee')};
			}
		}
		break;

	case 'PageSettings':
		content.title = $$$Text('Page Settings','%DeepSee');

		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Company Name','%DeepSee'), edit:'string', value:this.companyName, key:'pageCompanyName'};
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Company Logo','%DeepSee'), action:'drill', value:this.companyLogo,	key:'pageCompanyLogo'};
		break;

	case 'pageCompanyLogo':
		// get icon list
		content.title = $$$Text('Images','%DeepSee');
		var options = zenPage.fetchOptionList('image-list','');
		var list = options.children;
		content.html = zenPage.getNavigator().getIconListHTML(list,key,'');
		break;

	case 'WidgetList':
		content.title = $$$Text('Widgets','%DeepSee');

		var canEdit = !this.isReadOnly()&&this.dashboardModify;

		// "add widget" button
		if (canEdit) {
			content.headerButtons = [ 
				{key:'addWidget', caption:$$$Text('Add New Widget','%DeepSee'), image:'deepsee/ds2_plus_44_w.png'}
			];
		}
		// show list of widgets (from definition)
		// key is WidgetSettings~widgetKey
		if (def.widgets.length == 0) {
			content.items[content.items.length] = {display:'info', caption:$$$Text('Dashboard has no Widgets','%DeepSee'), value:'Press the Add button to add a Widget',captionStyle:'color:darkred;white-space: normal;width:260px;', style:'height:150px;'};
		}

		var types = this.getWidgetTypes();
		for (var n = 0; n < def.widgets.length; n++) {
			var widgetDef = def.widgets[n];
			if (widgetDef) {
				if (widgetDef.title) {
					var caption = widgetDef.title;
				}
				else {
					var caption = widgetDef.name;
				}
				
				// Supply default caption
				if (caption==='') {
					caption = '('+$$$Text('Widget','%DeepSee') + ' ' + (n+1) + ')';
				}
				
				var image = 'deepsee/ds2_dashboard_44.png';
				// find icon for widget
				for (var t = 0; t < types.children.length; t++) {
					var type = types.children[t];
					if (type.name == widgetDef.type) {
						image = type.image;
						if (widgetDef.subtype && type.children && type.children.length) {
							for (var tc = 0; tc < type.children.length; tc++) {
								var ctype = type.children[tc];
								if (ctype.name == widgetDef.subtype) {
									image = ctype.image;
									break;
								}
							}
						}
						break;
					}
				}
				// test for "closed" widget
				var widget = this.findWidgetByKey(widgetDef.key);
				var disabled = widget && widget.isClosed;
				content.items[content.items.length] = { widget: widget, display:'image-caption-hz', image:image, caption:caption, action:(canEdit?'drill':''), key:'WidgetSettings~'+widgetDef.key, closeButton:canEdit, selected:(!disabled && this.currWidgetKey==widgetDef.key), disabled:disabled};
			}
		}
		
		// Sort widgets by open/closed state
		var newContent = [];
		var openWidgets = content.items.filter(function(item) {return !item.disabled && item.widget});
		var closedWidgets = content.items.filter(function(item) {return item.disabled && item.widget});
		
		var openHeader = {caption: 'Open (' + openWidgets.length + ')', disabled: true};
		var closedHeader = {caption: 'Hidden (' + closedWidgets.length + ')', disabled: true};
		
		newContent.push(openHeader);
		openWidgets.map(function(item) {newContent.push(item); zenPage.getNavigator().widgets["'" + item.widget.id + "'"] = item.widget;});
		newContent.push(closedHeader);
		closedWidgets.map(function(item) {item.action="openButton"; newContent.push(item); zenPage.getNavigator().widgets["'" + item.widget.id + "'"] = item.widget;});
		
		content.items = newContent;

		break;

	case 'dbResource':
		content.title = $$$Text('Resource','%DeepSee');

		// get list
		var options = zenPage.fetchOptionList('dbResources',this.dashboardResource);
		if (options && options.children) {
			var list = options.children;
			content.html = zenPage.getNavigator().getChooserListHTML(list,key,zenGet(this.dashboardResource),$$$Text('Resources','%DeepSee'),$$$Text('The Resource setting defines who has access to this dashboard','%DeepSee'));
		}
		break;

	case 'dbOwner':
		// list of owners (just current user)
		content.title = $$$Text('Owner','%DeepSee');
		var dbOwner = zenGet(this.dashboardOwner);
		var currUser = this.userName;

		content.items[content.items.length] = {display:'value', selected:dbOwner=='', key:key, value:'', action:'apply', text:$$$Text('No owner','%DeepSee')};
		content.items[content.items.length] = {display:'value', selected:dbOwner==currUser, key:key, value:currUser, action:'apply', text:$$$Text('Me','%DeepSee')};
		break;

	case 'AddWidget':
		content.title = $$$Text('Add Widget','%DeepSee');
		break;
	case 'dbWidgetBorders':
		break;
	case 'widgetBorders': // JSL4482
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Widget borders','%DeepSee'), edit:'choice', value:zenGet(this.widgetBordersSwitch), key:'widgetBordersSwitch', edit:'choice', valueList:'edit,none,inherit', displayList:'edit,none,inherit'}; // JSL4482
		if (true) {
			var fillColor = navigator.transformColor(zenGet(this.widgetBordersColor)!="" ? this.widgetBordersColor : "#F0F0F0");			
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Color','%DeepSee'), action:'drill',  key:'widgetBordersColor', help:$$$Text('Specify color of widget','%DeepSee'), disabled:locked, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fillColor+';'}; // JSL4479
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Width','%DeepSee'), edit:'slider', value:this.widgetBordersWidth, minValue:0, maxValue:20, key:'widgetBordersWidth' };  // JSL4482
			content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Border Style','%DeepSee'), edit:'choice', value:zenGet(this.widgetBordersStyle), key:'widgetBordersStyle', edit:'choice', valueList:'solid,dashed,dotted,double', displayList:'solid,dashed,dotted,double'}; // JSL4482
		} else {
			// fall through and let event be generated
		}
		break;		
	case 'widgetBordersColor': // JSL4482
		var html = zenPage.getNavigator().getColorChooserHTML(key,value);
		content.html = html;
		break;
	case 'background': // JSL4479
		var fillColor = navigator.transformColor(def.backgroundColor);
		content.title = $$$Text('Background', '%DeepSee');
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background Color','%DeepSee'), action:'drill', 	key:'backgroundColor', help:$$$Text('Specify background color of Dashboard','%DeepSee'), disabled:locked, valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fillColor+';'}; // JSL4479
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background Image','%DeepSee'), action:'drill', value:def.backgroundImage, 	key:'backgroundImage', help:$$$Text('Specify background image of Dashboard','%DeepSee'), disabled:locked}; // JSL4479
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background Repeat','%DeepSee'), edit:'choice', 	value:def.backgroundRepeat, key:'backgroundRepeat', help:$$$Text('Specify background repeat of Dashboard','%DeepSee'), disabled:locked, valueList: "repeat,repeat-x,repeat-y,no-repeat,initial,inherit", displayList: "repeat,repeat-x,repeat-y,no-repeat,initial,inherit"}; // JSL4479
		//content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background Size','%DeepSee'), edit:'string', 	value:def.backgroundSize, key:'backgroundSize', help:$$$Text('Specify background size of Dashboard','%DeepSee'), disabled:locked}; // JSL4479
		if (def.backgroundOpacity == "") {
			def.backgroundOpacity = 1;
		}
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background Opacity','%DeepSee'), edit:'slider', 	value:def.backgroundOpacity, key:'backgroundOpacity', help:$$$Text('Specify background opacity of Dashboard','%DeepSee'), minValue: 0.0, maxValue:1.0, disabled:locked}; // JSL4479
		break;
	case 'backgroundColor': // JSL4479
		var html = zenPage.getNavigator().getColorChooserHTML(key,value);
		content.html = html;
		break;
	case 'backgroundImage': // JSL4479
		content.title = $$$Text('Images','%DeepSee');
		var options = zenPage.fetchOptionList('image-list','');
		var list = options.children;
		content.html = zenPage.getNavigator().getIconListHTML(list,key,'');
		break;	
	
	// + WAL101	
	case 'showTitleBar':
		content.title = $$$Text('Title Bar Settings','%DeepSee');
		var showTitleBar = zenGet(zenPage.showTitleBar) ? 1 : 0;
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title Bars','%DeepSee'), edit:'switch', value:showTitleBar, key:'showTitleBar', help:$$$Text('If ON, show the widget title bars','%DeepSee')};
		var fillColor = navigator.transformColor(zenGet(def.titleBarColor)!="" ? def.titleBarColor : "#F0F0F0");			
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title Bar Color','%DeepSee'), action:'drill',  key:'titleBarColor', help:$$$Text('Specify color of title bar','%DeepSee'), valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fillColor+';'};
		var opacity = zenGet(def.titleBarOpacity)=='' ? 1 : zenGet(def.titleBarOpacity);
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Title Bar Opacity','%DeepSee'), edit:'slider', value:opacity,	key:'titleBarOpacity', minValue:0, maxValue:1};
		fillColor = navigator.transformColor(zenGet(def.titleBarTextColor)!="" ? def.titleBarTextColor : "#F0F0F0");			
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text Color','%DeepSee'), action:'drill',  key:'titleBarTextColor', help:$$$Text('Specify color of title bar text','%DeepSee'), valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fillColor+';'};
		fillColor = navigator.transformColor(zenGet(def.selectedTitleBarColor)!="" ? def.selectedTitleBarColor : "#F0F0F0");			
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Selected Color','%DeepSee'), action:'drill',  key:'selectedTitleBarColor', help:$$$Text('Specify color of title bar for selected widgets','%DeepSee'), valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fillColor+';'};
		opacity = zenGet(def.selectedTitleBarOpacity)=='' ? 1 : zenGet(def.selectedTitleBarOpacity);
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Selected Opacity','%DeepSee'), edit:'slider', value:opacity,	key:'selectedTitleBarOpacity', minValue:0, maxValue:1};
		fillColor = navigator.transformColor(zenGet(def.selectedTitleBarTextColor)!="" ? def.selectedTitleBarTextColor : "#F0F0F0");			
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Selected Text Color','%DeepSee'), action:'drill',  key:'selectedTitleBarTextColor', help:$$$Text('Specify color of title bar text for selected widgets','%DeepSee'), valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+fillColor+';'};
		var fontValue = zenGet(def.titleBarFont);
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font','%DeepSee'), action:'drill',  key:'titleBarFontFamily', help:$$$Text('Specify the font for title bar text','%DeepSee'), value:zenGet(this.titleBarFont), valueStyle:'font-size:13px;font-family:'+zenGet(this.titleBarFont)+';'};
		break;
		
	case 'titleBarFontFamily':
		content.title = $$$Text('Color','%DeepSee');
		content.html = navigator.getFontChooserHTML(key,value);
		break;
	
	case 'titleBarColor':
	case 'selectedTitleBarColor':
	case 'titleBarTextColor':
	case 'selectedTitleBarTextColor':
		content.title = $$$Text('Color','%DeepSee');
		content.html = navigator.getColorChooserHTML(key,value);
		// get list of themes as well
		content.title = $$$Text('Themes','%DeepSee');
		var widgetDef = this.getDefinition(zenPage.currWidgetKey);
		var theme = '';
		if (widgetDef) {
			theme = widgetDef.theme;
		}

		var options = zenPage.fetchOptionList('widget-themes','');
		var list = options.children;
		
		content.items[content.items.length] = {display:'info', caption:$$$Text('Theme','%DeepSee'), value:$$$Text('The Theme provides the base styles for this widget','%DeepSee')};

		// show list of options
		for (var n = 0; n < list.length; n++) {
			var ivalue = zenGet(list[n].value);
			var caption = list[n].caption ? list[n].caption : ivalue;
			var style = ivalue==''?'font-style:italic;':'';
			content.items[content.items.length] = {display:'value', selected:theme==ivalue, key:key+':'+ivalue, value:ivalue, action:'apply', text:caption, style:style, closeButton:(ivalue!='')};
		}
		break;
	// - WAL101
		
	case 'WidgetSettings':
		content.title = $$$Text('Widget Settings','%DeepSee');
		// no break
	default:
		// dispatch to widget
		var widget = this.getCurrWidget();
		if (widget && widget.navGetContentForLevel && widget.getEnclosingDiv()) {
			content = widget.navGetContentForLevel(level,key,value);	
		}
		else{
			content.html = '<div style="padding:10px;font-size:20px;color:#804040;font-style:italic;">' + $$$Text('Please select a widget') + '</div>';
		}
		break;
}


	return content;
}

/// Arrange of data list in navigator.
ClientMethod navDataArrange(key, swap, final) [ Language = javascript ]
{
	// dispatch to widget
	if (key.toString().indexOf('widget-')==0) {
		var widget = this.getCurrWidget();
		if (widget && widget.navDataArrange) {
			widget.navDataArrange(key,swap,final);
		}
		return;
	}
}

/// Change of data value in navigator.
ClientMethod navDataChange(key, value, final) [ Language = javascript ]
{
	var nav = this.getNavigator();
	var def = this.getDefinition();
	// dispatch to widget
	if (key.toString().indexOf('widget-')==0) {
		var widget = this.getCurrWidget();
		if (widget && widget.navDataChange) {
			widget.navDataChange(key,value,final);
		}
		if (final) {
			this.setModified(true);
		}
		return;
	}
	
	switch(key) {
	case 'showTitleBar':
		this.setTitleBar(value);
		def.showTitleBar = value;
		this.setModified(true);
		break;
		
	// + WAL101
	case 'titleBarColor':
		// inherit might be the default value from the color chooser html
		if (value=='inherit') value = '';
		def.titleBarColor = value;
		this.titleBarColor = value;
		this.setTitleBarColorAndOpacity();
		this.setModified(true);
		break;
	case 'titleBarOpacity':
		def.titleBarOpacity = value;
		this.titleBarOpacity = value;
		this.setTitleBarColorAndOpacity();
		this.setModified(true);
		break;
	case 'selectedTitleBarColor':
		if (value=='inherit') value = '';
		def.selectedTitleBarColor = value;
		this.selectedTitleBarColor = value;
		this.setModified(true);
		break;
	case 'selectedTitleBarOpacity':
		def.selectedTitleBarOpacity = value;
		this.selectedTitleBarOpacity = value;
		this.setModified(true);
		break;
	case 'titleBarTextColor':
		if (value=='inherit') value = '';
		def.titleBarTextColor = value;
		this.titleBarTextColor = value;
		this.setTitleBarColorAndOpacity();
		this.setModified(true);
		break;
	case 'selectedTitleBarTextColor':
		if (value=='inherit') value = '';
		def.selectedTitleBarTextColor = value;
		this.selectedTitleBarTextColor = value;
		this.setModified(true);
		break;
	case 'titleBarFontFamily':
		if (final) {
			def.titleBarFont = value;
			this.titleBarFont = value;
			this.setTitleBarColorAndOpacity(); // Apply font here for now
			this.setModified(true);
		}
		break;
	// - WAL101

	case 'dbLocked':
		// don't set def.locked until we save!
		this.setProperty('dashboardLocked',value);
		nav.refreshTopSheet();
		this.setModified(true);
		break;

	case 'worklistCount':
		def.worklistCount = value;
		this.setProperty('worklistCount',value);
		this.setModified(true);
		break;

	case 'dbPublic':
		def.public = value;
		this.setProperty('dashboardPublic',value);
		this.setModified(true);
		break;

	case 'dbResize':
		def.canResize = value;
		this.setProperty('dashboardResize',value);
		this.setModified(true);
		break;

	case 'dbModify':
		def.canModify = value;
		this.setProperty('dashboardModify',value);
		this.setModified(true);
		break;

	case 'dbTitle':
		if (final) {
			def.title = value;
			this.setProperty('dashboardTitle',value);
			this.setModified(true);
		}
		break;

	case 'dbWidgetBorders': // JSL4482
		if (final) {
			def.widgetBorders = value;
			this.setProperty("widgetBorders",value);
			this.setModified(true);
		}
		break;

	case 'widgetBordersToggle': // JSL4482
	case 'widgetBordersSwitch': // JSL4482
	case 'widgetBordersColor': // JSL4482
	case 'widgetBordersStyle': // JSL4482
	case 'widgetBordersWidth': // JSL4482
		def[key] = value;
		this.setProperty(key, value);
		this.setModified(true);
		break;
	case 'dbOwner':
		if (final) {
			this.dashboardOwner = value;
			def.owner = value;
			this.setModified(true);
		}
		break;

	case 'dbResource':
		if (final) {
			this.dashboardResource = value;
			def.resource = value;
			this.setModified(true);
		}
		break;
	case 'dbCategory':
		if (final) {
			this.dashboardCategory = value;		// DTB711 - Set the page property
			def.category = value;
			this.setModified(true);
		}
		break;
	case 'dbDescription':
		if (final) {
			this.dashboardDescription = value;		// DTB885 - Set the page property
			def.description = value;
			this.setModified(true);
		}
		break;
	case 'dbKeywords':
		if (final) {
			this.dashboardKeywords = value;		// DTB885 - Set the page property
			def.keywords = value;
			this.setModified(true);
		}
		break;

	case 'gridRows':
		if (final) {
			def.gridRows = parseInt(value,10);
			this.setGridRows(def.gridRows);
			this.setModified(true);
		}
		break;
	case 'gridColumns':
		if (final) {
			def.gridCols = parseInt(value,10);
			this.setGridColumns(def.gridCols);
			this.setModified(true);
		}
		break;

	case 'dbSnapGrid':
		def.snapGrid = value;
		this.setModified(true);
		if (def.snapGrid) {
			if (!def.gridRows) {
				def.gridRows = 10;
			}
			if (!def.gridCols) {
				def.gridCols = 10;
			}
		}
		nav.refreshTopSheet();
		break;
	case 'backgroundColor': // JSL4479
	case 'backgroundImage': // JSL4479
	case 'backgroundSize': // JSL4479
	case 'backgroundRepeat': // JSL4479		
	case 'backgroundOpacity': // JSL4479
		// background attribute
		var attr = key.substring("background".length,key.length+1);
		attr = attr.toLowerCase();
		def[key] = value;
		this.setBackground(attr, value);
		this.setModified(true);
		break;
	
	case 'dbSnapTo':
		def.snapTo = value;
		this.setModified(true);
		nav.refreshTopSheet();
		break;

	case 'pageCompanyName':
		def.companyName = value;
		this.setModified(true);
		this.companyName = value;
		this.updateCompanyCell();
		break;

	case 'pageCompanyLogo':
		if (final) {
			def.companyLogo = value;
			this.setModified(true);
			this.companyLogo = value;
			this.updateCompanyCell();
		}
		break;
	}
}

/// Apply color and opacity to all available widgets
ClientMethod setTitleBarColorAndOpacity() [ Language = javascript ]
{
	var desktop = zen('desktop');
	//var navigator = this.getNavigator();
	if (desktop) {
		for (var n = 0; n < desktop.children.length; n++) {
			var widget = desktop.children[n];
			if (widget) {
				var header = widget.findElement('header');
				if (header) {
					var titleBarColor;
					var titleBarOpacity;
					if (!this.titleBarColor) {
						// this is the default from %DeepSee.Component.Widget.widget
						// the dragGroup block in the css declaration
						titleBarColor = 'rgb(220,231,241)';
					}
					else {
						titleBarColor = this.titleBarColor;
					}
					// 0 is a valid opacity value
					if (!this.titleBarOpacity && (parseInt(this.titleBarOpacity) != 0)) {
						titleBarOpacity = 1;
					}
					else {
						titleBarOpacity = this.titleBarOpacity;	
					}
					var rgba = ZLM.convertColorToRGBA(titleBarColor, titleBarOpacity);
					
					header.style.background = 'rgba('+rgba+')';
					if (this.titleBarTextColor) {
						header.style.color = this.titleBarTextColor;
					}
					else {
						header.style.color = '';	
					}
					// Handle font settings
					header.style.fontFamily = this.titleBarFont;
				}
			}
		}
	}
}

/// Select of item within the navigator.
ClientMethod navSelectItem(key, value, which) [ Language = javascript ]
{
	var nav = this.getNavigator();

	// dispatch to widget
	if (key.toString().indexOf('widget-')==0) {
		var widget = this.getCurrWidget();
		if (widget && widget.navSelectItem) {
			widget.navSelectItem(key,value,which);
		}
		return;
	}
	
	// handle locally
	if (which=='select') {
		nav.setExpanded(false);
		nav.popSheet();
	}
	else if (which=='drill') {
		// key for widget may take the form widget~widgetKey
		var widgetKey = '';
		if (key.toString().indexOf('~')>0) {
			var t = key.split('~');
			key = t[0];
			widgetKey = t[1];
		}
		if (key=='WidgetSettings') {
			// select the widget
			this.widgetSelected(null,widgetKey);
		}
	}
}

/// Click on header button in navigator.
ClientMethod navHeaderButtonClick(key) [ Language = javascript ]
{
	switch(key) {
	case 'addWidget':
		zenPage.newWidget();
		break;
	default:
		// send to widget
		var widget = this.getCurrWidget();
		if (widget && widget.navHeaderButtonClick) {
			widget.navHeaderButtonClick(key);
		}
		break;
	}
}

/// Click on close button in navigator.
ClientMethod navCloseButtonClick(key) [ Language = javascript ]
{
	// key for widget may take the form WidgetSettings~widgetKey
	var widgetKey = '';
	if (key.toString().indexOf('~')>0) {
		var t = key.split('~');
		key = t[0];
		widgetKey = t[1];
	}

	switch(key) {
	case 'WidgetSettings':
		if (confirm('Do you wish to delete this widget?')) {
			// remove widget from definition and save/reload
			var def = this.getDefinition();
			for (var n = 0; n < def.widgets.length; n++) {
				var widget = def.widgets[n];
				if (widget && widget.key == widgetKey) {
					// + WAL153 -- make widget delete like widget add
					//             don't save, just include new widget in definition
					var x = this.deleteWidget(n); // WAL153 (3) -- force synchronous
					if (this.autosave!='') {
						def.widgets.splice(n,1);
					}
					this.reloadDashboard();
					// - WAL153
					break;
				}
			}
		}
		break;

	default:
		// send to widget
		var widget = this.getCurrWidget();
		if (widget && widget.navCloseButtonClick) {
			widget.navCloseButtonClick(key);
		}
	}
}

Method deleteWidget(pIndex) As %String [ ZenMethod ]
{
	// Method added by WAL153
	Set tDashboard = ##class(%DeepSee.Dashboard.Utils).%OpenDashboard(..dashboardName,.tSC)
	If ($$$ISERR(tSC)||'$IsObject(tDashboard)) Quit
	Do tDashboard.widgets.RemoveAt(pIndex+1) // Adjust from javascript index to COS index
	Set tSC = tDashboard.%Save()
	
	If (..autosave'="") {
		Set tAutosaveDashboardName = ..tempStorageRoot_..autosave_"/"_..dashboardName
		If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(tAutosaveDashboardName)) { // WAL201
			Set tDashboard = ##class(%DeepSee.Dashboard.Utils).%OpenDashboard(tAutosaveDashboardName,.tSC)
			If ($$$ISERR(tSC)||'$IsObject(tDashboard)) Quit
			Do tDashboard.widgets.RemoveAt(pIndex+1)
			Set tSC = tDashboard.%Save()
		}
	}
	Quit $$$OK
}

/// Popup action in navigator.
ClientMethod navPopupAction(key, value) [ Language = javascript ]
{
	// key for widget may take the form WidgetSettings~widgetKey
	var widgetKey = '';
	if (key.toString().indexOf('~')>0) {
		var t = key.split('~');
		key = t[0];
		widgetKey = t[1];
	}

	switch(key) {
	default:
		// send to widget
		var widget = this.getCurrWidget();
		if (widget && widget.navPopupAction) {
			widget.navPopupAction(key,value);
		}
	}
}

/// Set number of grid rows in the desktop.
ClientMethod setGridRows(rows) [ Language = javascript ]
{
	this.dashboardGridRows = parseInt(rows,10);
	if (this.dashboardSnapGrid) {
		var desktop = zen('desktop');
		if (desktop) {
			if (desktop.rows!=rows) {
				desktop.setProperty('rows',rows);
				this.showCurrentGrid();
			}
		}
	}
}

ClientMethod setBorder(value) [ Language = javascript ]
{
	//+ JSL4488
	var dragGroupMgr = zen('desktop');
	if (dragGroupMgr != null) {
		dragGroupMgr.broadcast('setBodyStyle','border:'+value);
		// DTB171 - Always set the svg border to 'none'
		dragGroupMgr.broadcast('processAppMessage',{messageType:'setSVGFrameBorder',border:'none'});
	}
	//- JSL4488
}

ClientMethod setFromBorderValues() [ Language = javascript ]
{
	var value = this.widgetBordersWidth + 'px '+this.widgetBordersStyle + ' ' + this.widgetBordersColor;
	this.setBorder(value);
}

ClientMethod setBackground(attr, value) [ Language = javascript ]
{
	// method added by JSL4479
	/* JSL4488
	if (this.dashboardSnapGrid) {
		var div = document.getElementById('desktop');
		var zennum = div.getAttribute('zen');
		//var object=zen('snapGrid_'+zennum) // give object?
		//ZLM.dumpObj(object); // new debugging technique
		//alert("typeof object="+typeof(object));
		var g = document.getElementById('snapGrid_'+zennum);
		if (g != null) {
			for (var w=g.firstChild; w != null; w=w.nextSibling) {
				if (w.getAttribute('class')=='snapGridWallpaper') {
					break;
				}
			}
			if (w != null) {
				if (attr != 'opacity') {
					var jsattr = attr.substring(0,1).toUpperCase()+attr.substring(1);
					if (attr != 'image') {
						w.style['background'+jsattr] = value;
					} else {
						w.style['background'+jsattr] = "url('"+value+"')";
					}
				} else {
					w.style[attr] = value;
				}
			}
		}
	}
	*/
	//+ JSL4488
	var desktop = zen('desktop');
	if (desktop != null) {
		var w = desktop.getWallpaperDiv();
		if (w) {
			if (attr != 'opacity') {
				var jsattr = attr.substring(0,1).toUpperCase()+attr.substring(1);
				if (attr != 'image') {
					w.style['background'+jsattr] = value;
				} else {
					w.style['background'+jsattr] = "url('"+value+"')";
				}
			} else {
				w.style[attr] = value;
			}
		}
	}
	
	//- JSL4488
}

/// Set number of grid columns in the desktop.
ClientMethod setGridColumns(cols) [ Language = javascript ]
{
	this.dashboardGridCols = parseInt(cols,10);
	if (this.dashboardSnapGrid) {
		var desktop = zen('desktop');
		if (desktop) {
			if (desktop.cols!=cols) {
				desktop.setProperty('cols',cols);
				this.showCurrentGrid();
			}
		}
	}
}

/// Number of grid rows in the desktop.
ClientMethod getGridRows() [ Language = javascript ]
{
	var rows = 1;
	if (this.dashboardSnapGrid) {
		var desktop = zen('desktop');
		if (desktop) {
			rows = desktop.rows;
		}
	}
	return rows;
}

/// Number of grid columns in the desktop.
ClientMethod getGridColumns() [ Language = javascript ]
{
	var cols = 1;
	if (this.dashboardSnapGrid) {
		var desktop = zen('desktop');
		if (desktop) {
			cols = desktop.cols;
		}
	}
	return cols;
}

/// User has selected a widget on the dashboard.
ClientMethod widgetSelected(evt, key) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt && evt.stopPropagation) {
		evt.stopPropagation();
	}
	
	// DTB642 - Remove references to evt.cancelBubble, evt.returnValue
	
	if (this.currWidgetKey != key) {
		if (this.currWidgetKey!='') {
			widget = this.findWidgetByKey(this.currWidgetKey);
			if (widget && widget.setHighlight) {
				widget.setHighlight(false);
			}
		}
		this.currWidgetKey = key;
		if (this.currWidgetKey!='') {
			widget = this.findWidgetByKey(this.currWidgetKey);
			if (widget && widget.setHighlight) {
				widget.setHighlight(true);
			}

		}
		if (evt) {
			// update navigator just in case
			// skip if called from navigator!
			var nav = this.getNavigator();
			if (nav) {
				nav.refreshTopSheet();
			}
			this.showCurrentGrid();
		}
	}
}

/// If there is a selected widget, return it.
ClientMethod getCurrWidget() [ Language = javascript ]
{
	var widget = null;
	if (this.currWidgetKey!='') {
		widget = this.findWidgetByKey(this.currWidgetKey);
	}
	return widget;
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'dashboardResize':
		this.dashboardResize = value ? true : false;
		var desktop = zen('desktop');
		if (desktop && desktop.broadcast) {
			// !!! move as well???
			desktop.broadcast(this.dashboardResize ? 'enableResize' : 'disableResize');
			//desktop.broadcast(this.dashboardResize ? 'restoreDragHeader' : 'removeDragHeader');
		}
		break;
	case 'dashboardLocked':
		this.dashboardLocked = value ? true : false;
		break;
	case 'dashboardPublic':
		this.dashboardPublic = value ? true : false;
		break;
	case 'dashboardTitle':
		this.dashboardTitle = value;
		// !!!localization!!!
		this.dashboardTitleLocal = value;
		this.updateWorklistTitle();
		break;
	case 'widgetBorders': // JSL4482
		this.widgetBorders = value;
		this.setBorder(value);
		break;
	case 'widgetBordersSwitch': // JSL4482
		this.widgetBordersSwitch = value;
		if (value != 'edit') {
			this.setBorder(value);
		} else {
			this.setFromBorderValues();
		}
		break;
	case 'widgetBordersToggle':
		this.widgetBordersToggle = value;
		if (value != true) {
			this.setBorder('none');
		} else {
			this.setFromBorderValues();
		}
		break;
	case 'widgetBordersColor':
	case 'widgetBordersWidth':
	case 'widgetBordersStyle':
		this[property] = value;
		this.setFromBorderValues();
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

/// Make a poor man's grid to show the drop zones and add it to the wallpaper
ClientMethod showCurrentGrid() [ Internal, Language = javascript ]
{
	var desktop = zen("desktop");
	if (this.showTitleBar && desktop && desktop._type=='snapGrid') {
		var r = parseInt(desktop.rows,10);
		var c = parseInt(desktop.cols,10);
		var vPercent = 100/r;
		var hPercent = 100/c;
		var h = [];
		for (var i=1;i<r;i++) {
			h.push("<div style='width:100%;height:1px;position:absolute;top:"+(vPercent*i)+"%;left:0px;background:rgba(128,128,128,0.05);'></div>");
		}
		for (var i=1;i<c;i++) { 
			h.push("<div style='height:100%;width:1px;position:absolute;left:"+(hPercent*i)+"%;top:0px;background:rgba(128,128,128,0.05);'></div>");
		}
		var m = desktop.getGroupManager();
		if (m) {		// DTB490
			var w = m.getWallpaperDiv();
			w.innerHTML = h.join(" ");
		}
	}
	else {
		// turn off grid
		if (desktop.getGroupManager) {
			var m = desktop.getGroupManager();
			if (m) {
				var w = m.getWallpaperDiv();
				w.innerHTML = '';
			}
		}
	}
}

/// Return json data to drive the toolbar. !!!
ClientMethod getToolbarData() [ Language = javascript ]
{
	
	// contents of tab bar !!!
	var data = {
		children:[
			{ caption:"Patient Data", key:"menuTab1", type:'tab', selected:true},
			{ caption:"Trends", key:"menuTab2", type:'tab' },
			{ caption:"Forecast", key:"menuTab3", type:'tab' }
		]
	};
	
	return data;
}

/// Launch the book cover editor.
ClientMethod designBookCover() [ Internal, Language = javascript ]
{
	var parms = {
		SPEC:this.dashboardBookCover
	}
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.BookCoverBuilder.zen','CoverEdit','status,scrollbars,resizable=yes,width=900,height=700',parms);
}

/// Get the array of available widget types.
ClientMethod getWidgetTypes() [ Internal, Language = javascript ]
{
	return zen('jsonWidgetTypeList').getContentObject();
}

/// Return JSON array of widget types.<br/>
Method GetWidgetTypeList(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pMetaData = $LB("name","title","className","image")

		Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetWidgetClasses(.tInfo)
		If $$$ISERR(tSC) Quit

		// loop over types
		Set tCount = 0
		Set tItem = $O(tInfo(""))
		While (tItem'="") {
			Set tName = $LG(tInfo(tItem),1)
			Set tTitle = $LG(tInfo(tItem),2)
			Set tClassName = $LG(tInfo(tItem),3)
			Set tImage = $LG(tInfo(tItem),4)

			Set pData($I(tCount)) = $LB(tName,tTitle,tClassName,tImage)

			// Find subtypes
			Do $classmethod(tClassName,"%GetCatalogInfo",,.tList)

			Set n = $O(tList(""))
			While (n'="") {
				Set tSubName = $LG(tList(n),1)
				Set tSubTitle = $LG(tList(n),2)
				Set tSubImage = $LG(tList(n),4)
				Set:tSubImage="" tSubImage = "deepsee/lamp_48.gif"

				Set pData(tCount,n) = $LB(tSubName,tSubTitle,"",tSubImage)
				Set n = $O(tList(n))
			}
			Set tItem = $O(tInfo(tItem))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the dashboard definition object.
ClientMethod getDefinition() [ Internal, Language = javascript ]
{
	return zen('jsonDbDefinition').getContentObject();
}

/// Get the widget definition within the dashaboard definition object.
ClientMethod getWidgetDefinition(widgetKey) [ Internal, Language = javascript ]
{
	var widget = null;
	var model = this.getDefinition();
	if (model && model.widgets) {
		for (var n = 0; n < model.widgets.length; n++) {
			if (model.widgets[n] && model.widgets[n].key==widgetKey) {
				widget = model.widgets[n];
				break;
			}
		}
	}
	return widget;
}

/// Get the definition of this dashboard for the JSON provider.
Method GetDbDefinition(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		If $IsObject(..%dashboard) {
			Set pObject = ..%dashboard
			Set pObject.Timestamp = ..%dashboard.timeModified	// DTB103
			// find display names and apply to model
			For w = 1:1:..%dashboard.widgets.Count() {
				Set tWidget = ..%dashboard.widgets.GetAt(w)
				Set:(tWidget.key="") tWidget.key = $ZCRC(tWidget.name,7)		// DTB633 - Regenerate key if needed
				For c=1:1:tWidget.controls.Count() {
					Set tControl = tWidget.controls.GetAt(c)
					
					// hard code
					Set tControl.locationDisplay = $Case(tControl.location,
						"widget":$$$Text("Widget"),
						"dashboard":$$$Text("Dashboard"),
						"click":$$$Text("Click"),
						:tControl.location
						)

					Set tControl.actionDisplay = $Case(tControl.action,
						"applyFilter":$$$Text("Apply Filter"),
						"applyVariable":$$$Text("Apply Pivot Variable"),
						"setFilter":$$$Text("Set Filter"),
						"reload":$$$Text("Reload Dashboard"),
						"refresh":$$$Text("Refresh"),
						"navigate":$$$Text("Navigate"),
						"newWindow":$$$Text("New Window"),
						"showListing":$$$Text("Show Listing"),
						"showGeoListing":$$$Text("Show GeoListing"),
						"showBreakdown":$$$Text("Show Analysis"),
						"viewDashboard":$$$Text("View Dashboard"),
						"reload":$$$Text("Reload Dashboard"),
						"printWidget":$$$Text("Print Widget"),		// DTB251
						:tControl.action
						)
					
					Set tControl.typeDisplay = $Case(tControl.type,
						"auto":$$$Text("Auto"),
						"searchBox":$$$Text("Search Box"),
						"select":$$$Text("Dropdown"),
						"radioSet":$$$Text("Radio"),
						"button":$$$Text("Button"),
						"hidden":$$$Text("Hidden"),
						"timer":$$$Text("Timer"),
						"custom":$$$Text("Custom"),
						:tControl.type
						)
					
					Set tControl.activeWhenDisplay = $Case(tControl.activeWhen,
						"":$$$Text("Always"),
						"itemSelected":$$$Text("Item Selected"),
						"listingSelected1":$$$Text("1 Listing Item Selected"),
						"listingSelected":$$$Text("Listing Item Selected"),
						:tControl.activeWhen
						)
				}
			}
		}
		Else {
			// + WAL168 -- take autosave into account
			Set tLoadDashboardName = ..dashboardName
			If (..autosave'="") {
				Set tAutosaveDashboardName = ..tempStorageRoot_..autosave_"/"_..dashboardName
				Set tExists = ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(tAutosaveDashboardName)
				If (tExists) {
					Set tLoadDashboardName = tAutosaveDashboardName
				}
			}
			// - WAL168
			
			// DTB103 - the client called this and requires a reload of the object 
			// since ..%dashboard is no longer populated
			//Set tDashboard = ##class(%DeepSee.Dashboard.Utils).%OpenDashboard(..dashboardName,.tSC)
			Set tDashboard = ##class(%DeepSee.Dashboard.Utils).%OpenDashboard(tLoadDashboardName,.tSC) // + WAL168
			
			// DTB747 - Check the reloaded dashboard for empty names.
			Set tSC = ##class(%DeepSee.UserPortal.Utils).AddWidgetNames(tDashboard)
			If $$$ISERR(tSC) Quit
			
			Set pObject = tDashboard
			Set pObject.Timestamp = tDashboard.timeModified
			// find display names and apply to model
			For w = 1:1:tDashboard.widgets.Count() {
				Set tWidget = tDashboard.widgets.GetAt(w)
				Set:(tWidget.key="") tWidget.key = $ZCRC(tWidget.name,7)		// DTB633 - Regenerate key if needed
				For c=1:1:tWidget.controls.Count() {
					Set tControl = tWidget.controls.GetAt(c)
					
					// hard code
					Set tControl.locationDisplay = $Case(tControl.location,
						"widget":$$$Text("Widget"),
						"dashboard":$$$Text("Dashboard"),
						"click":$$$Text("Click"),
						:tControl.location
						)

					Set tControl.actionDisplay = $Case(tControl.action,
						"applyFilter":$$$Text("Apply Filter"),
						"applyVariable":$$$Text("Apply Pivot Variable"),
						"setFilter":$$$Text("Set Filter"),
						"reload":$$$Text("Reload Dashboard"),
						"refresh":$$$Text("Refresh"),
						"navigate":$$$Text("Navigate"),
						"newWindow":$$$Text("New Window"),
						"showListing":$$$Text("Show Listing"),
						"showGeoListing":$$$Text("Show GeoListing"),
						"showBreakdown":$$$Text("Show Analysis"),
						"viewDashboard":$$$Text("View Dashboard"),
						"reload":$$$Text("Reload Dashboard"),
						"printWidget":$$$Text("Print Widget"),		// DTB251
						:tControl.action
						)
					
					Set tControl.typeDisplay = $Case(tControl.type,
						"auto":$$$Text("Auto"),
						"searchBox":$$$Text("Search Box"),
						"select":$$$Text("Dropdown"),
						"radioSet":$$$Text("Radio"),
						"button":$$$Text("Button"),
						"hidden":$$$Text("Hidden"),
						"timer":$$$Text("Timer"),
						"custom":$$$Text("Custom"),
						:tControl.type
						)
					
					Set tControl.activeWhenDisplay = $Case(tControl.activeWhen,
						"":$$$Text("Always"),
						"itemSelected":$$$Text("Item Selected"),
						"listingSelected1":$$$Text("1 Listing Item Selected"),
						"listingSelected":$$$Text("Listing Item Selected"),
						:tControl.activeWhen
						)
				}
			}
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Update the definition of a widget on the server.
ClassMethod UpdateWidget(pWidget As %DeepSee.Component.Widget.widget, pJSON As %String, pWorkList As %ZEN.Component.group, pAction As %String, pControlLocation As %String, pControlIndex As %String, pWidgetControlIndex As %String) As %String [ Internal, ZenMethod ]
{
	Set tSC = $$$OK
	Try {
		// recreate definition from JSON object
		Set tSC = ##class(%ZEN.Auxiliary.jsonProvider).%ParseJSON(pJSON,,.tDef)
		If $$$ISERR(tSC) Quit

		// find widget
		Set tWidgetDef = ""
		If $IsObject(tDef) {
			For n=1:1:tDef.widgets.Count() {
				Set w = tDef.widgets.GetAt(n)
				If (w.key = pWidget.widgetKey) {
					Set tWidgetDef = w
					Quit
				}
			}
		}
				
		// convert properties to array!
		If $IsObject(tWidgetDef) {
			If $IsObject(tWidgetDef.properties) {
				Do tWidgetDef.properties.%CopyToArray(.tProps)
			}
			Set tWidgetDef.properties = ##class(%ArrayOfDataTypes).%New()
			Set p = $O(tProps(""))
			While (p'="") {
				Do tWidgetDef.properties.SetAt(tProps(p),p)
				Set p = $O(tProps(p))
			}
			
			// + WAL070 -- convert overrides to array as well so scorecard
			//             doesn't lose columns
			If $IsObject(tWidgetDef.overrides) {
				Do tWidgetDef.overrides.%CopyToArray(.tOverrides)
			}
			Set tWidgetDef.overrides = ##class(%ArrayOfDataTypes).%New()
			Set o = $O(tOverrides(""))
			While (o'="") {
				Do tWidgetDef.overrides.SetAt(tOverrides(o),o)
				Set o = $O(tOverrides(o))
			}
			// - WAL070

			// + WAL168
			// use JSON version as def
			Set pWidget.%definition = tWidgetDef
			// - WAL168

			Set pWidget.dataSource = $S('$IsObject(pWidget.%definition):"",pWidget.%definition.localDataSource'="":pWidget.%definition.localDataSource,1:pWidget.%definition.dataSource)

			// + WAL064 -- Add to/Remove from dashboard worklist or the widget itself
			If (pControlLocation = "dashboard") {
				If (pAction = "AddControl") {
					// The last control in the list is the new control
					// Make a dummy widget definition that only contains this control
					// %CreateControls will add just this one control
					// and leave the current controls untouched
					Set tNewControl = tWidgetDef.controls.GetAt(tWidgetDef.controls.Count())
					If ($IsObject(tNewControl)) {
						Do tWidgetDef.controls.Clear()
						Do tWidgetDef.controls.InsertAt(tNewControl,1)
					}
					If (tWidgetDef.controls.Count()>0) {
						Set tSC = ..%CreateControls("dashboard",tWidgetDef.controls,pWorkList,pWidget)
						If $$$ISERR(tSC) Quit
					}
				}
				ElseIf ((pAction = "RemoveControl")||(pAction = "EditControl")) {
					// pControlIndex tells us which of this widget's dashboard controls
					// should be removed -- if it is 2, remove the 2nd dashboard located
					// control that belongs to this widget
					Set tWidgetId = pWidget.id
					Set tWorkListIndex=""
					do pWorkList.children.GetNext(.tWorkListIndex)
					Set tDashboardControlCount = 1
					While (1) {
						Set tWorkListItem = pWorkList.children.GetAt(tWorkListIndex)		
						If (tWorkListItem="") Quit
						// Does this control belong to the widget we are updating?
						If (tWorkListItem.id [ ("/"_tWidgetId)) {
							If (tDashboardControlCount = pControlIndex) {
								// + WAL084 -- we've found the control to update
								//             Like the 'RemoveControl' case, we will remove the control
								//             But in the edit case, first add the updated version of the control
								//             the the worklist *before* the old version we will delete
								If (pAction = "EditControl") {
									// Add 1 to index since the index comes from javascript and we are in COS now
									// Here we create only the control to be updated
									Set tEditControlDef = tWidgetDef.controls.GetAt(pWidgetControlIndex+1)
									If ($IsObject(tEditControlDef)) {
										Do tWidgetDef.controls.Clear()
										Do tWidgetDef.controls.InsertAt(tEditControlDef,1)
									}
									// tWorkList is a dummy that is just used to collect the new control
									Set tWorkList = ##class(%ZEN.Component.group).%New()
									Set tSC = ..%CreateControls("dashboard",tWidgetDef.controls,tWorkList,pWidget)
									If $$$ISERR(tSC) Quit
									
									// Grab the updated control from the dummy worklist and add it to the real
									// worklist before deleting the old version of the control
									Set tEditedControl = tWorkList.children.GetAt(1)
									Kill tWorkList
									Do pWorkList.%AddChildBefore(tEditedControl,tWorkListItem)
								}
								// - WAL084 -- remove the old version of the control
								Do pWorkList.%RemoveChild(tWorkListItem)
								Quit	
							}
							Set tDashboardControlCount = $i(tDashboardControlCount)
						}
						do pWorkList.children.GetNext(.tWorkListIndex)		
					}	
				}
			}
			// Control location is "widget"
			Else {
				Set tHeader = pWidget.%FindComponent("header")
				Do tHeader.%RemoveChildren()

				Set tSC = pWidget.%CreateCommandButtons(tHeader)
				If $$$ISERR(tSC) Quit
				// let subclass add components to header group
				Set tSC = pWidget.%OnCreateControls(tHeader)
				If $$$ISERR(tSC) Quit

				If (tWidgetDef.controls.Count()>0) {
					Set tSC = ..%CreateControls("widget",tWidgetDef.controls,tHeader,pWidget)
					If $$$ISERR(tSC) Quit
				}
				// Show or hide the header as needed
				If (tHeader.children.Count() = 0) {
					Set tHeader.enclosingStyle = "display:none;"
					Set pWidget.showToolbar = 0	
				}	
				Else {
					Set tHeader.enclosingStyle = "display:block;"
					Set pWidget.showToolbar = 1
				}
			}
			// - WAL064
			
			// + WAL168
			Set pWidget.%definition = tWidgetDef
			// - WAL168

			// recreate main body
			Set tMainGroup = pWidget.%FindComponent("main")
			Do tMainGroup.%RemoveChildren()

			Set tSC = pWidget.%OnCreateWidget(tMainGroup)
			If $$$ISERR(tSC) Quit
			
			// +DTB194 - Add sidebar to the refreshed widget content
			Set tSC = pWidget.%AddSidebar(tMainGroup)
			If $$$ISERR(tSC) Quit
			// -DTB194
			
			Do pWidget.filterState.Clear()
			Do pWidget.filterText.Clear()

			Set tSC = pWidget.%ApplyFilters()
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Set tMsg = ""
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

/// Set the modified state of this page.
/// Modified flag only appears when user permissions are NOT read-only.
ClientMethod setModified(flag) [ Internal, Language = javascript ]
{
	if (!this._leavingPage && flag!=this.pageModified) {
		this.pageModified = flag;
		
		// Don't show modified flag in read-only mode
		if (!this.readOnly) {
			var html = [];
		
			html[html.length] = $$$Text('Modified');
			html[html.length] = '&nbsp;<image src="deepsee/ds2_x_44_w.png" style="height:12px;vertical-align:middle;" title="'+$$$Text('Cancel Changes') + '" onclick="zenPage.reloadPage();"/>';
			
			this.setPortalTitleMsg(this.pageModified ? html.join('') : '');
		}
	}
}

/// Recreate the given widget on the server and reload it.
ClientMethod recreateWidget(widgetKey, action, controlIndex) [ Internal, Language = javascript ]
{
	if (this._forceReload) {
		// save and reload
		this.setModified(false);
		this.saveDashboard(false);
		return;
	}
	
	// + WAL064
	if (action===undefined) {
		action = '';	
	}
	if (controlIndex===undefined) {
		controlIndex='';	
	}
	// Worklist is now passed to UpdateWidget so that filters can be
	// added/removed in that method
	var worklist = zen("worklistDiv1Group");
	var controlLocation='';
	// - WAL064
	var widgetControlIndex = ''; // WAL084 -- index of control in widget definition control array

	var widget = this.findWidgetByKey(widgetKey);
	var widgetDef = this.getWidgetDefinition(widgetKey);
	
	if (widget && widgetDef) {
		// get current filterState
		this._oldFilterState = null;
		if (widget.getFilterState) {
			this._oldFilterState = widget.getFilterState();
			// + WAL064 -- manually add new control to filter state array so that it
			//             can be used immediately after widget/worklist is redrawn
			if (action == 'AddControl') {
				var newControl = widgetDef.controls[widgetDef.controls.length-1];
				this._oldFilterState += newControl.targetProperty + '\t' + newControl.value + '\n';
				controlLocation = newControl.location
			}
			// - WAL064
		}
		// + WAL064
		if ((action == 'RemoveControl') || (action == 'EditControl')) { // + WAL084 -- need to fund the index for edit control actions as well
			// Find location of control we are removing
			controlLocation = widgetDef.controls[controlIndex].location;
			widgetControlIndex = controlIndex; // WAL084 -- index into widget definition controls array
			var dashboardControlCount=1;
			// If only the dashboard-located controls for this widget were a list,
			// which place would this control have? This is used to find the control's 
			// place in the worklist
			if (controlLocation == 'dashboard') {
				for (var i=0;i<widgetDef.controls.length;i++) {
					if (widgetDef.controls[i].location == 'dashboard') {
						if (i == controlIndex) {
							break;
						}
						++dashboardControlCount;
					}
				}
			}
			// Remove the control from the definition's control array before converting to JSON
			// + WAL084 -- In 'EditControl' case we don't want to delete the control, just update it, so leave in in the definition
			if (action == 'RemoveControl') {
				widgetDef.controls.splice(controlIndex,1);	
			}
			// - WAL084
			controlIndex = dashboardControlCount;
		}
		// - WAL064

		// convert entire def to JSON to ship to server
		var dbdef = widget.componentToJSON(this.getDefinition(),0,{});

		// prevent other changes
		var nav = zenPage.getNavigator();
		if (nav) {
			nav.setProperty('disabled',true);
		}

		// + WAL064 -- just handle portlets the old fashioned way for now	
		if (widgetDef.type == 'portlet') {
			this._forceReload = true;
			this.saveDashboard(false);
			return;
		}
		// - WAL064

		// force synchronous update
		var mode = zenSynchronousMode;
		zenSynchronousMode = true;
		// + WAL064 -- Pass worklist, action type, and index to control in widget's control definition array
		//             controlIndex is used to determine which control to remove from the worklist
		var msg = this.UpdateWidget(widget,dbdef,worklist,action,controlLocation,controlIndex,widgetControlIndex);
		// - WAL064
		if (msg) {
			alert(msg);
		}
		zenSynchronousMode = mode;

		// defer
		setTimeout("zenPage.recreateHandler('"+widgetKey+"');",40);
	}
}

/// Called after a widget is recreated.
ClientMethod recreateHandler(widgetKey) [ Language = javascript ]
{
	var widget = this.findWidgetByKey(widgetKey);
	
	// restore filter state
	if (this._oldFilterState) {
		widget.setFilterState(this._oldFilterState);
		widget.applyFilters(true);
	}

	zenPage.adjustSizes(true);

	var nav = zenPage.getNavigator();
	if (nav) {
		nav.setProperty('disabled',false);
	}
}

/// Fetch the given list of options from the server.
ClientMethod fetchOptionList(which, spec, properties) [ Language = javascript ]
{
	var json = zen('jsonOptionList');

	// only load if the request is for something different
	if (which != zen('jsonOptionWhich').value || spec != zen('jsonOptionSpec').value) {
		zen('jsonOptionWhich').value = which;
		zen('jsonOptionSpec').value = spec;
			
		// +DTB111 - pass properties as a string to the server on reload of the json object
		var propertyString = '';
		if (properties) {
			for (var prop in properties) {
				var delim = propertyString.length > 0 ? '~' : '';
				propertyString += delim + prop + ':' + properties[prop]; 
			}
		}
		zen('jsonOptionSettings').value = propertyString;
		// -DTB111
		json.reloadContents();
	}

	var list = json.getContentObject();
	if (!list || !list.children) {
		list = {children:[]};
	}
	return list;
}

/// Return JSON array of options.<br/>
Method GetOptionList(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pMetaData = $LB("value","caption","hint","image")

		Set tWhich = $G(pParameters("which"))
		Set tSpec = $G(pParameters("spec"))
		Set tJSONWidgetSettings = $G(pParameters("settings"))		// DTB111
		Set tCount = 0

		If (tWhich = "control-actions") {
			// list of actions for widget control: spec is dataSource
			Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetDashboardActionList(.tActions,tSpec)
			If $$$ISERR(tSC) Quit
			
			// +DTB229
			Set tListingCount = 0
			Set tGeoListingCount = 0
			
			Kill tListings
			Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetListingsForDataSource(tSpec,.tListings,"table")
			If $$$ISERR(tSC) Quit

			Set a = $O(tListings(""))
			While (a'="") {
				Set tListingCount = tListingCount + 1
				Set a = $O(tListings(a))
			}
	
			Kill tListings
			Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetListingsForDataSource(tSpec,.tListings,"map")
			If $$$ISERR(tSC) Quit

			Set a = $O(tListings(""))
			While (a'="") {
				Set tGeoListingCount = tGeoListingCount + 1
				Set a = $O(tListings(a))
			}
			
			Kill tListings
			// -DTB229
			
			Set tIKnowMeasureCount = 1

			Set a = $O(tActions(""))
			While (a'="") {
				Set tValue = $LG(tActions(a),1)
				Set tSkip = 0
				If ((tValue="showListing")&&(tListingCount=0)) {
					Set tSkip = 1
				}
				ElseIf ((tValue="showGeoListing")&&(tGeoListingCount=0)) {
					Set tSkip = 1
				}
				ElseIf ((tValue="showIKnowMsrValue")&&(tIKnowMeasureCount=0)) {
					Set tSkip = 1
				}
				If ('tSkip) {
					Set pData($I(tCount)) = $LB(tValue,$LG(tActions(a),2),$LG(tActions(a),3),"")
				}
				Set a = $O(tActions(a))
			}
		}
		ElseIf (tWhich = "control-filters") {
			// list of filters for widget control: spec is dataSource
			Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetFiltersForDataSource(tSpec,.tFilters)
			If $$$ISERR(tSC) Quit

			Set a = $O(tFilters(""))
			While (a'="") {
				Set pData($I(tCount)) = $LB($LG(tFilters(a),2),$LG(tFilters(a),1),"","")
				Set a = $O(tFilters(a))
			}

			// add *searchable* measures to the lists
			Set tExt = $P(tSpec,".",$L(tSpec,"."))
			If (tExt = "pivot") {
				Set tPivot = ""
				If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(tSpec)) {
					// DTB580 - Only set the folder item if we know it exists
					Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tSpec,.tSC)
					If $$$ISERR(tSC) Quit
				}
				If '$IsObject(tPivot) Quit

				Set tSC = ##class(%DeepSee.Utils).%GetCubeSearchableMeasures(tPivot.%GetCubeName(),.tMeasures)
				If $$$ISERR(tSC) Quit

				Set n = $O(tMeasures(""))
				While (n'="") {
					Set pData($I(tCount)) = $LB("[Measures].["_$LG(tMeasures(n),2)_"]","Measures."_$LG(tMeasures(n),1),"","")
					Set n = $O(tMeasures(n))
				}
			}
		}
		ElseIf (tWhich = "control-pivotVariables") {
			// JMD1276: list of pivot variables for widget control: spec is dataSource
			Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetPivotVariablesForDataSource(tSpec,.tVariables)
			If $$$ISERR(tSC) Quit

			Set a = $O(tVariables(""))
			While (a'="") {
				Set pData($I(tCount)) = $LB("$variable."_$LG(tVariables(a),1),$LG(tVariables(a),2),"","")
				Set a = $O(tVariables(a))
			}
		}
		ElseIf (tWhich="user-icons") {
			Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetUserIconList(.tIcons)
			If $$$ISERR(tSC) Quit
			Set k = $O(tIcons(""))
			While (k'="") {
				Set pData($I(tCount)) = $LB("@"_$LG(tIcons(k),1),,,$LG(tIcons(k),2))
				Set k = $O(tIcons(k))
			}
		}
		ElseIf (tWhich="widget-property") {
			// list of data values for widget: spec is dataSource
			Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetPropertiesForDataSource(tSpec,.tProps)
			If $$$ISERR(tSC) Quit

			Set a = $O(tProps(""))
			While (a'="") {
				// JMD1426: escape numbers!
				Set tVal = tProps(a)
				If (tVal=+tVal) {
					Set tVal = "=["_tVal_"]"
				}
				Set pData($I(tCount)) = $LB(tVal,tProps(a))
				Set a = $O(tProps(a))
			}
		}
		ElseIf (tWhich="widget-themes") {
			// list of themes for widget.
			Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetThemeList(.tThemes)
			If $$$ISERR(tSC) Quit

			Set pData($I(tCount)) = $LB("",$$$Text("No Theme"))		// DTB124 - Add localization

			Set a = $O(tThemes(""))
			While (a'="") {
				// JMD1201: clean up name
				Set tName = $LG(tThemes(a),2)
				Set tName = $P(tName,".",1)
				// JMD1344 localize
				Set tName = ##class(%DeepSee.UserPortal.Utils).%ResolveText(tName)
				If ($E(tName)'="$") {
					Set pData($I(tCount)) = $LB($LG(tThemes(a),2),tName)
				}
				Set a = $O(tThemes(a))
			}
		}
		ElseIf (tWhich="control-listing") {
			// list of listings for widget control: spec is dataSource
			Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetListingsForDataSource(tSpec,.tListings,"table")
			If $$$ISERR(tSC) Quit

			Set a = $O(tListings(""))
			While (a'="") {
				Set pData($I(tCount)) = $LB($LG(tListings(a),2),$LG(tListings(a),1))
				Set a = $O(tListings(a))
			}
		}
		ElseIf (tWhich="control-geolisting") {
			// list of geolistings for widget control: spec is dataSource
			Set tSC = ##class(%DeepSee.Dashboard.Utils).%GetListingsForDataSource(tSpec,.tListings,"map")
			If $$$ISERR(tSC) Quit

			Set a = $O(tListings(""))
			While (a'="") {
				Set pData($I(tCount)) = $LB($LG(tListings(a),2),$LG(tListings(a),1))
				Set a = $O(tListings(a))
			}
		}
		ElseIf (tWhich="control-breakdown") {
			Set pData($I(tCount)) = $LB("_DeepSee.UI.Analysis.Clustering.zen",$$$Text("Clustering"))
			Set pData($I(tCount)) = $LB("_DeepSee.UI.Analysis.Distribution.zen",$$$Text("Distribution"))
			Set pData($I(tCount)) = $LB("_DeepSee.UI.Analysis.Regression.zen",$$$Text("Regression"))
			if (1) { // perhaps check if there's any iKnow measures first?
				Set pData($I(tCount)) = $LB("_iKnow.DeepSee.UI.Analysis.Content.zen",$$$Text("iKnow - Content"))
				Set pData($I(tCount)) = $LB("_iKnow.DeepSee.UI.Analysis.Entities.zen",$$$Text("iKnow - Entities"))
			}
		}
		ElseIf (tWhich="widget-settings") {
			// list of widget properties; spec is widgetType:subtype
			// $lb("XgridLines",0,"%Boolean","X Grid Lines","Turn on chart grid lines",hidden,dlist)
			Set pMetaData = $LB("value","caption","hint","type","defValue","hidden","displayList")

			// +DTB111
			If (tJSONWidgetSettings'="") {
				Set tSettings = $L(tJSONWidgetSettings,"~")
				For p = 1:1:$L(tJSONWidgetSettings,"~") {
					Set tSetting = $P(tJSONWidgetSettings,"~",p)
					Set tSettings($$$UPPER($P(tSetting,":",1))) = $P(tSetting,":",2)
				}
			}
			// -DTB111
		
			Set tWidgetType = $P(tSpec,":",1)
			Set tWidgetSubtype = $P(tSpec,":",2)
			Set tClass = ##class(%DeepSee.Dashboard.Utils).%GetWidgetClass(tWidgetType)
			If (tClass'="") {
				If ((tWidgetType="portlet")&&$D(tSettings)) {
					// DTB111 - only portlets allow settings to be passed to the callback
					Do $classmethod(tClass,"%GetWidgetPropertyInfo",tWidgetSubtype,.tList,.tSettings)
				}
				Else {
					Do $classmethod(tClass,"%GetWidgetPropertyInfo",tWidgetSubtype,.tList)	
				}
				Set n = $O(tList(""))
				While (n'="") {
					Set pData($I(tCount)) = $LB($LG(tList(n),1),$LG(tList(n),4),$LG(tList(n),5),$LG(tList(n),3),$LG(tList(n),2),+$LG(tList(n),6),$LG(tList(n),7))
					Set n = $O(tList(n))
				}
			}
		}
		ElseIf (tWhich="dbResources") {
			// list of resources
			Set pMetaData = $LB("value","caption")
			Set tSC = ..%GetResourceList(.pData)
		}
		ElseIf (tWhich="image-list") {
			// list of images in "covers" directory
			Set pMetaData = $LB("image","caption","value")
			Set pData($I(pData)) = $LB("",$$$Text("No Image"),"")

			Set tSC = ##class(%DeepSee.UI.Dialog.BookCoverBuilder).GetImageList(,.tMetaData,.tData)
			Set k = $O(tData(""))
			While (k'="") {
				Set pData($I(pData)) = $LB($LG(tData(k),1),$LG(tData(k),2),$LG(tData(k),1))
				Set k = $O(tData(k))
			}
		}

		// JMD- work-around for JSON array trouble
		Set pData=""
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Launch the new control wizard.
ClientMethod addControlDef() [ Language = javascript ]
{
	var model = zenPage.getDefinition();
	var widgetDef = this.getWidgetDefinition(zenPage.currWidgetKey);

	// list of target widget names
	var names = [];
	if (model) {
		for (var n = 0; n < model.widgets.length; n++) {
			if (widgetDef.name != model.widgets[n].name && model.widgets[n].name) {
				names[names.length] = model.widgets[n].name;
			}
		}
	}
	
	var controlTarget = (('controlPanel'==widgetDef.type) ? '*' : '');		// DTB442 - Add control target
	
	var parms = {
		DASHBOARD:this.dashboardName,
		DATASOURCE:widgetDef.dataSource,
		WIDGETNAME:'',
		WIDGETNAMES:names.join(','),
		NUMBER:'',
		TARGET:controlTarget
	};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.ControlWizard.zen','AddControl','status,scrollbars,resizable=yes,width=800,height=650',parms);
}

/// Launch the new data property wizard.
ClientMethod addDataPropertyDef() [ Language = javascript ]
{
	var model = zenPage.getDefinition();
	var widgetDef = this.getWidgetDefinition(zenPage.currWidgetKey);
	
	var parms = {
		DASHBOARD:this.dashboardName,
		DATASOURCE:widgetDef.dataSource,
		WIDGETNAME:'',
		NUMBER:'',
		WIDGETTYPE:'pivot'
	};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.DataPropertyWizard.zen','AddDataProperty','status,scrollbars,resizable=yes,width=800,height=650',parms);
}

/// Save the selected widget to the widget catalog.
ClientMethod saveWidgetToCatalog() [ Language = javascript ]
{
	// these properties are used to get the input from the dialog
	zenPage.widgetTemplateName = '';
	zenPage.widgetDescription = '';
	zenPage.widgetResource = '';
	zenPage.widgetOwner = '';
	zenPage.widgetKeywords = '';

	var model = zenPage.getDefinition();
	var widgetDef = this.getWidgetDefinition(zenPage.currWidgetKey);
	if (widgetDef) {
		// show save dialog
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.WidgetSave.cls','WidgetSaveToCatalog','status,scrollbars,resizable=yes,width=700,height=600');
	}
	else {
		alert($$$Text('Please select a widget.'));
	}
}

ClientMethod getPreviewImage() [ Language = javascript ]
{
	var svgUtil = zen('svgUtil');
	var widget = this.getCurrWidget();
	var imgSrc = null;
	if (widget) {
		if (svgUtil) {
			var svgFrameId = widget.id+'/svgFrame';
			var svg = svgUtil.getSVGDOMRoot(svgFrameId);
			if (svg) {
				imgSrc = svgUtil.extractSVGSource(svg,'','');
				imgSrc[0]='';
				imgSrc[1]='';
				imgSrc[2]='';
			}
		}
	}
	return (imgSrc);
}

/// Launch the pdf options dialog.
ClientMethod showPDFOptions() [ Language = javascript ]
{
	var widget = this.getCurrWidget();
	if (widget && widget.getPivot) {
		var table = widget.getPivot();
		var widgetDef = this.getWidgetDefinition(zenPage.currWidgetKey);

		// find number of columns in pivot
		var colCount = 1;
		if (table.getContent() && table.getContent().columnCount) {
			colCount = table.getContent().columnCount;
		}

		// get filters so we know how many filters we have JSL4196
		var filterNames = [];
		var filterValues = [];
		table.getFilterInfo(filterNames,filterValues);
		filterRowCount = filterNames.length;

		var parms = {
				CUBE:this.cubeName,
				MODE:(widget.pivotView=='chart'?'chart':'table'),
				COLUMNCOUNT:colCount,
				LISTING:table.listing,
				LISTINGROWS:table.listingRows,
				ROWTOTALS:table.rowTotals?1:0,
				COLUMNTOTALS:table.columnTotals?1:0,
				ROWSPAN:table.rowLabelSpan?1:0,
				COLUMNSPAN:table.columnLabelSpan?1:0,
				ROWEMPTY:table.showEmptyRows?1:0,
				COLUMNEMPTY:table.showEmptyColumns?1:0,
				ROWSTYLE:table.rowHeaderStyle,
				COLUMNSTYLE:table.columnHeaderStyle,
				CELLSTYLE:table.cellStyle,
				CELLWIDTH:table.cellWidth,
				CELLHEIGHT:table.cellHeight,
				ZEBRA:table.showZebra?1:0,

				PAGESIZE:zenGet(widgetDef.properties.printPageSize,table.printPageSize),
				ORIENTATION:zenGet(widgetDef.properties.printOrientation,table.printOrientation),
				MARGINTOP:zenGet(widgetDef.properties.printMarginTop,table.printMarginTop),
				MARGINBOTTOM:zenGet(widgetDef.properties.printMarginBottom,table.printMarginBottom),
				MARGINLEFT:zenGet(widgetDef.properties.printMarginLeft,table.printMarginLeft),
				MARGINRIGHT:zenGet(widgetDef.properties.printMarginRight,table.printMarginRight),
				CMARGINTOP:zenGet(widgetDef.properties.chartMarginTop),
				CMARGINBOTTOM:zenGet(widgetDef.properties.chartMarginBottom),
				CMARGINLEFT:zenGet(widgetDef.properties.chartMarginLeft),
				CMARGINRIGHT:zenGet(widgetDef.properties.chartMarginRight),
				PRINTLABELWIDTH:zenGet(widgetDef.properties.printLabelWidth,table.printLabelWidth),
				PRINTCELLWIDTH:zenGet(widgetDef.properties.printCellWidth,table.printCellWidth),
				TITLE:zenGet(widgetDef.properties.printTitle,table.printTitle),
				SUBTITLE:zenGet(widgetDef.properties.printSubtitle,table.printSubtitle),
				SUBTITLEON:zenGet(widgetDef.properties.printSubtitleOn,table.printSubtitleOn),
				SHOWUSER:zenGet(widgetDef.properties.showUser,table.showUser),
				SHOWFILTERS:zenGet(widgetDef.properties.showFilters,table.showFilters),
				SHOWLISTINGFILTERS:zenGet(widgetDef.properties.showListingFilters,table.showListingFilters),
				LISTINGFONTSIZE:zenGet(widgetDef.properties.listingFontSize,table.listingFontSize),
				SHOWDATE:zenGet(widgetDef.properties.showDate,table.showDate),
				SHOWZEBRASTRIPES:zenGet(widgetDef.properties.showZebraStripes,table.showZebraStripes),
				FILTERROWCOUNT:filterRowCount,
				BORDERLEFTCELL:zenGet(widgetDef.properties.borderLeftCell,table.borderLeftCell),
				BORDERRIGHTCELL:zenGet(widgetDef.properties.borderRightCell,table.borderRightCell),
				BORDERTOPCELL:zenGet(widgetDef.properties.borderTopCell,table.borderTopCell),
				BORDERBOTTOMCELL:zenGet(widgetDef.properties.borderBottomCell,table.borderBottomCell),
				BORDERLEFTCOL:zenGet(widgetDef.properties.borderLeftCol,table.borderLeftCol),
				BORDERRIGHTCOL:zenGet(widgetDef.properties.borderRightCol,table.borderRightCol),
				BORDERTOPCOL:zenGet(widgetDef.properties.borderTopCol,table.borderTopCol),
				BORDERBOTTOMCOL:zenGet(widgetDef.properties.borderBottomCol,table.borderBottomCol),
				BORDERLEFTROW:zenGet(widgetDef.properties.borderLeftRow,table.borderLeftRow),
				BORDERRIGHTROW:zenGet(widgetDef.properties.borderRightRow,table.borderRightRow),
				BORDERTOPROW:zenGet(widgetDef.properties.borderTopRow,table.borderTopRow),
				BORDERBOTTOMROW:zenGet(widgetDef.properties.borderBottomRow,table.borderBottomRow),
				// + WAL100
				FONTFAMILYCELL:zenGet(widgetDef.properties.fontFamilyCell,table.fontFamilyCell),
				FONTSIZECELL:zenGet(widgetDef.properties.fontSizeCell,table.fontSizeCell),
				FONTFAMILYCOL:zenGet(widgetDef.properties.fontFamilyCol,table.fontFamilyCol),
				FONTSIZECOL:zenGet(widgetDef.properties.fontSizeCol,table.fontSizeCol),
				FONTFAMILYROW:zenGet(widgetDef.properties.fontFamilyRow,table.fontFamilyRow),
				FONTSIZEROW:zenGet(widgetDef.properties.fontSizeRow,table.fontSizeRow),
				// - WAL100
				FILTERTABLESTYLE:zenGet(widgetDef.properties.filterTableStyle,table.filterTableStyle),
				FILTERTABLECAPTIONSTYLE:zenGet(widgetDef.properties.filterTableCaptionStyle,table.filterTableCaptionStyle),
				FILTERTABLEITEMSTYLE:zenGet(widgetDef.properties.filterTableItemStyle,table.filterTableItemStyle),
				NOWDISPLAYFORMAT:zenGet(widgetDef.properties.nowDisplayFormat,table.nowDisplayFormat),
				ROWCAPTION:table.showRowCaption?1:0,
				MAXROWS:zenGet(widgetDef.properties.maxRows,table.maxRows),
				IMAGESOURCE:1
		};

		zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotPrintOptions.zen','WidgetPrintOptions','status=no,scrollbars=no,resizable,width=850,height=600',parms);
	}
}

/// Save the selected widget styles to the theme catalog.
ClientMethod saveWidgetToTheme() [ Language = javascript ]
{
	var widgetDef = this.getWidgetDefinition(zenPage.currWidgetKey);
	if (widgetDef) {
		// show save to theme dialog
		var parms = {
			THEME:widgetDef.theme
		};
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.WidgetSaveToTheme.cls','WidgetSaveToTheme','status,scrollbars,resizable=yes,width=700,height=600',parms);
	}
	else {
		alert($$$Text('Please select a widget.'));
	}
}

/// Save the given style overrides to the named theme. Create the theme if is does not exist.
ClassMethod SaveTheme(pThemeName As %String, pOverrides As %ZEN.proxyObject) As %String [ Internal, ZenMethod ]
{
	Set tMsg = ""
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(%DeepSee.Dashboard.Utils).%SaveTheme(pThemeName,pOverrides)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// Delete the named theme.
ClassMethod DeleteTheme(pThemeName As %String) As %String [ Internal, ZenMethod ]
{
	Set tMsg = ""
	Set tSC = $$$OK
	Try {
		Set tSC = ##class(%DeepSee.Dashboard.Utils).%DeleteTheme(pThemeName)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// Get a list of system resources.
ClassMethod %GetResourceList(Output pList) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Kill pList
		Set tNS = $namespace
		ZN "%SYS"
		Set pList($I(pList)) = $LB("",$$$Text("No Resource","%DeepSee"))

		Set tRS = ##class(%ResultSet).%New()
		Set tRS.ClassName = "Security.Resources"
		Set tRS.QueryName = "List"
		Set tSC =  tRS.%Execute()
		While (tRS.%Next()) {
			Set tName = tRS.%Get("Name")
			If ($E(tName)'="%") {
				Set pList($I(pList)) = $LB(tName,tName)
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	// close while still in %SYS ns!
	Set tRS = ""
	ZN tNS
	Quit tSC
}

/// Launch the color chooser.
ClientMethod launchColorChooser() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.ColorWheel.zen','ColorWheel','status,scrollbars,resizable=yes,width=400,height=650');
}

/// Set the data source for the given widget.
ClassMethod SetDataSource(pWidget As %DeepSee.Component.Widget.widget, pPivotTable As %DeepSee.Component.pivotTable, pDataSource As %String, pOverrides As %String = "") As %String [ Internal, ZenMethod ]
{
	// JMD1139
	Set tMsg = ""
	Set tSC = $$$OK
	Try {
		// +DTB480 - Some settings need to be reset as soon as the data source is changed
		If pPivotTable.rowAxisOptions.headEnabled {
			Set tRowHeadCount = pPivotTable.rowAxisOptions.headCount
		}
		If pPivotTable.rowAxisOptions.orderEnabled {
			Set tRowOrderDirection = pPivotTable.rowAxisOptions.orderDirection
		}
		If pPivotTable.columnAxisOptions.headEnabled {
			Set tColumnHeadCount = pPivotTable.columnAxisOptions.headCount
		}
		If pPivotTable.columnAxisOptions.orderEnabled {
			Set tColumnOrderDirection = pPivotTable.columnAxisOptions.orderDirection
		}
		// -DTB480
		
		If (pWidget.dataSource '= pDataSource) {
			Set pWidget.dataSource = pDataSource
			If (pWidget.%IsA("%DeepSee.Component.Widget.pivot")) {
				Set tSC = pWidget.%LoadPivotInfo(pDataSource,pPivotTable,pOverrides)	// DTB218 - Pass through the overrides
				If $$$ISERR(tSC) Quit
			}
			// + WAL173 && AGK
			Elseif ($P(pDataSource,".",$L(pDataSource,".")) = "pivot") { 
				Set tPivotDef = ""
				If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(pDataSource)) {
					// DTB580 - Only set the folder item if we know it exists
					Set tPivotDef = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pDataSource,.tSC)
					If $$$ISERR(tSC) Quit
				}
				If '$IsObject(tPivotDef) Quit
			    Set tSC = tPivotDef.%CopyToComponent(pPivotTable) 
				If $$$ISERR(tSC) Quit
			}
			// - WAL173 && AGK
			Else {
				// KPI and non-pivot
				Set tExt = $P(pDataSource,".",$L(pDataSource,"."))
				If (tExt = "kpi") {
					Set tName = $P(pDataSource,".",1,$L(pDataSource,".")-1)
					Set tKPIClass = ##class(%DeepSee.Utils).%GetKPIClass(tName)
				}
				ElseIf (tExt = "metric") {
					Set tKPIClass = "Ens.BusinessMetricKPI"
				}
				ElseIf (tExt = "worksheet") {
					Set tKPIClass = "%DeepSee.KPIWorksheet"
				}
	
				// pPivotTable is a controller
				Set pPivotTable.modelClass = tKPIClass
				If (tExt = "metric") {
					Set pPivotTable.modelId = pDataSource
				}
				ElseIf (tExt = "worksheet") {
					Set pPivotTable.modelId = pDataSource
				}
			}
			
			// +DTB480 - Restore settings
			If ($G(tRowHeadCount)'="") {
				Set pPivotTable.rowAxisOptions.headEnabled = 1
				Set pPivotTable.rowAxisOptions.headCount = tRowHeadCount
			}
			If ($G(tRowOrderDirection)'=""){
				Set pPivotTable.rowAxisOptions.orderEnabled = 1
				Set pPivotTable.rowAxisOptions.orderDirection = tRowOrderDirection
			}
			If ($G(tColumnHeadCount)'="") {
				Set pPivotTable.columnAxisOptions.headEnabled = 1
				Set pPivotTable.columnAxisOptions.headCount = tColumnHeadCount
			}
			If ($G(tColumnOrderDirection)'="") {
				Set pPivotTable.columnAxisOptions.orderEnabled = 1
				Set pPivotTable.columnAxisOptions.orderDirection = tColumnOrderDirection
			}
			// -DTB480
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

/// Get the contents of the small menu in the title area.
Method %OnGetSmallMenu(Output pMenu)
{
	// $LB(caption,title,script)
	Set pMenu($I(n)) = $LB($$$Text("Home"),$$$Text("Go to the Home page"),"zenPage.goHome();")
	Set pMenu($I(n)) = $LB($$$TextHTML("About"),$$$TextHTML("Display the About page"),"return zenPage.showAbout();")
	If ('..readOnly) {
		Set pMenu($I(n)) = $LB($$$Text("Save"),$$$Text("Save this dashboard"),"zenPage.saveDashboard(false);")
	}
	Set pMenu($I(n)) = $LB($$$Text("Logout"),$$$Text("End this session"),"zenPage.logout();")
}

/// Generate a nonce for an MDX query or XML payload.
ClassMethod CreateQueryNonce(pQuery As %String, pMode As %String = "MDX") As %String [ Internal, ZenMethod ]
{
	// WAL009
	If ($G(pMode)="") { Set pMode = "MDX" }
	Quit ##class(%DeepSee.Utils).%CreateQueryNonce(pQuery, pMode)
}

/// Generate a nonce for parameter value. This function will perform UTF8 conversion.
ClassMethod CreateParameterNonce(pParmValue As %String) As %String [ Internal, ZenMethod ]
{
	// JSL4171
	Quit ##class(%DeepSee.Utils).%CreateParameterNonce(pParmValue)
}

///  Ensure that auto-logout is not blocked by onunloadHandler checking for unsaved changes 
ClientMethod onlogoutHandler() [ Language = javascript ]
{
	this.autosave = '';
	return true;
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	// DP-427970 - Call the autosave for browsers which support unload activity.
	zenPage.runAutosave();
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	// JSL4479
	try {
		this.invokeSuper('onloadHandler',arguments);
		if (zenPage.canWrite) {		// DTB646
			zenPage.initializeSourceControl();	// DTB103
		}
		
		this.setBackground("color", this.getDefinition().backgroundColor);	
		this.setBackground("image", this.getDefinition().backgroundImage);	
		this.setBackground("repeat", this.getDefinition().backgroundRepeat);	
		this.setBackground("size", this.getDefinition().backgroundSize);	
		this.setBackground("opacity", this.getDefinition().backgroundOpacity);
		this.setTitleBarColorAndOpacity(); // + WAL071
		if (this.getDefinition().widgetBordersToggle) {
			//this.setBorder(this.getDefinition().widgetBorders); // JSL4482
			this.widgetBordersSwitch = "edit";
			this.setFromBorderValues(); // JSL4482
		} else {
			this.widgetBordersSwitch = "edit";
			this.setBorder("none"); // JSL4482
		}
		
		if ((this.widgetNamesAdded)&&(!this.readOnly)) {
			// DTB471 - Notify the developer if names were added. The end user will not be notified.
			this.setModified(true);
			alert($$$Text("Some widgets on this dashboard did not have names. "+
							"Names have been automatically assigned to allow editing to function properly. "+
							"The dashboard must be saved to commit these names."));
		}
		this.navGetContentForLevel(1, "WidgetList", "");
		
	} catch (ex) {
		alert(ex);
	}
}

/// Return the internal name of the current document, including the three letter
/// extension in upper-case. For example, MyPackage.MyClass.CLS would be the internal name
/// for the class MyPackage.MyClass.
/// Subclasses MUST override this method.
Method GetInternalName() As %String
{
	Set tName = ""
	// DTB103
	Set tDashboard = ##class(%DeepSee.Dashboard.Utils).%OpenDashboard(..dashboardName,.tSC)
	If $IsObject(tDashboard) {
		Set tName = tDashboard.documentNameGet()
	}
	Quit tName
}

/// Get the jsonProvider object on the client.
/// Subclasses MUST override this method to return the jsonProvider.
ClientMethod getClientModel() [ Language = javascript ]
{
	// DTB103
	return zen('jsonDbDefinition');
}

/// Return the current name of the class/object being modified.
/// Subclasses MUST override this method to return the correct name.
ClientMethod getCurrentName() [ Language = javascript ]
{
	// DTB103
	return this.dashboardName.replace(/\//g,'-').replace(/\\/g,'~');
}

/// Set <property>readOnly</property> to the value of <var>readOnly</var>.
/// Subclasses MUST implement this method to update the controls on the page
/// so that the page's behaviour actually matches the value of the readOnly flag.
ClientMethod setReadOnly(readOnly) [ Language = javascript ]
{
	// DTB103
	this.readOnly = !!readOnly;
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
	
	If ..canWrite {		// DTB646 -  Check privileges for source control button display
		Set tSC = ..%DrawSourceControlHead()	// DTB103
	}

	Quit $$$OK
}

/// Save the pivot table so we have an autosaved version
ClassMethod SavePivotTable(pPivot As %DeepSee.Component.pivotTable, autoSavePivotName As %String) As %String [ ZenMethod ]
{
	// + WAL112 -- method added
	//             called from onunloadHandler to preserve pivot table component state
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		Set tSavePivot = ""
		If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(autoSavePivotName)) {
			// DTB580 - Only set the folder item if we know it exists
			Set tSavePivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(autoSavePivotName,.tSC)
			If $$$ISERR(tSC) Quit
		}
		If '$IsObject(tSavePivot) {
			Set tSavePivot = ##class(%DeepSee.Dashboard.Pivot).%New()
		}
		
		If $$$ISERR(tSC) Quit

		Set tSavePivot.fullName = autoSavePivotName

		// Copy pivot settings into definition object
		Set tSC = tSavePivot.%CopyFromComponent(pPivot)
		If $$$ISERR(tSC) Quit

		Set tSC = tSavePivot.%Save()
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tSC
	// - WAL112
}

/// Return the string used as the command when sending JSON content to the server.
/// The OnSubmitContent handler for the jsonProvider MUST support two action types.
ClientMethod getSaveAction(force) [ Language = javascript ]
{
	// DTB103
	return (force ? 'force' + this.saveAction : this.saveAction);
}

/// Return the extension used by Studio for the class/object.
/// This is ".CLS" by default, but subclasses should override this method
/// if a different extension is in use.
ClientMethod getCurrentExtension() [ Language = javascript ]
{
	// DTB103
	return '.DFI';
}

ClientMethod setConnectivityStatusMsg(msg) [ Language = javascript ]
{
	// Method overriden by DTB789 - This needs specific handling for this page since the title bar is non-standard.
	var systemStyle = "text-align: center; background: #aa4040; color:#ffffff; font-size:10pt; padding:2px;"
	var msgHTML='<div title="'+msg+'" style="'+systemStyle+'">No Connection</div>';
	this.setPortalTitleMsg(msgHTML);
}

/// Handle a source control menu selection.
ClientMethod chooseSCMenu(menuName, commandName, saveFlags) [ Language = javascript ]
{
	// Method overidden by DTB646
	if ((typeof menuName == 'string') && (menuName.length != '') && (typeof commandName == 'string') && (commandName.length != '')) {
		if (this.pageModified && (typeof saveFlags == 'string')) {
			if ((saveFlags.charAt(0) == '1') || (saveFlags.charAt(2) == '1')) {
				this.saveDocument();
			}
		}
		this.invokeSourceControl(menuName+','+commandName);
	}
	
	zenPage.reloadPage();		// DTB646 - Reload the page to refresh state
}

}
