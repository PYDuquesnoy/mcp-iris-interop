/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Abstract base class to allow all portal pages to share a consistent 
/// interface for indicating whether auto-refresh behaviour is permitted.
/// This class is intended for use as a secondary super-class.
Class %ZEN.Portal.abstractRefreshable [ Abstract, Deprecated, System = 4 ]
{

/// True if pages in the management portal are permitted to use auto-refresh behaviour.
Property enableAutoRefresh As %ZEN.Datatype.boolean [ InitialExpression = {##class(%CSP.Portal.Utils).%IsAutoRefreshEnabled()} ];

}
