/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Deprecated in favor of <class>%Stream.GlobalCharacter</class>.
/// Stream class that stores character data in global nodes.
Class %Library.GlobalCharacterStream Extends (%CharacterStream, %GlobalStreamAdaptor) [ Deprecated, Inheritance = right, MemberSuper = %Compiler.Type.StreamLegacy, StorageStrategy = Custom, System = 2 ]
{

Storage Custom
{
<StreamLocation>^%Library.GlobalCharacterStreamS</StreamLocation>
<Type>%CompleteCustomStorage</Type>
}

}
