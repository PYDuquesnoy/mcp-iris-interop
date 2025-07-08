/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// APIs used by System Management Portal
/// Methods in this class should be generic and maybe used by any ISC portals pages
/// as well as in dialogs.
Class %ZEN.Portal.Utils Extends %RegisteredObject [ Abstract, Deprecated, System = 4 ]
{

/// This method can be called to disable a button in the ribbon bar or a button with id starting with "command_".
/// Pass in button id as defined in OnGetRibbonInfo.
ClientMethod disableCommandButton(buttonName) [ Language = javascript ]
{
	var button = document.getElementById("command_"+buttonName);
	if (button == null) return;
	button.className = "commandButtonDisabled";
	button.style.cursor = "default";
	// if we haven't set anything into OnclickArray, it needs to be initialized as an Array
	if (this.OnclickArray == null) {
		this.OnclickArray = new Array();
	}
	// if we've already stored the button's value, return
	if (typeof(this.OnclickArray[buttonName]) != 'undefined') {
		button['onclick'] = null;		// DTB932 - Clear onclick for the current button before exiting here
		return;
	}
	// save the current onclick contents into the onclick array
	var onclickContents = button['onclick'];
	if (typeof(onclickContents) != "function") {
		this.OnclickArray[buttonName] = new Function(onclickContents);
	} else {
		this.OnclickArray[buttonName] = onclickContents;
	}
	button['onclick'] = null;
}

/// This method can be called to enable a button in the ribbon bar.
ClientMethod enableCommandButton(buttonName) [ Language = javascript ]
{
	var button = document.getElementById("command_"+buttonName);
	if (button == null) return;
	button.className = "commandButton";
	button.style.cursor = "pointer";
	// if the onclick array is initialized and has a value for this button, add it
	if ((this.OnclickArray != null) && (this.OnclickArray[buttonName] != undefined)) {
		button['onclick'] = this.OnclickArray[buttonName];
	}
}

/// This method can be called to hide a button in the ribbon bar.
/// Pass in button id as defined in OnGetRibbonInfo.
ClientMethod hideCommandButton(buttonName) [ Language = javascript ]
{
	var button = document.getElementById("command_"+buttonName);
	if (button == null) return;
	button.style.display = "none";
}

/// This method can be called to show a button in the ribbon bar.
ClientMethod showCommandButton(buttonName) [ Language = javascript ]
{
	var button = document.getElementById("command_"+buttonName);
	if (button == null) return;
	button.style.display = "";
}

}
