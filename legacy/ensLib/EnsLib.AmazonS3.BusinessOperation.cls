/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// EnsLib.AmazonS3.BusinessOperation accepts:
/// EnsLib.CloudStorage.UploadRequest - upload a new object to Amazon S3
/// EnsLib.CloudStorage.DeleteRequest - delete an existing object from Amazon S3
Class EnsLib.AmazonS3.BusinessOperation Extends EnsLib.CloudStorage.BusinessOperation
{

Parameter ADAPTER = "EnsLib.AmazonS3.OutboundAdapter";

Property Adapter As EnsLib.AmazonS3.OutboundAdapter;

}
