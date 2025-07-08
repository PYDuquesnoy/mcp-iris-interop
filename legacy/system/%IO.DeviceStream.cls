/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %IO.DeviceStream Extends (%IO.I.CharacterStream, %IO.I.TranslationDevice) [ Inheritance = right, System = 2 ]
{

Property %Attached As %Boolean [ Private, ReadOnly, Transient ];

Property %CurrLineTerminator As %String [ Private, ReadOnly, Transient ];

Method DefaultFlushOnWriteGet() [ CodeMode = expression ]
{
..Name["|TCP|"
}

/// Attach the current $IO device to an instance of this class
ClassMethod AttachNew(pDevice As %String = {$IO}, Output pSC As %Status) As %IO.DeviceStream
{
	Set tStream = ..%New()  If '$IsObject(tStream) Set pSC = %objlasterror  Quit
	Do tStream.Attach(pDevice,.pSC)
	Quit tStream
}

/// Attach to the named open Device or to the current Device by default
Method Attach(pDevice As %String = {$IO}, Output pSC As %Status)
{
	Set tIO = $IO
	If pDevice'=tIO {
		Set $ZT="UseTrap"
		Use pDevice
		Use tIO
		Set $ZT=""
	}
	Set tLineTerm = ..GetDeviceLineTerminator(pDevice)
	Set:""'=tLineTerm i%LineTerminator=tLineTerm, i%%CurrLineTerminator=tLineTerm
	Set i%TranslationTable = ..GetDeviceTranslationTable(pDevice)
	Set i%CharEncoding = ..GetTableCharEncoding(i%TranslationTable)
	Set ..Name=pDevice,i%IsOpen=1,i%AtEnd=0,i%%Attached=1,pSC = $$$OK
	Quit
UseTrap
	Set $ZT="",tZE=$ZE,pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Quit
}

Method CharEncodingSet(pCharEncoding As %String) As %Status
{
	Quit:i%CharEncoding=pCharEncoding $$$OK
	Set tEncoding=$Case($ZCVT(pCharEncoding,"L"),
		"":"RawBytes",
		"bin":"RawBytes",
		"binary":"RawBytes",
		"raw":"RawBytes",
		:pCharEncoding)
	Set tSC=..SetCharEncodingTable(tEncoding,pCharEncoding)
	Set:$$$ISOK(tSC) i%CharEncoding=tEncoding
	Quit tSC
}

Method TranslationTableSet(pTable As %String) As %Status
{
	Set tSC=..SetTranslationTable(.pTable)
	Set:$$$ISOK(tSC) i%CharEncoding = ..GetTableCharEncoding(i%TranslationTable)
	Quit tSC
}

Method initDeviceTranslationTable(Output pSC As %Status) [ Private ]
{
	If ""=..TranslationTable { Set pSC=$$$OK, i%TranslationTable=..GetDeviceTranslationTable(..Name) }
	Else { Do ..SetDeviceTranslationTable(..Name, ..TranslationTable,.pSC) } ; Set the Translation table derived from our CharEncoding if any
}

Method Close(Output pSC As %Status) As %Boolean
{
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name) Quit 0
	Set $ZT="Trap",pSC=$$$OK
	Close ..Name
Trap
	Set $ZT=""
	Set i%IsOpen=0,i%AtEnd=1,i%TranslationTable=""
	Quit 1
}

Method %OnClose() As %Status [ Private ]
{
	Do:'..%Attached&&..IsOpen ..Close()
	Quit $$$OK
}

Method Write(pData As %String = "", pFlush As %Boolean = {..DefaultFlushOnWrite}, Output pSC As %Status)
{
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name) Quit
	Set pSC=$$$OK,$ZT="Trap",tIO=$IO  Use ..Name  Write pData  Write:pFlush&&(..Name["|TCP|") *-3  Use tIO
	Quit
Trap
	Set $ZT="",tZE=$ZE, pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Use tIO
	Quit
}

Method Flush(Output pSC As %Status)
{
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name) Quit
	Set pSC=$$$OK
	Quit:..Name'["|TCP|"
	Set tIO=$IO,$ZT="Trap"
	Use ..Name  Write *-3
Exit	
	Use tIO	Quit pSC
Trap
	Set $ZT="",tZE=$ZE,pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	If ..isWriteError(tZE) {
		If ..%Extends("%IO.IParts.ServerSocketIO") Do $method($this,"Disconnect")
		Else  Do ..Close()
	}
	Goto Exit
}

Method Read(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %String
{
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name) Quit ""
	Set pSC=$$$OK, tMaxLen=$$$MaxLocalLength  Set:""=$G(pMaxReadLen)||(pMaxReadLen>tMaxLen) pMaxReadLen=tMaxLen
	If 0=pMaxReadLen||..AtEnd Set pTimeout=0 Quit ""
	
	Set tEOFMode=$ZU(68,40) Do $ZU(68,40,1)
	Set tIO=$IO,tData=""
	Set $ZT="Trap" Use ..Name
	If ..%CurrLineTerminator'="" Do ..SetDeviceLineTerminator(..Name,"",.pSC) Quit:$$$ISERR(pSC)  Set i%%CurrLineTerminator=""
	If -1=pTimeout { Read tData#pMaxReadLen  Set tOK=1 }
	Else { Read tData#pMaxReadLen:pTimeout  Set tOK=$Test }
	Set:$ZEOF i%AtEnd=1
	Set:tOK||..AtEnd pTimeout=0
Exit
	Use tIO
	Do:$G(tEOFMode) $ZU(68,40,tEOFMode)
	Quit tData
Trap
	Set $ZT="",tZE=$ZE
	If $E($g(tZE),1,11)="<ENDOFFILE>" Set i%AtEnd=1  Goto Exit
	Set pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Set pTimeout=0
	Goto Exit
}

Method ReadLine(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric = -1, Output pSC As %Status, ByRef pLineTerminator As %String = {..LineTerminator}) As %String
{
	If '..IsOpen Set pSC = $$$ERROR($$$FileNotOpen,..Name) Quit ""
	Set pSC=$$$OK, tZB=pLineTerminator, pLineTerminator=""
	Set tMaxLen=$$$MaxLocalLength  Set:""=$G(pMaxReadLen)||(pMaxReadLen>tMaxLen) pMaxReadLen=tMaxLen
	If 0=pMaxReadLen||..AtEnd Set pTimeout=0 Quit ""
	
	Set tEOFMode=$ZU(68,40) Do $ZU(68,40,1)
	Set tIO=$IO,tData=""
	Set $ZT="Trap"
	If ..%CurrLineTerminator'=tZB Do ..SetDeviceLineTerminator(..Name,tZB,.pSC) Quit:$$$ISERR(pSC)  Set i%%CurrLineTerminator=tZB
	Use ..Name
	If -1=pTimeout { Read tData#pMaxReadLen  Set tOK=1 }
	Else { Read tData#pMaxReadLen:pTimeout  Set tOK=$Test }
	Set pLineTerminator=$ZB
	Set:$ZEOF i%AtEnd=1
	Set:tOK||..AtEnd pTimeout=0
Exit
	Use tIO
	Do:$G(tEOFMode) $ZU(68,40,tEOFMode)
	Quit tData
Trap
	Set $ZT="",tZE=$ZE
	If $E($g(tZE),1,11)="<ENDOFFILE>" Set i%AtEnd=1  Goto Exit
	Set pSC=$$$ERROR($$$ObjectScriptError,$g(tZE))
	Set pTimeout=0
	Goto Exit
}

ClassMethod isReadError(pZE As %String) As %Boolean [ CodeMode = expression, Private ]
{
pZE["<READ>"
}

ClassMethod isWriteError(pZE As %String) As %Boolean [ CodeMode = expression, Private ]
{
pZE["<WRITE>"
}

}
