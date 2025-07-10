/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class EnsLib.JMSPEX.Common Extends %RegisteredObject [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// JMS server URL
Property URL As %String(MAXLEN = 100);

/// JMS initial context factory name
Property InitialContextFactoryName As %String(MAXLEN = 100);

/// JMS connection factory name
Property ConnectionFactoryName As %String(MAXLEN = 100);

/// JMS client id
Property ClientID As %String(MAXLEN = 100);

/// This is the ID name of the set of credentials values (Username, Password) to be used to access the Kafka server.
Property Credentials As %String(MAXLEN = 200);

Parameter SETTINGS = "URL:JMS Settings,InitialContextFactoryName:JMS Settings,ConnectionFactoryName:JMS Settings,ClientID:JMS Settings,Credentials:JMS Settings:credentialsSelector";

}
