/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// This class is used internally by InterSystems IRIS.
/// You should not make direct use of it within your applications.
/// There is no guarantee made about either the behavior or future operation of this class.<p>
/// 
/// Manage output of lines for CSP page class that is being created using COS.
Class %CSP.PageSection Extends %RegisteredObject [ System = 3 ]
{

/// Current block being written to.
Property Block As %Integer [ InitialExpression = 0, Internal ];

/// Index in IRIS.Temp to hold lines for this section.
Property Index As %Integer [ Internal ];

/// The number of CRLF sequences whose output is deferred.
Property WriteCrLf As %Integer [ InitialExpression = 0, Internal, Private ];

/// If true, a line has been written into this section.
Property TagWritten As %Boolean [ InitialExpression = 0, Internal ];

/// When a new section is created, get index for the section.
Method %OnNew(initvalue) As %Status [ Internal ]
{
	Set i%Index=$increment(^||%CSP.PageSection)
	Quit $$$OK
}

/// When a section is discarded, cleanup section storage.
Method %OnClose() As %Status [ Internal ]
{
	Kill ^||%CSP.PageSection(i%Index)
	Quit $$$OK
}

/// Save executable line for class that is being created.
Method WriteLine(line As %String, keepTogether As %Boolean) As %Status [ Internal ]
{
 If i%WriteCrLf>0 {
	Set $piece(cr,"!,",i%WriteCrLf)="!"
	Set ^(i%Block,$increment(^||%CSP.PageSection(i%Index,i%Block)))="	Write "_cr
	Set i%WriteCrLf=0
 }
 If keepTogether {
	Set next=^||%CSP.PageSection(i%Index,i%Block)
	Set ^||%CSP.PageSection(i%Index,i%Block,next)=^||%CSP.PageSection(i%Index,i%Block,next)_$c(13,10)_line
 } Else {
	Set ^(i%Block,$increment(^||%CSP.PageSection(i%Index,i%Block)))=line
 }
 Quit $$$OK
}

/// Create and save write text line for class that is being created.
Method WriteText(text As %String, crlf As %Boolean = 0) As %Status [ Internal ]
{
 If crlf {
	If text="" Set i%WriteCrLf=i%WriteCrLf+1 Quit
	Set text=text_",!"
 } Else {
	If text="" Quit $$$OK
 }
 If i%WriteCrLf>0 {
	Set $piece(cr,"!,",i%WriteCrLf+1)=""
	Set text=cr_text
	Set i%WriteCrLf=0
 }
 Set ^(i%Block,$increment(^||%CSP.PageSection(i%Index,i%Block)))="	Write "_text
 Quit $$$OK
}

}
