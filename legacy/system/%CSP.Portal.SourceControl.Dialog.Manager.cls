/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Wrapper class to correctly manage popups requested by Source Control hooks.
Class %CSP.Portal.SourceControl.Dialog.Manager Extends %CSP.Portal.Template [ System = 4 ]
{

Parameter PAGENAME = "Source Control Dialog";

Property targetURL As %String(MAXLEN = "", ZENURL = "TARGET");

/// Flag to indicate whether the IE=Edge meta tag should be written out to force
/// Internet Explorer to use its most recent rendering engine. By default, the portal
/// does write out this flag, but users can disable the flag by implementing the
/// GetPortalPageOptions() callback defined in <class>%Studio.SourceControl.Base</class>
/// to specify that IE Compatibility should be permitted.
Property %UseIEEdge As %Boolean [ InitialExpression = 1, Internal, ServerOnly = 1 ];

/// Property to indicate whether a specific CSS Level should be used for the page.
/// By default, we will attempt to use CSS Level 3 if we can detect the browser 
/// supports HTML 5. The value can be modified by implementing the
/// GetPortalPageOptions() callback defined in <class>%Studio.SourceControl.Base</class>.
Property %CSSLevel As %String [ ServerOnly = 1 ];

XData Style
{
<style type="text/css">
#zenBody {
	/* Hide anything beyond the iframe */
	overflow: hidden;
}
</style>
}

/// Contents of this page:
XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="#(%page.StdTitle)#" layout="none">
<iframe id="sourceFrame" frameBorder="false" width="600" height="400" />
</page>
}

ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	this.initializeFrame(load);
}

/// Code to resize the iframe based on the window size and check whether a title 
ClientMethod initializeFrame(newSrc) [ Language = javascript ]
{
	var sourceFrame = zen('sourceFrame');
	var iframe = sourceFrame.findElement('iframe');
	// iframe.contentDocument doesn't work as expected on IE8, so use more circuitous reference.
	if (iframe && iframe.contentWindow && iframe.contentWindow.document && (iframe.contentWindow.document.title != null)) {
		document.title = iframe.contentWindow.document.title;
	}
	else if (!this._titleTimer) {
		this._titleTimer = setInterval('zenPage.updateTitle()',10);
	}
	if (newSrc) this.addCompletionCheck('zenPage.checkCompletion()',10);
	
	var width = zenGetWindowWidth();
	var height = zenGetWindowHeight();
	if (zenIsHTML5 && (zenIsIE || zenIsGecko)) {
		width -= 4;
		height -= 4;
	}
	else if (zenIsIE) {
		height -= 1;
	}
	
	sourceFrame.setProperty('width',width);
	sourceFrame.setProperty('height',height);
}

/// Point the iframe at the URL specified in targetURL.
Method %OnAfterCreatePage() As %Status
{
	// Ensure ..targetURL uses a relative path to avoid cross site scripting
	Do ##class(%Net.URLParser).Parse(..targetURL,.tURLParts)
	Set ..targetURL = $get(tURLParts("path"))
	If ($get(tURLParts("query")) '= "") {
		Set ..targetURL = ..targetURL _ "?" _ tURLParts("query")
	}
	If ($get(tURLParts("fragment")) '= "") {
		Set ..targetURL = ..targetURL _ "#" _ tURLParts("fragment")
	}
	Set tSourceFrame = ..%GetComponentById("sourceFrame")
	Set tSourceFrame.src = ..targetURL

	Try {
		Set tSourceControlClass = ##class(%Studio.SourceControl.Interface).SourceControlClassGet()
		If (tSourceControlClass '= "") {
			Do $classmethod(tSourceControlClass,"GetPortalPageOptions",..targetURL,.tOptions)
			If ($get(tOptions("IECompatibility")) = 1) {
				Set ..%UseIEEdge = 0
			}
			If ($get(tOptions("CSSLevel")) '= "") {
				Set ..%CSSLevel = tOptions("CSSLevel")
			}
		}
	}
	Catch {}

	Quit ##super()
}

/// Adds a JS Interval which executes the supplied function at the supplied interval.
ClientMethod addCompletionCheck(checkFunc, time) [ Language = javascript ]
{
	if (!this._completionChecks) this._completionChecks = [];
	this._completionChecks.push(setInterval(checkFunc, time));
}

/// Remove any intervals created while waiting for source control frames to load.
/// Primarily used to check on the status of the popup.
ClientMethod clearCompletionChecks() [ Language = javascript ]
{
	if (this._completionChecks) {
		var currInterval = this._completionChecks.pop();
		while (currInterval > 0) {
			clearInterval(currInterval);
			currInterval = this._completionChecks.pop();
		}
	}
}

/// Check whether the contents of the iframe have been completely loaded,
/// and close the window if it's a Studio template, otherwise
/// add the source control specific onbeforeunload event handling.
ClientMethod checkCompletion() [ Language = javascript ]
{
	var sourceFrame = zen('sourceFrame');
	var iframe = sourceFrame.findElement('iframe');
	var opener = this.getOpener();
	var zenOpener = (opener && opener.zenPage ? opener.zenPage : null);
	if (this._checkCount == null) this._checkCount = 0;
	
	// iframe.contentDocument doesn't work as expected on IE8, so use more circuitous reference.
	if (iframe && iframe.contentWindow && iframe.contentWindow.document) {
		var doc = iframe.contentWindow.document;
		var topNodeName = '';
		var readyState = '';
		try {
			readyState = doc.readyState;
			if (doc.documentElement) topNodeName = doc.documentElement.nodeName;
		}
		catch (ex) {}
		if (readyState == 'complete') {
			if ((topNodeName == 'template') || (zenIsIE && (!iframe.contentWindow._ISC_SourceControl) && doc.body && (doc.body.innerText.substring(2,39) == '<?xml version="1.0" ?> \r\n- <template>'))) {
				this.clearCompletionChecks();
				if (zenOpener && zenOpener._currentSCData) {
					var inputData = zenOpener._currentSCData;
					zenOpener._currentSCData = null;
					inputData.message = '';
					inputData.answer = 1;
					var userData = zenOpener._currentSCData_Context;
					zenOpener.invokeAfterUserAction(inputData,userData);
				}
				if (this.isSoftModal) {
					if (window.top && window.top.zenPage) window.top.zenPage.endModal();
				}
				else {
					window.close();
				}
				return;
			}
			else {
				if (iframe.contentWindow._ISC_SourceControl && (iframe.contentWindow.onbeforeunload != iframe.contentWindow._ISC_SourceControl.onFrameUnload)) {
					this.clearCompletionChecks();
					iframe.contentWindow._ISC_SourceControl.setHandler('onFrameUnload', 'onbeforeunload');
					return;
				}
			}
		}
	}
	
	this._checkCount += 1;
	if (this._checkCount > 1000) { // this equates to 10 seconds
		alert($$$Text('Source control timed out waiting for page to load. Further actions will not be handled by the source control system.','%Utility'));
		this.clearCompletionChecks();
	}
}

/// Update the title of the main window based on the title of the inner iframe.
ClientMethod updateTitle() [ Language = javascript ]
{
	if (this._titleCount == null) this._titleCount = 0;
	this._titleCount++;
	var updated = false;
	var sourceFrame = zen('sourceFrame');
	if (sourceFrame && sourceFrame.findElement) {
		var iframe = sourceFrame.findElement('iframe');
		// iframe.contentDocument doesn't work as expected on IE8, so use more circuitous reference.
		if (iframe && iframe.contentWindow && iframe.contentWindow.document && (iframe.contentWindow.document.title != null)) {
			updated = true;
			if (iframe.contentWindow.document.title != '') document.title = iframe.contentWindow.document.title;
		}
	}
	if (updated && this._titleTimer) clearInterval(this._titleTimer);
}

/// If the source control hooks a specific CSS level is specified in <property>%CSSLevel</property>,
/// return the value, otherwise use the default for the portal.
Method %OnDetermineCSSLevel() As %Integer
{
	If (..%CSSLevel '= "") {
		Quit ..%CSSLevel
	}
	Quit ##super()
}

Method %OnDrawHTMLMeta() As %Status
{
 /// If the source control hooks specify that IE Edge mode should NOT be used, ensure that we don't invoke
 /// the code to write out the corresponding meta tag.
	If '..%UseIEEdge {
		Quit $$$OK
	}
	Quit ##super()
}

ClientMethod onunloadHandler() [ Language = javascript ]
{
	var opener = this.getOpener();
	var zenOpener = (opener && opener.zenPage ? opener.zenPage : null);
	if (zenOpener) {
		var cls = zenOpener._serverClass;
		if (zenPage.CheckExtends(cls,"EnsPortal.Template.devPage")) { 
			zenOpener.toggleReadOnly();
		}
	}
	return true;
}

Method CheckExtends(pCls As %String, pSuper As %String) As %Boolean [ ZenMethod ]
{
	Quit:pCls="" 0
	Quit $classmethod(pCls,"%Extends",pSuper)
}

}
