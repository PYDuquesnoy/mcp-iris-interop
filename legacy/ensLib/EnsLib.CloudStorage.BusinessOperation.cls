/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.CloudStorage.BusinessOperation Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Parameter ADAPTER = "EnsLib.CloudStorage.OutboundAdapter";

Property Adapter As EnsLib.CloudStorage.OutboundAdapter;

/// Bucket name
Property BucketName As %String(MAXLEN = 1000);

Parameter SETTINGS = "BucketName:Cloud Storage";

Method OnMessage(pRequest As %Library.Persistent, Output pResponse As %Library.Persistent) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..Adapter.CheckGatewayConnection() 
		Quit:$$$ISERR(tSC)
		If pRequest.%Extends("EnsLib.CloudStorage.UploadRequest") {
			Set tSC = ..Upload(pRequest, pResponse)
		}
		ElseIf pRequest.%Extends("EnsLib.CloudStorage.DeleteRequest") {
			Set tSC = ..Delete(pRequest, pResponse)
		}
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method Upload(request As EnsLib.CloudStorage.UploadRequest, Output response As Ens.Response) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..Adapter.UploadBlobFromStream(..BucketName, request.BlobName, request.Content)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method Delete(request As EnsLib.CloudStorage.DeleteRequest, Output response As Ens.Response) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..Adapter.DeleteBlob(..BucketName, request.BlobName)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
