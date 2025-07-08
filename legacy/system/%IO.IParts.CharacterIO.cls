/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A character stream with byte-character transcoding for its storage or transport format based on the value of <property>..CharEncoding</property>.
/// ExternalCharacterStream extends IByteStream because "RawBytes" is an option for <property>..CharEncoding</property>.
Class %IO.IParts.CharacterIO Extends (%IO.IParts.ByteIO, %IO.IParts.LineIO) [ Abstract, Inheritance = right, System = 2 ]
{

/// (This property is overridden from %IO.I.Stream but has a different meaning in this context of character IO.)
Method IsCharacterGet() As %Boolean [ CodeMode = expression ]
{
1
}

/// Names the character encoding used to encode this character stream in its storage or transport format
/// A value of "Native" in this property means the stream is encoded in the native format for the local installation.
/// Values of "RawBytes" or "Binary" mean that each character is represented by the corresponding byte in the external storage or transport format.
/// (This property is overridden from %IO.IParts.ByteIO but has a different meaning in this character IO context.)
Property CharEncoding As %String(TRUNCATE = 1) [ InitialExpression = "Native" ];

Method CharEncodingSet(pCharEncoding As %String) As %Status
{
	Set i%CharEncoding=$S("binary"=$ZCVT(pCharEncoding,"L"):"RawBytes",1:pCharEncoding)
	Quit $$$OK
}

}
