/* Copyright (c) 2025 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include (%occJava, %occDotNet, %syPidtab, %External.language)

/// This class contains methods to start, monitor and stop an External Language Server for Java or .NET.
Class %Net.Remote.Service Extends %RegisteredObject [ System = 4 ]
{

ClassMethod SpawnGateway(pName As %String = "", pConfirmationTimeout As %Integer = 60) As %Status
{
	set tSC = $$$OK
	try {
		set tSC = $$SpawnGateway^%SYS.Gateway(pName) quit:$$$ISERR(tSC)
		if pConfirmationTimeout>0 {
			set tSC = ##class(%Net.Remote.Gateway).%Ping("",pName,pConfirmationTimeout)
		}
	} catch {
		set tSC = $$$ERROR($$$GeneralError, $ZE)
	}
	quit tSC
}

/// Start up the External Language Server whose definition is identified by pName.
/// To supress write of progress messages, pass pVerbose = 0.
ClassMethod StartGateway(pName As %String = "", pVerbose As %Boolean = 0, Output pOutput As %String, pConfirm As %Boolean = 0) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
		set tSC = $$StartGateway^%SYS.Gateway(pName, pVerbose, .pOutput, pConfirm) quit:$$$ISERR(tSC)
	} catch {
		set tSC = $$$ERROR($$$GeneralError, $ZE)
	}
	quit tSC
}

/// This method is internal, it's called from ^%SYS.Gateway after granting resources
ClassMethod StartGatewayInternal(pName As %String, pVerbose As %Boolean = 0, Output pOutput As %String, pConfirm As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..OpenGateway(pName, .pGateway)
		If tSC {
			If pGateway.Type="ML", '..IntegratedMLJARInstalled() {
				Set tSC = $$$ERROR($$$MLNotInstalled)
				Quit
			}
			Lock +^%ISC.ObjectGateway.Management(pName):15
			If $TEST=1 { // succeeded in acquiring lock before timeout
				Set tSC = ..StartGatewayObject(pGateway, pVerbose, .pOutput, .pConfirm)
				Lock -^%ISC.ObjectGateway.Management(pName)#"I"
			}
			Else { // lock timed out
				Set tSC = $$$ERROR($$$GeneralError, "Lock timeout expired for gateway object")
			}
		}
	}
	Catch {
		Set tSC = $$$ERROR($$$GeneralError, $ZE)
	}
	Quit tSC
}

/// Start up the External Language Server whose definition is an object reference variable pGateway.
/// To supress write of progress messages, pass pVerbose = 0.
ClassMethod StartGatewayObject(pGateway As %DynamicObject, pVerbose As %Boolean = 0, Output pOutput As %String, pConfirm As %Boolean = 0) As %Status [ Internal ]
{
	if $p($roles,",",1)'=$$$AllRoleName quit $$$ERROR($$$AccessDenied)
	
	new $namespace do $zutil(5,"%SYS")
	
	Set tSC = $$$OK
	set isRunning = 0
	Set tDev = $I

	// This section is only concerned with normalizing the pGateway object - to ensure we have a valid Config.Gateways or ad hoc
	Set pOutput = ""
	if (pGateway.%IsA("%Library.DynamicAbstractObject")) {
		set objectGateway = pGateway
	} elseif (pGateway.%IsA("%Net.Remote.ObjectGateway")) {
		set objectGateway = pGateway.toDao()
	} else {
		$$$ThrowStatus($$$ERROR($$$GeneralError,"%Net.Remote.Service::StartGatewayObject - invalid External Language Server"))
	}
			
	try {
		if (objectGateway.Type = "") || ($$$lcase(objectGateway.Type) = $$$EXTERNALLANGUAGESERVERTYPELCREMOTE) {
			do ..Log(1, objectGateway, "External Language Server is remote, won't be started by this Service",pVerbose)
		} else {
			do ..Log(1, objectGateway, "Starting "_objectGateway.Type_" Gateway Server '"_objectGateway.Name_"'",pVerbose)
				// This is the "is ELS running check. First, check for a free port. If not free then ping to see if the server is ours
			if ##class(%Net.Remote.Utility).CheckLocalPortFree("127.0.0.1", objectGateway.Port,objectGateway.AllowedIPAddresses) {
				if ($$$isUNIX) && (objectGateway.Type=".NET") && '..IsCore(objectGateway) && '..IsNet(objectGateway) {
					do ..Log(2, objectGateway, "External Language Server for .NET Framework can only be started on Windows systems",pVerbose)
					$$$ThrowStatus($$$ERROR($$$GeneralError,"External Language Server: Can only start a .NET Framework server on Windows"))
				} else {
					set tSC = ..RunStartCmd(objectGateway, .tOutput,pVerbose)
					set:tOutput'="" pOutput = tOutput
					if $$$ISERR(tSC) {
						if objectGateway.Resource'="" {
							do ##class(%Net.Remote.Utility).ClearPassphrase(objectGateway.Name)
						}
						$$$ThrowStatus(tSC)
					}
					Do ##class(%Net.Remote.Gateway).%RegisterSuperServer(objectGateway.Name, objectGateway.AllowedIPAddresses, objectGateway.Port)
					if pConfirm {
						if objectGateway.Name'="" {
							set tSC = ##class(%Net.Remote.Gateway).%Ping("",objectGateway.Name,objectGateway.InitializationTimeout,,,.serverName,objectGateway.SSLConfigurationClient)
							Do:$$$ISOK(tSC) ..Log(1, objectGateway, "Successfully pinged Gateway Server",pVerbose)
							set isGatewayRunning =  ##class(%Net.Remote.Service).IsGatewayRunning("",objectGateway.Name,0,,0,objectGateway.AllowedIPAddresses,objectGateway.SSLConfigurationClient)
						} else {
							set tSC = ##class(%Net.Remote.Gateway).%Ping("127.0.0.1",objectGateway.Port,objectGateway.InitializationTimeout,,,.serverName,objectGateway.SSLConfigurationClient)
							Do:$$$ISOK(tSC) ..Log(1, objectGateway, "Successfully pinged Gateway Server",pVerbose)
							set isGatewayRunning =  ##class(%Net.Remote.Service).IsGatewayRunning("127.0.0.1",objectGateway.Port,0,,0,objectGateway.AllowedIPAddresses,objectGateway.SSLConfigurationClient)
						}						
						if isGatewayRunning {
							Do ..UpdateState(objectGateway.Port,1)
							do ..Log(1, objectGateway, "Successfully detected Gateway Server running",pVerbose)
							Do ..Log(1, objectGateway, "Gateway Server successfully started",pVerbose)
						} else {
							do ..Log(1, objectGateway, "Failed to detect Gateway Server running",pVerbose)
							$$$ThrowStatus($$$ERROR($$$GeneralError, "Failed to detect Gateway"))
						}
					} else {
						do ..Log(1, objectGateway, "Gateway Server start-up confirmation skipped",pVerbose)
						Do ..UpdateState(objectGateway.Port,1)
					}
				}
			} else {
					// check to see if this port listener is the server we wish to start, this has the side effect of setting serverName
				if objectGateway.Name'="" {
					set pingStatus = ##class(%Net.Remote.Gateway).%Ping("",objectGateway.Name,10,,,.serverName)
				} else {
					set pingStatus = ##class(%Net.Remote.Gateway).%Ping("127.0.0.1",objectGateway.Port,10,,,.serverName)
				}
				if $$$ISERR(pingStatus) {
					set pingStatus = $$$EMBEDSC(pingStatus,$$$ERROR($$$GeneralError,"External Language Server: invalid ping response"))
					$$$ThrowStatus(pingStatus)
				} elseif (serverName '= "") && (serverName '= objectGateway.FullName) {
					$$$ThrowStatus($$$ERROR($$$GeneralError, "External Language Server: Cannot start server, port '" _ objectGateway.Port _ "' is in use"))
				} else {
					do ..Log(1, objectGateway, "External Language Server: Server is already running",pVerbose)
				}
			}
		}
	} catch exception {
		set tSC = exception.AsStatus()
		Do ..Log(1, objectGateway, "An error occurred while trying to start the Gateway Server",pVerbose)
	}
	
    Use:tDev'="" tDev
	return tSC
}

/// Run command to start the Gateway Server.
ClassMethod RunStartCmd(pGateway As %DynamicObject, Output pOutput As %String, pVerbose As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set pOutput = ""
	
	Try {
		Set tCmd = ""
		If (pGateway.Type="Java")||(pGateway.Type="JDBC")||(pGateway.Type="XSLT")||(pGateway.Type="ML")||(pGateway.Type="R") {
			Set tSC = ..CmdLineForJava(pGateway, .tCmd, .tCmdArgs, .tEnvVars, .tPredictedCmdStr)
		}
		ElseIf pGateway.Type=".NET" {
			Set tSC = ..CmdLineForDotNet(pGateway, .tCmd, .tCmdArgs, .tEnvVars, .tPredictedCmdStr)
		}
		ElseIf pGateway.Type="Python" {
			Set tSC = ..CmdLineForPython(pGateway, .tCmd, .tCmdArgs, .tEnvVars, .tPredictedCmdStr)
		}
		ElseIf pGateway.Type="ODBC" {
			Set tSC = ..CmdLineForODBC(pGateway, .tCmd, .tCmdArgs, .tEnvVars, .tPredictedCmdStr)
		}
		Else  {
			Set tSC = $$$ERROR($$$GeneralError, "Unknown External Language Server type '"_pGateway.Type_"'")
		}
		Set:($$$ISOK(tSC) && (tCmd="")) tSC = $$$ERROR($$$GeneralError, "Command to start Gateway couldn't be identified, check if property Type is properly set")
		If 'tSC Do ..LogStatus(tSC, pGateway, "RunStartCmd",pVerbose) Quit
		
		Do ..Log(1, pGateway, "Executing O.S. command: "_$Get(tPredictedCmdStr),pVerbose)
		
		// Start the External Language server
		Set tSC = ##class(%Net.Remote.Utility).RunCommandViaCPIPE(tCmd,.pDevice,.tOutput,pGateway.InitializationTimeout,10,.tCmdArgs,.tEnvVars)
		Close pDevice:"I"
		Do:$$$ISERR(tSC) ..LogStatus(tSC, pGateway, "RunStartCmd",pVerbose)
		Do ..Log(1, pGateway, "Execution returned: '"_tOutput_"'",pVerbose)
		Set pOutput = tOutput

		If (pGateway.Type="Java")||(pGateway.Type="JDBC")||(pGateway.Type="XSLT")||(pGateway.Type="ML") {
			if tOutput="nohup: ignoring input" {
			Set tOutput = ""
			}
		}
		
		If (pGateway.Type=".NET") {
			// Warning to check output text from .NET Gateway Server
			If (tOutput="") {
				// We should get "Listening on IP:Port...".
				Set tSC = $$$ERROR($$$GeneralError, "There was an error starting the .NET External Language Server")
			} Elseif '$$$DotNetOutputLineIndicatesListening(tOutput) {
				// Don't assume if output does not start with "Listening on" is an error, leave it up to the user to check the returned output, which was logged previously
				Do ..Log(2, pGateway, "Unexpected contents returned from .NET Gateway Server, please check",pVerbose)
			}
		}
	} Catch (ex) {
		// don't overwrite the error status if it's already populated
		Set:$$$ISOK(tSC) tSC = ex.AsStatus()
	}
	
	Quit tSC
}

/// True if the .NET version is .NET Core (ex: Core 2.1)
ClassMethod IsCore(pGateway As %DynamicObject) As %Boolean [ Internal ]
{
	return $e(pGateway.DotNetVersion,1)="C"
}

/// True if the .NET version is .NET 5 or greater
ClassMethod IsNet(pGateway As %DynamicObject) As %Boolean [ Internal ]
{
	return $e(pGateway.DotNetVersion,1)="N"
}

/// Assemble the command to start the External Language Server for .NET based on the settings.
ClassMethod CmdLineForDotNet(pGateway As %DynamicObject, Output pCmd As %String, Output pCmdArgs, Output pEnvVars, Output pPredictedCmdStr As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set pCmd = ""
	Set pPredictedCmdStr = ""

	Try {
		
		set tSC = ..GetDotNetAssembly(pGateway, .pCmd, .pCmdArgs, .pPredictedCmdStr)
		Quit:$$$ISERR(tSC)
		
		Set pCmdArgs($increment(pCmdArgs)) = +pGateway.Port

		Set pCmdArgs($increment(pCmdArgs)) = pGateway.LogFile

		Set pCmdArgs($increment(pCmdArgs)) = pGateway.FullName
		
		Set pCmdArgs($increment(pCmdArgs)) = pGateway.AllowedIPAddresses
		
		Set pCmdArgs($increment(pCmdArgs)) = "" //always use "" for what now is an SSL-only argument
		
		#dim tPassphraseHEX as %String = ""
		set pGateway.passphraseList = ""
		if pGateway.Resource'="" {
			try {
				set pGateway.passphraseList = ##class(%Net.Remote.Utility).GeneratePassphrase(pGateway.Name)
				set tPassphraseHEX = $LG(pGateway.passphraseList,2)
			} catch {}
			if tPassphraseHEX = "" {
				set tSC = $$$ERROR($$$GeneralError, "Failed to generate Passphrase")
				quit
			}
			set pEnvVars("IRIS_GATEWAY_PASSPHRASE") = tPassphraseHEX
		}
		
		// build the predicted command string (for displaying in logs, etc.)
		Set pPredictedCmdStr = pCmd
		For ctr=1:1:pCmdArgs {
			Set cmdArg = pCmdArgs(ctr)
			Set:(cmdArg[" ")||(cmdArg="") cmdArg = $char(34)_cmdArg_$char(34)
			Set pPredictedCmdStr = pPredictedCmdStr_" "_cmdArg
		}
	}
	Catch {
		Set tSC = $$$ERROR($$$GeneralError, $ZE)
	}	
	
	Quit tSC
}

ClassMethod GetDotNetAssembly(pGateway As %DynamicObject, Output pCmd As %String, Output pCmdArgs, Output pPredictedCmdStr As %String) As %Status [ Internal ]
{
	Set tSlash = $s($$$isUNIX:"/", 1:"\")
	set tSC = $$$OK
	
	// use executables with new names if they exist, FilePath is path to gateway executable directory
	// if it works, return from this method
	If ($$$isUNIX && ..IsNet(pGateway)) {
		Set tPath = pGateway.FilePath
		// add check for linux arm
		Set tExec = $select($$$isMACOSX:$$$DotNetGatewayMacExe, $$$isARM:$$$DotNetGatewayArmExe, 1:$$$DotNetGatewayLinuxExe)
		Set tVersion = pGateway.DotNetVersion
		
		If tVersion="N5.0" Set tDir = "net5.0"
		If tVersion="N6.0" Set tDir = "net6.0"
		If tVersion="N7.0" Set tDir = "net7.0"
		If tVersion="N8.0" Set tDir = "net8.0"
		
		if (tPath="") {
			set tPath = $system.Util.InstallDirectory()_tSlash_"dev"_tSlash_"dotnet"_tSlash_"bin"_tSlash_tDir
		}
		
		Set pCmd = ##class(%File).NormalizeFilename(tPath_tSlash_tExec)
		
		If ##class(%File).Exists(pCmd) {
			// Case where unix executables exist, so we can use them
			Kill pCmdArgs
			Quit tSC
		}
	}
	
	// Creates command <dotnet Gateway.dll>, where filepath is path to dotnet
	// Core always runs dll file, .NET 5+ runs dll file only if on Unix and no compatible executable was found
	If (..IsCore(pGateway) || $$$isUNIX) {
		Set tPath = pGateway.FilePath

		if (tPath'="") {
			if ($e(tPath,*)=tSlash) {
				set tPath=$e(tPath,1,*-1)
			}
			set pCmd = tPath_tSlash_"dotnet"
			Set pCmd = ##class(%File).NormalizeFilename(pCmd)
			If '##class(%File).Exists(pCmd_$select($$$isUNIX:"", 1:".exe")) {
				Set tSC = $$$ERROR($$$GeneralError, ".NET Core executable not found at '"_pCmd_"'") 
				Quit tSC
			}
		} else {
			set pCmd = "dotnet"
		}

		// find the Gateway DLL
		set tExec = $system.Util.InstallDirectory()_tSlash_"dev"_tSlash_"dotnet"_tSlash_"bin"
		if (..IsCore(pGateway)) {
			set tExec = tExec_tSlash_$$$CoreGatewayDirectory_tSlash_$$$CoreGatewayExec_".dll"
		} elseif pGateway.DotNetVersion = "N5.0" {
			set tExec = tExec_tSlash_$$$Net5GatewayDirectory_tSlash_$$$DotNetGatewayExe_".dll"
		} else {
			set tExec = tExec_tSlash_"net6.0"_tSlash_$$$DotNetGatewayExe_".dll"
		}
		Set tExec = ##class(%File).NormalizeFilename(tExec)

		If '##class(%File).Exists(tExec) {
			Set tSC = $$$ERROR($$$GeneralError, ".NET External Language Server dll not found at '"_tExec) 
			Quit tSC
		}

		// build the command arguments
		Kill pCmdArgs
		Set pCmdArgs($increment(pCmdArgs)) = tExec

	} Else {
		// .NET executable command used with .NET Framework and .NET 5+ on Windows
		Set tPath = pGateway.FilePath
		Set tExec = $s(($system.Version.Is64Bits() && 'pGateway.Exec32):$$$DotNetGatewayExe64, 1:$$$DotNetGatewayExe)
		Set tVersion = pGateway.DotNetVersion
					
		Set tDir = "net6.0" // Default
		If tVersion="F3.5" Set tDir = "v3.5"
		If tVersion="F4.6.2" Set tDir = "v4.6.2"
		If tVersion="N5.0" Set tDir = $$$Net5GatewayDirectory
		If tVersion="N7.0" Set tDir = "net7.0"
		If tVersion="N8.0" Set tDir = "net8.0"
		
		if (tPath="") {
			set tPath = $system.Util.InstallDirectory()_tSlash_"dev"_tSlash_"dotnet"_tSlash_"bin"_tSlash_tDir
		}

		Set pCmd = ##class(%File).NormalizeFilename(tPath_tSlash_tExec)
		
		If '##class(%File).Exists(pCmd_".exe") {
			Set tSC = $$$ERROR($$$GeneralError, ".NET External Language Server executable not found at '"_pCmd_".exe'") 
			Quit tSC
		}

		// build the command arguments
		Kill pCmdArgs
	}
	Quit tSC
}

/// Assemble the command to start the External Language Server for Java based on the settings.
ClassMethod CmdLineForJava(pGateway As %DynamicObject, Output pCmd As %String, Output pCmdArgs, Output pEnvVars, Output pPredictedCmdStr As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set pCmd = ""
	Set pPredictedCmdStr = ""

	Try {
		// Get Java executable command relative to JAVA_HOME
		Set tSC = ..GetJavaExecutableCommand(pGateway.JavaHome,.javaExecutable,0)
		Quit:$$$ISERR(tSC)
		Set pCmd = javaExecutable

		// build the command arguments
		Set pCmdArgs = ""

		/*
			To handle restricted login accounts that will lead to the gateway closing when the user exits
			We limit to Unix and Java Gateways
			We are using the JVMArgs field to examine if the system admin wants us to try to use nohup
			We then only start with nohup if job is Interactive Job (application mode) then use request nohup
		*/
		If ($$$isUNIX) && (pGateway.Type="Java") {
			/*
				Use a -D to set a system property in case
				not removed later and want it to be ignored
				if makes to command line
			*/
			#Dim tAllownohupArg = "-DInterSystems.nohup=allow"
			If pGateway.JVMArgs[tAllownohupArg {
				#; Remove the special identifier
				Set pGateway.JVMArgs = $Replace(pGateway.JVMArgs," "_tAllownohupArg,"")
				Set pGateway.JVMArgs = $Replace(pGateway.JVMArgs,tAllownohupArg_" ","")
				#; If job is Interactive Job (application mode) then use requested nohup
				If (##class(%SYS.ProcessQuery).%OpenId($Job).JobType = $$$FORAPPJOB) {
					Set pCmdArgs($increment(pCmdArgs)) = pCmd
					Set pCmd = "nohup"
				}
			}
		}

		// Add -Xrs to ignore OS signals and not shutdown when the user logs off
		Set pCmdArgs($increment(pCmdArgs)) = "-Xrs"

		// Add -Xshare:off to turn off class data sharing
		Set pCmdArgs($increment(pCmdArgs)) = "-Xshare:off"

		// Add system property for customized class loader
		Set pCmdArgs($increment(pCmdArgs)) = "-Djava.system.class.loader=com.intersystems.gateway.ClassLoader"

		// H2O IntegratedML third-party library uses reflection internally in a
		// way that requires reflective access to be granted explicity for Java
		// versions > 8
		If pGateway.Type = "ML" {
			Set tSC = ..GetJavaVersion(pGateway.JavaHome, .version)
			Quit:$$$ISERR(tSC)
			If version > 8 {
				Set pCmdArgs($increment(pCmdArgs)) = "--add-opens"
				Set pCmdArgs($increment(pCmdArgs)) = "java.base/java.lang=ALL-UNNAMED"
				Set pCmdArgs($increment(pCmdArgs)) = "--add-opens"
				Set pCmdArgs($increment(pCmdArgs)) = "java.base/java.util=ALL-UNNAMED"
				Set pCmdArgs($increment(pCmdArgs)) = "--add-opens"
				Set pCmdArgs($increment(pCmdArgs)) = "java.base/java.lang.reflect=ALL-UNNAMED"
			}
		}

		// Add any user supplied JVM arguments
		If (pGateway.JVMArgs '= "") {
			Set jvmArgs = $listfromstring(pGateway.JVMArgs," ")

			If $listlength(jvmArgs)>0 {
				// if any substring doesn't start with a single dash, then tack it on to the previous one
				Set jvmArgsDash = $listbuild($list(jvmArgs,1))
				For ctr=2:1:$listlength(jvmArgs) {
					Set arg = $list(jvmArgs,ctr)
					If $Extract(arg,1,1)'="-" {
						Set $list(jvmArgsDash,$listlength(jvmArgsDash)) = $list(jvmArgsDash,$listlength(jvmArgsDash))_" "_arg
					} Else {
						Set jvmArgsDash = jvmArgsDash_$listbuild(arg)
					}
				}
				Set jvmArgs = jvmArgsDash
				
				// if any substring contains an odd number of un-escaped double quotes, then keep appending to it until find the pair
				Set jvmArgsQuote = ""
				For ctr=1:1:$listlength(jvmArgs) {
					Set arg = $list(jvmArgs,ctr)
					
					Set unescapedQuotesFound = 0
					Set currentSearchIndex = 1
					While currentSearchIndex<($length(arg)+2) {
						Set indexAfterQuote = $find(arg,"""",currentSearchIndex)
						Quit:(indexAfterQuote=0) // no more double quotes found

						Set isEscaped = (indexAfterQuote>2)&&($extract(arg,indexAfterQuote-2,indexAfterQuote-2)="\")
						Set:'isEscaped unescapedQuotesFound = unescapedQuotesFound+1
						Set currentSearchIndex = indexAfterQuote
					}
					
					If (unescapedQuotesFound#2=0) { // even number of double quotes found
						Set jvmArgsQuote = jvmArgsQuote_$listbuild(arg)
					} Else { // odd number of double quotes found
						If (ctr=$listlength(jvmArgs)) { // end of list, just add to command line as is (should maybe throw an error here?)
							Set jvmArgsQuote = jvmArgsQuote_$listbuild(arg)
						} Else { // append to next list item
							Set $list(jvmArgs,ctr+1)=arg_" "_$list(jvmArgs,ctr+1)
						}
					}
				}
				Set jvmArgs = jvmArgsQuote
				
				For ctr=1:1:$listlength(jvmArgs) {
					Set cmdArg = $list(jvmArgs,ctr)
					Set pCmdArgs($increment(pCmdArgs)) = $list(jvmArgs,ctr)
				}
			}
		}

		if pGateway.Type = "XSLT" {
			set meta = ##class(%DynamicObject).%FromJSON(^%SYS("java","intersystems-utils"))
			if (meta.version.major = 4) && (meta.version.minor > 1) || (meta.version.major > 4) {
				set pGateway.MainClassName = $$$javaGatewayClass
			} else {
				set pGateway.MainClassName = $$$xsltGatewayClass
			}
		} else {
			set pGateway.MainClassName = $$$javaGatewayClass
		}

		// Get the required classpath (gateway + JDBC [+ util] JARs)
		Set tSC = ..GetJavaRequiredClassPath(pGateway,.requiredClassPath)
		Quit:$$$ISERR(tSC)

		// Build classpath argument
		// We assume that the user has properly quoted the class path and supplied correct class path separators.
		Set tCPSep = $Select($$$isWINDOWS:";", 1:":")
		Set tClassPath = pGateway.ClassPath_$Case(pGateway.ClassPath,"":"",:tCPSep)_requiredClassPath

		// Add the classpath (user supplied and default)
		Set pCmdArgs($increment(pCmdArgs)) = "-classpath"
		Set pCmdArgs($increment(pCmdArgs)) = tClassPath

		// Add the Gateway Server class name
		Set pCmdArgs($increment(pCmdArgs)) = pGateway.MainClassName

		Set pCmdArgs($increment(pCmdArgs)) = +pGateway.Port
		
		Set pCmdArgs($increment(pCmdArgs)) = pGateway.LogFile
		
		Set pCmdArgs($increment(pCmdArgs)) = pGateway.FullName

		Set pCmdArgs($increment(pCmdArgs)) = pGateway.AllowedIPAddresses

		set useEnv = 0
		for i=1:1:$l(tClassPath,tCPSep) {
			set tClassPathOne = $p(tClassPath,tCPSep,i)
			if tClassPathOne["intersystems-jdbc-" {
				set jdbcVersion = $p($p($p($tr(tClassPathOne,"\","/"),"/",*),"-",3),".",1,2)
				set useEnv = jdbcVersion>=3.6
			}
		}
		
		#dim tPassphraseHEX as %String = ""
		set pGateway.passphraseList = ""
		if pGateway.Resource'="" {
			try {
				set pGateway.passphraseList = ##class(%Net.Remote.Utility).GeneratePassphrase(pGateway.Name)
				set tPassphraseHEX = $LG(pGateway.passphraseList,2)
			} catch {}
			if tPassphraseHEX = "" {
				set tSC = $$$ERROR($$$GeneralError, "Failed to generate Passphrase")
				quit
			}
			if useEnv {
				set pCmdArgs($increment(pCmdArgs)) = "" // passphrase is empty string
				set pEnvVars("IRIS_GATEWAY_PASSPHRASE") = tPassphraseHEX
			} else {
				set pCmdArgs($increment(pCmdArgs)) = tPassphraseHEX
			}
		}
		
		// build the predicted command string (for displaying in logs, etc.)
		Set pPredictedCmdStr = pCmd
		For ctr=1:1:pCmdArgs {
			Set cmdArg = pCmdArgs(ctr)
			Set:(cmdArg[" ")||(cmdArg="") cmdArg = $char(34)_cmdArg_$char(34)
			Set pPredictedCmdStr = pPredictedCmdStr_" "_cmdArg
		}
	}
	Catch {
		Set tSC = $$$ERROR($$$GeneralError, $ZE)
	}
	
	Quit tSC
}

/// Assemble the command to start the External Language Server for Python based on the settings.
ClassMethod CmdLineForPython(pGateway As %DynamicObject, Output pCmd As %String, Output pCmdArgs, Output pEnvVars, Output pPredictedCmdStr As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set pCmd = ""
	Set pPredictedCmdStr = ""

	Try {
		// Get Python executable command and check Python version
		Set tSC = ..GetPythonExecutableCommand(pGateway.PythonPath,.pythonExecutable,.pythonVersion,0)
		Quit:$$$ISERR(tSC)
		// Get python script path
		Set tSC = ..GetPythonGatewayScript(.runpythonScript, "runpython", 0)
		Quit:$$$ISERR(tSC)
		Set tSC = ..GetPythonGatewayScript(.setupScript, "setup", 0)
		Quit:$$$ISERR(tSC)
		
		// Get iris version and remove parentheses
		Set irisVersion = $zstrip($SYSTEM.Version.GetVersion(),"*", "()")
		// Check if python version, python executable path, iris version is changed
		Set tSC = ..CompareChecksum(.compareResult, pGateway.Name, pythonVersion, pythonExecutable, irisVersion)
		Quit:$$$ISERR(tSC)
		
		// compareResult is:
		//   "0": re-create virtual environment
		//   "1": re-install package
		//   "2": do nothing
		If compareResult '= "2" {
			Set tSC = ..SetupVirtualEnv(setupScript, pGateway.Name, pythonExecutable, compareResult, irisVersion)
		Quit:$$$ISERR(tSC)
		}
		
		Set pCmd = runpythonScript

		// build the command arguments
		Set pCmdArgs = ""

		// Add any user supplied python options
		If (pGateway.PyOptions '= "") {
			Set pyOptions = $listfromstring(pGateway.PyOptions," ")
			If $listlength(pyOptions)>0 {
				For ctr=1:1:$listlength(pyOptions) {
					Set pCmdArgs($increment(pCmdArgs)) = $list(pyOptions,ctr)
				}
			}
		}
		
		// Add -m to search for the named module and execute its contents as the __main__ module
		Set pCmdArgs($increment(pCmdArgs)) = pGateway.Name
		Set pCmdArgs($increment(pCmdArgs)) = "-m"

		// Add the Gateway Server module name
		Set pCmdArgs($increment(pCmdArgs)) = "iris"
		Set pCmdArgs($increment(pCmdArgs)) = "PythonGateway"

		Set pCmdArgs($increment(pCmdArgs)) = +pGateway.Port
		
		Set pCmdArgs($increment(pCmdArgs)) = pGateway.LogFile
		
		// escape "%" character for Windows's batch file argument
		set serverFullName = pGateway.FullName
		if $$$isWINDOWS set serverFullName = $replace(serverFullName,"%","%%")
		Set pCmdArgs($increment(pCmdArgs)) = serverFullName

		Set pCmdArgs($increment(pCmdArgs)) = pGateway.AllowedIPAddresses
		
		if pGateway.SSLConfigurationServer '= "" {
			// First export the SSLConfig (minus the password)
			set sslConfigPath = ##class(%File).TempFilename(".xml")
			set sslConfig = pGateway.SSLConfigurationServer
			set tSC = ##class(Security.SSLConfigs).Export(sslConfigPath, .configCount, sslConfig, 1) quit:$$$ISERR(tSC)
			if configCount > 1 {
				set tSC = $$$ERROR($$$GeneralError, "At most one SSL Configuration may be provided for the gateway")
				quit
			}
			if configCount < 1 {
				set tSC = $$$ERROR($$$GeneralError, "The SSL Configuration provided could not be exported")
				quit
			}
			set securityArg = "ssl:" _ sslConfigPath_":"
			// If PrivateKeyPassword is needed, encode it and append to securityArg
			set tSC = ##class(Security.SSLConfigs).Get(sslConfig, .sslConfigProperties) quit:$$$ISERR(tSC)
			if sslConfigProperties("PrivateKeyPassword") '= "" {
				set encodedPwd = $system.Encryption.Base64Encode(sslConfigProperties("PrivateKeyPassword"))
				set securityArg = securityArg _ encodedPwd
			}
			Set pCmdArgs($increment(pCmdArgs)) = securityArg
		} else {
			Set pCmdArgs($increment(pCmdArgs)) = ""
		}

		#dim tPassphraseHEX as %String = ""
		set pGateway.passphraseList = ""
		if pGateway.Resource'="" {
			try {
				set pGateway.passphraseList = ##class(%Net.Remote.Utility).GeneratePassphrase(pGateway.Name)
				set tPassphraseHEX = $LG(pGateway.passphraseList,2)
			} catch {}
			if tPassphraseHEX = "" {
				set tSC = $$$ERROR($$$GeneralError, "Failed to generate Passphrase")
				quit
			}
			set pEnvVars("IRIS_GATEWAY_PASSPHRASE") = tPassphraseHEX
		}
		
		// build the predicted command string (for displaying in logs, etc.)
		Set pPredictedCmdStr = pCmd
		For ctr=1:1:pCmdArgs {
			Set cmdArg = pCmdArgs(ctr)
			Set:(cmdArg[" ")||(cmdArg="") cmdArg = $char(34)_cmdArg_$char(34)
			Set pPredictedCmdStr = pPredictedCmdStr_" "_cmdArg
		}
	}
	Catch {
		Set tSC = $$$ERROR($$$GeneralError, $ZE)
	}
	
	Quit tSC
}

/// Assemble the command to start the External Language Server for Python based on the settings.
ClassMethod CmdLineForODBC(pGateway As %DynamicObject, Output pCmd As %String, Output pCmdArgs, Output pEnvVars, Output pPredictedCmdStr As %String) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set pCmd = ""
	Set pPredictedCmdStr = ""
	
	set tpath = $zu(12)
	set path = $p(tpath,"\",1,$l(tpath,"\")-2)
	if (path = "") set path = $p(tpath,"/",1,$l(tpath,"/")-2)
	set path = path_"/bin/"
	
	// Get iris version and remove parentheses
	Set irisVersion = $zstrip($SYSTEM.Version.GetVersion(),"*", "()")
	
	Set pCmd = path_$s($$$isWINDOWS:"ODBCGateway.exe", 1:"ODBCGateway")

	// build the command arguments
	Set pCmdArgs = ""
	
	// Add any user supplied python options
	Set pCmdArgs($increment(pCmdArgs)) = +pGateway.Port

	Set pCmdArgs($increment(pCmdArgs)) = pGateway.LogFile

	Set pCmdArgs($increment(pCmdArgs)) = pGateway.FullName

	Set pCmdArgs($increment(pCmdArgs)) = pGateway.AllowedIPAddresses
		
	if pGateway.SSLConfigurationServer '= "" {
		// First export the SSLConfig (minus the password)
		set sslConfigPath = ##class(%File).TempFilename(".xml")
		set sslConfig = pGateway.SSLConfigurationServer
		set tSC = ##class(Security.SSLConfigs).Export(sslConfigPath, .configCount, sslConfig, 1) quit:$$$ISERR(tSC)
		if configCount > 1 {
			set tSC = $$$ERROR($$$GeneralError, "At most one SSL Configuration may be provided for the gateway")
			quit
		}
		if configCount < 1 {
			set tSC = $$$ERROR($$$GeneralError, "The SSL Configuration provided could not be exported")
			quit
		}
		set securityArg = "ssl:" _ sslConfigPath_":"
		// If PrivateKeyPassword is needed, encode it and append to securityArg
		set tSC = ##class(Security.SSLConfigs).Get(sslConfig, .sslConfigProperties) quit:$$$ISERR(tSC)
		if sslConfigProperties("PrivateKeyPassword") '= "" {
			set encodedPwd = $system.Encryption.Base64Encode(sslConfigProperties("PrivateKeyPassword"))
			set securityArg = securityArg _ encodedPwd
		}
		Set pCmdArgs($increment(pCmdArgs)) = securityArg
	} else {
		Set pCmdArgs($increment(pCmdArgs)) = ""
	}

	#dim tPassphraseHEX as %String = ""
	set pGateway.passphraseList = ""
	if pGateway.Resource'="" {
		try {
			set pGateway.passphraseList = ##class(%Net.Remote.Utility).GeneratePassphrase(pGateway.Name)
			set tPassphraseHEX = $LG(pGateway.passphraseList,2)
		} catch {}
		if tPassphraseHEX = "" {
			set tSC = $$$ERROR($$$GeneralError, "Failed to generate Passphrase")
			quit
		}
		set pEnvVars("IRIS_GATEWAY_PASSPHRASE") = tPassphraseHEX
	}
	
	// build the predicted command string (for displaying in logs, etc.)
	Set pPredictedCmdStr = pCmd
	For ctr=1:1:pCmdArgs {
		Set cmdArg = pCmdArgs(ctr)
		Set:(cmdArg[" ")||(cmdArg="") cmdArg = $char(34)_cmdArg_$char(34)
		Set pPredictedCmdStr = pPredictedCmdStr_" "_cmdArg
	}

	Quit tSC
}

/// Stop the External Language Server whose definition is identified by pName.
/// To supress write of progress messages, pass pVerbose = 0.
/// 
/// pName        : gateway name
/// pVerbose     : flag to enable verbose logging, 0 by default
/// pStopMonitor : flag to enable monitoring of gateway shutdown process, no longer in use
/// pTimeout     : soft shutdown timeout in seconds, 0 by default
ClassMethod StopGateway(pName As %String, pVerbose As %Boolean = 0, pStopMonitor As %Boolean = 1, pTimeout As %Integer = 0) As %Status
{
	Set tSC = $$$OK
	Try {
		Set tSC = ..OpenGateway(pName, .pGateway)
		If tSC Set tSC = ..StopGatewayObject(pGateway, pVerbose, pTimeout)
	}
	Catch {
		Set tSC = $$$ERROR($$$GeneralError, $ZE)
	}
	Quit tSC
}

/// Stop the External Language Server whose definition is an object reference variable pGateway.
/// To supress write of progress messages, pass pVerbose = 0.
/// 
/// pGateway     : object with gateway configuration settings
/// pVerbose     : flag to enable verbose logging, 0 by default
/// pTimeout     : soft shutdown timeout in seconds, 0 by default
ClassMethod StopGatewayObject(pGateway As %DynamicObject, pVerbose As %Boolean = 0, pTimeout As %Integer = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set tDev = $I
	if (pGateway.%IsA("%Library.DynamicAbstractObject")) {
		set objectGateway = pGateway
	} elseif (pGateway.%IsA("%Net.Remote.ObjectGateway")) {
		set objectGateway = pGateway.toDao()
	} else {
		$$$ThrowStatus($$$ERROR($$$GeneralError,"%Net.Remote.Service::StartGatewayObject - invalid External Language Server"))
	}
	
	Try {
		Do ..Log(1, objectGateway, "Stopping "_objectGateway.Type_" Gateway Server '"_objectGateway.Name_"'",pVerbose)
		If $$$isVMS {
			// VMS (not supported)
			Do ..Log(1, objectGateway, "This Service cannot stop a Gateway on VMS systems",pVerbose)
		}
		Else {
			// Windows or Unix
			Do ..Log(1, objectGateway, "Shutting down the Gateway Server",pVerbose)
			Set tSC = ..ShutdownGateway(objectGateway,pVerbose,pTimeout)
		}
	}
	Catch {
		Set tSC = $$$ERROR($$$GeneralError, $ZE)
	}
	
	If tSC {
		Do ..UpdateState(objectGateway.Port,0)
		Do ..Log(1, objectGateway, "Gateway Server stopped",pVerbose)
	}
	Else {
		Do ..LogStatus(tSC, objectGateway, "StopGatewayObject",pVerbose)
		Do ..Log(1, objectGateway, "An error occurred while trying to stop the Gateway Server",pVerbose)
	}
	
	Use:tDev'="" tDev
	Quit tSC
}

/// Shutdown the Gateway Server.
/// 
/// pGateway : object with gateway configuration settings
/// pVerbose : flag to enable verbose logging, 0 by default
/// pTimeout : soft shutdown timeout in seconds, 0 by default
ClassMethod ShutdownGateway(pGateway As %DynamicObject, pVerbose As %Boolean = 0, pTimeout As %Integer = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set tDev = $I
	if (pGateway.%IsA("%Library.DynamicAbstractObject")) {
		set objectGateway = pGateway
	} elseif (pGateway.%IsA("%Net.Remote.ObjectGateway")) {
		set objectGateway = pGateway.toDao()
	} else {
		$$$ThrowStatus($$$ERROR($$$GeneralError,"%Net.Remote.Service::StartGatewayObject - invalid External Language Server"))
	}
	set status = $$CheckRequiredResource^%SYS.Gateway(objectGateway) quit:$$$ISERR(status) status
	
	If '(..IsGatewayRunning("", objectGateway.Name, 0, .tSC, 0)) quit $$$OK

	Try {
		Close "|TCP|"_+objectGateway.Port
		Set tGatewayConn = ""
		Set tSC = ..ConnectGateway(objectGateway, .tGatewayConn, "", 0,pVerbose,0)
		If tSC {
			Do ..Log(1, objectGateway, "Shutting down "_objectGateway.Type_" Gateway Server '"_objectGateway.Name_"' with a timeout of "_pTimeout_" sec",pVerbose)
			Set tSC = tGatewayConn.%Shutdown(pTimeout)
			Do ..LogStatus(tSC, objectGateway, "%Shutdown",pVerbose)
			Set tGatewayConn.Closed = 1
		}
		Else {
			Do ..Log(3, objectGateway, "Connection failed, check if Gateway Server is active: "_$system.Status.GetOneErrorText(tSC),pVerbose)
		}
		Do ##class(%Net.Remote.Gateway).%DeregisterSuperServer(objectGateway.Name)
	}
	Catch {
		Set tSC = $$$ERROR($$$GeneralError, $ZE)
	}
	Use:tDev'="" tDev
	Quit tSC
}

/// "Ping" the Gateway server to check if it is alive.
/// If <var>pReuseSocket</var> is true (the default is false), it will try to reuse the TCP device and in case
/// the TCP connection has become invalid it will reconnect.<br>
/// Instead of using this method it is recommended to instantiate or use an
/// existing %Net.Remote.Gateway client and %Connect(), call %Ping() and then %Disconnect().
ClassMethod PingGateway(pPort As %String, pAddress As %String = "127.0.0.1", pTimeout As %Integer = 5, pReuseSocket As %Boolean = 0, pVerbose As %Boolean = 0) As %Status
{
	quit ##class(%Net.Remote.Gateway).%Ping(pAddress, $g(pPort), pTimeout, pReuseSocket)
}

/// Connect or reconnect to a running External Language Server. <br/>
/// When <var>pStartOnDemand</var> is true (which is the default), the Gateway will be started if it is not running. <br/>
ClassMethod ConnectGateway(pGateway As %DynamicObject, ByRef pGatewayConn As %Net.Remote.Gateway, pAdditionalPaths As %String = "", pStartOnDemand As %Boolean = 1, pVerbose As %Boolean = 0, useSharedMemoryIfPossible As %Boolean = 0) As %Status [ Internal ]
{
	Set tSC = $$$OK
	Set tDev = $I
	if (pGateway.%IsA("%Library.DynamicAbstractObject")) {
		set objectGateway = pGateway
	} elseif (pGateway.%IsA("%Net.Remote.ObjectGateway")) {
		set objectGateway = pGateway.toDao()
	} else {
		$$$ThrowStatus($$$ERROR($$$GeneralError,"%Net.Remote.Service::StartGatewayObject - invalid External Language Server"))
	}

	Try {
		If ($G(pGatewayConn)="") || '(pGatewayConn.%IsA("%Net.Remote.Gateway")) {
			Set pGatewayConn = ##class(%Net.Remote.Gateway).%New()
			If '$IsObject(pGatewayConn) Set tSC = %objlasterror Quit
		}
	
		Set tTime = objectGateway.ConnectionTimeout
		set sslConfiguration = objectGateway.SSLConfigurationClient

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

		// Start Gateway if not running
		If pStartOnDemand {
			Lock +^%ISC.ObjectGateway.Management(objectGateway.Name):15
			If $TEST=1 { // succeeded in acquiring lock before timeout
				Try {
					If objectGateway.Type=".NET" {
						Set tInterface = objectGateway.AllowedIPAddresses
					}
					Else {
						Set tInterface = ""
					}
					If '(..IsGatewayRunning("", objectGateway.Name, 0, .tSC, 0, tInterface, sslConfiguration)) {
						Set tSC = ..StartGatewayObject(objectGateway,pVerbose)
					}
				}
				Catch {
					Set tSC = $$$ERROR($$$GeneralError, $ZE)
				}
				Lock -^%ISC.ObjectGateway.Management(objectGateway.Name)#"I"
			}
			Else { // lock timed out
				Set tSC = $$$ERROR($$$GeneralError, "Lock timeout expired for gateway object")
			}
			If $$$ISERR(tSC) Quit
		}

		Do ..Log(1, objectGateway, "Invoking %Connect with Server='localhost', Port='"_objectGateway.Port_"', Namespace='"_$Namespace_"', Timeout='"_tTime_"', AdditionalPaths='"_pAdditionalPaths_"'",pVerbose)
		Set tSC = pGatewayConn.%Connect("", objectGateway.Name, $Namespace, tTime, tPath, sslConfiguration, , useSharedMemoryIfPossible)
		If 'tSC Do ..Log(3,objectGateway,"Error in %Connect: "_$system.Status.GetOneErrorText(tSC),pVerbose)
	}
	Catch {
		Set tSC = $$$ERROR($$$GeneralError, $ZE)
	}

	If $$$ISERR(tSC) && $IsObject(pGatewayConn) {
		Do pGatewayConn.%Disconnect()
		Set pGatewayConn = $$$NULLOREF
	}
	
	Use:tDev'="" tDev
	Quit tSC
}

/// Get the Gateway definition object for a given Gateway name.
ClassMethod OpenGateway(pName As %String, Output pGateway As %DynamicObject) As %Status [ Internal ]
{
	Set tSC = $$$OK
	// Set pGateway = ##Class(Config.Gateways).Open(pName,,,.Status)
	set pGateway = $$GetGateway^%SYS.CONFIG(pName,.Status)
	If '$IsObject(pGateway) Set tSC = $$$ADDSC($$$ERROR($$$GeneralError, "Can't open Gateway definition for name '"_$G(pName)),Status) Quit tSC
	Quit tSC
}

/// Return true if Gateway is running,  based on the status of the TCP port, and responsiveness to PING<br/>
/// If the port is not in use, then Gateway is not running on the port, otherwise, we will PING the port.
/// Parameters <var>pPing</var> is deprecated.
ClassMethod IsGatewayRunning(host As %String = "127.0.0.1", port As %String = "", pVerbose As %Boolean = 0, Output pSC As %Status, pPing As %Boolean = 1, allowedip As %String = "", sslConfiguration As %String = "") As %Boolean
{
	if host="" {
		set serverName = port
		set port = ""
	} else {
		set serverName = ##class(%Net.Remote.Gateway).%FindServerByHostPort(host,port)
	}
	if serverName'="" {
		set status = ##class(%Net.Remote.Service).OpenGateway(serverName, .objGateway) quit:$$$ISERR(status) status
		set allowedip = objGateway.AllowedIPAddresses
		set host = $s(objGateway.Type="Remote":objGateway.Address,1:$case(allowedip,"0.0.0.0":"127.0.0.1","::":"::1",:allowedip))
		if port="" set port = objGateway.Port
		set sslConfiguration = objGateway.SSLConfigurationClient
	}
	if ##class(%Net.Remote.Utility).IsServerLocal(host)&&##class(%Net.Remote.Utility).CheckLocalPortFree(host,port,allowedip) {
		set pSC = $$$ERROR($$$GeneralError, "TCP port is not in use") Quit 0
	}
	set pSC = ##class(%Net.Remote.Gateway).%Ping(host,port,10,,,.serverName,sslConfiguration)
	if $$$ISOK(pSC)&&($isObject($g(objGateway)))&&(objGateway.Type'="Remote")&&(serverName'="")&&(serverName'=objGateway.FullName) {
		set pSC = $$$ERROR($$$GeneralError, "Running Gateway Server is not this server") Quit 0
	}
	quit $$$ISOK(pSC)
}

/// Update local Gateway state
ClassMethod UpdateState(pPort As %String, pIsRunning As %Boolean) [ Internal ]
{
	If ('$G(pPort)="") || ($G(pIsRunning)="") Quit
	Set pPort = +pPort
	If pIsRunning {
		Set ^IRIS.Temp.Gateway.State(pPort) = $ZDT($H,3)
	}
	Else {
		Kill ^IRIS.Temp.Gateway.State(pPort)
	}
	Quit
}

/// Add the status expressed in variable 's' to the activity log as either "Info" or "Error".
ClassMethod LogStatus(s As %Status, pGateway As %DynamicObject, pSource As %String, pVerbose As %Boolean = 0) [ Internal ]
{
	Do ..Log($S(s:1,1:3), pGateway, $S($G(pSource)'="":"Return from "_pSource_": ",1:"")_$system.Status.GetOneErrorText(s),pVerbose)
	Quit
}

/// Add the text message expressed in variable pMsg to the activity log as type pRecordType, with
/// information about the Gateway that originated the message.
/// If pVerbose=1, also write it to the current device.
/// [TO DO] If the current namespace is production-enabled, also log it in the Interoperability event log.
ClassMethod Log(pRecordType, pGateway As %DynamicObject, pText As %String, pVerbose As %Boolean = 0) [ Internal ]
{
	If $G(pText)="" Quit
	
	Try {
		If $IsObject(pGateway) {
			Set Name = pGateway.Name
			Set Type = pGateway.Type
			Set Server = $s(Type="Remote":pGateway.Address,1:"127.0.0.1")
			Set Port = pGateway.Port
		}
		Else {
			Set Name = ""
			Set Type = ""
			Set Server = ""
			Set Port = ""
		}
		Set Now = $ZDT($H,3)
		Set Job = $J
		Set pRecordType = +$G(pRecordType) // 0=Debug/Trace, 1=Info, 2=Warning, 3=Error
		Set:pRecordType>3!(pRecordType<0) pRecordType = 0
		If $g(pVerbose) {
			Set Tx = $Case(pRecordType,2:"*WARNING* ",3:"*ERROR* ",:"")_pText
			If ($I?1"|TCP|".e) && ($IsObject($G(%response))) {
				Write Now,"&nbsp;&nbsp;",$zconvert(Tx,"O","HTML"),"<br>"
				Do %response.Flush() Hang 0.1
			}
			Else  {
				Write Now,"  ",Tx,!
			}
		}
		
		If ##class(%Library.EnsembleMgr).IsEnsembleNamespace() {
			Try {
				// TO DO: Insert into Ensemble Event Log -- if in a running production?
			}
			Catch {
			}
		}
		NEW %ROWID,%msg,%ROWCOUNT
		&sql( INSERT INTO ActivityLog
		(DateTime, RecordType, GatewayName, GatewayType, Server, Port, Text, Job)
		VALUES (:Now, :pRecordType, :Name, :Type, :Server, :Port, :pText, :Job)
		)
	}
	
	Catch {
	}
	
	Quit
}

ClassMethod GetJavaExecutableCommand(javaHomeDir As %String = "", Output javaExecutable As %String = "", normalizeWithSpaces As %Boolean = 1) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK

	Try {
		// Build the java executable path
		Set javaExecutable = "java"_$Select($$$isWINDOWS:".exe",$$$isVMS:".exe",1:"")
		If (javaHomeDir'="") {
		    if $e(javaHomeDir,1)="""",$e(javaHomeDir,*)="""" { set javaHomeDir=$e(javaHomeDir,2,*-1) }
			Set javaBinDir = ##class(%Library.File).SubDirectoryName(javaHomeDir,"bin")
			Set javaBinDir = javaBinDir_$Select($$$isWINDOWS:"\",$$$isVMS:"",1:"/")
			Set javaExecutable = ##class(%Library.File).NormalizeFilename(javaExecutable,javaBinDir)
		}
		Set:normalizeWithSpaces javaExecutable = ##class(%Library.File).NormalizeFilenameWithSpaces(javaExecutable)

		Set:(javaExecutable="") tSC = $$$ERROR($$$GeneralError,"Java executable not found in the given directory: "_$Get(javaBinDir))
	} Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

ClassMethod GetPythonExecutableCommand(pythonPath As %String = "", Output pythonExecutable As %String = "", Output pythonVersion As %String = "", normalizeWithSpaces As %Boolean = 1) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK

	Try {
		If (pythonPath'="") {
			Set pythonExecutable = ##class(%Library.File).CanonicalFilename(pythonPath)
			Set:normalizeWithSpaces pythonExecutable = ##class(%Library.File).NormalizeFilenameWithSpaces(pythonExecutable)
			Set:(pythonExecutable="") tSC = $$$ERROR($$$GeneralError,"Python executable not found in the given path: "_$Get(pythonPath))
			Quit:$$$ISERR(tSC)
			Set tSC = ..GetPythonVersion(pythonExecutable, .pythonVersion)
			Quit:$$$ISERR(tSC)
		}
		Else {
			Set pythonExecutable = "python3"
			Set tSC = ..GetPythonVersion(pythonExecutable, .pythonVersion)
			if $$$ISERR(tSC) {
				Set pythonExecutable = "python"
				Set tSC = ..GetPythonVersion(pythonExecutable, .pythonVersion)
				Quit:$$$ISERR(tSC)
			}
		}
	} Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

ClassMethod GetPythonGatewayScript(Output pythonGatewayScript As %String = "", scriptName As %String, normalizeWithSpaces As %Boolean = 1) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK

	Try {
		Set pythonGatewayScript = $Select($$$isWINDOWS:"\dev\python\"_scriptName_".bat",$$$isVMS:"\dev\python\"_scriptName_".bat",1:"/dev/python/"_scriptName_".sh")
		Set pythonGatewayScript = ##class(%Library.File).NormalizeFilename($System.Util.InstallDirectory()_pythonGatewayScript)
		Set:normalizeWithSpaces pythonGatewayScript = ##class(%Library.File).NormalizeFilenameWithSpaces(pythonGatewayScript)
		Set:(pythonGatewayScript="") tSC = $$$ERROR($$$GeneralError,"Python Gateway Script not found: "_$Get(pythonGatewayScript))
		Quit:$$$ISERR(tSC)
	} Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

ClassMethod GetPythonVersion(pythonExecutable As %String = "", Output pythonVersion As %String = "") As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim tCurrentDevice As %String = $IO
	#dim pOutput As %String = ""
	
	Try {
		Set cmdArgs = ""
		Set cmdArgs($increment(cmdArgs)) = "--version"
		Set tSC = ##class(%Net.Remote.Utility).RunCommandViaCPIPE(pythonExecutable,.pDevice,.pOutput,12,12,.cmdArgs)
		Close pDevice:"I"
		Quit:$$$ISERR(tSC)
		
		set pythonVersion = $zstrip(pOutput, "*c")
		set pverNumber = $p(pythonVersion, " ", 2)
		set p1 = +$p(pverNumber,".",1)
		set p2 = +$p(pverNumber,".",2)
		
		if '((p1=3) && (p2>=8))  {
			set tSC = $$$ERROR($$$GeneralError,"Only support Python 3.8+. Found Python version: "_pOutput)
		}
	} Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	
	Close:($Get(pDevice)'="") pDevice:"I"
	Use tCurrentDevice
	
	Quit tSC
}

ClassMethod GetChecksumPath(Output checksumPath As %String = "", serverName As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK

	Try {
		Set crcName = $zcrc(serverName,7)
		Set winPath = "\dev\python\virtual\"_serverName_"_"_crcName_"\.pythonpath"
		Set linuxPath = "/dev/python/virtual/"_serverName_"_"_crcName_"/.pythonpath"
		Set checksumPath = $Select($$$isWINDOWS:winPath,$$$isVMS:winPath,1:linuxPath)
		Set checksumPath = ##class(%Library.File).NormalizeFilename($System.Util.DataDirectory()_checksumPath)
	} Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	
	Quit tSC
}

ClassMethod CompareChecksum(Output compareResult As %String = "", serverName As %String, pythonVersion As %String, pythonPath As %String, irisVersion As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK

	Try {
		Set tSC = ..GetChecksumPath(.checksumPath, serverName)
		Quit:$$$ISERR(tSC)
		
		set compareResult = 0
						
		If ##class(%File).Exists(checksumPath) {
			set file=##class(%File).%New(checksumPath)
			do file.Open("R")
			set prePyVersion = file.Read()
			set prePath = file.Read()
			set preIRISVersion = file.Read()
			do file.Close()
			
			set compareResult = "0"
					
			if prePyVersion=pythonVersion {
				if prePath=pythonPath {
					if preIRISVersion=irisVersion {
						set compareResult = "2"
					} else {
						set compareResult = "1"
					}
				}
			}
		}
		Quit:$$$ISERR(tSC)
	} Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

ClassMethod SetupVirtualEnv(pythonSetupScript As %String, serverName As %String, pythonExecutable As %String, setupLevel As %String, irisVersion As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim tCurrentDevice As %String = $IO
	#dim pOutput As %String = ""
	
	Try {
		Set cmdArgs = ""
		Set cmdArgs($increment(cmdArgs)) = serverName
		Set cmdArgs($increment(cmdArgs)) = pythonExecutable
		Set cmdArgs($increment(cmdArgs)) = setupLevel
		Set cmdArgs($increment(cmdArgs)) = irisVersion
		Set tSC = ##class(%Net.Remote.Utility).RunCommandViaCPIPE(pythonSetupScript,.pDevice,.pOutput,120,120,.cmdArgs)
		Close pDevice:"I"
		Quit:$$$ISERR(tSC)
		
		set idx = $FIND(pOutput, "setting up virtual environment succeeded")
		
		if (idx=0)  {
			set tSC = $$$ERROR($$$GeneralError,"Python virtual environment setup failed: "_pOutput)
		}
	} Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	
	Close:($Get(pDevice)'="") pDevice:"I"
	Use tCurrentDevice
	
	Quit tSC
}

ClassMethod DeleteVirtualEnv(serverName As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim tCurrentDevice As %String = $IO
	#dim pOutput As %String = ""
	
	Try {
		Set tSC = ..GetPythonGatewayScript(.setupScript, "setup", 0)
		Quit:$$$ISERR(tSC)
		
		Set cmdArgs = ""
		Set cmdArgs($increment(cmdArgs)) = serverName
		Set cmdArgs($increment(cmdArgs)) = "Null"
		Set cmdArgs($increment(cmdArgs)) = "RemoveDirectoryTree"
		Set cmdArgs($increment(cmdArgs)) = $zcrc(serverName,7)
		Set tSC = ##class(%Net.Remote.Utility).RunCommandViaCPIPE(setupScript,.pDevice,.pOutput,120,120,.cmdArgs)
		Close pDevice:"I"
		Quit:$$$ISERR(tSC)
	} Catch (ex) {
		Set tSC = ex.AsStatus()
	}
	
	Close:($Get(pDevice)'="") pDevice:"I"
	Use tCurrentDevice
	
	Quit tSC
}

/// Returns the primary Java version number.
/// For example, for 1.8.0_241, it returns 8. For 11.0.6, it returns 11.
/// Rules of how the complete version string is formatted can be found here:
/// http://www.oracle.com/technetwork/java/javase/versioning-naming-139433.html
ClassMethod GetJavaVersion(javaHomeDir As %String = "", Output version As %Integer, Output versionString As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	#dim tCurrentDevice As %String = $IO
	#dim pOutput As %String = ""

	// Rules for parsing java -version to return primary version:
	// 1. Get output from "java -version"
	// 2. Look for version string inside quotes
	// 3. Get first and second pieces of the dot pieces of the version string and convert both to integers
	// 4. If the first piece is 1, the primary version is the second piece
	// 5. If the first piece is greater than 8, otherwise, the primary version is the first piece
	//
	// examples of some outputs of java -version:
	// java version "1.7.0_191"
	// openjdk version "1.8.0_222"
	// openjdk version "10.0.2" 2018-07-17
	// openjdk version "11-ea" 2018-09-25
	// openjdk version "11.0.6" 2020-01-14
		
	Try {
		// Build the java executable path
		Set tSC = ..GetJavaExecutableCommand(javaHomeDir,.javaExecutable,0)
		Quit:$$$ISERR(tSC)

		// java -version prints to std err, not std out, so we need to read that output as well
		Set cmdArgs = ""
		Set cmdArgs($increment(cmdArgs)) = "-Xmx8m"
		Set cmdArgs($increment(cmdArgs)) = "-version"
		Set tSC = ##class(%Net.Remote.Utility).RunCommandViaCPIPE(javaExecutable,.pDevice,.pOutput,12,12,.cmdArgs)
		Close pDevice:"I"
		Quit:$$$ISERR(tSC)
		
		set versionString = $p(pOutput,"""",2)
		set p1 = +$p(versionString,".",1)
		set p2 = +$p(versionString,".",2)
		if p1=1 {
			set version = p2
		} elseif p1>8 {
			set version = p1
		} else {
			set version = ""
			set tSC = $$$ERROR($$$GeneralError,"Java version not found: "_pOutput)
		}

	} Catch (ex) {
		Set tSC = ex.AsStatus()
	}

	// Close command pipe, restore original device
	Close:($Get(pDevice)'="") pDevice:"I"
	Use tCurrentDevice
	
	Quit tSC
}

ClassMethod CheckJavaVersionSupported(javaVersion As %String = "") As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	for i=1:1:$ll($$$javaSupportedVersions) set versions($li($$$javaSupportedVersions,i))=""
	set maxversion = $o(versions(""),-1)
	if ((javaVersion<maxversion) && ($d(versions(javaVersion))=0)) {
		set tSC = $$$ERROR($$$UnsupportedJavaVersion,javaVersion)
	}
	quit tSC
}

ClassMethod GetJARDirectory(javaVersion As %Integer, Output JARDir As %String) As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK
	set tSC = ..CheckJavaVersionSupported(javaVersion) quit:$$$ISERR(tSC) tSC
	set JARDir = ##class(%Library.File).NormalizeFilename($System.Util.InstallDirectory()_"/dev/java/lib/1.8")
	Quit tSC
}

ClassMethod GetJavaRequiredClassPath(pGateway As %DynamicObject, Output requiredClassPath As %String = "") As %Status [ Internal ]
{
	#dim tSC As %Status = $$$OK

	// The correct directory for the JARs depends on the version of Java (system default or the one that JAVA_HOME points to)
	set tSC = ..GetJavaVersion(pGateway.JavaHome,.javaVersion,.versionString) quit:$$$ISERR(tSC) tSC
	set tSC = ..GetJARDirectory(javaVersion, .JARDir) quit:$$$ISERR(tSC) tSC

	// Get JDBC JAR paths
	Set JDBCJARpath = ##class(%Library.File).NormalizeFilename($$$javaJDBCJAR,JARDir)
	Set JDBCJARpath = ##class(%Library.File).NormalizeFilenameWithSpaces(JDBCJARpath)
	If $extract(JDBCJARpath)="""",$extract(JDBCJARpath,*)="""" Set JDBCJARpath=$extract(JDBCJARpath,2,*-1)
	
	Set tCPSep = $Select($$$isWINDOWS:";", 1:":")
	Set requiredClassPath = JDBCJARpath
	
	if (pGateway.Type = "XSLT") {
		Set saxonJARPath = ##class(%Library.File).NormalizeFilename($SYSTEM.Util.InstallDirectory()_"dev/java/lib/xml/saxon9.jar")
		Set saxonJARPath = ##class(%Library.File).NormalizeFilenameWithSpaces(saxonJARPath)
		If $extract(saxonJARPath)="""",$extract(saxonJARPath,*)="""" Set saxonJARPath=$extract(saxonJARPath,2,*-1)
		Set utilsJARPath = ##class(%Library.File).NormalizeFilename($$$javaUtilsJAR,JARDir)
		Set utilsJARPath = ##class(%Library.File).NormalizeFilenameWithSpaces(utilsJARPath)
		If $extract(utilsJARPath)="""",$extract(utilsJARPath,*)="""" Set utilsJARPath=$extract(utilsJARPath,2,*-1)
		set meta = ##class(%DynamicObject).%FromJSON(^%SYS("java","intersystems-utils"))
		if (meta.version.major = 4) && (meta.version.minor > 1) || (meta.version.major > 4) {
			Set requiredClassPath = requiredClassPath_tCPSep_utilsJARPath
		} else {
			Set requiredClassPath = requiredClassPath_tCPSep_saxonJARPath_tCPSep_utilsJARPath
		}
		
	}
	
	if (pGateway.Type = "ML") {
		Set mlJARPath = ##class(%Library.File).NormalizeFilename($$$javaIntegratedMLJAR,JARDir)
		Set mlJARPath = ##class(%Library.File).NormalizeFilenameWithSpaces(mlJARPath)
		If $extract(mlJARPath)="""",$extract(mlJARPath,*)="""" Set mlJARPath=$extract(mlJARPath,2,*-1)
		Set requiredClassPath = requiredClassPath_tCPSep_mlJARPath
	}

	if (pGateway.Type = "R") {
		Set mlJARPath = ##class(%Library.File).NormalizeFilename($$$javaRGatewayJAR,JARDir)
		Set mlJARPath = ##class(%Library.File).NormalizeFilenameWithSpaces(mlJARPath)
		If $extract(mlJARPath)="""",$extract(mlJARPath,*)="""" Set mlJARPath=$extract(mlJARPath,2,*-1)
		Set requiredClassPath = requiredClassPath_tCPSep_mlJARPath
	}
	
	Quit tSC
}

/// Perform system startup task
ClassMethod OnSystemStartup(Output pConsoleLog As %String) [ Internal ]
{
	set pConsoleLog = 0
	set tSC = $$$OK
	try {
		; don't add if not first time after installation
		if '$g(^SYS("FirstRestartSinceInstall")) quit
		do ##class(%External.Gateway).importJavaLibraries()
	} catch ex {
		set tSC = ex.AsStatus()
	}
	if $$$ISERR(tSC) {
		set pConsoleLog($i(pConsoleLog)) = $lb(1,$system.Status.GetErrorText(tSC))
	}
	quit
}

ClassMethod GetJavaIntegratedMLJAR() As %String [ Internal ]
{
	set utilsJARPath = ""
	try {
		Set tSC = ..GetJavaVersion("",.javaVersion,.versionString) quit:$$$ISERR(tSC)
		set tSC = ..GetJARDirectory(javaVersion, .JARDir) quit:$$$ISERR(tSC)
		Set utilsJARPath = ##class(%Library.File).NormalizeFilename($$$javaIntegratedMLJAR,JARDir)
	} catch ex {
		set tSC = ex.AsStatus()
		set utilsJARPath = ""
	}
	quit utilsJARPath
}

ClassMethod IntegratedMLJARInstalled() As %Boolean [ Internal ]
{
	try {
		do $$$javaIntegratedMLJAR
		return 1
	} catch ex {
		if $system.Status.GetErrorCodes(ex.AsStatus())=$$$ERRORCODE($$$JarFileDoesNotExist) {
			return 0
		}
		throw ex
	}
}

}
