/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <Class>bookmark</Class>
/// The book formatting object is used to identify an access point, by name, and to specify where that access point is within the current document or another external document. A given bookmark may be further subdivided into a sequence of (sub-)bookmarks to as many levels as the authors desire.
Class %ZEN.Report.Display.bookmark Extends childrenNode [ Deprecated, Inheritance = right, PropertyClass = %ZEN.Report.Display.displayParameters, System = 4 ]
{

/// <Property>externalDestion</Property>
/// This attribute if not null is the uri to a place in another document
Property externalDestination As %ZEN.Datatype.string;

/// <Property>internalDestination</Property>
/// This attribute if not null is the idref of a place in the document of which it is a part
Property internalDestination As %ZEN.Datatype.string;

/// Specifies how the formatting object to which it applies is initially displayed. <br/>
/// Values have the following meanings: <br/>
/// <list>
/// <li><b>show</b></li>
/// <li><b>hide</b></li>
/// </list>
/// <b>show</b>
/// The content of the formatting object is a candidate for being displayed initially.<br/>
/// <b>hide</b>
/// The content of the formatting object is not a candidate for being displayed initially. 
Property startingState As %ZEN.Datatype.string;

/// This internal method is used to generate xsl-fo for all the children of this bookmark
Method %DrawToXSLFO(ByRef context As %String, ByRef XSL As %GlobalCharacterStream, delay As %GlobalCharacterStream) As %Status
{
	Set sc=$$$OK
	Set externalDestination=..externalDestination
	Set internalDestination=..internalDestination
	Set startingState=..startingState
	
	d ..%BeginDrawFo(.context,.XSL,.delay)
	
 	d ..tagChildren()
		// give children parent and class of containing table

	d XSL.WriteLine("<fo:bookmark>")
	
	if $e(externalDestination)="!" {
		Set externalDestion=$e(externalDestination,2,*)
		Set externalDestination="<xsl:value-of select='"_externalDestination_"'/>"
	}
	if $e(internalDestination)="!" {
		Set internalDestination=$e(internalDestination,2,*)
		Set internalDestination="<xsl:value-of select='"_internalDestination_"'/>"
	}
	if $e(startingState)="!" {
		Set startingState=$e(startingState,2,*)
		Set startingState="<xsl:value-of select='"_startingState_"'/>"
	}
	d:externalDestination'="" XSL.WriteLine("<xsl:attribute name='external-destination'>"_externalDestination_"</xsl:attribute>")
	d:internalDestination'="" XSL.WriteLine("<xsl:attribute name='internal-destination'>"_internalDestination_"</xsl:attribute>")
	d:startingState'="" XSL.WriteLine("<xsl:attribute name='starting-state'>"_startingState_"</xsl:attribute>")
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
	Do XSL.WriteLine("</fo:bookmark>")
	d ..%EndDrawFo(.context,.XSL,.delay)	
	Quit sc
}

}
