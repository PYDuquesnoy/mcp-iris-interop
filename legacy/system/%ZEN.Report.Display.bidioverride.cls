/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.bidioverride Extends (childrenNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

/// direction attribute
Property direction As %ZEN.Datatype.string(VALUELIST = ",ltr,rtl,inherit");

/// unicode-bidi - attribute only relevant to XSL-FO
Property unicodeBIDI As %ZEN.Datatype.string(VALUELIST = ",normal,embed,bidi-override,inherit", XMLNAME = "unicode-bidi");

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawHtml(.context,.XSL,.delay)	
	Set sc=$$$OK
	d ..tagChildren()
	Set i = ..children.Next("")
	Do XSL.WriteLine("<bdo"_$s(..direction'="":" dir='"_..direction_"'", 1:"")_">") 
	if 'incell $$$stylehtml
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
	Do XSL.WriteLine("</bdo>")
	d ..%EndDrawHtml(.context,.XSL,.delay)	
	Quit sc
}

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Set sc=$$$OK
	d ..tagChildren()
	Do XSL.WriteLine("<fo:bidi-override"_$$$applyclass("bidioverride",.context)_$s(..direction'="":" direction='"_..direction_"'", 1:"")_$s(..unicodeBIDI'="":" unicode-bidi='"_..unicodeBIDI_"'", 1:"")_">") 
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
	Do XSL.WriteLine("</fo:bidi-override>")
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit sc
}

}
