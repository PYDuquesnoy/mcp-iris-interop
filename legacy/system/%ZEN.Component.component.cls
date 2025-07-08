/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is the base class for all visual, HTML-based Zen components.
Class %ZEN.Component.component Extends object [ Abstract, Deprecated, System = 3 ]
{

/// Subclasses can set this to change default width for a component.
Parameter DEFAULTWIDTH As STRING;

/// Subclasses can set this to change default height for a component.
Parameter DEFAULTHEIGHT As STRING;

/// Subclasses can set this to change default visibilty for a component.
Parameter DEFAULTVISIBLE = 1;

/// Subclasses can set this to change default hidden property for a component.
Parameter DEFAULTHIDDEN As BOOLEAN = 0;

/// Subclasses can set this to change default css class used for labels.
Parameter DEFAULTLABELCLASS As STRING = "zenLabel";

/// Subclasses can set this to change default css class used for disabled labels.
Parameter DEFAULTLABELDISABLEDCLASS As STRING = "zenLabelDisabled";

/// Subclasses can set this to change default css class used for hints.
Parameter DEFAULTHINTCLASS As STRING = "zenHint";

/// Subclasses can set this to change default enclosingClass used for this
/// component.
Parameter DEFAULTENCLOSINGCLASS As STRING = "zendiv";

/// Run-time value; Set to indicate an error within this component.<br>
/// This is primarily used by controls.
/// It is defined here for flexibility.
Property error As %ZEN.Datatype.string(XMLPROJECTION = "none", ZENSETTING = 0);

/// User defined label used to label this component.
/// The actual display of this label is managed by the group
/// this component belongs to.
Property label As %ZEN.Datatype.caption;

/// Optional CSS class used for the component label.
Property labelClass As %ZEN.Datatype.cssClass [ InitialExpression = {..#DEFAULTLABELCLASS} ];

/// Optional CSS class used for the component label when disabled.
Property labelDisabledClass As %ZEN.Datatype.cssClass [ InitialExpression = {..#DEFAULTLABELDISABLEDCLASS} ];

/// User defined style used for the component label.
Property labelStyle As %ZEN.Datatype.style;

/// Controls whether a label is displayed for this component.<br/>
/// If false do not display a label for this component.
/// If labels are displayed to the left, the Layout Manager
/// will attempt to give the space allocated for the label to the
/// component as well. This makes this option useful for
/// placing labels between sections in forms.
Property showLabel As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// User defined hint text used to display additional hint text for this component.
/// If specified, the hint text is drawn below the component.
Property hint As %ZEN.Datatype.caption;

/// Optional CSS class used for the component hint.
Property hintClass As %ZEN.Datatype.cssClass [ InitialExpression = {..#DEFAULTHINTCLASS} ];

/// User defined style used for the component hint.
Property hintStyle As %ZEN.Datatype.style;

/// Help text (tool tip) displayed when mouse hovers over this component (or its label).
Property title As %ZEN.Datatype.caption;

/// If true, this component is hidden. That is, its enclosing
/// element's display style is set to "none".
Property hidden As %ZEN.Datatype.boolean(ZENEXPRESSION = 1) [ InitialExpression = {..#DEFAULTHIDDEN} ];

/// onshow event handler:
/// This event is fired when this component is made visible.
Property onshow As %ZEN.Datatype.eventHandler;

/// onhide event handler:
/// This event is fired when this component is made hidden.
Property onhide As %ZEN.Datatype.eventHandler;

/// onrefresh event handler:
/// This event is fired when the contents of this component are
/// refreshed from the server.
Property onrefresh As %ZEN.Datatype.eventHandler;

/// If this value is true and dragAndDrop is enabled for the page, then
/// this component can serve as a drag source (i.e., users can
/// start a drag and drop operation over this component).
/// The actual behavior is determined by the subclass implementation.
Property dragEnabled As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If this value is true and dragAndDrop is enabled for the page, then
/// this component can serve as a drag target (i.e., users can
/// end a drag and drop operation over this component).
/// The actual behavior is determined by the subclass implementation.
Property dropEnabled As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// onbeforedrag event handler:
/// If this value is true and <property>dragEnabled</property> is
/// true and drag-and-drop is enabled for the current page,
/// then this event is raised when a drag operation has 
/// been initiated within this component but before the component has 
/// started to process the event. This is for cases where you want to 
/// override the default drag behavior of a component.
Property onbeforedrag As %ZEN.Datatype.eventHandler(HANDLER = "");

/// ondrag event handler:
/// If this value is true and <property>dragEnabled</property> is
/// true and drag-and-drop is enabled for the current page,
/// then this event is raised when a drag operation has 
/// been initiated within this component.
Property ondrag As %ZEN.Datatype.eventHandler(HANDLER = "");

/// onafterdrag event handler:
/// If this value is true and <property>dragEnabled</property> is
/// true and drag-and-drop is enabled for the current page,
/// then this event is raised when a drag operation that started
/// within this component completes.
Property onafterdrag As %ZEN.Datatype.eventHandler(HANDLER = "");

/// ondrop event handler:
/// If this value is true and <property>dropEnabled</property> is
/// true and drag-and-drop is enabled for the current page,
/// then this event is raised when a drop operation occurs 
/// within this component.
Property ondrop As %ZEN.Datatype.eventHandler(HANDLER = "");

/// CSS style applied to the td element used to contain this child component within
/// its parent group's layout table. This overrides the parent group's <property>cellStyle</property> property
/// for this child. Typically this is used to provide padding or alignment for
/// a specific component. This only applies to layout strategies that use tables.
Property containerStyle As %ZEN.Datatype.style;

/// Specifies how this component should be horizontally aligned within its layout cell.
Property align As %ZEN.Datatype.align;

/// Specifies how this component should be vertically aligned within its layout cell.
Property valign As %ZEN.Datatype.valign;

/// Specifies the width of this component with respect to its container.
Property width As %ZEN.Datatype.length [ InitialExpression = {..#DEFAULTWIDTH} ];

/// Specifies the height of this component with respect to its container.
Property height As %ZEN.Datatype.length [ InitialExpression = {..#DEFAULTHEIGHT} ];

/// User-defined number of <i>units</i> of relative space this 
/// component's layout cell takes up within its group along the group layout direction.
/// This may be used by a layout manager when calculating layout requirements.
Property slice As %ZEN.Datatype.integer(MINVAL = 0);

/// Optional CSS class used for this component's enclosing div.
Property enclosingClass As %ZEN.Datatype.cssClass [ InitialExpression = {..#DEFAULTENCLOSINGCLASS} ];

/// Optional CSS style applied to this component's enclosing div.
Property enclosingStyle As %ZEN.Datatype.style;

/// Internal property<br>
/// Used to track the current overlay mode of this component.
Property overlayMode As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0, Internal ];

/// Internal property<br>
/// Used to keep track of components that were added dynamically to forms.
Property dynamic As %ZEN.Datatype.boolean(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0, Internal ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
/* @doc="Default style for labels." */
.zenLabel {
	padding-right: 3px;
}

/* @doc="Default style for labels for disabled components." */
.zenLabelDisabled {
	padding-right: 3px;
	color: gray;
}

/* @doc="Default style for hint text." */
.zenHint {
	font-size: 0.8em;
}

/* @doc="Default label style for required fields." */
.zenRequired {
	font-weight: bold;
	padding-right: 3px;
}

/* @doc="Default after text for required fields." */
.zenRequired:after {
	content: " *";
}

/* @doc="Style for components with invalid values." */
.zenInvalid {
	background: #FFA0A0;
}

/* @doc="Style for error messages for controls." */
.zenError {
	color: red;
	font-size: 90%;
	padding-left: 2px;
	padding-right: 2px;
}
.zenError:before {
	content: "[";
}
.zenError:after {
	content: "]";
}

/* transparent overlay */
.zenOverlay {
	border: 1px dotted darkblue;
	position: fixed;
	z-index: 2;
	background: none;
}

.zenOverlaySelected {
	border: 2px solid darkblue;
	position: fixed;
	z-index: 2;
	background: none;
}

/* @doc="Progress bar indicator." */
.zenProgressBar {
	border: 1px solid black;
	background: #DDDDFF;
	table-layout: fixed;
}

/* @doc="Thumb of progress bar indicator." */
.zenProgressBarThumb {
	border: 1px solid black;
	background: blue;
}

</style>
}

/// Draw enclosing div element and then draw contents within it.
Method %DrawComponentHTML(pStyle As %String = "") [ Final ]
{
	If ($IsObject($Get(%page)) && %page.designMode) {
		#; design mode; delegate rendering
		Do ##class(%ZEN.Controller).%DrawComponentHTML($this,pStyle)
		Quit
	}

	Set tStyleLen = $Length(..enclosingStyle)
	if (tStyleLen>0) {
		if ($Extract(..enclosingStyle,tStyleLen)'=";") {
			Set ..enclosingStyle = ..enclosingStyle _ ";"
		}
	}
	Set style = pStyle _ ..enclosingStyle _ $S($$$ZENVAL(..hidden)&&(pStyle'["display: none;"):"display: none;",1:"")	
	#; set up drag/drop handlers, if needed
	Set tDragHandler = $S(..dragEnabled:" zenPage.getComponent("_..index_").dragHandler();",1:"")
	Set tDropHandler = $S(..dropEnabled:" zenPage.getComponent("_..index_").dropHandler();",1:"")
	Write "<div class=""",..enclosingClass,""" id=""",..%EnclosingDivId(),""" zen=""",..index,""" ",..%Attr("style",style),..%Attr("ondatadrag",tDragHandler)," ",..%Attr("ondatadrop",tDropHandler),..%OnDrawEnclosingDiv(),">"	
	Do ..%DrawHTML()
	Write "</div>",!
}

/// This callback, if defined, makes it possible for a subclass to inject
/// additional attributes into the enclosing div element for a component.
/// If implemented, this method should return a string with a leading space to 
/// avoid conflict with other attributes.
Method %OnDrawEnclosingDiv() As %String [ CodeMode = expression ]
{
""
}

/// Compute the HTML id value used for an enclosing div.
/// Use component id for enclosing div; if not defined
/// use zen#, where # is the index number.
Method %EnclosingDivId() [ CodeMode = expression, Final ]
{
$S(..id="":"zen"_..index,1:..id)
}

/// This method, called from a client page, invokes this component's
/// <method>%DrawHTML</method>, converts its output to a JavaScript string
/// and replaces the component's enclosing div with this new HTML. This 
/// is useful for components that need to refresh their contents from the server
/// after being rendered.<br>
/// Internally, this refresh can occur immediately or be deferred
/// as specified by the zenRefreshMode flag.<br>
/// If <var>sync</var> is defined and is true, the refresh will be executed
/// synchronously (unless we are in deferred mode).
ClientMethod refreshContents(sync) [ Final, Language = javascript ]
{
	if (!this.visible) { return; }

	switch (zenRefreshMode) {
	case 0:
		if (sync) {
			var old = zenSynchronousMode;
			zenSynchronousMode = true;
		}	
		this.ReallyRefreshContents();
		if (sync) {
			zenSynchronousMode = old;
		}
		break;
	case 1:
		// deferred: add to list
		zenASSERT(zenThreadId!=null,'thread id should not be null',arguments);
		zenASSERT(zenRefreshList,'refresh list should not be null',arguments);
		zenRefreshList[zenThreadId][this.index] = this;
		break;
	}
}

/// Internal method.<br>
/// This is the server-side implementation of the <method>refreshContents</method>
/// method. Do not call this method directly.
Method ReallyRefreshContents() [ Internal, ZenMethod ]
{
	Set io="" // track mode for error trap
	Set $ZT="Trap"

	#; find our enclosing div
	&js<var enc = this.window.document.getElementById('#(..%EnclosingDivId())#');>
	&js<zenASSERT(enc,"Unable to find enclosing element.",arguments);>

	#; execute our %DrawHTML method and capture it as JavaScript
	Write "enc.innerHTML = '"

	#; use JS output to properly escape HTML for JS
	Set io = ##class(%ZEN.Controller).%BeginJSTranslation()
	#; note: use oref as we use #super to call this
	Do $this.%DrawHTML()
	Do ##class(%ZEN.Controller).%EndJSTranslation(io)
	Set io=""
	Write "';",!

	#; invoke client-side callback(s), if present
	#; make sure overlay mode is reapplied, if needed
	&js<var comp = zenPage.getComponent(#(..index)#);
	if (comp.overlayMode!=0) { comp.setOverlayMode(comp.overlayMode); }
	if (comp.onRefreshContents) { comp.onRefreshContents(); }
	zenInvokeCallbackMethod(comp.onrefresh,comp,'onrefresh'); 
	if (comp.exposeComponent) { comp.exposeComponent(); } >

	Quit
Trap
	Set $ZT=""
	Set tError = $ZE
	If (io'="") {
		Do ##class(%ZEN.Controller).%EndJSTranslation(io)
		Write "';",!
	}
	#; turn off progress bar, etc
	&js<var comp = zenPage.getComponent(#(..index)#);
	if (comp.onRefreshContents) { comp.onRefreshContents(); }
	zenInvokeCallbackMethod(comp.onrefresh,comp,'onrefresh'); >

	#; show alert
	&js<alert('ERROR in refreshContents: #($ZCVT(tError,"O","JS"))#\n-------------------');>

	Write "enc.innerHTML += '<div class=""zenError"">ERROR: ",$ZCVT($ZCVT(tError,"O","HTML"),"O","JS"),"</div>';"
	Quit
}

/// Client-side method returns the div element that encloses 
/// this component.
ClientMethod getEnclosingDiv() [ Final, Language = javascript ]
{
	return this.window.document.getElementById(('' == this.id) ? 'zen'+this.index : this.id);
}

/// Client-side method returns the HTML element that displays
/// the label for this component (if any).
ClientMethod getLabelElement() [ Final, Language = javascript ]
{
	return this.window.document.getElementById('zenlbl_'+this.index);
}

/// Client-side method returns the HTML element that displays
/// the hint for this component (if any).
ClientMethod getHintElement() [ Final, Language = javascript ]
{
	return this.window.document.getElementById('zenhint_'+this.index);
}

/// Expirimental: do not use.<br>
/// Set the overlay mode for this component.<br>
/// (An overlay is a transparent div placed atop a component
/// for the purpose of capturing events; it is used by the ZEN
/// Page editing utilities.)<br>
/// <var>mode</var> is the overlay mode:<br>
/// 0: turn off overlay.<br>
/// 1: turn on overlay.<br>
/// 2: turn on overlay, show indication that this component
/// is <em>selected</em>.
ClientMethod setOverlayMode(mode) [ Language = javascript ]
{
	var enc = this.getEnclosingDiv();
	if (!enc) return;

	// if we have an overlay remove it
	var overlay = this.window.document.getElementById('overlay_'+this.index);
	if (overlay) {
		enc.removeChild(overlay);
		delete overlay;
	}

	this.overlayMode = mode;

	// now, add an overlay if needed (note we may be called
	// for purpose of recreating the overlay).
	if (mode > 0) {
		var overlay = this.window.document.createElement('div');
		overlay.id = 'overlay_' + this.index;
		enc.appendChild(overlay);
	
		overlay.className = (2==mode) ? 'zenOverlaySelected' : 'zenOverlay';
		overlay.style.top = zenGetTop(enc) - 1 - zenGetTopScroll(enc);
		overlay.style.left = zenGetLeft(enc) - 1 - zenGetLeftScroll(enc);
		overlay.style.width = enc.offsetWidth;
		overlay.style.height = enc.offsetHeight;
	
		if (2==mode) {
			if (overlay.style.opacity != null) {
				// supports CSS
				overlay.style.background = 'yellow';
				overlay.style.opacity = '0.5';
			}
			else if (overlay.style.filter != null) {
				// MS filter
				overlay.style.background = 'yellow';
				overlay.style.filter = 'alpha(opacity=50)';
			}
		}
	
		overlay.onclick = new Function("zenPage.onoverlayHandler("+this.index+");");
	}
}

/// Start the display of a progress bar within display
/// area for this component.<br>
/// Typically this is used by components that refresh their contents
/// from the server (such as <class>tablePane</class>).<br>
/// <var>div</var>, if defined, is div element that will contain the
/// progress bar.
ClientMethod startProgressBar(div) [ Language = javascript ]
{
	this.stopProgressBar();
	if (!zenSynchronousMode) {
		// reset progress counter
		this._progressBarCount = 0;
		if (div) {
			this._progressBarDiv = div;
			delete this._progressBarDivWid;
			delete this._progressBarDivHgt;
		}
		else {
			// use enclosing div; remember its current size
			this._progressBarDiv = this.getEnclosingDiv();
			this._progressBarDivWid = this._progressBarDiv.offsetWidth;
			this._progressBarDivHgt = this._progressBarDiv.offsetHeight;
		}
		// wait longer first time
		this.progressBarTimerId = self.setTimeout("zenPage.getComponent("+this.index+").progressBarHandler()",zenProgressBarTimeout);
	}
}

/// Stop the timer used by the Progress bar.
ClientMethod stopProgressBar() [ Language = javascript ]
{
	if (this.progressBarTimerId) {
		self.clearTimeout(this.progressBarTimerId);
		this.progressBarTimerId = null;
	}
}

/// Internal method.<br>
/// Timer event handler used by the Progress bar.
ClientMethod progressBarHandler() [ Internal, Language = javascript ]
{
	this.progressBarTimerId = null;

	// increment progress counter
	this._progressBarCount++;

	// update progress indicator
	if (this._progressBarDiv) {
		var style = '';
		if (null != this._progressBarDivWid) {
			style += 'width: ' + this._progressBarDivWid + 'px;';
		}
		if (null != this._progressBarDivHgt) {
			style += 'height: ' + this._progressBarDivHgt + 'px;';
		}
		if ('' == style) {
			style = 'width: 100%';
		}
		this._progressBarDiv.innerHTML = '<div align="center" style="'+style+'"><table class="zenProgressBar" border="0" cellpadding="0" cellspacing="0" width="200px"><tr><td width="'+((this._progressBarCount%20)*10)+'px">&nbsp;</td><td class="zenProgressBarThumb" width="10px">&nbsp;</td><td width="99%">&nbsp;</td></tr></table></div>';
	}

	// restart timer (somewhat faster)
	this.progressBarTimerId = self.setTimeout("zenPage.getComponent("+this.index+").progressBarHandler()",75);
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'hidden':
		this.setHidden(value);
		break;

	case 'hint':
	case 'hintClass':
	case 'hintStyle':
		this[property] = value;
		var hint = this.getHintElement();
		if (hint) {
			switch(property) {
			case 'hint':
				hint.innerHTML = value;
				break;
			case 'hintClass':
				hint.className = value;
				break;
			case 'hintStyle':
				hint.style.cssText = value;
				break;
			}
		}
		else if (this.parent) {
			this.parent.refreshContents();
		}
		break;

	case 'label':
	case 'labelClass':
	case 'labelStyle':
		this[property] = value;
		// these deal with the label element
		var label = this.getLabelElement();
		if (label) {
			switch(property) {
			case 'label':
				label.innerHTML = value;
				break;
			case 'labelClass':
				label.className = value;
				break;
			case 'labelStyle':
				label.style.cssText = value;
				break;
			}
		}
		else if (this.parent) {
			this.parent.refreshContents();
		}
		break;

	case 'containerStyle':
	case 'align':
	case 'valign':
	case 'width':
	case 'height':
	case 'slice':
		// these affect the group this component is in
		this[property] = value;
		if (this.parent) {
			this.parent.refreshContents();
		}
		break;
	case 'enclosingClass':
		// apply to enclosing div
		this.enclosingClass = value;
		var enc = this.getEnclosingDiv();
		enc.className = value;
		break;
	case 'enclosingStyle':
		// apply to enclosing div
		this.enclosingStyle = value;
		var enc = this.getEnclosingDiv();
		enc.style.cssText = value;
		break;

	case 'dragEnabled':
	case 'dropEnabled':
		this[property] = value;
		break;

	default:
		return this.invokeSuper('setProperty',arguments);
		break;
	}
	return true;
}

/// If <var>flag</var> is true, hide this component
/// otherwise make it visible.
/// If present, invoke onshow or onhide callbacks.
ClientMethod setHidden(flag) [ Language = javascript ]
{
	var enc = this.getEnclosingDiv();
	zenASSERT(enc,"Unable to find enclosing element.",arguments);

	// invoke callback(s), if present
	if (flag) {
		zenInvokeCallbackMethod(this.onhide,this,'onhide');
	}
	else {
		zenInvokeCallbackMethod(this.onshow,this,'onshow');
	}

	this.hidden = flag;
	enc.style.display = this.hidden ? 'none' : '';

	// hide label if there is one
	var label = this.getLabelElement();
	if (label) {
		label.style.display = this.hidden ? 'none' : '';
	}
	// hide hint if there is one
	var hint = this.getHintElement();
	if (hint) {
		hint.style.display = this.hidden ? 'none' : '';
	}
	var labelCell = this.findElement('zenLayoutLabelCell');
	if (labelCell) {
		labelCell.style.display = this.hidden ? 'none' : '';
	}
	var wrapperCell = this.findElement('zenLayoutTableCell');
	if (wrapperCell) {
		wrapperCell.style.display = this.hidden ? 'none' : '';
	}
	if (!flag) {
		if (this.exposeComponent) {
			setTimeout('zenPage.getComponent('+this.index+').exposeComponent();',0);
		}
	}
}

/// Return whether this component is hidden.
ClientMethod getHidden() As %String [ Language = javascript ]
{
	return this.hidden;
}

/// This client callback is called just from refreshContents
/// just after the new HTML is delivered from the server.
ClientMethod onRefreshContents() [ Abstract, Language = javascript ]
{
}

/// This client callback is called from exposeComponent after
/// the element has been displayed on the screen.  This ia a synthetic event 
/// that fires when the page is first displayed, when the component or its containing
/// group is refreshed from the server, or when the component or its containing
/// group is displayed via a programmatic 'show()' call.  Note that setting the
/// style.display value from JavaScript DOES NOT trigger this event
ClientMethod onDisplayHandler() [ Abstract, Language = javascript ]
{
}

/// Notification that this component is about to become modal.
/// zindex is zindex value to use to make sure component is placed
/// above system-provided div element.
ClientMethod onStartModalHandler(zindex) [ Abstract, Language = javascript ]
{
}

/// Notification that this component is about to stop being modal.
ClientMethod onEndModalHandler(zindex) [ Abstract, Language = javascript ]
{
}

/// This client event, if present, is fired when a popup page has specified
/// this component as its parent and fires an action.<br>
/// <var>popupName</var> is the name of the popup window sending the action.<br>
/// <var>action</var> is the name of the action.<br>
/// <var>value</var> is the value associated with the action.<br>
ClientMethod onPopupAction(popupName, action, value) [ Abstract, Language = javascript ]
{
}

/// This manages the ondisplay event callback handling.  The display event
/// fires when the page is first displayed, when the component or its containing
/// group is refreshed from the server, or when the component or its containing
/// group is displayed via a programmatic 'show()' call.  Note that setting the
/// style.display value from JavaScript DOES NOT trigger this event. In general,
/// application code should not modify or overload this method; instead, use the
/// onDisplayHandler() to customize this processing.
ClientMethod exposeComponent() [ Language = javascript ]
{
	try {
		var div = this.getEnclosingDiv();
		if (!div) return;
		if (div.offsetWidth == 0 || div.offsetHeight == 0) return;

		if (this.onDisplayHandler) {
			this.onDisplayHandler();
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in exposeComponent.');
	}
}

/// This is called by the layout manager when a drag-and-drop operation
/// starts on this component.
ClientMethod dragHandler() [ Final, Language = javascript ]
{
	try {
		var dragData = new zenDragData();
		dragData.sourceComponent = this;
	
		// invoke onbeforedrag
		if ('' != this.onbeforedrag) {
			if (!zenInvokeCallbackMethod(this.onbeforedrag,this,'onbeforedrag','dragData',dragData)) {
				if (null == dragData.value) {
					// cancel drag
					dragData = null;
				}
				return dragData;
			}
		}
	
		if (!this.dragStartHandler || 
			!this.dragStartHandler(dragData) || 
			(null == dragData.value)) {
			// cancel	
			return null;
		}
		if ('' != this.ondrag) {
			if (!zenInvokeCallbackMethod(this.ondrag,this,'ondrag','dragData',dragData)) {
				// cancel
				return null;
			}
		}	
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in dragHandler.');
	}
	return dragData;
}

/// This is called by the layout manager when a drag-and-drop operation
/// ends on this component.
ClientMethod dropHandler() [ Final, Language = javascript ]
{
	try {
		var dragData = ZLM.getDragData();
		dragData.targetComponent = this;
	
		if ('' != this.ondrop) {
			if (!zenInvokeCallbackMethod(this.ondrop,this,'ondrop','dragData',dragData)) {
				return;
			}
		}
		if (this.dropStartHandler && !this.dropStartHandler(dragData)) {
			return;
		}
	
		// notify source
		if (dragData.sourceComponent) {
			dragData.sourceComponent.dragNotifyHandler(dragData);
		}
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in dropHandler.');
	}
}

/// This is called by the layout manager when a drag operation
/// that started on this component is completed (that is, after the
/// target component finished processing the drop).
ClientMethod dragNotifyHandler(dragData) [ Final, Language = javascript ]
{
	try {
		if (this.dragFinishHandler) {
			this.dragFinishHandler(dragData);
		}
		zenInvokeCallbackMethod(this.onafterdrag,this,'onafterdrag','dragData',dragData);
	}
	catch(ex) {
		zenExceptionHandler(ex,arguments,'Error in dragNotifyHandler.');
	}
}

/// This is called when a drag operation is started within this component.<br/>
/// This method is implemented by subclasses.
ClientMethod dragStartHandler(dragData) [ Abstract, Language = javascript ]
{
}

/// This is called when a data drop operation is started within this component.<br/>
/// This method is implemented by subclasses.
ClientMethod dropStartHandler(dragData) [ Abstract, Language = javascript ]
{
}

/// This is called when a drag operation started within this component
/// is completed.<br/>
/// This method is implemented by subclasses.
ClientMethod dragFinishHandler(dragData) [ Abstract, Language = javascript ]
{
}

}
