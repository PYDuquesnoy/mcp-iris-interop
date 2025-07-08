/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %External.Messaging.JMSSettings Extends %External.Messaging.Settings
{

/// JMS url
Property url As %String;

/// Initial context factory name
Property initialContextFactoryName As %String [ InitialExpression = "weblogic.jndi.WLInitialContextFactory" ];

/// JMS connection factory name
Property connectionFactoryName As %String;

/// Client ID
Property clientID As %String;

/// Username
Property username As %String;

/// Password
Property password As %String;

}
