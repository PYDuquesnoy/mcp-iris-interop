/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Net.Cloud.Storage.Client Extends %RegisteredObject [ Language = objectscript ]
{

Parameter BUFFERLENGTH = 32000;

/// Connection to a Java Gateway
Property gateway As %External.JavaGateway;

/// Remote Java client object to Azure, Google or S3 
Property jclient As %Net.Remote.Object;

/// Convert a stream to binary stream encoded in UTF-8
ClassMethod ToUTF8(stream As %Stream.Object) As %Stream.TmpBinary [ Private ]
{
	// Create binary stream
	Set bs = ##class(%Stream.TmpBinary).%New()
	Do stream.Rewind()
	While (stream.AtEnd = 0) {
		Set len = ..#BUFFERLENGTH
		Set buffer = stream.Read(.len)
		// Convert to UTF8
		Set utf8 = $ZCONVERT(buffer, "O", "UTF8")
		// Write to binary stream
		Do bs.Write(utf8)
	}
	Quit bs
}

/// Test if a bucket exists
Method BucketExists(bucketName As %String) As %Boolean
{
	Quit ..jclient.bucketExists(bucketName)
}

/// Get bucket info
Method GetBucketInfo(bucketName As %String) As BucketInfo
{
	Set jb = ..jclient.getBucketInfo(bucketName)
	Quit:jb="" ""
	Set bucketInfo = ##class(BucketInfo).%New()
	Set bucketInfo.name = jb.getName()
	Set bucketInfo.owner = jb.getOwner()
	Set createTime = jb.getCreateTime()
	Set:createTime'="" bucketInfo.createTime = createTime.toString()
	Set updateTime = jb.getUpdateTime()
	Set:updateTime'="" bucketInfo.updateTime = updateTime.toString()
	Quit bucketInfo
}

/// Create a new bucket
Method CreateBucket(bucketName As %String)
{
	Do ..jclient.createBucket(bucketName)
}

/// List all buckets
Method ListBuckets() As %ListOfObjects
{
	Set jbl = ..jclient.listBuckets()
	Set size = jbl.size()
	Set bucketList = ##class(%ListOfObjects).%New()
	For i=0:1:(size-1) {
		Set jb = jbl.get(i)
		Set bucketInfo = ##class(BucketInfo).%New()
		Set bucketInfo.name = jb.getName()
		Set bucketInfo.owner = jb.getOwner()
		Set createTime = jb.getCreateTime()
		Set:createTime'="" bucketInfo.createTime = createTime.toString()
		Set updateTime = jb.getUpdateTime()
		Set:updateTime'="" bucketInfo.updateTime = updateTime.toString()
		Do bucketList.Insert(bucketInfo)
	}
	Quit bucketList
}

/// Delete a bucket from the cloud
Method DeleteBucket(bucketName As %String)
{
	Do ..jclient.deleteBucket(bucketName)
}

/// Test if a blob exists
Method BlobExists(bucketName As %String, blobName As %String) As %Boolean
{
	Quit ..jclient.blobExists(bucketName, blobName)
}

/// Get blob info
Method GetBlobInfo(bucketName As %String, blobName As %String) As BlobInfo
{
	Set jb = ..jclient.getBlobInfo(bucketName, blobName)
	Quit:jb="" ""
	Set blobInfo = ##class(BlobInfo).%New()
	Set blobInfo.bucketName = jb.getBucketName()
	Set blobInfo.name = jb.getName()
	Set blobInfo.owner = jb.getOwner()
	Set blobInfo.size = jb.getSize()
	Set createTime = jb.getCreateTime()
	Set:createTime'="" blobInfo.createTime = createTime.toString()
	Set updateTime = jb.getUpdateTime()
	Set:updateTime'="" blobInfo.updateTime = updateTime.toString()
	Quit blobInfo
}

/// List all blobs within a bucket, filtered by blobNamePrefix and blobNamePattern.
/// bucketName: bucket name
/// blobNamePrefix: blob name prefix, used to filter the result on the server.
/// blobNamePattern: blob name pattern, used to filter the result by the client. Support wild cards "?" and "*".
Method ListBlobs(bucketName As %String, blobNamePrefix As %String = "", blobNamePattern As %String = "") As %ListOfObjects
{
	Set jbl = ..jclient.listBlobs(bucketName, blobNamePrefix, blobNamePattern)
	Set size = jbl.size()
	Set blobList = ##class(%ListOfObjects).%New()
	For i=0:1:(size-1) {
		Set jb = jbl.get(i)
		Set blobInfo = ##class(BlobInfo).%New()
		Set blobInfo.bucketName = jb.getBucketName()
		Set blobInfo.name = jb.getName()
		Set blobInfo.owner = jb.getOwner()
		Set blobInfo.size = jb.getSize()
		Set createTime = jb.getCreateTime()
		Set:createTime'="" blobInfo.createTime = createTime.toString()
		Set updateTime = jb.getUpdateTime()
		Set:updateTime'="" blobInfo.updateTime = updateTime.toString()
		Do blobList.Insert(blobInfo)
	}
	Quit blobList
}

/// Upload a string blob to the cloud
/// String content will be encoded as UTF-8
Method UploadBlobFromString(bucketName As %String, blobName As %String, content As %String)
{
	Do ..jclient.uploadBlobFromString(bucketName, blobName, content)
}

/// Upload a file blob to the cloud
Method UploadBlobFromFile(bucketName As %String, blobName As %String, filePath As %String)
{
	Do ..jclient.uploadBlobFromFile(bucketName, blobName, filePath)
}

/// Upload a binary or character stream blob to the cloud
/// For character stream, its content is converted to UTF-8 first, then uploaded as binary stream.
Method UploadBlobFromStream(bucketName As %String, blobName As %String, stream As %Stream.Object)
{
	Set bs = $S(stream.IsCharacter():..ToUTF8(stream), 1:stream)
	Do ..jclient.uploadBlobFromIStream(bucketName, blobName, bs)
}

Method UploadBlobWithPresignedUrl(presignedUrl As %String, stream As %Stream.Object)
{
	Do ..jclient.uploadBlobWithPresignedUrl(presignedUrl, stream)
}

/// Download a blob from the cloud to a string
/// blobEncoding: Blob content encoding, the name follows Java convention.
/// If blobEncoding = "", treat the blob content as encoded in UTF-8.
Method DownloadBlobToString(bucketName As %String, blobName As %String, blobEncoding As %String = "") As %String
{
	Quit $S(blobEncoding="":..jclient.downloadBlobToString(bucketName, blobName),
			1:..jclient.downloadBlobToString(bucketName, blobName, blobEncoding))
}

/// Download a blob from the cloud to a file
Method DownloadBlobToFile(bucketName As %String, blobName As %String, filePath As %String)
{
	Do ..jclient.downloadBlobToFile(bucketName, blobName, filePath)
}

/// Download a blob from the cloud to a stream
/// blobEncoding name follows Java convention
/// If blobEncoding = "", the returning stream is %GlobalBinarayStream; otherwise, it is %GlobalCharacterStream.
Method DownloadBlobToStream(bucketName As %String, blobName As %String, blobEncoding As %String = "") As %Stream.Object
{
	Quit $S(blobEncoding="":..jclient.downloadBlobToIStream(bucketName, blobName), 
			1:..jclient.downloadBlobToICStream(bucketName, blobName, blobEncoding))
}

/// Delete a blob from the cloud
Method DeleteBlob(bucketName As %String, blobName As %String)
{
	Do ..jclient.deleteBlob(bucketName, blobName)
}

/// Test if a bucket is public accessible
Method IsBucketPublicAccessible(bucketName As %String) As %Boolean
{
	Quit ..jclient.isBucketPublicAccessible(bucketName)
}

/// Close storage client and disconnect Java gateway 
Method Close()
{
	Do ..jclient.close()
	Do ..gateway.%Disconnect()
}

/// Create a Java gateway connection
ClassMethod CreateGateway(javaServer As %RawString) As %External.JavaGateway [ Private ]
{
	If javaServer'="" {
		Set gateway = $SYSTEM.external.getGateway(javaServer)
	}
	Else {
		Set gateway = $SYSTEM.external.getJavaGateway()
	}
	Quit gateway
}

/// Factory method to create a cloud storage client.
/// javaServer: Java gateway name, default to default Java gateway.
/// storageProvider: Specify storage provider. 0: Amazon S3, 1: Azure Blob, 2: Google Cloud Storage.
/// credentialsFile: File name containing credentials for specific storage provider.
/// region: Cloud storage region for specific storage provider.
/// sc: returning status code.
/// endPoint: Optional PrivateLink endpoint
ClassMethod CreateClient(javaServer As %RawString = "", storageProvider As %Integer, credentialsFile As %String = "", region As %String, Output sc As %Status, endPoint As %String = "") As Client
{
	Set sc = $$$OK
	#Dim client As Client = ""
	Try {
		Set gateway = ..CreateGateway(javaServer)
		If '$IsObject(gateway) {
			Set sc = $$$ERROR($$$GeneralError, "Error connecting to Java Gateway "_javaServer)
			Quit
		}
		
		// Jar home dir
		Set jarDir = ##class(%Library.File).NormalizeFilename($System.Util.InstallDirectory()_"/dev/java/lib/1.8")
		// Get utils JAR paths
		Set utilsJARpath = ##class(%Library.File).NormalizeFilename(##class(%External.Gateway).getJarPath("intersystems-utils"), jarDir)
		Set utilsJARpath = ##class(%Library.File).NormalizeFilenameWithSpaces(utilsJARpath)
		// Get cloudclient JAR paths
		Set cloudJARpath = ##class(%Library.File).NormalizeFilename(##class(%External.Gateway).getJarPath("intersystems-cloudclient"), jarDir)
		Set cloudJARpath = ##class(%Library.File).NormalizeFilenameWithSpaces(cloudJARpath)
		// 	Add to class path
		Do gateway.addToPath(utilsJARpath).addToPath(cloudJARpath)

		Set jclient = gateway.invoke("com.intersystems.cloud.storage.ClientFactory", "createStorageClient", storageProvider, endPoint, credentialsFile, region)
		If '$IsObject(jclient) {
			Set sc = $$$ERROR($$$GeneralError, "Error creating StorageClient ")
			Quit
		}

		// Cast Java client
		Set jclient = $CASE(storageProvider, 
							0:jclient.%CastAs("com.intersystems.cloud.storage.AmazonS3Client"),
							1:jclient.%CastAs("com.intersystems.cloud.storage.AzureBlobClient"),
							2:jclient.%CastAs("com.intersystems.cloud.storage.GCSClient"),
							:jclient)
							
		Set client = $S(storageProvider=0:##class(AmazonS3Client).%New(), 
						storageProvider=1:##class(AzureBlobClient).%New(), 
						storageProvider=2:##class(GCSClient).%New(), 1:"")
		If '$IsObject(client) {
			Set sc = $$$ERROR($$$GeneralError, "Error creating Client ")
			Quit
		}
		Set client.gateway = gateway
		Set client.jclient = jclient
	}
	Catch (ex) {
		Set sc = ex.AsStatus()
	}
	Quit client
}

/// Single method to upload blob from string
ClassMethod SingleUploadBlobFromString(javaServer As %RawString = "", storageProvider As %Integer, credentialsFile As %String = "", region As %String, endPoint As %String = "", bucketName As %String, blobName As %String, content As %String) As %Status
{
	Set sc = $$$OK
	#Dim client As Client = ""
	Try {
		Set client = ..CreateClient(javaServer, storageProvider, credentialsFile, region, .sc, endPoint)
		Quit:$$$ISERR(sc)
		Do client.UploadBlobFromString(bucketName, blobName, content)
	}
	Catch (ex) {
		Set sc = ex.AsStatus()
	}
	Do:$IsObject(client) client.Close()
	Quit sc
}

/// Single method to upload blob from file
ClassMethod SingleUploadBlobFromFile(javaServer As %RawString = "", storageProvider As %Integer, credentialsFile As %String = "", region As %String, endPoint As %String = "", bucketName As %String, blobName As %String, filePath As %String) As %Status
{
	Set sc = $$$OK
	#Dim client As Client = ""
	Try {
		Set client = ..CreateClient(javaServer, storageProvider, credentialsFile, region, .sc, endPoint)
		Quit:$$$ISERR(sc)
		Do client.UploadBlobFromFile(bucketName, blobName, filePath)
	}
	Catch (ex) {
		Set sc = ex.AsStatus()
	}
	Do:$IsObject(client) client.Close()
	Quit sc
}

/// Single method to upload blob from stream
ClassMethod SingleUploadBlobFromStream(javaServer As %RawString = "", storageProvider As %Integer, credentialsFile As %String = "", region As %String, endPoint As %String = "", bucketName As %String, blobName As %String, stream As %Stream.Object) As %Status
{
	Set sc = $$$OK
	#Dim client As Client = ""
	Try {
		Set client = ..CreateClient(javaServer, storageProvider, credentialsFile, region, .sc, endPoint)
		Quit:$$$ISERR(sc)
		Do client.UploadBlobFromStream(bucketName, blobName, stream)
	}
	Catch (ex) {
		Set sc = ex.AsStatus()
	}
	Do:$IsObject(client) client.Close()
	Quit sc
}

/// Single method to download blob to string
ClassMethod SingleDownloadBlobToString(javaServer As %RawString = "", storageProvider As %Integer, credentialsFile As %String = "", region As %String, endPoint As %String = "", bucketName As %String, blobName As %String, blobEncoding As %String = "", Output toString As %String) As %Status
{
	Set sc = $$$OK
	#Dim client As Client = ""
	Try {
		Set client = ..CreateClient(javaServer, storageProvider, credentialsFile, region, .sc, endPoint)
		Quit:$$$ISERR(sc)
		Set toString = client.DownloadBlobToString(bucketName, blobName, blobEncoding)
	}
	Catch (ex) {
		Set sc = ex.AsStatus()
	}
	Do:$IsObject(client) client.Close()
	Quit sc
}

/// Single method to download blob to file
ClassMethod SingleDownloadBlobToFile(javaServer As %RawString = "", storageProvider As %Integer, credentialsFile As %String = "", region As %String, endPoint As %String = "", bucketName As %String, blobName As %String, filePath As %String) As %Status
{
	Set sc = $$$OK
	#Dim client As Client = ""
	Try {
		Set client = ..CreateClient(javaServer, storageProvider, credentialsFile, region, .sc, endPoint)
		Quit:$$$ISERR(sc)
		Do client.DownloadBlobToFile(bucketName, blobName, filePath)
	}
	Catch (ex) {
		Set sc = ex.AsStatus()
	}
	Do:$IsObject(client) client.Close()
	Quit sc
}

/// Single method to download blob to stream
ClassMethod SingleDownloadBlobToStream(javaServer As %RawString = "", storageProvider As %Integer, credentialsFile As %String = "", region As %String, endPoint As %String = "", bucketName As %String, blobName As %String, blobEncoding As %String = "", Output toStream As %Stream.Object) As %Status
{
	Set sc = $$$OK
	#Dim client As Client = ""
	Try {
		Set client = ..CreateClient(javaServer, storageProvider, credentialsFile, region, .sc, endPoint)
		Quit:$$$ISERR(sc)
		Set toStream = client.DownloadBlobToStream(bucketName, blobName, blobEncoding)
	}
	Catch (ex) {
		Set sc = ex.AsStatus()
	}
	Do:$IsObject(client) client.Close()
	Quit sc
}

/// Copy a blob from source to target
Method CopyBlob(sourceBucketName As %String, sourceBlobName As %String, targetBucketName As %String, targetBlobName As %String)
{
	Do ..jclient.copyBlob(sourceBucketName, sourceBlobName, targetBucketName, targetBlobName)
}

/// Move a blob from source to target
Method MoveBlob(sourceBucketName As %String, sourceBlobName As %String, targetBucketName As %String, targetBlobName As %String)
{
	Do ..jclient.moveBlob(sourceBucketName, sourceBlobName, targetBucketName, targetBlobName)
}

/// Test if a bucket is writable
Method IsBucketWritable(bucketName As %String)
{
	Quit ..jclient.isBucketWritable(bucketName)
}

}
