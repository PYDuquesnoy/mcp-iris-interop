/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This page lets users enter MDX queries and view the results 
/// via a pivot table.
/// 
Class %DeepSee.UI.MDXQuery Extends %DeepSee.UI.standardPage [ System = 4 ]
{

Parameter PAGENAME = "MDX Query Tool";

Parameter DOCBOOKID = "D2GS_uis_query_tool";

Parameter RESOURCE = "%DeepSee_Admin,%Development";

/// Allow customization of number of rows.
Property rows As %ZEN.Datatype.string(ZENURL = "ROWS") [ InitialExpression = 8 ];

/// Name of initial subjectArea to query.
/// This is the full name of a subject area.
Property subjectArea As %ZEN.Datatype.string(ZENURL = "SUBJECTAREA");

XData Style
{
<style type="text/css">

#table {
	border: 1px #808080 solid;
	background: #C0C0C0;
	width: 1100px;
	height: 550px;
	overflow: hidden;
}

#mdx textarea {
	font-size: 16pt;
	width: 100%;
}

.iPivotTable {
	font-size: 1.2em;
}

select {
	font-size: 12px;
	color: #404040;
	width: 250px;
}

.iPivotDataTable {
	font-size: 1.2em;
}

.zenLabel {
	color: rgb(67,67,67);
	font-size: 10pt;
}

.zenHint {
	color: rgb(67,67,67);
	font-size: 8pt;
}

.dynaTreeNode {
	white-space: nowrap;
	font-size: 10pt;
}

.dynaTreeItem {
	color: rgb(71,72,67);
}


#groupTree {
	width: 250px;
	overflow-y: auto;
	overflow-x: auto;
	border: 1px solid black;
	background: white;
}

#dimTree {
	overflow: hidden;
}

#funcTree {
	width: 250px;
	overflow: hidden;
}

.hdrLink {
	font-size: 10pt;
	font-weight: normal;
	color: darkblue;
	text-decoration: none;
	padding-left: 6px;
	padding-right: 6px;
}

.hdrLinkDisabled {
	font-size: 10pt;
	font-weight: normal;
	color: gray;
	text-decoration: none;
	padding-left: 6px;
	padding-right: 6px;
}

.hdrLink:hover {
	color: orange;
}

</style>
}

/// This XML defines the contents of the contents pane for this page.
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" 
	xmlns:deepsee="http://www.intersystems.com/deepsee"
	import="%DeepSee.Component.pivotLevel" 
>
<hgroup cellVAlign="top">
<spacer width="10"/>
<vgroup>
<hgroup cellVAlign="top" labelPosition="left">
<select label="" id="treeSelect" valueList="mbrs,funcs" displayList="Cube Members,MDX Functions" onchange="zenPage.setTreeMode(zenThis.value);" showEmpty="false" value="mbrs"/>
</hgroup>
<vgroup id="groupTree">
<dynaTree id="dimTree" 
 imageContracted="portal/disc_up_16.gif"
imageExpanded="portal/disc_down_16.gif"
imageNode="deepsee/ds2_brightness_44.png"
	showLines="false" showFolders="false" dragEnabled="true" 
	OnGetTreeInfo="GetDimensionInfo">
<parameter id="pcubed" paramName="subjectArea" value="#(%page.subjectArea)#" />
</dynaTree>

<dynaTree id="funcTree" 
 imageContracted="images/arrow1R.gif"
 imageExpanded="images/arrow1D.gif"
 imageNode=""
	showLines="false" showFolders="false" dragEnabled="true" 
	OnGetTreeInfo="GetFunctionInfo">
</dynaTree>

</vgroup>
</vgroup>
<spacer width="10"/>
<vgroup>
<textarea id="mdx" label="MDX statement" 
	 dropEnabled="true"
	 ondrop="return zenPage.mdxDrop(zenThis,dragData);"
	rows="8" onfocus="zenPage.updateTextStyle();"/>
<hgroup id="buttonGroup">
<button controlClass="commandButton" caption="Execute" title="Execute the current query" onclick="zenPage.execute();"/>
<spacer width="10"/>
<button controlClass="commandButton" caption="Show Plan" title="Show execution plan for the current query" onclick="zenPage.showPlan();"/>
<spacer width="10"/>
<button controlClass="commandButton" caption="Export to Excel" title="Export the current query to Excel" onclick="zenPage.exportExcel();"/>
</hgroup>
<spacer height="5"/>
<deepsee:pivotTable	id="table" dataSource="manual"/>
</vgroup>
</hgroup>
</pane>
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If (..subjectArea="") {
		Quit $$$Text("Query Tool")
	}
	Quit $P(..subjectArea,".",1,$L(..subjectArea,".")-1)
}

/// Get the product name for the page.
Method %OnGetProductName() As %String
{
	Quit "DeepSee"
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("MDX Query Tool","%DeepSee")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Query Tool")

	// commands
	// $LB(id,caption,help,onclick)
	//Set pCommands(1) = $LB("cmdOpen",$$$Text("Open"),$$$Text("Load a previously saved query"),"alert('Please Save first!');")
	//Set pCommands(2) = $LB("cmdSave",$$$Text("Save"),$$$Text("Save this query"),"alert('Under construction as part of the American Stimulus and Recovery Act!');")
	Quit $$$OK
}

/// Draw additional stuff in the ribbon bar
Method OnDrawRibbon() As %Status
{
	Set msgChange = $$$Text("Change Subject Area")
	Set hlpChange = $$$Text("Change to a different Subject Area")

	&html<<td nowrap="1" width="20%">>
	&html<&nbsp;&nbsp;<a class="hdrLink" href="#" title="#(hlpChange)#" onclick="zenPage.changeSubjectArea();return false;">#(msgChange)#</a>>
	&html<</td>>
	Quit $$$OK
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,$ZCVT($className(),"O","URL")_".zen?SUBJECTAREA="_$ZCVT(..subjectArea,"O","URL"))	
	Quit $$$OK
}

/// Launch the subject area finder dialog.
ClientMethod changeSubjectArea() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.cls?MODE=subjectAreas','SubjectArea','status,scrollbars,resizable=yes,width=800,height=600');
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'SubjectArea':
		if (value != this.subjectArea) {
			self.document.location = zenLink('_DeepSee.UI.MDXQuery.zen?SUBJECTAREA=' + encodeURIComponent(value));
		}
		break;
	case 'switchNamespace':
		var homeurl = zenLink("/csp/sys/%25CSP.Portal.Home.zen");
		var url = zenPage.GetNewURL(value,"_DeepSee.UI.MDXQuery.zen");
		if (url == "" || value == "%SYS") url = homeurl;
		self.document.location = url;
		break;
	}
}

/// Update style of text area.
ClientMethod updateTextStyle() [ Language = javascript ]
{
	var mdx = zen('mdx');
	if (mdx.aux=='msg') {
		mdx.aux = '';
		zen('mdx').setValue('');
		zen('mdx').setProperty('controlStyle','');
	}
	else {
	}
}

/// Execute query
ClientMethod execute() [ Language = javascript ]
{
	var mdx = zen('mdx').getValue();
	mdx = zenTrim(mdx);
	var table = zen('table');
	if (mdx=='') {
		mdx = ' ';
	}
	// JMD1057
	table.userMDX = mdx;
	// DTB781 -  Manually set the drillthrough to correct paging behavior
	table.isDrillThrough = ((mdx.toUpperCase().indexOf('DRILLTHROUGH')>-1) || (mdx.toUpperCase().indexOf('DRILLFACTS')>-1));
	table.pivot = false;
	table.showPlan = false;
	table.cubeName = '';
	table.queryKey = '';
	// PFS015 - Execute queries with force=true from Query Tool
	table.executeQuery(true);
}

/// Show plan for query.
ClientMethod showPlan() [ Language = javascript ]
{
	var mdx = zen('mdx').getValue();
	mdx = zenTrim(mdx);
	if (mdx=='') {
		mdx = ' ';
	}
	var table = zen('table');
	// JMD1057
	table.userMDX = mdx;
	table.pivot = false;
	table.showPlan = true;
	table.cubeName = '';
	table.queryKey = '';
	table.executeQuery();
}

/// reset
ClientMethod refreshTable() [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	table.executeQuery();
}

/// pivot
ClientMethod pivot() [ Language = javascript ]
{
	var table = zenPage.getComponentById('table');
	table.pivotTable();
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	Set tTable = ..%GetComponentById("table")
	Set tMDX = ..%GetComponentById("mdx")
    Set tMDX = ..%GetComponentById("mdx")

	#; variable input box size
    Set:(+..rows>0) tMDX.rows = ..rows 

	// JMD1057: use userMDX
    If (..subjectArea'="") {
		Set tCubeName = $P(..subjectArea,".",1,$L(..subjectArea,".")-1)
		Set tTable.userMDX = "SELECT FROM [" _ tCubeName _ "]"
		Set tMDX.value = tTable.userMDX
		Set tMDX.aux = ""
	}
	Else {
		Set tMDX.value = $$$Text("Enter MDX query here")
		Set tMDX.controlStyle = "color: #808080;"
		Set tTable.userMDX = " " // force empty query
		Set tMDX.aux = "msg"
	}
	Quit $$$OK
}

/// Provide contents of the dimension tree.
ClassMethod GetDimensionInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCube = ""
		Set tSubjectArea = $G(pParms("subjectArea"))
		If (tSubjectArea'="") {
			Set tCube = $P(tSubjectArea,".",1,$L(tSubjectArea,".")-1)
		}
		Set tPivotName = $G(pParms("pivot"))

		If (tCube'="") {
			If (tPivotName'="") {
				Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tPivotName,.tSC)
				If $$$ISERR(tSC) Quit
				If $IsObject(tPivot) {
					// get local calc members
					For n = 1:1:tPivot.calculatedMembers.Count() {
						Set tCalcMbr = tPivot.calculatedMembers.GetAt(n)
						If ((tCalcMbr.dimension'="")&&(tCalcMbr.memberName'="")) {
							Set tCalcMbrs($$$UPPER(tCalcMbr.dimension),$$$UPPER(tCalcMbr.memberName)) = $LB(tCalcMbr.dimension,tCalcMbr.memberName)
						}
					}

					// get local named sets
				}
			}

			Set tSC = ##class(%DeepSee.Utils).%GetMemberTree(tCube,.pTree,,,pRoot,.tCalcMbrs,.tNamedSets)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Provide contents of the function tree.
ClassMethod GetFunctionInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Set tSC = ##class(%DeepSee.Utils).%GetFunctionList(.pTree,1)
	Quit tSC
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		if (load) {
			// JMD971: disable firefox spellcheck
			var textArea = zen('mdx').findElement('control');
			textArea.setAttribute('spellCheck',false);
		}

		this.adjustSizes();
		this.setTreeMode('mbrs');
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var tree = zen('groupTree');
		var divTree = tree.getEnclosingDiv();

		var table = zen('table');
		var divTable = table.getEnclosingDiv();

		var ctrl = zen('mdx');
		var divCtrl = ctrl.getEnclosingDiv();

		var btns = zen('buttonGroup');
		var divBtns = btns.getEnclosingDiv();

		var select = zen('treeSelect');
		var divSelect = select.getEnclosingDiv();

		// show tree
		divTree.style.display = '';

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		var th = this.getTitleAreaHeight();

		var w1 = winWidth - (50 + divTree.offsetWidth);
		divCtrl.style.width = (w1>0?w1:0) + 'px';

		var pivotWid = 0;
		var h = winHeight - th;

		divTable.style.display = '';
		pivotWid = winWidth - (50 + divTree.offsetWidth);
		divTable.style.width = (pivotWid>0?pivotWid:0) + 'px';
		var h1 = (h - 50 - divCtrl.offsetHeight - divBtns.offsetHeight);
		divTable.style.height = (h1>0?h1:0) + 'px';
		var h2 = (h - divSelect.offsetHeight - 27);
		divTree.style.height = (h2>0?h2:0) + 'px';
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// User has dropped an item on the textarea.
ClientMethod mdxDrop(textarea, dragData) [ Language = javascript ]
{
	// append drop to query
	var mdx = textarea.getValue();
	mdx = mdx + ' ' + dragData.value;
	textarea.setValue(mdx);
	return false;
}

/// Change which tree is displayed.
ClientMethod setTreeMode(mode) [ Language = javascript ]
{
	switch(mode) {
	case 'mbrs':
		zen('dimTree').setHidden(false);
		zen('funcTree').setHidden(true);
		break;
	case 'funcs':
		zen('dimTree').setHidden(true);
		zen('funcTree').setHidden(false);
		break;
	}
}

/// Export current query to excel
ClientMethod exportExcel() [ Language = javascript ]
{
	// make sure query has been run
	zenPage.execute();

	var table = zenPage.getComponentById('table');
	var mdx = table.GetCurrentQueryText();
	var nonce = '';

	if (mdx.toString().length > 1000) {
		// avoid long urls for IE!
		nonce = this.CreateQueryNonce(mdx);
		if (nonce.toString().indexOf('ERROR:')>=0) {
			// error
			alert(nonce);
			return;
		}
	}
	if (nonce) {
		var url = '_DeepSee.UI.MDXExcel.zen?NONCE=' + encodeURIComponent(nonce);
	}
	else {
		var url = '_DeepSee.UI.MDXExcel.zen?MDX=' + encodeURIComponent(mdx);
	}
	window.open(url,'excel','');
}

/// Generate a nonce for an MDX query.
ClassMethod CreateQueryNonce(pQuery As %String) As %String [ Internal, ZenMethod ]
{
	Quit ##class(%DeepSee.Utils).%CreateQueryNonce(pQuery)
}

/// Test for additional resources.
ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	// DTB287 - Redirect to the error page if privileges are not met
	Set tUse = $System.Security.Check("%DeepSee_Admin","USE")||
		 		$System.Security.Check("%Development","USE")
	
	If 'tUse {
		Set %response.Redirect = ##class(%DeepSee.Utils).%GetErrorPageURL("Privilege")
	}
	
	Quit tUse
}

}
