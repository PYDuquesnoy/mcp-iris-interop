/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Amazon S3 SQS message body and attributes.
Class %External.Messaging.SQSMessage Extends %External.Messaging.Message
{

/// SQS queue anme.
Property queue As %String(MAXLEN = 1000) [ Required ];

/// SQS message body.
Property body As %String(MAXLEN = "") [ Required ];

/// SQS message group ID.
Property groupID As %String(MAXLEN = 1000);

/// SQS message duplication ID.
Property deduplicationID As %String(MAXLEN = 1000);

/// SQS message receipt handle.
Property receiptHandle As %String(MAXLEN = 1000);

/// SQS Message ID.
Property messageID As %String(MAXLEN = 1000);

/// SQS message attributes.
Property messageAttributes As list Of SQSMessageAttribute;

}
