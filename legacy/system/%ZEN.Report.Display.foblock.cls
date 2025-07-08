/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %ZEN.Report.Display.foblock Extends (childrenNode, tableOutput) [ Deprecated, Inheritance = right, System = 4 ]
{

Property field As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property group As %ZEN.Datatype.string(XMLPROJECTION = "NONE");

Property removeEmpty As %ZEN.Datatype.boolean(XMLPROJECTION = "NONE") [ InitialExpression = 0 ];

Property backgroundImage As %ZEN.Datatype.string;

Property width As %ZEN.Datatype.length;

Property height As %ZEN.Datatype.length;

Property top As %ZEN.Datatype.length;

Property left As %ZEN.Datatype.length;

Property right As %ZEN.Datatype.length;

Property bottom As %ZEN.Datatype.length;

Property relativePosition As %ZEN.Datatype.string;

/// keep together on next page if possible
Property keepCondition As %ZEN.Datatype.string;

Method %DrawToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, incell As %Boolean = 0) As %Status
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

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Set sc=$$$OK
	d ..tagChildren()
	Do XSL.Write("<fo:block") 
	if ..height'="" Do XSL.Write(" height='"_..height_"'")
	if ..width'="" Do XSL.Write(" width='"_..width_"'")
	if ..relativePosition'="" Do XSL.Write(" relative-position='"_..relativePosition_"'")
	if ..top'="" Do XSL.Write(" top='"_..top_"'")
	if ..left'="" Do XSL.Write(" left='"_..left_"'")
	if ..right'="" Do XSL.Write(" right='"_..right_"'")
	if ..bottom'="" Do XSL.Write(" bottom='"_..bottom_"'")
	if ..keepCondition'="" D XSL.Write(" "_..keepCondition)

	if ..backgroundImage'="" {
		If $e(..backgroundImage)="!" {
			Set src="<xsl:value-of select='"_$e(..backgroundImage,2,$l(..backgroundImage))_"'/>"
		} Else {
			Set src="'url("_..%GetAbsoluteURL(..backgroundImage,.context)_")'"
		}
		Do XSL.Write(" background-image="_src)
	}
	Do XSL.WriteLine(">") 
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
	Do XSL.WriteLine("</fo:block>")
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit sc
}

Storage Default
{
<Data name="foblockDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^%ZEN.Report.Display.foblockD</DataLocation>
<DefaultData>foblockDefaultData</DefaultData>
<IdLocation>^%ZEN.Report.Display.foblockD</IdLocation>
<IndexLocation>^%ZEN.Report.Display.foblockI</IndexLocation>
<StreamLocation>^%ZEN.Report.Display.foblockS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
