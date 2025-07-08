/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Aggregation holder class for methods implemented in those Stream classes that support line-by-line Read and Write operations.
Class %IO.IParts.LineIO [ Abstract, System = 2 ]
{

/// A string of characters that will be written at the end of each WriteLine operation, and any of which will terminate a ReadLine() operation if it is encountered. (Note: special-case handling will treat CR/LF input sequences as a single terminator.)
Property LineTerminator As %String(TRUNCATE = 1) [ InitialExpression = {$S($$$isWINDOWS:$Char(13,10),1:$Char(10))} ];

/// Read until pMaxReadLen chars are gotten, pTimeout expires, or a LineTerminator character is found.
/// On return, if pTimeout=0 it means no timeout occurred. If pTimeout=0 and the returned string contains the full pMaxReadLen characters, it means no LineTerminator was encountered yet, even if the following character would be a LineTerminator.
/// If pTimeout=0 and the returned string is shorter than pMaxReadLen, then either a LineTerminator or the End Of Stream (AtEnd = 1) was encountered.
/// If pLineTerminator is defined, then the line is read until one of the given characters is encountered. On return, pLineTerminator contains the encountered character(s) if any.
Method ReadLine(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric = -1, Output pSC As %Status, ByRef pLineTerminator As %String) As %String [ Abstract ]
{
}

/// Write pLine to the stream buffer, followed by the current LineTerminator characters. If pFlush is True, ensure that the characters are actually sent to the stream.
/// Note: No pLineTerminator argument because delegators always call Write() not WriteLine()
Method WriteLine(pLine As %String = "", pFlush As %Boolean, Output pSC As %Status)
{
	Do ..Write(pLine_..LineTerminator,.pFlush,.pSC)
}

}
