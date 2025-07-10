/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.RabbitMQ.Common Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// RabitMQ server host name
Property MQHost As %String(MAXLEN = 100) [ InitialExpression = "localhost" ];

/// RabbitMQ port number
Property MQPort As %Integer [ InitialExpression = 5672 ];

/// RabbitMQ virtual host name
Property MQVirtualHost As %String(MAXLEN = 100) [ InitialExpression = "/" ];

/// This is the ID name of the set of credentials values (Username, Password) to be used to access the RabbitMQ server.
Property Credentials As %String(MAXLEN = 200);

/// Flag to enable SSL
Property EnableSSL As %Boolean [ InitialExpression = 0 ];

/// TSL version number
Property TLSVersion As %String [ InitialExpression = "TLSv1.2" ];

/// Credentails containing private key password
Property PrivateKeyCredentials As %String(MAXLEN = 200);

/// Client key file name
Property ClientKeyFile As %String(MAXLEN = 200);

/// Credentials containing key store password
Property KeyStoreCredentials As %String(MAXLEN = 200);

/// Key store file name
Property KeyStoreFile As %String(MAXLEN = 200);

/// Flag to enable hostname verification
Property EnableHostnameVerification As %Boolean [ InitialExpression = 0 ];

/// Failover addresses in the form of "host[:port]..."
Property FailoverAddresses As %String(MAXLEN = 300);

Parameter SETTINGS = "MQHost:RabbitMQ Settings,MQPort:RabbitMQ Settings,MQVirtualHost:RabbitMQ Settings,Credentials:RabbitMQ Settings:credentialsSelector,EnableSSL:RabbitMQ Settings,TLSVersion:RabbitMQ Settings,PrivateKeyCredentials:RabbitMQ Settings:credentialsSelector,ClientKeyFile:RabbitMQ Settings:fileSelector,KeyStoreCredentials:RabbitMQ Settings:credentialsSelector,KeyStoreFile:RabbitMQ Settings:fileSelector,EnableHostnameVerification:RabbitMQ Settings,FailoverAddresses:RabbitMQ Settings";

}
