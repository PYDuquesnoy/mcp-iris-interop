/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This component draws a dynamic view box based on executing
/// a user-provided callback method.
Class %ZEN.Component.dynaView Extends component [ Deprecated, System = 3 ]
{

/// How to draw the contents of this view.
Property viewType As %ZEN.Datatype.string(VALUELIST = ",details,list") [ InitialExpression = "list" ];

/// Number of rows to display for list mode.
/// Default value is 5.
Property rows As %ZEN.Datatype.integer(MINVAL = 1) [ InitialExpression = 5 ];

/// Index number (0-based) of current selection.
Property selectedIndex As %ZEN.Datatype.integer(XMLPROJECTION = "none") [ InitialExpression = -1 ];

/// User-defined set of parameters. These values are passed on
/// to the user callback function that provides the contents of 
/// this view. Typically this is used to hold search parameters
/// (such as current directory for a directory viewer).
Property parameters As array Of %ZEN.Auxiliary.parameter(XMLKEYNAME = "paramName", XMLNAME = "parameter", XMLPROJECTION = "ELEMENT");

/// Text (display) value of current item within the view.
/// Do not access this directly; use getProperty('text') instead.
Property text As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// Logical value of current item within the view.
/// Do not access this directly; use getProperty('value') instead.
Property value As %ZEN.Datatype.string(XMLPROJECTION = "none");

/// onclick event handler:
/// If defined, this event is fired when
/// the user clicks on an item
Property onclick As %ZEN.Datatype.eventHandler;

/// If defined, this event is fired when the user clicks on one of the table headers
Property onclickHeader As %ZEN.Datatype.eventHandler;

/// onchange event handler:
/// If defined, this event is fired when the user selects a new item within the view.
Property onchange As %ZEN.Datatype.eventHandler;

/// ondblclick event handler:
/// If defined, this event is fired when
/// the user double-clicks on an item
Property ondblclick As %ZEN.Datatype.eventHandler;

/// onselect event handler:
/// If defined, this event is fired when the user selects an item
/// by either pressing the Enter key or double-clicking.
Property onselect As %ZEN.Datatype.eventHandler;

/// Name of Server-side callback method to call to create the
/// data used for this view.<br>
/// This must be the name of a server-only method in the page
/// class that contains this view component.
Property OnGetViewContents As %ZEN.Datatype.delegator(FORMALSPEC = "&pParms:%String,*pContents:%String,*pHeaders:%String", RETURNTYPE = "%Status");

/// If present, this is the number of items in the dynaView.
Property itemCount As %ZEN.Datatype.integer(XMLPROJECTION = "none", ZENSETTING = 0) [ InitialExpression = 0 ];

/// defines style sheet used by this component.
XData Style
{
<style type="text/css">

/* @doc="Default style for dynaView: list mode." */
table.dynaViewList {
	background: white;
	padding: 0px;
	width: 100%;
	height: 100%;
}

/* @doc="Default style for dynaView: details mode." */
table.dynaViewDetails {
	background: white;
	padding: 0px;
	width: 100%;
	height: 100%;
}

/* @doc="Table header within dynaView: details mode." */
table.dynaViewDetails th {
	text-align: left;
	color: black;
	font-weight: bold;
	padding: 2px;
	border-bottom: 1px solid #808080;
	background: #404040;
	background-image: url(images/grad-gray-10x30.png);
	background-repeat: repeat-x;
}

/* @doc="Selectable item within dynaView." */
.dynaViewItem {
	vertical-align: middle;
	white-space: nowrap;
	color: black;
	/* ie does not handle transparent */
	border: 1px solid white;
	cursor: default;
}

/* @doc="Selected item in dynaView." */
.dynaViewItemSelected {
	vertical-align: middle;
	white-space: nowrap;
	color: black;
	background: #E0E0E0;
	border: 1px dotted #202060;
}

/* @doc="Selected item with focus in dynaView." */
.dynaViewItemFocus {
	vertical-align: middle;
	white-space: nowrap;
	color: white;
	background: #000040;
	background-image: url(images/grad-blue-10x30.png);
	background-repeat: repeat-x;
	border: 1px solid black;
}

/* @doc="Image in dynaView." */
.dynaViewItem img, .dynaViewItemSelected img, .dynaViewItemFocus img {
	border: none;
	vertical-align: middle;
}

.dynaViewItem:hover {
	color: red;
}

</style>
}

/// Draw innerHTML for this component (without enclosing div).
Method %DrawHTML()
{
	Set tSC = ..%GetViewContents(.tContents,.tHeaders)
	If $$$ISERR(tSC) {
		Do ##class(%ZEN.Utils).%DisplayErrorHTML($this,tSC)
		Quit
	}

	Set:..rows<1 ..rows=1
	Set ..rows=..rows\1

	#; Find number of items in the view
	Set tItems = +$O(tContents(""),-1)
	Set tColCount = ((tItems-1)+..rows) \ ..rows
	Set ..itemCount = tItems

	#; invisible field to catch key events
	&html<<input type="text" id="#(..%MakeId("invisible"))#" style="top:0px;left:0px;position:absolute;border: 0px solid green;width:0;height:0;" onkeydown="zenPage.getComponent(#(..index)#).dvKeyDownHandler(event);" onkeypress="zenPage.getComponent(#(..index)#).dvKeyPressHandler(event);" onfocus="zenPage.getComponent(#(..index)#).dvKeyFocus();" onblur="zenPage.getComponent(#(..index)#).dvKeyBlur();"/>>

	If (..viewType = "list") {
		#; draw contents of view box in list mode
		&html<<table id="#(..%MakeId("table"))#" class="dynaViewList" border="0" cellspacing="0" cellpadding="0">>
	
		For tRow = 1:1:..rows {
			&html<<tr>>
			For tCol = 1:1:tColCount {
				Set tKey = ((tCol-1)*..rows) + tRow
				If (tKey <= tItems) {
					Set tText = $ZCVT($LG(tContents(tKey),1),"O","HTML")
					Set tValue = $ZCVT($LG(tContents(tKey),2),"O","HTML")
					Set tIcon = $LG(tContents(tKey),3)
					Set icon = $S(tIcon="":"images/spacer.gif",1:tIcon)
					&html<<td class="dynaViewItem" id="#(..%MakeId("td_"_(tKey-1)))#" zenText="#(tText)#" zenValue="#(tValue)#" onclick="zenPage.getComponent(#(..index)#).itemClicked(#(tKey-1)#);return false;" ondblclick="zenPage.getComponent(#(..index)#).itemDblClicked(#(tKey-1)#);"><img src="#(icon)#" class="dynaViewIcon"/>&nbsp;#(tText)#&nbsp;</td>>
				}
				Else {
					&html<<td>&nbsp;</td>>
				}
			}
			&html<</tr>>
		}
	
		#; extra row to take up space
		&html<<tr height="80%"><td colspan="#(tColCount)#">&nbsp;</td></tr>>
		&html<</table>>
	}
	ElseIf (..viewType = "details") {
		#; draw contents of view box in details mode
	
		#; figure out number of columns from tHeaders
		Set tColCount = 0
		Set c = $O(tHeaders(""))
		While (c '= "") {
			Set tColCount = tColCount + 1
			Set c = $O(tHeaders(c))
		}

		&html<<table id="#(..%MakeId("table"))#" class="dynaViewDetails" border="0" cellspacing="0" cellpadding="0">>
		#; headers
		If (tColCount > 0) {
			&html<<tr><th>&nbsp;</th>>
			For c = 1:1:tColCount {
				Set tHeader = $ZCVT($G(tHeaders(c)),"O","HTML")
				Set tCursor = $S(..onclickHeader'="":"pointer",1:"default")
				&html<<th onclick="zenPage.getComponent(#(..index)#).headerClicked('#(tHeader)#');return false;" style="cursor:#(tCursor)#">#(tHeader)#&nbsp;</th>>
			}
			&html<</tr>>
		}

		For tKey = 1:1:tItems {
			Set tText = $ZCVT($LG(tContents(tKey),1),"O","HTML")
			Set tValue = $ZCVT($LG(tContents(tKey),2),"O","HTML")
			Set tIcon = $LG(tContents(tKey),3)
			Set icon = $S(tIcon="":"images/spacer.gif",1:tIcon)

			&html<<tr class="dynaViewItem" id="#(..%MakeId("td_"_(tKey-1)))#" zenText="#(tText)#" zenValue="#(tValue)#" onclick="zenPage.getComponent(#(..index)#).itemClicked(#(tKey-1)#);return false;" ondblclick="zenPage.getComponent(#(..index)#).itemDblClicked(#(tKey-1)#);">>
			&html<<td><img src="#(icon)#"/></td><td>#(tText)#&nbsp;</td>>
			#; additional cols
			For c = 2:1:tColCount {
				Set tText = $ZCVT($LG(tContents(tKey),c+2),"O","HTML")
				&html<<td>#(tText)#&nbsp;</td>>
			}

			&html<</tr>>
		}

		#; extra row to soak up space	
		&html<<tr height="99%"><td colspan="#(tColCount+1)#">&nbsp;</td></tr>>
		&html<</table>>
	}
	Quit tSC
}

/// Get an array (<var>pContents</var>) containing contents of 
/// the view box.<br>
/// This array is subscripted by item number; It is assumed
/// that there are no gaps in this array.
/// Each element within the array is a $List of the form:<br>
/// $LB(text,value,icon,[addition cols])<br>
/// Additional columns are displayed in "details" mode.
/// <var>pHeaders</var> should contain the labels used for the
/// columns displayed in "details" mode. For example:<br>
/// pHeaders(1)="Name"  // label for 'text' column
/// pHeaders(2)="Size"  // label for 1st extra column, etc.
Method %GetViewContents(ByRef pContents As %String, ByRef pHeaders As %String) As %Status
{
	Set $ZT="Trap"
	Set tSC = $$$OK

	Set tHost = $S($IsObject(..composite):..composite,1:$G(%page))
	If ($IsObject(tHost) && (..OnGetViewContents '= "")) {
		#; convert parameters to local array
		Set key = ..parameters.Next("")
		While (key'="") {
			Set value = ..parameters.GetAt(key).value
			Set tParameters(key) = value
			Set key = ..parameters.Next(key)
		}
		Set tSC = $zobjmethod(tHost,..OnGetViewContents,.tParameters,.pContents,.pHeaders)
	}
Done
	Quit tSC
Trap
	Set $ZT=""
	Set tSC = $$$ERROR($$$GeneralError,$ZE)
	Goto Done
}

/// Initialize additional client-side values
ClientMethod onCreate() [ Language = javascript ]
{
	this.hasFocus = false;
}

/// Select the specified item given its index number (0-based).
/// If scroll is true, scroll new item into view.
ClientMethod selectItem(idx, scroll) [ Language = javascript ]
{
	scroll = (null == scroll) ? true : scroll;
	
	// unhighlight old selection
	if ((idx != this.selectedIndex) && (-1 != this.selectedIndex)) {
		var td = this.findElement('td_' + this.selectedIndex);
		if (td) {
			td.className = 'dynaViewItem';
		}
	}

	// mark new selection
	this.selectedIndex = idx;
	this.text = '';
	this.value = '';

	if (-1 != this.selectedIndex) {
		var td = this.findElement('td_' + this.selectedIndex);
		if (td) {
			td.className = this.hasFocus ? 'dynaViewItemFocus' : 'dynaViewItemSelected';
			this.text = td.getAttribute('zenText');
			this.value = td.getAttribute('zenValue');
			if (scroll) {
				if ('details' == this.viewType && 0==this.selectedIndex) {
					this.getEnclosingDiv().scrollTop = 0;
				}
				else {
					zenScrollIntoView(this.getEnclosingDiv(),td);
				}
			}
		}
	}

	// call user event handler
	zenInvokeCallbackMethod(this.onchange,this,'onchange');
}

ClientMethod headerClicked(headerName) [ Language = javascript ]
{
	//call user event handler
	zenInvokeCallbackMethod(this.onclickHeader,headerName,'onclickHeader');
}

/// User clicked on an item.
ClientMethod itemClicked(idx) [ Language = javascript ]
{
	this.focus();

	// update current selection
	this.selectItem(idx,false);

	// call user event handler, 
	zenInvokeCallbackMethod(this.onclick,this,'onclick');
}

/// User double-clicked on an item.
ClientMethod itemDblClicked(idx) [ Language = javascript ]
{
	// call user event handler(s)
	zenInvokeCallbackMethod(this.ondblclick,this,'ondblclick');
	zenInvokeCallbackMethod(this.onselect,this,'onselect');
}

/// Move to a new item in the dynaView. <var>dir</var> is "up","down","left","right"
/// Returns true if move was successful.
ClientMethod moveToItem(dir) [ Language = javascript ]
{
	var ret = false;
	var idx = this.selectedIndex;
	var size = this.itemCount;

	switch (this.viewType) {
	case 'list':
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
		case 'left':
			if (idx >= this.rows) {
				ret = true;
				this.selectItem(idx - this.rows);
			}
			break;
		case 'right':
			if (idx+this.rows < size) {
				ret = true;
				this.selectItem(idx + this.rows);
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
		}
		break;
	case 'details':
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
		break;
	}
	return ret;
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
ClientMethod dvKeyFocus() [ Language = javascript ]
{
	this.hasFocus = true;
	this.selectItem(this.selectedIndex);
}

/// Focus taken from the invisible edit control.
ClientMethod dvKeyBlur() [ Language = javascript ]
{
	this.hasFocus = false;
	this.selectItem(this.selectedIndex);
}

/// Process keydown event within the invisible edit control.
ClientMethod dvKeyDownHandler(evt) [ Language = javascript ]
{
	if (this.disabled) return false;
	evt = evt ? evt : window.event;
	var ret = true;

	var row = this.currRow;
	var col = this.currColumn;

	// trap keys
	switch(evt.keyCode) {
	case zenENTER:
		zenInvokeCallbackMethod(this.onselect,this,'onselect');
		break;
	case zenPAGEUP:
		ret = !this.moveToItem('pageup');
		break;
	case zenPAGEDN:
		ret = !this.moveToItem('pagedn');
		break;
	case zenEND:
		ret = !this.moveToItem('end');
		break;
	case zenHOME:
		ret = !this.moveToItem('home');
		break;
	case zenUP:
		ret = !this.moveToItem('up');
		break;
	case zenDOWN:
		ret = !this.moveToItem('down');
		break;
	case zenRIGHT:
		ret = !this.moveToItem('right');
		break;
	case zenLEFT:
		ret = !this.moveToItem('left');
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
ClientMethod dvKeyPressHandler(evt) [ Language = javascript ]
{
	if (this.disabled) return false;
	evt = evt ? evt : window.event;
	var ret = true;

	// trap keys
	switch(evt.keyCode) {
	default:
		break;
	}
	return ret;
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'rows':
		if (this.rows != value) {
			this.rows = value;
			this.refreshContents(true);
			this.selectItem(this.selectedIndex);
		}		
		break;
	case 'viewType':
		if (this.viewType != value) {
			this.viewType = value;
			this.refreshContents(true);
			this.selectItem(this.selectedIndex);
		}		
		break;

	case 'parameters':
		// set value of named parameter
		// only works for pre-defined parameter names!
		if ('' != value) {
			 if (this.parameters[value]) {
				 if (this.parameters[value].value != value2) {
					this.parameters[value].value = value2;
					this.refreshContents();
				 }
			 }
		}
		break;

	case 'text':
	case 'value':
		// readonly
		break;
	case 'selectedIndex':
		this.selectItem(value,true);
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
