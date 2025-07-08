/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A work list class that displays details on the selected item within a User portal page.
Class %DeepSee.UserPortal.DetailsList Extends %DeepSee.UserPortal.WorkList [ System = 4 ]
{

/// Icon (16x16) to display for this work list.
Parameter ICON = "deepsee/ds2_info_44.png";

/// Return the localized display name for this work list.
ClassMethod %GetName() As %String
{
	Quit $$$Text("Details","%DeepSee")
}

/// Return the localized title for this work list.
ClassMethod %GetTitle() As %String
{
	Quit $$$Text("Details","%DeepSee")
}

/// Return an optional tool tip to display.
ClassMethod %GetToolTip() As %String
{
	Quit $$$Text("Show details on the selected item","%DeepSee")
}

/// Draw the contents of the worklist.<br/>
/// <var>pPanelNo</var> is the worklist panel number.
ClassMethod %DrawWorkList(pPanelNo As %Integer) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tMsg = $$$TextHTML("Show details for selected item","%DeepSee")
		&html<<div id="worklist#(pPanelNo)#" class="worklist">>
		&html<<div id="details#(pPanelNo)#"><div class="detailLabel">#(tMsg)#</div></div>>
		&html<</div>>
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
