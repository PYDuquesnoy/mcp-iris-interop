/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Library.SQLConnection Extends (%Persistent, %XML.Adaptor) [ Not ProcedureBlock, SqlTableName = sys_SQLConnection, StorageStrategy = StorageSpec, System = 4 ]
{

/// Index for property Name
Index NameIndex On Name [ Unique ];

Property Name As %String(CAPTION = "Connection Name") [ Required, SqlFieldName = Connection_Name ];

Property DSN As %String(CAPTION = "DSN", MAXLEN = 256);

Property Usr As %String(CAPTION = "User");

Property pwd As %CSP.Util.Passwd(CAPTION = "Password", MAXLEN = "");

Property ReverseOJ As %Boolean(CAPTION = "Legacy Sybase outer join syntax");

Property isJDBC As %Boolean(CAPTION = "Is JDBC connection");

Property useCAST As %Boolean(CAPTION = "Use CAST as VARCHAR");

Property useCASTCHAR As %Boolean(CAPTION = "Use CAST as CHAR");

Property useCOALESCE As %Boolean(CAPTION = "Use COALESCE") [ InitialExpression = 1 ];

Property URL As %String(CAPTION = "URL", MAXLEN = 4096);

Property driver As %String(CAPTION = "driver", MAXLEN = 256);

Property xadriver As %String(CAPTION = "driver", MAXLEN = 256);

Property classpath As %Library.String(CAPTION = "Class Path", MAXLEN = 4096);

Property properties As %Library.String(CAPTION = "Properties", MAXLEN = 256);

Property nodefq As %Boolean(CAPTION = "Do not use delimited identifiers by default");

Property noconcat As %Boolean(CAPTION = "Do not generate {fn concat()}");

Property nofnconv As %Boolean(CAPTION = "Do not generate {fn conv ...} by default");

Property needlongdatalen As %Boolean(CAPTION = "Needs long data length");

Property nvl As %Boolean(CAPTION = "Use NVL() instead of IFNULL()");

Property bUnicodeStream As %Boolean(CAPTION = "Supports Unicode Streams") [ InitialExpression = 1 ];

Property tpw As %String [ Private, Transient ];

Property bEncode As %Boolean [ InitialExpression = 1, Private, Transient ];

/// Bind TIMESTAMP type parmaters as VARCHAR.
/// When binding parameter values via the GateWay, some remote systems consider TIMESTAMP as a special structure that does not
/// match the the %TimeStamp datatype format of YYYY-MM-DD HH24:MI;SS[.ssssss].
/// Setting this property to 1 will bind TIMESTAMP parameters as VARCHARs instead of TIMESTAMP.
/// You might need this setting when binding TIMESTAMP parameters to Oracle, depending on the Oracle driver used.
Property bindTSasString As %Boolean(CAPTION = "Bind TIMESTAMP parameters as VARCHAR") [ InitialExpression = 0 ];

/// Statement to execute on remote system immediately after connection.
/// This is only for a Gateway conenction through %Library.GTWConnection.Connect() method.
/// An example usage of this would be to set a session parameter on an Oracle connection:
///    ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS.FF6'
Property OnConnectStatement As %String(CAPTION = "Statement to execute upon connection", MAXLEN = 4096);

/// This property determines whether or not to close the gateway connection after all users of this connection (linked table queries or %SQLGatewayConnection objects) 
/// have closed. This is tracked per-process.
Property disconnectOnClose As %Boolean(CAPTION = "Close the connection after each user of the connection in one process closes") [ InitialExpression = 0 ];

Method setEncode(val As %Boolean)
{
	set ..bEncode = val
}

ClassMethod ConnExists(nm As %String) As %Boolean
{
	New str
	set str=""
	&sql(select connection_name into :str from %Library.sys_SQLConnection where connection_name=:nm)
	Quit str'=""
}

/// Lookup by Connection name
Query ByName(name As %String = "") As %SQLQuery(ROWSPEC = "Connection_Name,DSN,User,ID,isJDBC") [ SqlProc ]
{
 SELECT  Connection_Name, DSN, usr, %ID, isJDBC
 FROM %Library.sys_SQLConnection
 WHERE Connection_Name %STARTSWITH %ALPHAUP(:name)
 ORDER BY Connection_Name
}

/// Lookup by Connection name without input parameter
Query ByConnection() As %SQLQuery(ROWSPEC = "Connection_Name,DSN,User,ID") [ SqlProc ]
{
 SELECT  Connection_Name, DSN, usr, %ID
 FROM %Library.sys_SQLConnection
 WHERE Connection_Name is not null
 ORDER BY Connection_Name
}

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that the object is being saved. It is called before 
/// any data is written to disk.
/// 
/// <P><VAR>insert</VAR> will be set to 1 if this object is being saved for the first time.
/// 
/// <P>If this method returns an error then the call to <METHOD>%Save</METHOD> will fail.
Method %OnBeforeSave(insert As %Boolean) As %Status [ Private ]
{
	s ..tpw=..pwd
	if ..bEncode s ..pwd=$$pp^%apiGTW(..pwd)
	q $$$OK
}

/// This callback method is invoked by the <METHOD>%Save</METHOD> method to 
/// provide notification that the object is being saved. It is called after 
/// the object's data has been successfully written to disk.
/// 
/// <P><VAR>insert</VAR> will be set to 1 if this object is being saved for the first time.
/// 
/// <P>If this method returns an error then the call to <METHOD>%Save</METHOD> will fail.
Method %OnAfterSave(insert As %Boolean) As %Status [ Private ]
{
	s ..pwd=..tpw
	q $$$OK
}

Storage StorageSpec
{
<Data name="SQLConnectionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>DSN</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
<Value name="4">
<Value>Usr</Value>
</Value>
<Value name="5">
<Value>pwd</Value>
</Value>
<Value name="6">
<Value>ReverseOJ</Value>
</Value>
<Value name="7">
<Value>isJDBC</Value>
</Value>
<Value name="8">
<Value>URL</Value>
</Value>
<Value name="9">
<Value>driver</Value>
</Value>
<Value name="10">
<Value>classpath</Value>
</Value>
<Value name="11">
<Value>properties</Value>
</Value>
<Value name="12">
<Value>useCAST</Value>
</Value>
<Value name="13">
<Value>xadriver</Value>
</Value>
<Value name="14">
<Value>nodefq</Value>
</Value>
<Value name="15">
<Value>nofnconv</Value>
</Value>
<Value name="16">
<Value>useCOALESCE</Value>
</Value>
<Value name="17">
<Value>needlongdatalen</Value>
</Value>
<Value name="18">
<Value>bUnicodeStream</Value>
</Value>
<Value name="19">
<Value>useCASTCHAR</Value>
</Value>
<Value name="20">
<Value>noconcat</Value>
</Value>
<Value name="21">
<Value>nvl</Value>
</Value>
<Value name="22">
<Value>bindTSasString</Value>
</Value>
<Value name="23">
<Value>OnConnectStatement</Value>
</Value>
<Value name="24">
<Value>disconnectOnClose</Value>
</Value>
</Data>
<DataLocation>^%SYS("sql","ODBCCONNECTION","DATA")</DataLocation>
<DefaultData>SQLConnectionDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^%SYS("sql","ODBCCONNECTION","DATA")</IdLocation>
<IndexLocation>^%SYS("sql","ODBCCONNECTION","INDEX")</IndexLocation>
<StreamLocation>^%Library.SQLConnectionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
