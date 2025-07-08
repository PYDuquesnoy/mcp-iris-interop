/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %soap

/// <p><b>For details on using this class</b>, see
/// <a target="_top" href="/csp/docbook/Doc.View.cls?FIND=CLASSES+%25XML.Document">Representing an XML Document as a DOM</a>.</p>
/// <class>%XML.Document</class> represents an XML document as an Document Object Model (DOM).
/// The DOM may be created either
/// <li>from an XML document by accessing the Document property of %XML.Reader 
/// after calling an Openxxx method of %XML.Reader.</li>
/// <li>as a new DOM by calling the <method>CreateDocument</method> of this class.</li><br>
/// The <class>%XML.Document</class> class maintains the namespaces for the DOM.
/// The <class>%XML.Node</class> class created by <method>GetDocumentElement</method> 
/// may be used to navigate the DOM or the macros in %xmlDOM.inc may be used to navigate
/// the DOM based on the <property>DocumentId</property> of <class>%XML.Document</class>.
Class %XML.Document Extends (%XML.ImportHandler, %XML.Node) [ Inheritance = right, System = 2 ]
{

/// Create a new Document Object Model (DOM) consisting of only a root element.
ClassMethod CreateDocument(localName As %String, namespace As %String) As %XML.Document
{
	Set document=##class(%XML.Document).%New()
	Set gbl=document.DOMName
	Set document.Tree=$increment(@gbl)
	Set document.DocumentId=$$$xmlDocumentId(document)
	Do document.InsertNamespace("http://www.w3.org/2001/XMLSchema-instance")
	$$$xmliSetDocumentNode(document.DocumentId)
	Set document.Document=document
	Do document.AppendElement(localName,.namespace)
	Quit document
}

/// Create a doocument by parsing the XML document contained in a stream.<br>
/// The parsed document is returned in <var>document</var>.<br>
/// A %Status is returned to indicate if parsing is successful.
ClassMethod GetDocumentFromStream(stream As %BinaryStream, Output document As %XML.Document) As %Status
{
	// Parse the message stream so that pieces may be Canonicalized
	If stream=0 {
		$$$XMLRewind
	} Else {
		Do stream.Rewind()
	}
	Set reader = ##class(%XML.Reader).%New()
	Set reader.SAXFlags=$$$SAXFULLDEFAULT-$$$SAXVALIDATIONSCHEMA
	Set sc=reader.OpenStream(stream)
	If $$$ISERR(sc) Quit sc
	Set document=reader.Document
	If document.GetVersion()<2 {
		Do document.AddWSSecurityIds()
	}
	Quit $$$OK
}

/// Returns an <class>%XML.Node</class> DOM navigation object which is positioned at the
/// the root element of this Document.
Method GetDocumentElement() As %XML.Node [ CodeMode = expression ]
{
..GetNode($$$xmlGetDocumentElement(..DocumentId))
}

/// Returns the node id of the root element of this Document.
Method GetDocumentNode() As %String [ CodeMode = expression ]
{
$$$xmlGetDocumentElement(..DocumentId)
}

/// Returns an <class>%XML.Node</class> DOM navigation object which is positioned at the
/// the node specified by the nodeId argument.
Method GetNode(nodeId As %String) As %XML.Node
{
	Set node=##class(%XML.Node).%New()
	Set node.Document=$this
	Set node.NodeId=nodeId
	Quit node
}

/// Return nodeId for node with id attribute = %id.
Method GetNodeById(id As %String) [ CodeMode = expression ]
{
$$$xmlGetNodeById(..DocumentId,id)
}

/// Save nodeId for node with id attribute = %id.
Method SetNodeById(id As %String, nodeId As %Integer)
{
	$$$xmlSetNodeById(..DocumentId,id,nodeId)
}

/// Return XML namespace URI for nsIndex into document's namespace table.
Method GetNamespace(nsIndex As %Integer) As %String [ CodeMode = expression ]
{
$$$xmlIndexToNamespace(..DocumentId,nsIndex)
}

/// Return number of namepsaces in document's namespace table.
Method CountNamespace() As %Integer [ CodeMode = expression ]
{
$$$xmlCountNamespace(..DocumentId)
}

/// Return XML namespace URI for nsIndex into document's namespace table.
Method InsertNamespace(namespace As %String)
{
	$$$xmlInsertNamespace(..DocumentId,namespace)
}

/// Return XML nsIndex into document's namespace table for namespace URI.
Method FindNamespace(namespace As %String) As %Integer [ CodeMode = expression ]
{
$$$xmlNamespaceToIndex(..DocumentId,namespace)
}

/// Return the version of the import handler that constructed this document.
/// A programmatically constructed DOM will always have version "".
Method GetVersion() As %Integer [ CodeMode = expression ]
{
$$$xmlGetVersion(..DocumentId)
}

}
