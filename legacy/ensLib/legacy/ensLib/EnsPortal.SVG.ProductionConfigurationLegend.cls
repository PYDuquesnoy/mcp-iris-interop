/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Production Configuration Legend.<br>
/// This page renders the SVG needed to display the legend.
/// It is called from the ProductionConfigurationLegend dialog.
Class EnsPortal.SVG.ProductionConfigurationLegend Extends %ZEN.SVGComponent.svgPage [ System = 4 ]
{

/// User needs READ permissions on the %Ens_ProductionConfig resource to view this page.
Parameter RESOURCE = "%Ens_ProductionConfig:READ";

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

Method %OnDrawSVGPage() As %Status
{
	Set tSC = ..DrawLegend()
	Quit tSC
}

/// Draw the SVG legend.
Method DrawLegend() As %Status
{
	/*
	Add a Legend option to the SVG context menu on the Config Diagram pane. 
	It should describe what the different color indicators mean for Hosts and Adapters.

Here is a sample description of what they mean:

Host indicators (circular):
Red - The last message this config item processed resulted in an error
Green - The last message processed by this config item was completed successfully
Purple - This config item is retrying its current message
Yellow - This config item is inactive based on its configured Inactivity Timeout
Dim Red -
Dim Green -
Dim Purple -
Dim Yellow - For stopped items, the dimmed colors show the last color an item had before it was stopped
Grey - not enabled, stopped or starting up

Adapter indicators (triangular) for adapters that can maintain a connection to an external system:
Red - At least one job for the host is not connected and either has queued messages (Operations only) or the host is configured with StayConnected=-1 (meaning it should never voluntarily disconnect)
Green - The adapter has at least one connection active and no job in a state that would make it Red
Yellow - The adapter is listening for a connection (Services) or has no connection and no queued messages (Operations)
Grey - The adapter is disabled or has no jobs running
Dim Red -
Dim Green -
Dim Yellow - For stopped items, the dimmed colors show the last color an item had before it was stopped
Note that the Production Configuration page no longer depicts the adapter status 
	*/

	&html<

<rect class="canvas" x="0" y="0" width="640" height="420" />

<text class="text.GroupHeader" x="30" y="40" text-anchor="start">#($$$TextHTML("Indicators"))#</text>

<g transform="translate(20,60)">
<circle class="itemStopped" cx="10" cy="6" r="7" />
<text class="Label" x="25" y="10" text-anchor="start">#($$$TextHTML("Not running, enabled"))#</text>
</g>

<g transform="translate(20,90)">
<circle class="itemRunning" cx="10" cy="6" r="7" />
<text class="Label" x="25" y="10" text-anchor="start">#($$$TextHTML("Running"))#</text>
</g>

<g transform="translate(20,120)">
<circle class="itemDisabled" cx="10" cy="6" r="7" />
<text class="Label" x="25" y="10" text-anchor="start">#($$$TextHTML("Disabled"))#</text>
</g>

<g transform="translate(20,150)">
<circle class="itemError" cx="10" cy="6" r="7" />
<text class="Label" x="25" y="10" text-anchor="start">#($$$TextHTML("Error"))#</text>
</g>

<g transform="translate(20,180)">
<circle class="itemRetrying" cx="10" cy="6" r="7" />
<text class="Label" x="25" y="10" text-anchor="start">#($$$TextHTML("Retrying"))#</text>
</g>

<g transform="translate(20,210)">
<circle class="itemInactive" cx="10" cy="6" r="7" />
<text class="Label" x="25" y="10" text-anchor="start">#($$$TextHTML("Inactive"))#</text>
</g>

<text class="text.GroupHeader" x="30" y="260" text-anchor="start">#($$$TextHTML("Interaction"))#</text>

<text class="Label" x="25" y="290" text-anchor="start">#($$$TextHTML("Click on an item's name to view its details"))#</text>

<text class="Label" x="25" y="320" text-anchor="start">#($$$TextHTML("Click on an indicator to view the connections"))#</text>

<text class="Label" x="25" y="350" text-anchor="start">#($$$TextHTML("Double-click on an item to enable, disable or restart it"))#</text>

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

.itemStopped {
	fill: #DEFFBC;
	stroke: gray;
	stroke-width: 1;
	opacity: 1.0;
}

.itemRunning {
	fill: #20C020;
	stroke: gray;
	stroke-width: 1;
	opacity: 1.0;
}

.itemDisabled {
	fill: #D0D0D0;
	stroke: gray;
	stroke-width: 1;
	opacity: 1.0;
}

.itemError {
	fill: red;
	stroke: gray;
	stroke-width: 1;
	opacity: 1.0;
}

.itemRetrying {
	fill: #9900CC;
	stroke: gray;
	stroke-width: 1;
	opacity: 1.0;
}

.itemInactive {
	fill: yellow;
	stroke: gray;
	stroke-width: 1;
	opacity: 1.0;
}

text.Title {
	font-size : 18pt;
	stroke : none;
	fill: blue;
}

text.GroupHeader {
	font-size : 10pt;
	font-weight: bold;
	stroke : none;
	fill: black;
}

text.Label {
	font-size : 10pt;
	stroke : none;
	fill: black;
}

text, tspan {
	font-family: #(tFont)#;
}

>
	Write "]]></style>>"
	Quit $$$OK
}

}
