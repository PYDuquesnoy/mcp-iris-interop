/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Each instance of this class represents an alert within the DeepSee User Portal.
Class %DeepSee.UserPortal.Data.Alert Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

Index userId On (userId, createDate) [ Type = bitmap ];

/// Time when alert was created.
Property createDate As %TimeStamp(XMLPROJECTION = "attribute") [ InitialExpression = {$ZDT($H,3)} ];

/// User ID of user that sent this alert.
Property senderId As %String(MAXLEN = 200, XMLPROJECTION = "attribute");

/// User ID of receipient of this alert.
Property userId As %String(MAXLEN = 200, XMLPROJECTION = "attribute");

/// Subject line for this alert.
Property subject As %String(MAXLEN = 200, XMLPROJECTION = "attribute");

/// Additional comments for this alert.
Property comments As %String(MAXLEN = 5000, XMLPROJECTION = "attribute");

/// True if this alert has not been reviewed yet.
Property isNew As %Boolean(XMLPROJECTION = "attribute") [ InitialExpression = 1 ];

/// ID of folder item to display for this alert.
Property dataId As %String(MAXLEN = 200, XMLPROJECTION = "attribute");

/// Priority of this alert (null is medium).
Property priority As %String(MAXLEN = 200, VALUELIST = ",low,high", XMLPROJECTION = "attribute");

Storage Default
{
<Data name="AlertDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>createDate</Value>
</Value>
<Value name="3">
<Value>senderId</Value>
</Value>
<Value name="4">
<Value>userId</Value>
</Value>
<Value name="5">
<Value>subject</Value>
</Value>
<Value name="6">
<Value>comments</Value>
</Value>
<Value name="7">
<Value>isNew</Value>
</Value>
<Value name="8">
<Value>dataId</Value>
</Value>
<Value name="9">
<Value>priority</Value>
</Value>
</Data>
<DataLocation>^DeepSee.UserPortal.Data.AlertD</DataLocation>
<DefaultData>AlertDefaultData</DefaultData>
<IdLocation>^DeepSee.UserPortal.Data.AlertD</IdLocation>
<IndexLocation>^DeepSee.UserPortal.Data.AlertI</IndexLocation>
<StreamLocation>^DeepSee.UserPortal.Data.AlertS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
