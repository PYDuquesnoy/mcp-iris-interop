/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// DeepSee Architect page.
Class %DeepSee.UI.Architect Extends (%DeepSee.UI.standardPage, %CSP.Portal.SourceControl.Base) [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Architect";

/// If this page has multiple views, this is its initial display mode.
Parameter DEFAULTVIEWMODE = "cube";

Parameter DOCBOOKID = "D2MODEL_intro_architect";

Parameter RESOURCE = "%DeepSee_Architect,%DeepSee_ArchitectEdit";

/// Name of Cube (with extension).
Property cubeFullName As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Name of Cube being viewed.
Property cubeName As %ZEN.Datatype.string;

/// This will be true if the cube being loaded logged an error on the last compile.
Property compileErrorOnLoad As %ZEN.Datatype.boolean;

/// Name of the inherited cube, if it exists.
Property inheritsFrom As %ZEN.Datatype.string;

/// Class name of Cube being viewed.
/// This is determined from the cube name.
Property cubeClass As %ZEN.Datatype.string;

/// Description of Cube being viewed.
/// This is determined from the cube name.
Property cubeDescription As %ZEN.Datatype.string;

/// Domain of Cube being viewed.
/// This is handled seperately from json.
Property cubeDomain As %ZEN.Datatype.string;

/// DependsOn for cube class. If provided, this is used as the DependsOn value
/// of the generated cube. If not, the sourceClass for the cube is used.
/// This is handled seperately from json.
Property cubeDependsOn As %ZEN.Datatype.string;

/// Data source. This is a copy of the value in the cube model.
Property dataSource As %ZEN.Datatype.string;

/// ID (index number, 0-based) of current selected item.
Property currItem As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// Type of the current selected item.
Property currItemType As %ZEN.Datatype.string;

/// Local copy of cube model object.
Property %model As %DeepSee.Model.cube;

/// If true, user cannot modify the current cube definition.
Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, user can modify (non-read-only) cube definitions,
/// otherwise they can only view.
Property canWrite As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property lblExpression As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("(expression)")} ];

Property lblDataLevel As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Level (type=data)")} ];

Property lblTimeLevel As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Level (type=time)")} ];

Property lblAgeLevel As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Level (type=age)")} ];

Property hlpRemove As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Remove this item")} ];

Property hlpMoveUp As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Move this item up")} ];

Property hlpMoveDown As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Move this item down")} ];

Property hlpShowHide As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Hide or show the properties box")} ];

Property msgCubeInherited As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("This cube inherits items from the %1 cube")} ];

Property msgItemInherited As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("This item has been inherited from the %1 cube")} ];

Property msgItemOverride As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("This is an override of an inherited cube item")} ];

Property msgInvalid As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Please click [Open] to select a model definition.")} ];

Property msgOpenModel As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Please open a model definition first.")} ];

Property hlpDropTooltip As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Create new %1")} ];

/// If true, the settings area (property sheet) is visible.
Property settingsExpanded As %Boolean [ InitialExpression = 1, Internal ];

/// Whether to expand all elements under each type. When user clicks Collapse All then this is set to 0. At end of renderTable it is set to 2.
Property expandAll As %Integer [ InitialExpression = 1 ];

Property DocumaticPage As %String;

Property timeFunctions As %ZEN.Datatype.string;

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

#dataSource {
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
background: -moz-linear-gradient(top, #F8F8FF, #E0E0D0);
background: -webkit-gradient(linear, left top, left bottom, color-stop(0.0,#F8F8FF), color-stop(1.0,#E0E0D0));
	background: linear-gradient(top, #F8F8FF, #E0E0D0);
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

.modelRowCubeSelected span.selector,
.modelRowDimensionSelected span.selector,
.modelRowHierarchySelected span.selector,
.modelRowLevelSelected span.selector,
.modelRowMeasureSelected span.selector {
	visibility: visible;
}

.modelRowCube {
	color: rgb(67,67,67);
	font-size: 1.2em;
	font-weight: bold;
	background: #D0D0FF;
}
.modelRowCubeSelected {
	font-size: 1.2em;
	font-weight: bold;
	color: white;
	background: rgb(53,107,141);
}

.modelRowDimension {
	color: rgb(67,67,67);
	font-weight: bold;
	background: #F0F0FF;
}
.modelRowDimensionSelected {
	font-weight: bold;
	color: white;
	background: rgb(53,107,141);
}

.modelRowHierarchy {
	font-weight: bold;
	color: rgb(67,67,67);
}
.modelRowHierarchySelected {
	font-weight: bold;
	color: white;
	background: rgb(53,107,141);
}

.modelRowLevel {
	color: rgb(67,67,67);
}

.modelRowLevelSelected {
	color: white;
	background: rgb(53,107,141);
}

.modelRowMeasure {
	color: rgb(67,67,67);
}
.modelRowMeasureSelected {
	color: white;
	background: rgb(53,107,141);
}

.modelRowProperty {
	color: rgb(67,67,67);
}
.modelRowPropertySelected {
	color: white;
	background: rgb(53,107,141);
}
.coverPaneActive {
	position:absolute;
	left:0px;
	right:0px;
	top:0px;
	bottom:0px;
	opacity:.2;
	background:grey;
	display:block;
}
.coverPaneInactive {
	position:absolute;
	left:0px;
	right:0px;
	top:0px;
	display:block;
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

#dataSource {
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

.modelRowCubeSelected span.selector,
.modelRowDimensionSelected span.selector,
.modelRowHierarchySelected span.selector,
.modelRowLevelSelected span.selector,
.modelRowMeasureSelected span.selector {
	visibility: visible;
}

.modelRowCube {
	color: rgb(67,67,67);
	font-size: 1.2em;
	font-weight: bold;
	background: #D0D0FF;
}
.modelRowCubeSelected {
	font-size: 1.2em;
	font-weight: bold;
	color: white;
	background: rgb(53,107,141);
}

.modelRowDimension {
	color: rgb(67,67,67);
	font-weight: bold;
	background: #F0F0FF;
}
.modelRowDimensionSelected {
	font-weight: bold;
	color: white;
	background: rgb(53,107,141); 
	/* #FFEEAA; */
}

.modelRowHierarchy {
	font-weight: bold;
	color: rgb(67,67,67);
}
.modelRowHierarchySelected {
	font-weight: bold;
	color: white;
	background: rgb(53,107,141);
}

.modelRowLevel {
	color: rgb(67,67,67);
}
.modelRowLevelSelected {
	color: white;
	background: rgb(53,107,141);
}

.modelRowMeasure {
	color: rgb(67,67,67);
}
.modelRowMeasureSelected {
	color: white;
	background: rgb(53,107,141);
}

.modelRowProperty {
	color: rgb(67,67,67);
}
.modelRowPropertySelected {
	color: white;
	background: rgb(53,107,141);
}
.coverPaneActive {
	position:absolute;
	left:0px;
	right:0px;
	top:0px;
	bottom:0px;
	opacity:.2;
	background:grey;
	display:block;
}
.coverPaneInactive {
	position:absolute;
	left:0px;
	right:0px;
	top:0px;
	display:block;
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

/* WAL176 */
.hzResizeBar {
	position:absolute;
	top:0px;
	bottom:0px;
	width:10px;
	cursor:ew-resize;
	z-index:-1;
}
/* WAL176 */

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">

<!-- Get Cube Definition in JSON format -->
<jsonProvider id="cube"
	OnGetTargetObject="GetCubeDefinition"
	OnSubmitContent="SubmitCube"
/>
<!-- DTB156 - Inherited Cube Definition in JSON format. There is no submit for this cube! -->
<jsonProvider id="inheritedCube"
	OnGetTargetObject="GetInheritedCubeDefinition"
>
<parameter id="parmInheritsFrom" paramName="inheritsFrom" value="#(%page.inheritsFrom)#"/>
</jsonProvider>

<hgroup id="mainGroup" cellVAlign="top">
<vgroup id="editorPane">
<html id="modelTableHeader" OnDrawContent="DrawTableHeader"></html>
<hgroup cellVAlign="top">
<dynaTree id="dataSource" 
 imageContracted="images/arrow1R.gif"
 imageExpanded="images/arrow1D.gif"
 imageNode=""
	showLines="false" showFolders="false" dragEnabled="true" 
	OnGetTreeInfo="GetDataSourceInfo">
<parameter id="sourceP1" paramName="dataSource" value="#(%page.dataSource)#" />
</dynaTree>
<html id="modelTableBody" dropEnabled="true" ondrop="return zenPage.tableDropHandler(dragData);"></html>
</hgroup>
</vgroup>
<vgroup id="propertyPane">
<html id="propertyTitle"><span id="spanArrow" title="#(%page.hlpShowHide)#" onclick="zenPage.toggleSettings();" onmouseover="this.style.color='#FFEEAA';this.style.cursor='pointer'" onmouseout="this.style.color='';this.style.cursor='';">&#187;</span></html>
<tabGroup id="propertyTabs" showTabBar="true">
<tab id="tabDetails" caption="Details">
<vgroup id="msgCubeInherited" hidden="true">
<spacer height="15"/>
<label id="msgCubeInheritedText" value="#(%page.msgCubeInherited)#" controlClass="detailLabel" width="95%"/>
<spacer height="5"/>
</vgroup>
<vgroup id="msgItemInherited" hidden="true">
<spacer height="15"/>
<label id="msgItemInheritedText" value="#(%page.msgItemInherited)#" controlClass="detailLabel" width="95%"/>
<spacer height="5"/>
<hgroup id="btnOverride" hidden="true">
<spacer width="15"/>
<button caption="Customize" onclick="zenPage.overrideInheritedItem();"/>
</hgroup>
<spacer height="15"/>
</vgroup>
<vgroup id="msgOverride" hidden="true">
<spacer height="15"/>
<label value="#(%page.msgItemOverride)#" controlClass="detailLabel" width="95%"/>
<spacer height="5"/>
</vgroup>
<vgroup id="tabDetailContent">
<spacer height="5"/>
<vgroup id="defaultDetails" label="Select an item to view details"/>
<vgroup id="cubeDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label label="Cube" labelClass="detailLabel"/>
<checkbox id="detailCubeDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
<checkbox id="detailCubeFactNums" label="Selective Build Enabled" disabled="true"/>
</hgroup>
<text id="detailCubeName" label="Cube Name" size="44" onchange="zenPage.applyDetails();"/>
<text id="detailCubeDisplayName" label="Display name" size="44" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailCubeDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailCubeDescription" hidden="true" cols="32" rows="4" onchange="zenPage.applyDescription('detailCubeDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailCubeDescription');"/>
</hgroup>
<hgroup>
<text id="detailCubeCaption" label="Caption" size="19" onchange="zenPage.applyDetails();"/>
<text id="detailCubeDomain" label="Domain" size="19" onchange="zenPage.applyDomain(zenThis.getValue());"/>
<!--<text id="detailCubeBucketSize" label="Bucket size" size="10" onchange="zenPage.applyDetails();"/>-->
</hgroup>
<text id="detailCubeSource" label="Source class" size="44" disabled="true"/>
<hgroup cellVAlign="bottom" cellStyle="padding-right:4px;">
<text id="detailCubeNullReplacement" label="Null replacement string" dropEnabled="true" size="19" onchange="zenPage.applyDetails();"/>
</hgroup>

<select id="detailCubeDefaultListing" label="Default listing" value="" originalValue="" onchange="zenPage.applyDetails();"/>

<hgroup hidden="true">
<select id="detailCubeDefaultMeasure" label="Default measure" value="" originalValue="" onchange="zenPage.applyDetails();"/>
<text id="detailCubeDefaultMember" label="Default member" dropEnabled="true" size="19" onchange="zenPage.applyDetails();"/>
</hgroup>
<hgroup cellVAlign="bottom">
<text id="detailCubeOwner" label="Owner" size="19" onchange="zenPage.applyDetails();"/>
<text id="detailCubeResource" label="Resource" size="19" onchange="zenPage.applyDetails();"/>
<image id="btndetailCubeResource" src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('CubeResource');"/>
</hgroup>
<hgroup>
<text id="detailCubeCountMeasureName" label="Count measure name" dropEnabled="true" size="19" onchange="zenPage.applyDetails();"/>
<text id="detailCubeCountMeasureCaption" label="Count measure caption" dropEnabled="true" size="19" onchange="zenPage.applyDetails();"/>
</hgroup>
<hgroup cellVAlign="bottom">
<text id="detailCubeBuildOrder" label="Initial build order" size="19" onchange="zenPage.applyDetails();"/>
<text id="detailCubeBuildRestriction" label="Build restriction" size="19" onchange="zenPage.applyDetails();"/>
<image id="btndetailBuildRestriction" src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('BuildRestriction');"/>
</hgroup>
<!--<text id="detailCubeDomain" label="Localization domain" size="19" onchange="zenPage.applyDetails();"/>-->
<text id="detailCubeClass" label="Class name" size="44" disabled="true" value="#(%page.cubeClass)#"/>
<text id="detailCubeDependsOn" label="Depends On" hint="Option list of classes that this cube depends on" size="44" onchange="zenPage.applyDependsOn(zenThis.getValue());"/>
<checkbox id="detailCubeSqlRestrict" label="Allow SQL Restrict" onchange="zenPage.applyDetails();"/>
<textarea label="Additional Description" id="areadetailAdditionalDescriptionCube" hidden="false" cols="32" rows="4" onchange="zenPage.applyDetails();"/>
</vgroup>
<!-- End of Cube Details -->

<vgroup id="measureDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label label="Measure" labelClass="detailLabel"/>
<checkbox id="detailMeasureDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
<checkbox id="detailMeasureHidden" label="Hidden" onchange="zenPage.applyDetails();"/>
<checkbox id="detailMeasureSearchable" label="Searchable" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailMeasureName" label="Name" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<text id="detailMeasureDisplayName" label="Display name" size="44" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailMeasureDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailMeasureDescription" hidden="true" cols="32" rows="4" onchange="zenPage.applyDescription('detailMeasureDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailMeasureDescription');"/>
</hgroup>
<label label="Source Values" labelClass="detailLabel" />
<hgroup label="Property" cellVAlign="top">
<radioButton id="detailMeasureSourcePropertyRB" name="detailMeasureSourceRB" optionValue="property" onclick="zenPage.toggleSource('Measure','Source');"/>
<text id="detailMeasureSource" size="40" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('MeasureSource');"/>
</hgroup>
<hgroup label="Expression" cellVAlign="top">
<radioButton id="detailMeasureSourceExpressionRB" name="detailMeasureSourceRB" optionValue="expression" onclick="zenPage.toggleSource('Measure','Expression');"/>
<text id="detailMeasureExpression" size="40" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('MeasureExpression');"/>
</hgroup>
<form enclosingStyle="background:lightgray;">
<select id="detailMeasureAgg" label="Aggregate" valueList="COUNT,SUM,AVG,MIN,MAX" required="true" showEmpty="false" onchange="zenPage.applyDetails();"/>
<hgroup cellVAlign="top" cellStyle="padding-right:4px;">
<select id="detailMeasureType" label="Type" hint="Leave blank for default" valueList="" required="false" showEmpty="true" onchange="zenPage.changeType(zenThis);zenPage.applyDetails();"/>
<text id="detailMeasureScale" label="Precision" size="20" onchange="zenPage.applyDetails();" hidden="true"/>
<select id="detailMeasureiKnowSource" label="iKnow Source" valueList="string,stream,file,domain" displayList="string,stream,file,domain" showEmpty="false" onchange="zenPage.changeType(zenThis);" hidden="true"/>
<image id="detailMeasureiKnowDictionaries" label="Dictionaries" src="deepsee/dictionary_24.png" title="Click to maintain optional iKnow dictionaries for use in matching."
onclick="zenPage.editItem('iKnowDictionaries');"/>
<hidden id="detailMeasureiKnowDictionaryValue"/>
</hgroup>
<hgroup cellVAlign="bottom" cellStyle="padding-right:4px;">
<text id="detailMeasureFormatString" label="Format string" size="42" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<image id="btndetailMeasureFormatString" src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('FormatString');"/>
</hgroup>
</form>
<text id="detailMeasureFactName" label="Field name in fact table" size="20" onchange="zenPage.applyDetails();"/>
<form label="Measure-Specific Listings" labelClass="detailLabel" enclosingStyle="background:lightgray;">
<select id="measureBasedListingComparison" label="Operator" valueList=",=,&lt;&gt;,&lt;,&gt;,&lt;=,&gt;=,MIN,MAX" required="true" showEmpty="false" onchange="zenPage.applyDetails();"/>
<textarea label="Value" id="areadetailMeasureBasedListing" hidden="false" cols="10" rows="1" onchange="zenPage.applyDetails();"/>
</form>
<textarea label="Additional Description" id="areadetailAdditionalDescriptionMeasure" hidden="false" cols="32" rows="4" onchange="zenPage.applyDetails();"/>
</vgroup>
<!-- End of Measure Details -->
<label id="lblComputed" hidden="true" label="To modify a computed dimension, edit the cube definition class with Studio."/>
<vgroup id="dimensionDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label label="Dimension" labelClass="detailLabel"/>
<checkbox id="detailDimensionDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
<checkbox id="detailDimensionHidden" label="Hidden" hidden="true" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailDimensionName" label="Name" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<text id="detailDimensionDisplayName" label="Display name" size="44" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailDimensionDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailDimensionDescription" hidden="true" cols="32" rows="4" onchange="zenPage.applyDescription('detailDimensionDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailDimensionDescription');"/>
</hgroup>
<vgroup id="idDimension">
<hgroup cellStyle="padding-right:2px;">
<select id="detailDimensionType" label="Dimension type" valueList="data,time,age,iKnow" required="true" showEmpty="false" onchange="zenPage.changeType(zenThis);zenPage.applyDetails();"/>
<select id="detailDimensionCalendar" label="Calendar"  valueList="gregorian,partial,hijriTabular,hijriObserved" displayList="gregorian,partial,hijri (tabular),hijri (observed)" required="true" showEmpty="false" onchange="zenPage.applyDetails();" value="gregorian"/>
<select id="detailDimensioniKnowType" label="iKnow type" valueList="entity,dictionary" displayList="entity,dictionary" required="true" showEmpty="false" onchange="zenPage.applyDetails();"/>
<select id="detailDimensioniKnowMeasure" label="iKnow measure" valueList="" title="iKnow measure is required for iKnow type" required="true" showEmpty="false" onchange="zenPage.applyDetails();"/>
</hgroup>
<vgroup id="idDetailDimensionSource">
<label label="Source Values" labelClass="detailLabel" />
<hgroup cellVAlign="top">
<radioButton id="detailDimensionSourcePropertyRB" name="detailDimensionSourceRB" optionValue="property" onclick="zenPage.toggleSource('Dimension','Source');"/>
<label label="Property" />
</hgroup>
<hgroup cellVAlign="top">
<text id="detailDimensionSource" size="44" dropEnabled="true" ondrop="zenThis.setValue(dragData.value)" onchange="zenPage.applyDetails();"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('DimensionSource');"/>
</hgroup>
<hgroup cellVAlign="top">
<radioButton id="detailDimensionSourceExpressionRB" name="detailDimensionSourceRB" optionValue="expression" onclick="zenPage.toggleSource('Dimension','Expression');"/>
<label label="Expression" />
</hgroup>
<hgroup cellVAlign="top">
<text id="detailDimensionExpression" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('DimensionExpression');"/>
</hgroup>
</vgroup>
<vgroup cellStyle="padding:4px;" label="All Level" labelClass="detailLabel">
<checkbox id="detailDimensionHasAll" caption="Enable the All level for this dimension" captionClass="zenLabel" value="1" onchange="zenPage.changeType(zenThis);zenPage.applyDetails();"/>
<text id="detailDimensionAllCaption" label="Caption for All member" size="44" onchange="zenPage.applyDetails();"/>
<text id="detailDimensionAllDisplayName" label="Display name for All member" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
</vgroup>
</vgroup>
<vgroup id="idDimensionSharesFrom" hidden="true">
<label id="detailDimensionSharesFromCube" label="Shares from Cube"/>
</vgroup>
<textarea label="Additional Description" id="areadetailAdditionalDescriptionDimension" hidden="false" cols="32" rows="4" onchange="zenPage.applyDetails();"/>
</vgroup>
<!-- End of Dimension Details -->

<vgroup id="hierarchyDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label label="Hierarchy" labelClass="detailLabel"/>
<checkbox id="detailHierarchyDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailHierarchyName" label="Name" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<text id="detailHierarchyDisplayName" label="Display name" size="20" onchange="zenPage.applyDetails();"/>
<textarea id="detailHierarchyDescription" label="Description" cols="32" rows="4" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailAdditionalDescriptionHierarchy" label="Additional Description" hidden="false" cols="32" rows="4" onchange="zenPage.applyDetails();"/>
</vgroup>
<!-- End of Hierarchy Details -->

<vgroup id="levelDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label id="lblLevel" controlClass="detailLabel" value="Data Level"/>
<checkbox id="detailLevelDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailLevelName" label="Name" size="44"  dropEnabled="true" onchange="zenPage.applyDetails();"/>
<text id="detailLevelDisplayName" label="Display name" size="44" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailLevelDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailLevelDescription" hidden="true" cols="32" rows="2" onchange="zenPage.applyDescription('detailLevelDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailLevelDescription');"/>
</hgroup>
<label label="Source Values" labelClass="detailLabel" />
<vgroup id="idDetailLevelSource">
<hgroup cellVAlign="top">
<radioButton id="detailLevelSourcePropertyRB" name="detailLevelSourceRB" optionValue="property" onclick="zenPage.toggleSource('Level','Source');"/>
<label label="Property" />
</hgroup>
<hgroup cellVAlign="top">
<text id="detailLevelSource" size="44" dropEnabled="true" ondrop="zenThis.setValue(dragData.value)" onchange="zenPage.applyDetails();"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('LevelSource');"/>
</hgroup>
<hgroup cellVAlign="top">
<radioButton id="detailLevelSourceExpressionRB" name="detailLevelSourceRB" optionValue="expression" onclick="zenPage.toggleSource('Level','Expression');"/>
<label label="Expression" />
</hgroup>
<hgroup cellVAlign="top">
<text id="detailLevelExpression" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('LevelExpression');"/>
</hgroup>
</vgroup>
<form id="frmHowtotransform" label="How to Transform the Source Values" labelClass="detailLabel" enclosingStyle="background:lightgray;">
<text id="detailLevelNullReplacement" label="Null replacement string" dropEnabled="true" size="20" onchange="zenPage.applyDetails();"/>

<hgroup cellVAlign="bottom">
<text id="detailLevelRangeExpression" label="Range expression" size="44" onchange="zenPage.applyDetails();"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('RangeExpression');"/>
</hgroup>
<checkbox id="detailLevelUseDisplayValue" caption="Use value in DISPLAYLIST" captionClass="zenLabel" onchange="zenPage.applyDetails();"/>

</form>
<hgroup id="idLevelTimeFunction" cellStyle="padding-right:4px;">
<select id="detailLevelTimeFunction" label="Extract value with function"
valueList="MinuteNumber,HourNumber,DayMonthYear,DayNumber,WeekNumber,MonthNumber,WeekYear,MonthYear,QuarterNumber,QuarterYear,Year,Decade" onchange="zenPage.changeType(zenThis);zenPage.applyDetails();"/>
</hgroup>
<hgroup id="idLevelTimeFormat" cellStyle="padding-right:4px;">
<text id="detailLevelTimeFormat" label="Time Format" onchange="zenPage.applyDetails();"/>
</hgroup>
<select id="detailLevelTimeFunctionAge" label="Extract value with function" hidden="true"
valueList="Days,Months,Years" onchange="zenPage.changeType(zenThis);zenPage.applyDetails();"/>
<hgroup id="idDataFunction" cellStyle="padding-right:4px;" valign="top">
<select id="detailLevelList" label="Source value list type" displayList="Not a list,$List structure,Comma delimited,Other delimited" valueList="false,true,comma,other" showEmpty="false" onchange="zenPage.changeType(zenThis);"/>
<text id="detailLevelListDelimiter" label="List delimiter" size="2" onblur="zenPage.applyDetails();"/>
</hgroup>
<select id="detailLevelSort" label="Sort option" valueList="asc,desc,asc numeric,desc numeric" showEmpty="true" onchange="zenPage.applyDetails();"/>
<text id="detailLevelFactName" label="Field name in fact table" size="20" onchange="zenPage.applyDetails();"/>
<hgroup id="idLevelDependsOn" cellVAlign="top">
<textarea id="areadetailLevelDependsOn" label="Depends on" cols="34" rows="6" onchange="zenPage.applyDetails();"/>
<vgroup>
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('LevelDependsOn');"/>
</vgroup>
</hgroup>
<textarea id="areadetailAdditionalDescriptionLevel" label="Additional Description" hidden="false" cols="32" rows="4" onchange="zenPage.applyDetails();"/>
</vgroup>
<!-- End of Level Details -->

<vgroup id="propertyDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label label="Property" labelClass="detailLabel"/>
<checkbox id="detailPropertyDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
<checkbox id="detailPropertyHidden" label="Hidden" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailPropertyName" label="Name" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<text id="detailPropertyDisplayName" label="Display name" size="44" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailPropertyDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailPropertyDescription" hidden="true" cols="32" rows="4" onchange="zenPage.applyDescription('detailPropertyDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailPropertyDescription');"/>
</hgroup>
<label label="Source Values" labelClass="detailLabel" />
<hgroup label="Property" cellVAlign="top">
<radioButton id="detailPropertySourcePropertyRB" name="detailPropertySourceRB" optionValue="property" onclick="zenPage.toggleSource('Property','Source');"/>
<text id="detailPropertySource" size="44" dropEnabled="true" ondrop="zenThis.setValue(dragData.value)" onchange="zenPage.applyDetails();"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('PropertySource');"/>
</hgroup>
<vgroup cellStyle="padding-left:20px;">
<hgroup>
<checkbox id="detailPropertyUseDisplayValue" onchange="zenPage.applyDetails();"/>
<label label="Use value in DISPLAYLIST"/>
</hgroup>
<hgroup>
<checkbox id="detailPropertyIsReference" onchange="zenPage.applyDetails();"/>
<label label="Get value at runtime"/>
</hgroup>
</vgroup>
<hgroup label="Expression" cellVAlign="top">
<radioButton id="detailPropertySourceExpressionRB" name="detailPropertySourceRB" optionValue="expression" onclick="zenPage.toggleSource('Property','Expression');"/>
<text id="detailPropertyExpression" size="44" onchange="zenPage.applyDetails();"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('PropertyExpression');"/>
</hgroup>
<label label="Effect of Properties on Level Members" labelClass="detailLabel"/>
<vgroup>
<hgroup>
<checkbox id="detailPropertyIsName" onchange="zenPage.applyDetails();"/>
<label label="Use as member names"/>
</hgroup>
<hgroup labelPosition="left" >
<select id="detailPropertySort" label="Sort members by property value" valueList="asc,desc,asc numeric,desc numeric" showEmpty="true" onchange="zenPage.applyDetails();"/>
</hgroup>
</vgroup>
<hgroup cellStyle="padding-right:4px;">
</hgroup>
<text id="detailPropertyFactName" label="Field name in level table" size="20" onchange="zenPage.applyDetails();"/>
<textarea label="Additional Description" id="areadetailAdditionalDescriptionProperty" hidden="false" cols="32" rows="4" onchange="zenPage.applyDetails();"/>
</vgroup>
<!-- End of Property Details -->

<vgroup id="listingDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label label="Listing" labelClass="detailLabel"/>
<checkbox id="detailListingDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailListingName" label="Name" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<text id="detailListingDisplayName" label="Display name" size="44" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailListingDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailListingDescription" hidden="true" cols="32" rows="4" onchange="zenPage.applyDescription('detailListingDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailListingDescription');"/>
</hgroup>
<hgroup>
<select id="detailListingType" label="Listing type" valueList="table,map" displayList="Table,Map" required="true" showEmpty="false" onchange="zenPage.applyDetails();"/>
<spacer width="10%"/>
<select id="detailListingSelectMode" label="SQL Select Mode" valueList="0,1,2" displayList="Logical,ODBC,Display" showEmpty="false" onchange="zenPage.applyDetails();"/>
</hgroup>
<hgroup cellVAlign="bottom">
<text id="detailListingResource" label="Resource" size="44" onchange="zenPage.applyDetails();"/>
<image id="btndetailListingResource" src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('ListingResource');"/>
</hgroup>
<hgroup id="idListingFieldList" cellVAlign="top">
<textarea id="areadetailListingFieldList" label="Field list" cols="32" rows="6" onchange="zenPage.applyDetails();"/>
<vgroup>
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('ListingFieldList');"/>
</vgroup>
</hgroup>
<hgroup id="idListingOrderBy" cellVAlign="top">
<textarea id="areadetailListingOrderBy" label="Order by" cols="32" rows="2" onchange="zenPage.applyDetails();"/>
<vgroup>
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('ListingOrderBy');"/>
</vgroup>
</hgroup>
<combobox id="detailListingSourceClass" label="Data connector" editable="true" valueList="" onchange="zenPage.applyDetails();" unrestricted="true"/>
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<checkbox id="detailListingUseSQL" label="Custom SQL query" onchange="zenPage.changeUseSQL();"/>
</hgroup>
<hgroup id="idListingSQL" cellVAlign="top" hidden="true">
<textarea id="areadetailListingSQL" label="SQL Query" cols="32" rows="6" onchange="zenPage.applyDetails();"/>
<vgroup>
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('ListingSQL');"/>
</vgroup>
</hgroup>
<textarea label="Additional Description" id="areadetailAdditionalDescriptionListing" hidden="false" cols="32" rows="4" onchange="zenPage.applyDetails();"/>
</vgroup>
<!-- End of Listing Details -->
<!-- JSL4434 add listingField -->
<vgroup id="listingFieldDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label label="Listing Field" labelClass="detailLabel"/>
<checkbox id="detailListingFieldDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailListingFieldName" label="Name" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<text id="detailListingFieldDisplayName" label="Display name" size="44" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailListingFieldDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailListingFieldDescription" hidden="true" cols="32" rows="4" onchange="zenPage.applyDescription('detailListingFieldDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailListingFieldDescription');"/>
</hgroup>
<hgroup id="areadetailListingFieldExpression" cellVAlign="top">
<text id="detailListingFieldExpression" label="Field Expression" size="44" ondrop="zenPage.dropDetailListingFieldExpression(dragData)" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<vgroup>
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('ListingField');"/>
</vgroup>
</hgroup>
<hgroup cellVAlign="bottom">
<text id="detailListingFieldResource" label="Resource" size="44" onchange="zenPage.applyDetails();"/>
<image id="btndetailListingFieldResource" src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('ListingFieldResource');"/>
</hgroup>

</vgroup>
<!-- End of ListingField Details -->


<vgroup id="calculatedMemberDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label label="Calculated Member" labelClass="detailLabel"/>
<checkbox id="detailCalMemberDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
<checkbox id="detailCalMemberHidden" label="Hidden" hidden="true" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailCalMemberName" label="Name" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<text id="detailCalMemberDisplayName" label="Display name" size="44" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailCalMemberDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailCalMemberDescription" hidden="true" cols="32" rows="4" onchange="zenPage.applyDescription('detailCalMemberDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailCalMemberDescription');"/>
</hgroup>
<selector id="detailCalMemberDimension" label="Dimension" size="41" onchange="zenPage.applyDetails();"/>
<hgroup cellVAlign="bottom" cellStyle="padding-right:4px;">
<text id="detailCalMemberFormatString" label="Format string" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('CalMemberFormatString');"/>
</hgroup>
<!--<text id="detailCalMemberUnits" label="Units" size="20" onchange="zenPage.applyDetails();" hidden="true"/>-->
<hgroup cellVAlign="top" cellStyle="padding-right:4px;">
<textarea id="areadetailCalMemberValueExpression" label="Value expression" cols="32" rows="6" onchange="zenPage.applyDetails();"/>
<vgroup>
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('CalMemberValueExpression');"/>
</vgroup>
</hgroup>
<hgroup cellVAlign="top" cellStyle="padding-right:4px;">
<textarea label="Listing Filter" id="areadetailCalcMemberListingFilter" hidden="false" cols="32" rows="4" onchange="zenPage.applyDetails();"/>
<vgroup id="areadetailCalcMemberListingFilterMagnifyingGlass">
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('listingFilterExpression');"/>
</vgroup>
</hgroup>
<textarea label="Additional Description" id="areadetailAdditionalDescriptionCalculatedMember" hidden="false" cols="32" rows="4" onchange="zenPage.applyDetails();"/>
</vgroup>
<!-- End of calculatedMembers Details -->

<vgroup id="namedSetDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label label="Named Sets" labelClass="detailLabel"/>
<checkbox id="detailNamedSetDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailNamedSetName" label="Name" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<text id="detailNamedSetDisplayName" label="Display name" size="44" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailNamedSetDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailNamedSetDescription" hidden="true" cols="32" rows="4" onchange="zenPage.applyDescription('detailNamedSetDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailNamedSetDescription');"/>
</hgroup>
<hgroup cellVAlign="top" cellStyle="padding-right:4px;">
<textarea id="areadetailNamedSetSetExpression" label="Set expression" cols="32" rows="6" onchange="zenPage.applyDetails();"/>
<vgroup>
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('SetExpression');"/>
</vgroup>
</hgroup>
<textarea label="Additional Description" id="areadetailAdditionalDescriptionNamedSet" hidden="false" cols="32" rows="4" onchange="zenPage.applyDetails();"/>
</vgroup>
<!-- End of namedSets Details -->

<vgroup id="relationshipDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label label="Relationship" labelClass="detailLabel"/>
<checkbox id="detailRelationshipDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailRelationshipName" label="Name" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<text id="detailRelationshipDisplayName" label="Display name" size="44" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailRelationshipDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailRelationshipDescription" hidden="true" cols="32" rows="4" onchange="zenPage.applyDescription('detailRelationshipDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailRelationshipDescription');"/>
</hgroup>
<vgroup id="idDetailRelationshipSource">
<label label="Source Values" labelClass="detailLabel" />
<hgroup cellVAlign="top">
<radioButton id="detailRelationshipSourcePropertyRB" name="detailRelationshipSourceRB" optionValue="property" onclick="zenPage.toggleSource('Relationship','Source');"/>
<label label="Property" />
</hgroup>
<hgroup cellVAlign="top">
<text id="detailRelationshipSource" size="44" dropEnabled="true" ondrop="zenThis.setValue(dragData.value)" onchange="zenPage.applyDetails();"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('RelationshipSource');"/>
</hgroup>
<hgroup cellVAlign="top">
<radioButton id="detailRelationshipSourceExpressionRB" name="detailRelationshipSourceRB" optionValue="expression" onclick="zenPage.toggleSource('Relationship','Expression');"/>
<label label="Expression" />
</hgroup>
<hgroup cellVAlign="top">
<text id="detailRelationshipExpression" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('RelationshipExpression');"/>
</hgroup>
</vgroup>
<form label="How to Transform the Source Values" labelClass="detailLabel" enclosingStyle="background:lightgray;">
<text id="detailRelationshipNullReplacement" label="Null replacement string" dropEnabled="true" size="20" onchange="zenPage.applyDetails();"/>
</form>
<select id="detailRelationshipCardinality" label="Cardinality" valueList="one,many" displayList="One,Many" showEmpty="false" onchange="zenPage.applyDetails();"/>
<text id="detailRelationshipInverse" label="Inverse" size="44" onchange="zenPage.applyDetails();"/>
<select id="detailRelationshipRelatedCube" label="Related cube" showEmpty="false" onchange="zenPage.applyDetails();"/>
<text id="detailRelationshipFactName" label="Field name in fact table" size="20" onchange="zenPage.applyDetails();"/>
<textarea label="Additional Description" id="areadetailAdditionalDescriptionRelationship" hidden="false" cols="32" rows="4" onchange="zenPage.applyDetails();"/>
</vgroup>
<!-- End of relationship Details -->

<vgroup id="expressionDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label label="Expression" labelClass="detailLabel"/>
<checkbox id="detailExpressionDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailExpressionName" label="Name" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailExpressionDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailExpressionDescription" hidden="true" cols="32" rows="4" onchange="zenPage.applyDescription('detailExpressionDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailExpressionDescription');"/>
</hgroup>
<vgroup id="idDetailExpressionSource">
<label label="Source Expression" labelClass="detailLabel" />
<hgroup cellVAlign="top">
<textarea id="areadetailExpressionExpression" cols="32" rows="6" onchange="zenPage.applyDetails();"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('ExpressionExpression');"/>
</hgroup>
</vgroup>
<textarea label="Additional Description" id="areadetailAdditionalDescriptionExpression" hidden="false" cols="32" rows="4" onchange="zenPage.applyDetails();"/>
</vgroup>
<!-- End of expression Details -->

</vgroup>
</tab>
<tab caption="Tools" id="tabTools" labelPosition="left" title="Various tools for working with Analytics data models">
<vgroup cellStyle="padding-left:3px;">
<label label="Various tools for working with Analytics data models"/>

<hgroup cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/comparison_chart_48.gif"/>
<vgroup>
<button caption="Analyzer" controlClass="commandButton" title="Use the Analyzer to view this cube." onclick="zenPage.toolAnalyzer();"/>
<label label="Use the Analyzer to view this cube."/>
</vgroup>
</hgroup>

<hgroup cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/sql_query_48.gif"/>
<vgroup>
<button caption="Query Tool" controlClass="commandButton" title="Use the Query Tool to run queries against this cube." onclick="zenPage.toolQuery();"/>
<label label="Use the Query Tool to run queries against this cube."/>
</vgroup>
</hgroup>

</vgroup>
</tab>
</tabGroup>
</vgroup>
</hgroup>
<timer id="commandBtnTimer" ontimeout="zenPage.commandBtnTimeout();" timeout="500"/>
</pane>
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If (..cubeName="") {
		Quit ..%OnGetPageName()
	}
	Quit ..cubeName
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Architect","%DeepSee")
}

/// Get the product name for the page.
Method %OnGetProductName() As %String
{
	Quit "Analytics"
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Architect")

	//Set pViewIcons(1) = $LB("cubes",$$$Text("Show related cubes"),"portal/view_cubes.png")
	Set pViewIcons(2) = $LB("cube",$$$Text("Show cube definition"),"portal/view_cube.png")
	//Set pViewIcons(3) = $LB("table",$$$Text("Show fact table definition"),"portal/view_facts.png")

	// commands
	// $LB(id,caption,help,onclick)
	// DTB390 - Hide buttons that the user does not have privilege to use
	Set:..canEdit pCommands($I(pCommands)) = $LB("cmdNew",$$$Text("New"),$$$Text("Create a new model"),"zenPage.newCube();")
	Set pCommands($I(pCommands)) = $LB("cmdOpen",$$$Text("Open"),$$$Text("Open a model"),"zenPage.changeSubjectArea();")
	Set:..canEdit pCommands($I(pCommands)) = $LB("cmdSave",$$$Text("Save"),$$$Text("Save this model"),"zenPage.save();")
	Set pCommands($I(pCommands)) = $LB("cmdCompile",$$$Text("Compile"),$$$Text("Compile this model"),"zenPage.compile();")
	Set pCommands($I(pCommands)) = $LB("cmdBuild",$$$Text("Build"),$$$Text("Rebuild data for this model"),"zenPage.buildCube();")
	Set pCommands($I(pCommands)) = $LB("cmdDoc",$$$Text("Documentation"),$$$Text("Open Documatic for this model"),"zenPage.doDocument();")

	Quit $$$OK
}

/// Draw the contents of the Table Header (the region between the diagram and the table).
Method DrawTableHeader(pSeed As %String) As %Status
{
	//Set msgChange = $$$Text("Change")
	//Set hlpChange = $$$Text("Change the data source for this model")
	Set msgNew = $$$Text("New")
	Set hlpNew = $$$Text("Add a new cube")
	Set msgAdd = $$$Text("Add Element")
	Set hlpAdd = $$$Text("Add an element to this model")
	Set msgUndo = $$$Text("Undo")
	Set hlpUndo = $$$Text("Undo the last change to this model")
	Set msgExpand = $$$Text("Expand All")
	Set hlpExpand = $$$Text("Expand all elements")
	Set msgCollapse = $$$Text("Collapse All")
	Set hlpCollapse = $$$Text("Collapse all elements")
	Set msgReorder = $$$Text("Reorder")
	Set hlpReorder = $$$Text("Reorder Dimensions or Measures")
	Set msgView = $$$Text("View")
	Set hlpView = $$$Text("View cube details")

	&html<<div style="position:relative;">>
	&html<<div style="position:absolute;top:16px;left:20px;font-weight:bold;color:#404040;">#($$$Text("Source Class"))#</div>>
	///&nbsp;<a class="hdrLink" href="#" title="#(hlpChange)#" onclick="zenPage.changeDataSource();return false;">#(msgChange)#</a>
	///</div>> 
	&html<<div style="position:absolute;top:16px;left:200px;font-weight:bold;color:#404040;">#($$$Text("Model Elements"))#
	&nbsp;<a class="hdrLink" href="#" title="#(hlpAdd)#" onclick="zenPage.addItem();return false;">#(msgAdd)#</a>
	&nbsp;&nbsp;<a id="cmdUndo" class="hdrLinkDisabled" disabled="true" href="#" title="#(hlpUndo)#" onclick="zenPage.undo();return false;">#(msgUndo)#</a>
	&nbsp;&nbsp;<a class="hdrLink" href="#" title="#(hlpExpand)#" onclick="zenPage.toggleExpand(1);return false;">#(msgExpand)#</a>
	&nbsp;&nbsp;<a class="hdrLink" href="#" title="#(hlpCollapse)#" onclick="zenPage.toggleExpand(0);return false;">#(msgCollapse)#</a>
	&nbsp;&nbsp;<a class="hdrLink" href="#" title="#(hlpReorder)#" onclick="zenPage.reorder();return false;">#(msgReorder)#</a>
	</div>>

	Quit $$$OK
}

/// Provide contents of the data source tree.
ClassMethod GetDataSourceInfo(pRoot As %String, Output pTree, ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Set tDataSource = $G(pParms("dataSource"))
	
	If (tDataSource="") && (%page.cubeName'="") &&
		$D(^DeepSee.Overrides($$$UPPER(%page.cubeName),"SOURCECLASS"),tDataSource) {
		// DP-404426 - If the source class for this cube is defined solely via an override,
		// use it to allow the UI to function with interaction with the source class.
		Set %page.dataSource = tDataSource
	}
	
	If (tDataSource '= "") {
		Set tSC = ##class(%DeepSee.Utils).%GetDataSourceTree(tDataSource,.pTree,,,,pRoot)
		If $$$ISERR(tSC) Quit tSC
	}
	Quit tSC
}

/// Draw additional stuff in the ribbon bar
Method OnDrawRibbon() As %Status
{
	If (%page.cubeName'="")&&(%page.canWrite) Quit ..%DrawSourceControlCommands()		// DTB646 - Check privileges for source control button display
	Quit 1
}

/// Launch the cube finder dialog.
ClientMethod changeSubjectArea() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.cls?MODE=models','SubjectArea','status,scrollbars,resizable=yes,width=800,height=600');
}

/// This function takes care of certain fields when their values are changed.
ClientMethod changeType(idfield) [ Language = javascript ]
{
	var idname = idfield.getProperty("id");
	switch(idname) {
	case 'detailMeasureType':
		var measureType = zen("detailMeasureType").getValue();
		zen("detailMeasureScale").setHidden(measureType!="number");
		zen("detailMeasureiKnowSource").setHidden(measureType!="iKnow");
		zen("detailMeasureiKnowDictionaries").setHidden(measureType!="iKnow");
		zen('detailMeasureFormatString').setDisabled(measureType=="iKnow");
		zen('detailMeasureAgg').setDisabled(measureType=="iKnow");		
		if (measureType=="iKnow"&&zen("detailMeasureiKnowSource").getValue()=="") {
			zen("detailMeasureiKnowSource").setValue('string');	
		}
		var currentAggFunc = zen('detailMeasureAgg').getValue();
		if ((new Array('iKnow','text','string','boolean')).indexOf(measureType)>=0) {
			zen('detailMeasureAgg').setValue('COUNT');
		} else if (((measureType=='date') || (measureType=='age')) && (currentAggFunc!='MAX') && (currentAggFunc!='MIN') && (currentAggFunc!='AVG')) {
			zen('detailMeasureAgg').setValue('AVG');
		}
		break;
	case 'detailDimensionType':
		var dimType = zen("detailDimensionType").getValue();
		if (dimType == 'data' || dimType == 'iKnow') { 
			zen('idDetailDimensionSource').setHidden(true);
		}
		else {
			zen('idDetailDimensionSource').setHidden(false);
		}
		zen('detailDimensionCalendar').setHidden('time'!=dimType);		// DTB181 - Only expose for time dimensions
		zen('detailDimensioniKnowType').setHidden(dimType!="iKnow");
		zen('detailDimensioniKnowMeasure').setHidden(dimType!="iKnow");
		if (dimType == "iKnow") {
			var iKnowMeasures = this.getiKnowMeasures();
			zen('detailDimensioniKnowMeasure').setProperty("valueList",iKnowMeasures);
			var currentIKnowMeasure = zen('detailDimensioniKnowMeasure').getValue();
			zen('detailDimensioniKnowMeasure').setValue((currentIKnowMeasure!='') ? currentIKnowMeasure : iKnowMeasures.split(',')[0]);
			var currentIKnowType = zen('detailDimensioniKnowType').getValue();
			zen('detailDimensioniKnowType').setValue((currentIKnowType!='') ? currentIKnowType : 'entity');
		}
		break;
	case 'detailDimensionHasAll':
		var hasAll = zen("detailDimensionHasAll").getValue();
		zen("detailDimensionAllCaption").setDisabled(hasAll!=1);
		zen("detailDimensionAllDisplayName").setDisabled(hasAll!=1);
		break;
	case 'detailLevelList':
		// listType value = false,true,comma,other
		var listType = zen("detailLevelList").getValue();
		var delimiter = zen("detailLevelListDelimiter");
		if (listType == "comma") delimiter.setValue(",");
		if ((listType != "comma")&&(listType != "other")) delimiter.setValue("");
		delimiter.setDisabled(listType!='other');
		// PFS041 - If other is selected, focus on delimiter input, else apply changes
		if (listType=='other') {
			zenPage.getComponentById('detailLevelListDelimiter').focus();
		} else {
			zenPage.applyDetails();
		}
		break;
	case 'detailLevelTimeFunction':
		zen("frmHowtotransform").setHidden(zen("detailLevelTimeFunction").getValue()!="");
		break;
	case 'detailLevelTimeFunctionAge':
		zen("frmHowtotransform").setHidden(zen("detailLevelTimeFunctionAge").getValue()!="");
		break;
	case 'detailMeasureiKnowSource':
		if (idfield.getValue() == "domain") {
			var ok = confirm($$$Text("You are changing iKnow source to 'domain' which is an advanced iKnow setting. Are you sure you want to do this?"));
			if (ok) {
				zen("detailMeasureiKnowDictionaries").setHidden(true);
			} else {
				// reset value back to 'string'
				zen("detailMeasureiKnowSource").setValue('string');
			}
		} else {
			zen("detailMeasureiKnowDictionaries").setHidden(false);
		}
		zenPage.applyDetails();
		break;
	}
}

/// User checked/unchecked the Use SQL field
ClientMethod changeUseSQL() [ Language = javascript ]
{
	var usesql = zen("detailListingUseSQL").getValue();
	zen("idListingSQL").setHidden(!usesql);
	zen("idListingFieldList").setHidden(usesql);
	zen("idListingOrderBy").setHidden(usesql);
	zen("detailListingSourceClass").setHidden(usesql);
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
			
			//YSD2397 - temp out until default Measure/Listing issue is resolved
			var cube  = zenPage.getCubeObject();
			if (cube) {
				this.selectItem('cube',0);
				//this.applyDetails();		// DTB918
			}
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
		var sourceDiv = zen('dataSource').getEnclosingDiv();
		var proptitleDiv = zen('propertyTitle').getEnclosingDiv();
		var proptabsDiv = zen('propertyTabs').getEnclosingDiv();

		propDiv.style.display = 'block';

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();

		var propWidth = 40;
		if (this.settingsExpanded) {
			propWidth = (winWidth<900) ? 300 : 400;		// DTB731 - Provide a little more space for the Details pane
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
		
		// + WAL177
		var bar = document.getElementById('resize');
		if (bar) {
			bar.style.position = "absolute";
			bar.style.left = parseInt(sourceDiv.style.width)-5+'px';
			bar.style.top= '0px';
			bar.style.width = '10px';
			bar.style.height = parseInt(sourceDiv.style.height)+'px';
			bar.style.cursor = "ew-resize";
			bar.style.zIndex = "100";
			this.handle = [];
			var o = {};
			o.div = bar;
			o.col = sourceDiv;
			o.pos = 0;
		    ZLM.registerDragItem(o.div,this);
			this.handle[0] = o;
		}
		// - WAL177
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Callback to initiate window resize event
ClientMethod startDrag(engine, wrapper) [ Language = javascript ]
{
	var idx = 0;
	while (this.handle[idx] && this.handle[idx].div!=wrapper.node) idx++;

	this.barInMotion = this.handle[idx];
	this.startingX = this.barInMotion.div.offsetLeft;
	this.startingW = this.barInMotion.col.offsetWidth;

	if (idx==0) this.minX = 10;
	else this.minX = this.handle[idx-1].div.offsetLeft+10;
	if (idx==this.handle.length-1) this.maxX = this.handle[idx].div.parentNode.offsetWidth-20;
	else this.maxX = this.handle[idx+1].div.offsetLeft-10;
}

/// Callback to wrap up window resize event 
ClientMethod endDrag(engine, wrapper) [ Language = javascript ]
{
	zenPage.adjustSizes();
}

/// Callback to limit horizontal resizing
ClientMethod constrainDragX(engine, wrapper, intendedX) [ Language = javascript ]
{
	var newX = intendedX;
	if (newX<this.minX) newX = this.minX;
	if (newX>this.maxX) newX = this.maxX;
	
	var newDelta = newX - this.startingX;
	this.barInMotion.col.style.width = (this.startingW+newDelta)+"px";
	zenPage.adjustSizes();
	return(newX);
}

/// Callback to limit vertical resizing
ClientMethod constrainDragY(engine, wrapper, intendedY) [ Language = javascript ]
{
	return(0);
}

/// Update the contents of the model table.
ClientMethod updateTable() [ Language = javascript ]
{
	this.renderTable();
	if ((''!==this.currItem)&&(''!==this.currItemType)) {
		// DTB190 - Re-select the item
		this.selectItem(this.currItemType,this.currItem,true);
	}
}

/// Update the contents of the model table.
ClientMethod renderTable() [ Language = javascript ]
{
	var table = zen('modelTableBody');
	var html = new Array();
	var cube = this.getCubeObject();
	var inheritedCube = this.getInheritedCubeObject();		// DTB156
	var source,type;

	// maps row number in the table back to an item in the model
	this._rowIndex = new Array();
	// DTB156 - maintains a record of which displayed items are inherited
	this._inheritedIndex = new Array();
	
	// n.b., we add a _parent and _index decoration to each element in the tree as we render
	if (null == cube) {
		html[html.length] = '<div class="modelError">' + this.msgInvalid + '</div>';
	}
	else {
		// we also add an array to track if disclosures are open or closed
		if (null == cube._contracted) {
			cube._contracted = new Object();
		}
		
		// WAL177
		html[html.length] = '<div id="resize" class="hzResizeBar" onmousedown="ZLM.drag(this,event);">';
		html[html.length] = '</div>';

		// create table displaying cube model.
		html[html.length] = '<table class="modelTable" border="0" cellspacing="0">';
		var indentDim = '<img height="1px" width="16px" src="images/spacer.gif"/>';
		var indentMea = '<img height="1px" width="32px" src="images/spacer.gif"/>';
		var indentHier = '<img height="1px" width="48px" src="images/spacer.gif"/>';
		var indentLevel = '<img height="1px" width="62px" src="images/spacer.gif"/>';
		var indentProperty = '<img height="1px" width="78px" src="images/spacer.gif"/>';
		var disc = '';
		var remove = '';
		var enabler = '';
		var style = '';
		var measureList = '';
		var listingList = '';
		// cube
		source = cube.sourceClass;

		type = 'cube';
		this._rowIndex[this._rowIndex.length] = cube;
		html[html.length] = '<tr class="modelRowCube" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'cube\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + zenEscapeXML(cube.name) + '</td>';
		html[html.length] = '<td>' + $$$Text("Element Type") + '&nbsp;</td>';
		html[html.length] = '<td>' + $$$Text("Details") + '&nbsp;</td>';
		html[html.length] = '<td>' + enabler + '&nbsp;</td>';
		html[html.length] = '<td>' + remove + '&nbsp;</td>';
		html[html.length] = '</tr>';

		// measures
		type = '';
		this._rowIndex[this._rowIndex.length] = 'measures';
		var closed = this.isClosed(cube,'measures');
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure(\'measures\');"/>';

		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'measures\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'measure\',this);" onmouseout="zenPage.rowMouseOut(this);">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + disc + $$$Text('Measures') + '</td>';
		html[html.length] = '<td>' + type + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;' + '</td>';
		html[html.length] = '<td>' + enabler + '&nbsp;</td>';
		html[html.length] = '<td>' + remove + '&nbsp;</td>';
		html[html.length] = '</tr>';
		if (!closed) {
			this.renderCubeItems(cube,'measure',html);
			if (inheritedCube) {
				// DTB156 - Add inherited measures
				this.renderCubeItems(inheritedCube,'measure',html);
			}
		}
		
		// dimensions
		this._rowIndex[this._rowIndex.length] = 'dimensions';
		closed = this.isClosed(cube,'dimensions');
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure(\'dimensions\');" onmouseover="zenPage.rowMouseOver(\'dimension\',this);" onmouseout="zenPage.rowMouseOut(this);"/>';

		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'dimensions\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'dimension\',this);" onmouseout="zenPage.rowMouseOut(this);">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td >' + disc + $$$Text('Dimensions') + '</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '</tr>';
		if (!closed) {
			this.renderCubeItems(cube,'dimension',html);
			if (inheritedCube) {
				// DTB156 - Add inherited dimensions
				this.renderCubeItems(inheritedCube,'dimension',html);
			}
	  	}
	  	
	  	// listings
		this._rowIndex[this._rowIndex.length] = 'listings';
		var closed = this.isClosed(cube,'listings');
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure(\'listings\');"/>';
		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'listings\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'listing\',this);" onmouseout="zenPage.rowMouseOut(this);">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + disc + $$$Text('Listings') + '</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '</tr>';	
		if (!closed) {
			this.renderCubeItems(cube,'listing',html);
			if (inheritedCube) {
				// DTB156 - Add inherited listings
				this.renderCubeItems(inheritedCube,'listing',html);
			}
		}
		
	  	// listing fields JSL4434
		this._rowIndex[this._rowIndex.length] = 'listingFields';		// DTB156 - plural reference to listingFields at top level
		var closed = this.isClosed(cube,'listingFields');
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure(\'listingFields\');"/>';
		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'listingFields\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'listingField\',this);" onmouseout="zenPage.rowMouseOut(this);">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + disc + $$$Text('Listing Fields') + '</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '</tr>';	
		if (!closed) {
			this.renderCubeItems(cube,'listingField',html);
			if (inheritedCube) {
				// DTB156 - Add inherited listingFields
				this.renderCubeItems(inheritedCube,'listingField',html);
			}
		}
		
	  	// calculated members
		this._rowIndex[this._rowIndex.length] = 'calculatedMembers';
		closed = this.isClosed(cube,'calculatedMembers');
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure(\'calculatedMembers\');"/>';

		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'calculatedMembers\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + disc + $$$Text('Calculated Members') + '</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '</tr>';	
		if (!closed) {
			this.renderCubeItems(cube,'calculatedMember',html);
			if (inheritedCube) {
				// DTB156 - Add inherited calcMembers
				this.renderCubeItems(inheritedCube,'calculatedMember',html);
			}
		}	
		
	  	// namedSets
		this._rowIndex[this._rowIndex.length] = 'namedSets';
		closed = this.isClosed(cube,'namedSets');
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure(\'namedSets\');"/>';

		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'namedSets\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + disc + $$$Text('Named Sets') + '</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '</tr>';	
		if (!closed) {
			this.renderCubeItems(cube,'namedSet',html);
			if (inheritedCube) {
				// DTB156 - Add inherited named sets
				this.renderCubeItems(inheritedCube,'namedSet',html);
			}
		}

	  	// relationships
		this._rowIndex[this._rowIndex.length] = 'relationships';
		closed = this.isClosed(cube,'relationships');
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure(\'relationships\');"/>';

		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'relationships\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + disc + $$$Text('Relationships') + '</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '</tr>';
		if (!closed) {
			this.renderCubeItems(cube,'relationship',html);
			if (inheritedCube) {
				// DTB156 - Add inherited relationships
				this.renderCubeItems(inheritedCube,'relationship',html);
			}
		}
		
		// +DTB390
		// expressions
		this._rowIndex[this._rowIndex.length] = 'expressions';
		closed = this.isClosed(cube,'expressions');
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure(\'expressions\');"/>';

		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'expressions\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + disc + $$$Text('Expressions') + '</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '</tr>';
		if (!closed) {
			this.renderCubeItems(cube,'expression',html);
			if (inheritedCube) {
				this.renderCubeItems(inheritedCube,'expression',html);
			}
		}		
		// -DTB390
		
		html[html.length] = '</table>'; 
	}
	table.setContent(html.join(''));
	this.expandAll = 2;
}

/// Render the actual items in a given group type in the table. This does not draw the 
/// title bars.
ClientMethod renderCubeItems(cube, itemGroupType, html) [ Language = javascript ]
{
	// Method added by DTB156
	var table = zen('modelTableBody');
	var source,type;
	var inherited = (zenPage.inheritsFrom.toUpperCase()==cube.name.toUpperCase());		// DTB172 - Cube names are not case-sensitive

	if (true) {
		// we also add an array to track if disclosures are open or closed
		if (null == cube._contracted) {
			cube._contracted = new Object();
		}

		var indentDim = '<img height="1px" width="16px" src="images/spacer.gif"/>';
		var indentMea = '<img height="1px" width="32px" src="images/spacer.gif"/>';
		var indentHier = '<img height="1px" width="48px" src="images/spacer.gif"/>';
		var indentLevel = '<img height="1px" width="62px" src="images/spacer.gif"/>';
		var indentProperty = '<img height="1px" width="78px" src="images/spacer.gif"/>';
		var disc = '';
		var remove = '';
		var enabler = '';
		var style = '';
		var measureList = '';
		var listingList = '';
		
		// DTB156 - Coordinated styling for inherited items 
		var inheritedBackground = ''; 
		var inheritedFontStyle = 'font-style:italic';
		
		if (inherited) {
			style = 'style="background:'+inheritedBackground+';'+inheritedFontStyle+';"';		// DTB156
		}

		switch (itemGroupType) {
			// measures
			case 'measure':
				for (var m = 0; m < cube.measures.length; m++) {
					var msr = cube.measures[m];
					if ((inherited)&&(this.findRowForItemName(msr.name,itemGroupType)>-1)) {
						// DTB156 - This has been overriden in the local definition
						continue;
					}
					msr._parent = cube;
					msr._index = m;
					this._inheritedIndex[this._rowIndex.length] = inherited;
					this._rowIndex[this._rowIndex.length] = msr;
					
					var type = msr.type + " " + $$$Text("measure");
					var details = (msr.type == 'string' || msr.type == 'text' || msr.type == 'iKnow') ? '' : msr.aggregate;
					var source = (msr.sourceExpression!='') ? this.lblExpression : msr.sourceProperty;
					
					// DTB156 - adjust behavior based on local or inherited definition
					if (inherited) {
						remove = '';
						style = (msr.disabled) ?
										'style="background:#C0C0C0;'+inheritedFontStyle+';"' :
										'style="background:'+inheritedBackground+';'+inheritedFontStyle+';"';
					}
					else {
						remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'measure\','+(this._rowIndex.length-1)+','+m+');" />';
						style = (msr.disabled) ? 'style="background:#C0C0C0;"' : '';
					}
					
					html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'measure\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
					html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
					html[html.length] = '<td>' + indentMea + zenEscapeXML(msr.name) + '</td>';
					html[html.length] = '<td>' + type + '&nbsp;</td>';
					html[html.length] = '<td>' + details + ' ' + source + '&nbsp;</td>';
					html[html.length] = '<td>' + remove + '&nbsp;</td>';	
					html[html.length] = '<td>' + '&nbsp;</td>';
					html[html.length] = '</tr>';
					
					if (msr.disabled == 0) {
						if (measureList != "") measureList = measureList + ",";
						measureList = measureList + msr.name;
					}
				}
				if (!inherited) {		// DTB156
					zen("detailCubeDefaultMeasure").setProperty("valueList",measureList);
				}
			break;

			// dimensions
			case 'dimension':
				for (var d = 0; d < cube.dimensions.length; d++) {
					var dim = cube.dimensions[d];
					if ((inherited)&&(this.findRowForItemName(dim.name,itemGroupType)>-1)) {
						// DTB156 - This has been overriden in the local definition
						continue;
					}
					
					if ((('time'==dim.type)||('age'==dim.type))&&(''==dim.calendar)) {
						// DTB190 - Assign the gregorian calendar to the serialized time dimension
						dim.calendar = 'gregorian';
					}
					
					dim._parent = cube;
					dim._index = d;
					this._inheritedIndex[this._rowIndex.length] = inherited;
					this._rowIndex[this._rowIndex.length] = dim;
					
					var source = dim.sourceProperty;
					var type = dim.type + " " + $$$Text("dimension");
					if (dim.sharesFrom != "") {
						type = $$$Text("Shared dimension");
						source = dim.sharesFrom;
					}
					var isTime = ('time' == dim.type);
					var closed = cube._contracted['dim'+d];
					disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure(\'dim'+d+'\');"/>';

					// DTB156 - adjust behavior based on local or inherited definition
					if (inherited) {
						remove = '';
						style = (dim.disabled) ?
										'style="background:#C0C0C0;'+inheritedFontStyle+';"' :
										'style="background:'+inheritedBackground+';'+inheritedFontStyle+';"';
					}
					else {
						remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'dimension\','+(this._rowIndex.length-1)+','+d+');" />';
						style = (dim.disabled) ? 'style="background:#C0C0C0;"' : '';
					}
					
					html[html.length] = '<tr class="modelRowDimension" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'dimension\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'hierarchy\',this);" onmouseout="zenPage.rowMouseOut(this);">';
					html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
					html[html.length] = '<td>' + indentDim + disc + zenEscapeXML(dim.name) + '</td>';
					html[html.length] = '<td>' + type + '&nbsp;</td>';
					html[html.length] = '<td>' + source + '&nbsp;</td>';
					html[html.length] = '<td>' + remove + '&nbsp;</td>';
					html[html.length] = '<td>' + '&nbsp;</td>';
					html[html.length] = '</tr>';

					if (!closed) {
						for (var h = 0; h < dim.hierarchies.length; h++) {
							var hier = dim.hierarchies[h];
							hier._parent = dim;
							hier._index = h;
							hier._dimtype = dim.type;
							hier._calendar = (('time'==dim.type)||('age'==dim.type)) ? dim.calendar : ''; 		// DTB180
							this._inheritedIndex[this._rowIndex.length] = inherited;
							this._rowIndex[this._rowIndex.length] = hier;
							type = 'hierarchy';
							
							// DTB156 - adjust behavior based on local or inherited definition
							if (inherited) {
								remove = '';
								style = (dim.disabled||hier.disabled) ? 
											'style="background:#C0C0C0;'+inheritedFontStyle+';"' :
											'style="background:'+inheritedBackground+';'+inheritedFontStyle+';"';
							}
							else {
								remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'hierarchy\','+(this._rowIndex.length-1)+','+d+','+h+');" />';
								style = (dim.disabled||hier.disabled) ? 'style="background:#C0C0C0;"' : '';
							}
							
							html[html.length] = '<tr class="modelRowHierarchy" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'hierarchy\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'level\',this);" onmouseout="zenPage.rowMouseOut(this);">';
							html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
							html[html.length] = '<td>' + indentHier + zenEscapeXML(hier.name) + '</td>';
							html[html.length] = '<td>' + type + '&nbsp;</td>';
							html[html.length] = '<td>' + '&nbsp;' + '</td>';
							html[html.length] = '<td>' + remove + '&nbsp;</td>';
							html[html.length] = '<td>' + '&nbsp;</td>';
							html[html.length] = '</tr>';
							var hierLen = hier.levels.length;
							var levelnum = 0
							for (var l = 0; l < hierLen; l++) {
								var level = hier.levels[l];
								level._dimtype = dim.type;
								level._calendar = (('time'==dim.type)||('age'==dim.type)) ? dim.calendar : '';		// DTB180
								level._parent = hier;
								level._index = l;
								levelnum++;
								this._inheritedIndex[this._rowIndex.length] = inherited;
								this._rowIndex[this._rowIndex.length] = level;
								type = 'level';
								source = (level.sourceExpression!='') ? this.lblExpression : level.sourceProperty;
								if (isTime) {
									source = level.timeFunction;
								}
								
								// DTB156 - adjust behavior based on local or inherited definition
								if (inherited) {
									remove = '';
									moveup = '';
									movedn = '';
									style = (dim.disabled||hier.disabled||level.disabled) ? 
											'style="background:#C0C0C0;'+inheritedFontStyle+';"' :
											'style="background:'+inheritedBackground+';'+inheritedFontStyle+';"';
								}
								else {
									remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'level\','+(this._rowIndex.length-1)+','+d+','+h+','+l+');" />';
									if (hierLen > 1) {
										moveup = '<img width="16px" src="' + 'deepsee/up_16.png' + '" title="' + this.hlpMoveUp + '" onclick="zenPage.moveItemUp(\'level\','+(this._rowIndex.length-1)+','+d+','+h+','+l+');" />';
										movedn = '<img width="16px" src="' + 'deepsee/down_16.png' + '" title="' + this.hlpMoveDown + '" onclick="zenPage.moveItemDown(\'level\','+(this._rowIndex.length-1)+','+d+','+h+','+l+');" />';
									} else {
										moveup = '';
										movedn = '';
									}
									style = (dim.disabled||hier.disabled||level.disabled) ? 'style="background:#C0C0C0;"' : '';
								}
								
								html[html.length] = '<tr class="modelRowLevel" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'level\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'property\',this);" onmouseout="zenPage.rowMouseOut(this);">';
								html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
								html[html.length] = '<td>' + indentLevel + zenEscapeXML(level.name) + '</td>';
								html[html.length] = '<td>' + type + '&nbsp;'+levelnum + '&nbsp;</td>';
								html[html.length] = '<td>' + source + '&nbsp;</td>';
								html[html.length] = '<td>' + remove + '&nbsp;</td>';
								html[html.length] = '<td>' + moveup + '&nbsp;' + movedn + '</td>';
								html[html.length] = '</tr>';

								var propLen = level.properties.length;
								for (var p = 0; p < propLen; p++) {
									var prop = level.properties[p];
									prop._parent = level;
									prop._index = p;
									this._inheritedIndex[this._rowIndex.length] = inherited;		// DTB156
									this._rowIndex[this._rowIndex.length] = prop;
									type = 'property';
									source = (prop.sourceExpression!='') ? this.lblExpression : prop.sourceProperty;
									
									if (inherited) {
										// DTB156 - adjust behavior based on local or inherited definition
										remove = '';
										moveup = '';
										movedn = '';
										style = (dim.disabled||hier.disabled||level.disabled||prop.disabled) ? 
											'style="background:#C0C0C0;'+inheritedFontStyle+';"' :
											'style="background:'+inheritedBackground+';'+inheritedFontStyle+';"';
									}
									else {
										remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'property\','+(this._rowIndex.length-1)+','+d+','+h+','+l+','+p+');" />';
										if (propLen > 1) {
											moveup = '<img width="16px" src="' + 'deepsee/up_16.png' + '" title="' + this.hlpMoveUp + '" onclick="zenPage.moveItemUp(\'property\','+(this._rowIndex.length-1)+','+d+','+h+','+l+','+p+');" />';
											movedn = '<img width="16px" src="' + 'deepsee/down_16.png' + '" title="' + this.hlpMoveDown + '" onclick="zenPage.moveItemDown(\'property\','+(this._rowIndex.length-1)+','+d+','+h+','+l+','+p+');" />';
										} else {
											moveup = '';
											movedn = '';
										}
										style = (dim.disabled||hier.disabled||level.disabled||prop.disabled) ? 'style="background:#C0C0C0;"' : '';
									}

									html[html.length] = '<tr class="modelRowProperty" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'property\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
									html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
									html[html.length] = '<td>' + indentProperty + zenEscapeXML(prop.name) + '</td>';
									html[html.length] = '<td>' + type + '&nbsp;</td>';
									html[html.length] = '<td>' + source + '&nbsp;</td>';
									html[html.length] = '<td>' + remove + '&nbsp;</td>';
									html[html.length] = '<td>' + moveup + '&nbsp;' + movedn + '</td>';
									html[html.length] = '</tr>';
								}
							}
						}
					}
				}
				break;
		  	
		  	// listings
			case 'listing':
				if (inherited) {
					// DTB190 - Inherited is rendered second. Pick up the previously accumulated listings
					listingList = zen('detailCubeDefaultListing').getProperty('valueList');
				}

				for (var d = 0; d < cube.listings.length; d++) {
					var list = cube.listings[d];
					if ((inherited)&&(this.findRowForItemName(list.name,itemGroupType)>-1)) {
						// DTB156 - This has been overriden in the local definition
						continue;
					}
					list._parent = cube;
					list._index = d;
					this._inheritedIndex[this._rowIndex.length] = inherited;		// DTB156
					this._rowIndex[this._rowIndex.length] = list;
					type = 'listing';
					var isdefault = '';
					if (list.name == cube.defaultListing) isdefault = "&nbsp;("+$$$Text("default")+")";
					
					if (inherited) {
						// DTB156 - adjust behavior based on local or inherited definition
						remove = '';
						style = (list.disabled) ?
										'style="background:#C0C0C0;'+inheritedFontStyle+';"' :
										'style="background:'+inheritedBackground+';'+inheritedFontStyle+';"';
					}
					else {
						remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'listing\','+(this._rowIndex.length-1)+','+d+');" />';
						style = (list.disabled) ? 'style="background:#C0C0C0;"' : '';
					}
					
					// show sql if it's defined. ow show fieldList.
					var fieldList = (list.sql != "") ? list.sql : list.fieldList;
					if (fieldList.length > 40) fieldList = fieldList.substring(0,40) + "...";
					html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'listing\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
					html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
					html[html.length] = '<td>' + indentMea + zenEscapeXML(list.name) + '</td>';
					html[html.length] = '<td>' + type + isdefault + '&nbsp;</td>';
					html[html.length] = '<td>' + zenEscapeXML(fieldList) + '&nbsp;</td>';
					html[html.length] = '<td>' + remove + '&nbsp;</td>';
					html[html.length] = '<td>' + '&nbsp;</td>';
					html[html.length] = '</tr>';
					if (list.disabled == 0) {
						if (listingList != "") listingList = listingList + ",";
						listingList = listingList + list.name;
					}
				}
				zen('detailCubeDefaultListing').setProperty('valueList',listingList);
				break;
			
		  	// listing fields JSL4434
			case 'listingField':
				for (var d = 0; d < cube.listingFields.length; d++) {
					var field = cube.listingFields[d];
					//console.log('name=' + field.name + ' itemGroupType=' + itemGroupType + ' row return: ' + this.findRowForItemName(field.name,itemGroupType));
					if ((inherited)&&(this.findRowForItemName(field.name,itemGroupType)>-1)) {
						// DTB156 - This has been overriden in the local definition
						continue;
					}
					field._parent = cube;
					field._index = d;
					this._inheritedIndex[this._rowIndex.length] = inherited;		// DTB156
					this._rowIndex[this._rowIndex.length] = field;
					type = 'listingField';
					var isdefault = '';
					
					if (inherited) {
						// DTB156 - adjust behavior based on local or inherited definition
						remove = '';
						style = (field.disabled) ?
										'style="background:#C0C0C0;'+inheritedFontStyle+';"' :
										'style="background:'+inheritedBackground+';'+inheritedFontStyle+';"';
					}
					else {
						remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'listingField\','+(this._rowIndex.length-1)+','+d+');" />';
						style = (field.disabled) ? 'style="background:#C0C0C0;"' : '';
					}
					
					var fieldExpression = field.fieldExpression;
					if (fieldExpression.length > 40) fieldExpression = fieldExpression.substring(0,40) + "...";
			
					html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'listingField\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
					html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
					html[html.length] = '<td>' + indentMea + zenEscapeXML(field.name) + '</td>';
					html[html.length] = '<td>' + type + isdefault + '&nbsp;</td>';
					html[html.length] = '<td>' + zenEscapeXML(fieldExpression) + '&nbsp;</td>';
					html[html.length] = '<td>' + remove + '&nbsp;</td>';
					html[html.length] = '<td>' + '&nbsp;</td>';
					html[html.length] = '</tr>';
				}
				break;
			
		  	// calculated members
			case 'calculatedMember':
				for (var d = 0; d < cube.calculatedMembers.length; d++) {
					var member = cube.calculatedMembers[d];
					if ((inherited)&&(this.findRowForItemName(member.name,itemGroupType)>-1)) {
						// DTB156 - This has been overriden in the local definition
						continue;
					}
					member._parent = cube;
					member._index = d;
					this._inheritedIndex[this._rowIndex.length] = inherited;		// DTB156
					this._rowIndex[this._rowIndex.length] = member;
					type = 'calculatedMember';
					
					if (inherited) {
						// DTB156 - adjust behavior based on local or inherited definition
						remove = '';
						style = (member.disabled) ?
										'style="background:#C0C0C0;'+inheritedFontStyle+';"' :
										'style="background:'+inheritedBackground+';'+inheritedFontStyle+';"';
					}
					else {
						remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'calculatedMember\','+(this._rowIndex.length-1)+','+d+');" />';
						style = (member.disabled) ? 'style="background:#C0C0C0;"' : '';
					}
					
					html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'calculatedMember\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
					html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
					html[html.length] = '<td>' + indentMea + zenEscapeXML(member.name) + '</td>';
					html[html.length] = '<td>' + type + '&nbsp;</td>';
					html[html.length] = '<td>' + member.dimension + '&nbsp;</td>';
					html[html.length] = '<td>' + remove + '&nbsp;</td>';
					html[html.length] = '<td>' + '&nbsp;</td>';
					html[html.length] = '</tr>';
				}
				break;
				
		  	// namedSets	
			case 'namedSet':
				for (var d = 0; d < cube.namedSets.length; d++) {
					var member = cube.namedSets[d];
					if ((inherited)&&(this.findRowForItemName(member.name,itemGroupType)>-1)) {
						// DTB156 - This has been overriden in the local definition
						continue;
					}
					member._parent = cube;
					member._index = d;
					this._inheritedIndex[this._rowIndex.length] = inherited;
					this._rowIndex[this._rowIndex.length] = member;
					type = 'namedSet';
					var setExpression = member.setExpression;
					if (setExpression.length > 40) setExpression = setExpression.substring(0,40) + "...";
					
					if (inherited) {
						// DTB156 - adjust behavior based on local or inherited definition
						remove = '';
						style = (member.disabled) ?
										'style="background:#C0C0C0;'+inheritedFontStyle+';"' :
										'style="background:'+inheritedBackground+';'+inheritedFontStyle+';"';
					}
					else {
						remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'namedSet\','+(this._rowIndex.length-1)+','+d+');" />';
						style = (member.disabled) ? 'style="background:#C0C0C0;"' : '';
					}
					
					html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'namedSet\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
					html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
					html[html.length] = '<td>' + indentMea + zenEscapeXML(member.name) + '</td>';
					html[html.length] = '<td>' + type + '&nbsp;</td>';
					html[html.length] = '<td>' + zenEscapeXML(setExpression) + '&nbsp;</td>';
					html[html.length] = '<td>' + remove + '&nbsp;</td>';
					html[html.length] = '<td>' + '&nbsp;</td>';
					html[html.length] = '</tr>';
				}
				break;

		  	// relationships
			case 'relationship':
				for (var d = 0; d < cube.relationships.length; d++) {
					var member = cube.relationships[d];
					if ((inherited)&&(this.findRowForItemName(member.name,itemGroupType)>-1)) {
						// DTB156 - This has been overriden in the local definition
						continue;
					}
					member._parent = cube;
					member._index = d;
					this._inheritedIndex[this._rowIndex.length] = inherited;		// DTB156
					this._rowIndex[this._rowIndex.length] = member;
					type = 'relationship';
					var sourceExpression = member.sourceExpression;
					if (sourceExpression.length > 40) sourceExpression = sourceExpression.substring(0,40) + "...";				
					
					if (inherited) {
						// DTB156 - adjust behavior based on local or inherited definition
						remove = '';
						style = (member.disabled) ?
										'style="background:#C0C0C0;'+inheritedFontStyle+';"' :
										'style="background:'+inheritedBackground+';'+inheritedFontStyle+';"';
					}
					else {
						remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'relationship\','+(this._rowIndex.length-1)+','+d+');" />';
						style = (member.disabled) ? 'style="background:#C0C0C0;"' : '';
					}
					
					html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'relationship\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
					html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
					html[html.length] = '<td>' + indentMea + zenEscapeXML(member.name) + '</td>';
					html[html.length] = '<td>' + type + '&nbsp;</td>';
					html[html.length] = '<td>' + zenEscapeXML(sourceExpression) + '&nbsp;</td>';
					html[html.length] = '<td>' + remove + '&nbsp;</td>';
					html[html.length] = '<td>' + '&nbsp;</td>';
					html[html.length] = '</tr>';
				}
				break;
			// expressions
			case 'expression':
				// Case added by DTB390
				for (var d = 0; d < cube.expressions.length; d++) {
					var member = cube.expressions[d];
					if ((inherited)&&(this.findRowForItemName(member.name,itemGroupType)>-1)) {
						continue;
					}
					member._parent = cube;
					member._index = d;
					this._inheritedIndex[this._rowIndex.length] = inherited;
					this._rowIndex[this._rowIndex.length] = member;
					type = 'expression';
					var sourceExpression = member.sourceExpression;
					if (sourceExpression.length > 40) sourceExpression = sourceExpression.substring(0,40) + "...";				
					
					if (inherited) {
						remove = '';
						style = (member.disabled) ?
										'style="background:#C0C0C0;'+inheritedFontStyle+';"' :
										'style="background:'+inheritedBackground+';'+inheritedFontStyle+';"';
					}
					else {
						remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'expression\','+(this._rowIndex.length-1)+','+d+');" />';
						style = (member.disabled) ? 'style="background:#C0C0C0;"' : '';
					}
					
					html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'expression\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
					html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
					html[html.length] = '<td>' + indentMea + zenEscapeXML(member.name) + '</td>';
					html[html.length] = '<td>' + type + '&nbsp;</td>';
					html[html.length] = '<td>' + zenEscapeXML(sourceExpression) + '&nbsp;</td>';
					html[html.length] = '<td>' + remove + '&nbsp;</td>';
					html[html.length] = '<td>' + '&nbsp;</td>';
					html[html.length] = '</tr>';
				}
				break;
				
			default:
				alert('Unknown type in renderCubeItems');
		}		
	}
}

ClientMethod isClosed(cube, item) [ Language = javascript ]
{
	var closed = cube._contracted[item];
	if (this.expandAll == 0) {
		closed = true;
		cube._contracted[item]=true;
	} 
	if (this.expandAll == 1){
		closed = false;
		cube._contracted[item]=false;			
	}
	return closed
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

/// Find the row number in the table for the given model item name.
/// If <var>itemGroup</var> is defined, return the first occurence of 
/// <var>name</var> within the particular group of model items.
/// This must be called after the table has been rendered.
ClientMethod findRowForItemName(name, itemGroup) [ Language = javascript ]
{
	// Method added by DTB156
	var row = -1;
	var itemType = '';
	if (this._rowIndex) {
		for (var r = 0; r < this._rowIndex.length; r++) {
			if (this._rowIndex[r].name == name) {
				if ((!itemGroup)||(this._rowIndex[r]._class.split('.')[2] == itemGroup)) {
					// Return the first occurence of the name if itemGroup is not defined
					row = r;
					break;
				}
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

		// check privileges
		Do CheckArchitectUseAccess^%qdsUtils()
		$$$dsTrackFeature("Architect")		// DTB393

		Set tWrite = $$CheckArchitectWriteAccess^%qdsUtils()
		If ('tWrite) {
			Set ..canWrite = 0
			#; Disable the property details pane 
			Set ..%GetComponentById("tabDetails").disabled = 1
		}
		Set ..readOnly = 0	

		If (..cubeFullName = "") {
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

		If (tExt = "subjectArea") {
			#; check if baseCube is compound. If it is, then do not open.
			If ##class(%DeepSee.UI.Dialog.finderDialog).IsCompound(..cubeFullName) '= "" {
				Set ..cubeFullName = ""
			}
			#; show other architect
			Set %response.Redirect = "_DeepSee.UI.ArchitectSA.zen?CUBE="_$ZCVT(..cubeFullName,"O","URL")
			Quit
		}

		If ('##class(%DeepSee.Utils).%CubeExists(..cubeName, .tSC)) {
			Set ..cubeName = ""
			Set ..dataSource = ""
			Set ..%model = ""
			// JMD1202: do not give error
			Set tSC = $$$OK
			Quit
		}

		Set ^DeepSee.LastCube($UserName) = ..cubeName_".cube"
		If ($G(%request.Data("home",1))'="") {
			Set %response.Context("home") = %request.Data("home",1)
		}

		// get class name for cube
		Set ..cubeClass = ##class(%DeepSee.Utils).%GetCubeClass(..cubeName)
		Set ..cubeDescription = ##class(%DeepSee.Utils).%GetCubeDescription(..cubeName)

		Set ..%model = ##class(%DeepSee.Utils).%GetModel(..cubeName, .tSC)
		If $IsObject(..%model) {
			Set ..cubeName = ..%model.name // Get actual name
			Set ..dataSource = ..%model.sourceClass
			Set ..inheritsFrom = ..%model.inheritsFrom		// DTB156

			// test for write access
			If ((..%model.resource'="")&&'$System.Security.Check(..%model.resource,"WRITE")) {
				Set ..readOnly = 1
			}		
			Set ..%GetComponentById("detailCalMemberDimension").context = "%DeepSee.Component.ContextSearch/Dimensions?subject="_..cubeName
		}
		Else {
			Set ..dataSource = ""
		}		
		Set ..%GetComponentById("detailListingSourceClass").valueList = ..LoadListingSource()
		Set pdef = ##class(%Dictionary.CompiledProperty).%OpenId("%DeepSee.Model.measure||aggregate")
		Set VALUELIST = pdef.Parameters.GetAt("VALUELIST")
		Set ..%GetComponentById("detailMeasureAgg").valueList = $P(VALUELIST,",",2,"999")
		Set pdef = ##class(%Dictionary.CompiledProperty).%OpenId("%DeepSee.Model.measure||type")		
		Set VALUELIST = pdef.Parameters.GetAt("VALUELIST")
		Set ..%GetComponentById("detailMeasureType").valueList = $P(VALUELIST,",",2,"999")
		Set ..cubeDomain = $$$comMemberKeyGet(..cubeClass,$$$cCLASSparameter,"DOMAIN",$$$cPARAMdefault)
		Set ..%GetComponentById("detailCubeDomain").value = ..cubeDomain
		
		// +DTB180 - Collect timefunctions for all calendars once and store in a JSON string
		Set ..timeFunctions = """gregorian"":""" _ ..GetTimeLevelClasses("%DeepSee.Time.AbstractLevel","gregorian") _ """"
		Set ..timeFunctions = ..timeFunctions _ ",""partial"":""" _ ..GetTimeLevelClasses("%DeepSee.Time.AbstractLevel","partial") _ """"		// DTB685 - Add partial dates
		Set ..timeFunctions = ..timeFunctions _ ",""hijriTabular"":""" _ ..GetTimeLevelClasses("%DeepSee.Time.AbstractLevel","hijriTabular") _ """"
		Set ..timeFunctions = ..timeFunctions _ ",""hijriObserved"":""" _ ..GetTimeLevelClasses("%DeepSee.Time.AbstractLevel","hijriObserved") _ """"		// DTB182 - Add hijriObserved
		Set ..timeFunctions = "{" _ ..timeFunctions _ "}"
		// -DTB180
		
		// +DTB321 - Use recursive node processing to capture all cubes in folders
		Set tSC = ##class(%DeepSee.Utils).%GetCubeListArray(.tParms,.pMetaData,.pData,"cubes")
		If $$$ISERR(tSC) Quit
		Set tSC = ##class(%DeepSee.Utils).%ProcessCubeListArrayNode(.pData,,.tCubeList)
		If $$$ISERR(tSC) Quit
		Set ..%GetComponentById("detailRelationshipRelatedCube").valueList = tCubeList
		// -DTB321
		
		#; JMD761
		Set tDependsOn = $$$comClassKeyGet(..cubeClass,$$$cCLASSdependson)
		Set ..cubeDependsOn = tDependsOn
		Set ..%GetComponentById("detailCubeDependsOn").value = ..cubeDependsOn

		#; If we are in a version that ResourceList does not exist (such as 2010.2) then hide the Resource image
		If $System.Version.GetMajor() < 2011 {
			Set ..%GetComponentById("btndetailCubeResource").hidden = 1
			Set ..%GetComponentById("btndetailListingResource").hidden = 1
		}
		Set ..DocumaticPage = ..Link("/csp/documatic/%25CSP.Documatic.cls",,1)_"CLASSNAME="_..EscapeURL(..cubeClass)_"&LIBRARY="_..EscapeURL($namespace)
		
		// +DTB730 - Set the tooltip for this checkBox here so it can support line breaks
		Set tSourceTable = ##class(%DeepSee.Utils).%GetSQLTableName(##class(%DeepSee.Utils).%GetSourceClass(..cubeName))
		Set ..%GetComponentById("detailCubeSqlRestrict").title = "Allow use of the special %SQLRESTRICT dimension where users can specify either:" _ $C(10) _
													"SQL SELECT query that returns one column of IDs that represent IDs of the source class." _ $C(10) _
													"SQL WHERE clause that will be added to query 'SELECT %ID from " _ tSourceTable _ "'." _ $C(10,10) _
													"The MDX result will be restricted to the facts built from the specified source IDs, then additional MDX filters will be applied."
		// -DTB730
		
		// DTB949 - Communicate to the client that the current definition failed to compile
		Set ..compileErrorOnLoad = $D($$$DeepSeeMetaGLVN("cubes",$$$UPPER(..cubeName),"compileError"))
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return Data Connector list
Method LoadListingSource() As %String
{
	Set valueList = ""	
	// setup Data Connector list for Listings
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Set tSC = tRS.Execute("%DeepSee.DataConnector")
	
	While tRS.Next() {
		Set tClass = tRS.GetData(1)
		Set tS = $zobjclassmethod(tClass,"%GetParameter","SUPPORTSIDLIST")
		If tS = 1 Set valueList = valueList _ $S(valueList'="":",",1:"") _ tClass
	}
	Quit valueList
}

/// Get Cube definition for JSON provider.
Method GetCubeDefinition(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	If $IsObject(..%model) {
		Set pObject = ..%model
	}
	ElseIf (..cubeName'="") {
		Set pObject = ##class(%DeepSee.Utils).%GetModel(..cubeName, .tSC)
		If $$$ISOK(tSC) && $IsObject(pObject) {
			If ..IsSourceControlReadOnly(..GetInternalName()) {
				Set pObject.ReadOnly = 2
			}
		}
	}
	
	If $IsObject(pObject)&&(pObject.sourceClass="")&&(..cubeName'="")&&
		$D(^DeepSee.Overrides($$$UPPER(..cubeName),"SOURCECLASS"),tSourceOverride) {
		// DP-404426 - If the source class for the cube is defined solely via an override,
		// use it to allow the UI to function.
		Set pObject.sourceClass = tSourceOverride
		Set ..dataSource = tSourceOverride
	}

	Quit tSC
}

/// Get the inherited Cube definition for JSON provider.
Method GetInheritedCubeDefinition(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	// Method added by DTB156
	Set pObject = $$$NULLOREF
	Set tSC = $$$OK
	Set tCubeName = pParms("inheritsFrom")
	
	If (tCubeName'="") {
		Set pObject = ##class(%DeepSee.Utils).%GetModel(tCubeName, .tSC)
		Set tSC = pObject.%ResolveInheritance()		// If this inherits something else, collapse all into a single inherited representation.
		If (pObject.sourceClass="")&&$D(^DeepSee.Overrides($$$UPPER(tCubeName),"SOURCECLASS"),tSourceOverride) {
			// DP-404426 - If the source class for the inherited cube is defined solely via an override,
			// use it to allow the UI to function.
			Set pObject.sourceClass = tSourceOverride
		}
		If $$$ISERR(tSC) Quit
	}
	Quit tSC
}

/// Report the supported functions for a given calendar.
ClientMethod getTimeFunctionsForCalendar(calendar) [ Language = javascript ]
{
	// Method added by DTB180
	var functionCalendars = ZLM.jsonParse(zenPage.timeFunctions);
	var functionList = '';
	if (calendar) {
		functionList = functionCalendars[calendar];
	}

	return functionList;
}

/// Produces a list of Time level class delimited by commas.
ClassMethod GetTimeLevelClasses(pSubClass, pCalendar = "gregorian") As %String
{
	Set VALUELIST = ""
	Set tCompare = $$$UPPER($P(pSubClass,".",1,2))
	Set tLen = $L(tCompare)
	// Find all subclasses of Time Level class
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Set tSC = tRS.Execute(pSubClass)
	Quit:$$$ISERR(tSC) VALUELIST
	While (tRS.Next(.tSC)) {
		Quit:$$$ISERR(tSC)
		Set tName = $G(tRS.Data("Name"))
		Set tShortName = $P(tName,".",$L(tName,"."))
		// In order to display, check that a time funciton
		// - Is a member of the %DeepSee.Time package (ie: display system functions only)
		// - Uses the appropriate calendar
		If ($E($$$UPPER(tName),1,tLen) = tCompare) && ($Parameter(tName,"CALENDAR")=pCalendar)  {
			Set VALUELIST = VALUELIST_$S(VALUELIST'="":",",1:"")_tShortName
		}
	}
	Quit VALUELIST
}

/// Return the cube definition object.
ClientMethod getCubeObject() [ Language = javascript ]
{
	var json = this.getComponentById('cube');
	var cube = json.getContentObject();
	return cube;
}

/// Return the cube definition object for the inherited cube.
ClientMethod getInheritedCubeObject() [ Language = javascript ]
{
	// Method added by DTB156
	var json = this.getComponentById('inheritedCube');
	var cube = json.getContentObject();
	return cube;
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

/// Return a list of iKnow measures
ClientMethod getiKnowMeasures() [ Language = javascript ]
{
	var cube = this.getCubeObject();
	var measures = "";
	for (var m = 0; m < cube.measures.length; m++) {
		if (cube.measures[m].type == "iKnow") {
			if (measures != "") measures += ","
			measures += cube.measures[m].name;	
		}
	}
	return measures;
}

/// Cancel changes from detail form.
ClientMethod cancelDetailForm() [ Language = javascript ]
{
	// reselect item
	this.selectItem(this.currItemType,this.currItem,true);
}

/// Do the actual work of updating the view to match the current view mode.
ClientMethod setViewModeHandler(mode) [ Language = javascript ]
{
	this.adjustSizes();
}

/// Launch the data source dialog.
ClientMethod changeDataSource() [ Language = javascript ]
{
	if (!this.canUserModify()) {
		return;
	}
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.cls?MODE=sourceclasses','DataSource','status,scrollbars,resizable=yes,width=800,height=600');
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	switch(popupName) {
	case 'SubjectArea':
		// pull extension off of name
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
		if (!isCube) {
			try {
				self.document.location = zenLink('_DeepSee.UI.ArchitectSA.zen?CUBE=' + encodeURIComponent(value));
			}
			catch(ex) {
			}
		}
		else if (name != this.cubeName) {
			try {
				self.document.location = zenLink('_DeepSee.UI.Architect.zen?CUBE=' + encodeURIComponent(value));
			}
			catch(ex) {
			}
		}
		break;
	case 'DataSource':
		if (value != '') {
			// pull extension off of name
			var s = value.toString().split('.');
			if ('cls' == s[s.length-1]) {
				s.length = s.length-1;
				zenPage.setDataSource(s.join('.'));
			}
		}
		break;
	case 'CubeAdd':
		if (value != this.cubeName) {
			try {
				self.document.location = zenLink('_DeepSee.UI.Architect.zen?CUBE=' + encodeURIComponent(value));
			}
			catch(ex) {
			}
		}
		break;	
	case 'CubeSave':
		setTimeout("zenPage.saveCube()",200);
		break;
	case 'CubeCompile':
		break;
	case 'CubeBuild':
		break;
	case 'CubeAddItem':
		if ('' != value) {
			this.addNewItemToModel(value);
		}
		break;
	case 'sourceClass':
		var classname = value.substring(0,value.indexOf('.cls'));
		zen('detailCubeSource').setValue(classname);
		zenPage.applyDetails();
		break;		
	case 'RangeExpression':
		zen('detailLevelRangeExpression').setValue(value);
		zenPage.applyDetails();
		break;	
	case 'FormatString':
		zen('detailMeasureFormatString').setValue(value);
		zenPage.applyDetails();
		break;
	case 'CalMemberFormatString':		// DTB654
		zen('detailCalMemberFormatString').setValue(value)
		zenPage.applyDetails();
		break;
	case 'switchNamespace':
		var homeurl = zenLink("/csp/sys/%25CSP.Portal.Home.zen");
		var url = zenPage.GetNewURL(value,"_DeepSee.UI.Architect.zen");
		if (url == "" || value == "%SYS") url = homeurl;
		try {
			self.document.location = url;
		}
		catch(ex) {
		}
		break;		
	case 'MeasureSource':
		zen('detailMeasureSource').setValue(value);
		zenPage.applyDetails();
		break;
	case 'MeasureExpression':
		zen('detailMeasureExpression').setValue(value);
		zenPage.applyDetails();
		break;
	case 'DimensionSource':
		zen('detailDimensionSource').setValue(value);
		zenPage.applyDetails();
		break;
	case 'DimensionExpression':
		zen('detailDimensionExpression').setValue(value);
		zenPage.applyDetails();
		break;
	case 'LevelSource':
		zen('detailLevelSource').setValue(value);
		zenPage.applyDetails();
		break;
	case 'LevelExpression':
		zen('detailLevelExpression').setValue(value);
		zenPage.applyDetails();
		break;
	case 'LevelDependsOn':
		zen('areadetailLevelDependsOn').setValue(value);
		zenPage.applyDetails();
		break;
	case 'PropertySource':
		zen('detailPropertySource').setValue(value);
		zenPage.applyDetails();
		break;
	case 'PropertyExpression':
		zen('detailPropertyExpression').setValue(value);
		zenPage.applyDetails();
		break;
	case 'RelationshipSource':
		zen('detailRelationshipSource').setValue(value);
		zenPage.applyDetails();
		break;
	case 'RelationshipExpression':
		zen('detailRelationshipExpression').setValue(value);
		zenPage.applyDetails();
		break;
	case 'ListingFieldList':
		zen('areadetailListingFieldList').setValue(value);
		zenPage.applyDetails();
		break;
	case 'ListingSQL':
		zen('areadetailListingSQL').setValue(value);
		zenPage.applyDetails();
		break;
	case 'ListingOrderBy':
		zen('areadetailListingOrderBy').setValue(value);
		zenPage.applyDetails();
		break;
	case 'ListingField': // JSL4436
		zen('detailListingFieldExpression').setValue(value);
		zenPage.applyDetails();
		break;
	case 'ListingFieldResource': // JSL4436		
		zen('detailListingFieldResource').setValue(value);
		zenPage.applyDetails();
		break;
	case 'CalMemberValueExpression':
		zen('areadetailCalMemberValueExpression').setValue(value);
		zenPage.applyDetails();
		break;
	// + WAL190 (2)
	case 'listingFilterExpression':
		zen('areadetailCalcMemberListingFilter').setValue(value);
		zenPage.applyDetails();
		break;
	// - WAL190 (2)
	case 'CubeResource':
		zen('detailCubeResource').setValue(value);
		zenPage.applyDetails();
		break;
	case 'BuildRestriction':
		zen('detailCubeBuildRestriction').setValue(value);
		zenPage.applyDetails();
		break;
	case 'ListingResource':
		zen('detailListingResource').setValue(value);
		zenPage.applyDetails();
		break;	
	case 'iKnowDictionaries':
		zen('detailMeasureiKnowDictionaryValue').setValue(value);
		var tDictLabel = $$$Text("Dictionaries") + " (0)";
		if (value != "") {
			var tDict = value.split(",");
			if (tDict.length > 0) tDictLabel = $$$Text("Dictionaries") + " (" + tDict.length + ")";
		}	
		zen("detailMeasureiKnowDictionaries").setProperty("label",tDictLabel);
		zenPage.applyDetails();
		break;
	case 'SetExpression':
		zen('areadetailNamedSetSetExpression').setValue(value);
		zenPage.applyDetails();
		break;	
	case 'ExpressionExpression':
		// Case added by DTB390
		zen('areadetailExpressionExpression').setValue(value);
		zenPage.applyDetails();
		break;
	case 'ReorderItems':
		var dataCube = value;
		var cube = this.getCubeObject();
		cube.dimensions = dataCube.dimensions;
		cube.measures = dataCube.measures;
		this.addUndoAction();
		this.updateTable();
	}
}

/// Do save now. This method is called from compile also.
ClientMethod saveCube() [ Language = javascript ]
{
	
	this.assignFactNumbers();		// DTB918 - Make sure all fact numbers are assigned
	
	var ok = this.saveDocument();
	if (ok) {
		this.clearUndoBuffer();
		/* saveDocument() may return a new object so we need to reload table object here*/	
		this.updateTable();
		this.selectItem(this.currItemType,this.currItem,true);		
	}
}

/// Set the dataSource for the current cube.
ClientMethod setDataSource(cls) [ Language = javascript ]
{
	if (cls != this.dataSource) {
		this.addUndoAction();
		this.dataSource = cls;
		var cube = this.getCubeObject();
		if (cube) {
			// set type !!!
			cube.sourceClass = this.dataSource;
		}

		zen('dataSource').refreshContents();
		zen('detailCubeSource').setValue(cls);
	}
}

/// Invoke dialog to add a new cube.
ClientMethod newCube() [ Language = javascript ]
{
	// check if there is unsaved changes
	var undo = self.document.getElementById('cmdUndo');
	
	if (undo.disabled == false) {
		var ok = confirm($$$Text("Changes have not been saved for the current cube. Discard changes?"));
		if (ok == false) {
			return false;	
		}
	}
	var parms = {
			MODE:'cube',
			CUBE:this.cubeName,
			CLASS:this.cubeClass
			};

	zenLaunchPopupWindow('_DeepSee.UI.Dialog.CubeAdd.cls','SubjectArea','status,scrollbars,resizable=yes,width=700,height=650',parms);
}

/// Open CubeView page to view all details (if user has not modified anything).
ClientMethod viewCube() [ Language = javascript ]
{
	var cube = this.getCubeObject();	
	if (null == cube) {
		alert(this.msgOpenModel);
		return;	
	}

	if (!this.canUndo()) {
		var urlPage = "_DeepSee.UI.CubeView.zen?CUBE=" + cspEncodeUTF8(this.cubeName);
		document.location = urlPage;

	}
}

/// Open Documatic page to view all details (if user has not modified anything).
ClientMethod doDocument() [ Language = javascript ]
{
	var cube = this.getCubeObject();	
	if (null == cube) {
		alert(this.msgOpenModel);
		return;	
	}

	if (this.canUndo()) {
		alert($$$Text("There are unsaved changes. Documentation will show Compiled class information only."));
	}
	var winWidth = zenGetWindowWidth();
	var winHeight = zenGetWindowHeight();
	var top = winHeight * 0.1;
	var left = winWidth * 0.1;
	var features = 'top='+top+',left='+left+',width='+winWidth+',height='+winHeight+',status,scrollbars,resizable=yes,location=1,toolbar=1,menubar=1';
	var popup = window.open(this.DocumaticPage,'DeepSeeDocument',features);
	popup.focus();
}

/// Invoke dialog to add a new item to the model.
ClientMethod addItem() [ Language = javascript ]
{
	if (!this.canUserModify()) {
		return;
	}
	var cube = this.getCubeObject();
	if (null == cube) {
		alert(this.msgOpenModel);
		return;	
	}
	// show add item dialog
	var selectedItem = this.getSelectedItem();
	var selectedClass;
	if (selectedItem._class) {
		selectedClass = selectedItem._class;
	} else {
		if ('measures' == selectedItem) selectedClass = '%DeepSee.Model.measure';
		// if user clicked 'Dimensions' then Add, we do not want to enable hierarchy therefore we send ''
		if ('dimensions' == selectedItem) selectedClass = '';
		if ('listings' == selectedItem) selectedClass = '%DeepSee.Model.listing';
		if ('listingField' == selectedItem) selectedClass = '%DeepSee.Model.listingField'; // JSL4434
		if ('calculatedMembers' == selectedItem) selectedClass = '%DeepSee.Model.calculatedMember';
		if ('namedSets' == selectedItem) selectedClass = '%DeepSee.Model.namedSets';
		if ('relationships' == selectedItem) selectedClass = '%DeepSee.Model.relationship';
	}
	this._newItemCounter = this._newItemCounter ? this._newItemCounter : 1;
	var parms = {
			MODE:'savecube',
			CUBE:this.cubeName,
			CLASS:this.cubeClass,
			SELECTEDCLASS:selectedClass,
			NEWITEMCOUNTER:this._newItemCounter
			};

	zenLaunchPopupWindow('_DeepSee.UI.Dialog.CubeAddItem.cls','CubeAddItem','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Add a new item to the model and select it.
ClientMethod addNewItemToModel(typenewname) [ Language = javascript ]
{
	if (!this.canUserModify()) {
		return;
	}
	var cube = this.getCubeObject();
	
	//this._newItemCounter = this._newItemCounter ? this._newItemCounter : 1;
	var newItem = null;
	var newType = '';
	this._newItemCounter++;

	// find current selection
	// if it is the correct type, we add new item after it or as a child as appropriate
	var selectedItem = this.getSelectedItem();
	var newnames = typenewname.split("^");
	var type = newnames[0];
	var newname = newnames[1];
	switch(type) {
	case 'measure':
		var newMsr = this.createMeasure(newname,'','number');	
		this.addUndoAction();
		//if (!selectedItem._class || '%DeepSee.Model.measure' != selectedItem._class || null == selectedItem._index) {
			// add to end
			cube.measures[cube.measures.length] = newMsr;
		//}
		//else {
			// insert
		//	cube.measures.splice(selectedItem._index,0,newMsr);
		//}
		newItem = newMsr;
		newType = 'measure';
		break;
	case 'dataDimension':
		var newDim = this.createDim(newname,'data',newname,'')
		this.addUndoAction();
		
		// add initial hierarchy
		var newHier = this.createHier('H1');		
		newDim.hierarchies[0] = newHier;
		
		// add inital level
		var newLevel = this.createLevel('New_Level1','');
		newHier.levels[0] = newLevel;
		
		// add at end
		cube.dimensions[cube.dimensions.length] = newDim;

		newItem = newDim;
		newType = 'dimension';
		break;
	case 'timeDimension':
		var newDim = this.createDim(newname,'time','','')
		this.addUndoAction();
	
		// add initial hierarchy
		var newHier = this.createHier('H1');		
		newDim.hierarchies[0] = newHier;
		
		// add inital level
		var newLevel = this.createLevel('New_Level1','');
		newHier.levels[0] = newLevel;
		
		newDim.hierarchies[0] = newHier;

		// add at end
		cube.dimensions[cube.dimensions.length] = newDim;

		newItem = newDim;
		newType = 'dimension';
		break;
	case 'ageDimension':
		var newDim = this.createDim(newname,'age',newname,'');
		this.addUndoAction();
		
		// add initial hierarchy
		var newHier = this.createHier('H1');		
		newDim.hierarchies[0] = newHier;
		
		// add inital level
		var newLevel = this.createLevel('New_Level1','');
		newHier.levels[0] = newLevel;

		// add at end
		cube.dimensions[cube.dimensions.length] = newDim;

		newItem = newDim;
		newType = 'dimension';
		break;
	case 'iKnowDimension':
		var newDim = this.createDim(newname,'iKnow',newname,'');
		this.addUndoAction();
		
		// add initial hierarchy
		var newHier = this.createHier('H1');		
		newDim.hierarchies[0] = newHier;
		
		// add inital level
		var newLevel = this.createLevel('New_Level1','');
		newHier.levels[0] = newLevel;

		// add at end
		cube.dimensions[cube.dimensions.length] = newDim;

		newItem = newDim;
		newType = 'dimension';
		break;
	case 'sharedDimension':
		var newDim = this.createDim(newname,'data',newname,'');
		newDim.sharesFrom = newnames[2];
		this.addUndoAction();
		
		// add at end
		cube.dimensions[cube.dimensions.length] = newDim;

		newItem = newDim;
		newType = 'dimension';
		break;			
	case 'hierarchy':
		if (!selectedItem._class || ('%DeepSee.Model.dimension' != selectedItem._class &&'%DeepSee.Model.hierarchy' != selectedItem._class)) {
			alert($$$Text('Please select a dimension or hierarchy'));
			return;
		}
		this.addUndoAction();

		var newHier = this.createHier(newname);
		// add inital level
		var newLevel = this.createLevel('New_Level1','');
		newHier.levels[0] = newLevel;

		if ('%DeepSee.Model.hierarchy' != selectedItem._class || null == selectedItem._index) {
			// add to end
			selectedItem.hierarchies[selectedItem.hierarchies.length] = newHier;
		}
		else {
			// insert
			selectedItem._parent.hierarchies.splice(selectedItem._index,0,newHier);
		}
		newItem = newHier;
		newType = 'hierarchy';
		break;
	case 'level':
		if (!selectedItem._class || ('%DeepSee.Model.hierarchy' != selectedItem._class &&'%DeepSee.Model.level' != selectedItem._class)) {
			alert($$$Text('Please select a hierarchy or level'));
			return;
		}
		this.addUndoAction();

		var newLevel = this.createLevel(newname,'');

		if ('%DeepSee.Model.level' != selectedItem._class || null == selectedItem._index) {
			// add to end
			selectedItem.levels[selectedItem.levels.length] = newLevel;
		}
		else {
			// insert
			selectedItem._parent.levels.splice(selectedItem._index,0,newLevel);
		}
		newItem = newLevel;
		newType = 'level';
		break;
	case 'property':
		if (!selectedItem._class || ('%DeepSee.Model.level' != selectedItem._class&&'%DeepSee.Model.property' != selectedItem._class)) {
			alert($$$Text('Please select a level or property'));
			return;
		}
		this.addUndoAction();

		// add a new property to the level
		var newProp = this.createProp(newname,'');

		if ('%DeepSee.Model.property' != selectedItem._class || null == selectedItem._index) {
			// add to end
			selectedItem.properties[selectedItem.properties.length] = newProp;
		}
		else {
			// insert
			selectedItem._parent.properties.splice(selectedItem._index,0,newProp);
		}
		newItem = newProp;
		newType = 'property';
		break;
	case 'listing':
		var newList = this.createListing(newname,'');
		
		this.addUndoAction();

		//YSD2514 always add to the end
		//if (!selectedItem._class || '%DeepSee.Model.listing' != selectedItem._class || null == selectedItem._index) {
			// add to end
			cube.listings[cube.listings.length] = newList;
		//}
		//else {
			// insert
		//	cube.listings.splice(selectedItem._index,0,newList);
		//}
		newItem = newList;
		newType = 'listing';
		break;
	case 'listingField': // JSL4434
		var newField = this.createListingField(newname,'');
		
		this.addUndoAction();
		newItem = newField;
		newType = 'listingField';
		cube.listingFields[cube.listingFields.length] = newField;
		break;
	case 'memberMeasure': case 'memberDimension':
		var newMember = new Object();
		newMember._class = '%DeepSee.Model.calculatedMember';
		newMember.name = newname;
		newMember.description = '';
		newMember.additionalDescription = '';		// DTB391
		newMember.displayName = '';
		newMember.disabled = 0;
		if (type == 'memberMeasure') newMember.dimension = 'Measures';
		else newMember.dimension = 'memberDimension';
		newMember.formatString = '';
		newMember.units = '';
		newMember.valueExpression = '';
		// + WAL190 (2)
		newMember.listingFilter = '';
		newMember.additionalDescription = '';
		// - WAL190 (2)
		
		this.addUndoAction();

		if (!selectedItem._class || '%DeepSee.Model.calculatedMember' != selectedItem._class || null == selectedItem._index) {
			// add to end
			cube.calculatedMembers[cube.calculatedMembers.length] = newMember;
		}
		else {
			// insert
			cube.calculatedMembers.splice(selectedItem._index,0,newMember);
		}
		newItem = newMember;
		newType = 'calculatedMember';
		break;	
	case 'namedSet':
		var newMember = new Object();
		newMember._class = '%DeepSee.Model.namedSet';
		newMember.name = newname;
		newMember.description = '';
		newMember.additionalDescription = '';		// DTB391
		newMember.displayName = '';
		newMember.disabled = 0;
		newMember.setExpression = '';
		
		this.addUndoAction();

		if (!selectedItem._class || '%DeepSee.Model.namedSet' != selectedItem._class || null == selectedItem._index) {
			// add to end
			cube.namedSets[cube.namedSets.length] = newMember;
		}
		else {
			// insert
			cube.namedSets.splice(selectedItem._index,0,newMember);
		}
		newItem = newMember;
		newType = 'namedSet';
		break;				
	case 'relationship':
		var newRelationship = this.createRelationship(newname);
		cube.relationships[cube.relationships.length] = newRelationship;
		this.addUndoAction();
		newItem = newRelationship;
		newType = 'relationship';
		break;
	case 'expression':
	// Case added by DTB390
		var newExpression = new Object();
		newExpression._class = '%DeepSee.Model.expression';
		newExpression.name = newname;
		newExpression.description = '';
		newExpression.additionalDescription = '';		// DTB391
		newExpression.disabled = 0;
		newExpression.sourceExpression = '';
		cube.expressions[cube.expressions.length] = newExpression;
		
		this.addUndoAction();

		newItem = newExpression;
		newType = 'expression';
		break;
	default:
		alert('addNewItem: unknown type: ' + type);
		return;
	}

	if (newItem && '' != newType) {
		this.updateTable();
		this.selectNewItem(newItem,newType);
	}
}

/// Add a new item to the model and select it. Designed for adding an overriden item from 
/// an inherited cube
ClientMethod addInheritedItemToModel(type, inheritedItem) [ Language = javascript ]
{
	// Method added by DTB156
	if (!this.canUserModify()) {
		return;
	}
	var cube = this.getCubeObject();
	this._newItemCounter++;

	// Add the inheritedItem to appropriate group in the local cube model. 
	switch(type) {
	case 'measure':		
		this.addUndoAction();
		cube.measures[cube.measures.length] = inheritedItem;
		break;
	case 'dimension':
		this.addUndoAction();
		cube.dimensions[cube.dimensions.length] = inheritedItem;
		break;		
	case 'hierarchy':
		// Cannot override an orphaned hierarchy
		inheritedItem = null;
		break;
	case 'level':
		// Cannot override an orphaned level
		inheritedItem = null;
		break;
	case 'property':
		// Cannot override an orphaned property
		inheritedItem = null;
		break;
	case 'listing':
		this.addUndoAction();
		cube.listings[cube.listings.length] = inheritedItem;
		break;
	case 'listingField':
		this.addUndoAction();
		cube.listingFields[cube.listingFields.length] = inheritedItem;
		break;
	case 'calculatedMember':
		this.addUndoAction();
		cube.calculatedMembers[cube.calculatedMembers.length] = inheritedItem;
		break;	
	case 'namedSet':
		this.addUndoAction();
		cube.namedSets[cube.namedSets.length] = inheritedItem;
		break;				
	case 'relationship':
		this.addUndoAction();
		cube.relationships[cube.relationships.length] = inheritedItem;
		break;
	default:
		alert('addInheritedItemToModel: unknown type: ' + type);
		return;
	}

	if (inheritedItem && '' != type) {
		this.updateTable();
		this.selectNewItem(inheritedItem,type);
	}
}

/// Create a new measure. 'type' passed in is 'number', 'date', 'boolean' or 'string'
ClientMethod createMeasure(newname, newsource, type) [ Language = javascript ]
{
	var newMsr = new Object();
	newMsr._class = '%DeepSee.Model.measure';
	newMsr.name = newname;
	newMsr.description = '';
	newMsr.additionalDescription = '';		// DTB391
	newMsr.sourceProperty = newsource;
	newMsr.sourceExpression = '';
	newMsr.aggregate = (type=='number') ? 'SUM' : ((type=='date') ? 'AVG' : 'COUNT');
	newMsr.hidden = 0;
	newMsr.scale = '';
	newMsr.type = type;
	newMsr.factName = '';
	newMsr.displayName = '';
	newMsr.disabled = 0;
	newMsr.units = '';
	newMsr.formatString = '';
	newMsr.iKnowSource = '';
	newMsr.iKnowDictionaries = '';
	newMsr.isModified = true;		// DTB918
	// + WAL190 (2)
	newMsr.additionalDescription = '';
	newMsr.listingFilterValue = ''; // WAL222
	// - WAL190 (2)
	return newMsr
}

/// Create new dimension. If drag & drop, sourceprop passed in will not be null.
ClientMethod createDim(newname, dimtype, sourceprop, caption) [ Language = javascript ]
{
	var newDim = new Object();
	newDim._class = '%DeepSee.Model.dimension';
	newDim.name = newname;
	newDim.description = '';
	newDim.additionalDescription = '';		// DTB391
	newDim.sourceProperty = (dimtype!='time') ? '' : sourceprop;
	newDim.sourceExpression = '';		
	newDim.type = dimtype;
	newDim.hasAll = 0;
	newDim.allCaption = 'All' + ' ' + newname;;
	newDim.allDisplayName = newname;
	newDim.disabled = 0;
	newDim.displayName = caption;
	newDim.hierarchies = new Array();
	if (dimtype=='iKnow') {
		var iKnowMeasures = this.getiKnowMeasures();
		newDim.iKnowMeasure = iKnowMeasures.split(',')[0];
		newDim.iKnowType = 'entity';
	}
	else if (dimtype=='time') {
		// DTB237 - Always default to gregorian calendar in new dimensions
		newDim.calendar = 'gregorian';
	}

	newDim.sharesFrom = '';
	return newDim
}

/// Create new hierarchy.
ClientMethod createHier(newname) [ Language = javascript ]
{
	// add a new hierarchy to the dimension
	var newHier = new Object();
	newHier._class = '%DeepSee.Model.hierarchy';
	newHier.name = newname; 
	newHier.description = '';
	newHier.additionalDescription = '';		// DTB391
	newHier.disabled = 0;
	newHier.displayName = '';
	newHier.levels = new Array();
	return newHier;
}

/// Create new level If drag & drop, newsource passed in will not be null.
ClientMethod createLevel(newname, newsource) [ Language = javascript ]
{
	// add a new level to the hierarchy
	var newLevel = new Object();
	newLevel._class = '%DeepSee.Model.level';
	newLevel.name = newname;
	newLevel.description = '';
	newLevel.additionalDescription = '';		// DTB391
	newLevel.sourceProperty = newsource;
	newLevel.sourceExpression = '';
	newLevel.timeFunction = '';
	newLevel.timeFormat = '';		// DTB340
	newLevel.list = false;
	newLevel.listDelimiter = '';
	newLevel.nullReplacement = null;
	newLevel.rangeExpression = '';
	newLevel.useDisplayValue = 1;
	newLevel.factName = '';
	newLevel.disabled = 0;
	newLevel.displayName = '';	
	newLevel.properties = new Array();
	newLevel.sort = '';
	newLevel.dependsOn = '';
	newLevel.isModified = true;		// DTB918
	// + WAL190 (2)
	newLevel.additionalDescription = '';
	// - WAL190 (2)
	return newLevel;
}

/// Create new property. If drag & drop, newsource passed in will not be null.
ClientMethod createProp(newname, newsource) [ Language = javascript ]
{
	// add a new property to the level
	var newProp = new Object();
	newProp._class = '%DeepSee.Model.property';
	newProp.name = newname;
	newProp.description = '';
	newProp.additionalDescription = '';		// DTB391
	newProp.sourceProperty = newsource;
	newProp.sourceExpression = '';
	newProp.factName = '';
	newProp.sort = '';
	newProp.isName = 0;
	newProp.isReference = 0;
	newProp.hidden = 0;
	newProp.disabled = 0;
	newProp.displayName = '';
	return newProp;
}

/// Create new listing object. If drag & drop, fieldName passed in will not be null.
ClientMethod createListing(newname, fieldName) [ Language = javascript ]
{
	var newList = new Object();
	newList._class = '%DeepSee.Model.listing';
	newList.name = newname;
	newList.description = '';
	newList.additionalDescription = '';		// DTB391
	newList.displayName = '';
	newList.disabled = 0;
	newList.fieldList = fieldName;
	newList.listingType = 'table';
	newList.orderBy = '';
	newList.resource = '';
	newList.sourceClass = '';
	newList.sql = '';
	return newList;
}

/// Create new listing object. If drag & drop, fieldExpression passed in will not be null.
ClientMethod createListingField(newname, fieldExpression) [ Language = javascript ]
{
	var newList = new Object();
	newList._class = '%DeepSee.Model.listingField';
	newList.name = newname;
	newList.description = '';
	newList.additionalDescription = '';		// DTB391
	newList.displayName = '';
	newList.disabled = 0;
	fieldExpression = this.transformToSQLExpression(fieldExpression); // JSL4436, only non-null when drag and drop from source tree
	newList.fieldExpression = fieldExpression;
	newList.resource = '';
	return newList;
}

/// Create new relationship object.
ClientMethod createRelationship(newname) [ Language = javascript ]
{
	var newRelationship = new Object();
	newRelationship._class = '%DeepSee.Model.relationship';
	newRelationship.name = newname;
	newRelationship.description = '';
	newRelationship.additionalDescription = '';		// DTB391
	newRelationship.displayName = '';
	newRelationship.disabled = 0;
	newRelationship.cardinality = '';
	newRelationship.factName = '';
	newRelationship.inverse = '';
	newRelationship.linkClass = '';
	newRelationship.linkProperty = '';
	newRelationship.nullReplacement = null;
	newRelationship.relatedCube = '';
	newRelationship.sourceExpression = '';
	newRelationship.sourceProperty = '';
	newRelationship.isModified = true;		// DTB918
	return newRelationship;
}

/// Invoke class finder dialog. popupName="sourceclasses" or "cubes"
ClientMethod browseClass(popupName) [ Language = javascript ]
{
	var mode = (popupName == "sourceClass") ? "sourceclasses" : "cubes";
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.cls?MODE='+mode,popupName,'resizable,width=900,height=500');
}

/// Invoke dialog to edit certain items: RangeExpression, FormatString, SourceProperty, SourceExpression, CubeResource, ListingResource, ListingField.
ClientMethod editItem(what) [ Language = javascript ]
{
	// PFS101 - Do not allow edit dialog if item is disabled
	// DTB755 - Test for existence of the component before checking disabled
	if (zen('detail'+what) && zen('detail'+what).getProperty('disabled')) {
		return;
	}
	var selectedItem = this.getSelectedItem();
	var uiclass = "_DeepSee.UI.Dialog.GetList.cls";
	var spec = "status,scrollbars,resizable=yes,width=640,height=680";
	switch(what) {
	case 'FormatString':
		var value = zen("detailMeasureFormatString").getValue();
		var element = zen('detailMeasureName').getValue();
		uiclass = "_DeepSee.UI.Dialog." + what + ".cls";
		break;
	case 'CalMemberFormatString':		// DTB654
		var value = zen("detailCalMemberFormatString").getValue();
		var element = zen('detailCalMemberName').getValue();
		uiclass = "_DeepSee.UI.Dialog.FormatString.cls";
		break;
	case 'RangeExpression':
		var value = zen("detailLevelRangeExpression").getValue();
		var element = zen('detailLevelName').getValue();
		uiclass = "_DeepSee.UI.Dialog." + what + ".cls";
		break;				
	case 'MeasureSource':
		var value = zen("detailMeasureSource").getValue();
		var element = zen('detailMeasureName').getValue();
		var uiclass = "_DeepSee.UI.Dialog.GetProperties.cls";
		break;			
	case 'MeasureExpression':
		var value = zen("detailMeasureExpression").getValue();
		var element = zen('detailMeasureName').getValue();
		break;		
	case 'DimensionSource':
		var value = zen("detailDimensionSource").getValue();
		var element = zen('detailDimensionName').getValue();
		var uiclass = "_DeepSee.UI.Dialog.GetProperties.cls";
		break;			
	case 'DimensionExpression':
		var value = zen("detailDimensionExpression").getValue();
		var element = zen('detailDimensionName').getValue();		
		break;
	case 'LevelSource':
		var value = zen("detailLevelSource").getValue();
		var element = zen('detailLevelName').getValue();
		var uiclass = "_DeepSee.UI.Dialog.GetProperties.cls";
		break;			
	case 'LevelExpression':
		var value = zen("detailLevelExpression").getValue();
		var element = zen('detailLevelName').getValue();
		break;
	case 'LevelDependsOn':
		var value = zen("areadetailLevelDependsOn").getValue();
		var element = zen('detailLevelName').getValue();
		var uiclass = "_DeepSee.UI.Dialog.FieldList.cls";
		spec = "status,scrollbars,resizable=yes,width=800,height=680";
		break;	
	case 'PropertySource':
		var value = zen("detailPropertySource").getValue();
		var element = zen('detailPropertyName').getValue();
		var uiclass = "_DeepSee.UI.Dialog.GetProperties.cls";
		break;		
	case 'PropertyExpression':
		var value = zen("detailPropertyExpression").getValue();
		var element = zen('detailPropertyName').getValue();
		break;
	case 'ListingFieldList':
		var value = zen("areadetailListingFieldList").getValue();
		var element = zen('detailListingName').getValue();
		var uiclass = "_DeepSee.UI.Dialog.FieldList.cls";
		break;		
	case 'ListingSQL':
		var value = zen("areadetailListingSQL").getValue();
		var element = zen('detailListingName').getValue();
		break;		
	case 'ListingOrderBy':
		var value = zen("areadetailListingOrderBy").getValue();
		var element = zen('detailListingName').getValue();
		var uiclass = "_DeepSee.UI.Dialog.FieldList.cls";
		break;		
	case 'ListingField': // JSL4436
		var value = zen("detailListingFieldExpression").getValue();
		var element = zen("detailListingFieldName").getValue();
		var uiclass = "_DeepSee.UI.Dialog.GetProperties.cls";
		break;			
	case 'ListingFieldResource':
		var value = zen("detailListingFieldExpression").getValue();
		var element = zen("detailListingFieldName").getValue();
		var uiclass = "_DeepSee.UI.Dialog.GetResource.cls";
		break;		// DTB244
	case 'CalMemberValueExpression':
		var value = zen("areadetailCalMemberValueExpression").getValue();
		var element = zen('detailCalMemberName').getValue();
		var uiclass = "_DeepSee.UI.Dialog.ExpressionBuilder.cls"; // WAL126 -- use expression builder
		break;
	// + WAL190 (2)
	case 'listingFilterExpression':
		var value = zen('areadetailCalcMemberListingFilter').getValue();
		var element = zen('detailCalMemberName').getValue();
		var uiclass = "_DeepSee.UI.Dialog.ExpressionBuilder.cls";
		break;
	// - WAL190
	case 'CubeResource':
		var value = zen('detailCubeResource').getValue();
		var element = zen("detailCubeName").getValue();
		var uiclass = "_DeepSee.UI.Dialog.GetResource.cls";
		break;
	case 'BuildRestriction':
		var value = zen('detailCubeBuildRestriction').getValue();
		var element = zen("detailCubeName").getValue();
		break;
	case 'ListingResource':
		var value = zen("detailListingName").getValue();
		var element = zen('detailListingName').getValue();
		var uiclass = "_DeepSee.UI.Dialog.GetResource.cls";
		break;	
	case 'SetExpression':
		var value = zen("areadetailNamedSetSetExpression").getValue();
		var element = zen('detailNamedSetName').getValue();
		var uiclass = "_DeepSee.UI.Dialog.ExpressionBuilder.cls"; // WAL126 -- use expression builder
		break;
	case 'RelationshipSource':
		var value = zen("detailRelationshipSource").getValue();
		var element = zen('detailRelationshipName').getValue();
		var uiclass = "_DeepSee.UI.Dialog.GetProperties.cls";
		break;			
	case 'RelationshipExpression':
		var value = zen("detailRelationshipExpression").getValue();
		var element = zen('detailRelationshipName').getValue();		
		break;
	case 'iKnowDictionaries':
		var value = zen('detailMeasureiKnowDictionaryValue').getValue();
		var element = zen('detailMeasureName').getValue()
		var uiclass = "_DeepSee.UI.Dialog.GetDictionaryList.cls";
	case 'ExpressionExpression':
		// Case added by DTB390
		var value = zen("areadetailExpressionExpression").getValue();
		var element = zen('detailExpressionName').getValue()
		break;
	}

	var parms = {
			CUBE:this.cubeName,
			ELEMENT:element,
			DATASOURCE:this.dataSource,
			SELECTEDCLASS:selectedItem._class,
			VALUE:value,
			WHAT:what
			};
	zenLaunchPopupWindow(uiclass,what,spec,parms);
}

ClientMethod toggleSource(element, type) [ Language = javascript ]
{
	var prop = zen('detail'+element+'Source');
	var expr = zen('detail'+element+'Expression');
	if (type=='Source') {
		prop.setProperty('disabled',false);
		expr.setValue('');
		expr.setProperty('disabled',true);
	} else {
		expr.setProperty('disabled',false);
		prop.setValue('');
		prop.setProperty('disabled',true);
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

/// Invoke dialog to reorder certain elements of the model.
ClientMethod reorder() [ Language = javascript ]
{
	if (!this.canUserModify()) {
		return;
	}
	var cube = this.getCubeObject();
	if (null == cube) {
		alert(this.msgOpenModel);
		return;	
	}

	 // Save a copy for export to child window
	this.exportCube = cube;
	var parms = { CUBENAME:this.cubeName };

	zenLaunchPopupWindow('_DeepSee.UI.Dialog.ReorderItems.cls','ReorderItems','status,scrollbars,resizable=yes,width=680,height=620',parms);
}

/// This method is called from child pages (reorder) to get a live javaScript object of the cube
ClientMethod fetchCube() [ Language = javascript ]
{
	return(this.exportCube);
}

/// Helper method: select an item, make sure it is visible
/// and give focus to the details panel.
ClientMethod selectNewItem(newItem, newType) [ Language = javascript ]
{
	var row = this.findRowForItem(newItem);
	// select the new item
	this.selectItem(newType,row,true);

	// make sure the new item is visible
	var body = self.document.getElementById('modelTableBody');
	var tr = self.document.getElementById('row_' + row);
	if (tr && body) {
		zenScrollIntoView(body,tr);
	}

	var giveFocusTo = '';
	switch(newType) {
	case 'measure':
		giveFocusTo = 'detailMeasureName';
		break;
	case 'dimension':
		giveFocusTo = 'detailDimensionName';
		break;
	case 'hierarchy':
		giveFocusTo = 'detailHierarchyName';
		break;
	case 'level':
		giveFocusTo = 'detailLevelName';
		break;
	case 'property':
		giveFocusTo = 'detailPropertyName';
		break;
	}
	
	if ('' != giveFocusTo) {
		var ctrl = zen(giveFocusTo);
		ctrl.focus();
		ctrl.select();
	}
}

/// User click on a row in the table.
ClientMethod rowClick(type, row) [ Language = javascript ]
{
	this.selectItem(type,row);
}

/// Select a row in the table.
ClientMethod selectItem(type, row, force) [ Language = javascript ]
{
	// console.log('type='+this._rowIndex[row].type+' classType='+this._rowIndex[row]._class.split('.')[2]+' name='+this._rowIndex[row].name+" row="+row+' isInherited='+this._inheritedIndex[row]); //DTB156
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

		/// don't do anything if it's at the top level
		if (('measures' == type)||('dimensions' == type)||('listings' == type)||('listingFields'==type)||('calculatedMembers' == type)||('namedSets' == type)||('relationships' == type)) {
			type = '';
		}
		// set contents of detail form
		var item = this._rowIndex[row];	
		var isInherited = this._inheritedIndex[row];				// DTB156
		var isOverride = this.itemIsOverride(item);					// DTB156
		
		if(type.length>0 && item.length>0 && item!=type) {
			type = '';
		}

		// make appropriate group in details panel visible
		zen('defaultDetails').setHidden(type != '');
		zen('cubeDetails').setHidden(type != 'cube');
		zen('dimensionDetails').setHidden(type != 'dimension');
		zen('hierarchyDetails').setHidden(type != 'hierarchy');
		zen('levelDetails').setHidden(type != 'level');
		zen('listingDetails').setHidden(type != 'listing');
		zen('listingFieldDetails').setHidden(type != 'listingField'); // JSL4434
		zen('propertyDetails').setHidden(type != 'property');
		zen('measureDetails').setHidden(type != 'measure');
		zen('calculatedMemberDetails').setHidden(type != 'calculatedMember');
		zen('namedSetDetails').setHidden(type != 'namedSet');
		zen('relationshipDetails').setHidden(type != 'relationship');
		zen('expressionDetails').setHidden(type != 'expression');			// DTB390
	
		if (item) {
			zen('lblComputed').setHidden(!((item.type == "computed")||(item._dimtype == "computed")));
			switch(type) {
			case 'cube':
				zen('areadetailAdditionalDescriptionCube').setValue(item.additionalDescription);  // WAL172
				zen('detailCubeName').setValue(item.name);
				zen('detailCubeOwner').setValue(item.owner);
				zen('detailCubeResource').setValue(item.resource);
				zen('detailCubeCaption').setValue(item.caption);
				zen('detailCubeDescription').setValue(item.description);
				if (''==this.inheritsFrom) {		// DTB156
					zen('detailCubeSource').setValue(item.sourceClass);
				}
				zen('detailCubeNullReplacement').setValue(item.nullReplacement);
				zen('detailCubeCountMeasureName').setValue(item.countMeasureName);
				zen('detailCubeCountMeasureCaption').setValue(item.countMeasureCaption);
				zen('detailCubeDisplayName').setValue(item.displayName);
				//zen('detailCubeBucketSize').setValue(item.bucketSize);
				zen('detailCubeDisabled').setValue(item.disabled);
				zen('detailCubeFactNums').setValue(item.namedFactNums);		// DTB859 - Make a control for this
				zen('detailCubeDefaultMeasure').setValue(item.defaultMeasure);
				zen('detailCubeDefaultListing').setValue(item.defaultListing);
				zen('detailCubeDefaultMember').setValue(item.defaultMember);
				zen('detailCubeBuildOrder').setValue(item.initialBuildOrder);
				zen('detailCubeBuildRestriction').setValue(item.buildRestriction);
				zen('detailCubeSqlRestrict').setValue(item.enableSqlRestrict);		// DTB730
				break;
			case 'measure':
				zen('areadetailAdditionalDescriptionMeasure').setValue(item.additionalDescription); // WAL172
				zen('areadetailMeasureBasedListing').setValue(item.listingFilterValue); // WAL190 // WAL222
				zen('measureBasedListingComparison').setValue(item.listingFilterOperator); // WAL190
				zen('detailMeasureName').setValue(item.name);
				zen('detailMeasureName').setDisabled(isOverride);		// DTB190
				zen('detailMeasureDescription').setValue(item.description);
				zen('areadetailMeasureDescription').setValue(item.description);
				var agg = item.aggregate;
				// if type is boolean/text/string and aggregate is null then default to COUNT
				if ('' == agg && (item.type == "boolean"||item.type == "text"||item.type == "string")) agg = 'COUNT';
				agg = ('' == agg) ? 'SUM' : agg;
				zen('detailMeasureAgg').setValue(agg);
				zen('detailMeasureType').setValue(item.type);

				var sp = item.sourceProperty;
				var se = item.sourceExpression;
				if ('' != se) {
					sp = '';
					zen('detailMeasureSourceExpressionRB').setValue('expression');
					this.toggleSource('Measure','Expression');
				}
				else {
					zen('detailMeasureSourcePropertyRB').setValue('property');
					this.toggleSource('Measure','Source');
				}
				zen('detailMeasureSource').setValue(sp);
				zen('detailMeasureExpression').setValue(se);
				zen('detailMeasureHidden').setValue(item.hidden);
				zen('detailMeasureScale').setValue(item.scale);
				zen("detailMeasureScale").setHidden(item.type!="number");
				zen('detailMeasureDisplayName').setValue(item.displayName);
				// if type is iKnow, disable Aggregate and Format string, show iKnow source
				zen('detailMeasureiKnowSource').setValue(item.iKnowSource);
				zen("detailMeasureiKnowSource").setHidden(item.type!="iKnow");
				zen("detailMeasureiKnowDictionaryValue").setValue(item.iKnowDictionaries);
				var hideDict = true;
				if (item.type=="iKnow"&&item.iKnowSource!="domain") hideDict = false;
				zen("detailMeasureiKnowDictionaries").setHidden(hideDict);
				var tDictLabel = $$$Text("Dictionaries") + " (0)";
				if (item.iKnowDictionaries != "") {
					var tDict = item.iKnowDictionaries.split(",");
					if (tDict.length > 0) tDictLabel = $$$Text("Dictionaries") + " (" + tDict.length + ")";
				}	
				zen("detailMeasureiKnowDictionaries").setProperty("label",tDictLabel);
				zen('detailMeasureFormatString').setValue(item.formatString);
				// allow to alter disabled status only if not ReadOnly!
				if (this.canWrite && !this.readOnly) {
					zen('detailMeasureFormatString').setDisabled(item.type=="iKnow");
					zen('detailMeasureAgg').setDisabled(item.type=="iKnow");
				}
				zen('detailMeasureDisabled').setValue(item.disabled);
				zen('detailMeasureDisabled').setHidden(isOverride);		// DTB173 - Hide Disabled for overrides
				zen('detailMeasureFactName').setValue(item.factName);
				zen('detailMeasureSearchable').setValue(item.searchable);
				break;
			case 'dimension':
				zen('areadetailAdditionalDescriptionDimension').setValue(item.additionalDescription); // WAL172
			    if (item.type == "computed") {
				    zen('dimensionDetails').setHidden(true);
				    break;
			    }
				zen('detailDimensionName').setValue(item.name);
				zen('detailDimensionName').setDisabled(isOverride);		// DTB190
				zen('detailDimensionDescription').setValue(item.description);
				zen('areadetailDimensionDescription').setValue(item.description);
				var sp = item.sourceProperty;
				var se = item.sourceExpression;
				var dSource = zen('detailDimensionSourceExpressionRB');
				if ('' != se) {
					sp = '';
					dSource.setValue('expression');
					this.toggleSource('Dimension','Expression');
				}
				else {
					dSource.setValue('property');
					this.toggleSource('Dimension','Source');
				}
				if (item.type == 'data' || item.type == 'iKnow') zen('idDetailDimensionSource').setHidden(true);
				else zen('idDetailDimensionSource').setHidden(false);
				zen('detailDimensionSource').setValue(sp);
				zen('detailDimensionExpression').setValue(se);
				zen('detailDimensionHidden').setValue(item.hidden);		// DTB156
				zen('detailDimensionHidden').setHidden(!isOverride);	// DTB156
				zen('detailDimensionType').setValue(item.type);
				zen('detailDimensionHasAll').setValue(item.hasAll);
				zen('detailDimensionAllCaption').setValue(item.allCaption);
				zen('detailDimensionAllDisplayName').setValue(item.allDisplayName);
				zen('detailDimensionDisabled').setValue(item.disabled);
				zen('detailDimensionDisabled').setHidden(isOverride);		// DTB173 - Hide Disabled for overrides
				zen('detailDimensionDisplayName').setValue(item.displayName);
				if (this.canWrite && !this.readOnly) {
					zen("detailDimensionAllCaption").setDisabled(item.hasAll!=1);
					zen("detailDimensionAllDisplayName").setDisabled(item.hasAll!=1);
				}
				zen('detailDimensioniKnowType').setHidden(item.type!="iKnow");
				zen('detailDimensioniKnowMeasure').setHidden(item.type!="iKnow");
				if ('time'==item.type) {
					// DTB181 - Initialize to gregorian if this is not already set
					zen('detailDimensionCalendar').setValue((item.calendar!='') ? item.calendar : 'gregorian');
				}
				else {		
				}
				zen('detailDimensionCalendar').setHidden('time'!=item.type);		// DTB181 - Only expose for time dimensions
				if (item.type == "iKnow") {
					zen('detailDimensioniKnowType').setValue((item.iKnowType!='') ? item.iKnowType : 'entity');
					var iKnowMeasures = this.getiKnowMeasures();
					zen('detailDimensioniKnowMeasure').setProperty("valueList",iKnowMeasures);
					zen('detailDimensioniKnowMeasure').setValue((item.iKnowMeasure!='') ? item.iKnowMeasure : iKnowMeasures.split(',')[0]);
				}
				zen('idDimension').setHidden(item.sharesFrom!="");
				zen('idDimensionSharesFrom').setHidden(item.sharesFrom=="");
				zen('detailDimensionSharesFromCube').setValue(item.sharesFrom);
				break;
			case 'hierarchy':
				zen('areadetailAdditionalDescriptionHierarchy').setValue(item.additionalDescription); // WAL172
				// DTB190 - Hide details for all computed dimension elements
				if (item._dimtype == "computed") {
				    zen('hierarchyDetails').setHidden(true);
				    break;
			    }
			
				zen('detailHierarchyName').setValue(item.name);
				zen('detailHierarchyDescription').setValue(item.description);
				zen('detailHierarchyDisabled').setValue(item.disabled);
				zen('detailHierarchyDisplayName').setValue(item.displayName);
				break;
			case 'level':
				zen('areadetailAdditionalDescriptionLevel').setValue(item.additionalDescription); // WAL172
				// DTB190 - Hide details for all computed dimension elements
				if (item._dimtype == "computed") {
				    zen('levelDetails').setHidden(true);
				    break;
			    }
			
				if (item._dimtype == "time") zen('lblLevel').setValue(this.lblTimeLevel);
				else if (item._dimtype == "age") zen('lblLevel').setValue(this.lblAgeLevel);
				else zen('lblLevel').setValue(this.lblDataLevel);
				///Extract value with function is shown only for time and age levels (p78905)
				zen('idLevelTimeFunction').setHidden(item._dimtype=="data");
				zen('idLevelTimeFormat').setHidden(item._dimtype=="data");			// DTB340
				zen('detailLevelTimeFunction').setProperty('valueList',zenPage.getTimeFunctionsForCalendar(item._calendar));		// DTB180 - Set the timeFunction list
				zen('detailLevelTimeFormat').setValue(item.timeFormat);				// DTB340
				if (this.canWrite && !this.readOnly) {
					// disable Source Values box if it is not "data dimension", but display the value if exists.
					zen('idDetailLevelSource').setProperty('disabled',item._dimtype!="data");
					var detailLevelListDelimiter = zen('detailLevelListDelimiter');
					detailLevelListDelimiter.setDisabled(item.detailLevelList!=1);
				}
				zen('detailLevelList').setValue(item.list);
				if (item.listDelimiter != "") {
					var choice = "other";
					if (item.listDelimiter == ",") choice = "comma";
					zen('detailLevelList').setValue(choice);
					zen('detailLevelList').setProperty("originalValue",choice);
					if (this.canWrite && !this.readOnly) {
						detailLevelListDelimiter.setDisabled(item.listDelimiter==",");
					}
				} 
				detailLevelListDelimiter.setValue(item.listDelimiter);
				// PFS101 - Put this block of code after enable/disable for non-data dimensions
				zen('detailLevelName').setValue(item.name);
				zen('detailLevelDescription').setValue(item.description);
				zen('areadetailLevelDescription').setValue(item.description);
				var sp = item.sourceProperty;
				var se = item.sourceExpression;
				var dSource = zen('detailLevelSourceExpressionRB');
				if (item._dimtype=="data") {
					if ('' != se) {
						sp = '';
						dSource.setValue('expression');
						this.toggleSource('Level','Expression');
					}
					else {
						dSource.setValue('property');
						this.toggleSource('Level','Source');
					}
				}
				zen('detailLevelSource').setValue(sp);
				zen('detailLevelExpression').setValue(se);
				zen('detailLevelNullReplacement').setValue(item.nullReplacement);
				zen('detailLevelUseDisplayValue').setValue(item.useDisplayValue);
				zen('detailLevelDisabled').setValue(item.disabled);
				zen('detailLevelDisplayName').setValue(item.displayName);
				zen("detailLevelRangeExpression").setValue(item.rangeExpression);
				zen('detailLevelSort').setValue(item.sort);
				//use frmHowtotransform now zen('idNotTimeFunction').setHidden(item.timeFunction!="");
				zen('detailLevelFactName').setValue(item.factName);
				zen('detailLevelFactName').setHidden(false);
				if (item._dimtype == "data") {
					zen('idDataFunction').setHidden(false);
					zen('frmHowtotransform').setHidden(false);
				} else {
					zen('frmHowtotransform').setHidden(true);
					zen('idDataFunction').setHidden(true);
					if (item._dimtype == "time") {
						zen('idLevelTimeFunction').setHidden(false);
						zen('idLevelTimeFormat').setHidden(false);					// DTB340
						zen('detailLevelTimeFunction').setValue(item.timeFunction);
						zen('detailLevelTimeFormat').setValue(item.timeFormat);		// DTB340
						zen('detailLevelTimeFunctionAge').setHidden(true);
					} else {
						/// dimtype = "age"
						zen('idLevelTimeFunction').setHidden(true);
						zen('idLevelTimeFormat').setHidden(true);					// DTB340
						zen('detailLevelTimeFunctionAge').setHidden(false);
						zen('detailLevelTimeFunctionAge').setValue(item.timeFunction);
					}
				}
				zen('detailLevelSort').setHidden(item._dimtype=="age");
				if (this.canWrite && !this.readOnly) {
					var iknowflag = (item._dimtype=="iKnow");
					zen('detailLevelSort').setDisabled(iknowflag);
					zen('detailLevelTimeFunctionAge').setDisabled(iknowflag);
					zen('detailLevelFactName').setDisabled(iknowflag);
				}
				zen('areadetailLevelDependsOn').setValue(item.dependsOn);	
				break;
			case 'property':
				zen('areadetailAdditionalDescriptionProperty').setValue(item.additionalDescription); // WAL172
				zen('detailPropertyName').setValue(item.name);
				zen('detailPropertyDescription').setValue(item.description);
				zen('areadetailPropertyDescription').setValue(item.description);
				var sp = item.sourceProperty;
				var se = item.sourceExpression;
				if ('' != se) {
					sp = '';
					zen('detailPropertySourceExpressionRB').setValue('expression');
					this.toggleSource('Property','Expression');
				}
				else {
					zen('detailPropertySourcePropertyRB').setValue('property');
					this.toggleSource('Property','Source');
				}
				zen('detailPropertySource').setValue(sp);
				zen('detailPropertyExpression').setValue(se);
				zen('detailPropertySort').setValue(item.sort);
				zen('detailPropertyIsName').setValue(item.isName);
				zen('detailPropertyIsReference').setValue(item.isReference);
				zen('detailPropertyHidden').setValue(item.hidden);
				zen('detailPropertyDisabled').setValue(item.disabled);
				zen('detailPropertyDisplayName').setValue(item.displayName);
				zen('detailPropertyUseDisplayValue').setValue(item.useDisplayValue);
				zen('detailPropertyFactName').setValue(item.factName);
				break;
			case 'listing':
				zen('areadetailAdditionalDescriptionListing').setValue(item.additionalDescription); // WAL172
				zen('detailListingName').setValue(item.name);
				zen('detailListingName').setDisabled(isOverride);		// DTB190
				zen('detailListingDescription').setValue(item.description);
				zen('areadetailListingDescription').setValue(item.description);
				zen('detailListingDisabled').setValue(item.disabled);
				zen('detailListingDisabled').setHidden(isOverride);		// DTB173 - Hide Disabled for overrides
				zen('detailListingDisplayName').setValue(item.displayName);
				zen('areadetailListingFieldList').setValue(item.fieldList);
				zen('detailListingType').setValue(item.listingType);
				zen('detailListingSelectMode').setValue(item.selectMode);		// DP-414835
				zen('areadetailListingOrderBy').setValue(item.orderBy);
				zen('detailListingResource').setValue(item.resource);
				zen('detailListingSourceClass').setValue(item.sourceClass);
				zen('areadetailListingSQL').setValue(item.sql);
				var useSQL = (item.sql.length > 0);
				zen('detailListingUseSQL').setValue(useSQL);
				this.changeUseSQL();
				break;
			case 'listingField': // JSL4434
				zen('detailListingFieldName').setValue(item.name);
				zen('detailListingFieldName').setDisabled(isOverride);		// DTB190
				zen('detailListingFieldDescription').setValue(item.description);
				zen('areadetailListingFieldDescription').setValue(item.description);
				zen('detailListingFieldDisabled').setValue(item.disabled);
				zen('detailListingFieldDisabled').setHidden(isOverride);		// DTB173 - Hide Disabled for overrides
				zen('detailListingFieldDisplayName').setValue(item.displayName);
				zen('detailListingFieldExpression').setValue(item.fieldExpression);
				zen('detailListingFieldResource').setValue(item.resource);
				break;
			case 'calculatedMember':
				zen('areadetailAdditionalDescriptionCalculatedMember').setValue(item.additionalDescription); // WAL172
				zen('areadetailCalcMemberListingFilter').setValue(item.listingFilter);	// WAL190
				zen('detailCalMemberName').setValue(item.name);
				zen('detailCalMemberName').setDisabled(isOverride);		// DTB190
				zen('detailCalMemberDescription').setValue(item.description);
				zen('detailCalMemberHidden').setValue(item.hidden);		// DTB156
				zen('detailCalMemberHidden').setHidden(!isOverride);	// DTB156
				zen('areadetailCalMemberDescription').setValue(item.description);
				zen('detailCalMemberDisabled').setValue(item.disabled);
				zen('detailCalMemberDisabled').setHidden(isOverride);		// DTB173 - Hide Disabled for overrides
				zen('detailCalMemberDisplayName').setValue(item.displayName);
				zen('detailCalMemberDimension').setValue(item.dimension);
				zen('detailCalMemberFormatString').setValue(item.formatString);
				//zen('detailCalMemberUnits').setValue(item.units);
				zen('areadetailCalMemberValueExpression').setValue(item.valueExpression);
				if (this.canWrite && !this.readOnly) {
					if (item.dimension == "Measures") zen('detailCalMemberDimension').setDisabled(true);
					else zen('detailCalMemberDimension').setDisabled(false);
				}
				// + WAL233
				if (item.dimension=='Measures') {
					zen('areadetailCalcMemberListingFilter').setHidden(false);
					zen('areadetailCalcMemberListingFilterMagnifyingGlass').setHidden(false);
				}
				else {
					zen('areadetailCalcMemberListingFilter').setHidden(true);
					zen('areadetailCalcMemberListingFilterMagnifyingGlass').setHidden(true);
				}
				// - WAL233
				break;
			case 'namedSet':
				zen('areadetailAdditionalDescriptionNamedSet').setValue(item.additionalDescription); // WAL172
				zen('detailNamedSetName').setValue(item.name);
				zen('detailNamedSetName').setDisabled(isOverride);		// DTB190
				zen('detailNamedSetDescription').setValue(item.description);
				zen('areadetailNamedSetDescription').setValue(item.description);
				zen('detailNamedSetDisabled').setValue(item.disabled);
				zen('detailNamedSetDisabled').setHidden(isOverride);		// DTB173 - Hide Disabled for overrides
				zen('detailNamedSetDisplayName').setValue(item.displayName);
				zen('areadetailNamedSetSetExpression').setValue(item.setExpression);
				break;				
			case 'relationship':
				zen('areadetailAdditionalDescriptionRelationship').setValue(item.additionalDescription); // WAL172
				zen('detailRelationshipName').setValue(item.name);
				zen('detailRelationshipName').setDisabled(isOverride);		// DTB190
				zen('detailRelationshipDescription').setValue(item.description);
				zen('areadetailRelationshipDescription').setValue(item.description);
				zen('detailRelationshipDisabled').setValue(item.disabled);
				zen('detailRelationshipDisabled').setHidden(isOverride);		// DTB173 - Hide Disabled for overrides
				zen('detailRelationshipNullReplacement').setValue(item.nullReplacement);
				zen('detailRelationshipDisplayName').setValue(item.displayName);
				zen('detailRelationshipCardinality').setValue(item.cardinality);
				zen('detailRelationshipInverse').setValue(item.inverse);
				zen('detailRelationshipRelatedCube').setValue(item.relatedCube);
				zen('detailRelationshipFactName').setValue(item.factName);
				var sp = item.sourceProperty;
				var se = item.sourceExpression;
				var dSource = zen('detailRelationshipSourceExpressionRB');
				if ('' != se) {
					sp = '';
					dSource.setValue('expression');
					this.toggleSource('Relationship','Expression');
				}
				else {
					dSource.setValue('property');
					this.toggleSource('Relationship','Source');
				}
				zen('detailRelationshipSource').setValue(sp);
				zen('detailRelationshipExpression').setValue(se);

				/*newRelationship.factName = '';
				newRelationship.linkClass = '';
				newRelationship.linkProperty = '';
				*/
				break;
			case 'expression':
				// Case added by DTB390
				zen('detailExpressionName').setValue(item.name);
				zen('detailExpressionName').setDisabled(isOverride);
				zen('detailExpressionDisabled').setValue(item.disabled);
				zen('areadetailExpressionExpression').setValue(item.sourceExpression);
				zen('detailExpressionDescription').setValue(item.description);
				zen('areadetailExpressionDescription').setValue(item.description);
				zen('areadetailAdditionalDescriptionExpression').setValue(item.additionalDescription);
				break;	
			}
		}
	}
	
	// +DTB156 - Adjust the details tab environment according to inheritance behavior
	var classType = (item&&item._class) ? item._class.split('.')[2] : null;

	// +DTB190 - Set message for cube inheritance
	if (('cube'==classType)&&(item.inheritsFrom)) {
		zen('msgCubeInherited').setProperty('hidden',false)
		zen('msgCubeInheritedText').setValue(zenPage.msgCubeInherited.replace(/%1/,zenPage.inheritsFrom));
	}
	else {
		zen('msgCubeInherited').setProperty('hidden',true)
	}

	if (isInherited) {
		zen('msgItemInherited').setProperty('hidden',false);
		zen('msgItemInheritedText').setValue(zenPage.msgItemInherited.replace(/%1/,zenPage.inheritsFrom));
	}
	else {
		zen('msgItemInherited').setProperty('hidden',true);
	}
	// -DTB190
	
	zen('msgOverride').setProperty('hidden',!isOverride);
	if (classType&&(('hierarchy'!=classType)&&('level'!=classType)&&('property'!=classType))) {
		if (('dimension'==classType)&&('computed'==item.type)) {
			zen('btnOverride').setProperty('hidden',true);
		}
		else {
			zen('btnOverride').setProperty('hidden',!isInherited);
		}
	}
	else {
		zen('btnOverride').setProperty('hidden',true);
	}
	zenPage.setDetailContentDisabled(this._inheritedIndex[row])		
	// -DTB156
}

/// Find the css class for the given row type.
ClientMethod getCSSForType(type) [ Language = javascript ]
{
	switch(type) {
	case 'cube':
		return 'modelRowCube';
	case 'measures':
		return 'modelRowDimension';
	case 'measure':
		return 'modelRowMeasure';
	case 'dimensions':
		return 'modelRowDimension';	
	case 'dimension':
		return 'modelRowDimension';		// DTB190 - Use dimension styling for individual dimensions
	case 'hierarchy':
		return 'modelRowHierarchy';
	case 'level':
		return 'modelRowLevel';
	case 'property':
		return 'modelRowProperty';
	case 'listings':
		return 'modelRowDimension';
	case 'listing':
		return 'modelRowMeasure';
	case 'listingFields':
		return 'modelRowDimension'; 	// DTB156 - fix selection formatting for listingFields title bar
	case 'listingField':
		return 'modelRowMeasure'; 		// DTB156 - fix selection formatting for listingField
	case 'calculatedMembers':
		return 'modelRowDimension';
	case 'calculatedMember':
		return 'modelRowMeasure';
	case 'namedSets':
		return 'modelRowDimension';
	case 'namedSet':
		return 'modelRowMeasure';
	case 'relationships':
		return 'modelRowDimension';
	case 'relationship':
		return 'modelRowMeasure';
	case 'expressions':					// DTB390
		return 'modelRowDimension';
	case 'expression':					// DTB390
		return 'modelRowMeasure';

	default:
		alert('Unknown type (css)' + type);
		break;
	}
	return '';
}

/// Apply changes from detail form.
ClientMethod applyDetails() [ Language = javascript ]
{
	var item = this._rowIndex[this.currItem];
	if (item) {
		this.addUndoAction();
		
		switch(this.currItemType) {
		case 'cube':
			item.additionalDescription = zen('areadetailAdditionalDescriptionCube').getValue(); // WAL172
			item.name = zen('detailCubeName').getValue();
			item.owner = zen('detailCubeOwner').getValue();
			item.resource = zen('detailCubeResource').getValue();
			item.caption = zen('detailCubeCaption').getValue();
			item.description = zen('detailCubeDescription').getValue();
			if (''==this.inheritsFrom) {			// DTB156
				item.sourceClass = zen('detailCubeSource').getValue();
				if (item.sourceClass != this.dataSource) {
					this.dataSource = item.sourceClass;
					zen('dataSource').refreshContents();
				}
			}
			item.nullReplacement = zen('detailCubeNullReplacement').getValue();
			item.countMeasureName = zen('detailCubeCountMeasureName').getValue();
			item.countMeasureCaption = zen('detailCubeCountMeasureCaption').getValue();
			item.defaultMeasure = zen('detailCubeDefaultMeasure').getValue();
			item.defaultListing = zen('detailCubeDefaultListing').getValue();
			item.defaultMember = zen('detailCubeDefaultMember').getValue();
			item.disabled = zen('detailCubeDisabled').getValue();
			item.namedFactNums = zen('detailCubeFactNums').getValue();		// DTB859 - Make a control for this
			//item.bucketSize = zen('detailCubeBucketSize').getValue();
			item.displayName = zen('detailCubeDisplayName').getValue();
			item.initialBuildOrder = zen('detailCubeBuildOrder').getValue();
			item.buildRestriction = zen('detailCubeBuildRestriction').getValue();
			item.enableSqlRestrict = zen('detailCubeSqlRestrict').getValue();		// DTB730
			break;
		case 'measure':
			if (this.checkItemModified(item,this.currItemType)) {
				// DTB918 - Mark this item as modified
				item.isModified = true;
				item.factNumber = '';
			}
			item.additionalDescription = zen('areadetailAdditionalDescriptionMeasure').getValue(); // WAL172
			item.listingFilterValue = zen('areadetailMeasureBasedListing').getValue(); // WAL190
			item.listingFilterOperator = zen('measureBasedListingComparison').getValue(); // WAL190
			if (item.listingFilterOperator!='') { zen('detailMeasureSearchable').setValue(true); } // WAL190 (2)
			item.name = zen('detailMeasureName').getValue();
			// + WAL062
			if (zen('detailMeasureSourceExpressionRB').getValue() == 'expression') {
				item.sourceExpression = zen('detailMeasureExpression').getValue();
				item.sourceProperty = '';
			}
			else {
				item.sourceProperty = zen('detailMeasureSource').getValue();
				item.sourceExpression = '';
			}
			// - WAL062
			item.description = zen('detailMeasureDescription').getValue();
			item.aggregate = zen('detailMeasureAgg').getValue();
			item.hidden = zen('detailMeasureHidden').getValue();
			item.scale = zen('detailMeasureScale').getValue();
			item.type = zen('detailMeasureType').getValue();
			item.factName = zen('detailMeasureFactName').getValue();
			item.disabled = zen('detailMeasureDisabled').getValue();
			item.displayName = zen('detailMeasureDisplayName').getValue();
			item.iKnowSource = zen('detailMeasureiKnowSource').getValue();
			item.iKnowDictionaries = zen('detailMeasureiKnowDictionaryValue').getValue();
			item.formatString = zen('detailMeasureFormatString').getValue();
			item.searchable = zen('detailMeasureSearchable').getValue();
			if (item.aggregate != "COUNT" && (item.type=="boolean"||item.type=="text"||item.type=="string")) {
				 if (confirm($$$Text("For a Boolean/String/Text measure, the Aggregate function must be COUNT. Change the Aggregate function now?"))) {
					 zen('detailMeasureAgg').setValue("COUNT");
					 item.aggregate = "COUNT";
				 } 
			}
			if ((item.aggregate!="AVG")&&(item.aggregate!="MAX")&&(item.aggregate!="MIN")
					 && (item.type=="age"||item.type=="date")) {
				if (confirm($$$Text("For a date/age measure, the Aggregate function must be AVG, MAX or MIN. Change the Aggregate function now?"))) {
					 zen('detailMeasureAgg').setValue("AVG");
					 item.aggregate = "AVG";
				 } 
			}
			break;
		case 'dimension':
			item.additionalDescription = zen('areadetailAdditionalDescriptionDimension').getValue(); // WAL172
			item.name = zen('detailDimensionName').getValue();
			item.sourceProperty = zen('detailDimensionSource').getValue();
			item.sourceExpression = zen('detailDimensionExpression').getValue();
			item.hidden = zen('detailDimensionHidden').getValue();				// DTB156
			item.description = zen('detailDimensionDescription').getValue();
			item.type = zen('detailDimensionType').getValue();
			item.hasAll = zen('detailDimensionHasAll').getValue();
			item.allCaption = zen('detailDimensionAllCaption').getValue();
			item.allDisplayName = zen('detailDimensionAllDisplayName').getValue();
			item.disabled = zen('detailDimensionDisabled').getValue();
			item.displayName = zen('detailDimensionDisplayName').getValue();
			item.iKnowMeasure = zen('detailDimensioniKnowMeasure').getValue();
			item.iKnowType = zen('detailDimensioniKnowType').getValue();
			item.calendar = zen('detailDimensionCalendar').getValue();		// DTB179
			break;
		case 'hierarchy':
			item.additionalDescription = zen('areadetailAdditionalDescriptionHierarchy').getValue(); // WAL172
			item.name = zen('detailHierarchyName').getValue();
			item.description = zen('detailHierarchyDescription').getValue();
			item.disabled = zen('detailHierarchyDisabled').getValue();
			item.displayName = zen('detailHierarchyDisplayName').getValue();
			break;
		case 'level':
			if (this.checkItemModified(item,this.currItemType)) {
				// DTB918 - Mark this item as modified
				item.isModified = true;
				item.factNumber = '';
			}
			item.additionalDescription = zen('areadetailAdditionalDescriptionLevel').getValue(); // WAL172
			item.name = zen('detailLevelName').getValue();
			// + WAL062
			if (zen('detailLevelSourceExpressionRB').getValue() == 'expression') {
				item.sourceExpression = zen('detailLevelExpression').getValue();
				item.sourceProperty = '';
			}
			else {
				item.sourceProperty = zen('detailLevelSource').getValue();
				item.sourceExpression = '';
			}
			// - WAL062
			item.description = zen('detailLevelDescription').getValue();
			var list = zen('detailLevelList').getValue();
			// list displayList= "Not a list,$List,Comman,Other"
			// list valueList  = "false,true,comma,other"
			item.list = true;
			item.listDelimiter = zen('detailLevelListDelimiter').getValue();			
			if (list == "false") {
				item.list = false;
				item.listDelimiter = "";
			} 
			if (item._dimtype == "time") {
				item.timeFunction = zen('detailLevelTimeFunction').getValue();
				item.timeFormat = zen('detailLevelTimeFormat').getValue();		// DTB340
			}
			if (item._dimtype == "age") item.timeFunction = zen('detailLevelTimeFunctionAge').getValue();
			item.nullReplacement = zen('detailLevelNullReplacement').getValue();
			item.useDisplayValue = zen('detailLevelUseDisplayValue').getValue();
			item.rangeExpression = zen('detailLevelRangeExpression').getValue();
			item.factName = zen('detailLevelFactName').getValue();
			item.disabled = zen('detailLevelDisabled').getValue();
			item.displayName = zen('detailLevelDisplayName').getValue();
			item.sort = zen('detailLevelSort').getValue();
			item.dependsOn = zen('areadetailLevelDependsOn').getValue();
			break;
		case 'property':
			item.additionalDescription = zen('areadetailAdditionalDescriptionProperty').getValue(); // WAL172
			item.name = zen('detailPropertyName').getValue();
			// + WAL062
			if (zen('detailPropertySourceExpressionRB').getValue() == 'expression') {
				item.sourceExpression = zen('detailPropertyExpression').getValue();
				item.sourceProperty = '';
			}
			else {
				item.sourceProperty = zen('detailPropertySource').getValue();
				item.sourceExpression = '';
			}
			// - WAL062		
			item.description = zen('detailPropertyDescription').getValue();
			item.useDisplayValue = zen('detailPropertyUseDisplayValue').getValue();
			item.sort = zen('detailPropertySort').getValue();
			item.isName = zen('detailPropertyIsName').getValue();
			item.isReference = zen('detailPropertyIsReference').getValue();
			item.hidden = zen('detailPropertyHidden').getValue();
			item.disabled = zen('detailPropertyDisabled').getValue();
			item.displayName = zen('detailPropertyDisplayName').getValue();
			item.factName = zen('detailPropertyFactName').getValue();
			break;
		case 'listing':
			item.additionalDescription = zen('areadetailAdditionalDescriptionListing').getValue(); // WAL172
			item.name = zen('detailListingName').getValue();
			item.description = zen('detailListingDescription').getValue();
			item.disabled = zen('detailListingDisabled').getValue();
			item.displayName = zen('detailListingDisplayName').getValue();
			item.fieldList = zen('areadetailListingFieldList').getValue();
			item.listingType = zen('detailListingType').getValue();
			item.selectMode = zen('detailListingSelectMode').getValue();		// DP-414835
			item.orderBy = zen('areadetailListingOrderBy').getValue();
			item.resource = zen('detailListingResource').getValue();
			item.sql = zen('areadetailListingSQL').getValue();
			item.sourceClass = zen('detailListingSourceClass').getValue();
			break;
		case 'listingField': // JSL4434
			item.name = zen('detailListingFieldName').getValue();
			item.fieldExpression = zen('detailListingFieldExpression').getValue(); // JSL4436
			item.description = zen('detailListingFieldDescription').getValue();
			item.disabled = zen('detailListingFieldDisabled').getValue();
			item.displayName = zen('detailListingFieldDisplayName').getValue();
			item.resource = zen('detailListingFieldResource').getValue();
			break;
		case 'calculatedMember':
			item.additionalDescription = zen('areadetailAdditionalDescriptionCalculatedMember').getValue(); // WAL172
			item.listingFilter = zen('areadetailCalcMemberListingFilter').getValue(); // WAL190
			item.name = zen('detailCalMemberName').getValue();
			item.description = zen('detailCalMemberDescription').getValue();
			item.disabled = zen('detailCalMemberDisabled').getValue();
			item.displayName = zen('detailCalMemberDisplayName').getValue();
			item.dimension = zen('detailCalMemberDimension').getValue();
			item.formatString = zen('detailCalMemberFormatString').getValue();
			item.hidden = zen('detailCalMemberHidden').getValue();				// DTB156
			item.valueExpression = zen('areadetailCalMemberValueExpression').getValue();
			break;
		case 'namedSet':
			item.additionalDescription = zen('areadetailAdditionalDescriptionNamedSet').getValue(); // WAL172
			item.name = zen('detailNamedSetName').getValue();
			item.description = zen('detailNamedSetDescription').getValue();
			item.disabled = zen('detailNamedSetDisabled').getValue();
			item.displayName = zen('detailNamedSetDisplayName').getValue();
			item.setExpression = zen('areadetailNamedSetSetExpression').getValue();
			break;
		case 'relationship':
			if (this.checkItemModified(item,this.currItemType)) {
				// DTB918 - Mark this item as modified
				item.isModified = true;
				item.factNumber = '';
			}
			item.additionalDescription = zen('areadetailAdditionalDescriptionRelationship').getValue(); // WAL172
			item.name = zen('detailRelationshipName').getValue();
			item.description = zen('detailRelationshipDescription').getValue();
			item.disabled = zen('detailRelationshipDisabled').getValue();
			item.displayName = zen('detailRelationshipDisplayName').getValue();
			item.nullReplacement = zen('detailRelationshipNullReplacement').getValue();
			item.cardinality = zen('detailRelationshipCardinality').getValue();
			item.inverse = zen('detailRelationshipInverse').getValue();
			item.relatedCube = zen('detailRelationshipRelatedCube').getValue();		
			item.factName = zen('detailRelationshipFactName').getValue();
			// + WAL062
			if (zen('detailRelationshipSourceExpressionRB').getValue() == 'expression') {
				item.sourceExpression = zen('detailRelationshipExpression').getValue();
				item.sourceProperty = '';
			}
			else {
				item.sourceProperty = zen('detailRelationshipSource').getValue();
				item.sourceExpression = '';
			}
			// - WAL062
			break;
		case 'expression':
				// Case added by DTB390
				item.name = zen('detailExpressionName').getValue();
				item.description = zen('detailExpressionDescription').getValue();
				item.disabled = zen('detailExpressionDisabled').getValue();
				item.sourceExpression = zen('areadetailExpressionExpression').getValue();
				item.additionalDescription = zen('areadetailAdditionalDescriptionExpression').getValue();
			break;

		}

		this.updateTable();
		// !!! this.setModified(true);
	}
}

/// user modified DependsOn. Since it is not part of json, handle it seperately.
ClientMethod applyDependsOn(value) [ Language = javascript ]
{
	this.addUndoAction();
	this.cubeDependsOn = value;
}

/// user modified Domain. Since it is not part of json, handle it seperately.
ClientMethod applyDomain(value) [ Language = javascript ]
{
	this.addUndoAction();
	this.cubeDomain = value;
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

ClientMethod moveItemUp(type, row, index, hier, level, prop) [ Language = javascript ]
{
	var item = this._rowIndex[row];
	var last = "";
	if (item) {
		row--;
		if (row > 0) {
			var cube = this.getCubeObject();
			switch(type) {
			case 'level':
				if (cube.dimensions[index].hierarchies[hier].levels[level-1]) {
					this.addUndoAction();
					last = cube.dimensions[index].hierarchies[hier].levels[level-1];
					cube.dimensions[index].hierarchies[hier].levels[level-1] = cube.dimensions[index].hierarchies[hier].levels[level];
					cube.dimensions[index].hierarchies[hier].levels[level] = last;
				}
			break;
			case 'property':
				if (cube.dimensions[index].hierarchies[hier].levels[level].properties[prop-1]) {
					this.addUndoAction();
					last = cube.dimensions[index].hierarchies[hier].levels[level].properties[prop-1];
					cube.dimensions[index].hierarchies[hier].levels[level].properties[prop-1] = cube.dimensions[index].hierarchies[hier].levels[level].properties[prop];
					cube.dimensions[index].hierarchies[hier].levels[level].properties[prop] = last;
				}
			break;
			}
			if (last != "") {	
				this.updateTable();
			}
		}
	}
}

ClientMethod moveItemDown(type, row, index, hier, level, prop) [ Language = javascript ]
{
	var item = this._rowIndex[row];
	var last = "";
	if (item) {
		row++;
		if (row > 0) {
			var cube = this.getCubeObject();
			switch(type) {
			case 'level':
				if (cube.dimensions[index].hierarchies[hier].levels[level+1]) {
					this.addUndoAction();
					last = cube.dimensions[index].hierarchies[hier].levels[level+1];
					cube.dimensions[index].hierarchies[hier].levels[level+1] = cube.dimensions[index].hierarchies[hier].levels[level];
					cube.dimensions[index].hierarchies[hier].levels[level] = last;
				}
			break;
			case 'property':
				if (cube.dimensions[index].hierarchies[hier].levels[level].properties[prop+1]) {
					this.addUndoAction();
					last = cube.dimensions[index].hierarchies[hier].levels[level].properties[prop+1];
					cube.dimensions[index].hierarchies[hier].levels[level].properties[prop+1] = cube.dimensions[index].hierarchies[hier].levels[level].properties[prop];
					cube.dimensions[index].hierarchies[hier].levels[level].properties[prop] = last;
				}
			break;
			}
			if (last != "") {	
				this.updateTable();
			}
		}
	}
}

/// Remove a row from the table.
ClientMethod removeItem(type, row, index, hier, level, prop) [ Language = javascript ]
{
	var item = this._rowIndex[row];
	if (item) {
		var cube = this.getCubeObject();
		
		var ok = confirm($$$Text('Do you wish to delete this item?')+'\n' + type + ": " + item.name);
		if (!ok) {
			return;
		}
		this.addUndoAction();

		switch(type) {
		case 'measure':
			cube.measures.splice(index,1);
			break;
		case 'dimension':
			cube.dimensions.splice(index,1);
			break;
		case 'hierarchy':
			cube.dimensions[index].hierarchies.splice(hier,1);
			break;
		case 'level':
			cube.dimensions[index].hierarchies[hier].levels.splice(level,1);
			break;
		case 'property':
			cube.dimensions[index].hierarchies[hier].levels[level].properties.splice(prop,1);
			break;
		case 'listing':
			cube.listings.splice(index,1);
			break;
		case 'listingField':
			cube.listingFields.splice(index,1); // JSL4434
			break;
		case 'calculatedMember':
			cube.calculatedMembers.splice(index,1);
			break;			
		case 'namedSet':
			cube.namedSets.splice(index,1);
			break;			
		case 'relationship':
			cube.relationships.splice(index,1);
			break;			
		case 'expression':
			cube.expressions.splice(index,1);		// DTB390
			break;
		}
		
		// +DTB460 - If the last item is being removed, reset the currItem before refreshing the table
		var isLastItem = ((row+1)==this._rowIndex.length);
		if (isLastItem) {
			this.currItem = -1;
			this.currItemType = '';
		}
		// -DTB460

		this.updateTable();

		// reset currItem
		this.currItem = -1;
		this.currItemType = '';
		this.selectItem(this.currItemType,this.currItem,true);
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
		var cube = this.getCubeObject();
		this._undoIndex--;
		var oldcube = this._undoBuffer[this._undoIndex];
		var json = this.getComponentById('cube');
		json.setContentObject(oldcube);
		this.updateTable();
		
		if (cube.sourceClass != oldcube.sourceClass) {
			this.dataSource = oldcube.sourceClass;
			zen('dataSource').refreshContents();
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
	var cube = this.getCubeObject();
	var oldcube = this.cloneObject(cube);
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
	var cube = this.getCubeObject();
	if (cube && cube._contracted) {
		cube._contracted[key] = !cube._contracted[key];
		this.updateTable();
	}
}

/// Drop handler for model table.
ClientMethod tableDropHandler(dragData) [ Language = javascript ]
{
	var tgtId = ZLM.getDragInnerDestination().id;
	var cube = this.getCubeObject();
	
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

	if (null == cube._contracted) {
		cube._contracted = new Object();
	}
	if (item) {
		this.addUndoAction();
		var folderClosed = false;
		var type = item._class;
		if ('measures' == item) {
			// act like a measure
			type = '%DeepSee.Model.measure';
			folderClosed = cube._contracted['measures'];
		}
		if ('dimensions' == item) {
			// act like a dimension
			type = '%DeepSee.Model.dimension';
			folderClosed = cube._contracted['dimensions'];
		}
		if ('listings' == item) {
			type = '%DeepSee.Model.listing';
			folderClosed = cube._contracted['listings'];			
		}
		if ('listingFields' == item) { 		// DTB156 - plural reference to listingFields folder
			type = '%DeepSee.Model.listingField';
			folderClosed = cube._contracted['listingFields'];
		}
		var isconfirmed = 1;
		
		// DTB779 - Set current item to the drop zone
		this.currItem = row;
		this.currItemType = type.split('.')[type.split('.').length-1];
		
		switch(type) {
		case '%DeepSee.Model.cube':
		case '%DeepSee.Model.dimension':
			// add a new dimension to the cube IF user dropped it onto "Dimensions".
			// if user dropped onto an existing dimension, then create H1 and new level with the property name.
			// !!! find type of source property
			var newDName = this.getDimName(cube,dragData.text);
			var proxy = this.GetPropInfo(cube.sourceClass,dragData.value);
			var createType = "data";
			if (proxy.IsDate==1) createType = "time";
			var newDim = this.createDim(newDName,createType,dragData.value,proxy.Caption);
			// add initial hierarchy
			var newHName = this.getHierName(item,"H");
			var newHier = this.createHier(newHName);
			newDim.hierarchies[0] = newHier;	
			// add initial level
			var newLName = this.getLevName(item,dragData.text);
			var newSource = (createType!='time') ? dragData.value : '';
			var newLevel = this.createLevel(newLName,newSource);
			newHier.levels[0] = newLevel;

			if ('%DeepSee.Model.cube' == type) {
				// add to end
				item.dimensions[item.dimensions.length] = newDim;
				newItem = newDim;
				newType = 'dimension';
			}
			else if ('dimensions' == item) {
				cube.dimensions[cube.dimensions.length] = newDim;
				newItem = newDim;
				newType = 'dimension';
			}
			else if (null != item._index) {
				// insert
				//item._parent.dimensions.splice(item._index,0,newDim);
				// create H1 under current dimensions
				item.hierarchies[item.hierarchies.length] = newHier;
				newItem = item;
				newType = 'hierarchy';
			}
			break;
		case '%DeepSee.Model.measure':
			if ('measures' != item) {
				isconfirmed = false;
				break;	
			}
			// add a new measure
			var proxy = this.GetPropInfo(cube.sourceClass,dragData.value);
			var newType = (proxy.IsNumeric == 1) ? 'number' : ((proxy.IsDate == 1) ? 'date' : ((proxy.IsBoolean == 1) ? 'boolean' : 'string'));
			if (newType == 'string') {
				isconfirmed = confirm($$$Text("Most measures are numeric. Are you sure you want to create this nonnumeric measure?"));
				if (!isconfirmed) break;
			}
			var newMName = this.getMeaName(cube,dragData.text);
			var newMsr = this.createMeasure(newMName,dragData.value,newType);

			//now always add to the end 
			//if ('measures' == item) {
			cube.measures[cube.measures.length] = newMsr;
			//}
			//else if (null != item._index) {
			//	item._parent.measures.splice(item._index,0,newMsr);
			//}
			newItem = newMsr;
			newType = 'measure';
			break;
		case '%DeepSee.Model.hierarchy':
			// add a new level to this hierarchy
			var newLName = this.getLevName(item,dragData.text);
			var newSource = (item._dimtype!='time'&&item._dimtype!='age') ? dragData.value : '';
			var newLevel = this.createLevel(newLName,newSource);
			item.levels[item.levels.length] = newLevel;
			newItem = newLevel;
			newType = 'level';
			break;

		case '%DeepSee.Model.level':
			// add a new property to this level
			var newPName = this.getPropName(item,dragData.text);
			var newProp = this.createProp(newPName,dragData.value);
			item.properties[item.properties.length] = newProp;
			newItem = newProp;
			newType = 'property';
			break;

		case '%DeepSee.Model.listing':
			if ('listings' != item) {
				isconfirmed = false;
				break;	
			}
			var newLName = this.getListName();
			//Field List names needs to be SQL name
			var proxy = this.GetPropInfo(this.dataSource,dragData.value);
			newItem = this.createListing(newLName,proxy.SQLNames);
			newType = 'listing';
			cube.listings[cube.listings.length] = newItem;
			break;
		case '%DeepSee.Model.listingField': // JSL4434
			if ('listingFields' != item) {		// DTB156 - change to listingFields (plural)
				isconfirmed = false;
				break;	
			}
			var newLFName = this.getListingFieldName(cube, dragData.text); // JSL4438
			var proxy = this.GetPropInfo(this.dataSource,dragData.value);		// DTB895 - Call GetPropInfo to discover characteristics of the current property
			newItem = this.createListingField(newLFName,proxy.SQLNames); // JSL4436		// DTB895 - Use SQLNames as found in GetPropInfo
			newType = 'listingField';
			cube.listingFields[cube.listingFields.length] = newItem; // JSL4436
			break;
			
		default:
			return true;
		}
		if (!isconfirmed) return false;
		// if user dropped onto a closed folder, open it now.
		if (folderClosed == true) {
			this.toggleDisclosure(item);
		} else {
			this.updateTable();			
		}
		if (newItem && ('' != newType)) {
			this.selectNewItem(newItem,newType);
		}
	} else {
		// item is undefined
	}
	return true;
}

/// Given the base name, return the new name with proper index number 
ClientMethod getMeaName(item, name) [ Language = javascript ]
{
	if (item.measures) {
		var len = item.measures.length;
	} else {
		return name;	
	}
	var namelen = name.length;
	var newnamelen = 0;
	for (var i=0; i < len; i++) {
		var orig = item.measures[i].name;
		if (name == orig.substring(0,namelen)) newnamelen++;
	}
	if (newnamelen == 0) return name;
	return name+newnamelen;
}

/// Given the base name, return the new name with proper index number 
ClientMethod getDimName(item, name) [ Language = javascript ]
{
	if (item.dimensions) {
		var len = item.dimensions.length;
	} else {
		return name;	
	}
	var namelen = name.length;
	var newnamelen = 0;
	for (var i=0; i < len; i++) {
		var orig = item.dimensions[i].name;
		if (name == orig.substring(0,namelen)) newnamelen++;
	}
	if (newnamelen == 0) return name;
	return name+newnamelen;
}

/// Given the base name, return the new name with proper index number 
ClientMethod getHierName(item, name) [ Language = javascript ]
{
	if (item.hierarchies) {
		var len = item.hierarchies.length;
	} else {
		return name+"1";	
	}
	var namelen = name.length;
	var newnamelen = 1;
	for (var i=0; i < len; i++) {
		var orig = item.hierarchies[i].name;
		if (name == orig.substring(0,namelen)) newnamelen++;
	}
	return name+newnamelen;
}

/// Given the base name, return the new name with proper index number 
ClientMethod getLevName(item, name) [ Language = javascript ]
{
	if (item.levels) {
		var len = item.levels.length;
	} else {
		return name;	
	}
	var namelen = name.length;
	var newnamelen = 0;
	for (var i=0; i < len; i++) {
		var orig = item.levels[i].name;
		if (name == orig.substring(0,namelen)) newnamelen++;
	}
	if (newnamelen == 0) return name;
	return name+newnamelen;
}

/// Given the base name, return the new name with proper index number 
ClientMethod getPropName(item, name) [ Language = javascript ]
{
	if (item.properties) {
		var len = item.properties.length;
	} else {
		return name;	
	}
	var namelen = name.length;
	var newnamelen = 0;
	for (var i=0; i < len; i++) {
		var orig = item.properties[i].name;
		if (name == orig.substring(0,namelen)) newnamelen++;
	}
	if (newnamelen == 0) return name;
	return name+newnamelen;
}

/// Return new list name. Starting "New_listing1".
ClientMethod getListName() [ Language = javascript ]
{
	var listNumber = this._newItemCounter ? this._newItemCounter : 1;
	var listName = "New_listing"+listNumber;
	this._newItemCounter = ++listNumber;
	return listName;
}

/// Return new list name. Starting "New_listing1".
ClientMethod getListingFieldName(cube, name) [ Language = javascript ]
{
 // JSL4434
 	if (name == "") { // addElement/Item
		var listNumber = this._newItemCounter ? this._newItemCounter : 1;
		var listName = "New_listingField"+listNumber;
		this._newItemCounter = ++listNumber;
		return listName;
 	} else { // drag and drop JSL4438
		if (cube.listingFields) {
			var len = cube.listingFields.length;
		} else {
			return name;	
		}
		var namelen = name.length;
		var newnamelen = 0;
		for (var i=0; i < len; i++) {
			var orig = cube.listingFields[i].name;
			if (name == orig.substring(0,namelen)) newnamelen++;
		}
		if (newnamelen == 0) return name;
		return name+newnamelen;
	 		
	 }
}

/// Save the cube.
ClientMethod save() [ Language = javascript ]
{
	if (!this.canUserModify()) {
		return;
	}
	if(this.cubeName == "") {
		alert(this.msgOpenModel);
		return;
	}

	// show save dialog
	var cubeName = zen("detailCubeName").getValue();
	if (cubeName == '') cubeName = this.cubeName;
	var parms = {
			MODE:'savecube',
			CUBE:cubeName,
			CLASS:this.cubeClass,
			DESC:this.cubeDescription
			};

	zenLaunchPopupWindow('_DeepSee.UI.Dialog.CubeSave.cls','CubeSave','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,$ZCVT($className(),"O","URL")_".zen?CUBE="_$ZCVT(..cubeFullName,"O","URL"))
	Quit $$$OK
}

/// Object submit handler JSON provider.
/// This is called when the client submits the Cube definition.
Method SubmitCube(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, ByRef pResponseObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tClass = ..cubeClass
		Set tDesc = $TR(..cubeDescription,$C(13),"")
		Set tDomain = ..cubeDomain
		Set tReadOnly = 0

		If (pCommand '= "forcesave") && ##class(%Dictionary.ClassDefinition).%ExistsId(..cubeClass) {
			Set tSC = ..LoadClassDefinition(..cubeClass,.tModelDef,.tReadOnly,1)
			If $$$ISERR(tSC) Quit
			If $zdatetime(tModelDef.TimeChanged,3,,6) '= pSubmitObject.Timestamp {
				Set pProvider.error = "timestamp"
				Quit
			}
		}
		// Save the class cube definition
		// JMD761
		Set tDependsOn = ..cubeDependsOn
		Set tSC = ##class(%DeepSee.Utils).%SaveCubeDefinition(tClass,"",tDesc,pSubmitObject,tDomain,tDependsOn)
		
		If $$$ISERR(tSC) Quit
		// send up-to-date model back to client, this should include updated timestamp
		Set pResponseObject = pSubmitObject
		// correct the ReadOnly flag on the response object
		If ..IsSourceControlReadOnly(..GetInternalName()) {
			Set pResponseObject.ReadOnly = 2
		}
		Else {
			Set pResponseObject.ReadOnly = tReadOnly
		}

	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Set the modified flag for the page.
ClientMethod setModified(flag) [ Language = javascript ]
{
	// Method override added by DTB918 
	this.invokeSuper('setModified',arguments);
	
	var cube  = zenPage.getCubeObject();

	// DTB918 - Block Build if a compile is required
	// DP-417293 - Block build if the cube is abstract
	if (flag || ((cube) && (cube.abstract))) {		// DP-418324 - Test for existence of cube
		this.disableCommandButton('cmdBuild');	
	}
	else {
		this.enableCommandButton('cmdBuild');
	}
}

/// Timeout for the timer managing the compile button
ClientMethod commandBtnTimeout() [ Language = javascript ]
{
	// Method added by DTB933
	zenPage.setCommandsFromBuildState();
	zen('commandBtnTimer').startTimer();
	
	return;
}

/// This method is responsible for controlling the Compile button's availability
/// according to the build lock.
ClientMethod setCommandsFromBuildState() [ Language = javascript ]
{
	// Method added by DTB933
	if (this.CheckBuildLock(zenPage.cubeName) || !this.canWrite || this.readOnly) {
		// The availability of the compile button is dependent on the build lock and the current state of
		// source control (this.readOnly) and current security authorization (this.canWrite)
		zenPage.disableCommandButton('cmdCompile');
	}
	else {
		zenPage.enableCommandButton('cmdCompile');
	}

	return;
}

/// Check to see if the current cube has a build lock, indicating there is an update underway
ClassMethod CheckBuildLock(pCubeName) As %Boolean [ ZenMethod ]
{
	// Method added by DTB933
	Set tCubeIndex = $$$DeepSeeIndex(pCubeName)
	
	Set tIsLocked = 1
	Lock ^DeepSee.Build(tCubeIndex):0

	If $Test {
		Lock -^DeepSee.Build(tCubeIndex)
		Set tIsLocked = 0
	}

	Quit tIsLocked
}

/// Compile the cube.
ClientMethod compile() [ Language = javascript ]
{
	if (!this.canUserModify()) {
		return;
	}
	if(this.cubeName == "") {
		alert(this.msgOpenModel);
		return;
	}
	if (this.CheckBuildLock(zenPage.cubeName)) {		// DTB933 - Final check to account for possible race condition
		zenPage.disableCommandButton('cmdCompile');
		return;
	}
	
	var undo = self.document.getElementById('cmdUndo');
	if ((undo.disabled == false) || (this.pageModified)) {		// DTB918 - Auto-assign will modify without an undo buffer!
		// save before compile!
		this.saveCube();
	}	
	// show compile dialog
	var parms = {
			CUBE:this.cubeName,
			CLASS:this.cubeClass
			};

	zenLaunchPopupWindow('_DeepSee.UI.Dialog.CubeCompile.cls','CubeCompile','status,scrollbars,resizable=yes,width=610,height=700',parms);
}

/// Rebuild the cube.
ClientMethod buildCube() [ Language = javascript ]
{
	// DTB942 - Confirm this user is authorized to build cubes
	if (!this.canUserBuild()) {
		return;
	}
	if(this.cubeName == "") {
		alert(this.msgOpenModel);
		return;
	}
	var cube = this.getCubeObject();
	var maxFacts = cube.maxFacts;
	var modSpecLists = {};
	zenPage.getModifiedFactList(modSpecLists);
	var factModJson = JSON.stringify(modSpecLists);		// DTB911

	// show build dialog
	var parms = {
			CUBE:this.cubeName,
			CLASS:this.cubeClass,
			maxFacts:maxFacts,
			MODIFIED:factModJson
			};

	zenLaunchPopupWindow('_DeepSee.UI.Dialog.CubeBuild.cls','CubeBuild','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Test if the user has write privilege.
ClientMethod canUserModify() [ Language = javascript ]
{
	if (!this.canWrite) {
		alert($$$Text('You are not authorized to modify or save cube definitions.'));
		return false;
	}
	if (this.readOnly) {
		alert($$$Text('This cube definition is read only.'));
		return false;
	}
	return true
}

/// Test if the user has build privileges.
ClientMethod canUserBuild() [ Language = javascript ]
{
	// Method added by DTB942
	if (!this.canWrite) {
		alert($$$Text('You are not authorized to initiate cube builds.'));
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

/// Show analyzer in a new window.
ClientMethod toolAnalyzer() [ Language = javascript ]
{
	var cube = this.cubeName;
	var win = window.open('_DeepSee.UI.Analyzer.zen?CUBE='+encodeURIComponent(cube),'Docbook');
	try {
		win.focus();
	}
	catch(ex) {
	}
}

/// Show query tool in a new window.
ClientMethod toolQuery() [ Language = javascript ]
{
	var cube = this.cubeName;
	cube = (cube!='') ? cube + '.cube' : '';
	var win = window.open('_DeepSee.UI.MDXQuery.zen?SUBJECTAREA='+encodeURIComponent(cube),'Docbook');
	try {
		win.focus();
	}
	catch(ex) {
	}
}

/// Add check to ensure that we correctly load documents on the client when source control hooks are in use.
/// Also set up a timer to ensure we don't hit timeouts while editing documents in Studio, as well as
/// When in Studio mode, also detect whether we are running IE10, as we need to save documents differently if that
/// is the case.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.initializeSourceControl();
	if (!this.canWrite) {
		// DTB646 - User authorization lock on the Page
		this.disableCommandButton("cmdNew");		// DTB440 - Disable New button for readOnly users
		this.disableCommandButton("cmdSave");
		this.disableCommandButton("cmdCompile");
		this.disableCommandButton("cmdBuild");
	}
	
	if (this.readOnly) {
		// DTB646 - Source control lock on the document
		this.disableCommandButton("cmdSave");
		this.disableCommandButton("cmdCompile");
	}
	
	var coverPane = zenPage.getComponentById('detailCoverPane');
	if (!coverPane) {
		zenPage.addDetailCoverPane();
	}
	
	// +DTB156 - set dataSource if cube is inherited
	var cubeI = this.getInheritedCubeObject();
	
	if (cubeI) {
		this.dataSource = cubeI.sourceClass;
		zen('detailCubeSource').setValue(cubeI.sourceClass);
		zen('dataSource').refreshContents();
		
		// DTB935 - The inherited cube settings might prevent the possiblity of the namedFactNums
		// in the current cube.
		// DP-417293 - The inherited cube will block the automatic assignment of fact numbers if it either has
		// no namedFactNums setting or it is set to "false".
		var blockNamedFactNums = (!cubeI.namedFactNums);
	}
	// - DTB156
	
	// + DTB918 - Set cubes as namedFactNums=true
	// DTB963 - Only set if this hasn't been set before. The first load of a cube that has not
	//  had this set should see (null==cube.namedFactNums)=true. Otherwise, 
	//  namedFactnums is already true or it is intentionally turned off
	var cube  = zenPage.getCubeObject();
	if ((cube) && (null==cube.namedFactNums) && (!cube.abstract) && (!blockNamedFactNums)) {		// DTB935 - Test against abstract and inheritance settings
		cube.namedFactNums = true;
		zenPage.setModified(true);
	}
	// - DTB918
	
	if (zenPage.compileErrorOnLoad || ((cube) && (cube.abstract))) {		// DP-418324 - Test for existence of cube
		// DTB949 - Prevent launch of the Build dialog if the cube build will not complete
		// due to compile failure
		// DP-417293 - Disable the Build button for abstract cubes
		this.disableCommandButton('cmdBuild');
	}
}

/// Adds a coverpane to the details tab in the DOM. This is used to disable the entire details section
/// while still being able to read the items.
ClientMethod addDetailCoverPane() [ Internal, Language = javascript ]
{
	// Method added by DTB156
	var detailsContent = zen('tabDetailContent');
	var parentDiv = detailsContent.getEnclosingDiv();
	var newDiv = document.createElement('div');
	newDiv.setAttribute('id','detailCoverPane');
	newDiv.setAttribute('class','coverPaneInactive');
	
	parentDiv.style.position='relative';
	
	parentDiv.appendChild(newDiv);
}

/// method for when user mouse over a row in the table
ClientMethod rowMouseOver(element, div) [ Language = javascript ]
{
	var tooltip = this.hlpDropTooltip;
	div.style.color='orange';
	if (ZLM.dragActive == 1) {
		div.style.color='orange';
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

/// This method returns the following values via proxy object:<br>
/// 1) IsDate is set to 1 if the property type is a date format. Verified against the ODBC type.<br>
/// 2) IsNumeric is set to 1 if the property type is any kind of numeric format. Verified against the ODBC type.<br>
/// 3) Caption is the property's parameter CAPTION.</br>
/// 4) SQLNames in the fashion of Prop1 -> Prop2 -> Prop3.</br>
/// 5) IsBoolean is set to 1 if the property type is a boolean. Verified against the ODBC type.
/// 
ClassMethod GetPropInfo(sourceClass, fullName) As %ZEN.proxyObject [ ZenMethod ]
{
	Try {
		Set tProxy = ##class(%ZEN.proxyObject).%New()
		Set tProxy.IsDate = 0
		Set tProxy.IsNumeric = 0
		Set tProxy.IsBoolean = 0
		Set tProxy.Caption = ""
		Set tProxy.SQLNames = ""
		Set cnt = 1
		
		// +DTB160
		Set tIsConnector = ##class(%DeepSee.Utils).%IsDataConnector(sourceClass)
		If tIsConnector {
			// Collect information about the dataconnector definition
			Set tSC = $classMethod(sourceClass,"%GetPropertyInfo",.tList)
			Set tItem = $O(tList(""))
			While (tItem'="") {
				Set tConnectorProperties($LG(tList(tItem),1)) = $LG(tList(tItem),3)
				Set tItem = $O(tList(tItem))
			}
		}
		// -DTB160

		Set prop = $P(fullName,".",cnt)
		Set tLen = $L(fullName,".")
		While prop '= "" {
			// + WAL074 -- Use global lookup instead of %Dictionary.Class query so users don't need
			//             privileges on that table for Architect functionality
			Set tPropClass = $$$comMemberKeyGet(sourceClass,$$$cCLASSproperty,prop,$$$cPROPtype)
			If tIsConnector {
				// DTB160 - If the property is defined by a dataconnector, normalize its data type
				Set tType = $S($D(tConnectorProperties(prop)):tConnectorProperties(prop))
				If $E(tType,1)="%" {
					Set tType = $E(tType,2,*)
				}
				Set tType = $$$UPPER(tType)
			}
			Else {
				// Revert to previous
				Set tType = $$$comClassKeyGet(tPropClass,$$$cCLASSodbctype)
			}
			If tPropClass '[ "%Library",##class(%Dictionary.CompiledClass).%ExistsId(tPropClass) {
				Set sourceClass = tPropClass
			}
			// - WAL074
			Set tProxy.IsDate = $Case(tType,"DATE":1,"TIMESTAMP":1,:0)
			Set tProxy.IsNumeric = $Case(tType,"INTEGER":1,"NUMERIC":1,"DOUBLE":1,"BIGINT":1,"LONGVARBINARY":1,"SMALLINT":1,"TINYINT":1,"VARBINARY":1,:0)
			Set tProxy.IsBoolean = $case(tType,"BOOLEAN":1, "BIT":1, :0)
			Set tProxy.Caption = $$$comMemberArrayGet(sourceClass,$$$cCLASSproperty,prop,$$$cPROPparameter,"CAPTION")
			Set tSQL = ##class(%DeepSee.Utils).%GetSQLColumnName(sourceClass,prop)
			Set tProxy.SQLNames = tProxy.SQLNames _ $S(tSQL'="":tSQL,1:prop) _ $S(cnt<tLen:"->",1:"")
			Set cnt = cnt + 1
			Set prop = $P(fullName,".",cnt)
		}
	} 
	Catch(ex) {
		Set tProxy.IsDate = 0
		Set tProxy.Caption = ""
	}
	Quit tProxy
}

/// Return the internal name of the current document, including the three letter
/// extension in upper-case. For example, MyPackage.MyClass.CLS would be the internal name
/// for the class MyPackage.MyClass.
Method GetInternalName() As %String
{
	Quit ..cubeClass_".CLS"
}

/// Return the current name of the class/object being modified.
ClientMethod getCurrentName() [ Language = javascript ]
{
	// fallback on class name if cube name is null or empty
 	if ((!this.cubeName) || (0 === this.cubeName.length))
 	{
 		return this.cubeClass;
 	}
	return this.cubeName;
}

/// Get the title string to add to the locator row.
/// This should be implemented in a subclass.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return this.getCurrentName();
}

/// Get the jsonProvider object on the client.
ClientMethod getClientModel() [ Language = javascript ]
{
	return zen('cube');
}

/// Callback method invoked after we have successfully loaded the current document.
ClientMethod onDocumentLoadComplete() [ Language = javascript ]
{
	this.updateDocumentState(true);
}

/// This callback is called at the end of the HTML HEAD section of the page.<br/>
Method %OnDrawHTMLHead() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set tSC = ..%DrawSourceControlHead()
	Quit tSC
}

/// method used by Source Control to set the value of the readOnly flag.
ClientMethod setReadOnly(readOnly) [ Language = javascript ]
{
	this.readOnly = !!readOnly;
	zen("tabDetails").setProperty('disabled',!!readOnly);
}

ClientMethod transformToSQLExpression(expr) [ Language = javascript ]
{
	// current implementation is a hack, does not take care of delimited identifiers
	components = expr.split(".");
	return components.join("->")
}

ClientMethod dropDetailListingFieldExpression(dragData) [ Language = javascript ]
{
	zen("detailListingFieldExpression").setValue(this.transformToSQLExpression(dragData.value));
	this.applyDetails();
}

/// Called by the Override button to override an inherited item in the local cube definition.
ClientMethod overrideInheritedItem() [ Language = javascript ]
{
	// Method added by DTB156
	var item = zenPage.getSelectedItem();
	var classType = item._class.split('.')[2]
	
	zenPage.addInheritedItemToModel(classType,item);
}

/// This prevents a user from making changes to the item details using the cover pane.
ClientMethod setDetailContentDisabled(setDisabled) [ Language = javascript ]
{
	// Method added by DTB156
	var coverPane = document.getElementById('detailCoverPane');
	if (setDisabled) {
		//coverPane.style.bottom='0px';
		coverPane.setAttribute('class','coverPaneActive');
	}
	else {
		//coverPane.style.bottom='';
		coverPane.setAttribute('class','coverPaneInactive');
	}
}

/// If it exists, search the inherited cube object for the same
/// logical definition as <var>item</var>.
ClientMethod itemIsOverride(item) [ Language = javascript ]
{
	// Method added by DTB156
	if (!item) {
		return false;
	}
	var isOverride = false;
	
	var inheritedCube = this.getInheritedCubeObject();
	var itemClass = (item._class) ? item._class : '';
	var itemType = '';
	var itemRow = -1;
	
	if (itemClass) {
		itemType = itemClass.split('.')[2] + 's';
		itemRow = this.findRowForItemName(item.name,itemClass.split('.')[2]);
	}
	
	if ((inheritedCube)&&(!this._inheritedIndex[itemRow])&&inheritedCube[itemType]) {
		for ( i = 0 ; i < inheritedCube[itemType].length ; i++ ) {
			if (item.name==inheritedCube[itemType][i].name) {
				isOverride = true;
				break;
			}
		}
	}
	
	return isOverride;
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

/// Pass in an item and type and test if the settings substantial to data storage definition 
/// (eg: values, type, etc.) have changed.
ClientMethod checkItemModified(item, type) [ Language = javascript ]
{
	// Method added by DTB918
	if (!item) return false;
	
	var isModified = false;
	var typeString = '';
	
	// Control settings are type-specific references
	if (!isModified) {
		switch (type) {
			case 'measure':
				typeString = 'Measure';
				if (	(item.type != zen('detailMeasureType').getValue()) 
					) {
					isModified = true;
				}
			break;
			case 'level':
				typeString = 'Level';
				if (	(item.dependsOn != zen('areadetailLevelDependsOn').getValue())||
						(item.nullReplacement != zen('detailLevelNullReplacement'))
					) {
					isModified = true;	
				}
				
				if ((item._dimtype == 'time') &&
						( (item.timeFunction != zen('detailLevelTimeFunction').getValue()) ||
						(item.timeFormat != zen('detailLevelTimeFormat').getValue()) )
					) {
					isModified = true;	
				}
				if ((item._dimtype == 'age') && (item.timeFunction != zen('detailLevelTimeFunctionAge').getValue())) {
					isModified = true;
				}
			break;
			case 'relationship':
				typeString = 'Relationship';
				if (	(item.cardinality != zen('detailRelationshipCardinality').getValue()) ||
						(item.inverse != zen('detailRelationshipInverse').getValue()) ||
						(item.relatedCube != zen('detailRelationshipRelatedCube').getValue())||
						(item.nullReplacement != zen('detailRelationshipNullReplacement'))
					) {
					isModified = true;	
				}
			break;
		}
	}
	
	if (	(item.sourceExpression != zen('detail'+typeString+'Expression').getValue()) ||
			(item.sourceProperty != zen('detail'+typeString+'Source').getValue()) ||
			(item.disabled != zen('detail'+typeString+'Disabled')) ||
			(item.factName != zen('detail'+typeString+'FactName'))
		) {
		isModified = true;	
	}

	return isModified;
}

/// Examine the cube definition object. If the cube's namedFactNums property is set, automatically assign a factNumber to
/// any structural element that does not already have one defined.
ClientMethod assignFactNumbers() [ Language = javascript ]
{
	// Method added by DTB910
	var cube = zenPage.getCubeObject();
	var isInherited = (''!==cube.inheritsFrom);		// DTB935
	
	if (cube && (cube.namedFactNums)) {
		// Create arrays to hold the reference locations of the items that need fact numbers set
		var definedFactNums = [1];		// The fact number "1" is always going to go to the %SEARCH virtual dimension
		var definedMsrNums = [];		// DTB918 - Previously generated ID numbers could be duplicated between Measures and Dimensions 
		var sourceIndex = {"dimensions":{},"measures":{},"relationships":{}};		// DTB918 - Remember the source for each fact number
		var missing = {"dimensions":[],"measures":[],"relationships":[]};
		
		// + DTB935 - Assemble the lookup indices for the cube, accounting for the inherited cube if applicable.
		// When complete:
		// - 'defined*' arrays will have the reserved fact numbers
		// - 'sourceIndex' will account for sources of all fact table columns that will be compiled
		// - the 'missing' index will point to any elements that need to be assigned a fact number prior to compile
		if (isInherited) {
			var iCube = zenPage.getInheritedCubeObject();
			zenPage.analyzeCubeModel(iCube, definedMsrNums, definedFactNums, sourceIndex, missing);
			// NB: 'missing' should be empty at this moment since the supercube should be compiled
		}
		zenPage.analyzeCubeModel(cube, definedMsrNums, definedFactNums, sourceIndex, missing);
		// - DTB935
		

		// Now assign factNumbers to any elements that have been recorded in 'missing'.
		var nextFact = 2;		// The fact number "1" is always going to go to the %SEARCH virtual dimension
		var nextMsr = 1;		// DTB918
		
		var currItem = null;
		var currItemType = '';		// DP-410382
		for (m in missing.measures) {
			// DTB918 - Check the sourceIndex and assign the same fact number to same source and type
			currItem = cube.measures[missing.measures[m]];
			currItemType = currItem.type;
			
			if (('' != currItem.sourceProperty) && ('' == currItemType)) {
				// DP-410382 - Attempt to fill in the measure type based on the metadata available from the source
				var proxy = this.GetPropInfo(this.dataSource,currItem.sourceProperty);
				if (proxy.IsNumeric) {
					currItemType = 'number';
				}
				else if (proxy.IsBoolean) {
					currItemType = 'boolean';
				}
				else if (proxy.IsDate) {
					currItemType = 'date';
				}
				else {
					currItemType = 'string';
				}
			}
			
			currSource = (currItem.sourceProperty ? currItem.sourceProperty : currItem.sourceExpression) +':'+ currItemType;

			if (sourceIndex.measures[currSource]) {
				currItem.factNumber = sourceIndex.measures[currSource];
			}
			else {
				while (definedMsrNums.indexOf(nextMsr)>=0) {
					nextMsr++;
				}
				
				currItem.factNumber = nextMsr;
				definedMsrNums.push(nextMsr);
				if (!sourceIndex.measures[currSource]) {
					// DTB935 - Log this in the sourceIndex in case the same source is going
					// to be assigned to another element marked missing
					sourceIndex.measures[currSource] = nextMsr;
				}
			}
		}
		
		for (r in missing.relationships) {
			// DTB918 - Check the sourceIndex and assign the same fact number to same source
			currItem = cube.relationships[missing.relationships[r]];
			currSource = (currItem.sourceProperty ? currItem.sourceProperty : currItem.sourceExpression);
			
			if (sourceIndex.relationships[currSource]) {
				currItem.factNumber = sourceIndex.relationships[currSource];
			}
			else {
				while (definedFactNums.indexOf(nextFact)>=0) {
					nextFact++;
				}
				
				currItem.factNumber = nextFact;
				definedFactNums.push(nextFact);
				if (!sourceIndex.relationships[currSource]) {
					// DTB935 - Log this in the sourceIndex in case the same source is going
					// to be assigned to another element marked missing
					sourceIndex.relationships[currSource] = nextFact;
				}
			}
		}
		var currSourceMap = new Map();
		for (a in missing.dimensions) {
			// DTB918 - Check the sourceIndex and assign the same fact number to same source
			var addr = missing.dimensions[a];
			var dimension = cube.dimensions[addr[0]];		// DTB935 - Extract the dimension for later reference
			currItem = dimension.hierarchies[addr[1]].levels[addr[2]];
			
			currSource = zenPage.getLevelSourceForIndex(dimension,currItem);		// DTB937
			// DP-405883
			if( ( ('iKnow' === dimension.type) || ('computed' === dimension.type) )){
					currSource = addr[0].toString()+'.'+addr[1].toString()+'.'+addr[2].toString();
					if(currSourceMap.has(currSource)){
						currSource = currSource + '_' + currSourceMap.get(currSource);
						currSourceMap.set(currSource, currSourceMap.get(currSource)+1);
					}
					else{
						currSourceMap.set(currSource,2);
					}
				}
			
			if (sourceIndex.dimensions[currSource]) {
				currItem.factNumber = sourceIndex.dimensions[currSource];
			}
			else {
				while (definedFactNums.indexOf(nextFact)>=0) {
					nextFact++;
				}
				
				currItem.factNumber = nextFact;
				definedFactNums.push(nextFact);
				if (!sourceIndex.dimensions[currSource]) {
					// DTB935 - Log this in the sourceIndex in case the same source is going
					// to be assigned to another element marked missing
					sourceIndex.dimensions[currSource] = nextFact;
				}
			}
		}
	}
}

/// This will compare the current cube model with the compiled definition. It will return two arrays 
///  <var>definedMsrNums</var>, <var>definedFactNums</var>
/// containing the known factNumbers that have been used in measures and levels/relationships, respectively.
/// For those items that have factNumbers assigned, the mapping between column sources and factNumbers 
/// is returned in <var>sourceIndex</var>. Anything that has been modified in the current session or did not 
/// previously have a compiled fact number will be returned in the <var>missing</var> index.<br><br>
/// If factNumbers of the model elements have not been explicitly set but have been previously assigned internally
/// via the compile, the factNumbers in the current cube model will be set to those numbers. 
/// In the case of inherited cubes, only the compiled factNumbers of the supercube will be held constant. 
ClientMethod analyzeCubeModel(cube, definedMsrNums, definedFactNums, sourceIndex, missing) [ Language = javascript ]
{
	// Method added by DTB935
	var currSource = '';
	var currFactNo = '';
	var isInherited = (''!=cube.inheritsFrom);
	
	// Initialize local versions of the input parameters if they are not supplied by the caller
	if (!definedFactNums) {
		var definedFactNums = [1];		// The fact number "1" is always going to go to the %SEARCH virtual dimension
	}
	if (!definedMsrNums) {
		var definedMsrNums = [];		// Previously generated ID numbers could be duplicated between Measures and Dimensions 
	}
	if (!sourceIndex) {
		var sourceIndex = {"dimensions":{},"measures":{},"relationships":{}};		// Remember the source for each fact number
	}
	if (!missing) {
		var missing = {"dimensions":[],"measures":[],"relationships":[]};
	}
	
	// Query the server for the relevant fact numbers that have previously been assigned in a compile.
	// When this cube inherits from another, use the compiled information from the supercube.
	if (isInherited) {
		var compiledFactNums = JSON.parse(zenPage.GetCompiledFactNumbers(cube.inheritsFrom));
	}
	else {
		var compiledFactNums = JSON.parse(zenPage.GetCompiledFactNumbers(cube.name));
	}

	// Examine current model measures
	var mName = '';
	var currItemType = '';		// DP-410382
	for (m in cube.measures) {
		mName = '[MEASURES].[' + cube.measures[m].name + ']';
		
		currItemType = cube.measures[m].type;
		if (('' != cube.measures[m].sourceProperty) && ('' == currItemType)) {
			// DP-410382 - Attempt to fill in the measure type based on the metadata available from the source
			var proxy = this.GetPropInfo(this.dataSource,cube.measures[m].sourceProperty);
			if (proxy.IsNumeric) {
				currItemType = 'number';
			}
			else if (proxy.IsBoolean) {
				currItemType = 'boolean';
			}
			else if (proxy.IsDate) {
				currItemType = 'date';
			}
			else {
				currItemType = 'string';
			}
		}
		
		currSource = (cube.measures[m].sourceProperty ? cube.measures[m].sourceProperty : cube.measures[m].sourceExpression) +':'+ currItemType;		// DTB918

		if (!cube.measures[m].isModified) {
			// If the measure is not marked modified, check the actual factNumber setting
			if (cube.measures[m].factNumber) {
				// The model does have a number already assigned
				definedMsrNums.push(cube.measures[m].factNumber);
			}
			else if (compiledFactNums.measures[mName.toUpperCase()]) {
				// This should be the initial assignment case following upgrade.
				// The model doesn't declare the fact number but there is an assigned number in
				// the metadata. Preserve this number.
				currFactNo = compiledFactNums.measures[mName.toUpperCase()];
				// For measures the returned factNumber probably begins with 'M'. Remove it to
				// expose the raw integer.
				currFactNo = (currFactNo[0]=='M' ? currFactNo.slice(1,currFactNo.length) : currFactNo );
				cube.measures[m].factNumber = parseInt(currFactNo);
				definedMsrNums.push(cube.measures[m].factNumber);
			}
			else if (isInherited) {
				// Elements defined in cubes inheriting other definitions could have conflicting
				// fact numbers due to changes in a supercube. To be safe these will all be reset.
				missing.measures.push(m);
			}
		}
		else {
			// DTB959 - Multiple compiles without a build can mean the element is marked modified
			// and has a factNumber assigned. Only assign to the missing index if there is no
			// factNumber.
			if (cube.measures[m].factNumber) {
				// The model does have a number already assigned
				definedMsrNums.push(cube.measures[m].factNumber);
			}
			else {
				missing.measures.push(m);
			}
		}
		
		if ((cube.measures[m].factNumber) && (currSource)) {
			// Remember which source is used to produce this value
			sourceIndex.measures[currSource] = cube.measures[m].factNumber;
		}
	}

	// Examine current model relationships
	var rName = '';
	for (r in cube.relationships) {
		rName = '[' + cube.relationships[r].name + ']';
		currSource = (cube.relationships[r].sourceProperty ? cube.relationships[r].sourceProperty : cube.relationships[r].sourceExpression);		// DTB918
		
		if (!cube.relationships[r].isModified) {
			// If the relationship is not marked modified, check the actual factNumber setting
			if (cube.relationships[r].factNumber) {
				// The model does have a number assigned
				definedFactNums.push(cube.relationships[r].factNumber);
			}
			else if (compiledFactNums.relationships[rName.toUpperCase()]) {
				// This should be the initial assignment case following upgrade.
				// The model doesn't declare the fact number but there is an assigned number in
				// the metadata. Preserve this number.
				currFactNo = compiledFactNums.relationships[rName.toUpperCase()];
				cube.relationships[r].factNumber = parseInt(currFactNo);
				definedFactNums.push(cube.relationships[r].factNumber);
			}
			else if (isInherited) {
				// Elements defined in cubes inheriting other definitions could have conflicting
				// fact numbers due to changes in a supercube. To be safe these will all be reset.
				missing.relationships.push(r);
			}
		}
		else {
			// DTB959 - Multiple compiles without a build can mean the element is marked modified
			// and has a factNumber assigned. Only assign to the missing index if there is no
			// factNumber.
			if (cube.relationships[r].factNumber) {
				// The model does have a number assigned
				definedFactNums.push(cube.relationships[r].factNumber);
			}
			else {
				missing.relationships.push(r);
			}
		}
		
		if ((cube.relationships[r].factNumber) && (currSource)) {
			// Remember which source is used to produce this value
			sourceIndex.relationships[currSource] = cube.relationships[r].factNumber;
		}
	}

	// Examine current model dimensions and levels
	var dName = '';
	var hName = '';
	var lName = '';
	var spec = '';
	var currSourceMap = new Map();
	for (d in cube.dimensions) {
		dName = '[' + cube.dimensions[d].name + ']';
		var dimension = cube.dimensions[d];
		
		for (h in dimension.hierarchies) {
			hName = '[' + dimension.hierarchies[h].name + ']';
			
			for (l in dimension.hierarchies[h].levels) {
				var level = dimension.hierarchies[h].levels[l];
				lName = '[' + level.name + ']';
				spec = dName + '.' + hName + '.' + lName;
				
				currSource = zenPage.getLevelSourceForIndex(dimension,level);		// DTB937
				// DP-405883				
				if( ( ('iKnow' === dimension.type) || ('computed' === dimension.type) )){
					currSource = d.toString()+'.'+h.toString()+'.'+l.toString();
					if(currSourceMap.has(currSource)){
						currSource = currSource + '_' + currSourceMap.get(currSource);
						currSourceMap.set(currSource, currSourceMap.get(currSource)+1);
					}
					else{
						currSourceMap.set(currSource,2);
					}
				}
				if (!level.isModified) {
					// If the level is not marked modified, check the actual factNumber setting
					if (level.factNumber) {
						// The model does have a number assigned
						definedFactNums.push(level.factNumber);
					}
					else if (compiledFactNums.dimensions[spec.toUpperCase()]) {
						// This should be the initial assignment case following upgrade.
						// The model doesn't declare the fact number but there is an assigned number in
						// the metadata. Preserve this number.
						currFactNo = compiledFactNums.dimensions[spec.toUpperCase()];
						level.factNumber = parseInt(currFactNo);
						definedFactNums.push(level.factNumber);
					}
					else if (isInherited) {
						// Elements defined in cubes inheriting other definitions could have conflicting
						// fact numbers due to changes in a supercube. To be safe these will all be reset.
						missing.dimensions.push([d,h,l]);
					}
				}
				else {
					// DTB959 - Multiple compiles without a build can mean the element is marked modified
					// and has a factNumber assigned. Only assign to the missing index if there is no
					// factNumber.
					if (level.factNumber) {
						// The model does have a number assigned
						definedFactNums.push(level.factNumber);
					}
					else {
						missing.dimensions.push([d,h,l]);
					}
				}
				
				if ((level.factNumber) && (currSource)) {
					// Remember which source is used to produce this value
					sourceIndex.dimensions[currSource] = level.factNumber;
				}
			}
		}
	}
}

/// Set or Clear all isModified flags in the cube definition according to <var>value</var>.
ClientMethod setFactsModified(value) [ Language = javascript ]
{
	// Method added by DTB911
	var cube = zenPage.getCubeObject();
	
	if (cube.namedFactNums) {
		// Collect the named facts that are already present and note locations of any that are missing.
		// There should be no conflicts since that would have failed any previous compile.
		for (m in cube.measures) {
			cube.measures[m].isModified = value;
		}

		for (r in cube.relationships) {
			cube.relationships[r].isModified = value;
		}

		for (d in cube.dimensions) {
			for (h in cube.dimensions[d].hierarchies) {
				for (l in cube.dimensions[d].hierarchies[h].levels) {
					cube.dimensions[d].hierarchies[h].levels[l].isModified = value;
				}
			}
		}
	}
}

/// Fetch the list of dimensions, measures, and relationships that are known to have been modified 
/// since the last build.
ClientMethod getModifiedFactList(specList) [ Language = javascript ]
{
	// Method added by DTB911
	var cube = zenPage.getCubeObject();
	if (!specList) {
		var specList = {};		// DTB911 - Initialize the specList
	}
	
	if (cube.namedFactNums) {
		// Create arrays to hold the reference locations of the items that need fact numbers set
		var definedFactNums = [1];		// The fact number "1" is always going to go to the %SEARCH virtual dimension
		var changedFactIndex = {"dimensions":[],"measures":[],"relationships":[]};
		
		// Collect the named facts that are already present and note locations of any that are missing.
		// There should be no conflicts since that would have failed any previous compile.
		var mName = '';
		specList.measures = [];
		for (m in cube.measures) {
			mName = cube.measures[m].name;
			if (cube.measures[m].isModified) {
				specList.measures.push('[MEASURES].[' + mName + ']');
				changedFactIndex.measures.push(m);
			}
		}

		var rName = '';
		specList.relationships = [];
		for (r in cube.relationships) {
			rName = cube.relationships[r].name;
			if (cube.relationships[r].isModified) {
				specList.relationships.push('[' + rName + ']');
				changedFactIndex.relationships.push(m);
			}
		}

		var dName = '';
		var hName = '';
		var lName = '';
		var level = {};
		specList.dimensions = [];
		for (d in cube.dimensions) {
			dName = '[' + cube.dimensions[d].name + ']';
			for (h in cube.dimensions[d].hierarchies) {
				hName = '[' + cube.dimensions[d].hierarchies[h].name + ']';
				for (l in cube.dimensions[d].hierarchies[h].levels) {
					level = cube.dimensions[d].hierarchies[h].levels[l];
					lName = '[' + level.name + ']';
					
					if (level.isModified) {
						specList.dimensions.push(dName + '.' + hName + '.' + lName);
						changedFactIndex.dimensions.push([d,h,l]);
					}
				}
			}
		}
	}
	
	return changedFactIndex;
}

/// Given the objects representing a <var>dimension</var> and a <var>level</var>, produce
/// a string that can be used as an identifier in the sourceIndex when determining shared storage
/// for fact table columns.
ClientMethod getLevelSourceForIndex(dimension, level) [ Language = javascript ]
{
	// Method added by DTB937
	// DTB961 - Protect all lookups from returning an undefined to better normalize the index
	if ('time'==dimension.type) {
		currSource = (dimension.sourceProperty ? dimension.sourceProperty : dimension.sourceExpression)
					+ ':'
					+ (level.timeFunction ? level.timeFunction : '')
					+ ':' 
					+ (level.timeOffset ? level.timeOffset : '');
	}
	else if ('age'==dimension.type) {
		currSource = (dimension.sourceProperty ? dimension.sourceProperty : dimension.sourceExpression) 
					+ ':'
					+ (level.timeFunction ? level.timeFunction : '');
	}
	else {
		currSource = (level.sourceProperty ? level.sourceProperty : level.sourceExpression) 
					+ ':'
					+ (level.rangeExpression ? level.rangeExpression : '');	
	}
	
	return currSource;
}

/// Return an index of the currently used fact numbers in the compiled metadata. This index is returned as a JSON object which takes the form:<br>
/// <example language=cos>
/// Set tCompiledFactNums = {
/// 		"measures":{
/// 		  "[MEASURES].[NAME]":"M1"
/// 		},
/// 		"dimensions":{
/// 		  "[DIM].[HIER].[LEVEL]":"2"		
/// 		},
/// 		"relationships":{
/// 		  "[RELNAME]":"3"
/// 		}
/// 	}
/// </example>
ClassMethod GetCompiledFactNumbers(pCubeName) As %String [ ZenMethod ]
{
	// Method added by DTB918
	Set tCompiledFactNums = {
		"measures":{},
		"dimensions":{},
		"relationships":{}
		}
	
	Try {
		Set tSC = ##class(%DeepSee.Utils).%GetDimensionList(pCubeName,.tFullList,,,1,1)		// DP-434926 - Use the showAll to fetch every indexed item
		If $$$ISERR(tSC) Quit
		// Walk straight through the triple-subscript array since it will have everything in the same order as in the cube definition
		Set d = $O(tFullList(""))
		While (d'="") {
			Set h = $O(tFullList(d,""))
			While (h'="") {
				Set l = $O(tFullList(d,h,""),1,tFactInfo)
				While (l'="") {
					Set tTypeCode = $LG(tFactInfo,1)
					Set tSpec = ""
					Set tFactNo = $LG(tFactInfo,5)
					
					If (tFactNo'="") {
						If (tTypeCode="m") {
							Set tType = "measures"
							Set tSpec = "[" _ $LG(tFactInfo,2) _ "].[" _ $LG(tFactInfo,3) _ "]"
						}
						ElseIf (tTypeCode="l") {
							Set tType = "dimensions"
							Set tSpec = "[" _ $LG(tFactInfo,2) _ "].[" _ $LG(tFactInfo,3) _ "].[" _ $LG(tFactInfo,4) _ "]"
						}
						ElseIf (tTypeCode="r") {
							Set tType = "relationships"
							Set tSpec = "[" _ $LG(tFactInfo,2) _ "]"
						}
						Else {
							// If this cannot assign a filing position, skip to the next level
							Continue
						}

						Do tCompiledFactNums.%Get(tType).%Set($$$UPPER(tSpec),tFactNo)
					}
					
					Set l = $O(tFullList(d,h,l),1,tFactInfo)
				}
				
				Set h = $O(tFullList(d,h))
			}
			
			Set d = $O(tFullList(d))
		}
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}

	Quit tCompiledFactNums.%ToJSON()
}

}
