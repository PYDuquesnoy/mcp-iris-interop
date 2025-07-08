/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A specialized group that defines a tab within a <class>%ZEN.Component.tabGroup</class>.
Class %ZEN.Component.tab Extends group [ Deprecated, System = 3 ]
{

Parameter DEFAULTLAYOUT = "vertical";

/// Caption displayed for this tab within the tabGroup tab bar (if displayed).<br>
/// This is a localized value.
Property caption As %ZEN.Datatype.caption;

/// (Optional) If defined, then the tab displayed within the tabGroup bar
/// will become a link referring to this value. No link is displayed for the current tab.
Property link As %ZEN.Datatype.uri(ZENEXPRESSION = 1);

/// (Optional) If specified, user must hold this resource or this item is disabled.
/// Note this merely disables this option; to prevent this component from being
/// served to the client, used the <property>%resource</property> property.
Property tabResource As %ZEN.Datatype.resource;

/// Server-side method: Make this tab the current tab within its parent tabGroup.
Method %Activate()
{
	If ($IsObject(..parent) && ..parent.%IsA("%ZEN.Component.tabGroup")) {
		Do ..parent.%SetCurrTab($this)
	}
}

/// Make this tab the current tab within its parent tabGroup.
ClientMethod activate() [ Language = javascript ]
{
	if (this.parent.getTabIndex) {
		this.parent.showTab(this.parent.getTabIndex(this));
		return true;
	}

	return false;
}

/// Client-side method that is called when a group's disabled
/// state changes. This gives subclasses a chance to update their
/// style when they are enabled/disabled.
ClientMethod ondisabledHandler() [ Language = javascript ]
{
	// notify our parent so that it can change tab display
	if (this.parent.tabDisabledHandler) {
		this.parent.tabDisabledHandler(this);
	}
}

}
