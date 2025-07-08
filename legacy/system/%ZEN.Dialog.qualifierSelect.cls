/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This utility dialog window displays and lets the user select 
/// from a set of qualifiers.<br>
/// Displays Export or Compile qualifiers and allow user to select multiple.
Class %ZEN.Dialog.qualifierSelect Extends standardDialog [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

/// No Apply button.
Parameter APPLYBUTTON = 0;

/// Type of group to select ("Export" or "Compiler"). Passed in via URL.
Property group As %ZEN.Datatype.string(ZENURL = "group");

/// Default qualifiers used when checkboxes are built (if null, system default will be used). Passed in via URL.
Property qspec As %ZEN.Datatype.string(ZENURL = "qspec");

/// Total Items of the qualifiers. Updated at the end of checkboxes building.
Property TotalItems As %ZEN.Datatype.string;

XData Style
{
<style type="text/css">
</style>
}

/// Contents of the dialog.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<vgroup labelPosition="left" cellStyle="padding:2px; padding-left: 5px; padding-right: 5px;">
<form id="form">
<text id="HelpLink" hidden="true"/>
<hgroup>
<html id="desc" OnDrawContent="%GetDescHTML"/>
<spacer width="20"/>
<link id="linkHelp" caption="Click here for Help" enclosingStyle="font-size:10px;" href="javascript:zenPage.openHelp();"/>
<spacer width="20"/>
<link id="linkRestore" caption="Restore Defaults" enclosingStyle="font-size:10px;" href="javascript:zenPage.restoreDefault();"/>
</hgroup>
<html id="items" label="Select Qualifiers:" OnDrawContent="DrawItems" seed=""/>
</form>
</vgroup>
</pane>
}

/// Get the selected values for this dialog. Return value does not include comma at the beginning and the end.
ClientMethod getDialogValue() [ Language = javascript ]
{
	try {
		var state = '';
		var numRows = zenPage.TotalItems;
		var cb;
		for (var i = 1; i <= numRows; i++) {
			cb = self.document.getElementById("cb_"+i);
			if (cb && cb.checked) {
				if (state != '') state += ',';
				state += cb.value;
			}
		}
		return state;
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
}

/// Open documentation for qualifiers
ClientMethod openHelp() [ Language = javascript ]
{
	var url = zenPage.getComponentById("HelpLink").getValue();	
	zenLaunchPopupWindow(url,'qualifierHelp','status,scrollbars,resizable,width=1000,height=1000');
}

/// Restore default 
ClientMethod restoreDefault() [ Language = javascript ]
{
	var html = zenPage.getComponentById("items");
	html.setProperty("seed","Export");
	html.refreshContents();
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("Qualifier Group: ")
	If (..group = "Export") {
		Write "<b>",$$$TextHTML("Export"),"</b>"
	} ElseIf (..group = "Complier") {
		Write "<b>",$$$TextHTML("Complier"),"</b>"
	} Else {
		Write "<i>",..EscapeHTML(..group),"</i>"
	}
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Qualifier Selection Dialog")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Select items from the list below.")
}

/// Load default values
Method %OnAfterCreatePage() As %Status
{
	Set tLink = "KEY=AMISC#AMISC_Qualifiers_"_..group
	Set ..%GetComponentById("HelpLink").value = ##class(%CSP.Page).Link("/csp/docbook/DocBook.UI.Page.cls",,1)_tLink
	Quit $$$OK
}

/// Draw Qualifiers. If seed is null, use qspec passed in. Else use default.
Method DrawItems(seed As %String) As %Status
{
	If seed = "" Set tSelected = ..qspec
	Else  Set tSelected = ""
	Set group = ..group
	If group = "" Set group = "Export"
	Set qname="" 
	Set qname=$o($$$QUALIFIER(group,qname))
	Set ind = 0
	While qname '= "" {
		Set type = $$$QUALIFIERtype(group,qname)
		If type '= "alias" {
			Set ind = ind + 1
			Set id = "cb_"_ind
			Set tname = "/"_qname
			If tSelected '= "" Set tdefault = tSelected[tname
			Else  Set tdefault = $$$QUALIFIERdefaultvalue(group,qname)
			&html<<input type="checkbox" id="#(id)#" value="#(tname)#" #($S(tdefault=1:"checked",1:""))#>#($ZCVT(tname,"O","HTML"))#<br>>
		}
		Set qname=$o($$$QUALIFIER(group,qname))	
	}
	Set %page.TotalItems = ind
	Quit $$$OK
}

}
