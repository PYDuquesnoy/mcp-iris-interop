/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Settings to create RabbitMQ queue.
Class %External.Messaging.RabbitMQQueueSettings Extends %External.Messaging.Settings
{

/// True if queue is durable(the queue will surrvive a server restart).
Property durable As %Boolean [ InitialExpression = 0 ];

/// True if queue is exclusive(restricted to this connection).
Property exclusive As %Boolean [ InitialExpression = 0 ];

/// True if queue is auto deleted(server will delete it when no longer in use).
Property autoDelete As %Boolean [ InitialExpression = 0 ];

}
