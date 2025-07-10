/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Divides HTTP body into chunks of equal size
Class EnsLib.HTTP.ChunkedWriter Extends %Net.ChunkedWriter [ System = 4 ]
{

/// The stream that acutally holds the stream data.
Property Stream As %Stream.TmpBinary [ Internal ];

/// The size of each chunk. The size of the last chunk can be different.
Property ChunkSize As %Integer(MINVAL = 1) [ InitialExpression = 1024 ];

/// Overrides the inherited abstract method.
/// Writes chunks each of size <PROPERTY>ChunkSize</PROPERTY>.
Method OutputStream()
{
    Set isFirstChunk = 1
    Do ..Stream.Rewind()
	While '..Stream.AtEnd {
        Set chunk = ..Stream.Read(..ChunkSize)
		If isFirstChunk {
			Do ..WriteFirstChunk(chunk)
			Set isFirstChunk = 0
		} Else {
			Do ..WriteChunk(chunk)
		}
	}
	Do ..WriteLastChunk("")
}

/// Copy stream data from source
Method CopyFrom(source As %Stream.Object) As %Status
{
	Return ..Stream.CopyFrom(source)
}

/// Clear stream data
Method Clear() As %Status
{
	Kill ..Attributes
	Return ..Stream.Clear()
}

}
