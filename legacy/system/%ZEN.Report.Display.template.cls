/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.template Extends childrenNode [ Deprecated, System = 4 ]
{

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)
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
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit sc
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	Set sc = $$$OK
	d ..%BeginDrawFo(.context,.XSL,.delay)
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
	d ..%EndDrawFo(.context,.XSL,.delay)		
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

Method %DrawPageMasterToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, SectionName As %String = "") As %Status
{
	Set sc = $$$OK
	d ..tagChildren()	

	if (..tag="pagemaster") {
		Do XSL.WriteLine("   <fo:page-sequence-master master-name='"_SectionName_"main'>")

		Do XSL.WriteLine("      <fo:repeatable-page-master-alternatives>")
	}

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
	if (..tag="pagemaster") {
		Do XSL.WriteLine("      </fo:repeatable-page-master-alternatives>")
	
		Do XSL.WriteLine("   </fo:page-sequence-master>")		
	}
	Quit sc
}

Storage Default
{
<Data name="templateDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%ZEN.Report.Display.templateD</DataLocation>
<DefaultData>templateDefaultData</DefaultData>
<IdLocation>^%ZEN.Report.Display.templateD</IdLocation>
<IndexLocation>^%ZEN.Report.Display.templateI</IndexLocation>
<StreamLocation>^%ZEN.Report.Display.templateS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
