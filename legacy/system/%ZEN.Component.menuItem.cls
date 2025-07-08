/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Defines an item within a <class>menu</class>.
/// Note that the properties of this component are provided by the 
/// class <class>menuCell</class>.
Class %ZEN.Component.menuItem Extends (component, menuCell) [ Deprecated, Inheritance = right, System = 3 ]
{

Parameter DOMAIN = "%ZEN";

XData Style
{
<style type="text/css">

/* @doc="Basic menu item." */
a.menuItem {
	display: inline-block;
	color: darkblue;
	padding: 2px 3px 2px 3px;
	text-decoration: none;
	white-space: nowrap;
	vertical-align: middle;
	border: none;
	margin: 1px 1px 1px 1px;
	cursor: pointer;
}

/* @doc="Mouse over menu item." */
a.menuItem:hover {
	background: #FFFFA0;
	border: 1px darkblue dotted;
	margin: 0px 0px 0px 0px;
	cursor: pointer;
}

a.menuItem:link, a.menuItem:visited, a.menuItem:active {
}

/* @doc="Disabled menu item." */
a.menuItemDisabled {
	display: inline-block;
	color: gray;
	background: #E0E0E0;
	padding: 4px 4px 4px 4px;
	text-decoration: none;
	white-space: nowrap;
	vertical-align: middle;
	border: none;
	margin: 0px 0px 0px 0px;
}

a.menuItemDisabled:hover,a.menuItemDisabled:active,a.menuItemDisabled:link, a.menuItemDisabled:visited {
}

/* active menu item: this is used for top-level items
	when their submenu is displayed.
*/
a.menuItemActive {
	display: inline-block;
	color: darkblue;
	padding: 2px 3px 2px 3px;
	text-decoration: none;
	white-space: nowrap;
	vertical-align: middle;
	background: #FFFFA0;
	border: 1px darkblue dotted;
	margin: 0px 0px 0px 0px;
	cursor: pointer;
}

a.menuItemActive:hover,a.menuItemActive:active,a.menuItemActive:link, a.menuItemActive:visited {
}

</style>
}

Method %DrawHTML()
{
	// dispatch to inherited helper method
	Do ..%DrawMenuCell(0)
}

/// Client-side method to get the disabled state of this menuItem.
ClientMethod getDisabled() As %Boolean [ Final, Language = javascript ]
{
	return this.disabled;
}

/// Client-side method to set disabled state of this menuItem.
ClientMethod setDisabled(flag) [ Final, Language = javascript ]
{
	this.disabled = flag ? true : false;
	var a = this.findElement("a");
	zenASSERT(a,"Unable to find anchor element",arguments);
	
	if (this.disabled) {
		a.className = "menuItemDisabled";
		a.disabled = true;
		a.href = "#";
		if (zenIsIE) {
			a["onclick"]=new Function("");
		}
		else a.setAttribute("onclick","");
	}
	else {
		a.className = "menuItem";
		a.disabled = false;
		a.href = this.secureLink;
		if (zenIsIE) {
			a["onclick"] = new Function(this.secureCallback);
		}
		else a.setAttribute("onclick",this.secureCallback);
	}
}

/// This callback is invoked just before this menuItem 
/// fires its action.
ClientMethod onActionHandler() [ Language = javascript ]
{
	// notify parent menu
	if (this.parent.onItemActionHandler) {
		this.parent.onItemActionHandler(1);
	}
}

/// This callback is invoked when the mouse moves over (true)
/// or out of (false) this menu item.
ClientMethod onShowHelpHandler(mode) [ Language = javascript ]
{
	// notify parent menu
	if (this.parent.onItemShowHelpHandler) {
		this.parent.onItemShowHelpHandler(mode,this);
	}
}

/// No-op used for disabled links.
ClientMethod doNothing() [ Final, Language = javascript ]
{
}

}
