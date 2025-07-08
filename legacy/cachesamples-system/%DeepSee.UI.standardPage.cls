/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%DeepSee, %products)

/// Base class for all DeepSee UI pages.
/// This is mainly for the purpose of setting common parameters for DeepSee.
Class %DeepSee.UI.standardPage Extends (%ZEN.Portal.standardPage, %ZEN.Portal.Utils) [ Abstract, System = 4 ]
{

Parameter JSINCLUDES = "zenCSLM.js,zenESVG.js,DeepSee.js";

Parameter DOMAIN = "%DeepSee";

/// All Analytics pages require %DeepSee_Portal USE.
Parameter RESOURCE = "%DeepSee_Portal,%DeepSee_PortalEdit";

/// favorite icon.
Parameter FAVORITEICON = "portal/ISC_IRIS_icon.ico";

/// Docbook ID for this page.
Parameter DOCBOOKID;

Property docbookId As %String [ InitialExpression = {..#DOCBOOKID} ];

Property metaData As %String [ InitialExpression = {..%GetMetaData()} ];

XData Style
{
<style type="text/css">
/*
@font-face {
  font-family: 'Electrolize';
  font-style: normal;
  font-weight: 400;
  src: local('Electrolize'), local('Electrolize-Regular'), url(deepsee/electrolize.woff) format('woff');
}

.portalLogo {
	font-family: 'Electrolize', arial;
	text-shadow: 1px 1px 1px #A0A0D0;
}
*/
.comboboxTable td {
	padding-left: 3px;
}
</style>
}

/// Return a serialized JSON array which contains information the client needs to send REST calls to the server
ClassMethod %GetMetaData() As %String [ Internal ]
{
	// [ns]
	Set metaArray = []
	Do metaArray.%Push($Namespace)
	Quit metaArray.%ToJSON()
}

/// Clientside fetch of information the client needs to send REST calls to the server, returned as an array.
ClientMethod getPageMeta() [ Language = javascript ]
{
	return JSON.parse(zenPage.metaData);
}

/// Override.
ClientMethod showHelp() [ Language = javascript ]
{
	var id = (this.docbookId=='') ? 'Home' : this.docbookId;
	var url = "/csp/docbook/DocBook.UI.Page.cls";
	var wid = self.screen.width;
	var hgt = self.screen.height;
	if (parseInt(navigator.appVersion)>3) {
		if (navigator.appName == "Netscape") {
			wid = window.innerWidth;
			hgt = window.innerHeight;
		}
		if (navigator.appName.indexOf("Microsoft") != -1) {
	 		wid = document.body.offsetWidth;
	 		hgt = document.body.offsetHeight;
		}
	}
	wid = wid * 0.8;
	hgt = hgt * 0.8;
	var top = self.screen.height * 0.1;
	var left = self.screen.width * 0.1;
	var features = 'left='+left+',top='+top+',width='+wid+',height='+hgt+',status,scrollbars,resizable,location=1,toolbar=1,menubar=1';
	// id may iniclude "#" so it needs to be added after ..Link
	url = this.GetCSPURL(url) + "&KEY=" + id;
	var popup = window.open(url,'HelpWindow',features);
	popup.focus();
	return false;
}

/// Set the modified flag for the page.
ClientMethod setModified(flag) [ Language = javascript ]
{
	this.pageModified = flag;
	if (document.getElementById("modifiedIndicator")) {
		document.getElementById("modifiedIndicator").innerHTML = (flag==true) ? "*" : "";
	}
}

/// Check if user really wants to exit if they have not saved changes
ClientMethod onunloadHandler() [ Language = javascript ]
{
	if (this.pageModified == true) {
		return $$$Text('Changes have not been saved permanently. If you navigate to a new page these changes will be lost!');
	}
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)	
	Set tPageName = ..%OnGetPageName()
	Set pLink($I(pLink)) = $LB(tPageName,$ZCVT($className(),"O","URL")_".zen")
	Quit $$$OK
}

Method %GetRootLink(Output pLink) As %Status
{
	Set tPageName = $$$PRODUCT1
	Set pLink($I(pLink)) = $LB(tPageName,..homePage)
}

/// Show dialog to switch namespace
ClientMethod switchNamespace() As %String [ Language = javascript ]
{
	zenLaunchPopupWindow('%DeepSee.UI.Dialog.namespaceSelect.cls','switchNamespace','status,scrollbars,resizable=yes,width=500,height=500,location=no');
}

ClientMethod reloadPage() [ Language = javascript ]
{
	// Reload this page in an IE-friendly way!
	// Method added by DTB646
	try {
		self.document.location.reload();
	}
	catch (ex) {
		// ignore
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// DTB845 - Provide a template for child pages to override
	this.invokeSuper('onloadHandler');
	
	// When overriding this in a subclass, all custom page code should begin here, leaving the 
	// call to the superclass in place.
}

}
