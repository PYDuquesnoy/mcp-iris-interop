/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.container Extends (childrenNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

Property backgroundImage As %ZEN.Datatype.string;

Property width As %ZEN.Datatype.length;

Property height As %ZEN.Datatype.length;

Property backgroundRepeat As %ZEN.Datatype.string;

Property position As %ZEN.Datatype.string;

/// writing-mode XML attribute.  It has the following possible values.  Note that not all XSL-FO renderers will support all possible values. <br>
/// lr-tb Text are written left-to-right and top-to-bottom (normal "alphabetic" text) <br>
/// rl-tb Text are written right-to-left and top-to-bottom (Arabic and Hebrew text) <br>
/// tb-rl Text are written top-to-bottom and right-to-left (Chinese and Japanese text) <br>
/// lr Same as lr-tb <br>
/// rl Same as rl-tb <br>
/// tb Same as tb-rl <br>
/// inherit <br>
Property writingMode As %ZEN.Datatype.string(VALUELIST = ",lr-tb,rl-tb,tb-rl,lr,rl,tb,inherit", XMLNAME = "writing-mode");

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)
	Set sc=$$$OK
	d ..tagChildren()
	Do XSL.Write("<div") 
	if ..style="" {
		set sep=""
	}
	else {
		set sep=";"
	}
	if ..height'="" Set ..style=..style_sep_"height:"_..height Set sep=";"
	if ..width'="" Set ..style=..style_sep_"width:"_..width Set sep=";"
	if ..backgroundRepeat'="" Set ..style=..style_sep_"background-repeat:"_..backgroundRepeat Set sep=";"
	If ..position="textual" Set position="relative"
	else  Set position=..position
	if position'="" Set ..style=..style_sep_"position:"_position Set sep=";"
	Do XSL.WriteLine(">") 
	If 'incell Do ..%StyleHTML(.context,.XSL,.delay,..backgroundImage)
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
	Do XSL.WriteLine("</div>")
	d ..%EndDrawHtml(.context,.XSL,.delay)		
	Quit sc
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Set sc=$$$OK
	d ..tagChildren()
	Do XSL.Write("<fo:block-container")
	if ..backgroundImage'="" {
		If $e(..backgroundImage)="!" {
			Set src="url(<xsl:value-of select='"_$e(..backgroundImage,2,$l(..backgroundImage))_"'/>)"
		} Else {
			Set src="url('"_..%GetAbsoluteURL(..backgroundImage,.context)_"')"
		}
	}
	if ..blockContainerProperty'="" Do XSL.Write(" "_..blockContainerProperty) 
	if ..height'="" Do XSL.Write(" height='"_..height_"'")
	if ..width'="" Do XSL.Write(" width='"_..width_"'")
	if ..backgroundRepeat'="" Do XSL.Write(" background-repeat='"_..backgroundRepeat_"'")
	If ..position="textual" Set position="absolute"
	else  Set position=..position
	if position'="" Do XSL.Write(" absolute-position='"_position_"'")
	Do XSL.WriteLine($s(..writingMode'="":" writing-mode='"_..writingMode_"'",1:"")_">") 
	if ..backgroundImage'="" {
		Do XSL.Write("<xsl:attribute name='background-image'>")
		Do XSL.Write(src)
		Do XSL.Write("</xsl:attribute>")
		Do XSL.WriteLine("")
	}
	If 'incell $$$stylefo
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
	Do XSL.WriteLine("</fo:block-container>")
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit sc
}

Storage Default
{
<Data name="containerDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%ZEN.Report.Dis6C0.containerD</DataLocation>
<DefaultData>containerDefaultData</DefaultData>
<IdLocation>^%ZEN.Report.Dis6C0.containerD</IdLocation>
<IndexLocation>^%ZEN.Report.Dis6C0.containerI</IndexLocation>
<StreamLocation>^%ZEN.Report.Dis6C0.containerS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
