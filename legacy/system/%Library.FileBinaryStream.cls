/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Stream class that stores binary data in external files.
/// This class is deprecated in favor of <class>%Stream.FileBinary</class>.
/// For example the following code opens a file binary stream, points it at a particular file
/// on the filesystem and then reads it in chunks of 32,000 bytes:
/// <example>
/// Set stream=##class(%FileBinaryStream).%New()
/// Set stream.Filename="c:\myfile.txt"
/// While 'stream.AtEnd {
/// Set line=stream.Read()
/// ; Process the chunk here
/// }
/// </example>
Class %Library.FileBinaryStream Extends (%BinaryStream, %FileStreamAdaptor) [ Deprecated, Inheritance = right, MemberSuper = %Compiler.Type.StreamLegacy, Not ProcedureBlock, StorageStrategy = Custom, System = 2 ]
{

Storage Custom
{
<StreamLocation>^%Library.FileBinaryStreamS</StreamLocation>
<Type>%CompleteCustomStorage</Type>
}

}
