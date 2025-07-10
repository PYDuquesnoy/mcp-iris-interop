/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Subclass of Ens.Util.Log that lives only on the Message Bank Server, incorporating the original event log entry from the client plus a record of the client node it came from
Class Ens.Enterprise.MsgBank.Log Extends (%Persistent, Ens.Util.LogBase, %XML.Adaptor) [ Inheritance = right, System = 4 ]
{

Parameter XMLTYPE = "MsgBankLogEvent";

Property ID As %Integer(MINVAL = 1, XMLPROJECTION = "NONE");

Index ID On ID [ IdKey ];

Index Extent [ Extent, Type = bitmap ];

Index TimeLogged On TimeLogged;

Index Type On Type [ Type = bitmap ];

Index ConfigName On ConfigName [ Type = bitmap ];

Property TimeBanked As Ens.DataType.UTC [ InitialExpression = {$ZDT($ZTS,3,,3)} ];

Property NodeId As %Integer(MAXVAL = 999, MINVAL = 100) [ Calculated, ReadOnly, SqlComputeCode = { Set {NodeId}=$E({ID},1,3) }, SqlComputed, Transient ];

Property ClientId As %Integer(MINVAL = 1) [ Calculated, ReadOnly, SqlComputeCode = { Set {ClientId}=$E({ID},4,*) }, SqlComputed, Transient ];

Property ClientSessionId As %Integer(MINVAL = 1) [ Calculated, ReadOnly, SqlComputeCode = { Set {ClientSessionId}=$E({SessionId},4,*) }, SqlComputed, Transient ];

Method NodeIdGet() As %Integer [ CodeMode = expression ]
{
$E(..%Id(),1,3)
}

Method ClientIdGet() As %Integer [ CodeMode = expression ]
{
$E(..%Id(),4,*)
}

Method ClientSessionIdGet() As %Integer [ CodeMode = expression ]
{
$E(..SessionId,4,*)
}

/// The same as %IdSet(), but works even if the object hasn't been saved already
Method SetEventId(pNodeClientId As %Integer) [ CodeMode = generator ]
{
	$$$GENERATE(" Lock +"_$$$EXTidlocation($$$pEXT,%class))
	$$$GENERATE(" Set:pNodeClientId>$G("_$$$EXTidlocation($$$pEXT,%class)_") "_$$$EXTidlocation($$$pEXT,%class)_"=pNodeClientId")
	$$$GENERATE(" Lock -"_$$$EXTidlocation($$$pEXT,%class))
	$$$GENERATE(" Do ..%IdSet(pNodeClientId)")
}

ClassMethod Purge(Output pDeletedCount As %Integer, pDaysToKeep As %Integer = 7, pBitmapPurgeRunLimit As %Integer = 600) As %Status [ Internal ]
{
	New %tDoNotDeleteDate,%tID Set %tID="", %tDoNotDeleteDate = ##class(Ens.Purge).GetDoNotDeleteDate(pDaysToKeep)
	Set SQLCODE=0, pDeletedCount=0
	&sql(DECLARE C1 CURSOR FOR
		Select ID Into :%tID From Ens_Enterprise_MsgBank.Log Where TimeLogged < :%tDoNotDeleteDate)
	&sql(OPEN C1) For { &sql(FETCH C1)  Quit:SQLCODE
		&sql(Delete From Ens_Enterprise_MsgBank.Log Where ID=:%tID)
		Set pDeletedCount=pDeletedCount+%ROWCOUNT
	} Set tCode=SQLCODE &sql(CLOSE C1) Set:'SQLCODE SQLCODE=tCode
	Quit:SQLCODE&&(SQLCODE'=100) $$$ERROR($$$EnsErrGeneral,"Purge error at ID "_%tID _"; SQLCODE = "_SQLCODE)
	Set tSC = ..PurgeBitmaps(pBitmapPurgeRunLimit,.tDeletedChunks)
	Merge pDeletedCount("bitmap chunks") = tDeletedChunks
	Quit tSC
}

Storage Default
{
<Data name="LogDefaultData1">
<Subscript>"Log"</Subscript>
<Value name="1">
<Value>NodeId</Value>
</Value>
<Value name="2">
<Value>ClientId</Value>
</Value>
<Value name="3">
<Value>TimeBanked</Value>
</Value>
<Value name="4">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="5">
<Value>SourceClass</Value>
</Value>
<Value name="6">
<Value>SourceMethod</Value>
</Value>
<Value name="7">
<Value>Text</Value>
</Value>
<Value name="8">
<Value>Type</Value>
</Value>
<Value name="9">
<Value>TimeLogged</Value>
</Value>
<Value name="10">
<Value>SessionId</Value>
</Value>
<Value name="11">
<Value>ConfigName</Value>
</Value>
<Value name="12">
<Value>TraceCat</Value>
</Value>
<Value name="13">
<Value>Job</Value>
</Value>
<Value name="14">
<Value>Stack</Value>
</Value>
<Value name="15">
<Value>MessageId</Value>
</Value>
<Value name="16">
<Value>StatusValue</Value>
</Value>
</Data>
<DataLocation>^Ens.EntMsgBank.LogD</DataLocation>
<DefaultData>LogDefaultData1</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.EntMsgBank.LogD</IdLocation>
<IndexLocation>^Ens.EntMsgBank.LogI</IndexLocation>
<StreamLocation>^Ens.EntMsgBank.LogS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
