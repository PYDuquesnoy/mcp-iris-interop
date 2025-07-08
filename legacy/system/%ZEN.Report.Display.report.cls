/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Renders the XSLT stylesheet that displays a ZEN report.
Class %ZEN.Report.Display.report Extends childrenNode [ Deprecated, System = 4 ]
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

/// writing-mode XML attribute.  It has the following possible values.  Note that not all XSL-FO renderers will support all possible values. <br>
/// lr-tb Text are written left-to-right and top-to-bottom (normal "alphabetic" text) <br>
/// rl-tb Text are written right-to-left and top-to-bottom (Arabic and Hebrew text) <br>
/// tb-rl Text are written top-to-bottom and right-to-left (Chinese and Japanese text) <br>
/// lr Same as lr-tb <br>
/// rl Same as rl-tb <br>
/// tb Same as tb-rl <br>
/// inherit <br>
Property writingMode As %ZEN.Datatype.string(VALUELIST = ",lr-tb,rl-tb,tb-rl,lr,rl,tb,inherit", XMLNAME = "writing-mode");

/// Report title
Property title As %ZEN.Datatype.caption;

/// Terminate if empty
Property terminateIfEmpty As %ZEN.Datatype.boolean;

/// font-family for fo:root, default value is "'Arial'"
/// <br>font-family-name is optional and does not have to be specified, in which case its value will be "'Arial'"
/// <br>Example: &lt;report name="MyReport" sql="SELECT WH,PNO FROM PARTS" font-family-name="Calibri">
/// <br>if font-family-name is "", i.e., null, no font-family attribute will be generated
Property fontFamilyName As %ZEN.Datatype.string(XMLNAME = "font-family-name") [ InitialExpression = "Arial" ];

Property StripSpace;

Property PreserveSpace;

Property Indent;

Property Encoding;

Property parentClass As %String;

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, ByRef incell As %Boolean, SubReport As %String, MainReport As %String, pUseInstalledFOP) As %Status
{
	//$$$levelNumInit
	Set ..applyLevel=-1
	Set sc=$$$OK
	Set PageMasterReport = 0
	Set SectionReport = 0
	Set SectionCount = 0
	Set i = ..children.Next("")
	Set foundNullSectionName=0
	While (i'="") {
		Set child=..children.GetAt(i)
		If child.tag="section" {
			if child.writingMode="",..writingMode'="" Set child.writingMode=..writingMode
			//Set section=##class(%ZEN.Report.Display.section).%New()
			d ..updateFromTemplate(.child)
			if (child.tag="template") {
				Set section=..GetFirstSection(child,.context,.XSL,child.children,child.xpath)
			} else {
				Set section=child
			}
			Set SectionCount = SectionCount +1
			Set SectionArray(SectionCount) = section
			if section.sectionName'="" {
				Set SectionNameCount(section.sectionName)=$i(SectionNameCount(section.sectionName))
			} else {
				Set foundNullSectionName=1
			}
			Set SectionReport = 1
		}
		Set i = ..children.Next(i)
	}
	if foundNullSectionName {
		quit $$$ERROR($$$GeneralError,"sectionName of section must not be null and must be unique amongst sections!")
	} else {
		Set j="" for {  Set j=$o(SectionNameCount(j),1,count) q:j=""
			if $g(count)>1 {
				quit
			}
		}
	}
	if $g(count)>1 {
		quit $$$ERROR($$$GeneralError,"sectionName of section must not be null and must be unique amongst sections! The sectionName "_j_" is not unique!")
	}
	New %report,%name
	Set %report=%context("OREF","this")
	Set context("tablenesting")=0
	kill ^||%ISC.ZENReport("ZENReportCache")
	Set context("SubReport")=SubReport
	Set context("primaryGroup")=..primaryGroup ; Prodlog 87313
	Set %name=..name
	if $e(%name)="!" {
		X "set %name="_$e(..name,2,$L(..name))
	}
	Set context("Name")=..qualify(%name)
	Do %report.OnAfterCreateDisplay()
	Set xmlns=""
	if ((..xmlnamespaceprefix'="") && (..xmlnamespace'="")) {
		Set xmlns=" xmlns:"_..xmlnamespaceprefix_"='"_..xmlnamespace_"'"
	}
	d ..tagChildren()
	d ..%BeginDrawFo(.context,.XSL,.delay)
	if (SubReport="") {
		Do XSL.WriteLine("<xsl:stylesheet version='"_%report.XsltVersion_"' ")
		Do XSL.WriteLine("   xmlns:xsl='http://www.w3.org/1999/XSL/Transform'")
		Do XSL.WriteLine("   xmlns:fo='http://www.w3.org/1999/XSL/Format'")
		Do XSL.WriteLine("   xmlns:xlink='http://www.w3.org/1999/xlink'")
		Do XSL.WriteLine("    xmlns:zr='http://www.intersystems.com/zenreports' xmlns:xs='http://www.w3.org/2001/XMLSchema' ")
		Do XSL.WriteLine("   xmlns:svg='http://www.w3.org/2000/svg'"_xmlns_$s(%report.NamespaceDeclarations="":"",1:" "_%report.NamespaceDeclarations)_">")
		Do XSL.WriteLine("   <xsl:output method='xml' version='1.0' indent='"_..Indent_"'"_$s(..Encoding'="":" encoding='"_..Encoding_"'",1:"")_"/>")
		if ..StripSpace'="" Do XSL.WriteLine("<xsl:strip-space elements="""_..StripSpace_"""/>")
		if ..PreserveSpace'="" Do XSL.WriteLine("<xsl:preserve-space elements="""_..PreserveSpace_"""/>")

		If ..style '= "none" Do ..%stdStyleSheetFO(.context,.XSL)

	}
	Do ..processContext(.context,.XSL,..children)

	Set tFoundDocumentOrPageMaster=0
	If 'SectionReport {
		if (SubReport="") {
			Set documentArray = ""
			Set masterArray = ""
			Set i = ..children.Next("")
			While (i'="") {
				Set child=..children.GetAt(i)
				;Set ^foobar($i(^foobar))="child.tag="_child.tag
				If child.tag="document" {
					d ..updateFromTemplate(.child)
					;Set document=..GetDocForXSLFO(##this,.context,.XSL,..children,..xpath)
					Set document=child
					Set sc=document.%DrawStyleToXSLFO(.context,.XSL,.delay) Quit:$$$ISERR(sc)
					Set documentArray("main") = document
					Set tFoundDocumentOrPageMaster=1
					Quit
				}
				If child.tag="pagemaster" {
					d ..updateFromTemplate(.child)
					Set pagemaster=..GetPageMaster(##this,.context,.XSL,..children,..xpath)
					Set sc=pagemaster.%DrawStyleToXSLFO(.context,.XSL,.delay) Quit:$$$ISERR(sc)
					Set masterArray("main")=pagemaster
					Set tFoundDocumentOrPageMaster=1
					Quit
				}
				Quit:$$$ISERR(sc)
				Set i = ..children.Next(i)
			}
			if (tFoundDocumentOrPageMaster=0) {
				Set document=##class(%ZEN.Report.Display.document).%New()
				Set sc=document.%DrawStyleToXSLFO(.context,.XSL,.delay) Quit:$$$ISERR(sc)
				Set documentArray("main") = document
			}
			// Proposed Enhancement End
			if $$$ISERR(sc) q sc
		}
	} Else {
		if (SubReport="") {
			Set i = ..children.Next("")
			While (i'="") {
				// incorporate any styles added by document
				Set child=..children.GetAt(i)
				If child.tag="document" {
					Set sc=child.%DrawStyleToXSLFO(.context,.XSL,.delay) Quit:$$$ISERR(sc)
					Quit
				}
				Set i = ..children.Next(i)
			}
			if $$$ISERR(sc) q sc
			Set documentArray = ""
			Set masterArray = ""
			For si = 1:1:SectionCount {
				Set section = SectionArray(si)
				d ..updateFromTemplate(.section)
				if (section.tag="template") {
					Set section=..GetFirstSection(section,.context,.XSL,section.children,section.xpath)
				}
				Set sc = section.%DrawToXSLFOStyle(.context,.XSL,.delay,.documentArray,.masterArray)
				Quit:$$$ISERR(sc)
			}
		}
	}
	if $$$ISERR(sc) q sc

	if (SubReport="") {
		Do XSL.WriteLine("   <xsl:template match='/"_..qualify(%name)_"'>")
	} else {
		Do XSL.WriteLine("   <xsl:template match='"_$s(MainReport'="":MainReport_"/",1:"")_..qualify(%name)_"' mode='"_SubReport_"'>")
		Do XSL.WriteLine(" <xsl:param name='zenPageSequenceId'/>")
	}

	if (SubReport="") {
		Do XSL.WriteLine("<fo:root xmlns:fo='http://www.w3.org/1999/XSL/Format' xmlns:fox='http://xmlgraphics.apache.org/fop/extensions' xmlns:pdf='http://xmlgraphics.apache.org/fop/extensions/pdf' "_$s(..fontFamilyName'="":("font-family='"_..fontFamilyName_"'"),1:"")_">")  // JSL5212 adds some more prefixes
		Do XSL.WriteLine("<fo:layout-master-set>")

		//Proposed Enhancement Begin
		//Set sc=document.%DrawPageToXSLFO(.context,.XSL,.delay) Quit:$$$ISERR(sc) sc
		Set documentId = $Order(documentArray(""))
		While documentId '= "" {
			Set document = documentArray(documentId)
			Set sc=document.%DrawPageToXSLFO(.context,.XSL,.delay,documentId) Quit:$$$ISERR(sc)
			Set documentId = $Order(documentArray(documentId))
		}
		Quit:$$$ISERR(sc) sc
		Set masterId = $Order(masterArray(""))
		While masterId '= "" {
			Set pagemaster = masterArray(masterId)
			if 'SectionReport {
				Set sc=pagemaster.%DrawPageToXSLFO(.context,.XSL,.delay,"") Quit:$$$ISERR(sc)
			} else {
				Set sc=pagemaster.%DrawPageToXSLFO(.context,.XSL,.delay,masterId) Quit:$$$ISERR(sc)
			}
			Set masterId = $Order(masterArray(masterId))
		}
		Quit:$$$ISERR(sc) sc
		Set masterId = $Order(masterArray(""))
		While masterId '= "" {
			Set pagemaster = masterArray(masterId)
			if 'SectionReport {
				Set sc=pagemaster.%DrawPageMasterToXSLFO(.context,.XSL,.delay,"") Quit:$$$ISERR(sc)
			} else {
				Set sc=pagemaster.%DrawPageMasterToXSLFO(.context,.XSL,.delay,masterId) Quit:$$$ISERR(sc)
			}
			Set masterId = $Order(masterArray(masterId))
		}
		Quit:$$$ISERR(sc) sc
		// Proposed Enhancement End

		Do XSL.WriteLine("</fo:layout-master-set>")
		// JSL5212 + support for titles
		If pUseInstalledFOP=1 { // Don't generate accessibilility instructions if the installed FOP is not being used,
								// For example, a FOP other than installed FOP, the FOP we install,
								// though using a FOP other than the installed FOP will result in
								// RenderServer either not working or not being supported through ISC
								// with IRIS
			Do XSL.WriteLine(" <fo:declarations>")
	        Do XSL.WriteLine(" <pdf:catalog >")
	        Do XSL.WriteLine(" <pdf:dictionary type='normal' key='ViewerPreferences'>")
	        Do XSL.WriteLine(" <pdf:boolean key='DisplayDocTitle'>true</pdf:boolean>")
	        Do XSL.WriteLine(" </pdf:dictionary>")
	        Do XSL.WriteLine(" </pdf:catalog>")
	        Do XSL.WriteLine(" <x:xmpmeta xmlns:x='adobe:ns:meta/'>")
	        Do XSL.WriteLine(" <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>")
	        Do XSL.WriteLine(" <rdf:Description rdf:about='' xmlns:dc='http://purl.org/dc/elements/1.1/'>")
	        Set title=$select(..title'="":..title,1:%report.%ClassName(1)_".cls")
	        Do XSL.WriteLine(" <dc:title>"_title_"</dc:title>")
	        Do XSL.WriteLine(" </rdf:Description>")
	        Do XSL.WriteLine(" </rdf:RDF>")
	        Do XSL.WriteLine(" </x:xmpmeta>")
			Do XSL.WriteLine(" </fo:declarations>")
			// JSL5212 - support for titles
			//+ JSL5217 support for bookmarks
			Do ..GenerateBookmarkTree(.context,.XSL,.delay)
			//- JSL5217
		}

	}

	If 'SectionReport {
		//JSL5238 
		if (SubReport="") {
			if ..primaryGroup'="" {
				// Bug fix for primaryGroup
				// Move terminateIfEmpty logic outside for primarGroup <xsl:for-each> logic
				if ..terminateIfEmpty {
					Do XSL.WriteLine(" <xsl:if test='count(descendant::*)=0'>")
					//JSL5237, JSL5238
					Do XSL.WriteLine("  <fo:page-sequence master-reference='main' id='{generate-id(.)}' "_$s(..writingMode'="":" writing-mode='"_..writingMode_"'",1:"")_$S(..pageNumberFormat'="":" format='"_..pageNumberFormat_"'",1:"")_">")
					Do XSL.WriteLine("       <xsl:variable name='zenPageSequenceId' select='generate-id(.)'/>")
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
				//JSL5237, JSL5238
				Do XSL.Write("       <fo:page-sequence master-reference='main' id='{generate-id(.)}'"_$s(..writingMode'="":" writing-mode='"_..writingMode_"'",1:"")_$S(..pageNumberFormat'="":" format='"_..pageNumberFormat_"'",1:""))
				Do XSL.WriteLine(" initial-page-number='1' force-page-count='no-force'>")
				Do XSL.WriteLine("       <xsl:variable name='zenPageSequenceId' select='generate-id(.)'/>")
				Set title = $s(..title'="":..title,1:"Untitled Report")
				Do XSL.WriteLine("          <fo:title>"_..title_"</fo:title>")
				Set context="report",key=..children.Next("")
				While (key'="") {
					Set child=..children.GetAt(key)
					if child.tag'="init",child.tag'= "bookmarkTree" {
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
					//Do XSL.WriteLine("   </fo:root>")
				}
				Do XSL.WriteLine(" </xsl:if>") ; count(/"_..qualify(..name)_"/"_..primaryGroup_")=0'
				// Bug fix for primaryGroup empty is above
				// We execute above if primaryGroup empty and if primaryGroup non-empty
				// then we come to this for-each loop and it has content which we go through
				Do XSL.WriteLine("<xsl:for-each select='/"_..qualify(..name)_"/"_..primaryGroup_"'>")
				If (..primaryGroupifxpath '= "") {
					Do XSL.Write("       <xsl:if test='"_..primaryGroupifxpath_"'>")
				}
				//JSL5237,JSL5238
				Do XSL.Write("       <fo:page-sequence master-reference='main' id='{generate-id(.)}' "_$s(..writingMode'="":" writing-mode='"_..writingMode_"'",1:"")_$S(..pageNumberFormat'="":" format='"_..pageNumberFormat_"'",1:""))
				Do XSL.WriteLine(" initial-page-number='1' force-page-count='no-force'>")
				Do XSL.WriteLine("       <xsl:variable name='zenPageSequenceId' select='generate-id(.)'/>")
			} else {
				//JSL5237,JSL5238
				Do XSL.WriteLine("       <fo:page-sequence master-reference='main' id='{generate-id(.)}' "_$s(..writingMode'="":" writing-mode='"_..writingMode_"'",1:"")_$S(..pageNumberFormat'="":" format='"_..pageNumberFormat_"'",1:"")_">")
				Do XSL.WriteLine("       <xsl:variable name='zenPageSequenceId' select='generate-id(.)'/>")
			}

			Set title = $s(..title'="":..title,1:"Untitled Report")
			Do XSL.WriteLine("          <fo:title>"_..title_"</fo:title>")

			//Do XSL.WriteLine("          <fo:flow flow-name='xsl-region-body'>")
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
				if child.tag'="init",child.tag'="bookmarkTree" {
				d ..updateFromTemplate(.child)
				Set child.parent=##this
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
			//Do XSL.WriteLine("          </fo:flow>")
			Do XSL.WriteLine("       </fo:page-sequence>")
			If ..primaryGroup '= "" {
				If (..primaryGroupifxpath '= "") {
					Do XSL.Write("       </xsl:if>")
				}
				Do XSL.WriteLine("</xsl:for-each>")
				// Bug fix for primaryGroup
				// Move terminateIfEmpty logic outside for primarGroup <xsl:for-each> logic
				if ..terminateIfEmpty {
					Do XSL.WriteLine("   </xsl:if>")
				}
			}
			Do XSL.WriteLine("   </fo:root>")
		}
		Do XSL.WriteLine("    </xsl:template>")
		//Do XSL.WriteLine(delay.Read())
		Do XSL.CopyFrom(delay)
	} Else {
		// Add terminateIfEmpty to <report> level of <section> report
		if ..terminateIfEmpty {
			Do XSL.WriteLine(" <xsl:if test='count(descendant::*)=0'>")
			//JSL5237,JSL5238
			Set name=$Order(masterArray(""))
			Do XSL.WriteLine("  <fo:page-sequence master-reference='"_name_"main' id='{generate-id(.)}'"_$s(..writingMode'="":" writing-mode='"_..writingMode_"'",1:"")_$S(..pageNumberFormat'="":" format='"_..pageNumberFormat_"'",1:"")_">")
			Do XSL.WriteLine("	<fo:flow flow-name='xsl-region-body'>")
			Do XSL.WriteLine("	  <fo:block>")
			Do XSL.WriteLine("	   <fo:inline>")
			Do XSL.WriteLine("	   No Data!")
			Do XSL.WriteLine("	   </fo:inline>")
			Do XSL.WriteLine("	  </fo:block>")
			Do XSL.WriteLine("	</fo:flow>")
			Do XSL.WriteLine("  </fo:page-sequence>")
			Do XSL.WriteLine(" </xsl:if>")
		}

		// Add terminateIfEmpty to <report> level of <section> report
		if ..terminateIfEmpty {
			Do XSL.WriteLine("   <xsl:if test='descendant::*'>")
		}
		For si = 1:1:SectionCount {
			Set section = SectionArray(si)
			Set sc = section.%DrawToXSLFO(.context,.XSL,.delay,.incell,SubReport)
			Quit:$$$ISERR(sc)
		}
		if $$$ISERR(sc) quit sc
		// Add terminateIfEmpty to <report> level of <section> report
		if ..terminateIfEmpty {
			Do XSL.WriteLine("   </xsl:if>")
		}
		If (SubReport="") {
			Do XSL.WriteLine("   </fo:root>")
		}
		Do XSL.WriteLine("    </xsl:template>")
		Do XSL.CopyFrom(delay)
	}
	if (SubReport="") {
		Do ..%CopyReportPageXdata(.XSL,"CommonXslFo")
		; XSLT Xdata
		d ..%CopyXsltXdata(.XSL,"AllXslt","XslFoXslt")
		; end
	}
	s sc=..GenerateInit(.context,.XSL, .delay,1)
	if $$$ISERR(sc) q sc

	if (SubReport="") {
		Do XSL.WriteLine("  </xsl:stylesheet>")
	} else {
	}
	d ..%EndDrawFo(.context,.XSL,.delay)
	Quit sc
}

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean, embedXSL As %Boolean = 0, UseInternalXSLT As %Boolean = 0, SubReport As %String, MainReport As %String, pXSLTMode) As %Status
{
		//$$$levelNumInit
		Set ..applyLevel=-1
		Set sc=$$$OK
		Set PageMasterReport = 0
		Set SectionReport = 0
		Set SectionCount = 0
		Set i = ..children.Next("")
		While (i'="") {
			Set child=..children.GetAt(i)
			If child.tag="section" {
				Set section=##class(%ZEN.Report.Display.section).%New()
				Set section=child
				Set SectionCount = SectionCount +1
				Set SectionArray(SectionCount) = section
				Set SectionReport = 1
			}
			Set i = ..children.Next(i)
		}


		New %report,%name
		Set %report=%context("OREF","this")
		Set context("tablenesting")=0
		kill ^||%ISC.ZENReport("ZENReportCache")
		Set context("SubReport")=SubReport
		Set %name=..name
		if $e(%name)="!" {
			X "set %name="_$e(..name,2,$L(..name))
		}
		Set context("Name")=..qualify(%name)
		Do %report.OnAfterCreateDisplay()
		Set xmlns=""
		d ..tagChildren()
		if ((..xmlnamespaceprefix'="") && (..xmlnamespace'="")) {
			Set xmlns="xmlns:"_..xmlnamespaceprefix_"='"_..xmlnamespace_"'"
		}
		d ..%BeginDrawHtml(.context,.XSL,.delay)
		if (SubReport="") {
			Set tHasHtml5=1
			if $D(%request),$isobject(%request) {
				Set tHasHtml5=$s(%report.UseHTML5="":##class(%ZEN.Utils).%BrowserSupportsHTML5(%request.UserAgent),1:%report.UseHTML5)
			} else {
				Set tHasHtml5=%report.UseHTML5
			}
			If ($g(pXSLTMode) = "browser") { // problems with FireFox with xsl:text outputing doctype
				Set tHasHtml5 = 0
			}

			Do XSL.WriteLine("<xsl:stylesheet version='"_%report.XsltVersion_"'"_$s(tHasHtml5&&'embedXSL:"", 1:" xmlns='http://www.w3.org/1999/xhtml'")_" xmlns:xsl='http://www.w3.org/1999/XSL/Transform' xmlns:svg='http://www.w3.org/2000/svg' "_xmlns_" xmlns:xhtml='http://www.w3.org/1999/xhtml' xmlns:xs='http://www.w3.org/2001/XMLSchema' xmlns:zr='http://www.intersystems.com/zenreports'"_$s(%report.NamespaceDeclarations="":"",1:" "_%report.NamespaceDeclarations)_" exclude-result-prefixes='"_$s(tHasHtml5:"xs svg zr xhtml",1:"xhtml")_"'>")
			if tHasHtml5,'embedXSL {
				Do XSL.WriteLine("   <xsl:output method='html' indent='"_..Indent_"'"_$s(..Encoding'="":" encoding='"_..Encoding_"'",1:"")_"/>")
			} else {
				Do XSL.WriteLine("   <xsl:output method='xml' version='1.0' indent='"_..Indent_"'"_$s(..Encoding'="":" encoding='"_..Encoding_"'",1:"")_"/>")
			}
			if 'tHasHtml5,('embedXSL) && ('$D(%session) || '$isobject(%session) || (%session.BrowserName'="IE")) {
				Do XSL.WriteLine("   <xsl:output doctype-public='-//W3C//DTD XHTML 1.0 Transitional//EN'/>")
				Do XSL.WriteLine("   <xsl:output doctype-system='http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'/>")
			}
			if (tHasHtml5),'($D(%session) && $isObject(%session) && (%session.BrowserName="IE")),embedXSL {
				;Do XSL.WriteLine("   <xsl:output doctype-public='PUBLIC XSLT-compat'/>")
			}
			elseif (tHasHtml5),'($D(%session) && $isObject(%session) && (%session.BrowserName="IE")) {
				;Do XSL.WriteLine("   <xsl:output doctype-public='PUBLIC XSLT-compat'/>")
			} elseif tHasHtml5,($D(%session) && $isObject(%session) && (%session.BrowserName="IE")) {
				;Do XSL.WriteLine("   <xsl:output doctype-public='PUBLIC XSLT-compat'/>")
			}
			if $D(%session) && $isobject(%session) && (%session.BrowserName="IE") {
				;if 'tHasHtml5 Do XSL.WriteLine("   <xsl:output method='xml' indent='"_..Indent_"'/>")
			}
			if ..StripSpace'="" Do XSL.WriteLine("<xsl:strip-space elements="""_..StripSpace_"""/>")
			if ..PreserveSpace'="" Do XSL.WriteLine("<xsl:preserve-space elements="""_..PreserveSpace_"""/>")

			if embedXSL {
				Do XSL.WriteLine("<xsl:template match='xsl:stylesheet'>")
#if 0 // JSL4462
				if tHasHtml5 {
					Do XSL.WriteLine("      <xsl:text disable-output-escaping=""yes""><![CDATA[<!doctype html>]]></xsl:text>")
				}
#endif
				Do XSL.WriteLine("<xsl:apply-templates select='"_..qualify(%name)_"'>")
				;Do ..%ApplyLevelParameters(.context,.XSL,.delay)
				Do XSL.WriteLine("</xsl:apply-templates>")
				Do XSL.WriteLine("</xsl:template>")

			}
		}

		Set tPrefix=""
		if (SubReport="") {
			if 'embedXSL {
				Do XSL.WriteLine("<xsl:template match=""/"">")
				if tHasHtml5 {
					Do XSL.WriteLine("      <xsl:text disable-output-escaping=""yes""><![CDATA[<!doctype html>]]></xsl:text>")
				}
				Do XSL.WriteLine("<xsl:apply-templates select='"_..qualify(%name)_"'>")
				Do ..%ApplyLevelParameters(.context,.XSL,.delay)
				Do XSL.WriteLine("</xsl:apply-templates>")
				Do XSL.WriteLine("</xsl:template>")
			}
			Do XSL.WriteLine("   <xsl:template match='"_..qualify(%name)_"'>")
		} else {
			Do XSL.WriteLine("   <xsl:template match='"_$s(MainReport'="":MainReport_"/",1:"")_..qualify(%name)_"' mode='"_SubReport_"'>")
		}

		if (SubReport="") {
			if tHasHtml5 {
				Do XSL.WriteLine("      <html>")
			} else {
				Do XSL.WriteLine("      <html xmlns='http://www.w3.org/1999/xhtml' xmlns:svg='http://www.w3.org/2000/svg'"_$s(..Encoding'="":" encoding='"_..Encoding_"'",1:"")_">")
			}

			Set title = $s(..title'="":..title,1:"Untitled Report")
			Do XSL.WriteLine("         <head>")
			;this logic should have tested for IE8, I guess http://webdesign.about.com/od/metataglibraries/p/x-ua-compatible-meta-tag.htm
			;if (tHasHtml5),'($D(%session) && $isObject(%session) && (%session.BrowserName="IE")) {
			;	Do XSL.WriteLine("<meta http-equiv='X-UA-Compatible' content='IE=edge' />")
			;}
			Do XSL.WriteLine("<title>"_title_"</title>")
			s tEncoding=$ZCVT(..Encoding,"L")
			if 1 { //tEncoding="utf-8" {
				if tHasHtml5 && '..IsIE(){
					Do XSL.WriteLine("<meta http-equiv='Content-Type' content='text/html; charset="_..Encoding_"' />")
				} elseif 'tHasHtml5 || '..IsIE() {
					if 'tHasHtml5 {
						Do XSL.WriteLine("<meta http-equiv='Content-Type' content='text/html; charset="_tEncoding_"' />")
					} else {
						Do XSL.WriteLine("<meta charset='"_..Encoding_"' />")
					}
				} else {
					; we are HMLT 5 and IE - use 'EI=edge' to force IE out of compatibilty mode if IE9 or IE10 or later
					Do XSL.WriteLine("<meta http-equiv='X-UA-Compatible' content='IE=edge' charset='"_..Encoding_"'/>")
				}
			}
			If ..style'="none" {
				Do XSL.WriteLine("<style type='text/css'>")
				Do ..%stdStyleSheetCSS(.XSL)
				Do XSL.WriteLine("</style>")
			}

			if ..terminateIfEmpty {
				Do XSL.WriteLine("   <xsl:if test='descendant::*'>")
			}

			if 'SectionReport {
				Do ..DoDocForHTML(##this,.context,.XSL,..children,..xpath)
			} else {
				Set i = ..children.Next("")
				While (i'="") {
					Set child=..children.GetAt(i)
					d ..updateFromTemplate(.child)
					Set child.parent=##this
					Set child.xpath=..xpath
					If child.tag="document" {
						Do child.%DrawStyleToHTML(.context,.XSL,.delay)
					}
					Set i= ..children.Next(i)
				}

				Set documentArray = ""
				Set masterArray = ""
				For si = 1:1:SectionCount {
					Set section = SectionArray(si)
					Set sc = section.DoDocForHTML(section,.context,.XSL,section.children,section.xpath)
					Quit:$$$ISERR(sc)
				}

			}
			if $$$ISERR(sc) Quit sc
			if ..terminateIfEmpty {
				Do XSL.WriteLine("   </xsl:if>")
			}


			if 'tHasHtml5,($D(%session)&& $isObject(%session) && (%session.BrowserName="IE")) {

				// hack for IE+Adobe SVG
				d ..%ContainsChart(.containsChart)
				if (containsChart) {
					Do XSL.WriteLine("<object id='AdobeSVG' classid='clsid:78156a80-c6a1-4bbf-8e6a-3cd390eeb4e2'>")
	  				Do XSL.WriteLine("SVG hack")
  					Do XSL.WriteLine("</object>")
  					Do XSL.WriteLine("<xsl:processing-instruction name='import'>")
  					Do XSL.WriteLine("namespace='svg' implementation='#AdobeSVG'")
  					Do XSL.WriteLine("</xsl:processing-instruction>")

				}
			}

			Do XSL.WriteLine("</head>")
			// look for body, get its style attribute
			Set i = ..children.Next("")
			#dim body as %ZEN.Report.Display.body
			Set body="" // non-empty indicates body found
			While (i'="") {
				Set child=..children.GetAt(i)
				If child.tag="body" {
					Set body=child
					quit
				}
				Set i = ..children.Next(i)
			}

			Do XSL.WriteLine("<body "_$s(body'="":"style='"_body.style_"'",1:"")_">")
			Do XSL.WriteLine("<xsl:variable name='level0' select='position()'/>")
			if ..terminateIfEmpty {
				Do XSL.WriteLine("   <xsl:if test='count(descendant::*)=0'>")
				Do XSL.WriteLine("   <inline>")
				Do XSL.WriteLine("   No Data!")
				Do XSL.WriteLine("   </inline>")
				Do XSL.WriteLine("   </xsl:if>")
			}
			if ..terminateIfEmpty {
				Do XSL.WriteLine("   <xsl:if test='descendant::*'>")
			}
		}
		$$$groupNumSet(0)
		Set i = ..children.Next("")
		While (i'="") {
			Set child=..children.GetAt(i)
			if child.tag'="init" {
				d ..updateFromTemplate(.child)
				Set:child.class="" child.class=..class
				Set sc = child.%DrawToHTML(.context,.XSL,.delay)
				Quit:$$$ISERR(sc)
			}
			Set i = ..children.Next(i)
		}
		if (SubReport="") {
			if ..terminateIfEmpty {
				Do XSL.WriteLine("   </xsl:if>")
			}
		}

		If $$$ISERR(sc) Quit sc

		if (SubReport="") {
			Do XSL.WriteLine("</body></html>")
		}
		Do XSL.WriteLine("</xsl:template>")
		Do delay.Rewind()
		Do XSL.CopyFrom(delay)
		if (SubReport="") {
			Do ..%CopyReportPageXdata(.XSL,"CommonHtml") ; HTML Xdata
			d ..%CopyXsltXdata(.XSL,"AllXslt","HtmlXslt")
			; end
		}
		s sc=..GenerateInit(.context,.XSL, .delay,0)
		if $$$ISERR(sc) q sc

		if (SubReport="") {
			if 'embedXSL Do XSL.WriteLine("</xsl:stylesheet>")
		}
		if (SubReport'="") {
		}

		d ..%EndDrawHtml(.context,.XSL,.delay)

		Quit $$$OK
}

/// Outputs the standard stylesheet for HTML reports
Method %stdStyleSheetCSS(ByRef XSL As %GlobalCharacterStream) As %Status
{
	// match text-align with XSLFO/FOP default
	Do XSL.WriteLine("th {")
	Do XSL.WriteLine("   text-align:left")
	Do XSL.WriteLine("}")

	Do XSL.WriteLine("p.banner1 {")
	Do XSL.WriteLine("	color:darkblue;")
	Do XSL.WriteLine("	font-family:Arial;")
	Do XSL.WriteLine("	border-bottom:1px solid darkblue;")
	Do XSL.WriteLine("	font-size:24pt;")
	Do XSL.WriteLine("	font-weight:bold;")
	Do XSL.WriteLine("}")

	Do XSL.WriteLine("inline.banner1 {")
	Do XSL.WriteLine("	color:darkblue;")
	Do XSL.WriteLine("	font-family:Arial;")
	Do XSL.WriteLine("	border-bottom:1px solid darkblue;")
	Do XSL.WriteLine("	font-size:24pt;")
	Do XSL.WriteLine("	font-weight:bold;")
	Do XSL.WriteLine("}")

	Do XSL.WriteLine("table.table1 {")
	Do XSL.WriteLine("	border:none;")
	Do XSL.WriteLine("}")
	Do XSL.WriteLine("th.table1 {")
	Do XSL.WriteLine("	text-align:right;")
	Do XSL.WriteLine("	font-weight:bold;")
	Do XSL.WriteLine("}")
	Do XSL.WriteLine("td.table1 {")
	Do XSL.WriteLine("	text-align:left;")
	Do XSL.WriteLine("}")

	Do XSL.WriteLine("th.table2 {")
	Do XSL.WriteLine("	border:1px solid gray;")
	Do XSL.WriteLine("	text-align:left;")
	Do XSL.WriteLine("	background-color:#e0e0e0;")
	Do XSL.WriteLine("	font-weight:normal;")
	Do XSL.WriteLine("}")
	Do XSL.WriteLine("td.table2 {")
	Do XSL.WriteLine("	font-weight:bold;")
	Do XSL.WriteLine("	border:1px solid gray;")
	Do XSL.WriteLine("}")

	Do XSL.WriteLine("table.table3 {")
	Do XSL.WriteLine("    border:none;")
	Do XSL.WriteLine("}")
	Do XSL.WriteLine("th.table3 {")
	Do XSL.WriteLine("    border:none;")
	Do XSL.WriteLine("    text-align:left;")
	Do XSL.WriteLine("    font-weight:bold;")
	Do XSL.WriteLine("}")
	Do XSL.WriteLine("td.table3 {")
	Do XSL.WriteLine("    border:none;")
	Do XSL.WriteLine("    text-align:left;")
	Do XSL.WriteLine("    font-weight:normal;")
	Do XSL.WriteLine("}")

	Do XSL.WriteLine("table.table4 {")
	Do XSL.WriteLine("    border:1px solid gray;")
	Do XSL.WriteLine("}")
	Do XSL.WriteLine("th.table4 {")
	Do XSL.WriteLine("    border:none;")
	Do XSL.WriteLine("    color:white;")
	Do XSL.WriteLine("    background-color:#6f6fff;")
	Do XSL.WriteLine("    text-align:left;")
	Do XSL.WriteLine("    font-weight:bold;")
	Do XSL.WriteLine("}")
	Do XSL.WriteLine("td.table4 {")
	Do XSL.WriteLine("    border:none;")
	Do XSL.WriteLine("    text-align:left;")
	Do XSL.WriteLine("    font-weight:normal;")
	Do XSL.WriteLine("}")

	Do XSL.WriteLine("table.table5 {")
	Do XSL.WriteLine("    border:none;")
	Do XSL.WriteLine("}")
	Do XSL.WriteLine("th.table5 {")
	Do XSL.WriteLine("    border:none;")
	Do XSL.WriteLine("    text-align:left;")
	Do XSL.WriteLine("    font-weight:normal;")
	Do XSL.WriteLine("    background-color:#bbbbff;")
	Do XSL.WriteLine("    border-top:1.5px solid black;")
	Do XSL.WriteLine("    border-bottom:1.5px solid black;")
	Do XSL.WriteLine("}")
	Do XSL.WriteLine("td.table5 {")
	Do XSL.WriteLine("    border:none;")
	Do XSL.WriteLine("    text-align:left;")
	Do XSL.WriteLine("    font-weight:normal;")
	Do XSL.WriteLine("    line-height:150%;")
	Do XSL.WriteLine("}")

	Do XSL.WriteLine("table.grid {")
	Do XSL.WriteLine("    border:none;")
	Do XSL.WriteLine("}")
	Do XSL.WriteLine("th.grid {")
	Do XSL.WriteLine("    border:1px solid black;")
	Do XSL.WriteLine("    text-align:left;")
	Do XSL.WriteLine("    font-weight:bold;")
	Do XSL.WriteLine("}")
	Do XSL.WriteLine("td.grid {")
	Do XSL.WriteLine("    border:1px solid black;")
	Do XSL.WriteLine("    text-align:left;")
	Do XSL.WriteLine("    font-weight:normal;")
	Do XSL.WriteLine("}")

	Do XSL.WriteLine("table.invisible {")
	Do XSL.WriteLine("    border:none;")
	Do XSL.WriteLine("}")
	Do XSL.WriteLine("th.invisible {")
	Do XSL.WriteLine("    border:none;")
	Do XSL.WriteLine("    text-align:left;")
	Do XSL.WriteLine("}")
	Do XSL.WriteLine("td.invisible {")
	Do XSL.WriteLine("    border:none;")
	Do XSL.WriteLine("    text-align:left;")
	Do XSL.WriteLine("}")


	Do XSL.WriteLine("th.numeric {")
	Do XSL.WriteLine("	border:1px solid gray;")
	Do XSL.WriteLine("	text-align:right;")
	Do XSL.WriteLine("	background-color:#e0e0e0;")
	Do XSL.WriteLine("	font-weight:normal;")
	Do XSL.WriteLine("}")
	Do XSL.WriteLine("td.numeric {")
	Do XSL.WriteLine("	font-weight:bold;")
	Do XSL.WriteLine("	text-align:right;")
	Do XSL.WriteLine("	border:1px solid gray;")
	Do XSL.WriteLine("}")
}

/// Outputs the standard stylesheet for PDF reports
Method %stdStyleSheetFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream) As %Status
{
	Do XSL.WriteLine("<xsl:attribute-set name='p.banner1'>")
	Do XSL.WriteLine("	<xsl:attribute name='color'>darkblue</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='font-family'>Arial</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='border-bottom'>1pt solid darkblue</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='font-size'>24pt</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='font-weight'>bold</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Set context("class","p.banner1")=""

	Do XSL.WriteLine("<xsl:attribute-set name='inline.banner1'>")
	Do XSL.WriteLine("	<xsl:attribute name='color'>darkblue</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='font-family'>Arial</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='border-bottom'>1pt solid darkblue</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='font-size'>24pt</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='font-weight'>bold</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Set context("class","inline.banner1")=""

	Do XSL.WriteLine("<xsl:attribute-set name='table.table1'>")
	Do XSL.WriteLine("	<xsl:attribute name='border'>none</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='th.table1'>")
	Do XSL.WriteLine("	<xsl:attribute name='text-align'>right</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='font-weight'>bold</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='td.table1'>")
	//Do XSL.WriteLine("	<xsl:attribute name='padding-left'>1.0em</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='text-align'>left</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Set context("class","table.table1")=""
	Set context("class","th.table1")=""
	Set context("class","td.table1")=""

	Do XSL.WriteLine("<xsl:attribute-set name='table.table2'>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='th.table2'>")
	Do XSL.WriteLine("	<xsl:attribute name='border'>1pt solid gray</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='text-align'>left</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='background-color'>#e0e0e0</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='font-weight'>normal</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='td.table2'>")
	Do XSL.WriteLine("	<xsl:attribute name='font-weight'>bold</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='border'>1pt solid gray</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Set context("class","table.table2")=""
	Set context("class","th.table2")=""
	Set context("class","td.table2")=""

	Do XSL.WriteLine("<xsl:attribute-set name='table.table3'>")
	Do XSL.WriteLine("    <xsl:attribute name='border'>none</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='th.table3'>")
	Do XSL.WriteLine("    <xsl:attribute name='border'>none</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='text-align'>left</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='font-weight'>bold</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='td.table3'>")
	Do XSL.WriteLine("    <xsl:attribute name='border'>none</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='text-align'>left</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='font-weight'>normal</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Set context("class","table.table3")=""
	Set context("class","th.table3")=""
	Set context("class","td.table3")=""

	Do XSL.WriteLine("<xsl:attribute-set name='table.table4'>")
	Do XSL.WriteLine("    <xsl:attribute name='border'>1pt solid gray</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='th.table4'>")
	Do XSL.WriteLine("    <xsl:attribute name='border'>none</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='color'>white</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='background-color'>#6f6fff</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='text-align'>left</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='font-weight'>bold</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='td.table4'>")
	Do XSL.WriteLine("    <xsl:attribute name='border'>none</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='text-align'>left</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='font-weight'>normal</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Set context("class","table.table4")=""
	Set context("class","th.table4")=""
	Set context("class","td.table4")=""

	Do XSL.WriteLine("<xsl:attribute-set name='table.table5'>")
	Do XSL.WriteLine("    <xsl:attribute name='border'>none</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='th.table5'>")
	Do XSL.WriteLine("    <xsl:attribute name='border'>none</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='text-align'>left</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='font-weight'>normal</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='background-color'>#bbbbff</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='border-top'>1.5pt solid black</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='border-bottom'>1.5pt solid black</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='td.table5'>")
	Do XSL.WriteLine("    <xsl:attribute name='border'>none</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='text-align'>left</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='font-weight'>normal</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='line-height'>150%</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Set context("class","table.table5")=""
	Set context("class","th.table5")=""
	Set context("class","td.table5")=""

	Do XSL.WriteLine("<xsl:attribute-set name='table.grid'>")
	Do XSL.WriteLine("    <xsl:attribute name='border'>none</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='th.grid'>")
	Do XSL.WriteLine("    <xsl:attribute name='border'>1pt solid black</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='text-align'>left</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='font-weight'>bold</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='td.grid'>")
	Do XSL.WriteLine("    <xsl:attribute name='border'>1pt solid black</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='text-align'>left</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='font-weight'>normal</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Set context("class","table.grid")=""
	Set context("class","th.grid")=""
	Set context("class","td.grid")=""

	Do XSL.WriteLine("<xsl:attribute-set name='table.invisible'>")
	Do XSL.WriteLine("    <xsl:attribute name='border'>none</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='th.invisible'>")
	Do XSL.WriteLine("    <xsl:attribute name='border'>none</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='text-align'>left</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='td.invisible'>")
	Do XSL.WriteLine("    <xsl:attribute name='border'>none</xsl:attribute>")
	Do XSL.WriteLine("    <xsl:attribute name='text-align'>left</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Set context("class","table.invisible")=""
	Set context("class","th.invisible")=""
	Set context("class","td.invisible")=""

	Do XSL.WriteLine("<xsl:attribute-set name='table.numeric'>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='th.numeric'>")
	Do XSL.WriteLine("	<xsl:attribute name='text-align'>right</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='border'>1pt solid gray</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='text-align'>left</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='background-color'>#e0e0e0</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='font-weight'>normal</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Do XSL.WriteLine("<xsl:attribute-set name='td.numeric'>")
	Do XSL.WriteLine("	<xsl:attribute name='font-weight'>bold</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='border'>1pt solid gray</xsl:attribute>")
	Do XSL.WriteLine("	<xsl:attribute name='text-align'>right</xsl:attribute>")
	Do XSL.WriteLine("</xsl:attribute-set>")
	Set context("class","table.numeric")=""
	Set context("class","th.numeric")=""
	Set context("class","td.numeric")=""

	Quit $$$OK
}

ClassMethod processContext(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, children As %ZEN.Report.Display.childrenNode)
{
		Set i = children.Next("")
		While (i'="") {
			Set child=children.GetAt(i)
			d ..updateFromTemplate(.child)
			If child.class'="" {
				for j=1:1:$L(child.class," ") {
					Set class=$P(child.class," ",j)
					if child.tag="table" || (child.tag="list") {
						Do XSL.WriteLine("<xsl:attribute-set name='"_child.tag_"."_class_"'>")
						Do XSL.WriteLine("</xsl:attribute-set>")
						Do XSL.WriteLine("<xsl:attribute-set name='th."_class_"'>")
						Do XSL.WriteLine("</xsl:attribute-set>")
						Do XSL.WriteLine("<xsl:attribute-set name='td."_class_"'>")
						Do XSL.WriteLine("</xsl:attribute-set>")
						Set context("class",child.tag_"."_class_"")=""
						Set context("class","th."_class_"")=""
						Set context("class","td."_class_"")=""

					} elseif child.tag="p" {
						Do XSL.WriteLine("<xsl:attribute-set name='p."_class_"'>")
						Do XSL.WriteLine("</xsl:attribute-set>")
						Set context("class","p."_class_"")=""
					} elseif child.tag="th" {
						Do XSL.WriteLine("<xsl:attribute-set name='th."_class_"'>")
						Do XSL.WriteLine("</xsl:attribute-set>")
						Set context("class","th."_class_"")=""
					} elseif child.tag="td" {
						Do XSL.WriteLine("<xsl:attribute-set name='td."_class_"'>")
						Do XSL.WriteLine("</xsl:attribute-set>")
						Set context("class","td."_class_"")=""
					} elseif child.tag="tr" {
						Do XSL.WriteLine("<xsl:attribute-set name='tr."_class_"'>")
						Do XSL.WriteLine("</xsl:attribute-set>")
						Set context("class","tr."_class_"")=""
					} elseif child.tag="inline" {
						Do XSL.WriteLine("<xsl:attribute-set name='inline."_class_"'>")
						Do XSL.WriteLine("</xsl:attribute-set>")
						Set context("class","inline."_class_"")=""
					} elseif child.tag="block" {
						Do XSL.WriteLine("<xsl:attribute-set name='block."_class_"'>")
						Do XSL.WriteLine("</xsl:attribute-set>")
						Set context("class","block."_class_"")=""
					} elseif child.tag="div" {
						Do XSL.WriteLine("<xsl:attribute-set name='div."_class_"'>")
						Do XSL.WriteLine("</xsl:attribute-set>")
						Set context("class","div."_class_"")=""
					} elseif child.tag="link" {
						Do XSL.WriteLine("<xsl:attribute-set name='link."_class_"'>")
						Do XSL.WriteLine("</xsl:attribute-set>")
						Set context("class","link."_class_"")=""
					} elseif child.tag="item" {
						Do XSL.WriteLine("<xsl:attribute-set name='td."_class_"'>")
						Do XSL.WriteLine("</xsl:attribute-set>")
						Set context("class","td."_class_"")=""
					} elseif child.tag="summary" {
						Do XSL.WriteLine("<xsl:attribute-set name='td."_class_"'>")
						Do XSL.WriteLine("</xsl:attribute-set>")
						Set context("class","td."_class_"")=""
					} elseif child.tag="bidioverride" {
						Do XSL.WriteLine("<xsl:attribute-set name='bidioverride."_class_"'>")
						Do XSL.WriteLine("</xsl:attribute-set>")
						Set context("class","bidioverride."_class_"")=""
					} elseif child.tag="inlinecontainer" {
						Do XSL.WriteLine("<xsl:attribute-set name='inlinecontainer."_class_"'>")
						Do XSL.WriteLine("</xsl:attribute-set>")
						Set context("class","inlinecontainer."_class_"")=""
					}


				}

			}
			if child.%IsA("%ZEN.Report.Display.childrenNode") Set grandchildren=child.children do ..processContext(.context, .XSL, grandchildren)
			Set i = children.Next(i)
		}
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
		// remove orientation from pageheader and pagefooter 03-22-12
		// If (child.tag="pagefooter")||(child.tag="pageheader") {
		//	Set child.orientation=document.orientation
		// }
		Set i= children.Next(i)
	}
	quit document
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
			Set pagemaster=..GetPageMaster(this,.context,.XSL,this.children,this.xpath)
			Set sc=pagemaster.%DrawStyleToHTML(.context,.XSL,.delay) Quit:$$$ISERR(sc)
			Set masterArray("main")=pagemaster
		}
		Set i= children.Next(i)
	}
	Quit $$$OK
}

ClassMethod %CopyXsltXdata(ByRef XSL As %GlobalCharacterStream, AllTag As %String, XdataName As %String) [ Internal ]
{
	if (AllTag'="") {
		d ..%CopyReportPageXdata(.XSL,AllTag)
	}
	if (XdataName'="") {
		d ..%CopyReportPageXdata(.XSL,XdataName)
	}
}

ClassMethod %CopyReportPageXdata(ByRef XSL As %GlobalCharacterStream, XdataName As %String)
{
	do ##class(%ZEN.Report.Display.report).%CopyXdataFromClass(.XSL,XdataName,%context("OREF","this").%ClassName(1))
}

ClassMethod %CopyXdataFromClass(ByRef XSL As %GlobalCharacterStream, XdataName As %String, Classname As %String)
{
	Set me = ##class(%Dictionary.CompiledClass).%OpenId(Classname)
	if ($isObject(me)) {
		Set idx = me.XDatas.FindObjectId(Classname_"||"_XdataName)
		if (idx="") quit
		Set data = me.XDatas.GetAt(idx).Data
		if $isObject(data) {
			#; strip <zenxslt> and </zenxslt> tags
			Set stripped=##class(%GlobalCharacterStream).%New()

			Set chunksize=32000
			Do data.Rewind()
			While 'data.AtEnd {
				Set chunk=data.Read(chunksize)
				While $f(chunk,"<zenxslt>") || $f(chunk,"</zenxslt>") {
					if $f(chunk,"<zenxslt>") {
						Set beg=$f(chunk,"<zenxslt>")-$L("<zenxslt>")-1
						Set end=$f(chunk,"<zenxslt>",beg)
					} else {
						Set beg=$f(chunk,"</zenxslt>")-$L("</zenxslt>")-1
						Set end=$f(chunk,"</zenxslt>",beg)
					}
					Set chunk=$e(chunk,1,beg)_$e(chunk,end,$l(chunk))
				}
				Do stripped.Write(chunk)
			}


			Do stripped.Rewind()
			Do XSL.CopyFrom(stripped)
		}
	} else {
		Do ##class(%ZEN.Report.reportPage).%LogError(%objlasterror)
		Set ^%ISC.ZENREPORTLOG($ZDT($ZTS,3,,3)) = "Could not open "_Classname_"||"_XdataName
	}
}

Method GenerateInit(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream, isFO As %Boolean) As %Status
{
	s sc=$$$OK
	Set init=""
	Set i = ..children.Next("")
	While (i'="") {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)
		Set child.parent=##this
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

Method GenerateBookmarkTree(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
	s sc=$$$OK
	;Do XSL.WriteLine("<fo:bookmark-tree>")
	Set i = ..children.Next("")
	While (i'="") {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)
		Set child.parent=##this
		Set child.xpath=..parent.xpath
		if child.tag="bookmarkTree" {
			Do child.%DrawToXSLFO(.context,.XSL,.delay)
		}
		Set i= ..children.Next(i)
	}
	;Do XSL.WriteLine("</fo:bookmark-tree>")
	q sc
}

Method %DrawToAnnotatedXML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
	Set sc=$$$OK
	New %report,%name
	Set %report=%context("OREF","this")
	d ..tagChildren()
	Set xmlns=""
	if ((..xmlnamespaceprefix'="") && (..xmlnamespace'="")) {
		Set xmlns=" xmlns:"_..xmlnamespaceprefix_"='"_..xmlnamespace_"'"
	}

	Do XSL.WriteLine("<xsl:stylesheet version='"_%report.XsltVersion_"' ")
	Do XSL.WriteLine("   xmlns:xsl='http://www.w3.org/1999/XSL/Transform'")
	Do XSL.WriteLine("   xmlns:fo='http://www.w3.org/1999/XSL/Format'")
	Do XSL.WriteLine("   xmlns:xlink='http://www.w3.org/1999/xlink'")
	Do XSL.WriteLine("    xmlns:zr='http://www.intersystems.com/zenreports' xmlns:xs='http://www.w3.org/2001/XMLSchema' ")
	Do XSL.WriteLine("   xmlns:svg='http://www.w3.org/2000/svg'"_xmlns_$s(%report.NamespaceDeclarations="":"",1:" "_%report.NamespaceDeclarations)_">")
	Do XSL.WriteLine("   <xsl:output method='xml' version='1.0' indent='"_..Indent_"'"_$s(..Encoding'="":" encoding='"_..Encoding_"'",1:"")_"/>")
	if ..StripSpace'="" Do XSL.WriteLine("<xsl:strip-space elements="""_..StripSpace_"""/>")
	if ..PreserveSpace'="" Do XSL.WriteLine("<xsl:preserve-space elements="""_..PreserveSpace_"""/>")
	Set %name=..name
	if $e(%name)="!" {
		X "set %name="_$e(..name,2,$L(..name))
	}
	Set context("Name")=..qualify(%name)
	Do XSL.WriteLine("   <xsl:template match='/"_..qualify(%name)_"'>")
	Do XSL.WriteLine("      <"_..qualify(%name)_">")
	Set i = ..children.Next("")
	While (i'="") {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)
		Set:child.class="" child.class=..class
		Set sc = child.%DrawToAnnotatedXML(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i = ..children.Next(i)
	}
	Do XSL.WriteLine("      </"_..qualify(%name)_">")
	Do XSL.WriteLine("	 </xsl:template>")
	Do delay.Rewind()
	Do XSL.CopyFrom(delay)

	//Write Custom Templates To Excel Output As Well - Prodlog 134659
	d ..%CopyXsltXdata(.XSL,"AllXslt","")

	Do XSL.WriteLine("</xsl:stylesheet>")
	Quit sc
}

ClassMethod GetPageMaster(this, ByRef context As %String, ByRef XSL As %GlobalCharacterStream, children As %ZEN.Report.Display.childrenNode, xpath As %String) As pagemaster
{
	Set pagemaster=##class(%ZEN.Report.Display.pagemaster).%New()
	Set i = children.Next("")
	While (i'="") {
		Set child=children.GetAt(i)
		Set child.parent=this
		Set child.xpath=xpath
		If child.tag="pagemaster" {
			d ..updateFromTemplate(.child)
			Set pagemaster=child Quit
		}
		Set i= children.Next(i)
	}
	quit pagemaster
}

ClassMethod GetFirstSection(this, ByRef context As %String, ByRef XSL As %GlobalCharacterStream, children As %ZEN.Report.Display.childrenNode, xpath As %String) As pagemaster
{
	Set section=##class(%ZEN.Report.Display.section).%New()
	Set i = children.Next("")
	While (i'="") {
		Set child=children.GetAt(i)
		Set child.parent=this
		Set child.xpath=xpath
		If child.tag="section" {
			d ..updateFromTemplate(.child)
			Set section=child Quit
		}
		Set i= children.Next(i)
	}
	quit section
}

ClassMethod IsIE()
{
	Quit ($D(%session) && $isObject(%session) && (%session.BrowserName="IE"))
}

}
