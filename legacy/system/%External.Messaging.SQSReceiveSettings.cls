/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %External.Messaging.SQSReceiveSettings Extends %External.Messaging.Settings
{

/// Max number of messages to retrieve
Property maxNumberOfMessages As %Integer [ InitialExpression = 10 ];

/// Poll timeout in second
Property waitTimeSeconds As %Integer [ InitialExpression = 1 ];

/// Visibility timeout in second
Property visibilityTimeout As %Integer [ InitialExpression = 1 ];

}
