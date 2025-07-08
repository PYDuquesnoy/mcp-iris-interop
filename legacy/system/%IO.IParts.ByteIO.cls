/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// /// Aggregation holder class for a stream of raw bytes that represent encoded characters.
/// The <Property>CharEncoding<Property> property designates which character encoding should be applied to convert the bytes into characters.
Class %IO.IParts.ByteIO Extends %RegisteredObject [ Abstract, System = 2 ]
{

/// Info-only description of the character encoding that this byte stream represents, if it
/// represents the storage or transport format of a character stream.
/// A value of "RawBytes" or "Binary" in this property means the stream does not represent character data.
Property CharEncoding As %String [ InitialExpression = "Native" ];

Method CharEncodingSet(pCharEncoding As %String) As %Status
{
	Set i%CharEncoding=$S("binary"=$ZCVT(pCharEncoding,"L"):"RawBytes",1:pCharEncoding)
	Quit $$$OK
}

}
