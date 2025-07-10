/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.CloudStorage.InboundAdapter Extends (EnsLib.CloudStorage.Common, EnsLib.PEX.InboundAdapter) [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Bucket name
Property BucketName As %String(MAXLEN = 1000);

/// Blob name prefix, used to filter blobs on server.
Property BlobNamePrefix As %String(MAXLEN = 1000);

/// Blob name pattern, used to filter blobs on client. Support wildcards ? and *.
Property BlobNamePattern As %String(MAXLEN = 1000);

/// Flag to indicate whether deleting the blob after downlaod
Property DeleteAfterDownload As %Boolean [ InitialExpression = 1 ];

/// Flag to indicate whether appending a timestamp when archiving a blob
Property AppendTimestamp As %Boolean [ InitialExpression = 0 ];

/// Archive bucket name
Property ArchiveBucket As %String(MAXLEN = 1000);

/// Archive folder name
Property ArchiveFolder As %String(MAXLEN = 1000);

/// Error archive bucket name
Property ErrorBucket As %String(MAXLEN = 1000);

/// Error archive folder name
Property ErrorFolder As %String(MAXLEN = 1000);

/// Number of levels of subdirectory depth under the BlobNamePrefix that should be searched for files matching the BlobNamePattern. <br>
/// Use -1 to search all subdirectory levels.
Property SubdirectoryLevels As %Integer(MINVAL = -1) [ InitialExpression = -1 ];

Parameter SETTINGS = "BucketName:Cloud Storage,BlobNamePrefix:Cloud Storage,BlobNamePattern:Cloud Storage,DeleteAfterDownload:Cloud Storage,AppendTimestamp:Cloud Storage,ArchiveBucket:Cloud Storage,ArchiveFolder:Cloud Storage,ErrorBucket:Cloud Storage,ErrorFolder:Cloud Storage";

Method CreateInboundInput(pInput As %Net.Remote.Object) As InboundInput
{
	Set input = ##class(InboundInput).%New()
	Set input.Name = pInput.getName()
	Set input.Meta = pInput.getMeta()
	Set input.Content = pInput.getContent()
	Quit input
}

Method OnInit() As %Status
{
	Set ..%remoteClassname = "com.intersystems.cloud.storage.InboundAdapter"
	Set ..%gatewayName = "%Java Server"
	Set ..%gatewayExtraClasspaths = ..GetCloudClientJARPaths()
	Quit ##super()
}

/// Set global to indicate a blob is processed
Method SetProcessed(BucketName As %String, BlobName As %String, Value As %String)
{
	Set ^Ens.AppData(..BusinessHost.%ConfigName, BucketName, BlobName) = Value
}

/// Test if a blob has been processed
Method IsProcessed(BucketName As %String, BlobName As %String) As %Boolean
{
	Quit $D(^Ens.AppData(..BusinessHost.%ConfigName, BucketName, BlobName))
}

}
