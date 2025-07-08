/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An XML Catalog file parser.<br>
/// This is used by the <CLASS>%XML.Catalog</CLASS> class.<br>
/// Use as follows:
/// <EXAMPLE>
/// Set parser = ##class(%XML.CatalogParser).%New()
/// Set sc = parser.Start("\dbdtd\docbook.cat"),!
/// 	
/// While (parser.NextElement(.el)) {
/// 	// el will contain the values for this element
/// 	// as subscripts
/// 	}
/// </EXAMPLE>
Class %XML.CatalogParser Extends %Library.RegisteredObject [ Not ProcedureBlock, System = 3 ]
{

Property BPos As %Integer;

Property Buffer As %String;

Property InStream As %AbstractStream;

Property LineNo As %Integer;

Property ColNo As %Integer;

Property LastColNo As %Integer;

Property AtEnd As %Boolean;

Property ErrorMsg As %String;

/// holds the last "undone" token
Property UndoBuffer As %String;

/// Begin parsing the given Catalog file
Method Start(file As %String) As %Status
{
	If ('##class(%File).Exists(file)) {
		Quit $$$ERROR($$$FileDoesNotExist,file)
	}

	Set ..InStream = ##class(%File).%New(file)
	Set sc = ..InStream.Open("R")

	If ($$$ISERR(sc)) Quit sc

	// initialize input
	Do ..InStream.Rewind()
	Set ..BPos = 1
	Set ..ColNo = 0
	Set ..LineNo = 0
	Set ..LastColNo = 0
	Set ..AtEnd = 0
	
	Quit $$$OK
}

Method End()
{
	If (..InStream '= "") {
		Set ..InStream = ""
	}
}

/// Find and return the next element in the catalog<br>
/// <VAR>element</VAR> returns the values of the element
/// as subscripts.
Method NextElement(ByRef element As %String) As %Boolean
{
	New done,state
	Set state = 0
	Set done = 0
	
	While (('done) && ('..AtEnd)) {
		Set element("KEYWORD") = ..NextToken()
		If (element("KEYWORD") = "PUBLIC") {
			Set element("PUBLIC") = ..NextToken()
			Set element("SYSTEM") = ..NextToken()
			Set done = 1
		}
		ElseIf (element("KEYWORD") = "SYSTEM") {
			Set element("SYSFROM") = ..NextToken()
			Set element("SYSTO") = ..NextToken()
			Set done = 1
		}
		ElseIf (element("KEYWORD") = "CATALOG") {
			Set element("CATALOG") = ..NextToken()
			Set done = 1
		}
	}
	
	Quit '..AtEnd
}

/// Display an error message
Method Error(text As %String)
{
	Set ..ErrorMsg = ..ErrorMsg _ "ERROR: " _ text _ " line: " _ ..LineNo _ " col: " _ ..LastColNo _ $c(13,10)
}

/// Put back a token into the input stream
Method UndoToken(token As %String)
{
	Set ..UndoBuffer = token
}

/// Return the next token from the InputStream
Method NextToken() As %String
{
	New c,state,done,atend,text
	
	Set text = ""
	Set state = 0
	Set done = 0
	
	If (..UndoBuffer '= "") {
		Set text = ..UndoBuffer
		Set ..UndoBuffer = ""
		Quit text
	}
	
	If (..AtEnd) {
		Quit ""
	}
	
	Set ..LastColNo = ..ColNo

	While ('done) {
		
		// get next character
		If (..BPos > $L(..Buffer)) {
			If (..InStream.AtEnd) {
				// no more data in stream
				Set ..Buffer = ""
				Set ..BPos = 1
				Set ..AtEnd = 1
				Set done = 1
			}
			Else {
				// fill up local buffer
				Set ..Buffer = ..InStream.Read(16000) _ " "
				Set ..LineNo = ..LineNo + 1
				Set ..LastColNo = 1
				Set ..ColNo = 0
				Set ..BPos = 1
			}
		}
		
		If (..AtEnd) {
			// trick to get last token
			Set c = " "
		}
		Else {
			Set c = $E(..Buffer,..BPos)
			Set ..BPos = ..BPos + 1
			Set ..ColNo = ..ColNo + 1
		}

		// convert tab&cr to space
		If ($C(9,10,13) [ c ) {
			Set c = " "
		}
		
		If (state = 0) {
			If (c = """") {
				Set text = ""
				Set state = 1				
			}
			ElseIf (c = "-") {
				// test for start of -- comment
				Set text = ""
				Set state = 4
			}
			ElseIf (c '= " ") {
				Set text = c
				Set state = 3
			}
		}
		ElseIf (state = 1) {
			// in a quoted string
			If (c = """") {
				// look for ""
				Set state = 2
			}
			Else {
				Set text = text _ c
			}
		}
		ElseIf (state = 2) {
			If (c = """") {
				// ""
				Set text = text _ """"
				Set state = 1
			}
			Else {
				// end of quoted block
				// undo read, return token
				Set ..BPos = ..BPos - 1
				Set done = 1
			}
		}
		ElseIf (state = 3) {
			// gathering characters
			If (c = " ") {
				// done
				Set done = 1
			}
			Else {
				Set text = text _ c
			}
		}
		ElseIf (state = 4) {
			// possible -- comment
			If (c = "-") {
				// comment
				Set state = 5
			}
			ElseIf (c = " ") {
				// solo -
				Set text = "-"
				Set done = 1
			}
			Else {
				Set text = "-"
				Set state = 3
			}
		}
		ElseIf (state = 5) {
			// in a -- comment
			If (c = "-") {
				// end of comment?
				Set state = 6
			}
		}
		ElseIf (state = 6) {
			// possible end of -- comment
			If (c = "-") {
				// end of comment
				Set state = 0
			}
			Else {
				// more to go
				Set state = 5
			}
		}
	}

	Quit text
}

}
