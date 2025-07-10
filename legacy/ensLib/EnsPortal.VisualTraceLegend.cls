/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.VisualTraceLegend Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs USE permissions on the %Ens_MessageTrace resource to view this page.
Parameter RESOURCE = "%Ens_MessageTrace:USE";

Parameter APPLYBUTTON As BOOLEAN = 0;

Parameter OKBUTTON As BOOLEAN = 1;

Parameter CANCELBUTTON As BOOLEAN = 0;

Parameter CLOSEONENTER = 1;

XData Style
{
<style type="text/css">

body {
	margin: 0px;
	padding: 0px;
}

</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<spacer height="5" />
<svgFrame id="legend" width="800" height="500" svgWidth="800" svgHeight="500"
svgPage="EnsPortal.SVG.TraceLegend">
</svgFrame>
</pane>
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Visual Trace Legend")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit ""
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return null;
}

}
