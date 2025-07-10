/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.CloudStorage.UploadRequest Extends Ens.Request
{

Property BlobName As %String(MAXLEN = 1000);

Property Content As %GlobalBinaryStream;

Storage Default
{
<Data name="UploadRequestDefaultData">
<Subscript>"UploadRequest"</Subscript>
<Value name="1">
<Value>BlobName</Value>
</Value>
<Value name="2">
<Value>Content</Value>
</Value>
</Data>
<DefaultData>UploadRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
