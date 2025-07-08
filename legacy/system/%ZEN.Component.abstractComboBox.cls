/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an abstract base class that provides common functionality
/// to the various combobox controls (such as <class>combobox</class> and 
/// <class>dataCombo</class>).<br>
/// A combobox consists of text control that displays the current (display) value of
/// the control, and a dropdown list (that appears when activated by the user) that
/// displays a set of options. The contents of the dropdown list are provided
/// by subclasses of this base class.<br>
/// A combobox is itself a subclass of the <class>text</class> control.
/// You can use the various methods defined by the <class>text</class> control to manipulate
/// the text box portion of the combobox.<br>
/// <br>
/// Note that unlike other controls, a combobox is not a simple wrapper around 
/// an HTML select control but is implemented using HTML primitives.
/// This is in order to provide additional functionality
/// than provided by the HTML select control (e.g., ability to edit values and, via subclassing, more
/// control over the contents of the drop down list.)
/// <div style="font-weight: bold;">Activating the dropdown list</div>
/// The dropdown list can be displayed in several manners. This behavior is 
/// defined by the <property>comboType</property> property.
/// 
Class %ZEN.Component.abstractComboBox Extends text [ Abstract, Deprecated, System = 3 ]
{

Parameter DEFAULTCONTROLCLASS = "comboboxInput";

/// Default image for button in normal state.
Parameter DEFAULTBUTTONIMAGE = "images/combobox.png";

/// Default image for button in down state.
Parameter DEFAULTBUTTONIMAGEDOWN = "images/comboboxpress.png";

/// Indicates that this combobox should cache its dropdown contents.
Parameter USECACHEDIV As BOOLEAN = 0;

/// Specifies how the dropdown box is activated for the combobox.<br>
/// <ul>
/// <li>"image" indicates that a user-clickable image should be displayed next to the combobox text box.</li>
/// <li>"button" indicates that a button should be displayed next to the combobox text box.</li>
/// <li>"timer" indicates the dropdown should appear shortly after the user enters a value within the combobox text box.</li>
/// </ul>
Property comboType As %ZEN.Datatype.string(VALUELIST = ",image,button,timer") [ InitialExpression = "image" ];

/// URI of image to display for the combo button in its normal state.
Property buttonImage As %ZEN.Datatype.uri [ InitialExpression = {..#DEFAULTBUTTONIMAGE} ];

/// URI of image to display for the combo button in its down (pressed) state.
Property buttonImageDown As %ZEN.Datatype.uri [ InitialExpression = {..#DEFAULTBUTTONIMAGEDOWN} ];

/// If true, then this is an editable combobox (a user can directly edit the value within the input box).
Property editable As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true, and if this is an editable combobox,
/// then values entered by the user are used as the value of the control,
/// otherwise the value is restricted to one of the choices within the dropdown list.
Property unrestricted As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Text (display) value of current item.
/// Do not access this directly; use getProperty('text') instead.
Property text As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// Caption used for the dropdown button when <property>comboType</property>
/// is "button".
Property buttonCaption As %ZEN.Datatype.caption;

/// Popup title used for the dropdown button when <property>comboType</property>
/// is "button" or "image".
Property buttonTitle As %ZEN.Datatype.caption;

/// Specifies how long to wait, in milliseconds, after user finishes typing
/// before showing the dropdown when <property>comboType</property> is "timer".
Property delay As %ZEN.Datatype.integer [ InitialExpression = 250 ];

/// Index (0-based) of current selected option.<br>
/// This is the ordinal position of the current item within the dropdown list.
Property selectedIndex As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// If defined, override default width of dropdown window.<br>
/// This is a CSS length value, e.g., "400px"
Property dropdownWidth As %ZEN.Datatype.length;

/// If defined, override default height of dropdown window.<br>
/// This is a CSS length value, e.g., "400px"
Property dropdownHeight As %ZEN.Datatype.length;

/// If true, allow the dropdown window to display horizontal scroll bars
/// if they are needed (and its current CSS style specifies them).
Property hzScroll As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Internal use only; client flag used to track if the
/// dropdown is visible.
Property isDropdownVisible As %ZEN.Datatype.boolean(XMLPROJECTION = "none") [ InitialExpression = 0 ];

/// If true, try and make the current item within the dropdown visible.<br>
Property scrollIntoView As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* @doc="Input box of combobox." */
.comboboxInput {
	background: white;
	vertical-align: middle;
	border-top: 1px solid black;
	border-bottom: 1px solid black;
	border-left: 1px solid black;
	border-right: none;
}

/* @doc="Input box of combobox in timer mode." */
.comboboxInputTimer {
}

/* @doc="Wrapper for dropdown of combobox." */
.comboboxDropDown {
	position: absolute;
	margin: 0px;
	top: 0px;
	left: 0px;
	background: white;
	border: 1px solid black;
	width: 250px;
	height: 250px;
	overflow: scroll;
}

/* @doc="Image button in combobox." */
.comboboxImgButton {
	background: white;
	vertical-align: middle;
	border-top: 1px solid black;
	border-bottom: 1px solid black;
	border-left: none;
	border-right: 1px solid black;
	/* attempt to scale button with text */
	width: 1.1em;
	height: 1.1em;
}

/* @doc="Text button in combobox." */
.comboboxTextButton {
	vertical-align: middle;
	font-size: 0.75em;
	border: 1px solid black;
	height: 100%;
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
}

.comboboxTextButton:hover {
	background: #404000;
	background-image: url(images/grad-yellow-10x100.png);
	background-repeat: repeat-x;
}

/* @doc="Table displaying combobox dropdown contents." */
.comboboxTable {
	background: white;
	width: 100%;
}

.comboboxTable td {
	white-space: nowrap;
	padding-right: 3px;
	padding-bottom: 2px;
}

/* @doc="Headers within combobox dropdown list." */
.comboboxTable th {
	white-space: nowrap;
	padding-right: 3px;
	padding-bottom: 2px;
	font-weight: bold;
	text-align: left;
	border-bottom: 1px solid #808080;
	background: #404040;
	background-image: url(images/grad-gray-10x30.png);
	background-repeat: repeat-x;
}

/* @doc="Item (tr) within combobox dropdown." */
.comboboxItem {
	width: 100%;
	color: black;
	cursor: pointer;
}

.comboboxItem a, .comboboxItemSelected a {
	width: 100%;
	display: block;
	text-decoration: none;
}

/* we have to use an anchor so that IE will recognize :hover */
.comboboxItem a:link, .comboboxItem a:active, .comboboxItem a:visited {
	color: black;
}

.comboboxItemSelected a:link, .comboboxItemSelected a:active, .comboboxItemSelected a:visited {
	color: white;
}

/* @doc="Mouse hover over selected item within combobox dropdown." */
.comboboxItemSelected a:hover {
	color: red;
}

/* @doc="Mouse hover over item within combobox dropdown." */
.comboboxItem a:hover {
	color: red;
}

/* @doc="Selected item (tr) within combobox dropdown." */
.comboboxItemSelected {
	width: 100%;
	color: white;
	cursor: pointer;
	background: #000040;
	background-image: url(images/grad-blue-10x30.png);
	background-repeat: repeat-x;
	border: 1px solid black;
}

/* @doc="Style for loading message within combobox dropdown." */
.comboboxLoading {
	font-style: italic;
	color: blue;
}

.debugsqlquerypre {
	white-space: normal;
}
</style>
}

/// Draw the input box and button for this combobox.<br>
/// Note that the actual value is placed in a hidden control as the
/// contents of the input box may not be the actual value.
Method %DrawHTML()
{
	#; find displayValue
	Set tDisplay = ..%GetDisplayValue($$$ZENVAL(..value))

	#; do not add this to set of events
	Set tIgnore("onkeypress")=""
	Set tIgnore("onchange")=""
	Set tIgnore("onblur")=""

	Set ..onchange=$$$ZENVALJS(..onchange)
	Set ..onkeypress=$$$ZENVALJS(..onkeypress)
	Set ..onblur=$$$ZENVALJS(..onblur)

	&html<<input type="hidden" id="#(..%MakeId("hidden"))#" #(..%Name())# #(..%Attr("value",..value))#/>>
	If (..comboType'="timer") {
		&html<<table border="0" cellspacing="0" cellpadding="0">>
	}

	#; render as one line as CR will mess up the display
	If (..comboType="image") {
		#; img button
		Set tTitle = $S(..buttonTitle="":"",1:"title="""_$ZCVT(..buttonTitle,"O","HTML")_"""")
		If (..dragEnabled) {
			#; simplify mouse handling
			&html<<tr><td style="white-space: nowrap"><input class="#(..controlClass)#" #(..%Attr("style",..controlStyle))# type="text" #(..%Attr("title",..title))# #(..%Attr("tabindex",..tabIndex))# #($S(..disabled:"disabled",1:""))# #($S(..editable:$S(..readOnly:"readonly",1:""),1:"readonly"))# id="#(..%MakeId("input"))#" #(..%Attr("size",..size))# #(..%Attr("value",tDisplay))# #(..%Attr("maxlength",..maxlength))# #(..%GetEventHandlers(.tIgnore))# onkeydown="zenPage.getComponent(#(..index)#).inputKeyHandler(event);" onblur="zenPage.getComponent(#(..index)#).inputBlurHandler(event);" onchange="zenPage.getComponent(#(..index)#).inputChangeHandler();"/><img src="#(..buttonImage)#" id="#(..%MakeId("btn"))#" #(tTitle)# class="comboboxImgButton" onclick="zenPage.getComponent(#(..index)#).showDropdown();"/></td></tr>>
		}
		Else {
			&html<<tr><td style="white-space: nowrap"><input class="#(..controlClass)#" #(..%Attr("style",..controlStyle))# type="text" #(..%Attr("title",..title))# #(..%Attr("tabindex",..tabIndex))# #($S(..disabled:"disabled",1:""))# #($S(..editable:$S(..readOnly:"readonly",1:""),1:"readonly"))# id="#(..%MakeId("input"))#" #(..%Attr("size",..size))# #(..%Attr("value",tDisplay))# #(..%Attr("maxlength",..maxlength))# #(..%GetEventHandlers(.tIgnore))# onkeydown="zenPage.getComponent(#(..index)#).inputKeyHandler(event);" onblur="zenPage.getComponent(#(..index)#).inputBlurHandler(event);" onchange="zenPage.getComponent(#(..index)#).inputChangeHandler();"/><img src="#(..buttonImage)#" id="#(..%MakeId("btn"))#" onmousedown="zenPage.getComponent(#(..index)#).comboboxButtonDown(event);" onmouseup="zenPage.getComponent(#(..index)#).comboboxButtonUp();" onmouseover="zenPage.getComponent(#(..index)#).comboboxMouseOver();" onmouseout="zenPage.getComponent(#(..index)#).comboboxMouseOut();" #(tTitle)# class="comboboxImgButton" onclick="zenPage.getComponent(#(..index)#).showDropdown();"/></td></tr>>
		}
	}
	ElseIf (..comboType="button") {
		#; text button
		Set tCaption = $S(..buttonCaption="":$$$Text("Search","%ZEN"),1:..buttonCaption)
		Set tTitle = $S(..buttonTitle="":"",1:"title="""_$ZCVT(..buttonTitle,"O","HTML")_"""")
		&html<<tr><td style="white-space: nowrap"><input class="#(..controlClass)#" #(..%Attr("style",..controlStyle))# type="text" #(..%Attr("title",..title))# #(..%Attr("tabindex",..tabIndex))# #($S(..disabled:"disabled",1:""))# #($S(..editable:$S(..readOnly:"readonly",1:""),1:"readonly"))# id="#(..%MakeId("input"))#" #(..%Attr("size",..size))# #(..%Attr("value",tDisplay))# #(..%Attr("maxlength",..maxlength))# #(..%GetEventHandlers(.tIgnore))# onkeydown="zenPage.getComponent(#(..index)#).inputKeyHandler(event);" onblur="zenPage.getComponent(#(..index)#).inputBlurHandler(event);" onchange="zenPage.getComponent(#(..index)#).inputChangeHandler();"/><input type="button" id="#(..%MakeId("btn"))#" #($S(..disabled:"disabled",1:""))# onclick="zenPage.getComponent(#(..index)#).showDropdown();" class="comboboxTextButton" #(tTitle)# value="#($ZCVT(tCaption,"O","HTML"))#"/></td></tr>>
	}
	ElseIf (..comboType="timer") {
		#; no button
		Set ..controlClass = "comboboxInputTimer"
		&html<<input class="#(..controlClass)#" #(..%Attr("style",..controlStyle))# type="text" #($S(..disabled:"disabled",1:""))# #(..%Attr("title",..title))# #(..%Attr("tabindex",..tabIndex))# #($S(..editable:$S(..readOnly:"readonly",1:""),1:"readonly"))# id="#(..%MakeId("input"))#" #(..%Attr("size",..size))# #(..%Attr("value",tDisplay))# #(..%Attr("maxlength",..maxlength))# #(..%GetEventHandlers(.tIgnore))# onkeydown="zenPage.getComponent(#(..index)#).inputKeyHandler(event);" onblur="zenPage.getComponent(#(..index)#).inputBlurHandler(event);" onchange="zenPage.getComponent(#(..index)#).inputChangeHandler();"/>>
	}

	If (..comboType'="timer") {
		&html<</table>>
	}

	If (+..#USECACHEDIV) {
		#; extra div to cache dropdown contents
		&html<<div style="display: none;" id="#(..%MakeId("cache"))#">>
		Do ..%OnDrawCacheDiv()
		&html<</div>>
	}
}

/// If implemented, allow control to provide initial contents of cache div.
Method %OnDrawCacheDiv() As %Boolean [ CodeMode = expression, Internal ]
{
1
}

/// Lookup up the display value for the combobox given
/// a logical value.<br>
/// This is called when the control is initially drawn.<br>
/// Note: this is implemented as an expression method; subclasses are
/// free to implement this as a regular method.
Method %GetDisplayValue(pValue As %String) As %String [ CodeMode = expression ]
{
pValue
}

/// Make dropdown visible
ClientMethod showDropdown() [ Language = javascript ]
{
	if (!this.disabled && !this.readOnly) {
		// clear flag
		this.buttonIsDown = false;
	
		// make drop down appear as modal element
		zenPage.startModal(this);

		// JMD813- always set keymode
		this.keyMode = true;
	}
}

/// Mouse down on combobox button
ClientMethod comboboxButtonDown(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt.preventDefault) {
		evt.preventDefault();
	}

	if (!this.disabled && !this.readOnly) {
		var btn = this.findElement('btn');
		if (btn) {
			btn.src = this.buttonImageDown;
		}
		this.buttonIsDown = true;
	}
}

/// Mouse up on combobox button
ClientMethod comboboxButtonUp() [ Language = javascript ]
{
	if (!this.disabled && !this.readOnly && this.buttonIsDown) {
		var btn = this.findElement('btn');
		if (btn) {
			btn.src = this.buttonImage;
		}
	}
}

/// Mouse over combobox button
ClientMethod comboboxMouseOver() [ Language = javascript ]
{
	if (!this.disabled && !this.readOnly && this.buttonIsDown) {
		var btn = this.findElement('btn');
		if (btn) {
			btn.src = this.buttonImageDown;
		}
	}
}

/// Mouse leaves combobox button
ClientMethod comboboxMouseOut() [ Language = javascript ]
{
	if (!this.disabled && !this.readOnly && this.buttonIsDown) {
		var btn = this.findElement('btn');
		if (btn) {
			btn.src = this.buttonImage;
		}
	}
}

/// Keydown within input control.
ClientMethod inputKeyHandler(evt) [ Language = javascript ]
{
	evt = evt ? evt : window.event;
	var idx = parseInt(this.selectedIndex,10);

	// trap keys
	if (this.isDropdownVisible) {
		switch(evt.keyCode) {
		case zenHOME:
			this.clearTimer();
			this.keyMode = true;
			if (evt.preventDefault) {
				evt.preventDefault();
			}
			this.selectItem(0,true,false);
			return false;
		case zenEND:
			this.clearTimer();
			this.keyMode = true;
			if (evt.preventDefault) {
				evt.preventDefault();
			}
			this.selectItem(this.getOptionCount()-1,true,false);
			return false;
		case zenUP:
			this.clearTimer();
			this.keyMode = true;
			if (evt.preventDefault) {
				evt.preventDefault();
			}
			if (idx > 0) {
				this.selectItem(idx - 1,true,false);
			}
			return false;
		case zenDOWN:
			this.clearTimer();
			this.keyMode = true;
			if (evt.preventDefault) {
				evt.preventDefault();
			}
			if (idx < (this.getOptionCount()-1)) {
				this.selectItem(idx + 1,true,false);
			}
			return false;
		case zenPAGEUP:
			this.clearTimer();
			this.keyMode = true;
			if (evt.preventDefault) {
				evt.preventDefault();
			}
			if (idx > 0) {
				this.selectItem((idx > 10) ? idx - 10 : 0,true,false);
			}
			return false;
		case zenPAGEDN:
			this.clearTimer();
			this.keyMode = true;
			if (evt.preventDefault) {
				evt.preventDefault();
			}
			var count = this.getOptionCount();
			if (idx < (count-1)) {
				this.selectItem((idx < count - 10) ? idx + 10 : count - 1,true,false);
			}
			return false;
		case zenESC:
			if (evt.preventDefault) {
				evt.preventDefault();
			}
			zenPage.endModal();
			return false;

		case zenENTER:
			this.clearTimer();
			if (this.keyMode) {
				// choose selected item!
				zenPage.endModal();
				this.selectItem(idx,false,true);
			}
			else {
				// refresh drop down
				this.renderDropdown();
			}
			return false;
		default:
			this.startTimer();
			this.keyMode = null;
			break;
		}
	}
	else {
		switch(evt.keyCode) {
		case zenDOWN:
		case zenENTER:
			// show drop down
			this.clearTimer();
			this.keyMode = true;
			this.showDropdown();
			return false;
		default:
			this.startTimer();
			break;
		}
	}

	// invoke callback, if present
	return zenInvokeCallbackMethod(this.onkeydown,this,'onkeydown');
}

/// Start (or restart) timer used by "timer" mode.
/// Users should not call this method.
ClientMethod startTimer() [ Internal, Language = javascript ]
{
	if ("timer" == this.comboType) {
		this.clearTimer();
		this.actionTimerId = self.setTimeout("zenPage.getComponent("+this.index+").timerHandler()",this.delay);
	}
}

/// Clear timer used by "timer" mode.
/// Users should not call this method.
ClientMethod clearTimer() [ Internal, Language = javascript ]
{
	if ("timer" == this.comboType) {
		if (this.actionTimerId) {
			self.clearTimeout(this.actionTimerId);
			this.actionTimerId = null;
		}
	}
}

/// This client method, if present, is called when this component is
/// removed from the page.
ClientMethod onDelete() [ Language = javascript ]
{
	this.clearTimer();
}

/// Timer event handler used by "timer" mode.
/// Users should not call this method.
ClientMethod timerHandler() [ Internal, Language = javascript ]
{
	if (this.isDropdownVisible) {
		// refresh drop down
		this.renderDropdown();
	}
	else {
		this.showDropdown();
	}
}

/// Change handler for input control.
/// Users should not call this method.
ClientMethod inputChangeHandler() [ Internal, Language = javascript ]
{
	if (this.unrestricted) {
		if (this.editable) {
			// apply user edit to control
			var hidden = this.findElement('hidden');
			var input = this.findElement('input');
			this.value = input.value;
			hidden.value = input.value;
		}

		// notify
		this.onchangeHandler();
	}
}

/// Blur handler for input control.
/// Users should not call this method.
ClientMethod inputBlurHandler(evt) [ Internal, Language = javascript ]
{
	evt = evt ? evt : window.event;

	this.clearTimer();

	if (this.isDropdownVisible && (!this.mouseDown)) {
		// add defensive code to ensure that the modal is actually visible
		var div = this.getDropDownDiv();
		if (div && (div.style.display != 'none')) {
			zenPage.endModal();
		}
		else {
			this.isDropDownVisible = false;
		}
	}

	// invoke callback, if present
	zenInvokeCallbackMethod(this.onblur,this,'onblur');
	return true;
}

/// User has pressed the mouse within an item in the DropDown box.
ClientMethod itemMouseDown(evt, idx) [ Internal, Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt.preventDefault) {
		evt.preventDefault();
	}

	// keep track of mouse down to manage focus
	this.mouseDown = true;
}

/// User has released the mouse within an item in the DropDown box.
ClientMethod itemMouseUp(evt, idx) [ Internal, Language = javascript ]
{
	evt = evt ? evt : window.event;
	if (evt.preventDefault) {
		evt.preventDefault();
	}

	// hide drop down
	zenPage.endModal();

	this.selectItem(idx,false,true);

	// make sure input has focus
	zenFocus(this.findElement('input'));
	this.mouseDown = false;
}

/// User has selected an item in the DropDown box.
/// If <var>show</var> is true, make item visible.
/// If <var>update</var> is true, update value of control.
ClientMethod selectItem(idx, show, update) [ Language = javascript ]
{
	var out = zenPage.getComponentById('events');

	// update value of main controls
	var input = this.findElement('input');
	var hidden = this.findElement('hidden');
	zenASSERT(input,'Unable to find input element',arguments);
	zenASSERT(hidden,'Unable to find hidden element',arguments);

	var value,text;
	
	// unhighlight old select
	if (parseInt(this.selectedIndex,10) >= 0) {
		var el = this.getItemEl(parseInt(this.selectedIndex,10));
		if (el) {
			el.className = 'comboboxItem';
		}
	}

	// find number of items in dropdown list
	var size = this.getOptionCount();

	if (idx < 0 || idx > size) {
		this.selectedIndex = -1;
		value = '';
		text = '';
	}
	else {
		idx = parseInt(idx,10);
		this.selectedIndex = idx;
		value = this.getOptionValue(idx);
		text = this.getOptionText(idx);

		var el = this.getItemEl(this.selectedIndex);
		if (el) {
			el.className = 'comboboxItemSelected';
			if (show && this.scrollIntoView) {
				if (this.selectedIndex == 0) {
					this.getDropDownDiv().scrollTop = 0;
				}
				else {
					zenScrollIntoView(this.getDropDownDiv(),el,!this.hzScroll);
				}
			}
		}
	}
	
	if (update) {
		this.value = value;
		this.text = text;
		hidden.value = value;
		input.value = text;

		// notify
		this.onchangeHandler();
	}
}

/// Return HTML element for given list item number.
ClientMethod getItemEl(idx) [ Language = javascript ]
{
	return this.findElement('item_' + idx);
}

/// Find the div element used to display the dropdown list.
ClientMethod getDropDownDiv() [ Language = javascript ]
{
	return self.document.getElementById('zenModalDiv');
}

/// Find the local div element used to cache the dropdown list.
ClientMethod getCacheDiv() [ Language = javascript ]
{
	return this.findElement('cache');
}

/// Adjust the placement and size of the dropdown box based on
/// current screen geometry and scrolling conditions.
ClientMethod adjustDropdownPosition() [ Language = javascript ]
{
	// find position of input element
	var div = this.getDropDownDiv();
	zenASSERT(div,'Unable to find dropdown div',arguments);
	var input = this.findElement('input');
	zenASSERT(input,'Unable to find input element',arguments);

	var iHgt = input.offsetHeight;
	var wScrollTop = zenGetPageScrollTop();
	var top,right;
	var obj = zenGetPageOffsets(input);

	// SAM010 
	if (div.nativeHeight) div.style.height=div.nativeHeight+"px";
	var dHgt = div.offsetHeight;
	
	var hgt = zenGetWindowHeight();
	var uSpace = obj.top - wScrollTop;	
	var dSpace = hgt-uSpace-iHgt-2;

	if (dHgt>dSpace) { // dropdown won't fit as is
		if (dSpace>uSpace) { // beneath is best option but must shorten menu
			if (!div.nativeHeight) div.nativeHeight = dHgt;
			div.style.height = (dSpace - 2) + "px";
			top = obj.top+iHgt;
		}
		else { // open dropdown upwards
			if (dHgt>uSpace) {
				if (!div.nativeHeight) div.nativeHeight = dHgt;
				div.style.height=(uSpace-2)+"px";
			}
			top = obj.top-div.offsetHeight;
		}
	}		
	else {  // Dropdown is fine where it is but need to be in page coordinates
		top = obj.top+iHgt;
	}	
	div.style.top = top + "px";
	div.style.left = obj.left + "px";
}

/// Notification that this component is about to become modal.
ClientMethod onStartModalHandler(zindex) [ Language = javascript ]
{
	
	// show the dropdown box
	var div = this.getDropDownDiv();
	zenASSERT(div,'Unable to find dropdown div',arguments);

	var input = this.findElement('input');
	zenASSERT(input,'Unable to find input element',arguments);

	// add event handler to div
	// (this is because IE raise mouse events if the scroll bar is clicked)
	div.onmousedown = new Function("event","zenPage.getComponent("+this.index+").mouseDown=true;");
	div.onmouseup = new Function("event","zenPage.getComponent("+this.index+").mouseDown=null;");

	// set up style for div
	div.className = 'comboboxDropDown';
	
	if (!this.hzScroll) {
		div.style.overflowX = 'hidden';
	}

	// apply instance styles
	if (zenIsHTML5 && (this.dropdownHeight == (''+parseFloat(this.dropdownHeight)))) this.dropdownHeight += 'px';
	div.style.height = this.dropdownHeight;
	if ('' == this.dropdownWidth) {
		var enc = this.getEnclosingDiv();
		div.style.width = enc.offsetWidth + 'px';
	}
	else {
		if (zenIsHTML5 && (this.dropdownWidth == (''+parseFloat(this.dropdownWidth)))) this.dropdownWidth += 'px';
		div.style.width = this.dropdownWidth;
	}

	// make sure we are placed above mouse trap
	div.style.zIndex = zindex;
	div.style.display = "";	
	this.adjustDropdownPosition();
	// display the contents of the drop down
	this.renderDropdown();
}

/// Notification that this component is about to stop being modal.
ClientMethod onEndModalHandler(zindex) [ Language = javascript ]
{
	this.clearTimer();
	
	// copy contents of dropdown to our cache div
	var div = this.getDropDownDiv();
	var cache = this.getCacheDiv();
	if (cache) {
		if ('' != div.innerHTML) {
			// somehow this prevents FireFox warning...
			cache.style.cssText='display: none;';
			cache.innerHTML = div.innerHTML;
			div.innerHTML = '';
			this._hasCache = true;
		}
		else {
			cache.innerHTML = '';
			delete this._hasCache;
		}
	}

	// hide the DropDown box
	div.style.cssText = "display:none;";

	// restore state
	div.className = "";
	div.mousedown = null;
	div.mouseup = null;
	this.isDropdownVisible = false;
	this.keyMode = null;

	// give focus to input box
	zenFocus(this.findElement('input'));
}

/// This client event is fired when the page is resized and the dropdown is
/// visible.  Resizing the window while the dropdown is open can cause the
/// base component and its dropdown to become detached, this method traps such
/// occuranences and allows the dropdown to be repositioned.
ClientMethod onresizeHandler() [ Language = javascript ]
{
	if (this.isDropdownVisible) {
		this.adjustDropdownPosition();
	}
}

/// Set the value of a named property.<br>
/// Assume that subclasses that simply wrap HTML controls
/// have named the control 'control' or else have overridden
/// this method.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var input = this.findElement('input');
	var hidden = this.findElement('hidden');
	var btn = this.findElement('btn');

	switch(property) {
	case 'value':
		this.value = value;
		if (hidden) { hidden.value = value; }
		if (input) { input.value = ''; }

		// if we are "unrestricted" use value as value, and value2 as text value
		if (this.unrestricted) {
			if (input) { input.value = (null==value2) ? value : value2; }
		}
		else {
			// find item that most closely matches this logical value
			var text = this.findDisplayValue(this.value);
			if (null != text) {
				if (input) { input.value = text; }
				this.text = text;
			}
		}
		break;
	case 'text':
		// readonly
		break;
	case 'unrestricted':
		value = (value) ? true : false;
		this.unrestricted = value;
		break;
	case 'controlStyle':
		this.controlStyle = value;
		if (input) { input.style.cssText = value;	}
		break;
	case 'disabled':
		value = (value) ? true : false;
		if (input) {input.disabled = value;}
		if (btn) {btn.disabled = value; }
		this.disabled = value;

		// dispatch to disable labels
		this.invokeSuper('setProperty',arguments);
		break;
	case 'readOnly':
		value = (value) ? true : false;
		if (input) {input.readOnly = this.editable ? value : true;}
		if (btn) { btn.disabled = value; }
		this.readOnly = value;
		break;
	case 'buttonImage':
		this.buttonImage = value;
		var btn = this.findElement('btn');
		if (btn) { btn.src = this.buttonImage; }
		break;
	case 'buttonImageDown':
		this.buttonImageDown = value;
		break;

	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}

	return true;
}

/// Create contents of the dropdown box using DHTML.<br>
/// This is overridden in subclasses.
ClientMethod renderDropdown() [ Language = javascript ]
{
	var div = this.getDropDownDiv();
	zenASSERT(div,'Unable to find DropDown element',arguments);

	div.innerHTML = "";
}

/// Find and select item within the dropdown that matches current control value.
/// This is called when the dropdown appears to make sure that the current
/// item is highlighted.
ClientMethod findSelectedItem(force) [ Language = javascript ]
{
	force = ('undefined'!=force)?force:false;
	if ((force||this.isDropdownVisible) && this.value != '') {
		var count = this.getOptionCount();
		for (var idx = 0; idx < count; idx++) {
			if (this.value == this.getOptionValue(idx)) {
				this.selectItem(idx,true,false);
				break;
			}
		}
	}
}

/// Given a logical value, lookup the display value within the current set of
/// options. Returns null if no match is found.<br>
/// Subclasses may override this to add additional lookup behavior.
ClientMethod findDisplayValue(value) [ Language = javascript ]
{
	if ('' === value) {
		return '';
	}
	var text = null;
	
	// find item that most closely matches the value
	var count = this.getOptionCount();
	for (var idx = 0; idx < count; idx++) {
		if (value == this.getOptionValue(idx)) {
			text = this.getOptionText(idx);
			break;
		}
	}
	
	return text;
}

/// Return number of items in the dropdown list.<br>
/// This must be overridden in subclasses.
ClientMethod getOptionCount() [ Language = javascript ]
{
	return 0;
}

/// Return the logical value of the given item (0-based) in the dropdown list.<br>
/// This must be overridden in subclasses.
ClientMethod getOptionValue(idx) [ Language = javascript ]
{
	return '';
}

/// Return the display text for the given item (0-based) in the dropdown list.<br>
/// This must be overridden in subclasses.
ClientMethod getOptionText(idx) [ Language = javascript ]
{
	return '';
}

/// Client-side method to input focus to this control.
ClientMethod focus() [ Language = javascript ]
{
	// default implementation
	zenFocus(this.findElement('input'));
}

/// Default drag handler for comboBox.
ClientMethod dragStartHandler(dragData) [ Language = javascript ]
{
	// get drag data
	if (!this.getDragData(dragData) || (''==this.text)) {
		return false;
	}

	ZLM.setDragCaption(this.text);
	return true;
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	// make sure selectedIndex is set
	this.findSelectedItem(true);
}

}
