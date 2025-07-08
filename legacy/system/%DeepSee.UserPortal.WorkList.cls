/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Base class for work list classes within the DeepSee user portal.
/// A work list class provides the content of a work list pane within a User portal page.
Class %DeepSee.UserPortal.WorkList Extends %RegisteredObject [ Abstract, System = 4 ]
{

/// Set this to the correct domain.
Parameter DOMAIN = "%DeepSee";

/// Icon (16x16) to display for this work list.
Parameter ICON As STRING = "deepsee/chat_16.gif";

/// Display type: "html" or "group".
Parameter TYPE As STRING = "html";

/// Return the localized display name for this work list.
ClassMethod %GetName() As %String
{
	Quit $$$Text("Work List","%DeepSee")
}

/// Return the localized title for this work list.
ClassMethod %GetTitle() As %String
{
	Quit ..%GetName()
}

/// Return the small icon for this work list.
ClassMethod %GetIcon() As %String
{
	Quit ..#ICON
}

/// Return the display type for this work list.
ClassMethod %GetType() As %String
{
	Quit ..#TYPE
}

/// Return an optional header message to display.
ClassMethod %GetHeaderMessage() As %String
{
	Quit ""
}

/// Return an optional tool tip to display.
ClassMethod %GetToolTip() As %String
{
	Quit ..%GetTitle()
}

/// Draw the contents of the worklist.<br/>
/// <var>pPanelNo</var> is the worklist panel number.
ClassMethod %DrawWorkList(pPanelNo As %Integer) As %Status
{
	Quit $$$OK
}

}
