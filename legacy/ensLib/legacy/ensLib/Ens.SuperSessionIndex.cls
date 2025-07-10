/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.SuperSessionIndex Extends %Persistent [ System = 4 ]
{

// This is a bitmap candidate, though not necessarily a strong one

Index SuperSession On SuperSession As SQLUPPER(250);

// If we can assume a message is only part of one SuperSession, this should be unique

Index MessageHeader On MessageHeader;

ForeignKey MessageHeaderFKey(MessageHeader) References Ens.MessageHeader() [ OnDelete = cascade ];

Property SuperSession As %String(MAXLEN = 300) [ Required ];

Property MessageHeader As Ens.MessageHeader [ Required ];

Storage Default
{
<Data name="SuperSessionIndexDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>SuperSession</Value>
</Value>
<Value name="3">
<Value>MessageHeader</Value>
</Value>
</Data>
<DataLocation>^Ens.SuperSessionIndexD</DataLocation>
<DefaultData>SuperSessionIndexDefaultData</DefaultData>
<IdLocation>^Ens.SuperSessionIndexD</IdLocation>
<IndexLocation>^Ens.SuperSessionIndexI</IndexLocation>
<StreamLocation>^Ens.SuperSessionIndexS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
