/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Base class for SVG-based dashboard meters.
Class CSPX.Dashboard.Meter Extends (%RegisteredObject, %XML.Adaptor) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 3 ]
{

/// Use our own domain for localization
Parameter DOMAIN = "Ensemble";

/// Minimum width, in logical units, of this meter.
Parameter MINWIDTH As INTEGER = 100;

/// Minimum height, in logical units, of this meter.
Parameter MINHEIGHT As INTEGER = 100;

/// Default width, in logical units, of this meter.
Parameter WIDTH As INTEGER = 100;

/// Default height, in logical units, of this meter.
Parameter HEIGHT As INTEGER = 100;

/// Should this meter display the standard label
Parameter SHOWLABEL As BOOLEAN = 1;

/// Width, in logical units, of this meter.
/// Note, this value is determined by the WIDTH class parameter.
Property Width As %Integer(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = {..#WIDTH} ];

/// Height, in logical units, of this meter.
/// Note, this value is determined by the HEIGHT class parameter.
Property Height As %Integer(XMLPROJECTION = "ATTRIBUTE") [ InitialExpression = {..#HEIGHT} ];

/// Represents the initial level of the meter.
Property Level As %Float(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

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
Property Label As %String(MAXLEN = 250, XMLPROJECTION = "ATTRIBUTE");

/// Description for the meter.
Property Description As %String(MAXLEN = 250, XMLPROJECTION = "ELEMENT");

/// Business Metric service (config name) providing the metric for this meter.
Property Metric As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// Metric property providing the metric for this meter.
Property Property As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// Optional method, within the Dashboard class, used to transform
/// the Property value
Property Method As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// X Position, in logical units, of this meter.
Property XPos As %Integer(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// Y Position, in logical units, of this meter.
Property YPos As %Integer(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// Indicates that the label should be displayed for this meter.
Property ShowLabel As %Boolean(XMLPROJECTION = "NONE") [ InitialExpression = {..#SHOWLABEL}, ReadOnly ];

/// Indicates that the production providing the metrics for this meter is running.
Property IsRunning As %Boolean(XMLPROJECTION = "NONE");

/// Id used when meter is placed on client page
Property MeterId As %Integer(XMLPROJECTION = "NONE");

/// Number of properties displayed by this meter
Property PropertyCount As %Integer(XMLPROJECTION = "NONE") [ InitialExpression = 1 ];

/// If present, the link (URL) used to drill into details for this meter.
Property Link As %String(MAXLEN = 128, XMLPROJECTION = "ATTRIBUTE");

/// Contains list of properties using default values.
Property DefList As %String(MAXLEN = 200, XMLPROJECTION = "NONE");

/// Called before any scripts, styles, defs are written
/// Usually used to pick up include files
ClassMethod OnSVGHead()
{
}

/// Draw the style section of this SVG meter
ClassMethod OnSVGStyle()
{
}

/// Draw the script section of this SVG meter
ClassMethod OnSVGScript()
{
}

/// Draw the defs section of this SVG meter
ClassMethod OnSVGDefs()
{
}

/// Generate JavaScript to initialize client-side
/// meter object
Method OnSVGInitJS()
{
}

/// Draw the body of this SVG meter
/// <var>id</var> is a run-time assigned id value that must
/// be used to prefix any DOM identifiers within this meter
Method OnSVGBody()
{
}

/// Called by Dashboard class to generate code to
/// create an instace of this object.
/// The object instance is called <var>tMeter</var>.
/// The generated code will be called in the context of the OnPage method of the CSPX.Dashboard.Page class.
Method GenerateCode(pCode As %CharacterStream, pLevel As %Integer = 1) As %Status
{
	Do:(..Label'="") pCode.WriteLine(" Set tMeter.Label=""" _ ..Label _ """")
	Do:(..Metric'="") pCode.WriteLine(" Set tMeter.Metric=""" _ ..Metric _ """")
	Do:(..Property'="") pCode.WriteLine(" Set tMeter.Property=""" _ ..Property _ """")
	Do:(..Width'="") pCode.WriteLine(" Set tMeter.Width=" _ ..Width)
	Do:(..Height'="") pCode.WriteLine(" Set tMeter.Height=" _ ..Height)
	Do:(..ScaleFactor'="") pCode.WriteLine(" Set tMeter.ScaleFactor=" _ ..ScaleFactor)
	Do:(..Method'="") pCode.WriteLine(" Set tMeter.Method=""" _ ..Method _ """")

	// these values get defaults from the metric class
	// if not defined by the meter (use abbreviations)
	Set tDefList = ""

	If (..Link="") {
		Do pCode.WriteLine(" Set tMeter.Link=##class(%CSP.Page).Link(tMeter.GetDefault(""Link""))")
		Set tDefList = tDefList _ $S(tDefList="":"",1:"|") _ "L"
	}
	Else {
		Do pCode.WriteLine(" Set tMeter.Link=##class(%CSP.Page).Link(""" _ ..Link _ """)")
	}
	If (..RangeLower="") {
		Do pCode.WriteLine(" Set tMeter.RangeLower=tMeter.GetDefault(""RangeLower"")")
		Set tDefList = tDefList _ $S(tDefList="":"",1:"|") _ "RL"
	}
	Else {
		Do pCode.WriteLine(" Set tMeter.RangeLower=""" _ ..RangeLower _ """")
	}
	If (..RangeUpper="") {
		Do pCode.WriteLine(" Set tMeter.RangeUpper=tMeter.GetDefault(""RangeUpper"")")
		Set tDefList = tDefList _ $S(tDefList="":"",1:"|") _ "RU"
	}
	Else {
		Do pCode.WriteLine(" Set tMeter.RangeUpper=""" _ ..RangeUpper _ """")
	}

	If (..ThresholdLower="") {
		Do pCode.WriteLine(" Set tMeter.ThresholdLower=tMeter.GetDefault(""ThresholdLower"")")
		Set tDefList = tDefList _ $S(tDefList="":"",1:"|") _ "TL"
	}
	Else {
		Do pCode.WriteLine(" Set tMeter.ThresholdLower=""" _ ..ThresholdLower _ """")
	}

	If (..ThresholdUpper="") {
		Do pCode.WriteLine(" Set tMeter.ThresholdUpper=tMeter.GetDefault(""ThresholdUpper"")")
		Set tDefList = tDefList _ $S(tDefList="":"",1:"|") _ "TU"
	}
	Else {
		Do pCode.WriteLine(" Set tMeter.ThresholdUpper=""" _ ..ThresholdUpper _ """")
	}

	If (..Description="") {
		// no default for description
	}
	Else {
		Do pCode.WriteLine(" Set tMeter.Description=""" _ ..Description _ """")
	}

	Do pCode.WriteLine(" Set tMeter.DefList=""" _ tDefList _ """")

	Quit $$$OK
}

Method SetClientProperties() [ CodeMode = objectgenerator ]
{
	If (%class.Name = "CSPX.Dashboard.Meter") {
		Quit $$$OK
	}
	
	For i = 1:1:%compiledclass.Properties.Count() {
		Set prop = %compiledclass.Properties.GetAt(i)
		Set type = $$$NormalizeClassname(prop.Type)
		
		If (prop.Collection = "") {
		
			// create client name
			Set cname = prop.Name
			If cname?1"%%".e Continue // Skip %% properties!
			If (cname = "Metric") {
				// metric value
				Do %code.WriteLine(" Write ""meter.metric = '"" _ $ZCVT(##class(CSPX.Dashboard.Renderer).EvalMetric(..Metric),""O"",""JS"") _ ""';"",!")
			}
			Else {
				Set $E(cname,1,1) = $ZCVT($E(cname,1,1),"L")
				Do %code.Write(" Write ""meter." _ cname _ " = ")
				If ((type = "Ens.DataType.Metric") ||
					(type = "%Library.Boolean") || 
					(type = "%Library.Integer") || 
					(type = "%Library.Float")) {
						
					Do %code.WriteLine(""",+.." _ prop.Name _ ","";"",!")
				}
				ElseIf (type = "CSPX.Dashboard.GridDimension") {
					// special handling for Grids
					Do %code.WriteLine(""",$S($IsObject(.." _ prop.Name _ "):""'""_.."_prop.Name_".Source_""'"",1:""null""),"";"",!")
				}
				Else {
					Do %code.WriteLine("'"",$ZCVT(.." _ prop.Name _ ",""O"",""JS""),""';"",!")
				}
			}
		}
	}

	// other properties
	Do %code.WriteLine(" Write ""meter.units = '"" _ $ZCVT(..GetUnits(),""O"",""JS"") _ ""';"",!")

	Quit $$$OK
}

/// Returns the units used for the metric associated with this meter.
/// Units are a user-defined string specified (by the UNITS parameter) within
/// the BusinessMetric class.
Method GetUnits() As %String
{
	Set $ZT = "Trap"
	Set tUnits = ""
	If ((..Metric '= "") && (..Property '= "")) {
		// convert Metric to class name
		Set tClass = $$$ConfigClassName(..Metric)
		Set tUnits = $zobjclassmethod(tClass,..Property_"Units")
	}
Done
	Quit tUnits
Trap
	Set $ZT = ""
	Goto Done
}

/// Returns the default value (from the Metric class) for the given property
/// (e.g., RangeLower, etc).
Method GetDefault(pName As %String) As %String
{
	Set $ZT="Trap", tValue=""
	Do {
		If ((..Metric '= "") && (..Property '= "")) {
			// convert Metric to class name
			Set tMetric = $P(..Metric,"(",1) // pull off metric name
			Set tClass = $G($$$ConfigClassName(tMetric))  Quit:""=tClass
			Set tValue = $zobjclassmethod(tClass,..Property_pName)
		}
	} While(0)
Done
	Quit tValue
Trap
	Set $ZT=""
	Goto Done
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
