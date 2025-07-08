/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Spacer meter for Dashboard.<br>
/// A spacer does not display any thing; it is simply
/// used to take up space in the dashboard for layout purposes.
Class CSPX.Dashboard.Spacer Extends Meter [ ClassType = "", ProcedureBlock, System = 3 ]
{

/// Should this meter display the standard label
Parameter SHOWLABEL As BOOLEAN = 0;

/// Minimum width, in logical units, of this meter.
Parameter MINWIDTH As INTEGER = 1;

/// Minimum height, in logical units, of this meter.
Parameter MINHEIGHT As INTEGER = 1;

/// Default width, in logical units, of this meter.
Parameter WIDTH As INTEGER = 25;

/// Default height, in logical units, of this meter.
Parameter HEIGHT As INTEGER = 25;

/// Draw the script section of this SVG meter
ClassMethod OnSVGScript()
{
	&js<
	
function Spacer_setProperty(property,value)
{
	return false;
}
	>
}

}
