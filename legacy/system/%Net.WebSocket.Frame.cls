/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %Net.WebSocket

/// Represents a sent/received frame in a WebSocket connection.
/// This class is internal to the module and should not be used directly.
Class %Net.WebSocket.Frame Extends %RegisteredObject [ Final ]
{

/// Device from which to read (for reads) or write (for writes)
Property Device As %String [ Private ];

/// Set to false if <method>Read</method> times out rather than receiving a message
Property HasMessage As %Boolean [ InitialExpression = 1 ];

Property Fin As %Boolean [ InitialExpression = 1, Required ];

/// Reserved - always 0
Property RSV1 As %Boolean [ InitialExpression = 0, Required ];

/// Reserved - always 0
Property RSV2 As %Boolean [ InitialExpression = 0, Required ];

/// Reserved - always 0
Property RSV3 As %Boolean [ InitialExpression = 0, Required ];

/// Valid values (macros in HSMOD.WebSocket.INC) are:
/// <code>
/// $$$WebSocketOpContinuation		0
/// $$$WebSocketOpTextFrame			1
/// $$$WebSocketOpBinaryFrame		2
/// $$$WebSocketOpClose				8
/// $$$WebSocketOpPing				9
/// $$$WebSocketOpPong				10
/// </code>
Property Opcode As %Integer(MAXVAL = 10, MINVAL = 0) [ Required ];

/// Set to 1 if the payload was received masked
/// Always set to 1 in send
Property Masked As %Boolean [ InitialExpression = 0, Required ];

/// The length of payload data
Property PayloadLength As %Integer [ InitialExpression = 0, Required ];

/// 4-byte masking key (if <property>Masked</property> is true)
/// If not provided prior to send, will be generated randomly
Property MaskingKey As %Binary;

/// Unmasked binary/character data received or to send -
/// on write, this is masked before sending; on read, it is unmasked automatically.
Property PayloadData As %Stream.TmpBinary [ Required ];

Method %OnNew(pDevice As %String = "") As %Status [ Private, ServerOnly = 1 ]
{
	Set i%Device = pDevice
	Quit $$$OK
}

/// Translates bytes read from the TCP device into a frame
Method Read(pTimeout As %Integer)
{
	// Only use the timeout for the initial read.
	Set ..HasMessage = 0
	Set tHeader = ..ReadBytes(1,.pTimeout)
	If (tHeader = "") {
		Quit
	}
	Set ..HasMessage = 1
	Set ..Fin = $$$HexMaskMatches(tHeader,"80")
	Set ..RSV1 = $$$HexMaskMatches(tHeader,"40")
	Set ..RSV2 = $$$HexMaskMatches(tHeader,"20")
	Set ..RSV3 = $$$HexMaskMatches(tHeader,"10")
	Set ..Opcode = $ASCII($$$HexMask(tHeader,"0F"))
	Set tPayloadInfo = ..ReadBytes(1)
	Set ..Masked = $$$HexMaskMatches(tPayloadInfo,"80")
	Set ..PayloadLength = $ASCII($$$HexMask(tPayloadInfo,"7F"))
	If (..PayloadLength = 126) {
		// Integer interpretation of following two bytes (reversed, because $ZWASCII needs that)
		Set ..PayloadLength = $ZWASCII($Reverse(..ReadBytes(2)))
	} ElseIf (..PayloadLength = 127) {
		// Integer interpretation of following eight bytes (reversed, because $ZQASCII needs that)
		Set ..PayloadLength = $ZQASCII($Reverse(..ReadBytes(8)))
	}
	If ..Masked {
		Set ..MaskingKey = ..ReadBytes(4)
	}
	
	Set ..PayloadData = ##class(%Stream.TmpBinary).%New()
	Set tSC = $$$OK
	Set tBytesRemaining = ..PayloadLength
	While (tBytesRemaining > 0) {
		Set tBytesToRead = $Select(tBytesRemaining>$$$MaxStringLength:$$$MaxStringLength,1:tBytesRemaining)
		If ..Masked {
			Set tSC = $$$ADDSC(tSC,..PayloadData.Write(..Mask(..ReadBytes(tBytesToRead))))
		} Else {
			Set tSC = $$$ADDSC(tSC,..PayloadData.Write(..ReadBytes(tBytesToRead)))
		}
		Set tBytesRemaining = tBytesRemaining - tBytesToRead
	}
	$$$ThrowOnError(tSC)
	Do ..PayloadData.Rewind()
}

/// Reads in a specified number of bytes from the TCP device
Method ReadBytes(pLength As %Integer, pTimeout As %Integer) As %String [ Private ]
{
	Set tSC = $$$OK
	Set tFinalBytes = ""
	Set tOldDevice = $io
	Try {
		Use i%Device:(/IOT="RAW":/TER="":/WAIT=1)
		
		// Read in a loop: the requested length might be greater than the buffer size.
		While pLength > 0 {
			Set tBytes = ""
			If $Data(pTimeout) {
				Read tBytes#pLength:pTimeout
				If '$Test {
					Set tBytes = ""
					Quit
				}
			} Else {
				// No timeout.
				Read tBytes#pLength
			}
			Set pLength = pLength - $Length(tBytes)
			Set tFinalBytes = tFinalBytes_tBytes
		}
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Use tOldDevice
	$$$ThrowOnError(tSC)
	Quit tFinalBytes
}

/// Translates the frame into the wire format and writes it to the TCP device
Method Write()
{
	Set tStream = ##class(%Stream.TmpBinary).%New()
	Set ..Masked = 1 // Always mask writes from the client
	
	// Header bytes:
	Do tStream.Write($Char(((8*..Fin) + (4*..RSV1) + (2*..RSV2) + ..RSV3)*16 + ..Opcode))
	If (..PayloadLength = 0) && $IsObject(..PayloadData) {
		Set ..PayloadLength = ..PayloadData.Size
	}
	If (..PayloadLength > 65535) {
		Do tStream.Write($Char(128*..Masked + 127))
		Do tStream.Write($Reverse($ZQChar(..PayloadLength)))
	} ElseIf (..PayloadLength > 125) {
		Do tStream.Write($Char(128*..Masked + 126))
		Do tStream.Write($Reverse($ZWChar(..PayloadLength)))
	} Else {
		Do tStream.Write($Char(128*..Masked + ..PayloadLength))
	}
	If (..MaskingKey = "") {
		Set ..MaskingKey = $System.Encryption.GenCryptRand(4)
	}
	Do tStream.Write(..MaskingKey)
	
	// Payload - always masked.
	Set tSC = $$$OK
	$$$ThrowOnError(..PayloadData.Rewind())
	Set tBytesRemaining = ..PayloadLength
	While (tBytesRemaining > 0) {
		Set tBytesToRead = $Select(tBytesRemaining>$$$MaxStringLength:$$$MaxStringLength,1:tBytesRemaining)
		Set tSC = $$$ADDSC(tSC,tStream.Write(..Mask(..PayloadData.Read(tBytesRemaining))))
		Set tBytesRemaining = tBytesRemaining - tBytesToRead
	}
	$$$ThrowOnError(tSC)
	Do ..WriteData(tStream)
}

/// Writes a stream out to the TCP device
Method WriteData(pData As %Stream.Object) [ Private ]
{
	Set tSC = $$$OK
	Set tBytes = ""
	Set tOldDevice = $io
	Try {
		$$$ThrowOnError(pData.Rewind())
		Use i%Device:(/IOT="RAW")
		While ('pData.AtEnd) {
			// Read 1024 characters (max TCP buffer size) at a time
			Set tNext = pData.Read(1024,.tReadSC)
			Set tBytes = tBytes_tNext
			Write tNext
			Set tSC = $$$ADDSC(tSC,tReadSC)
			Write *-3
		}
	} Catch e {
		Set tSC = e.AsStatus()
	}
	Use tOldDevice
	$$$ThrowOnError(tSC)
}

/// Masks the input string by XOR-ing 4-byte chunks with the masking key
Method Mask(pString As %String) As %String
{
	Set tMasked = ""
	For tChar=1:1:($Length(pString)+3)/4 {
		// XOR 4 bytes at a time for efficiency
		Set tMasked = tMasked_$ZBoolean($Extract(pString,(tChar-1)*4+1,(tChar-1)*4+4),i%MaskingKey,6)
	}
	Quit tMasked
}

}
