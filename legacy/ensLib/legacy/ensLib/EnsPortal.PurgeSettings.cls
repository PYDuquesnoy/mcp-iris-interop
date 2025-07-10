/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (EnsUI, EnsUtil, Ensemble)

Class EnsPortal.PurgeSettings Extends EnsPortal.Template.standardPage [ System = 4 ]
{

Parameter PAGENAME = "Purge Data Settings";

/// User needs USE permissions on the %Ens_Purge resource to access this page.
Parameter RESOURCE = "%Ens_PurgeSettings:WRITE";

/// User needs WRITE permissions on the %Ens_PurgeSettigns resource to change the purge criteria
Parameter EDITRESOURCE = "%Ens_PurgeSettings:WRITE";

XData Style
{
<style type="text/css">
.linkTxt {
	color: #00A09A;
	font-family: "Source Sans Pro",Futura,Arial,sans-serif;
	font-size: 12px;
	font-weight: bold;
	padding-left: 4px;
	text-decoration: none;
	cursor:pointer;
}
.linkTxt:hover {
	color: #333695;
}

</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane width="100%">
<hgroup valign="top" width="100%" >
<spacer width="20" />

<vgroup id="settingsPane" width="100%" valign="top">
<hgroup width="100%">
<form id="settingsForm" containerStyle="padding-left:10px;padding-top:20px;" cellStyle="padding-top:5px;" width="100%">
<hgroup>
<label label="Purge Data Settings" labelStyle="font-size:12pt;font-weight:600"/>
<image id="info" src="portal/images/icon_info.png" width="10" height="10" valign="top" title="View documentation for the purge criteria" onclick="zenPage.showPurgeDoc();"/>
<label controlClass="linkTxt" value="Learn more..." title="View documentation for the purge criteria" onclick="zenPage.showPurgeDoc();"/>
</hgroup>
<spacer height="15"/>
<checkbox id="chkBodiesToo" caption="Include message bodies"/>
<checkbox id="chkKeepIntegrity" caption="Purge only completed sessions"/>
<spacer height="10"/>
<textarea id="txtDescription" label="Description" rows="20" controlStyle="width:99%" labelStyle="font-size:10pt;" title="Description to display in explanatory box on Purge Management Data page"/>
<spacer height="15"/>
<hgroup align="right">
<button id="btnSave" caption="Save" controlClass="commandButton" enclosingStyle="padding-bottom:10px;" onclick="zenPage.saveSettings();"/>
</hgroup> 
</form>
</hgroup>
</vgroup>
</hgroup>
</pane>
}

/// This client event, if present, is fired when the page is loaded.
/// Start the timer so we can check the status. If there is a
/// background import job currently running,
/// you will see a periodic update until the job is finished.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);

	var settings = new Array();
	settings = JSON.parse(zenPage.GetPurgeSettings());
	if (settings) {
		zen("chkBodiesToo").setValue(settings.bodiesToo);
		zen("chkKeepIntegrity").setValue(settings.keepIntegrity);
		
		zen("txtDescription").setValue(settings.description);
	}

	zenPage.adjustSizes();
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	// compare values against existing
	var same = 1;
	var settings = new Array();
	settings = JSON.parse(zenPage.GetPurgeSettings());
	if (settings) {
		same = ((zen("chkBodiesToo").getValue() == settings.bodiesToo) && (zen("chkKeepIntegrity").getValue() == settings.keepIntegrity) && (zen("txtDescription").getValue() == settings.description));
	}
	// if values have changed, confirm before closing
	this.setModified(!same);
	
	return this.invokeSuper('onunloadHandler',[]);
}

ClientMethod saveSettings() [ Language = javascript ]
{
	var msg = zenPage.DoSaveSettings();
	if (msg != "") {
		alert(msg);
	} else {
		alert($$$Text("Updated Purge Data settings saved successfully."))
		this.setModified(false);
	}
}

Method DoSaveSettings() As %String [ ZenMethod ]
{
	Set tPermitted = $system.Security.Check("%Ens_PurgeSettings", "W")
	Quit:'tPermitted $$$TextJS("You do not have permission to change the Purge Data settings.  Please contact your system administrator or go to the documentation link for more information.")  // should not happen because checked before showing page
	
	Set $$$EnsPurgeDefaults("BodiesToo") = ..%GetComponentById("chkBodiesToo").value
	Set $$$EnsPurgeDefaults("KeepIntegrity") = ..%GetComponentById("chkKeepIntegrity").value
	Set $$$EnsPurgeDescriptions = ..%GetComponentById("txtDescription").value
	
	Quit ""
}

Method GetPurgeSettings() As %String [ ZenMethod ]
{
	#dim tObj = ##class(%Library.DynamicObject).%New()
	
	Do tObj.%Set("bodiesToo",+$G($$$EnsPurgeDefaults("BodiesToo"),0))
	Do tObj.%Set("keepIntegrity",+$G($$$EnsPurgeDefaults("KeepIntegrity"),1))
	Do tObj.%Set("description",$G($$$EnsPurgeDescriptions))
	
	Quit tObj.%ToJSON()
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Purge Data Settings","Ensemble")
}

/// Show documentation for message purge.
ClientMethod showPurgeDoc() [ Language = javascript ]
{
	var win = window.open('/csp/docbook/DocBook.UI.Page.cls?KEY=EGMG_purge#EGMG_purge_basic','Docbook');
	try {
		win.focus();
	}
	catch(ex) {}
}

/// Adjust sizes of components on the page.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	try {
		zenPage.adjustSizes();
	} catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in onlayoutHandler');
	}
}

/// Adjust sizes of components on the page.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
			var setDiv = zen('settingsPane').getEnclosingDiv();

			// find size of window
			var winHeight = zenGetWindowHeight();
			var winWidth = zenGetWindowWidth();
			
			// make settings sheet visible
			setDiv.style.visibility = 'visible';

			var setWidth = Math.max(Math.min(winWidth,500),300);
			setDiv.style.width = setWidth + 'px';

			var th = this.getTitleAreaHeight();
			var scroll =  ((zenBody.scrollWidth == zenBody.offsetWidth) && (zenBody.scrollLeft == 0 )) ? 0 :1;
			var hgt = winHeight - th - 16  - 10*scroll;
			hgt = Math.max(400,hgt);

			setDiv.style.height = hgt + 'px';
			
			var descDiv = zen('txtDescription').getEnclosingDiv();
			var descHgt = (hgt-221);
			descDiv.style.height = descHgt + 'px';
			zen('txtDescription').setProperty("rows",parseInt(descHgt/16));
		
		
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in adjustSizes');
	}
}

}
