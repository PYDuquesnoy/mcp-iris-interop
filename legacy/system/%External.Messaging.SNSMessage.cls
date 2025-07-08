/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Amazon S3 SNS message.
Class %External.Messaging.SNSMessage Extends %External.Messaging.Message
{

/// Message topic ARN.
Property topicARN As %String(MAXLEN = 1000) [ Required ];

/// Message body.
Property message As %String(MAXLEN = "") [ Required ];

/// Optional message subject.
Property subject As %String(MAXLEN = 1000);

}
