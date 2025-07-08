/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %products

Class %iKnow.UI.standardPage Extends (%ZEN.Portal.standardPage, %ZEN.Portal.Utils) [ Abstract, Deprecated, System = 4 ]
{

Parameter DOMAIN = "%DeepSee";

/// All DeepSee pages require %DeepSee_Portal USE.
Parameter RESOURCE = "%DeepSee_Portal";

/// DeepSee favorite icon.
Parameter FAVORITEICON = "portal/ISC_IRIS_icon.ico";

/// Docbook ID for this page.
Parameter DOCBOOKID;

Property docbookId As %String [ InitialExpression = {..#DOCBOOKID} ];

XData Style
{
<style type="text/css">
/* SMP reskin
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

	Set tPageName = $$$PRODUCT5
	Set pLink($I(pLink)) = $LB(tPageName,..homePage)
}

/// Show dialog to switch namespace
ClientMethod switchNamespace() As %String [ Language = javascript ]
{
	zenLaunchPopupWindow('%iKnow.UI.Dialog.selectNamespace.cls','switchNamespace','status,scrollbars,resizable=yes,width=500,height=500,location=no');
}

}
