/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This composite component provides a set of navigation buttons for
/// a <class>%ZEN.Component.tablePane</class>.<br>
/// For a more sophisticated component, use <class>%ZEN.Component.tableNavigatorBar</class>.<br>
Class %ZEN.Component.tableNavigator Extends composite [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

Parameter SYSMODULE = "table";

/// id of <class>%ZEN.Component.tablePane</class> component this
/// navigator is associated with.<br>
/// Note: if this component is placed within a composite element, then the
/// tablePane must be within the same composite element.
Property tablePaneId As %ZEN.Datatype.id(COMPONENTTYPE = "tablePane");

Property msgPage As %ZEN.Datatype.caption;

Property msgOf As %ZEN.Datatype.caption;

Property msgFirstPage As %ZEN.Datatype.caption;

Property msgLastPage As %ZEN.Datatype.caption;

Property msgNextPage As %ZEN.Datatype.caption;

Property msgPreviousPage As %ZEN.Datatype.caption;

/// defines style sheet used by this component
XData Style
{
<style type="text/css">
.tn-pageLabel {
	font-size: 0.75em;
	color: darkblue;
	margin-right: 5px;
	margin-left: 2px;
}
</style>
}

/// Contents of this composite component:
/// This is a set of paging buttons as well as text controls
/// to show the current page number.
XData Contents
{
<composite xmlns="http://www.intersystems.com/zen">
<hgroup labelPosition="left" cellAlign="left">
<button id="btnFirst" caption=" |&lt; " onclick="zenThis.composite.gotoPage('first');" />
<button id="btnPrev" caption=" &lt;&lt; " onclick="zenThis.composite.gotoPage('prev');" />
<button id="btnNext" caption=" &gt;&gt; " onclick="zenThis.composite.gotoPage('next');" />
<button id="btnLast" caption=" &gt;| " onclick="zenThis.composite.gotoPage('last');" />
<spacer width="20"/>
<text id="pageNo" size="2" labelClass="tn-pageLabel" onchange="zenThis.composite.gotoPage(zenThis.getValue());" onkeypress="zenThis.composite.checkEnter(event);"/>
<text id="pageCount" size="4" labelClass="tn-pageLabel" readOnly="true" />
<spacer width="*"/>
</hgroup>
</composite>
}

ClientMethod checkEnter(event) [ Language = javascript ]
{
/// This method is used to force a blur() of the text input box under IE.
/// Most browsers will fire an onchange event when the enter key is hit in
/// a text box but IE requires that the box lose focus before triggering
/// an onchange event.
	if (zenIsIE) {
		var keynum = 0;
		if (window.event) {
			keynum = event.keyCode;
		}
		else {
			if (event.which) {
				keynum = event.which;
			}
		}
		var keychar = String.fromCharCode(keynum);
		if ("\r" == keychar) {
			event.srcElement.blur();
			return false;
	 	}
	 }
}

/// This method is called from the associated tablePane when
/// it changes state. The navigator responds by updating the
/// state of its controls.
ClientMethod updateState() [ Language = javascript ]
{
	// buttons
	var btnFirst = this.getChildById('btnFirst');
	var btnPrev = this.getChildById('btnPrev');
	var btnNext = this.getChildById('btnNext');
	var btnLast = this.getChildById('btnLast');
	var ctrlPageNo = this.getChildById('pageNo');
	var ctrlPageCount = this.getChildById('pageCount');

	zenASSERT(ctrlPageNo,'tableNavigator: Unable to find pageNo control',arguments);
	
	var table = this.tablePane;
	if (null == table) {
		// disable
		ctrlPageNo.setProperty('disabled',true);
		ctrlPageCount.setProperty('disabled',true);
	
		btnFirst.setProperty('disabled',true);
		btnPrev.setProperty('disabled',true);
		btnNext.setProperty('disabled',true);
		btnLast.setProperty('disabled',true);
		return;
	}

	var pageNo = table.getProperty('currPage');
	var pageCount = table.getPageCount();

	ctrlPageNo.setValue(pageNo);
	ctrlPageCount.setValue(pageCount);

	ctrlPageNo.setProperty('disabled',pageCount==1);
	ctrlPageCount.setProperty('disabled',false);

	btnFirst.setProperty('disabled',pageNo==1);
	btnPrev.setProperty('disabled',pageNo==1);
	btnNext.setProperty('disabled',pageNo==pageCount);
	btnLast.setProperty('disabled',pageNo==pageCount);
}

/// Move to the specified page in the associated tablePane.
/// where can be 'first','last','next','prev' or a page number.
ClientMethod gotoPage(where) [ Language = javascript ]
{
	if (null == this.tablePane) return;

	// dispatch to tablePane
	switch(where) {
	case 'first':
		this.tablePane.firstPage();
		break;
	case 'last':
		this.tablePane.lastPage();
		break;
	case 'next':
		this.tablePane.nextPage();
		break;
	case 'prev':
		this.tablePane.previousPage();
		break;
	default:
		var page = parseInt(where,10);
		if (!isNaN(page)) {
			this.tablePane.gotoPage(page);
		}
		break;
	}
}

/// Set the value of a named property.<br>
ClientMethod setProperty(property, value, value2) [ Language = javascript ]
{
	switch(property) {
	case 'tablePaneId':
		if (this.tablePane && this.tablePane.removeNavigator) {
			this.tablePane.removeNavigator();
			this.tablePane = null;
		}
		this.tablePaneId = value;
		if (this.composite) {
			this.tablePane = this.composite.getChildById(this.tablePaneId);
		}
		else {
			this.tablePane = zenPage.getComponentById(this.tablePaneId);
		}
		if (this.tablePane && this.tablePane.addNavigator) {
			this.tablePane.addNavigator(this);
		}
		this.updateState();
		break;

	default:
		// dispatch
		return this.invokeSuper('setProperty',arguments);
	}
	return true;
}

Method %DrawHTML()
{

	#; force client-side render to get called
	Do ##super()
	Set ..renderFlag = ..renderFlag + 1
}

/// Client-side method to render this control.
/// In this case, we perform client-side connection to the tablePane.
ClientMethod renderContents() [ Language = javascript ]
{
	// set up association with tablePane
	this.setProperty('tablePaneId',this.tablePaneId);
}

/// This callback is called after the children of this composite
/// component have been created.
Method %OnAfterCreateComposite() As %Status
{
	Set:..msgPage="" ..msgPage = $$$Text("Page")
	Set:..msgOf="" ..msgOf = $$$Text("of")
	Set:..msgFirstPage="" ..msgFirstPage = $$$Text("Go to first page")
	Set:..msgLastPage="" ..msgLastPage = $$$Text("Go to last page")
	Set:..msgNextPage="" ..msgNextPage = $$$Text("Go to next page")
	Set:..msgPreviousPage="" ..msgPreviousPage = $$$Text("Go to previous page")
	set loop=..children.GetAt(1).children
	for i=1:1:loop.Count() {
		if loop.GetAt(i).id["pageNo" {	
			set loop.GetAt(i).label=..msgPage
		}
		if loop.GetAt(i).id["pageCount" {
			set loop.GetAt(i).label=..msgOf
		}
		if loop.GetAt(i).id["btnFirst" {
			set loop.GetAt(i).title=..msgFirstPage
		}
		if loop.GetAt(i).id["btnLast" {
			set loop.GetAt(i).title=..msgLastPage
		}
		if loop.GetAt(i).id["btnNext" {
			set loop.GetAt(i).title=..msgNextPage
		}
		if loop.GetAt(i).id["btnPrev" {
			set loop.GetAt(i).title=..msgPreviousPage
		}
	}
	Quit $$$OK
}

}
