/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Base class for DeepSee Control Panel Widget.<br/>
/// A control panel is a specialized widget that can be plugged into a DeepSee dashboard to
/// hold controls only.
Class %DeepSee.Component.Widget.abstractControlPanel Extends (%ZEN.Component.component, %ZEN.Component.dataView) [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// MultiDimensional property containing the current settings values for this panel.
Property settings As %String [ MultiDimensional ];

/// Style for the panel
XData Style
{
<style type="text/css">

.panelDiv {
	padding: 5px;
	font-size: 25px;
}
</style>
}

/// Return the localized caption of this panel.
/// This is displayed in the Widget Builder dialog.
/// This should be overridden in subclasses.
ClassMethod %OnGetPanelName() As %String
{
	Quit ..%ClassName(0)
}

/// Return the URL of the icon to display for this panel.
/// This is displayed in the Widget Builder dialog.
/// This should be overridden in subclasses.
ClassMethod %OnGetPanelIcon() As %String
{
	Quit ""
}

/// Static HTML display method: draw the BODY of this component as HTML.<br>
/// This should be overridden in subclasses.
Method %DrawHTML()
{
	&html<<div class="panelDiv">#($$$Text("This is a controlPanel!","%DeepSee"))#</div>>
}

/// Notification from the containing widget that the page is loaded or the widget is resized.
/// Subclass can implement this, if they wish.
ClientMethod adjustContentSize(load, width, height) [ Abstract, Language = javascript ]
{
}

/// Notification that a filter has changed.
/// Subclass can implement this, if they wish.<br/>
/// <var>refresh</var> inidicates if the display should be refreshed.<br/>
/// <var>widget</var> is the containing widget object.<br/>
ClientMethod onApplyFilters(refresh, widget) [ Abstract, Language = javascript ]
{
}

}
