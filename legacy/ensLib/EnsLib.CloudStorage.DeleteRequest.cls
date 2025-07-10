/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.CloudStorage.DeleteRequest Extends Ens.Request
{

Property BlobName As %String(MAXLEN = 1000);

Storage Default
{
<Data name="DeleteRequestDefaultData">
<Subscript>"DeleteRequest"</Subscript>
<Value name="1">
<Value>BlobName</Value>
</Value>
</Data>
<DefaultData>DeleteRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
