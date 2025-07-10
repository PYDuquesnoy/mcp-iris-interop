/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.CloudStorage.OutboundAdapter Extends (EnsLib.PEX.OutboundAdapter, EnsLib.CloudStorage.Common) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Presigned URL <br>
/// All other settings will be ignored if a Presigned URL is provided.
Property PresignedUrl As %String(MAXLEN = 10000);

Method OnInit() As %Status
{
	Set ..%remoteClassname = "com.intersystems.cloud.storage.OutboundAdapter"
	Set ..%gatewayName = "%Java Server"
	Set ..%gatewayExtraClasspaths = ..GetCloudClientJARPaths()
	Quit ##super()
}

Method UploadBlobFromString(bucketName As %String, bolbName As %String, content As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Do ..%gatewayProxy.uploadBlobFromString(bucketName, bolbName, content)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method UploadBlobFromStream(bucketName As %String, blobName As %String, content As %Stream.Object) As %Status
{
	Set tSC = $$$OK
	Try {
		Do ..%gatewayProxy.uploadBlobFromIStream(bucketName, blobName, content)
	} Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method UploadBlobFromFile(bucketName As %String, blobName As %String, filePath As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Do ..%gatewayProxy.uploadBlobFromFile(bucketName, blobName, filePath)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

Method DeleteBlob(bucketName As %String, blobName As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		Do ..%gatewayProxy.deleteBlob(bucketName, blobName)
	}
	Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}
