/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Each instance of this class represents a user within the DeepSee User Portal.
/// Each DeepSee user is assumed be a valid system user. This table is used
/// to track additional information about the user within the current namespace.
Class %DeepSee.UserPortal.Data.User Extends (%Persistent, %XML.Adaptor) [ SqlTableName = UserName, System = 4 ]
{

Index userId On userId [ IdKey ];

Index fullName On fullName;

/// User ID ($UserName value).
Property userId As %String(MAXLEN = 200, XMLPROJECTION = "attribute");

/// Full name of the user.<br>
Property fullName As %String(MAXLEN = 128);

/// User's email address, if any.
Property email As %String(MAXLEN = 500, XMLPROJECTION = "attribute");

/// If true, alerts are enabled for this user-- other users can send alerts to this user.
Property alertsEnabled As %Boolean(XMLPROJECTION = "attribute");

Storage Default
{
<Data name="UserDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>userId</Value>
</Value>
<Value name="3">
<Value>email</Value>
</Value>
<Value name="4">
<Value>contactMode</Value>
</Value>
<Value name="5">
<Value>fullName</Value>
</Value>
<Value name="6">
<Value>alertsEnabled</Value>
</Value>
</Data>
<DataLocation>^DeepSee.UserPortal.Data.UserD</DataLocation>
<DefaultData>UserDefaultData</DefaultData>
<IdLocation>^DeepSee.UserPortal.Data.UserD</IdLocation>
<IndexLocation>^DeepSee.UserPortal.Data.UserI</IndexLocation>
<StreamLocation>^DeepSee.UserPortal.Data.UserS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
