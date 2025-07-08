/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sqlui

/// This class is used internally by InterSystems IRIS. You should not make direct use of it within your applications. There is no guarantee made about either the behavior or future operation of this class.
/// <p>A specialized CSP page that automatically displays a page based on
/// information provided by a subclass.
Class %CSP.Util.AutoPage Extends %CSP.Page [ ServerOnly = 1, System = 4 ]
{

/// Default charset
Parameter CHARSET = "UTF-8";

/// Default Localization Domain
Parameter DOMAIN = "%Utility";

/// Name of the external style sheet file
Parameter STYLESHEET = "csputils.css";

/// SMP favorite icon.
Parameter FAVORITEICON = "portal/ISC_IRIS_icon.ico";

/// Allow pages to have iframes by not setting x-frame-options: same origin. 
/// Set default for Management Portal as iframes are not allowed.
Parameter IFRAMEALLOWED As BOOLEAN = 0;

/// Name of this page
Parameter PAGENAME;

/// Name of the parent page (used for the locator bar)
Parameter PARENTPAGE;

/// If true, this page uses frames
Parameter USEFRAMES = 0;

/// If true, this page changes namespace
Parameter USENAMESPACE = 0;

/// If true, this page uses hyper-events (#call)
Parameter HYPEREVENTS = 1;

/// If true, this page will automatically logout after a period of time
Parameter AUTOLOGOUT = 1;

ClassMethod OnPreHTTP() As %Boolean
{
	// construct a PageInstance object (before namespace switch)
	Set tPage = ..CreatePageInstance()
	Set %tPageInstance = tPage // cache this oref away
	Set tNS = ""

	If (+..#USENAMESPACE) {
		Kill %session.Data("$NAMESPACE") // no longer supported
		
		If ($G(%request.Data("$NSMODE",1)) '= "") {
			// change from namespace to implied namespace or v.v.
			Set tNSMODE = %request.Data("$NSMODE",1)
			Set tNS = ..ChangeNamespace("",tNSMODE)
		}
		Else {
			If ($G(%request.Data("$NAMESPACE",1)) '= "") {
				// change to specified namespace
				Set tNS = %request.Data("$NAMESPACE",1)
				If ((%request.PageName["Sql")&&($E(tNS)="^")) {
					// prevent sql pages from getting directory errors
					Set tNS = ""
				}

			}
			Set tNS = ..ChangeNamespace(tNS)
		}

		// if NS got changed, pass on new value
		Set %request.Data("$NAMESPACE",1) = tNS

		// make sure we pass this information along
		Set %response.Context("$NAMESPACE") = tNS
	}
	Else {
		// if namespace is around, remember it
		Set %response.Context("$NAMESPACE") = $G(%request.Data("$NAMESPACE",1))
	}

	Set tSubmit = 0
	Set tRedirect = 0
	
	// remove session lock to prevent blocking
	Do %session.Unlock()

	// test for autoform submit
	Set tSubmitBtn = ##class(AutoForm).DoSubmit()
	If (%response.Redirect '= "") {
		// error has forced a redirect
		Quit 1
	}
	If (tSubmitBtn '= "") {
		Set tSubmit = 1
		Set tRedirect = 1
	}

	// test for login
	/* In 5.1 you can't get to here unless you have already logged in
	If ((..#LOGINPAGE '= "") && (%session.Username = "")) {
		// if this is not the login page, then go there
		// !!! should this include path of page name (i.e., /csp/xxx)?
		
		If (..#LOGINPAGE '= %request.PageName) {
			// check if we are called from a frame...
			Set tf = $G(%request.Data("$FRAME",1))
			If (tf = "_top") {
				Set tf = ""
			}
			
			Set %response.Redirect = ..Link("/csp/sys/"_..#LOGINPAGE) _ "?$ID1=" _ ..EscapeURL(%request.URL _ "?$ID1=" _ $G(%request.Data("$ID1",1)) _ $S(tf="":"",1:"&$FRAME=" _ tf))
			Quit 1
		}
	}
	ElseIf ((tSubmitBtn = "$AUTOFORM_LOGIN") && (%session.Username '= "") && $D(%request.Data("$ID1",1))) {
		// redirect to original desination after login
		Set %response.Redirect = %request.Data("$ID1",1)
		Quit 1
	}
	*/
	// do we redirect?
	If (tRedirect) {
		Set %response.Redirect = tPage.MakeRedirectLink(%request.URL,tSubmitBtn)
	}

	If '(..#IFRAMEALLOWED) {
		Do %response.SetHeader("X-FRAME-OPTIONS","SAMEORIGIN")
	}

	Quit 1
}

/// Create the page instance object.
ClassMethod CreatePageInstance(ByRef pID As %String) As PageInstance
{
	Set tPagename = ..GetPageName()
	Set tInstance = ##class(PageInstance).%New()
	Set tInstance.Title = tPagename
	Set tInstance.PageClass = $classname()

	// add panes
	Set tPane = ..GetTitlePane(tInstance)
	If ($IsObject(tPane)) {
		Set tPane.Name = "Title"
		Do tInstance.Panes.SetAt(tPane,"Title")

		Do ..GetLocator(tPane,.tAddress)	// jmd
		Set tInstance.Address = tAddress
	}

	Set tPane = ..GetNavigatorPane(tInstance)
	If ($IsObject(tPane)) {
		Set tPane.Name = "Navigator"
		Do tInstance.Panes.SetAt(tPane,"Navigator")
	}
	
	Set tPane = ..GetDetailPane(tInstance)	
	If ($IsObject(tPane)) {
		Set tPane.Name = "Detail"
		Do tInstance.Panes.SetAt(tPane,"Detail")
	}

	Set tPane = ..GetInfoPane(tInstance)	
	If ($IsObject(tPane)) {
		Set tPane.Name = "Info"
		Do tInstance.Panes.SetAt(tPane,"Info")
	}
	
	// assign frame names
	
	Quit tInstance
}

/// Get the title pane info object
ClassMethod GetTitlePane(pInstance As PageInstance) As Pane
{
	Set tTitlePane = ""
	Quit tTitlePane
}

/// Get the navigator pane info object
ClassMethod GetNavigatorPane(pInstance As PageInstance) As Pane
{
	Set tNavigatorPane = ""
	Quit tNavigatorPane
}

/// Get the detail pane info object
ClassMethod GetDetailPane(pInstance As PageInstance) As Pane
{
	Set tDetailPane = ""
	Quit tDetailPane
}

/// Get the info pane info object
ClassMethod GetInfoPane(pInstance As PageInstance) As Pane
{
	Set tInfoPane = ""
	Quit tInfoPane
}

ClassMethod OnPage() As %Status
{
	;If ##class(%SYS.EMS).IsEMSManagerSMP() Quit ##class(%CSP.Portal.Utils).%DrawError($system.Status.Error($$$ERRORCODE($$$EMSNoSMP)))
	If '##class(%CSP.Portal.Utils).%CheckCustomResource($classname($this)) Quit ##class(%CSP.Portal.Utils).%DrawError($system.Status.Error($$$ERRORCODE($$$AccessDenied)))
	Quit ..DrawHTML()
}

/// Draw HTML for this CSP page
ClassMethod DrawHTML() As %Status
{
	// construct a PageInstance object
	Set tPage = $G(%tPageInstance)
	//Set tPage = ..CreatePageInstance() // jmd: now done in preHTTP
	
	If (..#USEFRAMES = 1) {
		If ($G(%request.Data("$FRAME",1)) = "") {
			Do ..DrawFrameSet(tPage)
		}
		Else {
			// draw the page
			&html<<html #($$$HTMLLangAttr)#><head>>
			
			If (..#HYPEREVENTS) {
				// set up hyper-event for this page
				Write ..HyperEventHead(),!
			}
			Do ..DrawAutoLogout()			
			Do ..DrawHEAD(tPage, %request.Data("$FRAME",1))
			&html<</head>>

			&html<<body style="margin:0px; padding: 0px;">>
			Do ..DrawFrameBODY(tPage, %request.Data("$FRAME",1))
			&html<</body></html>>
		}
	}
	Else {
		// draw the page
		&html<<html #($$$HTMLLangAttr)#><head>>
		If (..#HYPEREVENTS) {
			// set up hyper-event for this page
			Write ..HyperEventHead(),!
		}

		Do ..DrawAutoLogout()
		Do ..DrawHEAD(tPage)
		&html<</head>>

		&html<<body style="margin:0px; padding: 0px;" onresize="resizeHandler();" onload="onloadHandler();">>
		Do ..DrawBODY(tPage)

		&html<</body></html>>
	}
	Do ##class(%CSP.Util.AutoPage).RegisterRecent(tPage.Title)
	Quit $$$OK
}

/// Write JavaScript to automatically logout out this page
ClassMethod DrawAutoLogout()
{
	#; wait for session timeout period
	#; then refresh this page; the session *should*
	#; be timed out and thus we should get the login page.
	#; n.b. we add 15 seconds to AppTimeout to make it more likely
	#; that session has timedout
	If (%session.AppTimeout > 0) {
		#;YSD2224 - on the execute query page, do not auto-logout
		
		If ((%request.URL '[ "UtilSqlQuery.csp") ) {
			Set tClassName = ..GetCSPClassName(%request.URL)
			#; No need to add xenAutoLogout() to ZEN pages because they already have zenAutoLogout defined.  PubSub pages checked separately because PageContainer extends %ZEN.Component.abstractPage, but content classes do not
			If '##class(%Dictionary.ClassDefinition).%ExistsId(tClassName)||'($classmethod(tClassName,"%Extends","EnsPortal.PubSub.Utils")||$classmethod(tClassName,"%Extends","%ZEN.Component.abstractPage")) {
				Write "<script type=""text/javascript"">",!
				&html<
				var xenAutoLogoutTimerID = self.setTimeout("xenAutoLogout()",#((%session.AppTimeout+15)*1000)#);
				function xenAutoLogout()
				{
					top.document.location.reload();
				}
				>
				Write "</script>",!
			}
		}
	}
	Do ..DrawShowDoc()
}

/// Write JavaScript for displaying documentation. (Called directly from CSPX.AutoPageCSP.)
ClassMethod DrawShowDoc()
{
	Set helpClass = ##class(%CSP.Page).Link("/csp/docbook/DocBook.UI.Page.cls")

	&html<<script language="javascript">
	
	// launch DocBook window for given ID
	function showDocumentation(topic, anchor,url)
	{
		if (null==url) {
			url = "#(helpClass)#";
		}
		
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
		
		if (topic && ('' != topic)) {
			if (url.indexOf("?") == -1) {
				url += '?';
			} else {
				url += '&';	
			}
			url += 'KEY=' + encodeURIComponent(topic);
		}
		if (anchor && ('' != anchor)) {
			url += '#' + encodeURIComponent(anchor);
		}
		win = window.open(url,'docbook','left='+left+',top='+top+',width='+wid+',height='+hgt+',status,scrollbars,resizable,location=1,toolbar=1,menubar=1');
		win.focus();
	}

	</script>>
}

/// Draw the HEAD section for this page (or frame)
ClassMethod DrawHEAD(pInstance As PageInstance, pFrame As %String = "")
{
	If (pFrame '= "") {
		&html<<!-- Frame: #(pFrame)# -->>
	}

	&html<<title>#($ZCVT(pInstance.Title,"O","HTML"))#</title>>
	
	// make list of ID values for popup URL
	Set tJSID = ""
	Set id = $O(pInstance.IDValues(""))
	While (id '= "") {
		Set tJSID = tJSID _ $S(tJSID="":"",1:"&") _ "$ID" _ id _ "=" _ ..EscapeURL($G(pInstance.IDValues(id)))
		Set id = $O(pInstance.IDValues(id))
	}
	
	&html<<script language="JavaScript">
	
	// invoke resize handler if present
	function resizeHandler()
	{
		if (this.onResizeHandler) {
			this.onResizeHandler();
		}
	}
	
	// called by a frame to goto another page
	function gotoPage(url,frame)
	{
		if (!frame || frame == '') {
			self.top.document.location = url;
		}
		else {
			if (self.top.frames[frame]) {
				self.top.frames[frame].document.location = url;
			}
		}
	}
	
	// invoke a popup lookup dialog !!!
	function doLookup(name,query,column)
	{
		var form = self.document.theForm;
		var ctrl = form[name];
		var value = ctrl.value;
		
	  	var url = '%CSP.Util.LookupDialog.cls?QUERY=' + encodeURIComponent(query) + '&COLUMN=' + encodeURIComponent(column) + '&VALUE=' + encodeURIComponent(value);
		var sFeatures="dialogHeight: 400px; dialogWidth: 600px; dialogTop: " + event.clientY + "px; dialogLeft: " + event.clientX + "px; edge: Sunken; center: Yes; help: No; resizable: Yes; status: No;";
	  	
	  	// use IE Modal Dlg.
		self.showModalDialog(url, ctrl, sFeatures);
	
		return true;
	}

	function launchPopupWindow(page,features,pageName)
	{
		if (features == null) {
			features = "status,scrollbars,resizable";
		}

		var wid = self.screen.width;
		var hgt = self.screen.height;
		/* !!! jmd-- seems to not work!!!
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
		*/
		wid = wid * 0.8;
		hgt = hgt * 0.8;
		var top = self.screen.height * 0.1;
		var left = self.screen.width * 0.1;
	  	var id = #(..QuoteJS(tJSID))#;
	  	var questionmark = page.split("?");
	  	var url;
	  	if (questionmark.length > 1) {
		  	url = encodeURIComponent(questionmark[0]) + "?" + questionmark[1];
		  	url = url + "&" + id;
	  	} else {
		  	url = page + "?" + id;
	  	}
		if (pageName == null) {
			pageName = 'autopagePopup';
		}

		self.autopagePopupWindow = window.open(url,pageName,'left='+left+',top='+top+',width='+wid+',height='+hgt+(features==''?'':','+features));
		self.autopagePopupWindow.focus();
	}

  	// cancel button for end of popup
	function popupCancel()
	{
		if (document.getElementById("zenLaunch").value == 1) {
			firePopupAction('cancel',"",1);
		}
		opener.autopagePopupWindow = null;
		window.close();
		return true;
	}
	
	function firePopupAction(action, value, close)
	{
	// these may contain encoded data
	if ('string' == typeof action) {
		action = decodeURIComponent(action);
	}
	if ('string' == typeof value) {
		value = decodeURIComponent(value);
	}

	// notify our parent component

	// if this is an IE modal dialog, deal with it
	if (window.dialogArguments && window.dialogArguments.popupActionHandler) {
		window.dialogArguments.popupActionHandler(this.popupParent,window.dialogArguments._popupName,action,value);
	}
	else if (window.opener && window.opener.zenPage.popupActionHandler) {
		// use synchronous mode in our parent to avoid FireFox async issues
		var mode = window.opener.zenSynchronousMode;
		window.opener.zenSynchronousMode = true;
		window.opener.zenPage.popupActionHandler(this.popupParent,window.opener.zenPage._popupName,action,value);
		window.opener.zenPopupWindow = null;
		window.opener.zenSynchronousMode = mode;
	}

	// close our window
	if (close) {
		window.close();
	}
	}
	// called by popup when it is finished (ok)
	function updatePage()
	{
		self.document.location.reload();
		return true;
	}
	
	function cspRunServerMethodError(err, errObject)
	{
		var doAlert = true;
		if (errObject) {
			var code = errObject.code;
			var serverCode = errObject.serverCode;
			if ((code == 401) && ((serverCode == 864) || (serverCode == 5918))) {
				if (top && top.document) {
					top.document.location.reload();
				} else {
					self.document.location.reload();
				}
				doAlert = false;
			}
			else if ((#(##class(%CSP.Portal.Utils).%IsConnectivityPopupDisabled())#)&&(code<401)) { // check to see if this was refresh timer related
				var _refreshRate = false;
				if (typeof refreshRate === 'undefined') {
					var timer = self.document.getElementById('refreshRate');
					if (timer) _refreshRate = timer.value;
				}
				else {
					_refreshRate = refreshRate;
				}
				if (_refreshRate ||
				    (typeof refreshCount != 'undefined') || 
				    (typeof autoRefreshRate != 'undefined') || 
				    (typeof refreshInterval != 'undefined') || 
				    (typeof refreshTimerId != 'undefined') ) { //page has defined refresh rate
					cspSetConnectivityStatusMsg(err);
					window.setTimeout('cspSetConnectivityStatusMsg("Re-trying");',60000);
					window.setTimeout('cspTestConnectivity();',60000);
					doAlert = false;
				}
			}
		}
		if (doAlert) {
			alert(err);
		}
		cspXMLHttp = null;
		return null;
	}

	function cspPingHost() {
		var img = new Image();
		img.onload = function () {
			if (top && top.document) {
				top.document.location.reload();
			} else {
				self.document.location.reload();
			}
		};
		img.onerror = function (e) {
			cspRunServerMethodError("Server not responding", {code:0})
		};
		img.src = document.location.origin+'/csp/broker/images/cut.png?rnd='+Math.random(); 
	}

	function cspTestConnectivity()
	{
		cspPingHost();
	}
	
	function cspSetConnectivityStatusMsg(msg)
	{
		if (top && top.document) {
			var span = top.document.getElementById('lostConnectivityWarn');
		} else {
			var span = self.document.getElementById('lostConnectivityWarn');
		}
		if (span) {
			if (msg!='') {
				span.title = msg;
				span.innerHTML = "No Connection";
				span.hidden = false;
			} else {
				span.title='';
				span.innerHTML='';
				span.hidden = true;
			}
		}
	}

	</script>>

	// style sheet
	Set style = ""
	If (pFrame '= "") {
		Set tPane = pInstance.Panes.GetAt(pFrame)
		If ($IsObject(tPane)) {
			Set style = tPane.FrameStyle
		}
	}
	If (style = "") {
		Set style = ..Link("/csp/sys/"_..#STYLESHEET)
	}

	If (style '= "none") { 
		&html<<link rel="stylesheet" type="text/css" href="#(style)#" title="Standard Style" >>
	}

	If (..#FAVORITEICON '= "") {
		&html<<link rel="icon" type="image/ico" href="#(..Link(..#FAVORITEICON))#">>
	}
	
	// get pane objects; ask them to draw their head sections
	Set tTitlePane = pInstance.Panes.GetAt("Title")
	Set tDetailPane = pInstance.Panes.GetAt("Detail")
	Set tNavigatorPane = pInstance.Panes.GetAt("Navigator")
	Set tInfoPane = pInstance.Panes.GetAt("Info")
	
	If (((pFrame="Title") || (pFrame="")) && $IsObject($G(tTitlePane))) {
		Do tTitlePane.DrawHEAD(pInstance)
	}
	If (((pFrame="Navigator") || (pFrame="")) && $IsObject($G(tNavigatorPane))) {
		Do tNavigatorPane.DrawHEAD(pInstance)
	}
	If (((pFrame="Detail") || (pFrame="")) && $IsObject($G(tDetailPane))) {
		Do tDetailPane.DrawHEAD(pInstance)
	}	
	If (((pFrame="Info") || (pFrame="")) && $IsObject($G(tInfoPane))) {
		Do tInfoPane.DrawHEAD(pInstance)
	}
}

/// Draw the BODY section for this page
/// This consists of a number of "panes"
ClassMethod DrawBODY(pInstance As PageInstance)
{
	// get pane objects
	Set tTitlePane = pInstance.Panes.GetAt("Title")
	Set tDetailPane = pInstance.Panes.GetAt("Detail")
	Set tNavigatorPane = pInstance.Panes.GetAt("Navigator")
	
	#; JMD258 (add support for info pane)
	Set tInfoPane = pInstance.Panes.GetAt("Info")
	
	&html<<input type="hidden" name="zenLaunch" id="zenLaunch" value="#($ZCVT($G(%request.Data("zenLaunch",1)),"O","HTML"))#">>

	// Main layout table
	&html<
	<table border="0" class="LayoutMain" width="100%" height="100%" cellpadding="0" cellspacing="0">>
 
	// Title pane
	If ($IsObject($G(tTitlePane))) {
		Do tTitlePane.DrawBODY(pInstance)
	}

	&html<<tr height="100%">>

	// Navigator Pane
	If ($IsObject($G(tNavigatorPane))) {
		&html<<td width="20%" class="LayoutMenuCol">>
		Do tNavigatorPane.DrawBODY(pInstance)
		&html<</td>>
	}

	// Details pane
	If ($IsObject($G(tDetailPane))) {
		&html<<td class="LayoutContentCol" width="80%"><br/>>
		Do tDetailPane.DrawBODY(pInstance)
	}

	// Info pane
	If ($IsObject($G(tInfoPane))) {
		Do tInfoPane.DrawBODY(pInstance)
	}
	&html<</td>>
	&html<</tr></table>>
}

/// Draw frameset for this page (if appropriate)
ClassMethod DrawFrameSet(pInstance As PageInstance) As %Status
{
	&html<<html>
		<head>
		<title>#(pInstance.Title)#</title>>

	Do ..DrawAutoLogout()
	Do ..DrawFrameLayout()

	&html<</head>>
		
	// get pane objects;
	Set tTitlePane = pInstance.Panes.GetAt("Title")
	Set tDetailPane = pInstance.Panes.GetAt("Detail")
	Set tNavigatorPane = pInstance.Panes.GetAt("Navigator")
	Set tInfoPane = pInstance.Panes.GetAt("Info")
	
	Set title = $S($IsObject(tTitlePane):1,1:0)
	Set rows = 0
	Set rows = $S($IsObject(tDetailPane):rows+1,1:rows)
	Set rows = $S($IsObject(tInfoPane):rows+1,1:rows)
	Set nav = $S($IsObject(tNavigatorPane):1,1:0)
	
	// build list of URL parms to pass to frames
	Set k = $O(%request.Data(""))
	While (k '= "") {
		Set tParms(k) = $G(%request.Data(k,1))
		Set k = $O(%request.Data(k))
	}
	
	Set url = ##class(%CSP.Page).Link(..#CSPURL,.tParms)

	// JMD344 -- remove $S
	//Set titleframeheight = $S(..#STYLESHEET="intersystems.css":75,1:100)
	Set titleframeheight = 100

	// !!!assume there is always a title frame & 1+ rows
	If (nav) {

		If ..#STYLESHEET="intersystems.css" Set titleframeheight = titleframeheight + 26
		&html<<frameset rows="#(titleframeheight)#,*" frameborder="yes" frameborder="1" border="2">>
		Set tParms("$FRAME") = "Title"
		Set url = ##class(%CSP.Page).Link(..#CSPURL,.tParms)
		&html<<frame src="#(url)#" name="Title" marginwidth="0" marginheight="0" scrolling="0" frameborder="1" scrolling="no" resize="no">>

		&html<<frameset cols="15%,*" frameborder=yes frameborder=1 border=2>>
		Set tParms("$FRAME") = "Navigator"
		Set url = ##class(%CSP.Page).Link(..#CSPURL,.tParms)
		&html<<frame src="#(url)#" name="Navigator" marginwidth="0" marginheight="0" scrolling="0" frameborder="1" scrolling="no" resize="no">>

		If (rows = 1) {
			&html<<frameset rows="*" frameborder=yes frameborder=1 border=2>>
			Set frurl = $S(tDetailPane.URL="":..#CSPURL,1:tDetailPane.URL)
			Set tParms("$FRAME") = "Detail"
			Set url = ##class(%CSP.Page).Link(frurl,.tParms)
			&html<<frame src="#(url)#" name="Detail" marginwidth="0" marginheight="0" framespacing="0" frameborder="1" scrolling="yes" resize="no">>
			&html<</frameset>>
		}
		ElseIf (rows = 2) {
			&html<<frameset rows="40%,*" frameborder=yes frameborder=1 border=2>>
			Set tParms("$FRAME") = "Detail"
			Set frurl = $S(tDetailPane.URL="":..#CSPURL,1:tDetailPane.URL)
			Set url = ##class(%CSP.Page).Link(frurl,.tParms)
			&html<<frame src="#(url)#" name="Detail" marginwidth="0" marginheight="0" framespacing="0" frameborder="1" scrolling="yes" resize="no">>
			Set tParms("$FRAME") = "Info"
			Set url = ##class(%CSP.Page).Link(..#CSPURL,.tParms)
			&html<<frame src="#(url)#" name="Info" marginwidth="0" marginheight="0" framespacing="0" frameborder="1" scrolling=yes" resize="no">>
			&html<</frameset>>
		}

		&html<</frameset>>
		&html<</frameset>>
	}
	Else {
		If (rows = 1) {
			&html<<frameset id="frameset" onload="restoreLayout();" onbeforeunload="rememberLayout();" rows="#(titleframeheight)#,*" frameborder="yes" frameborder="1" border="2">>
			Set tParms("$FRAME") = "Title"
			Set url = ##class(%CSP.Page).Link(..#CSPURL,.tParms)
			&html<<frame src="#(url)#" name="Title" marginwidth="0" marginheight="0" framespacing="0" frameborder="1" scrolling="no" resize="no">>
			Set tParms("$FRAME") = "Detail"
			Set frurl = $S(tDetailPane.URL="":..#CSPURL,1:tDetailPane.URL)
			Set url = ##class(%CSP.Page).Link(frurl,.tParms)
			&html<<frame src="#(url)#" name="Detail" marginwidth="0" marginheight="0" framespacing="0" frameborder="1" scrolling="yes" resize="no">>
			&html<</frameset>>
		}
		Else {
			Set framesize = "40%,40%"
			If ..#STYLESHEET="intersystems.css" Set titleframeheight = titleframeheight + 26 //, framesize = "50%,30%"
			&html<<frameset id="frameset" onload="restoreLayout();" onbeforeunload="rememberLayout();" rows="#(titleframeheight)#,#(framesize)#" frameborder="yes" frameborder="1" border="2">>
			Set tParms("$FRAME") = "Title"
			Set url = ##class(%CSP.Page).Link(..#CSPURL,.tParms)
			&html<<frame src="#(url)#" name="Title" marginwidth="0" marginheight="0" framespacing="0" frameborder="1" scrolling="no" resize="no">>
			Set tParms("$FRAME") = "Detail"
			Set frurl = $S(tDetailPane.URL="":..#CSPURL,1:tDetailPane.URL)
			Set url = ##class(%CSP.Page).Link(frurl,.tParms)
			&html<<frame src="#(url)#" name="Detail" marginwidth="0" marginheight="0" framespacing="0" frameborder="1" scrolling="yes" resize="no">>
			Set tParms("$FRAME") = "Info"
			Set url = ##class(%CSP.Page).Link(..#CSPURL,.tParms)
			&html<<frame src="#(url)#" name="Info" marginwidth="0" marginheight="0" framespacing="0" frameborder="1" scrolling="yes" resize="no">>
			&html<</frameset>>
		}
	}

	&html<</html>>

	Quit $$$OK
}

/// Draw the BODY section for a specific pane as a frame
ClassMethod DrawFrameBODY(pInstance As PageInstance, pFrame As %String)
{
	// get pane object
	Set tPane = pInstance.Panes.GetAt(pFrame)

	If ($IsObject($G(tPane))) {
		// Main layout table
		&html<<table border="0" class="LayoutMain" width="100%" height="100%" cellpadding="0" cellspacing="0">>
		If (pFrame '= "Title") {
			&html<<tr height="100%">>

			If (pFrame = "Navigator") {
				&html<<td class="LayoutMenuCol">>
			}
			Else {
				&html<<td class="LayoutContentCol">>
			}
		}

		Do tPane.DrawBODY(pInstance)
		If (pFrame '= "Title") {
			&html<</td></tr>>
		}
		&html<</table>>
	}
}

/// Write JavaScript to manage size of frames
ClassMethod DrawFrameLayout()
{
	&html<<script language="javascript">
function restoreLayout()
{
	// restore size of frames from cookie
	// cookie is tied to this page name
	var frameset = self.document.getElementById("frameset");
	if (frameset) {
		var cookie = self.document.location.pathname;
		cookie = encodeURIComponent(cookie.split(".")[0]);
		var r = getCookie2(cookie, "");
		if (r != "") {
			// If size of title frame is larger than 100, reduce it back to original size of 100, because there's no point in it being larger than that.
			// Also contains a workaround to a problem with IE8 that causes Ensemble Portal pages to not be correctly displayed after frames were resized.
			// See HCR089, HCR090, HCR098.
			var title = r.split(",")[0];
			var changed = false;
			if ( (navigator.userAgent).indexOf('MSIE 8',0) > 0 ) {
				if ( title >= 1000 ) {
					title = title/100;
					changed = true;
				}
			}
			if ( title > 100 ) {
				title = 100;
				changed = true;
			}
			if ( changed ) {
				r = title + "," + r.split(",")[1] + "," + r.split(",")[2];
			}
			if ( frameset.rows != r ) {
				frameset.rows = r;
			}
		}
	}
}

function rememberLayout()
{
	// save size of frames to cookie
	var frameset = self.document.getElementById("frameset");
	if (frameset) {
		var cookie = self.document.location.pathname;
		cookie = encodeURIComponent(cookie.split(".")[0]);
	 	self.document.cookie = cookie + '=' + encodeURIComponent(frameset.rows);
	}
}

function getCookie2(name,def)
{
	var value = def; // default value
	var cookies = self.document.cookie;
	var pos = cookies.indexOf(name + '=');
	if (pos != -1) {
		var start = pos + 1 + name.length;
		var end = cookies.indexOf(';',start);
		if (end == -1) end = cookies.length;
		var value = decodeURIComponent(cookies.substring(start,end));
	}

	return value;
}
	</script>>
}

/// Get the list of items for the locator bar as well as the page address.
ClassMethod GetLocator(pTitlePane As TitlePane, ByRef pAddress As %String)
{
	Set tParent = ..#PARENTPAGE
	Set tName = ..GetPageName()
	Set tURL = ..#CSPURL
	Set pAddress = ..#PAGENAME
	
	// get parent page locator
	If (tParent '= "") {
		Set tParentClass = ..GetCSPClassName(tParent)
		If (tParentClass '= "") {
			Do $classmethod(tParentClass,"GetLocator",pTitlePane,.tAddress)
			Set:tAddress'="" pAddress = tAddress _ "," _ pAddress
		}
	}

	Set tLink = ##class(%CSP.Util.Link).%New()
	Set tLink.Caption = tName
	Set tLink.HREF = tURL
	Do pTitlePane.Locator.Insert(tLink)

	Quit $$$OK
}

/// For a given CSP page name, return the actual class name;
/// This method will normalize page names that do not have an application
/// in their URL.
ClassMethod GetCSPClassName(pURL As %String) As %String [ CodeMode = expression ]
{
$System.CSP.GetClassName(pURL,%request.URL)
}

/// Go to specified namespace.
/// Use "" to find a default namespace.
/// Return namespace we actually tried to go to.
ClassMethod ChangeNamespace(ns As %String, mode As %String = "") As %String
{
	Set defns = 0
	If (ns = "") {
		// use default namespace
		Set defns = 1
	}
	Else {
		Set tSC = ..SetNamespace(ns)
		If $$$ISERR(tSC) {
			Set %session.Data("$NSERROR") = ns // report namespace error to page
			Set defns = 1
		}
	}
	
	If (defns) {
		// try all available namespaces until one works!
		// Type = 1, Remote = 1, DontConnect = 1
		If (mode = "implied") {
			#;YSD2101 Do ListImplied^%SYS.NAMESPACE(.list,1,1,1)
			Set cnt = ##class(%CSP.Util.SMNavigatorPane).GetAllDatabases(.list)
		}
		Else {
			Do List^%SYS.NAMESPACE(.list,1,1,1)
		}
		Set ns = $O(list(""))
		While (ns '= "") {
			If mode '= "implied" Set tSC = ..SetNamespace(ns)
			Else  Set tSC = ..SetNamespace(list(ns))
			If $$$ISOK(tSC) Quit
			Set ns = $O(list(ns))
		}
		
		/* note: there is *nothing* we can do if no namespace is available */
	}

	// return actual NS
	Quit ns
}

/// This utility method actually changes namespaces.
/// [Previously private]
ClassMethod SetNamespace(ns As %String) As %Status
{
	Set tSC = $$$OK
	Set $ZT = "Trap"
	#; YSD2040 change namespace only it's different and run sql init code
	If ns '= $namespace {
		ZN ns
		Do ##class(%SQL.Manager.API).SetServerInitCode() 
	}
Done
	Quit tSC
Trap
	Set $ZT = ""
	Set tSC = $$$ERROR($$$GeneralError,$$$Text("Namespace not available"))
	Goto Done
}

/// Return localized version of PageName
ClassMethod GetPageName() As %String [ CodeMode = objectgenerator ]
{
	Do %code.WriteLine(" Quit $$$Text("""_$G(%parameter("PAGENAME"),"N/A")_""")")
	Quit $$$OK
}

/// Called by CSP Action pages to draw the page header
ClassMethod DrawTitle(tTitle As %String) As %Status
{
	&html<
	<div class="toolRibbon ribbonTitle">
		&nbsp;#($ZCVT($ZCVT(tTitle,"I","HTML"),"O","HTML"))#</span>
	</div>
	>
	Quit $$$OK
}

ClassMethod RegisterRecent(tTitle As %String) [ Language = objectscript ]
{
	/// Recent item is only registered at the Home level.
	/// This method maybe called by CSP pages
	If $G(%request.Data("Recent",1)) = "" Quit
	Try {
		Set tData = ""
		For n=1:1 {
			Set tData = $O(%request.Data(tData))
			Quit:tData=""
			Set tValue = $G(%request.Data(tData,1))
			Set tQuery(tData) = tValue
		}
		Set tURL = ..Link(%request.URL,.tQuery)
		// Swallow error if method not defined
		Set tSC = ##class(%CSP.Portal.Utils).%RegisterRecentItem(tTitle,tURL)
	} Catch(ex) {
	}
}

}
