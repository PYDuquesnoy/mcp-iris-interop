/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The &lt;document&gt; tag is used at the top-level to specify dimensions and
/// styling for the report. The dimensions only affect the PDF report.
Class %ZEN.Report.Display.document Extends childrenNode [ Deprecated, System = 4 ]
{

/// Specifies the height of the document.
Property height As %ZEN.Datatype.length [ InitialExpression = "11in" ];

/// Specifies the width of the document.
Property width As %ZEN.Datatype.length [ InitialExpression = "8.5in" ];

/// Specifies the left margin width of the document.
Property marginLeft As %ZEN.Datatype.length [ InitialExpression = "1.25in" ];

/// Specifies the right margin width of the document.
Property marginRight As %ZEN.Datatype.length [ InitialExpression = "1.25in" ];

/// Specifies the top margin of the document. This does not include the
/// space left for the header.
Property marginTop As %ZEN.Datatype.length [ InitialExpression = "1in" ];

/// Specifies the bottom margin of the document. This does not include the
/// space left for the footer.
Property marginBottom As %ZEN.Datatype.length [ InitialExpression = "1in" ];

/// Specifies the amount of room available for the contents of the &lt;pageheader&gt; tag.
Property headerHeight As %ZEN.Datatype.length [ InitialExpression = "0" ];

/// Specifies the amount of room available for the contents of the &lt;pagefooter&gt; tag.
Property footerHeight As %ZEN.Datatype.length [ InitialExpression = "0" ];

/// Specifies the amount of room available for the contents of the &lt;pagestartsidebar&gt; tag.
Property startSidebarLength As %ZEN.Datatype.length [ InitialExpression = "0" ];

/// Specifies the amount of room available for the contents of the &lt;endsidebar&gt; tag.
Property endSidebarLength As %ZEN.Datatype.length [ InitialExpression = "0" ];

/// value of reference-orientation in XSL-FO region-body
Property referenceOrientation As %ZEN.Datatype.integer;

/// size attribute on fo:simple-page-master
Property size As %ZEN.Datatype.string;

/// margin attribute on fo:simple-page-master
Property margin As %ZEN.Datatype.string;

Property ifxpath As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property ifexpression As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

/// Properties of fo:region-before
Property regionBefore As %ZEN.Datatype.string;

/// Properties of fo:region-after
Property regionAfter As %ZEN.Datatype.string;

/// Properties of fo:region-start
Property regionStart As %ZEN.Datatype.string;

/// Properties of fo:region-end
Property regionEnd As %ZEN.Datatype.string;

/// extent property 
Property regionBeforeExtent As %ZEN.Datatype.string;

/// extent property 
Property regionAfterExtent As %ZEN.Datatype.string;

/// extent property 
Property regionStartExtent As %ZEN.Datatype.string;

/// extent property 
Property regionEndExtent As %ZEN.Datatype.string;

/// orientation property 
Property regionStartOrientation As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// orientation property 
Property regionEndOrientation As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// orientation property 
Property regionBeforeOrientation As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// orientation property 
Property regionAfterOrientation As %ZEN.Datatype.integer [ InitialExpression = 0 ];

/// display-align property 
Property regionBeforeDisplayAlign As %ZEN.Datatype.string [ InitialExpression = "inherit" ];

/// display-align property 
Property regionAfterDisplayAlign As %ZEN.Datatype.string [ InitialExpression = "after" ];

Property regionAfterColor As %ZEN.Datatype.string;

Property regionBeforeColor As %ZEN.Datatype.string;

/// extent property 
Property orientation As %ZEN.Datatype.string(VALUELIST = ",portrait,landscape,none") [ InitialExpression = "portrait" ];

Property regionAfterName As %ZEN.Datatype.string;

Property regionBeforeName As %ZEN.Datatype.string;

/// display-align property 
Property regionStartDisplayAlign As %ZEN.Datatype.string [ InitialExpression = "inherit" ];

/// display-align property 
Property regionEndDisplayAlign As %ZEN.Datatype.string [ InitialExpression = "after" ];

Property regionEndColor As %ZEN.Datatype.string;

Property regionStartColor As %ZEN.Datatype.string;

/// extent property 
Property regionStartName As %ZEN.Datatype.string;

Property regionEndName As %ZEN.Datatype.string;

/// This is a list of attributes in XSL format: 'a1=v1 a2=v2, etc., with a terminating single quote or a double double quote
Property endGeneralRegionAttributes As %ZEN.Datatype.string;

/// This is a list of attributes in XSL format: 'a1=v1 a2=v2, etc., with a terminating single quote or a double double quote
Property startGeneralRegionAttributes As %ZEN.Datatype.string;

/// This is a list of attributes in XSL format: 'a1=v1 a2=v2, etc., with a terminating single quote or a double double quote
Property beforeGeneralRegionAttributes As %ZEN.Datatype.string;

/// This is a list of attributes in XSL format: 'a1=v1 a2=v2, etc., with a terminating single quote or a double double quote
Property afterGeneralRegionAttributes As %ZEN.Datatype.string;

/// writing-mode XML attribute.  It has the following possible values.  Note that not all XSL-FO renderers will support all possible values. <br>
/// lr-tb Text are written left-to-right and top-to-bottom (normal "alphabetic" text) <br>
/// rl-tb Text are written right-to-left and top-to-bottom (Arabic and Hebrew text) <br>
/// tb-rl Text are written top-to-bottom and right-to-left (Chinese and Japanese text) <br>
/// lr Same as lr-tb <br>
/// rl Same as rl-tb <br>
/// tb Same as tb-rl <br>
/// inherit <br>
/// Note this places a writing-mode on fo:simple-page-master.<br>
/// The semantics of writing-mode on simple-page-master differs from page-sequence. Specifically, on simple-page-master, it is used to interpret the meaning of before, after, start, end with respect to resolving the placement of page regions. However, it does not affect the writing-mode trait of reference areas generated by page-sequence. In the latter case, it is the writing-mode on page-sequence that counts.<br>
/// To place a writing-mode on page-sequence use the writing-mode in the report or section element<br>
Property writingMode As %ZEN.Datatype.string(VALUELIST = ",lr-tb,rl-tb,tb-rl,lr,rl,tb,inherit", XMLNAME = "writing-mode");

/// writing-mode XML attribute on the region-body.  It has the following possible values.  Note that not all XSL-FO renderers will support all possible values. <br>
/// lr-tb Text are written left-to-right and top-to-bottom (normal "alphabetic" text) <br>
/// rl-tb Text are written right-to-left and top-to-bottom (Arabic and Hebrew text) <br>
/// tb-rl Text are written top-to-bottom and right-to-left (Chinese and Japanese text) <br>
/// lr Same as lr-tb <br>
/// rl Same as rl-tb <br>
/// tb Same as tb-rl <br>
/// inherit <br>
Property writingModeRegionBody As %ZEN.Datatype.string(VALUELIST = ",lr-tb,rl-tb,tb-rl,lr,rl,tb,inherit", XMLNAME = "writing-mode-region-body");

/// writing-mode XML attribute on the region-after.  It has the following possible values.  Note that not all XSL-FO renderers will support all possible values. <br>
/// lr-tb Text are written left-to-right and top-to-bottom (normal "alphabetic" text) <br>
/// rl-tb Text are written right-to-left and top-to-bottom (Arabic and Hebrew text) <br>
/// tb-rl Text are written top-to-bottom and right-to-left (Chinese and Japanese text) <br>
/// lr Same as lr-tb <br>
/// rl Same as rl-tb <br>
/// tb Same as tb-rl <br>
/// inherit <br>
Property writingModeRegionAfter As %ZEN.Datatype.string(VALUELIST = ",lr-tb,rl-tb,tb-rl,lr,rl,tb,inherit", XMLNAME = "writing-mode-region-after");

/// writing-mode XML attribute on the region-before.  It has the following possible values.  Note that not all XSL-FO renderers will support all possible values. <br>
/// lr-tb Text are written left-to-right and top-to-bottom (normal "alphabetic" text) <br>
/// rl-tb Text are written right-to-left and top-to-bottom (Arabic and Hebrew text) <br>
/// tb-rl Text are written top-to-bottom and right-to-left (Chinese and Japanese text) <br>
/// lr Same as lr-tb <br>
/// rl Same as rl-tb <br>
/// tb Same as tb-rl <br>
/// inherit <br>
Property writingModeRegionBefore As %ZEN.Datatype.string(VALUELIST = ",lr-tb,rl-tb,tb-rl,lr,rl,tb,inherit", XMLNAME = "writing-mode-region-before");

/// writing-mode XML attribute on the region-start.  It has the following possible values.  Note that not all XSL-FO renderers will support all possible values. <br>
/// lr-tb Text are written left-to-right and top-to-bottom (normal "alphabetic" text) <br>
/// rl-tb Text are written right-to-left and top-to-bottom (Arabic and Hebrew text) <br>
/// tb-rl Text are written top-to-bottom and right-to-left (Chinese and Japanese text) <br>
/// lr Same as lr-tb <br>
/// rl Same as rl-tb <br>
/// tb Same as tb-rl <br>
/// inherit <br>
Property writingModeRegionStart As %ZEN.Datatype.string(VALUELIST = ",lr-tb,rl-tb,tb-rl,lr,rl,tb,inherit", XMLNAME = "writing-mode-region-start");

/// writing-mode XML attribute on the region-end.  It has the following possible values.  Note that not all XSL-FO renderers will support all possible values. <br>
/// lr-tb Text are written left-to-right and top-to-bottom (normal "alphabetic" text) <br>
/// rl-tb Text are written right-to-left and top-to-bottom (Arabic and Hebrew text) <br>
/// tb-rl Text are written top-to-bottom and right-to-left (Chinese and Japanese text) <br>
/// lr Same as lr-tb <br>
/// rl Same as rl-tb <br>
/// tb Same as tb-rl <br>
/// inherit <br>
Property writingModeRegionEnd As %ZEN.Datatype.string(VALUELIST = ",lr-tb,rl-tb,tb-rl,lr,rl,tb,inherit", XMLNAME = "writing-mode-region-end");

/// specifies that the fo:region-body is multicolumn.  The column-count property indicates the number of columns on every page instance formatted using the simple-page-master
/// to which this region-body belongs.
Property columnCount As %ZEN.Datatype.integer(XMLNAME = "column-count");

/// If column-count is greater than 1, a value may be specified for the column-gap property.  The value is either an explicit length or a percentage
/// of the inline-progression-dimension of the content rectangle of the region-body.
Property columnGap As %ZEN.Datatype.length(XMLNAME = "column-gap");

/// Renders the dimensions of the page for a PDF report.Proposed change - add "masterName" parameter with default value "main"
Method %DrawPageToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, masterName As %String = "main") As %Status
{
	if ..orientation="portrait" {
		Set:..referenceOrientation="" ..referenceOrientation=0
		Set ..regionAfterOrientation=0 // JSL4430
		Set ..regionBeforeOrientation=0 // JSL4430
	}
	if ..orientation="landscape" {
		Set:..referenceOrientation="" ..referenceOrientation=90
		Set ..regionAfterOrientation=90 // JSL4430
		Set ..regionBeforeOrientation=90 // JSL4430

	}
	// Proposed Change - Begin
	;Do XSL.WriteLine("           <fo:simple-page-master master-name='main'")
	Do XSL.WriteLine("           <fo:simple-page-master master-name='"_masterName_"'"_$s(..writingMode'="":" writing-mode='"_..writingMode_"'",1:""))
	// Proposed Change - End
	if ..size'="" Do XSL.WriteLine("            size='"_..size_"'")
	if ..margin="" Do XSL.WriteLine("            margin-right='"_..marginRight_"'")
	if ..margin="" Do XSL.WriteLine("            margin-left='"_..marginLeft_"'")
	if ..margin="" Do XSL.WriteLine("            margin-top='"_..marginTop_"'")
	if ..margin="" Do XSL.WriteLine("            margin-bottom='"_..marginBottom_"'")
	if ..margin'="" Do XSL.WriteLine("            margin='"_..margin_"'")
	Do XSL.WriteLine("            reference-orientation='"_..referenceOrientation_"'")
	Do XSL.WriteLine("            page-width='"_..width_"' page-height='"_..height_"'>")
	Do XSL.WriteLine("             <fo:region-body margin-bottom='"_..footerHeight_"' margin-top='"_..headerHeight_"' margin-left='"_..startSidebarLength_"' margin-right='"_..endSidebarLength_"'"_$s(..writingModeRegionBody'="":" writing-mode='"_..writingModeRegionBody_"'",1:"")_$s(..columnCount'="":" column-count='"_..columnCount_"'",1:"")_$s(..columnGap'="":" column-gap='"_..columnGap_"'",1:"")_"/>")
	;if ..referenceOrientation="" 
	;if ..orientation="portrait" Do XSL.WriteLine("             <fo:region-body margin-bottom='"_..footerHeight_"' margin-top='"_..headerHeight_"' reference-orientation='"_..referenceOrientation_"'/>")
	;if ..orientation="landscape" Do XSL.WriteLine("             <fo:region-body margin-bottom='"_..footerHeight_"' margin-top='"_..headerHeight_"' reference-orientation='"_..referenceOrientation_"'/>")
	;if ..orientation="landscape" Do XSL.WriteLine("             <fo:region-body margin-bottom='"_..marginLeft_"' margin-top='"_..marginRight_"' margin-right='"_..footerHeight_"' margin-left='"_..headerHeight_"' reference-orientation='"_..referenceOrientation_"'/>")
	if (..orientation="landscape") {
		// try to calculate extents
		Set marginsum=""
		if ((..regionBeforeExtent="")||(..regionAfterExtent="")) {
			if (..margin'="") {
				Set marginlength = ..toMilimeters(..margin)
				if (marginlength'="") {
					Set marginsum = 2 * marginlength
				} 
			}
			else {
				Set marginlength1 = ..toMilimeters(..marginBottom)
				Set marginlength2 = ..toMilimeters(..marginTop)
				if (marginlength1'="" && marginlength2'="") {
					Set marginsum = marginlength1 + marginlength2
				}
			}
			Set heightmm=..toMilimeters(..height)
			;if ..regionBeforeExtent="",heightmm'="",marginsum'="" {
			;	Set ..regionBeforeExtent = (heightmm-marginsum)_"mm"
			;}
			;if ..regionAfterExtent="",heightmm'="",marginsum'="" {
			;	Set ..regionAfterExtent = (heightmm-marginsum)_"mm"
			;}
			;if ..regionBeforeExtent="",heightmm'="",marginsum'="" {
			;	Set ..regionBeforeExtent = ..headerHeight
			;}
			;if ..regionAfterExtent="",heightmm'="",marginsum'="" {
			;	Set ..regionAfterExtent = ..footerHeight
			;}

	}
		
	}
	;if ..orientation="landscape" if ..regionBeforeExtent="" quit $$$ERROR($$$GeneralError,"In landscape mode set ..regionBeforeExtent to the difference between the height and both the top and bottom margin")
	;if ..orientation="landscape" if ..regionAfterExtent="" quit $$$ERROR($$$GeneralError,"In landscape mode set ..regionAfterExtent to the difference between the height and both the top and bottom margin")
	Set:..regionBeforeExtent="" ..regionBeforeExtent="0.0pt"
	Set:..regionAfterExtent="" ..regionAfterExtent="0.0pt"
	Do XSL.Write("<fo:region-before"_$s(..regionBefore'="":" "_..regionBefore_" ",1:"")_" extent='"_..regionBeforeExtent_"' reference-orientation='"_..regionBeforeOrientation_"' display-align='"_..regionBeforeDisplayAlign_"'"_$s(..regionBeforeColor'="":"  background-color='"_..regionBeforeColor_"'",1:"")_$s(..writingModeRegionBefore'="":" writing-mode='"_..writingModeRegionBefore_"'",1:"")_$s(..beforeGeneralRegionAttributes'="":" "_..beforeGeneralRegionAttributes,1:"")_" ")		
	If ..regionBeforeName '= "" {
		Do XSL.Write("region-name='"_..regionBeforeName_"'")
	}
	Do XSL.WriteLine("/>")
	Do XSL.Write("<fo:region-after"_$s(..regionAfter'="":" "_..regionAfter,1:"")_" extent='"_..regionAfterExtent_"' reference-orientation='"_..regionAfterOrientation_"' display-align='"_..regionAfterDisplayAlign_"'"_$s(..regionAfterColor'="":"  background-color='"_..regionAfterColor_"'",1:"")_$s(..writingModeRegionAfter'="":" writing-mode='"_..writingModeRegionAfter_"'",1:"")_$s(..afterGeneralRegionAttributes'="":" "_..afterGeneralRegionAttributes,1:"")_" ")
	If ..regionAfterName '= "" {
		Do XSL.Write("region-name='"_..regionAfterName_"'")
	}
	Do XSL.WriteLine("/>")

	// region-start and region-end
	
	Set:..regionStartExtent="" ..regionStartExtent="0.0pt"
	Set:..regionEndExtent="" ..regionEndExtent="0.0pt"
	Do XSL.Write("<fo:region-start"_$s(..regionStart'="":" "_..regionStart,1:"")_" extent='"_..regionStartExtent_"' reference-orientation='"_..regionStartOrientation_"' display-align='"_..regionStartDisplayAlign_"'"_$s(..regionStartColor'="":"  background-color='"_..regionStartColor_"'",1:"")_$s(..writingModeRegionStart'="":" writing-mode='"_..writingModeRegionStart_"'",1:"")_$s(..startGeneralRegionAttributes'="":" "_..startGeneralRegionAttributes,1:"")_" ")
	If ..regionStartName '= "" {
		Do XSL.Write("region-name='"_..regionStartName_"'")
	}
	Do XSL.WriteLine("/>")
	Do XSL.Write("<fo:region-end"_$s(..regionEnd'="":" "_..regionEnd,1:"")_" extent='"_..regionEndExtent_"' reference-orientation='"_..regionEndOrientation_"' display-align='"_..regionEndDisplayAlign_"'"_$s(..regionEndColor'="":"  background-color='"_..regionEndColor_"'",1:"")_$s(..writingModeRegionEnd'="":" writing-mode='"_..writingModeRegionEnd_"'",1:"")_$s(..endGeneralRegionAttributes'="":" "_..endGeneralRegionAttributes,1:"")_" ")
	If ..regionEndName '= "" {
		Do XSL.Write("region-name='"_..regionEndName_"'")
	}
	Do XSL.WriteLine("/>")
	
	Do XSL.WriteLine("            </fo:simple-page-master>")
	Quit $$$OK
}

/// Outputs the style information contained in its &lt;class&gt; children
/// for a PDF report.
Method %DrawStyleToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, SectionName As %String = "") As %Status
{
	#; Generate attribute sets from classes
	Set sc=$$$OK
	d ..tagChildren()	
	Set attsets=##class(%Stream.GlobalCharacter).%New()
	Set includes=##class(%Stream.GlobalCharacter).%New()
	
	Set i=..children.Next("")
	While i'="" {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		If child.tag="class" {
			Set sc=child.%DrawToXSLFO(.context,.attsets,.delay)
		} ElseIf child.tag="xslinclude" {
			Set sc=child.%DrawToXSLFO(.context,.includes,.delay)
		} ElseIf (child.tag="template") {
			Set sc=child.%DrawToXSLFO(.context,.attsets,.delay)
		} ElseIf child.%Extends("%ZEN.Report.Display.composite") {
			Set sc=child.%DrawToXSLFO(.context,.attsets,.delay)
		}

		Quit:$$$ISERR(sc)
		Set i=..children.Next(i)
	}
	Do XSL.CopyFrom(includes)
	Do XSL.CopyFrom(attsets)
	Quit sc
}

/// Outputs the style information contained in its &lt;class&gt; children
/// for an HTML report.
Method %DrawStyleToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	#; Generate attribute sets from classes
	Set sc=$$$OK
	d ..tagChildren()
	Set CSS=##class(%Stream.GlobalCharacter).%New()
	Set includes=##class(%Stream.GlobalCharacter).%New()

	Set i=..children.Next("")
	While i'="" {
		Set child=..children.GetAt(i)
		d ..updateFromTemplate(.child)		
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		If child.tag="class" {
			Set sc=child.%DrawToHTML(.context,.CSS,.delay)
		} ElseIf child.tag="cssinclude" {
			Set sc=child.%DrawToHTML(.context,.includes,.delay)
		} ElseIf child.tag="template" {
			Set sc=child.%DrawToHTML(.context,.CSS,.delay)
		} ElseIf child.%Extends("%ZEN.Report.Display.composite") {
			Set sc=child.%DrawToHTML(.context,.CSS,.delay)
		}
		Quit:$$$ISERR(sc)
		Set i=..children.Next(i)
	}

	Do XSL.CopyFrom(includes)
	// we must not generate style tag if CSS is empty because Microsoft Explorer
	// has problem with SAXON output of empty style tags as <style type='text/css'/>
	if (CSS.SizeGet()'=0) {
		Do XSL.WriteLine("<style type='text/css'>")
		Do XSL.CopyFrom(CSS)
		Do XSL.WriteLine("</style>")
	}

	Quit sc
}

ClassMethod toMilimeters(length As %String) As %String
{
	// A <number> followed by length units.  Length units are pt, pc in, cm, mm, px, em 
	// (points, picas, inches, centimeters, milimeters, pixels and em-box size)
	Set suffix = $e(length,$L(length)-1,$L(length)) // last two characters
	Set num=$e(length,1,$L(length)-2)
	Set result=$s(suffix="pt":num*127.0/360.0,suffix="pc":num*12.0*127.0/360.0,suffix="in":num*25.4,suffix="cm":10.0*num,suffix="mm":num,suffix="px":"",suffix="em":"",1:"")
	Quit result
}

}
