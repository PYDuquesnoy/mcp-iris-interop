/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.RuleEditor Extends (EnsPortal.Template.devPage, EnsPortal.Util.RuleSVGCommon) [ System = 4 ]
{

/// Comma-separated list of additional JS include files for the page.
Parameter JSINCLUDES As STRING = "zenCSLM.js";

/// User needs READ permissions on one of the following resources to view this page:
/// %Ens_Rules, %Ens_RoutingRules, %Ens_BusinessRules or %Ens_Code
Parameter RESOURCE = "%Ens_Rules:READ,%Ens_RoutingRules:READ,%Ens_BusinessRules:READ,%Ens_Code:READ";

/// User needs WRITE permissions on one of the following resources to make changes on this page:
/// %Ens_Rules, %Ens_RoutingRules, %Ens_BusinessRules or %Ens_Code
Parameter EDITRESOURCE = "%Ens_Rules:WRITE,%Ens_RoutingRules:WRITE,%Ens_BusinessRules:WRITE,%Ens_Code:WRITE";

/// Displayed name of this page.
Parameter PAGENAME = "Rule Editor";

/// The name of the rule to open
Property RULE As %String(ZENURL = "RULE");

Property RULELCP As %String(ZENURL = "rule");

/// Page invoked to create new rule
Property NEW As %Boolean(ZENURL = "NEW") [ InitialExpression = 0 ];

Property isRuleClass As %Boolean [ InitialExpression = 1 ];

/// The name of the default production name
Property PROD As %String(ZENURL = "PROD");

Property RULESET As %String(ZENURL = "RULESET");

Property FOCUSPATH As %String(ZENURL = "PATH");

/// The condition to be parsed
Property CONDITION As %String;

/// spacing between boxes
Property SPACING As %Integer [ InitialExpression = 15 ];

/// margin spacing for the frame box.
/// if FRAMEMARGIN is 0, no frame box is drawn
Property FRAMEMARGIN As %Integer [ InitialExpression = 0 ];

/// height of the text box
Property BOXHEIGHT As %Integer [ InitialExpression = 22 ];

/// distance of the vertical offset for the text y-attribute
Property TEXTVOFFSET As %Integer [ InitialExpression = 16 ];

/// length of the horizontal connecting lines
Property HLINELENGTH As %Integer [ InitialExpression = 20 ];

/// distance of the horizontal indentation
Property HINDENT As %Integer [ InitialExpression = 40 ];

/// distance of the horizontal indentation for condition graph
Property HCINDENT As %Integer [ InitialExpression = 20 ];

/// size of the margin of the text inside the text box
Property TEXTMARGIN As %Integer [ InitialExpression = 10 ];

/// radius of the rounded corners
Property RADIUS As %Integer [ InitialExpression = 6 ];

/// radius of the delete and insert circles
Property DOTRADIUS As %Integer [ InitialExpression = 7 ];

/// height of the total tab header
Property TABAREAHEIGHT As %Integer [ InitialExpression = 32 ];

/// height of the tabs
Property TABHEIGHT As %Integer [ InitialExpression = 26 ];

/// the maximum width of the tabs (from bottom to bottom)
Property TABMAXWIDTH As %Integer [ InitialExpression = 200 ];

/// The amout the tab top width is smaller than the bottom width
Property TABTOPREDUCTION As %Integer [ InitialExpression = 28 ];

/// the amount the top tab covers the bottom tab
Property TABOVERLAP As %Integer [ InitialExpression = 12 ];

/// the radius of the tab side curve
Property TABRADIUS As %Integer [ InitialExpression = 20 ];

/// the margin of tha tab text
Property TABTEXTMARGIN As %Integer [ InitialExpression = 20 ];

/// the row height of the ruleSetTable
Property TABLEROWHEIGHT As %Integer [ InitialExpression = 22 ];

/// the row height of the ruleSetTable
Property TABLETEXTVOFFSET As %Integer [ InitialExpression = 16 ];

/// the column width of the ruleSetTable
Property TABLECOLWIDTH As %Integer [ InitialExpression = 180 ];

/// the minimum first column width of the ruleSetTable
Property TABLEHEADCOLMINWIDTH As %Integer [ InitialExpression = 60 ];

/// the x-cellspacing of the ruleSetTable
Property TABLEXSPACING As %Integer [ InitialExpression = 4 ];

/// the y-cellspacing of the ruleSetTable
Property TABLEYSPACING As %Integer [ InitialExpression = 6 ];

/// the x-cellpadding of the ruleSetTable
Property TABLEXPADDING As %Integer [ InitialExpression = 6 ];

/// the x-margin of the ruleSetTable
Property TABLEXMARGIN As %Integer [ InitialExpression = 6 ];

Property %rule As Ens.Rule.Model.ruleDefinition;

Property drawHPathElbow As %Boolean [ InitialExpression = 1 ];

Property showProperty As %Boolean [ InitialExpression = 1 ];

Property optionDrawIfElse As %Boolean(ZENURL = "oIfElse") [ InitialExpression = 0 ];

Property helpVisible As %Boolean [ InitialExpression = 1 ];

Property msgRuleAssistant As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Rule Assistant")} ];

Property openNewWindow As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Property currentTab As %Integer [ InitialExpression = 0 ];

/// Comma-delimited list of states (1/true=contracted, 0/""/false=expanded=default) of rules in the ruleSet
Property ruleStates As %String(MAXLEN = "");

Property msgDocReadOnly As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("This rule is read only")} ];

Property tipSave As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save this Rule")} ];

Property tipNew As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Create a new Rule")} ];

Property tipOpen As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Load an existing Rule")} ];

Property tipSaveAs As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save this Rule with a new name")} ];

Property tipContractAll As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Contract Rules on the diagram")} ];

Property tipExpandAll As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Expand Rules on the diagram")} ];

/// This Style block contains page-specific CSS style definitions.
XData SVGStyle
{
<style type="text/css">

.rectRULESET { fill:#AAAADD; stroke:#BBBBBB; }
.textRULESET { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectEFFECTIVEBEGIN { fill:white; stroke:#BBBBBB; }
.textEFFECTIVEBEGIN { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectEFFECTIVEEND { fill:white; stroke:#BBBBBB; }
.textEFFECTIVEEND { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectRULE { fill:#AAAADD; stroke:#BBBBBB; }
.textRULE { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectNAME { fill:#E0E0F0; stroke:#BBBBBB; }
.textNAME { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectENABLED { fill:white; stroke:#BBBBBB; }
.textENABLED { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectDISABLED { fill:#DDDDDD; stroke:#BBBBBB;  }
.textDISABLED { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectWHEN { fill:#DDDDAA; stroke:#BBBBBB; }
.textWHEN { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectCONDITION { fill:#F1F0E7; stroke:#BBBBBB; }
.textCONDITION { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectOTHERWISE { fill:#DDDDAA; stroke:#BBBBBB; }
.textOTHERWISE { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectFOREACH { fill:#F7D4B2; stroke:#BBBBBB; }
.textFOREACH { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectPROPERTYPATH { fill:#F1F0E7; stroke:#BBBBBB; }
.textPROPERTYPATH { fill:black; stroke:non; font-family:arial; font-size:11pt; }

.rectASSIGN { fill:#DEF; stroke:#BBBBBB; }
.textASSIGN { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectPROPERTY { fill:#edece4; stroke:#BBBBBB; }
.textPROPERTY { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectEQUAL { fill:#DEF; stroke:#BBBBBB; }
.textEQUAL { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectVALUE { fill:white; stroke:#BBBBBB; }
.textVALUE { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectRETURN { fill:rgb(250,236,226); stroke:#BBBBBB; }
.textRETURN { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectTRACE { fill:#E0F0E0; stroke:#BBBBBB; }
.textTRACE { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectDEBUG { fill:#E0F0E0; stroke:#BBBBBB; }
.textDEBUG { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectCOMMENT { fill:#E0F0E0; stroke:#BBBBBB; }
.textCOMMENT { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectTEXT { fill:white; stroke:#BBBBBB; }
.textTEXT { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectSEND { fill:#FFFFDD; stroke:#BBBBBB; }
.textSEND { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectTRANSFORM { fill:#edece4; stroke:#BBBBBB; }
.textTRANSFORM { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectTARGET { fill:#f1f0e7; stroke:#BBBBBB; }
.textTARGET { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectDELETE { fill:#F0E0E0; stroke:#BBBBBB; }
.textDELETE { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectDELEGATE { fill:#E0E0F0; stroke:#BBBBBB; }
.textDELEGATE { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectRULENAME { fill:white; stroke:#BBBBBB; }
.textRULENAME { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectCONSTRAINT { fill:#DDDDFF; stroke:#BBBBBB; }
.textCONSTRAINT { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectBase { fill:#BBBBBB; stroke:#BBBBBB; }
.textBase { fill:white; stroke:none; font-family:arial; font-size:9pt; }

.rectFocused { fill:#FFEEAA; stroke:rgb(53,107,141); stroke-width:2; }
.textFocused { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectTabFocused { fill:white; stroke:#888888; }
.rectTabBack    { fill:#C0D9F8; stroke:#888888; }
.textTab        { fill:black; stroke:none; font-family:arial; font-size:9pt; }

.rectTableHeader { fill:#D0D0FF; stroke:#D0D0FF; }
.textTableHeader { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectTableRow { fill:#EEEEEE; stroke:#EEEEEE; }
.textTableRow { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectTableRowFocused { fill:#FFEEAA; stroke:rgb(53,107,141); stroke-width:2; }
.textTableRowFocused { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.rectCondOPERATOR { fill:rgb(56,113,139); stroke:black; }
.textCondOPERATOR { fill:white; stroke:none; font-family:arial; font-size:11pt; }

.rectCondVALUE  { fill:rgb(250,236,226); stroke:rgb(150,150,150); }
.textCondVALUE  { fill:black; stroke:none; font-family:arial; font-size:11pt; }

.numText { fill:#222222; font-size:8pt; }
.numRect { fill:#EDECE4; stroke:#999999; }
.numFocused { fill:#FFEEAA; stroke:rgb(53,107,141); }

.msgBox {
	fill: #FFCC11;
	stroke: white;
	stroke-width: 1;
	opacity: 0.8;
}

.msgBoxText {
	pointer-events: none;
	font-size: 14px;
	fill: black;
	stroke: none;
	font-family: arial;
}
</style>
}

XData Style
{
<style type="text/css">
.svgFrame { border: none; }
.imageLink { cursor:default;}
.csMenuSeparator { position:absolute; }

#emptyBar {
	overflow: hidden;
}

#helpPanel {
	background: #F0F0F0;
	border-left: 1px solid #808080;
	text-align: center;
	overflow-y: auto;
	overflow-x: hidden;
}

#helpPanelContents {
	padding: 5px;
	width: 277px;
}

#hpNoSelectMsg,
#hpCurrItemDesc {
	padding-top: 5px;
	font-size: 10pt;
	color: #404040;
}

.helpItem {
	background: #D0D0D0;
	color: #404040;
	border: 1px solid #808080;
	border-radius: 4px;
	text-align: center;
	font-size: 11pt;
	padding: 2px;
}

.imageButton img {
	border: 0px solid #808080;
	border-radius: 4px;
}

.addItem {
	cursor:default;
	background: #D0D0D0;
	color: #404040;
	border: 1px solid #808080;
	border-radius: 4px;
	text-align: center;
	font-size: 11pt;
	padding: 2px;
	width: 80px;
}

.imageButton img:hover {
	border: 0px solid blue;
	border-radius: 4px;
}

.hiddenImage {
	display: none;
}

.ribbonAction {
	font-size: 10pt;
	color: #606060;
	white-space: nowrap;
}

/* Styles for Rule Testing tab */
/* EDI Document Table */
TABLE.EDIDocumentTable {
	border: black solid 1px;
	font-size: 0.8em;
	background: #DDDDFF;
	margin-left: 10px;
	margin-right: 10px;
	width: 10px;
}

TD.EDIDocumentTableExpandor {
	background: #D0D0FF;
	border-bottom: gray solid 1px;
	padding: 2px;
}

TD.EDIDocumentTableSegnum {
	background: white;
	font-weight: bold;
	text-align: right;
	border-bottom: gray solid 1px;
	padding: 2px;
}

TD.EDIDocumentTableSegid {
	background: white;
	border-bottom: gray solid 1px;
	border-right: gray solid 1px;
	padding: 2px;
}

TD.EDIDocumentTableSegname {
	background: #D0D0FF;
	text-align: center;
	font-weight: bold;
	border-bottom: gray solid 1px;
	padding: 2px;
}

/* Segment single-row Table */
TABLE.EDISegmentsTable {
	background: white;
	font-size: 0.9em;
	border-bottom: gray solid 1px;
}

TD.EDISegmentsTableValue {
	background: white;
	padding: 2px;
}
TD.EDISegmentsTableSeparator {
	background: white;
	padding: 2px;
}
TD.EDISegmentsTableEmptyfield {
	background: white;
	padding: 2px;
}

/* rule log based on eventInfoTable but increased pt size*/
table.eventInfoTable {
	background-color: white;
	padding: 20px;
	margin-top: 5px;
}
table.eventInfoTable td {
	padding: 2px;
}
.eventCaption {
	font-weight: bold;
	font-size: 12pt;
}
.eventValue {
	font-weight: normal;
	font-size: 12pt;
}
.eventText {
	padding: 5px;
	background-color: ivory;
	border: 1px solid gray;
}
/* styles for detailed rule debugging table */
.ruleDebugWrapper {
	background-color: white;
	padding: 20px;
	border-top: 1px solid #CCC;
	margin-top: 5px;
	border-bottom: 1px solid #CCC;
}
.ruleDebugHeader {
	font-weight: bold;
	width: 100%;
	text-align: left;
	font-size: 0.9em;
	padding-top: 5px;
	padding-bottom: 5px;
}
table.ruleDebugData {
	font-size: 10pt;
	border-collapse: collapse;
	padding: 20px;
	border: 1px solid #CCC;
}
table.ruleDebugData tr th {
	text-align: left;
}
table.ruleDebugData tr td {
	padding-left: 20px;
	padding-right: 2px;
	padding-top: 2px;
	padding-bottom: 2px;
	color: #333;
}
table.ruleDebugData tr:nth-child(even) {
	background-color: #EEE;
}
table.ruleDebugData tr:first-child {
	border-bottom: 1px solid #CCC;
}

.errorMessage {
	color: darkred;
	font-size: 0.8em;
}
/* icons in the debug rule log output */
.rulePassed {
	padding:10px 10px;
	margin:0 auto;
	border-radius:50%;
	background-color:green;
}
.ruleError {
	padding:10px 10px;
	margin:0 auto;
	border-radius:50%;
	background-color:red;
}
.ruleFailed {
	padding:10px 10px;
	margin:0 auto;
	border-radius:50%;
	background-color:grey;
}
.ruleWarning{
	width: 0;
	height: 0;
	border-left: 10px solid transparent;
	border-right: 10px solid transparent;
	border-bottom: 16px solid orange;}

.hdrLink {
	font-size: 12pt;
	font-weight: normal;
	color: #78b6dc;
	text-decoration: none;
	padding-left: 6px;
	padding-right: 6px;
}

</style>
}

/// This XML block defines the contents of this page.
/// change to contentPane
XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" layout="none" id="mainPane" enclosingStyle="visibility: hidden;">

<jsonProvider id="modelRuleDefinition" OnGetTargetObject="GetRuleDefinitionObject" OnSubmitContent="SaveRuleDefinitionObject"/>

<jsonProvider id="modelCondition" OnGetTargetObject="GetConditionObject"/>

<jsonProvider id="ruleAssistList" OnGetTargetObject="GetRuleAssistList"/>

<group layout="none">
<contextMenu id="menuAdd"/>
</group>

<hgroup cellVAlign="top">
<vgroup>
<svgFrame id="svgTabArea" height="36" width="10" layout="none">
<ownerDraw height="30" onrender="zenPage.doOwnerDrawTabs();"/>
</svgFrame>

<group layout="none" id="bar">
<hgroup width="100%">
<image id="imgBlank" width="11px" height="27px" src="rule/blank.png"
onclick="zenPage.debugClicked()" controlStyle="border: 1px solid white;"
/>
<image id="imgUp"       title="move the node up" width="27px" height="27px" src="rule/up_disabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"
/>
<image id="imgDown"     title="move the node down" width="27px" height="27px" src="rule/down_disabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"
/>
<image id="imgAdd"      title="add new items" width="27px" height="27px" src="rule/add_disabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"
/>
<image id="imgDelete"   title="delete the node" width="27px" height="27px" src="rule/delete_disabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"
/>
<image id="imgUndo"     title="undo the last change" width="27px" height="27px" src="rule/undo_disabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"
/>
<image id="imgRedo"     title="redo the last undo change" width="27px" height="27px" src="rule/redo_disabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"
/>
<image id="imgDetail" title="edit expression or selection" width="27px" height="27px" src="rule/detail_disabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"
/>
<spacer width="4"/>

<group layout="none"  width="100%">
<hgroup id="emptyBar" width="100%">
<text disabled="true" id="emptyEditor" controlStyle="width:100%; overflow: hidden; font-family:arial; font-size:11pt; background:#EEEEEE; border:1px solid #AAAAAA;"/>
<spacer width="2px"/>
</hgroup>
<hgroup id="textBar" width="100%" hidden="true">
<text id="textEditor" controlStyle="width:100%; font-family:arial; font-size:11pt;" onkeypress="zenPage.textEditorKeypress()"/>
<spacer width="10px"/>
<button id="textOK" width="60px" caption="OK" controlClass="OKbutton" controlStyle="width:60px;" onclick="zenPage.textOKClicked()"/>
</hgroup>

<hgroup id="xyzBar" width="100%; font-family:arial; font-size:11pt;" hidden="true">
<html id="htmlPanel">
<div style="position:relative;top:0px;left:0px;overflow:visible;">
<div id="xyzSelectorParent" style="position:relative; top:0px; left:0px; width:100%;">
<select id="xyzSelector" size="5" style="position:absolute; display:none; top:26px; left:0px; width:100%;" onchange="zenPage.xyzSelectorChanged()" onfocus="zenPage.xyzSelectorFocused();" ondblclick="zenPage.xyzSelectorDblClicked();"/>
</div>
<input id="xyzGrayText"
type="text" style="position:absolute;top:0px;left:0px; width:100%;border:1px solid #7F9DB9;color:#C0C0C0;" readOnly="true"
onfocus="zenPage.xyzGrayTextGotFocus();">
</input>
<input id="xyzEditor" onkeydown="zenPage.xyzEditorKeyPressed(event);" onblur="zenPage.xyzEditorOnBlur(event);"
type="text" style="position:relative;top:0px;left:0px; width:100%;border:1px solid #7F9DB9;background:transparent;">
</input>
</div>
</html>
<spacer width="10px"/>
<button id="xyzOK" width="60" caption="OK" controlClass="OKbutton" controlStyle="width:60px;" onclick="zenPage.xyzOKClicked()"/>
</hgroup>

<hgroup id="propertyBar" width="100%" hidden="true">
<html width="100px">
<select id="propertySelector" height="22px" style="width:100px; min-width:100px;" onchange="zenPage.propertySelectorChanged();"/>
</html>
<spacer width="4px"/>
<spacer width="10px"/>
<button id="propertyOK" width="60" caption="OK" controlClass="OKbutton" controlStyle="width:60px;" onclick="zenPage.propertyOKClicked()"/>
</hgroup>
</group>
<spacer width="4px"/>
<group layout="none">
<image id="imgViewOn" title="toggle viewing of property name" height="27px" enclosingClass="hiddenImage" src="rule/viewon_disabled.png"
onmouseover="zenPage.mouseOver(zenThis);" onmouseout="zenPage.mouseOut(zenThis);" onmousedown="zenPage.mouseDown(zenEvent,zenThis);" onmouseup="zenPage.mouseUp(zenEvent,zenThis);"
/>
<image id="imgViewOff" title="toggle viewing of property name" height="27px" src="rule/viewoff_disabled.png"
onmouseover="zenPage.mouseOver(zenThis);" onmouseout="zenPage.mouseOut(zenThis);" onmousedown="zenPage.mouseDown(zenEvent,zenThis);" onmouseup="zenPage.mouseUp(zenEvent,zenThis);"
/>
</group>
<spacer width="4px"/>
</hgroup>
<spacer height="3px"/>
</group>

<group id="testPanel" hidden="true" layout="none">
<hidden name="testContextSerialized" id="testContextSerialized"/>
<hgroup containerStyle="padding:10px;">
<spacer width="20px"/>
<vgroup labelPosition="left" containerStyle="padding:10px; border: 1px solid black; background-color: lightgrey;">
<hgroup id="testSourceRow" label="Production Source for test" labelPosition="left">
<text id="testSource" name="testSource" title="Production Source Config Item" size="30" value="" />
<spacer width="5px" />
<button caption="Select" controlClass="commandButton" onclick="zenPage.testSourceLookup(); return false;" />
</hgroup>
<spacer height="8px;" />
<hgroup id="testContextSourceRow" label="Context/Context Document Source">
<combobox id="testContextSource" name="testContextSource" size="35"
		 valueList="Body,Header,Paste"
		 value="Paste"
		 displayList="Document Body ID,Message Header ID,User Input"
		 title="Use this field to specify whether you want to get message data from a message object stored within the namespace or from user input screen. For the message object, you may supply the ID of the message header object or the message body object."
		 onchange="zenPage.changeContextSource();" />
<label label=" "/>
</hgroup>
<spacer height="8px;" />
<hgroup id="docSourceLbl" label="" labelPosition="left">
<text id="docHeader" name="docHeader" size="20" hidden="true"/>
<text id="docId" name="docId" size="20" hidden="true"/>
<button name="msgEnterData" id="msgEnterData" caption="Data Form" controlClass="commandButton" onclick="zenPage.btnEnterData();" title="" hidden="true"/>
</hgroup>
<spacer height="20px;" />
<hgroup align="right">
<button name="Test" id="btnTest" caption=" Run Test " controlClass="commandButton" onclick="zenPage.btnTest();" title="" />
</hgroup>
</vgroup>
</hgroup>
<vgroup valign="top" align="left" id="testResults">
<hgroup>
<spacer width="20px"/>
<pane id="testErrorResultPane" label="Error:">
<html id="testErrorResult" OnDrawContent="DrawErrorResult"/>
</pane>
</hgroup>
<spacer height="20" />
<hgroup>
<spacer width="20px"/>
<pane id="testMessageDisplayPane" label="Document:">
<html id="testMessageDisplay" OnDrawContent="DrawMessageHTML" seed="#(%page.showTestMessage)#" />
</pane>
</hgroup>
<spacer height="20" />

<hgroup>
<spacer width="20px"/>
<pane id="testRuleLogDisplayPane" label="Test Result:" enclosingStyle="border-style: solid; border-color:black;">
<html id="testRuleLogDisplay" OnDrawContent="DrawRuleLog" seed="#(%page.testIsRoutingRule)#" />
</pane>
</hgroup>
<spacer height="20" />
<hgroup>
<spacer width="20px"/>
<pane id="testDebugLogDisplayPane" label="Test Logging" enclosingStyle="border-style: solid;border-color:black;">
<html id="testDebugLogDisplay" OnDrawContent="DrawRuleDebugLog" />
</pane>
</hgroup>
</vgroup>
</group>

<group id="svgScrollingArea" layout="none" onclick="zenPage.backgroundClicked();">

<svgFrame id="svgPanel" height="1" width="1" layout="none" onmouseWheel="zenPage.doScroll(delta);">
<ownerDraw height="0" onrender="zenPage.doOwnerDrawTable();"/>
</svgFrame>

<group id="headerPanel" height="1" width="1" cellStyle="padding-left:10px;">
<hgroup id="headerTop" containerStyle="padding:15px;">
<hgroup id="headerBlock" containerStyle="padding:0px; background:#DDDDDD;" enclosingStyle="display:none">
<vgroup id="genGroup" cellStyle="padding:4px;" labelPosition="left">
<textarea id="headerDescription"  label="Description:" cols="46" rows="4" onchange="zenPage.moRuleDefinitionObject.description=zenThis.value;zenPage.undoStackPush(true);"/>
<combobox id="headerRuleTypeCombo"
label="Rule Type:"
title="Please select what type of rule you want to create"
editable="false"
unrestricted="true"
onchange="zenPage.ruleTypeChanged();"
/>
<combobox id="headerAssistClassCombo"
label="Rule Assist Class:"
title="The class that provides editing and runtime constraint features for a particular type of message routing. For general business rules this is blank."
editable="true"
unrestricted="true"
onchange="zenPage.ruleAssistClassChanged();"
/>
<hgroup cellVAlign="middle" label="Context Class:"
       title="The class containing the properties that will be available when the rule is evaluated. For routing rules this is the message router class and the principal context property is called Document. It contains the object instance to be transformed and forwarded.">
<text id="headerContext" onchange="zenPage.moRuleDefinitionObject.context=zenThis.value;zenPage.undoStackPush(true);"/>
<spacer width="4px"/>
<image src="deepsee/zoom_16.png" onclick="zenPage.selectContextClass();" title="Select new context class"/>
</hgroup>
<text id="headerAlias" label="Rule Alias:"
onchange="zenPage.moRuleDefinitionObject.alias=zenThis.value;zenPage.undoStackPush(true);"
title="Not needed for new rules. This field provides backward compatibility with older rule names that use _ (underscore) or space characters. The following punctuation characters are not allowed in rule alias names: ;,:|!*-$'&quot;&lt;&gt; and &amp;."
/>
<text id="headerVariables" label="Temporary Variables:"
onchange="zenPage.variablesChanged(zenThis.value);"
title="Declare temporary variables in a comma seperated list."
/>
<dataCombo id="headerProduction" label="Production Name:"
title="The production in which a routing rule is expected to run."
onchange="zenPage.moRuleDefinitionObject.production=zenThis.value;zenPage.undoStackPush(true);"
queryClass="Ens.Config.Production" queryName="Extent"
editable="true" unrestricted="true"
/>
</vgroup>
</hgroup>
</hgroup>
<svgFrame id="svgTable" height="1" width="1" layout="none" enclosingStyle="overflow:visible;" onmouseWheel="zenPage.doScroll(delta);">
<ownerDraw height="0" onrender="zenPage.doOwnerDrawMain();"/>
</svgFrame>
</group>

</group>
</vgroup>
<vgroup id="helpPanel">
<html id="helpCommand" containerStyle="text-align:left; padding:4px;">
<div>
<a id="helpCommandLink" class="helpCommand" href="#" onclick="zenPage.toggleHelp(); return false;">
<span id="helpCommandArrow" class="helpArrow" title="Hide or show the Rule Assistant">&#187;</span>
</a>
</div>
</html>
<vgroup id="helpPanelContents">

<spacer height="5px"/>
<hgroup cellStyle="padding-left: 10px; border-bottom: 1px solid #808080;" cellVAlign="top">
<image src="portal/spyware_48.gif" title="Rules!"/>
<html><div style="font-size: 28px; color:#606060; text-shadow: #808080 1px 1px 1px;">#(%page.msgRuleAssistant)#</div></html>
</hgroup>

<!-- description of current selection -->
<hgroup id="hpCurrSelect" cellStyle="padding: 10px;" cellVAlign="top"  hidden="true">
<vgroup>
<html id="hpCurrItemType" enclosingClass="helpItem"/>
<html id="hpCurrItemDesc"/>
</vgroup>
</hgroup>

<hgroup id="hpNoSelect" cellStyle="padding-left: 10px;" cellVAlign="top"  hidden="true">
<html id="hpNoSelectMsg"/>
</hgroup>

<!-- options -->
<hgroup id="hpMoveUp"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<image id="hpiUp" enclosingClass="imageButton" title="Move the current item up" src="rule/up_enabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"/>
<label label="Move the current item up one position."/>
</hgroup>

<hgroup id="hpMoveDown"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<image id="hpiDown" enclosingClass="imageButton" title="Move the current item down" src="rule/down_enabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"/>
<label label="Move the current item down one position."/>
</hgroup>

<hgroup id="hpAdd"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<image id="hpiAdd-return" enclosingClass="imageButton" title="Add an assign action" src="rule/add_enabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"/>
<label label="Click on a button below to add an item to the diagram."/>
</hgroup>

<hgroup cellStyle="padding: 0px;">
<spacer width="10px"/>
<vgroup>
<hgroup id="hpAdd-assign"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<html><div id="btnAdd-assign" class="addItem">assign</div></html>
<label label="Add an assign action."/>
</hgroup>
<hgroup id="hpAdd-return"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<html><div id="btnAdd-return" class="addItem">return</div></html>
<label label="Add a return action."/>
</hgroup>
<hgroup id="hpAdd-trace"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<html><div id="btnAdd-trace" class="addItem">trace</div></html>
<label label="Add a trace action."/>
</hgroup>
<hgroup id="hpAdd-debug"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<html><div id="btnAdd-debug" class="addItem">debug</div></html>
<label label="Add a debug action."/>
</hgroup>
<hgroup id="hpAdd-comment"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<html><div id="btnAdd-comment" class="addItem">comment</div></html>
<label label="Add a comment."/>
</hgroup>
<hgroup id="hpAdd-send"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<html><div id="btnAdd-send" class="addItem">send</div></html>
<label label="Add a send action."/>
</hgroup>
<hgroup id="hpAdd-delete"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<html><div id="btnAdd-delete" class="addItem">delete</div></html>
<label label="Add a delete action."/>
</hgroup>
<hgroup id="hpAdd-delegate"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<html><div id="btnAdd-delegate" class="addItem">delegate</div></html>
<label label="Add a delegate action."/>
</hgroup>
<hgroup id="hpAdd-rule"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<html><div id="btnAdd-rule" class="addItem">rule</div></html>
<label label="Add a rule."/>
</hgroup>
<hgroup id="hpAdd-foreach"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<html><div id="btnAdd-foreach" class="addItem">foreach</div></html>
<label label="Add a foreach clause."/>
</hgroup>
<hgroup id="hpAdd-when"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<html><div id="btnAdd-when" class="addItem">when</div></html>
<label label="Add a when clause."/>
</hgroup>
<hgroup id="hpAdd-otherwise"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<html><div id="btnAdd-otherwise" class="addItem">otherwise</div></html>
<label label="Add an otherwise clause."/>
</hgroup>
</vgroup>
</hgroup>

<hgroup id="hpDelete"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<image id="hpiDelete" enclosingClass="imageButton" title="Delete the current item" src="rule/delete_enabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"/>
<label label="Delete the current item and all items related to it."/>
</hgroup>

<hgroup id="hpUndo"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<image id="hpiUndo" enclosingClass="imageButton" title="Undo the last change" src="rule/undo_enabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"/>
<label label="Undo the last change."/>
</hgroup>

<hgroup id="hpRedo"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<image id="hpiRedo" enclosingClass="imageButton" title="Redo the last change" src="rule/redo_enabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"/>
<label label="Redo the last change."/>
</hgroup>

<hgroup id="hpDetail"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<image id="hpiDetail" enclosingClass="imageButton" title="Invoke the expression or selection editor." src="rule/detail_enabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"/>
<label label="Invoke the expression or selection editor."/>
</hgroup>

<hgroup id="hpViewOn"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<image id="hpiViewOn" enclosingClass="imageButton" title="Turn property name view on" src="rule/viewon_enabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"/>
<label label="Turn on the viewing of property name in the diagram."/>
</hgroup>

<hgroup id="hpViewOff"  hidden="true" cellStyle="padding: 10px;" cellVAlign="top">
<image id="hpiViewOff" enclosingClass="imageButton" title="Turn property name view off" src="rule/viewoff_enabled.png"
onmouseover="zenPage.mouseOver(zenThis)" onmouseout="zenPage.mouseOut(zenThis)" onmousedown="zenPage.mouseDown(zenEvent,zenThis)" onmouseup="zenPage.mouseUp(zenEvent,zenThis)"/>
<label label="Turn off the viewing of property name in the diagram."/>
</hgroup>

</vgroup>
</vgroup>
</hgroup>
</pane>
}

ClientMethod doOwnerDrawTabs() [ Language = javascript ]
{
	this.svgTabAreaLoaded = true;
	if ( this.svgMainAreaLoaded&&this.svgTabAreaLoaded&&this.svgTableAreaLoaded ) this.initialize();
	return;
}

ClientMethod doOwnerDrawMain() [ Language = javascript ]
{
	this.svgMainAreaLoaded = true;
	if ( this.svgMainAreaLoaded&&this.svgTabAreaLoaded&&this.svgTableAreaLoaded ) this.initialize();
	return;
}

ClientMethod doOwnerDrawTable() [ Language = javascript ]
{
	this.svgTableAreaLoaded = true;
	if ( this.svgMainAreaLoaded&&this.svgTabAreaLoaded&&this.svgTableAreaLoaded ) this.initialize();
	return;
}

ClientMethod initialize() [ Language = javascript ]
{
	var json = this.getClientModel();
	this.svgTabAreaLoaded = false;
	this.svgMainAreaLoaded = false;
	this.svgTableAreaLoaded = false;
	this.moRuleDefinitionObject = json.getContentObject();
	if ( this.moRuleDefinitionObject == null ) return;
	this.buildConstraintCache();
	this.moFocusedPanelIndex = this.moRuleDefinitionObject.ruleSets.length > 0 ? 0 : -1;
	this.currentTab = this.moFocusedPanelIndex;
	this.moFocusedJsonObject = new Array();
	this.moFocusedJsonProperty = new Array();
	this.moFocusedRuleSetIndex = null;
	this.moMenuAddIsShown = false;
	if (this.RULESET != '') {
		this._checkFocusPath = (this.FOCUSPATH != '');
		var ruleSetPos = 0;
		if (this.RULESET === parseInt(this.RULESET,10)) {
			ruleSetPos = parseInt(this.RULESET,10) - 1;
		}
		else {
			for (var i = 0; i < this.moRuleDefinitionObject.ruleSets.length; i++) {
				var ruleSet = this.moRuleDefinitionObject.ruleSets[i];
				if (ruleSet && (ruleSet.name === this.RULESET)) {
					ruleSetPos = i;
					break;
				}
			}
		}
		this.moFocusedPanelIndex = ruleSetPos;
		this.currentTab = this.moFocusedPanelIndex;
		this.RULESET = '';
	}
	this.undoStackInit();
	this.headerPopulateComboBoxes();
	this.drawRuleDefinition();
	return;
}

ClientMethod headerPopulateComboBoxes() [ Language = javascript ]
{
	var assistData = zen('ruleAssistList').getContentObject();
	var typeList = '';
	if (assistData.typeList && (typeof assistData.typeList.join == 'function')) typeList = assistData.typeList.join(',');
	zen("headerRuleTypeCombo").setProperty("valueList",typeList);
	var classList = '';
	if (assistData.classList && (typeof assistData.classList.join == 'function')) classList = assistData.classList.join(',');
	zen("headerAssistClassCombo").setProperty("valueList",classList);
	this.moAssistClassArray = (assistData && assistData.itemList) ? assistData.itemList : [];
	for ( var i=0 ; i<this.moAssistClassArray.length ; i++ ) {
		var item = this.moAssistClassArray[i];
		item.hasConstraints = (item.hasConstraints===1);
		item.isRoutingRule = (item.isRoutingRule===1);
		item.hasSegments = (item.hasSegments===1);
	}
	return;
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	var scrollToObject = null;
	if (load) {
		this.setReadOnly(this.readOnly || !this.canEdit);
		this.updateBrowserFlags();
		this._svgData = { "list": [ { "component": zen('svgPanel'), "style": null }, { "component": zen('svgTable'), "style": null }, { "component": zen('svgTabArea'), "style": null } ] };
		this._validationData = { "when": [ "condition" ], "foreach": [ "propertypath" ], "assign": [ "property", "value" ], "trace": [ "value" ], "debug": [ "value" ], "comment": [ "text" ], "send": [ "target" ], "delegate": [ "ruleName" ] };
		zen('mainPane').getEnclosingDiv().style.visibility = 'visible';
		if ( this.isNew && (this.RULE === '') ) { this.newRule(this.RULE); }
		else if (this._checkFocusPath && (this.moFocusedPanelIndex != -1)) {
			var focusData = this.FOCUSPATH.split(':');
			var focusLength = focusData.length;
			var currObj = this.moRuleDefinitionObject.ruleSets[this.moFocusedPanelIndex];
			var currRule = null;
			for (var i = 0; i < focusLength; i++) {
				var currPair = focusData[i];
				var barPos = currPair.indexOf('|');
				if ((!currObj) || (!currObj.actions) || (barPos === -1)) {
					currObj = null;
					break;
				}
				var ruleNum = currPair.substring(0,barPos);
				ruleNum = parseInt(ruleNum,10);
				if (currObj.actions) {
					// ensure we only count rules in the actions list
					var tmpAction;
					var ruleCounter = 0;
					for (var j = 0; j < currObj.actions.length; j++) {
						tmpAction = currObj.actions[j];
						if (tmpAction && (tmpAction.type === 'rule')) {
							ruleCounter++;
							if (ruleCounter === ruleNum) {
								currRule = tmpAction;
								break;
							}
						}
					}
				}

				var whenPos = currPair.substring(barPos+1);
				if (whenPos == '0') {
					currObj = currRule;
				}
				else {
					var testWhen = null;
					if (currRule) {
						if (whenPos.toUpperCase() === 'OW') {
							testWhen = currRule.otherwise;
							if (testWhen && (testWhen.type != 'otherwise')) {
								testWhen = null;
							}
						}
						else if (currRule.whens) {
							whenPos = parseInt(whenPos,10);
							testWhen = currRule.whens[whenPos-1];
							if (testWhen && (testWhen.type != 'when')) {
								testWhen = null;
							}
						}
					}
					if (!testWhen) {
						currObj = null;
						break;
					}
					currObj = testWhen;
				}
			}
			if (currObj) {
				var objIndex = null;
				for (var j=0; j<this.moMainMap.length; j++) {
					var mapObj = this.moMainMap[j];
					if (mapObj && (mapObj.jsonObject === currObj)) {
						objIndex = j;
						break;
					}
				}
				if (objIndex != null) {
					this.getFocus(objIndex);
					scrollToObject = mapObj.svgRectObject;
				}
			}
		}
	}

	var area = zen("svgScrollingArea");
	var areaDiv = area.getEnclosingDiv();
	// When showing test tab (last tab) keep scroll bars
	if ((!load)&&(this.moRuleDefinitionObject)&&(this.moRuleDefinitionObject.ruleSets)&&(this.currentTab==this.moRuleDefinitionObject.ruleSets.length)) {
		document.body.style.overflow = "auto";
	} else {
		document.body.style.overflow = "hidden";
	}
	areaDiv.style.overflow = "auto";
	var areaHeight = zenGetWindowHeight()-this.getTitleAreaHeight()-zen('svgTabArea').getEnclosingDiv().offsetHeight-zen('bar').getEnclosingDiv().offsetHeight;
	areaDiv.style.height = (areaHeight < 0 ? 0 : areaHeight) + 'px';

	var helpDiv = zen("helpPanel").getEnclosingDiv();
	var helpHeight = zenGetWindowHeight()-this.getTitleAreaHeight();
	helpDiv.style.height = (helpHeight < 0 ? 0 : helpHeight) + 'px';

	var helpWid = this.helpVisible ? 300 : 40;
	var wwid = zenGetWindowWidth() - helpWid + 12;
	wwid = (wwid < 0 ? 0 : wwid);

	zen("helpPanelContents").setHidden(!this.helpVisible);

	areaDiv.style.width = wwid + 'px';
	zen("svgTabArea").setProperty("width",wwid);
	zen("svgTabArea").setProperty("height",this.TABAREAHEIGHT);

	var width = (wwid-150)*0.7;
	width = (width < 0 ? 0 : width);
	var widthM19 = ( width < 19 ? 0 : width - 19);
	var widthM10 = ( width < 10 ? 0 : width - 10);
	zen("headerDescription").setProperty("controlStyle","width:"+width+'px');
	zen("headerRuleTypeCombo").setProperty("controlStyle","width:"+widthM19+'px');
	zen("headerRuleTypeCombo").setProperty("dropdownWidth",widthM10+'px');
	zen("headerAssistClassCombo").setProperty("controlStyle","width:"+widthM19+'px');
	zen("headerAssistClassCombo").setProperty("dropdownWidth",widthM10+'px');
	zen("headerContext").setProperty("controlStyle","width:"+width+'px');
	zen("headerAlias").setProperty("controlStyle","width:"+width+'px');
	zen("headerVariables").setProperty("controlStyle","width:"+width+'px');
	zen("headerProduction").setProperty("controlStyle","width:"+widthM19+'px');
	zen("headerProduction").setProperty("dropdownWidth",widthM10+'px');
	zen("svgTable").setProperty("controlStyle","width:"+width+'px');

	if (load && !zen("svgTable").svgGroup && !(!!document.createElementNS && !! document.createElementNS(SVGNS, "svg").createSVGRect)) {
		alert($$$Text("Unable to load SVG diagram. Please ensure your browser is supported for portal access."));
	}

	this.drawTabs();
	this.drawRuleHeader();

	if (scrollToObject) {
		var scrollPos = scrollToObject.getAttribute('y');
		if (scrollPos) {
			areaDiv.scrollTop = parseInt(scrollPos,10) - 50;
		}
	}
	this.xyzBase = "\0";
	this.xyzblurHandler = null;
	if ( zenIsIE ) { document.getElementById("xyzEditor").style.top = "-1px"; }

	if (zenPage.RULE === '' || !zenPage.isRuleClass) {
		// assist text for the case when an existing Rule is not being displayed
		var msg = $$$Text("Use the buttons at the top to create a new Rule, or to open an existing Rule.");
		zen('hpNoSelect').setHidden(false);
		zen('hpNoSelectMsg').setContent(msg);
	}
	if (load && zenPage.RULE != '' && !zenPage.isRuleClass) {
		var msg = $$$FormatText($$$Text("There is no existing Rule with name '%1'.  Use the buttons at the top to create a new Rule, or to open an existing Rule."),this.RULE);
		alert(msg);
		return;
	}

	// on IE8, the text box is drawn too wide on long strings.
	// this is because IE8 doesn't do "width:100%" properly
	// It appears IE8 can't figure out what "width:100%" should be before the invisible parent is rendered
	// we just compute what "width:100%" should be in pixel number and set it by hand
	var textEditorWidth = Math.max(wwid-313,0);
	zen("textEditor").findElement('control').style.width = textEditorWidth + "px";

	// configure the test context source associated buttons/fields
	if (load) zenPage.changeContextSource();
	return;
}

ClientMethod drawTabs() [ Language = javascript ]
{
	var TABAREAHEIGHT = parseInt(this.TABAREAHEIGHT);
	var TABOVERLAP = parseInt(this.TABOVERLAP);
	var svg = zen("svgTabArea");

	// remove all children
	if (svg.svgGroup) {
		for ( var child = svg.svgGroup.firstChild; child != null ; child = svg.svgGroup.firstChild ) {
			svg.svgGroup.removeChild(child);
		}
	}

	if (svg.document) {
		// draw background
		var rect =svg.document.createElementNS(SVGNS,'rect');
		rect.setAttribute("x",0);
		rect.setAttribute("y",0);
		rect.setAttribute("width",zenGetWindowWidth());
		rect.setAttribute("height",svg.getProperty("height"));
		rect.setAttribute("style","stroke:#A5BFE4; fill:#A5BFE4");
		zen("svgTabArea").svgGroup.appendChild(rect);
	}
	// return when there is no ruleDefinition
	if ( this.moRuleDefinitionObject == null ) return;

	var tabwidth = Math.min(zenGetWindowWidth()/(this.moRuleDefinitionObject.ruleSets.length+1),parseInt(this.TABMAXWIDTH));

	// normalize this.moFocusedPanelIndex
	this.moFocusedPanelIndex = parseInt(this.moFocusedPanelIndex);
	this.currentTab = this.moFocusedPanelIndex;
	// draw un-focused tabs
	for ( var i=-1 ; i<this.moFocusedPanelIndex ; i++ ) {
		this.drawOneTab(i,tabwidth,false);
	}
	// last tab is test tab
	for ( var i=this.moRuleDefinitionObject.ruleSets.length ; i>this.moFocusedPanelIndex ; i-- ) {
		this.drawOneTab(i,tabwidth,false);
	}
	// draw focused tab
	this.drawOneTab(this.moFocusedPanelIndex,tabwidth,true);
	// draw the base line, there are 2 sections
	if (svg.document) {
		var line =svg.document.createElementNS(SVGNS,'line');
		line.setAttribute("x1",0);
		line.setAttribute("y1",TABAREAHEIGHT);
		line.setAttribute("x2",(this.moFocusedPanelIndex+1)*(tabwidth-TABOVERLAP));
		line.setAttribute("y2",TABAREAHEIGHT);
		line.setAttribute("style","stroke:#888888; fill:#888888");
		zen("svgTabArea").svgGroup.appendChild(line);
		var line =svg.document.createElementNS(SVGNS,'line');
		line.setAttribute("x1",(this.moFocusedPanelIndex+1)*(tabwidth-TABOVERLAP)+tabwidth);
		line.setAttribute("y1",TABAREAHEIGHT);
		line.setAttribute("x2",zenGetWindowWidth());
		line.setAttribute("y2",TABAREAHEIGHT);
		line.setAttribute("style","stroke:#888888; fill:#888888");
		zen("svgTabArea").svgGroup.appendChild(line);
	}
	return;
}

ClientMethod drawOneTab(index, tabwidth, isActive) [ Language = javascript ]
{
	var TABAREAHEIGHT = parseInt(this.TABAREAHEIGHT);
	var TABHEIGHT = parseInt(this.TABHEIGHT);
	var TEXTVOFFSET = parseInt(this.TEXTVOFFSET);
	var TABRADIUS = parseInt(this.TABRADIUS);
	var TABTOPREDUCTION = parseInt(this.TABTOPREDUCTION);
	var TABTEXTMARGIN = parseInt(this.TABTEXTMARGIN);
	var TABOVERLAP = parseInt(this.TABOVERLAP);
	var svg = zen("svgTabArea");

	// Last index # = numberOfRules since ruleSets array starts at 0
	var numberOfRules = this.moRuleDefinitionObject.ruleSets.length;

	var name = ((index === -1)||(index === numberOfRules)) ? "" : this.moRuleDefinitionObject.ruleSets[index].name
	var caption = (index === -1) ? $$$Text("general") : ((index === numberOfRules) ? $$$Text("test") : $$$Text("ruleSet:") + " " + (name!="" ? name : "(#"+(index+1)+")"));
	var x = (index+1)*(tabwidth-TABOVERLAP);

	var group = svg.document.createElementNS(SVGNS,'g');
	group.setAttribute("onclick","zenPage.tabClicked("+index+");");
	svg.svgGroup.appendChild(group);

	var path = svg.document.createElementNS(SVGNS,'path');
	if ( isActive ) {
		path.setAttribute('class','rectTabFocused');
	} else {
		path.setAttribute('class','rectTabBack');
	}
	d = "M " + x + " " + (TABAREAHEIGHT);
	d = d + " A " + TABRADIUS + " " + TABRADIUS + " 0 0 0 " + (x+(TABTOPREDUCTION)/4) + " " + (TABAREAHEIGHT-TABHEIGHT/2);
	d = d + " A " + TABRADIUS + " " + TABRADIUS + " 1 0 1 " + (x+(TABTOPREDUCTION)/2) + " " + (TABAREAHEIGHT-TABHEIGHT);
	d = d + " h " + (tabwidth-TABTOPREDUCTION);
	d = d + " A " + TABRADIUS + " " + TABRADIUS + " 1 0 1 " + (x+tabwidth-(TABTOPREDUCTION)/4) + " " + (TABAREAHEIGHT-TABHEIGHT/2);
	d = d + " A " + TABRADIUS + " " + TABRADIUS + " 0 0 0 " + (x+tabwidth) + " " + (TABAREAHEIGHT);
	path.setAttribute('d',d);
	group.appendChild(path);

	var textValue = svg.document.createElementNS(SVGNS,'text');
	textValue.setAttribute("y",TABAREAHEIGHT-TABHEIGHT+TEXTVOFFSET+3);
	textValue.setAttribute("class","textTab");
	textValue.appendChild(svg.document.createTextNode(caption));
	group.appendChild(textValue);
	textValue.setAttribute("x",x+TABTEXTMARGIN);

	var clipRect = svg.document.getElementById("clipRect_"+(index+1));
	if ( clipRect == null ) {
		var clipDefs = svg.document.createElementNS(SVGNS,'defs');
		var clipPath = svg.document.createElementNS(SVGNS,'clipPath');
		clipPath.setAttribute("id","clipPath_"+(index+1));
		clipRect = svg.document.createElementNS(SVGNS,'rect');
		clipRect.setAttribute("id","clipRect_"+(index+1));
		clipPath.appendChild(clipRect);
		clipDefs.appendChild(clipPath);
		svg.svgGroup.appendChild(clipDefs);
	}
	clipRect.setAttribute("x",x+TABTEXTMARGIN);
	clipRect.setAttribute("y",TABAREAHEIGHT-TABHEIGHT);
	clipRect.setAttribute("height",TABHEIGHT);
	clipRect.setAttribute("width",tabwidth-TABTEXTMARGIN*2);
	textValue.setAttribute("clip-path","url(#clipPath_"+(index+1)+")");

	return;
}

ClientMethod drawRuleDefinition() [ Language = javascript ]
{
	var svgPanelDiv = zen("svgPanel").getEnclosingDiv();
	var headerPanelDiv = zen("headerPanel").getEnclosingDiv();
	var headerBlockDiv = zen("headerBlock").getEnclosingDiv();
	if ( this.moFocusedPanelIndex === -1 ) {

		this.drawTestPanel(false);
		if (zenIsHTML5) {
			headerPanelDiv.style.height = "";
			svgPanelDiv.style.height = "0px";
		}
		else {
			headerPanelDiv.style.display = "block";
		}
		headerPanelDiv.style.overflow = "";
		headerBlockDiv.style.display = "block";
		headerBlockDiv.style.padding = "10px";
		svgPanelDiv.style.overflow = "hidden";

			zenPage.drawRuleHeader();
	} else if ( this.moFocusedPanelIndex === this.moRuleDefinitionObject.ruleSets.length ) {

		// From drawRuleDefinition
		headerBlockDiv.style.display = "none";

		if (zenIsHTML5) {
			headerPanelDiv.style.height = "0px";
			svgPanelDiv.style.height = "0px";
		}

		headerPanelDiv.style.overflow = "hidden";
		svgPanelDiv.style.overflow = "hidden";

		this.drawTestPanel(true);

	} else {

		this.drawTestPanel(false);

		headerBlockDiv.style.display = "none";
		svgPanelDiv.style.overflow = "";
		if (zenIsHTML5) {
			headerPanelDiv.style.height = "0px";
			svgPanelDiv.style.height = "";
		}
		headerPanelDiv.style.overflow = "hidden";
		this.drawRuleSet(false);
	}
	this.drawTabs();
	return;
}

ClientMethod drawRuleType() [ Language = javascript ]
{
	if ( this.moRuleDefinitionObject == null ) return;

	zen("headerRuleTypeCombo").setValue(this.moRuleDefinitionObject.ruleType);
	zen("headerAssistClassCombo").setValue(this.moRuleDefinitionObject.assistClass);
	zen("headerContext").setValue(this.moRuleDefinitionObject.context);
	zen("headerContext").setProperty("disabled",( (!this.canEdit)||(this.readOnly)||(!this.moRuleDefinitionObject.contextEditable) ));
	zen("headerProduction").setValue(this.moRuleDefinitionObject.production);
	zen("headerProduction").setHidden(!this.moRuleDefinitionObject.isRoutingRule);
	return;
}

ClientMethod drawRuleSetsTable() [ Language = javascript ]
{
	if ( this.moRuleDefinitionObject == null ) return;

	var TABLEROWHEIGHT = parseInt(this.TABLEROWHEIGHT);
	var TABLEYSPACING = parseInt(this.TABLEYSPACING);
	var panel = zen('htmlPanel');
	var html = new Array();

	var svgWidth = document.getElementById("headerTop").offsetWidth+5;

	zen("emptyBar").getEnclosingDiv().style.display = "block";
	zen("textBar").getEnclosingDiv().style.display = "none";
	zen("xyzBar").getEnclosingDiv().style.display = "none";
	this.updateButtons();
	this.updateMenuAdd();
	this.updateHelpPanel();

	// remove all children
	svg = zen("svgTable");
	for ( var child = svg.svgGroup.firstChild; child != null ; child = svg.svgGroup.firstChild ) {
		svg.svgGroup.removeChild(child);
	}

	this.dragObjects = new Array();
	this.drawTableRow(-1,svgWidth,"ruleSet name","beginning date and time","ending date and time");
	for ( var i=0 ; i<this.moRuleDefinitionObject.ruleSets.length ; i++ ) {
		this.dragObjects[i] = new Array();
		this.drawTableRow(i,svgWidth,this.moRuleDefinitionObject.ruleSets[i].name,this.moRuleDefinitionObject.ruleSets[i].effectiveBegin,this.moRuleDefinitionObject.ruleSets[i].effectiveEnd);
	}

	zen("svgTable").setProperty("height",(this.moRuleDefinitionObject.ruleSets.length+1)*(TABLEROWHEIGHT+TABLEYSPACING)+4);
	zen("svgTable").setProperty("width",svgWidth);

	return;
}

ClientMethod drawRuleHeader() [ Language = javascript ]
{
	if ( this.moRuleDefinitionObject == null ) return;

	zen("headerDescription").setValue(this.moRuleDefinitionObject.description);
	zen("headerAlias").setValue(this.moRuleDefinitionObject.alias);
	var variableList = new Array();
	for ( var i=0 ; i<this.moRuleDefinitionObject.variables.length ; i++ ) {
		variableList[i] = this.moRuleDefinitionObject.variables[i].name;
	}
	zen("headerVariables").setValue(variableList.join(","));

	this.drawRuleType();
	this.drawRuleSetsTable();
	return;
}

ClientMethod drawTestPanel(show) [ Language = javascript ]
{
	var barDiv = zen('bar').getEnclosingDiv();
	var helpPanelDiv = zen('helpPanel').getEnclosingDiv();
	var testPanelDiv = zen("testPanel").getEnclosingDiv();

	if (show) {
		document.body.style.overflow = "visible";
		barDiv.style.display = "none";
		helpPanelDiv.style.display = "none";
		testPanelDiv.style.display = "";

	} else if (testPanelDiv.style.display === "") {
		document.body.style.overflow = "hidden";
		barDiv.style.display = "";
		helpPanelDiv.style.display = "";
		testPanelDiv.style.display = "none";

	}
}

ClientMethod ruleTypeChanged() [ Language = javascript ]
{
	var answer = confirm($$$Text("If you change the type of an existing rule, the expressions it contains may no longer work.") + "\n" + $$$Text("Do you want to proceed?"));
	if ( answer ) {
		this.moRuleDefinitionObject.ruleType = zen("headerRuleTypeCombo").getValue();
		for ( var i=0 ; i<this.moAssistClassArray.length ; i++ ) {
			if ( this.moAssistClassArray[i].ruleType === this.moRuleDefinitionObject.ruleType ) {
				this.moRuleDefinitionObject.assistClass = this.moAssistClassArray[i].assistClass;
				if ( this.moAssistClassArray[i].contextClass != "" ) {
					this.moRuleDefinitionObject.context = this.moAssistClassArray[i].contextClass;
				}
				this.moRuleDefinitionObject.contextEditable = (this.moAssistClassArray[i].contextClass==="");
				this.moRuleDefinitionObject.hasConstraints = this.moAssistClassArray[i].hasConstraints;
				this.moRuleDefinitionObject.isRoutingRule = this.moAssistClassArray[i].isRoutingRule;
				this.moRuleDefinitionObject.hasSegments = this.moAssistClassArray[i].hasSegments;
				break;
			}
		}
		this.undoStackPush(true);
		this.drawRuleType();
	} else {
		zen("headerRuleTypeCombo").setValue(this.moRuleDefinitionObject.ruleType);
	}
	return;
}

ClientMethod ruleAssistClassChanged() [ Language = javascript ]
{
	var answer = confirm($$$Text("If you change the assist class of an existing rule, the expressions it contains may no longer work.") + "\n" + $$$Text("Do you want to proceed?"));
	if ( answer ) {
		this.moRuleDefinitionObject.assistClass = zen("headerAssistClassCombo").getValue();
		var found = false;
		for ( var i=0 ; i<this.moAssistClassArray.length ; i++ ) {
			if ( this.moAssistClassArray[i].assistClass === this.moRuleDefinitionObject.assistClass ) {
				this.moRuleDefinitionObject.ruleType = this.moAssistClassArray[i].ruleType;
				if ( this.moAssistClassArray[i].contextClass != "" ) {
					this.moRuleDefinitionObject.context = this.moAssistClassArray[i].contextClass;
				}
				this.moRuleDefinitionObject.contextEditable = (this.moAssistClassArray[i].contextClass==="");
				this.moRuleDefinitionObject.hasConstraints = this.moAssistClassArray[i].hasConstraints;
				this.moRuleDefinitionObject.isRoutingRule = this.moAssistClassArray[i].isRoutingRule;
				this.moRuleDefinitionObject.hasSegments = this.moAssistClassArray[i].hasSegments;
				found = true;
				break;
			}
		}
		if ( !found ) {
			var info = this.GetRuleAssistInfo(this.moRuleDefinitionObject.assistClass);
			var infoArray = new Array; infoArray = info.split(":");
			this.moRuleDefinitionObject.ruleType = infoArray[1];
			if ( infoArray[0] != "" ) {
				this.moRuleDefinitionObject.context = infoArray[0];
			}
			this.moRuleDefinitionObject.contextEditable = (infoArray[0]==="");
			this.moRuleDefinitionObject.hasConstraints = infoArray[2];
			this.moRuleDefinitionObject.isRoutingRule = infoArray[3];
			this.moRuleDefinitionObject.hasSegments = infoArray[4];
		}
		this.clearConstraintCache();
		this.undoStackPush(true);
		this.drawRuleType();
	} else {
		zen("headerAssistClassCombo").setValue(this.moRuleDefinitionObject.assistClass);
	}
	return;
}

ClassMethod GetRuleAssistList(ByRef pParameters As %String, Output pObject) As %Status
{
	Set pObject = ##class(%ZEN.proxyObject).%New()
	Set tClassList = ##class(%Library.ListOfDataTypes).%New()
	Set tTypeList = ##class(%Library.ListOfDataTypes).%New()
	Set tItemList = ##class(%Library.ListOfObjects).%New()
	Set pObject.classList = tClassList
	Set pObject.typeList = tTypeList
	Set pObject.itemList = tItemList
	Set tCount = 0
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition:SubclassOf")
	Do tRS.Execute("Ens.Rule.Assist")
	While (tRS.Next()) {
		set tClassname = tRS.GetData(1)
		set tIsHidden = $classmethod(tClassname,"IsHidden")
		if tIsHidden continue
		set tDescription = $classmethod(tClassname,"GetDescription")
		set tCount = tCount + 1
		set tItem = ##class(%ZEN.proxyObject).%New()
		set tItem.assistClass = tClassname
		set tItem.ruleType = tDescription
		set tItem.contextClass = $classmethod(tClassname,"GetContextClass")
		set tItem.hasConstraints = ($classmethod(tClassname,"GetMetaData")'="")
		set tItem.isRoutingRule = $classmethod(tClassname,"GetIsRoutingRule")
		Set tItem.hasSegments = $classmethod(tClassname,"GetIsSegmentedDoc")
		do tItemList.Insert(tItem)
		do tClassList.Insert(tClassname)
		do tTypeList.Insert(tDescription)
	}
	Do tRS.Close()
	quit $$$OK
}

ClassMethod GetRuleAssistInfo(pClassname) As %String [ ZenMethod ]
{
	try {
		set tDescription = $classmethod(pClassname,"GetDescription")
		set tContextClass = $classmethod(pClassname,"GetContextClass")
		set tHasConstraints = ($classmethod(pClassname,"GetMetaData")'="")
		set tIsRoutingRule = $classmethod(pClassname,"GetIsRoutingRule")
		Set tHasSegments = $classmethod(pClassname,"GetIsSegmentedDoc")
		set info = tContextClass_":"_tDescription_":"_tHasConstraints_":"_tIsRoutingRule_":"_tHasSegments
	} catch {
		set info=":(unknown)"
	}
	quit info
}

ClientMethod variablesChanged(newlist) [ Language = javascript ]
{
	this.moRuleDefinitionObject.variables = new Array();
	var variableList = newlist.split(',');
	for ( var i=0 ; i<variableList.length ; i++ ) {
		this.moRuleDefinitionObject.variables[i] = new Object();
		this.moRuleDefinitionObject.variables[i]._class = "Ens.Rule.Model.variable";
		this.moRuleDefinitionObject.variables[i].name = variableList[i];
	}
	zenPage.undoStackPush(true);
}

ClientMethod drawTableRow(count, width, name, begin, end) [ Language = javascript ]
{
	var TABLEROWHEIGHT = parseInt(this.TABLEROWHEIGHT);
	var TABLECOLWIDTH = parseInt(this.TABLECOLWIDTH);
	var TABLEHEADCOLMINWIDTH = parseInt(this.TABLEHEADCOLMINWIDTH);
	var TABLEXSPACING = parseInt(this.TABLEXSPACING);
	var TABLEXMARGIN = parseInt(this.TABLEXMARGIN);
	var TABLEYSPACING = parseInt(this.TABLEYSPACING);
	var svg = zen("svgTable");

	// 1st col, the row counter
	var headWidth = TABLEROWHEIGHT;
	var caption = (count===-1) ? "" : (count+1);
	var classsuffix = (count===-1) ? "Header" : "Row";
	var y = (count+1)*(TABLEROWHEIGHT+TABLEYSPACING);
	var x = TABLEXMARGIN;
	this.drawTableCell(count,x,y,headWidth,TABLEROWHEIGHT,caption,classsuffix,false,false);

	// 2nd col, the drag handle
	x = x + TABLEROWHEIGHT+TABLEXSPACING;
	this.imagePositionX = x;
	if ( count === -1 ) {
		this.drawTableCell(count,x,y,TABLEROWHEIGHT,TABLEROWHEIGHT,"",classsuffix,false,false);
	} else {
		var image = svg.document.createElementNS(SVGNS,'image');
		image.setAttribute("x",x);
		image.setAttribute("y",y);
		image.setAttribute("stroke","black");
		image.setAttribute("stroke-width","2");
		image.setAttribute("height",TABLEROWHEIGHT);
		image.setAttribute("width",TABLEROWHEIGHT);
		image.setAttributeNS("http://www.w3.org/1999/xlink","xlink:href","rule/drag_handle.png");
		image.setAttribute("onmousedown","zenPage.onmousedown(evt);");
		svg.svgGroup.appendChild(image);
		this.dragObjects[count][this.dragObjects[count].length]=image;
	}

	// 3rd col, the name of the ruleSet
	var headWidth = width - (TABLECOLWIDTH+TABLEXSPACING)*2 - (TABLEROWHEIGHT+TABLEXSPACING)*2 - TABLEXMARGIN -1;
	headWidth = Math.max(headWidth,TABLEHEADCOLMINWIDTH);
	var classsuffix = (count===-1) ? "Header" : "Row";
	var y = (count+1)*(TABLEROWHEIGHT+TABLEYSPACING);
	x = x + TABLEROWHEIGHT+TABLEXSPACING;
	if ( name === "" ) { name = "(not specified)"; }
	this.drawTableCell(count,x,y,headWidth,TABLEROWHEIGHT,name,classsuffix,true,this.canEdit&&!this.readOnly);

	// 4th col, begin date and time
	x = x + headWidth+TABLEXSPACING;
	if ( begin === "" ) { begin = "(not specified)"; }
	this.drawTableCell(count,x,y,TABLECOLWIDTH,TABLEROWHEIGHT,begin,classsuffix,true,this.canEdit&&!this.readOnly);

	// 5th col, end date and time
	x = x + TABLECOLWIDTH+TABLEXSPACING;
	if ( end === "" ) { end = "(not specified)"; }
	this.drawTableCell(count,x,y,TABLECOLWIDTH,TABLEROWHEIGHT,end,classsuffix,true,this.canEdit&&!this.readOnly);

	return;
}

ClientMethod drawTableCell(count, x, y, width, height, caption, classsuffix, focusable, dragable) [ Language = javascript ]
{
	var TABLETEXTVOFFSET = parseInt(this.TABLETEXTVOFFSET);
	var TABLEXPADDING = parseInt(this.TABLEXPADDING);
	var svg = zen("svgTable");

	if ( focusable && (count===this.moFocusedRuleSetIndex) ) classsuffix = classsuffix + "Focused";

	var rect = svg.document.createElementNS(SVGNS,'rect');
	rect.setAttribute("x",x);
	rect.setAttribute("y",y);
	rect.setAttribute("height",height);
	rect.setAttribute("width",width);
	rect.setAttribute("id",count);
	if ( count!=-1) this.addClickHandler(rect,'objectClicked');
	rect.setAttribute("class","rectTable"+classsuffix);
	svg.svgGroup.appendChild(rect);
	if ( (count!=-1)&&(dragable) ) this.dragObjects[count].push(rect);

	var text = svg.document.createElementNS(SVGNS,'text');
	text.setAttribute("x",x+TABLEXPADDING);
	text.setAttribute("y",y+TABLETEXTVOFFSET);
	text.setAttribute("id",count);
	if ( count!=-1) this.addClickHandler(text,'objectClicked');
	text.setAttribute("class","textTable"+classsuffix);
	text.appendChild(svg.document.createTextNode(caption));
	svg.svgGroup.appendChild(text);
	if ( (count!=-1)&&(dragable) ) this.dragObjects[count].push(text);

	return;
}

ClientMethod onmousedown(event) [ Language = javascript ]
{
	if (!event) event = window.event;
	var svg = zen("svgTable");
	this.dragIndex = null;
	for ( var i=0 ; i<this.dragObjects.length ; i++ ) {
		if ( this.dragObjects[i][0] === event.target ) {
			this.dragIndex = i;
			break;
		}
	}
	// don't allow drag events if the user can't edit
	if (( this.dragIndex == null ) || ( !this.canEdit ) || this.readOnly) return (ZLM.killEvent(event));

	if ( this.moFocusedRuleSetIndex != this.dragIndex ) {
		if ( this.moFocusedRuleSetIndex != null ) {
			for ( var i=0 ; i<this.dragObjects[this.moFocusedRuleSetIndex].length ; i++ ) {
				var currObj = this.dragObjects[this.moFocusedRuleSetIndex][i];
				var currObjClass = currObj.getAttribute("class");
				if ( currObjClass != null ) {
					currObj.setAttribute("class",currObjClass.replace(/Focused/,""));
				}
			}
		}
		this.moFocusedRuleSetIndex = this.dragIndex;
		for ( var i=0 ; i<this.dragObjects[this.moFocusedRuleSetIndex].length ; i++ ) {
			var currObj = this.dragObjects[this.moFocusedRuleSetIndex][i];
			var currObjClass = currObj.getAttribute("class");
			if ( (currObjClass  != "") && ( currObjClass != null ) ) {
				currObj.setAttribute("class",currObjClass+"Focused");
			}
		}
	}

	this.dragOffsetX = event.target.getAttribute("x") - event.clientX;
	this.dragOffsetY = event.target.getAttribute("y") - event.clientY;

	if (zenIsHTML5) { // assign via functions for new browsers
		svg.svgGroup.onmouseup = function(evt) { zenPage.onmouseup(evt); };
		svg.svgGroup.onmousemove = function(evt) { zenPage.onmousemove(evt); };
		svg.svgGroup.onmouseout = function(evt) { zenPage.onmouseout(evt); };
	}
	else { // use attributes for IE8 and older
		svg.svgGroup.setAttribute("onmouseup","zenPage.onmouseup(evt);");
		svg.svgGroup.setAttribute("onmousemove","zenPage.onmousemove(evt);");
		svg.svgGroup.setAttribute("onmouseout","zenPage.onmouseout(evt);");
	}

	for ( var i=0 ; i<this.dragObjects[this.dragIndex].length ; i++ ) {
		svg.svgGroup.removeChild(this.dragObjects[this.dragIndex][i]);
		svg.svgGroup.appendChild(this.dragObjects[this.dragIndex][i]);
	}

	return (ZLM.killEvent(event));
}

ClientMethod onmousemove(event) [ Language = javascript ]
{
	var TABLEROWHEIGHT = parseInt(this.TABLEROWHEIGHT);
	var TABLEYSPACING = parseInt(this.TABLEYSPACING);

	if ( this.dragIndex == null ) return;
	if (this.readOnly || !this.canEdit) { return; }

	var imageX = this.dragObjects[this.dragIndex][0].getAttribute("x");
	var imageY = this.dragObjects[this.dragIndex][0].getAttribute("y");
	for ( var i=0 ; i<this.dragObjects[this.dragIndex].length ; i++ ) {
		var thisObject = this.dragObjects[this.dragIndex][i];
		var offsetX = thisObject.getAttribute("x")-imageX;
		this.dragObjects[this.dragIndex][i].setAttribute("x",event.clientX+this.dragOffsetX+offsetX);
		var offsetY = thisObject.getAttribute("y")-imageY;
		this.dragObjects[this.dragIndex][i].setAttribute("y",event.clientY+this.dragOffsetY+offsetY);
	}

	var middle = (this.dragIndex)*(TABLEROWHEIGHT+TABLEYSPACING)+TABLEROWHEIGHT/2;
	if ( (this.dragIndex>0) && (event.clientY+this.dragOffsetY < middle ) ) {
		var dragObjects = this.dragObjects[this.dragIndex];
		this.dragObjects.splice(this.dragIndex,1);
		this.dragObjects.splice(parseInt(this.dragIndex)-1,0,dragObjects);
		var ruleSet = this.moRuleDefinitionObject.ruleSets[this.dragIndex];
		this.moRuleDefinitionObject.ruleSets.splice(this.dragIndex,1);
		this.moRuleDefinitionObject.ruleSets.splice(parseInt(this.dragIndex)-1,0,ruleSet);
		for ( var i=0 ; i<this.dragObjects[this.dragIndex-1].length ; i++ ) {
			this.dragObjects[this.dragIndex][i].setAttribute("y",parseInt(this.dragObjects[this.dragIndex][i].getAttribute("y"))+TABLEROWHEIGHT+TABLEYSPACING);
		}
		this.dragIndex = this.dragIndex-1;
		this.moFocusedRuleSetIndex = this.moFocusedRuleSetIndex-1;
		for ( var i=this.dragIndex ; i<this.dragIndex+2 ; i++ ) {
			for ( var j=1 ; j<this.dragObjects[i].length ; j++ ) {
				this.dragObjects[i][j].setAttribute("id",i);
			}
		}
		this.undoStackPush(true);
	}

	var middle = (this.dragIndex+2)*(TABLEROWHEIGHT+TABLEYSPACING)-TABLEROWHEIGHT/2;
	if ( (this.dragIndex<(this.dragObjects.length-1)) && (event.clientY+this.dragOffsetY > middle ) ) {
		var dragObjects = this.dragObjects[this.dragIndex];
		this.dragObjects.splice(this.dragIndex,1);
		this.dragObjects.splice(parseInt(this.dragIndex)+1,0,dragObjects);
		var ruleSet = this.moRuleDefinitionObject.ruleSets[this.dragIndex];
		this.moRuleDefinitionObject.ruleSets.splice(this.dragIndex,1);
		this.moRuleDefinitionObject.ruleSets.splice(parseInt(this.dragIndex)+1,0,ruleSet);
		for ( var i=0 ; i<this.dragObjects[this.dragIndex+1].length ; i++ ) {
			this.dragObjects[this.dragIndex][i].setAttribute("y",parseInt(this.dragObjects[this.dragIndex][i].getAttribute("y"))-TABLEROWHEIGHT-TABLEYSPACING);
		}
		this.dragIndex = this.dragIndex+1;
		this.moFocusedRuleSetIndex = this.moFocusedRuleSetIndex+1;
		for ( var i=this.dragIndex-1 ; i<this.dragIndex+1 ; i++ ) {
			for ( var j=1 ; j<this.dragObjects[i].length ; j++ ) {
				this.dragObjects[i][j].setAttribute("id",i);
			}
		}
		this.undoStackPush(true);
	}

	return;
}

ClientMethod onmouseup(event) [ Language = javascript ]
{
	if (!event) event = window.event;
	ZLM.killEvent(event);

	if ( this.dragIndex == null ) return;
	if (this.readOnly || !this.canEdit) { return; }
	this.stopDrag();
	return;
}

ClientMethod onmouseout(event) [ Language = javascript ]
{
	if (!event) event = window.event;
	if (zenIsHTML5) {
		// Make sure we ignore events from children of the main svg group
		var target = (window.event) ? event.srcElement : event.target;
		if (target.nodeName.toString().toUpperCase() != 'G') return;
		// check to see if the element is a child of the intended g element
		var checkElement = (event.relatedTarget) ? event.relatedTarget : event.toElement;
		var nodeName = checkElement.nodeName.toString().toUpperCase();
		while (checkElement && (checkElement != target) && (nodeName != 'SVG') && (nodeName != 'BODY')) {
			checkElement = checkElement.parentNode;
			if (checkElement) nodeName = checkElement.nodeName.toString().toUpperCase();
		}
		if (checkElement == target) return;
		// Not triggered from child element, so stop the drag
	}
	ZLM.killEvent(event);

	if ( this.dragIndex == null ) return;
	if (this.readOnly || !this.canEdit) { return; }
	this.stopDrag();
	return;
}

ClientMethod stopDrag() [ Language = javascript ]
{
	var TABLEROWHEIGHT = parseInt(this.TABLEROWHEIGHT);
	var TABLEYSPACING = parseInt(this.TABLEYSPACING);

	if (this.readOnly || !this.canEdit) { return; }
	var svg = zen('svgTable');
	var handlers = [ 'onmouseup', 'onmousemove', 'onmouseout' ];
	for (var i = 0; i < handlers.length; i++) {
		if (zenIsHTML5) {
			svg.svgGroup[handlers[i]] = null;
		}
		else {
			svg.svgGroup.setAttribute(handlers[i],'');
		}
	}

	var x = this.imagePositionX;
	var y = (this.dragIndex+1)*(TABLEROWHEIGHT+TABLEYSPACING);
	var imageX = this.dragObjects[this.dragIndex][0].getAttribute("x");
	var imageY = this.dragObjects[this.dragIndex][0].getAttribute("y");
	for ( var i=0 ; i<this.dragObjects[this.dragIndex].length ; i++ ) {
		var thisObject = this.dragObjects[this.dragIndex][i];
		var offsetX = thisObject.getAttribute("x")-imageX;
		thisObject.setAttribute("x",x+offsetX);
		var offsetY = thisObject.getAttribute("y")-imageY;
		thisObject.setAttribute("y",y+offsetY);
	}
	this.dragIndex = null;
	this.drawTabs();
	return;
}

ClientMethod drawRuleSet(skipLoseFocus) [ Language = javascript ]
{
	var SPACING = parseInt(this.SPACING);
	var BOXHEIGHT = parseInt(this.BOXHEIGHT);
	var endPoint = new EnsPortal_RuleEditor_point();
	var svg = zen("svgPanel");

	// remove all children
	for ( var child = svg.svgGroup.firstChild; child != null ; child = svg.svgGroup.firstChild ) {
		svg.svgGroup.removeChild(child);
	}
	if ( this.moMainMap ) delete this.moMainMap;

	this.moMainMap = new Array();
	this.moNextMainIndex = 0;
	this.moFocusedIndex = null;

	if ( this.moRuleDefinitionObject == null ) return;

	if ( !skipLoseFocus ) this.loseFocus();
	this.updateButtons();
	this.updateMenuAdd();
	this.updateHelpPanel();
	endPoint = this.drawData(svg,true,SPACING,SPACING,this.moRuleDefinitionObject.ruleSets[this.moFocusedPanelIndex],null,null,null,null,null);

	this.moMinWidth = (endPoint.x+SPACING)*svg.getProperty("zoom")/100;
	this.moMinHeight = (endPoint.y+SPACING)*svg.getProperty("zoom")/100;

	var svgLimit = 16383;
	var effectiveWidth = this.moMinWidth;
	var effectiveHeight = this.moMinHeight;
	var scaleSVG = (zenIsIE && (!zenIsHTML5) && ((effectiveWidth > svgLimit) || (effectiveHeight > svgLimit)));
	if (scaleSVG) {
		// handle Adobe plugin limitation of 16384px
		if (effectiveWidth < effectiveHeight) {
			effectiveHeight = svgLimit;
			effectiveWidth = parseInt((effectiveWidth / effectiveHeight) * svgLimit,10);
		}
		else {
			effectiveWidth = svgLimit;
			effectiveHeight = parseInt((effectiveHeight / effectiveWidth) * svgLimit,10);
		}
		svg.svgRoot.setAttribute('preserveAspectRatio','xMinYMin');
		svg.svgRoot.setAttribute('viewBox','0 0 '+this.moMinWidth+' '+this.moMinHeight);
	}
	else if (zenIsIE) {
		// ensure we remove the attributes if they are stale
		try { svg.svgRoot.removeAttribute('preserveAspectRatio'); }
		catch (ex) {}
		try { svg.svgRoot.removeAttribute('viewBox'); }
		catch (ex) {}
	}

	// add this background for trapping mouse click
	var rect = svg.document.createElementNS(SVGNS,'rect');
	rect.setAttribute("x",0);
	rect.setAttribute("y",0);
	rect.setAttribute("width",effectiveWidth);
	rect.setAttribute("height",effectiveHeight);
	rect.setAttribute("style","fill:white; stroke:white;");
	rect.setAttribute("onclick","zenPage.backgroundClicked()");
	svg.svgGroup.insertBefore(rect,svg.svgGroup.firstChild);

	var helpWid = this.helpVisible ? 300 : 40;
	var wwid = zenGetWindowWidth() - helpWid + 12;
	wwid = (wwid < 0 ? 0 : wwid);
	if (effectiveWidth < wwid) effectiveWidth = wwid - 20;

	svg.setProperty("height",effectiveHeight);
	svg.setProperty("width",effectiveWidth);

	return;
}

ClientMethod drawData(svg, isEnabled, x, y, pObject, pRuleObject, pParentObject, pParentArrayObject, pParentArrayIndex, pParentLoop) [ Language = javascript ]
{
	var BOXHEIGHT = parseInt(this.BOXHEIGHT);
	var HLINELENGTH = parseInt(this.HLINELENGTH);
	var HINDENT = parseInt(this.HINDENT);
	var SPACING = parseInt(this.SPACING);
	var FRAMEMARGIN = parseInt(this.FRAMEMARGIN);
	var VSIBLINGINDENT = 0;
	var VCHILDINDENT = 15;
	var RADIUS = parseInt(this.RADIUS);
	var anchorPoint = new EnsPortal_RuleEditor_point();
	var endPoint = new EnsPortal_RuleEditor_point();
	var p = new EnsPortal_RuleEditor_point();
	var drawHPathElbow = this.drawHPathElbow?1:0;

	if ( (this.optionDrawIfElse)&&(VSIBLINGINDENT>0) ) {
		VCHILDINDENT = VSIBLINGINDENT;
	}

	if ( pObject.type === "ruleSet" ) {
		pObject._ruleCounter = 0;
		p = this.drawTextBox(svg,isEnabled,x,y,pObject,"type",null,null,null,null,pObject.actions,null);
		this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
		p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"name",null,null,null,null,null,null);
		this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
		p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"effectiveBegin",null,null,null,null,null,null);
		this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
		p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"effectiveEnd",null,null,null,null,null,null);
		var xmax = p.x;
		var ylast = 0;
		for ( var i=0 ; i<pObject.actions.length ; i++ ) {
			var yboxmiddle = p.y+SPACING+BOXHEIGHT/2;
			ylast = p.y+SPACING;
			p = this.drawData(svg,isEnabled,x+HINDENT,p.y+SPACING,pObject.actions[i],null,pObject,pObject.actions,i,null);
			xmax = Math.max(xmax,p.x);
			this.drawHPath(svg,x+VCHILDINDENT,x+HINDENT,ylast+BOXHEIGHT/2);
			if ( pObject.actions[i].type === "rule" ) {
				this.drawPlusMinus(svg,x+VCHILDINDENT,ylast+BOXHEIGHT/2,pObject.actions[i]);
			}
		}
		if ( ylast>0 ) this.drawLine(svg,x+VCHILDINDENT,y+BOXHEIGHT,x+VCHILDINDENT,ylast+BOXHEIGHT/2-(RADIUS*drawHPathElbow));
		endPoint.x = xmax;
		endPoint.y = p.y;
	} else if ( pObject.type === "rule" ) {
		pParentObject._ruleCounter++;
		pObject._ruleCounter = 0;
		if ( !this.isRuleCollapsed(pObject) ) {
			// draw expanded
			var xmax = 0;
			var yprevious = 0;
			p.x=x;
			p.y=y+BOXHEIGHT;
			for ( var i=0 ; i<pObject.whens.length ; i++ ) {
				if ( (i>0)&&(VSIBLINGINDENT>0) ) this.drawLine(svg,x+SPACING+VSIBLINGINDENT+BOXHEIGHT/2,yprevious+BOXHEIGHT,x+SPACING+VSIBLINGINDENT+BOXHEIGHT/2,p.y+SPACING);
				yprevious = p.y+SPACING;
				p = this.drawData(svg,isEnabled&&(!pObject.disabled),x+SPACING+BOXHEIGHT/2,p.y+SPACING,pObject.whens[i],pObject,pObject,pObject.whens,i,pParentLoop);
				xmax = Math.max(xmax,p.x);
			}
			if ( pObject.otherwise ) {
				if ( (yprevious>0)&&(VSIBLINGINDENT>0) ) this.drawLine(svg,x+SPACING+VSIBLINGINDENT+BOXHEIGHT/2,yprevious+BOXHEIGHT,x+SPACING+VSIBLINGINDENT+BOXHEIGHT/2,p.y+SPACING);
				p = this.drawData(svg,isEnabled&&(!pObject.disabled),x+SPACING+BOXHEIGHT/2,p.y+SPACING,pObject.otherwise,pObject,pObject,null,null,pParentLoop);
				xmax = Math.max(xmax,p.x);
			}
			p2 = this.drawTextBox(svg,isEnabled,x,y,pObject,"type",pObject,pParentObject,pParentArrayObject,pParentArrayIndex,pObject.whens,null);
			this.drawLine(svg,p2.x,y+BOXHEIGHT/2,p2.x+HLINELENGTH,y+BOXHEIGHT/2);
			p2 = this.drawTextBox(svg,isEnabled,p2.x+HLINELENGTH,y,pObject,"name",pObject,null,null,null,null,null);
			this.drawLine(svg,p2.x,y+BOXHEIGHT/2,p2.x+HLINELENGTH,y+BOXHEIGHT/2);
			p2 = this.drawTextBox(svg,isEnabled,p2.x+HLINELENGTH,y,pObject,"disabled",pObject,null,null,null,null,null);
			if ( this.moRuleDefinitionObject.hasConstraints ) {
				this.constraintGetDisplay(pObject);
				this.drawLine(svg,p2.x,y+BOXHEIGHT/2,p2.x+HLINELENGTH,y+BOXHEIGHT/2);
				p2 = this.drawTextBox(svg,isEnabled,p2.x+HLINELENGTH,y,pObject,"constraint",pObject,null,null,null,null,null);
			}
			this.drawFrameBox(svg,x+BOXHEIGHT/2,y+BOXHEIGHT/2,Math.max(xmax,p2.x)-x+SPACING-BOXHEIGHT/2,p.y-y+SPACING-BOXHEIGHT/2,pObject.disabled);
			endPoint.x = Math.max(xmax,p2.x)+SPACING;
			endPoint.y = p.y+SPACING;
		} else {
			// draw collapsed
			p = this.drawTextBox(svg,isEnabled,x,y,pObject,"type",pObject,pParentObject,pParentArrayObject,pParentArrayIndex,pObject.whens,null);
			this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
			p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"name",pObject,pParentObject,pParentArrayObject,pParentArrayIndex,pObject.whens,null);
			this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
			p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"disabled",pObject,pParentObject,pParentArrayObject,pParentArrayIndex,pObject.whens,null);
			endPoint.x = p.x;
			endPoint.y = p.y;
		}
	} else if (pObject.type === "foreach" ) {
		pObject._ruleCounter = 0;
			var xmax = 0;
			var yprevious = 0;
			p.x=x;
			p.y=y+BOXHEIGHT;
			for ( var i=0 ; i<pObject.whens.length ; i++ ) {
				if ( (i>0)&&(VSIBLINGINDENT>0) ) this.drawLine(svg,x+SPACING+VSIBLINGINDENT+BOXHEIGHT/2,yprevious+BOXHEIGHT,x+SPACING+VSIBLINGINDENT+BOXHEIGHT/2,p.y+SPACING);
				yprevious = p.y+SPACING;
				p = this.drawData(svg,isEnabled,x+SPACING+BOXHEIGHT/2,p.y+SPACING,pObject.whens[i],pRuleObject,pObject,pObject.whens,i,pObject);
				xmax = Math.max(xmax,p.x);
			}
			if ( pObject.otherwise ) {
				if ( (yprevious>0)&&(VSIBLINGINDENT>0) ) this.drawLine(svg,x+SPACING+VSIBLINGINDENT+BOXHEIGHT/2,yprevious+BOXHEIGHT,x+SPACING+VSIBLINGINDENT+BOXHEIGHT/2,p.y+SPACING);
				p = this.drawData(svg,isEnabled,x+SPACING+BOXHEIGHT/2,p.y+SPACING,pObject.otherwise,pRuleObject,pObject,null,null,pObject);
				xmax = Math.max(xmax,p.x);
			}
			p2 = this.drawTextBox(svg,isEnabled,x,y,pObject,"type",pRuleObject,pParentObject,pParentArrayObject,pParentArrayIndex,pObject.whens,null);
			this.drawLine(svg,p2.x,y+BOXHEIGHT/2,p2.x+HLINELENGTH,y+BOXHEIGHT/2);
			p2 = this.drawTextBox(svg,isEnabled,p2.x+HLINELENGTH,y,pObject,"propertypath",pRuleObject,null,null,null,null,null);
			this.drawFrameBox(svg,x+BOXHEIGHT/2,y+BOXHEIGHT/2,Math.max(xmax,p2.x)-x+SPACING-BOXHEIGHT/2,p.y-y+SPACING-BOXHEIGHT/2,!isEnabled);
			endPoint.x = Math.max(xmax,p2.x)+SPACING;
			endPoint.y = p.y+SPACING;

	} else if ( pObject.type === "when" ) {
		pParentObject._ruleCounter++;
		pObject._ruleCounter = 0;
		p = this.drawTextBox(svg,isEnabled,x,y,pObject,"type",pRuleObject,pParentObject,pParentArrayObject,pParentArrayIndex,pObject.actions,pParentLoop);
		this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
		p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"condition",pRuleObject,null,null,null,null,pParentLoop);
		var xmax = p.x;
		var ylast = 0;
		for ( var i=0 ; i<pObject.actions.length ; i++ ) {
			ylast = p.y+SPACING;
			p = this.drawData(svg,isEnabled,x+HINDENT,p.y+SPACING,pObject.actions[i],pRuleObject,pObject,pObject.actions,i,pParentLoop);
			xmax = Math.max(xmax,p.x);
			this.drawHPath(svg,x+VCHILDINDENT,x+HINDENT,ylast+BOXHEIGHT/2);
			if ( pObject.actions[i].type === "rule" ) {
				this.drawPlusMinus(svg,x+VCHILDINDENT,ylast+BOXHEIGHT/2,pObject.actions[i]);
			}
		}
		if ( ylast>0 ) this.drawLine(svg,x+VCHILDINDENT,y+BOXHEIGHT,x+VCHILDINDENT,ylast+BOXHEIGHT/2-(RADIUS*drawHPathElbow));
		endPoint.x = xmax;
		endPoint.y = p.y;
	} else if ( pObject.type === "otherwise" ) {
		p = this.drawTextBox(svg,isEnabled,x,y,pObject,"type",pRuleObject,pParentObject,pParentArrayObject,pParentArrayIndex,pObject.actions,pParentLoop);
		var xmax = p.x;
		var ylast = 0;
		for ( var i=0 ; i<pObject.actions.length ; i++ ) {
			ylast = p.y+SPACING;
			p = this.drawData(svg,isEnabled,x+HINDENT,p.y+SPACING,pObject.actions[i],pRuleObject,pObject,pObject.actions,i,pParentLoop);
			xmax = Math.max(xmax,p.x);
			this.drawHPath(svg,x+VCHILDINDENT,x+HINDENT,ylast+BOXHEIGHT/2);
			if ( pObject.actions[i].type === "rule" ) {
				this.drawPlusMinus(svg,x+VCHILDINDENT,ylast+BOXHEIGHT/2,pObject.actions[i]);
			}
		}
		if ( ylast>0 ) this.drawLine(svg,x+VCHILDINDENT,y+BOXHEIGHT,x+VCHILDINDENT,ylast+BOXHEIGHT/2-(RADIUS*drawHPathElbow));
		endPoint.x = xmax;
		endPoint.y = p.y;
	} else if ( pObject.type === "assign" ) {
		p = this.drawTextBox(svg,isEnabled,x,y,pObject,"type",pRuleObject,pParentObject,pParentArrayObject,pParentArrayIndex,null,pParentLoop);
		this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
		p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"property",pRuleObject,null,null,null,null,pParentLoop);
		this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
		p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"equal",pRuleObject,null,null,null,null,pParentLoop);
		this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
		p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"value",pRuleObject,null,null,null,null,pParentLoop);
		endPoint.x = p.x;
		endPoint.y = p.y;

	} else if ( pObject.type === "return" ) {
		p = this.drawTextBox(svg,isEnabled,x,y,pObject,"type",pRuleObject,pParentObject,pParentArrayObject,pParentArrayIndex,null,pParentLoop);
		if ( !this.moRuleDefinitionObject.isRoutingRule ) {
			this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
			p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"value",pRuleObject,null,null,null,null,pParentLoop);
		}
		endPoint.x = p.x;
		endPoint.y = p.y;

	} else if ( pObject.type === "trace" ) {
		p = this.drawTextBox(svg,isEnabled,x,y,pObject,"type",pRuleObject,pParentObject,pParentArrayObject,pParentArrayIndex,null,pParentLoop);
		this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
		p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"value",pRuleObject,null,null,null,null,pParentLoop);
		endPoint.x = p.x;
		endPoint.y = p.y;

	} else if ( pObject.type === "debug" ) {
		p = this.drawTextBox(svg,isEnabled,x,y,pObject,"type",pRuleObject,pParentObject,pParentArrayObject,pParentArrayIndex,null,pParentLoop);
		this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
		p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"value",pRuleObject,null,null,null,null,pParentLoop);
		endPoint.x = p.x;
		endPoint.y = p.y;

	} else if ( pObject.type === "comment" ) {
		p = this.drawTextBox(svg,isEnabled,x,y,pObject,"type",pRuleObject,pParentObject,pParentArrayObject,pParentArrayIndex,null,pParentLoop);
		this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
		p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"text",pRuleObject,null,null,null,null,pParentLoop);
		endPoint.x = p.x;
		endPoint.y = p.y;

	} else if ( pObject.type === "send" ) {
		p = this.drawTextBox(svg,isEnabled,x,y,pObject,"type",pRuleObject,pParentObject,pParentArrayObject,pParentArrayIndex,null,pParentLoop);
		this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
		p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"transform",pRuleObject,null,null,null,null,pParentLoop);
		this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
		p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"target",pRuleObject,null,null,null,null,pParentLoop);
		endPoint.x = p.x;
		endPoint.y = p.y;

	} else if ( pObject.type === "delete" ) {
		p = this.drawTextBox(svg,isEnabled,x,y,pObject,"type",pRuleObject,pParentObject,pParentArrayObject,pParentArrayIndex,null,pParentLoop);
		endPoint.x = p.x;
		endPoint.y = p.y;

	} else if ( pObject.type === "delegate" ) {
		p = this.drawTextBox(svg,isEnabled,x,y,pObject,"type",pRuleObject,pParentObject,pParentArrayObject,pParentArrayIndex,null,pParentLoop);
		this.drawLine(svg,p.x,y+BOXHEIGHT/2,p.x+HLINELENGTH,y+BOXHEIGHT/2);
		p = this.drawTextBox(svg,isEnabled,p.x+HLINELENGTH,y,pObject,"ruleName",pRuleObject,null,null,null,null,pParentLoop);
		endPoint.x = p.x;
		endPoint.y = p.y;

	} else {
		p = this.drawTextBox(svg,isEnabled,x,y,pObject,"type",pRuleObject,pParentObject,pParentArrayObject,pParentArrayIndex,null,pParentLoop);
		endPoint.x = p.x;
		endPoint.y = p.y;
	}

	return endPoint;
}

ClientMethod drawTextBox(svg, isEnabled, x, y, jsonObject, jsonProperty, jsonRuleObject, jsonParentObject, jsonParentArrayObject, jsonParentArrayIndex, jsonChildrenArrayObject, jsonParentLoopObject) [ Language = javascript ]
{
	var BOXHEIGHT = parseInt(this.BOXHEIGHT);
	var TEXTVOFFSET = parseInt(this.TEXTVOFFSET);
	var TEXTMARGIN = parseInt(this.TEXTMARGIN);
	var RADIUS = parseInt(this.RADIUS);
	var caption;
	var classSuffix;
	var showProperty = this.showProperty;

	//
	// some minor adjustments to the display
	//
	// never show property for type and equal
	if ( (jsonProperty==="type")||(jsonProperty==="equal") ) {
		showProperty = false;
	}
	// set caption
	if ( jsonProperty==="equal" ) {
		caption = "=";
	} else if ( jsonProperty==="disabled" ) {
		var booleanValue = (jsonObject[jsonProperty] == null) ? "false" : jsonObject[jsonProperty];
		caption = showProperty ? String(booleanValue) : (booleanValue?"disabled":"enabled") ;
	} else {
		caption = String(jsonObject[jsonProperty]);
	}
	// display condition as "true" when using dummy condition of "1"
	if (( jsonProperty==="condition" ) && (caption==="1")) {
		caption = "true";
	}
	// set style Suffix
	if ( jsonProperty==="type" ) {
		classSuffix = caption.toUpperCase();
	} else if ( jsonProperty==="disabled" ) {
		var booleanValue = (jsonObject[jsonProperty] == null) ? "false" : jsonObject[jsonProperty];
		classSuffix = (booleanValue?"DISABLED":"ENABLED");
	} else {
		classSuffix = jsonProperty.toUpperCase();
	}
	// change when-otherwise to if-else
	if ( this.optionDrawIfElse ) {
		if ( caption==="when" ) caption = jsonParentArrayIndex===0 ? "if" : "else if";
		if ( caption==="otherwise" ) caption = "else";
	}

	// create group, rect and text
	var group = svg.document.createElementNS(SVGNS,'g');
	svg.svgGroup.appendChild(group);

	//
	// create base elements
	//
	if ( showProperty ) {
		var baseRect = svg.document.createElementNS(SVGNS,'rect');
		var baseText = svg.document.createElementNS(SVGNS,'text');
		var baseCover = svg.document.createElementNS(SVGNS,'rect');
		group.appendChild(baseRect);
		group.appendChild(baseText);
		group.appendChild(baseCover);
		// modify baseRect
		baseRect.setAttribute("x",x);
		baseRect.setAttribute("y",y);
		baseRect.setAttribute("rx",RADIUS);
		baseRect.setAttribute("height",BOXHEIGHT);
		baseRect.setAttribute("width",0);
		baseRect.setAttribute("class","rectBase");
		// modify baseText
		baseText.setAttribute("x",x+TEXTMARGIN);
		baseText.setAttribute("y",y+TEXTVOFFSET);
		baseText.setAttribute("class","textBase");
		baseText.appendChild(svg.document.createTextNode(jsonProperty));
		// modify baseCover
		baseCover.setAttribute("x",x);
		baseCover.setAttribute("y",y);
		baseCover.setAttribute("rx",RADIUS);
		baseCover.setAttribute("height",BOXHEIGHT);
		baseCover.setAttribute("width",0);
		baseCover.setAttribute("style","opacity:0.01");
		var computedBaseTextLength = jsonProperty==="" ? 0 : baseText.getComputedTextLength() + TEXTMARGIN*2;
	} else {
		var computedBaseTextLength = 0;
	}

	//
	// create value elements
	//
	var valueRect = svg.document.createElementNS(SVGNS,'rect');
	var valueText = svg.document.createElementNS(SVGNS,'text');
	var valueCover = svg.document.createElementNS(SVGNS,'rect');
	group.appendChild(valueRect);
	//group.appendChild(valueText);
	//group.appendChild(valueCover);
	// insert into the map
	var newIndex = this.insertMainMap(valueRect,valueText,jsonObject,jsonProperty,jsonRuleObject,jsonParentObject,jsonParentArrayObject,jsonParentArrayIndex,jsonChildrenArrayObject,jsonParentLoopObject);
	// modify group
	group.setAttribute("id",newIndex);
	this.addClickHandler(group,'objectClicked');

	//
	// add and draw valueText or Condition
	//
	var computedTextValueLength;
	var computedTextValueHeight;
	if ( (jsonProperty === "condition")&&(jsonObject.conditionObject.type != "value") ) {
		var p = this.drawCondition(svg,group,x+computedBaseTextLength+TEXTMARGIN,y+TEXTMARGIN,jsonObject.conditionObject)
		computedTextValueLength = p[0].x-(x+computedBaseTextLength+TEXTMARGIN);
		computedTextValueHeight = p[0].y-y+TEXTMARGIN;
	} else {
		group.appendChild(valueText);
		computedTextValueLength = 0;
		if ((caption === 'rule') || (caption === 'when')) {
			/* Geometry note: 	valueRect y-pos: 0 ~ 22
								numRect y-pos: 5 ~ 17
								valueText @11pt y-pos: 5 ~ 16
								numText @8pt y-pos: 7 ~ 15	*/
			var numLeftMargin = 4;
			var numTopMargin = 5;
			var numHeight = 12;
			var numWidthPad = 5;
			var numTextVOffset = 15;
			var rectClass = 'numRect';
			if ( this.moFocusedIndex === newIndex ) {
				rectClass += ' '+ 'numFocused';
			}
			var numRect = svg.document.createElementNS(SVGNS,'rect');
			group.appendChild(numRect);
			numRect.setAttribute('class',rectClass);
			numRect.setAttribute('y',y + numTopMargin);
			numRect.setAttribute('height',numHeight);
			numRect.setAttribute("rx",RADIUS/2);

			var numText = svg.document.createElementNS(SVGNS,'text');
			group.appendChild(numText);
			var currNumber = (jsonParentObject._ruleCounter ? jsonParentObject._ruleCounter : jsonParentArrayIndex + 1);
			numText.appendChild(svg.document.createTextNode(currNumber));
			numText.setAttribute('text-anchor','middle');
			var numTextLength = numText.getComputedTextLength();
			var numTextPos = x + numLeftMargin + (numTextLength/2);
			numText.setAttribute("x",numTextPos);
			numRect.setAttribute('x',x + (numLeftMargin/2));
			numRect.setAttribute('width',numTextLength + numWidthPad);
			numText.setAttribute("y",y + numTextVOffset);
			numText.setAttribute("class","text"+classSuffix+" numText");

			computedTextValueLength += numTextLength + 1; // add 1 space after

			var wrapperObject = this.moMainMap[newIndex];
			if (wrapperObject) {
				wrapperObject._svgNumRect = numRect;
				wrapperObject._svgNumText = numText;
			}
		}
		// modify valueText
		valueText.setAttribute("x",x + TEXTMARGIN + computedTextValueLength);
		valueText.setAttribute("y",y+TEXTVOFFSET);
		valueText.setAttribute("class","text"+classSuffix);
		valueText.appendChild(svg.document.createTextNode(caption));
		if ( showProperty ) {
			valueText.setAttribute("x",x+computedBaseTextLength+TEXTMARGIN);
		}
		if ( this.moFocusedIndex === newIndex ) {
			this.moFocusedOriginalTextClass = valueText.getAttribute("class");
			valueText.setAttribute("class","textFocused");
		}
		try { computedTextValueLength += caption==="" ? 0 : valueText.getComputedTextLength(); } catch(ex) { } // ignore errors on IE when caption contains punctuation only
		computedTextValueHeight = BOXHEIGHT;
	}

	// modify valueRect
	valueRect.setAttribute("x",x);
	valueRect.setAttribute("y",y);
	valueRect.setAttribute("rx",RADIUS);
	valueRect.setAttribute("height",computedTextValueHeight);
	valueRect.setAttribute("width",0);
	valueRect.setAttribute("class","rect"+classSuffix);
	if ( this.moFocusedIndex === newIndex ) {
		this.moFocusedOriginalRectClass = valueRect.getAttribute("class")
		valueRect.setAttribute("class","rectFocused");
	}
	// modify valueCover
	group.appendChild(valueCover);
	valueCover.setAttribute("x",x);
	valueCover.setAttribute("y",y);
	valueCover.setAttribute("rx",RADIUS);
	valueCover.setAttribute("height",computedTextValueHeight);
	valueCover.setAttribute("width",0);
	if ( isEnabled ) {
		valueCover.setAttribute("style","opacity:0.01");
	} else {
		valueCover.setAttribute("style","opacity:0.1");
	}

	var endPoint = new EnsPortal_RuleEditor_point();

	if ( showProperty ) {
		baseRect.setAttribute("width",computedBaseTextLength+computedTextValueLength+TEXTMARGIN*2);
		baseCover.setAttribute("width",computedBaseTextLength+computedTextValueLength+TEXTMARGIN*2);
		valueRect.setAttribute("x",x+computedBaseTextLength);
		valueRect.setAttribute("width",computedTextValueLength+TEXTMARGIN*2);
		valueCover.setAttribute("x",x+computedBaseTextLength);
		valueCover.setAttribute("width",computedTextValueLength+TEXTMARGIN*2);
		endPoint.x=x+computedBaseTextLength+computedTextValueLength+TEXTMARGIN*2;
		endPoint.y=y+computedTextValueHeight;
	} else {
		valueRect.setAttribute("width",computedTextValueLength+TEXTMARGIN*2);
		valueCover.setAttribute("width",computedTextValueLength+TEXTMARGIN*2);
		endPoint.x=x+computedTextValueLength+TEXTMARGIN*2;
		endPoint.y=y+computedTextValueHeight;
	}

	// add error symbol
	var errorText = this.getPropertyErrorText(jsonObject,jsonProperty);
	if ( errorText!="" ) {
		var errorGroup = svg.document.createElementNS(SVGNS,'g');;
		errorGroup.setAttribute("onclick","setTimeout(function(){alert('"+errorText+"');},0)");
	    var circle = svg.document.createElementNS(SVGNS,'circle');
	    circle.setAttribute('cx',endPoint.x);
	    circle.setAttribute('cy',y);
	    circle.setAttribute('r',6);
		circle.setAttribute('style','fill:red; stroke:red; ');
	    errorGroup.appendChild(circle);
		var text = svg.document.createElementNS(SVGNS,'text');
		text.setAttribute("x",endPoint.x-1);
		text.setAttribute("y",y+4);
		text.setAttribute("style","fill:white; stroke:none; font-family:arial; font-size:9pt; font-weight:bold;");
		text.appendChild(svg.document.createTextNode("!"));
	    errorGroup.appendChild(text);
	    group.appendChild(errorGroup);
	}

	// return endPoint
  	return endPoint;
}

ClientMethod drawCondition(svg, groupParent, x, y, pData) [ Language = javascript ]
{
	var BOXHEIGHT = parseInt(this.BOXHEIGHT);
	var HLINELENGTH = parseInt(this.HLINELENGTH);
	var HCINDENT = parseInt(this.HCINDENT);
	var SPACING = parseInt(this.SPACING);
	var anchorPoint = new EnsPortal_RuleEditor_point();
	var endPoint = new EnsPortal_RuleEditor_point();

	if ( pData.type === "value" ) {
		var p = this.drawConditionTextBox(svg,groupParent,x,y,pData,"value");
		anchorPoint.x = x;
		anchorPoint.y = y+BOXHEIGHT/2;
		endPoint.x=p.x;
		endPoint.y=p.y;
	} else {
		// draw the operator box
		var pointOperatorEnd = this.drawConditionTextBox(svg,groupParent,x,y,pData,"operator");
		var group = this.lastGroup;
		var xmax = 0;
		var ymover = y;
		var middle = new Array();
		var i, points, p, ap;
		var length = pData.operands.length;
		// draw the operands of the OR/AND first, indented
		for ( var i=0 ; i<length ; i++ ) {
			points = this.drawCondition(svg,groupParent,pointOperatorEnd.x+HCINDENT,ymover,pData.operands[i]);
			p = points[0];
			xmax = Math.max(xmax,p.x);
			middle[i] = points[1].y;
			ymover = p.y+SPACING;
		}
		ymover = ymover - SPACING;
		// initially set the center of the box to be middle between first and last child
		var ycenter = (middle[0]+middle[length-1])/2;
		// if the center of the box if slightly off wih one child, line up the center with this child's middle
		for ( i=0 ; i<length ; i++ ) {
			if ( (middle[i]>ycenter-BOXHEIGHT/2)&&(middle[i]<ycenter+BOXHEIGHT/2) ) {
				ycenter = middle[i];
				break;
			}
		}
		// move the operator box, center between the first and the last connector line
		for ( var child = group.firstChild; child != null ; child = child.nextSibling ) {
			child.setAttribute("y",parseInt(child.getAttribute("y"))-y+ycenter-BOXHEIGHT/2);
			child.setAttribute("cy",parseInt(child.getAttribute("cy"))-y+ycenter-BOXHEIGHT/2);
		}
		anchorPoint.x = x;
		anchorPoint.y = ycenter;
		// draw connector lines
		for ( i=0 ; i<length ; i++ ) {
			this.drawSpiderLine(svg,x,ycenter-BOXHEIGHT/2,pointOperatorEnd.x-x,BOXHEIGHT,pointOperatorEnd.x+HCINDENT,middle[i]);
		}
		endPoint.x=xmax;
		endPoint.y=ymover;
	}

	return [endPoint, anchorPoint];
}

ClientMethod drawConditionTextBox(svg, groupParent, x, y, jsonObject, jsonProperty, jsonParentObject, jsonParentArrayObject, jsonParentArrayIndex, jsonChildrenArrayObject) [ Language = javascript ]
{
	var BOXHEIGHT = parseInt(this.BOXHEIGHT);
	var TEXTVOFFSET = parseInt(this.TEXTVOFFSET);
	var TEXTMARGIN = parseInt(this.TEXTMARGIN);
	var RADIUS = parseInt(this.RADIUS);
	var caption = jsonObject[jsonProperty];
	var classSuffix = jsonProperty.toUpperCase();

	if ( jsonProperty==="operator" ) caption = (caption==="&&" ? "AND" : "OR");

	// create group, rect and text
	var group = svg.document.createElementNS(SVGNS,'g');
	group.setAttribute("class","rectCond"+classSuffix);
	var rect = svg.document.createElementNS(SVGNS,'rect');
	var text = svg.document.createElementNS(SVGNS,'text');

	// modify group
	group.appendChild(rect);
	group.appendChild(text);
	groupParent.appendChild(group);
	this.lastGroup = group;

	// modify rect
	rect.setAttribute("x",x);
	rect.setAttribute("y",y);
	rect.setAttribute("rx",RADIUS);
	rect.setAttribute("height",BOXHEIGHT);
	rect.setAttribute("width",0);
	rect.setAttribute("class","rectCond"+classSuffix);

	// modify text
	text.setAttribute("x",x+TEXTMARGIN);
	text.setAttribute("y",y+TEXTVOFFSET);
	text.setAttribute("class","textCond"+classSuffix);
	text.appendChild(svg.document.createTextNode(caption));

	// on IE, text.getComputedTextLength() crashes when caption===""
	var computedTextLength = caption==="" ? 0 : text.getComputedTextLength();

	// set rect width to the text width plus margins
	rect.setAttribute("width",computedTextLength+TEXTMARGIN*2);

	// compute endPoint
	var endPoint = new EnsPortal_RuleEditor_point();
	endPoint.x=x+computedTextLength+TEXTMARGIN*2;
	endPoint.y=y+BOXHEIGHT;

  	return endPoint;
}

ClientMethod getPropertyErrorText(jsonObject, jsonProperty) [ Language = javascript ]
{
	// Be sure to modify the contents of zenPage._validationData in onlayoutHandler() if any of the following validation checks change.
	switch(jsonObject.type) {
		case 'ruleSet':
		case 'rule':
		case 'otherwise':
		case 'return':
		case 'delete':
			return "";
		case 'foreach':
			if ( (jsonProperty==="propertypath")&&(jsonObject[jsonProperty]==="") ) return $$$Text("value is required");
			return "";
		case 'when':
			if ( (jsonProperty==="condition")&&(jsonObject[jsonProperty]==="") ) return $$$Text("value is required");
			return "";
		case 'assign':
			if ( (jsonProperty==="property")&&(jsonObject[jsonProperty]==="") ) return $$$Text("value is required");
			if ( (jsonProperty==="value")&&(jsonObject[jsonProperty]==="") ) return $$$Text("value is required");
			return "";
		case 'trace':
		case 'debug':
			if ( (jsonProperty==="value")&&(jsonObject[jsonProperty]==="") ) return $$$Text("value is required");
			return "";
		case 'send':
			if ( (jsonProperty==="target")&&(jsonObject[jsonProperty]==="") ) return $$$Text("value is required");
			return "";
		case 'delegate':
			if ( (jsonProperty==="ruleName")&&(jsonObject[jsonProperty]==="") ) return $$$Text("value is required");
			return "";
		case 'comment':
			if ( (jsonProperty==="text")&&(jsonObject[jsonProperty]==="") ) return $$$Text("value is required");
			return "";
		default:
			return "unknown type";
	}
}

ClientMethod drawFrameBox(svg, x, y, width, height, disabled) [ Language = javascript ]
{
	var RADIUS = parseInt(this.RADIUS);

	var rect = svg.document.createElementNS(SVGNS,'rect');
	rect.setAttribute("x",x);
	rect.setAttribute("y",y);
	rect.setAttribute("rx",RADIUS);
	rect.setAttribute("width",width);
	rect.setAttribute("height",height);
	if ( disabled ) {
		rect.setAttribute("style","stroke:#D0D0D0; fill:black; opacity:0.1;");
	} else {
		rect.setAttribute("style","stroke:#D0D0D0; fill:none;");
	}
	svg.svgGroup.insertBefore(rect,svg.svgGroup.firstChild);
  	return;
}

/// draw horizontal path, with a rounded elbow
ClientMethod drawHPath(svg, x1, x2, y) [ Language = javascript ]
{
	var RADIUS = parseInt(this.RADIUS);
	var drawHPathElbow = this.drawHPathElbow?1:0;

	if ( drawHPathElbow ) {
		d = "M " + x1 + " " + (y-RADIUS) + " A " + RADIUS + " " + RADIUS + " 0 0 0 " + (x1+RADIUS) + " " + y+ " H " + x2;
		var path = svg.document.createElementNS(SVGNS,'path');
		path.setAttribute('style','stroke: grey; fill:none; stroke-width: 1;');
		path.setAttribute('d',d);
	    svg.svgGroup.appendChild(path);
	} else {
		this.drawLine(svg,x1,y,x2,y);
		var circle = svg.document.createElementNS(SVGNS,'circle');
		circle.setAttribute('style','stroke:grey; fill:grey; stroke-width: 1;');
		circle.setAttribute('cx',x1);
		circle.setAttribute('cy',y);
		circle.setAttribute('r',RADIUS/2);
	    svg.svgGroup.appendChild(circle);
	}
	return;
}

/// draw the plus or minus for rule collapsing
ClientMethod drawPlusMinus(svg, cx, cy, object) [ Language = javascript ]
{
	var DOTRADIUS = parseInt(this.DOTRADIUS);

	var objectId = -1;
	for ( i=0 ; i<this.moMainMap.length ; i++ ) {
		if ( this.moMainMap[i].jsonObject === object ) objectId = i;
	}

	var group = svg.document.createElementNS(SVGNS,'g');
	if ( objectId > -1 ) {
		group.setAttribute("onclick","zenPage.collapseRule("+objectId+");");
	}
	group.setAttribute("z-index","100");
	svg.svgGroup.appendChild(group);

	if ( true ) {
		var circle = svg.document.createElementNS(SVGNS,'circle');
		circle.setAttribute('cx',cx);
		circle.setAttribute('cy',cy);
		circle.setAttribute('r',DOTRADIUS);
		circle.setAttribute('style','stroke:grey; fill:white; ');
		circle.setAttribute('id','dot-');
		group.appendChild(circle);
	} else {
		var rect = svg.document.createElementNS(SVGNS,'rect');
		rect.setAttribute('x',cx-DOTRADIUS);
		rect.setAttribute('y',cy-DOTRADIUS);
		rect.setAttribute('height',DOTRADIUS*2);
		rect.setAttribute('width',DOTRADIUS*2);
		rect.setAttribute('style','stroke:grey; fill:white; ');
		rect.setAttribute('id','dot-');
		group.appendChild(rect);
	}
	var line = svg.document.createElementNS(SVGNS,'line');
	line.setAttribute('x1',cx-DOTRADIUS*0.6);
	line.setAttribute('y1',cy);
	line.setAttribute('x2',cx+DOTRADIUS*0.6);
	line.setAttribute('y2',cy);
	line.setAttribute("style","fill:grey; stroke:grey; stroke-width:2;");
	group.appendChild(line);

	if ( this.isRuleCollapsed(object) ) {
		var line = svg.document.createElementNS(SVGNS,'line');
		line.setAttribute('x1',cx);
		line.setAttribute('y1',cy-DOTRADIUS*0.6);
		line.setAttribute('x2',cx);
		line.setAttribute('y2',cy+DOTRADIUS*0.6);
		line.setAttribute("style","fill:grey; stroke:grey; stroke-width:2;");
		group.appendChild(line);
	}
	return;
}

ClientMethod drawLine(svg, x1, y1, x2, y2, drawInFront) [ Language = javascript ]
{
    var line = svg.document.createElementNS(SVGNS,'line');
    line.setAttribute('x1',x1);
    line.setAttribute('y1',y1);
    line.setAttribute('x2',x2);
    line.setAttribute('y2',y2);
    line.setAttribute('style','stroke: grey; stroke-width: 1;');
	if ( drawInFront ) {
 		svg.svgGroup.appendChild(line);
	} else {
		svg.svgGroup.insertBefore(line,svg.svgGroup.firstChild);
	}
  	return;
}

/// we draw a connect line from a box to the target
/// the starting points can be the middle-top, middle-bottom or the right-middle
ClientMethod drawSpiderLine(svg, xbase, ybase, width, height, xtarget, ytarget) [ Language = javascript ]
{
	if ( ybase > ytarget ) {
		this.drawElbowLine(svg,xbase+width/2,ybase,xtarget,ytarget);
	} else if ( ybase+height < ytarget ) {
		this.drawElbowLine(svg,xbase+width/2,ybase+height,xtarget,ytarget);
	} else {
		this.drawLine(svg,xbase+width,ybase+height/2,xtarget,ytarget,true);
	}
  	return;
}

/// draw an elbow line between (x1,y1) and (x2,y2)
/// we assume x1<x2
ClientMethod drawElbowLine(svg, x1, y1, x2, y2) [ Language = javascript ]
{
	var RADIUS = parseInt(this.RADIUS);

	if ( y1 > y2 ) {
		d = "M " + x1 + " " + y1 + " V " + (y2+RADIUS) + " A " + RADIUS + " " + RADIUS + " 0 0 1 " + (x1+RADIUS) + " " + y2+ " H " + x2;
	} else {
		d = "M " + x1 + " " + y1 + " V " + (y2-RADIUS) + " A " + RADIUS + " " + RADIUS + " 0 0 0 " + (x1+RADIUS) + " " + y2+ " H " + x2;
	}
	var path = svg.document.createElementNS(SVGNS,'path');
	path.setAttribute('style','stroke: grey; fill:none; stroke-width: 1;');
	path.setAttribute('d',d);
	svg.svgGroup.appendChild(path);
	return;
}

ClientMethod insertMainMap(svgRectObject, svgTextObject, jsonObject, jsonProperty, jsonRuleObject, jsonParentObject, jsonParentArrayObject, jsonParentArrayIndex, jsonChildrenArrayObject, jsonParentLoopObject) [ Language = javascript ]
{
	var newIndex = this.moNextMainIndex++;
	this.moMainMap[newIndex] = new Object();
	this.moMainMap[newIndex].svgRectObject = svgRectObject;
	this.moMainMap[newIndex].svgTextObject = svgTextObject;
	this.moMainMap[newIndex].jsonObject = jsonObject;
	this.moMainMap[newIndex].jsonProperty = jsonProperty;
	this.moMainMap[newIndex].jsonRuleObject = jsonRuleObject;
	this.moMainMap[newIndex].jsonParentLoopObject = jsonParentLoopObject;
	this.moMainMap[newIndex].jsonParentObject = jsonParentObject;
	this.moMainMap[newIndex].jsonParentArrayObject = jsonParentArrayObject;
	this.moMainMap[newIndex].jsonParentArrayIndex = jsonParentArrayIndex;
	this.moMainMap[newIndex].jsonChildrenArrayObject = jsonChildrenArrayObject;
	if ( (jsonObject===this.moFocusedJsonObject[this.moFocusedPanelIndex])&&(jsonProperty===this.moFocusedJsonProperty[this.moFocusedPanelIndex]) ) {
		this.getFocus(newIndex);
		this.updateButtons();
		this.updateMenuAdd();
		this.updateHelpPanel();
	}
	return newIndex;
}

/// Collapse or expand a rule (flip state)
ClientMethod collapseRule(objectId) [ Language = javascript ]
{
	this.showMsgBox(true);
	setTimeout("zenPage.collapseRuleContd("+objectId+")",50);
}

ClientMethod collapseRuleContd(objectId) [ Language = javascript ]
{
	var object = this.moMainMap[objectId].jsonObject;
	var isCollapsed = false;
	var ruleNo = this.findRuleNo(object);
	if (ruleNo > -1) {
		var ruleStates = this.ruleStates;
		var state = ruleStates.substring(ruleNo+1,ruleNo+2);
		if (state == '1') {
			isCollapsed = true;
		}
		this.ruleStates = this.SaveRuleState(this.RULE,this.currentTab,ruleNo,!isCollapsed);
	}
	else {
		var object = this.moMainMap[objectId].jsonObject;
		var isCollapsed = false;
		for ( i=0 ; i<this.moCollapsedMap.length ; i++ ) {
			if ( this.moCollapsedMap[i] === object ) {
				this.moCollapsedMap.splice(i,1);
				isCollapsed = true;
				break;
			}
		}
		if ( !isCollapsed ) {
			this.moCollapsedMap.splice(this.moCollapsedMap.length,0,object);
		}
	}
	this.drawRuleSet(false);
	setTimeout("zenPage.showMsgBox(false)",200);
	return;
}

/// Return true if rule state is collapsed
ClientMethod isRuleCollapsed(object) [ Language = javascript ]
{
	var isCollapsed = false;
	var ruleNo = this.findRuleNo(object);
	if (ruleNo > -1) {
		var ruleStates = this.ruleStates;
		var state = ruleStates.substring(ruleNo+1,ruleNo+2);
		if (state == '1') {
			isCollapsed = true;
		}
	}
	else {
		if ( !this.moCollapsedMap ) this.moCollapsedMap = new Array();
		for ( i=0 ; i<this.moCollapsedMap.length ; i++ ) {
			if ( this.moCollapsedMap[i] === object ) {
				isCollapsed = true;
				break;
			}
		}
	}
	return isCollapsed;
}

ClientMethod isRuleCollapsed2(object) [ Language = javascript ]
{
	var isCollapsed = false;
	if ( !this.moCollapsedMap ) this.moCollapsedMap = new Array();
	for ( i=0 ; i<this.moCollapsedMap.length ; i++ ) {
		if ( this.moCollapsedMap[i] === object ) {
			isCollapsed = true;
			break;
		}
	}
	return isCollapsed;
}

/// Collapse (if argument is true) or expand (if argument is false) all rules of first level
ClientMethod collapseOrExpandAll(isCollapse) [ Language = javascript ]
{
	// Ignore if test tab
	if (this.currentTab ===  this.moRuleDefinitionObject.ruleSets.length) return;
	this.showMsgBox(true);
	setTimeout("zenPage.collapseOrExpandAllContd("+isCollapse+")",50);
}

ClientMethod collapseOrExpandAllContd(isCollapse) [ Language = javascript ]
{
	try {
		if ((this.currentTab > -1) && (this.currentTab < this.moRuleDefinitionObject.ruleSets.length)){
			if (this.moMainMap) {
				var mapObject = this.moMainMap[0];
				if (mapObject && mapObject.jsonObject) {
					var jsonObject = mapObject.jsonObject;
					if (jsonObject && jsonObject.actions) {
						if (isCollapse) {
							var state = '1';
						}
						else {
							var state = '0';
						}
						var ruleStates = '_';
						for ( ruleNo = 0; ruleNo < jsonObject.actions.length; ruleNo++) {
							ruleStates = ruleStates + state;
						}
						this.ruleStates = ruleStates;
						this.SetRuleStates(this.RULE,this.currentTab,ruleStates);
						this.drawRuleSet(false);
					}
				}
			}
		}
	} catch(ex) {
		alert('Error in collapseOrExpandAll ' + ex);
	}
	setTimeout("zenPage.showMsgBox(false)",200);
}

/// Collapse a rule
ClientMethod collapseRuleObject2(jObject) [ Language = javascript ]
{
	for ( i=0 ; i<this.moCollapsedMap.length ; i++ ) {
		if ( this.moCollapsedMap[i] === jObject ) {
			return;
		}
	}
	this.moCollapsedMap.splice(this.moCollapsedMap.length,0,jObject);
	this.drawRuleSet(false);
	return;
}

/// Expand a rule
ClientMethod expandRuleObject2(jObject) [ Language = javascript ]
{
	for ( i=0 ; i<this.moCollapsedMap.length ; i++ ) {
		if ( this.moCollapsedMap[i] === jObject ) {
			this.moCollapsedMap.splice(i,1);
			this.drawRuleSet(false);
			break;
		}
	}
	return;
}

/// Collapse (if argument is true) or expand (if argument is false) all rules of first level
ClientMethod collapseOrExpandAll2(isCollapse) [ Language = javascript ]
{
	// Ignore if test tab
	if (this.currentTab ===  this.moRuleDefinitionObject.ruleSets.length) return;
	this.showMsgBox(true);
	setTimeout("zenPage.collapseOrExpandAllContd2("+isCollapse+")",50);
}

ClientMethod collapseOrExpandAllContd2(isCollapse) [ Language = javascript ]
{
	var ruleNo = 0;
	try {
		if ((this.currentTab > -1) && (this.currentTab < this.moRuleDefinitionObject.ruleSets.length)){
			if (this.moMainMap) {
				var mapObject = this.moMainMap[0];
				if (mapObject && mapObject.jsonObject) {
					var jsonObject = mapObject.jsonObject;
					if (jsonObject && jsonObject.actions) {
						for ( ruleNo = 0; ruleNo < jsonObject.actions.length; ruleNo++) {
							var tObj = jsonObject.actions[ruleNo];
							if (tObj && tObj.type && tObj.type == 'rule') {
								if (isCollapse) {
									this.collapseRuleObject2(tObj);
								}
								else {
									this.expandRuleObject2(tObj);
								}
							}
						}
					}
				}
			}
		}
	} catch(ex) {
		alert('Error in collapseOrExpandAll ' + ex);
	}
	setTimeout("zenPage.showMsgBox(false)",200);
}

ClientMethod findRuleNo(object) [ Language = javascript ]
{
	try {
		if (this.currentTab > -1) {
			if (this.moMainMap) {
				var mapObject = this.moMainMap[0];
				if (mapObject && mapObject.jsonObject) {
					var jsonObject = mapObject.jsonObject;
					if (jsonObject && jsonObject.actions) {
						for ( ruleNo = 0; ruleNo < jsonObject.actions.length; ruleNo++) {
							if (jsonObject.actions[ruleNo] === object) {
								return ruleNo;
							}
						}
					}
				}
			}
		}
	} catch(ex) {
		//alert('Error in findRuleNo ' + ex);
	}
	return -1;
}

ClientMethod addClassToElement(elem, classToAdd) [ Language = javascript ]
{
	if (elem) {
		var newClass = elem.getAttribute('class');
		newClass += (newClass === '' ? '' : ' ') + classToAdd;
		elem.setAttribute('class',newClass);
	}
}

ClientMethod removeClassFromElement(elem, classToRemove) [ Language = javascript ]
{
	if (elem) {
		var currClass = elem.getAttribute('class');
		var classList = currClass.split(' ');
		for (var i = 0; i < classList.length; i++) {
			if (classList[i] === classToRemove) {
				classList.splice(i,1);
				i--;
			}
		}
		elem.setAttribute('class',classList.join(' '));
	}
}

ClientMethod objectClicked(event, isDoubleClick) [ Language = javascript ]
{
	if (!event) event = window.event;
	var button = zenIsIE && !zenIsHTML5 ? event.button : event.which;
	if ( button === 2 ) return (ZLM.killEvent(event));

	if ( isDoubleClick) {
		if (this.moFocusedPanelIndex === -1) {
			this.moFocusedPanelIndex = event.currentTarget.getAttribute("id");
			this.drawRuleDefinition();
		} else {
			if ( this.moMainMap[this.moFocusedIndex].jsonProperty === "disabled" ) {
				if (this.canUserModify()) {
					this.moMainMap[this.moFocusedIndex].jsonObject.disabled = ! this.moMainMap[this.moFocusedIndex].jsonObject.disabled;
					this.undoStackPush(true);
					this.drawRuleSet(true);
				}
			}
			else if ( this.moMainMap[this.moFocusedIndex].jsonProperty === "constraint" ) {
				var prod = ( this.moRuleDefinitionObject.isRoutingRule ? this.moRuleDefinitionObject.production : '' );
				var parms= { ASSIST:this.moRuleDefinitionObject.assistClass, PROD:prod, READONLY:((this.readOnly || !this.canEdit)?1 :0) };
				zenLaunchPopupWindow(zenLink('EnsPortal.ConstraintEditor.zen'),this.addPopupSuffix('editConstraint'),'modal=yes,status,scrollbars,resizable=yes,width=800,height=600',parms);
			} else {
				this.buttonDetailClicked();
			}
		}
	} else {
		this.loseFocus();
		this.getFocus(event.currentTarget.getAttribute("id"));
		this.undoStackPush(false);
		this.updateButtons();
		this.updateMenuAdd();
		this.updateHelpPanel();
		if (this.moFocusedPanelIndex === -1 ) this.drawRuleSetsTable();
	}
	return (ZLM.killEvent(event));
}

ClientMethod doScroll(delta) [ Language = javascript ]
{
	var area = zen("svgScrollingArea");
	area.getEnclosingDiv().scrollTop = area.getEnclosingDiv().scrollTop + delta*(-54);
	return;
}

ClientMethod backgroundClicked() [ Language = javascript ]
{
	if ( this.moRuleDefinitionObject == null ) return;
	this.menuHide();
	this.loseFocus();
	this.updateButtons();
	this.updateMenuAdd();
	this.updateHelpPanel();
	if ( this.moFocusedPanelIndex === -1 ) this.drawRuleSetsTable();
	return;
}

ClientMethod getFocus(id) [ Language = javascript ]
{
	if ( this.moFocusedPanelIndex === -1 ) {
		this.moFocusedRuleSetIndex = (id!="") ? parseInt(id,10) : id;
	} else {
		this.moFocusedIndex = id;
		var focusObject = this.moMainMap[id];
		this.moFocusedJsonObject[this.moFocusedPanelIndex] = focusObject.jsonObject;
		this.moFocusedJsonProperty[this.moFocusedPanelIndex] = focusObject.jsonProperty;
		this.moFocusedOriginalRectClass = focusObject.svgRectObject.getAttribute("class");
		focusObject.svgRectObject.setAttribute("class","rectFocused");
		this.moFocusedOriginalTextClass = focusObject.svgTextObject.getAttribute("class");
		focusObject.svgTextObject.setAttribute("class","textFocused");
		if (focusObject._svgNumRect) this.addClassToElement(focusObject._svgNumRect,'numFocused');
		var jsonProperty = focusObject.jsonProperty;
		// change the title bar
		if ( (jsonProperty==="condition")||(jsonProperty==="value")||(jsonProperty==="transform")||(jsonProperty==="target")||(jsonProperty==="ruleName")||(jsonProperty==="effectiveBegin")||(jsonProperty==="effectiveEnd")||(jsonProperty==="name")||(jsonProperty==="text") ) {
			zen("emptyBar").getEnclosingDiv().style.display = "none";
			zen("xyzBar").getEnclosingDiv().style.display = "none";
			zen("textBar").getEnclosingDiv().style.display = "block";
			zen("textEditor").setDisabled(this.readOnly || !this.canEdit);
			zen("textEditor").setValue(this.moMainMap[id].jsonObject[this.moMainMap[id].jsonProperty]);
			if (this.canEdit && !this.readOnly) {
				zen("textEditor").focus();
			}
		} else if (( jsonProperty==="property" ) || (jsonProperty==="propertypath")) {
			zen("emptyBar").getEnclosingDiv().style.display = "none";
			zen("textBar").getEnclosingDiv().style.display = "none";
			zen("xyzBar").getEnclosingDiv().style.display = "block";
			if (this.canEdit && !this.readOnly) {
				document.getElementById("xyzEditor").focus();
				document.getElementById("xyzEditor").disabled = 0;
				if (document.getElementById("xyzEditor").value != (this.moMainMap[id].jsonObject[this.moMainMap[id].jsonProperty])) {
					document.getElementById("xyzEditor").value = focusObject.jsonObject[focusObject.jsonProperty];
					document.getElementById("xyzGrayText").value = document.getElementById("xyzEditor").value;
				}
			} else {
				document.getElementById("xyzEditor").disabled = 1;
			}
		}
	}
	return;
}

ClientMethod loseFocus() [ Language = javascript ]
{
	this.transferEditorData();
	if ( this.moFocusedPanelIndex === -1 ) {
		this.moFocusedRuleSetIndex = null;
	} else if ( this.moFocusedIndex != null ) {
		var currObject = this.moMainMap[this.moFocusedIndex];
		currObject.svgRectObject.setAttribute("class",this.moFocusedOriginalRectClass);
		currObject.svgTextObject.setAttribute("class",this.moFocusedOriginalTextClass);
		if (currObject._svgNumRect) this.removeClassFromElement(currObject._svgNumRect,'numFocused');
		this.moFocusedIndex = null;
	}
	zen("emptyBar").getEnclosingDiv().style.display = "block";
	zen("textBar").getEnclosingDiv().style.display = "none";
	zen("xyzBar").getEnclosingDiv().style.display = "none";
	return;
}

ClientMethod transferEditorData() [ Language = javascript ]
{
	if (this.readOnly || !this.canEdit) {
		// changes should not be honored even if the rest of the UI lets them slip through.
		return;
	}
	if ( zen("textBar").getEnclosingDiv().style.display === "block" ) {
		this.textOKClicked();
	}
	if ( zen("xyzBar").getEnclosingDiv().style.display === "block" ) {
		this.xyzOKClicked();
	}
	return;
}

ClientMethod updateButtons() [ Language = javascript ]
{
	if ( (this.moFocusedPanelIndex===-1)&&(this.moFocusedRuleSetIndex!=null) ) {
		this.changeImage("imgUp",this.canEdit && (!this.readOnly) && (this.moFocusedRuleSetIndex>0));
		this.changeImage("imgDown",this.canEdit && (!this.readOnly) && (this.moFocusedRuleSetIndex<(this.moRuleDefinitionObject.ruleSets.length-1)));
		this.changeImage("imgDelete",this.canEdit && (!this.readOnly) && (this.moRuleDefinitionObject.ruleSets.length!=1));
		this.changeImage("imgDetail",false);
	} else if ( (this.moFocusedPanelIndex!=-1)&&(this.moFocusedIndex!=null) ) {
		var jsonObject = this.moMainMap[this.moFocusedIndex].jsonObject;
		var jsonProperty = this.moMainMap[this.moFocusedIndex].jsonProperty;
		var jsonParentArrayObject = this.moMainMap[this.moFocusedIndex].jsonParentArrayObject;
		var jsonParentArrayIndex = this.moMainMap[this.moFocusedIndex].jsonParentArrayIndex;
		var jsonChildrenArrayObject = this.moMainMap[this.moFocusedIndex].jsonChildrenArrayObject;

		this.changeImage("imgUp",this.canEdit && (!this.readOnly) && (jsonParentArrayObject!=null)&&(jsonParentArrayIndex>0));
		this.changeImage("imgDown",this.canEdit && (!this.readOnly) && (jsonParentArrayObject!=null)&&(jsonParentArrayIndex<(jsonParentArrayObject.length-1)));
		this.changeImage("imgDelete",this.canEdit && (!this.readOnly) && ((jsonParentArrayObject!=null)||(jsonObject.type==="otherwise")));
		// For properties which can be easily read without another dialog, disable the button if no edit privileges
		if ( (jsonProperty==="effectiveBegin")||(jsonProperty==="effectiveEnd")||(jsonProperty==="ruleName")||(jsonProperty==="transform")||(jsonProperty==="target") ) {
			this.changeImage("imgDetail", this.canEdit && (!this.readOnly));
		}
		else if ((jsonProperty==="condition")||(jsonProperty==="value")||(jsonProperty==="constraint")){
			this.changeImage("imgDetail", true);
		}
		else {
			this.changeImage("imgDetail", false);
		}
	} else {
		this.changeImage("imgUp",false);
		this.changeImage("imgDown",false);
		this.changeImage("imgDelete",false);
		this.changeImage("imgDetail",false);
	}
	this.changeImage("imgUndo",this.canEdit && (!this.readOnly)&&(this.moUndoPointer>0));
	this.changeImage("imgRedo",this.canEdit && (!this.readOnly)&&(this.moUndoStack)&&(this.moUndoPointer<(this.moUndoStack.length-1)));
	this.changeImage("imgViewOn",true);
	this.changeImage("imgViewOff",true);
	var toHide = this.showProperty ? zen("imgViewOn") : zen("imgViewOff");
	var toShow = this.showProperty ? zen("imgViewOff") : zen("imgViewOn");
	toHide.getEnclosingDiv().className = 'hiddenImage';
	toShow.getEnclosingDiv().className = '';

	return;
}

ClientMethod hideAllHelpPanelActions(imagesToo) [ Language = javascript ]
{
	zen("hpAdd").setHidden(true);
	zen("hpAdd-assign").setHidden(true);
	zen("hpAdd-return").setHidden(true);
	zen("hpAdd-trace").setHidden(true);
	zen("hpAdd-debug").setHidden(true);
	zen("hpAdd-comment").setHidden(true);
	zen("hpAdd-send").setHidden(true);
	zen("hpAdd-delete").setHidden(true);
	zen("hpAdd-delegate").setHidden(true);
	zen("hpAdd-rule").setHidden(true);
	zen("hpAdd-foreach").setHidden(true);
	zen("hpAdd-when").setHidden(true);
	zen("hpAdd-otherwise").setHidden(true);
	
	if (imagesToo) {
		zen('hpNoSelect').setHidden(false);
		zen('hpCurrSelect').setHidden(true);
		zen("hpMoveUp").setHidden(true);
		zen("hpMoveDown").setHidden(true);
		zen("hpDelete").setHidden(true);
		zen("hpUndo").setHidden(true);
		zen("hpRedo").setHidden(true);
		zen("hpDetail").setHidden(true);
	}
}

ClientMethod updateHelpPanel() [ Language = javascript ]
{
	if ( this.moFocusedPanelIndex != -1 ) {
		if ( this.moFocusedIndex != null ) {
			var jsonObject = this.moMainMap[this.moFocusedIndex].jsonObject;
			var jsonProperty = this.moMainMap[this.moFocusedIndex].jsonProperty;
			var jsonParentObject = this.moMainMap[this.moFocusedIndex].jsonParentObject;

			zen('hpNoSelect').setHidden(true);
			zen('hpCurrSelect').setHidden(false);

			var msg = 'Unknown!';
			if ( jsonProperty != "type" ) {
				msg = $$$FormatText($$$Text("The selected item is the %1 field of the %2 item."),jsonProperty,jsonObject.type);
				if ( (zen("emptyBar").getEnclosingDiv().style.display === "none") && this.canEdit && (!this.readOnly) ) {
					msg = msg + " " + $$$Text("You can edit the value directly in the text editor box above the diagram.");
				}
				if ( zen("imgDetail").src.indexOf("disabled")===-1 ) {
					msg = msg + " " + $$$Text("You can also invoke the expression or selection editor.");
				}
			} else {
				switch(jsonObject.type) {
					case 'ruleSet':
						msg = $$$Text("The selected item is a ruleSet. This defines a series of rules and associated actions for each rule. You can select the effectiveBegin and effectiveEnd fields following it to view or edit them.");
						break;
					case 'rule':
						msg = $$$Text("The selected item is a rule. This defines a set of conditions and actions for each condition. You can select the name field following it to view or edit the name. Double click on enabled/disabled field to change.");
						break;
					case 'foreach':
						msg = $$$Text("The selected item is a foreach clause. This defines a repeating segment to loop over, so that conditions can be defined for each occurrence of the segment. You can select the propertypath field following it to view or edit the segment to loop over."); 
						break;
					case 'when':
						msg = $$$Text("The selected item is a when clause. This defines a specific condition and a set of actions to invoke when the condition is true.  You can select the condition field following it to view or edit the condition.");
						break;
					case 'otherwise':
						msg = $$$Text("The selected item is an otherwise clause. This defines a set of actions to invoke when no other condition is true.");
						break;
					case 'assign':
						msg = $$$Text("The selected item is an assign action. This assigns a value to a property. You can select the property and value fields following it to view or edit them.");
						break;
					case 'return':
						msg = $$$Text("The selected item is a return action. This instructs the rule to exit. You can select the value field following it to view or edit it.");
						break;
					case 'trace':
						msg = $$$Text("The selected item is a trace action. This causes a trace statement to be executed. You can select the value field following it to view or edit it.");
						break;
					case 'send':
						msg = $$$Text("The selected item is a send action. This instructs the message router to send a document. You can select the transform and target fields following it to view or edit them.");
						break;
					case 'delete':
						msg = $$$Text("The selected item is a delete action. This instructs the message router to delete a document.");
						break;
					case 'delegate':
						msg = $$$Text("The selected item is a delegate action. This instructs the message router to invoke another rule. You can select the ruleName field following it to view or edit it.");
						break;
					case 'debug':
						msg = $$$Text("The selected item is a debug action. This causes a debug statement to be logged when the rule is in debug mode (the router business process RuleLogging property specifies the d flag).");
						msg += " ";
						msg += $$$Text("A log of the expression assigned to the debug action and its value at rule execution are written to the Rule Log under Detailed Logging.");
						break;
					case 'comment':
						msg = $$$Text("The selected item is a comment action. This is not used in the evaluation of the rule.");
						break;
				}
			}

			// description of selected item
			zen('hpCurrItemType').setContent(jsonObject.type);
			zen('hpCurrItemDesc').setContent(msg);

			// images
			zen("hpMoveUp").setHidden(zen("imgUp").src.indexOf("disabled")>=0)
			zen("hpMoveDown").setHidden(zen("imgDown").src.indexOf("disabled")>=0)
			zen("hpDelete").setHidden(zen("imgDelete").src.indexOf("disabled")>=0)
			zen("hpUndo").setHidden(zen("imgUndo").src.indexOf("disabled")>=0)
			zen("hpRedo").setHidden(zen("imgRedo").src.indexOf("disabled")>=0)
			zen("hpDetail").setHidden(zen("imgDetail").src.indexOf("disabled")>=0)
			zen("hpViewOn").setHidden(this.showProperty)
			zen("hpViewOff").setHidden(!this.showProperty)

			var menu = this.getComponentById("menuAdd");
			var menuCore = menu.getEnclosingDiv().item;

			var menuItems = new Array();
			for ( var child = menuCore.firstChild; child != null ; child = child.nextSibling ) {
				if ( child.firstChild.innerHTML.split(">").length > 3) {
					var oneMenuObject = new Object();
					oneMenuObject.caption = child.firstChild.innerHTML.split(">")[3].split("<")[0];
					oneMenuObject.onselect = child.firstChild.getAttribute("onselect");
					oneMenuObject.type = child.firstChild.getAttribute("onselect").split("\"")[1].substr(0,1);
					menuItems[menuItems.length] = oneMenuObject;
				}
			}
			zenPage.hideAllHelpPanelActions();
			if (menuItems.length > 0) {
				zen("hpAdd").setHidden(false);
				for ( var i=0 ; i<menuItems.length ; i++ ) {
					zen("hpAdd-"+menuItems[i].caption).setHidden(false);
					ZLM.setLocalAttribute(document.getElementById("btnAdd-"+menuItems[i].caption),"onclick",menuItems[i].onselect);
				}
			}

		} else {
			var msg = $$$Text("Select an item within the rules diagram to see a description and options.");
			zen('hpNoSelectMsg').setContent(msg);
			zenPage.hideAllHelpPanelActions(true);			
			zen("hpViewOn").setHidden(this.showProperty)
			zen("hpViewOff").setHidden(!this.showProperty)
		}
	} else {
		if (this.canEdit && (!this.readOnly)) {
			var msg = $$$Text("Click on the text fields to edit.");
		}
		else {
			var msg = $$$Text("You can view the current settings for the rule in the text fields.");
		}
		zen('hpNoSelectMsg').setContent(msg);
		zenPage.hideAllHelpPanelActions(true);
		zen("hpViewOn").setHidden(true);
		zen("hpViewOff").setHidden(true);
	}
	return;
}

ClientMethod updateMenuAdd() [ Language = javascript ]
{
	var shouldEnable = true;

	if ( this.moFocusedPanelIndex === -1 ) {
		if ( (this.moFocusedRuleSetIndex != null) && ( this.canEdit ) && ( !this.readOnly ) ) {
			this.changeImage("imgAdd",true);
		} else {
			this.changeImage("imgAdd",false);
		}
	} else {
		if ( this.readOnly || !this.canEdit ) {
			shouldEnable = false;
		}
		else if ( this.moFocusedIndex == null ) {
			shouldEnable = false;
		} else {
			var jsonObject = this.moMainMap[this.moFocusedIndex].jsonObject;
			var jsonProperty = this.moMainMap[this.moFocusedIndex].jsonProperty;
			var jsonParentObject = this.moMainMap[this.moFocusedIndex].jsonParentObject;
			var jsonParentArrayObject = this.moMainMap[this.moFocusedIndex].jsonParentArrayObject;
			var jsonChildrenArrayObject = this.moMainMap[this.moFocusedIndex].jsonChildrenArrayObject;
			if ( jsonProperty!="type" ) shouldEnable = false;
			if ( (jsonParentArrayObject==null)&&(jsonChildrenArrayObject==null) ) shouldEnable = false;
		}

		this.changeImage("imgAdd",shouldEnable);
		this.menuAddClear();

		if ( shouldEnable ) {
			var classType = jsonObject.type;

			if ( classType==="rule" ) {
				var isFirst = (jsonObject.whens.length===0);
				var includeOtherwise = (jsonObject.otherwise==null);
				this.populateMenuAddWhen("c-",isFirst,includeOtherwise);
				this.menuAddInsertSeparator();
				this.populateMenuAddAction("s-");
			} else if ( classType==="when" ) {
				// don't want nesting of foreach actions because only one pContext.Segment
				var parentLoop = this.moMainMap[this.moFocusedIndex].jsonParentLoopObject;
				if (parentLoop === null) {
					this.populateMenuAddForEach("c-");
				}
				this.populateMenuAddAction("c-");
				this.menuAddInsertSeparator();
				var isFirst = (jsonParentObject.whens.length===0);
				var includeOtherwise = (jsonParentObject.otherwise==null);
				this.populateMenuAddWhen("s-",isFirst,includeOtherwise);
			} else if (classType==="otherwise") {
				// don't want nesting of foreach actions because only one pContext.Segment
				var parentLoop = this.moMainMap[this.moFocusedIndex].jsonParentLoopObject;
				if (parentLoop === null) {
					this.populateMenuAddForEach("c-");
				}
				this.populateMenuAddAction("c-");
			} else if (classType==="ruleSet") {
				this.populateMenuAddAction("c-");
			} else if (classType==="foreach") {
				var isFirst = (jsonObject.whens.length===0);
				var includeOtherwise = (jsonObject.otherwise==null);
				this.populateMenuAddWhen("c-",isFirst,includeOtherwise);
				this.menuAddInsertSeparator();
				this.populateMenuAddForEach("s-");
				this.populateMenuAddAction("s-");
			} else {
				this.populateMenuAddAction("s-");
			}
			this.menuAddUpdateGeometry();
		}
	}
	return;
}

ClientMethod populateMenuAddAction(prefix) [ Language = javascript ]
{
	this.menuAddInsertPick("assign",  prefix+"assign");
	this.menuAddInsertPick("return",  prefix+"return");
	this.menuAddInsertPick("trace",   prefix+"trace");
	this.menuAddInsertPick("debug",   prefix+"debug");
	this.menuAddInsertPick("comment",   prefix+"comment");
	if ( this.moRuleDefinitionObject.isRoutingRule ) {
		this.menuAddInsertPick("send",    prefix+"send");
		this.menuAddInsertPick("delete",  prefix+"delete");
		this.menuAddInsertPick("delegate",prefix+"delegate");
	}
	this.menuAddInsertPick("rule",    prefix+"rule");
	return;
}

ClientMethod populateMenuAddForEach(prefix) [ Language = javascript ]
{
	if ( this.moRuleDefinitionObject.hasSegments ) {
		this.menuAddInsertPick("foreach", prefix+"foreach");
	}
	return;
}

ClientMethod populateMenuAddWhen(prefix, isFirst, includeOtherwise) [ Language = javascript ]
{
	var whenCaption = this.optionDrawIfElse? ( isFirst ? "if" : "else if" ) : "when"
	var otherwiseCaption = this.optionDrawIfElse ? "else" : "otherwise";

	this.menuAddInsertPick(whenCaption,prefix+"when");
	if ( includeOtherwise ) {
		this.menuAddInsertPick(otherwiseCaption,prefix + "otherwise");
	}
	return;
}

ClientMethod menuAddClear() [ Language = javascript ]
{
	var menu = this.getComponentById("menuAdd");
	var menuCore = menu.getEnclosingDiv().item;
	if ( menuCore == null ) return;
	menuCore.innerHTML="";
	this.menuAddUpdateGeometry();
}

ClientMethod menuAddInsertPick(caption, keyword) [ Language = javascript ]
{
	var menu = this.getComponentById("menuAdd");
	var menuCore = menu.getEnclosingDiv().item;
	var wrapper = ZLM.makeElement("div");
	var pick = ZLM.simulateTag("div class='csMenuItem' caption='"+caption+"'");
	pick.setAttribute('onselect',"zenPage.menuAddSelected(\""+keyword+"\")");
	if (pick.className === '') pick.className = 'csMenuItem';
	wrapper.appendChild(pick);
	menuCore.appendChild(wrapper);
	ZMS.createMenuItemSubtree(pick,20);
}

ClientMethod menuAddInsertSeparator() [ Language = javascript ]
{
	var menu = this.getComponentById("menuAdd");
	var menuCore = menu.getEnclosingDiv().item;
	var wrapper = ZLM.makeElement("div");
	var sep = ZLM.simulateTag("div class='csMenuSeparator'");
	wrapper.appendChild(sep);
	menuCore.appendChild(wrapper);
}

ClientMethod menuAddUpdateGeometry() [ Language = javascript ]
{
	var menu = zen("menuAdd");
	if (menu) {
		var menuCore = menu.getEnclosingDiv().item;
		if (menuCore) {
			ZMS.estimateContextMenuSize(menuCore);
			ZMS.setContextMenuSize(menuCore);
		}
	}
}

ClientMethod menuShow(menu, x, y) [ Language = javascript ]
{
	ZMS.showPullDownMenu(x,y,menu);
	zenPage.correctIELayering(menu);
	if (ZMS.mouseTrap) {
		ZLM.setLocalAttribute(ZMS.mouseTrap,"onclick","zenPage.menuOnClose(event);");
		ZLM.setLocalAttribute(ZMS.mouseTrap,"oncontextmenu","zenPage.menuOnClose(event);");
	}
	this.moMenuAddIsShown = true;
	return;
}

ClientMethod menuHide() [ Language = javascript ]
{
	if ( this.moMenuAddIsShown ) {
		this.moMenuAddIsShown = false;
		this.mouseOut(zen("imgAdd"));
		ZMS.closeMenu(null);
	}
	return;
}

ClientMethod menuOnClose(event) [ Language = javascript ]
{
	this.moMenuAddIsShown = false;
	this.mouseOut(zen("imgAdd"));
	ZMS.closeMenu(event);
	return;
}

ClientMethod menuAddSelected(menuSelection) [ Language = javascript ]
{
	this.menuHide();
	if (!this.checkEdit()) { return; }

	if ( this.moFocusedPanelIndex === -1 ) {
		if ( this.moFocusedRuleSetIndex != null ) {
			var newObject = this.jsonNewObject("ruleSet");
			this.moFocusedRuleSetIndex = parseInt(this.moFocusedRuleSetIndex);
			this.moRuleDefinitionObject.ruleSets.splice(this.moFocusedRuleSetIndex+1,0,newObject);
			this.moFocusedRuleSetIndex = this.moFocusedRuleSetIndex + 1;
			this.undoStackPush(true);
			this.drawRuleDefinition();
		}
	} else {
		if ( this.moFocusedIndex == null ) return;
		if ( menuSelection === "" ) return;

		var jsonObject = this.moMainMap[this.moFocusedIndex].jsonObject;
		var jsonProperty = this.moMainMap[this.moFocusedIndex].jsonProperty;
		var jsonParentObject = this.moMainMap[this.moFocusedIndex].jsonParentObject;
		var jsonParentArrayObject = this.moMainMap[this.moFocusedIndex].jsonParentArrayObject;
		var jsonParentArrayIndex = this.moMainMap[this.moFocusedIndex].jsonParentArrayIndex;
		var jsonChildrenArrayObject = this.moMainMap[this.moFocusedIndex].jsonChildrenArrayObject;

		var newPrefix = menuSelection.substring(0,1);
		var newType = menuSelection.substring(2);
		var newObject = this.jsonNewObject(newType);

		// otherwise is special, it's not in a collection
		if ( newType === "otherwise" ) {
			if ( newPrefix === "s" ) {
				// add as a sibling node
				jsonParentObject.otherwise = newObject;
				this.moFocusedJsonObject[this.moFocusedPanelIndex] = newObject;
				this.moFocusedJsonProperty[this.moFocusedPanelIndex] = "type"
			} else {
				// add as a child node
				jsonObject.otherwise = newObject;
				this.moFocusedJsonObject[this.moFocusedPanelIndex] = newObject;
				this.moFocusedJsonProperty[this.moFocusedPanelIndex] = "type"
			}
		} else {
			if ( newPrefix === "s" ) {
				// add as a sibling node
				if ((newType === "rule") && (this.moRuleDefinitionObject.assistClass === "EnsLib.HL7.MsgRouter.RuleAssistCompatible")){
					var newConstraint = zenPage.newObject('Object');
					newConstraint._class = "Ens.Rule.Model.constraint";
					newConstraint.type = "constraint";
					newConstraint.name = "msgClass";
					newConstraint.value = "EnsLib.HL7.Message";
					newObject.constraints.push(newConstraint);
				}
				jsonParentArrayObject.splice(jsonParentArrayIndex+1,0,newObject);
				this.moFocusedJsonObject[this.moFocusedPanelIndex] = newObject;
				this.moFocusedJsonProperty[this.moFocusedPanelIndex] = "type"
			} else {
				// add as a child node
				if ((newType === "rule") && (this.moRuleDefinitionObject.assistClass === "EnsLib.HL7.MsgRouter.RuleAssistCompatible")) {
					var newConstraint = zenPage.newObject('Object');
					newConstraint._class = "Ens.Rule.Model.constraint";
					newConstraint.type = "constraint";
					newConstraint.name = "msgClass";
					newConstraint.value = "EnsLib.HL7.Message";
					newObject.constraints.push(newConstraint);
				}
				if ( newType === "when" ) {
					jsonChildrenArrayObject.splice(jsonChildrenArrayObject.length,0,newObject);
				} else {
					jsonChildrenArrayObject.splice(0,0,newObject);
				}
				this.moFocusedJsonObject[this.moFocusedPanelIndex] = newObject;
				this.moFocusedJsonProperty[this.moFocusedPanelIndex] = "type"
			}
		}
		this.undoStackPush(true);
		this.drawRuleSet(false);
		this.centerFocusedObject();
	}
	return;
}

ClientMethod changeImage(imageId, enabled) [ Language = javascript ]
{
	var newsrc = zen(imageId).src;
	if ( enabled ) {
		if ( this.moPointInImage === zen(imageId) ) {
			newsrc = newsrc.substring(0,newsrc.indexOf("_"))+"_hover.png";
		} else {
			newsrc = newsrc.substring(0,newsrc.indexOf("_"))+"_enabled.png";
		}
	} else {
		newsrc = newsrc.substring(0,newsrc.indexOf("_"))+"_disabled.png";
	}
	zen(imageId).setProperty("src",newsrc);
	return;
}

ClientMethod tabClicked(index) [ Language = javascript ]
{
	this.menuHide();
	this.currentTab = index;
	this.moFocusedPanelIndex = index;
	// Test tab clear ruleStates
	if (index ===  this.moRuleDefinitionObject.ruleSets.length) {
		this.ruleStates = '';
	} else {
		this.ruleStates = this.GetRuleStates(this.RULE,this.currentTab);
	}
	this.undoStackPush(false);
	this.drawRuleDefinition();
	return;
}

ClientMethod jsonNewObject(type) [ Language = javascript ]
{
	if (!this.checkEdit()) { return null; }

	var newObject = { "_class": "Ens.Rule.Model." + type, "type": type };

	switch (type) {
		case "ruleSet":
			newObject.name = "";
			newObject.effectiveBegin = "";
			newObject.effectiveEnd = "";
			newObject.actions = [];
			break;
		case "rule":
			newObject.name = "";
			newObject.disabled = false;
			newObject.constraints = [];
			newObject.whens = [ this.jsonNewObject("when") ];
			newObject.otherwise = null;
			break;
		case "foreach":
			newObject.propertypath = "";
			newObject.whens = [ this.jsonNewObject("when") ];
			newObject.otherwise = null;
			break;
		case "when":
			newObject.condition = "1";
			newObject.conditionObject = { "type": "value", "value": "" };
			// note fall-through for actions array
		case "otherwise":
			newObject.actions = [];
			if ( this.moRuleDefinitionObject.isRoutingRule ) {
				newObject.actions[0] = this.jsonNewObject("return");
			}
			break;
		case "assign":
			newObject.property = "";
			newObject.value = "";
			break;
		case "return":
		case "trace":
		case "debug":
			newObject.value = "";
			break;
		case "comment":
			newObject.text = "";
			break;
		case "send":
			newObject.transform = "";
			newObject.target = "";
			break;
		case "delegate":
			newObject.ruleName = "";
			break;
	}
	return newObject;
}

ClientMethod mouseOver(image) [ Language = javascript ]
{
	if ( image.src.indexOf("disabled") != -1 ) return;
	this.moPointInImage = image;
	image.setProperty("src",image.src.substring(0,image.src.indexOf("_"))+"_hover.png");
	return;
}

ClientMethod mouseOut(image) [ Language = javascript ]
{
	if ( image.src.indexOf("disabled") != -1 ) return;
	if ( (image.id==="imgAdd")&&(this.moMenuAddIsShown) ) return;
	this.moPointInImage = null;
	image.setProperty("src",image.src.substring(0,image.src.indexOf("_"))+"_enabled.png");
	return;
}

ClientMethod mouseDown(event, image) [ Language = javascript ]
{
	if (!event) event = window.event;
	var button = zenIsIE && !zenIsHTML5 ? event.button : event.which;
	if ( button === 2 ) {
		ZLM.killEvent(event);
		return;
	}

	if ( image.src.indexOf("disabled") != -1 ) return;
	image.setProperty("src",image.src.substring(0,image.src.indexOf("_"))+"_pressed.png");
	if ( image.id === "imgAdd" ) this.buttonAddMouseDown();
	ZLM.killEvent(event);
	return;
}

ClientMethod mouseUp(event, image) [ Language = javascript ]
{
	if (!event) event = window.event;
	var button = (zenIsIE && !zenIsHTML5) ? event.button : event.which;
	ZLM.killEvent(event);
	if ( button === 2 ) return;

	if ( image.src.indexOf("disabled") != -1 ) return;
	image.setProperty("src",image.src.substring(0,image.src.indexOf("_"))+"_hover.png");
	switch ( image.id.substr(3) ) {
		case "Up":
			setTimeout("zenPage.buttonUpClicked()",0);
			break;
		case "Down":
			setTimeout("zenPage.buttonDownClicked()",0);
			break;
		case "Add":
			setTimeout("zenPage.buttonAddClicked()",0);
			break;
		case "Delete":
			setTimeout("zenPage.buttonDeleteClicked()",0);
			break;
		case "Undo":
			setTimeout("zenPage.undoStackPop()",0);
			break;
		case "Redo":
			setTimeout("zenPage.undoStackRedo()",0);
			break;
		case "Detail":
			setTimeout("zenPage.buttonDetailClicked()",0);
			break;
		case "ViewOn":
			setTimeout("zenPage.buttonViewClicked(true);",0);
			break;
		case "ViewOff":
			setTimeout("zenPage.buttonViewClicked(false);",0);
			break;
	}
	return;
}

ClientMethod centerFocusedObject() [ Language = javascript ]
{
	if ( this.moFocusedIndex == null ) return;
	var area = zen("svgScrollingArea");
	var x1 = parseInt(this.moMainMap[this.moFocusedIndex].svgRectObject.getAttribute("x"));
	var x2 = x1 + parseInt(this.moMainMap[this.moFocusedIndex].svgRectObject.getAttribute("width"));
	var y1 = parseInt(this.moMainMap[this.moFocusedIndex].svgRectObject.getAttribute("y"));
	var y2 = y1 + parseInt(this.moMainMap[this.moFocusedIndex].svgRectObject.getAttribute("height"));
	var w = parseInt(zen("svgScrollingArea").getEnclosingDiv().clientWidth);
	var h = parseInt(zen("svgScrollingArea").getEnclosingDiv().clientHeight);
	var l = parseInt(area.getEnclosingDiv().scrollLeft);
	var t = parseInt(area.getEnclosingDiv().scrollTop);
	if ( (x1<l) || (x2>(l+w)) || (y1<t) || (y2>(t+h)) ) {
		area.getEnclosingDiv().scrollTop = Math.max(y1-h/2,0);
		area.getEnclosingDiv().scrollLeft = Math.max(x1-w/2,0);
		}
	return;
}

ClientMethod debugClicked() [ Language = javascript ]
{
}

ClientMethod undoStackInit() [ Language = javascript ]
{
	this.moUndoStack = new Array();
	this.moUndoPointer = -1;
	this.undoStackPush(true);
	return;
}

ClientMethod undoStackPush(dataChanged) [ Language = javascript ]
{
	this.moUndoPointer = this.moUndoPointer+1;
	this.moUndoStack.length = this.moUndoPointer;
	this.moUndoStack[this.moUndoPointer] = new Object();
	var focusedObject = new Object();
	focusedObject.oldObj = this.moFocusedJsonObject[this.moFocusedPanelIndex];
	focusedObject.newObj = null;
	this.moUndoStack[this.moUndoPointer].moRuleDefinitionObject = this.clone(this.moRuleDefinitionObject,focusedObject);
	this.moUndoStack[this.moUndoPointer].moFocusedPanelIndex = this.moFocusedPanelIndex;
	this.moUndoStack[this.moUndoPointer].moFocusedRuleSetIndex = this.moFocusedRuleSetIndex;
	this.moUndoStack[this.moUndoPointer].moFocusedJsonObject = focusedObject.newObj;
	this.moUndoStack[this.moUndoPointer].moFocusedJsonProperty = this.moFocusedJsonProperty[this.moFocusedPanelIndex];
	this.moUndoStack[this.moUndoPointer].dataChanged = dataChanged;
	if ( this.moUndoPointer === 0 ) {
		this.moUndoStack[this.moUndoPointer].modified = false;
	} else if ( (this.moUndoStack[this.moUndoPointer-1].modified==false)&&(dataChanged==false)) {
		this.moUndoStack[this.moUndoPointer].modified = false;
	} else {
		this.moUndoStack[this.moUndoPointer].modified = true;
	}
	this.setModified(this.moUndoStack[this.moUndoPointer].modified);
	return;
}

ClientMethod undoStackPop() [ Language = javascript ]
{
	if ( this.moUndoPointer <= 0 ) return;
	this.moUndoPointer = this.moUndoPointer-1;
	var focusedObject = new Object();
	focusedObject.oldObj = this.moUndoStack[this.moUndoPointer].moFocusedJsonObject;
	focusedObject.newObj = null;
	this.moRuleDefinitionObject = this.clone(this.moUndoStack[this.moUndoPointer].moRuleDefinitionObject,focusedObject);
	this.moFocusedPanelIndex = this.moUndoStack[this.moUndoPointer].moFocusedPanelIndex;
	this.moFocusedRuleSetIndex = this.moUndoStack[this.moUndoPointer].moFocusedRuleSetIndex;
	this.moFocusedJsonObject[this.moFocusedPanelIndex] = focusedObject.newObj;
	this.moFocusedJsonProperty[this.moFocusedPanelIndex] = this.moUndoStack[this.moUndoPointer].moFocusedJsonProperty;
	this.drawRuleDefinition();
	this.centerFocusedObject();
	this.setModified(this.moUndoStack[this.moUndoPointer].modified);
	return;
}

ClientMethod undoStackRedo() [ Language = javascript ]
{
	if ( this.moUndoPointer >= (this.moUndoStack.length-1) ) return;
	this.moUndoPointer = this.moUndoPointer+1;
	var focusedObject = new Object();
	focusedObject.oldObj = this.moUndoStack[this.moUndoPointer].moFocusedJsonObject;
	focusedObject.newObj = null;
	this.moRuleDefinitionObject = this.clone(this.moUndoStack[this.moUndoPointer].moRuleDefinitionObject,focusedObject);
	this.moFocusedPanelIndex = this.moUndoStack[this.moUndoPointer].moFocusedPanelIndex;
	this.moFocusedRuleSetIndex = this.moUndoStack[this.moUndoPointer].moFocusedRuleSetIndex;
	this.moFocusedJsonObject[this.moFocusedPanelIndex] = focusedObject.newObj;
	this.moFocusedJsonProperty[this.moFocusedPanelIndex] = this.moUndoStack[this.moUndoPointer].moFocusedJsonProperty;
	this.drawRuleDefinition();
	this.centerFocusedObject();
	this.setModified(this.moUndoStack[this.moUndoPointer].modified);
	return;
}

ClientMethod undoStackResetModified() [ Language = javascript ]
{
	for ( var i=0 ; i<this.moUndoStack.length ; i++ ) {
		this.moUndoStack[i].modified = true;
	}
	this.moUndoStack[this.moUndoPointer].modified = false;
	for ( var i=this.moUndoPointer-1 ; i>-1 ; i-- ) {
		if ( this.moUndoStack[i+1].dataChanged ) break;
		this.moUndoStack[i].modified = false;
	}
	for ( var i=this.moUndoPointer+1 ; i<this.moUndoStack.length ; i++ ) {
		if ( this.moUndoStack[i].dataChanged ) break;
		this.moUndoStack[i].modified = false;
	}
	this.setModified(this.moUndoStack[this.moUndoPointer].modified);
	return;
}

ClientMethod clone(obj, focused) [ Language = javascript ]
{
	if ( obj == null ) {
		return null;
	} else if (Object.prototype.toString.call(obj) === '[object Array]') {
        var out = [], i = 0, len = obj.length;
        for ( ; i < len; i++ ) {
            out[i] = arguments.callee(obj[i],focused);
        }
        if ( focused.oldObj === obj ) focused.newObj = out;
        return out;
    }
    if (typeof obj === 'object') {
        var out = {}, i;
        for ( i in obj ) {
            out[i] = arguments.callee(obj[i],focused);
        }
        if ( focused.oldObj === obj ) focused.newObj = out;
        return out;
    }
    return obj;
}

ClientMethod buttonViewClicked(showProperty) [ Language = javascript ]
{
	this.showProperty = showProperty;
	this.drawRuleSet(false);
	this.SaveViewPropertyState(this.RULE,showProperty);
	return;
}

ClientMethod buttonUpClicked() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }

	if ( this.moFocusedPanelIndex === -1 ) {
		if ( this.moFocusedRuleSetIndex > 0 ) {
			var savedObject = this.moRuleDefinitionObject.ruleSets[this.moFocusedRuleSetIndex];
			this.moRuleDefinitionObject.ruleSets[this.moFocusedRuleSetIndex] = this.moRuleDefinitionObject.ruleSets[this.moFocusedRuleSetIndex-1];
			this.moRuleDefinitionObject.ruleSets[this.moFocusedRuleSetIndex-1] = savedObject;
			this.moFocusedRuleSetIndex = this.moFocusedRuleSetIndex-1;
			this.undoStackPush(true);
			this.drawRuleDefinition();
		}
	} else {
		if ( this.moFocusedIndex != null ) {
			var jsonParentArrayObject = this.moMainMap[this.moFocusedIndex].jsonParentArrayObject;
			var jsonParentArrayIndex = this.moMainMap[this.moFocusedIndex].jsonParentArrayIndex;
			if ( (jsonParentArrayObject!=null)&&(jsonParentArrayIndex>0) ) {
				var savedObject = jsonParentArrayObject[jsonParentArrayIndex];
				jsonParentArrayObject[jsonParentArrayIndex] = jsonParentArrayObject[jsonParentArrayIndex-1];
				jsonParentArrayObject[jsonParentArrayIndex-1] = savedObject;
				this.undoStackPush(true);
				this.drawRuleSet(false);
			}
		}
	}
	return;
}

ClientMethod buttonDownClicked() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }

	if ( this.moFocusedPanelIndex === -1 ) {
		if ( this.moFocusedRuleSetIndex < (this.moRuleDefinitionObject.ruleSets.length-1) ) {
			this.moFocusedRuleSetIndex = parseInt(this.moFocusedRuleSetIndex);
			var savedObject = this.moRuleDefinitionObject.ruleSets[this.moFocusedRuleSetIndex];
			this.moRuleDefinitionObject.ruleSets[this.moFocusedRuleSetIndex] = this.moRuleDefinitionObject.ruleSets[this.moFocusedRuleSetIndex+1];
			this.moRuleDefinitionObject.ruleSets[this.moFocusedRuleSetIndex+1] = savedObject;
			this.moFocusedRuleSetIndex = this.moFocusedRuleSetIndex+1;
			this.undoStackPush(true);
			this.drawRuleDefinition();
		}
	} else {
		if ( this.moFocusedIndex != null ) {
			var jsonParentArrayObject = this.moMainMap[this.moFocusedIndex].jsonParentArrayObject;
			var jsonParentArrayIndex = this.moMainMap[this.moFocusedIndex].jsonParentArrayIndex;
			if ( (jsonParentArrayObject!=null)&&(jsonParentArrayIndex<(jsonParentArrayObject.length-1)) ) {
				var savedObject = jsonParentArrayObject[jsonParentArrayIndex];
				jsonParentArrayObject[jsonParentArrayIndex] = jsonParentArrayObject[jsonParentArrayIndex+1];
				jsonParentArrayObject[jsonParentArrayIndex+1] = savedObject;
				this.undoStackPush(true);
				this.drawRuleSet(false);
			}
		}
	}
	return;
}

ClientMethod buttonAddMouseDown() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }
	if ( zen("imgAdd").src.indexOf("disabled") != -1 ) return;
	if ( this.moFocusedPanelIndex != -1 ) {
		var menu = this.getComponentById("menuAdd");
		var menuCore = menu.getEnclosingDiv().item;
		this.menuShow(menuCore,69,175);
	}
	return;
}

ClientMethod buttonAddClicked() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }
	if ( zen("imgAdd").src.indexOf("disabled") != -1 ) return;
	if ( this.moFocusedPanelIndex === -1 ) {
		this.menuAddSelected("ruleSet");
	}
	return;
}

ClientMethod buttonDeleteClicked() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }

	if ( this.moFocusedPanelIndex === -1 ) {
		if ( this.moFocusedRuleSetIndex != null ) {
			this.moRuleDefinitionObject.ruleSets.splice(this.moFocusedRuleSetIndex,1);
			this.undoStackPush(true);
			this.drawRuleDefinition();
		}
	} else {
		if ( this.moFocusedIndex != null ) {
			var jsonObject = this.moMainMap[this.moFocusedIndex].jsonObject;
			var jsonParentObject = this.moMainMap[this.moFocusedIndex].jsonParentObject;
			var jsonParentArrayObject = this.moMainMap[this.moFocusedIndex].jsonParentArrayObject;
			var jsonParentArrayIndex = this.moMainMap[this.moFocusedIndex].jsonParentArrayIndex;

			if ( jsonObject.type === "otherwise" ) {
				jsonParentObject.otherwise = null;
				if ( jsonParentObject.whens.length ) {
					this.moFocusedJsonObject[this.moFocusedPanelIndex] = jsonParentObject.whens[jsonParentObject.whens.length-1];
				} else {
					this.moFocusedJsonObject[this.moFocusedPanelIndex] = jsonParentObject;
				}
				this.moFocusedJsonProperty[this.moFocusedPanelIndex] = "type";
				this.undoStackPush(true);
				this.drawRuleSet(false);
			} else if ( jsonParentArrayObject != null ) {
				jsonParentArrayObject.splice(jsonParentArrayIndex,1);
				var jsonNextSiblingNode = jsonParentArrayObject[Math.min(jsonParentArrayIndex,jsonParentArrayObject.length-1)];
				this.moFocusedJsonObject[this.moFocusedPanelIndex] = jsonNextSiblingNode;
				this.moFocusedJsonProperty[this.moFocusedPanelIndex] = "type";
				this.undoStackPush(true);
				this.drawRuleSet(false);
			}
		}
	}
	return;
}

ClientMethod buttonDetailClicked() [ Language = javascript ]
{
	// Selectively determine whether we allow the associated dialog to be invoked, primarily because we need to allow
	// access to the Expression Editor for complicated expressions and the Constraint Editor for constraints.
	if ( this.moFocusedIndex != null ) {
		var jsonParentProperty = this.moMainMap[this.moFocusedIndex].jsonProperty;
		if (this.readOnly || !this.canEdit) {
			/*	only allow editors for expressions and constraints and
				transform selector if read only or cannot edit so that user
				can use link to the DTL editor */
			var permitted = false;
			switch(jsonParentProperty) {
				case 'condition':
				case 'value':
				case 'constraint':
				case 'transform':
					permitted = true;
					break;
			}
			if (!permitted) {
				this.checkEdit();
				return;
			}
		}
		if ( jsonParentProperty === "condition" ) {
			var parms= { EXP:zen("textEditor").getValue(), READONLY:((this.readOnly || !this.canEdit)?1 :0) };
			zenLaunchPopupWindow(zenLink('EnsPortal.ExpressionEditor.zen'),this.addPopupSuffix('editLogical'),'modal=yes,status,scrollbars,resizable=yes,width=640,height=550',parms);
		} else if ( jsonParentProperty === "value" ) {
			var parms= { EXP:zen("textEditor").getValue(), READONLY:((this.readOnly || !this.canEdit)?1 :0)};
			zenLaunchPopupWindow(zenLink('EnsPortal.ExpressionEditor.zen'),this.addPopupSuffix('editExpression'),'modal=yes,status,scrollbars,resizable=yes,width=640,height=550',parms);
		} else if ( (jsonParentProperty==="effectiveBegin")||(jsonParentProperty==="effectiveEnd") ) {
			var parms= { VALUE:zen("textEditor").getValue() };
			zenLaunchPopupWindow(zenLink('EnsPortal.DateTimeEditor.zen'),this.addPopupSuffix('editDateTime'),'modal=yes,status,scrollbars,resizable=yes,width=280,height=380',parms);
		} else if ( jsonParentProperty === "target" ) {
			// don't warn user if production hasn't been specified
			var parms= { PROD:this.moRuleDefinitionObject.production, TYPE:'target', MULTI:1, VALUE:zen("textEditor").getValue() };
			zenLaunchPopupWindow(zenLink('EnsPortal.ConfigItemSelector.zen'),this.addPopupSuffix('editTarget'),'status,scrollbars,resizable=yes,width=640,height=550',parms);
		} else if ( jsonParentProperty === "transform" ) {
			var parms = { VALUE: zen("textEditor").getValue() }
			zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.TransformSelector.zen'),this.addPopupSuffix('editTransform'),'status,scrollbars,resizable=yes,width=640,height=480',parms);
		} else if ( jsonParentProperty === "ruleName" ) {
			var parms= { MODE:"rules" };
			zenLaunchPopupWindow(zenLink('%ZEN.Dialog.finderDialog.zen'),this.addPopupSuffix('editRulename'),'status,scrollbars,resizable=yes,width=800,height=600',parms);
		} else if ( jsonParentProperty === "constraint" ) {
			var prod = ( this.moRuleDefinitionObject.isRoutingRule ? this.moRuleDefinitionObject.production : '' );
			var parms= { ASSIST:this.moRuleDefinitionObject.assistClass, PROD:prod, READONLY:((this.readOnly || !this.canEdit)?1 :0) };
			zenLaunchPopupWindow(zenLink('EnsPortal.ConstraintEditor.zen'),this.addPopupSuffix('editConstraint'),'modal=yes,status,scrollbars,resizable=yes,width=800,height=600',parms);
		}
	}
	return;
}

ClientMethod selectContextClass() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }
	var parms = {
		MODE : "classes",
		ABSTRACT : 0,
		GENERATED : "",
		SYSTEM : 0,
		PERCENT : 0,
		DATATYPE : 0,
		PRODUCT : 0
	};
	if ( !zen("headerContext").getProperty("disabled") ) {
		zenLaunchPopupWindow(zenLink('%ZEN.Dialog.finderDialog.zen'),this.addPopupSuffix('contextClass'),'status,scrollbars,resizable=yes,width=800,height=600', parms);
	}
	return;
}

ClientMethod textEditorKeypress() [ Language = javascript ]
{
	if ( (zenEvent.which===13)||(zenEvent.keyCode===13) ) {
		this.textOKClicked();
	}
	return;
}

ClientMethod textOKClicked() [ Language = javascript ]
{
	if ( this.moFocusedIndex != null ) {
		if (!this.checkEdit()) { return; } // don't trigger for all Enter keypresses!

		var focusedObject = this.moMainMap[this.moFocusedIndex];
		if ( focusedObject.jsonObject[focusedObject.jsonProperty] != zen("textEditor").getValue() ) {
			focusedObject.jsonObject[focusedObject.jsonProperty] = zen("textEditor").getValue();
			if ( focusedObject.jsonProperty === "condition" ) {
				this.CONDITION = zen("textEditor").getValue();
				var json = this.getComponentById("modelCondition");
				json.reloadContents();
				focusedObject.jsonObject.conditionObject = json.getContentObject();
			}
			this.undoStackPush(true);
			this.drawRuleSet(true);
			if ( (focusedObject.jsonObject.type==="ruleSet")&&(focusedObject.jsonProperty==="name") ) {
				this.drawTabs();
			}
		}
	}
	return;
}

ClientMethod xyzEditorKeyPressed(event) [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }

	// the current value is before the keyPress is applied, save it for comparision later
	this.oldTextValue = document.getElementById("xyzEditor").value;

	// right arrow on the last character completes the string
	if ( event.keyCode===39 ) {
		var selection = this.getSelection(document.getElementById("xyzEditor"));
		if ( (selection.start===selection.end) && (selection.start===this.oldTextValue.length) ) {
			document.getElementById("xyzEditor").value = document.getElementById("xyzGrayText").value;
		}
	}
	// tab key at any position completes the string
	if ( event.keyCode===9 ) {
		document.getElementById("xyzEditor").value = document.getElementById("xyzGrayText").value;
		// kill event to prevent focus being changed
		ZLM.killEvent(event);
	}
	// return means all done
	if ( event.keyCode===13 ) {
		if ( document.getElementById("xyzGrayText").value === document.getElementById("xyzEditor").value ) {
			this.xyzOKClicked();
		} else {
			document.getElementById("xyzGrayText").value = document.getElementById("xyzEditor").value;
			if ( this.iFrameCreated ) { document.getElementById("xyzSelectorIFrame").style.display = "none"; }
			document.getElementById("xyzSelector").style.display = "none";
		}
	}
	// escape key means all done
	if ( event.keyCode===27 ) {
		// On FireFox, under ESC, the value of xyzEditor is somehow rolled back if the previous action was the TAB key.
		// To reproduce this, do the following key sequence: %, TAB, ESC.
		// This probably is caused by the ZLM.killEvent(event) call in the TAB handling,
		// but we have no control over this rolling back.
		// We work around this problem by deferring the ESC action until after the rolling back has occured.
		setTimeout("zenPage.deferredEscapeAction()",1);
		return;
	}
	// up and down arrow changes the selection in the xyzSelector
	if ( event.keyCode===38 ) {
		if ( document.getElementById("xyzSelector").selectedIndex > 0 ) {
			document.getElementById("xyzSelector").selectedIndex --;
		}
		this.xyzSelectorChanged();
	}
	if ( event.keyCode===40 ) {
		if ( document.getElementById("xyzSelector").selectedIndex < (document.getElementById("xyzSelector").options.length)-1 ) {
			document.getElementById("xyzSelector").selectedIndex ++;
		}
		this.xyzSelectorChanged();
	}
	setTimeout("zenPage.xyzDoAction()",1);
	return;
}

ClientMethod deferredEscapeAction() [ Language = javascript ]
{
	document.getElementById("xyzEditor").value = this.oldTextValue;
	document.getElementById("xyzGrayText").value = this.oldTextValue;
	if ( this.iFrameCreated ) { document.getElementById("xyzSelectorIFrame").style.display = "none"; }
	document.getElementById("xyzSelector").style.display = "none";
	return;
}

ClientMethod xyzEditorOnBlur(event) [ Language = javascript ]
{
	this.xyzblurHandler = setTimeout("zenPage.xyzEditorLostFocus();",100);
	return;
}

ClientMethod xyzGrayTextGotFocus(event) [ Language = javascript ]
{
	// this is to handle IE9 problem that the control textbox is clicked through to the ghost textbox
	var length = document.getElementById("xyzEditor").value.length;
	this.setSelection(document.getElementById("xyzEditor"),length,length);
	document.getElementById("xyzEditor").focus();
	return;
}

ClientMethod xyzEditorLostFocus() [ Language = javascript ]
{
	document.getElementById("xyzGrayText").value = document.getElementById("xyzEditor").value
	if ( this.iFrameCreated ) { document.getElementById("xyzSelectorIFrame").style.display = "none"; }
	document.getElementById("xyzSelector").style.display = "none";
	return;
}

ClientMethod xyzSelectorFocused() [ Language = javascript ]
{
	if ( this.xyzblurHandler != null ) {
		clearTimeout(this.xyzblurHandler);
		this.xyzblurHandler = null;
	}
	document.getElementById("xyzEditor").focus();
	return;
}

ClientMethod xyzSelectorChanged() [ Language = javascript ]
{
	var select = document.getElementById("xyzSelector");
	document.getElementById("xyzGrayText").value = select.options[select.selectedIndex].text;
	return;
}

ClientMethod xyzSelectorDblClicked() [ Language = javascript ]
{
	document.getElementById("xyzEditor").value = document.getElementById("xyzGrayText").value;
	this.xyzDoAction();
	document.getElementById("xyzEditor").focus();
	return;
}

ClientMethod xyzDoAction() [ Language = javascript ]
{
	var textValue = document.getElementById("xyzEditor").value;
	if ( textValue === this.oldTextValue ) return;

	// check to see if we need to reload data
	var lastIndex = Math.max(textValue.lastIndexOf("."),textValue.lastIndexOf("{"),textValue.lastIndexOf(":"),textValue.lastIndexOf("@"));
	var xyzBase = textValue.substr(0,lastIndex+1);
	if ( xyzBase != this.xyzBase ) {
		this.xyzLoadData(xyzBase);
		var updatedDate = true;
	} else {
		var updatedData = false;
	}
	var textProperty = textValue.substr(lastIndex+1);
	var textPropertyLength = textProperty.length;
	var propertyFound = "";
	var propertyListFiltered = new Array();

	// search to see if partial match exists
	var extactMatchFound = false;
	for ( var i=0 ; i<this.propertyListComplete.length ; i++ ) {
		if ( this.propertyListComplete[i].substr(0,textPropertyLength) === textProperty ) {
			propertyListFiltered[propertyListFiltered.length] = xyzBase + this.propertyListComplete[i];
			if ( propertyFound === "" ) {
				propertyFound = xyzBase + this.propertyListComplete[i];
				exactMatchFound = (propertyFound === textValue);
			}
		}
	}

	// update the auto-complete text in gratText
	if ( propertyFound === "" ) {
		document.getElementById("xyzGrayText").value = textValue
	} else {
		document.getElementById("xyzGrayText").value = propertyFound;
	}

	// update the xyzSelector
	if ( propertyListFiltered.length < 1 ) {
		if ( this.iFrameCreated ) { document.getElementById("xyzSelectorIFrame").style.display = "none"; }
		document.getElementById("xyzSelector").style.display = "none";
	} else if ( (propertyListFiltered.length===1) && (exactMatchFound==true) ) {
		if ( this.iFrameCreated ) { document.getElementById("xyzSelectorIFrame").style.display = "none"; }
		document.getElementById("xyzSelector").style.display = "none";
	} else if ( (updatedData==false) && (exactMatchFound==true) ) {
		if ( this.iFrameCreated ) { document.getElementById("xyzSelectorIFrame").style.display = "none"; }
		document.getElementById("xyzSelector").style.display = "none";
	} else {
		if ((!this.iFrameCreated)) { //SAM055
			var div = document.getElementById("xyzSelectorParent");
			var iFrame = document.createElement("iframe");
			iFrame.id = 'xyzSelectorIFrame';
			iFrame.src = '';
			iFrame.frameBorder = '0';
			var s = iFrame.style;
			s.filter = 'alpha(opacity=0)';
			s.zIndex = '0';
			s.position = 'absolute';
			s.top = '0px';
			s.left = '0px';
			s.width = '100%';
			s.height = '100%';
			s.border = '0px solid black';
			s.background = 'transparent';
			div._iFrame = iFrame;
			div.insertBefore(div._iFrame,div.firstChild);
			this.iFrameCreated = true;
		}
		document.getElementById("xyzSelectorIFrame").style.display = "block";
		document.getElementById("xyzSelector").style.display = "block";
		// update the Combo has to be done after the stack is cleared so the screen can be painted correctly
		this.propertyListFiltered = propertyListFiltered;
		setTimeout("zenPage.deferredComboUpdate()",0);

	}
	return;
}

ClientMethod deferredComboUpdate() [ Language = javascript ]
{
	var propertyListFiltered = this.propertyListFiltered;
	var options = ""
	for ( var i=0 ; i<propertyListFiltered.length ; i++ ) {
		options = options + "," + propertyListFiltered[i]
	}
	this.setComboOptions(document.getElementById("xyzSelector"),options.substr(1),false);
	document.getElementById("xyzSelector").selectedIndex = 0;
	return;
}

ClientMethod xyzLoadData(xyzBase) [ Language = javascript ]
{
	this.xyzBase = xyzBase;
	if ( xyzBase==="@" ) {
		this.propertyListComplete = new Array();
		for ( var i=0 ; i<this.moRuleDefinitionObject.variables.length ; i++ ) {
			this.propertyListComplete[i] = this.moRuleDefinitionObject.variables[i].name;
		}
	} else {
		var context = new zenProxy();
		this.getRuleContext(context);
		var data = this.ServerGetPropertyList(context,xyzBase);
		this.propertyListComplete = new Array();
		this.propertyListComplete = data.split(",");
	}
	return;
}

ClientMethod getRuleContext(context) [ Language = javascript ]
{
	var currObject = this.moMainMap[this.moFocusedIndex];
	var jsonRuleObject = currObject.jsonRuleObject;
	if ( (jsonRuleObject!=null) && (jsonRuleObject.constraints!=null) ) {
		for ( var i=0 ; i<jsonRuleObject.constraints.length ; i++ ) {
			context[jsonRuleObject.constraints[i].name] = jsonRuleObject.constraints[i].value
		}
	}
	var jsonParentLoopObject = currObject.jsonParentLoopObject;
	if ( (jsonParentLoopObject!=null) && (jsonParentLoopObject.propertypath!="") ) {
		context["segName"] = this.getSegment(jsonParentLoopObject.propertypath);
	}
	if ((currObject!=null)&&(currObject.jsonProperty==="propertypath")) {
		context["%segsOnly"] = true;
	}
	context["%contextClass"] = this.moRuleDefinitionObject.context;
	context["%assistClass"] = this.moRuleDefinitionObject.assistClass;
	return;
}

ClientMethod getSegment(pathString) [ Language = javascript ]
{
	var segPath = pathString.slice(pathString.indexOf("{")+1,pathString.indexOf("}"));
	segPath = segPath.split(".");
	var segName = segPath[segPath.length-1];
	if (segName.indexOf("(")!=-1) {
		return segName.slice(0,segName.indexOf("("));
	} else {
		return segName;
	}
}

ClientMethod xyzOKClicked() [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }

	if ( this.moFocusedIndex > -1 ) {
		if ( this.moMainMap[this.moFocusedIndex] ) {
			if ( this.moMainMap[this.moFocusedIndex].jsonObject[this.moMainMap[this.moFocusedIndex].jsonProperty] != document.getElementById("xyzEditor").value ) {
				this.moMainMap[this.moFocusedIndex].jsonObject[this.moMainMap[this.moFocusedIndex].jsonProperty] = document.getElementById("xyzEditor").value;
				this.undoStackPush(true);
				this.drawRuleSet(true);
			}
		}
	}
	return;
}

ClientMethod setComboOptions(combo, options, insertBlank) [ Language = javascript ]
{
	if ( zenIsIE ) {
		while ( combo.options.length > 0 ) { combo.options.remove(0); }
		if ( insertBlank ) { combo.options.add(new Option("")); }
		var optionsArray = options.split(",")
		for ( var i=0 ; i<optionsArray.length ; i++ ) {
			var opt = new Option(optionsArray[i]);
			combo.options.add(opt);
		}
	} else {
		var optionsArray = options.split(",")
		var innerHTML = "";
		if ( insertBlank ) { innerHTML = "<option></option>"; }
		for ( i=0 ; i<optionsArray.length ; i++ ) {
			innerHTML = innerHTML + "<option>" + optionsArray[i] + "</option>"
		}
		combo.innerHTML = innerHTML;
	}
	return;
}

ClientMethod setComboValue(combo, value) [ Language = javascript ]
{
	combo.selectedIndex = -1;
	if ( zenIsIE ) {
		for ( var i=0 ; i<combo.options.length ; i++ ) {
			if ( combo.options[i].text === value ) {
				combo.selectedIndex = i;
			}
		}
	} else {
		combo.value = value;
	}
	return;
}

ClientMethod getSelection(ctrl) [ Language = javascript ]
{
	var selectionObject = {};
	if (document.selection) {
		// IE support
		ctrl.focus ();
		var Sel = document.selection.createRange();
		selectionObject.text = Sel.text;
		Sel.moveStart ('character', -ctrl.value.length);
		selectionObject.end = Sel.text.length;
		selectionObject.start = selectionObject.end - selectionObject.text.length;
	} else if (ctrl.selectionStart || ctrl.selectionStart === '0') {
		// Firefox support
		selectionObject.start = ctrl.selectionStart;
		selectionObject.end = ctrl.selectionEnd;
		selectionObject.text = ctrl.value.substring(selectionObject.start,selectionObject.end);
	}
	return selectionObject;
}

ClientMethod setSelection(ctrl, pos1, pos2) [ Language = javascript ]
{
	if(ctrl.setSelectionRange) {
		ctrl.focus();
		ctrl.setSelectionRange(pos1,pos2);
	} else if (ctrl.createTextRange) {
		var range = ctrl.createTextRange();
		range.collapse(true);
		range.moveEnd('character', pos2);
		range.moveStart('character', pos1);
		range.select();
	}
}

ClassMethod ServerGetPropertyList(proxy As %ZEN.proxyObject, pBase As %String) As %String [ ZenMethod ]
{
	do proxy.%CopyToArray(.tArray)
	set tAssistClass=$g(tArray("%assistClass"))
	if tAssistClass="" set tAssistClass="Ens.Rule.Assist"
	quit $classmethod(tAssistClass,"GetPropertyList",.tArray,pBase)
}

ClientMethod point(x, y) [ Language = javascript ]
{
	this.x=x;
	this.y=y;
}

Method InitializeServer(ByRef Params, Output pObject As %RegisteredObject) As %Status
{
	if ..RULE="" {
		set ..RULE=$g(^EnsPortal.Settings($username,"LastRule"))
		set ..isRuleClass = ##class(%Dictionary.XDataDefinition).IDKEYExists(..RULE,"RuleDefinition")
	}
	set:..isRuleClass ^EnsPortal.Settings($username,"LastRule")=..RULE

	// Retrieve last state for showProperty
	If (..RULE'="") && ($D(%session.Data("RuleEditor",..RULE,"showProperty"),showProperty)) && ($D(showProperty)=1) {
		Set ..showProperty = showProperty
	}

	// Retrieve last state for each rule in the current ruleSet; if state is not saved, assume null (all expanded)
	Set ruleStates = ..GetRuleStates(..RULE,..currentTab)
	Set ..ruleStates = ruleStates

	Do ..configureTestTab()

	Quit $$$OK
}

Method GetRuleDefinitionObject(ByRef Params, Output pObject As %RegisteredObject) As %Status
{
	Set tSC=$$$OK
	try {
		if '$IsObject(..%rule) {
			Set tSC = ..LoadRuleDefinition()
			If $$$ISERR(tSC) Quit
		}
		Set pObject = ..%rule
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	quit tSC
}

Method LoadRuleDefinition() As %Status
{
	Set tSC = $$$OK
	Try {
		Set ..%rule = ""
		If ..RULE = "" Quit
		If '..isRuleClass Quit

		Set tReadOnly = 0
		Set tSC = ..LoadClassDefinition(..RULE,.tClassDef,.tReadOnly)
		If $$$ISERR(tSC) {
			If ..isNew && $system.Status.Equals(tSC,$$$ERRORCODE($$$LoadObjectNotFound)) Set tSC = $$$OK
			Quit
		}

		#dim tRuleDef As Ens.Rule.Model.ruleDefinition
		Set tConcurrency = $select(tReadOnly: 0, 1: 4)
		Set tSC = ##class(Ens.Rule.Model.ruleDefinition).LoadFromClass(..RULE,.tRuleDef,,tConcurrency)
		If $$$ISERR(tSC) Quit

		If ..IsSourceControlReadOnly(..GetInternalName()) {
			Set tRuleDef.ReadOnly = 2
		}
		Else {
			Set tRuleDef.ReadOnly = tReadOnly
		}

		Set ..%rule = tRuleDef
	}
	Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method SaveRuleDefinitionObject(pCommand As %String, pProvider As %ZEN.Auxiliary.jsonProvider, pSubmitObject As %RegisteredObject, ByRef pResponseObject As %RegisteredObject) As %Status
{
	set tSC=$$$OK
	try {
		set tClassName=%page.RULE
		set ^EnsPortal.Settings($username,"LastRule")=%page.RULE
		set tReadOnly = 0
		if (pCommand '= "forcesave") && ##class(%Dictionary.ClassDefinition).%ExistsId(tClassName) {
			set tSC = ..LoadClassDefinition(tClassName,.tClassDef,.tReadOnly,1)
			if $$$ISERR(tSC) Quit
			if $zdatetime(tClassDef.TimeChanged,3,,6) '= pSubmitObject.Timestamp {
				Set pProvider.error = "timestamp"
				Quit
			}
		}
		If ..IsSourceControlReadOnly(..GetInternalName()) {
			Set pProvider.error = $$$Text("Your source control framework has marked this document as read only, so you will not be able to modify this document.")
			Quit
		}
		set tSC = pSubmitObject.SaveAs(tClassName) quit:$$$ISERR(tSC)
		set pResponseObject = pSubmitObject
		set pResponseObject.ReadOnly = tReadOnly

		// Kill class definition to avoid holding exclusive lock during multi-compile
		kill tClassDef
		set tSC=$system.OBJ.Compile(tClassName,"k-d")  quit:$$$ISERR(tSC)
	} catch {
		set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	quit tSC
}

Method GetConditionObject(ByRef Params, Output pObject As %RegisteredObject) As %Status
{
	set tSC = ##class(Ens.Rule.Model.expression).parse(%page.CONDITION,.pObject,1)
	quit tSC
}

Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)
	Set tPageName = $$$Text("Rule Editor","Ensemble")
	Set pLink(2)=$LB(tPageName,"#")
	Quit $$$OK
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Do ..InitializeServer()
	If (%page.RULE'="" && %page.isRuleClass) Quit %page.RULE
	Else  Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Rule Editor","Ensemble")
}

/// Get information to display in the ribbon bar.
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String) As %Status
{
	Set pDisplay = 1
	Set pSearchBox = 0
	Set pRibbonTitle = $$$Text("Rule Editor")

	//Set pViewIcons(1) = $LB("enterprise",$$$Text("Show enterprise view"),"portal/view_zoom_in.png")
	//Set pViewIcons(2) = $LB("productions",$$$Text("Show production view"),"portal/view_zoom_out.png")

	// commands: $LB(id,caption,help,onclick,hidden)
	Set cannotSave = (%page.RULE="")||('%page.isRuleClass)
	Set pCommands(1) = $LB("cmdNew",$$$Text("New"),..tipNew,"zenPage.newRule('');")
	Set pCommands(2) = $LB("cmdOpen",$$$Text("Open"),..tipOpen,"zenPage.openRule();")
	Set pCommands(3) = $LB("cmdSave",$$$Text("Save"),..tipSave,"zenPage.saveRule(false);",cannotSave)
	Set pCommands(4) = $LB("cmdSaveAs",$$$Text("Save As"),..tipSaveAs,"zenPage.saveRule(true);",cannotSave)
	Set pCommands(5) = $LB("btnContractAll",$$$Text("Contract"),..tipContractAll,"zenPage.collapseOrExpandAll(true);",cannotSave)
	Set pCommands(6) = $LB("btnExpandAll",$$$Text("Expand"),..tipExpandAll,"zenPage.collapseOrExpandAll(false);",cannotSave)

	Quit $$$OK
}

/// This is called in the middle of rendering the tool ribbon.
/// Subclasses can inject their own content into the ribbon by writing it out in this method.
/// This content should be wrapped within a td element.
Method OnDrawRibbon() As %Status
{
	Set tNewWindowDescr = $$$TextHTML("If this option is checked, a new browser window will be used when a Rule is created or opened")
	&html<<td><div class="spacer" style="width: 24px;"></div></td>>
	&html<<td class="ribbonAction" title="#(tNewWindowDescr)#"><input id="openNewWindow" type="checkbox" onchange="javascript: zenPage.openNewWindow=!zenPage.openNewWindow;" #($S(..openNewWindow: "checked=""checked""", 1:""))#></input><span>#($$$TextHTML("Open new windows"))#</span></td>>

	Set tSizeDescr = $$$TextHTML("Select the size of the diagram")
	&html<<td><table><tr><td ><div class="spacer" style="width: 24px;"></div></td><td title="#(tSizeDescr)#">
	<select id="menuZoom" style="height:20px;" onChange="zenPage.menuZoomChanged(this);">
	<option value="25">25%</option>
	<option value="50">50%</option>
	<option value="75">75%</option>
	<option value="85">85%</option>
	<option value="100" selected>100%</option>
	<option value="110">110%</option>
	<option value="125">125%</option>
	<option value="150">150%</option>
	<option value="200">200%</option>
	</select>
	</td></tr></table>
	</td>>

	Quit ##super()
}

ClientMethod newRule(ruleName) [ Language = javascript ]
{
	if (!this.checkEdit()) { return; }
	var parms = {RULE:ruleName};
	zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.BusinessRuleWizard.zen'),this.addPopupSuffix('newRule'),'status,scrollbars,resizable=yes,left=100,top=100,width=700,height=700',parms);
}

ClientMethod openRule() [ Language = javascript ]
{
	zenLaunchPopupWindow(zenLink('%ZEN.Dialog.finderDialog.zen?MODE=rules'),this.addPopupSuffix('openRule'),'status,scrollbars,resizable=yes,width=800,height=600');
	return;
}

ClientMethod saveRule(showDialog, oldName) [ Language = javascript ]
{
	if (!this.canUserModify(showDialog||zenPage.renamed)) { return; }
	if (!this.validateRule()) {
		alert($$$Text("There are errors in this Rule. Please correct the problems before saving."));
		// Enable correction of document after failed Save As while readonly
		if (showDialog && this.readOnly) {
			this.setReadOnly(false);
			zenPage.grayOutOneButton('command_cmdSave');
		}
		return false;
	}
	if ( showDialog ) {
		var parms = { RULE:this.RULE, ALIAS:zenPage.moRuleDefinitionObject.alias };
		zenLaunchPopupWindow(zenLink('EnsPortal.Dialog.BusinessRuleSave.zen'),this.addPopupSuffix('saveRule'),'status,scrollbars,resizable=yes,width=700,height=600',parms);
	} else {
		if (this.moRuleDefinitionObject.alias!='') {
			var msg = this.ValidateAlias(this.RULE,this.moRuleDefinitionObject.alias);
			if (msg!='') {
				alert(msg);
				return false;
			}
		}
		var json = this.getClientModel();
		json.setContentObject(this.moRuleDefinitionObject);
		if (zenPage.renamed && this.readOnly) {
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

		if (ok) {
			this.undoStackResetModified();
			setTimeout(function() {
				alert($$$FormatText($$$Text("Rule '%1' saved and compiled successfully."),zenPage.RULE));
				if (zenPage.renamed == true) {
					if (zenPage.NEW) zenPage.deleteUncompiledRule(oldName);
					self.document.location = zenLink("EnsPortal.RuleEditor.zen" + '?RULE=' + encodeURIComponent(zenPage.RULE) + '&RENAMED=1');
				}
			}, 50);
		} else {
			if (zenPage.renamed == true) {
				zenPage.renamed = false;
				zenPage.RULE = oldName;
				// Enable correction of document after failed Save As while readonly, but only if failure is a validation error and not source control/timestamp
				if (this.readOnly && this.pageModified) {
					var json = this.getClientModel();
					if (json.error.substring(0,5)=="ERROR") {
						this.setReadOnly(false);
						zenPage.grayOutOneButton('command_cmdSave');
						alert($$$Text('Please correct errors before saving.'));
					}
				}
			} else 	if (zenPage.getIsReadOnly()) {
				// If this document was found to be readOnly, gray out buttons to indicate this
				zenPage.grayOutButtons();
			}
		} // saveDocument() already alerts the user to errors, so no else block
	}
	return;
}

ClassMethod ValidateAlias(pClassName, pAlias) As %String [ ZenMethod ]
{
	Set msg = ""
	If $d(^Ens.Rule("class",pAlias)) || (pClassName=pAlias) {
		Set msg = $$$Text("Alias name already in use as a class name; choose another alias.  Remember alias is not required.")
	}
	Quit msg
}

/// Ensure we redraw the diagram if the model was updated.
ClientMethod onDocumentSaveComplete(contentUpdated) [ Language = javascript ]
{
	this.invokeSuper('onDocumentSaveComplete',arguments);
	if (contentUpdated) {
		var json = this.getClientModel();
		var ruleModel = json.getContentObject();
		if (ruleModel) {
			this.moRuleDefinitionObject = ruleModel;
			this.drawRuleDefinition();
		}
	}
}

/// Ensure we redraw the diagram if a reload was requested
ClientMethod onDocumentReload(reason) [ Language = javascript ]
{
	if (this._inReload) { return; } // avoid recursion
	this._inReload = true;
	this.updateDocumentState(true);
	if (reason == "dataChange") {
		var json = this.getClientModel();
		var ruleModel = json.getContentObject();
		if (ruleModel) {
			this.moRuleDefinitionObject = ruleModel;
			this.drawRuleDefinition();
			this.setModified(false);
		}
	}
	this._inReload = false;
}

ClientMethod validateRule() [ Language = javascript ]
{
	var isValid = true;
	if (this.moMainMap) {
		for (var i = 0; i < this.moMainMap.length; i++) {
			var mapObject = this.moMainMap[i];
			var jsonObject = mapObject.jsonObject;
			if (jsonObject && jsonObject.type && this._validationData[jsonObject.type]) {
				var propList = this._validationData[jsonObject.type];
				for (var j = 0; j < propList.length; j++) {
					var errText = this.getPropertyErrorText(jsonObject,propList[j]);
					if (errText != '') {
						isValid = false;
						break;
					}
				}
				if (!isValid) break;
			}
		}
	}
	return isValid;
}

ClientMethod menuZoomChanged(objMenu) [ Language = javascript ]
{
	zen("svgPanel").setProperty("zoom",objMenu.value);
	this.drawRuleSet(false);
	return;
}

ClientMethod newObject(objType) [ Language = javascript ]
{
	return new window[objType];
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != 'ok') return false;
	popupName = this.removePopupSuffix(popupName);
	if (this.readOnly || !this.canEdit) {
		var permittedAction = false;
		switch(popupName) {
			case 'openRule':
			case 'switchNamespace':
				permittedAction = true;
				break;
			case 'saveRule':
				permittedAction = zenPage.renamed;
				break;
			case 'testContextSet':
			case 'testSourceSet':
				permittedAction = true;
				break;
			case 'newRule':
				/* allow new option if there is a current rule marked read only */
				if (this.canEdit) permittedAction = true;
				break;
		}
		if (!permittedAction) {
			return;
		}
	}
	switch(popupName) {
		case 'openRule':
			if ( value.substr(value.length-4,4)===".rul" ) { value = value.substr(0,value.length-4); }
			if ( value.substr(value.length-4,4)===".cls" ) { value = value.substr(0,value.length-4); }
			setTimeout(function() {
				var url = zenLink("EnsPortal.RuleEditor.zen?RULE="+value);
				if (zenPage.openNewWindow) {
					window.open(url);
				}
				else {
					document.location = url;
				}
			}, 200);
			break;
		case 'editLogical':
			setTimeout(function() {
				zen("textEditor").setValue(value);
				zenPage.textOKClicked();
			}, 200);
			break;
		case 'editExpression':
		case 'editDateTime':
		case 'editTarget':
		case 'editTransform':
			setTimeout(function() {
				zen("textEditor").setValue(value);
				zenPage.textOKClicked();
			}, 200);
			break;
		case 'editRulename':
			setTimeout(function() {
				if ( value.substr(value.length-4,4)===".rul" ) { value = value.substr(0,value.length-4); }
				if ( value.substr(value.length-4,4)===".cls" ) { value = value.substr(0,value.length-4); }
				zen("textEditor").setValue(value);
				zenPage.textOKClicked();
			}, 200);
			break;
		case 'contextClass':
			setTimeout(function() {
				if ( value.substr(value.length-4,4)===".cls" ) { value = value.substr(0,value.length-4); }
				if ( zenPage.moRuleDefinitionObject.context != value ) {
					zenPage.moRuleDefinitionObject.context=value;
					zen("headerContext").setValue(value);
					zenPage.undoStackPush(true);
				}
			}, 200);
			break;
		case 'editConstraint':
			setTimeout(function() {
				zenPage.drawRuleSet(false);
				zenPage.undoStackPush(true);
			}, 200);
			break;
		case 'newRule':
			if (value!='') {
				setTimeout(function() {
					var url = zenLink("EnsPortal.RuleEditor.zen" + '?RULE=' + encodeURIComponent(value) + '&NEW=1');
					if (zenPage.openNewWindow) {
						window.open(url);
					}
					else {
						self.document.location = url;
					}
				}, 200);
			}
			break;
		case 'saveRule':
			setTimeout(function() {
				zenPage.saveRule(false,value);
			}, 200);
			break;
		case 'switchNamespace':
			zenPage.changeURLNamespace(value);
			break;
		case 'testContextSet':
			setTimeout(function() {
				zen('testContextSerialized').setValue(value);
			}, 200);
			break;
		case 'testSourceSet':
			setTimeout(function() {
				zen('testSource').setValue(value);
			}, 200);
			break;
		default:
			alert(popupName);
	}
}

/// Helper method to hide or show SVG elements when opening a popup.
/// This is primarily to ensure that we don't run into issues with IE8 and
/// the Adobe plugin when the popup window also uses SVG.
/// The approach used to "hide" the SVG embed is to reduce its wrapping div to 1px by 1px
/// during the modal. We use the wrapping div to avoid having the SVG re-rendered
/// after we re-expand after the modal ends. We don't use style.display = 'none'/'block'
/// as this makes the SVG non-interactive after the SVG is set back to 'block'.
ClientMethod toggleSVGElements(show) [ Language = javascript ]
{
	if (this._svgData && this._svgData.list) {
		for (var i=0; i<this._svgData.list.length; i++) {
			var itemData = this._svgData.list[i];
			var wrappingDiv = itemData.component.getEnclosingDiv();
			wrappingDiv = (wrappingDiv ? wrappingDiv.parentNode : null);
			var svgDiv = itemData.component.findElement('svgdiv');
			if (show) {
				if (itemData.styles) {
					if (wrappingDiv) wrappingDiv.style.background = itemData.styles.background;
					if (svgDiv) {
						svgDiv.style.height = itemData.styles.height + 'px';
						svgDiv.style.width = itemData.styles.width + 'px';
					}
				}
			}
			else {
				var styles = null;
				if (wrappingDiv) {
					styles = { "background": wrappingDiv.style.background };
					wrappingDiv.style.background = '#F0F0F0';
				}
				if (svgDiv) {
					if (!styles) styles = {};
					styles.height = svgDiv.offsetHeight;
					styles.width = svgDiv.offsetWidth;
					svgDiv.style.height = '1px';
					svgDiv.style.width = '1px';
				}
				itemData.styles = styles;
			}
		}
	}
}

ClientMethod buildConstraintCache() [ Language = javascript ]
{
	this.clearConstraintCache();
	var jsonData = this.getClientModel().getContentObject();
	if (jsonData && jsonData.constraintCache) {
		var cache = jsonData.constraintCache;
		if (typeof cache.empty != 'undefined') this._constraintCache.empty = cache.empty;
		if (cache.serverData) {
			for (var i = 0; i < cache.serverData.length; i++) {
				var pair = cache.serverData[i];
				this._constraintCache.path[pair.key] = pair.value;
			}
		}
	}
}

ClientMethod clearConstraintCache() [ Language = javascript ]
{
	this._constraintCache = { "path": {} };
}

ClientMethod constraintGetDisplay(rule) [ Language = javascript ]
{
	if (!this._constraintCache) this.buildConstraintCache();
	var proxy = new zenProxy();
	var cachePath = [];
	if ( rule.constraints ) {
		for ( var i=0 ; i<rule.constraints.length ; i++ ) {
			proxy[rule.constraints[i].name] = rule.constraints[i].value;
			cachePath.push(rule.constraints[i].name + '\x01' + rule.constraints[i].value);
		}
	}
	cachePath = cachePath.join('\x00');
	var value = '';
	if ((cachePath === '') && (typeof this._constraintCache.empty != 'undefined')) {
		value = this._constraintCache.empty;
	}
	else if ((cachePath !== '') && (typeof this._constraintCache.path[cachePath] != 'undefined')) {
		value = this._constraintCache.path[cachePath];
	}
	else {
		value = this.GetRuleAssistShortDisplay(this.moRuleDefinitionObject.assistClass,proxy);
		if (cachePath !== '') {
			this._constraintCache.path[cachePath] = value;
		}
		else {
			this._constraintCache.empty = value;
		}
	}
	rule.constraint = value;
	return;
}

ClassMethod GetRuleAssistShortDisplay(pClass As %String, pProxy As %ZEN.proxyObject) As %String [ ZenMethod ]
{
	do pProxy.%CopyToArray(.tArray)
	quit $classmethod(pClass,"GetShortDisplay",.tArray)
}

/// Hide/show assist panel.
ClientMethod toggleHelp() [ Language = javascript ]
{
	this.helpVisible = !this.helpVisible;
	var span = self.document.getElementById('helpCommandArrow');
	if (this.helpVisible) {
		span.innerHTML = '&#187;';
	}
	else {
		span.innerHTML = '&#171;';
	}
	this.onlayoutHandler(false);
}

/// Return the internal name of the current document.
Method GetInternalName() As %String
{
	Quit $select(..RULE = "": "", 1: $$$NormalizeClassname(..RULE)_".CLS")
}

/// Get the JSON model on the client.
ClientMethod getClientModel() [ Language = javascript ]
{
	return zen('modelRuleDefinition');
}

/// Return the current name of the class/object being modified
ClientMethod getCurrentName() [ Language = javascript ]
{
	return zenPage.RULE;
}

/// Show or hide message box.
ClientMethod showMsgBox(pShow) [ Language = javascript ]
{
	var svg = zen('svgPanel');

	if (this._msgBox) {
		try { svg.svgGroup.removeChild(this._msgBox); } catch(ex) { }
		delete this._msgBox;
	}

	if (!pShow) return;

	var svgDiv = svg.getEnclosingDiv();
	var svgDiv = document.getElementById('svgScrollingArea');
	topY = svgDiv.scrollTop;

	// message box with text "Updating diagram..."
	var group = svg.document.createElementNS(SVGNS,'g');
	this._msgBox = group;
	group.setAttribute('id','updatingDiagram');
	svg.svgGroup.appendChild(group);
	var msg = $$$Text('Updating diagram...');
	var helpWid = this.helpVisible ? 300 : 40;
	var wwid = zenGetWindowWidth() - helpWid + 12;
	wwid = (wwid < 0 ? 0 : wwid);
	var svgwid = svg.width;
	var svgWidth = Math.min(wwid,svgwid);
	var w = 143;
	var h = 32;
	var box = svg.document.createElementNS(SVGNS,'rect');
	box.setAttribute('id','updatingDiagramBox');
	box.setAttribute('x',svgWidth/2 - w/2);
	box.setAttribute('y',topY + 10);
	box.setAttribute('width',w);
	box.setAttribute('height',h);
	box.setAttribute('rx',2);
	box.setAttribute('class','msgBox');
	group.appendChild(box);
	var label = svg.document.createElementNS(SVGNS,'text');
	label.setAttribute('class','msgBoxText');
	label.setAttribute('x',svgWidth/2 - w/2 + 10);
	label.setAttribute('y',topY + 31);
	var textNode = svg.document.createTextNode(msg);
	label.appendChild(textNode);
	group.appendChild(label);
	var tw = label.getComputedTextLength() + 20;
	box.setAttribute('width',tw);
}

ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod,
				"SaveRuleDefinitionObject": ..#EDITRESOURCE,
				: ##super(pMethod))
}

/// Ensure the timestamp for the current BPL is loaded and sent out to the client.
Method %OnAfterCreatePage() As %Status
{
	#dim tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	If ..readOnly || ('..canEdit) { // disable controls in main page
		For ctrl = "headerDescription","headerRuleTypeCombo","headerAssistClassCombo","headerContext","headerAlias","headerVariables","headerProduction","textOK","xyzOK" {
			Set ..%GetComponentById(ctrl).disabled = 1
		}
	}
	If (..RULE="") && (..RULELCP'="") Set ..RULE=..RULELCP
	If (..RULE '= ""){
		If ..isNew {
			Set ..isNew = '##class(%Dictionary.ClassDefinition).%ExistsId(..RULE)
			Set:(..isNew) ..isNew = (($ZNAME(..RULE,4)) && (..RULE["."))
		}
		If (..isNew) {
			Set tSC = ..CreateRuleClass(..RULE)
			Set:$$$ISERR(tSC) ..isNew = 0
		}
		Set:('..isNew) ..isRuleClass = ##class(%Dictionary.XDataDefinition).IDKEYExists(..RULE,"RuleDefinition")
	}

	Set ..canViewContents = $system.Security.Check("%Ens_MessageContent","USE")

	Set ..canViewRuleLogs = $system.Security.Check("%Ens_RuleLog","USE")

	Set ..canTestRules = $system.Security.Check("%Ens_TestingService","USE")

	Quit ..LoadRuleDefinition()
}

ClientMethod setReadOnly(readOnly) [ Language = javascript ]
{
	readOnly = !!readOnly;
	this.readOnly = readOnly;
	var ctrls = ['headerDescription','headerRuleTypeCombo','headerAssistClassCombo','headerContext','headerAlias','headerVariables','headerProduction','textOK','xyzOK','textEditor']
	for (i in ctrls) {
		var ctrl = ctrls[i];
		if (zen(ctrl)) {
			zen(ctrl).setProperty('disabled',readOnly);
		}
	}
	document.getElementById('xyzEditor').disabled = readOnly;

	this.updateButtons();
	this.updateMenuAdd();
	this.updateHelpPanel();

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
			btnSave.onclick = function() { zenPage.saveRule(false);return false; }
			btnSave.title = this.tipSave;
		}
	}
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

/// Create a new Rule class.
ClassMethod CreateRuleClass(pClassName As %String) As %Status [ ZenMethod ]
{
	Set tMsg = ##class(EnsPortal.Dialog.BusinessRuleWizard).CreateRuleClass("",pClassName)
	If tMsg = "" {
		Set tSC = $$$OK
	} Else {
		Set tSC = $$$ERROR($$$EnsErrGeneral,tMsg)
	}
	Quit tSC
}

/// Delete the class definition for a Rule that a user might
/// have created with the New option, not saved and then renamed
/// using Save As.
ClassMethod deleteUncompiledRule(pClassName As %String) As %Status [ ZenMethod ]
{
	Set tSC = $$$OK
	Try {
		Quit:($D(^Ens.Rule("class",pClassName)))
		#;account for mapped rules that have not been compiled locally
		Quit:(##class(%Dictionary.CompiledClass).%ExistsId(pClassName))
		Set tSC = ##class(%Dictionary.ClassDefinition).%DeleteId(pClassName)
	}
	Catch {
		Set tSC = $$$SystemError
	}
	Quit tSC
}

ClassMethod SaveRuleState(pRuleName As %String, pRuleSetNo As %Integer, pRuleNo As %Integer, pIsCollapsed As %Boolean) As %String [ Internal, ZenMethod ]
{
	If ($G(pRuleName)="") || ('$D(pRuleSetNo)) || (+$G(pRuleSetNo)<0) || ('$D(pRuleNo)) || (+$G(pRuleNo)<0) || ('$D(pIsCollapsed)) Quit ""

	Set ruleStates = $G(%session.Data("RuleEditor",pRuleName,"ruleStates",+$G(pRuleSetNo)),"_")
	Set $E(ruleStates,pRuleNo+2) = ''pIsCollapsed
	Set %session.Data("RuleEditor",pRuleName,"ruleStates",+$G(pRuleSetNo)) = ruleStates
	Quit ruleStates
}

/// Return string with saved states for each rule in the current ruleSet
/// If state is not saved, assume null (i.e. all expanded)
ClassMethod GetRuleStates(pRuleName As %String, pRuleSetNo As %Integer) As %String [ Internal, ZenMethod ]
{
	Set ruleStates = ""
	If (pRuleName'="") && (+$G(pRuleSetNo)>-1) && (+$G(pRuleSetNo)<=$Order(%session.Data("RuleEditor",pRuleName,"ruleStates",""),-1)) {
		Set ruleStates = $G(%session.Data("RuleEditor",pRuleName,"ruleStates",+$G(pRuleSetNo)))
	}
	Quit ruleStates
}

/// Save to %session the states for all rules in the current ruleSet
ClassMethod SetRuleStates(pRuleName As %String, pRuleSetNo As %Integer, pRuleStates As %String = "") [ Internal, ZenMethod ]
{
	If (pRuleName'="") && (+$G(pRuleSetNo)>-1) {
		Set %session.Data("RuleEditor",pRuleName,"ruleStates",+$G(pRuleSetNo)) = pRuleStates
	}
	Quit
}

ClassMethod SaveViewPropertyState(pRuleName As %String, pState As %Boolean) [ Internal, ZenMethod ]
{
	Set:$G(pRuleName)'="" %session.Data("RuleEditor",pRuleName,"showProperty") = +$G(pState)
	Quit
}

Method %OnDrawHTMLHead() As %Status
{
	Do %session.Unlock()
	Quit ##super()
}

/*
	Rule Test properties
*/
/// Flag to indicate whether the user is permitted to view body contents of stored data.
Property canViewContents As %ZEN.Datatype.boolean;

/// Flag to indicate whether the user is permitted to view Rule logs for testing
Property canViewRuleLogs As %ZEN.Datatype.boolean;

/// Flag to indicate whether the user is permitted to test
Property canTestRules As %ZEN.Datatype.boolean;

/// This is the class used for data - either the context class
/// or the Document class is a routing rule
Property docClass As %String;

/// Where to find test data - Header, Body or Paste
Property contextSource As %String;

/// If source of data is from a message header's message body
Property docHeader As %String;

/// Id of message body used for data source
Property docId As %String;

/*
{
	"%clsname": "EnsLib.HL7.Message",
	"%IDXCONT": "MSH|^~\\&|XYZEC|CCF|PHARMACY|2623735|20050126150624|11111|ORM^O01|104|T|2.3||\nPID||16284718^^^^AM|Z1907||JONES^IVAN^S^A^^^||19490518|M|||4536 BAKER AVENUE^^MEDFORD^MA^06453^US^^^||(617)962-2876||||||000-00-0000||||\nORC|NW|244674^EPC|||||^^^200501260000^200503272359^Norm^||20050126|11111^JONES^IVAN^S.^^^||AC2876925^JONES^IVAN^S.^^^||(608)303-2340||||||||||9500 Euclid Avenue A91^^CLEVELAND^OH^44195\nRXO|0045--04-52-2^PRILOSEC 325 MG PO TABS^NDC|60||^|||2 tabs po q4-6 hr PRN||G||||12|AC2876925^JONES^IVAN^S.^^^||||||||\nNTE|1|||\nORC|NW|244674^EPC|||||^^^200501260000^200503272359^Norm^||20050126|11111^JONES^IVAN^S.^^^||AC2876925^JONES^IVAN^S.^^^||(608)303-5849||||||||||9500 Diogenes Road A91^^CLEVELAND^OH^44195\nRXO|0045--04-52-2^WELLBUTRIN 325 MG PO TABS^NDC|60||^|||2 tabs po q4-6 hr PRN||G||||12|AC2876925^JONES^IVAN^S.^^^||||||||\nNTE|1|||",
	"OriginalDocId": "",
	"ParentId": "",
	"CacheSegsGotten": 1,
	"TimeCreated": "2018-04-10 09:09:10.715",
	"Source": "ABC_HL7FileService",
	"IsMutable": 1,
	"AutoBuildMap": 0,
	"DocType": "Demo.HL7.MsgRouter.Schema:ORM_O01",
	"Envelope": "",
	"Separators": "|^~\\&"
}
*/
/// User entered production source item for the test 
Property testSource As %String(MAXLEN = 128);

/// User entered message data serialized
Property contextSerialized As %String(MAXLEN = "");

/// HTML rendition of the test message contents
Property testMessageHTML As %String(MAXLEN = "");

/// Indicate if test message needs HTML escaping before writing to current device
Property testMessageNeedsEscaping As %Boolean [ InitialExpression = 1 ];

/// test Result as JSON
Property testResultJSON As %String(MAXLEN = "");

/// test Result error message As %String
Property testError As %String(MAXLEN = "");

/// Indicates if the test ran without an error (an error in the Rule counts as OK)
Property testRanOK As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Flag to show message contents or not
Property showTestMessage As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Flag to indicate if a routing rule
Property testIsRoutingRule As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/*
	Rule Test JS methods
*/
/// What to do when the user selects a new testContextSource value.
ClientMethod changeContextSource() [ Language = javascript ]
{
	var val = zen('testContextSource').getValue(); // Header,Body, Paste
	if (val.match('Header')) {
		zen('docSourceLbl').setProperty('label',$$$Text('Enter Message Header ID'));
		zen('docHeader').setHidden(0);
		zen('docId').setHidden(1);
		zen('msgEnterData').setHidden(1);
	}
	else if (val.match('Body')) {
		zen('docSourceLbl').setProperty('label',$$$Text('Enter Document Body ID'));
		zen('docHeader').setHidden(1);
		zen('docId').setHidden(0);
		zen('msgEnterData').setHidden(1);
	}
	else if (val.match('Paste')) {
		zen('docSourceLbl').setProperty('label',$$$Text('Enter Message fields'));
		zen('docHeader').setHidden(1);
		zen('docId').setHidden(1);
		zen('msgEnterData').setHidden(0);
	}
	else {
		// this should never happen
	}
	zen('testResults').setHidden(1);
}

ClientMethod testSourceLookup() [ Language = javascript ]
{
	var parms = {PROD:this.moRuleDefinitionObject.production, TYPE:'source', MULTI:0, VALUE:zen("testSource").getValue() };
	zenLaunchPopupWindow(zenLink('EnsPortal.ConfigItemSelector.zen'),this.addPopupSuffix('testSourceSet'),'status,scrollbars,resizable=yes,width=600,height=480',parms);
}

ClientMethod btnEnterData() [ Language = javascript ]
{
	var context = this.docClass;
	var parms= {CONTEXT:context};
	var url=this.GetObjectEntryURL()

	zenLaunchPopupWindow(url,this.addPopupSuffix('testContextSet'),'modal=yes,status,scrollbars,resizable=yes,width=1000,height=800',parms);
	return false;
}

ClientMethod btnTest() [ Language = javascript ]
{
	// Check if rule has been modified
	if (this.pageModified) {
		var msgModified=$$$Text("This Rule has been modified.")
		var msgOptionA=$$$Text("Press OK to test with the current server version.")
		var msgOptionB=$$$Text("Press Cancel to return to the editor to save .")
		var msg = msgModified+"\n\n"+msgOptionA+"\n\n"+msgOptionB
		if (!confirm(msg)) return;
	}
	zenPage.contextSource =zen('testContextSource').getValue();
	zenPage.docId = zen('docId').getValue();
	zenPage.contextSerialized = zen('testContextSerialized').getValue();
	zenPage.docHeader = zen('docHeader').getValue();
	zenPage.testSource = zen('testSource').getValue();
	zenPage.testRanOK = zenPage.runTest();
	if (zenPage.testRanOK) {
		zen('testMessageDisplay').refreshContents(true);
		zen('testRuleLogDisplay').refreshContents(true);
		zen('testDebugLogDisplay').refreshContents(true);
		zen('testErrorResultPane').setHidden(true);
		zen('testMessageDisplayPane').setHidden(false);
		zen('testRuleLogDisplayPane').setHidden(false);
		zen('testDebugLogDisplayPane').setHidden(false);
	} else {
		zen('testErrorResult').refreshContents(true);
		zen('testErrorResultPane').setHidden(false);
		zen('testMessageDisplayPane').setHidden(true);
		zen('testRuleLogDisplayPane').setHidden(true);
		zen('testDebugLogDisplayPane').setHidden(true);
	}
	zen('testResults').setHidden(false);
}

ClientMethod toggleMessageDiv(show) [ Language = javascript ]
{
		zenPage.showTestMessage = show;
		zen('testMessageDisplay').refreshContents();
}

/*
	Rule Test Server Side methods - UI handing
*/
/// Used to configure test data entry pane
Method configureTestTab()
{

	/*	Get information for testing from ..%rule.
		Called by InitializeServer
	*/
	Try {

		If '$IsObject(..%rule) {

				If $$$ISERR(..LoadRuleDefinition()) Quit

		}

		If '$IsObject(..%rule) {Quit}

		#dim tTestSourceComponent = ..%GetComponentById("testSourceRow")
		#dim tContextSourceListComponent = ..%GetComponentById("testContextSource")
		#dim tContextSourceListComponentLbl = ..%GetComponentById("testContextSourceRow")
		#dim tUserEnterDataComponentLbl = ..%GetComponentById("docSourceLbl")

		If ..%rule.isRoutingRule {

			Set ..testIsRoutingRule = 1

			Set tContextSourceListComponentLbl.label = $$$TextHTML("Context Document object")

			Set tUserEnterDataComponentLbl.label = $$$TextHTML("Enter Message fields")

			#; Determine docClass from context class

			#dim tRuleContextClass = ..%rule.context
			If $classmethod(tRuleContextClass,"%Extends","EnsLib.HL7.MsgRouter.RoutingEngine") {

				Set ..docClass = "EnsLib.HL7.Message"

			} ElseIf $classmethod(tRuleContextClass,"%Extends","EnsLib.MsgRouter.VDocRoutingEngine") {

				Set ..docClass = "EnsLib.EDI.Document"

			} Else {

				#;EnsLib.MsgRouter.RoutingEngine
				Set ..docClass = "%Library.Persistent"

			}

		} Else {

			Set ..testIsRoutingRule = 0

			#; No Source user entry
			Set tTestSourceComponent.hidden = 1

			#; Change labels for Context
			Set tContextSourceListComponentLbl.label = $$$TextHTML("Context object")

			Set tUserEnterDataComponentLbl.label = $$$TextHTML("Enter Context fields")

			#; docClass is context class
			Set ..docClass = ..%rule.context
			If ..docClass = "" Set ..docClass = "%Library.Persistent"

			#; Remove Header option
			Set tContextSourceListComponent.valueList = $Replace(tContextSourceListComponent.valueList,"Header,","")
			Set tContextSourceListComponent.displayList = $Replace(tContextSourceListComponent.displayList,"Message Header ID,","")
			#; Remove Body option
			Set tContextSourceListComponent.valueList = $Replace(tContextSourceListComponent.valueList,"Body,","")
			Set tContextSourceListComponent.displayList = $Replace(tContextSourceListComponent.displayList,"Document Body ID,","")

		}

		/*
			Load last saved user test data
				^EnsPortal("TestRule", ..RULE, $username)=Header/Body/Paste
				^EnsPortal("TestRule", ..RULE, $username,"D")=id/id/serialized
				^EnsPortal("TestRule", ..RULE, $username,"H")=source host item
				^EnsPortal("TestRule", ..RULE, $username,"C")=docClass
		*/
		Try {

			#dim tcontextSource
			If $Data(^EnsPortal("TestRule", ..RULE, $username),tcontextSource) {

				Set tContextSourceListComponent.value = tcontextSource

				#dim tcontextClass = $Get(^EnsPortal("TestRule", ..RULE, $username,"C"))
				If tcontextClass '= "" Set ..docClass = tcontextClass

				#dim tcontextData = $Get(^EnsPortal("TestRule", ..RULE, $username,"D"))
				#; Default to show is Paste
				If tcontextSource = "Header" {

					Set ..%GetComponentById("docSourceLbl").label = $$$TextHTML("Enter Message Header ID")
					Set ..%GetComponentById("docHeader").hidden = 0
					Set ..%GetComponentById("docHeader").value = tcontextData
					Set ..%GetComponentById("docId").hidden = 1
					Set ..%GetComponentById("msgEnterData").hidden = 1

				} ElseIf tcontextSource = "Body" {

					Set ..%GetComponentById("docSourceLbl").label = $$$TextHTML("Enter Document Body ID")
					Set ..%GetComponentById("docId").hidden = 0
					Set ..%GetComponentById("docId").value = tcontextData
					Set ..%GetComponentById("docHeader").hidden = 1
					Set ..%GetComponentById("msgEnterData").hidden = 1

				} Else {

					#; "D" node is the serialized message data
					Set ..%GetComponentById("testContextSerialized").value = tcontextData

				}

				#; If not a routing rule then this will be empty string
				#dim tcontextSourceHost = $Get(^EnsPortal("TestRule", ..RULE, $username,"H"))
				If tcontextSourceHost'="" Set ..%GetComponentById("testSource").value = tcontextSourceHost

			}

		} Catch {}

	} Catch {}

	Quit
}

/// Method to draw any error of results.
Method DrawErrorResult(pSeed As %String) As %Status
{
	If ..testError '= "" Write "<div class=""errorMessage"">"_$ZCVT(..testError,"O","HTML")_"</div>"
	Quit $$$OK
}

/// Method to draw the Message
Method DrawMessageHTML(pShowTestMessage As %String) As %Status
{
	If ..testMessageHTML = "" Quit $$$OK

	#dim msgHide = $$$TextHTML("Hide contents")
	#dim hlpHide = $$$TextHTML("Hide the data used in the test")

	#dim msgShow = $$$TextHTML("Show contents")
	#dim hlpShow = $$$TextHTML("Show the data used in the test")


	if '..testIsRoutingRule {

		#dim tTestMessageDisplayPane = ..%GetComponentById("testMessageDisplayPane")
		Set tTestMessageDisplayPane.label=$$$TextHTML("Context:")

	}


	If pShowTestMessage {
		&html<
			<div style="position:relative; left:80px">
				<div id="hideMessageDiv" style="color:#404040;text-decoration: underline;">
					<a id="cmdHideMessage" class="hdrLink" href="#" title="#(hlpHide)#" onclick="zenPage.toggleMessageDiv(false);return false;">#(msgHide)#</a>
				</div>
			</div>
		>
	} Else {

		&html<
			<div style="position:absolute; left:80px;">
				<div id="showMessageDiv" style="color:#404040;text-decoration: underline;">
					<a id="cmdShowMessage" class="hdrLink" href="#" title="#(hlpShow)#" onclick="zenPage.toggleMessageDiv(true);return false;">#(msgShow)#</a>
				</div>
			</div>
		>

		Quit $$$OK

	}

	If ..testMessageNeedsEscaping {

		Write "<pre style=""white-space:pre-wrap"">"
		#dim tRemainder = ""
		Write $ZCONVERT(..testMessageHTML,"O","HTML",tRemainder)
		While (tRemainder'="") {
			Write $ZCONVERT(tRemainder,"O","HTML",tRemainder)
		}
		Write "</pre>"

	} Else {

		Write ..testMessageHTML,!

	}

	Quit $$$OK
}

/// Method to draw the Rule log
Method DrawRuleLog(pIsRoutingRule As %String) As %Status
{
	If ..testResultJSON = "" Quit $$$OK

	&html<
		<table border="0" cellpadding="0" cellspacing="0">
		<tr valign="top"><td>
		<table class="eventInfoTable" border="0" cellpadding="0" cellspacing="0">
	>

	#dim tResultObject={}.%FromJSON(..testResultJSON)

	#dim tTestResultComponentPane = ..%GetComponentById("testRuleLogDisplayPane")
	Set tTestResultComponentPane.label=$$$FormatTextHTML("Test Result at %1",tResultObject.TimeExecuted)

	#dim tTableArray
	#dim tRow = 0

	If ..RULE '= tResultObject.RuleName {
		#dim tNameMismatchMessage = $$$FormatText("UNEXPECTED RULE NAME MISMATCH: ")_..CleanEventText(tResultObject.RuleName)
		Set tRow = $I(tRow)
		Set tTableArray(tRow)=$LB(tNameMismatchMessage, $$$Text("Rule Name"))
	}

	#dim tReturnLabel
	#dim tReturnsLabel
	If pIsRoutingRule {

		Set tReturnLabel = $$$Text("Return Action")
		Set tReturnsLabel = $$$Text("Return Actions")

	} Else {

		Set tReturnLabel = $$$Text("Return Value")
		Set tReturnsLabel = $$$Text("Return Values")

	}

	#dim tReturnValue = ..CleanEventText(tResultObject.ReturnValue)
	Set tRow = $I(tRow)
	#dim tNumberActions = $Length(tReturnValue,";")
	If tNumberActions = 1 {
		Set tTableArray(tRow)=$LB(tReturnValue, tReturnLabel)
	} Else {
		Set tTableArray(tRow)=$LB(tReturnValue, tReturnsLabel)
	}

	Set tRow = $I(tRow)
	#dim tNumbeReasons = $Length(tResultObject.Reason,",")
	If tNumbeReasons = 1 {
		Set tTableArray(tRow)=$LB(tResultObject.Reason, $$$Text("Reason"))
	} Else {
		Set tTableArray(tRow)=$LB(tResultObject.Reason, $$$Text("Reasons"))
	}

	#; Empty Row
	Set tRow = $I(tRow)
	Set tTableArray(tRow)=$LB("","")

	/*Explain send Actions
		Routing rule:
		send:target:transformation;send:target:transformation
		delegate
		delete
	*/
	If pIsRoutingRule {

		#dim tActionCount, tOneActionSet
		#dim tAction, tTarget, tTransform
		#dim tTransformText
		#dim tTargetText

		For tActionCount=1:1:tNumberActions {

			Set tOneActionSet = $Piece(tReturnValue,";",tActionCount)
			Set tAction = $Piece(tOneActionSet,":",1)
			If tAction '= "send" continue
			Set tTransform = $Piece(tOneActionSet,":",3)
			Set tTarget = $Piece(tOneActionSet,":",2)

			Set tTransformText = ""
			Set tTargetText = $$$FormatText("Target: %1",tTarget)

			If (tTransform'="") {

				Set tTransformText = $$$FormatText("Transform: %1",tTransform)
				Set tRow = $I(tRow)
				Set tTableArray(tRow)=$LB(tTransformText, $$$Text("Send action")_" #"_tActionCount)
				Set tRow = $I(tRow)
				Set tTableArray(tRow)=$LB(tTargetText, "")

			} Else {

				Set tRow = $I(tRow)
				Set tTableArray(tRow)=$LB(tTargetText,  $$$Text("Send action")_" #"_tActionCount)

			}

		}

	}

	#; Empty Row
	Set tRow = $I(tRow)
	Set tTableArray(tRow)=$LB("","")


	#; If only one ruleset then the log might not record rule set name.
	If tResultObject.RuleSet = "" Set tResultObject.RuleSet = "ruleSet (#1)"
	Set tRow = $I(tRow)
	Set tTableArray(tRow)=$LB(tResultObject.RuleSet, $$$Text("Rule Set"))

	If tResultObject.IsError {
		Set tRow = $I(tRow)
		Set tTableArray(tRow)=$LB(tResultObject.IsError, $$$Text("Error?"))
		Set tRow = $I(tRow)
		Set tTableArray(tRow)=$LB(..CleanEventText(tResultObject.ErrorMsg), $$$Text("Error Message"))
	}

	If (tResultObject.EffectiveBegin'="")||(tResultObject.EffectiveEnd'="") {
		#; Empty Row
		Set tRow = $I(tRow)
		Set tTableArray(tRow)=$LB("","")
		Set tRow = $I(tRow)
		Set tTableArray(tRow)=$LB(tResultObject.EffectiveBegin, $$$Text("Effective Begin Date/Time"))
		Set tRow = $I(tRow)
		Set tTableArray(tRow)=$LB(tResultObject.EffectiveEnd, $$$Text("Effective End Date/Time"))
	}

	#dim i,tCurrentProp
	#dim tPropName, tValue
	#dim tValueHTML, tPropNameHTML
	#dim tcssClass

	For i=1:1:tRow {
		Set tCurrentProp = tTableArray(i)
		Set tValue = $LG(tCurrentProp, 1)
		Set tValueHTML = $ZCVT(tValue,"O","HTML")
		Set tPropName = $LG(tCurrentProp, 2)
		Set tPropNameHTML = $ZCVT(tPropName,"O","HTML")
		If tPropNameHTML '="" Set tPropNameHTML = tPropNameHTML_":"
		Set tcssClass = "eventValue"
		If tPropName=$$$Text("Error Message") Set tcssClass = tcssClass_" eventText"
		If tPropName=$$$Text("Rule Name") Set tcssClass ="errorMessage"
		&html<
			<tr valign="top">
				<td class="eventCaption">#($REPLACE(tPropNameHTML, " ", "&nbsp;"))#</td>
				<td class="#(tcssClass)#">#(tValue)#</td>
			</tr>
		>
	}
	&html<</table>>
	&html<</td></tr></table>>

	Quit $$$OK
}

/// Method to draw the Rule Debug 
Method DrawRuleDebugLog(pSeed As %String) As %Status
{
	If ..testResultJSON = "" Quit $$$OK

	#dim tResultObject={}.%FromJSON(..testResultJSON)
	#dim tDebugLogArray = tResultObject.DebugLog

	If '$IsObject(tDebugLogArray) Quit $$$OK

	&html<<table class="ruleDebugData">
			<tr>
				<th align="centre">#($$$TextHTML("Log Level"))#</th>
				<th align="centre">#($$$TextHTML("Source"))#</th>
				<th align="centre">#($$$TextHTML("Status"))#</th>
				<th align="centre">#($$$TextHTML("Message"))#</th>
			</tr>
	>

	#dim tIterator = tDebugLogArray.%GetIterator()
	#dim key, debugRow
	#dim statusClass
	While tIterator.%GetNext(.key,.debugRow) {

		If debugRow.Message["passed" {
			Set statusClass = "rulePassed"
		} ElseIf debugRow.Message["failed" {
			Set statusClass = "ruleFailed"
		} ElseIf debugRow.Message["succeeded" {
			Set statusClass = "rulePassed"
		} ElseIf debugRow.Message["no whens matched and no otherwise defined" {
			Set statusClass = "ruleWarning"
		} Else {
			Set statusClass = ""
		}

		&html<<tr>
				<td>#(debugRow.Type)#</td>
				<td>#(debugRow.Source)#</td>
				<td>
					<div class=#(statusClass)# ></div>
				</td>
				<td>#($zconvert(debugRow.Message,"O","HTML"))#</td>
			</tr>
		>
	}

	&html<
		</table>
	>

	Quit $$$OK
}

Method encounteredError(pHTMLText As %String = "") As %Boolean
{
	#; When testError is written it will be converted to HTML 
	Set ..testError = pHTMLText
	Quit 0
}

/// run the test. Returns 1 if OK and 0 if not OK via <method>encounteredError</method>
Method runTest() As %Boolean [ ZenMethod ]
{
	Set ..testError = ""
	Set ..testMessageHTML = ""
	Set ..testResultJSON = ""

	If '..canTestRules Quit ..encounteredError($$$Text("Insufficient privilege to test Rules."))

	If '..canViewRuleLogs Quit ..encounteredError($$$Text("Insufficient privilege to access Rule Logs."))

	#dim tSC = $$$OK

	#dim ex AS %Exception.AbstractException
	#dim tPageIO
	#dim encounteredErrorText = ""

	Try {
		#; Ensure any output from utility functions that are run do not leak to web page
		Do ToggleUseNullDevice^EnsUtil(1,.tPageIO)

		If '..sufficientTestData(.encounteredErrorText) Quit

		If '..canTestIfRunning(.encounteredErrorText) Quit

		#; Instantiate Rule object
		#dim tRuleDef
		Set tSC = ..GetRuleDefinitionObject(,.tRuleDef)
		If $$$ISERR(tSC) {
			Set encounteredErrorText = ($$$Text("Unable to open rule"))
			Quit
		}

		#; We set testIsRoutingRule on initialize but redo
		Set ..testIsRoutingRule = tRuleDef.isRoutingRule

		#; tRuleContextClass might be empty.
		#dim tRuleContextClass = tRuleDef.context

		#; tMessageObject will become the tContextObject if not a router/no constraints
		#; tMessageObject will be displayed not tContextObject
		#dim tMessageObject = $$$NULLOREF
		#dim tContextObject = $$$NULLOREF

		#; Need to be able record the id/data for the particular source
		#dim tDataToSave
		#; Create Document/Context object
		#dim tSCOpen = $$$OK
		If (..contextSource["Header") {

			#dim tSCHdrOpen = $$$OK
			#dim tMsgHeader = ##class(Ens.MessageHeader).%OpenId(..docHeader,,.tSCHdrOpen)
			If (('$$$IsdefObject(tMsgHeader)) || ('##class(%Dictionary.CompiledClass).%ExistsId(tMsgHeader.MessageBodyClassName)) || ('+tMsgHeader.MessageBodyId) || $$$ISERR(tSCHdrOpen) ) {

				Set encounteredErrorText = ($$$FormatText("Failed to open message header: %1",$$$StatusDisplayString($Get(tSCHdrOpen))))
				Quit

			} Else {

				Set tMessageObject = $classmethod(tMsgHeader.MessageBodyClassName,"%OpenId",tMsgHeader.MessageBodyId,,.tSCOpen)
				If '$$$IsdefObject(tMessageObject) || $$$ISERR(tSCOpen) {
					Set encounteredErrorText = ($$$FormatText("Failed to open document from Message header %1: %2",..docHeader,$$$StatusDisplayString($Get(tSCOpen))))
					Quit
				}
				If 'tMessageObject.%Extends(..docClass) {
					Set encounteredErrorText = ($$$FormatText("The message class %1 does not match or extend the requested document class %2",tMessageObject.%ClassName(1),..docClass))
					Quit
				}
			}
			If ..testSource="" {
				Set ..testSource = tMsgHeader.SourceConfigName
				#dim tTestSourceComponent = ..%GetComponentById("testSource")
				Set tTestSourceComponent.value = ..testSource
			}
			Set tDataToSave = ..docHeader

		} ElseIf (..contextSource["Body") {

			Set tMessageObject=$classmethod(..docClass,"%OpenId",..docId,,.tSCOpen)
			If '$$$IsdefObject(tMessageObject) {
				Set encounteredErrorText = ($$$FormatText("Failed to open document %1: %2",..docId,$$$StatusDisplayString($Get(tSCOpen))))
				Quit
			}
			If 'tMessageObject.%Extends(..docClass) {
				Set encounteredErrorText = ($$$FormatText("The message class %1 does not match or extend the requested document class %2",tMessageObject.%ClassName(1),..docClass))
				Quit
			}
			Set tDataToSave = ..docId

		} ElseIf (..contextSource["Paste") {

			#dim tResultObject={}.%FromJSON(..contextSerialized)

			If $classmethod(tResultObject.%clsname,"%Extends","EnsLib.EDI.Document") {

				Set tData = ##class(%Stream.GlobalCharacter).%New()
				Do tData.Write(tResultObject.%IDXCONT)
				Do tData.Rewind()
				Set tMessageObject = $classmethod(tResultObject.%clsname,"ImportFromLibraryStream",tData,.tSC)
				If $$$ISERR(tSC) {
					Set encounteredErrorText = $$$FormatText("Error creating Document: %1",$$$StatusDisplayString(tSC))
					Quit
				}
				If tResultObject.Separators '= "" Set tMessageObject.Separators = tResultObject.Separators
				If tResultObject.DocType '= "" Set tMessageObject.DocType = tResultObject.DocType
				#;Ensure segments cleaned up after serializing as HTML
				Try {Set tMessageObject.IsMutable = 0} Catch {}

			} ElseIf tResultObject.%clsname '= "" {

				Set tMessageObject = $classmethod(tResultObject.%clsname,"%New","")
				#dim tIterator = tResultObject.%GetIterator()
				#dim prop, val
				While tIterator.%GetNext(.prop,.val) {
					If prop'="%clsname" Set $property(tMessageObject,prop)=val
				}

			}
			Set tDataToSave = ..contextSerialized

		} Else {

			Set encounteredErrorText = ("No source of message data was specified")
			Quit

		}

		If '$IsObject(tMessageObject) {

			Set encounteredErrorText = ("Unable to create data object for rule test.")
			Quit

		}

		#; Create tContextObject
		If '..testIsRoutingRule {

			Set tContextObject = tMessageObject

		} Else {

			#dim tSCCreateContext = $$$OK
			Set tContextObject=##class(Ens.Host).GetShadowInstance("class ||"_tRuleContextClass,.tSCCreateContext)

			If $$$ISOK(tSCCreateContext) {

				#; Need to initialize the routing engine with a configname
				Set tContextObject = $classmethod(..%rule.context,"%New",$JOB_$USERNAME)
				Set tContextObject.Document = tMessageObject
				Set tContextObject.MsgClass = $classname(tMessageObject)
				Set tContextObject.Source = ..testSource

				If tContextObject.%Extends("EnsLib.MsgRouter.VDocRoutingEngine") {

					Set tContextObject.DocType = tMessageObject.DocType
					Set tContextObject.DocName = tMessageObject.Name

				}

			} Else {

				Set encounteredErrorText = ($$$FormatText("Error creating context object: %1",$$$StatusDisplayString(tSCCreateContext)))
				Quit

			}

		}

		#; Evaluate the Rule.
		#dim tRuleLogJSON = ""

		#dim tSCRuleEvaluation = ..evaluateRule(tContextObject,..RULE,.tRuleLogJSON)

		Set ..testResultJSON =tRuleLogJSON
		If $$$ISERR(tSCRuleEvaluation) {
			Set encounteredErrorText = ($$$FormatText("Error evaluating rule: %1",$$$StatusDisplayString(tSCRuleEvaluation)))
			Quit
		}

		#; Handle displaying message/context object
		#dim tAllowedToSeeMessage As %Boolean = 0
		#dim tAuditSource = $$$Text("Rule test message display")
		#dim tAuditHDrID = $$$Text("N/A")

		If (..contextSource["Header") {
			If ..canViewContents {
				Do $$$AuditViewMessage(tAuditSource, tMsgHeader.%Id(), tMsgHeader.MessageBodyClassName, tMessageObject.%Id())
				Set tAllowedToSeeMessage = 1
			}
		} ElseIf (..contextSource["Body") {
			If ..canViewContents {
				Do $$$AuditViewMessage(tAuditSource, tAuditHDrID, $classname(tMessageObject), tMessageObject.%Id())
				Set tAllowedToSeeMessage = 1
			}
		} ElseIf (..contextSource["Paste") {
			#; No Audit needed for user paste
			Set tAllowedToSeeMessage = 1
		} Else {
			Set encounteredErrorText = ($$$Text("No source of message data was specified"))
			Quit
		}
		If tAllowedToSeeMessage {
			#dim tNeedsHTMLEscaping
			#dim tMessageHTML = ..serializeMessageAsHTML(tMessageObject,.tSC,.tNeedsHTMLEscaping)
			#; Store as a string upto max length
			If $$$ISOK(tSC) || $$$IsdefObject(tMessageHTML) {
				Do tMessageHTML.Rewind()
				#dim tLengthToRead
				While 'tMessageHTML.AtEnd {
					Set tLengthToRead = ($SYSTEM.SYS.MaxLocalLength()-$Length(..testMessageHTML))
					If tLengthToRead = 0 Quit
					Set ..testMessageHTML = ..testMessageHTML_tMessageHTML.Read(.tLengthToRead)
				}
				Set ..testMessageNeedsEscaping = tNeedsHTMLEscaping
			} Else {
				Set encounteredErrorText = ($$$FormatText("Error displaying object: %1",$$$StatusDisplayString(tSC)))
				Quit
			}
		}

		#; Save test data (if changed/valid class)
		If ..docClass '= "%Library.Persistent" {
			#dim tSavedContextSource=$Get(^EnsPortal("TestRule", ..RULE, $username)) //=Header/Body/Paste
			If tSavedContextSource '= ..contextSource Set ^EnsPortal("TestRule", ..RULE, $username) = ..contextSource

			#dim tSavedContextData=$Get(^EnsPortal("TestRule", ..RULE, $username,"D")) //=id/id/serialized
			If tSavedContextData '= tDataToSave Set ^EnsPortal("TestRule", ..RULE, $username,"D") = tDataToSave

			#dim tSavedContextHost=$Get(^EnsPortal("TestRule", ..RULE, $username,"H")) //host item
			If tSavedContextHost '= ..testSource Set ^EnsPortal("TestRule", ..RULE, $username,"H") = ..testSource

			#dim tSavedDocClass=$Get(^EnsPortal("TestRule", ..RULE, $username,"C")) //docClass
			If tSavedDocClass '= ..docClass Set ^EnsPortal("TestRule", ..RULE, $username,"C") = ..docClass
		}
	} Catch ex {

		Set encounteredErrorText = $$$FormatText("Error evaluating rule: %1",$$$StatusDisplayString(ex.AsStatus()))

	}

	Try {
		Do ToggleUseNullDevice^EnsUtil(0,tPageIO)
	} Catch ex {
		Set encounteredErrorText = $$$FormatText("Error evaluating rule: %1",$$$StatusDisplayString(ex.AsStatus()))_"."_encounteredErrorText

	}
	If encounteredErrorText'="" Quit ..encounteredError(encounteredErrorText)

	Quit 1
}

Method sufficientTestData(Output pErrorText As %String = "") As %Boolean
{
	If ..docClass = "" {

		Set pErrorText = $$$Text("Unable to determine context class for test")
		Quit 0

	} ElseIf (..contextSource["Header") {

		If ..docHeader = "" {
			Set pErrorText = $$$Text("No message header ID supplied")
			Quit 0

		}

	} ElseIf (..contextSource["Body") {

		If ..docId = "" {
			Set pErrorText = $$$Text("No document body ID supplied")
			Quit 0
		}

	} ElseIf (..contextSource["Paste") {

		If ..contextSerialized = "" {
			Set pErrorText = $$$Text("No document context supplied")
			Quit 0
		}

	}

	Quit 1
}

/// Given a context object evaluate the rule and create result output as JSON
ClassMethod evaluateRule(pContext As %RegisteredObject, pRuleName As %String, Output pRuleLogData As %String = "", pDebugFlags As %String = "crd", pSelectMode As %Integer = 2) As %Status
{
	#; use a negative session id
	#dim tSessionId = -$JOB
	#dim tReturnValue = ""
	#dim tReason = ""
	#dim ex As %Exception.AbstractException
	#dim tSCRuleStatus = $$$OK
	Try {
		/*	Any error return status will only be reported if no rule log
			since the rule log will contain the error.
		*/
		#dim tSCRuleEvaluate= ##class(Ens.Rule.Definition).EvaluateRules(pRuleName,tSessionId,pContext,$$$Text("Test by")_" "_$username,.tReturnValue,.tReason,pDebugFlags)
		#; Get rule log output.
		#dim tSQL = "SELECT TOP 1 ID,TimeExecuted,RuleName,RuleSet,EffectiveBegin,EffectiveEnd,Reason,ReturnValue,IsError,ErrorMsg,DebugId FROM ENS_RULE.LOG WHERE SESSIONID = ? ORDER BY ID DESC"
		#; Specify display mode
		#dim tStatement = ##class(%SQL.Statement).%New()
		Set tStatement.%SelectMode=pSelectMode
		#dim tRS =  ##class(%SQL.Statement).%ExecDirect(.tStatement,tSQL,tSessionId)

		If 'tRS.%Next() {
			Set tSCRuleStatus =$$$ADDSC($$$ERROR($$$EnsErrGeneral,"Failed to open rule log"),tSCRuleEvaluate)
			Quit
		}

		#dim tRuleLogJSONObj ={}
		#dim tID = tRS.ID
		Do tRuleLogJSONObj.%Set("ID",tID)
		Do tRuleLogJSONObj.%Set("TimeExecuted",tRS.TimeExecuted)
		Do tRuleLogJSONObj.%Set("RuleName",tRS.RuleName)
		Do tRuleLogJSONObj.%Set("RuleSet",tRS.RuleSet)
		Do tRuleLogJSONObj.%Set("EffectiveBegin",tRS.EffectiveBegin)
		Do tRuleLogJSONObj.%Set("EffectiveEnd",tRS.EffectiveEnd)
		Do tRuleLogJSONObj.%Set("Reason",tRS.Reason)
		Do tRuleLogJSONObj.%Set("ReturnValue",tRS.ReturnValue)
		Do tRuleLogJSONObj.%Set("IsError",tRS.IsError)
		Do tRuleLogJSONObj.%Set("ErrorMsg",tRS.ErrorMsg)

		#dim tDebugId = tRS.DebugId
		If (tDebugId '= "") && ##class(Ens.Rule.DebugLog).DebugIdExists(tDebugId) {

			Set tRuleLogJSONObj.DebugLog = []
			#dim tLogTypes
			Set tLogTypes($$$eRuleLogTypeUserDebug) = "Debug"
			Set tLogTypes($$$eRuleLogTypeConditionDebug) = "Condition"

			Set tStatement = ##class(%SQL.Statement).%New()
			Set tStatement.%SelectMode=pSelectMode
			#dim tDebugRS = ##class(%SQL.Statement).%ExecDirect(.tStatement,"SELECT LogType,Source,Message,IsOtherwise FROM Ens_Rule.DebugLog WHERE DebugId = ? ORDER BY ID ASC",tDebugId)
			#dim tDebugLogEntry
			While tDebugRS.%Next() {

				Set tDebugLogEntry = {}
				Set tDebugLogEntry.Type = $Get(tLogTypes(tDebugRS.LogType))
				Set tDebugLogEntry.Source = tDebugRS.Source
				Set tDebugLogEntry.IsOtherwise = tDebugRS.IsOtherwise
				Set tDebugLogEntry.Message = tDebugRS.Message
				Do tRuleLogJSONObj.DebugLog.%Push(tDebugLogEntry)
			}

		}

		Set pRuleLogData = tRuleLogJSONObj.%ToJSON()

		#; Delete rule log
		Do ##class(Ens.Rule.Log).%DeleteId(tID)

	} Catch ex {

		Set tSCRuleStatus = ex.AsStatus()

	}

	Quit tSCRuleStatus
}

/// Given an object create an HTML serialization of the object.
Method serializeMessageAsHTML(pMessageObject As %RegisteredObject, Output pSC As %Status = {$$$OK}, Output pNeedsHTMLEscaping As %Boolean = 1) As %Stream.TmpCharacter
{
	#dim tFormatNotSupportMsg = $$$Text("Message format not supported for display in test results")
	#dim tXMLStream = ##class(%Stream.TmpCharacter).%New()
	If '$$$IsdefObject(pMessageObject) Quit tXMLStream

	If pMessageObject.%Extends("EnsLib.EDI.Document") {

		Try {

			If pMessageObject.%Extends("EnsLib.HL7.Message") {
				Set pNeedsHTMLEscaping = 0
				Set pSC=pMessageObject.OutputToLibraryStream(tXMLStream,,,"EnsLib.HL7.Util.FormatHTMLv2Zen")
			} ElseIf pMessageObject.%Extends("EnsLib.EDI.X12.Document") {
				Set pNeedsHTMLEscaping = 0
				Set pSC=pMessageObject.OutputToLibraryStream(tXMLStream,,$S(pMessageObject.useValSchema:"EnsLib.EDI.X12.Util.FormatValHTML",1:"EnsLib.EDI.X12.Util.FormatHTML"))
			} ElseIf pMessageObject.%Extends("EnsLib.EDI.ASTM.Document") {
				Set pNeedsHTMLEscaping = 0
				Set pSC=pMessageObject.OutputToLibraryStream(tXMLStream,,,"EnsLib.EDI.ASTM.Util.FormatHTML")
			} ElseIf pMessageObject.%Extends("EnsLib.EDI.EDIFACT.Document") {
				Set pNeedsHTMLEscaping = 0
				Set pSC=pMessageObject.OutputToLibraryStream(tXMLStream,,"EnsLib.EDI.EDIFACT.Util.FormatHTML")
			} ElseIf pMessageObject.%Extends("EnsLib.EDI.XML.Document") {
				Set pSC=pMessageObject.OutputToLibraryStream(tXMLStream,"wt")
			} Else {
				Do tXMLStream.Write(tFormatNotSupportMsg)
			}

		} Catch {

			Set pSC=$$$SystemError

		}

	} ElseIf pMessageObject.%Extends("%XML.Adaptor") {

		Try {

			Set tWriter=##class(%XML.Writer).%New()
			Set tWriter.Indent=1
			Set pSC=tWriter.OutputToStream(tXMLStream)
			Set:$$$ISOK(pSC) pSC=tWriter.RootObject(pMessageObject)

		} Catch {

			Set pSC=$$$SystemError

		}

	} Else {

		Do tXMLStream.Clear()
		Do tXMLStream.Write(tFormatNotSupportMsg)

	}

	If $$$ISERR(pSC) {
		Do tXMLStream.Clear()
		Do tXMLStream.Write("<div class=""errorMessage"">"_$$$FormatText($$$Text("Error displaying object: %1"),$$$StatusDisplayString(pSC))_"</div>")
	}
	If $IsObject(tXMLStream) {
		Do tXMLStream.Rewind()
	}
	Quit tXMLStream
}

/// Prepare text to be displayed in HTML. Taken from EnsPortal.Utils since private. Also set narrowdisplay default 0
ClassMethod CleanEventText(pText As %String, pNarrowDisplay As %Boolean = 0) As %String [ Private ]
{
	// Find replacement character for newlines
	Set tRepChar = ""
	For i=0:1:31 {
		If (i '= 10) && '$find(pText,$char(i)) {
			Set tRepChar = $char(i)
			Quit
		}
	}

	// If it's a narrow display, insert a space for lines with a "^" after position 20
	If pNarrowDisplay {
		Set tTextOut = ""
		Set tRemText = pText
		Set tCount = 0
		For {
			Set tPos = $find(tRemText, "^")
			If 'tPos {
				Set tTextOut = tTextOut _ tRemText
				Quit
			}
			If ((tCount + tPos) <= 20) {
				Set tTextOut = tTextOut _ $extract(tRemText, 1, tPos - 1)
				Set tCount = tCount + tPos
			}
			Else {
				Set tTextOut = tTextOut _ $extract(tRemText, 1, tPos - 2) _ " ^"
				Set tCount = 0
			}
			Set tRemText = $extract(tRemText, tPos, *)
		}
		Set tTextOut = $replace(tTextOut, "' ", "'"_tRepChar)
	}
	Else {
		Set tTextOut = pText
	}

	Set tTextOut = $translate(tTextOut, $char(13))
	Set tTextOut = $replace(tTextOut, $char(10), tRepChar)
	Set tTextOut = $replace(tTextOut, "<br/>", tRepChar)
	Set tTextOut = $replace(tTextOut, "<br>", tRepChar)
	Set tTemp = tTextOut
	Set tTextOut = ""
	For {
		Set tPos = $find(tTemp, tRepChar)
		If 'tPos {
			Set tTextOut = tTextOut _ $zconvert(tTemp,"O","HTML")
			Quit
		}
		Set tTextOut = tTextOut _ $zconvert($extract(tTemp, 1, tPos-2),"O","HTML") _ "<br/>"
		Set tTemp = $extract(tTemp, tPos, *)
	}
	Quit tTextOut
}

/// This returns 1 if a production is not running.
/// Returns 2 if a production is running and testing enabled
/// Returns 0 if a production is running and testing not enabled
Method canTestIfRunning(Output pErrorText As %String = "") As %Boolean
{
	#dim tSC = $$$OK
	#dim tProduction
	If '##class(Ens.Director).IsProductionRunning(.tProduction) Quit 1
	If ##class(EnsPortal.TestingService).GetIsTestingEnabled(tProduction) Quit 2
	Set pErrorText = $$$Text("A Production is running and Testing is not Enabled. Evaluating rules is disabled as a precaution.")
	Quit 0
}

Method GetObjectEntryURL() As %String [ ZenMethod ]
{
	Quit ..Link("EnsPortal.Dialog.ObjectEntry.cls")
}

}
