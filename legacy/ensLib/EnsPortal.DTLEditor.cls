/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Data Transformation Editor.<br/>
/// Also called from the BPL editor as Request or Response builder.
Class EnsPortal.DTLEditor Extends (EnsPortal.Template.devPage, EnsPortal.Util.CodeEditorBase) [ System = 4 ]
{

/// Displayed name of this page.
Parameter PAGENAME = "Data Transformation Editor";

/// User needs READ permissions on either the %Ens_Code or the %Ens_DTL resource to view this page.
Parameter RESOURCE = "%Ens_Code:READ,%Ens_DTL:READ";

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_DTL resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_Code:WRITE,%Ens_DTL:WRITE";

/// If this page has multiple views, this is its initial display mode.
Parameter DEFAULTVIEWMODE = "both";

Parameter JSINCLUDES = "zenCSLM.js";

/// URL for DT Designer.
Parameter DESIGNERURL As STRING = "EnsPortal.DTLEditor.zen";

Parameter DEFAULTZOOM As %Integer = 100;

/// URL for designer.
Property designerURL As %ZEN.Datatype.string [ InitialExpression = {..#DESIGNERURL} ];

/// Name of Data Transformation to display.
Property dtlId As %String(MAXLEN = 250, ZENURL = "DT");

/// Placeholder for DTL object representation during page load.
Property %dtl As Ens.DTL.Transform;

/// Name of Data Transformation first loaded.
Property originalId As %String [ Internal ];

/// Flag to indicate that the SVG diagram has been loaded.
Property diagramLoaded As %Boolean [ InitialExpression = 0 ];

/// ID (index number, 0-based) of current selected action.
Property currAction As %Integer [ InitialExpression = -1 ];

/// The current zoom level for the SVG diagram.
Property currZoom As %Integer [ InitialExpression = {..#DEFAULTZOOM}, Internal ];

/// Flag to indicate whether the user is permitted to test transforms.
Property canTest As %Boolean [ InitialExpression = {$system.Security.Check("%Ens_DTLTest","USE")} ];

/// If true, the settings area is visible.
Property settingsExpanded As %Boolean [ InitialExpression = 1, Internal ];

/// If true, run in mini-mode.
Property miniMode As %Boolean(ZENURL = "MINI") [ InitialExpression = 0, Internal ];

/// Number of "action" tab (used to give focus to action tab).
Property actionTabNo As %Integer [ InitialExpression = 2, Internal ];

/// Indicated Request or Response.
Property which As %ZEN.Datatype.string(ZENURL = "WHICH");

/// Csv list of properties in BP context (dialog mode).
Property contextList As %ZEN.Datatype.string(MAXLEN = 30000, ZENURL = "CONTEXTLIST");

Property contextTypeList As %ZEN.Datatype.string(MAXLEN = 30000, ZENURL = "CONTEXTTYPELIST");

/// Name of context super class (dialog mode).
Property classContextSuper As %ZEN.Datatype.string(ZENURL = "CONTEXTSUPER");

/// Name of BPL response class (dialog mode).
Property classResponse As %ZEN.Datatype.string(ZENURL = "RESPONSE");

/// Name of BPL request class (dialog mode).
Property classRequest As %ZEN.Datatype.string(ZENURL = "REQUEST");

/// Name of call response class (dialog mode).
Property classCallResponse As %ZEN.Datatype.string(ZENURL = "CALLRESPONSE");

/// Name of call request class (dialog mode).
Property classCallRequest As %ZEN.Datatype.string(ZENURL = "CALLREQUEST");

/// Language from BPL.
Property bplLang As %ZEN.Datatype.string(ZENURL = "LANG");

/// List of actions from BP (dialog mode).
Property actionList As %ZEN.Datatype.string(MAXLEN = 30000, ZENURL = "ACTIONLIST");

Property msgDocReadOnly As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("This data transformation is read only")} ];

Property tipSave As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save this Data Transformation")} ];

Property tipCompile As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Compile this Data Transformation into executable code")} ];

Property tipNew As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Create a new Data Transformation")} ];

Property tipSaveAs As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save this Data Transformation with a new name")} ];

Property tipOpen As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Load an existing Data Transformation")} ];

Property allExpanded As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

Property msgNotGenerated As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("This transformation was not generated")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">

.zenLabel {
	font-size: 12px;
	color: #404040;
	padding-top: 3px;
	padding-left: 1px;
	display: block;
}

.zenHint {
	font-size: 11px;
	color: #606060;
	padding-bottom: 2px;
}

#mainGroup {
	visibility: hidden;
}

#editorPane {
	position: relative;
	border-width: 0px;
}

/* Sequential list of DTL actions */
#dtlTable {
	position: absolute;
	border: 1px solid black;
	overflow: hidden;
	background: #D0D0E0;
}

#dtlTableHeader {
	height: 30px;
	top: 0px;
	background: #F0F0F0;
	overflow: hidden;
}

#dtlTableBody {
	top: 40px;
	height: 200px;
	border: 1px solid black;
	border-left-width: 0px;
	overflow: auto;
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

#propertyPane {
	background: rgb(156,154,141);
	height: 449px;
	width: 400px;
	border-right: 1px solid black;
	border-bottom: 1px solid black;
	visibility: hidden;
}

.DetailLabel {
	color: #404040;
	font-size: 11pt;
	padding-top: 4px;
	padding-bottom: 4px;
	display: block;
}

.DetailType {
	color: #606060;
	font-size: 15pt;
	font-weight: bold;
	padding-top: 4px;
}

#DetailDesc {
	color: #606060;
	font-size: 10pt;
}

.noActivity {
	font-size: 16px;
	color: #606060;
	font-weight: bold;
}

.noActivity2 {
	font-size: 12px;
	color: #606060;
}

.errorTitle {
	color: white;
	border: 1px solid #D0D0D0;
	background: #F04040;
	margin-right:  20px;
	padding: 2px;
	border: 1px solid #D04040;

	border-radius: 4px;
background: -moz-linear-gradient(top, #F04040, #800000);
background: -webkit-linear-gradient(top, #F04040, #800000);
	background: linear-gradient(top, #F04040, #800000);
}

ol.errorList {
	font-size: 12px;
	color: #404040;
}

ol.errorList li {
	margin-bottom: 4px;
}

.noMsg {
	color: #804040;
	font-size: 15pt;
	font-weight: bold;
	padding: 5px;
	width: 50%;
}

/* styles for tabs */
#tabGeneral,#tabDetails {
	overflow: auto;
	padding-left: 3px;
	color: #404040;
}

#propertyCommands {
	color: white;
}

.dtlTableEl {
	width: 100%;
	background: white;
}

table tr.dtlTableHeader {
	text-align: left;
	background: #D0D0E0;
	font-size: 9pt;
	color: #404040;
}

table tr.dtlTableHeader th {
	padding: 2px;
	padding-left: 5px;
	border-bottom: 1px solid #A0A0A0;
	background: #D0D0E0;
	font-size: 9pt;
	color: #404040;
	position: -webkit-sticky;
	position: -moz-sticky;
	position: -ms-sticky;
	position: -o-sticky;
	position: sticky;
	top: 0;
}

.dtlTableEl tr.evenRow {
	background: white;
}

.dtlTableEl tr.oddRow {
	background: #F0F0F6;
}

.dtlTableEl tr.selectedRow {
	color: white;
	background-color: #0066CC;
}

.dtlTableEl tr.disabledRow {
	color: #444;
	background-color: #999;
}

.dtlTableEl tr.evenRowHover {
	background: white;
	color: coral;
}

.dtlTableEl tr.oddRowHover {
	background: #F0F0F6;
	color: coral;
}

.dtlTableEl tr.selectedRowHover {
	background-color: #0066CC;
	color: orange;
}
.dtlTableEl tr.disabledChildRow {
	color: #444;
	background-color: #BBB;
}

.dtlTableEl tr.selectedRow.disabledRow,
.dtlTableEl tr.selectedRow.disabledChildRow {
	color: #BBB;
	background-color: #0033AA;
}

.dtlTableEl tr.evenRowHover.disabledRow,
.dtlTableEl tr.oddRowHover.disabledRow {
	color: #EEE;
	background-color: #999;
}
.dtlTableEl tr.selectedRowHover.disabledRow,
.dtlTableEl tr.selectedRowHover.disabledChildRow {
	color: #EEE;
	background-color: #0033AA;
}
.dtlTableEl tr.evenRowHover.disabledChildRow,
.dtlTableEl tr.oddRowHover.disabledChildRow {
	color: white;
	background-color: #BBB;
}

table.dtlTableEl td {
	padding: 4px;
	padding-left: 5px;
	font-size: 10pt;
}

.actionNo {
	text-align: right;
	vertical-align: bottom;
	color: #808080;
	font-size: 10pt;
}

table td.actionTitle {
	padding-left: 20px;
	padding-right: 20px;
	color: #808080;
	font-size: 10pt;
}

.ribbonSelect {
	color: #404080;
}

#horizBar {
	height: 5px;
	cursor: n-resize;
	border-left: 1px solid black;
	background-color: #B3B3B3;
	background-image: -webkit-linear-gradient(top, #4F4F4F 0%, #CCCCCC 50%, #4F4F4F 100%);
	background-image: linear-gradient(to bottom, #4F4F4F 0%, #CCCCCC 50%, #4F4F4F 100%);
}
#vertBar {
	width: 5px;
	cursor: e-resize;
	border: 1px solid black;
	border-left-width: 0px;
	border-right-width: 0px;
	background-color: #B3B3B3;
	background-image: -webkit-linear-gradient(left, #4F4F4F 0%, #CCCCCC 50%, #4F4F4F 100%);
	background-image: linear-gradient(to right, #4F4F4F 0%, #CCCCCC 50%, #4F4F4F 100%);
}
.resizeBar {
	position: absolute;
	background-color: gray;
	z-index: 50;
}
#svgMask {
	position: absolute;
	z-index: 49;
}
#svgFrameMask {
	filter: alpha(opacity=0);
	background: transparent;
	position: absolute;
	z-index: 48;
}

/* image */
.reIconBar {
	vertical-align: bottom;
}
/* Collapse-Expand image */
.reIconExpandBar {
	width: 20px;
	opacity: .4;
}
.reIconExpand {
	width: 15px;
	opacity: .4;
	vertical-align: middle;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">

<!-- Get DTL transformation in JSON format -->
<jsonProvider id="dtl"
	OnGetTargetObject="GetDTLContent"
	OnSubmitContent="SubmitDTL"
/>
<jsonProvider id="miniModeProvider" OnGetTargetObject="GetMiniModeData" />
<html id="resultsDiv" hidden="true">
<xml id="results" />
</html>
<html id="resizeGroup">
<div id="horizBar" class="resizeBar" style="display: none;"> </div>
<div id="vertBar" class="resizeBar" style="display: none;"> </div>
<div id="svgMask" style="display: none;"> </div>
</html>
<hgroup id="mainGroup" cellVAlign="top">
<vgroup id="editorPane">
<svgFrame id="svg" width="1" height="1" svgPage="EnsPortal.SVG.DTLDiagram">
<parameter id="svgStudioMode" paramName="STUDIO" value="" />
</svgFrame>
<vgroup id="dtlTable">
<html id="dtlTableHeader"></html>
<html id="dtlTableBody"></html>
</vgroup>
</vgroup>
<vgroup id="propertyPane">
<html id="propertyTitle"><span id="spanArrow" title="Hide or show the properties box" onclick="zenPage.toggleSettings();" onmouseover="this.style.color='#FFEEAA';" onmouseout="this.style.color='';">&#187;</span></html>
<tabGroup id="propertyTabs" showTabBar="true">
<tab caption="Transform" id="tabGeneral" layout="none">
<form id="generalForm" cellStyle="padding-left:3px;">
<label labelClass="DetailLabel" label="Details for the overall data transformation"/>

<text id="generalName" label="Name" size="50" disabled="true" readOnly="true" controlClass="readOnlyControl" onchange="zenPage.generalChange('Name');" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<select id="generalCreate" label="Create" valueList="new,copy,existing" required="true" showEmpty="false" disabled="true" onchange="zenPage.generalChange('Create');" title="Specify the behavior when a new target object is created"/>

<hgroup cellVAlign="top" label="Source Class">
<text id="generalSourceClass" size="50" disabled="true" onchange="zenPage.generalChange('SourceClass');" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.selectType('source_class');" title="Select new source class"/>
</hgroup>

<hgroup cellVAlign="top" label="Source Doc Type">
<text id="generalSourceDocType" size="50" disabled="true" onchange="zenPage.generalChange('SourceDocType');" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.selectType('source_doctype');" title="Select new source document type"/>
</hgroup>

<hgroup cellVAlign="top" label="Target Class" >
<text id="generalTargetClass" size="50" disabled="true" onchange="zenPage.generalChange('TargetClass');" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.selectType('target_class');" title="Select new target class"/>
</hgroup>

<hgroup cellVAlign="top" label="Target Doc Type" >
<text id="generalTargetDocType" size="50" disabled="true" onchange="zenPage.generalChange('TargetDocType');" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.selectType('target_doctype');" title="Select new target document type"/>
</hgroup>

<select id="generalLanguage" label="Language" valueList="objectscript,basic,python" required="true" showEmpty="false" disabled="true" onchange="zenPage.generalChange('Language');" title="Language used by transform expressions"/>

<hgroup id="gPyFromImportGroup" cellVAlign="top" hidden="true">
<textarea id="gPyFromImport" label="Python From / Import statements" rows="5" cols="40" disabled="true" hint="Optional list of Python 'from' and 'import' statements supporting modules available to all Python sub-contexts" onchange="zenPage.generalChange('pyFromImport');" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('gPyFromImport','code');" title="Launch the value editor"/>
</hgroup>



<checkbox id="generalReportErrors" label="Report Errors" disabled="true" title="Modify the value of the REPORTERRORS parameter" value="1" onchange="zenPage.generalChange('ReportErrors');"/>
<checkbox id="generalIgnoreMissingSource" label="Ignore missing source segments and properties" disabled="true" title="Modify the value of the IGNOREMISSINGSOURCE parameter" value="1" onchange="zenPage.generalChange('IgnoreMissingSource');"/>
<checkbox id="generalTreatEmptyAsNull" label="Treat empty repeating fields as null" disabled="true" title="Modify the value of the TREATEMPTYREPEATINGFIELDASNULL parameter" value="0" onchange="zenPage.generalChange('TreatEmptyAsNull');"/>
<checkbox id="generalGenerateEmptySegments" label="Allow empty segments in target" disabled="true" title="Modify the value of the GENERATEEMPTYSEGMENTS parameter" value="0" onchange="zenPage.generalChange('GenerateEmptySegments');"/>


<textarea id="generalDescription" label="Description" cols="35" rows="4" disabled="true" onchange="zenPage.generalChange('Annotation');" title="Description of this transform" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<spacer height="10"/>
</form>
</tab>
<tab caption="Action" id="tabDetails" layout="none">
<form id="actionForm" cellStyle="padding-left:3px;">
<label labelClass="DetailLabel" label="Details for the selected action"/>
<html id="detailDesc"/>
<html id="errorBox"/>
<select id="detailAction" label="Action" valueList="set,clear,remove,append,insert" required="true" showEmpty="false" disabled="true" onchange="zenPage.detailChange('detailAction');"/>
<text id="detailProperty" label="Property" size="48" disabled="true" onchange="zenPage.detailChange();" hint="Property whose value will be set. Double-clicking on a target property in the diagram will place that property in this field." onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<select id="detailLanguageOverride" label="Language Override" disabled="true" valueList="python,objectscript" displayList="Python,ObjectScript" showEmpty="true" onchange="zenPage.detailChange();"/>



<hgroup id="detailValueGroup" cellVAlign="top" label="Value" hint="Value to assign to the property. Double-clicking on a source property in the diagram will place that property in this field.">
<text id="detailValue" size="48" disabled="true" onchange="zenPage.detailChange();" onblur="zenPage.detailBlur(zenThis);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image id="detailValueLaunch" src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('detailValue','code');" title="Launch the value editor"/>
</hgroup>

<hgroup id="detailCodeGroup" cellVAlign="top" label="Code" hint="Code to execute">
<textarea id="detailCode" cols="40" rows="10" onchange="zenPage.detailChange();" onkeypress="return zenPage.codeKeyPress(zenThis,zenEvent,zenPage.getActionLanguage());" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('detailCode','code');" title="Launch the value editor"/>
</hgroup>


<hgroup id="detailSQLGroup" cellVAlign="top" label="SQL" hint="SQL statement to execute">
<textarea id="detailSQL" cols="40" rows="5" onchange="zenPage.detailChange();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('detailSQL','sql');" title="Launch the value editor"/>
</hgroup>

<hgroup id="detailConditionGroup" cellVAlign="top" label="Condition" >
<text id="detailCondition" size="40" disabled="true" onchange="zenPage.detailChange();" onblur="zenPage.detailBlur(zenThis);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('detailCondition','code');" title="Launch the value editor"/>
</hgroup>

<hgroup id="detailClassGroup" cellVAlign="top" label="Transform Class" >
<text id="detailClass" size="40" disabled="true" onchange="zenPage.detailChange();" title="Name of data transformation class" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.selectTransformClass();" title="Select a data transformation class"/>
</hgroup>
<text id="detailSourceObj" label="Source Property" size="40" onchange="zenPage.detailChange();" hint="Name of property providing the object or segments to be transformed. Double-clicking on a source property in the diagram will place that property in this field." onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<text id="detailTargetObj" label="Target Property" size="40" onchange="zenPage.detailChange();" hint="Name of property or segment in which to place the results. Double-clicking on a target property in the diagram will place that property in this field." onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<text id="detailAux" label="Auxiliary Property" size="40" onchange="zenPage.detailChange();" hint="The value to be supplied as the aux argument to a subtransform" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);" />
<text id="detailKey" label="Key" size="15" disabled="true" onchange="zenPage.detailChange();" hint="For collection properties, this string specifies the member of the collection that is the target of this assignment." onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<text id="detailLoopKey" label="Key" size="15" disabled="true" onchange="zenPage.detailChange();" hint="Name of the iterator variable used for this loop." onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<checkbox id="detailLoopUnload" label="Unload" onchange="zenPage.detailChange();" hint="Open object(s)/segment(s) for the Property collection will be unloaded/unswizzled at the end of each loop. Unsaved VDoc Segments will be saved and finalised." />

<checkbox id="detailDisabled" label="Disabled" onchange="zenPage.detailChange();" hint="Control whether this action and its children should be disabled." />
<textarea id="detailAnnotation" label="Description" cols="40" rows="4" disabled="true" onchange="zenPage.detailChange();" title="Description of this action"  onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<spacer height="10"/>
</form>
</tab>
<tab caption="Tools" id="tabTools" title="Tools for working with Data Transformations." layout="none">
<vgroup enclosingStyle="padding: 5px;" cellStyle="padding-left:3px;">
<label labelClass="DetailLabel" label="Tools for working with Data Transformations"/>

<hgroup cellStyle="padding: 10px;" cellVAlign="top">
<image src="portal/software_development_48.gif"/>
<vgroup>
<button id="testTransformButton" caption="Test" controlClass="commandButton" title="Test this Data transformation." onclick="zenPage.toolTestDT();"/>
<label label="Test this Data Transformation."/>
</vgroup>
</hgroup>
<hgroup cellStyle="padding: 10px;" cellVAlign="top" id="grpTestDTLGenerator">
<image src="portal/software_development_48.gif"/>
<vgroup>
<button id="testDTLGenerator" caption="DTL Generator" controlClass="commandButton" title="DTL Generator" onclick="zenPage.dtlGenerator();"/>
<label label="DTL generator"/>
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
	If (..miniMode) {
		Quit $case(..which, "Request": $$$Text("Request"), "Response": $$$Text("Response"), : $$$Text("Call"))
	}
	If (..dtlId="") {
		Quit $$$Text("Data Transformation")
	}
	Quit $P(..dtlId,".",1,$L(..dtlId,".")-1)
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String, Output pCommands As %List) As %Status
{
	If (..miniMode) {
		Set pDisplay = 1
		Set pSearchBox = 0
		Set pRibbonTitle = $$$Text("Call Builder")

		Set pCommands(1) = $LB("cmdOK",$$$Text("OK"),$$$Text("Apply changes"),"zenPage.applyChanges(); return false;")
		Set pCommands(2) = $LB("cmdCancel",$$$Text("Cancel"),$$$Text("Cancel changes"),"zenPage.cancelChanges(); return false;")
	}
	Else {
		Set pDisplay = 1
		Set pSearchBox = 0

		If '..studioMode {
			// commands
			// $LB(id,caption,help,onclick)
			If $system.Security.Check("%Ens_Code","WRITE") || $system.Security.Check("%Ens_DTL","WRITE") {
				Set pCommands(1) = $LB("cmdNew",$$$Text("New"),..tipNew,"zenPage.newDT(); return false;")
				Set pCommands(3) = $LB("cmdSave",$$$Text("Save"),..tipSave,"zenPage.saveDT(false); return false;")
				Set pCommands(4) = $LB("cmdSaveAs",$$$Text("Save As"),..tipSaveAs,"zenPage.saveDT(true); return false;")
				Set pCommands(5) = $LB("cmdCompile",$$$Text("Compile"),..tipCompile,"zenPage.compile(); return false;")
			}
			Set pCommands(2) = $LB("cmdOpen",$$$Text("Open"),..tipOpen,"zenPage.loadDT(); return false;")
		}
	}

	Set pViewIcons(1) = $LB("both",$$$Text("Show both views"),"portal/view_dtl_both.png")
	Set pViewIcons(2) = $LB("diagram",$$$Text("Show transform diagram"),"portal/view_dtl_diagram.png")
	Set pViewIcons(3) = $LB("table",$$$Text("Show action list"),"portal/view_dtl_table.png")

	Quit $$$OK
}

/// Add content to ribbon bar.
Method OnDrawRibbon() As %Status
{
	&html<<td nowrap="1" valign="middle">>

	Set hlpZoom = $$$TextHTML("Set the size of the diagram")
	Set msgAdd = $$$TextHTML("Add Action")
	Set hlpAdd = $$$TextHTML("Add a new action to the transformation")

	#dim tDividerID = "MENUHEADER"
	#dim tDivider As %String = ""
	Set tDivider(1)=$$$TextHTML("Assign Actions")
	Set tDivider(2)=$$$TextHTML("Conditional Actions")
	Set tDivider(3)=$$$TextHTML("Advanced Actions")
	Set tDivider(4)=$$$TextHTML("Annotation Actions")

	&html<<table>>
	&html<<tr>>

	&html<<td width="24">&nbsp;</td>>

	// zoom
	Set tSvg = ..%GetComponentById("svg")

	&html<<td>>
	&html<<select id="selectZoom" class="ribbonSelect" title="#(hlpZoom)#" onchange="zenPage.setZoom(this.value);">>
	For tZoom = 50,60,75,85,100,110,125,150,200 {
		&html<<option value="#(tZoom)#" #($S(..currZoom=tZoom:"selected=""1""",1:""))#>&nbsp;#(tZoom_"%")#&nbsp;</option>>
	}
	&html<</select>>
	&html<</td>>

	&html<<td width="24">&nbsp;</td>>

	// list of actions
	// tAction(n) = $LB(tDividerID,tHeaderDivider #) || ""
	// OR
	// tAction(n) = $LB(name,caption,title) || ""
	Set tAction($I(n)) = $LB(tDividerID,1)
	Set tAction($I(n)) = $LB("set",$$$Text("set"),$$$Text("Add an assignment action"))
	Set tAction($I(n)) = $LB("clear",$$$Text("clear"),$$$Text("Add a clear action"))
	Set tAction($I(n)) = $LB("remove",$$$Text("remove"),$$$Text("Add a remove action"))
	Set tAction($I(n)) = $LB("append",$$$Text("append"),$$$Text("Add an append action"))
	Set tAction($I(n)) = $LB("insert",$$$Text("insert"),$$$Text("Add an insert action"))
	If '..miniMode {
		Set tAction($I(n)) = $LB(tDividerID,2)
		Set tAction($I(n)) = $LB("if",$$$Text("if"),$$$Text("Add an if block"))
		Set tAction($I(n)) = $LB("for each",$$$Text("for each"),$$$Text("Add a for each block"))
		Set tAction($I(n)) = $LB("break",$$$Text("break"),$$$Text("Add a break to exit a for each block or quit the transform"))
		Set tAction($I(n)) = $LB("switch",$$$Text("switch"),$$$Text("Add a switch block"))
		Set tAction($I(n)) = $LB("case",$$$Text("case"),$$$Text("Add a case condition in a switch block"))
		Set tAction($I(n)) = $LB(tDividerID,3)
		Set tAction($I(n)) = $LB("code",$$$Text("code"),$$$Text("Add a Code statement"))
		Set tAction($I(n)) = $LB("sql",$$$Text("sql"),$$$Text("Add an SQL statement"))
		Set tAction($I(n)) = $LB("trace",$$$Text("trace"),$$$Text("Add a trace statement"))
		Set tAction($I(n)) = $LB("subtransform",$$$Text("subtransform"),$$$Text("Add a call to another data transformation (a subtransformation)"))
		Set tAction($I(n)) = $LB(tDividerID,4)
		Set tAction($I(n)) = $LB("group",$$$Text("group"),$$$Text("Add a block to display actions as a group"))
		Set tAction($I(n)) = $LB("comment",$$$Text("comment"),$$$Text("Add a comment"))
	}

	&html<<td>>
	&html<<select id="selectNewAction" class="ribbonSelect" title="#(hlpAdd)#" onchange="zenPage.addNewAction();">>
	&html<<option value="" style="display:none;">&nbsp;-#(msgAdd)#-&nbsp;</option>>
	Set k = $O(tAction(""))
	While (k'="") {
		If $LG(tAction(k),1)=tDividerID{
			// action divider
			If $Data(tDivider(+$LG(tAction(k),2)),tCaption){
				Set tCaption = "&nbsp;-"_tCaption_"-&nbsp;"
			} Else {
				Set tCaption = ""
			}
			&html<<option value="-1" disabled="1">#(tCaption)#</option>>
		}
		Else {
			Set tName = $LG(tAction(k),1)
			Set tCaption = $LG(tAction(k),2)
			Set tTitle = $LG(tAction(k),3)
			&html<<option value="#(tName)#" title="#($ZCVT(tTitle,"O","HTML"))#">&nbsp;#($ZCVT(tCaption,"O","HTML"))#&nbsp;</option>>
		}
		Set k = $O(tAction(k))
	}
	&html<</select>>
	&html<</td>>

	// icons
	Set hlpUndo = $$$Text("Undo last action")
	Set hlpDelete = $$$Text("Remove the selected action")
	Set hlpCopy = $$$Text("Copy the selected action")
	Set hlpPaste = $$$Text("Paste last deleted or copied action")

	&html<<td nowrap="1">>
	&html<<image width="24" src="images/spacer.gif"/>>
	&html<<image id="iconDelete" class="reIconDisabled" title="#(hlpDelete)#" src="deepsee/close_a_24.png" onclick="zenPage.removeAction();"/>>
	&html<&nbsp;>
	&html<<image id="iconCopy" class="reIconDisabled" title="#(hlpCopy)#" src="portal/copy_24.gif" onclick="zenPage.copyAction();"/>>
	&html<&nbsp;>
	&html<<image id="iconPaste" class="reIconDisabled" title="#(hlpPaste)#" src="portal/paste_24.gif" onclick="zenPage.pasteAction();"/>>
	&html<&nbsp;>
	&html<<image id="iconUndo" class="reIconDisabled" title="#(hlpUndo)#" src="portal/loop_24.gif" onclick="zenPage.undo();"/>>
	&html<</td>>

	&html<</tr>>
	&html<</table>>
	&html<</td>>
	Quit ##super()
}

/// Update icons on the toolbar to reflect current state.
ClientMethod updateToolbar() [ Internal, Language = javascript ]
{
	var canmod = this.canEdit && !this.readOnly;
	var action = this.getCurrentAction();

	var icon = self.document.getElementById('iconDelete');
	if (icon) {
		icon.className = (canmod && action) ? 'reIcon' : 'reIconDisabled';
	}
	var icon = self.document.getElementById('iconCopy');
	if (icon) {
		icon.className = (canmod && action) ? 'reIcon' : 'reIconDisabled';
	}
	var icon = self.document.getElementById('iconPaste');
	if (icon) {
		icon.className = (canmod && action && (zenPage._pasteBuffer)) ? 'reIcon' : 'reIconDisabled';
	}
	var icon = self.document.getElementById('iconUndo');
	if (icon) {
		icon.className = (this.canUndo()) ? 'reIcon' : 'reIconDisabled';
	}
}

/// Render the action header.
ClientMethod updateActionHeader() [ Internal, Language = javascript ]
{
	var html = [];

	// icon bar
	var hlpUp = $$$Text("Move selected item up one position");
	var hlpDown = $$$Text("Move selected item down one position");
	var hlpIn = $$$Text("Move the selected item into the next block of actions");
	var hlpOut = $$$Text("Move the selected item out of the current block of actions");
	var hlpRemove = $$$Text('Remove the selected action');

	var hlpRemoveAll = $$$Text("Remove all actions");
	var hlpCopy = $$$Text("Copy the selected action");
	var hlpPaste = $$$Text("Paste last deleted or copied action");
	var hlpCollapseAll = $$$Text("Collapse All Groups");
	var hlpExpandAll = $$$Text("Expand All Groups");

	html.push('<table><tr>');
	html.push('<td class="actionTitle" title="'+$$$Text("List of actions displayed in the order in which they are applied")+'">' + $$$Text("Actions") + '</td>');
	html.push('<td nowrap="1"><div class="reIconBar">');

	var dtl = zenPage.getDTLObject();
	var canmod = this.canEdit && !this.readOnly;
	var action = this.getCurrentAction();
	var canMoveUp = false;
	var canMoveDown = false;
	var canMoveIn = false;
	var canMoveOut = false;
	var canRemoveAll = false;

	// A switch's default cannot be moved
	// If in a case or default cannot move out
	if (dtl && canmod && action && (action._class !== 'Ens.DTL.Default')) {
		var isPseudoAction = (action._class == 'endif') || (action._class == 'endeach') || (action._class == 'else') || (action._class == 'endswitch');
		if (action._class == 'Ens.DTL.Case') {
			canMoveUp = (action._index > 0);
		} else {
			// can move up if not first action OR is first action inside a group unless in case/default
			if (!isPseudoAction) {
				if (action._index > 0) {
					canMoveUp = true;
				} else if (!action._parent || ((action._parent._class !== 'Ens.DTL.Case')&&(action._parent._class !== 'Ens.DTL.Default'))) {
					canMoveUp = (action._depth > 0);
				}
			}
		}
		var parentGroup = dtl.Actions;
		if ((action._parent != null) && (action._parentProp != null) && (action._parent[action._parentProp] != null)) {
			parentGroup = action._parent[action._parentProp];
		}
		if (action._class == 'Ens.DTL.Case') {
			//Case cannot move below Default
			var lowestIdx = parentGroup.length - 1
			if (parentGroup[lowestIdx]._class == 'Ens.DTL.Default') {
				lowestIdx = lowestIdx - 1;
			}
			canMoveDown = (action._index < lowestIdx);
		} else {
			// can move down if not last action OR is last action inside a group unless in case/default
			if (!isPseudoAction && parentGroup) {
				if (action._index < (parentGroup.length - 1)) {
					canMoveDown = true;
				} else if (!action._parent || ((action._parent._class !== 'Ens.DTL.Case')&&(action._parent._class !== 'Ens.DTL.Default'))) {
					canMoveDown =(action._depth > 0);
				}
			}
			canMoveOut = (action._parent && !isPseudoAction &&(action._parent._class !== 'Ens.DTL.Case') && (action._parent._class !== 'Ens.DTL.Default') && (action._class !== 'Ens.DTL.Case'));
			if (canMoveDown && (action._index != -1) && !isPseudoAction) {
				var nextAction = parentGroup[action._index+1];
				canMoveIn = (nextAction && ((nextAction._class == 'Ens.DTL.If') || (nextAction._class == 'Ens.DTL.ForEach') || (nextAction._class == 'Ens.DTL.Group')) && (action._class !== 'Ens.DTL.Case'));
			}
		}
	}

	if (dtl && canmod && this._actionIndex && (this._actionIndex.length > 0)) {
		canRemoveAll = true;
	}

	html.push(this.getIconHTML(canMoveUp,'deepsee/ds_up_24.gif',hlpUp,'zenPage.moveItemUp();'));
	html.push(this.getIconHTML(canMoveDown,'deepsee/ds_down_24.gif',hlpDown,'zenPage.moveItemDown();'));
	html.push(this.getIconHTML(canMoveOut,'deepsee/ds_back_24.gif',hlpOut,'zenPage.moveItemOut();'));
	html.push(this.getIconHTML(canMoveIn,'deepsee/ds_forward_24.gif',hlpIn,'zenPage.moveItemIn();'));
	html.push('&nbsp;&nbsp;&nbsp;');
	html.push(this.getIconHTML((canmod && action && this.canRemoveAction(action)),'deepsee/close_a_24.png',hlpRemove,'zenPage.removeAction();'));
	html.push('&nbsp;&nbsp;&nbsp;');
	html.push(this.getIconHTML((canmod && action),'portal/copy_24.gif',hlpCopy,'zenPage.copyAction();'));
	html.push('&nbsp;&nbsp;&nbsp;');
	var canPaste = (!!this._pasteBuffer)&&(canmod);
	html.push(this.getIconHTML(canPaste,'portal/paste_24.gif',hlpPaste,'zenPage.pasteAction();'));
	html.push('</div></td>');
	html.push('<td nowrap="1" width="100%" align="right">');
	var iconCollapse = 'images/arrow1D.gif';
	var iconExpand = 'images/arrow1R.gif';
	var expanded = ('undefined' == typeof this.allExpanded) ? true : this.allExpanded;
	if (expanded) {
		html.push('<img class="reIconExpandBar"'+' src="' + iconCollapse + '" title="' + hlpCollapseAll + '" onclick="zenPage.toggleExpandAll(false,true);" />');
	}
	else {
		html.push('<img class="reIconExpandBar"'+' src="' + iconExpand + '" title="' + hlpExpandAll + '" onclick="zenPage.toggleExpandAll(true,true);" />');
	}
	html.push('&nbsp;&nbsp;&nbsp;');
	html.push('&nbsp;&nbsp;&nbsp;');
	html.push(this.getIconHTML(canRemoveAll,'deepsee/delete_24.png',hlpRemoveAll,'zenPage.removeAllActions();'));
	html.push('&nbsp;&nbsp;&nbsp;');
	html.push('&nbsp;&nbsp;&nbsp;');

	html.push('</div></td></tr></table>');

	var header = zen('dtlTableHeader');
	header.setContent(html.join(''));
}

/// Get html to create an icon.
ClientMethod getIconHTML(enabled, img, help, click) [ Internal, Language = javascript ]
{
	// we of course have to do extra work for ie
	if (!enabled) {
		return '<img class="reIconDisabled" title="'+help+'" src="'+img+'" />';
	}
	return '<img class="reIcon" title="'+help+'" src="'+img+'" onclick="'+click+'" onmouseover="this._oldClass=this.className;this.className=\'reIconHover\';" onmouseout="this.className=this._oldClass;"/>';
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		if (load && this.miniMode) {
			// minimode (called from BPL)
			// build action list from BPL
			this._actionList = [];

			var opener = this.getOpener();
			if (opener && opener.zenPage && opener.zenPage.getCurrShape) {
				// get action list from BPL shape
				var shape = opener.zenPage.getCurrShape();
				var shapeModel = shape ? shape.model : null;
				if (shapeModel && shapeModel[this.which] && shapeModel[this.which].Activities) {
					var activities = shapeModel[this.which].Activities;
					for (var n = 0; n < activities.length; n++) {
						var action = activities[n];

						// note: we prepend source and target to property references
						var propExpr = action.Property.toString();
						propExpr = propExpr.split('').reverse().join('');
						var valueExpr = action.Value.toString();
						valueExpr = valueExpr.split('').reverse().join('');

						var mainObject = '';
						if (this.which == 'Request') {
							// mainObject for core properties is source
							mainObject = 'ecruos';
							// callrequest
							propExpr = propExpr.replace(/((tseuqerllac)$)|(tseuqerllac(?=[^A-Za-z0-9\.\%]))/g,'tseuqerllac.tegrat');
							valueExpr = valueExpr.replace(/((tseuqerllac)$)|(tseuqerllac(?=[^A-Za-z0-9\.\%]))/g,'tseuqerllac.tegrat');
						}
						else if (this.which == 'Response') {
							// mainObject for core properties is target
							mainObject = 'tegrat';
							// callresponse
							propExpr = propExpr.replace(/(esnopserllac)$|(esnopserllac(?=[^A-Za-z0-9\.\%]))/g,'esnopserllac.ecruos');
							valueExpr = valueExpr.replace(/(esnopserllac)$|(esnopserllac(?=[^A-Za-z0-9\.\%]))/g,'esnopserllac.ecruos');
						}
						if (mainObject != '') {
							// context
							propExpr = propExpr.replace(/((txetnoc)$)|(txetnoc(?=[^A-Za-z0-9\.\%]))/g,'txetnoc.' + mainObject);
							valueExpr = valueExpr.replace(/((txetnoc)$)|(txetnoc(?=[^A-Za-z0-9\.\%]))/g,'txetnoc.' + mainObject);
							// request
							propExpr = propExpr.replace(/(tseuqer)$|(tseuqer(?=[^A-Za-z0-9\.\%]))/g,'tseuqer.' + mainObject);
							valueExpr = valueExpr.replace(/(tseuqer)$|(tseuqer(?=[^A-Za-z0-9\.\%]))/g,'tseuqer.' + mainObject);
							// response
							propExpr = propExpr.replace(/(esnopser)$|(esnopser(?=[^A-Za-z0-9\.\%]))/g,'esnopser.' + mainObject);
							valueExpr = valueExpr.replace(/(esnopser)$|(esnopser(?=[^A-Za-z0-9\.\%]))/g,'esnopser.' + mainObject);
						}
						propExpr = propExpr.split('').reverse().join('');
						valueExpr = valueExpr.split('').reverse().join('');

						var newAction = {
							_class:'Ens.DTL.Assign',
							Action:action.Action,
							Annotation:action.Annotation,
							Key:action.Key,
							Property:propExpr,
							Value:valueExpr
						};
						this._actionList.push(newAction);
					}
					// Ensure we re-render the diagram using the new action list
					this.diagramLoaded = false;
				}
			}
		}

		if (load) this.initUIConstraints();

		if (!this.diagramLoaded) {
			if (load && !this.getSVGWindow() && !(!!document.createElementNS && !! document.createElementNS(SVGNS, "svg").createSVGRect)) {
				alert($$$Text('Unable to load SVG diagram. Please ensure your browser is supported for portal access.'));
			}
			else {
				this.initializeSVG(true);
			}
		}

		this.adjustSizes();

		if (load) {
			this.initDragBars();

			var mainDiv = zen('mainGroup').getEnclosingDiv();
			mainDiv.style.visibility = 'visible';

			var tableDiv = zen('dtlTableBody').getEnclosingDiv();
			tableDiv.scrollTop = 0;

			this.selectAction(-1, true);
			if (!this.miniMode) {
				this.raiseEvent('LOADCOMPLETE',1);
			}
			else {
				var opener = this.getOpener();
				if (opener && opener.zenPage) {
					this.setReadOnly(opener.zenPage.readOnly);
					if (typeof opener.zenPage.raiseEvent == 'function') opener.zenPage.raiseEvent('LOADCOMPLETE',0);
				}
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

ClientMethod onSVGLoad() [ Language = javascript ]
{
	this.initializeSVG(false);
}

ClientMethod initializeSVG(noAdjust) [ Language = javascript ]
{
	this.checkStudioHyperEvents();

	// initialize zoom level, restoring last value for this user/document
	// we need call this when the SVG is first rendered, but after we call checkStudioHyperEvents()
	if (this.dtlId && this.dtlId !='') {
		this.currZoom = this.FetchZoomFromServer(this.dtlId);
	}
	this.setZoom(this.currZoom,true);

	var svgWin = this.getSVGWindow();
	if (svgWin && svgWin.setTarget) {
		var dtl = zenPage.getDTLObject();
		if (dtl) {
			// build index of actions
			this.decorateActionList(dtl.Actions);

			// initialize contents of diagram
			svgWin.setDTLModel(dtl,this._actionIndex);
			svgWin.setSource(dtl.SourceClass,dtl.SourceDocType);
			svgWin.setTarget(dtl.TargetClass,dtl.TargetDocType);
			svgWin.loadTransform(dtl.Language);
			this.updateGeneralForm();
		}
		this.diagramLoaded = true;
		this.setReadOnly(this.readOnly || !this.canEdit);
	}
	if (!noAdjust) this.adjustSizes();
}

ClientMethod initUIConstraints() [ Language = javascript ]
{
	if (!this._mins) {
		this._mins = {
				"SVG": {
					"height": 200,
					"width": 200,
					"canvasWidth": 500
				},
				"DTLTable": {
					"height": 200,
				},
				"Properties": {
					"width": 300
				}
			};
	}
}

ClientMethod initDragBars() [ Language = javascript ]
{
	var horizBar = document.getElementById('horizBar');
	var vertBar = document.getElementById('vertBar');
	if (horizBar.addEventListener) {
		horizBar.addEventListener('mousedown',function(event) { ZLM.drag(this,event); });
		vertBar.addEventListener('mousedown',function(event) { ZLM.drag(this,event); });
	}
	else {
		ZLM.setLocalAttribute(horizBar,'onmousedown','ZLM.drag(this,event);');
		ZLM.setLocalAttribute(vertBar,'onmousedown','ZLM.drag(this,event);');
	}
	var horizManager = {
		"minY": 0,
		"maxY": 0,
		"startX": 0,
		"startY": 0,
		"startDrag": zenPage.horizStartDrag,
		"endDrag": zenPage.horizEndDrag,
		"constrainDragX": function() {
			return this.startX;
		},
		"constrainDragY": function(mgr,wrapper,intendedY) {
			if (intendedY < this.minY) {
				return this.minY;
			}
			if (intendedY > this.maxY) {
				return this.maxY;
			}
			return intendedY;
		}
	};
	horizBar.wrapper = ZLM.registerDragItem(horizBar,horizManager);

	var vertManager = {
		"minX": 0,
		"maxX": 0,
		"startX": 0,
		"startY": 0,
		"startDrag": zenPage.vertStartDrag,
		"endDrag": zenPage.vertEndDrag,
		"constrainDragX": function(mgr,wrapper,intendedX) {
			if (intendedX < this.minX) {
				return this.minX;
			}
			if (intendedX > this.maxX) {
				return this.maxX;
			}
			return intendedX;
		},
		"constrainDragY": function() {
			return this.startY;
		}
	};
	vertBar.wrapper = ZLM.registerDragItem(vertBar,vertManager);

	var addResizeBorders = true;
	// check if the gradient background-image values were processed
	if (document.defaultView && document.defaultView.getComputedStyle) {
		var compStyle = document.defaultView.getComputedStyle(horizBar);
		if (compStyle && compStyle.getPropertyValue) {
			var bgImage = compStyle.getPropertyValue('background-image');
			addResizeBorders = (bgImage == '') || (bgImage == 'none');
		}
		delete compStyle;
	}
	if (addResizeBorders) {
		horizBar.style.borderTop = '1px solid #333';
		horizBar.style.borderBottom = '1px solid #333';
		horizBar.style.height = '3px';
		vertBar.style.borderLeft = '1px solid #333';
		vertBar.style.borderRight = '1px solid #333';
		vertBar.style.width = '3px';
	}
}

/// Function to handle the start of a drag for the horizontal bar between the SVG and table items.
/// The main work is to determine the initial location of the bar, as well as the maximum reach of the
/// bar so that the constrainDragX and constrainDragY callbacks can correctly limit the drag.
/// This code also invokes <method>showSVGMask</method>() to ensure that we correctly handle mouse events
/// in this window and not in the SVG diagram window.
ClientMethod horizStartDrag(mgr, wrapper) [ Language = javascript ]
{
	ZLM.killBrowserSelectionProcess();
	var titleHeight = zenPage.getTitleAreaHeight();
	var winHeight = zenGetWindowHeight();
	this.maxY = winHeight - zenPage._mins.DTLTable.height;
	this.minY = titleHeight + zenPage._mins.SVG.height;
	this.startX = zenGetLeft(wrapper.node);
	this.startY = zenGetTop(wrapper.node);
	zenPage.showSVGMask();
}

/// Function to handle the completion of horizontal bar drags, which adjusts the height of the SVG and
/// table wrapper elements. It also removes the svgMask that is placed in front of the SVG during the drag.
/// Note that <var>this</var> refers to the drag manager, and NOT the zenPage object.
ClientMethod horizEndDrag(mgr, wrapper) [ Language = javascript ]
{
	var svgMask = document.getElementById('svgMask');
	svgMask.style.display = 'none';
	if (svgMask.iframe) svgMask.iframe.style.display = 'none';

	var endY = zenGetTop(wrapper.node);
	var yChange = endY - this.startY;
	var remProps = [
		zen('dtlTable').getEnclosingDiv(),
		zen('dtlTableBody').getEnclosingDiv()
	];
	zenPage.shiftElements(remProps,'height',-yChange);
	var svg = zen('svg');
	var svgHeight = svg.getProperty('height');
	svg.setProperty('height',svgHeight + yChange);
}

/// Helper method to move the svgMask div in front of SVG to ensure the mouse events
/// aren't pushed through to the SVG window and lost to the ZLM drag handling in
/// this window. 
ClientMethod showSVGMask() [ Language = javascript ]
{
/// Under IE, we also push in an iframe to make IE behave well with the embedded SVG.
	var editDiv = zen('editorPane').getEnclosingDiv();
	var svgMask = document.getElementById('svgMask');
	svgMask.style.display = 'block';
	svgMask.style.left = zenGetLeft(editDiv) + 'px';
	svgMask.style.top = zenGetTop(editDiv) + 'px';
	svgMask.style.height = Math.max(editDiv.clientHeight,editDiv.offsetHeight) + 'px';
	svgMask.style.width = Math.max(editDiv.clientWidth,editDiv.offsetWidth) + 'px';
	if (zenIsIE) {
		var iframe = svgMask.iframe;
		if (!iframe) {
			iframe = document.createElement('iframe');
			svgMask.iframe = iframe;
			iframe.setAttribute('id','svgFrameMask');
		}
		iframe.src = '';
		iframe.frameBorder = 0;
		iframe.style.display = 'block';
		iframe.style.left = svgMask.style.left;
		iframe.style.top = svgMask.style.top;
		iframe.style.height = svgMask.style.height;
		iframe.style.width = svgMask.style.width;
		svgMask.parentNode.insertBefore(iframe,svgMask);
	}
}

/// Function to handle the start of a drag for the vertical bar between the editor and property panes.
/// The main work is to determine the initial location of the bar, as well as the maximum reach of the
/// bar so that the constrainDragX and constrainDragY callbacks can correctly limit the drag.
/// This code also invokes <method>showSVGMask</method>() to ensure that we correctly handle mouse events
/// in this window and not in the SVG diagram window.
ClientMethod vertStartDrag(mgr, wrapper) [ Language = javascript ]
{
	ZLM.killBrowserSelectionProcess();
	var winWidth = zenGetWindowWidth();
	this.maxX = winWidth - zenPage._mins.Properties.width;
	this.minX = zenPage._mins.SVG.width;
	this.startX = zenGetLeft(wrapper.node);
	this.startY = zenGetTop(wrapper.node);
	zenPage.showSVGMask();
}

/// Function to handle the completion of vertical bar drags and adjust the width of various
/// elements that have explicit widths. It also removes the svgMask that is placed in front
/// of the SVG during the drag.
/// Note that <code>this</var> refers to the drag manager, and NOT the zenPage object.
ClientMethod vertEndDrag(mgr, wrapper) [ Language = javascript ]
{
	var svgMask = document.getElementById('svgMask');
	svgMask.style.display = 'none';
	if (svgMask.iframe) svgMask.iframe.style.display = 'none';

	var endX = zenGetLeft(wrapper.node);
	var xChange = endX - this.startX;
	var addProps = [
		zen('editorPane').getEnclosingDiv(),
		zen('dtlTable').getEnclosingDiv(),
		zen('dtlTableHeader').getEnclosingDiv(),
		zen('dtlTableBody').getEnclosingDiv(),
		document.getElementById('horizBar')
	];
	zenPage.shiftElements(addProps,'width',xChange);
	var remProps = [
		zen('propertyPane').getEnclosingDiv(),
		zen('propertyTabs').findElement('body')
	];
	zenPage.shiftElements(remProps,'width',-xChange);
	var svg = zen('svg');
	var svgWidth = svg.getProperty('width');
	svg.setProperty('width',svgWidth + xChange);
	var svgSVGWidth = Math.max(zenPage._mins.SVG.canvasWidth, xChange + svg.getProperty('svgWidth'));
	svg.setProperty('svgWidth',svgSVGWidth);
	var svgWin = zenPage.getSVGWindow();
	if (svgWin && svgWin.setCanvasWidth) svgWin.setCanvasWidth(svgSVGWidth);
	zenPage.resizeFormControls();
	if (Math.abs(xChange) > 15) {
		zenPage.updateTable();
	}
}

/// Helper method to allow a list of elements to have the CSS property specified in
/// <var>cssProp</var> to be modified by the increment in <var>change</var>. The method is
/// used to move elements around in response to the delta from a dragged bar.
ClientMethod shiftElements(elements, cssProp, change) [ Language = javascript ]
{
	if ((!elements) || (!elements.length) || (!cssProp) || (!change)) return;
	for (var i = 0; i < elements.length; i++) {
		var el = elements[i];
		if (el && el.style) {
			var currVal = parseInt(el.style[cssProp],10);
			if (!isNaN(currVal)) {
				el.style[cssProp] = (currVal + change) + 'px';
			}
		}
	}
}

/// Helper method to increase or decrease the size of the text
/// controls in the property pane when the pane's size changes.
ClientMethod resizeFormControls() [ Language = javascript ]
{
	var propertyTabs = zen('propertyTabs');
	var tabBody = propertyTabs.findElement('body');
	var tabWidth = parseInt(tabBody.style.width,10);
	var forms = ['actionForm'];
	if (!this.miniMode) {
		forms.push('generalForm');
	}
	for (var i = 0; i < forms.length; i++) {
		var controls = zen(forms[i]).getControlList();
		for (var j = 0; j < controls.length; j++) {
			var control = controls[j];
			if ((control._type == 'text') || (control._type == 'textarea')) {
				var input = control.findElement('control');
				if (input && input.style) input.style.width = (tabWidth - 70) + 'px';
			}
		}
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		this.initUIConstraints();
		var horizBar = document.getElementById('horizBar');
		var vertBar = document.getElementById('vertBar');
		var propDiv = zen('propertyPane').getEnclosingDiv();
		var editDiv = zen('editorPane').getEnclosingDiv();
		var tableDiv = zen('dtlTable').getEnclosingDiv();
		var proptitleDiv = zen('propertyTitle').getEnclosingDiv();
		var proptabsDiv = zen('propertyTabs').getEnclosingDiv();
		var tableHdrDiv = zen('dtlTableHeader').getEnclosingDiv();
		var tableBodyDiv = zen('dtlTableBody').getEnclosingDiv();

		// make property sheet visible
		propDiv.style.visibility = 'visible';

		var svg = zen('svg');
		var svgDiv = svg.getEnclosingDiv();

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();

		var propWidth = 40;
		if (this.settingsExpanded) {
			propWidth = (winWidth<1100) ? 300 : 400;
		}
		propDiv.style.width = propWidth + 'px';

		var th = this.getTitleAreaHeight();
		var tableHgt = 0;
		var scroll =  ((zenBody.scrollWidth == zenBody.offsetWidth) && (zenBody.scrollLeft == 0 )) ? 0 :1;
		var hgt = winHeight - th - 10 - 10*scroll;
		var svgHgt = 0;
		var svgWid = 1;
		var horizBarDisplay = '';
		var vertBarDisplay = '';
		if (this.settingsExpanded) {
			svgWid = winWidth - propDiv.offsetWidth - 25;
		}
		else {
			svgWid = winWidth - 50;
			vertBarDisplay = 'none';
		}

		switch (this.currViewMode) {
		case 'table':
			tableHgt = hgt;
			tableDiv.style.display = '';
			svgHgt = 0;
			horizBarDisplay = 'none';
			break;
		case 'diagram':
			tableDiv.style.display = 'none';
			tableHgt = 0;
			svgHgt = hgt - 1 - tableHgt;
			horizBarDisplay = 'none';
			break;
		case 'both':
		default:
			tableHgt = Math.max(this._mins.DTLTable.height,Math.floor(hgt*0.35));
			svgHgt = hgt - 1 - tableHgt;
			tableDiv.style.display = '';
			break;
		}
		if (svgHgt < 0) {
			svgHgt = 100;
		}

		editDiv.style.width = svgWid + 'px';
		tableDiv.style.height = tableHgt + 'px';
		tableDiv.style.width = svgWid + 'px';
		tableHdrDiv.style.width = svgWid + 'px';
		tableBodyDiv.style.width = svgWid + 'px';
		if (tableHgt > 0) {
			tableBodyDiv.style.height = tableHgt - tableHdrDiv.offsetHeight + 'px';
		}

		propDiv.style.height = hgt+1 + 'px';
		var svgCanvasWid = Math.max(this._mins.SVG.canvasWidth,svgWid);

		if (this.settingsExpanded) {
			var tabBodyHgt = (hgt - proptitleDiv.offsetHeight - 31);
			var tabGroup = zen('propertyTabs');
			tabGroup.setBodySize(tabBodyHgt,propDiv.offsetWidth- 3);
			tabGroup.setHidden(false);
			if (tabGroup.autoSizeH) {
				tabGroup.autoSizeH = false;
			}
		}
		else {
			zen('propertyTabs').setHidden(true);
		}
		
		horizBar.style.display = horizBarDisplay;
		horizBar.style.width = (svgWid) + 'px';
		horizBar.style.left = '4px';
		horizBar.style.top = (th + hgt - tableHgt) + 'px';

		vertBar.style.display = vertBarDisplay;
		vertBar.style.left = (4 + svgWid) + 'px';
		vertBar.style.top = (th + 1.5) + 'px';
		vertBar.style.height =  (hgt + 1) + 'px';

		if (null == this._percent) {
			svg.setProperty('height',svgHgt);
			svg.setProperty('width',svgWid);
			svg.setProperty('svgWidth',svgCanvasWid);

			// set size of svg components in the diagram
			// test for minimum size
			var svgWin = this.getSVGWindow();
			if (svgWin) {
				svgWin.setCanvasWidth(svgCanvasWid);
			}

			this.updateTable();
			this.updateActionHeader();
			this.updateToolbar();
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Update the contents of the dtl "action" table.
ClientMethod updateTable() [ Language = javascript ]
{
	var table = zen('dtlTableBody');
	var html = new Array();
	var dtl = this.getDTLObject();

	if (dtl) {
		// Implement a simple heuristic for specifying the maximum number of characters to display for the property, value and key columns
		// Note that the value can fall either side of the previous default of 40.
		var wrapperDiv = table.getEnclosingDiv();
		var cutoffPoint = 900;
		var wrapperWidth = (wrapperDiv && wrapperDiv.style ? parseInt(wrapperDiv.style.width,10) : cutoffPoint);
		if (isNaN(wrapperWidth)) wrapperWidth = cutoffPoint;
		var textCutoff = 40 + (Math.floor((wrapperWidth - cutoffPoint)/50) * 3);
		var hlpRemove = $$$Text('Remove this action');
		var hlpContract = $$$Text('Collapse this group');
		var hlpExpand = $$$Text('Expand this group');

		// create table of actions
		html.push('<table class="dtlTableEl" border="0" cellpadding="0" cellspacing="0">');
		html.push('<thead>');
		html.push('<tr class="dtlTableHeader">');
		html.push('<th width="25px" style="text-align:right;">' + '#&nbsp;' + '</th>');
		html.push('<th>' + $$$Text('Action') + '</th>');
		html.push('<th>' + $$$Text('Condition') + '</th>');
		html.push('<th>' + $$$Text('Property') + '&nbsp;</th>');
		html.push('<th>' + $$$Text('Value') + '&nbsp;</th>');
		html.push('<th>' + $$$Text('Key') + '&nbsp;/&nbsp;' + $$$Text('Transform')+ '&nbsp;</th>');
		html.push('<th>' + '&nbsp;' + '</th>');
		html.push('<th width="5%">' + '&nbsp;</th>');
		html.push('</tr>');
		html.push('</thead>');
		var mayRemove = (!this.readOnly && this.canEdit);
		if (this._actionIndex) {
			/* Account for hidden lines so as to maintain zebra */
			var nDisplayed = 0;

			/*	Account for loading stored expanded attribute from xml
				since ._display for children of collapsed nodes is undefined
			*/
			var inCollapsed = false;
			var lastInCollapsedGroup = '';

			for (var n = 0; n < this._actionIndex.length; n++) {
				var action = this._actionIndex[n];
				var errs = this.validateAction(action);

				var cls = (action.Disabled ? 'disabledRow ' : '');
				if (this.checkActionDisabled(action) == 2) {
					// depends on parent?
					cls += 'disabledChildRow ';
				}
				if (n == this.currAction) {
					cls += 'selectedRow';
				}
				else if (nDisplayed%2) {
					cls += 'oddRow';
				}
				else {
					cls += 'evenRow'
				}
				var idx = n;
				var click = ' ';
				click = ' onclick="zenPage.selectAction('+idx+');"';

				var prop = '';
				var cond = '';
				var value = '';
				var key = '';
				var canRemove = true;
				var canCollapseExpand = false;
				var iconCollapse = 'images/arrow1D.gif';
				var iconExpand = 'images/arrow1R.gif';
				var expandClick = '';

				switch (action._class) {
				case 'Ens.DTL.Assign':
					prop = action.Property;
					value = action.Value;
					key = action.Key;
					break;
				case 'Ens.DTL.Trace':
					value = action.Value;
					break;
				case 'Ens.DTL.Code':
					value = action.Code.toString();
					break;
				case 'Ens.DTL.SQL':
					value = action.SQL.toString();
					break;
				case 'Ens.DTL.ForEach':
					prop = action.Property;
					key = action.Key;
					canCollapseExpand = true;
					break;
				case 'Ens.DTL.SubTransform':
					prop = action.TargetObj;
					value = action.SourceObj;
					key = action.Class;
					break;
				case 'Ens.DTL.If':
					cond = action.Condition;
					canCollapseExpand = true;
					break;
				case 'Ens.DTL.Break':
					break;
				case 'Ens.DTL.Comment':
					//show description in Condition column
					cond = action.Annotation;
					break;
				case 'Ens.DTL.Switch':
					canCollapseExpand = true;
					break;
				case 'Ens.DTL.Case':
					action.LanguageOverride = action._parent.LanguageOverride
					cond = action.Condition;
					canCollapseExpand = true;
					break;
				case 'Ens.DTL.Default':
					canRemove = false;
					canCollapseExpand = true;
					break;
				case 'Ens.DTL.Group':
					canRemove = true;
					canCollapseExpand = true;
					//show description in Condition column
					cond = action.Annotation;
					break;
				case 'endif':
				case 'endeach':
				case 'endswitch':
				case 'endgroup':
					canRemove = false;
					break;
				case 'else':
					canRemove = false;
					break;
				default:
					canRemove = false;
					break;
				}

				// May have nested canCollapseExpand
				var expanded = true;
				var display = true;

				if (canCollapseExpand) {
					expanded = ('undefined' == typeof action.Expanded) ? true : action.Expanded;
				}

				if (inCollapsed) {
					action._display=false;
				} else {
					action._display=true;
				}
				/* See if last in collapsed group so can reset inCollapsed */
				if (inCollapsed) {
					if (action == lastInCollapsedGroup) {
						inCollapsed = false;
						lastInCollapsedGroup = '';
					}
				} else if (canCollapseExpand) {
					/* Examine if an inner collapsed group and remember parent */
					if (!expanded) {
						/* find last object in collapsed group */
						lastInCollapsedGroup = this.lastInGroup(action);
						if (lastInCollapsedGroup) {inCollapsed = true;}
					}
				}

				display = action._display;
				var condTitle = zenEscapeHTML(cond);
				var propTitle = zenEscapeHTML(prop);
				var valueTitle = zenEscapeHTML(value);
				var keyTitle = zenEscapeHTML(key);
				var condCutoff = textCutoff * 3;
				cond = (cond.length > condCutoff ? cond.substring(0,condCutoff) + '...' : cond);
				var propCutoff = (action._class == 'Ens.DTL.ForEach' ? textCutoff * 2 : textCutoff);
				prop = (prop.length > propCutoff ? prop.substring(0,propCutoff) + '...' : prop);
				value = (value.length > textCutoff ? value.substring(0,textCutoff) + '...' : value);
				key = (key.length > textCutoff ? key.substring(0,textCutoff) + '...' : key);

				var rowStyle = (errs && errs.length > 0) ? 'color: red; font-weight: bold;' : '';

				var actionStyle = '';
				if ((action._class=='endgroup') || (action._class=='Ens.DTL.Group') || (action._class=='Ens.DTL.Comment')) {
					actionStyle += 'font-style: oblique;';
				} else {
					actionStyle += 'font-weight:bold;';
				}
				if (action._depth) {
					actionStyle += 'padding-left:' + (action._depth*15) + 'px;';
				}
				if (display) {
					nDisplayed += 1;
					html.push('<tr id="row_'+(idx)+'" style="'+rowStyle+'" class="'+cls+'" onmouseover="zenPage.toggleRowHover(this);" onmouseout="zenPage.toggleRowHover(this);">');
					html.push('<td width="20px" class="actionNo"  '+click+'>' + (idx+1) + '</td>');
					if (canCollapseExpand) {
						if (expanded) {
							expandClick = '<img src="' + iconCollapse + '" class="reIconExpand" title="' + hlpContract + '" onclick="zenPage.toggleExpand('+n+',false,true);" />'
						}
						else {
							expandClick = '<img src="' + iconExpand + '" class="reIconExpand" title="' + hlpExpand + '" onclick="zenPage.toggleExpand('+n+',true,true);" />'
						}
					}
					else {
						expandClick = '';
					}
					var actionTitle = '';
					if (action._class=='Ens.DTL.Group') {
						if (action.Annotation !='') {
							actionTitle = zenEscapeHTML(action.Annotation);
						}
					}
					var actionDisplay = zenPage.getActionType(action);
					if ((action._class=='Ens.DTL.Comment') && (action.Annotation!='')) {
							actionDisplay += ': ';
					}
					html.push('<td '+click+' nowrap="1" style="'+actionStyle+'" title="'+actionTitle+'">' + actionDisplay + expandClick +'</td>');
					if (cond != '') {
						var condStyle = '';
						if ((action._class=='Ens.DTL.Group') || (action._class=='Ens.DTL.Comment')) {
							condStyle += ' Style="font-style: oblique;"';
						}
						html.push('<td '+click+' nowrap="1" title="'+condTitle+'" colspan="4"' + condStyle+ '>' + zenEscapeHTML(cond) + '&nbsp;</td>');
					}
					else {
						html.push('<td '+click+' nowrap="1">&nbsp;</td>');
						if ((action._class == 'Ens.DTL.ForEach') && (value === '')) {
							html.push('<td '+click+' nowrap="1" title="'+propTitle+'" colspan="2">' + zenEscapeHTML(prop) + '&nbsp;</td>');
						}
						else {
							html.push('<td '+click+' nowrap="1" title="'+propTitle+'">' + zenEscapeHTML(prop) + '&nbsp;</td>');
							html.push('<td '+click+' nowrap="1" title="'+valueTitle+'">' + zenEscapeHTML(value) + '&nbsp;</td>');
						}
						html.push('<td '+click+' nowrap="1" title="'+keyTitle+'">' + zenEscapeHTML(key) + '&nbsp;</td>');
					}
					html.push('<td '+click+'>' + '&nbsp;</td>');
					html.push('</tr>');
				}
			}
		}
		html.push('</table>');
	}
	else {
		html.push('<div class="noMsg">');
		html.push($$$Text('No data transformation is loaded.'));
		html.push('<br/>');
		html.push($$$Text('Use the Open button to open an existing transformation or use the New button to create a new transformation.'));
		html.push('</div>');
	}
	table.setContent(html.join(''));
}

/// Return the dtl transform object.
ClientMethod getDTLObject() [ Language = javascript ]
{
	if (this.miniMode) {
		// return local action list from BPL
		var dtl = {
			_class:'Ens.DTL.Transform',
			Actions:[],
			Annotation:"",
			Create:"new",
			Language:this.BPLLang
		};
		if (this._actionList) {
			dtl.Actions = this._actionList;
		}
		else { // ensure we create a valid action list
			this._actionList = dtl.Actions;
		}

	}
	else {
		var json = this.getComponentById('dtl');
		var dtl = json.getContentObject();
	}
	this.updateJSONSCReadOnly(dtl);
	return dtl;
}

/// Return current selected action, if any.
ClientMethod getCurrentAction() [ Language = javascript ]
{
	var item = this._actionIndex && (this.currAction>=0) ? this._actionIndex[this.currAction] : null;
	return item;
}

/// Return the current name of the class/object being modified
ClientMethod getCurrentName() [ Language = javascript ]
{
	var name = zenPage.dtlId;
	if (name.substring(name.length - 4).toLowerCase() == '.dtl') {
		name = name.substring(0, name.length - 4);
	}
	return name;
}

ClientMethod getClientModel() [ Language = javascript ]
{
	return zen('dtl');
}

/// Update actions in dtl diagram.
ClientMethod updateDiagramActions(keepSelected) [ Language = javascript ]
{
	var svgWin = this.getSVGWindow();
	var dtl = zenPage.getDTLObject();
	svgWin.setDTLModel(dtl,this._actionIndex);
	svgWin.loadTransform(dtl.Language);
	if (keepSelected) { // make sure we keep the selected action highlighted in the SVG
		svgWin.selectAction(this.currAction,false);
	}
}

ClientMethod addClass(element, cls) [ Language = javascript ]
{
	if ((!element) || (!cls)) return;
	var currClasses = ('' + element.className).split(' ');
	if (currClasses.indexOf(cls) == -1) {
		currClasses.push(cls);
		element.className = currClasses.join(' ');
		return true;
	}
	return false;
}

ClientMethod removeClass(element, cls) [ Language = javascript ]
{
	if ((!element) || (!cls)) return;
	var currClasses = ('' + element.className).split(' ');
	var pos = currClasses.indexOf(cls);
	var found = (pos > -1);
	while (pos > -1) {
		currClasses.splice(pos,1);
		pos = currClasses.indexOf(cls);
	}
	if (found) element.className = currClasses.join(' ');
	return found;
}

/// Select a DTL action.
ClientMethod selectAction(index, force, notify, tabChange) [ Language = javascript ]
{
	notify = ('undefined' == typeof notify) ? true : notify;
	tabChange = ('undefined' == typeof tabChange) ? true : tabChange;

	if (tabChange) {
		// force details tab to front
		zen('propertyTabs').showTab(this.actionTabNo);
	}

	if (this.currAction != index || force) {
		// unhighlight
		var trow = self.document.getElementById('row_' + this.currAction);
		this.removeClass(trow,'selectedRow');
		var wasHover = this.removeClass(trow,'selectedRowHover');
		this.addClass(trow,(this.currAction%2 ? 'oddRow' : 'evenRow') + (wasHover ? 'Hover' : ''));
		this.currAction = index;

		var item = this.getCurrentAction();
		// highlight row in action table
		var trow = self.document.getElementById('row_' + this.currAction);
		if (trow) {
			var wasHover = false;
			this.removeClass(trow,'oddRow');
			this.removeClass(trow,'evenRow');
			if (this.removeClass(trow,'oddRowHover')) wasHover = true;;
			if (this.removeClass(trow,'evenRowHover')) wasHover = true;;
			this.addClass(trow,'selectedRow' + (wasHover ? 'Hover' : ''));
			trow._oldClass = trow.className;

			// make sure row is visible
			var table = zen('dtlTableBody');
			zenScrollIntoView(table.getEnclosingDiv(),trow);
		}

		// set contents of detail form
		var show = { "Action": false, "Annotation": false, "Aux": false, "ClassGroup": false, "CodeGroup": false,
					"Condition": false, "ConditionGroup": false, "Disabled": false, "Key": false, "LoopKey": false, "LoopUnload": false, "Property": false,
					"SourceObj": false, "SQLGroup": false, "TargetObj": false, "Value": false, "ValueGroup": false, "LanguageOverride": false };

		var html = [];

		if (!item) {
			html.push('<div class="noActivity">'+$$$Text('No action selected')+'</div>');
			html.push('<div class="noActivity2">'+$$$Text('Select an action (connecting line) within the diagram using the mouse.')+'</div>');
			html.push('<div class="noActivity2">'+$$$Text('Alternatively, you can select an item in the Actions table beneath the diagram.')+'</div>');
		}
		else {
			switch(item._class) {
			case 'Ens.DTL.Assign':
				show.Action = true;
				zen('detailAction').setValue(item.Action);

				html.push(this.getActionDesc('assign',item.Action));

				
				zen('detailProperty').setProperty('hint',$$$Text('Property whose value will be set.')+' '+$$$Text('Double-clicking on a target property in the diagram will place that property in this field.'));
				zen('detailProperty').setValue(item.Property);
				show.Property = true;
				zen('detailLanguageOverride').setValue(item.LanguageOverride);
				show.LanguageOverride = true;

				if ((item.Action == 'clear') || (item.Action == 'remove')) {
					zen('detailValue').setValue('');
					zen('detailValueGroup').setHidden(true);
				}
				else {
					show.Value = true;
					zen('detailValue').setValue(item.Value);
					show.ValueGroup = true;
					zen('detailValueGroup').setProperty('hint',$$$Text('Value to assign to the property.')+' '+$$$Text('Double-clicking on a property in the diagram will place that property in this field.'));
				}

				zen('detailKey').setValue(item.Key);
				show.Key = true;

				zen('detailAnnotation').setValue(item.Annotation);
				show.Annotation = true;

				zen('detailDisabled').setValue(item.Disabled);
				show.Disabled = !this.miniMode;
				break;

			case 'Ens.DTL.Trace':
				html.push(this.getActionDesc('trace'));

				zen('detailValue').setValue(item.Value);
				show.Value = true;
				zen('detailValueGroup').setProperty('hint',$$$Text('Contents of the trace message this action will add to the Event Log.')+' '+$$$Text('Double-clicking on a property in the diagram will place that property in this field.'));
				show.ValueGroup = true;

				zen('detailAnnotation').setValue(item.Annotation);
				show.Annotation = true;

				zen('detailDisabled').setValue(item.Disabled);
				show.Disabled = true;

				zen('detailLanguageOverride').setValue(item.LanguageOverride);
				show.LanguageOverride = true;

				break;

			case 'Ens.DTL.SQL':
				html.push(this.getActionDesc('SQL'));

				show.SQLGroup = true;
				zen('detailSQL').setValue(item.SQL);

				zen('detailAnnotation').setValue(item.Annotation);
				show.Annotation = true;

				zen('detailDisabled').setValue(item.Disabled);
				show.Disabled = true;
				break;

			case 'Ens.DTL.Code':
				html.push(this.getActionDesc('code'));

				show.CodeGroup = true;
				zen('detailCode').setValue(item.Code);

				zen('detailLanguageOverride').setValue(item.LanguageOverride);
				show.LanguageOverride = true;

				zen('detailAnnotation').setValue(item.Annotation);
				show.Annotation = true;

				zen('detailDisabled').setValue(item.Disabled);
				show.Disabled = true;
				break;

			case 'Ens.DTL.If':
				html.push(this.getActionDesc('if'));

				zen('detailCondition').setValue(item.Condition);
				show.Condition = true;
				show.ConditionGroup = true;

				zen('detailAnnotation').setValue(item.Annotation);
				show.Annotation = true;

				zen('detailDisabled').setValue(item.Disabled);
				show.Disabled = true;

				zen('detailLanguageOverride').setValue(item.LanguageOverride);
				show.LanguageOverride = true;

				break;

			case 'Ens.DTL.ForEach':
				html.push(this.getActionDesc('foreach'));

				show.Property = true;
				show.LoopKey = true;
				show.LoopUnload = true;

				zen('detailProperty').setProperty('hint',$$$Text('Property to iterate over.')+' '+$$$Text('Double-clicking on a property in the diagram will place that property in this field.'));

				zen('detailProperty').setValue(item.Property);
				zen('detailLoopKey').setValue(item.Key);
				zen('detailLoopUnload').setValue(item.Unload);

				zen('detailAnnotation').setValue(item.Annotation);
				show.Annotation = true;

				zen('detailDisabled').setValue(item.Disabled);
				show.Disabled = true;
				break;

			case 'Ens.DTL.Break':
				html.push(this.getActionDesc('break'));

				zen('detailAnnotation').setValue(item.Annotation);
				show.Annotation = true;

				zen('detailDisabled').setValue(item.Disabled);
				show.Disabled = true;
				break;

			case 'Ens.DTL.Comment':
				html.push(this.getActionDesc('comment'));

				zen('detailAnnotation').setValue(item.Annotation);
				show.Annotation = true;

				break;

			case 'Ens.DTL.SubTransform':
				html.push(this.getActionDesc('subtransform'));

				show.Aux = true;
				show.ClassGroup = true;
				show.TargetObj = true;
				show.SourceObj = true;

				zen('detailClass').setValue(item.Class);
				zen('detailTargetObj').setValue(item.TargetObj);
				zen('detailSourceObj').setValue(item.SourceObj);
				zen('detailAux').setValue(item.Aux);

				zen('detailAnnotation').setValue(item.Annotation);
				show.Annotation = true;

				zen('detailDisabled').setValue(item.Disabled);
				show.Disabled = true;
				break;

			case 'Ens.DTL.Switch':
				html.push(this.getActionDesc('switch'));

				zen('detailAnnotation').setValue(item.Annotation);
				show.Annotation = true;

				zen('detailDisabled').setValue(item.Disabled);
				show.Disabled = true;

				zen('detailLanguageOverride').setValue(item.LanguageOverride);
				show.LanguageOverride = true;

				break;

			case 'Ens.DTL.Case':
				html.push(this.getActionDesc('case'));

				zen('detailCondition').setValue(item.Condition);
				show.Condition = true;
				show.ConditionGroup = true;

				zen('detailAnnotation').setValue(item.Annotation);
				show.Annotation = true;

				zen('detailDisabled').setValue(item.Disabled);
				show.Disabled = true;
				break;

			case 'Ens.DTL.Default':
				html.push(this.getActionDesc('default'));

				zen('detailAnnotation').setValue(item.Annotation);
				show.Annotation = true;

				zen('detailDisabled').setValue(item.Disabled);
				show.Disabled = true;
				break;

			case 'Ens.DTL.Group':
				html.push(this.getActionDesc('group'));

				zen('detailAnnotation').setValue(item.Annotation);
				show.Annotation = true;

				zen('detailDisabled').setValue(item.Disabled);
				show.Disabled = true;
				break;

			case 'else':
			case 'endif':
			case 'endeach':
			case 'endswitch':
			case 'endgroup':
				html.push(this.getActionDesc(item._class));
				break;
			default:
				break;
			}
		}
		var ebox = zen('errorBox');
		var errs = this.validateAction(item);
		if (errs.length > 0) {
			ehtml = [];
			ehtml.push('<hr/>');
			ehtml.push('<div class="errorTitle">'+$$$Text('This item is not valid')+'</div>');
			ehtml.push('<ol class="errorList">');
			for (var n = 0; n < errs.length; n++) {
				ehtml.push('<li>' + errs[n] + '</li>');
			}
			ehtml.push('</ol>');
			ehtml.push('<hr/>');
			ebox.setContent(ehtml.join(''));
		}
		else {
			ebox.setContent('');
		}

		// update display of controls
		for (var controlName in show) {			
			var control = zen('detail'+controlName);
			if (control) control.setHidden(!show[controlName]);
		}

		zen('detailDesc').setContent(html.join(''));

		this.updateActionHeader();
		this.updateToolbar();

		if (notify) {
			// highlight action in diagram
			var svgWin = this.getSVGWindow();
			if (svgWin) {
				svgWin.selectAction(this.currAction);
			}
		}
	}
}

/// Update contents of general settings form.
ClientMethod updateGeneralForm() [ Language = javascript ]
{
	var dtl = this.getDTLObject();
	if (dtl && !this.miniMode) {
		zen('generalName').setValue(this.dtlId);
		zen('generalName').setProperty('disabled',false);

		zen('generalCreate').setValue(dtl.Create);
		zen('generalCreate').setProperty('disabled',false);

		zen('generalLanguage').setValue(dtl.Language);
		zen('generalLanguage').setProperty('disabled',false);

		zen('generalSourceClass').setValue(dtl.SourceClass);
		zen('generalSourceClass').setProperty('disabled',false);

		zen('generalSourceDocType').setValue(dtl.SourceDocType);
		zen('generalSourceDocType').setProperty('disabled',false);

		zen('generalTargetClass').setValue(dtl.TargetClass);
		zen('generalTargetClass').setProperty('disabled',false);

		zen('generalTargetDocType').setValue(dtl.TargetDocType);
		zen('generalTargetDocType').setProperty('disabled',false);

		zen('generalReportErrors').setValue(dtl.ReportErrors);
		zen('generalReportErrors').setProperty('disabled',this.studioMode);

		zen('generalIgnoreMissingSource').setValue(dtl.IgnoreMissingSource);
		zen('generalIgnoreMissingSource').setProperty('disabled',this.studioMode);

		zen('generalTreatEmptyAsNull').setValue(dtl.TreatEmptyAsNull);
		zen('generalTreatEmptyAsNull').setProperty('disabled',this.studioMode);

		zen('generalGenerateEmptySegments').setValue(dtl.GenerateEmptySegments);
		zen('generalGenerateEmptySegments').setProperty('disabled',this.studioMode);

		zen('generalDescription').setValue(dtl.Annotation);
		zen('generalDescription').setProperty('disabled',false);

		if (dtl.pyFromImport == 'undefined') {dtl.pyFromImport = ""}
		zen('gPyFromImport').setValue(dtl.pyFromImport);
		zen('gPyFromImport').setProperty('disabled',false);
		zen('gPyFromImportGroup').setProperty('hidden',false);

		if (this.studioMode) {
			zen('generalReportErrors').setProperty('title',$$$Text('The Studio DTL Editor cannot modify this property.') + ' ' + $$$Text('The value can be modified in the class definition.'));
			zen('generalIgnoreMissingSource').setProperty('title',$$$Text('The Studio DTL Editor cannot modify this property.') + ' ' + $$$Text('The value can be modified in the class definition.'));
			zen('generalTreatEmptyAsNull').setProperty('title',$$$Text('The Studio DTL Editor cannot modify this property.') + ' ' + $$$Text('The value can be modified in the class definition.'));
			zen('generalGenerateEmptySegments').setProperty('title',$$$Text('The Studio DTL Editor cannot modify this property.') + ' ' + $$$Text('The value can be modified in the class definition.'));

		}
	}
	else {
		//zen('generalName').setProperty('disabled',true);
	}
}

/// Change to item in general form.
ClientMethod generalChange(which) [ Language = javascript ]
{
	var dtl = this.getDTLObject();
	if (!dtl) return;
	this._textMonitor.reset();
	this.addUndoAction();

	switch(which) {
	case 'Name':
		// !!dtl.Name = zen('generalName').getValue();
		break;
	case 'Create':
		dtl.Create = zen('generalCreate').getValue();
		break;
	case 'ReportErrors':
		dtl.ReportErrors = (zen('generalReportErrors').getValue() ? 1 : 0);
		break;
	case 'IgnoreMissingSource':
		dtl.IgnoreMissingSource = (zen('generalIgnoreMissingSource').getValue() ? 1 : 0);
		break;
	case 'TreatEmptyAsNull':
		dtl.TreatEmptyAsNull = (zen('generalTreatEmptyAsNull').getValue() ? 1 : 0);
		break;
	case 'GenerateEmptySegments':
		dtl.GenerateEmptySegments = (zen('generalGenerateEmptySegments').getValue() ? 1 : 0);
		break;
	case 'Language':
		if (confirm($$$Text('If you change languages you must change all expressions within this transformation. Are you sure you want to do this?'))) {
			dtl.Language = zen('generalLanguage').getValue();

			var imports=zenPage.getComponentById("gPyFromImportGroup");
			imports.setProperty('hidden',false);
			zen('gPyFromImport').setProperty('disabled',false);
			
		}
		else {
			zen('generalLanguage').setValue(dtl.Language);
		}
		break;
	case 'SourceClass':
	case 'SourceDocType':
		var cls = zen('generalSourceClass').getValue();
		var type = zen('generalSourceDocType').getValue();
		this.setClassAndType(true, cls, type);
		break;
	case 'TargetClass':
	case 'TargetDocType':
		var cls = zen('generalTargetClass').getValue();
		var type = zen('generalTargetDocType').getValue();
		this.setClassAndType(false, cls, type);
		break;
	case 'pyFromImport':
		dtl.pyFromImport = zen('gPyFromImport').getValue();
		break;
	case 'Annotation':
		dtl.Annotation = zen('generalDescription').getValue();
		break;
	default:
		alert('general change: unhandled type in generalChange: ' + which);
		break;
	}
	this.setModified(true);
}

/// Change to item in detail form.
ClientMethod detailChange(which) [ Language = javascript ]
{
	if (this._textMonitor) {
		if (this._textMonitor.processing) {
			return;
		}
		this._textMonitor.processing = true;
	}
	var currActionIndex = this.currAction;
	if ('undefined' != typeof which && 'detailAction' == which) {
		var html = this.getActionDesc('assign',zen('detailAction').getValue());
		zen('detailDesc').setContent(html);
	}
	this._textMonitor.reset();
	this.applyDetailForm();
	this._textMonitor.processing = false;
}

/// Get description for an action.
ClientMethod getActionDesc(type, actionType) [ Language = javascript ]
{
	var html = [];
	var hasHelp = true;

	html.push('<div class="DetailType">' + type + '</div>');

	var text = '';
	switch(type) {
	case 'assign':
		switch(actionType) {
		case 'set':
			text = $$$Text('Set the value of a target property.');
			break;
		case 'clear':
			text = $$$Text('Clear the value of a target property.');
			break;
		case 'remove':
			text = $$$Text('Remove a collection item from the target property.');
			break;
		case 'append':
			text = $$$Text('Append a collection item to the target property.');
			break;
		case 'insert':
			text = $$$Text('Insert a collection item into the target property.');
			break;
		}
		break;
	case 'if':
		text = $$$Text('Evaluate a condition.');
		break;
	case 'foreach':
		text = $$$Text('Loop over the contents of a collection.');
		break;
	case 'break':
		text = $$$Text('Break out of a for each loop or quit the transform. ');
		break;
	case 'comment':
		text = $$$Text('A comment for display purposes only. ');
		break;
	case 'subtransform':
		text = $$$Text('Invoke a data transformation to convert a source segment to a target segment.');
		break;
	case 'code':
		text = $$$Text('Execute lines of custom code.');
		break;
	case 'trace':
		text = $$$Text('Write a trace message.');
		break;
	case 'SQL':
		text = $$$Text('Execute an embedded SQL statement.');
		break;
	case 'else':
		hasHelp = false;
		text = $$$Text('Start of the false branch of an If block.');
		break;
	case 'endif':
		hasHelp = false;
		text = $$$Text('End of an if block.');
		break;
	case 'endeach':
		hasHelp = false;
		text = $$$Text('End of a foreach block.');
		break;
	case 'switch':
		text = $$$Text('Evaluate in order a set of conditions to determine which one of several actions to perform.');
		break;
	case 'case':
		text = $$$Text('Evaluate a single condition within a switch block.');
		break;
	case 'default':
		text = $$$Text('Default action within a switch block.');
		break;
	case 'endswitch':
		hasHelp = false;
		text = $$$Text('End of a switch block.');
		break;
	case 'group':
		text = $$$Text('Organize a group of actions for display purposes only.');
		break;
	case 'endgroup':
		hasHelp = false;
		text = $$$Text('End of a group block.');
		break;
	default:
		break;
	}
	html.push(text);

	if (hasHelp) {
		html.push('<div class="activityDesc"/><a class="portalTitleLink" onclick="zenPage.showActionDoc(\''+type+'\');return false;" href="#">'+$$$Text('View documentation')+'</a></div>');
	}

	return html.join('');
}

/// Apply changes from detail form.
ClientMethod applyDetailForm() [ Language = javascript ]
{
	var ebox = zen('errorBox');
	var dtl = this.getDTLObject();
	var item = this.getCurrentAction();
	if (!item) {
		ebox.setContent('');
	}
	else {
		this.addUndoAction();
		switch(item._class) {
		case 'Ens.DTL.Assign':
			item.Action = zen('detailAction').getValue();
			item.Property = zen('detailProperty').getValue();
			if ((item.Action == 'clear') || (item.Action == 'remove')) {
				item.Value = '';
				zen('detailValue').setValue('');
				zen('detailValue').setHidden(true);
				zen('detailValueGroup').setHidden(true);
			}
			else {
				item.Value = zen('detailValue').getValue();
				zen('detailValue').setHidden(false);
				zen('detailValueGroup').setHidden(false);
			}
			item.Key = zen('detailKey').getValue();
			item.LanguageOverride = zen('detailLanguageOverride').getValue();
			break;
		case 'Ens.DTL.If':
			item.Condition = zen('detailCondition').getValue();
			item.LanguageOverride = zen('detailLanguageOverride').getValue();
			break;
		case 'Ens.DTL.Trace':
			item.Value = zen('detailValue').getValue();
			item.LanguageOverride = zen('detailLanguageOverride').getValue();
			break;
		case 'Ens.DTL.SQL':
			item.SQL = zen('detailSQL').getValue();
			break;
		case 'Ens.DTL.Code':
			item.Code = zen('detailCode').getValue();
			item.LanguageOverride = zen('detailLanguageOverride').getValue();
			break;
		case 'Ens.DTL.SubTransform':
			item.Class = zen('detailClass').getValue();
			item.TargetObj = zen('detailTargetObj').getValue();
			item.SourceObj = zen('detailSourceObj').getValue();
			item.Aux = zen('detailAux').getValue();
			break;
		case 'Ens.DTL.ForEach':
			item.Property = zen('detailProperty').getValue();
			item.Key = zen('detailLoopKey').getValue();
			item.Unload = zen('detailLoopUnload').getValue();
			break;
		case 'Ens.DTL.Break':
			break;
		case 'Ens.DTL.Comment':
			break;
		case 'Ens.DTL.Switch':
			item.LanguageOverride = zen('detailLanguageOverride').getValue();
			break;
		case 'Ens.DTL.Case':
			item.Condition = zen('detailCondition').getValue();
			break;
		case 'Ens.DTL.Default':
			break;
		case 'Ens.DTL.Group':
			break;
		default:
			alert('unknown type in applyDetail form: ' + item._class);
			break;
		}
		item.Annotation = zen('detailAnnotation').getValue();
		var oldDisabled = item.Disabled;
		var disabledControl = zen('detailDisabled');
		if (disabledControl) {
			if (disabledControl.hidden) {
				item.Disabled = false;
			} else {
				item.Disabled = disabledControl.getValue();
			}
			if (oldDisabled != item.Disabled) {
				this.checkActionDisabled(item,true);
			}
		}
		this.updateTable();
		this.updateDiagramActions(true);
		this.setModified(true);

		var errs = this.validateAction(item);

		if (errs.length > 0) {
			html = [];
			html.push('<hr/>');
			html.push('<div class="errorTitle">'+$$$Text('This item is not valid')+'</div>');
			html.push('<ol class="errorList">');
			for (var n = 0; n < errs.length; n++) {
				html.push('<li>' + errs[n] + '</li>');
			}
			html.push('</ol>');
			html.push('<hr/>');
			ebox.setContent(html.join(''));
		}
		else {
			ebox.setContent('');
		}
	}
}

/// Test if there are any errors in this DTL definition.
ClientMethod validateDT(errors) [ Language = javascript ]
{
	if (!errors) errors = [];

	// check if general settings are ok
	var dtl = this.getDTLObject();
	if (dtl) {
		if (dtl.SourceClass == '') {
			errors.push($$$Text('Data Transformation must specify a source class. Please correct this problem before saving.'));
		}
		else if (dtl.TargetClass == '') {
			errors.push($$$Text('Data Transformation must specify a target class. Please correct this problem before saving.'));
		}
		if (errors.length > 0) return false;
	}

	var ok = true;
	for (var n = 0; n < this._actionIndex.length; n++) {
		var action = this._actionIndex[n];
		var errs = this.validateAction(action);
		if (errs.length > 0) {
			ok = false;
			break;
		}
	}
	if (!ok) errors.push($$$Text('There are errors in this Data Transformation. Please correct the problems before saving.'));
	return ok;
}

/// Validate the given action; return a list of errors (or an empty list).
ClientMethod validateAction(item) [ Language = javascript ]
{
	var errs = [];
	if (!item) return errs;

	switch(item._class) {
	case 'Ens.DTL.Assign':
		if (item.Property=='') {
			errs.push($$$Text('Assign statement must specify a property.'));
		}
		if ((item.Value.toString()=='') && (item.Action != 'clear') && (item.Action != 'remove')) {
			errs.push($$$Text('Assign statement must specify a value.'));
		}
		if (((item.Key === '') || (item.Key == '""')) && ((item.Action == 'insert') || (item.Action == 'remove'))) {
			if (!(item.Action=='remove' && zenPage.CompilesWithoutKey(item.Property))) {
				errs.push($$$FormatText($$$Text("Assign statement with action '%1' must specify a key."),item.Action));
			}
		}
		if ((typeof item.Value == 'string') && (item.Value.indexOf('.()') > -1)) {
			var quoteArray = item.Value.split('"');
			var isQuoted = false; // assume .() is in quotes
			for (var i = 0; i < quoteArray.length; i = i + 2) {
				if (quoteArray[i].indexOf('.()') > -1) {
					isQuoted = true;
					break;
				}
			}
			if (isQuoted) errs.push($$$FormatText($$$Text("Assign statement must not specify value containing '%1'."),'.()'));
		}
		break;
	case 'Ens.DTL.If':
		if (item.Condition=='') {
			errs.push($$$Text('If statement must specify a condition.'));
		}
		if ((typeof item.Condition == 'string') && (item.Condition.indexOf('.()') > -1)) {
			errs.push($$$FormatText($$$Text("If statement must not specify a condition containing '%1'."),'.()'));
		}
		break;
	case 'Ens.DTL.Trace':
		if (item.Value=='') {
			errs.push($$$Text('Trace statement must specify a value.'));
		}
		break;
	case 'Ens.DTL.SQL':
		if (item.SQL=='') {
			errs.push($$$Text('SQL action must define a valid SQL statement.'));
		}
		break;
	case 'Ens.DTL.Code':
		//item.Code = zen('detailCode').getValue();
		break;
	case 'Ens.DTL.SubTransform':
		if (item.Class=='') {
			errs.push($$$Text('SubTransform action must specify a data transformation class.'));
		}
		if (item.SourceObj=='') {
			errs.push($$$Text('SubTransform action must specify a source object.'));
		}
		if (item.TargetObj=='') {
			errs.push($$$Text('SubTransform action must specify a target object.'));
		}
		break;
	case 'Ens.DTL.ForEach':
		if (item.Property=='') {
			errs.push($$$Text('ForEach action must specify a property.'));
		}
		if (item.Key=='') {
			errs.push($$$Text('ForEach action must define a Key name.'));
		}
		if ((item.Property.indexOf('source.') == 0) || (item.Property.indexOf('target.') == 0)) {
			var svgWin = zenPage.getSVGWindow();
			var propNorm = svgWin.normalizePropertyName(item.Property);
			if (propNorm.substring(propNorm.length - 2) != '()'  &&  propNorm.substring(propNorm.length-("DocsRef".length)) !="DocsRef" ) {
				var index =  propNorm.indexOf("DocsRef-");
				if ((index == -1) || (propNorm.substring(index + "DocsRef-".length) != parseInt(propNorm.substring(index + "DocsRef-".length)))) {
				  errs.push($$$Text('ForEach action must specify a collection property.'));
				}
			}
		}
		break;
	case 'Ens.DTL.Case':
		if (item.Condition=='') {
			errs.push($$$Text('Case statement must specify a condition.'));
		}
		if ((typeof item.Condition == 'string') && (item.Condition.indexOf('.()') > -1)) {
			errs.push($$$FormatText($$$Text("Case statement must not specify a condition containing '%1'."),'.()'));
		}
		break;
	default:
		break;
	}
	item._isValid = (errs.length == 0);
	return errs;
}

ClassMethod CompilesWithoutKey(pProperty) As %Boolean [ ZenMethod ]
{
	Quit ##class(Ens.VDoc.Utils).isSingleVirtualProperty(pProperty)
}

/// User double-clicked on a property box in the diagram.
ClientMethod propertyClick(type, prop) [ Language = javascript ]
{
	if (this.readOnly || !this.canEdit) return;
	var currAction = null;
	// place value into field in details panel
	if ((this.currAction>=0) && (this.actionTabNo==zen('propertyTabs').getCurrTabNo())) {
		currAction = this.getCurrentAction();
	}
	if (!currAction) return;
	switch(currAction._class) {
		case 'else':
		case 'endeach':
		case 'endif':
		case 'endswitch':
		case 'endgroup':
			return;
			break;
	}

	var changeID = null;
	switch(currAction._class) {
		case 'Ens.DTL.Assign':
			changeID = (type == 'target' ? 'detailProperty' : 'detailValue');
			if (type == 'target') prop = this.correctAssignProperty(currAction.Action,prop);
			break;
		case 'Ens.DTL.SubTransform':
			changeID = (type == 'target' ? 'detailTargetObj' : 'detailSourceObj');
			break;
		case 'Ens.DTL.ForEach':
			changeID = 'detailProperty';
			// change "(keyname)" at end of string with "()"
			prop = String(prop).replace(/(\((\w)*\))$/g,'()');
			// change .() at end of string to ()
			prop = prop.replace(/(\.\(\))$/g,'()');
			break;
		case 'Ens.DTL.If':
			changeID = 'detailCondition';
			break;
		case 'Ens.DTL.Trace':
			changeID = 'detailValue';
			break;
		case 'Ens.DTL.Case':
			changeID = 'detailCondition';
			break;
	}
	if (changeID != null) {
		zen(changeID).setValue(prop);
	}
	this.detailChange();
}

/// Add a new action (called from toolbar or diagram).
ClientMethod addAction(cls, actionType, prop, value) [ Language = javascript ]
{
	var dtl = this.getDTLObject();

	this.addUndoAction();
	var idx = '';
	var newAction = this.newAction(cls);
	var currAction = this.getCurrentAction();

	if ((cls == 'Ens.DTL.Case') || (cls == 'Ens.DTL.Default')) {
		if ((!currAction) || (currAction._class !== 'Ens.DTL.Switch')) {
			alert($$$Text('case can only be added to a switch.'));
			return false;
		}
	}

	if (!currAction) {
		// add to end of list
		dtl.Actions.push(newAction);
	}
	else {
		if ((typeof currAction.Expanded == 'boolean') && !currAction.Expanded) {
			this.toggleExpandAction(currAction,true);
			this.updateTable();
		}
		switch(currAction._class) {
		case 'Ens.DTL.If':
			// add new item to true block
			currAction.True.splice(0,0,newAction);
			break;
		case 'else':
			// add new item to false block
			currAction._parent.False.splice(0,0,newAction);
			break;
		case 'Ens.DTL.ForEach':
			// add new item to ForEach block
			currAction.Actions.splice(0,0,newAction);
			break;
		case 'Ens.DTL.Case':
			// add new item to cases block
			currAction.Actions.splice(0,0,newAction);
			break;
		case 'Ens.DTL.Default':
			// add new item to default block
			currAction.Actions.splice(0,0,newAction);
			break;
		case 'Ens.DTL.Group':
			// add new item to group block
			currAction.Actions.splice(0,0,newAction);
			break;
		case 'endgroup':
		case 'endeach':
		case 'endif':
		case 'endswitch':
			// add new item after endeach/endif block
			var parentGroup = (currAction._parent._parent == null ? dtl.Actions : currAction._parent._parent[currAction._parent._parentProp]);
			parentGroup.splice(currAction._parent._index+1,0,newAction);
			break;
		case 'Ens.DTL.Switch':
			// Can only add Ens.DTL.Case & Ens.DTL.Default
			// Only one Ens.DTL.Default and that is handled in the code.
			if ((cls !== 'Ens.DTL.Case') && (cls !== 'Ens.DTL.Default')) {
				alert($$$Text('Only case can be added to a switch.'));
				return false;
			}
			newAction.LanguageOverride = currAction.LanguageOverride
			// add new item to cases block
			// If Cases.length > 0 and last one is Default then cannot add.
			// Add to end unless last one is Default
			var numCases = currAction.Cases.length;
			var position = 0
			if (numCases > 0 ) {
				if (currAction.Cases[numCases-1]._class == 'Ens.DTL.Default') {
					if (cls == 'Ens.DTL.Default') {
						alert($$$Text('Only one default can be added to a switch.'));
						return false;
					} else {
						position = numCases-1;
					}
				} else {
					position = numCases;
				}
			}
			currAction.Cases.splice(position,0,newAction);
			break
		default:
			// add after current action
			var parentGroup = (currAction._parent==null)?dtl.Actions:currAction._parent[currAction._parentProp];
			parentGroup.splice(currAction._index+1,0,newAction);
			break;
		}
	}

	switch (newAction._class) {
		case 'Ens.DTL.Assign':
			newAction.Action = actionType;
			newAction.Property = this.correctAssignProperty(actionType,prop);
			newAction.Value = value;
			break;
		case 'Ens.DTL.SubTransform':
			newAction.Class = '';
			newAction.TargetObj = prop;
			newAction.SourceObj = value;
			break;
		case 'Ens.DTL.If':
			if (value != '') {
				newAction.Condition = value;
			}
			else if (prop != '') {
				newAction.Condition = prop;
			}
			break;
		case 'Ens.DTL.ForEach':
			if (value != '') {
				if (value.substring(value.length - 4) == '(1)}') {
					newAction.Property = value.substring(0, value.length - 4) + '()}';
				}
				else if (value.substring(value.length - 3) == '(1)') {
					var remNum = (value.charAt(value.length - 4) == '.' ? 4 : 3);
					newAction.Property = value.substring(0, value.length - remNum) + '()';
				}
				else {
					newAction.Property = value;
				}
			}
			else if (prop != '') {
				if (prop.substring(prop.length - 4) == '(1)}') {
					newAction.Property = prop.substring(0, prop.length - 4) + '()}';
				}
				else if (prop.substring(prop.length - 3) == '(1)') {
					var remNum = (prop.charAt(prop.length - 4) == '.' ? 4 : 3);
					newAction.Property = prop.substring(0, prop.length - remNum) + '()';
				}
				else {
					newAction.Property = prop;
				}
			}
			// add a default key
			var kCount = 1;
			var parAction = currAction;
			var parentKeys = [];
			while (parAction) {
				if (parAction._class == 'Ens.DTL.ForEach') {
					kCount++;
					parentKeys.push(parAction.Key);
				}
				parAction = parAction._parent;
			}
			var newKey = 'k' + kCount;
			if (!parentKeys.indexOf) { // define indexOf for the array if needed.
				parentKeys.indexOf = function(searchElement) {
					for (var i = 0; i < this.length; i++) {
						if (this[i] === searchElement) return i;
					}
					return -1;
				}
			}
			while (parentKeys.indexOf(newKey) != -1) {
				newKey = 'k' + kCount++;
			}
			newAction.Key = newKey;
			break;
		case 'Ens.DTL.SubTransform':
			newAction.SourceObj = value;
			newAction.TargetObj = prop;
			break;
		case 'Ens.DTL.Trace':
			if (value != '') {
				newAction.Value = value;
			}
			if (prop != '') {
				newAction.Value = prop;
			}
			break;
		case 'Ens.DTL.Case':
			if (value != '') {
				newAction.Condition = value;
			}
			else if (prop != '') {
				newAction.Condition = prop;
			}
			break;
		case 'Ens.DTL.Group':
			break;
	}

	this.decorateActionList(dtl.Actions);

	// find idx of new action
	idx = -1;
	for (var n = 0; n < this._actionIndex.length; n++) {
		if (newAction === this._actionIndex[n]) {
			idx = n;
			break;
		}
	}

	this.updateTable();
	this.updateDiagramActions();
	this.selectAction(idx,true);
	this.setModified(true);

	return idx;
}

ClientMethod pasteAction() [ Language = javascript ]
{
	if (zenPage.readOnly || !zenPage.checkEdit()) { return; }
	if (!zenPage._pasteBuffer) {return;}

	var dtl = zenPage.getDTLObject();
	if (dtl) {
		var parentGroup = dtl.Actions;
		var pasteIndex = zenPage._actionIndex.length-1;
		var currentAction = zenPage.getCurrentAction();
		var canPaste = true;
		var reason = '';
		// case can be pasted into a switch or alongside a selected case
		// Assume false for case and set to true if in switch
		if ((zenPage._pasteBuffer._class) == 'Ens.DTL.Case') {
			canPaste = false;
			reason = $$$Text('A case can only be pasted into a switch or alongside another Case');
		}

		if (currentAction) {
			switch (currentAction._class) {
				case 'endif':
				case 'endeach':
				case 'endswitch':
				case 'endgroup':
					// place paste after endxxx
					if ((currentAction._depth>0) && (currentAction._parent._parent)) {
						/// Need to find parentGroup. parentProp can be True, False, Actions
						var parentProp = currentAction._parent._parentProp;
						if ((parentProp) && (currentAction._parent._parent[parentProp])) {
							parentGroup = currentAction._parent._parent[parentProp];
						}
					}
					pasteIndex = currentAction._parent._index + 1;
					break;
				case 'Ens.DTL.If':
					if (currentAction['True']) {
						parentGroup = currentAction['True'];
						pasteIndex = parentGroup.length;
					}
					break
				case 'else':
					if (currentAction._parent['False']) {
						parentGroup = currentAction._parent['False'];
						pasteIndex = parentGroup.length;
					}
					break
				case 'Ens.DTL.Switch':
					if ((zenPage._pasteBuffer._class) == 'Ens.DTL.Case') {
						canPaste = true;
						reason = '';
						// Leave Default as last cases[]
						if (currentAction['Cases']) {
							parentGroup = currentAction['Cases'];
							pasteIndex = currentAction.Cases.length;
							if (pasteIndex >0) {
								if ((currentAction.Cases[pasteIndex-1])&& (currentAction.Cases[pasteIndex-1]._class == 'Ens.DTL.Default')) {
									pasteIndex = pasteIndex-1;
								}
							}
						}
					} else {
						canPaste = false;
						reason = $$$Text('Only a case can be pasted into a switch');
					}
					break
				case 'Ens.DTL.Case':
					if ((zenPage._pasteBuffer._class) == 'Ens.DTL.Case') {
						// paste parallel
						canPaste = true;
						reason = '';
						pasteIndex = currentAction._index+1;
						parentGroup = currentAction._parent['Cases'];
						break;
					}
					// fall through to paste inside
				case 'Ens.DTL.Default':
				case 'Ens.DTL.Group':
				case 'Ens.DTL.ForEach':
					if (currentAction['Actions']) {
						parentGroup = currentAction['Actions'];
						pasteIndex = parentGroup.length;
					}
					break
				default:
					pasteIndex = currentAction._index+1;
					if (currentAction._parent) {
						parentGroup = currentAction._parent[currentAction._parentProp];
					}
					break;
			}
		}
		if (canPaste) {
			//This is safety check but we ought not to have the following result in canPaste = false.
			var isPseudoAction = (zenPage._pasteBuffer._class == 'endif') || (zenPage._pasteBuffer._class == 'endeach') || (zenPage._pasteBuffer._class == 'else') || (zenPage._pasteBuffer._class == 'endswitch') || (zenPage._pasteBuffer._class == 'endgroup');
			if (isPseudoAction || (zenPage._pasteBuffer._class == 'Ens.DTL.Default')) {
				canPaste = false;
				reason = $$$FormatText($$$Text('Unable to paste action type %1',zenPage.getActionType(zenPage._pasteBuffer)));
			}
		}
		if (!canPaste) {
			alert($$$FormatText($$$Text('Unable to paste last deleted or copied action at selected location. %1'),'\n'+reason));
			return;
		}

		zenPage.addUndoAction();

		// if pasting into a collapsed set of actions then expand the grouping
		if ((typeof currentAction.Expanded == 'boolean') && !currentAction.Expanded) {
			this.toggleExpandAction(currentAction,true);
		}

		var bufferClone = zenPage.cloneObject(zenPage._pasteBuffer);
		parentGroup.splice(pasteIndex,0,bufferClone);

		zenPage.decorateActionList(dtl.Actions);

		// find idx of new action
		idx = -1;
		for (var n = 0; n < zenPage._actionIndex.length; n++) {
			if (bufferClone === zenPage._actionIndex[n]) {
				idx = n;
				break;
			}
		}

		zenPage.updateTable();
		zenPage.updateDiagramActions();
		zenPage.selectAction(idx,true);
		zenPage.setModified(true);
	}
}

/// Copy the current action.
ClientMethod copyAction(idx) [ Language = javascript ]
{
	if (zenPage.readOnly || !zenPage.checkEdit()) { return; }
	if ('undefined' == typeof idx) {
		var action = zenPage.getCurrentAction();
	}
	else {
		var action = zenPage._actionIndex[idx];
	}
	if (action) {
		var isPseudoAction = (action._class == 'endif') || (action._class == 'endeach') || (action._class == 'else') || (action._class == 'endswitch') || (action._class == 'endgroup');
		if (!isPseudoAction && (action._class != 'Ens.DTL.Default')) {
			zenPage._pasteBuffer = action ;
			zenPage.updateToolbar();
			zenPage.updateActionHeader();
		} else {
			alert($$$FormatText($$$Text('Unable to copy action type %1',zenPage.getActionType(action))));
		}
	}
}

/// Delete the current action.
ClientMethod removeAction(idx) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return; }
	if ('undefined' == typeof idx) {
		var action = this.getCurrentAction();
	}
	else {
		var action = this._actionIndex[idx];
	}
	if (action) {
		if (!confirm($$$Text('Do you wish to delete the selected action?'))) {
			return;
		}

		this.addUndoAction();
		var dtl = this.getDTLObject();
		// remove action from its parent group
		var parentGroup = (action._parent==null)?dtl.Actions:action._parent[action._parentProp];
		this._pasteBuffer = parentGroup[action._index];
		parentGroup.splice(action._index,1);
		var oldIdx = this.currAction;
		this.currAction = -1;

		this.decorateActionList(dtl.Actions);
		this.updateTable();
		this.updateDiagramActions();

		var idx = -1;
		if (this._actionIndex.length > 0) {
			if (oldIdx < this._actionIndex.length) {
				idx = oldIdx;
			}
			else {
				idx = this._actionIndex.length - 1;
			}
		}
		this.selectAction(idx,true);
		this.setModified(true);
	}
}

/// Remove all actions.
ClientMethod removeAllActions() [ Language = javascript ]
{
	if (confirm($$$Text('Do you wish to remove all actions from this transformation?'))) {
		this.addUndoAction();
		var dtl = this.getDTLObject();
		dtl.Actions = new Array();
		this.currAction = -1;
		this.decorateActionList(dtl.Actions);
		this.updateTable();
		this.updateDiagramActions();
		this.selectAction(-1,true);
		this.setModified(true);
	}
}

/// Move the current item (action) up.
ClientMethod moveItemUp() [ Language = javascript ]
{
	var dtl = this.getDTLObject();
	if (dtl) {
		// swap curr action with prior one
		var moved = false;
		var action = this._actionIndex[this.currAction];
		var parentGroup = (action._parent==null)?dtl.Actions:action._parent[action._parentProp];
		var index = action._index;

		// first try prior element in same group
		if (index > 0) {
			var prior = parentGroup[index-1];
			if (prior) {
				// swap
				this.addUndoAction();
				parentGroup[prior._index] = action;
				parentGroup[action._index] = prior;
				moved = true;
			}
		}
		else if ((index == 0) && (action._depth > 0)) {
			if (action._parentProp == 'False') {
				// move from false branch to true branch
				this.addUndoAction();
				parentGroup.splice(index,1);
				action._parent.True.push(action);
				moved = true;
			}
			else {
				// move up and out of the group
				this.addUndoAction();
				parentGroup.splice(index,1);
				var newGroup = (!action._parent._parent ? dtl.Actions : action._parent._parent[action._parent._parentProp]);
				newGroup.splice(action._parent._index,0,action);
				moved = true;
			}
		}

		if (moved) this.afterActionMove(dtl.Actions,action);
	}
}

/// Move the current item (action) down.
ClientMethod moveItemDown() [ Language = javascript ]
{
	var dtl = this.getDTLObject();
	if (dtl && (this.currAction>=0) && (this.currAction < (this._actionIndex.length-1))) {
		// swap curr action with prior one
		var moved = false;
		var action = this._actionIndex[this.currAction];
		var parentGroup = dtl.Actions;
		if ((action._parent != null) && (action._parentProp != null) && (action._parent[action._parentProp] != null)) {
			parentGroup = action._parent[action._parentProp];
		}
		var index = action._index;

		// ignore elements with index == -1 (i.e. pseudo-actions like endeach,endif,else)
		if (index == -1) { }
		// try following element in same group
		else if (index < (parentGroup.length - 1)) {
			var next = parentGroup[index+1];
			if (next) {
				// swap
				this.addUndoAction();
				parentGroup[next._index] = action;
				parentGroup[action._index] = next;
				moved = true;
			}
		}
		else if ((index == parentGroup.length-1) && (action._depth > 0)) {
			if ('True'==action._parentProp) {
				// move from true branch to false branch
				this.addUndoAction();
				parentGroup.splice(index,1);
				action._parent.False.splice(0,0,action);
				moved = true;
			}
			else {
				// move down and out of the group
				this.addUndoAction();
				parentGroup.splice(index,1);
				var newGroup = (!action._parent._parent ? dtl.Actions : action._parent._parent[action._parent._parentProp]);
				newGroup.splice(action._parent._index+1,0,action);
				moved = true;
			}
		}

		if (moved) this.afterActionMove(dtl.Actions,action);
	}
}

/// Move the current item (action) into an adjacent block of actions.
ClientMethod moveItemIn() [ Language = javascript ]
{
	var dtl = this.getDTLObject();
	if (dtl && (this.currAction>=0) && (this.currAction < (this._actionIndex.length-1))) {
		var moved = false;
		var action = this._actionIndex[this.currAction];
		var parentGroup = dtl.Actions;
		if ((action._parent != null) && (action._parentProp != null) && (action._parent[action._parentProp] != null)) {
			parentGroup = action._parent[action._parentProp];
		}
		var index = action._index;

		// ignore elements with index == -1 (i.e. pseudo-actions like endeach,endif,else)
		if (index == -1) { }
		// move into next element in same group if it can accept children
		else if (index < (parentGroup.length - 1)) {
			var next = parentGroup[index+1];
			if (next && ((next._class == 'Ens.DTL.ForEach') || (next._class == 'Ens.DTL.If') || (next._class == 'Ens.DTL.Group'))) {
				this.addUndoAction();
				var listName = (next._class == 'Ens.DTL.If' ? 'True' : 'Actions');
				parentGroup.splice(index,1);
				next[listName].splice(0,0,action);
				moved = true;
				if ((typeof next.Expanded == 'boolean') && !next.Expanded) {
					this.toggleExpandAction(next,true);
					this.updateTable();
				}
			}
		}

		if (moved) this.afterActionMove(dtl.Actions,action);
	}
}

/// Move the current item (action) out of the current action block, i.e. move the action one level up.
ClientMethod moveItemOut() [ Language = javascript ]
{
	var dtl = this.getDTLObject();
	if (dtl) {
		// swap curr action with prior one
		var moved = false;
		var action = this._actionIndex[this.currAction];
		var parentGroup = (action._parent==null)?dtl.Actions:action._parent[action._parentProp];
		var index = action._index;

		if ((action._index >= 0) && (action._depth > 0) && action._parent) {
			var newGroup = (!action._parent._parent) ? dtl.Actions : action._parent._parent[action._parent._parentProp];
			this.addUndoAction();
			parentGroup.splice(index,1);
			newGroup.splice(action._parent._index,0,action);
			moved = true;
		}

		if (moved) this.afterActionMove(dtl.Actions,action);
	}
}

/// Helper method to execute common code after an action has been moved.
ClientMethod afterActionMove(actionList, action) [ Language = javascript ]
{
	this.setModified(true);
	this.decorateActionList(actionList);
	this.updateTable();
	this.updateDiagramActions();
	this.selectAction((action._index == -1 ? null : action._count),true);
}

/// Helper method to add or remove trailing array syntax from an assign property depending on the type of Assign.
ClientMethod correctAssignProperty(action, prop) [ Language = javascript ]
{
	if ((typeof prop == 'string') || (typeof prop == 'number')) {
		prop = prop.toString();
		var stripTrailingArray = false;
		var dtl = this.getDTLObject();
		var targetIsVDoc = dtl && (dtl.TargetClass != '') && this.isVDoc(dtl.TargetClass);
		switch (action) {
			case 'remove':
			case 'clear':
			case 'insert':
			case 'append':
				stripTrailingArray = true;
				break;
		}
		if (stripTrailingArray) { // strip trailing () for these actions
			if (!targetIsVDoc) { // don't do anything if the target is a VDoc
				var cutOff = -1;
				if (prop.substring(prop.length - 3) == '(1)') {
					cutOff = prop.length - 3;
				}
				else if (prop.substring(prop.length - 2) == '()') {
					cutOff = prop.length - 2;
				}
				if (cutOff > -1) {
					if (prop.charAt(cutOff - 1) == '.') cutOff--;
					prop = prop.substring(0,cutOff);
				}
			}
		}
		else { // make sure we have a trailing .(1) or (1) if needed
			var svgWin = this.getSVGWindow();
			if (svgWin && dtl && svgWin.propIndexTarget && svgWin.propIndexTarget[prop + '()']) {
				prop += ( !targetIsVDoc ? '.' : '' ) + '(1)';
			}
		}
	}
	return prop;
}

/// Construct a new Action object.
ClientMethod newAction(cls) [ Language = javascript ]
{
	var action = {
		"_class": ('undefined'==typeof cls) ? 'Ens.DTL.Assign' : cls,
		"Annotation": "",
		"Disabled": false,
		"_isValid": true,
		"_disabled": 0
	};

	switch (action._class) {
	case 'Ens.DTL.Assign':
		action.Action = 'set';
		action.Property = '';
		action.Value = '';
		action.Key = '""';
		break;
	case 'Ens.DTL.Trace':
		action.Value = '';
		break;
	case 'Ens.DTL.SQL':
		action.SQL = '';
		break;
	case 'Ens.DTL.Code':
		action.Code = '';
		action.LanguageOverride = '';
		break;
	case 'Ens.DTL.If':
		action.Condition = '1';
		action.True = new Array();
		action.False = new Array();
		action.Expanded = true;
		break;
	case 'Ens.DTL.ForEach':
		action.Actions = new Array();
		action.Property = '';
		action.Key = '';
		action.Unload = false;
		action.Expanded = true;
		break;
	case 'Ens.DTL.Break':
		break;
	case 'Ens.DTL.Comment':
		break;
	case 'Ens.DTL.SubTransform':
		action.Aux = '';
		action.Class = '';
		action.TargetObj = '';
		action.SourceObj = '';
		break;
	case 'Ens.DTL.Switch':
		action.Cases = new Array();
		action.Expanded = true;
		break;
	case 'Ens.DTL.Case':
		action.Condition = '1';
		action.Actions = new Array();
		action.Expanded = true;
		break;
	case 'Ens.DTL.Default':
		action.Actions = new Array();
		action.Expanded = true;
		break;
	case 'Ens.DTL.Group':
		action.Actions = new Array();
		action.Expanded = true;
		break;
	default:
		alert('Unhandled class in newAction: ' + action._class);
		break;
	}
	return action;
}

/// Do the actual work of updating the view to match the current view mode.
ClientMethod setViewModeHandler(mode) [ Language = javascript ]
{
	this.adjustSizes();
}

/// Get the SVG window object for the diagram.
/// This provides a way to access scripts in the SVG diagram.
ClientMethod getSVGWindow() [ Language = javascript ]
{
	var svg = zen('svg');
	return svg ? svg.svgWindow : null;
}

/// Test if the given class is a VDoc.
ClientMethod isVDoc(cls) [ Language = javascript ]
{
	if (!this._vdocCache) this._vdocCache = {};
	if (typeof this._vdocCache[cls] != 'boolean') {
		// No call to server needed for miniMode special properties, especially as isVDoc() may be called before Studio-specific HyperEvents take effect
		if (this.miniMode && ((cls = $$$Text('Business Process')) || (cls == $$$Text('Call Request')) || (cls == $$$Text('Call Response')))) {
			this._vdocCache[cls] = false;
		}
		else {
			this._vdocCache[cls] = this.IsVirtualDocument(cls);
		}
	}
	return this._vdocCache[cls];
}

/// Server method to test if document is virtual.
ClassMethod IsVirtualDocument(pClass As %String) As %Boolean [ ZenMethod ]
{
	Quit ##class(Ens.VDoc.Utils).IsVirtualDocument(pClass)
}

/// Load top-level document segments from the server and populate
/// part of the diagram.<br/>
/// <var>mode</var> is "target" or "source".
ClientMethod loadTopSegmentsFromServer(mode, cls, doctype) [ Language = javascript ]
{
	if (!this.miniMode) {
		// get contents from server
		this.GetTopSegments(mode,cls,doctype,true);
	}
	else {
		// create information for request and response from data
		var renderData = {
			"source": {
				"objects": [],
				"properties": [],
				"childQueue": []
			},
			"target": {
				"objects": [],
				"properties": [],
				"childQueue": []
			}
		}
		var objectData = zen('miniModeProvider').getContentObject();

		if (this.which == 'Request') {
			renderData.source.objects = [ 'context', 'request', 'response' ];
			renderData.target.objects = [ 'callrequest' ];
		}
		else {
			renderData.source.objects = [ 'callresponse' ];
			renderData.target.objects = [ 'context', 'request', 'response' ];
		}

		for (var type in renderData) {
			var objList = renderData[type].objects;
			// add main properties first, queue children to occur after render of main properties
			for (var i = 0; i < objList.length; i++) {
				var objName = objList[i];
				var childCount = objectData[objName].length;
				renderData[type].properties.push( [ '.' + objName, i+1, childCount ] );
				if (childCount > 0) {
					renderData[type].childQueue.push(objName);
				}
			}
		}

		if (renderData.source.properties.length > 0) {
			zenPage.setSourceSegments((this.which=='Request'?$$$Text('Business Process'):$$$Text('Call Response')),'',0,renderData.source.properties);
		}
		if (renderData.target.properties.length > 0) {
			zenPage.setTargetSegments((this.which=='Request'?$$$Text('Call Request'):$$$Text('Business Process')),'',0,renderData.target.properties);
		}

		// add child properties
		for (var type in renderData) {
			var childQueue = renderData[type].childQueue;
			var method = 'insert' + type.charAt(0).toUpperCase() + type.substring(1) + 'Segments';
			for (var i = 0; i < childQueue.length; i++) {
				var objName = childQueue[i];
				if (objectData[objName] && (objectData[objName].length > 0)) {
					zenPage[method](type + '.' + objName, objectData[objName]);
					if (objName == 'context') {
						for (var childProps in objectData[objName]) {
							// Remove leading ..
							var firstChildProp = objectData[objName][childProps][0];
							if (firstChildProp) {
								var childPropName = (firstChildProp.substring(2));
								var childObjName = 'zzcontext'+childPropName;
								if (objectData[childObjName] && (objectData[childObjName].length > 0)) {
									zenPage[method](type + '.' + objName + '.' + childPropName, objectData[childObjName]);
								}
							}
						}
					}
				}
			}
		}
	}
}

/// Load specified segments from the server.
ClientMethod loadSegmentsFromServer(type, cls, doctype, origName, idlist) [ Language = javascript ]
{
	if (!this.miniMode) {
		// get contents from server
		this.GetSegments(type,cls,doctype,origName,idlist);
	}
}

/// Generate JS to populate list of top-level segment
ClassMethod GetTopSegments(pMode As %String = "", pClass As %String = "", pDocType As %String = "", pDyn As %Boolean = 0) As %Boolean [ ZenMethod ]
{
	// mode can be csv list
	For p = 1:1:$L(pMode,",") {
		Set mode = $P(pMode,",",p)
		Set cls = $P(pClass,",",p)
		Set doctype = $P(pDocType,",",p)

		Set tType = $S(mode="target":"Target",1:"Source")

		Write "zenPage.set"_tType_"Segments("""_(cls)_""","""_(doctype)_""",",pDyn,",",!

		Set tIsXMLVDoc = 0
		Try {
			Set tIsXMLVDoc = $classmethod(pClass,"%Extends","EnsLib.EDI.XML.Document")
			If tIsXMLVDoc {
				Set tMaxLevel = 1
			}
		}
		Catch {}
		#dim tIncludeBatchChildInfo = 0
		#dim tBatchChildInfoArray
		#dim tReplaceName
		Set tIncludeBatchChildInfo = ..GetBatchChildInfoArray(pClass, pDocType, mode, -1, .tBatchChildInfoArray)

		// get DTL info
		Set tHandle = ##class(EnsPortal.SessionEvents).GetTempNode()
		Set tRef = ##class(EnsPortal.SessionEvents).GetReference(tHandle)
		Set tSC = ##class(Ens.VDoc.Utils).GetInfoArray(tRef,cls,mode,doctype,.tMaxLevel,,-1)
		Set tIsVDoc = ##class(Ens.VDoc.Utils).IsVirtualDocument(cls)

		// walk over contents list
		Write "[ "
		Set n=0,k="" For { Set k=$O(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,tHandle,k))  Quit:""=k  Continue:+k'=k  Set n=n+1
			Set tName = $G(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,tHandle,k,"name"))
			If tIncludeBatchChildInfo && $Data(tBatchChildInfoArray("replaceProperties",tName),tReplaceName)#2 Set tName=tReplaceName
			If $Case($E(tName),".":0, ":":0, :1) Set tName = "." _ $select(tIsVDoc: tName, $extract(tName,*-1,*) = "()": $$$QN($extract(tName,1,*-2))_"()", 1: $$$QN(tName))
			Set tChildCount = +$G(^IRIS.Temp.EnsPortal.Data(%session.SessionId,0,tHandle,k))
			Write $S(n>1:",",1:""),"[ '",$zconvert(tName,"O","JS"),"',",n,",",tChildCount," ]",!
		}
		Write " ] );",!

		// clear list
		Do ##class(EnsPortal.SessionEvents).KillTempNode(tHandle)
	}
	Quit 1
}

/// Called from client to get list of subsegments
/// pNodeAddr is csv-list of id numbers
ClassMethod GetSegments(pMode As %String, pClass As %String, pDocType As %String = "", pSegment As %String, pNodeAddr As %String = "") As %Boolean [ ZenMethod ]
{
	#dim start=0
	#dim arrayOpened=0
	Set $ZT="Trap"
	Set:""=pNodeAddr pNodeAddr=-1
	Write $c(9)_"zenPage.insert"_$S(pMode="target":"Target",1:"Source")_"Segments('"_(pSegment)_"',",!
	Set start=1

	// get DTL info
	#dim tIsXMLVDoc = 0
	Try {
		Set tIsXMLVDoc = $classmethod(pClass,"%Extends","EnsLib.EDI.XML.Document")
	}
	Catch {}

	#; We might request info for doctype and node that are not the DTL's source/target primary values
	#dim tInfoDocType = pDocType
	#dim tInfoNodeAddr = pNodeAddr

	#dim tIncludeBatchChildInfo = 0
	#dim tBatchChildInfoArray
	Set tIncludeBatchChildInfo = ..GetBatchChildInfoArray(pClass, pDocType, pSegment, pNodeAddr, .tBatchChildInfoArray)

	If tIncludeBatchChildInfo {
		Set tInfoDocType = $Get(tBatchChildInfoArray("infoschema"),pDocType)
		Set tInfoNodeAddr = $Get(tBatchChildInfoArray("nodeAddr"),pNodeAddr)
	}

	#dim tHandle = ##class(EnsPortal.SessionEvents).GetTempNode()
	#dim tGLVN = ##class(EnsPortal.SessionEvents).GetReference(tHandle)
	#dim tSC = ##class(Ens.VDoc.Utils).GetInfoArray(tGLVN,pClass,pMode,tInfoDocType,,,tInfoNodeAddr)
	#dim tIsVDoc = ##class(Ens.VDoc.Utils).IsVirtualDocument(pClass)

	// assemble glvn for looping over segments
	#dim dots = ""

	#dim tNodesLen=$S(+tInfoNodeAddr<=0:0, 1:$L(tInfoNodeAddr,","))

	#dim p, tNode, tID, k

	For p = 1:1:tNodesLen {
		Set tNode = +$P(tInfoNodeAddr,",",p)
		#; scan the current tree level up to the given node position
		Set tID=0, k=""  For { Set k=$O(@tGLVN@(k)) Quit:""=k  Continue:+k'=k  Set tID=tID+1 Quit:tID=tNode } Set:tID'=tNode k="_"
		#; XML VDoc only returns relevant level and not parent levels
		If 'tIsXMLVDoc {
			Set tGLVN = $Name(@tGLVN@(k))
		}
		Set dots = dots _ $S(":"=$E($G(@tGLVN@("name"))):":",1:".")
	}

	// Write JSON property array as 2nd parameter to zenPage.insert<xxx> method above
	Write " [ "
	Set arrayOpened = 1
	/*	If we are not using the main DTL source/target schema then
		we need to calculate correct number of dots for the level.
		Using $piece function to pad leading dots.
	*/
	If (tInfoNodeAddr'=pNodeAddr) Set $Piece(dots,".", ($Length(pSegment,".")))=""

	#dim n, tName, tChildCount
	#dim tReplaceName
	Set n=0,k="" For { Set k=$O(@tGLVN@(k))  Quit:""=k  Continue:+k'=k  Set n=n+1
		Set tName = $G(@($Name(@tGLVN@(k)))@("name"))
		If (tInfoNodeAddr'=pNodeAddr) && tIncludeBatchChildInfo {
			If $Data(tBatchChildInfoArray("replaceProperties",tName),tReplaceName)#2 {
				Set tName=tReplaceName
			}
		}
		Set tName = dots _ $S($E(tName)=":":"", 1:".") _ $select(tIsVDoc: tName, $extract(tName,*-1,*) = "()": $$$QN($extract(tName,1,*-2))_"()", 1: $$$QN(tName))
		Set tChildCount = +$G(@tGLVN@(k))
		Write $S(n>1:",",1:"")," [ '",$zconvert(tName,"O","JS"),"',",n,",",tChildCount," ]",!
	}

	Set start = 0, arrayOpened = 0
	Write " ] );",!
	// End Write of JSON Array

	// clear list
	Do ##class(EnsPortal.SessionEvents).KillTempNode(tHandle)
Exit
	Quit 1
Trap
	Set $ZT=""
	#; close out direct write of zenPage.insert...
	If arrayOpened {
		Write " ] );",!
	} ElseIf start {
		Write:start """"");",!
	}
	&js<alert('Error in GetSegments: #($ZCVT($ZE,"O","JS"))#');>
	Goto Exit
}

/// Set segments into the target portion of the diagram.
/// This is called by the GetTopSegments method.
ClientMethod setTargetSegments(clsname, doctype, reload, proplist) [ Language = javascript ]
{
	this.getSVGWindow().setTargetSegments(clsname,doctype,reload,proplist);
}

/// Set segments into the source portion of the diagram.
/// This is called by the GetTopSegments method.
ClientMethod setSourceSegments(clsname, doctype, reload, proplist) [ Language = javascript ]
{
	this.getSVGWindow().setSourceSegments(clsname,doctype,reload,proplist);
}

/// Insert segments into the target portion of the diagram.
/// This is called by the GetSegments method.
ClientMethod insertTargetSegments(segment, proplist) [ Language = javascript ]
{
	this.getSVGWindow().insertTargetSegments(segment, proplist);
}

/// Insert segments into the source portion of the diagram.
/// This is called by the GetSegments method.
ClientMethod insertSourceSegments(segment, proplist) [ Language = javascript ]
{
	this.getSVGWindow().insertSourceSegments(segment, proplist);
}

/// Called from diagram to set size of svg canvas.
ClientMethod setCanvasSize(width, height) [ Language = javascript ]
{
	var svg = zen('svg');
	svg.setProperty('svgHeight',height);
	svg.setProperty('svgWidth',width);
}

ClientMethod setReadOnly(readOnly) [ Language = javascript ]
{
	readOnly = !!readOnly;
	this.readOnly = readOnly;
	var svgWin = this.getSVGWindow();
	if (svgWin) {
		svgWin.readOnlyFlag = readOnly;
	}
	var forms = ['actionForm'];
	if (!this.miniMode) {
		forms.push('generalForm');
	}
	for (var i=0; i<forms.length; i++) {
		var currForm = zen(forms[i]);
		var controls = currForm.getControlList();
		for (var j=0; j<controls.length; j++) {
			var control = controls[j];
			control.setProperty('readOnly',readOnly);
			control.setProperty('disabled',readOnly);
			if (control._type == 'image') {
				var imgEl = control.findElement('image');
				if (imgEl) {
					var classes = [];
					if (imgEl.className != '') {
						classes = imgEl.className.split(' ');
					}
					var toAdd = (readOnly ? 'reIconDisabled' : 'imageLink');
					var toRemove = (readOnly ? 'imageLink' : 'reIconDisabled');
					var addSeen = false;
					for (var k=0; k<classes.length; k++) {
						if (classes[k] == toAdd) {
							addSeen = true;
						}
						if (classes[k] == toRemove) {
							classes.splice(k,1);
							k--;
						}
					}
					if (!addSeen) {
						classes.push(toAdd);
					}

					imgEl.className = classes.join(' ');
				}
			}
		}
	}
	if (!this.miniMode) {
		zen('generalName').setProperty('readOnly',true);
	}
	var newAction = document.getElementById('selectNewAction');
	if (newAction) {
		newAction.disabled = readOnly;
	}

	if (readOnly) {
		this.grayOutButtons();
		if (!this.canEdit) {
			this.grayOutOneButton('command_cmdSaveAs');
			this.grayOutOneButton('command_cmdNew');
		}
	} else {
		var btnSave = document.getElementById('command_cmdSave');
		if (btnSave) {
			btnSave.className = 'commandButton';
			btnSave.onclick = function() { zenPage.saveDT(false); return false; }
			btnSave.title = this.tipSave;
		}
		var btnCompile = document.getElementById('command_cmdCompile');
		if (btnCompile) {
			btnCompile.className = 'commandButton';
			btnCompile.title = this.tipCompile;
			btnCompile.onclick = function() { zenPage.compile(); return false; }
		}
	}

	this.updateActionHeader();
	this.updateTable();
	this.updateToolbar();
}

/// Call <method>UpdateSCMenu</method>() first in case the document has been modified elsewhere,
/// then display the source control menu based on the contents of the _sourceControlMenu data
/// created by <method>UpdateSCMenu</method>().
ClientMethod showSCMenu() [ Language = javascript ]
{
	this.UpdateSCMenus();
	this.invokeSuper('showSCMenu',arguments);
}

/// Handle a source control menu selection.
ClientMethod chooseSCMenu(menuName, commandName, saveFlags) [ Language = javascript ]
{
	zenPage.wasReadOnly = zenPage.getIsReadOnly();
	this.invokeSuper('chooseSCMenu',arguments);
	zenPage.toggleReadOnly();
}

/// Create a new data transformation.
ClientMethod newDT() [ Language = javascript ]
{
	if (this.studioMode) { return; }
	zenPage.checkTextControls();
	if (this.pageModified) {
		if (!confirm($$$Text('This Data Transformation has been modified. If you create a new Data Transformation now, without saving your changes to this Data Transformation, your changes will be lost. Do you wish to continue without saving?'))) {
			return;
		}
	}
	// show wizard dialog
	var parms = {};
	if (this.studioMode) parms.STUDIO = 1;
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.DataTransformWizard.zen',this.studioMode),this.addPopupSuffix('DTLNew'),'status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Launch the finder dialog.
ClientMethod loadDT() [ Language = javascript ]
{
	if (this.studioMode) { return; }
	zenPage.checkTextControls();
	if (this.pageModified) {
		if (!confirm($$$Text('This Data Transformation has been modified. If you open another Data Transformation now, without saving your changes to this Data Transformation, your changes will be lost. Do you wish to continue without saving?'))) {
			return;
		}
	}
	var parms = {
		MODE:'dtl'
	};
	zenLaunchPopupWindow(zenLink('%ZEN.Dialog.finderDialog.zen',this.studioMode),this.addPopupSuffix('DTLOpen'),'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// Launch the finder dialog to select a class for a subtransform.
ClientMethod selectTransformClass() [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var parms = {
		MODE:'dtlplus'
	};
	var url = zenLink('%ZEN.Dialog.finderDialog.zen',this.studioMode);
	zenLaunchPopupWindow(url,this.addPopupSuffix('DTLSelectTransform'),'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// Launch the compile dialog.
ClientMethod compile() [ Language = javascript ]
{
	if (this.studioMode || !this.canUserModify()) {
		return;
	}

	zenPage.checkTextControls();
	if (zenPage.dtlId=='') {
		alert($$$Text('Data Transformation must have a name.'));
		return;
	}

	var sync = zenPage.saveDT(false);
	if (!sync) return;

	var valid = zenPage.validateDT();
	if (!valid) {
		alert($$$Text('Not compiling the Data Transformation as it is not valid.'));
		return;
	}

	// strip off ext
	var name = zenPage.getCurrentName();

	// launch compile window
	var parms = {
		CLASSNAME: name,
		TYPE:'DTL'
	};
	if (this.studioMode) parms.STUDIO = 1;
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ClassCompile.zen',this.studioMode),this.addPopupSuffix('DTLCompile'),'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// Launch the save dialog.
ClientMethod saveDT(showDialog) [ Language = javascript ]
{
	if (!this.canUserModify(showDialog)) {
		return false;
	}
	this.checkTextControls();

	// validate the DTL
	var errors = [];
	var ok = this.validateDT(errors);
	if (!ok) {
		alert(errors.join('\n'));
		// Enable correction of document after failed Save As while readonly
		if (showDialog && this.readOnly) {
			this.setReadOnly(false);
			zenPage.grayOutOneButton('command_cmdSave');
			zenPage.grayOutOneButton('command_cmdCompile');
		}
		return false;
	}

	if ((!this.studioMode) && (showDialog || (this.dtlId === ''))) {
		var desc = '';
		var dtl = this.getDTLObject();
		if (dtl) desc = dtl.Annotation;

		// show save dialog
		var parms = {
			DT:this.dtlId,
			DESC:desc
		};
		if (this.studioMode) parms.STUDIO = 1;
		zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.DataTransformSave.zen',this.studioMode),this.addPopupSuffix('DTLSave'),'status,scrollbars,resizable=yes,width=700,height=600',parms);
	}
	else {
		return this.doSave();
	}
}

/// Actually perform the save.
ClientMethod doSave(delayAlert) [ Language = javascript ]
{
	var rename = ((zenPage.originalId!='') && (zenPage.originalId!=zenPage.dtlId))

	if (!this.canUserModify(rename)) return false;
	this.checkTextControls();

	// validate the DTL; just return if not valid -- user should get an alert from saveDT().
	if (!this.validateDT()) return false;
	
	if (this.studioMode) {
		var ok = this.studioSave();
	}
	else {
		if (rename && this.readOnly) {
			try {
				this.readOnly = false;
				var ok = this.saveDocument();
				this.readOnly = true;
			} catch (ex) {
				this.readOnly = true;
			}
		}
		else {
			var ok = this.saveDocument();
		}
		if (ok) {
			if (delayAlert) { setTimeout(zenPage.saveNotification, 300); }
			else { this.saveNotification(); }
		} else {
			// reset description to old value; control still holds original value if save failed
			var dtl = this.getDTLObject();
			if (dtl) {
				dtl.Annotation = zen('generalDescription').getValue();
				dtl.pyFromImport = zen('gPyFromImport').getValue();				
			}
			if (zenPage.originalId!='') {
				zenPage.dtlId = zenPage.originalId;
			}
			// Enable correction of document after failed Save As while readonly, but only if failure is a validation error and not source control/timestamp
			if (rename && this.readOnly && this.pageModified) {
				var json = this.getClientModel();
				if (json.error.substring(0,5)=="ERROR") {
					this.setReadOnly(false);
					zenPage.grayOutOneButton('command_cmdSave');
					zenPage.grayOutOneButton('command_cmdCompile');
					alert($$$Text('Please correct errors before saving.'));
				}
			} else if (!rename && zenPage.getIsReadOnly()) {
				// If this document was found to be readOnly, gray out buttons to indicate this
				zenPage.grayOutButtons();
			}
		}
	}
	return ok;
}

ClientMethod saveNotification() [ Language = javascript ]
{
	alert($$$Text('DTL saved.'));
	if (zenPage.originalId!=zenPage.dtlId) { // name changed; reload new item
		self.document.location = zenLink(zenPage.designerURL + '?DT=' + encodeURIComponent(zenPage.dtlId) + '&RENAMED=1');
	}
}

/// Ensure we redraw the diagram and actions table based if the model was updated.
ClientMethod onDocumentSaveComplete(contentUpdated) [ Language = javascript ]
{
	this.invokeSuper('onDocumentSaveComplete',arguments);
	if (contentUpdated) {
		var dtl = this.getDTLObject();
		if (dtl && dtl.Actions) {
			this.decorateActionList(dtl.Actions);
			this.updateTable();
			this.updateDiagramActions(true);
			this.updateGeneralForm();
		}
	}
}

/// Ensure we redraw the diagram if the model was updated.
ClientMethod onDocumentReload(reason) [ Language = javascript ]
{
	if (this._inReload) { return; } // avoid recursion
	this._inReload = true;
	this.updateDocumentState(true);
	if (reason == "dataChange") {
		var dtl = this.getDTLObject();
		if (dtl && dtl.Actions) {
			this.decorateActionList(dtl.Actions);
			this.updateTable();
			this.updateDiagramActions(true);
			this.updateGeneralForm();
			this.selectAction(this.currAction,true,false,false);
			this.setModified(false);
		}
	}
	this._inReload = false;
}

/// Launch the select type dialog.
ClientMethod selectType(which) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return; }
	var mode = '';
	var cls = '';

	switch(which) {
	case 'source_class':
		mode = 'vdocclass';
		break;
	case 'source_doctype':
		cls = zen('generalSourceClass').getValue();
		mode = 'vdoctype';
		break;
	case 'target_class':
		mode = 'vdocclass';
		break;
	case 'target_doctype':
		cls = zen('generalTargetClass').getValue();
		mode = 'vdoctype';
		break;
	default:
		return;
	}

	if (mode=='vdoctype') {
		if (cls=='') {
			alert($$$Text('Please select a message class first.'));
			return;
		}
		else if (!zenPage.isVDoc(cls)) {
			alert($$$Text('The message class is not a virtual document. No DocType can be specified.'));
			return;
		}
	}

	var parms = {
		MODE:mode,
		CATEGORY:cls,
		CALLER:'dtleditor'
	};
	var url = zenLink('%ZEN.Dialog.finderDialog.zen',this.studioMode);
	zenLaunchPopupWindow(url,this.addPopupSuffix(which),'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

ClientMethod studioSave() [ Language = javascript ]
{
	var useDOMSave = !!this._isIE10;
	try {
		var dtl = this.getDTLObject();
		var props = [ 	{ "prop": "SourceClass", "attrib": "sourceClass" },
							{ "prop": "SourceDocType", "attrib": "sourceDocType" },
							{ "prop": "TargetClass", "attrib": "targetClass" },
							{ "prop": "TargetDocType", "attrib": "targetDocType" },
							{ "prop": "Create", "attrib": "create" },
							{ "prop": "Language", "attrib": "language" } ];

		if (useDOMSave) {
			var transform = document.createElement('transform');
			var children = [];

			for (var i = 0; i < props.length; i++) {
				var pair = props[i];
				if (dtl[pair.prop]) transform.setAttribute(pair.attrib,dtl[pair.prop]);
			}
			if (dtl.Annotation != '') {
				var annotation = document.createElement('annotation');
				var annotationText = document.createTextNode(dtl.Annotation);
				annotation.appendChild(annotationText);
				//transform.appendChild(annotation);
				children.push(annotation);
			}
			if (dtl.pyFromImport != ''){
				var pyFromImport = document.createElement('pyFromImport');
				var pyImportsText = document.createTextNode(dtl.pyFromImport);
				pyFromImport.appendChild(pyImportsText);
				children.push(pyFromImport);
			}
			for (var i = 0; i < dtl.Actions.length; i++) {
				var action = dtl.Actions[i];
				if (action) {
					var childNode = this.serializeAction(action,true);
					if (childNode) children.push(childNode); //transform.appendChild(childNode);
				}
			}
			for (var i = 0; i < children.length; i++) {
				var newLine = document.createTextNode('\n');
				transform.appendChild(newLine);
				transform.appendChild(children[i]);
			}
			this.setResultsDiv('SAVE',transform,true);
		}
		else {
			var xml = [];
			var transform = '<transform ';

			for (var i = 0; i< props.length; i++) {
				var pair = props[i];
				if (dtl[pair.prop]) transform += pair.attrib +'="' + zenEscapeXML(dtl[pair.prop]) + '" ';
			}
			transform += '>';
			xml.push(transform);
			if (dtl.Annotation != '') xml.push('<annotation>' + zenEscapeXML(dtl.Annotation) + '</annotation>');
			if (dtl.pyFromImport != '') xml.push('<pyFromImport>' + zenEscapeXML(dtl.pyFromImport) + '</pyFromImport>');
			for (var i=0; i < dtl.Actions.length; i++) {
				var action = dtl.Actions[i];
				if (action) {
					xml.push(this.serializeAction(action));
				}
			}
			xml.push('</transform>');

			var fullXML = xml.join('\n');
			this.setResultsDiv('SAVE',fullXML,false);
		}
		this.setModified(false); // ensure we show the diagram as not modified if we complete the save
		return true;
	} catch (ex) {
		alert('Exception in studioSave: '+ex);
	}
	return false;
}

/// Helper to serialize the Action in <var>action</var> when saving data for Studio.
/// <var>useDOM</var> should only be true under IE10, as IE9 and lower aren't happy with this approach.
ClientMethod serializeAction(action, useDOM) [ Language = javascript ]
{
	if (!action) return (useDOM ? null : '');
	var tagName = action._class.split('.').pop().toLowerCase();
	var props = [];
	switch (tagName) {
		case 'assign':
			props = [ 	{ "propName": "Value", "attrib": "value", "required": true },
						{ "propName": "Property", "attrib": "property", "required": true },
						{ "propName": "Key", "attrib": "key" },
						{ "propName": "Action", "attrib": "action" }	];
			break;
		case 'if':
			props = [ { "propName": "Condition", "attrib": "condition", "required": true } ];
			break;
		case 'foreach':
			props = [	{ "propName": "Key", "attrib": "key", "required": true },
						{ "propName": "Property", "attrib": "property", "required": true },
						{ "propName": "Unload", "attrib": "unload" }	];
			break;
		case 'subtransform':
			props = [	{ "propName": "Class", "attrib": "class", "required": true },
						{ "propName": "TargetObj", "attrib": "targetObj", "required": true },
						{ "propName": "SourceObj", "attrib": "sourceObj", "required": true },
						{ "propName": "Aux", "attrib": "aux" }	];
			break;
		case 'trace':
			props = [ { "propName": "Value", "attrib": "value", "required": true } ];
			break;
		case 'case':
			props = [ { "propName": "Condition", "attrib": "condition", "required": true } ];
			break;
		case 'switch':
		case 'default':
		case 'break':
		case 'code':
		case 'subtransform':
		case 'sql':
		case 'group':
		default:
			props = [];
			break;
	}
	if (useDOM) {
		var actionEl = document.createElement(tagName);
		for (var i = 0; i < props.length; i++) {
			var prop = props[i];
			if (prop.required || (action[prop.propName].toString() != '')) {
				actionEl.setAttribute(prop.attrib,action[prop.propName]);
			}
		}
		if (action.Annotation != '') {
			var annotation = document.createElement('annotation');
			var annotationText = document.createTextNode(action.Annotation);
			annotation.appendChild(annotationText);
			actionEl.appendChild(annotation);
		}
		if ((typeof action.Disabled == 'boolean') && action.Disabled) {
			actionEl.setAttribute('disabled',1);
		}
		if ((typeof action.Expanded == 'boolean') && !action.Expanded) {
			actionEl.setAttribute('expanded',0);
		}
		if (((tagName == 'foreach')||(tagName == 'case')||(tagName == 'default')||(tagName == 'group')) && action.Actions) {
			for (var i = 0; i < action.Actions.length; i++) {
				var childAction = action.Actions[i];
				if (childAction) {
					var childActionEl = this.serializeAction(childAction,useDOM);
					actionEl.appendChild(childActionEl);
				}
			}
		}
		else if ((tagName == 'code') && action.Code) {
			var codeText = document.createTextNode('<![CDATA[' + this.escapeCData(action.Code) + ']]>');
			actionEl.appendChild(codeText);
		}
		else if (tagName == 'if') {
			var trueEl = document.createElement('true');
			var falseEl = document.createElement('false');
			if ((action.True && (action.True.length > 0)) || (action.False && (action.False.length > 0))) {
				if (action.True && (action.True.length > 0)) {
					for (var i = 0; i < action.True.length; i++) {
						var childAction = action.True[i];
						if (childAction) {
							var childActionEl = this.serializeAction(childAction,useDOM);
							trueEl.appendChild(childActionEl);
						}
					}
				}
				if (action.False && (action.False.length > 0)) {
					for (var i = 0; i < action.False.length; i++) {
						var childAction = action.False[i];
						if (childAction) {
							var childActionEl = this.serializeAction(childAction,useDOM);
							falseEl.appendChild(childActionEl);
						}
					}
				}
			}
			actionEl.appendChild(trueEl);
			actionEl.appendChild(falseEl);
		}
		else if ((tagName == 'sql') && action.SQL) {
			var sqlText = document.createTextNode('<![CDATA[' + this.escapeCData(action.SQL) + ']]>');
			actionEl.appendChild(sqlText);
		}
		else if (tagName == 'switch') {
			if (action.Cases && (action.Cases.length > 0)) {
				for (var i = 0; i < action.Cases.length; i++) {
					var caseAction = action.Cases[i];
					if (caseAction) {
						var caseActionEl = this.serializeAction(caseAction,useDOM);
						actionEl.appendChild(caseActionEl);
						}
					}
			}
		}
		return actionEl;
	}
	else {
		var hasChildren = (action.Annotation != '');
		if (!hasChildren) {
			switch (tagName) {
				case 'foreach':
					hasChildren = action.Actions && (action.Actions.length > 0);
					break;
				case 'code':
					hasChildren = action.Code && (action.Code != '');
					break;
				case 'sql':
					hasChildren = action.SQL && (action.SQL != '');
				case 'if':
					hasChildren = true;
					break;
				case 'switch':
				case 'case':
				case 'default':
				case 'group':
					hasChildren = true;
					break;
			}
		}
		var headerXML = '<' + tagName;

		for (var i=0; i<props.length; i++) {
			var prop = props[i];
			if (prop.required || (('' + action[prop.propName]) != '')) {
				headerXML += ' ' + prop.attrib + '="' + zenEscapeXML(action[prop.propName]) + '"';
			}
		}
		if ((typeof action.Disabled == 'boolean') && action.Disabled) {
			headerXML += ' disabled="1"';
		}
		if ((typeof action.Expanded == 'boolean') && !action.Expanded) {
			headerXML += ' expanded="0"';
		}
		if (!hasChildren) {
			headerXML += '>' + '</' + tagName + '>';
			return headerXML;
		}
		headerXML += '>';
		var xml = new Array();
		xml.push(headerXML);
		if (action.Annotation != '') {
			xml.push('<annotation>' + zenEscapeXML(action.Annotation) + '</annotation>');
		}

		if (((tagName == 'foreach')||(tagName == 'case')||(tagName == 'default')||(tagName == 'group')) && action.Actions) {
			for (var i=0; i<action.Actions.length; i++) {
				var childAction = action.Actions[i];
				if (childAction) {
					xml.push(this.serializeAction(childAction));
				}
			}
		}
		else if ((tagName == 'code') && action.Code) {
			xml.push('<![CDATA[' + this.escapeCData(action.Code) + ']]>');
		}
		else if (tagName == 'if') {
			if ((action.True && (action.True.length > 0)) || (action.False && (action.False.length > 0))) {
				if (action.True && (action.True.length > 0)) {
					xml.push('<true>');
					for (var i=0; i<action.True.length; i++) {
						var childAction = action.True[i];
						if (childAction) {
							xml.push(this.serializeAction(childAction));
						}
					}
					xml.push('</true>');
				}
				if (action.False && (action.False.length > 0)) {
					xml.push('<false>');
					for (var i=0; i<action.False.length; i++) {
						var childAction = action.False[i];
						if (childAction) {
							xml.push(this.serializeAction(childAction));
						}
					}
					xml.push('</false>');
				}
			}
			else {
				xml.push('<true/>');
				xml.push('<false/>');
			}
		}
		else if ((tagName == 'sql') && action.SQL) {
			xml.push('<![CDATA[' + this.escapeCData(action.SQL) + ']]>');
		}
		else if (tagName == 'switch') {
			if (action.Cases && (action.Cases.length > 0)) {
				for (var i=0; i<action.Cases.length; i++) {
					var caseAction = action.Cases[i];
					if (caseAction) {
						xml.push(this.serializeAction(caseAction));
					}
				}
			}
		}

		xml.push('</' + tagName + '>');
		return xml.join('\n');
	}
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	var dtl = this.getDTLObject();
	var svgWin = this.getSVGWindow();

	// chop last piece off of value
	var s = value.toString().split('.');
	s.length--;
	var shortValue = s.join('.');
	popupName = this.removePopupSuffix(popupName);

	switch(popupName) {
	case 'DTLOpen':
		// Mark the diagram as unmodified to avoid popups when trying to leave the page.
		this.setModified(false);
		self.document.location = zenLink(this.designerURL + '?DT=' + encodeURIComponent(value));
		break;

	case 'DTLNew':
		if (value!='') {
			// Mark the diagram as unmodified to avoid popups when trying to leave the page.
			this.setModified(false);
			self.document.location = zenLink(this.designerURL + '?DT=' + encodeURIComponent(value) + '&NEW=1');
		}
		break;

	case 'DTLSave':
		this.doSave(true);
		break;

	case 'DTLValue':
		if (this._currProperty) {
			setTimeout(function() {
				var ctrl = zen(zenPage._currProperty);
				if (ctrl) {
					ctrl.setValue(value);
					zenPage.detailChange();
				}
				zenPage._currProperty = null;
			}, 0);
		}
		break;
	case 'DTLFunctionWizard':
		if (this._currProperty) {
			setTimeout(function() {
				var ctrl = zen(zenPage._currProperty);
				if (ctrl) {
					if (zenPage._currSelection) {
						var oldValue = ctrl.getValue();
						var newValue = oldValue.substring(0,zenPage._currSelection[0]);
						newValue += value;
						newValue += oldValue.substring(zenPage._currSelection[1], oldValue.length);
						value = newValue;
						zenPage._currSelection = null;
					}
					ctrl.setValue(value);
					zenPage.detailChange();
				}
				this._currProperty = null;
			}, 0);
		}
		break;
	case 'switchNamespace':
		zenPage.changeURLNamespace(value);
		break;
	case 'DTLCompile':
		//self.document.location.reload();
		break;

	case 'source_class':
		if (dtl && dtl.SourceClass != shortValue) {
			dtl.SourceClass = shortValue;
			zen('generalSourceClass').setValue(shortValue);
			svgWin.setSource(dtl.SourceClass,dtl.SourceDocType);
			svgWin.loadTransform(dtl.Language);
			zenPage.setModified(true);
		}
		break;
	case 'source_doctype':
		if (dtl && dtl.SourceDocType != shortValue) {
			dtl.SourceDocType = shortValue;
			zen('generalSourceDocType').setValue(shortValue);
			svgWin.setSource(dtl.SourceClass,dtl.SourceDocType);
			svgWin.loadTransform(dtl.Language);
			zenPage.setModified(true);
		}
		break;
	case 'target_class':
		if (dtl && dtl.TargetClass != shortValue) {
			dtl.TargetClass = shortValue;
			zen('generalTargetClass').setValue(shortValue);
			svgWin.setTarget(dtl.TargetClass,dtl.TargetDocType);
			svgWin.loadTransform(dtl.Language);
			zenPage.setModified(true);
		}
		break;
	case 'target_doctype':
		if (dtl && dtl.TargetDocType != shortValue) {
			dtl.TargetDocType = shortValue;
			zen('generalTargetDocType').setValue(shortValue);
			svgWin.setTarget(dtl.TargetClass,dtl.TargetDocType);
			svgWin.loadTransform(dtl.Language);
			zenPage.setModified(true);
		}
		break;
	case 'DTLSelectTransform':
		// strip off .dtl
		var s = value.toString().split('.');
		s.length--;
		zen('detailClass').setValue(s.join('.'));
		zenPage.detailChange();
		break;
	}
}

/// Test if the user has write privilege.
ClientMethod canUserModify(saveAs) [ Language = javascript ]
{
	if (!this.canEdit) {
		alert($$$Text('You are not authorized to save data transformations.'));
		return false;
	}
	if (this.readOnly && !saveAs) {
		alert(this.msgDocReadOnly);
		return false;
	}
	return true
}

/// User has selected a new zoom level.
ClientMethod setZoom(zoom, updateSelect) [ Language = javascript ]
{
	zoom = parseInt(zoom,10);
	if (isNaN(zoom)) {
		return;
	}

	zenPage.currZoom = zoom;
	this.SaveZoomToServer(zoom,this.dtlId);
	var svgWin = this.getSVGWindow();
	if (svgWin && svgWin.setZoom) {
		svgWin.setZoom(zoom);
	}
	if (updateSelect) {
		var select = document.getElementById('selectZoom');
		if (select) {
			select.value = zoom;
		}
	}
}

ClassMethod SaveZoomToServer(pZoom As %String, pName As %String) [ Internal, ZenMethod ]
{
	Set pName = $G(pName)
	Set tType = $P(pName,".",*)
	If (tType="dtl") || (tType="DTL") {
		Set pName = $P(pName,".",1,*-1) // Remove suffix
	}
	If (pName'="") && (+$G(pZoom)) {
		If pZoom=..#DEFAULTZOOM {
			Kill ^IRIS.Temp.EnsDTLEditorZoom($Username,$Namespace,pName)
		}
		Else  {
			Set ^IRIS.Temp.EnsDTLEditorZoom($Username,$Namespace,pName) = +pZoom
		}
	}
}

ClassMethod FetchZoomFromServer(pName As %String) As %String [ Internal, ZenMethod ]
{
	Set pName = $G(pName)
	Set tType = $P(pName,".",*)
	If (tType="dtl") || (tType="DTL") {
		Set pName = $P(pName,".",1,*-1) // Remove suffix
	}
	Set tZoom = ..#DEFAULTZOOM
	If pName'="" {
		Set tZoom = $G(^IRIS.Temp.EnsDTLEditorZoom($Username,$Namespace,pName))
		Set:'tZoom tZoom = ..#DEFAULTZOOM
	}
	Quit tZoom
}

/// Notification that an item within the diagram has been selected.
ClientMethod itemSelected(item) [ Language = javascript ]
{
	if (item && item.gtype=='action') {
		this.checkTextControls();
		// pull action # out of id
		var x = item.id.toString().split('_');
		var actionNo = parseInt(x[1],10);
		this.selectAction(actionNo,false,false);
	}
}

/// Return the "type" of the given action (by combining its class and action).
ClientMethod getActionType(action) [ Language = javascript ]
{
	var type = 'unknown type (getActionType)'
	switch(action._class) {
	case 'Ens.DTL.Assign':
		type = action.Action;
		break;
	case 'Ens.DTL.If':
		type = 'if';
		break;
	case 'Ens.DTL.Trace':
		type = 'trace';
		break;
	case 'Ens.DTL.SQL':
		type = 'sql';
		break;
	case 'Ens.DTL.Code':
		type = 'code';
		break;
	case 'else':
		type = 'else';
		break;
	case 'endif':
		type = 'endif';
		break;
	case 'endeach':
		type = 'endeach';
		break;
	case 'Ens.DTL.ForEach':
		type = 'for each';
		break;
	case 'Ens.DTL.Break':
		type = 'break';
		break;
	case 'Ens.DTL.Comment':
		type = 'comment';
		break;
	case 'Ens.DTL.SubTransform':
		type = 'subtransform';
		break;
	case 'Ens.DTL.Switch':
		type = 'switch';
		break;
	case 'Ens.DTL.Case':
		type = 'case';
		break;
	case 'Ens.DTL.Default':
		type = 'default';
		break;
	case 'endswitch':
		type = 'endswitch';
		break;
	case 'Ens.DTL.Group':
		type = 'group';
		break;
	case 'endgroup':
		type = 'endgroup';
		break;
	default:
		break;
	}
	return type;
}

/// User has selected a new action to add.
ClientMethod addNewAction() [ Language = javascript ]
{
	var svgWin = this.getSVGWindow();
	var select = self.document.getElementById('selectNewAction');
	var cls = '';
	var actionType = '';
	var prop = svgWin.getSelectedTargetProp();
	var value = svgWin.getSelectedSourceProp();

	switch(select.value) {
	case 'set':
	case 'clear':
	case 'remove':
	case 'insert':
	case 'append':
		cls = 'Ens.DTL.Assign';
		actionType = select.value;
		break;
	case 'trace':
		cls = 'Ens.DTL.Trace';
		break;
	case 'sql':
		cls = 'Ens.DTL.SQL';
		break;
	case 'code':
		cls = 'Ens.DTL.Code';
		break;
	case 'if':
		cls = 'Ens.DTL.If';
		break;
	case 'for each':
		cls = 'Ens.DTL.ForEach';
		break;
	case 'break':
		cls = 'Ens.DTL.Break';
		break;
	case 'comment':
		cls = 'Ens.DTL.Comment';
		break;
	case 'subtransform':
		cls = 'Ens.DTL.SubTransform';
		break;
	case 'switch':
		cls = 'Ens.DTL.Switch';
		break;
	case 'case':
		cls = 'Ens.DTL.Case';
		break;
	case 'default':
		// this ought not to happen since not in the list.
		cls = 'Ens.DTL.Default';
		break;
	case 'group':
		cls = 'Ens.DTL.Group';
		break;
	}

	if (cls!='') {
		var idxAdded = this.addAction(cls,actionType,prop,value);
		if (cls == 'Ens.DTL.Switch') {
			this.addAction('Ens.DTL.Default','','','');
			this.selectAction(idxAdded,true); /* select switch so can add 1 Case */
			this.addAction('Ens.DTL.Case','','','');
		}
	}

	// reset select
	select.value = '';
}

/// Walk down list of actions, build an index, and set the parent pointers.
ClientMethod decorateActionList(actionList, parent, parentProp, depth) [ Language = javascript ]
{
	parent = ('undefined' == typeof parent) ? null : parent;
	parentProp = ('undefined' == typeof parentProp) ? '' : parentProp;
	depth = ('undefined' == typeof depth) ? 0 : depth;
	if (!parent) {
		// top level; reset index
		this._actionIndex = [];
		this._disabledIndex = {};
	}

	for (var n = 0; n < actionList.length; n++) {
		var action = actionList[n];
		var count = this._actionIndex.length;
		this._actionIndex.push(action);
		action._depth = depth;
		action._id = 'action_' + count;
		action._count = count; // index within list
		action._index = n;	// index within parent
		action._parent = parent;
		action._parentProp = parentProp;
		action._isValid = true;
		this.checkActionDisabled(action);
		action._synthList = null;

		// recurse
		switch(action._class) {
		case 'Ens.DTL.If':
			this.decorateActionList(action.True, action, 'True',depth+1);
			// add synthethic "else" action
			var elseObj = {
				_class: 'else',
				_depth: depth,
				_parent: action,
				_index: -1,
				_count: this._actionIndex.length,
				_disabled: (action._disabled ? 2 : 0),
				_display: (('undefined' != typeof action._display) ? ((!action._display) ? false : action.Expanded) : action.Expanded)
			};
			this._actionIndex.push(elseObj);
			action._synthList = [ elseObj ];

			this.decorateActionList(action.False, action, 'False', depth+1);

			// add synthethic "endif" action
			var endObj = {
				_class: 'endif',
				_depth: depth,
				_parent: action,
				_index: -1,
				_count: this._actionIndex.length,
				_disabled: (action._disabled ? 2 : 0),
				_display: (('undefined' != typeof action._display) ? ((!action._display) ? false : action.Expanded) : action.Expanded)
			};
			this._actionIndex.push(endObj);
			action._synthList.push(endObj);
			break;
		case 'Ens.DTL.ForEach':
			this.decorateActionList(action.Actions, action, 'Actions',depth+1);

			// add synthethic "endeach" action
			var endObj = {
				_class: 'endeach',
				_depth: depth,
				_parent: action,
				_index: -1,
				_count: this._actionIndex.length,
				_disabled: (action._disabled ? 2 : 0),
				_display: (('undefined' != typeof action._display) ? ((!action._display) ? false : action.Expanded) : action.Expanded)
			};
			this._actionIndex.push(endObj);
			action._synthList = [ endObj ];
			break;

		case 'Ens.DTL.Switch':
			this.decorateActionList(action.Cases, action, 'Cases',depth+1);
			// add synthethic "endswitch" action
			var endObj = {
				_class: 'endswitch',
				_depth: depth,
				_parent: action,
				_index: -1,
				_count: this._actionIndex.length,
				_disabled: (action._disabled ? 2 : 0),
				_display: (('undefined' != typeof action._display) ? ((!action._display) ? false : action.Expanded) : action.Expanded)
			};
			this._actionIndex.push(endObj);
			action._synthList = [ endObj ];
			break;

		case 'Ens.DTL.Case':
			action.LanguageOverride = action._parent.LanguageOverride
			this.decorateActionList(action.Actions, action, 'Actions',depth+1);
			break;
		case 'Ens.DTL.Default':
			this.decorateActionList(action.Actions, action, 'Actions',depth+1);
			break;

		case 'Ens.DTL.Group':
			this.decorateActionList(action.Actions, action, 'Actions',depth+1);
			// add synthethic "endgroup" action
			var endObj = {
				_class: 'endgroup',
				_depth: depth,
				_parent: action,
				_index: -1,
				_count: this._actionIndex.length,
				_disabled: (action._disabled ? 2 : 0),
				_display: (('undefined' != typeof action._display) ? ((!action._display) ? false : action.Expanded) : action.Expanded)
			};
			this._actionIndex.push(endObj);
			action._synthList = [ endObj ];
			break;

			default:
			break;
		}
	}
}

ClientMethod toggleRowHover(row) [ Language = javascript ]
{
	if (this.removeClass(row,'oddRow')) {
		this.addClass(row,'oddRowHover');
	}
	else if (this.removeClass(row,'evenRow')) {
		this.addClass(row,'evenRowHover');
	}
	else if (this.removeClass(row,'selectedRow')) {
		this.addClass(row,'selectedRowHover');
	}
	else if (this.removeClass(row,'oddRowHover')) {
		this.addClass(row,'oddRow');
	}
	else if (this.removeClass(row,'evenRowHover')) {
		this.addClass(row,'evenRow');
	}
	else if (this.removeClass(row,'selectedRowHover')) {
		this.addClass(row,'selectedRow');
	}
}

/// Update the disabled status of any actions in the supplied
/// <var>children</var> that need to be updated.
ClientMethod checkChildActions(children) [ Language = javascript ]
{
	if ((!children) || (!children.length)) return;
	for (var i = 0; i < children.length; i++) {
		var action = children[i];
		if (action) {
			this.checkActionDisabled(action,true);
		}
	}
}

ClientMethod checkActionDisabled(action, recurse) [ Language = javascript ]
{
	var returnVal = 0;
	if ((!action) || ((!action._count) && (action._count !== 0))) {
	}
	else if (action._index == -1) {
		if (action._parent && action._parent._disabled) {
			returnVal = 2;
		}
	}
	else if (action.Disabled) {
		returnVal = 1;
	}
	else if (action._parent && action._parent._disabled) {
		returnVal = 2;
	}
	if (returnVal == 0) {
		delete this._disabledIndex[action._count];
	}
	else {
		this._disabledIndex[action._count] = returnVal;
	}
	action._disabled = returnVal;
	if (recurse) {
		this.checkChildActions(action._synthList);
		if (action._class == 'Ens.DTL.ForEach') {
			this.checkChildActions(action.Actions);
		}
		else if (action._class == 'Ens.DTL.If') {
			this.checkChildActions(action.True);
			this.checkChildActions(action.False);
		}
	}
	return returnVal;
}

/// Decorate the page.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	If (..miniMode) {
		Set ..canEdit = ##class(EnsPortal.Utils).CheckResourceList(##class(EnsPortal.BPLEditor).#EDITRESOURCE)

		Set ..title = $case(..which, "Request": $$$Text("Request Builder"), "Response": $$$Text("Response Builder"), : $$$Text("Call Builder"))

		// Hide and remove value editor link
		Set ..%GetComponentById("detailValueLaunch").hidden = 1

		// remove extra tabs
		Set tTabGroup = ..%GetComponentById("propertyTabs")
		Do tTabGroup.%RemoveChild(..%GetComponentById("tabGeneral"))
		Do tTabGroup.%RemoveChild(..%GetComponentById("tabTools"))

		Set ..actionTabNo = 1
	}
	Else {
		// remember the last DTL viewed
		If (..dtlId="") {
			If ('..isNew) {
				Set ..dtlId = $G(^EnsPortal.Settings($UserName,"LastDTL"))
				If ..dtlId '= "" {
					Set tClassId = $extract(..dtlId, 1, *-4)
					If '##class(%Dictionary.ClassDefinition).%ExistsId(tClassId) {
						Set ..dtlId = ""
						Kill ^EnsPortal.Settings($UserName,"LastDTL")
					}
				}
			}
		}
		Else {
			Set ^EnsPortal.Settings($UserName,"LastDTL") = ..dtlId
		}

		If (..dtlId="") {
			Set ..isNew = 1
		}
		ElseIf '..studioMode {
			If ..isNew {
				Set tDTLClass = $select($zconvert($extract(..dtlId,*-3,*),"U") = ".DTL": $extract(..dtlId,1,*-4), 1: ..dtlId)
				Set ..isNew = '##class(%Dictionary.ClassDefinition).%ExistsId(tDTLClass)
			}
			Set tSC = ..GetDocument(..dtlId, .tDiagram)
			If $$$ISERR(tSC) Quit tSC
			Set ..%dtl = tDiagram
			Set ..readOnly = ''tDiagram.ReadOnly
		}

		If '..canTest {
			Set tTestButton = ..%GetComponentById("testTransformButton")
			Set tTestButton.controlClass = "commandButtonDisabled"
			Set tTestButton.disabled = 1
			Set tTestButton.title = ..msgNotPermitted
		}
		Set dtlName = $p(..dtlId,".dtl")
		Set tGenerateGroup = ..%GetComponentById("grpTestDTLGenerator")
		If '##class(%Dictionary.CompiledClass).%ExistsId("HS.InteropTools.HL7.GenerateDTL.UI.Main") || '##class(%Dictionary.CompiledClass).%ExistsId(dtlName) || ($parameter(dtlName,"TEMPLATE")="") {
			Set tGenerateGroup.hidden = 1
		} Else {
			Set tGenerateGroup.hidden = 0
		}
	}

	Set ..readOnly = '..canEdit
	// remember original name
	Set ..originalId = ..dtlId

	If ..studioMode {
		Set tSVG = ..%GetComponentById("svg")
		Do ..%SetValueById("svgStudioMode",1)
		Set tShareParm = ##class(%ZEN.Auxiliary.parameter).%New()
		Set tShareParm.id = "svgCSPSHARE"
		Set tShareParm.value = "1"
		If $$$ISOK(..%AddComponent(tShareParm)) {
			Do tSVG.parameters.SetAt(tShareParm,"CSPSHARE")
		}
	}

	Quit tSC
}

/// Update the description (annotation) of this DT.
ClientMethod setDescription(desc) [ Language = javascript ]
{
	if (this.canEdit) {
		var dtl = this.getDTLObject();
		if (dtl) {
			if (desc != dtl.Annotation) {
				dtl.Annotation = desc;
				this.setModified(true);
			}
		}
	}
}

/// Return the internal name of the current DTL document.
Method GetInternalName() As %String
{
	If ..dtlId = "" Quit ""
	Set name = ..dtlId
	If $zcvt($extract(name, *-3, *),"l") = ".dtl" {
		Set name = $extract(name, 1, *-4)
	}
	Quit $$$NormalizeClassname(name)_".CLS"
}

/// Get DTL object for JSON provider.
Method GetDTLContent(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	If ..miniMode {
		Set pObject = ""
	}
	ElseIf $IsObject(..%dtl) {
		Set pObject = ..%dtl
	}
	ElseIf ..isNew {
		Set pObject = ##class(Ens.DTL.Transform).%New()
	}
	Else {
		// create object to be rendered by client
		Set tSC = ..GetDocument(..dtlId,.pObject)
		// correct the ReadOnly flag
		If ..IsSourceControlReadOnly(..GetInternalName()) {
			Set pObject.ReadOnly = 2
		}
	}
	Quit tSC
}

/// Object submit handler JSON provider.
/// This is called when the client submits the DTL definition.
Method SubmitDTL(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As Ens.DTL.Transform, Output pResponseObject As %RegisteredObject) As %Status
{
	// pSubmitObject is the DTL document
	Set tSC = $$$OK

	If (pCommand = "save") || (pCommand = "forcesave") {
		If (..dtlId = "") {
			Quit $$$ERROR($$$GeneralError,"Transform cannot be saved without a name.")
		}

		Set tReadOnly = 0
		Set tClassName = $P(..dtlId,".",1,$L(..dtlId,".")-1)
		If (pCommand = "save") && ##class(%Dictionary.ClassDefinition).%ExistsId(tClassName) {
			Set tSC = ..LoadClassDefinition(tClassName,.tDef,.tReadOnly,1)
			If $$$ISERR(tSC) Quit tSC
			If $zdatetime(tDef.TimeChanged,3,,6) '= pSubmitObject.Timestamp {
				Set pProvider.error = "timestamp"
				Quit tSC
			}
		}
		If ..IsSourceControlReadOnly(..GetInternalName()) {
			Set pProvider.error = $$$Text("Your source control framework has marked this document as read only, so you will not be able to modify this document.")
			Quit tSC
		}
		Set tSC = ..SaveDTLToClass(tClassName, pSubmitObject)
		If $$$ISERR(tSC) Quit tSC
		Set pResponseObject = pSubmitObject
		// correct the ReadOnly flag on the response object
		Set pResponseObject.ReadOnly = tReadOnly
	}

	Quit tSC
}

/// Find DTL transform (Ens.DTL.Transform) object for the given DTL class.
ClassMethod GetDocument(pDTLId As %String, Output pDocument As %RegisteredObject) As %Status
{
	Set tSC=$$$OK
	Set pDocument = ""
	Try {
		If (pDTLId = "") Quit
		Set tClassName = $P(pDTLId,".",1,$L(pDTLId,".")-1)

		Set tIsNew = $select($IsObject($get(%page)): %page.isNew, 1: 0)
		If ('tIsNew) && '##class(EnsPortal.Utils).IsSubclass(tClassName, "Ens.DataTransformDTL") {
			Set tSC = $$$ERROR($$$NotAnInstanceError, "Ens.DataTransformDTL")
			Quit
		}

		Set tSC = ..GetTransform(.tTransform, tClassName)

		If ($$$ISOK(tSC) && $IsObject(tTransform)) {
			Set pDocument = tTransform
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Given a DTL transform object, convert it to XML and
/// save it in the specified class' XDATA block.<br/>
/// If class does not exist, create a new one.<br/>
/// (Copied from the old DTLDocument class).
ClassMethod SaveDTLToClass(pClassName As %String, pDTL As Ens.DTL.Transform) As %Status
{
	Set tSC = $$$OK

	Set tLockTimeout = $zu(115,4)
	// save this DTL document into the DTL class
	Try {
		Do $zu(115,4,3)
		Set tClassDefinition = ""
		#; open the class definition
		If ##class(%Dictionary.ClassDefinition).%ExistsId(pClassName) {
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%OpenId(pClassName,,.tSC)
			If $$$ISERR(tSC) Quit
		}
		If ($IsObject(tClassDefinition)) {
			If '##class(EnsPortal.Utils).IsSubclass(pClassName, "Ens.DataTransformDTL") {
				Set tSC = $$$ERROR($$$NotAnInstanceError, "Ens.DataTransformDTL")
				Quit
			}
			#; delete the old XDATA block named DTL
			Set tIndex = tClassDefinition.XDatas.FindObjectId(pClassName_"||DTL")
			If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)
		}
		Else {
			// create a new class
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%New()
			Set tClassDefinition.Name = pClassName
			Set tClassDefinition.Super = "Ens.DataTransformDTL"
			Set tClassDefinition.ClassVersion = $$$CLASSDEFINITIONVERSION
		}

		Set tDependsOn = ""
		If (pDTL.SourceClass '= "") Set tDependsOn =  pDTL.SourceClass
		If (pDTL.TargetClass '= "") && (pDTL.TargetClass '= pDTL.SourceClass) {
			Set tDependsOn = tDependsOn _ $select(tDependsOn '= "": ",", 1: "") _ pDTL.TargetClass
		}
		If tDependsOn '= "" {
			Set tClassDefinition.DependsOn = tDependsOn
		}
		Else {
			Do tClassDefinition.DependsOnReset()
		}

		#; define a new XDATA block named (DTL)
		Set tXDataDefinition = ##class(%Dictionary.XDataDefinition).%New()

		Set tXDataDefinition.Name = "DTL"
		Set tXDataDefinition.parent = tClassDefinition
		Set tXDataDefinition.XMLNamespace = "http://www.intersystems.com/dtl"

		If ($IsObject(pDTL)) {
			Set tReportErrorsPos = tClassDefinition.Parameters.FindObjectId(pClassName_"||REPORTERRORS")
			If tReportErrorsPos {
				Set tReportErrorsParm = tClassDefinition.Parameters.GetAt(tReportErrorsPos)
			}
			Else {
				Set tReportErrorsParm = ##class(%Dictionary.ParameterDefinition).%New()
				Set tReportErrorsParm.parent = tClassDefinition
				Set tReportErrorsParm.Name = "REPORTERRORS"
			}
			Set tReportErrorsParm.Default = pDTL.ReportErrors

			Set tIgnoreMissingSourcePos = tClassDefinition.Parameters.FindObjectId(pClassName_"||IGNOREMISSINGSOURCE")
			If tIgnoreMissingSourcePos {
				Set tIgnoreMissingSourceParm = tClassDefinition.Parameters.GetAt(tIgnoreMissingSourcePos)
			}
			Else {
				Set tIgnoreMissingSourceParm = ##class(%Dictionary.ParameterDefinition).%New()
				Set tIgnoreMissingSourceParm.parent = tClassDefinition
				Set tIgnoreMissingSourceParm.Name = "IGNOREMISSINGSOURCE"
			}
			Set tIgnoreMissingSourceParm.Default = pDTL.IgnoreMissingSource

			Set tTreatEmptyAsNullPos = tClassDefinition.Parameters.FindObjectId(pClassName_"||TREATEMPTYREPEATINGFIELDASNULL")
			If tTreatEmptyAsNullPos {
				Set tTreatEmptyAsNullParm = tClassDefinition.Parameters.GetAt(tTreatEmptyAsNullPos)
			}
			Else {
				Set tTreatEmptyAsNullParm = ##class(%Dictionary.ParameterDefinition).%New()
				Set tTreatEmptyAsNullParm.parent = tClassDefinition
				Set tTreatEmptyAsNullParm.Name = "TREATEMPTYREPEATINGFIELDASNULL"
			}
			Set tTreatEmptyAsNullParm.Default = pDTL.TreatEmptyAsNull

			Set tGenerateEmptySegmentsPos = tClassDefinition.Parameters.FindObjectId(pClassName_"||GENERATEEMPTYSEGMENTS")
			If tGenerateEmptySegmentsPos {
				Set tGenerateEmptySegmentsParm = tClassDefinition.Parameters.GetAt(tGenerateEmptySegmentsPos)
			}
			Else {
				Set tGenerateEmptySegmentsParm = ##class(%Dictionary.ParameterDefinition).%New()
				Set tGenerateEmptySegmentsParm.parent = tClassDefinition
				Set tGenerateEmptySegmentsParm.Name = "GENERATEEMPTYSEGMENTS"
			}
			Set tGenerateEmptySegmentsParm.Default = pDTL.GenerateEmptySegments

			// Convert DTL to XML
			// Note: DTL does not use %XML.Adaptor
			Set tSC = pDTL.GenerateXML(tXDataDefinition.Data)
		}
		If $$$ISERR(tSC) Quit

		Set tSC = tClassDefinition.%Save()
		If $$$ISERR(tSC) Quit
		Set pDTL.Timestamp = $zdatetime(tClassDefinition.TimeChanged,3,,6)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Do $zu(115,4,tLockTimeout)
	Quit tSC
}

/// Get DTL info for a class.
ClassMethod GetTransform(Output pTransform As Ens.DTL.Transform, pClassName As %String) As %Status
{
	Set pTransform = ""
	Set tSC = $$$OK

	Try {
		// Get DTL block from class
		Set tSC = ..GetDTLStream(.tStream, pClassName, .tDesc, .tTimestamp, .tReadOnly)
		If $$$ISERR(tSC) Quit

		// Now parse it into a Transform object
		Set tSC = ##class(Ens.DTL.Compiler).ParseStream(.pTransform, tStream)
		If $$$ISERR(tSC) Quit

		Try {
			Set tReportErrors = $parameter(pClassName,"REPORTERRORS")
		}
		Catch {
			Set tReportErrors = +$$$defMemberKeyGet(pClassName,$$$cCLASSparameter,"REPORTERRORS",$$$cPARAMdefault)
		}
		Set pTransform.ReportErrors = tReportErrors
		Try {
			Set tIgnoreMissingSource = $parameter(pClassName,"IGNOREMISSINGSOURCE")
		}
		Catch {
			Set tIgnoreMissingSource = +$$$defMemberKeyGet(pClassName,$$$cCLASSparameter,"IGNOREMISSINGSOURCE",$$$cPARAMdefault)
		}
		Set pTransform.IgnoreMissingSource = tIgnoreMissingSource
		Try {
			Set tTreatEmptyAsNull = $parameter(pClassName,"TREATEMPTYREPEATINGFIELDASNULL")
		}
		Catch {
			Set tTreatEmptyAsNull = +$$$defMemberKeyGet(pClassName,$$$cCLASSparameter,"TREATEMPTYREPEATINGFIELDASNULL",$$$cPARAMdefault)
		}
		Set pTransform.TreatEmptyAsNull = tTreatEmptyAsNull
		
		Try {
			Set tGenerateEmptySegments = $parameter(pClassName,"GENERATEEMPTYSEGMENTS")
		}
		Catch {
			Set tGenerateEmptySegments = +$$$defMemberKeyGet(pClassName,$$$cCLASSparameter,"GENERATEEMPTYSEGMENTS",$$$cPARAMdefault)
		}
		Set pTransform.GenerateEmptySegments = tGenerateEmptySegments

		Set pTransform.Timestamp = tTimestamp
		Set pTransform.ReadOnly = tReadOnly
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Find the DTL definition (as a stream) for the given
/// DTL class; return "" if not found.<BR>
/// Also returns Description for this class
ClassMethod GetDTLStream(Output pStream As %Stream.Object, pClassName As %String, ByRef pDesc As %String, Output pTimestamp As %String, Output pReadOnly As %Boolean = 0) As %Status
{
	Set pStream = ""
	Set pTimestamp = ""
	Set pReadOnly = 0
	Set tSC = $$$OK

	Try {
		Set tSC = ..LoadClassDefinition(pClassName,.cdef,.pReadOnly)
		If $$$ISERR(tSC) Quit
		If ('$IsObject(cdef)) {
			// no class
			Set tSC = $$$ERROR($$$GeneralError, "Unable to open class: " _ pClassName)
			Quit
		}

		Set pTimestamp = $zdatetime(cdef.TimeChanged,3,,6)
		Set pDesc = cdef.Description

		Set tConcurrency = $select(pReadOnly: 0, 1: 4)
		Set tXData = ##class(%Dictionary.XDataDefinition).IDKEYOpen(cdef.Name,"DTL",tConcurrency,.tSC)
		If $$$ISERR(tSC) Quit

		// get XDATA as stream
		Set pStream = tXData.Data
		If ($IsObject(pStream)) {
			Do pStream.Rewind()
		}
		Else {
			Set tSC = $$$ERROR($$$GeneralError, "Unable to open DTL stream within class: " _ pClassName)
			Quit
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Return true if it is possible to undo an action
ClientMethod canUndo() [ Language = javascript ]
{
	return (!this.readOnly) && this.canEdit && this._undoBuffer && (this._undoIndex > 0);
}

/// Undo the most recent change.
ClientMethod undo() [ Language = javascript ]
{
	if (zenPage.studioMode) {
		if (undoAction()) {
			return; // input text fields are handled by undoAction()
		}
	}

	if (this.canUndo()) {
		this._undoIndex--;
		var olddtl = this._undoBuffer[this._undoIndex];
		var oldAction = olddtl._oldCurrAction;
		var json = this.getComponentById('dtl');
		json.setContentObject(olddtl);
		var dtl = this.getDTLObject();

		// build index of actions
		this.decorateActionList(dtl.Actions);

		// initialize contents of diagram
		var svgWin = this.getSVGWindow();
		svgWin.setDTLModel(dtl,this._actionIndex);
		svgWin.setSource(dtl.SourceClass,dtl.SourceDocType);
		svgWin.setTarget(dtl.TargetClass,dtl.TargetDocType);
		svgWin.loadTransform(dtl.Language);

		this.updateGeneralForm();
		this.updateTable();
		this.selectAction(oldAction,true,false,false);
		this.setModified(true);

		if (this._undoIndex == 0) {
			// change undo button state
			var undo = self.document.getElementById('iconUndo');
			undo.disabled = true;
			undo.className = 'reIconDisabled';
			this.setModified(false);
		}
	}
}

ClientMethod clearUndoBuffer() [ Language = javascript ]
{
	delete this._undoBuffer;
	delete this._undoIndex;

	// change undo button state
	var undo = self.document.getElementById('iconUndo');
	undo.disabled = true;
	undo.className = 'reIconDisabled';
}

/// Remember the current state in the undo buffer.
ClientMethod addUndoAction() [ Language = javascript ]
{
	if (null == this._undoBuffer) {
		this._undoBuffer = new Array();
		this._undoIndex = 0;
	}

	// remember copy of entire model as state
	var dtl = this.getDTLObject();
	var olddtl = this.cloneObject(dtl);
	olddtl._oldCurrAction = this.currAction;

	this._undoBuffer[this._undoIndex] = olddtl;
	this._undoIndex++;

	// change undo button state
	var undo = self.document.getElementById('iconUndo');
	undo.disabled = false;
	undo.className = 'reIcon';
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

/// !!!
ClientMethod dump() [ Language = javascript ]
{
	var dtl = this.getDTLObject();
	var msg = '';
	for (var n = 0; n < dtl.Actions.length; n++) {
		msg += dtl.Actions[n]._class + ": " + dtl.Actions[n].Value + '->' + dtl.Actions[n].Property + '\n';
	}
	alert(msg);
}

/// Toggle display of settings box.
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
	this.resizeFormControls();
}

/// Launch test dialog.
ClientMethod toolTestDT() [ Language = javascript ]
{
	if (!this.canTest) {
		alert(this.msgNotPermitted);
		return;
	}
	// strip off ext
	var t = zenPage.dtlId.toString().split('.');
	t.length--;
	var name = t.join('.');

	var msgModified=$$$Text("This Data Transformation has been modified.")
	var msgWaitingCompile=$$$Text("This Data Transformation has not been compiled.")
	var msgWaitingReCompile=$$$Text("This Data Transformation has been modified and saved but not re-compiled.")
	var msgOptionA=$$$Text("Press OK to test with the current server version.")
	var msgOptionB=$$$Text("Press Cancel to return to the editor to save and compile.")
	var msgOptionC=$$$Text("Press Cancel to return to the editor to compile.")

	var needsCompiling = (this.CompileOlderThanSource(name))
	if (needsCompiling < 0) {
		alert(msgWaitingCompile);
		return;
	}
	if (this.pageModified) {
		var msg = msgModified+"\n\n"+msgOptionA+"\n\n"+msgOptionB
		if (!confirm(msg)) return;
	} else {
		if (needsCompiling) {
			var msg =msgWaitingReCompile+"\n\n"+msgOptionA+"\n\n"+msgOptionC
			if (!confirm(msg)) return;
		}
	}

	var parms = {
		TRANSFORM:name
	};
	if (this.studioMode) parms.STUDIO = 1;
	var url = zenLink('EnsPortal.Dialog.TestTransform.zen',this.studioMode);
	zenLaunchPopupWindow(url,'','status,scrollbars,resizable=yes,width=1004,height=800',parms);
}

ClientMethod dtlGenerator() [ Language = javascript ]
{
	document.location = zenLink('HS.InteropTools.HL7.GenerateDTL.UI.Main.zen?DT='+zenPage.getCurrentName() );
}

/// OnBlur handler for the detailValue and detailCondition controls, where we need to track the currently
/// selected text for the DTL Function Wizard. During the onblur, we capture the currently selected text
/// (if any) and store that in the _selectionData property of the <var>zenControl</var> Zen control. If we
/// populate _selectionData, we also set up a timer to call <method>detailClearSelection</method>() to clear
/// the data in 250 milliseconds. This means we will have the selection data if the user launches the wizard
/// within 250 ms, but don't keep lingering data when the user does something else.
ClientMethod detailBlur(zenControl) [ Language = javascript ]
{
	if (zenControl) {
		zenControl._selectionData = null;
		var control = zenControl.findElement('control');
		if (control) {
			var selectionData = null;
			if ((typeof control.selectionStart == 'number') && (typeof control.selectionEnd == 'number') && (control.selectionStart != control.selectionEnd)) {
				selectionData = { "text": control.value.substring(control.selectionStart,control.selectionEnd), "start": control.selectionStart, "end": control.selectionEnd };
			}
			else if (document.selection) {
				var range = document.selection.createRange();
				if (range && (range.parentElement() == control) && (range.text !== '') && (range.text != null)) {
					var controlRange = control.createTextRange();
					controlRange.moveToBookmark(range.getBookmark());
					var startRange = control.createTextRange();
					startRange.setEndPoint('EndToStart',controlRange);
					selectionData = { "text": range.text, "start": startRange.text.length, "end": startRange.text.length + range.text.length };
				}
			}
			if (selectionData) {
				zenControl._selectionData = selectionData;
				setTimeout('zenPage.detailClearSelection("' + zenControl.id + '");', 250);
			}
		}
	}
}

/// Clear out any data in the _selectionData property of the Zen control with id <var>controlId</var>.
ClientMethod detailClearSelection(controlId) [ Language = javascript ]
{
	if (controlId) {
		var control = zen(controlId);
		if (control) control._selectionData = null;
	}
}

/// Launch the property editor dialog.
ClientMethod editPropertyValue(name, type) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var value = zen(name).getValue();
	this._currProperty = name;

	if ((name == 'detailValue') || (name == 'detailCondition')) {
		this._currSelection = null;
		var control = zen(name);
		if (control && control._selectionData) {
			value = control._selectionData.text;
			this._currSelection = [ control._selectionData.start, control._selectionData.end ];
		}

		// simplistic check is OK -- wizard will run more thorough check
		var hasFunction = ((value.substring(0,2) == '..') || (value.substring(0,8).toLowerCase() == '##class('));
		var parms = { EDIT: (hasFunction ? 1 : 0) };
		if (this.studioMode) parms.STUDIO = 1;
		var url = zenLink('EnsPortal.Dialog.DTLFunctionWizard.zen',this.studioMode);
		this._currExpression = value;
		zenLaunchPopupWindow(url,this.addPopupSuffix('DTLFunctionWizard'),'status,scrollbars,resizable=yes,width=800,height=500',parms);
	}
	else {

		var dtl = zenPage.getDTLObject();

		// get list of context properties
		var list = '';

		var parms = {
			PROPERTY:name,
			TYPE:type,
			LANG:dtl.Language,
			RESPONSE:'',
			REQUEST:'',
			CONTEXTSUPER:'',
			CONTEXTLIST:'',
			NAMES:'',
			VALUE: (type == 'code' ? '' : value)	};
		if (this.studioMode) parms.STUDIO = 1;
		var url = zenLink('EnsPortal.Dialog.BusinessProcessValueEditor.zen',this.studioMode);
		zenLaunchPopupWindow(url,this.addPopupSuffix('DTLValue'),'status,scrollbars,resizable=yes,width=600,height=400',parms);
	}
}

ClientMethod getCurrentExpression() [ Language = javascript ]
{
	if (this._currExpression) {
		return this._currExpression;
	}
	return '';
}

/// In miniMode (dialog) apply changes..
ClientMethod applyChanges() [ Language = javascript ]
{
	var isValid = this.validateDT();
	if (!isValid) {
		alert($$$Text('There are errors in the actions you have specified. Please correct the problems before applying the changes.'));
		return false;
	}
	this.setModified(false);

	// copy changes back to BPL
	var opener = this.getOpener();
	if (opener && opener.zenPage && opener.zenPage.getCurrShape) {
		// get action list from BPL shape
		var shape = opener.zenPage.getCurrShape();
		var shapeModel = shape ? shape.model : null;
		var actionList = '';
		opener.zenPage.startUndoAction();
		if (shapeModel && shapeModel[this.which] && shapeModel[this.which].Activities) {
			shapeModel[this.which].Activities = [];

			for (var n = 0; n < this._actionList.length; n++) {
				var action = this._actionList[n];
				// note: we need to remove source and target from property references
				// the expression removes "target." from the start of the string and other appearances of "target." that come immediately
				// after whitespace or any other character that is not alphabetic, "%" or ".".
				// The string is reversed because Javascript regular expressions only support lookahead.
				var propExpr = action.Property.toString();
				propExpr = propExpr.split('').reverse().join('');
				var valueExpr = action.Value.toString();
				valueExpr = valueExpr.split('').reverse().join('');

				propExpr = propExpr.replace(/((\.tegrat)$|(\.tegrat(?=[^A-Za-z0-9\.\%])))/g,'');
				propExpr = propExpr.split('').reverse().join('');

				valueExpr = valueExpr.replace(/((\.ecruos)$|(\.ecruos(?=[^A-Za-z0-9\.\%])))/g,'');
				valueExpr = valueExpr.split('').reverse().join('');
				if (valueExpr == '') valueExpr = '""';

				// call API in parent page to add values because IE doesn't handle cross-window interactions well.
				opener.zenPage.addCallActivity(shapeModel[this.which], n==0, action.Action, action.Annotation, action.Key, propExpr, valueExpr);
			}
		}

		// update BPL editor (mini-mode)!
		opener.zenPage.updateActivitySettings(shape,true);
		opener.zenPage.endUndoAction();
	}

	// close window
	zenPage.cancelPopup();
}

/// In miniMode (dialog) cancel changes..
ClientMethod cancelChanges() [ Language = javascript ]
{
	zenPage.cancelPopup();
}

/// Set the modified flag for the page.
ClientMethod setModified(flag) [ Language = javascript ]
{
	if (this.miniMode) { // if we are in miniMode disable studioMode so we don't trigger Studio actions
		var studioMode = this.studioMode;
		this.studioMode = false;
		this.invokeSuper('setModified',arguments);
		this.studioMode = studioMode;
	}
	else {
		this.invokeSuper('setModified',arguments);
	}
}

/// Get the properties of the objects for use in miniMode (i.e. as the Request/Response Builder).
Method GetMiniModeData(ByRef pParms, Output pObject As %RegisteredObject) As %Status
{
	// If not in miniMode, don't do anything
	If '..miniMode {
		Set pObject = $$$NULLOREF
		Quit $$$OK
	}
	Set pObject = ##class(%ZEN.proxyObject).%New()
	// get lists of properties
	Set tSC = ..%GetPropertyListForClass(..classContextSuper, .tPropList)
	If $$$ISERR(tSC) Quit tSC
	Set pObject.context = tPropList

	Set tContextCount = tPropList.Count()
	// add in local context list
	For p=1:1:$L(..contextList,",") {
		Set tProp = $P(..contextList,",",p)
		If (tProp '= "") {
			Set tContextCount = tContextCount + 1
			Set tContextProp = ##class(%Library.ListOfDataTypes).%New()
			Do tContextProp.Insert(".."_tProp)
			Do tContextProp.Insert(tContextCount)
			Do tContextProp.Insert(0)
			Do pObject.context.Insert(tContextProp)

			Set tPropType = $P(..contextTypeList,",",p)
			If (tPropType'="") && ($E(tPropType)'="%") {
				Kill tPropTypeList
				Set tSC = ..%GetPropertyListForClass(tPropType, .tPropTypeList,".")
				Set tSubPropObject = "zzcontext"_tProp
				Set $property(pObject,tSubPropObject) = tPropTypeList
			}

		}
	}

	Set tSC = ..%GetPropertyListForClass(..classRequest, .tPropList)
	If $$$ISERR(tSC) Quit tSC
	Set pObject.request = tPropList

	Set tSC = ..%GetPropertyListForClass(..classResponse, .tPropList)
	If $$$ISERR(tSC) Quit tSC
	Set pObject.response = tPropList

	Set tSC = ..%GetPropertyListForClass(..classCallRequest, .tPropList)
	If $$$ISERR(tSC) Quit tSC
	Set pObject.callrequest = tPropList

	Set tSC = ..%GetPropertyListForClass(..classCallResponse, .tPropList)
	If $$$ISERR(tSC) Quit tSC
	Set pObject.callresponse = tPropList

	Quit $$$OK
}

/// For mini mode, create a list of properties within the given class that
/// can be used to drive the diagram contents.
ClassMethod %GetPropertyListForClass(pClass As %String = "", Output pList As %ListOfObjects, pAddLevel As %String = "") As %Status
{
	Set tSC = $$$OK
	Try {
		Kill pList
		Set pList = ##class(%Library.ListOfObjects).%New()
		If (pClass="") Quit

		Set tSC = ##class(Ens.Rule.Utils).GetPropertyList(.tList,pClass,,1)
		If $$$ISERR(tSC) Quit

		Set tHasChild = 0
		Set n = 0
		Set k = $O(tList(""))
		While (k'="") {
			// !!! check types !!!
			Set tName = $LG(tList(k),1)
			If (tName'="") {
				Set n = n + 1
				Set tProps = ##class(%Library.ListOfDataTypes).%New()
				//pAddLevel is 0 or more .
				Do tProps.Insert(pAddLevel_".." _ tName)
				Do tProps.Insert(n)
				Do tProps.Insert(0)
				Do pList.Insert(tProps)
			}
			Set k = $O(tList(k))
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)
	Set pLink(2) = $LB(..%OnGetPageName(),"#")
	Quit $$$OK
}

/// Get the (localized) name of the page based on whether we are in MiniMode or not.
Method %OnGetPageName() As %String
{
	If ..miniMode {
		Quit $case(..which, "Request": $$$Text("Request Builder"), "Response": $$$Text("Response Builder"), : $$$Text("Call Builder"))
	}
	Quit $$$Text("Data Transformation Builder","Ensemble")
}

ClientMethod setClassAndType(isSource, classname, doctype, noreload) [ Language = javascript ]
{
	var svgWin = this.getSVGWindow();
	if (svgWin) {
		var dtl = this.getDTLObject();
		classname = (classname != null ? classname : '');
		doctype = (doctype != null ? doctype : '');
		var propClass = (isSource ? 'SourceClass' : 'TargetClass');
		var propDocType = (isSource ? 'SourceDocType' : 'TargetDocType');
		if ((dtl[propClass] != classname) || (dtl[propDocType] != doctype)) {
			dtl[propClass] = classname;
			dtl[propDocType] = doctype;
			if (isSource) {
				svgWin.setSource(classname, doctype);
				zen('generalSourceClass').setValue(classname);
				zen('generalSourceDocType').setValue(doctype);
			}
			else {
				svgWin.setTarget(classname, doctype);
				zen('generalTargetClass').setValue(classname);
				zen('generalTargetDocType').setValue(doctype);
			}
			if (!noreload) {
				svgWin.loadTransform(dtl.Language);
			}
		}
	}
}

/// Show documentation for given action.
ClientMethod showActionDoc(type) [ Language = javascript ]
{
	var subtopic = type.toLowerCase();
	switch (subtopic) {
		case 'group':
			subtopic = 'xform_groups';
			break;
	}
	var win = window.open('/csp/docbook/DocBook.UI.Page.cls?KEY=EDTL_'+subtopic,'Docbook');
	try {
		win.focus();
	}
	catch(ex) {
	}
}

/// Find information on the ancestors of the current selected item.
/// Returns an array of all ancestors of the current action that are forEach
/// actions. Most immediate ancestor is at the start of the list.
ClientMethod getParentActionInfo() [ Language = javascript ]
{
	var ancestors = [];
	try {
		var action = this.getCurrentAction();
		if (action) {

			if (action._class == 'Ens.DTL.ForEach') {
				ancestors.push(action);
			}
			else if ((action._class == 'endeach') || (action._class == 'endif')) {
				action = action._parent;
			}

			// go up chain of parents
			var parent = action._parent;
			while (parent) {
				if (parent._class == 'Ens.DTL.ForEach') {
					ancestors.push(parent);
				}
				parent = (parent._class == 'endeach') || (parent._class == 'endif') ? parent._parent._parent : parent._parent;
			}

		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in getParentActionInfo');
	}
	return ancestors;
}

/// This callback is called at the end of the HTML HEAD section of the page.<br/>
/// (default implementation is a simple expression).
Method %OnDrawHTMLHead() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	&html<<script type="text/javascript">
if (!Array.prototype.indexOf) {
	Array.prototype.indexOf = function(searchElement,fromIndex) {
		fromIndex = !fromIndex ? 0 : parseInt(fromIndex,10);
		if (isNaN(fromIndex)) fromIndex = 0;
		var pos = -1;
		for (var i = 0; i < this.length; i++) {
			if (this[i] === searchElement) {
				pos = i;
				break;
			}
		}
		return pos;
	}
}
</script>>
	If ..studioMode {
		&html<<script type="text/javascript">
function document_save() {
	zenPage.saveDT(false);
}
function document_setTarget(classname, doctype) {
	if (zenPage && !zenPage._studioTargetSet) {
		zenPage._studioTargetSet = true;
		zenPage.setClassAndType(false, classname, doctype);
	}
}
function document_setSource(classname, doctype) {
	if (zenPage && !zenPage._studioSourceSet) {
		zenPage._studioSourceSet = true;
		zenPage.setClassAndType(true, classname, doctype);
	}
}
function document_undo() {
	zenPage.undo();
}
function document_canUndo() {
	var canUndo = zenPage.canUndo();
	zenPage.raiseEvent('CANUNDO',canUndo);
}
function document_redo() {
	// unimplemented
}
function document_getZoom() {
	zenPage.setResultsDiv('ZOOM',zenPage.currZoom);
}
function document_setZoom(zoom) {
	// This callback no longer needed as zoom is initialized elsewhere
}
function document_setReadOnly(ro) {
	if (zenPage && zenPage.setReadOnly) {
		zenPage.setReadOnly(ro);
	}
}
function document_setProperty(property, value) {
	if (zenPage && zenPage.isNew && (property == 'Language')) {
		var field = zenPage.getComponentById('generalLanguage');
		var dtl = zenPage.getDTLObject();
		if (field && dtl) {
			field.setValue(value);
			if (field.getValue() == value) {
				dtl[property] = value;
			}
		}
	}
}
</script>>
	}
	Quit $$$OK
}

/// Returns -1 if not compiled, 0 if compilation up to date, 1 if compilation older than source
ClassMethod CompileOlderThanSource(dtl) As %Integer [ ZenMethod ]
{
	#dim tUpToDate As %Boolean = 1
	#dim dtlClass = dtl_".cls"
	#dim tCompiledTS
	Do ##class(%RoutineMgr).TS(dtlClass,.tCompiledTS,.tUpToDate)
	If tCompiledTS = "" Quit -1
	Quit 'tUpToDate
}

/// Toggle Collapse/Expand one action based on row number and optional redraw Table 
ClientMethod toggleExpand(idx, expand, updateTable) [ Language = javascript ]
{
	if ('undefined' == typeof idx) {
		var action = this.getCurrentAction();
	}
	else {
		var action = this._actionIndex[idx];
	}
	if (action) {
		this.toggleExpandAction(action,expand);
		if (updateTable) {
			this.updateTable();
			this.selectAction(idx);
			this.updateDiagramActions();
		}
	}
}

/// Toggle Collapse/Expand all actions and optional redraw Table 
ClientMethod toggleExpandAll(expand, updateTable) [ Language = javascript ]
{
	this.allExpanded = expand;
	var action;
	for (var n = 0; n < this._actionIndex.length; n++) {
		action = this._actionIndex[n];
		if ((action)&&(action._parent==null)) {
			this.toggleExpandActionAndChildren(action,expand);
		}
	}
	if (updateTable) {
		this.updateTable();
		this.selectAction(-1);
		this.updateDiagramActions();
		this.updateToolbar();
		this.updateActionHeader();
	}
}

ClientMethod toggleExpandAction(action, expand) [ Language = javascript ]
{
	if (action) {
		/*	Toggle the top action in the group as expanded true or false. */
		action.Expanded = expand;
		/* toggle all those below in the group as display true or false
			but do not change the descendants' Expanded value*/
		var topParent = action._parent;
		var stopDepth = (topParent) ? topParent._depth : -1;
		var childIdx = action._count + 1;

		/* Used to monitor inner collapsed groups when expanding outer */
		var inCollapsed = false;
		var lastInCollapsedGroup = '';

		var currentAction = this._actionIndex[childIdx];
		while ((currentAction) && !(currentAction._parent==topParent) && (currentAction._depth>stopDepth)) {
			/*	if contracting then all inside need to be hidden
				otherwise need to maintain any child contracted setting.
			*/
			if (!expand) {
				currentAction._display=false;
			} else {
				/* we are expanding but do not want to expand those marked as collapsed. */
				if (inCollapsed) {
					currentAction._display=false;
				} else {
					currentAction._display=true;
				}
				/* See if last in collapsed group so can reset inCollapsed */
				if (inCollapsed) {
					if (currentAction == lastInCollapsedGroup) {
						inCollapsed = false;
						lastInCollapsedGroup = '';
					}
				} else if (this.canCollapseExpandAction(currentAction)) {
					/* Examine if an inner collapsed group and remember parent */
					if (('undefined' != typeof currentAction.Expanded) &&(!currentAction.Expanded)) {
						/* find last object in collapsed group */
						lastInCollapsedGroup = this.lastInGroup(currentAction);
						if (lastInCollapsedGroup) {inCollapsed = true;}
					}
				}
			}
			childIdx += 1;
			currentAction = this._actionIndex[childIdx];
		}
	}
}

/// Toggle Collapse/Expand for one action and all its descendants
ClientMethod toggleExpandActionAndChildren(action, expand) [ Language = javascript ]
{
	if (action) {
		/* toggle the top action in the group as expanded true or false */
		action.Expanded = expand;
		/* toggle all those below in the group as display true or false
			and change the .Expanded value*/
		var topParent = action._parent;
		var stopDepth = (topParent) ? topParent._depth : -1;
		var childIdx = action._count + 1;
		currentAction = this._actionIndex[childIdx];
		while ((currentAction) && !(currentAction._parent==topParent) && (currentAction._depth>stopDepth)) {
			if (this.canCollapseExpandAction(currentAction)) {
				currentAction.Expanded = expand;
			}
			currentAction._display=expand;
			childIdx += 1;
			currentAction = this._actionIndex[childIdx];
		}
	}
}

ClientMethod canRemoveAction(action) [ Language = javascript ]
{
	var canRemove = true;

	switch (action._class) {
		case 'Ens.DTL.Assign':
		case 'Ens.DTL.Trace':
		case 'Ens.DTL.Code':
		case 'Ens.DTL.SQL':
		case 'Ens.DTL.ForEach':
		case 'Ens.DTL.SubTransform':
		case 'Ens.DTL.If':
		case 'Ens.DTL.Break':
		case 'Ens.DTL.Comment':
		case 'Ens.DTL.Switch':
		case 'Ens.DTL.Case':
		case 'Ens.DTL.Group':
			break;
		default:
			canRemove = false;
			break;
	}
	return canRemove;
}

ClientMethod canCollapseExpandAction(action) [ Language = javascript ]
{
	var canCollapseExpand = false;

	switch (action._class) {
		case 'Ens.DTL.Case':
		case 'Ens.DTL.Default':
		case 'Ens.DTL.Group':
		case 'Ens.DTL.ForEach':
		case 'Ens.DTL.If':
		case 'Ens.DTL.Switch':
			canCollapseExpand = true;
			break;
		case 'Ens.DTL.Assign':
		case 'Ens.DTL.Break':
		case 'Ens.DTL.Code':
		case 'Ens.DTL.Trace':
		case 'Ens.DTL.SQL':
		case 'Ens.DTL.SubTransform':
		default:
			break;
	}
	return canCollapseExpand;
}

ClientMethod lastInGroup(action) [ Language = javascript ]
{
	var lastInGroup = '';
	switch(action._class) {
		case 'Ens.DTL.Case':
		case 'Ens.DTL.Default':
			if ((action.Actions) &&(action.Actions.length>0)) {
				var lastAction = action.Actions[action.Actions.length-1];
				if (this.canCollapseExpandAction(lastAction)) {
					lastInGroup = this.lastInGroup(lastAction);
				} else {
					lastInGroup = lastAction;
				}
			}
			break;
		case 'Ens.DTL.Group':
		case 'Ens.DTL.ForEach':
		case 'Ens.DTL.Switch':
			lastInGroup = action._synthList[0];
			break;
		case 'Ens.DTL.If':
			lastInGroup = action._synthList[1];
			break;
		default:
			break;
	}
	return lastInGroup;
}

ClassMethod GetBatchChildInfoArray(pMessageClass As %String, pDocType As %String, pSegment As %String, pNodeAddr As %String, ByRef pBatchChildInfoArray) As %Boolean [ Internal ]
{
	If pMessageClass = "" Return 0

		Try {

			If ($ClassMethod(pMessageClass,"%Extends","EnsLib.EDI.BatchDocument") && (pDocType '= "")) {

				Return $ClassMethod(pMessageClass, "GetBatchChildDTLInfoArray", pDocType, pSegment, pNodeAddr, .pBatchChildInfoArray)

			}

		} Catch {}

	Return 0
}

ClassMethod ValidateCodePy(pCode As %String) As %String [ Internal, ZenMethod ]
{
	// Retuns specific information about the source line location, and error type
	set ret=..ValidatePython(pCode)

	// if no syntax error then check for class case miss-spelling
	if ""=ret {
		set lineLength=$L(pCode,$C(10))
		set multiLineComment=0
		for lineNumber=1:1:lineLength {
			set line=$ZSTRIP($TR($P(pCode,$C(10),lineNumber),$C(13)),"<>W")
			continue:$E(line,1)="#" // skip comment lines
			if 'multiLineComment,$E(line,1,3)="""""""" {
				// assumes multi line comment starts with 3 double quotes prefix  
				set multiLineComment='multiLineComment
				continue
			} elseif multiLineComment,$E(line,*-3,*)="""""""" {
				// assumes multi line comment ends with 3 double quotes prefix
				set multiLineComment='multiLineComment
				continue
			}
			continue:multiLineComment
			set clsLength=$L(line,"iris.cls(")
			continue:clsLength<2
			for clsNumber=2:1:clsLength {
				// piece out the class names being used in code
				// replace leading and trailing single quote with double quote  
				set cls=$TR($P($P(line,"iris.cls(",clsNumber),")"),"'","""")
				if $E(cls)'="""", $E(cls,*)'="""" {
					// If not quoted, the class name may be a string variable
					// so python syntax check can detected a problem where quotes are not used
					continue
				}
				set cls=$E(cls,2,*-1)  // without quotes
				set tryCls=$Select("$_"[$E(cls):"%"_$E(cls,2,*),1:cls)

				// expand for %Library classes if needed
				if $L(tryCls,".")=1,"%"=$E(tryCls) set tryCls=$E(tryCls)_"Library."_$E(tryCls,2,*)
				// Quick filter bad values
				if tryCls'?.1"%"1.AN1.(1"."1.AN) {
					set ret=ret_$S(""'=ret:$C(13,10),1:"")_$$$FormatText($$$Text("Line %1"),lineNumber)
					set ret=ret_": "_$$$FormatText($$$Text("Classname not found"))_": iris.cls("""_cls_""")"
					continue
				}
				// More Exhaustive check
				if (('##class(%Dictionary.ClassDefinition).%ExistsId(tryCls)) || (("$_")[$E(cls))) {
					set item=0
					set ltryCls=$ZCVT(tryCls,"L")
					set upperTryCls($Increment(item))=$ZCVT(tryCls,"U")
					set:ltryCls["ise" upperTryCls($Increment(item))=$Replace(upperTryCls(1),"ISE","IZE")  // mistype "normalise" for "normalize"
					set:ltryCls["tor" upperTryCls($Increment(item))=$Replace(upperTryCls(1),"TOR","TER")  // mistype "adapter" instead of "adaptor"
					set:ltryCls["cie" upperTryCls($Increment(item))=$Replace(upperTryCls(1),"CIE","CEI")  // mistype "reciever" instead of "receiver"
					// mistype "behaviour" instead of "behavior"
					// mistype "colour" instead of "color"
					set:ltryCls["our" upperTryCls($Increment(item))=$Replace(upperTryCls(1),"OUR","OR")
					// misstype letter "l" for number "1" check
					// mistype "biul" instead of "biu1"
					if tryCls["l" {
						set position=0
						set l21startindex=item+1
						for {
							set position=$Find(tryCls,"l",position)
							quit:position=0 // real names can't start with a number
							continue:position=1
							if position=$L(tryCls) {
								set upperTryCls($Increment(item))=$ZCVT($E(tryCls,1,*-1)_"1","U")
							} else {
								set upperTryCls($Increment(item))=$ZCVT($E(tryCls,1,position-2)_"1"_$E(tryCls,position,*),"U")
							}
						}
					}
					set ret=ret_$S(""'=ret:$C(13,10),1:"")_$$$FormatText($$$Text("Line %1"),lineNumber)
					set ret=ret_": "_$$$FormatText($$$Text("Classname not found"))_": iris.cls("""_cls_""")"
					// There is a priority to the suggestions
					set item=""
					for {
						set item=$Order(upperTryCls(item),1,upperTryItem)
						quit:item=""
						&SQL(SELECT Name into :foundName FROM %Dictionary.ClassDefinition WHERE %UPPER(Name)=:upperTryItem)
						if SQLCODE=0 {
							set ret=ret_". "_$$$FormatText($$$Text("Did you mean classname %1?"),foundName)
							if tryCls["l" {
								set:(item>=$G(l21startindex,99999)) ret=ret_". "_$$$FormatText($$$Text("Hint substituted letter ""l"" for number ""1"""))_"."
							}
							quit
						}
					}

					continue
				}
				set method=$P($P($P(line,"iris.cls(",clsNumber),")",2),"(")
				// if the iris.cls reference is not follwed by a period then this is not a method call 
				continue:"."'=$E(method)
				// "%" methods are referenced by leading underscore "_" instead
				set method=$S("_"=$E(method,2):"%"_$E(method,3,*),1:$E(method,2,*))
				// Validate for known method names
				// use tryCls from earlier as has expanded %Library references
				if '##class(%Dictionary.MethodDefinition).%ExistsId(tryCls_"||"_method) {
					set item=0
					set lmethod=$ZCVT(method,"L")
					set upperMethodID($Increment(item))=$ZCVT(tryCls_"||"_method,"U")  // case sensitive
					set:lmethod["ise" upperMethodID($Increment(item))=$ZCVT(tryCls_"||"_$TR(method,"ise","ize"),"U")       // mistype "normalise" for "normalize"
					set:lmethod["tor" upperMethodID($Increment(item))=$ZCVT(tryCls_"||"_$Replace(method,"tor","ter"),"U")  // mistype "adapter" instead of "adaptor"
					set:lmethod["cie" upperMethodID($Increment(item))=$ZCVT(tryCls_"||"_$Replace(method,"cie","cei"),"U")  // mistype "reciever" instead of "receiver"
					// mistype "behaviour" instead of "behavior"
					// mistype "colour" instead of "color"
					set:lmethod["our" upperMethodID($Increment(item))=$ZCVT(tryCls_"||"_$Replace(method,"our","or"),"U") 
					// misstype letter "l" for number "1" check
					// mistype "biul" instead of "biu1"
					if method["l" {
						set position=0
						set l21startindex=item+1
						for {
							set position=$Find(method,"l",position)
							quit:position=0
							continue:position=1 // real names can't start with a number
							if position=$L(tryCls) {
								set upperMethodID($Increment(item))=$ZCVT(tryCls_"||"_$E(method,1,*-1)_"1","U")
							} else {
								set upperMethodID($Increment(item))=$ZCVT(tryCls_"||"_$E(method,1,position-2)_"1"_$E(method,position,*),"U")
							}
						}
					}
					set ret=ret_$S(""'=ret:$C(13,10),1:"")_$$$FormatText($$$Text("Line %1"),lineNumber)
					set ret=ret_": "_$$$FormatText($$$Text("Method name not found"))_": iris.cls("""_cls_""")."_method_"(...)"
					// There is a priority to the suggestions
					set item=""
					for {
						set item=$Order(upperMethodID(item),1,upperTryItem)
						quit:item=""
						&SQL(SELECT Name into :foundName FROM %Dictionary.MethodDefinition WHERE %UPPER(ID)=:upperTryItem)
						if SQLCODE=0 {
							set ret=ret_". "_$$$FormatText($$$Text("Did you mean method name %1?"),foundName)
							if method["l" {
								set:(item>=$G(l21startindex,99999999)) ret=ret_". "_$$$FormatText($$$Text("Hint substituted letter ""l"" for number ""1"""))_"."
							}
							quit
						}
					}
		
				}
			}
		}
	}
	return ret
}

ClassMethod ValidatePython(pCode As %String) As %String [ Internal, Language = python, ServerOnly = 1 ]
{
	import sys, traceback, ast
	ret=""
	try:
		# If source code is not yet available then return default
		# May occur on first loading of Editor
		if (pCode==None):
			return ret
		ast.parse(pCode,filename="Validate Python Code")
	except SyntaxError as e:
		# Check if the error is related to ".("
		if e.text and e.offset and ".(" in e.text[e.offset - 2 : e.offset]:
			# Ignore errors related to ".(" as ObjectScript Collections can use this syntax
			return ret
		else:
			exc_type, exc_value, exc_traceback = sys.exc_info()
			ret='\n'.join(traceback.format_exception_only(exc_type, exc_value))
	return ret
}

ClassMethod vDocsSyntaxRemoved(text, args, fullcode, replaced) As %String [ Internal, ZenMethod ]
{
    Set tSC = $$$OK
    Try {
        Kill args, fullcode
        Set fullcode = "", args = 0, replaced = text, newStart = 0
        Set matcher=##class(%Regex.Matcher).%New("(source\.\{[^}]+\})|(target\.\{[^}]+\})")
        Set matcher.Text = text
        While matcher.Locate() {
			If matcher.Start(1)>0 {Set id = 1} Else {Set id = 2}
			Set i = $INCREMENT(args)
			Set args(i) = matcher.Group(id)
			Set fullcode = "set arg"_i_" = "_matcher.Group(id)_$CHAR(13,10)_" "_fullcode
			Set replaced = $EXTRACT(replaced,1,matcher.Start-1-newStart)_"arg"_args_$EXTRACT(replaced,matcher.End-newStart,*)
			Set newStart = newStart + $LENGTH(args(i)) - $LENGTH("arg"_args)
        }
    } Catch ex {
       Set tSC = ex.AsStatus()
    }
    Return replaced
}

/// Resolve the language used in scope of a given action
ClientMethod getActionLanguage() [ Language = javascript ]
{
	var dtl = this.getDTLObject();
	var item = this.getCurrentAction();
	if (( item.LanguageOverride == 'python' ) || (item.LanguageOverride=="" && (dtl.Language == 'python'))){
		return 'python'
	} 
	return ''
}

}
