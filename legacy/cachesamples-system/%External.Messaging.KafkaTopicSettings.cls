/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Settings to create Kafka topic
Class %External.Messaging.KafkaTopicSettings Extends %External.Messaging.Settings
{

/// Number of partitions
Property numberOfPartitions As %Integer [ InitialExpression = 1 ];

/// Replication factor
Property replicationFactor As %TinyInt [ InitialExpression = 1 ];

}
