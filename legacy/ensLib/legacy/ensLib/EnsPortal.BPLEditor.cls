/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Business Process Designer.<br/>
/// This class should be considered as INTERNAL. 
Class EnsPortal.BPLEditor Extends (EnsPortal.Template.devPage, EnsPortal.Util.CodeEditorBase, EnsPortal.Util.PageLinks) [ System = 4 ]
{

Parameter JSINCLUDES;

/// Displayed name of this page.
Parameter PAGENAME = "Business Process Designer";

/// User needs READ permissions on either the %Ens_Code or the %Ens_BPL resource to view this page.
Parameter RESOURCE = "%Ens_BPL:READ,%Ens_Code:READ";

/// User needs WRITE permissions on either the %Ens_Code or the %Ens_BPL resource to make changes on this page.
Parameter EDITRESOURCE = "%Ens_BPL:WRITE,%Ens_Code:WRITE";

/// If this page has multiple views, this is its initial display mode.
Parameter DEFAULTVIEWMODE = "bpl";

/// URL for BP Designer.
Parameter DESIGNERURL As STRING = "EnsPortal.BPLEditor.zen";

Parameter DEFAULTZOOM As %Integer = 75;

/// ID (full classname) of Business Process to display.
Property bpId As %String(MAXLEN = 250, ZENURL = "BP");

/// Target SaveAs name of Business Process used by EnsPortal.Dialog.BusinessProcessSave.
Property bpAsName As %String;

/// Flag to indicate that the SVG diagram has been loaded.
Property diagramLoaded As %Boolean [ InitialExpression = 0 ];

/// URL for designer.
Property designerURL As %ZEN.Datatype.string [ InitialExpression = {..#DESIGNERURL} ];

/// ID (index number, 1-based) of current selected item.
Property currItem As %Integer;

/// Array of brief descriptions on each activity.
Property activityDesc As array Of %String;

/// Local copy of BPL diagram object.
Property %bpl As Ens.BPL.UI.Diagram;

/// Name of BPL first loaded.
Property originalId As %String [ Internal ];

/// Gridlines preference.
Property prefGridlines As %String [ Internal ];

/// AutoArrange preference.
Property prefAutoArrange As %Boolean [ InitialExpression = 0, Internal ];

/// Annotation display preference.
Property prefShowAnnotations As %Boolean [ InitialExpression = 1, Internal ];

/// If true, the settings area is visible.
Property settingsExpanded As %Boolean [ InitialExpression = 1, Internal ];

/// If true, the current BP does not exist.
Property bpMissing As %Boolean [ InitialExpression = 0, Internal ];

/// The current zoom level for the SVG diagram.
Property currZoom As %Integer [ InitialExpression = {..#DEFAULTZOOM}, Internal ];

/// Flag to control whether code elements are checked for leading whitespace.
Property codeValidation As %Boolean [ InitialExpression = 1 ];

Property msgDocReadOnly As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("This business process is read only")} ];

Property tipSave As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save this Business Process")} ];

Property tipCompile As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Compile this Business Process into executable code")} ];

Property tipNew As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Create a new Business Process")} ];

Property tipOpen As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Load an existing Business Process")} ];

Property tipSaveAs As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save this Business Process with a new name")} ];

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

#Loading {
	padding: 10px;
	font-size: 15pt;
	color: #D08080;
}

.expandoNode span {
	font-size: 12px;
	font-weight: bold;
	color: #404040;
}
.expandoNode {
	border-top: 1px solid gray;
}

a.radioSetCaption {
	font-size: 12px;
	color: #505050;
	font-weight: bold;
}

.checkboxCaption {
	font-size: 12px;
	color: #505050;
	font-weight: bold;
}

.iconBar {
	vertical-align: bottom;
}

td.diagramName {
	color: #404040;
	font-weight: bold;
}

td.shapeType {
	color: #808080;
	font-weight: bold;
}

td.shapeName {
	padding-left: 5px;
}

#propertyTitle {
	height: 40px;
	width: 40px;
	background: transparent;
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

#aDesc {
	color: #606060;
	padding: 4px;
}

#errorBox {
}

.errorTitle {
	color: white;
	border: 1px solid #D0D0D0;
	background: #F04040;
	margin-right: 20px;
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

.noActivity {
	font-size: 16px;
	color: #606060;
	font-weight: bold;
}

.noActivity2 {
	font-size: 12px;
	color: #606060;
}

.activityType {
	font-size: 18px;
	color: #606060;
	font-weight: bold;
}

.activityDesc {
	font-size: 12px;
	color: #606060;
}

#gContextList {
	width: 370px;
	overflow: auto;
}

#callRequestList,
#callResponseList,
#xsltParameterList {
	width: 365px;
	overflow: auto;
}

table.propListTable {
	width: 100%;
	border: 1px solid #C0C0C0;
	background: white;
}

.rowEven {
}

.rowOdd {
	background: #F0F0F0;
}

table.propListTable th {
	border-bottom: 1px solid #C0C0C0;
	color: #404040;
	font-size: 9pt;
	font-weight: bold;
	background: #E0E0E0;
	text-align: left;
	padding: 1px;
}

table.propListTable td {
	border-bottom: 1px solid #C0C0C0;
	color: #404040;
	font-size: 9pt;
	text-align: left;
	padding: 1px;
}

table.actionListTable {
	width: 100%;
	border: 1px solid #C0C0C0;
	background: white;
}

table.actionListTable th {
	border-bottom: 1px solid #C0C0C0;
	color: #404040;
	font-size: 9pt;
	font-weight: bold;
	background: #E0E0E0;
	text-align: left;
	padding: 1px;
}

table.actionListTable td {
	border-bottom: 1px solid #C0C0C0;
	color: #404040;
	font-size: 9pt;
	text-align: left;
	padding: 1px;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">

<!-- Get BPL Definition in JSON format -->
<jsonProvider id="bpl"
	OnRenderJSON="GetBPLDefinition"
	OnSubmitContent="SubmitBPL"
/>

<html id="resultsDiv" hidden="true">
<xml id="results" />
</html>
<hgroup id="mainHGroup" cellVAlign="top">
<html id="Loading" OnDrawContent="DrawLoadingMsg"/>
<svgFrame id="svg" svgPage="EnsPortal.SVG.BPLCanvas" zoom="85" width="1" height="1">
<parameter id="svgBPID" paramName="BP" value="#(%page.bpId)#"/>
<parameter id="svgStudioMode" paramName="STUDIO" value="" />
</svgFrame>
<vgroup id="propertyPane">
<html id="propertyTitle">
<span id="spanArrow" title="Hide or show the properties box" onclick="zenPage.toggleSettings();" onmouseover="this.style.color='#FFEEAA';" onmouseout="this.style.color='';">&#187;</span>
</html>
<tabGroup id="propertyTabs" showTabBar="true" onshowTab="zenPage.onshowTab();">
<tab caption="General" labelPosition="left" title="View and edit general settings for the process">
<form id="generalForm" labelPosition="top" cellStyle="padding:3px;">
<label label="General settings for this Business Process"/>
<radioSet id="gLanguage" label="Language" valueList="python,objectscript,basic" displayList="Python,ObjectScript,Basic" onchange="zenPage.diagramChange(zenThis);"/>
<hgroup>
<radioSet id="gLayout" label="Layout" valueList="automatic,manual" displayList="Automatic,Manual" onchange="zenPage.diagramChange(zenThis);"/>
<spacer width="15"/>
<text id="gWidth" label="Width" size="5" onchange="zenPage.diagramChange(zenThis);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<spacer width="5"/>
<text id="gHeight" label="Height" size="5" onchange="zenPage.diagramChange(zenThis);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
</hgroup>
<textarea id="gAnnotation" label="Annotation" rows="5" cols="40" onchange="zenPage.diagramChange(zenThis);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>

<text id="gIncludes" label="Includes" size="50" onchange="zenPage.diagramChange(zenThis);" hint="Optional list of ObjectScript include files" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<textarea id="gPyFromImport" label="Python From / Import statements" rows="5" cols="40" hint="Optional list of Python 'from' and 'import' statements supporting modules available to all Python sub-contexts" onchange="zenPage.diagramChange(zenThis);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>

<text id="gVersion" label="Version" size="5" onchange="zenPage.diagramChange(zenThis);" hint="Version number" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<checkbox id="gComponent" caption="Is component" onchange="zenPage.diagramChange(zenThis);" hint="If true, include this process in the Component Library"/>

</form>
</tab>
<tab caption="Context" labelPosition="left" title="View and edit context properties">
<form id="contextForm" labelPosition="top" cellStyle="padding:3px;">
<label label="Context for this Business Process"/>

<hgroup cellVAlign="top" label="Request Class" hint="Incoming request for this process">
<text id="cRequest" size="40" onchange="zenPage.diagramChange(zenThis);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.selectMessageClass('Request','cRequest',true);" title="Select new class"/>
</hgroup>

<hgroup cellVAlign="top" label="Response Class" hint="Response returned by this process">
<text id="cResponse" size="40" onchange="zenPage.diagramChange(zenThis);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.selectMessageClass('Response','cResponse',true);" title="Select new class"/>
</hgroup>

<hgroup cellVAlign="top" label="Context Superclass" hint="Optional superclass for generated context class">
<text id="cContextSuper" size="40" onchange="zenPage.diagramChange(zenThis);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.selectContextClass();" title="Select new context superclass"/>
</hgroup>

<hgroup>
<label label="Context properties"/>
<image src="deepsee/ds_plus_16.gif" title="Add a context property" onclick="zenPage.editContextProperty(-1);"/>
</hgroup>
<html id="gContextList"/>
</form>
</tab>
<tab id="activityTab" caption="Activity" labelPosition="left" title="View and edit details for a selected item">
<html id="aDesc"/>
<!-- 2 forms: one for activities, one for connectors -->
<form id="activityForm" labelPosition="top" cellStyle="padding-left:3px;">
<html id="errorBox"/>

<hgroup id="aNameGroup" hint="Caption for shape">
<text id="aName" label="Name" size="30" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
</hgroup>

<hgroup>
<hgroup hint="Position of shape">
<text id="axPos" label="x" size="2" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<spacer width="5"/>
<text id="ayPos" label="y" size="2" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
</hgroup>
<spacer width="5"/>
<checkbox id="aDisabled" caption="Disabled" onchange="zenPage.activityChange();"/>
</hgroup>

<spacer height="5"/>

<textarea id="aAnnotation" label="Annotation" rows="3" cols="35" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>

<!-- there is a group of controls for each type of shape -->
<vgroup id="vgAssign" hidden="true">
<select id="assignAction" label="Action" valueList="set,append,clear,insert,remove" showEmpty="false" onchange="zenPage.activityChange();"/>

<hgroup cellVAlign="top" label="Property">
<text id="assignProperty" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('assignProperty','property',zenPage.getControlLanguage('assign'));" title="Edit value"/>
</hgroup>

<hgroup cellVAlign="top" label="Value">
<text id="assignValue" size="40" onchange="zenPage.activityChange(1);" onvalidate="return zenPage.validateExpression(zenThis.getValue(),zenPage.getControlLanguage('assign'),zenThis);" invalidMessage="Expression is not valid" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('assignValue','value',zenPage.getControlLanguage('assign'));" title="Edit value"/>
<html><br/></html>
</hgroup>

<hgroup cellVAlign="top">
<select id="assignLanguageOverride" label="Value Language Override" valueList="python,objectscript" displayList="Python,ObjectScript" showEmpty="true" onchange="zenPage.activityChange();"/>
</hgroup>

<text id="assignKey" size="20" label="Key" onchange="zenPage.activityChange(1);" hint="For collection properties, this string specifies the member of the collection that is the target of this assignment." onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
</vgroup>

<vgroup id="vgCall" hidden="true">

<hgroup cellVAlign="top" label="Target" hint="Name of Operation or Process to call">
<text id="callTarget" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('callTarget','host');" title="Edit value"/>
</hgroup>

<hgroup cellVAlign="top">
<checkbox id="callAsync" label="Asynchronous" onchange="zenPage.activityChange();"/>
<spacer width="10"/>
<hgroup cellVAlign="top" label="Timeout" hint="Timeout for synchronous call">
<text id="callTimeout" size="5" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('callTimeout','duration');" title="Edit value"/>
</hgroup>
</hgroup>

<expando caption="Request" animate="true">
<hgroup cellVAlign="top" label="Request Message Class">
<text id="callRequestType" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.selectMessageClass('Request','callRequestType');" title="Select new class"/>
</hgroup>
<spacer height="5"/>
<hgroup>
<label label="Request Actions"/>
<image src="deepsee/ds_plus_16.gif" title="Add a request action" onclick="zenPage.editAction('Request',-1);"/>
</hgroup>
<html id="callRequestList"/>
<spacer height="5"/>
<button caption="Request Builder" controlClass="commandButton" title="Launch the request builder" onclick="zenPage.showBuilder('Request');"/>
<spacer height="5"/>
</expando>

<expando caption="Response" animate="true">
<hgroup cellVAlign="top" label="Response Message Class">
<text id="callResponseType" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.selectMessageClass('Response','callResponseType');" title="Select new class"/>
</hgroup>
<spacer height="5"/>
<hgroup>
<label label="Response Actions"/>
<image src="deepsee/ds_plus_16.gif" title="Add a response action" onclick="zenPage.editAction('Response',-1);"/>
</hgroup>
<html id="callResponseList"/>
<spacer height="5"/>
<button caption="Response Builder" controlClass="commandButton" title="Launch the response builder" onclick="zenPage.showBuilder('Response');"/>
<spacer height="5"/>
</expando>
<html><br/></html>

<hgroup cellVAlign="top">
<select id="callLanguageOverride" label="Value Language Override for Request and Response assigns" valueList="python,objectscript" displayList="Python,ObjectScript" showEmpty="true" onchange="zenPage.activityChange();"/>
</hgroup>

</vgroup>

<vgroup id="vgCode" hidden="true">

<hgroup cellVAlign="top" label="Code">
<textarea id="codeCode" rows="15" cols="35" onchange="zenPage.activityChange(1);" onvalidate="return zenPage.validateCode(zenThis.getValue(),null,null,zenPage.getControlLanguage('code'),zenThis);" invalidMessage="Code contains lines with no leading whitespace." onkeypress="return zenPage.codeKeyPress(zenThis,zenEvent,zenPage.getControlLanguage('code'));" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('codeCode','code',zenPage.getControlLanguage('code'));" title="Edit value"/>
</hgroup>
<checkbox id="codeNoValidation" caption="Disable code validation" title="Disable code validation for all code blocks in this Business Process" onchange="zenPage.changeCodeValidation(zenThis.value);" />
<hgroup cellVAlign="top">
<select id="codeLanguageOverride" label="Code Language Override" valueList="python,objectscript" displayList="Python,ObjectScript" showEmpty="true" onchange="zenPage.activityChange();"/>
</hgroup>
</vgroup>

<vgroup id="vgSQL" hidden="true">
<hgroup cellVAlign="top" label="SQL">
<textarea id="sqlCode" rows="4" cols="35" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('sqlCode','sql');" title="Edit value"/>
</hgroup>
</vgroup>

<vgroup id="vgDelay" hidden="true">
<hgroup cellVAlign="top" label="Duration" hint="Wait for a specified period of time">
<text id="delayDuration" size="30" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('delayDuration','duration');" title="Edit value"/>
</hgroup>

<hgroup cellVAlign="top" label="Until" hint="Wait until the specified time">
<text id="delayUntil" size="30" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('delayUntil','dateTime');" title="Edit value"/>
</hgroup>

</vgroup>

<vgroup id="vgIf" hidden="true">
<hgroup cellVAlign="top" label="Condition" hint="Condition to evaluate">
<text id="ifCondition" size="40" onchange="zenPage.activityChange(1);"  onvalidate="return zenPage.validateExpression(zenThis.getValue(),zenPage.getControlLanguage('if'),zenThis);" invalidMessage="Condition is not valid" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('ifCondition','value',zenPage.getControlLanguage('if'));" title="Edit value"/>
</hgroup>

<hgroup cellVAlign="top">
<select id="ifLanguageOverride" label="Conditon Language Override" valueList="python,objectscript" displayList="Python,ObjectScript" showEmpty="true" onchange="zenPage.activityChange();"/>
</hgroup>
</vgroup>

<vgroup id="vgWhile" hidden="true">
<hgroup cellVAlign="top" label="Condition" hint="Condition to evaluate">
<text id="whileCondition" size="40" onchange="zenPage.activityChange(1);"  onvalidate="return zenPage.validateExpression(zenThis.getValue(),zenPage.getControlLanguage('while'),zenThis);" invalidMessage="Condition is not valid" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('whileCondition','value',zenPage.getControlLanguage('while'));" title="Edit value"/>
</hgroup>
<hgroup cellVAlign="top">
<select id="whileLanguageOverride" label="Condition Language Override" valueList="python,objectscript" displayList="Python,ObjectScript" showEmpty="true" onchange="zenPage.activityChange();"/>
</hgroup>
</vgroup>

<vgroup id="vgUntil" hidden="true">
<hgroup cellVAlign="top" label="Condition" hint="Condition to evaluate">
<text id="untilCondition" size="40" onchange="zenPage.activityChange(1);"  onvalidate="return zenPage.validateExpression(zenThis.getValue(),zenPage.getControlLanguage('until'),zenThis);" invalidMessage="Condition is not valid" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('untilCondition','value',zenPage.getControlLanguage('until'));" title="Edit value"/>
</hgroup>
<hgroup cellVAlign="top">
<select id="untilLanguageOverride" label="Condition Language Override" valueList="python,objectscript" displayList="Python,ObjectScript" showEmpty="true" onchange="zenPage.activityChange();"/>
</hgroup>
</vgroup>

<vgroup id="vgForEach" hidden="true">
<hgroup cellVAlign="top" label="Property" hint="Collection to iterate over">
<text id="foreachProperty" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('foreachProperty','property');" title="Edit value"/>
</hgroup>

<hgroup cellVAlign="top" label="Key" hint="Property to use as a key while iterating over the source collection">
<text id="foreachKey" size="30" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('foreachKey','property');" title="Edit value"/>
</hgroup>
</vgroup>

<vgroup id="vgSwitch" hidden="true">
</vgroup>

<vgroup id="vgBranch" hidden="true">
<hgroup cellVAlign="top" label="Condition" hint="Condition to evaluate">
<text id="branchCondition" size="40" onchange="zenPage.activityChange(1);"  onvalidate="return zenPage.validateExpression((zenThis.getValue()), zenPage.getControlLanguage('branch'),zenThis);" invalidMessage="Condition is not valid" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('branchCondition','value',zenPage.getControlLanguage('branch'));" title="Edit value"/>
</hgroup>

<hgroup cellVAlign="top">
<select id="branchLanguageOverride" label="Condition Language Override" valueList="python,objectscript" displayList="Python,ObjectScript" showEmpty="true" onchange="zenPage.activityChange();"/>
</hgroup>

<hgroup cellVAlign="top" label="Label" hint="Name of label to branch to">
<text id="branchLabel" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('branchLabel','labels');" title="Edit value"/>
</hgroup>
</vgroup>

<vgroup id="vgLabel" hidden="true">
</vgroup>

<vgroup id="vgSync" hidden="true">

<hgroup cellVAlign="top" label="Calls" hint="List of calls to wait on">
<text id="syncCalls" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('syncCalls','calls');" title="Edit value"/>
</hgroup>

<select id="syncType" label="Type" valueList="all,any" displayList="All,Any" showEmpty="false" onchange="zenPage.activityChange();"/>
<hgroup cellVAlign="top" label="Timeout">
<text id="syncTimeout" size="5" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('syncTimeout','duration');" title="Edit value"/>
</hgroup>

<checkbox id="syncAllowResync" caption="Allow Resync" onchange="zenPage.activityChange();"/>
</vgroup>

<vgroup id="vgTrace" hidden="true">
<hgroup cellVAlign="top" label="Value" hint="Message to write">
<text id="traceValue" size="40" onchange="zenPage.activityChange(1);" onvalidate="return zenPage.validateExpression(zenThis.getValue(),zenPage.getControlLanguage('trace'),zenThis);" invalidMessage="Expression is not valid" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('traceValue','value',zenPage.getControlLanguage('trace'));" title="Edit value"/>
</hgroup>
<hgroup cellVAlign="top">
<select id="traceLanguageOverride" label="Value Language Override" valueList="python,objectscript" displayList="Python,ObjectScript" showEmpty="true" onchange="zenPage.activityChange();"/>
</hgroup>
</vgroup>

<vgroup id="vgAlert" hidden="true">
<hgroup cellVAlign="top" label="Value" hint="Value passed along with the alert">
<text id="alertValue" size="40" onchange="zenPage.activityChange(1);" onvalidate="return zenPage.validateExpression(zenThis.getValue(),zenPage.getControlLanguage('alert'),zenThis);" invalidMessage="Expression is not valid" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('alertValue','value',zenPage.getControlLanguage('alert'));" title="Edit value"/>
</hgroup>
<hgroup cellVAlign="top">
<select id="alertLanguageOverride" label="Value Language Override" valueList="python,objectscript" displayList="Python,ObjectScript" showEmpty="true" onchange="zenPage.activityChange();"/>
</hgroup>
</vgroup>

<vgroup id="vgMilestone" hidden="true">
<hgroup cellVAlign="top" label="Value" hint="Value to log for this milestone">
<text id="milestoneValue" size="40" onchange="zenPage.activityChange(1);" onvalidate="return zenPage.validateExpression(zenThis.getValue(),zenPage.getControlLanguage('milestone'),zenThis);" invalidMessage="Expression is not valid" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('milestoneValue','value',zenPage.getControlLanguage('milestone'));" title="Edit value"/>
</hgroup>
<hgroup cellVAlign="top">
<select id="milestoneLanguageOverride" label="Value Language Override" valueList="python,objectscript" displayList="Python,ObjectScript" showEmpty="true" onchange="zenPage.activityChange();"/>
</hgroup>
</vgroup>

<vgroup id="vgTransform" hidden="true">
<hgroup cellVAlign="top" label="Data Transformation Class">
<text id="transformClass" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.findTransform('transformClass');" title="Select a Data Transformation Class"/>
</hgroup>
<spacer height="5"/>
<button id="dtlEditorLink" caption="DTL Editor" controlClass="commandButton" title="Launch the DTL editor" onclick="zenPage.showDTLEditor();"/>
<spacer height="5"/>

<hgroup cellVAlign="top" label="Source">
<text id="transformSource" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('transformSource','property');" title="Edit value"/>
</hgroup>
<hgroup cellVAlign="top" label="Target">
<text id="transformTarget" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('transformTarget','property');" title="Edit value"/>
</hgroup>
</vgroup>

<vgroup id="vgRule" hidden="true">

<hgroup cellVAlign="top" label="Rule Name" hint="Name of Business Rule to invoke">
<text id="ruleRule" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.findRule('ruleRule');" title="Edit value"/>
</hgroup>

<spacer height="5"/>
<button id="ruleEditorLink" caption="Rule Editor" controlClass="commandButton" title="Launch the Rule Editor" onclick="zenPage.showRuleEditor();"/>
<spacer height="5"/>

<hgroup cellVAlign="top" label="Rule Context" hint="Context object to pass to rules engine">
<text id="ruleRuleContext" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('ruleRuleContext','property');" title="Edit value"/>
</hgroup>

<hgroup cellVAlign="top" label="Result Location" hint="Where to place rule result">
<text id="ruleResultLocation" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('ruleResultLocation','property');" title="Edit value"/>
</hgroup>

<hgroup cellVAlign="top" label="Reason Location" hint="Where to place reason why rule fired">
<text id="ruleReasonLocation" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('ruleReasonLocation','property');" title="Edit value"/>
</hgroup>
</vgroup>

<vgroup id="vgScope" hidden="true">
</vgroup>
<vgroup id="vgFlow" hidden="true">
</vgroup>
<vgroup id="vgJoin" hidden="true">
</vgroup>
<vgroup id="vgSequence" hidden="true">
</vgroup>

<vgroup id="vgXPATH" hidden="true">
<hgroup cellVAlign="top" label="Source" hint="Source data">
<text id="xpathSource" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('xpathSource','property');" title="Edit value"/>
</hgroup>

<hgroup cellVAlign="top" label="Property" hint="Destination for result">
<text id="xpathProperty" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('xpathProperty','property');" title="Edit value"/>
</hgroup>

<hgroup cellVAlign="top" label="Context" hint="Document context">
<text id="xpathContext" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('xpathContext','string');" title="Edit value"/>
</hgroup>

<hgroup cellVAlign="top" label="Expression" hint="XPath expression">
<text id="xpathExpression" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('xpathExpression','xpath');" title="Edit value"/>
</hgroup>

<hgroup cellVAlign="top" label="Prefix Mappings" hint="Prefix to namespace mappings">
<text id="xpathPrefixMappings" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('xpathPrefixMappings','string');" title="Edit value"/>
</hgroup>

<hgroup cellVAlign="top" label="Schema Specification" hint="XPath schema specification">
<text id="xpathSchemaSpec" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('xpathSchemaSpec','string');" title="Edit value"/>
</hgroup>

</vgroup>

<vgroup id="vgXSLT" hidden="true">
<hgroup cellVAlign="top" label="XSL URL" hint="URL of XSL stylesheet">
<text id="xsltXSLURL" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('xsltXSLURL','xslurl');" title="Edit value"/>
</hgroup>

<hgroup cellVAlign="top" label="Source" hint="Input stream for XSL transform">
<text id="xsltSource" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('xsltSource','property');" title="Edit value"/>
</hgroup>

<hgroup cellVAlign="top" label="Target" hint="Output location for XSL transform">
<text id="xsltTarget" size="40" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('xsltTarget','property');" title="Edit value"/>
</hgroup>

<hgroup>
<label label="Parameters"/>
<image src="deepsee/ds_plus_16.gif" title="Add a xslt parameter" onclick="zenPage.editXSLTParm('');"/>
</hgroup>
<html id="xsltParameterList"/>

<select id="xsltVersion" label="XSLT Version" hint="Default is 1.0" valueList="1.0,2.0" displayList="1.0,2.0" showEmpty="false" onchange="zenPage.activityChange();"/>

</vgroup>

<vgroup id="vgCatch" hidden="true">
<text id="catchFault" size="25" label="Fault" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
</vgroup>

<vgroup id="vgCatchAll" hidden="true">
</vgroup>

<vgroup id="vgCompensate" hidden="true">
<text id="compensateTarget" size="25" label="Target" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
</vgroup>

<vgroup id="vgThrow" hidden="true">
<text id="throwFault" size="25" label="Fault" onchange="zenPage.activityChange(1);" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>
</vgroup>

</form>

<form id="connectorForm" labelPosition="top" cellStyle="padding-left:3px;">
<text id="cName" label="Name" hint="Caption for connector" size="25" onchange="zenPage.connectorChange();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);"/>

<hgroup id="cConditionGroup" cellVAlign="top" label="Condition" hint="Condition for this branch">
<text id="cCondition" size="40" onchange="zenPage.connectorChange();" onkeyup="zenPage.textControlKeyUp(zenEvent,zenThis);" onkeydown="zenPage.textControlKeyDown(zenThis);" onvalidate="return zenPage.validateExpression(zenThis.getValue(),zenPage.getControlLanguage('c'),zenThis);" invalidMessage="Expression is not valid"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.editPropertyValue('cCondition','value',zenPage.getControlLanguage('c'));" title="Edit value"/>
</hgroup>
<hgroup cellVAlign="top">
<select id="cLanguageOverride" label="Condition Language Override" valueList="python,objectscript" displayList="Python,ObjectScript" showEmpty="true" onchange="zenPage.connectorChange(0);"/>
</hgroup>
</form>

</tab>
<tab caption="Preferences" labelPosition="left" title="View and edit preferences">
<vgroup>
<form id="prefForm" labelPosition="top" cellStyle="padding-left:3px;">
<label label="Adjust the appearance of the Business Process Designer"/>
<spacer height="5"/>
<radioSet id="prefGridlines" label="Gridlines" displayList="None,Light,Medium,Dark" valueList="none,light,medium,dark" onchange="zenPage.changePreference('gridlines',zenThis.getValue());"/>
<spacer height="5"/>
<checkbox id="prefShowAnnotations" caption="Show annotations" onchange="zenPage.changePreference('showAnnotations',zenThis.getValue());"/>
<spacer height="5"/>
<checkbox id="prefAutoArrange" caption="Auto arrange" hint="If true, automatically arrange the diagram as shapes are added to it" onchange="zenPage.changePreference('autoArrange',zenThis.getValue());"/>
</form>
</vgroup>
</tab>
</tabGroup>
</vgroup>
</hgroup>
</pane>
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method DrawLoadingMsg(pSeed As %String) As %Status
{
	If (..bpMissing) {
		Write $$$FormatText($$$Text("Business Process %1 does not exist."),..EscapeHTML(..bpId))
	}
	ElseIf (..bpId="") {
		Write $$$Text("Creating new Business Process...")
	}
	Else {
		Write $$$FormatText($$$Text("Preparing diagram for %1..."),..EscapeHTML(..bpId))
	}
	Quit $$$OK
}

/// Get the (localized) title string for the page.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $S(..bpId="":$$$Text("Business Process"),1:..bpId)
}

Method %OnGetPageName() As %String
{
	Quit $$$Text("Business Process Designer","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	
	If ..studioMode Quit $$$OK

	// commands
	// $LB(id,caption,help,onclick)
	Set pCommands(1) = $LB("cmdNew",$$$Text("New"),..tipNew,"zenPage.newBP();")
	Set pCommands(2) = $LB("cmdOpen",$$$Text("Open"),..tipOpen,"zenPage.loadBP();")
	Set pCommands(3) = $LB("cmdSave",$$$Text("Save"),..tipSave,"zenPage.saveBP(false);")
	Set pCommands(4) = $LB("cmdSaveAs",$$$Text("Save As"),..tipSaveAs,"zenPage.saveBP(true);")
	Set pCommands(5) = $LB("cmdCompile",$$$Text("Compile"),..tipCompile,"zenPage.compile();")
	
	Quit $$$OK
}

/// Add content to ribbon bar.
Method OnDrawRibbon() As %Status
{
	&html<<td nowrap="1" valign="middle">>

	Set hlpZoom = $$$TextHTML("Set the size of the BPL diagram")

	Set msgAdd = $$$TextHTML("Add Activity")
	Set hlpAdd = $$$TextHTML("Add a new activity to the business process")

	Set msgGroup = $$$TextHTML("Group Items")
	Set hlpGroup = $$$TextHTML("Place selected items within a group")

	&html<<table>>
	&html<<tr>>

	&html<<td width="24">&nbsp;</td>>

	// zoom
	Set tSvg = ..%GetComponentById("svg")

	&html<<td>>
	&html<<select id="selectZoom" style="color: #404080;" title="#(hlpZoom)#" onchange="zenPage.setZoom(this.value);">>
	For tZoom = 25,50,75,85,100,110,125,150,200 {
		&html<<option value="#(tZoom)#" #($S(..currZoom=tZoom:"selected=""1""",1:""))#>&nbsp;#(tZoom_"%")#&nbsp;</option>>
	}
	&html<</select>>
	&html<</td>>

	&html<<td width="24">&nbsp;</td>>

	// list of create options
	// tShape(n) = $LB(name,caption,title) || ""

	Set tShape($I(n)) = $LB("alert",$$$LocalizeText("EnsBPL","Alert","Alert"),$$$LocalizeText("EnsBPL","AddAlert","Add an alert action"))
	Set tShape($I(n)) = $LB("assign",$$$LocalizeText("EnsBPL","Assign","Assign"),$$$LocalizeText("EnsBPL","AddAssign","Add an assign action"))
	Set tShape($I(n)) = $LB("break",$$$LocalizeText("EnsBPL","Break","Break"),$$$LocalizeText("EnsBPL","AddBreak","Add a break"))
	Set tShape($I(n)) = $LB("code",$$$LocalizeText("EnsBPL","Code","Code"),$$$LocalizeText("EnsBPL","AddCode","Add a code block"))
	Set tShape($I(n)) = $LB("continue",$$$LocalizeText("EnsBPL","Continue","Continue"),$$$LocalizeText("EnsBPL","AddContinue","Add a continue"))
	Set tShape($I(n)) = $LB("call",$$$LocalizeText("EnsBPL","Call","Call"),$$$LocalizeText("EnsBPL","AddCall","Add a call to an operation or process"))
	Set tShape($I(n)) = $LB("delay",$$$LocalizeText("EnsBPL","Delay","Delay"),$$$LocalizeText("EnsBPL","AddDelay","Add a delay to this process"))
	Set tShape($I(n)) = $LB("empty",$$$LocalizeText("EnsBPL","Empty","Empty"),$$$LocalizeText("EnsBPL","AddEmpty","Add an empty action"))
	Set tShape($I(n)) = $LB("reply",$$$LocalizeText("EnsBPL","Reply","Reply"),$$$LocalizeText("EnsBPL","AddReply","Add a reply action"))
	Set tShape($I(n)) = $LB("rule",$$$LocalizeText("EnsBPL","Rule","Rule"),$$$LocalizeText("EnsBPL","AddRule","Add a rule"))
	Set tShape($I(n)) = $LB("sql",$$$LocalizeText("EnsBPL","SQL","SQL"),$$$LocalizeText("EnsBPL","AddSQL","Add an SQL action"))
	Set tShape($I(n)) = $LB("sync",$$$LocalizeText("EnsBPL","Sync","Sync"),$$$LocalizeText("EnsBPL","AddSync","Add a sync action"))
	Set tShape($I(n)) = $LB("trace",$$$LocalizeText("EnsBPL","Trace","Trace"),$$$LocalizeText("EnsBPL","AddTrace","Add a trace statement"))
	Set tShape($I(n)) = $LB("transform",$$$LocalizeText("EnsBPL","Transform","Transform"),$$$LocalizeText("EnsBPL","AddTransform","Add a data transformation"))
	Set tShape($I(n)) = $LB("xpath",$$$LocalizeText("EnsBPL","XPATH","XPATH"),$$$LocalizeText("EnsBPL","AddXPATH","Add an XPATH action"))
	Set tShape($I(n)) = $LB("xslt",$$$LocalizeText("EnsBPL","XSLT","XSLT"),$$$LocalizeText("EnsBPL","AddXSLT","Add an XSLT action"))
	Set tShape($I(n)) = ""
	Set tShape($I(n)) = $LB("if",$$$LocalizeText("EnsBPL","If","If"),$$$LocalizeText("EnsBPL","AddIf","Add an if block"))
	Set tShape($I(n)) = $LB("switch",$$$LocalizeText("EnsBPL","Switch","Switch"),$$$LocalizeText("EnsBPL","AddSwitch","Add a switch block"))
	Set tShape($I(n)) = $LB("branch",$$$LocalizeText("EnsBPL","Branch","Branch"),$$$LocalizeText("EnsBPL","Add","Add a branch condition"))
	Set tShape($I(n)) = $LB("label",$$$LocalizeText("EnsBPL","Label","Label"),$$$LocalizeText("EnsBPL","AddLabel","Add a label"))
	Set tShape($I(n)) = $LB("milestone",$$$LocalizeText("EnsBPL","Milestone","Milestone"),$$$LocalizeText("EnsBPL","AddMilestone","Add a milestone"))
	Set tShape($I(n)) = ""
	Set tShape($I(n)) = $LB("scope",$$$LocalizeText("EnsBPL","Scope","Scope"),$$$LocalizeText("EnsBPL","AddScope","Add a scope block"))
	Set tShape($I(n)) = $LB("flow",$$$LocalizeText("EnsBPL","Flow","Flow"),$$$LocalizeText("EnsBPL","AddFlow","Add a flow block"))
	Set tShape($I(n)) = $LB("join",$$$LocalizeText("EnsBPL","Join","Join"),$$$LocalizeText("EnsBPL","AddJoin","Add a join activity"))
	Set tShape($I(n)) = $LB("sequence",$$$LocalizeText("EnsBPL","Sequence","Sequence"),$$$LocalizeText("EnsBPL","AddSequence","Add a sequence"))
	Set tShape($I(n)) = ""
	Set tShape($I(n)) = $LB("foreach",$$$LocalizeText("EnsBPL","ForEach","ForEach"),$$$LocalizeText("EnsBPL","AddForEach","Add a ForEach loop"))
	Set tShape($I(n)) = $LB("while",$$$LocalizeText("EnsBPL","While","While"),$$$LocalizeText("EnsBPL","AddWhile","Add a While loop"))
	Set tShape($I(n)) = $LB("until",$$$LocalizeText("EnsBPL","Until","Until"),$$$LocalizeText("EnsBPL","AddUntil","Add an Until loop"))
	Set tShape($I(n)) = ""
	Set tShape($I(n)) = $LB("throw",$$$LocalizeText("EnsBPL","Throw","Throw"),$$$LocalizeText("EnsBPL","AddThrow","Add a throw action"))
	Set tShape($I(n)) = $LB("catch",$$$LocalizeText("EnsBPL","Catch","Catch"),$$$LocalizeText("EnsBPL","AddCatch","Add a catch action"))
	Set tShape($I(n)) = $LB("catchall",$$$LocalizeText("EnsBPL","CatchAll","Catch All"),$$$LocalizeText("EnsBPL","AddCatchAll","Add a catchAll action"))
	Set tShape($I(n)) = $LB("compensate",$$$LocalizeText("EnsBPL","Compensate","Compensate"),$$$LocalizeText("EnsBPL","AddCompensate","Add a compensate action"))
	Set tShape($I(n)) = $LB("compensationhandler",$$$LocalizeText("EnsBPL","CompensationHandler","Compensation Handler"),$$$LocalizeText("EnsBPL","AddCompensationHandler","Add a compensation handler"))

	&html<<td>>
	&html<<select id="selectNewShape" style="color: #404080; width:125px;" title="#(hlpAdd)#" onchange="zenPage.addNewShape();">>
	&html<<option value="" style="display:none;">&nbsp;-#(msgAdd)#-&nbsp;</option>>
	Set k = $O(tShape(""))
	While (k'="") {
		If (tShape(k)="") {
			// divider
			&html<<option value="-1" disabled="1" style="font-size:1px; border-bottom:1px solid #808080;"></option>>
		}
		Else {
			Set tName = $LG(tShape(k),1)
			Set tCaption = $LG(tShape(k),2)
			Set tTitle = $LG(tShape(k),3)
			&html<<option value="#(tName)#" title="#($ZCVT(tTitle,"O","HTML"))#">&nbsp;#($ZCVT(tCaption,"O","HTML"))#&nbsp;</option>>
		}
		Set k = $O(tShape(k))
	}
	&html<</select>>
	&html<</td>>


	&html<<td width="24">&nbsp;</td>>

	// list of grouping options
	// tGrouping(n) = $LB(name,caption,title) || ""

	Set tGrouping($I(n)) = $LB("sequence",$$$LocalizeText("EnsBPL","GroupAsSequence","As Sequence"),$$$LocalizeText("EnsBPL","GroupTipSequence","Place selected items within a sequence"))
	Set tGrouping($I(n)) = $LB("foreach",$$$LocalizeText("EnsBPL","GroupAsForEach","As a ForEach loop"),$$$LocalizeText("EnsBPL","GroupTipForEach","Place selected items within a ForEach loop"))
	Set tGrouping($I(n)) = $LB("until",$$$LocalizeText("EnsBPL","GroupAsUntil","As an Until loop"),$$$LocalizeText("EnsBPL","GroupTipUntil","Place selected items within an Until loop"))
	Set tGrouping($I(n)) = $LB("while",$$$LocalizeText("EnsBPL","GroupAsWhile","As a While loop"),$$$LocalizeText("EnsBPL","GroupTipWhile","Place selected items within a While loop"))
	Set tGrouping($I(n)) = ""
	Set tGrouping($I(n)) = $LB("scope",$$$LocalizeText("EnsBPL","GroupAsScope","As a Scope"),$$$LocalizeText("EnsBPL","GroupTipScope","Place selected items within a scope block"))
	Set tGrouping($I(n)) = $LB("flow",$$$LocalizeText("EnsBPL","GroupAsFlow","As a Flow"),$$$LocalizeText("EnsBPL","GroupTipFlow","Place selected items within a flow block"))

	&html<<td>>
	&html<<select id="selectNewGroup" style="color: #404080; width:125px;" title="#(hlpGroup)#" onchange="zenPage.addNewGroup();">>
	&html<<option value="" style="display:none;">&nbsp;-#(msgGroup)#-&nbsp;</option>>
	Set k = $O(tGrouping(""))
	While (k'="") {
		If (tGrouping(k)="") {
			// divider
			&html<<option value="-1" disabled="1" style="font-size:1px; border-bottom:1px solid #808080;"></option>>
		}
		Else {
			Set tName = $LG(tGrouping(k),1)
			Set tCaption = $LG(tGrouping(k),2)
			Set tTitle = $LG(tGrouping(k),3)
			&html<<option value="#(tName)#" title="#($ZCVT(tTitle,"O","HTML"))#">&nbsp;#($ZCVT(tCaption,"O","HTML"))#&nbsp;</option>>
		}
		Set k = $O(tGrouping(k))
	}
	&html<</select>>
	&html<</td>>

	// icons
	Set hlpUndo = $$$Text("Undo last action")
	Set hlpCut = $$$Text("Cut the selected items")
	Set hlpCopy = $$$Text("Copy the selected items")
	Set hlpPaste = $$$Text("Paste items from the BPL clipboard")
	Set hlpDelete = $$$Text("Delete the selected items")

	Set hlpDrillUp = $$$Text("Drill out of the current group activity")
	Set hlpDrillDown = $$$Text("Drill into the current group activity")

	Set hlpArrange = $$$Text("Arrange the layout of items in the diagram")
	Set hlpPrint = $$$Text("Show print friendly version of diagram")

	&html<<td nowrap="1">>
	&html<<image width="24" src="images/spacer.gif"/>>
	&html<<image id="iconUndo" class="reIconDisabled" title="#(hlpUndo)#" src="portal/loop_24.gif" onclick="zenPage.undo();"/>>
	&html<<image id="iconDelete" class="reIconDisabled" title="#(hlpDelete)#" src="deepsee/close_a_24.png"  onclick="zenPage.deleteShape();"/>>
	&html<<image id="iconCut" class="reIconDisabled" title="#(hlpCut)#" src="portal/scissors_24.gif"  onclick="zenPage.cutShape();"/>>
	&html<<image id="iconCopy" class="reIconDisabled" title="#(hlpCopy)#" src="portal/copy_24.gif"  onclick="zenPage.copyShape();"/>>
	&html<<image id="iconPaste" class="reIconDisabled" title="#(hlpPaste)#" src="portal/paste_24.gif"  onclick="zenPage.paste();"/>>
	&html<&nbsp;>
	&html<<image id="iconDrillDown" class="reIconDisabled" title="#(hlpDrillDown)#" src="portal/renderer_down_24.gif"  onclick="zenPage.drillDown();"/>>
	&html<<image id="iconDrillUp" class="reIconDisabled" title="#(hlpDrillUp)#" src="portal/renderer_up_24.gif"  onclick="zenPage.drillUp();"/>>
	&html<&nbsp;>
	&html<<image id="iconArrange" class="reIcon" title="#(hlpArrange)#" src="portal/shuffle_24.gif" onclick="zenPage.arrange();"/>>
	&html<&nbsp;>
	If ('..studioMode)&&((..cssLevel > 2) || '$$$ZENISIE) {
		&html<<image id="iconPrint" class="reIcon" title="#(hlpPrint)#" src="deepsee/printer_24.png" onclick="zenPage.print();"/>>
		&html<&nbsp;>
	}
	&html<</td>>

	&html<</tr>>
	&html<</table>>
	&html<</td>>
	Quit ##super()
}

/// This class method callback is called just before the server-side page 
/// object is created.
Method %OnAfterCreatePage() As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ##super()
		If $$$ISERR(tSC) Quit
		
		// build list of activity descriptions
		Do ..activityDesc.SetAt($$$Text("Assigns a value to a property."),"assign")
		Do ..activityDesc.SetAt($$$Text("Calls an operation or another business process."),"call")
		Do ..activityDesc.SetAt($$$Text("Delays the process for the specified time duration."),"delay")
		Do ..activityDesc.SetAt($$$Text("Ends a process or sequence."),"end")
		Do ..activityDesc.SetAt($$$Text("Starts a process or sequence."),"start")
		Do ..activityDesc.SetAt($$$Text("Wait for completion of one or more call activities."),"sync")
		Do ..activityDesc.SetAt($$$Text("Writes a trace message to the log."),"trace")

		Do ..activityDesc.SetAt($$$Text("Raises an alert."),"alert")
		Do ..activityDesc.SetAt($$$Text("Breaks out of a loop."),"break")
		Do ..activityDesc.SetAt($$$Text("Executes one or more lines of code."),"code")
		Do ..activityDesc.SetAt($$$Text("Does nothing."),"empty")
		Do ..activityDesc.SetAt($$$Text("Forces a reply to the original request."),"reply")
		Do ..activityDesc.SetAt($$$Text("Invokes a Business Rule."),"rule")
		Do ..activityDesc.SetAt($$$Text("Executes an SQL statement."),"sql")
		Do ..activityDesc.SetAt($$$Text("Evaluates an XPATH expression."),"xpath")
		Do ..activityDesc.SetAt($$$Text("Performs an XSLT transformation."),"xslt")

		Do ..activityDesc.SetAt($$$Text("Evaluate a condition and branch based on the result."),"if")
		Do ..activityDesc.SetAt($$$Text("Evaluate multiple conditions and branch based on the result."),"switch")
		Do ..activityDesc.SetAt($$$Text("Joins multiple branches together."),"join")
		Do ..activityDesc.SetAt($$$Text("Execute a sequence of activities for each item in a collection."),"foreach")
		Do ..activityDesc.SetAt($$$Text("Execute a sequence of activities while a condition is true."),"while")
		Do ..activityDesc.SetAt($$$Text("Execute a sequence of activities until a condition is true."),"until")

		Do ..activityDesc.SetAt($$$Text("Define a new scope within the Business Process."),"scope")
		Do ..activityDesc.SetAt($$$Text("Split the flow of execution into multiple branches."),"flow")
		Do ..activityDesc.SetAt($$$Text("Join multiple branches of execution back together."),"join")
		Do ..activityDesc.SetAt($$$Text("Execute a number of activities in sequential order."),"sequence")

		Do ..activityDesc.SetAt($$$Text("Catch a fault within the current execution scope."),"catch")
		Do ..activityDesc.SetAt($$$Text("Catch all unhandled faults within the current execution scope."),"catchall")
		Do ..activityDesc.SetAt($$$Text("Throw a fault."),"throw")
		Do ..activityDesc.SetAt($$$Text("Invoke a named compensation handler within a catch block. Following invocation of the handler, control returns to the next activity following the Compensate activity."),"compensate")
		Do ..activityDesc.SetAt($$$Text("Define a set of activities that compensate for a failed action."),"compensationhandler")

		Do ..activityDesc.SetAt($$$Text("Links one activity with another."),"connector")

		// Disable editor links in Studio
		If ..studioMode {
			Set tRuleEditorLink = ..%GetComponentById("ruleEditorLink")
			Set tRuleEditorLink.disabled = 1
			Set tRuleEditorLink.title = $$$Text("Not available in Studio")
			
			Set tDTLEditorLink = ..%GetComponentById("dtlEditorLink")
			Set tDTLEditorLink.disabled = 1
			Set tDTLEditorLink.title = $$$Text("Not available in Studio")
		}
		// remember the last BPL viewed
		Set tBPIn=..bpId, ..bpId=$E(..bpId,1,*-4)
		If (..bpId="") {
			If ""'=tBPIn Set tSC=$$$ERROR($$$EnsErrGeneral,"Got invalid BPL name '"_tBPIn_"'")  Quit
			If ('..isNew) {
				Set ..bpId = $G(^EnsPortal.Settings($UserName,"LastBP"))
				If ..bpId '= "" {
					If '##class(%Dictionary.ClassDefinition).%ExistsId(..bpId) {
						Kill ^EnsPortal.Settings($Username,"LastBP")
						Set ..bpId=""
					}
				}
			}
		} Else {
			If $Case($ZCVT($E(tBPIn,$L(tBPIn)-3,*),"L"),".bpl":0,".cls":0,:1) Set tSC=$$$ERROR($$$EnsErrGeneral,"Got BPL name '"_tBPIn_"' that does not end with '.bpl' or '.cls'")  Quit
		}
		// remember original name
		Set ..originalId = ..bpId

		Set:""=..bpId ..isNew = 1
		Set ..readOnly = '..canEdit

		Set ..bpMissing = 0
		If (..bpId'="") {
			// test if BP exists
			If '##class(EnsPortal.Utils).IsSubclass(..bpId, "Ens.BusinessProcessBPL")&&'..isNew {
				Set ..bpMissing = 1
			} Else {
				Set tSC = ..LoadBPLDiagram()
				If ('$IsObject(..%bpl))||$$$ISERR(tSC) {
					Set ..bpMissing = 1
				}
				ElseIf $IsObject(..%bpl) && ..isNew {
					Set ..isNew = 0
				}
				If ..isNew && $system.Status.Equals(tSC,$$$NotAnInstanceError) {
					Set tSC = $$$OK
				}
				Set:$$$ISOK(tSC) ^EnsPortal.Settings($UserName,"LastBP") = ..bpId
			}
		}

		If (..bpMissing) {
			// hide properties and arrow
			Set ..settingsExpanded = 0
			Set ..%GetComponentById("propertyTitle").content = ""
		}
		
		Set ..codeValidation = ..GetCodeValidation(..bpId)
		Set ..%GetComponentById("codeNoValidation").value = '..codeValidation

		// preferences
		Try {
			Set ..prefGridlines = $G(^EnsPortal.Settings($UserName,"BPL","gridlines"))
			Set ..prefAutoArrange = +$G(^EnsPortal.Settings($UserName,"BPL","autoArrange"))
			Set ..prefShowAnnotations = +$G(^EnsPortal.Settings($UserName,"BPL","showAnnotations"),1)
		}
		Catch {}
		Set:..prefGridlines="" ..prefGridlines = "light"
		Do ..%SetValueById("prefGridlines",..prefGridlines)
		Do ..%SetValueById("prefAutoArrange",..prefAutoArrange)
		Do ..%SetValueById("prefShowAnnotations",..prefShowAnnotations)
		
		If ..studioMode {
			Do ..%SetValueById("svgStudioMode",1)
			Set tShareParm = ##class(%ZEN.Auxiliary.parameter).%New()
			Set tShareParm.id = "svgCSPSHARE"
			Set tShareParm.value = "1"
			Set tSVG = ..%GetComponentById("svg")
			If $$$ISOK(..%AddComponent(tShareParm)) {
				Do tSVG.parameters.SetAt(tShareParm,"CSPSHARE")
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Adjust sizes of components on the page.
/// No HyperEvents should be executed before <method>initializeSVG</method>() is executed, as that method
/// calls <method>checkStudioHyperEvents</method>() to ensure that we maintain consistent session behaviour under Studio.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		if (load) {
			if (zenPage.bpMissing) {
				this.readOnly = true;
				this.grayOutOneButton('command_cmdSaveAs');
			}
			this.setReadOnly(this.readOnly || !this.canEdit);
		}
		if (!this.diagramLoaded) {
			var svgWin = this.getSVGWindow();
			
			if (load && !svgWin && !(!!document.createElementNS && !! document.createElementNS(SVGNS, "svg").createSVGRect)) {
				alert($$$Text('Unable to load SVG diagram. Please ensure your browser is supported for portal access.'));
			}
			else {
				this.initializeSVG();
			}
		}
		
		if (load) {
			if ((zenPage.bpId != '') && zenPage.bpMissing) {
				var msg = $$$FormatText($$$Text("There is no existing Business Process with name '%1'.  Use the buttons at the top to create a new Business Process, or to open an existing Business Process."),this.bpId);
				alert(msg);
				return;
			}

			this.updateSettings();
			this.updateIcons();
		}
		this.adjustSizes();
		if (load) {
			this.raiseEvent('LOADCOMPLETE',0);
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
		var svg = zen('svg');
		var propPane = zen('propertyPane');
		var propDiv = propPane.getEnclosingDiv();
		var proptitleDiv = zen('propertyTitle').getEnclosingDiv();

		if (!this.bpMissing) {
			zen('Loading').setHidden(true);

			// make property sheet visible
			propDiv.style.visibility = 'visible';
		}

		// find size of window
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();

		var scroll = ((zenBody.scrollWidth == zenBody.offsetWidth) && (zenBody.scrollLeft == 0 )) ? 0 :1;
		var th = this.getTitleAreaHeight();
		var hgt = winHeight - th - 5 - (15+1*zenIsIE)*scroll;

		var propWidth = 40;
		if (this.settingsExpanded) {
			propWidth = (winWidth<1100) ? 300 : 400;
		}
		propDiv.style.width = propWidth + 'px';

		var svgHgt = hgt - 1;
		if (this.settingsExpanded) {
			var svgWid = winWidth - propDiv.offsetWidth - 5;
		}
		else {
			var svgWid = winWidth - 50;
		}

		if (!this.bpMissing) {
			// svg element
			var svgDiv = svg.getEnclosingDiv();
			svgDiv.style.width = svgWid + 'px';
			svgDiv.style.height = svgHgt + 'px';

			// adjust size of svg frame
			svg.setProperty("width",svgWid+'px');
			svg.setProperty("height",svgHgt+'px');
		}

		var propTitleHeight = proptitleDiv.offsetHeight;
		var tabHeight = hgt - propTitleHeight - 35;
		// tabs etc.
		propDiv.style.height = hgt-1 + 'px';

		if (this.settingsExpanded) {
			var propertyTabs = zen('propertyTabs');
			if (propertyTabs) {
				propertyTabs.ieResizeBody = function() { return; };
				var tabDiv = propertyTabs.getEnclosingDiv();
				tabDiv.style.height = tabHeight + 'px';
				propertyTabs.setBodySize(tabHeight,propWidth - 1 - (zenIsChrome * 3));
				propertyTabs.setHidden(false);
			}
		}
		else {
			zen('propertyTabs').setHidden(true);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

/// Ensure tab content is correctly sized when the tab is shown.
ClientMethod onshowTab() [ Language = javascript ]
{
	var bodyHeight = zenGetWindowHeight() - this.getTitleAreaHeight() - 5;
	var propTitleDiv = zen('propertyTitle').getEnclosingDiv();
	var tabDiv = zen('propertyTabs').getEnclosingDiv();
	var tabHeight = bodyHeight - propTitleDiv.offsetHeight - 32;
	zen('propertyTabs').setBodySize(tabHeight);
}

/// Create a new Business Process.
ClientMethod newBP() [ Language = javascript ]
{
	if (this.studioMode || !zenPage.checkEdit()) { return false; }
	zenPage.checkTextControls();
	if (this.pageModified) {
		if (!confirm($$$Text('This Business Process has been modified. If you create a new Business Process now, without saving your changes to this Business Process, your changes will be lost. Do you wish to continue without saving?'))) {
			return;
		}
	}
	// show wizard dialog
	var parms = {};
	if (this.studioMode) parms.STUDIO = 1;
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.BusinessProcessWizard.zen',this.studioMode),this.addPopupSuffix('BPNew'),'status,scrollbars,resizable=yes,width=700,height=600',parms);
}

/// Launch the finder dialog.
ClientMethod loadBP() [ Language = javascript ]
{
	if (this.studioMode) { return false; }
	zenPage.checkTextControls();
	if (this.pageModified) {
		if (!confirm($$$Text('This Business Process has been modified. If you open another Business Process now, without saving your changes to this Business Process, your changes will be lost. Do you wish to continue without saving?'))) {
			return;
		}
	}
	var parms = {
		MODE:'bpl'
	};
	zenLaunchPopupWindow(zenLink('%ZEN.Dialog.finderDialog.zen',this.studioMode),this.addPopupSuffix('BPOpen'),'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// Launch the save dialog.
ClientMethod saveBP(showDialog, force) [ Language = javascript ]
{
	if (!this.canUserModify(showDialog)) return;
	this.checkTextControls();

	if (showDialog || this.bpId==='') {
		var desc = '';
		var model = this.getBPLObject();
		if (model && ('object' == typeof model)) desc = zenGet(model.Annotation);

		// show save dialog
		var parms = {
			BP:this.bpId+'.bpl',
			DESC:desc
				};
		if (this.studioMode) parms.STUDIO = 1;
		zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.BusinessProcessSave.zen',this.studioMode),this.addPopupSuffix('BPSave'),'status,scrollbars,resizable=yes,width=700,height=600',parms);
	}
	else {
		if (this.pageModified||force) {
			return this.bpSave();
		} else {
			alert($$$Text('No changes to save.'));
			return true;
		}
	}
}

/// Ensure we redraw the diagram if the model was updated.
ClientMethod onDocumentSaveComplete(contentUpdated) [ Language = javascript ]
{
	this.invokeSuper('onDocumentSaveComplete',arguments);
	if (contentUpdated) {
		var bpl = this.getBPLObject();
		if (bpl) this.replaceBPLObject(bpl);
	}
}

/// Ensure we redraw the diagram if a reload was requested
ClientMethod onDocumentReload(reason) [ Language = javascript ]
{
	if (this._inReload || this._inReplace) return;
	this._inReload = true;
	this.updateDocumentState(true);
	if (reason == "dataChange") {
		var bpl = this.getBPLObject();
		if (bpl) {
			this.replaceBPLObject(bpl);
			this.setModified(false);
		}
	}
	this._inReload = false;
}

/// Launch the compile dialog.
ClientMethod compile() [ Language = javascript ]
{
	if (!this.canUserModify()) return;
	zenPage.checkTextControls();
	if (zenPage.bpId=='') {
		alert($$$Text('Business Process must have a name.'));
		return;
	}
	
	var modified = zenPage.pageModified;

	var sync = zenPage.saveBP(false,true);
	if (!sync) return;

	var bpl = this.getBPLObject();
	bpl.HasErrors = this._bplAPI.currentDiagram.hasErrors();

	if (bpl.HasErrors) {
		if (!modified) alert($$$Text('The BPL Diagram contains errors. Correct the errors before compiling.'));
		return;
	}

	// launch compile window
	var parms = {
		CLASSNAME: zenPage.bpId,
		TYPE:'BPL'
	};
	if (this.studioMode) parms.STUDIO = 1;
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.ClassCompile.zen',this.studioMode),this.addPopupSuffix('BPCompile'),'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
	case 'BPOpen':
		// Mark the diagram as unmodified to avoid popups when trying to leave the page.
		this.setModified(false);
		self.document.location = zenLink(this.designerURL + '?BP=' + encodeURIComponent(value));
		break;

	case 'BPSave':
		this.bpSave();
		break;

	case 'BPNew':
		if (value!='') {
			// Mark the diagram as unmodified to avoid popups when trying to leave the page.
			this.setModified(false);
			self.document.location = zenLink(this.designerURL + '?BP=' + encodeURIComponent(value) + '&NEW=1');
		}
		break;

	case 'BPCompile':
		self.document.location.reload();
		break;

	case 'BPFindRule':
	case 'BPFindTransform':
	case 'BPResponseClass':
	case 'BPRequestClass':
		if (this._currProperty) {
			var ctrl = zen(this._currProperty.zenId);
			if (ctrl) {
				var t = value.toString().split('.');
				t.length--;
				var newValue = t.join('.');
				var oldValue = ctrl.getValue();
				if (newValue != oldValue) {
					var tabNum = zen('propertyTabs').currTab;
					this.startUndoAction(tabNum);
					ctrl.setValue(newValue);
					var target = this._currProperty.model;
					var path = this._currProperty.propPath.splice(0,1)[0];
					while (this._currProperty.propPath.length > 0) {
						target = target[path];
						path = this._currProperty.propPath.splice(0,1)[0];
					}
					target[path] = newValue;
					this.endUndoAction();
					if (this._currShape) this._currShape.updateStyle();
				}
			}
		}
		break;

	case 'BPContextSuperClass':
		var t = value.toString().split('.');
		t.length--;
		var newValue = t.join('.');
		var ctrl = zen('cContextSuper');
		var oldValue = ctrl.getValue();
		if (oldValue != newValue) {
			var tabNum = 2;
			this.startUndoAction(2);
			ctrl.setValue(t.join('.'));
			var bpl = this.getBPLObject();
			bpl.ContextSuperClass = newValue;
			this.endUndoAction();
		}
		break;

	case 'BPValue':
		if (this._currProperty) {
			var ctrl = zen(this._currProperty);
			if (ctrl) {
				var oldValue = ctrl.getValue();
				if (oldValue != value) {
					this.startUndoAction();
					ctrl.setValue(value);
					if (this._currProperty == 'cCondition') {
						this._textMonitor.textChanged = true;
						this.connectorChange();
					} else {
						this.activityChange();
					}
					this.endUndoAction();
				}
			}
		}		
		break;
	case 'switchNamespace':
		zenPage.changeURLNamespace(value);
		break;
	case 'newRule':
		if (value!='') {
			var url = zenLink(zenPage.ruleEditorBaseURL);
			url += ((url.indexOf('?') < 0) ? '?' : '&');
			url += 'rule=' + encodeURIComponent(value);
			var win = window.open(url);
			try {
				win.focus();
			}
			catch(ex) {}
		}
		break;
	}
}

ClientMethod bpSave() [ Language = javascript ]
{
	// reset errors before save
	var rename = false;
	var model = this.getBPLObject();
	model.HasErrors = this._bplAPI.currentDiagram.hasErrors();
	if (zenPage.bpAsName != '' && zenPage.bpAsName != zenPage.bpId) {
		rename = true;
		bpOldId=zenPage.bpId;
		zenPage.bpId = zenPage.bpAsName;
		model.Name = zenPage.bpId;
	} else if (zenPage.bpId == '') { // should not happen
		alert($$$Text('Business Process must have a name.'));
		return false;
	}

	if (model.HasErrors) {
		if ((!this.studioMode) && (!confirm($$$Text('Diagram has errors, no code will be generated. Ok to save?')))) {
			if (rename) zenPage.bpId=bpOldId, model.Name=bpOldId; // restore to empty
			return false;
		} else if (this.studioMode) {
			alert($$$Text('Diagram has errors, no code will be generated.'));
		}
	}
	if (this.studioMode) {
		this.studioSave();
		return true;
	}

	model = null;
	if (rename && this.readOnly) {
		try {
			this.readOnly = false;
			var ok = this.saveDocument();
			this.readOnly = true;
		} catch (ex) {
			this.readOnly = true;
		}
	} else {
		var ok = this.saveDocument();
	}
	var model = this.getBPLObject();
	model.HasErrors = this._bplAPI.currentDiagram.hasErrors();

	if (ok && rename) { // reload page
		self.document.location = zenLink(this.designerURL + '?BP=' + encodeURIComponent(zenPage.bpId+'.bpl') + '&RENAMED=1');
		return ok;
	} else if (rename) {
		zenPage.bpId=bpOldId, model.Name=bpOldId, zenPage.bpAsName=''; // restore to empty
		// Enable correction of document after failed Save As while readonly, but only if failure is a validation error and not source control/timestamp
		if (this.readOnly && this.pageModified) {
			var json = this.getClientModel();
			if (json.error.substring(0,5)=="ERROR") {
				this.setReadOnly(false);
				zenPage.grayOutOneButton('command_cmdSave');
				zenPage.grayOutOneButton('command_cmdCompile');
				alert($$$Text('Please correct errors before saving.'));
			}
		}
	}
	if (ok) {
		this.clearUndoBuffer();
	} else {
		// reset description to old value; control still holds original value if save failed
		model.Annotation = zen('gAnnotation').getValue();
		
		if (!rename && zenPage.getIsReadOnly()) {
			// If this document was found to be readOnly, gray out buttons to indicate this
			zenPage.grayOutButtons();
		}			
	}

	if (ok && model.HasErrors) {
		alert($$$Text('Process saved with errors.'));
	}
	else if (ok) {
		alert($$$Text('Process Saved.'));
	}
	return ok;
}

/// Return the BPL definition object.
ClientMethod getBPLObject() [ Language = javascript ]
{
	var json = this.getComponentById('bpl');
	if (json) {
		var bp = json.getContentObject();
		this.updateJSONSCReadOnly(bp);
		return bp;
	} else {
		return null;
	}
}

/// Replace the current BPL object with the supplied BPL object.
/// This is used by the undo framework.
ClientMethod replaceBPLObject(bpl) [ Language = javascript ]
{
	this._inReplace = true;
	var json = this.getComponentById('bpl');
	var selectedTab = bpl._selectedTab;
	var selectedModels = bpl._selectedModels;
	var currentParent = (typeof bpl._currentParent == 'undefined' ? null : bpl._currentParent);
	delete bpl._selectedTab;
	delete bpl._selectedModels;
	delete bpl._currentParent;

	json.setContentObject(bpl);
	if (this._bplAPI) {
		this.setOption('gridlineStyle',this.prefGridlines);
		this.setOption('showAnnotations',this.prefShowAnnotations);
		this._BPLDiagram = this._bplAPI.Diagram.create(bpl);
		this._BPLDiagram.setCurrentParent(currentParent);
		this._BPLDiagram.render();
		this.setOption('autoArrange',this.prefAutoArrange ? true : false);
	}
	this.updateSettings(true);
	if (this._BPLDiagram && selectedModels) {
		for (var i = 0; i < selectedModels.length; i++) {
			var model = selectedModels[i];
			if (model.Type == 'connector') { // connector
				var toShape = this._BPLDiagram.shapeList[model.ToShape];
				if (toShape && (toShape.model === bpl.ShapeList[model.ToShape])) {
					for (var j = 0; j < toShape.inputList.length; j++) {
						var conn = toShape.inputList[j];
						if (conn && (conn.model === model)) {
							this._BPLDiagram.selectItem(conn,true);
							break;
						}
					}
				}
			}
			else { // shape
				var shape = this._BPLDiagram.shapeList[model.Index];
				if (shape && (shape.model === model)) this._BPLDiagram.selectItem(shape,true);
			}
		}
	}
	if (selectedTab) zen('propertyTabs').showTab(selectedTab);
	this.updateIcons();
	this._inReplace = false;
}

/// Remove a connector definition from the model.
ClientMethod removeConnectorFromModel(connectorModel) [ Language = javascript ]
{
	if (connectorModel) {
		var model = this.getBPLObject();
		// find and remove model
		var connPos = model.Connectors.indexOf(connectorModel);
		if (connPos != -1) model.Connectors.splice(connPos,1);
	}
}

/// Update the settings panel.
ClientMethod updateSettings(noTabSelect) [ Language = javascript ]
{
	// general
	var model = this.getBPLObject();
	var gform = zen('generalForm');

	if (null == model) {
		gform.setProperty('hidden',true);
	}
	else {
		gform.setProperty('hidden',false);
		zen('gLanguage').setValue(model.Language);
		zen('gAnnotation').setValue(model.Annotation);
		zen('gLayout').setValue(model.Layout);
		zen('gVersion').setValue(model.Version);
		zen('gWidth').setValue(model.Width);
		zen('gHeight').setValue(model.Height);
		zen('gIncludes').setValue(model.Includes);
		zen('gComponent').setValue(model.Component);
		zen('gPyFromImport').setValue(model.PyFromImport)
	}

	// context
	var cform = zen('contextForm');
	if (null == model) {
		cform.setProperty('hidden',true);
	}
	else {
		cform.setProperty('hidden',false);
		zen('cRequest').setValue(model.Request);
		zen('cResponse').setValue(model.Response);
		zen('cContextSuper').setValue(model.ContextSuperClass);
		this.renderContextTable();
	}

	this.updateActivitySettings(null,false,noTabSelect);
}

/// Update the Activities tab on the settings panel.
/// LanguageOverride appearing in PropertyBag
/// This code executes whenever an activity item or canvas background is clicked on
ClientMethod updateActivitySettings(shape, isUpdate, noTabSelect) [ Language = javascript ]
{
	try {
		// Need to model to access the main language (model.Language)
		var model = this.getBPLObject();
		var isBasic=false;
		if (model) {
			isBasic=('basic'==model.Language)
		}

		if (this.bpMissing) {
			return;
		}
		if (this._textMonitor) {
			this._textMonitor.reset();
		}
		
		var aform = zen('activityForm');
		var cform = zen('connectorForm');
		var ebox = zen('errorBox');

		// bring activity tab to front
		if (!noTabSelect && (null != shape)) {
			zen('propertyTabs').showTab(3);
		}
		if (isUpdate) this.startUndoAction();

		// hold onto current shape
		this._currShape = shape;

		if (null == shape) {
			var html = '<div class="noActivity">'+$$$Text('No activity selected')+'</div>';
			html += '<div class="noActivity2">'+$$$Text('Select an activity or connection within the diagram using the mouse.')+'</div>';
			html += '<div class="noActivity2">'+$$$Text('You can select multiple activities by holding down the control key while selecting.')+'</div>';

			if (this._BPLDiagram && this._BPLDiagram.canDrillUp()) {
				html += '<br/>';
				html += '<div class="noActivity2">'+$$$Text('The current view shows the contents of a containing group. Press the Drill Out icon to see the outer view.')+'</div>';
			}

			zen('aDesc').setContent(html);
			ebox.setContent('');

			aform.setProperty('hidden',true);
			cform.setProperty('hidden',true);
		}
		else if (shape.model.Type=='connector') {
			var shapeModel = shape.model;

			var html = '<div class="activityType">&lt;'+shapeModel.Type+'&gt;</div>';
			var desc = this.activityDesc[shapeModel.Type];
			if (desc) {
				html = html + '<div class="activityDesc">'+desc+'</div>'
			}
			zen('aDesc').setContent(html);
			ebox.setContent('');

			zen('cName').setValue(shapeModel.Name);
			zen('cCondition').setValue(shapeModel.Condition);

			switch (shapeModel.ConnectType) {
			case 'case':
				zen('cConditionGroup').setProperty('hidden',false);

				zen('cLanguageOverride').setProperty('hidden',false);
				this.updateLanguageOverride('c', isBasic, shapeModel,shapeModel.LanguageOverride);
				break;
			case 'goto':
			case 'thread':
			default:
				zen('cConditionGroup').setProperty('hidden',true);
				zen('cLanguageOverride').setProperty('hidden',true);
				break;
			}
			// Ensure true/false branches can't be renamed
			zen('cName').setProperty('readOnly',this.readOnly || (shapeModel.ConnectType=='goto'));
			
			aform.setProperty('hidden',true);
			cform.setProperty('hidden',false);
		}
		else {
			// get corresponding item in model
			var shapeModel = shape.model;

			aform.setProperty('hidden',false);
			cform.setProperty('hidden',true);

			var html = '<div class="activityType">&lt;'+shapeModel.Type+'&gt;</div>';
			var desc = this.activityDesc[shapeModel.Type];
			if (desc) {
				html = html + '<div class="activityDesc">'+desc;+'</div>';
			}
			if (shape.children.length > 0) {
				html += '<br/>';
				html += '<div class="noActivity2">'+$$$Text('Press the Drill Down icon to see the contents of this item.')+'</div>';
			}
			if ((shapeModel.Type!='start')&&(shapeModel.Type!='end')&&(shapeModel.Type!='join')) {
				html = html + '<div class="activityDesc"/><a class="portalTitleLink" onclick="zenPage.showActivityDoc(\''+shapeModel.Type+'\');return false;" href="#">'+$$$Text('View documentation')+'</a></div>';
			}

			zen('aDesc').setContent(html);
			zen('aName').setValue(shapeModel.Name);
			zen('axPos').setValue(shapeModel.xPos);
			zen('ayPos').setValue(shapeModel.yPos);
			zen('aAnnotation').setValue(shapeModel.Annotation);
			zen('aDisabled').setValue(shapeModel.Disabled);

			// show details based on type

			// list of all groups
			var groups = {
				vgAssign:false,
				vgBranch:false,
				vgCall:false,
				vgDelay:false,
				vgIf:false,
				vgFlow:false,
				vgJoin:false,
				vgLabel:false,
				vgSequence:false,
				vgScope:false,
				vgSwitch:false,
				vgSync:false,
				vgTrace:false,
				vgTransform:false,

				vgWhile:false,
				vgUntil:false,
				vgForEach:false,
				vgMilestone:false,

				vgCatch:false,
				vgCatchAll:false,
				vgThrow:false,
				vgCompensate:false,
				vgCompensationHandler:false,

				vgAlert:false,
				vgBreak:false,
				vgCode:false,
				vgContinue:false,
				vgEmpty:false,
				vgReply:false,
				vgRule:false,
				vgSQL:false,
				vgXPATH:false,
				vgXSLT:false
			};

			zen('aNameGroup').setHidden(false);
			zen('aDisabled').setHidden(false);
			zen('aAnnotation').setHidden(false);

			// Language overide appearing in Property Bag when BPL opened in Editor
			if ((shapeModel) && (shapeModel.PropertyBag) && ((shapeModel.PropertyBag.LanguageOverride)&&(shapeModel.PropertyBag.LanguageOverride!==undefined))) {
				tmpCtl=zen((shapeModel.Type)+'LanguageOverride')
				if (tmpCtl!==null && tmpCtl!==undefined) {
					tmpCtl.setValue(zenGet(shapeModel.PropertyBag.LanguageOverride));
				}
			}
			switch(shapeModel.Type) {
			case 'start':
			case 'end':
				zen('aNameGroup').setHidden(true);
				zen('aDisabled').setHidden(true);
				zen('aAnnotation').setHidden(true);
				break;

			case 'assign':
				zen('assignAction').setValue(zenGet(shapeModel.PropertyBag.Action));
				zen('assignProperty').setValue(zenGet(shapeModel.PropertyBag.Property));
				zen('assignValue').setValue(zenGet(shapeModel.PropertyBag.Value));
				zen('assignKey').setValue(zenGet(shapeModel.PropertyBag.Key));
				this.updateLanguageOverride('assign',isBasic,shapeModel);
				groups.vgAssign = true;
				break;

			case 'branch':
				zen('branchCondition').setValue(zenGet(shapeModel.PropertyBag.Condition));
				zen('branchLabel').setValue(zenGet(shapeModel.PropertyBag.Label));
				this.updateLanguageOverride('branch',isBasic,shapeModel);
				groups.vgBranch = true;
				break;

			case 'call':
				var reqType = '';
				var respType = '';
				if (shapeModel.Request && shapeModel.Request.Type) {
					reqType = shapeModel.Request.Type;
				}
				if (shapeModel.Response && shapeModel.Response.Type) {
					respType = shapeModel.Response.Type;
				}
			
				zen('callRequestType').setValue(reqType);
				zen('callResponseType').setValue(respType);

				zen('callTarget').setValue(zenGet(shapeModel.PropertyBag.Target));
				zen('callAsync').setValue(zenGet(shapeModel.PropertyBag.Async)==1?true:false);
				zen('callTimeout').setValue(zenGet(shapeModel.PropertyBag.Timeout));
				groups.vgCall = true;

				zenPage.renderActionList('Request',shapeModel);
				zenPage.renderActionList('Response',shapeModel);
				this.updateLanguageOverride('call',isBasic,shapeModel);
				break;

			case 'catch':
				zen('catchFault').setValue(zenGet(shapeModel.PropertyBag.Fault));
				groups.vgCatch = true;
				break;

			case 'delay':
				zen('delayDuration').setValue(zenGet(shapeModel.PropertyBag.Duration));
				zen('delayUntil').setValue(zenGet(shapeModel.PropertyBag.Until));
				groups.vgDelay = true;
				break;
			case 'if':
				zen('ifCondition').setValue(zenGet(shapeModel.PropertyBag.Condition));
				this.updateLanguageOverride('if',isBasic,shapeModel);
				groups.vgIf = true;
				break;
			case 'while':
				zen('whileCondition').setValue(zenGet(shapeModel.PropertyBag.Condition));
				this.updateLanguageOverride('while',isBasic,shapeModel);
				groups.vgWhile = true;
				break;
			case 'until':
				zen('untilCondition').setValue(zenGet(shapeModel.PropertyBag.Condition));
				this.updateLanguageOverride('until',isBasic,shapeModel);
				groups.vgUntil = true;
				break;
			case 'foreach':
				zen('foreachKey').setValue(zenGet(shapeModel.PropertyBag.Key));
				zen('foreachProperty').setValue(zenGet(shapeModel.PropertyBag.Property));
				groups.vgForEach = true;
				break;

			case 'label':
				groups.vgLabel = true;
				break;

			case 'switch':
				groups.vgSwitch = true;
				break;

			case 'sync':
				zen('syncCalls').setValue(zenGet(shapeModel.PropertyBag.Calls));
				zen('syncType').setValue(zenGet(shapeModel.PropertyBag.Type));
				zen('syncTimeout').setValue(zenGet(shapeModel.PropertyBag.Timeout));
				zen('syncAllowResync').setValue(zenGet(shapeModel.PropertyBag.AllowResync));
				groups.vgSync = true;
				break;

			case 'milestone':
				zen('milestoneValue').setValue(zenGet(shapeModel.PropertyBag.Value));
				this.updateLanguageOverride('milestone',isBasic,shapeModel);
				groups.vgMilestone = true;
				break;

			case 'trace':
				zen('traceValue').setValue(zenGet(shapeModel.PropertyBag.Value));
				this.updateLanguageOverride('trace',isBasic,shapeModel);
				groups.vgTrace = true;
				break;

			case 'transform':
				zen('transformClass').setValue(zenGet(shapeModel.PropertyBag.Class));
				zen('transformSource').setValue(zenGet(shapeModel.PropertyBag.Source));
				zen('transformTarget').setValue(zenGet(shapeModel.PropertyBag.Target));
				groups.vgTransform = true;
				break;

			case 'scope':
				groups.vgScope = true;
				break;
			case 'flow':
				groups.vgFlow = true;
				break;
			case 'join':
				groups.vgJoin = true;
				break;
			case 'sequence':
				groups.vgSequence = true;
				break;

			case 'alert':
				zen('alertValue').setValue(zenGet(shapeModel.PropertyBag.Value))
				this.updateLanguageOverride('alert',isBasic,shapeModel)
				groups.vgAlert = true;
				break;
			case 'break':
				groups.vgBreak = true;
				break;
			case 'code':
				zen('codeCode').setValue(zenGet(shapeModel.Code));
				this.updateLanguageOverride('code',isBasic,shapeModel);
				groups.vgCode = true;
				break;
			case 'continue':
				groups.vgContinue = true;
				break;
			case 'empty':
				groups.vgEmpty = true;
				break;
			case 'reply':
				groups.vgReply = true;
				break;
			case 'rule':
				groups.vgRule = true;
				zen('ruleRule').setValue(zenGet(shapeModel.PropertyBag.Rule));
				zen('ruleRuleContext').setValue(zenGet(shapeModel.PropertyBag.RuleContext));
				zen('ruleResultLocation').setValue(zenGet(shapeModel.PropertyBag.ResultLocation));
				zen('ruleReasonLocation').setValue(zenGet(shapeModel.PropertyBag.ReasonLocation));
				break;
			case 'sql':
				zen('sqlCode').setValue(zenGet(shapeModel.Code));
				groups.vgSQL = true;
				break;
			case 'xpath':
				zen('xpathSource').setValue(zenGet(shapeModel.PropertyBag.Source));
				zen('xpathProperty').setValue(zenGet(shapeModel.PropertyBag.Property));
				zen('xpathContext').setValue(zenGet(shapeModel.PropertyBag.Context));
				zen('xpathExpression').setValue(zenGet(shapeModel.PropertyBag.Expression));
				zen('xpathPrefixMappings').setValue(zenGet(shapeModel.PropertyBag.PrefixMappings));
				zen('xpathSchemaSpec').setValue(zenGet(shapeModel.PropertyBag.SchemaSpec));
				groups.vgXPATH = true;
				break;
			case 'xslt':
				zen('xsltXSLURL').setValue(zenGet(shapeModel.PropertyBag.XSLURL));
				zen('xsltSource').setValue(zenGet(shapeModel.PropertyBag.Source));
				zen('xsltTarget').setValue(zenGet(shapeModel.PropertyBag.Target));
				zen('xsltVersion').setValue(zenGet(shapeModel.PropertyBag.XSLTVersion));
				zenPage.renderXSLTList(shapeModel);
				groups.vgXSLT = true;
				break;

			case 'compensate':
				zen('compensateTarget').setValue(zenGet(shapeModel.PropertyBag.Target));
				groups.vgCompensate = true;
				break;
			case 'throw':
				zen('throwFault').setValue(zenGet(shapeModel.PropertyBag.Fault));
				groups.vgThrow = true;
				break;

			default:
				break;
			}

			// show current group / hide others
			for (var g in groups) {
				var ctrl = zen(g);
				if (ctrl) {
					zen(g).setHidden(!groups[g]);
				}
			}

			this.validateShape(shape);

			// make sure old form errors are removed
			aform.validate();
		}
		if (isUpdate) this.endUndoAction();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in updateActivitySettings');
	}
}

ClientMethod updateLanguageOverride(controlprefix, isBasic, shapeModel) [ Language = javascript ]
{
	var zencontrol=zen(controlprefix+'LanguageOverride');
	if (zencontrol) {
		if (isBasic) {
			zencontrol.setHidden(1);
			zencontrol.setValue('');
			if (shapeModel) {
				zencontrol.setProperty('hidden',true);
				zencontrol.setValue('');
				if ((shapeModel.Type=='connector') && (shapeModel.ConnectType='case')) {
					shapeModel.LanguageOverride='';  // reset will remove Python logo if needed
				} else {
					if (shapeModel.PropertyBag) {
						shapeModel.PropertyBag.LanguageOverride='';  // reset will remove Python logo if needed
					}
				}
			} 
		} else {
			zencontrol.setProperty('hidden',false);
			if (shapeModel) {
				if ((shapeModel.Type=='connector') && (shapeModel.ConnectType='case')) {
					zencontrol.setValue(shapeModel.LanguageOverride);
				} else {
					if (shapeModel.PropertyBag) {
						zencontrol.setValue(shapeModel.PropertyBag.LanguageOverride);
					}
				}
			}
		}
	}
}

/// Test if current shape is valid. Show error message if not.
ClientMethod validateShape(shape) [ Language = javascript ]
{
	var ebox = zen('errorBox');
	// errors come from shape
	if (!shape || shape.isValid()) {
		ebox.setContent('');
	}
	else {
		html = [];
		html.push('<hr/>');
		html.push('<div class="errorTitle">'+$$$Text('This item is not valid')+'</div>');
		html.push('<ol class="errorList">');
		for (var n = 0; n < shape.errors.length; n++) {
			if (shape.errors[n] && (shape.errors[n].length > 0)) html.push('<li>' + zenEscapeHTML(shape.errors[n]) + '</li>');
		}
		html.push('</ol>');
		html.push('<hr/>');
		ebox.setContent(html.join(''));
	}
}

/// Update the contents of the Context Properties table.
ClientMethod renderContextTable() [ Language = javascript ]
{
	var table = zen('gContextList');
	var html = [];
	var model = this.getBPLObject();

	if (model) {
		html.push('<table class="propListTable" border="0" cellspacing="0">');
		html.push('<tr>');
		html.push('<th>' + '&nbsp;' + '</th>');
		html.push('<th>' + $$$Text('Name') + '</th>');
		html.push('<th>' + $$$Text('Type') + '</th>');
		html.push('<th>' + $$$Text('Default') + '</th>');
		html.push('</tr>');

		if (model.Context && model.Context.Properties && model.Context.Properties.length > 0) {
			for (var n = 0; n < model.Context.Properties.length; n++) {
				var prop = model.Context.Properties[n];

				// indicate collections
				var name = prop.Name;
				if (prop.Collection!='') name += '('+prop.Collection+')';

				// glue data type parameters together
				var type = prop ? prop.Type : '';
				if (prop && prop.Parameters) {
					var list = [];
					for (var p = 0; p < prop.Parameters.length; p++) {
						var parm = prop.Parameters[p];
						list.push(parm.Name + '=' + (!isNaN(parseFloat(parm.Value))?parm.Value:'"'+parm.Value+'"')); 
					}
					if (list.length > 0) type += '(' + list.join(',') + ')';
				}

				html.push('<tr class="'+((n%2)?'rowOdd':'rowEven')+'" title="'+zenEscapeHTML(zenGet(prop.Annotation))+'">');
				html.push('<td>');
				html.push('<image title="'+$$$Text('Edit this property')+'" src="deepsee/notepad_16.png"  onclick="zenPage.editContextProperty('+n+');"/>');
				html.push('<image title="'+$$$Text('Delete this property')+'" src="deepsee/close_a_16.gif" onclick="' + ((this.canEdit && !this.readOnly) ? 'zenPage.deleteContextProperty('+n+');' : 'alert(zenPage.msgNotPermitted);') + '"/>');
				html.push('</td>');
				html.push('<td>' + zenEscapeHTML(name) + '&nbsp;</td>');
				html.push('<td>' + zenEscapeHTML(type) + '&nbsp;</td>');
				html.push('<td>' + zenEscapeHTML(prop.InitialExpression) + '&nbsp;</td>');
				html.push('</tr>');
			}
		}
		else {
			html.push('<tr class="rowEven">');
			html.push('<td colspan="4"><i>' + $$$Text('No properties defined') + '</i></td>');
			html.push('</tr>');
		}
		html.push('</table>');
	}
	table.setContent(html.join(''));
}

/// Update the contents of the XSLT parameters table.
ClientMethod renderXSLTList(shapeModel) [ Language = javascript ]
{
	var table = zen('xsltParameterList');
	var html = [];

	if (shapeModel) {
		html.push('<table class="propListTable" border="0" cellspacing="0">');
		html.push('<tr>');
		html.push('<th>' + '&nbsp;' + '</th>');
		html.push('<th>' + $$$Text('Name') + '</th>');
		html.push('<th>' + $$$Text('Value') + '</th>');
		html.push('</tr>');

		var count = 0;
		if (shapeModel.Parameters) {
			for (var parm in shapeModel.Parameters) {
				if (parm.indexOf('_')==-1) {
					var value = shapeModel.Parameters[parm];

					html.push('<tr class="'+((count%2)?'rowOdd':'rowEven')+'">');
					html.push('<td>');
					html.push('<image title="'+$$$Text('Edit this parameter')+'" src="deepsee/notepad_16.png"  onclick="zenPage.editXSLTParm(\''+parm+'\');"/>');
					html.push('<image title="'+$$$Text('Delete this parameter')+'" src="deepsee/close_a_16.gif" onclick="'+ ((this.canEdit && !this.readOnly) ? 'zenPage.deleteXSLTParm(\''+parm+'\');' : 'alert(zenPage.msgNotPermitted);') +'"/>');
					html.push('</td>');
					html.push('<td>' + zenEscapeHTML(parm) + '&nbsp;</td>');
					html.push('<td>' + zenEscapeHTML(value) + '&nbsp;</td>');
					html.push('</tr>');
					count++;
				}
			}
		}

		if (count==0) {
			html.push('<tr class="rowEven">');
			html.push('<td colspan="4"><i>' + $$$Text('No parameters defined') + '</i></td>');
			html.push('</tr>');
		}
		html.push('</table>');
	}
	table.setContent(html.join(''));
}

/// Update the contents of the Call Request or Response Action table.
ClientMethod renderActionList(which, shapeModel) [ Language = javascript ]
{
	var array = null;
	if (shapeModel && shapeModel[which]) {
		array = shapeModel[which].Activities;
	}
	var html = this.getActionListHTML(which,array);

	var table = zen('call'+which+'List');
	table.setContent(html);
}

/// Return HTML for an action table.
ClientMethod getActionListHTML(which, array) [ Language = javascript ]
{
	var html = [];

	html.push('<table class="actionListTable" border="0" cellspacing="0">');
	html.push('<tr>');
	html.push('<th>' + '&nbsp;' + '</th>');
	html.push('<th>' + $$$Text('Action') + '</th>');
	html.push('<th>' + $$$Text('Property') + '</th>');
	html.push('<th>' + $$$Text('Value') + '</th>');
	html.push('<th>' + $$$Text('Key') + '</th>');
	html.push('</tr>');

	if (array && array.length > 0) {
		for (var n = 0; n < array.length; n++) {
			var act = array[n];
			html.push('<tr class="'+((n%2)?'rowOdd':'rowEven')+'">');
			html.push('<td>');
			html.push('<image title="'+$$$Text('Edit this action')+'" src="deepsee/notepad_16.png"  onclick="zenPage.editAction(\''+which+'\','+n+');"/>');
			html.push('<image title="'+$$$Text('Delete this action')+'" src="deepsee/close_a_16.gif" onclick="'+ ((this.canEdit && !this.readOnly) ? 'zenPage.deleteAction(\''+which+'\','+n+');' : 'alert(zenPage.msgNotPermitted);') + '"/>');
			html.push('</td>');

			html.push('<td>' + zenEscapeHTML(zenGet(act.Action)) + '&nbsp;</td>');
			html.push('<td>' + zenEscapeHTML(zenGet(act.Property)) + '&nbsp;</td>');
			html.push('<td>' + zenEscapeHTML(zenGet(act.Value)) + '&nbsp;</td>');
			html.push('<td>' + zenEscapeHTML(zenGet(act.Key)) + '&nbsp;</td>');
			html.push('</tr>');
		} 
	}
	else {
		html.push('<tr class="rowEven">');
		html.push('<td colspan="5"><i>' + $$$Text('No actions defined') + '</i></td>');
		html.push('</tr>');
	}

	html.push('</table>');
	return html.join('');
}

/// Get BPL definition for JSON provider
/// and write out JSON version of it.
Method GetBPLDefinition(ByRef pParms) As %Status
{
	Set tSC = $$$OK
	Set tDiagram = ""

	Set json = ..%GetComponentById("bpl")
	Set json.targetClass = "%ZEN.proxyObject"

	If '$IsObject(..%bpl) {
		Set tSC = ..LoadBPLDiagram()
		If $$$ISERR(tSC) Quit tSC
	}
	Set tDiagram = ..%bpl
	
	If $IsObject(tDiagram) {
		Set tSC = ..%BPLtoJSON(..bpId,tDiagram)
	}
	Else {
		Write "'"_$$$Text("Unable to open diagram:")_" "_$ZCVT(..bpId,"O","JS")_"'"
		Set tSC = $$$OK
	}

	Quit tSC
}

/// Helper method to load BPL diagram from disk.
Method LoadBPLDiagram() As %Status
{
	If (..bpMissing) || (..bpId = "") || (..isNew && (('##class(%Dictionary.ClassDefinition).%ExistsId(..bpId)) || '(##class(%Dictionary.XDataDefinition).IDKEYExists(..bpId,"BPL") || ##class(%Dictionary.XDataDefinition).IDKEYExists(..bpId,"BPLError")))) {
		// No bp: create empty one
		Set ..%bpl = ##class(Ens.BPL.UI.Diagram).CreateNewDiagram(..bpId)
		Quit $$$OK
	}

	If '##class(EnsPortal.Utils).IsSubclass(..bpId, "Ens.BusinessProcessBPL") {
		Quit $$$ERROR($$$NotAnInstanceError, "Ens.BusinessProcessBPL")
	}
	Set tStatus = $$$OK
	Set tReadOnly = 0
	Set tDiagram = ""
	Try {
		Set tStatus = ..LoadClassDefinition(..bpId,.tDefinition,.tReadOnly)
		If $$$ISERR(tStatus) Quit
		Set tConcurrency = $select(tReadOnly: 0, 1: 4)
		Set tStatus = ##class(Ens.BPL.UI.Diagram).Open(..bpId,.tDiagram,tConcurrency)
		If $$$ISERR(tStatus) Quit
		If $IsObject(tDiagram) {
			If ..IsSourceControlReadOnly(..GetInternalName()) {
				Set tDiagram.ReadOnly = 2
			} Else {
				Set tDiagram.ReadOnly = tReadOnly
			}
		}
	}
	Catch ex {
		Set tStatus = ex.AsStatus()
	}
	Set ..%bpl = tDiagram
	Quit tStatus
}

/// Output the contents of the given diagram to JSON.
ClassMethod %BPLtoJSON(pBPLName As %String, pDiagram As Ens.BPL.UI.Diagram) As %Status
{
	Set tSC = $$$OK
	Try {
		Write "{ _type:null"

		// compute last mod time
		If (pBPLName'="") {
			Set tInfo=$G(^rINDEXCLASS($$$UPPER(pBPLName)))
			Set tTime=$LG(tInfo,1)
			Set pDiagram.LastModified = ##class(%ZEN.FinderUtils).mactime(tTime)
		}
		Else {
			Set pDiagram.LastModified = "n/a"
		}

		// bp class name
		Write ", BPLClass:'"_$ZCVT(pBPLName,"O","JS")_"'"

		// properties
		For tAttr = "Name","Width","Height","Layout","Language","Request","Response","LastModified","Version","Includes","Annotation","ContextSuperClass","Timestamp","ReadOnly","PyFromImport" {
			$$$WriteProperty(pDiagram,tAttr)
		}

		// boolean properties
		For tAttr = "ShowAnnotation","HasErrors","Component" {
			$$$WriteBooleanProperty(pDiagram,tAttr)
		}

		// context
		Write ", Context:{ "
		If ($IsObject(pDiagram.Context)) {
			Write "Properties:[ "
			Set tSC = ..%PropertyListtoJSON(pDiagram.Context.Properties)
			If $$$ISERR(tSC) Quit
			Write " ]"
		}
		Write " }",!

		// shapes
		Set tShapeCount = 0
		Write ", ShapeList:[ "
		For n = 1:1:pDiagram.ShapeList.Count() {
			If (tShapeCount>0) {
				Write ", "
			}
			Set tShape = pDiagram.ShapeList.GetAt(n)
			Set tShapeCount = tShapeCount + 1
			If ($IsObject(tShape)) {
				Set tSC = ..%ShapetoJSON(tShape)
				If $$$ISERR(tSC) Quit
			}
			Else {
				Write "null"
			}
		}
		Write " ]",!
	
		// connectors
		Set tConCount = 0
		Write ", Connectors:[ "
		For i = 1:1:pDiagram.ShapeList.Count() {
			Set tShape =pDiagram.ShapeList.GetAt(i)
		
			For c = 1:1:tShape.OutputList.Count() {
				If (tConCount>0) {
					Write ", "
				}
				Set tConCount = tConCount + 1
				Set tConnector = tShape.OutputList.GetAt(c)
				Set tSC = ..%ConnectortoJSON(tConnector)
				If $$$ISERR(tSC) Quit
			}

			If (tShape.GotoConnection) {
				If (tConCount>0) {
					Write ", "
				}
				Set tConCount = tConCount + 1
				Set tConnector = tShape.GotoConnection
				Set tSC = ..%ConnectortoJSON(tConnector)
				If $$$ISERR(tSC) Quit
			}
		}
		Write " ]",!

		Write " }"
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Output the contents of the given property list to JSON.
ClassMethod %PropertyListtoJSON(pList As Ens.BPL.PropertyList) As %Status
{
	Set tSC = $$$OK
	Try {
		For n = 1:1:pList.Count() {
			Set tProp = pList.GetAt(n)
			If (n>1) {
				Write ", "
			}
			Write "{ _type:null"
			// properties
			For tAttr = "Name","Type","InitialExpression","Collection","Annotation" {
				$$$WriteProperty(tProp,tAttr)
			}

			// parameters
			Write ", Parameters:[ "
			Set tParm = ""
			Set tValue = tProp.Parameters.GetNext(.tParm)
			While (tParm '= "") {
				Write "{ Name:'"_$ZCVT(tParm,"O","JS")_"', Value:'"_$ZCVT(tValue,"O","JS")_"' }"
				Set tValue = tProp.Parameters.GetNext(.tParm)
				If (tParm '= "") {
					Write ", "
				}
			}
			Write " ]"

			// boolean properties
			For tAttr = "Instantiate" {
				$$$WriteBooleanProperty(tProp,tAttr)
			}
			Write " }"
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Output a shape in JSON format.
ClassMethod %ShapetoJSON(pShape As Ens.BPL.UI.Shape) As %Status
{
	Set tSC = $$$OK
	Try {
		
		Write "{ _type:'shape'"

		// parent
		Write ", ParentShape:"
		Write $select($IsObject(pShape.Parent) && pShape.Parent.Index: pShape.Parent.Index, 1: "null")

		// properties
		For tAttr = "Index","Name","Type","xPos","yPos","Annotation" {
			$$$WriteProperty(pShape,tAttr)
		}

		// boolean properties
		For tAttr = "Disabled" {
			$$$WriteBooleanProperty(pShape,tAttr)
		}

		// code
		Write ", Code:'"
		Do pShape.Code.Rewind()
		While ('pShape.Code.AtEnd) {
			Set tText = pShape.Code.Read(20000)
			Write $ZCVT(tText,"O","JS")
		}
		Write "'"

		// property bag
		Set tProp=""
		Write ", PropertyBag:{ "
		Set tValue = pShape.PropertyBag.GetNext(.tProp)
		While (tProp'="") {
			Write tProp_":'"_$ZCVT(tValue,"O","JS")_"'"
			Set tValue = pShape.PropertyBag.GetNext(.tProp)
			If (tProp'="") {
				Write ", "
			}
		}
		Write " }"

		// Parameters
		Set tParmName=""
		Write ", Parameters:{ "
		Set tValue = pShape.Parameters.GetNext(.tParmName)
		While (tParmName'="") {
			Write tParmName_":'"_$ZCVT(tValue,"O","JS")_"'"
			Set tValue = pShape.Parameters.GetNext(.tParmName)
			If (tParmName'="") {
				Write ", "
			}
		}
		Write " }"

		// request
		If $IsObject(pShape.Request) {
			Write ", Request:{ "
			Write "Type:'"_$ZCVT(pShape.Request.Type,"O","JS")_"'"
			// activities
			Write ", Activities:[ "
			For n = 1:1:pShape.Request.Activities.Count() {
				If (n>1) {
					Write ", "
				}
				Set tChild = pShape.Request.Activities.GetAt(n)
				Set tSC = ..%ActivitytoJSON(tChild)
				If $$$ISERR(tSC) Quit
			}
			Write "] }"
		}
		If $$$ISERR(tSC) Quit

		// response
		If $IsObject(pShape.Response) {
			Write ", Response:{ "
			Write "Type:'"_$ZCVT(pShape.Response.Type,"O","JS")_"'"

			// activities
			Write ", Activities:[ "
			For n = 1:1:pShape.Response.Activities.Count() {
				If (n>1) {
					Write ", "
				}
				Set tChild = pShape.Response.Activities.GetAt(n)
				Set tSC = ..%ActivitytoJSON(tChild)
				If $$$ISERR(tSC) Quit
			}
			Write "] }"
		}
		If $$$ISERR(tSC) Quit

		Write " }"
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Write "/* error in shape: ",$ZE,"*/",!
	}
	Quit tSC
}

/// Output an activity (for a request/response) in JSON format.
ClassMethod %ActivitytoJSON(pActivity As Ens.BPL.Activity) As %Status
{
#; Defined here because this method will be compiled before any others using these macros
#define WriteProperty(%object,%property)		Set val=$property(%object,%property) Write ", "_%property_":"_$S($IsValidNum(val):val,1:"'"_$zcvt(val,"O","JS")_"'")
#define WriteBooleanProperty(%object,%property)	Set val=+$property(%object,%property) Write ", "_%property_":"_$select(val:"true",1:"false")

	Set tSC = $$$OK
	Try {
		Set tClassName = pActivity.%ClassName()

		Write "{ _type:'activity', activityType:'"_tClassName_"'"

		// properties
		For tAttr = "Name","XPos","YPos","Annotation" {
			$$$WriteProperty(pActivity,tAttr)
		}

		// boolean properties
		For tAttr = "Disabled" {
			$$$WriteBooleanProperty(pActivity,tAttr)
		}

		// additional properties based on activity class
		// we support only a limited set of activities
		If (tClassName = "Assign") {
			For tAttr = "Property","Value","Action","Key" {
				$$$WriteProperty(pActivity,tAttr)
			}
		}
		Write " }"
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Write "/* error in activity: ",$ZE,"*/",!
	}
	Quit tSC
}

/// Output a connector in JSON format.
ClassMethod %ConnectortoJSON(pShape As Ens.BPL.UI.Connector) As %Status
{
	Set tSC = $$$OK
	Try {
		Write "{ _type:null"

		// properties
		For tAttr = "Type","ConnectType","Name","Condition","LanguageOverride" {
			$$$WriteProperty(pShape,tAttr)
		}

		// boolean properties
		For tAttr = "Disabled" {
			$$$WriteBooleanProperty(pShape,tAttr)
		}

		// from/to
		Write ", FromShape:"_pShape.FromShape.Index
		Write ", ToShape:"_pShape.ToShape.Index

		Write " }"
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
		Write "/* error in connector: ",$ZE,"*/",!
	}
	Quit tSC
}

/// Get the SVG window object for the diagram.
/// This provides a way to access scripts in the SVG diagram.
ClientMethod getSVGWindow() [ Language = javascript ]
{
	var svg = zen('svg');
	return svg ? svg.svgWindow : null;
}

/// Called from diagram to set size of svg canvas.
ClientMethod setCanvasSize(width, height) [ Language = javascript ]
{
	var svg = zen('svg');
	svg.setProperty('svgWidth',width);
	svg.setProperty('svgHeight',height);
}

/// Notification from SVG frame that its contents are loaded.
ClientMethod onSVGLoad() [ Language = javascript ]
{
	try {
		this.initializeSVG();
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onSVGLoad');
	}
}

ClientMethod initializeSVG() [ Language = javascript ]
{
	this.checkStudioHyperEvents();
	// initialize zoom level, restoring last value for this user/document
	// we need call this when the SVG is first rendered, but after we call checkStudioHyperEvents()
	if (this.bpId && this.bpId !='') {
		this.currZoom = this.FetchZoomFromServer(this.bpId);
	}
	var svgWin = this.getSVGWindow();
	this._svgWin = svgWin;
	if (svgWin) {
		this._bplAPI = svgWin.BPL;
		this._bplOptions = svgWin.BPL.Options;
	}
	if (svgWin && svgWin.BPL && svgWin.BPL.Diagram && !this.diagramLoaded) {
		var model = this.getBPLObject();
		if ('string' == typeof model) {
			// error
			alert(model);
		}
		else {
			this.setOption('gridlineStyle',this.prefGridlines);
			this.setOption('showAnnotations',this.prefShowAnnotations);
			this._BPLDiagram = svgWin.BPL.Diagram.create(model);
			this._BPLDiagram.render();
			// don't do initial arrange, just set the value for new items
			this.setOption('autoArrange',(this.prefAutoArrange ? true : false));
			this.diagramLoaded = true;
		}
		this.setReadOnly(this.readOnly || !this.canEdit);

		this.setZoom(this.currZoom,true);
		this.setOption('currentZoom',this.currZoom);
	}
	this.updateIcons();
}

ClientMethod setOption(option, value) [ Language = javascript ]
{
	if (this._bplAPI && this._bplAPI.Options) this._bplAPI.Options[option] = value;
}

ClientMethod setReadOnly(readOnly) [ Language = javascript ]
{
	readOnly = !!readOnly;
	this.readOnly = readOnly;
	if (this._bplAPI) this._bplAPI.readOnly = readOnly;
	var forms = ['generalForm','contextForm','activityForm','connectorForm'];
	for (var i=0; i<forms.length; i++) {
		var currForm = zen(forms[i]);
		var controls = currForm.getControlList();
		for (var j=0; j<controls.length; j++) {
			var control = controls[j];
			control.setProperty('readOnly',readOnly);
			if (control._type != 'button') {
				control.setProperty('disabled',readOnly);
			}
			if (control._type == 'image') {
				var imgEl = control.findElement('image');
				if (imgEl) {
					var classes = [];
					if (imgEl.className != '') classes = imgEl.className.split(' ');
					var toRemove = (readOnly ? 'imageLink' : 'reIconDisabled');
					var removePos = classes.indexOf(toRemove);
					if (removePos != -1) classes.splice(removePos,1);
					var toAdd = (readOnly ? 'reIconDisabled' : 'imageLink');
					if (!classes.contains(toAdd)) classes.push(toAdd);
					imgEl.className = classes.join(' ');
				}
			}
		}
	}
	zen('prefAutoArrange').setProperty('readOnly',readOnly);
	var htmlControls = ['selectNewShape', 'selectNewGroup'];
	for (var i=0; i<htmlControls.length; i++) {
		var control = document.getElementById(htmlControls[i]);
		if (control) control.disabled = readOnly;
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
			btnSave.onclick = function() { zenPage.saveBP(false);return false; }
			btnSave.title = this.tipSave;
		}
		var btnCompile = document.getElementById('command_cmdCompile');
		if (btnCompile) {
			btnCompile.className = 'commandButton';
			btnCompile.title = this.tipCompile;
			btnCompile.onclick = function() { zenPage.compile();return false; }
		}
	}
	this.updateIcons();
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

/// Event raised on canvas.
ClientMethod notify(type) [ Language = javascript ]
{
	try {
		if (!zen) return;
		if (this.bpMissing || !this.diagramLoaded) {
			return;
		}
		
		var shape = this.getSelectedItem();

		switch(type) {
		case 'MOVE':
			this.setModified(true);
		case 'SELECT':
			this.updateActivitySettings(shape);
			this.updateIcons();
			break;
		case 'RESELECT':
			// bring activity tab to front
			zen('propertyTabs').showTab(3);
			break;
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in notify');
	}
}

/// Return the selected item in the editor.
ClientMethod getSelectedItem() [ Language = javascript ]
{
	if (this._BPLDiagram) return this._BPLDiagram.selectedItems[0];
	return null;
}

/// User has changed a diagram value.
ClientMethod diagramChange(field) [ Language = javascript ]
{
	var model = this.getBPLObject();
	if (model) {
	// apply changes to model
		var tabNum = 1;
		if (field) {
			var contForm = field.getForm();
			if (contForm) tabNum = (contForm.id == 'generalForm' ? 1 : 2);
		}
		this.startUndoAction(tabNum);

		var strip = ['Includes','Version'];
		var gProps = ['Annotation','Layout','Width','Height','Component','Includes','Version','PyFromImport'];
		for (var i = 0; i < gProps.length; i++) {
			var propName = gProps[i];
			model[propName] = zen('g' + propName).getValue();
			if (strip.contains(propName)) model[propName] = zenTrim(model[propName]);
		}
		var lang = zen('gLanguage').getValue();
		model.Width = parseInt(model.Width,10);
		model.Height = parseInt(model.Height,10);
		model.Width = isNaN(model.Width) ? 0 : model.Width;
		model.Height = isNaN(model.Height) ? 0 : model.Height;

		// confirm change to language
		var langChangedBasic=false;
		if (model.Language != lang) {
			if (confirm($$$Text('If you change languages you must change all the code within this business process. Are you sure you want to do this?'))) {
				// Note whether changing "to" or "from" Basic
				// This affects whether the visability of LanguageOverride needs to be changed
				if (lang=='basic' || (model.Language=='basic')) {
					langChangedBasic=true;
				}
				// Update diagram model language
				model.Language = lang;
				if (langChangedBasic) {
					// Adjusts visability on Activity form for LanguageOverride
					currentShape=this.getCurrShape()
					var loModelTypes=['alert','assign','branch','code','connector','if','milestone','trace','while','until'];
					if (lang=='basic') {
						// disable and clear Language Override when switching to basic
						for (loItem in loModelTypes)
						{
							languageOverride=zen(loModelTypes[loItem]+'LanguageOverride')
							if (languageOverride) {
								languageOverride.setHidden(1)
								languageOverride=''
							}
						}
						// Updating model also clears the python logo from the currently selected shape
						if (currentShape && currentShape.model) {
							if (currentShape.model.PropertyBag && currentShape.model.PropertyBag.LanguageOverride) {
								// clears loModelTypes
								currentShape.model.PropertyBag.LanguageOverride='';
							} else if (currentShape.model.LanguageOverride) {
								// clears connector
								currentShape.model.LanguageOverride=''
							} 
						}
					} else {
						if (currentShape && currentShape.model) {
							if (loModelTypes.contains(currentShape.model.Type)) {
								languageOverride=zen(currentShape.model.Type+'LanguageOverride')
								if (languageOverride) {
									languageOverride.setHidden(0)
								}
								// expectation for LanguageOverride to be empty when moving from basic to something else
							}

						}
					}
				}
			}
			else {
				zen('gLanguage').setValue(model.Language);
			}
		}

		// don't forget context!
		model.Request = zen('cRequest').getValue();
		model.Response = zen('cResponse').getValue();
		model.ContextSuperClass = zen('cContextSuper').getValue();

		if (this._BPLDiagram) {
			this._BPLDiagram.render();
			// get actual clipped size
			var svg = zen('svg');
			model.Width = svg.svgWidth;
			model.Height = svg.svgHeight;
			zen('gWidth').setValue(model.Width);
			zen('gHeight').setValue(model.Height);
		}
		this.endUndoAction();
	}
}

/// Validate a code expression.
/// This expression is not necessarily the object this.getSelectedItem();
/// ie: Validation applied when navigating away from a shape
ClientMethod validateExpression(expr, languageOverride = "", control) [ Language = javascript ]
{
	// check for ObjectScript
	var model = this.getBPLObject();
	var isValid = true;
	var bplLanguage = (model && model.Language ? model.Language : 'objectscript');
	// Start Region Python Validaton
	if (((bplLanguage=='python') &&  (languageOverride=='')) || (languageOverride=='python')) {
		var msg=this.ValidateCodePy(expr)
		if (msg && ""!=msg) {
			if (control) {
				control.invalidMessage=msg
			}
			isValid=false;
		}
		return isValid
	}
	// End Region Python Validaton

	// If either the model language or override is Python then ObjectScript validation is not applied
	if ((model) && (('objectscript' == model.Language) && (''==languageOverride) || ('objectscript' == languageOverride))) {
		var strExp = expr.toString();
		if (!this._expressionCache) this._expressionCache = { "expressions": [], "valid": [] };
		var exPos = this._expressionCache.expressions.indexOf(strExp);
		if (exPos == -1) {
			if (strExp.indexOf('$$$')==-1) { // assume expressions with macros are ok; only look at 
				if (strExp == (parseFloat(expr) + '')) { // numerics are ok
					isValid = true;
				}
				else {
					var nonWordMatches = strExp.match(/\W/); // look for any non-word characters (i.e. NOT 0-9,a-z,A-Z or _ )
					if (nonWordMatches) {
						var eqMatches = strExp.match(/(\d+[.]*\d*|\w+(\d|\w)*)\s?=\s?(\d+[.]*\d*|\w+(\d|\w)*)/g);
						if (!eqMatches || !eqMatches.contains(strExp)) {
							isValid = zenPage.IsCodeValid(expr);
						}
					}
				}
			}
			this._expressionCache.expressions.push(strExp);
			this._expressionCache.valid.push(isValid)
			
		}
		else {
			isValid = this._expressionCache.valid[exPos];
		}
	}
	return isValid;
}

/// Modify the <property>codeValidation</property> flag and trigger
/// validation using the new value.
ClientMethod changeCodeValidation(newValue) [ Language = javascript ]
{
	if (this.codeValidation == newValue) {
		this.codeValidation = !newValue;
		this.SetCodeValidation(this.bpId,!newValue);
	}
	var form = zen('activityForm');
	form.validate();
}

/// Method to ensure code elements contain leading whitespace.
/// This validation can be disabled from the UI for BPs which
/// do contain routine tags.
ClientMethod validateCode(code, currWindow, showConfirm, languageOverride = "", control) [ Language = javascript ]
{
	if (!this.codeValidation) return true;

	var isValid = true;

	var bpl = this.getBPLObject();
	var bplLanguage = (bpl && bpl.Language ? bpl.Language : 'objectscript');
	// Start Region Python Validate
	if (((bplLanguage=='python') &&  (languageOverride=='')) || (languageOverride=='python')) {
		var msg=this.ValidateCodePy(code)
		if (msg && ""!=msg) {
			if (control) {
				control.invalidMessage=msg
			}
			isValid=false;
		}
		return isValid
	}
	// End Region Python Validate
	if (bplLanguage != 'objectscript' || ((languageOverride!='') && (languageOverride!='objectscript'))) return true;

	if (!currWindow) currWindow = self;
	
	var valArray = code.split('\n');
	var hasTag = false;
	for (var i = 0; i < valArray.length; i++) {
		var currVal = valArray[i];
		if (currVal != '') {
			var start = currVal.substring(0,1);
			if (start.match(/\S/)) { // non-whitespace character
				if (currVal.match(/^(trap)/i) || currVal.match(/^(exit)/i)) {
					hasTag = false;
				}
				else {
					hasTag = true;
					break; // exit FOR loop
				}
			}
		}
	}
	if (hasTag) {
		if (showConfirm) {
			var msg = $$$Text('Your code has a line without leading whitespace which will be treated as a routine tag by the compiler.');
			msg = msg + '\n' + $$$Text('Is this intentional?');
			isValid = currWindow.confirm(msg);
		}
		else {
			isValid = false;
		}
	}
	return isValid;
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
				if '##class(%Dictionary.CompiledMethod).%ExistsId(tryCls_"||"_method) {
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
	except:
		exc_type, exc_value, exc_traceback = sys.exc_info()
		ret='\n'.join(traceback.format_exception_only(exc_type, exc_value))
	return ret
}

/// Build a map of the properties expected in various shapes and the controls to fetch the values from.
ClientMethod buildActivityMap() [ Language = javascript ]
{
	if (!this._fieldMap) this._fieldMap = {};
	if (!this._fieldMapUtils) this._fieldMapUtils = {};
	if (!this._fieldMapUtils.getActivityPos) { // get the current xPos or yPos and update the control with the calculated value
	 	this._fieldMapUtils.getActivityPos = function getActivityPos(shapeModel,which) {
			if (((which != 'xPos') && (which != 'yPos')) || !shapeModel) return 0;
			var ctrl = zen('a'+which);
			var oldVal = shapeModel[which];
			var newVal = parseInt(ctrl.getValue(),10);
			newVal = isNaN(newVal) ? oldVal : newVal;
			ctrl.setValue(newVal);
			return newVal;
		};
	}
	if (!this._fieldMapUtils.onProcessBranch) { // create or remove a gotoConnection when the label property changes
	 	this._fieldMapUtils.onProcessBranch = function onProcessBranch(shape) {
			var label = shape.model.PropertyBag.Label;
			if (shape.gotoConnection && (shape.gotoConnection.toShape.model.PropertyBag.Label != label)) {
				shape.gotoConnection.remove();
			}
			if ((label != '') && !shape.gotoConnection) {
				var labelShape = zenPage._BPLDiagram.index.label[label];
				if (labelShape) zenPage.createConnectorModel(shape,labelShape,'','goto','');
			}
		};
	}
	if (!this._fieldMapUtils.getActivityName) { // ensure updates occur when we change a label's name
		this._fieldMapUtils.getActivityName = function getActivityName(shapeModel,name) {
			var newName = zen('aName').getValue();
			if ((shapeModel.Type == 'label') || (shapeModel.Type == 'call')) {
				var oldName = shapeModel.Name;
				var shape = zenPage._BPLDiagram.shapeList[shapeModel.Index];
				if ((oldName != '') && zenPage._BPLDiagram.index[shapeModel.Type][oldName] === shape) delete zenPage._BPLDiagram.index[shapeModel.Type][oldName];
				if (shape) {
					if (newName != '') zenPage._BPLDiagram.index[shapeModel.Type][newName] = shape;
					if (shapeModel.Type == 'label') {
						for (var i = 0; i < shape.inputList.length; i++) {
							var connection = shape.inputList[i];
							if (connection && connection.model && (connection.model.ConnectType == 'goto') && connection.fromShape && connection.fromShape.model) {
								connection.fromShape.model.PropertyBag.Label = newName;
							}
						}
						for (var i in zenPage._BPLDiagram.index.branch) {
							var branch = zenPage._BPLDiagram.index.branch[i];
							if (branch && branch.model && (branch.model.PropertyBag.Label != '') && (branch.model.PropertyBag.Label == newName) && !branch.gotoConnection) {
								zenPage.createConnectorModel(branch,shape,'','goto','');
							}
						}
					}
				}
			}
			return newName;
		};
	}
	if (!this._fieldMapUtils.getAsync) { // get the value of the Async flag in 0/1 format
		this._fieldMapUtils.getAsync = function getAsync(shapeModel,prop) {
			return zen('callAsync').getValue() ? '1' : '0';
		};
	}
	if (!this._fieldMapUtils.getCallProps) { // build the Request/Response property
		this._fieldMapUtils.getCallProps = function getCallProps(shapeModel,which) {
			if ((which != 'Request') && (which != 'Response')) return null;
			var activities = [];
			if (shapeModel[which] && shapeModel[which].Activities) activities = shapeModel[which].Activities;
			var type = zen('call'+ which + 'Type').getValue();
			return { "activityType": "Assign", "Type": type, "Activities": activities };
		};
	}
	// The following don't have extra properties:
	//		break, continue, empty, flow, join, label, reply, scope, sequence, switch
	// If a given field has a get() function defined, that will be used to populate the field's value.
	// If onProcess is defined, that will be invoked after processing the actual values.
	this._fieldMap.activity = {
		"all": { "Name": { "get": this._fieldMapUtils.getActivityName }, "Annotation": "aAnnotation", "Disabled": "aDisabled", 
			"xPos": { "get": this._fieldMapUtils.getActivityPos }, "yPos": { "get": this._fieldMapUtils.getActivityPos } },
		"alert": { "PropertyBag": { "Value": "alertValue","LanguageOverride":"alertLanguageOverride" } },
		"assign": { "PropertyBag": { "Action": "assignAction", "Property": "assignProperty", "Value": "assignValue", "LanguageOverride":"assignLanguageOverride", "Key": "assignKey" } },
		"branch": { "PropertyBag": { "Condition": "branchCondition", "Label": "branchLabel","LanguageOverride":"branchLanguageOverride" },
					"onProcess": this._fieldMapUtils.onProcessBranch },
		"call": { "Request": { "get": this._fieldMapUtils.getCallProps }, "Response": { "get": this._fieldMapUtils.getCallProps },
					"PropertyBag": { "Target": "callTarget", "Timeout": "callTimeout", "Async": { "get": this._fieldMapUtils.getAsync }, "LanguageOverride":"callLanguageOverride" } },
		"catch": { "PropertyBag": { "Fault": "catchFault" } },
		"code": { "Code": "codeCode", "PropertyBag": {"LanguageOverride":"codeLanguageOverride"} },
		"compensate": { "PropertyBag": { "Target": "compensateTarget" } },
		"delay": { "PropertyBag": { "Duration": "delayDuration", "Until": "delayUntil" } },
		"foreach": { "PropertyBag": { "Key": "foreachKey", "Property": "foreachProperty" } },
		"if": { "PropertyBag": { "Condition": "ifCondition", "LanguageOverride":"ifLanguageOverride" } },
		"milestone": { "PropertyBag": { "Value": "milestoneValue","LanguageOverride": "milestoneLanguageOverride" } },
		"rule": { "PropertyBag": { "Rule": "ruleRule", "RuleContext": "ruleRuleContext", "ResultLocation": "ruleResultLocation", "ReasonLocation": "ruleReasonLocation" } },
		"sql": { "Code": "sqlCode" },
		"sync": { "PropertyBag": { "Calls": "syncCalls", "Timeout": "syncTimeout", "Type": "syncType", "AllowResync": "syncAllowResync" } },
		"throw": { "PropertyBag": { "Fault": "throwFault" } },
		"trace": { "PropertyBag": { "Value": "traceValue","LanguageOverride":"traceLanguageOverride" } },
		"transform": { "PropertyBag": { "Class": "transformClass", "Source": "transformSource", "Target": "transformTarget" } },
		"until": { "PropertyBag": { "Condition": "untilCondition","LanguageOverride":"untilLanguageOverride" } },
		"while": { "PropertyBag": { "Condition": "whileCondition","LanguageOverride":"whileLanguageOverride" } },
		"xpath": { "PropertyBag": { "Context": "xpathContext", "Expression": "xpathExpression", "PrefixMappings": "xpathPrefixMappings",
								"Property": "xpathProperty", "SchemaSpec": "xpathSchemaSpec", "Source": "xpathSource" } },
		"xslt": { "PropertyBag": { "Source": "xsltSource", "Target": "xsltTarget", "XSLURL": "xsltXSLURL", "XSLTVersion": "xsltVersion" } }
	};
	this._fieldMap.initialValues = {
		"call": { "PropertyBag": { "Async": 1 } },
		"sync": { "PropertyBag": { "Type": "all" } }
	};
}

/// Helper method to invoke the correct get code in the activity map
ClientMethod getMapProperty(shapeModel, map, field) [ Language = javascript ]
{
	var value = '';
	if (map && field && map[field]) {
		value = map[field].get ? map[field].get(shapeModel,field) : zen(map[field]).getValue();
	}
	return value;
}

/// User has changed an activity value.<br/>
/// languageOverrideChanging is an optional parameter.<br/>
///   Supplied ONLY when the select list for a LanguageOverride is modified.<br/>
///   The values used will be for example: '', 'objectscript', 'python'<br/>
///   Required for cross-validation of controls on the Activity form
ClientMethod activityChange(isText As %Boolean = 0) [ Language = javascript ]
{
	if (this._textMonitor) {
		if (this._textMonitor.processing) return;
		if (isText && !this._textMonitor.textChanged) return;
		this._textMonitor.processing = true;
		this._textMonitor.reset();
	}
	if (!this._fieldMap) this._fieldMap = {};
	if (!this._fieldMap.activity) this.buildActivityMap();
	var form = zen('activityForm');
	form.validate();
	var tabNum = 3;
	this.startUndoAction(tabNum);
	var shape = this.getSelectedItem();
	if (shape) {
		var shapeModel = shape.model;
		var maps = [ 'all', shapeModel.Type ];
		for (var i = 0; i < maps.length; i++) {
			var map = this._fieldMap.activity[maps[i]];
			if (map) {
				for (var field in map) {
					if (field == 'PropertyBag') {
						for (var bagField in map.PropertyBag) {
							shapeModel.PropertyBag[bagField] = this.getMapProperty(shapeModel,map.PropertyBag,bagField);
						}
					}
					else if (field != 'onProcess') {
						shapeModel[field] = this.getMapProperty(shapeModel,map,field);
					}
				}
				if (map.onProcess) map.onProcess(shape);
			}
		}

		if (this._BPLDiagram && (this._BPLDiagram.currentOperation == 'move')) this._BPLDiagram.moveComplete();
		shape.render();
		shape.renderConnections();
		this.validateShape(shape);
	}
	this.endUndoAction();
	if (this._textMonitor) this._textMonitor.processing = false;
}

/// User has changed a connector value
ClientMethod connectorChange(isText As %Boolean = 1) [ Language = javascript ]
{
	if (1==isText) {
		if (this._textMonitor) {
			alert(this._textMonitor.textChanged)
			if (this._textMonitor.processing) return;
			if (!this._textMonitor.textChanged) return;
			this._textMonitor.processing = true;
		}
	}
	var shape = this.getSelectedItem();
	if (shape) {
		var newName = zen('cName').getValue();
		var newCondition = zen('cCondition').getValue();
		var newLanguageOverride = zen('cLanguageOverride').getValue();
		if ((shape.model) && (shape.model.ConnectType=='case') && (shape.model.Condition!=newCondition)) {
			var form = zen('connectorForm');
			form.validate();
		}
		// Also adding LanguageOverride to Connector
		if ((newName != shape.model.Name) || (newCondition != shape.model.Condition) || (newLanguageOverride != shape.model.LanguageOverride)) {
			this.startUndoAction();
			shape.model.Name = newName;
			shape.model.Condition = newCondition;
			shape.model.LanguageOverride = newLanguageOverride;
			shape.render();
			this.endUndoAction();
		}
	}
	if (1==isText) {
		if (this._textMonitor) {
			this._textMonitor.reset();
			this._textMonitor.processing = false;
		}
	}
}

/// Helper method to allow Call Builder to create valid Activity list in current window context.
ClientMethod addCallActivity(prop, reset, action, annotation, key, property, value) [ Language = javascript ]
{
	if ((!prop) || (action == null) || (annotation == null) || (key == null) || (property == null) || (value == null)) {
		return;
	}
	if (prop.Activities && reset) prop.Activities = [];
	var activity = {
		"activityType": "Assign", "Action": action, "Annotation": annotation,
		"Key": key, "Property": property, "Value": value	
	};
	prop.Activities.push(activity);
}

ClientMethod createConnectorModel(fromShape, toShape, name, connType, condition) [ Language = javascript ]
{
	var model = null;
	var bpl = this.getBPLObject();
	this.startUndoAction();
	if ((bpl.ShapeList.contains(fromShape.model)) && (bpl.ShapeList.contains(toShape.model))) {
		connType = (connType == null) ? '' : connType;
		condition = (condition == null) ? '' : condition;
		if (connType == 'goto') fromShape.model.PropertyBag.Label = toShape.model.Name;
		model = { "_type": null, "Type": "connector", "ConnectType": connType, "Name": name, "Condition": condition,
			"Disabled": false, "FromShape": fromShape.model.Index, "ToShape": toShape.model.Index };
		bpl.Connectors.push(model);
		if (this._bplAPI) {
			var conn = this._bplAPI.Connector.createConnector(model);
			if (conn) conn.render();
		}
	}
	if (this.prefAutoArrange) this.arrange();
	this.endUndoAction();
	return model;
}

ClientMethod createShapeModel(type, name, parentIndex, xPos, yPos, annotation, allAuto) [ Language = javascript ]
{
	if (!this.checkEdit() || this.readOnly) return;
	this.startUndoAction();
	var bplModel = this.getBPLObject();
	var nextIndex = bplModel.ShapeList.length;
	var shapeModel = { "_type": 'shape', "ParentShape": parentIndex, "Index": nextIndex,
		"Name": name, "Type": type, "xPos": xPos, "yPos": yPos, "Annotation": annotation ? annotation: '',
		"Disabled": false, "Code": '', "PropertyBag": {}, "Parameters": {}
	};
	bplModel.ShapeList.push(shapeModel);
	
	if (!this._fieldMap) this._fieldMap = {};
	if (!this._fieldMap.activity) this.buildActivityMap();
	
	if (type == 'call') {
		shapeModel.Request =  { "Type": "Ens.Request", "Activities": [] };
		shapeModel.Response = { "Type": "Ens.Response", "Activities": [] };
	}

	if (this._fieldMap.activity[type]) {
		var initVals = this._fieldMap.initialValues ?  this._fieldMap.initialValues[type] : null;
		for (var field in this._fieldMap.activity[type]) {
			if (field == 'PropertyBag') {
				for (var bagProp in this._fieldMap.activity[type].PropertyBag) {
					if (!shapeModel.PropertyBag[bagProp]) {
						shapeModel.PropertyBag[bagProp] = (initVals && initVals.PropertyBag && (typeof initVals.PropertyBag[bagProp] != 'undefined')) ? initVals.PropertyBag[bagProp] : '';
					}
				}
			}
			else if ((field != 'onProcess') && !shapeModel[field]) {
				shapeModel[field] = (initVals && (typeof initVals[field] != 'undefined')) ? initVals[field] : '';
			}
		}
	}
	var updateLocation = (!xPos) && (!yPos);
	var shape = this._bplAPI.Shape.createShape(shapeModel,updateLocation);
	if (shape && (shapeModel.ParentShape == this._BPLDiagram.currentParent)) shape.render();

	// some shapes automatically create other shapes
	var startShape = shape;
	var endShape = shape;

	switch (type) {
		case 'foreach':
		case 'sequence':
		case 'while':
		case 'until':
		case 'catch':
		case 'catchall':
		case 'compensationhandler':
			var childStart = this.createShapeModel('start','',shapeModel.Index,this._bplAPI.Constant.initialX,this._bplAPI.Constant.initialY,'');
			var childEnd = this.createShapeModel('end','',shapeModel.Index,this._bplAPI.Constant.initialX,this._bplAPI.Constant.initialY +(4 * this._bplAPI.Constant.shape.ySpace),'');
			if (this._BPLDiagram) {
				var childStartShape = this._BPLDiagram.shapeList[childStart.Index];
				var childEndShape = this._BPLDiagram.shapeList[childEnd.Index];
				if (childStartShape && childEndShape) {
					// add shortcut connection for these three types
					if (['catch','catchall','compensationhandler'].contains(type)) {
						childStartShape.addOutput(childEndShape,'');
					}
					else if (allAuto && ['foreach','sequence','while','until'].contains(type)) {
						var emptyChild = this.createShapeModel('empty','',shapeModel.Index,this._bplAPI.Constant.initialX,this._bplAPI.Constant.initialY + (2 *this._bplAPI.Constant.shape.ySpace),'');
						if (emptyChild) {
							var emptyChildShape = this._BPLDiagram.shapeList[emptyChild.Index];
							if (emptyChildShape) {
								childStartShape.addOutput(emptyChildShape,'','');
								emptyChildShape.addOutput(childEndShape,'','');
							}
						}
					}
				}
			}
			break;
		case 'flow':
			var join = this.createShapeModel('join','',parentIndex,shapeModel.xPos,shapeModel.yPos + this._bplAPI.Constant.shape.ySpace*2,'');
			var sequence = this.createShapeModel('sequence','',parentIndex,shapeModel.xPos,shapeModel.yPos + this._bplAPI.Constant.shape.ySpace,'');
			if (this._BPLDiagram) {
				this._BPLDiagram.createLocation.x = join.xPos + 25;
				this._BPLDiagram.createLocation.y = join.yPos + 25;
				var joinShape = this._BPLDiagram.shapeList[join.Index];
				var sequenceShape = this._BPLDiagram.shapeList[sequence.Index];
				if (shape && sequenceShape) shape.addOutput(sequenceShape,'','');
				if (sequenceShape && joinShape) sequenceShape.addOutput(joinShape,'','');
				endShape = joinShape;
			}
			break;
		case 'if':
		case 'switch':
			var join = this.createShapeModel('join','',parentIndex,shapeModel.xPos,shapeModel.yPos + this._bplAPI.Constant.shape.ySpace,'');
			if (this._BPLDiagram) {
				this._BPLDiagram.createLocation.x = join.xPos + 25;
				this._BPLDiagram.createLocation.y = join.yPos + 25;
				endShape = this._BPLDiagram.shapeList[join.Index];
				// add a default connector
				var connName = '';
				if (type == 'switch') { connName = 'default'; }
				else if (type == 'if') { connName = 'true'; }
				shape.addOutput(endShape,connName,'');				
			}
			break;
		case 'scope':
			var catchAll = this.createShapeModel('catchall','',parentIndex,shapeModel.xPos,shapeModel.yPos + this._bplAPI.Constant.shape.ySpace,'');
			var join = this.createShapeModel('join','',parentIndex,shapeModel.xPos,shapeModel.yPos + (2*this._bplAPI.Constant.shape.ySpace),'');
			if (this._BPLDiagram) {
				this._BPLDiagram.createLocation.x = join.xPos + 25;
				this._BPLDiagram.createLocation.y = join.yPos + 25;
				var catchAllShape = this._BPLDiagram.shapeList[catchAll.Index];
				var joinShape = this._BPLDiagram.shapeList[join.Index];
				if (shape && catchAllShape) shape.addOutput(catchAllShape,'');
				if (catchAllShape && joinShape) catchAllShape.addOutput(joinShape,'');
				if (joinShape) endShape = joinShape;
			}
			break;
		default:
			break;
	}

	var selectedItems = null;
	if (this._BPLDiagram) selectedItems = this._BPLDiagram.selectedItems;

	// try to connect new shapes to the diagram automatically
	if (allAuto && this._bplAPI && this._bplAPI.Options.smartConnect && selectedItems) {
		this.autoConnect(startShape,endShape);
	}
	
	if (allAuto && this.prefAutoArrange) this.arrange();
	this.endUndoAction();

	return shapeModel;
}

ClientMethod autoConnect(startShape, endShape) [ Language = javascript ]
{
	if (this._bplAPI && this._bplAPI.Options.smartConnect && this._BPLDiagram && this._BPLDiagram.selectedItems) {
		// if a connection is selected, replace it
		if (this._BPLDiagram.selectedItems.length == 1) {
			var item = this._BPLDiagram.selectedItems[0];
			if (item.model.Type == "connector") {
				var before = item.fromShape;
				var after = item.toShape;
				var model = item.model;
				var connType = model.ConnType;
				if (!connType) connType = '';

				item.remove();

				item = before.addOutput(startShape,model.name,connType,model.Condition);
				endShape.addOutput(after,'');
			}
			else {
				if ((item.model.ParentShape == startShape.model.ParentShape) &&	(item.model.yPos > startShape.model.yPos) && (!this.prefAutoArrange) &&
						item.canAcceptOutput(startShape) && startShape.canAcceptInput(item) && 
						endShape.canAcceptOutput(item) && item.canAcceptInput(endShape)) {
					// selected item is unconnected (i.e. can accept input and output) and below new item (except in case where autoarrange is enabled
					// insert shape(s) before item
					endShape.addOutput(item,'');
				}
				else if ((item.model.ParentShape == startShape.model.ParentShape) && item.canAcceptOutput(startShape) && startShape.canAcceptInput(item)) {
					// insert shape(s) after item
					item.addOutput(startShape,'',((item.model.Type == 'switch') ? 'case' : ''));
				}
				else if ((item.model.ParentShape == endShape.model.ParentShape) && endShape.canAcceptOutput(item) && item.canAcceptInput(endShape)) {
					// insert before item
					endShape.addOutput(item,'');
				}
			}
		}
		// if two shapes are selected try to add the new shape(s) in between
		else if (this._BPLDiagram.selectedItems.length == 2) {
			var item0 = this._BPLDiagram.selectedItems[0];
			var item1 = this._BPLDiagram.selectedItems[1];
			var currentParent = this._BPLDiagram.currentParent;

			if ((item0.model.Type != 'connector') && (item1.model.Type != 'connector') &&
					(item0.model.ParentShape == currentParent) && (item1.model.ParentShape == currentParent)) {
				if ((item0.model.yPos < item1.model.yPos) && item0.canAcceptOutput(startShape) &&
						startShape.canAcceptInput(item0) && endShape.canAcceptOutput(item1)	&& item1.canAcceptInput(startShape)) {
					// insert between item0 and item1
					item0.addOutput(startShape,'');
					endShape.addOutput(item1,'');
				}
				else if ((item1.model.yPos < item0.model.yPos) && item1.canAcceptOutput(startShape) &&
						startShape.canAcceptInput(item1) && endShape.canAcceptOutput(item0) && item0.canAcceptInput(endShape)) {
					// insert between item1 and item0
					item1.addOutput(startShape,"");
					endShape.addOutput(item0,"");
				}
			}
		}
	}
}

/// User has selected a new shape to add.
ClientMethod addNewShape(shapeType) [ Language = javascript ]
{
	if (!zenPage.checkEdit()) { return false; }

	if (!shapeType) {
		var select = self.document.getElementById('selectNewShape');
		shapeType = select.value;
		select.value = 'alert';	// force reset of dropdown
		select.value = '';
	}

	this.startUndoAction();
	this.setOption('autoArrange',false);
	var currentParent = this._BPLDiagram ? this._BPLDiagram.currentParent : null;
	var shapeModel = this.createShapeModel(shapeType,'',currentParent,null,null,'',true);
	this.setOption('autoArrange',this.prefAutoArrange);
	this.endUndoAction();
}

ClientMethod addNewGroup(groupType) [ Language = javascript ]
{
	if (!zenPage.checkEdit()) { return false; }
	if (!groupType) {
		var select = self.document.getElementById('selectNewGroup');
		groupType = select.value;
		select.value = '';
	}

	var groupInfo = {};
	if (this._BPLDiagram) {
		if (!this._BPLDiagram.canGroupShapes(groupType,groupInfo)) {
			alert(this._bplAPI.getLocalText('EDCannotGroup'));
		}
		else {
			this.startUndoAction();
			this.setOption('autoArrange',false);
			var bplModel = this.getBPLObject();
			var isParentGroup = ['foreach','sequence','catch','catchall','compensationhandler','until','while'].contains(groupType);
			var groupModel = this.createShapeModel(groupType,'',this._BPLDiagram.currentParent);
			if (groupModel) {
				var groupShape = this._BPLDiagram.shapeList[groupModel.Index];
				if (groupShape) {
					var lastGroupShape = null;
					if (isParentGroup) { lastGroupShape = groupShape; }
					else {
						var matches = this._BPLDiagram.findMatchingShapes(groupShape);
						for (var shapeIndex in matches) {
							lastGroupShape = matches[shapeIndex];
						}
					}
					
					var newStartShape = null;
					var newEndShape = null;
					if (isParentGroup) {
						for (var i = 0; i < groupShape.children.length; i++) {
							var child = groupShape.children[i];
							if (child) {
								if (child.model.Type == 'start') { newStartShape = child; }
								else if (child.model.Type == 'end') { newEndShape = child; }
								else {
									child.remove();
									bplModel.ShapeList[child.model.Index] = null;
								}
							}
						}
					}
					else {
						newStartShape = groupShape;
						newEndShape = lastGroupShape;
					}
					var previousShape = null;
					var nextShape = null;
					// find the shape before the group and remove the existing connector
					if (groupInfo && groupInfo.firstShape) {
						var inConn = groupInfo.firstShape.inputList[0];
						if (inConn) {
							previousShape = inConn.fromShape;
							inConn.remove();
							previousShape.addOutput(groupShape,inConn.model.Name,'');
							if (inConn.model.Condition != '') {
								var newConn = groupShape.inputList[0];
								if (newConn) newConn.model.Condition = inConn.model.Condition;
							}
						}
					}
					// find the shape after the group and remove the existing connector
					if (groupInfo && groupInfo.lastShape) {
						var outConn = groupInfo.lastShape.outputList[0];
						if (outConn) {
							nextShape = outConn.toShape;
							outConn.remove();
							lastGroupShape.addOutput(nextShape,outConn.model.Name,'');
							if (outConn.model.Condition != '') {
								var newConn = lastGroupShape.outputList[0];
								if (newConn) newConn.model.Condition = outConn.model.Condition;
							}
						}
					}

					if (isParentGroup) { // modify the elements' parent references
						for (var i = 0; i < this._BPLDiagram.selectedItems.length; i++) {
							var item = this._BPLDiagram.selectedItems[i];
							if (item && (item.model.Type != 'connector')) {
								item.changeParent(groupModel.Index);
							}
						}
					}
					
					/*	Connect the elements of the group of selected items to their new end shape
						If groupType = 'scope' then we need to add between the Scope and Catchall.
						We need to remove the connector b/n Scope and Catchall before adding
						newStartShape = Scope
						newEndShape is the join but we want the CatchAll
					*/
					if (groupType == 'scope') {
						var scopeoutConn = newStartShape.outputList[0];
						if (scopeoutConn) {
							var catchAllShape = scopeoutConn.toShape;
							scopeoutConn.remove();
							if (catchAllShape && groupInfo.lastShape) groupInfo.lastShape.addOutput(catchAllShape,'','');
						}
					} else {
						if (newEndShape && groupInfo.lastShape) groupInfo.lastShape.addOutput(newEndShape,'','');
					}
					// connect the elements of the group of selected items to their new start shape			
					if (newStartShape && groupInfo.firstShape) newStartShape.addOutput(groupInfo.firstShape,'','');
					// arrange newly grouped shapes if inside a parent
					if (isParentGroup) { this._BPLDiagram.arrangeShapes(groupModel.Index); }
					else if (this.prefAutoArrange) { this._BPLDiagram.arrangeShapes(); }
					groupShape.updateStyle();
					if (lastGroupShape != groupShape) lastGroupShape.updateStyle();
				}
			}
			this.setOption('autoArrange',this.prefAutoArrange);
			this.endUndoAction();
		}
	}
}

/// User has selected a new zoom level.
ClientMethod setZoom(zoom, updateSelect) [ Language = javascript ]
{
	zoom = parseInt(zoom,10);
	if (isNaN(zoom)) return;

	zen('svg').setProperty('zoom',zoom);
	this.currZoom = zoom;
	this.setOption('currentZoom',zoom);
	this.SaveZoomToServer(zoom,this.bpId);
	if (updateSelect) {
		var select = self.document.getElementById('selectZoom');
		if (select) select.value = zoom;
	}
}

ClassMethod SaveZoomToServer(pZoom As %String, pName As %String) [ Internal, ZenMethod ]
{
	If ($G(pName)'="") && (+$G(pZoom)) {
		If pZoom=..#DEFAULTZOOM {
			Kill ^IRIS.Temp.EnsBPLEditorZoom($Username,$Namespace,pName)
		}
		Else  {
			Set ^IRIS.Temp.EnsBPLEditorZoom($Username,$Namespace,pName) = +pZoom
		}
	}
}

ClassMethod FetchZoomFromServer(pName As %String) As %String [ Internal, ZenMethod ]
{
	Set tZoom = ..#DEFAULTZOOM
	If $G(pName)'="" {
		Set tZoom = $G(^IRIS.Temp.EnsBPLEditorZoom($Username,$Namespace,pName))
		Set:'tZoom tZoom = ..#DEFAULTZOOM
	}
	Quit tZoom
}

/// Paste items from the clipboard.
/// The logic is predicated on parents being copied before children.
ClientMethod paste() [ Language = javascript ]
{
	var icon = self.document.getElementById('iconPaste');
	if (icon.disabled) return;

	if (this._BPLDiagram && this._BPLDiagram.clipboard) {
		var bplModel = this.getBPLObject();
		var conns = [];
		var shapeIndex = {};
		this.startUndoAction();
		for (var i = 0; i < this._BPLDiagram.clipboard.length; i++) {
			var shapeModel = this._BPLDiagram.clipboard[i];
			if (shapeModel) {
				var checkAutoConnect = false;
				if (shapeModel.Type == 'connector') { // do connectors after we translate all the shape index values
					conns.push(shapeModel);
				}
				else {
					var newShapeModel = this.cloneObject(shapeModel);
					newShapeModel.Index = bplModel.ShapeList.length;
					shapeIndex[shapeModel.Index] = newShapeModel.Index;
					if ((newShapeModel.ParentShape != null) && (shapeIndex[newShapeModel.ParentShape])) {
						newShapeModel.ParentShape = shapeIndex[newShapeModel.ParentShape];
					}
					else {
						newShapeModel.ParentShape = this._BPLDiagram.currentParent;
						newShapeModel.xPos = this._BPLDiagram.createLocation.x;
						newShapeModel.yPos = this._BPLDiagram.createLocation.y;
						checkAutoConnect = true;
					}
					bplModel.ShapeList.push(newShapeModel);
					var newShape = this._bplAPI.Shape.createShape(newShapeModel);
					if (newShape && (newShapeModel.ParentShape == this._BPLDiagram.currentParent)) newShape.render();
					if (checkAutoConnect && newShape) this.autoConnect(newShape,newShape);
				}
			}
		}
		for (var i = 0; i < conns.length; i ++) {
			var connModel = conns[i];
			if (connModel) {
				var newConnModel = this.cloneObject(connModel);
				if (shapeIndex[newConnModel.FromShape] && shapeIndex[newConnModel.ToShape]) {
					newConnModel.FromShape = shapeIndex[newConnModel.FromShape];
					newConnModel.ToShape = shapeIndex[newConnModel.ToShape];
					bplModel.Connectors.push(newConnModel);
					var newConn = this._bplAPI.Connector.createConnector(newConnModel);
					if (newConn) newConn.render();
				}
			}
		}
		this.endUndoAction();
	}
}

ClientMethod drillDown() [ Language = javascript ]
{
	var icon = self.document.getElementById('iconDrillDown');
	if (icon.disabled) return;

	if (this._BPLDiagram) {
		this._BPLDiagram.drillDown();
		this.updateIcons();
	}
}

ClientMethod drillUp() [ Language = javascript ]
{
	var icon = self.document.getElementById('iconDrillUp');
	if (icon.disabled) return;

	if (this._BPLDiagram) {
		this._BPLDiagram.shiftUp();
		this.updateIcons();
	}
}

ClientMethod arrange() [ Language = javascript ]
{
	this.startUndoAction();
	if (this._BPLDiagram) this._BPLDiagram.arrangeShapes();
	this.endUndoAction();
}

/// Copy selected shape(s).
/// Note that we copy parents *BEFORE* children so that we can translate ParentShape references during paste.
ClientMethod copyShape(isCut, warnings) [ Language = javascript ]
{
	var warnings = [];
	var iconName = 'icon' + (isCut ? 'Cut' : 'Copy');
	var icon = self.document.getElementById(iconName);
	if (icon.disabled) return (isCut ? warnings : null);

	if (this._BPLDiagram && this._BPLDiagram.selectedItems) {
		this._BPLDiagram.clipboard = [];
		var selectedItems = this._BPLDiagram.selectedItems;
		for (var i = 0; i < selectedItems.length; i++) {
			var shape = selectedItems[i];
			if (shape && shape.model && shape.canCopy(warnings)) {
				var copyModel = true;
				if (shape.model.ParentShape) { // delay copy when the parent is selected to ensure parent is copied first
					var parentShape = this._BPLDiagram.shapeList[shape.model.ParentShape];
					copyModel = (!parentShape) || (!selectedItems.contains(parentShape));
				}
				var copy = this.cloneObject(shape.model);
				this._BPLDiagram.clipboard.push(copy);
				if (shape.children && (shape.children.length > 0)) {
					for (var j = 0; j < shape.children.length; j++) {
						var child = shape.children[j];
						if (child) this.copyShapeChild(child);
					}
				}
			}
		}
		if ((!isCut) && (warnings.length > 0)) {
			var msg = (warnings.length == selectedItems.length) ? $$$Text('None of the selected shapes could be copied:') : $$$Text('Not all selected shapes could be copied:') + '\n';
			msg += warnings.join('\n');
			alert(msg);
		}
	}
	if (isCut) return warnings;
	this.updateIcons();
}

ClientMethod copyShapeChild(shape) [ Language = javascript ]
{
	if (shape && shape.model) {
		var copy = this.cloneObject(shape.model);
		this._BPLDiagram.clipboard.push(copy);

		// copy outputs to ensure connections are copied, but avoid duplication on input
		for (var i = 0; i < shape.outputList.length; i++) {
			if (shape.outputList[i]) this._BPLDiagram.clipboard.push(this.cloneObject(shape.outputList[i].model));
		}
		if (shape.gotoConnection) this._BPLDiagram.clipboard.push(this.cloneObject(shape.gotoConnection.model));
		// copy children
		for (var i = 0; i < shape.children.length; i++) {
			var child = shape.children[i];
			if (child) this.copyShapeChild(child);
		}
	}
}

/// Helper method to recurse through children of selected items.
ClientMethod deleteShapeModel(bplModel, shape, warnings) [ Language = javascript ]
{
	if (!warnings) warnings = [];
	if (bplModel && shape) {
		this.startUndoAction();
		if (shape.children && (shape.children.length > 0)) {
			var child = shape.children.pop();
			while (child) {
				this.deleteShapeModel(bplModel,child,warnings);
				child = shape.children.pop();
			}
		}
		if (shape && shape.model && shape.canDelete(warnings)) {
			shape.remove();
			bplModel.ShapeList[shape.model.Index] = null;
		}
		this.endUndoAction();
	}
}

/// Delete selected item(s).
ClientMethod deleteShape(isCut) [ Language = javascript ]
{
	var warnings = [];
	var iconName = isCut ? 'Cut' : 'Delete';
	var icon = self.document.getElementById('icon' + iconName);
	if (icon.disabled) return (isCut ? warnings : null);

	if (this._BPLDiagram) {
		/*	When isCut we will have checked for start/end in copyShape
			if !isCut walk all selected to make sure can delete all selected before delete any.
			if start or end and has parent and parent not in selected then don't allow delete to proceed
		*/
		var selectedItems = this._BPLDiagram.selectedItems;
		if (!isCut) {
			for (var i = 0; i < selectedItems.length; i++) {
				var shape = selectedItems[i];
				if (shape && shape.model && ((shape.model.Type == 'start')|| (shape.model.Type == 'end'))) {
					if (shape.model.ParentShape) {
						var parentShape = this._BPLDiagram.shapeList[shape.model.ParentShape];
						// null parentShape will be protected in BPL.Event.prototype.canDelete()
						if ((parentShape) && (!selectedItems.contains(parentShape))) warnings.push(this._bplAPI.getLocalText('EDCannotDelete',shape.model.Type));
					}
				}
			}
			if (warnings.length > 0) {
				var msg = $$$Text('None of the selected shapes could be removed:') + '\n';
				msg += warnings.join('\n');
				alert(msg);
				return;
			}
		}
		this.startUndoAction();
		var model = this.getBPLObject();
		for (var i = 0; i < selectedItems.length; i++) {
			this.deleteShapeModel(model,selectedItems[i],warnings);
		}
		this.endUndoAction();
		if ((!isCut) && (warnings.length > 0)) {
			var msg = (warnings.length == selectedItems.length) ? $$$Text('None of the selected shapes could be removed:') : $$$Text('Not all selected shapes could be removed:') + '\n';
			msg += warnings.join('\n');
			alert(msg);
		}
		this._BPLDiagram.selectedItems.length = 0;
	}
	if (isCut) return warnings;
}

/// Cut selected item(s).
ClientMethod cutShape() [ Language = javascript ]
{
	var icon = self.document.getElementById('iconCut');
	if (icon.disabled) return;

	this.startUndoAction();
	var copyWarnings = this.copyShape(true);
	var deleteWarnings = this.deleteShape(true);
	var warnings = copyWarnings.concat(deleteWarnings);
	if (warnings.length > 0) {
		var msg = $$$Text('Not all selected items could be cut from the diagram:') + '\n';
		msg += warnings.join('\n');
		alert(msg);
	}
	this.endUndoAction();
}

/// Update the state of icons in the toolbar.
ClientMethod updateIcons() [ Language = javascript ]
{
	try {
		var itemsSelected = !!(this._BPLDiagram && (this._BPLDiagram.selectedItems.length > 0));
		var haveDiagram = !!this._BPLDiagram;
		// structure is: iconName = enabledFlag
		var icons = { "Arrange": (!this.readOnly) && this.canEdit,
			"Copy": (!this.readOnly) && this.canEdit && itemsSelected,
			"Cut": (!this.readOnly) && this.canEdit && itemsSelected,
			"Delete": (!this.readOnly) && this.canEdit && itemsSelected,
			"DrillDown": haveDiagram && this._BPLDiagram.canDrillDown(),
			"DrillUp": haveDiagram && this._BPLDiagram.canDrillUp(),
			"Paste": haveDiagram && this._BPLDiagram.canPaste(),
			"Print": haveDiagram,
			"Undo": this.canUndo()
		};
		for (var iconName in icons) {
			var icon = self.document.getElementById('icon' + iconName);
			if (icon) {
				icon.disabled = !icons[iconName];
				icon.className = 'reIcon' + (icon.disabled ? 'Disabled' : '');
			}
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in updateIcons');
	}
}

/// Update the description (annotation) of this BP.
ClientMethod setDescription(desc) [ Language = javascript ]
{
	var model = this.getBPLObject();
	if (model) {
		if (desc != model.Annotation) {
			model.Annotation = desc;
			this.setModified(true);
		}
	}
}

/// Return the internal name of the current BPL document.
Method GetInternalName() As %String
{
	Quit $select(..bpId = "": "", 1: $$$NormalizeClassname(..bpId)_".CLS")
}

/// Object submit handler JSON provider.
/// This is called when the client saves the Business Process.
Method SubmitBPL(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, ByRef pResponseObject As %RegisteredObject) As %Status
{
	Set tSC = $$$OK
	Set tDiagramSC = $$$OK

	Try {
		If '##class(EnsPortal.Utils).CheckResourceList(..#EDITRESOURCE) {
			Set tSC = $$$ERROR($$$InsufficientPrivilegeForOperation)
			Quit
		}
		Set tAnnotation = ""
		Set tReadOnly = 0
		If (pCommand '= "forcesave") && ##class(%Dictionary.ClassDefinition).%ExistsId(..bpId) {
			Set tSC = ..LoadClassDefinition(..bpId,.tBPLDef,.tReadOnly,1)
			If $$$ISERR(tSC) Quit
			If $zdatetime(tBPLDef.TimeChanged,3,,6) '= pSubmitObject.Timestamp {
				Set pProvider.error = "timestamp"
				Quit
			}
		}

		// pSubmitObject is a generic ZEN.proxyObject that should hold all the information!
		// The pSubmitObject corresponds to a Ens.BPL.UI.Diagram object
		// ShapeIndex is index of Shape # to Shape
		Kill tShapeIndex
		Set tSC = ..%CreateDiagramFromProxy(pSubmitObject,.tDiagram,.tShapeIndex)
		If $$$ISERR(tSC) Quit
		
		If ..IsSourceControlReadOnly(..GetInternalName()) {
			Set pProvider.error = $$$Text("Your source control framework has marked this document as read only, so you will not be able to modify this document.")
			Quit
		} Else {
			Set tDiagram.ReadOnly = tReadOnly
		}
		
		// convert BPL diagram to BPL DOM
		Set tXDataName = "BPL"
		Set tBPLStream = ##class(%GlobalCharacterStream).%New()
		Set tConverted = 0

		Set tAnnotation = tDiagram.Annotation
		If tAnnotation '= "" {
			// Ensure that all newlines are converted to CR/LF.
			Set tAnnotation = $replace(tAnnotation, $c(13,10), $c(10))
			Set tAnnotation = $replace(tAnnotation, $c(10), $c(13,10))
		}

		If ('tDiagram.HasErrors) {
			// if no logical errors in diagram, try to convert to BPL
			Set tSC = tDiagram.ConvertToBPL(tBPLStream,.tConverted)
			If $$$ISERR(tSC) {
				Set tDiagramSC = tSC
			}
		}

		If (tDiagram.HasErrors || $$$ISERR(tSC)) {
			// if we were unable to generate BPL, save an Error block instead
			If ('tConverted) {
				// save the Diagram XML instead of the BPL
				Set tXDataName = "BPLError"
				Do tBPLStream.Rewind()
				Do tDiagram.Serialize(tBPLStream)
			}
		}

		// now save the serialized BPL DOM into the class' xdata
		Do tBPLStream.Rewind()

		Set tSC = ..%SaveBPLClass(..bpId,tBPLStream, tXDataName, tAnnotation, .tTimestamp, pSubmitObject.ContextSuperClass)
		If $$$ISERR(tSC) Quit

		// Force JSON provider to send updated model to the client
		Do pProvider.%SetContentModified()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}

	If $$$ISERR(tDiagramSC) {
		Set tSC = tDiagramSC
	}

	Quit tSC
}

/// Convert data in the given proxy object into a Diagram.
ClassMethod %CreateDiagramFromProxy(pObject As %ZEN.proxyObject, Output pDiagram As Ens.BPL.UI.Diagram, ByRef pShapeIndex As Ens.BPL.UI.Shape) As %Status
{
	Set tSC = $$$OK
	Try {
		Set pDiagram = ##class(Ens.BPL.UI.Diagram).%New()
		Set pDiagram.Name = pObject.Name
		Set pDiagram.HasErrors = pObject.HasErrors
		Set pDiagram.Width = pObject.Width
		Set pDiagram.Height = pObject.Height
		Set pDiagram.Annotation = pObject.Annotation
		Set pDiagram.Component = pObject.Component
		Set pDiagram.Layout = pObject.Layout
		Set pDiagram.Version = pObject.Version
		Set pDiagram.Language = pObject.Language
		Set pDiagram.ContextSuperClass = pObject.ContextSuperClass
		Set pDiagram.Includes = pObject.Includes
		Set pDiagram.Request = pObject.Request
		Set pDiagram.Response = pObject.Response
		Set pDiagram.PyFromImport = pObject.PyFromImport

		// context properties
		If $IsObject(pObject.Context) {
			Set pDiagram.Context = ##class(Ens.BPL.Context).%New()

			If $IsObject(pObject.Context.Properties) {
				For n = 1:1:pObject.Context.Properties.Count() {
					Set tProp = pObject.Context.Properties.GetAt(n)
					If $IsObject(tProp) {
						Set tNewProp = ##class(Ens.BPL.Property).%New()
						Set tNewProp.Name = tProp.Name
						Set tNewProp.Type = tProp.Type
						Set tNewProp.Collection = tProp.Collection
						Set tNewProp.Annotation = tProp.Annotation
						Set tNewProp.InitialExpression = tProp.InitialExpression
						Set tNewProp.Instantiate = tProp.Instantiate

						// parameters
						For p = 1:1:tProp.Parameters.Count() {
							Set tParm = tProp.Parameters.GetAt(p)
							Do:tParm.Name'="" tNewProp.Parameters.SetAt(tParm.Value,tParm.Name)
						}
						Do pDiagram.Context.Properties.Insert(tNewProp)
					}
				}
			}
		}

		// shapes
		Set tSC = ..%CreateShapeListFromProxy(.pShapeIndex,pObject.ShapeList,.tParentList)
		If $$$ISERR(tSC) Quit

		// walk down set of shapes organized by parent and reconstruct graph 
		// Note that if the diagram has errors, all shapes must be present in pDiagram.ShapeList
		// and must have pointers to their parent shapes to ensure that all shapes are serialised into the BPLError XData.
		Set p = $O(tParentList(""))
		While (p'="") {
			If (p=-1E14)||pDiagram.HasErrors {
				Set tList = pDiagram.ShapeList
			}
			Else {
				Set tList = pShapeIndex(p).Children
			}

			Set k = $O(tParentList(p,""))
			While (k'="") {
				Do tList.Insert(pShapeIndex(k))
				If pDiagram.HasErrors && (p'=-1E14) {
					Set pShapeIndex(k).Parent = pShapeIndex(p)
				}
				Set k = $O(tParentList(p,k))
			}
			Set p = $O(tParentList(p))
		}

		// connections
		If $IsObject(pObject.Connectors) {
			For n = 1:1:pObject.Connectors.Count() {
				Set tConnector = pObject.Connectors.GetAt(n)
				If $IsObject(tConnector) {
					If ((tConnector.ToShape'="")&&(tConnector.FromShape'="")) {
						Set tToShape = $G(pShapeIndex(tConnector.ToShape))
						Set tFromShape = $G(pShapeIndex(tConnector.FromShape))
						If ($IsObject(tFromShape)&&$IsObject(tToShape)) {
							If (tConnector.ConnectType = "goto") {
								Do tFromShape.AddGotoConnect(tToShape)
							}
							Else {
								Do tFromShape.ConnectTo(tToShape,tConnector.Name,tConnector.Condition,tConnector.Disabled,tConnector.ConnectType,tConnector.LanguageOverride)
							}
						}
					}
				}
			}
		}

		Set tStream = ##class(%GlobalCharacterStream).%New()
		Do pDiagram.Serialize(tStream)
		Do tStream.Rewind()
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Convert an array of proxy objects into a local array of shapes (pShapeIndex) and an index by parent (pParentIndex).
ClassMethod %CreateShapeListFromProxy(ByRef pShapeIndex As Ens.BPL.UI.Shape, pObjectList As %ListOfObjects, Output pParentIndex As Ens.BPL.UI.Shape) As %Status
{
	Set tSC = $$$OK
	Try {
		If $IsObject(pObjectList) {
			For n = 1:1:pObjectList.Count() {
				Set tObject = pObjectList.GetAt(n)

				If $IsObject(tObject) {
					Set tShape = ##class(Ens.BPL.UI.Shape).%New(tObject.Type)
					Set tShape.Index = tObject.Index
					Set:tShape.Index'="" pShapeIndex(tShape.Index) = tShape
					
					If (tObject.ParentShape'="") {
						Set:tShape.Index'="" pParentIndex(tObject.ParentShape,tShape.Index) = tShape
					}
					Else {
						Set:tShape.Index'="" pParentIndex(-1E14,tShape.Index) = tShape
					}

					Set tShape.Name = tObject.Name
					Set tShape.Disabled = tObject.Disabled
					Set tShape.Annotation = tObject.Annotation
					Set tShape.xPos = tObject.xPos
					Set tShape.yPos = tObject.yPos

					// request
					If $IsObject(tObject.Request) {
						Set tSC = ..%CreateReqRespFromProxy(1,tObject.Request,.tRequest)
						If $$$ISERR(tSC) Quit
						Set tShape.Request = tRequest
					}
					ElseIf (tObject.Type="call") {
						// request is required
						Set tShape.Request = ##class(Ens.BPL.Request).%New()
					}

					// response
					If $IsObject(tObject.Response) {
						Set tSC = ..%CreateReqRespFromProxy(0,tObject.Response,.tResponse)
						If $$$ISERR(tSC) Quit
						Set tShape.Response = tResponse
					}

					// property bag
					Kill tProps
					Do tObject.PropertyBag.%CopyToArray(.tProps)
					Set tName = $O(tProps(""))
					While (tName'="") {
						Do tShape.SetProperty(tName,$G(tProps(tName)))
						Set tName = $O(tProps(tName))
					}

					// parameters
					Kill tParms
					Do tObject.Parameters.%CopyToArray(.tParms)
					Set tName = $O(tParms(""))
					While (tName'="") {
						Do tShape.Parameters.SetAt($G(tParms(tName)),tName)
						Set tName = $O(tParms(tName))
					}

					// code
					Do tShape.Code.Write(tObject.Code)
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Convert a proxy object into a request or response.
ClassMethod %CreateReqRespFromProxy(pIsRequest As %Boolean, pObject As %ZEN.proxyObject, Output pOutput As Ens.BPL.Message) As %Status
{
	Set tSC = $$$OK
	Try {
		If (pIsRequest) {
			Set pOutput = ##class(Ens.BPL.Request).%New()
		}
		ElseIf (pObject.Type = "") {
			Set pOutput = ""
			Quit
		}
		Else {
			Set pOutput = ##class(Ens.BPL.Response).%New()
		}

		Set pOutput.Type = pObject.Type
		If $IsObject(pObject.Activities) {
			If '$IsObject(pOutput.Activities) {
				Set pOutput.Activities = ##class(Ens.BPL.PropertyList).%New()
			}
			
			If pObject.Activities.%IsA("%ZEN.proxyObject") {
				Do pObject.Activities.%CopyToArray(.tActivities)
				Set tKey = ""
				For {
					Set tKey = $order(tActivities(tKey),1,tActivity)
					Quit:(tKey = "")
					If $IsObject($get(tActivity)) {
						Set tAssign = ##class(Ens.BPL.Assign).%New()
						Set tAssign.Property = tActivity.Property
						Set tAssign.Value = tActivity.Value
						Set tAssign.Action = tActivity.Action
						Set tAssign.LanguageOverride = tActivity.LanguageOverride
						Set tAssign.Key = tActivity.Key
						Set tAssign.Annotation = tActivity.Annotation
						Do pOutput.Activities.Insert(tAssign)
					}
				}
			}
			Else {
				For n=1:1:pObject.Activities.Count() {
					Set tActivity = pObject.Activities.GetAt(n)
					#; assume this is an assign
					Set tAssign = ##class(Ens.BPL.Assign).%New()
					Set tAssign.Property = tActivity.Property
					Set tAssign.Value = tActivity.Value
					Set tAssign.Action = tActivity.Action
					Set tAssign.LanguageOverride = tActivity.LanguageOverride
					Set tAssign.Key = tActivity.Key
					Set tAssign.Annotation = tActivity.Annotation
					Do pOutput.Activities.Insert(tAssign)
				}
			}
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Does the actual work of saving BPL stream to a BPL class.
ClassMethod %SaveBPLClass(pClassName As %String, pBPLStream As %Stream.Object, pXDataName As %String, pAnnotation As %String, Output pTimestamp As %TimeStamp = "", pContextSuperClass As %String = "") As %Status [ Private ]
{
	Set tSC = $$$OK
	Try {
		#; open the class definition
		If ##class(%Dictionary.ClassDefinition).%ExistsId(pClassName) {
			Set tSC = ..LoadClassDefinition(pClassName,.tClassDefinition,,1)
			If $$$ISERR(tSC) Quit
			If ($IsObject(tClassDefinition)) {
				If '##class(EnsPortal.Utils).IsSubclass(pClassName, "Ens.BusinessProcessBPL") {
					Set tSC = $$$ERROR($$$NotAnInstanceError, "Ens.BusinessProcessBPL")
					Quit
				}
				#; delete the old XDATA block named BPL
				Set tIndex = tClassDefinition.XDatas.FindObjectId(pClassName_"||BPL")
				If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)

				#; delete the old XDATA block named BPLError (if any)
				Set tIndex = tClassDefinition.XDatas.FindObjectId(pClassName_"||BPLError")
				If tIndex'="" Do tClassDefinition.XDatas.RemoveAt(tIndex)
			}
		}
		Else {
			#; create a new class
			Set tClassDefinition = ##class(%Dictionary.ClassDefinition).%New()
			Set tClassDefinition.Name = pClassName
			Set tClassDefinition.Super = "Ens.BusinessProcessBPL"
			Set tClassDefinition.ClassVersion = $$$CLASSDEFINITIONVERSION
		}

		Set tClassDefinition.Description = pAnnotation
		If pContextSuperClass '= "" {
			Set tClassDefinition.DependsOn = pContextSuperClass
		}
		Else {
			Do tClassDefinition.DependsOnReset()
		}

		#; define a new XDATA block named (BPL or BPLError)
		Set tXDataDefinition = ##class(%Dictionary.XDataDefinition).%New()

		If (pXDataName = "BPLError") {
			#; add a comment to the Error block
			Set tXDataDefinition.Description = "This BPLError block indicates that a BPL Diagram " _ $C(13,10) _ 
			"containing errors was saved." _ $C(13,10) _
			"To correct this class:" _ $C(13,10) _
			"* Open it using the Studio BPL Editor," _ $C(13,10) _
			"* Correct the errors, and," _ $C(13,10) _
			"* Save the diagram." _ $C(13,10) _
			"Do not edit the contents of the BPLError block"  _ $C(13,10) _
			"or you may lose your diagram."
		} Else {
			Set tXDataDefinition.Description = "BPL Definition"
			Set tXDataDefinition.XMLNamespace = "http://www.intersystems.com/bpl"
		}

		Set tXDataDefinition.Name = pXDataName
		Set tXDataDefinition.parent = tClassDefinition

		Set tSC = tXDataDefinition.Data.CopyFrom(pBPLStream)
		If $$$ISERR(tSC) Quit

		Set tSC = tClassDefinition.%Save()
		If $$$ISERR(tSC) Quit
		Set pTimestamp = $zdatetime(tClassDefinition.TimeChanged,3,,6)
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Launch the data transform finder dialog.
ClientMethod findTransform(prop) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var shapeModel = this._currShape ? this._currShape.model : null;
	this._currProperty =  { "zenId": prop, "model": shapeModel, "propPath": [ 'PropertyBag', 'Class' ] };

	var parms = {
		"MODE": 'dtlplus'
	};
	var url = zenLink('%ZEN.Dialog.finderDialog.zen',this.studioMode);
	zenLaunchPopupWindow(url,this.addPopupSuffix('BPFindTransform'),'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// Launch the select context super dialog.
ClientMethod selectContextClass() [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var parms = {
		MODE : 'classes',
		SUB : 'Ens.BP.Context'
	};
	var url = zenLink('%ZEN.Dialog.finderDialog.zen',this.studioMode);
	zenLaunchPopupWindow(url,this.addPopupSuffix('BPContextSuperClass'),'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// Launch the finder for request or response messages.
/// <var>which</var> should be 'Request' or 'Response'.
ClientMethod selectMessageClass(which, prop, isDiagramProperty) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var model = isDiagramProperty ? this.getBPLObject() : (this._currShape ? this._currShape.model : null);
	var propPath = isDiagramProperty ? [ which ] : [ which, 'Type' ];
	this._currProperty =  { "zenId": prop, "model": model, "propPath": propPath };
	var parms = {
		"MODE": which.toLowerCase()
	};
	var url = zenLink('%ZEN.Dialog.finderDialog.zen',this.studioMode)
	zenLaunchPopupWindow(url,this.addPopupSuffix('BP'+which+'Class'),'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// Launch the context property dialog.
ClientMethod editContextProperty(idx) [ Language = javascript ]
{
	if ((idx == -1) && (this.readOnly || !this.checkEdit())) { return false; }
	var model = this.getBPLObject();
	var prop = null;
	if (idx >= 0 && model && model.Context && model.Context.Properties) {
		prop = model.Context.Properties[idx];
	}

	// glue data type parameters together
	var type = prop ? prop.Type : '';
	if (prop && prop.Parameters) {
		var list = [];
		for (var p = 0; p < prop.Parameters.length; p++) {
			var parm = prop.Parameters[p];
			list.push(parm.Name + '=' + (!isNaN(parseFloat(parm.Value)) ? parm.Value:'"'+parm.Value+'"')); 
		}
		if (list.length > 0) type += '(' + list.join(',') + ')';
	}
	
	var parms = {
		INDEX:idx,
		PROPERTY:prop ? prop.Name : '',
		TYPE:type,
		DESC:prop ? prop.Annotation : '',
		COLLECTION:prop ? prop.Collection : '',
		INST:prop ? (prop.Instantiate?1:0) : 0,
		DEFAULT:prop ? prop.InitialExpression : '',
		READONLY: (this.readOnly || !this.canEdit) ? 1 : 0
	};
	if (this.studioMode) parms.STUDIO = 1;
	var url = zenLink('EnsPortal.Dialog.BusinessProcessContext.zen',this.studioMode);
	zenLaunchPopupWindow(url,this.addPopupSuffix('BPContext'),'status,scrollbars,resizable=yes,width=500,height=600',parms);
}

/// Set the values for a context property.
ClientMethod setContextProperty(idx, propName, propType, propDefault, propDesc, propCollection, propInstantiate) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var model = this.getBPLObject();
	if (model && model.Context) {
		this.startUndoAction();
		if (!model.Context.Properties) model.Context.Properties = [];
		var prop;
		if (idx < 0) {
			prop = {};
			model.Context.Properties.push(prop);
		} else {
			prop = model.Context.Properties[idx];
		}
		var type = propType.toString();
		var parms = [];

		// parse parameters out from type: e.g. %Integer ( MINVAL = 1, MAXVAL = 50 )
		var t = type.split('(');
		type = t[0].replace(/^\s+/,'').replace(/\s+$/,''); // knock off leading and trailing whitespace
		// get parms, remove ()
		t.splice(0,1); // knock off first piece
		t = t.join('('); // put the rest back together
		t = t.replace(/\)\s*$/,''); // knock off trailing paren and whitespace
		if (t != '') {
			var pt = t.split(',');
			for (var pn = 0; pn < pt.length; pn++) {
				var px = pt[pn].split('=');
				var name = px[0].replace(/^\s+/,'').replace(/\s+$/,'');
				var val = px[1].replace(/^\s+/,'').replace(/\s+$/,'');
				val = (val.charAt(0)=='"') ? val.substr(1,val.length-2) : val;
				parms.push({ Name: name, Value: val });
			}
		}

		prop.Name = propName;
		prop.Type = type;
		prop.InitialExpression = propDefault;
		prop.Annotation = propDesc;
		prop.Collection = propCollection;
		prop.Instantiate = propInstantiate;
		prop.Parameters = parms;

		this.renderContextTable();
		this.endUndoAction();
	}
}

/// Delete a context property.
ClientMethod deleteContextProperty(idx) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var model = this.getBPLObject();
	var prop = null;
	if (idx >= 0 && model && model.Context && model.Context.Properties) {
		prop = model.Context.Properties[idx];
		if (!confirm($$$FormatText($$$Text('Do you wish to delete the property %1?'),prop.Name))) {
			return;
		}
		var tabNum = 2;
		this.startUndoAction(tabNum);
		model.Context.Properties.splice(idx,1);
		this.renderContextTable();
		this.endUndoAction();
	}
}

/// Launch the action property dialog.
ClientMethod editAction(which, idx) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var shapeModel = this._currShape ? this._currShape.model : null;
	var action = null;
	if (idx >= 0 && shapeModel && shapeModel[which] && shapeModel[which].Activities) {
		action = shapeModel[which].Activities[idx];
	}
	
	if ((which != '') && ((!shapeModel[which]) || (shapeModel[which].Type == ''))) {
		if (which == 'Request') {
			alert($$$Text('You must specify a request message class in order to add or edit request actions.'));
			return;
		}
		if (which == 'Response') {
			alert($$$Text('You must specify a response message class in order to add or edit response actions.'));
			return;
		}
	}
	var model = this.getBPLObject();
	var callRequest = '';
	var callResponse = '';

	// get list of context properties
	var list = this.getContextProperties(true);
	var typeList = this.getContextPropertiesTypes(true);

	if (shapeModel && shapeModel.Response && shapeModel.Response.Type) {
		callResponse = shapeModel.Response.Type;
	}
	if (shapeModel && shapeModel.Request && shapeModel.Request.Type) {
		callRequest = shapeModel.Request.Type;
	}

	var parms = {
		WHICH:which,
		INDEX:idx,
		RESPONSE:model.Response,
		REQUEST:model.Request,
		CALLRESPONSE:callResponse,
		CALLREQUEST:callRequest,
		CONTEXTSUPER:model.ContextSuperClass,
		CONTEXTLIST:list,
		CONTEXTTYPELIST: typeList,
	};
	if (this.studioMode) parms.STUDIO = 1;
	var url = zenLink('EnsPortal.Dialog.BusinessProcessAction.zen',this.studioMode);
	zenLaunchPopupWindow(url,this.addPopupSuffix('BPAction'),'status,scrollbars,resizable=yes,width=600,height=600',parms);
}

/// Helper method to list the names of context properties.
ClientMethod getContextProperties(asCommaList) [ Language = javascript ]
{
	var propNames = [];
	var model = this.getBPLObject();
	if (model.Context && model.Context.Properties && model.Context.Properties.length > 0) {
		for (var p = 0; p < model.Context.Properties.length; p++) {
			var prop = model.Context.Properties[p];
			propNames.push(prop.Name);
		}
	}
	if (asCommaList) return propNames.join(',');
	return propNames;
}

/// Set the values for an action item.
ClientMethod setActionItem(which, idx, actionType, prop, value, key, annotation) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var shapeModel = this._currShape ? this._currShape.model : null;
	var action = null;
	if (shapeModel && shapeModel[which] && shapeModel[which].Activities) {
		this.startUndoAction();
		if (idx >= 0) {
			action = shapeModel[which].Activities[idx];
		}
		else {
			action = {};
			shapeModel[which].Activities.push(action);
		}
		
		action._type = 'activity';
		action.activityType = 'Assign';
		action.Action = actionType;
		action.Property = prop;
		action.Value = value;
		
		action.Key = key=='' ? '""' : key;
		action.Annotation = (annotation == null ? '' : annotation);
		this.renderActionList(which,shapeModel);
		this.endUndoAction();
	}
}

ClientMethod getAction(which, actionIndex) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var shapeModel = this._currShape ? this._currShape.model : null;
	var action = null;
	if ((actionIndex >= 0) && shapeModel && shapeModel[which] && shapeModel[which].Activities) {
		action = shapeModel[which].Activities[actionIndex];
	}
	if (!action) action = { "Action": 'set', "Property": '', "Value": '', "LanguageOverride": '', "Key": '', "Annotation": '' };
	return action;
}

/// Delete an action in a req/resp list.
ClientMethod deleteAction(which, idx) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var shapeModel = this._currShape ? this._currShape.model : null;
	if (idx >= 0 && shapeModel && shapeModel[which] && shapeModel[which].Activities) {
		var action = shapeModel[which].Activities[idx];
		if (!confirm($$$Text('Do you wish to delete this action?'))) {
			return;
		}
		this.startUndoAction();
		shapeModel[which].Activities.splice(idx,1);
		this.renderActionList(which,shapeModel);
		this.endUndoAction();
	}
}

/// Launch the XSLT parameter dialog.
ClientMethod editXSLTParm(idx) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var shapeModel = this._currShape ? this._currShape.model : null;
	var parm = null;
	var value = '';
	if (idx != '' && shapeModel && shapeModel.Parameters) value = shapeModel.Parameters[idx];

	var parms = {
		INDEX:idx,
		NAME:idx,
		VALUE:value
	};
	if (this.studioMode) parms.STUDIO = 1;
	var url = zenLink('EnsPortal.Dialog.BusinessProcessXSLTParm.zen',this.studioMode);
	zenLaunchPopupWindow(url,this.addPopupSuffix('BPXSLParm'),'status,scrollbars,resizable=yes,width=400,height=400',parms);
}

/// Set the values for an XSLT parameter.
ClientMethod setXSLTParm(idx, parm, value) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var shapeModel = this._currShape ? this._currShape.model : null;
	var newParm = null;

	this.startUndoAction();
	if (shapeModel && shapeModel.Parameters) {
		// remove old entry
		if (idx!='' && idx!=parm) delete shapeModel.Parameters[idx];
		if (parm != '') shapeModel.Parameters[parm] = value;
		this.renderXSLTList(shapeModel);
	}
	this.endUndoAction();
}

/// Delete an XSLT parameter.
ClientMethod deleteXSLTParm(idx) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var shapeModel = this._currShape ? this._currShape.model : null;
	if (idx != '' && shapeModel && shapeModel.Parameters) {
		if (!confirm($$$Text('Do you wish to delete this parameter?'))) {
			return;
		}
		this.startUndoAction();
		delete shapeDef.Parameters[idx];
		this.renderXSLTList(shapeModel);
		this.endUndoAction();
	}
}

/// Launch the property editor dialog.
ClientMethod editPropertyValue(name, type, languageOverride) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var value = zen(name).getValue();
	this._currProperty = name;
	var model = this.getBPLObject();

	// get list of context properties
	var list = this.getContextProperties(true);
	var typeList = this.getContextPropertiesTypes(true);

	// list of activity names
	var nameList = '';
	if (this._BPLDiagram && ((type == 'calls') || (type == 'labels'))) {
		var shapeType = type.substring(0,type.length-1);
		var shapeNames = this._BPLDiagram.listNames(shapeType);
		if (shapeNames.length > 0) nameList = shapeNames.join(',');
	}

	var callRequest = '';
	var callResponse = '';
	var shapeModel = this._currShape ? this._currShape.model : null;
	if (shapeModel) {
		if (shapeModel.Request && shapeModel.Request.Type) {
			callRequest = shapeModel.Request.Type;
		}
		if (shapeModel.Response && shapeModel.Response.Type) {
			callResponse = shapeModel.Response.Type;
		}
	}
	
	var parms = {
		PROPERTY:name,
		TYPE:type,
		LANG:languageOverride!=""?languageOverride:model.Language,
		RESPONSE:model.Response,
		REQUEST:model.Request,
		CALLRESPONSE:callResponse,
		CALLREQUEST:callRequest,
		CONTEXTSUPER:model.ContextSuperClass,
		CONTEXTLIST:list,
		CONTEXTTYPELIST: typeList,
		NAMES:nameList,
		VALUE: (type == 'code' ? '' : value) };
	if (this.studioMode) parms.STUDIO = 1;
	var width = (((type == 'code')||(name == 'callTarget')) ? 800 : 600);
	var height = (((type == 'code')||(name == 'callTarget')) ? 600 : 470);
	var url = zenLink('EnsPortal.Dialog.BusinessProcessValueEditor.zen',this.studioMode);
	zenLaunchPopupWindow(url,this.addPopupSuffix('BPValue'),'status,scrollbars,resizable=yes,width='+width+',height='+height,parms);
}

/// Launch rule finder.
ClientMethod findRule(prop) [ Language = javascript ]
{
	if (this.readOnly || !this.checkEdit()) { return false; }
	var shapeModel = this._currShape ? this._currShape.model : null;
	this._currProperty =  { "zenId": prop, "model": shapeModel, "propPath": [ 'PropertyBag', 'Rule' ] };
	var parms = { MODE: 'rules' };
	var url = zenLink('%ZEN.Dialog.finderDialog.zen',this.studioMode);
	zenLaunchPopupWindow(url,this.addPopupSuffix('BPFindRule'),'status,scrollbars,resizable=yes,width=800,height=600',parms);
}

/// Test if a code fragment contains valid ObjectScript code.
ClassMethod IsCodeValid(pCode As %String = "") As %Boolean [ ZenMethod ]
{
	Set tOK = 1
	Try {
		If (pCode="") Quit
		#dim status=##class(%Library.Routine).CheckSyntax(" set x=" _##class(Ens.VDoc.Utils).GetGetCode(pCode,"objectscript"))
		If $$$ISERR(status) Set tOK=0
	}
	Catch(ex) {
		If ($ZE["<SYNTAX>") {
			Set tOK = 0
		}
	}
	Quit tOK
}

/// Show documentation for given activity.
ClientMethod showActivityDoc(type) [ Language = javascript ]
{
	var win = window.open('/csp/docbook/DocBook.UI.Page.cls?KEY=EBPLR_'+type,'Docbook');
	try {
		win.focus();
	}
	catch(ex) {}
}

/// Change value of a BPL editor preference.
ClientMethod changePreference(pref, value) [ Language = javascript ]
{
	var svgWin = this.getSVGWindow();

	var jsValue = value;
	switch(pref) {
	case 'gridlines':
		this.prefGridlines = jsValue;
		this.setOption('gridlineStyle',jsValue);
		if (this._bplAPI) this._bplAPI.createGridLines();
		break;
	case 'autoArrange':
		jsValue = (jsValue ? true : false);
		this.prefAutoArrange = jsValue;
		this.setOption('autoArrange',jsValue);
		if (this._BPLDiagram) this._BPLDiagram.arrangeShapes();
		value = jsValue ? 1 : 0;
		break;
	case 'showAnnotations':
		this.prefShowAnnotations = jsValue;
		if (this._bplAPI) this._bplAPI.Options.toggleAnnotations(jsValue);
		value = jsValue ? 1 : 0;
		break;
	}

	var ok = zenPage.SetPreference(pref,value);
}

/// Toggle display of settings box.
ClientMethod toggleSettings() [ Language = javascript ]
{
	this.settingsExpanded = !this.settingsExpanded;
	var span = self.document.getElementById('spanArrow');
	if (span) span.innerHTML = this.settingsExpanded ? '&#187;' : '&#171';
	this.adjustSizes();
}

/// Set a value in the preference global.
ClassMethod SetPreference(pPref As %String, pValue As %String) As %Boolean [ ZenMethod ]
{
	Set tOK = 1
	Try {
		If (pPref'="") {
			Set ^EnsPortal.Settings($UserName,"BPL",pPref) = pValue
		}
	}
	Catch(ex) {
		Set tOK = 0
	}
	Quit tOK
}

/// Save XML content to the server for the print window to consume.
ClassMethod SaveXMLToServer(pXML As %String, pToken As %String) As %String [ Internal, ZenMethod ]
{
	Set tMsg = ""
	Set tSC = $$$OK
	Try {
		Kill ^IRIS.Temp.BPLPrint($namespace,pToken)
		If $IsObject(pXML) {
			Do pXML.Rewind()
			While ('pXML.AtEnd) {
				Set ^IRIS.Temp.BPLPrint($namespace,pToken,$I(n)) = pXML.Read(8000)
			}
		}
		Else {
			Set ^IRIS.Temp.BPLPrint($namespace,pToken,1) = pXML
		}
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	If $$$ISERR(tSC) {
		Set tMsg = $System.Status.GetErrorText(tSC)
	}
	Quit tMsg
}

ClassMethod GetCodeValidation(pBPL As %String = "") As %Boolean [ ZenMethod ]
{
	If pBPL = "" Quit 1
	
	Quit $get(^EnsPortal("DTLEditor","CodeValidation",$username,pBPL), 1)
}

ClassMethod SetCodeValidation(pBPL As %String = "", pNewValue As %Boolean = 1) As %Boolean [ ZenMethod ]
{
	If pBPL = "" Quit 1
	
	If pNewValue = 0 {
		Set ^EnsPortal("DTLEditor","CodeValidation",$username,pBPL) = pNewValue
	}
	Else {
		Kill ^EnsPortal("DTLEditor","CodeValidation",$username,pBPL)
	}
	Quit 1
}

/// Invoke the Testing Service.
ClientMethod toolTestingService() [ Internal, Language = javascript ]
{
	if (this.studioMode) { return; }
	// launch testing service
	var url = zenLink('EnsPortal.TestingService.zen',true);
	var testWin = window.open(url);
	try {
		testWin.focus();
	}
	catch(ex) {}
}

/// Render the SVG diagram in a print friendly fashion.
ClientMethod print() [ Internal, Language = javascript ]
{
	// IE doesn't have native SVG rendering at this time (i.e. IE8 and older)
	if (zenIsIE && !zenIsHTML5) {
		alert($$$Text('Your browser does not support native SVG graphics at this time.')+'\n'+$$$Text('Please try accessing the printable view using another browser.'));
		return;
	}
	var svgWin = this.getSVGWindow();
	var root = svgWin.document.getElementById("canvas");
	var xml = this.walkSVGDOM(root);

	// Save xml to server
	var token = Math.round(Math.random() * 100000000);
	var msg = zenPage.SaveXMLToServer(xml,token);
	if ('' != msg) {
		alert(msg);
		return;
	}
	var model = this.getBPLObject();
	var width = model.Width ? model.Width : '';
	var height = model.Height ? model.Height : '';

	// launch print window
	var url = 'EnsPortal.SVG.SVGPrint.zen?CSPSHARE=1&TOKEN=' + encodeURIComponent(token) + '&TITLE=' + encodeURIComponent(this.bpId) + '&WIDTH=' + encodeURIComponent(width) + '&HEIGHT=' + encodeURIComponent(height);
	var printWin = window.open(url,'',"width=800,height=600,menubar=yes,resizable=yes,scrollbars=yes");
	try {
		printWin.focus();
	}
	catch(ex) {}
}

/// Walk an SVG DOM and convert to XML.
ClientMethod walkSVGDOM(rootNode) [ Internal, Language = javascript ]
{
	var output = [];
	this.walkSVGNode(rootNode,output,0);
	return output.join('');
}

/// Walk a specific SVG node.
ClientMethod walkSVGNode(node, outputArray, level) [ Internal, Language = javascript ]
{
	var id = '';
	var visible = true;
	try {
		if (node.hasAttributes()) {
			id = node.getAttribute('id');
			if (node.getAttribute('visibility')=='hidden') {
				return;
			}
		}
	} catch(err) {}
	if (id == 'gridlines') return; // ignore grid group

	if (node.nodeName == '#text') {
		if (node.nodeValue!='') outputArray.push(zenEscapeXML(node.nodeValue));
		return;
	}

	outputArray.push('<' + node.nodeName);
	outputArray.push(' class="'+zenGet(node.getAttribute('class'))+'"');
	var style = zenGet(node.getAttribute('style'));
	if (style != '') outputArray.push(' style="'+zenEscapeXML(style)+'"');
	var fill = zenGet(node.getAttribute('fill'));
	if (fill != '') outputArray.push(' fill="'+zenEscapeXML(fill)+'"');

	var attribList = [];
	switch(node.nodeName) {
	case 'svg':
		attribList = [ 'transform', 'x', 'y', 'height', 'width'];
		break;
	case 'g':
		attribList = [ 'transform' ];
		break;
	case 'line':
		attribList = [ 'x1', 'x2', 'y1', 'y2' ];
		break;
	case 'rect':
		attribList = [ 'x', 'y', 'height', 'width', 'rx' ];
		break;
	case 'text':
		attribList = [ 'x', 'y', 'text-anchor' ];
		break;
	case 'circle':
		attribList = [ 'cx', 'cy', 'r' ];
		break;
	case 'path':
		attribList = [ 'id', 'd' ];
		break;
	case 'polyline':
	case 'polygon':
		attribList = [ 'points' ];
		break;
	case 'textPath':
		attribList = [ 'xlink:href', 'startOffset' ];
		break;
	case 'tspan':
		attribList = [ 'x', 'dy' ];
		break;
	}
	for (var i = 0; i<attribList.length; i++) {
		var val = node.getAttribute(attribList[i]);
		if ((val != '') && (val != null)) outputArray.push(' '+attribList[i]+'="'+val+'"');
	}

	// recurse
	if (node.childNodes.length>0) {
		outputArray[outputArray.length] = '>';
		for (var n = 0; n < node.childNodes.length; n++) {
			var child = (zenIsIE ? node.childNodes.item(n) : node.childNodes[n]);
			this.walkSVGNode(child,outputArray,level + 1);
		}
		outputArray.push('</'+node.nodeName+'>');
	}
	else {
		outputArray.push('/>');
	}
}

/// Open DTL editor in a new window.
ClientMethod showDTLEditor() [ Language = javascript ]
{
	if (this.studioMode) { return; }
	var dtl = zen('transformClass').getValue();
	if (dtl=='') {
		alert($$$Text('Please select a data transformation class.'));
		return;
	}
	dtl += '.DTL';
	var url = zenLink('EnsPortal.DTLEditor.zen');
	if (url.indexOf('?') < 0) { url += '?'; }
	else { url += '&'; }
	var win = window.open(url + 'DT='+encodeURIComponent(dtl));
	try {
		win.focus();
	}
	catch(ex) {}
}

/// Open Rule editor in a new window.
ClientMethod showRuleEditor() [ Language = javascript ]
{
	if (this.studioMode) { return; }
	var rule = zen('ruleRule').getValue();
	if (rule =='') {
		var parms = {RULE:''};
		zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.BusinessRuleWizard.zen'),this.addPopupSuffix('newRule'),'status,scrollbars,resizable=yes,left=100,top=100,width=700,height=700',parms);
	}
	else {
		if (rule.indexOf('.') == -1) {
			rule = this.bpId + '.' + rule; // append BPL name to unqualified rule name (HCR310)
		}
		var url = zenLink(zenPage.ruleEditorBaseURL);
		url += ((url.indexOf('?') < 0) ? '?' : '&');
		url += 'rule=' + encodeURIComponent(rule);
		var win = window.open(url);
		try {
			win.focus();
		}
		catch(ex) {}
	}
}

/// Called from request/response builder to get action list for current shape.
ClientMethod getCurrShape(which) [ Language = javascript ]
{
	return this._currShape;
}

/// Return the current name of the class/object being modified
ClientMethod getCurrentName() [ Language = javascript ]
{
	return zenPage.bpId;
}

ClientMethod getClientModel() [ Language = javascript ]
{
	return zen('bpl');
}

/// Request/Response (DTL) builder.
ClientMethod showBuilder(which) [ Language = javascript ]
{
	if (!this.checkEdit()) { return false; }
	var shapeModel = this._currShape ? this._currShape.model : null;
	var actionList = '';
	if (shapeModel && shapeModel[which] && shapeModel[which].Activities) {
		//action = shapeModel[which].Activities[idx];
	}

	if ((which == 'Request') && ((!shapeModel.Request) || (shapeModel.Request.Type == ''))) {
		alert($$$Text('You must specify a request message class in order to build call request actions.'));
		return;
	}
	if (which=='Response' && ((!shapeModel.Response) || (shapeModel.Response.Type == ''))) {
		alert($$$Text('You must specify a response message class in order to build call response actions.'));
		return;
	}

	var model = this.getBPLObject();
	var callRequest = '';
	var callResponse = '';

	// get list of context properties
	var list = this.getContextProperties(true);
	var typeList = this.getContextPropertiesTypes(true);

	if (shapeModel && shapeModel.Response && shapeModel.Response.Type) {
		callResponse = shapeModel.Response.Type;
	}
	if (shapeModel && shapeModel.Request && shapeModel.Request.Type) {
		callRequest = shapeModel.Request.Type;
	}

	var parms = {
		MINI:1,
		WHICH:which,
		ACTIONLIST:actionList,
		RESPONSE:model.Response,
		REQUEST:model.Request,
		LANG:model.Language,
		CALLRESPONSE:callResponse,
		CALLREQUEST:callRequest,
		CONTEXTSUPER:model.ContextSuperClass,
		CONTEXTLIST:list,
		CONTEXTTYPELIST:typeList
	};
	if (this.studioMode) parms.STUDIO = 1;
	var url = zenLink('EnsPortal.DTLEditor.zen',this.studioMode);
	// show DTL dialog
	zenLaunchPopupWindow(url,this.addPopupSuffix('BPBuilder'),'status,scrollbars,resizable=yes,width=1200,height=700',parms);
}

/// Return true if it is possible to undo an action
ClientMethod canUndo() [ Language = javascript ]
{
	return (!this.readOnly) && this.canEdit && !!(this._undoBuffer && (this._undoBuffer.length > 0))
}

/// Undo change.
ClientMethod undo() [ Language = javascript ]
{
	if (zenPage.studioMode) {
		if (undoAction()) {
			return; // input text fields are handled by undoAction()
		}
	}

	if (this.canUndo()) {
		var model = this._undoBuffer.pop();
		this._inUndo = true;
		if (model) this.replaceBPLObject(model);
		this._inUndo = false;
		this.updateIcons();
		if (this._undoBuffer.length == 0) {
			this.setModified(false);
		} else {
			this.setModified(true);
		}
	}
}

/// Clear the current undo buffer.
ClientMethod clearUndoBuffer() [ Language = javascript ]
{
	this._undoBuffer = [];
	this._undoLevel = 0;
}

/// Start an undo block. If the undo level is 0, save a copy of the current BPL model including
/// which items are selected.
ClientMethod startUndoAction(tabNum) [ Language = javascript ]
{
	if (!this._undoBuffer) this._undoBuffer = [];
	if (isNaN(this._undoLevel)) this._undoLevel = 0;
	if (this.diagramLoaded && (this._undoLevel == 0) && !this._inUndo) {
		if (!tabNum) tabNum = zen('propertyTabs').currTab;
		var bpl = this.getBPLObject();
		var copy = this.cloneObject(bpl);
		copy._selectedTab = tabNum;
		copy._selectedModels = [];
		copy._currentParent = null;
		if (this._BPLDiagram) {
			if (this._BPLDiagram.currentParent) copy._currentParent = this._BPLDiagram.currentParent;
			for (var i = 0; i < this._BPLDiagram.selectedItems.length; i++) {
				var item = this._BPLDiagram.selectedItems[i];
				if (item) {
					if (item.model.Type == 'connector') {
						var connIndex = bpl.Connectors.indexOf(item.model);
						if (connIndex) {
							var connClone = copy.Connectors[connIndex];
							if (connClone) copy._selectedModels.push(connClone);
						}
					}
					else {
						var modelClone = copy.ShapeList[item.model.Index];
						if (modelClone) copy._selectedModels.push(modelClone);
					}
				}
			}
		}
		this._undoBuffer.push(copy);
	}
	this._undoLevel++;
}

/// Close off an undo block. If the undoLevel is back to 0, update icons and mark the page as modified.
ClientMethod endUndoAction() [ Language = javascript ]
{
	if (this._undoLevel > 0) {
		this._undoLevel--;
	}
	if ((this._undoLevel == 0) && this.diagramLoaded && !this._inUndo) {
		this.setModified(true);
		this.updateIcons();
	}
}

/// Create a clone of an object supplied in <var>obj</var>.
/// If <var>noSVG</var> is specified, any properties with an _ other
/// than _type, _class and _className will not be cloned.
ClientMethod cloneObject(obj, clone, noSVG) [ Language = javascript ]
{
	var clone = clone ? clone : {};
	for (var i in obj) {
		if ((i == '_parent')||(i == '_index')) {
			// skip back pointers
		}
		else if (noSVG && (i.substring(0,1) == '_') && (i != '_type') && (i != '_class') && (i != '_className')) {
			// skip SVG shapes
		}
		else if (null == obj[i]) {
			clone[i] = null;
		}
		else if (typeof obj[i] === 'object') {
			clone[i] = (obj[i].constructor === Array) ? []: {};
			this.cloneObject(obj[i],clone[i], noSVG);
		}
		else {
			clone[i] = obj[i];
		}
	}
	return clone;
}

/// Method to produce and save the XML expected by Studio.
ClientMethod studioSave() [ Language = javascript ]
{
	var useDOMSave = !!this._isIE10;
	var bpl = this.getBPLObject();
	var fullXML;
	if (useDOMSave) {
		var diagram = document.createElement('diagram');
		fullXML = diagram;
		var children = [];
		var booleanProps = { "HasErrors": true, "ShowAnnotation": true };
		var propList = [ 'Name', 'HasErrors', 'Language', 'ContextSuperClass', 'Layout', 'Version', 'Includes', 'Request', 'Response', 'Width', 'Height', 'ShowAnnotation' ];
		for (var i = 0; i < propList.length; i++) {
			var propName = propList[i];
			var propValue = booleanProps[propName] ? (bpl[propName] ? '1' : '0') : bpl[propName];
			diagram.setAttribute(propName,propValue);
		}
		if (bpl.Component) diagram.setAttribute('Component','1');

		if (bpl.Annotation.toString() != '') {
			var annotation = document.createElement('annotation');
			var annotationText = document.createTextNode(bpl.Annotation);
			annotation.appendChild(annotationText);
			children.push(annotation);
		}

		if (bpl.PyFromImport.toString() != '') {
			var pyFromImport = document.createElement('pyFromImport');
			var pyFromImportText = document.createTextNode(bpl.PyFromImport);
			pyFromImport.appendChild(pyFromImportText);
			children.push(pyFromImport);
		}

		if (bpl.Context && bpl.Context.Properties && (bpl.Context.Properties.length > 0)) {
			var context = document.createElement('context');
			var propNames = [ 'Name', 'Type', 'InitialExpression', 'Collection', 'Instantiate'];
			for (var i = 0; i < bpl.Context.Properties.length; i++) {
				var propEl = document.createElement('property');
				var prop = bpl.Context.Properties[i];				
				for (var j = 0; j < propNames.length; j++) {
					var currName = propNames[j];
					if (prop[currName].toString() != '') propEl.setAttribute(currName.toLowerCase(), prop[currName]);
				}

				if (prop.Annotation.toString() != '') {
					var propAnnotation = document.createElement('annotation');
					var propAnnotationText = document.createTextNode(prop.Annotation);
					propAnnotation.appendChild(propAnnotationText);
					propEl.appendChild(propAnnotation);
				}
				if (prop.Parameters && (prop.Parameters.length > 0)) {
					var parms = document.createElement('parameters');
					for (var k = 0; k < prop.Parameters.length; k++) {
						var parmEl = document.createElement('parameter');
						var parm = prop.Parameters[k];
						parmEl.setAttribute('name',parm.Name);
						parmEl.setAttribute('value',parm.Value);
						parms.appendChild(parmEl);
					}
					propEl.appendChild(parms);
				}
				context.appendChild(propEl);
			}
			children.push(context);
		}

		var shapeProps = [ { "name": "Name", "property": "Name" }, { "name": "_Type", "property": "Type" }, { "name": "_index", "property": "Index" },
			{ "name": "xPos", "property": "xPos" }, { "name": "yPos", "property": "yPos" }, { "name": "parentShape", "property": function(model) {return (model && model.ParentShape ? model.ParentShape : ''); } } ];
		for (var i = 0; i < bpl.ShapeList.length; i++) {
			var shapeModel = bpl.ShapeList[i];
			if (shapeModel) {
				var shapeEl = document.createElement('shape');
				for (var j = 0; j < shapeProps.length; j++) {
					var propInfo = shapeProps[j];
					var propValue = (typeof propInfo.property == 'function' ? propInfo.property(shapeModel) : shapeModel[propInfo.property]);
					shapeEl.setAttribute(propInfo.name,propValue);
				}
				if (shapeModel.Disabled) shapeEl.setAttribute('Disabled','true');
				for (var prop in shapeModel.PropertyBag) {
					if (prop != '__cycle') shapeEl.setAttribute(prop,shapeModel.PropertyBag[prop]);
				}
				if (shapeModel.Annotation != '') {
					var shapeAnnotation = document.createElement('annotation');
					var shapeAnnotationText = document.createTextNode(shapeModel.Annotation);
					shapeAnnotation.appendChild(shapeAnnotationText);
					shapeEl.appendChild(shapeAnnotation);
				}
				if (shapeModel.Type == 'xslt') {
					var parmsEl = document.createElement('parameters');
					var xsltHasParms = false;
					for (var parm in shapeModel.Parameters) {
						var parmEl = document.createElement('parameter');
						parmEl.setAttribute('name',parm);
						parmEl.setAttribute('value',shapeModel.Parameters[parm]);
						parmsEl.appendChild(parmEl);
						xsltHasParms = true;
					}
					if (xsltHasParms) shapeEl.appendChild(parmsEl);
				}
				if (shapeModel.Type == 'call') {
					var actions = [ 'Request', 'Response' ];
					for (var j = 0; j < actions.length; j++) {
						var which = actions[j];
						if (shapeModel[which] && (shapeModel[which].Type != '')) {
							var tagName = which.toLowerCase();
							var callEl = document.createElement(tagName);
							callEl.setAttribute('type',shapeModel[which].Type);
							for (var k = 0; k < shapeModel[which].Activities.length; k++) {
								var activity = shapeModel[which].Activities[k];
								if (activity) {
									var activityEl = document.createElement('assign');
									activityEl.setAttribute('property',activity.Property);
									activityEl.setAttribute('value',activity.Value);
									activityEl.setAttribute('languageOverride',activity.LanguageOverride);
									activityEl.setAttribute('action',activity.Action);
									activityEl.setAttribute('key',activity.Key);
									callEl.appendChild(activityEl);
								}
							}
							shapeEl.appendChild(callEl);
						}
					}
				}
				if ((shapeModel.Type == 'code') || (shapeModel.Type == 'sql')) {
					var codeEl = document.createElement('code');
					var codeContent = document.createTextNode(shapeModel.Code);
					if (shapeModel.Type == 'code') {
						codeEl.setAttribute('languageOverride',shapeModel.PropertyBag.LanguageOverride);
					}
					codeEl.appendChild(codeContent);
					shapeEl.appendChild(codeEl);
				}
				children.push(shapeEl);
			}
		}

		for (var i = 0; i < bpl.Connectors.length; i++) {
			var conn = bpl.Connectors[i];
			if (conn && (conn.ConnectType != 'goto')) {
				var connEl = document.createElement('connection');
				connEl.setAttribute('Name',conn.Name);
				connEl.setAttribute('from',conn.FromShape);
				connEl.setAttribute('to',conn.ToShape);
				switch (conn.ConnectType) {
					case 'case':
						connEl.setAttribute('Condition',conn.Condition);
						connEl.setAttribute('LanguageOverride',conn.LanguageOverride);
					case 'branch':
					case 'thread':
						connEl.setAttribute('ConnectType',conn.ConnectType);
						break;
				}
				if (conn.Disabled) connEl.setAttribute('Disabled','true');
				children.push(connEl);
			}
		}

		for (var i = 0; i < children.length; i++) {
			var child = children[i];
			var newLine = document.createTextNode('\n');
			diagram.appendChild(newLine);
			diagram.appendChild(child);
		}
	}
	else {
		var xml = [];
		var hdr = '<diagram Name="' + zenEscapeXML(bpl.Name) +
					'" HasErrors="' + (bpl.HasErrors ? '1' : '0') +
					'" Language="' + zenEscapeXML(bpl.Language) +
					'" ContextSuperClass="' + zenEscapeXML(bpl.ContextSuperClass) +
					'" Layout="' + zenEscapeXML(bpl.Layout) +
					'" Version="' + zenEscapeXML(bpl.Version) +
					'" Includes="' + zenEscapeXML(bpl.Includes) +
					'" Request="' + zenEscapeXML(bpl.Request) +
					'" Response="' + zenEscapeXML(bpl.Response) +
					'" Width="' + zenEscapeXML(bpl.Width) +
					'" Height="' + zenEscapeXML(bpl.Height) +
					'" ShowAnnotation="' + (bpl.ShowAnnotation ? '1' : '0') + '"';
		if (bpl.Component) hdr += ' Component="1"';

		hdr += '>';
		xml.push(hdr);
		
		if (bpl.Annotation.toString() != '') xml.push('<annotation>' + zenEscapeXML(bpl.Annotation) + '</annotation>');

		if (bpl.PyFromImport.toString() !='') xml.push('<pyFromImport>' + zenEscapeXML(bpl.PyFromImport) + '</pyFromImport>');
		
		if (bpl.Context && bpl.Context.Properties && (bpl.Context.Properties.length > 0)) {
			xml.push('<context>');
			var propNames = [ 'Name', 'Type', 'InitialExpression', 'Collection', 'Instantiate'];
			for (var i = 0; i < bpl.Context.Properties.length; i++) {
				var prop = bpl.Context.Properties[i];
				var propXML = '<property ';
				for (var j = 0; j < propNames.length; j++) {
					var currName = propNames[j];
					if (prop[currName].toString() != '') propXML += currName.toLowerCase() + '="' + zenEscapeXML(prop[currName]) + '" ';
				}
				propXML += '>';
				xml.push(propXML);
				if (prop.Annotation.toString() != '') {
					xml.push('<annotation>' + zenEscapeXML(prop.Annotation) + '</annotation>');
				}
				if (prop.Parameters.length > 0) {
					xml.push('<parameters>');
					for (var k = 0; k < prop.Parameters.length; k++) {
						var parm = prop.Parameters[k];
						xml.push('<parameter name="' + zenEscapeXML(parm.Name) + '" value="'+ zenEscapeXML(parm.Value) + '"/>');
					}
					xml.push('</parameters>');
				}
				xml.push('</property>');
			}
			xml.push('</context>');
		}
		
		for (var i = 0; i < bpl.ShapeList.length; i++) {
			var shapeModel = bpl.ShapeList[i];
			if (shapeModel) {
				var shapeXML = '<shape ' +
									'Name="' + zenEscapeXML(shapeModel.Name) + '" ' +
									'_Type="' + zenEscapeXML(shapeModel.Type) + '" ' +
									'_index="' + zenEscapeXML(shapeModel.Index) + '" ' +
									(shapeModel.Disabled ? 'Disabled="true" ': '') +
									'xPos="' + zenEscapeXML(shapeModel.xPos) + '" ' +
									'yPos="' + zenEscapeXML(shapeModel.yPos) + '" ' +
									'parentShape="' + (shapeModel.ParentShape ? zenEscapeXML(shapeModel.ParentShape) : "") + '" ';
				// expecting LanguageOverride to be output here
				for (var prop in shapeModel.PropertyBag) {
					if (prop != '__cycle') shapeXML += prop + '="' + zenEscapeXML(shapeModel.PropertyBag[prop]) + '" ';
				}
				shapeXML += '>';
				xml.push(shapeXML);
				if (shapeModel.Annotation.toString() != '') xml.push('<annotation>' + zenEscapeXML(shapeModel.Annotation) + '</annotation>');
				if (shapeModel.Type == 'xslt') {
					var parmXML = '';
					var parmCount = 0;
					for (var parm in shapeModel.Parameters) {
						parmCount++;
						if (parmCount > 1) parmXML += '\n';
						parmXML += '<parameter name="' + zenEscapeXML(parm) + '" value="' + zenEscapeXML(shapeModel.Parameters[parm]) + '" />';
					}
					if (parmXML != '') {
						xml.push('<parameters>');
						xml.push(parmXML);
						xml.push('</parameters>');
					}
				}
				if (shapeModel.Type == 'call') {
					var actions = [ 'Request', 'Response' ];
					for (var j = 0; j < actions.length; j++) {
						var which = actions[j];
						if (shapeModel[which] && (shapeModel[which].Type != '')) {
							var tagName = which.toLowerCase();
							xml.push('<' + tagName + ' type="' + shapeModel[which].Type + '">');
							for (var k = 0; k < shapeModel[which].Activities.length; k++) {
								var activity = shapeModel[which].Activities[k];
								if (activity) {
									xml[xml.length] = '<assign property="' + zenEscapeXML(activity.Property) + '" ' +
												'value="' + zenEscapeXML(activity.Value) + '" ' +
												'action="' + zenEscapeXML(activity.Action) + '" ' +
												'key="' + zenEscapeXML(activity.Key) + '" />';
								}
							}
							xml.push('</' + tagName + '>');
						}
					}
				}
				if ((shapeModel.Type == 'code') || (shapeModel.Type == 'sql')) {
					// Called when "Save" in Editor
					languageOverride=shapeModel.PropertyBag.LanguageOverride?shapeModel.PropertyBag.LanguageOverride:''
					xml.push('<code languageOverride="' + zenEscapeXML(languageOverride) +'"><![CDATA[' + shapeModel.Code + ']]></code>');
				}
				xml.push('</shape>');
			}
		}

		for (var i = 0; i < bpl.Connectors.length; i++) {
			var conn = bpl.Connectors[i];
			if (conn && (conn.ConnectType != 'goto')) {
				var connXML = '<connection Name="' + zenEscapeXML(conn.Name) + '" from="' + conn.FromShape + '" to="' + conn.ToShape + '" ';
				switch (conn.ConnectType) {
					case 'case':
						connXML += 'Condition="' + zenEscapeXML(conn.Condition) + '" ';
						connXML += 'languageOverride="' + zenEscapeXML(conn.LanguageOverride) + '" ';
					case 'branch':
					case 'thread':
						connXML += 'ConnectType="' + conn.ConnectType + '" ';
						break;
				}
				if (conn.Disabled) connXML += 'Disabled="true" ';
				connXML += '/>';
				xml.push(connXML);
			}
		}
		xml.push('</diagram>');
		fullXML = xml.join('');
	}
	this.setResultsDiv('SAVE', fullXML, useDOMSave);
	this.setModified(false);
}

/// Add the Studio API methods.
Method %OnDrawHTMLHead() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	&html<<script type="text/javascript">
if (!Array.prototype.indexOf) { // ensure we have indexOf() available for arrays
	Array.prototype.indexOf = function Array_indexOf(searchElement,fromIndex) {
		var index = -1;
		if (!fromIndex) fromIndex = 0;
		for (var i = fromIndex; i < this.length; i++) {
			if (this[i] === searchElement) {
				index = i;
				break;
			}
		}
		return index;
	};
}
// Specify a contains function for all arrays.
Array.prototype.contains = function Array_contains(searchElement) {
	return this.indexOf(searchElement) != -1;
}
</script>>
	If ..studioMode {
		&html<<script type="text/javascript">
function document_save() {
	zenPage.saveBP(false);
}
function document_undo() {
	zenPage.undo();
}
function document_arrange() {
	zenPage.arrange();
}
function document_redo() {
	// unimplemented
}
function document_createShape(shapename) {
	// unimplemented
}
function document_setZoom(zoom) {
	// This callback no longer needed as zoom is initialized elsewhere
}
function document_getZoom(zoom) {
	zenPage.setResultsDiv('ZOOM',zenPage.currZoom);
}
function document_setReadOnly(ro) {
	zenPage.setReadOnly(ro);
}
function document_setProperty(property, value) {
	if (zenPage && zenPage.isNew && (property == 'Language')) {
		var field = zenPage.getComponentById('gLanguage');
		var bpl = zenPage.getBPLObject();
		if (field && bpl) {
			field.setValue(value);
			if (field.getValue() == value) bpl[property] = value;
		}
	}
}
invokeShapeCallbacks = true;
</script>>
	}
	Quit $$$OK
}

/// Helper method to list the types of context properties.
ClientMethod getContextPropertiesTypes(asCommaList) [ Language = javascript ]
{
	var propTypes = [];
	var model = this.getBPLObject();
	if (model.Context && model.Context.Properties && model.Context.Properties.length > 0) {
		for (var p = 0; p < model.Context.Properties.length; p++) {
			var prop = model.Context.Properties[p];
			propTypes.push(prop.Type);
		}
	}
	if (asCommaList) return propTypes.join(',');
	return propTypes;
}

/// Resolve the language used in scope of a given control
ClientMethod getControlLanguage(controlPrefix) [ Language = javascript ]
{
	var outLang=''
	var control = zen(controlPrefix+'LanguageOverride')
	var languageOverride=control?control.getValue():null
	if (languageOverride && (''!=languageOverride)) {
		outLang=languageOverride;
	} else {
		var model = this.getBPLObject();
		if (model) {
			outLang=model.Language 
		}
	}
	return outLang
}

}
