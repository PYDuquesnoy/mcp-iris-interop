/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %apiXSQL

/// <P> Front end for reading the CSV output from %SyntaxColor:Color.  Instead of reading the stream directly and reconstructing the lines
///     you can use a %SyntaxColorReader object and call its NextLine method.
/// <P> To create a %SyntaxColorReader object you can pass a CSV stream to %New; alternatively you can call FromCode and it will call %SyntaxColor for you.
Class %Library.SyntaxColorReader Extends %RegisteredObject [ System = 4 ]
{

Property CSV As %RegisteredObject [ Private ];

Property AtEnd As %Boolean [ Calculated, Private ];

/// This is here so that we can give better error messages
Property BufferedStream As %Boolean [ Private ];

Property PositionIsNoted As %Boolean [ Private ];

/// Not valid until AtEnd
Property InfoLine As %String [ Private ];

/// Not valid until AtEnd
Property ErrorInfo As %Stream.Object [ Private ];

/// Whether or not we've rewound ErrorInfo
Property RewoundErrorInfo As %Boolean [ Private ];

/// <P> The AtEnd property can be used to check for the end of the reader over the CSV stream
Method AtEndGet() As %Boolean
{
	Quit ..CSV.AtEnd
}

/// <P> Given a code stream, language, optional extra flags and/or symbols string for %SyntaxColor:Color
/// <P> Return a %SyntaxColorReader over the resulting CSV and whether there were any coloring errors/warnings (anywhere in the document)
ClassMethod FromCode(Code As %Stream.Object, Language As %String, ExtraFlags As %String, ByRef Reader As %Library.SyntaxColorReader, ByRef AnyColoringErrors As %Boolean, ByRef AnyColoringWarnings As %Boolean, Symbols As %String = "", BufferStream As %Boolean = 0) As %Status
{
	#Dim sc,outstr,ret
	
	// create a syntax colorer
	Set syncol=##class(%SyntaxColor).%New() If '$IsObject(syncol) {Quit %objlasterror}
	
	// invoke the Color method
	Set sc=Code.Rewind() If $$$ISERR(sc) {Quit sc}
	Set outstr=##class(%GlobalCharacterStream).%New() If '$IsObject(outstr) {Quit %objlasterror}
	If Symbols'="" {
		Set ret=syncol.Color(Code,outstr,Language,"MEC"_ExtraFlags,,,,.AnyColoringErrors,,.AnyColoringWarnings,Symbols)
	}
	Else {
		Set ret=syncol.Color(Code,outstr,Language,"MEC"_ExtraFlags,,,,.AnyColoringErrors,,.AnyColoringWarnings) // this is for backward compatibility
	}
	If 'ret {Quit $$$ERROR($$$GeneralError,"Error invoking syntax colorer: "_syncol.DLLResultCode)}
	
#if $$$DEBUGGING
	Do ##class(%CPT.CalloutDump).DumpStream("%SyntaxColorReader:FromCode outstr",outstr)
#endif

	// create and return the reader
	Set Reader=..%New(outstr,BufferStream) If '$IsObject(Reader) {Quit %objlasterror}
	
	Quit $$$OK
}

/// <P> Create a %SyntaxColorReader over the given CSV stream
Method %OnNew(CSV As %Stream.Object, BufferStream As %Boolean = 0) As %Status
{
	#Dim sc
	
	Set sc=CSV.Rewind() If $$$ISERR(sc) {Quit}
	
	If BufferStream {
		Set bufferedcsv=##class(%CPT.LineBufferedStream).%New(CSV) If '$IsObject(bufferedcsv) {Quit %objlasterror}
		Set ..CSV=bufferedcsv
	}
	Else {
		Set ..CSV=CSV
	}
	
	Set ..BufferedStream=BufferStream
	Set ..PositionIsNoted=0
	Set ..InfoLine=""
	Set ..ErrorInfo=##class(%Stream.GlobalCharacter).%New()
	Set ..RewoundErrorInfo=0
	
	Quit $$$OK
}

/// <P> Return a structured list of coloring information about the current line of code represented by
///     the CSV stream, advancing the stream.  In general, a number of lines will be read from the CSV stream
///     to make up one logical line corresponding to a line of the original code.  CSV lines of the form "\n"
///     determine logical line boundaries.
/// <P> If the stream is at its end this method returns 0, otherwise 1.
/// <P> If 1 is returned the ByRef parameters are set up from the stream items which were read :-
/// <UL>
///  <LI> LineCSV is set to a list of items, where each item is $LB(lang,terminal,code)
///  <LI> ColoringErrors and ColoringWarnings are set to whether there were any coloring errors/warnings at all on the line
/// </UL>
Method NextLine(ByRef LineCSV As %List, ByRef ColoringErrors As %Boolean, ByRef ColoringWarnings As %Boolean) As %Boolean
{
	#Dim record,lang,terminal,code,sc
	
	Set LineCSV=""
	Set ColoringErrors=0
	Set ColoringWarnings=0
	
	// if we're at the end right away ..
	If ..CSV.AtEnd {
		Quit 0
	}
	
	// fetch coloring records until we see \n
	While '..CSV.AtEnd {
					
		Set record=..CSV.ReadLine()
			
		// if it's a directive ..
		If $Extract(record)="\" {
			
			// if it's a newline ..
			If record="\n" {					
				Quit  // quit the while loop
			}
			
			// .. if it's an info line ..
			ElseIf $Extract(record,1,3)="\i " {
				ZTrap:..InfoLine'=""  // "there must only be one"
				Set ..InfoLine=$Extract(record,4,*)
			}

			// .. if it's an error info line ..
			ElseIf $Extract(record,1,3)="\e " {
				$$$THROWONERROR(sc,..ErrorInfo.WriteLine($Extract(record,4,*)))
			}
			
			// (ignore any other directives)
		}
		
		// .. not a directive ..
		Else {
			
			Set lang=$Piece(record,","),terminal=$Piece(record,",",2),code=$Piece(record,",",3,$Length(record,","))

			// if it's an error-coloring (attribute 0 means error)
			If terminal=0 {
				Set ColoringErrors=1
			}
			// .. if it's a warning ..
			ElseIf $Piece(terminal,":",2)="W" {
				Set ColoringWarnings=1
			}
			
			// add it to the result
			Set LineCSV=LineCSV_$ListBuild($ListBuild(lang,terminal,code))
		}
	}	
	
	Quit 1
}

/// <P> Move forward N lines - stops if end of file found first (doesn't report any error)
Method SkipLines(N As %Integer)
{
	#Dim record,i
	
	Set i=N	
	While i,'..CSV.AtEnd {
						
		Set record=..CSV.ReadLine()
		
		// if it's a newline ..
		If record="\n" {					
			Set i=i-1
		}
	}
}

/// <P> Move back to the beginning of the stream
/// <P> - not allowed if the position is noted
Method Rewind() As %Status
{
	If ..PositionIsNoted {ZTrap}
	
	Quit ..CSV.Rewind()
}

/// <P> Note the current stream position, caller must call
///     RestorePosition or ForgetPosition later.
Method NotePosition() As %Status
{
	If '..BufferedStream {Quit $$$ERROR($$$GeneralError,..%ClassName()_":NotePosition - Stream is not buffered")}
	If ..PositionIsNoted {Quit $$$ERROR($$$GeneralError,..%ClassName()_":NotePosition - NotePosition called twice")}
	
	Do ..CSV.NotePosition()
	Set ..PositionIsNoted=1
	
	Quit $$$OK
}

/// <P> Restore the noted position 
Method RestoreNotedPosition() As %Status
{
	If '..BufferedStream {Quit $$$ERROR($$$GeneralError,..%ClassName()_":RestorePosition - Stream is not buffered")}
	If '..PositionIsNoted {Quit $$$ERROR($$$GeneralError,..%ClassName()_":RestorePosition - NotePosition has not been called")}
	
	Do ..CSV.RestoreNotedPosition()
	Set ..PositionIsNoted=0
	
	Quit $$$OK
}

/// <P> Forget the noted position 
Method ForgetNotedPosition() As %Status
{
	If '..BufferedStream {Quit $$$ERROR($$$GeneralError,..%ClassName()_":ForgetPosition - Stream is not buffered")}
	If '..PositionIsNoted {Quit $$$ERROR($$$GeneralError,..%ClassName()_":ForgetPosition - NotePosition has not been called")}
	
	Do ..CSV.ForgetNotedPosition()
	Set ..PositionIsNoted=0
	
	Quit $$$OK
}

/// Return the info line, if any
/// Not valid until AtEnd
Method GetInfoLine() As %String
{
	ZTrap:'..AtEnd
	
	Quit ..InfoLine
}

/// Return the next error info
/// Not valid until AtEnd
Method NextErrorInfo(Output Description As %String, Output Source As %String, Output Location As %String, Output LineNumber As %Integer, Output LineOffset As %Integer) As %Boolean
{
	#Dim line,sc
	
	ZTrap:'..AtEnd
	
	If '..RewoundErrorInfo {
		$$$THROWONERROR(sc,..ErrorInfo.Rewind())
		Set ..RewoundErrorInfo=1
	}
	
	If ..ErrorInfo.AtEnd {
		Set (Description,Source,Location,LineNumber,LineOffset)=""
		Quit 0
	}
	Else {
		Set line=..ErrorInfo.ReadLine()
		Set $ListBuild(Description,Source,Location,LineNumber,LineOffset)=$ListFromString(line,$Char(9))
		Quit 1
	}
}

}
