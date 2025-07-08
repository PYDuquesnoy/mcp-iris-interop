/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Editor logic for a Zen Application Studio Document.
/// 
Class %ZEN.StudioDocument.ZENAppEditor Extends %ZEN.StudioDocument.AbstractEditor [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

XData Style
{
<style type="text/css">
body {
	background: #C5D6D6;
	font-family: verdana, sans-serif;
}

#pageList {
	overflow: auto;
}

#title {
	width: 100%;
	background: silver;
	border-bottom: 1px solid darkblue;
	padding: 3px;
}

.aeDesc {
	color: darkblue;
	margin-top: 20px;
	margin-bottom: 20px;
}

.aeLink {
	padding: 4px;
	border: 1px solid darkblue;
	background: white;
	margin-bottom: 2px;
}

.aeLinkHover {
	padding: 4px;
	border: 1px solid darkblue;
	background: #FFFFA0;
	margin-bottom: 2px;
}

.aeLink .aeMarker {
	color: white;
}

.aeLinkHover .aeMarker {
	color: black;
}
</style>
}

/// Contents of application editor page;
XData Contents
{
<page xmlns="http://www.intersystems.com/zen" >
<html id="title" OnDrawContent="DrawHTMLTitle"></html>

<hgroup cellVAlign="top">
<html id="pageList" OnDrawContent="DrawHTMLContent"></html>

<svgFrame id="svgFrame" layout="vertical"
	height="500" width="500">
<radialNavigator id="navigator"
	height="500" width="500" onselectNode="zenPage.selectNode(zenThis);"
	title="Page Map"
>
</radialNavigator>
</svgFrame>

</hgroup>
</page>
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Quit $$$OK
}

/// DrawHTMLTitle for title bar.
Method DrawHTMLTitle(seed As %ZEN.Datatype.string) As %Status
{
	Set tAppName = $P(..documentName,".",1,$L(..documentName,".")-1)
	
	#; title
	&html<<div>#($$$TextHTML("Zen Application"))#: <b>#($ZCVT(tAppName,"O","HTML"))#</b></div>>

	Quit $$$OK
}

/// DrawHTMLContent for page list.
Method DrawHTMLContent(seed As %ZEN.Datatype.string) As %Status
{
	Set tAppName = $P(..documentName,".",1,$L(..documentName,".")-1)
	
	#; list of pages within this application
	Do ##class(%ZEN.Utils).%GetPagesInApplication(tAppName,.pages)
	
	Set tOpen = $$$TextHTML("Open")

	If '$D(pages) {
		&html<<div class="aeDesc">#($$$TextHTML("There are no pages within this application."))#</div>>
	}
	Else {
		&html<<div class="aeDesc">#($$$TextHTML("The following pages belong to this application:"))#</div>>
		
		Set pg = $O(pages(""))
		While (pg '= "") {
			&html<<div class="aeLink" onclick="zenPage.selectPage('#($ZCVT(pg,"O","JS"))#');" onmouseover="this.className='aeLinkHover';" onmouseout="this.className='aeLink';"><span class="aeMarker">&raquo;</span>#($ZCVT(pg,"O","HTML"))#&nbsp;[<a href="javascript:zenPage.openPage('#($ZCVT(pg,"O","JS"))#');">#(tOpen)#</a>]</div>>
			Set pg = $O(pages(pg))
		}
	}

	Quit $$$OK
}

/// openPage: Open a Studio window for the given page.
ClientMethod openPage(page) [ Language = javascript ]
{
	zenPage.raiseOpenDocument(page + '.cls');
}

/// selectPage: Point navigator to this page.
ClientMethod selectPage(page) [ Language = javascript ]
{
	var nav = this.getComponentById('navigator');
	var s = page.split('.');
	var name = s[s.length-1];
	nav.setProperty('mainLabel',name);

	// update navigator
	nav.clearNodes();
	var ok = this.UpdateNav(this.documentName,page,nav);
	nav.renderContents();
	
	this.setModified();
	
	// update inspector
	var props = new Array();
	props[0] = { name:'Name',type:'STRING',value:name }
	this.raiseSelect(props);
}

/// User click on node within Navigator.
ClientMethod selectNode(nav) [ Language = javascript ]
{
	var node = nav.getCurrNode();
	if (node) {
		this.selectPage(node.value);
	}
}

/// Rebuild the array of nodes used by the Navigator
/// to show pages linked <var>page</var>.
ClassMethod UpdateNav(appName As %String, page As %String, nav As %ZEN.SVGComponent.radialNavigator) As %Boolean [ ZenMethod ]
{
	Set tAppName = $P(appName,".",1,$L(appName,".")-1)

	#; list of pages within this application
	Do ##class(%ZEN.Utils).%GetLinksInPage(page,.pages)

	Set pg = $O(pages(""))
	While (pg '= "") {
		If (pg '= page) {
			Set tNode = ##class(%ZEN.Auxiliary.radialNode).%New()
			Do %page.%AddComponent(tNode)
			Set tNode.caption = $P(pg,".",$L(pg,"."))
			Set tNode.value = pg
			Do nav.nodes.Insert(tNode)
		}
		Set pg = $O(pages(pg))
	}
	Quit 1
}

/// This client event, if present, is fired when the page 
/// is first loaded or whenever it is resized.<br>
/// If this is called at load time, then <var>load</var> will
/// be true.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	// adjust size of page list

	// find divs for title and page
	var list = zenPage.getComponentById('pageList');
	var listDiv = list.getEnclosingDiv();
	var title = zenPage.getComponentById('title');
	var divTitle = title.getEnclosingDiv();

	// find height of window
	var winHeight = zenGetWindowHeight();
	var winWidth = zenGetWindowWidth();

	// adjust size of pageList
	var hgt = winHeight  - (parseInt(divTitle.offsetHeight));
	listDiv.style.height = hgt + 'px';

	// adjust size of navigator
	var wid = winWidth  - (parseInt(listDiv.offsetWidth));
	var sz = (wid > hgt) ? hgt : wid;

	var svgFrame = zenPage.getComponentById('svgFrame');
	svgFrame.setProperty('width',sz);
	svgFrame.setProperty('height',sz);

	var nav = zenPage.getComponentById('navigator');
	nav.setProperty('width',sz);
	nav.setProperty('height',sz);
}

}
