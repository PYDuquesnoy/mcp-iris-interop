/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (Ensemble, EnsUI)

/// Visual Trace SVG Legend<br>
/// This page renders the SVG needed to display the Visual Trace Legend.
/// It is called from the TraceLegend dialog.
Class EnsPortal.SVG.TraceLegend Extends %ZEN.SVGComponent.svgPage [ System = 4 ]
{

/// User needs USE privilege on the %Ens_MessageTrace resource to view this page.
Parameter RESOURCE = "%Ens_MessageTrace";

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Method %OnDrawSVGPage() As %Status
{
	Set tSC = ..DrawMessageLegend()
	Quit tSC
}

/// Draw the SVG message legend
Method DrawMessageLegend() As %Status
{
	Set msgTime = $$$TextHTML("Time")
	Set msgType = $$$TextHTML("Message Type")

	&html<
<rect class="canvas" x="0" y="0" width="800" height="510" />

<text class="HostTitle" x="30" y="40" text-anchor="start">#($$$TextHTML("Messages"))#</text>

<g transform="translate(20,70)">
<line class="SepLine" x1="0" y1="-20" x2="240" y2="-20" />
<text class="Label" x="10" y="4" text-anchor="start">#($$$TextHTML("Synchronous request"))#</text>
<rect class="MsgOutline" x="10" y="8" width="190" height="24" rx="3" />
<rect class="MsgTermSync" x="183" y="11" width="14" height="18" rx="2"/>
<line class="MsgLineRequest" x1="20" y1="20" x2="182" y2="20" />
<circle class="MsgStartSync" cx="20" cy="20" r="8"/>
<line class="MsgLineRequest" x1="177" y1="15" x2="182" y2="20" />
<line class="MsgLineRequest" x1="177" y1="25" x2="182" y2="20" />
<text class="MsgLabel" x="35" y="18" text-anchor="start">#(msgTime)#</text>
<text class="MsgLabel" x="35" y="30" text-anchor="start">#(msgType)#</text>
</g>

<g transform="translate(20,140)">
<line class="SepLine" x1="0" y1="-20" x2="240" y2="-20" />
<text class="Label" x="10" y="4" text-anchor="start">#($$$TextHTML("Asynchronous request with response"))#</text>
<rect class="MsgOutline" x="10" y="8" width="190" height="24" rx="3" />
<rect class="MsgTermAsync" x="183" y="11" width="14" height="18" rx="2"/>
<line class="MsgLineRequest" x1="20" y1="20" x2="182" y2="20" />
<circle class="MsgStartAsync" cx="20" cy="20" r="8"/>
<line class="MsgLineRequest" x1="177" y1="15" x2="182" y2="20" />
<line class="MsgLineRequest" x1="177" y1="25" x2="182" y2="20" />
<line class="MsgLineRequest" x1="172" y1="15" x2="177" y2="20" />
<line class="MsgLineRequest" x1="172" y1="25" x2="177" y2="20" />
<text class="MsgLabel" x="35" y="18" text-anchor="start">#(msgTime)#</text>
<text class="MsgLabel" x="35" y="30" text-anchor="start">#(msgType)#</text>
</g>

<g transform="translate(20,210)">
<line class="SepLine" x1="0" y1="-20" x2="240" y2="-20" />
<text class="Label" x="10" y="4" text-anchor="start">#($$$TextHTML("Asynchronous request; no response"))#</text>
<rect class="MsgOutline" x="10" y="8" width="190" height="24" rx="3" />
<rect class="MsgTermNoResponse" x="183" y="11" width="14" height="18" rx="2"/>
<line class="MsgLineRequest" x1="20" y1="20" x2="182" y2="20" />
<circle class="MsgStartNoResponse" cx="20" cy="20" r="8"/>
<line class="MsgLineRequest" x1="177" y1="14" x2="177" y2="26" />
<line class="MsgLineRequest" x1="172" y1="15" x2="177" y2="20" />
<line class="MsgLineRequest" x1="172" y1="25" x2="177" y2="20" />
<text class="MsgLabel" x="35" y="18" text-anchor="start">#(msgTime)#</text>
<text class="MsgLabel" x="35" y="30" text-anchor="start">#(msgType)#</text>
</g>

<g transform="translate(20,280)">
<line class="SepLine" x1="0" y1="-20" x2="240" y2="-20" />
<text class="Label" x="10" y="4" text-anchor="start">#($$$TextHTML("Synchronous response"))#</text>
<rect class="MsgOutline" x="10" y="8" width="190" height="24" rx="3" />
<rect class="MsgTermSyncResponse" x="13" y="11" width="14" height="18" rx="2"/>
<line class="MsgLineResponse" x1="27" y1="20" x2="182" y2="20" />
<circle class="MsgStartSyncResponse" cx="189" cy="20" r="6"/>
<line class="MsgLineResponse" x1="28" y1="20" x2="33" y2="15" />
<line class="MsgLineResponse" x1="28" y1="20" x2="33" y2="25" />
<text class="MsgLabel" x="175" y="18" text-anchor="end">#(msgTime)#</text>
<text class="MsgLabel" x="175" y="30" text-anchor="end">#(msgType)#</text>
</g>

<g transform="translate(20,350)">
<line class="SepLine" x1="0" y1="-20" x2="240" y2="-20" />
<text class="Label" x="10" y="4" text-anchor="start">#($$$TextHTML("Asynchronous response"))#</text>
<rect class="MsgOutline" x="10" y="8" width="190" height="24" rx="3" />
<rect class="MsgTermAsyncResponse" x="13" y="11" width="14" height="18" rx="2"/>
<line class="MsgLineResponse" x1="27" y1="20" x2="182" y2="20" />
<circle class="MsgStartAsyncResponse" cx="189" cy="20" r="6"/>
<line class="MsgLineResponse" x1="28" y1="20" x2="33" y2="15" />
<line class="MsgLineResponse" x1="28" y1="20" x2="33" y2="25" />
<line class="MsgLineResponse" x1="33" y1="20" x2="38" y2="15" />
<line class="MsgLineResponse" x1="33" y1="20" x2="38" y2="25" />
<text class="MsgLabel" x="175" y="18" text-anchor="end">#(msgTime)#</text>
<text class="MsgLabel" x="175" y="30" text-anchor="end">#(msgType)#</text>
</g>

<g transform="translate(20,420)">
<line class="SepLine" x1="0" y1="-20" x2="240" y2="-20" />
<text class="Label" x="10" y="4" text-anchor="start">#($$$TextHTML("Discarded response"))#</text>
<rect class="MsgOutline" x="10" y="8" width="190" height="24" rx="3" />
<rect class="MsgTermDiscarded" x="13" y="11" width="14" height="18" rx="2"/>
<line class="MsgLineResponse" x1="27" y1="20" x2="182" y2="20" />
<circle class="Discarded" cx="189" cy="20" r="6"/>
<circle class="Discarded" cx="33" cy="20" r="5"/>
<text class="MsgLabel" x="175" y="18" text-anchor="end">#(msgTime)#</text>
<text class="MsgLabel" x="175" y="30" text-anchor="end">#(msgType)#</text>
</g>

/* Assert,Error,Warning,Info,Trace,Alert */

<text class="HostTitle" x="360" y="40" text-anchor="start">#($$$TextHTML("Events"))#</text>

<g transform="translate(350,70)">
<line class="SepLine" x1="0" y1="-20" x2="150" y2="-20" />
<text class="Label" x="10" y="4" text-anchor="start">#($$$TextHTML("Event Log Error"))#</text>
<g transform="translate(20,20)">
<rect class="eventMarkerBack" x="-8" y="-8" width="16" height="16" />
<path class="eventMarker2" d="M -6 0 L 0 6 6 0 0 -6 Z" />
</g>
</g>

<g transform="translate(350,140)">
<line class="SepLine" x1="0" y1="-20" x2="150" y2="-20" />
<text class="Label" x="10" y="4" text-anchor="start">#($$$TextHTML("Event Log Warning"))#</text>
<g transform="translate(20,20)">
<rect class="eventMarkerBack" x="-8" y="-8" width="16" height="16" />
<path class="eventMarker3" d="M -6 0 L 0 6 6 0 0 -6 Z" />
</g>
</g>

<g transform="translate(350,210)">
<line class="SepLine" x1="0" y1="-20" x2="150" y2="-20" />
<text class="Label" x="10" y="4" text-anchor="start">#($$$TextHTML("Event Log Alert"))#</text>
<g transform="translate(20,20)">
<rect class="eventMarkerBack" x="-8" y="-8" width="16" height="16" />
<path class="eventMarker6" d="M -6 0 L 0 6 6 0 0 -6 Z" />
</g>
</g>

<g transform="translate(350,280)">
<line class="SepLine" x1="0" y1="-20" x2="150" y2="-20" />
<text class="Label" x="10" y="4" text-anchor="start">#($$$TextHTML("Event Log Info"))#</text>
<g transform="translate(20,20)">
<rect class="eventMarkerBack" x="-8" y="-8" width="16" height="16" />
<path class="eventMarker4" d="M -6 0 L 0 6 6 0 0 -6 Z" />
</g>
</g>

<g transform="translate(350,350)">
<line class="SepLine" x1="0" y1="-20" x2="150" y2="-20" />
<text class="Label" x="10" y="4" text-anchor="start">#($$$TextHTML("Event Log Trace"))#</text>
<g transform="translate(20,20)">
<rect class="eventMarkerBack" x="-8" y="-8" width="16" height="16" />
<path class="eventMarker5" d="M -6 0 L 0 6 6 0 0 -6 Z" />
</g>
</g>
 
<g transform="translate(350,420)">
<line class="SepLine" x1="0" y1="-20" x2="150" y2="-20" />
<text class="Label" x="10" y="4" text-anchor="start">#($$$TextHTML("Event Log Assert"))#</text>
<g transform="translate(20,20)">
<rect class="eventMarkerBack" x="-8" y="-8" width="16" height="16" />
<path class="eventMarker1" d="M -6 0 L 0 6 6 0 0 -6 Z" />
</g>
</g>

/* IOLog entry, EDI Acknowledgement Response */

<text class="HostTitle" x="610" y="40" text-anchor="start">#($$$TextHTML("IOLog"))#</text>

<g transform="translate(600,70)">
<line class="SepLine" x1="0" y1="-20" x2="150" y2="-20" />
<text class="Label" x="10" y="4" text-anchor="start">#($$$TextHTML("IOLog Record"))#</text>
<g transform="translate(20,20)">
<rect class="eventMarkerBack" x="-9" y="-9" width="18" height="18" rx="1" />
<path class="ioArrows" d="M -7 -5 L 1 -5 1 -8 8 -4 1 1 1 -2 -8 -2 Z" />
<path class="ioArrows" d="M 7 5 L -1 5 -1 8 -8 4 -1 -1 -1 2 8 2 Z" />
</g>
</g>

<g transform="translate(600,140)">
<line class="SepLine" x1="0" y1="-20" x2="150" y2="-20" />
<text class="Label" x="10" y="4" text-anchor="start">#($$$TextHTML("EDI Response"))#</text>
<g transform="translate(20,20)">
<rect class="ackBack" x="-7" y="-7" width="14" height="14" />
<path class="ackArrow" d="M -6 0 L 0 5 0 1 6 1 6 -2 0 -2 0 -6 Z"/>
</g>
</g>

/* Rule Log */

<text class="HostTitle" x="610" y="220" text-anchor="start">#($$$TextHTML("Rule Log"))#</text>

<g transform="translate(600,250)">
<line class="SepLine" x1="0" y1="-20" x2="150" y2="-20" />
<text class="Label" x="10" y="4" text-anchor="start">#($$$TextHTML("Rule Log Record"))#</text>
<g transform="translate(20,20)">
<rect class="eventMarkerBack" x="-9" y="-9" width="18" height="18" rx="1" />
<path class="ruleMarker1" d="M 0 0 m -7, 0
        a 7,7 0 1,0 14,0
        a 7,7 0 1,0 -14,0"/>
</g>
</g>


	>
	Quit $$$OK
}

/// Callback method called when drawing the SVG CSS style for this page.
ClassMethod %OnDrawStyleSVG() As %Status
{
	#; find svg font from localization file
	Set tFont = $$$Text("FontFamily","Arial,Tahoma,Verdana")

	#; style
	Write "<style type=""text/css""><![CDATA[",!
	&html<

.canvas {
	fill: white;
	stroke : gray;
	stroke-width : 1;
}

rect.TitleRect {
	fill: #FFEEDD;
	stroke : black;
	stroke-width : 1;
}

rect.HostRect {
	fill: #EEDDFF;
	stroke : blue;
	stroke-width : 1;
}

rect.HostRectSelect {
	fill: yellow;
	stroke : green;
	stroke-width : 2;
}

rect.LaneRect1 {
	fill: none;
	stroke : none;
}

rect.LaneRect2 {
	fill: white;
	stroke : none;
}

rect.LaneRect3 {
	fill: none;
	stroke : none;
}

text.LaneTitle {
	font-size : 16pt;
	stroke : none;
	fill: black;
}

text.HostTitle {
	font-size : 9pt;
	font-weight: bold;
	stroke : none;
	fill: black;
}

text.MsgLabel {
  font-size: 8pt;
  stroke: none;
  fill: black;
}

text.Title {
	font-size : 18pt;
	stroke : none;
	fill: blue;
}

text.Label {
	font-size : 10pt;
	stroke : none;
	fill: black;
}

line.SepLine {
	stroke : gray;
	stroke-width : 1;
}

line.Time {
	stroke : gray;
	stroke-width : 2;
	stroke-linecap: round;
}

rect.HostLine {
	fill: #E0E0E0;
	stroke : gray;
	stroke-width : 1;
}

rect.HostLineSelect {
	fill: yellow;
	stroke : green;
	stroke-width : 2;
}

rect.MsgOutline {
	fill: white;
	stroke: darkblue;
	stroke-width: 2;
	fill-opacity: 0.9;
}

line.MsgLineRequest {
	stroke : blue;
	stroke-width : 2;
	stroke-linecap: round;
	opacity: 0.8;
}

line.MsgLineResponse {
	stroke : green;
	stroke-width : 2;
	stroke-linecap: round;
	opacity: 0.8;
}

rect.MsgTerm {
	fill: gray;
	stroke : blue;
	stroke-width : 1;
}

rect.MsgTermQueued {
	fill: gray;
	stroke : black;
	stroke-width : 1;
}

rect.MsgTermDiscarded {
	fill: silver;
	stroke : blue;
	stroke-width : 1;
}

rect.MsgTermNoResponse {
	fill: orange;
	stroke : blue;
	stroke-width : 1;
}

rect.MsgTermResponse {
	fill: plum;
	stroke : blue;
	stroke-width : 1;
}

rect.MsgTermAsyncResponse {
	fill: plum;
	stroke : blue;
	stroke-width : 1;
}

rect.MsgTermSyncResponse {
	fill: lightblue;
	stroke : blue;
	stroke-width : 1;
}

rect.MsgTermAsync {
	fill: plum;
	stroke : blue;
	stroke-width : 1;
}

rect.MsgTermSync {
	fill: lightblue;
	stroke : blue;
	stroke-width : 1;
}

circle.Discarded {
	fill: silver;
	stroke : blue;
	stroke-width : 1;
}

circle.MsgStart {
	fill: yellow;
	stroke : blue;
	stroke-width : 1;
}

circle.MsgStartNoResponse {
	fill: orange;
	stroke : blue;
	stroke-width : 1;
}

circle.MsgStartSyncResponse {
	fill: lightblue;
	stroke : blue;
	stroke-width : 1;
}

circle.MsgStartResponse {
	fill: plum;
	stroke : blue;
	stroke-width : 1;
}

circle.MsgStartSync {
	fill: lightblue;
	stroke : blue;
	stroke-width : 1;
}

circle.MsgStartAsync {
	fill: plum;
	stroke : blue;
	stroke-width : 1;
}

circle.MsgStartAsyncResponse {
	fill: plum;
	stroke : blue;
	stroke-width : 1;
}

.eventMarkerBack {
	fill: white;
	stroke: blue;
	stroke-width: 1;
	opacity: 0.9;
}

text, tspan {
	font-family: #(tFont)#;
}

/* Assert,Error,Warning,Info,Trace,Alert */

.eventMarker1 {
	fill: silver;
	stroke: black;
	stroke-width: 1;
}

.eventMarker2 {
	fill: red;
	stroke: black;
	stroke-width: 1;
	opacity: 0.7;
}

.eventMarker3 {
	fill: orange;
	stroke: black;
	stroke-width: 1;
}

.eventMarker4 {
	fill: white;
	stroke: black;
	stroke-width: 1;
}

.eventMarker5 {
	fill: lightblue;
	stroke: black;
	stroke-width: 1;
}

.eventMarker6 {
	fill: yellow;
	stroke: black;
	stroke-width: 1;
}

/* Rule Log */

.ruleMarker1 {
	fill: green;
	stroke: black;
	stroke-width: 1;
}

/* IOLog */

.ackArrow {
	fill: green;
	stroke: black;
	stroke-width: 0;
}

.ackBack {
	fill: white;
	stroke: blue;
	stroke-width: 1;
	opacity: 0.9;
}

.ioArrows {
	fill: blue;
	stroke-width: 0;
}
>
	Write "]]></style>>"
	Quit $$$OK
}

}
