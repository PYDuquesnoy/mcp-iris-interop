/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.PubSub.PageContainer Extends EnsPortal.Template.standardPage [ System = 4 ]
{

/// User needs WRITE privilege on this resource to view these pages.
Parameter RESOURCE = "%Ens_PubSub:READ";

Parameter PAGENAME = "PubSub Subscriptions";

Property ClassName As %ZEN.Datatype.className(ZENURL = "CLASSNAME");

XData Style
{
<style type="text/css">
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane>
<iframe id="contents" frameBorder="false" height="100%" width="100%" scrolling="auto" />
</pane>
}

/// Set source for frame object
Method %OnAfterCreatePage() As %Status
{
	// Default is Subscriptions
	If ..ClassName="" Set ..ClassName = "EnsPortal.PubSub.Subscriptions.cls"

	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC

	// Normalize
	If $E(..ClassName,*-3,*)=".zen" Set ..ClassName = $E(..ClassName,1,*-3)_"cls"
	Else  If $E(..ClassName,*-3,*)'=".cls"  Set ..ClassName = ..ClassName_".cls"

	If $extract(..ClassName,1,17) '= "EnsPortal.PubSub." {
		Set ..ClassName = "EnsPortal.PubSub.Subscriptions.cls"
	}
	If ($E(..ClassName,*-7,*-4) = "Edit") && '$system.Security.Check("%Ens_PubSub","WRITE") {
		Set %response.Status = "403 Forbidden"
		Quit $$$ERROR($$$AccessDenied)
	}

	// Relay URL $ parameters
	Kill parms
	Set var = ""
	For {
		Set var = $O(%request.Data(var))
		Quit:var=""
		If $E(var,1)="$" && $D(%request.Data(var,1)) Set parms(var) = %request.Data(var,1)
	}

	Set ..%GetComponentById("contents").src = ..Link(..ClassName,.parms)
	Quit $$$OK
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit ..%OnGetPageName()
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $Case(..ClassName,
		"EnsPortal.PubSub.Domains.cls": $$$Text("PubSub Domain Names"),
		"EnsPortal.PubSub.DomainEdit.cls": $$$Text("Edit PubSub Domain Name"),
		"EnsPortal.PubSub.Subscriptions.cls": $$$Text("PubSub Subscriptions"),
		"EnsPortal.PubSub.SubscriptionEdit.cls": $$$Text("Edit Subscription Definition"),
		"EnsPortal.PubSub.Subscribers.cls": $$$Text("PubSub Subscribers"),
		"EnsPortal.PubSub.SubscriberEdit.cls": $$$Text("Edit Subscriber Definition"),
		: $$$Text("Publish & Subscribe")
		)
}

/// Replace last locator's link to include CLASSNAME parameter.
/// pLink(n)=$LB(caption,link) 	
Method %GetLocatorLinks(Output pLink As %String) As %Status
{
	Do ##super(.pLink)
	Set index = +$O(pLink(""),-1)
	Set pLink(index) = $LB($LG(pLink(index),1),"EnsPortal.PubSub.PageContainer.cls?CLASSNAME="_..ClassName)
	Quit $$$OK
}

ClientMethod changeURLNamespace(value) [ Language = javascript ]
{
	// Need to keep URL parameter CLASSNAME
	var url = zenPage.GetNewURL(value, "EnsPortal.PubSub.PageContainer.cls?CLASSNAME=" + zenPage.ClassName);
	self.document.location = url;

	// PubSub may be disabled for the selected namespace, so we return to the menu - Use this in case it is conditionally linked to the menu
	//self.document.location = zenLink("/csp/sys/%25CSP.Portal.Home.zen?$NAMESPACE=" + value);
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	this.adjustSizes();
}

/// Adjust size of the contents area.
ClientMethod adjustSizes() [ Language = javascript ]
{
	try {
		var winHeight = zenGetWindowHeight();
		var winWidth = zenGetWindowWidth();
		var th = this.getTitleAreaHeight();
		var contentsDiv = zen('contents').getEnclosingDiv();
		contentsDiv.style.height = (winHeight - th - 22) + 'px';
		contentsDiv.style.width = (winWidth - 25) + 'px';
	}
	catch(ex) {
		alert('Error in adjustSizes()');
	}
}

/// Register this visit to the recent items list (override superclass method)
Method %Register() As %Status
{
	Set tSC = $$$OK
	#; register visit
	If (..#RECENT) {
		Set tURL = $ZCVT(%request.URL,"O","URL")
		Try {
			// Swallow error if method not defined
			Set tSC = ##class(%CSP.Portal.Utils).%RegisterRecentItem("Publish & Subscribe",$P(tURL,"?",1))
		}
		Catch(ex) {
		}
	}
	Quit tSC
}

}
