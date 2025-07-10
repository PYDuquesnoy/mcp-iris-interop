/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// An abstract business operation that can be used as a base class for Business Operation classes that invoke Java methods via the Java Gateway.
/// Implementing message handler methods that invoke functions on the Java Gateway is the responsibility of subclasses.
/// No adapter is needed but standard Java Gateway proxy objects should be generated and invoked.
/// The methods of this class simply manage the connection to the Java Gateway in a fault tolerant way. 
Class EnsLib.JavaGateway.AbstractOperation Extends Ens.BusinessOperation [ Abstract, ClassType = "", ProcedureBlock, System = 4 ]
{

/// IP address or name of the machine where the Java Gateway Server is located.
Property Address As %String [ InitialExpression = "127.0.0.1" ];

/// TCP port number for communication between the Java Gateway Server and the proxy classes in InterSystems IRIS.
Property Port As %String [ InitialExpression = "55555" ];

/// Optional comma-separated list of additional files containing classes you are using via the Java Gateway 
/// to be added to the ClassPath already specified in the service if any. 
/// Each path element should correspond to individual entry, fully qualified and properly quoted.
/// Please note the delimiter here should be a comma, instead of the platform dependent delimiter used for
/// ClassPath in class <class>EnsLib.JavaGateway.Service</class>. <br>
/// Example: "C:\JavaWork\test1.jar,C:\JavaTemp\test2.jar".
Property AdditionalPaths As %String(MAXLEN = 32000);

/// Timeout in seconds to connect to the Java Gateway Server from InterSystems IRIS.
Property ConnectTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 5 ];

/// Configurable settings for this operation.
Parameter SETTINGS = "Address:Basic,Port:Basic,AdditionalPaths,ConnectTimeout,-ArchiveIO";

/// The Java Gateway connection object.  It should always be accessed via the gateway connection object returned
/// by method <method>GetConnection</method>.
Property JavaGateway As EnsLib.JavaGateway.JavaGateway [ Private ];

Property TCPDevice As %String [ Internal, Private ];

/// This property has been deprecated.
Property Debug As %Boolean [ InitialExpression = 0, Internal ];

/// This property has been deprecated.
Property MaxRetries As %Integer(MAXVAL = 100, MINVAL = 0) [ InitialExpression = 3, Internal ];

/// This property has been deprecated.
Property RetryDelay As %Integer(MAXVAL = 100, MINVAL = 0) [ InitialExpression = 1, Internal ];

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
		Set tSC = $$$ERROR($$$EnsErrGeneral, "Java Gateway operation failed to connect to the Gateway Server")
	}
	
	// This host terminates if a connection can't be obtained.
	Quit tSC
}

/// This user callback method is called just before %OnClose() to disconnect from the .Java Gateway Server.
/// If you need to override this code, invoke the method in the superclass or add to the original code.
Method OnTearDown() As %Status
{
	Do ..CloseConnection()
	Quit $$$OK
}

/// Ensure we have a valid Java Gateway connection.  If not, try to recover.
/// This method returns a private gateway connection object to be used with the proxy classes. <br>
/// Example: <example language="cos">
///    Set tSC = ..GetConnection(.tGateway) 
///    If $$$ISOK(tSC) { 
///       // Start using the Java Gateway connection object tGateway 
///       ... 
///    } 
/// </example>
Method GetConnection(ByRef pGateway As EnsLib.JavaGateway.JavaGateway, pTimeout As %Numeric) As %Status
{
	Set tSC = $$$OK
	Set tIO = $IO Set:tIO="" tIO = 0
	If ""=$G(pTimeout) Set pTimeout = ..ConnectTimeout
	
	Try {
		If $IsObject(..JavaGateway) {
			// If we already have a valid Java Gateway connection, use it
			Set pGateway = ..JavaGateway
			$$$sysTRACE($classname()_", property JavaGateway already set = '"_pGateway_"'")
		}
		Else {
			// Get a new connection
			Set $ZE = ""
			$$$LOGINFO("Initiating connection...")
			Set tSC = ..ConnectJG(.pGateway, pTimeout)
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
			Set tSC = ..ConnectJG(.pGateway, pTimeout)
		}
	}
	Catch {
		Set tSC = ..ConnectJG(.pGateway, pTimeout)
	}
	
	Try {
		If 'tSC {
			// Log the error; final reattempt to recover
			$$$LOGSTATUS(tSC)
			Set $ZE = ""
			$$$LOGINFO("Trying to recover from lost connection...")
			Set tSC = ..ConnectJG(.pGateway, pTimeout)
		}
		If $IsObject(pGateway) {
			If ..JavaGateway="" $$$LOGINFO("Successfully reconnected to the Java Gateway Server")
			$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,"OK")
			Set ..JavaGateway = pGateway
		}
		Else {
			$$$LOGINFO("Couldn't connect to the Java Gateway Server")
			$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,"Error")
			Set ..JavaGateway = ""
		}
	}
	Catch {
	}
	
	Use tIO
	
	Quit tSC
}

/// This method is invoked from <method>GetConnection</method> and will either start a new connection or 
/// attempt to restore a broken connection.
/// It can be used in case there is a failure during communication with the Java Gateway Server.
/// A status is returned indicating success or failure of the [re]connection.
Method ConnectJG(ByRef pGateway As EnsLib.JavaGateway.JavaGateway, pTimeout As %Numeric) As %Status
{
	Set tSC = $$$OK
	Set tIO = $IO Set:tIO="" tIO = 0
	
	Try {
		If ""=$G(pTimeout) Set pTimeout = ..ConnectTimeout
		If ($ZE="") || ($ZE["<NOTOPEN>") || ($ZE["<WRITE>") || ($ZE["<READ>") || ($ZE["<DISCONNECT>") || ($ZE["<DSCON>") {
			If $ZE'="" {
				Set pTimeout = pTimeout+40 // Allow some extra time for recovery
			}
			Set pGateway = $$$NULLOREF
			Set ..JavaGateway = $$$NULLOREF
			Set tEndpoint = ..Address_";"_..Port_";"_$namespace
			$$$sysTRACE($classname()_" connecting to Java Gateway Server on "_tEndpoint)
			Close "|TCP|"_(+..Port) Hang 0.2 // Reset TCP connection
			Set tSC = ##class(EnsLib.JavaGateway.Service).ConnectGateway(tEndpoint, .pGateway, 0, pTimeout, ..AdditionalPaths)
			If ('tSC) || ('$IsObject($G(pGateway))) {
				Set:tSC tSC = $$$ERROR($$$EnsErrGeneral, "Failed to get a valid gateway connection")
				$$$LOGSTATUS(tSC)
			}
			If tSC {
				Use "|TCP|"_(+..Port):(::"-D")
				If ..JavaGateway="" $$$LOGINFO("Successfully connected to the Java Gateway Server")
				Set ..JavaGateway = pGateway
				Set $ZE = ""
			}
		}
	}
	
	Catch {
	}
	
	If $ZE'="" {
		Set tSC = $$$EnsSystemError
	}
	
	Use tIO
	
	Quit tSC
}

/// Close the connection from the business operation to the Gateway Server.
Method CloseConnection() As %Status
{
	Set tSC = $$$OK
	
	Try {
		// Check to see if we have a valid gateway
		If $IsObject(..JavaGateway) {
			$$$sysTRACE("Disconnecting from Java Gateway Server")
			Do ..JavaGateway.%Disconnect()
			Set ..JavaGateway = $$$NULLOREF
		}
	}
	Catch {
		Set tSC = $$$EnsSystemError
	}
	
	Quit tSC
}

}
