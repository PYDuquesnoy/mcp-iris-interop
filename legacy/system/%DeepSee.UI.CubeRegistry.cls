/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// DeepSee CubeRegistry page. 
/// This UI allows you to register a "Group" by drag and drop:
///    Drag a group from the tree and drop it on the header for the "Registered" groups.
/// The tree reprsents Unregistered groups. The center table represents Registered groups.
/// You can also register and merge at the same time:
///    Drag a group from the tree and drop it on a registered group in the center table. A confirmation box will display.
///    If confirmed the cubes from the tree will be merged into the registered group.
/// To Unregister, click the "x" image.
/// The map object will be saved immediately after a drag and drop or a unregister.
/// To modify properties for a registered group and cubes, click a row from the center table and modify the properties on the right in the Details pane.
/// After your modification is done, you can click the Save button. If you do a drag & drop or a unregister, these changes will also be saved automatically.
/// 
Class %DeepSee.UI.CubeRegistry Extends %DeepSee.UI.standardPage [ System = 4 ]
{

Parameter JSINCLUDES = "zenMenusSMP.js";

/// Displayed name of this page.
Parameter PAGENAME = "Cube Registry";

Parameter RESOURCE = "%DeepSee_Admin";

/// If this page has multiple views, this is its initial display mode.
Parameter DEFAULTVIEWMODE = "cube";

Parameter DOCBOOKID = "D2IMP_current_cubemgr";

/// [NO LONGER USED ON THIS PAGE] 
/// Name of Cube being viewed.
Property cubeName As %ZEN.Datatype.string;

/// [NO LONGER USED ON THIS PAGE] 
/// Class name of Cube being viewed.
/// This is determined from the cube name.
Property cubeClass As %ZEN.Datatype.string;

/// Data source. This is a copy of the value in the cube model.
Property tree As %ZEN.Datatype.string;

/// ID (index number, 0-based) of current selected item.
Property currItem As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// Type of the current selected item.
Property currItemType As %ZEN.Datatype.string;

/// Local copy of cube map model object.
Property %model As %RegisteredObject;

/// Set to 1 if server should reload json map after merge. 
Property reloadMap As %Boolean [ InitialExpression = 0 ];

/// If true, user cannot modify the current cube definition.
Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, user can modify (non-read-only) cube definitions,
/// otherwise they can only view.
Property canWrite As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property hlpRemove As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Remove this item")} ];

Property hlpDropTooltip As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Register %1")} ];

Property hlpMoveUp As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Move this group up")} ];

Property hlpMoveDown As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Move this group down")} ];

Property hlpShowHide As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Hide or show the properties box")} ];

Property msgSystemUpdates As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("This update schedule is managed by an external application")} ];

Property msgInvalid As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Cube Registry map is empty.")} ];

Property msgMerge As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Are you sure you want to merge group %1 to group %2?")} ];

Property imgArrow1D As %String [ InitialExpression = {..Link("/csp/broker/images/arrow1D.gif")} ];

Property imgArrow1R As %String [ InitialExpression = {..Link("/csp/broker/images/arrow1R.gif")} ];

/// Group name for the currently selected cube.
Property detailCubeGroupName As %String;

/// If true, the settings area (property sheet) is visible.
Property settingsExpanded As %Boolean [ InitialExpression = 1, Internal ];

/// Whether to expand all elements under each type. When user clicks Collapse All then this is set to 0. At end of renderTable it is set to 2.
Property expandAll As %Integer [ InitialExpression = 1 ];

/// Last cube save time when the cube is loaded.
Property SavedTime As %ZEN.Datatype.string;

/// The cube is currently locked by someone when the cube is opened in Architect
Property isLocked As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property DocumaticPage As %String;

Property activeRegistryExists As %Boolean;

/// This Style block contains page-specific CSS style definitions.
XData CSS3Style
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

.dynaTreeNode {
	font-size: 10pt;
	white-space: nowrap;
}

.dynaTreeItem {
	color: rgb(71,72,67);
}

.detailLabel {
	color: rgb(71,72,67);
	font-size: 10pt;
	font-weight: bold;
}

#editorPane {
	position: relative;
}

#modelTableHeader {
	background: #F0F0F0;
	height: 40px;
	top: 0px;
	overflow: hidden;
}

#modelTableBody {
	background: white;
	border: 1px solid gray;
	height: 200px;
	top: 40px;
	overflow: auto;
}

#tree {
	background: white;
	border-top: 1px solid gray;
	border-bottom: 1px solid gray;
	overflow: auto;
	width: 250px;
}

#propertyPane {
	background: rgb(156,154,141);
	border-right: 1px solid black;
	border-bottom: 1px solid black;
	display: none;
	height: 449px;
	position: relative;
	width: 350px;
}

/* styles for tabs */
#tabDetails,#tabTools {
	color: #404040;
	padding-left: 3px;
	overflow: auto;
}

td.tabGroupButtonOff:hover {
	color: #FFEEAA;
}

.tabGroupBody {
	background: #E0E0D0;
	min-height: 300px;
	width: 399px;
}

td.tabGroupButtonOn {
	color: #404040;
	background: #E0E0D0;
	background: -moz-linear-gradient(top, #F8F8FF, #E0E0D0);
	background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#F8F8FF), color-stop(1.0,#E0E0D0));
	background: linear-gradient(top, #F8F8FF, #E0E0D0);
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
	height: 30px;
	font-size: 10pt;
}

/* @doc="Individual tab bar button in Off state." */
td.tabGroupButtonOff,
td.tabGroupButtonDisabled {
	background: #C0C0C0;
	background-image: none;
	background-repeat: repeat-x;
	color: #404040;
	font-size: 10pt;
	height: 30px;
}
td.tabGroupButtonOff:hover {
	background: #C0C0C0;
}

td.tabGroupButtonDisabled {
	color: gray;
}

td.tabGroupButtonOff {
background: -moz-linear-gradient(top, #B0B0B0, #D0D0D0);
background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#B0B0B0), color-stop(1.0,#D0D0D0));
	background: linear-gradient(top, #B0B0B0, #D0D0D0);
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

td.tabGroupButtonDisabled {
background: -moz-linear-gradient(top, #B0B0B0, #D0D0D0);
background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#B0B0B0), color-stop(1.0,#D0D0D0));
	background: linear-gradient(top, #B0B0B0, #D0D0D0);
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}
.tabGroupGap {
	width: 0px;
}
#propertyTitle {
	height: 40px;
	width:  40px;
}
#spanArrow {
	color: white;
	font-size: 20pt;
	padding-left: 10px;
	text-shadow: black 1px 1px 1px;
}
#propertyCommands {
	color: white;
}
table.modelTable {
	background: white;
	font-size: 10pt;
	width: 100%;
}
table.modelTable td {
	border-bottom: 1px solid rgb(241,240,231);
	padding: 2px;
}
.modelError {
	background: lightgray;
	color: #404040;
	font-size: 24px;
	padding: 10px;
}
span.selector {
	visibility: hidden;
}
.modelRowGroups {
	background: #D0D0FF;
	color: rgb(67,67,67);
	font-size: 1.2em;
	font-weight: bold;
}
.modelRowGroupsSelected {
	background: rgb(53,107,141);
	color: white;
	font-size: 1.2em;
	font-weight: bold;
}
.modelRowGroup {
	background: #F0F0FF;
	color: rgb(67,67,67);
	font-weight: bold;
}
.modelRowGroupSelected {
	background: rgb(53,107,141);
	color: white;
	background: rgb(53,107,141);
	font-weight: bold;
}
.modelRowGroupCube {
	color: rgb(67,67,67);
	font-weight: normal;
}
.modelRowGroupCubeSelected {
	background: rgb(53,107,141);
	color: white;
	font-weight: bold;
}
.modelRowGroup {
	color: rgb(67,67,67);
}
.modelRowGroupSelected {
	background: rgb(53,107,141);
	color: white;
}

.hdrLink {
	color: #3b84bc;
	font-size: 10pt;
	font-weight: normal;
	text-decoration: none;
	padding-left: 6px;
	padding-right: 6px;
}

.hdrLinkDisabled {
	color: gray;
	font-size: 10pt;
	font-weight: normal;
	text-decoration: none;
	padding-left: 6px;
	padding-right: 6px;
}

.hdrLink:hover {
	color: #98923a;
}

</style>
}

/// This Style block contains page-specific CSS style definitions.
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

.dynaTreeNode {
	white-space: nowrap;
	font-size: 10pt;
}

.dynaTreeItem {
	color: rgb(71,72,67);
}

.detailLabel {
	font-weight: bold;
	color: rgb(71,72,67);
	font-size: 10pt;
}

#editorPane {
	position: relative;
}

#modelTableHeader {
	height: 40px;
	top: 0px;
	background: #F0F0F0;
	overflow: hidden;
}

#modelTableBody {
	top: 40px;
	height: 200px;
	border: 1px solid gray;
	overflow: auto;
	background: white;
}

#tree {
	background: white;
	width: 200px;
	overflow: auto;
	border-top: 1px solid gray;
	border-bottom: 1px solid gray;
}

#propertyPane {
	position: relative;
	background: rgb(156,154,141);
	height: 449px;
	width: 350px;
	border-right: 1px solid black;
	border-bottom: 1px solid black;
	display: none;
}

/* styles for tabs */
#tabDetails,#tabTools {
	overflow: auto;
	padding-left: 3px;
	color: #404040;
}

td.tabGroupButtonOff:hover {
	color: #FFEEAA;
}

.tabGroupBody {
	background: #E0E0D0;
	width: 399px;
	min-height: 300px;
}

td.tabGroupButtonOn {
	height: 30px;
	color: #404040;
	background: #E0E0D0;
	font-size: 10pt;
}

td.tabGroupButtonOn:not([ie]) {
	background: -moz-linear-gradient(top, #F8F8FF, #E0E0D0);
	-moz-border-radius-topleft:4px;
	-moz-border-radius-topright:4px;

	background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#F8F8FF), color-stop(1.0,#E0E0D0));
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

/* @doc="Individual tab bar button in Off state." */
td.tabGroupButtonOff,
td.tabGroupButtonDisabled {
	height: 30px;
	color: #404040;
	background: #C0C0C0;
	font-size: 10pt;
	background-image: none;
	background-repeat: repeat-x;
}
td.tabGroupButtonOff:hover {
	background: #C0C0C0;
}

td.tabGroupButtonDisabled {
	color: gray;
}

td.tabGroupButtonOff:not([ie]) {
	background: -moz-linear-gradient(top, #B0B0B0, #D0D0D0);
	-moz-border-radius-topleft:4px;
	-moz-border-radius-topright:4px;

	background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#B0B0B0), color-stop(1.0,#D0D0D0));
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

td.tabGroupButtonDisabled:not([ie]) {
	background: -moz-linear-gradient(top, #B0B0B0, #D0D0D0);
	-moz-border-radius-topleft:4px;
	-moz-border-radius-topright:4px;

	background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#B0B0B0), color-stop(1.0,#D0D0D0));
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

.tabGroupGap {
	width: 0px;
}

#propertyTitle {
	height: 40px;
	width: 40px;
}

#spanArrow {
	padding-left: 10px;
	color: white;
	font-size: 20pt;
	text-shadow: black 1px 1px 1px;
}

#propertyCommands {
	color: white;
}

table.modelTable {
	background: white;
	width: 100%;
	font-size: 10pt;
}

table.modelTable td {
	padding: 2px;
	border-bottom: 1px solid rgb(241,240,231);
}

.modelError {
	color: #404040;
	font-size: 24px;
	padding: 10px;
	background: lightgray;
}

span.selector {
	visibility: hidden;
}

.modelRowGroupsSelected span.selector,
.modelRowGroupSelected span.selector,
.modelRowGroupCubeSelected span.selector,
.modelRowSASelected span.selector,
.modelRowGroupSelected span.selector {
	visibility: visible;
}
.modelRowGroups {
	color: rgb(67,67,67);
	font-size: 1.2em;
	font-weight: bold;
	background: #D0D0FF;
}
.modelRowGroupsSelected {
	font-size: 1.2em;
	font-weight: bold;
	color: white;
	background: rgb(53,107,141);
}

.modelRowGroup {
	color: rgb(67,67,67);
	font-weight: bold;
	background: #F0F0FF;
}
.modelRowGroupSelected {
	font-weight: bold;
	color: white;
	background: rgb(53,107,141);
}

.modelRowGroupCube {
	color: rgb(67,67,67);
	font-weight: bold;
}
.modelRowGroupCubeSelected {
	color: white;
	font-weight: bold;
	background: rgb(53,107,141);
}
.modelRowGroup {
	color: rgb(67,67,67);
}
.modelRowGroupSelected {
	color: white;
	background: rgb(53,107,141);
}

.modelRowSA {
	font-style: italic;
	color: rgb(67,67,67);
}
.modelRowSASelected {
	font-style: italic;
	color: white;
	background: rgb(53,107,141);
}

.hdrLink {
	font-size: 10pt;
	font-weight: normal;
	color: #3b84bc;
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
	color: #98923a;
}

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">

<!-- Get Cube Map Definition in JSON format -->
<jsonProvider id="cube"
	OnGetTargetObject="GetMapDefinition"
	OnSubmitContent="SubmitMap"
/>

<hgroup id="mainGroup" cellVAlign="top">
<vgroup id="editorPane">
<html id="modelTableHeader" OnDrawContent="DrawTableHeader"></html>
<hgroup cellVAlign="top">
<dynaTree id="tree" 
imageContracted="portal/disc_up_16.gif"
imageExpanded="portal/disc_down_16.gif"
imageNode=""
showLines="false" showFolders="false" dragEnabled="true" 
OnGetTreeInfo="GetTreeInfo">
</dynaTree>
<html id="modelTableBody" dropEnabled="true" ondrop="return zenPage.tableDropHandler(dragData);"></html>
<vgroup id="modelTable" valign="top" hidden="true">
<tableNavigatorBar showFilter="true" showPageSize="true" tablePaneId="table" showMaxRows="true" 
onfilterChange="zenPage.filterChanged(value);"
title="Enter characters of Cube Name followed by [Tab] to filter the list. "/>
<tablePane id="table" cellSpacing="2"
queryClass="%DeepSee.CubeManager.RegistryMap"
queryName="RegistryMapTableView"
dataSource="columns"
fixedHeaders="false"
initialExecute="false"
maxRows="1000"
multiSelect="false"
showValueInTooltip="false"
showZebra="true"
valueColumn="CubeKey"
useSnapshot="true"
onselectrow="zenPage.selectTableItem(zenThis.getValue());"
>
<column colName="CubeKey" header="Cube Name"/>
<column colName="MgmtGroup" header="Group Name"/>
<column colName="IsRegistered" header="Registered" style="horizontal-align:center"/>
<column colName="Disabled" header="Exclude"/>
<column colName="CustomBuildOrder" header="Group Build Order"/>
<column colName="UpdatePlan" header="Update Plan"/>
<column colName="DSTimeEnabled" header="Supports Synchronize"/>
<column colName="BuildEvery" header="Build Every"/>
<column colName="SynchEvery" header="Synch Every"/>
<parameter id="tfilter" value="" />
 <!-- When status is Unregistered, give it a different row background color (same as unmounted database) -->
<condition colName="IsRegistered" predicate="EQ" value="No" rowStyle="background: #FFB6C1;" cellStyle="disabled"/>
 <!-- When status is Disabled, give it a different row background color -->
<condition colName="Disabled" predicate="EQ" value="Yes" rowStyle="background: #C0C0C0;" cellStyle="disabled"/> 

 </tablePane>
 </vgroup>
</hgroup>
</vgroup>
<vgroup id="propertyPane">
<html id="propertyTitle"><span id="spanArrow" title="#(%page.hlpShowHide)#" onclick="zenPage.toggleSettings();" onmouseover="this.style.color='#FFEEAA';this.style.cursor='pointer'" onmouseout="this.style.color='';this.style.cursor='';">&#187;</span></html>
<tabGroup id="propertyTabs" showTabBar="true">
<tab id="tabDetails" caption="Details">
<vgroup>
<spacer height="5"/>
<vgroup id="defaultDetails" label="Select a row to view details"/>
<vgroup id="namespaceDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<fieldSet legend="Cube Registry Settings" width="100%">
<text id="detailNamespaceStorage" label="Storage Class:" disabled="true" size="44"/>
<hgroup label="Description" cellStyle="padding:3px;" cellVAlign="top">
<text id="detailNamespaceDescription" size="42" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailNamespaceDescription" hidden="true" cols="32" rows="4" onchange="zenPage.applyDescription('detailNamespaceDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailNamespaceDescription');"/>
</hgroup>
<spacer height="10"/>
<html hidden="false"><hr width="100%"/></html>
<vgroup labelPosition="left" cellStyle="padding-right:10px;">
<checkbox id="detailNamespaceDisabled" label="Disable" title="If checked, the automated Build and Synch tasks for this namespace will be suspended" onchange="zenPage.applyDetails();"/>
<checkbox id="detailNamespaceIndependentSync" label="Synchronize Independently" title="If checked, this will allow synchronize to ignore relationship dependecies" hidden="true" onchange="zenPage.confirmSyncExemption();"/>
<select id="detailNamespaceSerialUpdates" clientType="boolean" valueList="false,true" displayList="In Parallel,Serially" label="Update Groups " showEmpty="false" title="Controls how groups are updated, with respect to each other. The automated tasks can update groups one at a time or in parallel." onchange="zenPage.applyDetails();"/>
</vgroup>
<spacer height="15"/>
<vgroup label="Allow build to start after this time:" labelClass="detailLabel" cellAlign="right" width="80%">
<hgroup> 
<spacer width="10%"/>
<select id="detailNamespaceBuildStartHour" label="Hour" valueList="00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23" showEmpty="false" onchange="zenPage.applyDetails();"/>
<spacer width="5"/>
<select id="detailNamespaceBuildStartMinute" label="Minute" valueList="00,15,30,45" showEmpty="false" onchange="zenPage.applyDetails();"/>
</hgroup>
</vgroup>
</fieldSet>
<fieldSet legend="Maintenance">
<spacer height="5"/>
<button id="btnBuildAllRegisteredGroups" caption="Build All Registered Groups" onclick="zenPage.buildAllRegisteredGroups();" title="This will initiate a build of all cubes in all registered groups." />
</fieldSet>
</vgroup>
<!-- End of Namespace Details -->
<vgroup id="groupDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<fieldSet legend="Registered Group">
<text id="detailGroupName" label="Name" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<spacer height="5"/>
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<checkbox id="detailGroupDisabled" label="Exclude" title="If checked this group will be excluded from automatic updates" onchange="zenPage.applyDetails();"/>
</hgroup>
</fieldSet>
<fieldSet legend="Update Plan">
<group id="groupGroupUpdatePlan">
<select id="detailGroupUpdatePlan" displayList="Build and Synch,Build Only,Synch Only,Manual" valueList="BuildSynch,Build,Synch,Manual" 
showEmpty="false" onchange="zenPage.applyDetails();"/>
<html><hr width="100%"/></html>
<vgroup >
<vgroup id="GroupGroupBuild" label="Build every" >
<hgroup>
<text id="detailGroupBuildFrequency" size="2" onchange="zenPage.applyDetails();"/>
<select id="detailGroupBuildTimeUnit" displayList="Day,Week,Month" valueList="Day,Week,Month" value="Week" showEmpty="false" onchange="zenPage.applyDetails();"/>
<select id="detailGroupBuildDayOfMonth" value="Week" showEmpty="false" onchange="zenPage.applyDetails();"/>
<select id="detailGroupBuildDayOfWeek" displayList="Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday" valueList="1,2,3,4,5,6,7" value="1" showEmpty="false" onchange="zenPage.applyDetails();"/>
</hgroup>
<vgroup id="GroupGroupBuildAsynch" labelPosition="left" cellStyle="padding-right:10px;" >
<spacer height="10"/>
<checkbox id="detailGroupBuildAsynch" label="Build Cubes Synchronously" title="If checked and applied, cube builds will not use the DeepSee Agents for parallel processing" onchange="zenPage.applyDetails();"/>
</vgroup>
</vgroup>
<html id="detailGroupBuildSynchSeparator" hidden="false"><hr width="100%"/></html>
<hgroup id="GroupGroupSynch" label="Synch every" >
<text id="detailGroupSynchFrequency" size="2" onchange="zenPage.applyDetails();"/>
<select id="detailGroupSynchTimeUnit" displayList="Minute,Hour,Day" valueList="Minute,Hour,Day" value="Day" showEmpty="false" onchange="zenPage.applyDetails();"/>
</hgroup>

<vgroup id="GroupManualText" hidden="true">
<spacer height="10"/>
<label label="The Cube Manager does not automatically update these cubes. It is the responsibility of your application to manage the updates."/>
</vgroup>
</vgroup>
</group>
<label id="msgGroupSystemUpdate" label="#(%page.msgSystemUpdates)#" hidden="true"/>
</fieldSet>
<vgroup>
<button id="detailGroupApply" caption="Apply to All Cubes in Group" onclick="zenPage.doApplyGroupChange();" hint="Apply the above group values to all cubes in the group"/>
</vgroup>
<fieldSet legend="Maintenance">
<spacer height="5"/>
<button id="btnBuildOneRegisteredGroup" caption="Build This Group" onclick="zenPage.buildOneRegisteredGroup();" title="This will initiate a build of this group." />
</fieldSet>
</vgroup>

</vgroup>
<!-- End of Group Details -->

<vgroup id="cubeDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<fieldSet legend="Registered Cube">
<text id="detailCubeName" label="Name" size="44" disabled="true"/>
<spacer height="5"/>
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<checkbox id="detailCubeDisabled" label="Exclude" title="If checked this cube will be excluded from automatic updates" onchange="zenPage.applyDetails();"/>
</hgroup>
<spacer id="idMergeSpacer" height="15" hidden="true"/>
<label id="labelCubeGroupName"/>
<checkbox id="chkCubeGroupMerge" caption="Merge to another group" captionClass="zenLabel" onclick="zenPage.doMergeLoadList();"/>
<hgroup id="idCubeGroupMerge" hidden="true">
<select id="selCubeGroupMerge" label="Which Group?" containerStyle="padding-left:22px;" />
<button id="btnCubeGroupMerge" caption="Merge" onclick="zenPage.doMerge();" valign="bottom"/>
</hgroup>
</fieldSet>

<fieldSet legend="Update Plan">
<group id="groupCubeUpdatePlan">
<hgroup>
<select id="detailCubeUpdatePlan" displayList="Build and Synch,Build Only,Synch Only,Manual" valueList="BuildSynch,Build,Synch,Manual" showEmpty="false" onchange="zenPage.applyDetails();"/>
<spacer width="10"/>
<label id="detailCubeDSTimeEnabled" label="" disabled="true"/>
</hgroup>
<html><hr width="100%"/></html>
<vgroup id="CubeGroupBuild" label="Build every" cellStyle="padding:3px;" cellVAlign="top">
<hgroup>
<text id="detailCubeBuildFrequency" size="2" onchange="zenPage.applyDetails();"/>
<select id="detailCubeBuildTimeUnit" displayList="Day,Week,Month" valueList="Day,Week,Month" value="Week" showEmpty="false" onchange="zenPage.applyDetails();"/>
<select id="detailCubeBuildDayOfMonth" value="1" showEmpty="false" onchange="zenPage.applyDetails();"/>
<select id="detailCubeBuildDayOfWeek" displayList="Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday" valueList="1,2,3,4,5,6,7" value="1" showEmpty="false" onchange="zenPage.applyDetails();"/>
</hgroup>
<hgroup label="Post-Build Code" cellStyle="padding:3px;" cellVAlign="top">
<text id="detailCubePostBuildCode" onchange="zenPage.applyDetails();" title="Enter a line of COS that will execute immediately after the cube has been built" />
<textarea id="areadetailCubePostBuildCode" hidden="true" cols="32" rows="4" onchange="zenPage.applyDescription('detailCubePostBuildCode');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailCubePostBuildCode');"/>
</hgroup>
<vgroup id="CubeGroupBuildAsynch" labelPosition="left" cellStyle="padding-right:10px;" >
<spacer height="10"/>
<checkbox id="detailCubeBuildAsynch" label="Build Cube Synchronously" title="If checked this cube build will not use the DeepSee Agents for parallel processing" onchange="zenPage.applyDetails();"/>
</vgroup>
</vgroup>
<html id="detailCubeBuildSynchSeparator" hidden="false"><hr width="100%"/></html>
<vgroup id="CubeGroupSynch" cellStyle="padding:3px;" cellVAlign="top">
<hgroup id="HCubeGroupSynch" label="Synchronize every">
<text id="detailCubeSynchFrequency" size="2" onchange="zenPage.applyDetails();"/>
<select id="detailCubeSynchTimeUnit" displayList="Minute,Hour,Day" valueList="Minute,Hour,Day" value="Day" showEmpty="false" onchange="zenPage.applyDetails();"/>
</hgroup>
<hgroup label="Pre-Synchronize Code" cellStyle="padding:3px;" cellVAlign="top">
<text id="detailCubePreSynchCode" onchange="zenPage.applyDetails();" title="Enter a line of COS that will execute just before the cube is synchronized" />
<textarea id="areadetailCubePreSynchCode" hidden="true" cols="32" rows="4" onchange="zenPage.applyDescription('detailCubePreSynchCode');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailCubePreSynchCode');"/>
</hgroup>
<hgroup label="Post-Synchronize Code" cellStyle="padding:3px;" cellVAlign="top">
<text id="detailCubePostSynchCode" onchange="zenPage.applyDetails();" title="Enter a line of COS that will execute immediately after the cube has been synchronized"/>
<textarea id="areadetailCubePostSynchCode" hidden="true" cols="32" rows="4" onchange="zenPage.applyDescription('detailCubePostSynchCode');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailCubePostSynchCode');"/>
</hgroup>

</vgroup>
<vgroup id="CubeManualText" hidden="true">
<spacer height="10"/>
<label label="The Cube Manager does not automatically update this cube. It is the responsibility of your application to manage the updates."/>
</vgroup>
</group>
<label id="msgCubeSystemUpdate" label="#(%page.msgSystemUpdates)#" hidden="true"/>
</fieldSet>
<fieldSet legend="Maintenance">
<spacer height="5"/>
<button id="btnRepairBuild" caption="Build Dependency List" onclick="zenPage.repairBuild();" title="This will initiate a build of this cube. If there are dependent cubes, they will also be built in the order listed"/>
<vgroup id="VDependentCubes">
<spacer height="10"/>
<textarea id="detailDependentCubes" label="Dependent Cubes" readOnly="true" cols="30"/>
</vgroup>
</fieldSet>
</vgroup>
<!-- End of Cube Details (for both Tree view and Table view) -->

<vgroup id="cubeSADetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<fieldSet legend="Subject Area">
<text id="detailCubeSAName" label="Name" size="44" disabled="true"/>
<label id="detailCubeSAIsCompound" label="IsCompound" disabled="true"/>
</fieldSet>
</vgroup>
<!-- End of Cube Subject Area Details -->

<fieldSet id="cubeTableCubeDetails" legend="Unregistered Group" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<text id="detailTableCubeGroupName" label="Default Name" size="44" readOnly="true"/>
<spacer height="5"/>
<button id="detailTableCubeRegister" caption="Register Group" hint="All cubes in the same group must be registered together" onclick="zenPage.doRegister();"/>
<textarea id="detailTableCubes" label="Grouped Cubes" cols="30" rows="10" readOnly="true"/>
</fieldSet>
<!-- End of Unregistered Cube Details (for Table view only) -->
</tab>

<tab caption="Tools" id="tabTools" labelPosition="left" title="Various tools for working with DeepSee data models">
<vgroup cellStyle="padding-left:3px;">
<label label="Various tools for working with DeepSee data models"/>

<hgroup id="toolAna" cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/comparison_chart_48.gif"/>
<vgroup>
<button caption="Analyzer" controlClass="commandButton" title="Use the Analyzer" onclick="zenPage.toolMenu('Analyzer');"/>
<label label="Use the Analyzer to view last selected cube."/>
</vgroup>
</hgroup>

<hgroup id="toolArc" cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/architect_48.gif"/>
<vgroup>
<button caption="Architect" controlClass="commandButton" title="Use the Architect" onclick="zenPage.toolMenu('Architect');"/>
<label label="Use the Architect to view last selected cube."/>
</vgroup>
</hgroup>

<hgroup id="toolQue" cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/sql_query_48.gif"/>
<vgroup>
<button caption="Query Tool" controlClass="commandButton" title="Use the Query Tool" onclick="zenPage.toolMenu('MDXQuery');"/>
<label label="Use the Query Tool to run queries against last selected cube."/>
</vgroup>
</hgroup>

<hgroup id="toolMod" cellStyle="padding: 10px;" cellVAlign="top">
<image src="deepsee/ds2_orgchart_44.png" width="44" height="44"/>
<vgroup>
<button caption="Model Browser" controlClass="commandButton" title="Use the Model Browser" onclick="zenPage.toolMenu('ModelBrowser');"/>
<label label="Use the Model Browser to view relationships between cube models."/>
</vgroup>
</hgroup>

</vgroup>
</tab>
</tabGroup>
</vgroup>
</hgroup>
</pane>
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Set tActiveRegistry = ##class(%DeepSee.CubeManager.Utils).GetActiveRegistry()
	If (tActiveRegistry="") {
		Quit ..%OnGetPageName()
	}
	Quit tActiveRegistry
}

Method GetTitle() As %String [ ZenMethod ]
{
	Quit ##class(%DeepSee.CubeManager.Utils).GetActiveRegistry()
}

/// Get the title string to add to the locator row.
/// This should be implemented in a subclass.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return zenPage.GetTitle();
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Cube Registry","%DeepSee")
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
	Set pRibbonTitle = ..%GetPageName()

	//Set pViewIcons(1) = $LB("cubes",$$$Text("Show related cubes"),"portal/view_cubes.png")
	Set pViewIcons(2) = $LB("cube",$$$Text("Show tree view"),"portal/view_cube.png")
	Set pViewIcons(3) = $LB("table",$$$Text("Show table view"),"portal/view_facts.png")

	// commands
	// $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("cmdExpand",$$$Text("Expand All"),$$$Text("Expand all elements"),"zenPage.toggleExpand(1);")
	Set pCommands(2) = $LB("cmdCollapse",$$$Text("Collapse All"),$$$Text("Collapse all elements"),"zenPage.toggleExpand(0);")
	Set pCommands(3) = $LB("cmdSave",$$$Text("Save"),$$$Text("Save this registry definition"),"zenPage.save();")

	Quit $$$OK
}

/// Draw the contents of the Table Header (the region between the diagram and the table).
Method DrawTableHeader(pSeed As %String) As %Status
{
	Set msgUndo = $$$Text("Undo")
	Set hlpUndo = $$$Text("Undo the last change to this model")
	&html<<div style="position:relative;">>
	&html<<div style="position:absolute;top:16px;left:224px;font-weight:bold;color:#404040;">&nbsp;&nbsp;
	&nbsp;&nbsp;<a id="cmdUndo" class="hdrLinkDisabled" disabled="true" href="#" title="#(hlpUndo)#" onclick="zenPage.undo();return false;">#(msgUndo)#</a>
	</div>>
	Set tmsg=$$$Text("THIS CUBE REGISTRY IS DISABLED FOR THIS NAMESPACE")
	&html<<div id="RegistryDisabled" style="display:none;position:absolute;top:16px;left:340px;color:#da4848;font-size:16px;font-weight:bold;">&nbsp;&nbsp;&nbsp;&nbsp;#(tmsg)#</div>>
	Quit $$$OK
}

/// Provide contents of the data source tree.
ClassMethod GetTreeInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	
	Try {
	     #; each node supplies: $LB(caption, value, hasChildren, link, expanded, icon, tooltip, style)
		//Set iconFolder = ..Link("/csp/broker/deepsee/folder_16.png")
		Set iconFolder = ..Link("/csp/broker/deepsee/ds2_box3_44.png")
		//Set iconItem = ..Link("/csp/broker/deepsee/cube_24.gif")
		Set iconItem = ""
		Set pObject = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap(.tSC)
		If $$$ISERR(tSC) { 
			// DTB449
			Set pTree(1) = $LB($$$Text("Error Loading Groups","%DeepSee"),"noGroups",0,,0,,,)		// DTB135 set Value to communicate an empty tree
			Set pTree(0,"ch",1) = ""
			Set tSC = $$$OK
			Quit	
		}
		
		Set tExpanded = 1
		Set tTotal = pObject.Groups.Count()
		If (tTotal = 0) {
			Set pTree(1) = $LB($$$Text("No Unregistered Groups","%DeepSee"),"noGroups",0,,0,,,)		// DTB135 set Value to communicate an empty tree
			Set pTree(0,"ch",1) = ""
			Quit
		}
		Set tIndexTotal = 1
		If pRoot = "" {
			Set tExpend = 0
			Set pTree(tIndexTotal) = $LB($$$Text("Unregistered Groups","%DeepSee"),"root",1,,tExpend,,,)
			Set pTree(0,"ch",tIndexTotal) = ""
		} Else {
			Set tGroupIndex = ""
			For ii=1:1:tTotal {
				Set tGroupObj = pObject.Groups.GetNext(.tGroupIndex)
				Set tIndexTotal = tIndexTotal + 1
				Set tGroupName = tGroupObj.GroupName
				Set IsRegistered = tGroupObj.IsRegistered
				If IsRegistered = 0 {
					Set tCubeIndex = ""
					For jj=1:1:tGroupObj.Cubes.Count() {
						Set tCubeKey = tGroupObj.Cubes.GetNext(.tCubeIndex).CubeKey
			         	Set tGroups(tIndexTotal,tCubeIndex) = tCubeKey			
					}
					Set pTree(0,"ch",tIndexTotal) = ""
					#; Set Groups
			        Set pTree(tIndexTotal) = $LB(tGroupName,tGroupName,1,"",tExpanded,iconFolder,tGroupName,"font-size:14px;font-weight:bold;")
				}
			}
			Set ii = $O(tGroups(""))
			While ii '= "" {
				Set jj = $O(tGroups(ii,""))
				While jj '= "" {
			        Set tIndexTotal = tIndexTotal + 1
		         	Set pTree(ii,"ch",tIndexTotal) = ""
		         	#; Set Cube value to null so it's not dragable.
		     		Set pTree(tIndexTotal) = $LB(tGroups(ii,jj),tGroups(ii,jj),0,"",1,iconItem,tGroups(ii,jj),"font-size:11px;color:black;style.cursor:default;")		// DTB135 - set Value as well as Text
					Set jj = $O(tGroups(ii,jj))	
				}
				Set ii = $O(tGroups(ii))	
			}
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tSC
}

/// Draw additional stuff in the ribbon bar
Method OnDrawRibbon() As %Status
{
	Quit $$$OK
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		this.updateTable();
		this.adjustSizes();
		
		if (load) {
			// reset scrolling !!!
			var tableBodyDiv = zen('modelTableBody').getEnclosingDiv();
			tableBodyDiv.scrollTop = 0;
			tableBodyDiv.scrollLeft = 0;			
		}
		
		if (load && this.activeRegistryExists) {
	  		this.selectItem('Groups',0);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var propDiv = zen('propertyPane').getEnclosingDiv();
		var editDiv = zen('editorPane').getEnclosingDiv();
		var tableHdrDiv = zen('modelTableHeader').getEnclosingDiv();
		var tableBodyDiv = zen('modelTableBody').getEnclosingDiv();
		var sourceDiv = zen('tree').getEnclosingDiv();
		var proptitleDiv = zen('propertyTitle').getEnclosingDiv();
		var proptabsDiv = zen('propertyTabs').getEnclosingDiv();

		propDiv.style.display = 'block';

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();

		var propWidth = 40;
		if (this.settingsExpanded) {
			propWidth = (winWidth<900) ? 300 : 350;
		}
		propDiv.style.width = propWidth + 'px';

		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th - 25;
		var editorHgt = hgt - 1;
		var editorWid = winWidth - propDiv.offsetWidth - 25;
		hgt = (hgt < 1 ? 1 : hgt);
		editDiv.style.width = editorWid + 'px';
		editDiv.style.height = editorHgt + 'px';
		tableHdrDiv.style.width = editorWid + 'px';
		tableBodyDiv.style.width = editorWid - sourceDiv.offsetWidth + 'px';
		tableBodyDiv.style.height = editorHgt - tableHdrDiv.offsetHeight + 'px';
		sourceDiv.style.height = editorHgt - tableHdrDiv.offsetHeight + 'px';

		propDiv.style.height = hgt - 1 + 'px';

		if (this.settingsExpanded) {
			var tabBodyHgt = (hgt - proptitleDiv.offsetHeight - 30);
			tabBodyHgt = (tabBodyHgt < 1 ? 1 : tabBodyHgt);
			zen('propertyTabs').setBodySize(tabBodyHgt,propDiv.offsetWidth- 2);
			zen('propertyTabs').setHidden(false);
		}
		else {
			zen('propertyTabs').setHidden(true);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Update the contents of the model table.
ClientMethod updateTable() [ Language = javascript ]
{
	this.renderTable();
	if ( this.currItem >= 0 ) {
		this.selectItem(this.currItemType,this.currItem,true);
	}
}

/// Update the contents of the model table.
ClientMethod renderTable() [ Language = javascript ]
{
	try {
		var table = zen('modelTableBody');
		var html = new Array();
		var map = this.getCubeObject();
		var source,type;

		// show warning message if namespace registry is diabled.
		document.getElementById("RegistryDisabled").style.display = (map.Disabled) ? "block" : "none";
		
		// maps row number in the table back to an item in the model
		this._rowIndex = new Array();
		
		// n.b., we add a _parent and _index decoration to each element in the tree as we render

		if (null == map) {
			html[html.length] = '<div class="modelError">' + this.msgInvalid + '</div>';
		}
		else {
			// we also add an array to track if disclosures are open or closed
			if (null == map._contracted) {
				map._contracted = new Object();
			}

			// create table displaying map model.
			html[html.length] = '<table class="modelTable" border="0" cellspacing="0">';
			var indentGroup = '<img height="1px" width="2px" src="images/spacer.gif"/>';
			var indentCube  = '<img height="1px" width="14px" src="images/spacer.gif"/>';
			var indentSA    = '<img height="1px" width="24px" src="images/spacer.gif"/>';
			var disc = '';
			var remove = '';
			var enabler = '';
			var style = '';
			// map
			var lblGroup = $$$Text("Group");
			var lblCube = $$$Text("Cube");
			var lblSA = $$$Text("Subject Area");
			var hlpGroupRow = $$$Text("click to view settings for namespace");
			map._type = 'Groups';
			this._rowIndex[this._rowIndex.length] = map;
			html[html.length] = '<tr class="modelRowGroups" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'Groups\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'Groups\',this);" onmouseout="zenPage.rowMouseOut(this);">';
			html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
			html[html.length] = '<td title="'+hlpGroupRow+'">' + $$$Text("Registered Groups") + '</td>';
			html[html.length] = '<td nowrap>' + $$$Text("Build Frequency") + '&nbsp;</td>';
			html[html.length] = '<td nowrap>' + $$$Text("Synch Frequency") + '&nbsp;</td>';
			html[html.length] = '<td>' + enabler + '&nbsp;</td>';
			html[html.length] = '<td>' + remove + '&nbsp;</td>';
			html[html.length] = '</tr>';
			var groupLen =  map.Groups.length;
			for (var d = 0; d < groupLen; d++) {
			  var group = map.Groups[d];
			  if (group.IsRegistered) {
				group._parent = map;
				group._index = d;
				group._type = "Group";
				this._rowIndex[this._rowIndex.length] = group;
				var closed = this.isClosed(map,'group'+d);
				if (groupLen > 1) {
					moveup = '<img width="16px" src="' + 'deepsee/up_16.png' + '" title="' + this.hlpMoveUp + '" onclick="zenPage.moveItemUp(\'Group\','+(this._rowIndex.length-1)+','+d+');" />';
					movedn = '<img width="16px" src="' + 'deepsee/down_16.png' + '" title="' + this.hlpMoveDown + '" onclick="zenPage.moveItemDown(\'Group\','+(this._rowIndex.length-1)+','+d+');" />';
				} else {
					moveup = '';
					movedn = '';
				}				
				var build = "";
				if ((!group.UserUpdatesLocked)&&(group.UpdatePlan.indexOf("Build")) > -1) build = group.BuildFrequency + ' ' + group.BuildTimeUnit + ' ' + this.getDayOf(group);		// DTB691 - Check user lock		
				var synch = "";
				if ((!group.UserUpdatesLocked)&&(group.UpdatePlan.indexOf("Synch")) > -1) synch = group.SynchFrequency + ' ' + group.SynchTimeUnit;		// DTB691 - Check user lock
				disc = '<img width="16px" src="' + (!closed ? this.imgArrow1D : this.imgArrow1R) + '" onclick="zenPage.toggleDisclosure(\'group'+d+'\');"/>';
				remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'Group\','+(this._rowIndex.length-1)+','+d+');" />';
				style = (group.Disabled) ? 'style="background:#C0C0C0;"' : '';
				html[html.length] = '<tr class="modelRowGroup" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'Group\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'Group\',this);" onmouseout="zenPage.rowMouseOut(this);">';
				html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
				html[html.length] = '<td title="'+lblGroup+'">' + indentGroup + disc + zenEscapeXML(group.GroupName) + '</td>';
				html[html.length] = '<td>' + build + '&nbsp;</td>';
				html[html.length] = '<td>' + synch + '&nbsp;</td>';
				if (!group.UserUpdatesLocked) {
					// DTB691 - Only show these if user can make changes to the group
					html[html.length] = '<td>' + remove + '&nbsp;</td>';
				}
				else {
					html[html.length] = '<td>&nbsp;</td>';
				}
				html[html.length] = '<td>' + moveup + '&nbsp;' + movedn + '</td>';
				html[html.length] = '</tr>';
				if (!closed) {
					for (var h = 0; h < group.Cubes.length; h++) {
						var groupCube = group.Cubes[h];
						groupCube._parent = group;
						groupCube._index = h;
						groupCube._dimtype = group.SubjectAreas;
						groupCube._type = "Cube";
						var build = "";
						if ((!group.UserUpdatesLocked)&&(groupCube.UpdatePlan.indexOf("Build")) > -1) build = groupCube.BuildFrequency + ' ' + groupCube.BuildTimeUnit + ' ' + this.getDayOf(groupCube);		// DTB691 - Check user lock		
						var synch = "";
						if ((!group.UserUpdatesLocked)&&(groupCube.UpdatePlan.indexOf("Synch")) > -1) synch = groupCube.SynchFrequency + ' ' + groupCube.SynchTimeUnit;		// DTB691 - Check user lock
						this._rowIndex[this._rowIndex.length] = groupCube;
						style = (groupCube.Disabled) ? 'style="background:#C0C0C0;"' : '';
						html[html.length] = '<tr class="modelRowGroupCube" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'Cube\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'GroupCube\',this);" onmouseout="zenPage.rowMouseOut(this);">';
						html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
						html[html.length] = '<td title="'+lblCube+'">' + indentCube + zenEscapeXML(groupCube.CubeKey) + '</td>';
						html[html.length] = '<td>' + build + '&nbsp;</td>';
						html[html.length] = '<td>' + synch + '&nbsp;</td>';
						html[html.length] = '<td>' + '&nbsp;</td>';
						html[html.length] = '<td>' + '&nbsp;</td>';
						html[html.length] = '</tr>';
						var isCompound = $$$Text("Is Compound: ");
						for (var s = 0; s < groupCube.SubjectAreas.length; s++) {
							var groupCubeSA = groupCube.SubjectAreas[s];
							groupCubeSA._parent = group;
							groupCubeSA._index = s;
							groupCubeSA._type = "CubeSA";
							this._rowIndex[this._rowIndex.length] = groupCubeSA;
							html[html.length] = '<tr class="modelRowGroupCube" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'CubeSA\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'cubeSA\',this);" onmouseout="zenPage.rowMouseOut(this);">';
							html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
							html[html.length] = '<td title="'+lblSA+'" style="font-style:italic;">' + indentSA + zenEscapeXML(groupCubeSA.SAName) + '</td>';
							//html[html.length] = '<td>' + isCompound + ' ' + groupCubeSA.IsCompound + '&nbsp;</td>';
							html[html.length] = '<td>' + '&nbsp;</td>';
							html[html.length] = '<td>' + '&nbsp;</td>';
							html[html.length] = '</tr>';	
						}
					}
				}
			}
		}
		html[html.length] = '</table>'; 
		}
		table.setContent(html.join(''));
		this.expandAll = 2;
	  	
	  	} catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in renderTable');
  	}
}

/// Exempting the synchronize from relationship dependencies is not recommended. When the user
/// attempts to turn this setting off, inform that this is not recommended and confirm that this 
/// is really what the user wants to do.
ClientMethod confirmSyncExemption() [ Language = javascript ]
{
	// Method added by DTB470
	var independentSync = zen('detailNamespaceIndependentSync').getValue();
	if (independentSync) {
		var exemptionMsg = $$$Text('Turning on independent synchronize will cause the synchronize operation to ignore relationship dependencies and is not recommended in a live update environment. Are you sure you want to do this?');
		if (confirm(exemptionMsg)) {
			// Apply the setting once confirmed
			zenPage.applyDetails();
		}
		else {
			zen('detailNamespaceIndependentSync').setValue(false);
		}
	}
	else {
		// Always apply if the setting is being turned off
		zenPage.applyDetails();
	}
}

/// return what to display for day of month or day of week in center pane
ClientMethod getDayOf(item) [ Language = javascript ]
{
	if (item.BuildTimeUnit!="Month"&&item.BuildTimeUnit!="Week") return "";
	
	if (item.BuildTimeUnit=="Month") {
		return (item.BuildDayOfMonth != "") ? "("+item.BuildDayOfMonth+")" : "";
	}
	
	if (item.BuildTimeUnit=="Week") {
		if (item.BuildDayOfWeek == "") return "";
		var days = $$$Text("Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday");
		var daysarray = days.split(",");
		var day = daysarray[item.BuildDayOfWeek-1];
		return "("+day+")";
	}
}

ClientMethod isClosed(map, item) [ Language = javascript ]
{
	var closed = map._contracted[item];
	if (this.expandAll == 0) {
		closed = true;
		map._contracted[item]=true;
	} 
	if (this.expandAll == 1){
		closed = false;
		map._contracted[item]=false;			
	}
	return closed
}

ClientMethod moveItemUp(type, row, index) [ Language = javascript ]
{
	var item = this._rowIndex[row];
	var last = "";
	if (item) {
		row--;
		if (row > 0) {
			var map = this.getCubeObject();
			switch(type) {
			case 'Group':
				if (map.Groups[index-1]) {
					this.addUndoAction();
					last = map.Groups[index-1];
					map.Groups[index-1] = map.Groups[index];
					map.Groups[index] = last;
				}
				break;
			}
			if (last != "") {	
				this.updateTable();
			}
		}
	}
}

ClientMethod moveItemDown(type, row, index) [ Language = javascript ]
{
	var item = this._rowIndex[row];
	var last = "";
	if (item) {
		row++;
		if (row > 0) {
			var map = this.getCubeObject();
			switch(type) {
			case 'Group':
				if (map.Groups[index+1]) {
					this.addUndoAction();
					last = map.Groups[index+1];
					map.Groups[index+1] = map.Groups[index];
					map.Groups[index] = last;
				}
				break;
			}
			if (last != "") {	
				this.updateTable();
			}
		}
	}
}

/// user clicked Expand All (flag=1) or Collapsed All (flag=0). 
ClientMethod toggleExpand(flag) [ Language = javascript ]
{
	this.expandAll = flag;
	this.updateTable();
}

/// Find the row number in the table for the given model item.
/// This must be called after the table has been rendered.
ClientMethod findRowForItem(item) [ Language = javascript ]
{
	var row = -1;
	if (this._rowIndex) {
		for (var r = 0; r < this._rowIndex.length; r++) {
			if (this._rowIndex[r] === item) {
				row = r;
				break;
			}
		}
	}
	return row;
}

/// This class method callback is called just before the server-side page 
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##super()
		If $$$ISERR(tSC) Quit

		If '$$CheckAnalyzerViewAccess^%qdsUtils() Set ..%GetComponentById("toolAna").hidden = 1
		If '$$CheckArchitectViewAccess^%qdsUtils() Set ..%GetComponentById("toolArc").hidden = 1
		
		Set tMonth = "" For m = 1:1:31 Set tMonth = tMonth _ m _ $S(m'=31:",",1:"")
		Set ..%GetComponentById("detailGroupBuildDayOfMonth").valueList = tMonth
		Set ..%GetComponentById("detailCubeBuildDayOfMonth").valueList = tMonth	
		
		Set tRegistryName = ##class(%DeepSee.CubeManager.Utils).GetActiveRegistry()
		Set ..activeRegistryExists = $S(tRegistryName="":0,1:1)
		
		// DTB470 - Show or hide the checkbox to toggle the independent synchronization setting
		Set tIndependentSync = ..%GetComponentById("detailNamespaceIndependentSync")
		Set tIndependentSync.hidden = '##class(%DeepSee.CubeManager.Utils).GetIndependentGroupSync()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Get Registry Map definition for JSON provider.
Method GetMapDefinition(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	If ..reloadMap = 1 Set ..%model = ""
	If $IsObject(..%model) {
		Set pObject = ..%model
	} Else {
		Set pObject = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap()
		Set ..%model = pObject
		Set ..reloadMap = 0
	}
	Quit tSC
}

/// CHUI quick view
ClassMethod ShowMap(showTable = 0)
{
	Set pObject = ##class(%DeepSee.CubeManager.Utils).BuildRegistryMap()	
	w !,"==== Current Registry Map ===="
	w !,$NAMESPACE
	set tGroupIndex = ""
	for ii=1:1:pObject.Groups.Count() {    				// Loop on Groups
		set tGroup = pObject.Groups.GetNext(.tGroupIndex)
		w !,?2,tGroup.GroupName
		w ?20,"GroupIndex: ",tGroupIndex
		w ?35,"IsValid = ",tGroup.IsValid
		w ?50,"IsReg = ",tGroup.IsRegistered
		w ?60,"Disabled = ",tGroup.Disabled  
		
		set tCubeIndex = ""
		for jj=1:1:tGroup.Cubes.Count() {			// Loop on cubes within group
			set tCube = tGroup.Cubes.GetNext(.tCubeIndex)
			w !,?4,tCube.CubeKey
			w "  (NaturalGroup = ",tCube.NaturalGroup,")"
			w ?60,"Disabled = ",tCube.Disabled
			
			set tSAIndex = ""
			for kk=1:1:tCube.SubjectAreas.Count() {	// Loop on subject areas pointing to each cube
				set tSA = tCube.SubjectAreas.GetNext(.tSAIndex)
				w !,?6,tSA.SAName
				w ?35,"IsCompound = ",tSA.IsCompound
			}

		}
	}
	Quit:'showTable
	Set rset = ##class(%ResultSet).%New("%DeepSee.CubeManager.RegistryMap:RegistryMapTableView")
	Set columns = rset.GetColumnCount()
	Set sc = rset.Execute()
	While (rset.Next()) { 
		Write "------------------------",! 
		For col = 1:1:columns { 
			Write rset.GetColumnName(col),": " Write rset.GetData(col),!
		} 
	} 
	Do rset.Close()
	Quit
}

/// Return the cube definition object.
ClientMethod getCubeObject() [ Language = javascript ]
{
	var json = this.getComponentById('cube');
	var map = json.getContentObject();
	return map;
}

/// Return the current selected item.
ClientMethod getSelectedItem() [ Language = javascript ]
{
	var item = null;
	if (this.currItem == -1) {
		this.currItem = 0;	
	}	
	if (this._rowIndex) {
		item = this._rowIndex[this.currItem];
	} 
	return item;
}

/// Launch a popup window to create a new Cube Registry document. 
ClientMethod createNewRegistry() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.CubeRegistryAdd.cls?ACTIVE='+this.activeRegistryExists,'RegistryAdd','status,resizable=no,width=500,height=700');
}

/// Client-side call to switch the active registry
Method SwitchActiveRegistry(pClassName = "") As %Status [ ZenMethod ]
{
	Set tSC = ##class(%DeepSee.CubeManager.Utils).SetActiveRegistry(pClassName)
	Quit $S($$$ISERR(tSC):$system.Status.GetErrorText(tSC),1:tSC)
}

/// Do the actual work of updating the view to match the current view mode.
ClientMethod setViewModeHandler(mode) [ Language = javascript ]
{
	zen('defaultDetails').setHidden(false);
	zen('namespaceDetails').setHidden(true);
	zen('groupDetails').setHidden(true);
	zen('cubeDetails').setHidden(true);
	zen('cubeSADetails').setHidden(true);
	zen('cubeTableCubeDetails').setHidden(true);
	// if user has unsaved changes, save it before switching views
	if (this.pageModified) this.saveMap();
	if (mode == "table") {
		zen("tree").setHidden(true);
		zen("modelTableBody").setHidden(true);
		zen("modelTable").setHidden(false);
		var table = zen("table");
		table.executeQuery();
		self.document.getElementById("command_cmdExpand").className = "commandButtonDisabled";
		self.document.getElementById("command_cmdCollapse").className = "commandButtonDisabled";
	} else {
		// we need to reload the page so that both tree and center table can be reloaded correctly.
		document.location.reload();
	}
	this.adjustSizes();
}

/// User entered something in to the filter. Re-load the table with filter value.
ClientMethod filterChanged(value) [ Language = javascript ]
{
	var table = zen("table");
	table.parameters[0].value = value;
	table.executeQuery();
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	switch(popupName) {
	case 'CubeSave':
		this.saveMap();
		break;
	case 'switchNamespace':
		var homeurl = zenLink("/csp/sys/%25CSP.Portal.Home.zen");
		var url = zenPage.GetNewURL(value,"_DeepSee.UI.CubeRegistry.zen");
		if (url == "" || value == "%SYS") url = homeurl;
		try {
			self.document.location = url;
		}
		catch (ex) {
		}
		break;		
	case 'RegistryAdd':
		var switchRegistryStatus = zenPage.SwitchActiveRegistry(value);
		if (1 != switchRegistryStatus) {
			alert(switchRegistryStatus);
		}
		document.location.reload();
		break;	
	}
}

/// Do save now.
ClientMethod saveMap() [ Language = javascript ]
{
	var json = this.getComponentById('cube');
	var ok = json.submitContent('save');

	// update the SavedTime after save
	if (!ok) {
		// DTB433 - Parse the bare error object for the text. 
		// 		This assumes no '[' and ':' characters exist in the error message.
		var error = json.getError();
		alert(error.slice(error.indexOf(":")+1).split("[")[0].trim());
	} else {
		this.clearUndoBuffer();
		if (this.currViewMode == "table") {
			/// if we come here then the group/cube is already registered.
			var cubeName = zen('table').getValue();
			this.selectTableItem(cubeName);
		} else {
			this.selectItem(this.currItemType,this.currItem,1);
		}
	}
}

/// Preparation for Merging two groups
ClientMethod mergeGroups(mergeFromText, mergeTo, map, index) [ Language = javascript ]
{
	// merge cubes under dragName to GroupName;	
	// example: add cube from group 11 to group 1
	try {
		var toGroup = map.Groups[index];
		var fromGroupIndex = -1;
		// find the index for the fromGroup
		//var groups = " mergeFrom=" + mergeFromText+"\n\n";
		//for (var d = 0; d < map.Groups.length; d++) {
		//	groups = groups+" d="+d + "GroupName = "+map.Groups[d].GroupName + " IsRegistered=" + map.Groups[d].IsRegistered+"\n";
		//}
		//alert(groups);
		for (var d = 0; d < map.Groups.length; d++) {
			if (map.Groups[d].GroupName == mergeFromText) {
				fromGroupIndex = d;
				break;
			}
		}
		if (fromGroupIndex > -1) {
			// now find each cube under this group and add it to the toGroup
			for (var d = 0; d < map.Groups[fromGroupIndex].Cubes.length; d++) {
				var cb = map.Groups[fromGroupIndex].Cubes[d];
				var newCube = new Object();
				newCube.CubeKey = cb.CubeKey;
				newCube.DSTimeEnabled = cb.DSTimeEnabled;
				newCube.UpdatePlan = cb.UpdatePlan;
				newCube.DependentCubes = cb.DependentCubes;
				newCube.BuildFrequency = cb.BuildFrequency;
				newCube.SynchFrequency = cb.SynchFrequency;
				newCube.BuildTimeUnit = cb.BuildTimeUnit;
				newCube.SynchTimeUnit = cb.SynchTimeUnit;
				newCube.BuildDayOfWeek = cb.BuildDayOfWeek;
				newCube.BuildDayOfMonth = cb.BuildDayOfMonth;
				newCube.SubjectAreas = cb.SubjectAreas;
				newCube.NaturalBuildOrder = cb.NaturalBuildOrder;
				newCube.Disabled = cb.Disabled;
				toGroup.Cubes[toGroup.Cubes.length] = newCube;
			}
			// remove group from mapObject
			map.Groups.splice(fromGroupIndex,1);	
		}
  	} catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in mergeGroups');
  	}

	return 1
}

/// User click on a row in the table.
ClientMethod rowClick(type, row) [ Language = javascript ]
{
	if (zenPage._removeItem==row) {
		// DTB750 - Check for the row removal signal. Only select the row if this is not also being fired 
		// as part of a removeItem click!
		this.selectItem('Groups','0');
	}
	else {
		this.selectItem(type,row);
	}

	// DTB750 - Clean this up every time
	zenPage._removeItem = false;
}

/// User clicked "Apply to All Cubes in Group" button to save changes to all cubes for that group.
ClientMethod doApplyGroupChange() [ Language = javascript ]
{
	var GroupName = zen('detailGroupName').getValue();	
	var Disabled = zen('detailGroupDisabled').getValue();
	var BuildFrequency = zen('detailGroupBuildFrequency').getValue();
	var BuildTimeUnit = zen('detailGroupBuildTimeUnit').getValue();
	var BuildDayOfWeek = zen('detailGroupBuildDayOfWeek').getValue();
	var BuildDayOfMonth = zen('detailGroupBuildDayOfMonth').getValue();
	var SynchFrequency = zen('detailGroupSynchFrequency').getValue();
	var SynchTimeUnit = zen('detailGroupSynchTimeUnit').getValue();
	var UpdatePlan = zen('detailGroupUpdatePlan').getValue();
	var BuildAsynch = !zen('detailGroupBuildAsynch').getValue();
	var map = this.getCubeObject();	
	for (var d = 0; d < map.Groups.length; d++) {
		var group = map.Groups[d];
		if (group.GroupName == GroupName) {
			var cubeAlert = "";
			for (var h = 0; h < group.Cubes.length; h++) {
			  	var item = group.Cubes[h];
				item.Disabled = Disabled;
				item.BuildAsynch = BuildAsynch;
				
				if ( (!item.DSTimeEnabled) && (( UpdatePlan=='Synch') || ( UpdatePlan=='BuildSynch')) ) {
					cubeAlert = cubeAlert + '\n' + item.CubeKey;
				} else {
					item.BuildFrequency = BuildFrequency;
					item.BuildTimeUnit = BuildTimeUnit;
					item.BuildDayOfWeek = BuildDayOfWeek;
					item.BuildDayOfMonth = BuildDayOfMonth;
					item.SynchFrequency = SynchFrequency;
					item.SynchTimeUnit = SynchTimeUnit;
					item.UpdatePlan = UpdatePlan;
				}
		 	}
			break;
		}
	}
	if (cubeAlert.length > 0 ) {
		alert($$$Text('Some cubes in this group cannot be synchronized. These update schedules will remain unchanged:','%DeepSee') + cubeAlert);
	} else {
		this.save();
	}
	this.updateTable();
}

/// User checked the Merge checkbox. We now load the registered groups into the drop-down and show it.
ClientMethod doMergeLoadList() [ Language = javascript ]
{
	var isChecked = zen("chkCubeGroupMerge").getValue();
	if (isChecked) {
		var mergeFromGroup = this.detailCubeGroupName;
		var select = zen("selCubeGroupMerge");
		var valueList = "";
		var map = this.getCubeObject();	
		for (var d = 0; d < map.Groups.length; d++) {
			var group = map.Groups[d];
			// include only if group is registered and is not the merge from group.
			if ((group.IsRegistered) && (group.GroupName != mergeFromGroup)) {
				if (valueList != "") valueList = valueList + ",";
				valueList = valueList + group.GroupName;
			}
		}
		select.setProperty("valueList",valueList);
	}
	zen("idCubeGroupMerge").setHidden(!isChecked);
}

/// User clicked Merge from "Merge to Group..." 
ClientMethod doMerge() [ Language = javascript ]
{
	var mergeFromGroup = this.detailCubeGroupName;
	var mergeToGroup = zen('selCubeGroupMerge').getValue();
	if (mergeToGroup == "") {
		alert($$$Text("Please select a group you wish to merge to."));
		zen('selCubeGroupMerge').focus();
		return;
	}
	var msg = this.msgMerge;
	msg = msg.replace("%1",mergeFromGroup);
	msg = msg.replace("%2",mergeToGroup);
	if (confirm(msg)) {
		var map = this.getCubeObject();
		var toGroupIndex = "";
		for (var index = 0; index < map.Groups.length; index++) {
			if (map.Groups[index].GroupName == mergeToGroup) {
				toGroupIndex = index;
				break;
			}
		}
		var ok = this.mergeGroups(mergeFromGroup,mergeToGroup,map,toGroupIndex);
		if (ok) {
			this.save();
			var table = zen('table');
			table.setProperty("selectedIndex",-1);
			table.executeQuery(0);
			zen('defaultDetails').setHidden(false);
			zen('cubeDetails').setHidden(true);
			zen('cubeTableCubeDetails').setHidden(true);	
		}
	}
	return;
}

/// User clicked "Register Group" button to register all cubes for a group when view mode is "table".
ClientMethod doRegister() [ Language = javascript ]
{
	var cubeName = zen('table').getValue();
	var proxy = this.findTableItem(cubeName);
	proxy.group.IsRegistered = 1;
	this.save();
	var table = zen('table');
	table.executeQuery(0);
}

ClientMethod findTableItem(cubeName) [ Language = javascript ]
{
	try {
		var proxy = new zenProxy();
		var map = this.getCubeObject();	
		var item;
		for (var d = 0; d < map.Groups.length; d++) {
			var group = map.Groups[d];
			for (var h = 0; h < group.Cubes.length; h++) {
				if (group.Cubes[h]) {
				  	if (group.Cubes[h].CubeKey == cubeName) {		
					  	item = group.Cubes[h];
					  	proxy.group = group;
					  	proxy.item = item;
						break;
			 		}
				}
		  	}
		}
		return proxy;
	} catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in findTableItem');
	}
}

/// User selected a row from the table view
ClientMethod selectTableItem(cubeName) [ Language = javascript ]
{
	if (cubeName == "") return;
	zen('defaultDetails').setHidden(true);
	var proxy = this.findTableItem(cubeName);
	
	if (proxy.group.IsRegistered) {
		var itemUpdatesLocked = proxy.group.UserUpdatesLocked;		// DTB691
		
		zen('cubeDetails').setHidden(false);
		zen('cubeTableCubeDetails').setHidden(true);
		zen('idMergeSpacer').setProperty('height',15);
		this.loadCubeDetails(proxy.item,itemUpdatesLocked);		// DTB691
		this.showUpdatePlan('Cube',proxy.item.UpdatePlan,proxy.item.BuildTimeUnit);
		var groupValue = $$$Text("This cube belongs to Group: %1.");
		groupValue = groupValue.replace("%1",proxy.group.GroupName);
		zen('labelCubeGroupName').setProperty("label",groupValue);
		this.detailCubeGroupName = proxy.group.GroupName;
		
		zen('detailCubeDisabled').setProperty('hidden',itemUpdatesLocked);		// DTB691
		
	    zen('groupCubeUpdatePlan').setProperty('hidden',itemUpdatesLocked);		// DTB691
	    zen('msgCubeSystemUpdate').setProperty('hidden',!itemUpdatesLocked);		// DTB691
	} else {
		zen('cubeDetails').setHidden(true);
		zen('cubeTableCubeDetails').setHidden(false);
		zen('detailTableCubeGroupName').setValue(proxy.group.GroupName);
		var group = proxy.group;
		var cubes = "";
		for (var h = 0; h < group.Cubes.length; h++) {
			cubes = cubes + group.Cubes[h].CubeKey + "\n";
		}
		zen('detailTableCubes').setValue(cubes);
	}
}

/// Select a row in the table.
ClientMethod selectItem(type, row, force) [ Language = javascript ]
{
	force = ('undefined' == typeof force) ? false : force;
	tab = zen('tabDetails');

	if (this.currItem != row || force) {
		// unhilite
		if (this.currItem >= 0 && this.currItemType != '') {
			var trow = self.document.getElementById('row_' + this.currItem);
			if (trow) {
				trow.className = this.getCSSForType(this.currItemType);
			}
		}

		this.currItem = row;
		this.currItemType = type;

		// hilite
		var trow = self.document.getElementById('row_' + this.currItem);
		if (trow) {
			trow.className = this.getCSSForType(this.currItemType) + 'Selected';
		}
	
		// set contents of detail form
		var item = this._rowIndex[row];
		if(type.length>0 && item && item.length>0 && item!=type) {
			type = '';
		}
		
		var itemUpdatesLocked = (item.UserUpdatesLocked);		// DTB691

		// make appropriate group in details panel visible
		zen('defaultDetails').setHidden(type != '');
		zen('namespaceDetails').setHidden(type != 'Groups');
		zen('groupDetails').setHidden(type != 'Group');
		zen('cubeDetails').setHidden(type != 'Cube');
		zen('cubeSADetails').setHidden(type != 'CubeSA');
		if (item) {
			switch(type) {
			case 'Groups':
				zen('detailNamespaceStorage').setValue(item.StorageClass);
				zen('detailNamespaceDisabled').setValue(item.Disabled);
				zen('detailNamespaceDisabled').setDisabled(itemUpdatesLocked);		// DTB691
				zen('detailNamespaceIndependentSync').setValue(item.IndependentSync);		// DTB470
				zen('detailNamespaceDescription').setValue(item.Description);
				zen('detailNamespaceBuildStartHour').setValue(item.BuildStartHour);
				zen('detailNamespaceBuildStartMinute').setValue(item.BuildStartMinute);
				zen('detailNamespaceSerialUpdates').setValue(item.SerialUpdates);
				zen("btnBuildAllRegisteredGroups").setProperty("disabled",(this.pageModified || item.Disabled || itemUpdatesLocked));		// DTB691
				break;
			case 'Group':
				zen('detailGroupName').setValue(item.GroupName);
				zen('detailGroupDisabled').setValue(item.Disabled);
				zen('detailGroupDisabled').setDisabled(itemUpdatesLocked);		// DTB691
				zen('detailGroupBuildFrequency').setValue(item.BuildFrequency);
				zen('detailGroupBuildTimeUnit').setValue(item.BuildTimeUnit);
				zen('detailGroupBuildDayOfWeek').setValue(item.BuildDayOfWeek);
				zen('detailGroupBuildDayOfMonth').setValue(item.BuildDayOfMonth);
				zen('detailGroupSynchFrequency').setValue(item.SynchFrequency);
				zen('detailGroupSynchTimeUnit').setValue(item.SynchTimeUnit);
				zen('detailGroupUpdatePlan').setValue(item.UpdatePlan);
				zen('detailGroupBuildAsynch').setValue(!item.BuildAsynch);
				this.showUpdatePlan(type,item.UpdatePlan,item.BuildTimeUnit);
				zen("btnBuildOneRegisteredGroup").setProperty("disabled",(this.pageModified || item.Disabled || itemUpdatesLocked));		// DTB691
				
				zen('groupGroupUpdatePlan').setProperty('hidden',itemUpdatesLocked);		// DTB691
				zen('detailGroupApply').setProperty('hidden',itemUpdatesLocked);		// DTB691
			    zen('msgGroupSystemUpdate').setProperty('hidden',!itemUpdatesLocked);		// DTB691
				break;
			case 'Cube':
			    itemUpdatesLocked = (item._parent.UserUpdatesLocked);		// DTB691
				zen('idMergeSpacer').setProperty('height',0);
				this.loadCubeDetails(item,itemUpdatesLocked);
				this.showUpdatePlan(type,item.UpdatePlan,item.BuildTimeUnit);
				
				zen('detailCubeDisabled').setProperty('hidden',itemUpdatesLocked);		// DTB691
				
			    zen('groupCubeUpdatePlan').setProperty('hidden',itemUpdatesLocked);		// DTB691
			    zen('msgCubeSystemUpdate').setProperty('hidden',!itemUpdatesLocked);		// DTB691
				break;
			case 'CubeSA':
				zen('detailCubeSAName').setValue(item.SAName);
				var CompoundNot = item.IsCompound ? '' : 'not'
				zen('detailCubeSAIsCompound').setProperty('label','This is ' + CompoundNot + ' a compound cube');	
			}
			
		}
		// prevent display of all BuildTimeUnit options on first cube select
		zen('cubeDetails').refreshContents();
	}
}

ClientMethod loadCubeDetails(item, systemLock) [ Language = javascript ]
{
try {
	zen('detailCubeName').setValue(item.CubeKey);
	zen('detailCubeDisabled').setValue(item.Disabled);
	zen('detailCubeDisabled').setProperty('hidden',systemLock);		// DTB691
	zen('detailCubeBuildFrequency').setValue(item.BuildFrequency);
	zen('detailCubeBuildTimeUnit').setValue(item.BuildTimeUnit);
	zen('detailCubeBuildDayOfWeek').setValue(item.BuildDayOfWeek);
	zen('detailCubeBuildDayOfMonth').setValue(item.BuildDayOfMonth);
	zen('detailCubeSynchFrequency').setValue(item.SynchFrequency);
	zen('detailCubeSynchTimeUnit').setValue(item.SynchTimeUnit);
	zen('detailCubeBuildAsynch').setValue(!item.BuildAsynch);
	zen('detailCubePreSynchCode').setValue(item.PreSynchCode);
	zen('detailCubePostSynchCode').setValue(item.PostSynchCode);
	zen('detailCubePostBuildCode').setValue(item.PostBuildCode);
	zen('areadetailCubePreSynchCode').setValue(item.PreSynchCode);		// DTB192
	zen('areadetailCubePostSynchCode').setValue(item.PostSynchCode);	// DTB192
	zen('areadetailCubePostBuildCode').setValue(item.PostBuildCode);	// DTB192
	
	var DSTimeNot = $$$Text('Not') + ' ';
	var updateValueList = 'BuildSynch,Build,Synch,Manual';
	var updateDisplayList = $$$Text('Build and Synch,Build Only,Synch Only,Manual');		// DTB192
	if ( (!item.DSTimeEnabled) && (( item.UpdatePlan=='Synch') || ( item.UpdatePlan=='BuildSynch')) ) {
		alert(item.CubeKey + ': ' + $$$Text('This cube cannot be synchronized. Please select a different Update Plan','%DeepSee'));
		updateValueList = ',Build,Manual';
		updateDisplayList = ',' + $$$Text('Build Only,Manual');		// DTB192
		zen('detailCubeUpdatePlan').setValue('');
	} else if (!item.DSTimeEnabled) {
		updateValueList = 'Build,Manual';
		updateDisplayList = $$$Text('Build Only,Manual');			// DTB192
		zen('detailCubeUpdatePlan').setValue(item.UpdatePlan);
	} else if (item.DSTimeEnabled) {
		DSTimeNot = '';
		zen('detailCubeUpdatePlan').setValue(item.UpdatePlan);
	}
	
	zen('detailCubeUpdatePlan').setProperty('valueList',updateValueList);
	zen('detailCubeUpdatePlan').setProperty('displayList',updateDisplayList);
	zen('detailCubeDSTimeEnabled').setProperty('label',DSTimeNot + $$$Text('Synchronize Enabled'));
	zen('chkCubeGroupMerge').setHidden((this.currViewMode!="table")||systemLock);		// DTB691
	
	// Display the dependent cubes if they exist
	if (item.DependentCubes == '') {
		zen('VDependentCubes').setHidden(true);
		zen('detailDependentCubes').setValue('');
	} else {
		if (item.DependentCubes) {
			var dependentCubes = item.DependentCubes.split(",");
			zen('VDependentCubes').setHidden(false);
			var cubes = '';
			for (var h = 0; h < dependentCubes.length; h++) {
				cubes = cubes + dependentCubes[h] + "\n";
			}
			
			zen('detailDependentCubes').setValue(cubes);
			zen('detailDependentCubes').setProperty('rows',h+1);
		}
	}
	
	// disable the repair button if the cube is disabled or the registry is modified 
 	zen('btnRepairBuild').setProperty('disabled',(item.Disabled || this.pageModified));
} catch(ex) {
	zenExceptionHandler(ex,arguments,'Error in loadCubeDetails');
}
}

/// This method shows and hide Build/Synch fields based on the item's UpdatePlan
ClientMethod showUpdatePlan(type, UpdatePlan, BuildTimeUnit) [ Language = javascript ]
{
	switch (UpdatePlan) {
		case 'BuildSynch':
			zen(type+'GroupBuild').setHidden(false);
			zen('detail'+type+'BuildSynchSeparator').setHidden(false);
			zen(type+'GroupSynch').setHidden(false);
			zen("detail"+type+"BuildDayOfMonth").setHidden(BuildTimeUnit!="Month");
			zen("detail"+type+"BuildDayOfWeek").setHidden(BuildTimeUnit!="Week");
			zen(type+"GroupBuildAsynch").setHidden(false);
			zen(type+"ManualText").setHidden(true);
			break;
		case 'Build':
			zen(type+'GroupBuild').setHidden(false);
			zen('detail'+type+'BuildSynchSeparator').setHidden(true);
			zen(type+'GroupSynch').setHidden(true);
			zen("detail"+type+"BuildDayOfMonth").setHidden(BuildTimeUnit!="Month");
			zen("detail"+type+"BuildDayOfWeek").setHidden(BuildTimeUnit!="Week");
			zen(type+"GroupBuildAsynch").setHidden(false);
			zen(type+"ManualText").setHidden(true);
			break;			
		case 'Synch':
			zen(type+'GroupBuild').setHidden(true);
			zen('detail'+type+'BuildSynchSeparator').setHidden(true);
			zen(type+'GroupSynch').setHidden(false);
			zen("detail"+type+"BuildDayOfMonth").setHidden(true);
			zen("detail"+type+"BuildDayOfWeek").setHidden(true);
			zen(type+"GroupBuildAsynch").setHidden(false);
			zen(type+"ManualText").setHidden(true);
			break;			
		case 'Manual':
			zen(type+'GroupBuild').setHidden(true);
			zen('detail'+type+'BuildSynchSeparator').setHidden(true);
			zen(type+'GroupSynch').setHidden(true);
			zen("detail"+type+"BuildDayOfMonth").setHidden(true);
			zen("detail"+type+"BuildDayOfWeek").setHidden(true);
			zen(type+"GroupBuildAsynch").setHidden(true);
			zen(type+"ManualText").setHidden(false);
			break;						
	}
}

ClientMethod buildAllRegisteredGroups() [ Language = javascript ]
{
	var cubeList = '';
	var groupList = '';
	var map = zenPage.getCubeObject();
	for (var i in map.Groups) {
		var Group = map.Groups[i];
		if (Group.IsRegistered==true) {
			var Cubes = Group.Cubes;
			for (var j in Cubes) {
				var Cube = Cubes[j];
				cubeList = cubeList + Cube.CubeKey + '\n';
			}
		}
	}
	var mode = 'all';
	if (!this.canUserModify()) {
		alert('User lacks privileges for this operation');
		return;
	}
	var parms = {
			CUBELIST:cubeList,
			MODE:mode,
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.RepairBuild.cls','CubeBuild','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

ClientMethod buildOneRegisteredGroup() [ Language = javascript ]
{
	var mode='group';	
	var group = zen('detailGroupName').getValue();
	var parms = {
			GROUP:group,
			MODE:mode,
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.RepairBuild.cls','CubeBuild','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

ClientMethod repairBuild() [ Language = javascript ]
{
	var Group = zenPage.getCubeObject().Groups[1];
	var Cubes = zenPage.getCubeObject().Groups[1].Cubes;
	if (!this.canUserModify()) {
		alert('User lacks privileges for this operation');
		return;
	}
	var cubeList = zen("detailCubeName").getValue() + '\n' + zen('detailDependentCubes').getValue();
	var mode = 'repair';	
	var parms = {
			CUBELIST:cubeList,
			MODE:mode,
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.RepairBuild.cls','CubeBuild','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Find the css class for the given row type.
ClientMethod getCSSForType(type) [ Language = javascript ]
{
	switch(type) {
	case 'Groups':
		return 'modelRowGroups';
	case 'Group':
		return 'modelRowGroup';
	case 'Cube':
		return 'modelRowGroupCube';
	case 'CubeSA':
		return 'modelRowGroupCube';
	default:
		alert('Unknown type (css)' + type);
		break;
	}
	return '';
}

/// Apply changes from detail form.
ClientMethod applyDetails() [ Language = javascript ]
{
	
	if (this.currViewMode == "table") {
		/// if we come here then the group/cube is already registered.
		var cubeName = zen('table').getValue();
		var proxy = this.findTableItem(cubeName);
		item = proxy.item;
		this.currItemType = "Cube";		
	} else {
		var item = this._rowIndex[this.currItem];
	}
	if (item) {
		this.addUndoAction();
		switch(this.currItemType) {
		case 'Groups':
			item.Disabled = zen("detailNamespaceDisabled").getValue();
			item.IndependentSync = zen('detailNamespaceIndependentSync').getValue();		// DTB470
			item.Description = zen("detailNamespaceDescription").getValue();
			item.BuildStartHour = zen("detailNamespaceBuildStartHour").getValue();
			item.BuildStartMinute = zen("detailNamespaceBuildStartMinute").getValue();
			item.SerialUpdates = zen("detailNamespaceSerialUpdates").getValue();
			zen("btnBuildAllRegisteredGroups").setProperty("disabled",(this.pageModified || item.Disabled));
			break;
		case 'Group':
			item.Disabled = zen('detailGroupDisabled').getValue();
			item.GroupName = zen('detailGroupName').getValue();
			item.BuildFrequency = zen('detailGroupBuildFrequency').getValue();
			item.BuildTimeUnit = zen('detailGroupBuildTimeUnit').getValue();
			item.BuildDayOfMonth = zen('detailGroupBuildDayOfMonth').getValue();
			item.BuildDayOfWeek = zen('detailGroupBuildDayOfWeek').getValue();
			item.SynchFrequency = zen('detailGroupSynchFrequency').getValue();
			item.SynchTimeUnit = zen('detailGroupSynchTimeUnit').getValue();
			var updatePlan = zen('detailGroupUpdatePlan').getValue();
			this.showUpdatePlan(this.currItemType,updatePlan,item.BuildTimeUnit);
			item.UpdatePlan = updatePlan;
			item.BuildAsynch = !zen('detailGroupBuildAsynch').getValue();
			zen('btnBuildOneRegisteredGroup').setProperty('disabled',(this.pageModified || item.Disabled));
			break;
		case 'Cube':
			item.Disabled = zen('detailCubeDisabled').getValue();
			item.BuildFrequency = zen('detailCubeBuildFrequency').getValue();
			item.BuildTimeUnit = zen('detailCubeBuildTimeUnit').getValue();
			item.BuildDayOfMonth = zen('detailCubeBuildDayOfMonth').getValue();
			item.BuildDayOfWeek = zen('detailCubeBuildDayOfWeek').getValue();
			item.SynchFrequency = zen('detailCubeSynchFrequency').getValue();
			item.SynchTimeUnit = zen('detailCubeSynchTimeUnit').getValue();
			item.PreSynchCode = zen('detailCubePreSynchCode').getValue();
			item.PostSynchCode = zen('detailCubePostSynchCode').getValue();
			item.PostBuildCode = zen('detailCubePostBuildCode').getValue();
			var updatePlan = zen('detailCubeUpdatePlan').getValue();
			this.showUpdatePlan(this.currItemType,updatePlan,item.BuildTimeUnit);
			item.UpdatePlan = updatePlan;
			item.BuildAsynch = !zen('detailCubeBuildAsynch').getValue();
			zen("btnRepairBuild").setProperty("disabled",(this.pageModified || item.Disabled));
			break;
		}			
		if (this.currViewMode != "table") {
			this.updateTable();
		} else {			
			this.save();		
			var table = zen('table');
			table.executeQuery(0);	
		}
	}
}

/// Enable/disable a row in the table.
ClientMethod enableItem(row, flag) [ Language = javascript ]
{
	var item = this._rowIndex[this.currItem];
	if (item) {
		item.disabled = !flag;
		this.updateTable();
		this.selectItem(this.currItemType,this.currItem,true);
	}
	return true;
}

/// Remove a row from the table.
ClientMethod removeItem(type, row, index) [ Language = javascript ]
{
	var item = this._rowIndex[row];
	if (item) {
		// DTB027 Prevent error when removing the selected item
		this.currItemType = 'Groups';
		this.currItem = 0;
		
		// DTB750 - Note that this item is being removed and signal the page's subsequent rowClick
		zenPage._removeItem = row;
	
		var map = this.getCubeObject();
		switch(type) {
		case 'Group':
			var ok = confirm($$$Text('Are you sure you want to unregister this group?')+'\n' + type + ": " + item.GroupName);
			if (!ok) {
				break;
			}
			map.Groups[index].IsRegistered = 0;
			this.updateMap(1);
			zen('namespaceDetails').setHidden(false);
			zen('groupDetails').setHidden(true);
			zen('cubeDetails').setHidden(true);
			zen('cubeSADetails').setHidden(true);
			break;
		}
	}
	return true;
}

/// Return true if it is possible to undo an action
ClientMethod canUndo() [ Language = javascript ]
{
	return this._undoBuffer && (this._undoIndex > 0);
}

/// Undo the most recent change.
ClientMethod undo() [ Language = javascript ]
{
	if (this.canUndo()) {
		var map = this.getCubeObject();
		this._undoIndex--;
		var oldcube = this._undoBuffer[this._undoIndex];
		var json = this.getComponentById('cube');
		json.setContentObject(oldcube);
		this.updateTable();
		
		if (map.sourceClass != oldcube.sourceClass) {
			this.tree = oldcube.sourceClass;
			zen('tree').refreshContents();
		}
		this.selectItem(this.currItemType,this.currItem,true);

		if (this._undoIndex == 0) {
			this.changeUndoState(true);
		}
	}
}

ClientMethod clearUndoBuffer() [ Language = javascript ]
{
	delete this._undoBuffer;
	delete this._undoIndex;

	this.changeUndoState(true);
}

/// Change Undo button state and View button state (opposite of Undo button)
ClientMethod changeUndoState(undostate) [ Language = javascript ]
{
	// change undo button state
	var undo = self.document.getElementById('cmdUndo');
	undo.disabled = undostate;
	undo.className = (undostate == true) ? 'hdrLinkDisabled' : 'hdrLink';
	this.setModified(!undostate);
}

/// Remember the current state in the undo buffer.
ClientMethod addUndoAction() [ Language = javascript ]
{
	if (null == this._undoBuffer) {
		this._undoBuffer = new Array();
		this._undoIndex = 0;
	}

	// remember copy of entire cube as state
	var map = this.getCubeObject();
	var oldcube = this.cloneObject(map);
	this._undoBuffer[this._undoIndex] = oldcube;
	this._undoIndex++;

	this.changeUndoState(false);
}

/// Create a clone of the given object.
ClientMethod cloneObject(obj, clone) [ Language = javascript ]
{
	var clone = clone ? clone : new Object();
	for (var i in obj) {
		if ((i == '_parent')||(i == '_index')) {
			// skip back pointers
		}
		else if (null == obj[i]) {
			clone[i] = null;
		}
		else if (typeof obj[i] === 'object') {
			clone[i] = (obj[i].constructor === Array) ? new Array(): new Object();
			this.cloneObject(obj[i],clone[i]);
		}
		else {
			clone[i] = obj[i];
		}
	}
	return clone;
}

/// User click on disclosure icon in table.
ClientMethod toggleDisclosure(key) [ Language = javascript ]
{
	var map = this.getCubeObject();
	if (map && map._contracted) {
		map._contracted[key] = !map._contracted[key];
		this.updateTable();
	}
}

/// Drop handler for model table. dragData.text is the GroupName; dragData.value is "group" or "cube" to indicate what is dragged here.
ClientMethod tableDropHandler(dragData) [ Language = javascript ]
{
	var map = this.getCubeObject();
	var tgtId = ZLM.getDragInnerDestination().id;
	var dragName = dragData.text;
	var dragValue = dragData.value;
	var group;
	var groupCube;
	if ('' == tgtId) {
		tgtId = ZLM.getDragInnerDestination().parentNode.id;
	}
	var row = -1;
	var tgtType;
	var newItem = null;
	var newType = '';

	if (''!=tgtId) {
		if (tgtId.indexOf('row_')!=-1) {
			
			tgtType = 'row';
			row = tgtId.split('_')[1];
		}
	}
	var item = this._rowIndex[row];
	if (item) {
		switch(item._type) {
		case 'Groups':
			// find the group from the object so we can have the cubes under the group
			var foundGroup = 0;
			for (var d = 0; d < map.Groups.length; d++) {
				var group = map.Groups[d];
				if (group.GroupName == dragValue) {
					group.IsRegistered = 1;
					this.addUndoAction();
					foundGroup = 1;
					break;
				 }
			}
			if (foundGroup) {
				this.updateMap(0);
			}
			break;
		case 'Group':
			var msg = this.msgMerge;
			msg = msg.replace("%1",dragName);
			msg = msg.replace("%2",item.GroupName);
			if (confirm(msg)) {
				var ok = this.mergeGroups(dragName,item.GroupName,map,item._index);
				if (ok) {
					this.updateMap(1);
					return true;
				}				
			} else {
				return false;
			}
		}
	} else {
		return false;	
	}
}

/// Thid method will save changes and reload tree. If reloadMap is set to 1 then reload content from server for table.
/// reloadMap is 1 for drag&drop merge and remove.
ClientMethod updateMap(reloadMap) [ Language = javascript ]
{
	try {
		// save changes
		this.save();
		// reload tree
		var tree = zen("tree");
		tree.reloadNode(0);
		// reload table
		if (reloadMap == 1) {
			this.reloadMap = 1;
			var json = this.getComponentById('cube');
			json.reloadContents();
		}
		this.updateTable();	
	 } catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in updateMap');
  	}
}

/// Save the map.
ClientMethod save() [ Language = javascript ]
{
	if (!this.canUserModify()) {
		return;
	}
	this.saveMap();
	
	// DTB751 - Natural group names might need to change
	var tree = zen('tree');
	if ('noGroups' != tree.getNodeValue(0)) {
		tree.reloadNode(0);
		if (!tree.isNodeExpanded(0)) {
			tree.toggleExpanded(0);
		}
	}
}

/// Object submit handler JSON provider.
/// This is called when the client submits the Cube definition.
Method SubmitMap(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, ByRef pResponseObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		// Save the group map definition
		Set tSC = ##class(%DeepSee.CubeManager.Utils).WriteToRegistry(.pSubmitObject, .pValidation)
		If $$$ISERR(tSC) Quit
		Set tSC = ##class(%DeepSee.CubeManager.Utils).ScheduleUpdaterTasks(pSubmitObject)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// Test if the user has write privilege.
ClientMethod canUserModify() [ Language = javascript ]
{
	if (!this.canWrite) {
		alert($$$Text('You are not authorized to modify or save map definitions.'));
		return false;
	}
	return true
}

/// Toggle display of settings (property tabs) box.
ClientMethod toggleSettings() [ Language = javascript ]
{
	this.settingsExpanded = !this.settingsExpanded;
	var span = self.document.getElementById('spanArrow');
	if (this.settingsExpanded) {
		span.innerHTML = '&#187;';
	}
	else {
		span.innerHTML = '&#171;';
	}
	this.adjustSizes();
}

/// Show a selected tool in a new window. pageName="Analyzer", "Architect", "MDXQuery", or "ModelBrowser".
ClientMethod toolMenu(pageName) [ Language = javascript ]
{
	// Open Analyzer focused on the currently selected item
	var cube = '';
	if (!zen('cubeDetails').hidden) {
		cube = zen('detailCubeName').getValue();
	} else if (!zen('cubeSADetails').hidden) {
		cube = zen('detailCubeSAName').getValue();
	}	
	var link = "_DeepSee.UI."+pageName+".zen";
	switch(pageName) {
		case "Analyzer":
			// Open analyzer focused on the currently selected item
			link += "?CUBE=";
			break;
		case "Architect":
			cube = (cube!='') ? cube + '.cube' : '';
			link += "?CUBE=";
			break;
		case "MDXQuery":
			// Open Query Tool focused on the currently selected item
			cube = (cube!='') ? cube + '.cube' : '';
			link += "?SUBJECTAREA=";
			break;
		case "ModelBrowser":
			// Open Model Browser focused on the the currently selected item
			link += "?CUBE=";
			break;			
	}
	link += encodeURIComponent(cube);
	var win = window.open(link,'DeepSee');
	try {
		win.focus();
	}
	catch(ex) {
	}
}

/// Toggle to show/hide Description textarea; set what's in text into textarea.
ClientMethod editDescription(what) [ Language = javascript ]
{
	var value = zen(what).getValue();
	var id = "area"+what;
	zen(id).setValue(value);
	zen(id).setHidden(!zen(id).getProperty("hidden"));
	zen(what).setHidden(!zen(what).getProperty("hidden"));
}

/// Set textarea description back into the text description field.
ClientMethod applyDescription(what) [ Language = javascript ]
{
	var id = "area"+what;
	var value = zen(id).getValue();
	zen(what).setValue(value);
	this.applyDetails();
}

/// method for when user mouse over a row in the table
ClientMethod rowMouseOver(element, div) [ Language = javascript ]
{
	var tooltip = this.hlpDropTooltip;
	div.style.color='#ED5A32';
	if (ZLM.dragActive == 1) {
		div.style.color='#ED5A32';
		div.style.cursor = 'pointer';
		div.title = tooltip.replace(/%1/,element);
	}
}

/// method for when mouse out
ClientMethod rowMouseOut(div) [ Language = javascript ]
{
	div.style.color = '';
	div.title = '';
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler');// ZHJ036: SMP Reskin
	if (!zenPage.activeRegistryExists) {
		zenPage.createNewRegistry();
	}
	else {
		var tree = zen('tree');
		if (('noGroups' != tree.getNodeValue(0)) && (!tree.isNodeExpanded(0))) {
			// DTB135 - only try to expand if there are unregistered cubes
			tree.toggleExpanded(0); 	
		}
	}
}

}
