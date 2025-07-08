/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Renders the XSLT stylesheet that displays a ZEN report.
Class %ZEN.Report.Display.section Extends childrenNode [ Deprecated, System = 4 ]
{

/// This property must match the name of the outermost tag of the report data.
/// In the case of ZEN generated data, this attribute must match the name
/// attribute of the &lt;report&lt; tag in the ReportDefinition XData block.
Property name As %ZEN.Datatype.name;

/// Primary outer sort group name that XSL:for-each statement will work with
Property primaryGroup As %ZEN.Datatype.string;

/// Primary outer sort group name ifxpath condition to determine if a group iteration should be
/// included and a page sequnce generated
Property primaryGroupifxpath As %ZEN.Datatype.string;

/// Allow setting page number format:
/// use i or I for roman
/// use a or A for alphabetic
/// use 1 for numeric
Property pageNumberFormat As %ZEN.Datatype.string;

/// Report title
Property title As %ZEN.Datatype.caption;

/// Terminate if empty
Property terminateIfEmpty As %ZEN.Datatype.boolean;

Property StripSpace;

Property PreserveSpace;

Property Indent;

Property Encoding;

Property parentClass As %String;

Property sectionName As %ZEN.Datatype.string [ Required ];

/// writing-mode XML attribute.  It has the following possible values.  Note that not all XSL-FO renderers will support all possible values. <br>
/// lr-tb Text are written left-to-right and top-to-bottom (normal "alphabetic" text) <br>
/// rl-tb Text are written right-to-left and top-to-bottom (Arabic and Hebrew text) <br>
/// tb-rl Text are written top-to-bottom and right-to-left (Chinese and Japanese text) <br>
/// lr Same as lr-tb <br>
/// rl Same as rl-tb <br>
/// tb Same as tb-rl <br>
/// inherit <br>
Property writingMode As %ZEN.Datatype.string(VALUELIST = ",lr-tb,rl-tb,tb-rl,lr,rl,tb,inherit", XMLNAME = "writing-mode");

Method %DrawToXSLFOStyle(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, ByRef documentArray As %ArrayOfDataTypes, ByRef masterArray As %ArrayOfDataTypes) As %Status
{
	Set sc=$$$OK

	Set i = ..children.Next("")
	While (i'="") {
		Set child=..children.GetAt(i)
		If child.tag="document" {
			Set document=..GetDocForXSLFO(##this,.context,.XSL,..children,..xpath)
			Set sc=document.%DrawStyleToXSLFO(.context,.XSL,.delay) Quit:$$$ISERR(sc)
			Set documentId = ..sectionName_"main"
			Set documentArray(documentId) = document
			Quit
		}
		If child.tag="pagemaster" {
			Set pagemaster=..GetPageMasterForXSLFO(##this,.context,.XSL,..children,..xpath)
			Set sc=pagemaster.%DrawStyleToXSLFO(.context,.XSL,.delay) Quit:$$$ISERR(sc)
			Set masterId = ..sectionName
			Set masterArray(masterId)=pagemaster
			Quit
		}
		Quit:$$$ISERR(sc)
		Set i = ..children.Next(i)
	}
	Quit sc
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, ByRef incell As %Boolean, SubReport As %String) As %Status
{
	Set sc=$$$OK
	d ..tagChildren()
	if ..sectionName="" quit $$$ERROR($$$GeneralError,"sectionName of section must not be null and must be unique amongst sections!")
	Set SubReport = $Get(SubReport)
	
	if (SubReport="") {
				
		if ..ifxpath '= "" {
			Do XSL.WriteLine("       <xsl:if test='"_..ifxpath_"'>")
		}
		
		if ..primaryGroup'="" {
			// Bug fix for primaryGroup
			// Move terminateIfEmpty logic outside for primarGroup <xsl:for-each> logic
			if ..terminateIfEmpty {
				Do XSL.WriteLine(" <xsl:if test='count(descendant::*)=0'>")
				//JSL5237
				Do XSL.Write("       <fo:page-sequence master-reference='"_..sectionName_"main' id='{generate-id(.)}' "_$s(..writingMode'="":" writing-mode='"_..writingMode_"'",1:"")_$S(..pageNumberFormat'="":" format='"_..pageNumberFormat_"'",1:""))
				Do XSL.WriteLine(" initial-page-number='1' force-page-count='no-force'>")
				Do XSL.WriteLine("  <xsl:variable name='zenPageSequenceId' select='generate-id(.)'/>")
				Do XSL.WriteLine("	<fo:flow flow-name='xsl-region-body'>")
				Do XSL.WriteLine("	  <fo:block>")
				Do XSL.WriteLine("	   <fo:inline>")
				Do XSL.WriteLine("	   No Data!")
				Do XSL.WriteLine("	   </fo:inline>")
				Do XSL.WriteLine("	  </fo:block>")
				Do XSL.WriteLine("	</fo:flow>")
				Do XSL.WriteLine("  </fo:page-sequence>")
				Do XSL.WriteLine(" </xsl:if>")
				Do XSL.WriteLine("   <xsl:if test='descendant::*'>")
			}
			// Bug fix for primaryGroup
			// Add <xsl:if> block that tests if the primaryGroup count is 0 and provides 
			// the <fo:root> child elements that would not have been built
			Do XSL.WriteLine("<xsl:if test='count(/"_..qualify(..name)_"/"_..primaryGroup_")=0'>")
			If (..primaryGroupifxpath '= "") {
				Do XSL.Write("       <xsl:if test='"_..primaryGroupifxpath_"'>")
			}	
			//JSL5237
			Do XSL.Write("       <fo:page-sequence master-reference='"_..sectionName_"main' id='{generate-id(.)}' "_$s(..writingMode'="":" writing-mode='"_..writingMode_"'",1:"")_$S(..pageNumberFormat'="":" format='"_..pageNumberFormat_"'",1:""))
			Do XSL.WriteLine(" initial-page-number='1' force-page-count='no-force'>")
			Do XSL.WriteLine("       <xsl:variable name='zenPageSequenceId' select='generate-id(.)'/>")
			Set title = $s(..title'="":..title,1:"Untitled Report")
			Do XSL.WriteLine("          <fo:title>"_..title_"</fo:title>")
			Set context="report",key=..children.Next("")
			While (key'="") {
				Set child=..children.GetAt(key)
				if child.tag'="init" {
					d ..updateFromTemplate(.child)		
					Set child.parent=$$$THIS
					Set child.xpath=..xpath
					Set sc = child.%DrawToXSLFO(.context,.XSL,.delay)
					Quit:$$$ISERR(sc)
				}
				Set key=..children.Next(key)
			}
			if (SubReport="") {
				//Do XSL.WriteLine("          </fo:flow>")
				Do XSL.WriteLine("       </fo:page-sequence>")
				If (..primaryGroupifxpath '= "") {
					Do XSL.Write("       </xsl:if>")
				}
			}
			Do XSL.WriteLine(" </xsl:if>") ; count(/"_..qualify(..name)_"/"_..primaryGroup_")=0
			// Bug fix for primaryGroup empty is above
			// We execute above if primaryGroup empty and if primaryGroup non-empty
			// then we come to this for-each loop and it has content which we go through			
			Do XSL.WriteLine("<xsl:for-each select='/"_..qualify(..name)_"/"_..primaryGroup_"'>")
			If (..primaryGroupifxpath '= "") {
				Do XSL.Write("       <xsl:if test='"_..primaryGroupifxpath_"'>")
			}
		}	
		//JSL5327
		Do XSL.Write("       <fo:page-sequence master-reference='"_..sectionName_"main' id='{generate-id(.)}' "_$s(..writingMode'="":" writing-mode='"_..writingMode_"'",1:"")_$S(..pageNumberFormat'="":" format='"_..pageNumberFormat_"'",1:""))
		Do XSL.WriteLine(" initial-page-number='1' force-page-count='no-force'>")
		Do XSL.WriteLine("       <xsl:variable name='zenPageSequenceId' select='generate-id(.)'/>")
		Set title = $s(..title'="":..title,1:"Untitled Report")
		Do XSL.WriteLine("          <fo:title>"_..title_"</fo:title>")
		
		// Bug fix for primaryGroup
		// terminateIfEmpty logic here if no a primaryGroup
		// if ..terminateIfEmpty {
		if ..terminateIfEmpty&&..primaryGroup="" {
			Do XSL.WriteLine("   <xsl:if test='count(descendant::*)=0'>")
			Do XSL.WriteLine("<fo:flow flow-name='xsl-region-body'>")
			Do XSL.WriteLine("  <fo:block>")
			Do XSL.WriteLine("   <fo:inline>")
			Do XSL.WriteLine("   No Data!")
			Do XSL.WriteLine("   </fo:inline>")
			Do XSL.WriteLine("  </fo:block>")
			Do XSL.WriteLine("</fo:flow>")
			Do XSL.WriteLine("   </xsl:if>")
		} 
		
		// Bug fix for primaryGroup
		// terminateIfEmpty logic here if no a primaryGroup
		// if ..terminateIfEmpty {
		if ..terminateIfEmpty&&..primaryGroup="" {
			Do XSL.WriteLine("   <xsl:if test='descendant::*'>")
		}
	}
			
	Set context="report",key=..children.Next("")
	While (key'="") {
		Set child=..children.GetAt(key)
		if child.tag'="init" {
			d ..updateFromTemplate(.child)		
			Set child.parent=$$$THIS
			Set child.xpath=..xpath
			Set sc = child.%DrawToXSLFO(.context,.XSL,.delay)
			Quit:$$$ISERR(sc)
		}
		Set key=..children.Next(key)
	}
	// Bug fix for primaryGroup
	// terminateIfEmpty logic here if no a primaryGroup
	// if ..terminateIfEmpty {
	if ..terminateIfEmpty&&..primaryGroup="" {
		Do XSL.WriteLine("   </xsl:if>")
	}
	if (SubReport="") {
		Do XSL.WriteLine("       </fo:page-sequence>")
		If ..primaryGroup '= "" {
			If (..primaryGroupifxpath '= "") {
				Do XSL.Write("       </xsl:if>")
			}
			Do XSL.WriteLine("       </xsl:for-each>")
			// Bug fix for primaryGroup
			// Move terminateIfEmpty logic outside for primarGroup <xsl:for-each> logic
			if ..terminateIfEmpty {
				Do XSL.WriteLine("   </xsl:if>")
			}
		}
		If ..ifxpath '= "" {
			Do XSL.WriteLine("       </xsl:if>")
		}
	}

	Quit sc
}

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean, embedXSL As %Boolean = 0, UseInternalXSLT As %Boolean = 0, SubReport As %String, MainReport As %String) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)
	Set sc = $$$OK
	d ..tagChildren()
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=##this
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		Set sc = child.%DrawToHTML(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit sc
}

ClassMethod processContext(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, children As %ZEN.Report.Display.childrenNode)
{
	do ##class(%ZEN.Report.Display.report).processContext(.context,.XSL,children)
}

ClassMethod GetDocForXSLFO(this, ByRef context As %String, ByRef XSL As %GlobalCharacterStream, children As %ZEN.Report.Display.childrenNode, xpath As %String) As document
{
	Set document=##class(%ZEN.Report.Display.document).%New()
	Set i = children.Next("")
	While (i'="") {
		Set child=children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=this
		Set child.xpath=xpath
		If child.tag="document" {
			Set document=child Quit
			Set orientation=document.orientation
		}
		//If (child.tag="pagefooter")||(child.tag="pageheader") {
		//	Set child.orientation=document.orientation
		//}
		Set i= children.Next(i)
	}
	quit document
}

ClassMethod GetPageMasterForXSLFO(this, ByRef context As %String, ByRef XSL As %GlobalCharacterStream, children As %ZEN.Report.Display.childrenNode, xpath As %String) As pagemaster
{
	Set pagemaster=##class(%ZEN.Report.Display.pagemaster).%New()
	Set i = children.Next("")
	While (i'="") {
		Set child=children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=this
		Set child.xpath=xpath
		If child.tag="pagemaster" {
			Set pagemaster=child Quit
		}
		Set i= children.Next(i)
	}
	quit pagemaster
}

Method GenerateInit(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, isFO As %Boolean) As %Status
{
	s sc=$$$OK
	Set init=""
	Set i = ..children.Next("")
	While (i'="") {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		If child.tag="init" {
			Set init=child Quit
		}
		Set i= ..children.Next(i)
	}
	if (init'="") {
		if (isFO) {
			Set sc=init.%DrawToXSLFO(.context,.XSL,.delay) 
		} else {
			Set sc=init.%DrawToHTML(.context,.XSL,.delay) 
		}
	}
	q sc
}

ClassMethod DoDocForHTML(this, ByRef context As %String, ByRef XSL As %GlobalCharacterStream, children As %ZEN.Report.Display.childrenNode, xpath As %String)
{
	Set i = children.Next("")
	While (i'="") {
		Set child=children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=this
		Set child.xpath=xpath
		If child.tag="document" {
			Do child.%DrawStyleToHTML(.context,.XSL,.delay)
		}
		If child.tag="pagemaster" {
			Set sc=child.%DrawStyleToHTML(.context,.XSL,.delay) Quit:$$$ISERR(sc)
		}
		Set i= children.Next(i)
	}
	Quit $$$OK
}

}
