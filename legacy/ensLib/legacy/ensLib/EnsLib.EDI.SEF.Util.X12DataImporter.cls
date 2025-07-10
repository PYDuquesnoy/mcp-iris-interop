/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include EnsEDISEF

/// This imports the X12 Implementation Guide Table Data
Class EnsLib.EDI.SEF.Util.X12DataImporter Extends %RegisteredObject [ ClassType = "", ProcedureBlock, System = 4 ]
{

ClassMethod Import(pDirectoryName As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
	
		Set tImporter=..%New()
		If '$IsObject(tImporter) Set tSC=%objlasterror Quit
		
		$$$KillRootNode($$$vaSchemaDescGbl) Set tPrefix="X12"
		
		Set tSC=tImporter.ImportFREEFORM(pDirectoryName_"FREEFORM.TXT",tPrefix)
		If $$$ISERR(tSC) Quit
		
		Set tSC=tImporter.ImportFREEFORM(pDirectoryName_"FREEFORM_X12.TXT",tPrefix)
		If $$$ISERR(tSC) Quit
		
		Set tSC=tImporter.ImportFREEFORM(pDirectoryName_"FREEFORM_X220.TXT",tPrefix)
		If $$$ISERR(tSC) Quit
		
		Set tSC=tImporter.ImportSEGHEAD(pDirectoryName_"SEGHEAD.TXT",tPrefix)
		If $$$ISERR(tSC) Quit
		
		Set tSC=tImporter.ImportSEGHEAD(pDirectoryName_"SEGHEAD_X12.TXT",tPrefix)
		If $$$ISERR(tSC) Quit
		
		Set tSC=tImporter.ImportSEGHEAD(pDirectoryName_"SEGHEAD_X220.TXT",tPrefix)
		If $$$ISERR(tSC) Quit
		
		Set tSC=tImporter.ImportCOMHEAD(pDirectoryName_"COMHEAD.TXT",tPrefix)
		If $$$ISERR(tSC) Quit
		
		Set tSC=tImporter.ImportCOMHEAD(pDirectoryName_"COMHEAD_X220.TXT",tPrefix)
		If $$$ISERR(tSC) Quit
		
		Set tSC=tImporter.ImportELEHEAD(pDirectoryName_"ELEHEAD.TXT",tPrefix)
		If $$$ISERR(tSC) Quit
		
		Set tSC=tImporter.ImportELEHEAD(pDirectoryName_"ELEHEAD_X12.TXT",tPrefix)
		If $$$ISERR(tSC) Quit
		
		Set tSC=tImporter.ImportELEHEAD(pDirectoryName_"ELEHEAD_X220.TXT",tPrefix)
		If $$$ISERR(tSC) Quit
		
		Set tSC=tImporter.GenerateBHT()
		If $$$ISERR(tSC) Quit
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method ImportFREEFORM(pFileName As %String, pPrefix As %String) As %Status
{

	#; File: FREEFORM.TXT
	Set $ZT="Trap",tSC=$$$OK
	do {
		
		#; Create the file character stream
		Set tStream=##class(%FileCharacterStream).%New()
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		
		#; Set the file name
		Set tStream.Filename=pFileName
		
		While 'tStream.AtEnd
		{
			Set tLine=tStream.ReadLine() If tLine=$Char(26) Quit
			While $Extract(tLine,1,7)="*ELEDEF"
			{
				#; Element Code Definition
				Set tCode=$ZSTRIP(tStream.ReadLine(),"<>W"),tText=""
				
				do {
					If tStream.AtEnd Quit
					Set tLine=tStream.ReadLine()
					If $Extract(tLine)="*" Quit
					Set tText=tText_tLine
				} while 1
				Set $$$vaSchemaDescGbl("X",pPrefix,"CODES",tCode)=tText
				If tStream.AtEnd Quit
			}
		}
		
		Do tStream.Rewind()
		While 'tStream.AtEnd
		{
			Set tLine=tStream.ReadLine() If tLine=$Char(26) Quit
			While $Extract(tLine,1,7)="*ELECOD"
			{
				#; Element Code Definition
				Set tLine=tStream.ReadLine()
				Set tCode=$Piece(tLine,","),tValue=$Piece(tLine,",",3),tText=""
				do {
					If tStream.AtEnd Quit
					Set tLine=tStream.ReadLine()
					If $Extract(tLine)="*" Quit
					Set tText=tText_tLine
				} while 1
				Set $$$vaSchemaDescGbl("X",pPrefix,"CODES",tCode,tValue)=tText
				If tStream.AtEnd Quit
			}
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method ImportSETHEAD(pFileName As %String, pPrefix As %String) As %Status
{

	#; File: SETHEAD.TXT
  	#; Fields: Transaction Set ID, Transaction Set Name, Functional Group ID
  	#; Lengths: 6, 80, 2
  	#; Example: "810-A1","Invoice","HC"
	Set $ZT="Trap",tSC=$$$OK
	do {
		
  		#; Fields: 	Transaction Set ID, Transaction Set Name, Functional Group ID
  		#; Lengths: 6, 80, 2
  		#; Example: "810-A1","Invoice","HC"

		#; Create the file character stream
		Set tStream=##class(%FileCharacterStream).%New()
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		
		#; Set the file name
		Set tStream.Filename=pFileName
		
		While 'tStream.AtEnd
		{
			#; Read in a line and strip quotes,whitespace
			Set tLine=tStream.ReadLine() If tLine=$Char(26) Quit
			Do ..Split(tLine,.tItems)
			
			$$$ASSERTNOLOG(tItems=3)
			
			Set $$$vaSchemaDescGbl("X",pPrefix,"SET",tItems(1),"Name")=tItems(2),^("Group")=tItems(3)
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method ImportSETDETL(pFileName As %String, pPrefix As %String) As %Status
{
  	Set $ZT="Trap",tSC=$$$OK
	do {		
		#; Fields: 	Transaction Set ID, Area, Sequence, Segment ID, Requirement, 
    	#; Maximum 	Use, Loop Level, Loop Repeat, Loop Identifier
    	#; Lengths: 6, 1, 3, 3, 1, 6, 1, 6, 6
    	#; Example: "810-A1","2","010","IT1","O","1","1","200000","IT1"
    	
    	#; Create the file character stream
		Set tStream=##class(%FileCharacterStream).%New()
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		
		#; Set the file name
		Set tStream.Filename=pFileName
		
		While 'tStream.AtEnd
		{
			#; Read in a line and strip quotes,whitespace
			Set tLine=tStream.ReadLine() If tLine=$Char(26) Quit
			Do ..Split(tLine,.tItems)
			
			$$$ASSERTNOLOG(tItems=9)
			
			Set $$$vaSchemaDescGbl("X",pPrefix,"SET",tItems(1),tItems(2),tItems(3),tItems(4),"Requirement")=tItems(5)
			Set ^("MaxUse")=tItems(6),^("LoopLevel")=tItems(7),^("LoopRepeat")=tItems(8),^("LoopID")=tItems(9)
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method ImportSEGHEAD(pFileName As %String, pPrefix As %String) As %Status
{
  	Set $ZT="Trap",tSC=$$$OK
	do {
		
		#; Fields: Segment ID, Segment Name
    	#; Lengths: 3, 80
    	#; Example: "A1","Rejection" 
		
		#; Create the file character stream
		Set tStream=##class(%FileCharacterStream).%New()
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		
		#; Set the file name
		Set tStream.Filename=pFileName
		
		While 'tStream.AtEnd
		{
			#; Read in a line and strip quotes,whitespace
			Set tLine=tStream.ReadLine() If tLine=$Char(26) Quit
			Do ..Split(tLine,.tItems)
			
			$$$ASSERTNOLOG(tItems=2)
				
			Set $$$vaSchemaDescGbl("X",pPrefix,"SEG",tItems(1))=tItems(2)
		}
		} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method ImportSEGDETL(pFileName As %String, pPrefix As %String) As %Status
{
  	Set $ZT="Trap",tSC=$$$OK
	do {

		#; Fields:  Segment ID, Sequence, Element/CompositeID, Requirement
    	#; Lengths: 3, 2, 4, 1
    	#; Example: "A1","01","131","M"
    	#; 
    	#; #; Create the file character stream
		Set tStream=##class(%FileCharacterStream).%New()
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		
		#; Set the file name
		Set tStream.Filename=pFileName
		
		While 'tStream.AtEnd
		{
			#; Read in a line and strip quotes,whitespace
			Set tLine=tStream.ReadLine() If tLine=$Char(26) Quit
			Do ..Split(tLine,.tItems)
			
			$$$ASSERTNOLOG(tItems=4)
			
			#; e|ID|ORDINAL|USRREQ|STDREQ|ACTREQ|TYPE|MIN|MAX|REPEAT
			Set tElementData=$Get($$$vaSchemaDescGbl("X",pPrefix,"e",tItems(3),"type"),"||")
			
			Set $$$vaSchemaDescGbl("X",pPrefix,"s",tItems(1),+tItems(2))=tType_"|"_tItems(3)_"|"_+tItems(2)_"|"_tItems(4)_"|"_tItems(4)_"|"_tItems(4)_"|"_tElementData_"|1"
		}
    
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method ImportCOMHEAD(pFileName As %String, pPrefix As %String) As %Status
{
	
  	Set $ZT="Trap",tSC=$$$OK
	do {
		
		#; Fields:  Composite Data Element Number, Composite Name
		#; Lengths: 4, 80
  		#; Example: "C002","Document/message name"
		
		#; Create the file character stream
		Set tStream=##class(%FileCharacterStream).%New()
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		
		#; Set the file name
		Set tStream.Filename=pFileName
		
		While 'tStream.AtEnd
		{
			#; Read in a line and strip quotes,whitespace
			Set tLine=tStream.ReadLine() If tLine=$Char(26) Quit
			Do ..Split(tLine,.tItems)
			
			$$$ASSERTNOLOG(tItems=2)
			
			Set $$$vaSchemaDescGbl("X",pPrefix,"COMP",tItems(1))=tItems(2)
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method ImportCOMDETL(pFileName As %String, pPrefix As %String) As %Status
{
  	Set $ZT="Trap",tSC=$$$OK
	do {

		#; Fields:  Composite Data Element Number, Sequence, Data Element
    	#; Number, Requirement
    	#; Lengths: 4, 2, 4, 1
    	#; Example: "C002","01","1001","C"
    	 
    	#; Create the file character stream
		Set tStream=##class(%FileCharacterStream).%New()
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		
		#; Set the file name
		Set tStream.Filename=pFileName
		
		While 'tStream.AtEnd
		{
			#; Read in a line and strip quotes,whitespace
			Set tLine=tStream.ReadLine() If tLine=$Char(26) Quit
			Do ..Split(tLine,.tItems)
			
			$$$ASSERTNOLOG(tItems=4)
			
			Set $$$vaSchemaDescGbl("X",pPrefix,"COM",tItems(1),+tItems(2),"Element")=tItems(3),^("Requirement")=tItems(4)
		}

	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method ImportELEHEAD(pFileName As %String, pPrefix As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
	
		#; Fields:  Data Element Number, Data Element Name
    	#; Lengths: 4, 80
    	#; Example: "1","Route Code
  	
		#; Create the file character stream
		Set tStream=##class(%FileCharacterStream).%New()
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		
		#; Set the file name
		Set tStream.Filename=pFileName
		
		While 'tStream.AtEnd
		{
			#; Read in a line and strip quotes,whitespace
			Set tLine=tStream.ReadLine() If tLine=$Char(26) Quit
			Do ..Split(tLine,.tItems)
			
			$$$ASSERTNOLOG(tItems=2)
			
			Set $$$vaSchemaDescGbl("X",pPrefix,"ELEM",tItems(1))=tItems(2)
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method ImportELEDETL(pFileName As %String, pPrefix As %String) As %Status
{
  	Set $ZT="Trap",tSC=$$$OK
	do {

		#; Fields:  Data Element Number, Data Element Type, Minimum Length, Maximum Length
    	#; Lengths: 4, 2, 6, 6
    	#; Example: "1","AN","1","13"
    	#; 
    	#; Create the file character stream
		Set tStream=##class(%FileCharacterStream).%New()
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		
		#; Set the file name
		Set tStream.Filename=pFileName
		
		While 'tStream.AtEnd
		{
			#; Read in a line and strip quotes,whitespace
			Set tLine=tStream.ReadLine() If tLine=$Char(26) Quit
			Do ..Split(tLine,.tItems)
			
			$$$ASSERTNOLOG(tItems=4)
			
			Set tData=$$$vaSchemaDescGbl("X",pPrefix,"e",tItems(1)),tID=$List(tData,2),tName=$List(tData,3)
			Kill $$$vaSchemaDescGbl("X",pPrefix,"e",tItems(1))
			
			#; $$$vaSchemaDescGbl("X",pPrefix,"e",elementid,"name")=display name
			Set $$$vaSchemaDescGbl("X",pPrefix,"e",tItems(1),"name")=tName
			
			#; $$$vaSchemaDescGbl("X",pPrefix,"x","displayname")=elementid
			Set $$$vaSchemaDescGbl("X",pPrefix,"x",tName)=tItems(1)
			
			#; $$$vaSchemaDescGbl("X",pPrefix,"e",elementid,"type")=datatype,minlength,maxlength
			Set $$$vaSchemaDescGbl("X",pPrefix,"e",tItems(1),"type")=tItems(2)_"|"_tItems(3)_"|"_tItems(4)
		}

	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method ImportCONDETL(pFileName As %String, pPrefix As %String) As %Status
{
  	Set $ZT="Trap",tSC=$$$OK
	do {
	
		#; Fields:  Record Type, Transaction Set ID, Area, Sequence, Segment ID,
    	#;          Reference Designator, Composite ID, Composite Sequence,
    	#;          Data Element Number, Code, Table, Position, Usage
    	#; Lengths: 1, 6, 1, 3, 3, 2, 4, 2, 4, 6, 1, 3, 1
    	#; Example: "E","857-U1","4","310","MAN","01","","","88","GM","","","2"

		#; Create the file character stream
		Set tStream=##class(%FileCharacterStream).%New()
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		
		#; Set the file name
		Set tStream.Filename=pFileName
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method ImportCONTEXT(pFileName As %String, pPrefix As %String) As %Status
{
	
  	Set $ZT="Trap",tSC=$$$OK
	do {
	
		#; Fields:  Record Type, Transaction Set ID, Area, Sequence, Segment ID,
    	#;          Reference Designator, Composite ID, Composite Sequence,
    	#;          Data Element Number, Code, Table, Position, Note Number,
    	#;          Note Type, Note
    	#; Lengths: 1, 6, 1, 3, 3, 2, 4, 2, 4, 6, 1, 3, 9, 1, 4096
    	#; Example: "E","830","2","410","FST","02","","","680","Q","","","5384",""
   
		#; Create the file character stream
		Set tStream=##class(%FileCharacterStream).%New()
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		
		#; Set the file name
		Set tStream.Filename=pFileName
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method ImportDED(pFileName As %String, pPrefix As %String) As %Status
{
	
  	Set $ZT="Trap",tSC=$$$OK
	do {
	
		#; Fields: UniqueID,element name, description
    	#; Lengths: 1, 64, 4096
    	#; Example: "2","Account Number Qualifier","Code indicating the type of account"
    
		#; Create the file character stream
		Set tStream=##class(%FileCharacterStream).%New()
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		
		#; Set the file name
		Set tStream.Filename=pFileName
		
		While 'tStream.AtEnd
		{
			#; Read in a line and strip quotes,whitespace
			Set tLine=tStream.ReadLine() If tLine=$Char(26) Quit
			Do ..Split(tLine,.tItems)
			
			$$$ASSERTNOLOG(tItems=3)
			
			Set $$$vaSchemaDescGbl("X",pPrefix,"DED",tItems(1),"Name")=tItems(2),^("Description")=tItems(3)
		}
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

Method ImportCONTROL(pFileName As %String, pPrefix As %String) As %Status
{
  	Set $ZT="Trap",tSC=$$$OK
	do {
	
		#; Fields:  Segment ID, Ordinal, Element ID, Code Value, Code Text
    	#; Example: "ISA","01",I01","00","No Security Information Present"

		#; Create the file character stream
		Set tStream=##class(%FileCharacterStream).%New()
		If '$IsObject(tStream) Set tSC=%objlasterror Quit
		
		#; Set the file name
		Set tStream.Filename=pFileName
		
		While 'tStream.AtEnd
		{
			#; Read in a line and strip quotes,whitespace
			Set tLine=tStream.ReadLine() If tLine=$Char(26) Quit
			Do ..Split(tLine,.tItems)
			
			$$$ASSERTNOLOG(tItems=5)
			
			Set tSegmentID=tItems(1),tOrdinal=tItems(2),tElementID=tItems(3),tCode=tItems(4),tText=tItems(5)
			If tCode'="" {
				Set $$$vaSchemaDescGbl("X",pPrefix,"c",tSegmentID,+tOrdinal,tCode)=tText
			}
		}
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	Goto Exit
}

ClassMethod Load()
{
	Set tSC=$$$OK
	do {
		Kill $$$vaSchemaDescGbl,$$$vaSchemaGbl
		
		Set tSC=..Import($Get(^ClearCase,"m:\")_"packages\EDI\data\X12\")
		If $$$ISERR(tSC) Quit
	
		Set Refs("$$$vaSchemaGbl.GBL")=""
		
		Set tSC=..ImportControlSegments($Get(^ClearCase,"m:\")_"packages\EDI\data\SEF\")
		If $$$ISERR(tSC) Quit
	
		Set Refs("$$$vaSchemaDescGbl.GBL")=""
		
		Do $system.OBJ.Export(.Refs,$Get(^ClearCase,"m:\")_"packages\EDI\gbl\X12.XML")
		
	} while (0)
	If $$$ISERR(tSC) Do $System.Status.DisplayError(tSC)
}

/// Split Comma Seperated Values into Items array with conversion
ClassMethod Split(pCSV As %String, Output pItems As %String)
{
	Kill pItems Set tInQuotes=0,tStart=1,pItems=0
	For tI=1:1:$Length(pCSV)+1 {
		If $Extract(pCSV,tI)="""" {
			Set tInQuotes='tInQuotes
		} else {
			If tInQuotes=0 {
				
				If (($Extract(pCSV,tI)=",")||($Extract(pCSV,tI)=""))
				{
					#; Strip Quotes,leading and trailing whitespace
					Set tItem=$ZSTRIP($Translate($Extract(pCSV,tStart,tI-1),""""),"<>W")
					
					Set pItems($Increment(pItems))=tItem
					Set tStart=tI+1
				}
			}
		}
	}
}

/// Mangle a text string to form a macro name
Method TextToMacro(pText As %String, pMaxLen = 32) As %String
{
	#; Remove Spaces,punctuation
	Set pText=$Translate(pText," ~`!@#$%^&*()_-+{}|""'`:;<>,.?/")
	If $Length(pText)>pMaxLen {
		Set tVC=0,tLen=$Length(pText)
		For tI=tLen:-1:1 {
			If tLen-tVC=pMaxLen Quit
			If "AEIOUaeiou"[$Extract(pText,tI)||($ZName($Extract(pText,tI))=0)
			{
				Set $Extract(pText,tI)="+",tVC=tVC+1
			}
		}
		Set pText=$Translate(pText,"+")
	}
	Quit "$$$"_pText
}

/// Loads the Intersystems Control Segment Definitions
ClassMethod ImportControlSegments(pDirectory As %String) As %Status
{
	Set $ZT="Trap",tSC=$$$OK
	do {
		#; Create an instance of the compiler
		Set tCompiler=##class(EnsLib.EDI.SEF.Compiler).%New()
		If '$IsObject(tCompiler) Set tSC=%objlasterror Quit
		
		For tVersion="ISC_00401","ISC_00405" {
			Kill $$$vaSchemaGbl(tVersion)
			Set tFilename=$Get(pFilename,pDirectory_tVersion_".SEF")
			Set tSC=tCompiler.Compile(tFilename,.tDocKey,.pValidationErrors)
			If $$$ISERR(tSC) Quit
		}
		Quit
		
	} while (0)
Exit
	Quit tSC
Trap
	Set $ZT="",tSC=$$$ERROR($$$ObjectScriptError,$ZE)
	Goto Exit
}

/// There is a hierarch linking the 1005 code values and the 735 codes. These must be
/// co-related to provide instructions for parsing hierarchical transactions
ClassMethod GenerateBHT() As %Status
{
	Set tSC=$$$OK Do
	{
		#; Delete any pre-existing data
		Kill $$$vaSchemaDescGbl("X","X12","HL")
		
		#; Walk through the list of 1005 codes
		Set tCode1005="" For {
			
			Set tCode1005=$Order($$$vaSchemaDescGbl("X","X12","CODES",1005,tCode1005),1,tCode1005Value) 
			If tCode1005="" Quit
			
			#; Split the code value into separate items
			Do ..Split(tCode1005Value,.tCode735Values)
			
			#; Now for each item, discover the corresponding 275 code and create the hierarchical structure
			For tI=1:1:tCode735Values {
				
				#; Get the item
				Set tCode735Value=$Piece(tCode735Values(tI)," (")
				
				#; Search for the corresponding 735
				Set tFound=0 Set tCode735="" For {
					
					Set tCode735=$Order($$$vaSchemaDescGbl("X","X12","CODES",735,tCode735),1,tCode735MatchValue)
					If tCode735="" Quit
					
					If tCode735Value=tCode735MatchValue {
						Set tFound=1,$$$vaSchemaDescGbl("X","X12","HL",tCode1005,$Increment($$$vaSchemaDescGbl("X","X12","HL",tCode1005)))=tCode735 Quit
					}
				}
				// If 'tFound Write "Warning - CODE 1005/735 Correspondence NOT found for "_tCode1005_" "_tCode1005Value,!
			}
		}
	} while (0)
	Quit tSC
}

}
