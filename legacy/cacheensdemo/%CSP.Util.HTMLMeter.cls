/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>Base class for HTML-based dashboard meters.
Class %CSP.Util.HTMLMeter Extends (%RegisteredObject, %XML.Adaptor) [ Inheritance = right, ServerOnly = 1, System = 4 ]
{

/// Default domain for the Portal's localization.
Parameter DOMAIN = "%Utility";

/// Minimum width, in logical units, of this meter.
Parameter MINWIDTH As INTEGER = 0;

/// Minimum height, in logical units, of this meter.
Parameter MINHEIGHT As INTEGER = 0;

/// Default width, in logical units, of this meter.
Parameter WIDTH As INTEGER = 100;

/// Default height, in logical units, of this meter.
Parameter HEIGHT As INTEGER = 20;

/// Should this meter display the standard label
Parameter SHOWLABEL As BOOLEAN = 1;

/// Width, in logical units, of this meter.
/// Note, this value is determined by the WIDTH class parameter.
Property Width As %Integer(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = {..#WIDTH} ];

/// Height, in logical units, of this meter.
/// Note, this value is determined by the HEIGHT class parameter.
Property Height As %Integer(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = {..#HEIGHT} ];

/// Represents the lower value of the meter range.
Property RangeLower As %Float(XMLPROJECTION = "ATTRIBUTE");

/// Represents the upper value of the meter range.
Property RangeUpper As %Float(XMLPROJECTION = "ATTRIBUTE");

/// Represents the lower threshold level for the meter.
Property ThresholdLower As %Float(XMLPROJECTION = "ATTRIBUTE");

/// Represents the upper threshold level for the meter.
Property ThresholdUpper As %Float(XMLPROJECTION = "ATTRIBUTE");

/// For numeric displays, the meter will multiply the current
/// level by this amount before displaying it.
Property ScaleFactor As %Float(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = 1 ];

/// The label displayed for the meter.
Property Label As %String(MAXLEN = 50, XMLPROJECTION = "ATTRIBUTE");

/// Optional details text (as HTML) for the meter.
Property Detail As %String(MAXLEN = 500, XMLPROJECTION = "ATTRIBUTE");

/// The initial value of the meter.
Property InitialValue As %String(MAXLEN = 500, XMLPROJECTION = "NONE");

/// The initial status of the meter.
Property InitialStatus As %String(MAXLEN = 50, XMLPROJECTION = "NONE");

/// Description for the meter.
Property Description As %String(MAXLEN = 250, XMLPROJECTION = "ELEMENT");

/// Metric property providing the metric for this meter.
Property Property As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// The resolved full property name.
Property FullProperty As %String(MAXLEN = 500, XMLPROJECTION = "NONE");

/// Parent meter for grouped elements
Property Parent As HTMLMeter(XMLPROJECTION = "NONE");

/// Dashboard this meter is part of
Property Dashboard As HTMLDashboardPane(XMLPROJECTION = "NONE");

/// Indicates that the label should be displayed for this meter.
Property ShowLabel As %Boolean(XMLPROJECTION = "NONE") [ InitialExpression = {..#SHOWLABEL}, ReadOnly ];

/// Id used when meter is placed on client page
Property MeterId As %Integer(XMLPROJECTION = "NONE");

/// If present, the link (URL) used to drill into details for this meter.
Property Link As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// Called before any scripts, styles, defs are written
/// Usually used to pick up include files
ClassMethod OnHTMLHead()
{
	&html<<!-- Meter -->>
}

/// Draw the style section of this HTML meter
ClassMethod OnHTMLStyle()
{
}

/// Draw the script section of this HTML meter
ClassMethod OnHTMLScript()
{
	Write "function ",..%ClassName(0),"_setProperty(prop, value, status)",!
	Write "{ return false; }",!
}

/// Generate JavaScript to initialize client-side
/// meter object
Method OnHTMLInitJS()
{
}

/// Draw the body of this HTML meter
Method OnHTMLBody()
{
}

/// Draw standard selector / indicator box for meter
Method DrawSelector()
{
	Set SpaceImage = ##class(%CSP.Page).Link("/csp/sys/images/spacer.gif")
	&html<<td width="18" valign="top"><image id="selector_#(..MeterId)#" src="#(SpaceImage)#" width="16"></td>>
	
	If (..Dashboard.ShowIcons) {
		&html<<td width="26" valign="top"><image id="indicator_#(..MeterId)#" src="#(SpaceImage)#" width="24"></td>>
	}
}

/// Called by Dashboard class to generate code to
/// create an instace of this object.
/// The object instance is called <var>tMeter</var>.
Method GenerateCode(pCode As %CharacterStream, pLevel As %Integer = 1) As %Status
{
	Do:(..Label'="") pCode.WriteLine(" Set tMeter.Label = $$$Text(""" _ ..Label _ """)")
	Do:(..Property'="") pCode.WriteLine(" Set tMeter.Property = """ _ ..Property _ """")
	Do:(..Width'="") pCode.WriteLine(" Set tMeter.Width = " _ ..Width)
	Do:(..Height'="") pCode.WriteLine(" Set tMeter.Height = " _ ..Height)
	Do:(..ScaleFactor'="") pCode.WriteLine(" Set tMeter.ScaleFactor = " _ ..ScaleFactor)

	// these values get defaults from the metric class
	// if not defined by the meter (use abbreviations)
	Set tDefList = ""

	If (..Link'="") {
		Do pCode.WriteLine(" Set tMeter.Link = """ _ ..Link _ """")
	}
	If (..Detail'="") {
		Do pCode.WriteLine(" Set tMeter.Detail = $$$Text(""" _ ..Detail _ """)")
	}
	If (..RangeLower'="") {
		Do pCode.WriteLine(" Set tMeter.RangeLower =""" _ ..RangeLower _ """")
	}
	If (..RangeUpper'="") {
		Do pCode.WriteLine(" Set tMeter.RangeUpper = """ _ ..RangeUpper _ """")
	}
	If (..ThresholdLower'="") {
		Do pCode.WriteLine(" Set tMeter.ThresholdLower = """ _ ..ThresholdLower _ """")
	}
	If (..ThresholdUpper'="") {
		Do pCode.WriteLine(" Set tMeter.ThresholdUpper = """ _ ..ThresholdUpper _ """")
	}
	If (..Description'="") {
		Do pCode.WriteLine(" Set tMeter.Description= $$$Text(""" _ ..Description _ """)")
	}

	Quit $$$OK
}

Method WidthSet(%val As %Integer) As %Status
{
	// don't allow width below minimum
	Set i%Width = $S(%val>..#MINWIDTH:%val,1:..#MINWIDTH)
	Quit $$$OK
}

Method HeightSet(%val As %Integer) As %Status
{
	// don't allow height below minimum
	Set i%Height = $S(%val>..#MINHEIGHT:%val,1:..#MINHEIGHT)
	Quit $$$OK
}

}
