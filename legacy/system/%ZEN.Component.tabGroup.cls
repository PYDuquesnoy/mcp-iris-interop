/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A specialized group used to enclose a set of overlayed <i>tabs</i>.
/// One tab is visible at a time.
/// This group does not support standard layout as it simply overlays
/// each of its children.
Class %ZEN.Component.tabGroup Extends group [ Deprecated, System = 3 ]
{

/// Number (1-based) of current tab displayed within tabGroup.
Property currTab As %ZEN.Datatype.integer(ZENEXPRESSION = 1) [ InitialExpression = 1 ];

/// If true, display a set of tab buttons along the top of this group.
/// The default is false.
Property showTabBar As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// If true (the default), render the div containing the tab's bodys. If false, the content 
/// will still be rendered, but not contained in a div.
Property showBody As %ZEN.Datatype.boolean [ InitialExpression = 1 ];

/// If true, remember most recent tab in a session cookie.
Property remember As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// onshowTab event handler:
/// This event is fired when a new tab is made visible.
Property onshowTab As %ZEN.Datatype.eventHandler;

/// onhideTab event handler:
/// This event is fired when a new tab is hidden.
Property onhideTab As %ZEN.Datatype.eventHandler;

/// defines style sheet used by this component
XData CSS3Style
{
<style type="text/css">

/* @doc="Wrapper for body of tabgroup, when tab bar is shown." */
.tabGroupBody {
	background: white;
	border-right: 1px solid black;
	border-left: 1px solid black;
	border-bottom: 1px solid black;
	min-height: 400px;
	overflow: auto;
}

/* @doc="Container of tab bar buttons." */
table.tabGroupBar {
	font-size: 1.0em;
	width: 100%;
}

/* @doc="Individual tab bar button in On state." */
td.tabGroupButtonOn {
	background: white;
	border-top: 1px solid black;
	border-bottom: none;
	border-right: 1px solid black;
	border-left: 1px solid black;
	font-weight: bold;
	padding-right: 5px;
	padding-left: 5px;
	cursor: pointer;
	border-top-left-radius:6px;
	border-top-right-radius:6px;
}

/* @doc="Individual tab bar button in Off state." */
td.tabGroupButtonOff {
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
	border-top: 1px solid black;
	border-bottom: 1px solid black;
	border-right: 1px solid black;
	border-left: 1px solid black;
	padding-right: 5px;
	padding-left: 5px;
	cursor: pointer;
	border-top-left-radius:6px;
	border-top-right-radius:6px;
}

/* @doc="Individual tab bar button in Disabled state." */
td.tabGroupButtonDisabled {
	background: #AAAAAA;
	color: gray;
	border-top: 1px solid black;
	border-bottom: 1px solid black;
	border-right: 1px solid black;
	border-left: 1px solid black;
	padding-right: 5px;
	padding-left: 5px;
	border-top-left-radius:6px;
	border-top-right-radius:6px;
}

/* @doc="Link within a tab button." */
td.tabGroupButtonOn a,td.tabGroupButtonOff a,td.tabGroupButtonDisabled a {
	color: black;
	text-decoration: none;
}

td.tabGroupButtonOff:hover {
	background: #FFEEAA;
}

td.tabGroupButtonOff:active {
	text-shadow: -1px 1px 8px #D0D0D0, 1px -1px 8px #808080;
}

/* @doc="Extra space on edges of tab bar." */
.tabGroupExtra {
	border-bottom: 1px solid black;
	background: transparent;
	width: 100%;
}

/* @doc="Container for gaps between tabs." */
.tabGroupGapTd {
	border-bottom: 1px solid black;
	background: transparent;
	empty-cells: show;
}

/* @doc="The width of this selector controls the gap between tabs in the tab bar." */
.tabGroupGap {
	width: 4px;
}

</style>
}

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* @doc="Wrapper for body of tabgroup, when tab bar is shown." */
.tabGroupBody {
	background: white;
	border-right: 1px solid black;
	border-left: 1px solid black;
	border-bottom: 1px solid black;
	min-height: 400px;
	overflow: auto;
}

/* @doc="Container of tab bar buttons." */
table.tabGroupBar {
	font-size: 1.0em;
	width: 100%;
}

/* @doc="Individual tab bar button in On state." */
td.tabGroupButtonOn {
	background: white;
	border-top: 1px solid black;
	border-bottom: none;
	border-right: 1px solid black;
	border-left: 1px solid black;
	font-weight: bold;
	padding-right: 5px;
	padding-left: 5px;
	cursor: pointer;
	-moz-border-radius-topleft:6px;
	-moz-border-radius-topright:6px;
}

/* @doc="Individual tab bar button in Off state." */
td.tabGroupButtonOff {
	background: #404040;
	background-image: url(images/grad-gray-10x100.png);
	background-repeat: repeat-x;
	border-top: 1px solid black;
	border-bottom: 1px solid black;
	border-right: 1px solid black;
	border-left: 1px solid black;
	padding-right: 5px;
	padding-left: 5px;
	cursor: pointer;
	-moz-border-radius-topleft:6px;
	-moz-border-radius-topright:6px;
}

/* @doc="Individual tab bar button in Disabled state." */
td.tabGroupButtonDisabled {
	background: #AAAAAA;
	color: gray;
	border-top: 1px solid black;
	border-bottom: 1px solid black;
	border-right: 1px solid black;
	border-left: 1px solid black;
	padding-right: 5px;
	padding-left: 5px;
	-moz-border-radius-topleft:6px;
	-moz-border-radius-topright:6px;
}

/* @doc="Link within a tab button." */
td.tabGroupButtonOn a,td.tabGroupButtonOff a,td.tabGroupButtonDisabled a {
	color: black;
	text-decoration: none;
}

td.tabGroupButtonOff:hover {
	background: #FFEEAA;
}

/* @doc="Extra space on edges of tab bar." */
.tabGroupExtra {
	border-bottom: 1px solid black;
	background: transparent;
	width: 100%;
}

/* @doc="Container for gaps between tabs." */
.tabGroupGapTd {
	border-bottom: 1px solid black;
	background: transparent;
	empty-cells: show;
}

/* @doc="The width of this selector controls the gap between tabs in the tab bar." */
.tabGroupGap {
	width: 4px;
}

</style>
}

Method %DrawHTML()
{
	Set tCount = ..children.Count()
	Set tCurrTab = $$$ZENVAL(..currTab)
	set ..currTab = tCurrTab

	// make sure all children are tabs and that starting tab is visible
	For n=1:1:tCount {
		Set tChild = ..children.GetAt(n)
		If tChild.%IsA("%ZEN.Component.tab") {
			Set tChild.hidden = (n'=tCurrTab)
		}
		Else {
			&html<<div>ERROR: All top-level children of tabGroup must be tabs</div>>
			Quit
		}
	}

	If (..showTabBar) {
		// draw tab bar
		&html<<table id="#(..%MakeId("bar"))#" class="tabGroupBar" border="0" cellpadding="0" cellspacing="0"><tr>>
		For n=1:1:tCount {
			Set tChild = ..children.GetAt(n)
			Set tName = $S(tChild.caption="":n,1:tChild.caption)
			Set tLink = $$$ZENVALHTML(tChild.link)
			Set tPriv = ((tChild.tabResource="")||$System.Security.Check(tChild.tabResource,"USE"))
			Set tDisabled = tChild.disabled || 'tPriv
			Set tClick = ""
			Set:tPriv tClick = "onclick=""return zenPage.getComponent("_..index_").showTab("_n_");"""
			Set tText = $S(((tLink="")||'tChild.hidden):"&nbsp;"_$ZCVT(tName,"O","HTML")_"&nbsp;",1:"<a href="""_%page.%Link(tLink)_""">&nbsp;"_$ZCVT(tName,"O","HTML")_"&nbsp;</a>")

			&html<<td nowrap="1" id="#(..%MakeId("btn_"_n))#" #(..%Attr("title",tChild.title))# class="tabGroupButton#($S(tDisabled:"Disabled",tChild.hidden:"Off",1:"On"))#" #(tClick)#>#(tText)#</td><td class="tabGroupGapTd"><div class="tabGroupGap"> </div></td>>
		}
		&html<<td width="25%" class="tabGroupExtra">&nbsp;</td>
		</tr></table>>
		If (..showBody) {
			&html<<div id="#(..%MakeId("body"))#" class="tabGroupBody">>
		}
	}

	// now draw a set of overlapping enclosing divs to hold the tabs
	For n=1:1:tCount {
		Set tChild = ..children.GetAt(n)
		Do tChild.%DrawComponentHTML()
	}

	If (..showTabBar && ..showBody) {
		&html<</div>>
	}
}

/// Notification that children have been added or removed from this group. 
Method %OnMutateChildren(pAdd As %Boolean) As %Boolean
{
	If ('pAdd && ($$$ZENVAL(..currTab) > ..children.Count())) {
		Set ..currTab = 0
	}
	Quit 1
}

/// Return index (1-based) of current tab within the tabGroup.
ClientMethod getCurrTabNo() [ Language = javascript ]
{
	return parseInt(this.currTab,10);
}

/// Return number of tabs within the tabGroup.
ClientMethod getTabCount() [ Language = javascript ]
{
	return this.children.length;
}

/// Return the HTML DIV element for the tab body.
ClientMethod getTabBodyElement() [ Language = javascript ]
{
	return this.findElement('body');
}

/// Return the HTML TABLE element for the tab bar.
ClientMethod getTabBarElement() [ Language = javascript ]
{
	return this.findElement('bar');
}

/// Set the size of the tab body and all tabs.
/// <var>width</var> and <var>height</var> are in pixels.<br/>
/// You must override the CSS min-height for the tabBody for this to be effective.
ClientMethod setBodySize(height, width) [ Language = javascript ]
{
	var body = this.findElement('body');
	if (body) {
		if (width) {
			body.style.width = width + 'px';
		}
		if (height) {
			body.style.height = height + 'px';
		}

		/*
		for (var n = 0; n < this.children.length; n++) {
			var div = this.children[n].getEnclosingDiv();
			if (div) {
				if (width) {
					div.style.width = width + 'px';
				}
				if (height) {
					div.style.height = height + 'px';
				}
			}
		}
		*/
	}
}

/// Notification to subclasses that a child has been added or removed
/// from this group.
ClientMethod childrenMutated() [ Language = javascript ]
{
	if (this.currTab > this.children.length) {
		this.currTab = 0;
	}
}

/// Look for the given tab object within this tabGroup's set of
/// tabs and return its 1-based index number.<br>
/// Returns -1 if unable to find the tab.
ClientMethod getTabIndex(tab) [ Language = javascript ]
{
	return this.getChildIndex(tab) + 1;
}

/// Server-only method: Find the specified tab by index number (1-based).
Method %GetTab(pIndex As %Integer) [ CodeMode = expression ]
{
..children.GetAt(pIndex)
}

/// Server-side method to set current tab of this tabGroup
/// to <var>pTab</var>.
Method %SetCurrTab(pTab As %ZEN.Component.tab)
{
	Set ..currTab = ..%GetChildIndex(pTab)
}

/// Display the specified tab (given its 1-based tab number)
/// and hide the current tab.
ClientMethod showTab(tabno) [ Language = javascript ]
{
	if (this.currTab == tabno) return true;
	
	// Don't switch if target tab is disabled
	if ((this.children.length >=tabno) && (this.children[tabno-1]) && (this.children[tabno-1].disabled)) return true;

	if (this.currTab > 0 && this.children.length > 0) {
		// invoke user callback, if present
		var ret = zenInvokeCallbackMethod(this.onhideTab,this,'onhideTab');
		if (this.onhideTab != '' && ret!=null && ret==false) {
			// do nothing
			return false;
		}

		// hide current tab
		if (this.children[this.currTab-1]!=undefined) this.children[this.currTab-1].setHidden(true);
		if (this.showTabBar) {
			// update tab bar
			var btn = this.findElement('btn_' + (this.currTab));
			zenASSERT(btn,"Unable to find tab bar button element (1)",arguments);
			btn.className = 'tabGroupButtonOff';
		}

		// invoke class callback
		if (this.onhideTabHandler) {
			this.onhideTabHandler(this.currTab);
		}
	}

	if (tabno <= 0 || tabno > this.children.length) {
		this.currTab = 0;
		return true;
	}
	if (this.children[tabno-1].disabled) return true;

	// show new tab
	this.currTab = tabno;
	if (this.currTab > 0) {
		this.children[this.currTab-1].setHidden(false);
		if (this.showTabBar) {
			// update tab bar
			var btn = this.findElement('btn_' + (this.currTab));
			zenASSERT(btn,"Unable to find tab bar button element (2)",arguments);
			btn.className = 'tabGroupButtonOn';
		}

		// invoke class callback
		if (this.onshowTabHandler) {
			this.onshowTabHandler(tabno);
		}

		// user callback
		zenInvokeCallbackMethod(this.onshowTab,this,'onshowTab');

		// check to prevent window collapse under IE
		if (zenIsIE==1 && !(zenIsHTML5==null) && !zenIsHTML5) this.ieResizeBody();
	}

	if (this.remember) {
		// stash current tab away
		zenStoreCookie(this,'currTab',this.currTab);
	}
	return true;
}

/// IE does not properly support the min-height CSS property.  This routine forces a
/// correction to the size of the tabBody should it be rendered too small.
ClientMethod ieResizeBody() [ Language = javascript ]
{
	// If a height property has been set, use it.
	// Else if a CSS height attribute has been set, use it
	// Else if a body.height/body.width attribute has been set don't change it
	// Else is a CSS min-height attribute has been set and the height is 
	//  underspecified, let the window float so long as it is at least
	//  min-height tall.
	var tabBody = this.findElement("body");
	if (!tabBody) return;
	if (this.children.length<=0) return;
	if (tabBody.style.width && tabBody.style.height) return;
	if (this.height) {
		this.cssHeight=parseInt(this.height,10)+'px';
		tabBody.style.height=this.cssHeight;
		return;
	} 
	else {
		if (this.autoSizeH) var cssH = 'auto';
		else var cssH = tabBody.currentStyle.height;
		if (cssH == 'auto' || cssH == '') {
			var minH=parseInt(tabBody.currentStyle.minHeight,10);
			var ofsH = tabBody.offsetHeight;
			var scrH = tabBody.scrollHeight;
			if (ofsH>=scrH) {
				if (ofsH==minH) return; // good enough
				// window is taller than it needs to be, collapse
				// and resize accordingly
				this.autoSizeH = true;
				tabBody.style.height=minH+"px";
				var style = tabBody.currentStyle; // Force display refresh 
				if (tabBody.scrollHeight>minH) {
					tabBody.style.height=tabBody.scrollHeight;
				}
			}
			else { // need to grow to hide scrollbars
				this.autoSizeH = true;
				tabBody.style.height = scrH+"px";
			}	
		}
		else {
			tabBody.style.height=cssH;
		}
	}
}

/// Called after refreshContents.
ClientMethod onRefreshContents() [ Language = javascript ]
{
	this.invokeSuper('onRefreshContents',[]);
	if (zenIsIE==1) this.ieResizeBody();
}

/// This client event, if present, is fired when the page is loaded.
ClientMethod onloadHandler() [ Language = javascript ]
{
	if (this.remember) {
		// go to recently saved tab
		var tab = parseInt(zenLoadCookie(this,'currTab'),10);
		if (tab > 0) {
			this.showTab(tab);
		}
	}
	if (zenIsIE==1) this.ieResizeBody();
}

/// Class-specific notification that a new tab has been selected.
/// Implemented by subclasses.
ClientMethod onshowTabHandler(tabno) [ Abstract, Language = javascript ]
{
}

/// Called by tabs of this group to notify that they have
/// changed their disabled state.
ClientMethod tabDisabledHandler(tab) [ Language = javascript ]
{
	// make sure style of tab is up-to-date
	var tabno = this.getTabIndex(tab);
	if (tabno > 0) {
		var btn = this.findElement('btn_' + tabno);
		if (btn) {
			if (tab.disabled) {
				btn.className = 'tabGroupButtonDisabled';
			}
			else {
				btn.className = (tabno==this.currTab) ? 'tabGroupButtonOn' : 'tabGroupButtonOff';
			}
		}
	}
}

/// Class-specific notification that a tab has been hidden.
/// Implemented by subclasses.
ClientMethod onhideTabHandler(tabno) [ Abstract, Language = javascript ]
{
}

/// Display the next tab in the tabGroup.
ClientMethod showNextTab(skipDisabled) [ Language = javascript ]
{
	if (skipDisabled==true) {
		var idx= -1;
		var i=parseInt(this.currTab,10);
		while (i<this.children.length && idx==-1) {
			if (!this.children[i].disabled) idx=i;
			i++;
		}
		if (idx!=-1) this.showTab(idx+1);
	}	
	else this.showTab(parseInt(this.currTab,10)+1);
}

/// Display the previous tab in the tabGroup.
ClientMethod showPreviousTab(skipDisabled) [ Language = javascript ]
{
	if (skipDisabled==true) {
		var idx= -2;
		var i=parseInt(this.currTab,10)-2;
		while (i>=0 && idx==-2) {
			if (!this.children[i].disabled) idx=i;
			i--;
		}
		if (idx!=-2) this.showTab(idx+1);
	}
	else this.showTab(parseInt(this.currTab,10)-1);
}

/// Set the value of a named property.<br>
/// Assume that subclasses that simply wrap HTML controls
/// have named the control 'control' or else have overridden
/// this method.
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'remember':
		this.remember = value ? true : false;
		break;
	case 'currTab':
		this.showTab(parseInt(value,10));
		break;
	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

}
