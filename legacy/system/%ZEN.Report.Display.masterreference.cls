/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specifies the &lt;conditional-page-master-refference&gt; used by the the
/// &lt;page-sequence-master&gt; section of the report display.
Class %ZEN.Report.Display.masterreference Extends childrenNode [ Deprecated, System = 4 ]
{

/// Defines the refere
Property masterReference As %ZEN.Datatype.string [ Required ];

Property pagePosition As %ZEN.Datatype.string(VALUELIST = ",only,first,last,rest,any") [ Required ];

Property ifxpath As %ZEN.Datatype.string(XMLPROJECTION = "none");

Property ifexpression As %ZEN.Datatype.string(XMLPROJECTION = "none");

Property unlessexpression As %ZEN.Datatype.string(XMLPROJECTION = "none");

Property includeColUnlessExpression As %ZEN.Datatype.string(XMLPROJECTION = "none");

Property includeColIfExpression As %ZEN.Datatype.string(XMLPROJECTION = "none");

Method %DrawPageToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, SectionName As %String = "") As %Status
{
	Set sc = $$$OK
	d ..tagChildren()	

	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		Set sc = child.%DrawPageToXSLFO(.context,.XSL,.delay,SectionName_..masterReference)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
	
	Quit sc
}

Method %DrawStyleToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, SectionName As %String = "") As %Status
{
	Set sc = $$$OK
	d ..tagChildren()	
	Set document = ""
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		If child.tag = "document" Set document = child
		If child.tag = "pageheader" {
			Set:child.regionName="" child.regionName = "xsl-region-before-"_SectionName_..masterReference
			If document '= "" {
				Set:document.regionBeforeName="" document.regionBeforeName = "xsl-region-before-"_SectionName_..masterReference
			}
		}
		If child.tag = "pagefooter" {
			Set:child.regionName="" child.regionName = "xsl-region-after-"_SectionName_..masterReference
			If document '= "" {
				Set:document.regionAfterName="" document.regionAfterName = "xsl-region-after-"_SectionName_..masterReference
			}
		}
		If child.tag = "pagestartsidebar" {
			Set:child.regionName="" child.regionName = "xsl-region-start-"_SectionName_..masterReference
			If document '= "" {
				Set:document.regionStartName="" document.regionStartName = "xsl-region-start-"_SectionName_..masterReference
			}
		}
		If child.tag = "pageendsidebar" {
			Set:child.regionName="" child.regionName = "xsl-region-end-"_SectionName_..masterReference
			If document '= "" {
				Set:document.regionEndName="" document.regionEndName = "xsl-region-end-"_SectionName_..masterReference
			}
		}
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		Set sc = child.%DrawStyleToXSLFO(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
	
	Quit sc
}

Method %DrawStyleToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, SectionName As %String = "") As %Status
{
	Set sc = $$$OK
	d ..tagChildren()	
	Set document = ""
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		If child.tag = "document" Set document = child
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		Set sc = child.%DrawStyleToHTML(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
	
	Quit sc
}

Method %DrawPageMasterToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, SectionName As %String = "") As %Status
{
	Set sc = $$$OK
	
	Do XSL.Write("<fo:conditional-page-master-reference")
	Do XSL.Write(" page-position='"_..pagePosition_"'")
	Do XSL.WriteLine(" master-reference='"_SectionName_..masterReference_"'>")
	$$$stylefo
	Do XSL.WriteLine("</fo:conditional-page-master-reference>")
	Quit sc
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean, SectionName As %String = "") As %Status
{
	Set sc = $$$OK
	Set document=""
	d ..tagChildren()	

	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		If child.tag = "document" Set document = child
		If child.tag = "pageheader" {
			Set:child.regionName="" child.regionName = "xsl-region-before-"_SectionName_..masterReference
			If document '= "" {
				Set:document.regionBeforeName="" document.regionBeforeName = "xsl-region-before-"_SectionName_..masterReference
			}
		}
		If child.tag = "pagefooter" {
			Set:child.regionName="" child.regionName = "xsl-region-after-"_SectionName_..masterReference
			If document '= "" {
				Set:document.regionAfterName="" document.regionAfterName = "xsl-region-after-"_SectionName_..masterReference
			}
		}
		If child.tag = "pagestartsidebar" {
			Set:child.regionName="" child.regionName = "xsl-region-start-"_SectionName_..masterReference
			If document '= "" {
				Set:document.regionStartName="" document.regionStartName = "xsl-region-start-"_SectionName_..masterReference
			}
		}
		If child.tag = "pageendsidebar" {
			Set:child.regionName="" child.regionName = "xsl-region-end-"_SectionName_..masterReference
			If document '= "" {
				Set:document.regionEndName="" document.regionEndName = "xsl-region-end-"_SectionName_..masterReference
			}
		}
		
		d ..updateFromTemplate(.child)
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		Set sc = child.%DrawToXSLFO(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
			
	Quit sc
}

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
{
	Set sc = $$$OK
	d ..tagChildren()	

	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		if (child.tag="pageheader") {
			if ..pagePosition="any" {
				Set sc = child.%DrawToHTML(.context,.XSL,.delay)
			}
		} else {
			Set sc = child.%DrawToHTML(.context,.XSL,.delay)
		}
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
			
	Quit sc
}

}
