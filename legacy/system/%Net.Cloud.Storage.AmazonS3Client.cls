/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %Net.Cloud.Storage.AmazonS3Client Extends Client
{

/// Get AWS S3 account id
Method GetS3AccountId() As %String
{
	Quit ..jclient.getS3AccountId()
}

/// Create an S3 AccessControlList object from scratch
Method CreateAcl(ownerId As %String = "", ownerDisplayName As %String = "") As %Net.Remote.Object
{
	Quit ..jclient.createAcl(ownerId, ownerDisplayName)
}

/// Upload a String object to the cloud
/// <ul>
/// <li>bucketName: Bucket name</li>
/// <li>keyName: Object key name</li>
/// <li>content: String content of the object</li>
/// <li>customHeaders: Custom header name value pairs</li>
/// <li>sse: Server side encryption flag </li>
/// <li>acl: Canned ACL value. Possible values: AuthenticatedRead, AwsExecRead, BucketOwnerFullControl, BucketOwnerRead, LogDeliveryWrite, Private, PublicRead, PublicReadWrite</li>
/// </ul>
/// Return json representation of S3 PutObjectResult
Method PutObjectFromString(bucketName As %String, keyName As %String, content As %String, customHeaders As %ArrayOfDataTypes = "", sse As %Boolean = 1, acl As %String = "") As %String
{
	Set headers = ##class(%Net.Remote.Object).%ClassMethod(..gateway, "com.intersystems.cloud.utils.IRISUtil", "convertIArrayToJMap", customHeaders)
	Quit ..jclient.putObjectFromString(bucketName, keyName, content, headers, sse, acl)
}

/// Upload a File object to the cloud
/// <ul>
/// <li>bucketName: Bucket name</li>
/// <li>keyName: Object key name</li>
/// <li>filePath: File name with path</li>
/// <li>customHeaders: Custom header name value pairs</li>
/// <li>sse: Server side encryption flag </li>
/// <li>acl: Canned ACL value. Possible values: AuthenticatedRead, AwsExecRead, BucketOwnerFullControl, BucketOwnerRead, LogDeliveryWrite, Private, PublicRead, PublicReadWrite</li>
/// </ul>
/// Return json representation of S3 PutObjectResult
Method PutObjectFromFile(bucketName As %String, keyName As %String, filePath As %String, customHeaders As %ArrayOfDataTypes = "", sse As %Boolean = 1, acl As %String = "") As %String
{
	Set headers = ##class(%Net.Remote.Object).%ClassMethod(..gateway, "com.intersystems.cloud.utils.IRISUtil", "convertIArrayToJMap", customHeaders)
	Quit ..jclient.putObjectFromFile(bucketName, keyName, filePath, headers, sse, acl)
}

/// Upload IRIS binary or character stream object to the cloud
/// <ul>
/// <li>bucketName: Bucket name</li>
/// <li>keyName: Object key name</li>
/// <li>stream: IRIS stream object to be uploaded. 
/// A character stream will be converted to a binary stream with UTF-8 encoding.</li>
/// <li>customHeaders: Custom header name value pairs</li>
/// <li>sse: Server side encryption flag </li>
/// <li>acl: Canned ACL value. Possible values: AuthenticatedRead, AwsExecRead, BucketOwnerFullControl, BucketOwnerRead, LogDeliveryWrite, Private, PublicRead, PublicReadWrite</li>
/// </ul>
/// Return json representation of S3 PutObjectResult
Method PutObjectFromStream(bucketName As %String, keyName As %String, stream As %Stream.Object, customHeaders As %ArrayOfDataTypes = "", sse As %Boolean = 1, acl As %String = "") As %String
{
	Set bs = $S(stream.IsCharacter():..ToUTF8(stream), 1:stream)
	Set headers = ##class(%Net.Remote.Object).%ClassMethod(..gateway, "com.intersystems.cloud.utils.IRISUtil", "convertIArrayToJMap", customHeaders)
	Set bytes = ##class(%Net.Remote.Object).%ClassMethod(..gateway, "com.intersystems.cloud.utils.IRISUtil", "convertIStreamToJBytes", bs)
	Quit ..jclient.putObjectFromBytes(bucketName, keyName, bytes, headers, sse, acl)
}

/// Get bucket access control list
/// <ul>
/// <li>bucketName: Bucket name</li>
/// </ul>
/// Return ACL ACL Java object
Method GetBucketAcl(bucketName As %String) As %Net.Remote.Object
{
	Quit ..jclient.getBucketAcl(bucketName)
}

/// Get object access control list
/// <ul>
/// <li>bucketName: Bucket name</li>
/// <li>keyName: Object key name</li>
/// </ul>
/// Return an ACL Java object
Method GetObjectAcl(bucketName As %String, keyName As %String) As %Net.Remote.Object
{
	Quit ..jclient.getObjectAcl(bucketName, keyName)
}

/// Set bucket access control list
/// <ul>
/// <li>bucketName: Bucket name</li>
/// <li>acl: acl Java object</li>
/// </ul>
Method SetBucketAcl(bucketName As %String, acl As %Net.Remote.Object) As %Net.Remote.Object
{
	Do ..jclient.setBucketAcl(bucketName, acl)
}

/// Set object access control list
/// <ul>
/// <li>bucketName: Bucket name</li>
/// <li>keyName: Object key name</li>
/// <li>acl: ACL Java object</li>
/// </ul>
Method SetObjectAcl(bucketName As %String, keyName As %String, acl As %Net.Remote.Object) As %Net.Remote.Object
{
	Do ..jclient.setObjectAcl(bucketName, keyName, acl)
}

/// Possible permission values: FullControl, Read, ReadAcp, Write, WriteAcp
Method GrantCanonicalPermission(acl As %Net.Remote.Object, id As %String, permission As %String)
{
	Do ..jclient.grantCanonicalPermission(acl, id, permission)
}

/// Possible permission values: FullControl, Read, ReadAcp, Write, WriteAcp
Method GrantEmailPermission(acl As %Net.Remote.Object, email As %String, permission As %String)
{
	Do ..jclient.grantEmailPermission(acl, email, permission)
}

/// Get object metadata
/// <ul>
/// <li>bucketName: Bucket name</li>
/// <li>keyName: Object key name</li>
/// </ul>
/// Return json representation of ObjectMetadata
Method GetObjectMetadata(bucketName As %String, keyName As %String) As %String
{
	quit ..jclient.getObjectMetadata(bucketName, keyName)
}

/// Create a bucket with default canned ACL that the bucket owner is granted full control
/// <ul>
/// <li>bucketName: Bucket name</li>
/// <li>region: Region name</li>
/// </ul>
Method CreateBucketWithAcl(bucketName As %String, region As %String = "")
{
	Do ..jclient.createBucketWithAcl(bucketName, region)
}

}
