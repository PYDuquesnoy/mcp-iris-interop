/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// DeepSee Analyzer page.
/// 
Class %DeepSee.UI.Analyzer Extends %DeepSee.UI.standardPage [ System = 4 ]
{

Parameter RESOURCE = "%DeepSee_Analyzer,%DeepSee_AnalyzerEdit";

Parameter PAGENAME = "Analyzer";

/// If this page has multiple views, this is its initial display mode.
Parameter DEFAULTVIEWMODE = "pivot";

/// If true, we are launched from the USER portal.
Parameter USERMODE As BOOL = 0;

/// URL for Analyzer.
Parameter ANALYZERURL As STRING = "_DeepSee.UI.Analyzer.zen";

Parameter DOCBOOKID = "D2ANLY_ch_intro";

/// Token to load unsaved pivot state.
Property autosave As %ZEN.Datatype.string(ZENURL = "AUTOSAVE");

/// Token to load unsaved pivot state.
Property autosaveOverride As %ZEN.Datatype.string(ZENURL = "AUTOSAVEOVERRIDE");

/// Token to load unsaved pivot state.
Property lastLeftWidth As %ZEN.Datatype.integer [ InitialExpression = 300 ];

/// Name of Cube (with extension).
Property cubeFullName As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Name of cube to explore.
Property cubeName As %ZEN.Datatype.string;

/// If true, user cannot modify the current pivot.
Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, user can modify (non-read-only) pivots.
Property canWrite As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Name of saved pivotTable to view (overrides CUBE if present).
Property pivotName As %ZEN.Datatype.string(ZENURL = "PIVOT");

/// Description of the saved pivot (if any).
Property pivotDescription As %ZEN.Datatype.string;

/// Resource of the saved pivot (if any).
Property pivotResource As %ZEN.Datatype.string;

/// Owner of the saved pivot (if any).
Property pivotOwner As %ZEN.Datatype.string;

/// Locked state of the saved pivot.
Property pivotLocked As %ZEN.Datatype.boolean;

/// Public state of the saved pivot.
Property pivotPublic As %ZEN.Datatype.boolean;

/// Keywords of the saved pivot (if any).
Property pivotKeywords As %ZEN.Datatype.string;

/// Category of the saved pivot.
Property pivotCategory As %ZEN.Datatype.string;

/// URL for Analyzer.
Property analyzerURL As %ZEN.Datatype.string [ InitialExpression = {..#ANALYZERURL} ];

/// If true, send e-mail using client-side mailto application.
Property useClientEmail As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, show one chart for each data series.
Property multiChart As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, use the new analysis dialog.
Property hasAnalysis As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, show the print/pdf option.
Property hasPDF As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Current CSP session.
Property sessionCookie As %ZEN.Datatype.string;

/// Initial value of autoexec setting for pivot table.
Property autoExec As %ZEN.Datatype.boolean(ZENURL = "EXEC") [ InitialExpression = 1 ];

/// Initial value of previewMode setting for the Analyzer.
Property previewMode As %ZEN.Datatype.boolean(ZENURL = "PREVIEW") [ InitialExpression = 0 ];

/// List of names for any actions for the current cube.
Property actionNames As list Of %ZEN.Datatype.string;

/// List of captions for any actions for the current cube.
Property actionCaptions As list Of %ZEN.Datatype.string;

/// Convenience property. Setting this true is equivalent to 
/// NOTITLE=1
Property isEmbedded As %ZEN.Datatype.boolean(ZENURL = "EMBED");

/// If true, then do not display the title area of this page.
Property noTitle As %ZEN.Datatype.boolean(ZENURL = "NOTITLE");

/// If true, show the dimensions tree.
Property showDimensions As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Location of the autosave items
Property tempStorageRoot As %ZEN.Datatype.string [ InitialExpression = "$Temp/Analyzer/" ];

/// What to show in the dimensions tree.
Property treeMode As %ZEN.Datatype.string;

/// Chart series color scheme.
Property chartSeriesScheme As %ZEN.Datatype.string;

/// Chart series color list.
Property chartSeriesColors As %ZEN.Datatype.string;

/// Flag to indicate whether or not the cube can use the special %SQLRESTRICT dimension.
Property cubeSupportsSqlRestrict As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Flag to indicate whether to warn user of unsaved changes on page unload
Property warnUser As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

XData Style
{
<style type="text/css">
body {
	visibility: hidden;
	/* do not show scroll bars for ie */
	overflow: hidden;
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

#mainHGroup {
}

#table {
	border: 1px #808080 solid;
	background: #E0E0E0;
	width: 1100px;
	height: 550px;
	overflow: hidden;
}

#filterGroup {
	background: #C0C0C0;
	background-image: url(images/grad-halfgray-10x30.png);
	background-repeat: repeat-x;
	border: 1px solid gray;
	overflow: hidden;
	overflow-x: auto;
	padding: 0px;
	color: #404040;
	vertical-align: middle;
	height: 42px;
}

#filterGroup .zenLabel {
	font-size: 10px;
	font-weight: bold;
	color: #808080;
}

.iPivotTable {
	font-size: 1.2em;
}

select {
	font-size: 0.9em;
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

.dynaTreeExp {
	opacity: 0.75;
}

.dynaTreeExp:hover {
	opacity: 1.0;
}

.dynaTreeExp:active {
	background: #FFEEAA;
	box-shadow: 0px 0px 20px #FFEEAA, -0px -0px 20px #FFEEAA;
}

.dynaTreeIcon {
	height: 14px;
	opacity: 0.75;
}

.dynaTreeNode {
	white-space: nowrap;
	font-size: 14px;
	padding: 2px;
}

a.dynaTreeItem {
	color: rgb(71,72,67);
}

.treeSelect {
	border: 1px solid #808080;
	color: #606060;
	font-weight: bold;
	font-size: 14px;
	background: #C0C0C0;

}

.treeSelect option {
	background-color: #FFFFFF;
}

.treeSelect option:nth-of-type(odd) {
	background-color: #F8F8F8;
}


#groupTree {
	width: 275px;
	overflow: hidden;
	border-left: 1px solid #D0D0D0;
	border-right: 1px solid #D0D0D0;
	border-bottom: 1px solid #D0D0D0;
	background: white;
}

#treeWrapper {
	overflow-y: hidden;
	overflow-x: hidden;
}

#treeWrapper:hover {
	overflow-y: auto;
	overflow-x: auto;
}

#dimTree {
	overflow: hidden;
	display: none;
}

#cubeName {
	color: #404040;
	background: #C0C0C0;
	border: none;
	border-bottom: 1px solid gray;
	width: 100%;
	overflow: hidden;
}

#cubeNameDiv, #cubeModeDiv {
	border-top: 1px solid #C0C0C0;
	font-size: 10pt;
	font-weight: bold;
	color: #404040;
	padding: 3px;
	overflow:hidden;
	white-space: nowrap;
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
	import="%DeepSee.Component.pivotLevel,%DeepSee.Component.searchBox,%DeepSee.Component.dsdynaTree" 
>
<!-->WAL179 split is now not a percentage to make left width fixed<-->
<deepsee:deepseeSvgImageProvider id="svgUtil"/>
<deepsee:deepseeCSVProvider id="csvUtil"/>
<timer id="autosaveTimer" ontimeout="zenPage.runAutosave();" timeout="2000"/>
<activeHGroup id="mainHGroup" split="300" handleThickness="4" onresizeLeft="zenPage.adjustSizes()" >
<vgroup id="groupTree" width="100%">
<html id="cubeName" OnDrawContent="DrawCubeName"/>
<vgroup id="treeWrapper">
<deepsee:dsdynaTree id="dimTree" 
imageContracted="portal/disc_up_16.gif"
imageExpanded="portal/disc_down_16.gif"
imageNode="deepsee/ds2_brightness_44.png"
onchange="zenPage.treeChange(zenThis);"
ondblclick="zenPage.treeDoubleClick(zenThis);"
showLines="false" showFolders="false" dragEnabled="true" 
OnGetTreeInfo="GetDimensionInfo">
<parameter id="pcubed" paramName="cube" value="#(%page.cubeName)#" />
<parameter id="ppivotd" paramName="pivot" value="#(%page.pivotName)#" />
</deepsee:dsdynaTree>

<deepsee:dsdynaTree id="dimTreePivot"
imageContracted="portal/disc_up_16.gif"
imageExpanded="portal/disc_down_16.gif"
imageNode="deepsee/deepsee/ds2_layers2_44.png"
onchange="zenPage.pivotTreeChange(zenThis);"
ondblclick="zenPage.pivotTreeDoubleClick(zenThis);"
showLines="false" showFolders="false" dragEnabled="false" 
OnGetTreeInfo="GetPivotInfo">
<parameter id="pcubedPivot" paramName="cube" value="#(%page.cubeName)#" />
<parameter id="ppivotdPivot" paramName="pivot" value="#(%page.pivotName)#" />
</deepsee:dsdynaTree>

<deepsee:dsdynaTree id="dimTreeQMSR"
imageContracted="portal/disc_up_16.gif"
imageExpanded="portal/disc_down_16.gif"
imageNode="deepsee/ds2_brightness_44.png"
onchange="zenPage.treeChange(zenThis);"
ondblclick="zenPage.treeDoubleClick(zenThis);"
showLines="false" showFolders="false" dragEnabled="true" 
OnGetTreeInfo="GetQMSRInfo">
<parameter id="pcubedQMSR" paramName="cube" value="#(%page.cubeName)#" />
<parameter id="ppivotdQMSR" paramName="pivot" value="#(%page.pivotName)#" />
</deepsee:dsdynaTree>

<deepsee:dsdynaTree id="dimTreeListingFields"
imageContracted="portal/disc_up_16.gif"
imageExpanded="portal/disc_down_16.gif"
imageNode="deepsee/ds2_brightness_44.png"
onchange="zenPage.treeChange(zenThis);"
ondblclick="zenPage.treeDoubleClick(zenThis);"
showLines="false" showFolders="false" dragEnabled="true" 
OnGetTreeInfo="GetListingFieldsInfo">
<parameter id="pcubedListingFields" paramName="cube" value="#(%page.cubeName)#" />
<parameter id="ppivotdListingFields" paramName="pivot" value="#(%page.pivotName)#" />
<parameter id="plistingdListingFields" paramName="listing"  />
</deepsee:dsdynaTree>

</vgroup>

</vgroup>


<vgroup id="groupPivot">
<deepsee:pivotController id="pivotController" pivotTableId="table" dropEnabled="true" dragEnabled="true"/>

<!--
filterGroup contains filter controls displayed above the pivot table
the controls are created in %OnAfterCreatePage (by calling %CreateFilterControls)
-->

<hgroup id="filterGroup" cellVAlign="top"
 ondrop="zenPage.dropOnFilterGroup(dragData);"
  dropEnabled="true"
	cellStyle="padding:2px;padding-right:4px;padding-top:0px;" labelPosition="top"></hgroup>
<hgroup cellVAlign="top">
<deepsee:pivotTable
	id="table"
	cubeName="#(%page.cubeName)#"
	dragEnabled="true"
	dropEnabled="true"
	showQuery="false"
	analyzerMode="true"
 >
</deepsee:pivotTable>
<html id="test" enclosingStyle="display:none;" />

<hgroup id="chartGroup" cellVAlign="top">
<svgFrame id="svg" width="0" height="0" layout="horizontal">
<barChart id="chart1"  width="500" height="500" 
	appearance="2D" 
	controllerId="table" 
	 marginLeft=""
	 marginRight=""
	 legendVisible="false"
	 hasZoom="false"
	 borderStyle=""
	 hidden="true"
	 onelementClick="zenPage.chartElementClick(chart);"
	 selectedItemStyle="stroke:red;stroke-width:0.1;stroke-dasharray:0.5,0.5;"
	>
<xAxis majorGridLines="true" labelAngle="0"/>
<yAxis majorGridLines="true" labelAngle="0"/>
</barChart>
</svgFrame>
<deepsee:chartLegend id="chartLegend" chartId="chart1" controllerId="table"/>
</hgroup>
</hgroup>
</vgroup>
</activeHGroup>

</pane>
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	If (..pivotName'="") {
		Set tName = $P(..pivotName,"/",*)
		Set tName = $P(tName,".",1)
		Quit ##class(%DeepSee.UserPortal.Utils).%ResolveText($Replace(tName,"#","/"))
	}
	ElseIf (..cubeName'="") {
		Quit ##class(%DeepSee.Utils).%GetCubeCaption(..cubeName)
	}
	Quit $$$Text("Analyzer")
}

Method GetTitle() As %String [ ZenMethod ]
{
	If (..pivotName'="") {
		Set tName = $P(..pivotName,"/",*)
		Set tName = $P(tName,".",1)
		Set tName = ##class(%DeepSee.UserPortal.Utils).%ResolveText($Replace(tName,"#","/"))
		Quit tName
	}
	ElseIf (..cubeName'="") {
		Quit ##class(%DeepSee.Utils).%GetCubeCaption(..cubeName)
	}
	Quit ""
}

/// Get the title string to add to the locator row.
/// This should be implemented in a subclass.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return zenPage.GetTitle();
}

/// Get the name for the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Analyzer")
}

/// Get the product name for the page.
Method %OnGetProductName() As %String
{
	Quit "DeepSee"
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Analyzer")

	Set pViewIcons(1) = $LB("pivot",$$$Text("Show pivot table"),"portal/view_pivot.png")
	Set pViewIcons(2) = $LB("chart",$$$Text("Show chart"),"portal/view_chart.png")
	Set pViewIcons(3) = $LB("both",$$$Text("Show pivot table and chart"),"portal/view_chart_pivot.png")

	// commands
	// $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("cmdNew",$$$Text("New"),$$$Text("Create a new pivot table"),"zenPage.newPivot();")
	Set pCommands(2) = $LB("cmdOpen",$$$Text("Open"),$$$Text("Load a previously saved pivot table"),"zenPage.loadPivot();")
	Set pCommands(3) = $LB("cmdSave",$$$Text("Save"),$$$Text("Save this pivot table"),"zenPage.savePivot(false);")
	Set pCommands(4) = $LB("cmdSaveAs",$$$Text("Save As"),$$$Text("Save this pivot table with a new name"),"zenPage.savePivot(true);")
	// + WAL053
	Set pCommands(5) = $LB("cmdRestore",$$$Text("Restore"),$$$Text("Restore pivot to Saved State"),"zenPage.restorePivot();")
	// - WAL053
	Set pCommands(6) = $LB("cmdDelete",$$$Text("Delete"),$$$Text("Delete this pivot table"),"zenPage.deletePivot();")
	Quit $$$OK
}

/// Draw additional stuff in the ribbon bar
Method OnDrawRibbon() As %Status
{
	// auto-exec mode
	Set hlp = $$$Text("Turn on auto-execute mode")
	Set tMsg = $$$Text("Auto-execute")
	Set tTable = ..%GetComponentById("table")
	Set tChecked = $S(tTable.autoExecute:"checked",1:"")
	&html<<td nowrap="1" style="padding-left:20px;font-size:12px;color:#606060;"><input type="checkbox" title="#(hlp)#" #(tChecked)# id="cbAutoExec" onclick="zenPage.autoExecChange();" style="font-size:10pt; color:#606060;"/><span onclick="zenPage.toggleAutoExecute();">#(tMsg)#</span></td>>		// DTB468 - Change the onchange to onclick

	// DTB701 - Add sample checkbox
	// DTB710 - Update text
	Set tSampleHlp = $$$Text("Turn on Preview Mode, which displays partial results")
	Set tSampleMsg = $$$Text("Preview Mode")
	Set tSampleChecked = $S(tTable.previewMode:"checked",1:"")
	&html<<td nowrap="1" style="padding-left:20px;font-size:12px;color:#606060;"><input type="checkbox" title="#(tSampleHlp)#" #(tSampleChecked)# id="cbpreviewMode" onclick="zenPage.previewModeChange();" style="font-size:10pt; color:#606060;"/><span onclick="zenPage.togglePreviewMode();">#(tSampleMsg)#</span></td>>

	If (..actionNames.Count()>0) {
		Set hlp = $$$Text("Invoke an action on the current subject area")
		&html<<td nowrap="1" style="padding-left:40px;"><select title="#(hlp)#" id="actionList" onchange="zenPage.actionHandler(this);" style="font-size:10pt; color:#606060;">>
		&html<<option value="" style="display:none;"> - #($$$Text("action"))# -  </option>>
		For n = 1:1:..actionNames.Count() {
			Set bg = $S(n#2:"white",1:"#F0F0F0")
			&html<<option style="color:#404040;background:#(bg)#;" value="#($ZCVT(..actionNames.GetAt(n),"O","HTML"))#">#($ZCVT(..actionCaptions.GetAt(n),"O","HTML"))#</option>>
		}
		&html<</select></td>>
	}
	Quit $$$OK
}

/// Draw cube name above member tree.
Method DrawCubeName(pSeed As %String) As %Status
{
	Set tCubeCaption = ""
	If (..cubeName'="") {
		Set tCubeCaption = ##class(%DeepSee.Utils).%GetCubeCaption(..cubeName)
	}
	Set tCubeName = $S(tCubeCaption'="":tCubeCaption,1:..cubeName)
	Set hlpCube = $$$Text("Current Subject Area","%DeepSee")
	Set msgChange = $$$Text("Select Subject Area")
	Set hlpChange = $$$Text("Change to a different Subject Area")

	Set hlpAddCalc = $$$Text("Add or edit a calculated member")
	Set hlpAddFilter = $$$Text("Add or edit a named filter for this Subject Area")
	Set hlpAddVariable = $$$Text("Add or edit a pivot variable for this Subject Area")
	Set hlpDelCalc = $$$Text("Remove selected calculated member or named filter")
	Set hlpRefresh = $$$Text("Refresh and reset the contents of the dimension tree","%DeepSee")

	// JMD: place caption on its own line

	&html<<div>>
	&html<<img class="dsptIcon" title="#(hlpChange)#" onclick="zenPage.changeSubjectArea();" style="height:24px;" src="deepsee/ds2_box3_44.png" onmouseover="this._oldClass=this.className;this.className='dsptIconHover';" onmouseout="this.className=this._oldClass;" />>

	If (..cubeName'="") {
		&html<&nbsp;<img class="dsptIcon" title="#(hlpRefresh)#" onclick="zenPage.updateMemberTree();" style="height:24px;" src="deepsee/ds2_refresh_44.png" onmouseover="this._oldClass=this.className;this.className='dsptIconHover';" onmouseout="this.className=this._oldClass;"/>>
		&html<&nbsp;<img class="dsptIcon" title="#(hlpAddCalc)#" onclick="zenPage.addCalculatedMember();" style="height:24px;" src="deepsee/ds2_calculator_44.png" onmouseover="this._oldClass=this.className;this.className='dsptIconHover';" onmouseout="this.className=this._oldClass;"/>>
		&html<&nbsp;<img class="dsptIcon" title="#(hlpAddFilter)#" onclick="zenPage.addNamedFilter();" style="height:24px;" src="deepsee/ds2_gear_44.png" onmouseover="this._oldClass=this.className;this.className='dsptIconHover';" onmouseout="this.className=this._oldClass;"/>>
		&html<&nbsp;<img class="dsptIcon" title="#(hlpAddVariable)#" onclick="zenPage.addPivotVariable();" style="height:24px;" src="deepsee/ds2_keyhole_44.png" onmouseover="this._oldClass=this.className;this.className='dsptIconHover';" onmouseout="this.className=this._oldClass;"/>>
		&html<&nbsp;<img class="dsptIconDisabled" id="iconDelCalc" title="#(hlpDelCalc)#" onclick="zenPage.deleteCalculatedMember();" style="height:24px;" src="deepsee/ds2_x_44.png" onmouseover="this._oldClass=this.className;this.className='dsptIconHover';" onmouseout="this.className=this._oldClass;"/>>
	}

	&html<</div>>

	If (..cubeName="") {
		&html<<div id="cubeNameDiv" title="#(hlpChange)#"><a href="#" onclick="zenPage.changeSubjectArea();">#($ZCVT(msgChange,"O","HTML"))#</a></div>>
	}
	Else {
		&html<<div id="cubeNameDiv" title="#(hlpCube)#">#($ZCVT(tCubeName,"O","HTML"))#</div>>
	}

	// mode selector
	Set tCurrMode = ..treeMode
	Set tModes($I(tModes)) = $LB("",$$$Text("Dimensions"))
	Set tModes($I(tModes)) = $LB("pivots",$$$Text("Pivots"))
	Set tModes($I(tModes)) = $LB("qmsrs",$$$Text("Quality Measures"))

	Set tTable = ..%GetComponentById("table")
	If ($IsObject(tTable) && tTable.listingEnabled) {
		Set tModes($I(tModes)) = $LB("fields",$$$Text("Detail Listings"))
	}

	&html<<div id="cubeModeDiv">>
	&html<<select onchange="zenPage.changeTreeMode(this.value);" class="treeSelect">>
	Set k = $O(tModes(""))
	While (k'="") {
		Set tValue = $LG(tModes(k),1)
		Set tCaption = $LG(tModes(k),2)
		&html<<option value="#(tValue)#" #($S(tValue=tCurrMode:"checked=""1""",1:""))#>#($ZCVT(tCaption,"O","HTML"))#</option>>
		Set k = $O(tModes(k))
	}
	&html<</select>>
	&html<</div>>
	Quit $$$OK
}

/// Launch the subject area finder dialog.
ClientMethod changeSubjectArea() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=subjectAreas','SubjectArea','status,scrollbars,resizable=yes,width=800,height=600');
}

/// Launch the calculated member dialog..
ClientMethod addCalculatedMember() [ Language = javascript ]
{
	if (!this.canUserModify()) {
		return;
	}

	// see if there is a selected calculated member in the tree
	var itemNo = this.isCalculatedMember();

	var table = this.getPivot();
	var dimension = '';
	var member = '';
	var expr = '';
	var format = '';
	var solveOrder = 0;
	var storedWithPivot = 0;			// DTB268

	if (itemNo>=0) {		// DTB308 - A valid array index indicates a local calc member
		var item = table.calculatedMembers[itemNo];
		if (item) {
			dimension = item.dimension;
			member = item.memberName;
			expr = item.valueExpression;
			format = item.formatString;
			solveOrder = item.solveOrder;
			storedWithPivot = 1;		// DTB268
		}
	}
	else if (itemNo<0) {
		// DTB268 - This is a shared member and details will need to be looked up
		var tree = zen('dimTree');
		
		// Send the entire spec, including %SHARED, to the dialog
		member = tree.getNodeValue(tree.getSelectedIndex())
		storedWithPivot = 0;		// DTB268
	}


	// get list of calculated members to pass along to dialog
	var cdimlist = new Array();
	for (var n = 0; n < table.calculatedMembers.length; n++) {
		cdimlist[cdimlist.length] = table.calculatedMembers[n].dimension;
	}

	var parms = {
		CUBE:this.cubeName,
		PIVOT:this.pivotName, // + WAL126 -- pass pivot name so we can construct the right tree of members
		INDEX:itemNo,
		DIMENSION:dimension,
		MEMBER:member,
		FORMAT:format,
		SOLVEORDER:solveOrder,
		DIMLIST:cdimlist.join(','),
		EXPR:expr,
		LOCAL:storedWithPivot			// DTB268
	};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.AddCalculatedMember.zen','AddCalculatedMember','status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// Launch the add named filter dialog..
ClientMethod addNamedFilter() [ Language = javascript ]
{
	if (!this.canUserModify()) {
		return;
	}

	// see if there is a named filter selected in the tree
	var fname = this.isNamedFilter();

	var table = this.getPivot();

	var parms = {
		NAMEDFILTER:1,
		CUBE:this.cubeName,
		EXPRESSION:'',
		FILTERNAME:fname
	};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.AdvancedFilter.zen','NamedFilter','status=no,scrollbars,resizable=yes,width=700,height=600',parms,this);
}

/// Launch the add pivot variable dialog.
ClientMethod addPivotVariable() [ Language = javascript ]
{
	// JMD1276
	if (!this.canUserModify()) {
		return;
	}

	// see if there is a pivot variable selected in the tree
	var vname = this.isPivotVariable();

	var table = this.getPivot();

	var parms = {
		CUBE:this.cubeName,
		VARIABLE:vname
	};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotVariable.zen','PivotVariable','status=no,scrollbars,resizable=yes,width=700,height=600',parms,this);
}

/// Test if the current item in the tree is a calculated member.
/// If so, return the index of the item within the calculatedMembers array.
ClientMethod isCalculatedMember() [ Language = javascript ]
{
	var itemNo = '';
	var table = this.getPivot();
	var tree = zen('dimTree');
	var idx = tree.getSelectedIndex();

	if (idx >= 0) {
		var val = tree.getNodeValue(idx);
		var valIsDim = val.indexOf('%TopMembers')>=0;
		var valIsShared = (val.indexOf('%SHAREDCALC')>-1)		// DTB715  Change test to search the entire string

		var testDim = '';
		var testMbr = '';
		if (valIsShared) {
			// DTB268 - Members with the %SHAREDCALC token are always calculated members
			itemNo=-1;
		}
		else {
			for (var n = 0; n < table.calculatedMembers.length; n++) {
				var mbr = table.calculatedMembers[n];
				if (valIsDim) {
					// get dimension name
					if (mbr.dimension.toString().charAt(0)=='[') {
						testDim = mbr.dimension+'.%TopMembers';
					}
					else {
						testDim = '['+mbr.dimension+'].%TopMembers';
					}
					if (testDim.toUpperCase() == val.toUpperCase()) {
						dimension = mbr.dimension;
						break;
					}
				}
				else {
					// get item no
					// DTB158 - Assume any ']' are already properly escaped if the string is quoted
					// If unquoted, escape any ']' to form a valid MDX string and quote it. This is  
					// the format used in the tree node's value
					if (mbr.dimension.toString().charAt(0)=='[') {
						testDim = mbr.dimension;
					}
					else {
						testDim = '['+mbr.dimension.replace(']',']]')+']';		// DTB158
					}
					
					if (mbr.memberName.toString().charAt(0)=='[') {
						testMbr = mbr.memberName;
					}
					else {
						testMbr = '['+mbr.memberName.replace(']',']]')+']';		// DTB158
					}
					testMbr = testDim + '.' + testMbr;

					if (testMbr.toUpperCase() == val.toUpperCase()) {
						itemNo = n;
						break;
					}
				}
			}
		}
	}

	return itemNo;
}

/// Test if the current item in the tree is a named filter.
/// If so, return the filter name else return ''.
ClientMethod isNamedFilter() [ Language = javascript ]
{
	var table = this.getPivot();
	var tree = zen('dimTree');
	var idx = tree.getSelectedIndex();
	var fname = '';

	if (idx >= 0) {
		var val = tree.getNodeValue(idx);
		if (val=='%FILTER') {
			fname = tree.getNodeText(idx);
		}
	}
	return fname;
}

/// Test if the current item in the tree is a pivot variable.
/// If so, return the variable name else return ''.
ClientMethod isPivotVariable() [ Language = javascript ]
{
	var table = this.getPivot();
	var tree = zen('dimTree');
	var idx = tree.getSelectedIndex();
	var fname = '';

	if (idx >= 0) {
		var val = tree.getNodeValue(idx).toString();
		if (val.toLowerCase().substr(0,10)=='$variable.') {
			fname = val.substr(10);
		}
	}
	return fname;
}

/// Launch the show query dialog.
ClientMethod showQuery() [ Language = javascript ]
{
	var table = this.getPivot();
	table.SynthesizeMDX();		// DTB595
	var manualMode = (table && table.dataSource=='manual');
	// JMD1180: always show query
	if (table) {
		// JMD1031
		this._oldDataSource = table.dataSource;
		this._oldMDX = table.userMDX;
		var mdx = manualMode ? table.userMDX : table.GetCurrentQueryText();
		// + WAL075 -- use nonce
		var nonce = zenPage.CreateQueryNonce(mdx); 
		if (nonce.toString().indexOf('ERROR:')>=0) {
			// error
			alert(nonce);
			return;
		}
		var parms = {
			CUBE:this.cubeName,
			LISTINGNAME:table.listing,
			MANUAL:manualMode?1:0,
			NONCE:nonce
		};
		// - WAL075
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.ShowQuery.zen','Query','status,scrollbars,resizable=yes,width=800,height=600',parms);
	}
}

/// Launch the chart options dialog.
ClientMethod showChartOptions() [ Language = javascript ]
{
	var chart = this.getCurrentChart();
	var chartType = this.getChartType();
	var grid = this.getGridType();
	var textSize = chart.getProperty('textSize');
	var title = chart.title;
	var min,max;
	if (chart.chartPivot) {
		min = chart.xAxis ? chart.xAxis.minValue : '';
		max = chart.xAxis ? chart.xAxis.maxValue : '';
	}
	else {
		min = chart.yAxis ? chart.yAxis.minValue : '';
		max = chart.yAxis ? chart.yAxis.maxValue : '';
	}
	
	var parms = {
			TYPE:chartType,
			GRID:grid,
			TEXTSIZE:textSize,
			MIN:min,
			MAX:max,
			TITLE:title
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.ChartOptions.zen','ChartOptions','status=no,scrollbars=no,resizable,width=550,height=600',parms);
}

/// Launch the cell format options dialog.
ClientMethod showFormatOptions() [ Language = javascript ]
{
	var table = this.getPivot();

	var parms = {
			COLORSCALE:table.colorScale
			};

	zenLaunchPopupWindow('_DeepSee.UI.Dialog.CellFormatOptions.zen','CellFormatOptions','status=no,scrollbars=no,resizable,width=550,height=600',parms);
}

/// Launch the pivot options dialog.
ClientMethod showPivotOptions() [ Language = javascript ]
{
	var table = this.getPivot();

	var parms = {
			CUBE:this.cubeName,
			SQLRESTRICT:table.sqlRestriction,		// DTB723
			LISTING:table.listing,
			LISTINGROWS:table.listingRows,
			ROWTOTALS:table.rowTotals?1:0,
			COLUMNTOTALS:table.columnTotals?1:0,
			ROWTOTALAGG:table.rowTotalAgg,
			COLUMNTOTALAGG:table.columnTotalAgg,
			ROWTOTALSOURCE:table.rowTotalSource,
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
			ROWCAPTION:table.showRowCaption?1:0
			};

	// DTB723 - Adjust window size according to the extra SQLRestrict field
	if (zenPage.cubeSupportsSqlRestrict) {
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotOptions.zen','PivotOptions','status=no,scrollbars=no,resizable,width=850,height=640',parms);
	}
	else {
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotOptions.zen','PivotOptions','status=no,scrollbars=no,resizable,width=850,height=600',parms);
	}
}

/// Launch the pdf options dialog.
ClientMethod showPDFOptions() [ Language = javascript ]
{
	var table = this.getPivot();

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
			BORDERLEFTCELL:table.borderLeftCell,
			BORDERRIGHTCELL:table.borderRightCell,
			BORDERTOPCELL:table.borderTopCell,
			BORDERBOTTOMCELL:table.borderBottomCell,
			BORDERLEFTCOL:table.borderLeftCol,
			BORDERRIGHTCOL:table.borderRightCol,
			BORDERTOPCOL:table.borderTopCol,
			BORDERBOTTOMCOL:table.borderBottomCol,
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

			PAGESIZE:table.printPageSize,
			ORIENTATION:table.printOrientation,
			MARGINTOP:table.printMarginTop,
			MARGINBOTTOM:table.printMarginBottom,
			MARGINLEFT:table.printMarginLeft,
			MARGINRIGHT:table.printMarginRight,
			PRINTLABELWIDTH:table.printLabelWidth,
			PRINTCELLWIDTH:table.printCellWidth,
			TITLE:table.printTitle,
			SUBTITLE:table.printSubtitle,
			SUBTITLEON:table.printSubtitleOn,
			SHOWDATE:table.showDate,						// DTB228
			SHOWUSER: table.showUser,
			SHOWZEBRASTRIPES: table.showZebraStripes,		// DTB228
			SHOWLISTINGFILTERS: table.showListingFilters,	// DTB228
			BORDERLEFTCELL:table.borderLeftCell,
			BORDERRIGHTCELL:table.borderRightCell,
			BORDERTOPCELL:table.borderTopCell,
			BORDERBOTTOMCELL:table.borderBottomCell,
			BORDERLEFTCOL:table.borderLeftCol,
			BORDERRIGHTCOL:table.borderRightCol,
			BORDERTOPCOL:table.borderTopCol,
			BORDERBOTTOMCOL:table.borderBottomCol,
			BORDERLEFTROW:table.borderLeftRow,
			BORDERRIGHTROW:table.borderRightRow,
			BORDERTOPROW:table.borderTopRow,
			BORDERBOTTOMROW:table.borderBottomRow,
			// + WAL100
			FONTFAMILYCELL:table.fontFamilyCell,
			FONTSIZECELL:table.fontSizeCell,
			FONTFAMILYCOL:table.fontFamilyCol,
			FONTSIZECOL:table.fontSizeCol,
			FONTFAMILYROW:table.fontFamilyRow,
			FONTSIZEROW:table.fontSizeRow,
			// - WAL100
			SHOWFILTERS: table.showFilters,
			FILTERROWCOUNT:filterRowCount,			
			FILTERTABLESTYLE: table.filterTableStyle,
			FILTERTABLECAPTIONSTYLE: table.filterTableCaptionStyle,
			FILTERTABLEITEMSTYLE: table.filterTableItemStyle,
			NOWDISPLAYFORMAT: table.nowDisplayFormat,

			ROWCAPTION:table.showRowCaption?1:0,
			MAXROWS:table.maxRows
	};

	zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotPrintOptions.zen','PrintOptions','status=no,scrollbars=no,resizable,width=850,height=600',parms);
}

/// Launch the pivot analysis dialog.
ClientMethod showBreakdown() [ Language = javascript ]
{
	var pivot = this.getPivot();
	if ('' == pivot.selectedRange) {
		alert($$$Text('Please select a cell to display a breakdown for.\nNote that you can select multiple adjacent cells by holding the Shift key down while clicking the mouse.'));
		return false;
	}

	// get WITH clause for local calc members
	var tWITH = '';
	for (var n = 0; n < pivot.calculatedMembers.length; n++) {
		var mbr = pivot.calculatedMembers[n];
		if (mbr.dimension!='' && mbr.memberName!='') {
			var dim = mbr.dimension.toString();
			var name = mbr.memberName.toString();
			dim = (dim.charAt(0)=='[') ? dim.substr(1,dim.length-2) : dim;
			name = (name.charAt(0)=='[') ? name.substr(1,name.length-2) : name;
			tWITH += " MEMBER ["+dim+"].["+name+"] AS \'" + mbr.valueExpression + "\'";
		}
	}

	var msr = '';
	if (pivot.measures.length > 0) {
		msr = pivot.measures[0].spec;
	}

	var parms = {
			CUBE:pivot.cubeName,
			KEY:pivot.queryKey,
			WITH:tWITH,
			MEASURE:msr,
			RANGE:pivot.selectedRange,
			SORTCOL:pivot.sortColumn,
			SORTDIR:pivot.sortDir
			};

	if (this.hasAnalysis) {
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotAnalysis.zen','BreakDown','status,scrollbars,resizable=yes,width=800,height=600',parms);
	}
	else {
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotBreakdown.zen','BreakDown','status,scrollbars,resizable=yes,width=800,height=600',parms);
	}
}

/// This client event is fired when a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'NamedFilter':
		this.updateMemberTree();
		var table = this.getPivot();
		table.executeQuery(true);
		break;

	case 'PivotVariable':
		this.updateMemberTree();
		var table = this.getPivot();
		table.executeQuery(true);
		var msg = zenPage.UpdateFilterControls(table.cubeName,zen('filterGroup'),table);
		if (''!==msg) {
			alert(msg);
		}
		break;

	case 'Query':
		// JMD1031
		var table = this.getPivot();
		if (table.dataSource!=this._oldDataSource || (table.dataSource=='manual'&&(table.userMdx!=this._oldMDX))) {
			if (table.dataSource!='manual') {
				table.cubeName = this.cubeName;
			}
			else {
				// JMD1453 remove filters so they don't get doubled up
				table.filters.length = 0;
				var msg = zenPage.UpdateFilterControls(table.cubeName,zen('filterGroup'),table);
				if (''!==msg) {
					alert(msg);
				}
			}
			table.executeQuery(true);
			table.updateController();
		}
		break;

	case 'PivotOpen':
		var table = this.getPivot();
		var exec = '';
		if (!table.autoExecute) {
			// pass autoexec setting to next pivot
			exec = '&EXEC=0';
		}
		// + WAL053
		var autosave = '';
		if ((this.autosave != '') && (!this.CheckAutosaveSetting())) {
			autosave = '&AUTOSAVE=' + this.autosave;	
		}
		self.document.location = zenLink(this.analyzerURL + '?PIVOT=' + encodeURIComponent(value) + exec + autosave);
		// - WAL053
		break;

	case 'PivotSave':
		// prevent updates during save!
		zenPage._noUpdate = true;
		var msg = this.SavePivotTable();
		zenPage._noUpdate = false;
		if (msg!="") {
			alert(msg);
		}

		// DP-423287 - Always refresh the pivot URL and page state
		// DTB780 - update the URL to jump to the new pivot name
		self.document.location = zenLink(this.analyzerURL + '?PIVOT=' + this.pivotName); 
			
		// make sure title shows new name
		zen('title').refreshContents();
		// PFS024 - Update the name on the pivot controller
		zen('table').name = this.pivotName
		this.updatePivotTree();
		break;

	case 'PivotOptions':
		var table = this.getPivot();
		table.executeQuery(true);
		break;

	case 'PrintOptions':
		// value is an object
		var options = value;
		var pivot = this.getPivot();
		pivot.printTitle = options.printTitle;
		pivot.printSubtitle = options.printSubtitle;
		pivot.printSubtitleOn = options.printSubtitleOn; // JSL4302
		pivot.showDate = options.showDate;						// DTB228
		pivot.showListingFilters = options.showListingFilters;	// DTB228
		pivot.showZebraStripes = options.showZebraStripes;		// DTB228
		pivot.showUser = options.showUser; // JSL4320
		pivot.printPageSize = options.printPageSize;
		pivot.printOrientation = options.printOrientation;
		pivot.printMarginTop = options.printMarginTop;
		pivot.printMarginBottom = options.printMarginBottom;
		pivot.printMarginLeft = options.printMarginLeft;
		pivot.printMarginRight = options.printMarginRight;
		pivot.printCellWidth = options.printCellWidth;
		// JSL4219
		pivot.maxRows = options.maxRows;
		// JSL4128
		pivot.borderLeftCell = options.borderLeftCell
		pivot.borderRightCell = options.borderRightCell
		pivot.borderTopCell = options.borderTopCell
		pivot.borderBottomCell = options.borderBottomCell
		pivot.borderLeftCol = options.borderLeftCol
		pivot.borderRightCol = options.borderRightCol
		pivot.borderTopCol = options.borderTopCol
		pivot.borderBottomCol = options.borderBottomCol
		pivot.borderLeftRow = options.borderLeftRow
		pivot.borderRightRow = options.borderRightRow
		pivot.borderTopRow = options.borderTopRow
		pivot.borderBottomRow = options.borderBottomRow
		
		// + WAL100 -- store settings from the dialog
		pivot.fontFamilyCell = options.fontFamilyCell;
		pivot.fontSizeCell = options.fontSizeCell;
		pivot.fontFamilyCol = options.fontFamilyCol;
		pivot.fontSizeCol = options.fontSizeCol;
		pivot.fontFamilyRow = options.fontFamilyRow;
		pivot.fontSizeRow = options.fontSizeRow;
		// - WAL100
		
		pivot.showFilters = options.showFilters;
		pivot.filterTableStyle = options.filterTableStyle;
		pivot.filterTableCaptionStyle = options.filterTableCaptionStyle;
		pivot.filterTableItemStyle = options.filterTableItemStyle;
		pivot.nowDisplayFormat = options.nowDisplayFormat; // JSL4308
		
		break;

	case 'ChartOptions':
		var chart = zen('chart1');
		if (chart) {
			var style = (value=='') ? '' : 'fill:' + value;
		}
		break;
	case 'CellFormatOptions':
		break;
	case 'SubjectArea':
		// strip off extension
		var isCube = true;
		var name = '';
		var s = value.toString().split('.');
		if ('cube' == s[s.length-1]) {
			s.length = s.length-1;
			name = s.join('.');
			isCube = true;
		}
		else if ('subjectArea' == s[s.length-1]) {
			s.length = s.length-1;
			name = s.join('.');
			isCube = false;
		}

		if (name != this.cubeName) {
			// + WAL053
			var autosave = '';
			if (this.autosave != '') {
				var overrideValue = zenPage.GetOverrideValue(this.autosave);
				autosave = '&AUTOSAVEOVERRIDE='+overrideValue;
				if (!this.CheckAutosaveSetting()) { autosave += '&AUTOSAVE='+this.autosave }
			}	
			self.document.location = zenLink(this.analyzerURL + '?CUBE=' + encodeURIComponent(value) + autosave);
			// - WAL053
		}
		break;
	case 'switchNamespace':
		var homeurl = zenLink("/csp/sys/%25CSP.Portal.Home.zen");
		var url = zenPage.GetNewURL(value,"_DeepSee.UI.Analyzer.zen");
		if (url == "" || value == "%SYS") url = homeurl;
		self.document.location = url;
		break;
	}
}

/// WAL053
ClientMethod restorePivot() [ Language = javascript ]
{
	this.warnUser = false;
	// WAL053 -- pass a token so that we don't open a temp pivot
	var url = this.analyzerURL
	if ((this.pivotName != '')&&(this.pageModified || this.autosave)) {
		url += '?PIVOT=' + encodeURIComponent(this.pivotName);
		if (this.autosave != '') {
			var overrideValue = this.GetOverrideValue(this.autosave);
			url += '&AUTOSAVEOVERRIDE='+encodeURIComponent(overrideValue);
			if (!this.CheckAutosaveSetting()) { url += '&AUTOSAVE='+encodeURIComponent(this.autosave) }	
		}
		
		if (confirm($$$Text('Do you wish to reload the saved version of the pivot table?'))) {
			self.document.location = zenLink(url);
		}
	}
}

/// Create a new saved pivot.
ClientMethod newPivot() [ Language = javascript ]
{
	this.warnUser = true;
	// + WAL053 -- pass a token so that we don't open a temp pivot
	var url = this.analyzerURL
	if (this.autosave != '') {
		var overrideValue = zenPage.GetOverrideValue(this.autosave);
		url += '?AUTOSAVEOVERRIDE='+overrideValue;
		if (!this.CheckAutosaveSetting()) { url += '&AUTOSAVE='+this.autosave };	
	}
	self.document.location = zenLink(url);
	// - WAL053
}

Method GetOverrideValue(pToken) As %String [ ZenMethod ]
{
	// Method added by WAL053
	q ($G(^DeepSee.Autosave(pToken)) + 1)
}

Method CheckAutosaveSetting() As %Boolean [ ZenMethod ]
{
	// Method added by WAL053
	q (+$G(^DeepSee.UserPortalSettings("autosaveAnalyzer")) && (..autosave = $USERNAME))
}

/// Launch the open saved pivot finder dialog.
ClientMethod loadPivot() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.zen?MODE=pivots','PivotOpen','status,scrollbars,resizable=yes,width=800,height=600');
}

/// Launch the save pivot dialog.
ClientMethod savePivot(showDialog) [ Language = javascript ]
{
	this.warnUser = false;
	if (!this.canUserModify()) {
		return;
	}

	if (showDialog || this.pivotName==='') {
		// show save dialog
		var parms = {
				PIVOT:this.pivotName,
				DESC:this.pivotDescription,
				RESOURCE:this.pivotResource,
				OWNER:this.pivotOwner,
				LOCKED:this.pivotLocked?1:0,
				PUBLIC:this.pivotPublic?1:0,
				CATEGORY:this.pivotCategory,
				WORDS:this.pivotKeywords
				};
		zenLaunchPopupWindow('_DeepSee.UI.Dialog.PivotSave.zen','PivotSave','status,scrollbars,resizable=yes,width=700,height=600',parms);
	}
	else if (this.pivotLocked) {
		alert($$$Text('This pivot is locked and cannot be saved without first unlocking it.'));
	}
	else {
		this.onPopupAction('PivotSave','','');
	}
}

/// Save and manage a temp version of this table and a "Last" copy for autosave
Method SaveTempTables() As %String [ ZenMethod ]
{
	// Method added by DP-427970
	Set tSC = $$$OK

	Try {
		Set tSavedPivotName = ..pivotName
		Set tModified = %page.pageModified
		// Initialize temp nameswith appropriate autosave root
		Set tTempPivotName = ..tempStorageRoot _ ..autosave _ "/"
		Set tLastPivotName = ..tempStorageRoot _ "Last/" _ ..autosave _ "/"
		Set tLastFolder = ..tempStorageRoot _ "Last/" _ ..autosave
		
		if (..pivotName '= "") {
			// A saved pivot is currently open
			Set tTempPivotName = tTempPivotName _ ..pivotName
			Set tLastPivotName = tLastPivotName _ ..pivotName
		}
		else {
			// Cube exploration without a saved pivot currently open
			Set tTempPivotName = tTempPivotName _ ..autosave
			Set tLastPivotName = tLastPivotName _ ..autosave
		}	
		
		// Clear the temp copy and save the new copy
		Set sc = ..KillTempPivot(tTempPivotName)
		Set sc = ..SavePivotTable(tTempPivotName)
		
		// Clear out the Last subfolder and save the newest copy
		Set sc = ..KillTempSubFolders(tLastFolder)
		Set sc = ..SavePivotTable(tLastPivotName)

		// Reset the modfiied state prior to executing saves on the temp tables, which can clear the pageModified flag
		Set %page.pageModified = tModified
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Save the pivot table. If the optional <var>pPivotName</var> is supplied, a copy of the pivot definition currently open will be filed under
/// that identifier. If no such custom identifier is supplied, the table will be saved under the name currently in use.
Method SavePivotTable(pPivotName As %String = "") As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		// DP-427970 - Use the pPivotName if supplied to direct to custom storage
		Set tPivotName = $S((pPivotName'=""):pPivotName,1:..pivotName)

		// save pivot
		Set tExists = ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(tPivotName)
		If (tExists=2) {
			Set tMsg = $$$Text("Name is already in use.")
			Quit
		}
		ElseIf ((tExists=1)||(tExists=3)) {
			// DTB925 - Respond to stricter validation in %OpenFolderItem
			// DP-432616 - If this is reached in locked mode, open it to prevent duplication of the table
			Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tPivotName,.tSC)
		}
		
		If '$IsObject($G(tPivot)) {
			Set tPivot = ##class(%DeepSee.Dashboard.Pivot).%New()
		}
		If $$$ISERR(tSC) Quit

		#; check for WRITE privilege
		If ('tPivot.%CheckResource("WRITE")) {
			Set tMsg = $$$Text("You do not hold WRITE permission on this pivot.")
			Quit
		}

		Set tPivot.fullName = tPivotName
		Set tPivot.description = ..pivotDescription
		Set tPivot.keywords = ..pivotKeywords
		Set tPivot.category = ..pivotCategory
		Set tPivot.locked = ..pivotLocked
		Set tPivot.public = ..pivotPublic
		Set tPivot.resource = ..pivotResource
		Set tPivot.owner = ..pivotOwner

		Set tTable = ..%GetComponentById("table")

		// Copy pivot settings into definition object
		Set tSC = tPivot.%CopyFromComponent(tTable)
		If $$$ISERR(tSC) Quit

		Set tSC = tPivot.%Save()
		If $$$ISERR(tSC) Quit
		Set tSC = ##class(%DeepSee.UserLibrary.Utils).%RegisterRecentItem("folder",tPivot.folderName)
		If $$$ISERR(tSC) Quit

		// DP-414702 - If this page has been modified, notify the user that the save was successful
		Set:%page.pageModified tMsg = $$$Text("Pivot successfully saved"), %page.pageModified = 0
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	
 	Quit tMsg
}

/// Delete the pivot table.
ClientMethod deletePivot() [ Language = javascript ]
{
	this.warnUser = false;
	if (!this.canUserModify()) {
		return;
	}
	if (''==this.pivotName) {
		return;
	}
	if (this.pivotLocked) {
		// DP-432616 - This blocks the delete of a locked pivot
		alert($$$Text('This pivot is locked and cannot be deleted without first unlocking it.'));
		return false;
	}
	else if (!confirm($$$Text('Do you wish to delete this saved pivot table?'))) {
		return;
	}
	var msg = this.DeletePivotTable();
	if (''!=msg) {
		alert(msg);
	}
	zenPage.newPivot();
}

/// Delete the pivot table.
Method DeletePivotTable() As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tMsg = ""
	Try {
		Set tPivotName = ..pivotName
		Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderItem(..pivotName)
		If $$$ISERR(tSC) Quit
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Else {
		Set tMsg = $$$FormatText($$$Text("Pivot table %1 deleted"),$G(tPivotName))
	}
	Quit tMsg
}

/// pivot
ClientMethod pivot() [ Language = javascript ]
{
	var table = this.getPivot();
	table.pivotTable();
}

ClientMethod setDim(dim, val) [ Language = javascript ]
{
	var param = zenPage.getComponentById(dim);
	if (param) {
		param.spec = val;
		var table = this.getPivot();
		table.executeQuery();
	}
}

/// Provide contents of the dimension tree.
ClassMethod GetDimensionInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Set tRoot=pRoot
	//Set pRoot = $replace(pRoot,"]]","]") // DTB127 - keep the escaped identifiers intact
	Try {
		Set tCube = $G(pParms("cube"))
		Set tCube = ##class(%DeepSee.CubeVersion.Utils).%GetVersionedCubeName(tCube)		// DTB130 - Reroute to a cube version if it exists
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
							Set tCalcMbrs($$$UPPER(tCalcMbr.dimension),$$$UPPER(tCalcMbr.memberName)) = $LB(tCalcMbr.dimension,tCalcMbr.memberName,tCalcMbr.valueExpression)
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

/// Provide contents of the saved pivot dimension tree.
ClassMethod GetPivotInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCube = $G(pParms("cube"))
		Set tPivotName = $G(pParms("pivot"))
		If (tCube'="") {
			// pivots for this cube
			Set tSC = ##class(%DeepSee.Utils).%GetPivotTree(tCube,.pTree,tPivotName)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Provide contents of the quality measures dimension tree.
ClassMethod GetQMSRInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCube = $G(pParms("cube"))
		Set tPivotName = $G(pParms("pivot"))

		If (tCube'="") {
			// quality measures
			Set tSC = ##class(%DeepSee.Utils).%GetQualityMeasureTree(tCube,.pTree)
			If $$$ISERR(tSC) Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Provide contents of the listing fields dimension tree.
ClassMethod GetListingFieldsInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tCube = $G(pParms("cube"))
		Set tPivotName = $G(pParms("pivot"))
		Set tCurrListing = $G(pParms("listing"))
		Kill pTree

		If (tCube'="") {

			Set tSC = ##class(%DeepSee.Utils).%GetCubeListings(tCube,.tListings)
			If $$$ISERR(tSC) Quit

			Set tIcon = "deepsee/ds2_binoculars_44.png"
			Set tStyleBase = "color:darkblue;"

			// Default
			Set pTree($I(pTree)) = $LB($$$Text("Default Listing"),"$$$LISTING:",0,"",0,tIcon,,tStyleBase_$S(tCurrListing="":"font-weight:bold;",1:""))
			Set pTree(0,"ch",pTree) = ""

			Set k = $O(tListings(""))
			While (k'="") {
				If (k'="$$$CUSTOM") {
					// DTB084 - provide a visual cue that this listing can be edited in the Listing Group Manager
					If ($LG(tListings(k),5)="listingGroup")&&$$CheckListingGroupWriteAccess^%qdsUtils()&&$LG(tListings(k),6) {
						Set tAppendedStyle = "font-style:italic;"
						// DTB139 - Use the listing description if there is one
						Set tHint = $S($LG(tListings(k),7)'="":$LG(tListings(k),7),1:$$$Text("This listing can be edited in the Listing Group Manager"))
					} Else {
						Set tAppendedStyle = ""
						Set tHint = $LG(tListings(k),7) // JSL4477
					}

					// Prepend listing name with $$$LISTING:
					Set pTree($I(pTree)) = $LB($LG(tListings(k),1),"$$$LISTING:"_k,0,"",0,tIcon,tHint,tStyleBase_tAppendedStyle_$S(tCurrListing=k:"font-weight:bold;",1:""))
					Set pTree(0,"ch",pTree) = ""
				}
				Set k = $O(tListings(k))
			}

			Set tSC = ##class(%DeepSee.Utils).%GetCubeListingFields(tCube,.tFields)
			If $$$ISERR(tSC) Quit

			If $D(tFields) {
				// add a custom listings set
				Set tIcon = "deepsee/ds2_notepad2_44.png"
				Set pTree($I(pTree)) = $LB($$$Text("Custom Listing"),"$$$LISTING:$$$CUSTOM",1,"",0,"",$$$Text("Custom Listing","%DeepSee"),"color:darkblue;"_$S(tCurrListing="$$$CUSTOM":"font-weight:bold;",1:""))
				Set pTree(0,"ch",pTree) = ""
				Set tRoot = pTree

				Set k = $O(tFields(""))
				While (k'="") {
					// put special $$$FIELD: token in front
					Set tDescription=$LG(tFields(k),3) // JSL4477
					Set pTree($I(pTree)) = $LB($LG(tFields(k),1),"$$$FIELD:"_$LG(tFields(k),2)_":"_k,0,"",0,tIcon,tDescription)		// DTB309 - Include the logical ID of the listingField
					Set pTree(tRoot,"ch",pTree) = ""
					Set k = $O(tFields(k))
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	If (..#USERMODE) {
		Set tHome = ##class(%DeepSee.UserPortal.Utils).%GetUserHomePageURL()
	}
	Else {
		Set tHome = ..homePage
	}
	Do ..%GetRootLink(.pLink)
	Set tPageName = ..%OnGetPageName()
	If (..pivotName'="") {
		Set pLink($I(pLink)) = $LB(tPageName,$ZCVT($classname(),"O","URL")_".zen?home="_..EscapeURL($G(%request.Data("home",1)))_"&PIVOT="_$ZCVT(..pivotName,"O","URL"))
	}
	Else {
		Set pLink($I(pLink)) = $LB(tPageName,$ZCVT($classname(),"O","URL")_".zen?home="_..EscapeURL($G(%request.Data("home",1)))_"&CUBE="_$ZCVT(..cubeFullName,"O","URL"))
	}
	Quit $$$OK
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		if (load) {
			// adjust style of delete button
			var btn = self.document.getElementById('command_cmdDelete');
			if (btn) {
				btn.className = "commandButtonRemove"
			}
		}
		document.getElementById('mainHGroup').children[0].engine.sizeContainer(); // WAL182
		this.adjustSizes(load);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

ClientMethod positionResizeHandles(initial) [ Language = javascript ]
{
	
	var controller = zen('pivotController');
	var divPivot = controller.findElement('pivotColumns');
	var table = divPivot.children[0];
	
	var groupTree = zen('groupTree');
	var divTree = groupTree.getEnclosingDiv();
	var groupTreeOffset = divTree.offsetWidth;
	var row = this.getFirstTableRow(table);
	
	// Initially we need to provide a width for each part of the controller
	if (initial) {
		for (var kid = row.children[0]; kid; kid = kid.nextSibling){
			kid.style.width = (divPivot.offsetWidth/4) + 'px';		// DTB560 - Set style.width instead of width
		}	
	}
	
	var kidCount = -1;
	for (var kid = row.children[0]; kid; kid = kid.nextSibling){	
		if (kid.tagName == "TH" || kid.tagName == "TD") {
			if (kidCount> -1) {
				var ctrl = this.handle[kidCount];
				var position = kid.offsetLeft-5;
				ctrl.pos = position;
				ctrl.div.style.left = position+"px"; // 10 for left margin of page
				ctrl.col = lastKid;
			}
			var lastKid = kid;
			kidCount++;
		}				
	}
	
	var ctrl = this.handle[3];
	ctrl.col = table;
}

ClientMethod getFirstTableRow(div) [ Language = javascript ]
{
	while (div.children && div.children.length>0 && !(div.children[0].tagName=="TH" || div.children[0].tagName=="TD")) div = div.children[0];
	return (div);
}

/// Callback to initiate window resize event
ClientMethod startDrag(engine, wrapper) [ Language = javascript ]
{
	var idx = 0;
	while (this.handle[idx] && this.handle[idx].div!=wrapper.node) idx++;
	
	// vertical resize of controller area
	if (idx==3) {
		this.verticalDrag = true;
		this.barInMotion = this.handle[idx];
		//this.startingX = this.barInMotion.div.offsetLeft;
		this.startingH = this.barInMotion.div.offsetHeight;
		return;
	}
	this.verticalDrag = false;

	this.barInMotion = this.handle[idx];
	this.startingX = this.barInMotion.div.offsetLeft;
	this.startingW = this.barInMotion.col.offsetWidth;
	
	if (idx==0) this.minX = 10;
	else this.minX = this.handle[idx-1].div.offsetLeft+10;
	// + WAL185 -- this.handle.length-2 is the last pivotController horizontal drag handle
	//             (the filters box). this.handle.length-1 is the vertical drag for the entire
	//             pivotController region
	if (idx==this.handle.length-2) this.maxX = this.handle[idx].div.parentNode.offsetWidth-20;
	// - WAL185
	else this.maxX = this.handle[idx+1].div.offsetLeft-10;
}

/// Callback to wrap up window resize event 
ClientMethod endDrag(engine, wrapper) [ Language = javascript ]
{
  	this.positionResizeHandles();
  	
  	var controller = zen('pivotController');
	var divPivot = controller.findElement('pivotColumns');
	var table = divPivot.children[0];
  	
  	var div = this.handle[3].div;
  	var pivotController = document.getElementById('controllerTableArea');
  	
  	var rowsHeader = document.getElementById('rows_header');
  	var height = (parseInt(pivotController.offsetHeight) - parseInt(rowsHeader.offsetHeight)) + 'px';
  	
  	// + WAL194 -- explicity resize content areas
  	if (this.verticalDrag==true) {
	  	var rowsBody = document.getElementById('rows_body');
	  	var colsBody = document.getElementById('cols_body');
	  	var filtersBody = document.getElementById('filters_body');
	  	var msrsBody = document.getElementById('msrs_body');
  		rowsBody.style.height = (parseInt(table.style.height)-30)+'px';
  		colsBody.style.height = (parseInt(table.style.height)-30)+'px';
  		msrsBody.style.height = (parseInt(table.style.height)-30)+'px';
  		filtersBody.style.height = (parseInt(table.style.height)-30)+'px';
  		// let the controller know what height it should use for the content areas
  		// when it runs its updateState method
  		controller.rowsHeight = rowsBody.style.height;
  		zenPage.adjustSizes();
  		this.positionResizeHandles();
  		
  		if (parseInt(div.style.top) < pivotController.offsetHeight) {
	 		div.style.top = parseInt(pivotController.offsetHeight) + 'px';
  		}
  	}
  	// - WAL194
}

/// Callback to limit horizontal resizing
ClientMethod constrainDragX(engine, wrapper, intendedX) [ Language = javascript ]
{
	if (this.verticalDrag==true) {
		return(0);	
	}
	var newX = intendedX;
	if (newX<this.minX) newX = this.minX;
	if (newX>this.maxX) newX = this.maxX;
	
	var newDelta = newX - this.startingX;
	this.barInMotion.col.style.width = (this.startingW+newDelta)+"px";
	return(newX);
}

/// Callback to limit vertical resizing
ClientMethod constrainDragY(engine, wrapper, intendedY) [ Language = javascript ]
{
	if (this.verticalDrag==true) {
		controllerHeight = document.getElementById('controllerTableArea').offsetHeight;
		tableHeight = document.getElementById('table').offsetHeight;

		if (intendedY < 75) return 75; // WAL183 -- don't let the controller area get too small
		
		if ((controllerHeight >= tableHeight) && (intendedY > controllerHeight)) {
			return controllerHeight;
		}
		this.barInMotion.col.style.height = intendedY + 'px';
		
		// + WAL194 -- specify the size of the content areas
		//             the this.barInMotion.col statement specifies the high of 
		//             the containing div
	  	var controller = zen('pivotController');
		var divPivot = controller.findElement('pivotColumns');
		var table = divPivot.children[0];
	  	var rowsBody = document.getElementById('rows_body');
	  	var colsBody = document.getElementById('cols_body');
	  	var filtersBody = document.getElementById('filters_body');
	  	var msrsBody = document.getElementById('msrs_body');
  		rowsBody.style.height = (intendedY-30)+'px';
  		colsBody.style.height = (intendedY-30)+'px';
  		msrsBody.style.height = (intendedY-30)+'px';
  		filtersBody.style.height = (intendedY-30)+'px';
		// - WAL194
		
		zenPage.adjustSizes();
		
		return intendedY;
	}
	return(0);
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes(load) [ Language = javascript ]
{
	var tree = zen('groupTree');
	var divTree = tree.getEnclosingDiv();

	var treeWrap = zen('treeWrapper');
	var divTreeWrap = treeWrap.getEnclosingDiv();
	var treeHeader = zen('cubeName');
	var divTreeHeader = treeHeader ? treeHeader.getEnclosingDiv() : null;

	var table = zen('table');
	var divTable = table.getEnclosingDiv();

	var ctrl = zen('pivotController');
	var divCtrl = ctrl.getEnclosingDiv();

	var filterGroup = zen('filterGroup');
	var divFilterGroup = filterGroup ? filterGroup.getEnclosingDiv() : null;

	// show tree (based on mode)
	var dimTree = zen('dimTree').getEnclosingDiv();
	var dimTreeQMSR = zen('dimTreeQMSR').getEnclosingDiv();
	var dimTreePivot = zen('dimTreePivot').getEnclosingDiv();
	var dimTreeFields = zen('dimTreeListingFields').getEnclosingDiv();

	switch (this.treeMode) {
	case 'qmsrs':
		dimTree.style.display = 'none';
		dimTreeQMSR.style.display = 'block';
		dimTreePivot.style.display = 'none';
		dimTreeFields.style.display = 'none';
		break;
	case 'pivots':
		dimTree.style.display = 'none';
		dimTreeQMSR.style.display = 'none';
		dimTreePivot.style.display = 'block';
		dimTreeFields.style.display = 'none';
		break;
	case 'fields':
		dimTree.style.display = 'none';
		dimTreeQMSR.style.display = 'none';
		dimTreePivot.style.display = 'none';
		dimTreeFields.style.display = 'block';
		break;
	case '':
	default:
		dimTree.style.display = 'block';
		dimTreeQMSR.style.display = 'none';
		dimTreePivot.style.display = 'none';
		dimTreeFields.style.display = 'none';
		break;
	}

	// find size of window
	var winHeight = zenGetWindowHeight();
	var winWidth = zenGetWindowWidth();
	var th = this.getTitleAreaHeight();

	// we need these commands or Chrome will make the title area too big
	// when initially displayed (on this page only!!!)
	// (which is kind of disappointing)
	var tdiv = zen('title').getEnclosingDiv();
	tdiv.style.width = winWidth + 'px';

	var tdiv = zen('toolRibbon').getEnclosingDiv();
	tdiv.style.width = winWidth + 'px';

	var cwid = winWidth - (25 + divTree.offsetWidth);
	cwid = (cwid>0)?cwid:0;

	divCtrl.style.width = cwid + 'px';
	var fgHgt = 0;
	if (divFilterGroup) {
		divFilterGroup.style.width = (cwid-2) + 'px';
		fgHgt = divFilterGroup.offsetHeight;
	}

	var h = winHeight - (25 + th);
	var phgt = h - divCtrl.offsetHeight - fgHgt;
	phgt = (phgt>0)?phgt:0;

	if (divTable && divTree) {
		var svg = zen('svg');
		var svgDiv = svg.getEnclosingDiv();

		var legend = zen('chartLegend');
		var legendDiv = legend ? legend.getEnclosingDiv() : null;

		var chart = zen('chart1');
		var svgWid = 0;
		var svgHgt = 0;
		var pivotWid = 0;
		var legwid = 0;

		// pick up chart colors
		if (chart) {
			if (zenPage.chartSeriesScheme && zenPage.chartSeriesScheme!=='') {
				chart.seriesColorScheme = zenPage.chartSeriesScheme;
				chart.seriesColors = '';
			}
			if (zenPage.chartSeriesColors && zenPage.chartSeriesColors!=='') {
				chart.seriesColors = zenPage.chartSeriesColors;
			}
		}

		var scount = table.getDimSize(2);

		switch(this.currViewMode) {
		case 'pivot':
			divTable.style.display = 'block';
			svgDiv.style.visibility = 'hidden';
			if (legendDiv) {
				legendDiv.style.visibility = 'hidden';
			}
			pivotWid = cwid-2;
			break;
		case 'chart':
			divTable.style.display = 'none';
			svgDiv.style.visibility = 'visible';
			if (legendDiv) {
				legendDiv.style.visibility = 'visible';
				legendDiv.style.height = phgt + 'px';
				legwid = legendDiv.offsetWidth + 2;
			}
			pivotWid = 0;
			svgHgt = phgt;
			svgWid = cwid - legwid;
			break;
		case 'both':
			divTable.style.display = 'block';
			svgDiv.style.visibility = 'visible';
			if (legendDiv) {
				legendDiv.style.visibility = 'visible';
				legendDiv.style.height = phgt + 'px';
				legwid = legendDiv.offsetWidth + 2;
			}
			svgHgt = phgt;
			svgWid = (cwid / 2) - legwid;
			pivotWid = ((cwid - svgWid -legwid)>0) ? (cwid - svgWid -legwid) : 0;
			break;
		}

		svg.setProperty('height',svgHgt);
		svg.setProperty('width',svgWid);

		if (chart) {
			var chartWid = svgWid;
			var chartHgt = svgHgt-10;

			if (this.multiChart) {
				chartWid = chartWid / scount;
				chart.seriesNumber = 0;
			}
			else {
				chart.seriesNumber = '';
			}
			
			// JMD1462: optimize chart size
			if ((chartHgt>0 && chart.height!=chartHgt) ||
				(chartWid>0 && chart.width!=chartWid)) {

				chart.setSize(chartWid,chartHgt);
				// notify parent
				if (chart.parent) {
					chart.parent.layoutChildren();
				}
			}

			if (this.currViewMode!='pivot') {
				this.createChartsForSeries();
				// show chart if hidden
				if (chart.hidden) {
					chart.setProperty('hidden',false);
					chart.render();
				}
			}
			else {
				chart.setProperty('hidden',true);
			}

		}

		divTable.style.width = ((pivotWid>0)?pivotWid:0) + 'px';
		divTable.style.height = phgt + 'px';
		divTree.style.height = ((h>0?h:0)+1) + 'px';
		divTreeWrap.style.width = divTree.offsetWidth-2 + 'px';

		var dthoh = divTreeHeader ? divTreeHeader.offsetHeight : 0;
		divTreeWrap.style.height = ((((h - dthoh)>0)?(h - dthoh):0)+1) + 'px';

		table.adjustTableLayout();
	}
	
	// + WAL176
	var ctrl = zen('pivotController');
	var divPivot = ctrl.findElement('pivotColumns');
	
	// Position resize bars
	this.handle = [];
	var o = {};
	o.div = document.getElementById("col_1_2");
	o.pos = 0;
    ZLM.registerDragItem(o.div,this);
	this.handle[0] = o;
	
	var o = {};
	o.div = document.getElementById("col_2_3");
    ZLM.registerDragItem(o.div,this);
	o.pos = 0;
	this.handle[1] = o;
	
	var o = {};
	o.div = document.getElementById("col_3_4");
    ZLM.registerDragItem(o.div,this);
	o.pos = 0;
	this.handle[2] = o;
	
	var o = {};
	o.div = document.getElementById("bottomResize");
    ZLM.registerDragItem(o.div,this);
	o.pos = 0;
	this.handle[3] = o;
	
	if (load && load==true) {
		this.positionResizeHandles(true);
	}
	else {
		this.positionResizeHandles(false);	
	}
	// - WAL176

	self.document.body.style.visibility = 'visible';
}

/// Return the current chart, if any.
ClientMethod getCurrentChart() [ Language = javascript ]
{
	return zen('chart1');
}

/// Return the current pivot table.
ClientMethod getPivot() [ Language = javascript ]
{
	return zen('table');
}

/// Get the type of the current chart.
ClientMethod getChartType() [ Language = javascript ]
{
	var type = '';
	var chart = this.getCurrentChart();
	if (null==chart) return '';

	switch(chart._type) {
	case 'barChart':
		if (chart.getProperty('chartPivot')) {
			if (chart.getProperty('chartStacked')) {
				type = 'StackedColumnChart';
			}
			else {
				type = 'ColumnChart';
			}
		}
		else {
			if (chart.getProperty('chartStacked')) {
				type = 'StackedBarChart';
			}
			else {
				if (chart.getProperty('appearance')=='3D') {
					type = 'BarChart3D';
				}
				else {
					type = 'BarChart';
				}
			}
		}
		break;
	case 'lineChart':
		if (chart.getProperty('chartFilled')) {
			type = 'AreaChart';
		}
		else {
			if (chart.getProperty('markersVisible')) {
				type = 'LineChartMarker';
			}
			else {
				type = 'LineChart';
			}
		}
		break;
	case 'comboChart':
		type = 'comboChart';
		break;
	case 'xyChart':
		type = 'XYChart';
		break;
	case 'hilowChart':
		type = 'HiLowChart';
		break;
	case 'pieChart':
		if (parseFloat(chart.getProperty('holeSize'))>0) {
			if (chart.getProperty('appearance')=='3D') {
				type = 'DonutChart3D';
			}
			else {
				type = 'DonutChart';
			}
		}
		else {
			if (chart.getProperty('appearance')=='3D') {
				type = 'PieChart3D';
			}
			else {
				type = 'PieChart';
			}
		}
		break;
	case 'swirlChart':
		type = 'SwirlChart'; // JSL4277
		break;
	}
	
	
	
	return type;
}

/// Get the grid type of the current chart.
ClientMethod getGridType() [ Language = javascript ]
{
	var type = 'NoGrid';
	var chart = this.getCurrentChart();
	if (null==chart) return type;

	var yMajor = true;
	var yMinor = false;
	var xMajor = false;
	var xMinor = false;

	if (chart.yAxis) {
		yMajor = chart.yAxis.majorGridLines;
		yMinor = chart.yAxis.minorGridLines;
	}
	if (chart.xAxis) {
		xMajor = chart.xAxis.majorGridLines;
		xMinor = chart.xAxis.minorGridLines;
	}

	if (yMinor && xMajor) {
		type = 'YMinorXMajor';
	}
	else if (yMajor && xMajor) {
		type = 'YMajorXMajor';
	}
	else if (yMinor && !xMajor) {
		type = 'YMinor';
	}
	else if (yMajor && !xMajor) {
		type = 'YMajor';
	}
	
	return type;
}

/// Apply the chart dialog options to the current chart.
ClientMethod setChartOptions(type, grid, textSize, title, min, max) [ Language = javascript ]
{
	if (''==type) return;
	var chart = this.getCurrentChart();
	if (null==chart) return;
	var newType = '';
	var svg = zen('svg');

	// make sure correct chart is in place
	switch(type) {
	case 'BarChart':
	case 'BarChart3D':
	case 'ColumnChart':
	case 'StackedBarChart':
	case 'StackedColumnChart':
		newType = 'barChart';
		break;
	case 'LineChart':
	case 'LineChartMarker':
	case 'AreaChart':
		newType = 'lineChart';
		break;
	case 'HiLowChart':
		newType = 'hilowChart';
		break;
	case 'XYChart':
		newType = 'xyChart';
		break;
	case 'ComboChart':
		newType = 'comboChart';
		break;
	case 'PieChart':
	case 'PieChart3D':
	case 'DonutChart':
	case 'DonutChart3D':
		newType = 'pieChart';
		break;
	case 'SwirlChart':
		newType = 'swirlChart';	// JSL4277
		break;
	default:
		alert('Unhandled type(1) in setChartType: ' + type);
		return;
	}

	if (newType != chart._type) {
		var newChart = zenPage.createComponent(newType);
		newChart.setProperty('controllerId',chart.controllerId);
		newChart.setProperty('width',chart.width);
		newChart.setProperty('height',chart.height);

		// copy over other settings
		newChart.appearance = chart.appearance;
		newChart.legendVisible= chart.legendVisible;
		newChart.titleStyle = chart.titleStyle;
		newChart.titleBoxStyle = chart.titleBoxStyle;
		newChart.borderRadius = chart.borderRadius;
		newChart.borderStyle = chart.borderStyle;
		newChart.plotAreaStyle = chart.plotAreaStyle;
		newChart.plotEdgeStyle = chart.plotEdgeStyle;
		newChart.selectedItemStyle = chart.selectedItemStyle;
		newChart.selectedItemStyle = chart.selectedItemStyle;
		newChart.title = chart.title;
		newChart.legendTitle = chart.legendTitle;
		newChart.stripesVisible = chart.stripesVisible;
		newChart.stripeStyle = chart.stripeStyle;
		newChart.seriesColors = chart.seriesColors;
		newChart.seriesColorScheme = chart.seriesColorScheme;
		newChart.seriesNames = chart.seriesNames;
		newChart.markerScale = chart.markerScale;
		newChart.gridStyle = chart.gridStyle;
		newChart.bandUpper = chart.bandUpper;
		newChart.bandUpperStyle = chart.bandUpperStyle;
		newChart.bandLower = chart.bandLower;
		newChart.bandLowerStyle = chart.bandLowerStyle;

		newChart.marginRight = chart.marginRight;
		newChart.marginLeft = chart.marginLeft;
	
		if (chart.xAxis) {
			newChart.xAxis = chart.xAxis;
		}
		if (chart.yAxis) {
			newChart.yAxis = chart.yAxis;
		}

		svg.addChild(newChart);
		svg.removeChild(chart);
		newChart.setProperty('id',chart.id);
		chart = newChart;
	}

	if ('' != textSize) {
		chart.textSize = textSize;
	}

	// apply chart parameters
	chart.appearance = '2D';
	chart.showMultiples = false;

	switch(type) {
	case 'BarChart':
		chart.chartPivot = false;
		chart.chartStacked = false;
		chart.plotToEdge = false;
		break;
	case 'BarChart3D':
		chart.appearance = '3D';
		chart.chartPivot = false;
		chart.chartStacked = false;
		chart.plotToEdge = false;
		break;
	case 'ColumnChart':
		chart.chartPivot = true;
		chart.chartStacked = false;
		chart.plotToEdge = false;
		break;
	case 'StackedBarChart':
		chart.chartPivot = false;
		chart.chartStacked = true;
		chart.plotToEdge = false;
		break;
	case 'StackedColumnChart':
		chart.chartPivot = true;
		chart.chartStacked = true;
		chart.plotToEdge = false;
		break;
	case 'LineChart':
		chart.markersVisible = false;
		chart.chartPivot = false;
		chart.chartStacked = false;
		chart.chartFilled = false;
		chart.plotToEdge = true;
		break;
	case 'LineChartMarker':
		chart.markersVisible = true;
		chart.chartPivot = false;
		chart.chartStacked = false;
		chart.chartFilled = false;
		chart.plotToEdge = false; // JSL4486
		break;
	case 'AreaChart':
		chart.markersVisible = false;
		chart.chartPivot = false;
		chart.chartStacked = true;
		chart.chartFilled = true;
		chart.plotToEdge = true;
		break;
	case 'HiLowChart':
		chart.markersVisible = false;
		chart.chartPivot = false;
		chart.plotToEdge = false;
		break;
	case 'ComboChart':
		chart.markersVisible = true;
		chart.chartPivot = false;
		chart.plotToEdge = false;
		break;
	case 'XYChart':
		chart.markersVisible = true;
		chart.chartPivot = false;
		chart.plotToEdge = true;
		break;
	case 'PieChart':
		chart.holeSize = 0;
		chart.marginLeft = 0;
		chart.showMultiples = true;
		chart.labelsVisible = false;
		chart.pieScale = 1.5;
		break;
	case 'PieChart3D':
		chart.holeSize = 0;
		chart.appearance = '3D';
		chart.marginLeft = 0;
		chart.showMultiples = true;
		chart.labelsVisible = false;
		chart.pieScale = 1.5;
		break;
	case 'DonutChart':
		chart.holeSize = 0.25;
		chart.marginLeft = 0;
		chart.showMultiples = true;
		chart.labelsVisible = false;
		chart.pieScale = 1.5;
		break;
	case 'DonutChart3D':
		chart.holeSize = 0.25;
		chart.appearance = '3D';
		chart.marginLeft = 0;
		chart.showMultiples = true;
		chart.labelsVisible = false;
		chart.pieScale = 1.5;
		break;
	case 'SwirlChart':
		// JSL4277
		chart.animate = 'none';
		break;
	default:
		alert('Unhandled type in setChartType: ' + type);
		break;
	}

	// grid
	if (null == chart.yAxis) {
		var axis = zenPage.createComponent('axis');
		chart.yAxis = axis;
	}
	if (null == chart.xAxis) {
		var axis = zenPage.createComponent('axis');
		chart.xAxis = axis;
	}
	chart.yAxis.majorGridLines = false;
	chart.yAxis.minorGridLines = false;
	chart.xAxis.minorGridLines = false;
	chart.xAxis.majorGridLines = false;

	switch(grid) {
	case 'NoGrid':
		break;
	case 'YMajor':
		chart.yAxis.majorGridLines = true;
		break;
	case 'YMinor':
		chart.yAxis.majorGridLines = true;
		chart.yAxis.minorGridLines = true;
		break;
	case 'YMajorXMajor':
		chart.yAxis.majorGridLines = true;
		chart.xAxis.majorGridLines = true;
		break;
	case 'YMinorXMajor':
		chart.yAxis.majorGridLines = true;
		chart.yAxis.minorGridLines = true;
		chart.xAxis.majorGridLines = true;
		break;
	default:
		alert('Unhandled grid style in setChartType: ' + grid);
		break;
	}

	// title
	chart.title = title;

	// range
	chart.yAxis.minValue = min;
	chart.yAxis.maxValue = max;
	chart.xAxis.minValue = min;
	chart.xAxis.maxValue = max;

	// apply changes
	chart.hzZoomStep = 0;
	chart.scrollLeft = 0;
	chart.render();

	this.createChartsForSeries();
}

/// This class method callback is called just before the server-side page 
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..sessionCookie = %session.CSPSessionCookie

		//Set tSC = ##super()
		//If $$$ISERR(tSC) Quit

		// check privileges
		Do CheckAnalyzerUseAccess^%qdsUtils()
		$$$dsTrackFeature("Analyzer")		// DTB393

		// use new analysis dialog?
		If $$$comClassDefined("%DeepSee.UI.Dialog.PivotAnalysis") {
			Set ..hasAnalysis = 1
		}

		If (+..isEmbedded) {
			// set other properties unless user has set them
			Set:..noTitle="" ..noTitle = 1
		}

		If (+..noTitle) {
			Set ..%GetComponentById("title").hidden = 1
			Set ..%GetComponentById("mainMenu").hidden = 1
			Set %response.Context("NOTITLE") = 1
		}

		// pdf enabled?
		If $$$comClassDefined("%DeepSee.UI.MDXPDF") {
			Set ..hasPDF = 1
		}

		#; register visit
		Set tSC = ..%Register()
		If $$$ISERR(tSC) Quit

		Set tWrite = $$CheckAnalyzerWriteAccess^%qdsUtils()
		If ('tWrite) {
			Set ..canWrite = 0
		}
		Set ..readOnly = 0

		// override menu logic
		Set %page.aboutPage = ##class(%CSP.Page).Link("_CSP.UI.Portal.About.cls")

		// tLinks is an array of menu options
		Set tSC = ..GetContextLinks(.tLinks)
		If $$$ISERR(tSC) Quit

		Set menuHolder = ..%GetComponentById("menuHolder")
		If $IsObject(menuHolder) {
			Set item = $O(tLinks(""))
	 		While (item'="") {
		 		Set tCaption = $LG(tLinks(item),1)
		 		Set tURL = $LG(tLinks(item),2)
		 		Set tJS = $LG(tLinks(item),3)
		 		Set tTitle = $LG(tLinks(item),4)
		 		If (tCaption="") {
					Set tOption = ##class(%ZEN.Component.csMenuSeparator).%New()
		 		}
		 		Else {
					Set tOption = ##class(%ZEN.Component.csMenuItem).%New()
					Do ..%AddComponent(tOption)
					Set tOption.caption = tCaption
					Set tOption.title = tTitle
			 		If (tJS'="") {
				 		Set tOption.onclick = tJS
			 		}
			 		Else {
						// make a link
						Set tOption.onclick = "zenPage.goMenu('"_##class(%CSP.Page).Link(tURL)_"');"
			 		}
		 		}
				Do menuHolder.%AddChild(tOption)
		 		Set item = $O(tLinks(item))
	 		}
		}

		If (..#USERMODE) {
			Set ..homePage = ##class(%DeepSee.UserPortal.Utils).%GetUserHomePageURL()

			Set tMailEnabled = +$G(^DeepSee.UserPortalSettings("MailEnabled"))
			// set flag to indicate how email is sent
			If (tMailEnabled = 2) {
				Set ..useClientEmail = 1
			}
			Else {
				Set ..useClientEmail = 0
			}
		}

		Set tTable = ..%GetComponentById("table")

		// + WAL053
		If (($$$UPPER(..autosave) = "$USERNAME")) { Set ..autosave = $UserName }
		If ((..autosave = "") && ($G(^DeepSee.UserPortalSettings("autosaveAnalyzer")))) {
			Set ..autosave = $UserName
		}
		Set tTemp = 1
		If ((..autosaveOverride '= "") && (..autosave '= "")) {
			If (..autosaveOverride > $G(^DeepSee.Autosave(..autosave))) { Set tTemp = 0}
		}
		Set tTempExists = 0
		If ((..autosave'="") && tTemp) {
			Set tTempPivotPrefix = ..tempStorageRoot _ ..autosave _ "/"
			If (..pivotName = "") {
				Set tTempPivotName = ""
				Set tLastFolder = ..tempStorageRoot _ "Last/" _ ..autosave
				// should only be one subfolder
				Set tSC = ##class(%DeepSee.UserLibrary.Utils).%GetSubFolderList(.tLastSubFolderList,tLastFolder)
				Set tLastSubFolder = $G(tLastSubFolderList(1))
				// For empty pivot
				If (tLastSubFolder = "") { Set tLastSubFolder = tLastFolder  Set tEmptyPivot = 1}
				If (tLastSubFolder '= "") {
					Set tSC = ##class(%DeepSee.UserLibrary.Utils).%GetFolderItemList(.tLastItemList,tLastSubFolder)
					// Should only be one item in the folder
					Set tLastItemId = $G(tLastItemList(1))
					If (tLastItemId '= "") {
						Set tTempPivot = ##class(%DeepSee.UserLibrary.FolderItem).%OpenId(tLastItemId)
						If $IsObject(tTempPivot) {
							Set tTempPivotName = tTempPivot.fullName	
							Set tName = $p(tTempPivot.fullName,tLastFolder_"/",2)
							If (tName '= ..autosave_".pivot") { 
								If ($G(tEmptyPivot)) { Set ..pivotName = "" }
								Else { Set ..pivotName = tName }
							}
						}
					}
				}
			}
			Else {
				Set tTempPivotName = tTempPivotPrefix _ ..pivotName	
			}
			// Check to see if there is a temp storage item with that name
			Set tTempExists = ##class(%DeepSee.UserLibrary.Utils).%FolderItemExists(tTempPivotName)
			If (tTempExists) {
				Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(tTempPivotName,.tSC)
				If $$$ISERR(tSC) Quit
				If $IsObject(tPivot) {
					Set ..cubeFullName = tPivot.cubeName _ $S((##class(%DeepSee.Utils).%GetBaseCube(tPivot.cubeName)=""):".cube",1:".subjectArea")	// DTB318
					Set ..pivotDescription = tPivot.description
					Set ..pivotKeywords = tPivot.keywords
					Set ..pivotCategory = tPivot.category
					Set ..pivotLocked = tPivot.locked
					Set ..pivotPublic = tPivot.public
					Set ..pivotResource = tPivot.resource
					Set ..pivotOwner = tPivot.owner
					Set ..previewMode = tPivot.previewMode		// DTB701

					Set tSC = tPivot.%CopyToComponent(tTable)
					If $$$ISERR(tSC) Quit

					// test for write access
					If ((..pivotResource'="")&&'$System.Security.Check(..pivotResource,"WRITE")) {
						Set ..readOnly = 1
					}
				}
				Else {
					Set ..pivotName = ""
				}
			}		
		}
		If (..pivotName'="" && 'tTempExists) {
		// - WAL053
			Set tPivot = ##class(%DeepSee.UserLibrary.Utils).%OpenFolderItem(..pivotName,.tSC)
			If $$$ISERR(tSC) Quit
			If $IsObject(tPivot) {
				Set ..pivotName = tPivot.fullName
				Set ..cubeFullName = tPivot.cubeName _ $S((##class(%DeepSee.Utils).%GetBaseCube(tPivot.cubeName)=""):".cube",1:".subjectArea")	// DTB318
				Set ..pivotDescription = tPivot.description
				Set ..pivotKeywords = tPivot.keywords
				Set ..pivotCategory = tPivot.category
				Set ..pivotLocked = tPivot.locked
				Set ..pivotPublic = tPivot.public
				Set ..pivotResource = tPivot.resource
				Set ..pivotOwner = tPivot.owner
				Set ..previewMode = tPivot.previewMode		// DTB701

				Set tSC = tPivot.%CopyToComponent(tTable)
				If $$$ISERR(tSC) Quit

				// test for write access
				If ((..pivotResource'="")&&'$System.Security.Check(..pivotResource,"WRITE")) {
					Set ..readOnly = 1
				}

				Set tSC = ##class(%DeepSee.UserLibrary.Utils).%RegisterRecentItem("pivot",tPivot.fullName)
				If $$$ISERR(tSC) Quit
			}
			Else {
				Set ..pivotName = ""
			}
		}
		Set tTable.name = ..pivotName		// DTB308 - Make sure the component understands the name
		
		// + WAL053 -- don't reuse override on refresh
		If ((..autosaveOverride '= "")&&(..autosave'="")) { Set ^DeepSee.Autosave(..autosave) = ..autosaveOverride}
		// - WAL053


		If (..cubeFullName="") {
			Set ..cubeFullName = $G(^DeepSee.LastCube($UserName))
		}

		// Strip off extension from name
		Set tExt = $P(..cubeFullName,".",$L(..cubeFullName,"."))
		If ((tExt = "cube")||(tExt = "subjectArea")) {
			Set tName = $P(..cubeFullName,".",1,$L(..cubeFullName,".")-1)
			Set ..cubeName = tName
		}
		Else {
			Set tExt = "cube"
			Set ..cubeName = ..cubeFullName
		}

		If ('##class(%DeepSee.Utils).%CubeExists(..cubeName, .tSC)) {
			// swallow the error
			Set tSC = $$$OK
			Set ..cubeName = ""
			Quit
		}
		Else {
			// Get original case of cube name
			Set ..cubeName = ##class(%DeepSee.Utils).%GetCubeName(..cubeName,.tSC)
		}

		Set ^DeepSee.LastCube($UserName) = ..cubeFullName
		If ($G(%request.Data("home",1))'="") {
			Set %response.Context("home") = %request.Data("home",1)
		}

		// test if listings are allowed
		Set tTable.listingEnabled = 0
		If (..cubeName'="") {
			Set tCubeClass = ##class(%DeepSee.Utils).%GetCubeClass(..cubeName,.tSC)
			If $$$ISERR(tSC) Quit
			Set tTable.listingEnabled = $classmethod(tCubeClass,"%CanDrillThrough")

			// JMD1034 Get actions if any
			Set tSC = $classmethod(tCubeClass,"%GetActionList",.tActionList)
			If $$$ISERR(tSC) Quit
			Set k = $O(tActionList(""))
			While (k'="") {
				Do ..actionNames.Insert($LG(tActionList(k),1))
				Do ..actionCaptions.Insert($LG(tActionList(k),2))
				Set k = $O(tActionList(k))
			}
			If ($IsObject(tTable)&&$D(tActionList)) {
				Set tTable.listingSelect = "multi"
			}
	
			// test if user can select custom listing fields
			If (tTable.listingEnabled) {
				Kill tList
				Set tSC = ##class(%DeepSee.Utils).%GetCubeListingFields(..cubeName,.tList)
				If $$$ISERR(tSC) Quit

				If $D(tList) {
					Set tTable.canUseListingFields = 1
				}
				Set tParm = ..%GetComponentById("plistingdListingFields")
				Set tParm.value = tTable.listing
			}
			
			// DTB723 - Determine the %SQLRESTRICT support for this cube
			Set ..cubeSupportsSqlRestrict = $D($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cubeName),"mbr#",-1))
		}

		// create filter controls
		If ($IsObject(tTable)) {
			Set tGroup = ..%GetComponentById("filterGroup")
			If ($IsObject(tGroup)) {
				Set tSC = ..%CreateFilterControls(..cubeName,tGroup,tTable)
				If $$$ISERR(tSC) Quit
			}
		}
		
		// set auto exec off if asked to
		If ($IsObject(tTable)) {
			If (tTable.autoExecute=0) {
				// JMD1025
				Set tTable.initialExecute = 0
				Set tTable.changesPending = 1
			}
			Else {
				Set tTable.autoExecute = +..autoExec
				Set tTable.initialExecute = +..autoExec
				Set tTable.changesPending = '..autoExec
			}
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
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Do the actual work of updating the view to match the current view mode.
ClientMethod setViewModeHandler(mode) [ Language = javascript ]
{
	this.adjustSizes();
	var table = this.getPivot();
	table.executeQuery();
}

/// User has clicked on a chart element.
ClientMethod chartElementClick(chart) [ Language = javascript ]
{
	var series = chart.getSelectedSeries();
	var item = chart.getSelectedItem();

	if (!isNaN(parseInt(series)) && !isNaN(parseInt(item))) {
		// set selected range in pivot to match
		var table = this.getPivot();
		table.selectCellRange(item+1,series+1,item+1,series+1);
	}
}

/// User has selected a new element in the tree control.
ClientMethod treeChange(tree) [ Language = javascript ]
{
	// change style of delete calculated member icon.
	var icon = self.document.getElementById('iconDelCalc');
	var cls = 'dsptIconDisabled';
	var text = tree.getNodeText(tree.selectedIndex);
	var value = tree.getNodeValue(tree.selectedIndex);
	
	if (this.treeMode=='fields') {
		// listing
		if (value.toString().substr(0,11)=='$$$LISTING:') {

			var pivot = this.getPivot();

			var t = value.toString().split(':');
			t.splice(0,1);
			pivot.listing = t.join(':');

			if (pivot.isDrillThrough) {
				pivot.executeQuery(pivot.autoExecute);
			}
		}
		return;
	}

	if (value && '' != value) {
		// see if this item is a calculated member or a named filter (or variable)
		var itemNo = this.isCalculatedMember();
		if (itemNo !== '') {
			cls = 'dsptIcon';
		}
		else if (this.isNamedFilter()!=='') {
			cls = 'dsptIcon';
		}
		else if (this.isPivotVariable()!=='') {
			cls = 'dsptIcon';
		}
	}
	icon.className = cls;
}

/// Delete the selected Calculated Member, named filter, or pivot variable.
ClientMethod deleteCalculatedMember(force) [ Language = javascript ]
{
	force = (force) ? force : 0;		// DTB334 - Add force parameter to suppress confirmation dialog
	if (!this.canUserModify()) {
		return;
	}
	// see if this item is a calculated member
	var itemNo = this.isCalculatedMember();
	if (itemNo !== '') {
		var name = '';
		var tree = zen('dimTree');
		var idx = tree.getSelectedIndex();
		if (idx >= 0) {
			name = tree.getNodeText(idx);
		}
		if ((!force) && (!confirm($$$FormatText($$$Text('Do you wish to delete the calculated member %1?'),name)))) {
			return;
		}
		if (itemNo>=0) {		// DTB308 - A valid array index indicates a local calc member
			var table = this.getPivot();
			table.calculatedMembers.splice(itemNo,1);
			this.savePivot(false);
			this.updateMemberTree();
			table.executeQuery(true);
		}
		else {
			// DTB268 - A negative index indicates a shared calculated member
			var val = tree.getNodeValue(idx);
			var dim = val.split('.')[1];
			var name = val.split(dim + '.')[1];		// DTB733 - Use everything after the dimension as the member name
			
			msg = this.DeleteSharedCalcMember(this.cubeName,name,dim);
			if (''!=msg) {
				alert(msg);
			}
			this.updateMemberTree();
		}
	}
	else {
		var fname = this.isNamedFilter();
		if (''!=fname) {
			if ((!force) && (!confirm($$$FormatText($$$Text('Do you wish to permanently delete the named filter %1?'),fname)))) {		// DTB334 - Add force
				return;
			}
			var table = this.getPivot();
			var msg = this.DeleteNamedFilter(table.cubeName,fname);
			if (''!=msg) {
				alert(msg);
			}
			this.updateMemberTree();
		}
		else {
			var vname = this.isPivotVariable();
			if (''!=vname) {
				if ((!force) && (!confirm($$$FormatText($$$Text('Do you wish to permanently delete the pivot variable %1?'),vname)))) {		// DTB334 - Add force
					return;
				}
				var table = this.getPivot();
				var msg = this.DeletePivotVariable(table.cubeName,vname);
				if (''!=msg) {
					alert(msg);
				}
				this.updateMemberTree();
			}
		}
	}
}

/// User has double-clicked on an element in the tree control.
ClientMethod treeDoubleClick(tree) [ Language = javascript ]
{
	var prevCanDrillDown = zenPage.getPivot().canDrillDown;
	var text = tree.getNodeText(tree.selectedIndex);
	var value = tree.getNodeValue(tree.selectedIndex);
	if (value && '' != value) {
		// check for special relationship marker
		if (value.toString().substr(0,2)=='@@') {
			return;
		}

		var filterChanged = false;

		var pivot = this.getPivot();
		if (pivot) {
			// check for custom listing field marker
			// listing
			if (value.toString().substr(0,11)=='$$$LISTING:') {
				return;
			}
			else if (value.toString().substr(0,9)=='$$$FIELD:') {
				pivot.listing = '$$$CUSTOM';

				var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
				pivot.listingFields[pivot.listingFields.length] = parm;
				var t = value.toString().split(':');
				t.splice(0,1);							// Remove the $$$FIELD token
				var fieldExpr = t.splice(0,1)[0];		// DTB309 - The field expression cannot contain the ':' character, so it will now be the first piece
				value = '$$$FIELD:'+t.join(':');		// DTB309 - Remaining is the name, which may contain ':'. Replace the $$$FIELD token in front
				pivot.listing = '$$$CUSTOM';

				parm.spec = fieldExpr;					// Field expression for building the custom SQL query
				parm.value = value;						// DTB309 - Logical value. Store for lookup in other locales
				parm.text = text;						// Current display value
				if (pivot.controller) {
					pivot.controller.updateState('fields');
				}
				if (pivot.isDrillThrough) {
					pivot.executeQuery(pivot.autoExecute);
				}
				return;
			}

			pivot.pushState();
			var isNamedFilter = (value == '%FILTER');
			var isMsr = (value.toUpperCase().indexOf('[MEASURES]') > -1);		// DP-427812
			if (isNamedFilter) {
				// append
				var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
				pivot.filters[pivot.filters.length] = parm;

				parm.spec = value;
				parm.text = text;
				parm.advanced = true;
			}
			else if (isMsr) {
				// append
				var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
				pivot.measures[pivot.measures.length] = parm;

				parm.spec = (value.indexOf('%SHAREDCALC')>-1) ? value.slice(12) : value;		// DP-427812
				parm.text = text;
			}
			else {
				if (pivot.rowLevels.length == 0) {
					// append
					var parm = zenPage.createComponentNS('http://www.intersystems.com/deepsee','pivotLevel');
					pivot.rowLevels[pivot.rowLevels.length] = parm;
				}
				else {
					var parm = pivot.rowLevels[pivot.rowLevels.length-1];
				}
				if (value.toString().toLowerCase().substr(0,10)=='$variable.') {
					// JMD1276
					filterChanged = true;
					parm.levelType = 'mdx';
					parm.value = value;
				}
				
				parm.spec = value;
				parm.text = text;
				if (value.toString().toLowerCase().substr(0,10)=='$variable.') {
					filterChanged = true;
				}
			}
			parm.drillLevel = pivot.getDrillLevel();
			if (pivot.isDrillThrough) {
				pivot.mdx = '';
				pivot.isDrillThrough = false;
			}
			if (filterChanged) {
				var msg = zenPage.UpdateFilterControls(pivot.cubeName,zen('filterGroup'),pivot);
				if (''!==msg) {
					alert(msg);
				}
			}

			pivot.selectedRange = '';
			pivot.executeQuery(pivot.autoExecute);
		}
	}
	zenPage.getPivot().canDrillDown = prevCanDrillDown;
}

/// User has selected a new element in the pivot tree control.
ClientMethod pivotTreeChange(tree) [ Language = javascript ]
{
	var text = tree.getNodeText(tree.selectedIndex);
	var value = tree.getNodeValue(tree.selectedIndex);

	if (value && '' != value) {
		value += '.pivot';
		var table = this.getPivot();
		var exec = '';
		if (!table.autoExecute) {
			// pass autoexec setting to next pivot
			exec = '&EXEC=0';
		}
		self.document.location = zenLink(this.analyzerURL + '?PIVOT=' + encodeURIComponent(value) + exec);
	}
}

/// User has double-clicked on an element in the pivot tree control.
ClientMethod pivotTreeDoubleClick(tree) [ Language = javascript ]
{
	var text = tree.getNodeText(tree.selectedIndex);
	var value = tree.getNodeValue(tree.selectedIndex);
}

/// Zen page notification of an HTTP request. This method can be overwritten
/// by subclasses.<br/>
/// This is called <em>before</em> the standard Zen pre-HTTP processing occurs.
ClassMethod %OnPreHTTP() As %Boolean [ ServerOnly = 1 ]
{
	// remember we are in user mode
	Set tUser = $G(%request.Data("USER",1))
	If (tUser'="") {
		Set %response.Context("USER") = tUser
	}
	Quit 1
}

/// Add include files to support color schemes.
Method %OnDrawHTMLHead() As %Status
{
	// always use simple for Analyzer
	Set tScheme = "simple"
	If (tScheme '= "") {
		// CSS file
		Set tCSSFile = "skin_"_tScheme_".css"
		Write "<link rel=""stylesheet"" type=""text/css"" href="""_tCSSFile_"""/>",!

		// Initializer file for SVG components
		Set tInitFile = "skin_"_tScheme_".js"
		Write "<script type=""text/javascript"" src="""_tInitFile_"""></script>",!
	}
	Quit $$$OK
}

/// Called from client to delete a named filter.
ClassMethod DeleteNamedFilter(pCubeName As %String, pFilterName As %String) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = ##class(%DeepSee.Utils).%DeleteNamedFilter(pCubeName,pFilterName)
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// Called from client to delete a shared calculated member.
ClassMethod DeleteSharedCalcMember(pCubeName, pCalcMbrName, pDimension) As %String [ ZenMethod ]
{
	// Method added by DTB268
	Set tMsg = ""
	
	// Parse the member inputs to remove [] quotes
	Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pCalcMbrName,.tMbrNameInfo)
	Set tCalcMbrName = tMbrNameInfo(1)
	Set tSC = ##class(%DeepSee.Query.Parser).%ParseMemberSpec(pDimension,.tDimInfo)
	Set tDimension = tDimInfo(1)
	
	
	Set tSC = ##class(%DeepSee.Utils).%DeleteSharedCalcMember(pCubeName,tCalcMbrName,tDimension)
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// Called from client to delete a pivot variable.
ClassMethod DeletePivotVariable(pCubeName As %String, pVariableName As %String) As %String [ ZenMethod ]
{
	Set tMsg = ""
	Set tSC = ##class(%DeepSee.Utils).%DeletePivotVariable(pCubeName,pVariableName)
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

/// Called from client to update list of filters.
ClassMethod UpdateFilterControls(pCubeName As %String, pGroup As %ZEN.Component.group, pPivotTable As %DeepSee.Component.pivotTable) As %String [ ZenMethod ]
{
	Set tMsg = ""
	If ($IsObject(pPivotTable)) {
		Set tSC = ..%CreateFilterControls(pCubeName,pGroup,pPivotTable)
		If $$$ISERR(tSC) {
			Set tMsg = $System.Status.GetOneErrorText(tSC)
		}
	}
	Quit tMsg
}

/// Create the set of filter controls along the top of the pivot table.<br/>
/// <var>pGroup</var> is the parent group containing the filter controls.<br/>
/// <var>pPivot</var> is the pivot table supplying the filter definitions.<br/>
ClassMethod %CreateFilterControls(pCubeName As %String, pGroup As %ZEN.Component.abstractGroup, pPivot As %DeepSee.Component.pivotTable = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Do pGroup.%RemoveChildren()

		// JMD1276: find all pivot variable references and create controls for them
		If ($IsObject(pPivot)) {
			Set tSC = ..%FindPivotVariables(pPivot.filters,.tPivotVariables)
			If $$$ISERR(tSC) Quit
			Set tSC = ..%FindPivotVariables(pPivot.columnLevels,.tPivotVariables)
			If $$$ISERR(tSC) Quit
			Set tSC = ..%FindPivotVariables(pPivot.rowLevels,.tPivotVariables)
			If $$$ISERR(tSC) Quit

			Kill tVarList
			Set k = $O(tPivotVariables(""))
			While (k'="") {
				Set tVarName = $P(k,".",2)
				Set tVarList(tVarName) = ""
				Kill tVarInfo
				Set tSC = ##class(%DeepSee.Utils).%GetPivotVariableInfo(pCubeName,tVarName,.tVarInfo)
				Set tVType = $G(tVarInfo("type"),"expression")
				Set tVDefVal = $G(tVarInfo("defaultValue"))

				If ((tVType="expression")||($G(tVarInfo("valueList"))'="")) {
					Set tControl = ##class(%DeepSee.Component.searchBox).%New()
					Set tControl.dataSourceName = pCubeName_".cube"
					Set tControl.filterName = k
					
					Set tValueList = $G(tVarInfo("valueList"))		// DTB569 - Stored as needed for the control
					Set tDisplayList = $G(tVarInfo("displayList"))		// DTB569 - Stored as needed for the control
					
					Set tControl.valueList = tValueList
					Set tControl.displayList = $G(tDisplayList,$G(tValueList))
					//Set tControl.multiSelect = (tVType="expression")		// DTB525 - Turn multiselect off
				}
				ElseIf ((tVType="day")||($G(tVarInfo("sourceType"))="manual")) {
					// JMD1317
					Set tControl = ##class(%DeepSee.Component.searchBox).%New()
					Set tControl.dataSourceName = pCubeName_".cube"
					Set tControl.filterName = k
				}
				Else {
					Set tControl = ##class(%ZEN.Component.text).%New()
					If (tVType'="string") {
						Set tControl.size = 8
					}
				}
				// DTB854 - After initializing the particular control, set the default value
				Set tControl.value = pPivot.pivotVariables.GetAt($$$LOWER(tVarName))
				Set:tControl.value="" tControl.value = tVDefVal

				Set tControl.label = $G(tVarInfo("displayName"))
				Set:tControl.label="" tControl.label = tVarName
				Set tControl.labelStyle = "color:green;"
				Set tControl.onchange = "zenPage.pivotVariableChangeHandler(zenThis,'"_tVarName_"','"_tVType_"');"

				Do pGroup.%AddChild(tControl)
				Set k = $O(tPivotVariables(k))
			}

			// reset pivot run-time values that are not in use
			Set tKey = pPivot.pivotVariables.Next("")
			While (tKey'="") {
				If '$D(tVarList($$$LOWER(tKey))) {
					Do pPivot.pivotVariables.RemoveAt($$$LOWER(tKey))
				}
				Set tKey = pPivot.pivotVariables.Next(tKey)
			}
		}

		If ($IsObject(pPivot) && $IsObject(pPivot.filters)) {
			// get local calc members
			For n = 1:1:pPivot.calculatedMembers.Count() {
				Set tCalcMbr = pPivot.calculatedMembers.GetAt(n)
				If ((tCalcMbr.dimension'="")&&(tCalcMbr.memberName'="")) {
					Set tCalcMbrs($$$UPPER(tCalcMbr.dimension),$$$UPPER(tCalcMbr.memberName)) = $LB(tCalcMbr.dimension,tCalcMbr.memberName)
				}
			}

			Set tFilters = pPivot.filters
			For n = 1:1:tFilters.Count() {
				Set tFilter = tFilters.GetAt(n)
				If (tFilter.enabled=0) {
					Continue
				}
				Set tIsRelation = 0
				If ('tFilter.advanced) {
					Set tFCube = pCubeName
					Set tFSpec = tFilter.spec
					// skip pivot variable (should be marked as advanced)
					If ($$$LOWER($E(tFSpec,1,10))="$variable.") Continue
					Kill tSpecInfo
					Set rc = 0
					While (1) {
						Kill tSpecInfo2
						Set tSC = ##class(%DeepSee.Utils).%GetDimensionInfo(tFCube,tFSpec,.tDimNo,.tHierNo,.tLevelNo,.tRelationName,.tRelationSpec,.tSpecInfo2,.tCalcMbrs)
						If $$$ISERR(tSC) Quit
						If (rc=0) {
							Merge tSpecInfo = tSpecInfo2
						}
						Set rc = rc + 1
						If (tRelationName="") Quit
						Set tIsRelation = tIsRelation + 1
						Set tFCube = ##class(%DeepSee.Utils).%GetRelatedCube(tFCube,tRelationName)
						Set tFSpec = tRelationSpec
					}
					If $$$ISERR(tSC) Quit

					If (($$$UPPER(tFilter.spec)[".MEMBERS")||($$$UPPER(tFilter.spec)[".ALLMEMBERS")) {
						// display a list of options
						Set tMemberSpec = ""
						If (tDimNo = -1) {
							// calculated member
							// JMD1404 get member name for relationship
							If (tIsRelation) {
								Set tMbrName = $G(tSpecInfo(tIsRelation + 1))
							}
							Else {
								Set tMbrName = $G(tSpecInfo(1))
							}
							Set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(tFCube,tMbrName,,,.tCaption)
							If $$$ISERR(tSC) Quit
							Set tFilter.caption = $S(tCaption'="":tCaption,1:tMbrName)		// DTB454 - Protect visual control from having a blank label

							// JMD1404
							If (tIsRelation) {
								Set tMemberSpec = ""
								For r = 1:1:tIsRelation+1 {
									Set tMemberSpec = tMemberSpec _ $S(tMemberSpec="":"",1:".") _ "["_$$$dsEscapeIdent($G(tSpecInfo(r)))_"]"	// DTB087
								}
							}
							Else {
								Set tMemberSpec = "["_$$$dsEscapeIdent(tMbrName)_"]"	// DTB087
							}
						}
						Else {
							Set tSC = ##class(%DeepSee.Utils).%GetDimensionCaption(tFCube,tDimNo,tHierNo,tLevelNo,.tCaption)
							If $$$ISERR(tSC) Quit
							Set tFilter.caption = tCaption

							Set tCount = $O(tSpecInfo(""),-1)
							For t=1:1:tCount-1 {
								Set tMemberSpec = tMemberSpec _ $S(tMemberSpec="":"",1:".") _ "["_$$$dsEscapeIdent(tSpecInfo(t))_"]"	// DTB087
							}
						}

						Set tFilterControls($I(tFilterControls)) = $LB(n,tMemberSpec)
					}
					Else {
						Set tMemberSpec = ""
						// filter on specific member
						If (tDimNo = -2) {
							// JMD1095 named set
							Set tMbrName = $G(tSpecInfo(1))
							Set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(tFCube,"%%NAMEDSETS",tMbrName,,.tCaption)
							If $$$ISERR(tSC) Quit
							Set tFilter.caption = tCaption
							Set tMemberSpec = "["_$$$dsEscapeIdent(tMbrName)_"]"  // DTB087
							Set tFilter.key = ""
						}
						ElseIf (tDimNo = -1) {
							// calculated member
							// JMD1404 get member name for relationship
							If (tIsRelation) {
								Set tMbrName = $G(tSpecInfo(tIsRelation + 1))
							}
							Else {
								Set tMbrName = $G(tSpecInfo(1))
							}
							
							Set tSC = ##class(%DeepSee.Utils).%GetMemberCaption(tFCube,tMbrName,,,.tCaption)
							If $$$ISERR(tSC) Quit
							Set tFilter.caption = tCaption

							// JMD1404
							If (tIsRelation) {
								Set tMemberSpec = ""
								For r = 1:1:tIsRelation+1 {
									Set tMemberSpec = tMemberSpec _ $S(tMemberSpec="":"",1:".") _ "["_$$$dsEscapeIdent($G(tSpecInfo(r)))_"]"	// DTB087
								}
							}
							Else {
								Set tMemberSpec = "["_$$$dsEscapeIdent(tMbrName)_"]"	// DTB087
							}
							Set tCount = $O(tSpecInfo(""),-1)
							Set tFilter.key = tSpecInfo(tCount)
						}
						Else {
							Set tSC = ##class(%DeepSee.Utils).%GetDimensionCaption(tFCube,tDimNo,tHierNo,tLevelNo,.tCaption)
							If $$$ISERR(tSC) Quit
							Set tFilter.caption = tCaption
							/*
							Set tCount = $O(tSpecInfo(""),-1)
							For t=1:1:tCount {
								Set tMemberSpec = tMemberSpec _ $S(tMemberSpec="":"",1:".") _ "["_tSpecInfo(t)_"]"
							}
							Set tFilter.key = tSpecInfo(tCount)
							*/

							// JMD1407 process list and check for range
							// first find number of items within the "key"
							Set tCount = 0
							Set tKeyCount = 1
							Set kx = $O(tSpecInfo(""))
							While (kx'="") {
								Set tCount = tCount + 1
								Set tToken = tSpecInfo(kx)
								If (tToken=":") {
									Set tKeyCount = 3
								}
								Set kx = $O(tSpecInfo(kx))
							}

							For t=1:1:tCount-tKeyCount {
								Set tMemberSpec = tMemberSpec _ $S(tMemberSpec="":"",1:".") _ "["_$$$dsEscapeIdent(tSpecInfo(t))_"]"	// DTB087
							}
							Set tMemberKey = ""
							If (tKeyCount = 1) {
								// single key
								Set tMemberKey = tSpecInfo(tCount)
							}
							ElseIf (tKeyCount=3) {
								// range
								Set tMemberKey = "&["_$$$dsEscapeIdent(tSpecInfo(tCount-2))_"]:&["_$$$dsEscapeIdent(tSpecInfo(tCount))_"]"	// DTB087
							}
							Set tFilter.key = tMemberKey
						}

						Set tFilterControls($I(tFilterControls)) = $LB(n,tMemberSpec,1)
					}
				}
			}
		}

		// now create controls for filters that need them
		Set k = $O(tFilterControls(""))
		While (k'="") {
			Set n = $LG(tFilterControls(k),1)
			Set tMemberSpec = $LG(tFilterControls(k),2)
			Set tReadOnly = +$LG(tFilterControls(k),3)
			Set tFilter = tFilters.GetAt(n)

			Set tControl = ##class(%DeepSee.Component.searchBox).%New()
			Set tControl.dataSourceName = pCubeName_".cube"
			Set tControl.filterName = tMemberSpec
			Set tControl.label = tFilter.caption
			Set tControl.value = tFilter.key
			If (tReadOnly) {
				Set tControl.readOnly = 1
			}
			Else {
				Set tControl.editable = 1
				Set tControl.onchange = "zenPage.filterChangeHandler(zenThis,"_n_");"
				Set tControl.onshowdropdown = "zenPage.filterDropDown(zenThis);"
			}

			Do pGroup.%AddChild(tControl)
			Set k = $O(tFilterControls(k))
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get list of pivot variables within the given collection.
ClassMethod %FindPivotVariables(pList As %Collection.AbstractList, ByRef pVariables) As %Status
{
	// JMD1276
	Set tSC = $$$OK
	Try {
		If ($IsObject(pList)) {
			For n = 1:1:pList.Count() {
				Set tItem = pList.GetAt(n)
				If ($$$LOWER($E(tItem.spec,1,10))="$variable.") {
					Set pVariables(tItem.spec) = ""
				}
				If $IsObject(tItem.childLevels) {
					Set tSC = ..%FindPivotVariables(tItem.childLevels,.pVariables)
					If $$$ISERR(tSC) Quit
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// User has changed a pivot variable control value.
ClientMethod pivotVariableChangeHandler(ctrl, varName, varType) [ Language = javascript ]
{
	// JMD1276
	var pivot = this.getPivot();
	if (pivot) {
		var value = ctrl.getValue();

		// cast value according to type
		switch(varType) {
		case 'number':
			value = parseFloat(value);
			value = isNaN(value) ? '' : value;
			ctrl.setValue(value);
			break;
		case 'integer':
			value = parseInt(value,10);
			value = isNaN(value) ? '' : value;
			ctrl.setValue(value);
			break;
		case 'year':
			value = parseInt(value,10);
			value = isNaN(value) ? '' : value;
			if (value && value.toString().length!=4) {
				value = '';
			}
			ctrl.setValue(value);
			break;
		}

		// change run-time value of variable
		pivot.pivotVariables[varName.toLowerCase()] = value;
		// force regeneration of listing
		if (pivot.isDrillThrough) {
			pivot.mdx = '';
		}
		pivot.executeQuery(pivot.autoExecute);
	}
}

/// User has changed a filter control value.
ClientMethod filterChangeHandler(ctrl, filterNo) [ Language = javascript ]
{
	var pivot = this.getPivot();
	if (pivot) {
		var filter = pivot.filters[filterNo-1];
		if (filter) {
			filter.key = ctrl.value;
			filter.text = ctrl.text ? ctrl.text : '';
			// JMD993: force regeneration of listing
			if (pivot.isDrillThrough) {
				pivot.mdx = '';
			}
			pivot.executeQuery(pivot.autoExecute);
		}
	}
}

/// Drop down is about to appear for filter control.
ClientMethod filterDropDown(ctrl) [ Language = javascript ]
{
	try {
		// get list of current filter values
		// assume these are all from the same data source

		var specList = [];
		var keyList = [];

		var pivot = this.getPivot();
		if (pivot) {
			for (var n = 0; n < pivot.filters.length; n++) {
				var filter = pivot.filters[n];
				if (!filter.enabled) {
					// DTB164 - Ignore filters that are disabled
					continue;
				}

				if (filter && (filter.key != '')) {
					var spec = filter.spec;
					if (spec.toUpperCase().indexOf('.MEMBERS')!=-1) {
						// strip off .members
						var s = spec.split('.');
						s.length--;
						spec = s.join('.'); 
					}
					if (ctrl.filterName.toUpperCase() != spec.toUpperCase()) {
						specList[specList.length] = spec;
						keyList[keyList.length] = filter.key;
					}
				}
				else if (filter && (filter.spec != '')) {
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

		ctrl.relatedFilterSpecs = specList;
		ctrl.relatedFilterKeys = keyList;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in filterDropDown');
	}
	return true;
}

ClientMethod toggleExportMenu(menuId) [ Language = javascript ]
{
	// Method added by DP-402897
	var dropMenu = document.getElementById(menuId);
	var trap = self.document.getElementById("zenMouseTrap");
	
	if ((dropMenu) && (dropMenu.style)) {
		var dropMenuIcon = dropMenu.previousElementSibling;
		
		if (dropMenu.style.display === "none") {
		    dropMenu.style.display = "block";
		    dropMenu.style.zIndex = 101;
 		    dropMenuIcon.setAttribute("class","dsptIconDropdownSelect");
		    
		    // Activate the transparent mouse trap around the menu to catch click events anywhere else 
		    // on the page.
		    trap.style.display = "block";
			trap.style.zIndex = 100;
		    trap.onmouseup = new Function("if (zenPage.closeModalPending) {zenPage.closeModalPending = 0; zenPage.closeExportMenu('"+menuId+"');}")
			trap.onmousedown = function() {zenPage.closeModalPending = 1;}
			trap.onmouseout = function() {zenPage.closeModalPending = 0;}
			trap.onmousemove = null;
		} else {
		    zenPage.closeExportMenu(menuId);
		}
	}
}

ClientMethod closeExportMenu(menuId) [ Language = javascript ]
{
	// Method added by DP-402897
	var dropMenu = document.getElementById(menuId);
	var trap = self.document.getElementById("zenMouseTrap");
	
	if (dropMenu) {
		var dropMenuIcon = dropMenu.previousElementSibling;
		dropMenu.style.display = "none";
		dropMenuIcon.setAttribute("class","dsptIconDropdown");
		
		// Clear the trap callbacks and disable the mouse trap.
		trap.style.display = "none";
		trap.style.zIndex = "";
		trap.onmouseup = null;
		trap.onmousedown = null;
		trap.onmouseout = null;
	}
}

/// Export current query to excel
ClientMethod exportExcel() [ Language = javascript ]
{
	var table = this.getPivot();
	if (table && (''!=table.cubeName) && (''!=table.queryKey)) {
		var filterNames = [];
		var filterValues = [];
		table.getFilterInfo(filterNames, filterValues);

		var nonce = '';

		// use actual query text
		// JMD1334: used resolved query to get pivot variables
		var mdx = table.GetCurrentQueryText("export");		// DTB835
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
		if (table.rowTotals) {
			url += '&ROWTOTALS=1';
		}
		if (table.columnTotals) {
			url += '&COLUMNTOTALS=1';
		}
		if (table.rowTotalAgg!='') {
			url += '&ROWTOTALAGG=' + table.rowTotalAgg;
		}
		if (table.columnTotalAgg!='') {
			url += '&COLUMNTOTALAGG=' + table.columnTotalAgg;
		}
		if (table.listing!='') {
			url += '&LISTINGNAME='+encodeURIComponent(table.listing);
		}
		if (filterNames.length > 0) {
			url += '&FILTERNAMES='+zenPage.CreateParameterNonce(filterNames.join('\n'));		// DTB916
			url += '&FILTERVALUES='+zenPage.CreateParameterNonce(filterValues.join('\n'));		// DTB797
		}
		// + WAL239
		url += '&ROWCAPTIONS='+encodeURIComponent(table.getRowCaptions().join('\n'));
		// - WAL239
		// + WAL175
		if (table.hiddenMeasureText.length > 0) {
			url += '&HIDDENMEASURES='+encodeURIComponent(table.hiddenMeasureText.join('\n'));
		}
		if (table.measureLocation) {
			url += '&MEASURELOCATION='+encodeURIComponent(table.measureLocation);
		}
		// - WAL175

		// title
		// JMD1000: use printTitle first, then pivot name
		var title = table.printTitle;
		var subtitle = table.printSubtitle;
		var subtitleon = table.printSubtitleOn;
		if (title=='') {
			title = this.pivotName;
			// remove extension
			if (title!='') {
				var s = title.toString().split('.');
				s.length = s.length-1;
				title = s.join('.');
			}
		}

		url += '&TITLE='+encodeURIComponent(title);
		url += '&SUBTITLE='+encodeURIComponent(subtitle);
		
		url += '&SHOWDATE='+encodeURIComponent(table.showDate);	// WAL247
		
		//APV020- Adding CUBENAME and PIVOTVARS to the URL
		url += '&CUBENAME='
		if(''!=table.cubeName) url += encodeURIComponent(table.cubeName);		
		var tPivotVarNames=[];
		var tPivotVarValues=[];
		table.getPivotVariablesValues(tPivotVarNames, tPivotVarValues);
		var pivotVarNamesAndValues='';
		var i;
		for ( i = 0; i<tPivotVarNames.length; i++){
			pivotVarNamesAndValues+=tPivotVarNames[i]+':'+tPivotVarValues[i]+',';
		}
		url += '&PIVOTVARS='+encodeURIComponent(pivotVarNamesAndValues);

		// DP-408448 - Pass session key of saved local results
		url += '&SESSIONKEY='+encodeURIComponent(table.LastSessionKey);

		var url = zenLink(url);
		
		window.open(url,'excel','');
	}
}

/// Export current query to a CSV file.
ClientMethod exportCSV(simple) [ Language = javascript ]
{
	simple = (simple) ? simple : false;
	var table = this.getPivot();
	if (table && (''!=table.cubeName) && (''!=table.queryKey)) {
		var csvUtil = zenPage.getComponentById("csvUtil");
		var mdx = table.GetCurrentQueryText("export");
		
		var exportParams = csvUtil.prepareTableParms(table);
		exportParams.simple = simple;
		
		csvUtil.downloadCSV(mdx,exportParams);
	}
}

/// Export current query to PDF.
ClientMethod exportPDF() [ Language = javascript ]
{
	var table = this.getPivot();
	var svgUtil = zen('svgUtil');

	if (table && (''!=table.cubeName) && (''!=table.queryKey)) {		// Verify there is a query to print
		// Assemble the parameters specific 
		var parms = zenPage.collectPrintParameters();
		zenPage.prepareSvgPrintParameters(parms);

		table.exportToPDF(parms);		// DP-416722
	}
}

/// Collect the print parameters for this pivot container. This includes both URL parameters (ALL CAPS) and parameters specific to the 
/// SVG printing utility. 
ClientMethod collectPrintParameters() [ Language = javascript ]
{
	// Method added by DP-416722
	var table = this.getPivot();
	var preserveTempFiles = zenPage.pdfPreserveTempFiles;
	var filterNames = [];
	var filterValues = [];
	var svgUtil = zen('svgUtil');
	table.getFilterInfo(filterNames, filterValues);
	// Add active pivot variables to filter table
	for (prop in table.pivotVariables) { // JSL4376
		filterNames[filterNames.length]= prop;
		filterValues[filterValues.length] = table.pivotVariables[prop];
	}


	// use actual query text
	// DP-416722 - Use export mode in the query fetch
	var mdx = table.GetCurrentQueryText('export');
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

	// Collect parameters into a single parms object. If the URL is needed, this will be produced from this parms object
	var parms = {};
	parms.nonce = nonce;
	
	if (table.rowTotals) {
		parms.ROWTOTALS = 1;
	}
	if (table.columnTotals) {
		parms.COLUMNTOTALS = 1;
	}
	if (table.columnTotalAgg!='') {
		parms.ROWTOTALAGG = table.columnTotalAgg;
	}
	if (table.rowTotalAgg!='') {
		parms.COLUMNTOTALAGG = table.rowTotalAgg;
	}
	if (table.showZebra) {
		parms.ZEBRA = 1;
	}
	if (table.listing!='') {
		parms.LISTINGNAME = table.listing;
	}
	if (table.showZebraStripes) {
		parms.SHOWZEBRASTRIPES = table.showZebraStripes;		// DTB228
	}
	if (table.showListingFilters) {
		parms.SHOWLISTINGFILTERS =table.showListingFilters;	// DTB228
	}
	
	if (filterNames.length > 0) {
		parms.FILTERNAMES = zenPage.CreateParameterNonce(filterNames.join('\n'));		// DTB916
		parms.FILTERVALUES = zenPage.CreateParameterNonce(filterValues.join('\n'));		// DTB916
	}

	// The prepared filter table needs to be added to the collection of parms before measuring the overall height of the printout
	parms.filterTable = svgUtil.prepareFilterTable(filterNames,filterValues,parms);

	if (table.printTitle) {
		parms.TITLE = table.printTitle;
	}
	else {
		parms.TITLE = zenPage.cubeName;
	}
	if (table.printSubtitle) {
		parms.SUBTITLE = table.printSubtitle;
	}
	parms.SUBTITLEON = table.printSubtitleOn; // JSL4302
	parms.SHOWDATE = table.showDate;	// DTB228
	parms.SHOWUSER = table.showUser; // JSL4320

	// find background-color
	var div = zen('test').getEnclosingDiv();

	var style = table.columnHeaderStyle;
	if (style!='') {
		div.style.cssText = style;
		var bg = div.style.backgroundColor != '' ? 'background-color:'+div.style.backgroundColor+';' : '';
		parms.COLUMNSTYLE = zenPage.CreateParameterNonce(style + bg);		// DTB916
	}
	var style = table.rowHeaderStyle;
	if (style!='') {
		div.style.cssText = style;
		var bg = div.style.backgroundColor != '' ? 'background-color:'+div.style.backgroundColor+';' : '';
		parms.ROWSTYLE = zenPage.CreateParameterNonce(style + bg);		// DTB916
	}
	var style = table.cellStyle;
	if (style!='') {
		div.style.cssText = style;
		var bg = div.style.backgroundColor != '' ? 'background-color:'+div.style.backgroundColor+';' : '';
		parms.CELLSTYLE = zenPage.CreateParameterNonce(style + bg);		// DTB916
	}

	if (table.printPageSize!='') {
		parms.PAGESIZE = table.printPageSize;
	}
	if (table.printOrientation!='') {
		parms.ORIENTATION = table.printOrientation;
	}
	if (table.printMarginTop!='') {
		parms.MARGINTOP = table.printMarginTop;
	}
	if (table.printMarginBottom!='') {
		parms.MARGINBOTTOM = table.printMarginBottom;
	}
	if (table.printMarginLeft!='') {
		parms.MARGINLEFT = table.printMarginLeft;
	}
	if (table.printMarginRight!='') {
		parms.MARGINRIGHT = table.printMarginRight;
	}
	// JSL4219
	if (table.maxRows!='') {
		parms.MAXROWS = table.maxRows;
	}
	// JSL4218 control borders within table
	if (table.borderLeftCell!='') {
		parms.BORDERLEFTCELL = table.borderLeftCell;
	}
	if (table.borderRightCell!='') {
		parms.BORDERRIGHTCELL = table.borderRightCell;
	}
	if (table.borderTopCell!='') {
		parms.BORDERTOPCELL = table.borderTopCell;
	}
	if (table.borderBottomCell!='') {
		parms.BORDERBOTTOMCELL = table.borderBottomCell;
	}
	// + WAL100
	if (table.fontFamilyCell!='') {
		parms.FONTFAMILYCELL = table.fontFamilyCell;
	}
	if (table.fontSizeCell!='') {
		parms.FONTSIZECELL = table.fontSizeCell;
	}
	// - WAL100
	if (table.borderLeftCol!='') {
		parms.BORDERLEFTCOL = table.borderLeftCol;
	}
	if (table.borderRightCol!='') {
		parms.BORDERRIGHTCOL = table.borderRightCol;
	}
	if (table.borderTopCol!='') {
		parms.BORDERTOPCOL = table.borderTopCol;
	}
	if (table.borderBottomCol!='') {
		parms.BORDERBOTTOMCOL = table.borderBottomCol;
	}
	// + WAL100
	if (table.fontFamilyCol!='') {
		parms.FONTFAMILYCOL = table.fontFamilyCol;
	}
	if (table.fontSizeCol!='') {
		parms.FONTSIZECOL = table.fontSizeCol;
	}
	// - WAL100
	if (table.borderLeftRow!='') {
		parms.BORDERLEFTROW = table.borderLeftRow;
	}
	if (table.borderRightRow!='') {
		parms.BORDERRIGHTROW = table.borderRightRow;
	}
	if (table.borderTopRow!='') {
		parms.BORDERTOPROW = table.borderTopRow;
	}
	if (table.borderBottomRow!='') {
		parms.BORDERBOTTOMROW = table.borderBottomRow;
	}
	// + WAL100
	if (table.fontFamilyRow!='') {
		parms.FONTFAMILYROW = table.fontFamilyRow;
	}
	if (table.fontSizeRow!='') {
		parms.FONTSIZEROW = table.fontSizeRow;
	}
	// - WAL100
	if (table.showFilters!='') {
		parms.SHOWFILTERS = table.showFilters;
	}
	if (table.filterTableStyle!='') {
		parms.FILTERTABLESTYLE = zenPage.CreateParameterNonce(table.filterTableStyle);		// DTB916	// DP-402876
	}
	if (table.filterTableCaptionStyle!='') {
		parms.FILTERTABLECAPTIONSTYLE = zenPage.CreateParameterNonce(table.filterTableCaptionStyle);		// DTB916
	}
	if (table.filterTableItemStyle!='') {
		parms.FILTERTABLEITEMSTYLE = zenPage.CreateParameterNonce(table.filterTableItemStyle);		// DTB916
	}

	//JSL4308
	if (table.nowDisplayFormat!='') {
		parms.NOWDISPLAYFORMAT = table.nowDisplayFormat;
	}
	
	parms.LABELWIDTH = table.printLabelWidth;
	parms.CELLWIDTH = table.printCellWidth;

	parms.ROWCAPTION = table.rowCaptionText;
	// + WAL239 -- this is used instead of "ROWCAPTION" above
	parms.ROWCAPTIONS = table.getRowCaptions().join('\n');
	// - WAL239

	if (preserveTempFiles) {
		// Option to preserve temp files
		parms.$NODELETE = 1
		parms.preserveTempFiles = preserveTempFiles;
	}

	return parms;
}

/// Transform a set of printing parameters that are compatible with the ZenReport-based
/// %DeepSee.UI.MDXPDF, %DeepSee.UI.ChartPDF, etc, into the parameters expected by the
/// %DeepSee.Component.deepseeSvgImageProvider
ClientMethod prepareSvgPrintParameters(parms) [ Internal, Language = javascript ]
{
	// Method added by DP-415765
	var svgUtil = zen('svgUtil');
	if (parms.PAGESIZE) {
		var printPageUnit = parms.PAGESIZE.substring(parms.PAGESIZE.indexOf(' ')+1);
	}
	else {
		var printPageUnit = 'pt';
	}

	
	// DTB250 - This could all be configurable with Print Setup that has svg mode
	// DTB252 - Set print page defaults
	parms.marginLeft = (parms.MARGINLEFT) ? svgUtil.convertSizeToPoint(parms.MARGINLEFT + printPageUnit).value+'pt' : '36pt';
	parms.marginRight = (parms.MARGINRIGHT) ? svgUtil.convertSizeToPoint(parms.MARGINRIGHT + printPageUnit).value+'pt' : '36pt';
	parms.marginTop = (parms.MARGINTOP) ? svgUtil.convertSizeToPoint(parms.MARGINTOP + printPageUnit).value+'pt' : '36pt';
	parms.marginBottom = (parms.MARGINBOTTOM) ? svgUtil.convertSizeToPoint(parms.MARGINBOTTOM + printPageUnit).value+'pt' : '36pt';

	if (parms.PAGESIZE) {
		// DTB366
		var printPageSize = parms.PAGESIZE.substring(0,parms.PAGESIZE.indexOf(' '));

		if ('landscape'==parms.ORIENTATION) {
			parms.pageWidth = printPageSize.substring(printPageSize.indexOf('x')+1) + printPageUnit;
			parms.pageHeight = printPageSize.substring(0,printPageSize.indexOf('x')) + printPageUnit;
		}
		else {
			parms.pageWidth = printPageSize.substring(0,printPageSize.indexOf('x')) + printPageUnit;
			parms.pageHeight = printPageSize.substring(printPageSize.indexOf('x')+1) + printPageUnit;
		}
	}
	else {
		parms.pageWidth = '8.5in';
		parms.pageHeight = '11in';
	}
	
	// The foIntro is used to inject XSL-FO directives in the generated
	// stylesheet. Note the use of buildFOBlock() and buildFOTable() to
	// turn the JavaScript object abstractions into actual FO
	// source 
	
	// If there are preamble items, build fo blocks to represent them (per widget)
	// DP-416722 - The svgImageProvider's title is not used in this implementation, it is covered by the foIntro contents
	parms.title = '';
	if (parms.TITLE) {
		var printTitle = {caption:parms.TITLE,
				style:{
					fontWeight:"bold",
					fontSize:"12pt",
					textAlign:"left",
					padding:"2pt"}
				};
				
		var foPrintTitle = svgUtil.buildFOBlock(printTitle);
	}
	if (('on' == parms.SUBTITLEON) && ('' != parms.SUBTITLE)) {
		// DTB366
		var printSubtitle = {caption:parms.SUBTITLE,
				style:{
					fontWeight:"bold",
					fontSize:"8pt",
					textAlign:"left",
					padding:"2pt"}
				};
				
		var foPrintSubtitle = svgUtil.buildFOBlock(printSubtitle);
	}
	if ('on' == parms.SHOWUSER) {
		// DTB366
		var printUser = {caption:zenPage.userName,
				style:{
					fontWeight:"bold",
					fontSize:"8pt",
					textAlign:"left",
					padding:"2pt"}
				};
				
		var foPrintUser = svgUtil.buildFOBlock(printUser);
	}
	if ('on' == parms.SHOWDATE) {
		// DTB366
		var dateObj = new Date;
		var printDate = {caption:dateObj.toLocaleString(),
				style:{
					fontWeight:"bold",
					fontSize:"8pt",
					textAlign:"left",
					padding:"2pt"}
				};
				
		var foPrintDate = svgUtil.buildFOBlock(printDate);
	}

	// If there are filters defined, construct the fo table to display the filter values
	var filterTableStyle = (parms.FILTERTABLESTYLE) ? svgUtil.parseCssStyleString(parms.FILTERTABLESTYLE) : {};
	
	// DTB405 - Add styling from the filter table style provided from Print Settings
	var filterTitle = {caption:$$$Text("Filter Values"),
				style:{
					backgroundColor:((filterTableStyle['background-color']) ? filterTableStyle['background-color'] :'#B9B9B9'),
					fontWeight:((filterTableStyle['font-weight']) ? filterTableStyle['font-weight'].trim() :'bold'),
					fontSize:((filterTableStyle['font-size']) ? svgUtil.convertSizeToPoint(filterTableStyle['font-size']).value+'pt' :'8pt'),
					textAlign:((filterTableStyle['text-align']) ? filterTableStyle['text-align'].trim() :"center"),
					padding:((filterTableStyle['padding']) ? svgUtil.convertSizeToPoint(filterTableStyle['padding']).value+'pt' :'2pt'),
					color:(filterTableStyle['color'] ? filterTableStyle['color'] : '') }
				};
	if (filterTableStyle['font-style']) {
		// DTB421 - Only set this attribute if there is a real value
		filterTitle.style.fontStyle = filterTableStyle['font-style'];
	}
	if (filterTableStyle['font-family']) {
		// DTB421 - Only set this attribute if there is a real value
		filterTitle.style.fontFamily = filterTableStyle['font-family'];
	}

	var postFilterSpacer = {caption:"",
				style:{padding:"2pt"}
				};
	 	
 	var foFilterTable = '';
 	if ((parms.filterTable)&&(parms.filterTable.rows)&&(parms.filterTable.rows.length)) {
	 	foFilterTable = svgUtil.buildFOBlock(filterTitle) +'\n'+
 					svgUtil.buildFOTable(parms.filterTable) +'\n'+
 					svgUtil.buildFOBlock(postFilterSpacer);
 	}
 	
 	// DTB366 - Assemble foIntro items
	parms.foIntro = ((typeof foPrintTitle != 'undefined') ? foPrintTitle : '') +
	 				((typeof foPrintSubtitle != 'undefined') ? '\n' + foPrintSubtitle : '') +
	 				((typeof foPrintUser != 'undefined') ? '\n' + foPrintUser : '') +
	 				((typeof foPrintDate != 'undefined') ? '\n' + foPrintDate : '') +
	 				((typeof foFilterTable != 'undefined') ? '\n' + foFilterTable : '')		// DTB385 - Check for the correct item!
	 				;
 	// End foIntro
}

/// Define any context links for the context menu in the header.
ClassMethod GetContextLinks(Output pLinks) As %Status
{
	Set pLinks($I(n)) = $LB($$$Text("Open"),,"zenPage.loadPivot();",$$$Text("Load a previously saved pivot table"))
	Set pLinks($I(n)) = $LB($$$Text("Save"),,"zenPage.savePivot(false);",$$$Text("Save this pivot table"))
	Set pLinks($I(n)) = $LB($$$Text("Save with options"),,"zenPage.savePivot(true);",$$$Text("Show the Save dialog for this pivot table"))
	Set pLinks($I(n)) = $LB("")
	Set pLinks($I(n)) = $LB($$$Text("Export to Excel"),,"zenPage.exportExcel();",$$$Text("Export currennt results to Excel"))

	// Remove email link if not enabled or not user mode
	Set tMailEnabled = +$G(^DeepSee.UserPortalSettings("MailEnabled"))
	If (..#USERMODE && tMailEnabled) {
		Set pLinks($I(n)) = $LB("")
		Set pLinks($I(n)) = $LB($$$Text("Email Pivot Table"),,"zenPage.mailPivot();",$$$Text("Email this pivot table to another user"))
	}
	Quit $$$OK
}

/// Update the contents of the member tree.
ClientMethod updateMemberTree() [ Language = javascript ]
{
	zen('dimTree').refreshContents();
	if (this.treeMode=='qmsrs') {
		this.updateQMSRTree();
	}
	else if (this.treeMode=='pivots') {
		this.updatePivotTree();
	}
	else if (this.treeMode=='fields') {
		this.updateListingsTree();
	}
}

/// Update the contents of the qmsr tree.
ClientMethod updateQMSRTree() [ Language = javascript ]
{
	zen('dimTreeQMSR').refreshContents();
}

/// Update the contents of the pivot tree.
ClientMethod updatePivotTree() [ Language = javascript ]
{
	zen('dimTreePivot').refreshContents();
}

/// Update the contents of the listings tree.
ClientMethod updateListingsTree() [ Language = javascript ]
{
	zen('dimTreeListingFields').refreshContents();
}

/// Test if the user has write privilege.
ClientMethod canUserModify() [ Language = javascript ]
{
	if (!this.canWrite) {
		alert($$$Text('You are not authorized to save or modify pivot tables.'));
		return false;
	}
	if (this.readOnly) {
		alert($$$Text('This pivot table is read only.'));
		return false;
	}
	return true
}

/// Data drop on filter tgroup area.
ClientMethod dropOnFilterGroup(dragData) [ Internal, Language = javascript ]
{
	var ctrl = zen('pivotController');
	if (ctrl && ctrl.dropStartHandler) {
		dragData._targetType = 'filtersappend';
		return ctrl.dropStartHandler(dragData);
	}
	return true
}

/// email this pivot.
ClientMethod mailPivot() [ Language = javascript ]
{
	if (''==this.pivotName) {
		alert($$$Text('Please save this pivot before mailing it'));
		return;
	}

	// save settings using nonce
	var nonce = Math.floor(Math.random()*10000000000);
	// this.saveSettings(nonce);

	var url = self.document.location.href.split('?')[0];
	url = url + '?PIVOT='+encodeURIComponent(this.pivotName)+'&NONCE='+nonce;

	var title = $$$Text('DeepSee Pivot');
	this.sendMail(url,title);
}

/// Launch the send email dialog.
/// Copy of method in %DeepSee.UserPortal.standardPage.
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

/// Toggle autoexec mode.
ClientMethod toggleAutoExecute() [ Language = javascript ]
{
	var table = this.getPivot();
	table.autoExecute = !table.autoExecute;
	var cb = self.document.getElementById('cbAutoExec');
	if (cb) {
		cb.checked = table.autoExecute;
	}

	if (table.autoExecute) {
		table.executeQuery(true);
	}
	else {
		table.updateController();
	}
}

/// Change of auto-exec checkbox.
ClientMethod autoExecChange() [ Language = javascript ]
{
	var cb = self.document.getElementById('cbAutoExec');
	if (cb) {
		var table = this.getPivot();
		table.autoExecute = cb.checked;
		if (table.autoExecute) {
			table.executeQuery(true);
		}
		else {
			table.updateController();
		}
	}
}

/// Toggle preview mode. The argument <var>id</var> is unused in the Analyzer case, but is
/// provided to match the signature of the call from the pivot component so a custom
/// page embedding multiple pivots could make use of a custom implementation of this
/// method.
ClientMethod togglePreviewMode(id) [ Language = javascript ]
{
	// Method added by DTB701
	// DTB712 - Implement the id lookup
	if (id) {
		var table = zenPage.getComponentById(id);
	}
	else {
		var table = this.getPivot();
	}
	
	zenPage.previewMode = !zenPage.previewMode;		// DTB714 - Control is directly linked to the page setting
	table.previewMode = zenPage.previewMode;
	var cb = self.document.getElementById('cbpreviewMode');
	if (cb) {
		//cb.checked = table.previewMode;		// DTB714 - Do not change control based on the table setting
	}
	
	if (table.autoExecute) {
		table.executeQuery(true);
	}
	else {
		table.updateController();
	}
}

/// Change of preview mode checkbox.
ClientMethod previewModeChange() [ Language = javascript ]
{
	// Method added by DTB701
 	var cb = self.document.getElementById('cbpreviewMode');
	if (cb) {
		var table = this.getPivot();
		zenPage.previewMode = cb.checked;		// DTB714 - Set in the page
		table.previewMode = cb.checked;
		if ((!cb.checked)&&table.headFunctionAdded) {
			// DTB712 - Unchecking should also show all the rows that were limited by a complex query
			table.crossJoinRowLimit = 0;
		}
		if (table.autoExecute) {
			table.executeQuery(true);
		}
		else {
			table.updateController();
		}
	}
}

/// Set the state of preview mode checkbox.
ClientMethod setPreviewMode(setChecked) [ Language = javascript ]
{
	// Method added by DTB712
 	var cb = self.document.getElementById('cbpreviewMode');
	if (cb) {
		cb.checked = setChecked;
		zenPage.previewModeChange();
	}
}

/// Create additional charts, one per data series.
ClientMethod createChartsForSeries() [ Language = javascript ]
{
	// !!!
	return;

	try {
		var pivot = zen('table');
		var chart = zen('chart1');
		var svg = zen('svg');

		// remove old charts
		for (var n = svg.children.length-1; n>0; n--) {
			var newChart = svg.children[n];
			//newChart.unrender();
			svg.removeChild(newChart);
		}

		if (!this.multiChart) {
			svg.layoutChildren();
			return;
		}

		var scount = pivot.getDimSize(2);
	
		if (scount > 1) {
			chart.seriesNumber = 0;
		}
	
		var dx = chart.width/2;
		var x = 0;
		for (var n = 1; n < scount; n++) {
			var newChart = zenPage.createComponent(chart._type);
			newChart.seriesNumber = n;
			newChart.setProperty('controllerId',chart.controllerId);
			newChart.setProperty('id','chart' + (n+1));

			x += dx;
			newChart.x = x;
			newChart.y = 0;
			newChart.width = chart.width/2;
			newChart.height = chart.height/2;
			
			// copy over other settings
			newChart.appearance = chart.appearance;
			newChart.legendVisible= chart.legendVisible;
			newChart.titleStyle = chart.titleStyle;
			newChart.titleBoxStyle = chart.titleBoxStyle;
			newChart.borderRadius = chart.borderRadius;
			newChart.borderStyle = chart.borderStyle;
			newChart.plotAreaStyle = chart.plotAreaStyle;
			newChart.plotEdgeStyle = chart.plotEdgeStyle;
			newChart.selectedItemStyle = chart.selectedItemStyle;
			newChart.selectedItemStyle = chart.selectedItemStyle;
			newChart.title = chart.title;
			newChart.legendTitle = chart.legendTitle;
			newChart.stripesVisible = chart.stripesVisible;
			newChart.stripeStyle = chart.stripeStyle;
			newChart.seriesColors = chart.seriesColors;
			newChart.seriesColorScheme = chart.seriesColorScheme;
			newChart.seriesNames = chart.seriesNames;
			newChart.markerScale = chart.markerScale;
			newChart.gridStyle = chart.gridStyle;
			newChart.bandUpper = chart.bandUpper;
			newChart.bandUpperStyle = chart.bandUpperStyle;
			newChart.bandLower = chart.bandLower;
			newChart.bandLowerStyle = chart.bandLowerStyle;
			newChart.msgIfNoData = chart.msgIfNoData; // JSL4478
			newChart.warnIfNoData = chart.warnIfNoData; // JSL4478
			newChart.noDataOpacity = chart.noDataOpacity; // JSL4478
			newChart.noDataFill = chart.noDataFill; // JSL4478
			newChart.noDataStroke = chart.noDataStroke; // JSL4478

			svg.addChild(newChart);

			/*

	
			if (chart.xAxis) {
				//!!! clone !!!
				//newChart.xAxis = chart.xAxis;
			}
			if (chart.yAxis) {
				//newChart.yAxis = chart.yAxis;
			}
			*/

		}

		svg.layoutChildren();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in createChartsForSeries');
	}
}

/// Get the value and text of the selected item in the tree (as an object).
ClientMethod getSelectedTreeValue() [ Language = javascript ]
{
	var ret = null;
	var tree = null;

	switch (this.treeMode) {
	case 'qmsrs':
		tree = zen('dimTreeQMSR');
		break;
	case 'pivots':
		tree = zen('dimTreePivot');
		break;
	case 'fields':
		tree = zen('dimTreeListingFields');
		break;
	case '':
	default:
		tree = zen('dimTree');
		break;
	}

	var idx = tree.getSelectedIndex();

	if (idx >= 0) {
		var val = tree.getNodeValue(idx);
		var text = tree.getNodeText(idx);
		ret = { value: val, text: text };
	}
	return ret;
}

/// User chose an action.
ClientMethod actionHandler(ctrl) [ Language = javascript ]
{
	var action = ctrl.value;
	// reset control
	ctrl.value = '';

	// fill in context object to send data to server
	var context = new zenProxy();
	context.command = '';
	context.textList = '';
	context.value = '';

	var pivot = this.getPivot();

	context.currSeriesNo = '';
	context.currItemNo = '';
	context.currValue = '';
	context.currValueName = '';
	context.currFilterSpec = '';

	var p = null;
	if (pivot.selectedRange && '' !== pivot.selectedRange) {
		p = pivot.selectedRange.toString().split(',');
		context.currItemNo = (null!=p[0]) ? parseInt(p[0]) : '';
		context.currSeriesNo = (null!=p[1]) ? parseInt(p[1]) : '';

		// find the filters that correspond to this range
		// JMD1468 add allRows/Cols
		context.currFilterSpec = pivot.getFilterForCells(p[0],p[1],p[2],p[3],zenGet(p[4]),zenGet(p[5]));
	}

	// find value of the item
	// value
	context.currValueName = 'Value';
	context.currValue = '';
	if (p && pivot.getValueName) {
		context.currValueName = pivot.getValueName();
		var data = pivot.getDataAsArrays();
		if (data && null != data[p[1]-1]) {
			context.currValue = data[p[1]-1][p[0]-1];
		}
	}

	// list of values for selected rows
	var list = pivot.getSelectedItems();
	if (list) {
		for (var n = 0; n < list.length; n++) {
			if (list[n] && list[n]!='' && 'string'==typeof list[n]) {
				list[n] = list[n].replace(/\,/g,'\\,');
			}
		} 
	}
	// + WAL161 -- add pivot variables to context
	var pivotVariables = new zenProxy();
	for (pVar in pivot.pivotVariables) {
		pivotVariables[pVar] = pivot.pivotVariables[pVar];
	}
	// - WAL161
	
	// + DTB476 - Add filter control settings to context
	var filters = new zenProxy();
	for (f in pivot.filters) {
		filters[pivot.filters[f].spec] = (pivot.filters[f].key ? pivot.filters[f].key : pivot.filters[f].value);		// DTB496
	}
	// - DTB476
	
	context.valueList = list ? list.join(',') : '';
	context.cubeName = pivot.cubeName;
	context.dataSource = this.pivotName;		// DTB543 - Add pivot name to context
	context.mdx = pivot.GetCurrentQueryText("resolved") ? pivot.GetCurrentQueryText("resolved") : '';  // WAL075 -- use getter method
	var msg = this.SendActionToDataSource(this.cubeName,action,context,pivotVariables,filters); // + WAL161 -- pass pivot variable context		DTB476 - Pass filter control context

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

			// JMD1051: apply $$$ substitutions
			var url = t.join(':');
			if ((url.indexOf('$$$VALUELIST')!=-1)||(url.indexOf('$$$LISTINGIDS')!=-1)) {
				var list = pivot.getSelectedItems();
				if (list) {
					for (var n = 0; n < list.length; n++) {
						if (list[n] && list[n]!='' && 'string'==typeof list[n]) {
							list[n] = list[n].replace(/\,/g,'\\,');
						}
					} 
				}
				var VALUELIST = list ? list.join(',') : '';
				if (url.indexOf('$$$LISTINGIDS')!=-1) {
					url = url.replace(/\$\$\$LISTINGIDS/g,VALUELIST);
				}
				else {
					url = url.replace(/\$\$\$VALUELIST/g,VALUELIST);
				}
			}

			if (''!==command) {
				// invoke actions
				switch(command) {
				case 'setFilter':
				case 'applyFilter':
				case 'refresh':
					// ignore
					break;
				case 'navigate':
					// command:url;
					zenPage.navigate(url);
					break;
				case 'newWindow':
					// command:url;
					window.open(url);
					break;
				case 'popup':
					// JMD1063
					zenLaunchPopupWindow(url,'ActionPopup','status,scrollbars,resizable=yes,width=800,height=600');
					break;
				case 'alert':
					// JMD1051
					alert(url);
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
ClassMethod SendActionToDataSource(pCubeName As %String, pAction As %String, pContext As %ZEN.proxyObject, pPivotVariables As %ZEN.proxyObject = "", pFilters As %ZEN.proxyObject = "") As %String [ Internal, ZenMethod ]
{
	Set tMsg = ""
	Set tSC = $$$OK
	Try {
		#; dispatch to cube class
		If (pCubeName'="") {
			Set pContext.pivotVariables = pPivotVariables // + WAL161 -- combine pivot variable information with other context
			Set pContext.filters = pFilters		// DTB476 - Add filter control settings to the context
			
			Set tActionClass = ##class(%DeepSee.Utils).%GetCubeActionClass(pCubeName)
			If (tActionClass'="") {
				Set tSC = $classmethod(tActionClass,"%InvokeDashboardAction",pAction,pContext)
				If $$$ISERR(tSC) Quit
			}
		}
		// text values?
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetOneErrorText(tSC)
	}
	Quit tMsg
}

ClientMethod showDimensionTree(flag) [ Language = javascript ]
{
	this.showDimensions = flag?true:false;
	var tree = zen('groupTree');
	tree.setHidden(!this.showDimensions);
	// + WAL179
	var activeHGroup = document.getElementById('mainHGroup');
	if (this.showDimensions==false) {
		zenPage.lastLeftWidth = document.getElementById('groupTree').parentNode.offsetWidth;	
	}
	var leftWidth = this.showDimensions?this.lastLeftWidth:0;
	if (activeHGroup && activeHGroup.children && activeHGroup.children[0]) {
		activeHGroup.children[0].engine.setSplit(leftWidth,0);
	}
	// - WAL179
	this.adjustSizes();
	var table = this.getPivot();
	table.updateController();
}

/// Change display mode for dimension tree.
ClientMethod changeTreeMode(mode) [ Language = javascript ]
{
	if (this.treeMode!=mode) {
		this.treeMode = mode;
		this.adjustSizes();
	}
}

ClassMethod KillTempSubFolders(pFolder As %String) As %String [ ZenMethod ]
{
	// Method added by WAL053
	If ($E(pFolder,1,5) '= "$Temp") Quit $$$OK
	// need to delete this folder as well
	Set tSC = ##class(%DeepSee.UserLibrary.Utils).%GetSubFolderList(.tSubFolderList,pFolder) 
	Set tSubFolder = $O(tSubFolderList(""))
	While (tSubFolder '= "") {
		// Recurse
		If (tSubFolderList(tSubFolder)'=pFolder) {
			Set tSC = ..KillTempSubFolders(tSubFolderList(tSubFolder))
			If (($G(tSubFolderList(tSubFolder))'="") && ($E($G(tSubFolderList(tSubFolder)),1,5) = "$Temp")) {
				Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderContents(tSubFolderList(tSubFolder))
				Set tFolder = ##class(%DeepSee.UserLibrary.Utils).%FindFolder(tSubFolderList(tSubFolder))
				If $IsObject(tFolder) {
					Set tSC = ##class(%DeepSee.UserLibrary.Folder).%DeleteId(tFolder.%Id())
				}
			}
		}
		Set tSubFolder = $O(tSubFolderList(tSubFolder))
	}
	// Delete this folder
	Set tSC = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderContents(pFolder)
	Set tFolder = ##class(%DeepSee.UserLibrary.Utils).%FindFolder(pFolder)
	If $IsObject(tFolder) {
		Set tSC = ##class(%DeepSee.UserLibrary.Folder).%DeleteId(tFolder.%Id())
	}
	Quit $$$OK
}

ClassMethod KillTempPivot(pPivotName As %String) As %String [ ZenMethod ]
{
	// Method added by WAL053
	If ($E(pPivotName,1,5) '= "$Temp") Quit $$$OK
	Set tExists = ##class(%DeepSee.UserLibrary.Utils).%DeleteFolderItem(pPivotName _ ".pivot")
	Quit $$$OK
}

/// Helper function to make <class>%DeepSee.Component.pivotTable</class>.DeleteLastResult() server call in asynchronous mode 
ClientMethod deleteLastPivotResult() [ Language = javascript ]
{
	var modeTemp = zenSynchronousMode;
	zenSynchronousMode = false;
	zenPage.getPivot().DeleteLastResult();
	zenSynchronousMode = modeTemp;
}

///  Ensure that auto-logout is not blocked by onunloadHandler checking for unsaved changes 
ClientMethod onlogoutHandler() [ Language = javascript ]
{
	this.autosave = '';
	return this.invokeSuper('onlogoutHandler',arguments);
}

/// Override the superclass logout function to delete the last pivotTable query from the local cache before exiting
ClientMethod logout() [ Language = javascript ]
{
	this.deleteLastPivotResult();
	return this.invokeSuper('logout',arguments);
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	// Attempt to cancel any running query and autosave if the browser allows unload events.
	zenPage.getPivot().cancelQuery();	// DTB167 - Call the pivot's cancel method
	this.runAutosave();
	if (this.pageModified && this.warnUser) {
		return '';
	}
}

/// Perform an autosave of the current pivot, filed under the current user. This method cotnains only asynchronous calls
ClientMethod runAutosave() [ Language = javascript ]
{
	// Method added by DP-427970
	var timer = zen('autosaveTimer');
	if (this.autosave!='') {
		// Execute the server-side save without changing the live working state of the page.
		this.SaveTempTables();
		timer.startTimer();
	}
	else {
		// If autosave is not on, turn the timer off
		timer.timeout = 0;
	}
}

/// Generate a nonce for an MDX query.
ClassMethod CreateQueryNonce(pQuery As %String) As %String [ Internal, ZenMethod ]
{
	Quit ##class(%DeepSee.Utils).%CreateQueryNonce(pQuery)
}

/// Generate a nonce for parameter value. This function will perform UTF8 conversion.
ClassMethod CreateParameterNonce(pParmValue As %String) As %String [ Internal, ZenMethod ]
{
	// Method added by DTB797
	Quit ##class(%DeepSee.Utils).%CreateParameterNonce(pParmValue)
}

}
