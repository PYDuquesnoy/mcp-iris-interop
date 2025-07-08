/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Settings to create SQS queue.
/// Refer link for details: https://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/com/amazonaws/services/sqs/model/CreateQueueRequest.html
Class %External.Messaging.SQSQueueSettings Extends %External.Messaging.Settings
{

/// The length of time, in seconds, for which the delivery of all messages in the queue is delayed.
Property DelaySeconds As %Integer;

/// Maximum message size in bytes.
Property MaximumMessageSize As %Integer;

/// The length of time, in seconds, for which Amazon SQS retains a message.
Property MessageRetentionPeriod As %Integer;

/// The queue's policy. A valid Amazon Web Services policy.
Property Policy As %String(MAXLEN = 1000);

/// The length of time, in seconds, for which a ReceiveMessage action waits for a message to arrive.
Property ReceiveMessageWaitTimeSeconds As %Integer;

/// The string that includes the parameters for the dead-letter queue functionality of the source queue as a JSON object.
Property RedrivePolicy As %String(MAXLEN = 1000);

/// The visibility timeout for the queue, in seconds.
Property VisibilityTimeout As %Integer;

/// Designates a queue as FIFO.
Property FifoQueue As %Boolean;

/// Enables content-based deduplication.
Property ContentBasedDeduplication As %Boolean;

}
