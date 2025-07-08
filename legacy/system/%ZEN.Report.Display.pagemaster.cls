/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specifies the &lt;page-sequence-master&gt; section of the report display that will be 
/// placed in the &lt;layout-master-set&gt; to allow the report to process the conditional 
/// alternatives defined by the &lt;masterreference&gt; tag definitions.
Class %ZEN.Report.Display.pagemaster Extends childrenNode [ Deprecated, System = 4 ]
{

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
		Set sc = child.%DrawPageToXSLFO(.context,.XSL,.delay,SectionName)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
			
	Quit sc
}

Method %DrawStyleToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, SectionName As %String = "") As %Status
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
		Set sc = child.%DrawStyleToXSLFO(.context,.XSL,.delay,SectionName)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
	
	Quit sc
}

Method %DrawStyleToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
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
		Set sc = child.%DrawStyleToHTML(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
	
	Quit sc
}

Method %DrawPageMasterToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, SectionName As %String = "") As %Status
{
	Set sc = $$$OK
	d ..tagChildren()	

	Do XSL.WriteLine("   <fo:page-sequence-master master-name='"_SectionName_"main'>")

	Do XSL.WriteLine("      <fo:repeatable-page-master-alternatives>")

	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		Set sc = child.%DrawPageMasterToXSLFO(.context,.XSL,.delay,SectionName)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
	Do XSL.WriteLine("      </fo:repeatable-page-master-alternatives>")
	
	Do XSL.WriteLine("   </fo:page-sequence-master>")		
	Quit sc
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean) As %Status
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
		Set sc = child.%DrawToHTML(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
			
	Quit sc
}

}
