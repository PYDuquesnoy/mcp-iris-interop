/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// DeepSee SubjectArea Architect page.
/// This is a special version of the Architect for operating on Subject Areas.
Class %DeepSee.UI.ArchitectSA Extends (%DeepSee.UI.standardPage, %CSP.Portal.SourceControl.Base) [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Architect Subject Area";

Parameter DOCBOOKID = "D2MODEL_intro_architect";

/// If this page has multiple views, this is its initial display mode.
Parameter DEFAULTVIEWMODE = "cube";

/// Name of SubjectArea (with extension).
Property subjectAreaFullName As %ZEN.Datatype.string(ZENURL = "CUBE");

/// Name of SubjectArea being viewed.
Property subjectAreaName As %ZEN.Datatype.string;

/// Class name of SubjectArea being viewed.
/// This is determined from the SubjectArea name.
Property subjectAreaClass As %ZEN.Datatype.string;

/// Base cube name for the current subject area.
Property baseCube As %ZEN.Datatype.string;

/// Description of SubjectArea being viewed.
/// This is determined from the subjectArea name.
Property subjectAreaDescription As %ZEN.Datatype.string;

/// Domain of SubjectArea being viewed.
/// This is handled seperately from json.
Property subjectAreaDomain As %ZEN.Datatype.string;

/// DependsOn for subjectArea class. If provided, this is used as the DependsOn value
/// of the generated subjectArea. If not, the base cube for the subjectArea is used.
/// This is handled seperately from json.
Property subjectAreaDependsOn As %ZEN.Datatype.string;

/// Data source. This is a copy of the value in the base cube model.
Property dataSource As %ZEN.Datatype.string;

/// ID (index number, 0-based) of current selected item.
Property currItem As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// Type of the current selected item.
Property currItemType As %ZEN.Datatype.string;

/// Local copy of SubjectArea model object.
Property %model As %DeepSee.Model.SubjectArea.subjectArea;

/// Local copy of BaseCube model object.
Property %basecube As %DeepSee.Model.SubjectArea.subjectArea;

/// If true, user cannot modify the current SubjectArea definition.
Property readOnly As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, user can modify (non-read-only) SubjectArea definitions,
/// otherwise they can only view.
Property canWrite As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property hlpRemove As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Remove this item")} ];

Property hlpShowHide As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Hide or show the properties box")} ];

Property lblMeasure As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("measure")} ];

Property lblDimension As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("dimension")} ];

Property lblHier As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("hierarchy")} ];

Property lblLevel As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("level")} ];

Property lblListing As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("listing")} ];

Property msgInvalid As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("Please click [Open] to select a model definition.")} ];

/// If true, the settings area (property sheet) is visible.
Property settingsExpanded As %Boolean [ InitialExpression = 1, Internal ];

Property DocumaticPage As %String;

/// This Style block contains page-specific CSS 3 style definitions.
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
#tabGeneral,#tabDetails {
	overflow: auto;
	padding-left: 3px;
	color: #404040;
}

.helpCommand {
	text-decoration: none;
	color: white;
	font-size: 10pt;
}

.helpCommand:hover {
	text-decoration: none;
	color: darkred;
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

.tabGroupBody {
	width: 349px;
	min-height: 300px;
	background: rgb(236,236,228);
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

.tabGroupGap {
	width: 0px;
}

#helpPane {
	position: relative;
	background: white;
	height: 449px;
	width: 300px;
	border-right: 1px solid black;
	border-bottom: 1px solid black;
	display: none;
	overflow-x: hidden;
	overflow-y: auto;
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
	color: #FFFFFF;
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
	font-style: italic;
	color: rgb(67,67,67);
}
.modelRowPropertySelected {
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

.helpCommand {
	text-decoration: none;
	color: white;
	font-size: 10pt;
}

.helpCommand:hover {
	text-decoration: none;
	color: darkred;
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

.tabGroupBody {
	width: 349px;
	min-height: 20px;
	background: rgb(236,236,228);
}

td.tabGroupButtonOn {
	height: 40px;
	color: #404040;
	background: rgb(236,236,228);
	font-size: 10pt;
	-moz-border-radius-topleft:0px;
	-moz-border-radius-topright:0px;
}

/* @doc="Individual tab bar button in Off state." */
td.tabGroupButtonOff
{
	height: 40px;
	color: #404040;
	background: #C0C0C0;
	font-size: 10pt;
	background-image: none;
	background-repeat: repeat-x;
	-moz-border-radius-topleft:0px;
	-moz-border-radius-topright:0px;
}

.tabGroupGap {
	width: 0px;
}


#helpPane {
	position: relative;
	background: white;
	height: 449px;
	width: 300px;
	border-right: 1px solid black;
	border-bottom: 1px solid black;
	display: none;
	overflow-x: hidden;
	overflow-y: auto;
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
	font-style: italic;
	color: rgb(67,67,67);
}
.modelRowPropertySelected {
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

<!-- Get SubjectArea in JSON format -->
<jsonProvider id="subjectArea"
	OnGetTargetObject="GetSubjectAreaDefinition"
	OnSubmitContent="SubmitSubjectArea"
/>
<jsonProvider id="baseCube"
	OnGetTargetObject="GetCubeDefinition"
/>
<hgroup id="mainGroup" cellVAlign="top">
<vgroup id="editorPane">
<html id="modelTableHeader" OnDrawContent="DrawTableHeader"></html>
<html id="modelTableBody" ondrop="return zenPage.tableDropHandler(dragData);"></html>
</vgroup>
<vgroup id="propertyPane">
<html id="propertyTitle"><span id="spanArrow" title="#(%page.hlpShowHide)#" onclick="zenPage.toggleSettings();" onmouseover="this.style.color='#FFEEAA';this.style.cursor='pointer';" onmouseout="this.style.color='';this.style.cursor='';">&#187;</span></html>
<tabGroup id="propertyTabs" showTabBar="true">
<tab id="tabDetails" caption="Details" layout="none">
<vgroup>
<spacer height="5"/>
<vgroup id="defaultDetails" label="Select an item to view details"/>
<vgroup id="subDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label controlClass="detailLabel" value="Subject Area"/>
<checkbox id="detailSubDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailSubName" label="Name" size="44" disabled="false"/>
<text id="detailSubDisplayName" label="Display name" size="44" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailSubDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailSubDescription" hidden="true" cols="30" rows="4" onchange="zenPage.applyDescription('detailSubDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailSubDescription');"/>
</hgroup>
<hgroup>
<text id="detailSubCaption" label="Caption" size="20" onchange="zenPage.applyDetails();"/>
<text id="detailSubDomain" label="Domain" size="19" onchange="zenPage.applyDomain(zenThis.getValue());"/>
</hgroup>
<hgroup cellVAlign="bottom">
<text id="detailSubBaseCube" label="Base cube" size="43" onchange="zenPage.applyDetails();"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.browseClass('cubes');"/>
</hgroup>
<text id="detailSubFilterSpec" label="Filter" size="44" onchange="zenPage.applyDetails();"/>
<hgroup cellVAlign="bottom">
<text id="detailSubResource" label="Resource" size="43" onchange="zenPage.applyDetails();"/>
<image id="btndetailCubeResource" src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('SubResource');"/>
</hgroup>

<select id="detailSubDefaultListing" label="Default listing" onchange="zenPage.applyDetails();"/>

<hgroup hidden="true">
<select id="detailSubDefaultMeasure" label="Default measure" onchange="zenPage.applyDetails();"/>
<text id="detailSubDefaultMember" label="Default member" dropEnabled="true" size="44" onchange="zenPage.applyDetails();"/>
</hgroup>
<hgroup>
<text id="detailSubOwner" label="Owner" size="19" onchange="zenPage.applyDetails();"/>
<text id="detailSubCountMeasureCaption" label="Count measure caption" dropEnabled="true" size="19" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailSubClass" label="Class name" size="44" disabled="true" value="#(%page.subjectAreaClass)#"/>
<text id="detailSubDependsOn" label="Depends On" hint="Option list of classes that this subject area depends on" size="44" onchange="zenPage.applyDependsOn(zenThis.getValue());"/>
</vgroup>
<!-- End of Subject Area Details -->

<vgroup id="measureDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label controlClass="detailLabel" value="Measure"/>
<!-- <checkbox id="detailMeasureDisabled" label="Disabled" onchange="zenPage.applyDetails();"/> -->
<checkbox id="detailMeasureHidden" label="Hidden" onchange="zenPage.applyDetails();"/>
<!-- <checkbox id="detailMeasureSearchable" label="Searchable" onchange="zenPage.applyDetails();"/> -->
</hgroup>
<text id="detailMeasureName" label="Name" size="44" disabled="true"/>
<text id="detailMeasureDisplayName" label="Display name" size="44" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailMeasureDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailMeasureDescription" hidden="true" cols="33" rows="4" onchange="zenPage.applyDescription('detailMeasureDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailMeasureDescription');"/>
</hgroup>
<hgroup cellVAlign="bottom" cellStyle="padding-right:4px;">
<text id="detailMeasureFormatString" label="Format string" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
<image id="btndetailMeasureFormatString" src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('FormatString');"/>
</hgroup>
</vgroup>
<!-- End of Measure Details -->

<vgroup id="dimensionDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label controlClass="detailLabel" value="Dimension"/>
<checkbox id="detailDimensionHidden" label="Hidden" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailDimensionName" label="Name" size="44" disabled="true"/>
<text id="detailDimensionDisplayName" label="Display name" size="44" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailDimensionDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailDimensionDescription" hidden="true" cols="33" rows="4" onchange="zenPage.applyDescription('detailDimensionDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailDimensionDescription');"/>
</hgroup>
<vgroup id="idAllLevel" cellStyle="padding:4px;" label="All Level" labelClass="detailLabel">
<text id="detailDimensionAllCaption" label="Caption for All member" size="44" onchange="zenPage.applyDetails();"/>
<text id="detailDimensionAllDisplayName" label="Display name for All member" size="44" dropEnabled="true" onchange="zenPage.applyDetails();"/>
</vgroup>

</vgroup>
<!-- End of Dimension Details -->

<vgroup id="hierarchyDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label controlClass="detailLabel" value="Hierarchy"/>
<checkbox id="detailHierarchyHidden" label="Hidden" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailHierarchyName" label="Name" size="44" disabled="true"/>
<text id="detailHierarchyDisplayName" label="Display name" size="20" onchange="zenPage.applyDetails();"/>
<textarea id="detailHierarchyDescription" label="Description" cols="33" rows="4" onchange="zenPage.applyDetails();"/>
</vgroup>
<!-- End of Hierarchy Details -->


<vgroup id="levelDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label id="lblLevel" controlClass="detailLabel" value="Data Level"/>
<checkbox id="detailLevelHidden" label="Hidden" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailLevelName" label="Name" size="44" disabled="true"/>
<text id="detailLevelDisplayName" label="Display name" size="44" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailLevelDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailLevelDescription" hidden="true" cols="33" rows="2" onchange="zenPage.applyDescription('detailLevelDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailLevelDescription');"/>
</hgroup>
<hgroup cellStyle="padding-right:4px;">
<!-- if left empty, it means "don't change the sorting" -->
<select id="detailLevelSort" label="Sort option" valueList="asc,desc" showEmpty="true" onchange="zenPage.applyDetails();"/>
</hgroup>

</vgroup>
<!-- End of Level Details -->

<vgroup id="listingDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<label controlClass="detailLabel" value="Listing"/>
<checkbox id="detailListingHidden" label="Hidden" onchange="zenPage.applyDetails();"/>
</hgroup>
<text id="detailListingName" label="Name" size="44" disabled="true"/>
<text id="detailListingDisplayName" label="Display name" size="44" onchange="zenPage.applyDetails();"/>
<hgroup label="Description" cellVAlign="top">
<text id="detailListingDescription" size="44" onchange="zenPage.applyDetails();"/>
<textarea id="areadetailListingDescription" hidden="true" cols="33" rows="4" onchange="zenPage.applyDescription('detailListingDescription');"/>
<image src="deepsee/ds2_page_44.png" width="16" height="16" onclick="zenPage.editDescription('detailListingDescription');"/>
</hgroup>
<hgroup>
<select id="detailListingSelectMode" label="SQL Select Mode" valueList="0,1,2" displayList="Logical,ODBC,Display" showEmpty="false" onchange="zenPage.applyDetails();"/>
</hgroup>
<hgroup id="idListingFieldList" cellVAlign="top">
<textarea id="areadetailListingFieldList" label="Field list" cols="33" rows="6" onchange="zenPage.applyDetails();"/>
<vgroup>
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('ListingFieldList');"/>
</vgroup>
</hgroup>
<hgroup id="idListingOrderBy" cellVAlign="top">
<textarea id="areadetailListingOrderBy" label="Order by" cols="33" rows="2" onchange="zenPage.applyDetails();"/>
<vgroup>
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('ListingOrderBy');"/>
</vgroup>
</hgroup>
<select id="detailListingSourceClass" label="Data connector" valueList="" onchange="zenPage.applyDetails();"/>
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<checkbox id="detailListingUseSQL" label="Custom SQL query" onchange="zenPage.changeUseSQL();"/>
</hgroup>
<hgroup id="idListingSQL" cellVAlign="top" hidden="true">
<textarea id="areadetailListingSQL" label="SQL Query" cols="33" rows="6" onchange="zenPage.applyDetails();"/>
<vgroup>
<image src="/csp/broker/images/spacer.gif" width="16" height="16"/>
<image src="deepsee/ds2_magnify_44.png" width="16" height="16" onclick="zenPage.editItem('ListingSQL');"/>
</vgroup>
</hgroup>
</vgroup>
<!-- End of Listing Details -->
</vgroup>
</tab>
<tab caption="Tools" id="tabTools" labelPosition="left" title="Various tools for working with DeepSee data models">
<vgroup cellStyle="padding-left:3px;">
<label label="Various tools for working with DeepSee data models"/>

<hgroup cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/comparison_chart_48.gif"/>
<vgroup>
<button caption="Analyzer" controlClass="commandButton" title="Use the Analyzer to view this subject area." onclick="zenPage.toolAnalyzer();"/>
<label label="Use the Analyzer to view this subject area."/>
</vgroup>
</hgroup>

<hgroup cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/sql_query_48.gif"/>
<vgroup>
<button caption="Query Tool" controlClass="commandButton" title="Use the Query Tool to run queries against this subject area." onclick="zenPage.toolQuery();"/>
<label label="Use the Query Tool to run queries against this subject area."/>
</vgroup>
</hgroup>

</vgroup>
</tab>
</tabGroup>
</vgroup>
<vgroup id="helpPane">
<html><div style="font-size:40pt;">Help</div></html>
</vgroup>
</hgroup>
</pane>
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	If (..subjectAreaName="") {
		Quit ..%OnGetPageName()
	}
	Quit ..subjectAreaName
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Architect","%DeepSee")
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
	Set pRibbonTitle = $$$Text("Architect")

	//Set pViewIcons(1) = $LB("cubes",$$$Text("Show related cubes"),"portal/view_cubes.png")
	Set pViewIcons(2) = $LB("cube",$$$Text("Show subject area definition"),"portal/view_cube.png")
	//Set pViewIcons(3) = $LB("table",$$$Text("Show fact table definition"),"portal/view_facts.png")

	// commands
	// $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("cmdNew",$$$Text("New"),$$$Text("Create a new subject area"),"zenPage.newSubjectArea();")
	Set pCommands(2) = $LB("cmdNew",$$$Text("Open"),$$$Text("Open a subject area"),"zenPage.changeSubjectArea();")
	Set pCommands(3) = $LB("cmdSave",$$$Text("Save"),$$$Text("Save this subject area"),"zenPage.save();")
	Set pCommands(4) = $LB("cmdCompile",$$$Text("Compile"),$$$Text("Compile this subject area"),"zenPage.compile();")
	Set pCommands(5) = $LB("cmdView",$$$Text("Documentation"),$$$Text("Open Documatic for this model"),"zenPage.doDocument();")

	Quit $$$OK
}

/// Draw the contents of the Table Header (the region between the diagram and the table).
Method DrawTableHeader(pSeed As %String) As %Status
{
	Set msgAdd = $$$Text("Add Element")
	Set hlpAdd = $$$Text("Add an element to this subject area")

	Set msgUndo = $$$Text("Undo")
	Set hlpUndo = $$$Text("Undo the last change to this subject area")

	Set msgView = $$$Text("View")
	Set hlpView = $$$Text("View subject area details")
	
	&html<<div style="position:absolute;top:16px;left:20px;font-weight:bold;color:#404040;">#($$$Text("Model Element Overrides"))#
	&nbsp;<a class="hdrLink" href="#" title="#(hlpAdd)#" onclick="zenPage.addItem();return false;">#(msgAdd)#</a>
	&nbsp;&nbsp;&nbsp;<a id="cmdUndo" class="hdrLinkDisabled" disabled="true" href="#" title="#(hlpUndo)#" onclick="zenPage.undo();return false;">#(msgUndo)#</a>
	</div>>
	//	&nbsp;&nbsp;&nbsp;<a id="cmdView" class="hdrLink" disabled="false" href="#" title="#(hlpView)#" onclick="zenPage.viewSub();return false;">#(msgView)#</a>

	&html<</div>>
	Quit $$$OK
}

/// Return the internal name of the current document, including the three letter
/// extension in upper-case. For example, MyPackage.MyClass.CLS would be the internal name
/// for the class MyPackage.MyClass.
Method GetInternalName() As %String
{
	Quit ..subjectAreaClass_".CLS"
}

/// Return the current name of the class/object being modified.
ClientMethod getCurrentName() [ Language = javascript ]
{
	return this.subjectAreaClass
}

/// Get the jsonProvider object on the client.
ClientMethod getClientModel() [ Language = javascript ]
{
	return zen('subjectArea');
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

/// Draw additional stuff in the ribbon bar
Method OnDrawRibbon() As %Status
{
	If %page.subjectAreaName '= "" Quit ..%DrawSourceControlCommands()
	Quit 1
}

/// Launch the subjectArea finder dialog.
ClientMethod changeSubjectArea() [ Language = javascript ]
{
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.cls?MODE=modelsSA','SubjectArea','status,scrollbars,resizable=yes,width=800,height=600');
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

/// Add check to ensure that we correctly load documents on the client when source control hooks are in use.
/// Also set up a timer to ensure we don't hit timeouts while editing documents in Studio, as well as
/// When in Studio mode, also detect whether we are running IE10, as we need to save documents differently if that
/// is the case.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.initializeSourceControl();
	if (!this.canWrite || this.readOnly) {
		this.disableCommandButton("cmdSave");
		this.disableCommandButton("cmdCompile");
	}
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
			//this.selectItem('subjectArea',0);
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

		editDiv.style.width = editorWid + 'px';
		editDiv.style.height = editorHgt + 'px';
		tableHdrDiv.style.width = editorWid + 'px';
		tableBodyDiv.style.width = editorWid + 'px';
		tableBodyDiv.style.height = editorHgt - tableHdrDiv.offsetHeight + 'px';

		propDiv.style.height = hgt + 'px';

		if (this.settingsExpanded) {
			var tabBodyHgt = (hgt - proptitleDiv.offsetHeight - 30);
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
}

/// Return the cube definition object.
ClientMethod getCubeObject() [ Language = javascript ]
{
	var json = this.getComponentById('baseCube');
	var cube = json.getContentObject();
	return cube;
}

/// Update the contents of the model table.
ClientMethod renderTable() [ Language = javascript ]
{
	var table = zen('modelTableBody');
	var html = new Array();
	var subjectArea = this.getSubjectAreaObject();
	var source,type;
	if (this.baseCube == "") this.baseCube = subjectArea.baseCube;
	var baseCube = this.getCubeObject();	

	// maps row number in the table back to an item in the model
	this._rowIndex = new Array();
	
	// n.b., we add a _parent and _index decoration to each element in the tree as we render

	if (null == subjectArea) {
		html[html.length] = '<div class="modelError">' + this.msgInvalid + '</div>';
	}
	else {
		// we also add an array to track if disclosures are open or closed
		if (null == subjectArea._contracted) {
			subjectArea._contracted = new Object();
		}

		// create table displaying subjectArea model.
		html[html.length] = '<table class="modelTable" border="0" cellspacing="0">';
		var indentDim = '<img height="1px" width="16px" src="images/spacer.gif"/>';
		var indentMea = '<img height="1px" width="32px" src="images/spacer.gif"/>';
		var indentHier = '<img height="1px" width="48px" src="images/spacer.gif"/>';
		var indentLevel = '<img height="1px" width="60px" src="images/spacer.gif"/>';
		var indentProperty = '<img height="1px" width="72px" src="images/spacer.gif"/>';
		var disc = '';
		var remove = '';
		var style = '';

		// subjectArea
		//source = subjectArea.sourceClass;
		type = $$$Text("Subject Area");
		this._rowIndex[this._rowIndex.length] = subjectArea;
		
		html[html.length] = '<tr class="modelRowCube" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'subjectArea\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + zenEscapeXML(subjectArea.name) + '</td>';
		html[html.length] = '<td>' + $$$Text("Element Type") + '&nbsp;</td>';
		html[html.length] = '<td>' + $$$Text("Hidden?") + '&nbsp;</td>';
		html[html.length] = '<td>' + $$$Text("Details") + '</td>';
		html[html.length] = '<td>' + remove + '&nbsp;</td>';
		html[html.length] = '</tr>';

		// measures
		type = '';
		this._rowIndex[this._rowIndex.length] = 'measures';
		var closed = subjectArea._contracted['measures'];
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure(\'measures\');"/>';

		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'measures\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + disc + $$$Text('Measures') + '</td>';
		html[html.length] = '<td>' + type + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;' + '</td>';
		html[html.length] = '<td>' + '&nbsp;' + '</td>';
		html[html.length] = '<td>' + remove + '&nbsp;</td>';
		html[html.length] = '</tr>';
		
		var lblHidden = $$$Text("hidden");
		var blen,ishidden;
		if (!closed) {
			for (var m = 0; m < subjectArea.measures.length; m++) {
				var msr = subjectArea.measures[m];
				msr._parent = subjectArea;
				msr._index = m;
				this._rowIndex[this._rowIndex.length] = msr;

				//find the measure properties that have different values than baseCube
				diffString = this.diffMeasures(msr,baseCube.measures);
				ishidden = ('1' == msr.hidden) ? lblHidden : '';
				
				remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'measure\','+(this._rowIndex.length-1)+','+m+');" />';
				style = msr.disabled ? 'style="background:#C0C0C0;"' : '';
				html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'measure\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
				html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
				html[html.length] = '<td>' + indentMea + zenEscapeXML(msr.name) + '</td>';
				html[html.length] = '<td>' + this.lblMeasure + '&nbsp;</td>';
				html[html.length] = '<td>' + ishidden + '&nbsp;</td>';
				html[html.length] = '<td>' + zenEscapeXML(diffString) + '&nbsp;</td>';
				html[html.length] = '<td>' + remove + '&nbsp;</td>';
				html[html.length] = '</tr>';
			}
		}
		// End of Measures
		// Dimensions:
		this._rowIndex[this._rowIndex.length] = 'dimensions';
		var closed = subjectArea._contracted['dimensions'];
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure(\'dimensions\');"/>';

		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'dimensions\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + disc + $$$Text('Dimensions') + '</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '</tr>';
			
		if (!closed) {
	
		for (var d = 0; d < subjectArea.dimensions.length; d++) {
			var dim = subjectArea.dimensions[d];
			dim._parent = subjectArea;
			dim._index = d;
			this._rowIndex[this._rowIndex.length] = dim;

			var closed = subjectArea._contracted['dim'+d];
			disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure(\'dim'+d+'\');"/>';
		
			diffString = this.diffDimensions(dim,baseCube.dimensions);
			ishidden = ('1' == dim.hidden) ? lblHidden : '';

			remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'dimension\','+(this._rowIndex.length-1)+','+d+');" />';
			style = dim.disabled ? 'style="background:#C0C0C0;"' : '';

			html[html.length] = '<tr class="modelRowDimension" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'dimension\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
			html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
			html[html.length] = '<td>' + indentDim + disc + zenEscapeXML(dim.name) + '</td>';
			html[html.length] = '<td>' + this.lblDimension + '&nbsp;</td>';
			html[html.length] = '<td>' + ishidden + '&nbsp;</td>';
			html[html.length] = '<td>' + zenEscapeXML(diffString) + '&nbsp;</td>';
			html[html.length] = '<td>' + remove + '&nbsp;</td>';
			html[html.length] = '</tr>';

			if (!closed) {
				for (var h = 0; h < dim.hierarchies.length; h++) {
					var hier = dim.hierarchies[h];
					hier._parent = dim;
					hier._index = h;
					this._rowIndex[this._rowIndex.length] = hier;

					diffString = this.diffHierarchies(hier,baseCube.dimensions);
					ishidden = ('1' == hier.hidden) ? lblHidden : '';

					remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'hierarchy\','+(this._rowIndex.length-1)+','+d+','+h+');" />';
					style = (dim.disabled||hier.disabled) ? 'style="background:#C0C0C0;"' : '';

					html[html.length] = '<tr class="modelRowHierarchy" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'hierarchy\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
					html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
					html[html.length] = '<td>' + indentHier + zenEscapeXML(hier.name) + '</td>';
					html[html.length] = '<td>' + this.lblHier + '&nbsp;</td>';
					html[html.length] = '<td>' + ishidden + '&nbsp;</td>';
					html[html.length] = '<td>' + zenEscapeXML(diffString) + '&nbsp;</td>';
					html[html.length] = '<td>' + remove + '&nbsp;</td>';
					html[html.length] = '</tr>';
					var hierLen = hier.levels.length;
					for (var l = 0; l < hierLen; l++) {
						var level = hier.levels[l];
						level._dimtype = dim.type;
						level._parent = hier;
						level._index = l;
						this._rowIndex[this._rowIndex.length] = level;
						
						diffString = this.diffLevels(level,baseCube.dimensions);
						ishidden = ('1' == level.hidden) ? lblHidden : '';

						remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'level\','+(this._rowIndex.length-1)+','+d+','+h+','+l+');" />';
						style = (dim.disabled||hier.disabled||level.disabled) ? 'style="background:#C0C0C0;"' : '';
						type = (level.sort != "") ? level.sort : "asc";
						html[html.length] = '<tr class="modelRowLevel" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'level\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
						html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
						html[html.length] = '<td>' + indentLevel + zenEscapeXML(level.name) + '</td>';
						html[html.length] = '<td>' + this.lblLevel + '&nbsp;</td>';
						html[html.length] = '<td>' + ishidden + '&nbsp;</td>';
						html[html.length] = '<td>' + zenEscapeXML(diffString) + '&nbsp;</td>';
						html[html.length] = '<td>' + remove + '&nbsp;</td>';
						html[html.length] = '</tr>';

						// levels have no properties in subjectArea
					}
				}
			}
		}
	  }
	  	// listings
		this._rowIndex[this._rowIndex.length] = 'listings';
		var closed = subjectArea._contracted['listings'];
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure(\'listings\');"/>';
		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'listings\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + disc + $$$Text('Listings') + '</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '</tr>';	
		if (!closed) {
			for (var d = 0; d < subjectArea.listings.length; d++) {
				var list = subjectArea.listings[d];
				list._parent = subjectArea;
				list._index = d;
				this._rowIndex[this._rowIndex.length] = list;
				ishidden = ('1' == list.hidden) ? lblHidden : '';					
				remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'listing\','+(this._rowIndex.length-1)+','+d+');" />';
				// show sql if it's defined. ow show fieldList.
				var fieldList = (list.sql != "") ? list.sql : list.fieldList;
				if (fieldList.length > 40) fieldList = fieldList.substring(0,40) + "...";
				if (fieldList != "") fieldList = $$$Text("Field list: ") + fieldList;
				style = (list.disabled) ? 'style="background:#C0C0C0;"' : '';
				html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'listing\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
				html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
				html[html.length] = '<td>' + indentMea + zenEscapeXML(list.name) + '</td>';
				html[html.length] = '<td>' + this.lblListing + '&nbsp;</td>';
				html[html.length] = '<td>' + ishidden + '&nbsp;</td>';
				html[html.length] = '<td>' + zenEscapeXML(fieldList) + '&nbsp;</td>';
				html[html.length] = '<td>' + remove + '&nbsp;</td>';
				html[html.length] = '</tr>';
			}
		}

		html[html.length] = '</table>'; 
	}
	table.setContent(html.join(''));
}

/// Check overrides for Measure
ClientMethod diffMeasures(itemObj, baseObj) [ Language = javascript ]
{
	var diffString = "";			
	var blen = baseObj.length;
	for (var b = 0; b < blen; b++) {
		if (baseObj[b].name == itemObj.name) {
			// go through each properties and compare value
			var base = baseObj[b];
			if (itemObj.description != base.description) diffString = "Description";
			if (itemObj.displayName != base.displayName) diffString = this.updateDiff(diffString,"Display name");
			if (itemObj.formatString != base.formatString) diffString = this.updateDiff(diffString,"Format string")+"("+itemObj.formatString+")";
			break;
		}	
	}
	return this.maxDiff(diffString);
}

/// Check overrides for Dimension
ClientMethod diffDimensions(itemObj, baseObj) [ Language = javascript ]
{
	var diffString = "";			
	var blen = baseObj.length;
	for (var b = 0; b < blen; b++) {
		if (baseObj[b].name == itemObj.name) {
			// go through each properties and compare value
			var base = baseObj[b];
			if (itemObj.description != base.description) diffString = "Description";
			if (itemObj.displayName != base.displayName) diffString = this.updateDiff(diffString,"Display name");
			//only show all members only if base's hasAll is true
			if (base.hasAll) {
				if (itemObj.allCaption != base.allCaption) diffString = this.updateDiff(diffString,"All member name");
				if (itemObj.allDisplayName != base.allDisplayName) diffString = this.updateDiff(diffString,"All member display name");
			}

			break;
		}	
	}
	return this.maxDiff(diffString);
}

/// Check overrides for Hierarchies
ClientMethod diffHierarchies(itemObj, baseObj) [ Language = javascript ]
{
	var diffString = "";
	var found = 0;
	var blen = baseObj.length;
	for (var b = 0; b < blen; b++) {
		var hlen = baseObj[b].hierarchies.length;
		for (var h = 0; h < hlen; h++) {
			if (baseObj[b].hierarchies[h].name == itemObj.name) {
				// go through each properties and compare value
				var base = baseObj[b].hierarchies[h];
				if (itemObj.description != base.description) diffString = "Description";
				if (itemObj.displayName != base.displayName) diffString = this.updateDiff(diffString,"Display name");
				found = 1;
				break;
			}
		}
		if (found) break;
	}
	return this.maxDiff(diffString);
}

/// Check overrides for Levels
ClientMethod diffLevels(itemObj, baseObj) [ Language = javascript ]
{
	var diffString = "";
	var found = 0;
	var blen = baseObj.length;
	for (var b = 0; b < blen; b++) {
		var hlen = baseObj[b].hierarchies.length;
		for (var h = 0; h < hlen; h++) {
			var llen = baseObj[b].hierarchies[h].levels.length;
			for (var l = 0; l < llen; l++) {
				if (baseObj[b].hierarchies[h].levels[l].name == itemObj.name) {
					// go through each properties and compare value
					var base = baseObj[b].hierarchies[h].levels[l];
					if (itemObj.description != base.description) diffString = "Description";
					if (itemObj.displayName != base.displayName) diffString = this.updateDiff(diffString,"Display name");
					if (itemObj.sort != base.sort) diffString = this.updateDiff(diffString,"Sort")+" ("+itemObj.sort+")";
					found = 1;
					break;
				}
			}
			if (found) break;
		}
		if (found) break;
	}
	return this.maxDiff(diffString);
}

ClientMethod updateDiff(diffString, propName) [ Language = javascript ]
{
	if (diffString.length > 0) diffString = diffString + ", ";
	diffString = diffString + propName;
	return diffString;
}

ClientMethod maxDiff(diffString) [ Language = javascript ]
{
	if (diffString.length > 0) diffString = $$$Text("Overrides: ") + diffString;
	if (diffString.length > 40) diffString = diffString.substring(0,40) + "...";
	return diffString;
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

		// check privileges
		Do CheckArchitectUseAccess^%qdsUtils()
		$$$dsTrackFeature("Architect")		// DTB393

		Set tWrite = $$CheckArchitectWriteAccess^%qdsUtils()
		If ('tWrite) {
			Set ..canWrite = 0
		}
		Set ..readOnly = 0

		If (..subjectAreaFullName="") {
			Set ..subjectAreaFullName = $G(^DeepSee.LastCube($UserName))
		}

		// Strip off extension from name
		Set tExt = $P(..subjectAreaFullName,".",$L(..subjectAreaFullName,"."))
		If ((tExt = "cube")||(tExt = "subjectArea")) {
			Set tName = $P(..subjectAreaFullName,".",1,$L(..subjectAreaFullName,".")-1)
			Set ..subjectAreaName = tName
		}
		Else {
			Set tExt = "subjectArea"
			Set ..subjectAreaName = ..subjectAreaFullName
		}

		If (tExt = "cube") {
			// show other architect
			Set %response.Redirect = "_DeepSee.UI.Architect.zen?CUBE="_$ZCVT(..subjectAreaFullName,"O","URL")
			Quit
		}

		If ('##class(%DeepSee.Utils).%CubeExists(..subjectAreaName, .tSC)) {
			Set ..subjectAreaName = ""
			Set ..%model = ""
			Quit
		}

		Set ^DeepSee.LastCube($UserName) = ..subjectAreaName _ ".subjectArea"
		If ($G(%request.Data("home",1))'="") {
			Set %response.Context("home") = %request.Data("home",1)
		}

		// get class name for subject area (cube API works for this)
		Set ..subjectAreaClass = ##class(%DeepSee.Utils).%GetCubeClass(..subjectAreaName)
		Set ..subjectAreaDescription = ##class(%DeepSee.Utils).%GetCubeDescription(..subjectAreaName)

		// JMD934
		Set tDependsOn = $$$comClassKeyGet(..subjectAreaClass,$$$cCLASSdependson)
		Set ..subjectAreaDependsOn = tDependsOn
		Set ..%GetComponentById("detailSubDependsOn").value = ..subjectAreaDependsOn

		Set ..%model = ##class(%DeepSee.Utils).%GetSubjectAreaModel(..subjectAreaName, .tSC)
		If $IsObject(..%model) {
			Set ..subjectAreaName = ..%model.name // Get actual name
			Set ..baseCube = ..%model.baseCube
			Set tcube = ##class(%DeepSee.Utils).%GetModel($P(..baseCube,",",1), .tSC)
			If $IsObject(tcube) {
				Set ..dataSource = tcube.sourceClass
			}

			// test for write access
			If ((..%model.resource'="")&&'$System.Security.Check(..%model.resource,"WRITE")) {
				Set ..readOnly = 1
			}
		}
		Set ..%GetComponentById("detailListingSourceClass").valueList = ..LoadListingSource()
		Set ..%GetComponentById("detailSubDefaultMeasure").valueList = ..LoadDefaultList(..baseCube,"m")
		Set ..%GetComponentById("detailSubDefaultListing").valueList = ..LoadDefaultList(..baseCube,"l")
		Set ..subjectAreaDomain = $$$comMemberKeyGet(..subjectAreaClass,$$$cCLASSparameter,"DOMAIN",$$$cPARAMdefault)
		Set ..%GetComponentById("detailSubDomain").value = ..subjectAreaDomain
		Set ..DocumaticPage = ..Link("/csp/documatic/%25CSP.Documatic.cls",,1)_"CLASSNAME="_..EscapeURL(..subjectAreaClass)_"&LIBRARY="_..EscapeURL($namespace)_"&BASECUBE="_..EscapeURL(..baseCube)_"&CUBE="_..EscapeURL(..subjectAreaName)
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
	Set tParms("super")="%DeepSee.DataConnector"
	Set tSC = ##class(%ZEN.FinderUtils).%GetClassListArray(.tParms,.pMetaData,.pData)
	Set dc = $O(pData("DEEPSEE.pkg","MODEL.pkg",""))
	While dc '= "" {
		Set item=pData("DEEPSEE.pkg","MODEL.pkg",dc)
		Set tClass = $lg(item,2)
		Set tS = $zobjclassmethod(tClass,"%GetParameter","SUPPORTSIDLIST")
		If tS = 1 Set valueList = valueList _ $S(valueList'="":",",1:"") _ tClass
		Set dc = $O(pData("DEEPSEE.pkg","MODEL.pkg",dc))
	}
	Quit valueList
}

/// Return Measure list or Listing list
Method LoadDefaultList(baseCube, pType) As %String
{
	Set valueList = ""
	Set baseCube = $P(baseCube,",",1)
	If pType = "m" Set tSC = ##class(%DeepSee.Utils).%GetCubeMeasures(baseCube,.tItems,1)
	Else  Set tSC = ##class(%DeepSee.Utils).%GetCubeListings(baseCube,.tItems)
	Set dc = $O(tItems(""))
	While dc '= "" {
		Set valueList = valueList _ $S(valueList'="":",",1:"") _ $lg(tItems(dc),1)
		Set dc = $O(tItems(dc))
	}
	Quit valueList
}

/// Get SubjectArea definition for JSON provider.
Method GetSubjectAreaDefinition(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	If $IsObject(..%model) {
		Set pObject = ..%model
	}
	ElseIf (..subjectAreaName'="") {
		Set pObject = ##class(%DeepSee.Utils).%GetSubjectAreaModel(..subjectAreaName, .tSC)
		If $$$ISOK(tSC) && $IsObject(pObject) {
			If ..IsSourceControlReadOnly(..GetInternalName()) {
				Set pObject.ReadOnly = 2
			}
		}
	}
	Quit tSC
}

/// Get BaseCube definition for JSON provider.
Method GetCubeDefinition(ByRef pParms, Output pBase As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	If $IsObject(..%basecube) {
		Set pBase = ..%basecube
	}
	ElseIf (..baseCube '= "") {
		Set pBase = ##class(%DeepSee.Utils).%GetModel($P(..baseCube,",",1), .tSC)
		Set ..%basecube = pBase
	}
	Quit tSC
}

/// Return the subject area definition object.
ClientMethod getSubjectAreaObject() [ Language = javascript ]
{
	var json = this.getComponentById('subjectArea');
	var subjectArea = json.getContentObject();
	return subjectArea;
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

		if (isCube) {
			try {
				self.document.location = zenLink('_DeepSee.UI.Architect.zen?CUBE=' + encodeURIComponent(value));
			}
			catch(ex) {
			}
		}
		else if (name != this.subjectAreaName) {
			try {
				self.document.location = zenLink('_DeepSee.UI.ArchitectSA.zen?CUBE=' + encodeURIComponent(value));
			}
			catch(ex) {
			}
		}
		break;
	case 'CubeAdd':
		if (value != this.subjectAreaName) {
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
	case 'SubjectAreaAddItem':
		if ('' != value) {
			this.addNewItemToModel(value);
		}
		break;
	case 'cubes':
		var classname = value.substring(0,value.indexOf('.cube'));
		zen('detailSubBaseCube').setValue(classname);
		zenPage.applyDetails();
		break;		
	case 'sourceClass':
		var classname = value.substring(0,value.indexOf('.cls'));
		zen('detailSubSource').setValue(classname);
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
	case 'switchNamespace':
		var homeurl = zenLink("/csp/sys/%25CSP.Portal.Home.zen");
		var url = zenPage.GetNewURL(value,"_DeepSee.UI.ArchitectSA.zen");
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
	case 'PropertySource':
		zen('detailPropertySource').setValue(value);
		zenPage.applyDetails();
		break;
	case 'PropertyExpression':
		zen('detailPropertyExpression').setValue(value);
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
	case 'SubResource':
		zen('detailSubResource').setValue(value);
		zenPage.applyDetails();
		break;

	}
}

/// Invoke dialog to add a new subjectArea.
ClientMethod newSubjectArea() [ Language = javascript ]
{
	// check if there is unsaved changes
	var undo = self.document.getElementById('cmdUndo');
	
	if (undo.disabled == false) {
		var ok = confirm($$$Text("Changes have not been saved for the current subject area. Discard changes?"));
		if (ok == false) {
			return false;	
		}
	}
	var parms = {
			MODE:'subjectArea',
			CUBE:this.subjectAreaName,
			CLASS:this.subjectAreaClass
			};

	zenLaunchPopupWindow('_DeepSee.UI.Dialog.CubeAdd.cls','SubjectArea','status,scrollbars,resizable=yes,width=700,height=650',parms);
}

/// Open Documatic page to view all details (if user has not modified anything).
ClientMethod doDocument() [ Language = javascript ]
{
	var cube = this.getSubjectAreaObject();	
	if (null == cube) {
		alert($$$Text("Please open a model definition first."));
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

/// Open View Cube page to view all details (if user has not modified anything).
ClientMethod viewSub() [ Language = javascript ]
{
	if (!this.canUndo()) {
		var urlPage = "_DeepSee.UI.CubeView.zen?CUBE=" + cspEncodeUTF8(this.subjectAreaName) + "&BASECUBE=" + cspEncodeUTF8(this.baseCube);
		document.location = urlPage;
	}
}

/// Invoke dialog to add a new item to the model.
ClientMethod addItem() [ Language = javascript ]
{
	if (!this.canUserModify()) {
		return;
	}
	// show add item dialog
	var selectedItem = this.getSelectedItem();
	var selectedClass = '%DeepSee.Model.SubjectArea.dimension';
	if (selectedItem._class) {
		selectedClass = selectedItem._class;
	} else {
		if ('measures' == selectedItem) selectedClass = '%DeepSee.Model.SubjectArea.measure';
		if ('listings' == selectedItem) selectedClass = '%DeepSee.Model.SubjectArea.listing';
	}
	
	this._newItemCounter = this._newItemCounter ? this._newItemCounter : 1;
	var parms = {
			MODE:'savecube',
			BASECUBE:this.baseCube,
			CUBE:this.subjectAreaName,
			CLASS:this.subjectAreaClass,
			SELECTEDCLASS:selectedClass,
			NEWITEMCOUNTER:this._newItemCounter
			};
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.SubjectAreaAddItem.cls','SubjectAreaAddItem','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Add a new item to the model and select it.
ClientMethod addNewItemToModel(typenewname) [ Language = javascript ]
{
	if (!this.canUserModify()) {
		return;
	}

	var subjectArea = this.getSubjectAreaObject();
	
	//this._newItemCounter = this._newItemCounter ? this._newItemCounter : 1;
	var newItem = null;
	var newType = '';

	// find current selection
	// if it is the correct type, we add new item after it or as a child as appropriate
	var selectedItem = this.getSelectedItem();
	var newnames = typenewname.split("^");
	var type = newnames[0];
	var newname = newnames[1];
	switch(type) {
	case 'measure':
		// go through baseCube's measures and compare to see if it is in the newnames. If match found, the create
		var newMsr;
		//var mlen = baseCube.measures.length;
		var mlen = subjectArea.measures.length;
		// for each item in the returned list, check to see if it exists in the object already.
		// if not, insert a new one. if yes, then append to it.
		var item = newname.split(",");
		var found = 0;
		var itemlen = item.length - 1;
	
		for (var i = 1; i < itemlen; i++) {
			newMsr = new Object();
			newMsr._class = '%DeepSee.Model.SubjectArea.measure';	
			newMsr.name = item[i];
			newMsr.description = '';
			newMsr.displayName = '';
			newMsr.disabled = '';
			newMsr.formatString = '';
			if (!selectedItem._class || '%DeepSee.Model.SubjectArea.measure' != selectedItem._class || null == selectedItem._index) {
				// add to end
				subjectArea.measures[subjectArea.measures.length] = newMsr;
			}
			else {
				// insert
				subjectArea.measures.splice(selectedItem._index,0,newMsr);
			}
			newItem = newMsr;
		}
		this.addUndoAction();
		newType = 'measure';
		break;
	case 'dimension':
		var dim,hier,level,newDim,newHier,newLevel,piece,foundDim,foundHier,foundLevel;
		var item = newname.split(",");
		var itemlen = item.length - 1;
			newType = 'dimension';
		// for each item in the returned list, check to see if it exists in the object already.
		// if not, insert a new one. if yes, then append to it.
		for (var i = 1; i < itemlen; i++)
		{
			var mlen = subjectArea.dimensions.length;
			piece = item[i].split("#");
			ptype = piece[0];
			dimname = piece[1];
			hiername = piece[2];
			levelname = piece[3];
			foundDim = 0;
			foundHier = 0;
			foundLevel = 0;
			switch (ptype) {
			case "d":
				for (var d = 0; d < mlen; d++) {
					dim = subjectArea.dimensions[d];
					if (dim.name == dimname) {
						newDim = dim;
						foundDim = 1;
						break;
					}
				}
				// dimension is new, so add it here
				if (!foundDim) {
					newDim = this.createDim(dimname);
					subjectArea.dimensions[subjectArea.dimensions.length] = newDim;
				}
				newItem = newDim;
				break;				
			case "h":
				for (var d = 0; d < mlen; d++) {
					dim = subjectArea.dimensions[d];
					// found existing dim
					if (dim.name == dimname) {
						foundDim = 1;
						var hlen = dim.hierarchies.length;
						for (var h = 0; h < hlen; h++) {
							hier = dim.hierarchies[h];
							if (hier.name == hiername) {
								foundHier = 1;
								break;
							}
						}
					}
					if (foundDim) break;
				}
				// dimension is new, so add it here and its hier.
				if (!foundDim) {
					newDim = this.createDim(dimname);
					newHier = this.createHier(hiername);
					newDim.hierarchies[newDim.hierarchies.length] = newHier;
					subjectArea.dimensions[subjectArea.dimensions.length] = newDim;
					newItem = newDim;
				} else {
					if (!foundHier) {
						newHier = this.createHier(hiername);
						dim.hierarchies[dim.hierarchies.length] = newHier;
						newItem = newHier;
						newType = "hierarchy";
					}
				}	
				break;
			
			case "l":
				for (var d = 0; d < mlen; d++) {
					dim = subjectArea.dimensions[d];
					// found existing dim
					if (dim.name == dimname) {
						foundDim = 1;
						newDim = dim;
						var hlen = dim.hierarchies.length;
						for (var h = 0; h < hlen; h++) {
							hier = dim.hierarchies[h];
							if (hier.name == hiername) {
								foundHier = 1;
								newHier = hier;
								var llen = hier.levels.length;
								for (var l = 0; l < llen; l++) {
									level = hier.levels[l];
									if (level.name == hiername) {
										foundLevel = 1;
										newLevel = level;
										break;	
									}
								}
							}		
						}
					}
					if (foundDim) break;
				}
				// dimension is new, so add it here and its hier.
				if (!foundDim) {
					newDim = this.createDim(dimname);
					newHier = this.createHier(hiername);
					newDim.hierarchies[newDim.hierarchies.length] = newHier;
					newLevel = this.createLevel(levelname);
					newHier.levels[newHier.levels.length] = newLevel;
					subjectArea.dimensions[subjectArea.dimensions.length] = newDim;
					newItem = newDim;
				} else {
					if (!foundHier) {
						newHier = this.createHier(hiername);
						newLevel = this.createLevel(levelname);
						newHier.levels[newHier.levels.length] = newLevel;
						dim.hierarchies[dim.hierarchies.length] = newHier;
						newItem = newHier;
						newType = "hier";
					} else {
						if (!foundLevel) {
							newLevel = this.createLevel(levelname);
							newHier.levels[newHier.levels.length] = newLevel;
							newItem = newLevel;
							newType = "level";				
						}
					}
				}	
			}
		}
		this.addUndoAction();
		break;

	case 'listing':
		var newList;
		var item = newname.split(",");
		var found = 0;
		var itemlen = item.length - 1;
	
		for (var i = 1; i < itemlen; i++) {
			newList = new Object();
			newList._class = '%DeepSee.Model.SubjectArea.listing';
			newList.name = item[i];
			newList.description = '';
			newList.displayName = '';
			newList.hidden = 0;
			newList.fieldList = '';
			newList.orderBy = '';
			newList.sourceClass = '';
			newList.sql = '';
			if (!selectedItem._class || '%DeepSee.Model.SubjectArea.listing' != selectedItem._class || null == selectedItem._index) {
				// add to end
				subjectArea.listings[subjectArea.listings.length] = newList;
			}
			else {
				// insert
				subjectArea.listings.splice(selectedItem._index,0,newList);
			}
			newItem = newList;
		}
		this.addUndoAction();
		newType = 'listing';
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

ClientMethod createLevel(newname) [ Language = javascript ]
{
	// add a new level to the hierarchy
	var newLevel = new Object();
	newLevel._class = '%DeepSee.Model.SubjectArea.level';
	newLevel.name = newname;
	newLevel.description = '';
	newLevel.hidden = 0;
	newLevel.displayName = '';	
	newLevel.sort = '';
	return newLevel;
}

ClientMethod createDim(newname) [ Language = javascript ]
{
	var newDim = new Object();
	newDim._class = '%DeepSee.Model.SubjectArea.dimension';
	newDim.name = newname;					
	newDim.description = '';
	newDim.allCaption = '';
	newDim.allDisplayName = ''; 
	newDim.displayName = '';
	newDim.hierarchies = new Array();
	return newDim;
}

ClientMethod createHier(newname) [ Language = javascript ]
{
	// add a new hierarchy to the dimension
	var newHier = new Object();
	newHier._class = '%DeepSee.Model.SubjectArea.hierarchy';
	newHier.name = newname;
	newHier.description = '';
	newHier.hidden = 0;
	newHier.displayName = '';
	newHier.levels = new Array();
	return newHier;
}

/// Invoke class finder dialog. popupName="sourceclasses" or "cubes"
ClientMethod browseClass(popupName) [ Language = javascript ]
{
	var mode = (popupName == "sourceClass") ? "sourceclasses" : "cubes";
	zenLaunchPopupWindow('_DeepSee.UI.Dialog.finderDialog.cls?MODE='+mode,popupName,'resizable,width=900,height=500');
}

/// user modified DependsOn. Since it is not part of json, handle it seperately.
ClientMethod applyDependsOn(value) [ Language = javascript ]
{
	// JMD934
	this.addUndoAction();
	this.subjectAreaDependsOn = value;
}

/// user modified Domain. Since it is not part of json, handle it seperately.
ClientMethod applyDomain(value) [ Language = javascript ]
{
	this.addUndoAction();
	this.subjectAreaDomain = value;
}

/// Invoke dialog to edit certain items: RangeExpression, FormatString, SourceProperty, SourceExpression.
ClientMethod editItem(what) [ Language = javascript ]
{
	var selectedItem = this.getSelectedItem();
	var uiclass = "_DeepSee.UI.Dialog.GetList.cls";
	switch(what) {		
	case 'FormatString':
		var value = zen("detailMeasureFormatString").getValue();
		var element = zen('detailMeasureName').getValue();
		uiclass = "_DeepSee.UI.Dialog." + what + ".cls";
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

	case 'SubResource':
		var value = zen('detailSubResource').getValue();
		var element = zen("detailSubName").getValue();
		var uiclass = "_DeepSee.UI.Dialog.GetResource.cls";
		break;		

	}

	var parms = {
			CUBE:this.subjectAreaName,
			ELEMENT:element,
			DATASOURCE:this.dataSource,
			SELECTEDCLASS:selectedItem._class,
			VALUE:value,
			WHAT:what
			};
	zenLaunchPopupWindow(uiclass,what,'status,scrollbars,resizable=yes,width=640,height=680',parms);
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
	//alert(type);
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
		if (('measures' == type)||('dimensions' == type)||('listings' == type)) {
			type = '';
		}

		// make appropriate group in details panel visible
		zen('defaultDetails').setHidden(type != '');
		zen('subDetails').setHidden(type != 'subjectArea');
		zen('measureDetails').setHidden(type != 'measure');
		zen('dimensionDetails').setHidden(type != 'dimension');
		zen('hierarchyDetails').setHidden(type != 'hierarchy');
		zen('levelDetails').setHidden(type != 'level');
		zen('listingDetails').setHidden(type != 'listing');

		// set contents of detail form
		var item = this._rowIndex[row];
		if (item) {
			switch(type) {
			case 'subjectArea':
				zen('detailSubName').setValue(item.name);
				zen('detailSubDisabled').setValue(item.disabled);
				zen('detailSubDisplayName').setValue(item.displayName);
				zen('detailSubDescription').setValue(item.description);
				zen('detailSubBaseCube').setValue(item.baseCube);
				zen('detailSubDefaultMeasure').setValue(item.defaultMeasure);
				zen('detailSubDefaultMember').setValue(item.defaultMember);
				zen('detailSubDefaultListing').setValue(item.defaultListing);
				zen('detailSubCountMeasureCaption').setValue(item.countMeasureCaption);
				zen('detailSubFilterSpec').setValue(item.filterSpec);
				zen('detailSubOwner').setValue(item.owner);
				zen('detailSubResource').setValue(item.resource);
				zen('detailSubCaption').setValue(item.caption);
				break;
			case 'measure':
				zen('detailMeasureName').setValue(item.name);
				zen('detailMeasureDescription').setValue(item.description);
				zen('detailMeasureHidden').setValue(item.hidden);
				zen('detailMeasureDisplayName').setValue(item.displayName);
				zen('detailMeasureFormatString').setValue(item.formatString);
				break;
			case 'dimension':
				zen('detailDimensionName').setValue(item.name);
				zen('detailDimensionDescription').setValue(item.description);
				zen('detailDimensionHidden').setValue(item.hidden);
				zen('detailDimensionDisplayName').setValue(item.displayName);
				zen('detailDimensionAllCaption').setValue(item.allCaption);
				zen('detailDimensionAllDisplayName').setValue(item.allDisplayName);
				//check if hasAll from the BaseCube is on/off. If off then hide both All fields.
				var dimHasAll = this.dimHasAll(item);
				zen('idAllLevel').setHidden(!dimHasAll);
				break;
			case 'hierarchy':
				zen('detailHierarchyName').setValue(item.name);
				zen('detailHierarchyDescription').setValue(item.description);
				zen('detailHierarchyHidden').setValue(item.hidden);
				zen('detailHierarchyDisplayName').setValue(item.displayName);
				break;
			case 'level':
				zen('detailLevelName').setValue(item.name);
				zen('detailLevelDescription').setValue(item.description);
				zen('detailLevelHidden').setValue(item.hidden);
				zen('detailLevelDisplayName').setValue(item.displayName);
				zen('detailLevelSort').setValue(item.sort);
				break;
			case 'listing':
				zen('detailListingName').setValue(item.name);
				zen('detailListingDescription').setValue(item.description);
				zen('detailListingHidden').setValue(item.hidden);
				zen('detailListingDisplayName').setValue(item.displayName);
				zen('areadetailListingFieldList').setValue(item.fieldList);
				zen('detailListingSelectMode').setValue(item.selectMode);		// DP-422922
				zen('areadetailListingOrderBy').setValue(item.orderBy);
				zen('areadetailListingSQL').setValue(item.sql);
				zen('detailListingSourceClass').setValue(item.sourceClass);
				var useSQL = (item.sql.length > 0);
				zen('detailListingUseSQL').setValue(useSQL);
				this.changeUseSQL();
				break;			
			}
		}
	}
}

/// Find if this baseCube's dimension property hasAll is true or false.
/// If false, then do not show the all members fields.
ClientMethod dimHasAll(item) [ Language = javascript ]
{
	var baseCube = this.getCubeObject();
	var blen = baseCube.dimensions.length;
	var dimHasAll = false;
	for (var b = 0; b < blen; b++) {
		if (baseCube.dimensions[b].name == item.name) {
			dimHasAll = baseCube.dimensions[b].hasAll;
			break;
		}
	}
	return dimHasAll;
}

/// Find the css class for the given row type.
ClientMethod getCSSForType(type) [ Language = javascript ]
{
	switch(type) {
	case 'subjectArea':
		return 'modelRowCube';
	case 'measures':
		return 'modelRowDimension';
	case 'measure':
		return 'modelRowMeasure';
	case 'dimensions':
	case 'measures':
		return 'modelRowDimension';	
	case 'dimension':
		return 'modelRowMeasure';
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
	case 'calculatedMembers':
		return 'modelRowDimension';
	case 'calculatedMember':
		return 'modelRowMeasure';
	case 'namedSets':
		return 'modelRowDimension';
	case 'namedSet':
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
		case 'subjectArea':
			//item.name = zen('detailSubName').getValue();
			item.owner = zen('detailSubOwner').getValue();
			item.caption = zen('detailSubCaption').getValue();
			item.description = zen('detailSubDescription').getValue();
			item.defaultMeasure = zen('detailSubDefaultMeasure').getValue();
			item.defaultListing = zen('detailSubDefaultListing').getValue();
			item.countMeasureCaption = zen('detailSubCountMeasureCaption').getValue();
			item.disabled = zen('detailSubDisabled').getValue();
			item.baseCube = zen('detailSubBaseCube').getValue();
			item.filterSpec = zen('detailSubFilterSpec').getValue();
			item.displayName = zen('detailSubDisplayName').getValue();
			item.resource = zen('detailSubResource').getValue();
			break;
		case 'measure':
			item.description = zen('detailMeasureDescription').getValue();
			item.hidden = zen('detailMeasureHidden').getValue();
			item.displayName = zen('detailMeasureDisplayName').getValue();
			item.formatString = zen('detailMeasureFormatString').getValue();
			break;
		case 'dimension':
			item.description = zen('detailDimensionDescription').getValue();
			item.allCaption = zen('detailDimensionAllCaption').getValue();
			item.hidden = zen('detailDimensionHidden').getValue();
			item.displayName = zen('detailDimensionDisplayName').getValue();
			item.allDisplayName = zen('detailDimensionAllDisplayName').getValue();
			break;
		case 'hierarchy':
			item.description = zen('detailHierarchyDescription').getValue();
			item.hidden = zen('detailHierarchyHidden').getValue();
			item.displayName = zen('detailHierarchyDisplayName').getValue();
			break;
		case 'level':
			item.description = zen('detailLevelDescription').getValue();
			item.hidden = zen('detailLevelHidden').getValue();
			item.displayName = zen('detailLevelDisplayName').getValue();
			item.sort = zen('detailLevelSort').getValue();
			break;
		case 'listing':
			item.name = zen('detailListingName').getValue();
			item.description = zen('detailListingDescription').getValue();
			item.hidden = zen('detailListingHidden').getValue();
			item.displayName = zen('detailListingDisplayName').getValue();
			item.fieldList = zen('areadetailListingFieldList').getValue();
			item.selectMode = zen('detailListingSelectMode').getValue();		// DP-422922
			item.orderBy = zen('areadetailListingOrderBy').getValue();
			item.sql = zen('areadetailListingSQL').getValue();
			item.sourceClass = zen('detailListingSourceClass').getValue();
			break;
		}

		this.updateTable();
		// !!! this.setModified(true);
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
ClientMethod removeItem(type, row, index, hier, level, prop) [ Language = javascript ]
{
	var item = this._rowIndex[row];
	if (item) {
		var subjectArea = this.getSubjectAreaObject();

		var ok = confirm($$$Text('Do you wish to delete this item?')+'\n' + type + ": " + item.name);
		if (!ok) {
			return;
		}
		this.addUndoAction();

		switch(type) {
		case 'measure':
			subjectArea.measures.splice(index,1);
			break;
		case 'dimension':
			subjectArea.dimensions.splice(index,1);
			break;
		case 'hierarchy':
			subjectArea.dimensions[index].hierarchies.splice(hier,1);
			break;
		case 'level':
			subjectArea.dimensions[index].hierarchies[hier].levels.splice(level,1);
			break;
		case 'property':
			subjectArea.dimensions[index].hierarchies[hier].levels[level].properties.splice(prop,1);
			break;
		case 'listing':
			subjectArea.listings.splice(index,1);
			break;
		case 'calculatedMember':
			// YSD2397 subjectArea.calculatedMembers.splice(index,1);
			break;			
		case 'namedSet':
			// YSD2397 subjectArea.namedSets.splice(index,1);
			break;			
		}
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
		var subjectArea = this.getSubjectAreaObject();
		this._undoIndex--;
		var oldSubjectArea = this._undoBuffer[this._undoIndex];
		var json = this.getComponentById('subjectArea');
		json.setContentObject(oldSubjectArea);
		this.updateTable();

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
	var subjectArea = this.getSubjectAreaObject();
	var oldSubjectArea = this.cloneObject(subjectArea);
	this._undoBuffer[this._undoIndex] = oldSubjectArea;
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
	// WAL014 - Add extension to name
	var cube = this.subjectAreaName + '.subjectArea';
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
	var cube = this.subjectAreaName;
	cube = (cube!='') ? cube + '.cube' : '';
	var win = window.open('_DeepSee.UI.MDXQuery.zen?SUBJECTAREA='+encodeURIComponent(cube),'Docbook');
	try {
		win.focus();
	}
	catch(ex) {
	}
}

/// User click on disclosure icon in table.
ClientMethod toggleDisclosure(key) [ Language = javascript ]
{
	var subjectArea = this.getSubjectAreaObject();
	if (subjectArea && subjectArea._contracted) {
		subjectArea._contracted[key] = !subjectArea._contracted[key];
		this.updateTable();
	}
}

/// Save the cube.
ClientMethod save() [ Language = javascript ]
{
	if (!this.canUserModify()) {
		return;
	}
	// show save dialog
	var parms = {
			MODE:'savesub',
			CUBE:this.subjectAreaName,
			CLASS:this.subjectAreaClass,
			DESC:this.subjectAreaDescription
			};

	zenLaunchPopupWindow('_DeepSee.UI.Dialog.CubeSave.cls','CubeSave','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Do save now. This method is called from compile also.
ClientMethod saveCube() [ Language = javascript ]
{
	var ok = this.saveDocument();
	if (ok) {
		this.clearUndoBuffer();
	}
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,$ZCVT($className(),"O","URL")_".zen?CUBE="_$ZCVT(..subjectAreaFullName,"O","URL"))
	Quit $$$OK
}

/// Object submit handler JSON provider.
/// This is called when the client submits the Subject Area definition.
Method SubmitSubjectArea(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, ByRef pResponseObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tClass = ..subjectAreaClass
		Set tDesc = $TR(..subjectAreaDescription,$C(13),"")
		Set tDomain = ..subjectAreaDomain
		Set tReadOnly = 0

		If (pCommand '= "forcesave") && ##class(%Dictionary.ClassDefinition).%ExistsId(tClass) {
			Set tSC = ..LoadClassDefinition(tClass,.tModelDef,.tReadOnly,1)
			If $$$ISERR(tSC) Quit
			If $zdatetime(tModelDef.TimeChanged,3,,6) '= pSubmitObject.Timestamp {
				Set pProvider.error = "timestamp"
				Quit
			}
		}
			
		// JMD934
		Set tDependsOn = ..subjectAreaDependsOn
		// Save the class subjectArea definition
		Set tSC = ##class(%DeepSee.Utils).%SaveSubjectAreaDefinition(tClass,"",tDesc,pSubmitObject,tDomain,tDependsOn)

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

/// Compile the cube.
ClientMethod compile() [ Language = javascript ]
{
	if (!this.canUserModify()) {
		return;
	}
	var undo = self.document.getElementById('cmdUndo');
	
	if (undo.disabled == false) {
		// save before compile!
		this.saveCube();
	}
	// show compile dialog
	var parms = {
			MODE:'compilesub',
			CUBE:this.subjectAreaName,
			CLASS:this.subjectAreaClass
			};

	zenLaunchPopupWindow('_DeepSee.UI.Dialog.CubeCompile.cls','CubeCompile','status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Test if the user has write privilege.
ClientMethod canUserModify() [ Language = javascript ]
{
	if (!this.canWrite) {
		alert($$$Text('You are not authorized to modify or save subject area definitions.'));
		return false;
	}
	if (this.readOnly) {
		alert($$$Text('This subject area definition is read only.'));
		return false;
	}
	return true
}

/// method used by Source Control to set the value of the readOnly flag.
ClientMethod setReadOnly(readOnly) [ Language = javascript ]
{
	this.readOnly = !!readOnly;
	zen("tabDetails").setProperty('disabled',!!readOnly);
}

}
