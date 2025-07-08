/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// <p>
/// External Language Servers provide access to external language platforms from Object Script. This class is the public Object Script 
/// interface for managing External Language Servers and for acquiring connections, referred to as gateways or gateway connections, to those 
/// servers. The <method>getGateway</method> will return a gateway connection to the requested server. There are also language specific 
/// methods for DotNet, Java, and Python that return a gateway connection to the default External Language Server for the requested language. 
/// </p>
Class %SYSTEM.external Extends (%SYSTEM.Help, %External.Server, %External.GeneralImpl) [ Language = objectscript ]
{

}
