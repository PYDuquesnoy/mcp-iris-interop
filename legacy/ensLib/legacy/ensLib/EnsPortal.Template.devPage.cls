/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

/// Template for pages which need to be able to interact with Source Control hooks.
/// This class extends the basic source control interactions implemented in <class>%CSP.Portal.SourceControl.Base</class>, which 
/// should be the primary reference for implementing pages that need to interact with source control hooks.
Class EnsPortal.Template.devPage Extends (EnsPortal.Template.standardPage, %CSP.Portal.SourceControl.Base, %ZEN.Component.dataView) [ Abstract, System = 4 ]
{

Parameter MANAGERDIALOG = "EnsPortal.Dialog.SourceControlManager.zen";

Parameter OUTPUTDIALOG = "EnsPortal.Dialog.SourceControlOutput.zen";

Property studioMode As %ZEN.Datatype.boolean(ZENURL = "STUDIO");

/// onnotifyView event handler:
/// This event is fired when a dataController connected to this dataView
/// raises an event.
Property onnotifyView As %ZEN.Datatype.eventHandler [ InitialExpression = "zenPage.onDocumentReload(reason)" ];

/// If true, create a NEW document.
Property isNew As %Boolean(ZENURL = "NEW") [ InitialExpression = 0, Internal ];

/// Flag to keep record of whether the document was readOnly before a source control action was invoked
Property wasReadOnly As %Boolean [ InitialExpression = 0, Internal ];

Property msgDocReadOnly As %ZEN.Datatype.caption [ InitialExpression = {$$$TextJS("This document is read only")} ];

Property tipSave As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save this document")} ];

Property tipCompile As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Compile this document into executable code")} ];

Property tipNew As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Create a new document")} ];

Property tipOpen As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Load an existing document")} ];

Property tipSaveAs As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save this document with a new name")} ];

Property tipGen As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Save this document and generate classes")} ];

Property tipDelete As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Delete the current document")} ];

Property tipImport As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Import a document from a file")} ];

Property tipImportLegacy As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Import a document from a file that was exported in legacy format")} ];

Property tipExport As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Export the current document to a file")} ];

Property tipCSVWizard As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Create a new document from a sample")} ];

Property tipContractAll As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Contract the diagram")} ];

Property tipExpandAll As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("Expand the diagram")} ];

/// This Style block contains CSS style definitions common to all subpages
XData Style
{
<style type="text/css">

.reIconDisabled {
	opacity:0.40;
}

</style>
}

/// Use <method>%DrawSourceControlCommands</method>() to render the extra source control options in the tool ribbon.
Method OnDrawRibbon() As %Status
{
	Quit ..%DrawSourceControlCommands()
}

/// Determine whether source control is enabled and ensure
/// we don't write out the session cookie if we are running in Studio mode.
Method %OnAfterCreatePage() As %Status
{
	Set ..sourceControlEnabled = ('..studioMode) && ..IsEnabled($namespace)
	If ..studioMode {
		Set %session.Data("Ensemble","StudioSession",$namespace) = 1
		Set %response.OutputSessionToken = 0
	}
	Quit ##super()
}

/// Add check to ensure that we correctly load documents on the client when source control hooks are in use.
/// Also set up a timer to ensure we don't hit timeouts while editing documents in Studio, as well as
/// When in Studio mode, also detect whether we are running IE10, as we need to save documents differently if that
/// is the case.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',arguments);
	if (this.studioMode) {
		this.initializeTextMonitor();
		// If we are running in Studio mode, ensure that we clear the Zen AutoLogout timer
		if (zenAutoLogoutTimerID) {
			self.clearTimeout(zenAutoLogoutTimerID);
			zenAutoLogoutTimerID = null;
		}
	}
	else {
		this.initializeSourceControl();
		// Make sure we check for read-only if we are in the portal and there isn't source control
		if ((!this.studioMode) && (!this.sourceControlEnabled) && (!this._documentLoaded)) {
			this.updateDocumentState(true);
		}
	}
	this.checkStudioHyperEvents();
	this._isIE10 = false;
	/* DDP870 - we now force IE10 to use the IE9 rendering engine
	if (this.studioMode && zenIsHTML5 && zenIsIE) {
		var userAgent = navigator.userAgent.toString();
		this._isIE10 = (6 <= parseInt(userAgent.substring(userAgent.toUpperCase().indexOf('TRIDENT/') + 'Trident/'.length),10));
	}
	*/
	
	// if defined, connect to dataController
	this.setControllerId(this.getClientModel().id);

	// check if file marked readOnly by source control in studio mode
	if (this.studioMode && zenPage.IsDocReadOnly()) {
		this.readOnly = 2;
	}
}

/// Get the title string to add to the locator row.
/// This should be implemented in a subclass.
ClientMethod getPageTitle() As %String [ Language = javascript ]
{
	return this.getCurrentName();
}

/// Set <property>readOnly</property> to the value of <var>readOnly</var>.
/// Subclasses MUST implement this method to update the controls on the page
/// so that the page's behaviour actually matches the value of the readOnly flag.
ClientMethod setReadOnly(readOnly) [ Language = javascript ]
{
	this.readOnly = !!readOnly;
}

/// Test if the user has write privilege.
ClientMethod canUserModify(saveAs) [ Language = javascript ]
{
	if (!this.checkEdit()) return false;
	if (this.readOnly && !saveAs) {
		alert(this.msgDocReadOnly);
		return false;
	}
	return true;
}

/// Gray out ribbon buttons 'Save', 'Save As', 'Compile', and 'Delete'.  Invoked in case of read-only mode.
ClientMethod grayOutButtons() [ Language = javascript ]
{
	this.grayOutOneButton('command_cmdSave');
	this.grayOutOneButton('command_cmdCompile');
	this.grayOutOneButton('command_cmdDelete');
	this.grayOutOneButton('command_cmdSaveGen');
	this.grayOutOneButton('command_cmdGen');
}

ClientMethod grayOutOneButton(buttonId) [ Internal, Language = javascript ]
{
	var btn = document.getElementById(buttonId);
	if (btn) {
		try {
			btn.className = 'commandButtonDisabled';
			btn.onclick = '';
			btn.title = this.msgDocReadOnly;
		}
		catch (ex) {
		}
	}
}

ClientMethod getIsReadOnly() As %Boolean [ Language = javascript ]
{
	var readOnly = (!this.canEdit || zenPage.IsDocReadOnly());
	if (!readOnly) {
		var model = this.getClientModel();
		if (model) {
			var json = model.getContentObject();
		}
		readOnly = (model&&json&&(json.ReadOnly==1));
	}
	return readOnly;
}

ClientMethod toggleReadOnly() [ Language = javascript ]
{
	var before = zenPage.wasReadOnly;
	var readOnly = zenPage.getIsReadOnly();
	
	// Don't disable editor unless the state we compute now differs from what we computed immediately before the source control action was performed.
	// Doing this reduces the possibility that a source control action elsewhere leaves us with a document that can't be saved because it is structurally incomplete.
	// If this does happen, user can attempt a Save As.
	if ((!readOnly) || (readOnly != before)) {
		zenPage.setReadOnly(readOnly);
	} else {
		zenPage.grayOutButtons();
	}
}

Method IsDocReadOnly() As %Boolean [ ZenMethod ]
{
	Quit ..IsSourceControlReadOnly(..GetInternalName())
}

ClientMethod checkStudioHyperEvents() [ Language = javascript ]
{
	if (this.studioMode && window.cspIntHttpServerMethod && window.studioIntHttpServerMethod && !this._forceHypereventShare) {
		window.cspIntHttpServerMethod = window.studioIntHttpServerMethod;
		this._forceHypereventShare = true;
	}
}

/// Note that special handling is required for the LOADCOMPLETE event.
/// We need to ensure that Studio gets the LOADCOMPLETE event, as well as updating the
/// document title later to ensure the correct reload behaviour.
/// The timeout is extra-long for IE9 and up because the main page's onload() sequence may be
/// triggered before the SVG is fully loaded, so we need to build in enough time to let the
/// SVG load before we update the title.
ClientMethod raiseEvent(type, value) [ Language = javascript ]
{
	if (!this.studioMode) {
		return;
	}

	var sendEvent = false;
	switch (type) {
		case 'MODIFIED':
		case 'NOTMODIFIED':
		case 'CANUNDO':
		case 'LOADCOMPLETE':
			sendEvent = true;
			break;
	}
	if (!sendEvent) {
		return;
	}
	if (!this._studioCounter) {
		this._studioCounter = 0;
	}
	
	var eventString = type +':'+this._studioCounter++;
	document.title = eventString;
	if (type == 'LOADCOMPLETE') {
		// ensure title isn't left as LOADCOMPLETE to avoid faulty behaviour during reload.
		var delay = 200;
		setTimeout("zenPage.fixDocumentTitle();",delay);
	}
}

ClientMethod fixDocumentTitle() [ Language = javascript ]
{
	if (this.studioMode) document.title = zenPage.StdTitle + ':' + zenPage._studioCounter++;
}

/// Callback to return a list of resources required for a specific HyperEvent.
/// The user must have sufficient privileges on one of the resource/permission pairs
/// to be permitted to execute the hyperevent. An empty string implies the user already
/// has sufficient privileges for the ZenMethod specified in <var>pMethod</var>.
ClassMethod GetHyperEventResources(pMethod As %String = "") As %String
{
	Quit $case(pMethod,
				"DocumentSave": ..#EDITRESOURCE,
				"CreateProject": ..#EDITRESOURCE,
				: "")
}

/// Set the modified flag for the page.
ClientMethod setModified(flag) [ Language = javascript ]
{
	if (!this.studioMode) {
		this.invokeSuper('setModified',[flag]);
	}
	else {
		this.pageModified = flag;
		var evtName = (flag ? 'MODIFIED' : 'NOTMODIFIED');
		this.raiseEvent(evtName, flag);
	}
}

/// Set data into the results element for Studio.
/// Note that <var>usingDOMElement</var> should only be true under IE10.
ClientMethod setResultsDiv(type, value, usingDOMElement) [ Language = javascript ]
{
	var setResult = false;
	switch (type) {
		case 'MODIFIED':
		case 'SAVE':
		case 'ZOOM':
		case 'CUT':
		case 'COPY':
			setResult = true;
	}
	if (!setResult) { return; }
	
	var div = document.getElementById('results');
	if (div) {
		if (!usingDOMElement) {
			div.innerHTML = value;
		}
		else {
			while (div.firstChild) {
				div.removeChild(div.firstChild);
			}
			div.appendChild(value);
		}
	}
}

ClientMethod escapeCData(text) [ Language = javascript ]
{
	if (text && ('' != text) && (text != text*1)) {
		text = text.replace(/]]>/g,']]]]><![CDATA[>');
	}
	return text;
}

/// Helper method to hide or show SVG elements when opening a popup.
/// This is primarily to ensure that we don't run into issues with IE and
/// the Adobe plugin when the popup window also uses SVG.
ClientMethod toggleSVGElements(show) [ Language = javascript ]
{
}

Method %OnDrawHTMLHead() As %Status
{
	Set tSC = ##super()
	If $$$ISERR(tSC) Quit tSC
	
	Set tSC = ..%DrawSourceControlHead()
	If $$$ISERR(tSC) Quit tSC

	// Specific check for IE versions using the Adobe plugin, as it manages SVG diagrams in popups very poorly
	&html<<script type="text/javascript">
zenDialog_onEndModalHandler = function() {
	if (isAdobeSVG) setTimeout('zenPage.toggleSVGElements(true);',150);
};
zenDialog_onStartModalHandler = function(zindex)
{
	if (isAdobeSVG) zenPage.toggleSVGElements(false);
}
var isAdobeSVG = (zenIsIE && !zenIsHTML5);
</script>>

	If ..studioMode {
		Set tSC = ..%AddCSPShareHyperevents()
		If $$$ISERR(tSC) Quit tSC

		&html<<script type="text/javascript">

function document_isModified() {
	var isModified = zenPage.pageModified ? 1 : 0;
	zenPage.setResultsDiv('MODIFIED', isModified);
}

function document_onLoseActiveFocus() {
	if (zenPage && zenPage.checkTextControls) {
		zenPage.checkTextControls();
	}
}

function document_onBeforeCompile() {
	if (zenPage && zenPage.checkTextControls) {
		zenPage.checkTextControls();
	}
	document_isModified();
}

function document_onBeforeClose() {
	if (zenPage && zenPage.checkTextControls) {
		zenPage.checkTextControls();
	}
}

// Studio intercepts the edit control keys ^C ^V ^X Del ^Z ^A.
// The functions below are invoked by Studio when these keys are pressed,
// to handle them and update the diagram if needed.

var invokeShapeCallbacks = false;

function document_getActiveElement() {
	var objElem = new Object();
	if (document.activeElement instanceof HTMLIFrameElement) {
		objElem.isiframe = true;
		var iframe = document.activeElement;
		var innerDoc = iframe.contentDocument || iframe.contentWindow.document;
		var active = innerDoc.activeElement;
	}
	else {
		objElem.isiframe = false;
		var active = document.activeElement;
	}
	objElem.active = active;
	objElem.zenid = getZenAttribute(active);
	if (active && active.type && (active.type=='text' || active.type=='textarea')) {
		objElem.isinput = true;
	}
	else {
		objElem.isinput = false;
	}
	return objElem;
}

function getZenAttribute(elem,level) {
	if (!level) {
		var level = 0;
	}
	if (level < 10 && elem && elem.parentNode) {
		if (elem.parentNode.getAttribute && elem.parentNode.getAttribute('zen')) {
			return elem.parentNode.getAttribute('zen'); // Found it
		}
		else {
			return getZenAttribute(elem.parentNode,level+1); // Look one level up
		}
	}
	else {
		return null; // Give up
	}
}

function document_getRange(ctrl) {
	var range = null;

	if (document.activeElement instanceof HTMLIFrameElement) {
		var iframe = document.activeElement;
		var win = iframe.contentWindow;
		var doc = iframe.contentDocument || win.document;
	}
	else {
		var win = window;
		var doc = window.document;
	}

    if (doc) {
		if (doc.selection) {
            // IE-specific
            return doc.selection.createRange();
        }
    }

	return range;
}

function document_findPositions(ctrl,range) {
	// IE-specific
	var pos = { start: 0, end: 0 };
	var controlRange = ctrl.createTextRange();
	var bookmark = range.getBookmark()
	controlRange.moveToBookmark(bookmark);
	
	var normalizedVal = ctrl.value.replace(/\r\n/g, '\n');
	var len = ctrl.value.length;
	var endRange = ctrl.createTextRange();
	endRange.collapse(false);
	if (controlRange.compareEndPoints('StartToEnd', endRange) > -1) {
		pos.start = pos.end = len;
	}
	else {
		pos.start = -controlRange.moveStart("character",-len);
		//pos.start += normalizedVal.slice(0,pos.start).split('\n').length - 1;
		
		if (controlRange.compareEndPoints("EndToEnd", endRange) > -1) {
			pos.end = len;
		}
		else {
			pos.end = -controlRange.moveEnd("character", -len);
			//pos.end += normalizedVal.slice(0,pos.end).split('\n').length - 1;
		}
	}
	return pos;
}

function document_selectText(ctrl,startPos,endPos) {
	// set the cursor position and focus on it
	if (ctrl.setSelectionRange) {
		ctrl.focus();
		ctrl.setSelectionRange(startPos,endPos);
	}
	else if (ctrl.createTextRange) {
		var newRange = ctrl.createTextRange();
		newRange.collapse(true);
		newRange.moveEnd('character', endPos);
		newRange.moveStart('character', endPos);
		newRange.select();
	}
}

function document_replaceSelectedText(ctrl,zenID,newText,isDelete) {
	var removedText = '';
	newText = (newText == null ? '' : newText);

	if (zenID && (zenID != '') && (ctrl.isContentEditable)) {
		var pos = { start: 0, end: 0 };
		var normalizedVal = ctrl.value.replace(/\r\n/g, '\n');
		var range = document_getRange(ctrl);

		// Get the corresponding Zen component in the proper context either in a popup or in the base page
		var comp = null;
		if (document.activeElement instanceof HTMLIFrameElement) {
			var win = document.activeElement.contentWindow;
			comp = document.activeElement.contentWindow.zenPage.getComponent(zenID);
		}
		else {
			comp = zenIndex(zenID);
		}

		if (range) {
			// check if user already has a selection; if so, set it to newText and return
			if (range.text.length > 0) {
				removedText = range.text;
				range.text = newText;
				range.select();
				if (comp) {
					comp.onchangeHandler();
				}
				return removedText;
			}
			else {
				var position = document_findPositions(ctrl,range);
				pos.start = position.start;
				pos.end = position.end;
			}
		}
		
		var shift = 0;
		// ensure we always delete the next character
		if (isDelete && (pos.start == pos.end)) {
			pos.end = pos.start + 1;
			shift = 1;
		}
		
		var first = normalizedVal.substring(0,pos.start);
		var second = normalizedVal.substring(pos.end);
		removedText = normalizedVal.substring(pos.start,pos.end);
		if (comp) {
			comp.setValue(first + newText + second);
			comp.onchangeHandler();
		}
		else {
			ctrl.value = first + newText + second;
		}
		var newEndPos = pos.end + newText.length - shift;
		document_selectText(ctrl,newEndPos,newEndPos);
	}
	return removedText;
}

function document_getSelText(ctrl) {
	var selText = null;

	if (document.activeElement instanceof HTMLIFrameElement) {
		var iframe = document.activeElement;
		var win = iframe.contentWindow;
		var doc = iframe.contentDocument || win.document;
	}
	else {
		var win = window;
		var doc = window.document;
	}

    if (doc) {
		if (doc.selection) {
            // IE-specific
            return doc.selection.createRange().text;
        }
        else if (doc.getSelection) {
            // Most browsers
            return String(doc.getSelection());
        }
        else if (win.getSelection) {
            // Safari 3 and other browsers
            return String(win.getSelection());
        }
    }

	return selText;
}

function document_copy() {
	var ispopup = false;
	var activeElement = document_getActiveElement();
	if (activeElement && activeElement.active && activeElement.isinput) {
		ispopup = activeElement.isiframe;
		var selectedText = document_getSelText();
		try {
			document.execCommand('Copy',false,true);
			zenPage.setResultsDiv('COPY',selectedText);
		}
		catch(ex) {
			zenExceptionHandler(ex,arguments,'Error in document_copy');
		}
		return;
	}
	if (invokeShapeCallbacks && !ispopup) zenPage.copyShape();
}

function document_paste(pasteVal) {
	pasteVal = (pasteVal == null ? '' : pasteVal);
	var ispopup = false;
	var activeElement = document_getActiveElement();
	if (activeElement && activeElement.active && activeElement.isinput) {
		var zenID = activeElement.zenid;
		ispopup = activeElement.isiframe;
		if (zenID && (zenID != '')) {
			try {
				document.execCommand('Paste',false,pasteVal);
			}
			catch(ex) {
				zenExceptionHandler(ex,arguments,'Error in document_paste');
			}
			return;
		}
	}
	if (invokeShapeCallbacks && !ispopup) zenPage.paste();
}

function document_cut() {
	var ispopup = false;
	var activeElement = document_getActiveElement();
	if (activeElement && activeElement.active && activeElement.isinput) {
		var zenID = activeElement.zenid;
		ispopup = activeElement.iframe;
		if (zenID && (zenID != '')) {
			var removedText = document_getSelText();
			if (removedText !== '') {
				try {
					document.execCommand('Delete',false,null);
					zenPage.setResultsDiv('CUT',removedText);
				}
				catch(ex) {
					zenExceptionHandler(ex,arguments,'Error in document_cut');
				}
			}
		}
		return;
	}
	if (invokeShapeCallbacks && !ispopup) zenPage.cutShape();
}

function document_delete() {
	var ispopup = false;
	var activeElement = document_getActiveElement();
	if (activeElement && activeElement.active && activeElement.isinput) {
		var zenID = activeElement.zenid;
		ispopup = activeElement.iframe;
		if (zenID && (zenID != '')) {
			try {
				document.execCommand('Delete',false,null);
			}
			catch(ex) {
				zenExceptionHandler(ex,arguments,'Error in document_delete');
			}
			return;
		}
	}
	if (invokeShapeCallbacks && !ispopup) zenPage.deleteShape();
}

function document_selectall() {
	var activeElement = document_getActiveElement();
	if (activeElement && activeElement.active) {
		var active = activeElement.active;
		if (active && active.type && (active.type=='text' || active.type=='textarea')) {
			active.select();
		}
	}
}

// Called from subclass
function undoAction() {
	var activeElement = document_getActiveElement();
	if (activeElement && activeElement.active && activeElement.isinput) {
		var zenID = activeElement.zenid;
		try {
			document.execCommand('Undo',false,null);
			if (!document.queryCommandSupported('Undo')) {
				alert("Sorry, execCommand('Undo') is not supported in this browser");
			}
		}
		catch(ex) {
			zenExceptionHandler(ex,arguments,'Error in undoAction');
		}
		return true;
	}
	return false;
}

</script>>

	}
	Quit $$$OK
}

Method %OnDrawHTMLMeta() As %Status
{
/// Ensure that we force Internet Explorer to use its most recent rendering engine,
/// <strong>except</strong> if we are in Studio, in which case we <strong>don't</strong>
/// want IE10 and IE11 as we have issues with the way it present XML to Studio.
	If ('..studioMode) {
		Quit ##super()
	}
	Set tUA = %request.UserAgent
	Set tIEVersion = +$piece($piece(tUA,"MSIE ",2),".",1)
	If ('tIEVersion) {
		Set tIEVersion = +$piece($piece(tUA,"; rv:",2),".",1)
	}
	Set tTridentVersion = +$piece($piece(tUA,"Trident/",2),";",1)
	If (tIEVersion=10) || (tIEVersion=11) || (tTridentVersion>5) {
		// Force IE10 or later to behave like IE9
		&html<<meta http-equiv="X-UA-Compatible" content="IE=9" />>
	}
	ElseIf (tIEVersion=8) || (tIEVersion=9) || (tTridentVersion>3) {
		// Force IE8 or IE9 into EDGE mode
		&html<<meta http-equiv="X-UA-Compatible" content="IE=edge" />>
	}
	Else {
		Quit ##super()
	}
	Quit $$$OK
}

/// Avoid writing out the session cookie if we are in a Studio session.
ClassMethod OnPreHyperEvent(class As %String, method As %String) As %Status [ ServerOnly = 1 ]
{
	If $get(%session.Data("Ensemble","StudioSession",$namespace)) Set %response.OutputSessionToken = 0
	Quit ##super(.class,.method)
}

/// Helper method to determine whether the current page should use a keepalive instead of logging
/// users out after a period of inactivity.
ClassMethod UseKeepAlive() As %Boolean [ Private ]
{
	// If we are in Studio mode we should disable keepalives
	If $isobject($get(%request)) && ($get(%request.Data("STUDIO",1)) = 1) {
		Quit 0
	}
	Quit ##super()
}

ClientMethod updateJSONSCReadOnly(jsonObject) [ Language = javascript ]
{
	try {
		if (jsonObject && 
			((parseInt(jsonObject.ReadOnly)!=0) && ((!this._documentLoaded)||(this._inReload))) && 
			(!zenPage.IsDocReadOnly())) {
				jsonObject.ReadOnly = 0;
			}
	}
		catch(ex) {
			zenExceptionHandler(ex,arguments,'Error in updateJSONSCReadOnly');
	}
}

}
