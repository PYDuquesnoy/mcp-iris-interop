/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Specifies the section of the report display that will be used as the body
/// of the report.
Class %ZEN.Report.Display.body Extends category [ Deprecated, System = 4 ]
{

Property foStyle As %ZEN.Datatype.string;

/// Boolean flag to block lst page reference creation 
Property blockZENLastPage As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

/// XPath value to use when generating the last page reference<br>
/// Would normally be used in coordination with an item special that includes an xpath, for instance,
/// <item style="text-align:right" special="page-number-of-with-xpath" field="SalesRep/@name"   />
Property genLastPageIdOn As %ZEN.Datatype.string;

/// Append group id to %ZENLastPage for uniqueness<br>
/// id of body is appended.  Unlike genLastPageIdOn does not use xpath.
Property appendIdToZenLastPage As %ZEN.Datatype.boolean [ InitialExpression = 0 ];

Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream, ByRef incell As %Boolean = 0) As %Status
{
	d ..%BeginDrawFo(.context,.XSL,.delay)
	Set sc = $$$OK
	if context("SubReport")="" {
		Do XSL.WriteLine("<fo:flow flow-name='xsl-region-body'"_$s(..foStyle'="":" "_..foStyle,1:"")_">")
		Do XSL.WriteLine("  <fo:block>")
		Do XSL.WriteLine("<xsl:variable name='level0' select='position()'/>")
	}
	d ..tagChildren()	
	Set i = ..children.Next("")
	While (i'="") {
		Set child = ..children.GetAt(i)
		Set child.parent=$$$THIS
		Set child.xpath=..parent.xpath
		Set:child.class="" child.class=..class
		d ..updateFromTemplate(.child)
		Set sc = child.%DrawToXSLFO(.context,.XSL,.delay)
		Quit:$$$ISERR(sc)
		Set i= ..children.Next(i)
	}
	if context("SubReport")="" {
		Do XSL.WriteLine("  </fo:block>")
		If '..blockZENLastPage {
			If ..genLastPageIdOn = "" {
				// Proposed Enhancement Begin
				If '..appendIdToZenLastPage {
					if context("primaryGroup")'="" {
						Do XSL.WriteLine("<fo:block id='{generate-id(.)}'/>")
					} else {
						Do XSL.WriteLine("<fo:block id='%ZENLastPage'/>")
					}
				} Else {
					Do XSL.WriteLine("<fo:block id='%ZENLastPage"_..id_"'/>")
				}
				// Proposed Enhancement End
			} Else {
				Do XSL.WriteLine("<fo:block id='{generate-id("_..genLastPageIdOn_")}'/>")
			}
		}	
		Do XSL.WriteLine("</fo:flow>")
	}
	d ..%EndDrawFo(.context,.XSL,.delay)		
	Quit sc
}

}
