/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// PageGenerator class.
/// This is used by the ZEN Page Wizard to create a new Title Page.
Class %ZEN.Template.PageGenerator.TitlePage Extends %ZEN.Template.PageGenerator [ Deprecated, System = 4 ]
{

Parameter DOMAIN = "%ZEN";

/// Return caption displayed by Wizard for this Page Generator.
ClassMethod %GetCaption() As %String
{
	Quit $$$Text("Title Page")
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
</style>>
	Quit $$$OK
}

/// Write out the contents of the XDATA Contents block for this page.<br>
/// <var>pInfo</var> includes information about the class to be created.
ClassMethod %WriteXDATAContents(pInfo As %ZEN.Template.PageGeneratorInfo) As %Status
{
	&html<<page xmlns="http://www.intersystems.com/zen" title="#(pInfo.PageTitle)#">
<html id="title">Title</html>
<vgroup width="100%">
<!-- put page contents here -->
</vgroup>
</page>>

	Quit $$$OK
}

}
