/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Deprecated in favor of <class>%Stream.GlobalBinary</class>.
/// Stream class that stores binary data in global nodes.
/// Note that although you can write unicode data into this class and read
/// it back out this is not a supported use of this class and the Size property would be incorrect
/// in this case as it would be the size in characters rather than the size in bytes.
Class %Library.GlobalBinaryStream Extends (%BinaryStream, %GlobalStreamAdaptor) [ Deprecated, Inheritance = right, MemberSuper = %Compiler.Type.StreamLegacy, StorageStrategy = Custom, System = 2 ]
{

Storage Custom
{
<StreamLocation>^%Library.GlobalBinaryStreamS</StreamLocation>
<Type>%CompleteCustomStorage</Type>
}

}
