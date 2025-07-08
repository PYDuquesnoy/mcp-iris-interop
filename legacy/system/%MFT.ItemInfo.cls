/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %mft

/// %MFT.ItemInfo is a detailed description of a file or folder.
/// Note: Even though this class is in IRISLIB, the storage is in the namespace which creates the instance.
Class %MFT.ItemInfo Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

/// The name of the file or folder item.
Property Name As %String(MAXLEN = 256);

/// The path of the containing folder.
/// This path may not be available for some services.  In that case a relative path is returned.Container may not be available under certain circumstances.
Property Container As %String(MAXLEN = 2048);

/// The type of the item:  $$$MFTfile or $$$MFTfolder.
Property Type As %Integer;

/// The internal item id for this item.
Property ItemId As %String;

/// Modified As %DateTime is the creation time of the item in UTC.
Property Modified As %TimeStamp;

/// The internal id of the user that last modified the item.
/// The GetUsername method must be called to retrieve the external username.
Property ModifiedBy As %String(MAXLEN = 300);

/// Details As %DynamicObject is the service specific dynamic object containing
/// specialized information for this service converted to JSON.
Property Details As %String(MAXLEN = "");

/// Get path of this item
Method GetPath(trailingSlash As %Boolean = 1) As %String [ CodeMode = expression ]
{
$select(..Container="":"",1:..Container_..Name_$select(trailingSlash&&(..Name'="")&&(..Type=$$$MFTfolder):"/",1:""))
}

Storage Default
{
<Data name="ItemInfoDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Container</Value>
</Value>
<Value name="4">
<Value>Type</Value>
</Value>
<Value name="5">
<Value>ItemId</Value>
</Value>
<Value name="6">
<Value>Modified</Value>
</Value>
<Value name="7">
<Value>ModifiedBy</Value>
</Value>
<Value name="8">
<Value>Details</Value>
</Value>
</Data>
<DataLocation>^MFT.ItemInfoD</DataLocation>
<DefaultData>ItemInfoDefaultData</DefaultData>
<IdLocation>^MFT.ItemInfoD</IdLocation>
<IndexLocation>^MFT.ItemInfoI</IndexLocation>
<StreamLocation>^MFT.ItemInfoS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
