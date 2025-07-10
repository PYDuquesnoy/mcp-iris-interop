/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI, %ZEN.Utils)

/// DTL Diagram<br>
/// This page renders the SVG needed to display the SVG portion of the DTL editor.
Class EnsPortal.SVG.DTLDiagram Extends EnsPortal.SVG.templatePage [ System = 4 ]
{

/// User needs READ permissions on either the %Ens_Code or the %Ens_DTL resource to view this page.
Parameter RESOURCE = "%Ens_Code:READ,%Ens_DTL:READ";

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// Comma-delimited list of additional .js files.
Parameter JSINCLUDES = "ensdtlzen.js,ensdtlparser.js";

/// Curr page of trace
Property currPage As %String(ZENURL = "PAGE");

Method %OnDrawSVGPage() As %Status
{
	Set tSC = ..DrawDTLDiagram()
	Quit tSC
}

/// Draw the SVG DTL diagram.
Method DrawDTLDiagram() As %Status
{
	// messages
	Set msgTarget = $$$Text("Target")
	Set msgNoTarget = $$$Text("no target object")
	Set msgSource = $$$Text("Source")
	Set msgNoSource = $$$Text("no source object")
	Set msgLoading = $$$Text("Loading...")

	Do ..DrawAdditionalScript()

	&html<
<!-- canvas -->
<svg id="canvasSVG" x="0" y="0" width="100" height="100%">
<g id="canvas" 
	onmousedown="canvasMouseDown(evt);"
	onmousemove="canvasMouseMove(evt);"
	onmouseup="canvasMouseUp(evt);"
	onmouseover="canvasMouseOver(evt);"
>

<rect id="canvasRect" class="canvas" x="0" y="0" width="100%" height="100%" />
<rect id="headerRect" class="header" x="0" y="0" width="100%" height="52" />

<!-- position of titles are set in js later as chrome does not handle % correctly 0--> 

<svg x="0" y="0" width="50%" height="50">
<text class="TitleSmall" id="sourceTitle" x="50%" y="14" text-anchor="middle">#(msgSource)#</text>
<text class="Title"  id="sourceName" x="50%" y="31" text-anchor="middle">&lt;#(msgNoSource)#&gt;</text>
<text class="TitleType" id="sourceType" x="50%" y="47" text-anchor="middle"> </text>

<rect class="scrollBtnBg" rx="2" x="5" y="5" width="12" height="40" transform="translate(24,0)" onclick="canvas_scrollSource();" onmouseover="evt.target.setAttribute('class','scrollBtnBgHover');" onmouseout="evt.target.setAttribute('class','scrollBtnBg');"/>
<polygon class="scrollBtn" points="5,6 15,12 5,18" transform="translate(25,26) rotate(90,10,12)" onclick="canvas_scrollSource(50);" onmouseover="evt.target.setAttribute('class','scrollBtnHover');" onmouseout="evt.target.setAttribute('class','scrollBtn');"/>
<polygon class="scrollBtn" points="5,6 15,12 5,18" transform="translate(25,0) rotate(-90,10,12)" onclick="canvas_scrollSource(-50);" onmouseover="evt.target.setAttribute('class','scrollBtnHover');" onmouseout="evt.target.setAttribute('class','scrollBtn');"/>
</svg>

<svg x="50%" y="0" width="50%" height="50">
<text class="TitleSmall" id="targetTitle" x="50%" y="14" text-anchor="middle">#(msgTarget)#</text>
<text class="Title" id="targetName" x="50%" y="31" text-anchor="middle">&lt;#(msgNoTarget)#&gt;</text>
<text class="TitleType" id="targetType" x="50%" y="47" text-anchor="middle"> </text>

<rect class="scrollBtnBg" rx="2" x="5" y="5" width="12" height="40" transform="translate(24,0)" onclick="canvas_scrollTarget();" onmouseover="evt.target.setAttribute('class','scrollBtnBgHover');" onmouseout="evt.target.setAttribute('class','scrollBtnBg');"/>
<polygon class="scrollBtn" points="5,6 15,12 5,18" transform="translate(25,26) rotate(90,10,12)" onclick="canvas_scrollTarget(50);" onmouseover="evt.target.setAttribute('class','scrollBtnHover');" onmouseout="evt.target.setAttribute('class','scrollBtn');"/>
<polygon class="scrollBtn" points="5,6 15,12 5,18" transform="translate(25,0) rotate(-90,10,12)" onclick="canvas_scrollTarget(-50);" onmouseover="evt.target.setAttribute('class','scrollBtnHover');" onmouseout="evt.target.setAttribute('class','scrollBtn');"/>
</svg>

<line class="TitleLine" x1="0" y1="52" x2="100%" y2="52" />

<!-- clipping frame -->
<svg id="clippingFrame" x="0" y="52" width="100%" height="100%" >
<g transform="translate(0,-52)">

<!-- dividing spine -->
<rect class="Spine" x="50%" y="0" width="40" height="100%" transform="translate(-20,0)"/>

<!-- group to contain connectors -->
<svg id="Spine" x="0" y="0" width="100%" height="100%" />

<!-- target box -->		
<svg id="targetFrame" x="0" y="0" width="100%" height="100%">
<rect class="container" id="targetBox" x="0" y="50" width="100%" height="100%"/>
</svg>

<!-- source box -->		
<svg id="sourceFrame" x="0" y="0" width="50%" height="100%">
<rect class="container" id="sourceBox" x="0" y="50" width="100%" height="100%"/>
</svg>

<!-- /clipping frame -->
</g>
</svg> 

</g>

<!-- status bar -->
<g id="StatusBar" style="display: none;">
<rect class="StatusBar" x="0" y="0" width="100" height="20" rx="2" />
<text class="StatusText" x="3" y="16" text-anchor="left">#(msgLoading)#</text>
</g>

</svg>
>
	Quit $$$OK
}

/// Write out any other scripts needed by editor.
Method DrawAdditionalScript()
{
	// script
	Write "<script language=""text/javascript""><![CDATA[",!

	&js<
function canvas_raiseSelectEvent(proplist)
{
}
	>

	Write "]]></script>>"
}

/// Callback method called when drawing the SVG CSS style for this page.
ClassMethod %OnDrawStyleSVG() As %Status
{
	#; find svg font from localization file
	Set tFont = $$$Text("FontFamily","tahoma,verdana")

	// find svg font from config global
	Set tFont = $G(^Ens.SVGStyle("font-family"),"tahoma,verdana")

	#; style
	Write "<style type=""text/css""><![CDATA[",!
	&html<
text, tspan {
	pointer-events : none;
	font-size: 17px;
	fill: #404040;
	font-family: ms mincho,arial;
	-webkit-user-select:none;
}

.canvas {
	fill: #FDFDFD;
	stroke: gray;
	stroke-width: 1;
}

#canvasSVG {
	/* prevent Firefox from selecting text during drag */
	-moz-user-select: none;
}

.header {
	fill: #D0D0E0;
	stroke: none;
}

/* rect that holds target/source boxes */
.container {
	fill: none;
}

.scrollBtn {
	opacity: 0.5;
	fill: #EEEEFF;
	stroke: #808080;
	stroke-width: 1;
}

.scrollBtnHover {
	opacity: 1.0;
	fill: #FFEEAA;
	stroke: #202020;
	stroke-width: 1;
}

.scrollBtnBg {
	opacity: 0.3;
	fill: #EEEEFF;
	stroke: #808080;
	stroke-width: 1;
}

.scrollBtnBgHover {
	opacity: 1.0;
	fill: #FFEEAA;
	stroke: #202020;
	stroke-width: 1;
}

.TitleLine {
	fill: none;
	stroke: #404040;
	stroke-width: 0.25;
}

.Spine {
	fill: #F0F0F8;
	stroke: #404040;
	stroke-width: 0.25;
}

.Expando {
	fill: #EEEEFF;
	stroke: #808080;
	stroke-width: 1;
}

.ExpandoNotLoaded {
	fill: #DDDDFF;
	stroke: #808080;
	stroke-width: 1;
}

.ExpandoDown {
	fill: yellow;
	stroke: #8080F0;
	stroke-width: 1.5;
}

.PropRect {
	fill: white;
	stroke: #8080D0;
	stroke-width: 1;
	opacity: 0.9;
}

.PropRectSelected {
	fill: #FFEEAA;
	stroke: rgb(53,107,141);
	stroke-width: 2;
}

.PropRectRelated {
	fill: #FFDDFF;
	stroke: rgb(53,107,141);
	stroke-width: 2;
}

.PropRectCanConnect {
	fill: orange;
	stroke: green;
	stroke-width: 1;
}

.IOActionNone {
	fill: white;
	stroke: #8080D0;
	stroke-width: 1;
}

.IOActionDisabled {
	fill: #DDEEFF;
	stroke: gray;
	stroke-width: 1;
}

.IOActionConnecting {
	fill: orange;
	stroke: #8080F0;
	stroke-width: 2;
}

.IOActionOver {
	fill: orange;
	stroke: #8080F0;
	stroke-width: 2;
}

.IOActionSelected {
	fill: #FFEEAA;
	stroke: rgb(53,107,141);
	stroke-width: 2;
}

.DTLAction {
	fill: none;
	stroke: green;
	stroke-width: 1.5;
	stroke-linejoin: round;
	opacity: 0.7;
}

.DTLActionRelated {
	fill: none;
	stroke: rgb(53,107,141);
	stroke-width: 3;
	stroke-linejoin: round;
}

.DTLActionSelected {
	fill: none;
	stroke: rgb(53,107,141);
	stroke-width: 3;
	stroke-linejoin: round;
}
.DTLActionHidden,
.DTLActionSelected.DTLActionHidden {
	stroke-dasharray: 4, 4;
}
.DTLActionDisabled,
.DTLActionSelected.DTLActionDisabled {
	stroke-dasharray: 2, 2;
	stroke: gray;
}

.DTLActionInvalid {
	stroke: red;
}

.DTLCircle {
	fill: white;
}

.DTLCircleSelected {
	fill: #FFEEAA;
	stroke: rgb(53,107,141);
}

.DTLCircleRelated {
	fill: #FFDDFF;
	stroke: rgb(53,107,141);
}

.StatusBar {
	fill: rgb(53,107,141);
	stroke: black;
	stroke-width: 1;
	filter: url(#dropShadow);
}

.StatusText {
  pointer-events: none;
  font-size: 9pt;
  fill: white;
  stroke: none;
}

.Title {
  pointer-events: none;
  font-size: 12pt;
  fill: #404040;
  font-weight: bold;
  stroke: none;
}

.Error {
  pointer-events: none;
  font-size: 12pt;
  fill: red;
  stroke: none;
}

.TitleSmall {
  pointer-events: none;
  font-size: 9pt;
  fill: #404040;
  stroke: none;
}

.TitleType {
  pointer-events: none;
  font-size: 10pt;
  fill: #404040;
  stroke: none;
}

.PropName {
  pointer-events: none;
  font-size: 10.5pt;
  font-weight: bold;
  fill: #606060;
  stroke: none;
}
  
.RubberBand {
  stroke: #404040;
  fill: none;
  stroke-width: 3;
  stroke-opacity: 0.5;
  stroke-linejoin: round;
  stroke-linecap: round;
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
	>
	Quit $$$OK
}

ClientMethod onSVGLoad() [ Language = javascript ]
{
	// notify container
	var container = zenPage;
	if (!container) { 
		container = window.parent && window.parent.zenPage ? window.parent.zenPage : null;
	}
	if (container && container.onSVGLoad) {
		container.onSVGLoad();
	}
}

/// Set the zoom level
ClientMethod setZoom(zoom) [ Language = javascript ]
{
	var currZoom = zenParent.getProperty('zoom');
	if (zoom == currZoom) return;

	var oldzoom = currZoom;
	zenParent.setProperty('zoom',zoom);
}

}
