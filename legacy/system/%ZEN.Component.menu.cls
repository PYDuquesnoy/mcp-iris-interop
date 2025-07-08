/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized group for defining menus.
Class %ZEN.Component.menu Extends (group, menuCell) [ Deprecated, Inheritance = right, System = 3 ]
{

Parameter DEFAULTLAYOUT = "horizontal";

Parameter DEFAULTGROUPCLASS = "menuTable";

/// onactivate event handler:
/// If this menu is a submenu, then this event is fired just
/// before the submenu is made visible.
Property onactivate As %ZEN.Datatype.eventHandler;

/// onshowHelp event handler:
/// This event is fired when the user moves the mouse over this
/// menu item.
Property onshowHelp As %ZEN.Datatype.eventHandler;

/// Internal property used to keep track of state on client
Property subMenuActive As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Internal property used to indicate if this is a submenu
/// and, if so, how many level deep.
Property subMenuLevel As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0 ];

/// Specifies how components within this group should be layed out. (VALUELIST = ",vertical,horizontal")
Property layout As %ZEN.Datatype.string(MAXLEN = 250, ZENENCRYPT = 0) [ InitialExpression = {..#DEFAULTLAYOUT} ];

XData Style
{
<style type="text/css">
/* @doc="Table used for menus." */
.menuTable {
	border: 1px solid darkblue;
	font-family: verdana;
	padding: 0px;
	background: white;
	cursor: pointer;
}

/* @doc="Table used for sub-menus." */
.submenu {
	background: white;
	cursor: pointer;
}

</style>
}

Method %DrawHTML()
{
	Set tVertical = 1

	#; see if we are a submenu
	If ($IsObject(..parent) && ..parent.%IsA("%ZEN.Component.menu")) {
		Set ..subMenuLevel = 1
		Set tVertical = (..parent.layout = "vertical")
		
		#; test for nested submenus
		If (..parent.subMenuLevel > 1) {
			#; 4th level menu not supported
			Set ..caption = ..caption _ " (4-level submenus not allowed)"
			Set ..disabled = 1
			Do ..%DrawMenuCell(0)
			Quit
		}
		ElseIf (..parent.subMenuLevel > 0) {
			Set ..subMenuLevel = ..parent.subMenuLevel + 1
		}
	}

	If (..subMenuLevel > 0) {
		#; draw menuItem to display submenu header
		#; dispatch to inherited helper method
		#; but first, adjust properties
	
		Set ..onclick = "zenPage.getComponent("_..index_").showSubMenu();"

		#; draw menu item; always show arrow, see pl 84572
		Do ..%DrawMenuCell(1)

		#; wrap submenu in extra div
		&html<<div id="#(..%MakeId("submenu"))#" class="submenu" style="display: none;">>
	}

	#; dispatch to super class to layout children
	Do ##super()

	If (..subMenuLevel > 0) {
		&html<</div>>
	}
}

/// Display the submenu.
ClientMethod showSubMenu() [ Language = javascript ]
{
	var hdr = this.findElement('a');
	if (null == hdr) {
		// assume we are not a submenu
		return;
	}
	zenASSERT(hdr,"Unable to find anchor div.",arguments);

	if (this.subMenuActive) {
		return;
	}

	// invoke onactivate callback, if present
	zenInvokeCallbackMethod(this.onactivate,this,'onactivate');

	// set active flag
	this.subMenuActive = true;

	// mark *this* menuItem to show source of submenu
	hdr.className = 'menuItemActive';

	// make submenu appear as modal element
	zenPage.startModal(this);
}

/// Notification that this component is about to become modal.
ClientMethod onStartModalHandler(zindex) [ Language = javascript ]
{
	var trap = self.document.getElementById("zenMouseTrap");
	if (zenASSERT(trap,"Unable to find zenMouseTrap div.",arguments)) { return; }

	var hdr = this.findElement('a');
	zenASSERT(hdr,"Unable to find anchor div.",arguments);

	var submenuDiv = this.findElement('submenu');
	zenASSERT(submenuDiv,"Unable to find submenu div.",arguments);

	// determine orientation of menu
	var vertical = true;
	if (1==this.subMenuLevel && this.parent.layout && this.parent.layout == 'horizontal') {
		vertical = false;
	}

	// find position of header <a> element
	var top,right;
	if (vertical) {
		var top = zenGetTop(hdr);
		var right = zenGetLeft(hdr) + hdr.offsetWidth;
	}
	else {
		var top = zenGetTop(hdr) + hdr.offsetHeight;
		var right = zenGetLeft(hdr);
	}

	// make submenu visible; place it to our right
	var submenu = submenuDiv;

	if (2 == this.subMenuLevel) {
		// if this is a sub-sub menu copy our contents
		// into the page-wide modal div!
		var div = self.document.getElementById('zenModalDiv');
		div.innerHTML = submenuDiv.innerHTML;
		submenu = div;
	}

	submenu.style.position = 'absolute';
	submenu.style.top = top + "px";
	submenu.style.left = right + "px";
	submenu.style.display = '';

	// make sure submenu is placed above mouse trap
	this.getEnclosingDiv().style.zIndex = zindex;
	hdr.style.zIndex = zindex+1;
	submenu.style.zIndex = zindex+1;
	document.body.appendChild(submenu);
	this.activeSubmenu=submenu;
	zenPage.correctIELayering(submenu);
}

/// Notification that this component is about to stop being modal.
ClientMethod onEndModalHandler(zindex) [ Language = javascript ]
{
	var hdr = this.findElement('a');
	zenASSERT(hdr,"Unable to find anchor div.",arguments);

	if (2 == this.subMenuLevel) {
		var submenu = self.document.getElementById('zenModalDiv');
	}
	else {
		var submenu = this.findElement('submenu');
	}
	zenASSERT(submenu,"Unable to find submenu div.",arguments);

	// unmark *this* menuItem
	hdr.className = 'menuItem';

	// hide sub menu
	submenu.style.display = 'none';
	this.getEnclosingDiv().appendChild(submenu); 
	this.activeSubmenu=null;
	
	// reset active flag
	this.subMenuActive = false;
}

/// This callback is invoked just before this menu
/// (acting as a menuItem) fires its action.
ClientMethod onActionHandler() [ Language = javascript ]
{
	// in this case we are displaying a submenu
	// so do nothing here.
}

/// This callback is invoked just after a menuItem within this
/// menu fires its action.
/// <var>depth</var> indicated how many submenu levels down this
/// event originated. If 1, then it came from *this* menu.
ClientMethod onItemActionHandler(depth) [ Language = javascript ]
{
	// dismiss this menu if called by submenu
	if (depth > 1) {
		zenPage.endModal();
	}

	// notify parent menu
	if (this.parent.onItemActionHandler) {
		this.parent.onItemActionHandler(depth+1);
	}
}

/// This callback is invoked when the mouse moves over (true)
/// or out of (false) this menu item.
ClientMethod onShowHelpHandler(mode) [ Language = javascript ]
{
}

ClientMethod onItemShowHelpHandler(mode, item) [ Language = javascript ]
{
	// notify parent menu
	if (this.parent.onItemShowHelpHandler) {
		this.parent.onItemShowHelpHandler(mode,item);
	}
	else {
		// we *are* the parent: handle the event
		if (mode) {
			zenInvokeCallbackMethod(this.onshowHelp, this, 'onshowHelp', 'help',item.help);
		}
		else {
			// clear
			zenInvokeCallbackMethod(this.onshowHelp, this, 'onshowHelp', 'help','');
		}
	}
}

}
