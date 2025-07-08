/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for Groups within an Dashboard.
Class CSPX.Dashboard.Group Extends Meter [ ClassType = "", CompileAfter = CSPX.Dashboard.BarChart, ProcedureBlock, System = 3 ]
{

Parameter SHOWLABEL = 0;

Parameter MINWIDTH = 0;

Parameter MINHEIGHT = 0;

Parameter WIDTH = 0;

Parameter HEIGHT = 0;

/// Meters belonging to this group
Property Meters As list Of Meter(XMLNAME = "Meters", XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

/// Direction in which to layout meters within this group.
Property Orientation As %String(MAXLEN = 10, VALUELIST = ",horizontal,vertical", XMLPROJECTION = "attribute") [ InitialExpression = "horizontal" ];

/// Insert a meter into this group
Method InsertMeter(pMeter As Meter)
{
	Do ..Meters.Insert(pMeter)
}

ClassMethod OnSVGStyle()
{
	&html<
.Group-OuterBorder { 
	fill: none;
	stroke: none;
	stroke-width: 1px;
}

.Group-Title { 
	pointer-events: none;
	font-size: 6;
	fill: yellow;
	stroke: none;
}
	>
}

/// Draw the script section of this SVG meter
ClassMethod OnSVGScript()
{
	&js<
function Group_setProperty(property,value)
{
	return false;
}
	>
}

Method OnSVGInitJS()
{
	// group methods
	&js<
meter.children = new Array();
meter.arrangeMeters = Group_arrangeMeters;
meter.alignMeters = Group_alignMeters;
meter.addMeter = Group_addMeter;
>
}

/// Draw the body of this SVG meter
Method OnSVGBody()
{
}

Method GenerateCode(pCode As %CharacterStream, pLevel As %Integer = 1) As %Status
{
	Set tVar = "tGroup" _ pLevel
	Do %code.WriteLine(" Set "_tVar_" = tMeter")
	Do:(..Label'="") pCode.WriteLine(" Set "_tVar_".Label=""" _ ..Label _ """")
	Do:(..Metric'="") pCode.WriteLine(" Set "_tVar_".Metric=""" _ ..Metric _ """")
	Do:(..Property'="") pCode.WriteLine(" Set "_tVar_".Property=""" _ ..Property _ """")
	Do:(..Orientation'="") pCode.WriteLine(" Set "_tVar_".Orientation=""" _ ..Orientation _ """")
	Do:(..Width'="") pCode.WriteLine(" Set "_tVar_".Width=" _ ..Width)
	Do:(..Height'="") pCode.WriteLine(" Set "_tVar_".Height=" _ ..Height)

	#; Generate code for each Meter within this group
	For i=1:1:..Meters.Count() {
		Set tMeter = ..Meters.GetAt(i)
		Do %code.WriteLine(" // " _ tMeter.%ClassName(1))
		Do %code.WriteLine(" Set tMeter = ##class(" _ tMeter.%ClassName(1) _ ").%New()")
		Do %code.WriteLine(" Do "_tVar_".InsertMeter(tMeter)")
		
		// apply default metric for members of this group
		If (tMeter.Metric = "") {
			Set tMeter.Metric = ..Metric
		}

		// default value of label		
		If (tMeter.Label = "") {
			Set tMeter.Label = tMeter.Property
		}

		Set tSC = tMeter.GenerateCode(%code, pLevel + 1)
		If $$$ISERR(tSC) Quit
	}

	Quit $$$OK
}

}
