/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %occIO

/// Abstract base class of all streams
/// The methods of this class work for both Byte and Character streams
Class %IO.I.Stream Extends %RegisteredObject [ Abstract, System = 2 ]
{

Property IsOpen As %Boolean [ InitialExpression = 0, ReadOnly ];

Property Name As %String(MAXLEN = 500, TRUNCATE = 1);

/// InputStream interface
/// 
/// Does this class flush after writes by default?
Property DefaultFlushOnWrite As %Boolean [ Calculated, ReadOnly ];

Method DefaultFlushOnWriteGet() [ CodeMode = expression ]
{
0
}

Property AtEnd As %Boolean [ InitialExpression = 1, ReadOnly ];

Property IsCharacter As %Boolean [ Calculated, ReadOnly ];

/// Read until pMaxReadLen chars are gotten or pTimeout expires
/// On return, if pTimeout is unchanged it means the full timeout period expired. If the timeout period expired and the returned string is shorter than pMaxReadLen, then AtEnd will be 1.
Method Read(pMaxReadLen As %Integer = {$$$MaxLocalLength}, ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %String [ Abstract ]
{
}

/// Write pData to the stream buffer. If pFlush is True, ensure that the data are actually sent to the stream.
Method Write(pData As %String, pFlush As %Boolean, Output pSC As %Status) [ Abstract ]
{
}

/// Ensure that any data already written to the stream buffer are actually sent to the stream.
Method Flush(Output pSC As %Status)
{
	Set pSC=$$$OK
}

/// Copy all available data from pSource to the current stream buffer. If pFlush is True, ensure that all data are actually sent to the stream.
Method CopyFrom(pSource As %IO.I.Stream, ByRef pTimeout As %Numeric = -1, pFlush As %Boolean = {..DefaultFlushOnWrite}, Output pSC As %Status) As %Integer
{
	If '$IsObject(pSource) Set pSC=$$$ERROR($$$OrefInvalid)  Quit 0
	Set pSC=$$$OK
	Set tTotal=0, tTimeout=pTimeout, tEnd=$S(tTimeout<=0:"",1:$ZH+tTimeout)
	While 'pSource.AtEnd,$$$ISOK(pSC) {
		Set tTO=tTimeout, tData=..delegateRead(pSource,32000,.tTO,.pSC)  Set:tTO<tTimeout pTimeout=pTimeout-tTimeout+tTO  Quit:$$$ISERR(pSC)
		Do ..Write(tData,0,.pSC)  Quit:$$$ISERR(pSC)
		Set tTotal=tTotal+$L(tData)
		Quit:tTO<tTimeout||('tTimeout&&($L(tData)<32000)) ; if timed out
		If ""'=tEnd Set tTimeout=tEnd-$ZH  Quit:tTimeout<=0 ; if timed out
	}
	Do:$$$ISOK(pSC)&&pFlush ..Flush(.pSC)
	Quit tTotal
}

/// Copy all available data from the current stream to the current system device.
Method OutputToDevice(pLength As %Integer = -1, ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %Integer
{
	Set pSC=$$$OK  If pLength=0 Set pTimeout=0  Quit 0
	Try {
		Set tTotal=0, tTimeout=pTimeout, tEnd=$S(tTimeout<=0:"",1:$ZH+tTimeout)
	    While pLength<0||(tTotal<pLength),'..AtEnd,$$$ISOK(pSC) {
		    Set tTO=tTimeout, (tChunk,tLen)=$S(pLength<0||(pLength-tTotal>32000):32000,1:pLength-tTotal)
			Set tData=..Read(tChunk,.tTO,.pSC)  Set tChunk=$L(tData)  Write:tChunk tData
			Set:tTO<tTimeout pTimeout=pTimeout-tTimeout+tTO  Set tTotal=tTotal+tChunk  Quit:$$$ISERR(pSC)
		    Quit:tTO<tTimeout||('tTimeout&&(tChunk<tLen)) ; if timed out
		    If ""'=tEnd Set tTimeout=tEnd-$ZH  Quit:tTimeout<=0 ; if timed out
	    }
	} Catch ex { Set pSC=ex.AsStatus() }
	Quit tTotal
}

Method InputFromDevice(ByRef pTotal As %Integer = 0, ByRef pTimeout As %Integer = -1, ByRef pIdleTimeout As %Integer = 20, Output pStatus As %Status) As %Integer
{
	Set pStatus=$$$OK, tMaxStr=$$$MaxLocalLength
	Set tLeft=pTotal, pTotal=0, tTimeout=pTimeout, pTimeout=0, tIdleTimeout=$S(((pIdleTimeout>tTimeout)||(pIdleTimeout<0))&&(tTimeout>=0):pTimeout,1:pIdleTimeout), pIdleTimeout=0
	Set:tTimeout>0 (t0,t1)=$ZH
	try {
		While tLeft>0  {
			If tIdleTimeout>=0 {
				Set tTOLeft=$S(tTimeout<=0:tIdleTimeout, tTimeout-pTimeout<tIdleTimeout:tTimeout-pTimeout, 1:tIdleTimeout)
				Read data#$S(tLeft>tMaxStr:tMaxStr,1:tLeft):tTOLeft
			} Else {
				Read data#$S(tLeft>tMaxStr:tMaxStr,1:tLeft)
			}
			If tTimeout>0 Set t1=$ZH, pTimeout=t1-t0
			If ""'=data {
				Set pIdleTimeout=0
				Do ..Write(data,,.pStatus)  Quit:$$$ISERR(pStatus)
				Set tLeft=tLeft-$L(data), pTotal=pTotal+$L(data)
			} Else {
				If tIdleTimeout>=0 { Set pIdleTimeout=tTOLeft  Quit }
			}
			Quit:'tTimeout||(tTimeout=tIdleTimeout&&(tTimeout>0))
			Quit:tTimeout>0&&(pTimeout>=tTimeout)
			Hang:'tIdleTimeout&&'$L(data) 0.1 ; prevent spin on no data if no idle timeout
		}
	} catch {
		Set pStatus=$$$ERROR($$$ObjectScriptError,$ZE)
	}
	Quit pTotal
}

ClassMethod delegateRead(s As %RegisteredObject, ByRef pMaxReadLen As %Integer, ByRef pTimeout As %Numeric, Output pSC As %Status) [ Internal, Private ]
{
	If s.%Extends("%IO.I.Stream") { Quit s.Read(.pMaxReadLen, .pTimeout, .pSC) }
	ElseIf s.%Extends("%Stream.Object") { Set pSC=$$$OK,pTimeout=0  Quit s.Read(.pMaxReadLen,.pSC) }
	Else { Set pSC=$$$ERROR($$$ErrIONotStream,s.%ClassName(1)) Quit "" }
}

/// Close the current stream
Method Close(Output pSC As %Status) As %Boolean
{
	If '..IsOpen { Set pSC = $$$ERROR($$$FileNotOpen,..Name) }
	Else { Set pSC = $$$ERROR($$$ErrIOStreamNotCloseable,..%ClassName(1),..Name) }
	Quit 0
}

Method %OnClose() As %Status [ Internal, Private ]
{
	Do ..Close() Quit $$$OK
}

Method IsCharacterGet() As %Boolean [ CodeMode = expression, Internal ]
{
0
}

/// Read until one of the Target strings is found or a timeout occurs.<p>
/// Return any data read until pTimeout seconds have elapsed, or until pIdleTimeout seconds elapse with no further data read, or up until any of the optional pTarget strings is encountered.<p>
/// If pTarget strings are provided the pWhich output argument will contain an integer indicating which of them was matched. A value of 0 in pWhich indicates that none was matched and therefore the timeout expired or an error occurred.<p>
/// Setting pInsensitive=1 means the pTarget strings will match data received in a case-insensitive way against the pTargets strings.<p>
/// If pPrevBuf is provided, it is prepended to any data read, and is included in the attempt to find a matching target string.
Method ReadUntil(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric, pIdleTimeout As %Numeric, pPrevBuf As %String, pInsensitive As %Boolean, Output pWhich As %Integer, Output pSC As %Status, pTarget...) As %String
{
	Quit ..ReadUntilArray(.pMaxReadLen, .pTimeout, .pIdleTimeout, .pPrevBuf, .pInsensitive, .pWhich, .pSC, .pTarget)
}

/// Read until one of the Target strings is found or a timeout occurs.<p>
/// Return any data read until pTimeout seconds have elapsed, or until pIdleTimeout seconds elapse with no further data read, or up until any of the optional pTargets strings is encountered.<p>
/// If pTargets strings are provided the pWhich output argument will contain an integer indicating which of them was matched. A value of 0 in pWhich indicates that none was matched and therefore the timeout expired or an error occurred.<p>
/// Setting pInsensitive=1 means the pTarget strings will match data received in a case-insensitive way against the pTargets strings.<p>
/// If pPrevBuf is provided, it is prepended to any data read, and is included in the attempt to find a matching target string.
Method ReadUntilArray(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric = -1, pIdleTimeout As %Numeric = 5, pPrevBuf As %String = "", pInsensitive As %Boolean = 0, Output pWhich As %Integer, Output pSC As %Status, ByRef pTargets) As %String
{
	Set tFound="", tData="", tMaxStr=$$$MaxLocalLength, pWhich=0, tTimeout=pTimeout, pTimeout=0, tIdleTimeout=pIdleTimeout, pIdleTimeout=0
	Set:""=$G(pMaxReadLen)||(pMaxReadLen>tMaxStr) pMaxReadLen=tMaxStr
	Set tMinTarg=tMaxStr
	For i=1:1:pTargets {
		Set:pInsensitive pTargets(i)=$ZCVT(pTargets(i),"L")
		Set tTargLen=$L(pTargets(i))
		Set:tTargLen<tMinTarg&&tTargLen tMinTarg=tTargLen
	}
	Set tData=pPrevBuf
	If ""=tData && ..AtEnd  Set pSC=$$$ERROR($$$FileNotOpen,..Name)  Quit tData

	#; Determine initial read timeout
	If (tTimeout >= 0) && (tIdleTimeout >= 0) {
		Set tUseIdleTimeout = (tIdleTimeout < tTimeout)
		Set tReadTimeout = $S(tUseIdleTimeout: tIdleTimeout, 1: tTimeout)
	} ElseIf (tTimeout < 0) && (tIdleTimeout < 0) {
		Set tUseIdleTimeout = 1
		Set tReadTimeout = -1
	} ElseIf (tTimeout <= 0) || (tIdleTimeout <= 0) {
		Set tUseIdleTimeout = (tTimeout < tIdleTimeout)
		Set tReadTimeout = $S(tUseIdleTimeout: tIdleTimeout, 1: tTimeout)
	}
	Set tCurrReadTimeout = tReadTimeout

	#; Determine overall timeout
	If tTimeout >= 0 { Set tEndTime = $ZH + tTimeout }
	Else { Set tEndTime = 0 }

	#; Fill a buffer long enough to try at least one match in
	While $L(tData)<tMinTarg&&'..AtEnd {
		Set tReadTO=$S(tUseIdleTimeout: tIdleTimeout, 1: tCurrReadTimeout)
		Set tRead=..Read(tMinTarg-$L(tData),.tReadTO,.pSC), tData=tData_tRead  Quit:$$$ISERR(pSC)
		If (""=tRead) {
			Set pTimeout = $S(tUseIdleTimeout: 0, 1: $S(tReadTO: tTimeout, 1: 0))
			Set pIdleTimeout = $S(tUseIdleTimeout: tReadTO, 1: 0)
			Quit
		}
		If tEndTime { // There is an overall timeout
			If ($ZH >= tEndTime) { Set pTimeout = tTimeout  Quit }
			Set tCurrReadTimeout = tEndTime - $ZH
			If tCurrReadTimeout < 0 { Set pTimeout = tTimeout  Quit }
			If tUseIdleTimeout && (tCurrReadTimeout < tIdleTimeout) {
				Set tUseIdleTimeout = 0
			}
		}
	}
	Quit:$L(tData)<tMinTarg tData

	#; Keep reading one character at a time until we find a match, time out, or get to the end
	Set tLwrData=$S(pInsensitive:$ZCVT(tData,"L"),1:tData)
	While 1 {
		Set tDataLen=$L(tData)
		For i=1:1:pTargets {
			Set tTarg=pTargets(i), tTargLen=$L(tTarg)
			If tTarg=$E(tLwrData,tDataLen-tTargLen+1,tDataLen)&&tTargLen Set pWhich=i Quit
		}
		Quit:pWhich||(tDataLen>=pMaxReadLen)||..AtEnd

		Set tReadTO=$S(tUseIdleTimeout: tIdleTimeout, 1: tCurrReadTimeout)
		Set tRead=..Read(1,.tReadTO,.pSC), tData=tData_tRead  Quit:$$$ISERR(pSC)
		If ""=tRead {
			Set pTimeout = $S(tUseIdleTimeout: 0, 1: $S(tReadTO: tTimeout, 1: 0))
			Set pIdleTimeout = $S(tUseIdleTimeout: tReadTO, 1: 0)
			Quit
		}
		If tEndTime { // There is an overall timeout
			If ($ZH >= tEndTime) { Set pTimeout = tTimeout  Quit }
			Set tCurrReadTimeout = tEndTime - $ZH
			If tCurrReadTimeout < 0 { Set pTimeout = tTimeout Quit }
			If tUseIdleTimeout && (tCurrReadTimeout < tIdleTimeout) {
				Set tUseIdleTimeout = 0
			}
		}
		Set:pInsensitive tRead=$ZCVT(tRead,"L")
		Set tLwrData=tLwrData_tRead
	}
	Quit tData
}

/// Replace from the current stream the strings contained in a list of alternating search and replace target string arguments.
/// Accepts a destination stream <var>pDest</var> into which the modified result will be written. If not supplied, <var>pDest</var> will be returned containing a newly created GlobalCharacter stream.
/// Reads until a maximum number of characters <var>pMaxReadLen</var> has been read or until a timeout <var>pTimeout</var> has occurred, or until <var>pIdleTimeout</var> seconds have elapsed with no further data read.<p>
/// Setting <var>pInsensitive</var>=1 means the search strings will match in a case-insensitive way.<p>
/// If <var>pPrevBuf</var> is provided, it is prepended to any data read, and is included in the attempt to find matching search strings.
/// Replaces from left to right and does not repeat and recurse. This means that once a substring is replaced the replacement result will not be searched or replaced again.
/// Returns the total count of characters written to the destination stream
/// If <var>pRewind</var> contains i the input stream will be rewound before copying
/// If <var>pRewind</var> contains I the input stream will be rewound after copying
/// If <var>pRewind</var> contains o the output stream will be rewound before copying
/// If <var>pRewind</var> contains O the output stream will be rewound after copying
/// If <var>pRewind</var> is 1 both streams will be rewound before and after copying. This is the default.
/// If <var>pRewind</var> is empty or zero neither stream will be rewound before or after copying
Method CopyReplace(pDest As %IO.I.Stream, pMaxReadLen As %Integer, ByRef pTimeout As %Numeric, pIdleTimeout As %Numeric, pPrevBuf As %String, pFlush As %Boolean, pInsensitive As %Boolean, pRewind As %String, Output pSC As %Status, pSearchReplace...) As %Integer
{
	Quit ..CopyReplaceArray(.pDest, .pMaxReadLen, .pTimeout, .pIdleTimeout, .pPrevBuf, .pFlush, .pInsensitive, .pRewind, .pSC, .pSearchReplace)
}

/// Replace from the current stream the strings contained in an array of alternating search and replace target string values called pSearchReplace.
/// Accepts a destination stream <var>pDest</var> into which the modified result will be written. If not supplied, <var>pDest</var> will be returned containing a newly created GlobalCharacter stream.
/// Reads until a maximum number of characters <var>pMaxReadLen</var> has been read or until a timeout <var>pTimeout</var> has occurred, or until <var>pIdleTimeout</var> seconds have elapsed with no further data read.<p>
/// Setting <var>pInsensitive</var>=1 means the search strings will match in a case-insensitive way.<p>
/// If <var>pPrevBuf</var> is provided, it is prepended to any data read, and is included in the attempt to find matching search strings.
/// Replaces from left to right and does not repeat and recurse. This means that once a substring is replaced the replacement result will not be searched or replaced again.
/// Returns the total count of characters written to the destination stream
Method CopyReplaceArray(pDest As %IO.I.Stream, pMaxReadLen As %Integer = -1, ByRef pTimeout As %Numeric = -1, pIdleTimeout As %Numeric = 5, pPrevBuf As %String = "", pFlush As %Boolean = {..DefaultFlushOnWrite}, pInsensitive As %Boolean = 0, pRewind As %String = 1, Output pSC As %Status, ByRef pSearchReplace = 0) As %Integer
{
	Set tMaxStr=$$$MaxLocalLength, pWhich=0, tTimeout=pTimeout, pTimeout=0, tIdleTimeout=pIdleTimeout, pIdleTimeout=0
	Set:pRewind=1 pRewind="ioIO"
	#; Construct pDest stream object if it is not an object passed in
	If '$IsObject($G(pDest)) {
		If $G(pDest)=$$$NULLOREF {
			Set pDest=##class(%Stream.GlobalCharacter).%New()
		} ElseIf ##class(%Dictionary.CompiledClass).%ExistsId(pDest) && ($classmethod(pDest,"%Extends","%IO.I.Stream") || $classmethod(pDest,"%Extends","%Stream.Object")) {
			Set pDest=$classmethod(pDest,"%New")
		} Else {
			Set tTemp=##class(%IO.FileStream).%New()
			Quit:'tTemp.Open(pDest,"NEW",,.pSC) 0
			Set pDest=tTemp
		}
	} ElseIf pRewind["o" {
		Do pDest.Rewind()
	}
	Do:pRewind["i" ..Rewind()
	
	#; Remember the length of the shortest search string
	Set tMaxSearch=0, tMinSearch=$S('pSearchReplace:0,1:tMaxStr), tSearches=0
	For i=1:2:pSearchReplace {
		Set tSearch=$G(pSearchReplace(i))
		Set:pInsensitive tSearch=$ZCVT(tSearch,"L")
		Set tSearches=i\2+1
		Set tSearches(tSearches)=tSearch
		Set tSearchLen=$L(tSearch)
		Set:tMinSearch>tSearchLen tMinSearch=tSearchLen
		Set:tMaxSearch<tSearchLen tMaxSearch=tSearchLen
	}
	;If i=pSearchReplace { Set pSC=$$$ERROR($$$GeneralError,"CopyReplace final search string '"_pSearchReplace(pSearchReplace)_"' has no corresponding replace target string") }

	#; Determine initial read timeout
	If (tTimeout >= 0) && (tIdleTimeout >= 0) {
		Set tUseIdleTimeout = (tIdleTimeout < tTimeout)
		Set tReadTimeout = $S(tUseIdleTimeout: tIdleTimeout, 1: tTimeout)
	} ElseIf (tTimeout < 0) && (tIdleTimeout < 0) {
		Set tUseIdleTimeout = 1
		Set tReadTimeout = -1
	} ElseIf (tTimeout <= 0) || (tIdleTimeout <= 0) {
		Set tUseIdleTimeout = (tTimeout < tIdleTimeout)
		Set tReadTimeout = $S(tUseIdleTimeout: tIdleTimeout, 1: tTimeout)
	}
	Set tCurrReadTimeout = tReadTimeout

	#; Determine overall timeout
	If tTimeout >= 0 { Set tEndTime = $ZH + tTimeout }
	Else { Set tEndTime = 0 }

	Set tIsIOStream=pDest.%Extends("%IO.I.Stream")
	Set tData=pPrevBuf
	Set tTotal=0, tTotalIn=0, pSC=$$$OK
	While '..AtEnd && ((pMaxReadLen<0) || (tTotalIn<pMaxReadLen)) {
		#; Refill the buffer
		While $L(tData)<tMaxStr && '..AtEnd && ((pMaxReadLen<0) || (tTotalIn<pMaxReadLen)) {
			Set tMaxLen=tMaxStr-$L(tData)  Set:(pMaxReadLen>=0)&&(tMaxLen>(pMaxReadLen-tTotalIn)) tMaxLen=(pMaxReadLen-tTotalIn)
			Set tReadTO=$S(tUseIdleTimeout: tIdleTimeout, 1: tCurrReadTimeout)
			Set tRead=..Read(tMaxLen,.tReadTO,.pSC), tData=tData_tRead, tTotalIn=tTotalIn+$L(tRead)  Quit:$$$ISERR(pSC)
			If (""=tRead) {
				Set pTimeout = $S(tUseIdleTimeout: 0, 1: $S(tReadTO: tTimeout, 1: 0))
				Set pIdleTimeout = $S(tUseIdleTimeout: tReadTO, 1: 0)
				Quit
			}
			If tEndTime { // There is an overall timeout
				If ($ZH >= tEndTime) { Set pTimeout = tTimeout  Quit }
				Set tCurrReadTimeout = tEndTime - $ZH
				If tCurrReadTimeout < 0 { Set pTimeout = tTimeout  Quit }
				If tUseIdleTimeout && (tCurrReadTimeout < tIdleTimeout) {
					Set tUseIdleTimeout = 0
				}
			}
		}
		#; Search in the buffer, write out unmatched string segments and replacements
		While $L(tData) && ($L(tData)>=tMaxSearch || (..AtEnd && $L(tData)>=tMinSearch)) {
			Set tDataIn=$S(pInsensitive:$ZCVT(tData,"L"),1:tData)
			Kill tMatches For i=1:1:tSearches { Set tLen=$L(tSearches(i)), tPos=$S(tLen:$F(tDataIn,tSearches(i)),1:0)  Set:tPos tPos=tPos-1-tLen, tMatches(tPos,i)="" }
			Set tLowPos=$O(tMatches(""))
			If ""=tLowPos {
				#; no match in this tData buffer; save the tail to start the next buffer
				Set tOut=$E(tData,1,*+1-tMaxSearch)
				Set $E(tData,1,$L(tOut))=""
				Quit:""=tOut
			} Else {
				Set tMatch=$O(tMatches(tLowPos,""))
				Set tOut=$E(tData,1,tLowPos)_$G(pSearchReplace(tMatch*2))
				Set $E(tData,1,tLowPos+$L(tSearches(tMatch)))=""
			}
			If tIsIOStream {
				Do pDest.Write(tOut,0,.pSC)  Quit:$$$ISERR(pSC)
			} Else {
				Set pSC=pDest.Write(tOut)  Quit:$$$ISERR(pSC)
			}
			Set tTotal=tTotal+$L(tOut)
			Quit:""=tLowPos ; no match in this tData; get more if we can
		} Quit:$$$ISERR(pSC)
	} Quit:$$$ISERR(pSC) tTotal ; end While 1

	#; Final write and flush of string remnant too short to match or unmatched
	If tIsIOStream {
		Do pDest.Write(tData,pFlush,.pSC)  Quit:$$$ISERR(pSC) tTotal
	} ElseIf $L(tData) {
		Set pSC=pDest.Write(tData)  Quit:$$$ISERR(pSC) tTotal
	}
	Set tTotal=tTotal+$L(tData)
	Do:pRewind["I" ..Rewind()
	Do:pRewind["O" pDest.Rewind()
	Quit tTotal
}

}
