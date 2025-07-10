/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A service responsible for starting, monitoring and stopping a Gateway Server in a production.
Class EnsLib.Gateway.Service Extends Ens.BusinessService [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// This adapter does not handle communication with external systems, it's for internal use of this class only.
Parameter ADAPTER = "EnsLib.Gateway.ServiceAdapter";

/// External Language Server Name. Once specified, the settings of the External Language Server
/// supersede the settings given in the production item such as Server, Port and other gateway
/// settings such as ClassPath.
/// Using External Language Server is preferred over Server and Port as the means to control the external
/// gateway and the Server/Port combination will be deprecated.
/// If UsePassphrase is enabled then a pre-defined External Language Server Name is required.
Property %gatewayName As %String;

/// If an External Language Server is specified this setting determines
/// if an attempt will be made to stop the specified named server when this item stops.<br>
/// The default is off. <br> Named External Language Servers can be managed via the SMP and
/// are also stopped when the instance is stopped.<br>
/// If an External Language Server is not specified, when this item stops an attempt
/// will always be made to stop the gateway that was started on the specified local port.
Property %stopNamedGatewayOnTeardown As %Boolean [ InitialExpression = 0 ];

/// IP address or name of the machine where the Gateway Server is located.
Property Server As %String [ InitialExpression = "127.0.0.1" ];

/// TCP port number for communication between the Gateway Server and in InterSystems IRIS.
Property Port As %String [ InitialExpression = "55555" ];

/// Fully qualified name of a file to log all communication between the InterSystems IRIS server and the Gateway.
/// Usually this setting should be left blank, and used only for trouble-shooting.
Property Logfile As %String(MAXLEN = 1023);

/// If the Gateway is to be started requiring a passphrase for connection.
/// An External Language Server Name (<property>%gatewayName</property>) is required.
Property UsePassphrase As %Boolean [ InitialExpression = 0 ];

/// This setting is not used when an External Language Server Name
/// is specified (<property>%gatewayName</property>) <br>
/// Number of seconds between each communication with the Gateway Server to check if it is active.
/// The default is 10 seconds.
/// When enabled, the minimum value is 5 seconds and the maximum value is 3600 seconds (1 hour). <br>
/// A value of 0 disables the monitoring feature; in this case, if the Gateway goes down, the status indicator color in the Production Configuration page will not be automatically updated.<br>
/// See also properties <property>HeartbeatFailureTimeout</property>, <property>HeartbeatFailureAction</property>
/// and <property>HeartbeatFailureRetry</property>, which only apply if monitoring is enabled.
Property HeartbeatInterval As %Integer(MAXVAL = 3600, MINVAL = 0) [ InitialExpression = 10 ];

/// Number of seconds without responding to the heartbeat, to consider that the Gateway Server is in failure state.
/// If this value is smaller than property <property>HeartbeatInterval</property>, it will be considered in
/// failure state every time the Gateway communication check fails.
/// The default is 30 seconds. 
/// The maximum value is 86400 seconds (1 day). <br>
/// See also properties <property>HeartbeatInterval</property>, <property>HeartbeatFailureAction</property>
/// and <property>HeartbeatFailureRetry</property>.
Property HeartbeatFailureTimeout As %Integer(MAXVAL = 86400, MINVAL = 0) [ InitialExpression = 30 ];

/// What action(s) to take if the Gateway Server goes into failure state.
/// Setting it to <b>Restart</b> (default) will cause the Gateway to be restarted.
/// Setting it to <b>Alert</b> will generate an alert entry in the Event Log. <br>
/// Note 1: This is independent of the <b>Alert on Error</b> setting. <br>
/// Note 2: If <property>Address</property> points to a remote system, this feature <b>must not</b>
/// restart the server; only alerts may be generated. <br>
/// See also properties <property>HeartbeatInterval</property>, <property>HeartbeatFailureTimeout</property>
/// and <property>HeartbeatFailureRetry</property>.
Property HeartbeatFailureAction As %String(DISPLAYLIST = ",None,Restart,Alert,Restart and Alert", VALUELIST = ",N,R,A,RA") [ InitialExpression = "R", Required ];

/// In case the Gateway Server goes into failure state, and stays in failure state, how much time
/// to wait before retrying the <property>HeartbeatFailureAction</property>.
/// The default value is 300 seconds (5 minutes).
/// A value of 0 disables this retry, meaning that once there is a failure that can't be immediately recovered,
/// there won't be automatic attempts to recovery. <br>
/// See also properties <property>HeartbeatInterval</property>, <property>HeartbeatFailureTimeout</property>
/// and <property>HeartbeatFailureAction</property>.
Property HeartbeatFailureRetry As %Integer(MAXVAL = 86400, MINVAL = 0) [ InitialExpression = 300 ];

/// Internal property to keep track of the elapsed failure time for the heartbeat feature.
Property HeartbeatFailureStart As %String [ Internal, Private ];

/// Internal property to keep track of the grace time after failure before restoring the heartbeat.
Property HeartbeatGraceStart As %String [ Internal, Private ];

/// Internal property to keep track of the status of Gateway Server.
Property GatewayStatus As %String [ InitialExpression = "OK", Internal, Private ];

/// This service does not actually handle input data.
/// The call interval is used as the heartbeat interval if enabled.
Method OnProcessInput(pInput As %RegisteredObject, pOutput As %RegisteredObject) As %Status
{
	Try {
		$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,..GatewayStatus)
		If ..HeartbeatGraceStart>0 {
			If ($ZH-..HeartbeatGraceStart)<..HeartbeatFailureRetry Quit  // Within grace period
			// Grace period is over
			Set ..HeartbeatGraceStart = 0
			Set ..HeartbeatFailureStart = 0
		}
		If ..HeartbeatInterval>0 {
			// Heartbeat is enabled
			Set tSC = ..PingThisGateway()
			If $$$ISOK(tSC) {
				// Succeeded; update status and reset failure tracking base timestamp
				If ..GatewayStatus'="OK" {
					$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,"OK")
					Set ..GatewayStatus = "OK"
				}
				Set ..HeartbeatFailureStart = 0
			} Else {
				// Failed; update status, log warning, check failure timeout
				If ..GatewayStatus'="Error" {
					$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,"Error")
					Set ..GatewayStatus = "Error"
				}
				$$$LOGWARNING("Gateway Server did not respond to PING request: "_$$$StatusDisplayString(tSC))
				Set t = $ZH
				If '..HeartbeatFailureStart {
					Set ..HeartbeatFailureStart = t
				}
				If (t-..HeartbeatFailureStart)>..HeartbeatFailureTimeout {
					// Handle the Gateway failure
					$$$LOGERROR("Gateway Server failure timeout on "_..Server_$S(..Server[":":"|",1:":")_..Port)
					If ..HeartbeatFailureAction["A" {
						Do ..SendAlert(##class(Ens.AlertRequest).%New($LB(..%ConfigName,"Gateway Server failure timeout on "_..Server_$S(..Server[":":"|",1:":")_..Port)))
					}
					If ..HeartbeatFailureAction["R" {
						$$$LOGINFO("Restarting the Gateway Server")
						// Stop the gateway just in case, collecting errors
						Set tSC1 = ..StopThisGateway()
						// Restart the gateway
						Set tSC = ..StartThisGateway()
						If $$$ISERR(tSC) {
							Set tSC=$$$ADDSC(tSC,tSC1)
							$$$LOGERROR("Failed to restart the Gateway Server: "_$$$StatusDisplayString(tSC))
						} Else {
							If $$$ISERR(tSC1) {
								$$$LOGWARNING("Error stopping Gateway Server before restart: "_$$$StatusDisplayString(tSC1))
							}
							$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,"OK")
							$$$LOGINFO("Gateway Server restarted successfully")
							Set ..GatewayStatus = "OK"
							Set ..HeartbeatGraceStart = 0
							Set ..HeartbeatFailureStart = 0
						}
					}
					If (..HeartbeatFailureStart>0) && (..HeartbeatFailureRetry>..HeartbeatInterval) {
						// Will observe grace time ..HeartbeatFailureRetry
						Set ..HeartbeatGraceStart = $ZH
					}
				}
			}
		}
		Set ..%WaitForNextCallInterval=1 ; Adapter will set this anyway but this prevents BS from doing extraneous trace logging
	}
	Catch {
		Set tSC = $$$EnsSystemError ; log it
	}
	Quit $$$OK
}

/// Upon instantiating this service, adjust some properties and start the Gateway Server.
Method OnInit() As %Status
{
	// Heartbeat functionality is not used with External Language Servers
	If ..%gatewayName '= "" {
		Set ..HeartbeatInterval = 0
		Set ..HeartbeatGraceStart = 0
	}
	// Adjust adapter's CallInterval based on heartbeat interval
	If ..HeartbeatInterval>0 {
		If ..HeartbeatInterval<5 {
			Set ..HeartbeatInterval = 5 // Minimum value is 5 seconds
			$$$LOGINFO("HeartbeatInterval adjusted to minimum value of 5 seconds")
		}
		Set ..Adapter.CallInterval = ..HeartbeatInterval
	}
	Else {
		Set ..Adapter.CallInterval = 10 // default 10 seconds if not checking heartbeat
	}
	$$$sysTRACE("Setting CallInterval = "_..Adapter.CallInterval)

	Set tSC = ..StartThisGateway()
	If $$$ISERR(tSC) {
		$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,"Error")
		Set ..GatewayStatus = "Error"
		$$$LOGERROR("Failed to start the Gateway server: "_$$$StatusDisplayString(tSC))
	}
	Else {
		$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,"OK")
		Set ..GatewayStatus = "OK"
		$$$LOGINFO("Gateway Server started successfully")
	}
	Quit tSC
}

/// Shutdown the Gateway Server.
Method OnTearDown() As %Status
{
	$$$LOGINFO("Stopping Gateway Server")
	Set tSC = ..StopThisGateway()
	If $$$ISERR(tSC) {
		$$$LOGERROR("Failed to stop the Gateway Server: "_$$$StatusDisplayString(tSC))
		$$$SetHostMonitor(..%ConfigName,$$$eMonitorStatus,"Error")
	}
	Quit $$$OK
}

/// Start up the Gateway Server.
Method StartThisGateway()
{
	set tSC = $$$OK
	try {
		If (..%gatewayName'="")||(..Server="127.0.0.1") || ($ZCVT(..Server,"l")="localhost") || ($ZCVT(..Server,"l")=$ZCVT($ZU(110),"l")) {
			Set gatewayDefinition = ..GetObjectGateway()
			if gatewayDefinition=$$$NULLOREF set tSC = $$$ERROR($$$GeneralError,"GatewayObject definition object is null") quit
			If ..%gatewayName="" {
				/* if %gatewayName defined then GetObjectGateway starts through call to $system.External.getGateway() */
				$$$LOGINFO("Starting Gateway on port "_gatewayDefinition.Port)
				Set tSC = ##class(%Net.Remote.Service).StartGatewayObject(gatewayDefinition)
			}
		} else {
			$$$LOGINFO("Gateway Server not local to the InterSystems IRIS server, won't be started by this service")
		}
	} catch {
		Set tSC = $$$EnsSystemError
	}
	quit tSC
}

/// Shutdown the Gateway Server.
Method StopThisGateway() As %Status
{
	set tSC = $$$OK
	try {
		If (..Server="127.0.0.1") || ($ZCVT(..Server,"l")="localhost") || ($ZCVT(..Server,"l")=$ZCVT($ZU(110),"l")) {
			/* if we have a Name then call StopGateway else instantiate and call individual methods to stop. */
			If (..%gatewayName '="") {
				If ..%stopNamedGatewayOnTeardown Set tSC = ##class(%Net.Remote.Service).StopGateway(..%gatewayName)
			} Else {
				Set gatewayDefinition = ..GetObjectGateway()
				If gatewayDefinition=$$$NULLOREF {
					Set tSC = $$$ERROR($$$GeneralError,"GatewayObject definition object is null")
				} Else {
					Set gatewayConnection = ##class(%Net.Remote.Gateway).%New()
					Set tSC = gatewayConnection.%Connect(gatewayDefinition.Server,gatewayDefinition.Port)
					If $$$ISOK(tSC) {
						Set tSC = gatewayConnection.%Shutdown()
						Set gatewayConnection.Closed = 1
					}
				}
			}
		} else {
			$$$LOGINFO("The Gateway Server is not local to the InterSystems IRIS server so it won't be shut down or stopped by this service")
		}
	}
	catch {
		set tSC = $$$SystemError
	}
	quit tSC
}

/// "Ping" the Gateway Server to check if it's alive.
Method PingThisGateway(pTimeout As %Numeric = 5) As %Status
{
	set tSC = $$$OK
	try {
		if ..%gatewayName = "" {
			$$$catTRACE("connwait","Gateway PING: Invoking ##class(%Net.Remote.Gateway).%Ping("_..Server_", "_..Port_", "_pTimeout_")")
			set tSC = ##class(%Net.Remote.Gateway).%Ping(..Server, ..Port, pTimeout)
		} else {
			$$$catTRACE("connwait","Gateway PING: Invoking ##class(%Net.Remote.Gateway).%Ping("", "_..%gatewayName_", "_pTimeout_")")
			set tSC = ##class(%Net.Remote.Gateway).%Ping("", ..%gatewayName, pTimeout)
		}
	} catch {
		set tSC = $$$SystemError
	}
	if $$$ISOK(tSC) {
		$$$catTRACE("connwait","Gateway PING successful")
	} else {
		$$$sysTRACE("Error in Gateway PING: "_$$$StatusDisplayString(tSC))
	}
	quit tSC
}

Method GetObjectGateway() As %DynamicObject
{
	quit $$$NULLOREF
}

}
