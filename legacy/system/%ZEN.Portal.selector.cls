/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Selector component for Portal applications.
/// This is a specialized form of text control that 
/// allows for free form text entry or context-aware selection from a list.
Class %ZEN.Portal.selector Extends %ZEN.Component.control [ Deprecated, System = 3 ]
{

Parameter DEFAULTCONTROLCLASS = "selectorInput";

/// Size of the input area for this text control.
Property size As %ZEN.Datatype.integer(MINVAL = 0);

/// Context string used to determine the selection list for this component.<br/>
/// A context string take the form of a URL:<br/>
/// SearchClass/SearchName?parm1=value&parm2=value<br/>
/// <i>SearchClass</i> is the name of a <class>%ZEN.Portal.ContextSearch</class>
/// search class that contains the search to perform.<br/>
/// <i>SearchName</i> is the name of the search method to invoke within
/// the search class.<br/>
Property context As %ZEN.Datatype.uri;

/// Flag to indicate whether multiSelect mode should be used when displaying the dropdown menu.
/// If this value is true, then the contents of the control are treated as a delimited list using
/// <property>separator</separator> as the delimiter. The dropdown will then present the user with a list
/// of checkboxes with the previously entered values checked. Checking and unchecking values will toggle
/// whether the property is included in the list.<br/>
/// NOTE: MultiSelect mode should not be used in conjunction with context-based lookups, as the behaviour
/// which could come from this approach would not be intuitive or easy to use.
Property multiSelect As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Define what delimiter to use for list properties when <property>multiSelect</property> is true.
Property separator As %ZEN.Datatype.string [ InitialExpression = "," ];

/// onkeyup event handler:
/// This event is fired when a key is released when this control has focus.
/// The HANDLER parameter is used to trigger the default onkeyup handler defined in
/// <method>onkeyupHandler</method>. If onkeyup is specified in the component,
/// then that specific code will be invoked rather than that in the default event handler, and it
/// is then the responsibility of the developer to call the <method>onkeyupHandler</method> function
/// defined in this class.
Property onkeyup As %ZEN.Datatype.eventHandler(HANDLER = """_$select((..onkeyup'=""""): ""return zenFireEvent('""_..index_""','""_$ZCVT($S(..onkeydown'[""#("":..onkeydown,1:..%Eval(..onkeydown,""JS"")),""O"",""JS"")_""','onkeydown',event);"", 1: ""zenPage.getComponent(""_..index_"").onkeyupHandler(event,""_..index_"");"")_""");

/// defines style sheet used by this component
XData CSS3Style
{
<style type="text/css">

/* @doc="Style for div around active selector." */
.selectorDiv {
	border: 1px solid #8080D0;
	background: white;
	height: 18px;
}

/* @doc="Style for selector input control." */
.selectorInput {
	border: none;
}

.selectorIcon {
	padding: 1px;
	width: 18px;
	height: 18px;
}

.selectorIcon:hover {
	padding: 0px;
	background: #FFEEAA;
	border-top: 1px solid silver;
	border-left: 1px solid silver;
	border-right: 1px solid darkgray;
	border-bottom: 1px solid darkgray;
	border-radius: 4px;
}

.selectorModalBox {
	/*width: 300px;*/
	height: 250px;
	overflow: hidden;
	overflow-y: auto;
	background: white;
	padding: 2px;
	box-shadow: 2px 2px 2px #808080;
	border: 1px solid #808080;
}

.selectorItem,.selectorItemOdd {
	display: block;
	color: #404040;
	text-decoration: none;
	font-size: 0.8em;
	padding: 2px;
	font-family: arial;
}

.selectorItemOdd {
	background: #F8F8F8;
}

.selectorItem:hover, .selectorItemOdd:hover {
	color: white;
	background: rgb(47,98,128);
}

.selectorCaption {
	color: gray;
	font-size: 8pt;
	text-align: center;
}

</style>
}

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* @doc="Style for div around active selector." */
.selectorDiv {
	border: 1px solid #8080D0;
	background: white;
	height: 18px;
}

/* @doc="Style for selector input control." */
.selectorInput {
	border: none;
}

.selectorIcon {
	padding: 1px;
	width: 18px;
	height: 18px;
}

.selectorIcon:hover {
	padding: 0px;
	background: #FFEEAA;
	border-top: 1px solid silver;
	border-left: 1px solid silver;
	border-right: 1px solid darkgray;
	border-bottom: 1px solid darkgray;
	-moz-border-radius: 4;
	-webkit-border-radius: 4;
}

.selectorModalBox {
	/*width: 300px;*/
	height: 250px;
	overflow: hidden;
	overflow-y: auto;
	background: white;
	padding: 2px;
	box-shadow: 2px 2px 2px #808080;
	border: 1px solid #808080;
}

.selectorItem,.selectorItemOdd {
	display: block;
	color: #404040;
	text-decoration: none;
	font-size: 0.8em;
	padding: 2px;
	font-family: arial;
}

.selectorItemOdd {
	background: #F8F8F8;
}

.selectorItem:hover, .selectorItemOdd:hover {
	color: white;
	background: rgb(47,98,128);
}

.selectorCaption {
	color: gray;
	font-size: 8pt;
	text-align: center;
}

</style>
}

/// Draw content of control.
Method %DrawHTML()
{
	Set disabled = $S(..disabled:"disabled",1:"")
	Set ro = $S(..readOnly:"readonly",1:"")
	Set tTitle = $$$Text("Show list of available choices.","%ZEN")
	Set tHideImage = 0
	If (..disabled || ..readOnly || (..context="")) {
		Set tHideImage = 1
	}
	Set tIcon = "portal/disc_down.gif"
	&html<<div class="selectorDiv" id="#(..%MakeId("div"))#" style="opacity:0.1;width:#((..size*7)+22)#px;"><nobr>
	<input type="text" class="#(..controlClass)#" #(..%Attr("title",..title))# id="#(..%MakeId("control"))#" #(..%Name())# #(disabled)# #(ro)# #(..%Attr("value",..value))# #(..%Attr("size",..size))# #(..%Attr("style",..controlStyle))# #(..%Attr("tabindex",..tabIndex))# #(..%GetEventHandlers())#/><image class="selectorIcon" align="top" src="#(tIcon)#" #($select(tHideImage: "style=""display: none;""", 1:""))# id="#(..%MakeId("icon"))#" title="#(tTitle)#" onclick="zenPage.getComponent(#(..index)#).showSelector();"/>
	</nobr></div>>
}

/// User has pressed the selector button.
ClientMethod showSelector() [ Language = javascript ]
{
	// Only draw the dropdown if the selector is not disabled, not readOnly and has a context
	if (!(this.disabled || this.readOnly || (this.context == ''))) {
		// resolve parameters within the context string
		// these are preceded by @:  var=@id

		var context = this.context.toString();
		var t = context.split('@');
		if (t.length > 1) {
			var context = t[0];
			for (var n = 1; n < t.length; n++) {
				var t2 = t[n].split('&'); // pull off value
				var id = t2[0];
				// find control with given id
				var ctrl = zenPage.getComponentById(id);
				t2[0] = (ctrl && ctrl.getValue) ? ctrl.getValue() : '';
				context += t2.join('&');
			}
		}
		var multiSelect = (this.multiSelect ? 1 : 0);

		zenPage._selectorHTML = '';
		var ok = this.RenderDropdownContent(this.index,context,this.getValue(),this.multiSelect,this.separator);
		if (zenPage._selectorHTML) {
			this.showDropdown(zenPage._selectorHTML);
		}
	}
}

/// Get the HTML contents of the dropdown area for the selector.<br/>
/// <var>pContext</var> is the (resolved) context string for the control.<br/>
/// <var>pSearchKey</var> is the current contents of the control.<br/>
/// <var>pMultiSelect</var> is a flag to indicate whether a multiSelect dropdown should be displayed.<br/>
/// <var>pSeparator</var> indicates which separator character should be used if <var>pMultiSelect</var> is true.<br/>
ClassMethod RenderDropdownContent(pIndex As %Integer, pContext As %String, pSearchKey As %String, pMultiSelect As %Boolean, pSeparator As %String = ",") As %Boolean [ ZenMethod ]
{
	Set io="" // track mode for error trap
	Set tRet = 1
	Set tSC = $$$OK
	Try {
		#; render content and capture it as JavaScript
		Write "zenPage._selectorHTML = '"

		#; use JS output to properly escape HTML for JS
		Set io = ##class(%ZEN.Controller).%BeginJSTranslation()

		Set tSC = ..%RenderDropdown(pIndex,pContext,pSearchKey,pMultiSelect,pSeparator)

		Do ##class(%ZEN.Controller).%EndJSTranslation(io)
		Set io=""
		Write "';",!
	}
	Catch(ex) {
		Set tRet = 0
		Set tSC = ex.AsStatus()
		If (io'="") {
			Do ##class(%ZEN.Controller).%EndJSTranslation(io)
			Write "';",!
		}
	}

	If $$$ISERR(tSC) {
		#; show error
		Set tError = $System.Status.GetErrorText(tSC)
		Write "zenPage._selectorHTML += '<div class=""zenError"">ERROR: ",$ZCVT($ZCVT(tError,"O","HTML"),"O","JS"),"</div>';"
	}
	Quit tRet
}

/// Render the HTML contents of the dropdown area for the selector.<br/>
/// <var>pContext</var> is the (resolved) context string for the control.<br/>
/// <var>pSearchKey</var> is the current contents of the control.<br/>
/// <var>pMultiSelect</var> is a flag to indicate whether a multiSelect dropdown should be displayed.<br/>
/// <var>pSeparator</var> indicates which separator character should be used if <var>pMultiSelect</var> is true.<br/>
ClassMethod %RenderDropdown(pIndex As %Integer, pContext As %String, pSearchKey As %String, pMultiSelect As %Boolean, pSeparator As %String = ",") As %Status
{
	Set tSC = $$$OK
	Try {
		Write "<div class=""selectorModalBox"">"
		Set tSearchKey = pSearchKey
		If pMultiSelect {
			Set tSearchKey = ""
		}
		// invoke search
		Set tCaption = ""
		Set tSC = ##class(%ZEN.Portal.ContextSearch).%Search(.tCaption,.tTopResults,.tResults,pContext,tSearchKey)
		If ($$$ISERR(tSC)) {
			Do $System.Status.DecomposeStatus(tSC,.tMsg)
			Write "<div>"_ $ZCVT(tMsg(1),"O","HTML") _ "</div></div>"
			Quit
		}
	
		If ('$D(tResults)) {
			Write "<div onclick=""zenPage.getComponent("_pIndex_").selectItem(null);""><i>"_$$$Text("No results","%ZEN") _ "</i></div></div>"
			Quit
		}

		If (tCaption '= "") {
			Write "<div class=""selectorCaption"">"_$ZCVT(tCaption,"O","HTML")_"</div>"
		}

		Set tRowNo = 0

		// show list of results
		If ($D(tTopResults)) {
			Set n = $O(tTopResults(""))
			While (n'="") {
				Set tRowNo = tRowNo + 1
				Write "<a class=""selectorItem"" href=""#"" onclick=""zenPage.getComponent("_pIndex_").selectItem('"_$ZCVT($Replace(tTopResults(n),"""","&quot;"),"O","JS")_"');return false;"">"_$ZCVT(tTopResults(n),"O","HTML")_"</a>"
				Set n = $O(tTopResults(n))
			}
			Write "<div style=""margin-bottom:1px; height:2px; border-bottom:1px solid gray;"">&nbsp;</div>"
		}
	
		If pMultiSelect {
			For i=$length(pSearchKey, pSeparator):-1:1 {
				Set tCurrVal = $zstrip($piece(pSearchKey, pSeparator, i),"<>W")
				If tCurrVal '= "" Set tCurrentValues(tCurrVal) = ""
			}
		}

		// iterate through the results
		Set n = $O(tResults(""))
		While (n'="") {
			Set tFound = 0
			Set tChecked = ""
			Set tResult = $get(tResults(n))
			Set tResultHTML = $ZCVT(tResult,"O","HTML")
			If pMultiSelect { // see if this is a current value
				Set tCurrVal = $O(tCurrentValues(""))
				While (('tFound) && (tCurrVal '= "")) {
					If (tCurrVal = tResult) {
						Set tChecked = " checked=""true"""
						Set tFound = 1
					}
					Set tCurrVal = $order(tCurrentValues(tCurrVal))
				}
				Write "<a class=""selectorItem"" href=""#"" title=""" _ tResultHTML _ """ onclick=""zenPage.getComponent("_pIndex_").selectItem('"_$ZCVT($Replace(tResult,"""","&quot;"),"O","JS")_"');return true;""><input id=""multiSelect."_pIndex_"."_tResultHTML_""" type=""checkbox"" "_tChecked_"/>"_ tResultHTML _"</a>"
			}
			Else {
				Set tRowNo = tRowNo + 1
				Write "<a class=""selectorItem"_$S(tRowNo#2:"",1:"Odd")_""" href=""#"" title=""" _ tResultHTML _ """ onclick=""zenPage.getComponent("_pIndex_").selectItem('"_$ZCVT($Replace(tResult,"""","&quot;"),"O","JS")_"');return false;"">"_tResultHTML_"</a>"
			}
			Set n = $O(tResults(n))
		}
		Write "</div>"
	}
	Catch(ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

/// Reveal the dropdown for this selector.
ClientMethod showDropdown(html) [ Internal, Language = javascript ]
{
	this._html = html;
	zenPage.startModal(this);
}

/// Notification that this component is about to become modal.
ClientMethod onStartModalHandler(zindex) [ Language = javascript ]
{
	// show the dropdown box
	var div = this.getModalDiv();
	zenASSERT(div,'Unable to find modal div',arguments);

	div.innerHTML = this._html;
	this._isModal = true;

	// set up style for div
	//div.className = 'selectorModalBox';
	
	// make sure we are placed above mouse trap
	div.style.zIndex = zindex;
	div.style.display = "";
	div.scrollTop = 0;
	
	this.adjustDropdownPosition();

	// register that we used the modal div!
	zenPage.lastModalIndex = this.index;
}

/// Notification that this component is about to stop being modal.
ClientMethod onEndModalHandler(zindex) [ Language = javascript ]
{
	var div = this.getModalDiv();
	delete this._html;
	this._isModal = false;

	// hide the DropDown box
	div.style.cssText = "display:none;";

	// restore state
	div.className = "";
	div.mousedown = null;
	div.mouseup = null;
}

/// This client event is fired when the page is resized and the dropdown is
/// visible. Resizing the window while the dropdown is open can cause the
/// base component and its dropdown to become detached, this method traps such
/// occurences and allows the dropdown to be repositioned.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	if (this._isModal) this.adjustDropdownPosition();
}

ClientMethod adjustDropdownPosition() [ Language = javascript ]
{
	if (!this._isModal) return;

	var width = '';
	var top = '';
	var left = '';
	var div = this.getModalDiv();
	if (div) {
		// set size/position
		div.style.position = 'absolute';
		var height = 250 + (2 * zenIsIE);
		div.style.height = height + 'px';
		var modalHeight = div.offsetHeight;
		var screenHeight = zenGetWindowHeight();
		var spaceUp,spaceDown;
		var isDown = true;

		var el = this.findElement('div');
		if (el) {
			var selectorBox = div.firstElementChild;
			if (selectorBox) selectorBox.style.height = '';
			width = el.offsetWidth;
			var winScrollTop = zenGetPageScrollTop();
			var elPos = zenGetPageOffsets(el);
			spaceUp = elPos.top - winScrollTop;
			spaceDown = screenHeight - spaceUp - el.offsetHeight - 2;
			
			if ((modalHeight + 2) > spaceDown) { // dropdown won't fit as is
				if (spaceDown > spaceUp) { // beneath is best option but must shorten menu
					div.style.height = (spaceDown - 2) + 'px';
					if (selectorBox) {
						var innerDiff = selectorBox.offsetHeight - 250;
						selectorBox.style.height = (spaceDown - 2 - innerDiff) + 'px';
					}
					top = elPos.top + el.offsetHeight + 2;
				}
				else { // open dropdown upwards
					if ((modalHeight + 2) > spaceUp) {
						div.style.height = (spaceUp - 2) + 'px';
						if (selectorBox) {
							var innerDiff = selectorBox.offsetHeight - 250;
							selectorBox.style.height = (spaceUp - 2 - innerDiff) + 'px';
						}
						top = 0;
					}
					else {
						top = elPos.top - modalHeight - 10;
					}
					isDown = false;
				}
			}		
			else {  // Dropdown is fine where it is but need to be in page coordinates
				top = elPos.top + el.offsetHeight + 2;
			}
			left = elPos.left;
		}
		
		if (width == '') width = 300;
		
		if (zenIsIE) {
			if (top != '') {
				top = top + (2 * isDown);
			}
			if (left != '') {
				left = left + 2;
			}
			if (width != '') {
				width = width + 2;
			}
		}

		if (top != '') {
			div.style.top = top + 'px';
		}
		if (left != '') {
			div.style.left = left + 'px';
		}
		div.style.width = width + 'px';
	}
}

/// Find the div element used to display modal popups.
ClientMethod getModalDiv() [ Language = javascript ]
{
	return self.document.getElementById('zenModalDiv');
}

/// User has selected an item in the dropdown list.
ClientMethod selectItem(value) [ Language = javascript ]
{
	if (!this.multiSelect) {
		if (null != value) {
			this.setValue(value);
		}
		zenPage.endModal(this);
		var el = this.findElement('control');
		try {
			el.focus();
		}
		catch(ex) {
		}
	}
	else {
		var currVal = this.getValue();
		var currArray = new Array();
		var currValues = new Object();
		if (currVal != '') {
			currArray = currVal.split(this.separator);
			for (var i=0; i<currArray.length; i++) {
				if (currArray[i] != '') {
					currValues[currArray[i]] = true;
				}
			}
		}
		if (value != null) {
			currValues[value] = !currValues[value];
		}
		var newValues = new Array();
		for (var i in currValues) {
			if (currValues[i]) {
				newValues[newValues.length] = i;
			}
			var checkbox = document.getElementById('multiSelect.'+this.index+'.'+i);
			if (checkbox) {
				checkbox.checked = currValues[i];
			}
		}
		this.setValue(newValues.join(this.separator));
	}

	// notify
	this.onchangeHandler();
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var el = this.findElement('control');

	switch(property) {
	case 'size':
		this.size = value;
		if (el) { el.size = value; }
		break;
	case 'context':
		this.context = value;
		var hideIcon = (value == '') || this.disabled || this.readOnly;
		this.toggleIconDisplay(hideIcon);
		break;
	case 'readOnly':
	case 'disabled':
		// update icon then dispatch to super
		var hideIcon = (!!value) || (property == 'readOnly' ? this.disabled : this.readOnly) || (this.context == '');
		this.toggleIconDisplay(hideIcon);
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

ClientMethod toggleIconDisplay(hide) [ Language = javascript ]
{
	var icon = this.findElement('icon');
	if (icon) {
		// short-circuit if we've already gone through the resize
		if (('undefined' !== typeof this._iconHidden) && ((!!this._iconHidden) == (!!hide))) return;
		// adjust control to take up extra space (or go back to normal)
		var control = this.findElement('control');
		if (control) {
			if (hide) {
				var div = this.findElement('div');
				if (div && (div.style.width != '') && (parseInt(div.style.width,10) > control.size)) {
					control.style.width = div.style.width;
				}
				else {
					control.style.width = (control.offsetWidth + control.offsetHeight) + 'px';
				}
			}
			else {
				control.style.width = '';
				control.style.height = '';
			}
		}
		icon.style.display = hide ? 'none' : '';
		this._iconHidden = !!hide;
		this.adjustSize();
	}
}

/// Default onkeyup handler to allow drop-down to be displayed (by pressing DOWN)
/// or hidden (by pressing ESCAPE). This method is only invoked if no onkeyup event
/// is defined for the selector using the standard onkeyup attribute. Should a developer
/// make use of the onkeyup callback, it is his/her responsibility to determine whether
/// this function should be invoked.
ClientMethod onkeyupHandler(event, index) [ Language = javascript ]
{
	if ((event) && (index) && (event.type == 'keyup')) {
		var keyCode = (zenIsIE ? event.keyCode : event.which);
		var selector = zenPage.getComponent(index);
		if (selector) {
			switch(keyCode) {
				case zenDOWN:
					if (!selector._isModal) {
						selector.showSelector();
					}
					break;
				case zenESC:
					if (selector._isModal) {
						zenPage.endModal(selector);
					}
					break;
			}
		}
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.adjustSize();
}

/// This client event, if present, is fired when the containing group is made visible.
ClientMethod onDisplayHandler() [ Language = javascript ]
{
	this.adjustSize();
}

/// Adjust size of control.
ClientMethod adjustSize() [ Language = javascript ]
{
	var el = this.findElement('control');
	var icon = this.findElement('icon');
	var div = this.findElement('div');
	if (el && icon && div) {
		div.style.opacity = 1.0;
		icon.style.width = el.offsetHeight + 'px';
		icon.style.height = el.offsetHeight + 'px';
		div.style.height = el.offsetHeight+2 + 'px';
		if (el.offsetWidth == 0) { // don't try anything if we don't have client geometry
			div.style.width = '';
			el.style.width = '';
		}
		else {
			div.style.width = el.offsetWidth + (this._iconHidden ? (zenIsIE * -2) : (el.offsetHeight+4)+(2*zenIsChrome)) + 'px';
			if (this._iconHidden) {
				el.style.width = (div.offsetWidth - 2 - (zenIsIE * 4)) + 'px';
				if (el.style.height == '') {
					el.style.height = (parseInt(div.style.height,10) - 3 - (zenIsIE * 2)) + 'px';
				}
			}
		}
	}
}

}
