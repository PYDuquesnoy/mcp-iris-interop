/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occSAX

/// Represents an HTML attribute associated with a specific HTML element.<BR>
/// See the <CLASS>Template.HTMLTag</CLASS> class for more information.
/// This class represents one of a list of HTML Tags.
/// This list is used by the Studio CSP Tag Template to provide a
/// list of HTML tags and their associated attributes (which as represented using
/// the related <CLASS>Template.HTMLAttribute</CLASS>).<BR>
/// The data for this set of objects is provided within an XML file,
/// htmltags.xml, that is provided in the dev/studio/templates directory.<BR>
/// To load this file:<BR>
/// <EXAMPLE>Do ##class(%Studio.Template.HTMLElement).Import()</EXAMPLE>
/// 
Class %Studio.Template.HTMLElement Extends (%Persistent, %XML.Adaptor) [ Inheritance = right, Not ProcedureBlock, System = 3 ]
{

Index IdIdx On Tag [ IdKey, Unique ];

Parameter XMLNAME = "element";

/// Represents an HTML attribute associated with a specific HTML element.<BR>
/// See the <CLASS>Template.HTMLTag</CLASS> class for more information.
/// Represents an HTML attribute associated with a specific HTML element.<BR>
/// See the <CLASS>Template.HTMLTag</CLASS> class for more information.
/// Name of an HTML tag
Property Tag As %String(MAXLEN = 256, XMLNAME = "ename", XMLPROJECTION = "attribute");

/// Description of this element.
Property Description As %String(MAXLEN = 4000, XMLNAME = "description", XMLPROJECTION = "element");

/// Description of this element.
Property ShortDescription As %String(MAXLEN = 255, XMLNAME = "edesc", XMLPROJECTION = "attribute");

/// Is this an empty tag?
Property IsEmpty As %Boolean(XMLNAME = "empty", XMLPROJECTION = "attribute");

/// Attributes associated with this tag.
Relationship Attrs As HTMLAttribute(XMLITEMNAME = "attr", XMLNAME = "attrs") [ Cardinality = children, Inverse = Tag ];

/// Get list of attributes used by <var>tag</var>.<BR>
/// Returns true if the element is defined.
ClassMethod GetAttrs(tag As %String, ByRef attrs, ByRef cats) As %Boolean
{
	New SQLCODE,name,cat,type,desc,enum,defined
	
	&sql(DECLARE GA CURSOR FOR
		SELECT Name,Category,Type,Description,Enum
		INTO :name,:cat,:type,:desc,:enum
		FROM HTMLAttribute
		WHERE Tag = :tag)
		
	&sql(OPEN GA)
	If SQLCODE<0 quit 0

	&sql(FETCH GA)
	If (SQLCODE '= 0) {
		Set defined = 0
	}
	Else {
		Set defined = 1
	}
		
	While (SQLCODE = 0) {
		Set name = $ZCVT(name,"U") // !!!
		Set attrs(name) = ""
		Set attrs(name,"type") = type
		Set attrs(name,"category") = cat
		Set:(cat'="") cats(cat) = ""
		Set attrs(name,"desc") = desc
		Set attrs(name,"enum") = enum
		&sql(FETCH GA)
	}

	&sql(CLOSE GA)
	
	Quit defined
}

/// Load an HTML tags definition file into the
/// HTMLTag extent
ClassMethod Import(filename As %String = "")
{
	New reader,object,count,sc
	
	Set $ZT = "ImportERR"
	
	If (filename = "") {
		// find dev directory
		Set filename = $ZU(12,$G(^%SYS("bindir"))_"../dev/studio/templates/htmltags.xml")
	}
	Else {
		Set filename = $ZU(12,filename)
	}

	If ('##class(%File).Exists(filename)) {
		Write "File not found: ",filename,!
		Quit
	}
	
	Set reader = ##class(%XML.Reader).%New()
	Set reader.SAXFlags=$zboolean($$$SAXDEFAULTS,$$$SAXVALIDATION,2)

	// Begin processing of the file
	Set sc = reader.OpenFile(filename)
	If ($$$ISERR(sc)) {
		Do $system.OBJ.DisplayError(sc)
		Quit sc
	}

	// Associate a class name with the XML element name
	Do reader.Correlate("element","%Studio.Template.HTMLElement")
	
	Do ..%KillExtent()
	Set count = 0

	// read objects from xml file
	While (reader.Next(.object,.sc)) {
		Set count = count + 1
		Write count,?5,object.Tag,!
		Set sc=object.%Save()
		If ($$$ISERR(sc)) Quit
	}

	If ($$$ISERR(sc)) {
		Do $system.OBJ.DisplayError(sc)
		Quit sc
	}

	Quit $$$OK

ImportERR
	Set $ZT = ""
	Write "%Studio.Template.HTMLElement:Import() ERROR: ",$ZE,!
	Quit $$$ERROR($$$GeneralError,"%Studio.Template.HTMLElement:Import() ERROR: "_$ZE)
}

Storage Default
{
<Data name="HTMLElementDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Description</Value>
</Value>
<Value name="3">
<Value>IsEmpty</Value>
</Value>
</Data>
<Data name="HTMLNode1">
<Subscript>"1"</Subscript>
<Value name="1">
<Value>ShortDescription</Value>
</Value>
</Data>
<DataLocation>^%qHTMLElementD</DataLocation>
<DefaultData>HTMLNode1</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%qHTMLElementD</IdLocation>
<IndexLocation>^%qHTMLElementI</IndexLocation>
<StreamLocation>^%Studio.HTMLElementS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
