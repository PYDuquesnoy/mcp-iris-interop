/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %MFT.UserInfo is a detailed description of a user
/// Note: Even though this class is in IRISLIB, the storage is in the namespace which creates the instance.
Class %MFT.UserInfo Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

/// Username is the unique username for this user.
/// It is currently the user's email address for all supported services.
Property Username As %Library.Username;

/// Name is the name of the user.
Property Name As %String(MAXLEN = 256);

/// UserId is the internal user id for this user.
Property Userid As %String;

/// Details is the service specific dynamic object containing specialized information for this user converted to JSON.
Property Details As %String(MAXLEN = "");

Storage Default
{
<Data name="UserInfoDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Username</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="4">
<Value>Userid</Value>
</Value>
<Value name="5">
<Value>Details</Value>
</Value>
</Data>
<DataLocation>^MFT.UserInfoD</DataLocation>
<DefaultData>UserInfoDefaultData</DefaultData>
<IdLocation>^MFT.UserInfoD</IdLocation>
<IndexLocation>^MFT.UserInfoI</IndexLocation>
<StreamLocation>^MFT.UserInfoS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
