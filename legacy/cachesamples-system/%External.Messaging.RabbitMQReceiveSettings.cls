/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %External.Messaging.RabbitMQReceiveSettings Extends %External.Messaging.Settings
{

/// true if the server should consider messages acknowledged once delivered; 
/// false if the server should expect explicit acknowledgements.
Property autoAck As %Boolean [ InitialExpression = 0 ];

/// true to acknowledge all messages up to and including the supplied delivery tag; 
/// false to acknowledge just the supplied delivery tag.
Property ackMultiple As %Boolean [ InitialExpression = 0 ];

}
