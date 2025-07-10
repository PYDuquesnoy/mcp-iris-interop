/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include Ensemble

Class Ens.Rule.DebugLog Extends (%Persistent, %XML.Adaptor) [ System = 4 ]
{

Index DebugId On DebugId;

Property DebugId As %Integer [ Required ];

Property Message As %String(MAXLEN = 4000, TRUNCATE = 1);

Property Source As %String(MAXLEN = 2000, TRUNCATE = 1);

Property LogType As %String(MAXLEN = 1) [ Required ];

Property IsOtherwise As %Boolean [ InitialExpression = 0 ];

ClassMethod Log(pDebugId As %Integer, pLogType As %String, pSource As %String, pMessage As %String, pIsOtherwise As %Boolean = 0) As %Status
{
	&sql(INSERT INTO Ens_Rule.DebugLog (DebugId, Message, Source, LogType, IsOtherwise)
		VALUES (:pDebugId, :pMessage, :pSource, :pLogType, :pIsOtherwise))
	If SQLCODE {
		Quit $$$ERROR($$$SQLCode,SQLCODE,$get(%msg))
	}
	Quit $$$OK
}

ClassMethod GetNextDebugId() As %Integer [ CodeMode = expression ]
{
$increment(^Ens.Rule.DebugLogC)
}

Storage Default
{
<Data name="DebugLogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>DebugId</Value>
</Value>
<Value name="3">
<Value>Message</Value>
</Value>
<Value name="4">
<Value>Source</Value>
</Value>
<Value name="5">
<Value>LogType</Value>
</Value>
<Value name="6">
<Value>IsOtherwise</Value>
</Value>
</Data>
<DataLocation>^Ens.Rule.DebugLogD</DataLocation>
<DefaultData>DebugLogDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^Ens.Rule.DebugLogD</IdLocation>
<IndexLocation>^Ens.Rule.DebugLogI</IndexLocation>
<StreamLocation>^Ens.Rule.DebugLogS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
