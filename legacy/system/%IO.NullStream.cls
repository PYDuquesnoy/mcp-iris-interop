/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Read returns nothing, Write does nothing
Class %IO.NullStream Extends %IO.I.ByteSeekableStream [ System = 2 ]
{

Method IsOpenGet() As %Boolean [ CodeMode = expression ]
{
1
}

Method AtEndGet() As %Boolean [ CodeMode = expression ]
{
1
}

Method Read(pMaxReadLen As %Integer, ByRef pTimeout As %Numeric = -1, Output pSC As %Status) As %String
{
	Set pSC = $$$OK, pTimeout=0
	Quit ""
}

Method Write(pData As %String = "", pFlush As %Boolean, Output pSC As %Status)
{
	Set pSC = $$$OK
}

Method Seek(pPosition As %Integer, Output pSC As %Status) As %Boolean
{
	Kill pSC  Set pSC = $S(pPosition=1:$$$OK,1:$$$ERROR($$$ErrIOSeekPastEnd, pPosition, ..Size))
	Quit (pPosition=1)
}

}
