/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// Monitor enabling class.  Users inherit from this class to register
/// as a Monitor class.
Class %Monitor.Adaptor Extends %RegisteredObject [ Abstract, Not ProcedureBlock, System = 3 ]
{

/// User name for application.  Default = Package name
Parameter APPLICATION;

/// User name for this group of metrics.  Default = classname
Parameter GROUPNAME;

/// Comma separated list of properties to act as primary key for instances.  Default = ""
Parameter INDEX;

/// Comma separated list of Resources required to view the CSP page.  Default = ""
Parameter SECURITYRESOURCE;

/// The Projection creates metadata and the sample persistent class
Projection RegisterMonitor As %Projection.Monitor(MONENABLED = 1);

/// USER MAY IMPLEMENT THIS METHOD<br>
/// This method is called once when the control object is created at the beginning of sampling.
/// The user may initialize the control class.
Method Startup() As %Status
{
	Quit $$$OK
}

/// USER MAY IMPLEMENT THIS METHOD<br>
/// This method is called once when the control object is closed at the end of sampling.
/// The user may cleanup the control class.
Method Shutdown() As %Status
{
	Quit $$$OK
}

/// USER MAY IMPLEMENT THIS METHOD<br>
/// This method is called to initialize the control for
/// the first sample of a set of sample instances.<br>
/// A return code of $$$OK indicates there is a new sample instance.<br>
/// A return code of 0 indicates there is no sample instance.
Method Initialize() As %Status
{
	Quit $$$OK
}

/// USER MUST IMPLEMENT THIS METHOD<br>
/// This method is called to initialize and populate properties
/// for successive sample instances.<br>
/// A return code of $$$OK indicates there is a new sample instance.<br>
/// A return code of 0 indicates there is no sample instance.
/// <br><br> NOTE: If an INDEX is specified, i.e. we expect to collect multiple samples for each sampling
/// period, then the System Monitor will loop calling GetSample() until "0" is returned. Users code MUST 
/// return "0" when all indexed sample have been collected for a period, in order to terminate the loop. 
Method GetSample() As %Status [ Abstract ]
{
}

/// Initialize the collection.
Method %OnNew() As %Status [ Private ]
{
	If ..Startup() '= $$$OK Q 0
	Quit $$$OK
}

}
