/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %WebStress.Portal.Home Extends %WebStress.Portal.standardPage [ System = 4 ]
{

/// 
/// Set this to the appropriate application class.
Parameter APPLICATION = "%WebStress.Portal.Application";

/// 
/// Set this to the correct domain.
Parameter DOMAIN = "%WebStress";

/// 
/// Name of this page.
Parameter PAGENAME = "Webstress Portal";

XData Style
{
<style type="text/css">



</style>
}

XData detailPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>

</pane>
}

/// 
/// Return the array of links to show in the locator bar.<br/>
/// 
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{

	// default: make *this* page the complete list

	Set tPageName = $$$ZENVAL(..title)

	Set tPageName = $P(tPageName," ",$L(tPageName," "))

	Set pLink(1) = $LB(tPageName,..Link($ZCVT(..%ClassName(1),"O","URL")_".zen?CSPSHARE=1"))

	Quit $$$OK
}

/// 
/// This class method callback is called just before the server-side page 
/// 
/// object is created.
Method %OnAfterCreatePage() As %Status
{

	Set tSC = ##super()



	Quit tSC
}

/// 
/// Get the (localized) title string for the page.
/// 
/// This should be implemented in a subclass.
Method %OnGetTitle() As %String
{
	Quit $$$Text("WebStress Portal")
}

/// This client event is fired when the a popup page launched from this page fires an action.
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	switch(popupName) {
	case 'switchNamespace':
		var url = zenPage.GetNewURL(value,"%25WebStress.Portal.Home.zen");
		// do not use this.gotoPage(url) because zenLink will not honor the latest $NAMESPACE you selected, i.e. you may end up with multiple $NAMESPACE on the URL.
		self.document.location = url;
		break;
	}
}

}
