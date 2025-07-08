/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Settings to create Amazon S3 SNS client.
Class %External.Messaging.SNSSettings Extends %External.Messaging.Settings
{

/// Amazon S3 credentials file. It takes precedence over access key and secret key.
Property credentialsFile As %String(MAXLEN = 1000);

/// Amazon S3 access key.
Property accessKey As %String(MAXLEN = 1000);

/// Amazon S3 secret key.
Property secretKey As %String(MAXLEN = 1000);

/// Amazon S3 session token.
Property sessionToken As %String(MAXLEN = 1000);

/// Amazon S3 storage region.
Property region As %String(MAXLEN = 100);

}
