/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %ZEN.Utils

/// This utility class is used by the ZEN Page Wizard to provide
/// a set of sample pages for the user to choose from.
Class %ZEN.Template.ZENPageList Extends %RegisteredObject [ Abstract, Deprecated, System = 4 ]
{

/// Return an array of page generator classes.
ClassMethod %GetPageGenerators(Output pPages) As %Status [ Final ]
{
	#; loop over all subclasses of the base PageGenerator class
	Set tRS = ##class(%ResultSet).%New("%Dictionary.ClassDefinition.SubclassOf")
	Set tSC = tRS.%Execute("%ZEN.Template.PageGenerator")
	
	#; add default to list
	Set pPages("Default") = "%ZEN.Template.PageGenerator"

	While (tRS.%Next()) {
		Set tName = $G(tRS.Data("Name"))

		#; only use compiled classes
		If ($$$comClassDefined(tName)) {
			Set tCaption = ..%GetPageCaption(tName)
			Set:tCaption="" tCaption=tName
			Set pPages(tCaption) = tName
		}
	}

	Quit $$$OK
}

/// Return the caption that should be used for the page.
ClassMethod %GetPageCaption(pClass As %String) As %String
{
	Set $ZT="Trap"
	Quit $zobjclassmethod(pClass,"%GetCaption")
Trap
	Set $ZT=""
	Quit pClass
}

/// Draw the SVG icon for the given page.
/// <var>pClass</var> is a generator class name
ClassMethod %GetPageSVG(pClass As %String) As %Status
{
	Set $ZT="Trap"
	#; get class to render icon using given id
	Do $zobjclassmethod(pClass,"%RenderSVGIcon","icon_"_pClass)
	Quit $$$OK
Trap
	Set $ZT=""
	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

/// Get generator class to write out methods for the new class.
ClassMethod %WriteMethods(pClass As %String, pInfo As %ZEN.Template.PageGeneratorInfo) As %Status
{
	Set $ZT="Trap"
	Do $zobjclassmethod(pClass,"%WriteMethods",pInfo)
	Quit $$$OK
Trap
	Set $ZT=""
	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

/// Get generator class to write out the XDATA Contents block for the new class.
ClassMethod %WriteXDATAContents(pClass As %String, pInfo As %ZEN.Template.PageGeneratorInfo) As %Status
{
	Set $ZT="Trap"
	Do $zobjclassmethod(pClass,"%WriteXDATAContents",pInfo)
	Quit $$$OK
Trap
	Set $ZT=""
	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

/// Get generator class to write out the XDATA Style block for the new class.
ClassMethod %WriteXDATAStyle(pClass As %String, pInfo As %ZEN.Template.PageGeneratorInfo) As %Status
{
	Set $ZT="Trap"
	Do $zobjclassmethod(pClass,"%WriteXDATAStyle",pInfo)
	Quit $$$OK
Trap
	Set $ZT=""
	Quit $$$ERROR($$$ObjectScriptError,$ZE)
}

}
