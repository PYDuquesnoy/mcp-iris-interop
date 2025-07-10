/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Generic REST Service based BusinessService class. Can use an HTTP InboundAdapter listener, or the standard CSP Service mechanism, or both.
/// In order for the CSP mechanism to work, HTTP Services using this class must be configured with the invoking URL including ?CfgItem= giving the config item name.
/// (Configured Services exposed using the HTTP Inbound Adapter may also be invoked with this URL parameter but because
///  each configured Inbound Adapter listens on its own TCP/IP port this parameter is just a safety check for them.)
Class EnsLib.REST.GenericService Extends EnsLib.HTTP.GenericService [ System = 4 ]
{

}
