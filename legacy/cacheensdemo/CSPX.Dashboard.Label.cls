/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Label meter for Dashboard.<br>
/// A label does nothing but display a label within a Dashboard.
Class CSPX.Dashboard.Label Extends Meter [ ClassType = "", ProcedureBlock, System = 3 ]
{

Parameter MINHEIGHT = 25;

Parameter MINWIDTH = 50;

Parameter HEIGHT = 25;

Parameter WIDTH = 75;

/// Draw the script section of this SVG meter
ClassMethod OnSVGScript()
{
	&js<
	
function Label_setProperty(property,value)
{
	return false;
}
	>
}

}
