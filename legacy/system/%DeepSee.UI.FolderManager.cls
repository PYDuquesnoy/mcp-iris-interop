/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// DeepSee Folder Manager page.
Class %DeepSee.UI.FolderManager Extends %DeepSee.UI.standardPage [ System = 4 ]
{

Parameter PAGENAME = "Folder Manager";

Parameter RESOURCE = "%DeepSee_Admin,%Development";

Parameter DOCBOOKID = "D2GS_uis_folder_manager";

/// Current folder name.
Property folderName As %ZEN.Datatype.string;

/// Export directory.
Property directory As %ZEN.Datatype.string;

/// List of selected items.
Property selectedItems As list Of %ZEN.Datatype.string;

/// List of selected files.
Property selectedFiles As list Of %ZEN.Datatype.string;

/// Comma-delimited list of resources available for the current user
Property resourceList As %ZEN.Datatype.string [ Internal ];

XData Style
{
<style type="text/css">

.zenLabel {
	color: rgb(67,67,67);
	font-size: 10pt;
}
.zenLabelDisabled {
	font-size: 10pt;
}

.zenHint {
	color: rgb(67,67,67);
	font-size: 8pt;
}

.workListType {
	font-size: 12px;
	color: #404080;
	font-variant: small-caps;
}

.rowHover {
	background: #FFEEAA;
}

#leftGroup {
	background: #D0D0D0;
}

#form {
	width: 360px;
	background: #D0D0D0;
	border-right: 1px solid #F0F0F0;
	margin-bottom: -20px;
}

#foldersList {
	background: white;
	overflow: auto;
	border: 1px solid #D0D0D0;
	display: none;
}

table.listTable td a {
	color: #404040;
	text-decoration: none;
}

table.listTable td a:hover {
	color: #404040;
	text-decoration: underline;
}

#help {
	color: #404040;
	font-size: 9pt;
}

#Directory {
	color: #404040;
	background: #D0D0D0;
	border-right: 1px solid #F0F0F0;
	height: 100px;
	width: 360px;
	overflow: auto;
}

.dirTable {
	font-size: 9pt;
}

#itemDetails {
	color: #404040;
	background: #D0D0D0;
	border-right: 1px solid #F0F0F0;
	height: 100px;
	width: 360px;
	overflow: auto;
}

#itemDetails ul {
	padding-left: 1em;
	text-indent: 0em;
	margin-left: 0px;
	margin-top: 0px;
}

.detailLabel {
	font-size: 9pt;
	font-weight: bold;
	color: #606060;
	padding: 2px;
}

.detailValue {
	padding: 2px;
	color: #202020;
	margin-bottom: 3px;
}

.EmptyMsg {
	padding: 20px;
	font-size: 20px;
	color: #808080;
}

/* folder list */
table.listTable {
}

table.listTable th {
	text-align: left;
	background: #D0D0D0;
	color: black;
	font-size: 16px;
	font-weight: bold;
	padding-top: 2px;
	padding-bottom: 2px;
}

tr.listRowEven {
}

tr.listRowOdd {
	background: rgb(236,236,236);
}

.tabGroupBody {
	background: #D0D0D0;
	min-height: 100px;
}
.tabGroupExtra {
	background: #D0D0D0;
}
.tabGroupGapTd {
	background: #D0D0D0;
}

</style>
}

/// This XML defines the contents of the contents pane for this page.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" 
	xmlns:deepsee="http://www.intersystems.com/deepsee"
>
<hgroup cellVAlign="top">
<vgroup id="leftGroup">
<form id="form" cellStyle="padding:4px;">
<html id="help" OnDrawContent="DrawHelp"/>
<radioSet id="ExportTo" name="ExportTo" label="Export/Import Location" displayList="Server,Browser" valueList="SERVER,BROWSER"
onclick="zenPage.doLocationChange(zenThis.getValue());" value="SERVER"/>
<text id="ctrlDirectory" size="35" label="Server Directory" onchange="zenPage.setExportDirectory(zenThis.getValue());"/>
<vgroup>
<checkbox id="ctrlUseContainerClass" caption="Create Container Class For Export" onclick="zenPage.toggleContainer(zenThis.value)"/>
<checkbox id="ctrlExportRelated" width="30" hidden="true" caption="Export Related Supporting Items"/>
<text id="ctrlContainerClassName" size="35" hidden="true" label="Container Class Name" hint="Valid class name required. Include a package name if defined."/>
</vgroup>
<hgroup>
<button caption="Export" id="btnExport" title="Export the selected items to the export directory" onclick="zenPage.exportThem();"/>
<spacer width="10"/>
<button caption="Import" id="btnImport" title="Import selected item(s)" onclick="zenPage.importThem();"/>
<spacer width="10"/>
<button caption="Delete" id="btnDelete" title="Delete the selected items" onclick="zenPage.deleteSelected();"/>
<spacer width="10"/>
<button caption="Browse" id="btnBrowse" title="Browse to Find Directory" onclick="zenPage.browseSelect();"/>
</hgroup>
<spacer height="10"/>
</form>
<tabGroup showTabBar="true" id="tabGrp">
<tab id="tab1" caption="Details" title="Details on selected item">
<html id="itemDetails" />
</tab>
<tab id="tab2" caption="Directory"  title="Contents of export directory">
<group id="svrExportDirectory">
<html id="exportDirectory" OnDrawContent="DrawExportDirectory" />
</group>
<group id="fileUpload" cellStyle="padding:4px;" hidden="true">
<form name="fileUploadForm" id="fileUploadForm"  enctype="multipart/form-data">
<fileUpload id="fileUploadCtrl" name="fileUploadCtrl" multiple="false" required="true" accept="text/xml"/>
</form>
</group>
</tab>
</tabGroup>
</vgroup>
<html id="foldersList" OnDrawContent="DrawFolders"/>
</hgroup>
</pane>
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Folder Manager","%DeepSee")
}

/// Get the product name for the page.
Method %OnGetProductName() As %String
{
	Quit "DeepSee"
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Folder Manager","%DeepSee")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 1
	Set pRibbonTitle = $$$Text("Folder Manager")

	Quit $$$OK
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		if (load) {
			this.updateDetails();
		}
		this.adjustSizes();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		var th = this.getTitleAreaHeight();

		var folders = zen('foldersList');
		var foldersDiv = folders.getEnclosingDiv();

		var form = zen('form');
		var formDiv = form.getEnclosingDiv();

		var hgt = winHeight - th - 25;
		var wid = winWidth - formDiv.offsetWidth - 25;

		// DTB540 - set all tab contents to the same height
		var tabsHeight = (((hgt - formDiv.offsetHeight)>0)?(hgt - formDiv.offsetHeight):0) + 'px';
		
		// DTB540 - Resize tabs in a way that satisfies all browsers (IE)
		var tabGrp = zen('tabGrp');
		var tabGrpDiv = tabGrp.getEnclosingDiv();
		
		tabGrp.height = tabsHeight;
		if (zenIsIE) {
			tabGrp.refreshContents();
		}
		else {
			var tabGrp = zen('tabGrp');
			var tabGrpDiv = tabGrp.getEnclosingDiv();
			
			var details = zen('itemDetails');
			var detailsDiv = details.getEnclosingDiv();

			var exportDir = zen('exportDirectory');
			var exportDiv = exportDir.getEnclosingDiv();
			
			// DTB540 - Control styling of the file directory tabs
			var fileUploadDir = zen('fileUpload');
			var fileUploadDiv = fileUploadDir.getEnclosingDiv();
			
			tabGrpDiv.style.height = parseInt(tabsHeight) + 20 + 'px';		// 20px is the height of the tab bar
			detailsDiv.style.height = tabsHeight;
			exportDiv.style.height = tabsHeight;
			fileUploadDiv.style.height = tabsHeight;
		}

		foldersDiv.style.height =  (hgt>0?hgt:0) + 'px';
		foldersDiv.style.width =  (wid>0?wid:0) + 'px';
		foldersDiv.style.display =  'block';
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		#; register visit
		Set tSC = ..%Register()
		If $$$ISERR(tSC) Quit
		
		// +DTB264
		Set tSC = ..%GetResourceList(.tResources)
		Set tResourceIdx = $O(tResources(""),1,tResourceData)
		While tResourceIdx'="" {
			Set ..resourceList = ..resourceList _ $S($L(..resourceList):",",1:"") _ $LG(tResourceData,1) _":"_ $LG(tResourceData,2)
			Set tResourceIdx = $O(tResources(tResourceIdx),1,tResourceData)
		}
		// -DTB264

		Set ..directory = $G(^DeepSee.UserPortalSettings("ExportDirectory"))
		Set ..%GetComponentById("ctrlDirectory").value = ..directory
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Draw content of the help box.
Method DrawHelp(pSeed As %String) As %Status
{
	Write $$$Text("The Folder Manager lets you import, export, and delete items within user folders.","%DeepSee")
	&html<<hr/>>
	Quit $$$OK
}

/// Draw content of folders list.
Method DrawFolders(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSearch = $$$UPPER(..searchKey)

		Set tFolderIconUp = "portal/disc_up.gif"
		Set tFolderIconDown = "portal/disc_down.gif"
		Set tDelIcon = "deepsee/ds2_x_44.png"
		Set hlpDel = $$$Text("Delete this item","%DeepSee")
		Set hlpAll = $$$Text("Select or unselect all items","%DeepSee")

		// list of folders: some may not have any items
		Set tSC = ##class(%DeepSee.UserLibrary.Utils).%GetFolderList(.tFolderList)
		If $$$ISERR(tSC) Quit

		Set tSC = ##class(%DeepSee.UserPortal.Utils).%GetFolderItemsForUser(.tList,..folderName,..searchKey,1)
		If $$$ISERR(tSC) Quit
		
		If (('$D(tList))&&('$D(tFolderList))) {
			&html<<div class="EmptyMsg">#($$$TextHTML("There are no folders currently defined.","%DeepSee"))#</div>>
			Quit
		}

		// build list to display
		Set tCurrFolder = -1E14
		Set k = $O(tList(""))
		While (k'="") {
			Set tName = $LG(tList(k),1)
			Set tKeywords = $LG(tList(k),7)
			Set tCreatedBy = $LG(tList(k),10)
			Set tLastAccessed = $LG(tList(k),16)

			// apply search key, if present
			// DP-419954 - Add createdBy and lastAccessed in search results
			Set tSkip = 0
			if (tSearch'="") {
				If (($$$UPPER(tName)'[tSearch)&&($$$UPPER(tKeywords)'[tSearch)&&($$$UPPER(tCreatedBy)'[tSearch)&&($$$UPPER(tLastAccessed)'[tSearch)) {
					Set tSkip = 1
				}
			}
			If ('tSkip) {
				Set tFolder = $P(tName,"/",1,$L(tName,"/")-1)
				If ((tFolder'="") && (tFolder '= tCurrFolder)) {
					// new folder
					Set tCurrFolder = tFolder
					Set tItems($$$UPPER(tCurrFolder)) = tFolder
				}
				Set tSortKey = $$$UPPER(tName)
				Set tItems($$$UPPER(tCurrFolder),tSortKey) = tList(k)
			}
			Set k = $O(tList(k))
		}

		// merge in folders with no items
		Set k = $O(tFolderList(""))
		While (k'="") {
			Set tName = tFolderList(k)
			// apply search key, if present
			Set tSkip = 0
			if (tSearch'="") {
				If (($$$UPPER(tName)'[tSearch)) {
					Set tSkip = 1
				}
			}
			If ('tSkip) {
				Set tItems($$$UPPER(tName)) = tName
			}
			Set k = $O(tFolderList(k))
		}

		Set msgName = $$$Text("Name")
		Set msgCreatedBy = $$$Text("Created By")
		Set msgLastAccessed = $$$Text("Last Accessed")		// DP-419954
		Set msgType = $$$Text("Type")
		Set msgName = $$$Text("Name")
		Set msgPublic = $$$Text("Public")
		Set msgKeyword = $$$Text("Keywords")
		Set tTruncLen = 50
		
		&html<<div id="folderList">
		<table class="listTable" width="100%" cellspacing="0" border="0" cellpadding="0">>
		&html<<tr class="listHeader">
			<th>&nbsp;</th>
			<th><input type="checkbox" input type="checkbox" title="#(hlpAll)#" id="cb_all" onclick="zenPage.allClick();"/></th>
			<th>&nbsp;</th>
			<th width="35%">#(msgName)#</th>
			<th width="15%">#(msgType)#</th>
			<th width="15%">#(msgCreatedBy)#</th>
			<th width="20%">#(msgLastAccessed)#</th>
			<th width="5%">#(msgPublic)#</th>
			<th>&nbsp;</th>
			</tr>>

		Set tCurrFolder = ""
		Set r = 0
		Set f = $O(tItems(""))
		While (f'="") {
			If (f '= -1E14) {
				// folder
				Set tName = $G(tItems(f))
				Set tIndent = $L(tName,"/")

				For p = 1:1:$L(tName,"/") {
					Set tTest = $P(tCurrFolder,"/",p)
					Set tFolderName = $P(tName,"/",p)
					Set tFName = $P(tName,"/",1,p)
					If ($$$UPPER(tTest) '= $$$UPPER(tFolderName)) {
						Set tURL = ""
						Set tTip = tName
						Set r = r + 1
						Set tFolderIndent = p-1
						Set tCls = $S(r#2:"listRowOdd",1:"listRowEven")
						
						// DTB777 - Prepare user defined strings for insertion into the HTML
						Set tEscapedTip = ..EscapeHTML(tTip)
						Set tEscapedFName = ..EscapeHTML(tFName)
						Set tEscapedName = ..EscapeHTML(tName)
						Set tEscapedTranslatedFolderName = ..EscapeHTML(##class(%DeepSee.UserPortal.Utils).%ResolveName(tFolderName)) //Localization added by APV107
						
						
						&html<<tr id="frow_#(r)#" class="#(tCls)#" style="font-weight:bold;color:#404040;" title="#(tEscapedTip)#" folderName="#(tEscapedFName)#" expanded="1" onmouseover="this.className='rowHover';" onmouseout="this.className='#(tCls)#';">
							<td>&nbsp;</td>
							<td><input type="checkbox" id="cb_#(r)#" value="#(tEscapedName)#" onclick="zenPage.cbClick(this);"/></td>>
							&html<<td>
							<image src="images/spacer.gif" width="#(tFolderIndent*24)#" height="24"/>
							<image id="icon_#(r)#" src="#(tFolderIconDown)#" height="24" width="24" alt="+" onclick="zenPage.toggleFolder(#(r)#);"/>
							</td>>
							&html<
							<td onclick="zenPage.rowClick('#(r)#');">#(tEscapedTranslatedFolderName)#</td>
							<td onclick="zenPage.rowClick('#(r)#');">#($$$Text("Folder","%DeepSee"))#</td>
							<td onclick="zenPage.rowClick('#(r)#');">&nbsp;</td>
							<td onclick="zenPage.rowClick('#(r)#');">&nbsp;</td>
							<td onclick="zenPage.rowClick('#(r)#');">&nbsp;</td>
							<td nowrap="1">
							<image src="#(tDelIcon)#" style="height:12px;width:12px;padding:2px;" alt="Delete" title="#(hlpDel)#" onclick="zenPage.deleteFolder('#(tEscapedName)#');"/>
							</td>
							</tr>>
					}
				}
			}
			Else {
				Set tIndent = 0
			}
			Set tCurrFolder = f

			// items in folder
			Set n = $O(tItems(f,""))
			While (n'="") {
				// $LB(name,type,tip,date,url,icon,keywords,public,title,createdBy,resource,cover,category,owner,write,lastAccessed)
				Set tName = $LG(tItems(f,n),1)		// User-defined
				Set tType = $LG(tItems(f,n),2)
				Set tTip = $LG(tItems(f,n),3)		// User-defined
				Set tURL = $LG(tItems(f,n),5)		// User-defined
				Set tIcon = $LG(tItems(f,n),6)
				Set tKeywords = $LG(tItems(f,n),7)		// User-defined
				Set tShortName = $P(tName,".",1)		// Derived from user-defined
				Set tCreatedBy = $LG(tItems(f,n),10)		// Can be user defined
				Set tLastAccessed = $LG(tItems(f,n),16)		// DP-419954
				Set tShortName = $P(tShortName,"/",$L(tShortName,"/"))
				Set tPublic = $S(+$LG(tItems(f,n),8):$$$Text("Yes"),1:"")
				
				// DTB777 - Prepare user defined strings for insertion into the HTML
				Set tEscapedName = ..EscapeHTML(tName)
				Set tEscapedTip = ..EscapeHTML(tTip)
				Set tEscapedURL = ..EscapeHTML(tURL)		// DTB778
				Set tEscapedKeywords = ..EscapeHTML(tKeywords)
				Set tEscapedCreatedBy = ..EscapeHTML(tCreatedBy)
				Set tEscapedTranslatedShortName = ..EscapeHTML(##class(%DeepSee.UserPortal.Utils).%ResolveName(tShortName))

				Set r = r + 1
				Set:tKeywords="" tKeyword = "&nbsp;"
				Set tCls = $S(r#2:"listRowOdd",1:"listRowEven")
				&html<<tr id="frow_#(r)#" fvalue="#(tEscapedName)#" class="#(tCls)#" title="#(tEscapedTip)#" folderName="#(tEscapedName)#" onmouseover="this.className='rowHover';" onmouseout="this.className='#(tCls)#';">
				<td>&nbsp;</td>
				<td><input type="checkbox" id="cb_#(r)#" value="#(tEscapedName)#" onclick="zenPage.cbClick(this);"/></td>>
				&html<<td nowrap="1">>
				&html<<image src="images/spacer.gif" width="#(tIndent*24)#" height="24"/>>
				If (tIcon '= "") {
					&html<<image style="height:16px;padding:2px;" src="#(tIcon)#" alt="#(tType)#"/>>
				}
				&html<</td>>
				&html<
					<td onclick="zenPage.rowClick('#(r)#');"><a href="#(tEscapedURL)#">#(tEscapedTranslatedShortName)#</a></td>
					<td class="workListType" onclick="zenPage.rowClick('#(r)#');">#(tType)#</td>
					<td onclick="zenPage.rowClick('#(r)#');">#(tEscapedCreatedBy)#&nbsp;</td>
					<td onclick="zenPage.rowClick('#(r)#');">#(tLastAccessed)#&nbsp;</td>
					<td onclick="zenPage.rowClick('#(r)#');">#(tPublic)#</td>
					<td nowrap="1">
					<image src="#(tDelIcon)#" style="height:12px;width:12px;padding:2px;" alt="Delete" title="#(hlpDel)#" onclick="zenPage.deleteItem('#(tEscapedName)#');"/>
					</td>
					</tr>>

				Set n = $O(tItems(f,n))
			}
			Set f = $O(tItems(f))
		}
		&html<</table></div>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Adjust the presentation to the user when the Container Class checkbox is checked.
ClientMethod toggleContainer(value) [ Language = javascript ]
{
	// Method Added By DTB514
	if (value) {
		zen('ctrlExportRelated').setProperty('hidden',false);
		zen('ctrlContainerClassName').setProperty('hidden',false);
	}
	else {
		// Turn off the related items. Export does not support individual classes of non-folder items.
		zen('ctrlExportRelated').setValue(false);
		zen('ctrlExportRelated').setProperty('hidden',true);
		zen('ctrlContainerClassName').setProperty('hidden',true);
	}
}

/// Hide/show folders in list.
ClientMethod toggleFolder(index) [ Language = javascript ]
{
	var folder = self.document.getElementById('frow_'+index);
	var folderName = folder.getAttribute('folderName');
	var expanded = !(parseInt(folder.getAttribute('expanded')) == 1);
	var icon = self.document.getElementById('icon_'+index);
	icon.src = !expanded ? 'portal/disc_up.gif' : 'portal/disc_down.gif';
	folder.setAttribute('expanded',expanded ? 1 : 0);
	
	// visit each row in the table
	var row = 0;
	while(true) {
		row++;
		var tr = self.document.getElementById('frow_'+row);
		if (!tr) break;
		
		var name = tr.getAttribute('folderName');
		if ((name.substr(0,folderName.length+1) == folderName+'/') && (name!=folderName)) {
			tr.style.display = expanded ? '' : 'none';
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

/// Delete the given folder.
ClientMethod deleteFolder(name) [ Language = javascript ]
{
	if (confirm($$$Text('Do you want to permanently delete this folder and its contents for all users?')+'\n'+name,false)) {
		var msg = zenPage.SendItemToTrash(name);
		if ('' != msg) {
			alert(msg);
		}
		this.refreshFolders();
	}
}

/// Delete the given item.
ClientMethod deleteItem(name) [ Language = javascript ]
{
	if (confirm($$$Text('Do you want to delete this item?')+'\n'+name,false)) {
		var msg = zenPage.SendItemToTrash(name);
		if ('' != msg) {
			alert(msg);
		}
		this.refreshFolders();
	}
}

/// Set the export directory.
ClientMethod setExportDirectory(dir) [ Language = javascript ]
{
	this.directory = dir;
	// update contents display
	zen('exportDirectory').refreshContents();
}

/// Reload the folder list.
ClientMethod refreshFolders() [ Language = javascript ]
{
	var folders = zen('foldersList');
	folders.refreshContents();
}

/// Click on all check box.
ClientMethod allClick() [ Language = javascript ]
{
	var cbAll = self.document.getElementById('cb_all');

	for (var r = 1;;r++) {
		var cb = self.document.getElementById('cb_'+r);
		if (cb) {
			cb.checked = cbAll.checked;
		}
		else {
			break;
		}
	}

	this.updateDetails();
}

/// Click on row.
ClientMethod rowClick(row) [ Language = javascript ]
{
	var cbAll = self.document.getElementById('cb_all');
	cbAll.checked = false;

	for (var r = 1;;r++) {
		var cb = self.document.getElementById('cb_'+r);
		if (cb) {
			cb.checked = (r == row);
		}
		else {
			break;
		}
	}
	this.updateDetails();
}

/// Click on checkbox.
ClientMethod cbClick(cb) [ Language = javascript ]
{
	var cbAll = self.document.getElementById('cb_all');
	cbAll.checked = false;
	this.updateDetails();
}

/// Return an array of selected folder items.
ClientMethod getSelectedItems() [ Language = javascript ]
{
	var array = new Array();
	for (var r = 1;;r++) {
		var cb = self.document.getElementById('cb_'+r);
		if (cb) {
			if (cb.checked) {
				array[array.length] = cb.value;
			}
		}
		else {
			break;
		}
	}
	
	return array;
}

/// Return an array of selected files in export directory.
ClientMethod getSelectedFiles() [ Language = javascript ]
{
	var array = new Array();
	for (var r = 1;;r++) {
		var cb = self.document.getElementById('xcb_'+r);
		if (cb) {
			if (cb.checked) {
				array[array.length] = cb.value;
			}
		}
		else {
			break;
		}
	}
	
	return array;
}

/// Export selected items.
ClientMethod exportThem() [ Language = javascript ]
{
	// NOTE: do not call this method "export" as IE will crash!
	
	this.selectedItems = this.getSelectedItems();
	if (this.selectedItems.length == 0) {
		alert($$$Text('Nothing selected'));
		return;
	}
	// + WAL248
	var useContainerClass = zen('ctrlUseContainerClass').value;
	var containerClassName = zen('ctrlContainerClassName').value;
	var msg = zenPage.ExportItems(useContainerClass,containerClassName);
	// - WAL248
	if ('' != msg) {
		alert(msg);
	}
	zen('exportDirectory').refreshContents();
}

/// Delete selected items.
ClientMethod deleteSelected() [ Language = javascript ]
{
	this.selectedItems = this.getSelectedItems();
	if (this.selectedItems.length == 0) {
		alert($$$Text('Nothing selected'));
		return;
	}
	if (confirm($$$Text('Do you want to delete the selected items?')+'\n'+name,false)) {
		var msg = zenPage.DeleteItems();
		if ('' != msg) {
			alert(msg);
		}
		this.refreshFolders();
	}
}

/// Import selected items.
ClientMethod importThem() [ Language = javascript ]
{
	var importLocation = zen('ExportTo').getValue();		// DTB540 - Take location selection into account
	if ('SERVER'==importLocation) {
		this.selectedFiles = this.getSelectedFiles();
		if (this.selectedFiles.length == 0) {
			alert($$$Text('No files selected'));
			return;
		}
		
		if (confirm($$$Text('Do you wish to import the selected files?'))) {
		var msg = zenPage.ImportItems();
		if ('' != msg) {
			alert(msg);
		}
		this.refreshFolders();
	}
	}
	else if ('BROWSER'==importLocation) {
		// DTB540 - Import the file from the client
		var importFile = zen('fileUploadCtrl').getValue();
		if (!importFile) {
			alert($$$Text('No file selected'));
			return;
		}
		
		// Same prompt as when loading from the server
		if (confirm($$$Text('Do you wish to import the selected file?'))) {
			zen('fileUploadForm').submit();
		}
		
		this.refreshFolders();
	}
}

/// Delete the given folder item or folder.
Method SendItemToTrash(pName As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		Set tCount = 0
		
		// DP-419305 - Test for existence of a folderItem that has pName.
		// If none is found, see if this was called for a folder.
		If ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(pName,.tFolderID) {
			// Item exists; move it to the trash folder
			Set tItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pName,.tSC)
			If $$$ISERR(tSC) Quit
			
			If $IsObject(tItem) {
				Set tExt = $P(tItem.fullName,".",$L(tItem.fullName,"."))
				Set tTrashName = "$TRASH" _ $S(tItem.folderName="":"",1:"/") _ tItem.folderName _ "/" _ tItem.name _ "." _ tExt
				Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderItem(tTrashName)
				If $$$ISERR(tSC) Quit

				Set tItem.fullName = tTrashName
				Set tSC = tItem.%Save()
				If $$$ISERR(tSC) Quit
				Set tCount = tCount + 1
			}
		}
		Else {
			// If no item, check for folder; delete if found
			Set tFolder = ##class(%DeepSee.UserLibrary.Utils).%FindFolder(pName)
			If $IsObject(tFolder) {
				Set tSC = tFolder.%DeleteId(tFolder.%Id())
				If $$$ISERR(tSC) {
					Do $System.Status.DecomposeStatus(tSC,.tDecomp)
					If ($G(tDecomp(1,"code"))=5823){
						Set tMsg = $$$Text("Unable to delete folder. Make sure that all subfolders are deleted first.")
						Set tSC = $$$OK
					}
					Quit
				}
				Set tCount = tCount + 1
			}
		}
		Set:tMsg'="" tMsg = $$$FormatText($$$Text("%1 item(s) deleted."),tCount)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// Export the current selected list.
Method ExportItems(pUseContainerClass As %Boolean, pContainerClassName As %String = "") As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Try {
		// remember directory
		Set ^DeepSee.UserPortalSettings("ExportDirectory") = ..directory
		Set tDir = ##class(%File).NormalizeDirectory(..directory)
		
		Set tExportTo = ..%GetComponentById("ExportTo").value		// DTB498
		
		If (pUseContainerClass) {
			// + WAL248 -- create a new container class
			If (pContainerClassName'="") {
				If '(..IsValidClassName(pContainerClassName)) {
					// DTB498 - If entered, insist that the class name is valid before proceeding
					Set tSC = $$$ERROR($$$GeneralError,$$$Text("Please enter a valid container class name. A package is required.","%DeepSee"))
					Quit
				}
				Set tClassDefName = pContainerClassName
			}
			Else {
				Set tClassDefName = "FolderManager.Export"_$P($H,",",2)	
			}
			
			#; Create a new class definition
			Set tClassDef = ##class(%Dictionary.ClassDefinition).%New(tClassDefName)
			If tClassDef = $$$NULLOREF Set tSC=$$$ERROR($$$CannotCreateObject,"%Dictionary.ClassDefinition") Quit
			Set tClassDef.Super = "%DeepSee.UserLibrary.Container"
	        Set tClassDef.IncludeCode = "%DeepSee"
	        
	        // Create items XDATA Block
			Set tExportData = ##class(%Dictionary.XDataDefinition).%New()
		
			Set tExportData.Description = "Items Exported From Folder Manager."
			Set tExportData.XMLNamespace = "http://www.intersystems.com/deepsee"

			Set tExportData.Name = "Contents"
			Set tExportData.parent = tClassDef
			
			// The Utils Export can handle a stream. So let's get a stream going
			Set tTempStream = ##class(%Stream.TmpCharacter).%New()
			
			// Write in items tag
			Do tTempStream.Write("<items>")
			// - WAL248
		}
		
		set tExportRelatedItems = ..%GetComponentById("ctrlExportRelated").value	// DTB514

		Set tCount = 0
		For n = 1:1:..selectedItems.Count() {
			Set tName = ..selectedItems.GetAt(n)
			//Set tShortName = $TR($P(tName,".",1),"/ ","-_")
			//include type in name to avoid conflicts
			
			// + WAL248 -- pass stream instead of file
			If (pUseContainerClass) {
				If (tExportRelatedItems) {
					// DTB514 - Collect the folder items 
					Set tCurrItemType = $P(tName,".",*)
					
					If (tCurrItemType="pivot")||(tCurrItemType="dashboard") {
						// Currently %GetRelatedItems only supports "pivot" and "dashboard".
						// Test for these in order to avoid an error in the call.
						Set tSC = ##class(%DeepSee.UserLibrary.Utils).%GetRelatedItems(tName,.tRelatedItems,0)
						If $$$ISERR(tSC) $$$ThrowStatus(tSC)	// DTB514 - Throw error from For loop
					}
					
					Set tRelatedItems("all",tName) = ""		// Include the original item in the related items list
					If (tCurrItemType="pivot")||(tCurrItemType="dashboard") {
						Set tRelatedItems("type",tCurrItemType,tName) = ""
					}
					Else {
						Set tRelatedItems("type","folder",tName) = ""
					}
				}
				Else {
					// Export only the original Item
					Set tSC = ##class(%DeepSee.UserLibrary.Utils).%Export(tName,tTempStream,0)
					If $$$ISERR(tSC) $$$ThrowStatus(tSC)		// DTB514 - Throw error from For loop
					
					Set tCount = tCount + 1
				}
			}
			Else {
				// If we aren't using a container class, still export in the standard studio fashion
				// This means we need the dfi name for the file.
				Set tItem = ""
				If (##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(tName)) {
					// DTB580 - Only set the folder item if we know it exists
					Set tItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tName,.tSC)
					If $$$ISERR(tSC) $$$ThrowStatus(tSC)		// DTB514 - Throw error from For loop
				}
				If '$IsObject(tItem) Continue
				
				Set tShortName = $TR(tName,"/ .","-_-")
				Set tFile = tDir_tShortName_".xml"
				Set tDocumentName = tItem.documentName
				//Set tSC = ##class(%DeepSee.UserLibrary.Utils).%Export(tName,tFile,0)
				Set tSC = $system.OBJ.Export(tDocumentName,tFile,"/display=none")
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)		// DTB514 - Throw error from For loop
				
				Set tCount = tCount + 1
			}
			// - WAL248
			If $$$ISERR(tSC) $$$ThrowStatus(tSC)			// DTB514 - Throw error from For loop
		}
		
		If $D(tRelatedItems)&&(tExportRelatedItems)&&(pUseContainerClass) {
			// DTB514 - Loop through the related items and add to the stream
			Set tRelItemName = $O(tRelatedItems("all",""))
			While (tRelItemName'="") {
				// Normalize item name for export
				If $L(tRelItemName,".")>1 {
					Set tTempName = $$$UPPER($P(tRelItemName,".",1,*-1)) _ "." _ $P(tRelItemName,".",*)
				}
				Else {
					Set tTempName = tRelItemName
				}

				Set tSC = ##class(%DeepSee.UserLibrary.Utils).%Export(tTempName,tTempStream,0)
				If $$$ISERR(tSC) $$$ThrowStatus(tSC)
				
				Set tCount = tCount + 1
				Set tRelItemName = $O(tRelatedItems("all",tRelItemName))
			}
		}
		
		If (pUseContainerClass) {
			// + WAL248 -- copy stream to XDATA block and save class
			// Close items tag
			Do tTempStream.Write("</items>")
			
			Set tSC = tExportData.Data.CopyFrom(tTempStream)
			If $$$ISERR(tSC) Quit
			
			Set tSC = tClassDef.%Save()
			If $$$ISERR(tSC) Quit
			
			// Export to a file and then delete the class
			Set tExportName = $P(tClassDefName,".",*)_".xml"
			Set tExportFullPath = tDir_tExportName
			Set tClassName = tClassDefName_".cls"
			
			If (tExportTo="SERVER") {
				Set tSC = $system.OBJ.Export(tClassName,tExportFullPath,"/display=none")
				If $$$ISERR(tSC) Quit
			}
			Else {
				// DTB498 - Add the browser export
				Set tTempName = ..GetTempFileName(tExportFullPath)
				Set tSC = $system.OBJ.Export(tClassName,tTempName,"/display=none")
				Do ..DownloadStream(tTempName,tExportName)
			}

			If $$$defClassDefined(tClassDefName) {
			    Set tSC = $$Delete^%apiOBJ(tClassDefName,"-d")
			    If $$$ISERR(tSC) Quit
			}
			// - WAL248
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $$$FormatText($$$Text("Error exporting item '%1'."),$G(tName)) _ $C(10) _ $System.Status.GetOneErrorText(tSC)
		If ($G(tClassDefName)'="")&&$$$defClassDefined(tClassDefName) {		// DTB533
			// DTB514 - Clean up the temp class in the error case so export works next time.
		    Set tSC = $$Delete^%apiOBJ(tClassDefName,"-d")
		    If $$$ISERR(tSC) Quit
		}
	}
	Else {
		Set tMsg = $$$FormatText($$$Text("%1 item(s) exported."),tCount)
	}
	Quit tMsg
}

/// Import the current selected file list.
Method ImportItems() As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Try {
		// remember directory
		Set ^DeepSee.UserPortalSettings("ExportDirectory") = ..directory
		Set tDir = ##class(%File).NormalizeDirectory(..directory)

		Kill tItemsLoaded
		Set tCount = 0
		For n = 1:1:..selectedFiles.Count() {
			Set tName = ..selectedFiles.GetAt(n)
			Set tFile = tDir_tName
			
			// + WAL248 -- attempt to import as if it were a container class or studio export first
			Set tCacheExport = $system.OBJ.Load(tFile,"c/display=none")
			If $$$ISOK(tCacheExport) {
				Set tItemsLoaded($I(tItemsLoaded)) = tName
			}
			Else {
				Set tSC = ##class(%DeepSee.UserLibrary.Utils).%Import(tFile,1,0,,,.tItemsLoaded)
				If $$$ISERR(tSC) Quit
			}
			// - WAL248
		}
		If $$$ISERR(tSC) Quit

		Set tList = ""
		Set k = $O(tItemsLoaded(""))
		While (k'="") {
			Set tCount = tCount + 1
			Set tList = tList _ $C(10) _ " - " _ tItemsLoaded(k)
			Set k = $O(tItemsLoaded(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Else {
		Set tMsg = $$$FormatText($$$Text("%1 item(s) imported."),tCount)
		Set tMsg = tMsg _ tList
	}
	Quit tMsg
}

/// Delete the current selected list.
Method DeleteItems() As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Try {
		Set tCount = 0
		For n = 1:1:..selectedItems.Count() {
			Set tName = ..selectedItems.GetAt(n)
			If (tName[".") {
				// skip folders
				Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderItem(tName,.tDCount)
				If $$$ISERR(tSC) Quit
				Set tCount = tCount + tDCount
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Else {
		Set tMsg = $$$FormatText($$$Text("%1 item(s) deleted."),tCount)
	}
	Quit tMsg
}

/// Change in search box value. Overridden by subclasses.
ClientMethod searchBoxHandler(searchKey) [ Language = javascript ]
{
	this.searchKey = searchKey;
	zen('foldersList').refreshContents();
}

/// Select all files in export directory.
ClientMethod selectAllFiles() [ Language = javascript ]
{
	var cball = self.document.getElementById('xcb_all');
	for (var n = 1;;n++) {
		var cb = self.document.getElementById('xcb_' + n);
		if (!cb) break;
		cb.checked = cball.checked;
	}
}

/// Select a file in the export directory.
ClientMethod selectFile(n, iscb) [ Language = javascript ]
{
	var cball = self.document.getElementById('xcb_all');
	cball.checked = false;
	if (!iscb) {
		var cb = self.document.getElementById('xcb_' + n);
		cb.checked = !cb.checked;
	}
}

/// Update the item details box.
ClientMethod updateDetails() [ Language = javascript ]
{
	try {
		var html = [];
		this.selectedItems = this.getSelectedItems();

		if (this.selectedItems.length == 0) {
			html[html.length] = '<div class="detailLabel">' + $$$Text('Details on selected item') + '</div>';
		}
		else if (this.selectedItems.length > 1) {
			html[html.length] = '<div class="detailLabel">' + $$$FormatText($$$Text('%1 items selected'),this.selectedItems.length) + '</div>';
		}
		else {
			var name = this.selectedItems[0];
			html[html.length] = '<div class="detailLabel">' + $$$Text('Name') + '</div>';

			var info = this.GetItemDetails(name);
			if (info){
				html[html.length] = '<div class="detailValue">' + zenEscapeXML(info.translatedName) + '</div>';
			}
			else{
				html[html.length] = '<div class="detailValue">' + zenEscapeXML(name) + '</div>';
			}
			if (info) {
				if (info.owner && '' !== info.owner) {
					html[html.length] = '<div class="detailLabel">' + $$$Text('Owner') + '</div>';
					html[html.length] = '<div class="detailValue">' + zenEscapeXML(info.owner) + '</div>';
				}

				if (info.isFolder) {
					// let user edit/save resource for folder
					var style = '';
					var resourceArray = zenPage.resourceList.split(',');		// DTB264 - Create an array for making a resource select
					
					if (info.origin!=name) {
						style = 'color: blue;'
					}
					html[html.length] = '<div class="detailLabel">' + $$$Text('Resource') + '</div>';
					// +DTB264 - Change to <select> input with <options>
					html[html.length] = '<div class="detailValue" title="'+zenEscapeXML(info.origin)+'"><select style="'+style+'" id="folderResource"/>';
					for (r=0 ; r < resourceArray.length ; r++) {
						html[html.length] = '<option value="'+ resourceArray[r].split(':')[0] + '"' + ((resourceArray[r].split(':')[0]==info.resource) ? 'selected' :'') + '>'+ resourceArray[r].split(':')[1] +'</option>';
					}
					html[html.length] = '</select></div>';
					html[html.length] = '<div class="detailValue"><input type="button" class="commandButton" onclick="zenPage.saveFolder(\''+zenEscapeXML(name)+'\');" value="' + $$$Text("Save Folder") + '"/></div>';
					// -DTB264
				}
				else {
					if (info.resource && '' !== info.resource) {
						var style = '';
						if (info.origin!='') {
							style = 'color: blue;'
						}
						html[html.length] = '<div class="detailLabel">' + $$$Text('Resource') + '</div>';
						html[html.length] = '<div class="detailValue" style="'+style+'" title="'+zenEscapeXML(info.origin)+'">' + zenEscapeXML(info.resource) + '</div>';
					}
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

				if (info.dependsOn && '' !== info.dependsOn) {
					html[html.length] = '<div class="detailLabel">' + $$$Text('Depends on') + '</div>';
					html[html.length] = '<div class="detailValue"><ul>' + info.dependsOn + '</ul></div>';
				}

				if (info.usedBy && '' !== info.usedBy) {
					html[html.length] = '<div class="detailLabel">' + $$$Text('Is used by') + '</div>';
					html[html.length] = '<div class="detailValue"><ul>' + info.usedBy + '</ul></div>';
				}
			}
		}

		zen('itemDetails').setContent(html.join(''));
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in updateDetails');
	}
}

/// Get details on selected item.
ClassMethod GetItemDetails(pName As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	Set tInfo = ""
	Set tItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(pName)
	If '$IsObject(tItem) {
		// could be a folder
		Set tFolder = ##class(%DeepSee.UserLibrary.Utils).%FindFolder(pName)
		If $IsObject(tFolder) {
			Set tInfo = ##class(%ZEN.proxyObject).%New()
			Set tInfo.isFolder = 1
			Set tInfo.name = tFolder.name
			Set tInfo.translatedName = ##class(%DeepSee.UserPortal.Utils).%ResolveName(tFolder.name)
			Set tInfo.resource = tFolder.%GetResource(.tOrigin)
			Set tInfo.origin = tOrigin
		}
	}
	Else {
		// folder item
		Set tInfo = ##class(%ZEN.proxyObject).%New()
		Set tInfo.owner = tItem.owner
		Set tInfo.translatedName = ##class(%DeepSee.UserPortal.Utils).%ResolveName(pName)
		Set tInfo.description = ##class(%DeepSee.UserPortal.Utils).%ResolveName(tItem.description)
		Set tInfo.resource = tItem.%GetResource(.tOrigin)
		Set tInfo.origin = tOrigin

		Set tInfo.timeCreated = ##class(%DeepSee.UserPortal.Utils).%FormatDate(tItem.timeCreated,1)
		Set tInfo.timeModified = ##class(%DeepSee.UserPortal.Utils).%FormatDate(tItem.timeModified,1)

		// find dependencies
		Kill tList
		Do ##class(%DeepSee.UserPortal.Utils).%FindDependencies(pName,.tList,0)
		Set tInfo.dependsOn = ""
		Set id = $O(tList(""))
		While (id'="") {
			Set tExt = $P(id,".",$L(id,"."))
			If ($$$UPPER(tExt)="CUBE") {
				Set tName = $P(id,".",1,$L(id,".")-1)
				Set tName = $$$Text("cube ","%DeepSee") _": <b>"_ $ZCVT(tName,"O","HTML") _"</b>"
			}
			ElseIf ($$$UPPER(tExt)="KPI") {
				Set tName = $P(id,".",1,$L(id,".")-1)
				Set tName = $$$Text("kpi ","%DeepSee") _": <b>"_$ZCVT(tName,"O","HTML")_"</b>"
			}
			ElseIf ($$$UPPER(tExt)="WORKSHEET") {
				Set tName = $P(id,".",1,$L(id,".")-1)
				Set tName = $$$Text("worksheet ","%DeepSee") _": <b>"_$ZCVT(tName,"O","HTML")_"</b>"
			}
			ElseIf ($$$UPPER(tExt)="METRIC") {
				Set tName = $P(id,".",1,$L(id,".")-1)
				Set tName = $$$Text("metric ","%DeepSee") _": <b>"_$ZCVT(tName,"O","HTML")_"</b>"
			}
			Else {
				Set tRefItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(id)
				If ('$IsObject(tRefItem)) {
					Set tName = "<span title="""_$$$Text("Cannot find item","%DeepSee")_""" style=""color:red;"">"_$ZCVT(id,"O","HTML")_"</span>"
				}
				Else {
					Set tName = $$$LOWER(tExt)_": <b>"_$ZCVT($P(tRefItem.fullName,".",1,$L(tRefItem.fullName,".")-1),"O","HTML")_"</b>"
				}
			}
			Set tInfo.dependsOn = tInfo.dependsOn _ "<li nowrap=""1"">"_ tName _ "</li>"
			Set id = $O(tList(id))
		}

		// find who uses this
		Kill tList
		Do ##class(%DeepSee.UserPortal.Utils).%FindIsUsedBy(pName,.tList,0)
		Set tInfo.usedBy = ""
		Set id = $O(tList(""))
		While (id'="") {
			If (($E(id)'="$")||($E(id,1,3)="$$$")) { // skip internal items
				Set tExt = $P(id,".",$L(id,"."))
				If ($$$UPPER(tExt)="CUBE") {
					Set tName = $P(id,".",1,$L(id,".")-1)
					Set tName = $$$Text("cube ","%DeepSee")_": <b>" _ $ZCVT(tName,"O","HTML") _"</b>"
				}
				ElseIf ($$$UPPER(tExt)="KPI") {
					Set tName = $P(id,".",1,$L(id,".")-1)
					Set tName = $$$Text("kpi ","%DeepSee") _": <b>"_ $ZCVT(tName,"O","HTML") _"</b>"
				}
				ElseIf ($$$UPPER(tExt)="WORKSHEET") {
					Set tName = $P(id,".",1,$L(id,".")-1)
					Set tName = $$$Text("worksheet ","%DeepSee") _": <b>"_ $ZCVT(tName,"O","HTML") _"</b>"
				}
				ElseIf ($$$UPPER(tExt)="METRIC") {
					Set tName = $P(id,".",1,$L(id,".")-1)
					Set tName = $$$Text("metric ","%DeepSee") _": <b>"_ $ZCVT(tName,"O","HTML") _"</b>"
				}
				Else {
					Set tRefItem = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(id)
					If ('$IsObject(tRefItem)) {
						Set tName = "<span title="""_$$$Text("Cannot find item","%DeepSee")_""" style=""color:red;"">"_$ZCVT(id,"O","HTML")_"</span>"
					}
					Else {
						Set tName = $$$LOWER(tExt)_": <b>"_$ZCVT($P(tRefItem.fullName,".",1,$L(tRefItem.fullName,".")-1),"O","HTML") _"</b>"
					}
				}
				Set tName = ##class(%DeepSee.UserPortal.Utils).%ResolveName(tName)
				Set tInfo.usedBy = tInfo.usedBy _ "<li nowrap=""1"">"_ tName _ "</li>"
			}
			Set id = $O(tList(id))
		}
	}
	Quit tInfo
}

/// Draw contents of export directory.
Method DrawExportDirectory(pSeed As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		&html<<table class="dirTable" border="0" cellspacing="0">>
		&html<
		<tr><td><input type="checkbox" id="xcb_all" onclick="zenPage.selectAllFiles();"/></td>
		<td>
		<div class="detailLabel">
		#($$$Text("Contents of export directory"))#</div></td></tr>>

		Set tRS = ##class(%ResultSet).%New("%File:FileSet")
		Set tSC = tRS.Execute(..directory,"*.xml")
		If $$$ISERR(tSC) Quit
		Set n = 0
		While(tRS.Next()) {
			Set n = n + 1
			Set tName = tRS.Data("ItemName")
			Set tTranslatedName = $S(($E(tName,1,3)="$$$"):$TR(##class(%DeepSee.UserPortal.Utils).%ResolveName($TR(tName,"-","/")),"/","-"), 1:tName) //Assumes that tName only contains "-" as a separator between 2 names and tName does not contain "/"
			Write "<tr><td><input id=""xcb_"_n_""" value="""_$ZCVT(tName,"O","HTML")_""" onclick=""zenPage.selectFile('"_n_"',true);"" type=""checkbox""/></td><td onclick=""zenPage.selectFile('"_n_"',false);"">",$ZCVT(tTranslatedName,"O","HTML"),"</td></tr>",!
		}

		&html<</table>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Save folder details.
ClientMethod saveFolder(name) [ Language = javascript ]
{
	var resource = self.document.getElementById('folderResource').value;
	var msg = this.SaveFolderDetails(name,resource);
	if (msg != '') {
		alert(msg);
	}
	this.updateDetails();
}

/// Save folder information.
ClassMethod SaveFolderDetails(pName As %String, pResource As %String) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = $$$OK
	Set tFolder = ##class(%DeepSee.UserLibrary.Utils).%FindFolder(pName)
	If $IsObject(tFolder) {
		Set tFolder.resource = pResource
		Set tSC = tFolder.%Save()
	}

	If ($$$ISERR(tSC)||'$IsObject(tFolder)) {
		Set tMsg = $$$Text("Unable to save folder","%DeepSee")
	}
	Else {
		Set tMsg = $$$Text("Folder saved","%DeepSee")
	}
	Quit tMsg
}

ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'switchNamespace':
		var homeurl = zenLink("/csp/sys/%25CSP.Portal.Home.zen");
		var url = zenPage.GetNewURL(value,"_DeepSee.UI.FolderManager.zen");
		if (url == "" || value == "%SYS") url = homeurl;
		self.document.location = url;
		break;
	// + WAL225
	case 'fileSelect':
		zen('ctrlDirectory').setValue(value);
		zenPage.setExportDirectory(value);
		break;	
	// - WAL225
	}
}

/// Test for additional resources.
ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	Quit $System.Security.Check("%DeepSee_Admin","USE")||
		 $System.Security.Check("%Development","USE")
}

ClassMethod %GetResourceList(Output pList) As %Status [ Internal ]
{
	// Method added by DTB264. Rewritten by DTB343 to avoid namespace switch.
	Set tSC = $$$OK
	Set tNS = $namespace
	Try {
		Kill pList
		Set pList($I(pList)) = $LB("",$$$Text("No Resource","%DeepSee"))
		
		// Function escalates privileges to query the %SYS database.
		// Returns tResources(Name)=$lb(Description,PublicPermissions,Type,ResourceType).
		Set tSC = $$ResourceList^%SYS.SECURITY("*",-1,-1,.tResources)
		
		Set tResName = $O(tResources(""),1,tResInfo)
		While tResName'="" {
			If ($E(tResName)'="%")&&$system.Security.Check(tResName,"USE") {
				// DTB343 - Only show the user-defined resource options that the current user actually holds.
				Set pList($I(pList)) = $LB(tResName,tResName)
			}
			Set tResName = $O(tResources(tResName),1,tResInfo)
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// User clicked the Browse button.
ClientMethod browseSelect() [ Language = javascript ]
{
	// Added by WAL225
	var wildcard = "*";
	var Dir = zen('ctrlDirectory').getValue();
	var showdirectoryonly = 1;
	zenLaunchPopupWindow('%ZEN.Dialog.fileSelect.zen?Dir='+encodeURIComponent(Dir)+'&wildcard='+wildcard+'&showdirectoryonly='+showdirectoryonly,'fileSelect','resizable,width=600,height=700');
}

/// User changed to export file between Server or Browser
ClientMethod doLocationChange(flag) [ Language = javascript ]
{
	// Method added by DTB498
	if (flag == 'BROWSER') {
		var name = zen('ctrlDirectory').getValue();
		var pos = name.lastIndexOf('\\');
		if (pos == -1) pos=0;
		
		zen('ctrlUseContainerClass').setValue(true);
		zenPage.toggleContainer(true);		// DTB514
		zen('ctrlUseContainerClass').setDisabled(true);
		zen('ctrlDirectory').setHidden(true);
		
		// Directory tab
		zen('svrExportDirectory').setHidden(true);
		zen('fileUpload').setHidden(false);		// DTB540
		zen('btnBrowse').setHidden(true);		// DTB540 - Export and import directory selections will browse for us
	} else {
		var Directory = zen('ctrlDirectory');
		var pathName = Directory.getValue();
		var pos = pathName.lastIndexOf('\\');
		if (pos == -1) pos=0;
		var docName = zen('ctrlContainerClassName').getValue();
		Directory.setValue(pathName.substring(0,pos+1)+docName);

		zen('ctrlUseContainerClass').setDisabled(false);
		zen('ctrlDirectory').setHidden(false);
		
		// Directory tab
		zen('svrExportDirectory').setHidden(false);
		zen('fileUpload').setHidden(true);		// DTB540
		zen('btnBrowse').setHidden(false);		// DTB540
	}
	
	zenPage.adjustSizes();		// DTB540 - Adjuust the heights of the tabs given the new form contents
}

/// Create a temporary file name with the same extension
/// as the current <var>pDocName</var>.
Method GetTempFileName(pDocName) As %String [ ZenMethod ]
{
	// Method added by DTB498
	Set ext = $P(pDocName,".",*)
	Set:(ext="") ext = "tmp"
	Quit ##class(%Library.File).TempFilename(ext)
}

/// Stream a temporary file located on the server at <var>pFileName</var>
/// and serve it to the current client <class>%CSP.StreamServer</class>.
ClassMethod DownloadStream(pFilename As %String, pDocName As %String, pCharSet As %String = "") [ ZenMethod ]
{
	// Method added by DTB498
	Set tStream = ##class(%FileBinaryStream).%New()
	Set tSC = tStream.LinkToFile(pFilename)
	Do tStream.SetAttribute("ContentDisposition","attachment; filename="_pDocName)
	Do tStream.SetAttribute("CharSet",pCharSet)
	Set tSC = tStream.%Save()
	Set Oid = tStream.%Oid()
	
	Do tStream.Rewind()
	&js<window.location="#url(%25CSP.StreamServer.cls?STREAMOID=#(..Encrypt(Oid))#)#";>
}

/// Test if the given class name is valid.
ClassMethod IsValidClassName(pClassName As %String) As %Boolean [ ZenMethod ]
{
	// Method added by DTB498
	Quit $S(pClassName'[".":0,1:$zname(pClassName,4))
}

/// Provides a compact means of switching to the file upload form
ClientMethod shortcutToFileUpload() [ Language = javascript ]
{
	// Method added by DTB540
	zen('ExportTo').setValue('BROWSER');
	zenPage.doLocationChange('BROWSER');
	zenPage.getComponentById('tabGrp').showTab(2);
}

/// Link to the stream of the file upload control and treanfer the stream contents to the server
ClassMethod SaveFileImportToDisk(pSubmit As %ZEN.Submit) As %Status
{
	// Method added by DTB540
	Try {
	    Set UploadData = pSubmit.%GetStream("fileUploadCtrl") 
	    Set NewFile = ##class(%FileBinaryStream).%New()
	    
	    Set tDir = ##class(%SYS.System).TempDirectory()
	    Set tLocation = ##class(%File).NormalizeFilename("UploadTestFile"_$zcrc($H,7)_".xml",tDir)

	    Set NewFile.Filename = tLocation
	    Set tSC = NewFile.CopyFrom(UploadData)
	    If $$$ISERR(tSC) Quit
	    Set tSC = NewFile.%Save()
	    If $$$ISERR(tSC) Quit
	    
	    Set tSC = $system.OBJ.Load(tLocation,"/display=none",.tErrorLog,.tLoadedList)
	    
	    // Look at the loaded contents. 
	    // DTB540 - Currently only *.DFI and subclasses of %DeepSee.UserLibrary.Container classes are permitted
	    Set tImportErrors = ""
	    Set tImportList = ""
	    Set tClassName = $O(tLoadedList(""))
	    While tClassName'="" {
		    Set tCompile = 0
		    Set tClassNameNoExt = $P(tClassName,".",1,*-1)
		    If $$$UPPER($P(tClassName,".",*))="DFI" {
			    // DFI files are allowed and require no compile, add to the success list and move on
			    Set tImportList = tImportList _ "IMPORT SUCCESS - " _ tClassName _ ";"
			    Set tCompile = 0
		    }
		    ElseIf (##class(%Dictionary.ClassDefinition).%ExistsId(tClassNameNoExt)&&
		       (##class(%Dictionary.ClassDefinition).%OpenId(tClassNameNoExt).Super["%DeepSee.UserLibrary.Container")) {
			    // Container class, mark for compile and move on
			    Set tCompile = 1
		    }
		    Else {
			    // Not supported for this import, add to the import error list
			    Set tImportErrors = tImportErrors _ "IMPORT ERROR - Cannot import content type: " _ tClassName _ "; "
		    }

			If tCompile {
		    	Set tCompileSC = $system.OBJ.Compile(tClassNameNoExt,"/display=none")
		    	If $$$ISERR(tCompileSC) {
			    	 Set tImportErrors = tImportErrors _ "COMPILE ERROR - " _ $system.Status.GetErrorText(tCompileSC) _ "; "
		    	}
		    	Else {
			    	// Process container to engage the %OnLoad callback if it exists
			    	Set tProcessingSC = ##class(%DeepSee.UserLibrary.Utils).%ProcessContainer(tClassNameNoExt,0,0,1)
			    	//Set tProcessingSC = 1
			    	If $$$ISERR(tProcessingSC) {
				    	Set tImportErrors = tImportErrors _ "PROCESSING ERROR - " _ $system.Status.GetErrorText(tProcessingSC) _ "; "
			    	}
		    	}
		    	
		    	// Report back all classes that succcessfully loaded
		  		If $$$ISOK($G(tCompileSC))&&$$$ISOK($G(tProcessingSC)) {
		    		Set tImportList = tImportList _ "IMPORT SUCCESS - " _ tClassName _ "; "
		  		}
			}
		    Set tClassName = $O(tLoadedList(tClassName))
	    }

	    If (tImportErrors'="") {
		    // This will be checked by the page on reload to see if there were any problems with the reload
	    	Do pSubmit.%SetError("fileUploadCtrl",tImportErrors)
	    }
	    
		// The primary form error contianer will contain a status message. Either
		Do pSubmit.%SetError("fileUploadForm",$S(tImportList'="":tImportList,pSubmit.%HasErrors():"There are errors in the client import.",1:""))
		
		// Clean up the temp file from the mgr/Temp directory
		If ##class(%Library.File).Exists(tLocation) {
			Set tSC = ##class(%Library.File).Delete(tLocation)
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
 
    Quit tSC
}

ClassMethod %OnSubmit(pSubmit As %ZEN.Submit) As %Status
{
	// Method added by DTB540
    Set tSC = ..SaveFileImportToDisk(pSubmit) 
    Quit tSC
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// Method added by DTB540
	this.invokeSuper('onloadHandler',arguments);		// DTB845
	
	zenPage.checkUploadInformation();
}

/// Check the error status of the fileUploadForm and the fileUploadCtrl. If present, alert the user to this information
ClientMethod checkUploadInformation() [ Language = javascript ]
{
	// Method added by DTB540
	var form = zen('fileUploadForm');
	var uploadControl = zen('fileUploadCtrl');
	if (form.error||uploadControl.error) {
		zenPage.shortcutToFileUpload();
	}
}

}
