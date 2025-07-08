/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This is a specialized type of tabGroup that implements
/// a "lookout" menu: a set of buttons stacked atop one another,
/// one for each tab. Clicking on a button makes the contents
/// of the tab visible beneath the button.
Class %ZEN.Component.lookoutMenu Extends tabGroup [ Deprecated, System = 3 ]
{

Parameter DEFAULTCELLVALIGN = "top";

Parameter DEFAULTENCLOSINGCLASS = "lookoutMenu";

/// Indicates whether this menu is expanded (children visible)
/// or contracted (children not visible).
Property expanded As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// Indicates whether this menu supports the ability to expand and contract.
Property expandable As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// onexpand event handler:
/// If defined and this menu is expandable, this event is fired just
/// before the children of this menu are made visible.
Property onexpand As %ZEN.Datatype.eventHandler;

/// oncontract event handler:
/// If defined and this menu is expandable, this event is fired just
/// before the children of this menu are hidden.
Property oncontract As %ZEN.Datatype.eventHandler;

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* @doc="Style for lookoutMenu enclosing div." */
.lookoutMenu {
	height: 100%;
	padding: 0px;
	position: relative;
	top: 0px;
	left: 0px;
}

/* @doc="Style for lookoutMenu children div." */
.lookoutMenuChildren {
}

/* @doc="Button within lookoutMenu." */
.lookoutButton {
	position: absolute;
	padding: 3px;
}

/* @doc="Style for enclosing div for tab within lookoutMenu." */ 
.lookoutTab {
	position: absolute;
	padding: 1px;
	background: darkgray;
	overflow: auto;
}

/* @doc="Style for grip within lookoutMenu." */ 
.lookoutGrip {
	color: white;
	background: darkblue;
	border: 1px solid black;
	width: 100%;
}

</style>
}

Method %DrawHTML()
{
	Set tCount = ..children.Count()

	#; make sure all children are tabs and that starting tab is visible
	For n=1:1:tCount {
		Set tChild = ..children.GetAt(n)
		If tChild.%IsA("%ZEN.Component.tab") {
			Set tChild.hidden = (n'=..currTab)
		}
		Else {
			&html<<div>ERROR: All top-level children of tabGroup must be tabs</div>>
			Quit
		}
	}

	If (+..expandable) {
		#; gripper for hiding/showing menu
		Set tHelp = $$$Text("Hide or show this menu","%ZEN")
		&html<<div title="#($ZCVT(tHelp,"O","HTML"))#" class="lookoutGrip" id="#(..%MakeId("grip"))#" onclick="zenPage.getComponent(#(..index)#).gripClickHandler();">&#8801;</div>>
	
		Set style = $S(+..expanded:"",1:"display: none;")
		&html<<div id="#(..%MakeId("menuChildren"))#" class="lookoutMenuChildren" style="#(style)#">>
	}

	#; now draw a set of buttons and children within enclosing divs
	For n=1:1:tCount {
		Set tChild = ..children.GetAt(n)
		Set tPriv = ((tChild.tabResource="")||$System.Security.Check(tChild.tabResource,"USE"))
		Set tName = $S(tChild.caption="":n,1:tChild.caption)
		Set tTooltip = $S(tChild.title="":$$$Text("Make this section visible","%ZEN"),1:tChild.title)
		&html<<input type="button" id="#(..%MakeId("btn_"_n))#" title="#($ZCVT(tTooltip,"O","HTML"))#" class="lookoutButton" onclick="zenPage.getComponent(#(..index)#).showTab(#(n)#);" #($S(tChild.disabled||'tPriv:"disabled",1:""))# value="#($ZCVT(tName,"O","HTML"))#"/>>
		Do tChild.%DrawComponentHTML()
	}
	If (+..expandable) {
		&html<</div>>
	}
}

/// Set the height and width of this menu.
/// This sets the height and width of the enclosing div
/// that contains the menu. The size values should be integers without
/// "px" appended to them.
ClientMethod setSize(width, height) [ Language = javascript ]
{
	width = parseInt(width,10);
	height = parseInt(height,10);

	var enc = this.getEnclosingDiv();
	if (this.expandable && !this.expanded) {
		// mini size
		var grip = this.findElement("grip");
		enc.style.height = (grip ? grip.offsetHeight : '0px');
		enc.style.width = '12px';
	}
	else {
		if (!isNaN(height)) {
			enc.style.height = height + 'px';
		}
		if (!isNaN(width)) {
			enc.style.width = width + 'px';
		}
	}
	this.height = height;
	this.width = width;
	this.adjustTabs();
}

/// Adjust the position of tabs that are not currently visible.  Note that the properties of width
/// and height for the component take precidence over the CSS attributes of the same name should
/// the assigned values differ for any reason.
/// 
ClientMethod adjustTabsOffscreen() [ Language = javascript ]
{
	var enc = this.getEnclosingDiv();
	if (enc.style.height=="") {
		if (this.height) enc.style.height=this.height+"px";
	}
	if (enc.style.width=="") {
		if (this.width) enc.style.width=this.width+"px";
	}
 	var oldP = enc.parentNode;
 	document.body.appendChild(enc);
	this.reallyAdjustTabs();
 	document.body.removeChild(enc);
 	oldP.appendChild(enc);
}

/// Adjust the position of the tabs.
ClientMethod adjustTabs() [ Language = javascript ]
{
	var enc = this.getEnclosingDiv();
	var encWid = (enc.offsetWidth<2) ? 2 : enc.offsetWidth;
	if (enc.offsetWidth==0 && enc.offsetHeight==0) {
		this.adjustTabsOffscreen();
		return;
	}
 	this.reallyAdjustTabs();
}

/// Adjust the position of the visible tabs.
ClientMethod reallyAdjustTabs() [ Language = javascript ]
{
	var enc = this.getEnclosingDiv();
	var encWid = (enc.offsetWidth<2) ? 2 : enc.offsetWidth;
 
	// get size of grip, if present
	var grip = this.findElement("grip");
	var gripHeight = (grip ? grip.offsetHeight : 0);
	
	// if user has specified a height, then force height of this menu
	if (('' == enc.style.height) && enc.offsetHeight < 50) {
		var btn = this.findElement("btn_1");
		if (btn) {
			enc.style.height = (btn.offsetHeight*(this.children.length+2)) + 'px';
		}
		else {
			enc.style.height = '100px';
		}
	}

	if (0 == this.children.length) return;

	// slide buttons up to current to top
	var currTab = this.currTab > 0 ? this.currTab : this.children.length;
	var top = 0;
	var y1 = top + gripHeight;
	for (var n = 1; n <= currTab; n++) {
		var btn = this.findElement("btn_" + n);
		btn.style.top = y1 + "px";
		btn.style.width = (encWid - 2)+"px";		
		y1 += btn.offsetHeight;
	}

	// slide buttons after current to bottom
	// test if lower buttons would overlap upper buttons
	var adj = 0;
	var y2 = top + enc.offsetHeight;
	var btn = this.findElement("btn_1");
	var btnHgt = btn.offsetHeight;
	var test = y2 - ((this.children.length + 3 - currTab)*btnHgt);
	if (test < y1) {
		adj = y1 - test;
	}

	for (var n = this.children.length; n > currTab; n--) {
		var btn = this.findElement("btn_" + n);
		y2 -= btn.offsetHeight;
		//btn.style.top = (y2 + adj)+"px";
		btn.style.top = (y2 +adj-btn.offsetHeight)+"px";
		btn.style.width = (encWid - 2)+"px";
	}
	
	// adjust size of inner tab
	if (this.currTab > 0 && this.children.length > 0) {
		var tab = this.children[this.currTab-1];
		if (tab) {
			var div = tab.getEnclosingDiv();
			div.className = 'lookoutTab';
			div.style.width = (encWid - (zenIsIE ? 2 : 4))+"px";
			div.style.top = y1+"px";
			var h = (y2 - y1 - btnHgt - 2);
			if (h<2*btnHgt) h = 2*btnHgt;
			div.style.height = h+'px';
		}
	}
}

/// Class-specific notification that a new tab has been selected.
ClientMethod onshowTabHandler(tabno) [ Language = javascript ]
{
	this.adjustTabs();
}

/// Called by tabs of this group to notify that they have
/// become disabled.
ClientMethod tabDisabledHandler(tab) [ Language = javascript ]
{
	// find this tab
	for (var n = 0; n < this.children.length; n++) {
		var child = this.children[n];
		if (tab == child) {
			var btn = this.findElement("btn_" + (n+1));
			btn.disabled = tab.disabled;
			if (this.currTab == (n+1)) {
				// hide this tab as well
				this.showTab(0);
				this.adjustTabs();
			}
			break;
		}
	}
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.adjustTabs();

	if (this.disabled && this.parent && !this.parent.disabled) {
		// if we are disabled, make sure our children
		// are disabled when this component is first loaded
		this.setProperty('disabled',true);
	}

	// dispatch
	this.invokeSuper('onloadHandler',arguments);
}

/// onclick handler for expander grip.
ClientMethod gripClickHandler() [ Language = javascript ]
{
	this.setExpanded(!this.getExpanded());
}

/// Returns the current expanded state of this menu.
ClientMethod getExpanded() [ Language = javascript ]
{
	return this.expanded;
}

/// Set the expanded state of this menu.
ClientMethod setExpanded(flag) [ Language = javascript ]
{
	this.expanded = flag;
	if (!this.expandable) return;

	var div = this.findElement('menuChildren');
	zenASSERT(div,'Unable to find div element for children',arguments);

	var img = this.findElement('image');

	// invoke callbacks, if present
	if (this.expanded) {
		zenInvokeCallbackMethod(this.onexpand,this,'onexpand');
	}
	else {
		zenInvokeCallbackMethod(this.oncontract,this,'oncontract');
	}

	div.style.display = this.expanded ? '' : 'none';
	if (img) {
		img.src = this.expanded ? this.imageExpanded : this.imageContracted;
	}
}

/// Set the value of a named property.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'expanded':
		value = value ? true : false;
		this.setExpanded(value);
		this
		break;
	case 'expandable':
		value = value ? true : false;
		this.expandable = value;
		this.refreshContents();
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
		break;
	}
	return true;
}

/// Called after refreshContents.
ClientMethod onRefreshContents() [ Internal, Language = javascript ]
{
	this.invokeSuper('onRefreshContents',[]);
	this.adjustTabs();
}

}
