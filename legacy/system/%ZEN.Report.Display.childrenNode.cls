/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// The base class is for nodes that want their children tags rendered
/// as objects and not as content text.
Class %ZEN.Report.Display.childrenNode Extends node [ Abstract, Deprecated, System = 4 ]
{

Property parent As %ZEN.Report.Display.node(XMLPROJECTION = "NONE");

Property xpath As %String(XMLPROJECTION = "NONE");

Property children As list Of %ZEN.Report.Display.node(XMLELEMENTREF = 1, XMLPROJECTION = "ELEMENT", XMLTYPECONSTRAINT = "CHOICE");

/// Loop over children and recursively see if one contains chart
Method %ContainsChart(ByRef containsChart As %Boolean) [ Internal ]
{
	s containsChart=0
	#; gather children into *buckets* according to type
	#; loop over children
	Set i = ..children.Next("")
	While ((i'="")&&(containsChart=0)) {
		Set child = ..children.GetAt(i)
		if ($$$ClassPackageName(child.%ClassName(1))="%ZEN.Report.Display.Chart")||($$$ClassPackageName(child.%ClassName(1))="%ZEN.Report.Display.COSChart") {
			Set containsChart=1 
		} else {
			if child.%Extends("%ZEN.Report.Display.childrenNode") d child.%ContainsChart(.containsChart)
			Set i=..children.Next(i)
		}
	}
}

Method %DrawStyleToHTML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, SectionName As %String = "") As %Status
{
	Quit $$$OK
}

Method %DrawToAnnotatedXML(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, ByRef delay As %GlobalCharacterStream) As %Status
{
	Set tSC=$$$OK
	d ..tagChildren()
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		d ..updateFromTemplate(.child)	
		Set child.parent=##this
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		if child.tag'="caption" Set sc = child.%DrawToAnnotatedXML(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
		
	}
	quit tSC
}

}
