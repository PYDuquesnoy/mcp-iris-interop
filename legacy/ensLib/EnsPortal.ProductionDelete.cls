/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsConstants, EnsUI)

/// StartProduction
Class EnsPortal.ProductionDelete Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// User needs WRITE permissions on the %Ens_ProductionConfig resource to view this page.
Parameter RESOURCE = "%Ens_ProductionConfig:WRITE";

/// Displayed name of this page.
Parameter PAGENAME = "Production Delete";

Parameter CSSINCLUDES = "ensemble/Ensemble_Wizards.css";

XData Style
{
<style type="text/css">
</style>
}

/// This XML block defines the contents of the page.
XData contentPane
{
<pane>
<spacer height="20" />
<hgroup>
<spacer width="20" />
<vgroup enclosingClass="wizardBox" >
<form id="form" align="center">
<vgroup labelPosition="left">
<spacer height="20" />
<dataCombo id="TargetName" name="TargetName" labelClass="labelRequired" 
	size="40" label="Production Name" title="Choose a production name from the list. If a production is Running or Suspended, you can choose it, but IRIS will not delete a production unless it is Stopped."
	displayColumns="1" valueColumn="1" choiceColumn="1" 
	queryClass="Ens.Config.Production" queryName="ProductionStatus" maxRows="1000" 
	 />
<!--
 ... suggestion: use a selector instead of dataCombo
<selector id="TargetName" name="TargetName" labelClass="labelRequired" 
 ... what else?
 />
-->
<spacer height="20" />
</vgroup>
<hgroup align="center">
 <button name="Details" id="Details" caption="Details" controlClass="commandButton" 
        title="After you have selected a production, click this button to pop up a window where you can view the production's configuration details. This can help you to confirm whether or not you want to delete this production."
          onclick="zenPage.btnView();" />
 <spacer width="10"/>
 <button name="OK" id="OK" caption=" OK " controlClass="commandButton" onclick="zenPage.btnOK();" 
	 	 title="Remove the production and all of its configured settings. The underlying classes for business hosts, business rules, routing rules, and data transformations will remain." />
 <spacer width="10"/>
 <button name="Cancel" id="Cancel" caption="Cancel" controlClass="commandButton" onclick="zenPage.gotoPage(zenPage.GetHomePage());"  
		 title="Cancel this operation and return to the IRIS home page." />
</hgroup>
</form>
</vgroup>
<spacer width="20" />
<vgroup valign="top">
<spacer height="40" />
<label id="helpSubject" enclosingClass="labelComment" value="Use this form to permanently delete a production. You cannot undo this operation." />
<spacer height="10" />
<label id="helpHover" enclosingClass="labelComment" value="For help with any item in this form, hover the cursor over the item." />
</vgroup>
</hgroup>
</pane>
}

/// View the configuration diagram for the specifed production.
ClientMethod btnView() [ Language = javascript ]
{
	var target = zen('TargetName');
	var name = target.getValue();
	if ((name) && (name != '')) {
		url = zenLink('EnsPortal.ProductionConfig.zen?PRODUCTION=' + encodeURIComponent(name));				
		zenLaunchPopupWindow(url);
	} 
	else {
		alert(zenText('msgProdDeleteSelect'));
	}
	return true;
}

/// Attempt to delete the specifed production.
ClientMethod btnOK() [ Language = javascript ]
{
	var target = zen('TargetName');
	var name = target.getValue();
	if (name == '') {
		alert(zenText('msgProdDeleteSelect'));
		return false;
	}
	if (confirm(zenText('msgProdDeleteConfirm',name))) {
		if (zenPage.DeleteProductionJS(name) == 0) {
			 alert(zenText('msgProdDeleteNo'));
		}
		else {
			 alert(zenText('msgProdDeleteYes'));
		}
		self.document.location = zenPage.GetHomePage();
	}
	return true;
}

Method %OnGetJSResources(ByRef pResources As %String) As %Status [ Private ]
{
  Set pResources("msgProdDeleteSelect") = $$$TextJS("Please choose a production.")
  Set pResources("msgProdDeleteConfirm") = $$$TextJS("Do you really wish to delete production %1? You cannot undo this operation.")
  Set pResources("msgProdDeleteYes") = $$$TextJS("Production successfully deleted.")
  Set pResources("msgProdDeleteNo") = $$$TextJS("Could not delete production. Production may be running or not fully stopped.")
  Quit $$$OK
}

/// This method deletes the specified production and returns a status that JavaScript can understand.
Method DeleteProductionJS(pProdId As %String) As %Boolean [ ZenMethod ]
{
	// Returning a boolean is similar to (System.AuditSearchPane).ValidateDateTime 
	// which also must return a value to JavaScript
	
	Quit $$$ISOK(##class(Ens.Director).DeleteProduction(pProdId))
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Production Delete","Ensemble")
}

/// Get information to display in the ribbon bar.
/// Make appropriate choices for Production Delete. 
Method OnGetRibbonInfo(Output pDisplay As %Boolean, Output pViewIcons As %List, Output pSortOptions As %List, Output pSearchBox As %Boolean, Output pRibbonTitle As %String) As %Status
{
	Quit $$$OK
}

}
