/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An abstract business operation that can be used as a base class for Business Operation classes that invoke REST services over HTTP
Class EnsLib.REST.Operation Extends (Ens.BusinessOperation, Ens.Util.JSON) [ Abstract, System = 4 ]
{

Parameter ADAPTER As %String = "EnsLib.HTTP.OutboundAdapter";

}
