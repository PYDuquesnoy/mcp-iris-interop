/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %SOAP.Security.TextElement defines a Security header element which is output from
/// the text string included that is set by its user.  The text string must include the element
/// tag as well as all its children.
Class %SOAP.Security.TextElement Extends %SOAP.Security.Element [ System = 4 ]
{

/// The text to be output for this element.	
Property Text As %String;

/// XMLExport of this element is just the write of the buffer
Method XMLExportInternal() As %Status [ Internal, ProcedureBlock = 0, ServerOnly = 1 ]
{
	$$$XMLSetBuffer(..Text)
	$$$XMLWrite
	
	Quit $$$OK
}

/// Set the Text property from specified XML document node as the specified text from the document.<br>
/// <var>document<var> is the document which contains the text to be added.
/// The document will frequently be set as client.ImportHandler where client is the %SOAP.WebClient subclass.
/// <var>nodeid<var> is the nodeid of the element and its children to be add to text property.
Method SetText(document As %XML.Document, nodeid As %String) As %Status
{
	Try {
		If '##class(%XML.ImportHandler).SerializeNode(document.DocumentId,nodeid,0,1,.text,1) {
			Set sc=$$$ERROR($$$SOAPMalformed)
			Quit
		}
		Set ..Text=text
		Set sc=$$$OK
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	Quit sc
}

/// Set the Text property from specified XML document node as canonicalized text.<br>
/// <var>document<var> is the document which contains the text to be canonicalized.
/// The document will frequently be set as client.ImportHandler where client is the %SOAP.WebClient subclass.<br>
/// <var>nodeid<var> is the nodeid of the element and its children to be add to Text property.<br>
/// For Exclusive XML Canonicalization <var>prefixList</var> is a multidimensional array which specifies
/// the prefixes that are included on the IncludedNamespaces list.  
/// prefixList(prefix)="" if the prefix is on the list.
/// If <var>prefixList</var> is = "c14n", then inclusive canonicalization is performed.
Method SetCanonicalized(document As %XML.Document, nodeid As %String, ByRef PrefixList) As %Status
{
	Try {
		// Get a writer configured to output an XML String
		Set writer=##class(%XML.Writer).%New()
		Set sc=writer.OutputToString()
		If $$$ISERR(sc) Quit
		
		// Canonicalize the specified node using the prefixList
		Set node=document.GetNode(nodeid)
		Set sc=writer.Canonicalize(node,.PrefixList)
		If $$$ISERR(sc) Quit
		
		// Save the string returned with the canonical XML
		Set ..Text=writer.GetXMLString(.sc)
		If $$$ISERR(sc) Quit
		
	} Catch ex {
		Set sc=ex.AsStatus()
	}
	
	Quit sc
}

}
