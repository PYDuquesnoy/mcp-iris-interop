/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// EnsLib.AmazonS3.OutboundAdapter provides the capability of uploading objects to and deleting objects from Amazon S3.
Class EnsLib.AmazonS3.OutboundAdapter Extends EnsLib.CloudStorage.OutboundAdapter
{

/// Storage provider - 0 - Amazon S3
Property StorageProvider As %Integer [ InitialExpression = 0, Internal, ReadOnly ];

/// Storage region. </br>
/// us-east-1, us-east-2, us-west-1, us-west-2, etc. </br>
/// For details, please refer to https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html </br>
Property StorageRegion As %String(MAXLEN = 100);

/// Credentials file. Place the credentials under [default] in the file.
Property ProviderCredentialsFile As %String(MAXLEN = 1000);

Parameter SETTINGS = "-StorageProvider,PresignedUrl:Cloud Storage";

}
