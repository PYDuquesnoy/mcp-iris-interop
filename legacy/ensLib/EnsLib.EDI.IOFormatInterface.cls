/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class EnsLib.EDI.IOFormatInterface [ Abstract, System = 4 ]
{

/// Return 1 if we took care of the whole document or got an error. Returning 0 means the caller will continue doing component segments as usual.
ClassMethod OutputDocument(pDocObj As EnsLib.EDI.Document, Output pStatus As %Status, pIOStream As %IO.I.CharacterStream, pSeparators As %String, ByRef pContext As %String) As %Boolean [ Abstract ]
{
	Set pStatus=$$$ERROR($$$NotImplemented)
	Quit 1
}

/// Output any post-segment trailing document content. Called only if OutputDocument() returned 0 meaning it did not complete output of all segments itself.
ClassMethod OutputDocumentEnd(pDocObj As EnsLib.EDI.Document, Output pStatus As %Status, pIOStream As %IO.I.CharacterStream, pSeparators As %String, pSequenceNumber As %String) [ Abstract ]
{
	Set pStatus=$$$ERROR($$$NotImplemented)
	Quit ; no return value
}

/// Return 1 if we took care of the segment or got an error. Returning 0 means the caller will output the segment as usual.
ClassMethod OutputSegment(pSegObj As EnsLib.EDI.Segment, Output pStatus As %Status, pIOStream As %IO.I.CharacterStream, pSeparators As %String, pSegNum As %String, pSegPath As %String, pParentDoc As EnsLib.EDI.Document, ByRef pContext As %String) As %Boolean
{
	Set pStatus=$$$ERROR($$$NotImplemented)
	Quit 1
}

/// Return 1 if we imported the whole document or got an error. Returning 0 means the caller will do its standard parse.
ClassMethod ImportDocument(Output pDocObj As EnsLib.EDI.Document, Output pStatus As %Status, pIOStream As %IO.I.CharacterStream, ByRef pContext As %String) As %Boolean [ Abstract ]
{
	Set pStatus=$$$ERROR($$$NotImplemented)
	Quit 1
}

/// Return 1 if we imported a segment or got an error. Returning 0 means the caller will do its standard parse.
ClassMethod ImportSegment(Output pSegObj As EnsLib.EDI.Segment, Output pStatus As %Status, pIOStream As %IO.I.CharacterStream, ByRef pContext As %String) As %Boolean [ Abstract ]
{
	Set pStatus=$$$ERROR($$$NotImplemented)
	Quit 1
}

}
