/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Displays the set of active components on a ZEN page within
/// a simple tree.<br>
/// This is used by ZEN Tools. 
Class %ZEN.Component.objectBrowser Extends component [ Deprecated, System = 3 ]
{

/// If defined, this is the page object containing the objects
/// we are browsing.
Property sourcePage As %ZEN.Component.page;

/// If defined, this is the id of top-most zen component to display
/// within the object browser.
Property rootObjectId As %ZEN.Datatype.string;

/// onselect event handler:
/// This event is fired when the user selects a component in the browser.
Property onselect As %ZEN.Datatype.eventHandler;

/// defines style sheet used by this component
XData Style
{
<style type="text/css">

/* outer div for object browser */
div.objectBrowserDiv {
	background: white;
	border: 1px solid black;
	padding: 2px;
	overflow: auto;
	height: 400px;
}

ul.objectBrowser {
	list-style-type: disc;
	margin-top: 0px;
	padding-top: 0px;
	margin-left: 0.5em;
	padding-left: 0.5em;
}

</style>
}

Method %DrawHTML()
{
	&html<<div class="objectBrowserDiv" id="#(..%MakeId("objectBrowser"))#"></div>>
	Set ..renderFlag = ..renderFlag + 1
}

/// Update the values displayed within the browser.
ClientMethod update() [ Language = javascript ]
{
	this.renderBrowser();
}

/// this client event is fired when the page is loaded.
ClientMethod renderContents() [ Language = javascript ]
{
	this.renderBrowser();
}

/// Initialize additional client-side variables
ClientMethod onCreate() [ Language = javascript ]
{
	// index of current object
	this.currObject = 1;
}

/// Return current object.
ClientMethod getCurrObject() [ Language = javascript ]
{
	var page = this.sourcePage ? this.sourcePage : zenPage;
	return page.getComponent(this.currObject);
}

/// Make given component the current browser selection.
ClientMethod setCurrObject(obj) [ Language = javascript ]
{
	zenASSERT(obj&&zenIsComponent(obj),"Invalid component.",arguments);
	this.currObject = obj.index;
	this.renderBrowser();

	// invoke callback, if present
	zenInvokeCallbackMethod(this.onselect,this,'onselect');
}

/// Redraw contents of browser to match current set of client objects
ClientMethod renderBrowser() [ Language = javascript ]
{
	// fill in div tag
	var div = this.findElement('objectBrowser');
	zenASSERT(div,"Unable to find div.",arguments);

	// find root object
	var page = this.sourcePage ? this.sourcePage : zenPage;
	var root = page.getComponentById(this.rootObjectId);
	if (!root) {
		root = page;
	}

	// build HTML to show object tree
	var html = new Array();
	html[html.length] = '<ul class="objectBrowser">';
	this.renderObject(root,html,1)
	html[html.length] = '</ul>';

	div.innerHTML = html.join("");
}

/// Get HTML for one object in client object tree.
ClientMethod renderObject(obj, html, level) [ Language = javascript ]
{
	var style = '';
	if (obj.index == this.currObject) {
		style = 'style="border: 1px solid black; background: yellow;"';
	}
	
	html[html.length] = '<li '+style+' onclick="zenPage.getComponent('+this.index+').selectObject('+obj.index+');">&nbsp;';
	html[html.length] = obj._type + ((obj.id&&obj.id!='') ? (' <i>'+obj.id+'</i>') : '');
	html[html.length] = '&nbsp;</li>';	

	// recurse over children (unless we are a composite object)
	if (obj.children && !obj.isOfType('composite')) {
		html[html.length] = '<ul class="objectBrowser">';
		for (var n in obj.children) {
			this.renderObject(obj.children[n],html,level+1);
		}
		html[html.length] = '</ul>';
	}
}

/// Select the given object within the object browser.
ClientMethod selectObject(index) [ Language = javascript ]
{
	var page = this.sourcePage ? this.sourcePage : zenPage;
	this.setCurrObject(page.getComponent(index));
}

}
