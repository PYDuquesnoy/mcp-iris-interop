/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Settings to create Kafka clients (Consumer, Producer and AdminClient)
Class %External.Messaging.KafkaSettings Extends %External.Messaging.Settings
{

/// User name used to create Kafka clients to the Kafka server.
Property username As %String(MAXLEN = 100);

/// Password used to create Kafka clients to the Kafka server.
Property password As %String(MAXLEN = 1000);

/// A comma separated list of host/port pairs to use for establishing the initial connection to the Kafka cluster.
Property servers As %String(MAXLEN = 1000) [ InitialExpression = "localhost:9092" ];

/// Client Id for Kafka producer.
Property clientId As %String(MAXLEN = 1000) [ InitialExpression = "KafkaProducer" ];

/// Group id for Kafka consumer.
Property groupId As %String(MAXLEN = 1000);

/// Security protocol between Kafka client and broker
/// Supported protocol: SASL_PLAINTEXT, SASL_SSL
Property securityprotocol As %String(MAXLEN = 50) [ InitialExpression = "SASL_PLAINTEXT" ];

/// SASL mechanism
/// Posssible values: GSSAPI,PLAIN,SCRAM-SHA-256,SCRAM-SHA-512,OAUTHBEARER
/// Supported mechanism: PLAIN,SCRAM-SHA-256,SCRAM-SHA-512
Property saslmechanism As %String(MAXLEN = 50) [ InitialExpression = "PLAIN" ];

/// Trust store location
Property truststorelocation As %String(MAXLEN = 1000);

/// Trust store password
Property truststorepassword As %String(MAXLEN = 1000);

/// Key store location
Property keystorelocation As %String(MAXLEN = 1000);

/// Key store password
Property keystorepassword As %String(MAXLEN = 1000);

/// Key password
Property keypassword As %String(MAXLEN = 1000);

}
