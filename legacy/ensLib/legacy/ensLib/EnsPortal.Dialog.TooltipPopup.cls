/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This very simple dialog allows us to pop up a term definition with the KEY= value being the term
/// and a value stored in the parent class property _helpText being the HTML-formatted definition text.
Class EnsPortal.Dialog.TooltipPopup Extends EnsPortal.Dialog.standardDialog [ System = 4 ]
{

/// User needs USE permissions on the %Ens_Portal resource to view this page.
Parameter RESOURCE = "%Ens_Portal:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Tooltip Popup";

/// If true, then this dialog displays an Apply button.
Parameter APPLYBUTTON As BOOLEAN = 0;

/// If true, then this dialog displays a Cancel button.
Parameter CANCELBUTTON As BOOLEAN = 0;

/// If true, then this dialog displays an OK button.
Parameter OKBUTTON As BOOLEAN = 0;

Property key As %ZEN.Datatype.string(ZENURL = "KEY");

Property localizedName As %ZEN.Datatype.string(ZENURL = "LOCALIZEDNAME");

XData Style
{
<style type="text/css">
body {
	margin: 0px;
	font-family: verdana;
}

div.title {
	width: 95%;
	font-size: 0.8em;
	font-weight: bold;
	padding-top: 10px;
	padding-left: 10px;
	padding-right: 10px;
}

div.text	{
	font-size: 0.8em; 
	padding-left: 10px;
	padding-right: 10px;
}

div.text:first-letter {
	font-size: 1.0em;
}

</style>
}

/// This XML block defines the contents of this pane.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" cellStyle="padding-bottom:8px;">
<spacer height="10" />
<html id="helpText">
</html>
</pane>
}

ClientMethod getDialogValue() [ Language = javascript ]
{
	return "";
}

/// Get the (localized) title string for the dialog.
Method %OnGetTitle() As %String
{
	Quit $zconvert(..localizedName,"O","HTML")
}

/// Get the (localized) subtitle string for the dialog.
Method %OnGetSubtitle() As %String
{
	If ..key=..localizedName Quit ""
	Quit "( "_$zconvert(..key,"O","HTML")_" )"
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	// fill the help text component with content saved in the _helpText property by the parent window (EnsPortal.ProductionConfig)
	var help = zen("helpText"); 
	var text = '';
	var opener = this.getOpener();
	if (opener && opener.zenPage && opener.zenPage._helpText) text = unescape(opener.zenPage._helpText);
	help.content = '<div class="text">' + text + '</div>';
	help.refreshContents();
}

}
