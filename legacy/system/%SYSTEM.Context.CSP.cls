/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Class %SYSTEM.Context.CSP Extends %Library.SystemBase
{

/// Timeout (in seconds) for SQL Gateway connections. If a connection
/// has not been used for longer than this time, it will be terminated.
/// The timeout is applied at the end of each CSP request.
Property SQLGatewayTimeout As %Integer;

Property AuthTokenInfo As %DynamicObject;

/// Array of devices that should not be closed after each request
Property persistentDevices As %String [ MultiDimensional ];

Method %OnNew() As %Status [ Private ]
{
	Set sc = $$$OK
	Try {
		Set i%SQLGatewayTimeout = $System.CSP.GetConfig("SQLGatewayTimeout")
	} Catch ex {
		Set sc = ex.AsStatus()
	}
	Return sc
}

/// Add the specified device to the list of persistent devices. 
/// Devices in this list will not be closed after each request. 
Method AddPersistentDevice(device As %String)
{
	if device'="" {
		set i%persistentDevices(device)=""
	}
}

/// Remove the specified device from the set of persistent devices.
/// This will allow the device to be closed normally after the current request.
Method RemovePersistentDevice(device As %String)
{
	if device'="" {
		kill i%persistentDevices(device)
	}
}

/// Check if the specified device is in the list of persistent devices. 
Method IsPersistent(device As %String) As %Boolean
{
	return $select(device="":0, 1:$data(i%persistentDevices(device))>0)
}

/// This method will remove any devices in the persistent list that are no longer open.
Method PurgePersistentDevices()
{
	// find the set of currently open devices
	#;SML3019 ; Handle file name with ",".
	set devices = $LFS($piece($View(-1,$job),"^",3),",",2)
	
	// remove any devices marked as persistent that no longer exist
	set dev = ""
	for {
		set dev = $order(i%persistentDevices(dev))
		if dev="" quit
		
		#;SML3019 ; Handle file name with ",".
		if $LISTFIND(devices,dev) {
			kill i%persistentDevices(dev)
		}
	}
}

/// Remove all devices marked as persistent. The devices are not closed immediately; 
/// they will be closed at the end of the current request
Method RemoveAllPersistentDevices()
{
	kill i%persistentDevices
}

/// Given a device, this method returns the next persistent device in this list, in collation order. 
/// This can be used to iterate over the list of devices. 
/// <p><var>device</var> indicates the current location of the iterator. Specify "" to retrieve the first device</p>
/// <p><var>direction</var> specify 1 to retrieve the next device in collation order, or -1 to retrieve the previous device. The default is 1.</p>
/// <p>returns the next device, or "" if there are no more devices.</p>
Method NextPersistentDevice(device As %String, direction As %Integer = 1)
{
	quit $order(i%persistentDevices(device),direction)
}

}
