/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%IKPublic, %IKInclude)

/// iKnow Architect helps users create %iKnow.AbstractDomain by manipulating
/// %iKnow.DomainDefinition. To create a iKnow Domain, users could manually
/// create a %iKnow.DomainDefintion class and encapsulate the all kinds of domain
/// settins into the XData section of %iKnow.DomainDefintion in Studio.
/// By %iKnow.UI.Architect, this GUI interface would create the corresponding
/// %iKnow.DomainDefinition based on the users input 
Class %iKnow.UI.Architect Extends %iKnow.UI.standardPage [ Deprecated, System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Domain Architect";

/// If this page has multiple views, this is its initial display mode.
Parameter DOCBOOKID;

Property %domain As %iKnow.Model.domain;

Property domainName As %ZEN.Datatype.string;

Property domainDefName As %ZEN.Datatype.string(ZENURL = "DOMAIN");

Property domainId As %String;

Property PageURL As %String;

Parameter DOMAIN = "%iKnow";

Parameter RESOURCE = "%Development";

Property currItem As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// Type of the current selected item.
Property currItemType As %ZEN.Datatype.string;

Property lblExpression As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("(expression)")} ];

Property lblDataLevel As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Level (type=data)")} ];

Property lblTimeLevel As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Level (type=time)")} ];

Property lblAgeLevel As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Level (type=age)")} ];

Property hlpRemove As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Remove this item")} ];

Property hlpMoveUp As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Move this item up")} ];

Property hlpMoveDown As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Move this item down")} ];

Property hlpShowHide As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Hide or show the properties box")} ];

Property msgInvalid As %ZEN.Datatype.caption [ InitialExpression = {$$$FormatText($$$Text("Please click [Open] to select a %1 Domain."),$$$PRODUCT5)} ];

Property msgOpenModel As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Please open a model definition first.")} ];

Property hlpDropTooltip As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Create new %1")} ];

Property manualInput As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Manually Input Group Field")} ];

/// If true, the settings area (property sheet) is visible.
Property settingsExpanded As %Boolean [ InitialExpression = 1, Internal ];

/// Whether to expand all elements under each type. When user clicks Collapse All then this is set to 0. At end of renderTable it is set to 2.
Property expandAll As %Integer [ InitialExpression = 1 ];

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


.modelRowDomain {
	color: rgb(67,67,67);
	font-size: 1.2em;
	font-weight: bold;
	background: #D0D0FF;
}
.modelRowDomainSelected {
	font-size: 1.2em;
	font-weight: bold;
	color: white;
	background: rgb(53,107,141);
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

.hdrLinkUndo {
	font-size: 10pt;
	font-weight: normal;
	color: #3b84bc;
	text-decoration: none;
	padding-left: 6px;
	padding-right: 6px;
	visibility: hidden;
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

<jsonProvider id="json" 
	targetClass="%iKnow.Model.Domain"
	OnGetTargetObject="OnGetModelDomain" 
	OnSubmitContent="OnSubmitModelDomain">
</jsonProvider>

<hgroup id="mainGroup" cellVAlign="top">
<vgroup id="editorPane">
<html id="modelTableHeader" OnDrawContent="DrawTableHeader"></html>
<hgroup cellVAlign="top">
<dynaTree id="dataSource" hidden="true" >
</dynaTree>
<html id="modelTableBody" dropEnabled="true" ondrop="return zenPage.tableDropHandler(dragData);"></html>
</hgroup>
</vgroup>
<vgroup id="propertyPane">
<html id="propertyTitle"><span id="spanArrow" title="#(%page.hlpShowHide)#" onclick="zenPage.toggleSettings();" onmouseover="this.style.color='#FFEEAA';this.style.cursor='pointer'" onmouseout="this.style.color='';this.style.cursor='';">&#187;</span></html>
<tabGroup id="propertyTabs" showTabBar="true">
<tab id="tabDetails" caption="Details">
<vgroup>
<spacer height="5"/>
<vgroup id="defaultDetails" label="Select an item on the left to view and edit its properties">
</vgroup>
<vgroup id="IKnowDomainDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<text id="domainName" label="Domain Name" size="44" onchange="zenPage.applyDetails();"/>
<text id="domainTablePackage" label="Domain Tables Package" size="44" onchange="zenPage.applyDetails();"
hint="Package name for table projections" 
title="When specified, table projections of the domain's data will be generated in this package"/>
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<checkbox id="domainAllowCustomUpdate" label="Allow Custom Updates" onchange="zenPage.applyDetails();"
   title="Check this box if you want to enable adding data or dictionaries to the domain manually." />
<checkbox id="domainDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
</hgroup>
</vgroup>
<vgroup id="IKnowDomainSetting" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<multiSelectSet id="domainConfigLang" label="Languages" layout="vertical" onchange="zenPage.applyDetails();" 
   title="Supported languages for this domain. Actual language will be detected automatically when selecting more than one language"/>
<button caption="Add Parameter" onclick="zenPage.addIKnowElementWrapper('%iKnow.Model.parameter','%iKnow.Model.configuration');"
   title="Add domain parameter."/>
<text id="domainMaxConceptLength" label="Maximum Concept Length" size="5" onchange="zenPage.applyDetails();" 
  title="Maximum # of words per concept." 
  hint="Leave 0 to use language default. For advanced use only!" />
<text id="domainConfigName" hidden="true" label="Name" size="44" onchange="zenPage.applyDetails();"/>
<button caption="Manage User Dictionary" onclick="zenPage.addUDEntry();" title="Edit User Dictionary entries"/>
</vgroup>
<vgroup id="IKnowDomainSettingField" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<text id="IKnowDomainSettingFieldName" label="Name" size="44" onchange="zenPage.applyDetails();"
 title="Domain Parameter value" hint="For advanced use only"/>
<text id="IKnowDomainSettingFieldValue" label="Value" size="44" onchange="zenPage.applyDetails();"
 title="Domain Parameter value" hint="For advanced use only"/>
</vgroup>
<vgroup id="IKnowDomainMetaData" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<checkbox id="metaDataDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
</hgroup>
<button caption="Add Metadata" onclick="zenPage.addIKnowElementWrapper('%iKnow.Model.metadataField','%iKnow.Model.metadata');"/>
</vgroup>
<vgroup id="IKnowDomainMetaDataField" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<text id="metaDataFieldName" label="Name" size="44" onchange="zenPage.applyDetails();"
title="Name of the metadata field"/>
<combobox id="metaDataFieldDataType" label="Data Type" size="44" onchange="zenPage.applyDetails();"/>
<text id="metaDataFieldOperators" label="Supported operators" size="44" onchange="zenPage.applyDetails();"
   title="Supported operators for metadata-based filters" hint="Available values: =, !=, &lt;, &lt;=, &gt;, &gt;=, IS NULL, IS NOT NULL, BETWEEN" />
<!--
<text id="metaDataFieldOperatorsManually" label="Current Operators" size="44" onchange="zenPage.applyDetails();"/>
<combobox id="metaDataFieldOperators" label="Available Operators" size="44" onchange="zenPage.applyDetails();"/>
-->
<select id="metaDataFieldStorage" label="Storage" valueList="normal 0,bitmap 1,compress 2,compressbitmap 3" required="true" showEmpty="false" onchange="zenPage.applyDetails();"
title="Storage type to use for this metadata field." hint="Use 'bitmap' when field values are limited, 'normal' otherwise"/>
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<checkbox id="metaDataFieldCaseSensitive" label="Case Sensitive" onchange="zenPage.applyDetails();"/>
<checkbox id="metaDataFieldDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
</hgroup>
</vgroup>
<vgroup id="IKnowDomainData" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<button caption="Add data from table" onclick="zenPage.addIKnowElementWrapper('%iKnow.Model.listTable','%iKnow.Model.data');"/>
<button caption="Add data from query" onclick="zenPage.addIKnowElementWrapper('%iKnow.Model.listQuery','%iKnow.Model.data');"/>
<button caption="Add data from files" onclick="zenPage.addIKnowElementWrapper('%iKnow.Model.listFiles','%iKnow.Model.data');"/>
<button caption="Add RSS data" onclick="zenPage.addIKnowElementWrapper('%iKnow.Model.listRSS','%iKnow.Model.data');"/>
<button caption="Add data from global" onclick="zenPage.addIKnowElementWrapper('%iKnow.Model.listGlobal','%iKnow.Model.data');"/>
<checkbox id="dataDropBeforeBuild" label="Drop existing data before build" onchange="zenPage.applyDetails();"/>
<checkbox id="dataDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
</vgroup>
<vgroup id="IKnowDomainList" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<text id="listName" label="Name" size="44" onchange="zenPage.applyDetails();"
   title="Identifier for this data location" />
<text id="listFilePath" label="Path" size="44" onchange="zenPage.applyDetails();" title="Filesystem location for the data, accessible from the server." />
<text id="listFileExtensions" label="Extensions" size="44" onchange="zenPage.applyDetails();" title="File extensions to load. Leave blank for all." />
<combobox id="listFileEncoding" label="Encoding" unrestricted="true" required="true" onchange="zenPage.applyDetails();"
hint="Character set of the files at this location. i.e. UTF-8" />
<text id="listFileFilterCondition" label="Filter Condition" size="44" onchange="zenPage.applyDetails();" hidden="true"
title="Filter condition to enforce for every file name"  hint="For advanced use only" />
<hgroup labelPosition="left" cellStyle="padding-right:10px;">
<checkbox id="listFileRecursive" label="Recursive" onchange="zenPage.applyDetails();" title="Check to enable loading data from subdirectories recursively" />
<checkbox id="listBatchMode" label="Batch Mode" onchange="zenPage.applyDetails();" title="Disable batch loading only for very small datasets (&lt;25 records)"/>
</hgroup>
<textarea id="listQuerySql" label="SQL" cols="32" rows="3" onchange="zenPage.applyDetails('sql');" title="SQL query to fetch data" />
<combobox id="listQueryIdField" label="ID Field" size="44" onchange="zenPage.toggleOrApply(zenThis);zenPage.adjustGroupFieldValue('listQueryGroupField',zenThis.getValue());" title="Query column containing record identifier" />
<text id="listQueryIdFieldFree" hidden="true" label="ID Field" size="44" onchange="zenPage.applyDetails();" title="Query column containing record identifier" />
<button id="listQueryIdFieldFreeRevert" hidden="true" caption="Show Default Options" onclick="zenPage.revertCustomizableField('listQueryIdField');"/>
<combobox id="listQueryGroupField" label="Group Field" size="44" onchange="zenPage.toggleOrApply(zenThis);" title="Query column containing secondary identifier" />
<text id="listQueryGroupFieldFree" hidden="true" label="Group Field" size="44" onchange="zenPage.applyDetails();" title="Query column containing secondary identifier" />
<button id="listQueryGroupFieldFreeRevert" hidden="true" caption="Show Default Options" onclick="zenPage.revertCustomizableField('listQueryGroupField');"/>
<combobox id="listQueryDataField" label="Data Field" size="44" onchange="zenPage.toggleOrApply(zenThis);" title="Query columns containing text data to be loaded" />
<text id="listQueryDataFieldFree" hidden="true" label="Data Field" size="44" onchange="zenPage.applyDetails();" title="Query columns containing text data to be loaded" />
<button id="listQueryDataFieldFreeRevert" hidden="true" caption="Show Default Options" onclick="zenPage.revertCustomizableField('listQueryDataField');"/>
<text id="listRSSServerName" label="Server Name" size="44" onchange="zenPage.applyDetails();" title="Server name hosting the RSS feed" hint="example: blogs.intersystems.com"/>
<text id="listRSSUrl" label="URL" size="44" onchange="zenPage.applyDetails();" title="URL path to the actual RSS feed" hint="example: /technology/iKnow/feed.xml"/>
<text id="listRSSTextElements" label="Text Elements" size="44" onchange="zenPage.applyDetails();" title="Text elements to load from the RSS feed. Leave blank for defaults" />
<text id="listGlobalGlobalReference" label="Global Reference" size="44" onchange="zenPage.applyDetails();" title="Global name to load data from"/>
<text id="listGlobalBeginSubscript" label="Begin Subscript" size="44" onchange="zenPage.applyDetails();"
title="Subscript to start reading from" hint="Leave blank to start from the beginning"/>
<text id="listGlobalEndSubscript" label="End Subscript" size="44" onchange="zenPage.applyDetails();"
title="Last subscript to read from global" hint="Leave blank to read until the end"/>
<text id="listGlobalFilterCondition" label="Filter Condition" size="44" onchange="zenPage.applyDetails();" hidden="true"
title="Filter condition to enforce for every node"  hint="For advanced use only"/>
<combobox id="listTableSchemaName" label="Schema" size="44" onchange="zenPage.applyDetails('schema');" title="Schema name"/>
<combobox id="listTableTableName" label="Table Name" size="44" onchange="zenPage.applyDetails('table');" title="Table to load data from" />
<combobox id="listTableIdField" label="ID Field" size="44" onchange="zenPage.toggleOrApply(zenThis);zenPage.adjustGroupFieldValue('listTableGroupField',zenThis.getValue());" title="Table column containing record identifier"/>
<text id="listTableIdFieldFree" hidden="true" label="ID Field" size="44" onchange="zenPage.applyDetails();" title="Custom SQL statement retrieving record identifier"/>
<button id="listTableIdFieldFreeRevert" hidden="true" caption="Show Default Options" onclick="zenPage.revertCustomizableField('listTableIdField');"/>
<combobox id="listTableGroupField" label="Group Field" size="44" onchange="zenPage.toggleOrApply(zenThis);" title="Table column containing secondary record identifier" />
<text id="listTableGroupFieldFree" hidden="true" label="Group Field" size="44" onchange="zenPage.applyDetails();" title="Custom SQL statement retrieving secondary record identifier" />
<button id="listTableGroupFieldFreeRevert" hidden="true" caption="Show Default Options" onclick="zenPage.revertCustomizableField('listTableGroupField');"/>
<combobox id="listTableDataField" label="Data Field" size="44" onchange="zenPage.toggleOrApply(zenThis);" title="Table columns containing text to index" />
<text id="listTableDataFieldFree" hidden="true" label="Data Field" size="44" onchange="zenPage.applyDetails();" title="Custom SQL statement retrieving text to index"/>
<button id="listTableDataFieldFreeRevert" hidden="true" caption="Show Default Options" onclick="zenPage.revertCustomizableField('listTableDataField');"/>
<text id="listTableWhereClause" label="Where Clause" size="44" onchange="zenPage.applyDetails('table');" title="Optional WHERE clause"/>
<vgroup id="listMetadataMapParent" width="100%" >
<titleBox title="Metadata mapping" enclosingStyle="margin-bottom:10px; margin-top:20px;" />
<button id="listMetadataDeclare" hidden="true" caption="Declare Metadata" onclick="zenPage.declareMetadata();"/>
<hidden id="listMetadataMapCount" />
<vgroup id="listMetadataMap" width="100%" />
</vgroup>
</vgroup>
<vgroup id="IKnowDomainBL" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<button caption="Add skiplist" onclick="zenPage.addIKnowElementWrapper('%iKnow.Model.skiplist','%iKnow.Model.skiplists');"/>
</vgroup>
<vgroup id="IKnowDomainBLDetails" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<text id="skipListName" label="Name" onchange="zenPage.applyDetails();" title="Name for referring to this skiplist" />
<textarea id="skipListEntries" label="Entries" onchange="zenPage.applyDetails();"
title="Terms making up this skiplist" hint="Enter one term per line" cols="35" rows="12" />
</vgroup>
<vgroup id="IKnowDomainMatching" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<checkbox id="matchingDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
<checkbox id="matchingDropBeforeBuild" label="Drop Before Build" onchange="zenPage.applyDetails();"/>
<checkbox id="matchingAutoExecute" label="Auto Execute" onchange="zenPage.applyDetails();"/>
<checkbox id="matchingIgnoreDictionaryErrors" label="Ignore Dictionary Errors" onchange="zenPage.applyDetails();"/>
<button caption="Add dictionary" onclick="zenPage.addIKnowElementWrapper('%iKnow.Model.dictionary','%iKnow.Model.matching');"/>
</vgroup>
<vgroup id="IKnowDomainDictionary" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<text id="dictionaryName" label="Name" size="44" onchange="zenPage.applyDetails();"/>
<text id="dictionaryDesc" label="Description" size="44" onchange="zenPage.applyDetails();"/>
<select id="dictionaryLanguage" label="Language" showEmpty="false" size="1" onchange="zenPage.applyDetails();"/>
<checkbox id="dictionaryDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
<text id="IKnowDomainDictionaryIndex"  hidden="true" size="44" onchange="zenPage.applyDetails();"/>
<button caption="Add Item" onclick="zenPage.addIKnowElementWrapper('%iKnow.Model.dictionaryItem',zen('IKnowDomainDictionaryIndex').getValue());"/>
</vgroup>
<vgroup id="IKnowDomainDictionaryTerm" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<text id="dictionaryTermString" label="String" size="44" onchange="zenPage.applyDetails();"/>
<select id="dictionaryTermLang" label="Language" showEmpty="false" size="1" onchange="zenPage.applyDetails();"/>
<checkbox id="dictionaryTermDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
</vgroup>
<vgroup id="IKnowDomainDictionaryItem" hidden="true" cellStyle="padding:3px;" labelPosition="top">
<text id="dictionaryItemName" label="Name" size="44" onchange="zenPage.applyDetails();"/>
<text id="dictionaryItemUri"  label="Uri" size="44" onchange="zenPage.applyDetails();"/>
<select id="dictionaryItemLanguage" label="Language" showEmpty="false" size="1" onchange="zenPage.applyDetails();"/>
<checkbox id="dictionaryItemDisabled" label="Disabled" onchange="zenPage.applyDetails();"/>
<text id="IKnowDomainDictionaryItemIndex" label="Language"  hidden="true" size="44" onchange="zenPage.applyDetails();"/>
<button caption="Add Term" onclick="zenPage.addIKnowElementWrapper('%iKnow.Model.dictionaryTerm',zen('IKnowDomainDictionaryItemIndex').getValue());"/>
<label id="IKnowDomainDictionaryFormats" title="Dictionary formats cannot be modified through the InterSystems Text Analytics Architect" />
</vgroup>
</vgroup>
</tab>
<tab caption="Tools" id="tabTools" labelPosition="left" title="Tools for working with InterSystems Text Analytics">
<vgroup cellStyle="padding-left:3px;">
<label label="Tools for working with InterSystems Text Analytics"/>

<hgroup cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/enttity_relationship_model_48.gif"/>
<vgroup>
<button caption="Domain Explorer" controlClass="commandButton" title="Go to Domain Explorer." onclick="zenPage.gotoPortal('KnowledgePortal');"/>
<label label="Use to analyze this domain"/>
</vgroup>
</hgroup>

<hgroup cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/comparison_chart_48.gif"/>
<vgroup>
<button caption="Indexing Results" controlClass="commandButton" title="Go to Indexing Results page." onclick="zenPage.gotoPortal('IndexingResults');"/>
<label label="Use to view record results"/>
</vgroup>
</hgroup>
</vgroup>
</tab>
</tabGroup>
</vgroup>
</hgroup>
</pane>
}

ClientMethod renderDictionaryFormat(item) [ Language = javascript ]
{
	if(!item || !item.formats || item.formats.length <= 0) {
		zen("IKnowDomainDictionaryFormats").setProperty("hidden", true);
	} else {
		zen("IKnowDomainDictionaryFormats").setProperty("hidden", false);
		zen("IKnowDomainDictionaryFormats").setProperty("label", "This item contains "+item.formats.length+" formats");
	}
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit "Domain Architect"
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Domain Architect","%iKnow")
}

/// Get the product name for the page.
Method %OnGetProductName() As %String
{
	Quit "iKnow"
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Domain Architect")

	// commands
	// $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("cmdNew",$$$Text("New"),$$$Text("Create a new domain"),"zenPage.newDomain();")
	Set pCommands(2) = $LB("cmdOpen",$$$Text("Open"),$$$Text("Open an existing domain"),"zenPage.openDomain();")
	Set pCommands(3) = $LB("cmdSave",$$$Text("Save"),$$$Text("Save this domain"),"zenPage.saveDomain();")
	Set pCommands(4) = $LB("cmdCompile",$$$Text("Compile"),$$$Text("Compile this domain"),"zenPage.compileDomain();")
	Set pCommands(5) = $LB("cmdBuild",$$$Text("Build"),$$$Text("Build this domain"),"zenPage.buildDomain();")
	Set pCommands(6) = $LB("cmdDelete",$$$Text("Delete"),$$$Text("Delete domain contents"),"zenPage.dropDomain();")
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
	&html<<div style="position:absolute;top:16px;left:20px;font-weight:bold;color:#404040;">#($$$Text("Model Elements"))#
	&nbsp;
	&nbsp;&nbsp;<a class="hdrLink" href="#" title="#(hlpExpand)#" onclick="zenPage.toggleExpand(1);return false;">#(msgExpand)#</a>
	&nbsp;&nbsp;<a class="hdrLink" href="#" title="#(hlpCollapse)#" onclick="zenPage.toggleExpand(0);return false;">#(msgCollapse)#</a>
	&nbsp;&nbsp;<a id="undoCmd" class="hdrLinkUndo" href="#" title="#(hlpUndo)#" onclick="zenPage.undo();return false;">#(msgUndo)#</a>
	&nbsp;&nbsp;
	</div>>

	Quit $$$OK
}

/// Remember the current state in the undo buffer.
ClientMethod addUndoAction() [ Language = javascript ]
{
	if (null == this._undoBuffer) 
	{
		this._undoBuffer = new Array();
		this._undoIndex = 0;
	}

	// remember copy of entire cube as state
	var model = this.getModelDomainObject();
	var oldModel = this.cloneObject(model);
	this._undoBuffer[this._undoIndex] = oldModel;
	this._undoIndex++;
	if(this._undoIndex && this._undoIndex > 0)
	{
		self.document.getElementById("undoCmd").style.visibility = "visible";
		this.setModified(1);
	}
}

ClientMethod clearUndoAction() [ Language = javascript ]
{
	if( this._undoBuffer)
	{
		this._undoBuffer = new Array();
		this._undoIndex = 0;
	}
	if(!this._undoIndex || this._undoIndex <= 0)
	{
		self.document.getElementById("undoCmd").style.visibility = "hidden";
		this.setModified(0);
	}
}

ClientMethod alreadySaved() [ Language = javascript ]
{
	if(this._undoBuffer && (this._undoIndex > 0))
		return 0;
	return 1;
}

ClientMethod undo() [ Language = javascript ]
{
	if(this._undoBuffer && (this._undoIndex > 0))
	{
		this._undoIndex--;
		var oldModel = this._undoBuffer[this._undoIndex];
		var json = this.getComponentById('json');
		json.setContentObject(oldModel);
		
		if(!this._undoIndex || this._undoIndex <= 0)
		{
			self.document.getElementById("undoCmd").style.visibility = "hidden";
			this.setModified(0);
		}
		this.updateTable();
		// go to refresh the page, but hard to know which row you should select since the selcted row may got removed
		this.selectItem('%iKnow.Model.domain',1);
	}
}

/// return the instance of %iKnow.Model.domain if its corresponding domain definition once compiled successfully
/// Otherwise, we try to load the xdata from domain definition directly.
ClassMethod %GetModel(pDomainDefName As %String, Output pStatus As %Status) As %iKnow.Model.domain
{
	Set tDomain = ""
	Set pStatus = $$$OK
	Try {
		
		Set tClassName = pDomainDefName
		//Set tClassName = ..getDomainDefName(pDomainName)
		If tClassName '= "" {
			// GetModel only works for *compiled* cubes!
			If ($System.OBJ.IsUpToDate(tClassName)) {
				If $zobjclassmethod(tClassName,"%IsA","%iKnow.DomainDefinition") {
					Set tDomain = $zobjclassmethod(tClassName,"%GetModel")
				}
				Else {
					Set pStatus = $$$ERROR($$$GeneralError,"Class is not domain definition")
					Quit
				}
			}
			Else {
				// get model from XData directly
				Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(tClassName,0,.pStatus)
				If $$$ISERR(pStatus) Quit 
				#; find the XDATA block named Cube
				Set tXData = ##class(%Dictionary.XDataDefinition).IDKEYOpen(tClassName,"Domain",0,.pStatus)
				If $$$ISERR(pStatus) Quit
				If $IsObject(tXData) {
					#; get XDATA as stream
					Set tStream = tXData.Data
					Do tStream.Rewind()

					If (tStream.Size > 0) {
						#; render the stream into cube meta-data object (with children)
						Set tReader = ##class(%XML.Reader).%New()

						Set pStatus = tReader.OpenStream(tStream)
						If $$$ISERR(pStatus) Quit

						Do tReader.Correlate("domain","%iKnow.Model.domain")

						#; there should only be one cube defined
						Do tReader.Next(.tDomain,.tSC)
						If $$$ISERR(tSC) Quit
						If '$IsObject(tDomain) {
							Set pStatus = $$$ERROR($$$GeneralError,"No <domain> element defined in Cube block.")
							Quit
						}
					}
				}
				If (tDomain = "") {
					Set pStatus = $$$ERROR($$$GeneralError,"Class does not contain a cube definition")
					Quit
				}
			}
		}
    }
	Catch(ex) {
		//Set tDomain = ""
		Set pStatus = ex.AsStatus()
	}
	Quit tDomain
}

Method OnGetModelDomain(ByRef pParameters, Output pObject As %RegisteredObject) As %Status [ ZenMethod ]
{
	Set pObject = ""
	if $IsObject(..%domain)
		Set pObject = ..%domain
	
	quit $$$OK
}

Method OnSubmitModelDomain(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, ByRef pResponseObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Try 
	{ 		
 		if pCommand = "save"{
 			Set tSC = pSubmitObject.%SaveToClass(..domainDefName,0,0,0,"%iKnow.DomainDefinition")
 		}
 	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}	
	Quit tSC
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
			// this.selectItem('cube',0);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	/// dataSource should be removed from iKnowSMP
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
}

ClientMethod getModelDomainObject() [ Language = javascript ]
{
	var json = this.getComponentById('json');
	var model = json.getContentObject();
	this.appendModelDomain(model);
	return model;
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

ClientMethod declareMetadata() [ Language = javascript ]
{
	var idx = this.findMetadataIndex();
	this.selectItem('%iKnow.Model.metadata', idx, 1);
}

ClientMethod findMetadataIndex() [ Language = javascript ]
{
	var idx = -1;
	var domain = this.getModelDomainObject();
	for (i=0;i<this._rowIndex.length;i++){
		if(this._rowIndex[i] === domain.metadata)
		{
			idx = i;
			break;
		}
	}
	return idx;
}

/// Update the contents of the model table.
ClientMethod renderTable() [ Language = javascript ]
{
	var table = zen('modelTableBody');
	var html = new Array();
	//var cube = this.getCubeObject();
	var domain = this.getModelDomainObject();
	var source,type;

	// maps row number in the table back to an item in the model
	this._rowIndex = new Array();
	
	// n.b., we add a _parent and _index decoration to each element in the tree as we render

	if (null == domain)
	{
		//alert('domain is null !');
		html[html.length] = '<div class="modelError">' + this.msgInvalid + '</div>';
	}
	else {
		// we also add an array to track if disclosures are open or closed
		/*if (null == cube._contracted) {
			cube._contracted = new Object();
		}*/
		if (null == domain._contracted) {
			domain._contracted = new Object();
		}

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
		//source = cube.sourceClass; //iknow don't need it.
		//type = 'cube';
		type = 'domain';
		//this._rowIndex[this._rowIndex.length] = cube;
		this._rowIndex[this._rowIndex.length] = domain;
		//html[html.length] = '<tr class="modelRowCube" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'cube\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
		html[html.length] = '<tr class="modelRowDomain" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'%iKnow.Model.domain\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		//html[html.length] = '<td>' + zenEscapeXML(cube.name) + '</td>';
		var displayName = domain.name;
		if (this.domainId != '')
			displayName += ' ( ID: ' + this.domainId + ' ) ';  
		html[html.length] = '<td>' + zenEscapeXML(displayName) + '</td>';
		html[html.length] = '<td>' + $$$Text("Element Type") + '&nbsp;</td>';
		//html[html.length] = '<td>' + $$$Text("Details") + '&nbsp;</td>';
		html[html.length] = '<td>' + enabler + '&nbsp;</td>';
		html[html.length] = '<td>' + remove + '&nbsp;</td>';
		html[html.length] = '</tr>';

		//iknow config
		type = '';
		//alert('the lengthof domain.configurations ' + domain.configurations.length);
		this._rowIndex[this._rowIndex.length] = domain.configurations[0];
		//this._rowIndex[this._rowIndex.length] = 'domainSetting';
		var closed = this.isClosed(domain,'%iKnow.Model.configuration');
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure2(zenPage.getModelDomainObject(),\'%iKnow.Model.configuration\');"/>';
		//disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '/>';
		//disc = '<img width="16px" src="images/arrow1R.gif"/>';
		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'%iKnow.Model.configuration\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'%iKnow.Model.configuration\',this);" onmouseout="zenPage.rowMouseOut(this);">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + disc + $$$Text('Domain Settings') + '</td>';
		html[html.length] = '<td>' + type + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;' + '</td>';
		html[html.length] = '<td>' + enabler + '&nbsp;</td>';
		html[html.length] = '<td>' + remove + '&nbsp;</td>';
		html[html.length] = '</tr>';
		
		
		if (!closed && domain.parameters && domain.parameters.length > 0) {
			for (var d = 0; d < domain.parameters.length; d++) {
				//if ((domain.parameters[d].name == 'DefaultConfig') && (domain.parameters[d].value == (domain.name+'.Configuration')))
				//	continue;
				var para = domain.parameters[d];
				para._parent = domain.configurations[0];
				para._index = d;
				this._rowIndex[this._rowIndex.length] = para;
				type = 'parameter';
				var isdefault = '';
				//remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'listingField\','+(this._rowIndex.length-1)+','+d+');" />';
				remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'%iKnow.Model.parameter\','+(this._rowIndex.length-1)+','+d+');" />';
				if ((domain.parameters[d].name == 'DefaultConfig') && (domain.parameters[d].value == (domain.name+'.Configuration'))) {
					style = 'style="display:none;"';
				} else {
					style = (para.disabled) ? 'style="background:#C0C0C0;"' : '';
				}
				var fieldExpression = "";
				if (fieldExpression.length > 40) fieldExpression = fieldExpression.substring(0,40) + "...";
		
				html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'%iKnow.Model.parameter\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
				html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
				html[html.length] = '<td>' + indentMea + zenEscapeXML(para.name) + '</td>';
				html[html.length] = '<td>' + type + isdefault + '&nbsp;</td>';
				html[html.length] = '<td>' + zenEscapeXML(fieldExpression) + '&nbsp;</td>';
				html[html.length] = '<td>' + remove + '&nbsp;</td>';
				html[html.length] = '<td>' + '&nbsp;</td>';
				html[html.length] = '</tr>';
			}
		}
		
		// +iknow Domain metaData
		this._rowIndex[this._rowIndex.length] = domain.metadata;
		//var closed = this.isClosed(cube,'listingField');
		var closed = this.isClosed(domain,'%iKnow.Model.metadata');
		//disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure(\'listingField\');"/>';
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure2(zenPage.getModelDomainObject(),\'%iKnow.Model.metadata\');"/>';
		//html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'listingField\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'listingField\',this);" onmouseout="zenPage.rowMouseOut(this);">';
		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'%iKnow.Model.metadata\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'%iKnow.Model.metadata\',this);" onmouseout="zenPage.rowMouseOut(this);">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + disc + $$$Text('Metadata Fields') + '</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '</tr>';	
		
		if (!closed && domain.metadata && domain.metadata.fields) {
			//for (var d = 0; d < cube.listingFields.length; d++) {
			for (var d = 0; d < domain.metadata.fields.length; d++) {
				var field = domain.metadata.fields[d];
				//field._parent = cube;
				field._parent = domain.metadata;
				field._index = d;
				this._rowIndex[this._rowIndex.length] = field;
				//type = 'metaDataField';
				type = field.dataType;
				var isdefault = '';
				//remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'listingField\','+(this._rowIndex.length-1)+','+d+');" />';
				remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'%iKnow.Model.metadataField\','+(this._rowIndex.length-1)+','+d+');" />';
				style = (field.disabled) ? 'style="background:#C0C0C0;"' : '';
				//var fieldExpression = field.fieldExpression;
				//var fieldExpression = field.name;
				var fieldExpression = "";
				if (fieldExpression.length > 40) fieldExpression = fieldExpression.substring(0,40) + "...";
		
				html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'%iKnow.Model.metadataField\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
				html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
				html[html.length] = '<td>' + indentMea + zenEscapeXML(field.name) + '</td>';
				html[html.length] = '<td>' + type + isdefault + '&nbsp;</td>';
				html[html.length] = '<td>' + zenEscapeXML(fieldExpression) + '&nbsp;</td>';
				html[html.length] = '<td>' + remove + '&nbsp;</td>';
				html[html.length] = '<td>' + '&nbsp;</td>';
				html[html.length] = '</tr>';
			}
		}
		//-iKnow domain meta data
		// +iknow domain source data
		this._rowIndex[this._rowIndex.length] = domain.data;
		//var closed = this.isClosed(cube,'listingField');
		var closed = this.isClosed(domain,'%iKnow.Model.data');
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure2(zenPage.getModelDomainObject(),\'%iKnow.Model.data\');"/>';
		//html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'listingField\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'listingField\',this);" onmouseout="zenPage.rowMouseOut(this);">';
		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'%iKnow.Model.data\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'%iKnow.Model.data\',this);" onmouseout="zenPage.rowMouseOut(this);">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + disc + $$$Text('Data Locations') + '</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '</tr>';	
		
		if (!closed && domain.data && domain.data.lists)
		{
			for (var d = 0; d < domain.data.lists.length; d++) {
				var list = domain.data.lists[d];
				var rep = this.getIKnowListerRep(list);
				type = this.getIKnowListerType(list)
				if(rep && rep.length > 0)
					type = type + ":[" + rep + "]";
				
				if(!type || type.length <= 0)
				{
					alert("Unrecognized IKnow Data Source");
					continue;
				}
				list._parent = domain.data;
				list._index = d;
				var source = 'Source';
				if(list.listname && list.listname.length > 0)
					source = list.listname;
				this._rowIndex[this._rowIndex.length] = list;
				var isdefault = '';
				//remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'listingField\','+(this._rowIndex.length-1)+','+d+');" />';
				remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'%iKnow.Model.list\','+(this._rowIndex.length-1)+','+d+');" />';
				style = (list.disabled) ? 'style="background:#C0C0C0;"' : '';
				var fieldExpression = "";
				if (fieldExpression.length > 40) fieldExpression = fieldExpression.substring(0,40) + "...";
		
				html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'%iKnow.Model.list\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
				html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
				html[html.length] = '<td>' + indentMea + zenEscapeXML(source) + '</td>';
				html[html.length] = '<td>' + type + isdefault + '&nbsp;</td>';
				html[html.length] = '<td>' + zenEscapeXML(fieldExpression) + '&nbsp;</td>';
				html[html.length] = '<td>' + remove + '&nbsp;</td>';
				html[html.length] = '<td>' + '&nbsp;</td>';
				html[html.length] = '</tr>';
			}
		}
		// -iknow domain source data
				
		
		// +iknow domain skiplists
		this._rowIndex[this._rowIndex.length] = domain.skiplists;
		var closed = this.isClosed(domain,'%iKnow.Model.skiplists');
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure2(zenPage.getModelDomainObject(),\'%iKnow.Model.skiplists\');"/>';
		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'%iKnow.Model.skiplists\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'%iKnow.Model.skiplists\',this);" onmouseout="zenPage.rowMouseOut(this);">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + disc + $$$Text('skiplists') + '</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '</tr>';	
		
		if (!closed && domain.skiplists)
		{
			for (var d = 0; d < domain.skiplists.length; d++) {
				var bl = domain.skiplists[d];
				bl._parent = domain;
				bl._index = d;
				this._rowIndex[this._rowIndex.length] = bl;
				var isdefault = '';
				remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'%iKnow.Model.skiplist\','+(this._rowIndex.length-1)+','+d+');" />';
				style = (bl.disabled) ? 'style="background:#C0C0C0;"' : '';
				var fieldExpression = '';
				if (fieldExpression.length > 40) fieldExpression = fieldExpression.substring(0,40) + "...";
		
				html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'%iKnow.Model.skiplist\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
				html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
				html[html.length] = '<td>' + indentMea + zenEscapeXML(bl.name) + '</td>';
				html[html.length] = '<td>' + (bl.entries ? bl.entries.length : 0)+' entries' + '&nbsp;</td>';
				html[html.length] = '<td>' + zenEscapeXML(fieldExpression) + '&nbsp;</td>';
				html[html.length] = '<td>' + remove + '&nbsp;</td>';
				html[html.length] = '<td>' + '&nbsp;</td>';
				html[html.length] = '</tr>';
			}
		}
		
		// +iknow matching
		this._rowIndex[this._rowIndex.length] = domain.matching;
		var closed = this.isClosed(domain,'%iKnow.Model.matching');
		disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure2(zenPage.getModelDomainObject(),\'%iKnow.Model.matching\');"/>';
		html[html.length] = '<tr class="modelRowDimension" id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'%iKnow.Model.matching\','+(this._rowIndex.length-1)+');" onmouseover="zenPage.rowMouseOver(\'%iKnow.Model.matching\',this);" onmouseout="zenPage.rowMouseOut(this);">';
		html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
		html[html.length] = '<td>' + disc + $$$Text('Matching') + '</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '<td>' + '&nbsp;</td>';
		html[html.length] = '</tr>';	
		
		if (!closed && domain.matching)
		{
			var t = new Date().getTime();
			for (var d = 0; d < domain.matching.dictionaries.length; d++) {
				var dic = domain.matching.dictionaries[d];
				dic._parent = domain.matching;
				//dic._index = d;
				if(!dic._index){
					dic._index = t ;
					t+=1;
				}
				this._rowIndex[this._rowIndex.length] = dic;
				
				//var closed = this.isClosed(domain,'%iKnow.Model.dictionary');
				//disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure2(zenPage.getModelDomainObject(),\'%iKnow.Model.dictionary\');"/>';
				
				var closed = this.isClosed(domain,dic._index);
				disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure2(zenPage.getModelDomainObject(),%%);"/>';
				disc = disc.replace("%%",dic._index);
				
				var isdefault = '';
				remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'%iKnow.Model.dictionary\','+(this._rowIndex.length-1)+','+d+');" />';
				style = (dic.disabled) ? 'style="background:#C0C0C0;"' : '';
				var fieldExpression = '';
				if (fieldExpression.length > 40) fieldExpression = fieldExpression.substring(0,40) + "...";
		
				html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'%iKnow.Model.dictionary\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
				html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
				html[html.length] = '<td>' + indentMea + disc + zenEscapeXML(dic.name) + '</td>';
				html[html.length] = '<td>' + (dic.items ? dic.items.length : 0)+' items' + '&nbsp;</td>';
				html[html.length] = '<td>' + zenEscapeXML(fieldExpression) + '&nbsp;</td>';
				html[html.length] = '<td>' + remove + '&nbsp;</td>';
				html[html.length] = '<td>' + '&nbsp;</td>';
				html[html.length] = '</tr>';
				///// for dictionary item
				for(var i=0; !closed && i<dic.items.length;i++)
				{
					//alert("start :" + i);
					var item = dic.items[i];
					item._parent = dic;
					//item._index = i;
					if(!item._index){
						item._index = t;
						t+=1;
					}
									
					this._rowIndex[this._rowIndex.length] = item;
					
					//var closed = this.isClosed(domain,'%iKnow.Model.dictionaryItem');
					//var closed = this.isClosed(domain,item);
					//disc = '<img width="16px" src="' + (!closed ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure2(zenPage.getModelDomainObject(),\'%iKnow.Model.dictionaryItem\');"/>';
				
					
					var firstTime = domain._contracted[item._index];
					if(typeof firstTime === "undefined" )
						firstTime = 1;
					var closedItem = this.isClosed(domain,item._index);
					if(!closedItem && firstTime == 1)
					{
						zenPage.toggleDisclosure2(domain,item._index,2); //just update, dont rerender table
						closedItem = !closedItem;
					}
					disc = '<img width="16px" src="' + (!closedItem ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure2(zenPage.getModelDomainObject(),%%);"/>';
					disc = disc.replace("%%",item._index);
				
					var isdefault = '';
					remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'%iKnow.Model.dictionaryItem\','+(this._rowIndex.length-1)+','+i+');" />';
					style = (item.disabled) ? 'style="background:#C0C0C0;"' : '';
					var fieldExpression = '';
					if (fieldExpression.length > 40) fieldExpression = fieldExpression.substring(0,40) + "...";
		
					html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'%iKnow.Model.dictionaryItem\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
					html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
					html[html.length] = '<td>' + indentHier +disc +zenEscapeXML(item.name) + '</td>';
					html[html.length] = '<td>' + (item.terms ? item.terms.length : 0)+' terms' + '&nbsp;</td>';
					html[html.length] = '<td>' + zenEscapeXML(fieldExpression) + '&nbsp;</td>';
					html[html.length] = '<td>' + remove + '&nbsp;</td>';
					html[html.length] = '<td>' + '&nbsp;</td>';
					html[html.length] = '</tr>';
					
					
					for(var j=0; !closedItem && j<item.terms.length;j++)
					{
						var term = item.terms[j];
						term._parent = item;
						term._index = j;
					
						this._rowIndex[this._rowIndex.length] = term;
					
						var closedTerm = this.isClosed(domain,'%iKnow.Model.dictionaryTerm');
						disc = '<img width="16px" src="' + (!closedItem ? 'images/arrow1D.gif' : 'images/arrow1R.gif') + '" onclick="zenPage.toggleDisclosure2(zenPage.getModelDomainObject(),%%);"/>';
						disc = disc.replace("%%",term._index);
						
						var isdefault = '';
						remove = '<img width="16px" src="' + 'deepsee/close_a_16.png' + '" title="' + this.hlpRemove + '" onclick="zenPage.removeItem(\'%iKnow.Model.dictionaryTerm\','+(this._rowIndex.length-1)+','+j+');" />';
						style = (item.disabled) ? 'style="background:#C0C0C0;"' : '';
						var fieldExpression = '';
						if (fieldExpression.length > 40) fieldExpression = fieldExpression.substring(0,40) + "...";
		
						html[html.length] = '<tr class="modelRowMeasure" '+style+' id="row_'+(this._rowIndex.length-1)+'" onclick="zenPage.rowClick(\'%iKnow.Model.dictionaryTerm\','+(this._rowIndex.length-1)+');" onmouseover="this.style.color=\'orange\';" onmouseout="this.style.color=\'\';">';
						html[html.length] = '<td width="10">' + '<span class="selector">&raquo;</span>' + '</td>';
						html[html.length] = '<td>' + indentLevel +disc +zenEscapeXML(term.string) + '</td>';
						html[html.length] = '<td>' + 'term' + '&nbsp;</td>';
						html[html.length] = '<td>' + zenEscapeXML(fieldExpression) + '&nbsp;</td>';
						html[html.length] = '<td>' + remove + '&nbsp;</td>';
						html[html.length] = '<td>' + '&nbsp;</td>';
						html[html.length] = '</tr>';
					}
				}
			}
		}
				
		html[html.length] = '</table>'; 
	}
	table.setContent(html.join(''));
	this.expandAll = 2;
}

ClientMethod addIKnowElementWrapper(type, disclosure) [ Language = javascript ]
{
	var sc = this.addUndoAction();

	//if(type != "%iKnow.Model.userDictionary")
	sc = this.addIKnowElement(type,this._rowIndex[this.currItem]);

	if (type.substring(0,"%iKnow.Model.list".length) == "%iKnow.Model.list"){
		type = '%iKnow.Model.list';
	}

	sc = this.toggleDisclosure2(zenPage.getModelDomainObject(),disclosure,1);
	
	var offset = 0;
		
	this.selectItem(type,this.currItem+1+offset,true);
}

ClientMethod addIKnowElement(type, parent) [ Language = javascript ]
{
	var domain = this.getModelDomainObject();
	//var parent = '';
	switch(type)
	{
		case '%iKnow.Model.listFiles':
		case '%iKnow.Model.listQuery':
		case '%iKnow.Model.listRSS':
		case '%iKnow.Model.listGlobal':
		case '%iKnow.Model.listTable':
			var file = this.createModelList(type);
			if(!domain.data)
				domain.data = this.createModelData();
			domain.data.lists.splice(0,0,file);
			//parent = '%iKnow.Model.data';
			break;
		case '%iKnow.Model.metadataField':
			var metadataField = this.createModelMetadataField();
			if(!domain.metadata)
				domain.metadata = this.createModelMetadata();
			domain.metadata.fields.splice(0,0,metadataField);
			//parent = '%iKnow.Model.metadata';
			break;
		case '%iKnow.Model.parameter':
			var para = this.createModelParameter();
			if(!domain.parameters)
				domain.parameters = [];
			domain.parameters.splice(0,0,para);
			break;
		case '%iKnow.Model.blacklist':
		case '%iKnow.Model.skiplist':
			var bl = { '_class':'%iKnow.Model.skiplist', 
						'name':'Skiplist_' + (domain.skiplists ? domain.skiplists.length+1 : 1), 
						'entries':[] };
			if (!domain.skiplists) 
				domain.skiplists = [];
			domain.skiplists.splice(0,0,bl);
			break;
		case '%iKnow.Model.dictionary':
			var dic = this.createDictionary();
			if(!domain.matching)
				domain.matching = this.createMatching();
			domain.matching.dictionaries.splice(0,0,dic);
			break;
		case '%iKnow.Model.dictionaryItem':
			var item = this.createDictionaryItem();;
			parent.items.splice(0,0,item);
			break;
		case '%iKnow.Model.dictionaryTerm':
			var term = this.createDictionaryTerm();;
			parent.terms.splice(0,0,term);
			break;
		default:
			alert("add "+type + " not yet implemented");
	}
}

ClientMethod createModelMetadata() [ Language = javascript ]
{
	var metadata = new Object();
	metadata._class = '%iKnow.Model.metadata';
	metadata.disabled = '';
	metadata.fields = [];
	return metadata;
}

Method getMDOPEQUAL() As %String [ ZenMethod ]
{
	quit $$$MDOPEQUAL
}

Method getMDDTSTRING() As %String [ ZenMethod ]
{
	quit $$$MDDTSTRING
}

ClientMethod createModelMetadataField() [ Language = javascript ]
{
	var metadataField = new Object();
	metadataField._class = '%iKnow.Model.metadataField';
	metadataField.name = '';
	metadataField.operators = this.getMDOPEQUAL();
	metadataField.dataType = this.getMDDTSTRING();
	metadataField.storage = 0;
	metadataField.caseSensitive = 0;
	metadataField.disabled = '';
	return metadataField;
}

ClientMethod createModelData() [ Language = javascript ]
{
	var newData = new Object();
	newData._class = '%iKnow.Model.data';
	newData.disabled = '';
	newData.dropBeforeBuild = 1;
	newData.lists = new Array();
	return newData
}

ClientMethod createModelProcessor() [ Language = javascript ]
{
	processor = new Object();
	processor._class = '%iKnow.Model.processor';
	processor.processorClass = '';
	return processor;
}

ClientMethod createModelConverter() [ Language = javascript ]
{
	converter = new Object();
	converter._class = '%iKnow.Model.converter';
	converter.converterClass = '';
	return converter;
}

ClientMethod getMetadataMapColumns() [ Language = javascript ]
{
	var cols = '';
	var cnt = parseInt(zen('listMetadataMapCount').getValue());
	for (var i = 0; i < cnt; i++) {
		var input = zen('listMetadataMap'+i);
		if ((input.getValue()=='') || (input.getValue()=='#')) {
			continue;
		} else if (input.getValue()=='##') {
			cols = cols + (cols=='' ? '' : ',') + zen('listMetadataMap'+i+'Free').getValue();
		} else  {
			cols = cols + (cols=='' ? '' : ',') + input.getValue();
		}
	}
	return cols;
}

ClientMethod getMetadataMapFields() [ Language = javascript ]
{
	var cols = '';
	var cnt = parseInt(zen('listMetadataMapCount').getValue());
	for (var i = 0; i < cnt; i++) {
		var input = zen('listMetadataMap'+i);
		if ((input.getValue()=='') || (input.getValue()=='#')) {
			continue;
		}
		cols = cols + (cols=='' ? '' : ',') + input.getProperty('label');
	}
	return cols;
}

/// maintain a stack which holds the left brace or quotes,
/// when meeting comman(sep), if the size of stack > 0, then this comman is invalid.
ClientMethod metadataColParser(cols, sep) As %String [ Language = javascript ]
{
	if(cols == null || cols.length <= 0)
		return null;
	
	var parsedCols = [];
	var isInQuotes = false;
	var parenthesesLevel = 0;
	var startPos = 0;
	for (var pos=0; pos<cols.length; pos++) {
		switch (cols.charAt(pos)) {
			case '\'':	// toggle quote (supports SQL-escaped quotes)
				if (isInQuotes) {
					isInQuotes = false;
				} else {
					isInQuotes = true;
				}
				break;
			case '(': 	// increase par level if not in quoted string
				if (!isInQuotes) {
					parenthesesLevel++;
				}
				break;
			case ')':	// decrease par level if not in quoted string
				if (!isInQuotes) {
					parenthesesLevel--;
				}
				break;
			case ',':	// if we're not in a quoted string nor SQL-function parentheses, split
				if (!isInQuotes && (parenthesesLevel==0)) {
					parsedCols[parsedCols.length] = cols.substring(startPos,pos);
					startPos = pos+1;
				}
				break;
			default:
				break;
		}
	}
	if (isInQuotes) {
		alert($$$Text('Unterimnated quotes in column list:\n'+cols));
	}
	if (parenthesesLevel!=0) {
		alert($$$Text('Opening and closing parentheses count doesn\'t match in column list:\n'+cols));
	}
	
	// add the last part
	parsedCols[parsedCols.length] = cols.substring(startPos);
	return parsedCols;
}

ClientMethod updateUserDictionary(json) [ Language = javascript ]
{
	if(!json)
		return;
	var domain = this.getModelDomainObject();
	var ud = "";
	if (domain.userDictionaries && domain.userDictionaries.length > 0) {
		for (var d = 0; d < domain.userDictionaries.length; d++) {
			if(domain.userDictionaries[d].name == domain.configurations[0].userDictionary){
				ud = domain.userDictionaries[d];
				break;
			}
		}
	}
	if(ud == "")
		return;

	var entries = JSON.parse(json);
	ud.entries = new Array();
	
	for(var i=0; i<entries.length; i++)
	{
		var udEntry = { '_class':'%iKnow.Model.userDictionaryEntry', 'rewriteFrom': entries[i].f };
		if (entries[i].l) {
			udEntry.assignLabel = entries[i].l;
			
			// DP-406858 - attribute metadata, such as c=9 for certainty level
			if (entries[i].m) { 
				udEntry.metadata = entries[i].m;
			}
			
		} else {
			udEntry.rewriteTo = entries[i].t;
		}
		ud.entries[ud.entries.length] = udEntry;
	}
}

ClientMethod getUserDictionary() [ Language = javascript ]
{
	var domain = this.getModelDomainObject();
	var entries = "";
	if (domain.userDictionaries && domain.userDictionaries.length > 0) 
	{
		for (var d = 0; d < domain.userDictionaries.length; d++) {
			if(domain.userDictionaries[d].name == domain.configurations[0].userDictionary){
				var ud = domain.userDictionaries[d];
				for(var i=0;ud.entries && i<ud.entries.length;i++)
				{
					var from = ""
                    if (ud.entries[i].rewriteFrom) {from = ud.entries[i].rewriteFrom.toString();}
                    var to = ""
                    if (ud.entries[i].rewriteTo) { to = ud.entries[i].rewriteTo.toString();}
                    var label = ""
                    if (ud.entries[i].assignLabel) {
	                    label = ud.entries[i].assignLabel.toString();
	                }
	                
	                // DP-406858 - attribute metadata, such as c=9 for certainty level
	                var meta = ""
                    if (ud.entries[i].metadata) {
	                    meta = ud.entries[i].metadata.toString();
                    }
                    
                    if (entries != "") entries += ","
					entries += '{ "f": "'+from.replace("\\","\\\\").replace('"','\\"')+'"';
					if ((to != null) && (to != "")) entries += ', "t": "'+to.replace("\\","\\\\").replace('"','\\"')+'"';
					if ((label != null) && (label != "")) entries += ', "l": "'+label.replace("\\","\\\\").replace('"','\\"')+'"';
					if ((meta != null) && (meta != "")) entries += ', "m": "'+meta.replace("\\","\\\\").replace('"','\\"')+'"';
					entries += '}';
				}
			}
		}
	}
	return "["+entries+"]";
}

ClientMethod refreshMetadataMap() [ Language = javascript ]
{
	// first get rid of existing controls
	var sc = zenPage.ClearMetadataMap()
	
	// find the current list object
	var list = this._rowIndex[this.currItem];
	
	// retrieve the list of available columns
	if (list._class == '%iKnow.Model.listQuery') {
		var sql = list.sql;
	} else if (list._class == '%iKnow.Model.listTable') {
		var sql = 'SELECT * FROM '+list.tableName;
	}
	else
		return;
		
	var cols = zenPage.getColumnNames(sql);
	
	// retrieve the list of metadata fields and add a control for each one
	var domain = zen('json').getContentObject();
	var fieldIndex = [];
	for (var i = 0; i<domain.metadata.fields.length; i++) {
		var field = domain.metadata.fields[i].name;
		fieldIndex[field] = i;
		sc = zenPage.CreateMetadataMapField(i, field, cols);
	}
	if(domain.metadata.fields.length == 0)
		zen('listMetadataDeclare').setHidden(false);
	else
		zen('listMetadataDeclare').setHidden(true);
	zen('listMetadataMapCount').setValue(domain.metadata.fields.length);
	sc = zen('listMetadataMapParent').refreshContents(true);
	
	// now populate the list of created dropdowns with the mapping in the definition
	// list.metadataColumns contains the actual mapping
	var currentColNames = this.metadataColParser(list.metadataColumns,',');
	// list.metadataFields contains the corresponding field names,
	// if not implied by list.metadataColumns
	var currentFieldNames = (list.metadataFields && (list.metadataFields!='')) ? list.metadataFields.split(',') : (currentColNames ? currentColNames : []);
	
	for (var i = 0; i < currentFieldNames.length; i++) {
		if (currentFieldNames[i] != '') {
			var fieldName = zenTrim(currentFieldNames[i]);
			if (fieldName.substring(fieldName.length-1)=="\"") {
				fieldName = fieldName.split("\"");
				fieldName = fieldName[fieldName.length-2];
			} else if (fieldName.indexOf(" ")>0) {
				fieldName = fieldName.split(" ");
				fieldName = fieldName[fieldName.length-1];
			}
			var colName = zenTrim(currentColNames[i]);
			var field = fieldIndex[fieldName];
			if (colName == '') {
				sc = zen('listMetadataMap'+field).setValue('#');
			} else if (cols.indexOf(colName)>=0) {
				sc = zen('listMetadataMap'+field).setValue(colName);
			} else {
				sc = zen('listMetadataMap'+field).setValue('##');
				sc = zen('listMetadataMap'+field+'Free').setValue(colName);
				zenPage.toggleCustomizableField('listMetadataMap'+field);
			}
		}
	}
	zen('listMetadataMap').refreshContents();
}

Method ClearMetadataMap() As %Status [ ZenMethod ]
{
	do ..%GetComponentById("listMetadataMap").%RemoveChildren()
	quit $$$OK
}

ClientMethod toggleCustomizableField(field) [ Language = javascript ]
{
	zen(field).setHidden(true);
	zen(field+'Free').setHidden(false);
	zen(field+'FreeRevert').setHidden(false);
}

ClientMethod revertCustomizableField(field) [ Language = javascript ]
{
	zen(field).setHidden(false);
	zen(field+'Free').setHidden(true);
	zen(field+'Free').setValue("");
	zen(field+'FreeRevert').setHidden(true);
	zenPage.setCustomizableFieldValue(field, "!!");
	zenPage.applyDetails();
}

ClientMethod toggleOrApply(field) [ Language = javascript ]
{
	if (field.getValue()=='##') {
		zenPage.toggleCustomizableField(field.getProperty('id'));
	} else {
		zenPage.applyDetails();
	}
}

ClientMethod adjustGroupFieldValue(groupField, val) [ Language = javascript ]
{
	if(zenPage.getCustomizableFieldValue(groupField) == "")
		zenPage.setCustomizableFieldValue(groupField, val);
}

Method CreateMetadataMapField(pIndex As %Integer, pField As %String, pValueList As %String) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		set tGroup = ..%GetComponentById("listMetadataMap")
		
		set tValueList = "#,##,"_pValueList
		set tDisplayList = "- not mapped -,- custom -,"_pValueList
		
		set tSelect = ##class(%ZEN.Component.select).%New()
		set tSelect.id = "listMetadataMap"_pIndex
		set tSelect.label = pField
		set tSelect.onchange = "zenPage.toggleOrApply(zenThis);"
		set tSelect.valueList = tValueList
		set tSelect.displayList = tDisplayList
		set tSelect.showEmpty = 0
		set tSelect.value = "#"
		do tGroup.%AddChild(tSelect)
		
		set tText = ##class(%ZEN.Component.text).%New()
		set tText.id = "listMetadataMap"_pIndex_"Free"
		set tText.label = pField
		set tText.onchange = "zenPage.applyDetails();"
		set tText.hidden = 1
		set tText.size = 44
		do tGroup.%AddChild(tText)
	
		set tCheckBox = ##class(%ZEN.Component.button).%New()
		set tCheckBox.id = "listMetadataMap"_pIndex_"FreeRevert"
		set tCheckBox.caption = "Show Default Options"
		set tCheckBox.hidden = 1
		set tCallback = "zenPage.revertCustomizableField('"_"listMetadataMap"_pIndex_"');"
		set tCheckBox.onclick = tCallback
		do tGroup.%AddChild(tCheckBox)
			
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		set err = $zconvert($system.Status.GetErrorText(tSC),"O","JS")
		&js<console.log('#(err)#')>
	}
	quit tSC
}

ClientMethod createModelList(option) [ Language = javascript ]
{
	var newList = new Object();
	newList.listerClass = '';
	newList.batchMode = 1;
	var name = this.createNameForLister(option);
	newList.listname = name;
	switch(option)
	{
		case '%iKnow.Model.listFiles':
			newList._class = '%iKnow.Model.listFiles';
			newList.path = '';
			newList.recursive = '';
			newList.extensions = '';
			newList.filterCondition ='';
			newList.encoding = '';
			newList.listerClass = '%iKnow.Source.File.Lister';
			break;
		case '%iKnow.Model.listQuery':
			newList._class = '%iKnow.Model.listQuery';
			newList.sql = '';
			newList.idField = '';
			newList.groupField = '';
			newList.dataFields = '';
			newList.metadataColumns = '';
			newList.metadataFields = '';
			newList.listerClass = '%iKnow.Source.SQL.Lister';
			break;
		case '%iKnow.Model.listRSS':
			newList._class = '%iKnow.Model.listRSS';
			newList.serverName = '';
			newList.url = '';
			newList.textElements = '';
			newList.listerClass = '%iKnow.Source.RSS.Lister';
			break;
		case '%iKnow.Model.listTable':
			newList._class = '%iKnow.Model.listTable';
			newList.tableName = '';
			newList.whereClause = '';
			newList.idField = '';
			newList.groupField = '';
			newList.dataFields = '';
			newList.metadataColumns = '';
			newList.metadataFields = '';
			newList.listerClass = '%iKnow.Source.SQL.Lister';
			break;
		case '%iKnow.Model.listGlobal':
			newList._class = '%iKnow.Model.listGlobal';
			newList.globalReference = '';
			newList.beginSubscript = '';
			newList.endSubscript = '';
			newList.filterCondition = '';
			newList.listerClass = '%iKnow.Source.Global.Lister';
	}
	return newList;
}

ClientMethod parseQuery(query) [ Language = javascript ]
{
	if(!query || query.length <= 0)
		return {};
	var tokens = query.split(" ");
	var fields = {'idField':'','groupField':'','dataFields':''};
	for(i=0;i<tokens.length;i++)
	{
		var key_value = tokens[i].split('=');
		if(key_value && key_value.length == 2 && key_value[0] in fields)
		{
			if((key_value[1].substring(0,1) == '"') && (key_value[1].substring(key_value[1].length-1,key_value[1].length) =='"')){
				key_value[1] = key_value[1].substring(1,key_value[1].length-1);
			}
			if((key_value[1].substring(0,1) == "'") && (key_value[1].substring(key_value[1].length-1,key_value[1].length) == "'"))
				key_value[1] = key_value[1].substring(1,key_value[1].length-1);
			fields[key_value[0]] = key_value[1];
		}
	}
	return fields;
}

ClientMethod createModelParameter() [ Language = javascript ]
{
	var parameter = new Object();
	parameter._class = '%iKnow.Model.parameter';
	parameter.name = '';
	parameter.value = '';
	return parameter;
}

ClientMethod createMatching() [ Language = javascript ]
{
	var matching = {
		 '_class':'%iKnow.Model.matching',
		 'disabled':0, 
		 'dropBeforeBuild':1, 
		 'autoExecute':1,
		 'ignoreDictionaryErrors':1,
		 'dictionaries': new Array(),
		 'external' : new Array(),
		 'profiles' : new Array(),
		 'defaultProfile' : "",
	};
	return matching;
}

ClientMethod createDictionary() [ Language = javascript ]
{
	var domain = this.getModelDomainObject();
	var idx = 1;
	if(domain.matching)
		idx += domain.matching.dictionaries.length ;
	var dictionary = 
	{
		'_class':'%iKnow.Model.dictionary',
		items : new Array(),
		name : "Dictionary_" + idx,
		description : "",
		language : "",
		profile : "",
		disabled : 0,
		_index : new Date().getTime()
	}
	return dictionary;
}

ClientMethod createDictionaryItem() [ Language = javascript ]
{
	var domain = this.getModelDomainObject();
	var idx = 1;
	if(domain.matching){
		for(var i=0;i<domain.matching.dictionaries.length;i++)
			idx += domain.matching.dictionaries[i].items.length;
	}
	var dictionaryItem = 
	{
		'_class':'%iKnow.Model.dictionaryItem',
		terms : new Array(),
		formats : new Array(),
		name : "Item_" + idx,
		uri : "uri:"+idx,
		language : "",
		disabled : 0,
		_index : new Date().getTime()
	};
	return dictionaryItem;
}

ClientMethod createDictionaryTerm() [ Language = javascript ]
{
	var dictionaryTerm = 
	{
		'_class':'%iKnow.Model.dictionaryTerm',
		'string':"",
		'language':"",
		'disabled':0,
	};
	return dictionaryTerm;
}

ClientMethod createModelConfig(configName) [ Language = javascript ]
{
	var config = new Object();
	config._class = '%iKnow.Model.configuration';
	config.name = configName;
	config.detectLanguage = 0;
	config.languages = 'en';
	config.userDictionary = '';
	config.summarize = '';
	config.maxConceptLength = 0;
	return config;
}

ClientMethod associateConfigToDomain(domain, configMacro) [ Language = javascript ]
{
	if(!domain || !domain.hasOwnProperty('parameters'))
		return;
	var parameter = this.createModelParameter();
	parameter.name = configMacro;
	parameter.value = domain.configurations[0].name;
	return parameter;
}

ClientMethod appendModelDomain(domain) [ Language = javascript ]
{
	if(!domain)
		return;
	
	if(!domain.data || !domain.hasOwnProperty('data'))
		domain.data = this.createModelData();
	if(!domain.metadata || !domain.hasOwnProperty('metadata'))
		domain.metadata = this.createModelMetadata();
	
	if(!domain.configurations || !domain.hasOwnProperty('configurations') || domain.configurations.length <= 0 || !domain.configurations[0].name){
		//alert('try to create the config name');
		domain.configurations = new Array();
		var config = this.createModelConfig(domain.name + '.Configuration');
		domain.configurations[domain.configurations.length] = config;
	}
	if(!domain.parameters || !domain.hasOwnProperty('parameters'))
		domain.parameters = new Array();
	if(!domain.skiplists || !domain.hasOwnProperty('skiplists'))
		domain.skiplists = new Array();
	
	var foundUD = 0;
	if(domain.userDictionaries && domain.hasOwnProperty('userDictionaries'))
	{//backward compatibility, if there are a lot of UD in this domain, but users do noes
	 //specify the UD in the default config, we need to create a empty for this domain too.
		for(var i=0;i<domain.userDictionaries.length;i++){
			if(domain.userDictionaries[i].name == domain.configurations[0].userDictionary){
				foundUD = 1;
				break;
			}
		}
	}
	if(!domain.userDictionaries || !domain.hasOwnProperty('userDictionaries') || (foundUD == 0)){
		if(!domain.userDictionaries || !domain.hasOwnProperty('userDictionaries')){
			domain.userDictionaries = new Array();	
		}
		var ud = { '_class':'%iKnow.Model.userDictionary', 
						'name':domain.name +'.Dictionary#' + (domain.userDictionaries ? domain.userDictionaries.length+1 : 1), 
						'entries':[] };
		domain.userDictionaries.splice(0,0,ud);
		domain.configurations[0].userDictionary = ud.name;
	}
	
	if(!domain.matching || !domain.hasOwnProperty('matching'))
		domain.matching = this.createMatching();
	
	var sc = this.assignDefaultConfig(domain);
}

ClientMethod commitChanges(pCommand As %String) [ Language = javascript ]
{
	 var msg = '';
	 if(this.getComponentById('json').submitContent(pCommand))
	 {
		 return msg;
	 }
	 msg = this.getComponentById('json').getError();
	 return msg;
}

ClientMethod saveDomain(pCommand As %String) [ Language = javascript ]
{
	var msg = 'Save Domain Successfully';
	var success = 1
	try
	{
		var model = this.getModelDomainObject();
		if(model)
		{
			// BDB876 - if there is a user-supplied DefaultConfig parameter, we should remove the implicit one
			var customConfigParameter = -1;
			var impliedConfigParameter = -1;
			for (var i=0; i<model.parameters.length; i++) {
				if (model.parameters[i].name == 'DefaultConfig') {
					if (model.parameters[i].value == (model.name+'.Configuration')) {
						impliedConfigParameter = i;
					} else {
	                	customConfigParameter = i;
					}
				}
			}
			if ((customConfigParameter >= 0) && (impliedConfigParameter >= 0)) {
				model.parameters.splice(impliedConfigParameter);
			}
			
			var res = this.commitChanges('save');
			if(res != '')
			{
				success = 0;
				msg =res;
			}
		}
		else
			msg = 'Get Model Failed, Please [OPEN] or reload this domain again !';
	}
	catch(ex)
	{
		success = 0;
		msg = ex.message;
	}		
	if(success)
	{
		this.clearUndoAction();
	}
	else
		alert(msg);	
	return success;
}

ClientMethod compileDomain(pCommand As %String) [ Language = javascript ]
{
	if(!this.alreadySaved())
	{
		var ok = this.saveDomain();;
		if(!ok) return;
	}
	var parms = {
			DOMAINDEF:this.domainDefName
	};
	zenLaunchPopupWindow('_iKnow.UI.Dialog.compileDomain.cls','compileDomain','status,scrollbars,resizable=yes,width=610,height=700',parms);
}

ClientMethod gotoPortal(page) [ Language = javascript ]
{
	var msg = "";
	try
	{
		//HSU040
		this.domainId = this.GetDomainId(this.domainDefName);
		if(this.domainId )
		{
			var url = "";
			if(window.location.protocol && window.location.pathname && window.location.host)
			{
				url = window.location.protocol + "//" + window.location.host;
				var tokens = window.location.pathname.split("/");
				if(tokens && tokens.length > 0)
				{
					url = url + tokens[0];
					for(i=1;i<tokens.length-1;i++){
						url = url + "/" + tokens[i];
					}
				}
				url += "/" + zenLink('%25iKnow.UI.'+page+'.cls?domain=' + encodeURIComponent(this.domainId));	
			}
			if(url){
				var win = window.open(url);
  				win.focus();
			}
		}
		else
		{
			msg = 'Cannot find domain, please load and compile it first';
		}
	}
	catch(ex)
	{
		msg = ex.message;
	}
	if(msg)
	{
		alert(msg);
	}
}

ClientMethod buildDomain(pCommand As %String) [ Language = javascript ]
{
	var parms = {
			DOMAINDEF:this.domainDefName
	};
	
	var json = this.getComponentById('json');
	var model = json.getContentObject();
	
	if(!model.disabled){ 
		zenLaunchPopupWindow('_iKnow.UI.Dialog.buildDomain.cls','buildDomain','status,scrollbars,resizable=yes,width=610,height=700',parms);
	}
	else{
		alert("this domain is not enabled");
	}
}

ClientMethod adjustIKnowListerFields(type) [ Language = javascript ]
{
	var prefix = 'list' + type;
	var listerProp = [
				/*'listClass',*/
				'listFilePath',
				'listFileRecursive',
				'listFileExtensions',
				'listFileFilterCondition',
				'listFileEncoding',
				'listQuerySql',
				'listQueryIdField',
				'listQueryIdFieldFree',
				'listQueryIdFieldFreeRevert',
				'listQueryGroupField',
				'listQueryGroupFieldFree',
				'listQueryGroupFieldFreeRevert',
				'listQueryDataField',
				'listQueryDataFieldFree',
				'listQueryDataFieldFreeRevert',
				'listRSSServerName',
				'listRSSUrl',
				'listRSSTextElements',
				'listGlobalGlobalReference',
				'listGlobalBeginSubscript',
				'listGlobalEndSubscript',
				'listGlobalFilterCondition',
				'listTableTableName',
				'listTableSchemaName',
				'listTableWhereClause',
				'listTableIdField',
				'listTableIdFieldFree',
				'listTableIdFieldFreeRevert',
				'listTableGroupField',
				'listTableGroupFieldFree',
				'listTableGroupFieldFreeRevert',
				'listTableDataField',
				'listTableDataFieldFree',
				'listTableDataFieldFreeRevert'
				];
				
	for(i=0;i<listerProp.length;i++)
	{
		var prop = listerProp[i];
		if(prop.indexOf(prefix) == 0) {
			if(!prop.endsWith('Revert')){
				zen(prop).setHidden(false);
			}
			
			// hide/show custom select lists
			if ((prop.substr(prop.length-4,4)=='Free') && (prop == (listerProp[i-1]+'Free'))) {
				if (zen(listerProp[i-1]).getValue()=='##') { // custom value
					zen(listerProp[i-1]).setHidden(true);
					zen(prop).setHidden(false);
					zen(prop+'Revert').setHidden(false);
				} else {
					zen(prop).setHidden(true);
					zen(listerProp[i+1]).setHidden(true);
				}
			}
		} 
		else
		{
			zen(listerProp[i]).setHidden(1);
		}
			
	}
	zen('listName').setHidden(0);
	zen('listBatchMode').setHidden(0);
	
	// hide metadata map
	var flds = ['listMetadataMapParent', 'listMetadataMap'];
	for (f in flds) {
		zen(flds[f]).setHidden((type!='Table') && (type!='Query'));
	}
	zenPage.refreshMetadataMap();
}

ClientMethod createNameForLister(type) [ Language = javascript ]
{
	var domain = this.getModelDomainObject();
	var count = 1;
	if (domain.data && domain.data.lists)
	{
		for (var d = 0; d < domain.data.lists.length; d++)
		{
			var list = domain.data.lists[d];
			type1 = list._class
			if(type == type1)
			{
				count++;
			}
		}
	}
	var prefix = "";
	switch(type)
	{
		case "%iKnow.Model.listFiles":
			prefix = "File";
			break;
		case "%iKnow.Model.listGlobal":
			prefix = "Global";
			break;
		case "%iKnow.Model.listQuery":
			prefix = "Query";
			break;
		case "%iKnow.Model.listRSS":
			prefix = "RSS";
			break;
		case "%iKnow.Model.listTable":
			prefix = "Table";
			break;
		default:
			break;
	}
	return prefix + "_" + count
}

ClientMethod getIKnowListerType(lister) [ Language = javascript ]
{
	var ret = '';
	if(!lister)
		return ret;
	else if(lister.hasOwnProperty('path'))
		return 'File';
	else if(lister.hasOwnProperty('sql'))
		return 'Query';
	else if(lister.hasOwnProperty('serverName'))
		return 'RSS';
	else if(lister.hasOwnProperty('globalReference'))
		return 'Global';
	else if(lister.hasOwnProperty('tableName'))
		return 'Table';
	return ret;
}

ClientMethod getIKnowListerRep(lister) [ Language = javascript ]
{
	var ret = '';
	if(!lister || lister.length <= 0)
		return ret;
	else if(lister.hasOwnProperty('path')){
		var ret = lister.path;
		if(lister.path.length > 0)
		{
			var tokens = lister.path.split('\\');
			if(tokens && tokens.length > 0)
				ret = tokens[tokens.length - 1];
			else
			{
				tokens = lister.path.split('/');
				if(tokens && tokens.length > 0)
					ret = tokens[tokens.length - 1];
			}
		}
		return ret;
	}
	else if(lister.hasOwnProperty('sql'))
	{
		var ret = lister.sql;
		if(lister.sql.length > 0)
		{
			var tokens = lister.sql.split(' ');
			if(tokens && tokens.length > 0)
			{
				for(i=0;i<tokens.length;i++)
				{
					if(tokens[i].toLowerCase() == 'from')
					{
						ret = ""
						for(j=0;j<=i;j++)
							ret = ret + tokens[j] + " ";
						if(i+1 < tokens.length)
							ret += tokens[i+1];
						break;
					}
				}
			}
		}
		return ret;
	}
	else if(lister.hasOwnProperty('serverName'))
		return lister.serverName;
	else if(lister.hasOwnProperty('globalReference'))
		return lister.globalReference;
	else if(lister.hasOwnProperty('tableName'))
		return lister.tableName;
	return ret;
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

/// This class method callback is called just before the server-side page 
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##super()
		If $$$ISERR(tSC) Quit

		/*iKnow*/
		Set ..PageURL = $ZCVT($className(),"O","URL")_".zen"
		
		// languages
		set tLanguages = $$$IKLANGUAGES, tDisplayList=""
		for i=1:1:$ll(tLanguages) {
			set tDisplayList=tDisplayList_$s(i=1:"",1:",")_$case($li(tLanguages,i),
				"en":"English", "fr":"French", "de":"German", "nl":"Dutch", "es":"Spanish",
				"pt":"Portuguese", "uk":"Ukrainian", "ru":"Russian", "ja":"Japanese", "sv":"Swedish",
				"cs":"Czech", :$li(tLanguages,i))
		}
		for id = "domainConfigLang", "dictionaryLanguage", "dictionaryItemLanguage", "dictionaryTermLang" {
			set ..%GetComponentById(id).valueList = $lts(tLanguages)
			set ..%GetComponentById(id).displayList = tDisplayList
			set ..%GetComponentById(id).value = "en"
		}
		
		if ..domainDefName '= "" 
		{
			Set ..%domain = ..%GetModel(..domainDefName,.status)
			if status '= $$$OK Set ..msgInvalid = $$$TextHTML("The Domain Definition name is invalid")
			Set ..domainName = ..GetDomainName(..domainDefName)
			Set ..domainId = ..GetDomainId(..domainDefName)
		}
		
		
		Set ..%GetComponentById("listFileEncoding").valueList = ..getEncodings()
		//Set ..%GetComponentById("metaDataFieldOperators").valueList = ..getMetadataOperators()
		Set ..%GetComponentById("metaDataFieldDataType").valueList = ..getMetadataDataTypes()
		//Set ..%GetComponentById("metaDataFieldStorage").valueList = ..getMetadataStorages()
		// end of iknow domain							
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod getEncodings() As %String
{
	set tLocales = ##class(%SYS.NLS.Locale).%New()
	set tList = tLocales.XLTTables, ptr=0, tEncodings=""
	while $listnext(tList, ptr, tEnc) {
		set tDisplay = ##class(%SYS.NLS.Table).LogicalToDisplay(tEnc)
		if tDisplay '= "" {set tEncodings = tEncodings _ $lb(tDisplay)}
	}
	quit $lts(tEncodings)
}

ClassMethod getMetadataDataTypes() As %String
{
	Set li = $lb($$$MDDTSTRING,$$$MDDTNUMBER,$$$MDDTDATE)
	Set len = $LISTLENGTH(li) 
	Set langs = ""
	for i=1:1:len
	{
		Set langs = langs _ $S(langs'="":",",1:"")_$LIST(li,i)
	}
	quit langs
}

ClientMethod getStorageName(index) [ Language = javascript ]
{
	var dict = {};
	dict["0"] = "normal ";
	dict["1"] = "bitmap ";
	dict["2"] = "compress ";
	dict["3"] = "compressbitmap ";
	return dict[index];
}

ClassMethod getMetadataStorages() As %String
{
	Set li = $lb("normal "_$$$MDSTNORMAL,"bitmap "_$$$MDSTBITMAP,"compress "_$$$MDSTCOMPRESS,"compressbitmap "_$$$MDSTCOMPRESSBITMAP)
	Set len = $LISTLENGTH(li) 
	Set langs = ""
	for i=1:1:len
	{
		Set langs = langs _ $S(langs'="":",",1:"")_$LIST(li,i)
	}
	quit langs
}

Method GetDomainName(DDName As %String) As %String [ ZenMethod ]
{
	if DDName = "" quit DDName
	quit $g(^IRIS.IK.Sys.Definition(DDName))
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

/// Do the actual work of updating the view to match the current view mode.
ClientMethod setViewModeHandler(mode) [ Language = javascript ]
{
	this.adjustSizes();
}

ClientMethod parseDomainDefName(ddName) [ Language = javascript ]
{
	if(!ddName || ddName.length <= 0){
		return ddName;
	}
	else if(ddName.length < 4  || ddName.substring(ddName.length - 4,ddName.length) != ".cls"){
		return ddName;
	}
	var dd = ddName.substring(0,ddName.length - 4);
	return dd;
}

/// dName should be the child class of %iKnow.DomainDefition
ClassMethod GetDomainId(dName) As %String [ ZenMethod ]
{
	set tDomainId = ""
	Try
	{
		Set tDomainId = $zobjclassmethod(dName,"%GetDomainId")
	}
	catch(Ex)
	{
		set tDomainId = ""
	}
	quit tDomainId
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	switch(popupName) {
	case 'newDomain':
	case 'openDomain':
	case 'compileDomain':
		try 
		{
			value = this.parseDomainDefName(value);
			self.document.location = zenLink('_iKnow.UI.Architect.zen?DOMAIN=' + encodeURIComponent(value));
		}
		catch(ex)
		{
			alert("exception when open namespace " + ex.AsStatus());
		}
		break;
	case 'switchNamespace':
		var homeurl = zenLink("/csp/sys/%25CSP.Portal.Home.zen");
		var url = zenPage.GetNewURL(value,"_iKnow.UI.Architect.zen");
		if (url == "" || value == "%SYS") url = homeurl;
		try {
			self.document.location = url;
		}
		catch(ex) {
		}
		break;
	case 'dropDomain':
		if (value=='redirect'){
			zenPage.gotoPage('_iKnow.UI.Architect.zen');
		}
		break;
	case 'editUDEntry':
		this.addUndoAction();
		zenPage.updateUserDictionary(value);		
	}
}

ClientMethod newDomain() [ Language = javascript ]
{
	var parms = {
		MODE: 'domain',
	};
	
	zenLaunchPopupWindow('_iKnow.UI.Dialog.addDomain.zen','newDomain','status,scrollbars,resizable=yes,width=600,height=650',parms);
}

ClientMethod openDomain() [ Language = javascript ]
{
	var parms = {
		MODE: 'domain:def',
	};
	zenLaunchPopupWindow('_iKnow.UI.Dialog.openDomain.zen','openDomain','status,scrollbars,resizable=yes,width=800,height=600',parms);
}

ClientMethod addUDEntry() [ Language = javascript ]
{
	var text = zenPage.getUserDictionary();
	var parms = {DIC:text};
	zenLaunchPopupWindow('_iKnow.UI.Dialog.CreateUserDictionaryEntry.zen','editUDEntry','status,scrollbars,resizable=yes,width=800,height=600',parms);
}

ClientMethod dropDomain() [ Language = javascript ]
{
	var parms = {
		DOMAINDEF: zenPage.getProperty('domainDefName')
	};
	zenLaunchPopupWindow('_iKnow.UI.Dialog.dropDomain.zen','dropDomain','status,scrollbars,resizable=yes,width=800,height=600',parms);
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

ClassMethod getIKnowParameterName() As %String [ ZenMethod ]
{
	return $$$IKPDEFAULTCONFIG_","_$$$IKPENABLENGRAMS_","_$$$IKPIGNOREDUPLICATEEXTIDS_","_
	$$$IKPIGNOREEMPTYBATCH_","_$$$IKPMATDEFAULTPROFILE_","_$$$IKPMATSKIPRELATIONS_","_$$$IKPSORTFIELD_","_$$$IKPSTATUS
}

ClientMethod assignDefaultConfig(domain) [ Language = javascript ]
{
	if(!domain || !domain.hasOwnProperty('parameters'))
		return;

	var defaultConfigName = 'DefaultConfig';		
	var findDefaultConfig = false;
	for(i=0;i<domain.parameters.length;i++)
	{
		if(domain.parameters[i].name == defaultConfigName)
		{
			if(domain.parameters[i].value == '' && domain.configurations && domain.configurations.length > 0 ){
				domain.parameters[i].value = domain.configurations[0].name;
			}
			findDefaultConfig = true;
		}
	}
	if(!findDefaultConfig)
	{
		var para = this.associateConfigToDomain(domain, defaultConfigName);
		domain.parameters[domain.parameters.length] = para; 
	}
}

/// The reason we need this helper is beacuse all the %iknow.model.configuationas and %iknow.model.parameters are all configure
/// through Domain setting section, the table could only store %iknow.model.configuations object.
ClientMethod fillUpParameters(domain) [ Language = javascript ]
{
	if(!domain || !domain.hasOwnProperty('parameters'))
		return ;
	var ids = ['domainParaDefaultConfig',
				'domainParaEnableNgrams',
				'domainParaIgnoreDuplicateExtIds',
				'domainParaIgnoreEmptyBatch',
				'domainParaMATDefaultProfile',
				'domainParaMATSkipRelations',
				'domainParaSortField',
				'domainStatus'];	
	var map = {};
	var macros = this.getIKnowParameterName().split(',');
	
	for(i=0;i<macros.length;i++)
		map[macros[i]] = ids[i]; 
	
	var findDefaultConfig = false;
	for(i=0;i<domain.parameters.length;i++)
	{
		if(domain.parameters[i].name == macros[0]){
			if(domain.parameters[i].value == '' && domain.configurations && domain.configurations.length > 0 ){
				domain.parameters[i].value = domain.configurations[0].name;
			}
			findDefaultConfig = true;
		}
	}
	if(!findDefaultConfig)
	{
		var para = this.associateConfigToDomain(domain, macros[0]);
		domain.parameters[domain.parameters.length] = para; 
	}
	
	for(i=0;i<domain.parameters.length;i++)
	{
		var parameter = domain.parameters[i];
		var id = map[parameter.name];
		zen(id).setValue(parameter.value); 
	}
}

ClientMethod applyParameters(domain) [ Language = javascript ]
{
	if(!domain)
		return ;
	
	var ids = ['domainParaDefaultConfig',
				'domainParaEnableNgrams',
				'domainParaIgnoreDuplicateExtIds',
				'domainParaIgnoreEmptyBatch',
				'domainParaMATDefaultProfile',
				'domainParaMATSkipRelations',
				'domainParaSortField',
				'domainStatus'];	
	var map = {};
	var macros = '';
	macros = this.getIKnowParameterName().split(',');
	for(i=0;i<ids.length;i++){
		map[ids[i]] = macros[i];
	}

	var parameters = new Array();

	for(var id in map)
	{
		if(zen(id).getValue() != '')
		{
			var parameter = this.createModelParameter();
			parameter.name = map[id];
			parameter.value = zen(id).getValue();
			parameters[parameters.length] = parameter; 
		}
	}
	// if there is not paramters, should we remove the parameters property from domain?
	domain.parameters = parameters;
}

/// User click on a row in the table.
ClientMethod rowClick(type, row) [ Language = javascript ]
{
	if(this.hasOwnProperty('removeItem') && this.removeItem)
	{
		delete this.removeItem;
		return;
	}
	this.selectItem(type,row);
}

/// Select a row in the table.
ClientMethod selectItem(type, row, force) [ Language = javascript ]
{
	//alert('selectItem type='+type+" row="+row); //jsl
	force = ('undefined' == typeof force) ? false : force;
	tab = zen('tabDetails');
	if ((this.currItem != row) || force) {
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
		//iknow
		zen('IKnowDomainDetails').setHidden(type != '%iKnow.Model.domain');
		zen('IKnowDomainMetaData').setHidden(type != '%iKnow.Model.metadata');
		zen('IKnowDomainMetaDataField').setHidden(type != '%iKnow.Model.metadataField');
		zen('IKnowDomainSetting').setHidden(type != '%iKnow.Model.configuration');
		zen('IKnowDomainData').setHidden(type != '%iKnow.Model.data');
		zen('IKnowDomainList').setHidden(type != '%iKnow.Model.list');
		zen('IKnowDomainBL').setHidden(type != '%iKnow.Model.skiplists');
		zen('IKnowDomainBLDetails').setHidden(type != '%iKnow.Model.skiplist');
		zen('IKnowDomainSettingField').setHidden(type != '%iKnow.Model.parameter');
		zen('IKnowDomainMatching').setHidden(type != '%iKnow.Model.matching');
		zen('IKnowDomainDictionary').setHidden(type != '%iKnow.Model.dictionary');	
		zen('IKnowDomainDictionaryItem').setHidden(type != '%iKnow.Model.dictionaryItem');
		zen('IKnowDomainDictionaryTerm').setHidden(type != '%iKnow.Model.dictionaryTerm');		
		if (item) {
			//zen('lblComputed').setHidden(item.type != "computed");
			switch(type) 
			{
			case '%iKnow.Model.domain':
				zen('domainDisabled').setValue(item.disabled);
				zen('domainAllowCustomUpdate').setValue(item.allowCustomUpdates);
				zen('domainTablePackage').setValue(item.objectsPackage);
				zen('domainName').setValue(item.name);
				break;
			case '%iKnow.Model.parameter':
				zen('IKnowDomainSettingFieldName').setValue(item.name);
				zen('IKnowDomainSettingFieldValue').setValue(item.value);
			case '%iKnow.Model.metadata':
				zen('metaDataDisabled').setValue(item.disabled);
				break;
			case '%iKnow.Model.metadataField':
				zen('metaDataFieldName').setValue(item.name);
				//zen('metaDataFieldOperatorsManually').setValue(item.operators);
				zen('metaDataFieldOperators').setValue(item.operators);
				zen('metaDataFieldDataType').setValue(item.dataType);
				zen('metaDataFieldStorage').setValue(this.getStorageName(item.storage) + item.storage);
				if(item.dataType == "" || item.dataType != 'STRING')
					zen('metaDataFieldCaseSensitive').setHidden(1);
				else
					zen('metaDataFieldCaseSensitive').setHidden(0);
				zen('metaDataFieldCaseSensitive').setValue(item.caseSensitive);
				zen('metaDataFieldDisabled').setValue(item.disabled);
				break;
			case '%iKnow.Model.configuration':
				zen('domainConfigLang').setValue(item.languages);
				zen('domainConfigName').setValue(item.name);
				zen('domainMaxConceptLength').setValue(item.maxConceptLength);
				break;
			case '%iKnow.Model.data':
				zen('dataDisabled').setValue(item.disabled);
				zen('dataDropBeforeBuild').setValue(item.dropBeforeBuild);
				break;
			case '%iKnow.Model.blacklist':
			case '%iKnow.Model.skiplist':
				zen('skipListName').setValue(item.name);
				zen('skipListEntries').setValue((item.entries && item.entries.length) ? item.entries.join('\n') : '');
				break;
			case '%iKnow.Model.matching':
				zen('matchingDisabled').setValue(item.disabled);
				zen('matchingDropBeforeBuild').setValue(item.dropBeforeBuild);
				zen('matchingAutoExecute').setValue(item.autoExecute);
				zen('matchingIgnoreDictionaryErrors').setValue(item.ignoreDictionaryErrors);
				break;
			case '%iKnow.Model.dictionary':
				zen('dictionaryName').setValue(item.name);
				zen('dictionaryDesc').setValue(item.description);
				zen('dictionaryLanguage').setValue(item.language);
				zen('dictionaryDisabled').setValue(item.disabled);
				zen('IKnowDomainDictionaryIndex').setValue(item._index); // xxxx
				break;
			case '%iKnow.Model.dictionaryItem':
				zen('dictionaryItemName').setValue(item.name);
				zen('dictionaryItemUri').setValue(item.uri);
				zen('dictionaryItemLanguage').setValue(item.language);
				zen('dictionaryItemDisabled').setValue(item.disabled);
				zen('IKnowDomainDictionaryItemIndex').setValue(item._index);
				zenPage.renderDictionaryFormat(item);
				break;
			case '%iKnow.Model.dictionaryTerm':
				zen('dictionaryTermString').setValue(item.string);
				zen('dictionaryTermLang').setValue(item.language);
				zen('dictionaryTermDisabled').setValue(item.disabled);
                break;
			case '%iKnow.Model.list':
				var detailType = "";
				if(item.hasOwnProperty('listname'))
					zen('listName').setValue(item.listname);
				zen('listBatchMode').setValue(item.batchMode);
		
				if(item.hasOwnProperty('path')){
					detailType = "%iKnow.Model.listFiles";
					zen('listFilePath').setValue(item.path);
					zen('listFileRecursive').setValue(item.recursive);
					zen('listFileExtensions').setValue(item.extensions);
					zen('listFileFilterCondition').setValue(item.filterCondition);
					zen('listFileEncoding').setValue(item.encoding);
					this.adjustIKnowListerFields(this.getIKnowListerType(item));
				}
				else if(item.hasOwnProperty('sql')){
					detailType = "%iKnow.Model.listQuery";

					if(item.sql){
						this.applySQLtoFields(item.sql);
					}
					zen('listQuerySql').setValue(item.sql);
					zenPage.setCustomizableFieldValue('listQueryIdField', item.idField);
					zenPage.setCustomizableFieldValue('listQueryGroupField', item.groupField);
					zenPage.setCustomizableFieldValue('listQueryDataField', item.dataFields);
					this.adjustIKnowListerFields(this.getIKnowListerType(item));
				}
				else if(item.hasOwnProperty('serverName')){
					detailType = "%iKnow.Model.listRSS";
					zen('listRSSServerName').setValue(item.serverName);
					zen('listRSSUrl').setValue(item.url);
					zen('listRSSTextElements').setValue(item.textElements);
					this.adjustIKnowListerFields(this.getIKnowListerType(item));
				}
				else if(item.hasOwnProperty('tableName')){
					detailType = "%iKnow.Model.listTable";
					var groupFields = "";
					var tableName = item.tableName;
					zen('listTableSchemaName')['valueList'] = this.retreiveSchemas();
					if(tableName != null)
					{
						var tok = tableName.split(".");
						if(tok != null && tok.length == 2 && zen('listTableSchemaName')['valueList'].indexOf(tok[0]) > -1 )
						{
							zen('listTableSchemaName').setValue(tok[0]);
							zen('listTableTableName')['valueList'] = this.retreiveTables(tok[0]); 
							zen('listTableTableName').setValue(tok[1]);		
							groupFields = this.applyTabletoFields(item.tableName);
						}
						else
						{
							zen('listTableSchemaName').setValue('');
							zen('listTableTableName').setValue('');		
						}
					}
					zen('listTableWhereClause').setValue(item.whereClause);
					zenPage.setCustomizableFieldValue('listTableIdField', item.idField);
					zenPage.setCustomizableFieldValue('listTableGroupField', item.groupField);
					zenPage.setCustomizableFieldValue('listTableDataField', item.dataFields);
					this.adjustIKnowListerFields(this.getIKnowListerType(item));
				}
				else if(item.hasOwnProperty('globalReference'))
				{
					detailType = "%iKnow.Model.listGlobal";
					zen('listGlobalGlobalReference').setValue(item.globalReference);
					zen('listGlobalBeginSubscript').setValue(item.beginSubscript);
					zen('listGlobalEndSubscript').setValue(item.endSubscript);
					zen('listGlobalFilterCondition').setValue(item.filterCondition);
					this.adjustIKnowListerFields(this.getIKnowListerType(item));
				}
				break;
			}
		}
	}
}

/// Find the css class for the given row type.
ClientMethod getCSSForType(type) [ Language = javascript ]
{
	switch(type) {
	case '%iKnow.Model.domain':
		return 'modelRowDomain';
	case '%iKnow.Model.metadata':
	case '%iKnow.Model.skiplists':
	case '%iKnow.Model.data':
	case '%iKnow.Model.matching':
		return 'modelRowDimension';
	case '%iKnow.Model.metadataField':
	case '%iKnow.Model.configuration':
	case '%iKnow.Model.list':
	case '%iKnow.Model.listFiles':
	case '%iKnow.Model.listQuery':
	case '%iKnow.Model.listGlobal':
	case '%iKnow.Model.listRSS':
	case '%iKnow.Model.listTable':
	case '%iKnow.Model.parameter':
	case '%iKnow.Model.skiplist':
	case '%iKnow.Model.userDictionary':
	case '%iKnow.Model.dictionary':
	case '%iKnow.Model.dictionaryItem':
	case '%iKnow.Model.dictionaryTerm':
		return 'modelRowMeasure';
	default:
		alert('Unknown type (css)' + type);
		break;
	}
	return '';
}

Method getColumnNames(sql) As %String [ ZenMethod ]
{
	set ret = ""
	try
	{
		set stmt = ##class(%SQL.Statement).%New()
		set sc = stmt.%Prepare(sql)
		if sc = 1
		{
			set colCnt = stmt.%Metadata.columnCount
			for i=1:1:colCnt
			{
				Set ret = ret _ $S(ret'="":",",1:"")_ stmt.%Metadata.columns.GetAt(i).colName
			}
		}
	}
	catch(ex)
	{
		set ret = ""
		&js<alert("the sql statement is invalid")>
	}
	quit ret
}

Method applyTabletoFields(table) As %String [ ZenMethod ]
{
	set valid = 1
	set ret = ""
	try{
		set sql = "select * from " _ table
		set stmt = ##class(%SQL.Statement).%New()
		set sc = stmt.%Prepare(sql)
		set ret = ""
		if sc = 1
		{
			set colCnt = stmt.%Metadata.columnCount
			for i=1:1:colCnt
			{
				Set ret = ret _ "," _ stmt.%Metadata.columns.GetAt(i).colName
			}
			for id = "listTableIdField", "listTableGroupField", "listTableDataField" {
				set ..%GetComponentById(id).valueList = "##"_ret
				set ..%GetComponentById(id).displayList = "- custom -"_ret
			}
		}
		else
		{
			&js<alert("%SQL.Statement.%Prepare fails !")>
			set valid = 0
		}
	}
	catch(ex)
	{
		&js<alert("the sql statement is invalid")>
		set valid = 0
	}
	if valid = 0
	{
		set ..%GetComponentById("listTableIdField").value = "" 
		set ..%GetComponentById("listTableGroupField").value = ""
		set ..%GetComponentById("listTableDataField").value = ""
		set ..%GetComponentById("listTableIdField").valueList = "" 
		set ..%GetComponentById("listTableGroupField").valueList = ""
		set ..%GetComponentById("listTableDataField").valueList = ""
	}
	quit ret
}

Method applySQLtoFields(sql) As %String [ ZenMethod ]
{
	set valid = 1
	set error = ""
	try{
		set stmt = ##class(%SQL.Statement).%New()
		set sc = stmt.%Prepare(sql)
		set ret = ""
		if sc = 1
		{
			set colCnt = stmt.%Metadata.columnCount
			for i=1:1:colCnt
			{
				Set ret = ret _ ","_ stmt.%Metadata.columns.GetAt(i).colName
			}
			for id = "listQueryIdField", "listQueryGroupField", "listQueryDataField" {
				set ..%GetComponentById(id).valueList = "##"_ret
				set ..%GetComponentById(id).displayList = "- custom -"_ret
			}
		}
		else
		{
			set error = $System.Status.GetErrorText(sc)
			set valid = 0	
		}
	}
	catch(ex)
	{
		set error = ex.AsStatus()
		set valid = 0
	}
	if valid = 0
	{
		set ..%GetComponentById("listQueryIdField").value = "" 
		set ..%GetComponentById("listQueryGroupField").value = ""
		set ..%GetComponentById("listQueryDataField").value = ""
		set ..%GetComponentById("listQueryIdField").valueList = "" 
		set ..%GetComponentById("listQueryGroupField").valueList = ""
		set ..%GetComponentById("listQueryDataField").valueList = ""
	}
	quit error
}

ClientMethod getCustomizableFieldValue(id) As %String [ Language = javascript ]
{
	var value = zen(id).getValue();
	return (value == '##') ? zen(id+'Free').getValue() : value;
}

ClientMethod findDefaultValue(id, value) [ Language = javascript ]
{
	var val = value
	var field = zen(id);
	var vals = field.getProperty('valueList').split(",");

	// switch back to dropdown and we shoose the first valid value in the list.
	if(value === "!!"){
		for(j=0;j<vals.length;j++){
			if(!vals[j].startsWith("#")){
				val = vals[j];
				break;
			}
		}
	}
	return val;
}

ClientMethod setCustomizableFieldValue(id, value) As %String [ Language = javascript ]
{
	var field = zen(id);
	var vals = field.getProperty('valueList').split(",");
	value = zenPage.findDefaultValue(id,value);
	
	var idx = - 1;
	for(j=0;j<vals.length;j++){
		if(vals[j].toLowerCase() === value.toLowerCase()){
			idx = j;
			break;
		}
	}
	
	if (idx>=0) {
		var sc = field.setValue(vals[idx]);
		field.refreshContents();
	} else {
		field.setHidden(true);
		field.setValue('##');
		zen(id+'Free').setValue(value);
		zen(id+'Free').setHidden(false);
		zen(id+'FreeRevert').setHidden(false);
	}
}

ClientMethod applyDetails(trigger) [ Language = javascript ]
{
	var item = this._rowIndex[this.currItem];
	
	if(!item || !this.currItemType) return;

	this.addUndoAction();
			
	switch(this.currItemType)
	{
		case '%iKnow.Model.domain':
			item.disabled = zen("domainDisabled").getValue();
			item.allowCustomUpdates = zen('domainAllowCustomUpdate').getValue();
			item.objectsPackage = zen('domainTablePackage').getValue();
			item.name = zen('domainName').getValue();
			break;
		case '%iKnow.Model.parameter':
			item.name = zen("IKnowDomainSettingFieldName").getValue();
			item.value = zen("IKnowDomainSettingFieldValue").getValue();
			// BDB - DP-401939 - removing old HSU252 code
			// if you put in an empty value for DefaultConfig, it will disappear
			// and automatically replaced with the default config managed by this domain
			// named as [domain name]_".Configuration"
            break;
		case '%iKnow.Model.metadata':
			item.disabled = zen("metaDataDisabled").getValue();
			break;
		case '%iKnow.Model.metadataField':
			item.name = zen("metaDataFieldName").getValue();
			item.operators = zen("metaDataFieldOperators").getValue();
			/*
			var oldop = zen("metaDataFieldOperatorsManually").getValue();
			if(oldop && oldop.length > 0 && oldop != item.operators)
			{
				item.operators = oldop;
			}
			else if(zen("metaDataFieldOperators").getValue() && zen("metaDataFieldOperators").getValue().length > 0)
			{
				var ops = "";
				if(zen("metaDataFieldOperators").getValue() == 'ALL')
					ops = this.getAllOperators();
				else
				{
					ops = zen("metaDataFieldOperators").getValue().split(" ");
					if(ops && ops.length > 0)
						ops = ops.join(",");
				}
				item.operators = ops
				zen("metaDataFieldOperatorsManually").setValue(ops);
			}
			*/
			item.dataType = zen("metaDataFieldDataType").getValue();
			if(item.dataType != '' && item.dataType == 'STRING')
				zen("metaDataFieldCaseSensitive").setHidden(0);
			else
				zen("metaDataFieldCaseSensitive").setHidden(1);
			if(zen("metaDataFieldStorage").getValue() != ''){
				var val = zen("metaDataFieldStorage").getValue().split(' ')[1]
				item.storage = val;
			}
			item.caseSensitive = zen("metaDataFieldCaseSensitive").getValue();
			item.disabled = zen("metaDataFieldDisabled").getValue();
			break;
		case '%iKnow.Model.configuration':
			item.languages = zen("domainConfigLang").getValue();
			item.detectLanguage = (item.languages.indexOf(',')>0);
			item.maxConceptLength = zen("domainMaxConceptLength").getValue(); 
			break;
		case '%iKnow.Model.data':
			item.disabled = zen("dataDisabled").getValue();
			item.dropBeforeBuild = zen("dataDropBeforeBuild").getValue();
			break;		
		case '%iKnow.Model.list':
			item.listname = zen("listName").getValue();
			item.batchMode = zen("listBatchMode").getValue();
			if(item.hasOwnProperty("path"))
			{
				item.path = zen("listFilePath").getValue();
				item.extensions = zen("listFileExtensions").getValue();
				item.filterCondition = zen("listFileFilterCondition").getValue();
				item.encoding = zen("listFileEncoding").getValue();
				item.recursive = zen("listFileRecursive").getValue();
			}
			else if(item.hasOwnProperty("sql"))
			{
				if((typeof trigger != 'undefined') && (trigger = 'sql')){
					var error = this.applySQLtoFields(zen("listQuerySql").getValue());
					if(error && error.length > 0)
						alert(error);
				}

				item.sql = zen("listQuerySql").getValue();
				item.idField = zenPage.getCustomizableFieldValue("listQueryIdField");
				item.groupField = zenPage.getCustomizableFieldValue("listQueryGroupField");
				item.dataFields = zenPage.getCustomizableFieldValue("listQueryDataField");
				item.metadataColumns = zenPage.getMetadataMapColumns();
				item.metadataFields = zenPage.getMetadataMapFields();
				zenPage.refreshMetadataMap();
			}
			else if(item.hasOwnProperty("globalReference"))
			{
				item.globalReference = zen("listGlobalGlobalReference").getValue();
				item.beginSubscript = zen("listGlobalBeginSubscript").getValue();
				item.endSubscript = zen("listGlobalEndSubscript").getValue();
				item.filterCondition = zen("listGlobalFilterCondition").getValue();
			}
			else if(item.hasOwnProperty("serverName"))
			{
				item.serverName = zen("listRSSServerName").getValue();
				item.url = zen("listRSSUrl").getValue();
				item.textElements = zen("listRSSTextElements").getValue();
			}
			else if(item.hasOwnProperty("tableName"))
			{
				if((typeof trigger != 'undefined') && (trigger == 'table')){
					if((zen("listTableTableName").getValue() != '') && (zen("listTableSchemaName").getValue() != ''))
					{
						this.applyTabletoFields(zen("listTableSchemaName").getValue()+"."+zen("listTableTableName").getValue());
						item.tableName = zen("listTableSchemaName").getValue()+"."+zen("listTableTableName").getValue();
					}
				}
				else if((typeof trigger != 'undefined') && (trigger == 'schema'))
				{
					zen("listTableTableName").setValue("");
					zen("listTableTableName")['valueList'] = this.retreiveTables(zen("listTableSchemaName").getValue()); 
				}
				
				item.whereClause = zen("listTableWhereClause").getValue();
				item.idField = zenPage.getCustomizableFieldValue("listTableIdField");
				item.groupField = zenPage.getCustomizableFieldValue("listTableGroupField");
				item.dataFields = zenPage.getCustomizableFieldValue("listTableDataField");
				item.metadataColumns = zenPage.getMetadataMapColumns();
				item.metadataFields = zenPage.getMetadataMapFields();
				zenPage.refreshMetadataMap();
			}
			break;
		case '%iKnow.Model.blacklist':
		case '%iKnow.Model.skiplist':
			item.name = zen('skipListName').getValue();
			var blEntries = zen('skipListEntries').getValue();
			item.entries = [];
			if ((blEntries!=null) && (blEntries!='')) {
				blEntries = blEntries.split('\n');
				item
				for (var i=0; i<blEntries.length; i++) {
					if (zenTrim(blEntries[i])=='') continue;
					item.entries[item.entries.length] = blEntries[i];
				}
			}
			break;
		case '%iKnow.Model.dictionary':	
			item.name = zen('dictionaryName').getValue();
			item.description = zen('dictionaryDesc').getValue();
			item.language = zen('dictionaryLanguage').getValue();
			item.disabled = zen('dictionaryDisabled').getValue();
			break;
		case '%iKnow.Model.dictionaryItem':	
			item.name = zen('dictionaryItemName').getValue();
			item.uri = zen('dictionaryItemUri').getValue();
			item.language = zen('dictionaryItemLanguage').getValue();
			item.disabled = zen('dictionaryItemDisabled').getValue();
			break;
		case '%iKnow.Model.dictionaryTerm':	
			item.string = zen('dictionaryTermString').getValue();
			item.language = zen('dictionaryTermLang').getValue();
			item.disabled = zen('dictionaryTermDisabled').getValue();
			break;
		case '%iKnow.Model.matching': 
			item.disabled = zen('matchingDisabled').getValue();
			item.dropBeforeBuild = zen('matchingDropBeforeBuild').getValue();
			item.autoExecute = zen('matchingAutoExecute').getValue();
			item.ignoreDictionaryErrors = zen('matchingIgnoreDictionaryErrors').getValue();	
			break;
		default:
			alert("Unkown Type for Text Analytics Domain ! " + this.currItemType)
	}
		
	this.updateTable();
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
	this.addUndoAction();
	if (item) 
	{
		//var cube = this.getCubeObject();
		var domain = this.getModelDomainObject();
		
		var ok = confirm($$$Text('Do you wish to delete this item?')+'\n');
		if (!ok) {
			return;
		}
	
		switch(type) 
		{
			case '%iKnow.Model.list':
				domain.data.lists.splice(index,1);
				break;
			case '%iKnow.Model.metadataField':
				domain.metadata.fields.splice(index,1);
				break;
			case '%iKnow.Model.parameter':
				domain.parameters.splice(index,1);
				break;
			case '%iKnow.Model.blacklist':
			case '%iKnow.Model.skiplist':
				domain.skiplists.splice(index,1);
				break;
			case '%iKnow.Model.dictionary':
				domain.matching.dictionaries.splice(index,1);
				break;
			case '%iKnow.Model.dictionaryItem':
				item._parent.items.splice(index,1);
				break;
			case '%iKnow.Model.dictionaryTerm':
				item._parent.terms.splice(index,1);
				break;
		}
		//this.updateTable();

		this.removeItem = true;
		this.selectItem('%iKnow.Model.domain',0,true);
		this.updateTable();
	}
	return true;
}

/// User click on disclosure icon in table.
ClientMethod toggleDisclosure2(domain, key, forceOpen = 0) [ Language = javascript ]
{
	if (domain && domain._contracted) {
		if (forceOpen==1) {
			domain._contracted[key] = false;
		} else {
			domain._contracted[key] = !domain._contracted[key];
		}
		if(forceOpen != 2 )
			this.updateTable();
	}
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

Method retreiveSchemas() As %String [ ZenMethod ]
{
	set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:Schemas")
	set tSC = tRS.Execute(0)
	quit:$$$ISERR(tSC)
	set tValueList=""
	while tRS.Next() {
		set tValueList = tValueList_","_tRS.GetData(1)
	}
	quit tValueList
}

Method retreiveTables(pSchema As %String) As %String [ ZenMethod ]
{
	set tRS = ##class(%ResultSet).%New("%SQL.Manager.Catalog:Tables")
	set tSC = tRS.Execute(pSchema)
	quit:$$$ISERR(tSC)
		
	set tValueList=""
	while tRS.Next() {
		set tValueList = tValueList_","_tRS.GetData(1)
	}
	quit tValueList
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	// BDB677 - disable command buttons when no domain def selected
	if ((zenPage.getProperty('domainDefName')==null) || (zenPage.getProperty('domainDefName')=='')) {
		zenPage.disableCommandButton('cmdSave');
		zenPage.disableCommandButton('cmdCompile');
		zenPage.disableCommandButton('cmdBuild');
		zenPage.disableCommandButton('cmdDelete');
	}
}

/// Get the title string to add to the locator row.
/// This should be implemented in a subclass.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return this.domainDefName;
}

}
