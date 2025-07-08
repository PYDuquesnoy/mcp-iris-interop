/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %External.Messaging.JMSReceiveSettings Extends %External.Messaging.Settings
{

/// Timeout in milisecond to receive messages
Property receiveTimeout As %Integer [ InitialExpression = 100 ];

/// Optional subscriber name
Property subscriber As %String;

}
