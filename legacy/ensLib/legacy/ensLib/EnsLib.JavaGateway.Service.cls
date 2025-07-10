/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

/// A service responsible for starting, monitoring and stopping the Java Gateway Server in a production.
Class EnsLib.JavaGateway.Service Extends EnsLib.Gateway.Service [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// IP address or name of the machine where the JVM to be used by the Java Gateway Server is located.
Property Address As %String [ InitialExpression = "127.0.0.1" ];

/// Location of the JVM (similar to JAVA_HOME environment variable).  It is used to find the target JVM and assemble the 
/// command to start the Java Gateway. <br>
/// Note: If there is a default JVM on the machine that is usable without the need to specify its location,
/// this setting may be left blank.
Property JavaHome As %String(MAXLEN = 1023);

/// DEPRECATED : We now check the version of the java executable before starting the gateway.
/// There is no need fo the user to tell which version of the JARs to use anymore.
/// Version of JDK used to select the intended version of the InterSystems .jar files.
/// It is used to assemble the command to start the Java Gateway.
Property JDKVersion As %String(DISPLAYLIST = ",Java 1.7,Java 1.8", VALUELIST = ",JDK17,JDK18") [ Deprecated, InitialExpression = "JDK18" ];

/// CLASSPATH containing the files required to be passed as an argument when starting the JVM.
/// The user should typically provide here the files containing the classes used via the Java Gateway. 
/// We assume that the user has properly quoted the classpath and supplied the correct separators for the platform
/// in case of multiple files. <br>
/// Note that additional classpath can be specified in business operations derived from <class>EnsLib.JavaGateway.AbstractOperation</class>.
/// See property AdditionalPaths in that class.
Property ClassPath As %String(MAXLEN = 32000);

/// Optional arguments to be passed to the Java Virtual Machine (JVM) to include when assembling the 
/// command to start the Java Gateway. <br>
/// For example, you can specify system properties: <b>Dsystemvar=value</b> <br>
/// or set the maximum heap size: <b>Xmx256m</b> <br>
/// and so on, as needed.
Property JVMArgs As %String(MAXLEN = 32000);

/// If set to <b>True</b>, enables Java debugging via TCP, allowing a Java debugger (such as Eclipse or Jswat) to attach. 
/// The default is <b>False</b>. <br>
/// The following arguments can be set: <property>JavaDebug</property>, <property>JavaDebugSuspend</property>
/// and <parameter>JAVADEBUG</parameter>.
Property JavaDebug As %Boolean [ InitialExpression = "0" ];

/// Specifies the port to listen on if <property>JavaDebug</property> is <b>True</b>.  The default is 8000.
Property JavaDebugPort As %String [ InitialExpression = "8000" ];

/// If <property>JavaDebug</property> is <b>True</b>, this setting indicates whether the JVM is suspended
/// on start in order to wait for the debugger to attach. 
/// The default is <b>No</b>.
Property JavaDebugSuspend As %String(DISPLAYLIST = ",Yes,No", VALUELIST = ",y,n") [ InitialExpression = "n" ];

/// Java debugging parameters, used if <property>JavaDebug</property> is <b>True</b>: <br>
/// (see http://java.sun.com/j2se/1.3/docs/guide/jpda/conninv.html#Xrunjdwp)
/// <ul>
/// <li> -Xdebug : Enable debugging </li>
/// <li> -Xnoagent : Disables oldjdb support </li>
/// <li> -Djava.compiler=NONE : Disable JIT compiler </li>
/// <li> -Xrunjdwp : JDWP Options
///      <ul>
///      <li> transport=dt_socket, (Use TCP/IP) </li>
///      <li> address=8000, (Listen on port 8000) </li>
///      <li> suspend=y, (Suspend the Java process until the debugger connects) </li>
///      <li> server=y (Listen for incoming debugger connection) </li> </ul> </ul>
Parameter JAVADEBUG As %String = "-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,address=${JavaDebugPort},suspend=${JavaDebugSuspend},server=y";

Parameter SETTINGS = "%gatewayName:Basic,%stopNamedGatewayOnTeardown:Basic,Address:Basic,Port:Basic,HeartbeatInterval,HeartbeatFailureTimeout,HeartbeatFailureAction,HeartbeatFailureRetry,JavaHome,ClassPath,JVMArgs,Logfile,UsePassphrase,JavaDebug,JavaDebugPort,JavaDebugSuspend,-ArchiveIO";

Method ServerGet() As %String
{
	quit ..Address
}

Method GetObjectGateway() As %DynamicObject
{
	If ..%gatewayName'="" {
		Set gatewayDefinition = $system.external.getGateway(..%gatewayName)
		/* Service/Operation using GetShadowInstance will not get these values
			Populating for any logging here.
		*/
		If $IsObject(gatewayDefinition) {
			Set ..Server = $lg(gatewayDefinition.connectParameters,1)
			Set ..Port = $lg(gatewayDefinition.connectParameters,2)
		}
	} ElseIf ..UsePassphrase {
		$$$LOGERROR("External Language GatewayName must be specified when using passphrase")
		Set gatewayDefinition = ""
	} Else {
		Set gatewayDefinition = ##class(%DynamicObject).%New()
		Set gatewayDefinition.Type = "Java" // type 1
		Set gatewayDefinition.Server = ..Server
		Set gatewayDefinition.Port = ..Port
		Set gatewayDefinition.LogFile = ..Logfile
		Set gatewayDefinition.UsePassphrase = 0
		;
		Set gatewayDefinition.JavaHome = ..JavaHome
		Set gatewayDefinition.ClassPath = ..ClassPath
		Set gatewayDefinition.JVMArgs = ..JVMArgs
		If ..JavaDebug {
			Set debugParams = ..JavaDebugParams(..JavaDebugPort, ..JavaDebugSuspend)
			If (gatewayDefinition.JVMArgs="") {
				Set gatewayDefinition.JVMArgs = debugParams
			} Else {
				Set gatewayDefinition.JVMArgs = gatewayDefinition.JVMArgs_" "_debugParams
			}
		}
	}
	;
	quit gatewayDefinition
}

ClassMethod JavaDebugParams(pDebugPort As %String, pDebugSuspend As %String) As %String
{
	Set tDebug = ..#JAVADEBUG

	Try {
		For parm = "JavaDebugPort", "JavaDebugSuspend" {
			Set what = "${"_parm_"}"
			If parm="JavaDebugPort" { Set value = pDebugPort }
			ElseIf parm="JavaDebugSuspend" { Set value = pDebugSuspend }
			Set p = 1
			For {
				Set p = $F(tDebug,what,p)
				Quit:'p
				Set tDebug = $E(tDebug,1,p-$L(what)-1)_value_$E(tDebug,p,$L(tDebug))
				Set p = p+$L(value)-$L(what)
			}			
		}
	}
	Catch {
		Set tSC = $$$EnsSystemError ; log it
	}

	Quit tDebug
}

/// Start up the Java Gateway Server.
/// This method is deprecated.
ClassMethod StartGateway(pJavaHome As %String, pClassPath As %String, pJVMArgs As %String, pPort As %String, pLogfile As %String = "", pJavaDebug As %Boolean = 0, ByRef pDevice As %String = "", pAddress As %String = "127.0.0.1", pJavaDebugPort As %String = "", pJavaDebugSuspend As %String = "", pUsePassphrase As %Boolean = 0) As %Status [ Deprecated ]
{
	set tSC = $$$OK
	try {
		If (pAddress="127.0.0.1") || ($ZCVT(pAddress,"l")="localhost") || ($ZCVT(pAddress,"l")=$ZCVT($ZU(110),"l")) {
			$$$LOGINFO("Starting Java Gateway with: Port="_pPort_", JavaHome="_pJavaHome_", ClassPath="_pClassPath_", JVMArgs="_pJVMArgs_", LogFile="_pLogfile_", JavaDebug="_$S(pJavaDebug:"y, JavaDebugPort="_pJavaDebugPort_", JavaDebugSuspend="_pJavaDebugSuspend,1:"n"))
			;
			Set gatewayDefinition = ##class(%DynamicObject).%New()
			Set gatewayDefinition.Type = "Java" // type 1
			Set gatewayDefinition.Server = "127.0.0.1"
			Set gatewayDefinition.Port = pPort
			Set gatewayDefinition.LogFile = pLogfile
			Set gatewayDefinition.UsePassphrase = pUsePassphrase
			;
			Set gatewayDefinition.JavaHome = pJavaHome
			Set gatewayDefinition.ClassPath = pClassPath
			Set gatewayDefinition.JVMArgs = pJVMArgs
			If pJavaDebug {
				Set debugParams = pJavaDebugParams(pJavaDebugPort, pJavaDebugSuspend)
				If (gatewayDefinition.JVMArgs="") {
					Set gatewayDefinition.JVMArgs = debugParams
				} Else {
					Set gatewayDefinition.JVMArgs = gatewayDefinition.JVMArgs_" "_debugParams
				}
			}
			;
			Set tSC = ##class(%Net.Remote.Service).StartGatewayObject(gatewayDefinition)
		} else {
			$$$LOGINFO("Java Server not local to the InterSystems IRIS server, won't be started by this service")
		}
	} catch {
		Set tSC = $$$EnsSystemError
	}
	quit tSC
}

/// Shutdown the Gateway.
/// This method is deprecated.
ClassMethod StopGateway(pPort As %String, pServer As %String = "127.0.0.1", pTimeout As %Numeric = 5) As %Status [ Deprecated ]
{
	set tSC = $$$OK
	try {
		if (pServer="127.0.0.1") || ($ZCVT(pServer,"l")="localhost") || ($ZCVT(pServer,"l")=$ZCVT($ZU(110),"l")) {
			/* Deprecated method modified to account for underlying change*/
			Set gatewayConnection = ##class(%Net.Remote.Gateway).%New()
			Set tSC = gatewayConnection.%Connect(pServer,pPort)
			If $$$ISOK(tSC) {
				Set tSC = gatewayConnection.%Shutdown()
				Set gatewayConnection.Closed = 1
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

/// "Ping" the Java Gateway server to check if it's alive.
/// This method is deprecated.
ClassMethod PingJavaGateway(pPort As %String, pServer As %String = "127.0.0.1") As %Status [ Deprecated ]
{
	set tSC = $$$OK
	try {
		$$$catTRACE("connwait","Gateway PING: Invoking ##class(%Net.Remote.Gateway).%Ping("_pServer_", "_pPort_", 4)")
		set tSC = ##class(%Net.Remote.Gateway).%Ping(pServer, pPort, 4)
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

/// Connect to a running Java Gateway Server.
/// This method is deprecated.
ClassMethod ConnectGateway(pEndpoint As %String, ByRef pGateway As %Net.Remote.Gateway, pDebug As %Boolean = 0, pTimeout As %Numeric = 5, pAdditionalPaths As %String = "") As %Status [ Deprecated ]
{
	Set tSC = $$$OK
	
	Try {
		// Create a gateway instance
		Set pGateway = ##class(%Net.Remote.Gateway).%New()
		If '$IsObject(pGateway) Set tSC = %objlasterror Quit
		
		Set tHost = $P(pEndpoint,";",1)
		Set tPort = +$P(pEndpoint,";",2)
		Set tNS = $P(pEndpoint,";",3)
		
		// Appropriate defaults
		If tHost = "" Set tHost = "127.0.0.1"
		If tNS = "" Set tNS = $namespace
		
		// Check port
		If ('tPort) || (tPort'?.N) Set tSC = $$$ERROR($$$EnsErrGeneral, "Invalid or missing port '"_tPort_"'") Quit
		
		$$$sysTRACE($classname()_" invoking %Connect with Address='"_tHost_"', Port='"_tPort_"', tNamespace='"_tNS_"', Timeout="_pTimeout_", AdditionalPaths="_pAdditionalPaths)
		
		// Convert pAdditionalPaths to %ListOfDataTypes if not null
		If pAdditionalPaths="" {
			Set tPath = ""
		}
		Else {
			Set tPath=##class(%ListOfDataTypes).%New()
			For i = 1:1:$L(pAdditionalPaths,",") {
				Do tPath.Insert($P(pAdditionalPaths,",",i))
			}
		}
		
		// And connect
		Set tSC = pGateway.%Connect(tHost, tPort, tNS, pTimeout, tPath,,,0)
		If 'tSC $$$sysTRACE("Error in %Connect: "_$system.Status.GetOneErrorText(tSC))
	}
	
	Catch {
		Set tSC = $$$EnsSystemError
	}
	
	If $$$ISERR(tSC) && $IsObject(pGateway) {
		Do pGateway.%Disconnect()
		Kill pGateway
	}

	Quit tSC
}

}
