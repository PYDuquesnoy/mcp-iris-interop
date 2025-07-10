/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An abstract business operation that can be used as a base for business operations
/// requiring the .NET Gateway.
/// This operation doesn't actually handle I/O and there isn't an adapter.
Class EnsLib.DotNetGateway.AbstractOperation Extends Ens.BusinessOperation [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// IP address or name of the machine where the .NET Gateway Server executable is located.
Property DotNetServer As %String [ InitialExpression = "127.0.0.1" ];

/// TCP port number for communication between the .NET Gateway Server and the proxy classes in InterSystems IRIS.
Property Port As %Integer [ InitialExpression = "55000" ];

/// Comma-separated list of assembly files containing classes you are using via the .NET Gateway. 
/// Each path element should correspond to individual assembly DLL entry, fully qualified.
/// Example: "C:\InterSystems\IRIS\Dev\dotnet\bin\DotNetGatewaySamples.dll". 
Property AdditionalPaths As %String(MAXLEN = 32000);

/// Timeout in seconds to connect to the .NET Gateway Server from InterSystems IRIS.
Property ConnectTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 5 ];

/// Configurable settings for this operation.
Parameter SETTINGS = "DotNetServer:Basic,Port:Basic,AdditionalPaths,ConnectTimeout,-ArchiveIO";

/// The .NET Gateway connection object.  It should always be accessed via the gateway connection object returned
/// by method <method>GetConnection</method>.
Property DotNetGateway As %Net.Remote.Gateway [ Private ];

Property TCPDevice As %String [ Internal, Private ];

/// This user callback method is called just after %OnNew() to initialize the connection among other things.
/// If you need to override this code, invoke the method in the superclass or add to the original code.
Method OnInit() As %Status
{
	// If a TCP port isn't configured, the operation won't work!
	If '..Port Quit $$$ERROR($$$EnsErrGeneral, "A valid Port must be configured (current port is '"_..Port_"'")
	
	Set ..TCPDevice = "|TCP|"_(+..Port)
	
	// This forces the connection to start at production start.
	Set tSC = ..GetConnection(.tGateway, ..ConnectTimeout+10)
	If 'tSC {
		Set tSC = $$$ERROR($$$EnsErrGeneral, "DotNetGateway operation failed to connect to the Gateway Server")
	}
	
	// This host terminates if a connection can't be obtained.
	Quit tSC
}

/// This user callback method is called just before %OnClose() to disconnect from the .NET gateway server.
/// If you need to override this code, invoke the method in the superclass or add to the original code.
Method OnTearDown() As %Status
{
	Do ..CloseConnection()
	Quit $$$OK
}

/// Ensure we have a valid .NET Gateway connection.  If not, try to recover.
/// This method returns a private gateway connection object to be used with the proxy classes. <br>
/// Example: <example language="cos">
///    Set tSC = ..GetConnection(.tGateway) 
///    If $$$ISOK(tSC) { 
///       // Start using the .NET Gateway connection object tGateway 
///       ... 
///    } 
/// </example>
Method GetConnection(ByRef pGateway As %Net.Remote.Gateway, pTimeout As %Numeric) As %Status
{
	Set tSC = $$$OK
	If ""=$G(pTimeout) Set pTimeout = ..ConnectTimeout
	
	Try {
		If $IsObject(..DotNetGateway) {
			// If we already have a valid .NET Gateway connection, use it
			Set pGateway = ..DotNetGateway
			$$$sysTRACE($classname()_", property DotNetGateway already set = '"_pGateway_"'")
		}
		Else {
			// Get a new connection
			Set $ZE = ""
			$$$LOGINFO("Initiating connection...")
			Set tSC = ..ConnectDNG(.pGateway, pTimeout)
		}
	}
	Catch {
		Set tSC = $$$EnsSystemError
	}
	
	Try {
		Use "|TCP|"_(+..Port):(::"-D")
		If '$ZU(189) {
			Set $ZE = "<DSCON>"
			$$$LOGINFO("Trying to rebind TCP socket...")
			Set tSC = ..ConnectDNG(.pGateway, pTimeout)
		}
	}
	Catch {
		Set tSC = ..ConnectDNG(.pGateway, pTimeout)
	}
	
	Try {
		If 'tSC {
			// Log the error; final reattempt to recover
			$$$LOGSTATUS(tSC)
			Set $ZE = ""
			$$$LOGINFO("Trying to recover from lost connection...")
			Set tSC = ..ConnectDNG(.pGateway, pTimeout)
		}
		If $IsObject(pGateway) {
			If ..DotNetGateway="" $$$LOGINFO("Successfully reconnected to the .NET Gateway Server")
			$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,"OK")
			Set ..DotNetGateway = pGateway
		}
		Else {
			$$$LOGINFO("Couldn't connect to the .NET Gateway Server")
			$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,"Error")
			Set ..DotNetGateway = ""
		}
	}
	Catch {
	}
	
	Quit tSC
}

/// This method is invoked from <method>GetConnection</method> and will either start a new connection or 
/// attempt to restore a broken connection.
/// It can be used in case there is a failure during communication with the .NET Gateway Server.
/// A status is returned indicating success or failure of the [re]connection.
Method ConnectDNG(ByRef pGateway As %Net.Remote.Gateway, pTimeout As %Numeric) As %Status
{
	Set tSC = $$$OK
	
	Try {
		If ""=$G(pTimeout) Set pTimeout = ..ConnectTimeout
		If ($ZE="") || ($ZE["<NOTOPEN>") || ($ZE["<WRITE>") || ($ZE["<READ>") || ($ZE["<DISCONNECT>") || ($ZE["<DSCON>") {
			If $ZE'="" {
				Set pTimeout = pTimeout+40 // Allow some extra time for recovery
			}
			Set pGateway = $$$NULLOREF
			Set ..DotNetGateway = $$$NULLOREF
			Set tEndpoint = ..DotNetServer_";"_..Port_";"_$namespace
			$$$sysTRACE($classname()_" connecting to .NET Gateway Server on "_tEndpoint)
			Close "|TCP|"_(+..Port) Hang 0.2 // Reset TCP connection
			Set tSC = ##class(EnsLib.DotNetGateway.Service).ConnectGateway(tEndpoint, .pGateway, pTimeout, ..AdditionalPaths)
			If ('tSC) || ('$IsObject($G(pGateway))) {
				Set:tSC tSC = $$$ERROR($$$EnsErrGeneral, "Failed to get a valid gateway connection")
				$$$LOGSTATUS(tSC)
			}
			If tSC {
				Use "|TCP|"_(+..Port):(::"-D")
				If ..DotNetGateway="" $$$LOGINFO("Successfully connected to the .NET Gateway Server")
				Set ..DotNetGateway = pGateway
				Set $ZE = ""
			}
		}
	}
	Catch {
	}
	
	If $ZE'="" {
		Set tSC = $$$EnsSystemError
	}
	
	Quit tSC
}

/// Close the connection from the business operation to the Gateway Server.
Method CloseConnection() As %Status
{
	Set tSC = $$$OK
	
	Try {
		// Check to see if we have a valid gateway
		If $IsObject(..DotNetGateway) {
			$$$sysTRACE("Disconnecting from .NET Gateway server")
			Do ..DotNetGateway.%Disconnect()
			Set ..DotNetGateway = $$$NULLOREF
		}
	}
	Catch {
		Set tSC = $$$EnsSystemError
	}
	
	Quit tSC
}

}
