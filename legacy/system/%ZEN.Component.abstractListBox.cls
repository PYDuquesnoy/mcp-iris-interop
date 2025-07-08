/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is an abstract base class that provides common functionality
/// to the various listBox controls.<br>
Class %ZEN.Component.abstractListBox Extends control [ Abstract, Deprecated, System = 3 ]
{

Parameter DEFAULTCONTROLCLASS = "listBox";

/// Index (0-based) of current selected option.<br>
/// This is the ordinal position of the current item within the item list.
Property selectedIndex As %ZEN.Datatype.integer [ InitialExpression = -1 ];

/// If defined, override default width of listBox.<br>
/// This is a CSS length value, e.g., "400px"
Property listWidth As %ZEN.Datatype.length;

/// If defined, override default height of listBox.<br>
/// This is a CSS length value, e.g., "400px"
Property listHeight As %ZEN.Datatype.length;

/// If true, allow this component to display horizontal scroll bars
/// if they are needed (and its current CSS style specifies them).
Property hzScroll As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// Text (display) value of current item.
/// Do not access this directly; use getProperty('text') instead.
Property text As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* @doc="Wrapper for listBox." */
.listBox {
	color: black;
	background: white;
	border: 1px black solid;
	width: 100%;
	height: 100px;
	overflow: auto;
}

/* @doc="Style for disabled list boxes." */
.listBoxDisabled {
	color: black;
	background: darkgray;
	border: 1px black solid;
	width: 100%;
	height: 100px;
	overflow: auto;
}

/* @doc="Item within listBox." */
.listBoxItem {
	white-space: nowrap;
	width: 100%;
	color: black;
	/* ie does not handle transparent */
	border: 1px solid white;
	cursor: pointer;
}

/* @doc="Selected item within listBox." */
.listBoxItemSelected {
	white-space: nowrap;
	width: 100%;
	color: black;
	background: #E0E0E0;
	font-weight: bold;
	border: 1px dotted #202060;
	cursor: pointer;
}

/* @doc="Selected item with focus within listBox." */
.listBoxItemFocus {
	white-space: nowrap;
	width: 100%;
	font-weight: bold;
	color: white;
	background: #5050F0;
	background-image: url(images/grad-blue-10x30.png);
	background-repeat: repeat-x;
	border: 1px solid black;
	cursor: pointer;
}

.listBoxItem:hover, .listBoxItemSelected:hover, .listBoxItemFocus:hover {
	color: red;
}

/* no hover when disabled */
.listBoxDisabled .listBoxItem:hover {
	color: black;
	background: darkgray;
}

.listBoxDisabled .listBoxItemSelected, .listBoxDisabled .listBoxItemSelected:hover, .listBoxDisabled .listBoxItemFocus {
	white-space: nowrap;
	width: 100%;
	color: gray;
	background: darkblue;
	font-weight: bold;
}

/* @doc="Table displaying dataListBox dropdown contents." */
.listBoxTable {
	background: white;
	width: 100%;
}

.listBoxTable td {
	white-space: nowrap;
	padding-right: 3px;
	padding-bottom: 2px;
}

/* @doc="Headers within combobox dropdown list." */
.listBoxTable th {
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

</style>
}

/// Draw HTML for this listBox.
/// Note that the actual value is placed in a hidden control.
Method %DrawHTML()
{
	Set lbStyle = ""
	Set:'..hzScroll lbStyle = "overflow-x: hidden;"
	Set:..listWidth'="" lbStyle = lbStyle_"width: " _ ..listWidth _ ";"
	Set:..listHeight'="" lbStyle = lbStyle_"height: " _ ..listHeight _ ";"
	Set:lbStyle'="" lbStyle = "style="""_lbStyle_""""

	#; find displayValue
	Set tDisplay = ..%GetDisplayValue(..value)

	#; hidden field to hold value
	&html<<input type="hidden" id="#(..%MakeId("hidden"))#" #(..%Name())# #(..%Attr("tabindex",..tabIndex))# #(..%Attr("value",..value))#/>>

	#; invisible field to catch key events
	&html<<div style="position:relative; display:block; height:0px; width:0px; overflow:hidden; font-size:0px; line-height:0px" >>
	&html<<input type="text" id="#(..%MakeId("invisible"))#" style="top:0px;left:0px;position:absolute;border: 0px solid green;width:0;height:0;" onkeydown="zenPage.getComponent(#(..index)#).lbKeyDownHandler(event);" onkeypress="zenPage.getComponent(#(..index)#).lbKeyPressHandler(event);" onfocus="if(zenPage){zenPage.getComponent(#(..index)#).lbKeyFocus();}" onblur="zenPage.getComponent(#(..index)#).lbKeyBlur();"/>>
	&html<</div>>
	
	#; draw listBox
	Set tCls = $S(+..disabled:"listBoxDisabled",1:..controlClass)
	&html<<div class="#(tCls)#" #(lbStyle)# #(..%Attr("title",..title))# id="#(..%MakeId("list"))#">>

	#; call server-side method to fill in contents of listBox
	#; (this may or may not be implemented)
	Do ..%DrawListContents()

	&html<</div>>
}

/// Server-side method to provide contents of the list box.
/// This is implemented by a subclass. If not implemented,
/// then the listbox will render its contents on the client.
Method %DrawListContents()
{
	Quit
}

/// Lookup up the display value for the listBox given
/// a logical value.<br>
/// This is called when the control is initially drawn.<br>
/// Note: this is implemented as an expression method; subclasses are
/// free to implement this as a regular method.
Method %GetDisplayValue(pValue As %String) As %String [ CodeMode = expression ]
{
pValue
}

/// Initialize additional client-side values
ClientMethod onCreate() [ Language = javascript ]
{
	this.hasFocus = false;
}

/// Client-side method to input focus to this control.
ClientMethod focus() [ Language = javascript ]
{
	// give focus to invisible control
	var inv = this.findElement('invisible');
	if (inv) {
		inv.focus();
	}
}

/// Focus passed to the invisible edit control.
ClientMethod lbKeyFocus() [ Language = javascript ]
{
	this.hasFocus = true;
	this.selectItem(this.selectedIndex);
}

/// Focus taken from the invisible edit control.
ClientMethod lbKeyBlur() [ Language = javascript ]
{
	this.hasFocus = false;
	this.selectItem(this.selectedIndex);
}

/// Process keydown event within the invisible edit control.
ClientMethod lbKeyDownHandler(evt) [ Language = javascript ]
{
	if (this.disabled) return false;
	if (this.readOnly) return false;
	evt = evt ? evt : window.event;
	var ret = true;

	var row = this.currRow;
	var col = this.currColumn;

	// test for event handler
	if (this.onkeydown != '') {
		ret = zenInvokeCallbackMethod(this.onkeydown,this,'onkeydown','evt',evt);
		if (!ret) return;
	}

	// trap keys
	switch(evt.keyCode) {
	case zenENTER:
		break;

	case zenPAGEUP:
		ret = false;
		this.moveToItem('pageup');
		break;
	case zenPAGEDN:
		ret = false;
		this.moveToItem('pagedn');
		break;

	case zenEND:
		ret = false;
		this.moveToItem('end');
		break;

	case zenHOME:
		ret = false;
		this.moveToItem('home');
		break;

	case zenUP:
		ret = false;
		this.moveToItem('up');
		break;
	case zenDOWN:
		ret = false;
		this.moveToItem('down');
		break;
	default:
		break;
	}

	if (!ret) {
		if (evt.preventDefault) {
			evt.preventDefault();
		}
		evt.cancelBubble = true;
	}

	return ret;
}

/// Process keypress event within the invisible edit control.
ClientMethod lbKeyPressHandler(evt) [ Language = javascript ]
{
	if (this.disabled) return false;
	if (this.readOnly) return false;
	evt = evt ? evt : window.event;
	var ret = true;

	// test for event handler
	if (this.onkeypress != '') {
		ret = zenInvokeCallbackMethod(this.onkeypress,this,'onkeypress','evt',evt);
		if (!ret) return;
	}

	// trap keys
	switch(evt.keyCode) {
	default:
		if (evt.ctrlKey || evt.altKey) {
			break;
		}
		var charCode = evt.charCode ? evt.charCode : evt.keyCode;
		// look for item starting with char
		if (charCode >= 32) {
			ret = false;
			var ch = evt.charCode ? String.fromCharCode(evt.charCode) : null;
			if (!ch && zenIsIE) ch = String.fromCharCode(charCode);

			if ('string' == typeof ch) {
				ch = ch.toUpperCase();
				var size = this.getOptionCount();
				var found = false;
				var start = this.selectedIndex+1;
				for (var pass = 0; pass < 2 && !found; pass++) {
					for (var i = start; i < size; i++) {
						var t = this.getOptionText(i);
						if ('string' == typeof t) {
							if (t.charAt(0).toUpperCase() == ch) {
								this.selectItem(i);
								found = true;
								break;
							}
						}
					}
					start = 0;
				}
			}
		}
		break;
	}
	return ret;
}

/// Return HTML element for given list item number.
ClientMethod getItemEl(idx) [ Language = javascript ]
{
	return this.findElement('item_' + idx);
}

/// Move to a new item in the listBox. <var>dir</var> is "up","down","left","right"
/// Returns true if move was successful.
ClientMethod moveToItem(dir) [ Language = javascript ]
{
	var ret = false;
	var idx = this.selectedIndex;
	var size = this.getOptionCount();

	switch(dir) {
	case 'up':
		if (idx > 0) {
			ret = true;
			this.selectItem(idx-1);
		}
		break;
	case 'down':
		if (idx < size-1) {
			ret = true;
			this.selectItem(idx+1);
		}
		break;
	case 'home':
		if (size > 0) {
			ret = true;
			this.selectItem(0);
		}
		break;
	case 'end':
		if (size > 0) {
			ret = true;
			this.selectItem(size - 1);
		}
		break;

	case 'pageup':
		if (size > 0) {
			ret = true;
			idx = idx > 10 ? idx - 10 : 0;
			this.selectItem(idx);
		}
		break;
	case 'pagedn':
		if (size > 0) {
			ret = true;
			idx = idx < (size - 10) ? idx + 10 : size-1;
			this.selectItem(idx);
		}
		break;
	}
	if (idx != this.selectedIndex) {
		this.onchangeHandler();
	}
	return ret;
}

/// User has selected an item in the list box.
ClientMethod selectItem(idx) [ Language = javascript ]
{
	// update value of main controls
	var hidden = this.findElement('hidden');
	zenASSERT(hidden,'Unable to find hidden element',arguments);

	var value,text;

	// unhighlight old item
	if (this.selectedIndex != -1) {
		var div = this.getItemEl(this.selectedIndex);
		if (div) {
			div.className = 'listBoxItem';
		}
	}

	// find number of items in list
	var size = this.getOptionCount();

	if (idx < 0 || idx > size) {
		this.selectedIndex = -1;
		value = '';
		text = '';
	}
	else {
		this.selectedIndex = idx;
		value = this.getOptionValue(idx);
		text = this.getOptionText(idx);
	}
	
	// highlight new item & make it visible
	if (this.selectedIndex != -1) {
		var div = this.getItemEl(this.selectedIndex);
		if (div) {
			div.className = (this.hasFocus&&!this.disabled) ? 'listBoxItemFocus' : 'listBoxItemSelected';

			if (this.hasFocus) {
				if (!this.divPending) {
					setTimeout("zenPage.getComponent("+this.index+").deferredScrollIntoView();",100);
				}
				this.divPending=div;
				this.encPending=this.findElement('list');
				this.hzScrollPending=!this.hzScroll;
			}
		}
	}

	hidden.value = value;
	this.value = value;
	this.text = text;
}

ClientMethod deferredScrollIntoView() [ Internal, Language = javascript ]
{
	// Experimental routine to collapse refresh events SAM###
	zenScrollIntoView(this.encPending,this.divPending,this.hzScrollPending);
	delete this.divPending;
	delete this.encPending;
	delete this.hzScrollPending;
}

/// User has clicked an item in the list box.
ClientMethod clickItem(idx) [ Language = javascript ]
{
	if (this.disabled) return;
	if (this.readOnly) return;
	var change = (idx != this.selectedIndex);

	this.focus();
	this.selectItem(idx);

	// notify
	if (change) {
		this.onchangeHandler();
	}
}

/// User has double-clicked an item in the list box.
ClientMethod dblClickItem(idx) [ Language = javascript ]
{
	if (this.disabled) return;

	// invoke callback, if present
	zenInvokeCallbackMethod(this.ondblclick,this,'ondblclick');
}

/// Mouse down handler for nodes.
ClientMethod itemMouseDown(evt, idx) [ Internal, Language = javascript ]
{
	if (this.dragEnabled) {
		evt = evt ? evt : window.event;
		if (evt.preventDefault) {
			evt.preventDefault();
		}
		this._dragSource = idx;
		var change = (idx != this.selectedIndex);
		this.selectItem(idx);
		if (change) {
			this.onchangeHandler();
		}
		return false;
	}
	return true;
}

/// Mouse up handler for nodes.
ClientMethod itemMouseUp(evt) [ Internal, Language = javascript ]
{
	if (this.dragEnabled) {
		evt = evt ? evt : window.event;
		if (evt.preventDefault) {
			evt.preventDefault();
		}
		delete this._dragSource;
		return false;
	}
	return true;
}

/// Default drag handler for list components.
ClientMethod dragStartHandler(dragData) [ Language = javascript ]
{
	var ok = false;
	var dragItem = this._dragSource;
	if (null != dragItem) {
		delete this._dragSource;
		var anchor = this.findElement('item_' + dragItem);
		if (anchor) {
			dragData.sourceItem = dragItem;
			ok = true;
			dragData.value = this.getOptionValue(dragItem);
			dragData.text = this.getOptionText(dragItem);

			// avatar
			var icon = anchor.cloneNode(true);
			icon.style.position ="absolute";
			icon.style.width = this.getEnclosingDiv().offsetWidth + 'px';
			icon.style.border = "1px solid darkgray";
			ZLM.setDragAvatar(icon);
		}
	}
	return ok;
}

/// Set the value of a named property.<br>
/// Assume that subclasses that simply wrap HTML controls
/// have named the control 'control' or else have overridden
/// this method.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	var hidden = this.findElement('hidden');

	switch(property) {
	case 'selectedIndex':
		value = parseInt(value);
		this.selectItem(value);
		break;
	case 'listHeight':
		this.listHeight = value;
		var list = this.findElement('list');
		if (list) {
			list.style.height = value;
		}
		break;
	case 'listWidth':
		this.listWidth = value;
		var list = this.findElement('list');
		if (list) {
			list.style.width = value;
		}
		break;
	case 'value':
		// find an item with this value
		var size = this.getOptionCount();
		for (var idx = 0; idx < size; idx++) {
			if (value == this.getOptionValue(idx)) {
				// select this one
				this.selectItem(idx);
			}
		}
		break;
	case 'text':
		break;
	case 'disabled':
		value = (value) ? true : false;
		this.disabled = value;
		var list = this.findElement('list');
		if (list) {
			list.className = this.disabled ? 'listBoxDisabled' : this.controlClass;
		}
		this.selectItem(this.selectedIndex);
		// dispatch to disable labels
		this.invokeSuper('setProperty',arguments);
		break;
	case 'readOnly':
		value = (value) ? true : false;
		this.readOnly = value;
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}

	return true;
}

/// Return number of items in list.<br>
/// This must be overridden in subclasses.
ClientMethod getOptionCount() [ Language = javascript ]
{
	return 0;
}

/// Return the logical value of the given item (0-based) in the list.<br>
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

}
