/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// PageGenerator class.
/// This is used by the ZEN Page Wizard to create a new page with 2 columns
/// with methods to resize the columns dynamically.
Class %ZEN.Template.PageGenerator.Column2Page Extends %ZEN.Template.PageGenerator [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

/// Return caption displayed by Wizard for this Page Generator.
ClassMethod %GetCaption() As %String
{
	Quit $$$Text("Column 2")
}

/// Draw the SVG icon displayed within the PageWizard.<br>
/// This should return a set of JS statements that will create a
/// set of SVG elements. These elements should be placed within an
/// SVG container called <var>theGroup</var>.<br>
/// <var>pID</var> is the id that should be assigned to the background
/// SVG element so that mouse handling and highlighting will work.
ClassMethod %RenderSVGIcon(pID As %String) As %Status
{
	#; outer rect
	Do ##super(pID)
	&js<
		var line = theDocument.createElementNS(SVGNS,'line');
		line.setAttribute('x1',0);
		line.setAttribute('y1',20);
		line.setAttribute('x2',150);
		line.setAttribute('y2',20);
		line.setAttribute('style','stroke: blue; stroke-width: 1;');
		theGroup.appendChild(line);

		var line = theDocument.createElementNS(SVGNS,'line');
		line.setAttribute('x1',40);
		line.setAttribute('y1',20);
		line.setAttribute('x2',40);
		line.setAttribute('y2',100);
		line.setAttribute('style','stroke: blue; stroke-width: 1;');
		theGroup.appendChild(line);
	>

	Quit $$$OK
}

/// Write out the contents of the XDATA Style block for this page.<br>
/// <var>pInfo</var> includes information about the class to be created.
ClassMethod %WriteXDATAStyle(pInfo As %ZEN.Template.PageGeneratorInfo) As %Status
{
	&html<<style type="text/css">
/* style for title bar */
#title {
	background: #C5D6D6;
	color: black;
	font-family: Verdana;
	font-size: 1.5em;
	font-weight: bold;
	padding: 5px;
	border-bottom: 1px solid black;
	text-align: center;
}

/* group on left-hand side */
#groupLeft {
	border-right: 1px solid black;
	background: #E0E0FF;
	height: 600px;
	width: 300px;
	overflow: auto;
}

/* group on right-hand side */
#groupRight {
	border-right: 1px solid black;
	background: #E0FFE0;
	height: 600px;
	overflow: auto;
}

</style>>
	Quit $$$OK
}

/// Write out the contents of the XDATA Contents block for this page.<br>
/// <var>pInfo</var> includes information about the class to be created.
ClassMethod %WriteXDATAContents(pInfo As %ZEN.Template.PageGeneratorInfo) As %Status
{
	&html<<page xmlns="http://www.intersystems.com/zen" title="#(pInfo.PageTitle)#">
<html id="title">Title</html>
<hgroup id="hgroup" width="100%">
<vgroup id="groupLeft">
<!-- put contents of left column here -->
<html>Column 1</html>
</vgroup>
<vgroup id="groupRight">
<!-- put contents of right column here -->
<html>Column 2</html>
</vgroup>
</hgroup>
</page>>

	Quit $$$OK
}

/// Write out method definitions for this page.<br>
/// <var>pInfo</var> includes information about the class to be created.
ClassMethod %WriteMethods(pInfo As %ZEN.Template.PageGeneratorInfo) As %Status
{
	#; write out override of onlayoutHandler
	&html<
/// This method is called when this page is resized.
/// In response to a resize, we use JavaScript to dynamically
/// resize the 2 main groups on this page.
/// You can modify this method to meet your needs.
ClientMethod onlayoutHandler(load) [ Language = javascript ]
{
	// find enclosing div for the title (if present) and get its height
	var title = zenPage.getComponentById('title');
	var divTitle = title ? title.getEnclosingDiv() : null;
	var hgtTitle = divTitle ? parseInt(divTitle.offsetHeight) : 0;
	// find the enclosing divs for the 2 groups
	var groupLeft = zenPage.getComponentById('groupLeft');
	var groupRight = zenPage.getComponentById('groupRight');
	var divgroupLeft = groupLeft ? groupLeft.getEnclosingDiv() : null;
	var divgroupRight = groupRight ? groupRight.getEnclosingDiv() : null;
	// find height of window
	var winHeight = zenGetWindowHeight();
	var winWidth = zenGetWindowWidth();
	// adjust the size of groups
	var widLeft = divgroupLeft ? parseInt(divgroupLeft.offsetWidth) : 0;
	var widRight = winWidth - widLeft;
	var hgt = winHeight - hgtTitle - 20;
	if (divgroupLeft) {
		divgroupLeft.style.height = hgt + 'px';
	}
	if (divgroupRight) {
		divgroupRight.style.height = hgt + 'px';
		divgroupRight.style.width = widRight + 'px';
	}
}
	>
	Quit $$$OK
}

}
