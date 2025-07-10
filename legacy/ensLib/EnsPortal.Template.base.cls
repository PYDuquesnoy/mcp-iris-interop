/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsPortal.Template.base [ Abstract, System = 4 ]
{

Parameter DOMAIN = "Ensemble";

/// Control whether we use a KeepAlive in subclasses of this page.</br>
/// [DEPRECATED] - the InterSystems IRIS UI now uses a lookup against 
/// <code>^EnsPortal("DisableInactivityTimeout","Portal")</code> for EnsPortal pages in Management Portal
Parameter USEKEEPALIVE As BOOLEAN = 0;

/// The interval in milliseconds at which keepalive events should be triggered.
/// The value is determed in the <method>GetKeepAliveInterval</method>() method.
Property keepAliveInterval As %ZEN.Datatype.integer [ InitialExpression = {..GetKeepAliveInterval() * 1000} ];

/// Start the client keepalive.
ClientMethod startKeepAlive() [ Language = javascript ]
{
	if ((this.keepAliveInterval > 0) && !this._keepAliveTimer) {
		this._keepAliveTimer = window.setInterval("zenPage.clientKeepAlive();",this.keepAliveInterval);
	}
}

/// Stop the client keepalive.
ClientMethod stopKeepAlive() [ Language = javascript ]
{
	if (this._keepAliveTimer) {
		window.clearInterval(this._keepAliveTimer);
		this._keepAliveTimer = null;
	}
}

/// Simple call back to the server.
ClientMethod clientKeepAlive() [ Language = javascript ]
{
	if (this.keepAliveInterval > 0) {
		var simpleString = this.SimpleKeepAlive('');
	}
}

/// Simple method for the client to call.
ClassMethod SimpleKeepAlive(pString As %String = "") As %String [ ZenMethod ]
{
	Quit " "
}

/// By default, this method returns 0 to indicate that no keepalive is in use.
/// The default value is 30 seconds less than the CSP application timeout, but this is reduced to 2 seconds less than the timeout if the timeout is
/// less than 60 seconds.
ClassMethod GetKeepAliveInterval() As %Integer [ Private ]
{
	If '$isobject($get(%session)) {
		Quit 0
	}

	Set tUseKeepAlive = ..UseKeepAlive()
	If ('tUseKeepAlive) {
		Quit 0
	}
	
	Quit $select(%session.AppTimeout < 60: %session.AppTimeout - 2, 1: %session.AppTimeout - 30)
}

/// Helper method to determine whether the current page should use a keepalive instead of logging
/// users out after a period of inactivity.
ClassMethod UseKeepAlive() As %Boolean [ Private ]
{
	Quit ''$get(^EnsPortal("DisableInactivityTimeout","Portal"),0)
}

/// Helper method to allow pages to detect when they are in a resize loop under IE8.
ClientMethod inResizeLoop() [ Language = javascript ]
{
	if (zenIsHTML5 || !zenIsIE) return false;
	if (!this._resizeHistory) this._resizeHistory = [];
	var currWidth = zenGetWindowWidth();
	var currHeight = zenGetWindowHeight();
	if (this._resizeHistory.length >= 4) {
		var check = this._resizeHistory[this._resizeHistory.length - 1];
		if ((currWidth == check.width) && (currHeight == check.height)) {
			return true;
		}
		check = this._resizeHistory[this._resizeHistory.length - 2];
		if ((currWidth == check.width) && (currHeight == check.height)) {
			return true;
		}
		this._resizeHistory.splice(0,1);
		this._resizeHistory.push( { "width": currWidth, "height": currHeight } );
	}
	else {
		this._resizeHistory.push( { "width": currWidth, "height": currHeight } );
	}
	return false;
}

ClientMethod initPopupSuffix() [ Language = javascript ]
{
	if (typeof this._popupSuffix == 'undefined') {
		this._popupSuffix = '_Ens' + (new Date().getTime());
	}
}

/// Add a suffix to the popup name to avoid name collisions.
ClientMethod addPopupSuffix(popupName) [ Language = javascript ]
{
	return popupName + this._popupSuffix;
}

/// Strip the suffix from a popup name created by <method>addPopupSuffix</method>().
ClientMethod removePopupSuffix(popupName) [ Language = javascript ]
{
	var pos = popupName.toString().indexOf(this._popupSuffix);
	if (pos > -1) return popupName.substring(0,pos);
	return popupName;
}

/// Override onServerMethodError to funnel HyperEvent errors through the
/// central exception handling code.
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
				EnsException.hyperEventHandler(errObject,err);
			}
		}
	}
	return true;
}

/// Add a modified version of cspIntHttpServerMethod to the page to force
/// hyperevents to specify CSPSHARE in requests to the server.
ClassMethod %AddCSPShareHyperevents() As %Status
{
	&html<<script type="text/javascript">
function studioIntHttpServerMethod(method, args, async)
{
	var arg;
	var i;
	var url = "%25CSP.Broker.cls";
	var n;
	var req;

	var data = "CSPSHARE=1&WARGC=" + (args.length - 1) + "&WEVENT=" + method.replace(/&amp;/g,'&');
	// check for missing CSPCHD
	if (data.indexOf('&CSPCHD=') < 0) {
		var cspToken = '';
		var currParms = self.document.location.search.substring(1).split('&');
		for (var j = 0; j < currParms.length; j++) {
			var pair = currParms[j].split('=');
			if ((pair[0] == 'CSPCHD') && pair[1]) {
				cspToken = pair[1];
				break;
			}
		}
		if (cspToken != '') data += '&CSPCHD=' + cspToken;
	}
	for (i = 1; i < args.length; i++) {
		arg = args[i];
		if (typeof arg != "object") {
			// Convert boolean to server format value before sending
			if (typeof arg == "boolean") arg = (arg ? 1 : 0);
			data = data + "&WARG_" + i + "=" + encodeURIComponent(arg);
		} else if (arg != null) {
			n = 0;
			for (var el in arg) {
				if (typeof arg[el] != "function") {
					data = data + "&W" + i + "=" + encodeURIComponent(arg[el]);
					n = n + 1;
				}
			}
			data = data + "&WLIST" + i + "=" + n;
		}
	}

	try {
		req=cspXMLHttp
		if (async) {
			if (cspMultipleCall) {
				if (cspActiveXMLHttp == null) cspActiveXMLHttp = new Array();
				cspActiveXMLHttp[cspActiveXMLHttp.length] = req;
				req.onreadystatechange = cspProcessMultipleReq;
			} else {
				req.onreadystatechange = cspProcessReq;
			}
		}
		cspXMLHttp = null;
		if (cspUseGetMethod) {
			req.open("GET", url+"?"+data, async);
			if (cspMozilla) {
				req.send(null);
			} else {
				req.send();
			}
		} else {
			req.open("POST", url, async);
			req.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
			req.send(data);
		}
	} catch (e) {
		var err=new cspHyperEventError(400,'Http object request failed, unable to process HyperEvent.',null,'',e);
		return cspHyperEventErrorHandler(err);
	}

	if (async) {
		return null;
	}

	return cspProcessResponse(req);
}
</script>>
	Quit $$$OK
}

/// Add centralised error handling for standard pages and dialogue windows.
ClassMethod %AddEnsExceptionHandler(pIsModal As %Boolean = 0) As %Status
{
	&html<<style type="text/css">
.ensExceptionModalGroup {
	padding: 0px;
	background-color: white;
}
.ensExceptionModalGroup div.modalGroupTitle {
	background-color: #356B8D;
}
.ensExceptionModalGroup div.modalGroupTitle td{
	font-size: 9pt;
}
#EnsException_Details {
	margin-top: 5px;
	overflow: auto;
	font-size: 10pt;
}
.EnsException_Detail {
	border: 1px solid gray;
	border-radius: 4px;
	padding: 5px;
	overflow: auto;
}
.EnsException_DetailsHeader {
	font-size: 11pt;
	font-weight: bold;
	/*text-decoration: underline;*/
}
#EnsException_Details_expando {
	color: #356B8D;
	border: 1px solid gray;
	border-radius: 4px;
	padding: 2px;
	font-size: 11pt;
}
#EnsException_Details p {
	margin: 0px;
}
#EnsException_Details span.header {
	font-weight: bold;
}
.EnsExceptionContent {
	background-color: #DEDDD8;
	border-radius: 4px;
	padding: 5px;
}
</style>
<script type="text/javascript">
var EnsException = {
	"queue": [],
	"currentError": null,
	"count": 0,
	"htmlIndex": null,
	"modalGroup": null,
	"hyperEventHandler": function(errObj,errMsg) {
		var newError = { "type": "hyperevent", "errObj": errObj, "message": errMsg, "content": '', "location": self.document.location };
		var topWin = ( window && window.top ? window.top : window);
		var exHandler = ( topWin && topWin.EnsException ? topWin.EnsException : EnsException ); 
		newError.content = exHandler.getDetailContent(newError);
		exHandler.count++;
		if (!exHandler.currentError) {
			exHandler.currentError = newError;
			exHandler.displayText();
		}
		else {
			exHandler.queue.push(newError);
		}
	},
	"exceptionHandler": function(ex, args, msg) {
		var newError = { "type": "exception", "exception": ex, "args": args, "message": msg, "content": '', "location": self.document.location };
		var topWin = ( window && window.top ? window.top : window);
		var exHandler = ( topWin && topWin.EnsException ? topWin.EnsException : EnsException ); 
		newError.content = exHandler.getDetailContent(newError);
		if (window.zenPage && (typeof window.zenPage.onEnsException == 'function')) window.zenPage.onEnsException();
		exHandler.count++;
		if (!exHandler.currentError) {
			exHandler.currentError = newError;
			exHandler.displayText();
		}
		else {
			exHandler.queue.push(newError);
		}
	},
	"options": [#($select(pIsModal: "{ ""action"": 'close', ""text"": '"_$$$TextJS("Close")_"', ""title"": '"_$$$TextJS("Close this popup")_"' }", 1: "{ ""action"": 'reload', ""text"": '"_$$$TextJS("Reload")_"', ""title"": '"_$$$TextJS("Refresh the page")_"' }"))#,
			{ "action": 'ignore', "text": '#($$$TextJS("Continue"))#', "title": '#($$$TextJS("Try to continue with the page"))#' }],
	"displayText": function() {
		var action = 'ignore';
		var text = [];
		// Note that we look at the queue to determine what number to display
		this._currLength = 1 + this.queue.length;
		if (this._currLength > 1) {
			text.push('#($$$TextJS("InterSystems IRIS has encountered %1 errors loading this page."))#'.replace(/%1/g,this._currLength));
		}
		else {
			text.push('#($$$TextJS("InterSystems IRIS encountered an error while loading this page."))#');
		}
		text.push('#($$$TextJS("The page is not behaving as expected."))#');
		text.push('#($select(pIsModal: $$$TextJS("Do you want to close the dialog?"), 1: $$$TextJS("Do you want to reload the page?")))#');
		
		this.modalGroup = null;
		try {
			if (self.document.getElementById('zenMouseTrap') && zenPage && zenPage.createComponent) {
				if (zenPage && zenPage.createComponent) {
					var exGroup = zenPage.createComponent('modalGroup');
					if (exGroup) {
						var html = zenPage.createComponent('html');
						if (html) {
							exGroup.addChild(html);
							exGroup.onhideGroup = "EnsException.endDisplay('');";
							exGroup.onshowGroup = "EnsException.modalShow();";
							exGroup.onDelete = EnsException.modalDelete;
							exGroup.id = 'EnsException_Modal';
							// override refreshContents() to ensure we don't call back to the server
							html.refreshContents = function() {
								var div = this.getEnclosingDiv();
								if (div) div.innerHTML = this.content;
							};
							this.modalGroup = exGroup;
							this.htmlIndex = html.index;
						}
					}
				}
			}
		}
		catch (ex) {}
		if (!this.modalGroup) {
			var reload = confirm(text.join('\n'));
			var pos = reload ? 0 : 1;
			action = this.options[pos].action;
			this.doAction(action);
		}
		else {
			var htmlComp = zenIndex(this.htmlIndex);
			htmlComp.content = '';
			var html = [];
			html.push('<div class="EnsExceptionContent"><div>');
			html.push(text.join('</div><div>'));
			html.push('</div>');
			for (var i=0; i<this.options.length; i++) {
				var opt = this.options[i];
				var buttonHTML = '<a id="EnsException_Button_'+opt.action+'" class="commandButton" href="#" style="line-height:48px;" ';
				buttonHTML += 'onclick="EnsException.doAction(\''+opt.action+'\'); return false;"';
				if (opt.title) buttonHTML += ' title="' + opt.title + '"';
				buttonHTML += '><nobr>'+opt.text+'</nobr></a>&nbsp;&nbsp;';
				html.push(buttonHTML);
			}
			html.push('<div><a id="EnsException_Details_expando" href="#" onclick="EnsException.displayDetails(); return false;">>>#($$$TextJS("Show Details"))#</a><div id="EnsException_Details" style="display: none;"></div></div>');
			html.push('</div>');
			
			htmlComp.content = html.join('');
			var width = parseInt(zenGetWindowWidth()*0.4,10);
			var height = parseInt(zenGetWindowHeight()*0.6,10);
			var top = parseInt((zenGetWindowHeight()-height)/2,10);
			var left = parseInt((zenGetWindowWidth()-width)/2,10);
			this.modalGroup.show('#($$$TextJS("Error"))#','dynamic','',top,left,width,height);
		}
		
	},
	"doAction": function(action) {
		if (action == 'reload') {
			if (zenPage.setModified) zenPage.setModified(false);
			setTimeout('document.location.reload();',100);
			return;
		}
		else if (action == 'close') {
			if (zenPage.setModified) zenPage.setModified(false);
			setTimeout('window.close();',100);
			return;
		}
		zenPage.endModal();
	},
	"endDisplay": function() {
		// dequeue all errors reported/displayed to the user
		this.currentError = this.queue.shift();
		while (this._currLength > 1) {
			this._currLength--;
			this.currentError = this.queue.shift();
		}
		if (this.currentError) this.displayText();
	},
	"displayDetails": function() {
		var detailsExpando = document.getElementById('EnsException_Details_expando');
		var detailsDiv = document.getElementById('EnsException_Details');
		
		if (detailsDiv.innerHTML == '') {
			var html = [];
			html.push(this.currentError.content);
			for (var i = 0; i<this._currLength-1; i++) {
				var exObj = this.queue[i];
				html.push(exObj.content);
			}
			detailsDiv.innerHTML = html.join('');
		}
		if ((detailsDiv.innerHTML == '') || (detailsDiv.style.display == 'none')) {
			detailsExpando.innerHTML = zenEscapeXML('<<')+'#($$$TextJS("Hide Details"))#';
			var floatingDiv = this.modalGroup.getFloatingDiv();
			if (floatingDiv) {
				var titleHeight = 0;
				var bodyHeight = 0;
				for (var i=0; i<floatingDiv.children.length; i++) {
					var child = floatingDiv.children.item(i);
					var childClass = ''+child.className;
					if (childClass.indexOf('modalGroupBody') != -1) {
						bodyHeight = child.offsetHeight;
					}
					else if (childClass.indexOf('modalGroupTitle') != -1) {
						titleHeight = child.offsetHeight;
					}
					if ((bodyHeight > 0) && (titleHeight > 0)) break;
				}
				var detailsHeight = floatingDiv.offsetHeight - titleHeight - bodyHeight - 8;
				detailsDiv.style.height = detailsHeight + 'px';
				
			}
			detailsDiv.style.display = 'block';
		}
		else {
			detailsExpando.innerHTML = zenEscapeXML('>>') + '#($$$TextJS("Show Details"))#';
			detailsDiv.style.display = 'none';
		}
	},
	"getDetailContent": function(exObj) {
		if (exObj.content != '') return exObj.content;
		
		var content = '<div class="EnsException_Detail">';
		var headerText = '';
		switch(exObj.type) {
			case 'exception':
				headerText = '#($$$TextJS("Exception Details"))#';
				break;
			case 'hyperevent':
				headerText = '#($$$TextJS("HyperEvent Error Details"))#';
				break;
			default:
				headerText = '#($$$TextJS("Error Details"))#';
				break;
		}
		content += '<span class="EnsException_DetailsHeader">' + zenEscapeHTML(headerText) + '</span>';
		var text = [];
		if (exObj.type == 'exception') {
			var ex = exObj['exception'];
			var args = exObj['args'];
			var msg = exObj["message"];
			var location = zenEscapeHTML(''+(exObj["location"] ? exObj["location"] : self.document.location));
			var fname = '<unknown>';
			try { // ensure we handle strict ECMA engines which may not permit access to arguments.callee
				if (args && args.callee) {
					if (args.callee.name) {
						fname = args.callee.name;
					}
					else if (args.callee.name != '') { // ie
						var n = args.callee.toString().split('(');
						if (n && (n.length > 0) && (n[0].toString().replace(/^\s*|\s*$/g,'') != 'function')) {
							var tmpFuncName = n[0].toString();
							if (tmpFuncName.substring(0,9) == 'function ') tmpFuncName = tmpFuncName.substring(9);
							if (tmpFuncName !== '') fname = tmpFuncName;
						}
					}
				}
			}
			catch (nameEx) {}
			text.push(zenEscapeHTML('#($$$TextJS("A JavaScript exception was caught in function '%1'"))#'.replace(/%1/g,fname)));
			text.push('<strong>' + zenEscapeHTML(ex.name) + ': ' + zenEscapeHTML(ex.message) + '</strong>');
			text.push('<strong>' + zenEscapeHTML('#($$$TextJS("Location"))#') + ':</strong> ' + location);
			if (null!=msg && ''!=msg) {
				text.push('====================================');
				text.push(zenEscapeHTML(msg));
			}
			text.push('====================================');
			text.push('<strong>' + zenEscapeHTML('#($$$TextJS("Stack trace"))#') + ':</strong>');
			var stackTrace = zenStackTrace(args);
			stackTrace = stackTrace.split('\n');
			var entry = stackTrace.shift();
			while (entry != null) {
				text.push(zenEscapeHTML(entry));
				var entry = stackTrace.shift();
			}
		}
		else if (exObj.type == 'hyperevent') {
			var hyperEvtError = exObj.errObj;
			text.push('<strong>' + zenEscapeHTML('#($$$TextJS("HTTP Code"))#') + ':</strong> ' + hyperEvtError.code);
			var msg = (''+zenEscapeHTML(exObj.message)).split('\n');
			text.push('<strong>' + zenEscapeHTML('#($$$TextJS("Error"))#') + ':</strong> ' + msg.shift());
			for (var i=0; i<msg.length; i++) { text.push(msg[i]); }
			if (hyperEvtError.serverCode) text.push('<strong>' + zenEscapeHTML('#($$$TextJS("Server Code"))#') + ':</strong> ' + zenEscapeHTML(hyperEvtError.serverCode));
			if (hyperEvtError.serverText) text.push('<strong>' + zenEscapeHTML('#($$$TextJS("Server Text"))#') + ':</strong> ' + zenEscapeHTML(hyperEvtError.serverText));
		}
		else {
			text.push('Unknown error');
		}
		content += '<p>'+text.join('</p><p>')+'</p>';
		content += '</div>';
		return content;
	},
	"modalShow": function() {
		// add ensExceptionModalGroup to class for floating div
		var modalGroup = EnsException.modalGroup;
		if (modalGroup) {
			var div = modalGroup.getFloatingDiv();
			if (div) div.className += ' ensExceptionModalGroup';
		}
		// override default behaviour -- user must make a choice
		var mouseTrap = document.getElementById('zenMouseTrap');
		if (mouseTrap) mouseTrap.onmouseup = null;
	},
	"modalDelete": function() {
		// clean up floating div
		var modalGroup = EnsException.modalGroup;
		if (modalGroup) {
			var div = modalGroup.getFloatingDiv();
			if (div && div.parentNode) {
				div.parentNode.removeChild(div);
			}
		}
	}
}
window.zenUserExceptionHandler = EnsException.exceptionHandler;
</script>>
	Quit $$$OK
}

}
