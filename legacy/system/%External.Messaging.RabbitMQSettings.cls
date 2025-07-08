/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Settings to create RabbitMQ client
Class %External.Messaging.RabbitMQSettings Extends %External.Messaging.Settings
{

/// RabbitMQ server host name.
Property host As %String [ InitialExpression = "localhost" ];

/// RabbitMQ server port number.
Property port As %Integer [ InitialExpression = 5672 ];

/// RabbitMQ server virtual host name.
Property virtualHost As %String [ InitialExpression = "/" ];

/// User name used to connect to RabbitMQ server.
Property username As %String [ InitialExpression = "guest" ];

/// Password used to connect to RabbitMQ server.
Property password As %String(MAXLEN = 200) [ InitialExpression = "guest" ];

/// Flag to enable SSL
Property enableSSL As %Boolean [ InitialExpression = 0 ];

/// TLS version
Property tlsVersion As %String [ InitialExpression = "TLSv1.2" ];

/// Private key password
Property keyPassword As %String(MAXLEN = 200);

/// Client key file name
Property clientKeyFile As %String(MAXLEN = 200);

/// Key store password
Property keyStorePassword As %String(MAXLEN = 200);

/// Key store file name
Property keyStoreFile As %String(MAXLEN = 200);

/// Flag to enable hostname verification
Property enableHostnameVerification As %Boolean [ InitialExpression = 0 ];

}
