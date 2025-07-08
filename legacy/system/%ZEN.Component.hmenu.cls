/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a specialized subclass of the <class>menu</class> component
/// that draws a horizontal menu.
Class %ZEN.Component.hmenu Extends menu [ Deprecated, System = 3 ]
{

Parameter DEFAULTWIDTH = "100%";

Parameter DEFAULTCELLALIGN = "left";

Parameter DEFAULTLAYOUT = "horizontal";

Parameter DEFAULTGROUPCLASS = "hmenuTable";

XData Style
{
<style type="text/css">
.hmenuTable {
	background: white;
	border-bottom: 1px solid darkblue;
	font-family: verdana;
	padding: 0px;
}

</style>
}

}
