/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This utility class is used by the ZEN Page Wizard to generate new page class definitions.
Class %ZEN.Template.PageGenerator [ Abstract, Deprecated, System = 4 ]
{

/// Localization domain.
Parameter DOMAIN = "%ZEN";

/// Return caption displayed by Wizard for this Page Generator.
ClassMethod %GetCaption() As %String
{
	Quit ""
}

/// Draw the SVG icon displayed within the PageWizard.<br>
/// This should return a set of JS statements that will create a
/// set of SVG elements. These elements should be placed within an
/// SVG container called <var>theGroup</var>.<br>
/// <var>pID</var> is the id that should be assigned to the background
/// SVG element so that mouse handling and highlighting will work.
ClassMethod %RenderSVGIcon(pID As %String) As %Status
{
	#; default page icon
	&js<
		var rect = theDocument.createElementNS(SVGNS,'rect');
		rect.setAttribute('id','#(pID)#');
		rect.setAttribute('x',0);
		rect.setAttribute('y',0);
		rect.setAttribute('width',150);
		rect.setAttribute('height',100);
		rect.setAttribute('fill','white');
		rect.setAttribute('stroke','blue');
		rect.setAttribute('stroke-width','1');
		theGroup.appendChild(rect);
	>
	
	Quit $$$OK
}

/// Write out the contents of the XDATA Style block for this page.<br>
/// <var>pInfo</var> includes information about the class to be created.
ClassMethod %WriteXDATAStyle(pInfo As %ZEN.Template.PageGeneratorInfo) As %Status
{
	&html<<style type="text/css">
</style>>
	Quit $$$OK
}

/// Write out the contents of the XDATA Contents block for this page.<br>
/// <var>pInfo</var> includes information about the class to be created.
ClassMethod %WriteXDATAContents(pInfo As %ZEN.Template.PageGeneratorInfo) As %Status
{
	&html<<page xmlns="http://www.intersystems.com/zen" title="#(pInfo.PageTitle)#">
</page>>

	Quit $$$OK
}

/// Write out method definitions for this page.<br>
/// <var>pInfo</var> includes information about the class to be created.
ClassMethod %WriteMethods(pInfo As %ZEN.Template.PageGeneratorInfo) As %Status
{
	Quit $$$OK
}

}
