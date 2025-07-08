/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %MFT.FolderContents lists the contents of a folder.
/// Note: Even though this class is in IRISLIB, the storage is in the namespace which creates the instance.
Class %MFT.FolderContents Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

/// Recursive is true if this list is a recursive list of all descendants of the folder.
Property Recursive As %Boolean;

/// Contents is a list of %MFT.ItemInfo to describe the folder contents.
Property Contents As list Of %MFT.ItemInfo;

Storage Default
{
<Data name="FolderContentsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Recursive</Value>
</Value>
<Value name="3">
<Value>Contents</Value>
</Value>
</Data>
<DataLocation>^MFT.FolderContentsD</DataLocation>
<DefaultData>FolderContentsDefaultData</DefaultData>
<IdLocation>^MFT.FolderContentsD</IdLocation>
<IndexLocation>^MFT.FolderContentsI</IndexLocation>
<StreamLocation>^MFT.FolderContentsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
