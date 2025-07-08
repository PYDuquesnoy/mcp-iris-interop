/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occIO

/// Abstract implementation class providing methods used by MetaStreams to wrapper one or more %IO streams, %Library streams or %Stream streams.
Class %IO.IParts.MetaIO [ Abstract, System = 2 ]
{

/// Read from another stream whenever there's a Read
/// %IO.I.Stream or %Stream.Object
Property StreamIn As %IO.I.Stream;

/// Write to other streams whenever there's a Read
/// *IO.I.Stream or %Stream.Object; indexed by oref to avoid duplicates */
Property StreamsCopyInput As %ArrayOfObjects;

/// Write to other streams whenever there's a Write
/// %IO.I.Stream or %Stream.Object; indexed by oref to avoid duplicates */
Property StreamsOutput As %ArrayOfObjects;

Property WriteToStreamIn As %Boolean [ InitialExpression = 0 ];

Property %Position As %Integer [ Private, ReadOnly ];

Method %OnNew(pBaseStream As %IO.I.Stream = "") As %Status
{
	if ""'=pBaseStream {
		If '$IsObject(pBaseStream) {
			Set pBaseStream=$classmethod(pBaseStream,"%New")
		}
		Do ..BindInput(pBaseStream, .tSC) Quit:$$$ISERR(tSC) tSC
		Set tSC = ..BindOutput(pBaseStream) Quit:$$$ISERR(tSC) tSC
	}
	Quit $$$OK
}

Method Close(Output pSC As %Status) As %Boolean
{
	Set pSC=$$$OK  Quit 1
}

Method Reset(pStream As %IO.I.Stream = {$$$NULLOREF}, pTimeout As %Numeric, Output pSC As %Status)
{
	Set ..StreamIn=$$$NULLOREF
	Set pSC=..StreamsOutput.Clear()  Quit:$$$ISERR(pSC)
	Set pSC=..StreamsCopyInput.Clear()  Quit:$$$ISERR(pSC)
	Do:$IsObject(pStream) ..BindInput(pStream),..BindOutput(pStream)
}

Method BindInput(pInputStream As %IO.I.Stream, Output pSC As %Status)
{
	Set pSC = $$$OK
	Set ..StreamIn = pInputStream
}

Method BindOutput(pOutputStreams...) As %Status
{
	Quit ..BindOutputArray(.pOutputStreams)
}

Method BindOutputArray(ByRef pOutputStreams) As %Status
{
	Set pSC = $$$OK
	For i=1:1:pOutputStreams { Do ..StreamsOutput.SetAt(pOutputStreams(i),pOutputStreams(i)) }
	Quit pSC
}

Method BindCopyInput(pOutputStreams...) As %Status
{
	Quit ..BindCopyInputArray(.pOutputStreams)
}

Method BindCopyInputArray(ByRef pOutputStreams) As %Status
{
	Set pSC = $$$OK
	For i=1:1:pOutputStreams { Do ..StreamsCopyInput.SetAt(pOutputStreams(i),pOutputStreams(i)) }
	Quit pSC
}

Method Read(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %String
{
	If '$IsObject(..StreamIn) Set pSC=$$$ERROR($$$ErrIONoDelegatedStream),pTimeout=0 Quit
	Set tIn = ..delegateRead(..StreamIn,.pMaxReadLen,.pTimeout,.pSC)
	Quit:""=tIn||$$$ISERR(pSC) tIn
	Set i%%Position=..Position+$L(tIn)

	#; copy to the BindCopyInput output streams
	Set k="" While 1 { Set k=..StreamsCopyInput.Next(k)  Quit:""=k  Set s=..StreamsCopyInput.GetAt(k)
		Do ..delegateWrite(s,tIn,,.pSC)
	}
	Quit tIn
}

Method Write(pData As %String = "", pFlush As %Boolean, Output pSC As %Status)
{
	Set pSC = $$$OK
	If ..WriteToStreamIn {
		Do ..delegateWrite(..StreamIn,pData,.pFlush,.pSC)
	}
	Quit:$$$ISERR(pSC)
	Set i%%Position=..Position+$L(pData)
	
	#; copy to the BindOutput output streams
	Set k="" for i=0:1 { Set k=..StreamsOutput.Next(k)  Quit:""=k  Set s=..StreamsOutput.GetAt(k)
		Do:s'=..StreamIn||'..WriteToStreamIn ..delegateWrite(s,pData,.pFlush,.pSC)
	}
	Set:i=0&&$$$ISOK(pSC)&&'..WriteToStreamIn pSC=$$$ERROR($$$ErrIONoDelegatedStream)
}

Method delegateWrite(s As %RegisteredObject, pData As %String, ByRef pFlush As %Boolean, Output pSC As %Status) [ Private ]
{
	If s.%Extends("%IO.I.Stream") { Do s.Write(pData,.pFlush,.pSC) }
	ElseIf s.%Extends("%Stream.Object") { Set pSC=s.Write(pData) Quit:$$$ISERR(pSC)  Do:$G(pFlush,0) s.Flush() }
	Else { Set pSC=$$$ERROR($$$ErrIONotStream,s.%ClassName(1)) }
}

Method Flush(Output pSC As %Status)
{
	#; flush the BindOutput output streams
	Do:..WriteToStreamIn&&($$$NULLOREF=..StreamsOutput.GetAt(..StreamIn)) ..StreamIn.Flush(.pSC)
	Do ..flushList(.pSC,..StreamsOutput,1)
}

Method FlushCopyInput(Output pSC As %Status)
{
	#; flush the BindCopyInput output streams
	Do ..flushList(.pSC,..StreamsCopyInput,1)
}

Method flushList(Output pSC As %Status, pList As %ArrayOfObjects, pFlush As %Boolean) [ Private ]
{
	Set pSC = $$$OK
	Quit:'$G(pFlush,1)
	Set k="" for i=0:1 { Set k=pList.Next(k)  Quit:""=k  Set s=pList.GetAt(k)
		If s.%Extends("%IO.I.Stream") { Do:$G(pFlush,s.DefaultFlushOnWrite) s.Flush(.pSC) }
		ElseIf s.%Extends("%Stream.Object") { Set:$G(pFlush) pSC=s.Flush() }
		Else { Set pSC=$$$ERROR($$$ErrIONotStream,s.%ClassName(1)) }
		Quit:$$$ISERR(pSC)
	}
	Set:i=0&&$$$ISOK(pSC) pSC=$$$ERROR($$$ErrIONoDelegatedStream)
}

Method Rewind(Output pSC As %Status)
{
	If '$IsObject(..StreamIn) Set pSC=$$$ERROR($$$ErrIONoDelegatedStream) Quit
	If ..StreamIn.%Extends("%Stream.Object") { Set pSC=..StreamIn.Rewind() Set:$$$ISOK(pSC) i%%Position=1 }
	ElseIf ..StreamIn.%Extends("%IO.I.Stream") {
		If '..StreamIn.%Extends("%IO.IParts.SeekableIO")  Set pSC=$$$ERROR($$$ErrIODelegatedNotSeekable) Quit
		Do ..StreamIn.Rewind(.pSC) Set i%%Position=1
	}
	Else { Set pSC=$$$ERROR($$$ErrIONotStream,..StreamIn.%ClassName(1)) }
}

Method Seek(pPosition As %Integer, Output pSC As %Status) As %Boolean
{
	If '$IsObject(..StreamIn) Set pSC=$$$ERROR($$$ErrIONoDelegatedStream) Quit 0
	If ..StreamIn.%Extends("%Stream.Object") { Set pSC=..StreamIn.MoveTo(pPosition)  Quit:$$$ISERR(pSC) 0  Set:pPosition'=..Position ..WriteToStreamIn=1 Set i%%Position=pPosition  Quit 1 }
	If ..StreamIn.%Extends("%IO.I.Stream") {
		If '..StreamIn.%Extends("%IO.IParts.SeekableIO")  Set pSC=$$$ERROR($$$ErrIODelegatedNotSeekable) Quit 0
		Set tOldPos=..StreamIn.Position
		Set tOK = ..StreamIn.Seek(pPosition,.pSC)
		Set:pPosition'=tOldPos&&$$$ISOK(pSC) ..WriteToStreamIn=1 ; Write after Seek() must go to StreamIn
		Quit tOK
	}
	Else { Set pSC=$$$ERROR($$$ErrIONotStream,..StreamIn.%ClassName(1))  Quit 0}
}

Method AtEndGet() As %Boolean [ CodeMode = expression ]
{
$S($IsObject(..StreamIn):..StreamIn.AtEnd,1:1)
}

Method IsOpenGet() As %Boolean [ CodeMode = expression ]
{
$S($IsObject(..StreamIn):..StreamIn.IsOpen,1:0)
}

Method SizeGet() As %Integer
{
	If '$IsObject(..StreamIn) Set pSC=$$$ERROR($$$ErrIONoDelegatedStream) Quit 0
	If ..StreamIn.%Extends("%Stream.Object") { Quit ..StreamIn.Size }
	If ..StreamIn.%Extends("%IO.I.Stream") {
		If '..StreamIn.%Extends("%IO.IParts.SeekableIO")  Set pSC=$$$ERROR($$$ErrIODelegatedNotSeekable) Quit 0
		Quit ..StreamIn.Size
	}
	Else { Set pSC=$$$ERROR($$$ErrIONotStream,..StreamIn.%ClassName(1)) Quit 0 }
}

Method PositionGet() As %Integer
{
	If '$IsObject(..StreamIn) Set pSC=$$$ERROR($$$ErrIONoDelegatedStream) Quit 0
	If ..StreamIn.%Extends("%Stream.Object") { Quit ..Position }
	If ..StreamIn.%Extends("%IO.I.Stream") {
		If '..StreamIn.%Extends("%IO.IParts.SeekableIO")  Set pSC=$$$ERROR($$$ErrIODelegatedNotSeekable) Quit 0
		 Quit ..StreamIn.Position
	}
	Else { Set pSC=$$$ERROR($$$ErrIONotStream,..StreamIn.%ClassName(1)) Quit 0 }
}

Method CopyFrom(pSource As %IO.I.Stream, ByRef pTimeout As %Numeric = -1, pFlush As %Boolean, Output pSC As %Status) As %Integer
{
	Quit:pSource=$$$NULLOREF $$$ERR($$$OrefInvalid)
	Set pSC=$$$OK
	Set total=0 For  Quit:(pSource.AtEnd)!($$$ISERR(pSC))  Set tData=..delegateRead(pSource,,.pTimeout,.pSC) Quit:$$$ISERR(pSC)  Do ..Write(tData,0,.pSC) Quit:$$$ISERR(pSC)  Set total=total+$L(tData)
	If $$$ISOK(pSC) {
		If $D(pFlush) { Do:pFlush ..Flush(.pSC) }
		Else { Do ..flushList(.pSC,..StreamsOutput,) }
	}
	Quit total
}

}
