/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// %MFT.UserList lists all users defined for this enterprise or team.
/// Note: Even though this class is in IRISLIB, the storage is in the namespace which creates the instance.
Class %MFT.UserList Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

/// Users is a list of users.
Property Users As list Of %MFT.UserInfo;

Storage Default
{
<Data name="UserListDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Users</Value>
</Value>
</Data>
<DataLocation>^MFT.UserListD</DataLocation>
<DefaultData>UserListDefaultData</DefaultData>
<IdLocation>^MFT.UserListD</IdLocation>
<IndexLocation>^MFT.UserListI</IndexLocation>
<StreamLocation>^MFT.UserListS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
