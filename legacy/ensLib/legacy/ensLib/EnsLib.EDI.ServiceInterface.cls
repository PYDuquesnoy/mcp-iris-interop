/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occInclude, EnsEDI)

Class EnsLib.EDI.ServiceInterface [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

Parameter DOCCLASS As %String;

/// This method is called before attempting to process a Document, giving an opportunity
/// to 'filter' extraneous header/trailer/filler which may be present in the stream.
/// pLineExtra contains any extra chars read that may be part of the beginning of the Document to follow.
Method OnPreDocument(pStream As %IO.I.CharacterStream, ByRef pLineExtra As %String = "")
{
	Quit $$$OK // Subclass Responsibility
}

/// Called by the Parser at the start of a document
Method OnDocumentStart(pDocument As EnsLib.EDI.Document, pSource As %String, pStatus As %Status) As %Status
{
	Quit $$$OK // Subclass Responsibility
}

/// Called by the Parser at the end of a document
Method OnDocumentEnd(pDocument As EnsLib.EDI.Document, pSource As %String, pStatus As %Status) As %Status
{
	Quit $$$OK // Subclass Responsibility
}

/// This method is called after processing a Document, giving an opportunity to 'filter'
/// extraneous header/trailer/filler which may be present in the stream.
/// pLineExtra contains any extra chars read that may be part of the beginning of the next Document.
Method OnPostDocument(pStream As %IO.I.CharacterStream, ByRef pLineExtra As %String = "")
{
	Quit $$$OK // Subclass Responsibility
}

/// This method is called when a fatal error is encountered while processing a Document,
/// giving an opportunity to send a Reply message in response to those documents that never
/// call OnDocumentEnd
Method OnParsingError(pStatus As %Status, pDocument As EnsLib.EDI.Document, pSeparators As %String = "") As %Status
{
	Quit $$$OK // Subclass Responsibility
}

/// Return the DocType that the given service would assign to this document
Method resolveDocType(pDoc As EnsLib.EDI.Document) As %String
{
	Quit "Subclass Responsibility"
}

}
