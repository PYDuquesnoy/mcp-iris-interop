/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class Ens.InboundAdapter Extends Ens.Adapter [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// The minimum interval between invocations of the adapter by the InterSystems IRIS framework. For adapters that poll for
/// external events, this is the polling interval. However, most polling adapters will process all inputs immediately
/// if several are detected at one time. This is also the interval at which each Business Service will check for shutdown requests.
Property CallInterval As %Numeric(MINVAL = 0.1) [ InitialExpression = 5 ];

Parameter SETTINGS = "CallInterval:Basic";

Property BusinessHost As Ens.BusinessService;

Parameter SERVICEINPUTCLASS As STRING = "%RegisteredObject";

Parameter SERVICEOUTPUTCLASS As STRING = "%RegisteredObject";

/// default InboundAdapter behavior: always call ProcessInput on CallInterval
Method OnTask() As %Status
{
	Set tSC = ..BusinessHost.ProcessInput($$$NULLOREF)
	Set ..BusinessHost.%WaitForNextCallInterval=1
	Quit tSC
}

}
