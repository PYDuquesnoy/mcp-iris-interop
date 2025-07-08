/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This utility dialog window displays and lets the user select from a set of available namespaces.<br/>
Class %ZEN.Dialog.namespaceSelect Extends %CSP.Portal.standardDialog [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

/// No Apply button.
Parameter APPLYBUTTON = 0;

/// User must hold at least operator privilege to use this dialog.
/// !!! this list should be longer
Parameter RESOURCE = "%Admin_Operate,%Development,%Service_SQL,%Ens_Portal,%DeepSee_Architect,%DeepSee_Analyzer,%DeepSee_Portal,%DeepSee_Admin";

/// Pass in current namespace.
Property CurrNamespace As %String(ZENURL = "CURRNS");

XData Style
{
<style type="text/css">
#desc {
	font-size: 10pt;
	color: #606060;
}

</style>
}

/// Contents of the dialog.
XData dialogBody [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<vgroup labelPosition="top" cellStyle="padding:5px;">
<listBox id="lstBox" onkeydown="return zenPage.listKeyDown(evt);"
	label="Available Namespaces" listWidth="400px" listHeight="200px" ondblclick="zenPage.dialogFinish();">
</listBox>
<html id="desc" OnDrawContent="%GetDescHTML"/>
</vgroup>
</pane>
}

/// Provide contents of description component.
Method %GetDescHTML(pSeed As %String) As %Status
{
	Write $$$TextHTML("If a namespace exists but is not listed, then you may not hold permission to view it, or its database may not be mounted.")
	Quit $$$OK
}

/// Get the (localized) title string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$TextHTML("Namespace Chooser")
}

/// Get the (localized) subtitle string for the dialog.
/// This should be implemented in a subclass.
Method %OnGetSubtitle() As %String
{
	Quit $$$TextHTML("Select a namespace")
}

/// User clicked Finish. Attampt change namespace. If fails, display error message and do not leave dialog.
ClientMethod ondialogFinish() As %Boolean [ Language = javascript ]
{
	try {
		var val = zen("lstBox").getValue();
		var canSwitchTo = this.ChangeNS(val);
		if (canSwitchTo == 1) return true;
		else alert(canSwitchTo);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments);
	}
	return false;
}

/// Return the value that should be returned by this dialog.
ClientMethod getDialogValue() [ Language = javascript ]
{
	var val = zen("lstBox").getValue();	
	return encodeURIComponent(val);
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tCombo = ..%GetComponentById("lstBox")
	Set tSC = ##class(%CSP.Portal.Utils).%GetNamespaceList(.NspList)
	If $$$ISERR(tSC) Quit tSC
	Set tNamespace = $O(NspList(""))
	Set tDisabled = ""
	While tNamespace '= "" {
		Set tEnabled = $lg(NspList(tNamespace),1)
		If tEnabled = 1 {
			#;YSD2618 If $system.CSP.GetDefaultApp(tNamespace) '= "" {
			If $system.CSP.GetPortalApp(tNamespace,"%ZEN.Dialog.namespaceSelect.cls") '= "" {	
				Set tOption = ##class(%ZEN.Auxiliary.option).%New()
				Do tCombo.options.Insert(tOption)
				Do ..%AddComponent(tOption)
				Set tOption.text = tNamespace
				Set tOption.value = tNamespace
			}
		} Else {
			Set tDisabled = tDisabled _ $S(tDisabled'="":", ",1:"")_tNamespace
		}
		Set tNamespace = $O(NspList(tNamespace))
	}

	Set:..CurrNamespace="" ..CurrNamespace = $namespace
	Set tCombo.value = ..CurrNamespace
	
	Quit $$$OK
}

/// Adjust size and position of components on this page.
ClientMethod adjustSize() [ Language = javascript ]
{
	this.invokeSuper('adjustSize',arguments);

	var body = zenPage.getComponentById('body');
	var list = zenPage.getComponentById('lstBox');
	var desc = zenPage.getComponentById('desc');

	var bw = body.getEnclosingDiv().offsetWidth;
	var bh = body.getEnclosingDiv().offsetHeight - desc.getEnclosingDiv().offsetHeight;

	list.setProperty('listWidth', bw - 40);
	list.setProperty('listHeight', bh - 60);
}

/// This callback, if defined, is called when the dialog page is loaded.
ClientMethod ondialogStart() [ Language = javascript ]
{
	var list = zenPage.getComponentById('lstBox');
	list.focus();
}

/// Key handler for list box.
ClientMethod listKeyDown(evt) [ Language = javascript ]
{
	switch(evt.keyCode) {
	case zenENTER:
		this.dialogFinish();
		break;
	case zenESC:
		this.dialogCancel();
		break;
	}
	return true;
}

/// Attempt to change namespace. If fails, then some thing unusual is there about this namespace.
ClassMethod ChangeNS(pNS As %String) As %String [ ZenMethod ]
{
	Set tSC = $$$OK
	Set tOldNS = $namespace
	Set $ZT = "Trap"
	If tOldNS '= pNS {
		#; Change namespace now
		Set $namespace = pNS
		#; This call returns 0 (success) or 453
		Set tSC = ##class(%SQL.Manager.API).SetServerInitCode()
		Set tSC = $S(tSC=0:$$$OK,1:$$$Text("Error in user initialization code."))
	}
	Quit tSC
Trap
	Set $ZT=""
	Set $namespace = tOldNS
	If $ZE [ "<PROTECT>" Quit $$$Text("Unable to switch to this namespace. Either the default database is not mounted, or you do not have permission to access it.","%Utility")
	Quit $ZCVT($ZE,"O","JS")
}

}
