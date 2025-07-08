/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SQL.Diag.Message Extends %Library.Persistent [ Final, StorageStrategy = diagStorage, System = 4 ]
{

Parameter USEEXTENTSET = 1;

Parameter DEFAULTGLOBAL = "^IRIS.sql.diag.message";

Parameter SQLPUBLICSECURITY = "{""Message"":""S,D""}";

Property diagResult As %SQL.Diag.Result [ Required ];

Property messageTime As %Library.PosixTime [ ReadOnly, SqlComputeCode = { set {*}=##class(%PosixTime).CurrentUTCTimeStamp()}, SqlComputed, SqlComputeOnChange = %%INSERT ];

/// actor is the name of the entity reporting the message
Property actor As %String;

Property sqlcode As %Library.Integer;

Property message As %Library.String(MAXLEN = "");

Property severity As %Library.EnumString(DISPLAYLIST = ", completed,info,warning,error,abort", VALUELIST = ",0,1,2,3,4");

Index xdr On diagResult [ Type = bitmap ];

/// Description
ForeignKey fkDiagResult(diagResult) References %SQL.Diag.Result() [ OnDelete = cascade ];

Storage diagStorage
{
<Data name="MessageDefaultData">
<Value name="1">
<Value>diagResult</Value>
</Value>
<Value name="2">
<Value>messageTime</Value>
</Value>
<Value name="3">
<Value>actor</Value>
</Value>
<Value name="4">
<Value>sqlcode</Value>
</Value>
<Value name="5">
<Value>message</Value>
</Value>
<Value name="6">
<Value>severity</Value>
</Value>
</Data>
<DataLocation>^IRIS.sql.diag.message.1</DataLocation>
<DefaultData>MessageDefaultData</DefaultData>
<ExtentLocation>^IRIS.sql.diag.message</ExtentLocation>
<IdLocation>^IRIS.sql.diag.message.1</IdLocation>
<Index name="$Message">
<Location>^IRIS.sql.diag.message.2</Location>
</Index>
<Index name="IDKEY">
<Location>^IRIS.sql.diag.message.1</Location>
</Index>
<Index name="xdr">
<Location>^IRIS.sql.diag.message.3</Location>
</Index>
<IndexLocation>^IRIS.sql.diag.message.I</IndexLocation>
<StreamLocation>^IRIS.sql.diag.message.S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
