/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specialized group for creating a set of modal components 
/// displayed within a page.<br>
/// To display a modalGroup, use the modalGroup's <method>show</method>
/// method. Use the zenPage object's <method>endModal</method> to remove the modalGroup.<br>
/// You can define the contents of a modalGroup in three different ways:<br>
/// <ol>
/// <li>Static mode: The modalGroup is defined within a page definition in the same
/// way as any other group. The contents of the group will be hidden until the <method>show</method>
/// is called.</li>
/// <li>Dynamic mode: The application creates a modalGroup dynamically (using
/// the page's <method>createComponent</method> method), adds components to it, and
/// displays it with the <method>show</method> method.</li>
/// <li>Built-in mode: The application uses the <method>show</method> method
/// to display one of the built-in groups: "msgBox" or "calendar".</li>
/// </ol>
Class %ZEN.Component.modalGroup Extends group [ Deprecated, System = 3 ]
{

Parameter DEFAULTLAYOUT = "vertical";

Parameter DEFAULTHIDDEN = 1;

/// If set, this indicates that a pre-defined modalGroup
/// of the specified type should be displayed.
/// This is set by the <method>show</method> method; applications
/// should not set this.
Property groupType As %ZEN.Datatype.string(VALUELIST = ",msgBox,calendar,dialog", XMLPROJECTION = "none", ZENSETTING = 0);

/// Title to display at top of modal group.
/// This is set dynamically by the <method>show</method> method.
/// For static modalGroups, it can be set in the original page definition.
Property groupTitle As %ZEN.Datatype.caption;

/// Optional.
/// User-defined seed value. This is an optional parameter that
/// is passed on to the <property>onaction</property> event handler.<br>
Property seed As %ZEN.Datatype.string;

/// This is used to hold a value for the modalGroup.<br>
/// This is set by the <method>show</method> method; applications
/// should not set this.
Property value As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0);

/// onshowGroup event handler:
/// This event is fired when the modalGroup is made visible.
Property onshowGroup As %ZEN.Datatype.eventHandler;

/// onhideGroup event handler:
/// This event is fired when the modalGroup is hidden.
Property onhideGroup As %ZEN.Datatype.eventHandler;

/// onaction event handler: 
/// client code to run when user takes action with pre-defined modalGroup.
Property onaction As %ZEN.Datatype.eventHandler;

/// Localizable "OK" caption displayed in OK button for a message box.
Property okCaption As %ZEN.Datatype.caption [ InitialExpression = {$$$Text("OK","%ZEN")} ];

XData Style
{
<style type="text/css">
/* @doc="Style for modalGroup: change this background for a different color" */
.modalGroup {
	position: absolute;
	border: 1px solid #808080;
	background: rgb(53,107,141);
	padding: 5px;
}

.modalGroup.modalGroupDialog {
	padding: 2px;
}

/* @doc="Title bar for modal group" */
.modalGroupTitle {
	position:relative;
	border-bottom: 1px #808080 solid;
	background: transparent;
	padding: 0px;
	cursor: move;
	top:0px;
	left:0px;
}

/* @doc="Close button for modal group" */
.modalGroupClose {
	position:absolute;
	top:0px;
	right:0px;
}

/* @doc="Resize handle for modal group" */
.modalGroupHandle {
	position:absolute;
	bottom:0px;
	right:0px;
}

.modalGroupTitle table {
	border: none;
}

.modalGroupTitle td {
	padding-top: 2px;
	padding-bottom: 2px;
	padding-left: 8px;
	padding-right: 0px;
	border: none;
	font-weight: bold;
	font-family: arial;
	font-size: 8pt;
	color: #F0F0F0;
}

.modalGroupCloseButton {
	filter: alpha(opacity=80);
	opacity: 0.8;
}

.modalGroupCloseButtonHover {
}

/* @doc="Body of modal group" */
.modalGroupBody {
	padding: 3px;
	background: none;
	position:relative;
	top:0px;
	left:0px;
}

.modalGroupBody.modalGroupDialog {
	padding: 0px;
}

/* @doc="OK button holder for MsgBox" */
.modalGroupFooter {
	padding: 3px;
	padding-top: 10px;
	background: none;
	text-align: center;
	position: relative;
	top: 0px;
	left: 0px;
}

.modalGroupFooter input {
	width: 7.0em;
	font-size: 0.8em;
}

/* iframe used for dialog mode */
.modalGroupIframe {
	background: white;
}

.modalGroupDialog.dragMouseTrap {
	position: fixed;
	top: 0px;
	left: 0px;
	filter: alpha(opacity=0);
	opacity: 0;
}
.modalGroupDialog.dragMouseTrap.move {
	cursor: move;
}
.modalGroupDialog.dragMouseTrap.resize {
	cursor: nw-resize;
}
</style>
}

XData CSS3Style
{
<style type="text/css">
/* @doc="Style for modalGroup: change this background for a different color" */
.modalGroup {
	position: absolute;
	border: 1px solid #808080;
	background: rgb(53,107,141); /*fallback*/
	background: rgba(53,107,141,0.8);
	box-shadow: 2px 2px 8px #808080;
	padding: 5px;
	border-radius: 4px;
	opacity: 0;
	transition: opacity 0.5s ease-in-out;
}

.modalGroup.modalGroupDialog {
	padding: 2px;
	background: rgb(53,107,141);/*fallback*/
	background: rgba(53,107,141,0.9);
}

/* @doc="Title bar for modal group" */
.modalGroupTitle {
	position:relative;
	border-bottom: 1px #808080 solid;
	background: transparent;
	padding: 0px;
	cursor: move;
	top:0px;
	left:0px;
}

/* @doc="Close button for modal group" */
.modalGroupClose {
	position:absolute;
	top:0px;
	right:0px;
}

/* @doc="Resize handle for modal group" */
.modalGroupHandle {
	position:absolute;
	bottom:0px;
	right:0px;
}

.modalGroupTitle table {
	border: none;
}

.modalGroupTitle td {
	padding-top: 2px;
	padding-bottom: 2px;
	padding-left: 8px;
	padding-right: 0px;
	border: none;
	font-weight: bold;
	font-family: arial;
	font-size: 8pt;
	color: #F0F0F0;
}

.modalGroupCloseButton {
	opacity: 0.8;
}

.modalGroupCloseButtonHover {
}

/* @doc="Body of modal group" */
.modalGroupBody {
	padding: 3px;
	background: none;
	position:relative;
	top:0px;
	left:0px;
}

.modalGroupBody.modalGroupDialog {
	padding: 0px;
}

/* @doc="OK button holder for MsgBox" */
.modalGroupFooter {
	padding: 3px;
	padding-top: 10px;
	background: none;
	text-align: center;
	position: relative;
	top: 0px;
	left: 0px;
}

.modalGroupFooter input {
	width: 7.0em;
	font-size: 0.8em;
}

/* iframe used for dialog mode */
.modalGroupIframe {
	background: white;
}

.modalGroupDialog.dragMouseTrap {
	position: fixed;
	top: 0px;
	left: 0px;
	opacity: 0;
}
.modalGroupDialog.dragMouseTrap.move {
	cursor: move;
}
.modalGroupDialog.dragMouseTrap.resize {
	cursor: nw-resize;
}
</style>
}

/// Return the HTML element used to display this modal group
ClientMethod getFloatingDiv() [ Language = javascript ]
{
	var divId='zenFloatingDiv_'+this.index;
	var div = self.document.getElementById(divId);
	return(div);
}

/// Notification that this component is about to become modal.
ClientMethod onStartModalHandler(zindex) [ Language = javascript ]
{
	// show the modal group
	var div = this.getFloatingDiv();
	if (!div) {
		var div = document.createElement('div');
		div.id='zenFloatingDiv_'+this.index;
		div.style.display="none";
		if (this.groupType == 'dialog') div.className = 'modalGroupDialog';
		document.body.appendChild(div);

		if (zenIsIE) { //SAM055
			var iFrame = document.createElement("iframe");
			iFrame.src = '';
			iFrame.frameBorder = '0';
			var s = iFrame.style;
			s.filter = 'alpha(opacity=0)';
			s.zIndex = '0';
			s.position = 'absolute';
			s.top = '0px';
			s.left = '0px';
			s.width = '100%';
			s.height = '100%';
			s.border = '0px solid black';
			s.background = 'transparent';
			div._iFrame = iFrame;
		}
	}
	var update = false;
	var resize = false;
	var moveWithZLM = true;

	// set up style for div
	var mainClassName = 'modalGroup';
	if (this.groupType == 'dialog') mainClassName += ' modalGroupDialog';
	div.className = mainClassName;
	div.onmousedown = null;
	div.onmouseup = null;
	div.onmousemove = null;

	// create children, depending on our type
	var contents = '';
	switch (this.groupType) {
	case 'calendar':
		var cal = zenPage.createComponent('calendar');
		this.addChild(cal);
		cal.setProperty('startYear',1900);
		cal.setProperty('onchange','zenPage.getComponent('+this.index+').actionHandler();');

		// if there are additional parms, apply them
		if (this._parms) {
			for (var p in this._parms) { 
				cal.setProperty(p,this._parms[p]);
			}
		}

		// set value *after* applying parms
		cal.setProperty('value',this.value);

		// remember index of this control
		this.controlIndex = cal.index;
		break;
	case 'msgBox':
		contents = this.value;
		break;
	case 'dialog':
		this._canClose = false;
		resize = !!this._allowResize;
		break;
	case 'callback':
		break;
	default:
		break;
	}

	var html = [];

	// title (with drag handling)
	if (('' != this.groupTitle) || (this.groupType == 'dialog')) {
		var titleClass = 'modalGroupTitle' + (this.groupType == 'dialog' ? ' modalGroupDialog' : '');
		// use ZLM drag controls for move handling if ZLM has been loaded for resize; also add 2 to zindex to allow for dragMouseTrap at zindex+1
		var mousedownHandler = moveWithZLM ? 'startZLMMove' : 'mousedownHandler';
		html.push('<div id="'+this.makeId('title')+'" class="'+titleClass+'" style="z-index:'+(zindex+(2*moveWithZLM))+';" onselectstart="return false;" onmousedown="zenPage.getComponent('+this.index+').'+mousedownHandler+'(event);" ontouchstart="zenPage.getComponent('+this.index+').'+mousedownHandler+'(event);">');
		html.push('<table border="0" cellpadding="0" cellspacing="0"><tr>');
		html.push('<td id="'+this.makeId('titleText')+'" style="text-align:left;" nowrap="1">' + this.groupTitle + '</td>');
		html.push('</tr></table>');
		html.push('</div>');
	}

	if ('dialog' == this.groupType) {
		// show iframe to hold dialog contents
		html.push('<div id="'+this.makeId('modalGroupBody')+'" class="modalGroupBody modalGroupDialog" style="z-index:'+zindex+';">');
		var src = this.value ? this.value : '';
		if ((-1 == src.indexOf('?$ZEN_POPUP=1')) && (-1 == src.indexOf('&$ZEN_POPUP=1'))) {
			src += (src.indexOf('?') == -1 ? '?' : '&') + '$ZEN_POPUP=1';
		}
		if ((-1 == src.indexOf('?$ZEN_SOFTMODAL=1')) && (-1 == src.indexOf('&$ZEN_SOFTMODAL=1'))) {
			src += (src.indexOf('?') == -1 ? '?' : '&') + '$ZEN_SOFTMODAL=1';
		}
		var fw = (this._width ? this._width : '700') + 'px';
		var fh = (this._height ? this._height : '500') + 'px';
		// add zenCompIndex attribute to record index of this component so that we can find our opening window 
		html.push('<iframe id="'+this.makeId('frame')+'" zenCompIndex="' + this.index + '" class="modalGroupIframe" frameborder="0" scrolling="auto" width="'+fw+'" height="'+fh+'" src="'+src+'" onload="zenPage.getComponent('+this.index+').onDialogFrameLoad(this.contentWindow);"/>');
		html.push('</div>');
	}
	else if ('callback' == this.groupType) {
		// invoke callback
		if (this._function && 'function' == typeof this._function) {
			var info = this._function(this);
			var style = info.style ? info.style : '';

			html.push('<div class="modalGroupBody" style="overflow:auto;z-index:'+zindex+';'+style+'">');
			html.push(info.content ? info.content : '');
			html.push('</div>');
		}
		else {
			html.push('<div class="modalGroupBody" style="z-index:'+zindex+';">');
			html.push('No callback supplied');
			html.push('</div>');
		}

	}
	else if ('static' != this.groupType) {
		if ('' != contents) {
			// contents of MsgBox
			html.push('<div class="modalGroupBody" style="z-index:'+zindex+';">');
			html.push(contents);
			html.push('</div>');

			html.push('<div class="modalGroupFooter" style="z-index:'+zindex+';">');
			html.push('<input type="button" value="'+this.okCaption+'" onclick="zenPage.endModal();" />');
			html.push('</div>');
		}
	}

	if ('static' == this.groupType) {
		var staticHTML = this.getModalBodyContent(false);
		html.push('<div id="' + this.makeId('modalBody') + '" class="modalGroupBody" style="z-index:'+zindex+';">');
		html.push(staticHTML);
		html.push('</div>');

		update = true;
	}
	else {
		// layout containing divs for components 
		for (var n = 0; n < this.children.length; n++) {
			var child = this.children[n];
			var divid = ('' == child.id) ? 'zen'+child.index : child.id;
			html.push('<div id="'+divid+'" class="modalGroupBody" style="z-index:'+zindex+';"></div>');
		}
	}

	div.innerHTML = html.join('');

	// set size (after setting contents)
	div.style.width = (this._width == null) ? 'auto' : this._width + 'px';
	div.style.height = (this._height == null) ? 'auto' : this._height + 'px';

	this._width = null;
	this._height = null;

	// close button
	var handle = document.createElement('div');
	handle.className = 'modalGroupClose';
	var thisIndex = this.index;
	// attach click handler to div, IE8 doesn't like working with the inner input element.
	handle.onclick = function(evt) { zenPage.getComponent(thisIndex).hideGroup(); };
	handle.innerHTML = '<input class="modalGroupCloseButton" type="image" src="images/closewhite.png" onmouseover="this.className=\'modalGroupCloseButtonHover\';" onmouseout="this.className=\'modalGroupCloseButton\'">';
	div.insertBefore(handle,div.firstChild);
	handle.style.zIndex = zindex + 3;
	
	if (resize) {
		var sz = 16;
		var handle = document.createElement('div');
		handle.className = 'modalGroupHandle';
		handle.style.zIndex = 65536;
		handle.style.width = '20px';
		handle.style.height = '20px';
		handle.innerHTML = '<image id="'+this.makeId('resize')+'" src="images/grayDragResize.png" style="cursor:nw-resize; z-index:65535; width:'+sz+'px; height:'+sz+'px; padding-left:2px; padding-top:2px;" onmousedown="zenPage.getComponent('+this.index+').startZLMResize(event);" ontouchstart="zenPage.getComponent('+this.index+').startZLMResize(event);">';
		div.insertBefore(handle,div.firstChild);
	}
	// set up ZLM drag; create div to allow for trapping of mouse events in entire screen
	if (moveWithZLM || resize) {
		var dragMouseTrap = document.createElement('div');
		dragMouseTrap.className = 'modalGroupDialog dragMouseTrap';
		dragMouseTrap.setAttribute('id',this.makeId('dragMouseTrap'));
		div.insertBefore(dragMouseTrap,div.firstChild.nextSibling);
		dragMouseTrap.style.display = 'none';
		dragMouseTrap.style.zIndex = zindex+1;
		// Older IE versions don't render the div as transparent with position = fixed
		if (zenIsIE && !zenIsHTML5) dragMouseTrap.style.position = 'absolute';
	}

	if (div._iFrame) div.insertBefore(div._iFrame,div.firstChild); //SAM055

	if ('static' != this.groupType) {
		// render dynamic component contents
		for (var n = 0; n < this.children.length; n++) {
			var child = this.children[n];
			if (child.renderContents) {
				child.renderContents();
			}
			else {
				// go to server
				child.refreshContents();
			}
		}
	}
	else if (update) {
		// fix for Mozilla bug
		this.updateControlsInGroup();
	}

	// make sure we are placed above mouse trap
	// make visible here so that we can find our width and height
	div.style.zIndex = zindex;
	div.style.display = 'block';

	// set position
	var page = zenPage.getEnclosingDiv();
	var top,left;
	if (this._top==null) {
		top = (zenGetWindowHeight() - div.offsetHeight) /2;
		top += zenGetPageScrollTop();
	}
	else {
		top = this._top;
		this._top = null;
	}
	if (this._left==null) {
		left = (page.offsetWidth - div.offsetWidth)/2;
		left += zenGetPageScrollLeft();
	}
	else {
		left = this._left;
		this._left = null;
	}

	div.style.top = top + 'px';
	div.style.left = left + 'px';
	// Update iframe size if needed
	if (this.groupType == 'dialog') this.updateFrameSize();
	// Ensure that we initialize _closing to false
	this._closing = false;

	// invoke event handler
	zenInvokeCallbackMethod(this.onshowGroup,this,'onshowGroup','group',this);

	this._oldTrapTAB = zenTrapTAB;
	zenTrapTAB = true;

	// IE can't figure out how to calculate a height properly so do it for it
	if (div._iFrame) {
		div._iFrame.style.zIndex= zindex-1;
		if (div._iFrame.offsetHeight < div.offsetHeight) {
			div._iFrame.style.height = div.offsetHeight + 'px'; //SAM055
			div._iFrame.style.top = '-1px';
		}
		if (div._iFrame.offsetWidth < div.offsetWidth) {
			div._iFrame.style.width = div.offsetWidth + 'px';
			div._iFrame.style.left = '-1px';
		}
	}
	div.focus();

	this._steps = 0;
	this._mode = 'show';

	// Ensure child components have a chance to correct their geometry to handle cases where styles
	// were set based on the hidden (i.e. 0-based) geometry during page load.
	for (var n = 0; n < this.children.length; n++) {
		var child = this.children[n];
		if (child.exposeComponent) {
			setTimeout("zenPage.getComponent("+child.index+").exposeComponent();",0);
		}
	}
	if (zenIsHTML5 && window.TransitionEnd) {
		div.addEventListener('transitionend', function() { if ((this.style.opacity == 0) && zenPage) { zenPage.endModal(); } });
	}
	div.style.opacity = 1;
}

/// Notification that this component is about to stop being modal.
ClientMethod onEndModalHandler(zindex) [ Language = javascript ]
{
	// hide the floating div
	var div = this.getFloatingDiv();
	div.style.display = "none";

	zenTrapTAB = (null == this._oldTrapTAB) ? false : this._oldTrapTAB;

	// if we are a dialog make sure that zenPopupWindow is set to null
	if ((this.groupType == 'dialog') && self.zenPopupWindow) {
		var iframe = this.findElement('frame');
		if (iframe && (self.zenPopupWindow == iframe.contentWindow)) self.zenPopupWindow = null;
	}
	if (zenPage && (('dynamic' == this.groupType) || ('dialog' == this.groupType))) {
		// remove this group from the page
		// set our visible flag false to avoid page refresh
		this.visible = false;
		zenPage.removeChild(this);
	}

	// restore state
	div.onmousedown = null;
	div.onmouseup = null;
	div.onmousemove = null;

	// invoke event handler
	zenInvokeCallbackMethod(this.onhideGroup,this,'onhideGroup','group',this);
}

/// Helper method to get the content for static modalGroups.
/// If the enclosing div has content, that content is returned,
/// and the enclosing div's content is cleared.
/// If <var>update</var> is true AND the modalBody element for
/// this group exists (i.e. the group has been displayed), then
/// the modalBody's content is updated to the new value.
ClientMethod getModalBodyContent(update) [ Language = javascript ]
{
	var content = '';
	if (this.groupType == 'static') {
		var enc = this.getEnclosingDiv();
		if (enc) {
			var modalBody = this.findElement('modalBody');
			if (modalBody) { // we have already been rendered once
				if (enc.innerHTML != '') { // enc has data, so it takes primacy
					content = enc.innerHTML;
				}
				else {
					content = modalBody.innerHTML;
				}
				if (update) {
					modalBody.innerHTML = content;
				}
			}
			else { // we haven't been rendered yet
				content = enc.innerHTML;
			}
			// make sure we only have one set of HTML in the DOM
			enc.innerHTML = '';
		}
		this._htmlStash = content;
	}
	return content;
}

/// Utility method:
/// Construct a wrapper around an instance method of this object
/// that can be used as an event listener.
ClientMethod wrapMethod(methodName) [ Internal, Language = javascript ]
{
	return new Function('evt','return zenPage.getComponent('+this.index+').'+methodName+'(evt);');
}

/// mousedownHandler: handles start of move operation
ClientMethod mousedownHandler(evt) [ Language = javascript ]
{
	var div = this.getFloatingDiv();
	evt = evt ? evt : window.event;
	this._mouseMode = 'move';

	var x = parseInt(div.style.left,10);
	var y = parseInt(div.style.top,10);
	this.deltaX = evt.clientX - x;
	this.deltaY = evt.clientY - y;

	// use older API for IE compat
	div.onmousemove = this.wrapMethod('mousemoveHandler');
	div.onmouseup = this.wrapMethod('mouseupHandler');

	if (evt.stopPropagation) { evt.stopPropagation(); }
	if (evt.preventDefault) { evt.preventDefault(); }
}

/// mousemoveHandler: handles move operation
ClientMethod mousemoveHandler(evt) [ Language = javascript ]
{
	var div = this.getFloatingDiv();
	evt = evt ? evt : window.event;

	if (this._mouseMode == 'resize') {
		var oldW = div.offsetWidth;
		var oldH = div.offsetHeight;

		div.style.width = parseInt(evt.clientX - this.deltaX - div.offsetLeft) + 'px';
		div.style.height = parseInt(evt.clientY - this.deltaY - div.offsetTop) + 'px';
		var frame = this.findElement('frame');
		if (frame) {
			// adjust frame
			var dw = div.offsetWidth - oldW;
			var dh = div.offsetHeight - oldH;
			frame.style.width = frame.offsetWidth + dw + 'px';
			frame.style.height = frame.offsetHeight + dh + 'px';
		}
	}
	else {
		div.style.left = (evt.clientX - this.deltaX) + 'px';
		div.style.top = (evt.clientY - this.deltaY) + 'px';
	}
	if (evt.stopPropagation) { evt.stopPropagation(); }
}

/// mouseupHandler: handles end of move operation
ClientMethod mouseupHandler(evt) [ Language = javascript ]
{
	var div = this.getFloatingDiv();
	evt = evt ? evt : window.event;

	// use older API for IE compat
	div.onmousemove = null;
	div.onmouseup = null;

	if (evt.stopPropagation) { evt.stopPropagation(); }
}

/// Toggle "visibility" of dragMouseTrap. The trap should be completely transparent
/// but allows the component to trap mouse events reliably during drag operations.
ClientMethod toggleDragMouseTrap(show) [ Language = javascript ]
{
	var trap = this.findElement('dragMouseTrap');
	if (trap) {
		if (show) {
			if (zenIsIE && !zenIsHTML5) {
				var mainDiv = this.getFloatingDiv();
				trap.style.width = mainDiv.offsetWidth + 'px';
				trap.style.height = mainDiv.offsetHeight + 'px';
			}
			else {
				trap.style.width = zenGetWindowWidth() + 'px';
				trap.style.height = zenGetWindowHeight() + 'px';
			}
			trap.className = 'modalGroupDialog dragMouseTrap' + (this._dragData ? ' '+this._dragData.type : '');
		}
		trap.style.display = (show ? 'block' : 'none');
	}
}

/// Start the ZLM drag-based resize operation.
ClientMethod startZLMResize(evt) [ Language = javascript ]
{
	if (typeof this._dragData == 'undefined') {
		var mainDiv = this.getFloatingDiv();
		var titleDiv = this.findElement('title');
		// calculate width and height limits
		this._dragData = { "type": "resize", "width": null };
		this._dragData.maxWidth = zenGetWindowWidth() - parseInt(mainDiv.style.left,10);
		this._dragData.maxHeight = zenGetWindowHeight() - parseInt(mainDiv.style.top,10) - (titleDiv ? titleDiv.offsetHeight : 0);
		this._dragData.startWidth = parseInt(mainDiv.style.width,10);
		this._dragData.startHeight = parseInt(mainDiv.style.height,10);
		if (this._dragData.startWidth > this._dragData.maxWidth) this._dragData.maxWidth = this._dragData.startWidth;
		if (this._dragData.startHeight > this._dragData.maxHeight) this._dragData.maxHeight = this._dragData.startHeight;

		this.startZLMDrag(evt);
	}
}

/// Start the ZLM drag-based move operation.
ClientMethod startZLMMove(evt) [ Language = javascript ]
{
	if (typeof this._dragData == 'undefined') {
		var mainDiv = this.getFloatingDiv();
		this._dragData = { "type": "move" };
		// calculate top limits
		this._dragData.startTop = parseInt(mainDiv.style.top,10);
		this._dragData.maxTop = zenGetWindowHeight() - mainDiv.offsetHeight - this._dropShadow;
		if (this._dragData.maxTop < this._dragData.startTop) this._dragData.maxTop = this._dragData.startTop;
		// calculate left limits
		this._dragData.startLeft = parseInt(mainDiv.style.left,10);
		this._dragData.maxLeft = zenGetWindowWidth() - mainDiv.offsetWidth - this._dropShadow;
		if (this._dragData.maxLeft < this._dragData.startLeft) this._dragData.maxLeft = this._dragData.startLeft;

		this.startZLMDrag(evt);
	}
}

/// Start ZLM drag once this._dragData has been set up.
ClientMethod startZLMDrag(evt) [ Language = javascript ]
{
	// enable dragMouseTrap, register the element and call ZLM.drag
	this.toggleDragMouseTrap(true);
	var dragMouseTrap = this.findElement('dragMouseTrap');
	if (!ZLM.getWrapper(dragMouseTrap)) ZLM.registerDragItem(dragMouseTrap,this);
	ZLM.drag(dragMouseTrap,evt);
}

/// Callback from the ZLM drag which is used to clean up.
ClientMethod endDrag(engine, wrapper) [ Language = javascript ]
{
	this.toggleDragMouseTrap(false);
	// unregister drag item to avoid cluttering ZLM.stones
	var dragMouseTrap = this.findElement('dragMouseTrap');
	if (dragMouseTrap && ZLM.getWrapper(dragMouseTrap)) {
		for (var i = ZLM.stones.length-1; i >= 0; i--) {
			if (ZLM.stones[i].node == dragMouseTrap) ZLM.stones.splice(i,1);
		}
	}
	delete this._dragData;
}

/// Limit the x-axis changes to the current screen size.
ClientMethod constrainDragX(engine, wrapper, intendedX) [ Language = javascript ]
{
	if (this._dragData) {
		if (this._dragData.type == 'move') {
			if (intendedX < -this._dragData.startLeft) intendedX = -this._dragData.startLeft;
			else if ((intendedX + this._dragData.startLeft) > this._dragData.maxLeft) intendedX = this._dragData.maxLeft-this._dragData.startLeft;
			var div = this.getFloatingDiv();
			div.style.left = this._dragData.startLeft + intendedX + 'px';
		}
		else if (this._dragData.type == 'resize') {
			this._dragData.width = this._dragData.startWidth + intendedX;
			if (this._dragData.width < 100) this._dragData.width = 100;
			if (this._dragData.width > this._dragData.maxWidth) this._dragData.width = this._dragData.maxWidth;
			// width is adjusted in constrainDragY() to keep size changes close together
		}
	}
	// we never want the dragMouseTrap to move from 0
	return 0;
}

/// Limit the y-axis changes to the current screen size.
ClientMethod constrainDragY(engine, wrapper, intendedY) [ Language = javascript ]
{
	if (this._dragData) {
		if (this._dragData.type == 'move') {
			if (intendedY < -this._dragData.startTop) intendedY = -this._dragData.startTop;
			else if ((intendedY + this._dragData.startTop) > this._dragData.maxTop) intendedY = this._dragData.maxTop - this._dragData.startTop; 
			var div = this.getFloatingDiv();
			div.style.top = (this._dragData.startTop + intendedY) + 'px';
		}
		else if (this._dragData.type == 'resize') {
			var newHeight = this._dragData.startHeight + intendedY;
			if (newHeight < 100) newHeight = 100;
			if (newHeight > this._dragData.maxHeight) newHeight = this._dragData.maxHeight;

			var div = this.getFloatingDiv();
			div.style.width = this._dragData.width + 'px';
			div.style.height = newHeight + 'px';
			this.updateFrameSize(this._dragData.width,newHeight);
			if (div._iFrame) { // update iFrame if present
				div._iFrame.style.height = div.offsetHeight + 'px';
				div._iFrame.style.width = div.offsetWidth + 'px';
			}
		}
	}
	// we never want the dragMouseTrap to move from 0
	return 0;
}

/// Make this group visible with modal behavior.<br>
/// <var>title</var> is the optional title to display for the group. For a 
/// static group, the application-defined value of <property>groupTitle</property> is
/// used if <var>title</var> is not supplied.<br>
/// <var>type</var> is the optional type of modalGroup to display. This can be:
/// <ul>
/// <li>"msgBox"-display the built-in message box.</li>
/// <li>"calendar"-display the built-in calendar box.</li>
/// <li>"dynamic"-display a dynamically created modalGroup.</li>
/// <li>"static"-display a modalGroup that has been defined as part of the page.</li>
/// <li>"dialog"-display the page with the URL supplied in <var>value</value> in an iframe.</li>
/// </ul>
/// If omitted, then the type will be "static" if the modalGroup has been defined
/// within the page object otherwise "dynamic".<br>
/// <var>value</var> is an optional value to display when a built-in modalGroup is used.<br>
/// <var>top</var>,<var>left</var>,<var>wid</var>, 
/// and <var>hgt</var> are optional position and 
/// dimensions to use for the modalGroup.<br>
/// <var>parms</var> is an optional object containing a set of 
/// additional characteristics passed on to the modalGroup (as
/// a set of name/value pairs). Basically this is a way to pass
/// additional parameters to the popup calendar.
ClientMethod show(title, type, value, top, left, wid, hgt, parms) [ Language = javascript ]
{
	var enc = this.getEnclosingDiv();

	this._function = null;

	if (enc) {
		// this is a static (embedded) group
		this.groupType = 'static'
		this.groupTitle = (null==title||''==title) ? this.groupTitle : title;
	}
	else {
		this.groupType = type==null ? 'dynamic' : type;
		this.value = value==null ? '' : value;
		this.groupTitle = title==null ? '' : title;

		if (zenPage && ('dynamic' == this.groupType)) {
			// add group to the page
			zenPage.addChild(this);
		}
		else if ('callback' == this.groupType && 'function' == typeof value) {
			this._function = value;
		}
	}

	// stash size args in transient properties;
	// these are defaulted if not provided by user.
	var scrollTop = zenGetPageScrollTop();
	if (top && (top < scrollTop)) top += scrollTop; 
	this._top = top;
	var scrollLeft = zenGetPageScrollLeft();
	if (left && (left < scrollLeft)) left += scrollLeft;
	this._left = left;
	this._width = wid;
	this._height = hgt;
	this._parms = parms;
	if (this.groupType == 'dialog') {
		var winWidth = zenGetWindowWidth();
		this._dropShadow = 8;
		if ((this._width + this._dropShadow) > winWidth) {
			this._left = scrollLeft;
			this._width = winWidth - this._dropShadow;
		}
		else if ((this._width + (this._left - scrollLeft) + this._dropShadow) > winWidth) {
			this._left = scrollLeft + parseInt((winWidth - this._width - this._dropShadow)/2,10);
		}
		var winHeight = zenGetWindowHeight();
		// include title height
		this._height = this._height - 20;
		if ((this._height + this._dropShadow) > winHeight) {
			this._top = scrollTop;
			this._height = winHeight - this._dropShadow;
		}
		else if ((this._height + (this._top - scrollTop) + this._dropShadow) > winHeight) {
			this._top = scrollTop + parseInt((winHeight - this._height - this._dropShadow)/2,10);
		}
		if (this._parms) {
			if (this._parms.rootWindow) {
				this._rootWindow = this._parms.rootWindow;
				delete this._parms.rootWindow;
			}
			this._allowResize = !!this._parms.allowResize;
		}
	}
	// ensure that the ZLM library is present for move and resize 
	if (!self.window.ZLM) zenLoadJS('zenCSLM.js');

	// show the group
	zenPage.startModal(this);
}

/// Client-side method to return the value associated with this group.
ClientMethod getValue() As %String [ Final, Language = javascript ]
{
	return this.getProperty('value');
}

ClientMethod onDialogFrameLoad(contentWindow) [ Language = javascript ]
{
	if (contentWindow) {
		if (contentWindow.document) this.updateTitle(contentWindow.document.title);
		contentWindow.focus();
	}
}

ClientMethod updateTitle(newTitle) [ Language = javascript ]
{
	if (newTitle == '') {
		var titleDiv = this.findElement('title');
		if (titleDiv) {
			var mainDiv = this.getFloatingDiv();
			if (mainDiv) mainDiv.removeChild(titleDiv);
		}
	}
	else if (newTitle != null) {
		this.groupTitle = newTitle;
		var titleCell = this.findElement('titleText');
		if (titleCell) titleCell.innerHTML = this.groupTitle;
	}
	this.updateFrameSize();
}

ClientMethod updateFrameSize(width, height) [ Language = javascript ]
{
	if (this.groupType != 'dialog') return;
	var frame = this.findElement('frame');
	var mainDiv = this.getFloatingDiv();
	if (frame && mainDiv) {
		if (typeof height == 'undefined') height = parseInt(mainDiv.style.height,10);
		if (typeof width == 'undefined') width = parseInt(mainDiv.style.width,10);
		var titleDiv = this.findElement('title');
		if (titleDiv) height -= titleDiv.offsetHeight;
		frame.height = height + 'px';
		frame.width = width + 'px';
	}
}

/// This method handles user actions within a pre-defined
/// modalGroup.
ClientMethod actionHandler() [ Language = javascript ]
{
	switch(this.groupType) {
	case 'calendar':
		// get value; invoke callback
		var ctrl = zenPage.getComponent(this.controlIndex);
		this.value = ctrl.getValue();
		zenInvokeCallbackMethod(this.onaction,this,'onaction','group',this);
		break;
	}

	this.hideGroup();
}

/// Hide the group.
ClientMethod hideGroup() [ Language = javascript ]
{
	if (this.groupType == 'dialog') this._canClose = true;
	var div = this.getFloatingDiv();
	if (div) {
		div.style.opacity = 0;
	}
	if ((!zenIsHTML5) || (!window.TransitionEnd)) {
		if (!this._closing) {
			zenPage.endModal();
			this._closing = true;
		}
	}
}

/// This method is deprecated as the fade effects for the modal now use CSS3 transition effects.
/// Slowly reveal the popup.
ClientMethod reveal() [ Internal, Language = javascript ]
{
	var div = this.getFloatingDiv();

	this._steps++;
	var maxSteps = 8;

	if (this._mode == 'show') {
		if (this._steps >= maxSteps) {
			div.style.display = 'block';
			div.style.opacity = 1.0;
		}
		else {
			div.style.display = 'block';
			div.style.opacity = this._steps/maxSteps;
			this._timerId = self.setTimeout('zenPage.getComponent('+this.index+').reveal()',10);
		}
	}
	else {
		if ((this._steps >= maxSteps) || (zenIsIE && !zenIsHTML5)) {
			div.style.display = 'none';
			zenPage.endModal();
		}
		else {
			div.style.display = 'block';
			div.style.opacity = 1 - this._steps/maxSteps;
			this._timerId = self.setTimeout('zenPage.getComponent('+this.index+').reveal()',10);
		}
	}
}

/// Ensure that we remove the floating div when the component is deleted.
ClientMethod onDelete() [ Language = javascript ]
{
	var div = this.getFloatingDiv();
	if (div && div.parentNode) div.parentNode.removeChild(div);
}

/// Don't allow the dialog to be closed unless the user explicitly does something 
/// to close the popup or fire a valid action.
ClientMethod onCanEndModalHandler() [ Language = javascript ]
{
	if (this.groupType != 'dialog') return true;
	return !!this._canClose;
}

/// Make sure that we correctly track the HTML for static modal groups.
ClientMethod onRefreshContents() [ Language = javascript ]
{
	if (this.groupType == 'static') {
		this.getModalBodyContent(true);
	}
	this.invokeSuper('onRefreshContents',arguments);
}

}
