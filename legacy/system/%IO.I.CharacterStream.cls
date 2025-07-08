/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Abstract Character Stream base class.
/// CharacterStreams extend Byte Streams because "RawBytes" is an option for ..CharEncoding
Class %IO.I.CharacterStream Extends (%IO.I.ByteStream, %IO.IParts.CharacterIO) [ Abstract, Inheritance = right, System = 2 ]
{

}
