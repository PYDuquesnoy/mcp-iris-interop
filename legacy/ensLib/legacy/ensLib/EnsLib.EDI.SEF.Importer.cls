/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

/// This parses, validates and imports data from a SEF file into InterSystems IRIS
Class EnsLib.EDI.SEF.Importer Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// Quit after discovering the DocKey
Property DocKeyOnly As %Boolean;

/// This holds the File Stream
Property Stream As %FileCharacterStream;

/// This holds the document key
Property DocKey As %Integer;

/// This holds the previous state of the machine
Property PrevState As %String;

/// This holds the next state of the machine
Property NextState As %String;

/// This holds the status of the machine
Property Status As %Integer [ InitialExpression = {$$$StateRunning} ];

/// This holds the Trace flag. Set to 1 to output trace to console
Property Trace As %Boolean [ InitialExpression = 0 ];

/// This holds error messages
Property Error As %Status [ InitialExpression = {$$$OK} ];

/// This holds the allowed sections in this file
Property Sections As %String [ MultiDimensional ];

/// This holds the version
Property Version As %String [ InitialExpression = "1.0" ];

/// This holds the current line
Property Line As %String;

/// This holds the current line number
Property LineNumber As %Integer [ InitialExpression = 0 ];

/// This holds the PRIVATE section flag
Property PrivateSection As %Integer [ InitialExpression = 0 ];

// Accessors

Method NextStateSet(pState As %String) As %Status
{
	Set ..PrevState=i%NextState,i%NextState=pState
	Quit $$$OK
}

// These methods handle the various sections

/// This handes the CODES section
Method CODES(pPrevState As %String)
{
	If ..Trace Write !,"CODES"
	Set ..NextState=..ProcessSectionBody("CODESLINE")
}

/// This is the processor for a single CODES line
Method CODESLINE() As %Status
{
	Set tSC=$$$OK
	Do {
		Set tID=$Piece(..Line,"=")
		If tID="" {
			Set:""'=..Line tSC=$$$ERROR($$$GeneralError,"Code ID is Invalid")
			Quit
		}
		Set ^IRIS.Temp.SEF(..DocKey,"CODES",tID)=$ZStrip($Piece(..Line,"=",2),"*W")
		
	} While 0
	Quit tSC
}

/// This method handles the COMS section
Method COMS(pPrevState As %String)
{
	If ..Trace Write !,"COMS"		
	Set ..NextState=..ProcessSectionBody("COMSLINE")
}

/// This is the processor for a single COMS line
Method COMSLINE() As %Status
{
	Set tSC=$$$OK
	Do {
		Set tID=$Piece(..Line,"=")
		If tID="" {
			Set:""'=..Line tSC=$$$ERROR($$$GeneralError,"Composite ID is Invalid")
			Quit
		}
		Set ^IRIS.Temp.SEF(..DocKey,"COMS",tID)=$ZStrip($Piece(..Line,"=",2),"*W")
	} While 0
	Quit tSC
}

/// This handes the ELMS section
Method ELMS(pPrevState As %String)
{
	If ..Trace Write !,"ELMS"
	Set ..NextState=..ProcessSectionBody("ELMSLINE")
}

/// This is the processor for a single ELMS line
Method ELMSLINE() As %Status
{
	Set tSC=$$$OK
	Do {
		Set tID=$Piece(..Line,"=")
		If tID="" {
			Set:""'=..Line tSC=$$$ERROR($$$GeneralError,"Element ID is Invalid")
			Quit
		}
		Set ^IRIS.Temp.SEF(..DocKey,"ELMS",tID)=$ZStrip($Piece(..Line,"=",2),"*W")
	} While 0
	Quit tSC
}

/// This handles the INI section
Method INI(pPrevState As %String)
{
	Do {
		If ..Trace Write !,"INI"
		
		#; RULE: The .INI section immeadiately follows the .VER section. If .VER
		#; is ommitted, then the .INI section must be the first two lines in the SEF file.
		
		If (pPrevState'="Start")&&(pPrevState'="VER") {
			Set ..Error=$$$ERROR($$$GeneralError,".IN Section must follow .VER or be first record in file")
			Set ..NextState="Error"
			Quit
		}
		#; Read a line
		If (..ReadLine(.tSC))=0 {
			If $$$ISERR(tSC) {
				Set ..Error=tSC,..NextState="Error"
			}
			Set ..NextState="EOF"
			Quit
		}
		#; RULE: INI line is comma delimited.
		#; Piece 1: The standard or implementation name, generally the same as the filename
		#; of the SEF file. It should be 1 to 8 characters that would be valid as an MS-DOS 
		#; file name
		#; Piece 2: Reserved
		#; Piece 3: The Functional Group Version, Release and Industry code which will identify 
		#; the standard in any Functional Group Envelope Header Segment. Each code is separated 
		#; by a space
		#; Piece 4: Responsible agency code which identifies the standards organization in the
		#; functional group header:
		#; 		GC GENDOD
		#; 		T  for T.D.C.C. (EDIA)
		#; 		TD TRADACOMS
		#; 		UN for UN/EDIFACT
		#; 		X  for ASC X12 (DISA)
		#; Piece 5: The standard of which this implementation guideline is based
		#; Piece 6: The description of the implementation guideline
		Set ..DocKey=$Piece(..Line,",")
		
		If ""=..DocKey {
			Set ..Error=$$$ERROR($$$GeneralError,"INI Implementation name is invalid")
			Set ..NextState="Error"
			Quit	
		}
		If ..DocKeyOnly {
			Set ..NextState="EOF"
			Quit	
		}
		Set tRAC=","_$Piece(..Line,",",4)_","
		If ",GC,T,TD,UN,X,"'[tRAC {
			Set ..Error=$$$ERROR($$$GeneralError,"INI Responsible Agency Code is INVALID")
			Set ..NextState="Error"
			Quit
		}
		Kill ^IRIS.Temp.SEF(..DocKey)
		Set ^IRIS.Temp.SEF(..DocKey,"INI")=..Line,..NextState=..Dispatch()
	} While 0
}

/// This method handles the OBJVARS section
Method OBJVARS(pPrevState As %String)
{
	If ..Trace Write !,"OBJVARS"
	Set ..NextState=..ProcessSectionBody("OBJVARSLINE")
}

/// This is the processor for a single OBJVARS line
Method OBJVARSLINE() As %Status
{
	Set tSC=$$$OK
	Do {
		Set tID=$Piece(..Line,"=")
		If tID="" {
			Set tSC=$$$ERROR($$$GeneralError,"OBJVAR ID is Invalid")
			Quit
		}
		#; RULE: Last seen OBJVARS definiton overrides previous definitions
		Set ^IRIS.Temp.SEF(..DocKey,"OBJVARS",tID)=$Piece(..Line,"=",2)
	} While 0
	Quit tSC
}

/// This method handes the OVERHEAD section
Method OVERHEAD(pPrevState As %String)
{
	If ..Trace Write !,"OVERHEAD"
	Set ..NextState=..ProcessSectionBody("OVERHEADLINE")
}

/// This is the processor for a single OBJVARS line
Method OVERHEADLINE() As %Status
{
	Set tSC=$$$OK
	Do {
		#; RULE:The .OVERHEAD section, if it exists, may be ignored. It is optional
		#; and shows how many duplicate or new records are included in the SEF
		#; file.
	} While 0
	Quit tSC
}

/// This method handles a PUBLIC declaration if no PRIVATE is present in the file
Method PUBLIC(pPrevState As %String)
{
	If ..Trace Write !,"PUBLIC"
	
	#; RULE: PUBLIC and PRIVATE supported by version 1.1 and above only
	If ..Version<1.1 {
		Set ..Error=$$$ERROR($$$GeneralError,"PUBLIC not allowed for version: "_..Version)
		Set ..NextState="Error"
		Quit
	}
	#; We are entering a public section
	Set ..PrivateSection=0,..NextState=..Dispatch()
}

/// This method handles the PRIVATE section
Method PRIVATE(pPrevState As %String)
{
	If ..Trace Write !,"PRIVATE"		

	#; RULE: PUBLIC and PRIVATE supported by version 1.1 and above only
	If ..Version<1.1 {
		Set ..Error=$$$ERROR($$$GeneralError,"PRIVATE not allowed for version: "_..Version)
		Set ..NextState="Error"
		Quit
	}
	#; We are entering a PRIVATE Section
	Set ..PrivateSection=1,..NextState=..ProcessSectionBody("PRIVATELINE")
}

/// This is the processor for a single PRIVATE line
Method PRIVATELINE() As %Status
{
	Set tSC=$$$OK
	Do {
		Set tID=$Piece(..Line,"=")
		If tID="" {
			Set tSC=$$$ERROR($$$GeneralError,"Private Line is Invalid")
			Quit
		}
		#; RULE: Last seen PRIVATE definition overrides previous definitions
		Set ^IRIS.Temp.SEF(..DocKey,"PRIVATE",tID)=$Piece(..Line,"=",2)
	} While 0
	Quit tSC
}

/// This method handles the SEGS section
Method SEGS(pPrevState As %String)
{
	If ..Trace Write !,"SEGS"		
	Set ..NextState=..ProcessSectionBody("SEGSLINE")
}

/// This is the processor for a single SEGS line
Method SEGSLINE() As %Status
{
	Set tSC=$$$OK
	Do {
		Set tID=$Piece(..Line,"=")
		If tID="" {
			Set:""'=..Line tSC=$$$ERROR($$$GeneralError,"Segment ID is Invalid")
			Quit
		}
		#; RULE: Last seen SEGS definiton overrides previous definitions
		Set ^IRIS.Temp.SEF(..DocKey,"SEGS",tID)=$ZStrip($Piece(..Line,"=",2),"*W")
	} While 0
	Quit tSC
}

/// This method handes the SEMREFS section
Method SEMREFS(pPrevState As %String)
{
	If ..Trace Write !,"SEMREFS"		
	Set ..NextState=..ProcessSectionBody("SEMREFSLINE")
}

/// This is the processor for a single SEMREFS line
Method SEMREFSLINE() As %Status
{
	Set tSC=$$$OK
	Do {
		Set tID=$Piece(..Line,"=")
		If tID="" {
			Set tSC=$$$ERROR($$$GeneralError,"SEMREF ID is Invalid")
			Quit
		}
		#; RULE: Last seen SEMREF definiton overrides previous definitions
		Set ^IRIS.Temp.SEF(..DocKey,"SEMREFS",tID)=$Piece(..Line,"=",2)
	} While 0
	Quit tSC
}

/// This method handles the SETS section
Method SETS(pPrevState As %String)
{
	If ..Trace Write !,"SETS"		
	Set ..NextState=..ProcessSectionBody("SETSLINE")
}

/// This is the processor for a single SETS line
Method SETSLINE() As %Status
{
	Set tSC=$$$OK
	Do {
		Set tID=$Piece(..Line,"=")
		If tID="" {
			Set tSC=$$$ERROR($$$GeneralError,"Transaction ID is Invalid")
			Quit
		}
		#; RULE: Last seen SETS definiton overrides previous definitions
		Set ^IRIS.Temp.SEF(..DocKey,"SETS",tID)=$Piece(..Line,"=",2)
	} While 0
	Quit tSC
}

/// This method handes the STD section
Method STD(pPrevState As %String)
{
	Do {
		If ..Trace Write !,"STD"
		
		Set tSTD=$ZStrip($Piece(..Line," ",2,99),"*W")
		For tI=2:1:$Length(tSTD,",") {
			If ",LS,RE,FX,"'[(","_$Piece(tSTD,",",tI)_",") {
				Set ..Error=$$$ERROR($$$GeneralError,"Invalid STD param")
				Set ..NextState="Error"
				Quit
			}
		}
		If ..NextState="Error" Quit 
		
		#; RULE: The last seen STD definition overrides previous definitions
		Set ^IRIS.Temp.SEF(..DocKey,"STD")=tSTD
		
		Set ..NextState=..Dispatch()
	} While 0
}

/// This method handes the TEXTCOMS section
Method TEXTCOMS(pPrevState As %String)
{
	If ..Trace Write !,"TEXTCOMS"		
	Set ..NextState=..ProcessSectionBody("TEXTCOMSLINE")
}

/// This is the processor for a single TEXTCOMS line
Method TEXTCOMSLINE() As %Status
{
	Set tSC=$$$OK
	Do {
		Set tID=$Piece(..Line,",")
		If tID="" {
			Set tSC=$$$ERROR($$$GeneralError,"TEXT,COMS ID is Invalid")
			Quit
		}
		#; RULE: Last seen definiton overrides previous definitions
		Set ^IRIS.Temp.SEF(..DocKey,"TEXTCOMS",tID)=$Piece(..Line,",",2)
	} While 0
	Quit tSC
}

/// This method handes the TEXTELMS section
Method TEXTELMS(pPrevState As %String)
{
	If ..Trace Write !,"TEXTELMS"		
	Set ..NextState=..ProcessSectionBody("TEXTELMSLINE")
}

/// This is the processor for a single TEXTELMS line
Method TEXTELMSLINE() As %Status
{
	Set tSC=$$$OK
	Do {
		Set tID=$Piece(..Line,",")
		If tID="" {
			Set tSC=$$$ERROR($$$GeneralError,"TEXT,ELMS ID is Invalid")
			Quit
		}
		#; RULE: Last seen definiton overrides previous definitions
		Set ^IRIS.Temp.SEF(..DocKey,"TEXTELMS",tID)=$Piece(..Line,",",2)
	} While 0
	Quit tSC
}

/// This method handes the TEXTSEGS section
Method TEXTSEGS(pPrevState As %String)
{
	If ..Trace Write !,"TEXTSEGS"		
	Set ..NextState=..ProcessSectionBody("TEXTSEGSLINE")
}

/// This is the processor for a single TEXTSEGS line
Method TEXTSEGSLINE() As %Status
{
	Set tSC=$$$OK
	Do {
		Set tID=$Piece(..Line,",")
		If tID="" {
			Set tSC=$$$ERROR($$$GeneralError,"TEXT,SEGS ID is Invalid")
			Quit
		}
		#; RULE: Last seen definiton overrides previous definitions
		Set ^IRIS.Temp.SEF(..DocKey,"TEXTSEGS",tID)=$Piece(..Line,",",2)
	} While 0
	Quit tSC
}

/// This method handes the TEXTSETS section
Method TEXTSETS(pPrevState As %String)
{
	If ..Trace Write !,"TEXTSETS"		
	Set ..NextState=..ProcessSectionBody("TEXTSETSLINE")
}

/// This is the processor for a single TEXTSETS line
Method TEXTSETSLINE() As %Status
{
	Set tSC=$$$OK
	Do {
		Set tID=$Piece(..Line,",")
		If tID="" {
			Set tSC=$$$ERROR($$$GeneralError,"TEXT,SETS ID is Invalid")
			Quit
		}
		#; RULE: Last seen definiton overrides previous definitions
		Set ^IRIS.Temp.SEF(..DocKey,"TEXTSETS",tID)=$Piece(..Line,",",2)
	} While 0
	Quit tSC
}

/// This method handes the VALLISTS section
Method VALLISTS(pPrevState As %String)
{
	If ..Trace Write !,"VALLISTS"

	#; Read a line
	If (..ReadLine(.tSC))=0 {
		If $$$ISERR(tSC) {
			Set ..Error=tSC,..NextState="Error"
		} Else {
			Set ..NextState="EOF"
		}
		Set tExit=1
		Quit
	}
	Set tExit=0
	While ($Extract(..Line)'=".") {
		Set tList=$Piece(..Line,"="),tDesc=$Piece(..Line,"=",2)
		
		If tList="" {
			Set ..Error=$$$ERROR($$$GeneralError,"VALLIST ID is invalid")
			Set ..NextState="Error",tExit=1
			Quit
		}
		Kill tSEF Set tSEF(tList)=tDesc
		
		If (..ReadLine(.tSC))=0 {
			If $$$ISERR(tSC) {
				Set ..Error=tSC,..NextState="Error"
			} Else {
				Set ..NextState="EOF"
			}
			Set tExit=1
			Quit
		}
		Set tI=0  While (($Extract(..Line)="'")||($Extract(..Line)="&")) {
			Set tSEF(tList,$Increment(tI))=..Line
			
			If (..ReadLine(.tSC))=0 {
				If $$$ISERR(tSC) {
					Set ..Error=tSC,..NextState="Error"
				} Else {
					Set ..NextState="EOF"
				}
				Set tExit=1
				Quit
			}
		}
		Merge ^IRIS.Temp.SEF(..DocKey,"VALLISTS",tList)=tSEF(tList)
		If tExit=1 Quit
	}
}

/// This method handes the VALREFS section
Method VALREFS(pPrevState As %String)
{
	If ..Trace Write !,"VALREFS"		
	Set ..NextState=..ProcessSectionBody("VALREFSLINE")
}

/// This is the processor for a single VALREFS line
Method VALREFSLINE() As %Status
{
	Set tSC=$$$OK
	Do {
		Set tID=$Piece(..Line,"=")
		If tID="" {
			Set tSC=$$$ERROR($$$GeneralError,"VALREFS ID is Invalid")
			Quit
		}
		#; RULE: Last seen definiton overrides previous definitions
		Set ^IRIS.Temp.SEF(..DocKey,"VALREFS",tID)=$Piece(..Line,"=",2)
	} While 0
	Quit tSC
}

/// This method handles the VER state
Method VER(pPrevState As %String)
{
	Do {
		If ..Trace Write !,"VER"
		
		#; RULE: If the .VER Section is included, it must be
		#; the first record in the SEF file. 
		If pPrevState'="Start" {
			Set ..Error=$$$ERROR($$$GeneralError,".VER Section must be first record in file")
			Set ..NextState="Error"
			Quit
		} 
		Set tVersion=$Piece(..Line," ",2)
		If tVersion'?1N1"."1N {
			Set ..Error=$$$ERROR($$$GeneralError,"Version has invalid format")
			Set ..NextState="Error"
			Quit
		} 
		#; Record the Version
		Set ..Version=tVersion,..NextState=..Dispatch()
	} While 0
}

// These methods correspond to various states

/// This handles the Error state
Method Error(pPrevState As %String)
{
	Set ..NextState="Stop"
}

/// This handles the EOF state
Method EOF(pPrevState As %String)
{
	Set ..NextState="Stop"
}

Method Start(pPrevState As %String)
{
	Set ..NextState=..Dispatch()
}

/// This handles the Stop state
Method Stop(pPrevState As %String)
{
	Set ..Status=$$$StateStopped
}

// These methods are utility functions

/// Read a line and dispatch to the section
Method Dispatch() As %String
{
	#; Read a line
	If (..ReadLine(.tSC))=0 {
		If $$$ISERR(tSC) {
			Set ..Error=tSC,tNextState="Error"
		}
		Set tNextState="EOF"
	} Else {
		#; Get the Section ID
		Set tSC=..Section(.tSection) 
		If $$$ISERR(tSC) {
			Set ..Error=tSC,tNextState="Error"
		} Else {
			#; Dispatch to Section Handler
			Set tNextState=tSection
		}
	}
	Quit tNextState
}

/// This method processes a section by reading lines, validating them
/// and returning the next state to invoke
Method ProcessSectionBody(pLineHandler As %String) As %String
{
	#; Read a line
	If (..ReadLine(.tSC))=0 {
		If $$$ISERR(tSC) {
			Set ..Error=tSC
			Quit "Error"
		}
		Quit "EOF"
	}
	Set tNextState="" For {
		#; If we are in a public section and we see a '.' line then we should start a new section
		#; If we are in a Private Section and have hit a line begining with '.', normally this indicates 
		#; a new section but in a private section that doesn't hold true ( anything goes except .PUBLIC )
		Set c1=$E(..Line) Quit:c1="."&&('..PrivateSection||(".PUBLIC"=$E(..Line,1,$L(".PUBLIC"))))
		If ""'=c1 {
			Set tSC=$zobjmethod($this,pLineHandler)
			If $$$ISERR(tSC) {
				Set ..Error=tSC, tNextState="Error"
				Quit
			}
		}
		If (..ReadLine(.tSC))=0 {
			If $$$ISERR(tSC) {
				Set ..Error=tSC, tNextState="Error"
			} Else {
				Set tNextState="EOF"
			}
			Quit
		}
	} 
	#; If there was an error during processing of the loop, exit this handler
	Quit:""'=tNextState tNextState
	
	#; Have read past the end of section, so must determine next section
	Set tSC=..Section(.tSection) 
	If $$$ISERR(tSC) {
		Set ..Error=tSC
		Quit "Error"
	}
	#; Dispatch to Section Handler
	Quit tSection
}

/// This Reads the next line from the file
Method ReadLine(ByRef pStatus As %Status) As %Boolean
{
	Set tRetVal=1,pStatus=$$$OK
	Do {
		#; No more lines ?
		If ..Stream.AtEnd Set ..Line="",tRetVal=0 Quit 
		
		#; Increment the line number
		Set ..LineNumber=..LineNumber+1
		
		#; Get the next line
		Set ..Line=..Stream.ReadLine()
		While $C(13)=$E(..Line,*) { Set ..Line=$E(..Line,1,*-1) }
		
		#; RULE: High-ASCII and other non printable characters can be included as
		#; 3-digit escaped values for versions 1.4 and above
		If ..Line["\",..Version>"1.4" {
			
			Set tLine=..Line
			If ..Unescape(.tLine,.tOffset)=0 {
				Set pStatus=$$$ERROR($$$GeneralError,"Invalid escape sequence at offset: "_tOffset)
				Set tRetVal=0 Quit
			}
			Set ..Line=tLine
		}
		#; Discard comments
	} While $E(..Line)="*"
	
	Quit tRetVal
}

Method Section(ByRef pSection As %String) As %Status
{
	#; Pick out the section ID
	Set pSection=$Piece(..Line," ")
	 
	#; If unrecognized section then indicate so 
	If (pSection="")||('$Data(..Sections(pSection))) {
		Quit $$$ERROR($$$GeneralError,"Invalid Section: "_pSection)
	} Else {
		#; Remove '.' and ','
		Set pSection=$Translate(pSection,".,")
	}
	Quit $$$OK
}

Method Unescape(ByRef pLine As %String, Output pOffset As %Integer) As %Boolean
{
	#; RULE: High-ASCII and other non-printable characters can be included in the SEF
	#; file as 3-digit escaped values. Any character from 0x00 to 0xFF can be used
	#; It appears from objservation of actual SEF files that the common 'c' escape sequences
	#; of \n \r should be supported too
	Set (tPos,pOffset)=0,tRet=1 
	Do {
		Set tPos=$Find(pLine,"\",tPos)
		If tPos {
			#; Found escape introducer, check for escape of escape, newline or carriage return
			Set tChar=$Extract(pLine,tPos)
			If tChar="\"||(tChar="n")||(tChar="r")||(tChar="t") {
				// For now we will not convert the cr/nl/tab
				Set tPos=tPos+1
			} Else {
				#; first validate the character number, MUST be 3 digits and numerically
				#; between 0 and 255
				Set tNum=$Extract(pLine,tPos,tPos+2)
				If tNum'?3N||(tNum>255) {
					Set tRet=0,pOffset=tPos
					Quit
				}
				#; Replace the escape sequence with the character
				Set $Extract(pLine,tPos-1,tPos+1)=$Char(tNum),tPos=tPos-2
			}
		}
	} While (tPos)
	
	Quit tRet
}

/// Import the named file 
Method Import(pFileName As %String, Output pDocKey As %String, pDocKeyOnly As %Boolean = 0) As %Status
{
	Set tSC=$$$OK,$ZT="Trap"
	Do {
		Set pDocKey="",..DocKeyOnly=pDocKeyOnly
		
		#; Check that file exists
		If '##class(%File).Exists(pFileName) {
			Set tSC=$$$ERROR($$$GeneralError,"File Does NOT exist")  Quit
		}
		#; Create the file character stream
		Set ..Stream=##class(%FileCharacterStream).%New()
		If '$IsObject(..Stream) Set tSC=%objlasterror Quit
		
		#; Set the file name and the first state
		Set ..Stream.LineTerminator=$C(10)
		Set ..Stream.Filename=pFileName, ..NextState="Start"	
		
		If ..Trace Write !,"Import Begins"

		While (..Status=$$$StateRunning) {
			#; Switch States
			Do $zobjmethod($this,..NextState,..PrevState)
		}
		Set tSC=..Error 
		If $$$ISERR(tSC) {
			Set tSC=$$$ADDSC(tSC,$$$ERROR($$$GeneralError,"At Line: "_..LineNumber))
		}
		Set pDocKey=..DocKey
		
		If ..Trace Write !,"Import Ends"
	} While 0
Exit
	Quit tSC
Trap
	Set tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

// Creators

Method %OnNew(initvalue As %RawString) As %Status [ ProcedureBlock = 1 ]
{
	Set ..Sections(".CODES")=""
	Set ..Sections(".COMS")=""
	Set ..Sections(".ELMS")=""
	Set ..Sections(".INI")=""
	Set ..Sections(".OBJVARS")=""
	Set ..Sections(".OVERHEAD")=""
	Set ..Sections(".PRIVATE")=""
	Set ..Sections(".PUBLIC")=""
	Set ..Sections(".SEGS")=""
	Set ..Sections(".SEMREFS")=""
	Set ..Sections(".SETS")=""
	Set ..Sections(".STD")=""
	Set ..Sections(".TEXT,COMS")=""
	Set ..Sections(".TEXT,ELMS")=""
	Set ..Sections(".TEXT,SEGS")=""
	Set ..Sections(".TEXT,SETS")=""
	Set ..Sections(".VALLISTS")=""
	Set ..Sections(".VALREFS")=""
	Set ..Sections(".VER")=""
	
	Quit $$$OK
}

}
