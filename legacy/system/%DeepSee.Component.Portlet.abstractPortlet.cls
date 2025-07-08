/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %DeepSee

/// Base class for DeepSee Dashboard portlets.<br/>
/// A portlet is a specialized Zen component that can be plugged into a DeepSee dashboard to
/// supply customized content.
Class %DeepSee.Component.Portlet.abstractPortlet Extends (%ZEN.Component.component, %ZEN.Component.dataView) [ System = 4 ]
{

Parameter NAMESPACE = "http://www.intersystems.com/deepsee";

/// MultiDimensional property containing the current settings values for this portlet.
Property settings As %String [ MultiDimensional ];

/// Style for the portlet
XData Style
{
<style type="text/css">

.portletDiv {
	padding: 5px;
	font-size: 25px;
}
</style>
}

/// Return the localized caption of this portlet.
/// This is displayed in the Widget Builder dialog.
/// This should be overridden in subclasses.
ClassMethod %OnGetPortletName() As %String
{
	Quit ..%ClassName(0)
}

/// Return the URL of the icon to display for this portlet.
/// This is displayed in the Widget Builder dialog.
/// This should be overridden in subclasses.
ClassMethod %OnGetPortletIcon() As %String
{
	Quit ""
}

/// Return an optional array of "settings" values for this portlet.<br/>
/// The list of settings is displayed in the Widget Builder where the user can view and
/// edit them.
/// When the portlet is rendered, the values of all settings is made available to the
/// portlet's <method>%DrawHTML</method> method via the <property>settings</property>--a
/// multidimensional array subscripted by setting name.<br/>
/// On return, <var>pInfo</var> can contain a list of settings in the form:<br/>
/// pInfo(n) = $LB(name,value,type,caption,title)<br/>
/// <var>name</var> is the logical name of the setting.<br/>
/// <var>value</var> is the default value of the setting.<br/>
/// <var>type</var> indicates the type of the setting. This determines the control
/// displayed to get the value of the setting. If omitted the type is assumed to be a string.
/// The type can be: "%Integer", "%Boolean", or "ENUM^caption1:value1,caption2:value2".<br/>
/// <var>caption</var> is the localized caption of the setting.<br/>
/// <var>title</var> is an optional tooltip displayed for the setting.<br/>
/// Custom portlet settings can be controlled using the SETTINGS=PORTLET parameter in the 
/// dashboard URL  
ClassMethod %OnGetPortletSettings(Output pInfo As %List, ByRef pSettings) As %Status
{
	// DTB111 - add pSettings to make available for user callback
	Kill pInfo
	//Set pInfo($I(pInfo)) = $LB("sample","","","Sample setting")
	Quit $$$OK
}

/// Static HTML display method: draw the BODY of this component as HTML.<br>
/// This should be overridden in subclasses.
Method %DrawHTML()
{
	&html<<div class="portletDiv">#($$$Text("This is a user-defined portlet!","%DeepSee"))#</div>>
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
