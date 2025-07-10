/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// Business Process SVG Page<br>
/// This page renders the SVG needed to host the BPL designer.
Class EnsPortal.SVG.BPLCanvas Extends EnsPortal.SVG.templatePage [ System = 4 ]
{

/// User needs READ permissions on either the %Ens_Code or the %Ens_BPL resource to view this page.
Parameter RESOURCE = "%Ens_Code:READ,%Ens_BPL:READ";

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// Comma-delimited list of additional .js files.
Parameter JSINCLUDES = "ensbplzen.js";

/// Business process name.
Property bpName As %String(ZENURL = "BP");

Method %OnDrawSVGPage() As %Status
{
	Set tSC = ..DrawBPLCanvas()
	Quit tSC
}

/// Draw the canvas for the BPL editor.
Method DrawBPLCanvas() As %Status
{
	// create array of localized text messages

	Set msgText("LastModified")		= $ZCVT($$$LocalizeText("EnsBPL","LastModified","Last modified:"),"O","JS")

	// validation
	Set msgText("BadCall")			= $ZCVT($$$LocalizeText("EnsBPL","BadCall","Referenced call, %S1, is not defined or is not asynchronous."),"O","JS")
	Set msgText("BranchBadJoin")	= $ZCVT($$$LocalizeText("EnsBPL","BranchBadJoin","All branches for %S1 must terminate at same join."),"O","JS")
	Set msgText("BranchCaseReq")	= $ZCVT($$$LocalizeText("EnsBPL","BranchCaseReq","There must be at least one non-default case (i.e., case with a condition) for a %S1."),"O","JS")
	Set msgText("BranchDefExcess")	= $ZCVT($$$LocalizeText("EnsBPL","BranchDefExcess","There is more than one case with no condition for a %S1."),"O","JS")
	Set msgText("BranchFalseExcess")= $ZCVT($$$LocalizeText("EnsBPL","BranchFalseExcess","There is more than one false branch for %S1."),"O","JS")
	Set msgText("BranchNoJoin")		= $ZCVT($$$LocalizeText("EnsBPL","BranchNoJoin","All branches for %S1 must terminate at a join."),"O","JS")
	Set msgText("BranchTORF")		= $ZCVT($$$LocalizeText("EnsBPL","BranchTORF","Branch for %S1 must be either true or false."),"O","JS")
	Set msgText("BranchTrueExcess")	= $ZCVT($$$LocalizeText("EnsBPL","BranchTrueExcess","There is more than one true branch for %S1."),"O","JS")
	Set msgText("BranchTrueReq")	= $ZCVT($$$LocalizeText("EnsBPL","BranchTrueReq","There must be a true branch for %S1."),"O","JS")
	Set msgText("LoopReq")			= $ZCVT($$$LocalizeText("EnsBPL","LoopReq","The %S1 activity can only be used within a loop."),"O","JS")
	Set msgText("NoAttr")			= $ZCVT($$$LocalizeText("EnsBPL","NoAttr","%S1 not specified for this %S2 activity."),"O","JS")
	Set msgText("NoDuration")		= $ZCVT($$$LocalizeText("EnsBPL","NoDuration","You must provide a value for either the Duration or Until attributes."),"O","JS")
	Set msgText("NoDuration2")		= $ZCVT($$$LocalizeText("EnsBPL","NoDuration2","You must provide a value for only one of the Duration or Until attributes."),"O","JS")
	Set msgText("NoInput")			= $ZCVT($$$LocalizeText("EnsBPL","NoInput","No input."),"O","JS")
	Set msgText("NoLabelFound")		= $ZCVT($$$LocalizeText("EnsBPL","NoLabelFound","No label with name '%S1' found."),"O","JS")
	Set msgText("NoOutput")			= $ZCVT($$$LocalizeText("EnsBPL","NoOutput","No output."),"O","JS")
	Set msgText("ChildErrors")		= $ZCVT($$$LocalizeText("EnsBPL","ChildErrors","There are errors in child activities within this Group."),"O","JS")
	Set msgText("AsyncTimeout")		= $ZCVT($$$LocalizeText("EnsBPL","AsyncTimeout","No timeout should be specified for an asynchronous call."),"O","JS")
	Set msgText("DupeCallName")		= $ZCVT($$$LocalizeText("EnsBPL","DupeCallName","Synchronous Call name %S2 already defined."),"O","JS")
	
	// tool tips
	Set msgText("TipAlert")		= $ZCVT($$$LocalizeText("EnsBPL","TipAlert","Raises an Alert."),"O","JS")
	Set msgText("TipAssign")	= $ZCVT($$$LocalizeText("EnsBPL","TipAssign","Assigns a value to a property:"),"O","JS")
	Set msgText("TipBranch")	= $ZCVT($$$LocalizeText("EnsBPL","TipBranch","Conditionally go to a label within this business process."),"O","JS")
	Set msgText("TipBreak")		= $ZCVT($$$LocalizeText("EnsBPL","TipBreak","Breaks out of the current loop."),"O","JS")
	Set msgText("TipCallAsync")	= $ZCVT($$$LocalizeText("EnsBPL","TipCallAsync","Makes an asynchronous request to:"),"O","JS")
	Set msgText("TipCallSync")	= $ZCVT($$$LocalizeText("EnsBPL","TipCallSync","Makes an synchronous request to:"),"O","JS")
	Set msgText("TipCode")		= $ZCVT($$$LocalizeText("EnsBPL","TipCode","Executes user-defined code."),"O","JS")
	Set msgText("TipContinue")	= ..EscapeJSKeepLF($$$LocalizeText("EnsBPL","TipContinue","Continues execution at the\nstart of the current loop."))
	Set msgText("TipDelay")		= $ZCVT($$$LocalizeText("EnsBPL","TipDelay","Waits for a specified amount of time:"),"O","JS")
	Set msgText("TipEmpty")		= $ZCVT($$$LocalizeText("EnsBPL","TipEmpty","This element does nothing."),"O","JS")
	Set msgText("TipLabel")		= $ZCVT($$$LocalizeText("EnsBPL","TipLabel","Provide a target for a branch activity within this business process."),"O","JS")
	Set msgText("TipEndProc")	= $ZCVT($$$LocalizeText("EnsBPL","TipEndProc","This is the end of this business process."),"O","JS")
	Set msgText("TipEndSeq")	= $ZCVT($$$LocalizeText("EnsBPL","TipEndSeq","This is the end of this sequence."),"O","JS")
	Set msgText("TipFlow")		= ..EscapeJSKeepLF($$$LocalizeText("EnsBPL","TipFlow","Marks the start of a flow:\nOne or more sets of activities\nexecuted in parallel."))
	Set msgText("TipIf")		= $ZCVT($$$LocalizeText("EnsBPL","TipIf","Execute one of two actions:"),"O","JS")
	Set msgText("TipJoin")		= ..EscapeJSKeepLF($$$LocalizeText("EnsBPL","TipJoin","Marks the end of a\nswitch or flow block."))
	Set msgText("TipLoop")		= $ZCVT($$$LocalizeText("EnsBPL","TipLoop","Executes a loop"),"O","JS")
	Set msgText("TipMilestone")	= ..EscapeJSKeepLF($$$LocalizeText("EnsBPL","TipMilestone","Updates the milestone\nassociated with this process:"))
	Set msgText("TipReceive")	= $ZCVT($$$LocalizeText("EnsBPL","TipReceive","Waits to receive a new incoming request."),"O","JS")
	Set msgText("TipReply")		= $ZCVT($$$LocalizeText("EnsBPL","TipReply","Returns a reply for this business process."),"O","JS")
	Set msgText("TipRule")		= $ZCVT($$$LocalizeText("EnsBPL","TipRule","Invokes a Business Rule:"),"O","JS")
	Set msgText("TipSQL")		= $ZCVT($$$LocalizeText("EnsBPL","TipSQL","Executes user-defined SQL statement."),"O","JS")
	Set msgText("TipSequence")	= ..EscapeJSKeepLF($$$LocalizeText("EnsBPL","TipSequence","Executes a sequence of activities.\nDrill down to see details."))
	Set msgText("TipStartProc")	= $ZCVT($$$LocalizeText("EnsBPL","TipStartProc","This is the start of this business process."),"O","JS")
	Set msgText("TipStartSeq")	= $ZCVT($$$LocalizeText("EnsBPL","TipStartSeq","This is the start of this sequence."),"O","JS")
	Set msgText("TipSwitch")	= $ZCVT($$$LocalizeText("EnsBPL","TipSwitch","Execute one of multiple actions."),"O","JS")
	Set msgText("TipSync")		= $ZCVT($$$LocalizeText("EnsBPL","TipSync","Waits for responses from asynchronous calls:"),"O","JS")
	Set msgText("TipTrace")		= $ZCVT($$$LocalizeText("EnsBPL","TipTrace","Generates a trace message:"),"O","JS")
	Set msgText("TipTransform")	= $ZCVT($$$LocalizeText("EnsBPL","TipTransform","Executes a data transformation:"),"O","JS")
	Set msgText("TipScope")		= $ZCVT($$$LocalizeText("EnsBPL","TipScope","Defines the start of a scope."),"O","JS")
	Set msgText("TipXSLT")		= $ZCVT($$$LocalizeText("EnsBPL","TipXSLT","Executes an XSLT transformation."),"O","JS")
	Set msgText("TipXPATH")		= $ZCVT($$$LocalizeText("EnsBPL","TipXPATH","Executes an XPATH expression against an XML document."),"O","JS")
	
	// Editor messages
	Set msgText("EDBusinessProcess")= $ZCVT($$$LocalizeText("EnsBPL","EDBusinessProcess","Business Process"),"O","JS")
	Set msgText("EDCannotDelete")	= $ZCVT($$$LocalizeText("EnsBPL","EDCannotDelete","You cannot delete the %S1 item."),"O","JS")
	Set msgText("EDCannotGroup")	= $ZCVT($$$LocalizeText("EnsBPL","EDCannotGroup","The current selected items cannot be made into a group."),"O","JS")
	Set msgText("EDContentsOf")		= $ZCVT($$$LocalizeText("EnsBPL","EDContentsOf","Contents of %S1."),"O","JS")
	Set msgText("EDItemInvalid")	= $ZCVT($$$LocalizeText("EnsBPL","EDItemInvalid","The current item is invalid for the following reason(s):"),"O","JS")
	Set msgText("EDItemValid") 		= $ZCVT($$$LocalizeText("EnsBPL","EDItemValid","The current item is valid."),"O","JS")
	Set msgText("EDMultiSelection")	= $ZCVT($$$LocalizeText("EnsBPL","EDMultiSelection","Multiple items are selected."),"O","JS")
	Set msgText("EDNoDrill") 		= $ZCVT($$$LocalizeText("EnsBPL","EDNoDrill","You cannot drill down into current item."),"O","JS")
	Set msgText("EDNoMoreIn")		= $ZCVT($$$LocalizeText("EnsBPL","EDNoMoreIn","This component cannot accept an additional input."),"O","JS")
	Set msgText("EDNoMoreOut")		= $ZCVT($$$LocalizeText("EnsBPL","EDNoMoreOut","This component cannot accept an additional output."),"O","JS")
	Set msgText("EDNoRule") 		= $ZCVT($$$LocalizeText("EnsBPL","EDNoRule","The rules editor is only available for rule activities."),"O","JS")
	Set msgText("EDNoSelection")	= $ZCVT($$$LocalizeText("EnsBPL","EDNoSelection","No item selected."),"O","JS")
	Set msgText("EDCannotConnect")	= $ZCVT($$$LocalizeText("EnsBPL","EDCannotConnect","You must select at least two items in order to create a connection."),"O","JS")
	Set msgText("EDCannotCopy") = $ZCVT($$$LocalizeText("EnsBPL","EDCannotCopy","You cannot copy the %S1 item."),"O","JS")
	Set msgText("EDCannotCopyConn") = $ZCVT($$$LocalizeText("EnsBPL","EDCannotCopyConn","You cannot copy a connector without selecting its source and target."),"O","JS")

	// script
	// !!! replace with $$$Text
	Write "<script language=""text/javascript""><![CDATA[",!

	&js<
// array of localized messages
var msgText = {};
	>

	// write out JavaScript version of text messages
	Set tKey = $O(msgText(""))
	While (tKey '= "") {
		Write "msgText['",tKey,"'] = '",msgText(tKey),"';",!
		Set tKey = $O(msgText(tKey))
	}

	&js<
// localized text utility function
// p1 and p2 are substituted for %S1 and %S2 in string resource.
function getLocalText(id,p1,p2)
{
	var text;

	if (msgText[id]) {
		text = msgText[id];

		// substitutions
		text = text.replace(/%S1/g,p1?p1:'');
		text = text.replace(/%S2/g,p2?p2:'');
	}
	else {
		text = "Missing string resource: " + id;
	}

	return text;
}
if (!window.BPL) window.BPL = {};
window.BPL.getLocalText = getLocalText;

function canvasKeyPress(evt)
{
	if (zenPage && zenPage.canvasKeyPress) {
		zenPage.canvasKeyPress(evt);
	}
}

	>
	Write "]]></script>>"

	&html<
<!-- canvas -->
<svg id="canvasSVG" x="0" y="0" width="2000" height="2000">
<g	id="canvas"
	onmousemove="BPL.events.canvasMouseMove(evt);"
	onmouseup="BPL.events.canvasMouseUp(evt);"
	onmousedown="BPL.events.canvasMouseDown(evt);"
	onmouseover="BPL.events.canvasMouseOver(evt);"
>
<rect id="canvasRect" class="canvas" width="100%" height="100%"/>
<g id="gridlines"/>
<g id="bbGroup"/>

<text id="ModelTextPath" class="ModelTextPath" ><textPath xlink:href="#ModelPath">Model</textPath></text>

</g>

<!-- tooltip -->
<g id="tooltip" visibility="hidden" >
<path class="tooltipBalloon" d="M 0 0 L 250 0, 250 40, 310 60, 240 50 L 0 50 Z" />	
<text class="tooltipText" id="tooltipText" x="5" y="10" />
</g>

</svg>
	>
	Quit $$$OK
}

/// Callback method called when drawing the SVG CSS style for this page.
ClassMethod %OnDrawStyleSVG() As %Status
{
	#; style
	Write "<style type=""text/css""><![CDATA[",!
	&html<

text, tspan {
	pointer-events : none;
	font-size: 17px;
	fill: #404040;
	/* prevent Chrome/Safari from selecting elements during drag */
	-webkit-user-select: none;
}

.canvas {
	fill: #FAFAFF;
	stroke: gray;
	stroke-width: 1;
}

#canvasSVG {
	/* prevent Firefox from selecting text during drag */
	-moz-user-select: none;
}

.GridLine {
	fill: none;
	stroke: #D0D0FF;
	stroke-width: 0.2px;
}

.DiagramLabel {
	fill: white;
	stroke: #D0D0D0;
	stroke-width: 0.25;
}

.LevelLabel {
	fill: white;
	stroke: #D0D0D0;
	stroke-width: 0.25;
}

.LevelLabelSelected {
	fill: #FFEEAA;
	stroke: black;
	stroke-width: 2;
}

.BPLShape {
	fill: white;
	stroke: #8080D0;
	stroke-width: 2;
	fill-opacity: 1.0;
	stroke-linejoin: round;
}

.BPLShapeSelected {
	fill: #FFEEAA;
	stroke: rgb(53,107,141);
	stroke-width: 3;
	fill-opacity: 1.0;
	stroke-linejoin: round;
}

.BPLShapeDisabled {
	fill: silver;
	stroke: gray;
	stroke-width: 2;
	fill-opacity: 1.0;
	stroke-linejoin: round;
}

.BPLShapeDisabledSelected {
	fill: #FFEEAA;
	stroke: gray;
	stroke-width: 3;
	fill-opacity: 1.0;
	stroke-linejoin: round;
	stroke-dasharray: 4,4;
}

.BPLShapeMoving {
	fill: none;
	stroke: gray;
	stroke-width: 2;
	fill-opacity: 1.0;
}

.BPLShapeInvalid {
	fill: #FFFAFA;
	stroke: red;
	stroke-width: 1.8;
	fill-opacity: 1.0;
	stroke-linejoin: round;
}

.BPLShapeInvalidSelected {
	fill: #FFEEAA;
	stroke: red;
	stroke-width: 2.0;
	fill-opacity: 1.0;
	stroke-linejoin: round;
}

.BPLShapeDeleted {
	fill: red;
	stroke: yellow;
	stroke-width: 2;
	fill-opacity: 0.9;
}

.BPLShapeMatching {
	fill: #CCFFCC;
	stroke: purple;
	stroke-width: 3;
	fill-opacity: 1.0;
	stroke-linejoin: round;
}

/* outer shape for End event */
.BPLEventEnd {
	fill: white;
	stroke: #8080F0;
	stroke-width: 1.5;
	fill-opacity: 1.0;
}

/* outer shape for start event */
.BPLEventStart {
	fill: white;
	stroke: #8080F0;
	stroke-width: 3.0;
	fill-opacity: 1.0;
}

/* for intermediate events */
.BPLEvent {
	fill: white;
	stroke: #8080F0;
	stroke-width: 1.5;
	fill-opacity: 1.0;
}

.BPLEventInner {
	fill: none;
	stroke: #8080F0;
	stroke-width: 1;
}

.BPLEventIcon {
	fill: none;
	stroke: rgb(53,107,141);
	stroke-width: 1;
	opacity: 0.5;
}

.BPLActivityIcon {
	fill: none;
	stroke: rgb(53,107,141);
	stroke-width: 1;
	opacity: 0.6;
	stroke-linejoin: round;
	stroke-linecap: round;
}

.BPLActivityIconText {
	pointer-events: none;
	font-size: 12px;
	fill: rgb(53,107,141);
	font-style: italic;
	opacity: 0.6;
}

.BPLUnderConnector {
	stroke: blue;
	stroke-width: 20;
	stroke-linejoin: round;
	opacity: 0.0;
	fill: none;
}

.BPLConnector,
.BPLConnectorGoto {
	stroke: #404040;
	stroke-width: 2.5;
	stroke-linejoin: round;
	opacity: 0.5;
	fill: none;
}

.BPLConnectorGoto {
	stroke-dasharray: 2,2;
}

.BPLConnectorSelected,
.BPLConnectorGotoSelected {
	stroke: rgb(53,107,141);
	stroke-width: 5;
	stroke-linejoin: round;
	fill: none;
}

.BPLConnectorGotoSelected {
	stroke-dasharray: 3,3;
}

.OutputHandleOff {
	stroke: gray;
	stroke-width: 1;
	fill: white;
}

.OutputHandleOn {
	stroke: rgb(53,107,141);
	stroke-width: 1;
	fill: #FFEEAA;
}
  
.OutputHandleAccept {
	stroke: blue;
	stroke-width: 2;
	fill: green;
}

.HandleOver {
	stroke: gray;
	stroke-width: 1;
	fill: green;
}
  
.HandleOut {
	stroke: gray;
	stroke-width: 1;
	fill: white;
}
  
.HandleClick {
	stroke: yellow;
	stroke-width: 1;
	fill: blue;
}

.InputHandleOff {
	stroke: gray;
	stroke-width: 1;
	fill: white;
}

.InputHandleOn {
	stroke: rgb(53,107,141);
	stroke-width: 1;
	fill: #FFEEAA;
}

.InputHandleAccept {
	stroke: blue;
	stroke-width: 2;
	fill: green;
}

.AnnotationLine {
	stroke: #808080;
	stroke-width: 1;
	stroke-linejoin: round;
	stroke-linecap: round;
	fill: none;
}

.AnnotationBox {
	stroke: none;
	fill: #FDFDFD;
	opacity: 0.7;
}

.box {
	fill: yellow;
	stroke: black;
	stroke-width: 2;
}

.border {
	fill: lightgreen;
	visibility: hidden;
}

.data {
	visibility: hidden;
}
  
.ShapeName {
	pointer-events: none;
	fill: #404040;
	font-size: 17px;
}

.LabelLine {
	stroke: #000000;
	stroke-width: 1;
}

.LabelTitle {
	pointer-events: none;
	font-size: 18px;
	fill: #808080;
}

.LabelName {
	pointer-events: none;
	font-size: 22px;
	fill: #404040;
}

.LabelAnnotation {
	pointer-events: none;
	font-size: 14px;
	fill: #808080;
}

.LabelTime {
	pointer-events: none;
	font-size: 14px;
	fill: #808080;
}

.LevelActivityType {
	pointer-events: none;
	fill: #808080;
	font-size: 12px;
}

.LevelActivityName {
	pointer-events: none;
	fill: #808080;
	font-size: 20px;
}

.ConnectorText {
	pointer-events: none;
	font-size: 15px;
	fill: #404040;
	/*baseline-shift: 3px;*/
	font-weight: bold;
	opacity: 0.5;
}

.ConnectorTextSelected {
	pointer-events: none;
	font-size: 15px;
	fill: green;
	/*baseline-shift: 4px;*/
	font-weight: bold;
}

.ModelTextPath {
	visibility: hidden;
}

.AnnotationText {
	pointer-events: none;
	fill: #404040;
	font-size: 14px;
}

.ActivityType {
	pointer-events: none;
	fill: rgb(53,107,141);
	font-size: 12px;
}

.RubberBand {
	stroke: black;
	fill: none;
	stroke-width: 3;
	stroke-opacity: 0.5;
	stroke-linejoin: round;
}

.tooltipBalloon {
	stroke: gray;
	fill: url(#balloon);
	stroke-width: 1;
	stroke-opacity: 0.5;
}

.tooltipText {
	pointer-events: none;
	fill: blue;
	font-size: 12px;
	clip-path: url(#clipPath_balloon);
}

.boundingBox {
	fill: #AAAAFF;
	opacity: 0.5;
	stroke: black;
	stroke-width: 2px;
	stroke-dasharray: 3,2;
}

.boundingBoxLine {
	fill: none;
	opacity: 0.5;
	stroke: black;
	stroke-width: 1px;
	stroke-dasharray: 6,6;
}
>
	Write "]]></style>>"

	Quit $$$OK
}

/// Callback method called when drawing the SVG defs for this page.
ClassMethod %OnDrawSVGDef() As %Status
{
	&html<
<!-- defs -->

<defs>
<linearGradient id="hostgrad" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="50%" style="stop-color:#D0D0FF" />
<stop offset="90%" style="stop-color:#8080FF" />
</linearGradient>

<linearGradient id="hostgradselect" x1="0%" y1="0%" x2="0%" y2="100%">
<stop offset="50%" style="stop-color:yellow" />
<stop offset="90%" style="stop-color:orange" />
</linearGradient>

<clipPath id="clipPath_label">
<rect x="0" y="0" width="440" height="200" class="DiagramLabel" />
</clipPath>

<clipPath id="clipPath_level">
<rect x="0" y="0" width="275" height="40" class="DiagramLabel" />
</clipPath>

<clipPath id="clipPath_event">
<circle cx="0" cy="0" r="27" class="BPLShape" />
</clipPath>

<clipPath id="clipPath_decision">
<polygon points="-100,0 0,-30 100,0 0,30 -100,0" class="BPLShape" />
</clipPath>

<clipPath id="clipPath_activity">
<rect x="-120" y="-25" width="238" height="50" rx="15" class="BPLShape" />
</clipPath>

<clipPath id="clipPath_activityIcon">
<rect x="-120" y="-25" width="218" height="50" rx="15" class="BPLShape" />
</clipPath>

<clipPath id="clipPath_balloon">
<rect x="0" y="0" width="250" height="50" />
</clipPath>
</defs>
>

	Quit $$$OK
}

ClientMethod onSVGLoad() [ Language = javascript ]
{
	// notify container
	if (zenPage && zenPage.onSVGLoad) {
		zenPage.onSVGLoad();
	}
}

/// Set the zoom level
ClientMethod setZoom(zoom) [ Language = javascript ]
{
	var currZoom = zenParent.getProperty('zoom');
	if (zoom == currZoom) return;

	var oldzoom = currZoom;
	zenParent.setProperty('zoom',zoom);

 	// update context menu
 	svgPage.setMenuItemOption("checked","menu_zoom_" + oldzoom, "menu_zoom", false);
 	svgPage.setMenuItemOption("checked","menu_zoom_" + zoom, "menu_zoom", true);
}

/// set the option for the given menu item
ClientMethod setMenuItemOption(pOption, pItemId, pSubMenuId, value) [ Language = javascript ]
{
	// adobe only
	try {
		var menuItems = contextMenu.childNodes.item(0).childNodes;
		var tItem;
	      
		for (i = 0; i != menuItems.length - 1; i++) {
			if (menuItems.item(i).nodeType == 1) {
				tItem = menuItems.item(i);
				if (!pSubMenuId) {
					// top-level menu item
					if (tItem.getAttribute('id') == pItemId) {
						tItem.setAttribute(pOption,value ? 'yes' : 'no');
					}
				}
	            else if ((tItem.nodeName == 'menu') && (tItem.getAttribute('id') == pSubMenuId)) {
					// submenu
	
					// loop over items in submenu
					var submenuItems = tItem.childNodes;
	               
					for (j = 0; j != submenuItems.length - 1; j++) {
						tSubItem = submenuItems.item(j)
						if (tSubItem.nodeType == 1) {
							if (tSubItem.getAttribute('id') == pItemId) {
								tSubItem.setAttribute(pOption,value ? 'yes' : 'no');
							}
						}
					}
				}
			}
		}
	}
	catch(ex) {
	}
}

/// Escape JS avoiding double-escaping to \n
ClassMethod EscapeJSKeepLF(s As %String) As %String
{
	If $G(s)'["\n" Quit $ZCVT(s,"O","JS")
	Set out = ""
	For i = 1:1:$L(s,"\n") {
		Set a = $P(s,"\n",i)
		Set:out'="" out = out_"\n"
		Set out = out_$ZCVT(a,"O","JS")
	}
	Quit out
}

}
