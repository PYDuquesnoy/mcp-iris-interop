/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %External.Messaging.KafkaReceiveSettings Extends %External.Messaging.Settings
{

/// Poll timeout in milisecond
Property pollTimeout As %Integer [ InitialExpression = 100 ];

}
