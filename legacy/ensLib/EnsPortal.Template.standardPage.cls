/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %products

/// Base class for generic InterSystems IRIS Interoperability pages.<br/>
/// This is used for pages that do fit into one of the other base class
/// categories.
Class EnsPortal.Template.standardPage Extends (%CSP.Portal.Template, EnsPortal.Template.base) [ Abstract, System = 4 ]
{

Parameter JSINCLUDES = "zenMenusSMPEns.js";

// ZHJ037: SMP Reskin - Menu Style Overriden for Interoperability Pages

Parameter DOMAIN = "Ensemble";

/// Do not switch namespace for the page based on $NAMESPACE; will stay in the original namespace.
Parameter AUTONS As %Boolean = 0;

/// Set this to the appropriate application class.
Parameter APPLICATION = "EnsPortal.Application";

/// favorite icon.
Parameter FAVORITEICON As COSEXPRESSION = "$$$ISCFAVORITEICON";

/// Resource for subclasses to indicate whether further resources are needed to perform actions on pages.
Parameter EDITRESOURCE;

/// If true and AUTOLOGOUT is true then call onhandleAutoLogout 30 seconds
/// prior to AUTOLOGOUT. This allows the page to handle client page modifications
/// while the session is still valid before the page is reloaded.
Parameter CHECKMODIFIEDBEFORELOGOUT = 1;

/// The help address that links to the "Help" (next to the "Logout" link) documentation
Property HelpAddress As %ZEN.Datatype.string [ InitialExpression = {$select(..#PAGENAME '= "": "Ensemble, "_..#PAGENAME, 1: "")} ];

/// Flag to indicate whether the user is permitted to make any changes on a given page.
Property canEdit As %ZEN.Datatype.boolean [ InitialExpression = {##class(EnsPortal.Utils).CheckResourceList(..#EDITRESOURCE)} ];

/// Message to inform the user they may not perform a given action.
Property msgNotPermitted As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("You are not permitted to perform this action")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
.zenLabel {
	color: rgb(67,67,67);
	font-size: 10pt;
}
.zenHint {
	color: rgb(67,67,67);
	font-size: 8pt;
}
.detailLabel {
	font-weight: bold;
	color: rgb(71,72,67);
	font-size: 10pt;
}

#zenBody {
	background: white;
}
#editorPane {
	position: relative;
	padding-left:4px;
	border-bottom:1px solid black;
}
#propertyPane {
	position: relative;
	background: #edece4;
	height: 449px;
	width: 400px;
	border: 1px solid rgb(156,154,141);
	border-bottom: 1px solid black;
}

#propertyTitle {
	background:rgb(156,154,141);
	color: white;
}

#propertyCommands {
	color: white;
}

.helpCommand {
	text-decoration: none;
	color: white;
	font-size: 9pt;
}

.helpCommand:hover {
	text-decoration: none;
	color: darkred;
}
/* generic button style*/
.button {
	background-color: #346C8D;
	color: #E0E0E0;
	font-size: 9pt;
}
.button:hover {
	color: white;
	background: #808080;
}

.helpArrow {
	font-size:18pt;
	color:white;
	padding-left: 4px;
	padding-right: 4px;
	background: rgb(53,107,141);
}

#helpPane {
	position: relative;
	background: white;
	height: 449px;
	width: 300px;
	border-right: 1px solid black;
	border-bottom: 1px solid black;
	display: none;
	overflow-x: hidden;
	overflow-y: auto;
}
.hdrLink {
	font-size: 10pt;
	font-weight: normal;
	color: #78b6dc;
	text-decoration: none;
	padding-left: 6px;
	padding-right: 6px;
}

.hdrLinkDisabled {
	font-size: 10pt;
	font-weight: normal;
	color: gray;
	text-decoration: none;
	padding-left: 6px;
	padding-right: 6px;
}

.hdrLink:hover {
	color: orange;
}

/* styles for tabs */
td.tabGroupButtonOff:hover {
	color: #FFEEAA;
}

.tabGroupBody {
	background: #E0E0D0;
	width: 399px;
	min-height: 100px;
}

td.tabGroupButtonOn {
	height: 30px;
	color: #404040;
	background: #E0E0D0;
	font-size: 10pt;
}

td.tabGroupButtonOn {
background: -moz-linear-gradient(top, #F8F8FF, #E0E0D0);
background: -webkit-linear-gradient(top, #F8F8FF, #E0E0D0);
	background: linear-gradient(top, #F8F8FF, #E0E0D0);
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

/* @doc="Individual tab bar button in Off state." */
td.tabGroupButtonOff,
td.tabGroupButtonDisabled {
	height: 30px;
	color: #404040;
	background: #C0C0C0;
	font-size: 10pt;
	background-image: none;
	background-repeat: repeat-x;
}
td.tabGroupButtonOff:hover {
	background: #C0C0C0;
}

td.tabGroupButtonDisabled {
	color: gray;
}

td.tabGroupButtonOff {
background: -moz-linear-gradient(top, #B0B0B0, #D0D0D0);
background: -webkit-linear-gradient(top, #B0B0B0, #D0D0D0);
	background: linear-gradient(top, #B0B0B0, #D0D0D0);
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

td.tabGroupButtonDisabled {
background: -moz-linear-gradient(top, #B0B0B0, #D0D0D0);
background: -webkit-linear-gradient(top, #B0B0B0, #D0D0D0);
	background: linear-gradient(top, #B0B0B0, #D0D0D0);
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
}

.tabGroupGap {
	width: 0px;
}

.fullMessageLink {
	font-size: 10pt;
	padding-left: 12px;
	padding-right: 12px;
}

[class*="timeoutWarn-"] {
    display: inline-block;
    position: absolute;
    z-index: 1;
    left: 30%;
    right: 70%;
    top: 30%;
    bottom: 70%;
    width: 400px;
    background-color:white;
    border: 2px solid #888;
    border-radius: 25px ;
}
.timeoutWarn-exclamation {
	height: 290px;
}
.timeoutWarn-noexclamation {
	height: 250px;
}
.stdTitle {
	color:#000000;
	background: #ffffff;
	border-bottom: none;
	font-family: Futura,Arial,sans-serif; 
	font-size: 16px;
	font-weight: 700;
	letter-spacing: 0.75px;
	margin: 20px 20px 10px 20px;
	text-transform: uppercase;
	white-space: nowrap;
}
.stdSubTitle-p20 {
	color:#000000;
	font-family: Futura,Arial,sans-serif;
	font-style: italic;
	font-size: 12px;
	font-weight: normal;
	letter-spacing: 0.75px;
	padding-left: 20px;
	width: 80%;
}
.commandButton-l20 {
	margin-left: 20px;
}
.commandButton-r20 {
	margin-right: 20px;
}
</style>
}

/// Return the array of links to show in the locator bar.<br/>
/// pLink(n)=$LB(caption,link) 
Method %GetLocatorLinks(Output pLink) As %Status
{
	Do ..%GetRootLink(.pLink)

	// default: add *this* page to list
	Set tPageName = ..%OnGetPageName()
	Set tURL = $ZCVT($classname(),"O","URL")_".zen"
	Set pLink(2) = $LB(tPageName,tURL)
	Quit $$$OK
}

Method %GetRootLink(Output pLink) As %Status
{
	Set tPageName = $$$PRODUCT2
	Set pLink($I(pLink)) = $LB(tPageName,..homePage)
}

/// Define any context links for the page. Sub-class to override.
ClassMethod GetContextLinks(Output pLinks) As %Status
{
	Set tSC = $$$OK
	// create list of jump targets and associated URL

	Set pLinks($I(n)) = $LB($$$Text("Monitor"),##class(%CSP.Page).Link("/csp/sys/%25CSP.UI.Portal.EnsembleMonitor.zen"),"")
	Set pLinks($I(n)) = $LB($$$Text("Production"),"EnsPortal.ProductionConfig.zen","")
	Set pLinks($I(n)) = $LB($$$Text("Message Viewer"),"EnsPortal.MessageViewer.zen","")
	Set pLinks($I(n)) = $LB($$$Text("Event Log"),"EnsPortal.EventLog.zen","")
	Set pLinks($I(n)) = $LB($$$Text("Queues"),"EnsPortal.Queues.zen","")
	Set pLinks($I(n)) = $LB($$$Text("Workflow"),"EnsPortal.WFWorklist.zen","")

	Quit ..CheckContextLinks(.pLinks)
}

/// *******************************************************************///
///                  
/// Used to move an item from one listbox to the other. The listboxes are side-by-side.
/// The action moves a list item from one box to the next, then remove it from the original box.
/// This method was originally in CSPX.Portal.Template which is no longer used.
/// 
/// *******************************************************************///
ClientMethod arrowClick(from, to) [ Language = javascript ]
{
	var fromCtl = zenPage.getComponentById(from);
	var currIndex = fromCtl.selectedIndex;
	if ( (currIndex < 0) || (currIndex >= fromCtl.getOptionCount()) ) return;	
	var optionValue = fromCtl.getOptionValue(currIndex);
	var optionText = fromCtl.getOptionText(currIndex);
	var toCtl = zenPage.getComponentById(to);
	toCtl.appendOption(optionValue,optionText);
	
	fromCtl.removeOption(currIndex);
	return optionValue;
}

ClientMethod checkEdit() [ Language = javascript ]
{
	if (!this.canEdit) {
		alert(this.msgNotPermitted);
	}
	return this.canEdit;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	this.startKeepAlive();
	this.initPopupSuffix();
}

/// Returning from dialogs 
ClientMethod onPopupAction(popupName, action, value) [ Language = javascript ]
{
	if (action != "ok") {
		return false;
	}
	popupName = this.removePopupSuffix(popupName);
	switch(popupName) {
		case 'switchNamespace': // change namespace but keep the same page
			zenPage.changeURLNamespace(value);
			break;
	}
	return true;
}

/// The input value is the name of the new namespace to switch to.
/// This method only works for EnsPortal classes whose URL is simple (no URL parameters).
/// This method will need to be overridden for classes such as EnsPortal.EDIDocumentView 
/// which cannot work without a URL parameter provided.
ClientMethod changeURLNamespace(nsVal) [ Language = javascript ]
{
	var newUrl = '';
	var oldUrl = self.document.location.toString();
	var start = oldUrl.indexOf("EnsPortal.");
	if (start >= 0) { // we found the start of the EnsPortal part of the URL
		var end = oldUrl.indexOf("?");
		if (end >= 0) { 
			newUrl = oldUrl.substring(start, end);
		} else {
			newUrl = oldUrl.substring(start);
		}
		var newUrl = zenPage.GetNewURL(nsVal, newUrl);
	//} else { // this is not an EnsPortal class
	}
	if (newUrl == '') newUrl = zenPage.GetNewURL(nsVal);
	self.document.location = newUrl;
}

/// Invoke the base OnPreHyperEvent() method, and then check whether the user
/// is permitted to invoke the specified method by checking the resource returned
/// by the <method>GetHyperEventResources</method> callback.
ClassMethod OnPreHyperEvent(class As %String, method As %String) As %Status [ ServerOnly = 1 ]
{
	Set tSC = ##super(.class,.method)
	If $$$ISERR(tSC) Quit tSC
	
	Set tClass = class
	Set tMethod = method
	If (tClass=$classname()){
		Set tContext = $get(%request.Data("WARG_1",1))
		If (tMethod = "InvokeInstanceMethod") && (tContext = 1) {
			Set tMethod = $get(%request.Data("WARG_2",1))
		}	
		ElseIf (tMethod = "InvokeClassMethod") && (tContext = $classname()) {
			Set tMethod = $get(%request.Data("WARG_2",1))
		}
		If tMethod = "" Set tMethod = method
	}
	Set tResourceList = ..GetHyperEventResources(.tMethod)
	If tResourceList = "" Quit $$$OK
	If '##class(EnsPortal.Utils).CheckResourceList(tResourceList) {
		Set %response.Status = "403 Forbidden"
		Quit $$$ERROR($$$InsufficientPrivilegeForOperation)
	}
	Quit $$$OK
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit ""
}

/// Get the contents of the small menu in the title area.
Method %OnGetSmallMenu(Output pMenu)
{
	// $LB(caption,title,script)
	Set tI=0
	Set pMenu($I(tI)) = $LB($$$TextHTML("Home"),$$$TextHTML("Go to the Home page"),"return zenPage.goHome();")
	If ##class(%Library.EnsembleMgr).IsHealthShareInstalled() {
		Set tURL = ##class(%ZHSLIB.SessionEventUtil).GetHealthSharePortalLink()
		#; Default for HealthShare and other:
		Set tText1 = $$$TextHTML("HealthShare"), tText2 = $$$TextHTML("Go to HealthShare Management")
		#; For IRIS for Health and Health Connect:
		If '##class(%ZHSLIB.HealthShareMgr).IsHealthShareInstance() {
			Set tText1 = $$$TextHTML("Health"), tText2 = $$$TextHTML("Go to Health Management")
		}
		Set pMenu($I(tI)) = $LB(tText1,tText2,"document.location='"_tURL_"';")
	}
	Set pMenu($I(tI)) = $LB($$$TextHTML("About"),$$$TextHTML("Display the About page"),"return zenPage.showAbout();")
	Set pMenu($I(tI)) = $LB($$$TextHTML("Help"),$$$TextHTML("Display help for this page"),"return zenPage.showHelp();")
	Set pMenu($I(tI)) = $LB($$$TextHTML("Logout"),$$$TextHTML("End this session"),"return zenPage.logout();")
}

/// Ensure that the user has the required privileges for the Portal application.
ClassMethod %OnPreHTTP() As %Boolean
{
	If '##class(EnsPortal.Application).CheckPrivileges() {
		Set %zenPageError = $$$ERROR($$$AccessDenied)
		Set %zenStatsTime = $zh
		Set %response.Status = "403 Forbidden"
	}
	Quit 1
}

/// Add the EnsException error handling on the client.
Method %OnDrawHTMLHead() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	Quit ..%AddEnsExceptionHandler()
}

/// Override onServerMethodError to funnel HyperEvent errors through the
/// central Ensemble exception handling code.
/// If session pollution occurs while in Studio mode, alert the user to the problem instead of reloading.
/// The method sets zenPage._staleStudioSession to true to ensure that an alert is displayed only once and subsequent
/// hyperevent failures will not trigger a reload of the page.
ClientMethod onServerMethodError(err, errObject) [ Language = javascript ]
{
	if (errObject) {
		if (zenPage && (!zenPage._staleStudioSession) && zenPage.studioMode && ((errObject.serverCode == 5919) || (errObject.serverCode == 5918))) {
			zenPage._staleStudioSession = true;
			alert($$$Text('Your browser session is no longer valid.') + '\n' + $$$Text('Please save changes to any modified documents and restart your IDE to resolve the problem.'));
		}
		if (zenPage && zenPage._staleStudioSession) return true;

		// A session timeout occurred, set the page to unmodified and reload
		if ((errObject.code == 401) && ((errObject.serverCode == 864) || (errObject.serverCode = 5918))) {
			this.setModified(false);
			return false;
		}
		var doAlert = true;
		if ((zenPage.limitPopups)&&(errObject.code<401)) { // check to see if this was refresh timer related
			var refreshRate = 0;
			if (zenPage.keepAliveInterval) {
				refreshRate = zenPage.keepAliveInterval;
			}
			if (zen('chkRefresh') && (!zen('chkRefresh').getValue().match("None"))) {
				if (refreshRate > 0) {
					refreshRate = Math.min(refreshRate,zen('chkRefresh').getValue());
				} else {
					refreshRate = zen('chkRefresh').getValue();
				}
			} else if ((self.document.getElementById('refreshRate')&&(document.getElementById("refreshOn"))&&(document.getElementById("refreshOn").checked))) {
				if (refreshRate > 0) {
					refreshRate = Math.min(refreshRate,self.document.getElementById('refreshRate').value*1000);
				} else {
					refreshRate = self.document.getElementById('refreshRate').value*1000;
				}
			} else if (zenPage.refreshRate && (zenPage.refreshRate > 0)) {  // hard coded value
				if (refreshRate > 0) {
				refreshRate = Math.min(refreshRate,zenPage.refreshRate*1000);
				} else {
					refreshRate = zenPage.refreshRate*1000;
				}
			}
			if (parseInt(refreshRate)) { //page has defined refresh rate
				refreshRate = Math.min(refreshRate,15000);
				zenPage.setConnectivityStatusMsg(err);
				window.setTimeout('zenPage.setConnectivityStatusMsg("Re-trying");',parseInt(refreshRate));
				window.setTimeout('zenPage.testConnectivity();',parseInt(refreshRate));
				doAlert = false;
			}
		}
		if (doAlert) {
			if (errObject.exception && errObject.arguments) {
				EnsException.exceptionHandler(errObject.exception, errObject.arguments, '');
			}
			else {
				if (errObject.code == 403) {
					alert($$$Text('You are not permitted to perform this action'));
				} else { 
					EnsException.hyperEventHandler(errObject,err);
				}
			}
		}
	}
	return true;
}

/// Render the contents trapping for permission issue
ClassMethod OnPage() As %Status
{
	If ($D(%zenPageError)#2) && $$$ISERR(%zenPageError) && $SYSTEM.Status.Equals(%zenPageError,$$$ERRORCODE($$$AccessDenied)) {

		#dim tMessage As %String = $$$TextHTML("Insufficient privileges to access page.")
		&html<<html><body>#(tMessage)#</div></body></html>>
		#; stats
		If (..#SHOWSTATS) {
			Write "<!-- ",$ZH-%zenStatsTime," -->"
		}
		Do %response.Flush()
		Quit $$$OK

	} Else {

		Quit ##super()		
	}
}

/// Overrides super class method to be able to set custom web application if
/// applicable when switching namespace.
ClassMethod GetNewURL(pNS As %String, pPage As %String = "%25CSP.Portal.Home.zen") As %String [ ZenMethod ]
{
	/* Use standard web application if HealthShare or HealthConnect product or not set custom portal URL */
	If (pPage="")||(pPage["/csp/sys/")||($$$ISCPRODUCTCODE=$$$HealthShareProductKey)||($Get(^%SYS("Ensemble","InstalledNamespace",pNS))="") {

		Quit ##super(pNS, pPage)

	}

	#dim tURL As %String
	Set tURL = ##class(%Library.EnsembleMgr).DetermineMgmtURLForNamespace(pNS,0)

	Set tURL = tURL _ pPage
	
	Set tURL = ##class(%CSP.Page).Link(tURL,,1)
	// Strip off $NAMESPACE from existing URL so only one $NAMESPACE will be built into URL.
	Set tquery = $P(tURL,"?",2)
	If tquery '= "" {
		Set tLen = $L(tquery,"&") - 1
		For tI = 1:1:tLen Set p1 = $P(tquery,"&",tI),p2=$P(p1,"=",1),p3=$p(p1,"=",2) if p2'="" s p(p2)=p3
		Set p("$NAMESPACE") = pNS
		Set tquery = ""
		Set p2 = $O(p(""))
		While p2 '= "" {
			Set tquery = tquery _ p2 _ "=" _ p(p2) _ "&"
			Set p2 = $O(p(p2))
		}
		Set tURL = $P(tURL,"?",1) _ "?" _ tquery
	} Else {
		Set tURL = tURL _ "$NAMESPACE="_pNS
	}
	Set %session.Data("$NAMESPACE") = pNS
	Quit tURL
}

ClientMethod setModified(flag) [ Language = javascript ]
{
	/* Store last UI change time. Used when detecting possible WIP loss due to secure autologout */
	if (this.keepAliveInterval <= 0) {
		if (flag) {
			this._pageTimeModified = new Date().getTime();
		} else {
			this._pageTimeModified = null;
		}
	}
	this.invokeSuper('setModified',arguments);
}

/// Prior to auto logout allow time to see if user needs to continue Session.
ClientMethod onhandleAutoLogoutWarn() [ Language = javascript ]
{
	/*
		This reminder is only set up when making server side calls.
		Timer set to SessionTimeout - 30 seconds (zenAutoLogoutWarnTime).
		If we made a change within the last half of current session timeout 
		then we will automatically renew the session otherwise we 
		will ask the user if they want to keep the session going.
		Not all pages set pageModified via setModified() and hence 
		_pageTimeModified will be null and the user will always be asked.
		We do not do automatic Saving - user needs to act accordingly
		on the given page.
		We ignore if we are using client side keep alive calls.
	*/
	if (this.keepAliveInterval > 0) {
		return true;
	}
	if (!(this.studioMode)) {
		if ((zenAutoLogoutWarnTime)&&(this._pageTimeModified)) {
			var now = new Date().getTime();
			if ((now-this._pageTimeModified) <= ((zenAutoLogoutWarnTime+25000)/2)) {
				var simpleString = this.SimpleKeepAlive('');
				return true;
			}
		}
		var doShow = this.showTimeoutWarning()
	}
	return true;
}

ClientMethod showTimeoutWarning() [ Language = javascript ]
{
	var warningDiv = document.getElementById('timeoutWarnDiv');
	if (!warningDiv) {
		warningDiv = this.createTimeWarning();
	} else {
		zenPage.hideWarnContinue(false); //in case hidden and session was auto logged in
	}
	if (warningDiv) {
		warningDiv.className =  this.pageModified ? 'timeoutWarn-exclamation' : 'timeoutWarn-noexclamation';
		zenPage._warnCount = 46;
		countDownTimerId = setInterval(this.displayCountDown, 1000);
		this.displayCountDown();
		var warningSymbol = document.getElementById('warningSymbol');
		if (warningSymbol) {
			warningSymbol.style.display = this.pageModified ? 'block' : 'none';
			var warnSpacer = document.getElementById('warnSpacer');
			if (warnSpacer) {
				warnSpacer.style.display = this.pageModified ? 'none' : 'block';
			}
		}
		warningDiv.style.display = 'inline-block';
		try {document.getElementById('continueTOSession').focus();} catch (e) {}
		warnClearTimerId = setTimeout(this.hideTimeoutWarning, 44000);
		document.addEventListener('click', zenPage.warnclickListener);
	}
	return true;
}

ClientMethod createTimeWarning() [ Language = javascript ]
{
	var warningDiv = document.createElement('div');
	warningDiv.setAttribute('id','timeoutWarnDiv');
	var doSetInner = this.setWarnInnerHTML(warningDiv);
	document.body.appendChild(warningDiv);
	try {
		document.getElementById('warnTOTitle').innerHTML = $$$Text('Session Timeout Warning');
		document.getElementById('warnTOReload').innerHTML = $$$Text('The page will be reloaded.');
		document.getElementById('warnTOContinue').innerHTML = $$$Text('Click Continue to extend the session and return to the page.');
		var cancelButton = document.getElementById('cancelTOWarning');
		if (cancelButton) {
			cancelButton.title = $$$Text('Press Cancel to close this alert.');
			cancelButton.value = $$$Text('Cancel');
		}
		var continueButton = document.getElementById('continueToSession');
		if (continueButton) {
			continueButton.title = $$$Text('Press Continue to maintain the session.');
			continueButton.value = $$$Text('Continue');
		}
	} catch (e) {}
	return warningDiv;
}

ClientMethod setWarnInnerHTML(warningDiv) [ Language = javascript ]
{
	var i = '<table style="width:100%;">';
	i += '<tr><td style="height:10px;"></td></tr>';
 	i += '<tr><td id="warnTOTitle" style="text-align:center;" class="stdTitle" colspan="2"></td></tr>';
	i += '<tr><td style="text-align:center;" colspan="2"><div style="text-align:center;"><img id="warningSymbol" src="portal/warning_64.png" style="margin-left:auto;margin-right:auto;"/></div></td></tr>';
	i += '<tr><td id="warnSpacer" style="height:40px;"></td></tr>';
	i += '</table><table style="width:100%;">';
	i += '<tr><td id="warnTOReload" class="stdSubTitle-p20"></td><td style="width:20%;"/></tr>';
	i += '<tr><td style="height:30px;"></td></tr>';
	i += '<tr><td id="warnTOContinue"class="stdSubTitle-p20"></td><td style="width:20%;"/></tr>';
	i += '<tr><td style="height:20px;"></td></tr>';
	i += '</table><table style="width:100%;">';
	i += '<tr>';
	i += '<td style="width:50%;text-align:left;""><input id="cancelTOWarning" type="button" class="commandButton commandButton-l20" value="Cancel" onclick="zenPage.hideTimeoutWarning();"/></td>';
	i += '<td style="width:50%;text-align:right;"><input id="continueTOSession" type="button" class="commandButton commandButton-r20" value="Continue" onclick="zenPage.manualKeepAlive();"/></td>';
	i += '</tr>';
	i += '</table>';
	warningDiv.innerHTML = i;
	return true;
}

ClientMethod displayCountDown() [ Language = javascript ]
{
	zenPage._warnCount += -1;
	try {
		var suffix = zenPage.pageModified ? '<br>'+$$$Text('Changes may be lost.') : '';
		var message = '';
		if (zenPage._warnCount < 1) {
			message = $$$Text('The page will be reloaded shortly.')+suffix;
			document.getElementById('warnTOReload').innerHTML = message;
		} else {
			message = $$$Text('The page will be reloaded in ')+zenPage._warnCount+' '+$$$Text('seconds.')+suffix;
			document.getElementById('warnTOReload').innerHTML = message;
		}
		if (zenPage._warnCount==14) {
			/* the reload happens 15 seconds after session timeout so the Continue might be too late */
			zenPage.hideWarnContinue(true);
		}
	} catch (e) {}
}

ClientMethod manualKeepAlive() [ Language = javascript ]
{
	var simpleString = zenPage.SimpleKeepAlive('');
	var hide = zenPage.hideTimeoutWarning();
	return true;
}

ClientMethod hideTimeoutWarning() [ Language = javascript ]
{
	var warningDiv = document.getElementById('timeoutWarnDiv');
	if (warningDiv) warningDiv.style.display = 'none';
	if ((typeof warnClearTimerId !== 'undefined')&&(warnClearTimerId)) clearTimeout(warnClearTimerId);
	if ((typeof countDownTimerId !== 'undefined')&&(countDownTimerId)) clearInterval(countDownTimerId);
	document.removeEventListener('click', zenPage.warnclickListener);
	return true;
}

ClientMethod warnclickListener(event) [ Language = javascript ]
{
	var warningDiv = document.getElementById('timeoutWarnDiv');
	if (warningDiv) {
		if (!warningDiv.contains(event.target)) {
			var hide = zenPage.hideTimeoutWarning();
		}
	}
}

ClientMethod hideWarnContinue(hide) [ Language = javascript ]
{
	var continueMessage = document.getElementById('warnTOContinue');
	if (continueMessage) {
		var continueButton = document.getElementById('continueTOSession');
		if (continueButton) {
			continueMessage.style.visibility = hide ? 'hidden' : 'visible';
			continueButton.style.visibility = continueMessage.style.visibility;
		}
	}
}

}
