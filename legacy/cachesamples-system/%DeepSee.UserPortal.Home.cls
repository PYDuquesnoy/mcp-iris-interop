/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Home page for the User Portal.<br/>
/// This provides end users a way to access reports, dashboards etc.
Class %DeepSee.UserPortal.Home Extends %DeepSee.UserPortal.standardPage [ System = 4 ]
{

/// Name of this page.
Parameter PAGENAME = "UserPortal Home";

/// URL of home page (used in links).
Parameter HOMEPAGE = "_DeepSee.UserPortal.Home.zen";

/// Starting view for worklist 1.
Parameter WORKLIST1VIEW;

/// Starting view for worklist 2.
Parameter WORKLIST2VIEW;

/// Current folder name.
Property folderName As %ZEN.Datatype.string;

/// Name of the new dashboard.
Property dashboardName As %ZEN.Datatype.string;

/// Title of the new dashboard.
Property dashboardTitle As %ZEN.Datatype.string;

/// Description of the new dashboard.
Property dashboardDescription As %ZEN.Datatype.string;

/// Owner of the currently displayed dashboard.
Property dashboardOwner As %ZEN.Datatype.string;

/// Resource for the currently displayed dashboard.
Property dashboardResource As %ZEN.Datatype.string;

/// If true, the dashboard uses the new snapGrid desktop and ignores the
/// the <property>dashboardSnapTo</property> property.
Property dashboardSnapGrid As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Is dashboard in "snap to" mode.
Property dashboardSnapTo As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If dashboard uses snap grid, then this is then number of grid rows.
Property dashboardGridRows As %ZEN.Datatype.integer [ InitialExpression = 2 ];

/// If dashboard uses snap grid, then this is then number of grid columns.
Property dashboardGridCols As %ZEN.Datatype.integer [ InitialExpression = 2 ];

/// Does this dashboard allow the user to move and resize widgets.
Property dashboardResize As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Does this dashboard allow the user to modify widgets.
Property dashboardModify As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Keywords for the new dashboard.
Property dashboardKeywords As %ZEN.Datatype.string;

/// Locked state of the currently displayed dashboard.
Property dashboardLocked As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Public state of the currently displayed dashboard.
Property dashboardPublic As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Category for the new dashboard.
Property dashboardCategory As %ZEN.Datatype.string;

/// Name of selected item.
Property selectedItemName As %ZEN.Datatype.string;

/// Current folder category (used for filtering).
Property folderCategory As %ZEN.Datatype.string [ InitialExpression = "all" ];

/// How to display items.
Property folderView As %ZEN.Datatype.string [ InitialExpression = "covers" ];

/// Style applied to coverView background;
Property desktopStyle As %ZEN.Datatype.style;

/// Current namespace.
Property namespace As %ZEN.Datatype.string [ InitialExpression = {$namespace} ];

XData Style
{
<style type="text/css">

#contentsLeft {
	width: 400px;
}

.EmptyMsg {
	padding: 20px;
	font-size: 20px;
	color: #808080;
}

.rowHover {
	background: #FFEEAA;
}

.fcLabel {
	font-size: 11px;
	color: #606060;
}

a.toggleButton {
	text-decoration: none;
	font-size: 20px;
	color: #606060;
}

a.toggleButton:hover {
	color: darkred;
}

a.folderCategory {
	padding-left:2px;
	padding-right:2px;
	text-decoration: none;
	font-size: 13px;
	color: #4b94cc;
	font-weight: normal;
}

a.folderCategorySelected {
	padding-left:2px;
	padding-right:2px;
	text-decoration: none;
	font-size: 13px;
	color: #404040;
	background: #FFEEAA;
	font-weight: normal;
}

a.folderCategory:hover,a.folderCategorySelected:hover {
	color: darkred;
}

a.folderCategory:active,a.folderCategorySelected:active {
	text-shadow: 2px 2px 8px #8080D0, -2px -2px 8px #8080D0;
}

img.toggleFolder {
	opacity: 0.8;
}

img.toggleFolder:hover {
	opacity: 1.0;
}

img.toggleFolder:active {
	background: #D0D0D0;
	border-radius: 4px;
	box-shadow: 2px 2px 8px #D0D0D0, -2px -2px 8px #D0D0D0;
}

</style>
}

/// This XML defines the menu for this page.
XData menuPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<csMenuBar id="mainMenu" width="100px">
<csMenuBarItem caption="Menu">
<contextMenu id="fileMenu">
<csMenuItem id="newDashboard" caption="New Dashboard" title="Create a new dashboard" onclick="zenPage.newDashboard();" />
<csMenuItem id="openDashboard" caption="Find Dashboard..." title="Find a dashboard" onclick="zenPage.openDashboard();"/>
<csMenuItem id="analyzer" caption="Analyzer" title="Go to the Analyzer" onclick="zenPage.gotoAnalyzer();" />
<csMenuSeparator/>
<csMenuItem id="register" caption="Register for Alerts" title="Sign up to receive alerts from other users" onclick="zenPage.registerUser();" />
<csMenuItem id="smp" caption="Management Portal" title="Go to the Management Portal" onclick="zenPage.gotoSMP();" />
</contextMenu>
</csMenuBarItem>
</csMenuBar>
</pane>
}

/// This XML defines the main display area.
XData contentsRightPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" xmlns:deepsee="http://www.intersystems.com/deepsee">

<jsonProvider id="jsonItems" OnGetArray="GetItemArray"/>

<html id="foldersHeader" OnDrawContent="DrawFoldersHeader"/>
<html id="foldersList"/>
<deepsee:coverView id="coversList" defaultCategory="All" ongetdata="return zenPage.getItemList();" onactivate="return zenPage.activateCover(index,action);"
ongetdetails="return zenPage.getCoverDetails(index);" ongetitemcontext="return zenPage.getCoverContext(index);"/>
<html id="foldersFooter" OnDrawContent="DrawFoldersFooter"/>
</pane>
}

/// Draw the contents of the worklist title area.
Method DrawWorklistTitle(pSeed As %String) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		Set tUserName = ##class(%DeepSee.UserPortal.Utils).%GetUserName()
		Write $$$FormatTextHTML($$$Text("Welcome, %1"),tUserName)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw the contents of the Folders Header area.
Method DrawFoldersHeader(pSeed As %String) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
		Set hlpRefresh = $$$Text("Refresh the folder list","%DeepSee")
		Set hlpSearch = $$$Text("Search for items","%DeepSee")
		Set hlpAdd = $$$Text("Add a new item","%DeepSee")
		Set hlpToggle = $$$Text("Hide or show worklists","%DeepSee")

		Set msgSearch = $$$Text("Search","%DeepSee")
		Set msgGo = $$$Text("Go","%DeepSee")
		
		&html<<div class="foldersHeaderDiv">
		<div style="padding-bottom:3px;">
		<a class="toggleButton" id="toggle" onclick="zenPage.toggleLayout();" title="#(hlpToggle)#">&laquo;</a>
		<image class="icon" style="vertical-align:bottom;height:24px;padding:2px;" title="#(hlpRefresh)#" src="deepsee/ds2_refresh_44.png" onclick="zenPage.refreshFolders(true);"/>>
		If (..canWrite) {
			&html<<image class="icon" style="vertical-align:bottom;height:24px;padding:2px;" title="#(hlpAdd)#" src="deepsee/ds2_plus_44.png" onclick="zenPage.addNewItem();"/>>
		}
		// HTML5
		&html<&nbsp;&nbsp;<nobr><input id="searchBox" type="search" title="#(hlpSearch)#" size="20" placeHolder="#(msgSearch)#" onchange="zenPage.doSearch();" onkeypress="zenPage.searchKeyPress(event);"/>>

		// view buttons
		Set tView(1) = $LB("covers",$$$Text("Covers"),$$$Text("Show book covers"))
		Set tView(2) = $LB("list",$$$Text("List"),$$$Text("Show list"))

		If $D(tView) {
			Set tLabel = $$$Text("View")
			&html<&nbsp;&nbsp;<span class="fcLabel">#(tLabel)#:</span>>
			Set k = $O(tView(""))
			While (k'="") {
				Set tOpt = $LG(tView(k),1)
				Set tFClass = $S(tOpt=..folderView:"folderCategorySelected",1:"folderCategory")
				&html<<a class="#(tFClass)#" id="fvopt_#(tOpt)#" href="#" title="#($ZCVT($LG(tView(k),3),"O","HTML"))#" onclick="return zenPage.setFolderView(event,'#(tOpt)#');">#($ZCVT($LG(tView(k),2),"O","HTML"))#</a>>
				Set k = $O(tView(k))
			}
		}


		// folder category buttons
		Set tCat(1) = $LB("favorites",$$$Text("Favorites"),$$$Text("Show my favorite items"))
		Set tCat(2) = $LB("all",$$$Text("All"),$$$Text("Show all items"))
		Set tCat(3) = $LB("personal",$$$Text("Personal"),$$$Text("Show my items"))
		Set tCat(4) = $LB("shared",$$$Text("Shared"),$$$Text("Show shared items"))
		Set tCat(5) = $LB("public",$$$Text("Public"),$$$Text("Show public items"))

		If $D(tCat) {
			Set tLabel = $$$Text("Show")
			&html<&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="fcLabel">#(tLabel)#:</span>>
			Set k = $O(tCat(""))
			While (k'="") {
				Set tOpt = $LG(tCat(k),1)
				Set tFClass = $S(tOpt=..folderCategory:"folderCategorySelected",1:"folderCategory")
				&html<<a class="#(tFClass)#" id="fopt_#(tOpt)#" href="#" title="#($ZCVT($LG(tCat(k),3),"O","HTML"))#" onclick="return zenPage.setFolderCategory(event,'#(tOpt)#');">#($ZCVT($LG(tCat(k),2),"O","HTML"))#</a>>
				Set k = $O(tCat(k))
			}
		}

		&html<</div>
		</div>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw the contents of the Folders Footer area.
Method DrawFoldersFooter(pSeed As %String) As %Status [ Final ]
{
	Set tSC = $$$OK
	Try {
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw the contents of the Folders area.
ClientMethod renderFoldersList() [ Language = javascript ]
{
	var list = this.getItemList();

	var html = [];
	var folderIconUp = "portal/disc_up_24.gif";
	var folderIconDown = "portal/disc_down_24.gif";
	var favIcon = "deepsee/ds2_star_44.png";
	var delIcon = "deepsee/ds2_x_44.png";
	var hlpFav = $$$Text("Add this item to the favorites list","%DeepSee");
	var hlpDel = $$$Text("Delete this item","%DeepSee");

	var itemCount = 0;

	if (list && list.length > 0) {
		var msgName = $$$Text("Name","%DeepSee");
		var msgType = $$$Text("Type","%DeepSee");
		var msgKeyword = $$$Text("Keywords","%DeepSee");

		html[html.length] = '<div id="folderList">';
		html[html.length] = '<table class="listTable" width="100%" cellspacing="0" border="0" cellpadding="0">';
		html[html.length] = '<tr class="listHeader">';
		html[html.length] = '<th>&nbsp;</th>';
		html[html.length] = '<th>&nbsp;</th>';
		html[html.length] = '<th width="50%">'+(msgName)+'</th>';
		html[html.length] = '<th>'+(msgType)+'</th>';
		html[html.length] = '<th width="25%">'+(msgKeyword)+'</th>';
		html[html.length] = '<th>&nbsp;</th>';
		html[html.length] = '</tr>';

		var currFolder = '';
		var r = 0;
		for (var n = 0; n < list.length; n++) {
			var item = list[n];

			// split name into folders
			var f = item.name.toString().split('/');
			var df = item.displayFolder.toString().split('/');
			var shortName = f[f.length-1];
			shortName = shortName.split('.')[0];
			f.splice(f.length-1,1);
			var indent = f.length;
			var folder = indent>0 ? f.join('/') : '';
			var dfolder = indent>0 ? df.join('/') : '';

			if (folder != '') {
				// folder
				var name = item.Name;
				for (var p = 0; p < indent; p++) {
					var test = currFolder.toString().split('/');
					var f2 = folder.toString().split('/');
					test.length = p+1;
					f2.length = p+1;

					var df2 = dfolder.toString().split('/');
					df2.length = p+1;

					if (test.join('/')!=f2.join('/')) {
						var URL = "";
						r++;
						var folderIndent = p;
						var folderName = f2[p];
						var dfolderName = df2[p];
						var tip = dfolderName;
						var cls = (r%2)?"listRowOdd":"listRowEven";
						
						// DTB777 - Escape potential problem strings in the HTML using zenEscapeXML
						html[html.length] = '<tr id="frow_'+r+'" class="'+cls+'" style="font-weight:bold;color:#404040;" title="'+zenEscapeXML(tip)+'" folderName="'+zenEscapeXML(f2.join('/'))+'" expanded="1"';		// DTB675 - Rebuild the current logical folder name from the truncated array
						if (zenPage.cssLevel<3) {
							html[html.length] = ' onmouseover="this.className=\'rowHover\';" onmouseout="this.className=\''+cls+'\';"';
						}
						html[html.length] = '>';
						html[html.length] = '<td>&nbsp;</td>' + 
							'<td>'+
							'<image src="images/spacer.gif" style="width:'+(folderIndent*24)+'px;height:24px;"/>'+
							'<image class="toggleFolder" id="icon_'+r+'" src="'+folderIconDown+'" style="width:24px;height:24px;" alt="+" onclick="zenPage.toggleFolder('+r+');"/>'+
							'</td>';
						html[html.length] = '<td>'+zenEscapeXML(dfolderName)+'</td>'+
							'<td>'+$$$Text("Folder","%DeepSee")+'</td>'+
							'<td>&nbsp;</td>'+
							'<td>&nbsp;</td>'+
							'</tr>';
					}
				}
			}
			else {
				indent = 0;
			}
			currFolder = folder;

			var name = item.name;
			var type = item.type;
			var tip = item.tooltip;
			var URL = item.url;
			var icon = item.icon;
			var keywords = item.keywords;
			var title = item.title;
			shortName = title=='' ? shortName : title;
			r++;
			keywords = (keywords=='') ? "&nbsp;" : keywords;
			var cls = (r%2)?"listRowOdd":"listRowEven";
			
			// DTB777 - Escape potential problem strings in the HTML using zenEscapeXML
			html[html.length] = '<tr id="frow_'+r+'" class="'+cls+'" title="'+zenEscapeXML(tip)+'" folderName="'+zenEscapeXML(name)+'" onclick="zenPage.selectItem(\''+zenEscapeXML(name)+'\');"';
			if (zenPage.cssLevel<3) {
				html[html.length] = ' onmouseover="this.className=\'rowHover\';" onmouseout="this.className=\''+cls+'\';"';
			}
			html[html.length] = '>';
			html[html.length] = '<td>&nbsp;</td>';
			html[html.length] = '<td nowrap="1">';
			html[html.length] = '<image src="images/spacer.gif" style="width:'+(indent*24)+'px;height:24px;"/>';
			if (icon!="") {
				html[html.length] = '<image style=width:20px;height:20px;" src="'+icon+'" alt="'+type+'"/>';
			}
			html[html.length] = '</td>';
			html[html.length] = '<td><a href="'+URL+'">'+zenEscapeXML(shortName)+'</a></td>' + 
				'<td class="workListType">'+type+'</td>'+
				'<td class="workListKeyWord">'+zenEscapeHTMLSafe(keywords)+'</td>'+
				'<td nowrap="1" style="vertical-align:bottom;">';
			
			if (item.active) {
				html[html.length] = '<image style="width:18px;height:18px;opacity:0.8;" src="'+favIcon+'" alt="Favorite" title="'+hlpFav+'" onclick="zenPage.addToFavorites(\''+zenEscapeXML(zenEscapeJS(name))+'\');"/>'+'&nbsp;';
				if (this.canWrite && item.write) {
					html[html.length] =	'<image style="width:12px;height:12px;padding-bottom:2px;opacity:0.8;" src="'+delIcon+'" alt="Delete" title="'+hlpDel+'" onclick="zenPage.deleteItem(\''+zenEscapeXML(zenEscapeJS(name))+'\');"/>';
				}
			}
				
			html[html.length] = '&nbsp;'+
				'</td>'+
				'</tr>';

			// don't count workflow item!
			itemCount++;
		}
		html[html.length] = '</table></div>';
	}
	
	if (itemCount == 0) {
		// !!! show message in covers mode !!!
		if (this.searchKey=='') {
			html[html.length] = '<div class="EmptyMsg">' + $$$Text("Your folders are currently empty.","%DeepSee") + '</div>';
			html[html.length] = '<div class="EmptyMsg">' + $$$Text("You can create new items using the menu.","%DeepSee") + '</div>';
		}
		else {
			html[html.length] = '<div class="EmptyMsg">' + $$$Text("No items match the search criteria.","%DeepSee") + '</div>';
		}
	}

	zen('foldersList').setContent(html.join(''));
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK

	Try {
		// check privileges
		Do CheckPortalUseAccess^%qdsUtils()

		Set tSC = ##super()
		If $$$ISERR(tSC) Quit

		// make sure soft modals are on
		Set ..useSoftModals = 1

		// override title
		Set ..title = $ZCVT($G(^DeepSee.UserPortalSettings("PageTitle"),$$$PRODUCT1),"O","HTML")

		// Remove smp links if not a developer
		If '$System.Security.Check("%Development","U") {
			Set tMenu = ..%GetComponentById("smp")
			If $IsObject(tMenu) {
				Do tMenu.parent.%RemoveChild(tMenu)
			}
		}

		If ('$$CheckAnalyzerViewAccess^%qdsUtils()) {
			Set tMenu = ..%GetComponentById("analyzer")
			If $IsObject(tMenu) {
				Do tMenu.parent.%RemoveChild(tMenu)
			}
		}

		// JMD1391 test for NOMODIFY flag
		If ((+..noModify)) {
			Set ..canWrite = 0
		}

		// Remove new dashboard option if user cannot write
		If ('..canWrite) {
			Set tMenu = ..%GetComponentById("newDashboard")
			If $IsObject(tMenu) {
				Do tMenu.parent.%RemoveChild(tMenu)
			}

			// no navigator for readonly
			Set tNavigator = ..%GetComponentById("navigator")
			If $IsObject(tNavigator) {
				Set tNavigator.hidden = 1
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("DeepSee Portal")
}

/// Get the (localized) name of the page.
/// This should be implemented in a subclass.
Method %OnGetPageName() As %String
{
	Quit $$$Text("UserPortal Home")
}

/// Refresh the folder list.
ClientMethod refreshFolders(reload) [ Language = javascript ]
{
	reload = zenGet(reload,false);
	if (reload) {
		zen('jsonItems').reloadContents();
	}

	var folders = zen('foldersList');
	// reset scrolling
	folders.getEnclosingDiv().scrollTop = 0;

	this.renderFoldersList();
	zen('coversList').render();
}

/// Activate the search text box;
ClientMethod activateSearchBox() [ Language = javascript ]
{
	var ctrl = self.document.getElementById('searchBox');
	if (ctrl && ctrl.style.color=='silver') {
		ctrl.style.color = '';
		ctrl.value = '';
	}
}

/// Key press in search box.
ClientMethod searchKeyPress(evt) [ Language = javascript ]
{
	//workaround for IE
	evt = evt ? evt : event;
	if (evt.keyCode == zenENTER) {
		zenPage.doSearch();
	}
}

/// Perform a search.
ClientMethod doSearch() [ Language = javascript ]
{
	var ctrl = self.document.getElementById('searchBox');
	this.searchKey = ctrl.value;
	this.refreshFolders();
}

/// Hide/show folders in list.
ClientMethod toggleFolder(index) [ Language = javascript ]
{
	var folder = self.document.getElementById('frow_'+index);
	var folderName = folder.getAttribute('folderName');
	var expanded = !(parseInt(folder.getAttribute('expanded')) == 1);
	var icon = self.document.getElementById('icon_'+index);
	icon.src = !expanded ? 'portal/disc_up_24.gif' : 'portal/disc_down_24.gif';
	folder.setAttribute('expanded',expanded ? 1 : 0);
	
	// visit each row in the table
	var row = 0;
	while(true) {
		row++;
		var tr = self.document.getElementById('frow_'+row);
		if (!tr) break;
		
		var name = tr.getAttribute('folderName');
		if (name) {
			if ((name.substr(0,folderName.length+1) == folderName+'/') && (name!=folderName)) {
				tr.style.display = expanded ? '' : 'none';
			}
		}
	}

	// now re-apply stripes
	var n = 0;
	var row = 0;
	while(true) {
		row++;
		var tr = self.document.getElementById('frow_'+row);
		if (!tr) break;
		
		if (tr.style.display == '') {
			n++;
			tr.className = (n%2) ? 'listRowOdd' : 'listRowEven';
		}
	}
}

/// Adjust sizes of content area.
ClientMethod onAdjustSizes(load, contentWidth, contentHeight) [ Language = javascript ]
{
	try {
		// folders
		var fHeader = zen('foldersHeader');
		var fList = zen('foldersList');
		var fCovers = zen('coversList');

		var fFooter = zen('foldersFooter');
		if (fHeader && fList && fFooter) {
			var fHeaderDiv = fHeader.getEnclosingDiv();
			var fListDiv = fList.getEnclosingDiv();
			var fFooterDiv = fFooter.getEnclosingDiv();

			var fCoversDiv = fCovers ? fCovers.getEnclosingDiv() : null;

			var flh = contentHeight - fHeaderDiv.offsetHeight - fFooterDiv.offsetHeight;
			if (flh < 0) {
				fListDiv.style.display = 'none';
				if (fCoversDiv) {
					fCoversDiv.style.display = 'none';
				}
			}
			else {
				fHeaderDiv.style.width = contentWidth + 'px';

				if (this.folderView == 'covers') {
					fListDiv.style.display = 'none';
					fCoversDiv.style.display = 'block';
					fCoversDiv.style.height = flh + 'px';
					fCoversDiv.style.width = contentWidth-2 + 'px';
				}
				else {
					fCoversDiv.style.display = 'none';
					fListDiv.style.display = 'block';
					fListDiv.style.height = flh + 'px';
					fListDiv.style.width = contentWidth + 'px';
				}
			}
		}
		
		if (load) {
			// restore state from cookies
			var fv = zenLoadCookie(zenPage,'folderView');
			if (fv!='' && fv!=this.folderView) {
				this.setFolderView(null,fv);
			}
			var fc = zenLoadCookie(zenPage,'folderCategory');
			if (fc!='' && fc!=this.folderCategory) {
				this.setFolderCategory(null,fc);
			}

			var hideLists = zenLoadCookie(zenPage,'hideWorklists');
			if (hideLists=='1') {
				this.toggleWorklists();
			}

			this.renderFoldersList();

			var fc = zenLoadCookie(zenPage,'desktopStyle');
			if (fc!='' && fc!=this.desktopStyle) {
				this.desktopStyle = fc;
				zen('coversList').setProperty('backgroundStyle',this.desktopStyle);
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onAdjustSizes');
	}
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'DashboardSave':
		var msg = this.SaveDashboardToFolder();
		if (msg!="") {
			alert(msg);
		}
		else {
			// show the new dashboard
			var url = this.viewerURL;
			url = url + ((url.indexOf('?')!=-1) ? '&' : '?') + 'DASHBOARD=' + encodeURIComponent(this.dashboardName);
			zenPage.gotoPage(url);
		}
		break;
	case 'DashboardEdit':
		var msg = this.SaveDashboardToFolder();
		if (msg!="") {
			alert(msg);
		}
		this.refreshFolders(true);
		break;
	case 'DashboardOpen':
		var url = this.viewerURL;
		url = url + ((url.indexOf('?')!=-1) ? '&' : '?') + 'DASHBOARD=' + encodeURIComponent(value);
		zenPage.gotoPage(url);
		break;
	case 'ReportEdit':
	case 'ReportSave':
	case 'LinkEdit':
	case 'LinkSave':
	case 'PivotEdit':
		this.refreshFolders(true);
		break;
	case 'Register':
		zenPage.updateWorklistTitle();
		break;
	case 'CoverEdit':
		var msg = this.SaveBookCover(this._currItemName,value);
		if (msg!='') {
			alert(msg);
		}
		this.refreshFolders(true);
		break;
	}
}

/// Create a new dashboard.
ClientMethod newDashboard() [ Language = javascript ]
{
	// show save dialog
	var parms = {
			NEW:1,
			DASHBOARD:'',
			TITLE:'',
			WORDS:'',
			DESC:''
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.DashboardSave.zen','DashboardSave','status,scrollbars,resizable=yes,width=700,height=800',parms);
}

/// Edit a dashboard.
ClientMethod editDashboard(info) [ Language = javascript ]
{
	// show save dialog
	var parms = {
			// we need to add *all* attribute OR have a "small" mode for the dialog
			// until then, this is not used.
			NEW:0,
			DASHBOARD:zenGet(info.name),
			TITLE:zenGet(info.title),
			WORDS:zenGet(info.keywords),
			DESC:zenGet(info.description)
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.DashboardSave.zen','DashboardEdit','status,scrollbars,resizable=yes,width=700,height=800',parms);
}

/// Create a new link.
ClientMethod newLink() [ Language = javascript ]
{
	// show save dialog
	var parms = {
			NEW:1,
			NAME:'',
			TITLE:'',
			WORDS:'',
			DESC:''
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.LinkSave.zen','LinkSave','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Edit a link.
ClientMethod editLink(info) [ Language = javascript ]
{
	// show save dialog
	var parms = {
			NEW:0,
			NAME:zenGet(info.name),
			URL:zenGet(info.href),
			TITLE:zenGet(info.title),
			WORDS:zenGet(info.keywords),
			CATEGORY:zenGet(info.category),
			DESC:zenGet(info.description)
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.LinkSave.zen','LinkEdit','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Edit a pivot.
ClientMethod editPivot(info) [ Language = javascript ]
{
	// show save dialog
	var parms = {
			NEW:0,
			PIVOT:zenGet(info.name),
			TITLE:zenGet(info.title),
			WORDS:zenGet(info.keywords),
			CATEGORY:zenGet(info.category),
			DESC:zenGet(info.description)
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotSave.zen','PivotEdit','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Create a new report shortcut.
ClientMethod newReport() [ Language = javascript ]
{
	// show save dialog
	var parms = {
			NEW:1,
			NAME:'',
			TITLE:'',
			WORDS:'',
			DESC:''
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.ReportSave.zen','ReportSave','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Edit a report shortcut.
ClientMethod editReport(info) [ Language = javascript ]
{
	// show save dialog
	var parms = {
			NEW:0,
			NAME:zenGet(info.name),
			REPORT:zenGet(info.reportClass),
			TITLE:zenGet(info.title),
			WORDS:zenGet(info.keywords),
			CATEGORY:zenGet(info.category),
			DESC:zenGet(info.description)
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.ReportSave.zen','ReportEdit','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Save the bookcover for the given dashboard.
Method SaveBookCover(pName As %String, pSpec As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		// JMD1345 special case for workflow cover
		If (pName = "$workflow") {
			Set ^DeepSee.UserPortalSettings("WorkflowBookCover") = pSpec
			Quit
		}
		
		// test for overwrite
		Set tItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pName,.tSC)
		If $$$ISERR(tSC) Quit

		Set tItem.bookCover = pSpec
		Set tSC = tItem.%Save()
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

/// Save the new dashboard.
Method SaveDashboardToFolder() As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		// test for overwrite
		If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(..dashboardName)) {
			Set tMsg = ..SendItemToTrash(..dashboardName)
			If (tMsg'="") Quit
		}

		// create and save dashboard
		Set tDashboard = ##class(%DeepSee.Dashboard.Definition).%New()
		Set tDashboard.fullName = ..dashboardName
		Set tDashboard.title = ..dashboardTitle
		Set tDashboard.keywords = ..dashboardKeywords
		Set tDashboard.description = ..dashboardDescription
		Set tDashboard.public = ..dashboardPublic
		Set tDashboard.locked = ..dashboardLocked
		Set tDashboard.worklistCount = ..worklistCount
		Set tDashboard.owner = ..dashboardOwner
		Set tDashboard.resource = ..dashboardResource
		Set tDashboard.category = ..dashboardCategory

		// JMD1053
		Set tDashboard.snapTo = ..dashboardSnapTo
		Set tDashboard.snapGrid = ..dashboardSnapGrid

		Set tDashboard.canModify = ..dashboardModify
		Set tDashboard.canResize = ..dashboardResize
		Set tDashboard.gridRows = ..dashboardGridRows
		Set tDashboard.gridCols = ..dashboardGridCols

		Set tSC = tDashboard.%Save()
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

/// Delete the given item.
ClientMethod deleteItem(name) [ Language = javascript ]
{
	if (confirm($$$Text('Do you want to delete this item?') + '\n'+name,false)) {
		var msg = zenPage.SendItemToTrash(name);
		if ('' != msg) {
			alert(msg);
		}
		if (this.selectedItemName==name) {
			this.selectedItemName = '';
		}
		this.refreshFolders(true);
	}
}

/// Select the given item.
ClientMethod selectItem(name) [ Language = javascript ]
{
	this.selectedItemName = name;

	// update details panel
	var details1 = self.document.getElementById('details1');
	var details2 = self.document.getElementById('details2');
	if (details1 || details2) {
		var html = this.getDetailsHTML();
		if (details1) {
			details1.innerHTML = html;
		}
		if (details2) {
			details2.innerHTML = html;
		}
	}
}

/// Show the analyzer page.
ClientMethod gotoAnalyzer() [ Language = javascript ]
{
	zenPage.gotoPage('_DeepSee.UserPortal.Analyzer.zen');
}

/// Show the System Management portal.
ClientMethod gotoSMP() [ Language = javascript ]
{
	zenPage.gotoPage('/csp/sys/_CSP.Portal.Home.zen' + (this.namespace != '' ? ('?$NAMESPACE=' + this.namespace) : ''));
}

/// Show the register user dialog.
ClientMethod registerUser() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.RegisterUser.zen','Register','status,scrollbars,resizable=yes,width=700,height=600');
}

/// Update the title for the dashboard.
ClientMethod updateWorklistTitle() [ Language = javascript ]
{
	var html = zen('worklistTitle');
	html.refreshContents();
}

/// Return list of options for work list 1.
Method %OnGetWorklistOptions1(Output pOptions, Output pDefaultMode) As %Status
{
	Set pDefaultMode = ""
	If +$G(^DeepSee.UserPortalSettings("Worklist")) {
		Set n = $O(^DeepSee.UserPortalSettings("Worklist","Home",1,""))
		While (n'="") {
			// $LB(name,class)
			Set pOptions($I(k)) = $LB("option"_n,^DeepSee.UserPortalSettings("Worklist","Home",1,n))
			Set:pDefaultMode="" pDefaultMode = "option"_n
			Set n = $O(^DeepSee.UserPortalSettings("Worklist","Home",1,n))
		}	
	}
	Else {
		Quit ##super(.pOptions,.pDefaultMode)
	}
	Quit $$$OK
}

/// Return list of options for work list 2.
Method %OnGetWorklistOptions2(Output pOptions, Output pDefaultMode) As %Status
{
	Set pDefaultMode = ""
	If +$G(^DeepSee.UserPortalSettings("Worklist")) {
		Set n = $O(^DeepSee.UserPortalSettings("Worklist","Home",2,""))
		While (n'="") {
			// $LB(name,class)
			Set pOptions($I(k)) = $LB("option"_n,^DeepSee.UserPortalSettings("Worklist","Home",2,n))
			Set:pDefaultMode="" pDefaultMode = "option"_n
			Set n = $O(^DeepSee.UserPortalSettings("Worklist","Home",2,n))
		}	
	}
	Else {
		Quit ##super(.pOptions,.pDefaultMode)
	}
	Quit $$$OK
}

/// Get contents for the item details box.
ClientMethod getDetailsHTML() [ Language = javascript ]
{
	var html = [];
	try {
		if (this.selectedItemName.length == '') {
			html[html.length] = '<div class="detailLabel">' + $$$Text('Details on selected item') + '</div>';
		}
		else {
			var name = this.selectedItemName;

			var info = this.GetItemDetails(name);
			if (info) {
				if (info.type && '' !== info.type) {
					html[html.length] = '<div class="detailLabel">' + $$$Text('Type') + '</div>';
					html[html.length] = '<div class="detailValue">' + zenEscapeXML(info.type) + '</div>';
				}

				if (info.folderName && '' !== info.folderName) {
					html[html.length] = '<div class="detailLabel">' + $$$Text('Folder') + '</div>';
					html[html.length] = '<div class="detailValue">' + zenEscapeXML(info.folderName) + '</div>';
				}

				if (info.title && '' !== info.title) {
					html[html.length] = '<div class="detailLabel">' + $$$Text('Name') + '</div>';
					html[html.length] = '<div class="detailValue">' + zenEscapeXML(info.title) + '</div>';
				}

				if (info.owner && '' !== info.owner) {
					html[html.length] = '<div class="detailLabel">' + $$$Text('Owner') + '</div>';
					html[html.length] = '<div class="detailValue">' + zenEscapeXML(info.owner) + '</div>';
				}

				if (info.description && '' !== info.description) {
					html[html.length] = '<div class="detailLabel">' + $$$Text('Description') + '</div>';
					html[html.length] = '<div class="detailValue">' + zenEscapeXML(info.description) + '</div>';
				}

				if (info.timeCreated && '' !== info.timeCreated) {
					html[html.length] = '<div class="detailLabel">' + $$$Text('Created on') + '</div>';
					html[html.length] = '<div class="detailValue">' + zenEscapeXML(info.timeCreated) + '</div>';
				}

				if (info.timeModified && '' !== info.timeModified) {
					html[html.length] = '<div class="detailLabel">' + $$$Text('Last modified') + '</div>';
					html[html.length] = '<div class="detailValue">' + zenEscapeXML(info.timeModified) + '</div>';
				}
			}
		}

	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in updateDetails');
	}

	return html.join('');
}

/// Get details on selected item.
ClassMethod GetItemDetails(pName As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tInfo = ""
	Set tItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pName)
	If $IsObject(tItem) {
		Set tInfo = ##class(%ZEN.proxyObject).%New()
		Set tInfo.title = $S(tItem.title="":tItem.name,1:tItem.title)
		Set tInfo.folderName = tItem.folderName
		Set tInfo.owner = tItem.owner
		If (tInfo.owner'="") {
			Set tInfo.owner = ##class(%DeepSee.UserPortal.Utils).%GetUserName(tInfo.owner)
		}
		Set tInfo.description = tItem.description
		Set tInfo.resource = tItem.resource
		Set tInfo.type = tItem.%GetTypeName()
		Set tInfo.keywords = tItem.keywords
		Set tInfo.category = tItem.category
		Set tInfo.write = tItem.%CheckResource("WRITE")

		Set tInfo.timeCreated = ##class(%DeepSee.UserPortal.Utils).%FormatDate(tItem.timeCreated)
		Set tInfo.timeModified = ##class(%DeepSee.UserPortal.Utils).%FormatDate(tItem.timeModified)

		If (tItem.%IsA("%DeepSee.UserLibrary.Link")) {
			Set tInfo.href = tItem.href
		}
		If (tItem.%IsA("%DeepSee.UserLibrary.Report")) {
			Set tInfo.reportClass = tItem.reportClass
		}
	}

	Quit tInfo
}

/// Change the folder category
ClientMethod setFolderCategory(evt, cat) [ Language = javascript ]
{
	//evt = evt ? evt : zenGet(event);
	if (evt && evt.preventDefault) {
		evt.preventDefault();
	}

	if (this.folderCategory!=cat) {
		var el = self.document.getElementById('fopt_'+ this.folderCategory);
		if (el) {
			el.className = 'folderCategory';
		}
		this.folderCategory = cat;
		var el = self.document.getElementById('fopt_'+ this.folderCategory);
		if (el) {
			el.className = 'folderCategorySelected';
		}

		var catName = '';
		switch(cat) {
		case 'all':
			catName = $$$Text('All');
			break;
		case 'favorites':
			catName = $$$Text('Favorites');
			break;
		case 'personal':
			catName = $$$Text('Personal');
			break;
		case 'shared':
			catName = $$$Text('Shared');
			break;
		case 'public':
			catName = $$$Text('Public');
			break;
		}

		zen('coversList').defaultCategory = catName;
		this.refreshFolders(true);

		// remember in cookie
		this.storeCookie('folderCategory',cat);
	}
	return false;
}

/// Change the folder view.
ClientMethod setFolderView(evt, view) [ Language = javascript ]
{
	//evt = evt ? evt : zenGet(event);
	if (evt && evt.preventDefault) {
		evt.preventDefault();
	}

	if (this.folderView!=view) {
		var el = self.document.getElementById('fvopt_'+ this.folderView);
		if (el) {
			el.className = 'folderCategory';
		}
		this.folderView = view;
		var el = self.document.getElementById('fvopt_'+ this.folderView);
		if (el) {
			el.className = 'folderCategorySelected';
		}
		this.adjustSizes(false);

		// remember in cookie
		this.storeCookie('folderView',view);
	}
	return false;
}

/// Toggle display of worklist area.
ClientMethod toggleLayout() [ Language = javascript ]
{
	var el = self.document.getElementById('toggle');
	if (el) {
		var hidden = '';
		if ('undefined' != typeof this._oldworklistCount) {
			el.innerHTML = '&laquo;';
			hidden = 0;
		}
		else {
			el.innerHTML = '&raquo;';
			hidden = 1;
		}
		// remember in cookie
		this.storeCookie('hideWorklists',hidden);
	}
	this.toggleWorklists();
}

/// Get popup details for a book cover.
ClientMethod getCoverDetails(index) [ Language = javascript ]
{
	var details = [];
	var data = this.getItemList();
	var info = null;

	if (data && data[index]) {
		if (data[index].name=='$workflow') {
			info = {write:0, description:$$$Text('View the Workflow Inbox','%DeepSee')};
			this.selectItem('');
		}
		else {
			info = this.GetItemDetails(data[index].name);
			// JMD1221: make sure details pane is up to date
			this.selectItem(data[index].name);
		}

		if (info) {
			
			details[details.length] = {key:'title', caption:$$$Text('Name'), value:info.title};
			if (info.type) {
				details[details.length] = {key:'type', caption:$$$Text('Type'), value:info.type};
			}
			details[details.length] = {key:'description', caption:$$$Text('Description'), value:info.description?info.description:'None'};

			if (info.keywords) {
				details[details.length] = {key:'keywords', caption:$$$Text('Keywords'), value:info.keywords};
			}

			if (info.timeCreated) {
				details[details.length] = {key:'created', caption:$$$Text('Created'), value:info.timeCreated};
			}

			if (info.owner) {
				details[details.length] = {key:'owner', caption:$$$Text('Owner'), value:info.owner};
			}
		}
	}

	// icons
	if (data[index].name=='$workflow') {
		// workflow
		details[details.length] = {key:'$configure',value:false};
		details[details.length] = {key:'$addFavorite',value:false};
		details[details.length] = {key:'$remove',value:false};
	}
	else if (!this.canWrite || (info && info.write==0)) {
		details[details.length] = {key:'$configure',value:false};
		details[details.length] = {key:'$designCover',value:false};
		details[details.length] = {key:'$remove',value:false};
	}
	
	return details;
}

/// Get $var context for a book cover.
ClientMethod getCoverContext(index) [ Language = javascript ]
{
	var context = {};
	var data = this.getItemList();
	if (data && data[index]) {
		var info = data[index];
		if (info) {
			context.$title = info.title?info.title:' ';
			context.$category = info.category?info.category:' ';
			context.$type = info.type?info.type : ' ';
			context.$owner = info.owner?info.owner : ' ';
		}
	}
	return context;
}

/// User action on a book cover.
ClientMethod activateCover(index, action) [ Language = javascript ]
{
	var data = this.getItemList();

	switch(action) {
	case 'navigate':
		var url = zen('coversList').getCoverObject(index).url;
		self.document.location = url;
		break;
	case 'addFavorite':
		if (data && data[index] && data[index].name) {
			zenPage.addToFavorites(data[index].name);
		}
		break;
	case 'configure':
		if (data && data[index] && data[index].type) {

			var info = this.GetItemDetails(data[index].name);
			info.name = data[index].name;

			// type is localized!
			switch (data[index].type) {
			case $$$Text('Dashboard'):
				var url = zen('coversList').getCoverObject(index).url;
				self.document.location = url;
				//this.editDashboard(info);
				break;
			case $$$Text('Pivot'):
				var url = zen('coversList').getCoverObject(index).url;
				self.document.location = url;
				// this.editPivot(info);
				break;
			case $$$Text('Report'):
				this.editReport(info);
				break;
			case $$$Text('Link'):
				this.editLink(info);
				break;
			}
		}
		break;
	case 'remove':
		if (data && data[index] && data[index].name) {
			zenPage.deleteItem(data[index].name);
		}
		break;
	case 'designCover':
		var cover = zen('coversList').getCoverObject(index);
		if (data && data[index] && data[index].spec) {
			this.designBookCover(data[index].name,data[index].spec);
		}
		break;
	}
}

/// Get the JSON item list.
/// Apply search filtering.
ClientMethod getItemList() [ Language = javascript ]
{
	var data = null;
	var model = zen('jsonItems').getContentObject();
	if (model && model.children) {
		data = model.children;
	
		if (data && this.searchKey) {
			var search = this.searchKey.toString().toUpperCase();
			var list = [];
			for (var n = 0; n < data.length; n++) {
				var item = data[n];

				// apply search key, if present
				var skip = false;
				if (search!="") {
					if (item.title.toString().toUpperCase().indexOf(search)<0 && item.keywords.toString().toUpperCase().indexOf(search)<0) {
						skip = true;
					}
					if (skip) {
						// take a look at the book cover
						if (item.spec.toString().toUpperCase().indexOf(search)>=0) {
							// could be a match; look inside
							var specObj = zen('coversList').evalSpec(item.spec);
							if (specObj) {
								var test = ['title','header','footer','subtitle'];
								for (var t = 0; t < test.length; t++) {
									if (specObj[test[t]] && specObj[test[t]].text && specObj[test[t]].text.toString().toUpperCase().indexOf(search)>=0) {
										skip = false;
										break;
									}
								}
							}
						}
					}
				}
				if (!skip) {
					list[list.length] = data[n];
				}
			}
			data = list;
		}
	}
	return data;
}

/// Get list of items for JSON provider.
Method GetItemArray(ByRef pParameters, Output pMetaData, Output pData) As %Status
{
	Set tSC = $$$OK
	Try {
		// JMD1344
		Set pMetaData = $LB("category","name","displayFolder","title","spec","tooltip","url","type","keywords","icon","active","owner","write")

		// n.b. search is done on the client
		If (..folderCategory="favorites") {
			Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetFavoritesForUser(.tFavorites)
			If $$$ISERR(tSC) Quit

			// convert favorites into items list
			Set n = 0
			Set k = $O(tFavorites(""))
			While (k'="") {
				Set tName = $LG(tFavorites(k),1)
				Set tItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tName)
				If $IsObject(tItem) {
					// get localized short name
					Set tTitle = $LG(tFavorites(k),2)
					Set tList($I(n)) = $LB(tItem.fullName,tItem.%GetTypeName(),"",tItem.timeModified,tItem.%GetURL(),tItem.%GetIcon(),tItem.keywords,tItem.public,tTitle,tItem.createdBy,tItem.%GetResource(),tItem.%GetCoverSpec(),tItem.category,,tItem.%CheckResource("WRITE"))
				}
				Set k = $O(tFavorites(k))
			}
		}
		Else {
			Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetFolderItemsForUser(.tList,..folderName)
			If $$$ISERR(tSC) Quit
		}

		// check if we need to show WorkFlow inbox link
		Set tHasWorkflow = 0
		Set tWorkflowItems = 0
		Try {
			If (($System.Version.GetMajor() > 2010) && (..folderCategory'="favorites")) {
				If (##class(%Library.EnsembleMgr).IsEnsembleNamespace()) {
					// check if user is registered for workflow
					If ($ClassMethod("EnsLib.Workflow.UserDefinition","%ExistsId",$UserName)) {
						Set tHasWorkflow = 1
						Set tWorkflowItems = ##class(EnsLib.Workflow.Engine).CountTasksForCurrentUser()
					}
				}
			}
		}
		Catch(ex) {
			Set tHasWorkflow = 0
		}
		
		Set n = 0

		// add workflow item to list
		If (tHasWorkflow) {
			Set tTip = $$$TextHTML("View the Workflow Inbox")
			Set tURL = "_DeepSee.UserPortal.Workflow.zen"
			Set tShortName = $$$TextHTML("Workflow Inbox")
			Set tTasks = $$$FormatText($$$TextHTML("%1 item(s)"),tWorkflowItems)
			Set tName = tShortName _ " - " _ tTasks

			Set tType = $$$Text("Workflow")
			Set tBackground = $S(tWorkflowItems:"#F0F0FF",1:"#F0F0F0")
			Set tIcon = "deepsee/ds2_group_44.png"
			// JMD1345: get saved cover, if present
			Set tSpec = $G(^DeepSee.UserPortalSettings("WorkflowBookCover"))
			Set:tSpec="" tSpec = "{background: {style:'background:"_tBackground_";'},header: {text:'"_tType_"'},title: {text:'"_tShortName_"',style:'font-size:20px;'},footer: {text:'"_tTasks_"'},image: {src:'"_tIcon_"',imageStyle:'width:64px;height:64px;'}}"
			Set pData($I(n)) = $LB("","$workflow",tName,tName,tSpec,tName,tURL,tType,"","",1)
		}

		If $D(tList) {
			// build list to display
			Set tCurrFolder = -1E14
			Set k = $O(tList(""))
			While (k'="") {
				Set tName = $LG(tList(k),1)
				Set tType = $LG(tList(k),2)
				Set tIcon = $LG(tList(k),6)
				Set tTitle = $LG(tList(k),9)
				Set tKeywords = $LG(tList(k),7)
				Set tOwner = $LG(tList(k),14)
				Set tResource = $LG(tList(k),11)
				Set tURL = $LG(tList(k),5)

				// use title as display, if present
				If (tTitle = "") {
					Set tSortKey = $$$UPPER(tName)
				}
				Else {
					Set tFolder = $P(tName,"/",1,$L(tName,"/")-1)
					Set tSortKey = $$$UPPER(tFolder_$S(tFolder="":"",1:"/")_tTitle)
				}
				Set tSortKey = tSortKey_"."_$$$UPPER(tType)

				// apply category, if present
				Set tSkip = 0
				If ((..folderCategory'="all")&&(..folderCategory'="favorites")) {
					Set tShow = 0
					If (..folderCategory="personal") {
						// items where owner = current user
						If (tOwner=$UserName) {
							Set tShow = 1
						}
					}
					ElseIf (..folderCategory="shared") {
						// items where owner '= current user AND there is a resource
						If ((tOwner'=$UserName)&&(tResource'="")) {
							Set tShow = 1
						}
					}
					ElseIf (..folderCategory="public") {
						// items where owner '= current user AND there is no resource
						If ((tOwner'=$UserName)&&(tResource="")) {
							Set tShow = 1
						}
					}
					Set tSkip = 'tShow
				}

				If ('tSkip) {
					Set tFolder = $P(tName,"/",1,$L(tName,"/")-1)
					Set:tFolder="" tFolder=" "
					Set tItems($$$UPPER(tFolder),tSortKey) = tList(k)
				}

				Set k = $O(tList(k))
			}
		}

		// now place items into json list
		Set f = $O(tItems(""))
		While (f'="") {
			Set k = $O(tItems(f,""))
			While (k'="") {
				Set tName = $LG(tItems(f,k),1)
				Set tFolder = $P(tName,"/",1,$L(tName,"/")-1)
				Set tType = $LG(tItems(f,k),2)
				Set tTip = $LG(tItems(f,k),3)
				Set tURL = $LG(tItems(f,k),5)
				Set tIcon = $LG(tItems(f,k),6)
				Set tKeywords = $LG(tItems(f,k),7)
				Set tShortName = $P(tName,".",1)
				Set tShortName = $P(tShortName,"/",$L(tShortName,"/"))
				Set tTitle = $LG(tItems(f,k),9)
				Set:tTitle="" tTitle = ##class(%DeepSee.UserPortal.Utils).%ResolveText($TR(tShortName,"#","/"))
				Set tCoverSpec = $LG(tItems(f,k),12)
				Set tCategory = $LG(tItems(f,k),13)
				Set tActive = 1
				Set tOwner = $LG(tItems(f,k),14)
				Set tWrite = $LG(tItems(f,k),15)
				If (tOwner'="") {
					Set tOwner = ##class(%DeepSee.UserPortal.Utils).%GetUserName(tOwner)
				}

				// localized folder name
				// split folder name into pieces
				// folders use $$$name:domain
				Set tDisplayFolder = ""
				For px = 1:1:$L(tFolder,"/") {
					Set tDisplayFolder = tDisplayFolder _ $S(tDisplayFolder="":"",1:"/")_##class(%DeepSee.UserPortal.Utils).%ResolveText($TR($P(tFolder,"/",px),"#","/"))
				}

				// set default category
				If (0 && tCategory="") {
					Set tCategory = $Case(..folderCategory,
						"all":$$$Text("All"),
						"public":$$$Text("Public"),
						"private":$$$Text("Private"),
						"favorites":$$$Text("Favorites"),
						"shared":$$$Text("Shared"),
						:"")
				}

				// add item to JSON list
				// JMD1370 call link
				Set tURL = ##class(%CSP.Page).Link(tURL)
				Set pData($I(n)) = $LB(tCategory,tName,tDisplayFolder,tTitle,tCoverSpec,tTitle,tURL,tType,tKeywords,tIcon,tActive,tOwner,tWrite)

				Set k = $O(tItems(f,k))
			}
			Set f = $O(tItems(f))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Store a persistent cookie.
ClientMethod storeCookie(property, value) [ Internal, Language = javascript ]
{
	var page = zenPage._serverClass;
	var index = this.index;
	var date = new Date();
	date.setFullYear(date.getFullYear()+1);

	if (self.document.cookie) {
		self.document.cookie = page + ':' + index + ':' + property + '=' + escape(value) +
		'; expires=' + date.toGMTString();
	}
}

/// Launch the book cover editor.
ClientMethod designBookCover(name, spec) [ Language = javascript ]
{
	// remember the name
	this._currItemName = name;
	var parms = {
		SPEC:spec
	}
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.BookCoverBuilder.zen','CoverEdit','status,scrollbars,resizable=yes,width=1000,height=700',parms);
}

/// Return an object describing what to display for this level within the navigator.
ClientMethod navGetContentForLevel(level, key, value) [ Language = javascript ]
{
	var title = $$$Text('Home Page Settings','%DeepSee');
	var content = { title: title, items:[] };
	var navigator = this.getNavigator();

	switch (key) {
	case '':
		// root
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Add','%DeepSee'), action:'drill', key:'addItem'};
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Background','%DeepSee'), action:'drill', key:'desktopStyle'};
		break;

	case 'addItem':
		title = $$$Text('Add New Item','%DeepSee');
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Add Dashboard','%DeepSee'), action:'select', key:'newDashboard'};
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Add Pivot','%DeepSee'), action:'select', key:'newPivot'};
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Add Report Shortcut','%DeepSee'), action:'select', key:'newReport'};
		content.items[content.items.length] = {display:'caption', caption:$$$Text('Add Link','%DeepSee'), action:'select', key:'newLink'};
		break;

	case 'desktopStyle':
		title = $$$Text('Style','%DeepSee');

		// pull apart style from incoming value
		var info = navigator.parseStyle(this.desktopStyle);
		var color = info.color;
		var background = info.backgroundColor;
		var fontFamily = info.fontFamily;
		var fontSize = info.fontSize;

		var fs = [];
		if (info.bold) { fs[fs.length] = 'bold'; }
		if (info.underline) { fs[fs.length] = 'underline'; }
		if (info.italic) { fs[fs.length] = 'italic'; }
		if (info.shadow) { fs[fs.length] = 'shadow'; }
		var fontStyle = fs.join(',');
		var which = key;

		content.items[content.items.length] = {display:'caption', caption:$$$Text('Reset Styles','%DeepSee'), action:'select', key:which+'-reset', help:$$$Text('Reset the background style','%DeepSee'), disabled:!zenPage.hasOverrides()};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Color','%DeepSee'), action:'drill', value:'',	key:which+'-color', valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+color+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Background','%DeepSee'), action:'drill', value:'',	key:which+'-background', valueStyle:'width:80px;border-radius:5px;border:1px solid #B0B0B0;background:'+background+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font','%DeepSee'), action:'drill', value:fontFamily,	key:which+'-font-family', valueStyle:'font-size:13px;font-family:'+fontFamily+';'};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Font Size','%DeepSee'), edit:'slider-toggle', value:fontSize,	key:which+'-font-size', minValue:2, maxValue:75, stepSize:1};
		content.items[content.items.length] = {display:'caption-value-hz', caption:$$$Text('Text Style','%DeepSee'), edit:'choice-multi', value:fontStyle,	key:which+'-style', valueList:'bold,italic,underline,shadow', displayList:'B,I,U,S', valueStyle:'font-size:12px;font-family:times new roman;',  choiceStyles:'font-weight:900;^font-style:italic;^text-decoration:underline;^text-shadow:1px 1px 2px #F0F0F0;'};
		break;

	case 'desktopStyle-color':
		// choose a color
		title = $$$Text('Color','%DeepSee');
		content.html = navigator.getColorChooserHTML(key,value,'html');
		break;

	case 'desktopStyle-background':
		// choose a color
		title = $$$Text('Background','%DeepSee');
		content.html = navigator.getColorChooserHTML(key,value,'html');
		break;

	case 'desktopStyle-font-family':
		title = $$$Text('Font','%DeepSee');
		content.html = navigator.getFontChooserHTML(key,value);
		break;
	}

	content.title = title;
	return content;
}

/// Select of item within the navigator.
ClientMethod navSelectItem(key, value, which) [ Language = javascript ]
{
	if (which == 'select') {
		switch(key) {
		case 'desktopStyle-reset':
			this.resetOverrides();
			break;
		case 'newDashboard':
			this.newDashboard();
			break;
		case 'newPivot':
			this.gotoAnalyzer();
			break;
		case 'newLink':
			this.newLink();
			break;
		case 'newReport':
			this.newReport();
			break;
		}

		var nav = this.getNavigator();
		nav.setExpanded(false);
		nav.popSheet();
	}
}

/// Show add item menu.
ClientMethod addNewItem() [ Language = javascript ]
{
	var nav = this.getNavigator();
	nav.setExpanded(true);

	var itemSpec = {key:'addItem'};
	nav.slideInto(itemSpec);
}

/// Change of data value in navigator.
ClientMethod navDataChange(key, value, final) [ Language = javascript ]
{
	var navigator = zen('navigator');

	var which = '';

	// key is which-element
	// use selectedElement in case user has clicked on a new item.
	var t = key.toString().split('-');
	if (t.length>1) {
		which = t[0];
		t.splice(0,1);
	}
	var k2 = t.join('-');

	var style = this[which];

	switch (k2) {
	case 'color':
	case 'background':
	case 'font-family':
	case 'opacity':
	case 'displayed':
	case 'text-align':
		style = navigator.setStyleIntoCSS(style,k2,value);
		break;

	case 'style':
		var styleValues = {};
		var cv = value.toString().split(',');
		for (var n = 0; n < cv.length; n++) {
			styleValues[cv[n]] = true;
		}
		var list = ['bold','underline','italic','shadow'];
		for (var n = 0; n < list.length; n++) {
			style = navigator.setStyleIntoCSS(style,list[n],styleValues[list[n]]?true:false);
		}
		break;

	case 'border-radius':
	case 'font-size':
	case 'padding':
	case 'margin':
	case 'top':
	case 'left':
	case 'height':
	case 'width':
		value = value!=='' ? value+'px' : value;
		style = navigator.setStyleIntoCSS(style,k2,value);
		break;
	}
	
	this[which] = style;
	switch(which) {
	case 'desktopStyle':
		zen('coversList').setProperty('backgroundStyle',this.desktopStyle);
		if (final) {
			// remember in cookie
			this.storeCookie('desktopStyle',style);
		}
		break;
	}
}

/// Test if there are background style overrides.
ClientMethod hasOverrides() [ Language = javascript ]
{
	return true;
	return (this.desktopStyle!='') ? true : false;
}

/// Reset any background style overrides.
ClientMethod resetOverrides() [ Language = javascript ]
{
	this.desktopStyle = '';
	zen('coversList').setProperty('backgroundStyle',this.desktopStyle);
	this.storeCookie('desktopStyle','');
}

/// Launch the dashboard finder.
ClientMethod openDashboard() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=dashboards','DashboardOpen','status,scrollbars,resizable=yes,width=800,height=600');
}

}
